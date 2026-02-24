library(dplyr, warn.conflicts = FALSE)
library(tidyr)

cat("Loading master...\n")
d <- readRDS("data/master/ess_final.rds")
cat("Loaded:", nrow(d), "x", ncol(d), "\n\n")

# Select only what we need to free memory
d <- d[, c("cntry", "essround", "hinctnta")]
gc(verbose = FALSE)

cat("=== hinctnta: all values by round (including codes > 10) ===\n")
for (r in sort(unique(d$essround))) {
  vals <- d$hinctnta[d$essround == r]
  cat(sprintf("\nRound %d (n=%d):\n", r, length(vals)))
  print(table(vals, useNA = "always"))
}

cat("\n\n=== Valid (1-10) % by country x round ===\n")
result <- d %>%
  mutate(valid = !is.na(hinctnta) & hinctnta >= 1 & hinctnta <= 10) %>%
  group_by(cntry, essround) %>%
  summarise(n = n(), valid_n = sum(valid),
            pct = round(100 * mean(valid), 1), .groups = "drop")

# Print as wide table
wide <- result %>%
  select(cntry, essround, pct) %>%
  pivot_wider(names_from = essround, values_from = pct, names_prefix = "R")
print(as.data.frame(wide))

cat("\n=== Sample size by country x round ===\n")
wide_n <- result %>%
  select(cntry, essround, n) %>%
  pivot_wider(names_from = essround, values_from = n, names_prefix = "R")
print(as.data.frame(wide_n))

cat("\n=== Overall by round ===\n")
overall <- d %>%
  mutate(valid = !is.na(hinctnta) & hinctnta >= 1 & hinctnta <= 10) %>%
  group_by(essround) %>%
  summarise(n = n(), valid = sum(valid),
            miss_pct = round(100 * (1 - mean(valid)), 1), .groups = "drop")
print(as.data.frame(overall))

# Check: is hinctnt (old variable) present?
cat("\n=== Checking if hinctnt (old income brackets R1-3) exists ===\n")
d_full <- readRDS("data/master/ess_final.rds")
if ("hinctnt" %in% names(d_full)) {
  cat("hinctnt EXISTS in master\n")
  d2 <- d_full[, c("cntry", "essround", "hinctnt")]
  for (r in 1:3) {
    vals <- d2$hinctnt[d2$essround == r]
    cat(sprintf("\nhinctnt Round %d (n=%d, non-NA=%d):\n", r, length(vals), sum(!is.na(vals))))
  }
} else {
  cat("hinctnt NOT in master\n")
}
rm(d_full); gc(verbose = FALSE)
