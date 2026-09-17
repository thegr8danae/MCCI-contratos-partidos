# =============================================================================
# 04_feature_engineering.R — Variables derivadas justificables para el modelo
# =============================================================================
# Generado con ayuda de Claude (Anthropic), junio 2026.
# Prompt: "Crea 8 scripts R autocontenidos para clasificación de partidos
# políticos a partir de características del proveedor — proyecto MCCI"
#
# Variables derivadas que se agregan (todas justificables en < 2 minutos):
#   duracion_dias    : días entre inicio y fin de vigencia del contrato
#   mes_firma        : mes del año (1–12) en que se firmó el contrato
#   es_diciembre     : 1 si el contrato se firmó en diciembre, 0 si no
#                      (diciembre es el cierre del ejercicio fiscal; patrón conocido)
#   log_costo        : log(costo + 1); normaliza la distribución sesgada del monto
#   es_persona_moral : 1 si el proveedor es persona moral (empresa), 0 si es física
#
# Variables ELIMINADAS respecto al notebook original:
#   alto_valor — SIMPLIFICADO: log_costo ya representa el monto continuo;
#                alto_valor (binario por mediana) duplica información sin aportar
#                señal adicional al modelo de árbol
#
# Ejecutar desde la raíz del proyecto:
#   Rscript scripts/04_feature_engineering.R
# =============================================================================

set.seed(123)

library(dplyr)
library(lubridate)

# Ajustar WD si se ejecuta desde el directorio scripts/
if (grepl("scripts$", getwd())) setwd("..")

if (!dir.exists("outputs")) dir.create("outputs")

# --- Carga de datos ---
if (!file.exists("./outputs/02_datos_limpios.rds")) {
  stop("Ejecuta primero 02_limpieza.R — no se encontró outputs/02_datos_limpios.rds")
}
datos <- readRDS("./outputs/02_datos_limpios.rds")

# --- Construcción de variables derivadas ---
# CONSERVADO: lógica de construir_features_proveedor() del proyecto original,
#             adaptada inline (sin wrapper innecesario para scripts independientes)
# SIMPLIFICADO: alto_valor eliminada (ver encabezado)
# SIMPLIFICADO: step_rm() en la recipe se evita pre-seleccionando columnas aquí

datos_features <- datos |>
  mutate(
    duracion_dias    = as.numeric(fecha_fin_vigencia - fecha_inicio_vigencia),
    mes_firma        = month(fecha_firma),
    es_diciembre     = as.integer(month(fecha_firma) == 12),
    log_costo        = log1p(costo),
    es_persona_moral = as.integer(tipo_persona == "Moral")
  ) |>
  filter(
    !is.na(duracion_dias),
    !is.na(mes_firma),
    !is.na(log_costo)
  ) |>
  # Seleccionar solo las columnas de modelado — evita listas largas en step_rm()
  select(
    partido,          # Variable objetivo (factor con 7 niveles)
    ano,              # Año del contrato (captura tendencias temporales)
    tipo_contrato,    # Categoría del contrato (factor, se codificará en la recipe)
    log_costo,        # Monto del contrato en escala log
    duracion_dias,    # Duración del contrato en días
    mes_firma,        # Mes de firma (1–12)
    es_diciembre,     # Indicador de cierre de ejercicio fiscal
    es_persona_moral  # Indicador del tipo de proveedor
  )

# --- Diagnóstico post-feature-engineering ---
cat("Variables de modelado seleccionadas:\n")
cat(paste(sprintf("  %-20s %s", names(datos_features),
                  sapply(datos_features, class)), collapse = "\n"), "\n")

cat(sprintf("\nObservaciones disponibles para modelado: %s\n",
            format(nrow(datos_features), big.mark = ",")))

nas_check <- sapply(datos_features, function(x) sum(is.na(x)))
if (any(nas_check > 0)) {
  cat("\nNAs restantes por columna:\n")
  print(nas_check[nas_check > 0])
} else {
  cat("\nSin valores faltantes en las variables de modelado.\n")
}

cat("\nDistribución de tipo_contrato (top 5):\n")
top5 <- sort(table(datos_features$tipo_contrato), decreasing = TRUE)[1:5]
print(top5)

saveRDS(datos_features, "./outputs/04_datos_features.rds")

cat("\n✅ Script completado — features guardados en outputs/04_datos_features.rds\n")
