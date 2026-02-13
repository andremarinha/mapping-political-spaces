# pilot/r_scripts/05_save_master.R
# Save MASTER dataset (with analysis_weight)

source("C:/Users/andre/Desktop/pilot/r_scripts/00_setup.R")

cat("\n── Script 05 — Save MASTER dataset ─────────────────────────────────────────────\n")

in_path  <- "data/temp/ess_4countries_r1_11_with_digclass.rds"
out_path <- "data/master/ess_master.rds"

if (!file.exists(in_path)) {
  stop("Missing input file: ", in_path, call. = FALSE)
}

master <- readRDS(in_path)

# ---- Ensure core vars exist ----
needed <- c("cntry", "essround", "dweight", "pspwght", "pweight")
missing_needed <- setdiff(needed, names(master))
if (length(missing_needed) > 0) {
  stop("Missing required variables in input: ", paste(missing_needed, collapse = ", "), call. = FALSE)
}

has_anweight <- "anweight" %in% names(master)

# ---- Create ESS-style analysis_weight (Option A) ----
# Rule:
# 1) If anweight exists and is non-missing -> use it
# 2) Else use dweight * pspwght
# (If you ever want pweight instead of pspwght, we can swap explicitly.)
master <- master |>
  dplyr::mutate(
    analysis_weight = dplyr::case_when(
      !!has_anweight & !is.na(.data$anweight) ~ as.numeric(.data$anweight),
      !is.na(.data$dweight) & !is.na(.data$pspwght) ~ as.numeric(.data$dweight) * as.numeric(.data$pspwght),
      TRUE ~ NA_real_
    )
  )

# ---- Sanity checks ----
nonpos <- sum(!is.na(master$analysis_weight) & master$analysis_weight <= 0)
if (nonpos > 0) {
  stop("analysis_weight has non-positive values (should not happen): ", nonpos, call. = FALSE)
}

na_share <- mean(is.na(master$analysis_weight))
cat("analysis_weight NA share: ", sprintf("%.4f", na_share), "\n", sep = "")

# ---- Save ----
dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)
saveRDS(master, out_path)

cat("✔ Saved MASTER dataset: ", out_path, "\n", sep = "")
cat("Rows: ", nrow(master), "\n", sep = "")
cat("Countries: ", paste(sort(unique(master$cntry)), collapse = ", "), "\n", sep = "")
cat("Rounds:    ", paste(sort(unique(master$essround)), collapse = ", "), "\n", sep = "")

# Quick coverage view if digclass columns exist
cov_vars <- c("ordc_dig", "egp_dig", "egp_mp_dig", "oesch16_dig", "oesch8_dig", "oesch5_dig",
              "microclass_dig", "msec_dig", "wright_dig")
present_cov <- cov_vars[cov_vars %in% names(master)]

if (length(present_cov) > 0) {
  cat("\nCoverage quick view (non-missing):\n")
  for (v in present_cov) {
    cat(sprintf("%-12s %d\n", sub("_dig$", "", v) %+% ":", sum(!is.na(master[[v]]))))
  }
}

# Keep any existing diagnostics attributes
if (!is.null(attr(master, "digclass_diagnostics"))) {
  cat("\n(Stored diagnostics found: attr(master, 'digclass_diagnostics'))\n")
}
