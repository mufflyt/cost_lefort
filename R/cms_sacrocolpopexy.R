required_cms_columns <- c(
  "Rndrng_NPI",
  "Rndrng_Prvdr_State_Abrvtn",
  "Rndrng_Prvdr_Type",
  "HCPCS_Cd",
  "HCPCS_Desc",
  "Place_Of_Srvc",
  "Tot_Benes",
  "Tot_Srvcs",
  "Tot_Bene_Day_Srvcs",
  "Avg_Sbmtd_Chrg",
  "Avg_Mdcr_Alowd_Amt",
  "Avg_Mdcr_Pymt_Amt",
  "Avg_Mdcr_Stdzd_Amt"
)

sacrocolpopexy_code_map <- c(
  "57280" = "Open abdominal",
  "57425" = "Minimally invasive"
)

read_cms_provider_service <- function(path, study_year, hcpcs_codes = names(sacrocolpopexy_code_map)) {
  stopifnot(file.exists(path))

  panel <- readr::read_csv(
    file = path,
    col_select = tidyselect::any_of(required_cms_columns),
    show_col_types = FALSE,
    progress = FALSE
  )

  panel |>
    dplyr::mutate(
      study_year = as.integer(study_year),
      HCPCS_Cd = as.character(.data$HCPCS_Cd),
      HCPCS_Desc = as.character(.data$HCPCS_Desc),
      Rndrng_Prvdr_Type = as.character(.data$Rndrng_Prvdr_Type),
      Rndrng_Prvdr_State_Abrvtn = as.character(.data$Rndrng_Prvdr_State_Abrvtn),
      Place_Of_Srvc = as.character(.data$Place_Of_Srvc),
      Tot_Benes = suppressWarnings(as.numeric(.data$Tot_Benes)),
      Tot_Srvcs = suppressWarnings(as.numeric(.data$Tot_Srvcs)),
      Tot_Bene_Day_Srvcs = suppressWarnings(as.numeric(.data$Tot_Bene_Day_Srvcs)),
      Avg_Sbmtd_Chrg = suppressWarnings(as.numeric(.data$Avg_Sbmtd_Chrg)),
      Avg_Mdcr_Alowd_Amt = suppressWarnings(as.numeric(.data$Avg_Mdcr_Alowd_Amt)),
      Avg_Mdcr_Pymt_Amt = suppressWarnings(as.numeric(.data$Avg_Mdcr_Pymt_Amt)),
      Avg_Mdcr_Stdzd_Amt = suppressWarnings(as.numeric(.data$Avg_Mdcr_Stdzd_Amt))
    ) |>
    dplyr::filter(.data$HCPCS_Cd %in% hcpcs_codes) |>
    dplyr::mutate(
      surgical_approach = dplyr::recode(.data$HCPCS_Cd, !!!sacrocolpopexy_code_map)
    )
}

read_cms_file_config <- function(path = "config/cms_files.csv") {
  config <- readr::read_csv(path, show_col_types = FALSE)

  if (!all(c("year", "file_path") %in% names(config))) {
    stop("config/cms_files.csv must contain columns named 'year' and 'file_path'.")
  }

  config |>
    dplyr::mutate(
      year = as.integer(.data$year),
      file_path = fs::path_expand(.data$file_path)
    )
}

build_sacrocolpopexy_panel <- function(config_tbl, hcpcs_codes = names(sacrocolpopexy_code_map)) {
  purrr::map2_dfr(
    .x = config_tbl$file_path,
    .y = config_tbl$year,
    .f = \(path, year) read_cms_provider_service(path, year, hcpcs_codes = hcpcs_codes)
  )
}

summarize_national_trend <- function(panel) {
  panel |>
    dplyr::group_by(.data$study_year, .data$surgical_approach) |>
    dplyr::summarise(
      provider_lines = dplyr::n(),
      provider_npi_count = dplyr::n_distinct(.data$Rndrng_NPI),
      medicare_beneficiaries = sum(.data$Tot_Benes, na.rm = TRUE),
      services = sum(.data$Tot_Srvcs, na.rm = TRUE),
      bene_day_services = sum(.data$Tot_Bene_Day_Srvcs, na.rm = TRUE),
      mean_std_payment = mean(.data$Avg_Mdcr_Stdzd_Amt, na.rm = TRUE),
      median_std_payment = stats::median(.data$Avg_Mdcr_Stdzd_Amt, na.rm = TRUE),
      .groups = "drop"
    ) |>
    tidyr::complete(
      .data$study_year,
      .data$surgical_approach,
      fill = list(
        provider_lines = 0,
        provider_npi_count = 0,
        medicare_beneficiaries = 0,
        services = 0,
        bene_day_services = 0,
        mean_std_payment = NA_real_,
        median_std_payment = NA_real_
      )
    ) |>
    dplyr::group_by(.data$study_year) |>
    dplyr::mutate(
      yearly_services_total = sum(.data$services, na.rm = TRUE),
      yearly_beneficiary_total = sum(.data$medicare_beneficiaries, na.rm = TRUE),
      service_share = dplyr::if_else(.data$yearly_services_total > 0, .data$services / .data$yearly_services_total, NA_real_),
      beneficiary_share = dplyr::if_else(.data$yearly_beneficiary_total > 0, .data$medicare_beneficiaries / .data$yearly_beneficiary_total, NA_real_)
    ) |>
    dplyr::ungroup() |>
    dplyr::arrange(.data$study_year, .data$surgical_approach)
}

summarize_state_trend <- function(panel) {
  panel |>
    dplyr::group_by(.data$study_year, .data$Rndrng_Prvdr_State_Abrvtn, .data$surgical_approach) |>
    dplyr::summarise(
      provider_npi_count = dplyr::n_distinct(.data$Rndrng_NPI),
      medicare_beneficiaries = sum(.data$Tot_Benes, na.rm = TRUE),
      services = sum(.data$Tot_Srvcs, na.rm = TRUE),
      bene_day_services = sum(.data$Tot_Bene_Day_Srvcs, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::arrange(.data$study_year, .data$Rndrng_Prvdr_State_Abrvtn, .data$surgical_approach)
}

summarize_provider_type_trend <- function(panel) {
  panel |>
    dplyr::group_by(.data$study_year, .data$Rndrng_Prvdr_Type, .data$surgical_approach) |>
    dplyr::summarise(
      provider_npi_count = dplyr::n_distinct(.data$Rndrng_NPI),
      medicare_beneficiaries = sum(.data$Tot_Benes, na.rm = TRUE),
      services = sum(.data$Tot_Srvcs, na.rm = TRUE),
      bene_day_services = sum(.data$Tot_Bene_Day_Srvcs, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::arrange(.data$study_year, .data$Rndrng_Prvdr_Type, .data$surgical_approach)
}

summarize_latest_state_open_share <- function(state_trend) {
  latest_year <- max(state_trend$study_year, na.rm = TRUE)

  state_trend |>
    dplyr::filter(.data$study_year == latest_year) |>
    dplyr::select(.data$Rndrng_Prvdr_State_Abrvtn, .data$surgical_approach, .data$services) |>
    tidyr::pivot_wider(
      names_from = .data$surgical_approach,
      values_from = .data$services,
      values_fill = 0
    ) |>
    dplyr::mutate(
      total_services = .data$`Open abdominal` + .data$`Minimally invasive`,
      open_service_share = dplyr::if_else(.data$total_services > 0, .data$`Open abdominal` / .data$total_services, NA_real_)
    ) |>
    dplyr::arrange(dplyr::desc(.data$open_service_share))
}

plot_national_services <- function(national_trend) {
  ggplot2::ggplot(
    national_trend,
    ggplot2::aes(x = .data$study_year, y = .data$services, color = .data$surgical_approach)
  ) +
    ggplot2::geom_line(linewidth = 1) +
    ggplot2::geom_point(size = 2) +
    ggplot2::scale_x_continuous(breaks = sort(unique(national_trend$study_year))) +
    ggplot2::labs(
      title = "Open vs minimally invasive sacrocolpopexy services",
      x = "Year",
      y = "Services",
      color = "Approach"
    ) +
    ggplot2::theme_minimal()
}

plot_service_share <- function(national_trend) {
  ggplot2::ggplot(
    national_trend,
    ggplot2::aes(x = .data$study_year, y = .data$service_share, color = .data$surgical_approach)
  ) +
    ggplot2::geom_line(linewidth = 1) +
    ggplot2::geom_point(size = 2) +
    ggplot2::scale_x_continuous(breaks = sort(unique(national_trend$study_year))) +
    ggplot2::scale_y_continuous(labels = scales::percent_format()) +
    ggplot2::labs(
      title = "Share of sacrocolpopexy services by approach",
      x = "Year",
      y = "Service share",
      color = "Approach"
    ) +
    ggplot2::theme_minimal()
}

build_results_blurb <- function(national_trend) {
  summary_tbl <- national_trend |>
    dplyr::select(.data$study_year, .data$surgical_approach, .data$services) |>
    tidyr::pivot_wider(
      names_from = .data$surgical_approach,
      values_from = .data$services,
      values_fill = 0
    ) |>
    dplyr::mutate(
      open_share = .data$`Open abdominal` / (.data$`Open abdominal` + .data$`Minimally invasive`)
    ) |>
    dplyr::arrange(.data$study_year)

  first_year <- min(summary_tbl$study_year, na.rm = TRUE)
  last_year <- max(summary_tbl$study_year, na.rm = TRUE)
  first_share <- summary_tbl$open_share[summary_tbl$study_year == first_year][1]
  last_share <- summary_tbl$open_share[summary_tbl$study_year == last_year][1]
  direction <- if (last_share < first_share) "decreased" else "increased"

  paste0(
    "From ", first_year, " to ", last_year,
    ", the share of sacrocolpopexy services coded as open abdominal ",
    direction, " from ",
    scales::percent(first_share, accuracy = 0.1),
    " to ",
    scales::percent(last_share, accuracy = 0.1),
    " in the CMS provider-service files."
  )
}

write_analysis_outputs <- function(
  national_trend,
  state_trend,
  provider_type_trend,
  latest_state_open_share,
  output_dir = "output"
) {
  fs::dir_create(output_dir)

  readr::write_csv(national_trend, fs::path(output_dir, "national_trend.csv"))
  readr::write_csv(state_trend, fs::path(output_dir, "state_trend.csv"))
  readr::write_csv(provider_type_trend, fs::path(output_dir, "provider_type_trend.csv"))
  readr::write_csv(latest_state_open_share, fs::path(output_dir, "latest_state_open_share.csv"))

  ggplot2::ggsave(
    filename = fs::path(output_dir, "national_services.png"),
    plot = plot_national_services(national_trend),
    width = 10,
    height = 6,
    dpi = 300
  )

  ggplot2::ggsave(
    filename = fs::path(output_dir, "service_share.png"),
    plot = plot_service_share(national_trend),
    width = 10,
    height = 6,
    dpi = 300
  )

  readr::write_lines(build_results_blurb(national_trend), fs::path(output_dir, "results_blurb.txt"))
}
