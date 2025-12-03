module DiscoveryEngine::Quality
  class FailedEvaluationError < StandardError
    attr_reader :sample_query_set_name

    def initialize(sample_query_set_name)
      super
      @sample_query_set_name = sample_query_set_name
    end

    def message
      "Evaluation of #{sample_query_set_name} failed"
    end
  end
end
