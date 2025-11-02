class Farm {
  final int? id;
  final String userId;
  final String ownerName;
  final String name;
  final String? address;
  final double latitude;
  final double longitude;
  final DateTime? createdAt;

  Farm({
    this.id,
    required this.userId,
    required this.name,
    required this.ownerName,
    required this.address,
    required this.latitude,
    required this.longitude,
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
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
