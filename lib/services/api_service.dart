import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  static Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      return jsonDecode(response.body);
    } catch (e) {
      print('API Error: $e');
      rethrow;
    }
  }

  static Future<dynamic> get(String endpoint) async {
    try {
      final response = await http.get(Uri.parse(endpoint));
      return jsonDecode(response.body);
    } catch (e) {
      print('API Error: $e');
      rethrow;
    }
  }

  static Future<dynamic> multipartPost(
    String endpoint,
    Map<String, String> fields,
    Map<String, File> files,
    Map<String, String>? headers,
  ) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(endpoint));
      
      // Add text fields
      request.fields.addAll(fields);
      
      // Add files
      for (var entry in files.entries) {
        var file = entry.value;
        var stream = http.ByteStream(file.openRead());
        var length = await file.length();
        
        var multipartFile = http.MultipartFile(
          entry.key,
          stream,
          length,
          filename: file.path.split('/').last,
        );
        
        request.files.add(multipartFile);
      }
      
      // Add headers if provided
      if (headers != null) {
        request.headers.addAll(headers);
      }
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      return jsonDecode(response.body);
    } catch (e) {
      print('API Error: $e');
      rethrow;
    }
  }
}
