# liminal2 0.3.0

* Prompt version `1.1.0`: every dimension template now carries a **scope
  guard** (the evidence that belongs to the dimension and the evidence it
  must not absorb from another dimension) and an **ordered scoring
  procedure** (quote the evidence, match the closest anchor, apply the
  dimension's partial-credit rules, interpolate, and reserve the extremes
  for structural cases). The anchor rubrics at 2, 5 and 8 and the
  direction statement are unchanged. Scores produced under `1.0.0` and
  `1.1.0` are not poolable; the prompt version is recorded in every
  result and every benchmark row.
* Add the methodology vignette, which documents the evolution from a
  naive single-shot judge to the current design and measures the effect
  of `1.1.0` against the frozen `1.0.0` benchmark.
* Benchmark caches now record `prompt_version` per row. The `1.0.0` run
  is frozen in
  `inst/extdata/model-comparison-results-v1.0.0.parquet`; the live cache
  always holds the current version.

# liminal2 0.2.0

* Add `assess_liminal_space()`: scores a business ask (and optional
  situation) through seven dimension-specific prompts with an LLM and
  aggregates the scores into the size of the liminal space. The seven
  calls run concurrently by default; failed dimensions are retried
  sequentially with backoff.
* Add `liminal_chat()` for the OpenAI-compatible Panama endpoint
  (model `glm-5.3` by default, temperature 0), configured entirely
  through the `PANAMA_API_KEY`, `PANAMA_BASE_URL` and `LIMINAL2_MODEL`
  environment variables. ellmer builds the client; the scoring
  transport itself runs on `httr2`, because the gateway labels its
  JSON responses `text/plain`, which ellmer's strict content-type
  check rejects.
* Add `liminal_prompts()` and `liminal_dimensions()`: the seven
  versioned prompt templates ship in `inst/prompts/` with fixed anchor
  rubrics that are independent of the test scenarios, keeping scores
  comparable across business cases.
* Implement `measure_liminal_space()` and `default_weights()` as
  specified by the test suite: `L = 1 - prod(scores ^ weights)` with
  full input validation and informative error classes.
* Add the model-comparison vignette, which benchmarks every model
  available on the endpoint over the six test scenarios and caches the
  raw scores, token usage and cost in
  `inst/extdata/model-comparison-results.parquet`.

# liminal2 0.1.0

* Initial development version.
