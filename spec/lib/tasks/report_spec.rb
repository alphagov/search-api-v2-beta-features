RSpec.describe "Report tasks" do
  describe "report:evaluations" do
    let(:reporter) { instance_double(DiscoveryEngine::Quality::EvaluationsReporter) }
    let(:task) { Rake::Task["report:evaluations"] }

    before do
      task.reenable

      allow(DiscoveryEngine::Quality::EvaluationsReporter).to receive(:new)
        .with(anything)
        .and_return(reporter)
      allow(reporter).to receive(:fetch_and_format)
    end

    it "does not require arguments" do
      expect { task.invoke }.not_to raise_error
    end

    it "raises an error if date string is not formatted correctly" do
      expect { task.invoke("2027-1") }.to raise_error(RuntimeError)
    end

    it "raises an error if the format is not valid" do
      expect { task.invoke("", "invalid") }.to raise_error(RuntimeError)
    end
  end
end
