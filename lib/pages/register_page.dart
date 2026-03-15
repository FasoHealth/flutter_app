import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../layout/main_shell.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  String _role = 'citizen';
  bool _loading = false;
  String? _error;

  Future<void> _handleRegister() async {
    setState(() => _error = null);

    if (_passwordController.text.length < 8 || !RegExp(r'\d').hasMatch(_passwordController.text)) {
      setState(() => _error = 'Le mot de passe doit contenir au moins 8 caractères et au moins un chiffre.');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _error = 'Les mots de passe ne correspondent pas.');
      return;
    }

    setState(() => _loading = true);

    try {
      final result = await ApiService.register({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'phone': _phoneController.text.trim(),
        'role': _role,
      });

      if (result['success']) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainShell(isDarkMode: false)),
          );
        }
      } else {
        setState(() => _error = result['message'] ?? "Erreur lors de l'inscription.");
      }
    } catch (e) {
      setState(() => _error = "Erreur lors de l'inscription. Veuillez réessayer.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          if (isDesktop)
            Expanded(
              flex: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.bgPrimary,
                  gradient: RadialGradient(
                    center: const Alignment(0.4, -0.4),
                    radius: 0.6,
                    colors: [
                      AppTheme.brandOrange.withOpacity(0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
                              ],
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
                    ),
                    const Spacer(),
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
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Créer un compte',
                        style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w700, color: const Color(0xFF222222), letterSpacing: -1),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Rejoignez des milliers de citoyens qui protègent leur quartier.',
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
                              const SizedBox(width: 10),
                              Expanded(child: Text(_error!, style: GoogleFonts.inter(color: const Color(0xFFF5222D), fontSize: 14))),
                            ],
                          ),
                        ),
                      Row(
                        children: [
                          Expanded(child: _buildLabel('Nom complet')),
                          const SizedBox(width: 20),
                          Expanded(child: _buildLabel('Téléphone (optionnel)')),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _nameController,
                              decoration: const InputDecoration(prefixIcon: Icon(Icons.person_outline_rounded, size: 20), hintText: 'Jean Dupont'),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(prefixIcon: Icon(Icons.phone_outlined, size: 20), hintText: '07 00 00 00 00'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildLabel('Adresse e-mail'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(prefixIcon: Icon(Icons.mail_outline_rounded, size: 20), hintText: 'votre@email.com'),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(child: _buildLabel('Mot de passe')),
                          const SizedBox(width: 20),
                          Expanded(child: _buildLabel('Confirmer')),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  controller: _passwordController,
                                  obscureText: true,
                                  decoration: const InputDecoration(prefixIcon: Icon(Icons.lock_outline_rounded, size: 20), hintText: '••••••••'),
                                ),
                                const SizedBox(height: 4),
                                Text('8 caractères min., dont 1 chiffre.', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF666666))),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: TextField(
                              controller: _confirmPasswordController,
                              obscureText: true,
                              decoration: const InputDecoration(prefixIcon: Icon(Icons.lock_outline_rounded, size: 20), hintText: '••••••••'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildLabel('Vous êtes'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _role = 'citizen'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _role == 'citizen' ? AppTheme.brandOrangePale : AppTheme.bgPrimary,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: _role == 'citizen' ? AppTheme.brandOrange : AppTheme.border, width: 2),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.person_outline_rounded, size: 18, color: _role == 'citizen' ? AppTheme.brandOrange : const Color(0xFF222222)),
                                    const SizedBox(width: 10),
                                    Text('Citoyen', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: _role == 'citizen' ? AppTheme.brandOrange : const Color(0xFF222222))),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.brandOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: _loading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Créer mon compte', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16)),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.arrow_forward_rounded, size: 20),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Déjà inscrit ? ', style: GoogleFonts.inter(color: const Color(0xFF666666), fontSize: 14)),
                            GestureDetector(
                              onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage())),
                              child: Text('Se connecter', style: GoogleFonts.inter(color: AppTheme.brandOrange, fontWeight: FontWeight.w700, fontSize: 14)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 40),
              decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFE8E3DB)))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _footerLink('Aide'),
                  _footerLink('Confidentialité'),
                  _footerLink('Conditions'),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF222222)));
  }

  Widget _footerLink(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(text, style: GoogleFonts.inter(color: const Color(0xFF999999), fontSize: 12)),
    );
  }
}
