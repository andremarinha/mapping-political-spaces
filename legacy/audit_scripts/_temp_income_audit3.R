library(dplyr, warn.conflicts = FALSE)

d <- readRDS("data/master/ess_final.rds")
d <- d[, c("cntry", "essround", "hinctnt", "hinctnta", "hinctnt_harmonised")]

cat("=== Portugal: hinctnt distribution in Round 2 ===\n")
vals <- d$hinctnt[d$cntry == "PT" & d$essround == 2]
print(table(vals, useNA = "always"))

cat("\n=== Portugal: hinctnt distribution in Round 3 ===\n")
vals <- d$hinctnt[d$cntry == "PT" & d$essround == 3]
print(table(vals, useNA = "always"))

cat("\n=== Portugal: hinctnta distribution in Round 4 ===\n")
vals <- d$hinctnta[d$cntry == "PT" & d$essround == 4]
print(table(vals, useNA = "always"))

cat("\n=== Portugal: hinctnta distribution in Round 6 ===\n")
vals <- d$hinctnta[d$cntry == "PT" & d$essround == 6]
print(table(vals, useNA = "always"))

# Also show all 4 countries for R1-3 to compare
cat("\n\n=== hinctnt by country, Round 1 (substantive values only) ===\n")
for (cc in c("PT", "ES", "GR", "IT")) {
  vals <- d$hinctnt[d$cntry == cc & d$essround == 1 & d$hinctnt %in% 1:12]
  if (length(vals) > 0) {
    cat(sprintf("\n%s (n=%d):\n", cc, length(vals)))
    print(table(vals))
  }
}

cat("\n=== hinctnt by country, Round 2 (substantive values only) ===\n")
for (cc in c("PT", "ES", "GR", "IT")) {
  vals <- d$hinctnt[d$cntry == cc & d$essround == 2 & d$hinctnt %in% 1:12]
  if (length(vals) > 0) {
    cat(sprintf("\n%s (n=%d):\n", cc, length(vals)))
    print(table(vals))
  }
}

cat("\n=== hinctnt by country, Round 3 (substantive values only) ===\n")
for (cc in c("PT", "ES", "GR")) {
  vals <- d$hinctnt[d$cntry == cc & d$essround == 3 & d$hinctnt %in% 1:12]
  if (length(vals) > 0) {
    cat(sprintf("\n%s (n=%d):\n", cc, length(vals)))
    print(table(vals))
  }
}

# Cumulative % to check whether 12-bracket maps similarly to 10-decile
cat("\n\n=== Portugal R2: hinctnt cumulative % (substantive 1-12) ===\n")
vals <- d$hinctnt[d$cntry == "PT" & d$essround == 2 & d$hinctnt %in% 1:12]
tbl <- table(vals)
cum_pct <- round(100 * cumsum(tbl) / sum(tbl), 1)
print(data.frame(bracket = names(tbl), n = as.integer(tbl), cum_pct = as.numeric(cum_pct)))

cat("\n=== Portugal R4: hinctnta cumulative % (substantive 1-10) ===\n")
vals <- d$hinctnta[d$cntry == "PT" & d$essround == 4 & d$hinctnta %in% 1:10]
tbl <- table(vals)
cum_pct <- round(100 * cumsum(tbl) / sum(tbl), 1)
print(data.frame(decile = names(tbl), n = as.integer(tbl), cum_pct = as.numeric(cum_pct)))
