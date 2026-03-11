import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.textPrimary : const Color(0xFF1E293B);
    final textDim = isDark ? AppTheme.textSecondary : const Color(0xFF64748B);
    final cardBg = isDark ? AppTheme.cardDark : Colors.white;

    // Remove redundant Scaffold (already provided by MainShell)
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Notifications', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: textColor, letterSpacing: -0.5)),
                  Text('Restez informé de l\'activité de votre quartier.', style: TextStyle(color: textDim, fontSize: 14)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.notifications_active_rounded, color: Colors.amber),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(40),
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.amber.withOpacity(0.05), shape: BoxShape.circle),
                    child: Icon(Icons.notifications_none_rounded, size: 64, color: textDim.withOpacity(0.5)),
                  ),
                  const SizedBox(height: 24),
                  Text('Tout est calme', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textColor)),
                  const SizedBox(height: 8),
                  Text('Vous n\'avez reçu aucune nouvelle notification pour le moment.', textAlign: TextAlign.center, style: TextStyle(color: textDim, height: 1.5)),
                  const SizedBox(height: 32),
                  TextButton(
                    onPressed: () {},
                    child: const Text('ACTIVER LES ALERTES CRITIQUES', style: TextStyle(color: AppTheme.accentPurple, fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
