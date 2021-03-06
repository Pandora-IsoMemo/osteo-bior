library(shiny)
library(shinyWidgets)
library(shinythemes)
library(colourpicker)
library(OsteoBioR)
library(shinyMatrix)
library(dplyr)
library(shinycssloaders)
library(ggplot2)
library(rstan)

tagList(
  shinyjs::useShinyjs(),
  shiny::navbarPage(
    includeCSS("www/custom.css"),
    title = paste("OsteoBioR App", packageVersion("OsteoBioR")),
    theme = shinythemes::shinytheme("flatly"),
    id = "tab",
    position = "fixed-top",
    collapsible = TRUE,
    # DATA  ------------------------------------------------------------------------------------------------
    tabPanel(
      title = "Data",
      id = "Data",
      value = "Data",
      sidebarLayout(
        sidebarPanel(
          width = 2,
          HTML("<h4>Upload</h4><br>"),
          HTML("<h5>Renewal rates dataset</h5>"),
          # DATASET
          selectInput(
            "filetypeData",
            "File type",
            choices = c("xlsx", "csv"),
            selected = "xlsx"
          ),
          conditionalPanel(
            condition = "input.filetypeData == 'csv'",
            div(
              style = "display: inline-block;horizontal-align:top; width: 80px;",
              textInput("colseparatorData", "column separator:", value = ",")
            ),
            div(
              style = "display: inline-block;horizontal-align:top; width: 80px;",
              textInput("decseparatorData", "decimal separator:", value = ".")
            )
          ),
          helpText("The first row in your file needs to contain variable names."),
          fileInput("fileData", ""),
          # ISOTOPIC VALUES
          HTML("<h5>Measurements dataset</h5>"),
          selectInput(
            "filetypeIso",
            "File type",
            choices = c("xlsx", "csv"),
            selected = "xlsx"
          ),
          conditionalPanel(
            condition = "input.filetypeIso == 'csv'",
            div(
              style = "display: inline-block;horizontal-align:top; width: 80px;",
              textInput("colseparatorIso", "column separator:", value = ",")
            ),
            div(
              style = "display: inline-block;horizontal-align:top; width: 80px;",
              textInput("decseparatorIso", "decimal separator:", value = ".")
            )
          ),
          helpText("The first row in your file needs to contain variable names."),
          fileInput("fileIso", ""),
          HTML("<hr>"),
          
          # DATA GENERATE
          HTML("<h5>Generate data</h5><br>"),
          actionButton("exampleData", "Load Example Data")
          
        ),
        
        mainPanel(
          HTML("<h5>Renewal rates dataset </h5>"),
          matrixInput(
            inputId = "dataMatrix",
            #inputClass = "matrix-input-rownames",
            class = "numeric",
            value = matrix(ncol = 6, dimnames = list(
              c(""),  c("individual", "intStart", "intEnd", "bone1", "bone2", "tooth1")
            )),
            #copy = TRUE,
            #paste = TRUE,
            cols = list(
              names = TRUE,
              extend = TRUE,
              delta = 1,
              editableNames = TRUE
            ),
            rows = list(
              names = FALSE,
              editableNames = TRUE,
              extend = TRUE,
              delta = 1
            )
          ),
          # To do: Add  time cuts: Split predictions into groups at the following points in time
          # for the selected individual
          HTML("<h5>Mean and (optional) standard deviation of measurements</h5>"),
          matrixInput(
            inputId = "isotope",
            #inputClass = "matrix-input-rownames",
            class = "numeric",
            value = matrix(ncol = 3, dimnames = list(c(""),  c("individual", "y_mean", "y_sigma"))),
            #copy = TRUE,
            #paste = TRUE,
            cols = list(
              names = TRUE,
              extend = FALSE,
              editableNames = FALSE,
              delta = 0
            ),
            rows = list(
              names = FALSE,
              editableNames = FALSE,
              extend = TRUE,
              delta = 1
            )
          )
        )
      )
    ),
    # MODEL ----------------------------------------------------------------------------------------------
    tabPanel("Model",
             id = "Model",
             fluidRow(
               sidebarPanel(
                 width = 2,
                 modelSpecificationsUI("modelSpecification", "Model Specification"),
                 actionButton("fitModel", "Fit Model")
               ),
               mainPanel(
                 tabsetPanel(
                   id = "modTabs",
                   tabPanel(
                     "Summary",
                     value = "summaryTab",
                     verbatimTextOutput("summary") %>% withSpinner(color =
                                                                     "#20c997"),
                     actionButton("exportSummary", "Export Interval Data")
                   ),
                   tabPanel(
                     "Credibility Intervals",
                     value = "credibilityIntervalsTab",
                     plotOutput("plot") %>% withSpinner(color =
                                                          "#20c997"),
                     actionButton("exportCredIntPlot", "Export Plot"),
                     actionButton("exportCredIntDat", "Export Data")
                   ),
                   tabPanel(
                     "Credibility intervals over time",
                     value = "credibilityIntervalsOverTimeTab",
                     HTML("<br>"),
                     plotOutput("plotTime") %>% withSpinner(color = "#20c997"),
                     tags$br(),
                     tags$br(),
                     fluidRow(
                       column(2,
                              textInput("xAxisLabel", label = "X-Axis title", value = "Time"),
                              numericInput(inputId = "sizeTextX", label = "Font size x-axis title", value = 24),
                              numericInput(inputId = "sizeAxisX", label = "Font size x-axis", value = 18),
                              numericInput("xmin", "Lower x limit", 
                                           value = defaultInputsForUI()$xmin),
                              numericInput("xmax", "Upper x limit", 
                                           value = defaultInputsForUI()$xmax)
                              ),
                       column(2,
                              textInput("yAxisLabel", label = "Y-Axis title", value = "Estimate"),
                              numericInput(inputId = "sizeTextY", label = "Font size y-axis title", value = 24),
                              numericInput(inputId = "sizeAxisY", label = "Font size y-axis", value = 18),
                              numericInput("ymin", "Lower y limit",
                                           value = defaultInputsForUI()$ymin),
                              numericInput("ymax", "Upper y limit",
                                           value = defaultInputsForUI()$ymax),
                              ),
                       column(4,
                              colourInput(inputId = "colorL",
                                          label = "Color line",
                                          value = rgb(0, 35 / 255, 80 / 255, alpha = 0.6)),
                              sliderInput("alphaL", "Transparency lines", min = 0, max = 1, value = 0.9),
                              tags$br(),
                              tags$br(),
                              colourInput(inputId = "colorU",
                                          label = "Color uncertainty region",
                                          value = rgb(0, 35 / 255, 80 / 255, alpha = 0.6)),
                              sliderInput("alphaU", "Transparency uncertainty region", min = 0, max = 1, value = 0.1)
                              ),
                       column(4,
                              checkboxInput("secAxis", "Add new secondary axis to existing plot", value = F),
                              radioButtons("deriv", "Type", choices = c("Absolute values" = "1", "First derivate" = "2")), 
                              sliderInput("modCredInt",
                                          "Credibility interval:",
                                          min = 0,
                                          max = .99,
                                          value = .8,
                                          step = .05),
                              tags$br(),
                              tags$br(),
                              selectizeInput("credIntTimePlot", "Select Models / Individuals", choices = NULL),
                              actionButton("newPlot", "New Plot"),
                              actionButton("addPlot", "Add Plot"),
                              actionButton("exportCredIntTimePlot", "Export Plot")
                       )
                     )
                   ),
                   tabPanel(
                     "Shift detection",
                     value = "shiftTime",
                     HTML("<br>"),
                     fluidRow(
                       column(4,
                              pickerInput("savedModelsShift",
                                          "Select Models / Individuals",
                                          choices = NULL, multiple = TRUE,
                                          options = list(`actions-box` = TRUE))
                              ),
                       column(3,
                              radioButtons(
                                "shiftTimeAbsOrRel",
                                "Shift detection:",
                                choices = c("absolute", "relative"),
                                selected = "absolute"),
                              radioButtons(
                                "slope",
                                "Shift detection type:",
                                choices = c("difference", "slope"),
                                selected = "difference")
                              ),
                       column(3,
                              numericInput("shiftTimeThreshold", 
                                           "Shift time threshold:", value = 0),
                              sliderInput("shiftTimeProb",
                                          "Shift time probability:",
                                          min = 0.5, max = 0.999, 
                                          value = 0.5, step = 0.001)
                              )
                     ),
                     tags$br(),
                     verbatimTextOutput("shiftTimePoints") %>% withSpinner(color = "#20c997")
                   ),
                   tabPanel(
                     "Time point estimates",
                     value = "timePointEstimatesTab",
                     tags$br(),
                     fluidRow(
                       column(4,
                              pickerInput("savedModelsTime", "Select Models / Individuals", choices = NULL, multiple = TRUE,
                                          options = list(`actions-box` = TRUE)),
                              tags$br(),
                              actionButton("estSpecTimePoint", "Estimate")
                       ),
                       column(4,
                              numericInput("from", "From", defaultInputsForUI()$from),
                              numericInput("to", "To", defaultInputsForUI()$to),
                              numericInput("by", "By", defaultInputsForUI()$by)
                              ),
                       column(4,
                              tags$br(),
                              actionButton("exportTimePointEst", "Export Time Point Estimates")
                              )
                     ),
                     tags$br(),
                     verbatimTextOutput("timePointEstimates")
                   ),
                   tabPanel(
                     "Estimates for user defined interval",
                     value = "userIntervalTab",
                     HTML("<br>"),
                     fluidRow(
                       column(4,
                              pickerInput("savedModelsUserDefined", "Select Models / Individuals", choices = NULL, multiple = TRUE,
                                          options = list(`actions-box` = TRUE))
                              ),
                       column(4,
                              radioButtons("typeEstUser", "Type", 
                                           choices = c("Absolute Mean + SD" = "1", "Total turnover Mean + SD" = "2"))
                              ),
                       column(4,
                              numericInput("from2", "From", value = defaultInputsForUI()$from2),
                              numericInput("to2", "To", value = defaultInputsForUI()$to2)
                              )
                       
                     ),
                     tags$br(),
                     verbatimTextOutput("userDefined") %>% withSpinner(color ="#20c997")
                   )
                 )
               ),
               sidebarPanel(
                 width = 2,
                 tags$h5("Save Model"),
                 fluidRow(
                   column(width = 8,
                          textInput("modelName", label = NULL, placeholder = "model name")),
                   column(width = 4,
                          actionButton("saveModel", "Save"))
                 ),
                 HTML("<br>"),
                 tags$h5("Load Model"),
                 fluidRow(
                   column(width = 8,
                          selectInput("savedModels", label = NULL, choices = NULL)),
                   column(width = 4,
                          actionButton("loadModel", "Load"))
                 ),
                 tags$br(),
                 downloadModelUI("modelDownload", "Download Model"),
                 uploadModelUI("modelUpload", "Upload Model")
               )
             )
             ),
    # RESIDING TIME ------------------------------------------------------------------------------------------------------
    tabPanel("Residence time",
             sidebarLayout(
               sidebarPanel(
                 width = 2,
                 HTML("<h5>Upload</h5><br>"),
                 selectInput(
                   "stayTimeDataSelect",
                   "File type",
                   choices = c("xlsx", "csv"),
                   selected = "xlsx"
                 ),
                 conditionalPanel(
                   condition = "input.stayTimeDataSelect == 'csv'",
                   div(
                     style = "display: inline-block;horizontal-align:top; width: 80px;",
                     textInput("colseparatorStay", "column separator:", value = ",")
                   ),
                   div(
                     style = "display: inline-block;horizontal-align:top; width: 80px;",
                     textInput("decseparatorStay", "decimal separator:", value = ".")
                   )
                 ),
                 helpText("The first row in your file needs to contain variable names."),
                 fileInput("stayTimeData", ""),
                 HTML("<hr>"),
                 HTML("<h5>Generate data</h5>"),
                 actionButton("loadStayTimeData", "Load Example Data"),
                 HTML("<hr>"),
                 HTML("<h5>Estimation</h5>"),
                 actionButton("stayingTime", "Estimate Residence Time")
               ),
               mainPanel(
                 HTML("<h5>Data</h5>"),
                 helpText("Two columns with mean and standard deviation; each row stands for unique site."),
                 matrixInput(
                   inputId = "stayTimeMatrix",
                   inputClass = "matrix-input-rownames",
                   class = "numeric",
                   value = matrix(ncol = 2, dimnames = list(c(""),  c(
                     "siteMeans", "siteSigma"
                   ))),
                   #copy = TRUE,
                   #paste = TRUE,
                   cols = list(
                     names = TRUE,
                     extend = TRUE,
                     delta = 1,
                     editableNames = TRUE
                   ),
                   rows = list(
                     names = FALSE,
                     editableNames = TRUE,
                     extend = TRUE
                   )
                 ),
                 conditionalPanel(condition = "input.stayingTime",
                                  HTML("<h3>Results</h3>")),
                 verbatimTextOutput("estimatedStayTimes"),
                 tags$br(),
                 actionButton("exportStayTimeDat", "Export estimated residence time lengths")
               )
             )
             ),
    # ISOTOPIC VALUES ---------------------------------------------------------------------------------------------
    tabPanel("Measurement simulation",
             sidebarLayout(
               sidebarPanel(
                 width = 2,
                 HTML("<h5>Upload</h5><br>"),
                 # DATASET
                 selectInput(
                   "filetypeHistData",
                   "File type",
                   choices = c("xlsx", "csv"),
                   selected = "xlsx"
                 ),
                 conditionalPanel(
                   condition = "input.filetypeHistData == 'csv'",
                   div(
                     style = "display: inline-block;horizontal-align:top; width: 80px;",
                     textInput("colseparatorHistData", "column separator:", value = ",")
                   ),
                   div(
                     style = "display: inline-block;horizontal-align:top; width: 80px;",
                     textInput("decseparatorHistData", "decimal separator:", value = ".")
                   )
                 ),
                 helpText("The first row in your file needs to contain variable names."),
                 fileInput("fileHistData", ""),
                 HTML("<hr>"),
                 HTML("<h5>Generate Data</h5><br>"),
                 # EXAMPLE DATA
                 actionButton("loadHistData", "Load Example Data"),
                 
                 HTML("<hr>"),
                 # SPECIFICATION
                 HTML("<h5>Specification</h5>"),
                 
                 pickerInput(
                   inputId = "timeVarHist",
                   label = "Time Variable:",
                   choices = character(0),
                   options = list(
                     "actions-box" = FALSE,
                     "none-selected-text" = 'No variables selected',
                     "max-options" = 1
                   ),
                   multiple = TRUE
                 ),
                 HTML("<br>"),
                 pickerInput(
                   inputId = "boneVarsHist",
                   label = "Variables for elements:",
                   choices = character(0),
                   options = list(
                     `actions-box` = FALSE,
                     size = 10,
                     `none-selected-text` = "No variables selected"
                   ),
                   multiple = TRUE
                 ),
                 HTML("<br>"),
                 pickerInput(
                   inputId = "meanVarHist",
                   label = "Measurement mean:",
                   choices = character(0),
                   options = list(
                     "actions-box" = FALSE,
                     "none-selected-text" = 'No variables selected',
                     "max-options" = 1
                   ),
                   multiple = TRUE
                 ),
                 HTML("<br>"),
                 pickerInput(
                   inputId = "sdVarHist",
                   label = "Measurement standard deviation:",
                   choices = character(0),
                   options = list(
                     "actions-box" = FALSE,
                     "none-selected-text" = 'No variables selected',
                     "max-options" = 1
                   ),
                   multiple = TRUE
                 ),
                 HTML("<br>"),
                 
                 actionButton("calcIsotopicValues", "Calculate Values")
               ),
               mainPanel(
                 HTML("<h5>Historic data</h5>"),
                 matrixInput(
                   inputId = "historicData",
                   inputClass = "matrix-input-rownames",
                   class = "numeric",
                   value = matrix(ncol = 5, dimnames = list(
                     c(""),  c("t", "bone1", "bone2", "mean", "sd")
                   )),
                   #copy = TRUE,
                   #paste = TRUE,
                   cols = list(
                     names = TRUE,
                     extend = TRUE,
                     delta = 1,
                     editableNames = TRUE
                   ),
                   rows = list(
                     names = FALSE,
                     editableNames = TRUE,
                     extend = TRUE
                   )
                 ),
                 conditionalPanel(condition = "input.calcIsotopicValues",
                                  HTML("<h3>Results</h3>")),
                 tableOutput("isotopicValues"),
                 verbatimTextOutput("quant"),
                 tags$br(),
                 actionButton("exportResultsDat", "Export Isotopic Values")
               )
             ))
    # STYLE of navbarPage ----
  ),
  # tags$head(
  #   tags$link(rel = "stylesheet", type = "text/css", href = "custom.css")
  # ),
  div(
    id = "header-right",
    # div(
    #   id = "logo-mpi",
    #   tags$a(
    #     href = "https://www.mpg.de/en",
    #     img(src = "MPIlogo.png", alt = "Supported by the Max Planck society"),
    #     target = "_blank"
    #   )
    # ),
    # div(
    #   id = "logo-isomemo",
    #   tags$a(
    #     href = "https://isomemo.com/",
    #     img(src = "IsoMemoLogo.png", alt = "IsoMemo"),
    #     target = "_blank"
    #   )
    # ),
    div(
      id = "further-help",
      tags$button(onclick = "window.open('https://isomemo.com','_blank');",
                  class = "btn btn-default",
                  "Further Help")
    ),
    div(id = "help",
        actionButton("getHelp", "?"))
  )
)
