# ============================================================
# 05_add_oesch.R
# Append Oesch class schema (16 / 8 / 5) using OFFICIAL Oesch scripts:
#  - Rounds 1–5: oesch_1_5.txt  (ISCO-88)
#  - Rounds 6–11: oesch_6_11.txt (ISCO-08)
# We keep the official scripts verbatim in r_scripts/oesch_source/
# and programmatically execute only the class assignment blocks.
# ============================================================

source("r_scripts/00_setup.R")

library(dplyr)

path_in  <- "data/temp/ess_4countries_r1_11_with_ordc.rds"
path_out <- "data/temp/ess_4countries_r1_11_with_ordc_oesch.rds"

src_1_5  <- "r_scripts/oesch_source/oesch_1_5.txt"
src_6_11 <- "r_scripts/oesch_source/oesch_6_11.txt"

ess <- readRDS(path_in)

# ---- helpers ------------------------------------------------
extract_lines_between <- function(lines, start_pat, end_pat) {
  s <- grep(start_pat, lines)
  e <- grep(end_pat, lines)
  if (length(s) == 0 || length(e) == 0) stop("Could not find block markers in Oesch source.")
  s <- s[1]
  e <- e[e > s][1]
  lines[(s + 1):(e - 1)]
}

keep_assignments <- function(lines, prefix = "d\\$class16_") {
  # keep only class assignment lines like: d$class16_r[...] <- ...
  lines <- trimws(lines)
  lines <- lines[grepl(paste0("^", prefix), lines)]
  # drop empty / comments
  lines[lines != "" & !grepl("^#", lines)]
}

make_selfem_mainjob <- function(d) {
  d$emplrel_r <- d$emplrel
  d$emplrel_r[is.na(d$emplrel_r)] <- 9L
  
  d$emplno_r <- d$emplno
  d$emplno_r[is.na(d$emplno_r)] <- 0L
  d$emplno_r[d$emplno_r >= 1 & d$emplno_r <= 9] <- 1L
  d$emplno_r[d$emplno_r >= 10 & d$emplno_r <= 66665] <- 2L
  
  d$selfem_mainjob <- NA_integer_
  d$selfem_mainjob[d$emplrel_r == 1 | d$emplrel_r == 9] <- 1L
  d$selfem_mainjob[d$emplrel_r == 2 & d$emplno_r == 0] <- 2L
  d$selfem_mainjob[d$emplrel_r == 3] <- 2L
  d$selfem_mainjob[d$emplrel_r == 2 & d$emplno_r == 1] <- 3L
  d$selfem_mainjob[d$emplrel_r == 2 & d$emplno_r == 2] <- 4L
  d
}

make_selfem_partner_1_5 <- function(d) {
  d$emplrel_p <- d$emprelp
  d$emplrel_p[is.na(d$emplrel_p)] <- 9L
  
  d$emplno_p <- d$emplnop
  d$emplno_p[is.na(d$emplno_p)] <- 0L
  d$emplno_p[d$emplno_p >= 1 & d$emplno_p <= 9] <- 1L
  d$emplno_p[d$emplno_p >= 10 & d$emplno_p <= 66665] <- 2L
  
  d$selfem_partner <- NA_integer_
  d$selfem_partner[d$emplrel_p == 1 | d$emplrel_p == 9] <- 1L
  d$selfem_partner[d$emplrel_p == 2 & d$emplno_p == 0] <- 2L
  d$selfem_partner[d$emplrel_p == 3] <- 2L
  d$selfem_partner[d$emplrel_p == 2 & d$emplno_p == 1] <- 3L
  d$selfem_partner[d$emplrel_p == 2 & d$emplno_p == 2] <- 4L
  d
}

make_selfem_partner_6_11 <- function(d) {
  d$selfem_partner <- NA_integer_
  d$selfem_partner[d$emprelp %in% c(1, 6, 7, 8, 9) | is.na(d$emprelp)] <- 1L
  d$selfem_partner[d$emprelp %in% c(2, 3)] <- 2L
  d
}

derive_class8_class5 <- function(d) {
  d$class8 <- NA_integer_
  d$class8[d$class16 <= 2] <- 1L
  d$class8[d$class16 %in% c(3,4)] <- 2L
  d$class8[d$class16 %in% c(5,6)] <- 3L
  d$class8[d$class16 %in% c(7,8)] <- 4L
  d$class8[d$class16 %in% c(9,10)] <- 5L
  d$class8[d$class16 %in% c(11,12)] <- 6L
  d$class8[d$class16 %in% c(13,14)] <- 7L
  d$class8[d$class16 %in% c(15,16)] <- 8L
  
  d$class5 <- NA_integer_
  d$class5[d$class16 <= 2 | d$class16 %in% c(5,9,13)] <- 1L
  d$class5[d$class16 %in% c(6,10,14)] <- 2L
  d$class5[d$class16 %in% c(3,4)] <- 3L
  d$class5[d$class16 %in% c(7,11,15)] <- 4L
  d$class5[d$class16 %in% c(8,12,16)] <- 5L
  d
}

eval_assignments <- function(d, assignment_lines) {
  # Evaluate lines like: d$class16_r[...] <- 2
  # in an environment where `d` exists and is modified.
  env <- list2env(list(d = d), parent = baseenv())
  for (ln in assignment_lines) {
    eval(parse(text = ln), envir = env)
  }
  env$d
}

# ============================================================
# Rounds 1–5 (ISCO-88) using oesch_1_5.txt
# ============================================================
d1 <- ess |> filter(essround <= 5)

if (nrow(d1) > 0) {
  stopifnot(all(c("iscoco","emplrel","emplno","iscocop","emprelp","emplnop") %in% names(d1)))
  
  lines_1_5 <- readLines(src_1_5, warn = FALSE)
  
  # respondent
  d1$isco_mainjob <- d1$iscoco
  d1$isco_mainjob[is.na(d1$isco_mainjob)] <- -9L
  d1 <- make_selfem_mainjob(d1)
  d1$class16_r <- -9L
  
  # Extract respondent block lines for class16_r
  block_r <- extract_lines_between(
    lines_1_5,
    start_pat = "Create Oesch class schema for respondents",
    end_pat   = "Respondent's Oesch class position - 8 classes"
  )
  asg_r <- keep_assignments(block_r, prefix = "d\\$class16_r")
  d1 <- eval_assignments(d1, asg_r)
  d1$class16_r[d1$class16_r == -9] <- NA_integer_
  
  # partner
  d1$isco_partner <- d1$iscocop
  d1$isco_partner[is.na(d1$isco_partner)] <- -9L
  d1 <- make_selfem_partner_1_5(d1)
  d1$class16_p <- -9L
  
  block_p <- extract_lines_between(
    lines_1_5,
    start_pat = "Create Oesch class schema for partners",
    end_pat   = "Partner's Oesch class position - 8 classes"
  )
  asg_p <- keep_assignments(block_p, prefix = "d\\$class16_p")
  d1 <- eval_assignments(d1, asg_p)
  d1$class16_p[d1$class16_p == -9] <- NA_integer_
}

# ============================================================
# Rounds 6–11 (ISCO-08) using oesch_6_11.txt  (FULL)
# ============================================================
d2 <- ess |> filter(essround >= 6)

if (nrow(d2) > 0) {
  stopifnot(all(c("isco08","emplrel","emplno","isco08p","emprelp") %in% names(d2)))
  
  lines_6_11 <- readLines(src_6_11, warn = FALSE)
  
  # respondent
  d2$isco_mainjob <- d2$isco08
  d2$isco_mainjob[is.na(d2$isco_mainjob)] <- -9L
  d2 <- make_selfem_mainjob(d2)
  d2$class16_r <- -9L
  
  block_r <- extract_lines_between(
    lines_6_11,
    start_pat = "Create Oesch class schema for respondents",
    end_pat   = "Respondent's Oesch class position - 8 classes"
  )
  asg_r <- keep_assignments(block_r, prefix = "d\\$class16_r")
  d2 <- eval_assignments(d2, asg_r)
  d2$class16_r[d2$class16_r == -9] <- NA_integer_
  
  # partner
  d2$isco_partner <- d2$isco08p
  d2$isco_partner[is.na(d2$isco_partner)] <- -9L
  d2 <- make_selfem_partner_6_11(d2)
  d2$class16_p <- -9L
  
  block_p <- extract_lines_between(
    lines_6_11,
    start_pat = "Create Oesch class schema for partners",
    end_pat   = "Partner's Oesch class position - 8 classes"
  )
  asg_p <- keep_assignments(block_p, prefix = "d\\$class16_p")
  d2 <- eval_assignments(d2, asg_p)
  d2$class16_p[d2$class16_p == -9] <- NA_integer_
}

# ============================================================
# Merge, final class, derive 8/5, save
# ============================================================
out <- bind_rows(d1, d2)

# Final rule from official scripts (respondent first, else partner) :contentReference[oaicite:4]{index=4}
out$class16 <- ifelse(!is.na(out$class16_r), out$class16_r, out$class16_p)
out <- derive_class8_class5(out)

saveRDS(out, path_out)

message("=== Oesch appended (FULL, 1–11) ===")
message("Rows: ", nrow(out))
message("Non-missing class16: ", sum(!is.na(out$class16)))
message("Saved: ", path_out)
