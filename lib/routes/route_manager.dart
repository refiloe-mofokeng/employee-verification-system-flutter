import 'package:flutter/material.dart';
import 'package:flutter_cc_evs/models/user_model.dart';
import 'package:flutter_cc_evs/views/auth/sign_in_screen.dart';
import 'package:flutter_cc_evs/views/auth/sign_up_personal_screen.dart';
import 'package:flutter_cc_evs/views/auth/sign_up_employee_screen.dart';
import 'package:flutter_cc_evs/views/auth/sign_up_documents_screen.dart';
import 'package:flutter_cc_evs/views/auth/sign_up_auth_options_screen.dart';
import 'package:flutter_cc_evs/views/auth/otp_verification_screen.dart';
import 'package:flutter_cc_evs/views/home_screen.dart';
import 'package:flutter_cc_evs/views/profile_screen.dart';
import 'package:flutter_cc_evs/views/messages_screen.dart';
import 'package:flutter_cc_evs/views/wrapper/navigation_wrapper.dart';

class RouteManager {
  // Route constants
  static const String signIn = '/signIn';
  static const String signUpPersonal = '/signUpPersonal';
  static const String signUpEmployee = '/signUpEmployee';
  static const String signUpDocuments = '/signUpDocuments';
  static const String signUpAuthOptions = '/signUpAuthOptions';
  static const String otpVerification = '/otpVerification';
  static const String mainWrapper = '/mainWrapper';
  static const String homeScreen = '/home';
  static const String profileScreen = '/profile';
  static const String messagesScreen = '/messages';

  // Route configuration
  static const Map<String, String> routeTitles = {
    signIn: 'Sign In',
    signUpPersonal: 'Personal Details',
    signUpEmployee: 'Employee Details',
    signUpDocuments: 'Upload Documents',
    signUpAuthOptions: 'Authentication Options',
    otpVerification: 'Verify OTP',
    mainWrapper: 'mainWrapper',
    homeScreen: 'Home',
    profileScreen: 'Profile',
    messagesScreen: 'Messages',
  };

  // Public routes (don't require authentication)
  static final publicRoutes = {
    signIn,
    signUpPersonal,
  };

  // Initial route determination
  static String getInitialRoute(bool isLoggedIn) {
    return isLoggedIn ? mainWrapper : signIn;
  }

  // Check if route requires authentication
  static bool requiresAuth(String routeName) {
    return !publicRoutes.contains(routeName);
  }

  // Generate route with enhanced safety
  static Route<dynamic> generateRoute(RouteSettings settings) {
    try {
      switch (settings.name) {
        case signIn:
          return _buildRoute(const SignInScreen(), settings);

        // Sign Up Flow
        case signUpPersonal:
          return _buildRoute(SignUpPersonalScreen(user: _getUserArgument(settings)), settings);

        case signUpEmployee:
          return _buildRoute(
            SignUpEmployeeScreen(user: _getRequiredUserArgument(settings, 'SignUpEmployeeScreen')),
            settings,
          );

        case signUpDocuments:
          return _buildRoute(
            SignUpDocumentsScreen(user: _getRequiredUserArgument(settings, 'SignUpDocumentsScreen')),
            settings,
          );

        case signUpAuthOptions:
          final args = settings.arguments;
          if (args is! Map<String, dynamic>) {
            return _buildErrorRoute('Invalid arguments for auth options');
          }
          
          final user = args['user'] as UserModel?;
          final password = args['password'] as String?;
          
          if (user == null || password == null) {
            return _buildErrorRoute('User data or password missing for auth options');
          }
          
          return MaterialPageRoute(
            builder: (_) => SignUpAuthOptionsScreen(
              user: user,
              password: password, // Pass the password
            ),
          );

        case otpVerification:
          final args = settings.arguments;
          if (args is! Map<String, dynamic>) {
            return _buildErrorRoute('Invalid arguments for OTP verification');
          }
          return _buildRoute(
            OtpVerificationScreen(
              verificationId: args['verificationId'] as String,
              user: args['user'] as UserModel, 
              password: args['password'] as String,
            ),
            settings,
          );

        // Main App Routes
        case mainWrapper:
          return _buildRoute(const NavigationWrapper(), settings);

        case homeScreen:
          return _buildRoute(const HomeScreen(), settings);

        case profileScreen:
          return _buildRoute(const ProfileScreen(), settings);

        case messagesScreen:
          return _buildRoute(const MessagesScreen(), settings);

        default:
          return _buildErrorRoute('Route not found: ${settings.name}');
      }
    } catch (e) {
      return _buildErrorRoute('Error navigating to ${settings.name}: $e');
    }
  }

  // Helper methods for safer route building
  static MaterialPageRoute _buildRoute(Widget screen, RouteSettings settings) {
    return MaterialPageRoute(
      builder: (context) => screen,
      settings: settings,
    );
  }

  static MaterialPageRoute _buildErrorRoute(String message) {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('Navigation Error')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.red),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, signIn),
                  child: const Text('Return to Sign In'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Argument helpers
  static UserModel? _getUserArgument(RouteSettings settings) {
    return settings.arguments is UserModel ? settings.arguments as UserModel : null;
  }

  static UserModel _getRequiredUserArgument(RouteSettings settings, String screenName) {
    if (settings.arguments is! UserModel) {
      throw ArgumentError('UserModel must be provided for $screenName');
    }
    return settings.arguments as UserModel;
  }

  // Navigation helpers
  static Future<T?> navigateTo<T>(BuildContext context, String routeName, {Object? arguments}) {
    return Navigator.pushNamed<T>(context, routeName, arguments: arguments);
  }

  // static Future<T?> navigateReplacement<T>(BuildContext context, String routeName, {Object? arguments}) {
  //   return Navigator.pushReplacementNamed<T>(context, routeName, arguments: arguments);
  // }

  static void popToRoot(BuildContext context) {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  // Get route title
  static String getRouteTitle(String routeName) {
    return routeTitles[routeName] ?? 'Unknown Screen';
  }

  // Check if current route is part of signup flow
  static bool isSignUpRoute(String routeName) {
    final signUpRoutes = {
      signUpPersonal,
      signUpEmployee,
      signUpDocuments,
      signUpAuthOptions,
    };
    return signUpRoutes.contains(routeName);
  }
}