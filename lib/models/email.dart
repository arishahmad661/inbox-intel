class Email {
  final String id;
  final String sender;
  final String subject;
  final String preview;
  final DateTime date;
  bool isRead;
  final bool isPhishing;

  Email({
    required this.id,
    required this.sender,
    required this.subject,
    required this.preview,
    required this.date,
    this.isRead = false,
    this.isPhishing = false,
  });

  // Optional: If you're parsing from JSON (e.g., API response)
  factory Email.fromJson(Map<String, dynamic> json) {
    return Email(
      id: json['id'] ?? '',
      sender: json['sender'] ?? '',
      subject: json['subject'] ?? '',
      preview: json['preview'] ?? '',
      date: DateTime.parse(json['date']),
      isRead: json['isRead'] ?? false,
      isPhishing: json['isPhishing'] ?? false,
    );
  }

  // Optional: For converting back to JSON (if needed)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': sender,
      'subject': subject,
      'preview': preview,
      'date': date.toIso8601String(),
      'isRead': isRead,
      'isPhishing': isPhishing,
    };
  }

  String toText() {
    return '''
ID: $id
Sender: $sender
Subject: $subject
Preview: $preview
Date: ${date.toIso8601String()}
Read: $isRead
Phishing: $isPhishing
''';
  }
}
