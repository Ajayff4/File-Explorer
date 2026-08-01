import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

Widget localImageForPath({
  required String path,
  BoxFit fit = BoxFit.contain,
  double? width,
  double? height,
  required ImageErrorWidgetBuilder errorBuilder,
}) {
  return const _UnsupportedLocalMedia();
}

VideoPlayerController? localMediaControllerForPath(String path) {
  return null;
}

class _UnsupportedLocalMedia extends StatelessWidget {
  const _UnsupportedLocalMedia();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Local media preview is unavailable'));
  }
}
