import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/incident_model.dart';
import '../models/user_model.dart';
import '../models/message_model.dart';
import 'package:http_parser/http_parser.dart';

class ApiService {
  // --- CONFIGURATION RÉSEAU ---
  // Remplacer par l'IP de votre PC (ex: 192.168.1.15) pour tester sur téléphone physique
  static const String _manualServerIp = "192.168.1.45"; 

  static String get baseUrl {
    if (kIsWeb) return "http://localhost:5000/api";
    
    // Sur desktop, on utilise toujours localhost
    try {
      if (defaultTargetPlatform == TargetPlatform.windows || 
          defaultTargetPlatform == TargetPlatform.macOS || 
          defaultTargetPlatform == TargetPlatform.linux) {
        return "http://localhost:5000/api";
      }
    } catch (_) {}

    // Pour le téléphone physique (si IP renseignée)
    if (_manualServerIp.isNotEmpty) {
      return "http://$_manualServerIp:5000/api";
    }

    // Par défaut pour l'émulateur Android
    return "http://10.0.2.2:5000/api";
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
    await prefs.setString('user_role', user.role);
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  static Future<String> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_name') ?? 'Utilisateur';
  }

  static Future<String> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final role = (prefs.getString('user_role') ?? 'citizen').toLowerCase();
    if (role == 'admin') return 'ADMINISTRATEUR';
    if (role == 'citizen') return 'CITOYEN';
    return role.toUpperCase();
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('user_role');
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
        final user = UserModel.fromJson(data['user']);
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
        return {'success': true, 'user': UserModel.fromJson(data['user'])};
      } else {
        return {'success': false, 'message': data['message'] ?? "Erreur lors de l'inscription"};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur réseau : $e'};
    }
  }

  // --- INCIDENTS ---

  static Future<List<IncidentModel>> getIncidents() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/incidents'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final List data = body['incidents'] ?? [];
        List<IncidentModel> list = data.map((item) => IncidentModel.fromJson(item, baseUrl: baseUrl)).toList();
        // User feed filter: only approved or resolved
        return list.where((inc) => inc.status == 'approved' || inc.status == 'resolved').toList();
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
      );

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

  static Future<bool> sendMessage(String incidentId, String content) async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/messages/$incidentId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'content': content}),
      );

      print('POST Message Status: ${response.statusCode}');
      print('POST Message Body: ${response.body}');

      return response.statusCode == 201;
    } catch (e) {
      print('POST Message Error: $e');
      return false;
    }
  }

  static Future<bool> markIncidentResolved(String id) async {
    try {
      final token = await getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/incidents/$id/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'status': 'resolved'}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
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
        return data.map((item) => UserModel.fromJson(item)).toList();
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
