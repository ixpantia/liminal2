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
