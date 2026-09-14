// import 'package:flutter/material.dart';
// import 'package:physiotherapy/common/color_extension.dart';
// import 'package:physiotherapy/common_widget/dissimble_note.dart';
// import 'package:physiotherapy/common_widget/round_button.dart';
// import 'package:physiotherapy/view/symptom_assessment/question_view.dart';

// class StartAssessment extends StatefulWidget {
//   const StartAssessment({super.key});

//   @override
//   State<StartAssessment> createState() => _StartAssessmentState();
// }

// class _StartAssessmentState extends State<StartAssessment> {
//   @override
//   Widget build(BuildContext context) {
//     var media = MediaQuery.of(context).size;
//     return Scaffold(
//       backgroundColor: TColor.white,
//       body: SafeArea(
//         child: Container(
//           width: media.width,
//           padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             mainAxisSize: MainAxisSize.max,
//             children: [
//               GestureDetector(
//                 onTap: () {
//                   Navigator.pop(
//                       context); // Navigate back to the previous screen
//                 },
//                 child: Container(
//                   padding: const EdgeInsets.all(10),
//                   decoration: BoxDecoration(
//                     color: TColor.gray.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: Icon(
//                     Icons.arrow_back_ios_new,
//                     color: TColor.black,
//                     size: 20,
//                   ),
//                 ),
//               ),
//               SizedBox(height: media.width * 0.05),
//               Text(
//                 "Hey Moaz,",
//                 style: TextStyle(
//                     color: TColor.black,
//                     fontSize: 20,
//                     fontWeight: FontWeight.w700),
//               ),
//               SizedBox(height: media.width * 0.02),
//               Text(
//                 "Start the assessment to know more about what you may be suffering from and to receive more details about your case.",
//                 textAlign: TextAlign.left,
//                 style: TextStyle(color: TColor.gray, fontSize: 12),
//               ),
//               SizedBox(height: media.width * 0.1),

//               // Important Note Section
//               DismissibleNote(),

//               const Spacer(),
//               RoundButton(
//                 title: "Start Symptom Assessment",
//                 onPressed: () {
//                   Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                           builder: (context) => const QuestionView()));
//                 },
//               ),
//               SizedBox(height: media.width * 0.04),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
