import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../models/incident_model.dart';
import '../widgets/messenger_dialog.dart';
import 'incident_detail_page.dart';

class AdminModerationPage extends StatefulWidget {
  const AdminModerationPage({super.key});

  @override
  State<AdminModerationPage> createState() => _AdminModerationPageState();
}

class _AdminModerationPageState extends State<AdminModerationPage> {
  String _statusFilter = 'pending';
  late Future<List<IncidentModel>> _future;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    final future = ApiService.getAdminIncidents(status: _statusFilter);
    setState(() {
      _future = future;
    });
  }

  void _openMessenger(IncidentModel inc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MessengerDialog(incidentId: inc.id, incidentTitle: inc.title),
    );
  }

  void _showModerateDialog(IncidentModel incident) {
    // Constraint: Can't moderate if already approved or rejected in a way that breaks user rules?
    // Actually, user said: "un incident approuver ne peut plus etre approuver" (obvious)
    // "un incident rejeter ne peut plus etre approver ni marquer resolue"
    // So if it's rejected, we hide TREAT button.

    final noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        title: Row(
          children: [
            const Icon(Icons.gavel_rounded, color: AppTheme.accentPurple),
            const SizedBox(width: 12),
            const Text('Modération', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(incident.title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Catégorie: ${incident.category.toUpperCase()}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              const SizedBox(height: 20),
              const Text('Motif ou commentaire :', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: noteController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Expliquez votre décision...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                  fillColor: AppTheme.bgDark,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Note : Le motif sera visible par le citoyen dans son historique.',
                style: TextStyle(color: Colors.amber, fontSize: 11, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('ANNULER', style: TextStyle(color: AppTheme.textSecondary)))),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    if (noteController.text.trim().isEmpty) {
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Un motif est requis pour rejeter un incident.')));
                       return;
                    }
                    final ok = await ApiService.moderateIncident(incident.id, 'rejected', noteController.text.trim());
                    if (mounted && ok) { Navigator.pop(context); _refresh(); }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed, foregroundColor: Colors.white),
                  child: const Text('REJETER'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final ok = await ApiService.moderateIncident(incident.id, 'approved', noteController.text.trim());
                    if (mounted && ok) { Navigator.pop(context); _refresh(); }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successGreen, foregroundColor: Colors.white),
                  child: const Text('APPROUVER'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.textPrimary : const Color(0xFF1E293B);
    final textDim = isDark ? AppTheme.textSecondary : const Color(0xFF64748B);
    final cardBg = isDark ? AppTheme.cardDark : Colors.white;

    return Column(
      children: [
        _buildHeader(textColor, textDim),
        _buildFilters(cardBg, textColor, textDim),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => _refresh(),
            color: AppTheme.accentPurple,
            child: FutureBuilder<List<IncidentModel>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return Center(child: Text('Erreur : ${snapshot.error}', style: const TextStyle(color: AppTheme.dangerRed)));
                
                final list = snapshot.data ?? [];
                if (list.isEmpty) return _buildEmptyState(textColor, textDim);

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  itemCount: list.length,
                  itemBuilder: (context, index) => _buildModerationTile(list[index], cardBg, textColor, textDim),
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
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Modération', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: textColor, letterSpacing: -0.5)),
              Text('Gérer la validité des signalements citoyens.', style: TextStyle(color: textDim, fontSize: 14)),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.accentPurple.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.gavel_rounded, color: AppTheme.accentPurple),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(Color cardBg, Color textColor, Color textDim) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          _filterChip('pending', 'À traiter', Icons.hourglass_empty),
          const SizedBox(width: 8),
          _filterChip('approved', 'Approuvés', Icons.check_circle_outline),
          const SizedBox(width: 8),
          _filterChip('rejected', 'Rejetés', Icons.cancel_outlined),
        ],
      ),
    );
  }

  Widget _filterChip(String status, String label, IconData icon) {
    final selected = _statusFilter == status;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() { _statusFilter = status; _refresh(); });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppTheme.accentPurple : AppTheme.cardDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? AppTheme.accentPurple : Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? Colors.white : AppTheme.textSecondary, size: 18),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: selected ? Colors.white : AppTheme.textSecondary, fontSize: 11, fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModerationTile(IncidentModel inc, Color cardBg, Color textColor, Color textDim) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => IncidentDetailPage(incident: inc))),
            title: Text(inc.title, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('${inc.category.toUpperCase()} • ${inc.location['address']}', style: TextStyle(color: textDim, fontSize: 13)),
            ),
          ),
          const Divider(height: 1, indent: 20, endIndent: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                // Messenger button
                InkWell(
                  onTap: () => _openMessenger(inc),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppTheme.accentPurple.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.forum_rounded, color: AppTheme.accentPurple, size: 18),
                  ),
                ),
                const SizedBox(width: 8),
                Text('Communiquer', style: TextStyle(color: AppTheme.accentPurple, fontSize: 11, fontWeight: FontWeight.bold)),
                const Spacer(),
                if (inc.status == 'pending')
                  ElevatedButton(
                    onPressed: () => _showModerateDialog(inc),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentPurple.withOpacity(0.1),
                      foregroundColor: AppTheme.accentPurple,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('MODÉRER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  )
                else
                  _statusBadge(inc.status),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color = AppTheme.successGreen;
    if (status == 'rejected') color = AppTheme.dangerRed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildEmptyState(Color textColor, Color textDim) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 64, color: textDim.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(_statusFilter == 'pending' ? 'Rien à modérer' : 'Aucun historique', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          Text('Tout est à jour ici.', style: TextStyle(color: textDim)),
        ],
      ),
    );
  }
}
