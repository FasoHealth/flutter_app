import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'login_page.dart';
import 'register_page.dart';
import 'report_incident_page.dart';
import '../services/translation_service.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.5,
              height: MediaQuery.of(context).size.width * 0.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.brandOrange.withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -100,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.6,
              height: MediaQuery.of(context).size.width * 0.6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF3B82F6).withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Column(
            children: [

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppTheme.brandOrange,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(color: AppTheme.brandOrange.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
                            ],
                          ),
                          child: const Icon(Icons.shield_outlined, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "CS Alert",
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () => T.toggleLanguage(),
                          icon: const Icon(Icons.language_rounded, size: 16),
                          label: Text(
                            T.locale.value == 'fr' ? "EN" : "FR", 
                            style: GoogleFonts.inter(
                              fontSize: 13, 
                              fontWeight: FontWeight.w800,
                              color: AppTheme.brandOrange
                            )
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.textPrimary,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            minimumSize: Size.zero,
                            backgroundColor: AppTheme.brandOrange.withOpacity(0.05),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(width: 4),
                        ElevatedButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage())),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.textPrimary,
                            side: const BorderSide(color: Color(0xFFE8E3DB)),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          child: Text(T.get('login')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.brandOrangePale,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: AppTheme.brandOrange.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.flash_on_rounded, color: AppTheme.brandOrange, size: 14),
                            const SizedBox(width: 8),
                            Text(
                              T.get('home_title'),
                              style: GoogleFonts.inter(color: AppTheme.brandOrange, fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        T.get('home_subtitle'),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textPrimary,
                          height: 1.1,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        T.get('home_desc'),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: AppTheme.textSecondary,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 48),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        alignment: WrapAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportIncidentPage())),
                            icon: const Icon(Icons.notifications_active_outlined, size: 20),
                            label: Text(T.get('report')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.brandOrange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                              elevation: 8,
                              shadowColor: AppTheme.brandOrange.withOpacity(0.3),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage())),
                            icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                            label: Text(T.get('register')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppTheme.textPrimary,
                              side: const BorderSide(color: Color(0xFFE8E3DB)),
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                              elevation: 0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 80),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: MediaQuery.of(context).size.width > 800 ? 3 : 1,
                        childAspectRatio: MediaQuery.of(context).size.width > 800 ? 1.2 : 0.6,
                        crossAxisSpacing: 24,
                        mainAxisSpacing: 24,
                        children: [
                          _buildFeatureCard(
                            icon: Icons.notifications_active_outlined,
                            title: "Alertes en temps réel",
                            desc: "Soyez informé instantanément des incidents signalés dans votre zone géographique pour rester en sécurité.",
                            color: const Color(0xFFEF4444),
                          ),
                          _buildFeatureCard(
                            icon: Icons.map_outlined,
                            title: "Cartographie précise",
                            desc: "Visualisez les zones à risque sur une carte interactive mise à jour par les citoyens et modérée par nos équipes.",
                            color: const Color(0xFF3B82F6),
                          ),
                          _buildFeatureCard(
                            icon: Icons.verified_user_outlined,
                            title: "Modération fiable",
                            desc: "Un système de validation par la communauté garantit la fiabilité des alertes pour éviter les fausses informations.",
                            color: const Color(0xFF10B981),
                          ),
                        ],
                      ),
                      const SizedBox(height: 80),
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Text(
                          "© 2024 Community Security Alert - CS27 Groupe 16. Tous droits réservés.",
                          style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({required IconData icon, required String title, required String desc, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8E3DB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 12),
          Text(
            desc,
            style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary, height: 1.6),
          ),
        ],
      ),
    );
  }
}
