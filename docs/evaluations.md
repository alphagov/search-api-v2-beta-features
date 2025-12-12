# Evaluations

We use Discovery Engine's in-built evaluations feature to measure the quality and relevance of search results. This allows us to:

- [Monitor search quality](#How-evaluations-are-monitored) with automated alerts if relevance scores drop unexpectedly.

- Compare search engines so that we can test out new configurations to improve search results.

Evaluations rely on 'judgement lists' (a.k.a. ['sample query sets'][sample-query-sets] in Discovery Engine terminology). These are sets of search queries paired with targets and their ratings, indicating how relevant specific results are for those queries. There are three sets of judgement lists that are used to create evaluations, which we refer to as ['datasets'](#Datasets). When evaluations are run, point-in-time search results are compared to the judgement lists to create [scores](#How-evaluations-are-scored), which can be tracked over time.

## Datasets

### Clickstream

The clickstream judgement lists are generated from the results users click on when using site search, with results given a score of 0-3 depending on how many clicks they get. Each query can have multiple targets, the number of which varies depending on how many results been clicked above the threshold. 

This judgement list is used for assessing relevance of search results at scale.

### Binary

The binary judgement lists contain a list of search queries with results that have a score of 3, indicating that they’re a perfect match for the query. The judgement list is made up of individual query-target pairs, for increased interpretability. A query can appear more than once in the judgement list if it has multiple targets with a score of 3, but these will be split out into separate query-target pairs, rather than having two targets nested under one query as it would be in the clickstream dataset.

This judgement list is used for assessing whether any results that should appear are missing - identifying relevance issues quickly.

### Explicit

Manually created and curated judgement lists. The explicit judgements are based on what the search team has determined should be in the top result for a query.

## How evaluations are run

### End-to-end

This diagram shows the end-to-end process of how an evaluation is run, including how the data is prepared before the evaluation and how results are processed afterwards:

![Evaluations sequence diagram](images/evaluations-sequence.png)
This diagram is a screenshot from a live [Mural board][evaluations-sequence-mural-board].

The overall process involves:

1. Gathering user interaction data on gov.uk. This is done using GA4.
2. For binary and clickstream datasets, judgement lists are compiled using user interaction data and stored in Big Query. This is done in SQL via [Dataform][dataform]. For the explicit datasets, judgement lists are compiled manually.
3. Judgement lists are taken from BigQuery and imported into Discovery Engine as Sample Query Sets. This is done via the [`setup_sample_query_sets` rake task][setup-sample-query-sets-rake-task].
4. Evaluations are run on a regular basis, and results are stored in a GCP Bucket (detailed metrics) and Prometheus (high level metrics). This is done via the [`report_quality_metrics` rake task][report-quality-metrics-rake-task].

Step 4 is usually what we mean when we say 'run an evaluation'.

### Schedule

When first created, the crontasks for running evaluations had the following schedule:

- Every day at 7am GMT (which is 8am BST) we run evaluations of clickstream, binary and explicit datasets.

- Every weekday at 10am, 12pm, 2pm, 4pm GMT (which is 11am, 1pm, 3pm and 5pm BST) we run evaluations of binary datasets.

A gap of two hours was added between each type of evaluation run to stop them from clashing. Only one evaluation can be run at time, and each dataset runs two evaluations, one for [this month and last month](#This-month-and-last-month). Each evaluation takes approximately 20-25 minutes to run on average.

See [`govuk-helm-charts`][govuk-helm-charts] for the current schedule.

## How evaluations are scored

The evaluation process calculates three primary metrics. These are derived by comparing actual search results at the time of the evaluation run, against the judgement lists. The metrics are calculated at specific "top-k" cutoff levels (top 1, top 3, top 5, and top 10) to assess performance at different positions in the search results.

- **Recall** (docRecall): The fraction of relevant targets in the top-k retrieved out of all relevant targets.

- **Precision** (docPrecision): The fraction of retrieved targets in the top-k that are relevant.

- **NDCG** (docNDCG): The Normalised Discounted Cumulative Gain at k. This measures the ranking quality of the search results.

See [GCP Ruby Client docs][interpret-results] for more details.

The full evaluation results that contain metrics for each individual query are known as "detailed metrics". At the end of the evaluation run, the detailed metrics are uploaded to a [GCP Bucket][evaluation-results-bucket]. These can also be [accessed via BigQuery][evaluation-results-in-big-query].

For each evaluation, aggregate metrics are also calculated by averaging the query level results. These are known as ["quality metrics"][quality-metric-definition]. At the end of the evaluation run, quality metrics are pushed to Prometheus.

### Important metrics

For the binary dataset, we pay particular attention to top-3 Recall. This is an easily interpretible metric that allows us to see whether a particular search result appears in the top 3 results for a given query.

For the clickstream dataset, we pay particular attention to top-10 NDCG. While this can be more challenging to interpret, it allows us to monitor the ranking quality of the first page of search results.

### This month and last month

As part of our evaluations methodology, we have chosen to create new judgement lists at the start of month, and keep them static for the duration of that month. This is so we have an apples-to-apples comparison of our evaluation results over a given month. However, at the start of a new month, we often see a jump in our evaluation metrics because we are comparing search results against different jugdement lists. To help us identify whether this jump shows a underlying change in results quality, or is just because of the change in the judgement lists, we run evaluations for this month and last month to give us continuity across month changes. For example, an evaluation run on 30 November against a 1 November ("this month") judgement list can be compared to an evaluation run on 1 December against a 1 November (now "last month") judgement list more easily than it could be compared to an evaulation run on 1 December against a 1 December ("this month") judgement list.

## How evaluations are monitored

Evaluations are monitored using Sentry, Kibana, Grafana and Prometheus/Alertmanager. For more information see [GOV.UK Site search alerts and monitoring manual][site-search-alerts-and-monitoring-manual].

[govuk-helm-charts]: https://github.com/alphagov/govuk-helm-charts/blob/main/charts/app-config/values-production.yaml#L3085-L3100
[sample-query-sets]: https://docs.cloud.google.com/ruby/docs/reference/google-cloud-discovery_engine-v1beta/latest/Google-Cloud-DiscoveryEngine-V1beta-SampleQuerySet
[evaluations-sequence-mural-board]: https://app.mural.co/t/govukdelivery7534/m/govukdelivery7534/1760104517917/d4a980e06e67cdc94dd224b2fbbea53804459869
[dataform]: https://github.com/alphagov/search-api-v2-dataform
[setup-sample-query-sets-rake-task]: https://github.com/alphagov/search-api-v2-beta-features/blob/main/lib/tasks/quality.rake#L6
[report-quality-metrics-rake-task]: https://github.com/alphagov/search-api-v2-beta-features/blob/main/lib/tasks/quality.rake#L27
[site-search-alerts-and-monitoring-manual]: https://docs.publishing.service.gov.uk/manual/search-alerts-and-monitoring.html
[evaluation-results-bucket]: https://console.cloud.google.com/storage/browser/search-api-v2-integration_vais_evaluation_output;tab=objects?project=search-api-v2-integration&prefix=&forceOnObjectsSortingFiltering=false
[evaluation-results-in-big-query]: https://console.cloud.google.com/bigquery?project=search-api-v2-integration&ws=!1m5!1m4!4m3!1ssearch-api-v2-integration!2svais_evaluation_output!3sresults
[quality-metric-definition]: https://docs.cloud.google.com/ruby/docs/reference/google-cloud-discovery_engine-v1beta/latest/Google-Cloud-DiscoveryEngine-V1beta-Evaluation#Google__Cloud__DiscoveryEngine__V1beta__Evaluation_quality_metrics_instance_
[interpret-results]: https://docs.cloud.google.com/generative-ai-app-builder/docs/evaluate-search-quality#interpret-results
