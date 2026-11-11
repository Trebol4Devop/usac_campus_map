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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF002B49),
          primary: const Color(0xFF002B49),
          secondary: const Color(0xFFD4AF37),
        ),
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

  final Map<String, (String, IconData)> _categoryMetadata = const {
    'faculty': ('Facultades', Icons.account_balance_rounded),
    'library': ('Bibliotecas', Icons.menu_book_rounded),
    'administrative': ('Administración', Icons.business_rounded),
    'cajeros': ('Cajeros', Icons.atm_rounded),
    'cafeterias': ('Cafeterías', Icons.restaurant_rounded),
    'sanitarios': ('Sanitarios', Icons.wc_rounded),
    'laboratorios': ('Laboratorios', Icons.science_rounded),
    'aulas': ('Aulas', Icons.meeting_room_rounded),
    'sports': ('Deportes', Icons.sports_soccer_rounded),
  };

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
      NavigationMode.vehicle: 'Modo Vehículo activado',
    };
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(modeNames[mode] ?? 'Modo actualizado'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
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
            final distMeters = DistanceCalculator.haversineDistance(
              selectedOrigin.center,
              selectedDest.center,
            );
            final walkMins = (distMeters / 75.0).ceil().clamp(1, 120);

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28.0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 20.0,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              padding: EdgeInsets.only(
                left: 20.0,
                right: 20.0,
                top: 12.0,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Grab Handle
                    Center(
                      child: Container(
                        width: 44.0,
                        height: 5.0,
                        margin: const EdgeInsets.only(bottom: 16.0),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFF002B49).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: const Icon(Icons.alt_route_rounded, color: Color(0xFF002B49)),
                        ),
                        const SizedBox(width: 10.0),
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
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),

                    // Selector Origen y Destino con diseño Google Maps
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Column(
                            children: [
                              const Icon(Icons.radio_button_checked, color: Colors.green, size: 20.0),
                              Container(
                                width: 2.0,
                                height: 28.0,
                                color: Colors.grey.shade300,
                              ),
                              const Icon(Icons.location_on, color: Colors.red, size: 22.0),
                            ],
                          ),
                          const SizedBox(width: 12.0),
                          Expanded(
                            child: Column(
                              children: [
                                DropdownButtonFormField<CampusBuilding>(
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                                    labelText: 'Punto de partida',
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
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
                                const SizedBox(height: 10.0),
                                DropdownButtonFormField<CampusBuilding>(
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                                    labelText: 'Destino',
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
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
                              ],
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          IconButton(
                            icon: const Icon(Icons.swap_vert_rounded, color: Color(0xFF002B49)),
                            tooltip: 'Invertir ruta',
                            onPressed: () {
                              setModalState(() {
                                final temp = selectedOrigin;
                                selectedOrigin = selectedDest;
                                selectedDest = temp;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16.0),

                    // Selector de Modo de Transporte
                    const Text(
                      'Modo de Transporte:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.0),
                    ),
                    const SizedBox(height: 8.0),
                    SegmentedButton<NavigationMode>(
                      segments: const [
                        ButtonSegment(
                          value: NavigationMode.pedestrian,
                          icon: Icon(Icons.directions_walk_rounded),
                          label: Text('Peatonal'),
                        ),
                        ButtonSegment(
                          value: NavigationMode.covered,
                          icon: Icon(Icons.roofing_rounded),
                          label: Text('Techado'),
                        ),
                        ButtonSegment(
                          value: NavigationMode.accessible,
                          icon: Icon(Icons.accessible_rounded),
                          label: Text('Accesible'),
                        ),
                        ButtonSegment(
                          value: NavigationMode.vehicle,
                          icon: Icon(Icons.directions_car_rounded),
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
                    const SizedBox(height: 14.0),

                    // Estimación de tiempo y distancia
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.timer_outlined, color: Color(0xFF002B49), size: 20.0),
                          const SizedBox(width: 8.0),
                          Text(
                            'Tiempo estimado: ~$walkMins min (${distMeters.round()} metros)',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF002B49),
                              fontSize: 13.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20.0),

                    // Botón de Calcular / Iniciar Ruta
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF002B49),
                        padding: const EdgeInsets.symmetric(vertical: 15.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.0),
                        ),
                      ),
                      icon: const Icon(Icons.navigation_rounded),
                      label: const Text(
                        'Iniciar Navegación Óptima',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.0),
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
    final hasActiveRoute = _mapController.currentRoute != null;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Capa de Mapa Full-Bleed
          UsacCampusMap(
            controller: _mapController,
            theme: const UsacMapTheme(
              primaryColor: Color(0xFF002B49),
              accentColor: Color(0xFFD4AF37),
            ),
          ),

          // 2. Capa Superior: Barra de Búsqueda Flotante y Chips de Filtro
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Barra de Búsqueda Flotante Material 3
                  Material(
                    elevation: 6.0,
                    shadowColor: Colors.black38,
                    borderRadius: BorderRadius.circular(28.0),
                    color: Colors.white,
                    child: Container(
                      height: 52.0,
                      padding: const EdgeInsets.symmetric(horizontal: 14.0),
                      child: Row(
                        children: [
                          const Icon(Icons.school_rounded, color: Color(0xFF002B49), size: 24.0),
                          const SizedBox(width: 10.0),
                          Expanded(
                            child: TextField(
                              controller: _searchFieldController,
                              style: const TextStyle(fontSize: 14.5, color: Colors.black87),
                              decoration: const InputDecoration(
                                hintText: 'Buscar edificio, alias (El Iglú, T-3)...',
                                hintStyle: TextStyle(color: Colors.black45, fontSize: 13.5),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              onChanged: (val) {
                                setState(() {
                                  _isSearching = val.isNotEmpty;
                                });
                                _mapController.search(
                                  val,
                                  category: _selectedCategory.isEmpty ? null : _selectedCategory,
                                );
                              },
                            ),
                          ),
                          if (_searchFieldController.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 20.0, color: Colors.grey),
                              onPressed: () {
                                _searchFieldController.clear();
                                setState(() {
                                  _isSearching = false;
                                });
                                _mapController.search('');
                              },
                            ),
                          IconButton(
                            tooltip: 'Reseñas del Campus',
                            icon: const Icon(Icons.star_rounded, color: Color(0xFFD4AF37), size: 24.0),
                            onPressed: _showCommunityDialog,
                          ),
                          IconButton(
                            tooltip: 'Trazar ruta',
                            icon: const Icon(Icons.directions_rounded, color: Color(0xFF002B49), size: 24.0),
                            onPressed: _showRoutePlannerDialog,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8.0),

                  // Fila de Filtros Rápidos (Chips Horizontales con Iconos)
                  SizedBox(
                    height: 38.0,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildFilterPill(
                          label: 'Todo',
                          icon: Icons.explore_rounded,
                          isSelected: _selectedCategory.isEmpty,
                          onTap: () {
                            setState(() => _selectedCategory = '');
                            if (_isSearching) {
                              _mapController.search(_searchFieldController.text);
                            }
                          },
                        ),
                        ..._categoryMetadata.entries.map((entry) {
                          final catKey = entry.key;
                          final (label, icon) = entry.value;
                          final isSel = _selectedCategory == catKey;
                          return _buildFilterPill(
                            label: label,
                            icon: icon,
                            isSelected: isSel,
                            onTap: () {
                              setState(() {
                                _selectedCategory = isSel ? '' : catKey;
                              });
                              if (_isSearching) {
                                _mapController.search(
                                  _searchFieldController.text,
                                  category: isSel ? null : catKey,
                                );
                              }
                            },
                          );
                        }),
                      ],
                    ),
                  ),

                  // 3. Resultados de búsqueda flotantes
                  if (_isSearching && _searchFieldController.text.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8.0),
                      constraints: const BoxConstraints(maxHeight: 280.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20.0),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 16.0,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20.0),
                        child: searchResults.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Center(
                                  child: Text(
                                    'No se encontraron lugares en el campus.',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                itemCount: searchResults.length,
                                separatorBuilder: (_, __) => const Divider(height: 1.0, color: Color(0xFFEEEEEE)),
                                itemBuilder: (context, idx) {
                                  final item = searchResults[idx];
                                  return ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(8.0),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF002B49).withValues(alpha: 0.08),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.place_rounded, color: Color(0xFF002B49), size: 20.0),
                                    ),
                                    title: Text(
                                      item.title,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.0),
                                    ),
                                    subtitle: Text(item.subtitle, style: const TextStyle(fontSize: 12.0)),
                                    trailing: item.matchedAlias != null
                                        ? Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(6.0),
                                            ),
                                            child: Text(
                                              'Alias: ${item.matchedAlias}',
                                              style: const TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF002B49),
                                              ),
                                            ),
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
                ],
              ),
            ),
          ),

          // 4. Barra inferior de Modo Activo / Ruta Activa
          Positioned(
            left: 16.0,
            bottom: 24.0,
            right: 16.0,
            child: hasActiveRoute
                ? _buildActiveRouteCard()
                : Align(
                    alignment: Alignment.bottomLeft,
                    child: _buildNavigationModeSelector(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: Material(
        elevation: isSelected ? 3.0 : 1.0,
        borderRadius: BorderRadius.circular(20.0),
        color: isSelected ? const Color(0xFF002B49) : Colors.white,
        child: InkWell(
          borderRadius: BorderRadius.circular(20.0),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(
                color: isSelected ? const Color(0xFFD4AF37) : Colors.grey.shade300,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16.0,
                  color: isSelected ? Colors.white : const Color(0xFF002B49),
                ),
                const SizedBox(width: 6.0),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationModeSelector() {
    return Material(
      elevation: 4.0,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(24.0),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _modeIconButton(NavigationMode.pedestrian, Icons.directions_walk_rounded, 'Peatonal'),
            _modeIconButton(NavigationMode.covered, Icons.roofing_rounded, 'Techado (lluvia)'),
            _modeIconButton(NavigationMode.accessible, Icons.accessible_rounded, 'Accesible'),
            _modeIconButton(NavigationMode.vehicle, Icons.directions_car_rounded, 'Vehicular'),
          ],
        ),
      ),
    );
  }

  Widget _modeIconButton(NavigationMode mode, IconData icon, String tooltip) {
    final isSelected = _activeMode == mode;
    return IconButton(
      tooltip: tooltip,
      icon: Icon(icon, size: 22.0),
      color: isSelected ? const Color(0xFF002B49) : Colors.grey.shade600,
      style: isSelected
          ? IconButton.styleFrom(
              backgroundColor: const Color(0xFF002B49).withValues(alpha: 0.12),
            )
          : null,
      onPressed: () => _onModeChanged(mode),
    );
  }

  Widget _buildActiveRouteCard() {
    final route = _mapController.currentRoute!;
    final totalDistance = route.totalDistance;
    final walkMins = (totalDistance / 75.0).ceil().clamp(1, 120);

    return Material(
      elevation: 6.0,
      borderRadius: BorderRadius.circular(20.0),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: const Color(0xFF002B49),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 22.0),
            ),
            const SizedBox(width: 14.0),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ruta en curso (~$walkMins min)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                  ),
                  Text(
                    '${totalDistance.round()} metros • Modo ${_activeMode.name}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12.0),
                  ),
                ],
              ),
            ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade700,
                side: BorderSide(color: Colors.red.shade300),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
              ),
              icon: const Icon(Icons.close_rounded, size: 16.0),
              label: const Text('Finalizar'),
              onPressed: () {
                _mapController.clearRoute();
              },
            ),
          ],
        ),
      ),
    );
  }
}
