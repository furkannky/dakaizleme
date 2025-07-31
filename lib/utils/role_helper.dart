class RoleHelper {
  // Rol sabitleri
  static const String admin = 'admin';
  static const String user = 'user';

  // Kullanıcının belirli bir role sahip olup olmadığını kontrol et
  static bool hasRole(String? userRole, String requiredRole) {
    if (userRole == null) return false;
    return userRole == requiredRole;
  }

  // Kullanıcı admin mi kontrol et
  static bool isAdmin(String? userRole) {
    return hasRole(userRole, admin);
  }

  // Kullanıcı normal kullanıcı mı kontrol et
  static bool isRegularUser(String? userRole) {
    return hasRole(userRole, user);
  }

  // Kullanıcının düzenleme yetkisi var mı kontrol et
  static bool canEdit(String? userRole) {
    return isAdmin(userRole); // Sadece adminler düzenleyebilir
  }

  // Kullanıcının silme yetkisi var mı kontrol et
  static bool canDelete(String? userRole) {
    return isAdmin(userRole); // Sadece adminler silebilir
  }

  // Kullanıcının yeni öğe ekleme yetkisi var mı kontrol et
  static bool canAdd(String? userRole) {
    return isAdmin(userRole); // Sadece adminler ekleyebilir
  }

  // Kullanıcının listeleme yapma yetkisi var mı kontrol et
  static bool canView(String? userRole) {
    return true; // Tüm kullanıcılar listeleyebilir
  }
}
