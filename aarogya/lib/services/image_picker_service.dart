import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

class ImagePickerException implements Exception {
  final String message;
  const ImagePickerException(this.message);

  @override
  String toString() => message;
}

class PickedImageData {
  final String name;
  final Uint8List bytes;
  final int sizeInBytes;
  final String? mimeType;

  const PickedImageData({
    required this.name,
    required this.bytes,
    required this.sizeInBytes,
    this.mimeType,
  });

  String get formattedSize {
    if (sizeInBytes < 1024) {
      return '$sizeInBytes B';
    } else if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
  }
}

class ImagePickerService {
  static const int maxFileSizeBytes = 10 * 1024 * 1024; // 10 MB
  final ImagePicker _picker;

  ImagePickerService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  Future<PickedImageData?> pickFromCamera() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 82,
      );
      return await _processPickedFile(file);
    } on ImagePickerException {
      rethrow;
    } catch (e) {
      throw ImagePickerException('Failed to capture image from camera: ${e.toString()}');
    }
  }

  Future<PickedImageData?> pickFromGallery() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 82,
      );
      return await _processPickedFile(file);
    } on ImagePickerException {
      rethrow;
    } catch (e) {
      throw ImagePickerException('Failed to select image from gallery: ${e.toString()}');
    }
  }

  Future<PickedImageData?> _processPickedFile(XFile? file) async {
    if (file == null) {
      return null; // User cancelled
    }

    final Uint8List bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw const ImagePickerException('The selected image is empty or corrupted.');
    }

    if (bytes.length > maxFileSizeBytes) {
      final double mb = bytes.length / (1024 * 1024);
      throw ImagePickerException(
        'Selected image exceeds the 10 MB limit (${mb.toStringAsFixed(1)} MB). Please select or capture a smaller image.',
      );
    }

    String name = file.name.isNotEmpty
        ? file.name
        : (file.path.isNotEmpty ? file.path.split(RegExp(r'[\\/]')).last : '');

    if (name.isEmpty) {
      final mime = (file.mimeType ?? '').toLowerCase();
      if (mime.contains('png')) {
        name = 'image_${DateTime.now().millisecondsSinceEpoch}.png';
      } else if (mime.contains('webp')) {
        name = 'image_${DateTime.now().millisecondsSinceEpoch}.webp';
      } else if (mime.contains('jpeg') || mime.contains('jpg')) {
        name = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      } else {
        name = 'image_${DateTime.now().millisecondsSinceEpoch}';
      }
    }

    final String lower = name.toLowerCase();
    final bool hasValidExtension = lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp');

    if (!hasValidExtension) {
      throw const ImagePickerException(
        'Unsupported image format. Please select a JPG, JPEG, PNG, or WebP image.',
      );
    }

    return PickedImageData(
      name: name,
      bytes: bytes,
      sizeInBytes: bytes.length,
      mimeType: file.mimeType,
    );
  }
}
