# Test trajectory computation + HCPC for Portugal political space
library(tidyverse)
library(FactoMineR)

df <- readRDS("data/master/ess_final.rds")

active_vars <- c("freehms_r", "gincdif_r", "imbgeco_3cat",
                  "imueclt_3cat", "imwbcnt_3cat")
oesch8_labels <- c("1" = "Self-emp prof", "2" = "Small business",
  "3" = "Tech (semi-)prof", "4" = "Production", "5" = "Managers",
  "6" = "Clerks", "7" = "Socio-cult prof", "8" = "Service workers")

cc <- "PT"
cd <- df %>%
  filter(cntry == cc) %>%
  filter(if_all(all_of(active_vars), ~ !is.na(.)))

mca_data <- cd %>%
  mutate(across(all_of(active_vars), factor),
         essround = factor(essround))

sup_cols <- c("essround")
mca_input <- mca_data %>% select(all_of(active_vars), all_of(sup_cols))

cat("Running MCA...\n")
res <- MCA(mca_input,
           quali.sup = which(names(mca_input) %in% sup_cols),
           ncp = 5, graph = FALSE)

# Test trajectory computation
ind_coord <- as.data.frame(res$ind$coord[, 1:2])
names(ind_coord) <- c("Dim1", "Dim2")
ind_coord$oesch8 <- factor(cd$oesch8, levels = 1:8, labels = oesch8_labels)
ind_coord$essround <- cd$essround

traj <- ind_coord %>%
  filter(!is.na(oesch8)) %>%
  group_by(oesch8, essround) %>%
  summarise(Dim1 = mean(Dim1), Dim2 = mean(Dim2), n = n(), .groups = "drop") %>%
  filter(n >= 30)

cat("\n=== Trajectory barycentres (first 20 rows) ===\n")
print(as.data.frame(head(traj, 20)))
cat("\nTotal class x round cells:", nrow(traj), "\n")

# Test HCPC
cat("\nRunning HCPC...\n")
hcpc_res <- HCPC(res, nb.clust = -1, consol = TRUE, graph = FALSE)
cat("Optimal K:", length(unique(hcpc_res$data.clust$clust)), "\n")
cat("Cluster sizes:\n")
print(table(hcpc_res$data.clust$clust))

cat("\nDone.\n")
