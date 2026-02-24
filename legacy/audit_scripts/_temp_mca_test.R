library(tidyverse)
library(FactoMineR)

df <- readRDS("data/master/ess_final.rds")

active_vars <- c("freehms_r", "gincdif_r",
                  "imbgeco_3cat", "imueclt_3cat", "imwbcnt_3cat")
sup_vars <- c("oesch8", "domicil_r", "income_quint_h",
              "eisced_5cat", "mother_edu_5cat", "father_edu_5cat")

# Portugal: pooled MCA
cd <- df %>%
  dplyr::filter(cntry == "PT") %>%
  dplyr::filter(if_all(all_of(active_vars), ~ !is.na(.)))

cat("PT complete cases:", nrow(cd), "\n")

mca_data <- cd %>%
  mutate(across(all_of(active_vars), factor),
         essround = factor(essround))
for (v in sup_vars) mca_data[[v]] <- factor(mca_data[[v]])

mca_input <- mca_data %>% dplyr::select(all_of(active_vars), essround, all_of(sup_vars))
sup_cols <- c("essround", sup_vars)

cat("Running pooled MCA...\n")
t0 <- Sys.time()
mca <- MCA(mca_input,
           quali.sup = which(names(mca_input) %in% sup_cols),
           ncp = 5, graph = FALSE)
t1 <- Sys.time()
cat("Done in", round(difftime(t1, t0, units = "secs"), 1), "seconds\n")

cat("\n--- Eigenvalues (first 5) ---\n")
print(round(mca$eig[1:5, ], 3))

cat("\n--- Active category coordinates (Dim 1-2) ---\n")
print(round(mca$var$coord[, 1:2], 3))

cat("\n--- Supplementary: Round barycentres ---\n")
round_idx <- grepl("^essround_", rownames(mca$quali.sup$coord))
print(round(mca$quali.sup$coord[round_idx, 1:2], 3))

cat("\n--- Supplementary: Oesch-8 barycentres ---\n")
oesch_idx <- grepl("^oesch8_", rownames(mca$quali.sup$coord))
print(round(mca$quali.sup$coord[oesch_idx, 1:2], 3))

cat("\nPooled MCA test passed.\n")
