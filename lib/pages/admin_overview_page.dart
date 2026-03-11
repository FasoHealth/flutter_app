import 'package:flutter/material.dart';
import 'dart:math';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

// ── Point de données pour le graphique barres ─────────────────────────────────
class BarData {
  final String label;
  final double value;
  BarData(this.label, this.value);
}

// ── Point de données pour le graphique camembert ─────────────────────────────
class PieData {
  final String label;
  final double value;
  final Color color;
  PieData(this.label, this.value, this.color);
}

class AdminOverviewPage extends StatefulWidget {
  const AdminOverviewPage({super.key});

  @override
  State<AdminOverviewPage> createState() => _AdminOverviewPageState();
}

class _AdminOverviewPageState extends State<AdminOverviewPage> with TickerProviderStateMixin {
  late Future<Map<String, dynamic>> _statsFuture;
  
  late AnimationController _kpiController;
  late AnimationController _chartController;
  late Animation<double> _kpiFade;
  late Animation<double> _chartFade;
  late Animation<double> _barAnimation;

  @override
  void initState() {
    super.initState();
    _statsFuture = ApiService.getAdminStats();

    _kpiController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _chartController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));

    _kpiFade = CurvedAnimation(parent: _kpiController, curve: Curves.easeOut);
    _chartFade = CurvedAnimation(parent: _chartController, curve: Curves.easeOut);
    _barAnimation = CurvedAnimation(parent: _chartController, curve: Curves.easeOutCubic);

    _kpiController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _chartController.forward();
    });
  }

  @override
  void dispose() {
    _kpiController.dispose();
    _chartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.textPrimary : const Color(0xFF1E293B);
    final textDim = isDark ? AppTheme.textSecondary : const Color(0xFF64748B);
    final cardBg = isDark ? AppTheme.cardDark : Colors.white;

    // Remove redundant Scaffold
    return FutureBuilder<Map<String, dynamic>>(
      future: _statsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('Erreur : ${snapshot.error}', style: const TextStyle(color: Colors.red)));

        final stats = snapshot.data?['stats'];
        if (stats == null) return const Center(child: Text('Aucune donnée disponible.'));

        final incidents = stats['incidents'] ?? {};
        
        final List<Map<String, dynamic>> kpiItems = [
          {'label': 'TOTAL INCIDENTS', 'value': incidents['total'] ?? 0, 'icon': '🚨', 'accent': const Color(0xFFE8453C)},
          {'label': 'À MODÉRER', 'value': incidents['pending'] ?? 0, 'icon': '⏳', 'accent': const Color(0xFFF59E0B)},
          {'label': 'APPROUVÉS', 'value': incidents['approved'] ?? 0, 'icon': '✅', 'accent': const Color(0xFF6C63FF)},
          {'label': 'CAS RÉSOLUS', 'value': incidents['resolved'] ?? 0, 'icon': '🏆', 'accent': const Color(0xFFFFD700)},
        ];

        final List<BarData> barItems = (stats['last7Days'] as List? ?? []).map((e) {
          String dateStr = e['_id'] ?? '??'; // YYYY-MM-DD
          try {
            DateTime dt = DateTime.parse(dateStr);
            return BarData('${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}', (e['count'] as int? ?? 0).toDouble());
          } catch(_) {
            return BarData(dateStr, (e['count'] as int? ?? 0).toDouble());
          }
        }).toList();

        final List<Color> colors = [const Color(0xFFE8453C), const Color(0xFFF59E0B), const Color(0xFFFFD700), const Color(0xFF6C63FF), Colors.cyan, Colors.teal];
        final List<PieData> pieItems = [];
        final byCat = stats['byCategory'] as List? ?? [];
        for (int i = 0; i < byCat.length; i++) {
          pieItems.add(PieData(byCat[i]['_id'].toString(), (byCat[i]['count'] as int? ?? 0).toDouble(), colors[i % colors.length]));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(textColor, textDim, cardBg),
              const SizedBox(height: 28),
              FadeTransition(
                opacity: _kpiFade,
                child: _buildKpiRow(kpiItems),
              ),
              const SizedBox(height: 24),
              FadeTransition(
                opacity: _chartFade,
                child: _buildChartsRow(barItems, pieItems, cardBg, textColor, textDim),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(Color textColor, Color textDim, Color cardBg) {
    return Row(
      children: [
        Text('Administration', style: TextStyle(color: textColor, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: const Color(0xFF6C63FF).withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.shield, color: Color(0xFF6C63FF), size: 20),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white.withOpacity(0.06))),
          child: Row(
            children: [
              Icon(Icons.calendar_today_outlined, color: textDim, size: 14),
              const SizedBox(width: 6),
              Text('Mars 2026', style: TextStyle(color: textDim, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKpiRow(List<Map<String, dynamic>> kpiItems) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 18 * 3) / 4;
        return Row(
          children: List.generate(kpiItems.length, (i) {
            return Row(
              children: [
                SizedBox(
                  width: cardWidth,
                  child: _KpiCard(
                    label: kpiItems[i]['label'],
                    value: kpiItems[i]['value'],
                    icon: kpiItems[i]['icon'],
                    accent: kpiItems[i]['accent'],
                  ),
                ),
                if (i < kpiItems.length - 1) const SizedBox(width: 18),
              ],
            );
          }),
        );
      },
    );
  }

  Widget _buildChartsRow(List<BarData> barItems, List<PieData> pieItems, Color cardBg, Color textColor, Color textDim) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 6, child: _buildBarChart(barItems, cardBg, textColor, textDim)),
        const SizedBox(width: 20),
        Expanded(flex: 4, child: _buildPieChart(pieItems, cardBg, textColor, textDim)),
      ],
    );
  }

  Widget _buildBarChart(List<BarData> barItems, Color cardBg, Color textColor, Color textDim) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.06))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Incidents des 7 derniers jours', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: AnimatedBuilder(
              animation: _barAnimation,
              builder: (context, child) {
                return _BarChartWidget(
                  data: barItems,
                  animationValue: _barAnimation.value,
                  barColor: const Color(0xFFE8453C),
                  gridColor: textColor.withOpacity(0.06),
                  labelColor: textDim,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(List<PieData> pieItems, Color cardBg, Color textColor, Color textDim) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.06))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Répartition par Catégorie', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Center(
            child: AnimatedBuilder(
              animation: _barAnimation,
              builder: (context, _) {
                return _DonutChartWidget(
                  data: pieItems,
                  animationValue: _barAnimation.value,
                  size: 160,
                  innerColor: cardBg,
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: pieItems.map((p) => _LegendItem(data: p, textDim: textDim)).toList(),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final int value;
  final String icon;
  final Color accent;

  const _KpiCard({required this.label, required this.value, required this.icon, required this.accent});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1A1D27) : Colors.white;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [BoxShadow(color: accent.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: accent.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text(icon, style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(height: 16),
          Text('$value', style: TextStyle(color: accent, fontSize: 36, fontWeight: FontWeight.w900, height: 1)),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Color(0xFF8B92A5), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
        ],
      ),
    );
  }
}

class _BarChartWidget extends StatelessWidget {
  final List<BarData> data;
  final double animationValue;
  final Color barColor;
  final Color gridColor;
  final Color labelColor;

  const _BarChartWidget({required this.data, required this.animationValue, required this.barColor, required this.gridColor, required this.labelColor});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BarPainter(data: data, animationValue: animationValue, barColor: barColor, gridColor: gridColor, labelColor: labelColor),
      child: const SizedBox.expand(),
    );
  }
}

class _BarPainter extends CustomPainter {
  final List<BarData> data;
  final double animationValue;
  final Color barColor;
  final Color gridColor;
  final Color labelColor;

  _BarPainter({required this.data, required this.animationValue, required this.barColor, required this.gridColor, required this.labelColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final double maxVal = data.map((e) => e.value).reduce(max);
    final double displayMax = maxVal == 0 ? 1 : maxVal;
    final double chartH = size.height - 30;
    final double chartW = size.width;
    const int gridLines = 4;

    final gridPaint = Paint()..color = gridColor..strokeWidth = 1;
    for (int i = 0; i <= gridLines; i++) {
        final y = chartH - (chartH / gridLines * i);
        canvas.drawLine(Offset(0, y), Offset(chartW, y), gridPaint);
        final val = (displayMax / gridLines * i).round();
        final tp = TextPainter(text: TextSpan(text: '$val', style: TextStyle(color: labelColor, fontSize: 10)), textDirection: TextDirection.ltr);
        tp.layout();
        tp.paint(canvas, Offset(-22, y - tp.height / 2));
    }

    final double barW = (chartW / data.length) * 0.5;
    final double gap  = (chartW / data.length) * 0.5;

    for (int i = 0; i < data.length; i++) {
      final x = i * (barW + gap) + gap / 2;
      final barH = displayMax > 0 ? (data[i].value / displayMax) * chartH * animationValue : 0.0;
      final y = chartH - barH;
      final rect = RRect.fromRectAndRadius(Rect.fromLTWH(x, y, barW, barH), const Radius.circular(6));
      final barPaint = Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [barColor, barColor.withOpacity(0.7)]).createShader(Rect.fromLTWH(x, y, barW, barH));
      canvas.drawRRect(rect, barPaint);

      final tp = TextPainter(text: TextSpan(text: data[i].label, style: TextStyle(color: labelColor, fontSize: 9)), textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, Offset(x + barW / 2 - tp.width / 2, chartH + 8));
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) => old.animationValue != animationValue;
}

class _DonutChartWidget extends StatelessWidget {
  final List<PieData> data;
  final double animationValue;
  final double size;
  final Color innerColor;

  const _DonutChartWidget({required this.data, required this.animationValue, required this.size, required this.innerColor});

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: size, height: size, child: CustomPaint(painter: _DonutPainter(data: data, animationValue: animationValue, innerColor: innerColor)));
  }
}

class _DonutPainter extends CustomPainter {
  final List<PieData> data;
  final double animationValue;
  final Color innerColor;

  _DonutPainter({required this.data, required this.animationValue, required this.innerColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeW = radius * 0.38;
    double startAngle = -pi / 2;
    final total = data.fold(0.0, (sum, d) => sum + d.value);
    if (total == 0) return;

    for (final d in data) {
      final sweep = (d.value / total) * 2 * pi * animationValue;
      final paint = Paint()..color = d.color..style = PaintingStyle.stroke..strokeWidth = strokeW..strokeCap = StrokeCap.butt;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius - strokeW / 2), startAngle, sweep - 0.04, false, paint);
      startAngle += sweep;
    }
    canvas.drawCircle(center, radius - strokeW, Paint()..color = innerColor..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.animationValue != animationValue;
}

class _LegendItem extends StatelessWidget {
  final PieData data;
  final Color textDim;
  const _LegendItem({required this.data, required this.textDim});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: data.color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(data.label.toUpperCase(), style: TextStyle(color: textDim, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
