# ============================================================
# 02_inventory_and_weights.R
# Inventory key variables + harmonise income + create ESS anweight
# ============================================================

source("r_scripts/00_setup.R")

# ---- Paths -------------------------------------------------
path_in  <- "data/temp/ess_4countries_r1_11.rds"
path_out <- "data/temp/ess_4countries_r1_11_weighted.rds"

if (!file.exists(path_in)) {
  stop("Input not found: ", path_in, "\nRun 01_load_ess.R first.", call. = FALSE)
}

# ---- Load --------------------------------------------------
ess <- readRDS(path_in)

# ---- Required core vars -----------------------------------
core_vars <- c("cntry", "essround")
missing_core <- setdiff(core_vars, names(ess))
if (length(missing_core) > 0) {
  stop("Missing required core variables: ", paste(missing_core, collapse = ", "), call. = FALSE)
}

# ---- Inventory: occupation --------------------------------
occ_vars_present <- intersect(c("iscoco", "isco08"), names(ess))
if (length(occ_vars_present) == 0) {
  stop(
    "No occupation variable found. Expected 'iscoco' (ISCO-88) and/or 'isco08' (ISCO-08).",
    call. = FALSE
  )
}

# ---- Inventory + harmonisation: income ---------------------
income_vars_present <- intersect(c("hinctnt", "hinctnta"), names(ess))
if (length(income_vars_present) == 0) {
  stop(
    "No income variable found. Expected 'hinctnt' (Rounds 1–3) and/or 'hinctnta' (Round 4+).",
    call. = FALSE
  )
}

# Safe vectors
hinctnt_vec  <- if ("hinctnt"  %in% names(ess)) ess$hinctnt  else rep(NA_integer_, nrow(ess))
hinctnta_vec <- if ("hinctnta" %in% names(ess)) ess$hinctnta else rep(NA_integer_, nrow(ess))

ess <- ess |>
  dplyr::mutate(
    hinctnt_harmonised = dplyr::coalesce(hinctnt_vec, hinctnta_vec),
    hinctnt_source = dplyr::case_when(
      !is.na(hinctnt_vec) ~ "hinctnt",
      is.na(hinctnt_vec) & !is.na(hinctnta_vec) ~ "hinctnta",
      TRUE ~ "missing"
    )
  )

# ---- Inventory: weight components --------------------------
w_needed <- c("pspwght", "pweight")
missing_w <- setdiff(w_needed, names(ess))
if (length(missing_w) > 0) {
  stop(
    "Missing required weight component(s): ",
    paste(missing_w, collapse = ", "),
    "\nCannot construct 'anweight' without these.",
    call. = FALSE
  )
}

anweight_exists <- "anweight" %in% names(ess)

# ---- Create/repair anweight --------------------------------
# We keep existing anweight (if present) and fill missing values using:
# anweight = pspwght * pweight * 10e3
scale_factor <- 10e3

if (!anweight_exists) {
  ess <- ess |>
    dplyr::mutate(anweight = pspwght * pweight * scale_factor)
} else {
  ess <- ess |>
    dplyr::mutate(
      anweight = dplyr::if_else(
        is.na(anweight),
        pspwght * pweight * scale_factor,
        anweight
      )
    )
}

# ---- Diagnostics -------------------------------------------
na_share <- function(x) mean(is.na(x))

message("=== Inventory report ===")
message("Input:  ", path_in)
message("Rows:   ", nrow(ess))
message("Countries: ", paste(sort(unique(ess$cntry)), collapse = ", "))
message("Rounds:    ", paste(sort(unique(ess$essround)), collapse = ", "))
message("Occupation vars present: ", paste(occ_vars_present, collapse = ", "))
message("Income vars present:     ", paste(income_vars_present, collapse = ", "))
message("anweight existed in input: ", ifelse(anweight_exists, "YES", "NO"))

message("\n=== Missingness (share NA) ===")
message("hinctnt_harmonised: ", round(na_share(ess$hinctnt_harmonised), 4))
if ("hinctnt" %in% names(ess))  message("hinctnt:            ", round(na_share(ess$hinctnt), 4))
if ("hinctnta" %in% names(ess)) message("hinctnta:           ", round(na_share(ess$hinctnta), 4))
if ("iscoco" %in% names(ess))   message("iscoco:             ", round(na_share(ess$iscoco), 4))
if ("isco08" %in% names(ess))   message("isco08:             ", round(na_share(ess$isco08), 4))
message("pspwght:            ", round(na_share(ess$pspwght), 4))
message("pweight:            ", round(na_share(ess$pweight), 4))
message("anweight:           ", round(na_share(ess$anweight), 4))

bad_w <- sum(!is.na(ess$anweight) & ess$anweight <= 0)
message("\n=== anweight validity ===")
message("Non-positive anweight count (should be 0): ", bad_w)

w_by_round <- ess |>
  dplyr::group_by(essround) |>
  dplyr::summarise(
    n = dplyr::n(),
    anweight_na = sum(is.na(anweight)),
    inc_na = sum(is.na(hinctnt_harmonised)),
    inc_source_hinctnt = sum(hinctnt_source == "hinctnt"),
    inc_source_hinctnta = sum(hinctnt_source == "hinctnta"),
    .groups = "drop"
  )

message("\n=== Round summary (weights + income source) ===")
print(w_by_round, n = Inf)

# ---- Save --------------------------------------------------
saveRDS(ess, path_out)
message("\n✔ Saved weighted+harmonised dataset: ", path_out)
