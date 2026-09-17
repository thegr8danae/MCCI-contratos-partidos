# =============================================================================
# 01_carga_datos.R — Importar y revisar el dataset original
# =============================================================================
# Generado con ayuda de Claude (Anthropic), junio 2026.
# Prompt: "Crea 8 scripts R autocontenidos para clasificación de partidos
# políticos a partir de características del proveedor — proyecto MCCI"
#
# Ejecutar desde la raíz del proyecto:
#   Rscript scripts/01_carga_datos.R
# =============================================================================

set.seed(123)

library(readr)
library(dplyr)
library(janitor)
library(lubridate)

# Ajustar WD si se ejecuta desde el directorio scripts/
if (grepl("scripts$", getwd())) setwd("..")

# Directorio de salida
if (!dir.exists("outputs")) dir.create("outputs")

# Ruta al CSV — producción, datos/ o caché de desarrollo en notebooks/
ruta_csv <- if (file.exists("./data/contratos_montos.csv")) {
  "./data/contratos_montos.csv"
} else if (file.exists("./datos/contratos_montos.csv")) {
  "./datos/contratos_montos.csv"
} else {
  "./notebooks/contratos_montos.csv"
}

cat(sprintf("Cargando datos desde: %s\n", ruta_csv))

# CONSERVADO: clean_names() de janitor para nombres homogéneos,
#             ymd() de lubridate para parseo de fechas, costo a numérico
datos_raw <- read_csv(
  ruta_csv,
  locale       = locale(encoding = "UTF-8"),
  show_col_types = FALSE
) |>
  clean_names() |>
  select(-any_of(c("h1", "1", "x1"))) |>   # Quitar columnas índice auxiliares
  mutate(
    across(starts_with("fecha"), ~ ymd(.x)),
    costo = as.numeric(costo)
  )

# --- Revisión del dataset ---
cat(sprintf("\nFilas totales  : %s\n", format(nrow(datos_raw), big.mark = ",")))
cat(sprintf("Columnas totales: %d\n", ncol(datos_raw)))

cat("\nColumnas disponibles:\n")
cat(paste("-", names(datos_raw), collapse = "\n"), "\n")

cat("\nDistribución de la variable objetivo (partido):\n")
print(table(datos_raw$partido, useNA = "always"))

cat("\nRango de fechas de firma:\n")
cat(sprintf("  Desde: %s\n", min(datos_raw$fecha_firma, na.rm = TRUE)))
cat(sprintf("  Hasta: %s\n", max(datos_raw$fecha_firma, na.rm = TRUE)))

cat("\nResumen del costo:\n")
print(summary(datos_raw$costo))

# Guardar RDS para que los scripts siguientes no tengan que releer el CSV
saveRDS(datos_raw, "./outputs/01_datos_raw.rds")

cat("\n✅ Script completado — datos guardados en outputs/01_datos_raw.rds\n")
