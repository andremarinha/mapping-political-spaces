# Audit ORDC, EGP11, and Oesch-8 labels in master data
library(tidyverse)
df <- readRDS("data/master/ess_final.rds")

cat("=== Master dimensions ===\n")
cat(nrow(df), "x", ncol(df), "\n\n")

# Oesch-8
cat("=== oesch8 ===\n")
cat("Class:", class(df$oesch8), "\n")
cat("Unique values:\n")
print(sort(unique(df$oesch8)))
cat("Coverage:", round(100 * mean(!is.na(df$oesch8)), 1), "%\n\n")

# ORDC
cat("=== ordc ===\n")
cat("Class:", class(df$ordc), "\n")
cat("Unique values:\n")
print(sort(unique(df$ordc)))
cat("Coverage:", round(100 * mean(!is.na(df$ordc)), 1), "%\n\n")

# ordc_label
cat("=== ordc_label ===\n")
cat("Class:", class(df$ordc_label), "\n")
if (is.factor(df$ordc_label)) cat("Levels:", levels(df$ordc_label), "\n")
cat("Unique values:\n")
print(sort(unique(as.character(df$ordc_label))))
cat("Coverage:", round(100 * mean(!is.na(df$ordc_label)), 1), "%\n\n")

# EGP11
cat("=== egp11 ===\n")
cat("Class:", class(df$egp11), "\n")
cat("Unique values:\n")
print(sort(unique(df$egp11)))
cat("Coverage:", round(100 * mean(!is.na(df$egp11)), 1), "%\n\n")

# egp11_label
cat("=== egp11_label ===\n")
cat("Class:", class(df$egp11_label), "\n")
if (is.factor(df$egp11_label)) cat("Levels:", levels(df$egp11_label), "\n")
cat("Unique values:\n")
print(sort(unique(as.character(df$egp11_label))))
cat("Coverage:", round(100 * mean(!is.na(df$egp11_label)), 1), "%\n\n")

# Cross-tab: how many have BOTH oesch8 and ordc?
cat("=== Joint coverage ===\n")
cat("oesch8 + ordc:", round(100 * mean(!is.na(df$oesch8) & !is.na(df$ordc)), 1), "%\n")
cat("oesch8 + egp11:", round(100 * mean(!is.na(df$oesch8) & !is.na(df$egp11)), 1), "%\n")
cat("oesch8 + ordc + egp11:", round(100 * mean(!is.na(df$oesch8) & !is.na(df$ordc) & !is.na(df$egp11)), 1), "%\n\n")

# For the class-comparison space, check complete cases with resources + class schemes
resource_vars <- c("income_quint_h", "eisced_5cat_h", "mother_edu_5cat",
                    "father_edu_5cat", "domicil_r")

cat("=== Class-comparison space complete cases (resources only) ===\n")
for (cc in c("PT", "ES", "GR", "IT")) {
  sub <- df %>% filter(cntry == cc)
  n_resources <- sub %>% filter(if_all(all_of(resource_vars), ~ !is.na(.))) %>% nrow()
  n_with_oesch <- sub %>% filter(if_all(all_of(c(resource_vars, "oesch8")), ~ !is.na(.))) %>% nrow()
  n_with_all3 <- sub %>% filter(if_all(all_of(c(resource_vars, "oesch8", "ordc", "egp11")), ~ !is.na(.))) %>% nrow()
  cat(cc, ": resources =", n_resources, "| +oesch =", n_with_oesch, "| +oesch+ordc+egp =", n_with_all3, "\n")
}
