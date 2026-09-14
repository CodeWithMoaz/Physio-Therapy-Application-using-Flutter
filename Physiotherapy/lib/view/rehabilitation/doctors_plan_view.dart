import 'package:flutter/material.dart';
import 'package:physiotherapy/common/color_extension.dart';
import 'package:physiotherapy/view/rehabilitation/rehabilitation_workout.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;

class RehabPlanDetailsPage extends StatefulWidget {
  final Map<String, dynamic> plan;
  const RehabPlanDetailsPage({super.key, required this.plan});

  @override
  _RehabPlanDetailsPageState createState() => _RehabPlanDetailsPageState();
}

class _RehabPlanDetailsPageState extends State<RehabPlanDetailsPage>
    with SingleTickerProviderStateMixin {
  bool _isEnrolled = false;
  bool showExercises = false;
  bool showExerciseList = false;
  int selectedDay = 1;
  int selectedWeek = 1;
  bool isLoading = true;
  double _progressPercentage = 0.0;
  DateTime? _enrolledAt;
  int _lastCompletedDay = 0;

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkEnrollmentStatus();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkEnrollmentStatus() async {
    setState(() {
      isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          isLoading = false;
        });
        return; // Not logged in, cannot be enrolled
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final enrolledPrograms =
          userDoc.data()?['enrolledPrograms'] as Map<String, dynamic>? ?? {};
      final programId = widget.plan['id'];

      if (enrolledPrograms.containsKey(programId)) {
        // User is enrolled
        final enrollmentData = enrolledPrograms[programId];
        _enrolledAt = (enrollmentData?['enrolledAt'] as Timestamp?)?.toDate();
        _lastCompletedDay = enrollmentData?['lastCompletedDay'] ?? 0;
        _isEnrolled = true;
        _calculateProgress(); // Calculate initial progress
        // Default selected day to the next day to complete
        selectedDay = _lastCompletedDay + 1;
        if (selectedDay >
            (parseDuration(widget.plan["duration"] ?? '0 Weeks') * 7)) {
          selectedDay = (parseDuration(widget.plan["duration"] ?? '0 Weeks') *
              7); // Don't exceed total days
        } else if (selectedDay == 0) {
          // Should not happen if initialized to 0, but safety check
          selectedDay = 1;
        }

        // Calculate selectedWeek based on selectedDay
        selectedWeek = ((selectedDay - 1) ~/ 7) + 1;
      } else {
        // User is not enrolled
        _isEnrolled = false;
      }
    } catch (e) {
      print('Error checking enrollment status: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _calculateProgress() {
    if (_enrolledAt == null) {
      _progressPercentage = 0.0;
      return;
    }

    // Assuming duration is in weeks, like "6 Weeks"
    final durationString = widget.plan["duration"] ?? '0 Weeks';
    final totalWeeks = parseDuration(durationString);
    final totalDays = totalWeeks * 7; // Simple conversion

    if (totalDays <= 0) {
      _progressPercentage = 0.0;
      return;
    }

    _progressPercentage = math.min(1.0, _lastCompletedDay / totalDays);

    // We might need more sophisticated progress tracking (e.g., tracking completed exercises/days) later.
    // For now, this gives a basic progress based on time passed since enrollment.
  }

  // Function to parse duration and get total weeks
  int parseDuration(String duration) {
    if (duration.contains("Week")) {
      return int.parse(duration.split(" ")[0]);
    } else if (duration.contains("Month")) {
      int months = int.parse(duration.split(" ")[0]);
      return months * 4; // Assuming 4 weeks per month
    } else if (duration.contains("Day")) {
      int days = int.parse(duration.split(" ")[0]);
      return (days / 7).ceil(); // Convert days to weeks
    }
    return 1; // Default to 1 week if no valid duration is found
  }

  Future<void> enrollInProgram() async {
    setState(() {
      isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to enroll in a program')),
        );
        return;
      }

      final programId = widget.plan['id'];

      // Check if user is already enrolled (double check to avoid race conditions)
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final enrolledPrograms =
          userDoc.data()?['enrolledPrograms'] as Map<String, dynamic>? ?? {};

      if (enrolledPrograms.containsKey(programId)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('You are already enrolled in this program')),
        );
        setState(() {
          isLoading = false;
          _isEnrolled = true; // Update state if already enrolled
          _enrolledAt =
              (enrolledPrograms[programId]['enrolledAt'] as Timestamp?)
                  ?.toDate();
          _lastCompletedDay =
              enrolledPrograms[programId]['lastCompletedDay'] ?? 0;
          _calculateProgress();
          selectedDay = _lastCompletedDay + 1;
          if (selectedDay >
              (parseDuration(widget.plan["duration"] ?? '0 Weeks') * 7)) {
            selectedDay = (parseDuration(widget.plan["duration"] ?? '0 Weeks') *
                7); // Don't exceed total days
          } else if (selectedDay == 0) {
            selectedDay = 1;
          }

          // Calculate selectedWeek based on selectedDay
          selectedWeek = ((selectedDay - 1) ~/ 7) + 1;
        });
        return;
      }

      // Calculate total days in the program
      final durationString = widget.plan["duration"] ?? '0 Weeks';
      final totalWeeks = parseDuration(durationString);
      final totalDays = totalWeeks * 7;
      // Create plan map with keys for each day (e.g., w1d1, w1d2, ...)
      final Map<String, List<String>> planMap = {};
      for (int week = 1; week <= totalWeeks; week++) {
        for (int day = 1; day <= 7; day++) {
          int absoluteDay = (week - 1) * 7 + day;
          if (absoluteDay > totalDays) break;
          planMap['w${week}d${day}'] = <String>[];
        }
      }
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'enrolledPrograms.$programId': {
          'enrolledAt': FieldValue.serverTimestamp(),
          'progress': 0.0,
          'lastVisit': DateTime.now()
              .toString()
              .split(' ')[0], // Or a meaningful initial date
          'lastCompletedDay': 0, // Initialize last completed day to 0
          'plan': planMap, // Add plan map with all days as empty arrays
        }
      });

      // Update program's enrolled patients count
      await FirebaseFirestore.instance
          .collection('programs')
          .doc(programId)
          .update({'enrolledPatients': FieldValue.increment(1)});

      setState(() {
        _isEnrolled = true;
        _enrolledAt =
            DateTime.now(); // Set enrollment time for progress calculation
        _calculateProgress();
        _lastCompletedDay = 0; // Newly enrolled, 0 days completed
        selectedDay = 1; // Start at day 1
        selectedWeek = 1; // Start at week 1
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Successfully enrolled in ${widget.plan["doctor"]}\'s program'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error enrolling in program: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error enrolling in program: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void showPaymentDialog() {
    // This dialog now acts as a confirmation before actual enrollment.
    // A real payment integration would replace this.
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            "Confirm Enrollment",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: TColor.primaryColor1,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Program Details:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 10),
              Text("Doctor: ${widget.plan["doctor"]}"),
              Text("Duration: ${widget.plan["duration"]}"),
              Text("Price: \$${widget.plan["price"]}"),
              SizedBox(height: 20),
              Text(
                "By confirming, you agree to enroll and pay for this program.", // Adjusted text for clarity
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                "Cancel",
                style: TextStyle(color: TColor.gray),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                enrollInProgram(); // Proceed with enrollment
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: TColor.primaryColor1,
                foregroundColor: TColor.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: Text("Confirm and Enroll"), // Adjusted text
            ),
          ],
        );
      },
    );
  }

  // Updated function to fetch exercises from Firestore
  Future<List<Map<String, dynamic>>> getExercisesForDay(int day) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return [];

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final programId = widget.plan['id'];
      final enrolledPrograms =
          userDoc.data()?['enrolledPrograms'] as Map<String, dynamic>? ?? {};
      final programData =
          enrolledPrograms[programId] as Map<String, dynamic>? ?? {};
      final plan = programData['plan'] as Map<String, dynamic>? ?? {};

      // Calculate week and day
      int week = ((day - 1) ~/ 7) + 1;
      int dayOfWeek = ((day - 1) % 7) + 1;
      final dayKey = 'w${week}d${dayOfWeek}';

      // Get exercise IDs for this day
      final exerciseIds = plan[dayKey] as List<dynamic>? ?? [];

      // Check if this is a clinic day
      if (exerciseIds.contains('CLINIC_DAY')) {
        // Check if this is the current day and if the next day should be unlocked
        if (day == _lastCompletedDay + 1) {
          // Calculate next day's key
          int nextWeek = ((day) ~/ 7) + 1;
          int nextDayOfWeek = ((day) % 7) + 1;
          final nextDayKey = 'w${nextWeek}d${nextDayOfWeek}';

          // Check if next day exists in the plan
          if (plan.containsKey(nextDayKey)) {
            // Update last completed day to current day
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .update({'enrolledPrograms.$programId.lastCompletedDay': day});

            // Update local state
            setState(() {
              _lastCompletedDay = day;
              _calculateProgress();
            });

            // Show success message
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Clinic day completed. Day ${day + 1} is now available!'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 3),
                ),
              );
            }
          }
        }

        return [
          {
            "name": "Clinic Visit Day",
            "description":
                "This is a clinic visit day. Please visit the clinic for in-person therapy.",
            "image": "assets/img/hospital.png",
            "duration": "Clinic Visit",
            "intensity": "Professional Care",
            "targetMuscles": ["Full Body Assessment"],
            "video": "",
            "isClinicDay": true
          }
        ];
      }

      if (exerciseIds.isEmpty) return [];

      // Fetch exercise details from exercises collection
      final exercisesSnapshot = await FirebaseFirestore.instance
          .collection('exercises')
          .where(FieldPath.documentId, whereIn: exerciseIds)
          .get();

      return exercisesSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          "name": data['name'] ?? '',
          "description": data['description'] ?? '',
          "image": data['image'] ?? 'assets/img/img_5.png',
          "duration": "${data['sets'] ?? 0} sets × ${data['reps'] ?? 0} reps",
          "intensity": data['difficulty'] ?? 'Moderate',
          "targetMuscles": List<String>.from(data['targetMuscles'] ?? []),
          "video": data['video'] ?? '',
          "isClinicDay": false
        };
      }).toList();
    } catch (e) {
      print('Error fetching exercises: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalWeeks = parseDuration(widget.plan["duration"] ?? '0 Weeks');
    int totalDays = totalWeeks * 7;

    return Scaffold(
      backgroundColor: TColor.white,
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(color: TColor.primaryColor1),
            )
          : Stack(
              children: [
                // Animated background gradient
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.lerp(
                              const Color(0xffA882DD).withOpacity(0.15),
                              const Color(0xff6d6492).withOpacity(0.1),
                              _fadeAnimation.value,
                            )!,
                            Color.lerp(
                              const Color(0xff6d6492).withOpacity(0.08),
                              const Color(0xffA882DD).withOpacity(0.2),
                              _fadeAnimation.value,
                            )!,
                          ],
                        ),
                      ),
                    );
                  },
                ),
                // Floating decorative elements
                ...List.generate(5, (index) {
                  return AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Positioned(
                        top: 80 +
                            (index * 140) +
                            (25 *
                                math.sin(
                                    _animationController.value * 2 * math.pi +
                                        index)),
                        left: (index.isEven
                                ? -40
                                : MediaQuery.of(context).size.width - 60) +
                            (15 *
                                math.cos(
                                    _animationController.value * 2 * math.pi +
                                        index)),
                        child: Container(
                          width: 60 + (index * 8),
                          height: 60 + (index * 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                TColor.primaryColor1.withOpacity(0.08),
                                const Color(0xffA882DD).withOpacity(0.03),
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    },
                  );
                }),
                // Main content
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Enhanced Header
                      Container(
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top + 10,
                          bottom: 20,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              TColor.primaryColor1.withOpacity(0.8),
                              TColor.primaryColor2.withOpacity(0.5)
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(40),
                            bottomRight: Radius.circular(40),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: TColor.primaryColor1.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Back Button
                            Positioned(
                              left: 20,
                              top: 0,
                              child: EnhancedBackButton(
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                            Column(
                              children: [
                                Hero(
                                  tag: 'doctor_${widget.plan["id"]}',
                                  child: Container(
                                    padding: EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      color: TColor.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: TColor.gray.withOpacity(0.3),
                                          blurRadius: 10,
                                          offset: Offset(0, 5),
                                        )
                                      ],
                                    ),
                                    child: CircleAvatar(
                                      radius: 47,
                                      backgroundImage: () {
                                        final String? doctorImage =
                                            widget.plan["doctorImage"];
                                        if (doctorImage != null) {
                                          if (doctorImage.startsWith('http') ||
                                              doctorImage.startsWith('https')) {
                                            return NetworkImage(doctorImage);
                                          } else {
                                            return AssetImage(doctorImage);
                                          }
                                        } else {
                                          return AssetImage(
                                            widget.plan["gender"]
                                                        ?.toLowerCase() ==
                                                    'female'
                                                ? 'assets/img/doctor1.jpg'
                                                : 'assets/img/doctor3.jpg',
                                          );
                                        }
                                      }() as ImageProvider,
                                      onBackgroundImageError:
                                          (exception, stackTrace) {
                                        // This callback is for debugging or logging, not for providing a fallback image.
                                        // The fallback logic is handled in the backgroundImage property itself.
                                        print(
                                            'Error loading image: $exception');
                                      },
                                    ),
                                  ),
                                ),
                                SizedBox(height: 15),
                                Text(
                                  "${widget.plan["doctor"]}",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.4,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.2),
                                        offset: const Offset(1, 1),
                                        blurRadius: 3,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 5),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.star,
                                        color: Colors.amber, size: 20),
                                    SizedBox(width: 5),
                                    Text(
                                      "${widget.plan["rating"]}",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    if (_isEnrolled)
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(15),
                                          border: Border.all(
                                            color:
                                                Colors.white.withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          '${(100 * _progressPercentage).toStringAsFixed(0)}% Complete',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Plan Details Card
                      Padding(
                        padding: EdgeInsets.all(20),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white,
                                const Color(0xffA882DD).withOpacity(0.02),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xffA882DD).withOpacity(0.2),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    const Color(0xffA882DD).withOpacity(0.15),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Plan Details",
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: TColor.primaryColor1,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                SizedBox(height: 20),
                                DetailItem(
                                  icon: Icons.monetization_on,
                                  title: "Price",
                                  value: "\$${widget.plan["price"]}",
                                ),
                                DetailItem(
                                  icon: Icons.calendar_today,
                                  title: "Duration",
                                  value: "${widget.plan["duration"]}",
                                ),
                                SizedBox(height: 20),
                                Container(
                                  padding: EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        TColor.primaryColor2.withOpacity(0.1),
                                        TColor.primaryColor1.withOpacity(0.05),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                      color:
                                          TColor.primaryColor2.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: TColor.primaryColor1
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              Icons.medical_information,
                                              color: TColor.primaryColor1,
                                              size: 24,
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Text(
                                            "Why This Plan?",
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: TColor.primaryColor1,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 15),
                                      Text(
                                        "This program is specifically designed for ${widget.plan["injury"]} injuries with ${widget.plan["severity"]} severity. It provides structured exercises under expert supervision to accelerate your recovery and restore full functionality.",
                                        style: TextStyle(
                                          color: TColor.gray,
                                          height: 1.5,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Conditional display based on enrollment status
                      if (!_isEnrolled)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 17),
                          width: double.infinity,
                          child: Column(
                            children: [
                              ElevatedButton(
                                onPressed: isLoading ? null : showPaymentDialog,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: TColor.primaryColor1,
                                  foregroundColor: TColor.white,
                                  padding: EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  elevation: 4,
                                  shadowColor:
                                      TColor.primaryColor1.withOpacity(0.5),
                                ),
                                child: isLoading
                                    ? CircularProgressIndicator(
                                        color: TColor.white)
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.lock_open, size: 17),
                                          SizedBox(width: 8),
                                          Text(
                                            "Enroll in the Program",
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                              SizedBox(height: 15),
                            ],
                          ),
                        ),
                      if (_isEnrolled)
                        Column(
                          children: [
                            Container(
                              margin: EdgeInsets.symmetric(horizontal: 20),
                              padding: EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 15),
                              decoration: BoxDecoration(
                                color: TColor.primaryColor1.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color:
                                        TColor.primaryColor1.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Progress:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: TColor.primaryColor1,
                                    ),
                                  ),
                                  Text(
                                    '${(100 * _progressPercentage).toStringAsFixed(0)}% Complete',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: TColor.primaryColor1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 20),
                            Container(
                              margin: EdgeInsets.symmetric(horizontal: 20),
                              padding: EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: TColor.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: TColor.gray.withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    "Rehabilitation Schedule",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: TColor.primaryColor1,
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Week Selector
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Select Week:",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: TColor.gray,
                                                fontSize: 13,
                                              ),
                                            ),
                                            SizedBox(height: 8),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 10),
                                              decoration: BoxDecoration(
                                                color: TColor.white,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: TColor.primaryColor1
                                                      .withOpacity(0.5),
                                                ),
                                              ),
                                              child:
                                                  DropdownButtonHideUnderline(
                                                child: DropdownButton<int>(
                                                  isExpanded: true,
                                                  value: selectedWeek,
                                                  onChanged: (int? newValue) {
                                                    setState(() {
                                                      selectedWeek = newValue!;
                                                      // Set selectedDay to the first unlocked day in the new week
                                                      final firstDayOfNewWeek =
                                                          (selectedWeek - 1) *
                                                                  7 +
                                                              1;
                                                      selectedDay = math.min(
                                                          firstDayOfNewWeek,
                                                          _lastCompletedDay +
                                                              1);
                                                      // Ensure selectedDay is at least 1 and not beyond total days
                                                      final totalDays =
                                                          parseDuration(widget
                                                                          .plan[
                                                                      "duration"] ??
                                                                  '0 Weeks') *
                                                              7;
                                                      selectedDay = math.max(
                                                          1,
                                                          math.min(selectedDay,
                                                              totalDays));
                                                    });
                                                  },
                                                  items: List.generate(
                                                    totalWeeks,
                                                    (index) => index + 1,
                                                  ).map<DropdownMenuItem<int>>(
                                                      (int value) {
                                                    return DropdownMenuItem<
                                                        int>(
                                                      value: value,
                                                      child:
                                                          Text("Week $value"),
                                                    );
                                                  }).toList(),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: 20),
                                      // Day Selector
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Select Day:",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: TColor.gray,
                                                fontSize: 13,
                                              ),
                                            ),
                                            SizedBox(height: 8),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 10),
                                              decoration: BoxDecoration(
                                                color: TColor.white,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: TColor.primaryColor1
                                                      .withOpacity(0.5),
                                                ),
                                              ),
                                              child:
                                                  DropdownButtonHideUnderline(
                                                child: DropdownButton<int>(
                                                  isExpanded: true,
                                                  value: selectedDay,
                                                  onChanged: (int? newValue) {
                                                    setState(() {
                                                      selectedDay = newValue!;
                                                    });
                                                  },
                                                  items: List.generate(
                                                    totalDays,
                                                    (index) => index + 1,
                                                  )
                                                      .where((day) =>
                                                          day >
                                                              (selectedWeek -
                                                                      1) *
                                                                  7 &&
                                                          day <=
                                                              selectedWeek *
                                                                  7 &&
                                                          day <=
                                                              _lastCompletedDay +
                                                                  1)
                                                      .map((day) =>
                                                          DropdownMenuItem<int>(
                                                            value: day,
                                                            child: Text(
                                                                "Day $day "),
                                                          ))
                                                      .toList(),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 20),
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        showExerciseList = true;
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: TColor.primaryColor1,
                                      foregroundColor: TColor.white,
                                      padding: EdgeInsets.symmetric(
                                          vertical: 10, horizontal: 17),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.visibility),
                                        SizedBox(width: 8),
                                        Text("Show Exercises"),
                                      ],
                                    ),
                                  ),
                                  if (showExerciseList)
                                    FutureBuilder<List<Map<String, dynamic>>>(
                                      future: getExercisesForDay(selectedDay),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return Center(
                                            child: CircularProgressIndicator(
                                              color: TColor.primaryColor1,
                                            ),
                                          );
                                        }

                                        if (snapshot.hasError) {
                                          return Center(
                                            child: Text(
                                              'Error loading exercises',
                                              style:
                                                  TextStyle(color: TColor.red),
                                            ),
                                          );
                                        }

                                        final exercises = snapshot.data ?? [];
                                        if (exercises.isEmpty) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 20.0),
                                            child: Card(
                                              color: TColor.primaryColor2
                                                  .withOpacity(0.1),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                              ),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(20.0),
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.info_outline,
                                                        color: TColor
                                                            .primaryColor1,
                                                        size: 28),
                                                    SizedBox(width: 15),
                                                    Expanded(
                                                      child: Text(
                                                        "Exercises will be added for this day later by the doctor.",
                                                        style: TextStyle(
                                                          color: TColor
                                                              .primaryColor1,
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        }

                                        return Column(
                                          children: [
                                            SizedBox(height: 20),
                                            ...exercises.map((exercise) {
                                              return Container(
                                                margin:
                                                    EdgeInsets.only(bottom: 13),
                                                decoration: BoxDecoration(
                                                  color: TColor.white,
                                                  borderRadius:
                                                      BorderRadius.circular(15),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: TColor.gray
                                                          .withOpacity(0.2),
                                                      blurRadius: 8,
                                                      offset: Offset(0, 3),
                                                    ),
                                                  ],
                                                  border: Border.all(
                                                    color: selectedDay <= 4
                                                        ? TColor.primaryColor1
                                                            .withOpacity(0.3)
                                                        : TColor.primaryColor2
                                                            .withOpacity(0.3),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Column(
                                                  children: [
                                                    ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.only(
                                                        topLeft:
                                                            Radius.circular(15),
                                                        topRight:
                                                            Radius.circular(15),
                                                      ),
                                                      child: exercise[
                                                                  "isClinicDay"] ==
                                                              true
                                                          ? Image.asset(
                                                              exercise["image"],
                                                              height: 150,
                                                              width: double
                                                                  .infinity,
                                                              fit: BoxFit.cover,
                                                              errorBuilder:
                                                                  (context,
                                                                      error,
                                                                      stackTrace) {
                                                                return Container(
                                                                  height: 150,
                                                                  width: double
                                                                      .infinity,
                                                                  color: TColor
                                                                      .lightGray,
                                                                  child: Icon(
                                                                    Icons
                                                                        .broken_image,
                                                                    color: TColor
                                                                        .gray,
                                                                    size: 50,
                                                                  ),
                                                                );
                                                              },
                                                            )
                                                          : exercise["image"]
                                                                  .startsWith(
                                                                      'assets/')
                                                              ? Image.asset(
                                                                  exercise[
                                                                      "image"],
                                                                  height: 150,
                                                                  width: double
                                                                      .infinity,
                                                                  fit: BoxFit
                                                                      .cover,
                                                                  errorBuilder:
                                                                      (context,
                                                                          error,
                                                                          stackTrace) {
                                                                    return Container(
                                                                      height:
                                                                          150,
                                                                      width: double
                                                                          .infinity,
                                                                      color: TColor
                                                                          .lightGray,
                                                                      child:
                                                                          Icon(
                                                                        Icons
                                                                            .broken_image,
                                                                        color: TColor
                                                                            .gray,
                                                                        size:
                                                                            50,
                                                                      ),
                                                                    );
                                                                  },
                                                                )
                                                              : Image.network(
                                                                  exercise[
                                                                      "image"],
                                                                  height: 150,
                                                                  width: double
                                                                      .infinity,
                                                                  fit: BoxFit
                                                                      .cover,
                                                                  errorBuilder:
                                                                      (context,
                                                                          error,
                                                                          stackTrace) {
                                                                    return Container(
                                                                      height:
                                                                          150,
                                                                      width: double
                                                                          .infinity,
                                                                      color: TColor
                                                                          .lightGray,
                                                                      child:
                                                                          Icon(
                                                                        Icons
                                                                            .broken_image,
                                                                        color: TColor
                                                                            .gray,
                                                                        size:
                                                                            50,
                                                                      ),
                                                                    );
                                                                  },
                                                                ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          EdgeInsets.all(10),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            children: [
                                                              Expanded(
                                                                child: Text(
                                                                  exercise[
                                                                      "name"],
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        15,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    color: selectedDay <=
                                                                            4
                                                                        ? TColor
                                                                            .primaryColor1
                                                                        : TColor
                                                                            .primaryColor2,
                                                                  ),
                                                                ),
                                                              ),
                                                              Container(
                                                                padding: EdgeInsets
                                                                    .symmetric(
                                                                        horizontal:
                                                                            8,
                                                                        vertical:
                                                                            4),
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: selectedDay <=
                                                                          4
                                                                      ? TColor
                                                                          .primaryColor1
                                                                          .withOpacity(
                                                                              0.1)
                                                                      : TColor
                                                                          .primaryColor2
                                                                          .withOpacity(
                                                                              0.1),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              20),
                                                                ),
                                                                child: Text(
                                                                  exercise[
                                                                      "duration"],
                                                                  style:
                                                                      TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        10,
                                                                    color: selectedDay <=
                                                                            4
                                                                        ? TColor
                                                                            .primaryColor1
                                                                        : TColor
                                                                            .primaryColor2,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          SizedBox(height: 10),
                                                          Text(
                                                            exercise[
                                                                "description"],
                                                            style: TextStyle(
                                                              color:
                                                                  TColor.gray,
                                                              height: 1.5,
                                                              fontSize: 13,
                                                            ),
                                                          ),
                                                          SizedBox(height: 15),
                                                          Wrap(
                                                            spacing: 8,
                                                            runSpacing: 8,
                                                            children: [
                                                              Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  Icon(
                                                                    Icons
                                                                        .fitness_center,
                                                                    size: 15,
                                                                    color: TColor
                                                                        .gray,
                                                                  ),
                                                                  SizedBox(
                                                                      width: 5),
                                                                  Text(
                                                                    "Intensity: ${exercise["intensity"]}",
                                                                    style:
                                                                        TextStyle(
                                                                      color: TColor
                                                                          .gray,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
                                                                      fontSize:
                                                                          13,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              if (exercise[
                                                                      "targetMuscles"] !=
                                                                  null)
                                                                ...(exercise[
                                                                            "targetMuscles"]
                                                                        as List<
                                                                            String>)
                                                                    .map((muscle) =>
                                                                        Container(
                                                                          padding: EdgeInsets.symmetric(
                                                                              horizontal: 8,
                                                                              vertical: 4),
                                                                          decoration:
                                                                              BoxDecoration(
                                                                            color:
                                                                                TColor.primaryColor1.withOpacity(0.1),
                                                                            borderRadius:
                                                                                BorderRadius.circular(15),
                                                                          ),
                                                                          child:
                                                                              Text(
                                                                            muscle,
                                                                            style:
                                                                                TextStyle(
                                                                              color: TColor.primaryColor1,
                                                                              fontSize: 10,
                                                                            ),
                                                                          ),
                                                                        ))
                                                                    .toList(),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          ],
                                        );
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: _isEnrolled &&
              showExerciseList &&
              selectedDay == _lastCompletedDay + 1 &&
              selectedDay <= totalDays
          ? FutureBuilder<List<Map<String, dynamic>>>(
              future: getExercisesForDay(selectedDay),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink();
                }

                final exercises = snapshot.data ?? [];
                if (exercises.isEmpty) {
                  return const SizedBox.shrink();
                }

                // Don't show the button for clinic days
                if (exercises.first["isClinicDay"] == true) {
                  return const SizedBox.shrink();
                }

                return Container(
                  margin: EdgeInsets.only(bottom: 13),
                  child: FloatingActionButton.extended(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RehabilitationWorkout(
                            plan: widget.plan,
                            selectedWeek: selectedWeek,
                            selectedDay: selectedDay,
                          ),
                        ),
                      ).then((_) => _checkEnrollmentStatus());
                    },
                    backgroundColor: TColor.primaryColor1,
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    icon: Icon(Icons.play_arrow, color: TColor.white),
                    label: Text(
                      "Start Rehabilitation",
                      style: TextStyle(
                        color: TColor.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              },
            )
          : null,
    );
  }

  // String getDayOfWeek(int day) {
  //   if (day < 1 || day > 7) return '';
  //   final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  //   return '(${days[day - 1]})';
  // }
}

class DetailItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const DetailItem({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xffA882DD).withOpacity(0.05),
            const Color(0xff6d6492).withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xffA882DD).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: TColor.primaryColor2.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: TColor.primaryColor2,
              size: 24,
            ),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: TColor.gray,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: TColor.primaryColor1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EnhancedBackButton extends StatefulWidget {
  final VoidCallback onPressed;

  const EnhancedBackButton({Key? key, required this.onPressed})
      : super(key: key);

  @override
  _EnhancedBackButtonState createState() => _EnhancedBackButtonState();
}

class _EnhancedBackButtonState extends State<EnhancedBackButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: Transform.scale(
        scale: _scaleAnimation.value,
        child: Container(
          height: 50,
          width: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isPressed
                  ? [
                      const Color(0xffA882DD).withOpacity(0.2),
                      Colors.white,
                    ]
                  : [Colors.white, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _isPressed
                    ? const Color(0xffA882DD).withOpacity(_glowAnimation.value)
                    : TColor.gray.withOpacity(0.2),
                blurRadius: _isPressed ? 15 : 10,
                spreadRadius: _isPressed ? 2 : 0,
                offset: Offset(0, 5),
              ),
            ],
            border: Border.all(
              color: _isPressed
                  ? const Color(0xffA882DD).withOpacity(0.4)
                  : TColor.gray.withOpacity(0.1),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Icon(
              Icons.arrow_back_ios_rounded,
              color: _isPressed
                  ? const Color(0xffA882DD)
                  : TColor.gray.withOpacity(0.8),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
