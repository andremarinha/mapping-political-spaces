library(tidyverse)
library(poLCA)

# poLCA loads MASS which masks dplyr::select — fix it
select <- dplyr::select

df <- readRDS("data/master/ess_final.rds")

active_vars <- c("freehms_r", "gincdif_r",
                  "imbgeco_3cat", "imueclt_3cat", "imwbcnt_3cat")
participation_vars <- c("badge_d", "bctprd_d", "contplt_d",
                         "sgnptit_d", "pbldmn_d", "vote_d")

# Prepare LCA data
lca_data <- df %>%
  select(idno, cntry, essround, all_of(participation_vars)) %>%
  mutate(across(all_of(participation_vars), ~ . + 1L)) %>%
  filter(if_all(all_of(participation_vars), ~ !is.na(.)))

cat("LCA-ready:", nrow(lca_data), "\n")
cat("By country:\n")
print(table(lca_data$cntry))

# Test: fit K=2 and K=3 for Portugal only
pt_data <- lca_data %>% filter(cntry == "PT")
f <- cbind(badge_d, bctprd_d, contplt_d, sgnptit_d, pbldmn_d, vote_d) ~ 1

cat("\nFitting K=2 for PT...\n")
set.seed(42)
m2 <- poLCA(f, data = pt_data, nclass = 2, nrep = 10, verbose = FALSE, graphs = FALSE)
cat("BIC:", m2$bic, "| AIC:", m2$aic, "| N:", m2$N, "\n")
cat("Class sizes:", round(m2$P, 3), "\n")
cat("Item-response probs (P(Yes)):\n")
for (v in participation_vars) {
  cat(sprintf("  %-12s: %s\n", v, paste(round(m2$probs[[v]][, 2], 3), collapse = "  ")))
}

cat("\nFitting K=3 for PT...\n")
set.seed(42)
m3 <- poLCA(f, data = pt_data, nclass = 3, nrep = 10, verbose = FALSE, graphs = FALSE)
cat("BIC:", m3$bic, "| AIC:", m3$aic, "\n")
cat("Class sizes:", round(m3$P, 3), "\n")
cat("Item-response probs (P(Yes)):\n")
for (v in participation_vars) {
  cat(sprintf("  %-12s: %s\n", v, paste(round(m3$probs[[v]][, 2], 3), collapse = "  ")))
}

cat("\nLCA test passed.\n")
