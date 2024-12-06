import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'workout_log_screen.dart';
import 'run_log_screen.dart';
import 'history_page.dart';
import 'login_screen.dart'; // Import the Login Screen

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? userName;

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
        if (doc.exists) {
          setState(() {
            userName = doc['name'];
          });
        } else {
          setState(() {
            userName = "User";
          });
        }
      } catch (e) {
        setState(() {
          userName = "User";
        });
      }
    } else {
      setState(() {
        userName = "User";
      });
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut(); // Log out the user
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()), // Redirect to Login Screen
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Welcome ${userName ?? 'Loading...'}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout, // Call the logout function
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: const Text("Log Workout"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WorkoutLogScreen()),
                );
              },
            ),
            ElevatedButton(
              child: const Text("Log Run"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RunLogScreen()),
                );
              },
            ),
            ElevatedButton(
              child: const Text("View History"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HistoryPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
