# 08_class_distributions.R
# ── Script 08 — Class distributions by scheme (country × round) ─────────────
# Output:
#  - data/output/class_distributions_long.rds
#  - data/output/class_distributions_long.csv
#  - data/output/class_distributions_wide.csv

source("C:/Users/andre/Desktop/pilot/r_scripts/00_setup.R")

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(readr)
  library(purrr)
  library(stringr)
})

cat("\n── Script 08 — Class distributions by scheme (country × round) ───────────────────────────────────────────────────────────────────\n")

in_master <- "data/master/ess_master.rds"
stopifnot(file.exists(in_master))

master <- readRDS(in_master)

cat("Input:", in_master, "\n")
cat("Rows:", nrow(master), "\n")
cat("Countries:", paste(sort(unique(master$cntry)), collapse = ", "), "\n")
cat("Rounds:", paste(sort(unique(master$essround)), collapse = ", "), "\n")

# ---- Required vars ----
req <- c("cntry", "essround", "analysis_weight")
missing <- setdiff(req, names(master))
if (length(missing) > 0) {
  stop("! Missing required variables in master dataset:\n", paste0("x ", missing, collapse = "\n"))
}

# ---- Scheme registry: class var + label var (if exists) ----
schemes <- tibble::tribble(
  ~scheme,           ~class_var,          ~label_var,
  "egp_dig",         "egp_dig",           "egp_dig_label",
  "egp_mp_dig",      "egp_mp_dig",        "egp_mp_dig_label",
  "microclass_dig",  "microclass_dig",    "microclass_dig_label",
  "msec_dig",        "msec_dig",          "msec_dig_label",
  "oesch16_dig",     "oesch16_dig",       "oesch16_dig_label",
  "oesch8_dig",      "oesch8_dig",        "oesch8_dig_label",
  "oesch5_dig",      "oesch5_dig",        "oesch5_dig_label",
  "ordc_dig",        "ordc_dig",          "ordc_label",
  "wright_dig",      "wright_dig",        "wright_dig_label"
)

# Keep only schemes whose class var exists
schemes <- schemes %>% filter(class_var %in% names(master))
if (nrow(schemes) == 0) stop("No class scheme variables found in master dataset.")

# ---- Applicability rule (Option A): ONLY microclass is structurally NA in rounds < 6 ----
is_applicable <- function(scheme, essround) {
  !(scheme == "microclass_dig" && essround < 6)
}

# ---- Main grid ----
countries <- sort(unique(master$cntry))
rounds <- sort(unique(master$essround))

grid <- tidyr::crossing(
  cntry = countries,
  essround = rounds,
  scheme = schemes$scheme
)

# ---- Worker ----
compute_one <- function(cntry, essround, scheme) {
  
  sc <- schemes %>% filter(.data$scheme == scheme) %>% slice(1)
  class_var <- sc$class_var[[1]]
  label_var <- sc$label_var[[1]]
  
  df <- master %>%
    filter(.data$cntry == cntry, .data$essround == essround) %>%
    select(cntry, essround, analysis_weight, all_of(class_var), any_of(label_var))
  
  n_unw <- nrow(df)
  w_n <- sum(df$analysis_weight, na.rm = TRUE)
  
  applicable <- is_applicable(scheme, essround)
  
  # Build 2-row "type" backbone ALWAYS (prevents vector length mismatches)
  types <- c("unweighted", "weighted")
  base2 <- tibble::tibble(
    cntry = rep(cntry, 2),
    essround = rep(as.integer(essround), 2),
    scheme = rep(scheme, 2),
    type = types,
    level = rep("coverage", 2),
    class_code = rep(NA_character_, 2),
    class_label = rep(NA_character_, 2),
    n = c(n_unw, NA_real_),
    covered = rep(NA_real_, 2),
    share = rep(NA_real_, 2),
    w_n = c(NA_real_, w_n),
    w_covered = rep(NA_real_, 2),
    w_share = rep(NA_real_, 2),
    applicable = rep(applicable, 2),
    share_app = rep(NA_real_, 2),
    w_share_app = rep(NA_real_, 2)
  )
  
  # Structural non-applicability: keep the 2-row coverage skeleton, but all shares NA
  if (!applicable) {
    return(base2)
  }
  
  x <- df[[class_var]]
  ok <- !is.na(x)
  
  covered_unw <- sum(ok)
  share_unw <- if (n_unw > 0) covered_unw / n_unw else NA_real_
  
  w_covered <- sum(df$analysis_weight[ok], na.rm = TRUE)
  w_share <- if (!is.na(w_n) && w_n > 0) w_covered / w_n else NA_real_
  
  coverage_rows <- base2 %>%
    mutate(
      covered = c(covered_unw, NA_real_),
      share   = c(share_unw, NA_real_),
      w_covered = c(NA_real_, w_covered),
      w_share   = c(NA_real_, w_share),
      share_app = c(share_unw, NA_real_),
      w_share_app = c(NA_real_, w_share)
    )
  
  # Class label (optional)
  has_label <- label_var %in% names(df)
  
  # Unweighted distribution among covered only
  dist_unw <- df %>%
    filter(!is.na(.data[[class_var]])) %>%
    mutate(
      class_code = as.character(.data[[class_var]]),
      class_label = if (has_label) as.character(.data[[label_var]]) else NA_character_
    ) %>%
    count(cntry, essround, scheme, class_code, class_label, name = "n_class") %>%
    mutate(
      type = "unweighted",
      level = "class",
      n = NA_real_,
      covered = NA_real_,
      share = if (covered_unw > 0) n_class / covered_unw else NA_real_,
      w_n = NA_real_,
      w_covered = NA_real_,
      w_share = NA_real_,
      applicable = TRUE,
      share_app = share,
      w_share_app = NA_real_
    ) %>%
    select(cntry, essround, scheme, type, level, class_code, class_label,
           n, covered, share, w_n, w_covered, w_share, applicable, share_app, w_share_app)
  
  # Weighted distribution among covered only
  dist_w <- df %>%
    filter(!is.na(.data[[class_var]])) %>%
    mutate(
      class_code = as.character(.data[[class_var]]),
      class_label = if (has_label) as.character(.data[[label_var]]) else NA_character_
    ) %>%
    group_by(cntry, essround, scheme, class_code, class_label) %>%
    summarise(w_class = sum(analysis_weight, na.rm = TRUE), .groups = "drop") %>%
    mutate(
      type = "weighted",
      level = "class",
      n = NA_real_,
      covered = NA_real_,
      share = NA_real_,
      w_n = NA_real_,
      w_covered = NA_real_,
      w_share = if (!is.na(w_covered) && w_covered > 0) w_class / w_covered else NA_real_,
      applicable = TRUE,
      share_app = NA_real_,
      w_share_app = w_share
    ) %>%
    select(cntry, essround, scheme, type, level, class_code, class_label,
           n, covered, share, w_n, w_covered, w_share, applicable, share_app, w_share_app)
  
  bind_rows(coverage_rows, dist_unw, dist_w)
}

# ---- Run ----
out <- purrr::pmap_dfr(
  list(grid$cntry, grid$essround, grid$scheme),
  compute_one
)

# ---- Save outputs ----
dir.create("data/output", recursive = TRUE, showWarnings = FALSE)

out_csv <- "data/output/class_distributions_long.csv"
out_rds <- "data/output/class_distributions_long.rds"

readr::write_csv(out, out_csv, na = "")
saveRDS(out, out_rds)

cat("✔ Saved long distributions:", out_csv, "\n")
cat("✔ Saved long distributions (RDS):", out_rds, "\n")

# wide coverage view (only coverage rows)
wide_cov <- out %>%
  filter(level == "coverage") %>%
  select(cntry, essround, scheme, type, n, covered, share, w_n, w_covered, w_share,
         applicable, share_app, w_share_app) %>%
  arrange(type, scheme, cntry, essround)

out_wide <- "data/output/class_distributions_wide.csv"
readr::write_csv(wide_cov, out_wide, na = "")
cat("✔ Saved wide coverage view:", out_wide, "\n")

cat("\n── Done. ──\n")
