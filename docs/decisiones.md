# Registro de Decisiones Metodológicas

| Fecha | Decisión | Motivo / Justificación |
| :--- | :--- | :--- |
| 04/11/2026 | Selección del dataset ENLA 2024 (6.° grado) | Permite analizar relaciones multivariadas con 105,242 estudiantes a nivel nacional. |
| 04/11/2026 | Estructuración de directorios del proyecto | Separar datos crudos (`data/raw`) de procesados para asegurar trazabilidad. |
| 04/11/2026 | Congelación de dependencias con `renv` | Garantizar la reproducibilidad computacional exacta ante futuras actualizaciones de paquetes. || 12/11/2026 | Script de preparación `R/01_preparacion.R` con validaciones que detienen la ejecución | Obtener el dataset curado sin pasos manuales y detectar errores de integridad antes de modelar. |
| 12/11/2026 | No imputar puntajes faltantes y usar el diseño muestral complejo | Los puntajes son variables respuesta y el faltante coincide con la ausencia de peso (estudiante no evaluado). |
| 12/11/2026 | Hipótesis H1 a H4 y decisiones para la Unidad II | Validación agrupada por IE, control de fuga de información y métricas para clases desbalanceadas. |

El registro detallado de decisiones de limpieza e ingeniería de variables (Unidad I) se genera por código en `docs/registro_decisiones.csv` y se presenta en la Tabla 2 de `analysis/U1_producto.html`.
