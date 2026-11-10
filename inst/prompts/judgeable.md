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
