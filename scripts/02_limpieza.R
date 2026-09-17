# =============================================================================
# 02_limpieza.R — Limpieza: tipos de variables, NAs y filtros básicos
# =============================================================================
# Generado con ayuda de Claude (Anthropic), junio 2026.
# Prompt: "Crea 8 scripts R autocontenidos para clasificación de partidos
# políticos a partir de características del proveedor — proyecto MCCI"
#
# Ejecutar desde la raíz del proyecto:
#   Rscript scripts/02_limpieza.R
# =============================================================================

set.seed(123)

library(readr)
library(dplyr)
library(janitor)
library(lubridate)

# Ajustar WD si se ejecuta desde el directorio scripts/
if (grepl("scripts$", getwd())) setwd("..")

if (!dir.exists("outputs")) dir.create("outputs")

# --- Carga autocontenida (usa RDS previo si existe, si no recarga el CSV) ---
if (file.exists("./outputs/01_datos_raw.rds")) {
  datos_raw <- readRDS("./outputs/01_datos_raw.rds")
} else {
  ruta_csv <- if (file.exists("./data/contratos_montos.csv")) {
    "./data/contratos_montos.csv"
  } else if (file.exists("./datos/contratos_montos.csv")) {
    "./datos/contratos_montos.csv"
  } else {
    "./notebooks/contratos_montos.csv"
  }
  datos_raw <- read_csv(ruta_csv, locale = locale(encoding = "UTF-8"),
                        show_col_types = FALSE) |>
    clean_names() |>
    select(-any_of(c("h1", "1", "x1"))) |>
    mutate(across(starts_with("fecha"), ~ ymd(.x)), costo = as.numeric(costo))
}

# --- Diagnóstico de NAs ---
# SIMPLIFICADO: cálculo explícito con sapply en lugar de función wrapper contar_nas()
cat("Columnas con valores faltantes:\n")
nas_count <- sapply(datos_raw, function(x) sum(is.na(x)))
nas_df    <- data.frame(
  columna = names(nas_count),
  n_na    = as.integer(nas_count),
  pct_na  = round(nas_count / nrow(datos_raw) * 100, 1),
  row.names = NULL
)
nas_df <- nas_df[nas_df$n_na > 0, ]
nas_df <- nas_df[order(-nas_df$n_na), ]
print(nas_df)

# --- Limpieza principal ---
# CONSERVADO: filtro de partido y costo (filas sin partido no sirven como objetivo;
#             costo == 0 o NA son contratos sin monto registrado)
# CONSERVADO: partido como factor con niveles canónicos para garantizar orden visual
datos_limpios <- datos_raw |>
  filter(
    !is.na(partido),
    !is.na(costo),
    costo > 0
  ) |>
  mutate(
    partido       = factor(partido,
                           levels = c("PAN", "PRI", "PRD", "Morena", "MC", "PVEM", "PT")),
    tipo_persona  = as.factor(tipo_persona),
    tipo_contrato = as.factor(tipo_contrato),
    ano           = as.integer(ano)
  )

cat(sprintf("\nFilas originales : %s\n", format(nrow(datos_raw),    big.mark = ",")))
cat(sprintf("Filas tras limpieza: %s\n", format(nrow(datos_limpios), big.mark = ",")))
cat(sprintf("Filas descartadas  : %s (sin partido válido, sin costo o costo = 0)\n",
            format(nrow(datos_raw) - nrow(datos_limpios), big.mark = ",")))

cat("\nDistribución de partido (datos limpios):\n")
print(table(datos_limpios$partido))

saveRDS(datos_limpios, "./outputs/02_datos_limpios.rds")

cat("\n✅ Script completado — datos guardados en outputs/02_datos_limpios.rds\n")
