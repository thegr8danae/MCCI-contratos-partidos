# =============================================================================
# 08_comparacion.R — Tabla comparativa: Árbol de Decisión vs Random Forest
# =============================================================================
# Generado con ayuda de Claude (Anthropic), junio 2026.
# Prompt: "Crea 8 scripts R autocontenidos para clasificación de partidos
# políticos a partir de características del proveedor — proyecto MCCI"
#
# Métricas comparadas en el conjunto de prueba:
#   Accuracy  : fracción de contratos clasificados correctamente (entre 0 y 1)
#   Precisión : promedio macro de precisión por clase (considera partidos pequeños)
#   Recall    : promedio macro de recall por clase (considera partidos pequeños)
#
# Línea base aleatoria (7 partidos, distribución uniforme): ~14.3%
#
# Ejecutar desde la raíz del proyecto:
#   Rscript scripts/08_comparacion.R
# =============================================================================

set.seed(123)

library(dplyr)

# Ajustar WD si se ejecuta desde el directorio scripts/
if (grepl("scripts$", getwd())) setwd("..")

if (!dir.exists("outputs")) dir.create("outputs")

# --- Carga de resultados de ambos modelos ---
if (!file.exists("./outputs/06_resultado_arbol.rds")) {
  stop("Ejecuta primero 06_arbol_decision.R — no se encontró outputs/06_resultado_arbol.rds")
}
if (!file.exists("./outputs/07_resultado_rf.rds")) {
  stop("Ejecuta primero 07_random_forest.R — no se encontró outputs/07_resultado_rf.rds")
}

res_arbol <- readRDS("./outputs/06_resultado_arbol.rds")
res_rf    <- readRDS("./outputs/07_resultado_rf.rds")

# --- Extraer métricas de cada modelo ---
acc_arbol <- res_arbol$metricas |>
  filter(.metric == "accuracy") |>
  pull(.estimate)

acc_rf <- res_rf$metricas |>
  filter(.metric == "accuracy") |>
  pull(.estimate)

# --- Tabla comparativa ---
tabla_comparacion <- data.frame(
  Modelo     = c("Árbol de Decisión", "Random Forest"),
  Accuracy   = round(c(acc_arbol,            acc_rf),            3),
  Precision  = round(c(res_arbol$precision,  res_rf$precision),  3),
  Recall     = round(c(res_arbol$recall,     res_rf$recall),     3),
  stringsAsFactors = FALSE
)

# --- Interpretación ---
linea_base <- 1 / 7

cat("=================================================================\n")
cat("  MCCI — Contratos Políticos México\n")
cat("  Comparación de modelos de clasificación\n")
cat("=================================================================\n\n")
cat("Pregunta de investigación:\n")
cat("  ¿Es posible predecir el partido político que asigna un contrato\n")
cat("  a partir de las características del proveedor?\n\n")
cat(sprintf("  Línea base aleatoria (7 partidos): %.1f%%\n\n", linea_base * 100))

cat("Resultados en conjunto de prueba (25% de los datos):\n\n")
print(tabla_comparacion, row.names = FALSE)

cat(sprintf("\n  Árbol de Decisión : %.1f%% accuracy (%.1fx sobre el azar)\n",
            acc_arbol * 100, acc_arbol / linea_base))
cat(sprintf("  Random Forest     : %.1f%% accuracy (%.1fx sobre el azar)\n",
            acc_rf * 100, acc_rf / linea_base))

cat("\nNotas sobre las métricas macro:\n")
cat("  - Precisión macro: promedio de 'de los contratos predichos como partido X,\n")
cat("    ¿qué fracción realmente lo era?' para cada uno de los 7 partidos.\n")
cat("  - Recall macro: promedio de 'de los contratos reales del partido X,\n")
cat("    ¿qué fracción predijo correctamente el modelo?' para cada partido.\n")
cat("  - El promedio macro penaliza cuando el modelo falla con partidos pequeños\n")
cat("    (MC, PT, PVEM) aunque tenga alta accuracy global.\n")

if (acc_rf > acc_arbol) {
  cat("\nConclusión: el Random Forest supera al Árbol de Decisión en accuracy.\n")
  cat("La brecha refleja que el ensemble captura interacciones más complejas.\n")
  cat("El Árbol sigue siendo valioso por su interpretabilidad visual.\n")
} else {
  cat("\nConclusión: ambos modelos tienen accuracy comparable.\n")
  cat("El Árbol de Decisión es preferible para la presentación académica\n")
  cat("gracias a su mayor interpretabilidad.\n")
}

cat("\nImportancia de variables — Random Forest (top 5):\n")
print(head(res_rf$importancia, 5), row.names = FALSE)

# --- Guardar resultados ---
write.csv(tabla_comparacion, "./outputs/08_tabla_comparacion.csv", row.names = FALSE)
saveRDS(tabla_comparacion,    "./outputs/08_tabla_comparacion.rds")

cat("\n✅ Script completado — tabla guardada en outputs/08_tabla_comparacion.csv\n")
