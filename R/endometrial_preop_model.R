read_parameter_table <- function(path = "data_raw/model_inputs/parameters.csv") {
  params <- readr::read_csv(path, show_col_types = FALSE)
  if (!all(c("parameter", "value") %in% names(params))) {
    stop("Parameter file must contain 'parameter' and 'value' columns.")
  }
  stats::setNames(params$value, params$parameter)
}

read_strategy_table <- function(path = "data_raw/model_inputs/strategies.csv") {
  readr::read_csv(path, show_col_types = FALSE)
}

lookup_param <- function(param_name, params) {
  value <- unname(params[[param_name]])
  if (length(value) == 0 || is.na(value)) {
    stop("Missing parameter value for: ", param_name)
  }
  as.numeric(value)
}

resolve_strategy_values <- function(strategy_row, params) {
  dplyr::tibble(
    strategy = strategy_row$strategy,
    uses_test = strategy_row$uses_test,
    selective_if_bleeding = strategy_row$selective_if_bleeding,
    test_name = strategy_row$test_name,
    test_cost = if (strategy_row$uses_test) lookup_param(strategy_row$test_cost, params) else 0,
    test_sensitivity = if (strategy_row$uses_test) lookup_param(strategy_row$test_sensitivity, params) else 0,
    test_specificity = if (strategy_row$uses_test) lookup_param(strategy_row$test_specificity, params) else 1,
    minor_complication_prob = if (strategy_row$uses_test) lookup_param(strategy_row$minor_complication_prob, params) else 0,
    major_complication_prob = if (strategy_row$uses_test) lookup_param(strategy_row$major_complication_prob, params) else 0
  )
}

evaluate_strategy <- function(strategy_row, params) {
  prevalence_cancer <- lookup_param("prevalence_endometrial_cancer", params)
  prevalence_bleeding <- lookup_param("prevalence_postmenopausal_bleeding", params)
  prob_bleeding_given_cancer <- lookup_param("prob_bleeding_given_cancer", params)
  cost_false_positive_workup <- lookup_param("cost_false_positive_workup", params)
  cost_missed_cancer <- lookup_param("cost_cancer_missed", params)
  cost_complication_minor <- lookup_param("cost_complication_minor", params)
  cost_complication_major <- lookup_param("cost_complication_major", params)

  strategy_values <- resolve_strategy_values(strategy_row, params)

  cancer_with_bleeding <- prevalence_cancer * prob_bleeding_given_cancer
  cancer_without_bleeding <- prevalence_cancer - cancer_with_bleeding
  noncancer_with_bleeding <- max(prevalence_bleeding - cancer_with_bleeding, 0)
  noncancer_without_bleeding <- (1 - prevalence_cancer) - noncancer_with_bleeding

  if (strategy_values$selective_if_bleeding) {
    test_rate <- prevalence_bleeding
    true_positive <- cancer_with_bleeding * strategy_values$test_sensitivity
    false_negative <- cancer_without_bleeding + (cancer_with_bleeding * (1 - strategy_values$test_sensitivity))
    false_positive <- noncancer_with_bleeding * (1 - strategy_values$test_specificity)
  } else if (strategy_values$uses_test) {
    test_rate <- 1
    true_positive <- prevalence_cancer * strategy_values$test_sensitivity
    false_negative <- prevalence_cancer - true_positive
    false_positive <- (1 - prevalence_cancer) * (1 - strategy_values$test_specificity)
  } else {
    test_rate <- 0
    true_positive <- 0
    false_negative <- prevalence_cancer
    false_positive <- 0
  }

  true_negative <- (1 - prevalence_cancer) - false_positive
  invasive_workups <- false_positive
  minor_complications <- test_rate * strategy_values$minor_complication_prob
  major_complications <- test_rate * strategy_values$major_complication_prob

  expected_cost <- (test_rate * strategy_values$test_cost) +
    (false_positive * cost_false_positive_workup) +
    (false_negative * cost_missed_cancer) +
    (minor_complications * cost_complication_minor) +
    (major_complications * cost_complication_major)

  dplyr::tibble(
    strategy = strategy_values$strategy,
    test_rate = test_rate,
    expected_cost = expected_cost,
    cancers_detected = true_positive,
    cancers_missed = false_negative,
    false_positive_workups = invasive_workups,
    false_positive_rate = false_positive,
    true_negative_rate = true_negative,
    expected_minor_complications = minor_complications,
    expected_major_complications = major_complications
  )
}

run_base_case <- function(
  parameter_path = "data_raw/model_inputs/parameters.csv",
  strategy_path = "data_raw/model_inputs/strategies.csv"
) {
  params <- read_parameter_table(parameter_path)
  strategies <- read_strategy_table(strategy_path)

  base_results <- purrr::map_dfr(
    seq_len(nrow(strategies)),
    \(idx) evaluate_strategy(strategies[idx, , drop = FALSE], params)
  ) |>
    dplyr::arrange(.data$expected_cost)

  base_results
}

calculate_incremental_results <- function(results_tbl) {
  ordered <- results_tbl |>
    dplyr::arrange(.data$expected_cost, dplyr::desc(.data$cancers_detected)) |>
    dplyr::mutate(
      incremental_cost = .data$expected_cost - dplyr::lag(.data$expected_cost),
      incremental_cancers_detected = .data$cancers_detected - dplyr::lag(.data$cancers_detected),
      icer_cost_per_cancer_detected = dplyr::if_else(
        is.na(.data$incremental_cost) | is.na(.data$incremental_cancers_detected) | .data$incremental_cancers_detected <= 0,
        NA_real_,
        .data$incremental_cost / .data$incremental_cancers_detected
      )
    )

  frontier <- ordered |>
    dplyr::filter(cummax(.data$cancers_detected) == .data$cancers_detected)

  list(all_results = ordered, frontier = frontier)
}

plot_base_case <- function(results_tbl) {
  ggplot2::ggplot(
    results_tbl,
    ggplot2::aes(x = .data$cancers_detected * 1000, y = .data$expected_cost, label = .data$strategy)
  ) +
    ggplot2::geom_point(size = 3) +
    ggplot2::geom_text(vjust = -0.8, size = 3.5) +
    ggplot2::labs(
      title = "Base-case decision analysis",
      x = "Cancers detected per 1,000 patients",
      y = "Expected cost per patient (USD)"
    ) +
    ggplot2::theme_minimal()
}

build_summary_text <- function(results_tbl) {
  best_detection <- results_tbl |>
    dplyr::arrange(dplyr::desc(.data$cancers_detected), .data$expected_cost) |>
    dplyr::slice(1)

  lowest_cost <- results_tbl |>
    dplyr::arrange(.data$expected_cost, dplyr::desc(.data$cancers_detected)) |>
    dplyr::slice(1)

  paste0(
    "Lowest expected cost strategy: ", lowest_cost$strategy,
    " ($", round(lowest_cost$expected_cost, 2), " per patient). ",
    "Highest cancer detection strategy: ", best_detection$strategy,
    " (", round(best_detection$cancers_detected * 1000, 2), " cancers detected per 1,000 patients)."
  )
}

run_one_way_sensitivity <- function(
  parameter_names = c(
    "prevalence_endometrial_cancer",
    "cost_tvus",
    "cost_emb",
    "cost_hsc_dnc",
    "sens_tvus",
    "sens_emb",
    "sens_hsc_dnc",
    "prevalence_postmenopausal_bleeding"
  ),
  parameter_path = "data_raw/model_inputs/parameters.csv",
  strategy_path = "data_raw/model_inputs/strategies.csv"
) {
  params_tbl <- readr::read_csv(parameter_path, show_col_types = FALSE)
  strategies <- read_strategy_table(strategy_path)

  sensitivity_results <- purrr::map_dfr(parameter_names, function(param_name) {
    param_row <- params_tbl |>
      dplyr::filter(.data$parameter == param_name)

    if (nrow(param_row) != 1) {
      stop("Expected exactly one row for parameter: ", param_name)
    }

    scenarios <- dplyr::bind_rows(
      dplyr::mutate(param_row, scenario = "low", value = .data$lower),
      dplyr::mutate(param_row, scenario = "base", value = .data$value),
      dplyr::mutate(param_row, scenario = "high", value = .data$upper)
    )

    purrr::map_dfr(seq_len(nrow(scenarios)), function(i) {
      tmp_tbl <- params_tbl
      tmp_tbl$value[tmp_tbl$parameter == param_name] <- scenarios$value[i]
      tmp_params <- stats::setNames(tmp_tbl$value, tmp_tbl$parameter)

      results <- purrr::map_dfr(
        seq_len(nrow(strategies)),
        \(idx) evaluate_strategy(strategies[idx, , drop = FALSE], tmp_params)
      )

      best <- results |>
        dplyr::arrange(.data$expected_cost) |>
        dplyr::slice(1)

      dplyr::mutate(
        results,
        varied_parameter = param_name,
        sensitivity_scenario = scenarios$scenario[i],
        varied_value = scenarios$value[i],
        lowest_cost_strategy = best$strategy
      )
    })
  })

  sensitivity_results
}

plot_one_way_sensitivity <- function(sensitivity_results) {
  plot_tbl <- sensitivity_results |>
    dplyr::group_by(.data$varied_parameter, .data$sensitivity_scenario) |>
    dplyr::arrange(.data$expected_cost, .by_group = TRUE) |>
    dplyr::slice(1) |>
    dplyr::ungroup()

  ggplot2::ggplot(
    plot_tbl,
    ggplot2::aes(
      x = .data$varied_parameter,
      y = .data$expected_cost,
      color = .data$sensitivity_scenario
    )
  ) +
    ggplot2::geom_point(size = 3, position = ggplot2::position_dodge(width = 0.4)) +
    ggplot2::coord_flip() +
    ggplot2::labs(
      title = "One-way sensitivity: lowest expected cost across scenarios",
      x = "Varied parameter",
      y = "Expected cost per patient (USD)",
      color = "Scenario"
    ) +
    ggplot2::theme_minimal()
}
