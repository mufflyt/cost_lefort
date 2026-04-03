required_packages <- c("readr", "dplyr", "tidyr", "ggplot2", "scales", "fs", "purrr")
missing_packages <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]

if (length(missing_packages) > 0) {
  stop("Install required packages first: ", paste(missing_packages, collapse = ", "))
}

source("R/endometrial_preop_model.R")

fs::dir_create("output")

base_case <- run_base_case()
incremental <- calculate_incremental_results(base_case)
summary_text <- build_summary_text(incremental$all_results)

readr::write_csv(incremental$all_results, "output/base_case_results.csv")

base_case_long <- incremental$all_results |>
  tidyr::pivot_longer(
    cols = c(
      "expected_cost",
      "cancers_detected",
      "cancers_missed",
      "false_positive_workups",
      "expected_minor_complications",
      "expected_major_complications"
    ),
    names_to = "metric",
    values_to = "value"
  )

readr::write_csv(base_case_long, "output/base_case_results_long.csv")
readr::write_csv(incremental$frontier, "output/efficiency_frontier.csv")
readr::write_lines(summary_text, "output/base_case_summary.txt")

ggplot2::ggsave(
  filename = "output/base_case_plot.png",
  plot = plot_base_case(incremental$all_results),
  width = 10,
  height = 6,
  dpi = 300
)

message(summary_text)
