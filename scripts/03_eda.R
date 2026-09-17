# =============================================================================
# 03_eda.R — Análisis exploratorio básico con visualizaciones simples
# =============================================================================
# Generado con ayuda de Claude (Anthropic), junio 2026.
# Prompt: "Crea 8 scripts R autocontenidos para clasificación de partidos
# políticos a partir de características del proveedor — proyecto MCCI"
#
# Ejecutar desde la raíz del proyecto:
#   Rscript scripts/03_eda.R
# =============================================================================

set.seed(123)

library(dplyr)
library(ggplot2)
library(scales)

# Ajustar WD si se ejecuta desde el directorio scripts/
if (grepl("scripts$", getwd())) setwd("..")

if (!dir.exists("outputs")) dir.create("outputs")

# CONSERVADO: paleta de colores oficial por partido, del proyecto original
paleta_partidos <- c(
  "PAN"    = "#003B8D",
  "PRI"    = "#CE1126",
  "PRD"    = "#FDD116",
  "Morena" = "#8B1A1A",
  "MC"     = "#FF6600",
  "PVEM"   = "#2E8B57",
  "PT"     = "#CC0000"
)

# --- Carga de datos limpios ---
if (!file.exists("./outputs/02_datos_limpios.rds")) {
  stop("Ejecuta primero 02_limpieza.R — no se encontró outputs/02_datos_limpios.rds")
}
datos <- readRDS("./outputs/02_datos_limpios.rds")

# --- Gráfica 1: Número de contratos por partido ---
# Relevante para la pregunta: muestra el desbalance de clases que enfrentará el modelo
cat("Generando gráfica 1: contratos por partido...\n")
g1 <- datos |>
  count(partido) |>
  ggplot(aes(x = reorder(partido, n), y = n, fill = partido)) +
  geom_col(alpha = 0.85) +
  coord_flip() +
  scale_fill_manual(values = paleta_partidos) +
  scale_y_continuous(labels = comma) +
  labs(
    title   = "Número de contratos por partido político",
    subtitle = "Desbalance de clases relevante para el modelo de clasificación",
    x       = NULL,
    y       = "Número de contratos",
    caption = "Fuente: MCCI — contratos_montos.csv"
  ) +
  theme_minimal() +
  theme(legend.position = "none")

ggsave("./outputs/eda_01_contratos_por_partido.png", g1, width = 8, height = 5, dpi = 150)

# --- Gráfica 2: Distribución del costo (log) por partido ---
# Relevante: si el monto varía sistemáticamente entre partidos, será un buen predictor
cat("Generando gráfica 2: distribución de costo (log) por partido...\n")
g2 <- datos |>
  mutate(log_costo = log1p(costo)) |>
  ggplot(aes(x = partido, y = log_costo, fill = partido)) +
  geom_boxplot(alpha = 0.7, outlier.size = 0.5, outlier.alpha = 0.3) +
  scale_fill_manual(values = paleta_partidos) +
  labs(
    title   = "Distribución del costo (escala logarítmica) por partido",
    subtitle = "La variación entre partidos justifica log_costo como predictor",
    x       = NULL,
    y       = "log(costo + 1)",
    caption = "Fuente: MCCI"
  ) +
  theme_minimal() +
  theme(legend.position = "none")

ggsave("./outputs/eda_02_costo_log_partido.png", g2, width = 8, height = 5, dpi = 150)

# --- Gráfica 3: Proporción persona física vs moral por partido ---
# Relevante: si cada partido prefiere distintos tipos de proveedor, es_persona_moral sirve
cat("Generando gráfica 3: tipo de persona por partido...\n")
g3 <- datos |>
  filter(!is.na(tipo_persona)) |>
  count(partido, tipo_persona) |>
  group_by(partido) |>
  mutate(prop = n / sum(n)) |>
  ungroup() |>
  ggplot(aes(x = partido, y = prop, fill = tipo_persona)) +
  geom_col(position = "fill", alpha = 0.85) +
  scale_y_continuous(labels = label_percent()) +
  scale_fill_manual(
    values = c("Moral" = "#003B8D", "Física" = "#CC6600"),
    name   = "Tipo de persona"
  ) +
  labs(
    title   = "Proporción de tipo de proveedor por partido político",
    subtitle = "Las diferencias entre partidos justifican es_persona_moral como predictor",
    x       = "Partido",
    y       = "Proporción de contratos",
    caption = "Fuente: MCCI"
  ) +
  theme_minimal()

ggsave("./outputs/eda_03_tipo_persona_partido.png", g3, width = 8, height = 5, dpi = 150)

# --- Tabla resumen en consola ---
cat("\nResumen estadístico por partido:\n")
datos |>
  mutate(log_costo = log1p(costo)) |>
  group_by(partido) |>
  summarise(
    n_contratos   = n(),
    costo_mediano = round(median(costo, na.rm = TRUE), 0),
    pct_moral     = round(mean(tipo_persona == "Moral", na.rm = TRUE) * 100, 1),
    .groups = "drop"
  ) |>
  as.data.frame() |>
  print()

cat("\nGráficas guardadas en outputs/\n")
cat("\n✅ Script completado\n")
