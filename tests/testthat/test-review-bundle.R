test_that("responseTheme reads the designSpec tag, misc-falls-back with a warning", {
  # responseTheme only reads designSpec$responses[[r]]$theme, so a plain list is a faithful,
  # core-free fixture (viz must not depend on spadesBioInfo.core). p_C has no theme -> misc.
  ds <- list(responses = list(Shannon = list(scope = "bySubset", theme = "diversity"),
                              p_C     = list(scope = "whole")))
  expect_equal(responseTheme(ds, "Shannon"), "diversity")
  expect_warning(expect_equal(responseTheme(ds, "p_C"), "misc"))
})

test_that("writeReviewLayout writes review/<dir>/<leaf>.png + a named index", {
  skip_if_not_installed("patchwork")
  style <- projectPlotStyle()
  fig <- ggplot2::ggplot(data.frame(x=1,y=1), ggplot2::aes(x,y)) + ggplot2::geom_point()
  out <- file.path(tempdir(), "rb"); unlink(out, recursive = TRUE)
  w <- writeReviewLayout(setNames(list(fig), "diversity/Shannon__ITS__whole"), out, style,
                         dims = c(6,4), indexName = "_index_ml")
  expect_true(file.exists(file.path(out, "review", "diversity", "Shannon__ITS__whole.png")))
  expect_true(file.exists(file.path(out, "review", "diversity", "_index_ml.png")))
})
