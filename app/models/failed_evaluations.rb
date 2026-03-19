class FailedEvaluations
  def evaluations(page)
    json = File.read(Rails.root.join("lib", "production_evaluations", page))
    JSON.parse(json)["evaluations"]
  end

  def all_evaluations
    ["page_1.json", "page_2.json", "page_3.json"].flat_map do |page|
      evaluations(page)
    end
  end

  def failed
    all_evaluations.select{|evaluation| evaluation["state"] == "FAILED"}
  end

  def printout(status)
    evaluations = status == "failed" ? failed : all_evaluations
    evaluations.each do |e|
      name = e["name"]
      sqs = e["evaluationSpec"]["querySetSpec"]["sampleQuerySet"].split("/").last
      time = e["createTime"]
      status = e["state"]
      puts name
      puts sqs
      puts time
      puts status
      puts "---"
    end
  end
end
