require "google/cloud/discovery_engine/v1beta"

RSpec.describe DiscoveryEngine::Quality::EvaluationsReporter do
  let(:evaluation_reporter) { described_class.new }

  let(:binary_evaluation_name) { "projects/123456/locations/global/evaluations/0038a998-7424-4fa4-ac3c-f70b3497ebf3" }

  let(:binary_set_name) { "projects/123456/locations/global/sampleQuerySets/binary_2025-12" }

  let(:binary_query_set_spec) do
    double("Google::Cloud::DiscoveryEngine::V1beta::Evaluation::EvaluationSpec::QuerySetSpec", sample_query_set: binary_set_name)
  end

  let(:binary_evaluation_spec) do
    double("Google::Cloud::DiscoveryEngine::V1beta::Evaluation::EvaluationSpec", query_set_spec: binary_query_set_spec)
  end

  let(:clickstream_evaluation_name) { "projects/123456/locations/global/evaluations/0392a80d-4c9b-433a-93a8-66f4235ba4f9" }

  let(:clickstream_set_name) { "projects/123456/locations/global/sampleQuerySets/clickstream_2025-12" }

  let(:clickstream_query_set_spec) do
    double("Google::Cloud::DiscoveryEngine::V1beta::Evaluation::EvaluationSpec::QuerySetSpec", sample_query_set: clickstream_set_name)
  end

  let(:clickstream_evaluation_spec) do
    double("Google::Cloud::DiscoveryEngine::V1beta::Evaluation::EvaluationSpec", query_set_spec: clickstream_query_set_spec)
  end

  let(:evaluation_success) do
    double("Google::Cloud::DiscoveryEngine::V1beta::Evaluation",
           name: binary_evaluation_name,
           evaluation_spec: binary_evaluation_spec,
           state: :SUCCEEDED,
           error: {})
  end

  let(:evaluation_failure) do
    double("Google::Cloud::DiscoveryEngine::V1beta::Evaluation",
           name: clickstream_evaluation_name,
           evaluation_spec: clickstream_evaluation_spec,
           state: :FAILED,
           error: { code: 13, message: "Internal error encountered. Please try again. If the issue persists, please contact our support team." })
  end

  let(:mock_client) { double(::Google::Cloud::DiscoveryEngine::V1beta::EvaluationService::Client) }
  let(:mock_list_evaluations_response) { double(Gapic::PagedEnumerable) }

  before do
    allow(DiscoveryEngine::Clients).to receive(:evaluation_service).and_return(mock_client)
    allow(mock_client).to receive(:list_evaluations).and_return(mock_list_evaluations_response)
    allow(mock_list_evaluations_response).to receive(:each).and_yield(evaluation_success).and_yield(evaluation_failure)
  end

  describe ".fetch_and_format" do
    it "fetches all pages of results from the evaluations service" do
      expected_output = <<~HEREDOC
        FAILED
        ==============
        Sample query set: clickstream_2025-12
        Evaluation: projects/123456/locations/global/evaluations/0392a80d-4c9b-433a-93a8-66f4235ba4f9

        SUCCEEDED
        ==============
        Sample query set: binary_2025-12
        Evaluation: projects/123456/locations/global/evaluations/0038a998-7424-4fa4-ac3c-f70b3497ebf3

        PENDING
        ==============
        RUNNING
        ==============
      HEREDOC

      expect { evaluation_reporter.fetch_and_format }.to output(expected_output).to_stdout
    end
  end
end
