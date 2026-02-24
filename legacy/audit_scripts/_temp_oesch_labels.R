# Temp: check oesch8 labels
library(tidyverse)
select <- dplyr::select
df <- readRDS("data/master/ess_final.rds")

cat("=== oesch8 values ===\n")
print(table(df$oesch8, useNA = "ifany"))

cat("\n=== oesch8_label values ===\n")
if ("oesch8_label" %in% names(df)) {
  print(table(df$oesch8_label, useNA = "ifany"))
  cat("\n=== Mapping oesch8 -> oesch8_label ===\n")
  print(df %>% filter(!is.na(oesch8)) %>%
    distinct(oesch8, oesch8_label) %>%
    arrange(oesch8))
} else {
  cat("oesch8_label not found in master\n")
}

# Also check vote_d values for supplementary
cat("\n=== vote_d values ===\n")
print(table(df$vote_d, useNA = "ifany"))
