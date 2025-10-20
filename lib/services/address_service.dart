import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/address.dart';

class AddressService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collection = 'addresses';

  // Get all addresses for a user
  Stream<List<Address>> getUserAddresses(String userId) {
    return _firestore
        .collection(collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      // Sort in memory instead of using orderBy to avoid index requirement
      final addresses = snapshot.docs
          .map((doc) => Address.fromMap(doc.data()))
          .toList();
      
      // Sort: default first, then by updated time
      addresses.sort((a, b) {
        if (a.isDefault && !b.isDefault) return -1;
        if (!a.isDefault && b.isDefault) return 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });
      
      return addresses;
    });
  }

  // Get default address for a user
  Future<Address?> getDefaultAddress(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(collection)
          .where('userId', isEqualTo: userId)
          .where('isDefault', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return Address.fromMap(querySnapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      print('Error getting default address: $e');
      return null;
    }
  }

  // Add new address
  Future<void> addAddress(Address address) async {
    try {
      // If this is set as default, unset all other defaults
      if (address.isDefault) {
        await _unsetAllDefaults(address.userId);
      }

      await _firestore
          .collection(collection)
          .doc(address.id)
          .set(address.toMap());
    } catch (e) {
      print('Error adding address: $e');
      rethrow;
    }
  }

  // Update address
  Future<void> updateAddress(Address address) async {
    try {
      // If this is set as default, unset all other defaults
      if (address.isDefault) {
        await _unsetAllDefaults(address.userId);
      }

      await _firestore
          .collection(collection)
          .doc(address.id)
          .update(address.toMap());
    } catch (e) {
      print('Error updating address: $e');
      rethrow;
    }
  }

  // Delete address
  Future<void> deleteAddress(String addressId) async {
    try {
      await _firestore.collection(collection).doc(addressId).delete();
    } catch (e) {
      print('Error deleting address: $e');
      rethrow;
    }
  }

  // Set address as default
  Future<void> setDefaultAddress(String userId, String addressId) async {
    try {
      // Unset all defaults first
      await _unsetAllDefaults(userId);

      // Set this address as default
      await _firestore
          .collection(collection)
          .doc(addressId)
          .update({
        'isDefault': true,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error setting default address: $e');
      rethrow;
    }
  }

  // Helper: Unset all default addresses for a user
  Future<void> _unsetAllDefaults(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(collection)
          .where('userId', isEqualTo: userId)
          .where('isDefault', isEqualTo: true)
          .get();

      final batch = _firestore.batch();
      for (var doc in querySnapshot.docs) {
        batch.update(doc.reference, {
          'isDefault': false,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
      await batch.commit();
    } catch (e) {
      print('Error unsetting defaults: $e');
    }
  }

  // Get single address by ID
  Future<Address?> getAddressById(String addressId) async {
    try {
      final doc = await _firestore.collection(collection).doc(addressId).get();
      if (doc.exists) {
        return Address.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting address: $e');
      return null;
    }
  }
}
