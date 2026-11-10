# Configuration of the LLM client through environment variables.

testthat::test_that("liminal_chat aborts without an API key", {
  withr::local_envvar(PANAMA_API_KEY = "")

  testthat::expect_error(
    liminal2::liminal_chat(),
    class = "liminal_error_input"
  )
})

testthat::test_that("liminal_chat reads its configuration from env vars", {
  withr::local_envvar(
    PANAMA_API_KEY = "test-key",
    PANAMA_BASE_URL = "https://example.com/v1",
    LIMINAL2_MODEL = "test-model"
  )
  chat <- liminal2::liminal_chat()

  # Constructing a client makes no network call, so these assertions
  # stay offline.
  testthat::expect_true(is.function(chat$chat_structured))
  testthat::expect_equal(
    chat$get_provider()@base_url,
    "https://example.com/v1"
  )
  testthat::expect_equal(chat$get_model_object()@name, "test-model")
})

testthat::test_that("liminal_chat falls back to the Panama defaults", {
  withr::local_envvar(
    PANAMA_API_KEY = "test-key",
    PANAMA_BASE_URL = "",
    LIMINAL2_MODEL = ""
  )

  chat <- liminal2::liminal_chat()

  testthat::expect_equal(
    chat$get_provider()@base_url,
    "https://panama.ixpantia.ixops.ai/v1"
  )
  testthat::expect_equal(chat$get_model_object()@name, "glm-5.3")
})

testthat::test_that("explicit arguments override the environment", {
  withr::local_envvar(
    PANAMA_API_KEY = "test-key",
    PANAMA_BASE_URL = "https://example.com/v1",
    LIMINAL2_MODEL = "test-model"
  )

  chat <- liminal2::liminal_chat(
    model = "other-model",
    base_url = "https://other.example.com/v1",
    api_key = "other-key"
  )

  testthat::expect_equal(
    chat$get_provider()@base_url,
    "https://other.example.com/v1"
  )
  testthat::expect_equal(chat$get_model_object()@name, "other-model")
})
