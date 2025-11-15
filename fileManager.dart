import 'dart:io';

Future<List<String>> loadWordsFromFileAsync(String filePath) async {
  final file = File(filePath);
  // Asynchronously reads the file line by line.
  return await file.readAsLines();
}

//Write a string to a file asynchronously
Future<void> writeStringToFileAsync(String filePath, String content) async {
  final file = File(filePath);
  await file.writeAsString(content);
}

//Read a string from a file asynchronously
Future<String> readStringFromFileAsync(String filePath) async {
  final file = File(filePath);
  return await file.readAsString();
}