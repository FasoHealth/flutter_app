import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import '../models/incident_model.dart';
import '../theme/app_theme.dart';
import 'incident_detail_page.dart';
import 'report_incident_page.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  List<IncidentModel> _incidents = [];
  bool _loading = true;
  String _category = '';
  String _searchVal = '';
  double _radiusKm = 2.5;
  LatLng _center = const LatLng(12.3647, -1.5338); // Ouaga par défaut
  LatLng? _userPos;
  String? _activeId;

  final Map<String, Color> _sevColors = {
    'low': const Color(0xFF22C55E),
    'medium': const Color(0xFFEAB308),
    'high': const Color(0xFFF97316),
    'critical': const Color(0xFFEF4444),
  };

  final Map<String, String> _sevLabels = {
    'low': 'Faible',
    'medium': 'Moyen',
    'high': 'Élevé',
    'critical': 'Critique',
  };

  final Map<String, String> _catLabels = {
    'theft': 'Vol',
    'assault': 'Agression',
    'vandalism': 'Vandalisme',
    'suspicious_activity': 'Suspect',
    'fire': 'Incendie',
    'kidnapping': 'Enlèvement',
    'other': 'Autre'
  };

  final Map<String, IconData> _catIcons = {
    'theft': Icons.shield_outlined,
    'assault': Icons.warning_amber_rounded,
    'vandalism': Icons.gavel_rounded,
    'suspicious_activity': Icons.visibility_outlined,
    'fire': Icons.local_fire_department_outlined,
    'kidnapping': Icons.person_off_outlined,
    'other': Icons.help_outline_rounded,
  };

  @override
  void initState() {
    super.initState();
    _initMap();
  }

  Future<void> _initMap() async {
    setState(() => _loading = true);
    
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        Position position = await Geolocator.getCurrentPosition();
        if (mounted) {
          setState(() {
            _userPos = LatLng(position.latitude, position.longitude);
            _center = _userPos!;
          });
        }
      }
    } catch (e) {
      debugPrint("Erreur géoloc : $e");
    }

    try {
      final data = await ApiService.getIncidents();
      if (mounted) {
        setState(() {
          _incidents = data.where((i) => i.status == 'approved').toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<IncidentModel> get _filteredIncidents {
    return _incidents.where((inc) {
      final matchCat = _category.isEmpty || inc.category == _category;
      final matchSearch = _searchVal.isEmpty || 
          inc.title.toLowerCase().contains(_searchVal.toLowerCase()) ||
          (inc.location['address'] ?? '').toLowerCase().contains(_searchVal.toLowerCase());
      
      if (inc.location['coordinates'] != null) {
        final coords = inc.location['coordinates']['coordinates'];
        if (coords != null && coords is List && coords.length == 2) {
          final distance = const Distance().as(
            LengthUnit.Kilometer,
            _center,
            LatLng((coords[1] as num).toDouble(), (coords[0] as num).toDouble()),
          );
          return matchCat && matchSearch && distance <= _radiusKm;
        }
      }
      return false;
    }).toList();
  }

  String _formatDist(double km) {
    return km < 1 ? "${(km * 1000).round()} m" : "${km.toStringAsFixed(1)} km";
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.brandOrange));
    }

    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      body: Row(
        children: [
          if (isDesktop)
            Container(
              width: 340,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(right: BorderSide(color: Color(0xFFE8E3DB))),
              ),
              child: _buildSidebar(),
            ),
          
          Expanded(
            child: Stack(
              children: [
                _buildMap(),
                _buildOverlays(isDesktop),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    final filtered = _filteredIncidents;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.my_location_rounded, color: AppTheme.brandOrange, size: 18),
                      const SizedBox(width: 8),
                      Text("Dans votre zone", style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppTheme.brandOrange, borderRadius: BorderRadius.circular(20)),
                    child: Text("${filtered.length} alertes", style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text("RAYON DE PROXIMITÉ", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF9BA3B4), letterSpacing: 1)),
              Row(
                children: [
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        activeTrackColor: AppTheme.brandOrange,
                        inactiveTrackColor: const Color(0xFFE8E3DB),
                        thumbColor: Colors.white,
                        overlayColor: AppTheme.brandOrange.withOpacity(0.1),
                      ),
                      child: Slider(
                        value: _radiusKm,
                        min: 0.5,
                        max: 10.0,
                        onChanged: (val) => setState(() => _radiusKm = val),
                      ),
                    ),
                  ),
                  Text("${_radiusKm.toStringAsFixed(1)} km", style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppTheme.brandOrange, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCatPill("Toutes", ""),
                    ..._catLabels.entries.map((e) => _buildCatPill(e.value, e.key)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) => _buildIncidentItem(filtered[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildCatPill(String label, String value) {
    final active = _category == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => setState(() => _category = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: active ? AppTheme.brandOrange : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: active ? Colors.white : const Color(0xFF475569))),
        ),
      ),
    );
  }

  Widget _buildIncidentItem(IncidentModel inc) {
    final active = _activeId == inc.id;
    final icon = _catIcons[inc.category] ?? Icons.warning_amber_rounded;
    final coords = inc.location['coordinates']['coordinates'];
    final distance = const Distance().as(LengthUnit.Kilometer, _center, LatLng((coords[1] as num).toDouble(), (coords[0] as num).toDouble()));

    return InkWell(
      onTap: () {
        setState(() => _activeId = inc.id);
        _mapController.move(LatLng((coords[1] as num).toDouble(), (coords[0] as num).toDouble()), 15);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: active ? AppTheme.brandOrangePale : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? AppTheme.brandOrange : const Color(0xFFE8E3DB)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: const Color(0xFFF8F4EE), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 18, color: const Color(0xFF1A2035)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(inc.title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      Text(_timeAgo(inc.createdAt), style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF9BA3B4))),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(inc.location['address']?.split(',')[0] ?? "", style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF9BA3B4)), maxLines: 1),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.navigation_outlined, size: 10, color: Color(0xFF9BA3B4)),
                      const SizedBox(width: 4),
                      Text(_formatDist(distance), style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF9BA3B4))),
                      if (inc.upvoteCount > 0) ...[
                        const Spacer(),
                        const Icon(Icons.thumb_up_alt_rounded, size: 10, color: AppTheme.brandOrange),
                        const SizedBox(width: 4),
                        Text("${inc.upvoteCount}", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.brandOrange)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mapTile = isDark
        ? "https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png"
        : "https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png";

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _center,
        initialZoom: 13,
        onTap: (_, __) => setState(() => _activeId = null),
      ),
      children: [
        TileLayer(
          urlTemplate: mapTile,
          userAgentPackageName: 'com.cs27.flashalerte',
        ),
        CircleLayer(
          circles: [
            CircleMarker(
              point: _center,
              radius: _radiusKm * 1000,
              useRadiusInMeter: true,
              color: AppTheme.brandOrange.withOpacity(0.06),
              borderColor: AppTheme.brandOrange,
              borderStrokeWidth: 2,
            ),
          ],
        ),
        MarkerLayer(
          markers: [
            if (_userPos != null)
              Marker(
                point: _userPos!,
                width: 20,
                height: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6),
                    border: Border.all(color: Colors.white, width: 3),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.6), blurRadius: 10)],
                  ),
                ),
              ),
            ..._filteredIncidents.map((inc) {
              final coords = inc.location['coordinates']['coordinates'];
              final color = _sevColors[inc.severity] ?? AppTheme.brandOrange;
              return Marker(
                point: LatLng((coords[1] as num).toDouble(), (coords[0] as num).toDouble()),
                width: 24,
                height: 24,
                child: GestureDetector(
                  onTap: () => _showIncidentPopup(inc),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      border: Border.all(color: Colors.white, width: 2),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: color.withOpacity(0.6), blurRadius: 10)],
                    ),
                    child: const Icon(Icons.warning_rounded, color: Colors.white, size: 12),
                  ),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  void _showIncidentPopup(IncidentModel inc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildBadge(_catLabels[inc.category] ?? inc.category, const Color(0xFFF1F5F9)),
                const SizedBox(width: 8),
                _buildBadge(_sevLabels[inc.severity] ?? inc.severity, _sevColors[inc.severity] ?? Colors.grey, textColor: Colors.white),
              ],
            ),
            const SizedBox(height: 16),
            Text(inc.title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF999999)),
                const SizedBox(width: 4),
                Expanded(child: Text(inc.location['address'] ?? "", style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF999999)))),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => IncidentDetailPage(incident: inc)));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Détails"),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlays(bool isDesktop) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8E3DB)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: TextField(
                onChanged: (val) => setState(() => _searchVal = val),
                decoration: const InputDecoration(
                  hintText: "Rechercher un quartier, une rue...",
                  prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF9BA3B4)),
                  fillColor: Colors.transparent,
                  filled: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
          ),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildMapButton(Icons.my_location_rounded, 'locate', () {
                if (_userPos != null) _mapController.move(_userPos!, 15);
              }),
              const SizedBox(height: 12),
              _buildMapButton(Icons.add_rounded, 'zoom_in', () {
                _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1);
              }),
              const SizedBox(height: 8),
              _buildMapButton(Icons.remove_rounded, 'zoom_out', () {
                _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1);
              }),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE8E3DB)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("GRAVITÉ", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF9BA3B4))),
                    const SizedBox(height: 8),
                    ..._sevLabels.entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Container(width: 8, height: 8, decoration: BoxDecoration(color: _sevColors[e.key], shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Text(e.value, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMapButton(IconData icon, String heroTag, VoidCallback onTap) {
    return FloatingActionButton.small(
      heroTag: heroTag,
      onPressed: onTap,
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF1A2035),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE8E3DB)),
      ),
      child: Icon(icon, size: 20),
    );
  }

  Widget _buildBadge(String label, Color bgColor, {Color? textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(4)),
      child: Text(label.toUpperCase(), style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: textColor ?? const Color(0xFF475569))),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return "À l'instant";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m";
    if (diff.inHours < 24) return "${diff.inHours}h";
    return "${date.day}/${date.month}";
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off_outlined, size: 48, color: Colors.grey.withOpacity(0.1)),
          const SizedBox(height: 16),
          Text("Aucun incident trouvé", style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
        ],
      ),
    );
  }
}
