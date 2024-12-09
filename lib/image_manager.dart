import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class ImageManager {
  final ImagePicker _picker = ImagePicker();

  Future<String?> uploadImage(String storagePath) async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
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
}
