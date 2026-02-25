# Test class-comparison space MCA for Portugal
library(tidyverse)
library(FactoMineR)

df <- readRDS("data/master/ess_final.rds")

# Labels
oesch8_labels <- c("1" = "Self-emp prof", "2" = "Small business",
  "3" = "Tech (semi-)prof", "4" = "Production", "5" = "Managers",
  "6" = "Clerks", "7" = "Socio-cult prof", "8" = "Service workers")
income_labels <- c("1" = "Q1 (lowest)", "2" = "Q2", "3" = "Q3",
                    "4" = "Q4", "5" = "Q5 (highest)")
edu_labels <- c("1" = "ISCED 0-1", "2" = "ISCED 2",
                "3" = "ISCED 3", "4" = "ISCED 4-5", "5" = "ISCED 6+")
domicil_labels <- c("1" = "Urban", "2" = "Suburban",
                     "3" = "Town", "4" = "Rural")

ordc_labels <- c("1" = "Cult Upper", "2" = "Bal Upper", "3" = "Econ Upper",
  "4" = "Cult Up-Mid", "5" = "Bal Up-Mid", "6.1" = "Econ Up-Mid(a)",
  "6.2" = "Econ Up-Mid(b)", "7" = "Cult Lo-Mid", "8" = "Bal Lo-Mid",
  "10" = "Skill WC", "11" = "Unskill WC", "12" = "Primary")

egp_labels <- c("1" = "I Hi Prof", "2" = "II Lo Prof", "3" = "IIIa Rout NM+",
  "4" = "IIIb Rout NM-", "5" = "IVa Sm Prop+", "7" = "IVc Farmer",
  "8" = "V Lo Tech", "9" = "VI Skill Man", "10" = "VIIa Unskill",
  "11" = "VIIb Farm Lab")

resource_active <- c("income_quint_h", "eisced_5cat_h",
                     "mother_edu_5cat", "father_edu_5cat", "domicil_r")

# Benzécri helper
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

cc <- "PT"
J_comp <- length(resource_active)

cd <- df %>%
  filter(cntry == cc) %>%
  filter(if_all(all_of(resource_active), ~ !is.na(.)))

cat("Complete cases (resources):", nrow(cd), "\n")

comp_data <- cd %>%
  mutate(
    income_quint_h  = factor(income_quint_h, levels = 1:5, labels = income_labels),
    eisced_5cat_h   = factor(eisced_5cat_h, levels = 1:5, labels = edu_labels),
    mother_edu_5cat = factor(mother_edu_5cat, levels = 1:5, labels = edu_labels),
    father_edu_5cat = factor(father_edu_5cat, levels = 1:5, labels = edu_labels),
    domicil_r       = factor(domicil_r, levels = 1:4, labels = domicil_labels),
    oesch8 = factor(oesch8, levels = 1:8, labels = oesch8_labels),
    ordc   = factor(ordc, levels = names(ordc_labels), labels = ordc_labels),
    egp11  = factor(egp11, levels = names(egp_labels), labels = egp_labels),
    essround = factor(essround)
  )

sup_cols_comp <- c("oesch8", "ordc", "egp11", "essround")

comp_input <- comp_data %>%
  select(all_of(resource_active), all_of(sup_cols_comp))

cat("Input dimensions:", nrow(comp_input), "x", ncol(comp_input), "\n")
cat("Columns:", names(comp_input), "\n")

# Check NAs in supplementary
for (v in sup_cols_comp) {
  cat(v, "NA:", sum(is.na(comp_input[[v]])), "/", nrow(comp_input), "\n")
}

res <- MCA(comp_input,
           quali.sup = which(names(comp_input) %in% sup_cols_comp),
           ncp = 5,
           graph = FALSE)

cat("\n=== Eigenvalues ===\n")
print(head(res$eig, 10))

bz <- benzecri_correction(res$eig, J_comp)
cat("\n=== Benzécri ===\n")
print(bz)

cat("\n=== Supplementary barycentres ===\n")
sup_coord <- as.data.frame(res$quali.sup$coord[, 1:2])
sup_coord$category <- rownames(sup_coord)
print(sup_coord)
