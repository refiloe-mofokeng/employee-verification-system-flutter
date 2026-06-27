import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cc_evs/models/user_model.dart';
import 'package:local_auth/local_auth.dart';

class AuthException implements Exception {
  final String code;
  final String message;
  
  AuthException(this.code, this.message);
  
  @override
  String toString() => 'AuthException($code): $message';
}

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final LocalAuthentication _localAuth;

  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    LocalAuthentication? localAuth,
  }) : 
    _auth = auth ?? FirebaseAuth.instance,
    _firestore = firestore ?? FirebaseFirestore.instance,
    _localAuth = localAuth ?? LocalAuthentication();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  void _logInfo(String message) => debugPrint('ℹ️ AuthService Info: $message');
  void _logError(String message, [dynamic error]) {
    debugPrint('❌ AuthService Error: $message');
    if (error != null) debugPrint('🔍 Error details: $error');
  }
  void _logSuccess(String message) => debugPrint('✅ AuthService Success: $message');

  Future<UserModel> createUserWithEmailAndPassword({
    required UserModel userModel,
    required String password,
  }) async {
    try {
      _logInfo('Starting user creation with email: ${userModel.email}');
      
      // Step 1: Create user in Firebase Auth
      final cred = await _auth.createUserWithEmailAndPassword(
        email: userModel.email,
        password: password,
      );

      final firebaseUser = cred.user;
      if (firebaseUser == null || firebaseUser.uid.isEmpty) {
        throw AuthException('user-creation-failed', 'Firebase user creation failed - no UID returned');
      }

      _logInfo('Firebase Auth user created with UID: ${firebaseUser.uid}');
      
      // Step 2: Create user document in Firestore with the UID
      final updatedUser = userModel.copyWith(uid: firebaseUser.uid);
      
      _logInfo('Saving user data to Firestore at path: users/${firebaseUser.uid}');
      
      // Save user data to Firestore in the same operation
      await _firestore.collection('users').doc(firebaseUser.uid).set(updatedUser.toMap());
      
      _logSuccess('User created successfully in both Firebase Auth and Firestore');
      return updatedUser;
    } on FirebaseAuthException catch (e) {
      _logError('Failed to create user in Firebase Auth', e);
      throw AuthException(e.code, handleAuthError(e));
    } catch (e) {
      _logError('Unexpected error creating user', e);
      throw AuthException('unexpected-error', 'An unexpected error occurred: $e');
    }
  }

  // REMOVED: saveUserToFirestore method - now integrated into createUserWithEmailAndPassword

  Future<bool> verifyWithBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) {
        _logError('Biometric hardware unavailable');
        return false;
      }
      
      final isAvailable = await _localAuth.isDeviceSupported();
      if (!isAvailable) {
        _logError('Biometric authentication not available on this device');
        return false;
      }

      return await _localAuth.authenticate(
        localizedReason: 'Authenticate to complete registration',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      _logError('Biometric auth failed', e);
      return false;
    }
  }

  Future<UserModel> signInWithIdentifier({
    required String identifier,
    required String password,
  }) async {
    try {
      String email = identifier.trim();

      if (!identifier.contains('@')) {
        final employeeQuery = await _firestore
            .collection('users')
            .where('employeeNumber', isEqualTo: identifier)
            .limit(1)
            .get();

        if (employeeQuery.docs.isEmpty) {
          final idQuery = await _firestore
              .collection('users')
              .where('idOrPassportNo', isEqualTo: identifier)
              .limit(1)
              .get();

          if (idQuery.docs.isEmpty) {
            throw AuthException('user-not-found', 'No user found with this identifier');
          } else {
            email = idQuery.docs.first.data()['email'];
          }
        } else {
          email = employeeQuery.docs.first.data()['email'];
        }
      }

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw AuthException('sign-in-failed', 'Sign in failed');
      }

      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        throw AuthException('user-not-found', 'User data not found');
      }

      return UserModel.fromMap(userDoc.id, userDoc.data()!);
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.code, handleAuthError(e));
    } catch (e) {
      throw AuthException('unexpected-error', 'An unexpected error occurred');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      _logSuccess('Password reset email sent to $email');
    } on FirebaseAuthException catch (e) {
      _logError('Password reset failed', e);
      throw AuthException(e.code, handleAuthError(e));
    } catch (e) {
      _logError('Unexpected error during password reset', e);
      throw AuthException('unexpected-error', 'An unexpected error occurred');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _logInfo('User signed out');
  }

  String handleAuthError(FirebaseAuthException error) {
    _logInfo('Handling auth error: ${error.code} - ${error.message}');
    switch (error.code) {
      case 'user-not-found': return 'No user found with this email';
      case 'wrong-password': return 'Incorrect password';
      case 'invalid-email': return 'Invalid email format';
      case 'user-disabled': return 'This account has been disabled';
      case 'email-already-in-use': return 'An account already exists with this email';
      case 'weak-password': return 'Password is too weak';
      case 'operation-not-allowed': return 'Email/password accounts are not enabled';
      case 'too-many-requests': return 'Too many attempts. Please try again later';
      case 'network-request-failed': return 'Network error. Please check your internet connection';
      default: return 'An authentication error occurred. Please try again';
    }
  }

  // Optional: Method to update user data in Firestore (for profile updates, etc.)
  Future<void> updateUserData(UserModel user) async {
    try {
      if (user.uid == null || user.uid!.isEmpty) {
        throw AuthException('invalid-uid', 'UID is null or empty');
      }

      await _firestore.collection('users').doc(user.uid).update(user.toMap());
      _logSuccess('User data updated in Firestore');
    } catch (e) {
      _logError('Failed to update user data in Firestore', e);
      rethrow;
    }
  }
}