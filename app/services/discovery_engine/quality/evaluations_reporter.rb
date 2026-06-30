module DiscoveryEngine::Quality
  class EvaluationsReporter
    # date_string format is "2026-02"
    def initialize(date_string: nil, states: [])
      @date_string = date_string
      @states = states
    end

    attr_reader :date_string, :states

    def fetch_and_format
      evaluations_grouped_by_state = {
        FAILED: [],
        SUCCEEDED: [],
        PENDING: [],
        RUNNING: [],
      }

      if states.present?
        evaluations_grouped_by_state.select! { |k, _v| states.include?(k) }
      end

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
      evaluations_hash.each do |state, evaluations|
        puts state
        puts "=============="

        sorted(evaluations).each do |evaluation|
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

    def sorted(evaluations)
      evaluations.sort do |a, b|
        [sample_query_set_name(a), formatted_date(a.create_time)] <=> [sample_query_set_name(b), formatted_date(b.create_time)]
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
