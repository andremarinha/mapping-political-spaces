library(dplyr, warn.conflicts = FALSE)

d <- readRDS("data/master/ess_final.rds")
d <- d[, c("cntry", "essround", "hinctnt", "hinctnta", "hinctnt_harmonised", "hinctnt_source")]

cat("=== hinctnt (R1-3): value distribution ===\n")
for (r in 1:3) {
  cat(sprintf("\nRound %d:\n", r))
  print(table(d$hinctnt[d$essround == r], useNA = "always"))
}

cat("\n=== hinctnta (R4+): value distribution (R4 only as example) ===\n")
print(table(d$hinctnta[d$essround == 4], useNA = "always"))

cat("\n=== hinctnt_harmonised: source breakdown ===\n")
print(table(d$hinctnt_source, d$essround))

cat("\n=== hinctnt_harmonised: value range by round ===\n")
for (r in 1:5) {
  vals <- d$hinctnt_harmonised[d$essround == r & !is.na(d$hinctnt_harmonised)]
  cat(sprintf("Round %d: range %s-%s, unique values: %s\n",
              r, min(vals), max(vals), paste(sort(unique(vals)), collapse=",")))
}

cat("\n=== Key: hinctnt uses 1-12 brackets, hinctnta uses 1-10 deciles ===\n")
cat("These are DIFFERENT scales if hinctnt goes up to 12.\n")
