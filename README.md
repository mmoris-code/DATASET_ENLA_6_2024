# Determinantes socioeducativos del rendimiento en lectura y matemática (ENLA 2024, 6.° primaria)

**Autores:** María del Pilar Mori Sánchez y Boris Jesús Arce Saavedra
**Institución:** Escuela de Posgrado, Universidad Peruana Unión (UPeU). Segunda Especialidad en Ciencia de Datos e IA Aplicada
**Versión:** `v1.0-unidad1` (Producto de la Unidad I)

## Pregunta de investigación
¿De qué manera el área geográfica, la gestión de la institución educativa y el sexo del estudiante se asocian con la medida y el nivel de logro en lectura y matemática de los estudiantes de 6.° grado de primaria evaluados en la ENLA 2024?

## Datos
- **Fuente:** Ministerio de Educación del Perú, Oficina de Medición de la Calidad de los Aprendizajes (UMC). Evaluación Nacional de Logros de Aprendizaje (ENLA) 2024, 6.° grado de primaria, base muestral.
- **Archivo crudo:** `data/raw/BD_6P ENLA muestral 2024.xlsx` (105 242 estudiantes, 21 variables). No se modifica.
- **Dataset curado:** `data/processed/enla6p_2024_curado.rds` y `.csv` (105 242 filas, 33 variables).
- **Términos de uso:** base de acceso público de la UMC; verificar las condiciones vigentes en el portal antes de redistribuir.

## Estructura
```
data/raw/            datos crudos (solo lectura)
data/processed/      dataset curado listo para modelar
R/00_dependencias.R  instalación de paquetes y actualización de renv.lock
R/01_preparacion.R   crudo -> curado, diccionario y registro de decisiones
analysis/            reporte Quarto (U1_producto.qmd) y su HTML renderizado
docs/                diccionario de datos, registro de decisiones y bitácora
```

## Cómo reproducir
1. Clone el repositorio y abra `DATASET_ENLA_6_2024.Rproj` en RStudio.
2. En la consola: `renv::restore()`. Si `renv.lock` aún no incluye los paquetes, ejecute `source("R/00_dependencias.R")`.
3. Prepare los datos: `source("R/01_preparacion.R")`.
4. Renderice el reporte desde la pestaña Terminal de RStudio: `quarto render analysis/U1_producto.qmd`.

## Uso de IA generativa
- **Herramienta:** Claude (Anthropic).
- **Etapa:** preparación de datos, ingeniería de características y redacción del reporte.
- **Para qué:** estructurar el script de preparación, el diccionario y el registro de decisiones, y redactar una versión preliminar del reporte.
- **Verificación:** todas las cifras se calculan por código; los autores revisaron el código y contrastaron conteos, faltantes y medias con la base cruda.
