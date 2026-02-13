# 09_class_tables_and_coverage_plots.R
# ── Script 09 — Tables (9A) + Coverage plots (9B) ───────────────────────────
# Option A:
#  - scheme-specific scaling (free scales) so within-scheme patterns are readable
#  - viridis palette reversed: light=low, dark=high (more intuitive)
#  - structural non-applicability shown as grey (NA)
#  - subtitle moved to a note at the bottom (caption)
#  - save heatmaps to PNG *and* PDF

source("C:/Users/andre/Desktop/pilot/r_scripts/00_setup.R")

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(readr)
  library(ggplot2)
  library(stringr)
  library(forcats)
  library(viridis)  # for scale_fill_viridis_c
})

cat("\n── Script 09 — Tables (9A) + Coverage plots (9B) ───────────────────────────\n")

in_rds <- "data/output/class_distributions_long.rds"
stopifnot(file.exists(in_rds))

dig_long <- readRDS(in_rds)
cat("✔ Loaded:", in_rds, "\n")

# ---- Robustness: ensure expected columns exist ----
needed_base <- c("cntry","essround","scheme","type","n","covered","share","w_n","w_covered","w_share")
missing_base <- setdiff(needed_base, names(dig_long))
if (length(missing_base) > 0) {
  stop("! Missing required variables in class_distributions_long:\n", paste0("x ", missing_base, collapse = "\n"))
}

# If class-level columns are absent, create placeholders (so Script 09 can still run coverage outputs)
if (!("class_code" %in% names(dig_long)))  dig_long$class_code  <- NA
if (!("class_label" %in% names(dig_long))) dig_long$class_label <- NA

# ---- Structural applicability rules (Option A logic stays in Script 09) ----
# The ONLY thing we treat as *structurally non-applicable* is microclass in rounds < 6
# (i.e., ISCO-08 not present; we intentionally do not backcast via crosswalk here).
dig_long <- dig_long %>%
  mutate(
    applicable = case_when(
      scheme == "microclass_dig" & essround < 6 ~ FALSE,
      TRUE ~ TRUE
    ),
    share_app   = if_else(applicable, share,   NA_real_),
    w_share_app = if_else(applicable, w_share, NA_real_)
  )

# ---- Output folders ----
dir.create("data/output/09_tables",  recursive = TRUE, showWarnings = FALSE)
dir.create("data/output/09_figures", recursive = TRUE, showWarnings = FALSE)

# ── 9C already exists upstream; here we (re)produce 9A/9B outputs ───────────

# ---- Coverage table (country × round × scheme) ----
coverage_tbl <- dig_long %>%
  filter(is.na(class_code)) %>%              # coverage rows are the scheme-level summary rows
  select(cntry, essround, scheme, type, n, covered, share, w_n, w_covered, w_share,
         applicable, share_app, w_share_app) %>%
  arrange(type, scheme, cntry, essround)

out_cov <- "data/output/09_tables/coverage_by_scheme_country_round.csv"
readr::write_csv(coverage_tbl, out_cov, na = "")
cat("✔ Saved coverage table:\n  ", out_cov, "\n", sep = "")

# ---- Lowest coverage (weighted, applicable only) ----
lowest_cov <- coverage_tbl %>%
  filter(type == "weighted", applicable) %>%
  arrange(w_share_app) %>%
  slice_head(n = 25)

out_low <- "data/output/09_tables/lowest_coverage_weighted_applicable.csv"
readr::write_csv(lowest_cov, out_low, na = "")
cat("✔ Saved lowest-coverage (weighted, applicable only):\n  ", out_low, "\n", sep = "")

# ---- Scheme summary (weighted, applicable only) ----
scheme_summary <- coverage_tbl %>%
  filter(type == "weighted", applicable) %>%
  group_by(scheme) %>%
  summarise(
    cells = n(),
    mean_w_share = mean(w_share_app, na.rm = TRUE),
    min_w_share  = min(w_share_app,  na.rm = TRUE),
    max_w_share  = max(w_share_app,  na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(mean_w_share))

out_sum <- "data/output/09_tables/coverage_summary_weighted_by_scheme.csv"
readr::write_csv(scheme_summary, out_sum, na = "")
cat("✔ Saved scheme summary:\n  ", out_sum, "\n", sep = "")

# ---- Class-distribution tables (per scheme × type) ----
# Only possible if class_code exists for some rows; we save what exists.
dist_long <- dig_long %>% filter(!is.na(class_code))

if (nrow(dist_long) > 0) {
  dist_long %>%
    group_by(scheme, type) %>%
    group_walk(~{
      fn <- paste0("data/output/09_tables/class_distributions_", .y$scheme, "_", .y$type, ".csv")
      readr::write_csv(.x, fn, na = "")
    })
  cat("✔ Saved class-distribution tables per scheme × type in:\n  data/output/09_tables\n", sep = "")
} else {
  cat("ℹ No class-level rows found (class_code is all NA). Skipping class-distribution tables.\n")
}

# ── 9B Heatmaps ─────────────────────────────────────────────────────────────

note_text <- "Structural non-applicability set to NA (grey). Scheme-specific scaling (free scales). Viridis reversed: light=low, dark=high."

plot_heatmap <- function(df, value_col, title, out_stub) {
  # df is coverage_tbl already (scheme-level rows)
  # value_col is "w_share_app" or "share_app"
  
  p <- ggplot(df, aes(x = essround, y = fct_rev(factor(cntry)), fill = .data[[value_col]])) +
    geom_tile(color = "white", linewidth = 0.25) +
    facet_wrap(~ scheme, ncol = 3, scales = "free") +
    scale_x_continuous(breaks = sort(unique(df$essround))) +
    scale_fill_viridis_c(
      option = "viridis",
      direction = -1,      # ✅ light=low, dark=high
      na.value = "grey80",
      limits = c(0, 1),    # keep the meaning as shares; free facet scaling handles readability
      oob = scales::squish
    ) +
    labs(
      title = title,
      x = "ESS round",
      y = "Country",
      fill = value_col,
      caption = note_text   # ✅ subtitle moved to bottom note
    ) +
    theme_minimal(base_size = 12) +
    theme(
      panel.grid = element_blank(),
      strip.text = element_text(face = "bold"),
      plot.title = element_text(face = "bold"),
      plot.caption = element_text(size = 10, hjust = 0)
    )
  
  # Save PNG + PDF
  png_path <- file.path("data/output/09_figures", paste0(out_stub, ".png"))
  pdf_path <- file.path("data/output/09_figures", paste0(out_stub, ".pdf"))
  
  ggsave(png_path, p, width = 16, height = 9, dpi = 300)
  ggsave(pdf_path, p, width = 16, height = 9, device = cairo_pdf)
  
  cat("✔ Saved figure:\n  ", png_path, "\n", sep = "")
  cat("✔ Saved figure:\n  ", pdf_path, "\n", sep = "")
  
  invisible(p)
}

# Use scheme-level coverage only
cov_weighted <- coverage_tbl %>% filter(type == "weighted")
cov_unweighted <- coverage_tbl %>% filter(type == "unweighted")

plot_heatmap(
  df = cov_weighted,
  value_col = "w_share_app",
  title = "Coverage by class scheme (weighted share)",
  out_stub = "coverage_heatmap_weighted_applicable"
)

plot_heatmap(
  df = cov_unweighted,
  value_col = "share_app",
  title = "Coverage by class scheme (unweighted share)",
  out_stub = "coverage_heatmap_unweighted_applicable"
)

cat("\n── Done (Script 09). ──\n")
