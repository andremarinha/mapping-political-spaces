# Temp: test social space MCA for all 4 countries
library(tidyverse)
library(FactoMineR)
select <- dplyr::select

df <- readRDS("data/master/ess_final.rds")

social_active_h <- c("oesch8", "income_quint_h", "eisced_5cat",
                      "mother_edu_5cat", "father_edu_5cat", "domicil_r")
social_active_c <- c("oesch8", "income_quint", "eisced_5cat",
                      "mother_edu_5cat", "father_edu_5cat", "domicil_r")

oesch8_labels <- c("1" = "Self-emp prof", "2" = "Small business",
                    "3" = "Tech (semi-)prof", "4" = "Production",
                    "5" = "Managers", "6" = "Clerks",
                    "7" = "Socio-cult prof", "8" = "Service workers")
income_labels <- c("1" = "Q1 (lowest)", "2" = "Q2", "3" = "Q3",
                    "4" = "Q4", "5" = "Q5 (highest)")
edu_labels <- c("1" = "ISCED 0-1", "2" = "ISCED 2",
                "3" = "ISCED 3", "4" = "ISCED 4-5", "5" = "ISCED 6+")
domicil_labels <- c("1" = "Urban", "2" = "Suburban",
                     "3" = "Town", "4" = "Rural")
vote_labels <- c("0" = "Did not vote", "1" = "Voted")

benzecri_correction <- function(eig_table, J) {
  eig_raw <- eig_table[, 1]
  threshold <- 1 / J
  mask <- eig_raw > threshold
  eig_kept <- eig_raw[mask]
  modified <- ((J / (J - 1)) * (eig_kept - threshold))^2
  mod_pct  <- 100 * modified / sum(modified)
  mod_cum  <- cumsum(mod_pct)
  data.frame(dimension = seq_along(modified), raw_eigenvalue = eig_kept,
             modified_eigenvalue = modified, modified_pct = mod_pct,
             cumulative_pct = mod_cum)
}

countries <- c("PT", "ES", "GR", "IT")
country_labels <- c(PT = "Portugal", ES = "Spain", GR = "Greece", IT = "Italy")
J_soc <- length(social_active_h)

# Primary (income_quint_h)
cat("========== PRIMARY (income_quint_h) ==========\n")
for (cc in countries) {
  cd <- df %>%
    filter(cntry == cc) %>%
    filter(if_all(all_of(social_active_h), ~ !is.na(.)))

  soc_data <- cd %>%
    mutate(
      oesch8          = factor(oesch8, levels = 1:8, labels = oesch8_labels),
      income_quint_h  = factor(income_quint_h, levels = 1:5, labels = income_labels),
      eisced_5cat     = factor(eisced_5cat, levels = 1:5, labels = edu_labels),
      mother_edu_5cat = factor(mother_edu_5cat, levels = 1:5, labels = edu_labels),
      father_edu_5cat = factor(father_edu_5cat, levels = 1:5, labels = edu_labels),
      domicil_r       = factor(domicil_r, levels = 1:4, labels = domicil_labels),
      essround        = factor(essround),
      vote_d          = factor(vote_d, levels = 0:1, labels = vote_labels)
    )

  sup_cols <- c("essround", "vote_d")
  soc_input <- soc_data %>%
    select(oesch8, income_quint_h, eisced_5cat,
           mother_edu_5cat, father_edu_5cat, domicil_r,
           all_of(sup_cols))

  soc_res <- MCA(soc_input,
                 quali.sup = which(names(soc_input) %in% sup_cols),
                 ncp = 5, graph = FALSE)

  bz <- benzecri_correction(soc_res$eig, J_soc)

  cat("\n===", country_labels[cc], "(n =", nrow(soc_input), ") ===\n")
  cat("  Dims above threshold:", nrow(bz), "\n")
  cat("  Dim 1: raw", round(soc_res$eig[1, 2], 1), "% -> modified",
      round(bz$modified_pct[1], 1), "%\n")
  cat("  Dim 2: raw", round(soc_res$eig[2, 2], 1), "% -> modified",
      round(bz$modified_pct[2], 1), "%\n")
  cat("  Cumul (2): raw", round(soc_res$eig[2, 3], 1),
      "% -> modified", round(bz$cumulative_pct[2], 1), "%\n")
}

# Robustness (income_quint)
cat("\n\n========== ROBUSTNESS (income_quint) ==========\n")
for (cc in countries) {
  cd <- df %>%
    filter(cntry == cc) %>%
    filter(if_all(all_of(social_active_c), ~ !is.na(.)))

  soc_data <- cd %>%
    mutate(
      oesch8          = factor(oesch8, levels = 1:8, labels = oesch8_labels),
      income_quint    = factor(income_quint, levels = 1:5, labels = income_labels),
      eisced_5cat     = factor(eisced_5cat, levels = 1:5, labels = edu_labels),
      mother_edu_5cat = factor(mother_edu_5cat, levels = 1:5, labels = edu_labels),
      father_edu_5cat = factor(father_edu_5cat, levels = 1:5, labels = edu_labels),
      domicil_r       = factor(domicil_r, levels = 1:4, labels = domicil_labels),
      essround        = factor(essround),
      vote_d          = factor(vote_d, levels = 0:1, labels = vote_labels)
    )

  sup_cols <- c("essround", "vote_d")
  soc_input <- soc_data %>%
    select(oesch8, income_quint, eisced_5cat,
           mother_edu_5cat, father_edu_5cat, domicil_r,
           all_of(sup_cols))

  soc_res <- MCA(soc_input,
                 quali.sup = which(names(soc_input) %in% sup_cols),
                 ncp = 5, graph = FALSE)

  bz <- benzecri_correction(soc_res$eig, J_soc)

  cat("\n===", country_labels[cc], "(n =", nrow(soc_input), ") ===\n")
  cat("  Dims above threshold:", nrow(bz), "\n")
  cat("  Dim 1: raw", round(soc_res$eig[1, 2], 1), "% -> modified",
      round(bz$modified_pct[1], 1), "%\n")
  cat("  Dim 2: raw", round(soc_res$eig[2, 2], 1), "% -> modified",
      round(bz$modified_pct[2], 1), "%\n")
  cat("  Cumul (2): raw", round(soc_res$eig[2, 3], 1),
      "% -> modified", round(bz$cumulative_pct[2], 1), "%\n")
}
