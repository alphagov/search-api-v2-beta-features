module DiscoveryEngine::Quality
  class EvaluationsReporter
    # date_string format is "2026-02"
    def fetch_and_format(date_string: nil)
      evaluations_grouped_by_state = {
        FAILED: [],
        SUCCEEDED: [],
        PENDING: [],
        RUNNING: [],
      }

      evaluation_service.list_evaluations(parent:).each do |evaluation|
        next if date_string && !formatted_date(evaluation.create_time).include?(date_string)

        evaluations_grouped_by_state.each_key do |state|
          if evaluation.state == state
            evaluations_grouped_by_state[state] << evaluation
          end
        end
      end
      printout_evaluations(evaluations_grouped_by_state)
    end

  private

    def printout_evaluations(evaluations_hash)
      evaluations_hash.each do |state, array_of_evaluations|
        puts state
        puts "=============="

        array_of_evaluations.each do |evaluation|
          sqs = sample_query_set_name(evaluation)
          name = evaluation.name
          time = formatted_date(evaluation.create_time)
          puts "Sample query set: #{sqs}"
          puts "Evaluation: #{name}"
          puts "Start time: #{time}"
          puts ""
        end
      end
    end

    def formatted_date(google_time_stamp)
      data = { nanos: google_time_stamp.nanos, seconds: google_time_stamp.seconds }
      Google::Protobuf::Timestamp.new(data)
        .to_time
        .strftime("%Y-%m-%d %H:%M:%S")
    end

    def sample_query_set_name(evaluation)
      evaluation.evaluation_spec.query_set_spec.sample_query_set.split("/").last
    end

    def evaluation_service
      @evaluation_service ||= DiscoveryEngine::Clients.evaluation_service
    end

    def parent
      @parent ||= Rails.application.config.discovery_engine_default_location_name
    end
  end
end
