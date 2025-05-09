% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/data.R
\docType{data}
\name{carcass_estimates}
\alias{carcass_estimates}
\title{Carcass Survey CJS Estimates}
\format{
\itemize{
\item \code{year}: year data were collected
\item \code{spawner_abundance_estimate}: estimated annual spawner abundance
\item \code{stream}: stream data were collected on
\item \code{lower}: lower confidence interval of abundance estimate
\item \code{upper}: upper confidence interval of abundance estimate
\item \code{confidence_interval}: confidence interval associated with lower and upper values
}
}
\source{
Carcass survey CJS estimates were provided by monitoring programs.
These data are currently being uploaded to EDI. In the meantime you can find data exploration scripts
for each tributary \href{https://github.com/SRJPE/JPE-datasets/tree/main/data-raw/qc-markdowns/adult-holding-redd-and-carcass-surveys}{here} and
combined carcass estimates \href{https://github.com/SRJPE/JPE-datasets/blob/main/data-raw/standard-format-data-prep/carcass_cjs_estimates_standard_format.Rmd}{here}.
}
\usage{
carcass_estimates
}
\description{
Carcass Estimates produced by analyzing mark-recapture carcass surveys
with a Cormack-Jolly-Seber (CJS) model. Performed on the Yuba River, Feather River, and
Butte Creek. Butte Creek uses the \code{escapeMR} package applied to raw count data.
}
\keyword{datasets}
