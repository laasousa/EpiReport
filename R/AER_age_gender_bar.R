#' Get disease-specific age and gender bar graph
#'
#' Function returning the age and gender bar graph that will be included
#' in the epidemiological report at the bookmark location \code{'BARGPH_AGEGENDER_BOOKMARK'}
#' of the template report. \cr
#' The bar graph presents the distribution of cases at EU/EEA level using either:
#' \itemize{
#'    \item{\code{AG-COUNT}: }{The number of cases by age and gender}
#'    \item{\code{AG-RATE}: }{The rate per 100 000 cases by age and gender}
#'    \item{\code{AG-PROP}: }{The proportion of cases by age and gender}
#'    \item{\code{A-RATE}: }{The rate per 100 000 cases by age only}
#' }
#' The choice of the type of bar graph is set in the report parameters table \code{AERparams}. \cr
#' (see ECDC reports
#' \url{https://ecdc.europa.eu/en/annual-epidemiological-reports})
#'
#' @param x dataframe, raw disease-specific dataset (see specification of the
#' dataset in the package vignette with \code{browseVignettes(package = "EpiReport")})
#' (default \code{SALM2016})
#' @param disease character string, disease code (default \code{"SALM"}).
#' Please make sure the disease code is included in the disease-specific dataset x
#' in the \code{HealthTopicCode} variable.
#' @param year numeric, year to produce the graph for (default \code{2016}).
#' Please make sure the year is included in the disease-specific dataset x
#' in the \code{TimeCode} variable.
#' @param reportParameters dataframe, dataset including the required parameters
#' for the graph and report production (default \code{AERparams}) (see specification
#' of the dataset in the package vignette with \code{browseVignettes(package = "EpiReport")})
#' @param geoCode character string, GeoCode to run the analysis on
#' (default \code{"EU_EEA31"})
#' @param index integer, figure number
#' @param doc 'Word' document (see \code{'officer'} package) in which to add the graph
#' at the bookmark location.
#' If doc is missing, \code{getAgeGender} returns the \code{ggplot2} object.
#'
#' @return 'Word' doc or a ggplot2 object
#'
#' @seealso Global function for the full epidemilogical report: \code{\link{getAER}}  \cr
#' Required Packages: \code{\link{ggplot2}} \code{\link{officer}} \cr
#' Internal functions: \code{\link{plotAgeGender}} \code{\link{plotAge}} \cr
#' Default datasets: \code{\link{AERparams}}
#'
#' @examples
#'
#' # --- Plot using the default dataset
#' getAgeGender()
#'
#' # --- Plot using external dataset
#' # --- Please see examples in the vignette
#' browseVignettes(package = "EpiReport")
#'
#' @export
#'
getAgeGender <- function(x = EpiReport::SALM2016,
                         disease = "SALM",
                         year = 2016,
                         reportParameters = EpiReport::AERparams,
                         geoCode = "EU_EEA31",
                         index = 1,
                         doc){

  ## ----
  ## Setting default arguments if missing
  ## ----

  if(missing(x)) { x <- EpiReport::SALM2016 }
  if(missing(disease)) { disease <- "SALM" }
  if(missing(year)) { year <- 2016 }
  if(missing(reportParameters)) { reportParameters <- EpiReport::AERparams }
  if(missing(geoCode)) { geoCode <- "EU_EEA31" }
  if(missing(index)) { index <- 1 }


  ## ----
  ## Preparing the data
  ## ----

  x$MeasureCode <- cleanMeasureCode(x$MeasureCode)


  ## ----
  ## Filtering parameter table
  ## ----

  reportParameters <- filterDisease(disease, reportParameters)


  ## ----
  ## Age Gender bar graph
  ## ----

  if(reportParameters$AgeGenderUse != "NO") {


    ## ----
    ## Filtering data
    ## ----

    # --- Filtering on the required variables
    x <- dplyr::select(x, c("HealthTopicCode", "MeasureCode", "TimeUnit",
                            "TimeCode", "GeoCode",
                            "XValue", "XLabel", "YValue", "YLabel", "ZValue"))
    if(nrow(x) == 0) {
      stop(paste('The dataset does not include the necessary variables.'))
    }

    # --- Filtering on the disease of interest
    x <- dplyr::filter(x, x$HealthTopicCode == disease)
    if(nrow(x) == 0) {
      stop(paste('The dataset does not include the selected disease "',
                 disease, '".'))
    }

    # --- Filtering on Yearly data only
    x <- dplyr::filter(x, x$TimeUnit == "Y")
    if(nrow(x) == 0) {
      stop(paste('The dataset does not include the required time unit \'Y\'',
                 'for the selected disease "', disease, '".'))
    }

    # --- Filtering on the year of interest
    x <- dplyr::filter(x, x$TimeCode == year)
    if(nrow(x) == 0) {
      stop(paste('The dataset does not include the year of interest "', year,
                 '" for the selected disease "', disease, '".'))
    }

    # --- Filtering on the GeoCode of interest
    x <- dplyr::filter(x, x$GeoCode == geoCode)
    if(nrow(x) == 0) {
      stop(paste('The dataset does not include the geoCode of interest "', geoCode,
                 '" for the selected disease "', disease, '".'))
    }



    ## ------------
    ## Age and Gender bar graph using rates: AG-RATE
    ## ------------

    if(reportParameters$AgeGenderUse == "AG-RATE") {

      # --- Filtering on MeasureCode indicators
      x <- dplyr::filter(x, x$MeasureCode %in%
                           paste(reportParameters$MeasurePopulation, "AGE_GENDER.RATE", sep="."))
      if(nrow(x) == 0) {
        stop(paste('The dataset does not include the required MeasureCode "',
                   paste(reportParameters$MeasurePopulation, "AGE_GENDER.RATE", sep="."),
                   '" for the selected disease "', disease, '".'))
      }
    }



    ## ------------
    ## Age and Gender bar graph using counts: AG-COUNT
    ## ------------

    if(reportParameters$AgeGenderUse == "AG-COUNT") {

      # --- Filtering on MeasureCode indicators
      x <- dplyr::filter(x, x$MeasureCode %in%
                           paste(reportParameters$MeasurePopulation, "AGE_GENDER.COUNT", sep="."))
      if(nrow(x) == 0) {
        stop(paste('The dataset does not include the required MeasureCode "',
                   paste(reportParameters$MeasurePopulation, "AGE_GENDER.COUNT", sep="."),
                   '" for the selected disease "', disease, '".'))
      }
    }



    ## ------------
    ## Proportion Graph: AG-PROP
    ## ------------

    if(reportParameters$AgeGenderUse == "AG-PROP") {

      # --- Filtering on MeasureCode indicators
      x <- dplyr::filter(x, x$MeasureCode %in%
                           paste(reportParameters$MeasurePopulation,
                                 "AGE_GENDER.PROPORTION", sep="."))
      if(nrow(x) == 0) {
        stop(paste('The dataset does not include the required MeasureCode "',
                   paste(reportParameters$MeasurePopulation, "AGE_GENDER.PROPORTION", sep="."),
                   '" for the selected disease "', disease, '".'))
      }

    }


    ## ------------
    ## Age Rate bar graph (WNV): A-RATE
    ## ------------

    if(reportParameters$AgeGenderUse == "A-RATE") {

      # --- Filtering on MeasureCode indicators
      x <- dplyr::filter(x, x$MeasureCode %in%
                           paste(reportParameters$MeasurePopulation, "AGE.RATE", sep="."))
      if(nrow(x) == 0) {
        stop(paste('The dataset does not include the required MeasureCode "',
                   paste(reportParameters$MeasurePopulation, "AGE.RATE", sep="."),
                   '" for the selected disease "', disease, '".'))
      }

    }


    ## ----
    ## Ordering the labels for gender variable
    ## ----

    x$XLabel = factor(x$XLabel, orderQuasinum(unique(x$XLabel)))
    # --- for Age by Gender
    if(substr(reportParameters$AgeGenderUse, 1, 2) == "AG") {
      x$YLabel = factor(x$YLabel, c("Male","Female"))
    }


    ## ----
    ## Plot
    ## ----

    if(substr(reportParameters$AgeGenderUse, 1, 2) == "AG") {
      # --- Age by Gender
      p <- plotAgeGender(x,
                         xvar = "XLabel",
                         yvar = "ZValue",
                         group = "YLabel",
                         fill_color1 = "#65B32E",
                         fill_color2 = "#7CBDC4",
                         ytitle  = toCapTitle(tolower(reportParameters$AgeGenderBarGraphLabel)))
    } else {
      # --- Age only
      p <- plotAge(x,
                   xvar = "XLabel",
                   yvar = "YValue",
                   fill_color1 = "#65B32E",
                   ytitle  = toCapTitle(tolower(reportParameters$AgeGenderBarGraphLabel)))
    }


    if(missing(doc)) {
      return(p)
    } else {

      ## ------ Caption
      pop <- ifelse(reportParameters$MeasurePopulation == "ALL", "", "-")
      pop <- ifelse(reportParameters$MeasurePopulation == "CONFIRMED", "confirmed ", pop)
      groupby <- ifelse(substr(reportParameters$AgeGenderUse, 1, 2) == "AG",
                        "by age and gender", "by age")
      caption <- paste("Figure ", index, ". Distribution of ", pop,
                       reportParameters$Label, " ",
                       tolower(reportParameters$AgeGenderBarGraphLabel),
                       ", ", groupby, ", EU/EEA, ",
                       year, sep = "")
      officer::cursor_bookmark(doc, id = "BARGPH_AGEGENDER_BOOKMARK")
      doc <- officer::body_add_par(doc,
                                   value = caption)

      ## ------ Plot
      doc <- officer::body_add_gg(doc,
                                  value = p,
                                  width = 6,
                                  height = 4)
    }
  }




  ## ----
  ## No AgeGender bar graph for this disease
  ## ----

  if(reportParameters$AgeGenderUse == "N") {
    message(paste('According to the parameter table \'AERparams\', this disease "',
                  disease, '" does not include any age and gender bar graph in the AER report.', sep = ""))
    if(missing(doc)) {
      return()
    } else {
      return(doc)
    }
  }


  ## ----
  ## Final output
  ## ----

  if(missing(doc)) {
    return(p)
  }else{
    return(doc)
  }



}





#' Age and Gender bar graph
#'
#' This function draws a bar graph of the distribution of cases by age group
#' and gender (or possibly other grouping). \cr
#' The bar graph presents the distribution of cases at EU/EEA level using either:
#' \itemize{
#'    \item{\code{AG-COUNT}: }{The number of cases by age and gender}
#'    \item{\code{AG-RATE}: }{The rate per 100 000 cases by age and gender}
#'    \item{\code{AG-PROP}: }{The proportion of cases by age and gender}
#' }
#' Expects aggregated data.
#'
#' @param data dataframe containing the variables to plot
#' @param xvar character string, name of the variable to plot on the x-axis in quotes
#' (default \code{"XLabel"})
#' @param yvar character string, name of the variable to plot on the y-axis in quotes
#' (default \code{"ZValue"})
#' @param fill_color1 character string, hexadecimal colour to use in the graph for bar 1;
#' (default to ECDC green \code{"#65B32E"})
#' @param fill_color2 character string, hexadecimal colour to use in the graph for bar 2;
#' (default to ECDC blue \code{"#7CBDC4"})
#' @param group character string, name of the grouping variable in quotes, e.g. gender.
#' (default \code{"YLabel"})
#' @param ytitle character string, y-axis title; (default \code{"Rate"}).
#'
#' @keywords age gender bargraph
#'
#' @seealso Global function: \code{\link{getAgeGender}}  \cr
#' Required Packages: \code{\link{ggplot2}}
#'
#' @examples
#' # --- Create dummy data
#' mydat <- data.frame(Gender=c("F", "F", "M", "M"),
#' AgeGroup = c("0-65", "65+", "0-65", "65+"),
#' NumberOfCases = c(54,43,32,41))
#'
#' # --- Plot the dummy data
#' plotAgeGender(mydat,
#'               xvar = "AgeGroup",
#'               yvar = "NumberOfCases",
#'               group = "Gender",
#'               ytitle = "Number of cases")
#'
#' @export
#'
plotAgeGender <- function(data,
                          xvar = "XLabel",
                          yvar = "ZValue",
                          group = "YLabel",
                          fill_color1 = "#65B32E",
                          fill_color2 = "#7CBDC4",
                          ytitle  = "Rate") {


  # --- Breaks for the Y axis

  FIGBREAKS <- pretty(seq(0,
                          max(data[[yvar]]),
                          by = max(data[[yvar]])/5))


  # --- Please Note: ECDC AER plots use the font "Tahoma"
  # --- The font is not available on Linux

  # if ("Tahoma" %in% extrafont::fonts()) {
  #   FONT <- "Tahoma"
  #   suppressMessages(extrafont::loadfonts(device = "win"))
  # } else if (Sys.info()["sysname"] == "Windows") {
  #   suppressMessages(extrafont::font_import(pattern = 'tahoma', prompt = FALSE))
  #   suppressMessages(extrafont::loadfonts(device = "win"))
  #   FONT <- "Tahoma"
  # } else {
  #   FONT <- NULL
  # }
  FONT <- NULL



  # --- Plotting

  p <- ggplot2::ggplot(data = data,
                       ggplot2::aes(x = data[[xvar]], y = data[[yvar]], fill = data[[group]])) +
    ggplot2::geom_bar(stat = "identity", position = ggplot2::position_dodge()) +
    ggplot2::scale_fill_manual(values = c(fill_color1, fill_color2)) +
    ggplot2::scale_y_continuous(expand = c(0,0),
                                limits = c(0, max(FIGBREAKS)),
                                breaks = FIGBREAKS) +
    ggplot2::labs(title = "", x = "Age", y = ytitle) +
    ggplot2::theme(axis.text = ggplot2::element_text(size = 8, family = FONT),
                   axis.title = ggplot2::element_text(size = 9, family = FONT),
                   axis.line = ggplot2::element_line(colour = "black"),
                   axis.line.x = ggplot2::element_blank(),
                   # --- Setting the background
                   panel.grid.major = ggplot2::element_blank(),
                   panel.grid.minor = ggplot2::element_blank(),
                   panel.background = ggplot2::element_blank(),
                   # --- Setting the legend
                   legend.position = "right",
                   legend.title = ggplot2::element_blank(),
                   legend.text = ggplot2::element_text(size = 8, family = FONT),
                   legend.key.width = ggplot2::unit(0.8, "cm"),
                   legend.key.size = ggplot2::unit(0.4, "cm"))

  return(p)
}




#' Age bar graph
#'
#' This function draws a bar graph by age group (or possibly other grouping). \cr
#' The bar graph presents the distribution of cases at EU/EEA level
#' using the rate per 100 000 cases by age. \cr
#' Expects aggregated data.
#'
#' @param data dataframe containing the variables to plot
#' @param xvar character string, name of the variable to plot on the x-axis in quotes
#' (default \code{"XLabel"})
#' @param yvar character string, name of the variable to plot on the y-axis in quotes
#' (default \code{"YValue"})
#' @param fill_color1 character string, hexadecimal colour to use in the graph;
#' (default to ECDC green \code{"#65B32E"})
#' @param ytitle character string, y-axis title; (default \code{"Rate"}).
#'
#' @keywords age bargraph
#'
#' @seealso Global function: \code{\link{getAgeGender}}  \cr
#' Required Packages: \code{\link{ggplot2}}
#'
#' @examples
#'
#' # --- Create dummy data
#' mydat <- data.frame(AgeGroup = c("0-25", "26-65", "65+"),
#'                     NumberOfCases = c(54,32,41))
#'
#' # --- Plot the dummy data
#' plotAge(mydat,
#'         xvar = "AgeGroup",
#'         yvar = "NumberOfCases",
#'         ytitle = "Number of cases")
#'
#' @export
#'
plotAge <- function(data,
                    xvar = "XLabel",
                    yvar = "YValue",
                    fill_color1 = "#65B32E",
                    ytitle  = "Rate") {


  # --- Breaks for the Y axis

  FIGBREAKS <- pretty(seq(0,
                          max(data[[yvar]]),
                          by = max(data[[yvar]])/5))

  # --- Plotting

  p <- ggplot2::ggplot(data = data,
                       ggplot2::aes(x = data[[xvar]], y = data[[yvar]])) +
    ggplot2::geom_bar(stat = "identity", fill = fill_color1) +
    ggplot2::scale_y_continuous(expand = c(0,0),
                                limits = c(0, max(FIGBREAKS)),
                                breaks = FIGBREAKS) +
    ggplot2::labs(title = "", x = "Age", y = ytitle) +
    ggplot2::theme(axis.text = ggplot2::element_text(size = 8),
                   axis.title = ggplot2::element_text(size = 9),
                   axis.line = ggplot2::element_line(colour = "black"),
                   axis.line.x = ggplot2::element_blank(),
                   # --- Setting the background
                   panel.grid.major = ggplot2::element_blank(),
                   panel.grid.minor = ggplot2::element_blank(),
                   panel.background = ggplot2::element_blank())

  return(p)
}

