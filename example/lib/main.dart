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
  final List<CampusBuilding> _buildings = const [
    CampusBuilding(
      id: 't-3',
      name: 'Edificio T-3',
      location: LatLng(14.5878, -90.5512),
      description: 'Facultad de Ingenieria: Escuelas de Mecanica, Civil y Ciencias.',
    ),
    CampusBuilding(
      id: 't-1',
      name: 'Edificio T-1',
      location: LatLng(14.5885, -90.5530),
      description: 'Facultad de Odontologia: Clinicas de atencion dental y aulas.',
    ),
    CampusBuilding(
      id: 's-2',
      name: 'Edificio S-2',
      location: LatLng(14.5862, -90.5535),
      description: 'Facultad de Ciencias Juridicas y Sociales.',
    ),
    CampusBuilding(
      id: 'rectoria',
      name: 'Edificio de Rectoria',
      location: LatLng(14.5855, -90.5528),
      description: 'Administracion Central y oficinas de Consejo Superior Universitario.',
    ),
    CampusBuilding(
      id: 'biblio',
      name: 'Biblioteca Central',
      location: LatLng(14.5868, -90.5518),
      description: 'Acervo bibliografico, salas de estudio y recursos digitales USAC.',
    ),
  ];

  void _onBuildingTap(CampusBuilding building) {
    showModalBottomSheet(
      context: context,
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
                children: [
                  const Icon(Icons.apartment, color: Color(0xFF002B49), size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      building.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                building.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
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
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Campus Central USAC',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF002B49),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Acerca del Mapa'),
                  content: const Text(
                    'Libreria privada de mapa y geolocalizacion desarrollada para Trebol4Devop.\n'
                    'Proporciona navegacion y ubicacion en tiempo real sobre el campus central de la USAC.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Entendido'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: UsacCampusMap(
        buildings: _buildings,
        onBuildingTap: _onBuildingTap,
      ),
    );
  }
}
