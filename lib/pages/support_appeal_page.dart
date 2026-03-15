import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class SupportAppealPage extends StatefulWidget {
  const SupportAppealPage({super.key});

  @override
  State<SupportAppealPage> createState() => _SupportAppealPageState();
}

class _SupportAppealPageState extends State<SupportAppealPage> {
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  final _checkEmailController = TextEditingController();
  bool _loading = false;
  bool _checking = false;
  Map<String, String>? _status;
  List<dynamic>? _appeals;

  Future<void> _handleSubmit() async {
    if (_emailController.text.isEmpty || _messageController.text.isEmpty) return;
    setState(() { _loading = true; _status = null; });
    try {
      final res = await ApiService.submitAppeal(_emailController.text.trim(), _messageController.text.trim());
      if (mounted) {
        setState(() {
          _status = {'type': 'success', 'text': res['message'] ?? 'Demande envoyée'};
          _emailController.clear();
          _messageController.clear();
        });
      }
    } catch (e) {
      if (mounted) setState(() => _status = {'type': 'error', 'text': 'Erreur lors de l\'envoi.'});
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleCheckStatus() async {
    if (_checkEmailController.text.isEmpty) return;
    setState(() => _checking = true);
    try {
      final data = await ApiService.getAppealStatus(_checkEmailController.text.trim());
      if (mounted) setState(() => _appeals = data);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur de vérification.')));
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: const Text("Support & Recours"),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: isDesktop 
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: _buildAppealForm()),
                  const SizedBox(width: 24),
                  Expanded(child: _buildStatusCheck()),
                ])
              : Column(children: [
                  _buildAppealForm(),
                  const SizedBox(height: 24),
                  _buildStatusCheck(),
                ]),
          ),
        ),
      ),
    );
  }

  Widget _buildAppealForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE8E3DB))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.shield_outlined, color: AppTheme.brandOrange, size: 24),
            const SizedBox(width: 12),
            Text("Envoyer un Recours", style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 12),
          Text("Votre compte est désactivé ? Expliquez-nous pourquoi il devrait être réactivé.", style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF5A6478))),
          const SizedBox(height: 24),
          if (_status != null) _buildAlert(),
          _buildFieldLabel("Email du compte"),
          TextField(controller: _emailController, decoration: const InputDecoration(hintText: "votre@email.com")),
          const SizedBox(height: 20),
          _buildFieldLabel("Message"),
          TextField(controller: _messageController, maxLines: 4, decoration: const InputDecoration(hintText: "Détails de votre demande...")),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandOrange, padding: const EdgeInsets.symmetric(vertical: 16)),
              child: Text(_loading ? "Envoi..." : "Envoyer la demande"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCheck() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFFF8F4EE), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE8E3DB))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.search_rounded, color: AppTheme.brandOrange, size: 24),
            const SizedBox(width: 12),
            Text("Vérifier l'état", style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 12),
          Text("Saisissez votre email pour voir si un administrateur vous a répondu.", style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF5A6478))),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: TextField(controller: _checkEmailController, decoration: const InputDecoration(hintText: "Votre email", fillColor: Colors.white))),
            const SizedBox(width: 12),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _checking ? null : _handleCheckStatus,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A2035)),
                child: Text(_checking ? "..." : "Vérifier"),
              ),
            ),
          ]),
          const SizedBox(height: 24),
          if (_appeals == null) 
            const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Icon(Icons.search_rounded, size: 48, color: Colors.black12)))
          else if (_appeals!.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Text("Aucune demande trouvée.")))
          else
            ..._appeals!.map((a) => _buildAppealItem(a)),
        ],
      ),
    );
  }

  Widget _buildAppealItem(dynamic a) {
    final isPending = a['status'] == 'pending';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE8E3DB))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(DateTime.parse(a['createdAt']).toLocal().toString().split(' ')[0], style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF9BA3B4))),
          _buildBadge(isPending ? "En attente" : "Répondu", isPending ? AppTheme.yellow : AppTheme.green),
        ]),
        const SizedBox(height: 12),
        Text(a['message'], style: GoogleFonts.inter(fontSize: 13, height: 1.5), maxLines: 2, overflow: TextOverflow.ellipsis),
        if (a['adminReply'] != null) ...[
          const Divider(height: 24),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: AppTheme.brandOrange),
            const SizedBox(width: 8),
            Expanded(child: Text(a['adminReply'], style: GoogleFonts.inter(fontSize: 13, color: AppTheme.brandOrange, fontWeight: FontWeight.w600))),
          ]),
        ],
      ]),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
    );
  }

  Widget _buildAlert() {
    final isError = _status!['type'] == 'error';
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(color: isError ? const Color(0xFFFFF1F0) : const Color(0xFFF6FFED), borderRadius: BorderRadius.circular(8), border: Border.all(color: isError ? const Color(0xFFFFA39E) : const Color(0xFFB7EB8F))),
      child: Row(children: [
        Icon(isError ? Icons.error_outline : Icons.check_circle_outline, size: 16, color: isError ? AppTheme.red : AppTheme.green),
        const SizedBox(width: 8),
        Expanded(child: Text(_status!['text']!, style: GoogleFonts.inter(fontSize: 13, color: isError ? AppTheme.red : AppTheme.green))),
      ]),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)));
  }
}
