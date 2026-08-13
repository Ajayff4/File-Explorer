import 'package:file_explorer/features/downloader/domain/entities/download_task.dart';
import 'package:flutter/material.dart';

IconData iconForDownloadMediaType(DownloadMediaType type) {
  return switch (type) {
    DownloadMediaType.video => Icons.movie_outlined,
    DownloadMediaType.audio => Icons.music_note_outlined,
  };
}

Color colorForDownloadStatus(
  BuildContext context,
  DownloadTaskStatus status,
) {
  final scheme = Theme.of(context).colorScheme;
  return switch (status) {
    DownloadTaskStatus.failed => const Color(0xFFE53935),
    DownloadTaskStatus.completed => const Color(0xFF43A047),
    DownloadTaskStatus.cancelled => scheme.outline,
    DownloadTaskStatus.running => scheme.primary,
    DownloadTaskStatus.queued => const Color(0xFFFF9800),
    DownloadTaskStatus.paused => const Color(0xFFFB8C00),
  };
}

IconData iconForDownloadStatus(DownloadTaskStatus status) {
  return switch (status) {
    DownloadTaskStatus.running => Icons.download_rounded,
    DownloadTaskStatus.queued => Icons.hourglass_top_rounded,
    DownloadTaskStatus.completed => Icons.check_circle_rounded,
    DownloadTaskStatus.failed => Icons.error_rounded,
    DownloadTaskStatus.cancelled => Icons.cancel_rounded,
    DownloadTaskStatus.paused => Icons.pause_circle_rounded,
  };
}

String formatTransferSpeed(double bytesPerSecond) {
  final value = bytesPerSecond.clamp(0, double.infinity);
  if (value >= 1024 * 1024) {
    return '${(value / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }
  if (value >= 1024) {
    return '${(value / 1024).toStringAsFixed(1)} KB/s';
  }
  return '${value.toStringAsFixed(0)} B/s';
}

String formatDownloadTimestamp(DateTime timestamp) {
  final local = timestamp.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(local.year, local.month, local.day);
  final diff = today.difference(day).inDays;

  final time = '${_two(local.hour)}:${_two(local.minute)}';
  if (diff == 0) {
    return 'Today at $time';
  }
  if (diff == 1) {
    return 'Yesterday at $time';
  }
  return '${_two(local.day)} ${_month(local.month)} $time';
}

String _month(int month) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return months[month - 1];
}

String _two(int value) => value.toString().padLeft(2, '0');