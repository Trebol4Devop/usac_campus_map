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
    BuildingDetailModal.show(
      context: context,
      building: building,
      referencePosition: UsacCampusDataset.campusCenter,
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
            buildings: buildings,
            showCampusBoundary: _showBoundary,
            onBuildingTap: _onBuildingTap,
          ),
          Positioned(
            top: 10,
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
