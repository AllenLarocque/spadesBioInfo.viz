thesisColours <- c(Control = "darkolivegreen", `60` = "darkolivegreen3",
                   `30` = "tan", ST = "tan3", CC = "chocolate4")

test_that("projectPlotStyle exposes a theme + palettes and no study-specific fields", {
  style <- projectPlotStyle()
  expect_true(inherits(reviewTheme(style), c("theme", "gg")))
  expect_named(style, c("theme", "groupColours", "qualitative", "diverging", "sequential", "referenceLine"))
  q <- qualitativePalette(style, c("flat", "with_block"))
  expect_equal(names(q), c("flat", "with_block")); expect_true(all(grepl("^#", q)))
  expect_length(divergingPalette(style, 5), 5)
  expect_true(grepl("grey", referenceLineColour(style)))
})

test_that("groupColours is NULL by default and carried verbatim when given", {
  expect_null(projectPlotStyle()$groupColours)
  expect_equal(projectPlotStyle(c(A = "red"))$groupColours, c(A = "red"))
})

test_that("treatmentPalette / treatmentPositions are removed from the package source", {
  # Check the source, not exists(): an older installed viz on the search path would make exists() TRUE.
  rFiles <- list.files(testthat::test_path("..", "..", "R"), pattern = "\\.R$", full.names = TRUE)
  src <- unlist(lapply(rFiles, readLines, warn = FALSE))
  expect_false(any(grepl("treatmentPalette\\s*<-", src)))
  expect_false(any(grepl("treatmentPositions\\s*<-", src)))
})

test_that("groupPalette uses groupColours when every level is named in it", {
  style <- projectPlotStyle(thesisColours)
  expect_equal(groupPalette(style, c("Control", "60", "30", "ST", "CC")), thesisColours)
  expect_equal(groupPalette(style, c("CC", "Control")), thesisColours[c("CC", "Control")])
})

test_that("groupPalette falls back to qualitative for all levels otherwise (no mix, no warning)", {
  style <- projectPlotStyle(thesisColours)
  expect_silent(p <- groupPalette(style, c("Control", "siteB")))
  expect_equal(p, c(Control = style$qualitative[1], siteB = style$qualitative[2]))
  expect_false(any(p %in% thesisColours))
  expect_length(groupPalette(style, c("A", "A", "B")), 2)
})

test_that("with no groupColours, levels A/B/C get the first three Okabe-Ito colours", {
  expect_equal(groupPalette(projectPlotStyle(), c("A", "B", "C")),
               c(A = "#E69F00", B = "#56B4E9", C = "#009E73"))
})
