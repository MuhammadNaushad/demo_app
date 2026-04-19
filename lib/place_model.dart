// ── PlaceImage ─────────────────────────────────────────────────────────────

class PlaceImage {
  final int id;
  final String url;
  final int imageableId;
  final String imageableType;
  final String? createdAt;
  final String? updatedAt;

  const PlaceImage({
    required this.id,
    required this.url,
    required this.imageableId,
    required this.imageableType,
    this.createdAt,
    this.updatedAt,
  });

  factory PlaceImage.fromJson(Map<String, dynamic> json) => PlaceImage(
    id: json['id'] as int,
    url: json['url'] as String,
    imageableId: 1,
    imageableType: '',
    createdAt: json['created_at'] as String?,
    updatedAt: json['updated_at'] as String?,
  );
}

// ── Place ──────────────────────────────────────────────────────────────────

class Place {
  final int id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final String? imageUrl;
  final String state;
  final String city;
  final String country;
  final String? createdAt;
  final String? updatedAt;
  final List<PlaceImage> images;

  const Place({
    required this.id,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
    required this.state,
    required this.city,
    required this.country,
    this.createdAt,
    this.updatedAt,
    this.images = const [],
  });

  factory Place.fromJson(Map<String, dynamic> json) => Place(
    id: json['id'] as int,
    name: json['name'] as String,
    description: json['description'] as String? ?? '',
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    imageUrl: json['image_url'] as String?,
    state: json['state'] as String? ?? '',
    city: json['city'] as String? ?? '',
    country: json['country'] as String? ?? '',
    createdAt: json['created_at'] as String?,
    updatedAt: json['updated_at'] as String?,
    images: (json['images'] as List<dynamic>? ?? [])
        .map((e) => PlaceImage.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'latitude': latitude,
    'longitude': longitude,
    'image_url': imageUrl,
    'state': state,
    'city': city,
    'country': country,
  };

  Place copyWith({
    int? id,
    String? name,
    String? description,
    double? latitude,
    double? longitude,
    String? imageUrl,
    String? state,
    String? city,
    String? country,
    String? createdAt,
    String? updatedAt,
    List<PlaceImage>? images,
  }) => Place(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    imageUrl: imageUrl ?? this.imageUrl,
    state: state ?? this.state,
    city: city ?? this.city,
    country: country ?? this.country,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    images: images ?? this.images,
  );
}
