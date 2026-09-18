# Reglas de Contexto del Proyecto - usac_campus_map

Este documento registra los lineamientos y directrices permanentes para el desarrollo de la librería modular `usac_campus_map`.

---

## 1. Estrategia Git Flow y Convenciones de Ramas
- **Ramas Principales:**
  - `main`: Rama de código estable en producción / releases finales.
  - `develop`: Rama base de integración y desarrollo activo.
- **Ramas de Soporte:**
  - `feature/<nombre-feature>`: Nuevas funcionalidades o módulos derivados de `develop`. Se integran de vuelta a `develop`.
  - `bugfix/<nombre-arreglo>`: Corrección de errores en `develop`.
  - `release/<version>`: Preparación, estabilización y pruebas de una versión candidata.
  - `hotfix/<nombre-fix>`: Correcciones críticas urgentes derivadas de `main`.
- **Conventional Commits:**
  - Todos los mensajes de commit deben seguir el estándar `tipo(alcance): descripción`, por ejemplo:
    - `feat: ...` (nuevas características)
    - `fix: ...` (correcciones de errores)
    - `chore: ...` (mantenimiento, configuración, dependencias)
    - `docs: ...` (documentación y diagramas)
    - `refactor: ...` (reestructuración sin alterar comportamiento)
    - `test: ...` (pruebas unitarias / integración)

---

## 2. Documentación Profesional y Exhaustiva
- Toda la librería debe estar documentada de forma exhaustiva y profesional.
- **Diagramas obligatorios:**
  - Diagramas de arquitectura y estructura de capas.
  - Diagramas de clases / componentes (Mermaid).
  - Diagramas de secuencia y flujo de datos (seguimiento de geolocalización, interacción con el mapa).
- Inclusión de guías de instalación, ejemplos de uso y especificación detallada de cada API pública en el `README.md` o en la carpeta `docs/`.

---

## 3. Estándares de Código
- **Sin comentarios en el código:** No colocar comentarios explicativos dentro del código fuente de la librería a menos que el usuario lo solicite explícitamente.
- Tipado estricto, inmutabilidad (`const`, `final`) y null-safety de Dart.
- Arquitectura modular limpia bajo `lib/src/` y exportación ordenada mediante archivo barril (`lib/usac_campus_map.dart`).
