% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/02-downAndUploadModel.R
\name{downloadModelUI}
\alias{downloadModelUI}
\alias{downloadModel}
\title{Download model module}
\usage{
downloadModelUI(id, label)

downloadModel(input, output, session, savedModels, uploadedNotes)
}
\arguments{
\item{id}{id of module}

\item{label}{label of module}

\item{input}{shiny input}

\item{output}{shiny output}

\item{session}{shiny session}

\item{savedModels}{(reactive) list of models of class \code{\link{TemporalIso}}}

\item{uploadedNotes}{(reactive) variable that stores content for README.txt}
}
\description{
UI function to download a zip file with notes and a list of models

Backend for download model module
}
