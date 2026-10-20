# spadesBioInfo.viz 0.2.2

Bug fix: `checkPalette(type = "diverging")` missed non-mirrored cross-arm collisions.

* The `mirrored_pair_delta_e` rows (which compared only `cols[i]` with `cols[n + 1 - i]`) are
  replaced by `cross_arm_delta_e`: every left-arm colour against every right-arm colour (the
  middle excluded for odd `n`), one row per vision type (normal, deutan, protan, tritan), Delta E
  >= `minDeltaE`. A palette such as `c("#0072B2", "#56B4E9", "#FFFFFF", "#0072B2", "#000000")`,
  whose entries 1 and 4 are identical, now fails. The default `divergingPalette(projectPlotStyle(), 7)`
  still passes (cross-arm minimum Delta E: normal 33.9, deutan 32.6, protan 25.8, tritan 41.2).

# spadesBioInfo.viz 0.2.1

Additive: reusable palette accessibility checks and an ordered default palette.

* New `simulateVision()`, `paletteDistinctness()`, `checkPalette()` and `assertPaletteAccessible()`:
  colour-vision-deficiency (deutan, protan, tritan, greyscale) checks on CIELAB Delta E 76, for any
  project to call from its own tests.
* `projectPlotStyle()` gains `sequential = "Batlow"`; new `sequentialPalette(style, n)`.
* `groupPalette(style, levels, ordered = FALSE)`: with `ordered = TRUE`, levels not fully named in
  `groupColours` get the sequential palette instead of the qualitative one.

# spadesBioInfo.viz 0.2.0

Breaking: the package no longer carries any study-specific names, colours or positions.

* `projectPlotStyle(groupColours = NULL)` takes the group colours from the caller. The list is now
  `theme`, `groupColours`, `qualitative`, `diverging`, `referenceLine`; `theme`, `qualitative`,
  `diverging` and `referenceLine` are unchanged.
* `groupPalette()` returns `style$groupColours[levels]` when every level is named in `groupColours`,
  otherwise the qualitative palette in level order (as before).
* Removed: `treatmentPalette()`, `treatmentPositions()` and the style fields `treatmentColours`,
  `treatmentGradient`, `treatmentPositions`. Disturbance positions move to the study config.
