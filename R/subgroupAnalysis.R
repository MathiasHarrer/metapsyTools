#' Run subgroup analyses
#'
#' This function allows to simultaneously conduct different subgroup analyses using
#' \code{runMetaAnalysis} objects.
#'
#' @usage subgroupAnalysis(.model,
#'                         ...,
#'                         .which.run = .model$which.run[1],
#'                         .round.digits = 2,
#'                         .nnt.cer = NULL,
#'                         .tau.common = FALSE,
#'                         .html = TRUE)
#'
#' @param .model An object of class \code{"runMetaAnalysis"}, created by \code{\link{runMetaAnalysis}}.
#' @param ... <\link[dplyr]{dplyr_data_masking}>. A number of subgroup variables included in the original dataset
#' provided to \code{\link{runMetaAnalysis}}, separated by commas.
#' @param .which.run The model in \code{.model} that should be used for the subgroup analyses. Uses the default
#' analysis in \code{.model} if no value is specified by the user.
#' @param .round.digits \code{numeric}. Number of digits to round the (presented) results by. Default is \code{2}.
#' @param .nnt.cer \code{numeric}. Value between 0 and 1, indicating the assumed control group event rate to be used
#' for calculating NNTs via the Furukawa-Leucht method. If set to \code{NULL} (default),
#' the value saved in \code{.model} is (re-)used.
#' @param .tau.common \code{logical}. Should a common (\code{TRUE}) or subgroup-specific (\code{FALSE}) estimate
#' of the between-study heterogeneity be calculated when analyzing the subgroups? \code{FALSE} by default. Note that subgroup
#' analyses based on "multilevel" models automatically assume common heterogeneity estimates.
#' @param .html \code{logical}. Should an HTML table be created for the results? Default is \code{TRUE}.
#'
#' @return Returns an object of class \code{"subgroupAnalysis"}. This object includes, among other things,
#' a \code{data.frame} with the name \code{summary}, in which all subgroup analysis results are summarized.
#' Other objects are the "raw" subgroup analysis model objects returned.
#' This allows to conduct further operations on some subgroup analysis specifically.
#'
#' @examples
#' \dontrun{
#' data("inpatients")
#' library(meta)
#'
#' inpatients %>%
#'    checkDataFormat() %>%
#'      checkConflicts() %>%
#'      expandMultiarmTrials() %>%
#'      calculateEffectSizes() -> data
#'
#' # Run the meta-analyses
#' runMetaAnalysis(data) -> res
#'
#' # Subgroup analysis
#' subgroupAnalysis(res, Outc_measure, country) -> sg
#' plot(sg, "Outc_measure")
#' plot(sg, "country")
#' }
#'
#' @author Mathias Harrer \email{mathias.h.harrer@@gmail.com},
#' Paula Kuper \email{paula.r.kuper@@gmail.com}, Pim Cuijpers \email{p.cuijpers@@vu.nl}
#'
#' @seealso \code{\link{runMetaAnalysis}}
#'
#' @details For more details see the help vignette: \code{vignette("metapsyTools")}.
#'
#' @import dplyr
#' @importFrom scales pvalue
#' @importFrom purrr map
#' @importFrom meta update.meta metagen
#' @importFrom metafor escalc aggregate.escalc rma.mv
#' @importFrom stats dffits model.matrix rnorm rstudent
#' @importFrom utils combn
#' @export subgroupAnalysis

subgroupAnalysis = function(.model, ...,
                 .which.run = .model$which.run[1],
                 .round.digits = 2,
                 .nnt.cer = NULL,
                 .tau.common = FALSE,
                 .html = TRUE){

  if (class(.model)[1] != "runMetaAnalysis"){
    stop("Input must be of class 'runMetaAnalysis'. Did you apply 'runMetaAnalysis' first?")
  }


  variables = .model$data %>% dplyr::select(...) %>% colnames()
  .round.digits = abs(.round.digits)

  # Get model type
  model.type = paste0("model.", .which.run)
  M = .model[[model.type]]
  message("- [OK] '", model.type, "' used for subgroup analyses.")

  if (.which.run[1] == "combined" & .model$model.combined$k == 1){
    stop("'.which.run' is set to 'combined', but there is only k=1 study/ES.")}
  if (.which.run[1] == "lowest" & .model$model.lowest$k == 1){
    stop("'.which.run' is set to 'lowest', but there is only k=1 study/ES.")}
  if (.which.run[1] == "highest" & .model$model.highest$k == 1){
    stop("'.which.run' is set to 'highest', but there is only k=1 study/ES.")}
  if (.which.run[1] == "influence" & .model$model.influence$k == 1){
    stop("'.which.run' is set to 'influence', but there is only k=1 study/ES.")}
  if (.which.run[1] == "rob" & .model$model.rob$k == 1){
    stop("'.which.run' is set to 'rob', but there is only k=1 study/ES.")}

  # Run all subgroup analyses
  if (class(M)[1] == "metagen"){
    
    if (.tau.common)
      message("- [OK] Subgroup analyses conducted using a common heterogeneity variance estimate.")
    
    purrr::map(as.list(variables), function(x){
      
      na.mask = !is.na(M$data[[x]])
      meta::metagen(TE = M$TE[na.mask],
                    seTE = M$seTE[na.mask],
                    studlab = M$studlab[na.mask],
                    method.tau = M$method.tau,
                    method.tau.ci = M$method.tau.ci,
                    hakn = M$hakn,
                    data = M$data[na.mask,],
                    subgroup = M$data[[x]][na.mask],
                    fixed = M$fixed,
                    random = M$random,
                    tau.common = .tau.common)

    }) -> subgroup.analysis.list
    names(subgroup.analysis.list) = variables


    if (sum(is.na(M$data[variables])) > 0){
      warning("Some subgroup variables contained NA. These entries were omitted from model fitting.")
    }

    # Extract information
    subgroup.analysis.list %>%
      purrr::map2(as.list(variables), function(x,y){

        # Effect size in each group
        if (x$comb.fixed == TRUE){g = round(x$TE.fixed.w, .round.digits)} else {
          g = round(x$TE.random.w, .round.digits)}

        # Confidence interval for g
        if (x$comb.fixed == TRUE){
          g.ci = paste0("[", round(x$lower.fixed.w, .round.digits), "; ",
                        round(x$upper.fixed.w, .round.digits), "]")
        } else {
          g.ci = paste0("[", round(x$lower.random.w, .round.digits), "; ",
                        round(x$upper.random.w, .round.digits), "]")}

        # I-squared
        i2 = ifelse(is.na(x$I2.w), "-", round(x$I2.w*100, .round.digits-1))
        i2.ci = paste0("[", ifelse(is.na(x$lower.I2.w), "-",
                                   round(x$lower.I2.w*100, .round.digits-1)),
                       "; ", ifelse(is.na(x$upper.I2.w), "-",
                                    round(x$upper.I2.w*100, .round.digits-1)),"]") %>%
          ifelse(.=="[-; -]", "-", .)

        # NNT
        if (is.null(.nnt.cer)){
          metapsyNNT(g, .model$nnt.cer) %>%
            round(.round.digits) %>% abs() -> nnt
        } else {
          metapsyNNT(g, .nnt.cer) %>%
            round(.round.digits) %>% abs() -> nnt
        }


        data.frame(variable = y,
                   group = x$bylevs,
                   n.comp = x$k.w, g = g, g.ci = g.ci,
                   i2 = i2, i2.ci = i2.ci,
                   nnt = nnt,
                   p = ifelse(is.na(x$pval.Q.b.random), NA,
                              scales::pvalue(x$pval.Q.b.random)))
      }) %>% do.call(rbind, .) %>% {rownames(.) = NULL;.} -> summary
  }


  if (class(M)[1] == "rma.mv"){

    stringr::str_replace_all(as.character(M$random[[1]]), "1 \\| ", "")[2] %>%
      strsplit("/") %>% {.[[1]]} %>% {.[1]} -> study.id

    dat.mv = data.frame(yi = M$yi,
                        vi = M$vi,
                        slab = M$slab,
                        study = .model$data[!is.na(.model$data$es), study.id],
                        es.id = 1:length(M$yi))
    dat.mv = cbind(dat.mv, .model$data[!is.na(.model$data$es),] %>%
                     dplyr::select(dplyr::all_of(variables)) %>%
                     purrr::map_dfr(~as.factor(.)))

    purrr::map(as.list(variables), function(x){
      form = as.formula(paste0("~", x))
      metafor::rma.mv(yi = yi,
                      V = vi,
                      data = dat.mv,
                      random = M$random[[1]],
                      test = M$test,
                      method = "REML",
                      mods = form) -> res.mv
      }) -> subgroup.analysis.list
    names(subgroup.analysis.list) = variables


    purrr::map2(subgroup.analysis.list, variables, function(x, y){

      g = c(as.numeric(x$b)[1],
            as.numeric(x$b)[-1] + as.numeric(x$b)[1]) %>% round(.round.digits)
      g.lower = {as.numeric(x$b)[1] + x$ci.lb} %>% round(.round.digits)
      g.upper = {as.numeric(x$b)[1] + x$ci.ub} %>% round(.round.digits)
      g.ci = paste0("[", g.lower, "; ", g.upper, "]")

      if (is.null(.nnt.cer)){
        metapsyNNT(g, .model$nnt.cer) %>%
          round(.round.digits) %>% abs() -> nnt
      } else {
        metapsyNNT(g, .nnt.cer) %>%
          round(.round.digits) %>% abs() -> nnt
      }

      data.frame(variable = y,
                 group = levels(dat.mv[[y]]),
                 n.comp = table(dat.mv[[y]]) %>% as.numeric(),
                 g = g, g.ci = g.ci, i2 = "-", i2.ci = "-",
                 nnt = nnt, p = x$QMp %>% scales::pvalue())
    }) %>% do.call(rbind, .) %>% {rownames(.) = NULL;.} -> summary

  }


  # Return
  returnlist = list(summary = summary,
                    subgroup.analysis.list = subgroup.analysis.list,
                    html = .html)
  class(returnlist) = c("subgroupAnalysis", "list")
  return(returnlist)

}




#' Print method for objects of class 'subgroupAnalysis'.
#'
#' Print S3 method for objects of class \code{subgroupAnalysis}.
#'
#' @param x An object of class \code{subgroupAnalysis}.
#' @param ... Additional arguments.
#'
#' @author Mathias Harrer \email{mathias.h.harrer@@gmail.com},
#' Paula Kuper \email{paula.r.kuper@@gmail.com}, Pim Cuijpers \email{p.cuijpers@@vu.nl}
#'
#' @importFrom knitr kable
#' @importFrom magrittr set_colnames
#' @importFrom dplyr as_tibble
#' @importFrom kableExtra kable_styling column_spec collapse_rows
#'
#' @export
#' @method print subgroupAnalysis

print.subgroupAnalysis = function(x, ...){

  cat("Subgroup analysis results ")
  cat("---------------------- \n")
  print(dplyr::as_tibble(x$summary), n = nrow(x$summary))

  if (x$html == TRUE){

    x$summary %>%
      magrittr::set_colnames(c("Variable", "Level", "<i>n</i><sub>comp</sub>",
                               "<i>g</i>", "CI",
                               "<i>I</i><sup>2</sup>",
                               "CI", "NNT", "<i>p</i>")) %>%
      knitr::kable(escape = FALSE) %>%
      kableExtra::kable_styling(font_size = 8, full_width = FALSE) %>%
      kableExtra::column_spec(1, bold = TRUE) %>%
      kableExtra::collapse_rows(columns = 1, valign = "top") %>%
      print()
  }
}


#' Plot method for objects of class 'runMetaAnalysis'.
#'
#' Plot S3 method for objects of class \code{runMetaAnalysis}.
#'
#' @param x An object of class \code{runMetaAnalysis}.
#' @param which \code{character}. Subgroup analysis to be plotted (variable name).
#' @param ... Additional arguments.
#'
#' @author Mathias Harrer \email{mathias.h.harrer@@gmail.com},
#' Paula Kuper \email{paula.r.kuper@@gmail.com}, Pim Cuijpers \email{p.cuijpers@@vu.nl}
#'
#' @importFrom meta forest.meta
#'
#' @export
#' @method plot subgroupAnalysis

plot.subgroupAnalysis = function(x, which = NULL, ...){

  if (class(x$subgroup.analysis.list[[1]])[1] == "rma.mv"){
    stop("Cannot generate subgroup analysis forest plots for 'threelevel' models.")
  }

  if (is.null(which)){
    message("- [OK] '", names(x$subgroup.analysis.list)[1], "' used for forest plot.")
    meta::forest.meta(x$subgroup.analysis.list[[1]])
  } else {
    meta::forest.meta(x$subgroup.analysis.list[[which[1]]])
  }
}
