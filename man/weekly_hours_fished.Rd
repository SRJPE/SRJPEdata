% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/data.R
\docType{data}
\name{weekly_hours_fished}
\alias{weekly_hours_fished}
\title{Weekly Hours Fished}
\format{
Dataframe containing 7 columns (stream, site, subsite, site_group, week, year, hours_fished)
\itemize{
\item \code{year}: year
\item \code{stream}: Stream RST is located on
\item \code{site}: Site RST is located on
\item \code{site_group}: Site group, used to separate traps within the same stream that have unique environmental conditions.
\item \code{week}: Week
\item \code{hours_fished}: Number of hours that a trap was operated in a given week. Capped at 168.
}
}
\usage{
weekly_hours_fished
}
\description{
Datasets containing the hours fished for each stream, site, and week.
See \code{vignette("trap_effort", package = "SRJPEdata")} for more details.
}
\keyword{datasets}
