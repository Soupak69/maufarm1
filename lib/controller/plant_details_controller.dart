import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class PlantDetailsController {
  final Map<String, dynamic> plant;
  final BuildContext context;
  
  final supabase = Supabase.instance.client;
  final ImagePicker _imagePicker = ImagePicker();
  
  late TextEditingController nameController;
  late TextEditingController quantityController;
  
  String? selectedFieldId;
  String? selectedFieldName;
  DateTime? selectedPlantingDate;
  List<Map<String, dynamic>> fields = [];
  List<Map<String, dynamic>> progressPhotos = [];
  
  bool isLoading = false;
  bool isLoadingProgress = false;
  
  String? currentImageUrl;
  File? newImageFile;
  
  // Callbacks for UI updates
  final VoidCallback onStateChanged;
  
  PlantDetailsController({
    required this.plant,
    required this.context,
    required this.onStateChanged,
  }) {
    _initialize();
  }
  
  void _initialize() {
    // Initialize controllers
    nameController = TextEditingController(text: plant['name'] ?? '');
    quantityController = TextEditingController(text: plant['quantity']?.toString() ?? '');
    
    // Initialize image
    currentImageUrl = plant['image'];
    
    // Initialize field
    final fieldData = plant['fields'];
    if (fieldData != null && fieldData is Map) {
      selectedFieldId = plant['field_id']?.toString();
      selectedFieldName = fieldData['name']?.toString();
    }
    
    // Initialize planting date
    final plantingDay = plant['planting_day']?.toString();
    if (plantingDay != null && plantingDay != 'N/A') {
      selectedPlantingDate = _parsePlantingDate(plantingDay);
    }
    
    loadFields();
    loadProgressPhotos();
  }
  
  void dispose() {
    nameController.dispose();
    quantityController.dispose();
  }
  
  DateTime? _parsePlantingDate(String plantingDay) {
    try {
      final parts = plantingDay.split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (e) {
      debugPrint('Error parsing date: $e');
    }
    return null;
  }
  
  String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
  
  Future<void> loadFields() async {
    try {
      final response = await supabase
          .from('fields')
          .select()
          .order('name', ascending: true);
      
      fields = List<Map<String, dynamic>>.from(response);
      onStateChanged();
    } catch (e) {
      debugPrint('Error loading fields: $e');
    }
  }
  
  Future<void> loadProgressPhotos() async {
    try {
      isLoadingProgress = true;
      onStateChanged();
      
      final response = await supabase
          .from('plant_progress')
          .select()
          .eq('plant_id', plant['id'])
          .order('week_number', ascending: true);

      progressPhotos = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error loading progress photos: $e');
    } finally {
      isLoadingProgress = false;
      onStateChanged();
    }
  }
  
  Future<void> uploadProgressPhoto(int weekNumber) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return;

      final file = File(image.path);

      final fileName =
          'progress_${plant['id']}_week$weekNumber\_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await supabase.storage.from('plant_images').upload(fileName, file);

      final imageUrl =
          supabase.storage.from('plant_images').getPublicUrl(fileName);

      await supabase.from('plant_progress').insert({
        'plant_id': plant['id'],
        'week_number': weekNumber,
        'image_url': imageUrl,
      });

      await loadProgressPhotos();

      _showSnackBar('Progress photo added');
    } catch (e) {
      debugPrint('Error uploading progress photo: $e');
      _showSnackBar('Error uploading: $e');
    }
  }
  
  Future<bool> updatePlant() async {
    if (nameController.text.trim().isEmpty) {
      _showSnackBar('Plant name cannot be empty');
      return false;
    }

    isLoading = true;
    onStateChanged();

    try {
      String? imageUrl = currentImageUrl;
      String? oldImagePath;
      
      // Extract old image path if it exists
      if (currentImageUrl != null && currentImageUrl!.isNotEmpty) {
        try {
          final uri = Uri.parse(currentImageUrl!);
          final pathSegments = uri.pathSegments;
          if (pathSegments.length >= 2) {
            oldImagePath = pathSegments.last;
          }
        } catch (e) {
          debugPrint('Error parsing old image URL: $e');
        }
      }
      
      // Upload new image if selected
      if (newImageFile != null) {
        final fileName = 'plant_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await supabase.storage
            .from('plant_images')
            .upload(fileName, newImageFile!);
        
        imageUrl = supabase.storage
            .from('plant_images')
            .getPublicUrl(fileName);
            
        // Delete old image
        if (oldImagePath != null) {
          try {
            await supabase.storage
                .from('plant_images')
                .remove([oldImagePath]);
            debugPrint('Old image deleted: $oldImagePath');
          } catch (e) {
            debugPrint('Error deleting old image: $e');
          }
        }
      }
      
      // Delete image if removed
      if (currentImageUrl == null && oldImagePath != null && plant['image'] != null) {
        try {
          await supabase.storage
              .from('plant_images')
              .remove([oldImagePath]);
          debugPrint('Image deleted from storage: $oldImagePath');
        } catch (e) {
          debugPrint('Error deleting image: $e');
        }
      }

      await supabase.from('plant').update({
        'name': nameController.text.trim(),
        'quantity': quantityController.text.trim().isEmpty 
            ? null 
            : quantityController.text.trim(),
        'field_id': selectedFieldId,
        'planting_day': selectedPlantingDate != null 
            ? formatDate(selectedPlantingDate!) 
            : null,
        'image': imageUrl,
      }).eq('id', plant['id']);

      _showSnackBar('Plant updated successfully', isSuccess: true);
      return true;
    } catch (e) {
      _showSnackBar('Error updating plant: $e');
      return false;
    } finally {
      isLoading = false;
      onStateChanged();
    }
  }
  
  Future<bool> deletePlant() async {
    isLoading = true;
    onStateChanged();

    try {
      await supabase.from('plant').update({'is_deleted': true}).eq('id', plant['id']);

      _showSnackBar('Plant deleted successfully', isSuccess: true, isDelete: true);
      Future.delayed(const Duration(milliseconds: 300), () {
        if (Navigator.canPop(context)) {
          Navigator.pop(context, true);
        }
      });
  return true;
    } catch (e) {
      _showSnackBar('Error deleting plant: $e');
      return false;
    } finally {
      isLoading = false;
      onStateChanged();
    }
  }
  
  Future<void> selectPlantingDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedPlantingDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF52B788),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1B4332),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      selectedPlantingDate = picked;
      onStateChanged();
    }
  }
  
  void selectField(String? fieldId, String? fieldName) {
    selectedFieldId = fieldId;
    selectedFieldName = fieldName;
    onStateChanged();
  }
  
  Future<void> pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        newImageFile = File(image.path);
        onStateChanged();
      }
    } catch (e) {
      _showSnackBar('Error picking image: $e');
    }
  }
  
  Future<void> takePicture() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        newImageFile = File(image.path);
        onStateChanged();
      }
    } catch (e) {
      _showSnackBar('Error taking picture: $e');
    }
  }
  
  void deleteImage() {
    currentImageUrl = null;
    newImageFile = null;
    onStateChanged();
  }
  
  int getNextWeekNumber() {
    if (progressPhotos.isEmpty) return 1;
    return (progressPhotos.last['week_number'] ?? 0) + 1;
  }
  
  Future<void> deleteProgressPhoto(int progressPhotoId, String imageUrl) async {
    try {
      // Extract image path from URL
      String? imagePath;
      try {
        final uri = Uri.parse(imageUrl);
        final pathSegments = uri.pathSegments;
        if (pathSegments.length >= 2) {
          imagePath = pathSegments.last;
        }
      } catch (e) {
        debugPrint('Error parsing image URL: $e');
      }

      // Delete from database
      await supabase.from('plant_progress').delete().eq('id', progressPhotoId);

      // Delete from storage if path exists
      if (imagePath != null) {
        try {
          await supabase.storage.from('plant_images').remove([imagePath]);
          debugPrint('Progress photo deleted from storage: $imagePath');
        } catch (e) {
          debugPrint('Error deleting progress photo from storage: $e');
        }
      }

      // Reload progress photos
      await loadProgressPhotos();

      _showSnackBar('Progress photo deleted', isSuccess: true);
    } catch (e) {
      debugPrint('Error deleting progress photo: $e');
      _showSnackBar('Error deleting photo: $e');
    }
  }

  Future<void> setProgressPhotoAsThumbnail(String imageUrl) async {
    try {
      // Set the current image to this progress photo's URL
      currentImageUrl = imageUrl;
      newImageFile = null;
      
      onStateChanged();
      
      _showSnackBar('Set as thumbnail. Save to apply changes.', isSuccess: true);
    } catch (e) {
      debugPrint('Error setting thumbnail: $e');
      _showSnackBar('Error setting thumbnail: $e');
    }
  }
  
  void _showSnackBar(String message, {bool isSuccess = false, bool isDelete = false}) {
    if (!_isContextValid()) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess 
            ? (isDelete ? Colors.redAccent : Colors.green)
            : null,
      ),
    );
  }
  
  bool _isContextValid() {
    try {
      return context.mounted;
    } catch (e) {
      return false;
    }
  }
}