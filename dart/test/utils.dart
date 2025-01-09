import 'dart:io';
import 'package:path/path.dart' as path;

List<String> getCsvLines(String fileName) {
  return File(fileName)
      .readAsLinesSync()
      .where((x) => x.isNotEmpty && !x.startsWith('#'))
      .map((x) => x.trim())
      .toList();
}

// Requires test csv files in a test_data directory under Open Location Code project root.
String testDataPath() {
  var projectRoot = Directory.current.parent;

  return path.absolute(projectRoot.path, 'test_data');
}

String cvsWithAbsolutePath(String file) => path.absolute(testDataPath(), file);

List<String> csvLinesFromFile(String file) =>
    getCsvLines(cvsWithAbsolutePath(file));
