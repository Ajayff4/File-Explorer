import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

Widget localImageForPath({
  required String path,
  BoxFit fit = BoxFit.contain,
  double? width,
  double? height,
  required ImageErrorWidgetBuilder errorBuilder,
}) {
  return Image.file(
    File(path),
    fit: fit,
    width: width,
    height: height,
    errorBuilder: errorBuilder,
  );
}

VideoPlayerController? localMediaControllerForPath(String path) {
  return VideoPlayerController.file(
    File(path),
    videoPlayerOptions: VideoPlayerOptions(
      allowBackgroundPlayback: true,
    ),
  );
}
