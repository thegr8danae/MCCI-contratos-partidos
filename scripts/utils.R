# =============================================================================
# utils.R — Funciones de utilidad para el proyecto MCCI
# =============================================================================
# Descripción: Funciones reutilizables para la carga, limpieza y exploración
#              de los datasets de contratos de partidos políticos de MCCI.
#
# Uso: source("scripts/utils.R")
# =============================================================================

library(readr)
library(dplyr)
library(janitor)
library(lubridate)
library(stringr)

# -----------------------------------------------------------------------------
# 1. CARGA DE DATOS
# -----------------------------------------------------------------------------

#' Cargar el dataset de contratos
#'
#' @param ruta Ruta al archivo contratos.csv (por defecto busca en datos/)
#' @return Un tibble con los datos limpios
cargar_contratos <- function(ruta = "datos/contratos.csv") {
  readr::read_csv(
    ruta,
    locale = readr::locale(encoding = "UTF-8"),
    show_col_types = FALSE
  ) |>
    janitor::clean_names() |>
    dplyr::mutate(
      across(starts_with("fecha"), ~ lubridate::ymd(.x)),
      costo = as.numeric(costo)
    )
}

#' Cargar el dataset de contratos con montos y partido
#'
#' @param ruta Ruta al archivo contratos_montos.csv (por defecto busca en datos/)
#' @return Un tibble con los datos limpios (sin la columna auxiliar h1)
cargar_contratos_montos <- function(ruta = "datos/contratos_montos.csv") {
  readr::read_csv(
    ruta,
    locale = readr::locale(encoding = "UTF-8"),
    show_col_types = FALSE
  ) |>
    janitor::clean_names() |>
    # Eliminar columna índice auxiliar
    dplyr::select(-any_of(c("h1", "1"))) |>
    dplyr::mutate(
      across(starts_with("fecha"), ~ lubridate::ymd(.x)),
      costo = as.numeric(costo),
      partido = as.factor(partido)
    )
}


# -----------------------------------------------------------------------------
# 2. EXPLORACIÓN RÁPIDA
# -----------------------------------------------------------------------------

#' Resumen rápido de un dataframe
#'
#' @param df Un dataframe o tibble
#' @param nombre Nombre descriptivo del dataset (para imprimir en consola)
#' @return Invisible: imprime el resumen en consola
resumen_rapido <- function(df, nombre = "Dataset") {
  cat("=================================================\n")
  cat(sprintf("  %s\n", nombre))
  cat("=================================================\n")
  cat(sprintf("  Filas    : %s\n", format(nrow(df), big.mark = ",")))
  cat(sprintf("  Columnas : %d\n", ncol(df)))
  cat(sprintf("  Periodo  : %s a %s\n",
              min(df$ano, na.rm = TRUE),
              max(df$ano, na.rm = TRUE)))
  cat(sprintf("  Costo total: $%s MXN\n",
              format(sum(df$costo, na.rm = TRUE), big.mark = ",", nsmall = 2)))
  cat("  Columnas : ", paste(names(df), collapse = ", "), "\n")
  cat("=================================================\n\n")
  invisible(df)
}

#' Contar valores faltantes por columna
#'
#' @param df Un dataframe o tibble
#' @return Un tibble con columna, n_na y pct_na ordenado de mayor a menor
contar_nas <- function(df) {
  df |>
    dplyr::summarise(across(everything(), ~ sum(is.na(.)))) |>
    tidyr::pivot_longer(everything(), names_to = "columna", values_to = "n_na") |>
    dplyr::mutate(pct_na = round(n_na / nrow(df) * 100, 1)) |>
    dplyr::arrange(desc(n_na)) |>
    dplyr::filter(n_na > 0)
}


# -----------------------------------------------------------------------------
# 3. COMPARACIÓN DE DATASETS
# -----------------------------------------------------------------------------

#' Comparar dos dataframes e identificar IDs exclusivos
#'
#' @param df1 Primer dataframe (debe tener columna `id`)
#' @param df2 Segundo dataframe (debe tener columna `id`)
#' @param nombre1 Nombre del primer dataset
#' @param nombre2 Nombre del segundo dataset
#' @return Una lista con: ids_comunes, solo_en_df1, solo_en_df2
comparar_ids <- function(df1, df2,
                          nombre1 = "contratos",
                          nombre2 = "contratos_montos") {
  ids1 <- unique(df1$id)
  ids2 <- unique(df2$id)

  comunes    <- intersect(ids1, ids2)
  solo_en_1  <- setdiff(ids1, ids2)
  solo_en_2  <- setdiff(ids2, ids1)

  cat(sprintf("IDs en '%s' : %s\n", nombre1, format(length(ids1), big.mark = ",")))
  cat(sprintf("IDs en '%s' : %s\n", nombre2, format(length(ids2), big.mark = ",")))
  cat(sprintf("IDs comunes        : %s\n", format(length(comunes), big.mark = ",")))
  cat(sprintf("Solo en '%s' : %s\n", nombre1, format(length(solo_en_1), big.mark = ",")))
  cat(sprintf("Solo en '%s' : %s\n\n", nombre2, format(length(solo_en_2), big.mark = ",")))

  invisible(list(
    ids_comunes  = comunes,
    solo_en_df1  = solo_en_1,
    solo_en_df2  = solo_en_2
  ))
}

#' Comparar columnas entre dos dataframes
#'
#' @param df1 Primer dataframe
#' @param df2 Segundo dataframe
#' @param nombre1 Nombre del primer dataset
#' @param nombre2 Nombre del segundo dataset
#' @return Invisible: imprime las diferencias en consola
comparar_columnas <- function(df1, df2,
                               nombre1 = "contratos",
                               nombre2 = "contratos_montos") {
  cols1 <- names(df1)
  cols2 <- names(df2)

  solo1 <- setdiff(cols1, cols2)
  solo2 <- setdiff(cols2, cols1)
  comun <- intersect(cols1, cols2)

  cat(sprintf("Columnas solo en '%s' (%d): %s\n",
              nombre1, length(solo1),
              ifelse(length(solo1) == 0, "ninguna", paste(solo1, collapse = ", "))))
  cat(sprintf("Columnas solo en '%s' (%d): %s\n",
              nombre2, length(solo2),
              ifelse(length(solo2) == 0, "ninguna", paste(solo2, collapse = ", "))))
  cat(sprintf("Columnas en común : %d\n\n", length(comun)))

  invisible(list(solo_en_df1 = solo1, solo_en_df2 = solo2, comunes = comun))
}


# -----------------------------------------------------------------------------
# 4. UTILIDADES DE FORMATO
# -----------------------------------------------------------------------------

#' Formatear montos en pesos mexicanos (MXN)
#'
#' @param x Vector numérico con montos
#' @return Vector de caracteres formateado (ej: "$1,234,567.89")
formato_pesos <- function(x) {
  paste0("$", format(round(x, 2), big.mark = ",", nsmall = 2))
}

#' Paleta de colores para partidos políticos mexicanos
paleta_partidos <- c(
  "PAN"    = "#003B8D",   # Azul PAN
  "PRI"    = "#CE1126",   # Rojo PRI
  "PRD"    = "#FDD116",   # Amarillo PRD
  "Morena" = "#8B1A1A",   # Guinda Morena
  "MC"     = "#FF6600",   # Naranja Movimiento Ciudadano
  "PVEM"   = "#2E8B57",   # Verde PVEM
  "PT"     = "#CC0000",   # Rojo PT
  "NA"     = "#4169E1",   # Azul Nueva Alianza
  "PES"    = "#6A0DAD"    # Morado PES
)


# -----------------------------------------------------------------------------
# 5. FEATURES DE PROVEEDOR Y MODELADO (notebook 02_prediccion)
# -----------------------------------------------------------------------------

#' Forzar orden canónico de partidos como factor
#'
#' @param x Vector de caracteres o factor con nombres de partidos
#' @return Factor con niveles c("PAN","PRI","PRD","Morena","MC","PVEM","PT")
forzar_orden_partidos <- function(x) {
  factor(x, levels = c("PAN", "PRI", "PRD", "Morena", "MC", "PVEM", "PT"))
}

#' Construir features de proveedor a nivel de contrato individual
#'
#' @param df Dataframe output de cargar_contratos_montos()
#' @return El mismo tibble con columnas derivadas agregadas
construir_features_proveedor <- function(df) {
  df |>
    mutate(
      duracion_dias    = as.numeric(fecha_fin_vigencia - fecha_inicio_vigencia),
      mes_firma        = lubridate::month(fecha_firma),
      es_diciembre     = mes_firma == 12,
      log_costo        = log1p(costo),
      alto_valor       = costo > median(costo, na.rm = TRUE),
      es_persona_moral = tipo_persona == "Moral"
    )
}

#' Crear perfil agregado por proveedor
#'
#' Requiere que el df haya pasado por construir_features_proveedor() primero,
#' ya que usa las columnas mes_firma y duracion_dias.
#'
#' @param df Dataframe con features de construir_features_proveedor()
#' @return Tibble a nivel proveedor con variables resumen
perfil_proveedor <- function(df) {
  df |>
    group_by(nom_fisica_homo, moral_razon_homo) |>
    summarise(
      n_contratos         = n(),
      costo_total         = sum(costo, na.rm = TRUE),
      costo_mediano       = median(costo, na.rm = TRUE),
      log_costo_mediano   = median(log1p(costo), na.rm = TRUE),
      n_partidos_distintos = n_distinct(partido),
      prop_diciembre      = mean(mes_firma == 12, na.rm = TRUE),
      prop_alto_valor     = mean(costo > median(costo, na.rm = TRUE), na.rm = TRUE),
      duracion_mediana    = median(duracion_dias, na.rm = TRUE),
      .groups = "drop"
    )
}
