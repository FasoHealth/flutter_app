import 'package:flutter/material.dart';

class ActionsRapidesWidget extends StatelessWidget {
  final VoidCallback? onNouveauSignalement;
  final VoidCallback? onVoirNotifications;
  final VoidCallback? onParcourirCarte;

  const ActionsRapidesWidget({
    super.key,
    this.onNouveauSignalement,
    this.onVoirNotifications,
    this.onParcourirCarte,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Couleurs Mode Sombre & Mode Clair
    final cardBg = isDark ? const Color(0xFF1E1E2E) : const Color(0xFFFFFFFF);
    final secondaryButtonBg = isDark ? const Color(0xFF2A2A3E) : const Color(0xFFF5F5F5);
    final borderColor = isDark ? const Color(0xFF3A3A5C) : const Color(0xFFE0E0E0);
    final textColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF1A1A2E);
    final primaryButtonBg = const Color(0xFFE8453C);
    final primaryButtonText = const Color(0xFFFFFFFF);
    final infoBg = isDark ? const Color(0xFF2A2A3E) : const Color(0xFFFFF5F5);
    final infoTitleColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF1A1A2E);
    final infoDescColor = isDark ? const Color(0xFF8888AA) : const Color(0xFF888888);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actions Rapides',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onNouveauSignalement ?? () => Navigator.pushNamed(context, '/nouveau-signalement'),
            icon: Icon(Icons.add, color: primaryButtonText),
            label: Text(
              'Nouveau Signalement',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryButtonText),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryButtonBg,
              foregroundColor: primaryButtonText,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onVoirNotifications ?? () => Navigator.pushNamed(context, '/notifications'),
            icon: const Text('🔔', style: TextStyle(fontSize: 18)),
            label: Text('Voir Notifications', style: TextStyle(fontSize: 15, color: textColor)),
            style: OutlinedButton.styleFrom(
              foregroundColor: textColor,
              backgroundColor: secondaryButtonBg,
              minimumSize: const Size(double.infinity, 50),
              side: BorderSide(color: borderColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onParcourirCarte ?? () => Navigator.pushNamed(context, '/carte'),
            icon: const Text('🔍', style: TextStyle(fontSize: 18)),
            label: Text('Parcourir la carte', style: TextStyle(fontSize: 15, color: textColor)),
            style: OutlinedButton.styleFrom(
              foregroundColor: textColor,
              backgroundColor: secondaryButtonBg,
              minimumSize: const Size(double.infinity, 50),
              side: BorderSide(color: borderColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
          const SizedBox(height: 16),
          // Info Card with left border issue fix by using clipBehavior combined with BoxDecoration
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: infoBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                border: Border(left: BorderSide(color: Color(0xFFE8453C), width: 4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('💡', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text(
                        'Saviez-vous que ?',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: infoTitleColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Plus vous apportez de détails et de photos précises, plus vite l\'incident sera traité par les autorités.',
                    style: TextStyle(
                      fontSize: 13,
                      color: infoDescColor,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
