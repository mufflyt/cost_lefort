# cost_lefort

Reproducible decision-model scaffold for:

**Cost analysis of preoperative endometrial cancer evaluation before Le Fort colpocleisis**

This repository now focuses on a fast, abstract-ready comparison of preoperative testing strategies before obliterative prolapse surgery.

Core strategies in the current model:

- no routine endometrial evaluation
- transvaginal ultrasound (`TVUS`)
- office endometrial biopsy (`EMB`)
- hysteroscopy with dilation and curettage (`HSC_D&C`)
- selective evaluation based on postmenopausal bleeding risk

## Project design

This is a one-cycle decision tree rather than a full Markov model. That is the right first move for an abstract deadline because the question is short-horizon and strategy-focused:

- what does each testing strategy cost up front?
- how many cancers are detected before surgery?
- how many false positives and unnecessary invasive workups are generated?
- what is the incremental cost per additional cancer detected?

The structure is intentionally small and editable, following the best pattern from the JAMA-adjacent cost-effectiveness repositories: explicit parameter files, one model file, one run script, and easy sensitivity analysis.

## Repository layout

```text
data_raw/
  cms/
  model_inputs/
docs/
output/
R/
scripts/
```

## Inputs

The model is driven by two editable CSV files:

- [`parameters.csv`](/Users/tylermuffly/cost_lefort/data_raw/model_inputs/parameters.csv)
- [`strategies.csv`](/Users/tylermuffly/cost_lefort/data_raw/model_inputs/strategies.csv)

The defaults in `parameters.csv` are **illustrative placeholders** intended to make the model run end to end. They are not yet manuscript-grade literature estimates.

You should replace at least these before using results in an abstract:

- occult endometrial cancer prevalence before colpocleisis
- prevalence of postmenopausal bleeding in the target population
- sensitivity and specificity of `TVUS`, `EMB`, and `HSC_D&C`
- procedure complication probabilities
- CMS-based costs for each test and downstream workup
- optional utility decrements if you want cost-per-QALY rather than cost-per-cancer-detected

## Quick start

1. Install required R packages:

```r
install.packages(c(
  "readr", "dplyr", "tidyr", "ggplot2", "scales", "fs", "purrr"
))
```

2. Run the base-case analysis:

```sh
Rscript scripts/01_run_endometrial_model.R
```

3. Run one-way sensitivity analysis:

```sh
Rscript scripts/02_one_way_sensitivity.R
```

## Outputs

The main script writes:

- `base_case_results.csv`
- `base_case_results_long.csv`
- `efficiency_frontier.csv`
- `base_case_plot.png`
- `base_case_summary.txt`

The sensitivity script writes:

- `one_way_sensitivity_results.csv`
- `one_way_sensitivity_plot.png`

## Outcome measures

Current outputs include:

- expected cost per patient
- cancers detected before surgery
- cancers missed
- false-positive rate
- downstream invasive workups
- expected complications
- incremental cost-effectiveness ratio using cost per additional cancer detected

If you later want cost per QALY, the current model already has a slot for utility-style penalties and can be extended without changing the overall structure.

## Recommended next step

The fastest defensible version for the abstract is:

1. keep the strategies exactly as defined here
2. replace placeholder inputs with literature and CMS values
3. run one-way sensitivity on prevalence, test cost, and test performance
4. report cost, detection yield, and ICER per cancer detected

## Limits you should state explicitly

- decision tree with short horizon
- no patient-level claims
- default parameter file is a scaffold and requires source replacement
- route to diagnosis and surgical delay harms are simplified
- cost-per-cancer-detected is easier to defend quickly than cost-per-QALY unless utility inputs are strong
