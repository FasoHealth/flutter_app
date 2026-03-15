import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../services/translation_service.dart';
import '../models/user_model.dart';
import '../models/incident_model.dart';
import '../theme/app_theme.dart';
import 'login_page.dart';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  final String? userId;
  const ProfilePage({super.key, this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  UserModel? _user;
  List<IncidentModel> _history = [];
  bool _loading = true;
  bool _saving = false;
  bool _saved = false;
  double _alertRadius = 5.0;
  
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  
  XFile? _avatarFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      // On lance les requêtes en parallèle pour gagner du temps
      final results = await Future.wait([
        widget.userId != null 
            ? ApiService.getUserById(widget.userId!)
            : ApiService.getUserProfile(),
        ApiService.getUserId(), // Pour savoir si c'est "Moi"
      ]);

      final user = results[0] as UserModel?;
      final myId = results[1] as String?;
      final isMe = widget.userId == null || widget.userId == myId;

      List<IncidentModel> incidents = [];
      if (isMe && user != null) {
        // Si c'est moi, on charge mon historique
        incidents = await ApiService.getMyIncidents();
      }
      
      if (mounted) {
        setState(() {
          if (user != null) {
            _user = user;
            _history = incidents;
            _nameController.text = user.name;
            _phoneController.text = user.phone ?? '';
            _cityController.text = user.location?['city'] ?? '';
          } else {
            // Fallback : si l'API échoue, on utilise les infos locales pour ne pas afficher "U"
            _loadFallbackData();
          }
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        _loadFallbackData();
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadFallbackData() async {
    final name = await ApiService.getUserName();
    final email = await ApiService.getUserEmail();
    final role = await ApiService.getUserRole();
    final id = await ApiService.getUserId();
    
    if (mounted) {
      setState(() {
        _user = UserModel(
          id: id ?? '',
          name: name,
          email: email ?? '', 
          role: role,
          isActive: true,
          incidentsReported: 0,
        );
        _nameController.text = name;
      });
    }
  }

  Future<void> _pickAvatar() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _avatarFile = image;
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _saved = false;
    });

    try {
      final success = await ApiService.updateProfile({
        'name': _nameController.text,
        'phone': _phoneController.text,
        'location': {
          'city': _cityController.text,
        },
      });

      if (mounted) {
        setState(() {
          _saving = false;
          if (success) {
            _saved = true;
          }
        });

        if (success) {
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) setState(() => _saved = false);
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Erreur lors de la sauvegarde"), backgroundColor: AppTheme.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur : $e"), backgroundColor: AppTheme.red),
        );
      }
    }
  }

  void _handleLogout() async {
    await ApiService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty || name == 'Utilisateur') return 'U';
    final parts = name.trim().split(' ');
    if (parts.length > 1 && parts[1].isNotEmpty) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: T.locale,
      builder: (context, lang, child) {
        if (_loading) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.brandOrange));
        }

        final isDesktop = MediaQuery.of(context).size.width > 900;
        final isMe = widget.userId == null;

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: !isMe ? AppBar(
            backgroundColor: const Color(0xFF1A2035),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(T.get('profile_title'), style: GoogleFonts.inter(color: Colors.white)),
          ) : null,
          body: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 40),
            child: Column(
              children: [
                // Banner
                Container(
                  height: 160,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1A2035), Color(0xFF2E3D6A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                  ),
                ),
                
                Transform.translate(
                  offset: const Offset(0, -60),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: isDesktop 
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(width: 300, child: _buildLeftColumn()),
                            const SizedBox(width: 30),
                            Expanded(child: _buildRightColumn()),
                          ],
                        )
                      : Column(
                          children: [
                            _buildLeftColumn(),
                            const SizedBox(height: 24),
                            _buildRightColumn(),
                          ],
                        ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLeftColumn() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
          ),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 5),
                      color: AppTheme.brandOrange,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                    ),
                    child: ClipOval(
                      child: _avatarFile != null 
                        ? Image.file(File(_avatarFile!.path), fit: BoxFit.cover)
                        : (_user?.avatar != null 
                            ? Image.network(_user!.avatar!, fit: BoxFit.cover)
                            : Center(child: Text(_getInitials(_user?.name ?? ""), style: GoogleFonts.inter(fontSize: 40, fontWeight: FontWeight.w800, color: Colors.white)))),
                    ),
                  ),
                  InkWell(
                    onTap: _pickAvatar,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                      child: const Icon(Icons.camera_alt_outlined, size: 18, color: Color(0xFF1A2035)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(_user?.name ?? "", style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon((_user?.role?.toLowerCase() == 'admin' || _user?.role?.toLowerCase() == 'administrateur') ? Icons.shield_outlined : Icons.person_outline, size: 14, color: AppTheme.brandOrange),
                  const SizedBox(width: 6),
                  Text(
                    (_user?.role?.toLowerCase() == 'admin' || _user?.role?.toLowerCase() == 'administrateur') 
                      ? T.get('profile_role_admin') 
                      : T.get('profile_role_citizen'),
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.brandOrange),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (widget.userId == null)
                OutlinedButton.icon(
                  onPressed: _handleLogout,
                  icon: const Icon(Icons.logout_rounded, size: 16),
                  label: Text(T.get('logout')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.red,
                    side: const BorderSide(color: Color(0xFFE8E3DB)),
                    minimumSize: const Size(double.infinity, 44),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: _buildCompactStat(T.get('profile_stats_alerts'), _history.length.toString(), Icons.analytics_outlined)),
            const SizedBox(width: 12),
            Expanded(child: _buildCompactStat(T.get('profile_stats_impact'), _history.fold(0, (sum, item) => sum + item.upvotes.length).toString(), Icons.trending_up_rounded)),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactStat(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E3DB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF9BA3B4))),
              Icon(icon, size: 14, color: AppTheme.brandOrange.withOpacity(0.6)),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildRightColumn() {
    if (widget.userId != null) {
      return Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE8E3DB))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("À propos", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Text(
              "Cet utilisateur fait partie de la communauté de vigilance. Vous pouvez voir ses signalements publics dans le fil d'actualité.",
              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF5A6478), height: 1.6),
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        // Settings Form
        Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE8E3DB))),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.settings_outlined, color: AppTheme.brandOrange, size: 20),
                              const SizedBox(width: 10),
                              Text(T.get('profile_settings_title'), style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(T.get('profile_settings_desc'), style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF9BA3B4))),
                        ],
                      ),
                    ),
                    if (_saved)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: AppTheme.greenBg, borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline, size: 14, color: AppTheme.green),
                            const SizedBox(width: 6),
                            Text(T.get('profile_saved'), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.green)),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                if (MediaQuery.of(context).size.width > 600)
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(T.get('profile_name'), _nameController),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _buildTextField(T.get('profile_phone'), _phoneController, placeholder: "+226 XX XX XX XX"),
                      ),
                    ],
                  )
                else ...[
                  _buildTextField(T.get('profile_name'), _nameController),
                  const SizedBox(height: 20),
                  _buildTextField(T.get('profile_phone'), _phoneController, placeholder: "+226 XX XX XX XX"),
                ],
                const SizedBox(height: 20),
                if (MediaQuery.of(context).size.width > 600)
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(T.get('profile_email'), TextEditingController(text: _user?.email), enabled: false),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _buildTextField(T.get('profile_city'), _cityController, placeholder: T.get('profile_city_placeholder')),
                      ),
                    ],
                  )
                else ...[
                  _buildTextField(T.get('profile_email'), TextEditingController(text: _user?.email), enabled: false),
                  const SizedBox(height: 20),
                  _buildTextField(T.get('profile_city'), _cityController, placeholder: T.get('profile_city_placeholder')),
                ],
                const SizedBox(height: 32),
                const Divider(height: 1),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _handleSave,
                    icon: _saving ? const SizedBox.shrink() : const Icon(Icons.flash_on_rounded, size: 18),
                    label: Text(_saving ? T.get('profile_saving') : T.get('profile_save')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brandOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        // Notifications card
        Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE8E3DB))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.radio_button_checked_rounded, color: AppTheme.brandOrange, size: 20),
                  const SizedBox(width: 10),
                  Text(T.get('profile_notif_title'), style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: const Color(0xFFF8F4EE), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(T.get('profile_notif_radius'), style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
                        Text("${_alertRadius.toInt()} km", style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppTheme.brandOrange)),
                      ],
                    ),
                    Slider(
                      value: _alertRadius,
                      min: 1,
                      max: 50,
                      onChanged: (val) => setState(() => _alertRadius = val),
                      activeColor: AppTheme.brandOrange,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Locale (1km)", style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF9BA3B4))),
                        Text("Régionale (50km)", style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF9BA3B4))),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        if (_history.isNotEmpty) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE8E3DB))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history_rounded, color: AppTheme.brandOrange, size: 20),
                    const SizedBox(width: 10),
                    Text("Mes derniers signalements", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 24),
                ..._history.take(5).map((inc) => _buildHistoryItem(inc)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {String? placeholder, bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF222222))),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: placeholder,
            fillColor: enabled ? Colors.white : const Color(0xFFF8F4EE),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryItem(IncidentModel inc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E3DB)),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: const Color(0xFFF8F4EE), borderRadius: BorderRadius.circular(10)),
            child: Icon(
              inc.category == 'fire' ? Icons.local_fire_department_outlined : (inc.category == 'flood' ? Icons.waves_rounded : Icons.warning_amber_rounded),
              color: inc.category == 'fire' ? AppTheme.red : (inc.category == 'flood' ? AppTheme.blue : AppTheme.yellow),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(inc.title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
                Text("${inc.createdAt.day}/${inc.createdAt.month}/${inc.createdAt.year}", style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF9BA3B4))),
              ],
            ),
          ),
          _buildStatusBadge(inc.status),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = AppTheme.yellow;
    String label = "En attente";
    if (status == 'approved') { color = AppTheme.green; label = "Confirmé"; }
    if (status == 'resolved') { color = AppTheme.blue; label = "Clôturé"; }
    if (status == 'rejected') { color = AppTheme.red; label = "Rejeté"; }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: GoogleFonts.inter(color: color, fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }
}
