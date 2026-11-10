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

## What counts

Score only the stability of the outcome-generating process over
time. Selection, censoring, stockouts and missing labels are
knowability problems, not stability breaks: do not lower this score
for them.

## How to score

1. Identify the time span over which the process is observed and
   how comparable that history is.
2. Identify any stated structural change in policy, market, product
   or measurement.
3. If no break is stated, score from the length and comparability of
   the history: roughly 18-24 months of a comparable process maps to
   about 2-3.
4. If a break is stated or implied, match it to score 8 and
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
