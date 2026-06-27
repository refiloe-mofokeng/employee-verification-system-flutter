import 'package:flutter/material.dart';
import 'package:flutter_cc_evs/models/user_model.dart';
import 'package:flutter_cc_evs/services/validation_service.dart';
import 'package:flutter_cc_evs/viewmodels/sign_up_personal_view_model.dart';
import 'package:flutter_cc_evs/widgets/custom_snackbars.dart';
import 'package:provider/provider.dart';

class SignUpPersonalScreen extends StatefulWidget {
  const SignUpPersonalScreen({super.key, UserModel? user});

  @override
  State<SignUpPersonalScreen> createState() => _SignUpPersonalScreenState();
}

class _SignUpPersonalScreenState extends State<SignUpPersonalScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Load any saved personal form data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SignUpPersonalViewModel>().loadSavedFormState();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SignUpPersonalViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Personal Details',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please provide your personal information',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 🧍 First Name
                  TextFormField(
                    controller: viewModel.firstNameController,
                    decoration: const InputDecoration(
                      labelText: 'First Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: ValidationService.validateFirstName,
                    onChanged: (_) => viewModel.onFieldChanged(),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // 🧍 Last Name
                  TextFormField(
                    controller: viewModel.lastNameController,
                    decoration: const InputDecoration(
                      labelText: 'Last Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: ValidationService.validateLastName,
                    onChanged: (_) => viewModel.onFieldChanged(),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // 🪪 SA ID / Passport
                  TextFormField(
                    controller: viewModel.identificationController,
                    decoration: const InputDecoration(
                      labelText: 'SA ID / Passport No',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    validator: ValidationService.validateIdentificationNumber,
                    onChanged: (_) => viewModel.onFieldChanged(),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // 📱 Phone Number
                  TextFormField(
                    controller: viewModel.phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone No',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: ValidationService.validatePhoneNumber,
                    onChanged: (_) => viewModel.onFieldChanged(),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // ✉️ Email
                  TextFormField(
                    controller: viewModel.emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: ValidationService.validateEmail,
                    onChanged: (_) => viewModel.onFieldChanged(),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // 🔒 Password
                  TextFormField(
                    controller: viewModel.passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock_outline),
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
                    validator: ValidationService.validatePassword,
                    onChanged: (_) => viewModel.onFieldChanged(),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // 🔒 Confirm Password
                  TextFormField(
                    controller: viewModel.confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          viewModel.obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: viewModel.toggleConfirmPasswordVisibility,
                      ),
                    ),
                    obscureText: viewModel.obscureConfirmPassword,
                    validator: (value) => ValidationService.validateConfirmPassword(
                      value,
                      viewModel.passwordController.text,
                    ),
                    onChanged: (_) => viewModel.onFieldChanged(),
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 32),

                  // 🚀 Continue Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: viewModel.isLoading
                          ? null
                          : () => _handleContinue(context, viewModel),
                      child: viewModel.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Continue'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🧠 Refined Continue Handler
  Future<void> _handleContinue(
    BuildContext context,
    SignUpPersonalViewModel viewModel,
  ) async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (viewModel.passwordController.text.trim() !=
        viewModel.confirmPasswordController.text.trim()) {
      CustomSnackbar.showError(context, 'Passwords do not match.');
      return;
    }

    viewModel.isLoading = true;

    try {
      // Persist data
      await viewModel.saveFormState();

      // Build user model
      final userModel = viewModel.createUserModel();

      // Navigate to Employee Details screen
      Navigator.pushNamed(
        context,
        '/signUpEmployee',
        arguments: userModel,
      );

      CustomSnackbar.showSuccess(
        context,
        'Personal details saved successfully!',
      );
    } catch (e) {
      CustomSnackbar.showError(context, 'Error: ${e.toString()}');
    } finally {
      viewModel.isLoading = false;
    }
  }
}
