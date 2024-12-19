import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'workout_log_screen.dart';
import 'run_log_screen.dart';
import 'history_page.dart';
import 'login_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? userName;
  int totalWorkouts = 0;
  int totalRuns = 0;
  Map<DateTime, int> activityCounts = {};
  final List<String> motivationalQuotes = [
    "The difference between try and triumph is just a little umph!",
    "Push yourself because no one else is going to do it for you.",
    "Fitness is not about being better than someone else; it's about being better than you used to be.",
    "Strive for progress, not perfection.",
  ];
  late String quoteOfTheDay;

  @override
  void initState() {
    super.initState();
    _fetchUserName();
    _listenToDashboardStats();
    _listenToActivityCounts();
    _selectQuoteOfTheDay();
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

  void _listenToDashboardStats() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      FirebaseFirestore.instance
          .collection('workouts')
          .where('userId', isEqualTo: userId)
          .snapshots()
          .listen((workoutSnapshot) {
        FirebaseFirestore.instance
            .collection('runs')
            .where('userId', isEqualTo: userId)
            .snapshots()
            .listen((runSnapshot) {
          setState(() {
            totalWorkouts = workoutSnapshot.docs.length;
            totalRuns = runSnapshot.docs.length;
          });
        });
      });
    }
  }

  void _listenToActivityCounts() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final counts = <DateTime, int>{};

      FirebaseFirestore.instance
          .collection('workouts')
          .where('userId', isEqualTo: userId)
          .snapshots()
          .listen((workoutSnapshot) {
        counts.clear();
        workoutSnapshot.docs.forEach((doc) {
          final date = (doc['date'] as Timestamp).toDate();
          final key = DateTime(date.year, date.month, date.day);
          counts[key] = (counts[key] ?? 0) + 1;
        });

        FirebaseFirestore.instance
            .collection('runs')
            .where('userId', isEqualTo: userId)
            .snapshots()
            .listen((runSnapshot) {
          runSnapshot.docs.forEach((doc) {
            final date = (doc['date'] as Timestamp).toDate();
            final key = DateTime(date.year, date.month, date.day);
            counts[key] = (counts[key] ?? 0) + 1;
          });

          setState(() {
            activityCounts = Map<DateTime, int>.from(counts);
          });
        });
      });
    }
  }

  void _selectQuoteOfTheDay() {
    setState(() {
      quoteOfTheDay = (motivationalQuotes..shuffle()).first;
    });
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("RunLift"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              "Welcome, ${userName ?? 'Loading...'}",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Card(
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      "Dashboard Overview",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text("Workouts", style: TextStyle(fontWeight: FontWeight.bold)),
                            Text("$totalWorkouts"),
                          ],
                        ),
                        Column(
                          children: [
                            Text("Runs", style: TextStyle(fontWeight: FontWeight.bold)),
                            Text("$totalRuns"),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Your Activity",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            HeatMap(
              datasets: activityCounts,
              startDate: DateTime.now().subtract(const Duration(days: 365)),
              endDate: DateTime.now(),
              colorMode: ColorMode.opacity,
              showText: false,
              scrollable: true,
              colorsets: const {
                1: Colors.green,
                3: Colors.greenAccent,
                5: Colors.blue,
                10: Colors.deepPurple,
              },
            ),
            const SizedBox(height: 20),
            Card(
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  '"$quoteOfTheDay"',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WorkoutLogScreen()),
                );
              },
              child: const Text("Log Workout"),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RunLogScreen()),
                );
              },
              child: const Text("Log Run"),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HistoryPage()),
                );
              },
              child: const Text("View History"),
            ),
          ],
        ),
      ),
    );
  }
}