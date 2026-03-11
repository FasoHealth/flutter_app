import 'package:flutter/material.dart';
import '../models/incident_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'incident_detail_page.dart';

class FeedPage extends StatefulWidget {
  final VoidCallback? onNavigateToReport;

  const FeedPage({super.key, this.onNavigateToReport});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  late Future<List<IncidentModel>> _incidentsFuture;
  String _search = '';
  String _categoryFilter = 'all';

  static const List<Map<String, String>> categories = [
    {'value': 'all', 'label': 'Tout'},
    {'value': 'theft', 'label': 'Vol'},
    {'value': 'assault', 'label': 'Agression'},
    {'value': 'vandalism', 'label': 'Vandalisme'},
    {'value': 'fire', 'label': 'Incendie'},
    {'value': 'accident', 'label': 'Accident'},
  ];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    final future = ApiService.getIncidents();
    // Fix: Use block to avoid returning Future to setState
    setState(() {
      _incidentsFuture = future;
    });
  }

  List<IncidentModel> _filter(List<IncidentModel> list) {
    return list.where((i) {
      if (_categoryFilter != 'all' && i.category != _categoryFilter) return false;
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        if (!i.title.toLowerCase().contains(q) && !i.description.toLowerCase().contains(q)) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.textPrimary : const Color(0xFF1E293B);
    final textDim = isDark ? AppTheme.textSecondary : const Color(0xFF64748B);
    final cardBg = isDark ? AppTheme.cardDark : Colors.white;

    // Fix: Remove redundant Scaffold (already in MainShell)
    return Column(
      children: [
        _buildHeader(textColor, textDim),
        _buildFilters(cardBg, textColor, textDim),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              _refresh();
            },
            color: AppTheme.accentPurple,
            child: FutureBuilder<List<IncidentModel>>(
              future: _incidentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return Center(child: Text('Erreur: ${snapshot.error}', style: const TextStyle(color: AppTheme.dangerRed)));
                
                final list = _filter(snapshot.data ?? []);
                if (list.isEmpty) return _buildEmptyState(textColor, textDim);

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  itemCount: list.length,
                  itemBuilder: (context, index) => _buildIncidentCard(list[index], cardBg, textColor, textDim),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(Color textColor, Color textDim) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Alertes en direct', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: textColor, letterSpacing: -0.5)),
              Text('Soyez informé des incidents autour de vous.', style: TextStyle(color: textDim, fontSize: 14)),
            ],
          ),
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.accentPurple),
            style: IconButton.styleFrom(backgroundColor: AppTheme.accentPurple.withOpacity(0.1)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(Color cardBg, Color textColor, Color textDim) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: TextField(
            onChanged: (v) => setState(() { _search = v; }),
            decoration: InputDecoration(
              hintText: 'Rechercher un incident...',
              prefixIcon: const Icon(Icons.search_rounded),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              fillColor: cardBg.withOpacity(0.5),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              final selected = _categoryFilter == cat['value'];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(cat['label']!),
                  selected: selected,
                  onSelected: (v) => setState(() { _categoryFilter = cat['value']!; }),
                  backgroundColor: cardBg,
                  selectedColor: AppTheme.accentPurple,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : textDim,
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  showCheckmark: false,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildIncidentCard(IncidentModel inc, Color cardBg, Color textColor, Color textDim) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => IncidentDetailPage(incident: inc))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Severity Bar
              Container(height: 4, color: _severityColor(inc.severity)),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: AppTheme.accentPurple.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text(inc.category.toUpperCase(), style: const TextStyle(color: AppTheme.accentPurple, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        ),
                        Text('${inc.createdAt.day}/${inc.createdAt.month} • ${inc.createdAt.hour}:${inc.createdAt.minute.toString().padLeft(2,'0')}', style: TextStyle(color: textDim, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(inc.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor, height: 1.2)),
                    const SizedBox(height: 8),
                    Text(inc.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: textDim, fontSize: 14)),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 14, color: AppTheme.dangerRed),
                        const SizedBox(width: 4),
                        Expanded(child: Text(inc.location['address'] ?? 'Lieu inconnu', style: TextStyle(color: textDim, fontSize: 12), overflow: TextOverflow.ellipsis)),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.accentPurple),
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

  Color _severityColor(String s) {
    switch (s) {
      case 'critical': return AppTheme.dangerRed;
      case 'high': return const Color(0xFFF97316);
      case 'medium': return AppTheme.warningOrange;
      default: return AppTheme.successGreen;
    }
  }

  Widget _buildEmptyState(Color textColor, Color textDim) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shield_outlined, size: 64, color: textDim.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text('Aucun incident trouvé', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          Text('La ville est calme pour le moment.', style: TextStyle(color: textDim)),
        ],
      ),
    );
  }
}
