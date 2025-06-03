import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Giả lập dữ liệu
class User {
  final String id;
  String name;
  String email;

  User({required this.id, required this.name, required this.email});
}

class Certificate {
  final String id;
  String name;
  String issueDate;

  Certificate({required this.id, required this.name, required this.issueDate});
}

// Dữ liệu giả lập
final List<User> _teachers = [
  User(id: "T1", name: "Teacher A", email: "teacherA@example.com"),
  User(id: "T2", name: "Teacher B", email: "teacherB@example.com"),
  User(id: "T3", name: "Teacher C", email: "teacherC@example.com"),
];

final List<User> _students = [
  User(id: "S1", name: "Student X", email: "studentX@example.com"),
  User(id: "S2", name: "Student Y", email: "studentY@example.com"),
  User(id: "S3", name: "Student Z", email: "studentZ@example.com"),
];

final List<Certificate> _certificates = [
  Certificate(id: "C1", name: "Certificate A", issueDate: "2023-01-15"),
  Certificate(id: "C2", name: "Certificate B", issueDate: "2023-06-20"),
  Certificate(id: "C3", name: "Certificate C", issueDate: "2024-03-10"),
];

// Liên kết giả lập: Student X có Certificate A, B
final Map<String, List<Certificate>> _studentCertificates = {
  "S1": [_certificates[0], _certificates[1]],
  "S2": [_certificates[2]],
  "S3": [],
};


// Màn hình chi tiết Certificate
class CertificateDetailScreen extends StatefulWidget {
  final Certificate certificate;

  CertificateDetailScreen({required this.certificate});

  @override
  _CertificateDetailScreenState createState() =>
      _CertificateDetailScreenState();
}

class _CertificateDetailScreenState extends State<CertificateDetailScreen> {
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _issueDateController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.certificate.name);
    _issueDateController =
        TextEditingController(text: widget.certificate.issueDate);
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _saveChanges() {
    if (_nameController.text.isEmpty || _issueDateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red[700],
        ),
      );
      return;
    }
    setState(() {
      widget.certificate.name = _nameController.text;
      widget.certificate.issueDate = _issueDateController.text;
      _isEditing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Certificate updated successfully'),
        backgroundColor: Colors.green[700],
      ),
    );
  }

  void _deleteCertificate() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Delete', style: GoogleFonts.poppins()),
        content: Text(
            'Are you sure you want to delete ${widget.certificate.name}?',
            style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () {
              _certificates.remove(widget.certificate);
              _studentCertificates.forEach((key, value) {
                value.remove(widget.certificate);
              });
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Certificate deleted successfully'),
                  backgroundColor: Colors.green[700],
                ),
              );
            },
            child: Text('Delete',
                style: GoogleFonts.poppins(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Giả lập: Certificate liên kết với Student X
    final linkedStudent =
    _students.firstWhere((s) => s.id == "S1", orElse: () => _students[0]);
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blue[600],
        title: Text(
          'Certificate Details',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: !_isEditing
            ? [
          IconButton(
            icon: Icon(Icons.edit, color: Colors.white),
            onPressed: _toggleEdit,
          ),
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: _deleteCertificate,
          ),
        ]
            : [],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Certificate Information',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[600],
                ),
              ),
              SizedBox(height: 16),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _isEditing
                      ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Name',
                          labelStyle: GoogleFonts.poppins(
                              color: Colors.blue[600]),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        style: GoogleFonts.poppins(),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: _issueDateController,
                        decoration: InputDecoration(
                          labelText: 'Issue Date (YYYY-MM-DD)',
                          labelStyle: GoogleFonts.poppins(
                              color: Colors.blue[600]),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        style: GoogleFonts.poppins(),
                        keyboardType: TextInputType.datetime,
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _toggleEdit,
                            child: Text('Cancel',
                                style: GoogleFonts.poppins(
                                    color: Colors.grey[600])),
                          ),
                          TextButton(
                            onPressed: _saveChanges,
                            child: Text('Save',
                                style: GoogleFonts.poppins(
                                    color: Colors.blue[600])),
                          ),
                        ],
                      ),
                    ],
                  )
                      : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ID: ${widget.certificate.id}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue[600],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Name: ${widget.certificate.name}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Issue Date: ${widget.certificate.issueDate}',
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
                'Linked Student',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[600],
                ),
              ),
              SizedBox(height: 16),
              Card(
                margin: EdgeInsets.symmetric(vertical: 8),
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue[100],
                    child: Text(
                      linkedStudent.name[0],
                      style: TextStyle(color: Colors.blue[600]),
                    ),
                  ),
                  title: Text(
                    linkedStudent.name,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    linkedStudent.email,
                    style: GoogleFonts.poppins(color: Colors.grey[600]),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.visibility, color: Colors.blue[600]),
                    onPressed: () {
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //     builder: (context) =>
                      //         StudentDetailScreen(student: linkedStudent),
                      //   ),
                      // );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _issueDateController.dispose();
    super.dispose();
  }
}