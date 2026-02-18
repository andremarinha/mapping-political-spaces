# ==============================================================================
# Script: 05_descriptives.R
# Path:   scripts/05_descriptives.R
# Purpose: Generate Coverage Statistics and Class Distributions (Tables & Plots)
# Input:   data/master/ess_final.rds
# Output:  tables/class_coverage.csv, tables/class_distributions.csv
#          figures/coverage_heatmap.png/pdf, figures/*_distribution.png/pdf
# ==============================================================================

library(tidyverse)
library(labelled)
library(scales)

# Paths
input_path  <- "data/master/ess_final.rds"
dir.create("tables", showWarnings = FALSE)
dir.create("figures", showWarnings = FALSE)

# 1. Load Data
df <- readRDS(input_path)

# Define schemes to analyze
schemes <- c("oesch8", "oesch5", "ordc", "egp11", "microclass")

# ==============================================================================
# PART A: COVERAGE ANALYSIS (The "Audit")
# ==============================================================================
message(">> Calculating Coverage...")

calc_coverage <- function(data, scheme_name) {
  data %>%
    group_by(cntry, essround) %>%
    summarise(
      n_total = n(),
      n_covered = sum(!is.na(.data[[scheme_name]])),
      pct_covered = n_covered / n_total,
      
      # Weighted Coverage
      w_total = sum(analysis_weight, na.rm = TRUE),
      w_covered = sum(analysis_weight[!is.na(.data[[scheme_name]])], na.rm = TRUE),
      w_pct_covered = w_covered / w_total,
      .groups = "drop"
    ) %>%
    mutate(scheme = scheme_name)
}

# Loop through schemes and bind rows
coverage_list <- list()
for(s in schemes) {
  if(s %in% names(df)) {
    coverage_list[[s]] <- calc_coverage(df, s)
  } else {
    warning(paste("Variable", s, "not found in dataset. Skipping."))
  }
}
df_coverage <- bind_rows(coverage_list)

# FIX APPLICABILITY: Microclass is NA for Rounds 1-5
df_coverage <- df_coverage %>%
  mutate(
    is_applicable = case_when(
      scheme == "microclass" & essround <= 5 ~ FALSE,
      TRUE ~ TRUE
    ),
    w_pct_covered = if_else(is_applicable, w_pct_covered, NA_real_)
  )

# Save Table
write_csv(df_coverage, "tables/class_coverage.csv")

# PLOT: Coverage Heatmap (Final Polish - 2x2 Grid + Plasma Palette)
df_plot <- df_coverage %>%
  filter(scheme != "oesch5") %>%
  mutate(scheme = factor(scheme, levels = c("oesch8", "ordc", "egp11", "microclass")))

p_cov <- ggplot(df_plot, aes(x = factor(essround), y = cntry, fill = w_pct_covered)) +
  geom_tile(color = "white", linewidth = 0.2) + 
  facet_wrap(~scheme, ncol = 2) +
  
  # Updated to Plasma Palette (matches bar charts)
  scale_fill_viridis_c(
    option = "plasma", 
    direction = -1, 
    na.value = "grey95", 
    labels = percent
  ) +
  
  labs(
    title = "Class Scheme Coverage by Country and Round",
    x = "ESS Round", y = NULL, fill = "Coverage (%)",
    caption = "Note: Grey = Not Applicable (e.g. Microclass R1-5). Lighter Yellow = Lower Coverage, Darker Purple = Higher Coverage."
  ) +
  theme_minimal() +
  theme(
    panel.grid = element_blank(),
    strip.text = element_text(face = "bold", size = 11),
    axis.text.x = element_text(size = 8),
    plot.title = element_text(face = "bold", size = 14),
    plot.caption = element_text(hjust = 0, color = "grey40", margin = margin(t = 10))
  )

ggsave("figures/coverage_heatmap.png", p_cov, width = 10, height = 10, bg = "white", dpi = 300)
ggsave("figures/coverage_heatmap.pdf", p_cov, width = 10, height = 10, device = cairo_pdf)

# ==============================================================================
# PART B: CLASS DISTRIBUTIONS (The "Result")
# ==============================================================================
message(">> Calculating Distributions...")

calc_dist <- function(data, scheme_col, label_col) {
  if(!all(c(scheme_col, label_col) %in% names(data))) return(NULL)
  
  data %>%
    filter(!is.na(.data[[label_col]])) %>% # Use labels (inc. Unclassifiable)
    group_by(cntry, class_label = .data[[label_col]]) %>%
    summarise(
      n = n(),
      w_n = sum(analysis_weight, na.rm = TRUE),
      .groups = "drop_last"
    ) %>%
    mutate(share = w_n / sum(w_n)) %>%
    ungroup() %>%
    mutate(scheme = scheme_col)
}

df_dist_oesch8 <- calc_dist(df, "oesch8", "oesch8_label")
df_dist_ordc   <- calc_dist(df, "ordc",   "ordc_label")
df_dist_egp    <- calc_dist(df, "egp11",  "egp11_label")

df_distributions <- bind_rows(
  if(!is.null(df_dist_oesch8)) df_dist_oesch8 %>% mutate(class_label = as.character(class_label)) else NULL,
  if(!is.null(df_dist_ordc))   df_dist_ordc   %>% mutate(class_label = as.character(class_label)) else NULL,
  if(!is.null(df_dist_egp))    df_dist_egp    %>% mutate(class_label = as.character(class_label)) else NULL
)

write_csv(df_distributions, "tables/class_distributions.csv")

# PLOT: Stacked Bars for Oesch 8 (Robust Color Mapping)
if(!is.null(df_dist_oesch8)) {
  # Create Explicit Color Mapping for 1..8
  oesch_levels <- levels(df_dist_oesch8$class_label)
  oesch_colors <- setNames(viridis::plasma(8, direction = 1), oesch_levels)
  
  p_dist_oesch <- ggplot(df_dist_oesch8, aes(x = cntry, y = share, fill = class_label)) +
    geom_bar(stat = "identity", position = "fill") +
    scale_y_continuous(labels = percent) +
    
    # Use Explicit Colors
    scale_fill_manual(values = oesch_colors) +
    
    labs(
      title = "Oesch 8-Class Distribution in Southern Europe",
      x = NULL, y = "Weighted Share", fill = "Class",
      caption = "Note: Pooled data from the European Social Survey (Rounds 1 to 11)"
    ) +
    coord_flip() +
    theme_minimal() +
    theme(
      legend.position = "bottom", 
      legend.direction = "horizontal",
      legend.text = element_text(size = 8),
      legend.key.size = unit(0.4, "cm"),
      legend.title = element_text(face = "bold"),
      plot.title = element_text(face = "bold", size = 14),
      plot.caption = element_text(hjust = 0, color = "grey40", margin = margin(t = 10))
    ) +
    guides(fill = guide_legend(ncol = 2, byrow = TRUE)) 
  
  ggsave("figures/oesch8_distribution.png", p_dist_oesch, width = 10, height = 9, bg = "white", dpi = 300)
  ggsave("figures/oesch8_distribution.pdf", p_dist_oesch, width = 10, height = 9, device = cairo_pdf)
}

# PLOT: Stacked Bars for ORDC (Robust Color Mapping)
if(!is.null(df_dist_ordc)) {
  ordc_levels <- levels(df_dist_ordc$class_label)
  # Map 1-13 to Plasma, 14 to Grey
  valid_colors <- viridis::plasma(13, direction = 1) 
  ordc_colors <- setNames(c(valid_colors, "grey80"), ordc_levels)
  
  p_dist_ordc <- ggplot(df_dist_ordc, aes(x = cntry, y = share, fill = class_label)) +
    geom_bar(stat = "identity", position = "fill") +
    scale_y_continuous(labels = percent) +
    
    scale_fill_manual(values = ordc_colors) + 
    
    labs(
      title = "ORDC Class Distribution in Southern Europe",
      x = NULL, y = "Weighted Share", fill = "Class",
      caption = "Note: Pooled data from the European Social Survey (Rounds 1 to 11)"
    ) +
    coord_flip() +
    theme_minimal() +
    theme(
      legend.position = "bottom", 
      legend.direction = "horizontal",
      legend.text = element_text(size = 7), 
      legend.key.size = unit(0.4, "cm"),
      legend.title = element_text(face = "bold"),
      plot.title = element_text(face = "bold", size = 14),
      plot.caption = element_text(hjust = 0, color = "grey40", margin = margin(t = 10))
    ) +
    guides(fill = guide_legend(ncol = 3, byrow = TRUE))
  
  ggsave("figures/ordc_distribution.png", p_dist_ordc, width = 10, height = 9, bg = "white", dpi = 300)
  ggsave("figures/ordc_distribution.pdf", p_dist_ordc, width = 10, height = 9, device = cairo_pdf)
}

message("Script 05 complete! All figures saved as PNG and PDF.")