# Temp: check complete-case coverage for social space MCA
library(tidyverse)
select <- dplyr::select

df <- readRDS("data/master/ess_final.rds")

social_vars_h <- c("oesch8", "income_quint_h", "eisced_5cat",
                    "mother_edu_5cat", "father_edu_5cat", "domicil_r")
social_vars_c <- c("oesch8", "income_quint", "eisced_5cat",
                    "mother_edu_5cat", "father_edu_5cat", "domicil_r")

cat("=== Individual variable coverage ===\n")
for (v in unique(c(social_vars_h, social_vars_c))) {
  n_valid <- sum(!is.na(df[[v]]))
  cat(sprintf("  %-20s %6d / %d  (%.1f%%)\n",
              v, n_valid, nrow(df), 100 * n_valid / nrow(df)))
}

cat("\n=== Complete cases (all 6 active vars) ===\n")
for (cc in c("PT", "ES", "GR", "IT")) {
  cd <- df %>% filter(cntry == cc)
  n_h <- cd %>% filter(if_all(all_of(social_vars_h), ~ !is.na(.))) %>% nrow()
  n_c <- cd %>% filter(if_all(all_of(social_vars_c), ~ !is.na(.))) %>% nrow()
  cat(sprintf("  %s: income_quint_h = %5d / %5d (%.1f%%)  |  income_quint = %5d / %5d (%.1f%%)\n",
              cc, n_h, nrow(cd), 100 * n_h / nrow(cd),
              n_c, nrow(cd), 100 * n_c / nrow(cd)))
}

cat("\n=== Complete cases by country x round (income_quint_h version) ===\n")
cc_data <- df %>% filter(if_all(all_of(social_vars_h), ~ !is.na(.)))
cat("Total:", nrow(cc_data), "/", nrow(df),
    "(", round(100 * nrow(cc_data) / nrow(df), 1), "%)\n\n")
print(addmargins(table(cc_data$cntry, cc_data$essround)))

cat("\n=== Complete cases by country x round (income_quint version) ===\n")
cc_data2 <- df %>% filter(if_all(all_of(social_vars_c), ~ !is.na(.)))
cat("Total:", nrow(cc_data2), "/", nrow(df),
    "(", round(100 * nrow(cc_data2) / nrow(df), 1), "%)\n\n")
print(addmargins(table(cc_data2$cntry, cc_data2$essround)))

# Also check: how many categories per variable (for Benzécri)
cat("\n=== Category counts per variable ===\n")
for (v in social_vars_h) {
  vals <- na.omit(df[[v]])
  cat(sprintf("  %-20s %d categories: %s\n",
              v, length(unique(vals)),
              paste(sort(unique(vals)), collapse = ", ")))
}
