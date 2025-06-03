import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../service/AppwriteService.dart';

class StudentDetailScreen extends StatefulWidget {
  final String studentId;

  const StudentDetailScreen({required this.studentId});

  @override
  _StudentDetailScreenState createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  final AppwriteService _appwriteService = AppwriteService();
  Map<String, dynamic>? _student;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStudentDetails();
  }

  Future<void> _fetchStudentDetails() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final studentData = await _appwriteService.getStudentById(widget.studentId);
      setState(() {
        _student = studentData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load student details: $e'),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }
  String _generateImageUrl(String fileId) {
    return '${_appwriteService.client.endPoint}/storage/buckets/681022e80022a492263e/files/$fileId/view?project=67f0f6cf0003bc00ed68';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[600],
        title: Text(
          'Student Details',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
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
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _student == null || _student!['studentImage'] == null
                          ? const AssetImage('assets/images/default_avatar.png')
                          : _student!['studentImage'] == 'default'
                          ? const AssetImage('assets/images/default_avatar.png')
                          : _student!['studentImage'].startsWith('https://')
                          ? NetworkImage(_student!['studentImage'])
                          : NetworkImage(_generateImageUrl(_student!['studentImage'])),
                      onBackgroundImageError: (error, stackTrace) {
                        print('Error loading student image: $error');
                      },
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Student ID: ${_student!['studentId']?.toString() ?? 'N/A'}',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[600],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Name: ${_student!['studentName']?.toString() ?? 'N/A'}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Email: ${_student!['studentEmail']?.toString() ?? 'N/A'}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Average Score: ${_student!['averageScore']?.toString() ?? '0.0'}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Secret Code: ${_student!['secretCode']?.toString() ?? 'N/A'}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Class ID: ${_student!['classId']?.toString() ?? 'N/A'}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Subjects: ${( _student!['subjectIds'] as List<dynamic>?)?.map((id) => id.toString()).join(', ') ?? 'None'}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}