#' Check data format
#'
#'
#' This is a function to check the format of meta-analysis data with class \code{data.frame} for its further applicability to the \code{expandMultiarmTrials} function.
#'
#' @param data Meta-analysis data stored as a data.frame.
#' @param must.contain \code{character} vector, containing all the variable names the data set should contain.
#' @param variable.contains \code{list}, defining which values should only be contained in a variable.
#' @param variable.class \code{list}, defining the required data class for some or all variables. If the class differs, the function will try to convert the variable to the desired class.
#' @param groups.column.indicator \code{character}. If the dataset is in wide format: a character vector with two elements, representing the suffix used to
#' differentiate between the first and second treatment in a comparison.
#' @param data.format \code{character}. Either \code{"long"} or \code{"wide"}, depending on the format of the dataset in
#' \code{data}. \code{NULL} by default, which lets the user define the format after the function has been called.
#'
#' @usage checkDataFormat(data,
#'            must.contain = c("study", "condition",
#'                             "Cond_spec", "is.multiarm",
#'                             "no.arms", "multiple_arms",
#'                             "Outc_measure", "Time", "primary",
#'                             "Time_weeks", "sr_clinician"),
#'            variable.contains = list("condition" = c("ig", "cg"),
#'                                     "is.multiarm" = c(0,1)),
#'            variable.class = list("study" = "character",
#'                                  "condition" = "character",
#'                                  "Cond_spec" = "character",
#'                                  "is.multiarm" = "numeric",
#'                                  "no.arms" = "numeric",
#'                                  "multiple_arms" = "character",
#'                                  "primary" = "numeric",
#'                                  "Time" = "character",
#'                                  "Time_weeks" = "character",
#'                                  "sr_clinician" = "character",
#'                                  "Post_M" = "numeric",
#'                                  "Post_SD" = "numeric",
#'                                  "Post_N" = "numeric",
#'                                  "Rand_N" = "numeric",
#'                                  "Improved_N" = "numeric",
#'                                  "Change_m" = "numeric",
#'                                  "Change_SD" = "numeric",
#'                                  "Change_N" = "numeric"),
#'            groups.column.indicator = c("_trt1", "_trt2"),
#'            data.format = NULL)
#'
#' @return \code{checkDataFormat} returns messages that specify if input variables, values and classes of the variables are as defined.
#' @details The function ckecks if:
#'  \itemize{
#'  \item{the data set contains all relevant variables}
#'  \item{variables contain desired values only and}
#'  \item{variables are of desired type (if not, it tries to convert them).}
#'  }
#'  If the dataset format is wide, please specify all variable/column names
#'  \emph{without} the group indicator suffix (e.g. for \code{"Cond_spec_trt1"} and
#'  \code{"Cond_spec_trt2"}, simply use \code{"Cond_spec"}).
#'
#' @examples
#' \dontrun{
#' data("inpatients")
#'
#' # Example 1: Check data with default arguments
#' checkDataFormat(inpatients)
#'
#' #Example 2: Check for specified variables and corresponding values and classes
#' checkDataFormat(inpatients,
#'                 must.contain = c("study", "condition",
#'                                  "primary", "year"),
#'                 variable.contains = list("condition" = c("ig","cg")),
#'                 variable.class = list(study = "character",
#'                                       no.arms = "numeric"))
#'
#' #Example 3: Convert variable class as predefined
#' checkDataFormat(inpatients,
#'                 must.contain = c("primary", "study"),
#'                 variable.class = list(primary = "integer"))
#'
#' #Example 4: Wide format
#' data("psyCtrSubsetWide")
#' checkDataFormat(psyCtrSubsetWide)
#' }
#'
#'
#' @author Mathias Harrer \email{mathias.h.harrer@@gmail.com}, Paula Kuper \email{paula.r.kuper@@gmail.com}, Pim Cuijpers \email{p.cuijpers@@vu.nl}
#'
#' @seealso \code{\link{expandMultiarmTrials}}
#' @export checkDataFormat
#' @importFrom methods as
#' @importFrom stats dffits model.matrix rnorm rstudent
#' @importFrom utils combn
#' @importFrom stringr str_remove_all

checkDataFormat = function(data,
                           must.contain = c("study", "condition",
                                            "Cond_spec", "is.multiarm",
                                            "no.arms", "multiple_arms",
                                            "Outc_measure", "Time", "primary",
                                            "Time_weeks", "sr_clinician"),
                           variable.contains = list("condition" = c("ig", "cg"),
                                                    "is.multiarm" = c(0,1)),
                           variable.class = list("study" = "character",
                                                 "condition" = "character",
                                                 "Cond_spec" = "character",
                                                 "is.multiarm" = "numeric",
                                                 "no.arms" = "numeric",
                                                 "multiple_arms" = "character",
                                                 "primary" = "numeric",
                                                 "Time" = "character",
                                                 "Time_weeks" = "character",
                                                 "sr_clinician" = "character",
                                                 "Post_M" = "numeric",
                                                 "Post_SD" = "numeric",
                                                 "Post_N" = "numeric",
                                                 "Rand_N" = "numeric",
                                                 "Improved_N" = "numeric",
                                                 "Change_m" = "numeric",
                                                 "Change_SD" = "numeric",
                                                 "Change_N" = "numeric"),
                           groups.column.indicator = c("_trt1", "_trt2"),
                           data.format = NULL){

  if (is.null(data.format)){
    # Format switch
    input = readline("Enter: Is the data set in long [l] or wide [w] format? ")
    if (input[1] %in% c("l", "L", "long", "Long")){
      format = "long"
      data.format = "long"
    } else if (input[1] %in% c("w", "W", "wide", "Wide")){
      format = "wide"
      data.format = "wide"
    } else {
      stop("Data format must either be long [l] or wide [w].")
    }
  }

  if (!(data.format[1] %in% c("long", "wide"))){
    # Format switch
    input = readline("Enter: Is the data set in long [l] or wide [w] format? ")
    if (input[1] %in% c("l", "L", "long", "Long")){
      format = "long"
    } else if (input[1] %in% c("w", "W", "wide", "Wide")){
      format = "wide"
    } else {
      stop("Data format must either be long [l] or wide [w].")
    }
  } else {format = data.format}


  if (format[1] == "wide"){

    # 0. Get unique colnames without group indicators
    stringr::str_remove_all(
      colnames(data),
      paste0(groups.column.indicator[1],
             "|", groups.column.indicator[2])) %>%
      unique() -> colNames

    # 1. Check if data set contains all relevant variables.
    if (length(must.contain) > 0){
      if (sum(colNames %in% must.contain) < length(must.contain)){
        must.contain[which(!must.contain %in% colNames)] -> miss
        message(paste0("! data set does not contain variable(s) ",
                       paste(miss, collapse = ", "), "."))
      } else {
        message("- [OK] data set contains all variables in 'must.contain'.")
      }
    }

    # 2. Check if variables only contain desired values.
    if (length(variable.contains) > 0){
      issue = FALSE
      issueList = list()
      for (i in 1:length(variable.contains)){
        x = unique(data[colnames(data) %in%
                          c(names(variable.contains)[i],
                            paste0(names(variable.contains)[i],
                                   groups.column.indicator))]) %>%
          as.list() %>% do.call(c, .)
        if (length(x) == length(variable.contains[[i]]) &
            sum(x %in% variable.contains[[i]]) == length(x)){
          issueList[[i]] = 0
        } else {
          issue = TRUE
          issueList[[i]] = 1
        }
      }

      if (issue == TRUE){
        message(paste0("[!] ",
                       paste(names(variable.contains)[issueList == 1],
                             collapse = ", "),
                       " not (only) contains the values specified in 'variable.contains'."))
      } else {
        message("- [OK] variables contain only the values specified in 'variable.contains'.")
      }
    }

    # 3. Check if variables are of desired type; if not, try to convert
    variable.class %>%
      append(variable.class %>%
               {names(.) = paste0(names(.),
                                  groups.column.indicator[1]);.}) %>%
      append(variable.class %>%
               {names(.) = paste0(names(.),
                                  groups.column.indicator[2]);.}) %>%
      {.[names(.) %in% colnames(data)]} -> variable.class

    if (length(variable.class) > 0){
      for (i in 1:length(variable.class)){
        if (class(data[[names(variable.class)[i]]]) == variable.class[[i]]){
          message(paste0("- [OK] '", names(variable.class)[i], "' has desired class ",
                         variable.class[[i]], "."))
        } else {
          try({
            data[[names(variable.class)[i]]] = as(data[[names(variable.class)[i]]],
                                                  variable.class[[i]])},
            silent = TRUE) -> try.convert

          message(paste0("- [OK] '", names(variable.class)[i], "' has been converted to class ",
                         variable.class[[i]], "."))
        }
      }
    }
    class(data) = c("wide", "data.frame")
  }

  if (format[1] == "long") {

    # 1. Check if data set contains all relevant variables.
    if (length(must.contain) > 0){
      if (sum(colnames(data) %in% must.contain) < length(must.contain)){
        must.contain[which(!must.contain %in% colnames(data))] -> miss
        message(paste0("! data set does not contain variable(s) ",
                       paste(miss, collapse = ", "), "."))
      } else {
        message("- [OK] data set contains all variables in 'must.contain'.")
      }
    }

    # 2. Check if variables only contain desired values.
    if (length(variable.contains) > 0){
      issue = FALSE
      issueList = list()
      for (i in 1:length(variable.contains)){
        x = unique(data[[names(variable.contains)[i]]])
        if (length(x) == length(variable.contains[[i]]) &
            sum(x %in% variable.contains[[i]]) == length(x)){
          issueList[[i]] = 0
        } else {
          issue = TRUE
          issueList[[i]] = 1
        }
      }

      if (issue == TRUE){
        message(paste0("[!] ",
                       paste(names(variable.contains)[issueList == 1],
                             collapse = ", "),
                       " not (only) contains the values specified in 'variable.contains'."))
      } else {
        message("- [OK] variables contain only the values specified in 'variable.contains'.")
      }
    }

    # 3. Check if variables are of desired type; if not, try to convert
    if (length(variable.class) > 0){
      for (i in 1:length(variable.class)){
        if (class(data[[names(variable.class)[i]]]) == variable.class[[i]]){
          message(paste0("- [OK] '", names(variable.class)[i], "' has desired class ",
                         variable.class[[i]], "."))
        } else {
          try({
            data[[names(variable.class)[i]]] = as(data[[names(variable.class)[i]]],
                                                  variable.class[[i]])},
            silent = TRUE) -> try.convert

          message(paste0("- [OK] '", names(variable.class)[i], "' has been converted to class ",
                         variable.class[[i]], "."))
        }
      }
    }
    class(data) = c("long", "data.frame")
  }
  return(data)
}
