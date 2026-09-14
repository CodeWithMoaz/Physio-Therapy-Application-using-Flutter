// import 'package:flutter/material.dart';
// import 'package:flutter_chat_bubble/chat_bubble.dart';
// import 'package:physiotherapy/common/color_extension.dart';

// class DoctorChatScreen extends StatefulWidget {
//   final String patientName;
//   final String patientImage;

//   const DoctorChatScreen({
//     super.key,
//     required this.patientName,
//     required this.patientImage,
//   });

//   @override
//   _DoctorChatScreenState createState() => _DoctorChatScreenState();
// }

// class _DoctorChatScreenState extends State<DoctorChatScreen>
//     with TickerProviderStateMixin {
//   final TextEditingController _messageController = TextEditingController();
//   final ScrollController _scrollController = ScrollController();
//   final List<Map<String, dynamic>> _messages = [
//     {
//       "sender": "patient",
//       "message": "Hello doctor, I wanted to ask about my exercise routine.",
//       "time": "Yesterday",
//       "isRead": true,
//     },
//     {
//       "sender": "doctor",
//       "message": "Hi there! Of course, what's your concern?",
//       "time": "Yesterday",
//       "isRead": true,
//     },
//     {
//       "sender": "patient",
//       "message":
//           "I'm experiencing some pain in my right knee after the last session.",
//       "time": "Yesterday",
//       "isRead": true,
//     },
//     {
//       "sender": "doctor",
//       "message":
//           "I understand. Could you describe the pain? Is it sharp, dull, or more of an ache?",
//       "time": "Yesterday",
//       "isRead": true,
//     },
//     {
//       "sender": "patient",
//       "message":
//           "It's more of a dull ache, especially when I try to bend my knee fully.",
//       "time": "10:30 AM",
//       "isRead": true,
//     },
//   ];

//   late AnimationController _typingIndicatorController;
//   bool _isPatientTyping = false;

//   get patientName => widget.patientName;

//   @override
//   void initState() {
//     super.initState();
//     _typingIndicatorController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 600),
//     )..repeat(reverse: true);

//     // Scroll to bottom initially
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _scrollToBottom();
//     });
//   }

//   @override
//   void dispose() {
//     _messageController.dispose();
//     _scrollController.dispose();
//     _typingIndicatorController.dispose();
//     super.dispose();
//   }

//   void _scrollToBottom() {
//     if (_scrollController.hasClients) {
//       _scrollController.animateTo(
//         _scrollController.position.maxScrollExtent,
//         duration: const Duration(milliseconds: 300),
//         curve: Curves.easeOut,
//       );
//     }
//   }

//   void _sendMessage(String message) {
//     if (message.trim().isNotEmpty) {
//       setState(() {
//         // Add the doctor's message to the list
//         _messages.add({
//           "sender": "doctor",
//           "message": message,
//           "time": "Just now",
//           "isRead": false,
//         });

//         // Clear the input field
//         _messageController.clear();
//       });

//       // Scroll to the bottom after sending a message
//       _scrollToBottom();

//       // Show typing indicator
//       setState(() {
//         _isPatientTyping = true;
//       });

//       // Simulate a patient's reply after a short delay
//       Future.delayed(const Duration(milliseconds: 1500), () {
//         setState(() {
//           _isPatientTyping = false;
//         });

//         Future.delayed(const Duration(milliseconds: 500), () {
//           setState(() {
//             _messages.add({
//               "sender": "patient",
//               "message":
//                   "Thank you for the advice, Doctor! I'll follow your recommendations.",
//               "time": "Just now",
//               "isRead": false,
//             });
//           });

//           // Scroll to bottom after receiving reply
//           _scrollToBottom();
//         });
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           "Chat with $patientName",
//           style: TextStyle(
//             color: TColor.white,
//             fontSize: 20,
//             fontWeight: FontWeight.w700,
//           ),
//         ),
//         backgroundColor: TColor.primaryColor1,
//         elevation: 0,
//         iconTheme: IconThemeData(color: TColor.white),
//       ),
//       backgroundColor: TColor.ivory.withOpacity(0.95),
//       body: SafeArea(
//         child: Column(
//           children: [
//             // Date separator
//             Container(
//               padding: const EdgeInsets.symmetric(vertical: 10),
//               child: Center(
//                 child: Container(
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                   decoration: BoxDecoration(
//                     color: Colors.grey.withOpacity(0.2),
//                     borderRadius: BorderRadius.circular(15),
//                   ),
//                   child: Text(
//                     "Today",
//                     style: TextStyle(
//                       color: TColor.gray,
//                       fontSize: 12,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ),
//               ),
//             ),

//             // Chat Messages
//             Expanded(
//               child: GestureDetector(
//                 onTap: () => FocusScope.of(context).unfocus(),
//                 child: ListView.builder(
//                   controller: _scrollController,
//                   padding: const EdgeInsets.all(16),
//                   itemCount: _messages.length + (_isPatientTyping ? 1 : 0),
//                   itemBuilder: (context, index) {
//                     // Typing indicator
//                     if (_isPatientTyping && index == _messages.length) {
//                       return _buildTypingIndicator();
//                     }

//                     final message = _messages[index];
//                     final isDoctor = message["sender"] == "doctor";

//                     return AnimatedContainer(
//                       duration: const Duration(milliseconds: 300),
//                       transform: Matrix4.translationValues(
//                           0, index == _messages.length - 1 ? 0 : 0, 0),
//                       child: _buildMessageBubble(message, isDoctor),
//                     );
//                   },
//                 ),
//               ),
//             ),

//             // Message Input Field
//             _buildMessageInputField(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildCustomAppBar() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
//       decoration: BoxDecoration(
//         color: TColor.primaryColor1,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 10,
//             offset: const Offset(0, 3),
//           ),
//         ],
//         borderRadius: const BorderRadius.only(
//           bottomLeft: Radius.circular(20),
//           bottomRight: Radius.circular(20),
//         ),
//       ),
//       child: Row(
//         children: [
//           IconButton(
//             icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
//             onPressed: () {
//               Navigator.of(context).pop();
//             },
//           ),
//           Hero(
//             tag: 'profile_${widget.patientName}',
//             child: Container(
//               height: 45,
//               width: 45,
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(15),
//                 border: Border.all(color: Colors.white, width: 2),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.1),
//                     blurRadius: 5,
//                     offset: const Offset(0, 3),
//                   ),
//                 ],
//               ),
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(13),
//                 child: Image.asset(
//                   widget.patientImage,
//                   fit: BoxFit.cover,
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   widget.patientName,
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 18,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 Row(
//                   children: [
//                     Container(
//                       width: 8,
//                       height: 8,
//                       decoration: BoxDecoration(
//                         color: Colors.green,
//                         shape: BoxShape.circle,
//                       ),
//                     ),
//                     SizedBox(width: 5),
//                     Text(
//                       "Online",
//                       style: TextStyle(
//                         color: Colors.white.withOpacity(0.8),
//                         fontSize: 13,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//           IconButton(
//             icon: const Icon(Icons.phone, color: Colors.white),
//             onPressed: () {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(content: Text("Video call initiated")),
//               );
//             },
//           ),
//           IconButton(
//             icon: const Icon(Icons.more_vert, color: Colors.white),
//             onPressed: () {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(content: Text("More options")),
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMessageBubble(Map<String, dynamic> message, bool isDoctor) {
//     final time = message["time"] as String;

//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: Row(
//         mainAxisAlignment:
//             isDoctor ? MainAxisAlignment.end : MainAxisAlignment.start,
//         crossAxisAlignment: CrossAxisAlignment.end,
//         children: [
//           if (!isDoctor) ...[
//             CircleAvatar(
//               radius: 16,
//               backgroundImage: AssetImage(widget.patientImage),
//             ),
//             const SizedBox(width: 8),
//           ],
//           Flexible(
//             child: Container(
//               constraints: BoxConstraints(
//                 maxWidth: MediaQuery.of(context).size.width * 0.7,
//               ),
//               child: ChatBubble(
//                 clipper: isDoctor
//                     ? ChatBubbleClipper5(type: BubbleType.sendBubble)
//                     : ChatBubbleClipper5(type: BubbleType.receiverBubble),
//                 backGroundColor: isDoctor
//                     ? TColor.primaryColor1.withOpacity(0.9)
//                     : Colors.white,
//                 margin: const EdgeInsets.only(top: 10),
//                 child: Container(
//                   constraints: BoxConstraints(
//                     maxWidth: MediaQuery.of(context).size.width * 0.7,
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.end,
//                     children: [
//                       Text(
//                         message["message"],
//                         style: TextStyle(
//                           color: isDoctor ? Colors.white : Colors.black87,
//                           fontSize: 15,
//                         ),
//                       ),
//                       const SizedBox(height: 5),
//                       Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Text(
//                             time,
//                             style: TextStyle(
//                               color: isDoctor
//                                   ? Colors.white.withOpacity(0.7)
//                                   : Colors.black54,
//                               fontSize: 11,
//                             ),
//                           ),
//                           if (isDoctor) ...[
//                             const SizedBox(width: 3),
//                             Icon(
//                               message["isRead"] ? Icons.done_all : Icons.done,
//                               size: 14,
//                               color: Colors.white.withOpacity(0.7),
//                             ),
//                           ],
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//           if (isDoctor) ...[
//             const SizedBox(width: 8),
//             CircleAvatar(
//               radius: 16,
//               backgroundColor: TColor.primaryColor1,
//               child: const Icon(
//                 Icons.medical_services_outlined,
//                 color: Colors.white,
//                 size: 18,
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _buildTypingIndicator() {
//     return Align(
//       alignment: Alignment.centerLeft,
//       child: Row(
//         children: [
//           CircleAvatar(
//             radius: 16,
//             backgroundImage: AssetImage(widget.patientImage),
//           ),
//           const SizedBox(width: 8),
//           Container(
//             margin: const EdgeInsets.only(top: 10, right: 10),
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(18),
//             ),
//             child: Row(
//               children: [
//                 _buildDot(0),
//                 const SizedBox(width: 3),
//                 _buildDot(100),
//                 const SizedBox(width: 3),
//                 _buildDot(200),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDot(int delay) {
//     return AnimatedBuilder(
//       animation: _typingIndicatorController,
//       builder: (context, child) {
//         final double bounce = Curves.easeInOut.transform(
//           ((_typingIndicatorController.value * 400) + delay) % 1000 / 1000,
//         );
//         return Container(
//           height: 6 + (bounce * 3),
//           width: 6 + (bounce * 3),
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             color: TColor.gray.withOpacity(0.7),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildMessageInputField() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 5,
//             offset: const Offset(0, -2),
//           ),
//         ],
//       ),
//       child: SafeArea(
//         top: false,
//         child: Row(
//           children: [
//             Container(
//               decoration: BoxDecoration(
//                 color: TColor.primaryColor1.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(25),
//               ),
//               child: IconButton(
//                 onPressed: () {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text("Attachments")),
//                   );
//                 },
//                 icon: Icon(Icons.add, color: TColor.primaryColor1),
//               ),
//             ),
//             const SizedBox(width: 10),
//             Expanded(
//               child: Container(
//                 decoration: BoxDecoration(
//                   color: Colors.grey.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(25),
//                 ),
//                 child: Row(
//                   children: [
//                     const SizedBox(width: 15),
//                     Expanded(
//                       child: TextField(
//                         controller: _messageController,
//                         maxLines: null,
//                         decoration: const InputDecoration(
//                           hintText: "Type a message...",
//                           border: InputBorder.none,
//                           contentPadding: EdgeInsets.symmetric(vertical: 10),
//                         ),
//                       ),
//                     ),
//                     IconButton(
//                       onPressed: () {
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           const SnackBar(content: Text("Voice recording")),
//                         );
//                       },
//                       icon: const Icon(Icons.mic_none, color: Colors.grey),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(width: 10),
//             Container(
//               height: 50,
//               width: 50,
//               decoration: BoxDecoration(
//                 color: TColor.primaryColor1,
//                 borderRadius: BorderRadius.circular(25),
//                 boxShadow: [
//                   BoxShadow(
//                     color: TColor.primaryColor1.withOpacity(0.3),
//                     blurRadius: 10,
//                     offset: const Offset(0, 3),
//                   ),
//                 ],
//               ),
//               child: IconButton(
//                 onPressed: () {
//                   _sendMessage(_messageController.text.trim());
//                 },
//                 icon: AnimatedSwitcher(
//                   duration: const Duration(milliseconds: 300),
//                   transitionBuilder:
//                       (Widget child, Animation<double> animation) {
//                     return ScaleTransition(scale: animation, child: child);
//                   },
//                   child: _messageController.text.trim().isEmpty
//                       ? const Icon(Icons.mic,
//                           color: Colors.white, key: ValueKey('mic'))
//                       : const Icon(Icons.send,
//                           color: Colors.white, key: ValueKey('send')),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
