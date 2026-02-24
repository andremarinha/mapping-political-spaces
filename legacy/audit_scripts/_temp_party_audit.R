df <- readRDS("data/master/ess_final.rds")

# Party vote variables by country and round
party_vars <- list(
  PT = c("prtvtpt", "prtvtapt", "prtvtbpt", "prtvtcpt", "prtvtdpt", "prtvtept"),
  ES = c("prtvtes", "prtvtaes", "prtvtbes", "prtvtces", "prtvtdes", "prtvtees", "prtvtfes", "prtvtges"),
  GR = c("prtvtgr", "prtvtagr", "prtvtbgr", "prtvtcgr", "prtvtdgr", "prtvtegr"),
  IT = c("prtvtit", "prtvtait", "prtvtbit", "prtvtcit", "prtvtdit", "prtvteit")
)

cat("=== PARTY VOTE VARIABLES ===\n\n")

for (cntry in names(party_vars)) {
  cat("========", cntry, "========\n\n")
  for (v in party_vars[[cntry]]) {
    if (v %in% names(df)) {
      # Filter to this country's data
      d <- df[df$cntry == cntry, ]
      vals <- d[[v]]
      n_valid <- sum(!is.na(vals) & vals < 50)  # ESS codes 66/77/88/99 etc. are missing
      n_total <- nrow(d)
      
      cat("---", v, "---\n")
      cat("Class:", class(vals), "\n")
      cat("Valid (likely substantive):", n_valid, "/", n_total, "\n")
      
      # Which rounds does this variable have valid data?
      cat("Non-NA count by round:\n")
      round_counts <- tapply(!is.na(vals) & vals < 50, d$essround, sum, na.rm = TRUE)
      # Only show rounds with >0
      round_counts <- round_counts[round_counts > 0]
      print(round_counts)
      
      # Show the actual value distribution (substantive values only)
      sub_vals <- vals[!is.na(vals) & vals < 50]
      if (length(sub_vals) > 0) {
        cat("Value distribution:\n")
        print(sort(table(sub_vals), decreasing = TRUE))
      }
      cat("\n")
    } else {
      cat("---", v, ": NOT FOUND ---\n\n")
    }
  }
}
