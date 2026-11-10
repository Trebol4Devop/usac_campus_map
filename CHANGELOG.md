## 0.5.0

- Sistema de comunidad estudiantil: reseñas, calificaciones y foro de discusión por edificio y POI (`CampusCommunityRepository`, `CampusReview`, `CampusComment`).
- Sistema de clasificación personalizable por categoría con rangos de evaluación, emojis y etiquetas (`RatingClassificationConfig`, `RatingClassificationBadge`).
- Integración en `PoiDetailSheet` con navegación por pestañas (Detalles, Reseñas, Foro Comunitario).
- Guía exhaustiva de implementación para aplicaciones cliente en `docs/guia_implementacion_cliente.md`.
- Desacople y remoción de visualización volumétrica y modelos 3D a favor de renderizado vectorial 2D liviano y de alto rendimiento.

## 0.4.0

- Fase 9: Implementacion de motor de proyeccion visual para Realidad Aumentada (ArProjectionEngine) con evaluacion de campo de vision (FOV), rumbo y elevacion.
- Modelado geometrico tridimensional volumetrico de edificios del campus (Building3DModel, Polygon3D, Vector3D).
- Componentes de interfaz de usuario para realidad aumentada (ArWayfindingView) y visor 3D interactivo con rotacion gestual (Building3DViewer).
- Suite de pruebas unitarias y de widgets para componentes 3D y de realidad aumentada.

## 0.3.0

- Fase 8: Motor de navegacion giro a giro en tiempo real (RealtimeNavigationEngine) con seguimiento continuo de GPS y proyeccion dinamica a la ruta.
- Deteccion automatica de desviacion de ruta ante alejamiento superior a 15 metros y recalculacion automatica hacia el destino.
- Sistema de notificaciones por voz e instrucciones habladas en espanol (NavigationVoiceNotifier).
- Estado inmutable de telemetria de navegacion (NavigationTrackingState) y adaptacion reactiva de TurnByTurnBanner.
- Orientacion visual del usuario con flecha de rumbo segun magnetometro/brujula.

## 0.2.0

- Fase 7: Modulo de calculo matematico de coordenadas y rangos de teselas slippy map (TileIndex).
- Empaquetado y metadatos de teselas offline para el campus central de la USAC (OfflineTilePackage).
- Proveedor de teselas fuera de linea para flutter_map (CampusOfflineTileProvider) con garantias de cero peticiones de red.
- Extension de UsacMapTheme para soporte de modo puramente offline.

## 0.1.0

- Migracion integral a arquitectura de motores offline de cero costo operativo (Cero USD).
- Integracion del catalogo de 248 entidades espaciales autovaciadas de OpenStreetMap (edificios, parqueos, canchas y plazas).
- Resolucion de siluetas de edificios estructurados en relaciones multipoligono de OSM (T-1, T-5, T-12, S-1, S-6, S-7, S-11, M-4, M-5, M-6, M-7, Bienestar Estudiantil).
- Incorporacion de 27 zonas oficiales de parqueo georreferenciadas.
- Integracion de garitas de acceso vehicular y peatonal (Periferico, Petapa, Las Charcas) como nodos POI sobre la red vial sin geometrias ficticias.
- Motor de ruteo A* multimodal con soporte para andadores peatonales, bicicletas, vehiculos y rutas accesibles.
- Implementacion de algoritmo de proyeccion ortogonal a trayectoria (SnapToPath).
- Motor de busqueda difusa indexada en memoria (SearchEngine).
- Controlador reactivo UsacCampusMapController y componentes visuales (MapView, FloorSelector, PoiDetailSheet, TurnByTurnBanner).
- Suite de pruebas unitarias y de widgets completa.
