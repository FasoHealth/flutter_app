import 'package:flutter/foundation.dart';

class IncidentModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String severity;
  final String status;
  final Map<String, dynamic> location;
  final List<String> images;
  final String reportedBy;
  final bool isAnonymous;
  final int upvoteCount;
  final List<String> upvotes;
  final DateTime createdAt;
  final String? reporterName;
  final String? reporterAvatar;

  IncidentModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.severity,
    required this.status,
    required this.location,
    required this.images,
    required this.reportedBy,
    required this.isAnonymous,
    required this.upvoteCount,
    required this.upvotes,
    required this.createdAt,
    this.reporterName,
    this.reporterAvatar,
  });

  factory IncidentModel.fromJson(Map<String, dynamic> json, {String? baseUrl}) {
    final host = (baseUrl != null && baseUrl.isNotEmpty)
        ? baseUrl.replaceFirst(RegExp(r'/api$'), '')
        : 'http://localhost:5000';
    List<String> imageUrls = [];
    if (json['images'] != null && json['images'] is List) {
      imageUrls = (json['images'] as List)
          .map((img) {
            String path = "";
            if (img is Map) {
              path = (img['url'] ?? img['secure_url'] ?? img['path'] ?? '').toString();
            } else {
              path = img.toString();
            }

            if (path.isEmpty) return "";
            
            if (path.startsWith('http://') || path.startsWith('https://')) {
              // Force HTTPS pour éviter les problèmes de "Cleartext traffic" sur Android
              return path.replaceFirst('http://', 'https://');
            }
            // Nettoyage du slash initial pour éviter les doubles slashes
            final cleanPath = path.replaceFirst(RegExp(r'^/'), '');
            return "$host/$cleanPath".replaceFirst('http://', 'https://');
          })
          .where((url) => url.isNotEmpty)
          .toList();
    }

    String? repName;
    String? repAvatar;
    String repBy = '';

    if (json['reportedBy'] != null) {
      if (json['reportedBy'] is Map) {
        repBy = json['reportedBy']['_id'] ?? '';
        repName = json['reportedBy']['name'];
        final avatarData = json['reportedBy']['avatar'];
        if (avatarData != null) {
          String avatarPath = "";
          if (avatarData is Map) {
            avatarPath = (avatarData['url'] ?? avatarData['secure_url'] ?? avatarData['path'] ?? '').toString();
          } else {
            avatarPath = avatarData.toString();
          }
          if (avatarPath.isNotEmpty) {
            if (avatarPath.startsWith('http')) {
              repAvatar = avatarPath.replaceFirst('http://', 'https://');
            } else {
              repAvatar = "$host/${avatarPath.replaceFirst(RegExp(r'^/'), '')}".replaceFirst('http://', 'https://');
            }
          }
        }
      } else {
        repBy = json['reportedBy'].toString();
      }
    }

    return IncidentModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      severity: json['severity'] ?? '',
      status: json['status'] ?? 'pending',
      location: json['location'] ?? {},
      images: imageUrls,
      reportedBy: repBy,
      reporterName: repName,
      reporterAvatar: repAvatar,
      isAnonymous: json['isAnonymous'] ?? false,
      upvoteCount: json['upvoteCount'] ?? 0,
      upvotes: (json['upvotes'] as List?)?.map((v) => v is Map ? (v['_id'] ?? '').toString() : v.toString()).toList() ?? [],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'severity': severity,
      'location': location,
      'isAnonymous': isAnonymous,
    };
  }
}
