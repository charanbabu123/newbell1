import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String ACCESS_TOKEN_KEY = 'access_token';
  static const String REFRESH_TOKEN_KEY = 'refresh_token';
  static const String PHONE_NUMBER_KEY = 'phone_number';

  static Future<void> saveAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ACCESS_TOKEN_KEY, token);
  }

  static Future<void> saveRefreshToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(REFRESH_TOKEN_KEY, token);
  }

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(ACCESS_TOKEN_KEY, accessToken),
      prefs.setString(REFRESH_TOKEN_KEY, refreshToken),
    ]);
  }

  static Future<void> savePhoneNumber(String phoneNumber) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PHONE_NUMBER_KEY, phoneNumber);
  }

  static Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(ACCESS_TOKEN_KEY);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(REFRESH_TOKEN_KEY);
  }

  static Future<String?> getPhoneNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(PHONE_NUMBER_KEY);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(ACCESS_TOKEN_KEY),
      prefs.remove(REFRESH_TOKEN_KEY),
      prefs.remove(PHONE_NUMBER_KEY),
    ]);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getAuthToken();
    return token != null;
  }
}
