# Evaluations

## Schedule

Every day at 7am GMT (which is 8am BST) we run evaluations of clickstream, binary and explicit datasets.

Every weekday at 10am, 12pm, 2pm, 4pm GMT (which is 11am, 1pm, 3pm and 5pm BST) we run evaluations of binary datasets.

The evaluations are run via crontasks configured in [`govuk-helm-charts`][govuk-helm-charts]

## Clickstream

Judgement lists generated from the results users click on when using site search, with results given a score of 0-3 depending on how many clicks they get.

For assessing relevance of search results at scale.

The clickstream judgements are evaluated for a whole query, with multiple targets, and NDCG@10 scoring the whole first page of 10 results. (The number of targets varies depending on what's been clicked above the threshold, sometimes less than 10 and sometimes more than 10, which will affect the scores, but NDCG also takes into account the positions.)

## Binary

List of search queries with results that have a score of 3, indicating that they’re a perfect match for the query.

For assessing whether any results that should appear are missing - identifying relevance issues quickly.

Binary judgements should be evaluated for individual query-target pairs, with the recall metric, so for each query-target it's either there or it's not (in the top-k). Which is much easier to interpret, so we can quickly find out why a score has dropped.

[govuk-helm-charts]: https://github.com/alphagov/govuk-helm-charts/blob/main/charts/app-config/values-production.yaml#L3085-L3100
