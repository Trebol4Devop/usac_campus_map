import 'package:flutter/material.dart' hide NavigationMode;
import 'package:latlong2/latlong.dart';
import '../../engine/campus_community_repository.dart';
import '../../models/building_3d_model.dart';
import '../../models/campus_building.dart';
import '../../models/campus_poi.dart';
import '../../models/navigation_mode.dart';
import '../../models/rating_classification.dart';
import '../themes/usac_map_theme.dart';
import 'building_3d_viewer.dart';
import 'community_forum_view.dart';
import 'community_reviews_view.dart';
import 'rating_classification_badge.dart';

class PoiDetailSheet extends StatefulWidget {
  final CampusBuilding? building;
  final CampusPoi? poi;
  final int currentFloor;
  final LatLng? userLocation;
  final UsacMapTheme theme;
  final void Function(NavigationMode mode)? onNavigate;
  final VoidCallback? onClose;
  final CampusCommunityRepository? communityRepository;
  final int initialTabIndex;

  const PoiDetailSheet({
    super.key,
    this.building,
    this.poi,
    this.currentFloor = 1,
    this.userLocation,
    this.theme = const UsacMapTheme(),
    this.onNavigate,
    this.onClose,
    this.communityRepository,
    this.initialTabIndex = 0,
  });

  static Future<void> show({
    required BuildContext context,
    CampusBuilding? building,
    CampusPoi? poi,
    int currentFloor = 1,
    LatLng? userLocation,
    UsacMapTheme theme = const UsacMapTheme(),
    void Function(NavigationMode mode)? onNavigate,
    CampusCommunityRepository? communityRepository,
    int initialTabIndex = 0,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PoiDetailSheet(
        building: building,
        poi: poi,
        currentFloor: currentFloor,
        userLocation: userLocation,
        theme: theme,
        onNavigate: onNavigate,
        onClose: () => Navigator.of(ctx).pop(),
        communityRepository: communityRepository,
        initialTabIndex: initialTabIndex,
      ),
    );
  }

  @override
  State<PoiDetailSheet> createState() => _PoiDetailSheetState();
}

class _PoiDetailSheetState extends State<PoiDetailSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late CampusCommunityRepository _communityRepo;

  @override
  void initState() {
    super.initState();
    _communityRepo =
        widget.communityRepository ?? CampusCommunityRepository.instance;
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _targetId =>
      widget.poi?.id ?? widget.building?.id ?? 'lugar_general';
  String get _targetName =>
      widget.poi?.name ?? widget.building?.name ?? 'Detalles del Lugar';
  String get _targetCategory =>
      widget.poi?.category ?? widget.building?.category ?? '';
  String get _targetType => widget.poi != null ? 'poi' : 'building';

  RatingClassificationConfig get _classification =>
      _communityRepo.getClassification(_targetCategory);

  @override
  Widget build(BuildContext context) {
    final title = _targetName;
    final code = widget.poi?.code ?? widget.building?.code ?? '';
    final category = _targetCategory;

    final floorPois = (widget.building?.floors ?? [])
        .where((f) => f.level == widget.currentFloor)
        .expand((f) => f.pois)
        .toList();

    final aggregate = _communityRepo.getAggregate(
      _targetId,
      category: _targetCategory,
    );
    final comments = _communityRepo.getComments(_targetId);

    final mediaHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(
        maxHeight: mediaHeight * 0.82,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40.0,
              height: 4.0,
              margin: const EdgeInsets.only(top: 12.0, bottom: 8.0),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: widget.theme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Icon(
                    _getCategoryIcon(category),
                    color: widget.theme.primaryColor,
                    size: 28.0,
                  ),
                ),
                const SizedBox(width: 14.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                          color: widget.theme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Row(
                        children: [
                          if (code.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6.0,
                                vertical: 2.0,
                              ),
                              decoration: BoxDecoration(
                                color: widget.theme.accentColor
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              child: Text(
                                code,
                                style: TextStyle(
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.bold,
                                  color: widget.theme.primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8.0),
                          ],
                          Text(
                            category.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12.0,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (widget.building != null) ...[
                            const SizedBox(width: 6.0),
                            Text(
                              '• ${widget.building!.floorsCount} niveles',
                              style: TextStyle(
                                fontSize: 12.0,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onClose ?? () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Resumen de Calificación clickeable
          Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 4.0),
            child: InkWell(
              onTap: () {
                _tabController.animateTo(1);
              },
              borderRadius: BorderRadius.circular(8.0),
              child: Row(
                children: [
                  if (_classification.tiers.isNotEmpty && aggregate.totalReviews > 0)
                    RatingClassificationBadge(
                      averageRating: aggregate.averageRating,
                      config: _classification,
                      compact: true,
                    )
                  else ...[
                    Icon(Icons.star_rounded,
                        size: 18.0, color: Colors.amber.shade700),
                    const SizedBox(width: 4.0),
                    Text(
                      aggregate.averageRating > 0
                          ? aggregate.averageRating.toStringAsFixed(1)
                          : 'Sin calificar',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(width: 4.0),
                    Text(
                      '(${aggregate.totalReviews} reseñas)',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12.0,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    'Ver opiniones ›',
                    style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                      color: widget.theme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // TabBar
          TabBar(
            controller: _tabController,
            labelColor: widget.theme.primaryColor,
            unselectedLabelColor: Colors.grey.shade600,
            indicatorColor: widget.theme.primaryColor,
            indicatorWeight: 3.0,
            labelStyle: const TextStyle(
              fontSize: 13.0,
              fontWeight: FontWeight.bold,
            ),
            tabs: [
              const Tab(
                icon: Icon(Icons.info_outline, size: 18.0),
                text: 'Detalles',
              ),
              Tab(
                icon: const Icon(Icons.star_rounded, size: 18.0),
                text: 'Reseñas (${aggregate.totalReviews})',
              ),
              Tab(
                icon: const Icon(Icons.forum_outlined, size: 18.0),
                text: 'Foro (${comments.length})',
              ),
            ],
          ),

          // TabBarView
          Flexible(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 0: Información estándar
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (floorPois.isNotEmpty) ...[
                        Text(
                          'En Nivel ${widget.currentFloor}:',
                          style: TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                            color: widget.theme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 6.0,
                          children: floorPois.map((p) {
                            return Chip(
                              label: Text(p.name),
                              labelStyle: const TextStyle(fontSize: 12.0),
                              backgroundColor: Colors.grey.shade100,
                              side: BorderSide(color: Colors.grey.shade300),
                              avatar: Icon(
                                _getCategoryIcon(p.category),
                                size: 16.0,
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16.0),
                      ],
                      if (widget.building?.entrances.isNotEmpty ?? false) ...[
                        Text(
                          'Accesos Peatonales:',
                          style: TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                            color: widget.theme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 6.0),
                        ...widget.building!.entrances.map(
                          (e) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.meeting_room,
                                  size: 16.0,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 6.0),
                                Expanded(
                                  child: Text(
                                    e.name,
                                    style: const TextStyle(fontSize: 13.0),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20.0),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: widget.theme.primaryColor,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                              ),
                              icon: const Icon(Icons.directions_walk),
                              label: const Text(
                                'Cómo llegar / Trazar Ruta',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              onPressed: () {
                                widget.onNavigate
                                    ?.call(NavigationMode.pedestrian);
                              },
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          IconButton.filledTonal(
                            tooltip: 'Ruta Techada (Lluvia)',
                            icon: const Icon(Icons.roofing),
                            onPressed: () {
                              widget.onNavigate?.call(NavigationMode.covered);
                            },
                          ),
                          IconButton.filledTonal(
                            tooltip: 'Ruta Accesible (Sin Gradas)',
                            icon: const Icon(Icons.accessible),
                            onPressed: () {
                              widget.onNavigate
                                  ?.call(NavigationMode.accessible);
                            },
                          ),
                          if (widget.building != null)
                            IconButton.filledTonal(
                              tooltip: 'Modelo 3D',
                              icon: const Icon(Icons.view_in_ar),
                              onPressed: () {
                                showDialog<void>(
                                  context: context,
                                  builder: (ctx) => Dialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20.0),
                                    ),
                                    child: SizedBox(
                                      width: 360.0,
                                      height: 420.0,
                                      child: Building3DViewer(
                                        model: Building3DModel.fromBuilding(
                                          widget.building!,
                                        ),
                                        theme: widget.theme,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Tab 1: Reseñas & Calificaciones
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 24.0),
                  child: CommunityReviewsView(
                    targetId: _targetId,
                    targetName: _targetName,
                    targetType: _targetType,
                    targetCategory: _targetCategory,
                    theme: widget.theme,
                    repository: _communityRepo,
                  ),
                ),

                // Tab 2: Foro de Discusión en Tiempo Real
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 24.0),
                  child: CommunityForumView(
                    targetId: _targetId,
                    targetName: _targetName,
                    theme: widget.theme,
                    repository: _communityRepo,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'faculty':
        return Icons.school;
      case 'library':
      case 'bibliotecas':
        return Icons.local_library;
      case 'administrative':
      case 'oficinas':
        return Icons.account_balance;
      case 'health':
        return Icons.local_hospital;
      case 'sports':
        return Icons.sports_soccer;
      case 'plaza':
      case 'monumentos':
        return Icons.flag;
      case 'cafeterias':
        return Icons.restaurant;
      case 'cajeros':
        return Icons.atm;
      case 'sanitarios':
        return Icons.wc;
      case 'laboratorios':
        return Icons.biotech;
      case 'aulas':
        return Icons.meeting_room;
      default:
        return Icons.place;
    }
  }
}
