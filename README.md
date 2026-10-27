# liminal2



`liminal2` estimates adjudication strength and liminality for predictive
modelling goals. A goal is described by six components:

| Component | Meaning |
|---|---|
| `a1` | Label determinacy across rival definitions |
| `a2` | Temporal stability of the construct |
| `a3` | Predictive multiplicity (Rashomon ambiguity) |
| `a4` | Attainable discriminability |
| `a5` | Oracle strength from an anchored rubric |
| `a6` | Normative consensus from an anchored rubric |

The composite is a weighted geometric mean,
`A = prod(a_k ^ w_k)` and `L = 1 - A`.

The package also provides bootstrap uncertainty, Dirichlet weight
sensitivity, dimensional attribution, leakage audits and five benchmark
scenarios of increasing liminality.

## Installation

This project uses [`rv`](https://a2-ai.github.io/rv-docs/) to manage
dependencies.

```sh
rv sync
R CMD INSTALL .
```

## Example

```r
library(liminal2)

scenario <- generate_scenario("S5", seed = 42)
goal <- assess_goal(
  label_defs = scenario$label_defs,
  X = scenario$X,
  time_index = scenario$time_index,
  y = scenario$y,
  oracle_scores = scenario$rubric$oracle,
  normative_scores = scenario$rubric$normative,
  seed = 42
)
goal
summary(goal)
```

A precomputed component vector can be assessed directly:

```r
a <- c(
  a1 = 0.9, a2 = 0.8, a3 = 0.7,
  a4 = 0.6, a5 = 0.5, a6 = 0.4
)
liminality(a)
```

## Measurement notes

Rashomon ambiguity for binary majority voting is at most 0.5, so `a3` has a
floor of 0.5. Scenario S5 uses a documented observed-outcome proxy for `a4`
because its target is counterfactual. Suggested packages are used only for
tests, cross-checks and development.

## Development

```sh
rv sync
make document
make test
make check
make benchmark
```

`make check` builds the tarball and runs `R CMD check` with `--no-manual`.
The explicit equivalent is:

```sh
R CMD build .
R CMD check --as-cran --no-manual liminal2_0.1.0.tar.gz
```

`R CMD check` must receive a package directory or a built tarball. Running it
with no argument produces `Error: no packages were specified`. If a manual
PDF is not required, keep `--no-manual`; otherwise install a TeX distribution
with `pdflatex`.

## License

MIT (c) 2026 ixpantia.
