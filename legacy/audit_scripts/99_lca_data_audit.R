# LCA Data Audit Script
# Purpose: Analyze country-round structure and participation dummy coverage
# Author: Claude
# Date: 2026-02-18

library(tidyverse)
library(knitr)

# Load master dataset
master <- readRDS("G:/My Drive/1_projects/mapping/data/master/ess_final.rds")

cat("\n========== 1. COUNTRY × ROUND CROSS-TABULATION ==========\n")
cntry_round <- master %>%
  count(cntry, essround, name = "n_obs") %>%
  pivot_wider(names_from = essround, values_from = n_obs, values_fill = 0)
print(kable(cntry_round, format = "rst"))

cat("\n========== 2. PARTICIPATION DUMMIES COMPLETENESS BY COUNTRY ==========\n")
# Define the 6 participation dummies
dummies <- c("badge_d", "bctprd_d", "contplt_d", "sgnptit_d", "pbldmn_d", "vote_d")

# Check that all dummies exist
missing_cols <- setdiff(dummies, names(master))
if (length(missing_cols) > 0) {
  stop("Missing columns: ", paste(missing_cols, collapse = ", "))
}

# Complete-cases count by country
complete_by_country <- master %>%
  mutate(complete = if_all(all_of(dummies), ~!is.na(.))) %>%
  group_by(cntry) %>%
  summarise(
    n_total = n(),
    n_complete = sum(complete),
    pct_complete = round(100 * n_complete / n_total, 1),
    .groups = "drop"
  ) %>%
  arrange(cntry)
print(kable(complete_by_country, format = "rst"))

cat("\n========== 3. COMPLETE CASES BY COUNTRY × ROUND ==========\n")
complete_by_country_round <- master %>%
  mutate(complete = if_all(all_of(dummies), ~!is.na(.))) %>%
  group_by(cntry, essround) %>%
  summarise(
    n_total = n(),
    n_complete = sum(complete),
    pct_complete = round(100 * n_complete / n_total, 1),
    .groups = "drop"
  ) %>%
  arrange(cntry, essround)
print(kable(complete_by_country_round, format = "rst"))

cat("\n========== 4. PREVALENCE RATES BY COUNTRY (among complete cases) ==========\n")
prevalence_by_country <- master %>%
  filter(if_all(all_of(dummies), ~!is.na(.))) %>%
  group_by(cntry) %>%
  summarise(
    across(all_of(dummies),
           list(prev = ~round(100 * mean(. == 1, na.rm = TRUE), 1)),
           .names = "{.col}"),
    n_complete = n(),
    .groups = "drop"
  ) %>%
  arrange(cntry)
print(kable(prevalence_by_country, format = "rst"))

cat("\n========== 5. RESPONSE PATTERN DISTRIBUTION ==========\n")
# Create response patterns: combine all 6 dummies into a single string
patterns <- master %>%
  filter(if_all(all_of(dummies), ~!is.na(.))) %>%
  mutate(pattern = paste(badge_d, bctprd_d, contplt_d, sgnptit_d, pbldmn_d, vote_d,
                         sep = "")) %>%
  count(pattern, name = "freq") %>%
  arrange(desc(freq))

cat("Total unique response patterns:", nrow(patterns), "\n")
cat("Total complete cases:", sum(patterns$freq), "\n\n")
cat("Top 20 most common response patterns:\n")
print(kable(head(patterns, 20), format = "rst"))

cat("\n========== 6. PATTERN DISTRIBUTION SUMMARY ==========\n")
pattern_summary <- tibble(
  metric = c("Total unique patterns", "Total complete cases", 
             "Cumulative % from top 5 patterns", "Cumulative % from top 10 patterns",
             "Cumulative % from top 20 patterns"),
  value = c(
    nrow(patterns),
    sum(patterns$freq),
    paste0(round(100 * sum(head(patterns, 5)$freq) / sum(patterns$freq), 1), "%"),
    paste0(round(100 * sum(head(patterns, 10)$freq) / sum(patterns$freq), 1), "%"),
    paste0(round(100 * sum(head(patterns, 20)$freq) / sum(patterns$freq), 1), "%")
  )
)
print(kable(pattern_summary, format = "rst"))

cat("\n========== 7. DISTRIBUTION OF PATTERN FREQUENCIES ==========\n")
pattern_freq_dist <- tibble(
  metric = c("Min frequency", "Max frequency", "Median frequency", "Mean frequency",
             "Patterns with freq=1 (singletons)"),
  value = c(
    min(patterns$freq),
    max(patterns$freq),
    median(patterns$freq),
    round(mean(patterns$freq), 2),
    sum(patterns$freq == 1)
  )
)
print(kable(pattern_freq_dist, format = "rst"))

cat("\nAudit complete.\n")
