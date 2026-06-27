// screens/sign_in_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_cc_evs/viewmodels/sign_in_viewmodel.dart';
import 'package:flutter_cc_evs/widgets/custom_snackbars.dart';
import 'package:provider/provider.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SignInViewModel(),
      child: Scaffold(
        appBar: null, // No app bar as requested
        body: const SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(
              child: SingleChildScrollView(
                child: SignInForm(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SignInForm extends StatelessWidget {
  const SignInForm({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<SignInViewModel>(context);
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title
        const Text(
          'Sign In',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        
        // Username/Email Field
        TextFormField(
          controller: viewModel.usernameController,
          decoration: const InputDecoration(
            labelText: 'Username or Email',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        
        // Password Field
        TextFormField(
          controller: viewModel.passwordController,
          decoration: InputDecoration(
            labelText: 'Password',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.lock),
            suffixIcon: IconButton(
              icon: Icon(
                viewModel.obscurePassword 
                    ? Icons.visibility_off 
                    : Icons.visibility,
              ),
              onPressed: viewModel.togglePasswordVisibility,
            ),
          ),
          obscureText: viewModel.obscurePassword,
        ),
        const SizedBox(height: 16),
        
        // Remember Me & Forgot Password Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Remember Me
            Row(
              children: [
                Checkbox(
                  value: viewModel.rememberMe,
                  onChanged: (value) => viewModel.toggleRememberMe(),
                ),
                const Text('Remember Me'),
              ],
            ),
            
            // Forgot Password
            TextButton(
              onPressed: () => _handleForgotPassword(context, viewModel),
              child: const Text('Forgot Password?'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Sign In Button
        ElevatedButton(
          onPressed: viewModel.isLoading 
              ? null 
              : () => _handleSignIn(context, viewModel),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: viewModel.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Login',
                  style: TextStyle(fontSize: 16),
                ),
        ),
        const SizedBox(height: 24),
        
        // Sign Up Link
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Don't have an Account?"),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/signUpPersonal');
              },
              child: const Text('Sign Up'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _handleSignIn(
      BuildContext context, 
      SignInViewModel viewModel
  ) async {
    try {
      final user = await viewModel.signIn();
      if (user != null) {
        // Navigate to home screen or main app
        CustomSnackbar.showSuccess(context, 'Successfully signed in!');
        Navigator.pushReplacementNamed(context, '/mainWrapper');
      }
    } catch (e) {
      CustomSnackbar.showError(context, e.toString());
    }
  }

  Future<void> _handleForgotPassword(
      BuildContext context, 
      SignInViewModel viewModel
  ) async {
    try {
      await viewModel.forgotPassword();
      CustomSnackbar.showSuccess(
        context, 
        'Password reset email sent! Check your inbox.',
      );
    } catch (e) {
      CustomSnackbar.showError(context, e.toString());
    }
  }
}