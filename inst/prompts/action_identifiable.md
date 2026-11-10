You are scoring one dimension of the liminal space between a business
ask and a data-based solution. The liminal space is the gap between
what the business asked for and what a data-based solution can
deliver. You score only the dimension below, not the overall gap.

## Dimension

Action is identifiable - the decision rule is recoverable from the
ask.

Question a business owner can answer: What will we do differently
when we see the output?

Question a data scientist can answer: Can the decision rule be
recovered from the ask?

Evidence: recoverability.

## Scale

Return an integer from 0 to 10. 0 means the dimension poses no
obstacle (the smallest possible liminal space). 10 means the dimension
is maximally obstructed (the largest possible liminal space).

## Anchor cases

Score 2 (small space): The ask states who does what, at which
threshold, when the output appears.

Score 5 (moderate space): The action is implied but its threshold,
owner or timing must still be negotiated.

Score 8 (large space): The ask requests information with no implied
action; nothing would change when the output arrives.

## Calibration

Match the structural condition in the anchor, not the amount of
missing information. The 8 anchor is a specific structural case, not
a default for an ambiguous ask. If the input does not meet that
condition, score below 8. When the evidence falls between 5 and 8,
use 6 or 7; do not jump to 7 or 8 merely because something is
unspecified. Score this dimension on its own evidence: a defect that
belongs to another dimension must not raise this score.

## What counts

A named action is not an identified action. To score below 5, the
input must state all four of:
- who acts;
- what threshold or decision rule triggers the action;
- when the output is available to act on;
- what changes in the world when the output arrives.

The cost of each error belongs to `tradeoff_agreed`. A missing cost
matrix is not evidence that the action is unidentified; do not raise
this score for it.

A request for information for an implied monitoring or review use is
not the same as no action. If the output would be reviewed and could
change a later decision, but no threshold, owner or timing is stated,
score 6-7. Reserve 8-9 for an information request with no implied use
at all, where nothing would change when the output arrives.

## How to score

1. Check the four parts in order and note which are missing.
2. If all four are explicit, score 0-2.
3. If an action is named and at least two parts are explicit, score
   3-5.
4. If an action is named but one or more of threshold, owner or timing
   is missing, score 6-7.
5. If the ask is a pure information request with no implied use, score
   8-9. If it has an implied monitoring or review use but no decision
   rule, score 6-7.
6. Interpolate between the anchors. Reserve 0-1 and 9-10 for the
   anchor extremes.

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
