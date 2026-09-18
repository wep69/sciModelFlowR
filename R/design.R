#' Validate a scientific design declaration
#' @export
smf_validate_design <- function(data, design, resampling=NULL) {
  cols <- unique(c(design@id_column, design@group_columns, design@block_columns, design@repeated_unit, design@time_column, design@coordinate_columns, design@external_domain_column, design@experimental_unit))
  .smf_abort_missing_columns(data, cols, "DesignSpec")
  warnings <- list()
  if (length(design@repeated_unit)) {
    tab <- table(data[[design@repeated_unit]])
    if (all(tab==1L)) warnings[[length(warnings)+1L]] <- smf_warning_record("REPEATED_UNIT_SINGLETON", "The declared repeated unit appears only once per unit.", "warning", evidence=list(variable=design@repeated_unit), suggested_action="Verify whether repeated_unit is the correct identifier.")
    if (!is.null(resampling) && resampling@method %in% c("holdout","stratified_holdout")) warnings[[length(warnings)+1L]] <- smf_warning_record("PSEUDOREPLICATION_RISK_RANDOM_SPLIT", "A random row-level split was requested for data with a declared repeated unit.", "high", evidence=list(repeated_unit=design@repeated_unit, method=resampling@method), suggested_action="Use group-aware resampling when it becomes available, or supply an externally grouped split manifest.")
  }
  if (length(design@time_column) && !inherits(data[[design@time_column]], c("Date","POSIXt")) && !is.numeric(data[[design@time_column]])) warnings[[length(warnings)+1L]] <- smf_warning_record("TIME_COLUMN_NONORDERED", "The declared time column is not numeric or a date/time class.", "high", evidence=list(variable=design@time_column), suggested_action="Encode time on an ordered scale before temporal validation.")
  if (length(design@coordinate_columns)) {
    bad <- !vapply(data[design@coordinate_columns], is.numeric, logical(1))
    if (any(bad)) .smf_abort("COORDINATES_NONNUMERIC", "Spatial coordinate columns must be numeric.", evidence=list(columns=design@coordinate_columns[bad]))
  }
  if (length(design@hierarchy)) {
    edges <- do.call(rbind, lapply(design@hierarchy, function(x) as.character(x)[1:2]))
    if (!is.null(edges) && nrow(edges)) {
      if (any(edges[,1]==edges[,2])) .smf_abort("HIERARCHY_SELF_EDGE", "Hierarchy cannot contain a self relationship.")
    }
  }
  warnings
}

#' Summarize the declared scientific design
#' @export
smf_design_summary <- function(data, design) {
  warnings <- smf_validate_design(data, design)
  counts <- function(cols) lapply(cols, function(nm) length(unique(data[[nm]])))
  list(id_column=design@id_column, group_columns=setNames(counts(design@group_columns), design@group_columns), block_columns=setNames(counts(design@block_columns), design@block_columns), repeated_unit=design@repeated_unit, time_column=design@time_column, coordinate_columns=design@coordinate_columns, external_domain_column=design@external_domain_column, experimental_unit=design@experimental_unit, warnings=warnings)
}

#' Screen a design for obvious pseudoreplication risk
#' @export
smf_check_pseudoreplication <- function(data, design, treatment=character()) {
  if (!length(design@experimental_unit) && !length(design@repeated_unit) && !length(design@group_columns)) return(list(status="unknown", warnings=list(smf_warning_record("EXPERIMENTAL_UNIT_UNDECLARED", "No experimental/repeated/group unit was declared.", "high", suggested_action="Declare the unit that was independently randomized or sampled."))))
  unit <- if (length(design@experimental_unit)) design@experimental_unit else if (length(design@repeated_unit)) design@repeated_unit else design@group_columns[[1]]
  .smf_abort_missing_columns(data, c(unit,treatment), "pseudoreplication screen")
  list(status="screened", unit=unit, n_units=length(unique(data[[unit]])), treatment=treatment)
}
