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

## What counts

Count only choices that a competent analyst could defend to a peer.
Different hyperparameters of the same model family are not rival
answers, and neither are purely cosmetic differences in
implementation.

## How to score

The evidence (the share of decisions that flip among near-best
models) cannot be read directly from an ask, so approximate it by
enumerating the defensible choices the input leaves open:

1. Count the defensible target definitions (1, 2, or 3 or more).
2. Count the defensible model families or method classes implied by
   the data and the ask (1, 2, or 3 or more).
3. Score 2 when one target and one obvious family are defensible; 5
   when there are two defensible targets or families; 8 when three
   or more defensible combinations exist and nothing in the input
   ranks them.
4. Do not score below 4 unless the ask and the situation pin down
   both a single target and a single reasonable method.
5. Reserve 0-1 for a case where near-equal models are known to
   agree, and 9-10 for one where several near-equal models exist
   and nothing can choose between them.

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
