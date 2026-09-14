// import 'package:flutter/material.dart';
// import 'package:physiotherapy/common/color_extension.dart';

// class ChatScreen extends StatefulWidget {
//   final String doctorName;
//   final String doctorImage; // Add this line

//   const ChatScreen({
//     super.key,
//     required this.doctorName,
//     required this.doctorImage,
//   }); // Update this line

//   @override
//   _ChatScreenState createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen> {
//   final TextEditingController _messageController = TextEditingController();
//   final List<Map<String, String>> _messages = [];

//   void _sendMessage() {
//     if (_messageController.text.trim().isNotEmpty) {
//       setState(() {
//         // Add the user's message to the list
//         _messages.add({
//           "sender": "user",
//           "message": _messageController.text.trim(),
//         });

//         // Simulate a doctor's reply after a short delay
//         Future.delayed(Duration(seconds: 1), () {
//           setState(() {
//             _messages.add({"sender": "doctor", "message": "Good Morning Moaz"});
//           });
//         });

//         // Clear the input field
//         _messageController.clear();
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Chat with ${widget.doctorName}"),
//         backgroundColor: TColor.primaryColor1,
//         foregroundColor: TColor.white,
//       ),
//       body: Column(
//         children: [
//           // Chat Messages
//           Expanded(
//             child: ListView.builder(
//               padding: EdgeInsets.all(16),
//               itemCount: _messages.length,
//               itemBuilder: (context, index) {
//                 final message = _messages[index];
//                 final isUser = message["sender"] == "user";

//                 return Align(
//                   alignment:
//                       isUser ? Alignment.centerRight : Alignment.centerLeft,
//                   child: Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     mainAxisAlignment:
//                         isUser
//                             ? MainAxisAlignment.end
//                             : MainAxisAlignment.start,
//                     children: [
//                       if (!isUser) // Show doctor's image only for doctor's messages
//                         Padding(
//                           padding: const EdgeInsets.only(right: 8.0),
//                           child: CircleAvatar(
//                             backgroundImage: AssetImage(widget.doctorImage),
//                           ),
//                         ),
//                       Container(
//                         margin: EdgeInsets.symmetric(vertical: 4),
//                         padding: EdgeInsets.symmetric(
//                           horizontal: 16,
//                           vertical: 10,
//                         ),
//                         decoration: BoxDecoration(
//                           color:
//                               isUser ? TColor.primaryColor2 : TColor.lightGray,
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Text(
//                           message["message"]!,
//                           style: TextStyle(
//                             color: isUser ? TColor.white : TColor.black,
//                             fontSize: 16,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 );
//               },
//             ),
//           ),

//           // Message Input Field
//           Container(
//             padding: EdgeInsets.all(8),
//             color: Colors.white,
//             child: Row(
//               children: [
//                 // Text Field for Message Input
//                 Expanded(
//                   child: TextField(
//                     controller: _messageController,
//                     decoration: InputDecoration(
//                       hintText: "Type a message...",
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(25),
//                       ),
//                       contentPadding: EdgeInsets.symmetric(horizontal: 16),
//                     ),
//                   ),
//                 ),

//                 // Send Button
//                 SizedBox(width: 8),
//                 IconButton(
//                   onPressed: _sendMessage,
//                   icon: Icon(Icons.send, color: TColor.primaryColor1),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
