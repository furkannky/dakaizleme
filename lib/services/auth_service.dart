import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Kullanıcı oturum durumunu dinleme
  Stream<User?> get userChanges => _auth.authStateChanges();

  // E-posta ve şifre ile giriş yapma
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      // Hata yönetimi için exception fırlatılabilir
      rethrow;
    }
  }

  // E-posta ve şifre ile yeni hesap oluşturma
  Future<UserCredential> signUpWithEmail(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  // Oturumu kapatma
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Mevcut kullanıcıyı alma
  User? getCurrentUser() {
    return _auth.currentUser;
  }
}