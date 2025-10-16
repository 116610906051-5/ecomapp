import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../services/notification_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? _user;
  AppUser? _currentUser;
  bool _isLoading = false;

  User? get user => _user;
  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  bool get isLoggedIn => _user != null;

  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  void _onAuthStateChanged(User? user) async {
    print('Auth state changed: ${user?.email}');
    _user = user;
    if (user != null) {
      await _loadUserData(user.uid);
    } else {
      _currentUser = null;
    }
    _isLoading = false; // Important: Set loading to false when auth state changes
    notifyListeners();
  }

  Future<void> _loadUserData(String uid) async {
    try {
      print('📚 Loading user data for UID: $uid');
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        print('📚 User data found: $data');
        _currentUser = AppUser.fromMap({...data, 'id': doc.id});
        print('📚 CurrentUser set: ${_currentUser?.email}');
        
        // Update FCM token for notifications
        await NotificationService.updateUserFCMToken(uid);
      } else {
        print('📚 No user document found, creating from Firebase Auth user');
        // หากไม่มีเอกสารใน Firestore ให้สร้างจากข้อมูล Firebase Auth
        final firebaseUser = _auth.currentUser;
        if (firebaseUser != null) {
          final now = DateTime.now();
          _currentUser = AppUser(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? '',
            name: firebaseUser.displayName ?? 'User',
            displayName: firebaseUser.displayName ?? 'User',
            photoURL: firebaseUser.photoURL,
            createdAt: now,
            updatedAt: now,
          );
          
          // บันทึกข้อมูลลง Firestore
          final userData = {
            'id': firebaseUser.uid,
            'email': firebaseUser.email ?? '',
            'name': firebaseUser.displayName ?? 'User',
            'displayName': firebaseUser.displayName ?? 'User',
            'photoURL': firebaseUser.photoURL,
            'phoneNumber': null,
            'addresses': [],
            'createdAt': now.toIso8601String(),
            'updatedAt': now.toIso8601String(),
          };
          await _firestore.collection('users').doc(firebaseUser.uid).set(userData);
          print('📚 Created new user document in Firestore');
        }
      }
    } catch (e) {
      print('❌ Error loading user data: $e');
      // หากเกิดข้อผิดพลาดในการโหลดจาก Firestore ให้ใช้ข้อมูลจาก Firebase Auth
      final firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        final now = DateTime.now();
        _currentUser = AppUser(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          name: firebaseUser.displayName ?? 'User',
          displayName: firebaseUser.displayName ?? 'User',
          photoURL: firebaseUser.photoURL,
          createdAt: now,
          updatedAt: now,
        );
        print('📚 Fallback: Using Firebase Auth user data');
      }
    }
  }

  Future<void> createUserWithEmailAndPassword(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      print('📝 Creating user account for: $email');
      _isLoading = true;
      notifyListeners();

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        print('✅ Firebase account created: ${credential.user!.uid}');
        
        // Update display name
        await credential.user!.updateDisplayName(displayName);
        print('✅ Display name updated: $displayName');

        // Create user document in Firestore
        final userData = AppUser(
          id: credential.user!.uid,
          email: email,
          name: displayName,
          displayName: displayName,
          photoURL: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .set(userData.toMap());
        
        print('✅ User document created in Firestore');
        _currentUser = userData;
        
        // รอให้ Firebase Auth state เปลี่ยน
        await Future.delayed(Duration(milliseconds: 1000));
        print('🔄 Account creation completed');
      }
    } catch (e, stackTrace) {
      print('❌ Error creating user: $e');
      print('❌ Stack trace: $stackTrace');
      
      // Handle cast error specifically
      if (e.toString().contains('List<Object?>')) {
        print('🔄 Cast error during registration - force reload auth state');
        final currentUser = _auth.currentUser;
        if (currentUser != null) {
          await currentUser.reload();
          _user = _auth.currentUser;
          await _loadUserData(_user!.uid);
          notifyListeners();
          return; // สำเร็จแล้ว ไม่ต้อง throw error
        }
      }
      
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      print('🔐 Attempting to sign in with: $email');
      _isLoading = true;
      notifyListeners();

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('✅ Sign in successful: ${userCredential.user?.email}');
      print('✅ User ID: ${userCredential.user?.uid}');
      print('✅ User verified: ${userCredential.user?.emailVerified}');
      
      // รอให้ _onAuthStateChanged ทำงานเสร็จ
      await Future.delayed(Duration(milliseconds: 1000));
      print('🔄 Auth state should be updated now');
      
    } catch (e, stackTrace) {
      print('❌ Error signing in: $e');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ Stack trace: $stackTrace');
      
      // แปลง error ให้เข้าใจง่าย
      String errorMessage = 'Login failed';
      if (e.toString().contains('user-not-found')) {
        errorMessage = 'No account found with this email';
        print('❌ User not found - email may not be registered');
      } else if (e.toString().contains('wrong-password')) {
        errorMessage = 'Incorrect password';
        print('❌ Wrong password');
      } else if (e.toString().contains('invalid-email')) {
        errorMessage = 'Invalid email format';
        print('❌ Invalid email format');
      } else if (e.toString().contains('user-disabled')) {
        errorMessage = 'User account has been disabled';
        print('❌ User account disabled');
      } else if (e.toString().contains('List<Object?>')) {
        // Handle the specific cast error
        errorMessage = 'Authentication data format error. Please try again.';
        print('❌ Cast error - likely Firebase plugin version issue');
        
        // Force reload auth state
        final currentUser = _auth.currentUser;
        if (currentUser != null) {
          print('🔄 Force reloading auth state');
          await currentUser.reload();
          _user = _auth.currentUser;
          await _loadUserData(_user!.uid);
          notifyListeners();
          return; // ถ้าสำเร็จให้ return ไม่ต้อง throw error
        }
      }
      
      throw Exception(errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _currentUser = null;
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Error sending password reset email: $e');
      rethrow;
    }
  }

  Future<void> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      if (_user == null || _currentUser == null) return;

      // Update Firebase Auth profile
      if (displayName != null) {
        await _user!.updateDisplayName(displayName);
      }
      if (photoURL != null) {
        await _user!.updatePhotoURL(photoURL);
      }

      // Update Firestore document
      final updatedData = {
        'displayName': displayName ?? _currentUser!.displayName,
        'photoURL': photoURL ?? _currentUser!.photoURL,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(_user!.uid)
          .update(updatedData);

      // Update local user data
      _currentUser = _currentUser!.copyWith(
        displayName: displayName ?? _currentUser!.displayName,
        photoURL: photoURL ?? _currentUser!.photoURL,
        updatedAt: DateTime.now(),
      );

      notifyListeners();
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    try {
      if (_user == null) return;

      final uid = _user!.uid;

      // Delete user document from Firestore
      await _firestore.collection('users').doc(uid).delete();

      // Delete user cart
      final cartCollection = _firestore
          .collection('users')
          .doc(uid)
          .collection('cart');
      final cartDocs = await cartCollection.get();
      final batch = _firestore.batch();
      for (var doc in cartDocs.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Delete Firebase Auth account
      await _user!.delete();

      _currentUser = null;
    } catch (e) {
      print('Error deleting account: $e');
      rethrow;
    }
  }

  Future<void> updateUserProfile({
    String? displayName,
    String? phone,
  }) async {
    try {
      if (_user == null || _currentUser == null) {
        throw Exception('User not authenticated');
      }

      print('📝 Updating user profile for: ${_user!.uid}');

      // Update Firestore document
      Map<String, dynamic> updateData = {
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (displayName != null && displayName.trim().isNotEmpty) {
        updateData['displayName'] = displayName.trim();
        updateData['name'] = displayName.trim();
      }

      if (phone != null) {
        updateData['phoneNumber'] = phone.trim();
      }

      try {
        await _firestore.collection('users').doc(_user!.uid).update(updateData);
        print('✅ Firestore update successful');
      } catch (firestoreError) {
        print('⚠️ Firestore update failed: $firestoreError');
        // Still update local data even if Firestore fails
      }

      // Update local user data (always do this)
      _currentUser = _currentUser!.copyWith(
        displayName: displayName?.trim() ?? _currentUser!.displayName,
        name: displayName?.trim() ?? _currentUser!.name,
        phoneNumber: phone?.trim() ?? _currentUser!.phoneNumber,
        updatedAt: DateTime.now(),
      );

      print('✅ Local user profile updated successfully');
      notifyListeners();
    } catch (e) {
      print('❌ Error updating user profile: $e');
      rethrow;
    }
  }
}
