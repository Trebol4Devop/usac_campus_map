import 'package:flutter/material.dart';
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
  final CampusDistanceService _distanceService = CampusDistanceService();
  BuildingCategory? _selectedCategory;
  String _searchQuery = '';
  bool _showBoundary = true;

  List<CampusBuilding> get _filteredBuildings {
    return _searchService.search(
      query: _searchQuery,
      category: _selectedCategory,
    );
  }

  void _onBuildingTap(CampusBuilding building) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF002B49).withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.account_balance, color: Color(0xFF002B49), size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          building.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            building.category.label,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                building.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (building.floors != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.layers, size: 18, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      'Niveles: ${building.floors}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.pin_drop, size: 18, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    'Coordenadas: ${building.location.latitude.toStringAsFixed(4)}, ${building.location.longitude.toStringAsFixed(4)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.directions_walk, size: 18, color: Color(0xFF002B49)),
                  const SizedBox(width: 6),
                  Text(
                    'Distancia desde centro USAC: ${_distanceService.formatDistance(_distanceService.calculateBuildingDistance(UsacCampusDataset.campusCenter, building))} (${_distanceService.formatWalkingTime(_distanceService.estimateWalkingDuration(_distanceService.calculateBuildingDistance(UsacCampusDataset.campusCenter, building)))} a pie)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF002B49),
                        ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
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
          preferredSize: const Size.fromHeight(60),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar edificio, sigla (T-3, S-2, Rectoria)...',
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          UsacCampusMap(
            buildings: buildings,
            showCampusBoundary: _showBoundary,
            onBuildingTap: _onBuildingTap,
          ),
          Positioned(
            top: 10,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  ChoiceChip(
                    label: const Text('Todos'),
                    selected: _selectedCategory == null,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = null;
                        });
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  ...BuildingCategory.values.map(
                    (cat) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(cat.label),
                        selected: _selectedCategory == cat,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = selected ? cat : null;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
