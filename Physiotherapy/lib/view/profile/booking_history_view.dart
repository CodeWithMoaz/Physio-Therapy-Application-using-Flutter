import 'package:flutter/material.dart';
import 'package:physiotherapy/common/color_extension.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:physiotherapy/models/user_model.dart';
import 'package:physiotherapy/models/program_model.dart';
import 'package:physiotherapy/services/auth_service.dart';
import 'package:physiotherapy/view/rehabilitation/way_of_rehab.dart';

class BookingHistoryView extends StatefulWidget {
  const BookingHistoryView({super.key});

  @override
  _BookingHistoryViewState createState() => _BookingHistoryViewState();
}

class _BookingHistoryViewState extends State<BookingHistoryView> {
  List<Map<String, dynamic>> enrolledPrograms = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEnrolledPrograms();
  }

  Future<void> _loadEnrolledPrograms() async {
    try {
      final user = AuthService().currentUser;
      if (user != null) {
        final userQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: user.email)
            .get();

        if (userQuery.docs.isNotEmpty) {
          final userData = userQuery.docs.first.data();
          final userEnrolledPrograms =
              userData['enrolledPrograms'] as Map<String, dynamic>? ?? {};

          List<Map<String, dynamic>> plans = [];

          for (String programId in userEnrolledPrograms.keys) {
            final programDoc = await FirebaseFirestore.instance
                .collection('programs')
                .doc(programId)
                .get();

            if (programDoc.exists) {
              final programData = programDoc.data()!;
              final enrolledData =
                  userEnrolledPrograms[programId] as Map<String, dynamic>? ??
                      {};

              final lastCompletedDay = enrolledData['lastCompletedDay'] ?? 0;
              final totalDays = 30;
              final progress = lastCompletedDay / totalDays;

              plans.add({
                "title": programData['programName'] ?? 'Unknown Program',
                "duration": programData['duration'] ?? '4 weeks',
                "difficulty": programData['severity'] ?? 'Moderate',
                "image": _getProgramImage(programData['injury']),
                "progress": progress,
                "programId": programId,
                "injury": programData['injury'] ?? 'Unknown Injury',
                "description":
                    programData['description'] ?? 'No description available',
                "enrolledAt": enrolledData['enrolledAt'],
                "lastVisit": enrolledData['lastVisit'],
                "lastCompletedDay": lastCompletedDay,
              });
            }
          }

          setState(() {
            enrolledPrograms = plans;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading enrolled programs: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  String _getProgramImage(String injury) {
    switch (injury.toLowerCase()) {
      case 'knee':
        return "assets/img/knee.png";
      case 'shoulder':
        return "assets/img/shoulder.png";
      case 'back':
        return "assets/img/back.png";
      case 'ankle':
        return "assets/img/ankle.png";
      default:
        return "assets/img/knee.png";
    }
  }

  Widget _buildProgressIndicator(double progress) {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                TColor.primaryColor1,
                TColor.primaryColor2,
              ],
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildProgramCard(Map<String, dynamic> program) {
    final progress = program['progress'].clamp(0.0, 1.0);
    final progressPercentage = (progress * 100).toStringAsFixed(1);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 3,
      child: Column(
        children: [
          Container(
            height: 150,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
              image: DecorationImage(
                image: AssetImage(program['image']),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    program['title'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${program['injury']} - ${program['difficulty']}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Started on ${program['enrolledAt'] != null ? (program['enrolledAt'] as Timestamp).toDate().toString().split(' ')[0] : 'Unknown date'}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: TColor.primaryColor1,
                      ),
                    ),
                    Text(
                      '$progressPercentage%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: TColor.primaryColor1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildProgressIndicator(progress),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoChip(
                      Icons.fitness_center,
                      'Day ${program['lastCompletedDay']} of 30',
                    ),
                    _buildInfoChip(
                      Icons.calendar_today,
                      program['duration'],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  program['description'],
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColor.primaryColor1,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Continue Program'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: TColor.primaryColor1.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: TColor.primaryColor1),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: TColor.primaryColor1,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColor.white,
      appBar: AppBar(
        backgroundColor: TColor.primaryColor1,
        elevation: 0,
        title: const Text(
          "Enrolled Programs",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : enrolledPrograms.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.fitness_center_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No Programs Enrolled",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Enroll in a program to start your rehabilitation journey",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const RehabilitationWayView(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TColor.primaryColor1,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text("Browse Programs"),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: enrolledPrograms.length,
                  itemBuilder: (context, index) {
                    return _buildProgramCard(enrolledPrograms[index]);
                  },
                ),
    );
  }
}
