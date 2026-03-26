import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform, kDebugMode;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/incident_model.dart';
import '../models/user_model.dart';
import '../models/message_model.dart';
import 'package:http_parser/http_parser.dart';

class ApiService {
  // --- CONFIGURATION RÉSEAU ---
  // Mettre 'true' pour utiliser le backend local, 'false' pour la production Render
  static const bool _useLocalBackend = false;
  
  // Remplacer par l'IP de votre PC (ex: 192.168.1.15) pour tester sur téléphone physique
  static const String _manualServerIp = "192.168.100.237"; 

  static String get baseUrl {
    if (_useLocalBackend) {
      if (kIsWeb) {
        return "http://localhost:5000/api";
      }
      // Pour les tests sur appareil physique via wifi ou émulateur Android
      // Si vous testez sur un téléphone réel (Infinix X650B), utilisez _manualServerIp
      return "http://$_manualServerIp:5000/api";
      // return "http://10.0.2.2:5000/api";
    } else {
      // URL de production sur Render
      return "https://cominity-system-management.onrender.com/api";
    }
  }

  // --- PERSISTENCE ---

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  static Future<void> saveUserInfo(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', user.id);
    await prefs.setString('user_name', user.name);
    await prefs.setString('user_email', user.email);
    await prefs.setString('user_role', user.role);
  }

  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email');
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  static Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<String> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_name') ?? 'Utilisateur';
  }

  static Future<String> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString('user_role') ?? 'citizen').toLowerCase();
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('user_role');
  }

  static Future<UserModel?> getUserProfile() async {
    try {
      final token = await getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/users/profile'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return UserModel.fromJson(data['user'] ?? data, baseUrl: baseUrl);
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('Error getting profile: $e');
      return null;
    }
  }

  static Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final response = await http.put(
        Uri.parse('$baseUrl/users/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) print('Error updating profile: $e');
      return false;
    }
  }

  static Future<UserModel?> getUserById(String id) async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/users/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserModel.fromJson(data['user'] ?? data, baseUrl: baseUrl);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // --- AUTHENTICATION ---

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        await saveToken(data['token']);
        final user = UserModel.fromJson(data['user'], baseUrl: baseUrl);
        await saveUserInfo(user);
        return {
          'success': true, 
          'token': data['token'], 
          'user': user
        };
      } else {
        return {'success': false, 'message': data['message'] ?? 'Erreur de connexion'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau : $e'};
    }
  }

  static Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {
          'success': true, 
          'message': data['message'],
          'email': userData['email']
        };
      } else {
        return {'success': false, 'message': data['message'] ?? "Erreur lors de l'inscription"};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau : $e'};
    }
  }

  static Future<Map<String, dynamic>> verifyCode(String email, String code) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'code': code,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (data['token'] != null) {
          await saveToken(data['token']);
          final user = UserModel.fromJson(data['user'], baseUrl: baseUrl);
          await saveUserInfo(user);
        }
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? "Code invalide"};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau : $e'};
    }
  }

  static Future<Map<String, dynamic>> resendVerificationCode(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/resend-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? "Erreur lors de l'envoi du code"
      };
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau : $e'};
    }
  }

  // --- INCIDENTS ---

  static Future<bool> updateFCMToken(String token) async {
    try {
      final userId = await getUserId();
      if (userId == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/users/fcm-token'),
        headers: await getHeaders(),
        body: jsonEncode({'fcmToken': token}),
      );

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) print('Error updating FCM token: $e');
      return false;
    }
  }

  static Future<bool> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) print('Error in forgotPassword: $e');
      return false;
    }
  }

  static Future<List<IncidentModel>> getIncidents({
    int page = 1,
    String category = '',
    String severity = '',
    String search = '',
    int limit = 50,
  }) async {
    try {
      String url = '$baseUrl/incidents?page=$page&limit=$limit';
      if (category.isNotEmpty) url += '&category=$category';
      if (severity.isNotEmpty) url += '&severity=$severity';
      if (search.isNotEmpty) url += '&search=$search';

      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final List data = body['incidents'] ?? [];
        return data.map((item) => IncidentModel.fromJson(item, baseUrl: baseUrl)).toList();
      } else {
        throw Exception('Erreur serveur (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Erreur lors du chargement des incidents : $e');
    }
  }

  static Future<List<IncidentModel>> getMyIncidents() async {
    try {
      final token = await getToken();
      if (token == null) return [];
      
      final response = await http.get(
        Uri.parse('$baseUrl/incidents/my'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final List data = body['incidents'] ?? [];
        return data.map((item) => IncidentModel.fromJson(item, baseUrl: baseUrl)).toList();
      } else {
        throw Exception('Erreur serveur (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Erreur lors du chargement de vos incidents : $e');
    }
  }

  static Future<bool> createIncident({
    required String title,
    required String description,
    required String category,
    required String severity,
    required String address,
    required bool isAnonymous,
    List<XFile>? images,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final token = await getToken();
      if (token == null) return false;

      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/incidents'));
      
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      request.fields['title'] = title;
      request.fields['description'] = description;
      request.fields['category'] = category;
      request.fields['severity'] = severity;
      request.fields['address'] = address;
      request.fields['isAnonymous'] = isAnonymous.toString();
      if (latitude != null) request.fields['lat'] = latitude.toString();
      if (longitude != null) request.fields['lng'] = longitude.toString();

      if (images != null) {
        for (var i = 0; i < images.length; i++) {
          final bytes = await images[i].readAsBytes();
          
          String? mimeTypeRaw = images[i].mimeType;
          String type = 'image';
          String subtype = 'jpeg';
          
          if (mimeTypeRaw != null && mimeTypeRaw.contains('/')) {
            final parts = mimeTypeRaw.split('/');
            type = parts[0];
            subtype = parts[1];
          } else {
            String ext = images[i].name.split('.').last.toLowerCase();
            if (ext == 'png') subtype = 'png';
            else if (ext == 'webp') subtype = 'webp';
            else if (ext == 'jpg') subtype = 'jpeg';
          }

          var multipartFile = http.MultipartFile.fromBytes(
            'images',
            bytes,
            filename: images[i].name,
            contentType: MediaType(type, subtype),
          );
          request.files.add(multipartFile);
        }
      }

      var response = await request.send();
      return response.statusCode == 201;
    } catch (e) {
      print("Erreur upload: $e");
      return false;
    }
  }

  // --- HEALTH CHECK ---

  static Future<bool> checkConnection() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // --- MESSAGING ---

  static Future<List<MessageModel>> getIncidentMessages(String incidentId) async {
    try {
      final token = await getToken();
      if (token == null) return [];
      
      final response = await http.get(
        Uri.parse('$baseUrl/messages/$incidentId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('GET Messages Status: ${response.statusCode}');
      print('GET Messages Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final List data = body['messages'] ?? [];
        return data.map((item) => MessageModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('GET Messages Error: $e');
      return [];
    }
  }

  static Future<bool> sendMessage(String incidentId, String content, {XFile? file, String? type}) async {
    try {
      final token = await getToken();
      if (token == null) return false;

      if (file == null) {
        final response = await http.post(
          Uri.parse('$baseUrl/messages/$incidentId'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'content': content,
            if (type != null) 'type': type,
          }),
        );
        return response.statusCode == 201;
      } else {
        var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/messages/$incidentId'));
        request.headers.addAll({'Authorization': 'Bearer $token'});
        request.fields['content'] = content;
        if (type != null) request.fields['type'] = type;

        final bytes = await file.readAsBytes();
      String mimeTypeRaw = file.mimeType ?? '';
      String majorType = 'application';
      String subtype = 'octet-stream';
      String filename = file.name;

      // Amélioration de la détection pour le Web ou les fichiers sans extension
      if (mimeTypeRaw.contains('/')) {
        final parts = mimeTypeRaw.split('/');
        majorType = parts[0];
        subtype = parts[1];
      } else {
        String ext = filename.contains('.') ? filename.split('.').last.toLowerCase() : '';
        
        // Si pas d'extension, on se base sur le paramètre 'type' passé
        if (ext.isEmpty || ext == 'blob') {
          if (type == 'audio') {
            majorType = 'audio';
            subtype = 'm4a';
            filename = 'vocal.m4a';
          } else if (type == 'image') {
            majorType = 'image';
            subtype = 'jpeg';
            filename = 'upload.jpg';
          } else if (type == 'video') {
            majorType = 'video';
            subtype = 'mp4';
            filename = 'video.mp4';
          }
        } else {
          if (['png', 'jpg', 'jpeg', 'webp'].contains(ext)) majorType = 'image';
          else if (['mp4', 'mov', 'avi'].contains(ext)) majorType = 'video';
          else if (['m4a', 'mp3', 'wav', 'aac', 'webm'].contains(ext)) majorType = 'audio';
          subtype = ext;
        }
      }

      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: MediaType(majorType, subtype),
      ));

        var response = await request.send();
        return response.statusCode == 201;
      }
    } catch (e) {
      if (kDebugMode) print('POST Message Error: $e');
      return false;
    }
  }

  static Future<bool> upvoteIncident(String id) async {
    try {
      final token = await getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/incidents/$id/upvote'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<IncidentModel?> getIncidentById(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/incidents/$id'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return IncidentModel.fromJson(data['incident'], baseUrl: baseUrl);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>> getNotifications() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/notifications'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'notifications': [], 'unreadCount': 0};
    } catch (e) {
      return {'notifications': [], 'unreadCount': 0};
    }
  }

  static Future<bool> markNotificationRead(String id) async {
    try {
      final token = await getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/notifications/$id/read'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> markAllNotificationsRead() async {
    try {
      final token = await getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/notifications/read-all'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> submitAppeal(String email, String message) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/support/appeal'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'message': message}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      throw Exception('Erreur support: $e');
    }
  }

  static Future<List<dynamic>> getAppealStatus(String email) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/support/appeal-status/$email'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['appeals'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> getAdminAppeals() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/support/appeals'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['appeals'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> replyToAppeal(String id, String reply, {String status = 'replied'}) async {
    try {
      final token = await getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/support/appeals/$id/reply'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'adminReply': reply, 'status': status}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> resetPassword(String token, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset-password/$token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'password': password}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<List<UserModel>> getUsers({String? search}) async {
    return getAllUsers(search: search);
  }

  // --- ADMIN ---

  static Future<Map<String, dynamic>> getAdminStats() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/users/stats'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Erreur ${response.statusCode}');
    } catch (e) {
      throw Exception('Erreur stats : $e');
    }
  }

  static Future<List<IncidentModel>> getAdminIncidents({String? status}) async {
    try {
      final token = await getToken();
      String url = '$baseUrl/incidents/admin?limit=100';
      if (status != null) url += '&status=$status';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final List data = body['incidents'] ?? [];
        return data.map((item) => IncidentModel.fromJson(item, baseUrl: baseUrl)).toList();
      }
      throw Exception('Erreur ${response.statusCode}');
    } catch (e) {
      throw Exception('Erreur incidents admin : $e');
    }
  }

  static Future<bool> moderateIncident(String id, String status, String note) async {
    try {
      final token = await getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/incidents/$id/moderate'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'status': status,
          'moderationNote': note,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<List<UserModel>> getAllUsers({String? search}) async {
    try {
      final token = await getToken();
      String url = '$baseUrl/users?limit=100';
      if (search != null && search.isNotEmpty) url += '&search=$search';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final List data = body['users'] ?? [];
        return data.map((item) => UserModel.fromJson(item, baseUrl: baseUrl)).toList();
      }
      throw Exception('Erreur ${response.statusCode}');
    } catch (e) {
      throw Exception('Erreur users admin : $e');
    }
  }

  static Future<bool> toggleUserStatus(String id) async {
    try {
      final token = await getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/users/$id/toggle'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
