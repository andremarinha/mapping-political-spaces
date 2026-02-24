library(tidyverse)
library(FactoMineR)

df <- readRDS("data/master/ess_final.rds")

active_vars <- c("freehms_r", "gincdif_r",
                  "imbgeco_3cat", "imueclt_3cat", "imwbcnt_3cat")
sup_vars <- c("oesch8", "domicil_r", "income_quint_h",
              "eisced_5cat", "mother_edu_5cat", "father_edu_5cat")

# --- Build MFA data for Portugal ---
cc <- "PT"
cd <- df %>%
  dplyr::filter(cntry == cc) %>%
  dplyr::filter(if_all(all_of(active_vars), ~ !is.na(.)))

cat("PT complete cases:", nrow(cd), "\n")
rounds <- sort(unique(cd$essround))
cat("Rounds:", rounds, "\n")

n <- nrow(cd)
n_active <- length(active_vars)
n_rounds <- length(rounds)

# Active groups: one per round
active_cols <- list()
for (i in seq_along(rounds)) {
  r <- rounds[i]
  for (v in active_vars) {
    col_name <- paste0(v, "_R", r)
    active_cols[[col_name]] <- rep(NA_integer_, n)
    idx <- which(cd$essround == r)
    active_cols[[col_name]][idx] <- cd[[v]][idx]
  }
}
wide <- as.data.frame(active_cols)

# Convert to factors
for (col in names(wide)) {
  wide[[col]] <- factor(wide[[col]])
}

# Add supplementary variables
for (v in sup_vars) {
  wide[[v]] <- factor(cd[[v]])
}

cat("Wide data:", nrow(wide), "x", ncol(wide), "\n")
cat("Active columns:", n_active * n_rounds, "\n")
cat("Supplementary columns:", length(sup_vars), "\n")

# MFA parameters
group_sizes <- c(rep(n_active, n_rounds), rep(1, length(sup_vars)))
group_types <- c(rep("n", n_rounds), rep("n", length(sup_vars)))
group_names <- c(paste0("R", rounds), sup_vars)
sup_group_idx <- (n_rounds + 1):(n_rounds + length(sup_vars))

cat("\nRunning MFA...\n")
t0 <- Sys.time()
mfa <- MFA(wide,
           group = group_sizes,
           type = group_types,
           name.group = group_names,
           num.group.sup = sup_group_idx,
           ncp = 5,
           graph = FALSE)
t1 <- Sys.time()
cat("Done in", round(difftime(t1, t0, units = "secs"), 1), "seconds\n")

# Inspect results
cat("\n--- Eigenvalues (first 5) ---\n")
print(round(mfa$eig[1:5, ], 3))

cat("\n--- RV coefficients (active groups) ---\n")
rv <- mfa$group$RV[1:n_rounds, 1:n_rounds]
rownames(rv) <- paste0("R", rounds)
colnames(rv) <- paste0("R", rounds)
print(round(rv, 3))

cat("\n--- Top 10 category contributions to Dim 1 ---\n")
contrib1 <- mfa$quali.var$contrib[, 1]
print(round(head(sort(contrib1, decreasing = TRUE), 10), 3))

cat("\n--- Supplementary barycentres (Dim 1-2) ---\n")
print(round(mfa$quali.var.sup$coord[, 1:2], 3))

cat("\nMFA test passed.\n")
