import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class OAuthService {
  static final OAuthService _instance = OAuthService._internal();

  static const String _googleServerClientId =
      '360832537424-4nc1qi1bca2udkbl284dikjg168mifrk.apps.googleusercontent.com';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: _googleServerClientId,
  );

  OAuthService._internal();

  factory OAuthService() {
    return _instance;
  }

  /// Sign in with Google
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null; // User cancelled
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('Failed to get ID token from Google');
      }

      // Send token to backend
      return await _handleOAuthToken(
        provider: 'google',
        idToken: idToken,
        email: googleUser.email,
      );
    } catch (e) {
      print('Google Sign-In error: $e');
      throw Exception(e.toString());
    }
  }

  /// Handle OAuth token exchange with backend
  Future<Map<String, dynamic>?> _handleOAuthToken({
    required String provider,
    required String idToken,
    required String? email,
    String? fullName,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/users/oauth-signin/');

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'provider': provider,
              'id_token': idToken,
              'email': email,
              'full_name': fullName,
            }),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        return decoded;
      } else {
        final error = _extractBackendError(response.body);
        throw Exception(error);
      }
    } catch (e) {
      print('OAuth token handler error: $e');
      throw Exception('OAuth token handler error: $e');
    }
  }

  /// Sign out from Google
  Future<void> signOutGoogle() async {
    await _googleSignIn.signOut();
  }

  String _extractBackendError(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is String && decoded.trim().isNotEmpty) {
        return decoded;
      }
      if (decoded is Map<String, dynamic>) {
        final detail = decoded['detail'];
        if (detail is String && detail.trim().isNotEmpty) {
          return detail;
        }
      }
    } catch (_) {
      // Fallback
    }
    return 'OAuth sign-in failed. Please try again.';
  }
}
