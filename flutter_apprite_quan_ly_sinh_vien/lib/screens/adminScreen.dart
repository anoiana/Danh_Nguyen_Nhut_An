import 'dart:io';
import 'dart:typed_data';
import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:midterm/screens/loginScreen.dart';
import 'package:midterm/screens/studentDetail.dart';
import 'package:midterm/screens/subjectDetail.dart';
import 'package:midterm/screens/teacherDetail.dart';
import '../service/AppwriteService.dart';
import 'package:flutter/painting.dart';

class AdminDashboard extends StatefulWidget {
  final String adminId;

  const AdminDashboard({Key? key, required this.adminId}) : super(key: key);

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  String _adminName = "Admin User";
  String _avatarUrl = "https://via.placeholder.com/150";

  final AppwriteService _appwriteService = AppwriteService();
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _subjects = [];
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _subjectIdController = TextEditingController();
  final TextEditingController _subjectDescriptionController = TextEditingController();
  final TextEditingController _subjectCreditController = TextEditingController();

  final TextEditingController _scoreController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _facultyController = TextEditingController();
  final TextEditingController _idController = TextEditingController();

  final TextEditingController _secretCodeController = TextEditingController();
  final TextEditingController _teacherEmailController = TextEditingController();
  final TextEditingController _teacherNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchAdminData();
    _fetchData();
    _searchController.addListener(() {
      if (!mounted) return;
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  Future<void> _fetchAdminData() async {
    try {
      final adminData = await _appwriteService.getAdmin(widget.adminId);
      if (!mounted) return;
      setState(() {
        _adminName = adminData['adminName'] ?? "Admin User";
        final adminImage = adminData['adminImage'] ?? 'default';
        _avatarUrl = adminImage.startsWith('https://') ? adminImage : _generateImageUrl(adminImage);
      });
    } catch (e) {
      print('Error fetching admin data: $e');
      if (mounted) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Failed to load admin data: $e'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final teacherList = await _appwriteService.getTeachers();
      final studentList = await _appwriteService.getStudents();
      final subjectList = await _appwriteService.getSubjects();

      if (!mounted) return;
      setState(() {
        _teachers = teacherList ?? [];
        _students = studentList ?? [];
        _subjects = subjectList ?? [];
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching data: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải dữ liệu: $e'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> _filterUsers(
      List<Map<String, dynamic>> users,
      String query,
      ) {
    if (query.isEmpty) return users;
    return users.where((user) {
      final name = user['studentName']?.toString().toLowerCase() ??
          user['teacherId']?.toString().toLowerCase() ??
          '';
      return name.contains(query.toLowerCase());
    }).toList();
  }

  List<Map<String, dynamic>> _filterSubjects(
      List<Map<String, dynamic>> subjects,
      String query,
      ) {
    if (query.isEmpty) return subjects;
    return subjects.where((subject) {
      final name = subject['subjectName']?.toString().toLowerCase() ?? '';
      final id = subject['subjectId']?.toString().toLowerCase() ?? '';
      return name.contains(query.toLowerCase()) || id.contains(query.toLowerCase());
    }).toList();
  }

  String _generateImageUrl(String fileId) {
    return '${_appwriteService.client.endPoint}/storage/buckets/681022e80022a492263e/files/$fileId/view?project=67f0f6cf0003bc00ed68';
  }

  void _logout() {
    if (mounted) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Đăng xuất thành công'),
          backgroundColor: Colors.green[700],
        ),
      );
    }

    // Trì hoãn điều hướng để tránh xung đột với SnackBar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _navigatorKey.currentState?.pushReplacement(
          MaterialPageRoute(
            builder: (context) => LoginScreen(),
          ),
        );
      }
    });
  }

  void _addUser(bool isTeacher) {
    _idController.clear();
    _nameController.clear();
    _facultyController.clear();
    _secretCodeController.clear();
    _teacherEmailController.clear();
    _teacherNameController.clear();

    final TextEditingController _classIdController = TextEditingController();

    XFile? pickedImage;
    Uint8List? imageBytes;

    Future<void> _pickImage() async {
      final ImagePicker picker = ImagePicker();
      pickedImage = await picker.pickImage(source: ImageSource.gallery);
      if (pickedImage != null) {
        imageBytes = await pickedImage!.readAsBytes();
        print('Picked image bytes length: ${imageBytes?.length}');
      } else {
        print('No image picked');
      }
    }

    Future<String?> _uploadImageToStorage(XFile image) async {
      try {
        final bytes = await image.readAsBytes();
        final inputFile = InputFile(bytes: bytes, filename: image.name);

        final response = await _appwriteService.storage.createFile(
          bucketId: '681022e80022a492263e',
          fileId: ID.unique(),
          file: inputFile,
        );

        return response.$id;
      } catch (e) {
        print('Error uploading image: $e');
        if (mounted) {
          _scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Text('Failed to upload image: $e'),
              backgroundColor: Colors.red[700],
            ),
          );
        }
        return null;
      }
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                isTeacher ? 'Add Teacher' : 'Add Student',
                style: GoogleFonts.poppins(),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (pickedImage != null && imageBytes != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: kIsWeb
                              ? Image.memory(
                            imageBytes!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          )
                              : Image.file(
                            File(pickedImage!.path),
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ElevatedButton(
                      onPressed: () async {
                        await _pickImage();
                        setState(() {});
                      },
                      child: Text('Pick Image', style: GoogleFonts.poppins()),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _idController,
                      decoration: InputDecoration(
                        labelText: isTeacher ? 'Teacher ID' : 'Student ID',
                        labelStyle: GoogleFonts.poppins(
                          color: Colors.blue[600],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      style: GoogleFonts.poppins(),
                    ),
                    SizedBox(height: 16),
                    if (!isTeacher)
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Student Name',
                          labelStyle: GoogleFonts.poppins(
                            color: Colors.blue[600],
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        style: GoogleFonts.poppins(),
                      ),
                    if (isTeacher)
                      TextField(
                        controller: _facultyController,
                        decoration: InputDecoration(
                          labelText: 'Faculty',
                          labelStyle: GoogleFonts.poppins(
                            color: Colors.blue[600],
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        style: GoogleFonts.poppins(),
                      ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _classIdController,
                      decoration: InputDecoration(
                        labelText: 'Class ID',
                        labelStyle: GoogleFonts.poppins(
                          color: Colors.blue[600],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      style: GoogleFonts.poppins(),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _secretCodeController,
                      decoration: InputDecoration(
                        labelText: 'Secret Code',
                        labelStyle: GoogleFonts.poppins(
                          color: Colors.blue[600],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      style: GoogleFonts.poppins(),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _teacherEmailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: GoogleFonts.poppins(
                          color: Colors.blue[600],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      style: GoogleFonts.poppins(),
                    ),
                    if (isTeacher)
                      SizedBox(height: 16),
                    if (isTeacher)
                      TextField(
                        controller: _teacherNameController,
                        decoration: InputDecoration(
                          labelText: 'Teacher Name',
                          labelStyle: GoogleFonts.poppins(
                            color: Colors.blue[600],
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        style: GoogleFonts.poppins(),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(color: Colors.grey[600]),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    if (_idController.text.isEmpty ||
                        _secretCodeController.text.isEmpty ||
                        _classIdController.text.isEmpty ||
                        _teacherEmailController.text.isEmpty ||
                        (!isTeacher && _nameController.text.isEmpty) ||
                        (isTeacher && _facultyController.text.isEmpty) ||
                        (isTeacher && _teacherNameController.text.isEmpty)) {
                      if (mounted) {
                        _scaffoldMessengerKey.currentState?.showSnackBar(
                          SnackBar(
                            content: Text('Please fill in all required fields'),
                            backgroundColor: Colors.red[700],
                          ),
                        );
                      }
                      return;
                    }
                    try {
                      String? fileId;

                      if (pickedImage != null) {
                        fileId = await _uploadImageToStorage(pickedImage!);
                        if (fileId == null) {
                          throw Exception('Failed to upload image');
                        }
                      }

                      if (isTeacher) {
                        final exists = await _appwriteService.checkTeacherExists(_idController.text);
                        if (exists) {
                          if (mounted) {
                            _scaffoldMessengerKey.currentState?.showSnackBar(
                              SnackBar(
                                content: Text('Teacher ID already exists'),
                                backgroundColor: Colors.red[700],
                              ),
                            );
                          }
                          return;
                        }
                        final classExists = await _appwriteService.checkClassIdExists(_classIdController.text);
                        bool isValidEmail(String email) {
                          final emailRegex = RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          );
                          return emailRegex.hasMatch(email);
                        }

                        if (!isValidEmail(_teacherEmailController.text)) {
                          await showDialog(
                            context: dialogContext,
                            builder: (context) => AlertDialog(
                              title: Text('Lỗi'),
                              content: Text('Vui lòng nhập email hợp lệ'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text('OK'),
                                ),
                              ],
                            ),
                          );
                          return;
                        }
                        if (classExists) {
                          await showDialog(
                            context: dialogContext,
                            builder: (context) => AlertDialog(
                              title: Text('Lỗi'),
                              content: Text('Class ID already has a teacher. Please use a different Class ID.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text('OK'),
                                ),
                              ],
                            ),
                          );
                          return;
                        }
                        await _appwriteService.addTeacher(
                          teacherId: _idController.text,
                          teacherFaculty: _facultyController.text,
                          teacherImage: fileId ?? 'default',
                          secretCode: _secretCodeController.text,
                          classId: _classIdController.text,
                          teacherEmail: _teacherEmailController.text,
                          teacherName: _teacherNameController.text,
                        );
                      } else {
                        final exists = await _appwriteService.checkStudentExists(_idController.text);
                        if (exists) {
                          await showDialog(
                            context: dialogContext,
                            builder: (context) => AlertDialog(
                              title: Text('Lỗi'),
                              content: Text('Student ID already exists.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text('OK'),
                                ),
                              ],
                            ),
                          );
                          return;
                        }

                        bool isValidEmail(String email) {
                          final emailRegex = RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          );
                          return emailRegex.hasMatch(email);
                        }

                        if (!isValidEmail(_teacherEmailController.text)) {
                          await showDialog(
                            context: dialogContext,
                            builder: (context) => AlertDialog(
                              title: Text('Lỗi'),
                              content: Text('Vui lòng nhập email hợp lệ'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text('OK'),
                                ),
                              ],
                            ),
                          );
                          return;
                        }

                        final classExists = await _appwriteService.checkClassIdExists(_classIdController.text);
                        if (!classExists) {
                          await showDialog(
                            context: dialogContext,
                            builder: (context) => AlertDialog(
                              title: Text('Lỗi'),
                              content: Text('Class ID does not exist or has no assigned teacher.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text('OK'),
                                ),
                              ],
                            ),
                          );
                          return;
                        }
                        await _appwriteService.addStudent(
                          studentId: _idController.text,
                          studentName: _nameController.text,
                          averageScore: 0.0,
                          studentImage: fileId ?? 'default',
                          secretCode: _secretCodeController.text,
                          classId: _classIdController.text,
                          subjectIds: [],
                          studentEmail: _teacherEmailController.text,
                        );
                      }
                      await _fetchData();
                      if (mounted) {
                        _scaffoldMessengerKey.currentState?.showSnackBar(
                          SnackBar(
                            content: Text('${isTeacher ? 'Teacher' : 'Student'} added successfully'),
                            backgroundColor: Colors.green[700],
                          ),
                        );
                      }
                      // Trì hoãn đóng dialog để tránh xung đột với SnackBar
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        Navigator.pop(dialogContext);
                      });
                    } catch (e) {
                      if (mounted) {
                        _scaffoldMessengerKey.currentState?.showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red[700],
                          ),
                        );
                      }
                    }
                  },
                  child: Text(
                    'Add',
                    style: GoogleFonts.poppins(color: Colors.blue[600]),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _addSubject() {
    _idController.clear();
    _nameController.clear();

    final TextEditingController _creditsController = TextEditingController();
    final TextEditingController _descriptionController = TextEditingController();
    final TextEditingController _feeController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Add Subject', style: GoogleFonts.poppins()),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _idController,
                  decoration: InputDecoration(
                    labelText: 'Subject ID',
                    labelStyle: GoogleFonts.poppins(color: Colors.blue[600]),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  style: GoogleFonts.poppins(),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Subject Name',
                    labelStyle: GoogleFonts.poppins(color: Colors.blue[600]),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  style: GoogleFonts.poppins(),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _creditsController,
                  decoration: InputDecoration(
                    labelText: 'Credit',
                    labelStyle: GoogleFonts.poppins(color: Colors.blue[600]),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  style: GoogleFonts.poppins(),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    labelStyle: GoogleFonts.poppins(color: Colors.blue[600]),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  style: GoogleFonts.poppins(),
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _feeController,
                  decoration: InputDecoration(
                    labelText: 'Fee',
                    labelStyle: GoogleFonts.poppins(color: Colors.blue[600]),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  style: GoogleFonts.poppins(),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey[600])),
            ),
            TextButton(
              onPressed: () async {
                String subjectId = _idController.text.trim();
                String subjectName = _nameController.text.trim();
                String creditText = _creditsController.text.trim();
                String feeText = _feeController.text.trim();

                if (subjectId.isEmpty || subjectName.isEmpty || creditText.isEmpty || feeText.isEmpty) {
                  if (mounted) {
                    _scaffoldMessengerKey.currentState?.showSnackBar(
                      SnackBar(
                        content: Text('Please fill in all required fields (Subject ID, Subject Name, Credits, Fee)'),
                        backgroundColor: Colors.red[700],
                      ),
                    );
                  }
                  return;
                }

                int? credit = int.tryParse(creditText);
                int? fee = int.tryParse(feeText);

                if (credit == null) {
                  await showDialog(
                    context: dialogContext,
                    builder: (context) => AlertDialog(
                      title: Text('Invalid Input', style: GoogleFonts.poppins()),
                      content: Text('Please enter valid numeric values for Credit.', style: GoogleFonts.poppins()),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('OK', style: GoogleFonts.poppins()),
                        )
                      ],
                    ),
                  );
                  return;
                }
                if (fee == null) {
                  await showDialog(
                    context: dialogContext,
                    builder: (context) => AlertDialog(
                      title: Text('Invalid Input', style: GoogleFonts.poppins()),
                      content: Text('Please enter valid numeric values for Fee.', style: GoogleFonts.poppins()),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('OK', style: GoogleFonts.poppins()),
                        )
                      ],
                    ),
                  );
                  return;
                }

                try {
                  final exists = await _appwriteService.checkSubjectExists(subjectId);
                  if (exists) {
                    if (mounted) {
                      _scaffoldMessengerKey.currentState?.showSnackBar(
                        SnackBar(
                          content: Text('Subject ID already exists'),
                          backgroundColor: Colors.red[700],
                        ),
                      );
                    }
                    return;
                  }

                  await _appwriteService.addSubject(
                    subjectId: subjectId,
                    subjectName: subjectName,
                    credits: credit,
                    description: _descriptionController.text.trim(),
                    fee: fee,
                  );

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Navigator.pop(dialogContext);
                  });

                  await _fetchData();

                  // Trì hoãn đóng dialog để đảm bảo không có xung đột với widget tree


                  // Xóa controller sau khi sử dụng
                  _creditsController.dispose();
                  _descriptionController.dispose();
                  _feeController.dispose();
                } catch (e) {
                  if (mounted) {
                    _scaffoldMessengerKey.currentState?.showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red[700],
                      ),
                    );
                  }
                }
              },
              child: Text(
                'Add',
                style: GoogleFonts.poppins(color: Colors.blue[600]),
              ),
            ),
          ],
        );
      },
    );
  }

  void _editUser(Map<String, dynamic> user, bool isTeacher) {
    final TextEditingController _classIdController = TextEditingController();

    if (!isTeacher) {
      _nameController.text = user['studentName']?.toString() ?? '';
    }
    _facultyController.text = user['teacherFaculty']?.toString() ?? '';
    _classIdController.text = user['classId']?.toString() ?? '';

    XFile? pickedImage;
    Uint8List? imageBytes;
    String? imageUrl;

    Future<void> _pickImage() async {
      final ImagePicker picker = ImagePicker();
      pickedImage = await picker.pickImage(source: ImageSource.gallery);
      if (pickedImage != null) {
        imageBytes = await pickedImage!.readAsBytes();
        print('Picked image bytes length: ${imageBytes?.length}');
      } else {
        print('No image picked');
      }
    }

    Future<String?> _uploadImageToStorage(XFile image) async {
      try {
        final bytes = await image.readAsBytes();
        final inputFile = InputFile(bytes: bytes, filename: image.name);

        final response = await _appwriteService.storage.createFile(
          bucketId: '681022e80022a492263e',
          fileId: ID.unique(),
          file: inputFile,
        );

        return response.$id;
      } catch (e) {
        print('Error uploading image: $e');
        if (mounted) {
          _scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Text('Failed to upload image: $e'),
              backgroundColor: Colors.red[700],
            ),
          );
        }
        return null;
      }
    }

    if (user[isTeacher ? 'teacherImage' : 'studentImage'] != null) {
      imageUrl = user[isTeacher ? 'teacherImage' : 'studentImage'].startsWith('https://')
          ? user[isTeacher ? 'teacherImage' : 'studentImage']
          : _generateImageUrl(user[isTeacher ? 'teacherImage' : 'studentImage']);
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'Edit ${isTeacher ? 'Teacher' : 'Student'}',
                style: GoogleFonts.poppins(),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (imageUrl != null || (pickedImage != null && imageBytes != null))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: imageUrl != null && pickedImage == null
                              ? Image.network(
                            imageUrl!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              print('Error loading image from URL $imageUrl: $error');
                              return const Icon(Icons.error);
                            },
                          )
                              : kIsWeb
                              ? Image.memory(
                            imageBytes!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          )
                              : Image.file(
                            File(pickedImage!.path),
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ElevatedButton(
                      onPressed: () async {
                        await _pickImage();
                        setState(() {});
                      },
                      child: Text('Pick Image', style: GoogleFonts.poppins()),
                    ),
                    SizedBox(height: 16),
                    if (!isTeacher)
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Student Name',
                          labelStyle: GoogleFonts.poppins(color: Colors.blue[600]),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        style: GoogleFonts.poppins(),
                      ),
                    if (isTeacher)
                      TextField(
                        controller: _facultyController,
                        decoration: InputDecoration(
                          labelText: 'Faculty',
                          labelStyle: GoogleFonts.poppins(color: Colors.blue[600]),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        style: GoogleFonts.poppins(),
                      ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _classIdController,
                      decoration: InputDecoration(
                        labelText: 'Class ID',
                        labelStyle: GoogleFonts.poppins(color: Colors.blue[600]),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      style: GoogleFonts.poppins(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(color: Colors.grey[600]),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    if (!isTeacher && _nameController.text.isEmpty) {
                      if (mounted) {
                        _scaffoldMessengerKey.currentState?.showSnackBar(
                          SnackBar(
                            content: Text('Please fill in the name field'),
                            backgroundColor: Colors.red[700],
                          ),
                        );
                      }
                      return;
                    }
                    if (isTeacher && _facultyController.text.isEmpty) {
                      if (mounted) {
                        _scaffoldMessengerKey.currentState?.showSnackBar(
                          SnackBar(
                            content: Text('Please fill in the faculty field'),
                            backgroundColor: Colors.red[700],
                          ),
                        );
                      }
                      return;
                    }
                    try {
                      String? fileId;

                      if (pickedImage != null) {
                        fileId = await _uploadImageToStorage(pickedImage!);
                        if (fileId == null) {
                          throw Exception('Failed to upload image');
                        }
                      }

                      if (isTeacher) {
                        await _appwriteService.updateTeacher(
                          teacherId: user['teacherId'],
                          teacherFaculty: _facultyController.text,
                          teacherImage: fileId ?? user['teacherImage'] ?? 'default',
                          secretCode: user['secretCode']?.toString() ?? '',
                          classId: _classIdController.text.isNotEmpty ? _classIdController.text : null,
                        );
                      } else {
                        final subjectIds = (user['subjectIds'] as List<dynamic>?)?.map((id) => id.toString()).toList() ?? [];

                        await _appwriteService.updateStudent(
                          studentId: user['studentId'],
                          studentName: _nameController.text,
                          averageScore: user['averageScore']?.toDouble() ?? 0.0,
                          studentImage: fileId ?? user['studentImage'] ?? 'default',
                          secretCode: user['secretCode']?.toString() ?? '',
                          classId: _classIdController.text.isNotEmpty ? _classIdController.text : null,
                          subjectIds: subjectIds,
                        );
                      }
                      await _fetchData();
                      if (mounted) {
                        _scaffoldMessengerKey.currentState?.showSnackBar(
                          SnackBar(
                            content: Text('${isTeacher ? 'Teacher' : 'Student'} updated successfully'),
                            backgroundColor: Colors.green[700],
                          ),
                        );
                      }
                      // Trì hoãn đóng dialog để tránh xung đột với SnackBar
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        Navigator.pop(dialogContext);
                      });
                    } catch (e) {
                      print('Error updating user: $e');
                      if (mounted) {
                        _scaffoldMessengerKey.currentState?.showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red[700],
                          ),
                        );
                      }
                    }
                  },
                  child: Text(
                    'Save',
                    style: GoogleFonts.poppins(color: Colors.blue[600]),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _editSubject(Map<String, dynamic> subject) {
    _nameController.text = subject['subjectName']?.toString() ?? '';
    final TextEditingController _descriptionController = TextEditingController(text: subject['description']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Edit Subject', style: GoogleFonts.poppins()),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Subject Name',
                    labelStyle: GoogleFonts.poppins(color: Colors.blue[600]),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  style: GoogleFonts.poppins(),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    labelStyle: GoogleFonts.poppins(color: Colors.blue[600]),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  style: GoogleFonts.poppins(),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
            ),
            TextButton(
              onPressed: () async {
                if (_nameController.text.isEmpty) {
                  if (mounted) {
                    _scaffoldMessengerKey.currentState?.showSnackBar(
                      SnackBar(
                        content: Text('Please fill in all fields'),
                        backgroundColor: Colors.red[700],
                      ),
                    );
                  }
                  return;
                }
                try {
                  await _appwriteService.updateSubject(
                    subjectId: subject['subjectId'],
                    subjectName: _nameController.text.trim(),
                    description: _descriptionController.text.trim(),
                  );
                  await _fetchData();
                  if (mounted) {
                    _scaffoldMessengerKey.currentState?.showSnackBar(
                      SnackBar(
                        content: Text('Subject updated successfully'),
                        backgroundColor: Colors.green[700],
                      ),
                    );
                  }
                  // Trì hoãn đóng dialog để tránh xung đột với SnackBar
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Navigator.pop(dialogContext);
                  });
                  _descriptionController.dispose();
                } catch (e) {
                  if (mounted) {
                    _scaffoldMessengerKey.currentState?.showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red[700],
                      ),
                    );
                  }
                }
              },
              child: Text(
                'Save',
                style: GoogleFonts.poppins(color: Colors.blue[600]),
              ),
            ),
          ],
        );
      },
    );
  }

  void _deleteUser(Map<String, dynamic> user, bool isTeacher) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Confirm Delete', style: GoogleFonts.poppins()),
          content: Text(
            'Are you sure you want to delete this ${isTeacher ? 'teacher' : 'student'}?',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                'Yes',
                style: GoogleFonts.poppins(color: Colors.red[700]),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      if (isTeacher) {
        await _appwriteService.deleteTeacher(user['teacherId']);
      } else {
        await _appwriteService.deleteStudent(user['studentId']);
      }
      await _fetchData();
      if (mounted) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('${isTeacher ? 'Teacher' : 'Student'} deleted successfully'),
            backgroundColor: Colors.green[700],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red[700]),
        );
      }
    }
  }

  void _deleteSubject(Map<String, dynamic> subject) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Confirm Delete', style: GoogleFonts.poppins()),
          content: Text(
            'Are you sure you want to delete this subject?',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                'Yes',
                style: GoogleFonts.poppins(color: Colors.red[700]),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await _appwriteService.deleteSubject(subject['subjectId']);
      await _fetchData();
      if (mounted) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Subject deleted successfully'),
            backgroundColor: Colors.green[700],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }

  Future<void> _saveScore() async {
    if (_studentIdController.text.isEmpty ||
        _subjectIdController.text.isEmpty ||
        _scoreController.text.isEmpty) {
      if (mounted) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Please fill in all fields'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
      return;
    }

    try {
      double score = double.parse(_scoreController.text);
      if (score < 0 || score > 10) {
        if (mounted) {
          _scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Text('Score must be between 0 and 10'),
              backgroundColor: Colors.red[700],
            ),
          );
        }
        return;
      }

      final studentExists = await _appwriteService.checkStudentExists(_studentIdController.text);
      if (!studentExists) {
        if (mounted) {
          _scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Text('Student not found'),
              backgroundColor: Colors.red[700],
            ),
          );
        }
        return;
      }

      final subjectExists = await _appwriteService.checkSubjectExists(_subjectIdController.text);
      if (!subjectExists) {
        if (mounted) {
          _scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Text('Subject not found'),
              backgroundColor: Colors.red[700],
            ),
          );
        }
        return;
      }

      final studentData = await _appwriteService.getStudentById(_studentIdController.text);
      final subjectIds = (studentData['subjectIds'] as List<dynamic>?)?.map((id) => id.toString()).toList() ?? [];
      if (!subjectIds.contains(_subjectIdController.text)) {
        if (mounted) {
          _scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Text('Student has not registered for this subject'),
              backgroundColor: Colors.red[700],
            ),
          );
        }
        return;
      }

      await _appwriteService.saveScore(
        studentId: _studentIdController.text,
        subjectId: _subjectIdController.text,
        score: _scoreController.text,
      );

      final scores = await _appwriteService.getScoresByStudentId(_studentIdController.text);
      double totalScore = 0.0;
      int scoreCount = scores.length;
      for (var s in scores) {
        totalScore += (s['score']?.toDouble() ?? 0.0);
      }
      double averageScore = scoreCount > 0 ? totalScore / scoreCount : 0.0;

      await _appwriteService.updateStudent(
        studentId: studentData['studentId'],
        studentName: studentData['studentName']?.toString() ?? '',
        averageScore: averageScore,
        studentImage: studentData['studentImage'] ?? 'default',
        secretCode: studentData['secretCode']?.toString() ?? '',
        classId: studentData['classId']?.toString(),
        subjectIds: subjectIds,
      );

      await _fetchData();
      if (mounted) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(
              'Score ${_scoreController.text} saved for Student ID ${_studentIdController.text} in Subject ID ${_subjectIdController.text}',
            ),
            backgroundColor: Colors.green[700],
          ),
        );
      }

      _studentIdController.clear();
      _subjectIdController.clear();
      _scoreController.clear();
    } catch (e) {
      if (mounted) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Failed to save score: $e'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }

  List<Widget> _buildScreens() {
    if (_isLoading) {
      return [
        Center(child: CircularProgressIndicator()),
        Center(child: CircularProgressIndicator()),
        Center(child: CircularProgressIndicator()),
        Center(child: CircularProgressIndicator()),
      ];
    }

    return [
      // Teachers Screen
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Teachers',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue[600],
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search Teachers...',
                hintStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.search, color: Colors.blue[600]),
              ),
              style: GoogleFonts.poppins(),
            ),
            SizedBox(height: 16),
            Expanded(
              child: _teachers.isEmpty
                  ? Center(
                child: Text(
                  'No teachers found',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              )
                  : ListView.builder(
                itemCount: _filterUsers(_teachers, _searchQuery).length,
                itemBuilder: (context, index) {
                  final teacher = _filterUsers(_teachers, _searchQuery)[index];
                  String? imageUrl;

                  if (teacher['teacherImage'] != null &&
                      teacher['teacherImage'].isNotEmpty &&
                      teacher['teacherImage'] != 'default' &&
                      !teacher['teacherImage'].startsWith('https://')) {
                    imageUrl = _generateImageUrl(teacher['teacherImage']);
                  }

                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      onTap: () {
                        // Trì hoãn điều hướng để tránh xung đột
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            _navigatorKey.currentState?.push(
                              MaterialPageRoute(
                                builder: (context) => TeacherDetailScreen(
                                  teacherId: teacher['teacherId']?.toString() ?? '',
                                ),
                              ),
                            );
                          }
                        });
                      },
                      leading: CircleAvatar(
                        backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                            ? NetworkImage(imageUrl)
                            : teacher['teacherImage'] != null &&
                            teacher['teacherImage'].isNotEmpty &&
                            teacher['teacherImage'].startsWith('https://')
                            ? NetworkImage(teacher['teacherImage'])
                            : const AssetImage('assets/images/default_avatar.png'),
                      ),
                      title: Text(
                        teacher['teacherId']?.toString() ?? 'Unknown',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        'Faculty: ${teacher['teacherFaculty']?.toString() ?? 'N/A'} | Class: ${teacher['classId']?.toString() ?? 'N/A'}',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                        ),
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          color: Colors.blue[600],
                        ),
                        onSelected: (value) {
                          if (value == 'edit') {
                            _editUser(teacher, true);
                          } else if (value == 'delete') {
                            _deleteUser(teacher, true);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text(
                              'Edit',
                              style: GoogleFonts.poppins(
                                color: Colors.blue[600],
                              ),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              'Delete',
                              style: GoogleFonts.poppins(
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      // Students Screen
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Students',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue[600],
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search Students...',
                hintStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.search, color: Colors.blue[600]),
              ),
              style: GoogleFonts.poppins(),
              onChanged: (value) {
                if (!mounted) return;
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            SizedBox(height: 16),
            Expanded(
              child: _students.isEmpty
                  ? Center(
                child: Text(
                  'No students found',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              )
                  : ListView.builder(
                itemCount: _filterUsers(_students, _searchQuery).length,
                itemBuilder: (context, index) {
                  final student = _filterUsers(_students, _searchQuery)[index];
                  String? imageUrl;

                  if (student['studentImage'] != null &&
                      student['studentImage'].isNotEmpty &&
                      student['studentImage'] != 'default' &&
                      !student['studentImage'].startsWith('https://')) {
                    imageUrl = _generateImageUrl(student['studentImage']);
                  }

                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      onTap: () {
                        // Trì hoãn điều hướng để tránh xung đột
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            _navigatorKey.currentState?.push(
                              MaterialPageRoute(
                                builder: (context) => StudentDetailScreen(
                                  studentId: student['studentId']?.toString() ?? '',
                                ),
                              ),
                            );
                          }
                        });
                      },
                      leading: CircleAvatar(
                        backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                            ? NetworkImage(imageUrl)
                            : student['studentImage'] != null &&
                            student['studentImage'].isNotEmpty &&
                            student['studentImage'].startsWith('https://')
                            ? NetworkImage(student['studentImage'])
                            : const AssetImage('assets/images/default_avatar.png'),
                      ),
                      title: Text(
                        student['studentName']?.toString() ?? 'N/A',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        'ID: ${student['studentId']?.toString() ?? 'N/A'} | Score: ${student['averageScore']?.toString() ?? 'N/A'} | Class: ${student['classId']?.toString() ?? 'N/A'}',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                        ),
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          color: Colors.blue[600],
                        ),
                        onSelected: (value) {
                          if (value == 'edit') {
                            _editUser(student, false);
                          } else if (value == 'delete') {
                            _deleteUser(student, false);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text(
                              'Edit',
                              style: GoogleFonts.poppins(
                                color: Colors.blue[600],
                              ),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              'Delete',
                              style: GoogleFonts.poppins(
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      // Subjects Screen
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subjects',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue[600],
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search Subjects...',
                hintStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.search, color: Colors.blue[600]),
              ),
              style: GoogleFonts.poppins(),
              onChanged: (value) {
                if (!mounted) return;
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            SizedBox(height: 16),
            Expanded(
              child: _subjects.isEmpty
                  ? Center(
                child: Text(
                  'No subjects found',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              )
                  : ListView.builder(
                itemCount: _filterSubjects(_subjects, _searchQuery).length,
                itemBuilder: (context, index) {
                  final subject = _filterSubjects(_subjects, _searchQuery)[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      onTap: () {
                        // Trì hoãn điều hướng để tránh xung đột
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            _navigatorKey.currentState?.push(
                              MaterialPageRoute(
                                builder: (context) => SubjectDetailScreen(
                                  subjectId: subject['subjectId']?.toString() ?? '',
                                ),
                              ),
                            );
                          }
                        });
                      },
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue[100],
                        child: Text(
                          subject['subjectName']?.toString()[0] ?? 'S',
                          style: TextStyle(color: Colors.blue[600]),
                        ),
                      ),
                      title: Text(
                        subject['subjectName']?.toString() ?? 'Unknown',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        'ID: ${subject['subjectId']?.toString() ?? 'N/A'}',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                        ),
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          color: Colors.blue[600],
                        ),
                        onSelected: (value) {
                          if (value == 'edit') {
                            _editSubject(subject);
                          } else if (value == 'delete') {
                            _deleteSubject(subject);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text(
                              'Edit',
                              style: GoogleFonts.poppins(
                                color: Colors.blue[600],
                              ),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              'Delete',
                              style: GoogleFonts.poppins(
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      // Enter Score Screen
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter Score',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue[600],
              ),
            ),
            SizedBox(height: 24),
            TextField(
              controller: _studentIdController,
              decoration: InputDecoration(
                labelText: 'Student ID',
                labelStyle: GoogleFonts.poppins(color: Colors.blue[600]),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.person, color: Colors.blue[600]),
              ),
              style: GoogleFonts.poppins(),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _subjectIdController,
              decoration: InputDecoration(
                labelText: 'Subject ID',
                labelStyle: GoogleFonts.poppins(color: Colors.blue[600]),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.book, color: Colors.blue[600]),
              ),
              style: GoogleFonts.poppins(),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _scoreController,
              decoration: InputDecoration(
                labelText: 'Score',
                labelStyle: GoogleFonts.poppins(color: Colors.blue[600]),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.score, color: Colors.blue[600]),
              ),
              keyboardType: TextInputType.number,
              style: GoogleFonts.poppins(),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _saveScore,
              child: Text(
                'Submit Score',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  void _onItemTapped(int index) {
    if (!mounted) return;
    setState(() {
      _selectedIndex = index;
      _searchController.clear();
      _searchQuery = '';
    });
  }

  void _changeAvatar() {
    XFile? pickedImage;
    Uint8List? imageBytes;

    Future<void> _pickImage() async {
      final ImagePicker picker = ImagePicker();
      pickedImage = await picker.pickImage(source: ImageSource.gallery);
      if (pickedImage != null) {
        imageBytes = await pickedImage!.readAsBytes();
        print('Picked image bytes length: ${imageBytes?.length}');
      } else {
        print('No image picked');
      }
    }

    Future<String?> _uploadImageToStorage() async {
      if (pickedImage == null || imageBytes == null) return null;
      try {
        final fileId = await _appwriteService.uploadImage(imageBytes!, pickedImage!.name);
        return fileId;
      } catch (e) {
        print('Error uploading image: $e');
        if (mounted) {
          _scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Text('Failed to upload image: $e'),
              backgroundColor: Colors.red[700],
            ),
          );
        }
        return null;
      }
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Change Profile Picture', style: GoogleFonts.poppins()),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (pickedImage != null && imageBytes != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: kIsWeb
                              ? Image.memory(
                            imageBytes!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          )
                              : Image.file(
                            File(pickedImage!.path),
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ElevatedButton(
                      onPressed: () async {
                        await _pickImage();
                        setDialogState(() {});
                      },
                      child: Text('Pick Image', style: GoogleFonts.poppins()),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey[600])),
                ),
                TextButton(
                  onPressed: () async {
                    if (pickedImage == null || imageBytes == null) {
                      if (mounted) {
                        _scaffoldMessengerKey.currentState?.showSnackBar(
                          SnackBar(
                            content: Text('Please pick an image first'),
                            backgroundColor: Colors.red[700],
                          ),
                        );
                      }
                      return;
                    }

                    try {
                      final fileId = await _uploadImageToStorage();
                      if (fileId == null) {
                        throw Exception('Failed to upload image');
                      }

                      await _appwriteService.updateAdmin(
                        adminId: widget.adminId,
                        adminName: _adminName,
                        adminImage: fileId,
                      );

                      // Clear the cache for the old image URL
                      imageCache.evict(NetworkImage(_avatarUrl));

                      await _fetchAdminData();

                      if (mounted) {
                        _scaffoldMessengerKey.currentState?.showSnackBar(
                          SnackBar(
                            content: Text('Profile picture updated successfully'),
                            backgroundColor: Colors.green[700],
                          ),
                        );
                      }

                      // Trì hoãn đóng dialog để tránh xung đột với SnackBar
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        Navigator.pop(dialogContext);
                      });
                    } catch (e) {
                      if (mounted) {
                        _scaffoldMessengerKey.currentState?.showSnackBar(
                          SnackBar(
                            content: Text('Failed to update profile picture: $e'),
                            backgroundColor: Colors.red[700],
                          ),
                        );
                      }
                    }
                  },
                  child: Text('Save', style: GoogleFonts.poppins(color: Colors.blue[600])),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _changeName() {
    _nameController.clear(); // Reset controller trước khi mở dialog

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Change Name', style: GoogleFonts.poppins()),
          content: TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'New Name',
              labelStyle: GoogleFonts.poppins(color: Colors.blue[600]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
            ),
            TextButton(
              onPressed: () async {
                if (_nameController.text.isNotEmpty) {
                  try {
                    await _appwriteService.updateAdmin(
                      adminId: widget.adminId,
                      adminName: _nameController.text,
                      adminImage: _avatarUrl,
                    );

                    if (!mounted) {
                      Navigator.pop(dialogContext);
                      return;
                    }

                    setState(() {
                      _adminName = _nameController.text;
                    });

                    _nameController.clear();

                    if (mounted) {
                      _scaffoldMessengerKey.currentState?.showSnackBar(
                        SnackBar(
                          content: Text('Name updated to $_adminName'),
                          backgroundColor: Colors.blue[700],
                        ),
                      );
                    }

                    // Trì hoãn đóng dialog để tránh xung đột với SnackBar
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.pop(dialogContext);
                    });
                  } catch (e) {
                    if (mounted) {
                      _scaffoldMessengerKey.currentState?.showSnackBar(
                        SnackBar(
                          content: Text('Failed to update name: $e'),
                          backgroundColor: Colors.red[700],
                        ),
                      );
                    }
                  }
                }
              },
              child: Text(
                'Save',
                style: GoogleFonts.poppins(color: Colors.blue[600]),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      home: Scaffold(
        key: _scaffoldMessengerKey,
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          backgroundColor: Colors.blue[600],
          title: Text(
            'Admin Dashboard',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.white),
              onPressed: _fetchData,
            ),
          ],
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: Colors.blue[600]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      key: UniqueKey(),
                      radius: 40,
                      backgroundImage: _avatarUrl.isNotEmpty && _avatarUrl.startsWith('https://')
                          ? NetworkImage(_avatarUrl)
                          : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                      onBackgroundImageError: (error, stackTrace) {
                        print('Error loading admin avatar from URL $_avatarUrl: $error');
                      },
                    ),
                    SizedBox(height: 8),
                    Text(
                      _adminName,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'admin@example.com',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: Icon(Icons.image, color: Colors.blue[600]),
                title: Text(
                  'Change Profile Picture',
                  style: GoogleFonts.poppins(),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _changeAvatar();
                },
              ),
              ListTile(
                leading: Icon(Icons.edit, color: Colors.blue[600]),
                title: Text('Change Name', style: GoogleFonts.poppins()),
                onTap: () {
                  Navigator.pop(context);
                  _changeName();
                },
              ),
              ListTile(
                leading: Icon(Icons.logout, color: Colors.blue[600]),
                title: Text('Log out', style: GoogleFonts.poppins()),
                onTap: () {
                  Navigator.pop(context);
                  _logout();
                },
              ),
            ],
          ),
        ),
        body: _buildScreens()[_selectedIndex],
        floatingActionButton: (_selectedIndex == 0 || _selectedIndex == 1 || _selectedIndex == 2)
            ? FloatingActionButton(
          backgroundColor: Colors.blue[600],
          onPressed: () {
            if (_selectedIndex == 0) {
              _addUser(true);
            } else if (_selectedIndex == 1) {
              _addUser(false);
            } else {
              _addSubject();
            }
          },
          child: Icon(Icons.add, color: Colors.white),
        )
            : null,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: Colors.blue[600],
          unselectedItemColor: Colors.grey[600],
          backgroundColor: Colors.white,
          elevation: 8,
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Teachers'),
            BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Students'),
            BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Subjects'),
            BottomNavigationBarItem(
              icon: Icon(Icons.score),
              label: 'Enter Score',
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _studentIdController.dispose();
    _subjectIdController.dispose();
    _scoreController.dispose();
    _nameController.dispose();
    _facultyController.dispose();
    _idController.dispose();
    _secretCodeController.dispose();
    _teacherEmailController.dispose();
    _teacherNameController.dispose();
    _subjectDescriptionController.dispose();
    _subjectCreditController.dispose();
    super.dispose();
  }
}