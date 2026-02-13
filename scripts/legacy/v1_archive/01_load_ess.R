# ============================================================
# 01_load_ess.R
# Load ESS integrated data and restrict to analysis universe
# ============================================================

source("r_scripts/00_setup.R")

# ---- Paths -------------------------------------------------
path_raw <- "data/raw/ESS/ess_integrated_rounds1_11.csv"
path_out <- "data/temp/ess_4countries_r1_11.rds"

# ---- Guardrails: raw file exists --------------------------
if (!file.exists(path_raw)) {
  stop(
    "Raw ESS file not found at: ", path_raw, "\n",
    "Place the integrated ESS CSV there (or update path_raw).",
    call. = FALSE
  )
}

# ---- Load raw ESS data ------------------------------------
ess_raw <- readr::read_csv(
  file = path_raw,
  show_col_types = FALSE,
  progress = FALSE
)

# ---- Required vars ----------------------------------------
needed_vars <- c("cntry", "essround")
missing_vars <- setdiff(needed_vars, names(ess_raw))
if (length(missing_vars) > 0) {
  stop(
    "Missing required variables in ESS file: ",
    paste(missing_vars, collapse = ", "),
    "\nCheck the column names in the CSV.",
    call. = FALSE
  )
}

# ---- Restrict to countries and rounds ---------------------
countries <- c("GR", "IT", "PT", "ES")

ess_sub <- ess_raw |>
  dplyr::filter(
    cntry %in% countries,
    essround %in% 1:11
  )

# ---- Save temporary dataset -------------------------------
saveRDS(ess_sub, path_out)

# ---- Diagnostics ------------------------------------------
message("✔ Loaded raw ESS file: ", path_raw)
message("Rows (raw):    ", nrow(ess_raw))
message("Rows (subset): ", nrow(ess_sub))
message("Countries in subset: ", paste(sort(unique(ess_sub$cntry)), collapse = ", "))
message("Rounds in subset:    ", paste(sort(unique(ess_sub$essround)), collapse = ", "))
message("✔ Saved: ", path_out)
