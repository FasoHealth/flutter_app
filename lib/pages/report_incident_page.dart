import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';

class ReportIncidentPage extends StatefulWidget {
  const ReportIncidentPage({super.key});

  @override
  State<ReportIncidentPage> createState() => _ReportIncidentPageState();
}

class _ReportIncidentPageState extends State<ReportIncidentPage> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _addressController = TextEditingController();
  final _picker = ImagePicker();

  String _selectedCategory = 'other';
  String _selectedSeverity = 'medium';
  bool _isAnonymous = false;
  bool _isLoading = false;
  bool _isLoadingLocation = false;
  List<XFile> _images = [];
  double? _latitude;
  double? _longitude;

  static const List<Map<String, String>> categories = [
    {'value': 'theft', 'label': 'Vol'},
    {'value': 'assault', 'label': 'Agression'},
    {'value': 'vandalism', 'label': 'Vandalisme'},
    {'value': 'fire', 'label': 'Incendie'},
    {'value': 'accident', 'label': 'Accident'},
    {'value': 'other', 'label': 'Autre'},
  ];

  static const List<Map<String, String>> severities = [
    {'value': 'low', 'label': 'Faible'},
    {'value': 'medium', 'label': 'Moyen'},
    {'value': 'high', 'label': 'Élevé'},
    {'value': 'critical', 'label': 'Critique'},
  ];

  Future<void> _pickImages() async {
    if (_images.length >= 4) return;
    try {
      final list = await _picker.pickMultiImage(imageQuality: 70, maxWidth: 1024);
      if (list.isEmpty) return;
      setState(() {
        for (var x in list) {
          if (_images.length < 4) _images.add(x);
        }
      });
    } catch (_) {}
  }

  Future<void> _myPosition() async {
    if (_isLoadingLocation) return;
    setState(() => _isLoadingLocation = true);
    final result = await LocationService.getCurrentPosition(fetchAddress: true);
    if (!mounted) return;
    setState(() => _isLoadingLocation = false);

    if (result != null) {
      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;
        _addressController.text = result.address ?? '${result.latitude.toStringAsFixed(5)}, ${result.longitude.toStringAsFixed(5)}';
      });
    }
  }

  Future<void> _submitReport() async {
    if (_titleController.text.trim().length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Titre trop court (min 5 caractères)')));
      return;
    }

    setState(() => _isLoading = true);
    final success = await ApiService.createIncident(
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      category: _selectedCategory,
      severity: _selectedSeverity,
      address: _addressController.text.trim(),
      isAnonymous: _isAnonymous,
      images: _images.isEmpty ? null : _images,
      latitude: _latitude,
      longitude: _longitude,
    );
    setState(() => _isLoading = false);

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signalement envoyé avec succès !'), backgroundColor: AppTheme.successGreen));
      Navigator.pop(context); // Optional: if it was a push
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.textPrimary : const Color(0xFF1E293B);
    final textDim = isDark ? AppTheme.textSecondary : const Color(0xFF64748B);
    final cardBg = isDark ? AppTheme.cardDark : Colors.white;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(textColor, textDim),
            const SizedBox(height: 32),
            _buildFieldGroup('INFORMATIONS DE BASE', [
              _buildLabel('TITRE DU SIGNALEMENT', textDim),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(hintText: 'Ex: Accident tunnel du Front de Mer'),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _buildDropdown('CATÉGORIE', _selectedCategory, categories, (v) => setState(() => _selectedCategory = v!))),
                  const SizedBox(width: 16),
                  Expanded(child: _buildDropdown('GRAVITÉ', _selectedSeverity, severities, (v) => setState(() => _selectedSeverity = v!))),
                ],
              ),
            ], cardBg),
            const SizedBox(height: 24),
            _buildFieldGroup('DESCRIPTION DÉTAILLÉE', [
              TextField(
                controller: _descController,
                maxLines: 4,
                decoration: const InputDecoration(hintText: 'Décrivez précisément ce que vous voyez...'),
              ),
            ], cardBg),
            const SizedBox(height: 24),
            _buildFieldGroup('LIEU DE L\'INCIDENT', [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _addressController,
                      decoration: const InputDecoration(hintText: 'Adresse ou point de repère'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: _myPosition,
                    icon: _isLoadingLocation 
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) 
                      : const Icon(Icons.my_location_rounded, color: AppTheme.dangerRed),
                    style: IconButton.styleFrom(backgroundColor: AppTheme.dangerRed.withOpacity(0.1), padding: const EdgeInsets.all(12)),
                  ),
                ],
              ),
            ], cardBg),
            const SizedBox(height: 24),
            _buildFieldGroup('PREUVES VISUELLES', [
              _buildImagePicker(cardBg, textDim),
            ], cardBg),
            const SizedBox(height: 24),
            SwitchListTile(
              value: _isAnonymous,
              onChanged: (v) => setState(() => _isAnonymous = v),
              title: const Text('Signalement Anonyme', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('Votre identité ne sera pas révélée aux autres citoyens.', style: TextStyle(fontSize: 12)),
              activeColor: AppTheme.accentPurple,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitReport,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed, shadowColor: AppTheme.dangerRed.withOpacity(0.3), elevation: 8),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text('ENVOYER LE SIGNALEMENT', style: TextStyle(letterSpacing: 1)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color textColor, Color textDim) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Signaler un Incident', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: textColor, letterSpacing: -0.5)),
        Text('Votre vigilance sauve des vies. Soyez précis.', style: TextStyle(color: textDim, fontSize: 15)),
      ],
    );
  }

  Widget _buildFieldGroup(String title, List<Widget> children, Color cardBg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.textSecondary, letterSpacing: 1)),
        ),
        ...children,
      ],
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)));
  }

  Widget _buildDropdown(String label, String value, List<Map<String, String>> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, AppTheme.textSecondary),
        DropdownButtonFormField<String>(
          value: value,
          items: items.map((e) => DropdownMenuItem(value: e['value'], child: Text(e['label']!, style: const TextStyle(fontSize: 14)))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildImagePicker(Color cardBg, Color textDim) {
    return InkWell(
      onTap: _pickImages,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: cardBg.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          children: [
            const Icon(Icons.add_a_photo_rounded, size: 32, color: AppTheme.accentPurple),
            const SizedBox(height: 12),
            Text('Ajouter des photos (preuves)', style: TextStyle(color: textDim, fontWeight: FontWeight.bold)),
            if (_images.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: _images.map((img) => Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.image_rounded, size: 20, color: Colors.white24),
                )).toList(),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
