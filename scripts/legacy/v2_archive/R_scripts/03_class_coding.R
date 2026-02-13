# ==============================================================================
# Script: 03_class_coding.R
# Path:   scripts/R_scripts/03_class_coding.R
# Purpose: Generate Class Schemes (Oesch with Partner Logic + DIGCLASS)
# Logic:   
#   1. Clean Data: Handle Respondent AND Partner variables.
#   2. Oesch 16: Calculate for Respondent, then Partner.
#   3. Substitution: If Respondent is missing, use Partner.
#   4. ORDC/EGP/Micro: DIGCLASS implementation (Respondent only).
# ==============================================================================

library(tidyverse)
library(DIGCLASS)
library(labelled)

input_path  <- "data/temp/02_weighted_data.rds"
output_path <- "data/temp/03_classed_data.rds"
log_path    <- "log/03_class_coding_log.txt"

sink(log_path)
cat("LOG START: 03_class_coding.R [Full Oesch Logic]\n")
cat("Time:", as.character(Sys.time()), "\n\n")

# 1. Load Data
df <- readRDS(input_path)
cat("Loaded N:", nrow(df), "\n\n")

# --- PART 1: ROBUST CLEANING (Respondent & Partner) ---
cat(">> Action: cleaning variables (Respondent + Partner)...\n")

clean_ess_numeric <- function(x) {
  val <- suppressWarnings(as.numeric(as.character(x)))
  val[val > 9999 & val < 100000] <- NA  # Catches 66666-99999
  val[val < 0] <- NA                    # Catches -1, -2
  return(val)
}

df_prep <- df %>%
  mutate(
    # --- RESPONDENT VARIABLES ---
    isco88_num = clean_ess_numeric(if("iscoco" %in% names(.)) iscoco else NA),
    isco08_num = clean_ess_numeric(if("isco08" %in% names(.)) isco08 else NA),
    emplrel_r  = clean_ess_numeric(emplrel),
    emplno_r   = clean_ess_numeric(emplno),
    
    # --- PARTNER VARIABLES ---
    # (Checking if they exist to prevent crashes if removed in Script 01)
    isco88_p_num = clean_ess_numeric(if("iscocop" %in% names(.)) iscocop else NA),
    isco08_p_num = clean_ess_numeric(if("isco08p" %in% names(.)) isco08p else NA),
    emplrel_p    = clean_ess_numeric(if("emprelp" %in% names(.)) emprelp else NA),
    emplno_p     = clean_ess_numeric(if("emplnop" %in% names(.)) emplnop else NA)
  ) %>%
  mutate(
    # Respondent Self-Employed Logic
    emplno_cat = case_when(
      is.na(emplno_r) | emplno_r == 0 ~ 0,
      emplno_r >= 1 & emplno_r <= 9   ~ 1,
      emplno_r >= 10                  ~ 2,
      TRUE                            ~ 0
    ),
    selfem_mainjob = case_when(
      emplrel_r %in% c(1, 9, NA) ~ 1,           
      (emplrel_r == 2 & emplno_cat == 0) ~ 2,   
      (emplrel_r == 3) ~ 2,                     
      (emplrel_r == 2 & emplno_cat == 1) ~ 3,   
      (emplrel_r == 2 & emplno_cat == 2) ~ 4,   
      TRUE ~ 1
    ),
    
    # Partner Self-Employed Logic
    emplno_p_cat = case_when(
      is.na(emplno_p) | emplno_p == 0 ~ 0,
      emplno_p >= 1 & emplno_p <= 9   ~ 1,
      emplno_p >= 10                  ~ 2,
      TRUE                            ~ 0
    ),
    selfem_partner = case_when(
      emplrel_p %in% c(1, 9, NA) ~ 1,           
      (emplrel_p == 2 & emplno_p_cat == 0) ~ 2,   
      (emplrel_p == 3) ~ 2,                     
      (emplrel_p == 2 & emplno_p_cat == 1) ~ 3,   
      (emplrel_p == 2 & emplno_p_cat == 2) ~ 4,   
      TRUE ~ 1
    )
  )

# --- PART 2: OESCH FUNCTIONS ---
# (Standard Logic - Abbreviated for readability, assume full function body here)
# ... [Keeping the exact same functions you had before] ...
get_oesch_isco88 <- function(isco, selfem) {
  if (is.na(isco) | is.na(selfem)) return(NA_real_)
  if (selfem == 4) return(1)
  if ((selfem == 2 | selfem == 3) && ((isco >= 2000 & isco <= 2229) | (isco >= 2300 & isco <= 2470))) return(2)
  if (selfem == 3 && ((isco >= 1000 & isco <= 1999) | (isco >= 3000 & isco <= 9333) | (isco == 2230))) return(3)
  if (selfem == 2 && ((isco >= 1000 & isco <= 1999) | (isco >= 3000 & isco <= 9333) | (isco == 2230))) return(4)
  if (selfem == 1) {
    if (isco >= 2100 & isco <= 2213) return(5)
    if ((isco >= 3100 & isco <= 3152) | (isco >= 3210 & isco <= 3213) | isco == 3434) return(6)
    if ((isco >= 6000 & isco <= 7442) | (isco >= 8310 & isco <= 8312) | (isco >= 8324 & isco <= 8330) | (isco >= 8332 & isco <= 8340)) return(7)
    if ((isco >= 8000 & isco <= 8300) | (isco >= 8320 & isco <= 8321) | isco == 8331 | (isco >= 9153 & isco <= 9333)) return(8)
    if ((isco >= 1000 & isco <= 1239) | (isco >= 2400 & isco <= 2429) | isco == 2441 | isco == 2470) return(9)
    if ((isco >= 1300 & isco <= 1319) | (isco >= 3400 & isco <= 3433) | (isco >= 3440 & isco <= 3450)) return(10)
    if ((isco >= 4000 & isco <= 4112) | (isco >= 4114 & isco <= 4210) | (isco >= 4212 & isco <= 4222)) return(11)
    if (isco %in% c(4113, 4211, 4223)) return(12)
    if ((isco >= 2220 & isco <= 2229) | (isco >= 2300 & isco <= 2320) | (isco >= 2340 & isco <= 2359) | (isco >= 2430 & isco <= 2440) | (isco >= 2442 & isco <= 2443) | isco %in% c(2445, 2451, 2460)) return(13)
    if (isco == 2230 | (isco >= 2330 & isco <= 2332) | isco == 2444 | (isco >= 2446 & isco <= 2450) | (isco >= 2452 & isco <= 2455) | isco == 3200 | (isco >= 3220 & isco <= 3224) | isco == 3226 | (isco >= 3229 & isco <= 3340) | (isco >= 3460 & isco <= 3472) | isco == 3480) return(14)
    if (isco == 3225 | (isco >= 3227 & isco <= 3228) | (isco >= 3473 & isco <= 3475) | (isco >= 5000 & isco <= 5113) | isco == 5122 | (isco >= 5131 & isco <= 5132) | (isco >= 5140 & isco <= 5141) | isco == 5143 | (isco >= 5160 & isco <= 5220) | isco == 8323) return(15)
    if ((isco >= 5120 & isco <= 5121) | (isco >= 5123 & isco <= 5130) | (isco >= 5133 & isco <= 5139) | isco == 5142 | isco == 5149 | isco == 5230 | isco == 8322 | (isco >= 9100 & isco <= 9152)) return(16)
  }
  return(NA_real_)
}

get_oesch_isco08 <- function(isco, selfem) {
  if (is.na(isco) | is.na(selfem)) return(NA_real_)
  if (selfem == 4) return(1)
  if ((selfem == 2 | selfem == 3) && ((isco >= 2000 & isco <= 2162) | (isco >= 2164 & isco <= 2165) | (isco >= 2200 & isco <= 2212) | isco == 2250 | (isco >= 2261 & isco <= 2262) | (isco >= 2300 & isco <= 2330) | (isco >= 2350 & isco <= 2352) | (isco >= 2359 & isco <= 2432) | (isco >= 2500 & isco <= 2619) | isco == 2621 | (isco >= 2630 & isco <= 2634) | (isco >= 2636 & isco <= 2640) | (isco >= 2642 & isco <= 2643))) return(2)
  if (selfem == 3 && ((isco >= 1000 & isco <= 1439) | isco %in% c(2163, 2166) | (isco >= 2220 & isco <= 2240) | isco == 2260 | (isco >= 2263 & isco <= 2269) | (isco >= 2340 & isco <= 2342) | (isco >= 2353 & isco <= 2356) | (isco >= 2433 & isco <= 2434) | isco %in% c(2620, 2622, 2635, 2641) | (isco >= 2650 & isco <= 2659) | (isco >= 3000 & isco <= 9629))) return(3)
  if (selfem == 2 && ((isco >= 1000 & isco <= 1439) | isco %in% c(2163, 2166) | (isco >= 2220 & isco <= 2240) | isco == 2260 | (isco >= 2263 & isco <= 2269) | (isco >= 2340 & isco <= 2342) | (isco >= 2353 & isco <= 2356) | (isco >= 2433 & isco <= 2434) | isco %in% c(2620, 2622, 2635, 2641) | (isco >= 2650 & isco <= 2659) | (isco >= 3000 & isco <= 9629))) return(4)
  if (selfem == 1) {
    if ((isco >= 2100 & isco <= 2162) | (isco >= 2164 & isco <= 2165) | (isco >= 2500 & isco <= 2529)) return(5)
    if ((isco >= 3100 & isco <= 3155) | (isco >= 3210 & isco <= 3214) | isco == 3252 | (isco >= 3500 & isco <= 3522)) return(6)
    if ((isco >= 6000 & isco <= 7549) | (isco >= 8310 & isco <= 8312) | isco == 8330 | (isco >= 8332 & isco <= 8340) | (isco >= 8342 & isco <= 8344)) return(7)
    if ((isco >= 8000 & isco <= 8300) | (isco >= 8320 & isco <= 8321) | isco == 8341 | isco == 8350 | (isco >= 9200 & isco <= 9334) | (isco >= 9600 & isco <= 9620) | (isco >= 9622 & isco <= 9629)) return(8)
    if ((isco >= 1000 & isco <= 1300) | (isco >= 1320 & isco <= 1349) | (isco >= 2400 & isco <= 2432) | (isco >= 2610 & isco <= 2619) | isco == 2631 | (isco >= 100 & isco <= 110)) return(9)
    if ((isco >= 1310 & isco <= 1312) | (isco >= 1400 & isco <= 1439) | (isco >= 2433 & isco <= 2434) | (isco >= 3300 & isco <= 3339) | isco == 3343 | (isco >= 3350 & isco <= 3359) | isco == 3411 | isco == 5221 | (isco >= 200 & isco <= 210)) return(10)
    if ((isco >= 3340 & isco <= 3342) | isco == 3344 | (isco >= 4000 & isco <= 4131) | (isco >= 4200 & isco <= 4221) | (isco >= 4224 & isco <= 4413) | (isco >= 4415 & isco <= 4419)) return(11)
    if (isco == 4132 | isco == 4222 | isco == 4223 | isco == 5230 | isco == 9621) return(12)
    if ((isco >= 2200 & isco <= 2212) | isco == 2250 | (isco >= 2261 & isco <= 2262) | (isco >= 2300 & isco <= 2330) | (isco >= 2350 & isco <= 2352) | isco == 2359 | isco == 2600 | isco == 2621 | isco == 2630 | (isco >= 2632 & isco <= 2634) | (isco >= 2636 & isco <= 2640) | (isco >= 2642 & isco <= 2643)) return(13)
    if (isco == 2163 | isco == 2166 | (isco >= 2220 & isco <= 2240) | isco == 2260 | (isco >= 2263 & isco <= 2269) | (isco >= 2340 & isco <= 2342) | (isco >= 2353 & isco <= 2356) | isco == 2620 | isco == 2622 | isco == 2635 | isco == 2641 | (isco >= 2650 & isco <= 2659) | isco == 3200 | (isco >= 3220 & isco <= 3230) | isco == 3250 | (isco >= 3253 & isco <= 3257) | isco == 3259 | (isco >= 3400 & isco <= 3410) | (isco >= 3412 & isco <= 3413) | (isco >= 3430 & isco <= 3433) | isco == 3435 | isco == 4414) return(14)
    if (isco == 3240 | isco == 3251 | isco == 3258 | (isco >= 3420 & isco <= 3423) | isco == 3434 | (isco >= 5000 & isco <= 5120) | (isco >= 5140 & isco <= 5142) | isco == 5163 | isco == 5165 | isco == 5200 | isco == 5220 | (isco >= 5222 & isco <= 5223) | (isco >= 5241 & isco <= 5242) | (isco >= 5300 & isco <= 5321) | (isco >= 5400 & isco <= 5413) | isco == 5419 | isco == 8331) return(15)
    if ((isco >= 5130 & isco <= 5132) | (isco >= 5150 & isco <= 5162) | isco == 5164 | isco == 5169 | (isco >= 5210 & isco <= 5212) | isco == 5240 | (isco >= 5243 & isco <= 5249) | (isco >= 5322 & isco <= 5329) | isco == 5414 | isco == 8322 | (isco >= 9100 & isco <= 9129) | (isco >= 9400 & isco <= 9520)) return(16)
  }
  return(NA_real_)
}

calc_oesch_88 <- Vectorize(get_oesch_isco88)
calc_oesch_08 <- Vectorize(get_oesch_isco08)

# --- PART 3: APPLY OESCH CODING (Resp & Partner) ---
cat("\n>> Action: Applying Oesch Logic (Respondent + Partner Substitution)...\n")

df_oesch <- df_prep %>%
  mutate(
    # 1. Respondent Class
    oesch_resp = case_when(
      essround <= 5 ~ calc_oesch_88(isco88_num, selfem_mainjob),
      essround >= 6 ~ calc_oesch_08(isco08_num, selfem_mainjob),
      TRUE ~ NA_real_
    ),
    
    # 2. Partner Class
    oesch_part = case_when(
      essround <= 5 ~ calc_oesch_88(isco88_p_num, selfem_partner),
      essround >= 6 ~ calc_oesch_08(isco08_p_num, selfem_partner),
      TRUE ~ NA_real_
    ),
    
    # 3. Final Oesch 16 (Respondent > Partner)
    oesch16 = coalesce(oesch_resp, oesch_part)
  ) %>%
  mutate(
    # Collapse to Oesch 8
    oesch8 = case_when(
      oesch16 <= 2 ~ 1,
      oesch16 %in% c(3, 4) ~ 2,
      oesch16 %in% c(5, 6) ~ 3,
      oesch16 %in% c(7, 8) ~ 4,
      oesch16 %in% c(9, 10) ~ 5,
      oesch16 %in% c(11, 12) ~ 6,
      oesch16 %in% c(13, 14) ~ 7,
      oesch16 %in% c(15, 16) ~ 8,
      TRUE ~ NA_real_
    )
  )

# --- PART 4: DIGCLASS SCHEMES (Respondent Only) ---
cat("\n>> Action: Coding ORDC, EGP, and Microclass (Respondent Only)...\n")
# Note: DIGCLASS packages typically focus on the individual respondent by default.

df_final <- df_oesch %>%
  mutate(
    # 1. Bridge for ORDC/EGP
    isco88_str = case_when(
      essround <= 5 & !is.na(isco88_num) ~ str_pad(isco88_num, 4, pad="0"),
      essround >= 6 & !is.na(isco08_num) ~ suppressWarnings(DIGCLASS::isco08_to_isco88(str_pad(isco08_num, 4, pad="0"))),
      TRUE ~ NA_character_
    ),
    
    # 2. ORDC
    ordc = DIGCLASS::isco88_to_ordc(isco88_str),
    
    # 3. EGP
    egp11 = DIGCLASS::isco88_to_egp(
      isco88_str, 
      self_employed = if_else(selfem_mainjob > 1, 1, 0), 
      n_employees = if_else(emplno_cat == 2, 15, 0),
      n_classes = 11
    ),
    
    # 4. MICROCLASS
    microclass = if_else(
      essround >= 6 & !is.na(isco08_num), 
      DIGCLASS::isco08_to_microclass(str_pad(isco08_num, 4, pad="0")), 
      NA_character_
    )
  )

# --- PART 5: REPORT & SAVE ---
cat("\n>> Final Distributions:\n")
cat("Oesch 8 (With Substitution):\n"); print(head(table(df_final$oesch8), 5))

saveRDS(df_final, output_path)
cat("\nSaved to", output_path, "\n")
sink()

message("Script 03 complete. Oesch now uses Partner Substitution.")