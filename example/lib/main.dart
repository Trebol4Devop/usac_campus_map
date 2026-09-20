import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:usac_campus_map/usac_campus_map.dart';

void main() {
  runApp(const UsacCampusMapExampleApp());
}

class UsacCampusMapExampleApp extends StatelessWidget {
  const UsacCampusMapExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'USAC Campus Map Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF002B49)),
        useMaterial3: true,
      ),
      home: const CampusMapDemoPage(),
    );
  }
}

class CampusMapDemoPage extends StatefulWidget {
  const CampusMapDemoPage({super.key});

  @override
  State<CampusMapDemoPage> createState() => _CampusMapDemoPageState();
}

class _CampusMapDemoPageState extends State<CampusMapDemoPage> {
  final CampusSearchService _searchService = CampusSearchService();
  final UsacCampusMapController _mapController = UsacCampusMapController();
  BuildingCategory? _selectedCategory;
  String _searchQuery = '';
  bool _showBoundary = true;
  LatLng? _currentUserPosition;
  CampusBuilding? _navigatingDestination;

  List<CampusBuilding> get _filteredBuildings {
    return _searchService.search(
      query: _searchQuery,
      category: _selectedCategory,
    );
  }

  void _onBuildingTap(CampusBuilding building) {
    _mapController.highlightBuilding(building.id);
    BuildingDetailModal.show(
      context: context,
      building: building,
      referencePosition: _currentUserPosition,
      onNavigate: () {
        Navigator.of(context).pop();
        setState(() {
          _navigatingDestination = building;
        });
      },
    );
  }

  void _showRoutePlannerSheet() {
    CampusBuilding? selectedOrigin = UsacCampusDataset.getById('t-3');
    CampusBuilding? selectedDestination =
        UsacCampusDataset.getById('biblio-central');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final allBuildings = UsacCampusDataset.allBuildings;

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.alt_route, color: Color(0xFF002B49)),
                      const SizedBox(width: 8),
                      const Text(
                        'Planificador de Rutas Peatonales',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF002B49),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(modalContext).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<CampusBuilding>(
                    decoration: const InputDecoration(
                      labelText: 'Edificio de Origen',
                      prefixIcon: Icon(Icons.trip_origin, color: Colors.green),
                      border: OutlineInputBorder(),
                    ),
                    value: selectedOrigin,
                    isExpanded: true,
                    items: allBuildings
                        .map(
                          (b) => DropdownMenuItem(
                            value: b,
                            child: Text(
                              b.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      setModalState(() {
                        selectedOrigin = val;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<CampusBuilding>(
                    decoration: const InputDecoration(
                      labelText: 'Edificio de Destino',
                      prefixIcon: Icon(Icons.location_on, color: Colors.red),
                      border: OutlineInputBorder(),
                    ),
                    value: selectedDestination,
                    isExpanded: true,
                    items: allBuildings
                        .map(
                          (b) => DropdownMenuItem(
                            value: b,
                            child: Text(
                              b.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      setModalState(() {
                        selectedDestination = val;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF002B49),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.directions_walk),
                    label: const Text('Trazar Ruta Peatonal'),
                    onPressed: (selectedOrigin != null &&
                            selectedDestination != null &&
                            selectedOrigin != selectedDestination)
                        ? () {
                            Navigator.of(modalContext).pop();
                            setState(() {
                              _navigatingDestination = null;
                            });
                            _mapController.startRouteBetweenBuildings(
                              origin: selectedOrigin!,
                              destination: selectedDestination!,
                            );
                          }
                        : null,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buildings = _filteredBuildings;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Campus Central USAC',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF002B49),
        actions: [
          IconButton(
            tooltip: 'Planificar ruta entre edificios',
            icon: const Icon(Icons.alt_route, color: Colors.white),
            onPressed: _showRoutePlannerSheet,
          ),
          IconButton(
            tooltip: _showBoundary ? 'Ocultar perimetro' : 'Mostrar perimetro',
            icon: Icon(
              _showBoundary ? Icons.layers : Icons.layers_outlined,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _showBoundary = !_showBoundary;
              });
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: CampusSearchBar(
            hintText: 'Buscar edificio, sigla (T-3, S-2, Rectoria)...',
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
          ),
        ),
      ),
      body: Stack(
        children: [
          UsacCampusMap(
            controller: _mapController,
            buildings: buildings,
            showCampusBoundary: _showBoundary,
            routeDestination: _navigatingDestination,
            onClearRoute: () {
              setState(() {
                _navigatingDestination = null;
              });
              _mapController.clearRoute();
            },
            onBuildingTap: _onBuildingTap,
            onUserLocationTap: (loc) =>
                setState(() => _currentUserPosition = loc),
            onUserLocationChanged: (loc) =>
                setState(() => _currentUserPosition = loc),
          ),
          Positioned(
            top: (_navigatingDestination != null ||
                    _mapController.currentRoute != null)
                ? 76
                : 10,
            left: 0,
            right: 0,
            child: CategoryFilterChips(
              selectedCategory: _selectedCategory,
              onCategorySelected: (cat) {
                setState(() {
                  _selectedCategory = cat;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
