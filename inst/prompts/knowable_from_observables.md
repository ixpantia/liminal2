You are scoring one dimension of the liminal space between a business
ask and a data-based solution. The liminal space is the gap between
what the business asked for and what a data-based solution can
deliver. You score only the dimension below, not the overall gap.

## Dimension

Knowable from what we can see - the target is attainable from
observable features.

Question a business owner can answer: Is the answer visible in
anything we can observe?

Question a data scientist can answer: Is the target attainable from
observable features?

Evidence: skill ceiling against required skill.

## Scale

Return an integer from 0 to 10. 0 means the dimension poses no
obstacle (the smallest possible liminal space). 10 means the dimension
is maximally obstructed (the largest possible liminal space).

## Anchor cases

Score 2 (small space): The target is a near-deterministic function of
available, timely features.

Score 5 (moderate space): Available features carry signal but leave
substantial irreducible variance.

Score 8 (large space): The target is dominated by latent or post-hoc
causes; achievable skill is near the base rate.

## What counts

Score the attainability of the target from the data-generating
process the input describes. Lower the score (larger liminal space)
when:
- the outcome is latent or observed only after the decision;
- the training sample is selected by a policy that depends on the
  outcome (selection, truncation, approval-constrained portfolios);
- outcomes are censored or stockouts hide demand;
- features are missing, delayed, or only joinable through a proxy.

Coverage and join gaps count: a target that is recorded against a
different unit than the ask requires is not directly observable.

## How to score

1. Is the outcome itself observed, and observed for a representative
   sample? If it is selected or censored, score at least 6.
2. Are the features that drive it available at decision time? If
   not, score at least 6.
3. If both hold, match to the anchors and interpolate.
4. Reserve 2 for genuinely near-deterministic targets; most real
   targets are at least 3.
5. Reserve 9-10 for a target dominated by latent causes, where
   achievable skill is near the base rate.

## Input

Business ask:

```
{{ask}}
```

Situation and context:

```
{{situation}}
```

## Output

Return only the integer. No explanation, no units, no decimals.
