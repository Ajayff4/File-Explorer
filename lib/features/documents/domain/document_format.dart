import 'package:path/path.dart' as p;

bool isPdfFile(String path) {
  return p.extension(path).toLowerCase() == '.pdf';
}

bool isEpubFile(String path) {
  return p.extension(path).toLowerCase() == '.epub';
}
