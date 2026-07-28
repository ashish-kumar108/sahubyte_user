import 'dart:convert';

import 'package:http/http.dart' as http;

import '../exception/api_exceptions.dart';
import 'api_service.dart';

class NetworkApiService extends BaseApiService {
  static const _getTimeout = Duration(seconds: 15);
  static const _postTimeout = Duration(seconds: 30);
  static const _formPostTimeout = Duration(seconds: 45);

  final Map<String, String> _jsonHeaders = {"Content-Type": "application/json"};
  final Map<String, String> _formHeaders = {
    "Content-Type": "application/x-www-form-urlencoded",
  };

  @override
  Future<dynamic> getGetApiRequest(String url) async {
    try {
      final response = await http
          .get(Uri.parse(url), headers: _jsonHeaders)
          .timeout(_getTimeout);

      return returnResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw FetchDataException(e.toString());
    }
  }

  @override
  Future<dynamic> getPostApiRequest(String url, dynamic data) async {
    try {
      final response = await http
          .post(Uri.parse(url), headers: _jsonHeaders, body: jsonEncode(data))
          .timeout(_postTimeout);

      return returnResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw FetchDataException(e.toString());
    }
  }

  @override
  Future<dynamic> getPostFormApiRequest(
    String url,
    Map<String, String> data,
  ) async {
    try {
      final response = await http
          .post(Uri.parse(url), headers: _formHeaders, body: data)
          .timeout(_formPostTimeout);

      return returnResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw FetchDataException(e.toString());
    }
  }

  dynamic returnResponse(http.Response response) {
    final decodedBody = response.body.isEmpty
        ? null
        : jsonDecode(response.body);

    switch (response.statusCode) {
      case 200:
      case 201:
        return decodedBody;

      case 400:
        throw BadRequestException(decodedBody?['message'] ?? 'Bad request');

      case 401:
      case 403:
        throw UnauthorisedException("Unauthorized request");

      case 500:
        throw ApiInternalException("Server error");

      default:
        throw FetchDataException("Error: ${response.statusCode}");
    }
  }
}
