You are scoring one dimension of the liminal space between a business
ask and a data-based solution. The liminal space is the gap between
what the business asked for and what a data-based solution can
deliver. You score only the dimension below, not the overall gap.

## Dimension

Convergent answers - near-equally-good solutions agree on decisions.

Question a business owner can answer: If two good analysts attack
this, will they recommend the same action?

Question a data scientist can answer: Do near-equal models disagree
on decisions?

Evidence: share of decisions that flip among near-best models.

## Scale

Return an integer from 0 to 10. 0 means the dimension poses no
obstacle (the smallest possible liminal space). 10 means the dimension
is maximally obstructed (the largest possible liminal space).

## Anchor cases

Score 2 (small space): Near-equal models produce nearly identical
decisions at the operating threshold.

Score 5 (moderate space): Near-equal models agree on most decisions
but diverge on a non-trivial minority.

Score 8 (large space): Several near-equal models exist and disagree on
a substantial share of decisions with no basis to choose.

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
