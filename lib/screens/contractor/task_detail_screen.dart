import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../providers/contractor_provider.dart';
import '../../models/task_model.dart';
import '../../utils/theme.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final _commentController = TextEditingController();
  final _progressController = TextEditingController();
  File? _selectedImage;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _submitUpdate() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a comment'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final contractorProvider = Provider.of<ContractorProvider>(context, listen: false);

    String? imageUrl;
    if (_selectedImage != null) {
      imageUrl = await contractorProvider.uploadImage(_selectedImage!.path);
    }

    double? progressUpdate;
    if (_progressController.text.isNotEmpty) {
      progressUpdate = double.tryParse(_progressController.text);
      if (progressUpdate != null && (progressUpdate < 0 || progressUpdate > 100)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Progress must be between 0 and 100'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        setState(() {
          _isSubmitting = false;
        });
        return;
      }
    }

    final success = await contractorProvider.uploadTaskUpdate(
      taskId: widget.task.id,
      userId: authProvider.currentUser!.id,
      comment: _commentController.text.trim(),
      imageUrl: imageUrl,
      progressUpdate: progressUpdate,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Update submitted successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(contractorProvider.errorMessage ?? 'Update failed'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }

    setState(() {
      _isSubmitting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _getStatusColor(widget.task.status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getStatusIcon(widget.task.status),
                            color: _getStatusColor(widget.task.status),
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.task.title,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getStatusLabel(widget.task.status),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _getStatusColor(widget.task.status),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.task.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: AppTheme.textSecondaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Start: ${_formatDate(widget.task.startDate)}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                    if (widget.task.endDate != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.event,
                              size: 16,
                              color: AppTheme.textSecondaryColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'End: ${_formatDate(widget.task.endDate!)}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    const Text(
                      'Progress',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: widget.task.completionPercentage / 100,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getStatusColor(widget.task.status),
                            ),
                            minHeight: 10,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${widget.task.completionPercentage.toInt()}%',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(widget.task.status),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Update Form
            const Text(
              'Submit Daily Update',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _commentController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Comment / Update',
                        hintText: 'Describe your progress...',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _progressController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Update Progress (%)',
                        hintText: 'Enter 0-100',
                        prefixIcon: Icon(Icons.percent),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Upload Photo Proof',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_selectedImage != null)
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _selectedImage!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                setState(() {
                                  _selectedImage = null;
                                });
                              },
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Take Photo'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submitUpdate,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(Icons.send),
                        label: Text(_isSubmitting ? 'Submitting...' : 'Submit Update'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return AppTheme.successColor;
      case 'in_progress':
        return AppTheme.primaryColor;
      default:
        return AppTheme.warningColor;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'in_progress':
        return Icons.pending;
      default:
        return Icons.radio_button_unchecked;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'completed':
        return 'Completed';
      case 'in_progress':
        return 'In Progress';
      default:
        return 'Pending';
    }
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
