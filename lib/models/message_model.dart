class MessageModel {
  final String id;
  final String incidentId;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime createdAt;

  final String type;
  final List<Map<String, String>> attachments;

  MessageModel({
    required this.id,
    required this.incidentId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.createdAt,
    this.type = 'text',
    this.attachments = const [],
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    List<Map<String, String>> parsedAttachments = [];
    if (json['attachments'] != null) {
      for (var att in json['attachments']) {
        parsedAttachments.add({
          'filename': att['filename']?.toString() ?? '',
          'path': att['path']?.toString() ?? '',
          'mimetype': att['mimetype']?.toString() ?? '',
        });
      }
    }

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
      type: json['type'] ?? 'text',
      attachments: parsedAttachments,
    );
  }
}
