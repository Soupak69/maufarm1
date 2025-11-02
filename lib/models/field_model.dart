class Farm {
  final int? id;
  final String userId;
  final String ownerName;
  final String name;
  final String? address;
  final double latitude;
  final double longitude;
  final double? landSize;
  final String? landUnit;
  final List<String>? imageUrls;
  final DateTime? createdAt;

  Farm({
    this.id,
    required this.userId,
    required this.name,
    required this.ownerName,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.landSize,
    this.landUnit,
    this.imageUrls,
    this.createdAt,
  });

  factory Farm.fromJson(Map<String, dynamic> json) {
    return Farm(
      id: json['id'] as int?,
      userId: json['user_id'] as String,
      ownerName: json['owner_name'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      landSize: json['land_size'] != null
          ? (json['land_size'] as num).toDouble()
          : null,
      landUnit: json['land_unit'] as String?,
      imageUrls: json['image_urls'] != null
          ? List<String>.from(json['image_urls'] as List)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'owner_name': ownerName,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'land_size': landSize,
      'land_unit': landUnit,
      'image_urls': imageUrls,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  Farm copyWith({
    int? id,
    String? userId,
    String? ownerName,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    double? landSize,
    String? landUnit,
    List<String>? imageUrls,
    DateTime? createdAt,
  }) {
    return Farm(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      ownerName: ownerName ?? this.ownerName,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      landSize: landSize ?? this.landSize,
      landUnit: landUnit ?? this.landUnit,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}