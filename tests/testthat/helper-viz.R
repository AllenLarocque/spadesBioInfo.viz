# Source the package R/ so tests run without installing the package (as core's helper-core.R does).
# test_dir() runs with the working directory set to this folder, so R/ is ../../R. Under an
# installed-package run (tests/testthat.R) R/ does not exist and the guard skips, leaving the
# attached library(spadesBioInfo.viz) in force.
local({
  rDir <- normalizePath(file.path("..", "..", "R"), mustWork = FALSE)
  if (dir.exists(rDir))
    for (f in list.files(rDir, pattern = "\\.R$", full.names = TRUE))
      sys.source(f, envir = globalenv())
})
