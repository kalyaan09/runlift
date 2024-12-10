import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class ImageManager {
  final ImagePicker _picker = ImagePicker();

  /// Show a dialog to choose between camera and gallery
  Future<String?> pickImageAndUpload(BuildContext context, String storagePath) async {
    final selectedOption = await _showImageSourceDialog(context);

    if (selectedOption == null) return null; // If user cancels the dialog

    try {
      final XFile? photo = await _picker.pickImage(
        source: selectedOption == ImageSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
      );

      if (photo == null) return null;

      final File imageFile = File(photo.path);
      final storageRef = FirebaseStorage.instance.ref().child(storagePath);
      await storageRef.putFile(imageFile);
      final imageUrl = await storageRef.getDownloadURL();

      return imageUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  /// Display a dialog to choose the image source
  Future<ImageSource?> _showImageSourceDialog(BuildContext context) async {
    return showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
  }
}
