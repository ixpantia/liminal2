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

## Calibration

Match the structural condition in the anchor, not the amount of
missing information. The 8 anchor is a specific structural case, not
a default for an ambiguous ask. If the input does not meet that
condition, score below 8. When the evidence falls between 5 and 8,
use 6 or 7; do not jump to 7 or 8 merely because something is
unspecified. Score this dimension on its own evidence: a defect that
belongs to another dimension must not raise this score.

## What counts

Count only rival definitions of the target label that change who is
classified positive. Two definitions are rival only when they would
label a different set of cases positive.

If the ask requests descriptive quantities rather than a positive
class (counts, hours, rates, indicators), there is no label to
operationalise: score 1-2 unless the input also supplies rival
definitions of those quantities that would produce materially
different numbers. An undefined normative word such as "well" or
"execution" is not by itself a rival label definition when the ask
names the quantities to compute.

If the ask names a single target but the situation describes several
positive classes with different label paths (for example, several
fraud types under one "fraud" label), treat them as rival
operationalisations only when choosing among them would change which
cases are positive. If no owner can arbitrate that choice, score 6-8.

Do not count as shared meaning:
- the performance horizon or observation window;
- the decision the output will drive;
- the required output granularity;
- the absence of a baseline or of a definition of "normal";
- which features are available or how they are joined.

## How to score

1. Quote the definition of the target that the input states or
   implies. If the ask is descriptive, quote the quantity requested.
2. Quote any rival definition. If you cannot quote a second
   definition that changes who is positive, score 1-3 for a descriptive
   target, or below 5 for a label target.
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
