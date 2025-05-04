import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/attendance.dart';
import '../models/permission.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<Map<String, dynamic>?> signIn(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      if (result.user != null) {
        final userData = await getUserData(result.user!.uid);
        return {'user': result.user, 'data': userData};
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return {'error': _mapAuthError(e.code)};
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['uid'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> addUser({
    required String email,
    required String password,
    required String nama,
    required String role,
    required String jabatan,
    String? id,
    String fotoUrl = '',
  }) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('createUser');
      final result = await callable.call({
        'email': email,
        'password': password,
        'nama': nama,
        'role': role,
        'jabatan': jabatan,
        'id': id,
        'fotoUrl': fotoUrl,
      });
      return result.data;
    } on FirebaseFunctionsException catch (e) {
      return {'error': e.message ?? 'Gagal membuat user'};
    } catch (e) {
      return {'error': 'Terjadi kesalahan: $e'};
    }
  }

  Future<Map<String, dynamic>> updateUser({
    required String uid,
    required String nama,
    required String role,
    required String jabatan,
    required String email,
    String? id,
    String fotoUrl = '',
  }) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'nama': nama,
        'role': role,
        'jabatan': jabatan,
        'email': email,
        'id': id ?? uid,
        'fotoUrl': fotoUrl,
      });
      return {'success': true};
    } catch (e) {
      return {'error': 'Gagal memperbarui pengguna: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
      return {'success': true};
    } catch (e) {
      return {'error': 'Gagal menghapus pengguna: $e'};
    }
  }

  Future<Map<String, dynamic>> saveAttendance(Attendance attendance) async {
    try {
      await _firestore.collection('absensi').doc(attendance.id).set(attendance.toMap());
      return {'success': true};
    } catch (e) {
      return {'error': 'Gagal menyimpan absensi: $e'};
    }
  }

  Future<List<Attendance>> getUserAttendance(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('absensi')
          .where('uid', isEqualTo: uid)
          .orderBy('timestamp', descending: true)
          .get();
      return snapshot.docs.map((doc) => Attendance.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      print('Error getting attendance: $e');
      return [];
    }
  }

  Future<List<Attendance>> getAllAttendance() async {
    try {
      final snapshot = await _firestore
          .collection('absensi')
          .orderBy('timestamp', descending: true)
          .get();
      return snapshot.docs.map((doc) => Attendance.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      print('Error getting all attendance: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> submitPermission(Permission permission) async {
    try {
      await _firestore.collection('izin').doc(permission.id).set(permission.toMap());
      return {'success': true};
    } catch (e) {
      return {'error': 'Gagal mengajukan izin: $e'};
    }
  }

  Future<List<Permission>> getUserPermissions(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('izin')
          .where('uid', isEqualTo: uid)
          .orderBy('submissionDate', descending: true)
          .get();
      return snapshot.docs.map((doc) => Permission.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      print('Error getting permissions: $e');
      return [];
    }
  }

  Future<List<Permission>> getAllPermissions() async {
    try {
      final snapshot = await _firestore
          .collection('izin')
          .where('status', isEqualTo: 'Pending')
          .orderBy('submissionDate', descending: true)
          .get();
      return snapshot.docs.map((doc) => Permission.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      print('Error getting all permissions: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> updatePermissionStatus({
    required String permissionId,
    required String status,
    required String reviewedBy,
    String? reviewNotes,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User tidak login');
      await _firestore.collection('izin').doc(permissionId).update({
        'status': status,
        'reviewedBy': reviewedBy,
        'reviewNotes': reviewNotes,
        'reviewDate': FieldValue.serverTimestamp(),
      });
      return {'success': true};
    } catch (e) {
      return {'error': 'Gagal memperbarui status izin: $e'};
    }
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Pengguna tidak ditemukan.';
      case 'wrong-password':
        return 'Kata sandi salah.';
      case 'invalid-email':
        return 'Email tidak valid.';
      case 'email-already-in-use':
        return 'Email sudah digunakan.';
      default:
        return 'Terjadi kesalahan: $code';
    }
  }
}