import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart'; // LatLng için

// --- SİZİN MANUEL KONUMLAR MAP'İNİZ ---
final Map<String, LatLng> staticKonumlar = {
  "MUŞ-Merkez": LatLng(38.7369, 41.4883),
  "VAN-Tuşba": LatLng(38.5147, 43.3444),
  "VAN-Erciş": LatLng(39.0253, 43.3592),
  "MUŞ-Malazgirt": LatLng(39.0833, 42.5417),
  "BİTLİS-Merkez": LatLng(38.4063, 42.1264),
  "BİTLİS-Adilcevaz": LatLng(38.9833, 42.9242),
  "HAKKARİ-Yüksekova": LatLng(37.5684, 44.2562),
  "VAN-İpekyolu": LatLng(38.4988, 43.3719),
  "VAN-Özalp": LatLng(38.6750, 43.9167),
  "BİTLİS-Tatvan": LatLng(38.5083, 42.2750),
  "BİTLİS-Güroymak": LatLng(38.5667, 42.2667),
  "HAKKARİ-Merkez": LatLng(37.5759, 43.7381),
  "BİTLİS-Ahlat": LatLng(38.7472, 42.4764),
  "MUŞ-Bulanık": LatLng(39.0433, 42.4283),
  "VAN-Edremit": LatLng(38.4414, 43.3087),
  "HAKKARİ-Şemdinli": LatLng(37.3833, 44.5833),
  "VAN-Gürpınar": LatLng(38.2583, 43.2750),
  "VAN-Gevaş": LatLng(38.1694, 43.0806),
  "MUŞ-Hasköy": LatLng(38.7450, 41.6967),
  "MUŞ-Varto": LatLng(39.1833, 41.6500),
  "VAN-Çaldıran": LatLng(39.3139, 43.7917),
  "VAN-Çatak": LatLng(38.0583, 43.0833),
  "VAN-Başkale": LatLng(38.0167, 44.0000),
  "BİTLİS-Hizan": LatLng(38.1417, 42.3417),
  "HAKKARİ-Çukurca": LatLng(37.1667, 43.5833),
  "VAN-Bahçesaray": LatLng(38.0667, 42.7667),
  "VAN-Saray": LatLng(38.6944, 44.1500),
  "VAN-Muradiye": LatLng(38.8500, 43.5000),
  "MUŞ-Korkut": LatLng(38.9000, 41.8333),
  "HAKKARİ-Derecik": LatLng(37.2833, 44.5167),
  "BİTLİS-Mutki": LatLng(38.4472, 41.8708)
};

// --- TEMİZLEME FONKSİYONU ---
// Bu fonksiyon, Firestore'dan gelen metni, statik map'inizdeki
// anahtarlara tam olarak uyacak formata dönüştürür.
String _cleanAndStandardizeLocation(String rawLocation) {
  String cleaned = rawLocation.toUpperCase(); // Tümünü büyük harfe çevir
  cleaned = cleaned.trim(); // Baştaki ve sondaki boşlukları kaldır
  cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' '); // Birden fazla boşluğu tek boşluğa indir
  cleaned = cleaned.replaceAll(' - ', '-'); // "İL - İLÇE" -> "İL-İLÇE"
  cleaned = cleaned.replaceAll(' / ', '-'); // "İL / İLÇE" -> "İL-İLÇE"
  cleaned = cleaned.replaceAll(' ', '-'); // "MUŞ MERKEZ" -> "MUŞ-MERKEZ"
  cleaned = cleaned.replaceAll(RegExp(r'[.,;]'), ''); // Noktalama işaretlerini kaldır

  return cleaned;
}

Future<void> updateAllDocumentLocations() async {
  print('Konum güncelleme işlemi başlatılıyor...');
  final firestore = FirebaseFirestore.instance;
  final collection = firestore.collection('ajansDestekleri');

  final snapshot = await collection.get();

  if (snapshot.docs.isEmpty) {
    print('ajansDestekleri koleksiyonunda güncellenecek belge bulunamadı.');
    return;
  }

  int updatedCount = 0;
  int skippedCount = 0;
  List<String> notFoundInMap = [];

  for (var doc in snapshot.docs) {
    final data = doc.data();
    final docId = doc.id;

    // Alanları doğru anahtarla bulmak için yardımcı fonksiyon
    String? findFieldIgnoringSpaces(Map<String, dynamic> docData, String targetKey) {
      for (final key in docData.keys) {
        // Anahtarın başında ve sonunda boşluklar olabileceğini düşünerek trim() kullanıyoruz
        // Ayrıca, anahtarın tam eşleşme için temizlenmiş halini kontrol ediyoruz.
        if (key.trim() == targetKey.trim()) {
          return docData[key]?.toString().trim();
        }
      }
      return null;
    }

    final rawIl = findFieldIgnoringSpaces(data, 'Projenin Uygulama İli') ?? '';
    final rawIlceYeri = findFieldIgnoringSpaces(data, 'Projenin Uygulama Yeri') ?? '';

    // --- DEBUG AMAÇLI EKLENDİ ---
    print('--- Belge ID: $docId ---');
    print('Projenin Uygulama İli (okunan): "$rawIl"');
    print('Projenin Uygulama Yeri (okunan): "$rawIlceYeri"');
    // --- DEBUG AMAÇLI EKLENDİ ---

    // Veritabanındaki verilerin boş olup olmadığını kontrol et
    if (rawIl.isEmpty || rawIlceYeri.isEmpty) {
      print('Belge $docId için il ("$rawIl") veya ilçe ("$rawIlceYeri") eksik/boş, atlanıyor.');
      skippedCount++;
      continue;
    }

    // Belge zaten güncellenmiş mi? (latitude alanı varsa ve 0.0 değilse)
    if (data.containsKey('latitude') && data['latitude'] != null && data['latitude'] != 0.0) {
      print('Belge $docId için konum zaten mevcut, atlanıyor.');
      skippedCount++;
      continue;
    }

    // --- Statik Map'imizde ara ---
    // 'Projenin Uygulama Yeri' birden fazla ilçe içerebilir (virgülle ayrılmış), her birini dene
    final rawIlceList = rawIlceYeri.split(',').map((e) => e.trim()).toList();
    bool foundInStaticMap = false;

    for (var ilceItem in rawIlceList) {
      // Hem il hem de ilçe bilgisini kullanarak Map anahtarını oluştur
      // Örn: "HAKKARİ-MERKEZ"
      final fullLocationKey = _cleanAndStandardizeLocation('$rawIl-$ilceItem');
      final LatLng? coords = staticKonumlar[fullLocationKey];

      if (coords != null) {
        await doc.reference.update({
          'latitude': coords.latitude,
          'longitude': coords.longitude,
        });
        print('✅ Belge $docId statik haritadan güncellendi: "$rawIlceYeri" -> "$fullLocationKey"');
        updatedCount++;
        foundInStaticMap = true;
        break; // Bulunduysa diğer ilçeleri denemeye gerek yok
      }
    }

    if (!foundInStaticMap) {
      // Statik Map'te bulunamadıysa logla
      final cleanedRawIlceYeriForLog = _cleanAndStandardizeLocation('$rawIl-$rawIlceYeri');
      if (!notFoundInMap.contains(cleanedRawIlceYeriForLog)) {
        notFoundInMap.add(cleanedRawIlceYeriForLog);
      }
      print('⚠️ Belge $docId için "$rawIlceYeri" (Temizlenmiş: "$cleanedRawIlceYeriForLog") statik haritada bulunamadı.');
      skippedCount++;
    }
  }

  print('-----------------------------------------');
  print('Toplam güncellenen belge sayısı: $updatedCount');
  print('Toplam atlanan (geçersiz/zaten mevcut/bulunamayan) belge sayısı: $skippedCount');

  if (notFoundInMap.isNotEmpty) {
    print('\n--- Statik Haritada Bulunamayan Benzersiz Konumlar (Manuel Eklenmesi Tavsiye Edilir) ---');
    notFoundInMap.toSet().forEach((loc) => print(' - $loc')); // Benzersizleri yazdır
  }

  print('\n🎯 Konum güncelleme işlemi tamamlandı.');
}