import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/attendance.dart';

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

  // Fungsi untuk menyimpan data absensi
  Future<Map<String, dynamic>> saveAttendance(Attendance attendance) async {
    try {
      await _firestore.collection('absensi').doc(attendance.id).set(attendance.toMap());
      return {'success': true};
    } catch (e) {
      return {'error': 'Gagal menyimpan absensi: $e'};
    }
  }

  // Fungsi untuk mengambil riwayat absensi pengguna
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