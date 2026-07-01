require "google/cloud/discovery_engine/v1beta"

RSpec.describe DiscoveryEngine::Quality::EvaluationsReporter do
  let(:evaluation_reporter) { described_class }

  let(:binary_evaluation_name) { "projects/123456/locations/global/evaluations/0038a998-7424-4fa4-ac3c-f70b3497ebf3" }
  let(:another_binary_evaluation_name) { "projects/123456/locations/global/evaluations/0038a998-7424-4fa4-ac3c-f70b34123456" }

  let(:binary_set_name) { "projects/123456/locations/global/sampleQuerySets/binary_2025-12" }

  let(:binary_query_set_spec) do
    double("Google::Cloud::DiscoveryEngine::V1beta::Evaluation::EvaluationSpec::QuerySetSpec", sample_query_set: binary_set_name)
  end

  let(:binary_evaluation_spec) do
    double("Google::Cloud::DiscoveryEngine::V1beta::Evaluation::EvaluationSpec", query_set_spec: binary_query_set_spec)
  end

  let(:clickstream_evaluation_name) { "projects/123456/locations/global/evaluations/0392a80d-4c9b-433a-93a8-66f4235ba4f9" }
  let(:another_clickstream_evaluation_name) { "projects/123456/locations/global/evaluations/0392a80d-4c9b-433a-93a8-123456" }

  let(:clickstream_set_name) { "projects/123456/locations/global/sampleQuerySets/clickstream_2025-12" }

  let(:clickstream_query_set_spec) do
    double("Google::Cloud::DiscoveryEngine::V1beta::Evaluation::EvaluationSpec::QuerySetSpec", sample_query_set: clickstream_set_name)
  end

  let(:clickstream_evaluation_spec) do
    double("Google::Cloud::DiscoveryEngine::V1beta::Evaluation::EvaluationSpec", query_set_spec: clickstream_query_set_spec)
  end

  let(:quality_metrics) { double("Google::Cloud::DiscoveryEngine::V1beta::QualityMetrics", to_h: { "anything": "anything" }) }

  let(:timestamp_one) { double("Google::Protobuf::Timestamp", seconds: 1_763_535_606, nanos: 700_845_000) }
  let(:timestamp_two) { double("Google::Protobuf::Timestamp", seconds: 1_763_536_521, nanos: 507_884_722) }
  let(:timestamp_three) { double("Google::Protobuf::Timestamp", seconds: 1_758_096_006, nanos: 123_415_000) }
  let(:timestamp_four) { double("Google::Protobuf::Timestamp", seconds: 1_758_097_403, nanos: 880_911_074) }
  let(:timestamp_five) { double("Google::Protobuf::Timestamp", seconds: 1_782_468_026, nanos: 497_828_000) }
  let(:timestamp_six) { double("Google::Protobuf::Timestamp", seconds: 1_782_468_035, nanos: 806_111_919) }

  let(:evaluation_success) do
    double("Google::Cloud::DiscoveryEngine::V1beta::Evaluation",
           name: binary_evaluation_name,
           evaluation_spec: binary_evaluation_spec,
           state: :SUCCEEDED,
           quality_metrics: quality_metrics,
           error: {},
           create_time: timestamp_one,
           end_time: timestamp_two)
  end

  let(:evaluation_success_two) do
    double("Google::Cloud::DiscoveryEngine::V1beta::Evaluation",
           name: another_binary_evaluation_name,
           evaluation_spec: binary_evaluation_spec,
           state: :SUCCEEDED,
           quality_metrics: {},
           error: {},
           create_time: timestamp_three,
           end_time: timestamp_four)
  end

  let(:evaluation_failure) do
    double("Google::Cloud::DiscoveryEngine::V1beta::Evaluation",
           name: clickstream_evaluation_name,
           evaluation_spec: clickstream_evaluation_spec,
           state: :FAILED,
           error: { code: 13, message: "Internal error encountered. Please try again. If the issue persists, please contact our support team." },
           create_time: timestamp_three,
           end_time: timestamp_four)
  end

  let(:evaluation_failure_two) do
    double("Google::Cloud::DiscoveryEngine::V1beta::Evaluation",
           name: another_clickstream_evaluation_name,
           evaluation_spec: clickstream_evaluation_spec,
           state: :FAILED,
           error: { code: 13, message: "Internal error encountered. Please try again. If the issue persists, please contact our support team." },
           create_time: timestamp_five,
           end_time: timestamp_six)
  end

  let(:mock_client) { double(::Google::Cloud::DiscoveryEngine::V1beta::EvaluationService::Client) }
  let(:mock_list_evaluations_response) { double(Gapic::PagedEnumerable) }

  before do
    allow(DiscoveryEngine::Clients).to receive(:evaluation_service).and_return(mock_client)
    allow(mock_client).to receive(:list_evaluations).and_return(mock_list_evaluations_response)
    allow(mock_list_evaluations_response).to receive(:each)
      .and_yield(evaluation_success)
      .and_yield(evaluation_success_two)
      .and_yield(evaluation_failure)
      .and_yield(evaluation_failure_two)
  end

  describe ".fetch_and_format" do
    context "when no date string is passed in" do
      it "prints out all pages of results from the evaluation service" do
        expected_output = <<~HEREDOC
          FAILED
          ==============
          Sample query set: clickstream_2025-12
          Evaluation: projects/123456/locations/global/evaluations/0392a80d-4c9b-433a-93a8-66f4235ba4f9
          Start time: 2025-09-17 08:00:06

          Sample query set: clickstream_2025-12
          Evaluation: projects/123456/locations/global/evaluations/0392a80d-4c9b-433a-93a8-123456
          Start time: 2026-06-26 10:00:26

          SUCCEEDED
          ==============
          Sample query set: binary_2025-12
          Evaluation: projects/123456/locations/global/evaluations/0038a998-7424-4fa4-ac3c-f70b34123456
          Start time: 2025-09-17 08:00:06
          No quality metrics!

          Sample query set: binary_2025-12
          Evaluation: projects/123456/locations/global/evaluations/0038a998-7424-4fa4-ac3c-f70b3497ebf3
          Start time: 2025-11-19 07:00:06

          PENDING
          ==============
          RUNNING
          ==============
        HEREDOC

        expect { evaluation_reporter.new.fetch_and_format }.to output(expected_output).to_stdout
      end
    end

    context "when a 'YYYY-MM' date string is passed in" do
      it "only prints out evaluations created during the year and month specified" do
        expected_output = <<~HEREDOC
          FAILED
          ==============
          Sample query set: clickstream_2025-12
          Evaluation: projects/123456/locations/global/evaluations/0392a80d-4c9b-433a-93a8-66f4235ba4f9
          Start time: 2025-09-17 08:00:06

          SUCCEEDED
          ==============
          Sample query set: binary_2025-12
          Evaluation: projects/123456/locations/global/evaluations/0038a998-7424-4fa4-ac3c-f70b34123456
          Start time: 2025-09-17 08:00:06
          No quality metrics!

          PENDING
          ==============
          RUNNING
          ==============
        HEREDOC

        date_string = "2025-09"
        expect { evaluation_reporter.new(date_string:).fetch_and_format }.to output(expected_output).to_stdout
      end
    end

    context "when a state is passed in" do
      it "only prints out evaluations with a matching state" do
        expected_output = <<~HEREDOC
          FAILED
          ==============
          Sample query set: clickstream_2025-12
          Evaluation: projects/123456/locations/global/evaluations/0392a80d-4c9b-433a-93a8-66f4235ba4f9
          Start time: 2025-09-17 08:00:06

          Sample query set: clickstream_2025-12
          Evaluation: projects/123456/locations/global/evaluations/0392a80d-4c9b-433a-93a8-123456
          Start time: 2026-06-26 10:00:26

          PENDING
          ==============
        HEREDOC

        expect {
          evaluation_reporter.new(states: %i[FAILED PENDING]).fetch_and_format
        }.to output(expected_output).to_stdout
      end
    end
  end
end
