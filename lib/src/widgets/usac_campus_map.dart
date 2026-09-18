import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/campus_building.dart';
import '../services/location_service.dart';

class UsacCampusMap extends StatefulWidget {
  final List<CampusBuilding> buildings;
  final Function(CampusBuilding)? onBuildingTap;

  const UsacCampusMap({
    super.key,
    this.buildings = const [],
    this.onBuildingTap,
  });

  @override
  State<UsacCampusMap> createState() => _UsacCampusMapState();
}

class _UsacCampusMapState extends State<UsacCampusMap> {
  final MapController _mapController = MapController();
  final CampusLocationService _locationService = CampusLocationService();
  StreamSubscription<LatLng>? _locationSubscription;
  LatLng? _currentPosition;

  static const LatLng _usacCampusCenter = LatLng(14.5866, -90.5524);

  @override
  void initState() {
    super.initState();
    _initTracking();
  }

  void _initTracking() {
    _locationSubscription = _locationService.studentPositionStream.listen(
      (LatLng pos) {
        if (mounted) {
          setState(() {
            _currentPosition = pos;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _mapController,
      options: const MapOptions(
        initialCenter: _usacCampusCenter,
        initialZoom: 16.5,
        maxZoom: 19.0,
        minZoom: 14.5,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'gt.edu.usac.map',
        ),
        MarkerLayer(
          markers: [
            ...widget.buildings.map(
              (building) => Marker(
                point: building.location,
                width: 40,
                height: 40,
                child: GestureDetector(
                  onTap: () => widget.onBuildingTap?.call(building),
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.redAccent,
                    size: 32,
                  ),
                ),
              ),
            ),
            if (_currentPosition != null)
              Marker(
                point: _currentPosition!,
                width: 36,
                height: 36,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.navigation,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
