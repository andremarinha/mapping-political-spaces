# ============================================================
# 04_add_digclass_schemes.R
# Append DIGCLASS-based class schemes (scheme-safe, ESS-consistent)
#
# Outputs (added columns):
#   - spines: isco88_spine, isco88_source, isco88com_spine
#   - context: self_employed, is_supervisor, n_employees + imputation flags
#   - schemes: ordc_dig + ordc_label, egp_dig, egp_mp_dig,
#              oesch16_dig, oesch8_dig, oesch5_dig,
#              microclass_dig, msec_dig, wright_dig
#   - classifiable flags per spine
# Diagnostics saved as: attr(d, "digclass_diagnostics")
# ============================================================

source("r_scripts/00_setup.R")

# ---- Packages ----------------------------------------------
required_pkgs <- c("dplyr", "DIGCLASS", "labelled")
missing <- required_pkgs[
  !vapply(required_pkgs, requireNamespace, quietly = TRUE, FUN.VALUE = logical(1))
]
if (length(missing) > 0) stop("Missing packages: ", paste(missing, collapse = ", "), call. = FALSE)

library(dplyr)
library(DIGCLASS)
library(labelled)

# ---- Paths -------------------------------------------------
path_in  <- "data/temp/ess_4countries_r1_11_stage_occ.rds"
path_out <- "data/temp/ess_4countries_r1_11_with_digclass.rds"

if (!file.exists(path_in)) {
  stop("Input not found: ", path_in, "\nRun 03_occupation_staging.R first.", call. = FALSE)
}

d <- readRDS(path_in)

# ---- Preconditions -----------------------------------------
must_have <- c("cntry", "essround", "isco_scheme", "occ_isco88", "occ_isco08")
miss <- setdiff(must_have, names(d))
if (length(miss) > 0) stop("Missing staged variables: ", paste(miss, collapse = ", "), call. = FALSE)

# ============================================================
# Helpers: ESS special missings -> NA (robust)
# ============================================================
ess_to_na_char <- function(x) {
  x <- labelled::to_character(x)
  x <- trimws(x)
  x[x %in% c(
    "", "0",
    "7","8","9",
    "77","88","99",
    "777","888","999",
    "6666","7777","8888","9999",
    "66666","77777","88888","99999",
    "-1","-2","-3","-4","-5","-7","-8","-9"
  )] <- NA_character_
  x
}
ess_to_na_num <- function(x) suppressWarnings(as.numeric(ess_to_na_char(x)))

# ============================================================
# 1) Context vars (DIGCLASS conventions) + flags
# ============================================================
emplrel_clean <- ess_to_na_num(d$emplrel)
jbspv_clean   <- ess_to_na_num(d$jbspv)
emplno_clean  <- ess_to_na_num(d$emplno)

d <- d |>
  mutate(
    # ESS emplrel: 1=employee, 2=self-employed, 3=family business
    self_employed = case_when(
      emplrel_clean %in% c(2, 3) ~ 1,
      emplrel_clean == 1         ~ 0,
      TRUE                       ~ 0
    ),
    # ESS jbspv: 1=yes, 2=no
    is_supervisor = case_when(
      jbspv_clean == 1 ~ 1,
      jbspv_clean == 2 ~ 0,
      TRUE             ~ 0
    ),
    # DIGCLASS wants 0 instead of NA for emplno
    n_employees = if_else(is.na(emplno_clean), 0, emplno_clean),
    
    ctx_selfemp_imputed    = is.na(emplrel_clean),
    ctx_supervisor_imputed = is.na(jbspv_clean),
    ctx_emplno_imputed     = is.na(emplno_clean),
    ctx_any_imputed        = ctx_selfemp_imputed | ctx_supervisor_imputed | ctx_emplno_imputed
  )

# ============================================================
# 2) Repair occupation codes ONLY within scheme
# ============================================================
d <- d |>
  mutate(
    occ_isco88_rep = if_else(
      isco_scheme == "ISCO88",
      DIGCLASS::repair_isco(ess_to_na_char(occ_isco88), digits = 4),
      NA_character_
    ),
    occ_isco08_rep = if_else(
      isco_scheme == "ISCO08",
      DIGCLASS::repair_isco(ess_to_na_char(occ_isco08), digits = 4),
      NA_character_
    )
  )

# ============================================================
# 3) Spines (your exact logic)
# ============================================================
# Note: DIGCLASS may emit messages/warnings for a small set of codes due to
# internal table coverage; we audit EGP coverage explicitly later.
d <- d |>
  mutate(
    isco88_spine = case_when(
      isco_scheme == "ISCO88" ~ occ_isco88_rep,
      isco_scheme == "ISCO08" ~ suppressWarnings(DIGCLASS::isco08_to_isco88(occ_isco08_rep)),
      TRUE ~ NA_character_
    ),
    isco88_source = case_when(
      isco_scheme == "ISCO88" ~ "native_isco88",
      isco_scheme == "ISCO08" ~ "xwalk_08_to_88",
      TRUE ~ NA_character_
    ),
    # ISCO88COM is 4-digit in DIGCLASS; do NOT truncate
    isco88com_spine = if_else(
      !is.na(isco88_spine),
      suppressWarnings(DIGCLASS::isco88_to_isco88com(isco88_spine)),
      NA_character_
    ),
    classifiable_isco88    = !is.na(isco88_spine),
    classifiable_isco08    = !is.na(occ_isco08_rep),
    classifiable_isco88com = !is.na(isco88com_spine)
  )

# ============================================================
# 4) DIGCLASS schemes
# ============================================================

# ORDC (codes as character)
d$ordc_dig <- DIGCLASS::isco88_to_ordc(d$isco88_spine)

# EGP (11 classes)
d$egp_dig <- DIGCLASS::isco88_to_egp(
  d$isco88_spine,
  self_employed = d$self_employed,
  n_employees   = d$n_employees,
  n_classes     = 11
)

# EGP-MP
d$egp_mp_dig <- DIGCLASS::isco88_to_egp_mp(
  d$isco88_spine,
  is_supervisor = d$is_supervisor,
  self_employed = d$self_employed,
  n_employees   = d$n_employees
)

# Oesch (16 / 8 / 5)  ✅
d$oesch16_dig <- DIGCLASS::isco88_to_oesch(
  d$isco88_spine,
  self_employed = d$self_employed,
  n_employees   = d$n_employees,
  n_classes     = 16
)
d$oesch8_dig <- DIGCLASS::isco88_to_oesch(
  d$isco88_spine,
  self_employed = d$self_employed,
  n_employees   = d$n_employees,
  n_classes     = 8
)
d$oesch5_dig <- DIGCLASS::isco88_to_oesch(
  d$isco88_spine,
  self_employed = d$self_employed,
  n_employees   = d$n_employees,
  n_classes     = 5
)

# Microclass (native ISCO08 only)
d$microclass_dig <- DIGCLASS::isco08_to_microclass(d$occ_isco08_rep)

# MSEC + Wright (need ISCO88COM spine)
d$msec_dig <- DIGCLASS::isco88com_to_msec(
  d$isco88com_spine,
  is_supervisor = d$is_supervisor,
  self_employed = d$self_employed,
  n_employees   = d$n_employees
)

d$wright_dig <- DIGCLASS::isco88com_to_wright(
  d$isco88com_spine,
  is_supervisor = d$is_supervisor,
  self_employed = d$self_employed,
  n_employees   = d$n_employees,
  type = "simple"
)

# Honest missingness: if no ISCO88COM, no MSEC/Wright
d <- d |>
  mutate(
    msec_dig   = if_else(is.na(isco88com_spine), NA_character_, msec_dig),
    wright_dig = if_else(is.na(isco88com_spine), NA_character_, wright_dig)
  )

# ============================================================
# 5) ORDC labels (ordered factor)
# ============================================================

ordc_levels <- as.character(1:13)
ordc_labels <- c(
  "1: Cultural upper class",
  "2: Balanced upper class",
  "3: Economic upper class",
  "4: Cultural upper middle class",
  "5: Balanced upper middle class",
  "6: Economic upper middle class",
  "7: Cultural lower middle class",
  "8: Balanced lower middle class",
  "9: Economic lower middle class",
  "10: Skilled working class",
  "11: Unskilled working class",
  "12: Primary-sector employees",
  "13: Welfare dependents"
)

ordc_map <- setNames(ordc_labels, ordc_levels)

d <- d |>
  mutate(
    ordc_label = dplyr::if_else(
      !is.na(ordc_dig) & ordc_dig %in% ordc_levels,
      unname(ordc_map[ordc_dig]),
      NA_character_
    ),
    ordc_factor = factor(ordc_dig, levels = ordc_levels, labels = ordc_labels, ordered = TRUE)
  )

# ============================================================
# 6) Audits + diagnostics (appendix-friendly)
# ============================================================

# EGP audit: codes with valid ISCO88 spine but NA EGP
egp_unmapped <- d |>
  filter(!is.na(isco88_spine) & is.na(egp_dig)) |>
  count(isco88_spine, name = "n") |>
  arrange(desc(n))

# “EGP covered” flag
d <- d |>
  mutate(egp_covered = !is.na(isco88_spine) & !is.na(egp_dig))

# Store diagnostics attribute
diag <- list(
  n_rows = nrow(d),
  isco_scheme_counts = table(d$isco_scheme, useNA = "ifany"),
  spines_nonmissing = c(
    isco88_spine = sum(!is.na(d$isco88_spine)),
    isco88com_spine = sum(!is.na(d$isco88com_spine)),
    isco08_rep = sum(!is.na(d$occ_isco08_rep))
  ),
  context_imputation_share = c(
    any = mean(d$ctx_any_imputed),
    emplrel = mean(d$ctx_selfemp_imputed),
    jbspv = mean(d$ctx_supervisor_imputed),
    emplno = mean(d$ctx_emplno_imputed)
  ),
  coverage = c(
    ordc = sum(!is.na(d$ordc_dig)),
    egp = sum(!is.na(d$egp_dig)),
    egp_mp = sum(!is.na(d$egp_mp_dig)),
    oesch16 = sum(!is.na(d$oesch16_dig)),
    oesch8 = sum(!is.na(d$oesch8_dig)),
    oesch5 = sum(!is.na(d$oesch5_dig)),
    microclass = sum(!is.na(d$microclass_dig)),
    msec = sum(!is.na(d$msec_dig)),
    wright = sum(!is.na(d$wright_dig))
  ),
  egp_unmapped_codes = egp_unmapped
)
attr(d, "digclass_diagnostics") <- diag

# Console summary (compact)
message("=== DIGCLASS appended (with ORDC labels) ===")
message("Rows: ", nrow(d))
message("ISCO scheme counts:"); print(table(d$isco_scheme, useNA = "ifany"))
message("\nSpines non-missing:")
message("  ISCO88 spine:    ", diag$spines_nonmissing["isco88_spine"])
message("  ISCO88COM spine: ", diag$spines_nonmissing["isco88com_spine"])
message("  ISCO08 repaired: ", diag$spines_nonmissing["isco08_rep"])
message("\nContext imputation share (any): ", round(diag$context_imputation_share["any"], 4))
message("\nScheme coverage (non-missing):")
print(diag$coverage)

if (nrow(egp_unmapped) > 0) {
  message("\nEGP unmapped codes (top 20):")
  print(head(egp_unmapped, 20), n = 20)
}

# ============================================================
# 7) Save
# ============================================================
saveRDS(d, path_out)
message("\n✔ Saved dataset with DIGCLASS schemes: ", path_out)
