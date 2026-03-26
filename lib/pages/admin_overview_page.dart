import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class AdminOverviewPage extends StatefulWidget {
  const AdminOverviewPage({super.key});

  @override
  State<AdminOverviewPage> createState() => _AdminOverviewPageState();
}

class _AdminOverviewPageState extends State<AdminOverviewPage> {
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getAdminStats();
      if (mounted) {
        setState(() {
          _stats = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.brandOrange));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 32),
          _buildStatGrid(),
          const SizedBox(height: 32),
          _buildChartsRow(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shield_rounded, color: AppTheme.brandOrange, size: 24),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          "Administration",
                          style: GoogleFonts.inter(
                            fontSize: 24, 
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
                    "Vue d'ensemble de l'activité du système.",
                    style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF666666)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF1A2035), Color(0xFF2E3D6A)]),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 14),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatGrid() {
    final s = _stats?['incidents'] ?? {};
    return LayoutBuilder(builder: (context, constraints) {
      // Pour des petits carrés, on peut essayer d'en mettre 3 par ligne sur mobile
      final int crossAxisCount = constraints.maxWidth > 500 ? 4 : 3;
      final double spacing = 10;
      final double cardWidth = (constraints.maxWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;

      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          _buildStatCard('Total', s['total']?.toString() ?? '0', Icons.warning_amber_rounded, AppTheme.brandOrange, AppTheme.brandOrangePale, cardWidth),
          _buildStatCard('Attente', s['pending']?.toString() ?? '0', Icons.access_time_rounded, AppTheme.yellow, AppTheme.yellowBg, cardWidth),
          _buildStatCard('Approuvés', s['approved']?.toString() ?? '0', Icons.check_circle_outline_rounded, AppTheme.blue, AppTheme.blueBg, cardWidth),
          _buildStatCard('Résolus', s['resolved']?.toString() ?? '0', Icons.emoji_events_outlined, AppTheme.green, AppTheme.greenBg, cardWidth),
          _buildStatCard('Recours', 'Gérer', Icons.help_outline_rounded, AppTheme.purple, AppTheme.purpleBg, cardWidth),
        ],
      );
    });
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, Color bgColor, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E3DB)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value, 
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF222222)),
            textAlign: TextAlign.center,
          ),
          Text(
            label, 
            style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF666666), fontWeight: FontWeight.w500), 
            maxLines: 1, 
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChartsRow() {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: _buildChartCard(
              title: "Incidents des 7 derniers jours",
              icon: Icons.bar_chart_rounded,
              child: Container(
                height: 300,
                alignment: Alignment.center,
                child: _buildBarChartPlaceholder(),
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 2,
            child: _buildChartCard(
              title: "Répartition par Catégorie",
              icon: Icons.pie_chart_outline_rounded,
              child: Container(
                height: 300,
                alignment: Alignment.center,
                child: _buildPieChartPlaceholder(),
              ),
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          _buildChartCard(
            title: "Incidents des 7 derniers jours",
            icon: Icons.bar_chart_rounded,
            child: Container(
              height: 250,
              alignment: Alignment.center,
              child: _buildBarChartPlaceholder(),
            ),
          ),
          const SizedBox(height: 24),
          _buildChartCard(
            title: "Répartition par Catégorie",
            icon: Icons.pie_chart_outline_rounded,
            child: Container(
              height: 250,
              alignment: Alignment.center,
              child: _buildPieChartPlaceholder(),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildChartCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E3DB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.brandOrange, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildBarChartPlaceholder() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = (constraints.maxWidth / 7) - 8;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(7, (i) {
            final height = [40.0, 80.0, 120.0, 60.0, 100.0, 150.0, 90.0][i];
            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: barWidth > 0 ? barWidth.clamp(10, 30) : 10,
                  height: height,
                  decoration: BoxDecoration(
                    color: AppTheme.brandOrange,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "${i + 1} Mar",
                  style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF999999)),
                ),
              ],
            );
          }),
        );
      },
    );
  }

  Widget _buildPieChartPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.brandOrange, width: 20),
          ),
          child: const Center(child: Text("100%", style: TextStyle(fontWeight: FontWeight.bold))),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          children: [
            _buildLegendItem("Vol", AppTheme.red),
            _buildLegendItem("Feu", AppTheme.brandOrange),
            _buildLegendItem("Autre", AppTheme.blue),
          ],
        )
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
