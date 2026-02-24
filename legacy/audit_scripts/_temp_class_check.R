# Check: do ORDC and EGP variables exist in master?
library(tidyverse)
select <- dplyr::select
df <- readRDS("data/master/ess_final.rds")

# Search for class-related columns
class_cols <- names(df)[grepl("ordc|egp|oesch|class|digclass", names(df), ignore.case = TRUE)]
cat("Class-related columns:", paste(class_cols, collapse = ", "), "\n\n")

for (v in class_cols) {
  cat("---", v, "---\n")
  cat("  Type:", class(df[[v]]), "\n")
  n_valid <- sum(!is.na(df[[v]]))
  cat("  Valid:", n_valid, "/", nrow(df), "(", round(100*n_valid/nrow(df),1), "%)\n")
  if (is.numeric(df[[v]])) {
    cat("  Unique values:", length(unique(na.omit(df[[v]]))), "\n")
    cat("  Range:", range(na.omit(df[[v]])), "\n")
  } else {
    cat("  Levels:", length(unique(na.omit(df[[v]]))), "\n")
  }
  cat("\n")
}
