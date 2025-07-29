import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dakaizleme/views/ajans_destek_add_edit_screen.dart';
import 'package:dakaizleme/views/ajans_destek_detail_screen.dart';
import 'package:dakaizleme/models/ajans_destek.dart';
import 'package:dakaizleme/services/ajans_destek_service.dart';
import 'package:dakaizleme/views/project_list_screen.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;

class HomeScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String?
  initialProjectName; // Bu parametre artık doğrudan kullanılmayacak ama kalsın
  final String?
  initialProjectId; // <-- YENİ PARAMETRE: Sadece belirli projeyi göstermek için

  const HomeScreen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialProjectName,
    this.initialProjectId, // <-- BURAYA EKLENDİ
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GoogleMapController? mapController;
  final Set<Marker> _markers = {}; // Haritada gösterilecek markerlar
  Set<Polygon> _provincePolygons = {}; // Haritada gösterilecek il poligonları
  // İl adlarına göre poligonları saklamak için yeni bir harita
  Map<String, Polygon> _provincePolygonsMap = {};

  // Varsayılan başlangıç konumunuz ve zoom
  LatLng _center = const LatLng(38.80, 40.00); // Türkiye'nin ortalama merkezi
  double _zoom = 6.0; // Türkiye'yi gösteren başlangıç zoom seviyesi
  MapType _currentMapType = MapType.normal;

  final AjansDestekService _ajansDestekService = AjansDestekService();
  final TextEditingController _searchController = TextEditingController();
  List<AjansDestek> _allAjansDestekleri =
      []; // Tüm projeler (Firebase'den gelen)
  List<AjansDestek> _filteredAjansDestekleri =
      []; // Arama sonuçları için filtreli liste

  // Yeni eklenen değişkenler
  String? _selectedSupportType; // Seçili destek türü
  String? _lastSearchedCity; // Son aranan ilin adı

  // Destek türleri ve renkleri
  final List<String> _supportTypes = [
    'Tümü',
    'Cazibe Merkezleri Destekleme Programı',
    'Çalışan ve Üreten Gençler Programı',
    'Doğrudan Faaliyet Desteği',
    'Finansman Desteği',
    'Fizibilite Desteği',
    'Güdümlü Proje Desteği',
    'Proje Teklif Çağrısı',
    'Sosyal Gelişmeyi Destekleme Programı',
    'Teknik Destek',
  ];

  // Destek türleri ve renkleri - çeşitli yazım varyasyonlarını destekleyecek şekilde güncellendi
  final Map<String, Color> _markerColors = {
    // Cazibe Merkezleri varyasyonları
    'cazibe merkezleri destekleme programı': Colors.purple,
    'cazibe merkezi destekleme programı': Colors.purple,
    'cazibe merkezleri': Colors.purple,
    'cazibe merkezi': Colors.purple,
    'cazibe': Colors.purple,
    
    // Çalışan ve Üreten Gençler Programı varyasyonları
    'çalışan ve üreten gençler programı': Colors.blue,
    'çalışan gençler programı': Colors.blue,
    'üreten gençler': Colors.blue,
    'gençler programı': Colors.blue,
    
    // Diğer destek türleri
    'doğrudan faaliyet desteği': Colors.green,
    'faaliyet desteği': Colors.green,
    'doğrudan destek': Colors.green,
    
    'finansman desteği': Colors.orange,
    'finansal destek': Colors.orange,
    
    'fizibilite desteği': Colors.teal,
    'fizibilite': Colors.teal,
    
    'proje teklif çağrısı': Colors.red,
    'proje çağrısı': Colors.red,
    'teklif çağrısı': Colors.red,
    'proje teklif': Colors.red,
    
    'güdümlü proje desteği': Colors.pinkAccent,
    'güdümlü proje': Colors.pinkAccent,
    'güdümlü destek': Colors.pinkAccent,
    
    'sosyal gelişmeyi destekleme programı': Colors.indigo,
    'sosyal gelişme programı': Colors.indigo,
    'sosyal destek programı': Colors.indigo,
    'sosyal gelişme': Colors.indigo,
    
    'teknik destek': Colors.amber,
    'teknik': Colors.amber,
    
    // Varsayılan
    'diğer': Colors.grey,
  };

  bool _isLegendExpanded = false;

  @override
  void initState() {
    super.initState();
    // Projeleri dinlemeye başla
    _ajansDestekService.getAjansDestekleri().listen((data) {
      setState(() {
        _allAjansDestekleri = data;
        _filteredAjansDestekleri =
            data; // Başlangıçta tüm projeler filtrelenmiş listeye aktarılır

        // Eğer bir projeden haritaya gelindiyse (initialLatitude varsa)
        if (widget.initialLatitude != null && widget.initialLongitude != null) {
          _zoom = 14.0; // Projeye özel daha yakın zoom seviyesi
          _center = LatLng(
            widget.initialLatitude!,
            widget.initialLongitude!,
          ); // Merkezi ayarla

          // Eğer belirli bir proje ID'si ile geldiysek, sadece onu göster
          if (widget.initialProjectId != null) {
            final selectedProject = IterableExtension(
              _allAjansDestekleri,
            ).firstWhereOrNull((p) => p.id == widget.initialProjectId);
            if (selectedProject != null) {
              _loadSingleMarkerForProject(
                selectedProject,
              ); // <-- YENİ METOD ÇAĞRISI
            }
          } else {
            // Eğer proje ID'si yoksa ama koordinat varsa (eski davranış), ili yükle
            final selectedProject = IterableExtension(
              _allAjansDestekleri,
            ).firstWhereOrNull(
              (p) =>
                  p.latitude == widget.initialLatitude &&
                  p.longitude == widget.initialLongitude,
            );
            if (selectedProject != null) {
              _loadMarkersForCity(
                selectedProject.il,
              ); // Bu ilin markerlarını yükle
            }
          }
        }
        // Başlangıçta markerları yüklemiyoruz, sadece poligonlar görünecek.
        // Markerlar il poligonuna tıklandığında yüklenecek veya arama ile.
      });
    });
    _loadProvincePolygons(); // Bölge poligonlarını yükle
  }

  @override
  void dispose() {
    mapController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Sadece belirli bir projeyi haritada marker olarak gösterir.
  /// Diğer tüm markerları temizler.
  void _loadSingleMarkerForProject(AjansDestek project) {
    _markers.clear(); // Önceki tüm markerları temizle

    if (project.latitude != null && project.longitude != null) {
      _markers.add(
        Marker(
          markerId: MarkerId(project.id),
          position: LatLng(project.latitude!, project.longitude!),
          infoWindow: InfoWindow(
            title: project.projeAdi,
            snippet: '${project.ilce}, ${project.il}',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          AjansDestekDetailScreen(ajansDestekId: project.id),
                ),
              );
            },
          ),
          icon: _getMarkerHueForSupportType(project.destekTuru),
        ),
      );
    }
    setState(() {}); // UI'ı yenile
  }

  // Belirli bir şehre ait projeleri haritada gösteren metod
  // Bu metod sadece il poligonuna tıklandığında çağrılır ve destek türü filtresini dikkate almaz
  Future<void> _loadMarkersForCity(String cityName) async {
    try {
      if (cityName.isEmpty) return;
      
      // Clear previous markers
      setState(() {
        _markers.clear();
      });

      // Check if projects are loaded
      if (_allAjansDestekleri == null || _allAjansDestekleri.isEmpty) {
        debugPrint('UYARI: Proje verileri yüklenmedi veya boş');
        return;
      }

      // Filter projects by city name (case-insensitive)
      final normalizedCityName = cityName.trim().toLowerCase();
      final filteredProjects = _allAjansDestekleri.where(
        (destek) => destek.il.trim().toLowerCase() == normalizedCityName,
      ).toList();

      debugPrint('$cityName için ${filteredProjects.length} proje bulundu');

      // Reset support type filter if active
      if (_selectedSupportType != null && _selectedSupportType != 'Tümü') {
        setState(() {
          _selectedSupportType = null;
        });
      }

      // Add markers for filtered projects
      for (final destek in filteredProjects) {
        try {
          if (destek.latitude != null && destek.longitude != null) {
            _markers.add(
              Marker(
                markerId: MarkerId(destek.id),
                position: LatLng(destek.latitude!, destek.longitude!),
                infoWindow: InfoWindow(
                  title: destek.projeAdi,
                  snippet: '${destek.destekTuru} - ${destek.ilce}, ${destek.il}',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => 
                            AjansDestekDetailScreen(ajansDestekId: destek.id),
                      ),
                    );
                  },
                ),
                icon: _getMarkerHueForSupportType(destek.destekTuru),
              ),
            );
          }
        } catch (e) {
          debugPrint('Hata: ${destek.id} ID li proje için marker oluşturulamadı: $e');
        }
      }

      // Update UI with new markers
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('_loadMarkersForCity hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$cityName için projeler yüklenirken hata oluştu'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Destek türüne göre filtreleme yapan metod
  void _filterBySupportType(String? supportType) {
    debugPrint('\n=== DESTEK TÜRÜNE GÖRE FİLTRELEME BAŞLIYOR ===');
    debugPrint('Seçilen destek türü: "$supportType"');
    
    _selectedSupportType = supportType == 'Tümü' ? null : supportType;
    _markers.clear();

    if (_selectedSupportType != null) {
      // Tüm destek türlerini ve sayılarını logla
      final supportTypeCounts = <String, int>{};
      final allSupportTypes = <String>{};

      for (var destek in _allAjansDestekleri) {
        supportTypeCounts[destek.destekTuru] = (supportTypeCounts[destek.destekTuru] ?? 0) + 1;
        allSupportTypes.add(destek.destekTuru);
      }

      debugPrint('\nTÜM BENZERSİZ DESTEK TÜRLERİ:');
      allSupportTypes.toList()
        ..sort()
        ..forEach((type) => debugPrint(' - "$type" (${supportTypeCounts[type]})'));

      final normalizedSelectedType = _normalizeSupportType(_selectedSupportType!);
      debugPrint('\nARANAN NORMALİZE EDİLMİŞ DESTEK TÜRÜ: "$normalizedSelectedType"');

      var filteredProjects = <AjansDestek>[];
      var matchCount = 0;

      debugPrint('\nEŞLEŞME ARANIYOR...');
      for (var destek in _allAjansDestekleri) {
        final normalizedDestekTuru = _normalizeSupportType(destek.destekTuru);
        final exactMatch = normalizedDestekTuru == normalizedSelectedType;
        final partialMatch = normalizedDestekTuru.contains(normalizedSelectedType) || 
                           normalizedSelectedType.contains(normalizedDestekTuru);
        
        if (exactMatch || partialMatch) {
          filteredProjects.add(destek);
          matchCount++;
          debugPrint('\n✅ EŞLEŞME BULUNDU (${matchCount}):');
          debugPrint('   - Aranan: "$_selectedSupportType"');
          debugPrint('   - Verideki: "${destek.destekTuru}"');
          debugPrint('   - Normalize edilmiş: "$normalizedDestekTuru"');
        }
      }

      debugPrint('Bulunan proje sayısı: ${filteredProjects.length}');

      // Filtrelenen projeler için marker oluştur
      for (final destek in filteredProjects) {
        if (destek.latitude != null && destek.longitude != null) {
          _markers.add(
            Marker(
              markerId: MarkerId(destek.id),
              position: LatLng(destek.latitude!, destek.longitude!),
              infoWindow: InfoWindow(
                title: destek.projeAdi,
                snippet: '${destek.destekTuru} - ${destek.ilce}, ${destek.il}',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              AjansDestekDetailScreen(ajansDestekId: destek.id),
                    ),
                  );
                },
              ),
              icon: _getMarkerHueForSupportType(destek.destekTuru),
            ),
          );
          debugPrint('Eklendi: ${destek.projeAdi} - ${destek.destekTuru}');
        } else {
          debugPrint(
            'Koordinat eksik: ${destek.projeAdi} - ${destek.destekTuru}',
          );
        }
      }

      // Eğer daha önce bir şehir seçilmişse, onu sıfırla
      _lastSearchedCity = null;

      // Eğer filtreleme sonucu hiç proje bulunamadıysa kullanıcıyı bilgilir
      if (filteredProjects.isEmpty) {
        debugPrint('UYARI: "$_selectedSupportType" için hiç proje bulunamadı!');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"$_selectedSupportType" için proje bulunamadı.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      // Eğer filtre kaldırıldıysa, haritayı temizle
      _markers.clear();
      debugPrint('Tüm filtreler kaldırıldı, harita temizlendi.');
    }

    setState(() {
      debugPrint('UI güncellendi. Toplam marker sayısı: ${_markers.length}');
    });
  }

  // Proje arama işlevi (bu kısım tüm projeler arasından arama yapacak)
  void _searchProject(String query) {
    _markers.clear(); // Önceki markerları temizle

    // Eğer arama kutusu boşsa, tüm markerları temizle ve çık
    if (query.isEmpty) {
      _lastSearchedCity = null;
      setState(() {});
      // Haritayı başlangıç durumuna (poligonlar) geri döndür.
      mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _center, zoom: _zoom),
        ),
      );
      return;
    }

    // Arama terimine uyan projeleri filtrele
    var results =
        _allAjansDestekleri
            .where(
              (d) =>
                  d.projeAdi.toLowerCase().contains(query.toLowerCase()) ||
                  d.il.toLowerCase().contains(query.toLowerCase()) ||
                  d.ilce.toLowerCase().contains(query.toLowerCase()) ||
                  d.destekTuru.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();

    // Destek türüne göre filtrele (eğer seçiliyse)
    if (_selectedSupportType != null && _selectedSupportType != 'Tümü') {
      results =
          results.where((d) => d.destekTuru == _selectedSupportType).toList();
    }

    // Eğer sadece bir il arandıysa, şehir olarak kaydet
    final matchingCity = IterableExtension(
      _allAjansDestekleri,
    ).firstWhereOrNull((d) => d.il.toLowerCase() == query.toLowerCase());

    if (matchingCity != null) {
      _lastSearchedCity = matchingCity.il;
    } else {
      _lastSearchedCity = null;
    }

    // Filtrelenen projeler için markerları oluştur
    for (final destek in results) {
      if (destek.latitude != null && destek.longitude != null) {
        _markers.add(
          Marker(
            markerId: MarkerId(destek.id),
            position: LatLng(destek.latitude!, destek.longitude!),
            infoWindow: InfoWindow(
              title: destek.projeAdi,
              snippet: '${destek.destekTuru} - ${destek.ilce}, ${destek.il}',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            AjansDestekDetailScreen(ajansDestekId: destek.id),
                  ),
                );
              },
            ),
            icon: _getMarkerHueForSupportType(destek.destekTuru),
          ),
        );
      }
    }
    setState(() {}); // Markerları güncelle
  }

  // Özel renkli iller
  final Map<String, Color> _specialProvinceColors = {
    'Van': Colors.blue.shade300,
    'Hakkari': Colors.green.shade300,
    'Muş': Colors.purple.shade300,
    'Bitlis': Colors.orange.shade300,
  };

  // Poligon verilerini yükleme metodu
  Future<void> _loadProvincePolygons() async {
    final String response = await rootBundle.loadString(
      'assets/geo/local.json',
    );
    final data = json.decode(response);

    final Set<Polygon> loadedPolygons = {};
    final Map<String, Polygon> loadedPolygonsMap = {};

    for (var provinceData in data['features']) {
      final String provinceName = provinceData['properties']['name'];
      final List<LatLng> polygonPoints = [];

      // GeoJSON yapısına göre koordinatları al ve double'a çevir
      if (provinceData['geometry']['type'] == 'Polygon') {
        for (var coord in provinceData['geometry']['coordinates'][0]) {
          polygonPoints.add(
            LatLng((coord[1] as num).toDouble(), (coord[0] as num).toDouble()),
          );
        }
      } else if (provinceData['geometry']['type'] == 'MultiPolygon') {
        for (var polygonCoords in provinceData['geometry']['coordinates']) {
          for (var coord in polygonCoords[0]) {
            polygonPoints.add(
              LatLng(
                (coord[1] as num).toDouble(),
                (coord[0] as num).toDouble(),
              ),
            );
          }
        }
      }

      // Özel renkli il mi kontrol et
      final bool isSpecialProvince = _specialProvinceColors.containsKey(
        provinceName,
      );
      final Color provinceColor =
          isSpecialProvince
              ? _specialProvinceColors[provinceName]!
              : Colors.blue;

      final Polygon polygon = Polygon(
        polygonId: PolygonId(provinceName),
        points: polygonPoints,
        strokeWidth: isSpecialProvince ? 3 : 2, // Özel illerde daha kalın çizgi
        strokeColor: provinceColor,
        fillColor:
            isSpecialProvince
                ? provinceColor.withOpacity(0.3) // Özel illerde daha koyu dolgu
                : Colors.blue.withOpacity(0.2),
        consumeTapEvents: true,
        onTap: () {
          setState(() {
            _lastSearchedCity = provinceName; // Tıklanan ili kaydet
          });
          _loadMarkersForCity(provinceName);
          _zoomToPolygon(polygonPoints); // Poligona yakınlaştır
        },
      );
      loadedPolygons.add(polygon);
      loadedPolygonsMap[provinceName.toLowerCase()] = polygon;
    }

    setState(() {
      _provincePolygons = loadedPolygons;
      _provincePolygonsMap = loadedPolygonsMap;
    });
  }

  // Poligona yakınlaştırma metodu
  void _zoomToPolygon(List<LatLng> polygonPoints) {
    if (polygonPoints.isEmpty) return;

    double minLat = polygonPoints[0].latitude;
    double maxLat = polygonPoints[0].latitude;
    double minLng = polygonPoints[0].longitude;
    double maxLng = polygonPoints[0].longitude;

    for (var point in polygonPoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        50, // padding
      ),
    );
  }

  // Destek türünü normalleştiren metod
  // - Tüm harfleri küçük yapar
  // - Baştaki ve sondaki boşlukları kaldırır
  // - Çoklu boşlukları tek boşluğa indirger
  // - Türkçe karakterleri İngilizce karşılıkları ile değiştirir
  // - Yaygın varyasyonları standartlaştırır
  String _normalizeSupportType(String supportType) {
    if (supportType.isEmpty) return '';
    
    // Önce temizleme
    String normalized = supportType
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' '); // Çoklu boşlukları tek boşluğa indirge
    
    // Türkçe karakterleri değiştir
    normalized = normalized
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c');
    
    // Yaygın varyasyonları standartlaştır
    final variations = <String, String>{
      'cazibe merkez': 'cazibe merkezleri',
      'cazibe merkezi': 'cazibe merkezleri',
      'cazibe merkezleri destekleme programi': 'cazibe merkezleri',
      'cazibe merkezleri destek programi': 'cazibe merkezleri',
      'cazibe merkezleri programi': 'cazibe merkezleri',
      'proje teklif cagrisi': 'proje teklif cagrisi',
      'proje teklif cagri': 'proje teklif cagrisi',
      'ptc': 'proje teklif cagrisi',
    };
    
    // Varyasyon kontrolü yap
    for (final entry in variations.entries) {
      if (normalized.contains(entry.key)) {
        normalized = entry.value;
        break;
      }
    }
    
    debugPrint('Normalize edilen destek türü: "$supportType" -> "$normalized"');
    return normalized;
  }

  BitmapDescriptor _getMarkerHueForSupportType(String supportType) {
    if (supportType.isEmpty) {
      debugPrint('UYARI: Boş destek türü alındı, varsayılan renk kullanılıyor');
      return BitmapDescriptor.defaultMarker;
    }

    // Log the original support type for debugging
    debugPrint('\n=== RENK EŞLEŞTİRME BAŞLIYOR ===');
    debugPrint('Orijinal destek türü: "$supportType"');

    // Normalize the input support type
    final normalizedType = _normalizeSupportType(supportType);
    debugPrint('Normalize edilmiş destek türü: "$normalizedType"');

    // Özel eşleştirmeler - öncelikle kontrol edilecek
    final specialMappings = <String, Color>{
      'cazibe merkezleri': Colors.purple,
      'cazibe merkez': Colors.purple,
      'cazibe merkezi': Colors.purple,
      'proje teklif cagrisi': Colors.red,
      'proje teklif cagri': Colors.red,
      'ptc': Colors.red,
      'güdümlü proje': Colors.pinkAccent,
      'sosyal gelişme': Colors.indigo,
      'teknik destek': Colors.amber,
    };

    // Özel eşleştirmeleri kontrol et
    for (final entry in specialMappings.entries) {
      if (normalizedType.contains(entry.key)) {
        debugPrint('✅ ÖZEL EŞLEŞME: "$supportType" -> "${entry.key}" -> ${entry.value}');
        try {
          final hsvColor = HSVColor.fromColor(entry.value);
          return BitmapDescriptor.defaultMarkerWithHue(hsvColor.hue);
        } catch (e) {
          debugPrint('HATA: Özel renk dönüşümü başarısız: $e');
          return BitmapDescriptor.defaultMarker;
        }
      }
    }

    // Eğer özel eşleşme yoksa, normal eşleştirme yap
    debugPrint('Özel eşleşme bulunamadı, normal eşleştirme yapılıyor...');
    
    // Try to find a matching color (case-insensitive and trimmed)
    String? matchedKey;
    Color? color;

    // Önce tam eşleşme kontrolü
    for (var entry in _markerColors.entries) {
      final normalizedEntryKey = _normalizeSupportType(entry.key);
      debugPrint('  Kontrol edilen anahtar: "${entry.key}" -> "$normalizedEntryKey"');
      
      if (normalizedEntryKey == normalizedType) {
        matchedKey = entry.key;
        color = entry.value;
        debugPrint('  ✅ Tam eşleşme bulundu: "$matchedKey" -> $color');
        break;
      }
    }

    // Eğer tam eşleşme yoksa, kısmi eşleşme kontrolü
    if (color == null) {
      debugPrint('Tam eşleşme bulunamadı, kısmi eşleşme aranıyor...');
      for (var entry in _markerColors.entries) {
        final normalizedEntryKey = _normalizeSupportType(entry.key);
        if (normalizedType.contains(normalizedEntryKey) || 
            normalizedEntryKey.contains(normalizedType)) {
          matchedKey = entry.key;
          color = entry.value;
          debugPrint('  ✅ Kısmi eşleşme bulundu: "$matchedKey" -> $color');
          break;
        }
      }
    }

    // If no match found, use the default 'Diğer' color
    if (color == null) {
      debugPrint('UYARI: "$supportType" için eşleşen renk bulunamadı. Varsayılan renk kullanılıyor.');
      color = _markerColors['diğer'] ?? Colors.grey;
    }

    debugPrint('Sonuç: "$supportType" -> "$matchedKey" -> $color');

    // Convert color to HSV and get the hue value (0-360)
    try {
      final hsvColor = HSVColor.fromColor(color);
      return BitmapDescriptor.defaultMarkerWithHue(hsvColor.hue);
    } catch (e) {
      debugPrint('HATA: Renk dönüşümü başarısız: $e');
      return BitmapDescriptor.defaultMarker;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ajans Destek Haritası',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 8, 49, 70),

        foregroundColor: colorScheme.onPrimary,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt_rounded),
            tooltip: 'Proje Listesini Görüntüle',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ProjectListScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    // Arama çubuğu
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Proje, İl veya İlçe Ara...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _markers
                                  .clear(); // Arama temizlendiğinde markerları da temizle
                              _lastSearchedCity = null;
                            });
                            // Haritayı başlangıç durumuna (poligonlar) geri döndür.
                            mapController?.animateCamera(
                              CameraUpdate.newCameraPosition(
                                CameraPosition(target: _center, zoom: _zoom),
                              ),
                            );
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onChanged: (query) {
                        _searchProject(
                          query,
                        ); // Arama değiştikçe projeleri filtrele
                      },
                    ),
                    const SizedBox(height: 8),
                    // Destek türü filtreleme dropdown'ı
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedSupportType ?? 'Tümü',
                          isExpanded: true,
                          hint: const Text('Destek Türü Seçiniz'),
                          items:
                              _supportTypes.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                          onChanged: (String? newValue) {
                            _filterBySupportType(newValue);
                          },
                        ),
                      ),
                    ),
                    // Seçili filtreyi göster
                    if (_selectedSupportType != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          children: [
                            Chip(
                              label: Text(_selectedSupportType!),
                              backgroundColor:
                                  (_markerColors[_selectedSupportType] ??
                                          Colors.grey)
                                      .withOpacity(0.2),
                              labelStyle: TextStyle(
                                color:
                                    _markerColors[_selectedSupportType] ??
                                    Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                              deleteIcon: const Icon(Icons.close, size: 18),
                              onDeleted: () {
                                _filterBySupportType('Tümü');
                              },
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () {
                                _filterBySupportType('Tümü');
                              },
                              child: const Icon(Icons.refresh, size: 18),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: GoogleMap(
                  onMapCreated: (controller) {
                    mapController = controller;
                    // Eğer bir projeden haritaya geldiysek, o projeye ve iline odaklan.
                    if (widget.initialLatitude != null &&
                        widget.initialLongitude != null) {
                      // Eğer belirli bir proje ID'si ile geldiysek, o projeyi bulup odaklan
                      if (widget.initialProjectId != null) {
                        final selectedProject = IterableExtension(
                          _allAjansDestekleri,
                        ).firstWhereOrNull(
                          (p) => p.id == widget.initialProjectId,
                        );
                        if (selectedProject != null) {
                          _loadSingleMarkerForProject(selectedProject);
                          mapController?.animateCamera(
                            CameraUpdate.newLatLngZoom(
                              LatLng(
                                selectedProject.latitude!,
                                selectedProject.longitude!,
                              ),
                              _zoom, // Sadece projeye odaklandığında belirlediğimiz zoom seviyesi
                            ),
                          );
                        }
                      } else {
                        // Eğer initialProjectId yoksa, eski davranış devam eder (ili yükle)
                        final selectedProject = IterableExtension(
                          _allAjansDestekleri,
                        ).firstWhereOrNull(
                          (p) =>
                              p.latitude == widget.initialLatitude &&
                              p.longitude == widget.initialLongitude,
                        );
                        if (selectedProject != null) {
                          final polygonToZoom =
                              _provincePolygonsMap[selectedProject.il
                                  .toLowerCase()];
                          if (polygonToZoom != null) {
                            _zoomToPolygon(polygonToZoom.points);
                          } else {
                            mapController?.animateCamera(
                              CameraUpdate.newLatLngZoom(
                                LatLng(
                                  widget.initialLatitude!,
                                  widget.initialLongitude!,
                                ),
                                _zoom,
                              ),
                            );
                          }
                        }
                      }
                    } else {
                      // Normal başlangıçta haritayı varsayılan konuma ayarla (poligonlar görünür)
                      mapController?.animateCamera(
                        CameraUpdate.newCameraPosition(
                          CameraPosition(target: _center, zoom: _zoom),
                        ),
                      );
                    }
                  },
                  initialCameraPosition: CameraPosition(
                    target: _center,
                    zoom: _zoom,
                  ),
                  mapType: _currentMapType,
                  markers:
                      _markers, // Markerlar sadece il tıklamasına veya aramaya göre görünür
                  polygons: _provincePolygons, // Poligonlar her zaman görünür
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                ),
              ),
            ],
          ),

          // Sol alt köşedeki Marker Renk Efsanesi
          Positioned(
            left: 10,
            bottom: 130,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Toggle Button
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isLegendExpanded = !_isLegendExpanded;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isLegendExpanded
                              ? Icons.arrow_drop_down
                              : Icons.arrow_right,
                          color: Colors.black87,
                          size: 40,
                        ),
                        const Text(
                          'Gösterge',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // Legend Content
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: _isLegendExpanded ? null : 0,
                  child: SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:
                            _markerColors.entries.map((e) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 2,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      color: e.value,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      e.key,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Sol alt köşedeki butonlar (üst üste)
          Positioned(
            left: 20,
            bottom: 10,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                SizedBox(
                  width: 50,
                  height: 50,
                  child: FloatingActionButton(
                    heroTag: 'addProject',
                    backgroundColor: Colors.green,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => const AjansDestekAddEditScreen(),
                        ),
                      );
                    },
                    child: const Icon(Icons.add, size: 40),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: 50,
                  height: 50,
                  child: FloatingActionButton(
                    heroTag: 'mapType',
                    backgroundColor: Colors.blueAccent,
                    onPressed: () {
                      setState(() {
                        _currentMapType =
                            _currentMapType == MapType.normal
                                ? MapType.hybrid
                                : MapType.normal;
                      });
                    },
                    child: const Icon(Icons.layers, size: 38),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
