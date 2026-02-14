# All Quiet on the Southern Front? Mapping the Political Spaces in twenty-first century Southern Europe

## 1. Abstract

This project analyses the structure and social structuring of political conflict over time in Southern Europe — Portugal, Spain, Greece, and Italy — using data from the European Social Survey (ESS), Rounds 1 through 11 (~2002–2022). Drawing on the Geometric Data Analysis (GDA) tradition, the project pursues two interlocking objectives: (A) identifying how many dimensions structure political conflict at different points in time, how these dimensions are composed, and whether this composition is stable or changes across rounds; and (B) analysing how political spaces are socially structured over time, focusing on the positioning of Oesch social classes and their proximity to political parties.

**Outputs:** This project produces (1) the first empirical chapter of a PhD thesis and (2) a standalone manuscript for submission to a Q1 journal in Political Science / Political Sociology.

## 1b. Repositories and Replication

| Location | Purpose | URL |
|----------|---------|-----|
| Google Drive | Working copy (primary) | `G:\My Drive\1_projects\mapping` |
| GitHub | Version control and replication | `github.com/andremarinha/mapping-political-spaces` |

The GitHub repository is the canonical version-controlled copy. Large data files (ESS CSV, `.rds` intermediates, reference articles) are excluded via `.gitignore` and must be obtained separately (see Section 5 for data source).

---

## 2. Theoretical Orientation

### Relational conception of political space

Political space is treated as a **relational structure of oppositions**, not as a set of latent scales. This project follows the geometric data analysis tradition rooted in the work of Bourdieu, Benzécri, and their successors (Le Roux & Rouanet, Hjellbrekke, Lebaron). Within this framework:

- **Distances** represent similarity of response profiles between individuals or groups
- **Axes** represent major oppositions emerging from the data, not pre-defined theoretical dimensions
- **Positions** are meaningful only in relation to other positions — there are no absolute coordinates

### Key epistemological commitments

1. **No a priori assumption about the number or meaning of dimensions.** The dimensionality of political conflict is an empirical question, not a theoretical input.
2. **No assumption of linearity or equal spacing** between attitudinal categories. Ordinal response scales are not treated as interval measures.
3. **Emphasis on relative positions and proximities** rather than absolute scores, coefficients, or effect sizes.
4. **Diachronic comparison must be methodologically grounded.** Separately estimated spaces cannot be compared directly due to rotational and scaling indeterminacy.

---

## 3. Project Governance

### No-delete policy

**No file, directory, or data object may be deleted — ever.** This is a strict, unconditional rule that protects the project's audit trail and ensures full reproducibility.

| Situation | Action |
|-----------|--------|
| A script is superseded by a new version | Move the old script to `scripts/archive/` (or relevant `archive/` subdirectory) |
| A data file is replaced | Move the old version to `data/archive/` |
| Code is deprecated | Rename with `_deprecated` suffix or move to `legacy/` |
| A file is no longer needed | Keep it where it is, or move to `archive/` — never delete |

### Logging requirement

**Every working session must produce a log entry.** Session logs are stored in `log/session_YYYY-MM-DD.md` and record:

1. **Actions taken** — what was done, which files were created/modified
2. **Decisions made** — including rationale
3. **Current project state** — what phase the project is in
4. **Next steps** — what should happen in the following session

If multiple sessions occur on the same day, append numbered sections (Session 1, Session 2, ...). The cumulative session history is also maintained in `CLAUDE.md`.

### Decision log

All analytical and engineering decisions are recorded in Section 16 of this document with a unique ID (D01, D02, ...), a description, and a rationale. Frozen decisions cannot be reversed without explicit justification logged in the same table.

---

## 4. Research Questions

### A. Dimensionality

How many dimensions structure political conflict at different points in time? How are these dimensions composed (which attitudinal oppositions define them)? Is this composition stable across ESS rounds, or does it change?

### B. Structuring

How are political spaces socially structured over time? Specifically:
- Where are Oesch social classes positioned in the political space?
- Where are political parties positioned?
- How close or distant are specific classes from specific parties?
- Do class–party alignments reconfigure over time?
- Do classes move within a stable structure, or does the structure itself shift?

---

## 5. Data

### Source
European Social Survey (ESS), integrated file covering Rounds 1–11.

| Property | Value |
|----------|-------|
| Rounds | 1–11 (~2002–2022) |
| Countries | Portugal (PT), Spain (ES), Greece (GR), Italy (IT) |
| Target population | Adults aged 18+ |
| Raw file | `data/raw/ESS/ess_integrated_rounds1_11.csv` (~150 MB) |

**Note:** Greece and Italy have coverage gaps across rounds. Portugal and Spain have complete or near-complete coverage across all 11 rounds.

### Master analytical file
`data/master/ess_final.rds` — the single source of truth for all downstream analyses. This file is produced by the data engineering pipeline described below.

---

## 6. Data Engineering Pipeline

The dataset is built via **6 sequential R scripts** located in `scripts/legacy/v2_archive/R_scripts/`. They must be executed in order. Each script reads from the previous output and writes to a defined location.

| # | Script | Action | Key Logic | Output |
|---|--------|--------|-----------|--------|
| 01 | `01_cleaning.R` | Filter and pre-clean | Filters for PT, ES, GR, IT; age >= 18. Normalises column names to lowercase. Pads ISCO codes to 4 digits. Cleans employment relation (`emplrel`), employee count (`emplno`), supervisor status (`jbspv`). | `data/temp/01_filtered_data.rds` |
| 02 | `02_weighting.R` | Calculate analysis weights | Computes `analysis_weight = pspwght * pweight * 10000`. See weighting strategy below. | `data/temp/02_weighted_data.rds` |
| 03 | `03_class_coding.R` | Derive class schemes | Oesch 16/8: manual syntax (Oesch's original ranges). ORDC and EGP: via `DIGCLASS` package (ISCO-88 bridged). Microclass: via `DIGCLASS` (Rounds 6–11 only, requires ISCO-08). | `data/temp/03_classed_data.rds` |
| 04 | `04_final_merge.R` | Label, aggregate, finalise | Aggregates Oesch 16 → Oesch 5. Applies factor labels to all class schemes. Maps unmapped ORDC codes to "14. Unclassifiable". **Retains ALL original ESS variables** (v2; previous restrictive version archived at `scripts/archive/04_final_merge_v1.R`). | `data/master/ess_final.rds` |
| 05 | `05_descriptives.R` | Audit and visualise | Generates coverage heatmaps and class distribution plots. Applies Plasma palette standards. | `figures/*.png`, `figures/*.pdf` |
| 06 | `06_participation.R` | Recode participation dummies | Recodes 6 political participation items as dummies (0/1). Harmonises `pbldmn`/`pbldmna` across rounds via `coalesce()`. Recodes `vote` 3 ("Not eligible") to NA. | `data/master/ess_final.rds` (updated) |

**Master dataset:** 67,358 rows × 1,688 columns (all original ESS variables + derived class, weight, and participation variables).

### Weighting Strategy

**Problem:** ESS changed the weighting variable structure at Round 9, introducing `anweight`.

**Decision:** Hybrid strategy.

| Rounds | Formula | Source |
|--------|---------|--------|
| 1–8 | `analysis_weight = pspwght * pweight * 10000` | ESS Weighting Guide V1.1, p. 6 |
| 9–11 | `anweight` (already incorporates design and population corrections) | ESS documentation |

- `pspwght` corrects for sampling bias (post-stratification)
- `pweight` corrects for country population size
- The 10,000 scaling factor converts decimal weights into readable integer-scale counts

**Interpretation:** Weighted counts (`w_n`) are not population estimates. They are used to compute within-country shares: `share = w_n(class) / w_n(country total)`.

---

## 7. Class Schemes

### Oesch (16 → 8 → 5 classes)

**Source:** Daniel Oesch's class schema, based on occupational logic (work logic axis) and hierarchical position (employment relation axis).

**Implementation:** Manual syntax applied in R, using Oesch's original ISCO-based ranges. This is a deliberate choice over automated packages to ensure exact correspondence with Oesch's published coding rules.

| Level | Classes | Aggregation logic |
|-------|---------|-------------------|
| Oesch 16 | 16 detailed classes | Base level, derived from ISCO + employment relation |
| Oesch 8 | 8 classes | Collapse within each work logic: self-employed professionals & large employers, small business owners, technical (semi-)professionals, production workers, (associate) managers, clerks, socio-cultural (semi-)professionals, service workers |
| Oesch 5 | 5 classes | Higher-grade service class, lower-grade service class, small business owners, skilled workers, unskilled workers |

### ORDC (13 + 1 classes)

**Source:** Occupational-Resource-based Distributional Class schema.

**Implementation:** Derived via the `DIGCLASS` R package using ISCO-88 bridged codes.

**Gap fix (Decision D03):** Approximately 10–15% of respondents (Armed Forces, vague occupation codes, etc.) fall outside the standard 13 ORDC classes. These are **not** dropped. They are explicitly coded as **"14. Unclassifiable / Armed Forces"** and rendered in grey in all visualisations. This ensures that sample sizes remain consistent and that dropped cases do not silently bias class distributions.

| Classes 1–13 | Standard ORDC categories (cultural/balanced/economic × upper/upper-middle/lower-middle, skilled working, unskilled working, primary-sector, welfare dependents) |
|---------------|---|
| Class 14 | Unclassifiable / Armed Forces (explicit residual) |

### EGP (11 classes)

**Source:** Erikson–Goldthorpe–Portocarero class schema.

**Implementation:** Derived via `DIGCLASS`.

Classes: I (higher managerial/professional), II (lower managerial/professional), IIIa (routine non-manual high), IIIb (routine non-manual low), IVa (small proprietors with employees), IVb (small proprietors without employees), IVc (farmers), V (lower technical/supervisors), VI (skilled manual), VIIa (unskilled manual), VIIb (farm labour).

### Microclass

**Source:** Grusky–Weeden microclass schema.

**Implementation:** Derived via `DIGCLASS`. **Only available for Rounds 6–11** because it requires ISCO-08 codes, which are not present in Rounds 1–5. Returns `NA` for earlier rounds.

---

## 8. Coding Strategy (Frozen Design Decision)

This is a settled design decision. Both approaches are used, but they serve different purposes.

### Primary analysis: Disjunctive (categorical) coding

**Decision:** All attitudinal variables entering the MCA/MFA analysis are treated as categorical and coded using **complete disjunctive (indicator) coding**. Each response category becomes a binary column.

**Rationale:**
1. ESS attitudinal items are **ordinal but not interval-scaled**. Treating 5-point scales as numeric imposes linearity and equal-distance assumptions that are not warranted.
2. Disjunctive coding **avoids imposing** any assumption about the distance between adjacent categories. The geometry of the space is determined entirely by the empirical co-occurrence of response patterns.
3. Category meanings may **shift subtly over time**. Categorical treatment is more robust to such diachronic drift because it does not assume that "4" in 2002 means the same distance from "3" as "4" in 2022.
4. This coding is **standard practice** in MCA, CSA, and broader GDA-based political space analyses.

**Implications:**
- Lower explained inertia per dimension (this is **expected and acceptable** — see Section 12)
- Axes are interpreted via **category contributions and oppositions**, not regression coefficients
- Results are interpreted **relationally** (distances, proximities, poles)

### Robustness appendix: Ordered / numeric coding

**Decision:** All analyses are replicated using ordered/numeric coding of attitudinal items.

**Purpose:**
1. Demonstrate that substantive conclusions about class–party structuring **do not depend on the coding choice**
2. Bridge GDA-based and mainstream political science expectations (where numeric PCA is more familiar)

**Interpretation rule:** Numeric-coding results are used **only for robustness**. Primary interpretations always rely on the disjunctive-coded analysis.

---

## 9. Attitudinal Variables

### Selection criteria

Candidate attitudinal items must:
1. Be available across **all 11 ESS rounds** (or a clearly documented core subset)
2. Capture politically relevant attitudes (economic redistribution, immigration, social trust, European integration, democratic satisfaction, cultural values, etc.)
3. Have **stable category structures** across rounds (or be harmonisable)
4. Not have excessive missingness in any country-round combination

### Harmonisation process

1. Identify all candidate items in the ESS integrated file
2. Audit category labels and response scales across all 11 rounds for each item
3. Recode refusals, "Don't know", and "No answer" consistently (either as passive/supplementary or excluded)
4. Flag and document any items where categories were collapsed, added, or reworded across rounds
5. Produce a comparability audit: category counts, missingness rates by country × round

### Key diagnostics
- Category stability across rounds
- Rare or collapsing categories (categories with very few responses may distort the geometry)
- Missingness patterns (systematic missingness by country or round)

### Retained items

`[TBD — to be completed after Phase 1 item selection and harmonisation]`

### Category harmonisation details

`[TBD — to be completed after Phase 1]`

### Comparability audit results

`[TBD — to be completed after Phase 1]`

---

## 10. Multi-Table Analytical Strategy

### The problem of diachronic comparison

Political spaces estimated separately for each ESS round **cannot be directly compared**. This is because:
- Factor solutions are subject to **rotational indeterminacy** (axes can be arbitrarily rotated)
- Solutions are subject to **scaling indeterminacy** (eigenvalues and coordinates depend on sample-specific inertia)
- Even if the same substantive oppositions emerge in two rounds, coordinates are not on a shared metric

Comparing raw coordinates across separately estimated MCA solutions is **methodologically invalid**.

### Chosen approach: Multi-table GDA (MFA / STATIS)

To enable legitimate diachronic comparison, time is incorporated **within a single comparative framework**:

1. Each ESS round is treated as a separate but comparable **block** (a sub-table of attitudinal indicators)
2. Multiple Factor Analysis (MFA) or the STATIS family of methods produce:
   - A **compromise space** capturing the common structure of political conflict across all rounds
   - **Partial representations** showing how each round expresses (or deviates from) this common structure
3. This framework allows:
   - Assessing whether the dimensional structure is **stable or changing**
   - Identifying which rounds **deviate** from the compromise
   - Projecting supplementary variables (classes, parties) into a **shared space** with legitimate coordinate comparison

### Country-specific analyses

Portugal, Spain, Greece, and Italy are analysed **separately**. This avoids forcing cross-national equivalence of political conflict structures. Cross-national comparison, if conducted, is done **ex post** at the level of interpreted results — comparing the narrative conclusions, not the raw coordinates.

---

## 11. Phase-by-Phase Analytical Plan

### Phase 1 — Item Selection and Harmonisation

**Goal:** Establish the set of attitudinal variables that will define the political space.

**Steps:**
1. Identify candidate attitudinal items in the ESS integrated file
2. Retain only items available across all 11 rounds (or define and document a core set)
3. Harmonise categories across rounds
4. Recode refusals / DK / NA consistently
5. Produce a comparability audit (category counts, missingness by country × round)

**Key diagnostics:**
- Category stability across rounds
- Rare or collapsing categories
- Missingness patterns

### Phase 2 — Construction of Multi-Table Objects

**Goal:** Build the analytical objects for multi-table GDA.

**Steps:**
1. Apply disjunctive coding to all retained attitudinal variables
2. Construct round-specific blocks (sub-tables)
3. Verify block balance and dimensional coherence

**Key diagnostics:**
- Block size and inertia balance across rounds
- Sensitivity to alternative block constructions

### Phase 3 — Dimensionality Analysis (Research Question A)

**Goal:** Assess the structure of political conflict and its stability over time.

**Metrics and outputs:**
- Eigenvalues and inertia of compromise dimensions
- Category contributions to each dimension (which attitudes define each axis)
- Partial representations of rounds (how each round maps onto the compromise)
- Similarity/dissimilarity measures between round-specific structures (e.g., RV coefficients)

**Interpretation focus:**
- Stability vs. change in dimensional composition
- Emergence or weakening of dimensions over time
- Deviations of specific rounds from the compromise structure

### Phase 4 — Structuring Analysis (Research Question B)

**Goal:** Analyse how political spaces are socially structured over time.

**Procedure:**
1. Project individuals into the compromise space
2. Compute **barycentres** (mean positions) for:
   - Oesch class × round
   - Party choice × round
3. Compute distances between classes and parties by round
4. Track trajectories over time (how class and party positions move across rounds)

**Metrics and outputs:**
- Class and party barycentre coordinates in the compromise space
- Class–party distances by round
- Diachronic trajectories (paths of movement across rounds)

**Interpretation focus:**
- Reconfiguration of class–party alignments over time
- Relative movement of classes within a stable or semi-stable structure
- Increasing or decreasing political representation gaps
- Which classes are becoming closer to or more distant from which parties

---

## 12. Interpretation Rules

These rules are binding. They follow directly from the relational-geometric framework and the multi-table analytical strategy.

1. **Do not compare raw coordinates across separately estimated spaces.** Only coordinates within the compromise space (or projected into it) are comparable.

2. **Do not interpret numeric distances as metric effects.** A distance of 0.4 is not "twice as large" as a distance of 0.2 in any substantive sense. Distances indicate relative proximity or opposition, not quantities.

3. **Always interpret movement relative to other groups and parties.** A class moving "to the right" on Axis 1 is meaningful only in relation to where other classes and the axis poles are. Absolute coordinate shifts are not interpretable in isolation.

4. **Clearly distinguish:**
   - **Change in dimensionality** (the structure itself changes — e.g., a new axis emerges, an existing axis weakens or recomposes)
   - **Change in structuring** (positions within a stable structure shift — e.g., a class moves closer to a different party while the axes remain the same)

5. **MCA inertia is not explained variance.** In disjunctive coding, total inertia is mechanically inflated by the number of categories. Percentages of inertia per axis will be low compared to PCA. This is expected and does not indicate poor model fit. Interpretation focuses on the stability and interpretability of oppositions, not on variance thresholds.

6. **Barycentres for small groups must be treated with caution.** Always report the n (and weighted n) for any class × round or party × round cell. Avoid over-interpreting positions based on very small groups.

---

## 13. Limitations and Mitigations

### Changing item meanings over time

**Risk:** The substantive meaning of attitudinal categories may shift over two decades. "Agree" with a redistribution statement in 2002 may not carry the same political valence as in 2022.

**Mitigations:**
- Disjunctive coding does not assume stable metric distances between categories
- Focus on relational patterns (which categories oppose which) rather than absolute scale positions
- Robustness checks with numeric coding to assess sensitivity
- The multi-table framework explicitly models round-specific deviations from the compromise

### Sample composition changes

**Risk:** The composition of class or party groups may change over time (e.g., a party gains or loses voters, a class grows or shrinks). Barycentres for shrinking groups become less reliable.

**Mitigations:**
- Report n (raw and weighted) for all class × round and party × round estimates
- Avoid over-interpretation of barycentres based on small groups
- Sensitivity checks excluding very small cells

### Explained variance appears low

**Risk:** Non-GDA audiences may interpret low percentages of inertia as indicating a poor or uninformative analysis.

**Mitigations:**
- Explicit explanation that inertia in MCA-style methods is structurally different from variance in PCA
- Total inertia depends on the number of categories, not on the "quality" of the solution
- Emphasis on stability of oppositions and interpretability of axes, not on percentage thresholds
- Modified rates (Benzécri correction) reported where appropriate

### Coverage gaps

**Risk:** Greece and Italy have missing rounds in the ESS, which affects block completeness in the multi-table analysis.

**Mitigation:**
- Document which country × round combinations are available
- Country-specific analyses handle this naturally (each country's multi-table only includes its available rounds)

---

## 14. Visualization Standards

| Element | Standard |
|---------|----------|
| Colour palette | `viridis::plasma` (purple → yellow) for ordinal/nominal class schemes |
| Missing / Unclassifiable | `grey80` |
| Output formats | High-resolution PNG (300 dpi) + vector PDF |
| Heatmaps | 2×2 grid layout |
| Bar charts | Condensed bottom legends |
| Axis labels | Always include dimension number and inertia percentage |
| Barycentre plots | Points labelled with group names; trajectories shown as connected paths with round labels |

---

## 15. Folder Structure

```
mapping/
├── data/
│   ├── raw/ESS/                  Read-only source: ess_integrated_rounds1_11.csv [.gitignored]
│   ├── temp/                     Intermediate pipeline outputs (.rds) [.gitignored]
│   ├── master/                   ess_final.rds (single source of truth) [.gitignored]
│   └── archive/                  Previous master/data versions [.gitignored]
├── scripts/
│   ├── legacy/
│   │   ├── v2_archive/R_scripts/ Active pipeline: 01–05 sequential R scripts
│   │   ├── v1_archive/           Deprecated pipeline (preserved, never deleted)
│   │   ├── oesch_source/         Oesch class coding reference data (.txt)
│   │   └── *.qmd                 Quarto reference files (MCA/PCA interpretation logic)
│   └── archive/                  Superseded scripts (moved here, never deleted)
├── figures/                      Generated plots: PNG (300dpi) + PDF
├── tables/                       Audit tables, class distributions (.csv)
├── articles/                     Reference literature (PDFs) [.gitignored]
├── misc/                         ESS documentation, ISCO correspondence tables
├── legacy/                       Historical README and execution logs
├── log/                          Session logs (one .md per working session)
├── writing/                      Future LaTeX manuscripts
├── presentation/                 Future Beamer slides
├── .gitignore                    Git exclusion rules
├── CLAUDE.md                     Claude Code project brief (updated every session)
├── README.md                     This file
└── mappingSE.Rproj               RStudio project file
```

---

## 16. Decision Log

### Data Engineering Decisions

| ID | Decision | Rationale |
|----|----------|-----------|
| D01 | Input data converted to `.rds` immediately | Preserves R data types and avoids repeated CSV parsing |
| D02 | "Keep All Variables" approach throughout pipeline | Prevents accidental data loss; Script 04 v2 retains all original ESS columns (v1 had a restrictive `select()` — archived at `scripts/archive/04_final_merge_v1.R`) |
| D03 | ORDC gap: unmapped codes → "14. Unclassifiable" | ~15% of respondents fall outside standard 13 classes. Dropping them would silently bias distributions. Explicit 14th category makes the gap visible and auditable. |
| D04 | Heatmap palette: lighter (yellow) = higher coverage | Better visual contrast than "darker = higher" |

### Project Governance Decisions

| ID | Decision | Rationale |
|----|----------|-----------|
| D10 | No-delete policy: files are never removed, only archived | Protects audit trail and reproducibility; superseded files moved to `archive/` or `legacy/` |
| D11 | Mandatory session logging in `log/session_YYYY-MM-DD.md` | Ensures continuity across sessions and enables retrospective tracing of decisions |
| D12 | Dual-repository setup (Google Drive + GitHub) | Google Drive for working collaboration; GitHub for version control, replication, and public access |

### Analytical Design Decisions

| ID | Decision | Rationale |
|----|----------|-----------|
| D05 | Disjunctive coding as primary, numeric as robustness | ESS ordinal items are not interval-scaled; disjunctive coding is standard in GDA; numeric replication demonstrates robustness without compromising the primary analysis |
| D06 | Country-specific analyses (no pooled cross-national MCA) | Political conflict structures may differ fundamentally across countries; pooling would force artificial equivalence |
| D07 | Multi-table (MFA/STATIS) for diachronic comparison | Separately estimated spaces are rotationally indeterminate; multi-table methods provide a shared compromise space enabling legitimate temporal comparison |
| D08 | Oesch implemented via manual syntax, not automated packages | Ensures exact correspondence with Oesch's published coding rules |
| D09 | Microclass restricted to Rounds 6–11 | Requires ISCO-08, which is only available from Round 6 onwards |
| D13 | `vote` value 3 ("Not eligible") recoded to NA | Not a participation choice — excluding maintains validity of participation dummies |
| D14 | `pbldmn` + `pbldmna` harmonised via `coalesce()` | Same concept split at Round 10; `coalesce()` prefers R1-9 variable, falls back to R10-11 |
| D15 | Participation profiles via LCA (not arbitrary typology) | Following Oser (2022) and Jeroense & Spierings (2023): data-driven profiles are more defensible than ad hoc combinatorial categories |
| D16 | Country-specific + regional (pooled) LCA models | Consistent with project's country-specific analytical strategy (D06), with regional model for cross-national comparison |

---

## 17. Key Outputs

| Output | Path | Description |
|--------|------|-------------|
| Master data | `data/master/ess_final.rds` | Cleaned, weighted, class-coded analytical file |
| Master data (CSV) | `data/master/ess_final_sample.csv` | CSV export for inspection |
| Coverage heatmap | `figures/coverage_heatmap.png` | Visualises class scheme coverage by country × round |
| ORDC distribution | `figures/ordc_distribution.png` | Class structure evolution over rounds |
| Oesch 8 distribution | `figures/oesch8_distribution.png` | Oesch 8-class distribution over rounds |
| Class coverage table | `tables/class_coverage.csv` | Detailed coverage counts by scheme × country × round |
| Class distributions | `tables/class_distributions.csv` | Weighted shares by class × country × round |
| Execution logs | `legacy/log/01–04_*.txt` | Automated logs from each pipeline script |

---

## 18. Methodological Reference: MCA + Cluster Analysis Tutorial

The file `scripts/legacy/Análise multivariada_A2_ACM_AC.qmd` (Daniela Craveiro) contains a complete MCA + Cluster Analysis tutorial from a Methods course, using `FactoMineR`/`factoextra` with the `hobbies` dataset. It demonstrates a 6-step workflow:

1. **Data adequacy** — Check categorical structure, residual categories, sample representation
2. **Dimensionality** — Eigenvalues, inertia, scree plot; retain dimensions
3. **Interpret dimensions** — Discrimination measures (eta2), identify structuring variables
4. **Interpret categories** — Contributions (contrib), associations (cos2), perceptual maps; identify poles and oppositions per axis
5. **Supplementary variable projection** — Project socio-demographic variables into the MCA space
6. **Cluster analysis on MCA coordinates** — Hierarchical clustering (Ward, Euclidean) to identify number of clusters; K-means for final assignment; profile description via chi-square tests

This tutorial serves as **procedural inspiration** for our analysis. Our project adapts this single-table MCA workflow to a multi-table (MFA/STATIS) framework with ESS attitudinal data across 11 rounds. Key differences:
- We use MFA/STATIS instead of standalone MCA (to handle diachronic comparison)
- Our "supplementary variables" are Oesch classes and political parties (projected as barycentres)
- Cluster analysis may be applied within the compromise space, not on raw MCA coordinates

---

## 19. References and Resources

- **ESS Weighting Guide V1.1** — weighting strategy foundation
- **Oesch class schema** — original ISCO-based coding syntax (source files in `scripts/legacy/oesch_source/`)
- **DIGCLASS R package** — automated ORDC, EGP, and Microclass derivation
- **ISCO-88 / ISCO-08 correspondence** — `misc/Correspondence_EN_ISCO_08_to_ISCO_88.xlsx`
- Reference articles in `articles/`:
  - Hjellbrekke & Jarness (2022) — MCA and CSA methodology
  - Delespaul (2025) — Common two-dimensional structure of political space
  - Hansen & Toft (2021) — Wealth accumulation and class
  - Hertel et al. (2025) — Multiverse of social class measurement
  - `digclassr_final.pdf` — DIGCLASS package documentation
