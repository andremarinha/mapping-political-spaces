# ============================================================
# 00_setup.R
# Project setup and sanity checks
# ============================================================

# ============================================================
# What is 00_setup.R responsible for:
#
#   - Load required packages
#   - Assert that the working directory is correct
#   - Assert that required folders exist
#   - Fail early if something is wrong
#   - GUARDIAN OF THE PIPELINE
#
# How to use it:
#   - At the top of every script, it will be added:
#     source("r_scripts/00_setup.R")
#       - If anything is wrong (working directory, missing folders, missing packages),
#         the pipeline will stop immediately!
#       - We are assuming that ALL scripts in this project have a validated directory structure
#         and a reproducible R environment
#
# ============================================================

# ---- Packages ----------------------------------------------
required_pkgs <- c(
  "tidyverse",
  "haven",
  "labelled"
)

missing_pkgs <- required_pkgs[
  !vapply(required_pkgs, requireNamespace, quietly = TRUE, FUN.VALUE = logical(1))
]

if (length(missing_pkgs) > 0) {
  stop(
    "Missing required packages: ",
    paste(missing_pkgs, collapse = ", "),
    "\nInstall them and re-run.",
    call. = FALSE
  )
}

invisible(lapply(required_pkgs, function(pkg) {
  suppressPackageStartupMessages(library(pkg, character.only = TRUE))
}))

# ---- Working directory check -------------------------------
if (!file.exists("pilot.Rproj")) {
  stop(
    "Working directory is not the project root.\n",
    "Open the project using pilot.Rproj.",
    call. = FALSE
  )
}

# ---- Folder structure checks -------------------------------
required_dirs <- c(
  "data/raw/ESS",
  "data/temp",
  "data/master",
  "r_scripts",
  "r_scripts/functions",
  "quarto",
  "figures/pdf",
  "figures/png",
  "tables/tex"
)

missing_dirs <- required_dirs[!dir.exists(required_dirs)]

if (length(missing_dirs) > 0) {
  stop(
    "Missing required directories:\n",
    paste(missing_dirs, collapse = "\n"),
    call. = FALSE
  )
}

message("✔ Project setup complete")
message("✔ All required packages loaded")
message("✔ Folder structure validated")
message("R version: ", getRversion())
message("Platform:  ", R.version$platform)