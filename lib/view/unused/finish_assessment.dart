// import 'package:flutter/material.dart';
// import 'package:physiotherapy/common/color_extension.dart';
// import 'package:physiotherapy/common_widget/round_button.dart';
// import 'package:physiotherapy/view/symptom_assessment/medical_report_data_extraction.dart';

// class FinishAssessment extends StatefulWidget {
//   const FinishAssessment({super.key});

//   @override
//   State<FinishAssessment> createState() => FinishAssessmentState();
// }

// class FinishAssessmentState extends State<FinishAssessment> {
//   int? selectedIndex; // Store selected choice index

//   List<String> choices = ["Low", "Medium", "High"];

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
//                 "New Assessment",
//                 style: TextStyle(
//                     color: TColor.black,
//                     fontSize: 20,
//                     fontWeight: FontWeight.w700),
//               ),
//               SizedBox(height: media.width * 0.02),
//               Text(
//                 "Please answer the following questions as accurately as possible, as your responses will impact our analysis of your situation. If you have any doubts about a question's meaning, consider researching it online.",
//                 textAlign: TextAlign.left,
//                 style: TextStyle(color: TColor.gray, fontSize: 12),
//               ),
//               SizedBox(height: media.width * 0.1),

//               Text(
//                 "How severe is your pain?",
//                 style: TextStyle(
//                     color: TColor.black,
//                     fontSize: 21,
//                     fontWeight: FontWeight.w300),
//               ),
//               SizedBox(height: media.width * 0.1),

//               // Multiple Choice Buttons
//               Column(
//                 children: List.generate(choices.length, (index) {
//                   bool isSelected = selectedIndex == index;
//                   return GestureDetector(
//                     onTap: () {
//                       setState(() {
//                         selectedIndex = index;
//                       });
//                     },
//                     child: Container(
//                       margin: const EdgeInsets.symmetric(vertical: 5),
//                       padding: const EdgeInsets.symmetric(
//                           vertical: 15, horizontal: 20),
//                       width: double.infinity,
//                       decoration: BoxDecoration(
//                         color: isSelected
//                             ? TColor.primaryColor2 // Highlighted when selected
//                             : Colors.transparent,
//                         border:
//                             Border.all(color: TColor.primaryColor2, width: 1.5),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Text(
//                         choices[index],
//                         style: TextStyle(
//                           color:
//                               isSelected ? Colors.white : TColor.primaryColor2,
//                           fontSize: 16,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ),
//                   );
//                 }),
//               ),

//               const Spacer(),
//               RoundButton(
//                 title: "Proceed",
//                 onPressed: () {
//                   Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                           builder: (context) => const MriClassificationView()));
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
