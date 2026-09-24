import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  final Dio dio;
  final FlutterSecureStorage secureStorage;

  ApiClient({
    String baseUrl = 'https://opencaller.blackmatter.cc',
    Dio? customDio,
    FlutterSecureStorage? storage,
  })  : secureStorage = storage ?? const FlutterSecureStorage(),
        dio = customDio ??
            Dio(BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 8),
              headers: {'Content-Type': 'application/json'},
            )) {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await secureStorage.read(key: 'auth_token');
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  Future<Map<String, dynamic>> lookupNumber(String number) async {
    final response = await dio.get('/v1/lookup/$number');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> submitReport({
    required int e164Number,
    required String countryCode,
    required String category,
    String? callerName,
    String? comment,
  }) async {
    final response = await dio.post('/v1/report', data: {
      'e164_number': e164Number,
      'country_code': countryCode,
      'category': category,
      'caller_name': callerName,
      'comment': comment,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Response> getDelta({
    required String countryCode,
    DateTime? since,
    String? ifNoneMatch,
    int limit = 5000,
  }) async {
    final queryParams = <String, dynamic>{
      'country': countryCode,
      'limit': limit,
    };
    if (since != null) {
      queryParams['since'] = since.toIso8601String();
    }

    final headers = <String, dynamic>{};
    if (ifNoneMatch != null) {
      headers['If-None-Match'] = ifNoneMatch;
    }

    return dio.get(
      '/v1/sync/delta',
      queryParameters: queryParams,
      options: Options(
        headers: headers,
        validateStatus: (status) => status != null && (status == 200 || status == 304),
      ),
    );
  }

  Future<Map<String, dynamic>> contributeContacts({
    required List<Map<String, dynamic>> contacts,
    required bool userPrivacyConsent,
  }) async {
    final response = await dio.post('/v1/contacts/contribute', data: {
      'contacts': contacts,
      'user_privacy_consent': userPrivacyConsent,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> delistNumber({
    required int e164Number,
    String? reason,
  }) async {
    final response = await dio.post('/v1/privacy/delist', data: {
      'e164_number': e164Number,
      'reason': reason,
    });
    return response.data as Map<String, dynamic>;
  }
}
