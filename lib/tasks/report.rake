namespace :report do
  # Outputs a list of evaluations of GOV.UK site search quality fetched from the Google DiscoveryEngine API's evaluations endpoint.
  # The task can be called with no arguments, or with two arguments.
  # Example usage:
  # rake report:evaluations['2026-06','failed pending'] will fetch pending and failed evaluations created in June 2026.
  # rake report:evaluations['','failed pending'] will fetch all failed and pending evaluations
  # rake report:evaluations['2026-06',''] will fetch all evaluations created in June 2026
  # rake report:evaluations will fetch all evaluations

  desc "Output evaluations report"
  task :evaluations, %i[date_string states] => :environment do |_, args|
    valid_date_regex = /^\d{4}-\d{2}$/
    valid_states = %i[FAILED PENDING RUNNING SUCCEEDED]

    if args[:date_string]
      date_string = args[:date_string]
      raise "date_string must be in the format yyyy-mm" unless date_string.match(valid_date_regex)
    end

    if args[:states]
      states = args[:states].split(" ").map { |arg| arg.upcase.to_sym }
      raise "state must be one of #{valid_states.to_sentence}" unless (states - valid_states).empty?
    end

    DiscoveryEngine::Quality::EvaluationsReporter.new(date_string:, states:).fetch_and_format
  end
end
