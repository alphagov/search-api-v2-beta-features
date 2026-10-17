module DiscoveryEngine::Quality
  class FailedEvaluationError < StandardError
    attr_reader :error_message

    def initialize(error_message)
      super
      @error_message = error_message
    end

    def message
      @error_message
    end
  end
end
