# Bulk retrieval of every sub-theme of a Data Dashboard theme.

# Sub-themes of the "infectious_disease" theme, as of this writing.
.infectious_disease_subthemes <- c(
  "antimicrobial_resistance",
  "bloodborne",
  "bloodstream_infection",
  "childhood_illness",
  "contact",
  "gastrointestinal",
  "invasive_bacterial_infections",
  "respiratory",
  "vaccine_preventable",
  "vector_borne"
)

# These sub-themes are only published for nations; everything else is
# published by UKHSA region.
.nation_subthemes <- c("contact", "vector_borne")

.default_geography_type <- function(sub_theme) {
  ifelse(sub_theme %in% .nation_subthemes, "Nation", "UKHSA Region")
}

# Work out the geography_type to use for each sub-theme.
.geography_types_for <- function(sub_themes, geography_type) {
  out <- .default_geography_type(sub_themes)
  names(out) <- sub_themes
  if (is.null(geography_type)) return(out)

  geo_names <- names(geography_type)
  geography_type <- as.character(geography_type)
  names(geography_type) <- geo_names
  if (is.null(geo_names)) {
    if (length(geography_type) != 1) {
      stop("'geography_type' must be NULL, a single value, or a named vector ",
           "with one element per sub-theme.", call. = FALSE)
    }
    out[] <- geography_type
  } else {
    unknown <- setdiff(names(geography_type), sub_themes)
    if (length(unknown) > 0) {
      stop("'geography_type' has names that are not in 'sub_themes': ",
           paste(unknown, collapse = ", "), call. = FALSE)
    }
    out[names(geography_type)] <- geography_type
  }
  out
}

#' Download every sub-theme of a UKHSA dashboard theme
#'
#' Runs \code{\link{get_data}} once per sub-theme (all topics, all
#' geographies and all metrics at one geography type) and optionally saves
#' each result to its own file. With the defaults it retrieves the ten
#' sub-themes of \code{infectious_disease} (antimicrobial resistance,
#' bloodborne, bloodstream infection, childhood illness, contact,
#' gastrointestinal, invasive bacterial infections, respiratory,
#' vaccine-preventable and vector-borne).
#'
#' This is a large download, issued at the rate set by
#' \code{options(ukhsadatR.requests_per_second = )} (default one request per
#' second), so it takes a long time. Preview a single sub-theme's size first
#' with \code{\link{get_combinations}}, and use \code{sub_themes} to fetch only
#' what you need. Sub-themes that fail to resolve or download are skipped with
#' a message, and the rest are still returned.
#'
#' @param sub_themes character vector of sub-themes. \code{NULL} (default)
#'   means the ten known \code{infectious_disease} sub-themes. Values
#'   containing \code{*} or \code{?} are expanded against the API, so
#'   \code{"*"} fetches every sub-theme the API lists for \code{theme}.
#' @param theme the theme, default \code{"infectious_disease"}.
#' @param topic,geography,metric passed to \code{\link{get_data}}; all default
#'   to \code{"*"} (everything).
#' @param geography_type the geography type to retrieve. \code{NULL} (default)
#'   uses \code{"Nation"} for the \code{contact} and \code{vector_borne}
#'   sub-themes, which are only published nationally, and \code{"UKHSA Region"}
#'   for everything else. Supply a single value to use for all sub-themes, or
#'   a named vector (e.g. \code{c(respiratory = "Nation")}) to override
#'   individual sub-themes.
#' @param out_dir optional directory. If supplied, each sub-theme is saved as
#'   \code{<out_dir>/<sub_theme>.<format>}.
#' @param format file format used when \code{out_dir} is supplied:
#'   \code{"csv"} (default), \code{"csv.gz"} or \code{"rds"}.
#' @param as_data_table if \code{TRUE}, return \code{data.table}s rather than
#'   \code{data.frame}s.
#' @param max_datasets passed to \code{\link{get_data}}; the per-sub-theme
#'   safety limit on the number of metric datasets. The default is generous
#'   because a whole sub-theme can contain thousands of datasets.
#' @param verbose show progress messages.
#'
#' @return A named list with one element per sub-theme: a data.frame (or
#'   data.table), or \code{NULL} if that sub-theme could not be retrieved.
#'   Returns \code{NULL} invisibly if \code{sub_themes} contained patterns
#'   that could not be resolved.
#'
#' @seealso \code{\link{get_data}}, \code{\link{get_combinations}}
#'
#' @export
#'
#' @examples
#' \donttest{
#' # Two sub-themes only, kept in memory
#' x <- get_subtheme_data(sub_themes = c("contact", "vector_borne"))
#' names(x)
#'
#' # The respiratory sub-theme by nation rather than region, saved to disk
#' get_subtheme_data(
#'   sub_themes = "respiratory",
#'   geography_type = "Nation",
#'   out_dir = file.path(tempdir(), "ukhsa")
#' )
#' }
get_subtheme_data <- function(sub_themes = NULL,
                              theme = "infectious_disease",
                              topic = "*",
                              geography_type = NULL,
                              geography = "*",
                              metric = "*",
                              out_dir = NULL,
                              format = c("csv", "csv.gz", "rds"),
                              as_data_table = FALSE,
                              max_datasets = 1e5,
                              verbose = TRUE) {
  format <- match.arg(format)
  if (!is.character(theme) || length(theme) != 1 || is.na(theme) ||
      !nzchar(theme) || .has_glob(theme)) {
    stop("'theme' must be a single exact theme name", call. = FALSE)
  }

  if (is.null(sub_themes)) {
    sub_themes <- .infectious_disease_subthemes
  } else {
    sub_themes <- .clean_spec(sub_themes)
    if (is.null(sub_themes)) stop("'sub_themes' contains no values", call. = FALSE)
    if (any(.has_glob(sub_themes))) {
      combos <- get_combinations(theme = theme, sub_theme = sub_themes, verbose = verbose)
      if (is.null(combos)) return(invisible(NULL))
      sub_themes <- unique(combos$sub_theme)
    }
  }

  geo_types <- .geography_types_for(sub_themes, geography_type)

  out <- stats::setNames(vector("list", length(sub_themes)), sub_themes)
  for (st in sub_themes) {
    if (verbose) {
      message(sprintf("== %s / %s (%s) ==", theme, st, geo_types[[st]]))
    }
    save_to <- if (is.null(out_dir)) NULL else file.path(out_dir, paste0(st, ".", format))
    res <- get_data(
      theme = theme, sub_theme = st, topic = topic,
      geography_type = geo_types[[st]], geography = geography, metric = metric,
      save_to = save_to, as_data_table = as_data_table,
      max_datasets = max_datasets, verbose = verbose
    )
    if (is.null(res)) {
      message(sprintf("! Skipping sub-theme '%s': nothing could be retrieved.", st))
    } else {
      out[[st]] <- res
    }
  }
  out
}
