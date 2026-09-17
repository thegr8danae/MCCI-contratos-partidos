# MCCI — Contratos de Partidos Políticos

> **Mexicanos Contra la Corrupción y la Impunidad (MCCI)**
> Análisis de datos de contrataciones públicas de partidos políticos en México.
> Proyecto Integrador · 2026

---

## Descripción del proyecto

Este repositorio contiene el análisis de los datos compartidos por MCCI sobre contratos de bienes y servicios celebrados por partidos políticos mexicanos. El proyecto responde la pregunta: **¿puede un modelo de machine learning predecir el partido que asigna un contrato a partir de sus características observables?**

La respuesta es sí: el modelo Random Forest alcanzó 87.1% de exactitud (6.1× sobre la línea base aleatoria de 14.3%), lo que demuestra que cada partido tiene una "firma de gasto" estadísticamente reconocible.

---

## Estructura del repositorio

```
MCCI_Proyecto_Integrador/
├── _quarto.yml                              # Configuración del sitio Quarto
├── index.qmd                               # Página principal: hipótesis + hallazgos
├── nota_difusion.qmd                       # Nota ejecutiva (2 cuartillas)
├── declaracion_ia.md                       # Declaración de uso de IA
├── notebooks/
│   ├── 01_exploracion.qmd                  # Comparación y exploración de datasets
│   ├── 02_contratos_montos.qmd             # Análisis univariado y bivariado
│   ├── 02_prediccion_partido_proveedor.qmd # ML: clasificación multiclase (RF)
│   └── contratos_montos.csv               # Caché de datos para desarrollo
├── scripts/
│   ├── 01_carga_datos.R                    # Importar y revisar dataset original
│   ├── 02_limpieza.R                       # Limpieza y estandarización
│   ├── 03_eda.R                            # Análisis exploratorio de datos
│   ├── 04_feature_engineering.R            # Construcción de variables derivadas
│   ├── 05_recipe_modelo.R                  # Split, recipe y folds de CV
│   ├── 06_arbol_decision.R                 # Árbol de Decisión: tuning y evaluación
│   ├── 07_random_forest.R                  # Random Forest: tuning y evaluación
│   ├── 08_comparacion.R                    # Tabla comparativa de métricas
│   ├── instalar_paquetes.R                 # Instalar dependencias (ejecutar una vez)
│   └── utils.R                             # Funciones reutilizables
├── outputs/
│   ├── 01_datos_raw.rds                    # Dataset original (RDS)
│   ├── 02_datos_limpios.rds                # Dataset limpio
│   ├── 04_datos_features.rds               # Dataset con features construidas
│   ├── 05_setup_modelo.rds                 # Split + recipe + folds
│   ├── 06_resultado_arbol.rds              # Resultados del árbol de decisión
│   ├── 07_resultado_rf.rds                 # Resultados del Random Forest
│   ├── 08_tabla_comparacion.csv            # Comparativa de modelos (CSV)
│   └── 08_tabla_comparacion.rds            # Comparativa de modelos (RDS)
├── referencias/
│   └── diccionario_datos.qmd              # Descripción de las 28-30 variables
├── styles/
│   └── mcci-theme.scss                    # Tema visual MCCI para Quarto
└── docs/                                  # HTML renderizado (output de Quarto)
```

Los datos originales (`datos/contratos.csv`, `datos/contratos_montos.csv`) viven fuera del repo (gitignored). Una copia de desarrollo de `contratos_montos.csv` se mantiene en `notebooks/` para facilitar el renderizado sin acceso al directorio `datos/`.

---

## Cómo reproducir el análisis

### Paso 0 — Requisitos previos

- **R** ≥ 4.3 · [descargar](https://cran.r-project.org/)
- **Quarto** ≥ 1.4 · [descargar](https://quarto.org/docs/get-started/)
- **RStudio** (recomendado) · [descargar](https://posit.co/download/rstudio-desktop/)

### Paso 1 — Clonar el repositorio

```bash
git clone https://github.com/thegr8danae/MCCI-contratos-partidos.git
cd MCCI-contratos-partidos
```

### Paso 2 — Instalar dependencias de R

Abre RStudio y ejecuta **una sola vez**:

```r
source("scripts/instalar_paquetes.R")
```

Este script instala automáticamente todos los paquetes necesarios:
`tidyverse`, `tidymodels`, `ranger`, `vip`, `janitor`, `skimr`, `gt`, `lubridate`, `scales`, `knitr`, `readr`

### Paso 3 — Colocar los datos

Coloca los archivos CSV en la carpeta `datos/` (créala si no existe):

```
datos/
├── contratos.csv          # 15,736 filas × 28 columnas
└── contratos_montos.csv   # 15,118 filas × 30 columnas
```

Si no tienes acceso a los datos originales, el notebook de ML (`02_prediccion_partido_proveedor.qmd`) usa la copia de desarrollo en `notebooks/contratos_montos.csv`.

### Paso 4 — Ejecutar los scripts en orden (pipeline ML)

Los scripts deben ejecutarse en orden desde la **raíz del proyecto**:

```r
# Opción A: desde RStudio (abrir el .Rproj primero)
source("scripts/01_carga_datos.R")
source("scripts/02_limpieza.R")
source("scripts/03_eda.R")
source("scripts/04_feature_engineering.R")
source("scripts/05_recipe_modelo.R")
source("scripts/06_arbol_decision.R")
source("scripts/07_random_forest.R")
source("scripts/08_comparacion.R")
```

```bash
# Opción B: desde la terminal (línea a línea)
Rscript scripts/01_carga_datos.R
Rscript scripts/02_limpieza.R
# ... continuar en orden hasta 08_comparacion.R
```

Los resultados intermedios se guardan automáticamente en `outputs/` como archivos `.rds`.

### Paso 5 — Renderizar el reporte Quarto

```bash
# Renderizar todo el sitio (requiere estar en la raíz del proyecto)
quarto render

# Renderizar solo un notebook
quarto render notebooks/02_prediccion_partido_proveedor.qmd
```

Desde RStudio: abrir cualquier `.qmd` y presionar **Ctrl+Shift+K**.

El output se genera en `docs/` y puede abrirse directamente en el navegador.

---

## Descripción de los datasets

### `contratos.csv` — 15,736 filas × 28 columnas

Dataset completo de contratos de bienes y servicios de partidos políticos. El partido se identifica mediante la columna `partido_archivo`, que requiere parsing manual.

### `contratos_montos.csv` — 15,118 filas × 30 columnas

Subconjunto con dos columnas adicionales:
- **`partido`** — nombre del partido en formato estandarizado (factor con 7 niveles)
- **`H1`** — índice auxiliar heredado del archivo fuente (puede ignorarse)

La diferencia de 618 filas representa contratos sin partido identificable o sin costo registrado.

**Dataset recomendado para el modelado:** `contratos_montos.csv`

---

## Resultados principales

| Modelo | Accuracy | Precisión (macro) | Recall (macro) |
|---|---|---|---|
| Árbol de Decisión | 72.5% | 74.4% | 59.4% |
| **Random Forest** | **87.1%** | **85.0%** | **81.8%** |

Línea base aleatoria (7 partidos): **14.3%**

---

## Declaración de uso de IA

Este proyecto utilizó **Claude (Anthropic)** para asistir en la escritura de código R, la estructura de los notebooks y la revisión de comentarios. Ver [declaracion_ia.md](declaracion_ia.md) para el detalle completo de qué fragmentos fueron asistidos y con qué prompts.

---

## Créditos

- **Datos:** Mexicanos Contra la Corrupción y la Impunidad · [contralacorrupcion.mx](https://contralacorrupcion.mx)
- **Análisis:** Oscar Verdugo Carranza
- **Asistencia de IA:** Claude (Anthropic)
- **Herramientas:** R · tidyverse · tidymodels · Quarto · ggplot2
