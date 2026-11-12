# =============================================================================
# 01_preparacion.R
# Proyecto : Determinantes socioeducativos del rendimiento en lectura y
#            matemática - ENLA 2024, 6.° grado de primaria (muestral)
# Autores  : María del Pilar Mori Sánchez y Boris Jesús Arce Saavedra
# Propósito: transformar el archivo crudo del MINEDU (data/raw) en el dataset
#            curado (data/processed), el diccionario de datos y el registro de
#            decisiones (docs). Se ejecuta de inicio a fin sin intervención
#            manual desde la raíz del proyecto:
#                source("R/01_preparacion.R")
#            o, desde una terminal:  Rscript R/01_preparacion.R
# =============================================================================

paquetes <- c("readxl", "dplyr", "writexl")
faltan <- paquetes[!vapply(paquetes, requireNamespace, logical(1), quietly = TRUE)]
if (length(faltan) > 0) {
  stop("Instale los paquetes faltantes con renv::restore() o install.packages(): ",
       paste(faltan, collapse = ", "))
}
suppressPackageStartupMessages(library(dplyr))

# -----------------------------------------------------------------------------
# 0. Rutas
# -----------------------------------------------------------------------------
ruta_raw  <- file.path("data", "raw", "BD_6P ENLA muestral 2024.xlsx")
dir_proc  <- file.path("data", "processed")
dir_docs  <- "docs"
if (!file.exists(ruta_raw)) {
  stop("No se encuentra ", ruta_raw, ". Ejecute el script desde la raíz del proyecto.")
}
dir.create(dir_proc, showWarnings = FALSE, recursive = TRUE)
dir.create(dir_docs, showWarnings = FALSE, recursive = TRUE)

# -----------------------------------------------------------------------------
# 1. Lectura de los datos crudos (solo lectura; el archivo no se modifica)
# -----------------------------------------------------------------------------
raw <- readxl::read_excel(ruta_raw, sheet = "BD")
raw <- as.data.frame(raw)
n_raw <- nrow(raw)
p_raw <- ncol(raw)

# -----------------------------------------------------------------------------
# 2. Validaciones de integridad (el script se detiene si alguna falla)
# -----------------------------------------------------------------------------
clave <- paste(raw$ID_IE, raw$ID_SECCION, raw$cor_est, sep = "_")
n_dup_clave <- sum(duplicated(clave))
n_dup_fila  <- sum(duplicated(raw))

stopifnot(
  "Columnas esperadas ausentes" = all(c(
    "ID_IE", "ID_SECCION", "cor_est", "cod_DRE", "nom_dre", "cod_UGEL",
    "nom_ugel", "codgeo", "departamento", "provincia", "distrito", "gestion2",
    "area", "sexo", "M500_EM_6P_2024_CT", "grupo_EM_6P_2024_CT",
    "M500_EM_6P_2024_MA", "grupo_EM_6P_2024_MA", "peso_Lectura", "peso_Mate",
    "Estrato_DRE") %in% names(raw)),
  "Códigos fuera de rango en gestion2" = all(raw$gestion2 %in% 1:2),
  "Códigos fuera de rango en area"     = all(raw$area %in% 1:2),
  "Códigos fuera de rango en sexo"     = all(raw$sexo %in% 1:2),
  "Niveles de logro fuera de rango" =
    all(raw$grupo_EM_6P_2024_CT %in% c(1:4, NA)) &&
    all(raw$grupo_EM_6P_2024_MA %in% c(1:4, NA)),
  "Peso faltante no coincide con puntaje faltante (lectura)" =
    identical(is.na(raw$peso_Lectura), is.na(raw$M500_EM_6P_2024_CT)),
  "Peso faltante no coincide con puntaje faltante (matemática)" =
    identical(is.na(raw$peso_Mate), is.na(raw$M500_EM_6P_2024_MA)),
  "Nivel faltante no coincide con puntaje faltante" =
    identical(is.na(raw$grupo_EM_6P_2024_CT), is.na(raw$M500_EM_6P_2024_CT)) &&
    identical(is.na(raw$grupo_EM_6P_2024_MA), is.na(raw$M500_EM_6P_2024_MA))
)

# Cada IE debe tener una sola gestión y una sola área
ie_inconsist <- raw |>
  group_by(ID_IE) |>
  summarise(k_g = n_distinct(gestion2), k_a = n_distinct(area), .groups = "drop") |>
  filter(k_g > 1 | k_a > 1) |>
  nrow()
stopifnot("IE con gestión o área inconsistente" = ie_inconsist == 0)

# Los niveles de logro deben corresponder a intervalos no solapados de la medida
rangos_nivel <- function(score, nivel) {
  r <- aggregate(score, by = list(nivel = nivel), FUN = range)
  r <- data.frame(nivel = r$nivel, min = r$x[, 1], max = r$x[, 2])
  r[order(r$nivel), ]
}
rn_lect <- rangos_nivel(raw$M500_EM_6P_2024_CT, raw$grupo_EM_6P_2024_CT)
rn_mat  <- rangos_nivel(raw$M500_EM_6P_2024_MA, raw$grupo_EM_6P_2024_MA)
stopifnot(
  "Niveles de lectura solapados" = all(head(rn_lect$max, -1) < tail(rn_lect$min, -1)),
  "Niveles de matemática solapados" = all(head(rn_mat$max, -1) < tail(rn_mat$min, -1))
)

# -----------------------------------------------------------------------------
# 3. Limpieza, recodificación e ingeniería de características
# -----------------------------------------------------------------------------
lab_nivel <- c("Previo al inicio", "En inicio", "En proceso", "Satisfactorio")

curado <- raw |>
  mutate(
    id_est   = paste(ID_IE, ID_SECCION, cor_est, sep = "_"),
    id_ie    = as.integer(ID_IE),
    id_seccion = paste(ID_IE, ID_SECCION, sep = "_"),
    cod_dre  = as.integer(cod_DRE),
    dre      = factor(nom_dre),
    cod_ugel = as.integer(cod_UGEL),
    ugel     = nom_ugel,
    ubigeo   = sprintf("%06d", as.integer(codgeo)),
    departamento, provincia, distrito,
    estrato  = as.integer(Estrato_DRE),
    gestion  = factor(gestion2, levels = 1:2, labels = c("Pública", "Privada")),
    area     = factor(area, levels = 1:2, labels = c("Urbana", "Rural")),
    sexo     = factor(sexo, levels = 1:2, labels = c("Hombre", "Mujer")),
    gestion_area = factor(paste(gestion, area, sep = "-"),
                          levels = c("Pública-Urbana", "Pública-Rural",
                                     "Privada-Urbana", "Privada-Rural")),
    lect     = M500_EM_6P_2024_CT,
    mat      = M500_EM_6P_2024_MA,
    nivel_lect = factor(grupo_EM_6P_2024_CT, levels = 1:4, labels = lab_nivel,
                        ordered = TRUE),
    nivel_mat  = factor(grupo_EM_6P_2024_MA, levels = 1:4, labels = lab_nivel,
                        ordered = TRUE),
    satisf_lect  = as.integer(grupo_EM_6P_2024_CT == 4),
    satisf_mat   = as.integer(grupo_EM_6P_2024_MA == 4),
    satisf_ambas = as.integer(grupo_EM_6P_2024_CT == 4 & grupo_EM_6P_2024_MA == 4),
    falta_lect = as.integer(is.na(M500_EM_6P_2024_CT)),
    falta_mat  = as.integer(is.na(M500_EM_6P_2024_MA)),
    peso_lect  = peso_Lectura,
    peso_mat   = peso_Mate,
    .keep = "none"
  ) |>
  group_by(id_ie) |>
  mutate(n_eval_ie = n()) |>
  ungroup() |>
  group_by(id_seccion) |>
  mutate(n_eval_seccion = n()) |>
  ungroup() |>
  mutate(
    # Estandarización exploratoria (media y DE de toda la muestra disponible).
    # En la Unidad II debe reajustarse dentro de cada pliegue de validación.
    z_lect = as.numeric(scale(lect)),
    z_mat  = as.numeric(scale(mat)),
    atip_lect = as.integer(abs(z_lect) > 3),
    atip_mat  = as.integer(abs(z_mat) > 3)
  ) |>
  relocate(id_est, id_ie, id_seccion, cod_dre, dre, cod_ugel, ugel, ubigeo,
           departamento, provincia, distrito, estrato, gestion, area,
           gestion_area, sexo, n_eval_ie, n_eval_seccion,
           lect, nivel_lect, satisf_lect, falta_lect, z_lect, atip_lect, peso_lect,
           mat, nivel_mat, satisf_mat, falta_mat, z_mat, atip_mat, peso_mat,
           satisf_ambas) |>
  as.data.frame()

stopifnot(nrow(curado) == n_raw, !anyDuplicated(curado$id_est))

# -----------------------------------------------------------------------------
# 4. Exportación del dataset curado
# -----------------------------------------------------------------------------
saveRDS(curado, file.path(dir_proc, "enla6p_2024_curado.rds"))
utils::write.csv(curado, file.path(dir_proc, "enla6p_2024_curado.csv"),
                 row.names = FALSE, na = "", fileEncoding = "UTF-8")

# -----------------------------------------------------------------------------
# 5. Diccionario de datos (incluye variables derivadas)
# -----------------------------------------------------------------------------
fuente <- "MINEDU-UMC, ENLA 2024 6.° primaria (BD_6P ENLA muestral 2024.xlsx, hoja BD)"
der    <- "Derivada en 01_preparacion.R"
fmt_rng <- function(x) sprintf("%.3f a %.3f", min(x, na.rm = TRUE), max(x, na.rm = TRUE))

diccionario <- data.frame(
  variable = names(curado),
  stringsAsFactors = FALSE
)
info <- list(
  id_est = c("Identificador único del estudiante (anonimizado)", "carácter", "código", "ID_IE_ID_SECCION_cor_est; único", fuente, "Concatenación de ID_IE, ID_SECCION y cor_est; reemplaza a cor_est"),
  id_ie = c("Identificador anonimizado de la institución educativa (conglomerado del diseño)", "entero", "código", sprintf("1 a %d (%d IE)", max(curado$id_ie), n_distinct(curado$id_ie)), fuente, "Renombrado de ID_IE"),
  id_seccion = c("Identificador único de sección dentro de la IE", "carácter", "código", "ID_IE_ID_SECCION", fuente, "Concatenación de ID_IE e ID_SECCION"),
  cod_dre = c("Código de la Dirección Regional de Educación", "entero", "código", "100 a 2500", fuente, "Renombrado de cod_DRE"),
  dre = c("Nombre de la DRE", "factor", "nominal", sprintf("%d niveles", nlevels(curado$dre)), fuente, "nom_dre convertido a factor"),
  cod_ugel = c("Código de la Unidad de Gestión Educativa Local", "entero", "código", sprintf("%d UGEL", n_distinct(curado$cod_ugel)), fuente, "Renombrado de cod_UGEL"),
  ugel = c("Nombre de la UGEL", "carácter", "nominal", "texto", fuente, "Renombrado de nom_ugel"),
  ubigeo = c("Código de ubicación geográfica INEI (distrito)", "carácter", "código de 6 dígitos", "010101 a 250401", fuente, "codgeo formateado con ceros a la izquierda para enlazar fuentes INEI"),
  departamento = c("Departamento", "carácter", "nominal", "25 departamentos", fuente, "Sin cambios"),
  provincia = c("Provincia", "carácter", "nominal", "texto", fuente, "Sin cambios"),
  distrito = c("Distrito", "carácter", "nominal", "texto", fuente, "Sin cambios"),
  estrato = c("Estrato muestral (Estrato_DRE)", "entero", "código", sprintf("%d estratos", n_distinct(curado$estrato)), fuente, "Renombrado de Estrato_DRE; se usa como estrato del diseño muestral"),
  gestion = c("Gestión de la IE", "factor", "nominal", "Pública; Privada", fuente, "Recodificación de gestion2 (1 = Pública, 2 = Privada)"),
  area = c("Área donde se ubica la IE", "factor", "nominal", "Urbana; Rural", fuente, "Recodificación de area (1 = Urbana, 2 = Rural)"),
  gestion_area = c("Combinación de gestión y área", "factor", "nominal", "Pública-Urbana; Pública-Rural; Privada-Urbana; Privada-Rural", der, "Cruce de gestion y area; Privada-Rural tiene n = 381"),
  sexo = c("Sexo del estudiante", "factor", "nominal", "Hombre; Mujer", fuente, "Recodificación de sexo (1 = Hombre, 2 = Mujer)"),
  n_eval_ie = c("Número de estudiantes evaluados de la IE en la muestra", "entero", "estudiantes", sprintf("%d a %d", min(curado$n_eval_ie), max(curado$n_eval_ie)), der, "Conteo por id_ie; variable contextual, no usa información de resultados"),
  n_eval_seccion = c("Número de estudiantes evaluados de la sección en la muestra", "entero", "estudiantes", sprintf("%d a %d", min(curado$n_eval_seccion), max(curado$n_eval_seccion)), der, "Conteo por id_seccion"),
  lect = c("Medida promedio en Lectura (escala ENLA)", "numérico", "puntos de la escala de medida (TRI)", fmt_rng(curado$lect), fuente, "Renombrado de M500_EM_6P_2024_CT; faltantes sin imputar"),
  nivel_lect = c("Nivel de logro en Lectura", "factor ordenado", "ordinal", paste(lab_nivel, collapse = " < "), fuente, "Recodificación de grupo_EM_6P_2024_CT (1 a 4)"),
  satisf_lect = c("Logro satisfactorio en Lectura", "entero", "binaria", "0 = no; 1 = sí; NA = no evaluado", der, "1 si grupo_EM_6P_2024_CT = 4"),
  falta_lect = c("Indicador de puntaje de Lectura faltante", "entero", "binaria", "0 = observado; 1 = faltante", der, "1 si M500_EM_6P_2024_CT es NA"),
  z_lect = c("Medida de Lectura estandarizada", "numérico", "desviaciones estándar", fmt_rng(curado$z_lect), der, "(lect - media) / DE sobre la muestra disponible; uso exploratorio"),
  atip_lect = c("Indicador de valor atípico en Lectura", "entero", "binaria", "0; 1; NA", der, "1 si |z_lect| > 3; los casos se conservan"),
  peso_lect = c("Factor de expansión de Lectura", "numérico", "estudiantes representados", fmt_rng(curado$peso_lect), fuente, "Renombrado de peso_Lectura"),
  mat = c("Medida promedio en Matemática (escala ENLA)", "numérico", "puntos de la escala de medida (TRI)", fmt_rng(curado$mat), fuente, "Renombrado de M500_EM_6P_2024_MA; faltantes sin imputar"),
  nivel_mat = c("Nivel de logro en Matemática", "factor ordenado", "ordinal", paste(lab_nivel, collapse = " < "), fuente, "Recodificación de grupo_EM_6P_2024_MA (1 a 4)"),
  satisf_mat = c("Logro satisfactorio en Matemática", "entero", "binaria", "0 = no; 1 = sí; NA = no evaluado", der, "1 si grupo_EM_6P_2024_MA = 4"),
  falta_mat = c("Indicador de puntaje de Matemática faltante", "entero", "binaria", "0 = observado; 1 = faltante", der, "1 si M500_EM_6P_2024_MA es NA"),
  z_mat = c("Medida de Matemática estandarizada", "numérico", "desviaciones estándar", fmt_rng(curado$z_mat), der, "(mat - media) / DE sobre la muestra disponible; uso exploratorio"),
  atip_mat = c("Indicador de valor atípico en Matemática", "entero", "binaria", "0; 1; NA", der, "1 si |z_mat| > 3; los casos se conservan"),
  peso_mat = c("Factor de expansión de Matemática", "numérico", "estudiantes representados", fmt_rng(curado$peso_mat), fuente, "Renombrado de peso_Mate"),
  satisf_ambas = c("Logro satisfactorio simultáneo en ambas áreas", "entero", "binaria", "0; 1; NA si falta alguna prueba", der, "1 si nivel 4 en Lectura y en Matemática")
)
stopifnot(setequal(names(info), names(curado)))
m <- do.call(rbind, info[diccionario$variable])
diccionario <- data.frame(
  variable = diccionario$variable,
  descripcion = m[, 1], tipo = m[, 2], unidad_escala = m[, 3],
  valores_validos = m[, 4], fuente_origen = m[, 5], transformacion = m[, 6],
  n_faltantes = vapply(curado, function(x) sum(is.na(x)), integer(1)),
  row.names = NULL, stringsAsFactors = FALSE
)
utils::write.csv(diccionario, file.path(dir_docs, "diccionario_datos.csv"),
                 row.names = FALSE, fileEncoding = "UTF-8")
writexl::write_xlsx(list(diccionario = diccionario),
                    file.path(dir_docs, "diccionario_datos.xlsx"))

# -----------------------------------------------------------------------------
# 6. Registro de decisiones (cifras calculadas, no escritas a mano)
# -----------------------------------------------------------------------------
n_lect <- sum(!is.na(curado$lect)); n_mat <- sum(!is.na(curado$mat))
n_ambas <- sum(!is.na(curado$lect) & !is.na(curado$mat))
pct <- function(a, b) paste0(formatC(100 * a / b, format = "f", digits = 1, decimal.mark = ","), " %")
n_atl <- sum(curado$atip_lect, na.rm = TRUE); n_atm <- sum(curado$atip_mat, na.rm = TRUE)
n_pr  <- sum(curado$gestion_area == "Privada-Rural")
n_str1 <- curado |> distinct(estrato, id_ie) |> count(estrato) |> filter(n == 1) |> nrow()

decisiones <- data.frame(
  id = sprintf("D%02d", 1:13),
  etapa = c("Gobernanza", "Integridad", "Integridad", "Faltantes", "Atípicos",
            "Codificación", "Codificación", "Variables derivadas",
            "Variables derivadas", "Escalamiento", "Diseño muestral",
            "Selección/reducción", "Privacidad"),
  decision = c(
    "Conservar el Excel original en data/raw/ sin modificaciones; todo cambio se aplica por código",
    "Construir id_est = ID_IE_ID_SECCION_cor_est y verificar unicidad",
    "Verificar coherencia interna: códigos válidos, una gestión y un área por IE, niveles de logro sin solapamiento con la medida, peso faltante solo cuando falta el puntaje",
    sprintf("No imputar lect (%s faltante) ni mat (%s faltante); crear falta_lect y falta_mat; analizar cada área con sus casos disponibles", pct(n_raw - n_lect, n_raw), pct(n_raw - n_mat, n_raw)),
    sprintf("Conservar los valores extremos (|z| > 3: %d en lectura, %d en matemática) y marcarlos con atip_lect y atip_mat", n_atl, n_atm),
    "Recodificar gestion2, area y sexo a factores etiquetados según el diccionario del MINEDU",
    "Convertir los niveles de logro a factor ordenado y derivar satisf_lect, satisf_mat y satisf_ambas",
    sprintf("Crear gestion_area (4 categorías); la celda Privada-Rural tiene n = %d", n_pr),
    "Crear n_eval_ie y n_eval_seccion como variables contextuales de tamaño",
    "Estandarizar lect y mat (z_lect, z_mat) con la media y DE de la muestra completa, solo para el EDA",
    sprintf("Estimar descriptivos con el diseño complejo: conglomerado id_ie, estrato Estrato_DRE y peso específico de cada prueba; los estratos con una sola IE (%d) se tratan con survey.lonely.psu = 'adjust'", n_str1),
    "No aplicar Boruta, RFE ni PCA/t-SNE/UMAP en esta unidad",
    "Excluir cor_est del dataset curado (reemplazado por id_est) y no incorporar nombres, DNI ni códigos modulares"
  ),
  justificacion = c(
    "Trazabilidad y reproducibilidad: el crudo es la referencia para auditar cualquier transformación",
    "La base no trae identificador único de estudiante; la combinación de los tres campos lo es por construcción",
    "Detectar errores de digitación o de fusión antes de modelar; el script se detiene si alguna verificación falla",
    "Los puntajes son variables respuesta; el faltante coincide exactamente con la ausencia de peso, lo que indica estudiante no evaluado en esa prueba. Imputar la respuesta crearía información artificial y el diseño ya trata la no respuesta mediante los pesos",
    "Las medidas provienen de un modelo TRI y son valores plausibles de la escala; los extremos bajos se concentran en contextos vulnerables, de modo que eliminarlos sesgaría las brechas",
    "Evitar que R trate códigos nominales como cantidades y documentar las etiquetas oficiales",
    "El nivel de logro es la métrica de política educativa; la binaria satisfactorio/no permite plantear una tarea de clasificación en la Unidad II",
    "Gestión y área están asociadas; la combinación permite examinar el confusor y advierte sobre una celda escasa",
    "El número de evaluados aproxima el tamaño de la IE sin usar resultados de aprendizaje",
    "Facilitar comparaciones en unidades de DE y la detección de atípicos",
    "ENLA 2024 es una muestra estratificada por conglomerados con probabilidades desiguales; las medias sin ponderar no representan a la población de 6.° grado",
    "Solo existen cuatro predictores contextuales (gestión, área, sexo, DRE); la selección automática no aporta y una PCA sobre lect y mat mezclaría variables respuesta",
    "Minimización de datos personales; los identificadores de IE ya vienen anonimizados por el MINEDU"
  ),
  alternativa_descartada = c(
    "Editar o filtrar directamente el Excel",
    "Deduplicar por coincidencia de todas las columnas",
    "Confiar en la estructura del archivo sin verificar",
    sprintf("Eliminación por lista en ambas pruebas (n pasaría de %d a %d) o imputación múltiple de la respuesta", n_raw, n_ambas),
    sprintf("Eliminar o winsorizar los %d + %d casos extremos", n_atl, n_atm),
    "Mantener códigos numéricos 1/2",
    "Usar solo la medida continua",
    "Analizar gestión y área únicamente por separado",
    "Media de la IE en lectura o matemática (descartada por fuga de información)",
    "Estandarizar con parámetros fijos de la escala oficial (no publicados en la base)",
    "Estadísticos sin ponderar y errores estándar que asumen muestreo aleatorio simple",
    "Boruta/RFE sobre las cuatro variables o un índice compuesto lect-mat por PCA",
    "Conservar cor_est como variable"
  ),
  efecto = c(
    sprintf("Crudo intacto: %d filas x %d columnas", n_raw, p_raw),
    sprintf("%d duplicados por clave y %d filas duplicadas; n = %d", n_dup_clave, n_dup_fila, n_raw),
    sprintf("Todas las verificaciones superadas; %d IE inconsistentes", ie_inconsist),
    sprintf("n total = %d; n analítico lectura = %d; matemática = %d; ambas = %d", n_raw, n_lect, n_mat, n_ambas),
    "0 casos eliminados; 2 indicadores nuevos",
    "3 variables recodificadas; sin cambio en n",
    "2 factores ordenados y 3 binarias nuevas",
    "1 variable nueva",
    "2 variables nuevas",
    "2 variables nuevas; deben reajustarse dentro de la validación cruzada en la Unidad II",
    "Estimaciones representativas con IC 95 % de diseño; sin cambio en n",
    "Sin cambio en el número de variables",
    sprintf("Dataset curado: %d filas x %d columnas", nrow(curado), ncol(curado))
  ),
  stringsAsFactors = FALSE
)
utils::write.csv(decisiones, file.path(dir_docs, "registro_decisiones.csv"),
                 row.names = FALSE, fileEncoding = "UTF-8")

message(sprintf("Preparación completa: %d filas, %d variables -> %s",
                nrow(curado), ncol(curado), dir_proc))
