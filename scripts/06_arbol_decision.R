# =============================================================================
# 06_arbol_decision.R — Árbol de Decisión: entrenamiento, tuning y evaluación
# =============================================================================
# Generado con ayuda de Claude (Anthropic), junio 2026.
# Prompt: "Crea 8 scripts R autocontenidos para clasificación de partidos
# políticos a partir de características del proveedor — proyecto MCCI"
#
# Modelo: Árbol de Decisión (rpart)
#   Justificación: completamente interpretable, se puede visualizar y explicar
#   nodo por nodo. Es el modelo más transparente para una audiencia académica.
#
# Tuning: solo tree_depth (2 a 6) con 5 combinaciones — ver CLAUDE.md §7
# Métrica: accuracy (fracción de contratos clasificados correctamente)
# Validación: 5-fold CV (creados en 05_recipe_modelo.R) + evaluación final en test
#
# Ejecutar desde la raíz del proyecto:
#   Rscript scripts/06_arbol_decision.R
# =============================================================================

set.seed(123)

library(tidymodels)

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
# CONSERVADO: decision_tree() con motor rpart — interpretable y visualizable
# cost_complexity fijo (0.001) para que el árbol crezca y tree_depth lo controle
modelo_arbol <- decision_tree(
  tree_depth      = tune(),   # Profundidad máxima: único hiperparámetro a tunear
  cost_complexity = 0.001,    # Penalización de poda fija (baja para no podar en exceso)
  min_n           = 5         # Mínimo de observaciones para dividir un nodo
) |>
  set_engine("rpart") |>
  set_mode("classification")

wf_arbol <- workflow() |>
  add_recipe(receta) |>
  add_model(modelo_arbol)

# --- Grid de búsqueda ---
# SIMPLIFICADO: solo 5 combinaciones de profundidad (ver CLAUDE.md §7)
# SIMPLIFICADO: solo accuracy como métrica (más directa que AUC multiclase)
arbol_grid <- grid_regular(
  tree_depth(range = c(2, 6)),
  levels = 5   # profundidades: 2, 3, 4, 5, 6
)

cat("Tuning del árbol de decisión:\n")
cat(sprintf("  Combinaciones: %d | Folds: 5 | Ajustes totales: %d\n",
            nrow(arbol_grid), nrow(arbol_grid) * 5))

tune_arbol <- tune_grid(
  wf_arbol,
  resamples = cv_folds,
  grid      = arbol_grid,
  metrics   = metric_set(accuracy)
)

best_arbol <- select_best(tune_arbol, metric = "accuracy")
cat("\nMejor profundidad del árbol (por accuracy en CV):\n")
print(best_arbol)

cat("\nResultados por profundidad:\n")
collect_metrics(tune_arbol) |>
  select(tree_depth, mean, std_err) |>
  as.data.frame() |>
  print()

# --- Ajuste final con los mejores parámetros ---
final_wf_arbol  <- finalize_workflow(wf_arbol, best_arbol)
fit_final_arbol <- last_fit(final_wf_arbol, split, metrics = metric_set(accuracy))

metricas_arbol <- collect_metrics(fit_final_arbol)
cat("\nMétricas en conjunto de prueba (Árbol de Decisión):\n")
print(metricas_arbol)

preds_arbol <- collect_predictions(fit_final_arbol)

# --- Matriz de confusión ---
cm_arbol <- conf_mat(preds_arbol, truth = partido, estimate = .pred_class)
cat("\nMatriz de confusión — Árbol de Decisión:\n")
print(cm_arbol)

# Precisión y recall macro para uso en 08_comparacion.R
prec_arbol <- precision(preds_arbol, truth = partido,
                        estimate = .pred_class, estimator = "macro")
rec_arbol  <- recall(preds_arbol, truth = partido,
                     estimate = .pred_class, estimator = "macro")

cat(sprintf("\nPrecisión macro : %.3f\n", prec_arbol$.estimate))
cat(sprintf("Recall macro    : %.3f\n",  rec_arbol$.estimate))

# --- Guardar resultados ---
saveRDS(
  list(
    metricas  = metricas_arbol,
    preds     = preds_arbol,
    precision = prec_arbol$.estimate,
    recall    = rec_arbol$.estimate,
    fit       = fit_final_arbol
  ),
  "./outputs/06_resultado_arbol.rds"
)

cat("\n✅ Script completado — resultados guardados en outputs/06_resultado_arbol.rds\n")
