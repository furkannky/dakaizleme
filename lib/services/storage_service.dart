// lib/services/storage_service.dart
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart'; // uuid paketi için pubspec.yaml'a eklemeyi unutmayın

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  // Proje resmini Firebase Storage'a yükler
  Future<String?> uploadProjectImage(File imageFile) async {
    try {
      String fileName = 'project_images/${_uuid.v4()}-${imageFile.path.split('/').last}';
      Reference ref = _storage.ref().child(fileName);
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Resim yükleme hatası: $e');
      return null;
    }
  }

  // Resim URL'si ile Firebase Storage'dan resmi siler (isteğe bağlı)
  Future<void> deleteImage(String imageUrl) async {
    try {
      Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      print('Resim başarıyla silindi: $imageUrl');
    } catch (e) {
      print('Resim silme hatası: $e');
    }
  }
}