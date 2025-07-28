// lib/models/ajans_destek.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AjansDestek {
  String id;
  String basariDurumu;
  String destekTuru; // Daha önce 'destekProgrami' olarak düşünmüştük ama mevcut kodda 'destekTuru' kullanılmış.
  String karAmaci;
  String kurumSiniflandirmasi;
  String kurumTuru;
  String mdpAdi;
  int mdpYili;
  String projeAdi;
  DateTime projeBaslamaTarihi;
  DateTime projeBitisTarihi;
  String projeDurumu;
  String naceFaaliyetBolumu;
  String naceFaaliyetGrubu;
  String naceFaaliyetKisimi;
  String naceFaaliyetSinifi;
  String il;
  String ilce;
  double toplamOdeme;
  String referansNo;
  double sozlesmeDestekTutari;
  double sozlesmeButcesi;
  DateTime sozlesmeImzalamaTarihi;
  double teknikDestekMaliyeti;
  String yararlaniciAdi;
  double? latitude; // Haritadan belirlenecek enlem
  double? longitude; // Haritadan belirlenecek boylam
  String? imageUrl; // Opsiyonel resim URL'si

  AjansDestek({
    this.id = '',
    required this.basariDurumu,
    required this.destekTuru,
    required this.karAmaci,
    required this.kurumSiniflandirmasi,
    required this.kurumTuru,
    required this.mdpAdi,
    required this.mdpYili,
    required this.projeAdi,
    required this.projeBaslamaTarihi,
    required this.projeBitisTarihi,
    required this.projeDurumu,
    required this.naceFaaliyetBolumu,
    required this.naceFaaliyetGrubu,
    required this.naceFaaliyetKisimi,
    required this.naceFaaliyetSinifi,
    required this.il,
    required this.ilce,
    required this.toplamOdeme,
    required this.referansNo,
    required this.sozlesmeDestekTutari,
    required this.sozlesmeButcesi,
    required this.sozlesmeImzalamaTarihi,
    required this.teknikDestekMaliyeti,
    required this.yararlaniciAdi,
    this.latitude,
    this.longitude,
    this.imageUrl,
  });

  // Firestore'dan veri okumak için factory constructor
  factory AjansDestek.fromFirestore(Map<String, dynamic> firestore, String id) {
    return AjansDestek(
      id: id,
      basariDurumu: firestore['Başarı Durumu'] ?? '',
      destekTuru: firestore['Destek Türü'] ?? '',
      karAmaci: firestore['Kar Amacı'] ?? '',
      kurumSiniflandirmasi: firestore['Kurum Sınıflandırması'] ?? '',
      kurumTuru: firestore['Kurum Türü'] ?? '',
      mdpAdi: firestore['MDP Adı'] ?? '',
      mdpYili: (firestore['MDP Yılı'] as num?)?.toInt() ?? 0,
      projeAdi: firestore['Proje Adı'] ?? '',
      projeBaslamaTarihi: (firestore['Proje Başlama Tarihi'] as Timestamp).toDate(),
      projeBitisTarihi: (firestore['Proje Bitiş Tarihi'] as Timestamp).toDate(),
      projeDurumu: firestore['Proje Durumu'] ?? '',
      naceFaaliyetBolumu: firestore['NACE Faaliyet Bölümü (2.Seviye)'] ?? '',
      naceFaaliyetGrubu: firestore['NACE Faaliyet Grubu (3.Seviye)'] ?? '',
      naceFaaliyetKisimi: firestore['NACE Faaliyet Kısımı (1.Seviye)'] ?? '',
      naceFaaliyetSinifi: firestore['NACE Faaliyet Sınıfı (4.Seviye)'] ?? '',
      il: firestore['Projenin Uygulama Yeri']?['İl'] ?? '', // Nested field
      ilce: firestore['Projenin Uygulama Yeri']?['İlçe'] ?? '', // Nested field
      toplamOdeme: (firestore['Projenin Toplam Ödemesi (TL)'] as num?)?.toDouble() ?? 0.0,
      referansNo: firestore['Referans No'] ?? '',
      sozlesmeDestekTutari: (firestore['Sözleşme Destek Tutarı (TL)'] as num?)?.toDouble() ?? 0.0,
      sozlesmeButcesi: (firestore['Sözleşme Eş Finansman Dahil Bütçesi (TL)'] as num?)?.toDouble() ?? 0.0,
      sozlesmeImzalamaTarihi: (firestore['Sözleşme İmzalama Tarihi'] as Timestamp).toDate(),
      teknikDestekMaliyeti: (firestore['Teknik Destek Maliyeti (TL)'] as num?)?.toDouble() ?? 0.0,
      yararlaniciAdi: firestore['Yararlanıcı Adı'] ?? '',
      latitude: (firestore['latitude'] as num?)?.toDouble(), // Nullable double
      longitude: (firestore['longitude'] as num?)?.toDouble(), // Nullable double
      imageUrl: firestore['imageUrl'] ?? '',
    );
  }

  // Firestore'a veri yazmak için metoda dönüştürme
  Map<String, dynamic> toFirestore() {
    return {
      'Başarı Durumu': basariDurumu,
      'Destek Türü': destekTuru,
      'Kar Amacı': karAmaci,
      'Kurum Sınıflandırması': kurumSiniflandirmasi,
      'Kurum Türü': kurumTuru,
      'MDP Adı': mdpAdi,
      'MDP Yılı': mdpYili,
      'Proje Adı': projeAdi,
      'Proje Başlama Tarihi': Timestamp.fromDate(projeBaslamaTarihi),
      'Proje Bitiş Tarihi': Timestamp.fromDate(projeBitisTarihi),
      'Proje Durumu': projeDurumu,
      'NACE Faaliyet Bölümü (2.Seviye)': naceFaaliyetBolumu,
      'NACE Faaliyet Grubu (3.Seviye)': naceFaaliyetGrubu,
      'NACE Faaliyet Kısımı (1.Seviye)': naceFaaliyetKisimi,
      'NACE Faaliyet Sınıfı (4.Seviye)': naceFaaliyetSinifi,
      'Projenin Uygulama Yeri': {
        'İl': il,
        'İlçe': ilce,
      },
      'Projenin Toplam Ödemesi (TL)': toplamOdeme,
      'Referans No': referansNo,
      'Sözleşme Destek Tutarı (TL)': sozlesmeDestekTutari,
      'Sözleşme Eş Finansman Dahil Bütçesi (TL)': sozlesmeButcesi,
      'Sözleşme İmzalama Tarihi': Timestamp.fromDate(sozlesmeImzalamaTarihi),
      'Teknik Destek Maliyeti (TL)': teknikDestekMaliyeti,
      'Yararlanıcı Adı': yararlaniciAdi,
      'latitude': latitude, // Nullable olarak gönder
      'longitude': longitude, // Nullable olarak gönder
      'imageUrl': imageUrl,
    };
  }
}