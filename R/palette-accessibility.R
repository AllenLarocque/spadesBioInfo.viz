# Palette accessibility (colour-vision-deficiency) checks. General and reusable: nothing here
# knows about any study, and there is no testthat dependency, so any project can call these from
# its own tests, e.g. `expect_no_error(assertPaletteAccessible(cols, "qualitative"))`.

.visions <- c("normal", "deutan", "protan", "tritan", "greyscale")

# CIELAB coordinates (n x 3 matrix) of colours given as hex or R colour names.
.lab <- function(cols) {
  rgb <- grDevices::col2rgb(cols) / 255
  methods::as(colorspace::sRGB(t(rgb)), "LAB")@coords
}

# Smallest pairwise Euclidean CIELAB distance (Delta E 76); Inf for fewer than two colours.
.minDeltaE <- function(cols) {
  if (length(cols) < 2) return(Inf)
  min(stats::dist(.lab(cols)))
}

.strictlyMonotonic <- function(x) {
  d <- diff(x)
  length(d) == 0 || all(d > 0) || all(d < 0)
}

#' Colours as seen under one vision type.
#'
#' Meant to be reused in other projects' tests and plotting code. Simulates colour-vision
#' deficiency with the colorspace package (`deutan`, `protan`, `tritan`; severity 1) or
#' greyscale (`desaturate`).
#' @param cols Character vector of colours (hex or R colour names).
#' @param vision One of `"normal"`, `"deutan"`, `"protan"`, `"tritan"`, `"greyscale"`.
#' @return Character vector of upper-case hex colours, same length as `cols`.
#' @export
simulateVision <- function(cols, vision = c("normal", "deutan", "protan", "tritan", "greyscale")) {
  vision <- match.arg(vision)
  hex <- toupper(grDevices::rgb(t(grDevices::col2rgb(cols)), maxColorValue = 255))
  switch(vision,
    normal    = hex,
    deutan    = toupper(colorspace::deutan(hex)),
    protan    = toupper(colorspace::protan(hex)),
    tritan    = toupper(colorspace::tritan(hex)),
    greyscale = toupper(colorspace::desaturate(hex)))
}

#' Smallest pairwise colour difference of a palette under each vision type.
#'
#' Meant to be reused in other projects' tests. The difference is the plain Euclidean distance
#' in CIELAB (Delta E 76) between every pair of colours after [simulateVision()]; larger is more
#' distinguishable. The just-noticeable difference is about 2.3; 10 is a heuristic for colours that are easy to tell
#' apart at a glance in small chart marks.
#' Limit: `NA` is not detected (grDevices treats it as white).
#' @param cols Character vector of colours.
#' @param vision Vision types to evaluate (default all five).
#' @return `data.frame(vision, min_delta_e)`, one row per vision type (`Inf` for fewer than two colours).
#' @export
paletteDistinctness <- function(cols, vision = c("normal", "deutan", "protan", "tritan", "greyscale")) {
  vision <- match.arg(vision, several.ok = TRUE)
  data.frame(vision = vision,
             min_delta_e = vapply(vision, function(v) .minDeltaE(simulateVision(cols, v)), numeric(1)),
             row.names = NULL, stringsAsFactors = FALSE)
}

#' Check a palette for colour-vision-deficiency accessibility.
#'
#' Meant to be reused in other projects' tests (see [assertPaletteAccessible()]). Distances are
#' CIELAB Delta E 76 (Euclidean). Checks by `type`:
#' * `"qualitative"`: pairwise minimum Delta E >= `minDeltaE` under normal, deutan, protan and tritan
#'   vision (greyscale is not required).
#' * `"sequential"`: the same four, plus greyscale, plus CIELAB L* strictly monotonic (increasing or
#'   decreasing) in the order given.
#' * `"diverging"`: the middle is the L* extremum: L* is strictly monotonic from each end to the
#'   middle, in the SAME direction on both arms (both rising to a light middle, or both falling to
#'   a dark middle; odd `n`: the middle colour belongs to both arms), and every left-arm colour
#'   has Delta E >= `minDeltaE` from every right-arm colour (check `cross_arm_delta_e`; the middle
#'   excluded) under each of the four vision types, so no colour on one arm can be confused with
#'   any colour on the other. Colours within one arm are separated by the L* check only.
#'
#' Unparseable colour names produce a failing row instead of an error. Limit: `NA` is not detected
#' (grDevices treats it as white).
#' @param cols Character vector of colours, in palette order.
#' @param type `"qualitative"`, `"sequential"` or `"diverging"`.
#' @param minDeltaE Minimum acceptable Delta E (default 10).
#' @return `data.frame(check, vision, value, threshold, pass)`; `value` is the measured Delta E, or
#'   1/0 for the monotonic checks (threshold 1).
#' @export
checkPalette <- function(cols, type = c("qualitative", "sequential", "diverging"), minDeltaE = 10) {
  type <- match.arg(type)
  row <- function(check, vision, value, threshold) {
    data.frame(check = check, vision = vision, value = value, threshold = threshold,
               pass = isTRUE(value >= threshold), stringsAsFactors = FALSE)
  }
  out <- tryCatch({
    four <- setdiff(.visions, "greyscale")
    n <- length(cols)
    rows <- list()
    if (type == "qualitative" || type == "sequential") {
      vs <- if (type == "sequential") .visions else four
      rows <- lapply(vs, function(v)
        row("min_delta_e", v, .minDeltaE(simulateVision(cols, v)), minDeltaE))
    }
    if (type == "sequential") {
      rows <- c(rows, list(row("L_monotonic", "normal",
                               as.numeric(.strictlyMonotonic(.lab(cols)[, 1])), 1)))
    }
    if (type == "diverging") {
      L <- .lab(cols)[, 1]
      half <- floor(n / 2)
      left <- L[seq_len(ceiling(n / 2))]
      right <- rev(L)[seq_len(ceiling(n / 2))]
      dir <- function(x) { d <- diff(x)
        if (length(d) && all(d > 0)) 1 else if (length(d) && all(d < 0)) -1 else 0 }
      dl <- dir(left); dr <- dir(right)   # both arms oriented end -> middle
      rows <- list(row("L_monotonic_left", "normal", as.numeric(dl != 0), 1),
                   row("L_monotonic_right", "normal", as.numeric(dr != 0 && dr == dl), 1))
      # Every left-arm colour against every right-arm colour (the middle excluded for odd n):
      # a collision need not be mirrored (e.g. cols[1] == cols[4] of 5).
      cross <- lapply(four, function(v) {
        lab <- .lab(simulateVision(cols, v))
        d <- if (half == 0) Inf else {
          l <- lab[seq_len(half), , drop = FALSE]
          r <- lab[n - half + seq_len(half), , drop = FALSE]
          min(sqrt(outer(l[, 1], r[, 1], "-")^2 + outer(l[, 2], r[, 2], "-")^2 +
                   outer(l[, 3], r[, 3], "-")^2))
        }
        row("cross_arm_delta_e", v, d, minDeltaE)
      })
      rows <- c(rows, cross)
    }
    do.call(rbind, rows)
  }, error = function(e) row(paste("error:", conditionMessage(e)), NA_character_, NA_real_, minDeltaE))
  rownames(out) <- NULL
  out
}

#' Assert that a palette is colour-vision-deficiency accessible.
#'
#' Meant to be called from any project's tests, e.g.
#' `expect_no_error(assertPaletteAccessible(cols, "qualitative"))`. Wraps [checkPalette()].
#' @inheritParams checkPalette
#' @return `invisible(TRUE)`; otherwise stops, printing the failing rows of [checkPalette()].
#' @export
assertPaletteAccessible <- function(cols, type = c("qualitative", "sequential", "diverging"),
                                    minDeltaE = 10) {
  type <- match.arg(type)
  r <- checkPalette(cols, type, minDeltaE)
  bad <- r[!r$pass, , drop = FALSE]
  if (nrow(bad))
    stop("Palette is not accessible (", type, "):\n",
         paste(utils::capture.output(print(bad, row.names = FALSE)), collapse = "\n"), call. = FALSE)
  invisible(TRUE)
}
