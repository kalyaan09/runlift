import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:async';

class RunLogScreen extends StatefulWidget {
  const RunLogScreen({super.key});

  @override
  _RunLogScreenState createState() => _RunLogScreenState();
}

class _RunLogScreenState extends State<RunLogScreen> {
  final TextEditingController distanceController = TextEditingController();
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _isRunning = false;
  String? runId;
  String? runImagePath;

  @override
  void initState() {
    super.initState();
    runId = FirebaseFirestore.instance.collection('runs').doc().id;
  }

  String get _formattedTime {
    final hours = _elapsedSeconds ~/ 3600;
    final minutes = (_elapsedSeconds % 3600) ~/ 60;
    final seconds = _elapsedSeconds % 60;
    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  void _startTimer() {
    if (_isRunning) return;
    setState(() {
      _isRunning = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  void _pauseTimer() {
    if (!_isRunning) return;
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
    _showSaveRunDialog();
  }

  Future<void> captureRunImage() async {
    final imageSource = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Choose Image Source"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Camera"),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Gallery"),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (imageSource == null) return;

    try {
      final XFile? photo = await ImagePicker().pickImage(source: imageSource);
      if (photo == null) return;

      final File imageFile = File(photo.path);
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('runs/$runId.jpg');
      await storageRef.putFile(imageFile);
      final imageURL = await storageRef.getDownloadURL();

      setState(() {
        runImagePath = imageURL;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Image uploaded successfully!")),
      );
    } catch (e) {
      print("Error uploading image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to upload image.")),
      );
    }
  }

  Future<void> _logRun() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not logged in!")),
      );
      return;
    }

    final shouldUploadImage = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add a Picture?"),
        content: const Text("Would you like to click or upload a picture for this run?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("No"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Yes"),
          ),
        ],
      ),
    );

    if (shouldUploadImage == true) {
      await captureRunImage();
    }

    try {
      await FirebaseFirestore.instance.collection('runs').doc(runId).set({
        'distance': double.tryParse(distanceController.text) ?? 0.0,
        'time': _formattedTime,
        'date': DateTime.now(),
        'userId': userId,
        'image': runImagePath,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Run logged successfully!")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to log run: $e")),
      );
    }
  }

  void _showSaveRunDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Save Run"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: distanceController,
              decoration: const InputDecoration(labelText: "Distance (km)"),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),
            const SizedBox(height: 10),
            Text("Time: $_formattedTime"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _logRun();
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Log Run")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "Elapsed Time: $_formattedTime",
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: distanceController,
              decoration: const InputDecoration(labelText: "Distance (km)"),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _startTimer,
                  child: const Text("Start"),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _pauseTimer,
                  child: const Text("Pause"),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _stopTimer,
                  child: const Text("Stop"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}