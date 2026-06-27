// import 'package:flutter/material.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// class SecureStorageScreen extends StatefulWidget {
//   const SecureStorageScreen({super.key});

//   @override
//   State<SecureStorageScreen> createState() => _SecureStorageScreenState();
// }

// class _SecureStorageScreenState extends State<SecureStorageScreen> {
//   final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
//   String? _storedEmail;
//   String? _storedPassword;

//   @override
//   void initState() {
//     super.initState();
//     _loadStoredCredentials();
//   }

//   Future<void> _loadStoredCredentials() async {
//     final email = await _secureStorage.read(key: 'email');
//     final password = await _secureStorage.read(key: 'password');
//     debugPrint('Stored email: $email, password: $password');

//     setState(() {
//       _storedEmail = email;
//       _storedPassword = password != null ? '********' : null; // mask password
//     });
//   }
  
//   Future<void> _clearCredentials() async {
//     await _secureStorage.deleteAll();
//     await _loadStoredCredentials();
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Stored credentials cleared')),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Secure Storage')),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             ListTile(
//               leading: const Icon(Icons.email),
//               title: const Text('Stored Email'),
//               subtitle: Text(_storedEmail ?? 'No email stored'),
//             ),
//             ListTile(
//               leading: const Icon(Icons.lock),
//               title: const Text('Stored Password'),
//               subtitle: Text(_storedPassword ?? 'No password stored'),
//             ),
//             const SizedBox(height: 32),
//             ElevatedButton.icon(
//               onPressed: _clearCredentials,
//               icon: const Icon(Icons.delete_forever),
//               label: const Text('Clear Stored Credentials'),
//               style: ElevatedButton.styleFrom(
//                 minimumSize: const Size(double.infinity, 50),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
