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
