class Plant {
  final int id;
  final String name;
  final int plantNumber;
  final List<String> photos;
  final int photoCount;
  final String? lastPhotoDate;
  final String? nextPhotoDate;
  final double? latitude;
  final double? longitude;

  Plant({
    required this.id,
    required this.name,
    required this.plantNumber,
    required this.photos,
    required this.photoCount,
    this.lastPhotoDate,
    this.nextPhotoDate,
    this.latitude,
    this.longitude,
  });

  factory Plant.fromJson(Map<String, dynamic> json) {
    return Plant(
      id: json['id'] as int,
      name: json['name'] as String,
      plantNumber: json['plantNumber'] as int,
      photos: List<String>.from(json['photos'] ?? []),
      photoCount: json['photoCount'] as int? ?? 0,
      lastPhotoDate: json['lastPhotoDate'] as String?,
      nextPhotoDate: json['nextPhotoDate'] as String?,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
    );
  }
}
