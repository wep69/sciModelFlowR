# pkgdown build harness for sciModelFlowR 1.0.2 (documented workaround).
#
# pkgdown 2.2.1 + Quarto 1.11.0 on Windows: pkgdown:::quarto_render() passes an
# absolute --output-dir taken from tempdir(); the Quarto CLI joins it to the
# input directory, producing os error 123
# (stat 'D:\...\vignettes\C:\Users\...\pkgdown-quarto-<id>').
#
# Workaround (harness-only, no package file is affected):
#   1. TMPDIR/TMP/TEMP moved to a directory on the same drive as the project;
#   2. in-session patch of pkgdown:::quarto_render() that absolutizes the input
#      and passes --output-dir relative to it.
# See DERIVED_PATCH_NOTES.md item 21 and the 1.0.2 validation record.
#
# Usage: Rscript --vanilla tools/pkgdown_build_1.0.2.R
# (run from the repository root; .libPaths must resolve sciModelFlowR 1.0.2)

smf_tmp <- "D:/smf_tmp"
dir.create(smf_tmp, showWarnings = FALSE, recursive = TRUE)
Sys.setenv(TMPDIR = smf_tmp, TMP = smf_tmp, TEMP = smf_tmp)

patched_quarto_render <- function(pkg, path, quiet = TRUE, frame = rlang::caller_env()) {
  path <- normalizePath(path, winslash = "/", mustWork = TRUE)
  metadata_path <- withr::local_tempfile(fileext = ".yml", pattern = "pkgdown-quarto-metadata-")
  yaml::write_yaml(pkgdown:::quarto_format(pkg), metadata_path)
  output_dir <- withr::local_tempdir("pkgdown-quarto-", .local_envir = frame)
  out_rel <- as.character(fs::path_rel(output_dir, path))
  quarto::quarto_render(path, metadata_file = metadata_path,
                        quarto_args = c("--output-dir", out_rel),
                        quiet = quiet, as_job = FALSE)
  output_dir
}

assignInNamespace("quarto_render", patched_quarto_render, ns = "pkgdown")

pkgdown::build_site()
pkgdown:::build_sitemap()
cat("=== SITE 1.0.2 DONE ===\n")
