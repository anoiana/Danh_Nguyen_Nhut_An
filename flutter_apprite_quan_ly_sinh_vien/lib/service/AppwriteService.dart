import 'dart:io';
import 'dart:typed_data';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';

class AppwriteService {
  Client client = Client();
  late Databases databases;
  late Storage storage;

  final String databaseId = '67f374d30033afc2fac6';
  final String studentCollectionId = '6801f6bb00064ffbc248';
  final String teacherCollectionId = '6801f6b50004d37f8d33';
  final String subjectCollectionId = '680f6a5100259451d0a0';
  final String adminCollectionId = '6801f6a0000ca8f7f26e';
  final String scoreCollectionId = '680fa99e0015124ae5a2';
  final String bucketId = '681022e80022a492263e';

  AppwriteService() {
    client
        .setEndpoint('https://cloud.appwrite.io/v1')
        .setProject('67f0f6cf0003bc00ed68')
        .setSelfSigned(status: true);
    databases = Databases(client);
    storage = Storage(client);
  }

  Future<Map<String, dynamic>> getAdmin(String adminId) async {
    try {
      final response = await databases.getDocument(
        databaseId: databaseId,
        collectionId: adminCollectionId,
        documentId: adminId,
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to fetch admin data: $e');
    }
  }

  /// Cập nhật thông tin admin (tên và ảnh đại diện)
  Future<void> updateAdmin({
    required String adminId,
    required String adminName,
    required String adminImage,
  }) async {
    try {
      await databases.updateDocument(
        databaseId: databaseId,
        collectionId: adminCollectionId,
        documentId: adminId,
        data: {
          'adminName': adminName,
          'adminImage': adminImage,
        },
      );
    } catch (e) {
      throw Exception('Failed to update admin data: $e');
    }
  }

  Future<Map<String, dynamic>?> getLoggedInUser({
    required String role,
    required String account,
    required String secretCode,
  }) async {
    try {
      if (role == "Admin") {
        final response = await databases.listDocuments(
          databaseId: databaseId,
          collectionId: adminCollectionId,
          queries: [
            Query.equal('adminEmail', account),
            Query.equal('adminId', secretCode),
          ],
        );

        if (response.documents.isNotEmpty) {
          final doc = response.documents.first;
          return {
            'adminId': doc.data['adminId'],
            'adminEmail': doc.data['adminEmail'],
            'adminName': doc.data['adminName'] ?? 'Admin User',
            'avatar': doc.data['avatar'] ?? 'https://via.placeholder.com/150',
            'role': 'Admin',
          };
        }
        return null;
      } else if (role == "Teacher") {
        final response = await databases.listDocuments(
          databaseId: databaseId,
          collectionId: teacherCollectionId,
          queries: [
            Query.equal('teacherId', account),
            Query.equal('secretCode', secretCode),
          ],
        );

        if (response.documents.isNotEmpty) {
          final doc = response.documents.first;
          return {
            'teacherId': doc.data['teacherId'],
            'teacherFaculty': doc.data['teacherFaculty'],
            'teacherImage': doc.data['teacherImage'],
            'secretCode': doc.data['secretCode'],
            'classId': doc.data['classId'],
            'teacherEmail': doc.data['teacherEmail'],
            'role': 'Teacher',
            'documentId': doc.$id,
          };
        }
        return null;
      } else if (role == "Student") {
        final response = await databases.listDocuments(
          databaseId: databaseId,
          collectionId: studentCollectionId,
          queries: [
            Query.equal('studentId', account),
            Query.equal('secretCode', secretCode),
          ],
        );

        if (response.documents.isNotEmpty) {
          final doc = response.documents.first;
          return {
            'studentId': doc.data['studentId'],
            'studentName': doc.data['studentName'],
            'averageScore': doc.data['averageScore'],
            'studentImage': doc.data['studentImage'],
            'secretCode': doc.data['secretCode'],
            'classId': doc.data['classId'],
            'subjectIds': doc.data['subjectIds'] ?? [],
            'role': 'Student',
            'studentEmail': doc.data['studentEmail'],
            'documentId': doc.$id,
          };
        }
        return null;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getStudents() async {
    try {
      final response = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: studentCollectionId,
      );
      return response.documents.map((doc) => {
        'studentId': doc.data['studentId'],
        'studentName': doc.data['studentName'],
        'averageScore': doc.data['averageScore'],
        'studentImage': doc.data['studentImage'],
        'secretCode': doc.data['secretCode'],
        'classId': doc.data['classId'],
        'subjectIds': doc.data['subjectIds'] ?? [],
        'studentEmail': doc.data['studentEmail'],
        'documentId': doc.$id,
      }).toList();
    } catch (e) {
      throw Exception('Failed to load students: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getTeachers() async {
    try {
      final response = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: teacherCollectionId,
      );
      return response.documents.map((doc) => {
        'teacherId': doc.data['teacherId'],
        'teacherFaculty': doc.data['teacherFaculty'],
        'teacherImage': doc.data['teacherImage'],
        'secretCode': doc.data['secretCode'],
        'classId': doc.data['classId'],
        'documentId': doc.$id,
        'teacherEmail': doc.data['teacherEmail'],
        'teacherName': doc.data['teacherName'],
      }).toList();
    } catch (e) {
      throw Exception('Failed to load teachers: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getSubjects() async {
    try {
      final response = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: subjectCollectionId,
      );
      return response.documents.map((doc) => {
        'subjectId': doc.data['subjectId'],
        'subjectName': doc.data['subjectName'],
        'credits': doc.data['credits'] ?? 0,
        'description': doc.data['description'] ?? '',
        'fee': doc.data['fee'] ?? 0,
        'documentId': doc.$id,
      }).toList();
    } catch (e) {
      throw Exception('Failed to load subjects: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getSubjectsByIds(List<String> subjectIds) async {
    try {
      if (subjectIds.isEmpty) return [];
      final response = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: subjectCollectionId,
        queries: [Query.equal('subjectId', subjectIds)],
      );
      return response.documents.map((doc) => {
        'subjectId': doc.data['subjectId'],
        'subjectName': doc.data['subjectName'],
        'credits': doc.data['credits'] ?? 0,
        'description': doc.data['description'] ?? '',
        'fee': doc.data['fee'] ?? 0,
        'documentId': doc.$id,
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch subjects by IDs: $e');
    }
  }

  Future<bool> checkStudentExists(String studentId) async {
    try {
      final response = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: studentCollectionId,
        queries: [Query.equal('studentId', studentId)],
      );
      return response.documents.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check student existence: $e');
    }
  }

  Future<bool> checkTeacherExists(String teacherId) async {
    try {
      final response = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: teacherCollectionId,
        queries: [Query.equal('teacherId', teacherId)],
      );
      return response.documents.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check teacher existence: $e');
    }
  }

  Future<bool> checkSubjectExists(String subjectId) async {
    try {
      final response = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: subjectCollectionId,
        queries: [Query.equal('subjectId', subjectId)],
      );
      return response.documents.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check subject existence: $e');
    }
  }

  Future<void> addStudent({
    required String studentId,
    required String studentName,
    required double averageScore,
    required String studentImage,
    required String secretCode,
    required String classId,
    required String studentEmail,
    List<String>? subjectIds,
  }) async {
    try {
      await databases.createDocument(
        databaseId: databaseId,
        collectionId: studentCollectionId,
        documentId: ID.unique(),
        data: {
          'studentId': studentId,
          'studentName': studentName,
          'averageScore': averageScore,
          'studentImage': studentImage,
          'secretCode': secretCode,
          'classId': classId,
          'subjectIds': subjectIds ?? [],
          'studentEmail': studentEmail,
        },
      );
    } catch (e) {
      throw Exception('Failed to add student: $e');
    }
  }

  Future<void> addTeacher({
    required String teacherName,
    required String teacherId,
    required String teacherFaculty,
    required String teacherImage,
    required String secretCode,
    required String classId,
    required String teacherEmail,
  }) async {
    try {
      await databases.createDocument(
        databaseId: databaseId,
        collectionId: teacherCollectionId,
        documentId: ID.unique(),
        data: {
          'teacherId': teacherId,
          'teacherName' : teacherName,
          'teacherFaculty': teacherFaculty,
          'teacherImage': teacherImage,
          'secretCode': secretCode,
          'classId': classId,
          'teacherEmail': teacherEmail,
          'teacherName': teacherName,
        },
      );
    } catch (e) {
      throw Exception('Failed to add teacher: $e');
    }
  }

  Future<void> addSubject({
    required String subjectId,
    required String subjectName,
    int credits = 0,
    String description = '',
    int fee = 0,
  }) async {
    try {
      await databases.createDocument(
        databaseId: databaseId,
        collectionId: subjectCollectionId,
        documentId: ID.unique(),
        data: {
          'subjectId': subjectId,
          'subjectName': subjectName,
          'credits': credits,
          'description': description,
          'fee': fee,
        },
      );
    } catch (e) {
      throw Exception('Failed to add subject: $e');
    }
  }

  Future<void> updateStudent({
    required String studentId,
    String? studentName,
    double? averageScore,
    String? studentImage,
    String? secretCode,
    String? classId,
    List<String>? subjectIds,
  }) async {
    try {
      final response = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: studentCollectionId,
        queries: [Query.equal('studentId', studentId)],
      );

      if (response.documents.isEmpty) {
        throw Exception('Student not found');
      }

      final studentDoc = response.documents.first;
      final documentId = studentDoc.$id;
      final oldClassId = studentDoc.data['classId'] as String?;
      final data = <String, dynamic>{};

      if (studentName != null) data['studentName'] = studentName;
      if (averageScore != null) data['averageScore'] = averageScore;
      if (studentImage != null) data['studentImage'] = studentImage;
      if (secretCode != null) data['secretCode'] = secretCode;
      if (classId != null) data['classId'] = classId;
      if (subjectIds != null) data['subjectIds'] = subjectIds;

      await databases.updateDocument(
        databaseId: databaseId,
        collectionId: studentCollectionId,
        documentId: documentId,
        data: data,
      );

      if (classId != null && classId != oldClassId) {
        await updateTeacherStudentIds(classId);
        if (oldClassId != null) {
          await updateTeacherStudentIds(oldClassId);
        }
      }
    } catch (e) {
      throw Exception('Failed to update student: $e');
    }
  }

  Future<void> updateTeacher({
    required String teacherId,
    String? teacherFaculty,
    String? teacherImage,
    String? secretCode,
    String? classId,
  }) async {
    try {
      final response = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: teacherCollectionId,
        queries: [Query.equal('teacherId', teacherId)],
      );

      if (response.documents.isEmpty) {
        throw Exception('Teacher not found');
      }

      final teacherDoc = response.documents.first;
      final documentId = teacherDoc.$id;
      final oldClassId = teacherDoc.data['classId'] as String?;
      final data = <String, dynamic>{};

      if (teacherFaculty != null) data['teacherFaculty'] = teacherFaculty;
      if (teacherImage != null) data['teacherImage'] = teacherImage;
      if (secretCode != null) data['secretCode'] = secretCode;
      if (classId != null) data['classId'] = classId;

      await databases.updateDocument(
        databaseId: databaseId,
        collectionId: teacherCollectionId,
        documentId: documentId,
        data: data,
      );

      if (classId != null && classId != oldClassId) {
        await updateTeacherStudentIds(classId);
        if (oldClassId != null) {
          await updateTeacherStudentIds(oldClassId);
        }
      }
    } catch (e) {
      throw Exception('Failed to update teacher: $e');
    }
  }

  Future<bool> checkClassIdExists(String classId) async {
    try {
      final response = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: teacherCollectionId, // ID collection giáo viên
        queries: [
          Query.equal('classId', classId),
        ],
      );

      return response.documents.isNotEmpty;
    } catch (e) {
      print('Error checking class ID: $e');
      return false;
    }
  }

  Future<void> updateSubject({
    required String subjectId,
    required String subjectName,
    required String description,
  }) async {
    try {
      final response = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: subjectCollectionId,
        queries: [Query.equal('subjectId', subjectId)],
      );

      if (response.documents.isEmpty) {
        throw Exception('Subject not found');
      }

      final documentId = response.documents.first.$id;

      await databases.updateDocument(
        databaseId: databaseId,
        collectionId: subjectCollectionId,
        documentId: documentId,
        data: {
          'subjectName': subjectName,
          'description': description,
        },
      );
    } catch (e) {
      throw Exception('Failed to update subject: $e');
    }
  }

  Future<void> updateTeacherStudentIds(String classId) async {
    try {
      final students = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: studentCollectionId,
        queries: [
          Query.equal('classId', classId),
        ],
      );

      final studentIds = students.documents
          .map((student) => student.data['studentId'] as String)
          .toList();

      final teachers = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: teacherCollectionId,
        queries: [
          Query.equal('classId', classId),
        ],
      );

      for (var teacher in teachers.documents) {
        await databases.updateDocument(
          databaseId: databaseId,
          collectionId: teacherCollectionId,
          documentId: teacher.$id,
          data: {
            'studentIds': studentIds,
          },
        );
      }
    } catch (e) {
      throw Exception('Failed to update teacher studentIds: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getStudentsByClassId(String classId) async {
    try {
      final response = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: studentCollectionId,
        queries: [
          Query.equal('classId', classId),
        ],
      );

      return response.documents.map((doc) => {
        'documentId': doc.$id,
        'studentId': doc.data['studentId']?.toString() ?? 'Unknown',
        'studentName': doc.data['studentName']?.toString() ?? 'N/A',
        'averageScore': doc.data['averageScore']?.toDouble() ?? 0.0,
        'studentImage':
        doc.data['studentImage']?.toString() ?? 'https://via.placeholder.com/150',
        'secretCode': doc.data['secretCode']?.toString() ?? '',
        'classId': doc.data['classId']?.toString() ?? 'N/A',
        'subjectIds': doc.data['subjectIds'] ?? [],
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch students by classId: $e');
    }
  }

  Future<void> deleteStudent(String studentId) async {
    try {
      final response = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: studentCollectionId,
        queries: [Query.equal('studentId', studentId)],
      );

      if (response.documents.isEmpty) {
        throw Exception('Student not found');
      }

      final documentId = response.documents.first.$id;

      await databases.deleteDocument(
        databaseId: databaseId,
        collectionId: studentCollectionId,
        documentId: documentId,
      );
    } catch (e) {
      throw Exception('Failed to delete student: $e');
    }
  }

  Future<void> deleteTeacher(String teacherId) async {
    try {
      final response = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: teacherCollectionId,
        queries: [Query.equal('teacherId', teacherId)],
      );

      if (response.documents.isEmpty) {
        throw Exception('Teacher not found');
      }

      final documentId = response.documents.first.$id;

      await databases.deleteDocument(
        databaseId: databaseId,
        collectionId: teacherCollectionId,
        documentId: documentId,
      );
    } catch (e) {
      throw Exception('Failed to delete teacher: $e');
    }
  }

  Future<void> deleteSubject(String subjectId) async {
    try {
      final response = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: subjectCollectionId,
        queries: [Query.equal('subjectId', subjectId)],
      );

      if (response.documents.isEmpty) {
        throw Exception('Subject not found');
      }

      final documentId = response.documents.first.$id;

      await databases.deleteDocument(
        databaseId: databaseId,
        collectionId: subjectCollectionId,
        documentId: documentId,
      );
    } catch (e) {
      throw Exception('Failed to delete subject: $e');
    }
  }

  // Kiểm tra xem studentId có tồn tại trong collection students không
  Future<bool> doesStudentExist(String studentId) async {
    try {
      final response = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: studentCollectionId,
        queries: [
          Query.equal('studentId', studentId),
        ],
      );
      return response.documents.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check student existence: $e');
    }
  }

  Future<Document?> getExistingScore(String studentId, String subjectId) async {
    try {
      final response = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: scoreCollectionId,
        queries: [
          Query.equal('studentId', studentId),
          Query.equal('subjectId', subjectId),
        ],
      );
      return response.documents.isNotEmpty ? response.documents[0] : null;
    } catch (e) {
      throw Exception('Failed to check existing score: $e');
    }
  }

  // Kiểm tra xem subjectId có tồn tại trong collection subjects không
  Future<bool> doesSubjectExist(String subjectId) async {
    try {
      final response = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: subjectCollectionId,
        queries: [
          Query.equal('subjectId', subjectId),
        ],
      );
      return response.documents.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check subject existence: $e');
    }
  }

  // Lấy tất cả điểm của một học sinh và tính điểm trung bình
  Future<double> calculateAverageScore(String studentId) async {
    try {
      // Lấy tất cả điểm của học sinh từ collection scores
      final scoresResponse = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: scoreCollectionId,
        queries: [
          Query.equal('studentId', studentId),
        ],
      );

      final scores = scoresResponse.documents;
      if (scores.isEmpty) {
        return 0.0; // Nếu không có điểm, trả về 0
      }

      // Tính tổng điểm
      final totalScore = scores.fold<double>(
        0.0,
            (sum, doc) => sum + (doc.data['score'] as num).toDouble(),
      );

      // Tính điểm trung bình
      final scoreCount = scores.length;
      final averageScore = totalScore / scoreCount;

      return averageScore;
    } catch (e) {
      throw Exception('Failed to calculate average score: $e');
    }
  }

  // Cập nhật averageScore vào collection students
  Future<void> updateStudentAverageScore(String studentId, double averageScore, String scoreId) async {
    try {
      final studentResponse = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: studentCollectionId,
        queries: [
          Query.equal('studentId', studentId),
        ],
      );

      if (studentResponse.documents.isEmpty) {
        throw Exception('Student with ID $studentId not found');
      }

      final studentDoc = studentResponse.documents[0];
      // Lấy scoreIds hiện tại, nếu không có thì khởi tạo mảng rỗng
      List<String> scoreIds = List<String>.from(studentDoc.data['scoreIds'] ?? []);

      // Nếu scoreId chưa có trong scoreIds, thêm vào
      if (!scoreIds.contains(scoreId)) {
        scoreIds.add(scoreId);
      }

      await databases.updateDocument(
        databaseId: databaseId,
        collectionId: studentCollectionId,
        documentId: studentDoc.$id,
        data: {
          'averageScore': averageScore,
          'scoreIds': scoreIds,
        },
      );
    } catch (e) {
      throw Exception('Failed to update student data: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getStudentScores(String studentId) async {
    try {
      // Lấy thông tin học sinh để lấy scoreIds
      final studentResponse = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: studentCollectionId,
        queries: [
          Query.equal('studentId', studentId),
        ],
      );

      if (studentResponse.documents.isEmpty) {
        throw Exception('Student with ID $studentId not found');
      }

      final studentDoc = studentResponse.documents[0];
      final scoreIds = List<String>.from(studentDoc.data['scoreIds'] ?? []);

      if (scoreIds.isEmpty) {
        return []; // Nếu không có điểm, trả về mảng rỗng
      }

      // Lấy thông tin điểm từ collection scores dựa trên scoreId
      final scoresResponse = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: scoreCollectionId,
        queries: [
          Query.contains('scoreId', scoreIds), // Tìm các document có scoreId nằm trong scoreIds
        ],
      );

      return scoresResponse.documents.map((doc) => doc.data).toList();
    } catch (e) {
      throw Exception('Failed to fetch student scores: $e');
    }
  }

  // Hàm lưu điểm với kiểm tra studentId, subjectId, tính điểm trung bình và cập nhật
  Future<void> saveScore({
    required String studentId,
    required String subjectId,
    required String score,
  }) async {
    try {
      // Kiểm tra studentId có tồn tại không
      final studentExists = await doesStudentExist(studentId);
      if (!studentExists) {
        throw Exception('Student with ID $studentId does not exist');
      }

      // Kiểm tra subjectId có tồn tại không
      final subjectExists = await doesSubjectExist(subjectId);
      if (!subjectExists) {
        throw Exception('Subject with ID $subjectId does not exist');
      }

      // Lấy thông tin sinh viên để kiểm tra subjectIds
      final studentResponse = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: studentCollectionId,
        queries: [
          Query.equal('studentId', studentId),
        ],
      );

      if (studentResponse.documents.isEmpty) {
        throw Exception('Student with ID $studentId not found');
      }

      final studentDoc = studentResponse.documents[0];
      final subjectIds = List<String>.from(studentDoc.data['subjectIds'] ?? []);

      // Kiểm tra xem sinh viên đã đăng ký môn học này chưa
      if (!subjectIds.contains(subjectId)) {
        throw Exception('Sinh viên chưa đăng ký môn này');
      }

      // Kiểm tra xem đã có bản ghi điểm cho studentId và subjectId chưa
      final existingScore = await getExistingScore(studentId, subjectId);
      final parsedScore = double.parse(score);
      String scoreId;

      if (existingScore != null) {
        // Nếu đã có bản ghi, cập nhật điểm cũ, giữ nguyên scoreId
        scoreId = existingScore.data['scoreId'];
        await databases.updateDocument(
          databaseId: databaseId,
          collectionId: scoreCollectionId,
          documentId: existingScore.$id,
          data: {
            'studentId': studentId,
            'subjectId': subjectId,
            'score': parsedScore,
            'scoreId': scoreId,
          },
        );
      } else {
        // Nếu chưa có, tạo scoreId mới và tạo bản ghi mới
        scoreId = ID.unique();
        await databases.createDocument(
          databaseId: databaseId,
          collectionId: scoreCollectionId,
          documentId: ID.unique(),
          data: {
            'studentId': studentId,
            'subjectId': subjectId,
            'score': parsedScore,
            'scoreId': scoreId,
          },
        );
      }

      // Tính điểm trung bình
      final averageScore = await calculateAverageScore(studentId);

      // Cập nhật averageScore và scoreIds vào collection students
      await updateStudentAverageScore(studentId, averageScore, scoreId);
    } catch (e) {
      throw Exception('Failed to save score: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getScoresByStudentId(String studentId) async {
    try {
      final response = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: scoreCollectionId,
        queries: [Query.equal('studentId', studentId)],
      );
      return response.documents.map((doc) => {
        'studentId': doc.data['studentId']?.toString() ?? 'Unknown',
        'subjectId': doc.data['subjectId']?.toString() ?? 'N/A',
        'score': doc.data['score']?.toDouble() ?? 0.0,
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch scores: $e');
    }
  }

  Future<Map<String, dynamic>> getTeacherById(String teacherId) async {
    try {
      final response = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: teacherCollectionId,
        queries: [
          Query.equal('teacherId', teacherId),
        ],
      );
      if (response.documents.isNotEmpty) {
        final doc = response.documents.first;
        return {
          'documentId': doc.$id,
          'teacherId': doc.data['teacherId']?.toString() ?? 'Unknown',
          'teacherName': doc.data['teacherName']?.toString() ?? 'Unknown', // Thêm teacherName
          'teacherEmail': doc.data['teacherEmail']?.toString() ?? 'Unknown', // Thêm teacherEmail
          'teacherFaculty': doc.data['teacherFaculty']?.toString() ?? 'N/A',
          'teacherImage':
          doc.data['teacherImage']?.toString() ?? 'https://via.placeholder.com/150',
          'secretCode': doc.data['secretCode']?.toString() ?? '',
          'classId': doc.data['classId']?.toString() ?? 'N/A',
        };
      } else {
        throw Exception('Teacher not found');
      }
    } catch (e) {
      throw Exception('Failed to fetch teacher: $e');
    }
  }

  Future<Map<String, dynamic>> getStudentById(String studentId) async {
    try {
      final response = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: studentCollectionId,
        queries: [
          Query.equal('studentId', studentId),
        ],
      );
      if (response.documents.isNotEmpty) {
        final doc = response.documents.first;
        return {
          'documentId': doc.$id,
          'studentId': doc.data['studentId']?.toString() ?? 'Unknown',
          'studentEmail': doc.data['studentEmail']?.toString() ?? 'Unknown',
          'studentName': doc.data['studentName']?.toString() ?? 'N/A',
          'averageScore': doc.data['averageScore']?.toDouble() ?? 0.0,
          'studentImage':
          doc.data['studentImage']?.toString() ?? 'https://via.placeholder.com/150',
          'secretCode': doc.data['secretCode']?.toString() ?? '',
          'classId': doc.data['classId']?.toString() ?? 'N/A',
          'subjectIds': doc.data['subjectIds'] ?? [],
        };
      } else {
        throw Exception('Student not found');
      }
    } catch (e) {
      throw Exception('Failed to fetch student: $e');
    }
  }



  Future<void> registerSubject({
    required String studentId,
    required String subjectId,
  }) async {
    try {
      final studentDoc = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: studentCollectionId,
        queries: [
          Query.equal('studentId', studentId),
        ],
      );

      if (studentDoc.documents.isEmpty) {
        throw Exception('Student not found');
      }

      final student = studentDoc.documents.first;
      final subjectIds = List<String>.from(student.data['subjectIds'] ?? []);

      if (subjectIds.contains(subjectId)) {
        throw Exception('Subject already registered');
      }

      subjectIds.add(subjectId);

      await databases.updateDocument(
        databaseId: databaseId,
        collectionId: studentCollectionId,
        documentId: student.$id,
        data: {
          'subjectIds': subjectIds,
        },
      );
    } catch (e) {
      throw Exception('Failed to register subject: $e');
    }
  }


  Future<Map<String, dynamic>> getSubjectById(String subjectId) async {
    try {
      print('Fetching subject with subjectId: $subjectId');
      final response = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: subjectCollectionId,
        queries: [Query.equal('subjectId', subjectId)],
      );
      if (response.documents.isEmpty) {
        throw Exception('Subject not found');
      }
      return response.documents[0].data;
    } catch (e) {
      throw Exception('Failed to fetch subject: $e');
    }
  }

  Future<String> getImageUrl(String fileId) async {
    try {
      final url = await storage.getFilePreview(
        bucketId: bucketId,
        fileId: fileId,
      );
      return url.toString();
    } catch (e) {
      throw Exception('Failed to get image URL: $e');
    }
  }

  Future<String> uploadImage(Uint8List imageBytes, String fileName) async {
    try {
      final storage = Storage(client);
      final file = await storage.createFile(
        bucketId: bucketId,
        fileId: ID.unique(),
        file: InputFile.fromBytes(
          bytes: imageBytes,
          filename: fileName,
        ),
      );
      return file.$id; // Trả về fileId
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

// Phương thức mới để lấy dữ liệu ảnh (bytes) từ fileId
  Future<Uint8List> getImageBytes(String fileId) async {
    try {
      final data = await storage.getFileView(
        bucketId: bucketId,
        fileId: fileId,
      );
      return data; // Trả về dữ liệu bytes của ảnh
    } catch (e) {
      throw Exception('Failed to get image bytes: $e');
    }
  }

}