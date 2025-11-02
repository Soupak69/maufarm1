import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '../../models/field_model.dart';
import '../../controller/field_controller.dart';

class AddFarmViewModel extends ChangeNotifier {
  // Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ownerNameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController landSizeController = TextEditingController();

  // Map properties
  GoogleMapController? mapController;
  LatLng? selectedLocation;
  Set<Marker> markers = {};
  late CameraPosition initialPosition;

  // Loading states
  bool isLoadingAddress = false;
  bool isUploadingImages = false;

  // Image properties
  final ImagePicker _picker = ImagePicker();
  List<File> selectedImages = [];
  List<String> existingImageUrls = [];

  // Unit properties
  String selectedUnit = 'Hectare';
  final Map<String, double> conversionRates = {
    'Hectare': 10000.0,
    'Arpent': 4221.0,
    'Perche': 42.21,
    'Toise': 3.80,
    'Square Meters': 1.0,
    'Square Feet': 0.092903,
  };

  // Farm to edit
  Farm? _farmToEdit;
  Farm? get farmToEdit => _farmToEdit;

  // Constructor
  AddFarmViewModel({Farm? farmToEdit}) {
    _farmToEdit = farmToEdit;
    _initialize();
  }

  void _initialize() {
    if (_farmToEdit != null) {
      nameController.text = _farmToEdit!.name;
      ownerNameController.text = _farmToEdit!.ownerName;
      addressController.text = _farmToEdit!.address ?? '';
      landSizeController.text = _farmToEdit!.landSize?.toStringAsFixed(2) ?? '';
      
      existingImageUrls = List<String>.from(_farmToEdit!.imageUrls ?? []);

      selectedLocation = LatLng(
        _farmToEdit!.latitude,
        _farmToEdit!.longitude,
      );

      initialPosition = CameraPosition(
        target: selectedLocation!,
        zoom: 14,
      );

      _addMarker(selectedLocation!);
    } else {
      initialPosition = const CameraPosition(
        target: LatLng(-20.24, 57.5522),
        zoom: 10,
      );
    }
  }

  // Map methods
  void _addMarker(LatLng position) {
    markers = {
      Marker(
        markerId: const MarkerId('farm_location'),
        position: position,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Farm Location'),
      ),
    };
    notifyListeners();
  }

  Future<String?> onMapTapped(LatLng position) async {
    selectedLocation = position;
    isLoadingAddress = true;
    notifyListeners();

    _addMarker(position);

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final address = [
          place.street,
          place.locality,
          place.administrativeArea,
          place.country,
        ].where((e) => e != null && e.isNotEmpty).join(', ');

        addressController.text = address;
        isLoadingAddress = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      isLoadingAddress = false;
      notifyListeners();
      return 'Could not fetch address: $e';
    }
    
    isLoadingAddress = false;
    notifyListeners();
    return null;
  }

  Future<String?> searchAddress() async {
    final address = addressController.text.trim();
    if (address.isEmpty) return 'Please enter an address';

    isLoadingAddress = true;
    notifyListeners();

    try {
      List<Location> locations = await locationFromAddress(address);

      if (locations.isNotEmpty) {
        final location = locations.first;
        final position = LatLng(location.latitude, location.longitude);

        selectedLocation = position;
        isLoadingAddress = false;
        notifyListeners();

        _addMarker(position);
        mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: position, zoom: 14),
          ),
        );
        return null;
      }
    } catch (e) {
      isLoadingAddress = false;
      notifyListeners();
      return 'Could not find address: $e';
    }
    
    isLoadingAddress = false;
    notifyListeners();
    return 'Could not find address';
  }

  // Image methods
  Future<String?> pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 80,
      );
      
      if (images.isNotEmpty) {
        selectedImages.addAll(images.map((xfile) => File(xfile.path)));
        notifyListeners();
      }
      return null;
    } catch (e) {
      return 'Error picking images: $e';
    }
  }

  Future<String?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      
      if (image != null) {
        selectedImages.add(File(image.path));
        notifyListeners();
      }
      return null;
    } catch (e) {
      return 'Error taking photo: $e';
    }
  }

  void removeImage(int index) {
    selectedImages.removeAt(index);
    notifyListeners();
  }

  void removeExistingImage(int index) {
    existingImageUrls.removeAt(index);
    notifyListeners();
  }

  Future<List<String>> _uploadImages() async {
    if (selectedImages.isEmpty) return [];

    isUploadingImages = true;
    notifyListeners();

    final supabase = Supabase.instance.client;
    List<String> uploadedUrls = [];

    try {
      for (var i = 0; i < selectedImages.length; i++) {
        final file = selectedImages[i];
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final filePath = 'fields/$fileName';

        await supabase.storage.from('field_images').upload(
          filePath,
          file,
          fileOptions: const FileOptions(
            cacheControl: '3600',
            upsert: false,
          ),
        );

        final url = supabase.storage.from('field_images').getPublicUrl(filePath);
        uploadedUrls.add(url);
      }
    } catch (e) {
      isUploadingImages = false;
      notifyListeners();
      rethrow;
    }

    isUploadingImages = false;
    notifyListeners();
    return uploadedUrls;
  }

  // Unit conversion methods
  double _convertToHectares(double value, String fromUnit) {
    final m2 = value * conversionRates[fromUnit]!;
    return m2 / 10000.0;
  }

  Map<String, double> getConvertedValues(double hectareValue) {
    final m2 = hectareValue * 10000;
    return {
      'Hectare': hectareValue,
      'Arpent': m2 / 4221,
      'Perche': m2 / 42.21,
      'Toise': m2 / 3.80,
      'Square Meters': m2,
      'Square Feet': m2 / 0.092903,
    };
  }

  String getUnitSymbol(String unit) {
    switch (unit) {
      case 'Hectare':
        return 'Ha';
      case 'Arpent':
        return 'Arpent';
      case 'Perche':
        return 'Perche';
      case 'Toise':
        return 'Toise';
      case 'Square Meters':
        return 'm²';
      case 'Square Feet':
        return 'ft²';
      default:
        return '';
    }
  }

  void updateSelectedUnit(String unit) {
    selectedUnit = unit;
    notifyListeners();
  }

  // Validation
  String? validateFieldName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a field name';
    }
    return null;
  }

  String? validateOwnerName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter the owner name';
    }
    return null;
  }

  String? validateLandSize(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter land size';
    }
    final parsed = double.tryParse(value);
    if (parsed == null || parsed <= 0) {
      return 'Enter a valid number';
    }
    return null;
  }

  String? validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter an address';
    }
    return null;
  }

  // Save farm
  Future<SaveFarmResult> saveFarm() async {
    if (selectedLocation == null) {
      return SaveFarmResult(
        success: false,
        message: 'Please select a location on the map',
      );
    }

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      return SaveFarmResult(
        success: false,
        message: 'User not logged in. Please sign in again.',
      );
    }

    try {
      // Upload new images
      final newImageUrls = await _uploadImages();

      // Combine existing and new image URLs
      final allImageUrls = [...existingImageUrls, ...newImageUrls];

      final rawValue = double.tryParse(landSizeController.text.trim());
      final hectareValue = rawValue != null
          ? _convertToHectares(rawValue, selectedUnit)
          : null;

      final farm = Farm(
        id: _farmToEdit?.id,
        userId: user.id,
        name: nameController.text.trim(),
        ownerName: ownerNameController.text.trim(),
        address: addressController.text.trim().isEmpty
            ? null
            : addressController.text.trim(),
        latitude: selectedLocation!.latitude,
        longitude: selectedLocation!.longitude,
        landSize: hectareValue,
        landUnit: selectedUnit,
        imageUrls: allImageUrls.isEmpty ? null : allImageUrls,
      );

      final farmController = FarmController();
      final success = _farmToEdit != null
          ? await farmController.updateFarm(farm)
          : await farmController.addFarm(farm);

      if (success) {
        return SaveFarmResult(success: true);
      } else {
        return SaveFarmResult(
          success: false,
          message: farmController.error ?? 'Unknown error occurred',
        );
      }
    } catch (e) {
      return SaveFarmResult(
        success: false,
        message: 'Error uploading images: $e',
      );
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    ownerNameController.dispose();
    addressController.dispose();
    landSizeController.dispose();
    mapController?.dispose();
    super.dispose();
  }
}

class SaveFarmResult {
  final bool success;
  final String? message;

  SaveFarmResult({required this.success, this.message});
}