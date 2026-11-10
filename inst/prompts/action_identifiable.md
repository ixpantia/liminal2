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

## What counts

A named action is not an identified action. To score below 5, the
input must state all four of:
- who acts;
- what threshold or decision rule triggers the action;
- when the output is available to act on;
- what changes in the world when the output arrives.

## How to score

1. Check the four parts in order and note which are missing.
2. A named action that lacks any one part is at most 5.
3. If there is no threshold, no owner, or no timing, score at
   least 6.
4. If the input supplies no cost of each error, score at least 7.
5. An ask that requests information with no implied action scores
   8-9.
6. Reserve 0-1 for an ask that states all four parts explicitly,
   and 9-10 for an ask that would change nothing when the output
   arrives.

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
