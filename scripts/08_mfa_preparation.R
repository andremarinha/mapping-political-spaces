# ==============================================================================
# Script: 08_mfa_preparation.R
# Path:   scripts/08_mfa_preparation.R
# Purpose: Recode and categorise variables for MFA political space analysis
# Input:   data/master/ess_final.rds (output of 07_attitudinal_recoding.R)
# Output:  data/master/ess_final.rds (updated in place)
# Log:     log/08_mfa_preparation_log.txt
#
# Variables created:
#   imbgeco_3cat  — Immigration (economy): 1=Negative, 2=Ambivalent, 3=Positive
#   imueclt_3cat  — Immigration (culture): 1=Negative, 2=Ambivalent, 3=Positive
#   imwbcnt_3cat  — Immigration (overall): 1=Negative, 2=Ambivalent, 3=Positive
#   income_quint  — Household income quintiles from hinctnta only (R4-11)
#   income_quint_h — Household income quintiles from hinctnt_harmonised (R1-11)
#   eisced_5cat   — Respondent education, 5-category ISCED
#
# Design decisions:
#   - Immigration 0-10 scales categorised into 3 groups (0-3 / 4-6 / 7-10).
#     Three categories maximise balance (no cell < 18%) and have clear
#     substantive meaning: negative, ambivalent, positive orientation.
#   - Income deciles (hinctnta 1-10) recoded to quintiles by merging pairs
#     (income_quint). Note: hinctnta is completely absent in Rounds 1-3.
#   - Harmonised income quintiles (income_quint_h) use hinctnt_harmonised
#     (created in script 02 via coalesce of hinctnt R1-3 + hinctnta R4+)
#     with empirical ntile() within each country x round. This extends
#     coverage from 47.7% to 63.5% by including R1-3 data.
#     Both kept: income_quint = clean decile-pair mapping; income_quint_h =
#     empirical quintiles from harmonised source. As supplementary in MFA,
#     missing cases do not affect axis construction.
#   - Respondent education (eisced 0-7) recoded to 5 categories matching
#     the parental education harmonisation scheme (mother_edu_5cat,
#     father_edu_5cat). Note: low coverage in Rounds 1-3 (ES-ISCED
#     introduced later).
#   - euftf (EU integration) excluded from active MFA variables: missing
#     in Rounds 1 and 5 would unbalance round blocks (Decision D22).
#   - ESS missing codes (77, 88, 99) mapped to NA throughout.
# ==============================================================================

library(tidyverse)

# --- Paths ---
input_path  <- "data/master/ess_final.rds"
output_path <- "data/master/ess_final.rds"
log_path    <- "log/08_mfa_preparation_log.txt"

# Start log capture
sink(log_path, split = TRUE)
cat("=== 08_mfa_preparation.R ===\n")
cat("Timestamp:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n\n")

# --- Load master ---
df <- readRDS(input_path)
cat("Input dimensions:", nrow(df), "x", ncol(df), "\n\n")

# ==============================================================================
# 1. Immigration attitudes — 0-10 → 3 categories
# ==============================================================================
# ESS scales: 0 = negative pole, 10 = positive pole
# ESS missing codes: 77, 88, 99
# Target: 1 = Negative (0-3), 2 = Ambivalent (4-6), 3 = Positive (7-10)

recode_imm_3cat <- function(x) {
  case_when(
    x %in% 0:3  ~ 1L,
    x %in% 4:6  ~ 2L,
    x %in% 7:10 ~ 3L,
    TRUE         ~ NA_integer_
  )
}

cat("--- imbgeco_3cat (Immigration: economy) ---\n")
df <- df %>% mutate(imbgeco_3cat = recode_imm_3cat(imbgeco))
cat("Original imbgeco (substantive 0-10):\n")
print(table(df$imbgeco[df$imbgeco %in% 0:10], useNA = "no"))
cat("Recoded imbgeco_3cat:\n")
print(table(df$imbgeco_3cat, useNA = "ifany"))

cat("\n--- imueclt_3cat (Immigration: culture) ---\n")
df <- df %>% mutate(imueclt_3cat = recode_imm_3cat(imueclt))
cat("Original imueclt (substantive 0-10):\n")
print(table(df$imueclt[df$imueclt %in% 0:10], useNA = "no"))
cat("Recoded imueclt_3cat:\n")
print(table(df$imueclt_3cat, useNA = "ifany"))

cat("\n--- imwbcnt_3cat (Immigration: overall) ---\n")
df <- df %>% mutate(imwbcnt_3cat = recode_imm_3cat(imwbcnt))
cat("Original imwbcnt (substantive 0-10):\n")
print(table(df$imwbcnt[df$imwbcnt %in% 0:10], useNA = "no"))
cat("Recoded imwbcnt_3cat:\n")
print(table(df$imwbcnt_3cat, useNA = "ifany"))

# ==============================================================================
# 2. Income — deciles → quintiles
# ==============================================================================
# ESS hinctnta: 1-10 = deciles, 77/88/99 = missing
# Note: completely absent in Rounds 1-3; high missingness R4+
# Target: 1 = Q1 (lowest) ... 5 = Q5 (highest)

cat("\n--- income_quint ---\n")
df <- df %>%
  mutate(
    income_quint = case_when(
      hinctnta %in% 1:2  ~ 1L,
      hinctnta %in% 3:4  ~ 2L,
      hinctnta %in% 5:6  ~ 3L,
      hinctnta %in% 7:8  ~ 4L,
      hinctnta %in% 9:10 ~ 5L,
      TRUE                ~ NA_integer_
    )
  )
cat("Original hinctnta (substantive 1-10):\n")
print(table(df$hinctnta[df$hinctnta %in% 1:10], useNA = "no"))
cat("Recoded income_quint:\n")
print(table(df$income_quint, useNA = "ifany"))
cat("Missingness by round:\n")
print(tapply(is.na(df$income_quint), df$essround, function(x) round(mean(x)*100, 1)))

# ==============================================================================
# 2b. Income — harmonised empirical quintiles (R1-11)
# ==============================================================================
# Uses hinctnt_harmonised (from script 02: coalesce of hinctnt R1-3 + hinctnta R4+).
# hinctnt (R1-3) uses 12 country-specific income brackets (1-12).
# hinctnta (R4+) uses 10 harmonised income deciles (1-10).
# Both are ordinal low-to-high, with similar cumulative distributions.
# Empirical ntile() within each country x round handles the different scales
# transparently: each respondent is ranked within their country-round group
# and assigned to Q1-Q5 based on their relative position.
# ESS missing codes (77, 88, 99) are excluded before ranking.

cat("\n--- income_quint_h (harmonised, empirical quintiles) ---\n")
df <- df %>%
  mutate(
    # Clean: strip ESS missing codes from hinctnt_harmonised
    .inc_clean = ifelse(hinctnt_harmonised %in% c(77, 88, 99), NA, hinctnt_harmonised)
  ) %>%
  group_by(cntry, essround) %>%
  mutate(
    income_quint_h = ifelse(is.na(.inc_clean), NA_integer_, as.integer(ntile(.inc_clean, 5)))
  ) %>%
  ungroup() %>%
  select(-`.inc_clean`)

cat("Recoded income_quint_h:\n")
print(table(df$income_quint_h, useNA = "ifany"))
cat("Coverage: income_quint (hinctnta only) vs income_quint_h (harmonised):\n")
cat(sprintf("  income_quint   : %d / %d (%.1f%%)\n",
            sum(!is.na(df$income_quint)), nrow(df),
            100 * mean(!is.na(df$income_quint))))
cat(sprintf("  income_quint_h : %d / %d (%.1f%%)\n",
            sum(!is.na(df$income_quint_h)), nrow(df),
            100 * mean(!is.na(df$income_quint_h))))
cat("Missingness by round (income_quint_h):\n")
print(tapply(is.na(df$income_quint_h), df$essround, function(x) round(mean(x)*100, 1)))

# ==============================================================================
# 3. Respondent education — eisced 0-7 → 5 categories
# ==============================================================================
# ESS eisced: 0 = not harmonisable, 1-7 = ES-ISCED categories
# ESS missing codes: 55, 77, 88, 99
# Target (matching parental education scheme):
#   1 = Less than lower secondary (ES-ISCED I)
#   2 = Lower secondary (ES-ISCED II)
#   3 = Upper secondary (ES-ISCED IIIa + IIIb)
#   4 = Post-secondary non-tertiary / Advanced vocational (ES-ISCED IV)
#   5 = Tertiary (ES-ISCED V1 + V2)

cat("\n--- eisced_5cat ---\n")
df <- df %>%
  mutate(
    eisced_5cat = case_when(
      eisced == 1          ~ 1L,
      eisced == 2          ~ 2L,
      eisced %in% 3:4     ~ 3L,
      eisced == 5          ~ 4L,
      eisced %in% 6:7     ~ 5L,
      TRUE                 ~ NA_integer_
    )
  )
cat("Original eisced (substantive 1-7):\n")
print(table(df$eisced[df$eisced %in% 1:7], useNA = "no"))
cat("Recoded eisced_5cat:\n")
print(table(df$eisced_5cat, useNA = "ifany"))
cat("Valid by round:\n")
print(tapply(!is.na(df$eisced_5cat), df$essround, sum))

# ==============================================================================
# 4. Diagnostic summary
# ==============================================================================
cat("\n=== DIAGNOSTIC SUMMARY ===\n\n")

# MFA active variables: check complete cases across 5 active vars
active_vars <- c("freehms_r", "gincdif_r", "imbgeco_3cat", "imueclt_3cat", "imwbcnt_3cat")
df_active_complete <- df %>% filter(if_all(all_of(active_vars), ~ !is.na(.)))
cat("MFA active variables:", paste(active_vars, collapse = ", "), "\n")
cat("Complete cases on all 5 active vars:", nrow(df_active_complete), "/", nrow(df),
    "(", round(100 * nrow(df_active_complete) / nrow(df), 1), "%)\n")
cat("By country:\n")
print(table(df_active_complete$cntry))
cat("By round:\n")
print(table(df_active_complete$essround))

# Supplementary variables: coverage
cat("\nSupplementary variable coverage (non-NA):\n")
sup_vars <- c("oesch8", "domicil_r", "income_quint", "income_quint_h",
              "eisced_5cat", "mother_edu_5cat", "father_edu_5cat")
for (v in sup_vars) {
  n_valid <- sum(!is.na(df[[v]]))
  pct <- round(100 * n_valid / nrow(df), 1)
  cat(sprintf("  %-20s: %6d / %d (%5.1f%%)\n", v, n_valid, nrow(df), pct))
}

# ==============================================================================
# 5. Archive current master and save
# ==============================================================================
if (file.exists(output_path)) {
  if (!dir.exists("data/archive")) dir.create("data/archive", recursive = TRUE)
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  archive_path <- file.path("data/archive",
                            paste0("ess_final_pre08_", timestamp, ".rds"))
  file.copy(output_path, archive_path)
  cat("\nArchived previous master to:", archive_path, "\n")
}

saveRDS(df, output_path)
cat("\nOutput dimensions:", nrow(df), "x", ncol(df), "\n")
cat("New columns: imbgeco_3cat, imueclt_3cat, imwbcnt_3cat, income_quint, income_quint_h, eisced_5cat\n")
cat("\n=== Done ===\n")
sink()
