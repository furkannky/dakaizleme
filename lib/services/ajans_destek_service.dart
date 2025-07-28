// lib/services/ajans_destek_service.dart
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/ajans_destek.dart';

class AjansDestekService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collectionName = 'dakaDestekleri';

  /// Normalizes Turkish characters and converts to lowercase for case-insensitive comparison
  String normalizeTurkish(String input) {
    return input
        .replaceAll('İ', 'i')
        .replaceAll('ı', 'i')
        .replaceAll('Ğ', 'g')
        .replaceAll('ğ', 'g')
        .replaceAll('Ü', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('Ş', 's')
        .replaceAll('ş', 's')
        .replaceAll('Ö', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('Ç', 'c')
        .replaceAll('ç', 'c')
        .toLowerCase()
        .trim();
  }

  /// Fetches all AjansDestek records with optional filtering
  Stream<List<AjansDestek>> getAjansDestekleri({
    String? yil,
    String? destekTuru,
    String? projeDurumu,
    String? il,
    String? ilce,
  }) async* {
    // Debug: Print all field values for reference
    await debugFieldValues('il');
    await debugFieldValues('ilce');
    
    debugPrint('\n=== NEW QUERY ===');
    debugPrint('Filters:');
    debugPrint('- il: $il');
    debugPrint('- ilce: $ilce');
    debugPrint('- yil: $yil');
    debugPrint('- destekTuru: $destekTuru');
    debugPrint('- projeDurumu: $projeDurumu');
    
    try {
      Query query = _db.collection(_collectionName);
      List<String>? matchingDocIds;

      // Handle city (il) filtering with case-insensitive and Turkish character support
      if (il != null && il.isNotEmpty) {
        final normalizedIl = normalizeTurkish(il);
        debugPrint('Filtering by city (il or ilce): $normalizedIl');
        
        // First, get all documents and filter in memory
        final snapshot = await _db.collection(_collectionName).get();
        matchingDocIds = [];
        
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final docIl = data['il']?.toString() ?? '';
          final docIlce = data['ilce']?.toString() ?? '';
          
          if (normalizeTurkish(docIl) == normalizedIl || 
              normalizeTurkish(docIlce) == normalizedIl) {
            matchingDocIds.add(doc.id);
          }
        }
        
        debugPrint('Found ${matchingDocIds.length} matching documents');
        
        if (matchingDocIds.isEmpty) {
          // If no matches, yield empty list and return
          yield [];
          return;
        }
      }

      // Apply remaining filters
      if (yil != null && yil.isNotEmpty) {
        final yilInt = int.tryParse(yil);
        if (yilInt != null) {
          query = query.where('yil', isEqualTo: yilInt);
        } else {
          debugPrint('Warning: Could not parse year "$yil" as integer');
        }
      }
      
      if (destekTuru != null && destekTuru.isNotEmpty) {
        query = query.where('destekTuru', isEqualTo: destekTuru);
      }
      
      if (projeDurumu != null && projeDurumu.isNotEmpty) {
        query = query.where('projeDurumu', isEqualTo: projeDurumu);
      }
      
      if (matchingDocIds != null) {
        query = query.where(FieldPath.documentId, whereIn: matchingDocIds);
      }
      
      if (ilce != null && ilce.isNotEmpty) {
        query = query.where('ilce', isEqualTo: ilce);
      }

      debugPrint('Final query: $query');
      
      // Set up the real-time listener
      yield* query.snapshots().map((snapshot) {
        debugPrint('Realtime update: ${snapshot.docs.length} documents');
        return snapshot.docs
            .map((doc) => AjansDestek.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
      });
    } catch (e) {
      log('Error in getAjansDestekleri: $e');
      rethrow;
    }
  }

  /// Fetches a single AjansDestek by its ID
  Future<AjansDestek?> getAjansDestekById(String id) async {
    try {
      final doc = await _db.collection(_collectionName).doc(id).get();
      if (doc.exists) {
        return AjansDestek.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      log('Error getting AjansDestek by ID: $e');
      rethrow;
    }
  }

  /// Adds a new AjansDestek to Firestore
  Future<DocumentReference> addAjansDestek(AjansDestek ajansDestek) async {
    try {
      return await _db
          .collection(_collectionName)
          .add(ajansDestek.toFirestore());
    } catch (e) {
      debugPrint('Error adding AjansDestek: $e');
      rethrow;
    }
  }

  /// Updates an existing AjansDestek in Firestore
  Future<void> updateAjansDestek(AjansDestek ajansDestek) async {
    if (ajansDestek.id.isEmpty) {
      throw Exception("Ajans destek ID'si boş olamaz.");
    }
    try {
      await _db
          .collection(_collectionName)
          .doc(ajansDestek.id)
          .update(ajansDestek.toFirestore());
    } catch (e) {
      debugPrint('Error updating AjansDestek: $e');
      rethrow;
    }
  }

  /// Deletes an AjansDestek from Firestore
  Future<void> deleteAjansDestek(String id) async {
    try {
      await _db.collection(_collectionName).doc(id).delete();
    } catch (e) {
      debugPrint('Error deleting AjansDestek: $e');
      rethrow;
    }
  }

  /// Gets the count of AjansDestek records
  Future<int> getAjansDestekleriCount() async {
    try {
      final snapshot = await _db.collection(_collectionName).count().get();
      return snapshot.count ?? 0; // Ensure we return 0 instead of null
    } catch (e) {
      log('Error getting AjansDestek count: $e');
      rethrow;
    }
  }

  /// Gets distinct values for a specific field (for filters)
  // Debug function to print all unique values for a field
  Future<void> debugFieldValues(String fieldName) async {
    try {
      debugPrint('\n=== DEBUG: Checking $fieldName values ===');
      final snapshot = await _db.collection(_collectionName).get();
      
      // Get all non-null values
      final allValues = snapshot.docs
          .map((doc) => doc.data()[fieldName]?.toString().trim())
          .where((value) => value != null && value.isNotEmpty)
          .toList();
      
      // Count occurrences of each value
      final valueCounts = <String, int>{};
      for (var value in allValues) {
        valueCounts[value!] = (valueCounts[value] ?? 0) + 1;
      }
      
      // Print results
      debugPrint('Found ${allValues.length} non-null values for $fieldName');
      debugPrint('Unique values and their counts:');
      valueCounts.entries.toList()
        ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()))
        ..forEach((entry) => debugPrint('  "${entry.key}": ${entry.value}'));
      
      // Check for similar values (case-insensitive)
      final lowerCaseValues = allValues.map((v) => v!.toLowerCase()).toList();
      final uniqueLowerValues = lowerCaseValues.toSet().toList();
      
      if (uniqueLowerValues.length < allValues.length) {
        debugPrint('\nPossible duplicate values (case-insensitive):');
        for (var value in uniqueLowerValues) {
          final originals = allValues.where((v) => v!.toLowerCase() == value).toSet();
          if (originals.length > 1) {
            debugPrint('  "$value" appears as: ${originals.join(', ')}');
          }
        }
      }
      
      debugPrint('=== END DEBUG ===\n');
    } catch (e) {
      debugPrint('Error in debugFieldValues: $e');
    }
  }

  Future<List<String>> getDistinctFieldValues(String fieldName) async {
    try {
      // Debug: Print detailed info about this field
      await debugFieldValues(fieldName);
      
      final snapshot = await _db.collection(_collectionName).get();
      
      // Get all non-empty values
      final values = snapshot.docs
          .map((doc) => doc.data()[fieldName]?.toString().trim() ?? '')
          .where((value) => value.isNotEmpty)
          .toList();
      
      // For city field, ensure consistent casing
      if (fieldName == 'il' || fieldName == 'ilce') {
        // Convert to title case for display
        final processedValues = values.map((value) {
          if (value.isEmpty) return value;
          // Handle Turkish characters properly
          return value[0].toUpperCase() + value.substring(1).toLowerCase();
        }).toSet().toList();
        
        processedValues.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        return processedValues;
      }
      
      // For other fields, just return unique sorted values
      return values.toSet().toList()..sort();
    } catch (e) {
      debugPrint('Error getting distinct values for $fieldName: $e');
      rethrow;
    }
  }

}

// Aşağıdaki "konumlar" haritasını ve "updateDocumentLocationsFromMap" fonksiyonunu kaldırın.
// final Map<String, LatLng> konumlar = { /* ... */ };
// Future<void> updateDocumentLocationsFromMap() async { /* ... */ }
