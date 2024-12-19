import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'dart:io';

class WorkoutLogScreen extends StatefulWidget {
  const WorkoutLogScreen({super.key});

  @override
  _WorkoutLogScreenState createState() => _WorkoutLogScreenState();
}

class _WorkoutLogScreenState extends State<WorkoutLogScreen> {
  final List<Map<String, dynamic>> exercises = [];
  String? workoutId;
  String? workoutImagePath;

  final Map<String, List<Map<String, dynamic>>> workoutTemplates = {
    "Push": [
      {"name": "Bench Press", "sets": [{"reps": 10, "weight": 0}]},
      {"name": "Overhead Press", "sets": [{"reps": 8, "weight": 0}]},
      {"name": "Tricep Dips", "sets": [{"reps": 12, "weight": 0}]},
    ],
    "Pull": [
      {"name": "Pull-Ups", "sets": [{"reps": 8, "weight": 0}]},
      {"name": "Barbell Row", "sets": [{"reps": 10, "weight": 0}]},
      {"name": "Bicep Curls", "sets": [{"reps": 12, "weight": 0}]},
    ],
    "Legs": [
      {"name": "Squats", "sets": [{"reps": 10, "weight": 0}]},
      {"name": "Lunges", "sets": [{"reps": 12, "weight": 0}]},
      {"name": "Leg Press", "sets": [{"reps": 10, "weight": 0}]},
    ],
  };

  @override
  void initState() {
    super.initState();
    workoutId = FirebaseFirestore.instance.collection('workouts').doc().id;
  }

  Future<void> captureWorkoutImage() async {
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
      final storageRef =
          FirebaseStorage.instance.ref().child('workouts/$workoutId.jpg');
      await storageRef.putFile(imageFile);
      final imageURL = await storageRef.getDownloadURL();

      setState(() {
        workoutImagePath = imageURL;
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

  Future<void> logWorkout() async {
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
        content:
            const Text("Would you like to click or upload a picture for this workout?"),
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
      await captureWorkoutImage();
    }

    try {
      await FirebaseFirestore.instance.collection('workouts').doc(workoutId).set({
        'exercises': exercises,
        'date': DateTime.now(),
        'userId': userId,
        'image': workoutImagePath,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Workout logged successfully!")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to log workout: $e")),
      );
    }
  }

  void addExercise() {
    setState(() {
      exercises.add({'name': '', 'sets': []});
    });
  }

  void addTemplate(String templateName) {
    setState(() {
      exercises.clear();
      exercises.addAll(workoutTemplates[templateName]!);
    });
  }

  void addSet(int exerciseIndex) {
    setState(() {
      exercises[exerciseIndex]['sets'].add({'reps': 0, 'weight': 0});
    });
  }

  void showTemplateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Choose a Template"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: workoutTemplates.keys.map((templateName) {
            return ListTile(
              title: Text(templateName),
              onTap: () {
                addTemplate(templateName);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Log Workout"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box),
            tooltip: "Choose Template",
            onPressed: showTemplateDialog,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: exercises.length,
                itemBuilder: (context, exerciseIndex) {
                  final exercise = exercises[exerciseIndex];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller:
                                TextEditingController(text: exercise['name']),
                            onChanged: (value) => exercise['name'] = value,
                            decoration: const InputDecoration(
                              labelText: "Exercise Name",
                            ),
                          ),
                          const SizedBox(height: 10),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: exercise['sets'].length,
                            itemBuilder: (context, setIndex) {
                              final set = exercise['sets'][setIndex];
                              return Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly
                                      ],
                                      onChanged: (value) => set['reps'] =
                                          int.tryParse(value) ?? 0,
                                      decoration: const InputDecoration(
                                        labelText: "Reps",
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly
                                      ],
                                      onChanged: (value) => set['weight'] =
                                          int.tryParse(value) ?? 0,
                                      decoration: const InputDecoration(
                                        labelText: "Weight (kg)",
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          TextButton(
                            onPressed: () => addSet(exerciseIndex),
                            child: const Text("Add Set"),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: addExercise,
              child: const Text("Add Exercise"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: logWorkout,
              child: const Text("Log Workout"),
            ),
          ],
        ),
      ),
    );
  }
}
