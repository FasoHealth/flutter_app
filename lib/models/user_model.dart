class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final bool isActive;
  final Map<String, dynamic>? location;
  final int incidentsReported;
  final String? avatar;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    required this.isActive,
    this.location,
    required this.incidentsReported,
    this.avatar,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, {String? baseUrl}) {
    final host = (baseUrl != null && baseUrl.isNotEmpty)
        ? baseUrl.replaceFirst(RegExp(r'/api$'), '')
        : 'http://localhost:5000';

    String? avatarUrl;
    if (json['avatar'] != null) {
      final img = json['avatar'];
      String path = "";
      if (img is Map) {
        path = (img['url'] ?? img['secure_url'] ?? img['path'] ?? '').toString();
      } else {
        path = img.toString();
      }

      if (path.isNotEmpty) {
        if (path.startsWith('http://') || path.startsWith('https://')) {
          avatarUrl = path;
        } else {
          avatarUrl = "$host/${path.replaceFirst(RegExp(r'^/'), '')}";
        }
      }
    }

    return UserModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      role: json['role'] ?? 'citizen',
      isActive: json['isActive'] ?? true,
      location: json['location'],
      incidentsReported: json['incidentsReported'] ?? 0,
      avatar: avatarUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'location': location,
      'avatar': avatar,
    };
  }
}
