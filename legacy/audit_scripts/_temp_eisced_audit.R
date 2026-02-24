# Audit: why does eisced_5cat have 0 obs in early rounds for PT/GR/IT?
# Check the RAW eisced variable + edulvla
library(tidyverse)
select <- dplyr::select

df <- readRDS("data/master/ess_final.rds")

# 1. Does eisced exist in the data? What values?
cat("=== eisced overall ===\n")
cat("Column exists:", "eisced" %in% names(df), "\n")
if ("eisced" %in% names(df)) {
  cat("Unique values:", paste(sort(unique(df$eisced)), collapse = ", "), "\n")
  print(table(df$eisced, useNA = "ifany"))
}

# 2. eisced by country x round — is value 0 the culprit?
cat("\n\n=== eisced distribution by country x round ===\n")
for (cc in c("PT", "ES", "GR", "IT")) {
  cat("\n---", cc, "---\n")
  cd <- df %>% filter(cntry == cc)
  for (r in sort(unique(cd$essround))) {
    cr <- cd %>% filter(essround == r)
    vals <- table(cr$eisced, useNA = "ifany")
    cat(sprintf("  R%d (n=%d): ", r, nrow(cr)))
    cat(paste(names(vals), "=", vals, collapse = ", "), "\n")
  }
}

# 3. Does edulvla exist?
cat("\n\n=== edulvla ===\n")
cat("Column exists:", "edulvla" %in% names(df), "\n")
if ("edulvla" %in% names(df)) {
  cat("Unique values:", paste(sort(unique(df$edulvla)), collapse = ", "), "\n")
  cat("\nBy country x round:\n")
  for (cc in c("PT", "ES", "GR", "IT")) {
    cd <- df %>% filter(cntry == cc, !is.na(edulvla))
    if (nrow(cd) > 0) {
      cat(cc, ": rounds", paste(sort(unique(cd$essround)), collapse = ", "),
          "| n =", nrow(cd), "\n")
    } else {
      cat(cc, ": no data\n")
    }
  }
}

# 4. Also check edulvlb (another education variable?)
for (edvar in c("edulvlb", "edlvla", "edlvlb", "edulvl")) {
  cat("\n", edvar, "exists:", edvar %in% names(df), "\n")
}

# 5. How does script 08 create eisced_5cat? Check the actual recode
cat("\n\n=== eisced_5cat creation audit ===\n")
cat("eisced_5cat unique values:", paste(sort(unique(df$eisced_5cat)), collapse = ", "), "\n")
cat("eisced_5cat NAs:", sum(is.na(df$eisced_5cat)), "/", nrow(df), "\n\n")

# Cross-tab eisced vs eisced_5cat
if ("eisced" %in% names(df)) {
  cat("Cross-tab eisced -> eisced_5cat:\n")
  print(table(df$eisced, df$eisced_5cat, useNA = "ifany"))
}
