import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/contact.dart';

class ContactService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _contactsRef = _firestore.collection('contacts');

  // ส่งข้อความติดต่อใหม่
  static Future<String> submitContact({
    required String name,
    required String email,
    required String subject,
    required String message,
    required ContactType type,
    String? userId,
  }) async {
    try {
      final contactId = _contactsRef.doc().id;
      
      final contact = Contact(
        id: contactId,
        name: name,
        email: email,
        subject: subject,
        message: message,
        type: type,
        status: ContactStatus.pending,
        createdAt: DateTime.now(),
        userId: userId,
      );

      await _contactsRef.doc(contactId).set(contact.toMap());
      
      print('✅ Contact submitted successfully: $contactId');
      return contactId;
    } catch (e) {
      print('❌ Error submitting contact: $e');
      throw Exception('Failed to submit contact: $e');
    }
  }

  // ดึงข้อมูลติดต่อทั้งหมด (สำหรับ Admin)
  static Stream<List<Contact>> getAllContacts() {
    try {
      return _contactsRef
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          try {
            final data = doc.data() as Map<String, dynamic>;
            return Contact.fromMap(data);
          } catch (e) {
            print('❌ Error parsing contact ${doc.id}: $e');
            return null;
          }
        }).where((contact) => contact != null).cast<Contact>().toList();
      });
    } catch (e) {
      print('❌ Error getting contacts stream: $e');
      return Stream.value([]);
    }
  }

  // ดึงข้อมูลติดต่อของผู้ใช้คนหนึ่ง
  static Stream<List<Contact>> getUserContacts(String userId) {
    print('🔍 Getting contacts for userId: $userId');
    
    return Stream.fromFuture(_getUserContactsFallback(userId));
  }

  // Fallback method using simple get() instead of snapshots with orderBy
  static Future<List<Contact>> _getUserContactsFallback(String userId) async {
    try {
      print('🔄 Using fallback method to get user contacts');
      
      final snapshot = await _contactsRef
          .where('userId', isEqualTo: userId)
          .get();
      
      print('📄 Got ${snapshot.docs.length} documents from fallback');
      
      final contacts = snapshot.docs.map((doc) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          print('📝 Processing contact: ${data['subject']}');
          return Contact.fromMap(data);
        } catch (e) {
          print('❌ Error parsing contact ${doc.id}: $e');
          return null;
        }
      }).where((contact) => contact != null).cast<Contact>().toList();
      
      // Sort in memory
      contacts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      print('✅ Returning ${contacts.length} contacts from fallback');
      
      return contacts;
    } catch (e) {
      print('❌ Fallback method error: $e');
      return [];
    }
  }

  // อัพเดทสถานะ (สำหรับ Admin)
  static Future<void> updateContactStatus(
    String contactId,
    ContactStatus status, {
    String? adminResponse,
  }) async {
    try {
      final updateData = {
        'status': status.name,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      
      if (adminResponse != null) {
        updateData['adminResponse'] = adminResponse;
        updateData['respondedAt'] = DateTime.now().toIso8601String();
      }

      await _contactsRef.doc(contactId).update(updateData);
      print('✅ Contact status updated: $contactId -> $status');
    } catch (e) {
      print('❌ Error updating contact status: $e');
      throw Exception('Failed to update contact status: $e');
    }
  }

  // ลบข้อความติดต่อ (สำหรับ Admin)
  static Future<void> deleteContact(String contactId) async {
    try {
      await _contactsRef.doc(contactId).delete();
      print('✅ Contact deleted: $contactId');
    } catch (e) {
      print('❌ Error deleting contact: $e');
      throw Exception('Failed to delete contact: $e');
    }
  }

  // ดึงสถิติ Contact (สำหรับ Admin Dashboard)
  static Future<Map<String, int>> getContactStats() async {
    try {
      final snapshot = await _contactsRef.get();
      final contacts = snapshot.docs.map((doc) {
        try {
          return Contact.fromMap(doc.data() as Map<String, dynamic>);
        } catch (e) {
          return null;
        }
      }).where((contact) => contact != null).cast<Contact>().toList();

      final stats = <String, int>{
        'total': contacts.length,
        'pending': contacts.where((c) => c.status == ContactStatus.pending).length,
        'inProgress': contacts.where((c) => c.status == ContactStatus.inProgress).length,
        'resolved': contacts.where((c) => c.status == ContactStatus.resolved).length,
        'closed': contacts.where((c) => c.status == ContactStatus.closed).length,
      };

      // นับตามประเภท
      for (final type in ContactType.values) {
        stats[type.name] = contacts.where((c) => c.type == type).length;
      }

      return stats;
    } catch (e) {
      print('❌ Error getting contact stats: $e');
      return {};
    }
  }

  // ค้นหา Contact
  static Future<List<Contact>> searchContacts(String query) async {
    try {
      final snapshot = await _contactsRef.get();
      final contacts = snapshot.docs.map((doc) {
        try {
          return Contact.fromMap(doc.data() as Map<String, dynamic>);
        } catch (e) {
          return null;
        }
      }).where((contact) => contact != null).cast<Contact>().toList();

      final searchQuery = query.toLowerCase();
      return contacts.where((contact) {
        return contact.name.toLowerCase().contains(searchQuery) ||
               contact.email.toLowerCase().contains(searchQuery) ||
               contact.subject.toLowerCase().contains(searchQuery) ||
               contact.message.toLowerCase().contains(searchQuery);
      }).toList();
    } catch (e) {
      print('❌ Error searching contacts: $e');
      return [];
    }
  }

  // ส่งการตอบกลับ (สำหรับ Admin)
  static Future<void> replyToContact(
    String contactId,
    String adminResponse,
  ) async {
    try {
      await updateContactStatus(
        contactId,
        ContactStatus.resolved,
        adminResponse: adminResponse,
      );
      print('✅ Admin reply sent to contact: $contactId');
    } catch (e) {
      print('❌ Error sending admin reply: $e');
      throw Exception('Failed to send reply: $e');
    }
  }

  // ดึงข้อมูล Contact ตาม ID
  static Future<Contact?> getContactById(String contactId) async {
    try {
      final doc = await _contactsRef.doc(contactId).get();
      if (doc.exists) {
        return Contact.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('❌ Error getting contact by ID: $e');
      return null;
    }
  }

  // ดึงจำนวน Contact ที่ยังไม่ได้จัดการ (สำหรับ Badge)
  static Stream<int> getPendingContactsCount() {
    try {
      return _contactsRef
          .where('status', isEqualTo: ContactStatus.pending.name)
          .snapshots()
          .map((snapshot) => snapshot.docs.length);
    } catch (e) {
      print('❌ Error getting pending contacts count: $e');
      return Stream.value(0);
    }
  }
}
