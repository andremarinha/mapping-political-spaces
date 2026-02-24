# Audit edulvla: what are the categories, and can we harmonise with eisced_5cat?
library(tidyverse)
select <- dplyr::select

df <- readRDS("data/master/ess_final.rds")

cat("=== edulvla values ===\n")
print(table(df$edulvla, useNA = "ifany"))

# By country x round
cat("\n=== edulvla by country x round ===\n")
for (cc in c("PT", "ES", "GR", "IT")) {
  cat("\n---", cc, "---\n")
  cd <- df %>% filter(cntry == cc)
  for (r in sort(unique(cd$essround))) {
    cr <- cd %>% filter(essround == r, !is.na(edulvla))
    if (nrow(cr) > 0) {
      vals <- table(cr$edulvla)
      cat(sprintf("  R%d (n=%d): ", r, nrow(cr)))
      cat(paste(names(vals), "=", vals, collapse = ", "), "\n")
    }
  }
}

# Where eisced_5cat is NA but edulvla is available
cat("\n=== Potential recovery: eisced_5cat is NA but edulvla is available ===\n")
recoverable <- df %>%
  filter(is.na(eisced_5cat) & !is.na(edulvla) & !edulvla %in% c(77, 88, 99))
cat("Total recoverable:", nrow(recoverable), "\n")
for (cc in c("PT", "ES", "GR", "IT")) {
  cd <- recoverable %>% filter(cntry == cc)
  if (nrow(cd) > 0) {
    cat(cc, ": rounds", paste(sort(unique(cd$essround)), collapse = ", "),
        "| n =", nrow(cd), "\n")
  }
}

# Cross-tab: for R4 where BOTH exist (ES, PT), do they map consistently?
cat("\n=== R4 cross-check: edulvla vs eisced_5cat (where both exist) ===\n")
both <- df %>%
  filter(!is.na(edulvla) & edulvla < 77 & !is.na(eisced_5cat))
if (nrow(both) > 0) {
  cat("Observations with both:", nrow(both), "\n")
  cat("Countries:", paste(unique(both$cntry), collapse = ", "), "\n")
  cat("Rounds:", paste(sort(unique(both$essround)), collapse = ", "), "\n\n")
  cat("Cross-tab edulvla → eisced_5cat:\n")
  print(table(edulvla = both$edulvla, eisced_5cat = both$eisced_5cat))

  cat("\nRow percentages (how edulvla maps to eisced_5cat):\n")
  ct <- table(both$edulvla, both$eisced_5cat)
  print(round(prop.table(ct, margin = 1) * 100, 1))
}

# Also check edulvlb
cat("\n\n=== edulvlb ===\n")
cat("Values:", paste(sort(unique(df$edulvlb)), collapse = ", "), "\n")
for (cc in c("PT", "ES", "GR", "IT")) {
  cd <- df %>% filter(cntry == cc, !is.na(edulvlb), !edulvlb %in% c(77, 88, 99))
  if (nrow(cd) > 0) {
    cat(cc, ": rounds", paste(sort(unique(cd$essround)), collapse = ", "),
        "| n =", nrow(cd), "\n")
  }
}
