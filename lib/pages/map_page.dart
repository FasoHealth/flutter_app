import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../models/incident_model.dart';
import '../theme/app_theme.dart';
import 'incident_detail_page.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  List<IncidentModel> _incidents = [];
  bool _isLoading = true;
  String _categoryFilter = '';
  String _severityFilter = '';
  String _statusFilter = ''; // Added status filter

  final Map<String, Color> _sevColors = {
    'critical': AppTheme.dangerRed,
    'high': const Color(0xFFF97316),
    'medium': AppTheme.warningOrange,
    'low': AppTheme.successGreen,
  };

  final Map<String, String> _sevLabels = {
    'critical': 'CRITIQUE',
    'high': 'ÉLEVÉ',
    'medium': 'MOYEN',
    'low': 'FAIBLE',
  };

  final Map<String, IconData> _catIcons = {
    'theft': Icons.shopping_bag_rounded,
    'assault': Icons.warning_amber_rounded,
    'vandalism': Icons.format_paint_rounded,
    'fire': Icons.local_fire_department_rounded,
    'accident': Icons.car_crash_rounded,
    'suspicious_activity': Icons.visibility_rounded,
    'other': Icons.more_horiz_rounded,
  };

  @override
  void initState() {
    super.initState();
    _loadIncidents();
  }

  Future<void> _loadIncidents() async {
    try {
      // Fetching incidents (ApiService already filters by approved/resolved for users)
      final data = await ApiService.getIncidents();
      if (mounted) {
        setState(() {
          _incidents = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppTheme.dangerRed),
        );
      }
    }
  }

  List<IncidentModel> get _filteredIncidents {
    return _incidents.where((inc) {
      final catMatch = _categoryFilter.isEmpty || inc.category == _categoryFilter;
      final sevMatch = _severityFilter.isEmpty || inc.severity == _severityFilter;
      final statusMatch = _statusFilter.isEmpty || inc.status == _statusFilter;
      
      final hasCoords = inc.location['coordinates'] != null &&
          inc.location['coordinates']['lat'] != null &&
          inc.location['coordinates']['lng'] != null;
      
      return catMatch && sevMatch && statusMatch && hasCoords;
    }).toList();
  }

  void _showMarkerBottomSheet(BuildContext context, IncidentModel inc) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.cardDark : Colors.white;
    final textColor = isDark ? AppTheme.textPrimary : const Color(0xFF1E293B);
    final textDim = isDark ? AppTheme.textSecondary : const Color(0xFF64748B);
    final sevColor = _sevColors[inc.severity] ?? AppTheme.accentPurple;
    final sevLabel = _sevLabels[inc.severity] ?? inc.severity;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: sevColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(sevLabel, style: TextStyle(color: sevColor, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  Text('${inc.createdAt.day}/${inc.createdAt.month}/${inc.createdAt.year}', style: TextStyle(color: textDim, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 16),
              Text(inc.title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textColor)),
              const SizedBox(height: 8),
              Text(inc.description, style: TextStyle(color: textDim, fontSize: 14), maxLines: 3, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(Icons.location_on_rounded, size: 16, color: AppTheme.dangerRed),
                  const SizedBox(width: 8),
                  Expanded(child: Text(inc.location['address'] ?? 'Adresse non spécifiée', style: TextStyle(color: textDim, fontSize: 14))),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => IncidentDetailPage(incident: inc)));
                      },
                      child: const Text('DÉTAILS'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 54,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppTheme.accentPurple.withOpacity(0.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final lat = (inc.location['coordinates']['lat'] as num).toDouble();
                        final lng = (inc.location['coordinates']['lng'] as num).toDouble();
                        final url = Uri.parse('https://www.google.com/maps?q=$lat,$lng');
                        if (await canLaunchUrl(url)) await launchUrl(url);
                      },
                      child: const Icon(Icons.directions_rounded, color: AppTheme.accentPurple),
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

  void _zoomIn() => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1);
  void _zoomOut() => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.cardDark : Colors.white;
    final textColor = isDark ? AppTheme.textPrimary : const Color(0xFF1E293B);
    final textDim = isDark ? AppTheme.textSecondary : const Color(0xFF64748B);

    final mapTileUrl = isDark
        ? "https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png"
        : "https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png";

    return Stack(
      children: [
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(12.3647, -1.5338),
              initialZoom: 13,
            ),
            children: [
              TileLayer(urlTemplate: mapTileUrl, userAgentPackageName: 'com.example.community_security_alert_app_flutter'),
              MarkerLayer(
                markers: _filteredIncidents.map((inc) {
                  final lat = (inc.location['coordinates']['lat'] as num).toDouble();
                  final lng = (inc.location['coordinates']['lng'] as num).toDouble();
                  final color = _sevColors[inc.severity] ?? Colors.grey;
                  final icon = _catIcons[inc.category] ?? Icons.shield_rounded;
                  
                  return Marker(
                    width: 44, height: 44,
                    point: LatLng(lat, lng),
                    child: GestureDetector(
                      onTap: () => _showMarkerBottomSheet(context, inc),
                      child: Container(
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: color, 
                              shape: BoxShape.circle, 
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 8, spreadRadius: 1)]
                            ),
                            child: Icon(icon, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

        // Floating Control Overlay
        Positioned(
          top: 24, left: 24, right: 24,
          child: Column(
            children: [
              // Category Row
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.05)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)]),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _categoryFilter.isEmpty ? null : _categoryFilter,
                          hint: Text('Quelle catégorie ?', style: TextStyle(color: textDim, fontSize: 13)),
                          dropdownColor: cardBg,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.accentPurple),
                          items: _catIcons.keys.map((c) => DropdownMenuItem(
                            value: c, 
                            child: Row(
                              children: [
                                Icon(_catIcons[c], size: 16, color: AppTheme.accentPurple),
                                const SizedBox(width: 8),
                                Text(c.replaceAll('_', ' ').toUpperCase(), style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold))
                              ],
                            )
                          )).toList(),
                          onChanged: (val) => setState(() => _categoryFilter = val ?? ''),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => setState(() { _categoryFilter = ''; _severityFilter = ''; _statusFilter = ''; }),
                    icon: const Icon(Icons.filter_list_off_rounded, color: AppTheme.accentPurple),
                    style: IconButton.styleFrom(backgroundColor: cardBg, padding: const EdgeInsets.all(12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 4),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Severity Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _sevLabels.keys.map((s) {
                    final selected = _severityFilter == s;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: selected,
                        label: Text(_sevLabels[s]!, style: TextStyle(color: selected ? Colors.white : _sevColors[s], fontSize: 10, fontWeight: FontWeight.bold)),
                        backgroundColor: cardBg,
                        selectedColor: _sevColors[s],
                        onSelected: (val) => setState(() => _severityFilter = val ? s : ''),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: selected ? Colors.transparent : _sevColors[s]!.withOpacity(0.3)),
                        showCheckmark: false,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // Zoom Controls
        Positioned(
          bottom: 24, right: 24,
          child: Column(
            children: [
              FloatingActionButton.small(onPressed: _zoomIn, backgroundColor: cardBg, foregroundColor: AppTheme.accentPurple, child: const Icon(Icons.add_rounded), heroTag: 'map_zoom_in'),
              const SizedBox(height: 8),
              FloatingActionButton.small(onPressed: _zoomOut, backgroundColor: cardBg, foregroundColor: AppTheme.accentPurple, child: const Icon(Icons.remove_rounded), heroTag: 'map_zoom_out'),
            ],
          ),
        ),
      ],
    );
  }
}
