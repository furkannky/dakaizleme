import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dakaizleme/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Kullanıcı oturum durumunu dinleme
  Stream<User?> get userChanges => _auth.authStateChanges();

  // Kullanıcı bilgileriyle birlikte stream sağlar
  Stream<AppUser?> get userStream {
    return _auth.authStateChanges().asyncMap((user) {
      if (user == null) return null;
      return getUserFromFirestore(user.uid);
    });
  }

  // E-posta ve şifre ile giriş yapma
  Future<AppUser> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      // Kullanıcı bilgilerini Firestore'dan çek
      final userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
      
      if (!userDoc.exists) {
        throw Exception('Kullanıcı bulunamadı');
      }
      
      return AppUser.fromMap(userDoc.data()!, userCredential.user!.uid);
    } catch (e) {
      rethrow;
    }
  }

  // E-posta ve şifre ile yeni hesap oluşturma
  Future<AppUser> signUpWithEmail(String email, String password) async {
    try {
      // Kullanıcıyı oluştur
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      // Varsayılan olarak 'user' rolü ile kullanıcı oluştur
      final user = AppUser(
        uid: userCredential.user!.uid,
        email: email,
        role: 'user', // Varsayılan rol
        createdAt: DateTime.now(),
      );
      
      // Kullanıcı bilgilerini Firestore'a kaydet
      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(user.toMap());
      
      return user;
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

  // Kullanıcıyı Firestore'dan getir
  Future<AppUser?> getUserFromFirestore(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (!userDoc.exists) return null;
      return AppUser.fromMap(userDoc.data()!, uid);
    } catch (e) {
      return null;
    }
  }

  // Kullanıcı rolünü güncelle (sadece admin tarafından yapılabilir)
  Future<void> updateUserRole(String userId, String newRole) async {
    if (newRole != 'admin' && newRole != 'user') {
      throw Exception('Geçersiz rol');
    }
    
    await _firestore.collection('users').doc(userId).update({'role': newRole});
  }
}