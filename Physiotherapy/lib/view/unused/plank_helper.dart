// import 'package:flutter/material.dart';
// import 'package:physiotherapy/common/color_extension.dart';

// class PlankHelper {
//   // Feedback visualization with animated highlights
//   static Widget buildFeedbackVisual(
//       String bodyPart, double angle, bool isCorrect) {
//     final Color color = isCorrect ? Colors.green : Colors.red;
//     const double visualSize = 120.0;

//     return Container(
//       width: visualSize,
//       height: visualSize,
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(visualSize / 2),
//         border: Border.all(color: color, width: 2),
//       ),
//       child: Stack(
//         alignment: Alignment.center,
//         children: [
//           // Body part icon
//           _buildBodyPartIcon(bodyPart, color, visualSize * 0.4),

//           // Angle indicator
//           Positioned(
//             bottom: 20,
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
//               decoration: BoxDecoration(
//                 color: color.withOpacity(0.8),
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: Text(
//                 "${angle.toStringAsFixed(1)}°",
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 12,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Build feedback message card
//   static Widget buildFeedbackCard(String message,
//       {Color? color, bool isHighlighted = false}) {
//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 300),
//       margin: const EdgeInsets.only(bottom: 8),
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       decoration: BoxDecoration(
//         color: isHighlighted
//             ? (color ?? Colors.red).withOpacity(0.15)
//             : Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//             color: isHighlighted ? (color ?? Colors.red) : Colors.grey.shade300,
//             width: 1.5),
//         boxShadow: isHighlighted
//             ? [
//                 BoxShadow(
//                   color: (color ?? Colors.red).withOpacity(0.3),
//                   blurRadius: 8,
//                   offset: const Offset(0, 3),
//                 )
//               ]
//             : null,
//       ),
//       child: Row(
//         children: [
//           Icon(
//             isHighlighted ? Icons.warning_amber_rounded : Icons.info_outline,
//             color: isHighlighted ? (color ?? Colors.red) : Colors.grey,
//             size: 24,
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Text(
//               message,
//               style: TextStyle(
//                 color: isHighlighted ? (color ?? Colors.red) : Colors.black87,
//                 fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
//                 fontSize: 15,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Build timer display
//   static Widget buildTimerDisplay(int remainingSeconds, int totalSeconds) {
//     final double progress = remainingSeconds / totalSeconds;
//     final Color timerColor = remainingSeconds < 5
//         ? Colors.red
//         : (remainingSeconds < 10 ? Colors.orange : TColor.primaryColor1);

//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black12,
//             blurRadius: 10,
//             offset: const Offset(0, 5),
//           ),
//         ],
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text(
//             "Time Remaining",
//             style: TextStyle(
//               fontSize: 14,
//               color: Colors.grey[600],
//             ),
//           ),
//           const SizedBox(height: 8),
//           Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(Icons.timer, color: timerColor),
//               const SizedBox(width: 8),
//               Text(
//                 "$remainingSeconds s",
//                 style: TextStyle(
//                   fontSize: 28,
//                   fontWeight: FontWeight.bold,
//                   color: timerColor,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 10),
//           SizedBox(
//             width: 100,
//             height: 6,
//             child: ClipRRect(
//               borderRadius: BorderRadius.circular(3),
//               child: LinearProgressIndicator(
//                 value: progress,
//                 backgroundColor: Colors.grey[200],
//                 valueColor: AlwaysStoppedAnimation<Color>(timerColor),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Build stat counter card
//   static Widget buildStatCard(
//       String title, int value, IconData icon, Color color) {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 5,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(icon, color: color, size: 18),
//               const SizedBox(width: 6),
//               Text(
//                 title,
//                 style: TextStyle(
//                   fontSize: 12,
//                   color: Colors.grey[600],
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 4),
//           Text(
//             "$value s",
//             style: TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//               color: color,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Build form indicator
//   static Widget buildFormIndicator(bool isCorrect, String message) {
//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 500),
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//       decoration: BoxDecoration(
//         color: isCorrect ? Colors.green : Colors.red,
//         borderRadius: BorderRadius.circular(30),
//         boxShadow: [
//           BoxShadow(
//             color: (isCorrect ? Colors.green : Colors.red).withOpacity(0.3),
//             blurRadius: 10,
//             offset: const Offset(0, 5),
//           ),
//         ],
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(
//             isCorrect ? Icons.check_circle : Icons.warning_rounded,
//             color: Colors.white,
//             size: 24,
//           ),
//           const SizedBox(width: 8),
//           Text(
//             message,
//             style: const TextStyle(
//               color: Colors.white,
//               fontWeight: FontWeight.bold,
//               fontSize: 16,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Private methods
//   static Widget _buildBodyPartIcon(String bodyPart, Color color, double size) {
//     IconData iconData;

//     switch (bodyPart.toLowerCase()) {
//       case 'head':
//         iconData = Icons.face;
//         break;
//       case 'shoulder':
//       case 'shoulders':
//         iconData = Icons.accessibility_new;
//         break;
//       case 'hip':
//       case 'hips':
//         iconData = Icons.airline_seat_legroom_extra;
//         break;
//       case 'foot':
//       case 'feet':
//         iconData = Icons.do_not_step;
//         break;
//       default:
//         iconData = Icons.person;
//     }

//     return Icon(
//       iconData,
//       color: color,
//       size: size,
//     );
//   }
// }
