import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  bool _loading = false;
  String? _message;
  String? _error;
  bool _submitted = false;

  Future<void> _handleSubmit() async {
    if (_emailController.text.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
      _message = null;
    });

    try {
      final success = await ApiService.forgotPassword(_emailController.text.trim());
      if (success && mounted) {
        setState(() {
          _message = "Un lien de réinitialisation a été envoyé à votre adresse e-mail.";
          _submitted = true;
        });
      } else {
        setState(() => _error = "Impossible d'envoyer le lien. Vérifiez votre email.");
      }
    } catch (e) {
      setState(() => _error = "Une erreur est survenue.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: Row(
        children: [
          if (isDesktop)
            Expanded(
              flex: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.bgPrimary,
                  gradient: RadialGradient(
                    center: const Alignment(-0.4, 0.0),
                    radius: 0.6,
                    colors: [
                      AppTheme.brandOrange.withOpacity(0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                          ),
                          child: const Icon(Icons.flash_on_rounded, color: AppTheme.brandOrange, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Flash Alerte',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: const Color(0xFF222222), fontSize: 20),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            flex: 1,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40.0),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.chevron_left_rounded, size: 18),
                        label: const Text("Retour à la connexion"),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF9BA3B4),
                          padding: EdgeInsets.zero,
                          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (!_submitted) ...[
                        Text(
                          'Mot de passe oublié ?',
                          style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w700, color: const Color(0xFF222222), letterSpacing: -1),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Entrez votre adresse mail pour recevoir un lien de réinitialisation.',
                          style: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF666666)),
                        ),
                        const SizedBox(height: 32),
                        if (_error != null)
                          Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(color: const Color(0xFFFFF1F0), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFFA39E))),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded, color: Color(0xFFF5222D), size: 18),
                                const SizedBox(width: 8),
                                Expanded(child: Text(_error!, style: GoogleFonts.inter(color: const Color(0xFFF5222D), fontSize: 14))),
                              ],
                            ),
                          ),
                        Text('Adresse e-mail', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF222222))),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.mail_outline_rounded, size: 20),
                            hintText: 'votre@email.com',
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.brandOrange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _loading
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Envoyer le lien'),
                          ),
                        ),
                      ] else ...[
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 64, height: 64,
                                decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFD1FAE5)),
                                child: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 32),
                              ),
                              const SizedBox(height: 24),
                              Text('Vérifiez vos emails', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 12),
                              Text(_message!, textAlign: TextAlign.center, style: GoogleFonts.inter(color: const Color(0xFF5A6478), fontSize: 16, height: 1.6)),
                              const SizedBox(height: 32),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text('Retour à la connexion'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
