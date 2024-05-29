ui <- dashboardPage(
  dashboardHeader(title = ""),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Acerca de", tabName = "acerca", icon = icon("info-circle")),
      menuItem("Panorama general", tabName = "map", icon = icon("globe")),
      menuItem("Factores de la violencia", tabName = "violence_factors", icon = icon("balance-scale")),
      menuItem("Relaciones", tabName = "relaciones", icon = icon("chart-line")) # New menu item for "Relaciones"
    )
  ),
  dashboardBody(
    tabItems(
      tabItem(tabName = "acerca",
              fluidRow(
                box(
                  width = 12,
                  tags$div(
                    style = "font-size: 15px;",  # Adjust the font size as needed
                    h2("¡Bienvenidxs!", style = "text-align: center;font-size: 40px;"),  # Larger font size for the title
                    tags$p("En este sitio encontrarás herramientas gráficas para entender la crisis de violencia relacionada 
         con el crimen organizado que ha atravesado México en las últimas dos décadas. 
         Este es un proyecto de visualización de datos creado por Silvio Mauricio Jurado Zenteno, 
         estudiante de El Colegio de México, para fines académicos y de divulgación científica."),
                    tags$p(
                           "La pregunta principal que guía el proyecto es: ¿cómo ha evolucionado la dinámica de la violencia 
         relacionada con el crimen organizado tanto en intensidad como en su distribución geográfica 
         a partir de la llamada guerra contra el narcotráfico hasta la actualidad?. 
         En ese sentido, nos interesa saber también cuáles han sido los factores determinantes 
         detrás de dicha dinámica a lo largo del tiempo, así como los mecanismos a través de los cuales dichos factores operan."),
                    tags$p("El sitio está organizado en tres secciones adicionales a esta sección introductoria: 
         la primera provee un panorama general de la evolución de la violencia relacionada con el crimen organizado
         en los últimos años y el cambio en su composición geográfica; 
         la segunda se propone explorar algunas potenciales causas catalizadoras de dicha situación, 
         con un enfoque particular en las respuestas del Estado a la problemática; 
         la tercera observa algunas correlaciones entre los cambios en las respuestas estatales y 
         los cambios en los niveles de violencia a nivel estatal."),
                    tags$p(style = "text-align: center; font-size: 18px;",  # Larger and bold font size for the closing statement
                           "¡Esperamos que tengas una experiencia informativa!")
                  )
                )
              )
      ),
      tabItem(tabName = "map",
              fluidPage(
                sidebarLayout(
                  sidebarPanel(
                    checkboxGroupInput("linesToShow",
                                       "Selecciona las líneas:",
                                       choices = c("Homicidios por arma de fuego" = "tasa_hom_arm",
                                                   "Homicidios totales" = "tasa_hom_gen",
                                                   "Homicidios de hombres" = "Hombres",
                                                   "Homicidios de mujeres" = "Mujeres"),
                                       selected = c("tasa_hom_gen"))
                  ),
                  mainPanel(
                    plotOutput("line_tasas_plot")
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Evolución de los homicidios a nivel nacional",
                  width = 12,
                  "Los gráficos anteriores fueron elaborados con los datos de vitalidad del INEGI y estimaciones poblacionales de la CONAPO. 
                  A partir de ellos observamos una caída inicial en las tasas de homicidio entre 1992 y 2007. 
                  La pronunciada tendencia a la alza entre 2007 y 2011 coinciden con el inicio de la llamada guerra contra el narcotráfico
                  emprendida por el expresidente Felipe Calderón. Posteriormente, las tasas de homicidio caen de 2011 hasta 2014 para volver a subir y alcanzar un máximo en 2018.
                  Desde ese año, la tasa de homicidios ha tenido una ligera tendencia a la baja, pero se mantiene por encima de años anteriores.",
                  
                  tags$p("Respecto de la tasa de homicidios cometidos con armas de fuego, 
                  la cual puede considerarse como proxy de la tasa de homicidios relacionados con el crimen organizado,
                  podemos notar que, aunque de menor nivel, sigue un patrón similar a las tasas de homicidio del primer gráfico. 
                  El patrón se repite si nos enfocamos en solo hombres o solo mujeres.")
                )
              ),
              fluidRow(
                box(
                  width = 4,
                  sliderInput("selected_year", 
                              "Año", 
                              min = min(homicidios_data$año), 
                              max = max(homicidios_data$año), 
                              value = min(homicidios_data$año),
                              sep = "", 
                              step = 1)
                ),
                box(
                  title = "Tasa de homicidios vinculados al CO por estado",
                  width = 8,
                  leafletOutput("dynamic_map")
                )
              ),
              fluidRow(
                box(
                  title = "Homicidios vinculados al crimen organizado",
                  width = 12,
                  "El mapa anterior fue creado a partir de datos de la llamada 'base oculta' publicada por la organización Data Cívica, 
                  la cual contiene información que el Estado no ha hecho pública sobre una serie de eventos relacionados al crimen organizado, 
                  entre los cuales están las agresiones de grupos delincuenciales a autoridades, enfrentamientos 
                  entre autoridades y dichos grupos, enfrentamientos entre organizaciones criminales y ejecuciones realizadas por las mismas. 
                  En este mapa nos enfocamos en la última categoría."
                )
              ),
              
              fluidRow(
              # Sidebar with a slider and checkboxes
              sidebarLayout(
                sidebarPanel(
                    # Slider for selecting the year
                    box(
                      width = 12, 
                      sliderInput("selected_year_2",
                                  "Año:",
                                  min = 2006, # Assuming 'years' is defined in your global.R
                                  max = 2020,
                                  value = 2010, # Default value
                                  step = 1,
                                  ticks = FALSE,
                                  sep = ""# Set to NULL to allow only specific values
                      )
                    ),
                    
                    selectInput("selected_events",
                                "Selecciona un evento:",
                                choices = event_type_labels,
                                selected = event_types[3]) # Default selection
                    
                  ),
                  # Main panel for displaying the map
                mainPanel(
                  box(
                    # Output for the Leaflet map
                    width = 12,
                    title = "Eventos relacionados al crimen organizado por municipio",
                    leafletOutput("bubble_map")
                  )
                )
              ),
              fluidRow(
                box(
                  title = "Eventos relacionados al crimen organizado",
                  width = 12,
                  "De forma similar al primer mapa, la información utilizada para el creado arriba se obtuvo a partir 
                  de la 'base oculta' y la llamada 'base Presidencia' a la cual tuvo acceso el CIDE y que ha hecho pública desde su obtención. 
                  Se presume que ambas bases son parte de una misma serie de registros que el Estado hace sobre eventos relacionados al crimen organizado 
                  y que, hasta el momento, no ha hecho pública."
                  # Replace the text above with your actual information content.
                )
              ),
              # Slider for selecting the year
              fluidRow(
                box(
                  width = 12,
                  sliderInput("yearInput", "Año:",
                              min = min(tasa_cracks_data_log$año), 
                              max = max(tasa_cracks_data_log$año), 
                              value = min(tasa_cracks_data_log$año),
                              step = 1, sep = "")
                )
              ),
              # Plot output
              fluidRow(
                box(
                  width = 12,
                  plotOutput("statePlot", height = "500px")
                )  
              ),
              # Information box
              fluidRow(
                box(
                  title = "Evolución de la violencia a nivel estatal",
                  width = 12,
                  "El gráfico anterior fue creado a partir de los datos de vitalidad del INEGI mencionados anteriormente, 
                  así como por las estimaciones poblacionales de la CONAPO "
                )
              )
            )
      ),
    # New "Factores de la violencia" Tab
    tabItem(tabName = "violence_factors",
            fluidRow(
              box(
                title = "Factores de la violencia",
                width = 12,
                "En esta sección nos concentraremos en dos grandes y plausibles determinantes de las dinámicas de violencia: 
                las acciones punitivas del Estado en contra de los grupos criminales y las disputas entre los mismos. 
                El objetivo es observar si las tendencias de la violencia siguen algún patrón similar o responsivo a dichos determinantes.
                Comenzaremos contrastando la evolución de la tasa de homicidios con arma de fuego con enfrentamientos, detenciones y 
                abatimientos que las organizaciones estatales de alto nivel han experimentado con la delincuencia organizada. 
                Estos datos fueron obtenidos a través de la página del Programa de Política de Drogas del CIDE, 
                los cuales fueron a su vez recabados mediante consultas de información al Sistema de Transparencia."
          )
        ),
        fluidRow(
          box(
            selectInput("selected_dataset", "Selecciona la gráfica",
                        choices = c("Homicidios por arma de fuego - Enfrentamientos" = "enfrentamientos",
                                    "Homicidios por arma de fuego - Detenciones" = "detenciones")),
            width = 12
          )
        ),
        fluidRow(
          box(
            plotOutput("plot_output", height = "900px"),
            width = 12
          )
        ),
        fluidRow(
          box(
            title = "Fragmentación de las disputas criminales",
            width = 12,
            "El gráfico anterior fue construido a partir de datos del Uppsala Conflict Data de la Universidad de Uppsala, 
            quienes dan seguimiento a los conflictos armados alrededor del mundo. Así, en el gráfico se muestran los distintos grupos 
            que han estado en pugna en nuestro país desde 2007 a 2018, así como el número de muertes que sus enfrentamientos han dejado.
            De particular interés es la existencia de una tendencia hacia la pulverización de conflictos entre distintos y nuevos grupos criminales, 
            posiblemente como respuesta a la fragmentación de grupos más grandes derivados tanto de
            captura de las cabecillas de los grupos así como por dinámicas de competencia interna entre los mismos.  "

          )
        ),
        fluidRow(
          box(
            plotlyOutput("pp2_plot"),
            width = 12
              )
            )
          ),
          # "Relaciones" Tab
          tabItem(tabName = "relaciones",
                fluidRow(
                    box(
                      title = "Las respuestas del Estado y las dinámicas de la violencia",
                      width = 12,
                      "A partir de lo observado en los gráficos anteriores, 
                      es menester considerar cómo es que las estrategias de seguridad y 
                      los brotes de violencia interactúan entre sí. 
                      Particularmente, considerando que una importante parte 
                      de las respuestas estatales al crimen organizado se han basado 
                      en el descabezamiento de organizaciones criminales, 
                      querríamos ver si dicho enfoque tiene algún tipo de relación 
                     con cambios en la tasa de homicidios. 
                      Por lo tanto, tomamos de nuevo las variables de detenciones y 
                      abatimientos de miembros de grupos criminales de altos niveles de gobierno y 
                      los contrastamos con cambios en tasas de homicidio por armas de fuego."
                      # Add your introductory text here
                    )
                  ),
                  fluidRow(
                    box(
                      plotlyOutput("heatmap_output", height = "600px"),
                      width = 12
                    )
                  ),
                  fluidRow(
                    box(
                      title = "Relación entre el cambio en detenciones y cambio en violencia",
                      width = 12,
                      "A partir del mapa de calor, notamos que existe una correlación 
                      importante y positiva entre el cambio en las detenciones y abatimientos 
                      de miembros de grupos criminales y el aumento en la violencia, 
                      de modo que dicha relación nos sirve de punto de partida para determinar vínculos de causalidad.
                      Realizaremos un modelo sencillo de regresión de efectos fijos en dos direcciones (tiempo y unidad)
                      con errores estándar agrupados por estado para notar si dicha relación es significativa, así como la magnitud de su efecto."

                    )
                  ),
                # Insert the new fluidRow for the table here
               # fluidRow(
                  # box(
                    # title = "Título de la Tabla",  # Add your table title
                   # width = 12,
                   # htmlOutput("table_output")  # Output ID matching the server function

                fluidRow(
                  box(
                   plotlyOutput("pp_cracks_plot", height = "800px"),
                    width = 12   
                 )
                )
          )
     )
  )
)  
  
