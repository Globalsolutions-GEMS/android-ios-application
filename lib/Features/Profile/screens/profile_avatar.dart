import 'dart:convert';
import 'dart:io';

import 'package:erp_app/api_manager/api_client.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Profile photo (base64) or the first letter of the name.
/// With [showUploadButton] it also shows Upload / Remove actions.
class ProfileAvatar extends StatefulWidget {
  const ProfileAvatar({
    super.key,
    required this.name,
    this.photoBase64,
    this.radius = 44,
    this.onImageUpdated,
    this.onRemove,
    this.showUploadButton = true,
  });

  final String name;
  final String? photoBase64;
  final double radius;
  final Function(String)? onImageUpdated;
  final VoidCallback? onRemove;
  final bool showUploadButton;

  static const Color _primary = Color(0xFF6D4AFF);

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  static const Color _primary = ProfileAvatar._primary;

  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isUploading = false;
  String? _currentPhotoBase64;

  @override
  void initState() {
    super.initState();
    _currentPhotoBase64 = widget.photoBase64;
  }

  @override
  void didUpdateWidget(covariant ProfileAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photoBase64 != widget.photoBase64) {
      _currentPhotoBase64 = widget.photoBase64;
    }
  }

  bool get _hasPhoto =>
      _currentPhotoBase64 != null && _currentPhotoBase64!.isNotEmpty;

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() => _selectedImage = File(image.path));
      }
    } catch (e) {
      _snack('Failed to pick image: $e');
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;
    setState(() => _isUploading = true);

    try {
      final response = await ApiClient().uploadProfileImage(_selectedImage!);

      if (response.statusCode == 200) {
        final bytes = await _selectedImage!.readAsBytes();
        final base64String = base64Encode(bytes);

        if (!mounted) return;
        setState(() {
          _currentPhotoBase64 = base64String;
          _selectedImage = null;
        });
        widget.onImageUpdated?.call(base64String);
        _snack('Profile photo updated');
      } else {
        _snack('Upload failed: ${response.statusText}');
      }
    } catch (e) {
      _snack('Upload failed: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _cancelUpload() => setState(() => _selectedImage = null);

  ImageProvider? _photo() {
    if (_selectedImage != null) return FileImage(_selectedImage!);
    if (_hasPhoto) {
      try {
        return MemoryImage(base64Decode(_currentPhotoBase64!));
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  ButtonStyle _outlined(Color color) => OutlinedButton.styleFrom(
    foregroundColor: color,
    side: BorderSide(color: color),
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  );

  @override
  Widget build(BuildContext context) {
    final photo = _photo();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar with ring and a tick when a new image is selected
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _primary.withOpacity(0.25), width: 3),
          ),
          child: Stack(
            children: [
              CircleAvatar(
                radius: widget.radius,
                backgroundColor: _primary.withOpacity(0.12),
                backgroundImage: photo,
                child: photo == null
                    ? Text(
                        widget.name.isEmpty
                            ? '?'
                            : widget.name[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: widget.radius * 0.75,
                          fontWeight: FontWeight.w700,
                          color: _primary,
                        ),
                      )
                    : null,
              ),
              if (_selectedImage != null)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 16),
                  ),
                ),
            ],
          ),
        ),
        if (widget.showUploadButton) ...[
          const SizedBox(height: 14),
          if (_selectedImage != null)
            Wrap(
              spacing: 12,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _isUploading ? null : _uploadImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isUploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Upload'),
                ),
                OutlinedButton(
                  onPressed: _isUploading ? null : _cancelUpload,
                  style: _outlined(const Color(0xFF64748B)),
                  child: const Text('Cancel'),
                ),
              ],
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: const Text('Upload'),
                  style: _outlined(_primary),
                ),
                if (_hasPhoto && widget.onRemove != null)
                  OutlinedButton.icon(
                    onPressed: widget.onRemove,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Remove'),
                    style: _outlined(Colors.red),
                  ),
              ],
            ),
        ],
      ],
    );
  }
}
