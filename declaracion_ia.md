# Declaración de Uso de Inteligencia Artificial

**Proyecto:** MCCI — Contratos de Partidos Políticos  
**Autor:** Oscar Verdugo Carranza  
**Fecha:** junio de 2026

---

## Herramientas de IA utilizadas

| Herramienta | Proveedor | Versión aproximada |
|---|---|---|
| Claude | Anthropic | Claude Sonnet 4.x (junio 2026) |

No se utilizaron otras herramientas de IA generativa (ChatGPT, Gemini, Copilot, etc.) en este proyecto.

---

## Uso detallado por componente

### Scripts auxiliares (`scripts/`)

**Archivos asistidos:** `01_carga_datos.R`, `02_limpieza.R`, `03_eda.R`, `04_feature_engineering.R`, `05_recipe_modelo.R`, `06_arbol_decision.R`, `07_random_forest.R`, `08_comparacion.R`

**Prompt principal usado:**
> "Crea 8 scripts R autocontenidos para clasificación de partidos políticos a partir de características del proveedor — proyecto MCCI. Cada script debe leer desde outputs/ del script anterior y guardar sus resultados como RDS. Los scripts deben seguir el estilo tidymodels y estar comentados en español."

**Fragmentos asistidos:**
- Estructura general de cada script (encabezado, carga, procesamiento, guardado de RDS)
- Código de tuning con `tune_grid()` y `select_best()` en scripts 06 y 07
- Tabla comparativa de métricas en script 08
- Comentarios explicativos del propósito de cada paso

**Fragmentos propios (sin asistencia de IA):**
- Elección de la variable objetivo (`partido`) y exclusión de `area` por data leakage
- Decisión de usar árbol de decisión primero (interpretabilidad) y Random Forest como extensión
- Selección del rango de hiperparámetros a explorar
- Interpretación de los resultados y redacción de las conclusiones

---

### Notebook principal de ML (`notebooks/02_prediccion_partido_proveedor.qmd`)

**Prompt principal usado:**
> "Crea un notebook de Quarto en R con tidymodels para clasificación multiclase de partidos políticos a partir de características de proveedores, siguiendo el estilo del proyecto MCCI Proyecto Integrador."

**Prompt secundario:**
> "Escribe un recipe de tidymodels para clasificación multiclase con variables mixtas, excluyendo columnas de texto libre y fechas crudas."

**Prompt secundario:**
> "Configura tune_grid con 10 combinaciones aleatorias de hiperparámetros para un Random Forest multiclase con tidymodels."

**Fragmentos asistidos:**
- Estructura del notebook (secciones, callouts, código de carga)
- Recipe de preprocesamiento con `step_unknown`, `step_dummy`, `step_nzv`, `step_impute_median`
- Código de evaluación del modelo (matriz de confusión, F1 macro, tabla de métricas)
- Sección de importancia de variables con `vip::vi()`

**Fragmentos propios (sin asistencia de IA):**
- Justificación de la pregunta de investigación y su relevancia periodística
- Decisión de trabajar a nivel de contrato (no de proveedor) y su justificación
- Redacción de la sección de interpretación y limitaciones éticas
- Análisis de qué variables son sustantivamente importantes y por qué

---

### Utilidades y funciones (`scripts/utils.R`)

**Fragmentos asistidos:**
- Documentación de funciones con `#'` (estilo roxygen)
- Implementación de `construir_features_proveedor()` y `perfil_proveedor()`

**Fragmentos propios:**
- Paleta de colores `paleta_partidos` (colores institucionales de cada partido)
- Función `forzar_orden_partidos()` (orden canónico para gráficas)

---

### Notebooks de exploración (`notebooks/01_exploracion.qmd`, `notebooks/02_contratos_montos.qmd`)

**Asistencia:** Mínima. El código base fue escrito sin asistencia de IA. Se usó Claude para:
- Ajustar colores MCCI en las gráficas de distribución
- Formatear tablas con `gt`

---

### Nota de difusión (`nota_difusion.qmd`)

**Asistencia:** Se usó Claude para estructurar el documento y sugerir secciones. La redacción fue revisada, adaptada y en varios párrafos reescrita por el autor.

---

### Índice del proyecto (`index.qmd`)

**Asistencia:** Se usó Claude para el HTML de las tarjetas de hallazgos ("Lo que encontramos") y la estructura de la sección de hipótesis de valor.

---

## Política de verificación aplicada

Todo el código generado con asistencia de IA fue:

1. **Revisado línea por línea** antes de incluirse en el proyecto
2. **Ejecutado y verificado** que produce los resultados esperados
3. **Comentado** con la lógica del propósito de cada paso, no solo lo que hace
4. **Ajustado** donde la sugerencia de IA no era correcta para este contexto específico

---

## Nota sobre uso responsable

El uso de IA en este proyecto siguió los lineamientos del curso:
- Cada fragmento asistido está marcado con un comentario `# Generado con ayuda de Claude (Anthropic)`
- Se documentó el prompt utilizado en cada caso
- El autor puede explicar el propósito y funcionamiento de cada sección del código
- Los hallazgos e interpretaciones son propios del autor, no de la IA
