class MessageModel {
  final String id;
  final String incidentId;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.incidentId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['_id'] ?? '',
      incidentId: json['incident'] ?? '',
      senderId: (json['sender'] is Map) 
          ? json['sender']['_id'] ?? '' 
          : json['sender'] ?? '',
      senderName: (json['sender'] is Map) 
          ? json['sender']['name'] ?? 'Inconnu' 
          : 'Inconnu',
      content: json['content'] ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }
}
