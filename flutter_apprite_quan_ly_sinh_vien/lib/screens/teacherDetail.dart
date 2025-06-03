import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../service/AppwriteService.dart';

class TeacherDetailScreen extends StatefulWidget {
  final String teacherId;

  const TeacherDetailScreen({required this.teacherId});

  @override
  _TeacherDetailScreenState createState() => _TeacherDetailScreenState();
}

class _TeacherDetailScreenState extends State<TeacherDetailScreen> {
  final AppwriteService _appwriteService = AppwriteService();
  Map<String, dynamic>? _teacher;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTeacherDetails();
  }

  Future<void> _fetchTeacherDetails() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final teacherData = await _appwriteService.getTeacherById(
        widget.teacherId,
      );
      setState(() {
        _teacher = teacherData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load teacher details: $e'),
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
          'Teacher Details',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
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
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: _teacher == null || _teacher!['teacherImage'] == null
                          ? const AssetImage('assets/images/default_avatar.png')
                          : _teacher!['teacherImage'] == 'default'
                          ? const AssetImage('assets/images/default_avatar.png')
                          : _teacher!['teacherImage'].startsWith('https://')
                          ? NetworkImage(_teacher!['teacherImage'])
                          : NetworkImage(_generateImageUrl(_teacher!['teacherImage'])),
                      onBackgroundImageError: (error, stackTrace) {
                        print('Error loading teacher image: $error');
                      },
                      backgroundColor: Colors.grey[200],
                    ),
                  ),
                  SizedBox(height: 16),
                  Center(
                    child: Text(
                      _teacher!['teacherName']?.toString() ?? 'N/A', // Thêm teacherName
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[600],
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Teacher ID: ${_teacher!['teacherId']?.toString() ?? 'N/A'}',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Faculty: ${_teacher!['teacherFaculty']?.toString() ?? 'N/A'}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Email: ${_teacher!['teacherEmail']?.toString() ?? 'N/A'}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Secret Code: ${_teacher!['secretCode']?.toString() ?? 'N/A'}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Class ID: ${_teacher!['classId']?.toString() ?? 'N/A'}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
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