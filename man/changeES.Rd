% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utils.R
\name{changeES}
\alias{changeES}
\title{Calculate Hedges' g based on change data.}
\usage{
changeES(x, ...)
}
\arguments{
\item{x}{data}

\item{...}{Change score effect size data. Must be \code{Change_m_trt1}, \code{Change_m_trt2}, \code{Change_SD_trt1},
\code{Change_SD_trt2}, \code{Change_N_trt1}, \code{Change_N_trt2} (all \code{numeric}).}
}
\description{
Calculate Hedges' g based on change data. Only meant to be used as
part of \code{\link{calculateEffectSizes}}.
}
\keyword{internal}
