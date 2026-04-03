required_packages <- c("readr", "dplyr", "tidyr", "ggplot2", "scales", "fs", "purrr", "tidyselect")
missing_packages <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]

if (length(missing_packages) > 0) {
  stop("Install required packages first: ", paste(missing_packages, collapse = ", "))
}

source("R/cms_sacrocolpopexy.R")

config_tbl <- read_cms_file_config("config/cms_files.csv")
panel <- build_sacrocolpopexy_panel(config_tbl)
national_trend <- summarize_national_trend(panel)
state_trend <- summarize_state_trend(panel)
provider_type_trend <- summarize_provider_type_trend(panel)
latest_state_open_share <- summarize_latest_state_open_share(state_trend)

write_analysis_outputs(
  national_trend = national_trend,
  state_trend = state_trend,
  provider_type_trend = provider_type_trend,
  latest_state_open_share = latest_state_open_share,
  output_dir = "output"
)

message(build_results_blurb(national_trend))
