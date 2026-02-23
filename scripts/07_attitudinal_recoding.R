# ==============================================================================
# Script: 07_attitudinal_recoding.R
# Path:   scripts/07_attitudinal_recoding.R
# Purpose: Recode attitudinal and structural variables for MCA/LCA analysis
# Input:   data/master/ess_final.rds (output of 06_participation.R)
# Output:  data/master/ess_final.rds (updated in place)
# Log:     log/07_attitudinal_recoding_log.txt
#
# Variables recoded:
#   freehms_r   — Gay rights (reversed: 1=Disagree strongly ... 5=Strongly agree)
#   gincdif_r   — Income redistribution (reversed: same scale)
#   polintr_r   — Political interest (reversed: 1=Not at all ... 4=Very interested)
#   rlgblg_r    — Religious belonging (0=No, 1=Yes)
#   rlgatnd_r   — Church attendance (1=Active, 2=Occasional, 3=Not religious)
#   domicil_r   — Urbanisation (1=Urban, 2=Suburban, 3=Town, 4=Rural)
#   mother_edu_5cat — Mother's education (harmonised 5-cat ISCED)
#   father_edu_5cat — Father's education (harmonised 5-cat ISCED)
#
# Methodological notes:
#   - freehms, gincdif reversed following Delespaul (2025): higher = more agreement
#   - polintr reversed: higher = more interested
#   - rlgatnd collapsed from 7 to 3 categories to avoid sparsity
#   - domicil collapsed from 5 to 4 categories (farm + village → Rural)
#   - Parental education harmonised across edulvlma/edulvlfa (R1-4, 5-cat ISCED)
#     and eiscedm/eiscedf (R4-11, 7-cat ES-ISCED) into a common 5-category scale.
#     Where both old and new variables are present (R4), the new ES-ISCED variable
#     takes priority (finer granularity).
#   - ESS missing codes (7, 8, 9, 77, 88, 99) recoded to NA throughout.
# ==============================================================================

library(tidyverse)

# --- Paths ---
input_path  <- "data/master/ess_final.rds"
output_path <- "data/master/ess_final.rds"
log_path    <- "log/07_attitudinal_recoding_log.txt"

# Start log capture
sink(log_path, split = TRUE)
cat("=== 07_attitudinal_recoding.R ===\n")
cat("Timestamp:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n\n")

# --- Load master ---
df <- readRDS(input_path)
cat("Input dimensions:", nrow(df), "x", ncol(df), "\n\n")

# ==============================================================================
# 1. freehms — Gay rights (reverse-code)
# ==============================================================================
# ESS original: 1=Agree strongly ... 5=Disagree strongly (+ 7/8/9 = missing)
# Target:       1=Disagree strongly ... 5=Strongly agree
cat("--- freehms_r ---\n")
df <- df %>%
  mutate(
    freehms_r = case_when(
      freehms == 1 ~ 5L,
      freehms == 2 ~ 4L,
      freehms == 3 ~ 3L,
      freehms == 4 ~ 2L,
      freehms == 5 ~ 1L,
      TRUE ~ NA_integer_
    )
  )
cat("Original freehms:\n"); print(table(df$freehms, useNA = "ifany"))
cat("Recoded freehms_r:\n"); print(table(df$freehms_r, useNA = "ifany"))

# ==============================================================================
# 2. gincdif — Income redistribution (reverse-code)
# ==============================================================================
# ESS original: 1=Agree strongly ... 5=Disagree strongly (+ 7/8/9 = missing)
# Target:       1=Disagree strongly ... 5=Strongly agree
cat("\n--- gincdif_r ---\n")
df <- df %>%
  mutate(
    gincdif_r = case_when(
      gincdif == 1 ~ 5L,
      gincdif == 2 ~ 4L,
      gincdif == 3 ~ 3L,
      gincdif == 4 ~ 2L,
      gincdif == 5 ~ 1L,
      TRUE ~ NA_integer_
    )
  )
cat("Original gincdif:\n"); print(table(df$gincdif, useNA = "ifany"))
cat("Recoded gincdif_r:\n"); print(table(df$gincdif_r, useNA = "ifany"))

# ==============================================================================
# 3. polintr — Political interest (reverse-code)
# ==============================================================================
# ESS original: 1=Very interested ... 4=Not at all interested (+ 7/8/9 = missing)
# Target:       1=Not at all ... 4=Very interested
cat("\n--- polintr_r ---\n")
df <- df %>%
  mutate(
    polintr_r = case_when(
      polintr == 1 ~ 4L,
      polintr == 2 ~ 3L,
      polintr == 3 ~ 2L,
      polintr == 4 ~ 1L,
      TRUE ~ NA_integer_
    )
  )
cat("Original polintr:\n"); print(table(df$polintr, useNA = "ifany"))
cat("Recoded polintr_r:\n"); print(table(df$polintr_r, useNA = "ifany"))

# ==============================================================================
# 4. rlgblg — Religious belonging (recode to 0/1)
# ==============================================================================
# ESS original: 1=Yes, 2=No (+ 7/8/9 = missing)
# Target:       0=No, 1=Yes
cat("\n--- rlgblg_r ---\n")
df <- df %>%
  mutate(
    rlgblg_r = case_when(
      rlgblg == 1 ~ 1L,
      rlgblg == 2 ~ 0L,
      TRUE ~ NA_integer_
    )
  )
cat("Original rlgblg:\n"); print(table(df$rlgblg, useNA = "ifany"))
cat("Recoded rlgblg_r:\n"); print(table(df$rlgblg_r, useNA = "ifany"))

# ==============================================================================
# 5. rlgatnd — Church attendance (collapse 7 → 3 categories)
# ==============================================================================
# ESS original: 1=Every day ... 7=Never (+ 77/88/99 = missing)
# Target: 1=Active churchgoing (1-4), 2=Occasional (5-6), 3=Not religious (7)
cat("\n--- rlgatnd_r ---\n")
df <- df %>%
  mutate(
    rlgatnd_r = case_when(
      rlgatnd %in% 1:4 ~ 1L,
      rlgatnd %in% 5:6 ~ 2L,
      rlgatnd == 7     ~ 3L,
      TRUE ~ NA_integer_
    )
  )
cat("Original rlgatnd:\n"); print(table(df$rlgatnd, useNA = "ifany"))
cat("Recoded rlgatnd_r:\n"); print(table(df$rlgatnd_r, useNA = "ifany"))

# ==============================================================================
# 6. domicil — Urbanisation (collapse 5 → 4 categories)
# ==============================================================================
# ESS original: 1=Big city, 2=Suburbs, 3=Town/small city, 4=Country village,
#               5=Farm/countryside (+ 7/8/9 = missing)
# Target: 1=Urban, 2=Suburban, 3=Town/small city, 4=Rural (village + farm)
cat("\n--- domicil_r ---\n")
df <- df %>%
  mutate(
    domicil_r = case_when(
      domicil == 1    ~ 1L,
      domicil == 2    ~ 2L,
      domicil == 3    ~ 3L,
      domicil %in% 4:5 ~ 4L,
      TRUE ~ NA_integer_
    )
  )
cat("Original domicil:\n"); print(table(df$domicil, useNA = "ifany"))
cat("Recoded domicil_r:\n"); print(table(df$domicil_r, useNA = "ifany"))

# ==============================================================================
# 7. Parental education — harmonise edulvlma/eiscedm → mother_edu_5cat
#                          and edulvlfa/eiscedf → father_edu_5cat
# ==============================================================================
# Strategy:
#   - edulvlma / edulvlfa: R1-4, 5-cat ISCED (0-5, where 0 = not harmonisable)
#     Substantive values 1-5 map directly to the target 5 categories.
#   - eiscedm / eiscedf: R4-11, 7-cat ES-ISCED (0-7, where 0 = not harmonisable)
#     Recode: 1→1, 2→2, 3/4→3, 5→4, 6/7→5
#   - Where both are available (R4), prefer eiscedm/eiscedf (finer granularity).
#   - Non-substantive codes (0, 55, 77, 88, 99) → NA
#
# Target 5-category scale:
#   1 = Less than lower secondary
#   2 = Lower secondary
#   3 = Upper secondary
#   4 = Post-secondary non-tertiary
#   5 = Tertiary

cat("\n--- mother_edu_5cat ---\n")

# Helper: recode 7-cat ES-ISCED to 5-cat ISCED
recode_eisced_to_5cat <- function(x) {
  case_when(
    x == 1          ~ 1L,
    x == 2          ~ 2L,
    x %in% 3:4     ~ 3L,
    x == 5          ~ 4L,
    x %in% 6:7     ~ 5L,
    TRUE            ~ NA_integer_
  )
}

# Helper: recode 5-cat old ISCED (edulvlma/edulvlfa) — substantive values 1-5 only
recode_old_isced_to_5cat <- function(x) {
  case_when(
    x %in% 1:5 ~ as.integer(x),
    TRUE        ~ NA_integer_
  )
}

df <- df %>%
  mutate(
    # Recode both systems
    .mother_old  = recode_old_isced_to_5cat(edulvlma),
    .mother_new  = recode_eisced_to_5cat(eiscedm),
    .father_old  = recode_old_isced_to_5cat(edulvlfa),
    .father_new  = recode_eisced_to_5cat(eiscedf),
    # Prefer new (ES-ISCED) where available; fall back to old (ISCED)
    mother_edu_5cat = coalesce(.mother_new, .mother_old),
    father_edu_5cat = coalesce(.father_new, .father_old)
  ) %>%
  select(-starts_with(".mother_"), -starts_with(".father_"))

cat("mother_edu_5cat:\n"); print(table(df$mother_edu_5cat, useNA = "ifany"))
cat("father_edu_5cat:\n"); print(table(df$father_edu_5cat, useNA = "ifany"))

# Validate: check coverage by round
cat("\nmother_edu_5cat valid cases by round:\n")
print(tapply(!is.na(df$mother_edu_5cat), df$essround, sum))
cat("father_edu_5cat valid cases by round:\n")
print(tapply(!is.na(df$father_edu_5cat), df$essround, sum))

# ==============================================================================
# 8. Archive current master and save
# ==============================================================================
if (file.exists(output_path)) {
  if (!dir.exists("data/archive")) dir.create("data/archive", recursive = TRUE)
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  archive_path <- file.path("data/archive",
                            paste0("ess_final_pre07_", timestamp, ".rds"))
  file.copy(output_path, archive_path)
  cat("\nArchived previous master to:", archive_path, "\n")
}

saveRDS(df, output_path)
cat("\nOutput dimensions:", nrow(df), "x", ncol(df), "\n")
cat("New columns: freehms_r, gincdif_r, polintr_r, rlgblg_r, rlgatnd_r,",
    "domicil_r, mother_edu_5cat, father_edu_5cat\n")
cat("\n=== Done ===\n")
sink()
