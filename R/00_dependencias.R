# =============================================================================
# 00_dependencias.R
# Instala los paquetes que usan 01_preparacion.R y analysis/U1_producto.qmd
# y actualiza renv.lock. Ejecutar una sola vez desde la raíz del proyecto.
# =============================================================================
paquetes <- c("readxl", "dplyr", "tidyr", "writexl", "ggplot2", "scales",
              "survey", "lme4", "knitr", "rmarkdown")
renv::install(paquetes)
renv::snapshot(packages = c("renv", paquetes), prompt = FALSE)
