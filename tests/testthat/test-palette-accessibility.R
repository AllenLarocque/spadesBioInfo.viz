oldStudy <- c("darkolivegreen", "darkolivegreen3", "tan", "tan3", "chocolate4")

test_that("the default palettes pass their accessibility checks", {
  s <- projectPlotStyle()
  expect_no_error(assertPaletteAccessible(qualitativePalette(s, letters[1:8]), "qualitative"))
  expect_no_error(assertPaletteAccessible(sequentialPalette(s, 5), "sequential"))
  expect_no_error(assertPaletteAccessible(divergingPalette(s, 7), "diverging"))
})

test_that("the checker catches bad palettes", {
  r <- checkPalette(oldStudy, "sequential")
  expect_true(any(!r$pass))
  expect_true(any(r$vision == "greyscale" & !r$pass))
  q <- checkPalette(c("#CC0000", "#009900"), "qualitative")  # equal-lightness red/green (pure red/green differ in L*, deutan dE 28)
  expect_true(any(q$vision == "deutan" & !q$pass))
  expect_error(assertPaletteAccessible(oldStudy, "sequential"), "greyscale")
  expect_s3_class(checkPalette("notacolour", "qualitative"), "data.frame")
})

test_that("non-monotonic sequential, plain ramps and identical mirrored arms are flagged", {
  r <- checkPalette(c("#000000", "#FFFFFF", "#444444"), "sequential")
  expect_false(r$pass[r$check == "L_monotonic"])
  # a plain sequential ramp is not diverging: the middle is not the lightness extremum
  g <- checkPalette(c("#000000", "#777777", "#EEEEEE"), "diverging")
  expect_false(g$pass[g$check == "L_monotonic_right"])
  expect_true(g$pass[g$check == "L_monotonic_left"])
  expect_error(assertPaletteAccessible(c("#000000", "#777777", "#EEEEEE"), "diverging"),
               "L_monotonic_right")
  # identical mirrored pairs: arms fine, but the two arms are indistinguishable
  m <- checkPalette(c("#000000", "#555555", "#FFFFFF", "#555555", "#000000"), "diverging")
  expect_true(all(m$pass[grepl("^L_", m$check)]))
  expect_true(all(!m$pass[m$check == "mirrored_pair_delta_e"]))
})

test_that("paletteDistinctness reports 5 visions; Okabe-Ito normal is the measured value", {
  d <- paletteDistinctness(projectPlotStyle()$qualitative)
  expect_equal(nrow(d), 5)
  expect_named(d, c("vision", "min_delta_e"))
  expect_equal(d$min_delta_e[d$vision == "normal"], 26.4, tolerance = 0.1 / 26.4)
})

test_that("simulateVision returns hex of the same length", {
  expect_equal(simulateVision(c("red", "blue"), "normal"), toupper(c("#FF0000", "#0000FF")))
  expect_length(simulateVision(c("red", "blue"), "deutan"), 2)
  expect_error(simulateVision("red", "bogus"))
})

test_that("groupPalette(ordered = TRUE) uses the sequential palette for unnamed levels", {
  s <- projectPlotStyle()
  expect_equal(groupPalette(s, c("a", "b", "c"), ordered = TRUE),
               setNames(sequentialPalette(s, 3), c("a", "b", "c")))
  expect_equal(groupPalette(s, c("a", "b", "c")), qualitativePalette(s, c("a", "b", "c")))
  expect_equal(s$sequential, "Batlow")
  named <- projectPlotStyle(c(a = "red", b = "blue"))
  expect_equal(groupPalette(named, c("a", "b"), ordered = TRUE), c(a = "red", b = "blue"))
})
