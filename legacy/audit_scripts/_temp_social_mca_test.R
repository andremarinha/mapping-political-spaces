# Temp: test social space MCA on Portugal
library(tidyverse)
library(FactoMineR)
select <- dplyr::select

df <- readRDS("data/master/ess_final.rds")

social_active_h <- c("oesch8", "income_quint_h", "eisced_5cat",
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
  data.frame(
    dimension = seq_along(modified),
    raw_eigenvalue = eig_kept,
    modified_eigenvalue = modified,
    modified_pct = mod_pct,
    cumulative_pct = mod_cum
  )
}

J_soc <- length(social_active_h)

cc <- "PT"
cd <- df %>%
  filter(cntry == cc) %>%
  filter(if_all(all_of(social_active_h), ~ !is.na(.)))

cat("Portugal n:", nrow(cd), "\n")

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

# Check for empty factor levels
cat("\n=== Factor level counts ===\n")
for (v in social_active_h) {
  cat(v, ":\n")
  print(table(soc_data[[v]], useNA = "ifany"))
  cat("\n")
}

# Check supplementary
cat("vote_d:\n")
print(table(soc_data$vote_d, useNA = "ifany"))
cat("\n")

sup_cols_soc <- c("essround", "vote_d")
soc_input <- soc_data %>%
  select(oesch8, income_quint_h, eisced_5cat,
         mother_edu_5cat, father_edu_5cat, domicil_r,
         all_of(sup_cols_soc))

cat("Running MCA...\n")
soc_res <- MCA(soc_input,
               quali.sup = which(names(soc_input) %in% sup_cols_soc),
               ncp = 5,
               graph = FALSE)

cat("\n=== Raw eigenvalues ===\n")
print(round(soc_res$eig[1:10, ], 3))

bz <- benzecri_correction(soc_res$eig, J_soc)
cat("\n=== Benzécri correction ===\n")
cat("Dims above threshold:", nrow(bz), "of", nrow(soc_res$eig), "\n")
print(round(bz, 3))

cat("\n=== Active category coordinates (Dim 1-2) ===\n")
print(round(soc_res$var$coord[, 1:2], 3))

cat("\n=== Supplementary barycentres (Dim 1-2) ===\n")
print(round(soc_res$quali.sup$coord[, 1:2], 3))

cat("\n=== Top 10 contributions to Dim 1 ===\n")
top1 <- head(soc_res$var$contrib[order(-soc_res$var$contrib[, 1]), , drop = FALSE], 10)
print(round(top1[, 1, drop = FALSE], 2))

cat("\n=== Top 10 contributions to Dim 2 ===\n")
top2 <- head(soc_res$var$contrib[order(-soc_res$var$contrib[, 2]), , drop = FALSE], 10)
print(round(top2[, 2, drop = FALSE], 2))

cat("\nDone.\n")
