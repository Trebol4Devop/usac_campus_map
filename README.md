# usac_campus_map

Libreria modular en Flutter para la visualizacion interactiva del Campus Central de la Universidad de San Carlos de Guatemala (USAC), renderizado de huellas edilicias extraidas de OpenStreetMap, calculo de rutas multi-modal offline (caminando, bicicleta, vehiculo, accesible), busqueda difusa de edificios y puntos de interes (POIs), visualizacion de niveles interiores (indoor mapping) y control centralizado mediante `UsacCampusMapController`.

---

## Tabla de Contenidos

1. [Vision General y Filosofia](#vision-general-y-filosofia)
2. [Caracteristicas Principales](#caracteristicas-principales)
3. [Arquitectura del Sistema](#arquitectura-del-sistema)
4. [Diagramas de Flujo y Secuencia](#diagramas-de-flujo-y-secuencia)
   - [Flujo 1: Inicializacion y Arranque en Frio (Cold Boot)](#flujo-1-inicializacion-y-arranque-en-frio-cold-boot)
   - [Flujo 2: Busqueda Difusa e Indexacion](#flujo-2-busqueda-difusa-e-indexacion)
   - [Flujo 3: Planificacion de Rutas Multi-modal (A*)](#flujo-3-planificacion-de-rutas-multi-modal-a)
   - [Flujo 4: Navegacion en Tiempo Real y Snap-to-Path](#flujo-4-navegacion-en-tiempo-real-y-snap-to-path)
   - [Flujo 5: Cartografia de Interiores (Indoor Mapping)](#flujo-5-cartografia-de-interiores-indoor-mapping)
5. [Diagrama de Clases y Dominio](#diagrama-de-clases-y-dominio)
6. [Maquina de Estados del Controlador](#maquina-de-estados-del-controlador)
7. [Estructura de Directorios](#estructura-de-directorios)
8. [Especificacion de Datos Geograficos (Ground Truth)](#especificacion-de-datos-geograficos-ground-truth)
   - [Esquema de Edificios y Poligonos](#esquema-de-edificios-y-poligonos)
   - [Esquema del Grafo Vial y Peatonal](#esquema-del-grafo-vial-y-peatonal)
   - [Esquema de POIs y Planos Interiores](#esquema-de-pois-y-planos-interiores)
9. [Referencia de API y Componentes](#referencia-de-api-y-componentes)
   - [Controlador](#controlador-usaccampusmapcontroller)
   - [Motores de Procesamiento](#motores-de-procesamiento)
   - [Algoritmos del Core](#algoritmos-del-core)
   - [Widgets de Presentacion](#widgets-de-presentacion)
10. [Guia de Integracion y Ejemplos](#guia-de-integracion-y-ejemplos)
11. [Protocolo de Actualizacion y Mantenimiento](#protocolo-de-actualizacion-y-mantenimiento)
12. [Validacion y Cobertura de Pruebas](#validacion-y-cobertura-de-pruebas)

---

## Vision General y Filosofia

El diseno de `usac_campus_map` parte de una premisa estricta: **Cero Costo Operativo ($0 USD)** y **Funcionamiento 100% Offline**.

En entornos universitarios donde la cobertura de red celular puede ser irregular dentro de edificios de concreto armado, depender de APIs comerciales de mapas como Google Maps o Mapbox genera:
- Costos variables imprevistos por cuotas de consumo de API.
- Fallas de disponibilidad y latencia cuando el dispositivo pierde conexion de datos.
- Falta de granularidad en andadores peatonales internos, accesos a nivel de piso y planos de aulas.

Para solucionar esto, `usac_campus_map` empaqueta la cartografia vectorial, la topologia de la red de andadores, los puntos de interes y los planos de planta directamente como activos del paquete. Todo el procesamiento (calculo de distancias, enrutamiento heuristico A*, busqueda textual difusa y proyeccion geometrica) se ejecuta en el procesador del dispositivo cliente.

---

## Caracteristicas Principales

- **Cartografia Autentica y Detallada:** 248 geometrias procesadas directamente desde OpenStreetMap, incluyendo huellas arquitectonicas multiverdice para facultades, escuelas, 27 zonas de parqueo y areas deportivas.
- **Ruteo Multi-modal Inteligente:** Cuatro perfiles de desplazamiento independientes (peatonal, bicicleta, vehiculo y accesible para sillas de ruedas), penalizando o restringiendo tramos con gradas, pasarelas estrechas o calles de sentido unico.
- **Alineacion de Trayectoria GPS (`SnapToPath`):** Proyeccion ortogonal de coordenadas dispersas a los andadores oficiales mas cercanos con verificacion de umbral de desvio.
- **Buscador Instantaneo en Memoria:** Consultas difusas por codigo de edificio (ej. "T-3", "S-12", "M-1"), nombre comun, facultad o servicios disponibles con ponderacion de relevancia.
- **Soporte de Navegacion Interior (Indoor Mapping):** Desglose por niveles (Nivel 1, Nivel 2, Sótano, etc.), permitiendo conmutar la visibilidad de aulas y laboratorios internos.
- **Puntos de Acceso Oficiales (Garitas):** Localizacion y ruteo hacia las garitas principales (Periferico, Avenida Petapa y Las Charcas) como nodos integrados a la red de transporte.
- **Desacoplamiento Visual:** Arquitectura orientada a controlador que separa la logica espacial del arbol de renderizado de Flutter.

---

## Arquitectura del Sistema

La libreria sigue una arquitectura en capas con separacion estricta de responsabilidades:

```drawio
<mxfile>
  <diagram id="y62I_S9oRpRS3zDT24TX" name="Page-1">
    <mxGraphModel dx="2" dy="1" grid="0" gridSize="10" guides="1" tooltips="0" connect="0" arrows="0" fold="0" page="0" pageScale="1" pageWidth="850" pageHeight="1100" math="0" shadow="0">
      <root>
        <mxCell id="wW3I6VSSMsV_W1t6AP4m-0" />
        <mxCell id="wW3I6VSSMsV_W1t6AP4m-1" parent="wW3I6VSSMsV_W1t6AP4m-0" />
        <UserObject label="" mermaidData="{&#xa;  &quot;data&quot;: &quot;flowchart TD\n    subgraph ClientLayer[\&quot;1. Capa de Aplicacion Cliente\&quot;]\n        ConsumerApp[\&quot;Aplicacion Flutter Consumidora\&quot;]\n    end\n\n    subgraph PresentationLayer[\&quot;2. Capa de Presentacion (Widgets)\&quot;]\n        MapView[\&quot;MapView (flutter_map Canvas)\&quot;]\n        PoiDetailSheet[\&quot;PoiDetailSheet (Ficha Informativa)\&quot;]\n        FloorSelector[\&quot;FloorSelector (Selector de Pisos)\&quot;]\n        TurnByTurnBanner[\&quot;TurnByTurnBanner (Guia de Direccion)\&quot;]\n        UsacTheme[\&quot;UsacMapTheme (Tokens de Color y Estilos)\&quot;]\n    end\n\n    subgraph StateLayer[\&quot;3. Capa de Control y Estado\&quot;]\n        Controller[\&quot;UsacCampusMapController (ValueNotifier / ChangeNotifier)\&quot;]\n    end\n\n    subgraph EngineLayer[\&quot;4. Capa de Motores Offline (Logica de Negocio)\&quot;]\n        RouteEngine[\&quot;RouteEngine (Planificador de Rutas)\&quot;]\n        SearchEngine[\&quot;SearchEngine (Indice y Busqueda Difusa)\&quot;]\n        DataRepo[\&quot;CampusDataRepository (Carga y Cache de Datos)\&quot;]\n    end\n\n    subgraph CoreAlgorithmLayer[\&quot;5. Capa de Algoritmos Core (Matematicas y Topologia)\&quot;]\n        AStar[\&quot;AStarNavigator (Grafo y Heuristica A*)\&quot;]\n        PriorityQueue[\&quot;CustomPriorityQueue (Min-Heap Binario)\&quot;]\n        SnapToPath[\&quot;SnapToPath (Proyeccion Ortogonal a Segmentos)\&quot;]\n        DistanceCalc[\&quot;DistanceCalculator (Haversine y Geometria Esferica)\&quot;]\n    end\n\n    subgraph DomainModels[\&quot;6. Capa de Modelos de Dominio\&quot;]\n        BuildingModel[\&quot;CampusBuilding\&quot;]\n        PoiModel[\&quot;CampusPoi\&quot;]\n        NodeModel[\&quot;CampusNode\&quot;]\n        EdgeModel[\&quot;CampusEdge\&quot;]\n        RouteModel[\&quot;CampusRoute\&quot;]\n        IndoorModel[\&quot;IndoorFloor\&quot;]\n        ModeEnum[\&quot;NavigationMode\&quot;]\n    end\n\n    subgraph DataAssets[\&quot;7. Capa de Activos Locales (Zero Cost Offline Assets)\&quot;]\n        BoundaryGeo[\&quot;assets/geojson/usac_boundary.geojson\&quot;]\n        BuildingsGeo[\&quot;assets/geojson/usac_buildings.geojson\&quot;]\n        GraphJson[\&quot;assets/graph/campus_graph.json\&quot;]\n        PoisJson[\&quot;assets/pois/usac_pois_and_indoors.json\&quot;]\n    end\n\n    ConsumerApp --&gt; Controller\n    ConsumerApp --&gt; MapView\n    MapView --&gt; Controller\n    PoiDetailSheet --&gt; Controller\n    FloorSelector --&gt; Controller\n    TurnByTurnBanner --&gt; Controller\n\n    Controller --&gt; RouteEngine\n    Controller --&gt; SearchEngine\n    Controller --&gt; DataRepo\n\n    RouteEngine --&gt; AStar\n    RouteEngine --&gt; DistanceCalc\n    AStar --&gt; PriorityQueue\n    Controller --&gt; SnapToPath\n\n    DataRepo --&gt; BoundaryGeo\n    DataRepo --&gt; BuildingsGeo\n    DataRepo --&gt; GraphJson\n    DataRepo --&gt; PoisJson\n\n    DataRepo --&gt; BuildingModel\n    DataRepo --&gt; PoiModel\n    DataRepo --&gt; NodeModel\n    DataRepo --&gt; EdgeModel\n    RouteEngine --&gt; RouteModel\n    RouteEngine --&gt; ModeEnum&quot;,&#xa;  &quot;config&quot;: null&#xa;}" id="QrrXP81SY32-a7-iXn6G-0">
          <mxCell connectable="0" parent="wW3I6VSSMsV_W1t6AP4m-1" style="group;transparentBounds=1;editIcon=1;lockedGroup=0;groupPadding=10;" vertex="1">
            <mxGeometry as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="1. Capa de Aplicacion Cliente" mermaidId="n:ClientLayer" mermaidBaseStyle="html=1;whiteSpace=wrap;strokeWidth=1;verticalAlign=top;fillColor=light-dark(#ffffde,#1f2020);strokeColor=light-dark(#aaaa33,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="1. Capa de Aplicacion Cliente" id="wW3I6VSSMsV_W1t6AP4m-2">
          <mxCell parent="QrrXP81SY32-a7-iXn6G-0" style="html=1;whiteSpace=wrap;strokeWidth=1;verticalAlign=top;fillColor=light-dark(#ffffde,#1f2020);strokeColor=light-dark(#aaaa33,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="124" width="355" x="2889" y="10" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="Aplicacion Flutter Consumidora" mermaidId="n:ConsumerApp" mermaidBaseStyle="html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="Aplicacion Flutter Consumidora" id="wW3I6VSSMsV_W1t6AP4m-3">
          <mxCell parent="wW3I6VSSMsV_W1t6AP4m-2" style="html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="54" width="285" x="35" y="45" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="2. Capa de Presentacion (Widgets)" mermaidId="n:PresentationLayer" mermaidBaseStyle="html=1;whiteSpace=wrap;strokeWidth=1;verticalAlign=top;fillColor=light-dark(#ffffde,#1f2020);strokeColor=light-dark(#aaaa33,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="2. Capa de Presentacion (Widgets)" id="wW3I6VSSMsV_W1t6AP4m-4">
          <mxCell parent="QrrXP81SY32-a7-iXn6G-0" style="html=1;whiteSpace=wrap;strokeWidth=1;verticalAlign=top;fillColor=light-dark(#ffffde,#1f2020);strokeColor=light-dark(#aaaa33,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="124" width="1431" x="1713" y="164" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="MapView (flutter_map Canvas)" mermaidId="n:MapView" mermaidBaseStyle="html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="MapView (flutter_map Canvas)" id="wW3I6VSSMsV_W1t6AP4m-5">
          <mxCell parent="wW3I6VSSMsV_W1t6AP4m-4" style="html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="54" width="280" x="1116" y="45" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="PoiDetailSheet (Ficha Informativa)" mermaidId="n:PoiDetailSheet" mermaidBaseStyle="html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="PoiDetailSheet (Ficha Informativa)" id="wW3I6VSSMsV_W1t6AP4m-6">
          <mxCell parent="wW3I6VSSMsV_W1t6AP4m-4" style="html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="54" width="306" x="760" y="45" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="FloorSelector (Selector de Pisos)" mermaidId="n:FloorSelector" mermaidBaseStyle="html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="FloorSelector (Selector de Pisos)" id="wW3I6VSSMsV_W1t6AP4m-7">
          <mxCell parent="wW3I6VSSMsV_W1t6AP4m-4" style="html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="54" width="293" x="417" y="45" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="TurnByTurnBanner (Guia de Direccion)" mermaidId="n:TurnByTurnBanner" mermaidBaseStyle="html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="TurnByTurnBanner (Guia de Direccion)" id="wW3I6VSSMsV_W1t6AP4m-8">
          <mxCell parent="wW3I6VSSMsV_W1t6AP4m-4" style="html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="54" width="332" x="35" y="45" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="UsacMapTheme (Tokens de Color y Estilos)" mermaidId="n:UsacTheme" mermaidBaseStyle="html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="UsacMapTheme (Tokens de Color y Estilos)" id="wW3I6VSSMsV_W1t6AP4m-9">
          <mxCell parent="wW3I6VSSMsV_W1t6AP4m-4" style="html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="54" width="363" x="1028" y="45" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="3. Capa de Control y Estado" mermaidId="n:StateLayer" mermaidBaseStyle="html=1;whiteSpace=wrap;strokeWidth=1;verticalAlign=top;fillColor=light-dark(#ffffde,#1f2020);strokeColor=light-dark(#aaaa33,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="3. Capa de Control y Estado" id="wW3I6VSSMsV_W1t6AP4m-10">
          <mxCell parent="QrrXP81SY32-a7-iXn6G-0" style="html=1;whiteSpace=wrap;strokeWidth=1;verticalAlign=top;fillColor=light-dark(#ffffde,#1f2020);strokeColor=light-dark(#aaaa33,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="124" width="555" x="2261" y="318" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="UsacCampusMapController (ValueNotifier / ChangeNotifier)" mermaidId="n:Controller" mermaidBaseStyle="html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="UsacCampusMapController (ValueNotifier / ChangeNotifier)" id="wW3I6VSSMsV_W1t6AP4m-11">
          <mxCell parent="wW3I6VSSMsV_W1t6AP4m-10" style="html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="54" width="485" x="35" y="45" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="4. Capa de Motores Offline (Logica de Negocio)" mermaidId="n:EngineLayer" mermaidBaseStyle="html=1;whiteSpace=wrap;strokeWidth=1;verticalAlign=top;fillColor=light-dark(#ffffde,#1f2020);strokeColor=light-dark(#aaaa33,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="4. Capa de Motores Offline (Logica de Negocio)" id="wW3I6VSSMsV_W1t6AP4m-12">
          <mxCell parent="QrrXP81SY32-a7-iXn6G-0" style="html=1;whiteSpace=wrap;strokeWidth=1;verticalAlign=top;fillColor=light-dark(#ffffde,#1f2020);strokeColor=light-dark(#aaaa33,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="124" width="1721" x="1529" y="472" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="RouteEngine (Planificador de Rutas)" mermaidId="n:RouteEngine" mermaidBaseStyle="html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="RouteEngine (Planificador de Rutas)" id="wW3I6VSSMsV_W1t6AP4m-13">
          <mxCell parent="wW3I6VSSMsV_W1t6AP4m-12" style="html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="54" width="317" x="1369" y="45" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="SearchEngine (Indice y Busqueda Difusa)" mermaidId="n:SearchEngine" mermaidBaseStyle="html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="SearchEngine (Indice y Busqueda Difusa)" id="wW3I6VSSMsV_W1t6AP4m-14">
          <mxCell parent="wW3I6VSSMsV_W1t6AP4m-12" style="html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="54" width="349" x="819" y="45" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="CampusDataRepository (Carga y Cache de Datos)" mermaidId="n:DataRepo" mermaidBaseStyle="html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="CampusDataRepository (Carga y Cache de Datos)" id="wW3I6VSSMsV_W1t6AP4m-15">
          <mxCell parent="wW3I6VSSMsV_W1t6AP4m-12" style="html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="54" width="408" x="35" y="45" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="5. Capa de Algoritmos Core (Matematicas y Topologia)" mermaidId="n:CoreAlgorithmLayer" mermaidBaseStyle="html=1;whiteSpace=wrap;strokeWidth=1;verticalAlign=top;fillColor=light-dark(#ffffde,#1f2020);strokeColor=light-dark(#aaaa33,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="5. Capa de Algoritmos Core (Matematicas y Topologia)" id="wW3I6VSSMsV_W1t6AP4m-16">
          <mxCell parent="QrrXP81SY32-a7-iXn6G-0" style="html=1;whiteSpace=wrap;strokeWidth=1;verticalAlign=top;fillColor=light-dark(#ffffde,#1f2020);strokeColor=light-dark(#aaaa33,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="253" width="1352" x="3076" y="626" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="AStarNavigator (Grafo y Heuristica A*)" mermaidId="n:AStar" mermaidBaseStyle="html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="AStarNavigator (Grafo y Heuristica A*)" id="wW3I6VSSMsV_W1t6AP4m-17">
          <mxCell parent="wW3I6VSSMsV_W1t6AP4m-16" style="html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="54" width="332" x="976" y="45" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="CustomPriorityQueue (Min-Heap Binario)" mermaidId="n:PriorityQueue" mermaidBaseStyle="html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="CustomPriorityQueue (Min-Heap Binario)" id="wW3I6VSSMsV_W1t6AP4m-18">
          <mxCell parent="wW3I6VSSMsV_W1t6AP4m-16" style="html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="54" width="350" x="967" y="174" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="SnapToPath (Proyeccion Ortogonal a Segmentos)" mermaidId="n:SnapToPath" mermaidBaseStyle="html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="SnapToPath (Proyeccion Ortogonal a Segmentos)" id="wW3I6VSSMsV_W1t6AP4m-19">
          <mxCell parent="wW3I6VSSMsV_W1t6AP4m-16" style="html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="54" width="405" x="521" y="45" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="DistanceCalculator (Haversine y Geometria Esferica)" mermaidId="n:DistanceCalc" mermaidBaseStyle="html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="DistanceCalculator (Haversine y Geometria Esferica)" id="wW3I6VSSMsV_W1t6AP4m-20">
          <mxCell parent="wW3I6VSSMsV_W1t6AP4m-16" style="html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="54" width="436" x="35" y="45" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="" mermaidId="e:AStar-&gt;PriorityQueue#0" mermaidBaseStyle="curved=1;startArrow=none;endArrow=block;endSize=7;strokeColor=light-dark(#333333,#cccccc);exitX=0.5;exitY=1;entryX=0.5;entryY=0;" mermaidBaseValue="" id="wW3I6VSSMsV_W1t6AP4m-56">
          <mxCell edge="1" parent="wW3I6VSSMsV_W1t6AP4m-16" source="wW3I6VSSMsV_W1t6AP4m-17" style="curved=1;startArrow=none;endArrow=block;endSize=7;strokeColor=light-dark(#333333,#cccccc);exitX=0.5;exitY=1;entryX=0.5;entryY=0;" target="wW3I6VSSMsV_W1t6AP4m-18">
            <mxGeometry relative="1" as="geometry">
              <Array as="points" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <UserObject label="6. Capa de Modelos de Dominio" mermaidId="n:DomainModels" mermaidBaseStyle="html=1;whiteSpace=wrap;strokeWidth=1;verticalAlign=top;fillColor=light-dark(#ffffde,#1f2020);strokeColor=light-dark(#aaaa33,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="6. Capa de Modelos de Dominio" id="wW3I6VSSMsV_W1t6AP4m-21">
          <mxCell parent="QrrXP81SY32-a7-iXn6G-0" style="html=1;whiteSpace=wrap;strokeWidth=1;verticalAlign=top;fillColor=light-dark(#ffffde,#1f2020);strokeColor=light-dark(#aaaa33,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="124" width="1453" x="1603" y="626" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="CampusBuilding" mermaidId="n:BuildingModel" mermaidBaseStyle="html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="CampusBuilding" id="wW3I6VSSMsV_W1t6AP4m-22">
          <mxCell parent="wW3I6VSSMsV_W1t6AP4m-21" style="html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="54" width="173" x="1245" y="45" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="CampusPoi" mermaidId="n:PoiModel" mermaidBaseStyle="html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="CampusPoi" id="wW3I6VSSMsV_W1t6AP4m-23">
          <mxCell parent="wW3I6VSSMsV_W1t6AP4m-21" style="html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="54" width="137" x="1058" y="45" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="CampusNode" mermaidId="n:NodeModel" mermaidBaseStyle="html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="CampusNode" id="wW3I6VSSMsV_W1t6AP4m-24">
          <mxCell parent="wW3I6VSSMsV_W1t6AP4m-21" style="html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="54" width="152" x="856" y="45" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="CampusEdge" mermaidId="n:EdgeModel" mermaidBaseStyle="html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="CampusEdge" id="wW3I6VSSMsV_W1t6AP4m-25">
          <mxCell parent="wW3I6VSSMsV_W1t6AP4m-21" style="html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="54" width="150" x="656" y="45" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="CampusRoute" mermaidId="n:RouteModel" mermaidBaseStyle="html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="CampusRoute" id="wW3I6VSSMsV_W1t6AP4m-26">
          <mxCell parent="wW3I6VSSMsV_W1t6AP4m-21" style="html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="54" width="156" x="450" y="45" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="IndoorFloor" mermaidId="n:IndoorModel" mermaidBaseStyle="html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="IndoorFloor" id="wW3I6VSSMsV_W1t6AP4m-27">
          <mxCell parent="wW3I6VSSMsV_W1t6AP4m-21" style="html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="54" width="142" x="832" y="45" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="NavigationMode" mermaidId="n:ModeEnum" mermaidBaseStyle="html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="NavigationMode" id="wW3I6VSSMsV_W1t6AP4m-28">
          <mxCell parent="wW3I6VSSMsV_W1t6AP4m-21" style="html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="54" width="173" x="35" y="45" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="7. Capa de Activos Locales (Zero Cost Offline Assets)" mermaidId="n:DataAssets" mermaidBaseStyle="html=1;whiteSpace=wrap;strokeWidth=1;verticalAlign=top;fillColor=light-dark(#ffffde,#1f2020);strokeColor=light-dark(#aaaa33,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="7. Capa de Activos Locales (Zero Cost Offline Assets)" id="wW3I6VSSMsV_W1t6AP4m-29">
          <mxCell parent="QrrXP81SY32-a7-iXn6G-0" style="html=1;whiteSpace=wrap;strokeWidth=1;verticalAlign=top;fillColor=light-dark(#ffffde,#1f2020);strokeColor=light-dark(#aaaa33,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="124" width="1544" x="10" y="626" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="assets/geojson/usac_boundary.geojson" mermaidId="n:BoundaryGeo" mermaidBaseStyle="html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="assets/geojson/usac_boundary.geojson" id="wW3I6VSSMsV_W1t6AP4m-30">
          <mxCell parent="wW3I6VSSMsV_W1t6AP4m-29" style="html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="54" width="340" x="1169" y="45" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="assets/geojson/usac_buildings.geojson" mermaidId="n:BuildingsGeo" mermaidBaseStyle="html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="assets/geojson/usac_buildings.geojson" id="wW3I6VSSMsV_W1t6AP4m-31">
          <mxCell parent="wW3I6VSSMsV_W1t6AP4m-29" style="html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="54" width="339" x="780" y="45" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="assets/graph/campus_graph.json" mermaidId="n:GraphJson" mermaidBaseStyle="html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="assets/graph/campus_graph.json" id="wW3I6VSSMsV_W1t6AP4m-32">
          <mxCell parent="wW3I6VSSMsV_W1t6AP4m-29" style="html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="54" width="298" x="432" y="45" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="assets/pois/usac_pois_and_indoors.json" mermaidId="n:PoisJson" mermaidBaseStyle="html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="assets/pois/usac_pois_and_indoors.json" id="wW3I6VSSMsV_W1t6AP4m-33">
          <mxCell parent="wW3I6VSSMsV_W1t6AP4m-29" style="html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="54" width="347" x="35" y="45" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="" mermaidId="e:ConsumerApp-&gt;Controller#0" mermaidBaseStyle="curved=1;startArrow=none;endArrow=block;endSize=7;strokeColor=light-dark(#333333,#cccccc);exitX=0.68;exitY=1;entryX=1;entryY=0.13;" mermaidBaseValue="" id="wW3I6VSSMsV_W1t6AP4m-34">
          <mxCell edge="1" parent="QrrXP81SY32-a7-iXn6G-0" source="wW3I6VSSMsV_W1t6AP4m-3" style="curved=1;startArrow=none;endArrow=block;endSize=7;strokeColor=light-dark(#333333,#cccccc);exitX=0.68;exitY=1;entryX=1;entryY=0.13;" target="wW3I6VSSMsV_W1t6AP4m-11">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="3164" y="134" />
                <mxPoint x="3164" y="159" />
                <mxPoint x="3164" y="184" />
                <mxPoint x="3164" y="236" />
                <mxPoint x="3164" y="288" />
                <mxPoint x="3164" y="313" />
                <mxPoint x="3164" y="338" />
              </Array>
            </mxGeometry>
          </mxCell>
        </UserObject>
        <UserObject label="" mermaidId="e:ConsumerApp-&gt;MapView#0" mermaidBaseStyle="curved=1;startArrow=none;endArrow=block;endSize=7;strokeColor=light-dark(#333333,#cccccc);exitX=0.32;exitY=1;entryX=0.5;entryY=0;" mermaidBaseValue="" id="wW3I6VSSMsV_W1t6AP4m-35">
          <mxCell edge="1" parent="QrrXP81SY32-a7-iXn6G-0" source="wW3I6VSSMsV_W1t6AP4m-3" style="curved=1;startArrow=none;endArrow=block;endSize=7;strokeColor=light-dark(#333333,#cccccc);exitX=0.32;exitY=1;entryX=0.5;entryY=0;" target="wW3I6VSSMsV_W1t6AP4m-5">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="2969" y="134" />
                <mxPoint x="2969" y="159" />
                <mxPoint x="2969" y="184" />
              </Array>
            </mxGeometry>
          </mxCell>
        </UserObject>
        <UserObject label="" mermaidId="e:MapView-&gt;Controller#0" mermaidBaseStyle="curved=1;startArrow=none;endArrow=block;endSize=7;strokeColor=light-dark(#333333,#cccccc);exitX=0.5;exitY=1;entryX=0.96;entryY=0;" mermaidBaseValue="" id="wW3I6VSSMsV_W1t6AP4m-36">
          <mxCell edge="1" parent="QrrXP81SY32-a7-iXn6G-0" source="wW3I6VSSMsV_W1t6AP4m-5" style="curved=1;startArrow=none;endArrow=block;endSize=7;strokeColor=light-dark(#333333,#cccccc);exitX=0.5;exitY=1;entryX=0.96;entryY=0;" target="wW3I6VSSMsV_W1t6AP4m-11">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="2969" y="288" />
                <mxPoint x="2969" y="313" />
                <mxPoint x="2969" y="338" />
              </Array>
            </mxGeometry>
          </mxCell>
        </UserObject>
        <UserObject label="" mermaidId="e:PoiDetailSheet-&gt;Controller#0" mermaidBaseStyle="curved=1;startArrow=none;endArrow=block;endSize=7;strokeColor=light-dark(#333333,#cccccc);exitX=0.5;exitY=1;entryX=0.59;entryY=0;" mermaidBaseValue="" id="wW3I6VSSMsV_W1t6AP4m-37">
          <mxCell edge="1" parent="QrrXP81SY32-a7-iXn6G-0" source="wW3I6VSSMsV_W1t6AP4m-6" style="curved=1;startArrow=none;endArrow=block;endSize=7;strokeColor=light-dark(#333333,#cccccc);exitX=0.5;exitY=1;entryX=0.59;entryY=0;" target="wW3I6VSSMsV_W1t6AP4m-11">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="2626" y="288" />
                <mxPoint x="2626" y="313" />
                <mxPoint x="2626" y="338" />
              </Array>
            </mxGeometry>
          </mxCell>
        </UserObject>
        <UserObject label="" mermaidId="e:FloorSelector-&gt;Controller#0" mermaidBaseStyle="curved=1;startArrow=none;endArrow=block;endSize=7;strokeColor=light-dark(#333333,#cccccc);exitX=0.5;exitY=1;entryX=0.22;entryY=0;" mermaidBaseValue="" id="wW3I6VSSMsV_W1t6AP4m-38">
          <mxCell edge="1" parent="QrrXP81SY32-a7-iXn6G-0" source="wW3I6VSSMsV_W1t6AP4m-7" style="curved=1;startArrow=none;endArrow=block;endSize=7;strokeColor=light-dark(#333333,#cccccc);exitX=0.5;exitY=1;entryX=0.22;entryY=0;" target="wW3I6VSSMsV_W1t6AP4m-11">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="2276" y="288" />
                <mxPoint x="2276" y="313" />
                <mxPoint x="2276" y="338" />
              </Array>
            </mxGeometry>
          </mxCell>
        </UserObject>
        <UserObject label="" mermaidId="e:TurnByTurnBanner-&gt;Controller#0" mermaidBaseStyle="curved=1;startArrow=none;endArrow=block;endSize=7;strokeColor=light-dark(#333333,#cccccc);exitX=0.5;exitY=1;entryX=0;entryY=0.13;" mermaidBaseValue="" id="wW3I6VSSMsV_W1t6AP4m-39">
          <mxCell edge="1" parent="QrrXP81SY32-a7-iXn6G-0" source="wW3I6VSSMsV_W1t6AP4m-8" style="curved=1;startArrow=none;endArrow=block;endSize=7;strokeColor=light-dark(#333333,#cccccc);exitX=0.5;exitY=1;entryX=0;entryY=0.13;" target="wW3I6VSSMsV_W1t6AP4m-11">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="1914" y="288" />
                <mxPoint x="1914" y="313" />
                <mxPoint x="1914" y="338" />
              </Array>
            </mxGeometry>
          </mxCell>
        </UserObject>
        <UserObject label="" mermaidId="e:Controller-&gt;RouteEngine#0" mermaidBaseStyle="curved=1;startArrow=none;endArrow=block;endSize=7;strokeColor=light-dark(#333333,#cccccc);exitX=1;exitY=0.94;entryX=0.5;entryY=0;" mermaidBaseValue="" id="wW3I6VSSMsV_W1t6AP4m-40">
          <mxCell edge="1" parent="QrrXP81SY32-a7-iXn6G-0" source="wW3I6VSSMsV_W1t6AP4m-11" style="curved=1;startArrow=none;endArrow=block;endSize=7;strokeColor=light-dark(#333333,#cccccc);exitX=1;exitY=0.94;entryX=0.5;entryY=0;" target="wW3I6VSSMsV_W1t6AP4m-13">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="3057" y="442" />
                <mxPoint x="3057" y="467" />
                <mxPoint x="3057" y="492" />
              </Array>
            </mxGeometry>
          </mxCell>
        </UserObject>
        <UserObject label="" mermaidId="e:Controller-&gt;SearchEngine#0" mermaidBaseStyle="curved=1;startArrow=none;endArrow=block;endSize=7;strokeColor=light-dark(#333333,#cccccc);exitX=0.48;exitY=1;entryX=0.5;entryY=0;" mermaidBaseValue="" id="wW3I6VSSMsV_W1t6AP4m-41">
          <mxCell edge="1" parent="QrrXP81SY32-a7-iXn6G-0" source="wW3I6VSSMsV_W1t6AP4m-11" style="curved=1;startArrow=none;endArrow=block;endSize=7;strokeColor=light-dark(#333333,#cccccc);exitX=0.48;exitY=1;entryX=0.5;entryY=0;" target="wW3I6VSSMsV_W1t6AP4m-14">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="2523" y="442" />
                <mxPoint x="2523" y="467" />
                <mxPoint x="2523" y="492" />
              </Array>
            </mxGeometry>
          </mxCell>
        </UserObject>
        <UserObject label="" mermaidId="e:Controller-&gt;DataRepo#0" mermaidBaseStyle="curved=1;startArrow=none;endArrow=block;endSize=7;strokeColor=light-dark(#333333,#cccccc);exitX=0;exitY=0.8;entryX=0.5;entryY=0;" mermaidBaseValue="" id="wW3I6VSSMsV_W1t6AP4m-42">
          <mxCell edge="1" parent="QrrXP81SY32-a7-iXn6G-0" source="wW3I6VSSMsV_W1t6AP4m-11" style="curved=1;startArrow=none;endArrow=block;endSize=7;strokeColor=light-dark(#333333,#cccccc);exitX=0;exitY=0.8;entryX=0.5;entryY=0;" target="wW3I6VSSMsV_W1t6AP4m-15">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="1768" y="442" />
                <mxPoint x="1768" y="467" />
                <mxPoint x="1768" y="492" />
              </Array>
            </mxGeometry>
          </mxCell>
        </UserObject>
        <UserObject label="" mermaidId="e:RouteEngine-&gt;AStar#0" mermaidBaseStyle="curved=1;startArrow=none;endArrow=block;endSize=7;strokeColor=light-dark(#333333,#cccccc);exitX=1;exitY=0.69;entryX=0.5;entryY=0;" mermaidBaseValue="" id="wW3I6VSSMsV_W1t6AP4m-43">
          <mxCell edge="1" parent="QrrXP81SY32-a7-iXn6G-0" source="wW3I6VSSMsV_W1t6AP4m-13" style="curved=1;startArrow=none;endArrow=block;endSize=7;strokeColor=light-dark(#333333,#cccccc);exitX=1;exitY=0.69;entryX=0.5;entryY=0;" target="wW3I6VSSMsV_W1t6AP4m-17">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="3859" y="596" />
                <mxPoint x="4218" y="621" />
                <mxPoint x="4218" y="646" />
              </Array>
            </mxGeometry>
          </mxCell>
        </UserObject>
        <UserObject label="" mermaidId="e:RouteEngine-&gt;DistanceCalc#0" mermaidBaseStyle="curved=1;startArrow=none;endArrow=block;endSize=7;strokeColor=light-dark(#333333,#cccccc);exitX=0.95;exitY=1;entryX=0.5;entryY=0;" mermaidBaseValue="" id="wW3I6VSSMsV_W1t6AP4m-44">
          <mxCell edge="1" parent="QrrXP81SY32-a7-iXn6G-0" source="wW3I6VSSMsV_W1t6AP4m-13" style="curved=1;startArrow=none;endArrow=block;endSize=7;strokeColor=light-dark(#333333,#cccccc);exitX=0.95;exitY=1;entryX=0.5;entryY=0;" target="wW3I6VSSMsV_W1t6AP4m-20">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="3329" y="596" />
                <mxPoint x="3329" y="621" />
                <mxPoint x="3329" y="646" />
              </Array>
            </mxGeometry>
          </mxCell>
        </UserObject>
        <UserObject label="" mermaidId="e:Controller-&gt;SnapToPath#0" mermaidBaseStyle="curved=1;startArrow=none;endArrow=block;endSize=7;strokeColor=light-dark(#333333,#cccccc);exitX=1;exitY=0.65;entryX=0.5;entryY=0;" mermaidBaseValue="" id="wW3I6VSSMsV_W1t6AP4m-45">
          <mxCell edge="1" parent="QrrXP81SY32-a7-iXn6G-0" source="wW3I6VSSMsV_W1t6AP4m-11" style="curved=1;startArrow=none;endArrow=block;endSize=7;strokeColor=light-dark(#333333,#cccccc);exitX=1;exitY=0.65;entryX=0.5;entryY=0;" target="wW3I6VSSMsV_W1t6AP4m-19">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="4039" y="442" />
                <mxPoint x="4039" y="467" />
                <mxPoint x="4039" y="492" />
                <mxPoint x="4039" y="544" />
                <mxPoint x="4039" y="596" />
                <mxPoint x="3800" y="621" />
                <mxPoint x="3800" y="646" />
              </Array>
            </mxGeometry>
          </mxCell>
        </UserObject>
        <UserObject label="" mermaidId="e:DataRepo-&gt;BoundaryGeo#0" mermaidBaseStyle="curved=1;startArrow=none;endArrow=block;endSize=7;strokeColor=light-dark(#333333,#cccccc);exitX=0;exitY=0.96;entryX=0.5;entryY=0;" mermaidBaseValue="" id="wW3I6VSSMsV_W1t6AP4m-46">
          <mxCell edge="1" parent="QrrXP81SY32-a7-iXn6G-0" source="wW3I6VSSMsV_W1t6AP4m-15" style="curved=1;startArrow=none;endArrow=block;endSize=7;strokeColor=light-dark(#333333,#cccccc);exitX=0;exitY=0.96;entryX=0.5;entryY=0;" target="wW3I6VSSMsV_W1t6AP4m-30">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="1349" y="596" />
                <mxPoint x="1349" y="621" />
                <mxPoint x="1349" y="646" />
              </Array>
            </mxGeometry>
          </mxCell>
        </UserObject>
        <UserObject label="" mermaidId="e:DataRepo-&gt;BuildingsGeo#0" mermaidBaseStyle="curved=1;startArrow=none;endArrow=block;endSize=7;strokeColor=light-dark(#333333,#cccccc);exitX=0;exitY=0.74;entryX=0.5;entryY=0;" mermaidBaseValue="" id="wW3I6VSSMsV_W1t6AP4m-47">
          <mxCell edge="1" parent="QrrXP81SY32-a7-iXn6G-0" source="wW3I6VSSMsV_W1t6AP4m-15" style="curved=1;startArrow=none;endArrow=block;endSize=7;strokeColor=light-dark(#333333,#cccccc);exitX=0;exitY=0.74;entryX=0.5;entryY=0;" target="wW3I6VSSMsV_W1t6AP4m-31">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="960" y="596" />
                <mxPoint x="960" y="621" />
                <mxPoint x="960" y="646" />
              </Array>
            </mxGeometry>
          </mxCell>
        </UserObject>
        <UserObject label="" mermaidId="e:DataRepo-&gt;GraphJson#0" mermaidBaseStyle="curved=1;startArrow=none;endArrow=block;endSize=7;strokeColor=light-dark(#333333,#cccccc);exitX=0;exitY=0.67;entryX=0.5;entryY=0;" mermaidBaseValue="" id="wW3I6VSSMsV_W1t6AP4m-48">
          <mxCell edge="1" parent="QrrXP81SY32-a7-iXn6G-0" source="wW3I6VSSMsV_W1t6AP4m-15" style="curved=1;startArrow=none;endArrow=block;endSize=7;strokeColor=light-dark(#333333,#cccccc);exitX=0;exitY=0.67;entryX=0.5;entryY=0;" target="wW3I6VSSMsV_W1t6AP4m-32">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="591" y="596" />
                <mxPoint x="591" y="621" />
                <mxPoint x="591" y="646" />
              </Array>
            </mxGeometry>
          </mxCell>
        </UserObject>
        <UserObject label="" mermaidId="e:DataRepo-&gt;PoisJson#0" mermaidBaseStyle="curved=1;startArrow=none;endArrow=block;endSize=7;strokeColor=light-dark(#333333,#cccccc);exitX=0;exitY=0.63;entryX=0.5;entryY=0;" mermaidBaseValue="" id="wW3I6VSSMsV_W1t6AP4m-49">
          <mxCell edge="1" parent="QrrXP81SY32-a7-iXn6G-0" source="wW3I6VSSMsV_W1t6AP4m-15" style="curved=1;startArrow=none;endArrow=block;endSize=7;strokeColor=light-dark(#333333,#cccccc);exitX=0;exitY=0.63;entryX=0.5;entryY=0;" target="wW3I6VSSMsV_W1t6AP4m-33">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="219" y="596" />
                <mxPoint x="219" y="621" />
                <mxPoint x="219" y="646" />
              </Array>
            </mxGeometry>
          </mxCell>
        </UserObject>
        <UserObject label="" mermaidId="e:DataRepo-&gt;BuildingModel#0" mermaidBaseStyle="curved=1;startArrow=none;endArrow=block;endSize=7;strokeColor=light-dark(#333333,#cccccc);exitX=1;exitY=0.67;entryX=0.5;entryY=0;" mermaidBaseValue="" id="wW3I6VSSMsV_W1t6AP4m-50">
          <mxCell edge="1" parent="QrrXP81SY32-a7-iXn6G-0" source="wW3I6VSSMsV_W1t6AP4m-15" style="curved=1;startArrow=none;endArrow=block;endSize=7;strokeColor=light-dark(#333333,#cccccc);exitX=1;exitY=0.67;entryX=0.5;entryY=0;" target="wW3I6VSSMsV_W1t6AP4m-22">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="2935" y="596" />
                <mxPoint x="2935" y="621" />
                <mxPoint x="2935" y="646" />
              </Array>
            </mxGeometry>
          </mxCell>
        </UserObject>
        <UserObject label="" mermaidId="e:DataRepo-&gt;PoiModel#0" mermaidBaseStyle="curved=1;startArrow=none;endArrow=block;endSize=7;strokeColor=light-dark(#333333,#cccccc);exitX=1;exitY=0.7;entryX=0.5;entryY=0;" mermaidBaseValue="" id="wW3I6VSSMsV_W1t6AP4m-51">
          <mxCell edge="1" parent="QrrXP81SY32-a7-iXn6G-0" source="wW3I6VSSMsV_W1t6AP4m-15" style="curved=1;startArrow=none;endArrow=block;endSize=7;strokeColor=light-dark(#333333,#cccccc);exitX=1;exitY=0.7;entryX=0.5;entryY=0;" target="wW3I6VSSMsV_W1t6AP4m-23">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="2730" y="596" />
                <mxPoint x="2730" y="621" />
                <mxPoint x="2730" y="646" />
              </Array>
            </mxGeometry>
          </mxCell>
        </UserObject>
        <UserObject label="" mermaidId="e:DataRepo-&gt;NodeModel#0" mermaidBaseStyle="curved=1;startArrow=none;endArrow=block;endSize=7;strokeColor=light-dark(#333333,#cccccc);exitX=1;exitY=0.76;entryX=0.5;entryY=0;" mermaidBaseValue="" id="wW3I6VSSMsV_W1t6AP4m-52">
          <mxCell edge="1" parent="QrrXP81SY32-a7-iXn6G-0" source="wW3I6VSSMsV_W1t6AP4m-15" style="curved=1;startArrow=none;endArrow=block;endSize=7;strokeColor=light-dark(#333333,#cccccc);exitX=1;exitY=0.76;entryX=0.5;entryY=0;" target="wW3I6VSSMsV_W1t6AP4m-24">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="2535" y="596" />
                <mxPoint x="2535" y="621" />
                <mxPoint x="2535" y="646" />
              </Array>
            </mxGeometry>
          </mxCell>
        </UserObject>
        <UserObject label="" mermaidId="e:DataRepo-&gt;EdgeModel#0" mermaidBaseStyle="curved=1;startArrow=none;endArrow=block;endSize=7;strokeColor=light-dark(#333333,#cccccc);exitX=1;exitY=0.85;entryX=0.5;entryY=0;" mermaidBaseValue="" id="wW3I6VSSMsV_W1t6AP4m-53">
          <mxCell edge="1" parent="QrrXP81SY32-a7-iXn6G-0" source="wW3I6VSSMsV_W1t6AP4m-15" style="curved=1;startArrow=none;endArrow=block;endSize=7;strokeColor=light-dark(#333333,#cccccc);exitX=1;exitY=0.85;entryX=0.5;entryY=0;" target="wW3I6VSSMsV_W1t6AP4m-25">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="2334" y="596" />
                <mxPoint x="2334" y="621" />
                <mxPoint x="2334" y="646" />
              </Array>
            </mxGeometry>
          </mxCell>
        </UserObject>
        <UserObject label="" mermaidId="e:RouteEngine-&gt;RouteModel#0" mermaidBaseStyle="curved=1;startArrow=none;endArrow=block;endSize=7;strokeColor=light-dark(#333333,#cccccc);exitX=0;exitY=0.67;entryX=0.5;entryY=0;" mermaidBaseValue="" id="wW3I6VSSMsV_W1t6AP4m-54">
          <mxCell edge="1" parent="QrrXP81SY32-a7-iXn6G-0" source="wW3I6VSSMsV_W1t6AP4m-13" style="curved=1;startArrow=none;endArrow=block;endSize=7;strokeColor=light-dark(#333333,#cccccc);exitX=0;exitY=0.67;entryX=0.5;entryY=0;" target="wW3I6VSSMsV_W1t6AP4m-26">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="2131" y="596" />
                <mxPoint x="2131" y="621" />
                <mxPoint x="2131" y="646" />
              </Array>
            </mxGeometry>
          </mxCell>
        </UserObject>
        <UserObject label="" mermaidId="e:RouteEngine-&gt;ModeEnum#0" mermaidBaseStyle="curved=1;startArrow=none;endArrow=block;endSize=7;strokeColor=light-dark(#333333,#cccccc);exitX=0;exitY=0.61;entryX=0.5;entryY=0;" mermaidBaseValue="" id="wW3I6VSSMsV_W1t6AP4m-55">
          <mxCell edge="1" parent="QrrXP81SY32-a7-iXn6G-0" source="wW3I6VSSMsV_W1t6AP4m-13" style="curved=1;startArrow=none;endArrow=block;endSize=7;strokeColor=light-dark(#333333,#cccccc);exitX=0;exitY=0.61;entryX=0.5;entryY=0;" target="wW3I6VSSMsV_W1t6AP4m-28">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="1725" y="596" />
                <mxPoint x="1725" y="621" />
                <mxPoint x="1725" y="646" />
              </Array>
            </mxGeometry>
          </mxCell>
        </UserObject>
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>

```
---

## Diagramas de Flujo y Secuencia

### Flujo 1: Inicializacion y Arranque en Frio (Cold Boot)

Muestra la secuencia de deserializacion de archivos GeoJSON/JSON locales y construccion de los indices espaciales y de busqueda en memoria:

```drawio
<mxfile>
  <diagram id="-KMcGxrhTOv2ZcyzsNzx" name="Page-1">
    <mxGraphModel dx="2" dy="1" grid="0" gridSize="10" guides="1" tooltips="0" connect="0" arrows="0" fold="0" page="0" pageScale="1" pageWidth="850" pageHeight="1100" math="0" shadow="0">
      <root>
        <mxCell id="F2x6qsZyWYDmIotpopH5-0" />
        <mxCell id="F2x6qsZyWYDmIotpopH5-1" parent="F2x6qsZyWYDmIotpopH5-0" />
        <UserObject label="" mermaidData="{&#xa;  &quot;data&quot;: &quot;sequenceDiagram\n    autonumber\n    actor App as Aplicacion Flutter\n    participant Repo as CampusDataRepository\n    participant Bundle as rootBundle (Flutter Assets)\n    participant RouteEng as RouteEngine\n    participant SearchEng as SearchEngine\n    participant Ctrl as UsacCampusMapController\n    participant UI as MapView\n\n    App-&gt;&gt;Repo: loadData()\n    activate Repo\n    \n    Repo-&gt;&gt;Bundle: loadString(&#39;usac_boundary.geojson&#39;)\n    Bundle--&gt;&gt;Repo: String GeoJSON\n    Repo-&gt;&gt;Repo: Parsear perimetro exterior y crear LatLngBounds\n\n    Repo-&gt;&gt;Bundle: loadString(&#39;usac_buildings.geojson&#39;)\n    Bundle--&gt;&gt;Repo: String GeoJSON\n    Repo-&gt;&gt;Repo: Deserializar 248 entidades (edificios, parqueos, canchas)\n\n    Repo-&gt;&gt;Bundle: loadString(&#39;campus_graph.json&#39;)\n    Bundle--&gt;&gt;Repo: String JSON\n    Repo-&gt;&gt;Repo: Construir grafo (479 nodos, 1072 aristas indexadas)\n\n    Repo-&gt;&gt;Bundle: loadString(&#39;usac_pois_and_indoors.json&#39;)\n    Bundle--&gt;&gt;Repo: String JSON\n    Repo-&gt;&gt;Repo: Cargar catalogo de POIs, garitas y planos interiores\n    Repo--&gt;&gt;App: Inicializacion completada\n    deactivate Repo\n\n    App-&gt;&gt;RouteEng: new RouteEngine(repo.campusGraph)\n    App-&gt;&gt;SearchEng: new SearchEngine(repo.buildings, repo.pois)\n    App-&gt;&gt;Ctrl: new UsacCampusMapController(repo, routeEng, searchEng)\n    \n    App-&gt;&gt;UI: Montar MapView(controller: Ctrl)\n    UI-&gt;&gt;Ctrl: Suscribirse a cambios de estado\n    Ctrl--&gt;&gt;UI: Estado inicial (edificios cargados, camara centrada en USAC)&quot;,&#xa;  &quot;config&quot;: null&#xa;}" id="ELMwE-0kKht0vhzvMppJ-0">
          <mxCell connectable="0" parent="F2x6qsZyWYDmIotpopH5-1" style="group;transparentBounds=1;editIcon=1;lockedGroup=0;groupPadding=10;" vertex="1">
            <mxGeometry as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="Aplicacion Flutter" mermaidId="n:App" mermaidBaseStyle="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);participant=seqActorStick;verticalAlign=bottom;align=center;spacingBottom=4;size=90;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="Aplicacion Flutter" id="F2x6qsZyWYDmIotpopH5-2">
          <mxCell parent="ELMwE-0kKht0vhzvMppJ-0" style="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);participant=seqActorStick;verticalAlign=bottom;align=center;spacingBottom=4;size=90;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="1380" width="150" x="10" y="10" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="CampusDataRepository" mermaidId="n:Repo" mermaidBaseStyle="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="CampusDataRepository" id="F2x6qsZyWYDmIotpopH5-3">
          <mxCell parent="ELMwE-0kKht0vhzvMppJ-0" style="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="1355" width="150" x="243" y="10" as="geometry" />
          </mxCell>
        </UserObject>
        <mxCell id="F2x6qsZyWYDmIotpopH5-9" parent="F2x6qsZyWYDmIotpopH5-3" style="html=1;points=[];perimeter=orthogonalPerimeter;outlineConnect=0;targetShapes=umlLifeline;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};fillColor=light-dark(#f4f4f4,#2a2a2a);strokeColor=light-dark(#666666,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" value="" vertex="1">
          <mxGeometry height="897" width="10" x="70" y="109" as="geometry" />
        </mxCell>
        <UserObject label="rootBundle (Flutter Assets)" mermaidId="n:Bundle" mermaidBaseStyle="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="rootBundle (Flutter Assets)" id="F2x6qsZyWYDmIotpopH5-4">
          <mxCell parent="ELMwE-0kKht0vhzvMppJ-0" style="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="1355" width="150" x="581" y="10" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="RouteEngine" mermaidId="n:RouteEng" mermaidBaseStyle="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="RouteEngine" id="F2x6qsZyWYDmIotpopH5-5">
          <mxCell parent="ELMwE-0kKht0vhzvMppJ-0" style="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="1355" width="150" x="781" y="10" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="SearchEngine" mermaidId="n:SearchEng" mermaidBaseStyle="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="SearchEngine" id="F2x6qsZyWYDmIotpopH5-6">
          <mxCell parent="ELMwE-0kKht0vhzvMppJ-0" style="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="1355" width="150" x="981" y="10" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="UsacCampusMapController" mermaidId="n:Ctrl" mermaidBaseStyle="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="UsacCampusMapController" id="F2x6qsZyWYDmIotpopH5-7">
          <mxCell parent="ELMwE-0kKht0vhzvMppJ-0" style="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="1355" width="150" x="1181" y="10" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="MapView" mermaidId="n:UI" mermaidBaseStyle="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="MapView" id="F2x6qsZyWYDmIotpopH5-8">
          <mxCell parent="ELMwE-0kKht0vhzvMppJ-0" style="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="1355" width="150" x="1667" y="10" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="loadData()" mermaidId="e:App-&gt;Repo#0" mermaidBaseStyle="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="loadData()" id="F2x6qsZyWYDmIotpopH5-10">
          <mxCell edge="1" parent="ELMwE-0kKht0vhzvMppJ-0" source="F2x6qsZyWYDmIotpopH5-2" style="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="F2x6qsZyWYDmIotpopH5-9">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="199" y="119" />
              </Array>
              <mxPoint x="85" y="119" as="sourcePoint" />
              <mxPoint x="313" y="119" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="F2x6qsZyWYDmIotpopH5-11" parent="ELMwE-0kKht0vhzvMppJ-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="1" vertex="1">
          <mxGeometry height="20" width="20" x="75" y="109" as="geometry" />
        </mxCell>
        <UserObject label="loadString(&#39;usac_boundary.geojson&#39;)" mermaidId="e:Repo-&gt;Bundle#0" mermaidBaseStyle="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="loadString(&#39;usac_boundary.geojson&#39;)" id="F2x6qsZyWYDmIotpopH5-12">
          <mxCell edge="1" parent="ELMwE-0kKht0vhzvMppJ-0" source="F2x6qsZyWYDmIotpopH5-9" style="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="F2x6qsZyWYDmIotpopH5-4">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="490" y="163" />
              </Array>
              <mxPoint x="323" y="163" as="sourcePoint" />
              <mxPoint x="656" y="163" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="F2x6qsZyWYDmIotpopH5-13" parent="ELMwE-0kKht0vhzvMppJ-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="2" vertex="1">
          <mxGeometry height="20" width="20" x="308" y="153" as="geometry" />
        </mxCell>
        <UserObject label="String GeoJSON" mermaidId="e:Bundle-&gt;Repo#0" mermaidBaseStyle="dashed=1;fixDash=1;dashPattern=3 3;endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="String GeoJSON" id="F2x6qsZyWYDmIotpopH5-14">
          <mxCell edge="1" parent="ELMwE-0kKht0vhzvMppJ-0" source="F2x6qsZyWYDmIotpopH5-4" style="dashed=1;fixDash=1;dashPattern=3 3;endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="F2x6qsZyWYDmIotpopH5-9">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="490" y="207" />
              </Array>
              <mxPoint x="656" y="207" as="sourcePoint" />
              <mxPoint x="323" y="207" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="F2x6qsZyWYDmIotpopH5-15" parent="ELMwE-0kKht0vhzvMppJ-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="3" vertex="1">
          <mxGeometry height="20" width="20" x="646" y="197" as="geometry" />
        </mxCell>
        <UserObject label="" mermaidId="e:Repo-&gt;Repo#0" mermaidBaseStyle="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="" id="F2x6qsZyWYDmIotpopH5-16">
          <mxCell edge="1" parent="ELMwE-0kKht0vhzvMppJ-0" source="F2x6qsZyWYDmIotpopH5-9" style="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="F2x6qsZyWYDmIotpopH5-9">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="358" y="298" />
                <mxPoint x="362" y="310" />
                <mxPoint x="358" y="322" />
              </Array>
              <mxPoint x="323" y="298" as="sourcePoint" />
              <mxPoint x="323" y="322" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="F2x6qsZyWYDmIotpopH5-17" parent="ELMwE-0kKht0vhzvMppJ-0" style="text;html=1;strokeColor=none;fillColor=none;align=center;verticalAlign=middle;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;fontColor=light-dark(#333333,#cccccc);" value="Parsear perimetro exterior y crear LatLngBounds" vertex="1">
          <mxGeometry height="18" width="200" x="223" y="274" as="geometry" />
        </mxCell>
        <mxCell id="F2x6qsZyWYDmIotpopH5-18" parent="ELMwE-0kKht0vhzvMppJ-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="4" vertex="1">
          <mxGeometry height="20" width="20" x="308" y="288" as="geometry" />
        </mxCell>
        <UserObject label="loadString(&#39;usac_buildings.geojson&#39;)" mermaidId="e:Repo-&gt;Bundle#1" mermaidBaseStyle="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="loadString(&#39;usac_buildings.geojson&#39;)" id="F2x6qsZyWYDmIotpopH5-19">
          <mxCell edge="1" parent="ELMwE-0kKht0vhzvMppJ-0" source="F2x6qsZyWYDmIotpopH5-9" style="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="F2x6qsZyWYDmIotpopH5-4">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="490" y="372" />
              </Array>
              <mxPoint x="323" y="372" as="sourcePoint" />
              <mxPoint x="656" y="372" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="F2x6qsZyWYDmIotpopH5-20" parent="ELMwE-0kKht0vhzvMppJ-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="5" vertex="1">
          <mxGeometry height="20" width="20" x="308" y="362" as="geometry" />
        </mxCell>
        <UserObject label="String GeoJSON" mermaidId="e:Bundle-&gt;Repo#1" mermaidBaseStyle="dashed=1;fixDash=1;dashPattern=3 3;endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="String GeoJSON" id="F2x6qsZyWYDmIotpopH5-21">
          <mxCell edge="1" parent="ELMwE-0kKht0vhzvMppJ-0" source="F2x6qsZyWYDmIotpopH5-4" style="dashed=1;fixDash=1;dashPattern=3 3;endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="F2x6qsZyWYDmIotpopH5-9">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="490" y="416" />
              </Array>
              <mxPoint x="656" y="416" as="sourcePoint" />
              <mxPoint x="323" y="416" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="F2x6qsZyWYDmIotpopH5-22" parent="ELMwE-0kKht0vhzvMppJ-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="6" vertex="1">
          <mxGeometry height="20" width="20" x="646" y="406" as="geometry" />
        </mxCell>
        <UserObject label="" mermaidId="e:Repo-&gt;Repo#1" mermaidBaseStyle="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="" id="F2x6qsZyWYDmIotpopH5-23">
          <mxCell edge="1" parent="ELMwE-0kKht0vhzvMppJ-0" source="F2x6qsZyWYDmIotpopH5-9" style="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="F2x6qsZyWYDmIotpopH5-9">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="358" y="524" />
                <mxPoint x="362" y="536" />
                <mxPoint x="358" y="548" />
              </Array>
              <mxPoint x="323" y="524" as="sourcePoint" />
              <mxPoint x="323" y="548" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="F2x6qsZyWYDmIotpopH5-24" parent="ELMwE-0kKht0vhzvMppJ-0" style="text;html=1;strokeColor=none;fillColor=none;align=center;verticalAlign=middle;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;fontColor=light-dark(#333333,#cccccc);" value="Deserializar 248 entidades (edificios, parqueos, canchas)" vertex="1">
          <mxGeometry height="18" width="200" x="223" y="500" as="geometry" />
        </mxCell>
        <mxCell id="F2x6qsZyWYDmIotpopH5-25" parent="ELMwE-0kKht0vhzvMppJ-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="7" vertex="1">
          <mxGeometry height="20" width="20" x="308" y="514" as="geometry" />
        </mxCell>
        <UserObject label="loadString(&#39;campus_graph.json&#39;)" mermaidId="e:Repo-&gt;Bundle#2" mermaidBaseStyle="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="loadString(&#39;campus_graph.json&#39;)" id="F2x6qsZyWYDmIotpopH5-26">
          <mxCell edge="1" parent="ELMwE-0kKht0vhzvMppJ-0" source="F2x6qsZyWYDmIotpopH5-9" style="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="F2x6qsZyWYDmIotpopH5-4">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="490" y="598" />
              </Array>
              <mxPoint x="323" y="598" as="sourcePoint" />
              <mxPoint x="656" y="598" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="F2x6qsZyWYDmIotpopH5-27" parent="ELMwE-0kKht0vhzvMppJ-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="8" vertex="1">
          <mxGeometry height="20" width="20" x="308" y="588" as="geometry" />
        </mxCell>
        <UserObject label="String JSON" mermaidId="e:Bundle-&gt;Repo#2" mermaidBaseStyle="dashed=1;fixDash=1;dashPattern=3 3;endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="String JSON" id="F2x6qsZyWYDmIotpopH5-28">
          <mxCell edge="1" parent="ELMwE-0kKht0vhzvMppJ-0" source="F2x6qsZyWYDmIotpopH5-4" style="dashed=1;fixDash=1;dashPattern=3 3;endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="F2x6qsZyWYDmIotpopH5-9">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="490" y="642" />
              </Array>
              <mxPoint x="656" y="642" as="sourcePoint" />
              <mxPoint x="323" y="642" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="F2x6qsZyWYDmIotpopH5-29" parent="ELMwE-0kKht0vhzvMppJ-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="9" vertex="1">
          <mxGeometry height="20" width="20" x="646" y="632" as="geometry" />
        </mxCell>
        <UserObject label="" mermaidId="e:Repo-&gt;Repo#2" mermaidBaseStyle="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="" id="F2x6qsZyWYDmIotpopH5-30">
          <mxCell edge="1" parent="ELMwE-0kKht0vhzvMppJ-0" source="F2x6qsZyWYDmIotpopH5-9" style="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="F2x6qsZyWYDmIotpopH5-9">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="358" y="733" />
                <mxPoint x="362" y="745" />
                <mxPoint x="358" y="757" />
              </Array>
              <mxPoint x="323" y="733" as="sourcePoint" />
              <mxPoint x="323" y="757" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="F2x6qsZyWYDmIotpopH5-31" parent="ELMwE-0kKht0vhzvMppJ-0" style="text;html=1;strokeColor=none;fillColor=none;align=center;verticalAlign=middle;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;fontColor=light-dark(#333333,#cccccc);" value="Construir grafo (479 nodos, 1072 aristas indexadas)" vertex="1">
          <mxGeometry height="18" width="200" x="223" y="709" as="geometry" />
        </mxCell>
        <mxCell id="F2x6qsZyWYDmIotpopH5-32" parent="ELMwE-0kKht0vhzvMppJ-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="10" vertex="1">
          <mxGeometry height="20" width="20" x="308" y="723" as="geometry" />
        </mxCell>
        <UserObject label="loadString(&#39;usac_pois_and_indoors.json&#39;)" mermaidId="e:Repo-&gt;Bundle#3" mermaidBaseStyle="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="loadString(&#39;usac_pois_and_indoors.json&#39;)" id="F2x6qsZyWYDmIotpopH5-33">
          <mxCell edge="1" parent="ELMwE-0kKht0vhzvMppJ-0" source="F2x6qsZyWYDmIotpopH5-9" style="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="F2x6qsZyWYDmIotpopH5-4">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="490" y="807" />
              </Array>
              <mxPoint x="323" y="807" as="sourcePoint" />
              <mxPoint x="656" y="807" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="F2x6qsZyWYDmIotpopH5-34" parent="ELMwE-0kKht0vhzvMppJ-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="11" vertex="1">
          <mxGeometry height="20" width="20" x="308" y="797" as="geometry" />
        </mxCell>
        <UserObject label="String JSON" mermaidId="e:Bundle-&gt;Repo#3" mermaidBaseStyle="dashed=1;fixDash=1;dashPattern=3 3;endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="String JSON" id="F2x6qsZyWYDmIotpopH5-35">
          <mxCell edge="1" parent="ELMwE-0kKht0vhzvMppJ-0" source="F2x6qsZyWYDmIotpopH5-4" style="dashed=1;fixDash=1;dashPattern=3 3;endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="F2x6qsZyWYDmIotpopH5-9">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="490" y="851" />
              </Array>
              <mxPoint x="656" y="851" as="sourcePoint" />
              <mxPoint x="323" y="851" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="F2x6qsZyWYDmIotpopH5-36" parent="ELMwE-0kKht0vhzvMppJ-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="12" vertex="1">
          <mxGeometry height="20" width="20" x="646" y="841" as="geometry" />
        </mxCell>
        <UserObject label="" mermaidId="e:Repo-&gt;Repo#3" mermaidBaseStyle="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="" id="F2x6qsZyWYDmIotpopH5-37">
          <mxCell edge="1" parent="ELMwE-0kKht0vhzvMppJ-0" source="F2x6qsZyWYDmIotpopH5-9" style="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="F2x6qsZyWYDmIotpopH5-9">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="358" y="942" />
                <mxPoint x="362" y="954" />
                <mxPoint x="358" y="966" />
              </Array>
              <mxPoint x="323" y="942" as="sourcePoint" />
              <mxPoint x="323" y="966" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="F2x6qsZyWYDmIotpopH5-38" parent="ELMwE-0kKht0vhzvMppJ-0" style="text;html=1;strokeColor=none;fillColor=none;align=center;verticalAlign=middle;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;fontColor=light-dark(#333333,#cccccc);" value="Cargar catalogo de POIs, garitas y planos interiores" vertex="1">
          <mxGeometry height="18" width="200" x="223" y="918" as="geometry" />
        </mxCell>
        <mxCell id="F2x6qsZyWYDmIotpopH5-39" parent="ELMwE-0kKht0vhzvMppJ-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="13" vertex="1">
          <mxGeometry height="20" width="20" x="308" y="932" as="geometry" />
        </mxCell>
        <UserObject label="Inicializacion completada" mermaidId="e:Repo-&gt;App#0" mermaidBaseStyle="dashed=1;fixDash=1;dashPattern=3 3;endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="Inicializacion completada" id="F2x6qsZyWYDmIotpopH5-40">
          <mxCell edge="1" parent="ELMwE-0kKht0vhzvMppJ-0" source="F2x6qsZyWYDmIotpopH5-9" style="dashed=1;fixDash=1;dashPattern=3 3;endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="F2x6qsZyWYDmIotpopH5-2">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="199" y="1016" />
              </Array>
              <mxPoint x="313" y="1016" as="sourcePoint" />
              <mxPoint x="85" y="1016" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="F2x6qsZyWYDmIotpopH5-41" parent="ELMwE-0kKht0vhzvMppJ-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="14" vertex="1">
          <mxGeometry height="20" width="20" x="308" y="1006" as="geometry" />
        </mxCell>
        <UserObject label="new RouteEngine(repo.campusGraph)" mermaidId="e:App-&gt;RouteEng#0" mermaidBaseStyle="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="new RouteEngine(repo.campusGraph)" id="F2x6qsZyWYDmIotpopH5-42">
          <mxCell edge="1" parent="ELMwE-0kKht0vhzvMppJ-0" source="F2x6qsZyWYDmIotpopH5-2" style="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="F2x6qsZyWYDmIotpopH5-5">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="471" y="1060" />
              </Array>
              <mxPoint x="85" y="1060" as="sourcePoint" />
              <mxPoint x="856" y="1060" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="F2x6qsZyWYDmIotpopH5-43" parent="ELMwE-0kKht0vhzvMppJ-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="15" vertex="1">
          <mxGeometry height="20" width="20" x="75" y="1050" as="geometry" />
        </mxCell>
        <UserObject label="new SearchEngine(repo.buildings, repo.pois)" mermaidId="e:App-&gt;SearchEng#0" mermaidBaseStyle="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="new SearchEngine(repo.buildings, repo.pois)" id="F2x6qsZyWYDmIotpopH5-44">
          <mxCell edge="1" parent="ELMwE-0kKht0vhzvMppJ-0" source="F2x6qsZyWYDmIotpopH5-2" style="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="F2x6qsZyWYDmIotpopH5-6">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="571" y="1104" />
              </Array>
              <mxPoint x="85" y="1104" as="sourcePoint" />
              <mxPoint x="1056" y="1104" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="F2x6qsZyWYDmIotpopH5-45" parent="ELMwE-0kKht0vhzvMppJ-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="16" vertex="1">
          <mxGeometry height="20" width="20" x="75" y="1094" as="geometry" />
        </mxCell>
        <UserObject label="new UsacCampusMapController(repo, routeEng, searchEng)" mermaidId="e:App-&gt;Ctrl#0" mermaidBaseStyle="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="new UsacCampusMapController(repo, routeEng, searchEng)" id="F2x6qsZyWYDmIotpopH5-46">
          <mxCell edge="1" parent="ELMwE-0kKht0vhzvMppJ-0" source="F2x6qsZyWYDmIotpopH5-2" style="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="F2x6qsZyWYDmIotpopH5-7">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="671" y="1148" />
              </Array>
              <mxPoint x="85" y="1148" as="sourcePoint" />
              <mxPoint x="1256" y="1148" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="F2x6qsZyWYDmIotpopH5-47" parent="ELMwE-0kKht0vhzvMppJ-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="17" vertex="1">
          <mxGeometry height="20" width="20" x="75" y="1138" as="geometry" />
        </mxCell>
        <UserObject label="Montar MapView(controller: Ctrl)" mermaidId="e:App-&gt;UI#0" mermaidBaseStyle="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="Montar MapView(controller: Ctrl)" id="F2x6qsZyWYDmIotpopH5-48">
          <mxCell edge="1" parent="ELMwE-0kKht0vhzvMppJ-0" source="F2x6qsZyWYDmIotpopH5-2" style="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="F2x6qsZyWYDmIotpopH5-8">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="914" y="1192" />
              </Array>
              <mxPoint x="85" y="1192" as="sourcePoint" />
              <mxPoint x="1742" y="1192" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="F2x6qsZyWYDmIotpopH5-49" parent="ELMwE-0kKht0vhzvMppJ-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="18" vertex="1">
          <mxGeometry height="20" width="20" x="75" y="1182" as="geometry" />
        </mxCell>
        <UserObject label="Suscribirse a cambios de estado" mermaidId="e:UI-&gt;Ctrl#0" mermaidBaseStyle="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="Suscribirse a cambios de estado" id="F2x6qsZyWYDmIotpopH5-50">
          <mxCell edge="1" parent="ELMwE-0kKht0vhzvMppJ-0" source="F2x6qsZyWYDmIotpopH5-8" style="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="F2x6qsZyWYDmIotpopH5-7">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="1499" y="1236" />
              </Array>
              <mxPoint x="1742" y="1236" as="sourcePoint" />
              <mxPoint x="1256" y="1236" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="F2x6qsZyWYDmIotpopH5-51" parent="ELMwE-0kKht0vhzvMppJ-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="19" vertex="1">
          <mxGeometry height="20" width="20" x="1732" y="1226" as="geometry" />
        </mxCell>
        <UserObject label="Estado inicial (edificios cargados, camara centrada en USAC)" mermaidId="e:Ctrl-&gt;UI#0" mermaidBaseStyle="dashed=1;fixDash=1;dashPattern=3 3;endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="Estado inicial (edificios cargados, camara centrada en USAC)" id="F2x6qsZyWYDmIotpopH5-52">
          <mxCell edge="1" parent="ELMwE-0kKht0vhzvMppJ-0" source="F2x6qsZyWYDmIotpopH5-7" style="dashed=1;fixDash=1;dashPattern=3 3;endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="F2x6qsZyWYDmIotpopH5-8">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="1499" y="1280" />
              </Array>
              <mxPoint x="1256" y="1280" as="sourcePoint" />
              <mxPoint x="1742" y="1280" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="F2x6qsZyWYDmIotpopH5-53" parent="ELMwE-0kKht0vhzvMppJ-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="20" vertex="1">
          <mxGeometry height="20" width="20" x="1246" y="1270" as="geometry" />
        </mxCell>
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>

```
---

### Flujo 2: Busqueda Difusa e Indexacion

Describe como las consultas del usuario son procesadas contra el catalogo de edificios y puntos de interes:

```drawio
<mxfile>
  <diagram id="MDTFq79AS6bRtWUfZEmk" name="Page-1">
    <mxGraphModel dx="2" dy="1" grid="0" gridSize="10" guides="1" tooltips="0" connect="0" arrows="0" fold="0" page="0" pageScale="1" pageWidth="850" pageHeight="1100" math="0" shadow="0">
      <root>
        <mxCell id="kzJl7j1RpnY_vKqfsPez-0" />
        <mxCell id="kzJl7j1RpnY_vKqfsPez-1" parent="kzJl7j1RpnY_vKqfsPez-0" />
        <UserObject label="" mermaidData="{&#xa;  &quot;data&quot;: &quot;sequenceDiagram\n    autonumber\n    actor App as Aplicacion Flutter\n    participant Repo as CampusDataRepository\n    participant Bundle as rootBundle (Flutter Assets)\n    participant RouteEng as RouteEngine\n    participant SearchEng as SearchEngine\n    participant Ctrl as UsacCampusMapController\n    participant UI as MapView\n\n    App-&gt;&gt;Repo: loadData()\n    activate Repo\n    \n    Repo-&gt;&gt;Bundle: loadString(&#39;usac_boundary.geojson&#39;)\n    Bundle--&gt;&gt;Repo: String GeoJSON\n    Repo-&gt;&gt;Repo: Parsear perimetro exterior y crear LatLngBounds\n\n    Repo-&gt;&gt;Bundle: loadString(&#39;usac_buildings.geojson&#39;)\n    Bundle--&gt;&gt;Repo: String GeoJSON\n    Repo-&gt;&gt;Repo: Deserializar 248 entidades (edificios, parqueos, canchas)\n\n    Repo-&gt;&gt;Bundle: loadString(&#39;campus_graph.json&#39;)\n    Bundle--&gt;&gt;Repo: String JSON\n    Repo-&gt;&gt;Repo: Construir grafo (479 nodos, 1072 aristas indexadas)\n\n    Repo-&gt;&gt;Bundle: loadString(&#39;usac_pois_and_indoors.json&#39;)\n    Bundle--&gt;&gt;Repo: String JSON\n    Repo-&gt;&gt;Repo: Cargar catalogo de POIs, garitas y planos interiores\n    Repo--&gt;&gt;App: Inicializacion completada\n    deactivate Repo\n\n    App-&gt;&gt;RouteEng: new RouteEngine(repo.campusGraph)\n    App-&gt;&gt;SearchEng: new SearchEngine(repo.buildings, repo.pois)\n    App-&gt;&gt;Ctrl: new UsacCampusMapController(repo, routeEng, searchEng)\n    \n    App-&gt;&gt;UI: Montar MapView(controller: Ctrl)\n    UI-&gt;&gt;Ctrl: Suscribirse a cambios de estado\n    Ctrl--&gt;&gt;UI: Estado inicial (edificios cargados, camara centrada en USAC)&quot;,&#xa;  &quot;config&quot;: null&#xa;}" id="VvhX4G9XBWi0id6H-Sn4-0">
          <mxCell connectable="0" parent="kzJl7j1RpnY_vKqfsPez-1" style="group;transparentBounds=1;editIcon=1;lockedGroup=0;groupPadding=10;" vertex="1">
            <mxGeometry as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="Aplicacion Flutter" mermaidId="n:App" mermaidBaseStyle="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);participant=seqActorStick;verticalAlign=bottom;align=center;spacingBottom=4;size=90;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="Aplicacion Flutter" id="kzJl7j1RpnY_vKqfsPez-2">
          <mxCell parent="VvhX4G9XBWi0id6H-Sn4-0" style="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);participant=seqActorStick;verticalAlign=bottom;align=center;spacingBottom=4;size=90;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="1380" width="150" x="10" y="10" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="CampusDataRepository" mermaidId="n:Repo" mermaidBaseStyle="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="CampusDataRepository" id="kzJl7j1RpnY_vKqfsPez-3">
          <mxCell parent="VvhX4G9XBWi0id6H-Sn4-0" style="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="1355" width="150" x="243" y="10" as="geometry" />
          </mxCell>
        </UserObject>
        <mxCell id="kzJl7j1RpnY_vKqfsPez-9" parent="kzJl7j1RpnY_vKqfsPez-3" style="html=1;points=[];perimeter=orthogonalPerimeter;outlineConnect=0;targetShapes=umlLifeline;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};fillColor=light-dark(#f4f4f4,#2a2a2a);strokeColor=light-dark(#666666,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" value="" vertex="1">
          <mxGeometry height="897" width="10" x="70" y="109" as="geometry" />
        </mxCell>
        <UserObject label="rootBundle (Flutter Assets)" mermaidId="n:Bundle" mermaidBaseStyle="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="rootBundle (Flutter Assets)" id="kzJl7j1RpnY_vKqfsPez-4">
          <mxCell parent="VvhX4G9XBWi0id6H-Sn4-0" style="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="1355" width="150" x="581" y="10" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="RouteEngine" mermaidId="n:RouteEng" mermaidBaseStyle="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="RouteEngine" id="kzJl7j1RpnY_vKqfsPez-5">
          <mxCell parent="VvhX4G9XBWi0id6H-Sn4-0" style="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="1355" width="150" x="781" y="10" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="SearchEngine" mermaidId="n:SearchEng" mermaidBaseStyle="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="SearchEngine" id="kzJl7j1RpnY_vKqfsPez-6">
          <mxCell parent="VvhX4G9XBWi0id6H-Sn4-0" style="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="1355" width="150" x="981" y="10" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="UsacCampusMapController" mermaidId="n:Ctrl" mermaidBaseStyle="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="UsacCampusMapController" id="kzJl7j1RpnY_vKqfsPez-7">
          <mxCell parent="VvhX4G9XBWi0id6H-Sn4-0" style="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="1355" width="150" x="1181" y="10" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="MapView" mermaidId="n:UI" mermaidBaseStyle="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="MapView" id="kzJl7j1RpnY_vKqfsPez-8">
          <mxCell parent="VvhX4G9XBWi0id6H-Sn4-0" style="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="1355" width="150" x="1667" y="10" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="loadData()" mermaidId="e:App-&gt;Repo#0" mermaidBaseStyle="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="loadData()" id="kzJl7j1RpnY_vKqfsPez-10">
          <mxCell edge="1" parent="VvhX4G9XBWi0id6H-Sn4-0" source="kzJl7j1RpnY_vKqfsPez-2" style="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="kzJl7j1RpnY_vKqfsPez-9">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="199" y="119" />
              </Array>
              <mxPoint x="85" y="119" as="sourcePoint" />
              <mxPoint x="313" y="119" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="kzJl7j1RpnY_vKqfsPez-11" parent="VvhX4G9XBWi0id6H-Sn4-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="1" vertex="1">
          <mxGeometry height="20" width="20" x="75" y="109" as="geometry" />
        </mxCell>
        <UserObject label="loadString(&#39;usac_boundary.geojson&#39;)" mermaidId="e:Repo-&gt;Bundle#0" mermaidBaseStyle="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="loadString(&#39;usac_boundary.geojson&#39;)" id="kzJl7j1RpnY_vKqfsPez-12">
          <mxCell edge="1" parent="VvhX4G9XBWi0id6H-Sn4-0" source="kzJl7j1RpnY_vKqfsPez-9" style="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="kzJl7j1RpnY_vKqfsPez-4">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="490" y="163" />
              </Array>
              <mxPoint x="323" y="163" as="sourcePoint" />
              <mxPoint x="656" y="163" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="kzJl7j1RpnY_vKqfsPez-13" parent="VvhX4G9XBWi0id6H-Sn4-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="2" vertex="1">
          <mxGeometry height="20" width="20" x="308" y="153" as="geometry" />
        </mxCell>
        <UserObject label="String GeoJSON" mermaidId="e:Bundle-&gt;Repo#0" mermaidBaseStyle="dashed=1;fixDash=1;dashPattern=3 3;endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="String GeoJSON" id="kzJl7j1RpnY_vKqfsPez-14">
          <mxCell edge="1" parent="VvhX4G9XBWi0id6H-Sn4-0" source="kzJl7j1RpnY_vKqfsPez-4" style="dashed=1;fixDash=1;dashPattern=3 3;endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="kzJl7j1RpnY_vKqfsPez-9">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="490" y="207" />
              </Array>
              <mxPoint x="656" y="207" as="sourcePoint" />
              <mxPoint x="323" y="207" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="kzJl7j1RpnY_vKqfsPez-15" parent="VvhX4G9XBWi0id6H-Sn4-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="3" vertex="1">
          <mxGeometry height="20" width="20" x="646" y="197" as="geometry" />
        </mxCell>
        <UserObject label="" mermaidId="e:Repo-&gt;Repo#0" mermaidBaseStyle="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="" id="kzJl7j1RpnY_vKqfsPez-16">
          <mxCell edge="1" parent="VvhX4G9XBWi0id6H-Sn4-0" source="kzJl7j1RpnY_vKqfsPez-9" style="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="kzJl7j1RpnY_vKqfsPez-9">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="358" y="298" />
                <mxPoint x="362" y="310" />
                <mxPoint x="358" y="322" />
              </Array>
              <mxPoint x="323" y="298" as="sourcePoint" />
              <mxPoint x="323" y="322" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="kzJl7j1RpnY_vKqfsPez-17" parent="VvhX4G9XBWi0id6H-Sn4-0" style="text;html=1;strokeColor=none;fillColor=none;align=center;verticalAlign=middle;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;fontColor=light-dark(#333333,#cccccc);" value="Parsear perimetro exterior y crear LatLngBounds" vertex="1">
          <mxGeometry height="18" width="200" x="223" y="274" as="geometry" />
        </mxCell>
        <mxCell id="kzJl7j1RpnY_vKqfsPez-18" parent="VvhX4G9XBWi0id6H-Sn4-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="4" vertex="1">
          <mxGeometry height="20" width="20" x="308" y="288" as="geometry" />
        </mxCell>
        <UserObject label="loadString(&#39;usac_buildings.geojson&#39;)" mermaidId="e:Repo-&gt;Bundle#1" mermaidBaseStyle="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="loadString(&#39;usac_buildings.geojson&#39;)" id="kzJl7j1RpnY_vKqfsPez-19">
          <mxCell edge="1" parent="VvhX4G9XBWi0id6H-Sn4-0" source="kzJl7j1RpnY_vKqfsPez-9" style="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="kzJl7j1RpnY_vKqfsPez-4">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="490" y="372" />
              </Array>
              <mxPoint x="323" y="372" as="sourcePoint" />
              <mxPoint x="656" y="372" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="kzJl7j1RpnY_vKqfsPez-20" parent="VvhX4G9XBWi0id6H-Sn4-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="5" vertex="1">
          <mxGeometry height="20" width="20" x="308" y="362" as="geometry" />
        </mxCell>
        <UserObject label="String GeoJSON" mermaidId="e:Bundle-&gt;Repo#1" mermaidBaseStyle="dashed=1;fixDash=1;dashPattern=3 3;endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="String GeoJSON" id="kzJl7j1RpnY_vKqfsPez-21">
          <mxCell edge="1" parent="VvhX4G9XBWi0id6H-Sn4-0" source="kzJl7j1RpnY_vKqfsPez-4" style="dashed=1;fixDash=1;dashPattern=3 3;endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="kzJl7j1RpnY_vKqfsPez-9">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="490" y="416" />
              </Array>
              <mxPoint x="656" y="416" as="sourcePoint" />
              <mxPoint x="323" y="416" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="kzJl7j1RpnY_vKqfsPez-22" parent="VvhX4G9XBWi0id6H-Sn4-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="6" vertex="1">
          <mxGeometry height="20" width="20" x="646" y="406" as="geometry" />
        </mxCell>
        <UserObject label="" mermaidId="e:Repo-&gt;Repo#1" mermaidBaseStyle="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="" id="kzJl7j1RpnY_vKqfsPez-23">
          <mxCell edge="1" parent="VvhX4G9XBWi0id6H-Sn4-0" source="kzJl7j1RpnY_vKqfsPez-9" style="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="kzJl7j1RpnY_vKqfsPez-9">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="358" y="524" />
                <mxPoint x="362" y="536" />
                <mxPoint x="358" y="548" />
              </Array>
              <mxPoint x="323" y="524" as="sourcePoint" />
              <mxPoint x="323" y="548" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="kzJl7j1RpnY_vKqfsPez-24" parent="VvhX4G9XBWi0id6H-Sn4-0" style="text;html=1;strokeColor=none;fillColor=none;align=center;verticalAlign=middle;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;fontColor=light-dark(#333333,#cccccc);" value="Deserializar 248 entidades (edificios, parqueos, canchas)" vertex="1">
          <mxGeometry height="18" width="200" x="223" y="500" as="geometry" />
        </mxCell>
        <mxCell id="kzJl7j1RpnY_vKqfsPez-25" parent="VvhX4G9XBWi0id6H-Sn4-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="7" vertex="1">
          <mxGeometry height="20" width="20" x="308" y="514" as="geometry" />
        </mxCell>
        <UserObject label="loadString(&#39;campus_graph.json&#39;)" mermaidId="e:Repo-&gt;Bundle#2" mermaidBaseStyle="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="loadString(&#39;campus_graph.json&#39;)" id="kzJl7j1RpnY_vKqfsPez-26">
          <mxCell edge="1" parent="VvhX4G9XBWi0id6H-Sn4-0" source="kzJl7j1RpnY_vKqfsPez-9" style="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="kzJl7j1RpnY_vKqfsPez-4">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="490" y="598" />
              </Array>
              <mxPoint x="323" y="598" as="sourcePoint" />
              <mxPoint x="656" y="598" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="kzJl7j1RpnY_vKqfsPez-27" parent="VvhX4G9XBWi0id6H-Sn4-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="8" vertex="1">
          <mxGeometry height="20" width="20" x="308" y="588" as="geometry" />
        </mxCell>
        <UserObject label="String JSON" mermaidId="e:Bundle-&gt;Repo#2" mermaidBaseStyle="dashed=1;fixDash=1;dashPattern=3 3;endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="String JSON" id="kzJl7j1RpnY_vKqfsPez-28">
          <mxCell edge="1" parent="VvhX4G9XBWi0id6H-Sn4-0" source="kzJl7j1RpnY_vKqfsPez-4" style="dashed=1;fixDash=1;dashPattern=3 3;endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="kzJl7j1RpnY_vKqfsPez-9">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="490" y="642" />
              </Array>
              <mxPoint x="656" y="642" as="sourcePoint" />
              <mxPoint x="323" y="642" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="kzJl7j1RpnY_vKqfsPez-29" parent="VvhX4G9XBWi0id6H-Sn4-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="9" vertex="1">
          <mxGeometry height="20" width="20" x="646" y="632" as="geometry" />
        </mxCell>
        <UserObject label="" mermaidId="e:Repo-&gt;Repo#2" mermaidBaseStyle="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="" id="kzJl7j1RpnY_vKqfsPez-30">
          <mxCell edge="1" parent="VvhX4G9XBWi0id6H-Sn4-0" source="kzJl7j1RpnY_vKqfsPez-9" style="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="kzJl7j1RpnY_vKqfsPez-9">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="358" y="733" />
                <mxPoint x="362" y="745" />
                <mxPoint x="358" y="757" />
              </Array>
              <mxPoint x="323" y="733" as="sourcePoint" />
              <mxPoint x="323" y="757" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="kzJl7j1RpnY_vKqfsPez-31" parent="VvhX4G9XBWi0id6H-Sn4-0" style="text;html=1;strokeColor=none;fillColor=none;align=center;verticalAlign=middle;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;fontColor=light-dark(#333333,#cccccc);" value="Construir grafo (479 nodos, 1072 aristas indexadas)" vertex="1">
          <mxGeometry height="18" width="200" x="223" y="709" as="geometry" />
        </mxCell>
        <mxCell id="kzJl7j1RpnY_vKqfsPez-32" parent="VvhX4G9XBWi0id6H-Sn4-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="10" vertex="1">
          <mxGeometry height="20" width="20" x="308" y="723" as="geometry" />
        </mxCell>
        <UserObject label="loadString(&#39;usac_pois_and_indoors.json&#39;)" mermaidId="e:Repo-&gt;Bundle#3" mermaidBaseStyle="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="loadString(&#39;usac_pois_and_indoors.json&#39;)" id="kzJl7j1RpnY_vKqfsPez-33">
          <mxCell edge="1" parent="VvhX4G9XBWi0id6H-Sn4-0" source="kzJl7j1RpnY_vKqfsPez-9" style="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="kzJl7j1RpnY_vKqfsPez-4">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="490" y="807" />
              </Array>
              <mxPoint x="323" y="807" as="sourcePoint" />
              <mxPoint x="656" y="807" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="kzJl7j1RpnY_vKqfsPez-34" parent="VvhX4G9XBWi0id6H-Sn4-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="11" vertex="1">
          <mxGeometry height="20" width="20" x="308" y="797" as="geometry" />
        </mxCell>
        <UserObject label="String JSON" mermaidId="e:Bundle-&gt;Repo#3" mermaidBaseStyle="dashed=1;fixDash=1;dashPattern=3 3;endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="String JSON" id="kzJl7j1RpnY_vKqfsPez-35">
          <mxCell edge="1" parent="VvhX4G9XBWi0id6H-Sn4-0" source="kzJl7j1RpnY_vKqfsPez-4" style="dashed=1;fixDash=1;dashPattern=3 3;endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="kzJl7j1RpnY_vKqfsPez-9">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="490" y="851" />
              </Array>
              <mxPoint x="656" y="851" as="sourcePoint" />
              <mxPoint x="323" y="851" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="kzJl7j1RpnY_vKqfsPez-36" parent="VvhX4G9XBWi0id6H-Sn4-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="12" vertex="1">
          <mxGeometry height="20" width="20" x="646" y="841" as="geometry" />
        </mxCell>
        <UserObject label="" mermaidId="e:Repo-&gt;Repo#3" mermaidBaseStyle="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="" id="kzJl7j1RpnY_vKqfsPez-37">
          <mxCell edge="1" parent="VvhX4G9XBWi0id6H-Sn4-0" source="kzJl7j1RpnY_vKqfsPez-9" style="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="kzJl7j1RpnY_vKqfsPez-9">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="358" y="942" />
                <mxPoint x="362" y="954" />
                <mxPoint x="358" y="966" />
              </Array>
              <mxPoint x="323" y="942" as="sourcePoint" />
              <mxPoint x="323" y="966" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="kzJl7j1RpnY_vKqfsPez-38" parent="VvhX4G9XBWi0id6H-Sn4-0" style="text;html=1;strokeColor=none;fillColor=none;align=center;verticalAlign=middle;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;fontColor=light-dark(#333333,#cccccc);" value="Cargar catalogo de POIs, garitas y planos interiores" vertex="1">
          <mxGeometry height="18" width="200" x="223" y="918" as="geometry" />
        </mxCell>
        <mxCell id="kzJl7j1RpnY_vKqfsPez-39" parent="VvhX4G9XBWi0id6H-Sn4-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="13" vertex="1">
          <mxGeometry height="20" width="20" x="308" y="932" as="geometry" />
        </mxCell>
        <UserObject label="Inicializacion completada" mermaidId="e:Repo-&gt;App#0" mermaidBaseStyle="dashed=1;fixDash=1;dashPattern=3 3;endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="Inicializacion completada" id="kzJl7j1RpnY_vKqfsPez-40">
          <mxCell edge="1" parent="VvhX4G9XBWi0id6H-Sn4-0" source="kzJl7j1RpnY_vKqfsPez-9" style="dashed=1;fixDash=1;dashPattern=3 3;endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="kzJl7j1RpnY_vKqfsPez-2">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="199" y="1016" />
              </Array>
              <mxPoint x="313" y="1016" as="sourcePoint" />
              <mxPoint x="85" y="1016" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="kzJl7j1RpnY_vKqfsPez-41" parent="VvhX4G9XBWi0id6H-Sn4-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="14" vertex="1">
          <mxGeometry height="20" width="20" x="308" y="1006" as="geometry" />
        </mxCell>
        <UserObject label="new RouteEngine(repo.campusGraph)" mermaidId="e:App-&gt;RouteEng#0" mermaidBaseStyle="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="new RouteEngine(repo.campusGraph)" id="kzJl7j1RpnY_vKqfsPez-42">
          <mxCell edge="1" parent="VvhX4G9XBWi0id6H-Sn4-0" source="kzJl7j1RpnY_vKqfsPez-2" style="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="kzJl7j1RpnY_vKqfsPez-5">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="471" y="1060" />
              </Array>
              <mxPoint x="85" y="1060" as="sourcePoint" />
              <mxPoint x="856" y="1060" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="kzJl7j1RpnY_vKqfsPez-43" parent="VvhX4G9XBWi0id6H-Sn4-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="15" vertex="1">
          <mxGeometry height="20" width="20" x="75" y="1050" as="geometry" />
        </mxCell>
        <UserObject label="new SearchEngine(repo.buildings, repo.pois)" mermaidId="e:App-&gt;SearchEng#0" mermaidBaseStyle="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="new SearchEngine(repo.buildings, repo.pois)" id="kzJl7j1RpnY_vKqfsPez-44">
          <mxCell edge="1" parent="VvhX4G9XBWi0id6H-Sn4-0" source="kzJl7j1RpnY_vKqfsPez-2" style="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="kzJl7j1RpnY_vKqfsPez-6">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="571" y="1104" />
              </Array>
              <mxPoint x="85" y="1104" as="sourcePoint" />
              <mxPoint x="1056" y="1104" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="kzJl7j1RpnY_vKqfsPez-45" parent="VvhX4G9XBWi0id6H-Sn4-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="16" vertex="1">
          <mxGeometry height="20" width="20" x="75" y="1094" as="geometry" />
        </mxCell>
        <UserObject label="new UsacCampusMapController(repo, routeEng, searchEng)" mermaidId="e:App-&gt;Ctrl#0" mermaidBaseStyle="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="new UsacCampusMapController(repo, routeEng, searchEng)" id="kzJl7j1RpnY_vKqfsPez-46">
          <mxCell edge="1" parent="VvhX4G9XBWi0id6H-Sn4-0" source="kzJl7j1RpnY_vKqfsPez-2" style="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="kzJl7j1RpnY_vKqfsPez-7">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="671" y="1148" />
              </Array>
              <mxPoint x="85" y="1148" as="sourcePoint" />
              <mxPoint x="1256" y="1148" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="kzJl7j1RpnY_vKqfsPez-47" parent="VvhX4G9XBWi0id6H-Sn4-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="17" vertex="1">
          <mxGeometry height="20" width="20" x="75" y="1138" as="geometry" />
        </mxCell>
        <UserObject label="Montar MapView(controller: Ctrl)" mermaidId="e:App-&gt;UI#0" mermaidBaseStyle="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="Montar MapView(controller: Ctrl)" id="kzJl7j1RpnY_vKqfsPez-48">
          <mxCell edge="1" parent="VvhX4G9XBWi0id6H-Sn4-0" source="kzJl7j1RpnY_vKqfsPez-2" style="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="kzJl7j1RpnY_vKqfsPez-8">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="914" y="1192" />
              </Array>
              <mxPoint x="85" y="1192" as="sourcePoint" />
              <mxPoint x="1742" y="1192" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="kzJl7j1RpnY_vKqfsPez-49" parent="VvhX4G9XBWi0id6H-Sn4-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="18" vertex="1">
          <mxGeometry height="20" width="20" x="75" y="1182" as="geometry" />
        </mxCell>
        <UserObject label="Suscribirse a cambios de estado" mermaidId="e:UI-&gt;Ctrl#0" mermaidBaseStyle="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="Suscribirse a cambios de estado" id="kzJl7j1RpnY_vKqfsPez-50">
          <mxCell edge="1" parent="VvhX4G9XBWi0id6H-Sn4-0" source="kzJl7j1RpnY_vKqfsPez-8" style="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="kzJl7j1RpnY_vKqfsPez-7">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="1499" y="1236" />
              </Array>
              <mxPoint x="1742" y="1236" as="sourcePoint" />
              <mxPoint x="1256" y="1236" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="kzJl7j1RpnY_vKqfsPez-51" parent="VvhX4G9XBWi0id6H-Sn4-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="19" vertex="1">
          <mxGeometry height="20" width="20" x="1732" y="1226" as="geometry" />
        </mxCell>
        <UserObject label="Estado inicial (edificios cargados, camara centrada en USAC)" mermaidId="e:Ctrl-&gt;UI#0" mermaidBaseStyle="dashed=1;fixDash=1;dashPattern=3 3;endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="Estado inicial (edificios cargados, camara centrada en USAC)" id="kzJl7j1RpnY_vKqfsPez-52">
          <mxCell edge="1" parent="VvhX4G9XBWi0id6H-Sn4-0" source="kzJl7j1RpnY_vKqfsPez-7" style="dashed=1;fixDash=1;dashPattern=3 3;endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="kzJl7j1RpnY_vKqfsPez-8">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="1499" y="1280" />
              </Array>
              <mxPoint x="1256" y="1280" as="sourcePoint" />
              <mxPoint x="1742" y="1280" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="kzJl7j1RpnY_vKqfsPez-53" parent="VvhX4G9XBWi0id6H-Sn4-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="20" vertex="1">
          <mxGeometry height="20" width="20" x="1246" y="1270" as="geometry" />
        </mxCell>
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>

```
---

### Flujo 3: Planificacion de Rutas Multi-modal (A*)

Detalla el calculo de ruta minima utilizando el algoritmo A* con discriminacion por medio de transporte:

```drawio
<mxfile>
  <diagram id="1vvMir8C8cPQijjOS_jB" name="Page-1">
    <mxGraphModel dx="2" dy="1" grid="0" gridSize="10" guides="1" tooltips="0" connect="0" arrows="0" fold="0" page="0" pageScale="1" pageWidth="850" pageHeight="1100" math="0" shadow="0">
      <root>
        <mxCell id="DAo4bJDWTWjROyO8AEtg-0" />
        <mxCell id="DAo4bJDWTWjROyO8AEtg-1" parent="DAo4bJDWTWjROyO8AEtg-0" />
        <UserObject label="" mermaidData="{&#xa;  &quot;data&quot;: &quot;sequenceDiagram\n    autonumber\n    actor Usuario\n    participant UI as Interfaz de Usuario\n    participant Ctrl as UsacCampusMapController\n    participant RouteEng as RouteEngine\n    participant Snap as SnapToPath\n    participant AStar as AStarNavigator\n    participant MapUI as MapView\n\n    Usuario-&gt;&gt;UI: Solicita ruta: Origen (Garita Periferico) -&gt; Destino (T-3)\n    UI-&gt;&gt;Ctrl: calculateRoute(origen, destino, NavigationMode.pedestrian)\n    activate Ctrl\n\n    Ctrl-&gt;&gt;RouteEng: planRoute(origen, destino, mode: pedestrian)\n    activate RouteEng\n\n    RouteEng-&gt;&gt;Snap: findNearestNode(origen, graph)\n    Snap--&gt;&gt;RouteEng: Nodo Inicial (nodo_garita_periferico)\n\n    RouteEng-&gt;&gt;Snap: findNearestNode(destino, graph)\n    Snap--&gt;&gt;RouteEng: Nodo Final (nodo_t3_acceso)\n\n    RouteEng-&gt;&gt;AStar: findPath(startNode, endNode, mode, graph)\n    activate AStar\n\n    AStar-&gt;&gt;AStar: Inicializar cola de prioridad con startNode (costo = 0)\n    loop Mientras la cola no este vacia\n        AStar-&gt;&gt;AStar: Extraer nodo actual con menor fScore (gScore + heuristica)\n        alt Nodo actual es endNode\n            AStar-&gt;&gt;AStar: Reconstruir ruta enlazando predecesores\n        else Explorar vecinos\n            AStar-&gt;&gt;AStar: Filtrar aristas compatibles con NavigationMode\n            AStar-&gt;&gt;AStar: Evaluar si nuevo gScore es menor al registrado\n            AStar-&gt;&gt;AStar: Actualizar mejor costo e insertar vecino en cola\n        end\n    end\n    AStar--&gt;&gt;RouteEng: List&lt;CampusNode&gt; (secuencia optima)\n    deactivate AStar\n\n    RouteEng-&gt;&gt;RouteEng: Generar polilinea completa (List&lt;LatLng&gt;)\n    RouteEng-&gt;&gt;RouteEng: Calcular distancia acumulada y tiempo estimado\n    RouteEng-&gt;&gt;RouteEng: Generar instrucciones paso a paso\n    RouteEng--&gt;&gt;Ctrl: CampusRoute construida\n    deactivate RouteEng\n\n    Ctrl-&gt;&gt;Ctrl: Notificar nuevo estado: activeRoute = ruta\n    Ctrl-&gt;&gt;MapUI: Dibujar PolylineLayer sobre el mapa\n    Ctrl-&gt;&gt;UI: Desplegar TurnByTurnBanner con primera instruccion\n    deactivate Ctrl&quot;,&#xa;  &quot;config&quot;: null&#xa;}" id="tKDNcO07BNQh3qffwDL6-0">
          <mxCell connectable="0" parent="DAo4bJDWTWjROyO8AEtg-1" style="group;transparentBounds=1;editIcon=1;lockedGroup=0;groupPadding=10;" vertex="1">
            <mxGeometry as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="Usuario" mermaidId="n:Usuario" mermaidBaseStyle="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);participant=seqActorStick;verticalAlign=bottom;align=center;spacingBottom=4;size=90;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="Usuario" id="DAo4bJDWTWjROyO8AEtg-2">
          <mxCell parent="tKDNcO07BNQh3qffwDL6-0" style="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);participant=seqActorStick;verticalAlign=bottom;align=center;spacingBottom=4;size=90;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="2098" width="150" x="10" y="10" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="Interfaz de Usuario" mermaidId="n:UI" mermaidBaseStyle="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="Interfaz de Usuario" id="DAo4bJDWTWjROyO8AEtg-3">
          <mxCell parent="tKDNcO07BNQh3qffwDL6-0" style="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="2073" width="150" x="457" y="10" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="UsacCampusMapController" mermaidId="n:Ctrl" mermaidBaseStyle="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="UsacCampusMapController" id="DAo4bJDWTWjROyO8AEtg-4">
          <mxCell parent="tKDNcO07BNQh3qffwDL6-0" style="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="2073" width="150" x="940" y="10" as="geometry" />
          </mxCell>
        </UserObject>
        <mxCell id="DAo4bJDWTWjROyO8AEtg-17" parent="DAo4bJDWTWjROyO8AEtg-4" style="html=1;points=[];perimeter=orthogonalPerimeter;outlineConnect=0;targetShapes=umlLifeline;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};fillColor=light-dark(#f4f4f4,#2a2a2a);strokeColor=light-dark(#666666,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" value="" vertex="1">
          <mxGeometry height="1835" width="10" x="70" y="153" as="geometry" />
        </mxCell>
        <UserObject label="RouteEngine" mermaidId="n:RouteEng" mermaidBaseStyle="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="RouteEngine" id="DAo4bJDWTWjROyO8AEtg-5">
          <mxCell parent="tKDNcO07BNQh3qffwDL6-0" style="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="2073" width="150" x="1318" y="10" as="geometry" />
          </mxCell>
        </UserObject>
        <mxCell id="DAo4bJDWTWjROyO8AEtg-16" parent="DAo4bJDWTWjROyO8AEtg-5" style="html=1;points=[];perimeter=orthogonalPerimeter;outlineConnect=0;targetShapes=umlLifeline;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};fillColor=light-dark(#f4f4f4,#2a2a2a);strokeColor=light-dark(#666666,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" value="" vertex="1">
          <mxGeometry height="1582" width="10" x="70" y="197" as="geometry" />
        </mxCell>
        <UserObject label="SnapToPath" mermaidId="n:Snap" mermaidBaseStyle="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="SnapToPath" id="DAo4bJDWTWjROyO8AEtg-6">
          <mxCell parent="tKDNcO07BNQh3qffwDL6-0" style="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="2073" width="150" x="1633" y="10" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="AStarNavigator" mermaidId="n:AStar" mermaidBaseStyle="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="AStarNavigator" id="DAo4bJDWTWjROyO8AEtg-7">
          <mxCell parent="tKDNcO07BNQh3qffwDL6-0" style="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="2073" width="150" x="1833" y="10" as="geometry" />
          </mxCell>
        </UserObject>
        <mxCell id="DAo4bJDWTWjROyO8AEtg-15" parent="DAo4bJDWTWjROyO8AEtg-7" style="html=1;points=[];perimeter=orthogonalPerimeter;outlineConnect=0;targetShapes=umlLifeline;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};fillColor=light-dark(#f4f4f4,#2a2a2a);strokeColor=light-dark(#666666,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" value="" vertex="1">
          <mxGeometry height="955" width="10" x="70" y="417" as="geometry" />
        </mxCell>
        <UserObject label="MapView" mermaidId="n:MapUI" mermaidBaseStyle="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="MapView" id="DAo4bJDWTWjROyO8AEtg-8">
          <mxCell parent="tKDNcO07BNQh3qffwDL6-0" style="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="2073" width="150" x="2033" y="10" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="loop" mermaidId="n:f0" mermaidBaseStyle="html=1;shape=umlFrame;dashed=1;fixDash=1;dashPattern=2 2;strokeWidth=2;pointerEvents=0;dropTarget=0;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontSize=16;align=center;verticalAlign=middle;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);height=20;width=50;" mermaidBaseValue="loop" id="DAo4bJDWTWjROyO8AEtg-9">
          <mxCell parent="tKDNcO07BNQh3qffwDL6-0" style="html=1;shape=umlFrame;dashed=1;fixDash=1;dashPattern=2 2;strokeWidth=2;pointerEvents=0;dropTarget=0;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontSize=16;align=center;verticalAlign=middle;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);height=20;width=50;" vertex="1">
            <mxGeometry height="736" width="200" x="1808" y="622" as="geometry" />
          </mxCell>
        </UserObject>
        <mxCell id="DAo4bJDWTWjROyO8AEtg-10" parent="DAo4bJDWTWjROyO8AEtg-9" style="text;strokeColor=none;fillColor=none;align=center;verticalAlign=middle;whiteSpace=wrap;fontSize=16;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);" value="[Mientras la cola no este vacia]" vertex="1">
          <mxGeometry height="32" width="146" x="54" y="2" as="geometry" />
        </mxCell>
        <UserObject label="alt" mermaidId="n:f1" mermaidBaseStyle="html=1;shape=umlFrame;dashed=1;fixDash=1;dashPattern=2 2;strokeWidth=2;pointerEvents=0;dropTarget=0;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontSize=16;align=center;verticalAlign=middle;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);height=20;width=50;" mermaidBaseValue="alt" id="DAo4bJDWTWjROyO8AEtg-11">
          <mxCell parent="tKDNcO07BNQh3qffwDL6-0" style="html=1;shape=umlFrame;dashed=1;fixDash=1;dashPattern=2 2;strokeWidth=2;pointerEvents=0;dropTarget=0;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontSize=16;align=center;verticalAlign=middle;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);height=20;width=50;" vertex="1">
            <mxGeometry height="544" width="180" x="1818" y="794" as="geometry" />
          </mxCell>
        </UserObject>
        <mxCell id="DAo4bJDWTWjROyO8AEtg-12" parent="DAo4bJDWTWjROyO8AEtg-11" style="text;strokeColor=none;fillColor=none;align=center;verticalAlign=middle;whiteSpace=wrap;fontSize=16;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);" value="[Nodo actual es endNode]" vertex="1">
          <mxGeometry height="32" width="126" x="54" y="2" as="geometry" />
        </mxCell>
        <mxCell id="DAo4bJDWTWjROyO8AEtg-13" parent="DAo4bJDWTWjROyO8AEtg-11" style="shape=line;dashed=1;fixDash=1;dashPattern=2 2;strokeColor=light-dark(#9370DB,#cccccc);" vertex="1">
          <mxGeometry height="1" width="180" y="198" as="geometry" />
        </mxCell>
        <mxCell id="DAo4bJDWTWjROyO8AEtg-14" parent="DAo4bJDWTWjROyO8AEtg-11" style="text;strokeColor=none;fillColor=none;align=center;verticalAlign=middle;whiteSpace=wrap;fontSize=16;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);" value="[Explorar vecinos]" vertex="1">
          <mxGeometry height="16" width="180" y="200" as="geometry" />
        </mxCell>
        <UserObject label="Solicita ruta: Origen (Garita Periferico) -&gt; Destino (T-3)" mermaidId="e:Usuario-&gt;UI#0" mermaidBaseStyle="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="Solicita ruta: Origen (Garita Periferico) -&gt; Destino (T-3)" id="DAo4bJDWTWjROyO8AEtg-18">
          <mxCell edge="1" parent="tKDNcO07BNQh3qffwDL6-0" source="DAo4bJDWTWjROyO8AEtg-2" style="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="DAo4bJDWTWjROyO8AEtg-3">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="309" y="119" />
              </Array>
              <mxPoint x="85" y="119" as="sourcePoint" />
              <mxPoint x="532" y="119" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="DAo4bJDWTWjROyO8AEtg-19" parent="tKDNcO07BNQh3qffwDL6-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="1" vertex="1">
          <mxGeometry height="20" width="20" x="75" y="109" as="geometry" />
        </mxCell>
        <UserObject label="calculateRoute(origen, destino, NavigationMode.pedestrian)" mermaidId="e:UI-&gt;Ctrl#0" mermaidBaseStyle="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="calculateRoute(origen, destino, NavigationMode.pedestrian)" id="DAo4bJDWTWjROyO8AEtg-20">
          <mxCell edge="1" parent="tKDNcO07BNQh3qffwDL6-0" source="DAo4bJDWTWjROyO8AEtg-3" style="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="DAo4bJDWTWjROyO8AEtg-17">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="771" y="163" />
              </Array>
              <mxPoint x="532" y="163" as="sourcePoint" />
              <mxPoint x="1010" y="163" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="DAo4bJDWTWjROyO8AEtg-21" parent="tKDNcO07BNQh3qffwDL6-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="2" vertex="1">
          <mxGeometry height="20" width="20" x="522" y="153" as="geometry" />
        </mxCell>
        <UserObject label="planRoute(origen, destino, mode: pedestrian)" mermaidId="e:Ctrl-&gt;RouteEng#0" mermaidBaseStyle="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="planRoute(origen, destino, mode: pedestrian)" id="DAo4bJDWTWjROyO8AEtg-22">
          <mxCell edge="1" parent="tKDNcO07BNQh3qffwDL6-0" source="DAo4bJDWTWjROyO8AEtg-17" style="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="DAo4bJDWTWjROyO8AEtg-16">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="1204" y="207" />
              </Array>
              <mxPoint x="1020" y="207" as="sourcePoint" />
              <mxPoint x="1388" y="207" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="DAo4bJDWTWjROyO8AEtg-23" parent="tKDNcO07BNQh3qffwDL6-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="3" vertex="1">
          <mxGeometry height="20" width="20" x="1005" y="197" as="geometry" />
        </mxCell>
        <UserObject label="findNearestNode(origen, graph)" mermaidId="e:RouteEng-&gt;Snap#0" mermaidBaseStyle="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="findNearestNode(origen, graph)" id="DAo4bJDWTWjROyO8AEtg-24">
          <mxCell edge="1" parent="tKDNcO07BNQh3qffwDL6-0" source="DAo4bJDWTWjROyO8AEtg-16" style="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="DAo4bJDWTWjROyO8AEtg-6">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="1553" y="251" />
              </Array>
              <mxPoint x="1398" y="251" as="sourcePoint" />
              <mxPoint x="1708" y="251" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="DAo4bJDWTWjROyO8AEtg-25" parent="tKDNcO07BNQh3qffwDL6-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="4" vertex="1">
          <mxGeometry height="20" width="20" x="1383" y="241" as="geometry" />
        </mxCell>
        <UserObject label="Nodo Inicial (nodo_garita_periferico)" mermaidId="e:Snap-&gt;RouteEng#0" mermaidBaseStyle="dashed=1;fixDash=1;dashPattern=3 3;endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="Nodo Inicial (nodo_garita_periferico)" id="DAo4bJDWTWjROyO8AEtg-26">
          <mxCell edge="1" parent="tKDNcO07BNQh3qffwDL6-0" source="DAo4bJDWTWjROyO8AEtg-6" style="dashed=1;fixDash=1;dashPattern=3 3;endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="DAo4bJDWTWjROyO8AEtg-16">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="1553" y="295" />
              </Array>
              <mxPoint x="1708" y="295" as="sourcePoint" />
              <mxPoint x="1398" y="295" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="DAo4bJDWTWjROyO8AEtg-27" parent="tKDNcO07BNQh3qffwDL6-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="5" vertex="1">
          <mxGeometry height="20" width="20" x="1698" y="285" as="geometry" />
        </mxCell>
        <UserObject label="findNearestNode(destino, graph)" mermaidId="e:RouteEng-&gt;Snap#1" mermaidBaseStyle="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="findNearestNode(destino, graph)" id="DAo4bJDWTWjROyO8AEtg-28">
          <mxCell edge="1" parent="tKDNcO07BNQh3qffwDL6-0" source="DAo4bJDWTWjROyO8AEtg-16" style="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="DAo4bJDWTWjROyO8AEtg-6">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="1553" y="339" />
              </Array>
              <mxPoint x="1398" y="339" as="sourcePoint" />
              <mxPoint x="1708" y="339" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="DAo4bJDWTWjROyO8AEtg-29" parent="tKDNcO07BNQh3qffwDL6-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="6" vertex="1">
          <mxGeometry height="20" width="20" x="1383" y="329" as="geometry" />
        </mxCell>
        <UserObject label="Nodo Final (nodo_t3_acceso)" mermaidId="e:Snap-&gt;RouteEng#1" mermaidBaseStyle="dashed=1;fixDash=1;dashPattern=3 3;endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="Nodo Final (nodo_t3_acceso)" id="DAo4bJDWTWjROyO8AEtg-30">
          <mxCell edge="1" parent="tKDNcO07BNQh3qffwDL6-0" source="DAo4bJDWTWjROyO8AEtg-6" style="dashed=1;fixDash=1;dashPattern=3 3;endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="DAo4bJDWTWjROyO8AEtg-16">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="1553" y="383" />
              </Array>
              <mxPoint x="1708" y="383" as="sourcePoint" />
              <mxPoint x="1398" y="383" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="DAo4bJDWTWjROyO8AEtg-31" parent="tKDNcO07BNQh3qffwDL6-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="7" vertex="1">
          <mxGeometry height="20" width="20" x="1698" y="373" as="geometry" />
        </mxCell>
        <UserObject label="findPath(startNode, endNode, mode, graph)" mermaidId="e:RouteEng-&gt;AStar#0" mermaidBaseStyle="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="findPath(startNode, endNode, mode, graph)" id="DAo4bJDWTWjROyO8AEtg-32">
          <mxCell edge="1" parent="tKDNcO07BNQh3qffwDL6-0" source="DAo4bJDWTWjROyO8AEtg-16" style="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="DAo4bJDWTWjROyO8AEtg-15">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="1651" y="427" />
              </Array>
              <mxPoint x="1398" y="427" as="sourcePoint" />
              <mxPoint x="1903" y="427" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="DAo4bJDWTWjROyO8AEtg-33" parent="tKDNcO07BNQh3qffwDL6-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="8" vertex="1">
          <mxGeometry height="20" width="20" x="1383" y="417" as="geometry" />
        </mxCell>
        <UserObject label="" mermaidId="e:AStar-&gt;AStar#0" mermaidBaseStyle="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="" id="DAo4bJDWTWjROyO8AEtg-34">
          <mxCell edge="1" parent="tKDNcO07BNQh3qffwDL6-0" source="DAo4bJDWTWjROyO8AEtg-15" style="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="DAo4bJDWTWjROyO8AEtg-15">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="1948" y="518" />
                <mxPoint x="1952" y="530" />
                <mxPoint x="1948" y="542" />
              </Array>
              <mxPoint x="1913" y="518" as="sourcePoint" />
              <mxPoint x="1913" y="542" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="DAo4bJDWTWjROyO8AEtg-35" parent="tKDNcO07BNQh3qffwDL6-0" style="text;html=1;strokeColor=none;fillColor=none;align=center;verticalAlign=middle;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;fontColor=light-dark(#333333,#cccccc);" value="Inicializar cola de prioridad con startNode (costo = 0)" vertex="1">
          <mxGeometry height="18" width="200" x="1813" y="494" as="geometry" />
        </mxCell>
        <mxCell id="DAo4bJDWTWjROyO8AEtg-36" parent="tKDNcO07BNQh3qffwDL6-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="9" vertex="1">
          <mxGeometry height="20" width="20" x="1898" y="508" as="geometry" />
        </mxCell>
        <UserObject label="" mermaidId="e:AStar-&gt;AStar#1" mermaidBaseStyle="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="" id="DAo4bJDWTWjROyO8AEtg-37">
          <mxCell edge="1" parent="tKDNcO07BNQh3qffwDL6-0" source="DAo4bJDWTWjROyO8AEtg-15" style="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="DAo4bJDWTWjROyO8AEtg-15">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="1948" y="697" />
                <mxPoint x="1952" y="709" />
                <mxPoint x="1948" y="721" />
              </Array>
              <mxPoint x="1913" y="697" as="sourcePoint" />
              <mxPoint x="1913" y="721" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="DAo4bJDWTWjROyO8AEtg-38" parent="tKDNcO07BNQh3qffwDL6-0" style="text;html=1;strokeColor=none;fillColor=none;align=center;verticalAlign=middle;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;fontColor=light-dark(#333333,#cccccc);" value="Extraer nodo actual con menor fScore (gScore + heuristica)" vertex="1">
          <mxGeometry height="18" width="200" x="1813" y="673" as="geometry" />
        </mxCell>
        <mxCell id="DAo4bJDWTWjROyO8AEtg-39" parent="tKDNcO07BNQh3qffwDL6-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="10" vertex="1">
          <mxGeometry height="20" width="20" x="1898" y="687" as="geometry" />
        </mxCell>
        <UserObject label="" mermaidId="e:AStar-&gt;AStar#2" mermaidBaseStyle="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="" id="DAo4bJDWTWjROyO8AEtg-40">
          <mxCell edge="1" parent="tKDNcO07BNQh3qffwDL6-0" source="DAo4bJDWTWjROyO8AEtg-15" style="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="DAo4bJDWTWjROyO8AEtg-15">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="1948" y="869" />
                <mxPoint x="1952" y="881" />
                <mxPoint x="1948" y="893" />
              </Array>
              <mxPoint x="1913" y="869" as="sourcePoint" />
              <mxPoint x="1913" y="893" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="DAo4bJDWTWjROyO8AEtg-41" parent="tKDNcO07BNQh3qffwDL6-0" style="text;html=1;strokeColor=none;fillColor=none;align=center;verticalAlign=middle;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;fontColor=light-dark(#333333,#cccccc);" value="Reconstruir ruta enlazando predecesores" vertex="1">
          <mxGeometry height="18" width="200" x="1813" y="845" as="geometry" />
        </mxCell>
        <mxCell id="DAo4bJDWTWjROyO8AEtg-42" parent="tKDNcO07BNQh3qffwDL6-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="11" vertex="1">
          <mxGeometry height="20" width="20" x="1898" y="859" as="geometry" />
        </mxCell>
        <UserObject label="" mermaidId="e:AStar-&gt;AStar#3" mermaidBaseStyle="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="" id="DAo4bJDWTWjROyO8AEtg-43">
          <mxCell edge="1" parent="tKDNcO07BNQh3qffwDL6-0" source="DAo4bJDWTWjROyO8AEtg-15" style="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="DAo4bJDWTWjROyO8AEtg-15">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="1948" y="1036" />
                <mxPoint x="1952" y="1048" />
                <mxPoint x="1948" y="1060" />
              </Array>
              <mxPoint x="1913" y="1036" as="sourcePoint" />
              <mxPoint x="1913" y="1060" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="DAo4bJDWTWjROyO8AEtg-44" parent="tKDNcO07BNQh3qffwDL6-0" style="text;html=1;strokeColor=none;fillColor=none;align=center;verticalAlign=middle;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;fontColor=light-dark(#333333,#cccccc);" value="Filtrar aristas compatibles con NavigationMode" vertex="1">
          <mxGeometry height="18" width="200" x="1813" y="1012" as="geometry" />
        </mxCell>
        <mxCell id="DAo4bJDWTWjROyO8AEtg-45" parent="tKDNcO07BNQh3qffwDL6-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="12" vertex="1">
          <mxGeometry height="20" width="20" x="1898" y="1026" as="geometry" />
        </mxCell>
        <UserObject label="" mermaidId="e:AStar-&gt;AStar#4" mermaidBaseStyle="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="" id="DAo4bJDWTWjROyO8AEtg-46">
          <mxCell edge="1" parent="tKDNcO07BNQh3qffwDL6-0" source="DAo4bJDWTWjROyO8AEtg-15" style="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="DAo4bJDWTWjROyO8AEtg-15">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="1948" y="1167" />
                <mxPoint x="1952" y="1179" />
                <mxPoint x="1948" y="1191" />
              </Array>
              <mxPoint x="1913" y="1167" as="sourcePoint" />
              <mxPoint x="1913" y="1191" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="DAo4bJDWTWjROyO8AEtg-47" parent="tKDNcO07BNQh3qffwDL6-0" style="text;html=1;strokeColor=none;fillColor=none;align=center;verticalAlign=middle;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;fontColor=light-dark(#333333,#cccccc);" value="Evaluar si nuevo gScore es menor al registrado" vertex="1">
          <mxGeometry height="18" width="200" x="1813" y="1143" as="geometry" />
        </mxCell>
        <mxCell id="DAo4bJDWTWjROyO8AEtg-48" parent="tKDNcO07BNQh3qffwDL6-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="13" vertex="1">
          <mxGeometry height="20" width="20" x="1898" y="1157" as="geometry" />
        </mxCell>
        <UserObject label="" mermaidId="e:AStar-&gt;AStar#5" mermaidBaseStyle="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="" id="DAo4bJDWTWjROyO8AEtg-49">
          <mxCell edge="1" parent="tKDNcO07BNQh3qffwDL6-0" source="DAo4bJDWTWjROyO8AEtg-15" style="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="DAo4bJDWTWjROyO8AEtg-15">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="1948" y="1298" />
                <mxPoint x="1952" y="1310" />
                <mxPoint x="1948" y="1322" />
              </Array>
              <mxPoint x="1913" y="1298" as="sourcePoint" />
              <mxPoint x="1913" y="1322" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="DAo4bJDWTWjROyO8AEtg-50" parent="tKDNcO07BNQh3qffwDL6-0" style="text;html=1;strokeColor=none;fillColor=none;align=center;verticalAlign=middle;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;fontColor=light-dark(#333333,#cccccc);" value="Actualizar mejor costo e insertar vecino en cola" vertex="1">
          <mxGeometry height="18" width="200" x="1813" y="1274" as="geometry" />
        </mxCell>
        <mxCell id="DAo4bJDWTWjROyO8AEtg-51" parent="tKDNcO07BNQh3qffwDL6-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="14" vertex="1">
          <mxGeometry height="20" width="20" x="1898" y="1288" as="geometry" />
        </mxCell>
        <UserObject label="List&lt;CampusNode&gt; (secuencia optima)" mermaidId="e:AStar-&gt;RouteEng#0" mermaidBaseStyle="dashed=1;fixDash=1;dashPattern=3 3;endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="List&lt;CampusNode&gt; (secuencia optima)" id="DAo4bJDWTWjROyO8AEtg-52">
          <mxCell edge="1" parent="tKDNcO07BNQh3qffwDL6-0" source="DAo4bJDWTWjROyO8AEtg-15" style="dashed=1;fixDash=1;dashPattern=3 3;endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="DAo4bJDWTWjROyO8AEtg-16">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="1651" y="1382" />
              </Array>
              <mxPoint x="1903" y="1382" as="sourcePoint" />
              <mxPoint x="1398" y="1382" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="DAo4bJDWTWjROyO8AEtg-53" parent="tKDNcO07BNQh3qffwDL6-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="15" vertex="1">
          <mxGeometry height="20" width="20" x="1898" y="1372" as="geometry" />
        </mxCell>
        <UserObject label="" mermaidId="e:RouteEng-&gt;RouteEng#0" mermaidBaseStyle="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="" id="DAo4bJDWTWjROyO8AEtg-54">
          <mxCell edge="1" parent="tKDNcO07BNQh3qffwDL6-0" source="DAo4bJDWTWjROyO8AEtg-16" style="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="DAo4bJDWTWjROyO8AEtg-16">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="1433" y="1473" />
                <mxPoint x="1437" y="1485" />
                <mxPoint x="1433" y="1497" />
              </Array>
              <mxPoint x="1398" y="1473" as="sourcePoint" />
              <mxPoint x="1398" y="1497" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="DAo4bJDWTWjROyO8AEtg-55" parent="tKDNcO07BNQh3qffwDL6-0" style="text;html=1;strokeColor=none;fillColor=none;align=center;verticalAlign=middle;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;fontColor=light-dark(#333333,#cccccc);" value="Generar polilinea completa (List&lt;LatLng&gt;)" vertex="1">
          <mxGeometry height="18" width="200" x="1298" y="1449" as="geometry" />
        </mxCell>
        <mxCell id="DAo4bJDWTWjROyO8AEtg-56" parent="tKDNcO07BNQh3qffwDL6-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="16" vertex="1">
          <mxGeometry height="20" width="20" x="1383" y="1463" as="geometry" />
        </mxCell>
        <UserObject label="" mermaidId="e:RouteEng-&gt;RouteEng#1" mermaidBaseStyle="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="" id="DAo4bJDWTWjROyO8AEtg-57">
          <mxCell edge="1" parent="tKDNcO07BNQh3qffwDL6-0" source="DAo4bJDWTWjROyO8AEtg-16" style="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="DAo4bJDWTWjROyO8AEtg-16">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="1433" y="1594" />
                <mxPoint x="1437" y="1606" />
                <mxPoint x="1433" y="1618" />
              </Array>
              <mxPoint x="1398" y="1594" as="sourcePoint" />
              <mxPoint x="1398" y="1618" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="DAo4bJDWTWjROyO8AEtg-58" parent="tKDNcO07BNQh3qffwDL6-0" style="text;html=1;strokeColor=none;fillColor=none;align=center;verticalAlign=middle;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;fontColor=light-dark(#333333,#cccccc);" value="Calcular distancia acumulada y tiempo estimado" vertex="1">
          <mxGeometry height="18" width="200" x="1298" y="1570" as="geometry" />
        </mxCell>
        <mxCell id="DAo4bJDWTWjROyO8AEtg-59" parent="tKDNcO07BNQh3qffwDL6-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="17" vertex="1">
          <mxGeometry height="20" width="20" x="1383" y="1584" as="geometry" />
        </mxCell>
        <UserObject label="" mermaidId="e:RouteEng-&gt;RouteEng#2" mermaidBaseStyle="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="" id="DAo4bJDWTWjROyO8AEtg-60">
          <mxCell edge="1" parent="tKDNcO07BNQh3qffwDL6-0" source="DAo4bJDWTWjROyO8AEtg-16" style="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="DAo4bJDWTWjROyO8AEtg-16">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="1433" y="1715" />
                <mxPoint x="1437" y="1727" />
                <mxPoint x="1433" y="1739" />
              </Array>
              <mxPoint x="1398" y="1715" as="sourcePoint" />
              <mxPoint x="1398" y="1739" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="DAo4bJDWTWjROyO8AEtg-61" parent="tKDNcO07BNQh3qffwDL6-0" style="text;html=1;strokeColor=none;fillColor=none;align=center;verticalAlign=middle;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;fontColor=light-dark(#333333,#cccccc);" value="Generar instrucciones paso a paso" vertex="1">
          <mxGeometry height="18" width="200" x="1298" y="1691" as="geometry" />
        </mxCell>
        <mxCell id="DAo4bJDWTWjROyO8AEtg-62" parent="tKDNcO07BNQh3qffwDL6-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="18" vertex="1">
          <mxGeometry height="20" width="20" x="1383" y="1705" as="geometry" />
        </mxCell>
        <UserObject label="CampusRoute construida" mermaidId="e:RouteEng-&gt;Ctrl#0" mermaidBaseStyle="dashed=1;fixDash=1;dashPattern=3 3;endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="CampusRoute construida" id="DAo4bJDWTWjROyO8AEtg-63">
          <mxCell edge="1" parent="tKDNcO07BNQh3qffwDL6-0" source="DAo4bJDWTWjROyO8AEtg-16" style="dashed=1;fixDash=1;dashPattern=3 3;endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="DAo4bJDWTWjROyO8AEtg-17">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="1204" y="1789" />
              </Array>
              <mxPoint x="1388" y="1789" as="sourcePoint" />
              <mxPoint x="1020" y="1789" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="DAo4bJDWTWjROyO8AEtg-64" parent="tKDNcO07BNQh3qffwDL6-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="19" vertex="1">
          <mxGeometry height="20" width="20" x="1383" y="1779" as="geometry" />
        </mxCell>
        <UserObject label="" mermaidId="e:Ctrl-&gt;Ctrl#0" mermaidBaseStyle="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="" id="DAo4bJDWTWjROyO8AEtg-65">
          <mxCell edge="1" parent="tKDNcO07BNQh3qffwDL6-0" source="DAo4bJDWTWjROyO8AEtg-17" style="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="DAo4bJDWTWjROyO8AEtg-17">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="1055" y="1880" />
                <mxPoint x="1059" y="1892" />
                <mxPoint x="1055" y="1904" />
              </Array>
              <mxPoint x="1020" y="1880" as="sourcePoint" />
              <mxPoint x="1020" y="1904" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="DAo4bJDWTWjROyO8AEtg-66" parent="tKDNcO07BNQh3qffwDL6-0" style="text;html=1;strokeColor=none;fillColor=none;align=center;verticalAlign=middle;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;fontColor=light-dark(#333333,#cccccc);" value="Notificar nuevo estado: activeRoute = ruta" vertex="1">
          <mxGeometry height="18" width="200" x="920" y="1856" as="geometry" />
        </mxCell>
        <mxCell id="DAo4bJDWTWjROyO8AEtg-67" parent="tKDNcO07BNQh3qffwDL6-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="20" vertex="1">
          <mxGeometry height="20" width="20" x="1005" y="1870" as="geometry" />
        </mxCell>
        <UserObject label="Dibujar PolylineLayer sobre el mapa" mermaidId="e:Ctrl-&gt;MapUI#0" mermaidBaseStyle="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="Dibujar PolylineLayer sobre el mapa" id="DAo4bJDWTWjROyO8AEtg-68">
          <mxCell edge="1" parent="tKDNcO07BNQh3qffwDL6-0" source="DAo4bJDWTWjROyO8AEtg-17" style="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="DAo4bJDWTWjROyO8AEtg-8">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="1564" y="1954" />
              </Array>
              <mxPoint x="1020" y="1954" as="sourcePoint" />
              <mxPoint x="2108" y="1954" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="DAo4bJDWTWjROyO8AEtg-69" parent="tKDNcO07BNQh3qffwDL6-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="21" vertex="1">
          <mxGeometry height="20" width="20" x="1005" y="1944" as="geometry" />
        </mxCell>
        <UserObject label="Desplegar TurnByTurnBanner con primera instruccion" mermaidId="e:Ctrl-&gt;UI#0" mermaidBaseStyle="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="Desplegar TurnByTurnBanner con primera instruccion" id="DAo4bJDWTWjROyO8AEtg-70">
          <mxCell edge="1" parent="tKDNcO07BNQh3qffwDL6-0" source="DAo4bJDWTWjROyO8AEtg-17" style="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="DAo4bJDWTWjROyO8AEtg-3">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="771" y="1998" />
              </Array>
              <mxPoint x="1010" y="1998" as="sourcePoint" />
              <mxPoint x="532" y="1998" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="DAo4bJDWTWjROyO8AEtg-71" parent="tKDNcO07BNQh3qffwDL6-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="22" vertex="1">
          <mxGeometry height="20" width="20" x="1005" y="1988" as="geometry" />
        </mxCell>
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>

```
---

### Flujo 4: Navegacion en Tiempo Real y Snap-to-Path

Muestra el procesamiento de las actualizaciones satelitales del dispositivo y su proyeccion a la red geometrica:

```drawio
<mxfile>
  <diagram id="npm2DMhMJF5euA0SVEq_" name="Page-1">
    <mxGraphModel dx="2" dy="1" grid="0" gridSize="10" guides="1" tooltips="0" connect="0" arrows="0" fold="0" page="0" pageScale="1" pageWidth="850" pageHeight="1100" math="0" shadow="0">
      <root>
        <mxCell id="WUgnBUTgcxEe0jBnYhTB-0" />
        <mxCell id="WUgnBUTgcxEe0jBnYhTB-1" parent="WUgnBUTgcxEe0jBnYhTB-0" />
        <UserObject label="" mermaidData="{&#xa;  &quot;data&quot;: &quot;sequenceDiagram\n    autonumber\n    actor Usuario\n    participant UI as SearchBar / Interfaz\n    participant Ctrl as UsacCampusMapController\n    participant SearchEng as SearchEngine\n    participant MapUI as MapView\n\n    Usuario-&gt;&gt;UI: Escribe \&quot;T3 Ingenieria\&quot;\n    UI-&gt;&gt;Ctrl: search(\&quot;T3 Ingenieria\&quot;)\n    Ctrl-&gt;&gt;SearchEng: search(\&quot;T3 Ingenieria\&quot;)\n    activate SearchEng\n    \n    SearchEng-&gt;&gt;SearchEng: Normalizar consulta (minusculas, remover tildes, trim)\n    SearchEng-&gt;&gt;SearchEng: Comparar por codigo exacto de edificio (ej. \&quot;T-3\&quot;)\n    SearchEng-&gt;&gt;SearchEng: Comparar por tokens de nombre y descripcion\n    SearchEng-&gt;&gt;SearchEng: Calcular puntuacion de coincidencia (Fuzzy Score)\n    SearchEng-&gt;&gt;SearchEng: Ordenar resultados por relevancia descendente\n    SearchEng--&gt;&gt;Ctrl: List&lt;CampusBuilding&gt; + List&lt;CampusPoi&gt;\n    deactivate SearchEng\n\n    Ctrl--&gt;&gt;UI: Notificar lista de resultados encontrados\n    Usuario-&gt;&gt;UI: Selecciona \&quot;Edificio T-3 - Facultad de Ingenieria\&quot;\n    UI-&gt;&gt;Ctrl: selectBuilding(t3Building)\n    Ctrl-&gt;&gt;Ctrl: Actualizar selectedBuilding = t3Building\n    Ctrl-&gt;&gt;MapUI: Mover camara al centroide de T-3 con animacion\n    Ctrl-&gt;&gt;UI: Mostrar PoiDetailSheet con informacion de T-3&quot;,&#xa;  &quot;config&quot;: null&#xa;}" id="fooONwX62kx8ZsJYX7d8-0">
          <mxCell connectable="0" parent="WUgnBUTgcxEe0jBnYhTB-1" style="group;transparentBounds=1;editIcon=1;lockedGroup=0;groupPadding=10;" vertex="1">
            <mxGeometry as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="Usuario" mermaidId="n:Usuario" mermaidBaseStyle="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);participant=seqActorStick;verticalAlign=bottom;align=center;spacingBottom=4;size=90;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="Usuario" id="WUgnBUTgcxEe0jBnYhTB-2">
          <mxCell parent="fooONwX62kx8ZsJYX7d8-0" style="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);participant=seqActorStick;verticalAlign=bottom;align=center;spacingBottom=4;size=90;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="1297" width="150" x="10" y="10" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="SearchBar / Interfaz" mermaidId="n:UI" mermaidBaseStyle="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="SearchBar / Interfaz" id="WUgnBUTgcxEe0jBnYhTB-3">
          <mxCell parent="fooONwX62kx8ZsJYX7d8-0" style="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="1272" width="150" x="407" y="10" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="UsacCampusMapController" mermaidId="n:Ctrl" mermaidBaseStyle="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="UsacCampusMapController" id="WUgnBUTgcxEe0jBnYhTB-4">
          <mxCell parent="fooONwX62kx8ZsJYX7d8-0" style="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="1272" width="150" x="789" y="10" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="SearchEngine" mermaidId="n:SearchEng" mermaidBaseStyle="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="SearchEngine" id="WUgnBUTgcxEe0jBnYhTB-5">
          <mxCell parent="fooONwX62kx8ZsJYX7d8-0" style="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="1272" width="150" x="1001" y="10" as="geometry" />
          </mxCell>
        </UserObject>
        <mxCell id="WUgnBUTgcxEe0jBnYhTB-7" parent="WUgnBUTgcxEe0jBnYhTB-5" style="html=1;points=[];perimeter=orthogonalPerimeter;outlineConnect=0;targetShapes=umlLifeline;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};fillColor=light-dark(#f4f4f4,#2a2a2a);strokeColor=light-dark(#666666,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" value="" vertex="1">
          <mxGeometry height="649" width="10" x="70" y="197" as="geometry" />
        </mxCell>
        <UserObject label="MapView" mermaidId="n:MapUI" mermaidBaseStyle="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="MapView" id="WUgnBUTgcxEe0jBnYhTB-6">
          <mxCell parent="fooONwX62kx8ZsJYX7d8-0" style="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="1272" width="150" x="1201" y="10" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="Escribe &quot;T3 Ingenieria&quot;" mermaidId="e:Usuario-&gt;UI#0" mermaidBaseStyle="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="Escribe &quot;T3 Ingenieria&quot;" id="WUgnBUTgcxEe0jBnYhTB-8">
          <mxCell edge="1" parent="fooONwX62kx8ZsJYX7d8-0" source="WUgnBUTgcxEe0jBnYhTB-2" style="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="WUgnBUTgcxEe0jBnYhTB-3">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="284" y="119" />
              </Array>
              <mxPoint x="85" y="119" as="sourcePoint" />
              <mxPoint x="482" y="119" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="WUgnBUTgcxEe0jBnYhTB-9" parent="fooONwX62kx8ZsJYX7d8-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="1" vertex="1">
          <mxGeometry height="20" width="20" x="75" y="109" as="geometry" />
        </mxCell>
        <UserObject label="search(&quot;T3 Ingenieria&quot;)" mermaidId="e:UI-&gt;Ctrl#0" mermaidBaseStyle="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="search(&quot;T3 Ingenieria&quot;)" id="WUgnBUTgcxEe0jBnYhTB-10">
          <mxCell edge="1" parent="fooONwX62kx8ZsJYX7d8-0" source="WUgnBUTgcxEe0jBnYhTB-3" style="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="WUgnBUTgcxEe0jBnYhTB-4">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="673" y="163" />
              </Array>
              <mxPoint x="482" y="163" as="sourcePoint" />
              <mxPoint x="864" y="163" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="WUgnBUTgcxEe0jBnYhTB-11" parent="fooONwX62kx8ZsJYX7d8-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="2" vertex="1">
          <mxGeometry height="20" width="20" x="472" y="153" as="geometry" />
        </mxCell>
        <UserObject label="search(&quot;T3 Ingenieria&quot;)" mermaidId="e:Ctrl-&gt;SearchEng#0" mermaidBaseStyle="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="search(&quot;T3 Ingenieria&quot;)" id="WUgnBUTgcxEe0jBnYhTB-12">
          <mxCell edge="1" parent="fooONwX62kx8ZsJYX7d8-0" source="WUgnBUTgcxEe0jBnYhTB-4" style="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="WUgnBUTgcxEe0jBnYhTB-7">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="968" y="207" />
              </Array>
              <mxPoint x="864" y="207" as="sourcePoint" />
              <mxPoint x="1071" y="207" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="WUgnBUTgcxEe0jBnYhTB-13" parent="fooONwX62kx8ZsJYX7d8-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="3" vertex="1">
          <mxGeometry height="20" width="20" x="854" y="197" as="geometry" />
        </mxCell>
        <UserObject label="" mermaidId="e:SearchEng-&gt;SearchEng#0" mermaidBaseStyle="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="" id="WUgnBUTgcxEe0jBnYhTB-14">
          <mxCell edge="1" parent="fooONwX62kx8ZsJYX7d8-0" source="WUgnBUTgcxEe0jBnYhTB-7" style="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="WUgnBUTgcxEe0jBnYhTB-7">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="1116" y="298" />
                <mxPoint x="1120" y="310" />
                <mxPoint x="1116" y="322" />
              </Array>
              <mxPoint x="1081" y="298" as="sourcePoint" />
              <mxPoint x="1081" y="322" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="WUgnBUTgcxEe0jBnYhTB-15" parent="fooONwX62kx8ZsJYX7d8-0" style="text;html=1;strokeColor=none;fillColor=none;align=center;verticalAlign=middle;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;fontColor=light-dark(#333333,#cccccc);" value="Normalizar consulta (minusculas, remover tildes, trim)" vertex="1">
          <mxGeometry height="18" width="200" x="981" y="274" as="geometry" />
        </mxCell>
        <mxCell id="WUgnBUTgcxEe0jBnYhTB-16" parent="fooONwX62kx8ZsJYX7d8-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="4" vertex="1">
          <mxGeometry height="20" width="20" x="1066" y="288" as="geometry" />
        </mxCell>
        <UserObject label="" mermaidId="e:SearchEng-&gt;SearchEng#1" mermaidBaseStyle="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="" id="WUgnBUTgcxEe0jBnYhTB-17">
          <mxCell edge="1" parent="fooONwX62kx8ZsJYX7d8-0" source="WUgnBUTgcxEe0jBnYhTB-7" style="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="WUgnBUTgcxEe0jBnYhTB-7">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="1116" y="419" />
                <mxPoint x="1120" y="431" />
                <mxPoint x="1116" y="443" />
              </Array>
              <mxPoint x="1081" y="419" as="sourcePoint" />
              <mxPoint x="1081" y="443" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="WUgnBUTgcxEe0jBnYhTB-18" parent="fooONwX62kx8ZsJYX7d8-0" style="text;html=1;strokeColor=none;fillColor=none;align=center;verticalAlign=middle;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;fontColor=light-dark(#333333,#cccccc);" value="Comparar por codigo exacto de edificio (ej. &quot;T-3&quot;)" vertex="1">
          <mxGeometry height="18" width="200" x="981" y="395" as="geometry" />
        </mxCell>
        <mxCell id="WUgnBUTgcxEe0jBnYhTB-19" parent="fooONwX62kx8ZsJYX7d8-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="5" vertex="1">
          <mxGeometry height="20" width="20" x="1066" y="409" as="geometry" />
        </mxCell>
        <UserObject label="" mermaidId="e:SearchEng-&gt;SearchEng#2" mermaidBaseStyle="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="" id="WUgnBUTgcxEe0jBnYhTB-20">
          <mxCell edge="1" parent="fooONwX62kx8ZsJYX7d8-0" source="WUgnBUTgcxEe0jBnYhTB-7" style="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="WUgnBUTgcxEe0jBnYhTB-7">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="1116" y="540" />
                <mxPoint x="1120" y="552" />
                <mxPoint x="1116" y="564" />
              </Array>
              <mxPoint x="1081" y="540" as="sourcePoint" />
              <mxPoint x="1081" y="564" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="WUgnBUTgcxEe0jBnYhTB-21" parent="fooONwX62kx8ZsJYX7d8-0" style="text;html=1;strokeColor=none;fillColor=none;align=center;verticalAlign=middle;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;fontColor=light-dark(#333333,#cccccc);" value="Comparar por tokens de nombre y descripcion" vertex="1">
          <mxGeometry height="18" width="200" x="981" y="516" as="geometry" />
        </mxCell>
        <mxCell id="WUgnBUTgcxEe0jBnYhTB-22" parent="fooONwX62kx8ZsJYX7d8-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="6" vertex="1">
          <mxGeometry height="20" width="20" x="1066" y="530" as="geometry" />
        </mxCell>
        <UserObject label="" mermaidId="e:SearchEng-&gt;SearchEng#3" mermaidBaseStyle="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="" id="WUgnBUTgcxEe0jBnYhTB-23">
          <mxCell edge="1" parent="fooONwX62kx8ZsJYX7d8-0" source="WUgnBUTgcxEe0jBnYhTB-7" style="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="WUgnBUTgcxEe0jBnYhTB-7">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="1116" y="661" />
                <mxPoint x="1120" y="673" />
                <mxPoint x="1116" y="685" />
              </Array>
              <mxPoint x="1081" y="661" as="sourcePoint" />
              <mxPoint x="1081" y="685" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="WUgnBUTgcxEe0jBnYhTB-24" parent="fooONwX62kx8ZsJYX7d8-0" style="text;html=1;strokeColor=none;fillColor=none;align=center;verticalAlign=middle;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;fontColor=light-dark(#333333,#cccccc);" value="Calcular puntuacion de coincidencia (Fuzzy Score)" vertex="1">
          <mxGeometry height="18" width="200" x="981" y="637" as="geometry" />
        </mxCell>
        <mxCell id="WUgnBUTgcxEe0jBnYhTB-25" parent="fooONwX62kx8ZsJYX7d8-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="7" vertex="1">
          <mxGeometry height="20" width="20" x="1066" y="651" as="geometry" />
        </mxCell>
        <UserObject label="" mermaidId="e:SearchEng-&gt;SearchEng#4" mermaidBaseStyle="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="" id="WUgnBUTgcxEe0jBnYhTB-26">
          <mxCell edge="1" parent="fooONwX62kx8ZsJYX7d8-0" source="WUgnBUTgcxEe0jBnYhTB-7" style="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="WUgnBUTgcxEe0jBnYhTB-7">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="1116" y="782" />
                <mxPoint x="1120" y="794" />
                <mxPoint x="1116" y="806" />
              </Array>
              <mxPoint x="1081" y="782" as="sourcePoint" />
              <mxPoint x="1081" y="806" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="WUgnBUTgcxEe0jBnYhTB-27" parent="fooONwX62kx8ZsJYX7d8-0" style="text;html=1;strokeColor=none;fillColor=none;align=center;verticalAlign=middle;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;fontColor=light-dark(#333333,#cccccc);" value="Ordenar resultados por relevancia descendente" vertex="1">
          <mxGeometry height="18" width="200" x="981" y="758" as="geometry" />
        </mxCell>
        <mxCell id="WUgnBUTgcxEe0jBnYhTB-28" parent="fooONwX62kx8ZsJYX7d8-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="8" vertex="1">
          <mxGeometry height="20" width="20" x="1066" y="772" as="geometry" />
        </mxCell>
        <UserObject label="List&lt;CampusBuilding&gt; + List&lt;CampusPoi&gt;" mermaidId="e:SearchEng-&gt;Ctrl#0" mermaidBaseStyle="dashed=1;fixDash=1;dashPattern=3 3;endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="List&lt;CampusBuilding&gt; + List&lt;CampusPoi&gt;" id="WUgnBUTgcxEe0jBnYhTB-29">
          <mxCell edge="1" parent="fooONwX62kx8ZsJYX7d8-0" source="WUgnBUTgcxEe0jBnYhTB-7" style="dashed=1;fixDash=1;dashPattern=3 3;endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="WUgnBUTgcxEe0jBnYhTB-4">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="968" y="856" />
              </Array>
              <mxPoint x="1071" y="856" as="sourcePoint" />
              <mxPoint x="864" y="856" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="WUgnBUTgcxEe0jBnYhTB-30" parent="fooONwX62kx8ZsJYX7d8-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="9" vertex="1">
          <mxGeometry height="20" width="20" x="1066" y="846" as="geometry" />
        </mxCell>
        <UserObject label="Notificar lista de resultados encontrados" mermaidId="e:Ctrl-&gt;UI#0" mermaidBaseStyle="dashed=1;fixDash=1;dashPattern=3 3;endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="Notificar lista de resultados encontrados" id="WUgnBUTgcxEe0jBnYhTB-31">
          <mxCell edge="1" parent="fooONwX62kx8ZsJYX7d8-0" source="WUgnBUTgcxEe0jBnYhTB-4" style="dashed=1;fixDash=1;dashPattern=3 3;endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="WUgnBUTgcxEe0jBnYhTB-3">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="673" y="900" />
              </Array>
              <mxPoint x="864" y="900" as="sourcePoint" />
              <mxPoint x="482" y="900" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="WUgnBUTgcxEe0jBnYhTB-32" parent="fooONwX62kx8ZsJYX7d8-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="10" vertex="1">
          <mxGeometry height="20" width="20" x="854" y="890" as="geometry" />
        </mxCell>
        <UserObject label="Selecciona &quot;Edificio T-3 - Facultad de Ingenieria&quot;" mermaidId="e:Usuario-&gt;UI#1" mermaidBaseStyle="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="Selecciona &quot;Edificio T-3 - Facultad de Ingenieria&quot;" id="WUgnBUTgcxEe0jBnYhTB-33">
          <mxCell edge="1" parent="fooONwX62kx8ZsJYX7d8-0" source="WUgnBUTgcxEe0jBnYhTB-2" style="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="WUgnBUTgcxEe0jBnYhTB-3">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="284" y="944" />
              </Array>
              <mxPoint x="85" y="944" as="sourcePoint" />
              <mxPoint x="482" y="944" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="WUgnBUTgcxEe0jBnYhTB-34" parent="fooONwX62kx8ZsJYX7d8-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="11" vertex="1">
          <mxGeometry height="20" width="20" x="75" y="934" as="geometry" />
        </mxCell>
        <UserObject label="selectBuilding(t3Building)" mermaidId="e:UI-&gt;Ctrl#1" mermaidBaseStyle="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="selectBuilding(t3Building)" id="WUgnBUTgcxEe0jBnYhTB-35">
          <mxCell edge="1" parent="fooONwX62kx8ZsJYX7d8-0" source="WUgnBUTgcxEe0jBnYhTB-3" style="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="WUgnBUTgcxEe0jBnYhTB-4">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="673" y="988" />
              </Array>
              <mxPoint x="482" y="988" as="sourcePoint" />
              <mxPoint x="864" y="988" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="WUgnBUTgcxEe0jBnYhTB-36" parent="fooONwX62kx8ZsJYX7d8-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="12" vertex="1">
          <mxGeometry height="20" width="20" x="472" y="978" as="geometry" />
        </mxCell>
        <UserObject label="" mermaidId="e:Ctrl-&gt;Ctrl#0" mermaidBaseStyle="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="" id="WUgnBUTgcxEe0jBnYhTB-37">
          <mxCell edge="1" parent="fooONwX62kx8ZsJYX7d8-0" source="WUgnBUTgcxEe0jBnYhTB-4" style="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="WUgnBUTgcxEe0jBnYhTB-4">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="899" y="1079" />
                <mxPoint x="903" y="1091" />
                <mxPoint x="899" y="1103" />
              </Array>
              <mxPoint x="864" y="1079" as="sourcePoint" />
              <mxPoint x="864" y="1103" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="WUgnBUTgcxEe0jBnYhTB-38" parent="fooONwX62kx8ZsJYX7d8-0" style="text;html=1;strokeColor=none;fillColor=none;align=center;verticalAlign=middle;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;fontColor=light-dark(#333333,#cccccc);" value="Actualizar selectedBuilding = t3Building" vertex="1">
          <mxGeometry height="18" width="200" x="764" y="1055" as="geometry" />
        </mxCell>
        <mxCell id="WUgnBUTgcxEe0jBnYhTB-39" parent="fooONwX62kx8ZsJYX7d8-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="13" vertex="1">
          <mxGeometry height="20" width="20" x="854" y="1069" as="geometry" />
        </mxCell>
        <UserObject label="Mover camara al centroide de T-3 con animacion" mermaidId="e:Ctrl-&gt;MapUI#0" mermaidBaseStyle="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="Mover camara al centroide de T-3 con animacion" id="WUgnBUTgcxEe0jBnYhTB-40">
          <mxCell edge="1" parent="fooONwX62kx8ZsJYX7d8-0" source="WUgnBUTgcxEe0jBnYhTB-4" style="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="WUgnBUTgcxEe0jBnYhTB-6">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="1070" y="1153" />
              </Array>
              <mxPoint x="864" y="1153" as="sourcePoint" />
              <mxPoint x="1276" y="1153" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="WUgnBUTgcxEe0jBnYhTB-41" parent="fooONwX62kx8ZsJYX7d8-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="14" vertex="1">
          <mxGeometry height="20" width="20" x="854" y="1143" as="geometry" />
        </mxCell>
        <UserObject label="Mostrar PoiDetailSheet con informacion de T-3" mermaidId="e:Ctrl-&gt;UI#1" mermaidBaseStyle="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="Mostrar PoiDetailSheet con informacion de T-3" id="WUgnBUTgcxEe0jBnYhTB-42">
          <mxCell edge="1" parent="fooONwX62kx8ZsJYX7d8-0" source="WUgnBUTgcxEe0jBnYhTB-4" style="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="WUgnBUTgcxEe0jBnYhTB-3">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="673" y="1197" />
              </Array>
              <mxPoint x="864" y="1197" as="sourcePoint" />
              <mxPoint x="482" y="1197" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="WUgnBUTgcxEe0jBnYhTB-43" parent="fooONwX62kx8ZsJYX7d8-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="15" vertex="1">
          <mxGeometry height="20" width="20" x="854" y="1187" as="geometry" />
        </mxCell>
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>

```
---

### Flujo 5: Cartografia de Interiores (Indoor Mapping)

Explica como se gestiona la conmutacion de niveles en edificios de multiples pisos:

```drawio
<mxfile>
  <diagram id="s-PSKktj7Ii-8_AB4-q8" name="Page-1">
    <mxGraphModel dx="2" dy="1" grid="0" gridSize="10" guides="1" tooltips="0" connect="0" arrows="0" fold="0" page="0" pageScale="1" pageWidth="850" pageHeight="1100" math="0" shadow="0">
      <root>
        <mxCell id="7FWVn6w-uaNkV8hgYGqE-0" />
        <mxCell id="7FWVn6w-uaNkV8hgYGqE-1" parent="7FWVn6w-uaNkV8hgYGqE-0" />
        <UserObject label="" mermaidData="{&#xa;  &quot;data&quot;: &quot;sequenceDiagram\n    autonumber\n    actor Usuario\n    participant Map as MapView\n    participant Ctrl as UsacCampusMapController\n    participant Selector as FloorSelector\n    participant Sheet as PoiDetailSheet\n\n    Usuario-&gt;&gt;Map: Toca el poligono del Edificio T-3\n    Map-&gt;&gt;Ctrl: onBuildingTapped(t3Building)\n    activate Ctrl\n\n    Ctrl-&gt;&gt;Ctrl: selectedBuilding = t3Building\n    Ctrl-&gt;&gt;Ctrl: Verificar si t3Building.hasIndoorData (3 niveles)\n    Ctrl-&gt;&gt;Ctrl: selectedFloor = 1 (Nivel predeterminado)\n    Ctrl--&gt;&gt;Selector: Activar selector visible con pisos [1, 2, 3]\n    Ctrl--&gt;&gt;Sheet: Mostrar informacion institucional de T-3\n    deactivate Ctrl\n\n    Usuario-&gt;&gt;Selector: Selecciona \&quot;Nivel 2\&quot;\n    Selector-&gt;&gt;Ctrl: selectFloor(2)\n    activate Ctrl\n    Ctrl-&gt;&gt;Ctrl: selectedFloor = 2\n    Ctrl-&gt;&gt;Map: Filtrar POIs y aulas visibles al nivel 2 (Laboratorios de Computo)\n    Ctrl--&gt;&gt;Map: Redibujar capa interior con la distribucion del Nivel 2\n    deactivate Ctrl&quot;,&#xa;  &quot;config&quot;: null&#xa;}" id="GP0c6iqeVVshaMqxLdUi-0">
          <mxCell connectable="0" parent="7FWVn6w-uaNkV8hgYGqE-1" style="group;transparentBounds=1;editIcon=1;lockedGroup=0;groupPadding=10;" vertex="1">
            <mxGeometry as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="Usuario" mermaidId="n:Usuario" mermaidBaseStyle="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);participant=seqActorStick;verticalAlign=bottom;align=center;spacingBottom=4;size=90;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="Usuario" id="7FWVn6w-uaNkV8hgYGqE-2">
          <mxCell parent="GP0c6iqeVVshaMqxLdUi-0" style="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);participant=seqActorStick;verticalAlign=bottom;align=center;spacingBottom=4;size=90;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="994" width="150" x="10" y="10" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="MapView" mermaidId="n:Map" mermaidBaseStyle="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="MapView" id="7FWVn6w-uaNkV8hgYGqE-3">
          <mxCell parent="GP0c6iqeVVshaMqxLdUi-0" style="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="969" width="150" x="288" y="10" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="UsacCampusMapController" mermaidId="n:Ctrl" mermaidBaseStyle="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="UsacCampusMapController" id="7FWVn6w-uaNkV8hgYGqE-4">
          <mxCell parent="GP0c6iqeVVshaMqxLdUi-0" style="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="969" width="150" x="798" y="10" as="geometry" />
          </mxCell>
        </UserObject>
        <mxCell id="7FWVn6w-uaNkV8hgYGqE-7" parent="7FWVn6w-uaNkV8hgYGqE-4" style="html=1;points=[];perimeter=orthogonalPerimeter;outlineConnect=0;targetShapes=umlLifeline;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};fillColor=light-dark(#f4f4f4,#2a2a2a);strokeColor=light-dark(#666666,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" value="" vertex="1">
          <mxGeometry height="451" width="10" x="70" y="153" as="geometry" />
        </mxCell>
        <mxCell id="7FWVn6w-uaNkV8hgYGqE-8" parent="7FWVn6w-uaNkV8hgYGqE-4" style="html=1;points=[];perimeter=orthogonalPerimeter;outlineConnect=0;targetShapes=umlLifeline;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};fillColor=light-dark(#f4f4f4,#2a2a2a);strokeColor=light-dark(#666666,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" value="" vertex="1">
          <mxGeometry height="192" width="10" x="70" y="692" as="geometry" />
        </mxCell>
        <UserObject label="FloorSelector" mermaidId="n:Selector" mermaidBaseStyle="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="FloorSelector" id="7FWVn6w-uaNkV8hgYGqE-5">
          <mxCell parent="GP0c6iqeVVshaMqxLdUi-0" style="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="969" width="150" x="1145" y="10" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="PoiDetailSheet" mermaidId="n:Sheet" mermaidBaseStyle="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="PoiDetailSheet" id="7FWVn6w-uaNkV8hgYGqE-6">
          <mxCell parent="GP0c6iqeVVshaMqxLdUi-0" style="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="969" width="150" x="1345" y="10" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="Toca el poligono del Edificio T-3" mermaidId="e:Usuario-&gt;Map#0" mermaidBaseStyle="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="Toca el poligono del Edificio T-3" id="7FWVn6w-uaNkV8hgYGqE-9">
          <mxCell edge="1" parent="GP0c6iqeVVshaMqxLdUi-0" source="7FWVn6w-uaNkV8hgYGqE-2" style="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="7FWVn6w-uaNkV8hgYGqE-3">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="224" y="119" />
              </Array>
              <mxPoint x="85" y="119" as="sourcePoint" />
              <mxPoint x="363" y="119" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="7FWVn6w-uaNkV8hgYGqE-10" parent="GP0c6iqeVVshaMqxLdUi-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="1" vertex="1">
          <mxGeometry height="20" width="20" x="75" y="109" as="geometry" />
        </mxCell>
        <UserObject label="onBuildingTapped(t3Building)" mermaidId="e:Map-&gt;Ctrl#0" mermaidBaseStyle="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="onBuildingTapped(t3Building)" id="7FWVn6w-uaNkV8hgYGqE-11">
          <mxCell edge="1" parent="GP0c6iqeVVshaMqxLdUi-0" source="7FWVn6w-uaNkV8hgYGqE-3" style="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="7FWVn6w-uaNkV8hgYGqE-7">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="616" y="163" />
              </Array>
              <mxPoint x="363" y="163" as="sourcePoint" />
              <mxPoint x="868" y="163" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="7FWVn6w-uaNkV8hgYGqE-12" parent="GP0c6iqeVVshaMqxLdUi-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="2" vertex="1">
          <mxGeometry height="20" width="20" x="353" y="153" as="geometry" />
        </mxCell>
        <UserObject label="" mermaidId="e:Ctrl-&gt;Ctrl#0" mermaidBaseStyle="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="" id="7FWVn6w-uaNkV8hgYGqE-13">
          <mxCell edge="1" parent="GP0c6iqeVVshaMqxLdUi-0" source="7FWVn6w-uaNkV8hgYGqE-7" style="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="7FWVn6w-uaNkV8hgYGqE-7">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="913" y="254" />
                <mxPoint x="917" y="266" />
                <mxPoint x="913" y="278" />
              </Array>
              <mxPoint x="878" y="254" as="sourcePoint" />
              <mxPoint x="878" y="278" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="7FWVn6w-uaNkV8hgYGqE-14" parent="GP0c6iqeVVshaMqxLdUi-0" style="text;html=1;strokeColor=none;fillColor=none;align=center;verticalAlign=middle;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;fontColor=light-dark(#333333,#cccccc);" value="selectedBuilding = t3Building" vertex="1">
          <mxGeometry height="18" width="200" x="778" y="230" as="geometry" />
        </mxCell>
        <mxCell id="7FWVn6w-uaNkV8hgYGqE-15" parent="GP0c6iqeVVshaMqxLdUi-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="3" vertex="1">
          <mxGeometry height="20" width="20" x="863" y="244" as="geometry" />
        </mxCell>
        <UserObject label="" mermaidId="e:Ctrl-&gt;Ctrl#1" mermaidBaseStyle="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="" id="7FWVn6w-uaNkV8hgYGqE-16">
          <mxCell edge="1" parent="GP0c6iqeVVshaMqxLdUi-0" source="7FWVn6w-uaNkV8hgYGqE-7" style="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="7FWVn6w-uaNkV8hgYGqE-7">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="913" y="375" />
                <mxPoint x="917" y="387" />
                <mxPoint x="913" y="399" />
              </Array>
              <mxPoint x="878" y="375" as="sourcePoint" />
              <mxPoint x="878" y="399" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="7FWVn6w-uaNkV8hgYGqE-17" parent="GP0c6iqeVVshaMqxLdUi-0" style="text;html=1;strokeColor=none;fillColor=none;align=center;verticalAlign=middle;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;fontColor=light-dark(#333333,#cccccc);" value="Verificar si t3Building.hasIndoorData (3 niveles)" vertex="1">
          <mxGeometry height="18" width="200" x="778" y="351" as="geometry" />
        </mxCell>
        <mxCell id="7FWVn6w-uaNkV8hgYGqE-18" parent="GP0c6iqeVVshaMqxLdUi-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="4" vertex="1">
          <mxGeometry height="20" width="20" x="863" y="365" as="geometry" />
        </mxCell>
        <UserObject label="" mermaidId="e:Ctrl-&gt;Ctrl#2" mermaidBaseStyle="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="" id="7FWVn6w-uaNkV8hgYGqE-19">
          <mxCell edge="1" parent="GP0c6iqeVVshaMqxLdUi-0" source="7FWVn6w-uaNkV8hgYGqE-7" style="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="7FWVn6w-uaNkV8hgYGqE-7">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="913" y="496" />
                <mxPoint x="917" y="508" />
                <mxPoint x="913" y="520" />
              </Array>
              <mxPoint x="878" y="496" as="sourcePoint" />
              <mxPoint x="878" y="520" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="7FWVn6w-uaNkV8hgYGqE-20" parent="GP0c6iqeVVshaMqxLdUi-0" style="text;html=1;strokeColor=none;fillColor=none;align=center;verticalAlign=middle;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;fontColor=light-dark(#333333,#cccccc);" value="selectedFloor = 1 (Nivel predeterminado)" vertex="1">
          <mxGeometry height="18" width="200" x="778" y="472" as="geometry" />
        </mxCell>
        <mxCell id="7FWVn6w-uaNkV8hgYGqE-21" parent="GP0c6iqeVVshaMqxLdUi-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="5" vertex="1">
          <mxGeometry height="20" width="20" x="863" y="486" as="geometry" />
        </mxCell>
        <UserObject label="Activar selector visible con pisos [1, 2, 3]" mermaidId="e:Ctrl-&gt;Selector#0" mermaidBaseStyle="dashed=1;fixDash=1;dashPattern=3 3;endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="Activar selector visible con pisos [1, 2, 3]" id="7FWVn6w-uaNkV8hgYGqE-22">
          <mxCell edge="1" parent="GP0c6iqeVVshaMqxLdUi-0" source="7FWVn6w-uaNkV8hgYGqE-7" style="dashed=1;fixDash=1;dashPattern=3 3;endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="7FWVn6w-uaNkV8hgYGqE-5">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="1049" y="570" />
              </Array>
              <mxPoint x="878" y="570" as="sourcePoint" />
              <mxPoint x="1220" y="570" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="7FWVn6w-uaNkV8hgYGqE-23" parent="GP0c6iqeVVshaMqxLdUi-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="6" vertex="1">
          <mxGeometry height="20" width="20" x="863" y="560" as="geometry" />
        </mxCell>
        <UserObject label="Mostrar informacion institucional de T-3" mermaidId="e:Ctrl-&gt;Sheet#0" mermaidBaseStyle="dashed=1;fixDash=1;dashPattern=3 3;endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="Mostrar informacion institucional de T-3" id="7FWVn6w-uaNkV8hgYGqE-24">
          <mxCell edge="1" parent="GP0c6iqeVVshaMqxLdUi-0" source="7FWVn6w-uaNkV8hgYGqE-7" style="dashed=1;fixDash=1;dashPattern=3 3;endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="7FWVn6w-uaNkV8hgYGqE-6">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="1149" y="614" />
              </Array>
              <mxPoint x="878" y="614" as="sourcePoint" />
              <mxPoint x="1420" y="614" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="7FWVn6w-uaNkV8hgYGqE-25" parent="GP0c6iqeVVshaMqxLdUi-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="7" vertex="1">
          <mxGeometry height="20" width="20" x="863" y="604" as="geometry" />
        </mxCell>
        <UserObject label="Selecciona &quot;Nivel 2&quot;" mermaidId="e:Usuario-&gt;Selector#0" mermaidBaseStyle="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="Selecciona &quot;Nivel 2&quot;" id="7FWVn6w-uaNkV8hgYGqE-26">
          <mxCell edge="1" parent="GP0c6iqeVVshaMqxLdUi-0" source="7FWVn6w-uaNkV8hgYGqE-2" style="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="7FWVn6w-uaNkV8hgYGqE-5">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="653" y="658" />
              </Array>
              <mxPoint x="85" y="658" as="sourcePoint" />
              <mxPoint x="1220" y="658" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="7FWVn6w-uaNkV8hgYGqE-27" parent="GP0c6iqeVVshaMqxLdUi-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="8" vertex="1">
          <mxGeometry height="20" width="20" x="75" y="648" as="geometry" />
        </mxCell>
        <UserObject label="selectFloor(2)" mermaidId="e:Selector-&gt;Ctrl#0" mermaidBaseStyle="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="selectFloor(2)" id="7FWVn6w-uaNkV8hgYGqE-28">
          <mxCell edge="1" parent="GP0c6iqeVVshaMqxLdUi-0" source="7FWVn6w-uaNkV8hgYGqE-5" style="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="7FWVn6w-uaNkV8hgYGqE-8">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="1049" y="702" />
              </Array>
              <mxPoint x="1220" y="702" as="sourcePoint" />
              <mxPoint x="878" y="702" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="7FWVn6w-uaNkV8hgYGqE-29" parent="GP0c6iqeVVshaMqxLdUi-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="9" vertex="1">
          <mxGeometry height="20" width="20" x="1210" y="692" as="geometry" />
        </mxCell>
        <UserObject label="" mermaidId="e:Ctrl-&gt;Ctrl#3" mermaidBaseStyle="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="" id="7FWVn6w-uaNkV8hgYGqE-30">
          <mxCell edge="1" parent="GP0c6iqeVVshaMqxLdUi-0" source="7FWVn6w-uaNkV8hgYGqE-8" style="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="7FWVn6w-uaNkV8hgYGqE-8">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="913" y="776" />
                <mxPoint x="917" y="788" />
                <mxPoint x="913" y="800" />
              </Array>
              <mxPoint x="878" y="776" as="sourcePoint" />
              <mxPoint x="878" y="800" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="7FWVn6w-uaNkV8hgYGqE-31" parent="GP0c6iqeVVshaMqxLdUi-0" style="text;html=1;strokeColor=none;fillColor=none;align=center;verticalAlign=middle;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;fontColor=light-dark(#333333,#cccccc);" value="selectedFloor = 2" vertex="1">
          <mxGeometry height="18" width="200" x="778" y="752" as="geometry" />
        </mxCell>
        <mxCell id="7FWVn6w-uaNkV8hgYGqE-32" parent="GP0c6iqeVVshaMqxLdUi-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="10" vertex="1">
          <mxGeometry height="20" width="20" x="863" y="766" as="geometry" />
        </mxCell>
        <UserObject label="Filtrar POIs y aulas visibles al nivel 2 (Laboratorios de Computo)" mermaidId="e:Ctrl-&gt;Map#0" mermaidBaseStyle="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="Filtrar POIs y aulas visibles al nivel 2 (Laboratorios de Computo)" id="7FWVn6w-uaNkV8hgYGqE-33">
          <mxCell edge="1" parent="GP0c6iqeVVshaMqxLdUi-0" source="7FWVn6w-uaNkV8hgYGqE-8" style="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="7FWVn6w-uaNkV8hgYGqE-3">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="616" y="850" />
              </Array>
              <mxPoint x="868" y="850" as="sourcePoint" />
              <mxPoint x="363" y="850" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="7FWVn6w-uaNkV8hgYGqE-34" parent="GP0c6iqeVVshaMqxLdUi-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="11" vertex="1">
          <mxGeometry height="20" width="20" x="863" y="840" as="geometry" />
        </mxCell>
        <UserObject label="Redibujar capa interior con la distribucion del Nivel 2" mermaidId="e:Ctrl-&gt;Map#1" mermaidBaseStyle="dashed=1;fixDash=1;dashPattern=3 3;endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="Redibujar capa interior con la distribucion del Nivel 2" id="7FWVn6w-uaNkV8hgYGqE-35">
          <mxCell edge="1" parent="GP0c6iqeVVshaMqxLdUi-0" source="7FWVn6w-uaNkV8hgYGqE-8" style="dashed=1;fixDash=1;dashPattern=3 3;endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="7FWVn6w-uaNkV8hgYGqE-3">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="616" y="894" />
              </Array>
              <mxPoint x="868" y="894" as="sourcePoint" />
              <mxPoint x="363" y="894" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="7FWVn6w-uaNkV8hgYGqE-36" parent="GP0c6iqeVVshaMqxLdUi-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="12" vertex="1">
          <mxGeometry height="20" width="20" x="863" y="884" as="geometry" />
        </mxCell>
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>

```
---

## Diagrama de Clases y Dominio

Estructura de entidades y tipos de datos del paquete:

```drawio
<mxfile>
  <diagram id="g1Y6qGiwnqDZhVMeX6Ma" name="Page-1">
    <mxGraphModel dx="2" dy="1" grid="0" gridSize="10" guides="1" tooltips="0" connect="0" arrows="0" fold="0" page="0" pageScale="1" pageWidth="850" pageHeight="1100" math="0" shadow="0">
      <root>
        <mxCell id="ccdg8dRkxmDzWLiZokrG-0" />
        <mxCell id="ccdg8dRkxmDzWLiZokrG-1" parent="ccdg8dRkxmDzWLiZokrG-0" />
        <UserObject label="" mermaidData="{&#xa;  &quot;data&quot;: &quot;sequenceDiagram\n    autonumber\n    actor Usuario\n    participant UI as Interfaz de Usuario\n    participant Ctrl as UsacCampusMapController\n    participant RouteEng as RouteEngine\n    participant Snap as SnapToPath\n    participant AStar as AStarNavigator\n    participant MapUI as MapView\n\n    Usuario-&gt;&gt;UI: Solicita ruta: Origen (Garita Periferico) -&gt; Destino (T-3)\n    UI-&gt;&gt;Ctrl: calculateRoute(origen, destino, NavigationMode.pedestrian)\n    activate Ctrl\n\n    Ctrl-&gt;&gt;RouteEng: planRoute(origen, destino, mode: pedestrian)\n    activate RouteEng\n\n    RouteEng-&gt;&gt;Snap: findNearestNode(origen, graph)\n    Snap--&gt;&gt;RouteEng: Nodo Inicial (nodo_garita_periferico)\n\n    RouteEng-&gt;&gt;Snap: findNearestNode(destino, graph)\n    Snap--&gt;&gt;RouteEng: Nodo Final (nodo_t3_acceso)\n\n    RouteEng-&gt;&gt;AStar: findPath(startNode, endNode, mode, graph)\n    activate AStar\n\n    AStar-&gt;&gt;AStar: Inicializar cola de prioridad con startNode (costo = 0)\n    loop Mientras la cola no este vacia\n        AStar-&gt;&gt;AStar: Extraer nodo actual con menor fScore (gScore + heuristica)\n        alt Nodo actual es endNode\n            AStar-&gt;&gt;AStar: Reconstruir ruta enlazando predecesores\n        else Explorar vecinos\n            AStar-&gt;&gt;AStar: Filtrar aristas compatibles con NavigationMode\n            AStar-&gt;&gt;AStar: Evaluar si nuevo gScore es menor al registrado\n            AStar-&gt;&gt;AStar: Actualizar mejor costo e insertar vecino en cola\n        end\n    end\n    AStar--&gt;&gt;RouteEng: List&lt;CampusNode&gt; (secuencia optima)\n    deactivate AStar\n\n    RouteEng-&gt;&gt;RouteEng: Generar polilinea completa (List&lt;LatLng&gt;)\n    RouteEng-&gt;&gt;RouteEng: Calcular distancia acumulada y tiempo estimado\n    RouteEng-&gt;&gt;RouteEng: Generar instrucciones paso a paso\n    RouteEng--&gt;&gt;Ctrl: CampusRoute construida\n    deactivate RouteEng\n\n    Ctrl-&gt;&gt;Ctrl: Notificar nuevo estado: activeRoute = ruta\n    Ctrl-&gt;&gt;MapUI: Dibujar PolylineLayer sobre el mapa\n    Ctrl-&gt;&gt;UI: Desplegar TurnByTurnBanner con primera instruccion\n    deactivate Ctrl&quot;,&#xa;  &quot;config&quot;: null&#xa;}" id="-ZPzY6BomA9m1LeNq2AM-0">
          <mxCell connectable="0" parent="ccdg8dRkxmDzWLiZokrG-1" style="group;transparentBounds=1;editIcon=1;lockedGroup=0;groupPadding=10;" vertex="1">
            <mxGeometry as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="Usuario" mermaidId="n:Usuario" mermaidBaseStyle="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);participant=seqActorStick;verticalAlign=bottom;align=center;spacingBottom=4;size=90;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="Usuario" id="ccdg8dRkxmDzWLiZokrG-2">
          <mxCell parent="-ZPzY6BomA9m1LeNq2AM-0" style="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);participant=seqActorStick;verticalAlign=bottom;align=center;spacingBottom=4;size=90;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="2098" width="150" x="10" y="10" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="Interfaz de Usuario" mermaidId="n:UI" mermaidBaseStyle="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="Interfaz de Usuario" id="ccdg8dRkxmDzWLiZokrG-3">
          <mxCell parent="-ZPzY6BomA9m1LeNq2AM-0" style="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="2073" width="150" x="457" y="10" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="UsacCampusMapController" mermaidId="n:Ctrl" mermaidBaseStyle="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="UsacCampusMapController" id="ccdg8dRkxmDzWLiZokrG-4">
          <mxCell parent="-ZPzY6BomA9m1LeNq2AM-0" style="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="2073" width="150" x="940" y="10" as="geometry" />
          </mxCell>
        </UserObject>
        <mxCell id="ccdg8dRkxmDzWLiZokrG-17" parent="ccdg8dRkxmDzWLiZokrG-4" style="html=1;points=[];perimeter=orthogonalPerimeter;outlineConnect=0;targetShapes=umlLifeline;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};fillColor=light-dark(#f4f4f4,#2a2a2a);strokeColor=light-dark(#666666,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" value="" vertex="1">
          <mxGeometry height="1835" width="10" x="70" y="153" as="geometry" />
        </mxCell>
        <UserObject label="RouteEngine" mermaidId="n:RouteEng" mermaidBaseStyle="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="RouteEngine" id="ccdg8dRkxmDzWLiZokrG-5">
          <mxCell parent="-ZPzY6BomA9m1LeNq2AM-0" style="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="2073" width="150" x="1318" y="10" as="geometry" />
          </mxCell>
        </UserObject>
        <mxCell id="ccdg8dRkxmDzWLiZokrG-16" parent="ccdg8dRkxmDzWLiZokrG-5" style="html=1;points=[];perimeter=orthogonalPerimeter;outlineConnect=0;targetShapes=umlLifeline;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};fillColor=light-dark(#f4f4f4,#2a2a2a);strokeColor=light-dark(#666666,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" value="" vertex="1">
          <mxGeometry height="1582" width="10" x="70" y="197" as="geometry" />
        </mxCell>
        <UserObject label="SnapToPath" mermaidId="n:Snap" mermaidBaseStyle="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="SnapToPath" id="ccdg8dRkxmDzWLiZokrG-6">
          <mxCell parent="-ZPzY6BomA9m1LeNq2AM-0" style="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="2073" width="150" x="1633" y="10" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="AStarNavigator" mermaidId="n:AStar" mermaidBaseStyle="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="AStarNavigator" id="ccdg8dRkxmDzWLiZokrG-7">
          <mxCell parent="-ZPzY6BomA9m1LeNq2AM-0" style="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="2073" width="150" x="1833" y="10" as="geometry" />
          </mxCell>
        </UserObject>
        <mxCell id="ccdg8dRkxmDzWLiZokrG-15" parent="ccdg8dRkxmDzWLiZokrG-7" style="html=1;points=[];perimeter=orthogonalPerimeter;outlineConnect=0;targetShapes=umlLifeline;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};fillColor=light-dark(#f4f4f4,#2a2a2a);strokeColor=light-dark(#666666,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" value="" vertex="1">
          <mxGeometry height="955" width="10" x="70" y="417" as="geometry" />
        </mxCell>
        <UserObject label="MapView" mermaidId="n:MapUI" mermaidBaseStyle="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="MapView" id="ccdg8dRkxmDzWLiZokrG-8">
          <mxCell parent="-ZPzY6BomA9m1LeNq2AM-0" style="html=1;shape=umlLifeline;perimeter=lifelinePerimeter;whiteSpace=wrap;container=1;dropTarget=0;collapsible=0;recursiveResize=0;outlineConnect=0;portConstraint=eastwest;newEdgeStyle={&quot;edgeStyle&quot;:&quot;elbowEdgeStyle&quot;,&quot;elbow&quot;:&quot;vertical&quot;,&quot;curved&quot;:0,&quot;rounded&quot;:0};lifelineDashed=0;strokeWidth=2;rounded=1;absoluteArcSize=1;arcSize=6;lifelineColor=light-dark(#9370DB,#cccccc);size=65;lifelineMirror=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="2073" width="150" x="2033" y="10" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="loop" mermaidId="n:f0" mermaidBaseStyle="html=1;shape=umlFrame;dashed=1;fixDash=1;dashPattern=2 2;strokeWidth=2;pointerEvents=0;dropTarget=0;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontSize=16;align=center;verticalAlign=middle;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);height=20;width=50;" mermaidBaseValue="loop" id="ccdg8dRkxmDzWLiZokrG-9">
          <mxCell parent="-ZPzY6BomA9m1LeNq2AM-0" style="html=1;shape=umlFrame;dashed=1;fixDash=1;dashPattern=2 2;strokeWidth=2;pointerEvents=0;dropTarget=0;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontSize=16;align=center;verticalAlign=middle;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);height=20;width=50;" vertex="1">
            <mxGeometry height="736" width="200" x="1808" y="622" as="geometry" />
          </mxCell>
        </UserObject>
        <mxCell id="ccdg8dRkxmDzWLiZokrG-10" parent="ccdg8dRkxmDzWLiZokrG-9" style="text;strokeColor=none;fillColor=none;align=center;verticalAlign=middle;whiteSpace=wrap;fontSize=16;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);" value="[Mientras la cola no este vacia]" vertex="1">
          <mxGeometry height="32" width="146" x="54" y="2" as="geometry" />
        </mxCell>
        <UserObject label="alt" mermaidId="n:f1" mermaidBaseStyle="html=1;shape=umlFrame;dashed=1;fixDash=1;dashPattern=2 2;strokeWidth=2;pointerEvents=0;dropTarget=0;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontSize=16;align=center;verticalAlign=middle;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);height=20;width=50;" mermaidBaseValue="alt" id="ccdg8dRkxmDzWLiZokrG-11">
          <mxCell parent="-ZPzY6BomA9m1LeNq2AM-0" style="html=1;shape=umlFrame;dashed=1;fixDash=1;dashPattern=2 2;strokeWidth=2;pointerEvents=0;dropTarget=0;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontSize=16;align=center;verticalAlign=middle;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);height=20;width=50;" vertex="1">
            <mxGeometry height="544" width="180" x="1818" y="794" as="geometry" />
          </mxCell>
        </UserObject>
        <mxCell id="ccdg8dRkxmDzWLiZokrG-12" parent="ccdg8dRkxmDzWLiZokrG-11" style="text;strokeColor=none;fillColor=none;align=center;verticalAlign=middle;whiteSpace=wrap;fontSize=16;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);" value="[Nodo actual es endNode]" vertex="1">
          <mxGeometry height="32" width="126" x="54" y="2" as="geometry" />
        </mxCell>
        <mxCell id="ccdg8dRkxmDzWLiZokrG-13" parent="ccdg8dRkxmDzWLiZokrG-11" style="shape=line;dashed=1;fixDash=1;dashPattern=2 2;strokeColor=light-dark(#9370DB,#cccccc);" vertex="1">
          <mxGeometry height="1" width="180" y="198" as="geometry" />
        </mxCell>
        <mxCell id="ccdg8dRkxmDzWLiZokrG-14" parent="ccdg8dRkxmDzWLiZokrG-11" style="text;strokeColor=none;fillColor=none;align=center;verticalAlign=middle;whiteSpace=wrap;fontSize=16;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);" value="[Explorar vecinos]" vertex="1">
          <mxGeometry height="16" width="180" y="200" as="geometry" />
        </mxCell>
        <UserObject label="Solicita ruta: Origen (Garita Periferico) -&gt; Destino (T-3)" mermaidId="e:Usuario-&gt;UI#0" mermaidBaseStyle="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="Solicita ruta: Origen (Garita Periferico) -&gt; Destino (T-3)" id="ccdg8dRkxmDzWLiZokrG-18">
          <mxCell edge="1" parent="-ZPzY6BomA9m1LeNq2AM-0" source="ccdg8dRkxmDzWLiZokrG-2" style="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="ccdg8dRkxmDzWLiZokrG-3">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="309" y="119" />
              </Array>
              <mxPoint x="85" y="119" as="sourcePoint" />
              <mxPoint x="532" y="119" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="ccdg8dRkxmDzWLiZokrG-19" parent="-ZPzY6BomA9m1LeNq2AM-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="1" vertex="1">
          <mxGeometry height="20" width="20" x="75" y="109" as="geometry" />
        </mxCell>
        <UserObject label="calculateRoute(origen, destino, NavigationMode.pedestrian)" mermaidId="e:UI-&gt;Ctrl#0" mermaidBaseStyle="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="calculateRoute(origen, destino, NavigationMode.pedestrian)" id="ccdg8dRkxmDzWLiZokrG-20">
          <mxCell edge="1" parent="-ZPzY6BomA9m1LeNq2AM-0" source="ccdg8dRkxmDzWLiZokrG-3" style="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="ccdg8dRkxmDzWLiZokrG-17">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="771" y="163" />
              </Array>
              <mxPoint x="532" y="163" as="sourcePoint" />
              <mxPoint x="1010" y="163" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="ccdg8dRkxmDzWLiZokrG-21" parent="-ZPzY6BomA9m1LeNq2AM-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="2" vertex="1">
          <mxGeometry height="20" width="20" x="522" y="153" as="geometry" />
        </mxCell>
        <UserObject label="planRoute(origen, destino, mode: pedestrian)" mermaidId="e:Ctrl-&gt;RouteEng#0" mermaidBaseStyle="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="planRoute(origen, destino, mode: pedestrian)" id="ccdg8dRkxmDzWLiZokrG-22">
          <mxCell edge="1" parent="-ZPzY6BomA9m1LeNq2AM-0" source="ccdg8dRkxmDzWLiZokrG-17" style="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="ccdg8dRkxmDzWLiZokrG-16">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="1204" y="207" />
              </Array>
              <mxPoint x="1020" y="207" as="sourcePoint" />
              <mxPoint x="1388" y="207" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="ccdg8dRkxmDzWLiZokrG-23" parent="-ZPzY6BomA9m1LeNq2AM-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="3" vertex="1">
          <mxGeometry height="20" width="20" x="1005" y="197" as="geometry" />
        </mxCell>
        <UserObject label="findNearestNode(origen, graph)" mermaidId="e:RouteEng-&gt;Snap#0" mermaidBaseStyle="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="findNearestNode(origen, graph)" id="ccdg8dRkxmDzWLiZokrG-24">
          <mxCell edge="1" parent="-ZPzY6BomA9m1LeNq2AM-0" source="ccdg8dRkxmDzWLiZokrG-16" style="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="ccdg8dRkxmDzWLiZokrG-6">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="1553" y="251" />
              </Array>
              <mxPoint x="1398" y="251" as="sourcePoint" />
              <mxPoint x="1708" y="251" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="ccdg8dRkxmDzWLiZokrG-25" parent="-ZPzY6BomA9m1LeNq2AM-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="4" vertex="1">
          <mxGeometry height="20" width="20" x="1383" y="241" as="geometry" />
        </mxCell>
        <UserObject label="Nodo Inicial (nodo_garita_periferico)" mermaidId="e:Snap-&gt;RouteEng#0" mermaidBaseStyle="dashed=1;fixDash=1;dashPattern=3 3;endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="Nodo Inicial (nodo_garita_periferico)" id="ccdg8dRkxmDzWLiZokrG-26">
          <mxCell edge="1" parent="-ZPzY6BomA9m1LeNq2AM-0" source="ccdg8dRkxmDzWLiZokrG-6" style="dashed=1;fixDash=1;dashPattern=3 3;endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="ccdg8dRkxmDzWLiZokrG-16">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="1553" y="295" />
              </Array>
              <mxPoint x="1708" y="295" as="sourcePoint" />
              <mxPoint x="1398" y="295" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="ccdg8dRkxmDzWLiZokrG-27" parent="-ZPzY6BomA9m1LeNq2AM-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="5" vertex="1">
          <mxGeometry height="20" width="20" x="1698" y="285" as="geometry" />
        </mxCell>
        <UserObject label="findNearestNode(destino, graph)" mermaidId="e:RouteEng-&gt;Snap#1" mermaidBaseStyle="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="findNearestNode(destino, graph)" id="ccdg8dRkxmDzWLiZokrG-28">
          <mxCell edge="1" parent="-ZPzY6BomA9m1LeNq2AM-0" source="ccdg8dRkxmDzWLiZokrG-16" style="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="ccdg8dRkxmDzWLiZokrG-6">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="1553" y="339" />
              </Array>
              <mxPoint x="1398" y="339" as="sourcePoint" />
              <mxPoint x="1708" y="339" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="ccdg8dRkxmDzWLiZokrG-29" parent="-ZPzY6BomA9m1LeNq2AM-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="6" vertex="1">
          <mxGeometry height="20" width="20" x="1383" y="329" as="geometry" />
        </mxCell>
        <UserObject label="Nodo Final (nodo_t3_acceso)" mermaidId="e:Snap-&gt;RouteEng#1" mermaidBaseStyle="dashed=1;fixDash=1;dashPattern=3 3;endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="Nodo Final (nodo_t3_acceso)" id="ccdg8dRkxmDzWLiZokrG-30">
          <mxCell edge="1" parent="-ZPzY6BomA9m1LeNq2AM-0" source="ccdg8dRkxmDzWLiZokrG-6" style="dashed=1;fixDash=1;dashPattern=3 3;endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="ccdg8dRkxmDzWLiZokrG-16">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="1553" y="383" />
              </Array>
              <mxPoint x="1708" y="383" as="sourcePoint" />
              <mxPoint x="1398" y="383" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="ccdg8dRkxmDzWLiZokrG-31" parent="-ZPzY6BomA9m1LeNq2AM-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="7" vertex="1">
          <mxGeometry height="20" width="20" x="1698" y="373" as="geometry" />
        </mxCell>
        <UserObject label="findPath(startNode, endNode, mode, graph)" mermaidId="e:RouteEng-&gt;AStar#0" mermaidBaseStyle="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="findPath(startNode, endNode, mode, graph)" id="ccdg8dRkxmDzWLiZokrG-32">
          <mxCell edge="1" parent="-ZPzY6BomA9m1LeNq2AM-0" source="ccdg8dRkxmDzWLiZokrG-16" style="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="ccdg8dRkxmDzWLiZokrG-15">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="1651" y="427" />
              </Array>
              <mxPoint x="1398" y="427" as="sourcePoint" />
              <mxPoint x="1903" y="427" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="ccdg8dRkxmDzWLiZokrG-33" parent="-ZPzY6BomA9m1LeNq2AM-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="8" vertex="1">
          <mxGeometry height="20" width="20" x="1383" y="417" as="geometry" />
        </mxCell>
        <UserObject label="" mermaidId="e:AStar-&gt;AStar#0" mermaidBaseStyle="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="" id="ccdg8dRkxmDzWLiZokrG-34">
          <mxCell edge="1" parent="-ZPzY6BomA9m1LeNq2AM-0" source="ccdg8dRkxmDzWLiZokrG-15" style="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="ccdg8dRkxmDzWLiZokrG-15">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="1948" y="518" />
                <mxPoint x="1952" y="530" />
                <mxPoint x="1948" y="542" />
              </Array>
              <mxPoint x="1913" y="518" as="sourcePoint" />
              <mxPoint x="1913" y="542" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="ccdg8dRkxmDzWLiZokrG-35" parent="-ZPzY6BomA9m1LeNq2AM-0" style="text;html=1;strokeColor=none;fillColor=none;align=center;verticalAlign=middle;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;fontColor=light-dark(#333333,#cccccc);" value="Inicializar cola de prioridad con startNode (costo = 0)" vertex="1">
          <mxGeometry height="18" width="200" x="1813" y="494" as="geometry" />
        </mxCell>
        <mxCell id="ccdg8dRkxmDzWLiZokrG-36" parent="-ZPzY6BomA9m1LeNq2AM-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="9" vertex="1">
          <mxGeometry height="20" width="20" x="1898" y="508" as="geometry" />
        </mxCell>
        <UserObject label="" mermaidId="e:AStar-&gt;AStar#1" mermaidBaseStyle="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="" id="ccdg8dRkxmDzWLiZokrG-37">
          <mxCell edge="1" parent="-ZPzY6BomA9m1LeNq2AM-0" source="ccdg8dRkxmDzWLiZokrG-15" style="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="ccdg8dRkxmDzWLiZokrG-15">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="1948" y="697" />
                <mxPoint x="1952" y="709" />
                <mxPoint x="1948" y="721" />
              </Array>
              <mxPoint x="1913" y="697" as="sourcePoint" />
              <mxPoint x="1913" y="721" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="ccdg8dRkxmDzWLiZokrG-38" parent="-ZPzY6BomA9m1LeNq2AM-0" style="text;html=1;strokeColor=none;fillColor=none;align=center;verticalAlign=middle;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;fontColor=light-dark(#333333,#cccccc);" value="Extraer nodo actual con menor fScore (gScore + heuristica)" vertex="1">
          <mxGeometry height="18" width="200" x="1813" y="673" as="geometry" />
        </mxCell>
        <mxCell id="ccdg8dRkxmDzWLiZokrG-39" parent="-ZPzY6BomA9m1LeNq2AM-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="10" vertex="1">
          <mxGeometry height="20" width="20" x="1898" y="687" as="geometry" />
        </mxCell>
        <UserObject label="" mermaidId="e:AStar-&gt;AStar#2" mermaidBaseStyle="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="" id="ccdg8dRkxmDzWLiZokrG-40">
          <mxCell edge="1" parent="-ZPzY6BomA9m1LeNq2AM-0" source="ccdg8dRkxmDzWLiZokrG-15" style="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="ccdg8dRkxmDzWLiZokrG-15">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="1948" y="869" />
                <mxPoint x="1952" y="881" />
                <mxPoint x="1948" y="893" />
              </Array>
              <mxPoint x="1913" y="869" as="sourcePoint" />
              <mxPoint x="1913" y="893" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="ccdg8dRkxmDzWLiZokrG-41" parent="-ZPzY6BomA9m1LeNq2AM-0" style="text;html=1;strokeColor=none;fillColor=none;align=center;verticalAlign=middle;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;fontColor=light-dark(#333333,#cccccc);" value="Reconstruir ruta enlazando predecesores" vertex="1">
          <mxGeometry height="18" width="200" x="1813" y="845" as="geometry" />
        </mxCell>
        <mxCell id="ccdg8dRkxmDzWLiZokrG-42" parent="-ZPzY6BomA9m1LeNq2AM-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="11" vertex="1">
          <mxGeometry height="20" width="20" x="1898" y="859" as="geometry" />
        </mxCell>
        <UserObject label="" mermaidId="e:AStar-&gt;AStar#3" mermaidBaseStyle="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="" id="ccdg8dRkxmDzWLiZokrG-43">
          <mxCell edge="1" parent="-ZPzY6BomA9m1LeNq2AM-0" source="ccdg8dRkxmDzWLiZokrG-15" style="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="ccdg8dRkxmDzWLiZokrG-15">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="1948" y="1036" />
                <mxPoint x="1952" y="1048" />
                <mxPoint x="1948" y="1060" />
              </Array>
              <mxPoint x="1913" y="1036" as="sourcePoint" />
              <mxPoint x="1913" y="1060" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="ccdg8dRkxmDzWLiZokrG-44" parent="-ZPzY6BomA9m1LeNq2AM-0" style="text;html=1;strokeColor=none;fillColor=none;align=center;verticalAlign=middle;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;fontColor=light-dark(#333333,#cccccc);" value="Filtrar aristas compatibles con NavigationMode" vertex="1">
          <mxGeometry height="18" width="200" x="1813" y="1012" as="geometry" />
        </mxCell>
        <mxCell id="ccdg8dRkxmDzWLiZokrG-45" parent="-ZPzY6BomA9m1LeNq2AM-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="12" vertex="1">
          <mxGeometry height="20" width="20" x="1898" y="1026" as="geometry" />
        </mxCell>
        <UserObject label="" mermaidId="e:AStar-&gt;AStar#4" mermaidBaseStyle="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="" id="ccdg8dRkxmDzWLiZokrG-46">
          <mxCell edge="1" parent="-ZPzY6BomA9m1LeNq2AM-0" source="ccdg8dRkxmDzWLiZokrG-15" style="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="ccdg8dRkxmDzWLiZokrG-15">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="1948" y="1167" />
                <mxPoint x="1952" y="1179" />
                <mxPoint x="1948" y="1191" />
              </Array>
              <mxPoint x="1913" y="1167" as="sourcePoint" />
              <mxPoint x="1913" y="1191" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="ccdg8dRkxmDzWLiZokrG-47" parent="-ZPzY6BomA9m1LeNq2AM-0" style="text;html=1;strokeColor=none;fillColor=none;align=center;verticalAlign=middle;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;fontColor=light-dark(#333333,#cccccc);" value="Evaluar si nuevo gScore es menor al registrado" vertex="1">
          <mxGeometry height="18" width="200" x="1813" y="1143" as="geometry" />
        </mxCell>
        <mxCell id="ccdg8dRkxmDzWLiZokrG-48" parent="-ZPzY6BomA9m1LeNq2AM-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="13" vertex="1">
          <mxGeometry height="20" width="20" x="1898" y="1157" as="geometry" />
        </mxCell>
        <UserObject label="" mermaidId="e:AStar-&gt;AStar#5" mermaidBaseStyle="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="" id="ccdg8dRkxmDzWLiZokrG-49">
          <mxCell edge="1" parent="-ZPzY6BomA9m1LeNq2AM-0" source="ccdg8dRkxmDzWLiZokrG-15" style="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="ccdg8dRkxmDzWLiZokrG-15">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="1948" y="1298" />
                <mxPoint x="1952" y="1310" />
                <mxPoint x="1948" y="1322" />
              </Array>
              <mxPoint x="1913" y="1298" as="sourcePoint" />
              <mxPoint x="1913" y="1322" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="ccdg8dRkxmDzWLiZokrG-50" parent="-ZPzY6BomA9m1LeNq2AM-0" style="text;html=1;strokeColor=none;fillColor=none;align=center;verticalAlign=middle;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;fontColor=light-dark(#333333,#cccccc);" value="Actualizar mejor costo e insertar vecino en cola" vertex="1">
          <mxGeometry height="18" width="200" x="1813" y="1274" as="geometry" />
        </mxCell>
        <mxCell id="ccdg8dRkxmDzWLiZokrG-51" parent="-ZPzY6BomA9m1LeNq2AM-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="14" vertex="1">
          <mxGeometry height="20" width="20" x="1898" y="1288" as="geometry" />
        </mxCell>
        <UserObject label="List&lt;CampusNode&gt; (secuencia optima)" mermaidId="e:AStar-&gt;RouteEng#0" mermaidBaseStyle="dashed=1;fixDash=1;dashPattern=3 3;endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="List&lt;CampusNode&gt; (secuencia optima)" id="ccdg8dRkxmDzWLiZokrG-52">
          <mxCell edge="1" parent="-ZPzY6BomA9m1LeNq2AM-0" source="ccdg8dRkxmDzWLiZokrG-15" style="dashed=1;fixDash=1;dashPattern=3 3;endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="ccdg8dRkxmDzWLiZokrG-16">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="1651" y="1382" />
              </Array>
              <mxPoint x="1903" y="1382" as="sourcePoint" />
              <mxPoint x="1398" y="1382" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="ccdg8dRkxmDzWLiZokrG-53" parent="-ZPzY6BomA9m1LeNq2AM-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="15" vertex="1">
          <mxGeometry height="20" width="20" x="1898" y="1372" as="geometry" />
        </mxCell>
        <UserObject label="" mermaidId="e:RouteEng-&gt;RouteEng#0" mermaidBaseStyle="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="" id="ccdg8dRkxmDzWLiZokrG-54">
          <mxCell edge="1" parent="-ZPzY6BomA9m1LeNq2AM-0" source="ccdg8dRkxmDzWLiZokrG-16" style="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="ccdg8dRkxmDzWLiZokrG-16">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="1433" y="1473" />
                <mxPoint x="1437" y="1485" />
                <mxPoint x="1433" y="1497" />
              </Array>
              <mxPoint x="1398" y="1473" as="sourcePoint" />
              <mxPoint x="1398" y="1497" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="ccdg8dRkxmDzWLiZokrG-55" parent="-ZPzY6BomA9m1LeNq2AM-0" style="text;html=1;strokeColor=none;fillColor=none;align=center;verticalAlign=middle;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;fontColor=light-dark(#333333,#cccccc);" value="Generar polilinea completa (List&lt;LatLng&gt;)" vertex="1">
          <mxGeometry height="18" width="200" x="1298" y="1449" as="geometry" />
        </mxCell>
        <mxCell id="ccdg8dRkxmDzWLiZokrG-56" parent="-ZPzY6BomA9m1LeNq2AM-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="16" vertex="1">
          <mxGeometry height="20" width="20" x="1383" y="1463" as="geometry" />
        </mxCell>
        <UserObject label="" mermaidId="e:RouteEng-&gt;RouteEng#1" mermaidBaseStyle="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="" id="ccdg8dRkxmDzWLiZokrG-57">
          <mxCell edge="1" parent="-ZPzY6BomA9m1LeNq2AM-0" source="ccdg8dRkxmDzWLiZokrG-16" style="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="ccdg8dRkxmDzWLiZokrG-16">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="1433" y="1594" />
                <mxPoint x="1437" y="1606" />
                <mxPoint x="1433" y="1618" />
              </Array>
              <mxPoint x="1398" y="1594" as="sourcePoint" />
              <mxPoint x="1398" y="1618" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="ccdg8dRkxmDzWLiZokrG-58" parent="-ZPzY6BomA9m1LeNq2AM-0" style="text;html=1;strokeColor=none;fillColor=none;align=center;verticalAlign=middle;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;fontColor=light-dark(#333333,#cccccc);" value="Calcular distancia acumulada y tiempo estimado" vertex="1">
          <mxGeometry height="18" width="200" x="1298" y="1570" as="geometry" />
        </mxCell>
        <mxCell id="ccdg8dRkxmDzWLiZokrG-59" parent="-ZPzY6BomA9m1LeNq2AM-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="17" vertex="1">
          <mxGeometry height="20" width="20" x="1383" y="1584" as="geometry" />
        </mxCell>
        <UserObject label="" mermaidId="e:RouteEng-&gt;RouteEng#2" mermaidBaseStyle="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="" id="ccdg8dRkxmDzWLiZokrG-60">
          <mxCell edge="1" parent="-ZPzY6BomA9m1LeNq2AM-0" source="ccdg8dRkxmDzWLiZokrG-16" style="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="ccdg8dRkxmDzWLiZokrG-16">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="1433" y="1715" />
                <mxPoint x="1437" y="1727" />
                <mxPoint x="1433" y="1739" />
              </Array>
              <mxPoint x="1398" y="1715" as="sourcePoint" />
              <mxPoint x="1398" y="1739" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="ccdg8dRkxmDzWLiZokrG-61" parent="-ZPzY6BomA9m1LeNq2AM-0" style="text;html=1;strokeColor=none;fillColor=none;align=center;verticalAlign=middle;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;fontColor=light-dark(#333333,#cccccc);" value="Generar instrucciones paso a paso" vertex="1">
          <mxGeometry height="18" width="200" x="1298" y="1691" as="geometry" />
        </mxCell>
        <mxCell id="ccdg8dRkxmDzWLiZokrG-62" parent="-ZPzY6BomA9m1LeNq2AM-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="18" vertex="1">
          <mxGeometry height="20" width="20" x="1383" y="1705" as="geometry" />
        </mxCell>
        <UserObject label="CampusRoute construida" mermaidId="e:RouteEng-&gt;Ctrl#0" mermaidBaseStyle="dashed=1;fixDash=1;dashPattern=3 3;endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="CampusRoute construida" id="ccdg8dRkxmDzWLiZokrG-63">
          <mxCell edge="1" parent="-ZPzY6BomA9m1LeNq2AM-0" source="ccdg8dRkxmDzWLiZokrG-16" style="dashed=1;fixDash=1;dashPattern=3 3;endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="ccdg8dRkxmDzWLiZokrG-17">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="1204" y="1789" />
              </Array>
              <mxPoint x="1388" y="1789" as="sourcePoint" />
              <mxPoint x="1020" y="1789" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="ccdg8dRkxmDzWLiZokrG-64" parent="-ZPzY6BomA9m1LeNq2AM-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="19" vertex="1">
          <mxGeometry height="20" width="20" x="1383" y="1779" as="geometry" />
        </mxCell>
        <UserObject label="" mermaidId="e:Ctrl-&gt;Ctrl#0" mermaidBaseStyle="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="" id="ccdg8dRkxmDzWLiZokrG-65">
          <mxCell edge="1" parent="-ZPzY6BomA9m1LeNq2AM-0" source="ccdg8dRkxmDzWLiZokrG-17" style="edgeStyle=none;curved=1;endArrow=block;endSize=9;verticalAlign=bottom;align=center;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="ccdg8dRkxmDzWLiZokrG-17">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="1055" y="1880" />
                <mxPoint x="1059" y="1892" />
                <mxPoint x="1055" y="1904" />
              </Array>
              <mxPoint x="1020" y="1880" as="sourcePoint" />
              <mxPoint x="1020" y="1904" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="ccdg8dRkxmDzWLiZokrG-66" parent="-ZPzY6BomA9m1LeNq2AM-0" style="text;html=1;strokeColor=none;fillColor=none;align=center;verticalAlign=middle;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;fontColor=light-dark(#333333,#cccccc);" value="Notificar nuevo estado: activeRoute = ruta" vertex="1">
          <mxGeometry height="18" width="200" x="920" y="1856" as="geometry" />
        </mxCell>
        <mxCell id="ccdg8dRkxmDzWLiZokrG-67" parent="-ZPzY6BomA9m1LeNq2AM-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="20" vertex="1">
          <mxGeometry height="20" width="20" x="1005" y="1870" as="geometry" />
        </mxCell>
        <UserObject label="Dibujar PolylineLayer sobre el mapa" mermaidId="e:Ctrl-&gt;MapUI#0" mermaidBaseStyle="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="Dibujar PolylineLayer sobre el mapa" id="ccdg8dRkxmDzWLiZokrG-68">
          <mxCell edge="1" parent="-ZPzY6BomA9m1LeNq2AM-0" source="ccdg8dRkxmDzWLiZokrG-17" style="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="ccdg8dRkxmDzWLiZokrG-8">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="1564" y="1954" />
              </Array>
              <mxPoint x="1020" y="1954" as="sourcePoint" />
              <mxPoint x="2108" y="1954" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="ccdg8dRkxmDzWLiZokrG-69" parent="-ZPzY6BomA9m1LeNq2AM-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="21" vertex="1">
          <mxGeometry height="20" width="20" x="1005" y="1944" as="geometry" />
        </mxCell>
        <UserObject label="Desplegar TurnByTurnBanner con primera instruccion" mermaidId="e:Ctrl-&gt;UI#0" mermaidBaseStyle="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" mermaidBaseValue="Desplegar TurnByTurnBanner con primera instruccion" id="ccdg8dRkxmDzWLiZokrG-70">
          <mxCell edge="1" parent="-ZPzY6BomA9m1LeNq2AM-0" source="ccdg8dRkxmDzWLiZokrG-17" style="endArrow=block;endSize=9;verticalAlign=bottom;edgeStyle=elbowEdgeStyle;elbow=vertical;curved=0;rounded=0;fontSize=16;labelBackgroundColor=none;strokeWidth=1.5;strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;" target="ccdg8dRkxmDzWLiZokrG-3">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="771" y="1998" />
              </Array>
              <mxPoint x="1010" y="1998" as="sourcePoint" />
              <mxPoint x="532" y="1998" as="targetPoint" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <mxCell id="ccdg8dRkxmDzWLiZokrG-71" parent="-ZPzY6BomA9m1LeNq2AM-0" style="ellipse;aspect=fixed;fillColor=light-dark(#333333,#cccccc);align=center;verticalAlign=middle;fontColor=light-dark(#FFFFFF,#333333);fontSize=12;" value="22" vertex="1">
          <mxGeometry height="20" width="20" x="1005" y="1988" as="geometry" />
        </mxCell>
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>

```
---

## Maquina de Estados del Controlador

El `UsacCampusMapController` gestiona el ciclo de vida del mapa y las transiciones entre modos de exploracion y navegacion:

```drawio
<mxfile>
  <diagram id="U7NBL7lB_EGaC2tsEFz6" name="Page-1">
    <mxGraphModel dx="2" dy="1" grid="0" gridSize="10" guides="1" tooltips="0" connect="0" arrows="0" fold="0" page="0" pageScale="1" pageWidth="850" pageHeight="1100" math="0" shadow="0">
      <root>
        <mxCell id="8O_1LrPOFjY7Xs-Moz61-0" />
        <mxCell id="8O_1LrPOFjY7Xs-Moz61-1" parent="8O_1LrPOFjY7Xs-Moz61-0" />
        <UserObject label="" mermaidData="{&#xa;  &quot;data&quot;: &quot;stateDiagram-v2\n    [*] --&gt; Idle : Datos cargados\n\n    state Idle {\n        [*] --&gt; BrowsingMap\n        BrowsingMap --&gt; BuildingSelected : Tap en poligono\n        BuildingSelected --&gt; BrowsingMap : Tap en espacio vacio\n        BuildingSelected --&gt; FloorSelected : Cambiar nivel (Indoor)\n        FloorSelected --&gt; BuildingSelected : Cerrar selector\n        BrowsingMap --&gt; PoiSelected : Tap en marcador\n        PoiSelected --&gt; BrowsingMap : Deseleccionar POI\n    }\n\n    Idle --&gt; RoutePlanning : calculateRoute(...)\n    \n    state RoutePlanning {\n        [*] --&gt; CalculatingPath\n        CalculatingPath --&gt; RouteReady : Ruta valida encontrada\n        CalculatingPath --&gt; RouteError : Sin conexion en grafo\n        RouteError --&gt; [*] : Reintentar o cancelar\n    }\n\n    RouteReady --&gt; Navigating : Iniciar seguimiento GPS\n    \n    state Navigating {\n        [*] --&gt; OnTrack\n        OnTrack --&gt; AdvancingTurn : Se acerca al giro (&lt; 10m)\n        AdvancingTurn --&gt; OnTrack : Nueva instruccion activa\n        OnTrack --&gt; OffTrack : Desvio &gt; 30m\n        OffTrack --&gt; Recalculating : Re-enrutar\n        Recalculating --&gt; OnTrack : Nueva ruta calculada\n        OnTrack --&gt; DestinationReached : Distancia restante &lt; 5m\n    }\n\n    DestinationReached --&gt; Idle : Finalizar viaje\n    Navigating --&gt; Idle : clearRoute()\n    RouteReady --&gt; Idle : clearRoute()&quot;,&#xa;  &quot;config&quot;: null&#xa;}" id="7thMd6aekalAEQu9H9C8-0">
          <mxCell connectable="0" parent="8O_1LrPOFjY7Xs-Moz61-1" style="group;transparentBounds=1;editIcon=1;lockedGroup=0;groupPadding=10;" vertex="1">
            <mxGeometry as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="" mermaidId="n:root_start" mermaidBaseStyle="ellipse;html=1;fillColor=light-dark(#333333,#cccccc);strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="" id="8O_1LrPOFjY7Xs-Moz61-2">
          <mxCell parent="7thMd6aekalAEQu9H9C8-0" style="ellipse;html=1;fillColor=light-dark(#333333,#cccccc);strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="14" width="14" x="644" y="10" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="Idle" mermaidId="n:Idle" mermaidBaseStyle="swimlane;html=1;fontStyle=0;align=center;verticalAlign=middle;startSize=30;container=0;collapsible=0;rounded=1;absoluteArcSize=1;arcSize=16;footerSize=4;dropTarget=0;pointerEvents=0;swimlaneFillColor=light-dark(#ffffff,#1f2020);fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="Idle" id="8O_1LrPOFjY7Xs-Moz61-3">
          <mxCell parent="7thMd6aekalAEQu9H9C8-0" style="swimlane;html=1;fontStyle=0;align=center;verticalAlign=middle;startSize=30;container=0;collapsible=0;rounded=1;absoluteArcSize=1;arcSize=16;footerSize=4;dropTarget=0;pointerEvents=0;swimlaneFillColor=light-dark(#ffffff,#1f2020);fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="494" width="685" x="308" y="121" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="" mermaidId="n:Idle_start" mermaidBaseStyle="ellipse;html=1;fillColor=light-dark(#333333,#cccccc);strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="" id="8O_1LrPOFjY7Xs-Moz61-4">
          <mxCell parent="8O_1LrPOFjY7Xs-Moz61-3" style="ellipse;html=1;fillColor=light-dark(#333333,#cccccc);strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="14" width="14" x="58" y="35" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="BrowsingMap" mermaidId="n:BrowsingMap" mermaidBaseStyle="rounded=1;absoluteArcSize=1;arcSize=10;html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="BrowsingMap" id="8O_1LrPOFjY7Xs-Moz61-5">
          <mxCell parent="8O_1LrPOFjY7Xs-Moz61-3" style="rounded=1;absoluteArcSize=1;arcSize=10;html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="40" width="108" x="400" y="124" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="BuildingSelected" mermaidId="n:BuildingSelected" mermaidBaseStyle="rounded=1;absoluteArcSize=1;arcSize=10;html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="BuildingSelected" id="8O_1LrPOFjY7Xs-Moz61-6">
          <mxCell parent="8O_1LrPOFjY7Xs-Moz61-3" style="rounded=1;absoluteArcSize=1;arcSize=10;html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="40" width="135" x="225" y="258" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="FloorSelected" mermaidId="n:FloorSelected" mermaidBaseStyle="rounded=1;absoluteArcSize=1;arcSize=10;html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="FloorSelected" id="8O_1LrPOFjY7Xs-Moz61-7">
          <mxCell parent="8O_1LrPOFjY7Xs-Moz61-3" style="rounded=1;absoluteArcSize=1;arcSize=10;html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="40" width="114" x="236" y="429" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="PoiSelected" mermaidId="n:PoiSelected" mermaidBaseStyle="rounded=1;absoluteArcSize=1;arcSize=10;html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="PoiSelected" id="8O_1LrPOFjY7Xs-Moz61-8">
          <mxCell parent="8O_1LrPOFjY7Xs-Moz61-3" style="rounded=1;absoluteArcSize=1;arcSize=10;html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="40" width="99" x="528" y="258" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="" mermaidId="e:Idle_start-&gt;BrowsingMap#0" mermaidBaseStyle="curved=1;startArrow=none;endArrow=classic;endSize=9;fillColor=none;strokeColor=light-dark(#333333,#cccccc);exitX=1;exitY=0.5;entryX=0.5;entryY=0;" mermaidBaseValue="" id="8O_1LrPOFjY7Xs-Moz61-28">
          <mxCell edge="1" parent="8O_1LrPOFjY7Xs-Moz61-3" source="8O_1LrPOFjY7Xs-Moz61-4" style="curved=1;startArrow=none;endArrow=classic;endSize=9;fillColor=none;strokeColor=light-dark(#333333,#cccccc);exitX=1;exitY=0.5;entryX=0.5;entryY=0;" target="8O_1LrPOFjY7Xs-Moz61-5">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="454" y="86" />
              </Array>
            </mxGeometry>
          </mxCell>
        </UserObject>
        <UserObject label="Tap en poligono" mermaidId="e:BrowsingMap-&gt;BuildingSelected#0" mermaidBaseStyle="curved=1;startArrow=none;endArrow=classic;endSize=9;fillColor=none;strokeColor=light-dark(#333333,#cccccc);html=1;fontSize=16;labelBackgroundColor=#E8E8E88D;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);exitX=0;exitY=0.825;entryX=1;entryY=0.825;curved=1;exitX=0;exitY=0.83;entryX=1;entryY=0.83;" mermaidBaseValue="Tap en poligono" id="8O_1LrPOFjY7Xs-Moz61-29">
          <mxCell edge="1" parent="8O_1LrPOFjY7Xs-Moz61-3" source="8O_1LrPOFjY7Xs-Moz61-5" style="curved=1;startArrow=none;endArrow=classic;endSize=9;fillColor=none;strokeColor=light-dark(#333333,#cccccc);html=1;fontSize=16;labelBackgroundColor=#E8E8E88D;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);exitX=0;exitY=0.83;entryX=1;entryY=0.83;" target="8O_1LrPOFjY7Xs-Moz61-6">
            <mxGeometry relative="1" as="geometry">
              <mxPoint as="offset" />
              <Array as="points">
                <mxPoint x="380" y="279" />
              </Array>
            </mxGeometry>
          </mxCell>
        </UserObject>
        <UserObject label="Tap en espacio vacio" mermaidId="e:BuildingSelected-&gt;BrowsingMap#0" mermaidBaseStyle="curved=1;startArrow=none;endArrow=classic;endSize=9;fillColor=none;strokeColor=light-dark(#333333,#cccccc);html=1;fontSize=16;labelBackgroundColor=#E8E8E88D;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);exitX=1;exitY=0.175;entryX=0;entryY=0.175;curved=1;exitX=1;exitY=0.18;entryX=0;entryY=0.18;" mermaidBaseValue="Tap en espacio vacio" id="8O_1LrPOFjY7Xs-Moz61-30">
          <mxCell edge="1" parent="8O_1LrPOFjY7Xs-Moz61-3" source="8O_1LrPOFjY7Xs-Moz61-6" style="curved=1;startArrow=none;endArrow=classic;endSize=9;fillColor=none;strokeColor=light-dark(#333333,#cccccc);html=1;fontSize=16;labelBackgroundColor=#E8E8E88D;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);exitX=1;exitY=0.18;entryX=0;entryY=0.18;" target="8O_1LrPOFjY7Xs-Moz61-5">
            <mxGeometry relative="1" as="geometry">
              <mxPoint as="offset" />
              <Array as="points">
                <mxPoint x="380" y="126" />
              </Array>
            </mxGeometry>
          </mxCell>
        </UserObject>
        <UserObject label="Cambiar nivel (Indoor)" mermaidId="e:BuildingSelected-&gt;FloorSelected#0" mermaidBaseStyle="curved=1;startArrow=none;endArrow=classic;endSize=9;fillColor=none;strokeColor=light-dark(#333333,#cccccc);html=1;fontSize=16;labelBackgroundColor=#E8E8E88D;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);exitX=0.5962962962962963;exitY=1;entryX=0.6140350877192983;entryY=0;curved=1;exitX=0.6;exitY=1;entryX=0.61;entryY=0;" mermaidBaseValue="Cambiar nivel (Indoor)" id="8O_1LrPOFjY7Xs-Moz61-31">
          <mxCell edge="1" parent="8O_1LrPOFjY7Xs-Moz61-3" source="8O_1LrPOFjY7Xs-Moz61-6" style="curved=1;startArrow=none;endArrow=classic;endSize=9;fillColor=none;strokeColor=light-dark(#333333,#cccccc);html=1;fontSize=16;labelBackgroundColor=#E8E8E88D;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);exitX=0.6;exitY=1;entryX=0.61;entryY=0;" target="8O_1LrPOFjY7Xs-Moz61-7">
            <mxGeometry relative="1" as="geometry">
              <mxPoint as="offset" />
              <Array as="points">
                <mxPoint x="385" y="364" />
              </Array>
            </mxGeometry>
          </mxCell>
        </UserObject>
        <UserObject label="Cerrar selector" mermaidId="e:FloorSelected-&gt;BuildingSelected#0" mermaidBaseStyle="curved=1;startArrow=none;endArrow=classic;endSize=9;fillColor=none;strokeColor=light-dark(#333333,#cccccc);html=1;fontSize=16;labelBackgroundColor=#E8E8E88D;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);exitX=0.38596491228070173;exitY=0;entryX=0.4037037037037037;entryY=1;curved=1;exitX=0.39;exitY=0;entryX=0.4;entryY=1;" mermaidBaseValue="Cerrar selector" id="8O_1LrPOFjY7Xs-Moz61-32">
          <mxCell edge="1" parent="8O_1LrPOFjY7Xs-Moz61-3" source="8O_1LrPOFjY7Xs-Moz61-7" style="curved=1;startArrow=none;endArrow=classic;endSize=9;fillColor=none;strokeColor=light-dark(#333333,#cccccc);html=1;fontSize=16;labelBackgroundColor=#E8E8E88D;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);exitX=0.39;exitY=0;entryX=0.4;entryY=1;" target="8O_1LrPOFjY7Xs-Moz61-6">
            <mxGeometry relative="1" as="geometry">
              <mxPoint as="offset" />
              <Array as="points">
                <mxPoint x="227" y="364" />
              </Array>
            </mxGeometry>
          </mxCell>
        </UserObject>
        <UserObject label="Tap en marcador" mermaidId="e:BrowsingMap-&gt;PoiSelected#0" mermaidBaseStyle="curved=1;startArrow=none;endArrow=classic;endSize=9;fillColor=none;strokeColor=light-dark(#333333,#cccccc);html=1;fontSize=16;labelBackgroundColor=#E8E8E88D;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);exitX=0.6203703703703703;exitY=1;entryX=0.6313131313131313;entryY=0;curved=1;exitX=0.62;exitY=1;entryX=0.63;entryY=0;" mermaidBaseValue="Tap en marcador" id="8O_1LrPOFjY7Xs-Moz61-33">
          <mxCell edge="1" parent="8O_1LrPOFjY7Xs-Moz61-3" source="8O_1LrPOFjY7Xs-Moz61-5" style="curved=1;startArrow=none;endArrow=classic;endSize=9;fillColor=none;strokeColor=light-dark(#333333,#cccccc);html=1;fontSize=16;labelBackgroundColor=#E8E8E88D;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);exitX=0.62;exitY=1;entryX=0.63;entryY=0;" target="8O_1LrPOFjY7Xs-Moz61-8">
            <mxGeometry relative="1" as="geometry">
              <mxPoint as="offset" />
              <Array as="points">
                <mxPoint x="588" y="211" />
              </Array>
            </mxGeometry>
          </mxCell>
        </UserObject>
        <UserObject label="Deseleccionar POI" mermaidId="e:PoiSelected-&gt;BrowsingMap#0" mermaidBaseStyle="curved=1;startArrow=none;endArrow=classic;endSize=9;fillColor=none;strokeColor=light-dark(#333333,#cccccc);html=1;fontSize=16;labelBackgroundColor=#E8E8E88D;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);exitX=0.3686868686868687;exitY=0;entryX=0.37962962962962965;entryY=1;curved=1;exitX=0.37;exitY=0;entryX=0.38;entryY=1;" mermaidBaseValue="Deseleccionar POI" id="8O_1LrPOFjY7Xs-Moz61-34">
          <mxCell edge="1" parent="8O_1LrPOFjY7Xs-Moz61-3" source="8O_1LrPOFjY7Xs-Moz61-8" style="curved=1;startArrow=none;endArrow=classic;endSize=9;fillColor=none;strokeColor=light-dark(#333333,#cccccc);html=1;fontSize=16;labelBackgroundColor=#E8E8E88D;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);exitX=0.37;exitY=0;entryX=0.38;entryY=1;" target="8O_1LrPOFjY7Xs-Moz61-5">
            <mxGeometry relative="1" as="geometry">
              <mxPoint as="offset" />
              <Array as="points">
                <mxPoint x="439" y="211" />
              </Array>
            </mxGeometry>
          </mxCell>
        </UserObject>
        <UserObject label="RoutePlanning" mermaidId="n:RoutePlanning" mermaidBaseStyle="swimlane;html=1;fontStyle=0;align=center;verticalAlign=middle;startSize=30;container=0;collapsible=0;rounded=1;absoluteArcSize=1;arcSize=16;footerSize=4;dropTarget=0;pointerEvents=0;swimlaneFillColor=light-dark(#ffffff,#1f2020);fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="RoutePlanning" id="8O_1LrPOFjY7Xs-Moz61-9">
          <mxCell parent="7thMd6aekalAEQu9H9C8-0" style="swimlane;html=1;fontStyle=0;align=center;verticalAlign=middle;startSize=30;container=0;collapsible=0;rounded=1;absoluteArcSize=1;arcSize=16;footerSize=4;dropTarget=0;pointerEvents=0;swimlaneFillColor=light-dark(#ffffff,#1f2020);fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="519" width="460" x="1034" y="528" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="" mermaidId="n:RoutePlanning_start" mermaidBaseStyle="ellipse;html=1;fillColor=light-dark(#333333,#cccccc);strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="" id="8O_1LrPOFjY7Xs-Moz61-10">
          <mxCell parent="8O_1LrPOFjY7Xs-Moz61-9" style="ellipse;html=1;fillColor=light-dark(#333333,#cccccc);strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="14" width="14" x="274" y="35" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="CalculatingPath" mermaidId="n:CalculatingPath" mermaidBaseStyle="rounded=1;absoluteArcSize=1;arcSize=10;html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="CalculatingPath" id="8O_1LrPOFjY7Xs-Moz61-11">
          <mxCell parent="8O_1LrPOFjY7Xs-Moz61-9" style="rounded=1;absoluteArcSize=1;arcSize=10;html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="40" width="128" x="217" y="175" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="RouteReady" mermaidId="n:RouteReady" mermaidBaseStyle="rounded=1;absoluteArcSize=1;arcSize=10;html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="RouteReady" id="8O_1LrPOFjY7Xs-Moz61-12">
          <mxCell parent="8O_1LrPOFjY7Xs-Moz61-9" style="rounded=1;absoluteArcSize=1;arcSize=10;html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="40" width="100" x="65" y="309" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="RouteError" mermaidId="n:RouteError" mermaidBaseStyle="rounded=1;absoluteArcSize=1;arcSize=10;html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="RouteError" id="8O_1LrPOFjY7Xs-Moz61-13">
          <mxCell parent="8O_1LrPOFjY7Xs-Moz61-9" style="rounded=1;absoluteArcSize=1;arcSize=10;html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="40" width="93" x="301" y="309" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="" mermaidId="n:RoutePlanning_end" mermaidBaseStyle="ellipse;html=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#333333,#cccccc);strokeWidth=2;centerRadius=4;centerColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="" id="8O_1LrPOFjY7Xs-Moz61-14">
          <mxCell parent="8O_1LrPOFjY7Xs-Moz61-9" style="ellipse;html=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#333333,#cccccc);strokeWidth=2;centerRadius=4;centerColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="14" width="14" x="340" y="480" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="" mermaidId="e:RoutePlanning_start-&gt;CalculatingPath#0" mermaidBaseStyle="curved=1;startArrow=none;endArrow=classic;endSize=9;fillColor=none;strokeColor=light-dark(#333333,#cccccc);exitX=0.5;exitY=1;entryX=0.5;entryY=0;" mermaidBaseValue="" id="8O_1LrPOFjY7Xs-Moz61-35">
          <mxCell edge="1" parent="8O_1LrPOFjY7Xs-Moz61-9" source="8O_1LrPOFjY7Xs-Moz61-10" style="curved=1;startArrow=none;endArrow=classic;endSize=9;fillColor=none;strokeColor=light-dark(#333333,#cccccc);exitX=0.5;exitY=1;entryX=0.5;entryY=0;" target="8O_1LrPOFjY7Xs-Moz61-11">
            <mxGeometry relative="1" as="geometry">
              <Array as="points" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <UserObject label="Ruta valida encontrada" mermaidId="e:CalculatingPath-&gt;RouteReady#0" mermaidBaseStyle="curved=1;startArrow=none;endArrow=classic;endSize=9;fillColor=none;strokeColor=light-dark(#333333,#cccccc);html=1;fontSize=16;labelBackgroundColor=#E8E8E88D;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);exitX=0.23;exitY=1;entryX=0.65;entryY=0;" mermaidBaseValue="Ruta valida encontrada" id="8O_1LrPOFjY7Xs-Moz61-36">
          <mxCell edge="1" parent="8O_1LrPOFjY7Xs-Moz61-9" source="8O_1LrPOFjY7Xs-Moz61-11" style="curved=1;startArrow=none;endArrow=classic;endSize=9;fillColor=none;strokeColor=light-dark(#333333,#cccccc);html=1;fontSize=16;labelBackgroundColor=#E8E8E88D;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);exitX=0.23;exitY=1;entryX=0.65;entryY=0;" target="8O_1LrPOFjY7Xs-Moz61-12">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="166" y="262" />
              </Array>
            </mxGeometry>
          </mxCell>
        </UserObject>
        <UserObject label="Sin conexion en grafo" mermaidId="e:CalculatingPath-&gt;RouteError#0" mermaidBaseStyle="curved=1;startArrow=none;endArrow=classic;endSize=9;fillColor=none;strokeColor=light-dark(#333333,#cccccc);html=1;fontSize=16;labelBackgroundColor=#E8E8E88D;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);exitX=0.66;exitY=1;entryX=0.49;entryY=0;" mermaidBaseValue="Sin conexion en grafo" id="8O_1LrPOFjY7Xs-Moz61-37">
          <mxCell edge="1" parent="8O_1LrPOFjY7Xs-Moz61-9" source="8O_1LrPOFjY7Xs-Moz61-11" style="curved=1;startArrow=none;endArrow=classic;endSize=9;fillColor=none;strokeColor=light-dark(#333333,#cccccc);html=1;fontSize=16;labelBackgroundColor=#E8E8E88D;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);exitX=0.66;exitY=1;entryX=0.49;entryY=0;" target="8O_1LrPOFjY7Xs-Moz61-13">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="347" y="262" />
              </Array>
            </mxGeometry>
          </mxCell>
        </UserObject>
        <UserObject label="Reintentar o cancelar" mermaidId="e:RouteError-&gt;RoutePlanning_end#0" mermaidBaseStyle="curved=1;startArrow=none;endArrow=classic;endSize=9;fillColor=none;strokeColor=light-dark(#333333,#cccccc);html=1;fontSize=16;labelBackgroundColor=#E8E8E88D;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);exitX=0.5;exitY=1;entryX=0.5;entryY=0;" mermaidBaseValue="Reintentar o cancelar" id="8O_1LrPOFjY7Xs-Moz61-38">
          <mxCell edge="1" parent="8O_1LrPOFjY7Xs-Moz61-9" source="8O_1LrPOFjY7Xs-Moz61-13" style="curved=1;startArrow=none;endArrow=classic;endSize=9;fillColor=none;strokeColor=light-dark(#333333,#cccccc);html=1;fontSize=16;labelBackgroundColor=#E8E8E88D;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);exitX=0.5;exitY=1;entryX=0.5;entryY=0;" target="8O_1LrPOFjY7Xs-Moz61-14">
            <mxGeometry relative="1" as="geometry">
              <Array as="points" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <UserObject label="Navigating" mermaidId="n:Navigating" mermaidBaseStyle="swimlane;html=1;fontStyle=0;align=center;verticalAlign=middle;startSize=30;container=0;collapsible=0;rounded=1;absoluteArcSize=1;arcSize=16;footerSize=4;dropTarget=0;pointerEvents=0;swimlaneFillColor=light-dark(#ffffff,#1f2020);fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="Navigating" id="8O_1LrPOFjY7Xs-Moz61-15">
          <mxCell parent="7thMd6aekalAEQu9H9C8-0" style="swimlane;html=1;fontStyle=0;align=center;verticalAlign=middle;startSize=30;container=0;collapsible=0;rounded=1;absoluteArcSize=1;arcSize=16;footerSize=4;dropTarget=0;pointerEvents=0;swimlaneFillColor=light-dark(#ffffff,#1f2020);fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="495" width="1131" x="10" y="973" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="" mermaidId="n:Navigating_start" mermaidBaseStyle="ellipse;html=1;fillColor=light-dark(#333333,#cccccc);strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="" id="8O_1LrPOFjY7Xs-Moz61-16">
          <mxCell parent="8O_1LrPOFjY7Xs-Moz61-15" style="ellipse;html=1;fillColor=light-dark(#333333,#cccccc);strokeColor=light-dark(#333333,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="14" width="14" x="588" y="35" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="OnTrack" mermaidId="n:OnTrack" mermaidBaseStyle="rounded=1;absoluteArcSize=1;arcSize=10;html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="OnTrack" id="8O_1LrPOFjY7Xs-Moz61-17">
          <mxCell parent="8O_1LrPOFjY7Xs-Moz61-15" style="rounded=1;absoluteArcSize=1;arcSize=10;html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="40" width="74" x="558" y="162" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="AdvancingTurn" mermaidId="n:AdvancingTurn" mermaidBaseStyle="rounded=1;absoluteArcSize=1;arcSize=10;html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="AdvancingTurn" id="8O_1LrPOFjY7Xs-Moz61-18">
          <mxCell parent="8O_1LrPOFjY7Xs-Moz61-15" style="rounded=1;absoluteArcSize=1;arcSize=10;html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="40" width="120" x="789" y="296" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="OffTrack" mermaidId="n:OffTrack" mermaidBaseStyle="rounded=1;absoluteArcSize=1;arcSize=10;html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="OffTrack" id="8O_1LrPOFjY7Xs-Moz61-19">
          <mxCell parent="8O_1LrPOFjY7Xs-Moz61-15" style="rounded=1;absoluteArcSize=1;arcSize=10;html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="40" width="77" x="499" y="296" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="Recalculating" mermaidId="n:Recalculating" mermaidBaseStyle="rounded=1;absoluteArcSize=1;arcSize=10;html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="Recalculating" id="8O_1LrPOFjY7Xs-Moz61-20">
          <mxCell parent="8O_1LrPOFjY7Xs-Moz61-15" style="rounded=1;absoluteArcSize=1;arcSize=10;html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="40" width="112" x="258" y="430" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="DestinationReached" mermaidId="n:DestinationReached" mermaidBaseStyle="rounded=1;absoluteArcSize=1;arcSize=10;html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" mermaidBaseValue="DestinationReached" id="8O_1LrPOFjY7Xs-Moz61-21">
          <mxCell parent="8O_1LrPOFjY7Xs-Moz61-15" style="rounded=1;absoluteArcSize=1;arcSize=10;html=1;whiteSpace=wrap;strokeWidth=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontSize=16;" vertex="1">
            <mxGeometry height="40" width="157" x="221" y="296" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="" mermaidId="e:Navigating_start-&gt;OnTrack#0" mermaidBaseStyle="curved=1;startArrow=none;endArrow=classic;endSize=9;fillColor=none;strokeColor=light-dark(#333333,#cccccc);exitX=0.5;exitY=1;entryX=0.5;entryY=0;" mermaidBaseValue="" id="8O_1LrPOFjY7Xs-Moz61-39">
          <mxCell edge="1" parent="8O_1LrPOFjY7Xs-Moz61-15" source="8O_1LrPOFjY7Xs-Moz61-16" style="curved=1;startArrow=none;endArrow=classic;endSize=9;fillColor=none;strokeColor=light-dark(#333333,#cccccc);exitX=0.5;exitY=1;entryX=0.5;entryY=0;" target="8O_1LrPOFjY7Xs-Moz61-17">
            <mxGeometry relative="1" as="geometry">
              <Array as="points" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <UserObject label="Se acerca al giro (&lt; 10m)" mermaidId="e:OnTrack-&gt;AdvancingTurn#0" mermaidBaseStyle="curved=1;startArrow=none;endArrow=classic;endSize=9;fillColor=none;strokeColor=light-dark(#333333,#cccccc);html=1;fontSize=16;labelBackgroundColor=#E8E8E88D;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);exitX=1;exitY=0.825;entryX=0;entryY=0.825;curved=1;exitX=1;exitY=0.83;entryX=0;entryY=0.83;" mermaidBaseValue="Se acerca al giro (&lt; 10m)" id="8O_1LrPOFjY7Xs-Moz61-40">
          <mxCell edge="1" parent="8O_1LrPOFjY7Xs-Moz61-15" source="8O_1LrPOFjY7Xs-Moz61-17" style="curved=1;startArrow=none;endArrow=classic;endSize=9;fillColor=none;strokeColor=light-dark(#333333,#cccccc);html=1;fontSize=16;labelBackgroundColor=#E8E8E88D;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);exitX=1;exitY=0.83;entryX=0;entryY=0.83;" target="8O_1LrPOFjY7Xs-Moz61-18">
            <mxGeometry relative="1" as="geometry">
              <mxPoint as="offset" />
              <Array as="points">
                <mxPoint x="711" y="351" />
              </Array>
            </mxGeometry>
          </mxCell>
        </UserObject>
        <UserObject label="Nueva instruccion activa" mermaidId="e:AdvancingTurn-&gt;OnTrack#0" mermaidBaseStyle="curved=1;startArrow=none;endArrow=classic;endSize=9;fillColor=none;strokeColor=light-dark(#333333,#cccccc);html=1;fontSize=16;labelBackgroundColor=#E8E8E88D;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);exitX=0;exitY=0.175;entryX=1;entryY=0.175;curved=1;exitX=0;exitY=0.18;entryX=1;entryY=0.18;" mermaidBaseValue="Nueva instruccion activa" id="8O_1LrPOFjY7Xs-Moz61-41">
          <mxCell edge="1" parent="8O_1LrPOFjY7Xs-Moz61-15" source="8O_1LrPOFjY7Xs-Moz61-18" style="curved=1;startArrow=none;endArrow=classic;endSize=9;fillColor=none;strokeColor=light-dark(#333333,#cccccc);html=1;fontSize=16;labelBackgroundColor=#E8E8E88D;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);exitX=0;exitY=0.18;entryX=1;entryY=0.18;" target="8O_1LrPOFjY7Xs-Moz61-17">
            <mxGeometry relative="1" as="geometry">
              <mxPoint as="offset" />
              <Array as="points">
                <mxPoint x="711" y="149" />
              </Array>
            </mxGeometry>
          </mxCell>
        </UserObject>
        <UserObject label="Desvio &gt; 30m" mermaidId="e:OnTrack-&gt;OffTrack#0" mermaidBaseStyle="curved=1;startArrow=none;endArrow=classic;endSize=9;fillColor=none;strokeColor=light-dark(#333333,#cccccc);html=1;fontSize=16;labelBackgroundColor=#E8E8E88D;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);exitX=0.27;exitY=1;entryX=0.49;entryY=0;" mermaidBaseValue="Desvio &gt; 30m" id="8O_1LrPOFjY7Xs-Moz61-42">
          <mxCell edge="1" parent="8O_1LrPOFjY7Xs-Moz61-15" source="8O_1LrPOFjY7Xs-Moz61-17" style="curved=1;startArrow=none;endArrow=classic;endSize=9;fillColor=none;strokeColor=light-dark(#333333,#cccccc);html=1;fontSize=16;labelBackgroundColor=#E8E8E88D;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);exitX=0.27;exitY=1;entryX=0.49;entryY=0;" target="8O_1LrPOFjY7Xs-Moz61-19">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="537" y="249" />
              </Array>
            </mxGeometry>
          </mxCell>
        </UserObject>
        <UserObject label="Re-enrutar" mermaidId="e:OffTrack-&gt;Recalculating#0" mermaidBaseStyle="curved=1;startArrow=none;endArrow=classic;endSize=9;fillColor=none;strokeColor=light-dark(#333333,#cccccc);html=1;fontSize=16;labelBackgroundColor=#E8E8E88D;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);exitX=0.49;exitY=1;entryX=1;entryY=0.08;" mermaidBaseValue="Re-enrutar" id="8O_1LrPOFjY7Xs-Moz61-43">
          <mxCell edge="1" parent="8O_1LrPOFjY7Xs-Moz61-15" source="8O_1LrPOFjY7Xs-Moz61-19" style="curved=1;startArrow=none;endArrow=classic;endSize=9;fillColor=none;strokeColor=light-dark(#333333,#cccccc);html=1;fontSize=16;labelBackgroundColor=#E8E8E88D;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);exitX=0.49;exitY=1;entryX=1;entryY=0.08;" target="8O_1LrPOFjY7Xs-Moz61-20">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="537" y="383" />
              </Array>
            </mxGeometry>
          </mxCell>
        </UserObject>
        <UserObject label="Nueva ruta calculada" mermaidId="e:Recalculating-&gt;OnTrack#0" mermaidBaseStyle="curved=1;startArrow=none;endArrow=classic;endSize=9;fillColor=none;strokeColor=light-dark(#333333,#cccccc);html=1;fontSize=16;labelBackgroundColor=#E8E8E88D;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);exitX=0.69;exitY=0;entryX=0.22;entryY=1;" mermaidBaseValue="Nueva ruta calculada" id="8O_1LrPOFjY7Xs-Moz61-44">
          <mxCell edge="1" parent="8O_1LrPOFjY7Xs-Moz61-15" source="8O_1LrPOFjY7Xs-Moz61-20" style="curved=1;startArrow=none;endArrow=classic;endSize=9;fillColor=none;strokeColor=light-dark(#333333,#cccccc);html=1;fontSize=16;labelBackgroundColor=#E8E8E88D;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);exitX=0.69;exitY=0;entryX=0.22;entryY=1;" target="8O_1LrPOFjY7Xs-Moz61-17">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="110" y="383" />
                <mxPoint x="110" y="316" />
                <mxPoint x="110" y="249" />
              </Array>
            </mxGeometry>
          </mxCell>
        </UserObject>
        <UserObject label="Distancia restante &lt; 5m" mermaidId="e:OnTrack-&gt;DestinationReached#0" mermaidBaseStyle="curved=1;startArrow=none;endArrow=classic;endSize=9;fillColor=none;strokeColor=light-dark(#333333,#cccccc);html=1;fontSize=16;labelBackgroundColor=#E8E8E88D;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);exitX=0;exitY=0.78;entryX=0.66;entryY=0;" mermaidBaseValue="Distancia restante &lt; 5m" id="8O_1LrPOFjY7Xs-Moz61-45">
          <mxCell edge="1" parent="8O_1LrPOFjY7Xs-Moz61-15" source="8O_1LrPOFjY7Xs-Moz61-17" style="curved=1;startArrow=none;endArrow=classic;endSize=9;fillColor=none;strokeColor=light-dark(#333333,#cccccc);html=1;fontSize=16;labelBackgroundColor=#E8E8E88D;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);exitX=0;exitY=0.78;entryX=0.66;entryY=0;" target="8O_1LrPOFjY7Xs-Moz61-21">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="385" y="249" />
              </Array>
            </mxGeometry>
          </mxCell>
        </UserObject>
        <UserObject label="Datos cargados" mermaidId="e:root_start-&gt;Idle#0" mermaidBaseStyle="curved=1;startArrow=none;endArrow=classic;endSize=9;fillColor=none;curved=1;strokeColor=light-dark(#333333,#cccccc);html=1;fontSize=16;labelBackgroundColor=#E8E8E88D;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);exitX=0.5;exitY=1;entryX=0.5;entryY=0;" mermaidBaseValue="Datos cargados" id="8O_1LrPOFjY7Xs-Moz61-22">
          <mxCell edge="1" parent="7thMd6aekalAEQu9H9C8-0" source="8O_1LrPOFjY7Xs-Moz61-2" style="curved=1;startArrow=none;endArrow=classic;endSize=9;fillColor=none;strokeColor=light-dark(#333333,#cccccc);html=1;fontSize=16;labelBackgroundColor=#E8E8E88D;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);exitX=0.5;exitY=1;entryX=0.5;entryY=0;" target="8O_1LrPOFjY7Xs-Moz61-3">
            <mxGeometry relative="1" as="geometry">
              <Array as="points" />
            </mxGeometry>
          </mxCell>
        </UserObject>
        <UserObject label="calculateRoute(...)" mermaidId="e:Idle-&gt;RoutePlanning#0" mermaidBaseStyle="curved=1;startArrow=none;endArrow=classic;endSize=9;fillColor=none;curved=1;strokeColor=light-dark(#333333,#cccccc);html=1;fontSize=16;labelBackgroundColor=#E8E8E88D;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);exitX=1;exitY=0.81;entryX=0;entryY=0.04;" mermaidBaseValue="calculateRoute(...)" id="8O_1LrPOFjY7Xs-Moz61-23">
          <mxCell edge="1" parent="7thMd6aekalAEQu9H9C8-0" source="8O_1LrPOFjY7Xs-Moz61-3" style="curved=1;startArrow=none;endArrow=classic;endSize=9;fillColor=none;strokeColor=light-dark(#333333,#cccccc);html=1;fontSize=16;labelBackgroundColor=#E8E8E88D;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);exitX=1;exitY=0.81;entryX=0;entryY=0.04;" target="8O_1LrPOFjY7Xs-Moz61-9">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="1034" y="529" />
              </Array>
            </mxGeometry>
          </mxCell>
        </UserObject>
        <UserObject label="Iniciar seguimiento GPS" mermaidId="e:RouteReady-&gt;Navigating#0" mermaidBaseStyle="curved=1;startArrow=none;endArrow=classic;endSize=9;fillColor=none;curved=1;strokeColor=light-dark(#333333,#cccccc);html=1;fontSize=16;labelBackgroundColor=#E8E8E88D;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);exitX=0;exitY=0.5;entryX=1;entryY=0.12;" mermaidBaseValue="Iniciar seguimiento GPS" id="8O_1LrPOFjY7Xs-Moz61-24">
          <mxCell edge="1" parent="7thMd6aekalAEQu9H9C8-0" source="8O_1LrPOFjY7Xs-Moz61-12" style="curved=1;startArrow=none;endArrow=classic;endSize=9;fillColor=none;strokeColor=light-dark(#333333,#cccccc);html=1;fontSize=16;labelBackgroundColor=#E8E8E88D;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);exitX=0;exitY=0.5;entryX=1;entryY=0.12;" target="8O_1LrPOFjY7Xs-Moz61-15">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="1141" y="910" />
              </Array>
            </mxGeometry>
          </mxCell>
        </UserObject>
        <UserObject label="Finalizar viaje" mermaidId="e:DestinationReached-&gt;Idle#0" mermaidBaseStyle="curved=1;startArrow=none;endArrow=classic;endSize=9;fillColor=none;curved=1;strokeColor=light-dark(#333333,#cccccc);html=1;fontSize=16;labelBackgroundColor=#E8E8E88D;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);exitX=0.46;exitY=0;entryX=0;entryY=0.11;" mermaidBaseValue="Finalizar viaje" id="8O_1LrPOFjY7Xs-Moz61-25">
          <mxCell edge="1" parent="7thMd6aekalAEQu9H9C8-0" source="8O_1LrPOFjY7Xs-Moz61-21" style="curved=1;startArrow=none;endArrow=classic;endSize=9;fillColor=none;strokeColor=light-dark(#333333,#cccccc);html=1;fontSize=16;labelBackgroundColor=#E8E8E88D;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);exitX=0.46;exitY=0;entryX=0;entryY=0.11;" target="8O_1LrPOFjY7Xs-Moz61-3">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="290" y="1222" />
                <mxPoint x="290" y="1155" />
                <mxPoint x="290" y="1097" />
                <mxPoint x="290" y="1060" />
                <mxPoint x="290" y="1015" />
                <mxPoint x="290" y="971" />
                <mxPoint x="290" y="924" />
                <mxPoint x="290" y="857" />
                <mxPoint x="290" y="790" />
                <mxPoint x="290" y="723" />
                <mxPoint x="290" y="665" />
                <mxPoint x="290" y="628" />
                <mxPoint x="290" y="570" />
                <mxPoint x="290" y="513" />
                <mxPoint x="290" y="466" />
                <mxPoint x="290" y="399" />
                <mxPoint x="290" y="332" />
                <mxPoint x="290" y="265" />
                <mxPoint x="290" y="207" />
              </Array>
            </mxGeometry>
          </mxCell>
        </UserObject>
        <UserObject label="clearRoute()" mermaidId="e:Navigating-&gt;Idle#0" mermaidBaseStyle="curved=1;startArrow=none;endArrow=classic;endSize=9;fillColor=none;curved=1;strokeColor=light-dark(#333333,#cccccc);html=1;fontSize=16;labelBackgroundColor=#E8E8E88D;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);exitX=0.15;exitY=0;entryX=0;entryY=0.15;" mermaidBaseValue="clearRoute()" id="8O_1LrPOFjY7Xs-Moz61-26">
          <mxCell edge="1" parent="7thMd6aekalAEQu9H9C8-0" source="8O_1LrPOFjY7Xs-Moz61-15" style="curved=1;startArrow=none;endArrow=classic;endSize=9;fillColor=none;strokeColor=light-dark(#333333,#cccccc);html=1;fontSize=16;labelBackgroundColor=#E8E8E88D;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);exitX=0.15;exitY=0;entryX=0;entryY=0.15;" target="8O_1LrPOFjY7Xs-Moz61-3">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="175" y="971" />
                <mxPoint x="175" y="924" />
                <mxPoint x="175" y="857" />
                <mxPoint x="175" y="790" />
                <mxPoint x="175" y="723" />
                <mxPoint x="175" y="665" />
                <mxPoint x="175" y="628" />
                <mxPoint x="175" y="570" />
                <mxPoint x="175" y="513" />
                <mxPoint x="175" y="466" />
                <mxPoint x="175" y="399" />
                <mxPoint x="175" y="332" />
                <mxPoint x="175" y="265" />
                <mxPoint x="175" y="207" />
              </Array>
            </mxGeometry>
          </mxCell>
        </UserObject>
        <UserObject label="clearRoute()" mermaidId="e:RouteReady-&gt;Idle#0" mermaidBaseStyle="curved=1;startArrow=none;endArrow=classic;endSize=9;fillColor=none;curved=1;strokeColor=light-dark(#333333,#cccccc);html=1;fontSize=16;labelBackgroundColor=#E8E8E88D;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);exitX=0;exitY=0.5;entryX=1;entryY=0.88;" mermaidBaseValue="clearRoute()" id="8O_1LrPOFjY7Xs-Moz61-27">
          <mxCell edge="1" parent="7thMd6aekalAEQu9H9C8-0" source="8O_1LrPOFjY7Xs-Moz61-12" style="curved=1;startArrow=none;endArrow=classic;endSize=9;fillColor=none;strokeColor=light-dark(#333333,#cccccc);html=1;fontSize=16;labelBackgroundColor=#E8E8E88D;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);exitX=0;exitY=0.5;entryX=1;entryY=0.88;" target="8O_1LrPOFjY7Xs-Moz61-3">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="993" y="767" />
              </Array>
            </mxGeometry>
          </mxCell>
        </UserObject>
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>

```
---

## Estructura de Directorios

```text
usac_campus_map/
├── assets/
│   ├── geojson/
│   │   ├── usac_boundary.geojson         # Limite perimetral exterior oficial
│   │   └── usac_buildings.geojson        # 248 entidades espaciales verificadas
│   ├── graph/
│   │   └── campus_graph.json             # Grafo de navegacion (479 nodos, 1072 aristas)
│   └── pois/
│       └── usac_pois_and_indoors.json    # Catalogo de POIs, garitas y planos interiores
├── lib/
│   ├── usac_campus_map.dart              # Barrel export de la libreria
│   └── src/
│       ├── controllers/
│       │   └── usac_campus_map_controller.dart # Controlador reactivo principal
│       ├── core/
│       │   ├── algorithms/
│       │   │   ├── a_star.dart           # Motor A* de caminos minimos
│       │   │   ├── priority_queue.dart   # Min-heap para seleccion eficiente
│       │   │   └── snap_to_path.dart     # Proyeccion ortogonal a aristas
│       │   └── utils/
│       │       └── distance_calculator.dart # Formulas trigonometricas y Haversine
│       ├── engine/
│       │   ├── campus_data_repository.dart  # Deserializacion de datos locales
│       │   ├── route_engine.dart            # Ruteo multi-modal y giros
│       │   └── search_engine.dart           # Motor de busqueda difusa
│       ├── models/
│       │   ├── campus_building.dart         # Entidad de edificio y silueta
│       │   ├── campus_edge.dart             # Conexion entre nodos del grafo
│       │   ├── campus_node.dart             # Vertice de navegacion
│       │   ├── campus_poi.dart              # Punto de interes o servicio
│       │   ├── campus_route.dart            # Trayectoria de navegacion calculada
│       │   ├── indoor_floor.dart            # Plano de nivel interior
│       │   └── navigation_mode.dart         # Enumerador de modos de transporte
│       └── presentation/
│           ├── themes/
│           │   └── usac_map_theme.dart      # Paleta oficial azul (#002B49) y oro
│           └── widgets/
│               ├── floor_selector.dart      # Selector flotante de pisos
│               ├── map_view.dart            # Lienzo cartografico con FlutterMap
│               ├── poi_detail_sheet.dart    # Modal inferior con ficha tecnica
│               └── turn_by_turn_banner.dart # Banner de instrucciones de giro
├── test/
│   ├── controller_and_widgets_test.dart  # Pruebas de widgets y controlador
│   ├── core_algorithms_test.dart        # Pruebas de algoritmos matematicos
│   ├── engine_test.dart                 # Pruebas de motores de ruteo y busqueda
│   └── ground_truth_dataset_test.dart   # Validacion de integridad de datos OSM
└── pubspec.yaml
```

---

## Especificacion de Datos Geograficos (Ground Truth)

### Esquema de Edificios y Poligonos (`usac_buildings.geojson`)

Estructura GeoJSON estandarizada (`FeatureCollection`) donde cada `Feature` representa un poligono perimetral:

```json
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "id": "T-3",
      "properties": {
        "id": "T-3",
        "name": "Edificio T-3 - Facultad de Ingenieria",
        "category": "faculty",
        "floors": 3,
        "description": "Decanatura de Ingenieria, Escuelas de Ingenieria Civil y Mecanica."
      },
      "geometry": {
        "type": "Polygon",
        "coordinates": [
          [
            [-90.552680, 14.583120],
            [-90.552150, 14.583120],
            [-90.552150, 14.582570],
            [-90.552680, 14.582570],
            [-90.552680, 14.583120]
          ]
        ]
      }
    }
  ]
}
```

#### Categorias de Entidades Soportadas
- `faculty`: Modulos academicos, facultades, escuelas y laboratorios docentes.
- `parking`: Zonas de estacionamiento de automoviles y motocicletas.
- `green`: Areas verdes, jardines protegidos y plazas civicas.
- `sports`: Canchas polideportivas, estadio y gimnasios.
- `administrative`: Dependencias del gobierno universitario y servicios estudiantiles.
- `cultural`: Teatros, museos y centros comunitarios.
- `library`: Biblioteca central y bibliotecas especializadas.
- `service`: Centros de atencion medica, bancos y cafeterias.

---

### Esquema del Grafo Vial y Peatonal (`campus_graph.json`)

Define los nodos y aristas de la red de transporte:

```json
{
  "nodes": [
    {
      "id": "node_t3_entrance",
      "lat": 14.582845,
      "lng": -90.552431,
      "label": "Entrada Principal T-3"
    }
  ],
  "edges": [
    {
      "id": "edge_t3_walkway",
      "source": "node_t3_entrance",
      "target": "node_t4_entrance",
      "distance": 45.2,
      "isAccessible": true,
      "allowsVehicles": false,
      "allowsBicycles": true
    }
  ]
}
```

---

### Esquema de POIs y Planos Interiores (`usac_pois_and_indoors.json`)

```json
{
  "pois": [
    {
      "id": "garita-periferico-entrada",
      "name": "Garita Periferico (Ingreso Vehicular)",
      "category": "access",
      "lat": 14.589488,
      "lng": -90.553168,
      "description": "Acceso poniente al campus desde el Anillo Periferico."
    }
  ],
  "indoors": [
    {
      "buildingId": "T-3",
      "floors": [
        {
          "floorNumber": 1,
          "floorName": "Nivel 1",
          "pois": [
            {
              "id": "t3-aula-101",
              "name": "Salon 101",
              "category": "academic",
              "lat": 14.582845,
              "lng": -90.552431
            }
          ]
        }
      ]
    }
  ]
}
```

---

## Referencia de API y Componentes

### Controlador: `UsacCampusMapController`

Es el orquestador central del mapa. Extiende `ChangeNotifier`:

| Metodo | Descripcion |
| :--- | :--- |
| `calculateRoute({origin, destination, mode})` | Calcula y traza la ruta optima en el mapa entre dos puntos utilizando el modo de movilidad indicado. |
| `clearRoute()` | Limpia la ruta activa, elimina la polilinea del mapa y oculta el banner paso a paso. |
| `selectBuilding(CampusBuilding? building)` | Establece el edificio activo, resalta su silueta perimetral y abre la ficha de detalles. |
| `selectFloor(int? floor)` | Conmuta el nivel interior visible para el edificio seleccionado. |
| `selectPoi(CampusPoi? poi)` | Enfoca un punto de interes en el mapa y despliega su informacion. |
| `search(String query)` | Ejecuta una consulta difusa instantanea sobre edificios y POIs en memoria. |
| `dispose()` | Libera los recursos y listeners activos del controlador. |

---

### Motores de Procesamiento

#### 1. `RouteEngine`
- Algoritmo A* heuristico con distancia euclidiana esferica.
- Filtrado de aristas en tiempo real segun `NavigationMode`.
- Ensamblado de indicaciones giro a giro (ej. "En 30 metros, gire a la derecha hacia Edificio T-4").

#### 2. `SearchEngine`
- Normalizacion de texto: eliminacion de diacriticos, acentos y conversion a minusculas.
- Indice de coincidencia invertido para nombres, codigos de edificio y descripciones.
- Ordenamiento ponderado: coincidencia exacta de codigo > coincidencia de nombre > descripcion.

#### 3. `CampusDataRepository`
- Carga asincrona paralela de los activos GeoJSON y JSON.
- Cache en memoria inmutable para consultas rapidas.

---

### Algoritmos del Core

#### 1. `AStarNavigator`
- Utiliza una cola de prioridad basada en monticulo binario (`CustomPriorityQueue`) logrando complejidad `O(E log V)`.

#### 2. `SnapToPath`
- Proyecta un punto `P(lat, lng)` sobre un segmento de recta `AB` en coordenadas cartesianas locales.
- Valida si el pie de la perpendicular cae dentro del segmento; en caso contrario, toma el vertice mas cercano.

#### 3. `DistanceCalculator`
- Implementacion estricta de la formula de Haversine con radio terrestre promedio `R = 6,371,000 m`.
- Estimacion de tiempos de traslado:
  - Peatonal: 1.2 m/s (~4.3 km/h).
  - Bicicleta: 3.5 m/s (~12.6 km/h).
  - Vehiculo: 5.5 m/s (~20 km/h, limite campus).

---

### Widgets de Presentacion

#### `MapView`
Lienzo interactivo construido sobre `flutter_map`. Renderiza:
- Capa base de teselas OpenStreetMap locales o en linea con proteccion de limites (`exactCampusBounds`).
- Capa de poligonos (`PolygonLayer`) con colores clasificados segun el tipo de instalacion.
- Capa de polilinea (`PolylineLayer`) con estilo distintivo para la ruta activa.
- Capa de marcadores (`MarkerLayer`) para POIs, accesos y ubicacion del usuario.

#### `TurnByTurnBanner`
Banner superior flotante con animaciones que muestra la instruccion inmediata, distancia restante al proximo giro e icono de maniobra.

#### `FloorSelector`
Botonera vertical flotante que se activa automaticamente cuando el usuario enfoca un edificio con planos interiores, permitiendo alternar pisos (ej. S, 1, 2, 3).

#### `PoiDetailSheet`
Panel modal deslizable (BottomSheet) con el nombre del edificio, fotografia o silueta, facultades residentes, cantidad de niveles y boton directo de "Como llegar".

---

## Guia de Integracion y Ejemplos

### Ejemplo Completo de Pantalla de Mapa

```dart
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:usac_campus_map/usac_campus_map.dart';

class UsacMapScreen extends StatefulWidget {
  const UsacMapScreen({Key? key}) : super(key: key);

  @override
  State<UsacMapScreen> createState() => _UsacMapScreenState();
}

class _UsacMapScreenState extends State<UsacMapScreen> {
  UsacCampusMapController? _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeCampusMap();
  }

  Future<void> _initializeCampusMap() async {
    final repository = CampusDataRepository();
    await repository.loadData();

    final routeEngine = RouteEngine(repository.campusGraph);
    final searchEngine = SearchEngine(repository.buildings, repository.pois);

    final controller = UsacCampusMapController(
      repository: repository,
      routeEngine: routeEngine,
      searchEngine: searchEngine,
    );

    setState(() {
      _controller = controller;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _controller == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: UsacMapTheme.primaryBlue),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Central USAC'),
        backgroundColor: UsacMapTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MapView(
            controller: _controller!,
            showUserLocation: true,
            theme: UsacMapTheme.standardTheme(),
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: TurnByTurnBanner(controller: _controller!),
          ),
          Positioned(
            right: 16,
            bottom: 120,
            child: FloorSelector(controller: _controller!),
          ),
          PoiDetailSheet(controller: _controller!),
        ],
      ),
    );
  }
}
```

---

## Protocolo de Actualizacion y Mantenimiento

Para asegurar que cualquier cambio futuro mantenga la integridad del proyecto, siga este protocolo:

### 1. Agregar o Modificar Edificios
- Modifique unicamente `assets/geojson/usac_buildings.geojson`.
- Si el edificio proviene de OpenStreetMap, verifique si es un `way` o una `relation` (multipoligono) para asegurar que todos los vertices del anillo exterior esten incluidos.
- Asigne siempre un `id` unico y normalizado (ej. `T-1`, `S-2`, `PRK-ING`).

### 2. Actualizar la Red de Caminos
- Edite `assets/graph/campus_graph.json`.
- Cada nodo debe tener coordenadas reales sobre andadores existentes.
- Cada arista debe ser bidireccional si el andador no tiene restriccion de sentido.
- Configure `isAccessible: false` si el tramo contiene gradas o escalinatas.

### 3. Agregar Nuevos Niveles Interiores (Indoor)
- Modifique `assets/pois/usac_pois_and_indoors.json`.
- Especifique el `buildingId` exacto, el `floorNumber` y el listado de aulas o laboratorios correspondientes.

### 4. Reglas Estrictas de Desarrollo
- **Cero comentarios en codigo Dart:** No utilizar `//`, `/* */` ni `///`. El codigo debe ser autoexplicativo mediante nombres claros y tipado riguroso.
- **Cero emojis:** No usar emojis en codigo, mensajes de commit, archivos markdown ni registros de consola.
- **Compatibilidad Offline:** No introducir llamadas HTTP externas requeridas para el funcionamiento basico.

---

## Validacion y Cobertura de Pruebas

El repositorio cuenta con 27 pruebas automatizadas organizadas por subsistema:

```bash
# Ejecutar todas las pruebas unitarias y de widgets
flutter test

# Ejecutar validacion estatica del codigo
flutter analyze
```

### Detalle de Suites de Pruebas
1. `test/ground_truth_dataset_test.dart`: Verifica que los archivos GeoJSON y JSON contengan las 248 entidades, los edificios clave (T-1, T-5, T-12, S-1, M-4, etc.), los 27 parqueos y las garitas oficiales.
2. `test/core_algorithms_test.dart`: Prueba unitaria de `AStarNavigator`, `CustomPriorityQueue`, `SnapToPath` y `DistanceCalculator`.
3. `test/engine_test.dart`: Valida la planificacion de rutas multi-modal y las consultas difusas del buscador.
4. `test/controller_and_widgets_test.dart`: Valida el montaje de `MapView`, `FloorSelector`, `PoiDetailSheet` y las emisiones reactivas del `UsacCampusMapController`.
