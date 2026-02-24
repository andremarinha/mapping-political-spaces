# Check: social space coverage with eisced_5cat_h
library(tidyverse)
select <- dplyr::select
df <- readRDS("data/master/ess_final.rds")

social_vars_new <- c("oesch8", "income_quint_h", "eisced_5cat_h",
                      "mother_edu_5cat", "father_edu_5cat", "domicil_r")
social_vars_old <- c("oesch8", "income_quint_h", "eisced_5cat",
                      "mother_edu_5cat", "father_edu_5cat", "domicil_r")

cat("=== Complete cases comparison ===\n\n")
for (cc in c("PT", "ES", "GR", "IT")) {
  cd <- df %>% filter(cntry == cc)
  n_old <- cd %>% filter(if_all(all_of(social_vars_old), ~ !is.na(.))) %>% nrow()
  n_new <- cd %>% filter(if_all(all_of(social_vars_new), ~ !is.na(.))) %>% nrow()
  cat(sprintf("  %s: OLD (eisced_5cat) = %5d (%.1f%%)  |  NEW (eisced_5cat_h) = %5d (%.1f%%)  |  +%d\n",
              cc, n_old, 100*n_old/nrow(cd), n_new, 100*n_new/nrow(cd), n_new - n_old))
}

cat("\n\n=== NEW complete cases by country x round ===\n")
cc_new <- df %>% filter(if_all(all_of(social_vars_new), ~ !is.na(.)))
cat("Total:", nrow(cc_new), "/", nrow(df), "(", round(100*nrow(cc_new)/nrow(df), 1), "%)\n\n")
print(addmargins(table(cc_new$cntry, cc_new$essround)))

cat("\n\n=== OLD complete cases by country x round ===\n")
cc_old <- df %>% filter(if_all(all_of(social_vars_old), ~ !is.na(.)))
cat("Total:", nrow(cc_old), "/", nrow(df), "(", round(100*nrow(cc_old)/nrow(df), 1), "%)\n\n")
print(addmargins(table(cc_old$cntry, cc_old$essround)))

# Also: without oesch8 (for the class-comparison space user wants)
social_no_class <- c("income_quint_h", "eisced_5cat_h",
                      "mother_edu_5cat", "father_edu_5cat", "domicil_r")
cat("\n\n=== Without oesch8 (class-comparison space) ===\n")
cc_noclass <- df %>% filter(if_all(all_of(social_no_class), ~ !is.na(.)))
cat("Total:", nrow(cc_noclass), "/", nrow(df), "(", round(100*nrow(cc_noclass)/nrow(df), 1), "%)\n\n")
print(addmargins(table(cc_noclass$cntry, cc_noclass$essround)))
