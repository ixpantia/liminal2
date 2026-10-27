testthat::test_that("the package can be loaded", {
  testthat::expect_true(
    requireNamespace("liminal2", quietly = TRUE)
  )
})
