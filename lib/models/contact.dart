class Contact {
  final String id;
  final String name;
  final String email;
  final String subject;
  final String message;
  final ContactType type;
  final ContactStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? userId;
  final String? adminResponse;
  final DateTime? respondedAt;

  Contact({
    required this.id,
    required this.name,
    required this.email,
    required this.subject,
    required this.message,
    required this.type,
    this.status = ContactStatus.pending,
    required this.createdAt,
    this.updatedAt,
    this.userId,
    this.adminResponse,
    this.respondedAt,
  });

  factory Contact.fromMap(Map<String, dynamic> map) {
    return Contact(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      subject: map['subject'] ?? '',
      message: map['message'] ?? '',
      type: ContactType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ContactType.general,
      ),
      status: ContactStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ContactStatus.pending,
      ),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      userId: map['userId'],
      adminResponse: map['adminResponse'],
      respondedAt: map['respondedAt'] != null ? DateTime.parse(map['respondedAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'subject': subject,
      'message': message,
      'type': type.name,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'userId': userId,
      'adminResponse': adminResponse,
      'respondedAt': respondedAt?.toIso8601String(),
    };
  }

  Contact copyWith({
    String? id,
    String? name,
    String? email,
    String? subject,
    String? message,
    ContactType? type,
    ContactStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
    String? adminResponse,
    DateTime? respondedAt,
  }) {
    return Contact(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      subject: subject ?? this.subject,
      message: message ?? this.message,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      adminResponse: adminResponse ?? this.adminResponse,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }
}

enum ContactType {
  general('General Inquiry', '📝'),
  support('Technical Support', '🛠️'),
  complaint('Complaint', '⚠️'),
  suggestion('Suggestion', '💡'),
  billing('Billing Issue', '💳'),
  order('Order Issue', '📦'),
  refund('Refund Request', '💰'),
  other('Other', '❓');

  const ContactType(this.displayName, this.icon);
  final String displayName;
  final String icon;
}

enum ContactStatus {
  pending('Pending', '⏳'),
  inProgress('In Progress', '🔄'),
  resolved('Resolved', '✅'),
  closed('Closed', '🔒');

  const ContactStatus(this.displayName, this.icon);
  final String displayName;
  final String icon;
}

// Helper extension for better display
extension ContactExtension on Contact {
  String get statusDisplay => '${status.icon} ${status.displayName}';
  String get typeDisplay => '${type.icon} ${type.displayName}';
  
  String get formattedDate {
    final months = [
      'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
      'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
    ];
    return '${createdAt.day} ${months[createdAt.month - 1]} ${createdAt.year + 543}';
  }
  
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} วันที่แล้ว';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ชั่วโมงที่แล้ว';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} นาทีที่แล้ว';
    } else {
      return 'เพิ่งส่ง';
    }
  }
}
