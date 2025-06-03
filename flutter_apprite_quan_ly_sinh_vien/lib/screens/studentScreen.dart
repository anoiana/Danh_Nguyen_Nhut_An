import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../service/AppwriteService.dart';
import './subjectDetail.dart';
import 'loginScreen.dart';

class StudentScreen extends StatefulWidget {
  final String studentId;

  const StudentScreen({
    required this.studentId,
  });

  @override
  _StudentScreenState createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  int _selectedIndex = 0;
  final AppwriteService _appwriteService = AppwriteService();

  Map<String, dynamic>? _student;
  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _registeredSubjects = [];
  List<Map<String, dynamic>> _scores = [];
  bool _isLoadingStudent = false;
  bool _isLoadingSubjects = false;
  bool _isLoadingRegisteredSubjects = false;
  bool _isLoadingScores = false;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final ImagePicker _picker = ImagePicker();
  Uint8List? _studentImageBytes;

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
    await _fetchStudent();
    await _fetchSubjects();
    await _fetchRegisteredSubjects();
    await _fetchScores();
  }

  Future<void> _fetchStudent() async {
    setState(() {
      _isLoadingStudent = true;
    });
    try {
      final studentData = await _appwriteService.getStudentById(widget.studentId);
      setState(() {
        _student = studentData;
        _isLoadingStudent = false;
      });

      if (_student != null && _student!['studentImage'] != null && _student!['studentImage'] != 'default') {
        try {
          final imageBytes = await _appwriteService.getImageBytes(_student!['studentImage']);
          setState(() {
            _studentImageBytes = imageBytes;
          });
        } catch (e) {
          print('Failed to load student image bytes: $e');
          setState(() {
            _studentImageBytes = null;
          });
        }
      } else {
        setState(() {
          _studentImageBytes = null;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingStudent = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load student data: $e'),
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
        _subjects = subjects;
        _isLoadingSubjects = false;
      });
    } catch (e) {
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

  Future<void> _fetchRegisteredSubjects() async {
    setState(() {
      _isLoadingRegisteredSubjects = true;
    });
    try {
      final subjectIds = _student?['subjectIds'] as List<dynamic>? ?? [];
      final registeredSubjects = await _appwriteService.getSubjectsByIds(subjectIds.cast<String>());
      setState(() {
        _registeredSubjects = registeredSubjects;
        _isLoadingRegisteredSubjects = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingRegisteredSubjects = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load registered subjects: $e'),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  Future<void> _fetchScores() async {
    setState(() {
      _isLoadingScores = true;
    });
    try {
      final scores = await _appwriteService.getStudentScores(widget.studentId);
      setState(() {
        _scores = scores;
        _isLoadingScores = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingScores = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load scores: $e'),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  List<Map<String, dynamic>> _filterSubjects(
      List<Map<String, dynamic>> subjects, String query) {
    if (query.isEmpty) return subjects;
    return subjects.where((subject) {
      final name = subject['subjectName']?.toString().toLowerCase() ?? '';
      final id = subject['subjectId']?.toString().toLowerCase() ?? '';
      return name.contains(query.toLowerCase()) || id.contains(query.toLowerCase());
    }).toList();
  }

  void _registerSubject(Map<String, dynamic> subject) async {
    try {
      await _appwriteService.registerSubject(
        studentId: widget.studentId,
        subjectId: subject['subjectId']?.toString() ?? '',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully registered for ${subject['subjectName']?.toString() ?? 'Unknown'}'),
          backgroundColor: Colors.green[700],
        ),
      );
      await _fetchStudent();
      await _fetchRegisteredSubjects();
      await _fetchScores();
    } catch (e) {
      String errorMessage = 'Failed to register: $e';
      if (e.toString().contains('Subject already registered')) {
        errorMessage = 'You have already registered for this subject';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      final Uint8List imageBytes = await pickedFile.readAsBytes();
      final String fileName = pickedFile.name;

      final fileId = await _appwriteService.uploadImage(imageBytes, fileName);

      await _appwriteService.updateStudent(
        studentId: widget.studentId,
        studentName: _student!['studentName']?.toString() ?? '',
        averageScore: _student!['averageScore']?.toDouble() ?? 0.0,
        studentImage: fileId,
        secretCode: _student!['secretCode']?.toString() ?? '',
        classId: _student!['classId']?.toString() ?? '',
        subjectIds: (_student!['subjectIds'] as List<dynamic>?)?.cast<String>() ?? [],
      );

      await _fetchStudent();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile picture updated successfully'),
          backgroundColor: Colors.green[700],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload image: $e'),
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

  void _onItemTapped(int index) {
    if (index == 2) {
      _logout();
    } else {
      setState(() {
        _selectedIndex = index;
        _searchController.clear();
        _searchQuery = '';
      });
    }
  }

  List<Widget> _buildScreens() {
    return [
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Student Profile',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[600],
                ),
              ),
              SizedBox(height: 16),
              _isLoadingStudent
                  ? Center(child: CircularProgressIndicator())
                  : _student == null
                  ? Center(
                child: Text(
                  'Failed to load student data',
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
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundColor: Colors.grey[200],
                                backgroundImage: _student!['studentImage'] == null ||
                                    _student!['studentImage'] == 'default'
                                    ? const AssetImage('assets/images/default_avatar.png')
                                    : _studentImageBytes != null
                                    ? MemoryImage(_studentImageBytes!)
                                    : const AssetImage('assets/images/default_avatar.png')
                                as ImageProvider,
                                onBackgroundImageError: (error, stackTrace) {
                                  print('Error loading student image: $error');
                                },
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _pickAndUploadImage,
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
                              ),
                            ],
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _student!['studentName'] ?? 'N/A',
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[600],
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'ID: ${_student!['studentId'] ?? 'N/A'}',
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
                        'Average Score: ${_student!['averageScore']?.toStringAsFixed(1) ?? 'N/A'}',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Secret Code: ${_student!['secretCode'] ?? 'N/A'}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Class ID: ${_student!['classId'] ?? 'N/A'}',
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
              Text(
                'Registered Subjects',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[600],
                ),
              ),
              SizedBox(height: 16),
              _isLoadingRegisteredSubjects
                  ? Center(child: CircularProgressIndicator())
                  : _registeredSubjects.isEmpty
                  ? Center(
                child: Text(
                  'No registered subjects yet',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              )
                  : ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _registeredSubjects.length,
                itemBuilder: (context, index) {
                  final subject = _registeredSubjects[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue[100],
                        child: Text(
                          subject['subjectName']?.toString()[0] ?? 'S',
                          style: TextStyle(color: Colors.blue[600]),
                        ),
                      ),
                      title: Text(
                        subject['subjectName']?.toString() ?? 'Unknown',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        'ID: ${subject['subjectId']?.toString() ?? 'N/A'}',
                        style: GoogleFonts.poppins(color: Colors.grey[600]),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 24),
              Text(
                'My Scores',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[600],
                ),
              ),
              SizedBox(height: 16),
              _isLoadingScores
                  ? Center(child: CircularProgressIndicator())
                  : _scores.isEmpty
                  ? Center(
                child: Text(
                  'No scores available',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              )
                  : ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _scores.length,
                itemBuilder: (context, index) {
                  final score = _scores[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue[100],
                        child: Text(
                          score['subjectId']?.toString()[0] ?? 'S',
                          style: TextStyle(color: Colors.blue[600]),
                        ),
                      ),
                      title: Text(
                        'Subject ID: ${score['subjectId']?.toString() ?? 'Unknown'}',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        'Score: ${score['score']?.toString() ?? 'N/A'}',
                        style: GoogleFonts.poppins(color: Colors.grey[600]),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
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
                  final isRegistered = (_student?['subjectIds'] as List<dynamic>? ?? [])
                      .contains(subject['subjectId']?.toString());
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
                              onRegister: () => _registerSubject(subject),
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
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        'ID: ${subject['subjectId']?.toString() ?? 'N/A'} | Credits: ${subject['credits']?.toString() ?? 'N/A'} | Fee: ${subject['fee']?.toString() ?? 'N/A'}',
                        style: GoogleFonts.poppins(color: Colors.grey[600]),
                      ),
                      trailing: isRegistered
                          ? ElevatedButton(
                        onPressed: null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[400],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Registered',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      )
                          : ElevatedButton(
                        onPressed: () {
                          _registerSubject(subject);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Register',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blue[600],
        title: Text(
          'Student Dashboard',
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue[600],
        unselectedItemColor: Colors.grey[600],
        backgroundColor: Colors.white,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Subjects',
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