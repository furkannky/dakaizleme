import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AjansDestek {
  final String id;
  final String destekProgrami;
  final String destekTuru;
  final String desteklenenAlan;
  final int yil;
  final String yararlaniciAdi;
  final String referansNo;
  final String projeAdi;
  final String projeDurumu;
  final String naceFaaliyetKisimi;
  final double teknikDestekMaliyeti;
  final double sozlesmeButcesi;
  final double sozlesmeDestekTutari;
  final DateTime? sozlesmeImzalamaTarihi;
  final DateTime? projeBaslamaTarihi;
  final DateTime? projeBitisTarihi;
  final String il;
  final String ilce;
  final double? latitude;
  final double? longitude;
  final String? imageUrl;
  final String? projeAciklamasi;

  AjansDestek({
    required this.id,
    required this.destekProgrami,
    required this.destekTuru,
    required this.desteklenenAlan,
    required this.yil,
    required this.yararlaniciAdi,
    required this.referansNo,
    required this.projeAdi,
    required this.projeDurumu,
    required this.naceFaaliyetKisimi,
    required this.teknikDestekMaliyeti,
    required this.sozlesmeButcesi,
    required this.sozlesmeDestekTutari,
    this.sozlesmeImzalamaTarihi,
    this.projeBaslamaTarihi,
    this.projeBitisTarihi,
    required this.il,
    required this.ilce,
    this.latitude,
    this.longitude,
    this.imageUrl,
    this.projeAciklamasi,
  });

  factory AjansDestek.fromFirestore(Map<String, dynamic> firestore, String id) {
    // Tarih ayrıştırma yardımcı fonksiyonu
    DateTime? _parseFirebaseDate(dynamic dateData) {
      if (dateData == null) return null;
      
      if (dateData is Timestamp) {
        return dateData.toDate();
      }
      // Eğer String ise, ISO formatında ayrıştırmaya çalış
      else if (dateData is String && dateData.isNotEmpty) {
        try {
          return DateTime.parse(dateData);
        } catch (e) {
          print('Uyarı: Tarih metni ayrıştırılamadı "$dateData". Hata: $e');
          return null;
        }
      }
      return null;
    }

    return AjansDestek(
      id: id,
      destekProgrami: firestore['destekProgrami'] ?? '',
      destekTuru: firestore['destekTuru'] ?? '',
      desteklenenAlan: firestore['desteklenenAlan'] ?? '',
      yil: (firestore['yil'] as num?)?.toInt() ?? 0,
      yararlaniciAdi: firestore['yararlaniciAdi'] ?? '',
      referansNo: firestore['referansNo'] ?? '',
      projeAdi: firestore['projeAdi'] ?? '',
      projeDurumu: firestore['projeDurumu'] ?? '',
      naceFaaliyetKisimi: firestore['naceFaaliyetKisimi'] ?? '',
      teknikDestekMaliyeti: (firestore['teknikDestekMaliyeti'] as num?)?.toDouble() ?? 0.0,
      sozlesmeButcesi: (firestore['sozlesmeButcesi'] as num?)?.toDouble() ?? 0.0,
      sozlesmeDestekTutari: (firestore['sozlesmeDestekTutari'] as num?)?.toDouble() ?? 0.0,
      sozlesmeImzalamaTarihi: _parseFirebaseDate(firestore['sozlesmeImzalamaTarihi']),
      projeBaslamaTarihi: _parseFirebaseDate(firestore['projeBaslamaTarihi']),
      projeBitisTarihi: _parseFirebaseDate(firestore['projeBitisTarihi']),
      il: firestore['il'] ?? '',
      ilce: firestore['ilce'] ?? '',
      latitude: (firestore['latitude'] as num?)?.toDouble(),
      longitude: (firestore['longitude'] as num?)?.toDouble(),
      imageUrl: firestore['imageUrl'] as String?,
      projeAciklamasi: firestore['projeAciklamasi'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'destekProgrami': destekProgrami,
      'destekTuru': destekTuru,
      'desteklenenAlan': desteklenenAlan,
      'yil': yil,
      'yararlaniciAdi': yararlaniciAdi,
      'referansNo': referansNo,
      'projeAdi': projeAdi,
      'projeDurumu': projeDurumu,
      'naceFaaliyetKisimi': naceFaaliyetKisimi,
      'teknikDestekMaliyeti': teknikDestekMaliyeti,
      'sozlesmeButcesi': sozlesmeButcesi,
      'sozlesmeDestekTutari': sozlesmeDestekTutari,
      'sozlesmeImzalamaTarihi': sozlesmeImzalamaTarihi?.toIso8601String(),
      'projeBaslamaTarihi': projeBaslamaTarihi?.toIso8601String(),
      'projeBitisTarihi': projeBitisTarihi?.toIso8601String(),
      'il': il,
      'ilce': ilce,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
      'projeAciklamasi': projeAciklamasi,
    };
  }
}
