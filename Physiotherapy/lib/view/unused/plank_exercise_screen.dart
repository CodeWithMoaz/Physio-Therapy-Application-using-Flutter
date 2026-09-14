// import 'dart:async';
// import 'dart:typed_data';
// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:camera/camera.dart';

// import 'package:web_socket_channel/web_socket_channel.dart';
// import 'package:physiotherapy/common/color_extension.dart';
// import 'package:image/image.dart' as img;
// import 'package:physiotherapy/view/rehabilitation/plank_helper.dart';

// class PlankExerciseScreen extends StatefulWidget {
//   final Map<String, dynamic> exercise;

//   const PlankExerciseScreen({
//     Key? key,
//     required this.exercise,
//   }) : super(key: key);

//   @override
//   _PlankExerciseScreenState createState() => _PlankExerciseScreenState();
// }

// class _PlankExerciseScreenState extends State<PlankExerciseScreen>
//     with TickerProviderStateMixin {
//   // Camera related variables
//   CameraController? _cameraController;
//   List<CameraDescription>? _cameras;
//   bool _isCameraInitialized = false;
//   bool _isAnalysisRunning = false;
//   CameraLensDirection _currentCameraDirection = CameraLensDirection.back;

//   // Web socket and service
//   WebSocketChannel? _channel;

//   // Exercise state
//   bool exerciseCompleted = false;
//   Map<String, dynamic>? _analysisResults;
//   Widget? _annotatedImageWidget;
//   String _feedbackText = '';
//   int _correctTime = 0;
//   int _incorrectTime = 0;

//   // Feedback and animation
//   late AnimationController _feedbackAnimationController;
//   late Animation<double> _feedbackAnimation;
//   late AnimationController _pulseAnimationController;
//   late Animation<double> _pulseAnimation;

//   // Exercise tracking variables
//   int currentSet = 1;
//   int totalSets = 0;
//   bool isTimedExercise = false;
//   int durationInSeconds = 0;
//   int remainingSeconds = 0;
//   Timer? _exerciseTimer;

//   // Camera streaming
//   bool _processingFrame = false;
//   int _frameCount = 0;
//   int _processedFrameCount = 0;

//   // Form status
//   bool _isCorrectForm = false;
//   List<Map<String, dynamic>> _activeCorrections = [];

//   // Camera stream
//   StreamController<CameraImage>? _cameraStreamController;
//   bool _isCameraStreaming = false;

//   // Performance tracking
//   DateTime? _lastFrameTime;
//   int _framesPerSecond = 0;

//   // Image buffer
//   Uint8List? _lastProcessedImage;

//   // Error handling
//   bool _hasConnectionError = false;
//   String _errorMessage = '';

//   // UI state
//   bool _showFeedbackPanel = true; // Changed to true by default
//   final ScrollController _feedbackScrollController = ScrollController();
//   bool _isFullScreenCamera = false;

//   @override
//   void initState() {
//     super.initState();

//     // Setup animation controllers
//     _feedbackAnimationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 300),
//     );

//     _feedbackAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(
//         parent: _feedbackAnimationController,
//         curve: Curves.easeInOut,
//       ),
//     );

//     _pulseAnimationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1500),
//     )..repeat(reverse: true);

//     _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
//       CurvedAnimation(
//         parent: _pulseAnimationController,
//         curve: Curves.easeInOut,
//       ),
//     );

//     _initCamera();

//     // Initialize exercise parameters
//     totalSets = widget.exercise["sets"] ?? 3;

//     // Check if it's a duration-based exercise
//     if (widget.exercise.containsKey("duration")) {
//       isTimedExercise = true;
//       // Parse duration (assuming format like "30 seconds")
//       String durationStr = widget.exercise["duration"];
//       try {
//         durationInSeconds = int.parse(durationStr.split(' ')[0]);
//       } catch (e) {
//         // Default duration if parsing fails
//         durationInSeconds = 30;
//       }
//       remainingSeconds = durationInSeconds;
//     } else {
//       // Default to 30 seconds for plank if not specified
//       isTimedExercise = true;
//       durationInSeconds = 30;
//       remainingSeconds = durationInSeconds;
//     }
//   }

//   Future<void> _initCamera() async {
//     try {
//       _cameras = await availableCameras();

//       if (_cameras != null && _cameras!.isNotEmpty) {
//         await _setupCamera();
//       }
//     } catch (e) {
//       setState(() {
//         _hasConnectionError = true;
//         _errorMessage = 'Error initializing camera: $e';
//       });
//       print('Error initializing camera: $e');
//     }
//   }

//   Future<void> _setupCamera() async {
//     if (_cameras == null || _cameras!.isEmpty) return;

//     // Find camera with the desired direction
//     final selectedCamera = _cameras!.firstWhere(
//       (camera) => camera.lensDirection == _currentCameraDirection,
//       orElse: () => _cameras!.first,
//     );

//     // Dispose the current controller if it exists
//     if (_cameraController != null) {
//       await _cameraController!.dispose();
//     }

//     _cameraController = CameraController(
//       selectedCamera,
//       ResolutionPreset.medium,
//       enableAudio: false,
//       imageFormatGroup: ImageFormatGroup.yuv420,
//     );

//     try {
//       await _cameraController!.initialize();

//       if (mounted) {
//         setState(() {
//           _isCameraInitialized = true;
//         });
//       }
//     } catch (e) {
//       print('Error initializing camera: $e');
//       setState(() {
//         _hasConnectionError = true;
//         _errorMessage = 'Error initializing camera: $e';
//       });
//     }
//   }

//   Future<void> _toggleCameraDirection() async {
//     if (_isAnalysisRunning) {
//       // Stop analysis before switching camera
//       _stopRealTimeAnalysis();
//     }

//     // Toggle camera direction
//     _currentCameraDirection =
//         _currentCameraDirection == CameraLensDirection.back
//             ? CameraLensDirection.front
//             : CameraLensDirection.back;

//     setState(() {
//       _isCameraInitialized = false;
//     });

//     // Setup camera with new direction
//     await _setupCamera();
//   }

//   void _startRealTimeAnalysis() {
//     if (!_isCameraInitialized || _isAnalysisRunning) return;

//     try {
//       // First start camera streaming - do this separately from WebSocket connection
//       _startCameraStream();

//       setState(() {
//         _isAnalysisRunning = true;
//         _feedbackText = 'Starting analysis...';
//         _showFeedbackPanel = true;
//       });

//       // Try to connect to WebSocket (with timeout)
//       Future.microtask(() async {
//         try {
//           // Add a timeout to prevent hanging if server is unreachable
//           WebSocketChannel? channel;

//           if (_channel != null) {
//             // Listen for responses from the server
//             _channel!.stream.listen(
//               (message) {
//                 _processingFrame = false;
//                 _processedFrameCount++;

//                 final data = message is String ? message : '';
//                 Map<String, dynamic> responseData = {};

//                 try {
//                   responseData = Map<String, dynamic>.from(
//                       message is String ? jsonDecode(message) : {});

//                   if (mounted) {
//                     setState(() {
//                       if (responseData.containsKey('results')) {
//                         _analysisResults = responseData['results'];

//                         // Update form status
//                         _isCorrectForm =
//                             _analysisResults!['is_correct'] ?? false;

//                         // Update feedback
//                         _activeCorrections = [];
//                         if (_analysisResults!['feedback'] != null &&
//                             _analysisResults!['feedback'].isNotEmpty) {
//                           // Store all active corrections
//                           for (var correction
//                               in _analysisResults!['feedback']) {
//                             _activeCorrections.add(correction);
//                           }

//                           // Set main feedback text from first correction
//                           final firstFeedback =
//                               _analysisResults!['feedback'][0];
//                           _feedbackText =
//                               '${firstFeedback['message']} (${firstFeedback['angle']}°)';

//                           // Trigger feedback animation
//                           _feedbackAnimationController.reset();
//                           _feedbackAnimationController.forward();
//                         } else {
//                           _feedbackText = 'Good form!';
//                         }

//                         // Update time stats
//                         if (responseData['stats'] != null) {
//                           _correctTime =
//                               (responseData['stats']['correct_time'] as double)
//                                   .round();
//                           _incorrectTime = (responseData['stats']
//                                   ['incorrect_time'] as double)
//                               .round();
//                         }
//                       }

//                       // Calculate FPS
//                       if (_lastFrameTime != null) {
//                         final now = DateTime.now();
//                         final duration = now.difference(_lastFrameTime!);
//                         if (duration.inMilliseconds > 0) {
//                           _framesPerSecond =
//                               (1000 / duration.inMilliseconds).round();
//                         }
//                         _lastFrameTime = now;
//                       } else {
//                         _lastFrameTime = DateTime.now();
//                       }

//                       // Clear any previous error state
//                       _hasConnectionError = false;
//                       _errorMessage = '';
//                     });
//                   }
//                 } catch (e) {
//                   print('Error processing server response: $e');
//                   _handleError('Error processing response: $e');
//                 }
//               },
//               onError: (error) {
//                 print('WebSocket error: $error');
//                 _handleError('Connection error: $error');
//                 _useFallbackMode();
//               },
//               onDone: () {
//                 print('WebSocket connection closed');
//                 _handleError('Connection closed unexpectedly');
//                 _useFallbackMode();
//               },
//             );
//           } else {
//             // Failed to connect to WebSocket
//             _handleError('Could not connect to server');
//             _useFallbackMode();
//           }
//         } catch (e) {
//           print('Error with WebSocket setup: $e');
//           _handleError('Connection setup error: $e');
//           _useFallbackMode();
//         }
//       });

//       if (isTimedExercise) {
//         _startExerciseTimer();
//       }
//     } catch (e) {
//       print('Error starting real-time analysis: $e');
//       _handleError('Failed to start analysis: $e');

//       // Show error message to user
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error starting exercise analysis: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//       _stopRealTimeAnalysis();
//     }
//   }

//   // Fallback to use when WebSocket is unavailable
//   void _useFallbackMode() {
//     if (mounted) {
//       setState(() {
//         _feedbackText = 'Using local camera mode (server unavailable)';
//         _isCorrectForm = true; // Default to true in fallback mode
//       });

//       // Setup a timer to update time stats even without server
//       Timer.periodic(Duration(seconds: 1), (timer) {
//         if (!_isAnalysisRunning) {
//           timer.cancel();
//           return;
//         }

//         if (mounted) {
//           setState(() {
//             _correctTime += 1;
//           });
//         }
//       });
//     }
//   }

//   void _handleError(String message) {
//     if (mounted) {
//       setState(() {
//         _hasConnectionError = true;
//         _errorMessage = message;
//       });
//     }
//   }

//   void _startCameraStream() {
//     if (_cameraController == null || !_cameraController!.value.isInitialized) {
//       return;
//     }

//     try {
//       _cameraStreamController = StreamController<CameraImage>();

//       // Start image stream from camera with simpler approach
//       _cameraController!.startImageStream((CameraImage image) {
//         // Update FPS counter even without server connection
//         final now = DateTime.now();
//         if (_lastFrameTime != null) {
//           final duration = now.difference(_lastFrameTime!);
//           if (mounted && duration.inMilliseconds > 0) {
//             setState(() {
//               _framesPerSecond = (1000 / duration.inMilliseconds).round();
//             });
//           }
//         }
//         _lastFrameTime = now;

//         // Only process frames if we have an active WebSocket channel
//       }).catchError((error) {
//         print('Error starting camera stream: $error');
//         _handleError('Camera error: $error');

//         // Handle camera errors gracefully
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text('Camera error: $error'),
//               backgroundColor: Colors.red,
//             ),
//           );
//         }
//       });

//       _isCameraStreaming = true;
//     } catch (e) {
//       print('Critical error starting camera stream: $e');
//       _handleError('Critical camera error: $e');

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to start camera: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   void _startExerciseTimer() {
//     remainingSeconds = durationInSeconds;
//     _exerciseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       setState(() {
//         if (remainingSeconds > 0) {
//           remainingSeconds--;
//         } else {
//           timer.cancel();
//           // Set is complete, check if there are more sets
//           _completeCurrentSet();
//         }
//       });
//     });
//   }

//   void _completeCurrentSet() {
//     _exerciseTimer?.cancel();

//     setState(() {
//       if (currentSet < totalSets) {
//         // Move to next set
//         currentSet++;

//         if (isTimedExercise) {
//           remainingSeconds = durationInSeconds;
//         }

//         // Add a small pause between sets
//         _stopRealTimeAnalysis();
//       } else {
//         // All sets completed
//         exerciseCompleted = true;
//         _stopRealTimeAnalysis();
//       }
//     });
//   }

//   void _stopRealTimeAnalysis() {
//     // Stop camera streaming
//     if (_isCameraStreaming && _cameraController != null) {
//       _cameraController!.stopImageStream();
//       _isCameraStreaming = false;
//     }

//     // Close stream controller
//     _cameraStreamController?.close();
//     _cameraStreamController = null;

//     _channel?.sink.close();
//     _exerciseTimer?.cancel();

//     setState(() {
//       _isAnalysisRunning = false;
//       _channel = null;
//       _processingFrame = false;
//       _lastFrameTime = null;
//       _lastProcessedImage = null;
//       _showFeedbackPanel = false;
//     });
//   }

//   void completeExercise() {
//     Navigator.pop(context, true); // Return true to indicate completion
//   }

//   void quitExercise() {
//     Navigator.pop(context, false); // Return false to indicate not completed
//   }

//   @override
//   void dispose() {
//     _stopRealTimeAnalysis();
//     _cameraController?.dispose();
//     _exerciseTimer?.cancel();
//     _feedbackAnimationController.dispose();
//     _pulseAnimationController.dispose();
//     _feedbackScrollController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//       onWillPop: () async {
//         quitExercise();
//         return false; // Prevent default back behavior
//       },
//       child: Scaffold(
//         extendBodyBehindAppBar: true,
//         appBar: AppBar(
//           title: Text(widget.exercise["name"]),
//           backgroundColor: TColor.primaryColor1.withOpacity(0.8),
//           foregroundColor: TColor.white,
//           leading: IconButton(
//             icon: const Icon(Icons.arrow_back),
//             onPressed: quitExercise,
//           ),
//           elevation: 0,
//           centerTitle: true,
//           actions: [
//             IconButton(
//               icon: Icon(_isFullScreenCamera
//                   ? Icons.fullscreen_exit
//                   : Icons.fullscreen),
//               onPressed: () {
//                 setState(() {
//                   _isFullScreenCamera = !_isFullScreenCamera;
//                   _showFeedbackPanel = !_isFullScreenCamera;
//                 });
//               },
//             ),
//           ],
//         ),
//         body: exerciseCompleted
//             ? _buildCompletionScreen()
//             : _buildExerciseScreen(),
//       ),
//     );
//   }

//   Widget _buildCompletionScreen() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//           colors: [
//             TColor.primaryColor1.withOpacity(0.1),
//             Colors.white,
//           ],
//         ),
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           // Trophy icon with animation
//           ScaleTransition(
//             scale: _pulseAnimation,
//             child: Container(
//               padding: const EdgeInsets.all(25),
//               decoration: BoxDecoration(
//                 color: Colors.amber.withOpacity(0.2),
//                 shape: BoxShape.circle,
//               ),
//               child: const Icon(
//                 Icons.emoji_events,
//                 color: Colors.amber,
//                 size: 100,
//               ),
//             ),
//           ),
//           const SizedBox(height: 30),
//           Text(
//             "Great Job!",
//             style: TextStyle(
//               fontSize: 30,
//               fontWeight: FontWeight.bold,
//               color: TColor.black,
//             ),
//           ),
//           const SizedBox(height: 15),
//           Text(
//             "You've completed ${widget.exercise["name"]}",
//             style: TextStyle(
//               fontSize: 18,
//               color: TColor.gray,
//             ),
//           ),
//           const SizedBox(height: 25),

//           // Stats summary
//           Container(
//             padding: const EdgeInsets.all(20),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(16),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.08),
//                   blurRadius: 10,
//                   offset: const Offset(0, 5),
//                 ),
//               ],
//             ),
//             child: Column(
//               children: [
//                 Text(
//                   "Exercise Summary",
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: TColor.black,
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   children: [
//                     _buildSummaryItem(
//                       "Total Time",
//                       "${_correctTime + _incorrectTime}s",
//                       Icons.timer,
//                       TColor.primaryColor1,
//                     ),
//                     _buildSummaryItem(
//                       "Correct Form",
//                       "${_correctTime}s",
//                       Icons.check_circle,
//                       Colors.green,
//                     ),
//                     _buildSummaryItem(
//                       "Sets Completed",
//                       "$currentSet/$totalSets",
//                       Icons.fitness_center,
//                       TColor.primaryColor2,
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 40),
//           ElevatedButton(
//             onPressed: completeExercise,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: TColor.primaryColor2,
//               foregroundColor: TColor.white,
//               padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(30),
//               ),
//               elevation: 5,
//               shadowColor: TColor.primaryColor2.withOpacity(0.5),
//             ),
//             child: const Text(
//               "Return to Workout",
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSummaryItem(
//       String title, String value, IconData icon, Color color) {
//     return Column(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(12),
//           decoration: BoxDecoration(
//             color: color.withOpacity(0.1),
//             shape: BoxShape.circle,
//           ),
//           child: Icon(
//             icon,
//             color: color,
//             size: 24,
//           ),
//         ),
//         const SizedBox(height: 8),
//         Text(
//           value,
//           style: TextStyle(
//             fontSize: 20,
//             fontWeight: FontWeight.bold,
//             color: color,
//           ),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           title,
//           style: TextStyle(
//             fontSize: 12,
//             color: TColor.gray,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildExerciseScreen() {
//     final screenHeight = MediaQuery.of(context).size.height;
//     final screenWidth = MediaQuery.of(context).size.width;

//     return Stack(
//       children: [
//         // Main content layout
//         Column(
//           children: [
//             // Exercise Progress Header
//             if (!_isFullScreenCamera) _buildProgressHeader(),

//             // Main content (Camera + Feedback)
//             _isFullScreenCamera
//                 ? Expanded(child: _buildCameraArea())
//                 : Container(
//                     height: screenHeight * 0.6, // Increased space for camera
//                     child: _buildCameraArea(),
//                   ),

//             // Bottom section with feedback and stats
//             if (!_isFullScreenCamera)
//               Expanded(
//                 child: Container(
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.only(
//                       topLeft: Radius.circular(30),
//                       topRight: Radius.circular(30),
//                     ),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.05),
//                         blurRadius: 10,
//                         offset: Offset(0, -5),
//                       ),
//                     ],
//                   ),
//                   child: Column(
//                     children: [
//                       // Handle indicator
//                       Container(
//                         margin: EdgeInsets.only(top: 10, bottom: 10),
//                         width: 50,
//                         height: 5,
//                         decoration: BoxDecoration(
//                           color: Colors.grey.withOpacity(0.3),
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                       ),

//                       // Time stats
//                       Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 20),
//                         child: Row(
//                           children: [
//                             Expanded(
//                               child: PlankHelper.buildStatCard(
//                                 "Correct Form",
//                                 _correctTime,
//                                 Icons.check_circle,
//                                 Colors.green,
//                               ),
//                             ),
//                             SizedBox(width: 15),
//                             Expanded(
//                               child: PlankHelper.buildStatCard(
//                                 "Incorrect Form",
//                                 _incorrectTime,
//                                 Icons.warning_amber_rounded,
//                                 Colors.red,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),

//                       SizedBox(height: 15),

//                       // Feedback panel
//                       Expanded(
//                         child: _activeCorrections.isEmpty && !_isAnalysisRunning
//                             ? Center(
//                                 child: Container(
//                                   padding: EdgeInsets.all(20),
//                                   child: Text(
//                                     "Start the exercise to get real-time feedback on your plank form",
//                                     textAlign: TextAlign.center,
//                                     style: TextStyle(
//                                       color: TColor.gray,
//                                       fontSize: 16,
//                                     ),
//                                   ),
//                                 ),
//                               )
//                             : _isAnalysisRunning
//                                 ? Padding(
//                                     padding: const EdgeInsets.symmetric(
//                                         horizontal: 20),
//                                     child: Column(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         Padding(
//                                           padding: const EdgeInsets.only(
//                                               left: 10, bottom: 8),
//                                           child: Text(
//                                             "Form Feedback",
//                                             style: TextStyle(
//                                               fontSize: 18,
//                                               fontWeight: FontWeight.bold,
//                                               color: TColor.black,
//                                             ),
//                                           ),
//                                         ),
//                                         Expanded(
//                                           child: _activeCorrections.isEmpty
//                                               ? Center(
//                                                   child: Container(
//                                                     padding: EdgeInsets.all(15),
//                                                     decoration: BoxDecoration(
//                                                       color: Colors.green
//                                                           .withOpacity(0.1),
//                                                       borderRadius:
//                                                           BorderRadius.circular(
//                                                               15),
//                                                       border: Border.all(
//                                                         color: Colors.green
//                                                             .withOpacity(0.3),
//                                                       ),
//                                                     ),
//                                                     child: Text(
//                                                       "Perfect form! Keep it up!",
//                                                       style: TextStyle(
//                                                         color: Colors.green,
//                                                         fontWeight:
//                                                             FontWeight.bold,
//                                                       ),
//                                                     ),
//                                                   ),
//                                                 )
//                                               : ListView.builder(
//                                                   padding: EdgeInsets.zero,
//                                                   controller:
//                                                       _feedbackScrollController,
//                                                   shrinkWrap: true,
//                                                   itemCount:
//                                                       _activeCorrections.length,
//                                                   itemBuilder:
//                                                       (context, index) {
//                                                     final correction =
//                                                         _activeCorrections[
//                                                             index];
//                                                     return PlankHelper
//                                                         .buildFeedbackCard(
//                                                       "${correction['message']} (${correction['angle']}°)",
//                                                       color: Colors.red,
//                                                       isHighlighted: index == 0,
//                                                     );
//                                                   },
//                                                 ),
//                                         ),
//                                       ],
//                                     ),
//                                   )
//                                 : Container(),
//                       ),

//                       // Controls
//                       _buildControlsBar(),
//                     ],
//                   ),
//                 ),
//               ),
//           ],
//         ),

//         // Camera switch button
//         Positioned(
//           bottom: _isFullScreenCamera ? 85 : screenHeight * 0.62,
//           right: 20,
//           child: FloatingActionButton(
//             heroTag: "switchCamera",
//             backgroundColor: Colors.white.withOpacity(0.8),
//             foregroundColor: TColor.primaryColor1,
//             mini: true,
//             elevation: 4,
//             child: const Icon(Icons.flip_camera_ios),
//             onPressed: _toggleCameraDirection,
//           ),
//         ),

//         // Full screen controls when in fullscreen mode
//         if (_isFullScreenCamera)
//           Positioned(
//             bottom: 20,
//             left: 0,
//             right: 0,
//             child: Container(
//               padding: EdgeInsets.symmetric(horizontal: 20),
//               child: _buildControlsBar(),
//             ),
//           ),

//         // Help button
//         Positioned(
//           top: 70,
//           right: 15,
//           child: FloatingActionButton.small(
//             heroTag: "helpButton",
//             backgroundColor: Colors.white.withOpacity(0.8),
//             foregroundColor: TColor.primaryColor1,
//             elevation: 4,
//             child: const Icon(Icons.help_outline),
//             onPressed: _showHelpDialog,
//           ),
//         ),

//         // Connection error overlay
//         if (_hasConnectionError) _buildErrorOverlay(),
//       ],
//     );
//   }

//   Widget _buildCameraArea() {
//     return Stack(
//       children: [
//         // Camera Preview
//         _buildCameraPreview(),

//         // Overlay elements
//         if (_isAnalysisRunning) ...[
//           // Form Status Indicator
//           Positioned(
//             top: 20,
//             right: 20,
//             child: PlankHelper.buildFormIndicator(
//               _isCorrectForm,
//               _isCorrectForm ? "Good Form" : "Needs Correction",
//             ),
//           ),

//           // Timer Display (for timed exercises)
//           if (isTimedExercise)
//             Positioned(
//               top: 20,
//               left: 0,
//               right: 0,
//               child: Center(
//                 child: PlankHelper.buildTimerDisplay(
//                   remainingSeconds,
//                   durationInSeconds,
//                 ),
//               ),
//             ),

//           // Compact stats in fullscreen mode
//           if (_isFullScreenCamera)
//             Positioned(
//               top: 20,
//               left: 20,
//               child: _buildStatsOverlay(),
//             ),

//           // Feedback in fullscreen mode - more compact
//           if (_isFullScreenCamera && _activeCorrections.isNotEmpty)
//             Positioned(
//               bottom: 100,
//               left: 20,
//               right: 20,
//               child: Container(
//                 padding: EdgeInsets.all(15),
//                 decoration: BoxDecoration(
//                   color: Colors.black.withOpacity(0.7),
//                   borderRadius: BorderRadius.circular(15),
//                 ),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       "Corrections Needed:",
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 14,
//                       ),
//                     ),
//                     SizedBox(height: 8),
//                     ..._activeCorrections
//                         .take(2)
//                         .map((correction) => Padding(
//                               padding: const EdgeInsets.only(bottom: 5),
//                               child: Row(
//                                 children: [
//                                   Icon(Icons.warning_amber_rounded,
//                                       color: Colors.orange, size: 18),
//                                   SizedBox(width: 8),
//                                   Expanded(
//                                     child: Text(
//                                       "${correction['message']} (${correction['angle']}°)",
//                                       style: TextStyle(
//                                         color: Colors.white,
//                                         fontSize: 13,
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ))
//                         .toList(),
//                     if (_activeCorrections.length > 2)
//                       Text(
//                         "... and ${_activeCorrections.length - 2} more issues",
//                         style: TextStyle(
//                           color: Colors.white70,
//                           fontSize: 12,
//                           fontStyle: FontStyle.italic,
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//         ],
//       ],
//     );
//   }

//   Widget _buildProgressHeader() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
//       decoration: BoxDecoration(
//         color: TColor.primaryColor1,
//         borderRadius: const BorderRadius.vertical(
//           bottom: Radius.circular(20),
//         ),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 "Set",
//                 style: TextStyle(
//                   fontSize: 14,
//                   color: TColor.white.withOpacity(0.8),
//                 ),
//               ),
//               Text(
//                 "$currentSet of $totalSets",
//                 style: const TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white,
//                 ),
//               ),
//             ],
//           ),
//           if (isTimedExercise && !_isAnalysisRunning)
//             Row(
//               children: [
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.end,
//                   children: [
//                     Text(
//                       "Duration",
//                       style: TextStyle(
//                         fontSize: 14,
//                         color: TColor.white.withOpacity(0.8),
//                       ),
//                     ),
//                     Text(
//                       "$durationInSeconds sec",
//                       style: const TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(width: 10),
//                 const Icon(Icons.timer, color: Colors.white)
//               ],
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildCameraPreview() {
//     if (_isCameraInitialized && _cameraController != null) {
//       return Container(
//         width: double.infinity,
//         color: Colors.black,
//         child: _isAnalysisRunning && _annotatedImageWidget != null
//             ? AnimatedSwitcher(
//                 duration: Duration(milliseconds: 300),
//                 child: _annotatedImageWidget!,
//               )
//             : AspectRatio(
//                 aspectRatio: _cameraController!.value.aspectRatio,
//                 child: CameraPreview(_cameraController!),
//               ),
//       );
//     } else {
//       return Container(
//         color: Colors.black,
//         child: Center(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const CircularProgressIndicator(color: Colors.white),
//               const SizedBox(height: 20),
//               Text(
//                 "Initializing camera...",
//                 style: TextStyle(color: Colors.white, fontSize: 16),
//               ),
//             ],
//           ),
//         ),
//       );
//     }
//   }

//   Widget _buildStatsOverlay() {
//     return Container(
//       padding: const EdgeInsets.all(15),
//       decoration: BoxDecoration(
//         color: Colors.black.withOpacity(0.6),
//         borderRadius: BorderRadius.circular(15),
//         border: Border.all(
//           color: Colors.white.withOpacity(0.2),
//           width: 1,
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Container(
//                 height: 10,
//                 width: 10,
//                 decoration: BoxDecoration(
//                   color: Colors.green,
//                   borderRadius: BorderRadius.circular(5),
//                 ),
//               ),
//               const SizedBox(width: 8),
//               Text(
//                 "Correct: $_correctTime sec",
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 14,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           Row(
//             children: [
//               Container(
//                 height: 10,
//                 width: 10,
//                 decoration: BoxDecoration(
//                   color: Colors.red,
//                   borderRadius: BorderRadius.circular(5),
//                 ),
//               ),
//               const SizedBox(width: 8),
//               Text(
//                 "Incorrect: $_incorrectTime sec",
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 14,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ],
//           ),
//           if (_framesPerSecond > 0) ...[
//             const SizedBox(height: 8),
//             Row(
//               children: [
//                 const Icon(Icons.speed, color: Colors.white, size: 12),
//                 const SizedBox(width: 5),
//                 Text(
//                   "FPS: $_framesPerSecond",
//                   style: TextStyle(
//                     color: _framesPerSecond < 15 ? Colors.orange : Colors.white,
//                     fontSize: 14,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _buildErrorOverlay() {
//     return Container(
//       color: Colors.black.withOpacity(0.7),
//       width: double.infinity,
//       height: double.infinity,
//       child: Center(
//         child: Container(
//           margin: const EdgeInsets.all(30),
//           padding: const EdgeInsets.all(20),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(20),
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Icon(
//                 Icons.error_outline,
//                 color: Colors.red,
//                 size: 60,
//               ),
//               const SizedBox(height: 20),
//               Text(
//                 "Connection Error",
//                 style: TextStyle(
//                   fontSize: 22,
//                   fontWeight: FontWeight.bold,
//                   color: TColor.black,
//                 ),
//               ),
//               const SizedBox(height: 15),
//               Text(
//                 _errorMessage.isNotEmpty
//                     ? _errorMessage
//                     : "Failed to connect to the server. Please try again.",
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontSize: 16,
//                   color: TColor.gray,
//                 ),
//               ),
//               const SizedBox(height: 25),
//               ElevatedButton(
//                 onPressed: () {
//                   setState(() {
//                     _hasConnectionError = false;
//                     _errorMessage = '';
//                   });
//                   _stopRealTimeAnalysis();
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: TColor.primaryColor1,
//                   foregroundColor: Colors.white,
//                 ),
//                 child: const Text("Close"),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildControlsBar() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, -5),
//           ),
//         ],
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//         children: [
//           if (!_isAnalysisRunning)
//             Expanded(
//               child: ElevatedButton(
//                 onPressed: _startRealTimeAnalysis,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: TColor.primaryColor1,
//                   foregroundColor: TColor.white,
//                   padding: const EdgeInsets.symmetric(vertical: 15),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(15),
//                   ),
//                   elevation: 5,
//                   shadowColor: TColor.primaryColor1.withOpacity(0.5),
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Icon(Icons.play_arrow),
//                     const SizedBox(width: 8),
//                     Text(
//                       currentSet == 1
//                           ? "Start Exercise"
//                           : "Start Set $currentSet",
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 16,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             )
//           else
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 Expanded(
//                   child: ElevatedButton(
//                     onPressed: _stopRealTimeAnalysis,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.red,
//                       foregroundColor: TColor.white,
//                       padding: const EdgeInsets.symmetric(vertical: 15),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(15),
//                       ),
//                     ),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: const [
//                         Icon(Icons.stop),
//                         SizedBox(width: 8),
//                         Text(
//                           "Stop",
//                           style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             fontSize: 16,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 if (isTimedExercise && currentSet < totalSets)
//                   Container(
//                     margin: EdgeInsets.only(left: 10),
//                     child: ElevatedButton(
//                       onPressed: _completeCurrentSet,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.green,
//                         foregroundColor: TColor.white,
//                         padding: const EdgeInsets.symmetric(
//                             vertical: 15, horizontal: 15),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(15),
//                         ),
//                       ),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: const [
//                           Icon(Icons.skip_next),
//                           SizedBox(width: 8),
//                           Text(
//                             "Next Set",
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 16,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//         ],
//       ),
//     );
//   }

//   void _showHelpDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text("Plank Exercise Tips",
//             style: TextStyle(color: TColor.primaryColor1)),
//         content: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildHelpTip(
//                 "Keep your body straight from head to heels",
//                 Icons.straighten,
//               ),
//               _buildHelpTip(
//                 "Engage your core and glutes",
//                 Icons.fitness_center,
//               ),
//               _buildHelpTip(
//                 "Keep your head aligned with your spine",
//                 Icons.face,
//               ),
//               _buildHelpTip(
//                 "Breathe evenly throughout the exercise",
//                 Icons.air,
//               ),
//               _buildHelpTip(
//                 "Position your smartphone to capture your entire body from the side",
//                 Icons.phone_android,
//               ),
//               const SizedBox(height: 15),
//               const Divider(),
//               const SizedBox(height: 5),
//               _buildHelpTip(
//                 "The AI will analyze your form and provide real-time feedback",
//                 Icons.tips_and_updates,
//                 isHighlighted: true,
//               ),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child:
//                 Text("Got it!", style: TextStyle(color: TColor.primaryColor2)),
//           ),
//         ],
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(20),
//         ),
//         backgroundColor: Colors.white,
//         elevation: 10,
//       ),
//     );
//   }

//   Widget _buildHelpTip(String text, IconData icon,
//       {bool isHighlighted = false}) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 15),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Icon(
//             icon,
//             color: isHighlighted ? TColor.primaryColor2 : TColor.primaryColor1,
//             size: 22,
//           ),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Text(
//               text,
//               style: TextStyle(
//                 fontSize: 15,
//                 color: isHighlighted ? TColor.primaryColor2 : Colors.black87,
//                 fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
