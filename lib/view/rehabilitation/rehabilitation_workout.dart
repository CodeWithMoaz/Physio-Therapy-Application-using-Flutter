import 'package:flutter/material.dart';
import 'package:physiotherapy/common/color_extension.dart';
import 'package:physiotherapy/view/unused/chatwithdoctor.dart';
import 'package:video_player/video_player.dart';
import 'package:lottie/lottie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RehabilitationWorkout extends StatefulWidget {
  final Map<String, dynamic> plan;
  final int selectedWeek;
  final int selectedDay;

  const RehabilitationWorkout({
    super.key,
    required this.plan,
    required this.selectedWeek,
    required this.selectedDay,
  });

  @override
  _RehabilitationWorkoutState createState() => _RehabilitationWorkoutState();
}

class _RehabilitationWorkoutState extends State<RehabilitationWorkout>
    with SingleTickerProviderStateMixin {
  int currentExerciseIndex = 0;
  List<Map<String, dynamic>> exercises = [];
  VideoPlayerController? _videoController;
  bool _isVideoPlaying = true;
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  bool _showCompletionAnimation = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _loadExercises().then((_) {
      if (exercises.isNotEmpty) {
        setState(() {
          _progressAnimation = Tween<double>(
            begin: 0,
            end: (currentExerciseIndex + 1) / exercises.length,
          ).animate(CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ));
          _isLoading = false;
        });
        _animationController.forward();
      }
    });
  }

  Future<void> _loadExercises() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final programData =
          userDoc.data()?['enrolledPrograms']?[widget.plan['id']];
      if (programData == null) return;

      final dayKey = 'w${widget.selectedWeek}d${widget.selectedDay}';
      final exerciseIds = List<String>.from(programData['plan']?[dayKey] ?? []);

      if (exerciseIds.isEmpty) {
        setState(() {
          exercises = [];
          _isLoading = false;
        });
        return;
      }

      final exercisesSnapshot = await FirebaseFirestore.instance
          .collection('exercises')
          .where(FieldPath.documentId, whereIn: exerciseIds)
          .get();

      final loadedExercises = exercisesSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          "name": data['name'] ?? '',
          "sets": data['sets'] ?? 3,
          "reps": data['reps'] ?? 10,
          "image": data['image'] ?? "assets/img/img_5.png",
          "video": data['video'] ?? "assets/videos/Back2.mp4",
          "description": data['description'] ?? '',
          "color": Color(0xFFF8BBD0), // Light pink
        };
      }).toList();

      setState(() {
        exercises = loadedExercises;
        if (exercises.isNotEmpty) {
          _initializeVideo(exercises[0]["video"]);
        }
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading exercises: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading exercises: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Function to parse duration and get total weeks (copied from doctors_plan_view.dart)
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

  void _initializeVideo(String videoPath) {
    print(
        'Attempting to initialize video from path in RehabilitationWorkout: $videoPath');

    // Dispose existing controller if it exists
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
            _isVideoPlaying = false; // Start paused
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
        // if (mounted) {
        //   setState(() {
        //     _isVideoPlaying = _videoController?.value.isPlaying ?? false;
        //   });
        // }
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

  @override
  void dispose() {
    if (_videoController != null) {
      _videoController!.pause();
      _videoController!.dispose();
      _videoController = null;
    }
    _animationController.dispose();
    super.dispose();
  }

  Future<void> goToNextExercise() async {
    if (currentExerciseIndex < exercises.length - 1) {
      // Pause and dispose current video before moving to next
      if (_videoController != null) {
        _videoController!.pause();
        _videoController!.dispose();
        _videoController = null;
      }

      _animationController.reset();
      setState(() {
        currentExerciseIndex++;
        if (exercises.isNotEmpty) {
          _initializeVideo(exercises[currentExerciseIndex]["video"]);

          _progressAnimation = Tween<double>(
            begin: currentExerciseIndex / exercises.length,
            end: (currentExerciseIndex + 1) / exercises.length,
          ).animate(CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ));
        }
      });
      _animationController.forward();
    } else {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final programId = widget.plan['id'];
          // Calculate total days for progress calculation
          final durationString = widget.plan["duration"] ?? '0 Weeks';
          final totalWeeks = parseDuration(durationString);
          final totalDays = totalWeeks * 7;

          // Calculate the new completed day and progress percentage
          final newLastCompletedDay =
              widget.selectedDay; // The day just finished
          final newProgressPercentage =
              totalDays > 0 ? (newLastCompletedDay / totalDays) * 100.0 : 0.0;

          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
            'enrolledPrograms.$programId.lastCompletedDay': newLastCompletedDay,
            'enrolledPrograms.$programId.progress':
                newProgressPercentage.toInt(),
          });
        }
      } catch (e) {
        print('Error updating lastCompletedDay: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
              SnackBar(
                content: Text(
                  "Congratulations! You've completed Day ${widget.selectedDay}.",
                ),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                backgroundColor: TColor.primaryColor1,
                duration: Duration(seconds: 2),
              ),
            )
            .closed
            .then((_) {
          Navigator.pop(context);
        });
      }
    }
  }

  void _togglePlayPause() {
    setState(() {
      if (_videoController?.value.isPlaying != _isVideoPlaying) {
        if (mounted) {
          setState(() {
            _isVideoPlaying = _videoController?.value.isPlaying ?? false;
          });
        }
      }
    });
  }

  void _openChatWithDoctor() {
    // Navigator.push(
    //   context,
    //   PageRouteBuilder(
    //     pageBuilder: (context, animation, secondaryAnimation) => ChatScreen(
    //       doctorName: widget.plan["doctor"],
    //       doctorImage: widget.plan["image"],
    //     ),
    //     transitionsBuilder: (context, animation, secondaryAnimation, child) {
    //       const begin = Offset(1.0, 0.0);
    //       const end = Offset.zero;
    //       const curve = Curves.easeInOutCubic;

    //       var tween =
    //           Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
    //       var offsetAnimation = animation.drive(tween);

    //       return SlideTransition(position: offsetAnimation, child: child);
    //     },
    //   ),
    // );
  }

  Widget _buildProgressNodes() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(
        exercises.length,
        (index) => TweenAnimationBuilder<double>(
          tween: Tween<double>(
            begin: 0.0,
            end: index <= currentExerciseIndex ? 1.0 : 0.0,
          ),
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index <= currentExerciseIndex
                    ? TColor.primaryColor1
                    : TColor.lightGray,
                boxShadow: index <= currentExerciseIndex
                    ? [
                        BoxShadow(
                          color: TColor.primaryColor1.withOpacity(0.3),
                          blurRadius: 4.0 * value,
                          spreadRadius: 1.0 * value,
                        ),
                      ]
                    : null,
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (exercises.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Rehabilitation Workout - Day ${widget.selectedDay}"),
          backgroundColor: TColor.primaryColor1,
          foregroundColor: TColor.white,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
                  "Your doctor will add exercises for this day soon. Please check back later.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: TColor.gray,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text("Go Back"),
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
        ),
      );
    }

    final currentExercise = exercises[currentExerciseIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text("Rehabilitation Workout - Day ${widget.selectedDay}"),
        backgroundColor: TColor.primaryColor1,
        foregroundColor: TColor.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (context) => _buildInfoSheet(),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main Content
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  TColor.primaryColor1.withOpacity(0.1),
                  Colors.white,
                ],
              ),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Day and Week Number with animated card
                    _buildHeaderCard(),
                    SizedBox(height: 20),

                    // Progress Bar with Nodes
                    Column(
                      children: [
                        AnimatedBuilder(
                          animation: _progressAnimation,
                          builder: (context, child) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: _progressAnimation.value,
                                backgroundColor: TColor.lightGray,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    TColor.primaryColor1),
                                minHeight: 8,
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 10),
                        _buildProgressNodes(),
                      ],
                    ),
                    SizedBox(height: 15),

                    // Instructive Video with rounded corners and controls
                    _buildVideoPlayer(currentExercise),
                    SizedBox(height: 17),

                    // Exercise Card with details and animations
                    _buildExerciseCard(currentExercise),
                    SizedBox(height: 17),

                    // Bottom Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: goToNextExercise,
                            icon: Icon(
                                currentExerciseIndex < exercises.length - 1
                                    ? Icons.arrow_forward
                                    : Icons.check_circle_outline),
                            label: Text(
                              currentExerciseIndex < exercises.length - 1
                                  ? "Next Exercise"
                                  : "Finish Day ${widget.selectedDay}",
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: TColor.primaryColor2,
                              foregroundColor: TColor.white,
                              padding: EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Completion Animation Overlay
          if (_showCompletionAnimation)
            Container(
              color: Colors.black54,
              child: Center(
                child: Image.asset(
                  'assets/img/celebration.jpg',
                  width: 300,
                  height: 300,
                  fit: BoxFit.contain,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  TColor.primaryColor1,
                  TColor.primaryColor2,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: TColor.primaryColor1.withOpacity(0.3),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Day ${widget.selectedDay}, Week ${widget.selectedWeek}",
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: TColor.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "${widget.plan["injury"]} (${widget.plan["severity"]})",
                        style: TextStyle(
                          fontSize: 14,
                          color: TColor.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.healing,
                    color: TColor.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideoPlayer(Map<String, dynamic> exercise) {
    return Hero(
      tag: "video_${exercise["name"]}",
      child: AnimatedContainer(
        duration: Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            alignment: Alignment.center,
            children: [
              _videoController?.value.isInitialized == true
                  ? AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: VideoPlayer(_videoController!),
                    )
                  : Container(
                      height: 170,
                      decoration: BoxDecoration(
                        color: TColor.lightGray,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: TColor.primaryColor1,
                        ),
                      ),
                    ),
              // Video Controls
              if (_videoController?.value.isInitialized == true)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _togglePlayPause,
                    child: AnimatedOpacity(
                      opacity: _isVideoPlaying ? 0.0 : 1.0,
                      duration: Duration(milliseconds: 300),
                      child: Container(
                        color: Colors.black26,
                        child: Center(
                          child: Icon(
                            _isVideoPlaying
                                ? Icons.pause_circle
                                : Icons.play_circle,
                            color: Colors.white,
                            size: 51,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              // Video Progress Indicator
              if (_videoController?.value.isInitialized == true)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: VideoProgressIndicator(
                    _videoController!,
                    allowScrubbing: true,
                    padding: EdgeInsets.symmetric(vertical: 2, horizontal: 0),
                    colors: VideoProgressColors(
                      playedColor: TColor.primaryColor1,
                      bufferedColor: TColor.lightGray,
                      backgroundColor: Colors.white.withOpacity(0.3),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseCard(Map<String, dynamic> exercise) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: exercise["color"].withOpacity(0.4),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: exercise["color"].withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exercise["name"],
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: TColor.black,
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: exercise["color"].withOpacity(0.3),
                                borderRadius: BorderRadius.circular(17),
                              ),
                              child: Text(
                                exercise.containsKey("duration")
                                    ? "${exercise["sets"]} sets of ${exercise["duration"]}"
                                    : "${exercise["sets"]} sets of ${exercise["reps"]} reps",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: TColor.black.withOpacity(0.7),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 43,
                        height: 43,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: exercise["color"].withOpacity(0.2),
                        ),
                        child: Icon(
                          _getExerciseIcon(exercise["name"]),
                          color: TColor.primaryColor1,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    exercise["description"],
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: TColor.gray,
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildTipsSection(exercise),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getExerciseIcon(String exerciseName) {
    switch (exerciseName.toLowerCase()) {
      case "push-ups":
        return Icons.fitness_center;
      case "squats":
        return Icons.arrow_downward;
      case "plank":
        return Icons.straighten;
      default:
        return Icons.directions_run;
    }
  }

  Widget _buildTipsSection(Map<String, dynamic> exercise) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: TColor.lightGray.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: TColor.lightGray,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: TColor.primaryColor2,
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              _getExerciseTip(exercise["name"]),
              style: TextStyle(
                fontSize: 12,
                color: TColor.black.withOpacity(0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getExerciseTip(String exerciseName) {
    switch (exerciseName.toLowerCase()) {
      case "push-ups":
        return "Keep your core tight and body straight. Lower until your chest nearly touches the ground.";
      case "squats":
        return "Keep weight in your heels and knees aligned with toes. Lower until thighs are parallel to the ground.";
      case "plank":
        return "Keep your body in a straight line from head to heels. Don't let your hips sag or rise.";
      default:
        return "Focus on proper form and controlled movements for maximum benefit.";
    }
  }

  Widget _buildInfoSheet() {
    return Container(
      padding: EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(17),
          topRight: Radius.circular(17),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 4,
            decoration: BoxDecoration(
              color: TColor.lightGray,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          SizedBox(height: 20),
          Text(
            "Rehabilitation Plan Info",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: TColor.black,
            ),
          ),
          SizedBox(height: 20),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: TColor.primaryColor1.withOpacity(0.2),
              child: Icon(
                Icons.healing,
                color: TColor.primaryColor1,
              ),
            ),
            title: Text("Injury"),
            subtitle: Text("${widget.plan["injury"]}"),
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: TColor.primaryColor1.withOpacity(0.2),
              child: Icon(
                Icons.assessment,
                color: TColor.primaryColor1,
              ),
            ),
            title: Text("Severity"),
            subtitle: Text("${widget.plan["severity"]}"),
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: TColor.primaryColor1.withOpacity(0.2),
              child: Icon(
                Icons.person,
                color: TColor.primaryColor1,
              ),
            ),
            title: Text("Doctor"),
            subtitle: Text("${widget.plan["doctor"]}"),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: TColor.primaryColor1,
              foregroundColor: TColor.white,
              minimumSize: Size(double.infinity, 43),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text("Close"),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}
