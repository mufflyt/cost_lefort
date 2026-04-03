required_packages <- c("readr", "dplyr", "tidyr", "ggplot2", "scales", "fs", "purrr")
missing_packages <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]

if (length(missing_packages) > 0) {
  stop("Install required packages first: ", paste(missing_packages, collapse = ", "))
}

source("R/endometrial_preop_model.R")

fs::dir_create("output")

sensitivity_results <- run_one_way_sensitivity()

readr::write_csv(sensitivity_results, "output/one_way_sensitivity_results.csv")

ggplot2::ggsave(
  filename = "output/one_way_sensitivity_plot.png",
  plot = plot_one_way_sensitivity(sensitivity_results),
  width = 10,
  height = 6,
  dpi = 300
)

message("One-way sensitivity analysis complete.")
