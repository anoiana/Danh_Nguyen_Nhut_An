import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:midterm/screens/studentDetail.dart';
import 'package:midterm/screens/subjectDetail.dart';
import '../service/AppwriteService.dart';
import 'loginScreen.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:appwrite/appwrite.dart';
import 'package:flutter/painting.dart';

class TeacherScreen extends StatefulWidget {
  final String teacherId;

  const TeacherScreen({required this.teacherId});

  @override
  _TeacherScreenState createState() => _TeacherScreenState();
}

class _TeacherScreenState extends State<TeacherScreen> {
  int _selectedIndex = 0;
  final AppwriteService _appwriteService = AppwriteService();

  Map<String, dynamic>? _teacher;
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _subjects = [];
  bool _isLoadingTeacher = false;
  bool _isLoadingStudents = false;
  bool _isLoadingSubjects = false;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _subjectIdController = TextEditingController();
  final TextEditingController _scoreController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _secretCodeController = TextEditingController();
  final TextEditingController _classIdController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  Future<void> _fetchData() async {
    await _fetchTeacher();
    await _fetchStudents();
    await _fetchSubjects();
  }

  Future<void> _fetchTeacher() async {
    setState(() {
      _isLoadingTeacher = true;
    });
    try {
      final teacherData = await _appwriteService.getTeacherById(
        widget.teacherId,
      );
      setState(() {
        _teacher = teacherData;
        _isLoadingTeacher = false;
      });
    } catch (e) {
      print('Error fetching teacher: $e');
      setState(() {
        _isLoadingTeacher = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load teacher data: $e'),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  Future<void> _fetchStudents() async {
    setState(() {
      _isLoadingStudents = true;
    });
    try {
      if (_teacher == null || _teacher!['classId'] == null) {
        setState(() {
          _students = [];
          _isLoadingStudents = false;
        });
        return;
      }
      final students = await _appwriteService.getStudentsByClassId(
        _teacher!['classId'],
      );
      setState(() {
        _students = students ?? [];
        _isLoadingStudents = false;
      });
    } catch (e) {
      print('Error fetching students: $e');
      setState(() {
        _isLoadingStudents = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load students: $e'),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  Future<void> _fetchSubjects() async {
    setState(() {
      _isLoadingSubjects = true;
    });
    try {
      final subjects = await _appwriteService.getSubjects();
      setState(() {
        _subjects = subjects ?? [];
        _isLoadingSubjects = false;
      });
    } catch (e) {
      print('Error fetching subjects: $e');
      setState(() {
        _isLoadingSubjects = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load subjects: $e'),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  List<Map<String, dynamic>> _filterStudents(
    List<Map<String, dynamic>> students,
    String query,
  ) {
    if (query.isEmpty) return students;
    return students.where((student) {
      final name = student['studentName']?.toString().toLowerCase() ?? '';
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
      return name.contains(query.toLowerCase()) ||
          id.contains(query.toLowerCase());
    }).toList();
  }

  String _generateImageUrl(String fileId) {
    return '${_appwriteService.client.endPoint}/storage/buckets/681022e80022a492263e/files/$fileId/view?project=67f0f6cf0003bc00ed68';
  }

  void _addItem(bool isStudent) {
    _idController.clear();
    _nameController.clear();
    _secretCodeController.clear();
    _classIdController.clear();
    _emailController.clear(); // Xóa email controller

    if (isStudent && _teacher != null) {
      _classIdController.text = _teacher!['classId']?.toString() ?? '';
    }

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: $e'),
            backgroundColor: Colors.red[700],
          ),
        );
        return null;
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        // Thêm các controller cho các trường mới
        final TextEditingController _creditsController = TextEditingController();
        final TextEditingController _descriptionController = TextEditingController();
        final TextEditingController _feeController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                isStudent ? 'Add Student' : 'Add Subject',
                style: GoogleFonts.poppins(),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Hiển thị ảnh nếu đã chọn
                    if (isStudent && pickedImage != null && imageBytes != null)
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
                    // Nút chọn ảnh (chỉ hiển thị khi thêm student)
                    if (isStudent)
                      ElevatedButton(
                        onPressed: () async {
                          await _pickImage();
                          setState(() {});
                        },
                        child: Text('Pick Image', style: GoogleFonts.poppins()),
                      ),
                    if (isStudent) SizedBox(height: 16),
                    TextField(
                      controller: _idController,
                      decoration: InputDecoration(
                        labelText: isStudent ? 'Student ID' : 'Subject ID',
                        labelStyle: GoogleFonts.poppins(color: Colors.blue[600]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      style: GoogleFonts.poppins(),
                    ),
                    SizedBox(height: 16),
                    if (isStudent)
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Student Name',
                          labelStyle: GoogleFonts.poppins(color: Colors.blue[600]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        style: GoogleFonts.poppins(),
                      ),
                    if (!isStudent)
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Subject Name',
                          labelStyle: GoogleFonts.poppins(color: Colors.blue[600]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        style: GoogleFonts.poppins(),
                      ),
                    if (isStudent) SizedBox(height: 16),
                    if (isStudent)
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: GoogleFonts.poppins(color: Colors.blue[600]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        style: GoogleFonts.poppins(),
                      ),
                    if (isStudent) SizedBox(height: 16),
                    if (isStudent)
                      TextField(
                        controller: _secretCodeController,
                        decoration: InputDecoration(
                          labelText: 'Secret Code',
                          labelStyle: GoogleFonts.poppins(color: Colors.blue[600]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        style: GoogleFonts.poppins(),
                      ),
                    if (isStudent) SizedBox(height: 16),
                    if (isStudent)
                      TextField(
                        controller: _classIdController,
                        decoration: InputDecoration(
                          labelText: 'Class ID',
                          labelStyle: GoogleFonts.poppins(color: Colors.blue[600]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        style: GoogleFonts.poppins(),
                        readOnly: true,
                      ),
                    if (!isStudent) SizedBox(height: 16),
                    if (!isStudent)
                      TextField(
                        controller: _creditsController,
                        decoration: InputDecoration(
                          labelText: 'Credits',
                          labelStyle: GoogleFonts.poppins(color: Colors.blue[600]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        style: GoogleFonts.poppins(),
                        keyboardType: TextInputType.number,
                      ),
                    if (!isStudent) SizedBox(height: 16),
                    if (!isStudent)
                      TextField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          labelStyle: GoogleFonts.poppins(color: Colors.blue[600]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        style: GoogleFonts.poppins(),
                        maxLines: 3,
                      ),
                    if (!isStudent) SizedBox(height: 16),
                    if (!isStudent)
                      TextField(
                        controller: _feeController,
                        decoration: InputDecoration(
                          labelText: 'Fee',
                          labelStyle: GoogleFonts.poppins(color: Colors.blue[600]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        style: GoogleFonts.poppins(),
                        keyboardType: TextInputType.number,
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel',
                      style: GoogleFonts.poppins(color: Colors.grey[600])),
                ),
                TextButton(
                  onPressed: () async {
                    String errorMessage = '';
                    if (_idController.text.trim().isEmpty) {
                      errorMessage =
                      'Please enter ${isStudent ? 'Student ID' : 'Subject ID'}';
                    } else if (_nameController.text.trim().isEmpty) {
                      errorMessage =
                      isStudent
                          ? 'Please enter Student Name'
                          : 'Please enter Subject Name';
                    } else if (isStudent &&
                        _secretCodeController.text.trim().isEmpty) {
                      errorMessage = 'Please enter Secret Code';
                    } else if (isStudent &&
                        _classIdController.text.trim().isEmpty) {
                      errorMessage = 'Class ID is required';
                    } else if (isStudent &&
                        _emailController.text.trim().isEmpty) {
                      errorMessage = 'Please enter Email';
                    } else if (!isStudent &&
                        _creditsController.text.trim().isEmpty) {
                      errorMessage = 'Please enter Credits';
                    } else if (!isStudent && _feeController.text.trim().isEmpty) {
                      errorMessage = 'Please enter Fee';
                    }

                    if (errorMessage.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(errorMessage),
                          backgroundColor: Colors.red[700],
                        ),
                      );
                      return;
                    }

                    // Kiểm tra định dạng email nếu là student
                    if (isStudent) {
                      bool isValidEmail(String email) {
                        final emailRegex = RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        );
                        return emailRegex.hasMatch(email);
                      }

                      if (!isValidEmail(_emailController.text.trim())) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Please enter a valid email'),
                            backgroundColor: Colors.red[700],
                          ),
                        );
                        return;
                      }
                    }

                    try {
                      String? fileId;
                      if (isStudent && pickedImage != null) {
                        fileId = await _uploadImageToStorage(pickedImage!);
                        if (fileId == null) {
                          throw Exception('Failed to upload image');
                        }
                      }

                      if (isStudent) {
                        final exists = await _appwriteService.checkStudentExists(
                          _idController.text,
                        );
                        if (exists) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Student ID already exists'),
                              backgroundColor: Colors.red[700],
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
                          studentEmail: _emailController.text.trim(),
                        );
                      } else {
                        final exists = await _appwriteService.checkSubjectExists(
                          _idController.text,
                        );
                        if (exists) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Subject ID already exists'),
                              backgroundColor: Colors.red[700],
                            ),
                          );
                          return;
                        }
                        await _appwriteService.addSubject(
                          subjectId: _idController.text,
                          subjectName: _nameController.text,
                          credits: int.tryParse(_creditsController.text) ?? 0,
                          description: _descriptionController.text.trim(),
                          fee: int.tryParse(_feeController.text) ?? 0,
                        );
                      }

                      Navigator.pop(context);
                      
                      if (isStudent) {
                        await _fetchStudents();
                      } else {
                        await _fetchSubjects();
                      }


                      // Xóa các controller sau khi sử dụng
                      _creditsController.dispose();
                      _descriptionController.dispose();
                      _feeController.dispose();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red[700],
                        ),
                      );
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

  void _editStudent(Map<String, dynamic> student) {
    _nameController.text = student['studentName']?.toString() ?? '';
    _classIdController.text = student['classId']?.toString() ?? '';

    XFile? pickedImage; // To store the newly picked image
    Uint8List? imageBytes; // To store the bytes of the newly picked image
    Uint8List? currentImageBytes; // To store the bytes of the current student image

    // Load the current student image if it exists
    Future<void> _loadCurrentImage() async {
      if (student['studentImage'] != null && student['studentImage'] != 'default') {
        try {
          currentImageBytes = await _appwriteService.getImageBytes(student['studentImage']);
        } catch (e) {
          print('Failed to load current student image: $e');
          currentImageBytes = null;
        }
      }
    }

    // Pick a new image
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

    // Upload the new image to Appwrite storage
    Future<String?> _uploadImageToStorage() async {
      if (pickedImage == null || imageBytes == null) return null;
      try {
        final fileId = await _appwriteService.uploadImage(imageBytes!, pickedImage!.name);
        return fileId;
      } catch (e) {
        print('Error uploading image: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: $e'),
            backgroundColor: Colors.red[700],
          ),
        );
        return null;
      }
    }

    // Load the current image before showing the dialog
    _loadCurrentImage().then((_) {
      showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Text('Edit Student', style: GoogleFonts.poppins()),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Display current or newly picked image
                      if (imageBytes != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              imageBytes!,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      else if (currentImageBytes != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              currentImageBytes!,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: const AssetImage('assets/images/default_avatar.png'),
                          ),
                        ),
                      // Button to pick a new image
                      ElevatedButton(
                        onPressed: () async {
                          await _pickImage();
                          setDialogState(() {}); // Update the dialog UI
                        },
                        child: Text('Pick Image', style: GoogleFonts.poppins()),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Student Name',
                          labelStyle: GoogleFonts.poppins(color: Colors.blue[600]),
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
                          labelStyle: GoogleFonts.poppins(color: Colors.blue[600]),
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
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(color: Colors.grey[600]),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      if (_nameController.text.isEmpty || _classIdController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Please fill in all fields'),
                            backgroundColor: Colors.red[700],
                          ),
                        );
                        return;
                      }
                      try {
                        final subjectIds = (student['subjectIds'] as List<dynamic>?)
                            ?.map((id) => id.toString())
                            .toList() ??
                            [];

                        // Upload the new image if picked
                        String? newImageFileId;
                        if (pickedImage != null && imageBytes != null) {
                          newImageFileId = await _uploadImageToStorage();
                          if (newImageFileId == null) {
                            throw Exception('Failed to upload image');
                          }
                        }

                        print('Updating student with data:');
                        print('studentId: ${student['studentId']}');
                        print('studentName: ${_nameController.text}');
                        print('averageScore: ${student['averageScore']?.toDouble() ?? 0.0}');
                        print('studentImage: ${newImageFileId ?? student['studentImage'] ?? 'default'}');
                        print('secretCode: ${student['secretCode']?.toString() ?? ''}');
                        print('classId: ${_classIdController.text}');
                        print('subjectIds: $subjectIds');

                        await _appwriteService.updateStudent(
                          studentId: student['studentId'],
                          studentName: _nameController.text,
                          averageScore: student['averageScore']?.toDouble() ?? 0.0,
                          studentImage: newImageFileId ?? student['studentImage'] ?? 'default',
                          secretCode: student['secretCode']?.toString() ?? '',
                          classId: _classIdController.text,
                          subjectIds: subjectIds,
                        );
                        await _fetchStudents();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Student updated successfully'),
                            backgroundColor: Colors.green[700],
                          ),
                        );
                      } catch (e) {
                        print('Error updating student: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red[700],
                          ),
                        );
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
    });
  }

  void _editSubject(Map<String, dynamic> subject) {
    _nameController.text = subject['subjectName']?.toString() ?? '';
    showDialog(
      context: context,
      builder: (context) {
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
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
            ),
            TextButton(
              onPressed: () async {
                if (_nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please fill in all fields'),
                      backgroundColor: Colors.red[700],
                    ),
                  );
                  return;
                }
                try {
                  await _appwriteService.updateSubject(
                    subjectId: subject['subjectId'],
                    subjectName: _nameController.text,
                    description: _descriptionController.text,
                  );
                  await _fetchSubjects();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Subject updated successfully'),
                      backgroundColor: Colors.green[700],
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red[700],
                    ),
                  );
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

  void _deleteStudent(Map<String, dynamic> student) async {
    try {
      await _appwriteService.deleteStudent(student['studentId']);
      await _fetchStudents();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Student deleted successfully'),
          backgroundColor: Colors.green[700],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red[700]),
      );
    }
  }

  void _deleteSubject(Map<String, dynamic> subject) async {
    try {
      await _appwriteService.deleteSubject(subject['subjectId']);
      await _fetchSubjects();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Subject deleted successfully'),
          backgroundColor: Colors.green[700],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red[700]),
      );
    }
  }

  Future<void> _saveScore() async {
    if (_studentIdController.text.isEmpty ||
        _subjectIdController.text.isEmpty ||
        _scoreController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red[700],
        ),
      );
      return;
    }

    try {
      double score = double.parse(_scoreController.text);
      if (score < 0 || score > 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Score must be between 0 and 10'),
            backgroundColor: Colors.red[700],
          ),
        );
        return;
      }

      if (_isLoadingStudents || _students.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Student list is not loaded yet'),
            backgroundColor: Colors.red[700],
          ),
        );
        return;
      }

      final student = _students.firstWhere(
        (s) =>
            (s['studentId']?.toString() ?? '') ==
            _studentIdController.text.trim(),
        orElse: () => <String, dynamic>{},
      );

      if (student.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Student not found in your class'),
            backgroundColor: Colors.red[700],
          ),
        );
        return;
      }

      final subjectExists = await _appwriteService.checkSubjectExists(
        _subjectIdController.text.trim(),
      );
      if (!subjectExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Subject not found'),
            backgroundColor: Colors.red[700],
          ),
        );
        return;
      }

      final subjectIds =
          (student['subjectIds'] as List<dynamic>?)
              ?.map((id) => id.toString())
              .toList() ??
          [];
      if (!subjectIds.contains(_subjectIdController.text.trim())) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Student has not registered for this subject'),
            backgroundColor: Colors.red[700],
          ),
        );
        return;
      }

      await _appwriteService.saveScore(
        studentId: _studentIdController.text,
        subjectId: _subjectIdController.text,
        score: _scoreController.text,
      );

      final scores = await _appwriteService.getScoresByStudentId(
        _studentIdController.text,
      );
      double totalScore = 0.0;
      int scoreCount = scores.length;
      for (var s in scores) {
        totalScore += (s['score']?.toDouble() ?? 0.0);
      }
      double averageScore = scoreCount > 0 ? totalScore / scoreCount : 0.0;

      await _appwriteService.updateStudent(
        studentId: student['studentId'],
        studentName: student['studentName']?.toString() ?? '',
        averageScore: averageScore,
        studentImage: student['studentImage'] ?? 'default',
        secretCode: student['secretCode']?.toString() ?? '',
        classId: student['classId']?.toString(),
        subjectIds: subjectIds,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Score ${_scoreController.text} saved for Student ID ${_studentIdController.text} in Subject ID ${_subjectIdController.text}',
          ),
          backgroundColor: Colors.green[700],
        ),
      );

      _studentIdController.clear();
      _subjectIdController.clear();
      _scoreController.clear();
      await _fetchStudents();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save score: $e'),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Confirm Logout',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Đóng dialog
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Logged out successfully'),
                  backgroundColor: Colors.green[700],
                  duration: Duration(seconds: 1),
                ),
              );
              // Chuyển hướng về LoginScreen
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
                    (route) => false, // Xóa tất cả các route trước đó
              );
            },
            child: Text(
              'OK',
              style: GoogleFonts.poppins(color: Colors.red[700]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateTeacherImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      final Uint8List imageBytes = await pickedFile.readAsBytes();
      final String fileName = pickedFile.name;

      final fileId = await _appwriteService.uploadImage(imageBytes, fileName);
      if (fileId == null) {
        throw Exception('Failed to upload image');
      }

      if (_teacher != null && _teacher!['teacherImage'] != null && _teacher!['teacherImage'] != 'default') {
        final oldImageUrl = _teacher!['teacherImage'].startsWith('https://')
            ? _teacher!['teacherImage']
            : _generateImageUrl(_teacher!['teacherImage']);
        imageCache.evict(NetworkImage(oldImageUrl));
      }

      await _appwriteService.updateTeacher(
        teacherId: _teacher!['teacherId']?.toString() ?? '',
        teacherFaculty: _teacher!['teacherFaculty']?.toString() ?? '',
        teacherImage: fileId,
        secretCode: _teacher!['secretCode']?.toString() ?? '',
        classId: _teacher!['classId']?.toString() ?? '',
      );

      await _fetchTeacher();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile picture updated successfully'),
          backgroundColor: Colors.green[700],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile picture: $e'),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }
  List<Widget> _buildScreens() {
    return [
      // Tab 1: Profile
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Teacher Profile',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue[600],
              ),
            ),
            SizedBox(height: 16),
            _isLoadingTeacher
                ? Center(child: CircularProgressIndicator())
                : _teacher == null
                ? Center(
              child: Text(
                'Failed to load teacher data',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
            )
                : Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: _teacher == null ||
                                  _teacher!['teacherImage'] == null
                                  ? const AssetImage(
                                'assets/images/default_avatar.png',
                              )
                                  : _teacher!['teacherImage'] == 'default'
                                  ? const AssetImage(
                                'assets/images/default_avatar.png',
                              )
                                  : _teacher!['teacherImage']
                                  .startsWith('https://')
                                  ? NetworkImage(
                                  _teacher!['teacherImage'])
                                  : NetworkImage(
                                _generateImageUrl(
                                  _teacher!['teacherImage'],
                                ),
                              ),
                              onBackgroundImageError: (error, stackTrace) {
                                print('Error loading teacher image: $error');
                              },
                            ),
                            // Add camera icon to update the image
                            GestureDetector(
                              onTap: _updateTeacherImage, // Method to handle image update
                              child: CircleAvatar(
                                radius: 15,
                                backgroundColor: Colors.blue[600],
                                child: Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ID: ${_teacher?['teacherId']?.toString() ?? 'N/A'}',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Faculty: ${_teacher?['teacherFaculty']?.toString() ?? 'N/A'}',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Name: ${_teacher?['teacherName']?.toString() ?? 'N/A'}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Secret Code: ${_teacher?['secretCode']?.toString() ?? 'N/A'}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Class ID: ${_teacher?['classId']?.toString() ?? 'N/A'}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
          ],
        ),
      ),

      // Tab 2: List Students (unchanged)
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
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            SizedBox(height: 16),
            Expanded(
              child: _isLoadingStudents
                  ? Center(child: CircularProgressIndicator())
                  : _students.isEmpty
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
                itemCount: _filterStudents(_students, _searchQuery).length,
                itemBuilder: (context, index) {
                  final student = _filterStudents(_students, _searchQuery)[index];
                  String? imageUrl;
                  if (student['studentImage'] != null &&
                      student['studentImage'].isNotEmpty &&
                      student['studentImage'] != 'default' &&
                      !student['studentImage'].startsWith('https://')) {
                    imageUrl = _generateImageUrl(
                      student['studentImage'],
                    );
                  }

                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StudentDetailScreen(
                              studentId: student['studentId']?.toString() ?? '',
                            ),
                          ),
                        );
                      },
                      leading: CircleAvatar(
                        backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                            ? NetworkImage(imageUrl)
                            : student['studentImage'] != null &&
                            student['studentImage'].isNotEmpty &&
                            student['studentImage'].startsWith('https://')
                            ? NetworkImage(student['studentImage'])
                            : const AssetImage('assets/images/default_avatar.png'),
                        onBackgroundImageError: (error, stackTrace) {
                          print('Error loading student image from URL $imageUrl: $error');
                        },
                      ),
                      title: Text(
                        student['studentName']?.toString() ?? 'Unknown',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        'ID: ${student['studentId']?.toString() ?? 'N/A'} | Score: ${student['averageScore']?.toString() ?? '0.0'} | Class: ${student['classId']?.toString() ?? 'N/A'}',
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
                            _editStudent(student);
                          } else if (value == 'delete') {
                            _deleteStudent(student);
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

      // Tab 3: List Subjects (unchanged)
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
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            SizedBox(height: 16),
            Expanded(
              child: _isLoadingSubjects
                  ? Center(child: CircularProgressIndicator())
                  : _subjects.isEmpty
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
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SubjectDetailScreen(
                              subjectId: subject['subjectId']?.toString() ?? '',
                            ),
                          ),
                        );
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

      // Tab 4: Enter Score (unchanged)
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
    if (index == 4) {
      _logout();
    } else {
      setState(() {
        _selectedIndex = index;
        _searchController.clear();
        _searchQuery = '';
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _studentIdController.dispose();
    _subjectIdController.dispose();
    _scoreController.dispose();
    _idController.dispose();
    _nameController.dispose();
    _secretCodeController.dispose();
    _classIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blue[600],
        title: Text(
          'Teacher Dashboard',
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
      body: _buildScreens()[_selectedIndex],
      floatingActionButton:
          (_selectedIndex == 1 || _selectedIndex == 2)
              ? FloatingActionButton(
                onPressed: () {
                  _addItem(_selectedIndex == 1);
                },
                backgroundColor: Colors.blue[600],
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
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Students'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Subjects'),
          BottomNavigationBarItem(
            icon: Icon(Icons.score),
            label: 'Enter Score',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: 'Logout',
          ),
        ],
      ),
    );
  }
}
