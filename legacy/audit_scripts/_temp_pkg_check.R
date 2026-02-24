pkgs <- c("FactoMineR", "factoextra", "poLCA", "patchwork",
          "knitr", "kableExtra", "tidyverse", "scales", "ggrepel")
for (p in pkgs) {
  installed <- requireNamespace(p, quietly = TRUE)
  cat(sprintf("%-15s: %s\n", p, ifelse(installed, "OK", "MISSING")))
}
