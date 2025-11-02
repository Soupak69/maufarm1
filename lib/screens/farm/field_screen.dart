import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import '../../models/field_model.dart';
import '../../controller/field_controller.dart';

class AddFarmScreen extends StatefulWidget {
  final Farm? farmToEdit;

  const AddFarmScreen({super.key, this.farmToEdit});

  @override
  State<AddFarmScreen> createState() => _AddFarmScreenState();
}

class _AddFarmScreenState extends State<AddFarmScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _addressController = TextEditingController();
  
  late CameraPosition _initialPosition;
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  bool _isLoadingAddress = false;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    
    if (widget.farmToEdit != null) {
      _nameController.text = widget.farmToEdit!.name;
      _ownerNameController.text = widget.farmToEdit!.ownerName;
      _addressController.text = widget.farmToEdit!.address ?? '';
      _selectedLocation = LatLng(
        widget.farmToEdit!.latitude,
        widget.farmToEdit!.longitude,
      );
      _initialPosition = CameraPosition(
        target: _selectedLocation!,
        zoom: 14,
      );
      _addMarker(_selectedLocation!);
    } else {
      // Default to Mauritius center
      _initialPosition = const CameraPosition(
        target: LatLng(-20.24, 57.5522),
        zoom: 10,
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ownerNameController.dispose();
    _addressController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _addMarker(LatLng position) {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('farm_location'),
          position: position,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Farm Location'),
        ),
      };
    });
  }

  Future<void> _onMapTapped(LatLng position) async {
    setState(() {
      _selectedLocation = position;
      _isLoadingAddress = true;
    });
    
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
        
        setState(() {
          _addressController.text = address;
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingAddress = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not fetch address: $e')),
        );
      }
    }
  }

  Future<void> _searchAddress() async {
    final address = _addressController.text.trim();
    if (address.isEmpty) return;

    setState(() => _isLoadingAddress = true);

    try {
      List<Location> locations = await locationFromAddress(address);
      
      if (locations.isNotEmpty) {
        final location = locations.first;
        final position = LatLng(location.latitude, location.longitude);
        
        setState(() {
          _selectedLocation = position;
          _isLoadingAddress = false;
        });
        
        _addMarker(position);
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: position, zoom: 14),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoadingAddress = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not find address: $e')),
        );
      }
    }
  }

  Future<void> _saveFarm() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location on the map')),
      );
      return;
    }

    final farm = Farm(
      id: widget.farmToEdit?.id,
      userId: '',
      name: _nameController.text.trim(),
      ownerName: _ownerNameController.text.trim(),
      address: _addressController.text.trim().isEmpty 
          ? null 
          : _addressController.text.trim(),
      latitude: _selectedLocation!.latitude,
      longitude: _selectedLocation!.longitude,
    );

    final farmController = FarmController();
    final success = widget.farmToEdit != null
        ? await farmController.updateFarm(farm)
        : await farmController.addFarm(farm);

    if (mounted) {
      if (success) {
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${farmController.error}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.farmToEdit != null ? 'Edit Farm' : 'Add Field'),
        actions: [
          TextButton(
            onPressed: _saveFarm,
            child: Text(
              'Save',
              style: TextStyle(
                fontSize: 18,
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Field Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.agriculture),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a field name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _ownerNameController,
                      decoration: const InputDecoration(
                        labelText: 'Owner Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter the owner name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: 'Address(Manual or Map)',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.location_on),
                        suffixIcon: _isLoadingAddress
                            ? const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.search),
                                onPressed: _searchAddress,
                                tooltip: 'Search address',
                              ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter an address';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _searchAddress(),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tap on the map to select field location',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade300,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: GoogleMap(
                          initialCameraPosition: _initialPosition,
                          markers: _markers,
                          onMapCreated: (controller) => _mapController = controller,
                          onTap: _onMapTapped,
                          myLocationButtonEnabled: true,
                          myLocationEnabled: true,
                          zoomControlsEnabled: true,
                          mapToolbarEnabled: false,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}