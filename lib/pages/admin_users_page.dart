import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import '../services/api_service.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  List<UserModel> _users = [];
  bool _loading = true;
  String _search = '';
  String? _actionLoading;
  int _page = 1;
  static const int _limit = 10;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getUsers(search: _search);
      if (mounted) {
        setState(() {
          _users = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleUserStatus(String id) async {
    setState(() => _actionLoading = id);
    try {
      final success = await ApiService.toggleUserStatus(id);
      if (success && mounted) {
        _fetchUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors de la modification du statut.')));
      }
    } finally {
      if (mounted) setState(() => _actionLoading = null);
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final activeCnt = _users.where((u) => u.isActive).length;
    final bannedCnt = _users.where((u) => !u.isActive).length;
    final totalPages = (_users.length / _limit).ceil();
    final paginated = _users.skip((_page - 1) * _limit).take(_limit).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.brandOrange))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _buildUsersTable(paginated, totalPages),
                        const SizedBox(height: 32),
                        _buildSummaryCards(activeCnt, bannedCnt),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.people_alt_rounded, color: AppTheme.brandOrange, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        "Utilisateurs",
                        style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: const Color(0xFF222222)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppTheme.brandOrangePale, borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        "${_users.length} total",
                        style: const TextStyle(color: AppTheme.brandOrange, fontSize: 10, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (val) {
                    setState(() {
                      _search = val;
                      _page = 1;
                    });
                    _fetchUsers();
                  },
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: "Rechercher...",
                    prefixIcon: Icon(Icons.search_rounded, size: 18),
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: () {}, // Action pour ajouter
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.brandOrange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTable(List<UserModel> paginated, int totalPages) {
    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: paginated.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _buildUserCard(paginated[index]),
        ),
        if (totalPages > 1) ...[
          const SizedBox(height: 16),
          _buildPagination(totalPages),
        ],
      ],
    );
  }

  Widget _buildUserCard(UserModel u) {
    final isLoading = _actionLoading == u.id;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E3DB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.brandOrange,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: Text(_getInitials(u.name), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(u.name, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(u.email, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF5A6478)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              _buildRoleBadge(u.role),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                 children: [
                    const Icon(Icons.description_outlined, size: 16, color: Color(0xFF9BA3B4)),
                    const SizedBox(width: 6),
                    Text(
                      "${u.incidentsReported} signalement${u.incidentsReported > 1 ? 's' : ''}", 
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF5A6478), fontSize: 13),
                    ),
                 ]
              ),
              Row(
                children: [
                  Text(u.isActive ? "Actif" : "Inactif", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: u.isActive ? AppTheme.green : AppTheme.red)),
                  const SizedBox(width: 4),
                  Switch(
                    value: u.isActive,
                    onChanged: isLoading ? null : (val) => _toggleUserStatus(u.id),
                    activeColor: AppTheme.green,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    final isAdmin = role == 'admin';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isAdmin ? AppTheme.brandOrangePale : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isAdmin ? AppTheme.brandOrange.withOpacity(0.2) : const Color(0xFFE8E3DB)),
      ),
      child: Text(
        isAdmin ? "ADMIN" : (role == 'guide' ? "MODÉRATEUR" : "CITOYEN"),
        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: isAdmin ? AppTheme.brandOrange : const Color(0xFF5A6478)),
      ),
    );
  }

  Widget _buildPagination(int totalPages) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F4EE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E3DB)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Affichage de ${(_page - 1) * _limit + 1}-${min(_page * _limit, _users.length)} sur ${_users.length}",
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF9BA3B4), fontWeight: FontWeight.w500),
          ),
          Row(
            children: [
              _buildPageBtn(Icons.chevron_left_rounded, _page > 1 ? () => setState(() => _page--) : null),
              const SizedBox(width: 8),
              ...List.generate(min(totalPages, 5), (i) {
                final p = i + 1;
                final active = _page == p;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: () => setState(() => _page = p),
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: active ? AppTheme.brandOrange : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(child: Text("$p", style: TextStyle(color: active ? Colors.white : const Color(0xFF222222), fontWeight: FontWeight.w700, fontSize: 13))),
                    ),
                  ),
                );
              }),
              _buildPageBtn(Icons.chevron_right_rounded, _page < totalPages ? () => setState(() => _page++) : null),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageBtn(IconData icon, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE8E3DB))),
        child: Icon(icon, size: 18, color: onTap == null ? const Color(0xFF9BA3B4) : const Color(0xFF222222)),
      ),
    );
  }

  Widget _buildSummaryCards(int active, int banned) {
    return LayoutBuilder(builder: (context, constraints) {
      final cardWidth = (constraints.maxWidth - 12) / 2;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _buildSummaryCard("Actifs", active.toString(), Icons.check_circle_outline_rounded, AppTheme.green, AppTheme.greenBg, cardWidth),
          _buildSummaryCard("Inactifs", banned.toString(), Icons.block_rounded, AppTheme.red, AppTheme.redBg, cardWidth),
          _buildSummaryCard("Nouveaux", "0", Icons.person_add_rounded, AppTheme.blue, AppTheme.blueBg, cardWidth),
        ],
      );
    });
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color, Color bgColor, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E3DB)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label.toUpperCase(), style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: const Color(0xFF9BA3B4), letterSpacing: 0.5)),
                Text(value, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF222222))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
