# Temp: test Benzécri correction for all 4 countries
library(tidyverse)
library(FactoMineR)
select <- dplyr::select

df <- readRDS("data/master/ess_final.rds")
active_vars <- c("freehms_r", "gincdif_r",
                  "imbgeco_3cat", "imueclt_3cat", "imwbcnt_3cat")
countries <- c("PT", "ES", "GR", "IT")
country_labels <- c(PT = "Portugal", ES = "Spain", GR = "Greece", IT = "Italy")
J <- length(active_vars)

benzecri_correction <- function(eig_table, J) {
  eig_raw <- eig_table[, 1]
  threshold <- 1 / J
  mask <- eig_raw > threshold
  eig_kept <- eig_raw[mask]
  modified <- ((J / (J - 1)) * (eig_kept - threshold))^2
  mod_pct  <- 100 * modified / sum(modified)
  mod_cum  <- cumsum(mod_pct)
  data.frame(
    dimension = seq_along(modified),
    raw_eigenvalue = eig_kept,
    modified_eigenvalue = modified,
    modified_pct = mod_pct,
    cumulative_pct = mod_cum
  )
}

for (cc in countries) {
  cd <- df %>%
    filter(cntry == cc) %>%
    filter(if_all(all_of(active_vars), ~ !is.na(.)))

  mca_data <- cd %>%
    mutate(across(all_of(active_vars), factor),
           essround = factor(essround))
  mca_input <- mca_data %>% select(all_of(active_vars), essround)

  mca_res <- MCA(mca_input,
                 quali.sup = which(names(mca_input) == "essround"),
                 ncp = 5, graph = FALSE)

  bz <- benzecri_correction(mca_res$eig, J)

  cat("\n===", country_labels[cc], "===\n")
  cat("Dims above threshold:", nrow(bz), "\n")
  cat("Dim 1: raw", round(mca_res$eig[1, 2], 1), "% -> modified",
      round(bz$modified_pct[1], 1), "%\n")
  cat("Dim 2: raw", round(mca_res$eig[2, 2], 1), "% -> modified",
      round(bz$modified_pct[2], 1), "%\n")
  cat("Cumulative (2 dims): raw", round(mca_res$eig[2, 3], 1),
      "% -> modified", round(bz$cumulative_pct[2], 1), "%\n")
}
