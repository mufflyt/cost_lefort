# Parameter sources

These values were used to replace the placeholder base-case inputs in `data_raw/model_inputs/parameters.csv`.

## Literature

- Occult malignant uterine pathology in prolapse surgery:
  - Frick et al. reported 2.6% unexpected abnormal uterine pathology in postmenopausal women without bleeding undergoing reconstructive prolapse surgery.
  - Ben-Baruch Golan et al. reported 0.14% occult endometrial carcinoma and 0.35% significant endometrial pathology in asymptomatic postmenopausal women undergoing vaginal hysterectomy for prolapse.
  - A more recent prolapse hysterectomy series reported 0.7% malignant uterine pathology and 3.2% significant premalignancy in postmenopausal women.
- Bleeding as a triage symptom:
  - NCI summary of Clarke et al. meta-analysis: about 90% of women with endometrial cancer had postmenopausal bleeding, and about 9% of women evaluated for PMB were diagnosed with endometrial cancer.
  - StatPearls: PMB is reported in up to 10% of postmenopausal women.
- Test performance:
  - Endometrial sampling meta-analysis: sensitivity about 90% and specificity 98% to 100% in women with PMB.
  - Hysteroscopy systematic review: sensitivity 86.4% and specificity 99.2% for endometrial cancer.
  - Recent PMB cohort using a 4 mm TVUS threshold: sensitivity 93.3% and specificity 24.7%; older PMB studies reported higher specificity, which is reflected in the sensitivity range.

## CMS-linked cost inputs

- CPT `76830` TVUS, CPT `58100` office endometrial biopsy, and CPT `58558` hysteroscopy with endometrial sampling were extracted from the 2025 CMS physician fee schedule carrier files.
- The model uses the mean non-facility amount across localities as a CMS-based national proxy.
- Missed-cancer downstream cost uses the Federal Register uterine cancer treatment table based on SEER-Medicare estimates:
  - initial year: `$39,638`
  - continuing annual care: `$2,066`
  - last year of life: `$118,058`

This is still a fast-turnaround abstract model. If you want manuscript-grade costing, the next refinement should link CPT `58558` to hospital outpatient or ASC facility payment rather than using the MPFS non-facility amount as a proxy.
