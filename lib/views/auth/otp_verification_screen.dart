import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cc_evs/models/user_model.dart';
import 'package:flutter_cc_evs/services/auth_service.dart';
import 'package:flutter_cc_evs/views/wrapper/navigation_wrapper.dart';
import 'package:flutter_cc_evs/widgets/custom_snackbars.dart';
import 'package:pinput/pinput.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String verificationId;
  final UserModel user;
  final String password;

  const OtpVerificationScreen({
    super.key,
    required this.verificationId,
    required this.user,
    required this.password,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _canResend = true;
  int _resendTimer = 60;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _resendTimer--;
          if (_resendTimer > 0) {
            _startResendTimer();
          } else {
            _canResend = true;
          }
        });
      }
    });
  }

  Future<void> _resendOTP() async {
    if (!_canResend) return;

    setState(() {
      _canResend = false;
      _resendTimer = 60;
    });

    _startResendTimer();

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: "+27${widget.user.phoneNumber}",
        verificationCompleted: (credential) {},
        verificationFailed: (e) {
          if (context.mounted) {
            CustomSnackbar.showError(context, "Resend failed: ${e.message}");
          }
        },
        codeSent: (verificationId, resendToken) {
          if (context.mounted) {
            CustomSnackbar.showSuccess(context, "OTP resent successfully");
          }
        },
        codeAutoRetrievalTimeout: (verificationId) {},
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      if (context.mounted) {
        CustomSnackbar.showError(context, "Failed to resend OTP: $e");
      }
    }
  }


Future<void> verifyOTP(String pin) async {
  if (!mounted) return;

  setState(() => _isLoading = true);

  try {
    final credential = PhoneAuthProvider.credential(
      verificationId: widget.verificationId,
      smsCode: pin,
    );

    final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
    
    if (userCredential.user != null) {
      // Create user in both Firebase Auth and Firestore
      final updatedUser = widget.user.copyWith(
        uid: userCredential.user!.uid,
        isOTPVerified: true,
      );
      
      await _authService.createUserWithEmailAndPassword(
        userModel: updatedUser,
        password: widget.password, // This will now work
      );
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const NavigationWrapper()),
        );
      }
    }
  } catch (e) {
    if (mounted) {
      CustomSnackbar.showError(context, "Invalid code or expired OTP");
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
      appBar: AppBar(
        title: const Text("Verify OTP"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            const Text(
              'Enter OTP',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'We sent a code to +27${widget.user.phoneNumber}',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Pinput(
              length: 6,
              controller: _otpController,
              onCompleted: verifyOTP,
              defaultPinTheme: PinTheme(
                width: 56,
                height: 56,
                textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              focusedPinTheme: PinTheme(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              submittedPinTheme: PinTheme(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              TextButton(
                onPressed: _canResend ? _resendOTP : null,
                child: Text(
                  _canResend ? 'Resend OTP' : 'Resend in $_resendTimer seconds',
                  style: TextStyle(
                    color: _canResend ? Colors.blue : Colors.grey,
                  ),
                ),
              ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : () => verifyOTP(_otpController.text),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Verify'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}