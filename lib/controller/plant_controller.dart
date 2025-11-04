import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class PlantController {
  final supabase = Supabase.instance.client;
  
  List<Map<String, dynamic>> plants = [];
  List<Map<String, dynamic>> fields = [];
  bool isLoadingPlants = true;
  
  final VoidCallback onUpdate;
  
  PlantController({required this.onUpdate});

  Future<void> loadData() async {
    await Future.wait([
      loadPlantsFromDatabase(),
      loadFieldsFromDatabase(),
    ]);
  }

  Future<void> loadPlantsFromDatabase() async {
    try {
      isLoadingPlants = true;
      onUpdate();

      final response = await supabase
          .from('plant')
          .select('*, fields(name)')
          .order('created_at', ascending: false);

      plants = List<Map<String, dynamic>>.from(response);
      isLoadingPlants = false;
      onUpdate();
    } catch (e) {
      debugPrint('Error loading plants: $e');
      isLoadingPlants = false;
      onUpdate();
      rethrow;
    }
  }

  Future<void> loadFieldsFromDatabase() async {
    try {
      final response = await supabase
          .from('fields')
          .select()
          .order('name', ascending: true);

      fields = List<Map<String, dynamic>>.from(response);
      onUpdate();
    } catch (e) {
      debugPrint('Error loading fields: $e');
      rethrow;
    }
  }

  Future<bool> savePlantToDatabase({
    required String name,
    required String imageUrl,
    String? quantity,
    String? fieldId,
    String? planting_day,
  }) async {
    try {
      await supabase.from('plant').insert({
        'name': name,
        'image': imageUrl,
        'quantity': quantity,
        'field_id': fieldId,
        'planting_day': planting_day
      });
      return true;
    } catch (e) {
      debugPrint('Error saving plant: $e');
      rethrow;
    }
  }

  List<Map<String, dynamic>> filterPlants(String searchText) {
    return plants
        .where((p) => (p['name'] ?? '')
            .toLowerCase()
            .contains(searchText.toLowerCase()))
        .toList();
  }

List<Map<String, dynamic>> sortPlants(
      List<Map<String, dynamic>> plants, String filter) {
    final sorted = List<Map<String, dynamic>>.from(plants);
    switch (filter) {
      case 'A-Z':
        sorted.sort((a, b) =>
            (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()));
        break;
      case 'Z-A':
        sorted.sort((a, b) =>
            (b['name'] ?? '').toString().compareTo((a['name'] ?? '').toString()));
        break;
      case 'Date added':
        sorted.sort((a, b) => DateTime.parse(b['created_at'])
            .compareTo(DateTime.parse(a['created_at'])));
        break;
      case 'Quantity':
        sorted.sort((a, b) {
          final int aQuantity = int.tryParse(a['quantity']?.toString() ?? '0') ?? 0;
          final int bQuantity = int.tryParse(b['quantity']?.toString() ?? '0') ?? 0;
          return bQuantity.compareTo(aQuantity);
        });
        break;
      case 'Planted (Newest)':
        sorted.sort((a, b) {
          final aDate = _parsePlantingDate(a['planting_day']);
          final bDate = _parsePlantingDate(b['planting_day']);
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1; // nulls last
          if (bDate == null) return -1;
          return bDate.compareTo(aDate); // newest first
        });
        break;
      case 'Planted (Oldest)':
        sorted.sort((a, b) {
          final aDate = _parsePlantingDate(a['planting_day']);
          final bDate = _parsePlantingDate(b['planting_day']);
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1; // nulls last
          if (bDate == null) return -1;
          return aDate.compareTo(bDate); // oldest first
        });
        break;
    }
    return sorted;
  }

  DateTime? _parsePlantingDate(dynamic plantingDay) {
    if (plantingDay == null || plantingDay.toString().isEmpty || plantingDay == 'N/A') {
      return null;
    }
    
    try {
      final parts = plantingDay.toString().split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (e) {
      debugPrint('Error parsing planting date: $e');
    }
    
    return null;
  }

  Map<String, List<Map<String, dynamic>>> groupPlantsByFarm(
      List<Map<String, dynamic>> plants) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    grouped['Main'] = List.from(plants);
    for (var plant in plants) {
      final fieldData = plant['fields'];
      if (fieldData != null && fieldData is Map) {
        final fieldName = fieldData['name'];
        if (fieldName != null && fieldName.toString().isNotEmpty) {
          grouped.putIfAbsent(fieldName, () => []);
          grouped[fieldName]!.add(plant);
        }
      }
    }
    return grouped;
  }

  List<MapEntry<String, List<Map<String, dynamic>>>> sortGroupsByQuantity(
      Map<String, List<Map<String, dynamic>>> grouped) {
    final sortedGroups = grouped.entries.toList();
    sortedGroups.sort((a, b) => b.value.length.compareTo(a.value.length));
    return sortedGroups;
  }

  Future<String?> uploadImageToSupabase(String filePath) async {
    try {
      final file = File(filePath);
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      await supabase.storage.from('plant_images').upload(fileName, file);
      final publicUrl =
          supabase.storage.from('plant_images').getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      rethrow;
    }
  }
}