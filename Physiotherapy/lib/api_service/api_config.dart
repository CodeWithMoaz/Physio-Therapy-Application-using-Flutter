import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static bool isApiKeyConfigured() {
    return dotenv.env['API_KEY'] != null && dotenv.env['API_KEY']!.isNotEmpty;
  }

  static String getApiKey() {
    if (!isApiKeyConfigured()) {
      throw Exception("API key is not configured in .env file");
    }
    return dotenv.env['API_KEY']!;
  }

  static Future<bool> validateOpenRouterApiKey() async {
    if (!isApiKeyConfigured()) {
      return false;
    }

    return true;
  }
}
