// lib/views/map_picker_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_android/geolocator_android.dart';
import 'package:geolocator_apple/geolocator_apple.dart';

class MapPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;
  final String title;

  const MapPickerScreen({
    super.key,
    this.initialLocation,
    this.title = 'Konum Seçin',
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  LatLng? _pickedLocation;
  Set<Marker> _markers = {};
  GoogleMapController? _mapController;
  MapType _currentMapType = MapType.satellite;
  bool _isMapReady = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      if (widget.initialLocation != null) {
        _pickedLocation = widget.initialLocation;
        _addMarker(_pickedLocation!);
      } else {
        // Try to get current location if no initial location is provided
        await _getCurrentLocation();
      }
      if (mounted) {
        setState(() {
          _isMapReady = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Harita yüklenirken bir hata oluştu: ${e.toString()}';
          _isMapReady = true; // Still set to true to show error UI
        });
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Konum servisleri devre dışı';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Konum izinleri reddedildi';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Konum izinleri kalıcı olarak reddedildi, ayarlardan etkinleştirin';
      }

      Position position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _pickedLocation = LatLng(position.latitude, position.longitude);
          _addMarker(_pickedLocation!);
        });
      }
    } catch (e) {
      // If we can't get current location, default to Turkey center
      if (mounted) {
        setState(() {
          _pickedLocation = const LatLng(38.80, 40.00); // Türkiye ortası
          _addMarker(_pickedLocation!);
          _errorMessage =
              'Mevcut konum alınamadı, varsayılan konum kullanılıyor';
        });
      }
    }
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    _mapController = controller;
    
    // Harita stilini ayarla (daha net görüntü için)
    await controller.setMapStyle('''
      [
        {
          "featureType": "all",
          "elementType": "all",
          "stylers": [
            {"saturation": -100},
            {"gamma": 1.0},
            {"lightness": 0.5}
          ]
        }
      ]
    ''');

    if (_pickedLocation != null) {
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _pickedLocation!,
            zoom: 18.0, // Daha yüksek zoom seviyesi
            tilt: 45.0, // 3D etkisi için hafif açı
            bearing: 0.0
          ),
        ),
      );
    }
  }

  void _selectLocation(LatLng position) {
    setState(() {
      _pickedLocation = position;
      _markers.clear();
      _addMarker(position);
    });
  }

  void _addMarker(LatLng position) {
    _markers.add(
      Marker(
        markerId: const MarkerId('pickedLocation'),
        position: position,
        infoWindow: const InfoWindow(title: 'Seçilen Konum'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );
  }

  // Map type names in Turkish
  final Map<MapType, String> _mapTypeNames = {
    MapType.normal: 'Normal Harita',
    MapType.satellite: 'Uydu Görünümü',
    MapType.terrain: 'Arazi Görünümü',
    MapType.hybrid: 'Hibrit Görünüm',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          // Map type dropdown
          Padding(
            padding: const EdgeInsets.only(right: 8.0, top: 8.0, bottom: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<MapType>(
                  value: _currentMapType,
                  icon: const Icon(Icons.arrow_drop_down, size: 24),
                  iconSize: 24,
                  elevation: 16,
                  style: Theme.of(context).textTheme.bodyMedium,
                  onChanged: (MapType? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _currentMapType = newValue;
                      });
                    }
                  },
                  items:
                      _mapTypeNames.entries.map<DropdownMenuItem<MapType>>((
                        entry,
                      ) {
                        return DropdownMenuItem<MapType>(
                          value: entry.key,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                            ),
                            child: Text(
                              entry.value,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ),
            ),
          ),
          // Done button
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: const Icon(Icons.check_circle, size: 28),
              tooltip: 'Konumu se',
              onPressed:
                  _pickedLocation == null
                      ? null
                      : () {
                        Navigator.of(context).pop(_pickedLocation);
                      },
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_isMapReady && _errorMessage == null) ...[
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _pickedLocation ?? const LatLng(38.80, 40.00), // Türkiye ortası
                zoom: 18.0, // Daha yüksek başlangıç zoom seviyesi
                tilt: 45.0, // 3D etkisi için hafif açı
                bearing: 0.0
              ),
              zoomControlsEnabled: true,
              zoomGesturesEnabled: true,
              buildingsEnabled: true,
              rotateGesturesEnabled: true,
              tiltGesturesEnabled: true,
              onMapCreated: (controller) {
                _mapController = controller;
                _onMapCreated(controller);
              },
              onTap: _selectLocation,
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              mapType: _currentMapType,
            ),
          ] else if (_errorMessage != null) ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tekrar Dene'),
                      onPressed: () {
                        setState(() {
                          _errorMessage = null;
                          _isMapReady = false;
                        });
                        _initializeMap();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Harita yükleniyor...'),
                ],
              ),
            ),
          ],
          if (_pickedLocation == null)
            const Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Card(
                  elevation: 4,
                  color: Colors.blueAccent,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Harita üzerinde bir konum seçmek için dokunun',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
