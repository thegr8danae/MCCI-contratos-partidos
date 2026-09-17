# =============================================================================
# 07_random_forest.R — Random Forest: entrenamiento, tuning y evaluación
# =============================================================================
# Generado con ayuda de Claude (Anthropic), junio 2026.
# Prompt: "Crea 8 scripts R autocontenidos para clasificación de partidos
# políticos a partir de características del proveedor — proyecto MCCI"
#
# Modelo: Random Forest (ranger)
#   Justificación: extensión natural del árbol de decisión; promedia muchos árboles
#   para reducir varianza. Se explica como "un comité de árboles" — intuitivo.
#
# Tuning: mtry (2–4) × min_n (5–20) = 9 combinaciones — ver CLAUDE.md §7
#   trees = 300 fijo (equilibrio entre rendimiento y tiempo de ejecución)
# Métrica: accuracy
# Validación: 5-fold CV (creados en 05_recipe_modelo.R) + evaluación final en test
#
# Tiempo estimado: 2–5 minutos según el equipo
#
# Ejecutar desde la raíz del proyecto:
#   Rscript scripts/07_random_forest.R
# =============================================================================

set.seed(123)

library(tidymodels)
library(ranger)

# Ajustar WD si se ejecuta desde el directorio scripts/
if (grepl("scripts$", getwd())) setwd("..")

if (!dir.exists("outputs")) dir.create("outputs")

# --- Carga del setup de modelado ---
if (!file.exists("./outputs/05_setup_modelo.rds")) {
  stop("Ejecuta primero 05_recipe_modelo.R — no se encontró outputs/05_setup_modelo.rds")
}
setup    <- readRDS("./outputs/05_setup_modelo.rds")
split    <- setup$split
train    <- setup$train
test     <- setup$test
receta   <- setup$receta
cv_folds <- setup$cv_folds

# --- Definición del modelo ---
# CONSERVADO: rand_forest() con motor ranger — robusto y eficiente
# SIMPLIFICADO: trees = 300 fijo (el notebook usaba 500; reduce ~40% del tiempo)
# SIMPLIFICADO: no se usa roc_auc multiclase (más difícil de explicar que accuracy)
modelo_rf <- rand_forest(
  mtry  = tune(),   # Variables candidatas por split (de 2 a 4)
  min_n = tune(),   # Mínimo de observaciones para crear un nuevo nodo
  trees = 300       # Número de árboles fijo para controlar tiempo de ejecución
) |>
  set_engine("ranger") |>
  set_mode("classification")

wf_rf <- workflow() |>
  add_recipe(receta) |>
  add_model(modelo_rf)

# --- Grid de búsqueda ---
# SIMPLIFICADO: 3×3 = 9 combinaciones totales (ver CLAUDE.md §7)
# SIMPLIFICADO: no se usa tune_bayes() ni tune_race_anova()
rf_grid <- grid_regular(
  mtry(range  = c(2, 4)),   # 3 valores: 2, 3, 4
  min_n(range = c(5, 20)),  # 3 valores: 5, 12, 20
  levels = 3
)

cat("Tuning del Random Forest:\n")
cat(sprintf("  Combinaciones: %d | Folds: 5 | Ajustes totales: %d\n",
            nrow(rf_grid), nrow(rf_grid) * 5))
cat("  Esto puede tardar 2–5 minutos...\n\n")

tune_rf <- tune_grid(
  wf_rf,
  resamples = cv_folds,
  grid      = rf_grid,
  metrics   = metric_set(accuracy)
)

best_rf <- select_best(tune_rf, metric = "accuracy")
cat("Mejores hiperparámetros del Random Forest (por accuracy en CV):\n")
print(best_rf)

cat("\nResultados por combinación de hiperparámetros:\n")
collect_metrics(tune_rf) |>
  select(mtry, min_n, mean, std_err) |>
  arrange(desc(mean)) |>
  as.data.frame() |>
  print()

# --- Ajuste final con los mejores parámetros ---
final_wf_rf  <- finalize_workflow(wf_rf, best_rf)
fit_final_rf <- last_fit(final_wf_rf, split, metrics = metric_set(accuracy))

metricas_rf <- collect_metrics(fit_final_rf)
cat("\nMétricas en conjunto de prueba (Random Forest):\n")
print(metricas_rf)

preds_rf <- collect_predictions(fit_final_rf)

# --- Matriz de confusión ---
cm_rf <- conf_mat(preds_rf, truth = partido, estimate = .pred_class)
cat("\nMatriz de confusión — Random Forest:\n")
print(cm_rf)

# Precisión y recall macro para uso en 08_comparacion.R
prec_rf <- precision(preds_rf, truth = partido,
                     estimate = .pred_class, estimator = "macro")
rec_rf  <- recall(preds_rf, truth = partido,
                  estimate = .pred_class, estimator = "macro")

cat(sprintf("\nPrecisión macro : %.3f\n", prec_rf$.estimate))
cat(sprintf("Recall macro    : %.3f\n",  rec_rf$.estimate))

# --- Importancia de variables (vip integrado vía ranger) ---
# CONSERVADO: importancia de variables es esencial para responder qué características
#             del proveedor predicen mejor el partido (pregunta de investigación)
cat("\nImportancia de variables (impureza Gini — Random Forest):\n")
rf_fit <- extract_fit_parsnip(fit_final_rf)
importancia <- rf_fit$fit$variable.importance
importancia_df <- data.frame(
  variable    = names(importancia),
  importancia = as.numeric(importancia)
)
importancia_df <- importancia_df[order(-importancia_df$importancia), ]
print(head(importancia_df, 10))

# --- Guardar resultados ---
saveRDS(
  list(
    metricas   = metricas_rf,
    preds      = preds_rf,
    precision  = prec_rf$.estimate,
    recall     = rec_rf$.estimate,
    fit        = fit_final_rf,
    importancia = importancia_df
  ),
  "./outputs/07_resultado_rf.rds"
)

cat("\n✅ Script completado — resultados guardados en outputs/07_resultado_rf.rds\n")
