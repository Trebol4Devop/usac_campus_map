import 'package:flutter/material.dart' hide NavigationMode;
import 'package:usac_campus_map/usac_campus_map.dart';

void main() {
  runApp(const UsacCampusMapExampleApp());
}

class UsacCampusMapExampleApp extends StatelessWidget {
  const UsacCampusMapExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'USAC Campus Map',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF002B49)),
        useMaterial3: true,
      ),
      home: const CampusMapHomePage(),
    );
  }
}

class CampusMapHomePage extends StatefulWidget {
  const CampusMapHomePage({super.key});

  @override
  State<CampusMapHomePage> createState() => _CampusMapHomePageState();
}

class _CampusMapHomePageState extends State<CampusMapHomePage> {
  final UsacCampusMapController _mapController = UsacCampusMapController();
  final TextEditingController _searchFieldController = TextEditingController();

  bool _isSearching = false;
  String _selectedCategory = '';
  NavigationMode _activeMode = NavigationMode.pedestrian;

  final List<String> _categories = const [
    'faculty',
    'library',
    'administrative',
    'cajeros',
    'cafeterias',
    'sanitarios',
    'laboratorios',
    'aulas',
    'sports',
  ];

  @override
  void initState() {
    super.initState();
    _mapController.loadData();
    _mapController.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _mapController.removeListener(_onControllerChanged);
    _mapController.dispose();
    _searchFieldController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  void _onModeChanged(NavigationMode mode) {
    setState(() {
      _activeMode = mode;
    });
    _mapController.setNavigationMode(mode);
    final modeNames = {
      NavigationMode.pedestrian: 'Modo Peatonal activado',
      NavigationMode.accessible: 'Modo Accesible (sin gradas) activado',
      NavigationMode.covered: 'Modo Techado (pasillos cubiertos) activado',
      NavigationMode.vehicle: 'Modo Vehiculo activado',
    };
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(modeNames[mode] ?? 'Modo actualizado'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showRoutePlannerDialog() {
    final buildings = _mapController.buildings;
    if (buildings.length < 2) return;

    CampusBuilding selectedOrigin = buildings.firstWhere(
      (b) => b.id == 't-3',
      orElse: () => buildings[0],
    );
    CampusBuilding selectedDest = buildings.firstWhere(
      (b) => b.id == 'biblio-central',
      orElse: () => buildings[1],
    );
    NavigationMode dialogMode = _activeMode;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
              ),
              padding: EdgeInsets.only(
                left: 20.0,
                right: 20.0,
                top: 20.0,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.alt_route, color: Color(0xFF002B49)),
                        const SizedBox(width: 8.0),
                        const Text(
                          'Planificador de Rutas USAC',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF002B49),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    DropdownButtonFormField<CampusBuilding>(
                      decoration: const InputDecoration(
                        labelText: 'Origen',
                        prefixIcon: Icon(Icons.trip_origin, color: Colors.green),
                        border: OutlineInputBorder(),
                      ),
                      initialValue: selectedOrigin,
                      isExpanded: true,
                      items: buildings
                          .map((b) => DropdownMenuItem(
                                value: b,
                                child: Text(b.name, overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedOrigin = val);
                      },
                    ),
                    const SizedBox(height: 12.0),
                    DropdownButtonFormField<CampusBuilding>(
                      decoration: const InputDecoration(
                        labelText: 'Destino',
                        prefixIcon: Icon(Icons.location_on, color: Colors.red),
                        border: OutlineInputBorder(),
                      ),
                      initialValue: selectedDest,
                      isExpanded: true,
                      items: buildings
                          .map((b) => DropdownMenuItem(
                                value: b,
                                child: Text(b.name, overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedDest = val);
                      },
                    ),
                    const SizedBox(height: 16.0),
                    const Text(
                      'Modo de Transporte:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8.0),
                    SegmentedButton<NavigationMode>(
                      segments: const [
                        ButtonSegment(
                          value: NavigationMode.pedestrian,
                          icon: Icon(Icons.directions_walk),
                          label: Text('Peatonal'),
                        ),
                        ButtonSegment(
                          value: NavigationMode.accessible,
                          icon: Icon(Icons.accessible),
                          label: Text('Accesible'),
                        ),
                        ButtonSegment(
                          value: NavigationMode.covered,
                          icon: Icon(Icons.roofing),
                          label: Text('Techado'),
                        ),
                        ButtonSegment(
                          value: NavigationMode.vehicle,
                          icon: Icon(Icons.directions_car),
                          label: Text('Vehículo'),
                        ),
                      ],
                      selected: {dialogMode},
                      onSelectionChanged: (set) {
                        setModalState(() {
                          dialogMode = set.first;
                        });
                      },
                    ),
                    const SizedBox(height: 20.0),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF002B49),
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      icon: const Icon(Icons.route),
                      label: const Text(
                        'Calcular Ruta Óptima',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: selectedOrigin.id != selectedDest.id
                          ? () {
                              Navigator.of(context).pop();
                              setState(() {
                                _activeMode = dialogMode;
                              });
                              _mapController.startRouteBetweenBuildings(
                                origin: selectedOrigin,
                                destination: selectedDest,
                                mode: dialogMode,
                              );
                            }
                          : null,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showCommunityDialog() {
    final buildings = _mapController.buildings;
    if (buildings.isEmpty) return;

    final target = _mapController.selectedBuilding ??
        buildings.firstWhere(
          (b) => b.id == 't-3',
          orElse: () => buildings.first,
        );

    PoiDetailSheet.show(
      context: context,
      building: target,
      currentFloor: _mapController.selectedFloor,
      userLocation: _mapController.userLocation,
      communityRepository: _mapController.communityRepository,
      initialTabIndex: 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = _mapController.searchResults;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchFieldController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Buscar edificio, alias (El Iglú, T-3, 5B)...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  _mapController.search(val, category: _selectedCategory.isEmpty ? null : _selectedCategory);
                },
              )
            : const Text(
                'Campus Central USAC',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
        backgroundColor: const Color(0xFF002B49),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.white),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchFieldController.clear();
                  _mapController.search('');
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          IconButton(
            tooltip: 'Reseñas y Foro Comunitario',
            icon: const Icon(Icons.rate_review, color: Colors.white),
            onPressed: _showCommunityDialog,
          ),
          IconButton(
            tooltip: 'Trazar ruta entre edificios',
            icon: const Icon(Icons.alt_route, color: Colors.white),
            onPressed: _showRoutePlannerDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          UsacCampusMap(
            controller: _mapController,
            theme: const UsacMapTheme(
              primaryColor: Color(0xFF002B49),
              accentColor: Color(0xFFD4AF37),
            ),
          ),
          Positioned(
            top: _mapController.currentRoute != null ? 85.0 : 10.0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 40.0,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: FilterChip(
                      label: const Text('Todos'),
                      selected: _selectedCategory.isEmpty,
                      onSelected: (_) {
                        setState(() => _selectedCategory = '');
                        if (_isSearching) {
                          _mapController.search(_searchFieldController.text);
                        }
                      },
                    ),
                  ),
                  ..._categories.map((cat) {
                    final isSel = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: FilterChip(
                        label: Text(cat.toUpperCase()),
                        selected: isSel,
                        onSelected: (_) {
                          setState(() {
                            _selectedCategory = isSel ? '' : cat;
                          });
                          if (_isSearching) {
                            _mapController.search(
                              _searchFieldController.text,
                              category: isSel ? null : cat,
                            );
                          }
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          if (_isSearching && _searchFieldController.text.isNotEmpty)
            Positioned(
              top: 55.0,
              left: 16.0,
              right: 16.0,
              bottom: 100.0,
              child: Material(
                elevation: 8.0,
                borderRadius: BorderRadius.circular(16.0),
                color: Colors.white,
                child: ListView.separated(
                  itemCount: searchResults.length,
                  separatorBuilder: (_, __) => const Divider(height: 1.0),
                  itemBuilder: (context, idx) {
                    final item = searchResults[idx];
                    return ListTile(
                      title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(item.subtitle),
                      trailing: item.matchedAlias != null
                          ? Chip(
                              label: Text('Alias: ${item.matchedAlias}'),
                              labelStyle: const TextStyle(fontSize: 10.0),
                            )
                          : null,
                      onTap: () {
                        setState(() {
                          _isSearching = false;
                        });
                        if (item.building != null) {
                          _mapController.selectBuilding(item.building!.id);
                        } else if (item.poi != null) {
                          _mapController.selectPoi(item.poi);
                        }
                      },
                    );
                  },
                ),
              ),
            ),
          Positioned(
            left: 16.0,
            bottom: 24.0,
            child: Material(
              elevation: 4.0,
              borderRadius: BorderRadius.circular(24.0),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _modeButton(NavigationMode.pedestrian, Icons.directions_walk, 'Peatonal'),
                    _modeButton(NavigationMode.accessible, Icons.accessible, 'Accesible'),
                    _modeButton(NavigationMode.covered, Icons.roofing, 'Techado'),
                    _modeButton(NavigationMode.vehicle, Icons.directions_car, 'Vehículo'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeButton(NavigationMode mode, IconData icon, String tooltip) {
    final isSelected = _activeMode == mode;
    return IconButton(
      tooltip: tooltip,
      icon: Icon(icon),
      color: isSelected ? const Color(0xFF002B49) : Colors.grey,
      style: isSelected
          ? IconButton.styleFrom(
              backgroundColor: const Color(0xFF002B49).withValues(alpha: 0.12),
            )
          : null,
      onPressed: () => _onModeChanged(mode),
    );
  }
}
