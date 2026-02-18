# ============================================================
# 07_class_coverage_tables.R  (UPDATED)
# Coverage diagnostics by round × country (appendix-ready)
#
# Fixes vs previous version:
#   1) Distinguishes "NOT APPLICABLE" vs "0 coverage"
#      - Microclass is only applicable for ISCO08 rounds (6–11 in our data)
#   2) Makes weighted totals interpretable by rescaling weights *within each cntry×round cell*
#      - Keeps w_share meaningful, avoids absurd w_n magnitudes
#   3) Adds "strict context complete" variants for context-hungry schemes
#      - MSEC and Wright are additionally reported as *_strict
# ============================================================

source("r_scripts/00_setup.R")

required_pkgs <- c("dplyr", "readr")
missing <- required_pkgs[
  !vapply(required_pkgs, requireNamespace, quietly = TRUE, FUN.VALUE = logical(1))
]
if (length(missing) > 0) stop("Missing packages: ", paste(missing, collapse = ", "), call. = FALSE)

library(dplyr)
library(readr)

path_in  <- "data/master/ess_master.rds"
path_out <- "tables/tex/class_scheme_coverage_round_country.csv"

if (!file.exists(path_in)) {
  stop("Master dataset not found: ", path_in, "\nRun 05_save_master.R first.", call. = FALSE)
}

d <- readRDS(path_in)

# ---- Safety checks -----------------------------------------
needed <- c("cntry", "essround", "anweight")
miss <- setdiff(needed, names(d))
if (length(miss) > 0) {
  stop("Missing required variables in master: ", paste(miss, collapse = ", "), call. = FALSE)
}

# ---- Helper: NA share (unused here, but handy) -------------
na_share <- function(x) mean(is.na(x))

# ---- Weight rescaling within cells -------------------------
# We rescale anweight within each cntry×round so that sum(w)=n.
# This makes w_n comparable across cells and avoids huge scale differences
# in integrated files where anweight might be pre-scaled inconsistently.
d <- d |>
  group_by(cntry, essround) |>
  mutate(
    anweight_cell = {
      w <- anweight
      if (all(is.na(w)) || sum(w, na.rm = TRUE) == 0) {
        rep(NA_real_, length(w))
      } else {
        w * (dplyr::n() / sum(w, na.rm = TRUE))
      }
    }
  ) |>
  ungroup()

# ---- Context completeness flag -----------------------------
# Context-hungry schemes: MSEC and Wright
# We'll compute *_strict versions only when context is complete.
ctx_vars <- c("emplrel", "jbspv", "emplno")
ctx_present <- ctx_vars %in% names(d)
if (all(ctx_present)) {
  d <- d |>
    mutate(ctx_complete = !is.na(emplrel) & !is.na(jbspv) & !is.na(emplno))
} else {
  # If context vars are absent, ctx_complete cannot be established
  d <- d |> mutate(ctx_complete = NA)
}

# ---- Applicability rules (explicit, academic) --------------
# Microclass requires ISCO08; in our staged ESS universe this is rounds 6–11.
# We define applicability by round, since staging showed perfect separation.
d <- d |>
  mutate(
    applicable_microclass = essround >= 6,
    applicable_default = TRUE
  )

# ---- Coverage helper ---------------------------------------
coverage_cell <- function(data, var, applicable = "applicable_default", weight = NULL) {
  
  # subset to applicable rows
  dd <- data |> filter(.data[[applicable]])
  
  # if not applicable (no rows), return NA shares
  if (nrow(dd) == 0) {
    if (is.null(weight)) {
      return(tibble(n = 0L, covered = 0L, share = NA_real_))
    } else {
      return(tibble(w_n = 0, w_covered = 0, w_share = NA_real_))
    }
  }
  
  if (is.null(weight)) {
    n <- nrow(dd)
    covered <- sum(!is.na(dd[[var]]))
    tibble(n = n, covered = covered, share = covered / n)
  } else {
    w <- dd[[weight]]
    # if weights unusable
    if (all(is.na(w)) || sum(w, na.rm = TRUE) == 0) {
      return(tibble(w_n = NA_real_, w_covered = NA_real_, w_share = NA_real_))
    }
    w_n <- sum(w, na.rm = TRUE)
    w_covered <- sum(w[!is.na(dd[[var]])], na.rm = TRUE)
    tibble(w_n = w_n, w_covered = w_covered, w_share = w_covered / w_n)
  }
}

# ---- Schemes to audit --------------------------------------
schemes <- c(
  "ordc_dig",
  "egp_dig",
  "oesch16_dig",
  "microclass_dig",
  "msec_dig",
  "wright_dig"
)

# Applicability mapping by scheme
scheme_applicability <- function(scheme) {
  if (scheme == "microclass_dig") return("applicable_microclass")
  "applicable_default"
}

# ---- Build coverage table ----------------------------------
coverage <- bind_rows(lapply(schemes, function(v) {
  
  app <- scheme_applicability(v)
  
  # Unweighted
  uw <- d |>
    group_by(cntry, essround) |>
    group_modify(~coverage_cell(.x, var = v, applicable = app, weight = NULL)) |>
    ungroup() |>
    mutate(scheme = v, type = "unweighted")
  
  # Weighted (cell-rescaled weights)
  w <- d |>
    group_by(cntry, essround) |>
    group_modify(~coverage_cell(.x, var = v, applicable = app, weight = "anweight_cell")) |>
    ungroup() |>
    mutate(scheme = v, type = "weighted")
  
  bind_rows(uw, w)
}))

# ---- Add STRICT variants for MSEC and Wright ----------------
# Strict = only among ctx_complete == TRUE rows (and applicable rows).
add_strict <- function(var, scheme_label) {
  
  # Unweighted strict
  uw <- d |>
    mutate(applicable_strict = (ctx_complete %in% TRUE)) |>
    group_by(cntry, essround) |>
    group_modify(~coverage_cell(.x, var = var, applicable = "applicable_strict", weight = NULL)) |>
    ungroup() |>
    mutate(scheme = scheme_label, type = "unweighted")
  
  # Weighted strict
  w <- d |>
    mutate(applicable_strict = (ctx_complete %in% TRUE)) |>
    group_by(cntry, essround) |>
    group_modify(~coverage_cell(.x, var = var, applicable = "applicable_strict", weight = "anweight_cell")) |>
    ungroup() |>
    mutate(scheme = scheme_label, type = "weighted")
  
  bind_rows(uw, w)
}

coverage_strict <- bind_rows(
  add_strict("msec_dig",   "msec_dig_strict"),
  add_strict("wright_dig", "wright_dig_strict")
)

coverage_all <- bind_rows(coverage, coverage_strict) |>
  arrange(scheme, type, cntry, essround)

# ---- Save ---------------------------------------------------
write_csv(coverage_all, path_out)

# ---- Console summary ----------------------------------------
message("✔ Saved coverage table: ", path_out)

message("\nMean coverage by scheme (unweighted):")
print(
  coverage_all |>
    filter(type == "unweighted") |>
    group_by(scheme) |>
    summarise(mean_share = mean(share, na.rm = TRUE), .groups = "drop") |>
    arrange(desc(mean_share)),
  n = Inf
)

message("\nMean coverage by scheme (weighted; cell-rescaled weights):")
print(
  coverage_all |>
    filter(type == "weighted") |>
    group_by(scheme) |>
    summarise(mean_share = mean(w_share, na.rm = TRUE), .groups = "drop") |>
    arrange(desc(mean_share)),
  n = Inf
)

message("\nNote: Microclass is marked NOT APPLICABLE (share=NA) in rounds < 6.")
message("Note: *_strict variants restrict to rows with non-missing (emplrel, jbspv, emplno).")
message("Note: Weighted shares use anweight rescaled within cntry×round cells (sum weights = n).")
