import 'dart:io';

Future<List<String>> loadWordsFromFileAsync(String filePath) async {
  final file = File(filePath);
  // Asynchronously reads the file line by line.
  return await file.readAsLines();
}