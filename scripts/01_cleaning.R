# ==============================================================================
# Script: 01_cleaning.R
# Path:   scripts/01_cleaning.R
# Purpose: Filter ESS Data (PT, ES, GR, IT | Age 18+) & Pre-clean for 'digclass'
# Input:  data/raw/ESS/ess_integrated_rounds1_11.csv
# Output: data/temp/01_filtered_data.rds
# Log:    log/01_cleaning_log.txt
# ==============================================================================

# 1. Load Libraries
library(tidyverse)
library(haven)

# 2. Setup Paths
raw_path  <- "data/raw/ESS/ess_integrated_rounds1_11.csv" 
temp_path <- "data/temp/01_filtered_data.rds"
log_path  <- "log/01_cleaning_log.txt"

# Ensure directories exist
if(!dir.exists("log")) dir.create("log")
if(!dir.exists("data/temp")) dir.create("data/temp")

# Open Log
sink(log_path)
cat("====================================================================\n")
cat("LOG START: 01_cleaning.R\n")
cat("Execution Time:", as.character(Sys.time()), "\n")
cat("====================================================================\n\n")

# 3. Load Raw Data (CSV) and Normalize Names
cat(">> Action: Loading raw CSV from", raw_path, "...\n")
if (!file.exists(raw_path)) stop("CRITICAL ERROR: Raw file not found!")

# Load and immediately convert all column names to lowercase (e.g., JBSPV -> jbspv)
df_raw <- read_csv(raw_path, show_col_types = FALSE) %>%
  rename_with(tolower)

cat("   Raw Dataset Loaded. Total Observations:", nrow(df_raw), "\n")

# ... (Sections 1-3 remain the same)

# 4. Filter Rows (Robust Case Handling)
# We define targets in Uppercase to match standard ESS data
target_countries <- c("PT", "ES", "GR", "IT")

cat(">> Action: Filtering for Target Countries (PT, ES, GR, IT) and Age >= 18...\n")

# We convert the data column to Uppercase inside the filter just to be 100% safe
df_filtered <- df_raw %>%
  filter(toupper(cntry) %in% target_countries) %>%
  filter(agea >= 18)

cat("   Rows remaining:", nrow(df_filtered), "\n")
cat("   Rows dropped:", nrow(df_raw) - nrow(df_filtered), "\n\n")

# 5. Pre-Processing for 'digclass'
cat(">> Action: Cleaning Employment Variables for 'digclass'...\n")

df_clean <- df_filtered %>%
  mutate(
    # --- ISCO CODES ---
    # Pad to 4 digits (e.g. "110" -> "0110")
    isco08 = str_pad(as.character(isco08), width = 4, pad = "0"),
    iscoco = str_pad(as.character(iscoco), width = 4, pad = "0"),
    
    # --- EMPLOYMENT RELATION ---
    # 1=Employee, 2=Self, 3=Family. Treat 6-9 as NA.
    emplrel_clean = if_else(emplrel %in% c(1, 2, 3), emplrel, NA_real_),
    is_self_employed = if_else(emplrel_clean %in% c(2, 3), 1, 0),
    
    # --- NUMBER OF EMPLOYEES ---
    # Cap at 50000 to remove missing codes (66666, 99999)
    emplno_clean = if_else(emplno > 50000, NA_real_, emplno),
    
    # --- SUPERVISOR (jbspv) ---
    # 1=Yes, 2=No. 
    # 6 (Not app), 7 (Refusal), 8 (Don't know), 9 (No answer) -> NA
    is_supervisor = case_when(
      jbspv == 1 ~ 1,
      jbspv == 2 ~ 0,
      TRUE ~ NA_real_
    )
  )

# 6. Safety Check: Data Quality
cat("\n>> Safety Check: Missing Values in Key Class Indicators\n")
cat("   Missing ISCO-08 (R5-11):", sum(is.na(df_clean$isco08[df_clean$essround >= 5])), "\n")
cat("   Missing ISCO-88 (R1-4): ", sum(is.na(df_clean$iscoco[df_clean$essround <= 4])), "\n")
cat("   Missing Employment Status:", sum(is.na(df_clean$is_self_employed)), "\n")
cat("   Missing Supervisor Status:", sum(is.na(df_clean$is_supervisor)), "\n")

# 7. Safety Check: Valid Observations by Country and Round
cat("\n>> Safety Check: Valid Observations by Country and Round\n")
print(table(df_clean$cntry, df_clean$essround))

# 8. Save to Temp (RDS)
cat("\n>> Action: Saving to", temp_path, "...\n")
saveRDS(df_clean, temp_path)

cat("\n====================================================================\n")
cat("LOG END: Script 01 Completed.\n")
cat("====================================================================\n")
sink()

message("Script 01 complete! Check 'log/01_cleaning_log.txt' to confirm valid row counts.")