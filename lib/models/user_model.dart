class AppUser {
  final String uid;
  final String email;
  final String role; // 'admin' veya 'user' değerlerini alacak
  final DateTime? createdAt;
  final DateTime? lastLogin;

  AppUser({
    required this.uid,
    required this.email,
    this.role = 'user', // Varsayılan olarak 'user' rolü atanıyor
    this.createdAt,
    this.lastLogin,
  });

  // Firestore'dan veri okurken kullanılacak factory constructor
  factory AppUser.fromMap(Map<String, dynamic> data, String id) {
    return AppUser(
      uid: id,
      email: data['email'] ?? '',
      role: data['role'] ?? 'user',
      createdAt: data['createdAt']?.toDate(),
      lastLogin: data['lastLogin']?.toDate(),
    );
  }

  // Firestore'a yazarken kullanılacak metot
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role,
      'createdAt': createdAt,
      'lastLogin': lastLogin,
    };
  }
}
