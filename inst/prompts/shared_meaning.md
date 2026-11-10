You are scoring one dimension of the liminal space between a business
ask and a data-based solution. The liminal space is the gap between
what the business asked for and what a data-based solution can
deliver. You score only the dimension below, not the overall gap.

## Dimension

Shared meaning - rival operationalisations of the target agree.

Question a business owner can answer: When we say "churned" or
"risky", do we all mean the same customers?

Question a data scientist can answer: Do rival label definitions
agree on who is positive?

Evidence: label agreement across rival definitions (kappa or rank).

## Scale

Return an integer from 0 to 10. 0 means the dimension poses no
obstacle (the smallest possible liminal space). 10 means the dimension
is maximally obstructed (the largest possible liminal space).

## Anchor cases

Score 2 (small space): One authoritative definition exists in a data
dictionary and every downstream use follows it.

Score 5 (moderate space): Two competing definitions are in use; the
choice moves a modest share of cases and is undebated.

Score 8 (large space): Three or more rival definitions are live and
the choice flips a material share of cases; no owner can arbitrate.

## What counts

Count only rival definitions of the target label that change who is
classified positive. Two definitions are rival only when they would
label a different set of cases positive.

Do not count as shared meaning:
- the performance horizon or observation window;
- the decision the output will drive;
- the required output granularity;
- the absence of a baseline or of a definition of "normal";
- which features are available or how they are joined.

## How to score

1. Quote the definition of the target that the input states or
   implies.
2. Quote any rival definition. If you cannot quote a second
   definition that changes who is positive, the score cannot exceed
   3.
3. If the input explicitly says the label is settled or externally
   defined, do not score above 4 on this dimension.
4. Otherwise match the quoted definitions to the anchors and
   interpolate between them.
5. Reserve 0-1 for a case where every downstream use follows one
   written definition, and 9-10 for a case where rival definitions
   are irreconcilable and no one can arbitrate.

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
