# participation_audit.R — Check availability of participation variables by round and country

library(dplyr)

d <- readRDS("G:/My Drive/1_projects/mapping/data/master/ess_final.rds")

vars <- c("badge","bctprd","contplt","sgnptit","pbldmn","pbldmna",
          "vote","wrkorg","wrkprty","clsprty","donprty","pstplonl")

existing <- vars[vars %in% names(d)]
missing  <- vars[!vars %in% names(d)]
if (length(missing) > 0) {
  cat("Variables NOT found in master:", paste(missing, collapse=", "), "\n\n")
}

cat("=== PARTICIPATION VARIABLE AVAILABILITY BY ESS ROUND ===\n\n")

for (v in existing) {
  cat(sprintf("--- %s ---\n", v))
  tab <- d %>%
    group_by(essround) %>%
    summarise(
      n_total = n(),
      n_valid = sum(!is.na(.data[[v]])),
      pct_valid = round(100 * n_valid / n_total, 1),
      .groups = "drop"
    ) %>%
    arrange(essround)
  print(as.data.frame(tab), row.names = FALSE)
  cat("\n")
}

cat("\n=== wrkorg AVAILABILITY BY ROUND x COUNTRY ===\n\n")
if ("wrkorg" %in% existing) {
  tab2 <- d %>%
    filter(cntry %in% c("PT","ES","GR","IT")) %>%
    group_by(essround, cntry) %>%
    summarise(
      n_total = n(),
      n_valid = sum(!is.na(wrkorg)),
      pct_valid = round(100 * n_valid / n_total, 1),
      .groups = "drop"
    ) %>%
    arrange(essround, cntry)
  print(as.data.frame(tab2), row.names = FALSE)
} else {
  cat("wrkorg not found.\n")
}

cat("\n\n=== wrkprty AVAILABILITY BY ROUND x COUNTRY ===\n\n")
if ("wrkprty" %in% existing) {
  tab3 <- d %>%
    filter(cntry %in% c("PT","ES","GR","IT")) %>%
    group_by(essround, cntry) %>%
    summarise(
      n_total = n(),
      n_valid = sum(!is.na(wrkprty)),
      pct_valid = round(100 * n_valid / n_total, 1),
      .groups = "drop"
    ) %>%
    arrange(essround, cntry)
  print(as.data.frame(tab3), row.names = FALSE)
} else {
  cat("wrkprty not found.\n")
}

cat("\nDone.\n")
