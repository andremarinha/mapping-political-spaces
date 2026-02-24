# Temp script: test Benzécri correction on Portugal pooled MCA
# Path: legacy/audit_scripts/_temp_benzecri_test.R

library(tidyverse)
library(FactoMineR)

select <- dplyr::select

df <- readRDS("data/master/ess_final.rds")

active_vars <- c("freehms_r", "gincdif_r",
                  "imbgeco_3cat", "imueclt_3cat", "imwbcnt_3cat")

# Run pooled MCA for Portugal
cd <- df %>%
  filter(cntry == "PT") %>%
  filter(if_all(all_of(active_vars), ~ !is.na(.)))

mca_data <- cd %>%
  mutate(across(all_of(active_vars), factor),
         essround = factor(essround))

mca_input <- mca_data %>% select(all_of(active_vars), essround)

mca_pt <- MCA(mca_input,
              quali.sup = which(names(mca_input) == "essround"),
              ncp = 5,
              graph = FALSE)

# --- Raw eigenvalues ---
cat("=== RAW MCA eigenvalues ===\n")
print(round(mca_pt$eig, 4))

# --- Benzécri correction ---
# J = number of active variables
J <- length(active_vars)
cat("\nJ (number of active variables):", J, "\n")
cat("Threshold (1/J):", 1/J, "\n\n")

eig_raw <- mca_pt$eig[, 1]  # raw eigenvalues

# Only keep eigenvalues > 1/J
mask <- eig_raw > (1/J)
cat("Eigenvalues above threshold:", sum(mask), "out of", length(eig_raw), "\n\n")

# Benzécri formula: modified_λ = ((J/(J-1)) * (λ - 1/J))²
eig_modified <- ((J / (J - 1)) * (eig_raw[mask] - 1/J))^2

# Modified rates (% of modified inertia)
mod_rates <- 100 * eig_modified / sum(eig_modified)
mod_cum   <- cumsum(mod_rates)

cat("=== MODIFIED (Benzécri) eigenvalues ===\n")
benzecri_table <- data.frame(
  Dimension = 1:length(eig_modified),
  Raw_eigenvalue = round(eig_raw[mask], 4),
  Modified_eigenvalue = round(eig_modified, 4),
  Modified_rate_pct = round(mod_rates, 2),
  Cumulative_pct = round(mod_cum, 2)
)
print(benzecri_table, row.names = FALSE)

cat("\n=== Comparison: raw vs modified rates ===\n")
cat("Raw Dim 1:", round(mca_pt$eig[1, 2], 2), "% -> Modified Dim 1:", round(mod_rates[1], 2), "%\n")
cat("Raw Dim 2:", round(mca_pt$eig[2, 2], 2), "% -> Modified Dim 2:", round(mod_rates[2], 2), "%\n")
if (length(mod_rates) >= 3) {
  cat("Raw Dim 3:", round(mca_pt$eig[3, 2], 2), "% -> Modified Dim 3:", round(mod_rates[3], 2), "%\n")
}
cat("\nModified cumulative (first 2 dims):", round(mod_cum[min(2, length(mod_cum))], 2), "%\n")
