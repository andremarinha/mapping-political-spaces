# ============================================================
# 03_occupation_staging.R
# Stage occupation variables for class coding (ISCO-88 / ISCO-08)
# ============================================================

source("r_scripts/00_setup.R")

path_in  <- "data/temp/ess_4countries_r1_11_weighted.rds"
path_out <- "data/temp/ess_4countries_r1_11_stage_occ.rds"

if (!file.exists(path_in)) {
  stop("Input not found: ", path_in, "\nRun 02_inventory_and_weights.R first.", call. = FALSE)
}

ess <- readRDS(path_in)

# ---- Check availability ------------------------------------
has_isco88 <- "iscoco" %in% names(ess)
has_isco08 <- "isco08" %in% names(ess)

if (!has_isco88 && !has_isco08) {
  stop("Neither 'iscoco' nor 'isco08' found. Cannot stage occupation.", call. = FALSE)
}

# Safe vectors
iscoco_vec <- if (has_isco88) ess$iscoco else rep(NA_integer_, nrow(ess))
isco08_vec <- if (has_isco08) ess$isco08 else rep(NA_integer_, nrow(ess))

# ---- Academic rule for scheme assignment -------------------
# Primary rule (documented):
# - Rounds 1–5: treat as ISCO88 universe (iscoco)
# - Rounds 6–11: treat as ISCO08 universe (isco08)
#
# Fallback rule (for integrated-file anomalies):
# - If primary is missing but the other is present, use the other and flag it.

ess <- ess |>
  dplyr::mutate(
    isco_scheme = dplyr::case_when(
      essround <= 5  & !is.na(iscoco_vec) ~ "ISCO88",
      essround <= 5  &  is.na(iscoco_vec) & !is.na(isco08_vec) ~ "ISCO08_fallback",
      essround <= 5  &  is.na(iscoco_vec) &  is.na(isco08_vec) ~ "missing",
      
      essround >= 6  & !is.na(isco08_vec) ~ "ISCO08",
      essround >= 6  &  is.na(isco08_vec) & !is.na(iscoco_vec) ~ "ISCO88_fallback",
      essround >= 6  &  is.na(isco08_vec) &  is.na(iscoco_vec) ~ "missing",
      
      TRUE ~ "missing"
    ),
    
    classifiable_occ = isco_scheme != "missing",
    
    # Staged occupation variables (single source of truth)
    occ_isco88 = if_else(isco_scheme %in% c("ISCO88", "ISCO88_fallback"), iscoco_vec, NA_integer_),
    occ_isco08 = if_else(isco_scheme %in% c("ISCO08", "ISCO08_fallback"), isco08_vec, NA_integer_)
  )

# ---- Diagnostics -------------------------------------------
message("=== Occupation staging report ===")
message("Input:  ", path_in)
message("Rows:   ", nrow(ess))
message("ISCO vars present: ",
        paste(c(if (has_isco88) "iscoco" else NULL, if (has_isco08) "isco08" else NULL),
              collapse = ", "))

message("\nOverall scheme counts:")
print(table(ess$isco_scheme, useNA = "ifany"))

scheme_tab <- ess |>
  dplyr::count(essround, cntry, isco_scheme, name = "n") |>
  dplyr::group_by(essround, cntry) |>
  dplyr::mutate(share = n / sum(n)) |>
  dplyr::ungroup() |>
  dplyr::arrange(essround, cntry, isco_scheme)

message("\n=== Scheme shares by round x country ===")
print(scheme_tab, n = 200)

# Fallback audit: should be rare (if it's large, integrated file mixing is happening)
fallback_n <- sum(ess$isco_scheme %in% c("ISCO08_fallback", "ISCO88_fallback"))
message("\nFallback rows (should be small): ", fallback_n)

# ---- Save --------------------------------------------------
saveRDS(ess, path_out)
message("\n✔ Saved staged occupation dataset: ", path_out)
