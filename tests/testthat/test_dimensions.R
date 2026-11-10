# The dimension registry.

testthat::test_that("the dimension registry is canonical", {
  registry <- liminal2::liminal_dimensions()

  testthat::expect_s3_class(registry, "tbl_df")
  testthat::expect_equal(nrow(registry), 7L)
  testthat::expect_identical(registry$name, liminal_dimension_names)
  testthat::expect_false(anyNA(registry))
  testthat::expect_true(
    all(vapply(registry, function(column) all(nzchar(column)), logical(1)))
  )
})

testthat::test_that("the registry carries the documented columns", {
  registry <- liminal2::liminal_dimensions()

  testthat::expect_identical(
    names(registry),
    c(
      "name",
      "title",
      "formal_name",
      "question_business",
      "question_data_scientist",
      "evidence",
      "prompt_version"
    )
  )
  testthat::expect_true(all(registry$prompt_version == "1.0.0"))
})
