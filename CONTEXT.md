# Reglas de Contexto del Proyecto - usac_campus_map

Este documento registra los lineamientos y directrices permanentes para el desarrollo de la libreria modular usac_campus_map.

---

## 1. Estrategia Git Flow y Convenciones de Ramas
- Ramas Principales:
  - main: Rama de codigo estable en produccion / releases finales.
  - develop: Rama base de integracion y desarrollo activo.
- Ramas de Soporte:
  - feature/<nombre-feature>: Nuevas funcionalidades o modulos derivados de develop. Se integran de vuelta a develop.
  - bugfix/<nombre-arreglo>: Correccion de errores en develop.
  - release/<version>: Preparacion, estabilizacion y pruebas de una version candidata.
  - hotfix/<nombre-fix>: Correcciones criticas urgentes derivadas de main.
- Conventional Commits:
  - Todos los mensajes de commit deben seguir el estandar tipo(alcance): descripcion:
    - feat: (nuevas caracteristicas)
    - fix: (correcciones de errores)
    - chore: (mantenimiento, configuracion, dependencias)
    - docs: (documentacion y diagramas)
    - refactor: (reestructuracion sin alterar comportamiento)
    - test: (pruebas unitarias o integracion)

---

## 2. Politica de Formato y Estilo Profesional
- Cero emojis: No utilizar emojis en documentacion tecnica, commits, comentarios ni en el codigo fuente. Mantener tono estrictamente corporativo y profesional.
- Sin comentarios en el codigo: No colocar comentarios explicativos dentro del codigo fuente de la libreria salvo solicitud expresa del usuario.
- Tipado estricto, inmutabilidad (const, final) y null-safety de Dart.
- Arquitectura modular limpia bajo lib/src/ con exposicion controlada mediante archivo barril (lib/usac_campus_map.dart).
- Preservacion del proyecto de demostracion en la carpeta example/.

---

## 3. Propiedad Intelectual, Licenciamiento y Dependencias de Terceros
- Licencia de la libreria: Propiedad privada, confidencial y cerrada de Trebol4Devop (All Rights Reserved / Proprietary & Confidential). Prohibida su distribucion publica no autorizada.
- Compatibilidad legal de dependencias de terceros:
  - Unicamente se permite la incorporacion de dependencias bajo licencias permisivas no-copyleft: MIT, BSD (2-Clause y 3-Clause) y Apache 2.0.
  - Queda estrictamente prohibido el uso de dependencias bajo licencias copyleft fuertes o reciprocas (GPL, AGPL, o LGPL con riesgo de vinculacion estatica) que impidan la venta, monetizacion o cierre del codigo de productos derivados.

---

## 4. Documentacion Exhaustiva con Diagramas
- Toda la libreria debe contar con documentacion exhaustiva en README.md y carpetas de soporte.
- Inclusion obligatoria de diagramas Mermaid tecnicos:
  - Diagrama de Arquitectura de Capas.
  - Diagrama de Clases.
  - Diagrama de Secuencia y Flujo de Datos.
