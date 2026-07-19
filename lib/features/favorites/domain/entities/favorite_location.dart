class FavoriteLocation {
  const FavoriteLocation({
    required this.path,
    required this.label,
    required this.createdAt,
    required this.updatedAt,
  });

  final String path;
  final String label;
  final DateTime createdAt;
  final DateTime updatedAt;

  FavoriteLocation copyWith({
    String? label,
    DateTime? updatedAt,
  }) {
    return FavoriteLocation(
      path: path,
      label: label ?? this.label,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
