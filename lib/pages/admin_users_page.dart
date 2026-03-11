import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final _searchController = TextEditingController();
  late Future<List<UserModel>> _future;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    final future = ApiService.getAllUsers(search: _searchController.text);
    setState(() {
      _future = future;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.textPrimary : const Color(0xFF1E293B);
    final textDim = isDark ? AppTheme.textSecondary : const Color(0xFF64748B);
    final cardBg = isDark ? AppTheme.cardDark : Colors.white;

    // Remove redundant Scaffold
    return Column(
      children: [
        _buildHeader(textColor, textDim),
        _buildSearchBar(cardBg, textColor, textDim),
        Expanded(
          child: FutureBuilder<List<UserModel>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (snapshot.hasError) return Center(child: Text('Erreur : ${snapshot.error}', style: const TextStyle(color: AppTheme.dangerRed)));

              final list = snapshot.data ?? [];
              if (list.isEmpty) return _buildEmptyState(textColor, textDim);

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                itemCount: list.length,
                itemBuilder: (context, index) => _buildUserTile(list[index], cardBg, textColor, textDim),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(Color textColor, Color textDim) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Utilisateurs', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: textColor, letterSpacing: -0.5)),
              Text('Gérer les accès et les rôles de la plateforme.', style: TextStyle(color: textDim, fontSize: 14)),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.people_outline_rounded, color: Colors.blue),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(Color cardBg, Color textColor, Color textDim) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => _refresh(),
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          hintText: 'Rechercher un nom ou e-mail...',
          prefixIcon: const Icon(Icons.search_rounded),
          fillColor: cardBg.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildUserTile(UserModel user, Color cardBg, Color textColor, Color textDim) {
    final isAdmin = user.role.toLowerCase() == 'admin';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: isAdmin ? Colors.amber.withOpacity(0.2) : AppTheme.accentPurple.withOpacity(0.1),
          child: Text(user.name[0].toUpperCase(), style: TextStyle(color: isAdmin ? Colors.amber : AppTheme.accentPurple, fontWeight: FontWeight.bold)),
        ),
        title: Text(user.name, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
        subtitle: Text(user.email, style: TextStyle(color: textDim, fontSize: 12)),
        trailing: isAdmin 
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
              child: const Text('ADMIN', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(user.isActive ? 'ACTIF' : 'SUSPENDU', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: user.isActive ? AppTheme.successGreen : AppTheme.dangerRed)),
                const SizedBox(width: 8),
                Switch(
                  value: user.isActive,
                  activeColor: AppTheme.successGreen,
                  onChanged: (val) async {
                    final ok = await ApiService.toggleUserStatus(user.id);
                    if (ok) _refresh();
                  },
                ),
              ],
            ),
      ),
    );
  }

  Widget _buildEmptyState(Color textColor, Color textDim) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_rounded, size: 64, color: textDim.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text('Aucun utilisateur', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          Text('Modifiez votre recherche.', style: TextStyle(color: textDim)),
        ],
      ),
    );
  }
}
