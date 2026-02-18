# ==============================================================================
# Script: 02_weighting.R
# Path:   scripts/02_weighting.R
# Purpose: Inventory, Income Harmonization, and Robust Weight Construction
# Logic:   Adopts Legacy '02_inventory_and_weights.R' logic
# Input:   data/temp/01_filtered_data.rds
# Output:  data/temp/02_weighted_data.rds
# Log:     log/02_weighting_log.txt
# ==============================================================================

library(tidyverse)
library(labelled)

# Paths
input_path  <- "data/temp/01_filtered_data.rds"
output_path <- "data/temp/02_weighted_data.rds"
log_path    <- "log/02_weighting_log.txt"

sink(log_path)
cat("LOG START: 02_weighting.R [Legacy-Aligned]\n")
cat("Time:", as.character(Sys.time()), "\n\n")

# 1. Load Data
if (!file.exists(input_path)) stop("Input not found!")
df <- readRDS(input_path)
cat("Rows loaded:", nrow(df), "\n")

# 2. Inventory Check (Legacy Feature)
# We ensure the raw ingredients for weights and income exist before proceeding.
req_vars <- c("essround", "cntry", "pspwght", "pweight")
missing  <- setdiff(req_vars, names(df))
if(length(missing) > 0) stop("Missing core variables: ", paste(missing, collapse=", "))

# 3. Income Harmonization (Legacy Feature)
# Merges R1-3 (hinctnt) and R4+ (hinctnta) into a single metric.
cat(">> Action: Harmonizing Income...\n")

# Safe extraction helper
get_col <- function(d, x) if(x %in% names(d)) d[[x]] else rep(NA, nrow(d))

df <- df %>%
  mutate(
    val_hinctnt  = get_col(., "hinctnt"),
    val_hinctnta = get_col(., "hinctnta"),
    
    # Coalesce: take hinctnt; if missing, take hinctnta
    hinctnt_harmonised = coalesce(val_hinctnt, val_hinctnta),
    
    hinctnt_source = case_when(
      !is.na(val_hinctnt) ~ "hinctnt",
      is.na(val_hinctnt) & !is.na(val_hinctnta) ~ "hinctnta",
      TRUE ~ "missing"
    )
  )

cat("   Income missingness:", mean(is.na(df$hinctnt_harmonised)), "\n")

# 4. Weight Construction (Legacy Feature)
# We prioritize existing 'anweight'. If missing, we construct it.
cat(">> Action: Constructing/Repairing 'anweight'...\n")

scale_factor <- 10000 # Matches your legacy script scaling

df <- df %>%
  mutate(
    # If anweight exists, use it. If NA (or column missing), calc from components.
    anweight_constructed = pspwght * pweight * scale_factor,
    
    analysis_weight = if("anweight" %in% names(.)) anweight else NA_real_,
    analysis_weight = coalesce(analysis_weight, anweight_constructed)
  )

# Validation
neg_weights <- sum(df$analysis_weight <= 0, na.rm = TRUE)
if(neg_weights > 0) warning("Found ", neg_weights, " non-positive weights!")

cat("   Weights constructed. Mean:", mean(df$analysis_weight, na.rm=TRUE), "\n")

# 5. Save
saveRDS(df, output_path)
cat("\nSaved to", output_path, "\n")
sink()