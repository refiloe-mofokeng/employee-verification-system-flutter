import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_cc_evs/models/user_model.dart';
import 'package:flutter_cc_evs/services/auth_service.dart';
import 'package:flutter_cc_evs/views/auth/otp_verification_screen.dart';
import 'package:flutter_cc_evs/views/wrapper/navigation_wrapper.dart';
import 'package:flutter_cc_evs/widgets/custom_snackbars.dart';

class SignUpAuthOptionsScreen extends StatefulWidget {
  final UserModel user;
  final String password;

  const SignUpAuthOptionsScreen({super.key, required this.user, required this.password});

  @override
  State<SignUpAuthOptionsScreen> createState() => _SignUpAuthOptionsScreenState();
}

class _SignUpAuthOptionsScreenState extends State<SignUpAuthOptionsScreen> {
  final AuthService _authService = AuthService();
  String? _selectedOption;
  bool _isLoading = false;
  final String dialCode = "+27";

  Widget _buildAuthOptionCard({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback? onTap,
    required IconData icon,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Colors.blue : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Colors.blue : Colors.grey.shade700,
          size: 28,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey.shade600),
        ),
        trailing: Radio<String>(
          value: title.toLowerCase().contains('otp') ? 'otp' : 'biometric',
          groupValue: _selectedOption,
          onChanged: (value) => onTap?.call(),
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Future<void> _sendOTP() async {
    final phone = widget.user.phoneNumber.trim(); // FIXED: widget.user is not null
    if (phone.isEmpty) {
      if (mounted) {
        CustomSnackbar.showError(context, "Phone number missing from registration form");
      }
      return;
    }

    if (!mounted) return; // FIXED: Use mounted check

    setState(() {
      _selectedOption = 'otp';
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: "$dialCode$phone",
        verificationCompleted: (PhoneAuthCredential credential) async {
          final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
          if (userCredential.user != null && mounted) { // FIXED: Use mounted
            // Create user after successful verification
            final updatedUser = widget.user.copyWith(
              uid: userCredential.user!.uid,
              isOTPVerified: true,
            );

            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const NavigationWrapper()),
              );
            }
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (mounted) { // FIXED: Use mounted
            CustomSnackbar.showError(context, "Verification failed: ${e.message}");
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          if (mounted) { // FIXED: Use mounted
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OtpVerificationScreen(
                  verificationId: verificationId,
                  user: widget.user,
                  password: widget.password,
                ),
              ),
            );
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint("Auto retrieval timeout: $verificationId");
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      if (mounted) { // FIXED: Use mounted
        CustomSnackbar.showError(context, "OTP sending failed: $e");
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleBiometricSignUp() async {
  if (!mounted) return;

  setState(() {
    _selectedOption = 'biometric';
    _isLoading = true;
  });

  try {
    // First, verify biometric authentication
    final verified = await _authService.verifyWithBiometrics();
    if (!verified) {
      throw Exception('Biometric authentication failed');
    }

    // Create user in both Firebase Auth and Firestore in one operation
    final userCredential = await _authService.createUserWithEmailAndPassword(
      userModel: widget.user.copyWith(isBiometricCompleted: true),
      password: widget.password,
    );

    if (mounted) {
      CustomSnackbar.showSuccess(context, "Account created successfully with biometric verification!");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const NavigationWrapper()),
      );
    }
  } catch (e) {
    if (mounted) {
      CustomSnackbar.showError(context, "Error during biometric sign-up: $e");
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Authentication Options")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Choose your preferred authentication method",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildAuthOptionCard(
              title: "OTP Authentication",
              subtitle: "Receive a verification code via SMS",
              isSelected: _selectedOption == 'otp',
              onTap: _sendOTP,
              icon: Icons.sms,
            ),
            const SizedBox(height: 16),
            _buildAuthOptionCard(
              title: "Biometric Authentication",
              subtitle: "Use your fingerprint or face ID",
              isSelected: _selectedOption == 'biometric',
              onTap: _handleBiometricSignUp,
              icon: Icons.fingerprint,
            ),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 32),
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}