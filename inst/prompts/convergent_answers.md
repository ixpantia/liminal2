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

## Calibration

Match the structural condition in the anchor, not the amount of
missing information. The 8 anchor is a specific structural case, not
a default for an ambiguous ask. If the input does not meet that
condition, score below 8. When the evidence falls between 5 and 8,
use 6 or 7; do not jump to 7 or 8 merely because something is
unspecified. Score this dimension on its own evidence: a defect that
belongs to another dimension must not raise this score.

## What counts

Count only choices that a competent analyst could defend to a peer
and that would change the decision, the ranking, or the set of cases
classified positive. Different hyperparameters of the same model
family are not rival answers, and neither are purely cosmetic
differences in implementation.

Different methods that produce the same decision or the same ranking
are not divergent answers. The score is the share of decisions that
flip, not the number of defensible methods.

## How to score

1. Identify the decision or classification the output will drive. If
   the ask is descriptive and names no decision, use the ranking or
   classification that the requested output would produce.
2. Enumerate only choices that would change that decision, ranking or
   positive set materially. A different method that reproduces the
   same ordering is not a rival answer.
3. Estimate the share of cases that would flip:
   - score 2 when near-equal approaches produce nearly identical
     decisions or rankings;
   - score 5 when they agree on most cases but flip a non-trivial
     minority;
   - score 8 when several near-equal approaches flip a substantial
     share and nothing in the input ranks them.
4. If the ask requests multiple descriptive indicators, different
   indicators are not rival answers to one decision. Score agreement
   on the requested quantities, not on an unasked downstream decision.
5. Do not raise the score merely because several methods are
   defensible. Method count is not decision disagreement. There is no
   floor: a case with one stable ranking can score 2 even when the
   method is not specified.
6. Reserve 0-1 for a case where near-equal approaches are known to
   agree, and 9-10 for one where several near-equal approaches exist
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
