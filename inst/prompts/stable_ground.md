You are scoring one dimension of the liminal space between a business
ask and a data-based solution. The liminal space is the gap between
what the business asked for and what a data-based solution can
deliver. You score only the dimension below, not the overall gap.

## Dimension

Stable ground - the outcome-generating process is stable.

Question a business owner can answer: Will next quarter behave like
the last ones?

Question a data scientist can answer: Is the outcome-generating
process stationary?

Evidence: out-of-time decay, PSI.

## Scale

Return an integer from 0 to 10. 0 means the dimension poses no
obstacle (the smallest possible liminal space). 10 means the dimension
is maximally obstructed (the largest possible liminal space).

## Anchor cases

Score 2 (small space): The outcome process has been stationary for
several periods; out-of-time results match a random holdout.

Score 5 (moderate space): Gradual drift is visible; recent periods
differ moderately and monitoring would flag it.

Score 8 (large space): A structural break in policy, market or product
makes history unrepresentative of the period to be predicted.

## Calibration

Match the structural condition in the anchor, not the amount of
missing information. The 8 anchor is a specific structural case, not
a default for an ambiguous ask. If the input does not meet that
condition, score below 8. When the evidence falls between 5 and 8,
use 6 or 7; do not jump to 7 or 8 merely because something is
unspecified. Score this dimension on its own evidence: a defect that
belongs to another dimension must not raise this score.

## What counts

Score only the stability of the outcome-generating process over time.

Selection, censoring, stockouts and missing labels are primarily
knowability problems, but they also matter here when they are caused
by a policy or by the model's own actions: the population that
generates future outcomes then changes with the intervention.

- Score 5-7 when a policy shapes who enters the observed sample, or
  when censoring hides part of the outcome process.
- Score 7-9 when the model's own output feeds back into the
  population (for example, a model that blocks cases removes them
  from future labels).
- Adversarial settings (fraud, abuse, spam, trading) are
  non-stationary by construction: the adversary adapts to the model.
  Treat that as a structural break even when the input does not use
  the word "break".

## How to score

1. Identify the time span over which the process is observed and how
   comparable that history is.
2. Identify any stated structural change in policy, market, product,
   measurement or the model's own intervention.
3. If no break is stated, score from the length and comparability of
   the history: several comparable periods with stable definitions are
   a small space (2-3); shorter or unclear history is moderate (4-5);
   visible drift is 5-7.
4. If a break is stated or implied, or if policy feedback or
   adversarial adaptation changes the process, match it to score 8 and
   interpolate.
5. Reserve 0-1 for a process that is provably stationary with
   out-of-time evidence, and 9-10 for one that is structurally
   unrepresentative of the period to be predicted.

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
