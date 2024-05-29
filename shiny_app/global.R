library(leaflet)
library(sf)
library(shiny)
library(dplyr)
library(stringr)
library(shinydashboard)
library(ggplot2)
library(hrbrthemes)
library(patchwork)
library(gghighlight)
library(readxl)
library(tidyr)
library(plotly)
library(viridis)
library(RColorBrewer)
library(plm)
library(reshape2)
library(d3heatmap)
library(heatmaply)
library(shinyWidgets)
library(wesanderson)
library(knitr)
library(DT)
library(kableExtra)

# Gráficos iniciales ----

tasah_arm <- read_excel("www/data_shiny/tasa_hom_arm_sex.xlsx")

#e41a1c
#377eb8
#4daf4a
#984ea3

tasas_data <- tasah_arm %>%
  select(Año, tasa_hom_arm, tasa_hom_gen, Hombres, Mujeres)

# You can define the aesthetics for each line here if they are complex and need to be reused
# Define the colors for each line
line_colors <- list(
  tasa_hom_arm = "#e41a1c",
  tasa_hom_gen = "#377eb8",
  Hombres = "#4daf4a",
  Mujeres = "#984ea3"
)

# Base plot with theme and labels, no lines yet
base_plot <- ggplot() + 
  theme_bw() +
  theme(
    axis.text.x = element_text(angle = 90, vjust = 0.5),
    panel.grid.major.x = element_blank(),
    panel.grid.minor.x = element_blank(),
    plot.title = element_text(hjust = 0.5),
    legend.position = "bottom"
  ) +
  geom_point( size=4.0, shape=20 ) +
  labs(
    title = "Tasas de homicidios a nivel nacional",
    x = "Año",
    y = "Homicidios por 100 mil habs."
  ) +
  scale_x_continuous(breaks = unique(tasas_data$Año)) 

# Mapa homicidios ----


# Load the shapefiles and data
mexico_shape <- st_read("www/data_shiny/map/00ent.shp") %>% 
  st_transform(4326)

mexico_mun <- st_read("www/data_shiny/map/00mun.shp") %>% 
  st_transform(4326)

homicidios_data <- read.csv("www/data_shiny/modificadas/base_oculta_shape.csv") %>% 
  mutate(cvegeo = str_pad(as.character(cvegeo), width = 2, side = "left", pad = "0"))

# Lowercase column names
colnames(mexico_shape) <- tolower(colnames(mexico_shape))
colnames(mexico_mun) <- tolower(colnames(mexico_mun))
colnames(homicidios_data) <- tolower(colnames(homicidios_data))

quantiles_hom <- quantile(homicidios_data$tasa_hom, probs = seq(0.1, 0.9, by = 0.1))
quantiles_hom

cortes <- c(min(homicidios_data$tasa_hom, na.rm = TRUE), 1.5, 3, 4, 6, 9, 14, 19, 30, max(homicidios_data$tasa_hom, na.rm = TRUE))

# Preprocess maps
map_list <- lapply(unique(homicidios_data$año), function(year) {
  homicidios_filtrados <- filter(homicidios_data, año == year)
  datos_combinados <- merge(mexico_shape, homicidios_filtrados, by.x = "cvegeo", by.y = "cvegeo")
  
  # Color palette
  color_pal <- colorBin(palette = "YlOrRd", domain = datos_combinados$tasa_hom, bins = cortes, na.color = "transparent")
  
  leaflet(data = datos_combinados) %>%
    addTiles() %>%
    setView(lng = -102.552784, lat = 23.634501, zoom = 4.1) %>%
    addPolygons(
    fillColor = ~color_pal(tasa_hom),
    fillOpacity = 0.8,
    color = "black",
    weight = 1,
    smoothFactor = 0.5,
    popup = ~paste("Entidad:", entidad, 
                   "<br><b>Año:</b>", año, 
                   "<br><b>Tasa de homicidios:</b>", round(tasa_hom, 2))
    ) %>%
    addLegend(pal = color_pal, 
              values = ~tasa_hom, 
              title = "Tasa de Homicidios",
              labFormat = labelFormat(suffix = ""))
  
})  

names(map_list) <- unique(homicidios_data$año)


# Mapa eventos ----

eventos_data <- read.csv("www/data_shiny/modificadas/modalidad_ent_mun.csv")

eventos_data$cve_ent <- str_pad(as.character(eventos_data$cve_ent), width = 2, side = "left", pad = "0")
eventos_data$cve_mun <- str_pad(as.character(eventos_data$cve_mun), width = 3, side = "left", pad = "0")
eventos_data$cvegeo <- paste0(eventos_data$cve_ent, eventos_data$cve_mun)

head(eventos_data)
head(mexico_mun)

# Join de df de eventos con shapefile
eventos_shp <- left_join(mexico_mun, eventos_data, by = c("cvegeo" = "cvegeo"))

# Checamos clase
class(eventos_shp)

#mexico_eventos <- mexico_shape %>%
  #left_join(eventos_shp, by = c("cve_ent" = "cve_ent.x"))#


eventos_shp <- eventos_shp %>%
  na.omit() 

global_qpal <- colorQuantile("YlOrRd", eventos_shp$hvdo_ent, n = 9)

# Calculamos cuantiles
n <- 9  
quantile_breaks <- quantile(eventos_shp$hvdo_ent, probs = seq(0, 1, length.out = n + 1), na.rm = TRUE)

# Asignamos labels a cuantiles
etiquetas <- sapply(1:n, function(i) {
  paste(formatC(quantile_breaks[i], format = "f", digits = 2), " - ",
        formatC(quantile_breaks[i + 1], format = "f", digits = 2))
})


# Aquí guardamos los datos requeridos para las funciones del server
preprocessed_data <- list()

# Definimos lista de años y eventos
years <- unique(eventos_shp$año)
years_to_include <- c(2006:2011, 2017:2020)
event_types <- c("ag_dir_mun", "ag_enf_mun", "hvdo_mun", "enf_mun")

event_type_labels <- c("Agresiones directas" = "ag_dir_mun", 
                       "Agresiones por enfrentamiento" = "ag_enf_mun", 
                       "HVDO" = "hvdo_mun", 
                       "Enfrentamientos" = "enf_mun")

# Preprocesamiento de datos para cada año y cada evento
for (year in years) {
  for (event_type in event_types) {
    key <- paste(year, event_type, sep = "_")
    filtered_data <- eventos_shp %>%
      filter(año == year, .data[[event_type]] > 0)
    
    if (nrow(filtered_data) == 0) {
      warning(paste("No data available for year", year, "and event type", event_type))
      next
    }
    
    filtered_data <- st_transform(filtered_data, 4326)
    
    centroids <- tryCatch({
      st_centroid(filtered_data)
    }, error = function(e) {
      warning(paste("Error in computing centroids for year", year, "and event type", event_type, ":", e$message))
      return(NULL)
    })
    
    if (is.null(centroids)) next
    
    coordinates <- st_coordinates(centroids)
    
    if (is.null(coordinates)) {
      warning(paste("Coordinates are NULL for year", year, "and event type", event_type))
      next
    }
    
    longitude <- coordinates[, "X"]
    latitude <- coordinates[, "Y"]
    
    radius_test <- filtered_data[[event_type]] * 100
    mean_lng <- mean(longitude, na.rm = TRUE)
    mean_lat <- mean(latitude, na.rm = TRUE)
    nomgeo <- filtered_data$nomgeo
    valor_evento <- filtered_data[[event_type]]
    nombre_evento <- names(event_type_labels)[event_type_labels == event_type]
    hvdo_ent <- filtered_data$hvdo_ent
    
    
    # Checar NULL
    if (any(sapply(list(longitude, latitude, radius_test, mean_lng, mean_lat, nomgeo, hvdo_ent), is.null))) {
      warning(paste("One of the list elements is NULL for key", key))
      next
    }
    
    
    preprocessed_data[[key]] <- list(
      longitude = longitude,
      latitude = latitude,
      radius_test = radius_test,
      mean_lng = mean_lng,
      mean_lat = mean_lat,
      nomgeo = nomgeo,
      value = valor_evento,
      nombre_evento = nombre_evento,
      hvdo_ent = hvdo_ent
      
    )
  }
}


# data_year <- eventos_shp %>%
# filter(año == 2010)#

# Calculate centroids of the geometries
#centroids <- st_centroid(data_year)
#centroids <- st_transform(centroids, 4326) # Transform to WGS 84 (lat/long)

# Añadir latitud y longitud
#data_year$longitude <- st_coordinates(centroids)[, "X"]
#data_year$latitude <- st_coordinates(centroids)[, "Y"]

# Calcular la media de latitud y longitud para el SetView
#mean_lng <- mean(data_year$longitude, na.rm = TRUE)
#mean_lat <- mean(data_year$latitude, na.rm = TRUE)

# Valores de radio para los círculos
#radius_test <- data_year$hvdo_mun * 100


# gráfico 7 estados ----

#Graph 6: 


# Global Script
# Assuming 'tasa_cracks_data_log' is a function that processes your data and does not depend on any user inputs
# Global Script
# Data Loading (replace this with your actual data loading code)
tasa_cracks_data_log <- read.csv("www/data_shiny/modificadas/tasa_cracks_estado_2007_2018_logs.csv")

# Prepare a Wes Anderson color palette
unique_entidades <- unique(tasa_cracks_data_log$estado)
num_entidades <- length(unique_entidades)
darjeeling_palette <- wes_palette("Darjeeling1", num_entidades, type = "continuous")



# You can now call this function in your server script, passing reactive values as arguments.


# líneas combinadas ----


enf_autoridades <- read.csv("www/data_shiny/modificadas/enf_autoridades.csv")

tasah_arm_filtered <- tasah_arm %>% 
  filter(!Año %in% c(2020, 2021, 2022))

# First Plot
plot_tasa_arm <- ggplot(tasah_arm_filtered, aes(x = Año, y = tasa_hom_arm)) +
  geom_line(linewidth = 0.4, color = '#4393C3') +
  theme_bw() +
  labs(title = "Tasa de Homicidios por Arma de Fuego", x = "", y = "") +
  scale_x_continuous(breaks = unique(tasah_arm$Año)) +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5),
        panel.grid.major.x = element_blank(),
        panel.grid.minor.x = element_blank())

# Reshape dataset
long_enf_aut <- enf_autoridades %>% 
  pivot_longer(cols = c(enfren, tot_eventos_pf), names_to = "variable", values_to = "value")

# Second Plot (SEDENA vs. Crimen Organizado)
plot_sedena <- ggplot(subset(long_enf_aut, variable == "enfren"), aes(x = año, y = value)) +
  geom_line(linewidth = 0.4, color = '#FFA07A') +
  theme_bw() +
  labs(title = "Enfrentamientos SEDENA vs. Crimen Organizado", x = "", y = "") +
  scale_x_continuous(limits = c(2000, max(long_enf_aut$año, na.rm = TRUE)),
                     breaks = seq(2000, max(long_enf_aut$año, na.rm = TRUE), by = 1)) +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5),
        panel.grid.major.x = element_blank(),
        panel.grid.minor.x = element_blank())

# Third Plot (Policía Federal vs. Crimen Organizado)
plot_policia_federal <- ggplot(subset(long_enf_aut, variable == "tot_eventos_pf"), aes(x = año, y = value)) +
  geom_line(linewidth = 0.4, color = '#20B2AA') +
  theme_bw() +
  labs(title = "Enfrentamientos Policía Federal vs. Crimen Organizado", x = "Año", y = "") +
  scale_x_continuous(limits = c(2000, max(long_enf_aut$año, na.rm = TRUE)),
                     breaks = seq(2000, max(long_enf_aut$año, na.rm = TRUE), by = 1)) +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5),
        panel.grid.major.x = element_blank(),
        panel.grid.minor.x = element_blank())

# Combine the plots
combined_plot <- plot_tasa_arm / plot_sedena / plot_policia_federal

# Display the combined plot
combined_plot

# Lines 2 ----

cracks <- read.csv("www/data_shiny/modificadas/cracks_tnacional_2007_2018.csv")

tasah_arm_cracks <- tasah_arm %>% 
  filter(!Año %in% c(2000, 2001, 2002, 2003, 2004, 2005, 2006, 2019, 2020, 2021, 2022))

# First Plot
plot_tasa_arm <- ggplot(tasah_arm_cracks, aes(x = Año, y = tasa_hom_arm)) +
  geom_line(linewidth = 0.4, color = '#4393C3') +
  theme_bw() +
  labs(title = "Tasa de Homicidios por Arma de Fuego", x = "", y = "") +
  scale_x_continuous(breaks = unique(tasah_arm_cracks$Año)) +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5),
        panel.grid.major.x = element_blank(),
        panel.grid.minor.x = element_blank())

# Reshape dataset
long_cracks <- cracks %>% 
  pivot_longer(cols = c(tot_crack_sedena, tot_crack_pf, tot_crack_semar), names_to = "variable", values_to = "value")

# Second Plot (SEDENA vs. Crimen Organizado)
plot_crack_sedena <- ggplot(subset(long_cracks, variable == "tot_crack_sedena"), aes(x = año, y = value)) +
  geom_line(linewidth = 0.4, color = '#FFA07A') +
  theme_bw() +
  labs(title = "SEDENA vs. Crimen Organizado", x = "", y = "") +
  scale_x_continuous(limits = c(2007, max(long_cracks$año, na.rm = TRUE)),
                     breaks = seq(2007, max(long_cracks$año, na.rm = TRUE), by = 1)) +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5),
        panel.grid.major.x = element_blank(),
        panel.grid.minor.x = element_blank())

# Third Plot (Policía Federal vs. Crimen Organizado)
plot_crack_pf <- ggplot(subset(long_cracks, variable == "tot_crack_pf"), aes(x = año, y = value)) +
  geom_line(linewidth = 0.4, color = '#20B2AA') +
  theme_bw() +
  labs(title = "Policía Federal vs. Crimen Organizado", x = "Año", y = "") +
  scale_x_continuous(limits = c(2007, max(long_cracks$año, na.rm = TRUE)),
                     breaks = seq(2007, max(long_cracks$año, na.rm = TRUE), by = 1)) +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5),
        panel.grid.major.x = element_blank(),
        panel.grid.minor.x = element_blank())

# Third Plot (Policía Federal vs. Crimen Organizado)
plot_crack_semar <- ggplot(subset(long_cracks, variable == "tot_crack_semar"), aes(x = año, y = value)) +
  geom_line(linewidth = 0.4, color = '#20B2AA') +
  theme_bw() +
  labs(title = "SEMAR vs. Crimen Organizado", x = "Año", y = "") +
  scale_x_continuous(limits = c(2007, max(long_cracks$año, na.rm = TRUE)),
                     breaks = seq(2007, max(long_cracks$año, na.rm = TRUE), by = 1)) +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5),
        panel.grid.major.x = element_blank(),
        panel.grid.minor.x = element_blank())

# Combine the plots
combined_plot_cracks <- plot_tasa_arm / plot_crack_sedena / plot_crack_pf / plot_crack_semar

# Display the combined plot
combined_plot_cracks

# Assuming combined_plot and combined_plot_cracks are defined and are static



# Bubble chart 1 ----

conflicts <- read.csv("www/data_shiny/modificadas/uppsala_conflicts.csv")

# Prepare the data
conflict_data <- conflicts %>%
  count(dyad_name, year) %>%
  rename(total_count = n)

# Create the bubble chart
p <- conflict_data %>%
  ggplot(aes(x = year, y = total_count, size = total_count, text = paste("Conflicto:", dyad_name, "\nOcurrencias:", total_count, "\nAño:", year), color = dyad_name)) +
  geom_point(alpha = 0.7) +
  scale_size(range = c(0.1, 20), name = "Total Count") +
  scale_color_viridis(discrete = TRUE) +  # Use viridis color scale for discrete categories
  scale_y_continuous(limits = c(0, 1200)) +  # Set y-axis limits
  theme_ipsum() +
  theme(legend.position = "none", axis.text.x = element_text(angle = 90, vjust = 0.5)) +
  labs(x = "Año", y = "Total de Ocurrencias")

# Turn ggplot interactive with plotly
pp <- ggplotly(p, tooltip = "text")
pp

# Bubble chart  2 ----

conflicts_dyad <- read.csv("www/data_shiny/modificadas/uppsala_conflicts_nodyad.csv")


# Get a list of unique combined_names
unique_combined_names <- unique(conflicts_dyad$combined_name)

# Create a Spectral color palette
spectral_palette <- colorRampPalette(brewer.pal(12, "Paired"))(length(unique_combined_names))

# Create the bubble chart with Spectral colors
p2 <- conflicts_dyad %>%
  ggplot(aes(x = year, y = high_fatality_estimate, size = high_fatality_estimate, text = paste("Conflicto:", combined_name, "\nFatalidades:", high_fatality_estimate, "\nAño:", year), color = combined_name)) +
  geom_point(alpha = 0.7) +  # Increased transparency
  scale_size(range = c(0.1, 20), name = "Fatalidades") +
  scale_color_manual(values = setNames(spectral_palette, unique_combined_names)) +
  scale_y_continuous(limits = c(0, 6000)) +
  scale_x_continuous(breaks = unique(conflicts_dyad$year)) +  # Every year as tick
  theme_ipsum() +
  theme(
    legend.position = "none",
    axis.text.x = element_text(angle = 90, vjust = 0.5),
    panel.grid.major.x = element_line(color = "grey", linewidth = 0.5),  # X-axis gridlines
    panel.grid.major.y = element_line(color = "grey", linewidth = 0.5)   # Y-axis gridlines
  ) +
  labs(x = "Año", y = "Fatalidades")

# Turn ggplot interactive with plotly
pp2 <- ggplotly(p2, tooltip = "text") %>%
  layout(height = 800)  # Adjust height as needed



#  bubble regression ----

p_cracks_log <- tasa_cracks_data_log %>%
  arrange(desc(cambio_tasa)) %>%
  mutate(text = paste("Estado: ", estado, "\nTasa de homicidios: ", tasa_hom_arm,
                      "\nAño: ", año, "\nDetenciones y abatimientos: ", total_cracks,
                      "\nCambio en tasa de homicidios: ", cambio_tasa,
                      "\nCambio en detenciones y abatimientos: ", cambio_log_total_cracks, sep="")) %>%
  ggplot(aes(x=cambio_log_total_cracks, y=cambio_tasa, size = cambio_tasa, fill = estado, text=text)) +
  geom_point(alpha=0.5, shape=21, stroke=0.1) +  # Shape 21 is a filled circle with border; stroke controls the border size
  geom_smooth(method="lm", formula = y~log(x), se=FALSE, color="black") +  # Add a regression line without confidence interval
  scale_size(range = c(0.4, 8), name="Cambio Tasa") +
  scale_color_viridis(discrete=TRUE, guide=FALSE) +
  theme_ipsum() +
  theme(plot.title = element_text(family = "Helvetica", face = "light", size = (13)), legend.position="none") +
  labs(title= "Detenciones y abatimientos vs. tasa de homicidios",
       x = "Cambio en Log de Detenciones y Abatimientos",
       y = "Cambio en tasa de homicidios",
       caption = "Fuente: Datos hipotéticos")

# Turn ggplot interactive with plotly
pp_cracks <- ggplotly(p_cracks_log, tooltip="text")
pp_cracks 


#  heatmap ----

selected_data <- tasa_cracks_data_log %>%
  select(log_total_cracks, cambio_log_total_cracks, log_tot_crack_semar, cambio_crack_semar, log_tot_crack_sedena, cambio_log_tot_crack_sedena, log_tot_crack_pf, cambio_log_tot_crack_pf, tasa_hom_arm, cambio_tasa)

correlation_matrix <- cor(selected_data, use = "complete.obs")

heat <- heatmaply(correlation_matrix, 
                     dendrogram = "none",
                      xlab = "", ylab = "", 
                      main = "Matriz de correlaciones",
                  margins = c(60,100,40,20),
                  grid_color = "white",
                  grid_width = 0.00001,
                  titleX = FALSE,
                  hide_colorbar = FALSE,
                  branches_lwd = 0.1,
                  fontsize_row = 5, fontsize_col = 5,
                  labCol = colnames(correlation_matrix),
                  labRow = rownames(correlation_matrix),
                  heatmap_layers = theme(axis.line=element_blank())
                   )

heat





#  tabla regresión fe ----


# Replace 'path/to/your/file.txt' with the actual path to your text file
results <- read.delim("www/data_shiny/modificadas/reg_fe_cracks.txt", header = TRUE)


# Creating a table with kable
kable_table <- kable(results, caption = "Regression Results", align = 'c')

# Creating an interactive table
datatable(results, options = list(pageLength = 32, autoWidth = TRUE))





