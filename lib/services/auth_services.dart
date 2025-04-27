import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream untuk memantau status autentikasi
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Fungsi untuk login
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

  // Fungsi untuk logout
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Fungsi untuk mengambil data pengguna dari Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Fungsi untuk mengambil daftar semua pengguna (hanya untuk kepala cabang)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }

  // Fungsi untuk menambah pengguna baru (hanya untuk kepala cabang)
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
      // Buat pengguna baru di Firebase Authentication
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Simpan data pengguna ke Firestore
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'nama': nama,
          'role': role,
          'jabatan': jabatan,
          'email': email,
          'id': id ?? credential.user!.uid, // Gunakan UID sebagai ID jika tidak ada ID khusus
          'fotoUrl': fotoUrl,
        });

        return {'success': true};
      }
      return {'error': 'Gagal membuat pengguna'};
    } on FirebaseAuthException catch (e) {
      return {'error': _mapAuthError(e.code)};
    } catch (e) {
      return {'error': 'Terjadi kesalahan: $e'};
    }
  }

  // Fungsi untuk memetakan kode error Firebase ke pesan yang ramah pengguna
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