# User Tier Badge

[ENGLISH](README.md) | **ESPAÑOL**

Componente de tema de Discourse que muestra el avance de un miembro por niveles de
insignias personalizados (no niveles de confianza). Cada nivel es un conjunto de insignias;
completar el conjunto desbloquea un grupo.

## Características

- **Progreso por nivel**: avatar, estadísticas de posts/likes/karma, una barra de progreso y
  una lista que nombra cada insignia que falta del nivel actual.
- **Niveles definidos por ids de insignias** en un ajuste `objects`, una fila por nivel con
  el grupo que desbloquea. Pertenecer al grupo también satisface el nivel, así que una
  suscripción o una concesión manual cuentan.
- **Insignias de nivel recientes**: quién obtuvo una más recientemente, de la más nueva a la más
  antigua, una fila por miembro.
- **Caché del navegador** con TTL configurable, para no repetir la consulta de insignias en
  cada vista de página.
- **Ubicable en cualquier lugar**: se renderiza en cualquier outlet de bloques mediante el
  ajuste `sidebar_outlet`, o por nombre desde otro tema
  (`theme:user-tier-badge:badge`, `theme:user-tier-badge:recent-badges`),
  incluso dentro de
  [discourse-right-sidebar-blocks](https://github.com/discourse/discourse-right-sidebar-blocks).

## Instalación

Súbelo en **Admin > Personalizar > Temas**, asócialo a tu tema activo y
completa el ajuste `tiers` con los ids de insignias y el grupo de cada nivel.

## Licencia

MIT. Consulta [LICENSE](LICENSE).

Texto de este README bajo [CC BY-NC-SA 4.0](CC-BY-NC-SA-4.0.txt).
