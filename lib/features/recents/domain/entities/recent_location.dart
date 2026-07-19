class RecentLocation {
  const RecentLocation({
    required this.path,
    required this.label,
    required this.openedAt,
    this.openCount = 1,
    this.isFolder = true,
  });

  final String path;
  final String label;
  final DateTime openedAt;
  final int openCount;
  final bool isFolder;

  RecentLocation copyWith({
    String? label,
    DateTime? openedAt,
    int? openCount,
    bool? isFolder,
  }) {
    return RecentLocation(
      path: path,
      label: label ?? this.label,
      openedAt: openedAt ?? this.openedAt,
      openCount: openCount ?? this.openCount,
      isFolder: isFolder ?? this.isFolder,
    );
  }
}
