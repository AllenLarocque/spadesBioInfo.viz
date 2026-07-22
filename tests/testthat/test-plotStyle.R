test_that("projectPlotStyle exposes a theme + palettes; treatmentPalette is name-keyed", {
  style <- projectPlotStyle()
  expect_true(inherits(reviewTheme(style), c("theme", "gg")))
  expect_equal(treatmentPalette(style, c("Control", "CC")),
               c(Control = "darkolivegreen", CC = "chocolate4"))
  # Hue tracks the disturbance gradient (green->brown by % cut): 30 mid, ST at the brown end (near CC).
  expect_equal(unname(treatmentPalette(style, "30")), "tan")    # subset keeps per-level hue
  expect_equal(unname(treatmentPalette(style, "ST")), "tan3")   # ST = 90% cut -> brown end, next to CC
  q <- qualitativePalette(style, c("flat", "with_block"))
  expect_equal(names(q), c("flat", "with_block")); expect_true(all(grepl("^#", q)))
  expect_length(divergingPalette(style, 5), 5)
  expect_true(grepl("grey", referenceLineColour(style)))
})

test_that("treatmentPalette warns + falls back for an unknown level", {
  style <- projectPlotStyle()
  expect_warning(p <- treatmentPalette(style, c("Control", "BOGUS")))
  expect_equal(unname(p["Control"]), "darkolivegreen")
  expect_true(grepl("^#", p["BOGUS"]))                          # qualitative fallback hex
})

test_that("projectPlotStyle carries the treatmentPositions disturbance map", {
  style <- projectPlotStyle()
  expect_equal(treatmentPositions(style),
               c(Control = 0, `60` = 40, `30` = 70, ST = 90, CC = 100))   # % cut; ST = 90
})

test_that("groupPalette dispatches: all-treatment -> treatment colours, else qualitative (no mix/warn)", {
  style <- projectPlotStyle()
  # all levels are treatment levels -> identical to treatmentPalette (disturbance colours)
  expect_equal(groupPalette(style, c("Control", "CC")),
               treatmentPalette(style, c("Control", "CC")))
  # any non-treatment level -> qualitative for ALL levels, no warning, no treatment colour mixed in
  expect_silent(p <- groupPalette(style, c("Control", "siteB")))
  expect_true(all(grepl("^#", p)))                       # all hex (qualitative), none are named treatment colours
  expect_false(any(p %in% style$treatmentColours))
  expect_equal(names(p), c("Control", "siteB"))
  # duplicate levels collapse; single level works
  expect_length(groupPalette(style, c("A", "A", "B")), 2)
})
