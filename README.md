# cost_lefort

Reproducible CMS-based analysis scaffold for:

**Persistence of Open Abdominal Sacrocolpopexy in the Minimally Invasive Era**

This repository is built to answer a fast, defensible abstract question with public Medicare data:

- How often is sacrocolpopexy coded as open abdominal (`57280`) versus minimally invasive (`57425`) in Medicare fee-for-service?
- Has the open share changed over time?
- Which states and provider types still account for a relatively high open share?

## Why this project

The fastest path to an abstract is not a complicated model. It is a clean descriptive question, public data, and a deterministic pipeline. This repo follows the same pattern seen in stronger JAMA-adjacent reproducibility repos: simple design, ordered scripts, explicit outputs, and sensitivity-ready summaries.

## Data source

Public CMS Medicare Physician & Other Practitioners by Provider and Service files.

- Dataset family: https://data.cms.gov/provider-summary-by-type-of-service/medicare-physician-other-practitioners/medicare-physician-other-practitioners-by-provider-and-service
- Methodology: https://data.cms.gov/sites/default/files/2025-04/MUP_PHY_RY25_202350312_Methodology_508.pdf
- Data dictionary: https://data.cms.gov/sites/default/files/2025-03/bbb1e50e-5ba8-42ed-b072-18368b6f37f9/MUP_PHY_RY25_20250312_DD_PRV_SVC_508.pdf

These files describe Original Medicare Part B fee-for-service claims. They do not represent Medicare Advantage or the full US surgical population.

## Repository layout

```text
config/
data_raw/
  cms/
docs/
output/
R/
scripts/
```

## Procedure codes

- `57280`: open abdominal sacrocolpopexy / abdominal colpopexy
- `57425`: minimally invasive sacrocolpopexy / laparoscopic colpopexy

The current implementation treats these as the core comparison. If you later decide to include robotic coding proxies or related prolapse procedures, extend the code list explicitly and state the change in the abstract.

## Quick start

1. Download annual CMS provider-service CSV files and place them under `data_raw/cms/`.
2. Edit [`config/cms_files.csv`](/Users/tylermuffly/cost_lefort/config/cms_files.csv) with the file paths you downloaded.
3. Install required R packages:

```r
install.packages(c(
  "readr", "dplyr", "tidyr", "ggplot2", "scales", "fs", "purrr", "tidyselect"
))
```

4. Run the analysis:

```sh
Rscript scripts/02_run_sacrocolpopexy_analysis.R
```

5. Review outputs in `output/`:

- `national_trend.csv`
- `state_trend.csv`
- `provider_type_trend.csv`
- `latest_state_open_share.csv`
- `national_services.png`
- `service_share.png`
- `results_blurb.txt`

## Main output

The repository produces a clean abstract-ready result sentence based on the first and last observed years:

> From YEAR1 to YEAR2, the share of sacrocolpopexy services coded as open abdominal decreased from X% to Y% in the CMS provider-service files.

That is the right level of claim for this dataset.

## Limits you should state explicitly

- Medicare fee-for-service only
- Aggregated provider-service data, not patient-level claims
- Descriptive utilization patterns, not route-selection causality
- Procedure coding may not fully capture operative complexity or case-mix

## Transferable repo patterns

The short review is in [`docs/repo_review.md`](/Users/tylermuffly/cost_lefort/docs/repo_review.md). The useful patterns were:

- pipeline-first structure
- deterministic ordered scripts
- simple models and summaries
- strong tables and figures rather than clever methods
- explicit sensitivity-analysis hooks
