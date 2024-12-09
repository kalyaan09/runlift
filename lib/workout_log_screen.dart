import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'image_manager.dart';
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
  @override
  void initState() {
    super.initState();
    workoutId = FirebaseFirestore.instance.collection('workouts').doc().id;
  }
  Future<void> captureWorkoutImage() async{
    final imageManager = ImageManager();
    final imageURL = await imageManager.uploadImage('workouts/$workoutId.jpg');
    if (imageURL != null) {
      setState(() {
        workoutImagePath = imageURL;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Image uploaded successfully!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to capture and upload image.")),
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

  void addSet(int exerciseIndex) {
    setState(() {
      exercises[exerciseIndex]['sets'].add({'reps': 0, 'weight': 0.0});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Log Workout")),
      body: SingleChildScrollView(
        child: Padding(
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
                                        onChanged: (value) => set['weight'] =
                                            double.tryParse(value) ?? 0.0,
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
              ElevatedButton.icon(
                icon: const Icon(Icons.camera),
                label: const Text("Click a Picture!"),
                onPressed: () async {
                  if (workoutImagePath == null) {
                    await captureWorkoutImage();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Image already captured!")),
                    );
                  }
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: logWorkout,
                child: const Text("Log Workout"),
              ),
            ],
          ),
        ),
      )
    );
  }
}