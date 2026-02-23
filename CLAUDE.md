# CLAUDE.md — Project Brief

> **This file is the persistent context document. It MUST be updated at the end of every session.**

## Project
**"All Quiet on the Southern Front? Mapping the Political Spaces in twenty-first century Southern Europe"** — Structure and social structuring of political conflict in Southern Europe (PT, ES, GR, IT) using ESS data (Rounds 1–11, ~2002–2022). Geometric Data Analysis tradition.

**Output:** First empirical chapter of a PhD thesis AND a standalone manuscript for submission to a Q1 journal in Political Science / Political Sociology.

## Repositories
- **Primary (working):** Google Drive — `G:\My Drive\1_projects\mapping`
- **Replication (public):** GitHub — `github.com/andremarinha/mapping-political-spaces`
- Keep both in sync. GitHub is the canonical version-controlled copy.

## Iron Rules (Do Not Violate)

### 1. Never delete files
- **No file, directory, or data object may be deleted — ever.**
- Superseded files are moved to `archive/` subdirectories (e.g., `scripts/archive/`, `data/archive/`).
- Deprecated code is preserved in `scripts/legacy/`.
- If a file is no longer needed, rename it with a `_deprecated` suffix or move it — never `rm`.

### 2. Always log
- **Every working session must produce a log entry** in `log/session_YYYY-MM-DD.md`.
- If multiple sessions occur on the same day, append sections (Session 1, Session 2, ...).
- Logs record: actions taken, decisions made, current project state, next steps.
- `CLAUDE.md` Session History section is updated at the end of every session.

### 3. Interpretation constraints
1. Never compare raw coordinates across separately estimated spaces
2. Never interpret numeric distances as metric effects
3. Always interpret movement **relative to** other groups and parties
4. Distinguish change in dimensionality (structure) from change in structuring (positions)
5. MCA inertia is **not** explained variance — do not interpret percentage thresholds as in PCA

## Language & Tools
- **R** (tidyverse ecosystem), RStudio project: `mappingSE.Rproj`
- Always use **relative paths** from project root
- DIGCLASS package for class scheme derivation (ORDC, EGP, Microclass)
- Key R packages for analysis: `FactoMineR`, `factoextra` (MCA/MFA), `cluster` (clustering), `multilevLCA` / `poLCA` (LCA)

## Folder Structure
```
mapping/
├── 0_README.md                    Project documentation (renamed from README.md)
├── 1_analysis.qmd                 Central Quarto analysis document
├── 2_replication_code.R           Auto-generated replication code (via knitr::purl)
├── 3_presentation.qmd            Reveal.js presentation slides
├── 4_paper.qmd                   PhD chapter / journal manuscript
├── 5_overleaf_prep.qmd           Export figures/tables for Overleaf
├── CLAUDE.md                     This file (updated every session)
├── assets/                       Bibliography (bib.bib) + citation style (apsr.csl)
├── saved/                        Shared workspace (.Rdata/.rds) [.gitignored]
├── exports/                      Overleaf-ready outputs [.gitignored]
│   ├── figures/                  PNG (300dpi) + PDF
│   └── tables/                   LaTeX code
├── data/                         [all .gitignored]
│   ├── raw/ESS/                  Read-only source data
│   ├── temp/                     Intermediate pipeline outputs
│   ├── master/                   ess_final.rds (single source of truth)
│   └── archive/                  Previous master versions
├── scripts/                      Active pipeline (01–06, sequential)
│   ├── 01_cleaning.R ... 06_participation.R
│   └── helpers/                  Oesch reference data (.txt)
├── figures/                      Audit PNG (300dpi) + PDF outputs
├── tables/                       Audit tables (.csv)
├── articles/                     Reference literature [.gitignored]
├── misc/                         ESS docs, ISCO correspondence tables
├── log/                          Session logs
└── legacy/                       All historical material
    ├── scripts_v1/               Deprecated v1 pipeline
    ├── archive/                  Superseded scripts (04_v1, etc.)
    ├── reference_qmd/            MCA/PCA tutorial QMDs
    ├── old_dirs/                 Empty writing/ and presentation/ dirs
    └── log/                      Historical execution logs
```

## Data Pipeline
Scripts **must run in order**: `01_cleaning.R` → `02_weighting.R` → `03_class_coding.R` → `04_final_merge.R` → `05_descriptives.R` → `06_participation.R` → `07_attitudinal_recoding.R`. Master output: `data/master/ess_final.rds` (67,358 × 1,696 — ALL original ESS variables + derived class/weight/participation/attitudinal variables).

**Note:** Script 04 was updated (2026-02-14) to retain ALL original ESS columns. Previous version archived at `legacy/archive/04_final_merge_v1.R`.

## Class Schemes
| Scheme | Classes | Method | Coverage |
|--------|---------|--------|----------|
| Oesch 16/8/5 | 16 → 8 → 5 | Manual syntax (Oesch's original ranges) | All rounds |
| ORDC | 13 + 1 (Unclassifiable) | DIGCLASS (ISCO-88 bridged) | All rounds |
| EGP | 11 | DIGCLASS | All rounds |
| Microclass | Variable | DIGCLASS (requires ISCO-08) | Rounds 6–11 only |

## Political Participation Dummies (Script 06)
| Dummy | Source | Rounds | Recode |
|-------|--------|--------|--------|
| `badge_d` | `badge` | 1–11 | 1=Yes→1, 2=No→0, else→NA |
| `bctprd_d` | `bctprd` | 1–11 | 1=Yes→1, 2=No→0, else→NA |
| `contplt_d` | `contplt` | 1–11 | 1=Yes→1, 2=No→0, else→NA |
| `sgnptit_d` | `sgnptit` | 1–11 | 1=Yes→1, 2=No→0, else→NA |
| `pbldmn_d` | `pbldmn` (R1-9) + `pbldmna` (R10-11) | 1–11 | Harmonised via `coalesce()` |
| `vote_d` | `vote` | 1–11 | 3="Not eligible"→NA |

**Next step:** Latent Class Analysis (country-specific + regional) using `multilevLCA` or `poLCA` to derive participation profiles from these dummies (following Oser 2022; Jeroense & Spierings 2023).

## Attitudinal & Structural Recodes (Script 07)
| Variable | Source | Recode | Rounds |
|----------|--------|--------|--------|
| `freehms_r` | `freehms` | Reversed: 1=Disagree strongly...5=Strongly agree | 1–11 |
| `gincdif_r` | `gincdif` | Reversed: 1=Disagree strongly...5=Strongly agree | 1–11 |
| `polintr_r` | `polintr` | Reversed: 1=Not at all...4=Very interested | 1–11 |
| `rlgblg_r` | `rlgblg` | 0=No, 1=Yes | 1–11 |
| `rlgatnd_r` | `rlgatnd` | 1=Active, 2=Occasional, 3=Not religious | 1–11 |
| `domicil_r` | `domicil` | 1=Urban, 2=Suburban, 3=Town, 4=Rural | 1–11 |
| `mother_edu_5cat` | `edulvlma`+`eiscedm` | Harmonised 5-cat ISCED via `coalesce()` | 1–11 |
| `father_edu_5cat` | `edulvlfa`+`eiscedf` | Harmonised 5-cat ISCED via `coalesce()` | 1–11 |

Reversal logic follows Delespaul (2025). Parental education harmonised across two ESS coding systems (5-cat ISCED for R1–4, 7-cat ES-ISCED for R4–11) into common 5 categories; ES-ISCED preferred where both available.

## Coding Strategy (Frozen)
- **Primary analysis**: Disjunctive (categorical/indicator) coding of all attitudinal variables
- **Robustness appendix**: Numeric/ordered coding — never used for primary interpretation

## Analytical Method
- **Country-specific** analyses (no forced cross-national equivalence)
- **Multi-table GDA**: MFA / STATIS logic — each ESS round is a separate block
- Compromise space captures common structure; partial representations capture round deviations
- Supplementary projections: Oesch classes and parties as barycentres

## Weighting
`analysis_weight = pspwght * pweight * 10000` — the 10k factor produces readable weighted counts. ESS changed weighting variables at Round 9 (`anweight`); hybrid strategy handles this.

## Visualization Standards
- Palette: `viridis::plasma` (purple → yellow)
- Missing/Unclassifiable: `grey80`
- Outputs: high-res PNG (300dpi) + vector PDF
- Heatmaps: 2x2 grid layout. Bar charts: condensed bottom legends.

## Workflow Architecture (Humphreys Pattern)
```
R scripts (01–06)  →  data/master/ess_final.rds
                              ↓
                     1_analysis.qmd  →  saved/analysis.Rdata
                              ↓
              ┌───────────────┼───────────────┐
              ↓               ↓               ↓
       4_paper.qmd    3_presentation.qmd   5_overleaf_prep.qmd
                                              ↓
                                     exports/figures/ + exports/tables/
```
All consumer documents (`4_paper`, `3_presentation`, `5_overleaf_prep`) load the shared workspace from `saved/analysis.Rdata`. The replication script `2_replication_code.R` is auto-generated via `knitr::purl("1_analysis.qmd")`.

## Methodological Reference
`legacy/reference_qmd/Análise multivariada_A2_ACM_AC.qmd` — MCA + Cluster Analysis tutorial (Daniela Craveiro). Uses `FactoMineR`/`factoextra` with the `hobbies` dataset. Demonstrates a 6-step workflow:
1. Data adequacy assessment
2. Dimensionality (eigenvalues, inertia, scree)
3. Interpret dimensions (discrimination measures, eta2)
4. Interpret category configurations (contributions, cos2, perceptual maps)
5. Supplementary variable projection
6. Cluster analysis on MCA coordinates (hierarchical → K-means, Carvalho 2008 approach)

This serves as **procedural inspiration** for our analysis. Our project adapts this workflow to a multi-table (MFA/STATIS) framework with political attitudinal data.

## Session Log
All session logs are stored in `log/session_YYYY-MM-DD.md`. Always consult the most recent log to understand current project state.

## Session History (cumulative)

### 2026-02-12 — Project Documentation Setup
- Inspected full folder structure
- Created `CLAUDE.md` and `README.md` (17 sections, comprehensive)
- Created `log/` directory and session logging system
- Noted QMD reference file as methodological inspiration
- **Project state**: Data engineering complete. Analysis Phase 1 not started.
- **Next**: Begin Phase 1 — attitudinal variable selection and harmonisation

### 2026-02-13 — Governance Hardening & Git Setup
- Added manuscript title and dual-output framing (PhD chapter + Q1 journal)
- Established **Iron Rules**: (1) never delete files, (2) always log, (3) interpretation constraints
- Added dual-repository setup (Google Drive working copy + GitHub replication)
- Created `.gitignore` (excludes large data, articles, RStudio internals)
- Initialized git repository; configured GitHub remote (`andremarinha`)
- Updated `CLAUDE.md` and `README.md` with all governance changes
- **Project state**: Data engineering complete. Git repo initialized. Analysis Phase 1 not started.
- **Next**: Begin Phase 1 — attitudinal variable selection and harmonisation

### 2026-02-14 — Master Widening & Participation Recoding
- Fixed `04_final_merge.R`: removed restrictive `select()` that kept only ~25 vars; master now retains ALL 1,682 original ESS + derived variables. Previous version archived at `legacy/archive/04_final_merge_v1.R`.
- Created `06_participation.R`: recodes 6 political participation items as dummies (0/1/NA), harmonises `pbldmn`/`pbldmna` across rounds via `coalesce()`, recodes `vote` value 3 ("Not eligible") to NA.
- Master dimensions: 67,358 × 1,688 (1,682 existing + 6 new dummies).
- Noted methodological references for future LCA: Oser (2022), Jeroense & Spierings (2023). Packages: `multilevLCA`, `poLCA`.
- **Project state**: Master dataset complete with all ESS variables + class schemes + participation dummies. LCA for participation profiles not yet started.
- **Next**: Latent Class Analysis (country-specific + regional) to derive participation profiles from the 6 dummies.

### 2026-02-16 — Humphreys-style Workflow Reorganization
- Reorganized entire project to follow Macartan Humphreys' `sample_project` radial workflow pattern.
- Promoted 6 active pipeline scripts from `scripts/legacy/v2_archive/R_scripts/` → `scripts/` (top-level).
- Moved Oesch helper files to `scripts/helpers/`.
- Consolidated legacy material: v1 scripts → `legacy/scripts_v1/`, archived scripts → `legacy/archive/`, QMD tutorials → `legacy/reference_qmd/`, empty dirs → `legacy/old_dirs/`.
- Renamed `README.md` → `0_README.md` (Humphreys convention).
- Created Quarto stubs: `1_analysis.qmd` (central analysis), `3_presentation.qmd` (reveal.js), `4_paper.qmd` (manuscript), `5_overleaf_prep.qmd` (export).
- Created `2_replication_code.R` (auto-generated stub via `knitr::purl`).
- Created `assets/` with `bib.bib` (starter bibliography) and `apsr.csl` (APSA citation style).
- Created `saved/` for shared workspace persistence, `exports/` for Overleaf outputs.
- Updated `.gitignore` for new paths (`saved/`, `exports/`, `*_files/`, `*.html`, `*_cache/`).
- Updated `# Path:` comments in all 6 R scripts.
- All moves via `git mv` (history preserved). No files deleted (Iron Rule 1).
- **Project state**: Project restructured for Humphreys-style workflow. Data pipeline functional. Analysis not yet started.
- **Next**: Begin Phase 1 — attitudinal variable selection and harmonisation in `1_analysis.qmd`.

### 2026-02-23 — Attitudinal & Structural Variable Recoding
- Created `07_attitudinal_recoding.R`: recodes 8 variables for downstream MCA/LCA analysis.
- Recoded: `freehms_r`, `gincdif_r` (reversed per Delespaul 2025), `polintr_r` (reversed), `rlgblg_r` (binary), `rlgatnd_r` (7→3 categories), `domicil_r` (5→4 categories).
- Harmonised parental education: `mother_edu_5cat` and `father_edu_5cat` from two ESS coding systems (5-cat ISCED R1–4 + 7-cat ES-ISCED R4–11) into common 5-category scale via `coalesce()`.
- Master dimensions: 67,358 × 1,696 (1,688 + 8 new columns).
- Decided LCA indicator set: 6 existing participation dummies (R1–11 coverage), not adding wrkorg/wrkprty (which would restrict to R1–9).
- **Project state**: Data engineering extended with attitudinal recodes. LCA-MCA implementation plan drafted. Ready to begin coding analysis.
- **Next**: Implement LCA-MCA analysis in `1_analysis.qmd`.
