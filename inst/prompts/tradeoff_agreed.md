You are scoring one dimension of the liminal space between a business
ask and a data-based solution. The liminal space is the gap between
what the business asked for and what a data-based solution can
deliver. You score only the dimension below, not the overall gap.

## Dimension

Trade-off is agreed - the recovered decision rule is normatively
settled.

Question a business owner can answer: Do the people who bear the cost
of errors accept this threshold?

Question a data scientist can answer: Do stakeholders' loss functions
agree?

Evidence: consensus.

## Scale

Return an integer from 0 to 10. 0 means the dimension poses no
obstacle (the smallest possible liminal space). 10 means the dimension
is maximally obstructed (the largest possible liminal space).

## Anchor cases

Score 2 (small space): The parties who bear the cost of each error
accept the threshold and the error costs.

Score 5 (moderate space): Agreement on the principle exists but not
on the operating point.

Score 8 (large space): The parties disagree on the criterion itself,
or on who bears the cost of each error.

## Calibration

Match the structural condition in the anchor, not the amount of
missing information. The 8 anchor is a specific structural case, not
a default for an ambiguous ask. If the input does not meet that
condition, score below 8. When the evidence falls between 5 and 8,
use 6 or 7; do not jump to 7 or 8 merely because something is
unspecified. Score this dimension on its own evidence: a defect that
belongs to another dimension must not raise this score.

## What counts

Score the agreement among the parties who bear the cost of each
error. A missing cost matrix is evidence of an unresolved trade-off,
not evidence of agreement.

A missing cost matrix alone does not distinguish a descriptive request
from a live decision. If the ask requests indicators with no operating
decision, score 6-7: the trade-off is not yet operative. If the ask
names a live decision with asymmetric error costs, score 8 when no
matrix is supplied, and 9 when a fixed capacity or policy silently
sets the threshold. Score 5 when the principle is agreed but the
operating point is not.

## How to score

1. Is a cost of each error stated? If not, continue to step 2; do not
   apply a fixed floor.
2. Is there a live operating decision? If not, score 6-7.
3. If there is a live decision and no cost matrix, score 8.
4. If a fixed capacity or policy silently sets the threshold, score
   9.
5. If the principle is agreed but the operating point is not, score
   5.
6. If several parties with conflicting loss functions are described
   and no one can arbitrate, score 8-9.
7. Reserve 0-1 for a case where every party accepts the threshold and
   the error costs, and 9-10 for one where the parties disagree on the
   criterion itself.

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
