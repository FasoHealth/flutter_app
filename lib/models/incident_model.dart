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
  final DateTime createdAt;

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
    required this.createdAt,
  });

  factory IncidentModel.fromJson(Map<String, dynamic> json, {String? baseUrl}) {
    final host = (baseUrl != null && baseUrl.isNotEmpty)
        ? baseUrl.replaceFirst(RegExp(r'/api$'), '')
        : 'http://localhost:5000';
    List<String> imageUrls = [];
    if (json['images'] != null && json['images'] is List) {
      imageUrls = (json['images'] as List)
          .map((img) {
          final path = img is Map ? (img['path'] ?? img).toString() : img.toString();
          return "$host/${path.replaceFirst(RegExp(r'^/'), '')}";
        })
          .toList();
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
      reportedBy: (json['reportedBy'] is Map) 
          ? json['reportedBy']['_id'] ?? '' 
          : json['reportedBy'] ?? '',
      isAnonymous: json['isAnonymous'] ?? false,
      upvoteCount: json['upvoteCount'] ?? 0,
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
