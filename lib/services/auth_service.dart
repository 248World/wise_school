import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _firebaseAuth.currentUser;

  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      return null;
    }

    final doc = await _firestore.collection('users').doc(user.uid).get();

    if (!doc.exists) {
      return null;
    }

    return {
      'id': doc.id,
      ...doc.data()!,
    };
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    final user = credential.user;

    if (user == null) {
      throw Exception('Login failed. Please try again.');
    }

    final userDoc = await _firestore.collection('users').doc(user.uid).get();

    if (!userDoc.exists) {
      throw Exception('User profile not found in database.');
    }

    final data = userDoc.data()!;

    if (data['isActive'] == false) {
      throw Exception('This account has been disabled.');
    }

    return {
      'id': userDoc.id,
      ...data,
    };
  }

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    final user = credential.user;

    if (user == null) {
      throw Exception('Account creation failed. Please try again.');
    }

    await user.updateDisplayName(fullName.trim());

    final userData = {
      'fullName': fullName.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'role': role,
      'profileImage': '',
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('users').doc(user.uid).set(userData);

    return {
      'id': user.uid,
      ...userData,
    };
  }

  Future<void> sendPasswordReset({
    required String email,
  }) async {
    await _firebaseAuth.sendPasswordResetEmail(
      email: email.trim(),
    );
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }
}