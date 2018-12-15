import 'dart:io';
import 'package:path/path.dart' as path;

List<String> getCsvLines(String fileName) {
  return new File(fileName)
      .readAsLinesSync()
      .where((x) => !x.isEmpty && !x.startsWith('#'))
      .map((x) => x.trim())
      .toList();
}

// Requires test csv files in a test_data directory under open location code project root.
String testDataPath() {
  Directory projectRoot = Directory.current.parent;

  return path.absolute(projectRoot.path, 'test_data');
}

String cvsWithAbsolutePath(String file) => path.absolute(testDataPath(), file);

List<String> csvLinesFromFile(String file) =>
    getCsvLines(cvsWithAbsolutePath(file));
