#' The canonical project plot style: the single source of truth for palettes + theme, consumed by
#' plotting modules ONLY through the accessors below (never by reaching into the list). See the
#' plot-style-foundation design spec.
#' @param groupColours Optional named character vector of colours keyed by group level (e.g.
#'   `c(A = "red", B = "blue")`); `NULL` (default) means every grouping uses the qualitative palette.
#'   The study supplies its own from config; the package carries no study-specific colours.
#' @return list(theme, groupColours, qualitative, diverging, referenceLine).
#' @export
projectPlotStyle <- function(groupColours = NULL) {
  list(
    theme = ggplot2::theme_classic(base_size = 11) +
            ggplot2::theme(plot.title = ggplot2::element_text(size = 11, face = "bold"),
                           legend.position = "right"),
    groupColours = groupColours,
    qualitative = c("#E69F00", "#56B4E9", "#009E73", "#F0E442",   # Okabe-Ito, colourblind-safe
                    "#0072B2", "#D55E00", "#CC79A7", "#000000"),
    diverging   = "Blue-Red 3",                    # colorspace diverging: blue = -, red = +
    referenceLine = "grey60"
  )
}

#' The shared ggplot2 theme.
#' @export
reviewTheme <- function(style) style$theme

#' Colours for an arbitrary grouping variable: `style$groupColours[levels]` when EVERY level is named
#' in `groupColours`, otherwise the qualitative palette assigned in level order. All-or-nothing
#' (never a mix), no warning. Generic: no hardcoded level names.
#' @export
groupPalette <- function(style, levels) {
  levels <- as.character(unique(levels))
  if (length(levels) && all(levels %in% names(style$groupColours)))
    stats::setNames(unname(style$groupColours[levels]), levels)
  else
    qualitativePalette(style, levels)
}

#' Colourblind-safe qualitative colours for arbitrary `levels` (Okabe-Ito, position-recycled).
#' @export
qualitativePalette <- function(style, levels) {
  levels <- as.character(levels)
  stats::setNames(rep(style$qualitative, length.out = length(levels)), levels)
}

#' `n` diverging colours (colorspace Blue-Red 3): blue = negative, red = positive.
#' @export
divergingPalette <- function(style, n) colorspace::diverging_hcl(n, palette = style$diverging)

#' The colour for zero/reference lines and other neutral chrome.
#' @export
referenceLineColour <- function(style) style$referenceLine
