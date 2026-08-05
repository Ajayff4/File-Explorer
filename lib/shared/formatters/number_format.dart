String formatCount(int count) {
  final str = count.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < str.length; i++) {
    if (i > 0 && (str.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(str[i]);
  }
  return buffer.toString();
}

String formatItemCount(int count) {
  return count == 1 ? '1 item' : '${formatCount(count)} items';
}
