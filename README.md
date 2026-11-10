# liminal2 <img src="man/figures/logo.png" align="right" height="200" alt="liminal2 logo" />

<!-- Describe the new implementation here. -->

## Definition

A **Liminal space** refers to a transitional, in-between place — a threshold.
The word comes from the Latin *limen*, meaning "threshold." Liminal spaces are
the transitional zones between distinct phases of development where
transformation actively occurs. It was used by the ethnographer van Gennep
(1909) to describe the rituals people have devised for transition phases
between two states, such as childhood and adulthood, and this way of looking at
transitions has since been used in many papers in management and organization
studies (Soderlund & Borg 2017).

If we look at the steps of finding and implementing a data based solution for a
business ask the concept of liminal space may be a helpful way to think about
the different transitions that are occurring. These transitions between one
state and the next are shown in the next table, with a proposed name for the
liminal space between them. The resulting state is the starting state of the
next transition. 

| state 1 | liminal space | state 2 |
|---|---|---|
| business needs externalized | translation | requirements and hypotheses formalized |
| requirements and hypotheses formalized | experimentation | methodology defined |
| methodology defined | realization | prototype built |
| prototype built | implementation | augmented intelligence available to users |
| augmented intelligence available to users | activation | decisions and actions are data driven |
| decisions and actions are data driven | observation | improvement registered for continous improvement |

One can imagine a funnel narrowing from top to bottom as a progression through
decreasing *context size*, decreasing *complexity* within a narrowing *solution
space*.

The states in Table 1 are ot mere handoff points but dynamic spaces where there
is iteration between one state and the other. Formulating requirements and
hypotheses often requiere a review of the definitions and assumptions
underlying the business needs, for example. There are no straight lines within
those spaces, a a first attempt to characterise them was by outlining:

 - Definitional ambiguity
 - Target clarity
 - Technical difficulty
 - Statistical difficulty
 - Data readiness

These seem a natural way of coming to grips with the liminality we face when
developming data based solutions for business needs but as we shall see, these
are not the best dimensions to use to give a value to the liminal space between
each of the states. We need a better way to measure the extent of this liminal
space because understanding and managing these liminal spaces is essential
because this is where the most crucial work happens—where abstract ideas become
concrete solutions, where assumptions are tested and refined, and where
potential failures can be caught before they become costly problems. 

liminal2 helps teams assess the size of these liminal spaces. Eventually, as we
are better able to assess the size, we plan to use this indicator to develop
methodology that will use LLMs to provide a context-aware breakdown of project
complexity to anticipate specific challenges and opportunities that emerge when
you're "betwixt and between" development states. Rather than treating these
transitions as gaps to rush through, we recognize them as valuable spaces for
deliberate transformation and creative problem-solving.

### implementation

The liminal2 packages implements measures to assess the size of the liminal
space between a business ask and the best fitting analytical solution (a.k.a.
AI) . The ask is the question or need as the business states it (a decision to
be improved, a risk to be reduced, an outcome to be anticipated). And the
solution the analytics or AI team offers in response (and indicator or set of
metrics, a machine learning model, a clasification score, a dashboard, or AI
solutions based on rules, prediction, optimization or generative AI). 

The liminal space is a characteristic of the relation between the ask and the
solution. It is the gap across which the first must be *transformed* into the
second and back again — and it is liminal precisely because that transformation
is where the project execution lives: the ask is stated in the language of
consequences, the solution in the language of operationalised targets, and
nothing in either artifact guarantees that the second answers the first. 

Liminality is the measured bilateral distance of
that gap $L = 1 - A$, where $A$ is the weighted geometric mean of seven
conditions on the ask–solution pair:

 1. whether rival operationalisations of the target agree 
 2. whether the process generating the ask's outcome is stable
 3. whether near-equally-good solutions disagree 
 4. whether the target is attainable from observable features 
 5. whether an external authority can adjudicate whether the solution satisfies
    the ask
 6.  wether the decision rule is recoverable from the ask
 7. and whether the decision rule implied by the ask is normatively settled 

Condition 6 and 7 may not immediately obvious, so we explain it in more detail
here. Every business ask, once you look past its wording, implies a decision: a
mapping from information to action. "Reduce churn" implies intervene on some
customers; "anticipate demand" implies staff, stock, or price according to the
forecast; "flag risky loans" implies decline, price up, or refer to a human. A
model produces a quantity — a probability, a ranking, a forecast. Something has
to convert that quantity into an action. That converter is the decision rule,
and it is almost never written down in the ask; it has to be reconstructed.

Condition 6 and 7 asks two things about that reconstructed rule:

 - Is it elicitable? Can the rule be recovered from the ask at all, or does the
   ask imply no action (a "tell me something interesting" request)?
 - Is it normative consensus once elicited? Do the parties with authority over
   the outcome agree that this rule — this threshold, this trade-off between
   false positives and false negatives, this allocation of who bears the cost of
   each error — is the one that should be applied?

So "normatively settled" means settled as a matter of what should be done, not
as a matter of what can be computed. A threshold can be perfectly computable
and still normatively unsettled: you can estimate the churn probability at
which intervention pays for itself to three decimal places, and still have no
agreement that profit maximisation is the right criterion, or that the
customers it identifies are the ones who should get the offer.

## The dimensions of liminal space

The seven conditions above can be used as dimensions on wich we measure liminal space. To make these dimensions easier to work with, we translated the above 7 dimensions to plain language and added some examples that of questions and evidence. These are listed in Table 2

nr | Plain-language name | Formal name | Question a business owner can answer | Question a data scientist can answer | Evidence
-- | -- | -- | -- | -- | --
1 | Shared meaning | Rival operationalisations of the target agree | When we say "churned" or "risky", do we all mean the same customers? | Do rival label definitions agree on who is positive? | Label agreement across rival definitions (κ or rank)
2 | Stable ground | Outcome-generating process is stable | Will next quarter behave like the last ones? | Is the outcome-generating process stationary? | Out-of-time decay, PSI
3 | Convergent answers | Near-equally-good solutions agree on decisions (inverted from source) | If two good analysts attack this, will they recommend the same action? | Do near-equal models disagree on decisions? | Share of decisions that flip among near-best models
4 | Knowable from what we can see | Target is attainable from observable features | Is the answer visible in anything we can observe? | Is the target attainable from observable features? | Skill ceiling against required skill
5 | Judgeable | An external authority can adjudicate | Who can say, independently, that this worked? | Is there an adjudicator with a defined procedure? | Rubric: exists, independent, has a procedure
6 | Action is identifiable | The decision rule is recoverable from the ask | What will we do differently when we see the output? | Can the decision rule be recovered from the ask? | Recoverability
7 | Trade-off is agreed | The recovered decision rule is normatively settled | Do the people who bear the cost of errors accept this threshold? | Do stakeholders' loss functions agree? | Consensus

### Test scenarios

To test the package we defined 6 test scenarios. During their definition we used the 5 characteristics that we intuitively assigned to the ambiguity of liminal spaces when we started out. The details are avaible in the tests/scenarios folder, with the statemen of ask and context and the expected outcomes

In summary these are the following, and they include a scenario where the size of the liminal space goes towards infinity - a business asks that seems to make sense, but that cannot be answered with the data and methodology available.


Scenario | Technical difficulty | Statistical difficulty | Definitional ambiguity | Target clarity (inv.) | Data readiness (inv.)
-- | -- | -- | -- | -- | --
Execution indicators (tasks opened/closed, hours by person and project), complete in-house data | 2 | 2 | 2 | 1 | 1
Contractual churn model, subscription business; cancel event recorded, 24 months history | 4 | 4 | 3 | 3 | 3
Credit risk scorecard, regulated lender; 90-DPD default, bureau + internal data | 5 | 6 | 4 | 4 | 4
Intermittent demand forecasting, 1,800 SKU × 50,000 customers, daily; business use undecided | 7 | 8 | 5 | 5 | 5
Real-time adversarial decisioning (fraud / AML triage), sub-200 ms, chargeback labels 60–120 days late | 9 | 9 | 7 | 8 | 7
Per-customer price elasticity from a completed single-date nationwide price change — no holdout, no control market, no historical price variation | 2 | 10 | 7 | 10 | 2


## Installation

This project uses [`rv`](https://a2-ai.github.io/rv-docs/) to manage
dependencies.

```sh
rv sync
R CMD INSTALL .
```

### Development

```sh
rv sync
make document
make test
make check
```

`make check` builds the tarball and runs `R CMD check` with `--no-manual`.

Live API calls (the integration tests and
`data-raw/model_comparison.R`) need a Panama key. Copy `.env.example` to
`.env`, fill in `PANAMA_API_KEY`, and keep the file local: `.env` is
gitignored and excluded from the build. An exported
`PANAMA_API_KEY` takes precedence over the file.

## License

MIT (c) 2026 ixpantia.
