#' Create a publication-oriented table
#' @export
smf_publication_table <- function(result,
  component=c("metrics","predictions","diagnostics","audit","manifest","external_validation"),
  digits=3L, format=c("data.frame","markdown","csv","parquet"), file=NULL) {
  component <- match.arg(component); format <- match.arg(format); digits <- as.integer(digits)
  if (S7::S7_inherits(result, ExternalValidationResult)) {
    if (component != "external_validation" && component != "metrics") cli::cli_abort("ExternalValidationResult supports metric/external-validation tables.")
    x <- result@metrics
  } else {
    if (!S7::S7_inherits(result, ExperimentResult)) cli::cli_abort("{.arg result} must be an ExperimentResult or ExternalValidationResult.")
    x <- switch(component,
      metrics=result@metrics,
      predictions=data.frame(row_id=result@prediction@row_ids, truth=I(result@prediction@truth), estimate=I(result@prediction@estimate)),
      diagnostics=.smf_flat_table(result@diagnostics@checks),
      audit=data.frame(code=vapply(result@audit@quality_flags, function(z) z@code, character(1)),
                       severity=vapply(result@audit@quality_flags, function(z) z@severity, character(1)),
                       message=vapply(result@audit@quality_flags, function(z) z@message, character(1))),
      manifest=.smf_flat_table(smf_to_list(result@manifest)),
      external_validation=cli::cli_abort("Use an ExternalValidationResult for component='external_validation'."))
  }
  if (!is.data.frame(x)) x <- as.data.frame(x)
  num <- vapply(x,is.numeric,logical(1)); x[num] <- lapply(x[num], round, digits=digits)
  if (format=="data.frame") return(x)
  if (format=="markdown") {
    if (!requireNamespace("knitr",quietly=TRUE)) return(paste(capture.output(print(x,row.names=FALSE)),collapse="\n"))
    return(knitr::kable(x,format="pipe",digits=digits))
  }
  if (is.null(file)) cli::cli_abort("{.arg file} is required for CSV/Parquet export.")
  if (format=="csv") utils::write.csv(x,file,row.names=FALSE,na="") else {
    if (!requireNamespace("arrow",quietly=TRUE)) cli::cli_abort("Package {.pkg arrow} is required for Parquet export.")
    arrow::write_parquet(x,file)
  }
  normalizePath(file,mustWork=TRUE)
}

.smf_flat_table <- function(x) {
  if (is.null(x)) return(data.frame())
  if (!is.list(x)) return(data.frame(name="value",value=as.character(x)))
  vals <- vapply(x, function(z) paste(capture.output(str(z,give.attr=FALSE)),collapse=" "), character(1))
  data.frame(name=names(vals), value=unname(vals), row.names=NULL)
}

#' Create a publication-oriented plot while retaining observed data where appropriate
#' @export
smf_publication_plot <- function(result, type=c("observed_predicted","residuals","calibration"), show_data=TRUE) {
  type <- match.arg(type)
  if (!S7::S7_inherits(result, ExperimentResult)) cli::cli_abort("{.arg result} must be an ExperimentResult.")
  p <- smf_plot(result,type=type)
  attr(p,"smf_show_observed_data") <- isTRUE(show_data)
  p
}

#' Minimum scientific reporting checklist
#' @export
smf_reporting_checklist <- function(result, external_validation=NULL) {
  if (!S7::S7_inherits(result, ExperimentResult)) cli::cli_abort("{.arg result} must be an ExperimentResult.")
  has_external <- !is.null(external_validation) && S7::S7_inherits(external_validation, ExternalValidationResult)
  data.frame(
    item=c("scientific question/task","experimental or sampling design","data audit and leakage safeguards",
      "resampling and final assessment separation","preprocessing/feature provenance","model/backend and hyperparameters",
      "performance with uncertainty","diagnostics","calibration or conformal assumptions where used","explanation limitations",
      "external validation or explicit absence","reproducibility manifest","software versions and seeds","limits on extrapolation"),
    status=c("required","required","required","required","required","required","required","required","conditional","conditional",
      if(has_external) "available" else "report absence", "available","available","required"),
    evidence=c(result@spec@task@kind,"DesignSpec","DataAuditResult","SplitRecord/ResampleCollection","FitResult state",
      paste(result@spec@model@engine,result@spec@model@family),"metrics/uncertainty","DiagnosticResult","typed calibration/conformal state",
      "causal_interpretation=FALSE",if(has_external) external_validation@domain_name else "none supplied","RunManifest","RunManifest","discussion"),
    row.names=NULL)
}

#' Create a scientific report artifact
#' @export
smf_report <- function(result, spec=NULL, external_validation=NULL, file=NULL, title="sciModelFlowR scientific analysis", format=c("object","markdown","quarto","html","pdf","docx","latex")) {
  format <- match.arg(format)
  if(!S7::S7_inherits(result,ExperimentResult)) cli::cli_abort("{.arg result} must be an ExperimentResult.")
  if (is.null(spec)) spec <- result@spec
  obj <- list(scientific_target=spec@task@target,task=spec@task@kind,
    design=smf_to_list(result@spec@design),audit_flags=lapply(result@audit@quality_flags,smf_to_list),
    split=smf_split_manifest(result@split),metrics=result@metrics,
    calibration=if(is.null(result@prediction@calibration))NULL else smf_to_list(result@prediction@calibration),
    diagnostics=smf_to_list(result@diagnostics),
    external_validation=if(is.null(external_validation))NULL else list(domain=external_validation@domain_name,metrics=external_validation@metrics,diagnostics=external_validation@diagnostics),
    reporting_checklist=smf_reporting_checklist(result,external_validation),
    reproducibility=smf_to_list(result@manifest),
    limitations=c("Predictive performance does not by itself establish causal effects.","External validity must be supported by a protected external domain or reported as absent.","Optional backends are not release-certified until the consolidated local validation campaign passes."))
  if(format=="object") return(obj)
  if(is.null(file)) file <- tempfile(fileext=switch(format,markdown=".md",quarto=".qmd",html=".html",pdf=".pdf",docx=".docx",latex=".tex"))
  md <- c(paste0("# ",title),"",paste0("**Task:** ",obj$task),paste0("**Target:** ",paste(obj$scientific_target,collapse=", ")),"","## Performance","",smf_publication_table(result,"metrics",format="markdown"),"","## Reporting checklist","", if(requireNamespace("knitr",quietly=TRUE)) knitr::kable(obj$reporting_checklist,format="pipe") else paste(capture.output(print(obj$reporting_checklist,row.names=FALSE)),collapse="\n"),"","## Reproducibility","",paste0("Run ID: `",result@manifest@run_id,"`"),paste0("Spec hash: `",result@manifest@spec_hash,"`"),"","## Limitations",paste0("- ",obj$limitations))
  if(format %in% c("markdown","quarto")) {
    if(format=="quarto") md <- c("---",paste0("title: \"",gsub('"','\\\\"',title),"\""),"format: html","---","",md)
    writeLines(md,file,useBytes=TRUE); return(ReportingResult(format=format,path=normalizePath(file,mustWork=TRUE),content=obj,tables=list(metrics=result@metrics),figures=list(),checklist=obj$reporting_checklist,manifest=smf_to_list(result@manifest)))
  }
  if(!requireNamespace("quarto",quietly=TRUE)) cli::cli_abort("Package {.pkg quarto} is required to render HTML/PDF/DOCX/LaTeX reports.")
  qmd <- tempfile(fileext=".qmd"); writeLines(c("---",paste0("title: \"",gsub('"','\\\\"',title),"\""),paste0("format: ",switch(format,html="html",pdf="pdf",docx="docx",latex="latex")),"---","",md),qmd,useBytes=TRUE)
  out_dir <- dirname(file); dir.create(out_dir,recursive=TRUE,showWarnings=FALSE)
  quarto::quarto_render(qmd,output_format=switch(format,html="html",pdf="pdf",docx="docx",latex="latex"),output_file=basename(file),output_dir=out_dir,quiet=TRUE)
  ReportingResult(format=format,path=normalizePath(file,mustWork=TRUE),content=obj,tables=list(metrics=result@metrics),figures=list(),checklist=obj$reporting_checklist,manifest=smf_to_list(result@manifest))
}
