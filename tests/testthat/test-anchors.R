test_that("the anchor table is ordered and complete", {
  anchors <- liminal_anchors()
  expect_equal(nrow(anchors), 6L)
  expect_true(all(anchors$A_lower < anchors$A_upper))
  expect_true(all(anchors$L_lower < anchors$L_upper))
  expect_true(all(abs(anchors$A_upper + anchors$L_lower - 1) < 1e-8))
  expect_true(all(abs(anchors$A_lower + anchors$L_upper - 1) < 1e-8))
})

test_that("case lookup returns bands and supports partial matching", {
  result <- liminal_case("causal")
  expect_equal(result$case, "causal_counterfactual")
  expect_true(result$L_band[["lower"]] >= 0.5)
  expect_error(liminal_case("unknown-case"), "arg")
})
