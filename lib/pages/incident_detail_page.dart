import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../models/incident_model.dart';
import '../theme/app_theme.dart';
import '../widgets/messenger_dialog.dart';
import 'profile_page.dart';

class IncidentDetailPage extends StatefulWidget {
  final IncidentModel incident;

  const IncidentDetailPage({super.key, required this.incident});

  @override
  State<IncidentDetailPage> createState() => _IncidentDetailPageState();
}

class _IncidentDetailPageState extends State<IncidentDetailPage> {
  late IncidentModel _incident;
  bool _loading = false;
  bool _hasVoted = false;
  String? _userId;
  String? _userRole;

  final Map<String, String> _catLabels = {
    'theft': 'Vol',
    'assault': 'Agression',
    'vandalism': 'Vandalisme',
    'suspicious_activity': 'Suspect',
    'fire': 'Incendie',
    'kidnapping': 'Enlèvement',
    'other': 'Autre'
  };

  @override
  void initState() {
    super.initState();
    _incident = widget.incident;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final id = await ApiService.getUserId();
    final role = await ApiService.getUserRole();
    if (mounted) {
      setState(() {
        _userId = id;
        _userRole = role;
        _hasVoted = _incident.upvotes.contains(_userId);
      });
    }
  }

  Future<void> _handleUpvote() async {
    if (_userId == null || _incident.status != 'pending' || (_userRole == 'admin' || _userRole == 'administrateur')) return;

    setState(() => _loading = true);
    try {
      final success = await ApiService.upvoteIncident(_incident.id);
      if (success) {
        final updated = await ApiService.getIncidentById(_incident.id);
        if (mounted && updated != null) {
          setState(() {
            _incident = updated;
            _hasVoted = _incident.upvotes.contains(_userId);
          });
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleResolve() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmer la résolution"),
        content: const Text("Voulez-vous vraiment marquer cette affaire comme résolue ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("ANNULER")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("CONFIRMER")),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ApiService.moderateIncident(_incident.id, 'resolved', 'Marqué comme résolu par l\'administrateur');
      if (success) {
        final updated = await ApiService.getIncidentById(_incident.id);
        if (mounted && updated != null) {
          setState(() => _incident = updated);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final coords = _incident.location['coordinates']?['coordinates'];
    final hasCoords = coords != null && coords is List && coords.length == 2;

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _incident.title, 
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if ((_userRole == 'admin' || _userRole == 'administrateur') && _incident.status == 'approved')
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: TextButton.icon(
                onPressed: _handleResolve,
                icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                label: const Text("Marquer Résolu", style: TextStyle(color: Colors.white)),
                style: TextButton.styleFrom(backgroundColor: AppTheme.green),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _buildMainContent()),
                  const SizedBox(width: 32),
                  Expanded(flex: 2, child: _buildSidebar(hasCoords, coords)),
                ],
              )
            else
              Column(
                children: [
                  _buildMainContent(),
                  const SizedBox(height: 24),
                  _buildSidebar(hasCoords, coords),
                ],
              ),
            const SizedBox(height: 40),
            _buildChatSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    final isMobile = MediaQuery.of(context).size.width <= 600;
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E3DB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildStatusBadge(_incident.status),
              const SizedBox(width: 8),
              _buildBadge(_catLabels[_incident.category] ?? _incident.category, AppTheme.brandOrange),
            ],
          ),
          const SizedBox(height: 24),
          if (!_incident.isAnonymous)
            InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage(userId: _incident.reportedBy))),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppTheme.brandOrangePale,
                      backgroundImage: _incident.reporterAvatar != null ? NetworkImage(_incident.reporterAvatar!) : null,
                      child: _incident.reporterAvatar == null 
                        ? Text((_incident.reporterName != null && _incident.reporterName!.isNotEmpty) ? _incident.reporterName![0].toUpperCase() : '?',
                            style: const TextStyle(color: AppTheme.brandOrange, fontWeight: FontWeight.bold))
                        : null,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_incident.reporterName ?? "Chargement...", style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
                        Text("Voir le profil de l'informateur", style: GoogleFonts.inter(fontSize: 11, color: AppTheme.brandOrange)),
                      ],
                    ),
                  ],
                ),
              ),
            )
          else
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[100],
                  child: const Icon(Icons.person_off_outlined, color: Colors.grey, size: 20),
                ),
                const SizedBox(width: 12),
                Text("Signalement anonyme", style: GoogleFonts.inter(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w600)),
              ],
            ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 18, color: Color(0xFF9BA3B4)),
              const SizedBox(width: 8),
              Text(
                "Signalé le ${_incident.createdAt.day}/${_incident.createdAt.month}/${_incident.createdAt.year}",
                style: GoogleFonts.inter(color: const Color(0xFF9BA3B4), fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            "Description",
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF222222)),
          ),
          const SizedBox(height: 16),
          Text(
            _incident.description,
            style: GoogleFonts.inter(fontSize: 16, height: 1.8, color: const Color(0xFF5A6478)),
          ),
          if (_incident.images.isNotEmpty) ...[
            const SizedBox(height: 40),
            Text(
              "Photos de l'incident",
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF222222)),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              itemCount: _incident.images.length,
              itemBuilder: (context, index) => ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _incident.images[index], 
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: const Color(0xFFF1F5F9),
                    child: const Icon(Icons.image_not_supported_outlined, color: Color(0xFF9BA3B4), size: 20),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSidebar(bool hasCoords, dynamic coords) {
    final isMobile = MediaQuery.of(context).size.width <= 600;
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8E3DB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, color: AppTheme.brandOrange, size: 20),
                  const SizedBox(width: 10),
                  Text("Localisation", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                _incident.location['address'] ?? "Adresse non spécifiée", 
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                _incident.location['city'] ?? "Ouagadougou", 
                style: GoogleFonts.inter(color: const Color(0xFF9BA3B4), fontSize: 13),
              ),
              if (hasCoords) ...[
                const SizedBox(height: 24),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE8E3DB)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng((coords[1] as num).toDouble(), (coords[0] as num).toDouble()),
                        initialZoom: 15,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                          userAgentPackageName: 'com.fasohealth.flutter_app',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng((coords[1] as num).toDouble(), (coords[0] as num).toDouble()),
                              child: const Icon(Icons.location_on, color: AppTheme.brandOrange, size: 30),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _launchMap('google', coords[1], coords[0]),
                        icon: const Icon(Icons.map_outlined, size: 16),
                        label: const Text("Google Maps"),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _launchMap('waze', coords[1], coords[0]),
                        icon: const Icon(Icons.navigation_outlined, size: 16),
                        label: const Text("Waze"),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.brandOrangePale,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.brandOrange.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.shield_outlined, color: AppTheme.brandOrange, size: 18),
                  const SizedBox(width: 8),
                  Text("CONSEIL DE SÉCURITÉ", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.brandOrange, letterSpacing: 1)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                "Évitez cette zone si possible jusqu'à ce que l'incident soit marqué comme résolu par les autorités ou les modérateurs.",
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF5A6478), height: 1.5),
              ),
            ],
          ),
        ),
        if (_incident.status == 'pending') ...[
          const SizedBox(height: 24),
          _buildConfirmSection(),
        ],
      ],
    );
  }

  Widget _buildConfirmSection() {
    final votes = _incident.upvoteCount;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E3DB)),
      ),
      child: Column(
        children: [
          ElevatedButton.icon(
            onPressed: _loading || _userRole == 'ADMINISTRATEUR' ? null : _handleUpvote,
            icon: Icon(_hasVoted ? Icons.check_circle : Icons.thumb_up_alt_outlined, size: 18),
            label: Text(_hasVoted ? "Confirmé" : "Confirmer l'incident"),
            style: ElevatedButton.styleFrom(
              backgroundColor: _hasVoted ? const Color(0xFFF1F5F9) : AppTheme.brandOrange,
              foregroundColor: _hasVoted ? const Color(0xFF475569) : Colors.white,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("$votes/5 confirmations", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.brandOrange)),
              Text("${(5 - votes).clamp(0, 5)} de plus pour validation", style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF9BA3B4))),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: votes / 5,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.brandOrange),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatSection() {
    final canChat = _userId == _incident.reportedBy || (_userRole == 'admin' || _userRole == 'administrateur');
    if (!canChat) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.brandOrange, size: 24),
            const SizedBox(width: 12),
            Text("Discussion en direct", style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          height: 400,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8E3DB)),
          ),
          child: MessengerDialog(incidentId: _incident.id, incidentTitle: _incident.title),
        ),
      ],
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(label.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = AppTheme.yellow;
    if (status == 'approved') color = AppTheme.green;
    if (status == 'resolved') color = AppTheme.blue;
    if (status == 'rejected') color = AppTheme.red;
    return _buildBadge(status, color);
  }

  Future<void> _launchMap(String type, double lat, double lng) async {
    final url = type == 'google' 
      ? 'https://www.google.com/maps/search/?api=1&query=$lat,$lng'
      : 'https://waze.com/ul?ll=$lat,$lng&navigate=yes';
      
    try {
      await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Impossible d'ouvrir l'application de cartographie."),
            backgroundColor: AppTheme.red,
          )
        );
      }
    }
  }
}
