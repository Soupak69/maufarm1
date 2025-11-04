import 'package:flutter/material.dart';

class PlantDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> plant;

  const PlantDetailsScreen({super.key, required this.plant});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fieldData = plant['fields'];
    final fieldName = fieldData != null && fieldData is Map
        ? (fieldData['name']?.toString() ?? 'N/A')
        : 'N/A';
    final quantity = plant['quantity']?.toString() ?? 'N/A';
    final imageUrl = plant['image'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(plant['name'] ?? 'Plant Details'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Plant Image ---
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                height: 250,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  height: 250,
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(Icons.local_florist,
                        size: 80, color: Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- Plant Info ---
            Text(
              plant['name'] ?? 'Unknown Plant',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.nature, color: Colors.green),
                const SizedBox(width: 6),
                Text(
                  'Quantity: $quantity',
                  style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.terrain, color: Colors.green),
                const SizedBox(width: 6),
                Text(
                  'Field: $fieldName',
                  style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                ),
              ],
            ),

            const SizedBox(height: 30),
            // Optional extra details
          ],
        ),
      ),
    );
  }
}
