import 'package:flutter/material.dart';
import 'package:flutter_cc_evs/models/user_model.dart';

class DocumentItem extends StatefulWidget {
  final String documentType;
  final String label;
  final DocumentFile? document;
  final VoidCallback onUpload;
  final VoidCallback onReplace;
  final VoidCallback onDelete;
  final bool isLoading;
  final double? uploadProgress;

  const DocumentItem({
    super.key,
    required this.documentType,
    required this.label,
    required this.document,
    required this.onUpload,
    required this.onReplace,
    required this.onDelete,
    this.isLoading = false,
    this.uploadProgress,
  });

  @override
  State<DocumentItem> createState() => _DocumentItemState();
}

class _DocumentItemState extends State<DocumentItem> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _heightAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _heightAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void didUpdateWidget(DocumentItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset expanded state when document changes
    if (oldWidget.document != widget.document) {
      setState(() => _isExpanded = false);
      _animationController.reverse();
    }
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasDocument = widget.document != null;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Document Icon
                _getDocumentIcon(widget.documentType),
                const SizedBox(width: 12),
                
                // Document Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.label,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildStatusText(hasDocument),
                    ],
                  ),
                ),
                
                // Action Button/Expand Arrow
                if (hasDocument) 
                  IconButton(
                    icon: Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.blue,
                    ),
                    onPressed: _toggleExpanded,
                  )
                else
                  _buildUploadButton(),
              ],
            ),
          ),
          
          // Upload Progress Bar
          if (widget.isLoading && widget.uploadProgress != null)
            LinearProgressIndicator(
              value: widget.uploadProgress,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade400),
            ),
          
          // Expanded Document Details
          if (hasDocument) 
            SizeTransition(
              sizeFactor: _heightAnimation,
              child: _buildDocumentDetails(),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusText(bool hasDocument) {
    if (widget.isLoading) {
      return Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: widget.uploadProgress,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Uploading...',
            style: TextStyle(
              color: Colors.blue,
              fontSize: 14,
            ),
          ),
        ],
      );
    }
    
    if (hasDocument) {
      return Text(
        _isExpanded 
            ? 'Uploaded at ${_formatDate(widget.document!.uploadedAt)}'
            : 'Uploaded',
        style: TextStyle(
          color: Colors.green.shade600,
          fontSize: 14,
        ),
      );
    }
    
    return const Text(
      'Not Uploaded yet',
      style: TextStyle(
        color: Colors.orange,
        fontSize: 14,
      ),
    );
  }

  Widget _buildUploadButton() {
    return ElevatedButton(
      onPressed: widget.isLoading ? null : widget.onUpload,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: const Text(
        'Upload',
        style: TextStyle(fontSize: 14),
      ),
    );
  }

  Widget _buildDocumentDetails() {
    final document = widget.document!;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          // Document Icon
          Icon(
            document.isImage ? Icons.image : Icons.description,
            color: Colors.grey.shade600,
            size: 36,
          ),
          const SizedBox(width: 12),
          
          // Document Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.fileName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${document.fileSizeFormatted} • ${_formatDate(document.uploadedAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (document.fileType.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Type: ${document.fileType}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Action Buttons
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: widget.isLoading ? null : widget.onReplace,
                tooltip: 'Replace Document',
                color: Colors.blue,
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 20),
                onPressed: widget.isLoading ? null : widget.onDelete,
                tooltip: 'Delete Document',
                color: Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _getDocumentIcon(String type) {
    final iconData = switch (type) {
      'saIdPassportImage' => Icons.badge,
      'workPermit' => Icons.work,
      'proofOfResidence' => Icons.home,
      'qualificationsCertificates' => Icons.school,
      _ => Icons.description,
    };

    final color = switch (type) {
      'saIdPassportImage' => Colors.blue,
      'workPermit' => Colors.green,
      'proofOfResidence' => Colors.orange,
      'qualificationsCertificates' => Colors.purple,
      _ => Colors.grey,
    };

    return Icon(iconData, color: color, size: 28);
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}