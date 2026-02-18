# ============================================================
# 06_dictionary_master.R
# Build a data dictionary for the MASTER dataset (appendix-ready)
# ============================================================

source("r_scripts/00_setup.R")

required_pkgs <- c("dplyr", "readr", "labelled", "tibble")
missing <- required_pkgs[
  !vapply(required_pkgs, requireNamespace, quietly = TRUE, FUN.VALUE = logical(1))
]
if (length(missing) > 0) stop("Missing packages: ", paste(missing, collapse = ", "), call. = FALSE)

library(dplyr)
library(readr)
library(labelled)
library(tibble)

path_in  <- "data/master/ess_master.rds"
path_out <- "data/master/ess_master_dictionary.csv"

if (!file.exists(path_in)) {
  stop("Input not found: ", path_in, "\nRun 05_save_master.R first.", call. = FALSE)
}

d <- readRDS(path_in)

# ---- Helper: NA share --------------------------------------
na_share <- function(x) mean(is.na(x))

# ---- Helper: scheme family tagging --------------------------
scheme_family <- function(varname) {
  if (grepl("^ordc", varname)) return("ORDC")
  if (grepl("^egp", varname)) return("EGP")
  if (grepl("^oesch", varname)) return("Oesch")
  if (grepl("^microclass", varname)) return("Microclass")
  if (grepl("^msec", varname)) return("MSEC")
  if (grepl("^wright", varname)) return("Wright")
  if (grepl("^isco", varname) || grepl("^occ_", varname)) return("Occupation spine")
  if (grepl("^ctx_", varname) || varname %in% c("self_employed","is_supervisor","n_employees")) return("DIGCLASS context")
  if (varname %in% c("anweight","pspwght","pweight")) return("Weights")
  if (grepl("^hinctnt", varname)) return("Income")
  return("Other")
}

# ---- Build dictionary ---------------------------------------
vars <- names(d)

dict <- tibble(
  variable = vars,
  type = vapply(d, function(x) class(x)[1], character(1)),
  label = vapply(d, function(x) {
    lab <- labelled::var_label(x)
    if (is.null(lab) || is.na(lab) || lab == "") "" else as.character(lab)
  }, character(1)),
  na_share = vapply(d, na_share, numeric(1)),
  n_unique = vapply(d, function(x) dplyr::n_distinct(x, na.rm = TRUE), integer(1)),
  family = vapply(vars, scheme_family, character(1))
) |>
  arrange(family, variable)

# ---- Save ---------------------------------------------------
readr::write_csv(dict, path_out)

# ---- Print compact report ----------------------------------
message("✔ Saved master data dictionary: ", path_out)
message("Variables: ", nrow(dict))

message("\nTop families by variable count:")
print(dict |> count(family, sort = TRUE), n = Inf)

message("\nHighest missingness (top 20 vars):")
print(dict |> arrange(desc(na_share)) |> slice_head(n = 20), n = 20)
