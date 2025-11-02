import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../models/field_model.dart';
import '../../models/add_farm_viewmodel.dart';

class AddFarmScreen extends StatelessWidget {
  final Farm? farmToEdit;

  const AddFarmScreen({super.key, this.farmToEdit});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AddFarmViewModel(farmToEdit: farmToEdit),
      child: const _AddFarmScreenContent(),
    );
  }
}

class _AddFarmScreenContent extends StatefulWidget {
  const _AddFarmScreenContent();

  @override
  State<_AddFarmScreenContent> createState() => _AddFarmScreenContentState();
}

class _AddFarmScreenContentState extends State<_AddFarmScreenContent> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AddFarmViewModel>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(viewModel.farmToEdit != null ? 'Edit Field' : 'Add Field'),
        actions: [
          TextButton(
            onPressed:
                viewModel.isUploadingImages ? null : () => _saveFarm(context),
            child: viewModel.isUploadingImages
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
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
        child: Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildFieldNameInput(viewModel),
                const SizedBox(height: 16),
                _buildOwnerNameInput(viewModel),
                const SizedBox(height: 16),
                _buildLandSizeSection(viewModel),
                const SizedBox(height: 16),
                _buildAddressInput(viewModel),
                const SizedBox(height: 16),
                _buildMapSection(viewModel, theme),
                const SizedBox(height: 24),
                _buildImagesSection(viewModel),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldNameInput(AddFarmViewModel viewModel) {
    return TextFormField(
      controller: viewModel.nameController,
      decoration: const InputDecoration(
        labelText: 'Field Name',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.agriculture),
      ),
      validator: viewModel.validateFieldName,
    );
  }

  Widget _buildOwnerNameInput(AddFarmViewModel viewModel) {
    return TextFormField(
      controller: viewModel.ownerNameController,
      decoration: const InputDecoration(
        labelText: 'Owner Name',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.person),
      ),
      validator: viewModel.validateOwnerName,
    );
  }

  Widget _buildLandSizeSection(AddFarmViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Land Size',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Flexible(
              flex: 2,
              child: TextFormField(
                controller: viewModel.landSizeController,
                decoration: const InputDecoration(
                  labelText: 'Enter size',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.landscape),
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: viewModel.validateLandSize,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              flex: 2,
              child: DropdownButtonFormField<String>(
                value: viewModel.selectedUnit,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Unit',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                ),
                items: viewModel.conversionRates.keys.map((unit) {
                  return DropdownMenuItem(
                    value: unit,
                    child: Text(unit, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) viewModel.updateSelectedUnit(value);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAddressInput(AddFarmViewModel viewModel) {
    return TextFormField(
      controller: viewModel.addressController,
      decoration: InputDecoration(
        labelText: 'Address (Manual or Map)',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.location_on),
        suffixIcon: viewModel.isLoadingAddress
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
                onPressed: () => _searchAddress(viewModel),
                tooltip: 'Search address',
              ),
      ),
      validator: viewModel.validateAddress,
      onFieldSubmitted: (_) => _searchAddress(viewModel),
    );
  }

  Widget _buildMapSection(AddFarmViewModel viewModel, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tap on the map to select field location',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 250,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: GoogleMap(
              initialCameraPosition: viewModel.initialPosition,
              markers: viewModel.markers,
              onMapCreated: (controller) => viewModel.mapController = controller,
              onTap: (position) async {
                final error = await viewModel.onMapTapped(position);
                if (error != null && mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(error)));
                }
              },
              myLocationButtonEnabled: true,
              myLocationEnabled: true,
              zoomControlsEnabled: true,
              mapToolbarEnabled: false,
              gestureRecognizers: <
                  Factory<OneSequenceGestureRecognizer>>{
                Factory<PanGestureRecognizer>(() => PanGestureRecognizer()),
                Factory<VerticalDragGestureRecognizer>(
                    () => VerticalDragGestureRecognizer()),
                Factory<HorizontalDragGestureRecognizer>(
                    () => HorizontalDragGestureRecognizer()),
                Factory<ScaleGestureRecognizer>(
                    () => ScaleGestureRecognizer()),
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagesSection(AddFarmViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Field Images',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: () => _showImageSourceDialog(context, viewModel),
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Add Images'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (viewModel.existingImageUrls.isNotEmpty) ...[
          const Text(
            'Existing Images:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          _buildImageGrid(
            viewModel.existingImageUrls,
            isNetworkImage: true,
            onRemove: viewModel.removeExistingImage,
          ),
          const SizedBox(height: 16),
        ],
        if (viewModel.selectedImages.isNotEmpty) ...[
          const Text(
            'New Images to Upload:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          _buildImageGrid(
            viewModel.selectedImages,
            isNetworkImage: false,
            onRemove: viewModel.removeImage,
          ),
        ],
        if (viewModel.selectedImages.isEmpty &&
            viewModel.existingImageUrls.isEmpty)
          _buildEmptyImageState(),
      ],
    );
  }

  Widget _buildImageGrid(
    List<dynamic> images, {
    required bool isNetworkImage,
    required Function(int) onRemove,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        return Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: isNetworkImage
                  ? Image.network(
                      images[index] as String,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                            child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.error),
                      ),
                    )
                  : Image.file(
                      images[index],
                      fit: BoxFit.cover,
                    ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => onRemove(index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close,
                      color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyImageState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.image_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text('No images added yet',
              style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  void _showImageSourceDialog(BuildContext context, AddFarmViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final error = await viewModel.pickImages();
                if (error != null && mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(error)));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () async {
                Navigator.pop(context);
                final error = await viewModel.pickImageFromCamera();
                if (error != null && mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(error)));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _searchAddress(AddFarmViewModel viewModel) async {
    final error = await viewModel.searchAddress();
    if (error != null && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _saveFarm(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final viewModel = context.read<AddFarmViewModel>();
    final result = await viewModel.saveFarm();

    if (mounted) {
      if (result.success) {
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(result.message ?? 'Unknown error')));
      }
    }
  }
}
