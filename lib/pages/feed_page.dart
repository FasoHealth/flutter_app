import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../models/incident_model.dart';
import '../theme/app_theme.dart';
import 'incident_detail_page.dart';
import 'profile_page.dart';

class FeedPage extends StatefulWidget {
  final VoidCallback onNavigateToReport;

  const FeedPage({super.key, required this.onNavigateToReport});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  List<IncidentModel> _incidents = [];
  bool _loading = true;
  String _search = '';
  String _category = '';
  String _severity = '';
  int _page = 1;
  String? _userId;

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

  final Map<String, String> _sevLabels = {
    'low': 'Faible',
    'medium': 'Moyen',
    'high': 'Élevé',
    'critical': 'Critique'
  };

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _fetchIncidents();
  }

  Future<void> _loadUserId() async {
    _userId = await ApiService.getUserId();
  }

  Future<void> _fetchIncidents() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getIncidents(
        page: _page,
        category: _category,
        severity: _severity,
        search: _search,
      );
      
      final fortyEightHoursAgo = DateTime.now().subtract(const Duration(hours: 48));
      final filtered = data.where((inc) => inc.createdAt.isAfter(fortyEightHoursAgo)).toList();

      if (mounted) {
        setState(() {
          _incidents = filtered;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return "À l'instant";
    if (diff.inMinutes < 60) return "Il y a ${diff.inMinutes} min";
    if (diff.inHours < 24) return "Il y a ${diff.inHours}h";
    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          _buildHeader(),
          _buildFilters(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.brandOrange))
                : _incidents.isEmpty
                    ? _buildEmptyState()
                    : _buildIncidentGrid(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: widget.onNavigateToReport,
        backgroundColor: AppTheme.brandOrange,
        child: const Icon(Icons.flash_on_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.brandOrangePale,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.grid_view_rounded, color: AppTheme.brandOrange, size: 24),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Fil d'Actualité",
                    style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: const Color(0xFF222222)),
                  ),
                  Text(
                    "Dernières alertes communautaires",
                    style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF666666)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 24.0),
      child: Column(
        children: [
          TextField(
            onChanged: (val) {
              setState(() {
                _search = val;
                _page = 1;
              });
              _fetchIncidents();
            },
            decoration: const InputDecoration(
              hintText: "Rechercher par titre, description, lieu...",
              prefixIcon: Icon(Icons.search_rounded, size: 20),
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  value: _category,
                  hint: "Toutes catégories",
                  items: _catLabels,
                  onChanged: (val) {
                    setState(() {
                      _category = val ?? '';
                      _page = 1;
                    });
                    _fetchIncidents();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown(
                  value: _severity,
                  hint: "Toutes gravités",
                  items: _sevLabels,
                  onChanged: (val) {
                    setState(() {
                      _severity = val ?? '';
                      _page = 1;
                    });
                    _fetchIncidents();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required String hint,
    required Map<String, String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E3DB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value.isEmpty ? null : value,
          hint: Text(hint, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF666666))),
          isExpanded: true,
          items: [
            DropdownMenuItem(value: null, child: Text(hint)),
            ...items.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildIncidentGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 3 : (MediaQuery.of(context).size.width > 800 ? 2 : 1),
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        childAspectRatio: 0.75, // Augmenté de 0.85 à 0.75 pour éviter l'overflow vertical
      ),
      itemCount: _incidents.length,
      itemBuilder: (context, index) => _buildIncidentCard(_incidents[index]),
    );
  }

  Widget _buildIncidentCard(IncidentModel inc) {
    final isPending = inc.status == 'pending';
    final icon = _catIcons[inc.category] ?? Icons.warning_amber_rounded;
    final upvoteCount = inc.upvoteCount;

    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => IncidentDetailPage(incident: inc))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPending ? AppTheme.brandOrange : const Color(0xFFE8E3DB),
            width: isPending ? 2 : 1,
          ),
          boxShadow: [
            if (isPending)
              BoxShadow(color: AppTheme.brandOrange.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 8))
            else
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Contenu scrollable si nécessaire, mais on va plutôt limiter la taille des éléments
              Expanded(
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(), // On garde le scroll de la grille
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: inc.isAnonymous ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage(userId: inc.reportedBy))),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F4EE),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: inc.isAnonymous 
                                  ? Icon(icon, color: const Color(0xFF1A2035), size: 16)
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: inc.reporterAvatar != null
                                        ? Image.network(inc.reporterAvatar!, fit: BoxFit.cover)
                                        : Center(child: Text(
                                            (inc.reporterName != null && inc.reporterName!.isNotEmpty) ? inc.reporterName![0].toUpperCase() : '?',
                                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.brandOrange)
                                          )),
                                    ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: InkWell(
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => IncidentDetailPage(incident: inc))),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      inc.title,
                                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      inc.isAnonymous ? (inc.location['address']?.split(',')[0] ?? "Lieu inconnu") : (inc.reporterName ?? "Chargement..."),
                                      style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF999999)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Badges
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            _buildBadge(_catLabels[inc.category] ?? inc.category, const Color(0xFFF1F5F9)),
                            _buildBadge(_sevLabels[inc.severity] ?? inc.severity, const Color(0xFFF1F5F9)),
                            if (isPending)
                              _buildBadge("EN ATTENTE", AppTheme.brandOrange, textColor: Colors.white),
                          ],
                        ),
                      ),

                      // Description
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          inc.description,
                          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF5A6478), height: 1.4),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      if (inc.images.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              inc.images[0],
                              height: 100,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                height: 100,
                                color: Colors.grey[100],
                                child: const Icon(Icons.image_not_supported_outlined, size: 20),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const Divider(height: 1),

              // Footer (fixé en bas)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.thumb_up_alt_outlined, size: 12, color: Color(0xFF9BA3B4)),
                            const SizedBox(width: 4),
                            Text("$upvoteCount", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF9BA3B4))),
                          ],
                        ),
                        Text(_timeAgo(inc.createdAt), style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF9BA3B4))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (inc.status == 'approved')
                      Row(
                        children: [
                          const Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 12),
                          const SizedBox(width: 4),
                          Text(
                            "VÉRIFIÉ",
                            style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: const Color(0xFF10B981), letterSpacing: 0.5),
                          ),
                        ],
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "$upvoteCount/5 confirmations",
                                style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.brandOrange),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: (upvoteCount / 5).clamp(0.0, 1.0),
                              backgroundColor: const Color(0xFFE8E3DB),
                              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.brandOrange),
                              minHeight: 3,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color bgColor, {Color? textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: textColor ?? const Color(0xFF475569),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined, size: 64, color: Colors.grey.withOpacity(0.1)),
          const SizedBox(height: 20),
          Text(
            "Aucun incident trouvé",
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          Text(
            "Essayez de modifier vos filtres ou effectuez une nouvelle recherche.",
            style: GoogleFonts.inter(color: const Color(0xFF999999)),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () {
              setState(() {
                _search = '';
                _category = '';
                _severity = '';
                _page = 1;
              });
              _fetchIncidents();
            },
            child: const Text("Réinitialiser les filtres"),
          ),
        ],
      ),
    );
  }
}
