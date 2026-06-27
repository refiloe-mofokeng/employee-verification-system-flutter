import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class UploadButtonSheet extends StatelessWidget {
  final Function(PlatformFile) onFileSelected;
  final Function(Exception)? onError;
  final double maxFileSizeMB;

  const UploadButtonSheet({
    super.key,
    required this.onFileSelected,
    this.onError,
    this.maxFileSizeMB = 10.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDragHandle(),
            const SizedBox(height: 16),
            Text(
              'Upload Document',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildOptionButton(
              context,
              icon: Icons.folder_open,
              title: 'Choose from Files',
              subtitle: 'Select PDF, DOC, or Image files (max ${maxFileSizeMB}MB)',
              onTap: () => _pickFile(context, FileType.custom),
            ),
            const SizedBox(height: 12),
            _buildOptionButton(
              context,
              icon: Icons.photo_library,
              title: 'Choose from Gallery',
              subtitle: 'Select images from your gallery (max ${maxFileSizeMB}MB)',
              onTap: () => _pickFile(context, FileType.image),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildOptionButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Future<void> _pickFile(BuildContext context, FileType fileType) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: fileType,
        allowedExtensions: fileType == FileType.custom 
            ? ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx']
            : null,
        allowMultiple: false,
      );

      if (!context.mounted) return;

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        // Validate file size
        if (file.size > maxFileSizeMB * 1024 * 1024) {
          _showError(context, 'File size must be less than ${maxFileSizeMB}MB');
          return;
        }

        // Validate file has path
        if (file.path == null) {
          _showError(context, 'Unable to access file');
          return;
        }

        Navigator.pop(context);
        onFileSelected(file);
      }
    } catch (e) {
      _handleError(context, e);
    }
  }

  void _showError(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  void _handleError(BuildContext context, dynamic error) {
    final exception = error is Exception ? error : Exception(error.toString());
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${exception.toString()}')),
      );
    }
    onError?.call(exception);
  }
}