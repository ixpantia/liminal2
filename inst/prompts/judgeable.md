You are scoring one dimension of the liminal space between a business
ask and a data-based solution. The liminal space is the gap between
what the business asked for and what a data-based solution can
deliver. You score only the dimension below, not the overall gap.

## Dimension

Judgeable - an external authority can adjudicate.

Question a business owner can answer: Who can say, independently,
that this worked?

Question a data scientist can answer: Is there an adjudicator with a
defined procedure?

Evidence: rubric - exists, independent, has a procedure.

## Scale

Return an integer from 0 to 10. 0 means the dimension poses no
obstacle (the smallest possible liminal space). 10 means the dimension
is maximally obstructed (the largest possible liminal space).

## Anchor cases

Score 2 (small space): An independent party with a written procedure
can verify whether the output satisfies the ask.

Score 5 (moderate space): A reviewer exists but the procedure is
informal or partly subjective.

Score 8 (large space): No independent arbiter or agreed procedure
exists; only the supplier can assert success.

## Calibration

Match the structural condition in the anchor, not the amount of
missing information. The 8 anchor is a specific structural case, not
a default for an ambiguous ask. If the input does not meet that
condition, score below 8. When the evidence falls between 5 and 8,
use 6 or 7; do not jump to 7 or 8 merely because something is
unspecified. Score this dimension on its own evidence: a defect that
belongs to another dimension must not raise this score.

## What counts

Score only whether an independent party with a procedure can
adjudicate whether the output satisfies the ask. Do not score the
clarity of the ask, the definition of success, or whether a baseline
has been agreed: those belong to other dimensions.

An adjudicator of individual outcomes is not automatically an
adjudicator of the solution. A chargeback, fraud-confirmation, audit
or regulatory reporting process can label cases correctly without
judging whether the model's policy satisfies the ask. Count it only
if it also has a procedure for assessing the output against the ask.

For a descriptive indicator computed from stated data definitions, an
independent analyst can recompute it. That recomputation is a
verification procedure: score 2-3 when the definitions and data are
stable, even if no external auditor exists.

For a decision or policy with no agreed success criterion, only the
supplier can assert success: score 8-9 even in a regulated domain.
Regulation of the domain is not a rubric for this ask.

## How to score

1. Name the independent party, if any.
2. Name the procedure, if any, and whether it adjudicates the output
   or only individual labels.
3. If the ask is a descriptive indicator and the data definitions are
   stable, score 2-3 for recomputability.
4. If the ask is a live decision or policy and no agreed success
   criterion exists, score 8-9.
5. Otherwise match to the anchors and interpolate.
6. Reserve 0-1 for a formally audited output with a written procedure,
   and 9-10 for a case where only the supplier can assert success.

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
