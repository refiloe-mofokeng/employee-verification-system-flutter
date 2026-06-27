import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cc_evs/services/auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

mixin ViewModelErrorHandler on ChangeNotifier {
  String? _error;
  String? get error => _error;

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  Future<T> handleAsyncOperation<T>(Future<T> operation) async {
    try {
      setError(null);
      return await operation;
    } catch (e) {
      setError(e.toString());
      rethrow;
    }
  }
}

class SignInViewModel with ChangeNotifier, ViewModelErrorHandler {
  final AuthService _authService = AuthService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _rememberMe = false;
  bool _obscurePassword = true;

  bool get isLoading => _isLoading;
  bool get rememberMe => _rememberMe;
  bool get obscurePassword => _obscurePassword;

  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  set rememberMe(bool value) {
    _rememberMe = value;
    notifyListeners();
  }

  set obscurePassword(bool value) {
    _obscurePassword = value;
    notifyListeners();
  }

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
  }

  void toggleRememberMe() {
    rememberMe = !rememberMe;
  }

  Future<User?> signIn() async {
    final identifier = usernameController.text.trim();
    final password = passwordController.text.trim();

    if (identifier.isEmpty) throw 'Please enter your username/email';
    if (password.isEmpty) throw 'Please enter your password';
    
    if (!identifier.contains('@') && identifier.length < 3) {
      throw 'Please enter a valid username or email';
    }

    return await handleAsyncOperation(_performSignIn(identifier, password));
  }

  // In the _performSignIn method, remove the unused userModel variable:
Future<User?> _performSignIn(String identifier, String password) async {
  isLoading = true;
  try {
    await _authService.signInWithIdentifier( // FIXED: Remove unused variable assignment
      identifier: identifier,
      password: password,
    );
    
    if (rememberMe) {
      await _saveCredentials(identifier);
    } else {
      await _clearCredentials();
    }
    
    return FirebaseAuth.instance.currentUser;
  } finally {
    isLoading = false;
  }
}

  Future<void> forgotPassword() async {
    final identifier = usernameController.text.trim();
    if (identifier.isEmpty) throw 'Please enter your username/email';

    await handleAsyncOperation(_authService.sendPasswordResetEmail(
      await _getEmailFromIdentifier(identifier)
    ));
  }

  Future<String> _getEmailFromIdentifier(String identifier) async {
    if (identifier.contains('@')) return identifier;
    
    // Lookup email from identifier
    final authService = AuthService();
    try {
      // This will throw if user not found, which is fine for password reset
      await authService.signInWithIdentifier(
        identifier: identifier, 
        password: 'dummy' // Will fail but we just need the email lookup
      );
    } catch (e) {
      // Extract email from error or rethrow
      if (e.toString().contains('user-not-found')) {
        throw 'No user found with this identifier';
      }
      // If it's a password error, the user exists but we can't get email this way
      throw 'Please use your email address for password reset';
    }
    
    throw 'Unable to process password reset';
  }

  Future<void> _saveCredentials(String identifier) async {
    await _secureStorage.write(key: 'username', value: identifier);
    // Never store passwords
  }

  Future<void> _clearCredentials() async {
    await _secureStorage.delete(key: 'username');
  }

  Future<void> loadSavedCredentials() async {
    final savedUsername = await _secureStorage.read(key: 'username');
    if (savedUsername != null) {
      usernameController.text = savedUsername;
      rememberMe = true;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}