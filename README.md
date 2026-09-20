# usac_campus_map

Libreria modular y privada en Flutter para la visualizacion interactiva del mapa del Campus Central de la Universidad de San Carlos de Guatemala (USAC), delimitacion perimetral, recorte cartografico exclusivo, calculo de rutas peatonales por andadores, consulta de puntos de interes (POIs) y seguimiento de geolocalizacion en tiempo real.

---

## Caracteristicas Principales

- **Cartografia Exclusiva del Campus Central:** Capacidad de recorte visual inverso (`clipToCampus`) que enmascara el exterior del campus y proyecta unicamente el area oficial universitaria con borde institucional azul USAC (`#002B49`).
- **Navegacion y Delimitacion Espacial Estricta:** Restriccion de camara (`cameraConstraint`) y limite de descarga de teselas (`tileBounds`) a la extension exacta de la universidad (`exactCampusBounds`).
- **Catalogo Oficial Georreferenciado:** Mas de 45 puntos de interes estructurados en 9 categorias tematicas con coordenadas exactas verificadas sobre OpenStreetMap.
- **Enrutamiento Peatonal por Andadores (`CampusRouteService`):** Algoritmo de navegacion a pie guiado por la red de senderos y pasarelas internas del campus, calculando la distancia real y tiempo estimado de caminata.
- **Geolocalizacion Reactiva e Inclusiva:** Deteccion satelital en tiempo real (`CampusLocationService`) con verificacion de permanencia en el campus mediante Ray Casting (`isInsideCampus`) y deteccion pasiva sin forzar solicitudes de permisos si el hardware esta desactivado.
- **Buscador Inteligente y Filtros:** Busqueda por coincidencias difusas en nombres, siglas y facultades (`CampusSearchService`), complementado con selectores de categorias individuales o multiples.
- **Componentes Modulares Reutilizables:** Widgets independientes (`UsacCampusMap`, `CampusSearchBar`, `CategoryFilterChips`, `BuildingDetailModal`) listos para ser ensamblados en cualquier aplicacion estudiantil o administrativa.

---

## Inventario Oficial de Edificios y Puntos Georreferenciados

La libreria cuenta con mas de 45 puntos de interes georreferenciados con exactitud de centroide:

### 1. Facultad de Arquitectura (FARUSAC)
- **`T-1` (Talleres de Arquitectura):** Talleres de diseno arquitectonico, salones de dibujo tecnico, modelado y maquetas.
- **`T-2` (Sede Central FARUSAC):** Decanatura de Arquitectura, Direccion de la Escuela de Diseno Grafico, coordinacion academica y administracion.
- **`PRK-ARQ` (Estacionamiento Arquitectura):** Area de parqueo vehicular contigua a los edificios T-1 y T-2.

### 2. Facultad de Ingenieria (FIUSAC)
- **`T-3` (Sede Central FIUSAC):** Decanatura de Ingenieria, Escuelas de Ingenieria Civil e Ingenieria Mecanica, Centro de Computo y oficinas administrativas.
- **`T-4` (Ingenieria Quimica e Industrial):** Escuelas de Ingenieria Quimica e Industrial, coordinacion de Ejercicio Profesional Supervisado (EPS).
- **`T-6` (Aulas de Ingenieria):** Modulo de catedra, salones docentes y aulas para ciclos intermedios.
- **`T-7` (Talleres de Mecanica):** Talleres de manufactura, soldadura, metrologia, maquinas herramientas y fundicion.
- **`CII` (Centro de Investigaciones de Ingenieria):** Ensayos estructurales, sismologia, investigacion aplicada y desarrollo tecnologico.
- **`ERIS` (Escuela Regional de Ingenieria Sanitaria):** Posgrados en recursos hidricos, tratamiento de aguas y saneamiento ambiental.
- **`CANCHA-ING` (Cancha de Ingenieria):** Area recreativa polideportiva adyacente a T-3 y T-4.
- **`PRK-ING` (Estacionamiento Ingenieria):** Area de parqueo vehicular y de motocicletas del sector tecnologico.

### 3. Facultad de Odontologia
- **`M-1` (Sede Central Odontologia):** Decanatura de Odontologia, aulas magnas y auditorios de docencia.
- **`M-2` (Clinicas Integrales Odontologicas):** Modulo de clinicas dentales abiertas a atencion estudiantil y del publico general.
- **`M-3` (Laboratorios Odontologicos):** Laboratorios de protesis dental, radiologia, biomateriales y ortodoncia.

### 4. Facultad de Ciencias Quimicas y Farmacia
- **`T-15` (Sede Central Farmacia):** Decanatura de Ciencias Quimicas y Farmacia y Auditorio Principal.
- **`T-10` (Escuela de Biologia):** Aulas docentes, herbarios y laboratorios de investigacion biologica.
- **`T-11` (Escuela de Nutricion):** Laboratorios de bromatologia, evaluacion nutricional y aulas docentes.
- **`T-13` (Planta Piloto):** Planta de procesamiento farmaceutico, industrializacion de medicamentos y control microbiologico.
- **`T-14` (Laboratorios Especializados):** Laboratorios de analisis instrumental y control de calidad quimico.

### 5. Facultad de Agronomia (FAUSAC)
- **`T-8` (Docencia Agronomia):** Secretaria Academica de Agronomia, aulas tecnicas y coordinaciones docentes.
- **`T-9` (Sede Central FAUSAC):** Decanatura de Agronomia, administracion central y departamentos tecnicos.
- **`UVIGER` (Laboratorios Tecnicos):** Unidad de Vinculacion y Laboratorios de Suelos, Fitopatologia y Biotecnologia.
- **`CEDA` (Centro Experimental Docente):** Campos de cultivo, invernaderos, viveros y parcelas demostrativas.
- **`PRK-AGRO` (Estacionamiento Agronomia):** Aparcamiento docente y estudiantil de ciencias agropecuarias.

### 6. Facultad de Medicina Veterinaria y Zootecnia (FMVZ)
- **`M-8` (Hospital Veterinario Universitario):** Hospital Veterinario (HVAC) con atencion a especies menores y mayores, quirofanos y clinicas.

### 7. Area de Ciencias Sociales y Humanidades
- **`S-2` (Facultad de Ciencias Juridicas y Sociales):** Decanatura de Derecho, bufete popular y salas de juicios orales simulados.
- **`S-3` (Facultad de Ciencias Economicas):** Decanatura de Economicas, Escuelas de Auditoria, Economia y Administracion de Empresas.
- **`S-4` (Escuela de Ciencias de la Comunicacion):** Sede de la ECC, cabinas de grabacion de audio, radio universitaria y set de television.
- **`S-5` (Escuela de Trabajo Social):** Docencia e investigacion social comunitaria.
- **`S-8` (Posgrados Sociales):** Escuela de Estudios de Posgrado de las areas economica y social.
- **`S-9` (Escuela de Historia):** Antropologia, arqueologia, historia y archivo documental de investigaciones.
- **`S-10` (Facultad de Humanidades):** Decanatura de Humanidades, Departamentos de Pedagogia, Letras, Filosofia y Arte.
- **`S-12` y `ANEXO-S12` (EFPEM):** Escuela de Formacion de Profesores de Ensenanza Media y profesorados tecnicos.
- **`S-13` (CALUSAC):** Escuela de Ciencias Linguisticas y Centro de Aprendizaje de Lenguas.

### 8. Area Administrativa, Institucional y Cultural
- **`RECT` (Edificio de Rectoria):** Sede central del gobierno universitario y Consejo Superior Universitario (CSU).
- **`PLAZA` (Plaza de los Martires):** Plaza civica e historica de concentracion de la comunidad universitaria.
- **`BIBLIO` (Biblioteca Central Cesar Branas):** Acervo bibliografico general, hemeroteca, salas de tesis y repositorio digital.
- **`CAJA` (Caja Central):** Tesoreria, departamento de caja y gestion financiera universitaria.
- **`RyE` (Registro y Estadistica):** Matricula estudiantil, equivalencias, certificaciones de cursos y tramites de graduacion.
- **`IGLU` (Auditorio IGLU):** Auditorio de asambleas magistrales, congresos y actos de graduacion.
- **`BCIE` (Edificio USAC-BCIE):** Modulo de gestion institucional y cooperacion universitaria.
- **`EDITORIAL` (Editorial Universitaria):** Editorial, produccion y venta de textos y libros universitarios.
- **`AEU` (Sede AEU):** Asociacion de Estudiantes Universitarios Oliverio Castaneda de Leon.
- **`REY-CARLOS` (Colegio Rey Carlos II):** Centro educativo infantil para hijos de trabajadores y estudiantes USAC.
- **`CULTURA` (Casa de la Cultura de Agronomia):** Espacio cultural y extension comunitaria.

### 9. Salud y Asistencia Universitaria
- **`SALUD` (Centro de Salud y Farmacia Universitaria):** Atencion medica ambulatoria, farmacia social y atencion preventiva.
- **`M-2` (Clinicas Odontologicas):** Clinicas de atencion dental general y especializada.
- **`M-8` (Hospital Veterinario Universitario):** Atencion medica y quirurgica veterinaria.

### 10. Infraestructura Deportiva
- **`ESTADIO` (Estadio Revolucion):** Cancha de futbol reglamentaria, graderias principales y pista de atletismo.
- **`POLI` (Polideportivo Central):** Gimnasio cerrado para baloncesto, voleibol, futsal y entrenamientos.
- **`TENIS` (Canchas de Tenis USAC):** Canchas reglamentarias de tenis universitario.
- **`CANCHA-ING` (Cancha de Ingenieria):** Cancha polideportiva del sector T.

### 11. Movilidad, Garitas y Accesos Oficiales
- **`GAR-PER` (Garita Periferico):** Ingreso y egreso vehicular y peatonal del poniente (Anillo Periferico).
- **`GAR-PET` (Garita Petapa):** Acceso vehicular y pasarela peatonal del oriente (Avenida Petapa).
- **`GAR-SMR` (Garita San Marcos):** Control y acceso peatonal del sector norte.
- **`PRK-PER` (Estacionamiento Periferico):** Parqueo amplio del sector poniente.
- **`PRK-PET` (Estacionamiento Petapa):** Parqueo del sector oriente.

---

## Delimitacion Perimetral y Recorte Cartografico (`UsacCampusBoundary`)

La libreria incorpora la delimitacion espacial completa del terreno de la universidad mediante un poligono de 80 vertices georreferenciados:

- **Propiedad `campusPerimeter`:** Lista inmutable `List<LatLng>` con el perimetro oficial del campus central.
- **Metodo `isInsideCampus(LatLng point)`:** Algoritmo de punto en poligono (Ray Casting) para determinar si un dispositivo o coordenada esta dentro del territorio de la USAC.
- **Metodo `createCampusCutoutMask(...)`:** Construye un poligono de mascara inversa que cubre el cuadrante exterior completo y perfora un orificio con los vertices de `campusPerimeter`, recortando el mapa al area universitaria con borde azul `#002B49`.
- **Propiedad `defaultPerimeterPolygon`:** Poligono traslucido institucional para renderizado perimetral en `PolygonLayer`.
- **Propiedad `exactCampusBounds`:** Caja delimitadora cartografica (`LatLngBounds`) ajustada al perimetro universitario (Suroeste: `[14.5760, -90.5605]`, Noreste: `[14.5905, -90.5445]`).

---

## Arquitectura del Sistema

```mermaid
graph TD
    ClientApp["Aplicacion Consumidora"] -->|Importa| Barrel["usac_campus_map.dart (Barrel)"]
    
    subgraph usac_campus_map
        Barrel --> UsacMapWidget["UsacCampusMap (Widget)"]
        Barrel --> SearchBarWidget["CampusSearchBar (Widget)"]
        Barrel --> ChipsWidget["CategoryFilterChips (Widget)"]
        Barrel --> ModalWidget["BuildingDetailModal (Widget)"]
        Barrel --> BuildingModel["CampusBuilding (Model)"]
        Barrel --> CategoryEnum["BuildingCategory (Enum)"]
        Barrel --> RouteModel["CampusRoute (Model)"]
        Barrel --> Dataset["UsacCampusDataset (Data Catalog)"]
        Barrel --> Boundary["UsacCampusBoundary (Delimitacion Espacial)"]
        Barrel --> LocationSvc["CampusLocationService (Service)"]
        Barrel --> SearchSvc["CampusSearchService (Service)"]
        Barrel --> DistanceSvc["CampusDistanceService (Service)"]
        Barrel --> RouteSvc["CampusRouteService (Service)"]
        
        UsacMapWidget -->|Consume Stream GPS| LocationSvc
        UsacMapWidget -->|Carga POIs por Defecto| Dataset
        UsacMapWidget -->|Mascara de Recorte y Limites| Boundary
        UsacMapWidget -->|Calcula Ruta Peatonal| RouteSvc
        RouteSvc -->|Calcula Metros y Tiempos| DistanceSvc
        RouteSvc -->|Valida Limites de Origen/Destino| Boundary
        Dataset -->|Instancia| BuildingModel
        BuildingModel --> CategoryEnum
        UsacMapWidget -->|Renderiza Marcadores| BuildingModel
        ModalWidget -->|Calcula Metros y Tiempos| DistanceSvc
        SearchBarWidget -->|Dispara Consultas| SearchSvc
        LocationSvc -->|Verifica Pertenencia al Campus| Boundary
        LocationSvc -->|Hardware GPS| GeolocatorPlugin["Geolocator Engine"]
        UsacMapWidget -->|Teselas OpenStreetMap| FlutterMapEngine["FlutterMap Engine"]
    end
```

---

## Diagrama de Clases

```mermaid
classDiagram
    class BuildingCategory {
        <<enumeration>>
        faculty
        administrative
        library
        sports
        food
        parking
        access
        health
        generalAcademic
        +label String
    }

    class CampusBuilding {
        +String id
        +String name
        +String? acronym
        +LatLng location
        +String description
        +BuildingCategory category
        +int? floors
        +CampusBuilding(id, name, location, description, acronym, category, floors)
    }

    class CampusRoute {
        +LatLng origin
        +CampusBuilding destination
        +List~LatLng~ points
        +double distanceInMeters
        +Duration estimatedDuration
        +CampusRoute(origin, destination, points, distanceInMeters, estimatedDuration)
    }

    class UsacCampusDataset {
        +LatLng campusCenter$
        +List~CampusBuilding~ allBuildings$
        +getById(String id)$ CampusBuilding?
        +getByCategory(BuildingCategory category)$ List~CampusBuilding~
        +search(String query)$ List~CampusBuilding~
    }

    class UsacCampusBoundary {
        +List~LatLng~ campusPerimeter$
        +isInsideCampus(LatLng point)$ bool
        +createCampusCutoutMask(color, borderColor, borderStrokeWidth)$ Polygon
        +defaultPerimeterPolygon$ Polygon
        +exactCampusBounds$ LatLngBounds
        +defaultCameraBounds$ LatLngBounds
    }

    class CampusLocationService {
        +Stream~LatLng~ studentPositionStream
        +getCurrentPosition() Future~LatLng?~
    }

    class CampusSearchService {
        +search(query, category, categories) List~CampusBuilding~
    }

    class CampusDistanceService {
        +calculateDistance(point1, point2) double
        +calculateBuildingDistance(from, building) double
        +estimateWalkingDuration(distanceMeters) Duration
        +estimateCampusWalkingDuration(distanceMeters) Duration
        +formatDistance(distanceMeters) String
        +formatWalkingTime(duration) String
    }

    class CampusRouteService {
        +calculateRoute(origin, destination) CampusRoute?
    }

    class UsacCampusMap {
        +List~CampusBuilding~? buildings
        +Function(CampusBuilding)? onBuildingTap
        +Widget Function(BuildContext, CampusBuilding)? markerBuilder
        +LatLng? initialCenter
        +double initialZoom
        +double minZoom
        +double maxZoom
        +bool showCampusBoundary
        +bool clipToCampus
        +Color campusCutoutColor
        +List~Polygon~? customPolygons
        +List~Polyline~? customPolylines
        +CampusBuilding? routeDestination
        +CampusRoute? activeRoute
        +VoidCallback? onClearRoute
        +Color routeColor
        +double routeStrokeWidth
        +bool animateCameraTransitions
        +CameraConstraint? cameraConstraint
        +bool showOutOfCampusBanner
        +String? outOfCampusMessage
        +bool showRecenterCampusButton
        +bool showLocationButton
        +bool showZoomButtons
        +bool enableActiveTracking
        +ValueChanged~LatLng~? onUserLocationTap
        +ValueChanged~LatLng~? onUserLocationChanged
        +MapController? mapController
        +createState() _UsacCampusMapState
    }

    class CampusSearchBar {
        +TextEditingController? controller
        +ValueChanged~String~? onChanged
        +VoidCallback? onClear
        +String hintText
    }

    class CategoryFilterChips {
        +BuildingCategory? selectedCategory
        +Set~BuildingCategory~? selectedCategories
        +ValueChanged~BuildingCategory?~? onCategorySelected
        +ValueChanged~Set~BuildingCategory~~? onCategoriesChanged
        +bool isMultiSelect
    }

    class BuildingDetailModal {
        +CampusBuilding building
        +LatLng? referencePosition
        +VoidCallback? onNavigate
        +show(context, building, referencePosition, onNavigate)$ Future
    }

    CampusBuilding --> BuildingCategory
    CampusRoute --> CampusBuilding
    CampusRouteService ..> CampusRoute : construye
    CampusRouteService ..> CampusDistanceService : calcula metricas
    CampusRouteService ..> UsacCampusBoundary : valida perimetro
    UsacCampusDataset --> CampusBuilding
    UsacCampusMap ..> UsacCampusBoundary : aplica mascara y limites
    UsacCampusMap ..> CampusBuilding : renderiza marcadores
    UsacCampusMap ..> CampusRouteService : calcula rutas
    BuildingDetailModal ..> CampusBuilding : presenta informacion
    BuildingDetailModal ..> CampusDistanceService : calcula distancias
```

---

## Diagramas de Secuencia y Flujo de Datos

### Flujo 1: Busqueda y Filtrado Tematico de Edificios

```mermaid
sequenceDiagram
    autonumber
    actor Usuario
    participant SearchBar as CampusSearchBar
    participant Chips as CategoryFilterChips
    participant SearchService as CampusSearchService
    participant MapWidget as UsacCampusMap
    participant Modal as BuildingDetailModal

    Usuario->>SearchBar: Escribe termino ("T-3" o "Ingenieria")
    SearchBar->>SearchService: search(query: "T-3")
    SearchService-->>MapWidget: Lista filtrada de edificios
    Usuario->>Chips: Selecciona chip de categoria (faculty)
    Chips->>SearchService: search(query: "T-3", category: faculty)
    SearchService-->>MapWidget: Actualiza marcadores visibles en el mapa
    Usuario->>MapWidget: Toca marcador de edificio
    MapWidget->>Modal: BuildingDetailModal.show(context, building, referencePosition)
    Modal-->>Usuario: Ficha tecnica con distancia y tiempo a pie
```

### Flujo 2: Enrutamiento Peatonal por Andadores y Navegacion Activa

```mermaid
sequenceDiagram
    autonumber
    actor Usuario
    participant Modal as BuildingDetailModal
    participant MapWidget as UsacCampusMap
    participant RouteService as CampusRouteService
    participant Boundary as UsacCampusBoundary

    Usuario->>Modal: Presiona boton "Como llegar"
    Modal->>MapWidget: Dispara callback onNavigate con destino
    MapWidget->>RouteService: calculateRoute(origin: userLocation, destination: building)
    RouteService->>Boundary: isInsideCampus(origin) & isInsideCampus(destination)
    Boundary-->>RouteService: true (ambos puntos dentro del campus)
    RouteService->>RouteService: Mapea trayectoria por red de andadores universitarios
    RouteService-->>MapWidget: Instancia de CampusRoute (puntos, metros, tiempo)
    MapWidget->>MapWidget: Dibuja Polyline institucional sobre el mapa
    MapWidget->>MapWidget: Despliega tarjeta flotante de navegacion activa
    MapWidget->>MapWidget: Anima camara encuadrando la ruta completa
    Usuario->>MapWidget: Presiona icono cerrar en tarjeta de navegacion
    MapWidget->>MapWidget: Limpia la ruta activa y restablece vista
```

---

## Referencia de API

### 1. [`UsacCampusMap`](file:///C:/Users/emanu/Desktop/Programacion/ProyectosUniversidad/2025/Proyectos/usac_campus_map/lib/src/widgets/usac_campus_map.dart)
Widget principal que encapsula el motor cartografico `flutter_map` con configuraciones preestablecidas de alto rendimiento:
- `clipToCampus`: Booleano (`true` por defecto) que activa la mascara poligonal inversa para recortar el mapa al perimetro del campus.
- `campusCutoutColor`: Color del area exterior recortada (por defecto `Colors.white`).
- `cameraConstraint`: Restriccion de camara (`exactCampusBounds` por defecto) que previene el desplazamiento fuera del campus.
- `routeDestination`: Edificio destino para trazar ruta peatonal automatica desde la ubicacion actual del usuario.
- `activeRoute`: Instancia personalizada de `CampusRoute` inyectada directamente al mapa.
- `onClearRoute`: Callback disparado al descartar la ruta activa desde la tarjeta flotante.
- `routeColor`: Color de la polilinea de ruta (por defecto `#002B49`).
- `routeStrokeWidth`: Grosor de la linea de ruta (por defecto `4.5 px`).
- `markerBuilder`: Builder opcional para inyectar disenos personalizados en los marcadores de edificios.
- `showRecenterCampusButton`: Muestra boton flotante para recentrar el mapa en el centroide universitario.
- `showLocationButton`: Muestra boton flotante de geolocalizacion satelital.
- `enableActiveTracking`: Mantiene la camara centrada continuamente en la posicion del usuario mientras se desplaza.

### 2. [`CampusRouteService`](file:///C:/Users/emanu/Desktop/Programacion/ProyectosUniversidad/2025/Proyectos/usac_campus_map/lib/src/services/route_service.dart)
Servicio especializado en navegacion peatonal interna:
- `calculateRoute({required LatLng origin, required CampusBuilding destination})`: Calcula la trayectoria caminando por los andadores principales del campus, validando que el origen y destino se encuentren dentro del perimetro universitario. Retorna `CampusRoute?`.

### 3. [`UsacCampusBoundary`](file:///C:/Users/emanu/Desktop/Programacion/ProyectosUniversidad/2025/Proyectos/usac_campus_map/lib/src/data/usac_campus_boundary.dart)
Modulo de delimitacion geometrica y espacial:
- `isInsideCampus(LatLng point)`: Determina si una coordenada geografica esta contenida dentro del perimetro universitario.
- `createCampusCutoutMask(...)`: Genera el poligono de mascara inversa con orificio para recorte cartografico.
- `exactCampusBounds`: Bounding box que enmarca de forma ceñida la superficie universitaria.

### 4. [`CampusDistanceService`](file:///C:/Users/emanu/Desktop/Programacion/ProyectosUniversidad/2025/Proyectos/usac_campus_map/lib/src/services/distance_service.dart)
Servicio de mediciones metricas y tiempos:
- `calculateDistance(LatLng point1, LatLng point2)`: Distancia Haversine en metros.
- `estimateWalkingDuration(double distanceMeters)`: Estimacion de tiempo a pie a velocidad media universitaria (1.2 m/s).
- `formatDistance(double distanceMeters)`: Retorna formato legible (ej. "450 m" o "1.2 km").
- `formatWalkingTime(Duration duration)`: Retorna tiempo formateado (ej. "6 min" o "1 h 12 min").

### 5. [`CampusSearchService`](file:///C:/Users/emanu/Desktop/Programacion/ProyectosUniversidad/2025/Proyectos/usac_campus_map/lib/src/services/search_service.dart)
Motor de busqueda y filtrado:
- `search({String? query, BuildingCategory? category, Set<BuildingCategory>? categories, List<CampusBuilding>? source})`: Busqueda insensible a mayusculas y tildes con soporte de categorias unicas o multiples.

---

## Ejemplo Completo de Integracion

```dart
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:usac_campus_map/usac_campus_map.dart';

void main() {
  runApp(const MaterialApp(home: CampusScreen()));
}

class CampusScreen extends StatefulWidget {
  const CampusScreen({super.key});

  @override
  State<CampusScreen> createState() => _CampusScreenState();
}

class _CampusScreenState extends State<CampusScreen> {
  final CampusSearchService _searchService = CampusSearchService();
  BuildingCategory? _selectedCategory;
  String _searchQuery = '';
  CampusBuilding? _navigatingDestination;
  LatLng? _currentUserLocation;

  @override
  Widget build(BuildContext context) {
    final buildings = _searchService.search(
      query: _searchQuery,
      category: _selectedCategory,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Central USAC'),
        backgroundColor: const Color(0xFF002B49),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: CampusSearchBar(
            hintText: 'Buscar edificio (T-3, S-2, Rectoria)...',
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
        ),
      ),
      body: Stack(
        children: [
          UsacCampusMap(
            buildings: buildings,
            clipToCampus: true,
            routeDestination: _navigatingDestination,
            onClearRoute: () => setState(() => _navigatingDestination = null),
            onUserLocationChanged: (loc) => setState(() => _currentUserLocation = loc),
            onBuildingTap: (building) {
              BuildingDetailModal.show(
                context: context,
                building: building,
                referencePosition: _currentUserLocation,
                onNavigate: () {
                  Navigator.of(context).pop();
                  setState(() => _navigatingDestination = building);
                },
              );
            },
          ),
          Positioned(
            top: _navigatingDestination != null ? 76 : 10,
            left: 0,
            right: 0,
            child: CategoryFilterChips(
              selectedCategory: _selectedCategory,
              onCategorySelected: (cat) => setState(() => _selectedCategory = cat),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## Aplicacion de Demostracion (`example/`)

El subproyecto en [`example/`](file:///C:/Users/emanu/Desktop/Programacion/ProyectosUniversidad/2025/Proyectos/usac_campus_map/example) integra todos los componentes de la libreria en una aplicacion completa:
- `CampusSearchBar`: Buscador interactivo por nombre, sigla y dependencias asociadas.
- `CategoryFilterChips`: Barra deslizable de seleccion tematica por categoria.
- `UsacCampusMap`: Mapa reactivo con mascara de recorte perimetral, navegacion por andadores y controles flotantes.
- `BuildingDetailModal`: Ficha descriptiva modal con metricas de proximidad y accionador de navegacion guiada.

Para ejecutarla:
```bash
cd example
flutter run
```

---

## Suite de Pruebas Automatizadas

La libreria cuenta con una suite completa de pruebas unitarias y de widgets que cubren todos los servicios y componentes visuales:
```bash
flutter test
cd example && flutter test
```

---

## Licencia y Confidencialidad

Propiedad privada y confidencial de Trebol4Devop. Todos los derechos reservados.
Prohibida su distribucion, copia o modificacion sin autorizacion expresa.
Consulte el archivo `LICENSE` para conocer los terminos de propiedad intelectual.
