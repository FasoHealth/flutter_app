import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ResetPasswordPage extends StatefulWidget {
  final String token;
  const ResetPasswordPage({super.key, required this.token});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _showPwd = false;
  bool _loading = false;
  bool _success = false;
  String? _error;

  Future<void> _handleSubmit() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _error = 'Les mots de passe ne correspondent pas.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final success = await ApiService.resetPassword(widget.token, _passwordController.text);
      if (success && mounted) {
        setState(() => _success = true);
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
        });
      } else {
        setState(() => _error = "Le lien est invalide ou a expiré.");
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
                decoration: const BoxDecoration(
                  color: AppTheme.bgPrimary,
                  image: DecorationImage(
                    image: AssetImage('assets/images/auth_bg_pattern.png'),
                    fit: BoxFit.cover,
                    opacity: 0.1,
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
            child: Container(
              color: Colors.white,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(40.0),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!_success) ...[
                          Text(
                            'Nouveau mot de passe',
                            style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w700, color: const Color(0xFF222222), letterSpacing: -1),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Définissez votre nouveau mot de passe sécurisé.',
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
                          Text('Nouveau mot de passe', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF222222))),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _passwordController,
                            obscureText: !_showPwd,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                              hintText: 'Min. 8 caractères',
                              suffixIcon: IconButton(
                                icon: Icon(_showPwd ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                                onPressed: () => setState(() => _showPwd = !_showPwd),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text('Confirmer le mot de passe', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF222222))),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _confirmPasswordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.lock_outline_rounded, size: 20),
                              hintText: '••••••••',
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
                                  : const Text('Réinitialiser le mot de passe'),
                            ),
                          ),
                        ] else ...[
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  width: 64, height: 64,
                                  decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFD1FAE5)),
                                  child: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 32),
                                ),
                                const SizedBox(height: 24),
                                Text('Succès !', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 12),
                                Text(
                                  'Votre mot de passe a été mis à jour. Vous allez être redirigé vers la page de connexion.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(color: const Color(0xFF5A6478), fontSize: 16, height: 1.6),
                                ),
                                const SizedBox(height: 32),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.brandOrange,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 18),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: const Text('Se connecter maintenant'),
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
