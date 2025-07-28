import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class DakaMapPage extends StatefulWidget {
  const DakaMapPage({Key? key}) : super(key: key);

  @override
  State<DakaMapPage> createState() => _DakaMapPageState();
}

class _DakaMapPageState extends State<DakaMapPage> {
  Map<String, List<LatLng>> provinces = {};

  @override
  void initState() {
    super.initState();
    loadFourProvinces();
  }

  Future<void> loadFourProvinces() async {
    try {
      final data = await rootBundle.loadString('assets/geo/local.json');
      final geo = json.decode(data);

      final Map<String, List<LatLng>> result = {};

      for (var f in geo['features']) {
        final id = f['properties']['id'];
        if (['TR49', 'TR65', 'TR30', 'TR13'].contains(id)) {
          final coords = <LatLng>[];
          final geom = f['geometry'];
          if (geom['type'] == 'Polygon') {
            for (var ring in geom['coordinates']) {
              coords.addAll(ring.map<LatLng>((c) => LatLng(c[1], c[0])));
            }
          } else if (geom['type'] == 'MultiPolygon') {
            for (var poly in geom['coordinates']) {
              for (var ring in poly) {
                coords.addAll(ring.map<LatLng>((c) => LatLng(c[1], c[0])));
              }
            }
          }
          result[id] = coords;
        }
      }

      setState(() {
        provinces = result;
      });
    } catch (e) {
      print('Error loading GeoJSON data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (provinces.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final colorMap = {
      'TR49': Colors.red.withOpacity(0.5),   // Muş
      'TR65': Colors.green.withOpacity(0.5), // Van
      'TR30': Colors.orange.withOpacity(0.5),// Hakkari
      'TR13': Colors.blue.withOpacity(0.5),  // Bitlis
    };

    return Scaffold(
      appBar: AppBar(title: const Text('DAKA Destekli Projeler Haritası')),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(38.5, 42.8),
          initialZoom: 7,
        ),
        children: [
          TileLayer(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            userAgentPackageName: 'com.example.dakamapapp', // Your package name here
          ),
          PolygonLayer(
            polygons: provinces.entries.map((entry) {
              return Polygon(
                points: entry.value,
                color: colorMap[entry.key]!, // Providing a color implies it's filled
                borderColor: Colors.white,
                borderStrokeWidth: 2,
                // isFilled: true, // This parameter is no longer needed
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}