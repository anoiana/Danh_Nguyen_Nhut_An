// import 'package:flutter/material.dart';
// import 'package:midterm/service/AppwriteService.dart';
// import 'package:midterm/screens/signin.dart';
// import 'package:flutter/material.dart';
// import 'package:midterm/service/AppwriteService.dart';
// import 'package:midterm/screens/signin.dart';
// import 'package:image_picker/image_picker.dart';
// import 'dart:io' show File;
// import 'dart:typed_data';
// import 'package:flutter/foundation.dart' show kIsWeb;
//
// class StudentManagementApp extends StatelessWidget {
//   final String userRole; // Thêm tham số vai trò
//
//   const StudentManagementApp({super.key, required this.userRole});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         primaryColor: Colors.blue[900],
//         colorScheme: ColorScheme.fromSwatch(
//           primarySwatch: Colors.blue,
//           accentColor: Colors.blue[300],
//         ),
//         fontFamily: 'Roboto',
//       ),
//       home: HomePage(userRole: userRole),
//     );
//   }
// }
//
// class HomePage extends StatefulWidget {
//   final String userRole;
//
//   const HomePage({super.key, required this.userRole});
//
//   @override
//   State<HomePage> createState() => _HomePageState();
// }
//
// class _HomePageState extends State<HomePage> {
//   List<Map<String, dynamic>> students = [];
//   final AppwriteService _appwriteService = AppwriteService();
//   String? userName;
//   String? userEmail;
//   String avatarUrl = 'https://picsum.photos/150';
//
//   @override
//   void initState() {
//     super.initState();
//     _loadUserInfo();
//     _loadStudents();
//   }
//
//   Future<void> _loadUserInfo() async {
//     try {
//       final user = await _appwriteService.account.get();
//       setState(() {
//         userName = user.name;
//         userEmail = user.email;
//       });
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Lỗi khi lấy thông tin người dùng: $e')),
//       );
//     }
//   }
//
//   Future<void> _loadStudents() async {
//     try {
//       final studentList = await _appwriteService.getStudents();
//       setState(() {
//         students = studentList;
//       });
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Lỗi khi tải danh sách sinh viên: $e')),
//       );
//     }
//   }
//
//   Future<void> _logout() async {
//     try {
//       await _appwriteService.account.deleteSession(sessionId: 'current');
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (context) => const Signin()),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Lỗi khi đăng xuất: $e')),
//       );
//     }
//   }
//
//   void _changeName() {
//     final nameController = TextEditingController(text: userName);
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Change Name'),
//         content: TextField(
//           controller: nameController,
//           decoration: const InputDecoration(labelText: 'New Name'),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               if (nameController.text.isNotEmpty) {
//                 try {
//                   await _appwriteService.account.updateName(
//                     name: nameController.text,
//                   );
//                   setState(() {
//                     userName = nameController.text;
//                   });
//                   Navigator.pop(context);
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text('Name updated')),
//                   );
//                 } catch (e) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text('Error: $e')),
//                   );
//                 }
//               }
//             },
//             child: const Text('Save'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _changeAvatar() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Change Avatar'),
//         content: const Text('Feature under development. Coming soon!'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Student Management',
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             fontSize: 24,
//             color: Colors.white,
//           ),
//         ),
//         centerTitle: true,
//         elevation: 4,
//         flexibleSpace: Container(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [Colors.blue[900]!, Colors.blue[300]!],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//           ),
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.search, color: Colors.white),
//             onPressed: () {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(content: Text('Search feature coming soon!')),
//               );
//             },
//           ),
//         ],
//       ),
//       drawer: Drawer(
//         child: ListView(
//           padding: EdgeInsets.zero,
//           children: [
//             UserAccountsDrawerHeader(
//               accountName: Text(
//                 userName ?? 'Loading...',
//                 style: const TextStyle(fontWeight: FontWeight.bold),
//               ),
//               accountEmail: Text('${userEmail ?? 'Loading...'} (${widget.userRole})'), // Hiển thị vai trò
//               currentAccountPicture: GestureDetector(
//                 onTap: _changeAvatar,
//                 child: CircleAvatar(
//                   backgroundImage: NetworkImage(avatarUrl),
//                   onBackgroundImageError: (exception, stackTrace) {
//                     print('Error loading avatar: $exception');
//                   },
//                   child: avatarUrl.isEmpty
//                       ? const Icon(Icons.person, size: 50, color: Colors.white)
//                       : null,
//                 ),
//               ),
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [Colors.blue[900]!, Colors.blue[300]!],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 ),
//               ),
//             ),
//             ListTile(
//               leading: const Icon(Icons.person),
//               title: const Text('Change Name'),
//               onTap: _changeName,
//             ),
//             ListTile(
//               leading: const Icon(Icons.settings),
//               title: const Text('Settings'),
//               onTap: () {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(content: Text('Settings coming soon!')),
//                 );
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.logout),
//               title: const Text('Logout'),
//               onTap: _logout,
//             ),
//           ],
//         ),
//       ),
//         body: Container(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [Colors.blue[300]!.withOpacity(0.1), Colors.white],
//               begin: Alignment.topCenter,
//               end: Alignment.bottomCenter,
//             ),
//           ),
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: students.isEmpty
//                 ? Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(
//                     Icons.people_outline,
//                     size: 80,
//                     color: Colors.blue[900]!.withOpacity(0.5),
//                   ),
//                   const SizedBox(height: 16),
//                   Text(
//                     'No students found.\nTap the + button to add one!',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       fontSize: 18,
//                       color: Colors.blue[900]!.withOpacity(0.7),
//                     ),
//                   ),
//                 ],
//               ),
//             )
//                 : ListView.builder(
//               itemCount: students.length,
//               itemBuilder: (context, index) {
//                 final student = students[index];
//                 return Card(
//                   elevation: 6,
//                   margin: const EdgeInsets.symmetric(vertical: 10),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   child: Container(
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(16),
//                       gradient: LinearGradient(
//                         colors: [
//                           Colors.blue[300]!.withOpacity(0.2),
//                           Colors.white
//                         ],
//                         begin: Alignment.topLeft,
//                         end: Alignment.bottomRight,
//                       ),
//                     ),
//                     child: ListTile(
//                       leading: CircleAvatar(
//                         backgroundImage: student['image'] != null && student['image'].isNotEmpty
//                             ? NetworkImage(student['image'])
//                             : NetworkImage(avatarUrl),
//                         backgroundColor: Colors.blue[900],
//                         child: student['image'] == null || student['image'].isEmpty
//                             ? Text(
//                           student['name'][0],
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         )
//                             : null,
//                       ),
//                       title: Text(
//                         student['name'],
//                         style: TextStyle(
//                           fontWeight: FontWeight.w600,
//                           fontSize: 18,
//                           color: Colors.blue[900],
//                         ),
//                       ),
//                       subtitle: Text(
//                         'Lớp: ${student['class']} - Tuổi: ${student['age']}', // Hiển thị tuổi
//                         style: TextStyle(color: Colors.blue[900]!.withOpacity(0.7)),
//                       ),
//                       trailing: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           IconButton(
//                             icon: Icon(Icons.edit, color: Colors.blue[900]),
//                             onPressed: () => _showEditDialog(student),
//                           ),
//                           IconButton(
//                             icon: const Icon(Icons.delete, color: Colors.red),
//                             onPressed: () async {
//                               try {
//                                 await _appwriteService.deleteStudent(student['mssv']);
//                                 setState(() {
//                                   students.removeAt(index);
//                                 });
//                                 ScaffoldMessenger.of(context).showSnackBar(
//                                   const SnackBar(content: Text('Student deleted')),
//                                 );
//                               } catch (e) {
//                                 ScaffoldMessenger.of(context).showSnackBar(
//                                   SnackBar(content: Text('Error: $e')),
//                                 );
//                               }
//                             },
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ),
//       floatingActionButton: widget.userRole == 'admin' || widget.userRole == 'teacher'
//           ? FloatingActionButton(
//         onPressed: _showAddStudentDialog,
//         backgroundColor: Colors.blue[900],
//         child: const Icon(Icons.add, color: Colors.white),
//       )
//           : null,
//     );
//   }
//
//   void _showAddStudentDialog() async {
//     final mssvController = TextEditingController();
//     final nameController = TextEditingController();
//     final classController = TextEditingController();
//     final ageController = TextEditingController(); // Thêm controller cho tuổi
//     dynamic image;
//
//     showDialog(
//       context: context,
//       builder: (dialogContext) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: Text('Thêm Sinh Viên Mới', style: TextStyle(color: Colors.blue[900])),
//         content: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextField(
//                 controller: mssvController,
//                 decoration: InputDecoration(
//                   labelText: 'MSSV',
//                   border: const OutlineInputBorder(),
//                   focusedBorder: OutlineInputBorder(
//                     borderSide: BorderSide(color: Colors.blue[900]!),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 10),
//               TextField(
//                 controller: nameController,
//                 decoration: InputDecoration(
//                   labelText: 'Tên',
//                   border: const OutlineInputBorder(),
//                   focusedBorder: OutlineInputBorder(
//                     borderSide: BorderSide(color: Colors.blue[900]!),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 10),
//               TextField(
//                 controller: classController,
//                 decoration: InputDecoration(
//                   labelText: 'Lớp',
//                   border: const OutlineInputBorder(),
//                   focusedBorder: OutlineInputBorder(
//                     borderSide: BorderSide(color: Colors.blue[900]!),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 10),
//               TextField(
//                 controller: ageController,
//                 keyboardType: TextInputType.number,
//                 decoration: InputDecoration(
//                   labelText: 'Tuổi',
//                   border: const OutlineInputBorder(),
//                   focusedBorder: OutlineInputBorder(
//                     borderSide: BorderSide(color: Colors.blue[900]!),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 10),
//               ElevatedButton(
//                 onPressed: () async {
//                   try {
//                     final picker = ImagePicker();
//                     final pickedFile = await picker.pickImage(source: ImageSource.gallery);
//                     if (pickedFile != null) {
//                       if (kIsWeb) {
//                         image = await pickedFile.readAsBytes();
//                       } else {
//                         image = File(pickedFile.path);
//                       }
//                       setState(() {});
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(content: Text('Đã chọn ảnh')),
//                       );
//                     }
//                   } catch (e) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(content: Text('Lỗi khi chọn ảnh: $e')),
//                     );
//                   }
//                 },
//                 style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[300]),
//                 child: const Text('Chọn Ảnh', style: TextStyle(color: Colors.white)),
//               ),
//               if (image != null)
//                 Padding(
//                   padding: const EdgeInsets.only(top: 10),
//                   child: kIsWeb
//                       ? Image.memory(image, height: 100, width: 100, fit: BoxFit.cover)
//                       : Image.file(image, height: 100, width: 100, fit: BoxFit.cover),
//                 ),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(dialogContext),
//             child: Text('Hủy', style: TextStyle(color: Colors.blue[900])),
//           ),
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[900]),
//             onPressed: () async {
//               if (mssvController.text.isNotEmpty &&
//                   nameController.text.isNotEmpty &&
//                   classController.text.isNotEmpty &&
//                   ageController.text.isNotEmpty) {
//                 try {
//                   final studentList = await _appwriteService.getStudents();
//                   if (studentList.any((s) => s['mssv'] == mssvController.text)) {
//                     ScaffoldMessenger.of(dialogContext).showSnackBar(
//                       const SnackBar(content: Text('MSSV đã tồn tại')),
//                     );
//                     return;
//                   }
//
//                   String imageUrl = '';
//                   if (image != null) {
//                     imageUrl = await _appwriteService.uploadImage(image);
//                   }
//
//                   await _appwriteService.addStudent(
//                     mssv: mssvController.text,
//                     name: nameController.text,
//                     studentClass: classController.text,
//                     age: int.parse(ageController.text), // Thêm tuổi
//                     imageUrl: imageUrl,
//                   );
//
//                   setState(() {
//                     students.add({
//                       'mssv': mssvController.text,
//                       'name': nameController.text,
//                       'class': classController.text,
//                       'age': int.parse(ageController.text),
//                       'image': imageUrl,
//                     });
//                   });
//
//                   Navigator.pop(dialogContext);
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text('Đã thêm sinh viên')),
//                   );
//                 } catch (e) {
//                   ScaffoldMessenger.of(dialogContext).showSnackBar(
//                     SnackBar(content: Text('Lỗi: $e')),
//                   );
//                 }
//               } else {
//                 ScaffoldMessenger.of(dialogContext).showSnackBar(
//                   const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin')),
//                 );
//               }
//             },
//             child: const Text('Thêm', style: TextStyle(color: Colors.white)),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _showEditDialog(Map<String, dynamic> student) {
//     final nameController = TextEditingController(text: student['name']);
//     final classController = TextEditingController(text: student['class']);
//     final ageController = TextEditingController(text: student['age']?.toString() ?? ''); // Thêm tuổi
//     dynamic image;
//
//     showDialog(
//       context: context,
//       builder: (dialogContext) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: Text('Sửa Sinh Viên', style: TextStyle(color: Colors.blue[900])),
//         content: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextField(
//                 controller: nameController,
//                 decoration: InputDecoration(
//                   labelText: 'Tên',
//                   border: const OutlineInputBorder(),
//                   focusedBorder: OutlineInputBorder(
//                     borderSide: BorderSide(color: Colors.blue[900]!),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 10),
//               TextField(
//                 controller: classController,
//                 decoration: InputDecoration(
//                   labelText: 'Lớp',
//                   border: const OutlineInputBorder(),
//                   focusedBorder: OutlineInputBorder(
//                     borderSide: BorderSide(color: Colors.blue[900]!),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 10),
//               TextField(
//                 controller: ageController,
//                 keyboardType: TextInputType.number,
//                 decoration: InputDecoration(
//                   labelText: 'Tuổi',
//                   border: const OutlineInputBorder(),
//                   focusedBorder: OutlineInputBorder(
//                     borderSide: BorderSide(color: Colors.blue[900]!),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 10),
//               ElevatedButton(
//                 onPressed: () async {
//                   try {
//                     final picker = ImagePicker();
//                     final pickedFile = await picker.pickImage(source: ImageSource.gallery);
//                     if (pickedFile != null) {
//                       if (kIsWeb) {
//                         image = await pickedFile.readAsBytes();
//                       } else {
//                         image = File(pickedFile.path);
//                       }
//                       setState(() {});
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(content: Text('Đã chọn ảnh')),
//                       );
//                     }
//                   } catch (e) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(content: Text('Lỗi khi chọn ảnh: $e')),
//                     );
//                   }
//                 },
//                 style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[300]),
//                 child: const Text('Chọn Ảnh Mới', style: TextStyle(color: Colors.white)),
//               ),
//               if (image != null)
//                 Padding(
//                   padding: const EdgeInsets.only(top: 10),
//                   child: kIsWeb
//                       ? Image.memory(image, height: 100, width: 100, fit: BoxFit.cover)
//                       : Image.file(image, height: 100, width: 100, fit: BoxFit.cover),
//                 )
//               else if (student['image'] != null && student['image'].isNotEmpty)
//                 Padding(
//                   padding: const EdgeInsets.only(top: 10),
//                   child: Image.network(
//                     student['image'],
//                     height: 100,
//                     width: 100,
//                     fit: BoxFit.cover,
//                     errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
//                   ),
//                 ),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(dialogContext),
//             child: Text('Hủy', style: TextStyle(color: Colors.blue[900])),
//           ),
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[900]),
//             onPressed: () async {
//               if (nameController.text.isNotEmpty &&
//                   classController.text.isNotEmpty &&
//                   ageController.text.isNotEmpty) {
//                 try {
//                   String imageUrl = student['image'] ?? '';
//                   if (image != null) {
//                     imageUrl = await _appwriteService.uploadImage(image);
//                   }
//
//                   await _appwriteService.updateStudent(
//                     mssv: student['mssv'],
//                     name: nameController.text,
//                     studentClass: classController.text,
//                     age: int.parse(ageController.text), // Thêm tuổi
//                     imageUrl: imageUrl,
//                   );
//
//                   setState(() {
//                     student['name'] = nameController.text;
//                     student['class'] = classController.text;
//                     student['age'] = int.parse(ageController.text);
//                     if (image != null) student['image'] = imageUrl;
//                   });
//
//                   Navigator.pop(dialogContext);
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text('Đã cập nhật sinh viên')),
//                   );
//                 } catch (e) {
//                   ScaffoldMessenger.of(dialogContext).showSnackBar(
//                     SnackBar(content: Text('Lỗi: $e')),
//                   );
//                 }
//               } else {
//                 ScaffoldMessenger.of(dialogContext).showSnackBar(
//                   const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin')),
//                 );
//               }
//             },
//             child: const Text('Lưu', style: TextStyle(color: Colors.white)),
//           ),
//         ],
//       ),
//     );
//   }
// }