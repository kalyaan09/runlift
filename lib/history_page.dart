import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  Future<List<Map<String, dynamic>>> _fetchHistory() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return [];
    }

    try {
      final workoutSnapshot = await FirebaseFirestore.instance
          .collection('workouts')
          .where('userId', isEqualTo: userId)
          .get();

      final runSnapshot = await FirebaseFirestore.instance
          .collection('runs')
          .where('userId', isEqualTo: userId)
          .get();

      final history = [
        ...workoutSnapshot.docs.map((doc) => {
              'type': 'Workout',
              ...doc.data(),
              'id': doc.id,
            }),
        ...runSnapshot.docs.map((doc) => {
              'type': 'Run',
              ...doc.data(),
              'id': doc.id, // Include run ID
            }),
      ];

      history.sort((a, b) => (b['date'] as Timestamp).compareTo(a['date'] as Timestamp));

      return history;
    } catch (e) {
      print("Error fetching history: $e");
      return [];
    }
  }

  Future<void> _uploadImage(
      BuildContext context, String collection, String docId) async {
    try {
      // Show dialog for selecting image source
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

      if (imageSource == null) return; // User canceled dialog

      // Pick image
      final XFile? photo = await ImagePicker().pickImage(source: imageSource);
      if (photo == null) return;

      final File imageFile = File(photo.path);
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('$collection/$docId.jpg');
      await storageRef.putFile(imageFile);
      final imageUrl = await storageRef.getDownloadURL();

      // Update Firestore with the new image URL
      await FirebaseFirestore.instance
          .collection(collection)
          .doc(docId)
          .update({'image': imageUrl});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Image uploaded successfully!")),
      );
    } catch (e) {
      print('Error uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to upload image.")),
      );
    }
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return DateFormat('MM/dd/yy hh:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("History")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No history available."));
          }

          final history = snapshot.data!;

          return ListView.builder(
            itemCount: history.length,
            itemBuilder: (context, index) {
              final entry = history[index];

              if (entry['type'] == 'Workout') {
                final imageUrl = entry['image'];

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Workout on: ${_formatDate(entry['date'])}"),
                              if (entry['exercises'] != null &&
                                  entry['exercises'] is List)
                                for (var exercise in entry['exercises'])
                                  Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            "Exercise: ${exercise['name'] ?? 'Unknown'}"),
                                        if (exercise['sets'] != null &&
                                            exercise['sets'] is List)
                                          for (var set in exercise['sets'])
                                            Row(
                                              children: [
                                                Text(
                                                    "Reps: ${set['reps'] ?? 'N/A'}"),
                                                const SizedBox(width: 10),
                                                Text(
                                                    "Weight: ${set['weight'] ?? 'N/A'} kg"),
                                              ],
                                            ),
                                      ],
                                    ),
                                  )
                              else
                                const Text("No exercises recorded."),
                            ],
                          ),
                        ),
                        if (imageUrl != null)
                          GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => Dialog(
                                  child: Image.network(imageUrl),
                                ),
                              );
                            },
                            child: Image.network(
                              imageUrl,
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                            ),
                          )
                        else
                          ElevatedButton.icon(
                            onPressed: () async {
                              await _uploadImage(
                                  context, 'workouts', entry['id']);
                            },
                            icon: const Icon(Icons.upload),
                            label: const Text("Upload"),
                          ),
                      ],
                    ),
                  ),
                );
              } else if (entry['type'] == 'Run') {
                final imageUrl = entry['image'];

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Run: ${entry['distance'] ?? 'Unknown'} km"),
                              Text("Time: ${entry['time'] ?? 'N/A'}"),
                              Text(_formatDate(entry['date'])),
                            ],
                          ),
                        ),
                        if (imageUrl != null)
                          GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => Dialog(
                                  child: Image.network(imageUrl),
                                ),
                              );
                            },
                            child: Image.network(
                              imageUrl,
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                            ),
                          )
                        else
                          ElevatedButton.icon(
                            onPressed: () async {
                              await _uploadImage(context, 'runs', entry['id']);
                            },
                            icon: const Icon(Icons.upload),
                            label: const Text("Upload"),
                          ),
                      ],
                    ),
                  ),
                );
              } else {
                return const SizedBox.shrink();
              }
            },
          );
        },
      ),
    );
  }
}
