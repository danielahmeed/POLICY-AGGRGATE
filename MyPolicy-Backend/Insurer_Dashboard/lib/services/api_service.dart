import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ApiService {
  // Data Pipeline Service (direct) for insurer file uploads
  // Change this to your deployed URL in production
  static const String _dataPipelineBaseUrl = 'http://localhost:8082';

  // BFF Service for orchestrated API calls
  static const String _bffBaseUrl = 'http://localhost:8090';

  /// Maps UI dropdown labels to backend collection names
  static String mapDataTypeToCollection(String dataType) {
    switch (dataType) {
      case 'Life Insurance':
        return 'life_insurance';
      case 'Health Insurance':
        return 'health_insurance';
      case 'Motor Insurance':
        return 'auto_insurance';
      default:
        return 'auto_insurance';
    }
  }

  /// Upload CSV file to Data Pipeline → triggers ingestion + stitching + policy sync
  /// Endpoint: POST /api/pipeline/upload (multipart)
  static Future<Map<String, dynamic>> uploadCsvFile({
    required String dataType,
    required String fileName,
    required Uint8List fileBytes,
  }) async {
    final collectionName = mapDataTypeToCollection(dataType);
    final uri = Uri.parse('$_dataPipelineBaseUrl/api/pipeline/upload');

    final request = http.MultipartRequest('POST', uri)
      ..fields['collectionName'] = collectionName
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
      ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(
          'Upload failed (${response.statusCode}): ${response.body}');
    }
  }

  /// Trigger full pipeline run (all CSVs already loaded in MongoDB)
  /// Endpoint: POST /api/pipeline/run
  static Future<Map<String, dynamic>> runFullPipeline() async {
    final uri = Uri.parse('$_dataPipelineBaseUrl/api/pipeline/run');
    final response = await http.post(uri);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(
          'Pipeline run failed (${response.statusCode}): ${response.body}');
    }
  }
}
