test_that("scenario registry has five ordered scenarios", {
  registry <- scenario_registry()
  expect_equal(registry$id, paste0("S", 1:5))
  expect_true(all(diff(registry$target_L) > 0))
  expect_true(all(registry$target_A + registry$target_L == 1))
})

test_that("scenario generators return the documented structure", {
  scenario <- generate_scenario("S5", seed = 42)
  expect_named(
    scenario,
    c(
      "X", "y", "time_index", "label_defs",
      "rubric", "truth", "metadata"
    )
  )
  expect_equal(nrow(scenario$X), scenario$metadata$n)
  expect_length(scenario$y, scenario$metadata$n)
  expect_equal(ncol(scenario$label_defs), 3L)
  expect_true(all(
    unlist(scenario$rubric) %in% c(0, 0.25, 0.5, 0.75, 1)
  ))
  expect_equal(scenario$truth$target_A + scenario$truth$target_L, 1)
})

test_that("scenario generation is deterministic", {
  first <- generate_scenario("S5", seed = 7)
  second <- generate_scenario("S5", seed = 7)
  expect_identical(first$X, second$X)
  expect_identical(first$y, second$y)
  expect_identical(first$label_defs, second$label_defs)
})

test_that("scenario variants modify the expected object", {
  leak <- generate_scenario("S3_leak", seed = 42)
  expect_true("label_leak" %in% names(leak$X))
  expect_equal(leak$metadata$variant, "leak")

  null <- generate_scenario("S1_null", seed = 42)
  expect_equal(null$metadata$variant, "null")

  shuffled <- generate_scenario("S4_shuffled", seed = 42)
  expect_equal(shuffled$metadata$variant, "shuffled")
})

test_that("unknown scenarios error", {
  expect_error(generate_scenario("S9", seed = 1), "must be one of")
  expect_error(
    generate_scenario("S1", seed = 1, variant = "other"),
    "arg"
  )
})
