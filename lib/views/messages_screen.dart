import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_cc_evs/widgets/custom_snackbars.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Get user data to check verification status
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final isVerified = userData['isVerified'] ?? false;
        final firstName = userData['firstName'] ?? 'User';
        final lastName = userData['lastName'] ?? '';

        // Create appropriate message based on verification status
        final welcomeMessage = {
          'id': 'welcome_1',
          'title': isVerified ? 'Account Verified' : 'Verification Pending',
          'message': isVerified 
              ? 'Hello $firstName $lastName, you have been verified. Welcome to the system!'
              : 'Hello $firstName $lastName, be patient until verification.',
          'timestamp': DateTime.now(),
          'isRead': false,
          'type': 'system',
        };

        setState(() {
          _messages = [welcomeMessage];
          _isLoading = false;
        });

        // Mark as read after a delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              welcomeMessage['isRead'] = true;
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(context, 'Error loading messages: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading messages...'),
                ],
              ),
            )
          : _messages.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.message, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No messages yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return _buildMessageCard(message);
                  },
                ),
    );
  }

  Widget _buildMessageCard(Map<String, dynamic> message) {
    final isRead = message['isRead'] ?? false;
    final timestamp = message['timestamp'] is Timestamp 
        ? (message['timestamp'] as Timestamp).toDate()
        : message['timestamp'] as DateTime;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      color: isRead ? Colors.white : Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: isRead ? Colors.grey : Colors.blue,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message['title'] ?? 'Message',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: isRead ? Colors.black87 : Colors.blue.shade700,
                    ),
                  ),
                ),
                if (!isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              message['message'] ?? '',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatTimestamp(timestamp),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    
    return '${timestamp.year}/${timestamp.month.toString().padLeft(2, '0')}/${timestamp.day.toString().padLeft(2, '0')}';
  }
}