import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_cc_evs/views/messages_screen.dart';
import 'package:flutter_cc_evs/widgets/custom_snackbars.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // Welcome User Section
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Text(
                    'Welcome User',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  );
                }

                final userData = snapshot.data!.data() as Map<String, dynamic>;
                final firstName = userData['firstName'] ?? '';
                final lastName = userData['lastName'] ?? '';
                final isVerified = userData['isVerified'] ?? false;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome $firstName $lastName',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Verification Status
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isVerified ? Colors.green.shade50 : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isVerified ? Colors.green.shade200 : Colors.orange.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isVerified ? Icons.verified : Icons.pending,
                            color: isVerified ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isVerified ? 'Verified' : 'Not yet Verified',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isVerified ? Colors.green : Colors.orange,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isVerified 
                                      ? 'Your account has been verified successfully'
                                      : 'Your verification is pending approval',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
            // Messages Tile
            Card(
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.message, color: Colors.blue),
                title: const Text(
                  'Messages',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Check your verification status updates'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context, 
                    MaterialPageRoute(
                      builder: (context) => const MessagesScreen(),
                    ),
                  );
                },
              ),
            ),
            const Spacer(),
            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildActionCard(
                  icon: Icons.person,
                  title: 'Profile',
                  onTap: () {
                    // Navigate to profile
                    DefaultTabController.of(context).animateTo(1);
                  },
                ),
                _buildActionCard(
                  icon: Icons.upload_file,
                  title: 'Upload Docs',
                  onTap: () {
                    CustomSnackbar.showInfo(context, 'Document upload feature coming soon');
                  },
                ),
                _buildActionCard(
                  icon: Icons.help,
                  title: 'Support',
                  onTap: () {
                    CustomSnackbar.showInfo(context, 'Support feature coming soon');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade100),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.blue, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}