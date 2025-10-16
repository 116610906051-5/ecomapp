class ChatRoom {
  final String id;
  final String customerId;
  final String customerName;
  final String customerEmail;
  final String? assignedAdminId;
  final String? assignedAdminName;
  final ChatStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final bool isCustomerOnline;
  final bool isAdminOnline;
  final int unreadByCustomer;
  final int unreadByAdmin;

  ChatRoom({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerEmail,
    this.assignedAdminId,
    this.assignedAdminName,
    this.status = ChatStatus.waiting,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessage,
    this.lastMessageAt,
    this.isCustomerOnline = false,
    this.isAdminOnline = false,
    this.unreadByCustomer = 0,
    this.unreadByAdmin = 0,
  });

  factory ChatRoom.fromMap(Map<String, dynamic> map) {
    return ChatRoom(
      id: map['id'] ?? '',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      customerEmail: map['customerEmail'] ?? '',
      assignedAdminId: map['assignedAdminId'],
      assignedAdminName: map['assignedAdminName'],
      status: ChatStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ChatStatus.waiting,
      ),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      lastMessage: map['lastMessage'],
      lastMessageAt: map['lastMessageAt'] != null 
          ? DateTime.parse(map['lastMessageAt']) 
          : null,
      isCustomerOnline: map['isCustomerOnline'] ?? false,
      isAdminOnline: map['isAdminOnline'] ?? false,
      unreadByCustomer: map['unreadByCustomer'] ?? 0,
      unreadByAdmin: map['unreadByAdmin'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'assignedAdminId': assignedAdminId,
      'assignedAdminName': assignedAdminName,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastMessage': lastMessage,
      'lastMessageAt': lastMessageAt?.toIso8601String(),
      'isCustomerOnline': isCustomerOnline,
      'isAdminOnline': isAdminOnline,
      'unreadByCustomer': unreadByCustomer,
      'unreadByAdmin': unreadByAdmin,
    };
  }

  ChatRoom copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerEmail,
    String? assignedAdminId,
    String? assignedAdminName,
    ChatStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? lastMessage,
    DateTime? lastMessageAt,
    bool? isCustomerOnline,
    bool? isAdminOnline,
    int? unreadByCustomer,
    int? unreadByAdmin,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      assignedAdminId: assignedAdminId ?? this.assignedAdminId,
      assignedAdminName: assignedAdminName ?? this.assignedAdminName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      isCustomerOnline: isCustomerOnline ?? this.isCustomerOnline,
      isAdminOnline: isAdminOnline ?? this.isAdminOnline,
      unreadByCustomer: unreadByCustomer ?? this.unreadByCustomer,
      unreadByAdmin: unreadByAdmin ?? this.unreadByAdmin,
    );
  }
}

class ChatMessage {
  final String id;
  final String chatRoomId;
  final String senderId;
  final String senderName;
  final String senderRole; // 'customer' or 'admin'
  final String message;
  final ChatMessageType type;
  final DateTime createdAt;
  final bool isRead;
  final String? imageUrl;
  final String? fileUrl;
  final String? fileName;

  ChatMessage({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.message,
    this.type = ChatMessageType.text,
    required this.createdAt,
    this.isRead = false,
    this.imageUrl,
    this.fileUrl,
    this.fileName,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] ?? '',
      chatRoomId: map['chatRoomId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      senderRole: map['senderRole'] ?? 'customer',
      message: map['message'] ?? '',
      type: ChatMessageType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ChatMessageType.text,
      ),
      createdAt: DateTime.parse(map['createdAt']),
      isRead: map['isRead'] ?? false,
      imageUrl: map['imageUrl'],
      fileUrl: map['fileUrl'],
      fileName: map['fileName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chatRoomId': chatRoomId,
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'message': message,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'imageUrl': imageUrl,
      'fileUrl': fileUrl,
      'fileName': fileName,
    };
  }
}

enum ChatStatus {
  waiting('รออีกครั่วหนึ่ง', '⏳', '🟡'),
  active('กำลังสนทนา', '💬', '🟢'),
  resolved('เสร็จสิ้น', '✅', '🔵'),
  closed('ปิดแล้ว', '🔒', '⚫');

  const ChatStatus(this.displayName, this.icon, this.color);
  final String displayName;
  final String icon;
  final String color;
}

enum ChatMessageType {
  text('ข้อความ', '💬'),
  image('รูปภาพ', '🖼️'),
  file('ไฟล์', '📎'),
  system('ระบบ', '🤖');

  const ChatMessageType(this.displayName, this.icon);
  final String displayName;
  final String icon;
}

// Helper extensions
extension ChatRoomExtension on ChatRoom {
  String get statusDisplay => '${status.icon} ${status.displayName}';
  
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(lastMessageAt ?? createdAt);
    
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

  String get formattedDate {
    final months = [
      'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
      'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
    ];
    return '${createdAt.day} ${months[createdAt.month - 1]} ${createdAt.year + 543}';
  }
}

extension ChatMessageExtension on ChatMessage {
  String get timeFormat {
    final hour = createdAt.hour.toString().padLeft(2, '0');
    final minute = createdAt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String get dateFormat {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(createdAt.year, createdAt.month, createdAt.day);
    
    if (messageDate == today) {
      return 'วันนี้';
    } else if (messageDate == today.subtract(Duration(days: 1))) {
      return 'เมื่อวาน';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year + 543}';
    }
  }

  bool get isFromCustomer => senderRole == 'customer';
  bool get isFromAdmin => senderRole == 'admin';
}
