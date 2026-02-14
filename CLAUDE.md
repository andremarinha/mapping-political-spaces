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
data/raw/ESS/          Read-only source data (ESS integrated CSV) [.gitignored]
data/temp/             Intermediate pipeline outputs (.rds) [.gitignored]
data/master/           Single source of truth: ess_final.rds [.gitignored]
data/archive/          Previous master versions [.gitignored]
scripts/legacy/v2_archive/R_scripts/   Active pipeline (01–06, sequential)
scripts/legacy/        Quarto refs, Oesch source files, v1 archive
scripts/archive/       Superseded scripts (never deleted, moved here)
figures/               PNG (300dpi) + PDF outputs
tables/                Audit tables and distributions (.csv)
articles/              Reference literature (PDFs) [.gitignored]
misc/                  ESS docs, ISCO correspondence tables
legacy/                Historical documentation and execution logs
log/                   Session logs (one per working session)
writing/               Future LaTeX manuscripts
presentation/          Future Beamer slides
.gitignore             Git exclusion rules (large data, RStudio internals)
```

## Data Pipeline
Scripts **must run in order**: `01_cleaning.R` → `02_weighting.R` → `03_class_coding.R` → `04_final_merge.R` → `05_descriptives.R` → `06_participation.R`. Master output: `data/master/ess_final.rds` (67,358 × 1,688 — ALL original ESS variables + derived class/weight/participation variables).

**Note:** Script 04 was updated (2026-02-14) to retain ALL original ESS columns. Previous version archived at `scripts/archive/04_final_merge_v1.R`.

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

## Methodological Reference
`scripts/legacy/Análise multivariada_A2_ACM_AC.qmd` — MCA + Cluster Analysis tutorial (Daniela Craveiro). Uses `FactoMineR`/`factoextra` with the `hobbies` dataset. Demonstrates a 6-step workflow:
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
- Fixed `04_final_merge.R`: removed restrictive `select()` that kept only ~25 vars; master now retains ALL 1,682 original ESS + derived variables. Previous version archived at `scripts/archive/04_final_merge_v1.R`.
- Created `06_participation.R`: recodes 6 political participation items as dummies (0/1/NA), harmonises `pbldmn`/`pbldmna` across rounds via `coalesce()`, recodes `vote` value 3 ("Not eligible") to NA.
- Master dimensions: 67,358 × 1,688 (1,682 existing + 6 new dummies).
- Noted methodological references for future LCA: Oser (2022), Jeroense & Spierings (2023). Packages: `multilevLCA`, `poLCA`.
- **Project state**: Master dataset complete with all ESS variables + class schemes + participation dummies. LCA for participation profiles not yet started.
- **Next**: Latent Class Analysis (country-specific + regional) to derive participation profiles from the 6 dummies.
