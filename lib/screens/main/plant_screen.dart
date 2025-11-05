import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../widgets/app_bar.dart';
import '../../controller/plant_controller.dart';
import '../../screens/plants/plant_details.dart';

class PlantScreen extends StatefulWidget {
  const PlantScreen({super.key});

  @override
  State<PlantScreen> createState() => _PlantScreenState();
}

class _PlantScreenState extends State<PlantScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'A-Z';
  final Map<String, bool> _expandedFarms = {};
  late PlantController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PlantController(onUpdate: () {
      if (mounted) setState(() {});
    });
    _controller.loadData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // --- Filter + Search ---
    final filteredPlants = _controller.filterPlants(_searchController.text);
    
    // --- Auto-expand "Main" group when searching ---
    if (_searchController.text.isNotEmpty) {
      _expandedFarms['Main'] = true;
    }

    // --- Sorting Logic ---
    final sortedPlants = _controller.sortPlants(filteredPlants, _selectedFilter);
    final groupedPlants = _controller.groupPlantsByFarm(sortedPlants);

    // --- Sort groups by Quantity if selected ---
    List<MapEntry<String, List<Map<String, dynamic>>>> sortedGroups =
        groupedPlants.entries.toList();

    if (_selectedFilter == 'Quantity') {
      sortedGroups = _controller.sortGroupsByQuantity(groupedPlants);
    }

    return Scaffold(
      appBar: const CustomAppBar(),
      backgroundColor: theme.colorScheme.surface,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddPlantDialog,
        backgroundColor: Colors.green,
        elevation: 2,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Plant',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _controller.isLoadingPlants
          ? const Center(child: CircularProgressIndicator())
          : _controller.plants.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_florist,
                          size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'No plants yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the button below to add your first plant',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Search by plant name',
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 15,
                                  ),
                                  border: InputBorder.none,
                                  prefixIcon: const Icon(Icons.search,
                                      color: Colors.grey),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear,
                                              color: Colors.grey),
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() {});
                                          },
                                        )
                                      : null,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                    horizontal: 12,
                                  ),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _openFilterOptions(context),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.filter_list,
                                  color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _controller.loadData,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Column(
                              children: sortedGroups.map((entry) {
                                final farmName = entry.key;
                                final farmPlants = entry.value;
                                final isExpanded = _expandedFarms[farmName] ?? false;

                                return Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: theme.colorScheme.shadow
                                              .withOpacity(0.1),
                                          spreadRadius: 0.5,
                                          blurRadius: 1,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        InkWell(
                                          onTap: () {
                                            setState(() {
                                              _expandedFarms[farmName] = !isExpanded;
                                            });
                                          },
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                farmName,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: theme.colorScheme.onSurface,
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  if (_selectedFilter == 'Quantity')
                                                    Text(
                                                      '(${farmPlants.length})',
                                                      style: const TextStyle(
                                                        color: Colors.grey,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  Icon(
                                                    isExpanded
                                                        ? Icons
                                                            .keyboard_arrow_up_rounded
                                                        : Icons
                                                            .keyboard_arrow_down_rounded,
                                                    color: theme.colorScheme.onSurface,
                                                    size: 26,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isExpanded)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 12),
                                            child: SizedBox(
                                              height: 280,
                                              child: ListView.builder(
                                                scrollDirection: Axis.horizontal,
                                                itemCount: farmPlants.length,
                                                itemBuilder: (context, index) {
                                                  final plant = farmPlants[index];
                                                  return Container(
                                                    width: 170,
                                                    margin: const EdgeInsets.only(right: 12),
                                                    child: _buildPlantCard(context, plant),
                                                  );
                                                },
                                              ),
                                            ),
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
    );
  }

 Widget _buildPlantCard(BuildContext context, Map<String, dynamic> plant) {
  final theme = Theme.of(context);
  final fieldData = plant['fields'];
  final fieldName = fieldData != null && fieldData is Map 
      ? (fieldData['name']?.toString() ?? 'N/A') 
      : 'N/A';
  final quantity = plant['quantity']?.toString() ?? 'N/A';
  final plantingDay = plant['planting_day']?.toString() ?? 'N/A';
  
  return GestureDetector(
  onTap: () async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlantDetailsScreen(plant: plant),
      ),
    );

    if (result == true && mounted) {
      await _controller.loadData();
    }
  },
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              flex: 3,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  plant['image'] ?? '',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.local_florist,
                            size: 50, color: Colors.grey),
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                ),
              ),
            ),
            Flexible(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      'Name: ${plant['name'] ?? 'Unknown'}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Quantity: $quantity',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Field: $fieldName',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Planted: $plantingDay',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  void _openFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Wrap(
            children: [
              const Center(
                child: Text(
                  'Sort by',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(),
              _buildFilterOption('A-Z'),
              _buildFilterOption('Z-A'),
              _buildFilterOption('Date added'),
              _buildFilterOption('Quantity'),
              _buildFilterOption('Planted (Newest)'),
              _buildFilterOption('Planted (Oldest)'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(String label) {
    final isSelected = _selectedFilter == label;
    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.green : Colors.black87,
        ),
      ),
      trailing:
          isSelected ? const Icon(Icons.check, color: Colors.green) : null,
      onTap: () {
        setState(() => _selectedFilter = label);
        Navigator.pop(context);
      },
    );
  }

void _openAddPlantDialog() {
  final nameController = TextEditingController();
  final quantityController = TextEditingController();
  DateTime? plantingDate; 
  String? imagePath;
  String? selectedFieldId;
  bool isUploading = false;

  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final modalBackground = isDark ? Colors.grey[900] : Colors.white;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: modalBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Text(
                      'Add a New Plant',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                  child:GestureDetector(
                    onTap: isUploading
                        ? null
                        : () async {
                            final picker = ImagePicker();
                            final picked = await picker.pickImage(
                              source: ImageSource.gallery,
                            );
                            if (picked != null) {
                              setDialogState(() => imagePath = picked.path);
                            }
                          },
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.green,
                          backgroundImage: imagePath != null
                              ? FileImage(File(imagePath!))
                              : null,
                          child: imagePath == null
                              ? const Icon(Icons.add_a_photo, size: 30, color: Colors.white,)
                              : null,
                        ),
                        if (isUploading)
                          Positioned.fill(
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black26,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Plant Name*',
                      border: const OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color.fromARGB(255, 179, 240, 182),
                        ),
                      ),
                      floatingLabelStyle: TextStyle(
                        color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
                      ),
                      filled: true,
                      fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                    ),
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Quantity*',
                      border: const OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color.fromARGB(255, 179, 240, 182),
                        ),
                      ),
                      floatingLabelStyle: TextStyle(
                        color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
                      ),
                      filled: true,
                      fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                    ),
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                  const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: plantingDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setDialogState(() => plantingDate = picked);
                    }
                  },
                  child: AbsorbPointer(
                    child: TextField(
                      controller: TextEditingController(
                        text: plantingDate != null
                            ? "${plantingDate!.day}/${plantingDate!.month}/${plantingDate!.year}"
                            : '',
                      ),
                      decoration: InputDecoration(
                        labelText: 'Planting Day',
                        hintText: 'Select a date',
                        border: const OutlineInputBorder(),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Color.fromARGB(255, 179, 240, 182),
                          ),
                        ),
                        floatingLabelStyle: TextStyle(
                          color: theme.brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                      ),
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Field (optional)',
                      border: const OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color.fromARGB(255, 179, 240, 182),
                        ),
                      ),
                      floatingLabelStyle: TextStyle(
                        color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
                      ),
                      filled: true,
                      fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                    ),
                    value: selectedFieldId,
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('No field'),
                      ),
                      ..._controller.fields.map((field) {
                        return DropdownMenuItem<String>(
                          value: field['id'].toString(),
                          child: Text(field['name'] ?? 'Unnamed Field'),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setDialogState(() => selectedFieldId = value);
                    },
                    dropdownColor: modalBackground,
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: isUploading ? null : () => Navigator.pop(context),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        onPressed: isUploading
                            ? null
                            : () async {
                                if (nameController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please enter a plant name'),
                                    ),
                                  );
                                  return;
                                }

                                setDialogState(() => isUploading = true);

                                String? imageUrl;
                                if (imagePath != null) {
                                  try {
                                    imageUrl = await _controller.uploadImageToSupabase(imagePath!);
                                  } catch (e) {
                                    setDialogState(() => isUploading = false);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Failed to upload image: $e')),
                                      );
                                    }
                                    return;
                                  }
                                }

                                // Format planting date as text
                                String? plantingDayText;
                                if (plantingDate != null) {
                                  plantingDayText = "${plantingDate!.day}/${plantingDate!.month}/${plantingDate!.year}";
                                }

                                bool success = false;
                                try {
                                  success = await _controller.savePlantToDatabase(
                                    name: nameController.text,
                                    imageUrl: imageUrl ?? '',
                                    quantity: quantityController.text,
                                    fieldId: selectedFieldId,
                                    planting_day: plantingDayText,
                                  );
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Failed to save plant: $e')),
                                    );
                                  }
                                }

                                setDialogState(() => isUploading = false);
                                if (success && mounted) {
                                  Navigator.pop(context);
                                  await _controller.loadPlantsFromDatabase();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Plant added successfully!')),
                                  );
                                }
                              },
                        child: const Text(
                          'Save',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}
}