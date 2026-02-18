# ==============================================================================
# Script: 06_participation.R
# Path:   scripts/06_participation.R
# Purpose: Recode political participation variables as dummies (0/1),
#          harmonise pbldmn/pbldmna across rounds, prepare inputs for LCA.
# Input:   data/master/ess_final.rds
# Output:  data/master/ess_final.rds (updated with 6 new dummy variables)
# Archive: data/archive/ess_final_pre06_<timestamp>.rds
# Log:     log/06_participation_log.txt
# ==============================================================================

library(tidyverse)

# --- Paths ---
master_path <- "data/master/ess_final.rds"
archive_dir <- "data/archive"
log_path    <- "log/06_participation_log.txt"

# --- Ensure directories exist ---
if(!dir.exists(archive_dir)) dir.create(archive_dir, recursive = TRUE)
if(!dir.exists("log")) dir.create("log")

# --- Open log ---
sink(log_path)
cat("====================================================================\n")
cat("LOG START: 06_participation.R\n")
cat("Time:", as.character(Sys.time()), "\n")
cat("====================================================================\n\n")

# ==============================================================================
# 1. Load Data
# ==============================================================================

if(!file.exists(master_path)) stop("CRITICAL: Master file not found at ", master_path)

df <- readRDS(master_path)
cat("Loaded master:", nrow(df), "rows x", ncol(df), "columns\n\n")

# Safety check: verify participation variables exist
participation_vars <- c("badge", "bctprd", "contplt", "sgnptit", "pbldmn", "vote")
optional_vars <- c("pbldmna")  # Only exists as column if Rounds 10-11 present

missing_required <- setdiff(participation_vars, names(df))
if(length(missing_required) > 0) {
  stop("CRITICAL: Missing required participation variables: ",
       paste(missing_required, collapse = ", "))
}

cat(">> Required participation variables found:",
    paste(participation_vars, collapse = ", "), "\n")
cat(">> Optional variable pbldmna:",
    ifelse("pbldmna" %in% names(df), "FOUND", "NOT FOUND"), "\n\n")

# ==============================================================================
# 2. Helper Function: Recode ESS Participation Items to Dummies
# ==============================================================================
# ESS coding: 1 = Yes, 2 = No, 7 = Refusal, 8 = Don't know, 9 = No answer
# Target:     1 = Yes, 0 = No, NA = everything else

recode_participation <- function(x) {
  case_when(
    x == 1 ~ 1L,
    x == 2 ~ 0L,
    TRUE   ~ NA_integer_  # catches 7, 8, 9, NA, and any other values
  )
}

# ==============================================================================
# 3. Recode Standard Participation Variables
# ==============================================================================
cat(">> Recoding participation variables as dummies (1/0/NA)...\n")

df <- df %>%
  mutate(
    badge_d   = recode_participation(badge),
    bctprd_d  = recode_participation(bctprd),
    contplt_d = recode_participation(contplt),
    sgnptit_d = recode_participation(sgnptit)
  )

# ==============================================================================
# 4. Harmonise pbldmn (R1-9) + pbldmna (R10-11) into Single Dummy
# ==============================================================================
cat(">> Harmonising pbldmn (R1-9) + pbldmna (R10-11)...\n")

df <- df %>%
  mutate(
    # Recode each source variable separately
    .pbldmn_d  = recode_participation(pbldmn),
    .pbldmna_d = if("pbldmna" %in% names(df)) recode_participation(pbldmna) else NA_integer_,

    # Coalesce: prefer pbldmn (R1-9); fall back to pbldmna (R10-11)
    pbldmn_d = coalesce(.pbldmn_d, .pbldmna_d)
  ) %>%
  # Drop intermediate columns (prefixed with . for clarity)
  select(-.pbldmn_d, -.pbldmna_d)

# ==============================================================================
# 5. Recode Vote (Special: value 3 = "Not eligible" -> NA)
# ==============================================================================
cat(">> Recoding vote (1=Yes, 2=No, 3=Not eligible -> NA)...\n")

df <- df %>%
  mutate(
    vote_d = case_when(
      vote == 1 ~ 1L,    # Yes, voted
      vote == 2 ~ 0L,    # No, did not vote
      vote == 3 ~ NA_integer_,  # Not eligible to vote
      TRUE      ~ NA_integer_   # 7, 8, 9, NA
    )
  )

# ==============================================================================
# 6. Diagnostics: Dummy Distributions by Round
# ==============================================================================
cat("\n====================================================================\n")
cat("DIAGNOSTICS: Dummy Distributions by ESS Round\n")
cat("====================================================================\n")

dummy_vars <- c("badge_d", "bctprd_d", "contplt_d", "sgnptit_d", "pbldmn_d", "vote_d")

for(var in dummy_vars) {
  cat("\n---", var, "---\n")
  print(table(df$essround, df[[var]], useNA = "ifany", dnn = c("Round", var)))
}

# Harmonisation check: pbldmn_d should have valid values in ALL rounds
cat("\n>> Harmonisation check: pbldmn_d valid (non-NA) counts by round:\n")
pbldmn_check <- df %>%
  group_by(essround) %>%
  summarise(n = n(), valid = sum(!is.na(pbldmn_d)), pct = round(100 * valid / n, 1))
print(as.data.frame(pbldmn_check))

# ==============================================================================
# 7. Missingness Summary
# ==============================================================================
cat("\n====================================================================\n")
cat("MISSINGNESS SUMMARY\n")
cat("====================================================================\n")

for(var in dummy_vars) {
  n_na <- sum(is.na(df[[var]]))
  pct_na <- round(100 * n_na / nrow(df), 1)
  cat("  ", var, ":", n_na, "NA (", pct_na, "%)\n")
}

# ==============================================================================
# 8. Archive Current Master and Save
# ==============================================================================
cat("\n>> Archiving current master before overwriting...\n")
timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
archive_path <- file.path(archive_dir, paste0("ess_final_pre06_", timestamp, ".rds"))
file.copy(master_path, archive_path)
cat("   Archived to:", archive_path, "\n")

cat("\n>> Saving updated master...\n")
cat("   Dimensions:", nrow(df), "x", ncol(df), "\n")
cat("   New variables added:", paste(dummy_vars, collapse = ", "), "\n")
saveRDS(df, master_path)
cat("   Saved to:", master_path, "\n")

# ==============================================================================
# 9. Close Log
# ==============================================================================
cat("\n====================================================================\n")
cat("LOG END: Script 06 Completed.\n")
cat("====================================================================\n")
sink()

message("Script 06 complete! Check 'log/06_participation_log.txt' for diagnostics.")
