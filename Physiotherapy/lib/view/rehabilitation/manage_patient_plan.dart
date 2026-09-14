import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:physiotherapy/common/color_extension.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'package:video_player/video_player.dart';
import 'package:physiotherapy/models/exercise_model.dart';
import 'package:physiotherapy/models/program_model.dart';

class ManagePatientPlanPage extends StatefulWidget {
  final ProgramModel program;
  final String userId;
  final String patientName;
  final Map<String, dynamic> plan;
  final dynamic progress;
  final dynamic lastVisit;

  const ManagePatientPlanPage({
    super.key,
    required this.program,
    required this.userId,
    required this.patientName,
    required this.plan,
    required this.progress,
    required this.lastVisit,
  });

  @override
  State<ManagePatientPlanPage> createState() => _ManagePatientPlanPageState();
}

class _ManagePatientPlanPageState extends State<ManagePatientPlanPage>
    with TickerProviderStateMixin {
  int selectedDayIndex = 0;
  List<RehabExercise> exercises = [];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _backgroundAnimationController;
  late Animation<double> _backgroundAnimation;
  VideoPlayerController? _videoController;
  bool _isVideoPlaying = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int? _expandedExerciseIndex;
  bool _isLoading = true;
  late int totalDays;
  Map<String, bool> _clinicDays = {};

  @override
  void initState() {
    super.initState();
    totalDays = _parseTotalDays(widget.program.duration);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_backgroundAnimationController);

    _backgroundAnimationController.repeat(reverse: true);

    _loadExercisesForDay();
    _loadClinicDays();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _backgroundAnimationController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _loadClinicDays() async {
    try {
      final userDoc =
          await _firestore.collection('users').doc(widget.userId).get();
      final clinicDays = userDoc.data()?['enrolledPrograms']
                  ?[widget.program.programId]?['clinicDays']
              as Map<String, dynamic>? ??
          {};

      setState(() {
        _clinicDays =
            clinicDays.map((key, value) => MapEntry(key, value as bool));
      });
    } catch (e) {
      print('Error loading clinic days: $e');
    }
  }

  Future<void> _toggleClinicDay() async {
    try {
      int dayNum = selectedDayIndex + 1;
      int week = ((dayNum - 1) ~/ 7) + 1;
      int dayOfWeek = ((dayNum - 1) % 7) + 1;
      final dayKey = 'w${week}d${dayOfWeek}';

      final newValue = !(_clinicDays[dayKey] ?? false);

      await _firestore.collection('users').doc(widget.userId).update({
        'enrolledPrograms.${widget.program.programId}.clinicDays.$dayKey':
            newValue
      });

      setState(() {
        _clinicDays[dayKey] = newValue;
      });

      if (newValue) {
        await _removeAllExercisesForDay(dayKey);
        await _firestore.collection('users').doc(widget.userId).update({
          'enrolledPrograms.${widget.program.programId}.plan.$dayKey': [
            'CLINIC_DAY'
          ]
        });
      } else {
        await _firestore.collection('users').doc(widget.userId).update(
            {'enrolledPrograms.${widget.program.programId}.plan.$dayKey': []});
      }
    } catch (e) {
      print('Error toggling clinic day: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating clinic day: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _removeAllExercisesForDay(String dayKey) async {
    try {
      final userDoc =
          await _firestore.collection('users').doc(widget.userId).get();
      final planData = userDoc.data()?['enrolledPrograms']
              ?[widget.program.programId]?['plan']?[dayKey] as List<dynamic>? ??
          [];

      await _firestore.collection('users').doc(widget.userId).update({
        'enrolledPrograms.${widget.program.programId}.plan.$dayKey':
            FieldValue.delete()
      });

      for (var exerciseId in planData) {
        await _firestore.collection('exercises').doc(exerciseId).delete();
      }

      await _loadExercisesForDay();
    } catch (e) {
      print('Error removing exercises: $e');
    }
  }

  bool isClinicVisit(int dayIndex) {
    int dayNum = dayIndex + 1;
    int week = ((dayNum - 1) ~/ 7) + 1;
    int dayOfWeek = ((dayNum - 1) % 7) + 1;
    final dayKey = 'w${week}d${dayOfWeek}';
    return _clinicDays[dayKey] ?? false;
  }

  String getDayOfWeek(int dayIndex) {
    List<String> days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
    return days[dayIndex % 7];
  }

  String getFullDayName(int dayIndex) {
    List<String> days = [
      "Sunday",
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday"
    ];
    return days[dayIndex % 7];
  }

  int _parseTotalDays(String duration) {
    if (duration.contains("Week")) {
      return int.parse(duration.split(" ")[0]) * 7;
    } else if (duration.contains("Month")) {
      int months = int.parse(duration.split(" ")[0]);
      return months * 4 * 7;
    } else if (duration.contains("Day")) {
      return int.parse(duration.split(" ")[0]);
    }
    return 7;
  }

  Future<void> _loadExercisesForDay() async {
    setState(() {
      _isLoading = true;
    });
    try {
      int dayNum = selectedDayIndex + 1;
      int week = ((dayNum - 1) ~/ 7) + 1;
      int dayOfWeek = ((dayNum - 1) % 7) + 1;
      final dayKey = 'w${week}d${dayOfWeek}';

      final userDoc =
          await _firestore.collection('users').doc(widget.userId).get();
      final planData = userDoc.data()?['enrolledPrograms']
              ?[widget.program.programId]?['plan']?[dayKey] as List<dynamic>? ??
          [];

      if (planData.contains('CLINIC_DAY')) {
        setState(() {
          exercises = [];
          _isLoading = false;
        });
        return;
      }

      if (planData.isEmpty) {
        setState(() {
          exercises = [];
          _isLoading = false;
        });
        return;
      }

      final exercisesSnapshot = await _firestore
          .collection('exercises')
          .where(FieldPath.documentId, whereIn: planData)
          .get();

      setState(() {
        exercises = exercisesSnapshot.docs.map((doc) {
          final data = doc.data();
          return RehabExercise(
            id: doc.id,
            name: data['name'] ?? '',
            sets: data['sets'] ?? 3,
            reps: data['reps'] ?? 10,
            image: data['image'] ?? "assets/img/img_5.png",
            video: data['video'] ?? "assets/videos/Back2.mp4",
            description: data['description'] ?? '',
            difficulty: data['difficulty'] ?? 'Moderate',
            targetMuscles: List<String>.from(data['targetMuscles'] ?? []),
            programId: widget.program.programId,
            createdAt:
                (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            updatedAt:
                (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            isCompleted: data['isCompleted'] ?? false,
          );
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading exercises: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveExerciseToPlan(RehabExercise exercise) async {
    try {
      int dayNum = selectedDayIndex + 1;
      int week = ((dayNum - 1) ~/ 7) + 1;
      int dayOfWeek = ((dayNum - 1) % 7) + 1;
      final dayKey = 'w${week}d${dayOfWeek}';

      // Check if exercise with same name already exists
      final existingExerciseQuery = await _firestore
          .collection('exercises')
          .where('name', isEqualTo: exercise.name)
          .get();

      String exerciseId;
      if (existingExerciseQuery.docs.isNotEmpty) {
        // Use existing exercise
        exerciseId = existingExerciseQuery.docs.first.id;
      } else {
        // Create new exercise
        final exerciseRef =
            await _firestore.collection('exercises').add(exercise.toMap());
        exerciseId = exerciseRef.id;
      }

      await _firestore.collection('users').doc(widget.userId).update({
        'enrolledPrograms.${widget.program.programId}.plan.$dayKey':
            FieldValue.arrayUnion([exerciseId])
      });

      await _loadExercisesForDay();
    } catch (e) {
      print('Error saving exercise: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving exercise: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _removeExerciseFromPlan(String exerciseId) async {
    try {
      int dayNum = selectedDayIndex + 1;
      int week = ((dayNum - 1) ~/ 7) + 1;
      int dayOfWeek = ((dayNum - 1) % 7) + 1;
      final dayKey = 'w${week}d${dayOfWeek}';

      // Remove exercise from the current day's plan
      await _firestore.collection('users').doc(widget.userId).update({
        'enrolledPrograms.${widget.program.programId}.plan.$dayKey':
            FieldValue.arrayRemove([exerciseId])
      });

      // Check if the exercise is used in any other days
      final userDoc =
          await _firestore.collection('users').doc(widget.userId).get();
      final enrolledPrograms =
          userDoc.data()?['enrolledPrograms'] as Map<String, dynamic>? ?? {};
      final programData =
          enrolledPrograms[widget.program.programId] as Map<String, dynamic>? ??
              {};
      final plan = programData['plan'] as Map<String, dynamic>? ?? {};

      bool isExerciseUsedElsewhere = false;
      plan.forEach((key, value) {
        if (key != dayKey && value is List && value.contains(exerciseId)) {
          isExerciseUsedElsewhere = true;
        }
      });

      // Only delete the exercise from the exercises collection if it's not used anywhere else
      if (!isExerciseUsedElsewhere) {
        await _firestore.collection('exercises').doc(exerciseId).delete();
      }

      await _loadExercisesForDay();
    } catch (e) {
      print('Error removing exercise: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing exercise: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _initializeVideo(String videoPath) {
    print('Initializing video from path: $videoPath');

    if (_videoController != null) {
      _videoController!.pause();
      _videoController!.dispose();
      _videoController = null;
    }

    try {
      _videoController = VideoPlayerController.asset(videoPath);

      _videoController!.initialize().then((_) {
        if (mounted) {
          setState(() {
            _isVideoPlaying = false;
          });
          _videoController!.play();
        }
      }).catchError((error) {
        print('Error initializing video: $error');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading video: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });

      _videoController!.addListener(() {
        if (mounted) {
          setState(() {
            _isVideoPlaying = _videoController?.value.isPlaying ?? false;
          });
        }
      });
    } catch (e) {
      print('Error creating video controller: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating video player: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _togglePlayPause() {
    if (_videoController == null) return;

    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
      _isVideoPlaying = _videoController!.value.isPlaying;
    });
  }

  void toggleExerciseExpansion(int index) {
    setState(() {
      if (_expandedExerciseIndex == index) {
        _expandedExerciseIndex = null;
        _videoController?.pause();
        _videoController?.dispose();
        _videoController = null;
      } else {
        _expandedExerciseIndex = index;
        _initializeVideo(exercises[index].video);
      }
    });
  }

  void toggleExerciseCompletion(int index) async {
    try {
      final exercise = exercises[index];
      final updatedExercise =
          exercise.copyWith(isCompleted: !exercise.isCompleted);

      await _firestore.collection('exercises').doc(exercise.id).update({
        'isCompleted': updatedExercise.isCompleted,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      setState(() {
        exercises[index] = updatedExercise;
      });

      if (updatedExercise.isCompleted) {
        _showCompletionConfetti();
      }
    } catch (e) {
      print('Error toggling exercise completion: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating exercise: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showCompletionConfetti() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          Navigator.of(context).pop();
        });

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Lottie.asset(
            'assets/animations/confetti.json',
            width: 200,
            height: 200,
            fit: BoxFit.contain,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _backgroundAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(
                        const Color(0xffA882DD).withOpacity(0.5),
                        const Color(0xff6d6492).withOpacity(0.5),
                        _backgroundAnimation.value,
                      )!,
                      Color.lerp(
                        const Color(0xff6d6492).withOpacity(0.05),
                        const Color(0xffA882DD).withOpacity(0.4),
                        _backgroundAnimation.value,
                      )!,
                    ],
                  ),
                ),
              );
            },
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              title: Text(
                "${widget.patientName}'s Plan",
                style: TextStyle(
                  color: TColor.primaryColor1,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              leading: IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: Icon(
                  Icons.arrow_back_ios,
                  color: TColor.primaryColor1,
                ),
              ),
              actions: [
                IconButton(
                  onPressed: _toggleClinicDay,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isClinicVisit(selectedDayIndex)
                          ? TColor.primaryColor1
                          : TColor.primaryColor1.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.medical_services,
                      color: isClinicVisit(selectedDayIndex)
                          ? Colors.white
                          : TColor.primaryColor1,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
            ),
            body: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${widget.program.programName}",
                            style: TextStyle(
                              color: TColor.black,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: TColor.primaryColor1.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "Duration: ${widget.program.duration}",
                              style: TextStyle(
                                color: TColor.primaryColor1,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Week selector
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        height: 70,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: (totalDays / 7).ceil(),
                          itemBuilder: (context, weekIndex) {
                            bool isSelected =
                                (selectedDayIndex ~/ 7) == weekIndex;
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 5),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    selectedDayIndex = weekIndex * 7;
                                    _loadExercisesForDay();
                                    _expandedExerciseIndex = null;
                                  });
                                },
                                child: Container(
                                  width: 80,
                                  decoration: BoxDecoration(
                                    gradient: isSelected
                                        ? LinearGradient(
                                            colors: [
                                              TColor.primaryColor1,
                                              TColor.primaryColor2,
                                            ],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                          )
                                        : null,
                                    color: isSelected
                                        ? null
                                        : TColor.primaryColor1.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: TColor.primaryColor2
                                                  .withOpacity(0.3),
                                              blurRadius: 10,
                                              offset: const Offset(0, 5),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      "Week ${weekIndex + 1}",
                                      style: TextStyle(
                                        color: isSelected
                                            ? TColor.white
                                            : TColor.primaryColor1,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Day selector
                      SizedBox(
                        height: 70,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: 7,
                          itemBuilder: (context, index) {
                            bool isSelected = selectedDayIndex % 7 == index;
                            int dayNum = index + 1;
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  selectedDayIndex =
                                      (selectedDayIndex ~/ 7) * 7 + index;
                                  _loadExercisesForDay();
                                  _expandedExerciseIndex = null;
                                });
                              },
                              child: Container(
                                width: 60,
                                margin: const EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? LinearGradient(
                                          colors: [
                                            TColor.primaryColor1,
                                            TColor.primaryColor2,
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        )
                                      : null,
                                  color: isSelected
                                      ? null
                                      : TColor.primaryColor1.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: TColor.primaryColor2
                                                .withOpacity(0.3),
                                            blurRadius: 10,
                                            offset: const Offset(0, 5),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Center(
                                  child: Text(
                                    "Day $dayNum",
                                    style: TextStyle(
                                      color: isSelected
                                          ? TColor.white
                                          : TColor.primaryColor1,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: TColor.primaryColor1,
                          ),
                        )
                      : AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _buildDayContent(),
                        ),
                ),
              ],
            ),
            floatingActionButton: isClinicVisit(selectedDayIndex)
                ? null
                : FloatingActionButton.extended(
                    onPressed: () async {
                      final selectedExercise = await showDialog<RehabExercise>(
                        context: context,
                        builder: (context) => ExerciseSelectionDialog(
                          programId: widget.program.programId,
                          userId: widget.userId,
                        ),
                      );

                      if (selectedExercise != null) {
                        await _saveExerciseToPlan(selectedExercise);
                      }
                    },
                    backgroundColor: TColor.primaryColor1,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      "Add from Previous Exercises",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayContent() {
    bool isClinic = isClinicVisit(selectedDayIndex);

    if (isClinic) {
      return Center(
        child: Column(
          children: [
            const SizedBox(height: 125),
            Image.asset(
              "assets/img/hospital.png",
              width: 100,
              height: 100,
            ),
            const SizedBox(height: 20),
            Text(
              "Clinic Visit Day",
              style: TextStyle(
                color: TColor.black,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                "This is a clinic visit day. Patient should visit the clinic for in-person therapy.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: TColor.gray,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      );
    } else if (exercises.isEmpty) {
      return Center(
        child: Column(
          children: [
            const SizedBox(height: 90),
            Icon(
              Icons.fitness_center,
              size: 80,
              color: TColor.gray.withOpacity(0.5),
            ),
            const SizedBox(height: 20),
            Text(
              "No Exercises Yet",
              style: TextStyle(
                color: TColor.black,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                "Tap the + button to add exercises for ${getFullDayName(selectedDayIndex)}",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: TColor.gray,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: addExercise,
              label: const Text(
                "Add an Exercise",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: TColor.primaryColor1,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return ListView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: exercises.length + 1,
        itemBuilder: (context, index) {
          if (index == exercises.length) {
            return Container(
              margin: const EdgeInsets.only(top: 20),
              child: ElevatedButton.icon(
                onPressed: addExercise,
                label: const Text(
                  "Add an Exercise",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TColor.primaryColor1,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            );
          }

          final exercise = exercises[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                // Exercise Header
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: TColor.primaryColor1.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          exercise.image,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 60,
                              height: 60,
                              color: TColor.lightGray,
                              child: const Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exercise.name,
                              style: TextStyle(
                                color: TColor.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: TColor.lightGray,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "${exercise.sets} sets",
                                    style: TextStyle(
                                      color: TColor.gray,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: TColor.lightGray,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "${exercise.reps} reps",
                                    style: TextStyle(
                                      color: TColor.gray,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => toggleExerciseExpansion(index),
                        icon: Icon(
                          _expandedExerciseIndex == index
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: TColor.gray,
                        ),
                      ),
                    ],
                  ),
                ),
                // Exercise Details
                if (_expandedExerciseIndex == index)
                  Container(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(),
                        const SizedBox(height: 10),
                        Text(
                          "Description",
                          style: TextStyle(
                            color: TColor.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          exercise.description,
                          style: TextStyle(
                            color: TColor.gray,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          "Target Muscles",
                          style: TextStyle(
                            color: TColor.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: exercise.targetMuscles
                              .map((muscle) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          TColor.primaryColor1.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: TColor.primaryColor1
                                            .withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      muscle,
                                      style: TextStyle(
                                        color: TColor.primaryColor1,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 20),
                        // Video Player Section
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                if (_videoController != null &&
                                    _videoController!.value.isInitialized)
                                  AspectRatio(
                                    aspectRatio:
                                        _videoController!.value.aspectRatio,
                                    child: VideoPlayer(_videoController!),
                                  )
                                else
                                  AspectRatio(
                                    aspectRatio: 16 / 9,
                                    child: Container(
                                      color: Colors.black,
                                      child: Center(
                                        child: Icon(
                                          Icons.play_circle_outline,
                                          color: Colors.white,
                                          size: 50,
                                        ),
                                      ),
                                    ),
                                  ),
                                Positioned.fill(
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _togglePlayPause,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black.withOpacity(0.3),
                                            ],
                                          ),
                                        ),
                                        child: Center(
                                          child: AnimatedOpacity(
                                            opacity:
                                                _isVideoPlaying ? 0.0 : 1.0,
                                            duration:
                                                Duration(milliseconds: 300),
                                            child: Icon(
                                              _isVideoPlaying
                                                  ? Icons.pause
                                                  : Icons.play_arrow,
                                              color: Colors.white,
                                              size: 50,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                if (_videoController != null &&
                                    _videoController!.value.isInitialized)
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: VideoProgressIndicator(
                                      _videoController!,
                                      allowScrubbing: true,
                                      padding: EdgeInsets.symmetric(
                                          vertical: 2, horizontal: 0),
                                      colors: VideoProgressColors(
                                        playedColor: TColor.primaryColor1,
                                        bufferedColor: TColor.lightGray,
                                        backgroundColor:
                                            Colors.white.withOpacity(0.3),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => editExercise(index),
                                icon: const Icon(Icons.edit),
                                label: const Text("Edit"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: TColor.lightGray,
                                  foregroundColor: TColor.black,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => deleteExercise(index),
                                icon: const Icon(Icons.delete_outline),
                                label: const Text("Delete"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: TColor.red.withOpacity(0.1),
                                  foregroundColor: TColor.red,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      );
    }
  }

  void addExercise() async {
    String exerciseName = "";
    int sets = 3;
    int reps = 10;
    String description = "";
    String difficulty = "Moderate";
    List<String> muscles = [];
    XFile? imageFile;

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Exercise"),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: "Exercise Name"),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter an exercise name";
                    }
                    return null;
                  },
                  onSaved: (value) => exerciseName = value!,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(labelText: "Sets"),
                        keyboardType: TextInputType.number,
                        initialValue: "3",
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter number of sets";
                          }
                          return null;
                        },
                        onSaved: (value) => sets = int.parse(value!),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(labelText: "Reps"),
                        keyboardType: TextInputType.number,
                        initialValue: "10",
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter number of reps";
                          }
                          return null;
                        },
                        onSaved: (value) => reps = int.parse(value!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  decoration: const InputDecoration(labelText: "Description"),
                  maxLines: 3,
                  onSaved: (value) => description = value ?? "",
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: "Difficulty"),
                  value: difficulty,
                  items: ["Beginner", "Moderate", "Advanced"]
                      .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(e),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      difficulty = value;
                    }
                  },
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    "Shoulders",
                    "Chest",
                    "Back",
                    "Arms",
                    "Legs",
                    "Core",
                    "Full Body"
                  ].map((muscle) {
                    final isSelected = muscles.contains(muscle);
                    return FilterChip(
                      label: Text(muscle),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            muscles.add(muscle);
                          } else {
                            muscles.remove(muscle);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final ImagePicker picker = ImagePicker();
                          final XFile? image = await picker.pickImage(
                              source: ImageSource.gallery);
                          if (image != null) {
                            imageFile = image;
                          }
                        },
                        icon: const Icon(Icons.image),
                        label: const Text("Add Image"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();

                // Check if exercise name already exists
                final existingExerciseQuery = await _firestore
                    .collection('exercises')
                    .where('name', isEqualTo: exerciseName)
                    .get();

                if (existingExerciseQuery.docs.isNotEmpty) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'An exercise with this name already exists. Please use "Add from Previous Exercises" instead.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  return;
                }

                if (exerciseName.isNotEmpty &&
                    sets > 0 &&
                    reps > 0 &&
                    muscles.isNotEmpty) {
                  try {
                    final exercise = RehabExercise(
                      id: '', // Will be set after creation
                      name: exerciseName,
                      sets: sets,
                      reps: reps,
                      image: imageFile?.path ?? "assets/img/img_7.png",
                      video: "assets/videos/Back2.mp4",
                      description: description,
                      difficulty: difficulty,
                      targetMuscles: muscles,
                      programId: widget.program.programId,
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    );
                    await _saveExerciseToPlan(exercise);
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Exercise added successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    print('Error adding exercise: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error adding exercise: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void editExercise(int index) {
    RehabExercise exercise = exercises[index];
    String exerciseName = exercise.name;
    int sets = exercise.sets;
    int reps = exercise.reps;
    String image = exercise.image;
    String video = exercise.video;
    String description = exercise.description;
    String difficulty = exercise.difficulty;
    List<String> muscles = List<String>.from(exercise.targetMuscles);

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Exercise"),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: "Exercise Name"),
                  initialValue: exerciseName,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter an exercise name";
                    }
                    return null;
                  },
                  onSaved: (value) => exerciseName = value!,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(labelText: "Sets"),
                        keyboardType: TextInputType.number,
                        initialValue: sets.toString(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter number of sets";
                          }
                          return null;
                        },
                        onSaved: (value) => sets = int.parse(value!),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(labelText: "Reps"),
                        keyboardType: TextInputType.number,
                        initialValue: reps.toString(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter number of reps";
                          }
                          return null;
                        },
                        onSaved: (value) => reps = int.parse(value!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  decoration: const InputDecoration(labelText: "Description"),
                  maxLines: 3,
                  initialValue: description,
                  onSaved: (value) => description = value ?? "",
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: "Difficulty"),
                  value: difficulty,
                  items: ["Beginner", "Moderate", "Advanced"]
                      .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(e),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      difficulty = value;
                    }
                  },
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    "Shoulders",
                    "Chest",
                    "Back",
                    "Arms",
                    "Legs",
                    "Core",
                    "Full Body"
                  ].map((muscle) {
                    final isSelected = muscles.contains(muscle);
                    return FilterChip(
                      label: Text(muscle),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            muscles.add(muscle);
                          } else {
                            muscles.remove(muscle);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final ImagePicker picker = ImagePicker();
                          final XFile? newImage = await picker.pickImage(
                              source: ImageSource.gallery);
                          if (newImage != null) {
                            image = newImage.path;
                          }
                        },
                        icon: const Icon(Icons.image),
                        label: const Text("Change Image"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                if (exerciseName.isNotEmpty &&
                    sets > 0 &&
                    reps > 0 &&
                    muscles.isNotEmpty) {
                  try {
                    final updatedExercise = exercise.copyWith(
                      name: exerciseName,
                      sets: sets,
                      reps: reps,
                      image: image,
                      video: "assets/videos/Back2.mp4",
                      description: description,
                      difficulty: difficulty,
                      targetMuscles: muscles,
                      updatedAt: DateTime.now(),
                    );

                    // Update exercise in Firestore
                    await _firestore
                        .collection('exercises')
                        .doc(exercise.id)
                        .update(updatedExercise.toMap());

                    setState(() {
                      exercises[index] = updatedExercise;
                    });

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Exercise updated successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    print('Error updating exercise: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error updating exercise: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void deleteExercise(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text("Delete Exercise"),
          content: Text(
              "Are you sure you want to delete '${exercises[index].name}'?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: TextStyle(color: TColor.gray),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _removeExerciseFromPlan(exercises[index].id);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text("Exercise deleted"),
                        backgroundColor: TColor.red,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        margin: const EdgeInsets.all(10),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  print('Error deleting exercise: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error deleting exercise: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: TColor.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Delete",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}

class ExerciseSelectionDialog extends StatefulWidget {
  final String programId;
  final String userId;

  const ExerciseSelectionDialog({
    super.key,
    required this.programId,
    required this.userId,
  });

  @override
  State<ExerciseSelectionDialog> createState() =>
      _ExerciseSelectionDialogState();
}

class _ExerciseSelectionDialogState extends State<ExerciseSelectionDialog> {
  List<RehabExercise> availableExercises = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAvailableExercises();
  }

  Future<void> _loadAvailableExercises() async {
    try {
      // First get all programs managed by this doctor
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      final enrolledPrograms =
          userDoc.data()?['enrolledPrograms'] as Map<String, dynamic>? ?? {};
      final programIds = enrolledPrograms.keys.toList();

      // Get all exercises from all programs
      final exercisesSnapshot = await FirebaseFirestore.instance
          .collection('exercises')
          .where('programId', whereIn: programIds)
          .get();

      setState(() {
        availableExercises = exercisesSnapshot.docs.map((doc) {
          final data = doc.data();
          return RehabExercise(
            id: doc.id,
            name: data['name'] ?? '',
            sets: data['sets'] ?? 3,
            reps: data['reps'] ?? 10,
            image: data['image'] ?? 'assets/img/img_7.png',
            video: data['video'] ?? 'assets/videos/Back2.mp4',
            description: data['description'] ?? '',
            difficulty: data['difficulty'] ?? 'Moderate',
            targetMuscles: List<String>.from(data['targetMuscles'] ?? []),
            programId: data['programId'] ?? '',
            createdAt:
                (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            updatedAt:
                (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            isCompleted: data['isCompleted'] ?? false,
          );
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error loading exercises: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Select Exercise",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: TColor.black,
              ),
            ),
            const SizedBox(height: 20),
            if (isLoading)
              const CircularProgressIndicator()
            else if (availableExercises.isEmpty)
              Text(
                "No exercises available",
                style: TextStyle(
                  color: TColor.gray,
                  fontSize: 16,
                ),
              )
            else
              SizedBox(
                height: 300,
                child: ListView.builder(
                  itemCount: availableExercises.length,
                  itemBuilder: (context, index) {
                    final exercise = availableExercises[index];
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          exercise.image,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 40,
                              height: 40,
                              color: TColor.lightGray,
                              child: const Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      ),
                      title: Text(exercise.name),
                      subtitle: Text(
                        "${exercise.sets} sets × ${exercise.reps} reps • ${exercise.difficulty}",
                      ),
                      onTap: () {
                        Navigator.pop(context, exercise);
                      },
                    );
                  },
                ),
              ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: TColor.gray,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
