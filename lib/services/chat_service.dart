import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat.dart';
import 'notification_service.dart';

class ChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _chatRoomsRef = _firestore.collection('chatRooms');
  static final CollectionReference _messagesRef = _firestore.collection('chatMessages');

  // สร้างหรือเข้าร่วมห้องแชท
  static Future<String> createOrJoinChatRoom({
    required String customerId,
    required String customerName,
    required String customerEmail,
  }) async {
    try {
      // ตรวจสอบว่ามีห้องแชทที่ยังไม่ปิดอยู่หรือไม่
      final existingRooms = await _chatRoomsRef
          .where('customerId', isEqualTo: customerId)
          .where('status', whereIn: ['waiting', 'active'])
          .get();

      if (existingRooms.docs.isNotEmpty) {
        final roomId = existingRooms.docs.first.id;
        print('✅ Joining existing chat room: $roomId');
        
        // อัพเดทว่าลูกค้าออนไลน์
        await _updateOnlineStatus(roomId, isCustomer: true, isOnline: true);
        return roomId;
      }

      // สร้างห้องแชทใหม่
      final roomId = _chatRoomsRef.doc().id;
      final chatRoom = ChatRoom(
        id: roomId,
        customerId: customerId,
        customerName: customerName,
        customerEmail: customerEmail,
        status: ChatStatus.waiting,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isCustomerOnline: true,
      );

      await _chatRoomsRef.doc(roomId).set(chatRoom.toMap());
      
      // ส่งข้อความต้อนรับ
      await _sendSystemMessage(
        roomId,
        'สวัสดีครับ! ยินดีต้อนรับสู่ระบบแชทสนับสนุน เรากำลังหาทีมงานมาช่วยเหลือคุณ กรุณารอสักครู่นะครับ',
      );

      print('✅ Created new chat room: $roomId');
      return roomId;
    } catch (e) {
      print('❌ Error creating/joining chat room: $e');
      throw Exception('Failed to create chat room: $e');
    }
  }

  // Admin รับเรื่อง
  static Future<void> assignAdminToChatRoom({
    required String roomId,
    required String adminId,
    required String adminName,
  }) async {
    try {
      await _chatRoomsRef.doc(roomId).update({
        'assignedAdminId': adminId,
        'assignedAdminName': adminName,
        'status': ChatStatus.active.name,
        'updatedAt': DateTime.now().toIso8601String(),
        'isAdminOnline': true,
      });

      // ส่งข้อความแจ้งว่า Admin เข้ามา
      await _sendSystemMessage(
        roomId,
        'ทีมงาน $adminName เข้ามาช่วยเหลือคุณแล้ว สามารถสอบถามได้เลยครับ',
      );

      print('✅ Admin $adminName assigned to room $roomId');
    } catch (e) {
      print('❌ Error assigning admin: $e');
      throw Exception('Failed to assign admin: $e');
    }
  }

  // ส่งข้อความ
  static Future<void> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String senderName,
    required String senderRole,
    required String message,
    ChatMessageType type = ChatMessageType.text,
    String? imageUrl,
    String? fileUrl,
    String? fileName,
  }) async {
    try {
      final messageId = _messagesRef.doc().id;
      final chatMessage = ChatMessage(
        id: messageId,
        chatRoomId: chatRoomId,
        senderId: senderId,
        senderName: senderName,
        senderRole: senderRole,
        message: message,
        type: type,
        createdAt: DateTime.now(),
        imageUrl: imageUrl,
        fileUrl: fileUrl,
        fileName: fileName,
      );

      // ส่งข้อความ
      await _messagesRef.doc(messageId).set(chatMessage.toMap());

      // อัพเดทห้องแชท
      final updateData = <String, dynamic>{
        'lastMessage': message,
        'lastMessageAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // เพิ่มจำนวนข้อความที่ยังไม่ได้อ่าน
      if (senderRole == 'customer') {
        updateData['unreadByAdmin'] = FieldValue.increment(1);
      } else {
        updateData['unreadByCustomer'] = FieldValue.increment(1);
      }

      await _chatRoomsRef.doc(chatRoomId).update(updateData);

      // Send notification (in a real app, this would be handled by backend)
      try {
        await NotificationService.sendChatNotification(
          toUserId: senderRole == 'customer' ? 'admin' : 'customer',
          fromUserName: senderName,
          message: type == ChatMessageType.image ? '📷 ส่งรูปภาพ' : message,
          chatRoomId: chatRoomId,
        );
      } catch (notificationError) {
        print('⚠️ Failed to send notification: $notificationError');
      }

      print('✅ Message sent to room $chatRoomId');
    } catch (e) {
      print('❌ Error sending message: $e');
      throw Exception('Failed to send message: $e');
    }
  }

  // ส่งข้อความระบบ
  static Future<void> _sendSystemMessage(String chatRoomId, String message) async {
    try {
      final messageId = _messagesRef.doc().id;
      final systemMessage = ChatMessage(
        id: messageId,
        chatRoomId: chatRoomId,
        senderId: 'system',
        senderName: 'ระบบ',
        senderRole: 'system',
        message: message,
        type: ChatMessageType.system,
        createdAt: DateTime.now(),
        isRead: true,
      );

      await _messagesRef.doc(messageId).set(systemMessage.toMap());
    } catch (e) {
      print('❌ Error sending system message: $e');
    }
  }

  // ดึงข้อความทั้งหมดในห้อง (Real-time)
  static Stream<List<ChatMessage>> getChatMessages(String chatRoomId) {
    try {
      return _messagesRef
          .where('chatRoomId', isEqualTo: chatRoomId)
          .snapshots()
          .map((snapshot) {
        final messages = snapshot.docs.map((doc) {
          try {
            final data = doc.data() as Map<String, dynamic>;
            return ChatMessage.fromMap(data);
          } catch (e) {
            print('❌ Error parsing message ${doc.id}: $e');
            return null;
          }
        }).where((message) => message != null).cast<ChatMessage>().toList();

        // Sort by time
        messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        return messages;
      });
    } catch (e) {
      print('❌ Error getting messages stream: $e');
      return Stream.value([]);
    }
  }

  // ดึงห้องแชทของลูกค้า
  static Stream<List<ChatRoom>> getCustomerChatRooms(String customerId) {
    try {
      return _chatRoomsRef
          .where('customerId', isEqualTo: customerId)
          .snapshots()
          .map((snapshot) {
        final rooms = snapshot.docs.map((doc) {
          try {
            final data = doc.data() as Map<String, dynamic>;
            return ChatRoom.fromMap(data);
          } catch (e) {
            print('❌ Error parsing chat room ${doc.id}: $e');
            return null;
          }
        }).where((room) => room != null).cast<ChatRoom>().toList();

        // Sort by last message time
        rooms.sort((a, b) => (b.lastMessageAt ?? b.createdAt)
            .compareTo(a.lastMessageAt ?? a.createdAt));
        return rooms;
      });
    } catch (e) {
      print('❌ Error getting customer chat rooms: $e');
      return Stream.value([]);
    }
  }

  // ดึงห้องแชททั้งหมด (สำหรับ Admin)
  static Stream<List<ChatRoom>> getAllChatRooms() {
    try {
      return _chatRoomsRef
          .snapshots()
          .map((snapshot) {
        final rooms = snapshot.docs.map((doc) {
          try {
            final data = doc.data() as Map<String, dynamic>;
            return ChatRoom.fromMap(data);
          } catch (e) {
            print('❌ Error parsing admin chat room ${doc.id}: $e');
            return null;
          }
        }).where((room) => room != null).cast<ChatRoom>().toList();

        // Sort by status and time
        rooms.sort((a, b) {
          // Waiting rooms first
          if (a.status == ChatStatus.waiting && b.status != ChatStatus.waiting) {
            return -1;
          }
          if (b.status == ChatStatus.waiting && a.status != ChatStatus.waiting) {
            return 1;
          }
          // Then by last message time
          return (b.lastMessageAt ?? b.createdAt)
              .compareTo(a.lastMessageAt ?? a.createdAt);
        });
        
        return rooms;
      });
    } catch (e) {
      print('❌ Error getting all chat rooms: $e');
      return Stream.value([]);
    }
  }

  // อัพเดทสถานะออนไลน์
  static Future<void> _updateOnlineStatus(
    String roomId, {
    required bool isCustomer,
    required bool isOnline,
  }) async {
    try {
      final field = isCustomer ? 'isCustomerOnline' : 'isAdminOnline';
      await _chatRoomsRef.doc(roomId).update({
        field: isOnline,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('❌ Error updating online status: $e');
    }
  }

  // เข้าห้องแชท (อัพเดทสถานะออนไลน์)
  static Future<void> joinChatRoom(String roomId, bool isAdmin) async {
    try {
      final field = isAdmin ? 'adminOnline' : 'customerOnline';
      await _chatRoomsRef.doc(roomId).update({
        field: true,
        'lastSeen': FieldValue.serverTimestamp(),
      });
      print('✅ ${isAdmin ? 'Admin' : 'Customer'} joined chat room: $roomId');
    } catch (e) {
      print('❌ Error joining chat room: $e');
      throw e;
    }
  }

  // ออกจากห้องแชท
  static Future<void> leaveChatRoom(String roomId, bool isAdmin) async {
    try {
      final field = isAdmin ? 'adminOnline' : 'customerOnline';
      await _chatRoomsRef.doc(roomId).update({
        field: false,
        'lastSeen': FieldValue.serverTimestamp(),
      });
      print('✅ ${isAdmin ? 'Admin' : 'Customer'} left chat room: $roomId');
    } catch (e) {
      print('❌ Error leaving chat room: $e');
    }
  }

  // ปิดห้องแชท
  static Future<void> closeChatRoom(String roomId, String reason) async {
    try {
      await _chatRoomsRef.doc(roomId).update({
        'status': 'closed',
        'closedAt': FieldValue.serverTimestamp(),
        'closedReason': reason,
      });

      // ส่งข้อความปิดห้อง
      await sendMessage(
        chatRoomId: roomId,
        senderId: 'system',
        senderName: 'System',
        senderRole: 'system',
        message: 'แชทถูกปิดแล้ว: $reason',
      );
      
      print('✅ Chat room closed: $roomId');
    } catch (e) {
      print('❌ Error closing chat room: $e');
      throw e;
    }
  }

  // ดึงสถิติแชท
  static Future<Map<String, int>> getChatStats() async {
    try {
      final snapshot = await _chatRoomsRef.get();
      final rooms = snapshot.docs.map((doc) {
        try {
          return ChatRoom.fromMap(doc.data() as Map<String, dynamic>);
        } catch (e) {
          return null;
        }
      }).where((room) => room != null).cast<ChatRoom>().toList();

      return {
        'total': rooms.length,
        'waiting': rooms.where((r) => r.status == ChatStatus.waiting).length,
        'active': rooms.where((r) => r.status == ChatStatus.active).length,
        'resolved': rooms.where((r) => r.status == ChatStatus.resolved).length,
        'closed': rooms.where((r) => r.status == ChatStatus.closed).length,
      };
    } catch (e) {
      print('❌ Error getting chat stats: $e');
      return {};
    }
  }

  // ดึงห้องที่รอคิว
  static Stream<int> getWaitingRoomsCount() {
    try {
      return _chatRoomsRef
          .where('status', isEqualTo: ChatStatus.waiting.name)
          .snapshots()
          .map((snapshot) => snapshot.docs.length);
    } catch (e) {
      print('❌ Error getting waiting rooms count: $e');
      return Stream.value(0);
    }
  }

  // Mark messages as read
  static Future<void> markMessagesAsRead(String chatRoomId, bool isAdmin) async {
    try {
      print('📖 Marking messages as read for chatRoomId: $chatRoomId, isAdmin: $isAdmin');
      
      // Update unread count in chat room
      final field = isAdmin ? 'unreadByAdmin' : 'unreadByCustomer';
      print('📖 Updating field: $field to 0');
      
      await _chatRoomsRef.doc(chatRoomId).update({
        field: 0,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      print('📖 Updated $field = 0 in chatRoom document');

      // Mark individual messages as read
      final messages = await _messagesRef
          .where('chatRoomId', isEqualTo: chatRoomId)
          .where('isRead', isEqualTo: false)
          .get();

      print('📖 Found ${messages.docs.length} unread messages to mark as read');

      // Batch update for performance
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in messages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      
      if (messages.docs.isNotEmpty) {
        await batch.commit();
        print('📖 Batch committed: ${messages.docs.length} messages marked as read');
      }

      print('✅ Messages marked as read for ${isAdmin ? 'admin' : 'customer'}');
    } catch (e) {
      print('❌ Error marking messages as read: $e');
    }
  }
}
