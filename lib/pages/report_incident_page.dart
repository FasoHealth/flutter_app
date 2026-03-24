import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'dart:io';

class ReportIncidentPage extends StatefulWidget {
  const ReportIncidentPage({super.key});

  @override
  State<ReportIncidentPage> createState() => _ReportIncidentPageState();
}

class _ReportIncidentPageState extends State<ReportIncidentPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController(text: 'Ouagadougou');

  String _category = 'other';
  String _severity = 'medium';
  bool _isAnonymous = false;
  bool _loading = false;
  bool _geoLoading = false;
  double? _latitude;
  double? _longitude;
  String? _error;

  final List<XFile> _images = [];
  final ImagePicker _picker = ImagePicker();

  final List<Map<String, dynamic>> _categories = [
    {'value': 'theft', 'label': 'Vol', 'icon': Icons.shield_outlined},
    {'value': 'security', 'label': 'Sécurité', 'icon': Icons.security_rounded},
    {'value': 'vandalism', 'label': 'Vandalisme', 'icon': Icons.gavel_rounded},
    {'value': 'suspicious_activity', 'label': 'Suspect', 'icon': Icons.visibility_outlined},
    {'value': 'fire', 'label': 'Incendie', 'icon': Icons.local_fire_department_outlined},
    {'value': 'kidnapping', 'label': 'Enlèvement', 'icon': Icons.person_off_outlined},
    {'value': 'other', 'label': 'Autre', 'icon': Icons.help_outline_rounded},
  ];

  final List<Map<String, dynamic>> _severities = [
    {'value': 'low', 'label': 'Faible', 'desc': 'Peu urgent'},
    {'value': 'medium', 'label': 'Moyen', 'desc': 'Modéré'},
    {'value': 'high', 'label': 'Élevé', 'desc': 'Urgent'},
    {'value': 'critical', 'label': 'Critique', 'desc': 'Extrême'},
  ];

  Future<void> _pickImage() async {
    if (_images.length >= 4) return;
    final List<XFile> selectedImages = await _picker.pickMultiImage();
    if (selectedImages.isNotEmpty) {
      setState(() {
        _images.addAll(selectedImages.take(4 - _images.length));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _geoLoading = true;
      _error = null;
    });

    try {
      // 1. Vérifier si les services de localisation sont activés
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _error = "Les services de localisation sont désactivés.");
        return;
      }

      // 2. Vérifier et demander les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _error = "Permission de localisation refusée.");
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _error = "Les permissions de localisation sont définitivement refusées.");
        return;
      }

      // 3. Obtenir la position avec un timeout et une précision équilibrée pour plus de rapidité
      Position? position;
      try {
        // Essayer d'abord d'obtenir la position actuelle avec un timeout court
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (e) {
        // En cas de timeout, essayer de récupérer la dernière position connue (plus rapide)
        if (kDebugMode) print("Timeout position actuelle, essai dernière connue...");
        position = await Geolocator.getLastKnownPosition();
      }

      if (position != null) {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude, 
          position.longitude,
        ).timeout(const Duration(seconds: 10));
        
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          
          String rue = place.street ?? '';
          String quartier = place.subLocality ?? '';
          String ville = place.locality ?? '';
          String province = place.administrativeArea ?? '';
          String pays = place.country ?? '';
          
          List<String> addressParts = [];
          if (rue.isNotEmpty && rue != quartier) addressParts.add(rue);
          if (quartier.isNotEmpty) addressParts.add(quartier);
          if (ville.isNotEmpty) addressParts.add(ville);
          if (province.isNotEmpty) addressParts.add(province);
          if (pays.isNotEmpty) addressParts.add(pays);
          
          String fullAddress = addressParts.join(', ');

          setState(() {
            _latitude = position!.latitude;
            _longitude = position!.longitude;
            _addressController.text = fullAddress;
            _cityController.text = ville.isNotEmpty ? ville : (place.subAdministrativeArea ?? 'Ouagadougou');
          });
        }
      } else {
        setState(() => _error = "Impossible d'obtenir votre position. Vérifiez votre GPS.");
      }
    } catch (e) {
      if (kDebugMode) print("Erreur localisation: $e");
      setState(() => _error = "Erreur de localisation. Veuillez saisir l'adresse manuellement.");
    } finally {
      if (mounted) setState(() => _geoLoading = false);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final success = await ApiService.createIncident(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _category,
        severity: _severity,
        address: _addressController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        isAnonymous: _isAnonymous,
        images: _images,
      );
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Signalement envoyé avec succès !'), backgroundColor: AppTheme.green),
          );
          Navigator.pop(context);
        } else {
          setState(() => _error = "Erreur lors de l'envoi du signalement.");
        }
      }
    } catch (e) {
      setState(() => _error = "Erreur lors du signalement. Veuillez réessayer.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _buildFormCard()),
                  const SizedBox(width: 32),
                  Expanded(flex: 1, child: _buildSideColumn()),
                ],
              )
            else
              Column(
                children: [
                  _buildFormCard(),
                  const SizedBox(height: 24),
                  _buildSideColumn(),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.shield_outlined, color: AppTheme.brandOrange, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Signaler un incident",
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: const Color(0xFF222222)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          "Aidez la communauté en signalant un problème de sécurité localement.",
          style: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF666666)),
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E3DB)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error != null) _buildErrorAlert(),
            
            _buildLabel("Titre du signalement", hint: "(Min. 5 caractères)"),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(hintText: "Ex: Incendie au marché central, Vol de moto..."),
              validator: (val) => (val == null || val.length < 5) ? "Titre trop court" : null,
            ),
            const SizedBox(height: 24),

            _buildLabel("Catégorie"),
            _buildCategoryGrid(),
            const SizedBox(height: 24),

            _buildLabel("Niveau de gravité"),
            _buildSeverityGrid(),
            const SizedBox(height: 24),

            _buildLabel("Description détaillée", hint: "(Min. 20)"),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: "Décrivez l'incident en détail...",
              ),
              validator: (val) => (val == null || val.length < 20) ? "Description trop courte" : null,
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: _buildLabel("Localisation")),
                TextButton.icon(
                  onPressed: _geoLoading ? null : _getCurrentLocation,
                  icon: _geoLoading 
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.my_location_rounded, size: 14),
                  label: Flexible(
                    child: Text(
                      _geoLoading ? "Localisation..." : "Ma position GPS",
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.brandOrange),
                ),
              ],
            ),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(hintText: "Adresse ou point de repère"),
              onChanged: (_) {
                // Réinitialise les coordonnées exactes si l'utilisateur modifie manuellement l'adresse
                _latitude = null;
                _longitude = null;
              },
              validator: (val) => (val == null || val.isEmpty) ? "L'adresse est requise" : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(hintText: "Ville"),
            ),
            const SizedBox(height: 24),

            _buildLabel("Photos (optionnel)", hint: "Max 4 photos"),
            _buildUploadZone(),
            if (_images.isNotEmpty) _buildImagePreviews(),
            const SizedBox(height: 24),

            _buildAnonymousToggle(),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _handleSubmit,
                icon: _loading ? const SizedBox.shrink() : const Icon(Icons.send_rounded, size: 20),
                label: Text(_loading ? "Envoi en cours..." : "Soumettre le signalement"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, {String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(text, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF222222))),
          if (hint != null) ...[
            const SizedBox(width: 8),
            Text(hint, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF999999))),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorAlert() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFA39E)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFF5222D), size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(_error!, style: GoogleFonts.inter(color: const Color(0xFFF5222D), fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.85,
          ),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final cat = _categories[index];
            final selected = _category == cat['value'];
            return InkWell(
              onTap: () => setState(() => _category = cat['value']),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.brandOrangePale : const Color(0xFFF8F4EE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: selected ? AppTheme.brandOrange : Colors.transparent, width: 2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(cat['icon'], color: selected ? AppTheme.brandOrange : const Color(0xFF1A2035), size: 20),
                    const SizedBox(height: 4),
                    Flexible(
                      child: Text(
                        cat['label'],
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: selected ? AppTheme.brandOrange : const Color(0xFF1A2035),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSeverityGrid() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _severities.map((sev) {
          final selected = _severity == sev['value'];
          Color sevColor;
          switch(sev['value']) {
            case 'low': sevColor = AppTheme.green; break;
            case 'medium': sevColor = AppTheme.yellow; break;
            case 'high': sevColor = const Color(0xFFF97316); break;
            case 'critical': sevColor = AppTheme.red; break;
            default: sevColor = Colors.grey;
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () => setState(() => _severity = sev['value']),
              child: Container(
                width: 85,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                decoration: BoxDecoration(
                  color: selected ? sevColor.withOpacity(0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: selected ? sevColor : const Color(0xFFE8E3DB), width: 2),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      sev['label'],
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        color: selected ? sevColor : const Color(0xFF222222),
                      ),
                    ),
                    Text(
                      sev['desc'],
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF666666)),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUploadZone() {
    return InkWell(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8E3DB), width: 2, style: BorderStyle.solid),
        ),
        child: Column(
          children: [
            const Icon(Icons.image_outlined, size: 32, color: Color(0xFF9BA3B4)),
            const SizedBox(height: 12),
            Text("Cliquez pour ajouter des photos", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
            Text("JPG, PNG, WEBP • Max 5 Mo chacune", style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF9BA3B4))),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreviews() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: List.generate(_images.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(File(_images[index].path), width: 80, height: 80, fit: BoxFit.cover),
                ),
                Positioned(
                  top: -6,
                  right: -6,
                  child: InkWell(
                    onTap: () => _removeImage(index),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: AppTheme.brandOrange, shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildAnonymousToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFF8F4EE), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: _isAnonymous,
                onChanged: (val) => setState(() => _isAnonymous = val ?? false),
                activeColor: AppTheme.brandOrange,
              ),
              const Icon(Icons.person_off_outlined, size: 18),
              const SizedBox(width: 8),
              Text("Signaler anonymement", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
          if (_isAnonymous)
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: Text("Votre identité ne sera pas visible dans le signalement public.", style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF666666))),
            ),
        ],
      ),
    );
  }

  Widget _buildSideColumn() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF1A2035), Color(0xFF2E3D6A)]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("RÉCAPITULATIF", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white.withOpacity(0.4), letterSpacing: 1)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Icon(_categories.firstWhere((c) => c['value'] == _category)['icon'], color: AppTheme.brandOrange, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_categories.firstWhere((c) => c['value'] == _category)['label'], style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white)),
                        const SizedBox(height: 4),
                        _buildBadge(_severities.firstWhere((s) => s['value'] == _severity)['label'], AppTheme.brandOrange),
                      ],
                    ),
                  ),
                ],
              ),
              if (_addressController.text.isNotEmpty) ...[
                const Divider(height: 32, color: Colors.white10),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: Colors.white60),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_addressController.text, style: GoogleFonts.inter(fontSize: 13, color: Colors.white60), maxLines: 2, overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildInfoCard("Rappel civique", "Tout signalement abusif peut entraîner des sanctions. La précision géographique permet une intervention plus rapide.", const Color(0xFFB45309), const Color(0xFFFEF3C7)),
        const SizedBox(height: 12),
        _buildInfoCard("Validation rapide", "Si d'autres citoyens signalent le même incident à proximité, il sera priorisé par nos services de modération.", const Color(0xFF047857), const Color(0xFFD1FAE5)),
      ],
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      child: Text(label.toUpperCase(), style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
    );
  }

  Widget _buildInfoCard(String title, String desc, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12), border: Border(left: BorderSide(color: textColor, width: 4))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 16, color: textColor),
              const SizedBox(width: 8),
              Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13, color: textColor)),
            ],
          ),
          const SizedBox(height: 8),
          Text(desc, style: GoogleFonts.inter(fontSize: 12, color: textColor.withOpacity(0.8), height: 1.5)),
        ],
      ),
    );
  }
}
