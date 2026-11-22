# Registro de Decisiones Metodológicas

| Fecha | Decisión | Motivo / Justificación |
| :--- | :--- | :--- |
| 04/11/2026 | Selección del dataset ENLA 2024 (6.° grado) | Permite analizar relaciones multivariadas con 105,242 estudiantes a nivel nacional. |
| 04/11/2026 | Estructuración de directorios del proyecto | Separar datos crudos (`data/raw`) de procesados para asegurar trazabilidad. |
| 04/11/2026 | Congelación de dependencias con `renv` | Garantizar la reproducibilidad computacional exacta ante futuras actualizaciones de paquetes. || 12/11/2026 | Script de preparación `R/01_preparacion.R` con validaciones que detienen la ejecución | Obtener el dataset curado sin pasos manuales y detectar errores de integridad antes de modelar. |
| 12/11/2026 | No imputar puntajes faltantes y usar el diseño muestral complejo | Los puntajes son variables respuesta y el faltante coincide con la ausencia de peso (estudiante no evaluado). |
| 12/11/2026 | Hipótesis H1 a H4 y decisiones para la Unidad II | Validación agrupada por IE, control de fuga de información y métricas para clases desbalanceadas. |

El registro detallado de decisiones de limpieza e ingeniería de variables (Unidad I) se genera por código en `docs/registro_decisiones.csv` y se presenta en la Tabla 2 de `analysis/U1_producto.html`.

## Unidad II (sesiones 4 a 6)

| Fecha | Decisión | Motivo / Justificación |
| :--- | :--- | :--- |
| 17/11/2026 | Variable respuesta: logro satisfactorio en Matemática (`satisf_mat`, 14,4 % positivos) | Clasificación binaria exigida por los laboratorios; Matemática concentra el menor logro. |
| 17/11/2026 | Excluir del modelado los resultados de Lectura y todas las variables derivadas de la medida de Matemática | Evitar fuga de información. |
| 22/11/2026 | Archivo de modelado `data/processed/enla6p_2024_modelado_mat.csv` (`R/02_dataset_modelado.R`) | Separar las variables predictoras conocidas antes de la prueba y la respuesta en texto (`logro_mat`) para el cuaderno de redes. |
| 22/11/2026 | Tamaño de lote 256 en las redes (el cuaderno original usa 32) | Con 58 230 casos de estudio, un lote de 32 multiplica por cinco el tiempo; con 256 hay unas 228 actualizaciones por época. |
| 22/11/2026 | Reportar errores también con umbral = proporción de positivos en el entrenamiento (0,144) | Con clase minoritaria del 14 %, el umbral 0,5 casi no detecta positivos. |
| 22/11/2026 | Elección final: Elastic Net | Empata con LightGBM, stacking y redes dentro de la variabilidad práctica y es el más interpretable (parsimonia). |
