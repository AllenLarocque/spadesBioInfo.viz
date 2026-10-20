# spadesBioInfo.viz 0.2.0

Breaking: the package no longer carries any study-specific names, colours or positions.

* `projectPlotStyle(groupColours = NULL)` takes the group colours from the caller. The list is now
  `theme`, `groupColours`, `qualitative`, `diverging`, `referenceLine`; `theme`, `qualitative`,
  `diverging` and `referenceLine` are unchanged.
* `groupPalette()` returns `style$groupColours[levels]` when every level is named in `groupColours`,
  otherwise the qualitative palette in level order (as before).
* Removed: `treatmentPalette()`, `treatmentPositions()` and the style fields `treatmentColours`,
  `treatmentGradient`, `treatmentPositions`. Disturbance positions move to the study config.
