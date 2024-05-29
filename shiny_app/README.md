# Shiny App: Violence and Organized Crime in Mexico

This directory contains an R Shiny app that provides graphical tools to understand the crisis of violence related to organized crime in Mexico over the past two decades. This is a data visualization project created by Héctor Santiago Bautista Aniceto and Silvio Mauricio Jurado Zenteno, students at El Colegio de México, for academic and scientific dissemination purposes.

## Project Description

The main question guiding this project is: How has the dynamics of violence related to organized crime evolved both in intensity and geographical distribution from the so-called war on drugs to the present? We are also interested in understanding the determining factors behind this dynamic over time, as well as the mechanisms through which these factors operate.

The site is organized into three additional sections besides this introductory section:
1. **General Overview**: Provides a general overview of the evolution of violence related to organized crime in recent years and changes in its geographical composition.
2. **Factors of Violence**: Explores some potential causes of this situation, with a particular focus on the state's responses to the issue.
3. **Relationships**: Observes some correlations between changes in state responses and changes in violence levels at the state level.

We hope you have an informative experience!

## Structure

- `ui.R`: Defines the user interface of the Shiny app.
- `server.R`: Contains the server logic of the Shiny app.
- `global.R`: Contains global objects and functions used by both `ui.R` and `server.R`.

## Prerequisites

Make sure you have the following R packages installed:

```r
install.packages("leaflet")
install.packages("sf")
install.packages("shiny")
install.packages("dplyr")
install.packages("stringr")
install.packages("shinydashboard")
install.packages("ggplot2")
install.packages("hrbrthemes")
install.packages("patchwork")
install.packages("gghighlight")
install.packages("readxl")
install.packages("tidyr")
install.packages("plotly")
install.packages("viridis")
install.packages("RColorBrewer")
install.packages("plm")
install.packages("reshape2")
install.packages("d3heatmap")
install.packages("heatmaply")
install.packages("shinyWidgets")
install.packages("wesanderson")
install.packages("knitr")
install.packages("DT")
install.packages("kableExtra")
```

## Running the App Locally

To run the Shiny app locally, open R or RStudio and set the working directory to the location of this folder. Then run the following command:

```r
library(shiny)
runApp()
```

## Running the App from GitHub
You can also run this Shiny app directly from GitHub using the `runGitHub` function from the `shiny` package. Use the following command in R:

```r
library(shiny)
runGitHub("SilvioMJZ_DataSciPortfolio", "your-username", subdir = "python_assignments/shiny_app")
```

Replace `"your-username"` with your GitHub username.

## License


