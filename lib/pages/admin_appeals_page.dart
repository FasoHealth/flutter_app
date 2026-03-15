import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class AdminAppealsPage extends StatefulWidget {
  const AdminAppealsPage({super.key});

  @override
  State<AdminAppealsPage> createState() => _AdminAppealsPageState();
}

class _AdminAppealsPageState extends State<AdminAppealsPage> {
  List<dynamic> _appeals = [];
  bool _loading = true;
  String? _replyingToId;
  final _replyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchAppeals();
  }

  Future<void> _fetchAppeals() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getAdminAppeals();
      if (mounted) {
        setState(() {
          _appeals = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleReply(String id) async {
    if (_replyController.text.trim().isEmpty) return;
    try {
      final success = await ApiService.replyToAppeal(id, _replyController.text.trim());
      if (success && mounted) {
        setState(() {
          _replyingToId = null;
          _replyController.clear();
        });
        _fetchAppeals();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors de l\'envoi.')));
    }
  }

  Future<void> _handleReactivate(dynamic appeal) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmer la réactivation"),
        content: Text("Voulez-vous vraiment réactiver le compte de ${appeal['user']['name']} ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("ANNULER")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("CONFIRMER")),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final success = await ApiService.toggleUserStatus(appeal['user']['_id']);
        if (success) {
          await ApiService.replyToAppeal(appeal['_id'], "Votre compte a été réactivé. Vous pouvez vous connecter.", status: 'resolved');
          _fetchAppeals();
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors de la réactivation.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.brandOrange))
                : _appeals.isEmpty
                    ? _buildEmptyState()
                    : _buildAppealsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shield_outlined, color: AppTheme.brandOrange, size: 24),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        "Recours de compte",
                        style: GoogleFonts.inter(
                          fontSize: 22, 
                          fontWeight: FontWeight.w700, 
                          color: const Color(0xFF222222)
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "Gérez les demandes de réactivation.",
                  style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF666666)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _fetchAppeals,
            icon: const Icon(Icons.refresh_rounded, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              side: const BorderSide(color: Color(0xFFE8E3DB)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppealsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _appeals.length,
      itemBuilder: (context, index) => _buildAppealCard(_appeals[index]),
    );
  }

  Widget _buildAppealCard(dynamic appeal) {
    final status = appeal['status'] ?? 'pending';
    final isReplying = _replyingToId == appeal['_id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F4EE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E3DB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(color: const Color(0xFF1A2035), borderRadius: BorderRadius.circular(12)),
                    child: Center(
                      child: Text(
                        appeal['user']?['name']?[0].toUpperCase() ?? 'U',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(appeal['user']?['name'] ?? "Utilisateur inconnu", style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
                      Text(appeal['email'] ?? "", style: GoogleFonts.inter(color: const Color(0xFF9BA3B4), fontSize: 13)),
                    ],
                  ),
                ],
              ),
              _buildStatusBadge(status),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("MESSAGE DE L'UTILISATEUR :", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: const Color(0xFF9BA3B4), letterSpacing: 1)),
                const SizedBox(height: 8),
                Text(appeal['message'] ?? "", style: GoogleFonts.inter(fontSize: 14, height: 1.5, color: const Color(0xFF222222))),
              ],
            ),
          ),
          if (appeal['adminReply'] != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.brandOrangePale,
                borderRadius: const BorderRadius.only(topRight: Radius.circular(12), bottomRight: Radius.circular(12)),
                border: const Border(left: BorderSide(color: AppTheme.brandOrange, width: 4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shield_outlined, size: 14, color: AppTheme.brandOrange),
                      const SizedBox(width: 8),
                      Text("RÉPONSE ADMIN", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.brandOrange, letterSpacing: 1)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(appeal['adminReply'], style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF222222))),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 16),
          if (isReplying)
            Column(
              children: [
                TextField(
                  controller: _replyController,
                  maxLines: 3,
                  decoration: const InputDecoration(hintText: "Tapez votre réponse pour l'utilisateur...", fillColor: Colors.white),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => setState(() => _replyingToId = null), child: const Text("Annuler")),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _handleReply(appeal['_id']),
                      icon: const Icon(Icons.send_rounded, size: 16),
                      label: const Text("Envoyer"),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandOrange),
                    ),
                  ],
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (status != 'resolved')
                  ElevatedButton.icon(
                    onPressed: () => _handleReactivate(appeal),
                    icon: const Icon(Icons.lock_open_rounded, size: 16),
                    label: const Text("Réactiver le compte"),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.green),
                  ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _replyingToId = appeal['_id'];
                      _replyController.text = appeal['adminReply'] ?? '';
                    });
                  },
                  icon: const Icon(Icons.reply_rounded, size: 16),
                  label: Text(appeal['adminReply'] == null ? "Répondre" : "Modifier la réponse"),
                  style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF1A2035)),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = AppTheme.yellow;
    String label = "EN ATTENTE";
    if (status == 'replied') { color = AppTheme.brandOrange; label = "RÉPONDU"; }
    if (status == 'resolved') { color = AppTheme.green; label = "RÉSOLU"; }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline_rounded, size: 64, color: Colors.grey.withOpacity(0.1)),
          const SizedBox(height: 20),
          Text("Aucune demande en attente", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
          Text("Tout semble en ordre ! Revenez plus tard.", style: GoogleFonts.inter(color: const Color(0xFF999999))),
        ],
      ),
    );
  }
}
