# =============================================================================
# 05_recipe_modelo.R — División train/test y recipe simplificada
# =============================================================================
# Generado con ayuda de Claude (Anthropic), junio 2026.
# Prompt: "Crea 8 scripts R autocontenidos para clasificación de partidos
# políticos a partir de características del proveedor — proyecto MCCI"
#
# Recipe simplificada (3 steps vs 5 del notebook original):
#   step_unknown       : NA en tipo_contrato → nivel "Unknown"
#   step_dummy         : tipo_contrato → variables indicadoras (K-1 columnas)
#   step_impute_median : NAs numéricos → mediana calculada en train (no en test)
#
# Steps ELIMINADOS respecto al notebook original:
#   step_rm()  — SIMPLIFICADO: las columnas ya fueron seleccionadas en 04_feature_engineering.R
#   step_nzv() — SIMPLIFICADO: con variables pre-seleccionadas no hay near-zero-variance
#
# Ejecutar desde la raíz del proyecto:
#   Rscript scripts/05_recipe_modelo.R
# =============================================================================

set.seed(123)

library(tidymodels)

# Ajustar WD si se ejecuta desde el directorio scripts/
if (grepl("scripts$", getwd())) setwd("..")

if (!dir.exists("outputs")) dir.create("outputs")

# --- Carga de datos con features ---
if (!file.exists("./outputs/04_datos_features.rds")) {
  stop("Ejecuta primero 04_feature_engineering.R — no se encontró outputs/04_datos_features.rds")
}
datos <- readRDS("./outputs/04_datos_features.rds")

# --- División train/test ---
# CONSERVADO: holdout 75/25 estratificado por partido (preferido por CLAUDE.md §8)
#             strata = partido garantiza proporciones similares en ambos conjuntos
split <- initial_split(datos, prop = 0.75, strata = partido)
train <- training(split)
test  <- testing(split)

cat(sprintf("Entrenamiento : %s contratos\n", format(nrow(train), big.mark = ",")))
cat(sprintf("Prueba        : %s contratos\n", format(nrow(test),  big.mark = ",")))

cat("\nProporción de partido en train:\n")
print(round(prop.table(table(train$partido)) * 100, 1))

# --- Validación cruzada 5-fold ---
# CONSERVADO: 5-fold CV sobre el conjunto de entrenamiento para tuning de hiperparámetros
#             Se crea aquí una sola vez y se comparte entre 06_arbol y 07_random_forest
cv_folds <- vfold_cv(train, v = 5, strata = partido)
cat("\nValidación cruzada: 5-fold estratificada sobre train\n")

# --- Recipe simplificada ---
# SIMPLIFICADO: sin step_rm() (columnas ya seleccionadas) ni step_nzv() (innecesario)
receta <- recipe(partido ~ ., data = train) |>
  step_unknown(all_nominal_predictors()) |>           # tipo_contrato NA → "Unknown"
  step_dummy(all_nominal_predictors(), one_hot = FALSE) |>  # tipo_contrato → binarias
  step_impute_median(all_numeric_predictors())         # NAs numéricos → mediana del train

cat("\nRecipe preparada — 3 steps:\n")
cat("  1. step_unknown:       NA en tipo_contrato se etiqueta como 'Unknown'\n")
cat("  2. step_dummy:         tipo_contrato se convierte a variables indicadoras (0/1)\n")
cat("  3. step_impute_median: NAs numéricos se imputan con la mediana del train\n")

# Vista previa de las columnas que generará la recipe
baked <- prep(receta, training = train) |> bake(new_data = NULL)
cat(sprintf("\nColumnas en train tras aplicar la recipe: %d\n", ncol(baked)))
cat(paste("-", names(baked), collapse = "\n"), "\n")

# --- Guardar todo lo necesario para los scripts de modelos ---
saveRDS(
  list(split = split, train = train, test = test,
       receta = receta, cv_folds = cv_folds),
  "./outputs/05_setup_modelo.rds"
)

cat("\n✅ Script completado — split, recipe y folds guardados en outputs/05_setup_modelo.rds\n")
