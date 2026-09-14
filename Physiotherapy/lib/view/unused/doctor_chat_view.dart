// import 'package:flutter/material.dart';
// import 'package:physiotherapy/common/color_extension.dart';
// import 'package:physiotherapy/view/rehabilitation/doctorchatscreen.dart';
// import 'package:flutter_staggered_animations/flutter_staggered_animations.dart'; // Add this package

// class PatientChatsView extends StatefulWidget {
//   const PatientChatsView({super.key});

//   @override
//   State<PatientChatsView> createState() => _PatientChatsViewState();
// }

// class _PatientChatsViewState extends State<PatientChatsView>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;

//   List<Map<String, dynamic>> patients = [
//     {
//       "name": "John Doe",
//       "lastMessage": "How often should I do the exercises?",
//       "image": "assets/img/pic_4.png",
//       "unread": 2,
//       "lastMessageTime": "10:30 AM",
//     },
//     {
//       "name": "Jane Smith",
//       "lastMessage": "I feel pain in my shoulder.",
//       "image": "assets/img/pic_4.png",
//       "unread": 0,
//       "lastMessageTime": "Yesterday",
//     },
//     {
//       "name": "Alice Johnson",
//       "lastMessage": "Can I skip the clinic visit tomorrow?",
//       "image": "assets/img/pic_4.png",
//       "unread": 1,
//       "lastMessageTime": "9:45 AM",
//     },
//     {
//       "name": "Robert Williams",
//       "lastMessage": "Thanks for the therapy plan!",
//       "image": "assets/img/pic_4.png",
//       "unread": 0,
//       "lastMessageTime": "Yesterday",
//     },
//     {
//       "name": "Emily Davis",
//       "lastMessage": "The stretching routine is helping a lot",
//       "image": "assets/img/pic_4.png",
//       "unread": 3,
//       "lastMessageTime": "8:15 AM",
//     },
//   ];

//   String searchQuery = '';
//   bool isSearching = false;

//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 300),
//     );
//     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
//     );
//     _animationController.forward();
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }

//   List<Map<String, dynamic>> get filteredPatients {
//     if (searchQuery.isEmpty) {
//       return patients;
//     } else {
//       return patients
//           .where((patient) =>
//               patient['name'].toLowerCase().contains(searchQuery.toLowerCase()))
//           .toList();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           "Patient Chats",
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
//       backgroundColor: TColor.ivory,
//       body: SafeArea(
//         child: Column(
//           children: [
//             Expanded(
//               child: Padding(
//                 padding: const EdgeInsets.fromLTRB(15, 5, 15, 15),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     _buildSearchBar(),
//                     const SizedBox(height: 20),
//                     Padding(
//                       padding: const EdgeInsets.only(left: 5, bottom: 10),
//                       child: Text(
//                         "Recent Conversations",
//                         style: TextStyle(
//                           color: TColor.black,
//                           fontSize: 18,
//                           fontWeight: FontWeight.w600,
//                           letterSpacing: 0.5,
//                         ),
//                       ),
//                     ),
//                     Expanded(
//                       child: _buildChatList(),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildAppBar() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
//       decoration: BoxDecoration(
//         color: TColor.primaryColor1,
//         borderRadius: const BorderRadius.only(
//           bottomLeft: Radius.circular(25),
//           bottomRight: Radius.circular(25),
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 10,
//             offset: const Offset(0, 5),
//           ),
//         ],
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Row(
//             children: [
//               Hero(
//                 tag: 'appBarIcon',
//                 child: Container(
//                   height: 40,
//                   width: 40,
//                   decoration: BoxDecoration(
//                     color: Colors.white.withOpacity(0.2),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Icon(Icons.chat, color: TColor.white),
//                 ),
//               ),
//               const SizedBox(width: 15),
//               Text(
//                 "Patient Chats",
//                 style: TextStyle(
//                   color: TColor.white,
//                   fontSize: 22,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ],
//           ),
//           Container(
//             padding: const EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color: Colors.white.withOpacity(0.2),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Icon(Icons.notifications_outlined, color: TColor.white),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSearchBar() {
//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 300),
//       height: 55,
//       decoration: BoxDecoration(
//         color: TColor.realWhite,
//         borderRadius: BorderRadius.circular(isSearching ? 20 : 15),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 5),
//           ),
//         ],
//       ),
//       child: TextField(
//         onTap: () {
//           setState(() {
//             isSearching = true;
//           });
//         },
//         onSubmitted: (_) {
//           setState(() {
//             isSearching = false;
//           });
//         },
//         onChanged: (value) {
//           setState(() {
//             searchQuery = value;
//           });
//         },
//         decoration: InputDecoration(
//           hintText: "Search patients",
//           hintStyle: TextStyle(color: TColor.gray.withOpacity(0.7)),
//           prefixIcon: Icon(Icons.search, color: TColor.primaryColor1),
//           suffixIcon: searchQuery.isNotEmpty
//               ? IconButton(
//                   icon: Icon(Icons.clear, color: TColor.gray),
//                   onPressed: () {
//                     setState(() {
//                       searchQuery = '';
//                     });
//                   },
//                 )
//               : null,
//           border: InputBorder.none,
//           contentPadding:
//               const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
//         ),
//       ),
//     );
//   }

//   Widget _buildChatList() {
//     return AnimationLimiter(
//       child: filteredPatients.isEmpty
//           ? _buildEmptyState()
//           : ListView.builder(
//               itemCount: filteredPatients.length,
//               itemBuilder: (context, index) {
//                 final patient = filteredPatients[index];
//                 return AnimationConfiguration.staggeredList(
//                   position: index,
//                   duration: const Duration(milliseconds: 375),
//                   child: SlideAnimation(
//                     verticalOffset: 50.0,
//                     child: FadeInAnimation(
//                       child: _buildChatCard(
//                         patientName: patient['name'],
//                         lastMessage: patient['lastMessage'],
//                         patientImage: patient['image'],
//                         unreadCount: patient['unread'],
//                         lastMessageTime: patient['lastMessageTime'],
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             PageRouteBuilder(
//                               pageBuilder:
//                                   (context, animation, secondaryAnimation) =>
//                                       DoctorChatScreen(
//                                 patientName: patient['name'],
//                                 patientImage: patient['image'],
//                               ),
//                               transitionsBuilder: (context, animation,
//                                   secondaryAnimation, child) {
//                                 var begin = const Offset(1.0, 0.0);
//                                 var end = Offset.zero;
//                                 var curve = Curves.easeInOut;
//                                 var tween = Tween(begin: begin, end: end)
//                                     .chain(CurveTween(curve: curve));
//                                 return SlideTransition(
//                                   position: animation.drive(tween),
//                                   child: child,
//                                 );
//                               },
//                             ),
//                           );
//                         },
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             ),
//     );
//   }

//   Widget _buildEmptyState() {
//     return FadeTransition(
//       opacity: _fadeAnimation,
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.chat_bubble_outline,
//             size: 80,
//             color: TColor.gray.withOpacity(0.5),
//           ),
//           const SizedBox(height: 20),
//           Text(
//             "No conversations found",
//             style: TextStyle(
//               color: TColor.gray,
//               fontSize: 18,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           const SizedBox(height: 10),
//           Text(
//             searchQuery.isNotEmpty
//                 ? "Try a different search term"
//                 : "Your patient conversations will appear here",
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               color: TColor.gray.withOpacity(0.7),
//               fontSize: 14,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildChatCard({
//     required String patientName,
//     required String lastMessage,
//     required String patientImage,
//     required int unreadCount,
//     required String lastMessageTime,
//     required VoidCallback onTap,
//   }) {
//     return Container(
//       margin: const EdgeInsets.symmetric(vertical: 8),
//       decoration: BoxDecoration(
//         color: TColor.realWhite,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 5),
//           ),
//         ],
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           onTap: onTap,
//           borderRadius: BorderRadius.circular(20),
//           splashColor: TColor.primaryColor1.withOpacity(0.1),
//           highlightColor: TColor.primaryColor1.withOpacity(0.05),
//           child: Padding(
//             padding: const EdgeInsets.all(12),
//             child: Row(
//               children: [
//                 Hero(
//                   tag: 'profile_$patientName',
//                   child: Container(
//                     height: 60,
//                     width: 60,
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(20),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.1),
//                           blurRadius: 5,
//                           offset: const Offset(0, 3),
//                         ),
//                       ],
//                     ),
//                     child: ClipRRect(
//                       borderRadius: BorderRadius.circular(20),
//                       child: Image.asset(
//                         patientImage,
//                         fit: BoxFit.cover,
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 15),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text(
//                             patientName,
//                             style: TextStyle(
//                               color: TColor.black,
//                               fontSize: 16,
//                               fontWeight: unreadCount > 0
//                                   ? FontWeight.w700
//                                   : FontWeight.w600,
//                             ),
//                           ),
//                           Text(
//                             lastMessageTime,
//                             style: TextStyle(
//                               color: unreadCount > 0
//                                   ? TColor.primaryColor1
//                                   : TColor.gray,
//                               fontSize: 12,
//                               fontWeight: unreadCount > 0
//                                   ? FontWeight.w600
//                                   : FontWeight.normal,
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 5),
//                       Row(
//                         children: [
//                           Expanded(
//                             child: Text(
//                               lastMessage,
//                               maxLines: 2,
//                               overflow: TextOverflow.ellipsis,
//                               style: TextStyle(
//                                 color: unreadCount > 0
//                                     ? TColor.black.withOpacity(0.7)
//                                     : TColor.gray,
//                                 fontSize: 14,
//                                 fontWeight: unreadCount > 0
//                                     ? FontWeight.w500
//                                     : FontWeight.normal,
//                               ),
//                             ),
//                           ),
//                           if (unreadCount > 0) ...[
//                             const SizedBox(width: 5),
//                             Container(
//                               padding: const EdgeInsets.all(6),
//                               decoration: BoxDecoration(
//                                 color: TColor.primaryColor1,
//                                 shape: BoxShape.circle,
//                               ),
//                               child: Text(
//                                 unreadCount.toString(),
//                                 style: const TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 12,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
