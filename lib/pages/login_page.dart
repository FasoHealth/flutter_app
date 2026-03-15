import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../layout/main_shell.dart';
import 'register_page.dart';
import 'forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPwd = false;
  String? _error;
  bool _loading = false;

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _error = "Veuillez remplir tous les champs.");
      return;
    }

    setState(() {
      _error = null;
      _loading = true;
    });

    try {
      final result = await ApiService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (result['success']) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainShell(isDarkMode: false)),
          );
        }
      } else {
        setState(() => _error = result['message'] ?? "Identifiants invalides ou compte désactivé.");
      }
    } catch (e) {
      setState(() => _error = "Erreur lors de la connexion. Veuillez réessayer.");
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
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF222222),
                              fontSize: 20,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      constraints: const BoxConstraints(maxWidth: 320),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 50,
                            offset: const Offset(0, 20),
                          )
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.network(
                          'https://cominity-system-management.onrender.com/memorial.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 400,
                            color: Colors.grey[200],
                            child: const Icon(Icons.image_outlined, size: 50, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      'Votre sécurité,\nnotre communauté.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF222222),
                        height: 1.2,
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
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Bon retour',
                            style: GoogleFonts.inter(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF222222),
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '•',
                            style: TextStyle(color: AppTheme.brandOrange, fontSize: 32, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Veuillez entrer vos coordonnées pour vous connecter.',
                        style: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF666666)),
                      ),
                      const SizedBox(height: 32),
                      if (_error != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1F0),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFFA39E)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded, color: Color(0xFFF5222D), size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: GoogleFonts.inter(color: const Color(0xFFF5222D), fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                              if (_error!.contains('désactivé'))
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: OutlinedButton.icon(
                                    onPressed: () => Navigator.pushNamed(context, '/support-appeal'),
                                    icon: const Icon(Icons.shield_outlined, size: 16),
                                    label: const Text('Contacter un administrateur'),
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: const Color(0xFF222222),
                                      side: const BorderSide(color: Color(0xFFD9D9D9)),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      Text(
                        'Adresse e-mail',
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF222222)),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.mail_outline_rounded, size: 20),
                          hintText: 'votre@email.com',
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Mot de passe',
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF222222)),
                          ),
                          TextButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordPage())),
                            child: Text(
                              'Mot de passe oublié ?',
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.brandOrange),
                            ),
                          ),
                        ],
                      ),
                      TextField(
                        controller: _passwordController,
                        obscureText: !_showPwd,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                          hintText: '••••••••',
                          suffixIcon: IconButton(
                            icon: Icon(_showPwd ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                            onPressed: () => setState(() => _showPwd = !_showPwd),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _handleLogin,
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
                                    Text('Se connecter', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16)),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.chevron_right_rounded, size: 20),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Nouveau ici ? ', style: GoogleFonts.inter(color: const Color(0xFF666666), fontSize: 14)),
                            GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage())),
                              child: Text(
                                'Créer un compte',
                                style: GoogleFonts.inter(color: AppTheme.brandOrange, fontWeight: FontWeight.w700, fontSize: 14),
                              ),
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
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE8E3DB))),
              ),
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

  Widget _footerLink(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(text, style: GoogleFonts.inter(color: const Color(0xFF999999), fontSize: 12)),
    );
  }
}
