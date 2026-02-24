library(dplyr, warn.conflicts = FALSE)
library(tidyr)

d <- readRDS("data/master/ess_final.rds")
d <- d[, c("cntry", "essround", "hinctnt", "hinctnta", "hinctnt_harmonised")]

# What does hinctnt_harmonised look like once we strip out 77/88/99?
cat("=== hinctnt_harmonised: substantive values (excluding 77/88/99) ===\n")
d <- d %>%
  mutate(inc_clean = ifelse(hinctnt_harmonised %in% c(77, 88, 99), NA, hinctnt_harmonised))

cat("\nOverall valid (non-NA, not 77/88/99):", sum(!is.na(d$inc_clean)), "/", nrow(d),
    "(", round(100*mean(!is.na(d$inc_clean)),1), "%)\n")

cat("\n--- Valid % by country x round ---\n")
d %>%
  mutate(valid = !is.na(inc_clean)) %>%
  group_by(cntry, essround) %>%
  summarise(pct = round(100*mean(valid),1), .groups="drop") %>%
  pivot_wider(names_from = essround, values_from = pct, names_prefix = "R") %>%
  as.data.frame() %>%
  print()

# Compare: current income_quint coverage vs potential harmonised coverage
cat("\n--- COMPARISON: current vs harmonised coverage ---\n")
cat("Current income_quint (hinctnta R4+ only):",
    sum(!is.na(d$hinctnta) & d$hinctnta %in% 1:10), "/", nrow(d), "\n")
cat("Potential harmonised (hinctnt_harmonised, clean):",
    sum(!is.na(d$inc_clean)), "/", nrow(d), "\n")
cat("Gain:", sum(!is.na(d$inc_clean)) - sum(!is.na(d$hinctnta) & d$hinctnta %in% 1:10), "respondents\n")

# Show what empirical quintiles would look like for PT R2 using ntile()
cat("\n--- Example: empirical quintiles for PT R2 (hinctnt 1-12) ---\n")
pt_r2 <- d %>% filter(cntry == "PT", essround == 2, !is.na(inc_clean))
pt_r2 <- pt_r2 %>% mutate(emp_quint = ntile(inc_clean, 5))
cat("n =", nrow(pt_r2), "\n")
print(table(pt_r2$emp_quint))
cat("\nMapping of original brackets to empirical quintiles:\n")
print(pt_r2 %>% count(inc_clean, emp_quint) %>% pivot_wider(names_from = emp_quint, values_from = n, names_prefix = "Q"))

# Same for PT R4 (hinctnta 1-10)
cat("\n--- Example: empirical quintiles for PT R4 (hinctnta 1-10) ---\n")
pt_r4 <- d %>% filter(cntry == "PT", essround == 4, !is.na(inc_clean))
pt_r4 <- pt_r4 %>% mutate(emp_quint = ntile(inc_clean, 5))
cat("n =", nrow(pt_r4), "\n")
print(table(pt_r4$emp_quint))
cat("\nMapping of original deciles to empirical quintiles:\n")
print(pt_r4 %>% count(inc_clean, emp_quint) %>% pivot_wider(names_from = emp_quint, values_from = n, names_prefix = "Q"))

# And for ES R2 to show another country
cat("\n--- Example: empirical quintiles for ES R2 (hinctnt 1-12) ---\n")
es_r2 <- d %>% filter(cntry == "ES", essround == 2, !is.na(inc_clean))
es_r2 <- es_r2 %>% mutate(emp_quint = ntile(inc_clean, 5))
cat("n =", nrow(es_r2), "\n")
print(table(es_r2$emp_quint))
cat("\nMapping of original brackets to empirical quintiles:\n")
print(es_r2 %>% count(inc_clean, emp_quint) %>% pivot_wider(names_from = emp_quint, values_from = n, names_prefix = "Q"))
