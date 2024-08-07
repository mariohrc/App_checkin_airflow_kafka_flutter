import 'package:dio/dio.dart';

class ApiService {
  final String baseUrl;
  final Dio _dio;

  ApiService(this.baseUrl) : _dio = Dio();

  Future<bool> checkCodeExists(String qrcode, String readerName) async {
    try {
      final response = await _dio.get(
        '$baseUrl/api/check-code/',
        queryParameters: {
          'qrcode': qrcode,
          'reader_name': readerName,
        },
      );
      return response.statusCode == 201; // Check for 201 Created
    } catch (e) {
      print('Error checking code: $e');
      return false;
    }
  }
}
