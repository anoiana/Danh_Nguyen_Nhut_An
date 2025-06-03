import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../service/AppwriteService.dart';

class SubjectDetailScreen extends StatefulWidget {
  final String subjectId;
  final VoidCallback? onRegister;

  const SubjectDetailScreen({
    required this.subjectId,
    this.onRegister,
  });

  @override
  _SubjectDetailScreenState createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends State<SubjectDetailScreen> {
  final AppwriteService _appwriteService = AppwriteService();
  Map<String, dynamic>? _subject;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSubjectDetails();
  }

  Future<void> _fetchSubjectDetails() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final subjectData = await _appwriteService.getSubjectById(widget.subjectId);
      setState(() {
        _subject = subjectData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load subject details: $e'),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[600],
        title: Text(
          'Subject Details',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _subject == null
          ? Center(
        child: Text(
          'Failed to load subject data',
          style: GoogleFonts.poppins(
            fontSize: 18,
            color: Colors.grey[600],
          ),
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blue[100],
                child: Text(
                  _subject!['subjectName']?.toString()[0] ?? 'S',
                  style: TextStyle(
                    color: Colors.blue[600],
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Subject Name: ${_subject!['subjectName']?.toString() ?? 'N/A'}',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Subject ID: ${_subject!['subjectId']?.toString() ?? 'N/A'}',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Credits: ${_subject!['credits']?.toString() ?? 'N/A'}',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Fee: ${_subject!['fee']?.toString() ?? 'N/A'}',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Description: ${_subject!['description']?.toString() ?? 'No description available'}',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 24),
            // Center(
            //   child: ElevatedButton(
            //     onPressed: widget.onRegister,
            //     style: ElevatedButton.styleFrom(
            //       backgroundColor: Colors.blue[600],
            //       padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
            //       shape: RoundedRectangleBorder(
            //         borderRadius: BorderRadius.circular(12),
            //       ),
            //     ),
            //     child: Text(
            //       'Register',
            //       style: GoogleFonts.poppins(
            //         color: Colors.white,
            //         fontSize: 16,
            //         fontWeight: FontWeight.bold,
            //       ),
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}