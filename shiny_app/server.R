library(leaflet)
library(sf)
library(shiny)
library(dplyr)
library(RColorBrewer)
library(plotly)
library(patchwork)

server <- function(input, output, session) {
  
  output$line_tasas_plot <- renderPlot({
    # Start with the base plot
    tasas_plot <- base_plot
    
    # Dynamically add lines based on the selection
    selected_lines <- input$linesToShow
    
    # Check if any lines were selected
    if (length(selected_lines) == 0) {
      return(tasas_plot)
    }
    
    # Add each selected line to the plot
    for (line_name in selected_lines) {
      color_name <- line_colors[[line_name]] # Get the color for the line
      tasas_plot <- tasas_plot +
        geom_line(data = tasas_data, aes(x = !!sym("Año"), y = !!sym(line_name), color = I(color_name))) +
        geom_point(data = tasas_data, aes(x = !!sym("Año"), y = !!sym(line_name), color = I(color_name)))
    }
    
    # Set color scale to use the line colors
    tasas_plot <- tasas_plot + 
      scale_color_identity()
    
    # Return the plot with lines and points
    tasas_plot
  })
  
    output$dynamic_map <- renderLeaflet({
      # Retrieve the map for the selected year
      map_list[[as.character(input$selected_year)]]
    })
  
  output$year_debug <- renderText({
    paste("Selected year:", input$selected_year_2)
  })
  
  reactive_event_data <- reactive({
    # Generate the key based on selected year and first selected event
    # Note: This assumes 'selected_events' is a list of event type strings
    key <- paste(gsub(",", "", input$selected_year_2), input$selected_events[1], sep = "_")
    
    # Retrieve the preprocessed data
    preprocessed_data[[key]]
    })
  
  output$bubble_map <- renderLeaflet({
    req(reactive_event_data()) # This ensures that the code waits for the reactive data to be available
    data_to_plot <- reactive_event_data()
    
    leaflet(data = data_to_plot) %>%
      addTiles() %>%
      addCircles(
        lng = ~longitude,
        lat = ~latitude,
        weight = 0.3,  # Weight of the circle border
        radius = ~radius_test, # Use the precomputed radius values
        popup = ~paste("<b>Municipio:</b> ", nomgeo,
                       "<br/><b>", nombre_evento, "</b> ", value, sep=""),
        fillOpacity = 0.7,
        fillColor = ~global_qpal(hvdo_ent), # Use the quantile-based colors for the fill
        color = "black", # Set the border color to black
        stroke = TRUE # Ensure that the circle border is drawn
      ) %>%
      setView(
        lng = mean_lng, # Use the mean longitude and latitude
        lat = mean_lat,
        zoom = 4.1
      ) %>%
      addLegend(
                position = "bottomleft",
                pal = global_qpal, 
                values = ~hvdo_ent, 
                title = "Núm. de eventos <br/><b> por estado",
                labels = etiquetas,
                labFormat = labelFormat(suffix = " ", big.mark = ","))
  })
  
  filtered_data <- reactive({
    tasa_cracks_data_log[tasa_cracks_data_log$año == input$yearInput, ]
  })
  
  output$statePlot <- renderPlot({
    ggplot(tasa_cracks_data_log[tasa_cracks_data_log$año == input$yearInput, ], 
           aes(x = estado, y = tasa_hom_arm, fill = estado)) +
      geom_bar(stat = "identity") +
      scale_fill_manual(values = darjeeling_palette) +
      theme_minimal() +
      theme(legend.position = "none",  # Remove legend
            axis.text.x = element_text(angle = 90, vjust = 0.5),  # Rotate x-axis ticks
            axis.title.x = element_blank(),  # Optionally remove x-axis title
            axis.text.y = element_text(hjust = 1)) +
      labs(title = paste("Tasa de homicidios por arma de fuego y entidad federativa", input$yearInput),
           y = "Tasa de homicidios")
  })
  
  output$plot_output <- renderPlot({
    if (input$selected_dataset == "enfrentamientos") {
      # Display the combined plot for enfrentamientos
      combined_plot
    } else if (input$selected_dataset == "detenciones") {
      # Display the combined plot for detenciones
      combined_plot_cracks
    }
  })
  
  output$pp2_plot <- renderPlotly({
    # Return the plotly plot
    pp2
  })
  
  output$heatmap_output <- renderPlotly({
    # Assuming heat is your heatmaply object
    heat
  })
  
  #output$table_output <- renderUI({
  # Create the styled, scrollable table
  #styled_table <- kable(results, caption = "Regression Results", align = 'c') %>%
  #kable_styling(bootstrap_options = c("striped", "hover", "condensed"), 
  #full_width = F) %>%
  # scroll_box(width = "100%", height = "500px")
  
  # Return the table as an HTML object
  #styled_table
  # })
  
  output$pp_cracks_plot <- renderPlotly({
    # Return the plotly plot
    pp_cracks
  })
  
      
  
}










