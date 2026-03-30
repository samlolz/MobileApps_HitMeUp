import 'package:flutter/foundation.dart';

class ApiConfig {
  ApiConfig._();

  static String get baseUrl {
    const overrideUrl = String.fromEnvironment('SIGNUP_API_BASE_URL');
    if (overrideUrl.isNotEmpty) {
      return overrideUrl;
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }

    return 'http://127.0.0.1:8000';
  }
}
