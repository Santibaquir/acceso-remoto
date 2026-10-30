# Skills de Claude Code para desarrollar una app

Oct 30, 2026 · @santiago rios

## Diseño distinto y bien hecho

Para el diseño, la skill principal es `frontend-design`: evita el look genérico de plantilla, define una dirección estética, elige tipografías con criterio y toma decisiones visuales intencionales.

Para sacarle el máximo, dale contexto en el prompt: qué app es, quién la usará y qué estilo quieres (editorial, brutalista, retro…). Por ejemplo: "app para X, público Y, estilo editorial, evita el típico degradado morado".

Si la app tiene gráficos o paneles de datos, añade `dataviz`, que mantiene colores, ejes y leyendas consistentes.

## Estructura del código

Seis skills del plugin de ingeniería cubren todo el ciclo, desde el diseño inicial hasta la documentación.

| Skill | Cuándo usarla |
| --- | --- |
| `system-design` | Al inicio: carpetas, capas, modelo de datos, diseño de API y límites entre módulos. |
| `architecture` | Al elegir entre tecnologías (React vs Vue, SQL vs NoSQL) y dejar la decisión documentada. |
| `testing-strategy` | Para definir qué probar y cómo organizar las pruebas. |
| `code-review` | Después de cada bloque grande de código: fallos de seguridad, rendimiento y casos borde. |
| `tech-debt` | Cuando el proyecto crezca, para decidir qué refactorizar. |
| `documentation` | Para un README claro y la documentación del proyecto. |

## Orden recomendado

1. `system-design` y `architecture`: definir estructura y stack.
2. `frontend-design`: definir y construir la interfaz.
3. `testing-strategy` y `code-review`: mientras desarrollas.
4. `documentation`: al cerrar.

Una buena práctica es pedirle a Claude Code que primero proponga la arquitectura y la guarde en un archivo `CLAUDE.md`. Así sigue esas reglas durante toda la sesión y el código no se desordena.
