# =============================================================================
# instalar_paquetes.R
# =============================================================================
# Descripción: Script de configuración inicial del entorno.
#              Ejecutar UNA SOLA VEZ al clonar el repositorio.
#
# Uso: source("scripts/instalar_paquetes.R")
# =============================================================================

cat("=== Instalando paquetes necesarios para el proyecto MCCI ===\n\n")

paquetes <- c(
  "tidyverse",   # Manipulación y visualización de datos
  "janitor",     # Limpieza de datos y nombres de columnas
  "skimr",       # Resumen estadístico rápido
  "gt",          # Tablas con formato profesional
  "lubridate",   # Manejo de fechas
  "readr",       # Lectura eficiente de CSVs
  "scales",      # Escalas y formatos para ggplot2
  "knitr",       # Renderizado de documentos
  "quarto",      # Integración con Quarto desde R
  "plotly",      # Gráficas interactivas (requerido por 02_contratos_montos y 02_prediccion)
  "tidymodels",  # Framework de modelado ML (árbol + random forest)
  "ranger",      # Motor para Random Forest
  "vip"          # Importancia de variables
)

instalar_si_falta <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    cat(sprintf("  Instalando: %s...\n", pkg))
    install.packages(pkg, repos = "https://cloud.r-project.org")
  } else {
    cat(sprintf("  ✅ Ya instalado: %s\n", pkg))
  }
}

invisible(lapply(paquetes, instalar_si_falta))

cat("\n✅ Todos los paquetes están disponibles.\n")
cat("Ahora puedes abrir notebooks/01_exploracion.qmd y hacer clic en 'Render'.\n")
