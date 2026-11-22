# =============================================================================
# 02_dataset_modelado.R
# Genera el archivo de modelado de la Unidad II (sesiones 4 a 6) a partir del
# dataset curado de la Unidad I. Una fila por estudiante con medida observada
# en Matemática; solo predictores contextuales conocidos antes de la prueba.
# Uso (desde la raíz del proyecto): source("R/02_dataset_modelado.R")
# =============================================================================
ruta_cur <- file.path("data", "processed", "enla6p_2024_curado.rds")
if (!file.exists(ruta_cur)) source(file.path("R", "01_preparacion.R"))
d <- readRDS(ruta_cur)

mod <- d[!is.na(d$mat), c("id_ie", "gestion", "area", "sexo", "dre",
                          "n_eval_ie", "n_eval_seccion", "satisf_mat")]
mod$logro_mat <- ifelse(mod$satisf_mat == 1, "Satisfactorio", "No satisfactorio")
mod$satisf_mat <- NULL
mod$dre <- as.character(mod$dre)

stopifnot(!anyNA(mod))
utils::write.csv(mod, file.path("data", "processed", "enla6p_2024_modelado_mat.csv"),
                 row.names = FALSE, fileEncoding = "UTF-8")
message(sprintf("Archivo de modelado: %d filas, %d columnas; %.1f %% «Satisfactorio»",
                nrow(mod), ncol(mod), 100 * mean(mod$logro_mat == "Satisfactorio")))
