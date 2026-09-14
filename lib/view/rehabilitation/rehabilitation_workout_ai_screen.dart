import 'package:flutter/material.dart';
import 'package:physiotherapy/common/color_extension.dart';
import 'package:video_player/video_player.dart';

class RehabilitationWorkoutAIScreen extends StatefulWidget {
  final List<Map<String, dynamic>> exercises;
  final String injuryType;
  final String planType;

  const RehabilitationWorkoutAIScreen({
    super.key,
    required this.exercises,
    required this.injuryType,
    required this.planType,
  });

  @override
  _RehabilitationWorkoutAIScreenState createState() =>
      _RehabilitationWorkoutAIScreenState();
}

class _RehabilitationWorkoutAIScreenState
    extends State<RehabilitationWorkoutAIScreen>
    with SingleTickerProviderStateMixin {
  int currentExerciseIndex = 0;
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

    if (widget.exercises.isNotEmpty) {
      setState(() {
        _progressAnimation = Tween<double>(
          begin: 0,
          end: (currentExerciseIndex + 1) / widget.exercises.length,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeInOut,
        ));
        _isLoading = false;
      });
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> goToNextExercise() async {
    if (currentExerciseIndex < widget.exercises.length - 1) {
      _animationController.reset();
      setState(() {
        currentExerciseIndex++;
        _videoController?.dispose();
        if (widget.exercises.isNotEmpty) {
          _progressAnimation = Tween<double>(
            begin: currentExerciseIndex / widget.exercises.length,
            end: (currentExerciseIndex + 1) / widget.exercises.length,
          ).animate(CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ));
        }
      });
      _animationController.forward();
    } else {
      setState(() {
        _showCompletionAnimation = true;
      });

      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _showCompletionAnimation = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Congratulations! You've completed your workout.",
              ),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              backgroundColor: TColor.primaryColor1,
            ),
          );
          Navigator.pop(context);
        }
      });
    }
  }

  void _togglePlayPause() {
    setState(() {
      if (_videoController?.value.isPlaying ?? false) {
        _videoController?.pause();
      } else {
        _videoController?.play();
      }
    });
  }

  Widget _buildProgressNodes() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(
        widget.exercises.length,
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
    if (widget.exercises.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Workout"),
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
                "No Exercises Available",
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
                  "Please check back later for exercises.",
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

    final currentExercise = widget.exercises[currentExerciseIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text("Rehabilitation Workout"),
        backgroundColor: TColor.primaryColor1,
        foregroundColor: TColor.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
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
                    // Injury Type and Plan Type
                    Container(
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
                                  widget.injuryType,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: TColor.white,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  widget.planType,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: TColor.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.healing,
                              color: TColor.white,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                    SizedBox(height: 24),

                    // Exercise Card
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: TColor.primaryColor1.withOpacity(0.1),
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentExercise["name"],
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: TColor.black,
                            ),
                          ),
                          SizedBox(height: 16),
                          if (currentExercise["description"] != null &&
                              currentExercise["description"].isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text(
                                currentExercise["description"],
                                style: TextStyle(
                                  fontSize: 15,
                                  color: TColor.gray,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _buildInfoChip(
                                      "${currentExercise["sets"]} sets",
                                      Icons.repeat),
                                  SizedBox(width: 8),
                                  _buildInfoChip(
                                      "${currentExercise["reps"]} reps",
                                      Icons.fitness_center),
                                ],
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  _buildInfoChip(
                                      "${currentExercise["duration"]}",
                                      Icons.timer),
                                  SizedBox(width: 8),
                                  _buildInfoChip(
                                      "${currentExercise["difficulty"]}",
                                      Icons.trending_up),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          if (currentExercise["equipment"] != null &&
                              currentExercise["equipment"].isNotEmpty)
                            _buildDetailSection(
                              "Equipment",
                              currentExercise["equipment"].join(", "),
                              Icons.hardware,
                            ),
                          SizedBox(height: 16),
                          if (currentExercise["instructions"] != null &&
                              currentExercise["instructions"].isNotEmpty)
                            _buildDetailSection(
                              "Instructions",
                              currentExercise["instructions"].join("\n"),
                              Icons.lightbulb_outline,
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: 40),

                    // Next Exercise Button
                    ElevatedButton.icon(
                      onPressed: goToNextExercise,
                      icon: Icon(
                          currentExerciseIndex < widget.exercises.length - 1
                              ? Icons.arrow_forward
                              : Icons.check_circle_outline),
                      label: Text(
                        currentExerciseIndex < widget.exercises.length - 1
                            ? "Next Exercise"
                            : "Complete Workout",
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TColor.primaryColor2,
                        foregroundColor: TColor.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        minimumSize: Size(double.infinity, 50),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
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

  Widget _buildInfoChip(String text, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: TColor.primaryColor1.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: TColor.primaryColor1),
          SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: TColor.primaryColor1,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, String content, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: TColor.primaryColor1),
            SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: TColor.black,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            fontSize: 14,
            color: TColor.gray,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
