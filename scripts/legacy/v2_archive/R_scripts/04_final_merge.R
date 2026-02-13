# ==============================================================================
# Script: 04_final_merge.R
# Path:   scripts/R_scripts/04_final_merge.R
# Purpose: Calculate Oesch 5, apply labels, finalize variables, and save Master.
# Input:   data/temp/03_classed_data.rds
# Output:  data/master/ess_final.rds
# ==============================================================================

library(tidyverse)
library(labelled)

# Paths
input_path  <- "data/temp/03_classed_data.rds"
output_path <- "data/master/ess_final.rds"
log_path    <- "log/04_final_merge_log.txt"

# Ensure output directory exists
if(!dir.exists("data/master")) dir.create("data/master")

sink(log_path)
cat("LOG START: 04_final_merge.R [Updated Selection]\n")
cat("Time:", as.character(Sys.time()), "\n\n")

# 1. Load Data
df <- readRDS(input_path)
cat("Loaded N:", nrow(df), "\n\n")

# 2. Calculate Missing Oesch 5 (Aggregation)
cat(">> Action: Aggregating Oesch 16 -> Oesch 5...\n")

df_calc <- df %>%
  mutate(
    oesch5 = case_when(
      oesch16 <= 2 | oesch16 %in% c(5, 9, 13) ~ 1,
      oesch16 %in% c(6, 10, 14) ~ 2,
      oesch16 %in% c(3, 4) ~ 3,
      oesch16 %in% c(7, 11, 15) ~ 4,
      oesch16 %in% c(8, 12, 16) ~ 5,
      TRUE ~ NA_real_
    )
  )

# 3. Apply Labels (Factorizing) with Unclassifiable Handling
cat(">> Action: Applying Labels to Class Schemes...\n")

df_labeled <- df_calc %>%
  mutate(
    # --- OESCH 8 CLASSES ---
    oesch8_label = factor(oesch8, levels = 1:8, labels = c(
      "1. Self-emp professionals & large employers",
      "2. Small business owners",
      "3. Technical (semi-)professionals",
      "4. Production workers",
      "5. (Associate) managers",
      "6. Clerks",
      "7. Socio-cultural (semi-)professionals",
      "8. Service workers"
    ), ordered = TRUE),
    
    # --- OESCH 5 CLASSES ---
    oesch5_label = factor(oesch5, levels = 1:5, labels = c(
      "1. Higher-grade service class",
      "2. Lower-grade service class",
      "3. Small business owners",
      "4. Skilled workers",
      "5. Unskilled workers"
    ), ordered = TRUE),
    
    # --- ORDC (Handling the "Gap") ---
    # 1. Convert to numeric to avoid type errors
    ordc_num = suppressWarnings(as.numeric(ordc)),
    
    # 2. Force anything not in 1-13 to be 99 (Unclassifiable)
    ordc_clean = if_else(ordc_num %in% 1:13, ordc_num, 99, missing = 99),
    
    # 3. Label 1-13 normally, and map 99 to "Unclassifiable"
    ordc_label = factor(ordc_clean, levels = c(1:13, 99), labels = c(
      "1. Cultural upper class",
      "2. Balanced upper class",
      "3. Economic upper class",
      "4. Cultural upper middle class",
      "5. Balanced upper middle class",
      "6. Economic upper middle class",
      "7. Cultural lower middle class",
      "8. Balanced lower middle class",
      "9. Economic lower middle class",
      "10. Skilled working class",
      "11. Unskilled working class",
      "12. Primary-sector employees",
      "13. Welfare dependents",
      "14. Unclassifiable" # Explicit 14th category
    ), ordered = TRUE),
    
    # --- EGP (11 CLASSES) ---
    egp11_label = factor(egp11, levels = 1:11, labels = c(
      "I. Higher managerial and professional",
      "II. Lower managerial and professional",
      "IIIa. Routine non-manual (High)",
      "IIIb. Routine non-manual (Low)",
      "IVa. Small proprietors (employees)",
      "IVb. Small proprietors (no employees)",
      "IVc. Farmers",
      "V. Lower technical / Supervisors",
      "VI. Skilled manual",
      "VIIa. Unskilled manual",
      "VIIb. Farm labour"
    ), ordered = TRUE)
  )

# 4. Final Variable Selection
cat(">> Action: Selecting final variables...\n")

df_master <- df_labeled %>%
  select(
    # ID & Design
    idno, cntry, essround,
    
    # Weights
    dweight, pspwght, pweight, anweight, analysis_weight,
    
    # Demographics
    gndr, agea,
    
    # Education (ES-ISCED)
    eisced,
    
    # Work Context (Cleaned)
    isco_main = isco88_str, 
    emplrel_r = selfem_mainjob, 
    
    # Class Schemes (Numeric & Labeled)
    oesch_resp,  # <--- NEW: Keep respondent raw class
    oesch_part,  # <--- NEW: Keep partner raw class
    oesch16, 
    oesch8, oesch8_label,
    oesch5, oesch5_label,
    ordc, ordc_label,
    egp11, egp11_label,
    microclass,
    
    # Income (Harmonized)
    hinctnt_harmonised, hinctnt_source
  )

# 5. Save
cat("\n>> Final Dimensions:", paste(dim(df_master), collapse=" x "), "\n")
saveRDS(df_master, output_path)
cat("Saved to", output_path, "\n")

# 6. Export CSV for quick inspection (Optional)
write_csv(df_master, "data/master/ess_final_sample.csv")

sink()
message("Script 04 complete! Oesch Respondent/Partner columns preserved.")