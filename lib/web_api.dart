import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// Base URL of the rke-nextjs site, whose /api routes perform writes that
/// Firestore rules reserve for the Admin SDK (moderation queue, account deletion).
/// Override with --dart-define=RKE_API_BASE_URL=https://preview.roorkee.org.
const String webApiBaseUrl = String.fromEnvironment(
  'RKE_API_BASE_URL',
  defaultValue: 'https://www.roorkee.org',
);

class WebApiException implements Exception {
  final int statusCode;
  final String message;
  final String? code;

  WebApiException(this.statusCode, this.message, [this.code]);

  @override
  String toString() => message;
}

/// POSTs [body] to /api/[route] as the signed-in user.
/// Set [forceRefreshToken] when the server checks a recent sign-in time.
Future<void> postWebApi(
  String route,
  Map<String, dynamic> body, {
  bool forceRefreshToken = false,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw WebApiException(401, 'You need to be signed in.');
  }
  final idToken = await user.getIdToken(forceRefreshToken);

  final response = await http.post(
    Uri.parse('$webApiBaseUrl/api/$route'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $idToken',
    },
    body: jsonEncode(body),
  );

  if (response.statusCode >= 200 && response.statusCode < 300) return;

  String message = 'Request failed (${response.statusCode}).';
  String? code;
  try {
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    message = decoded['error'] as String? ?? message;
    code = decoded['code'] as String?;
  } catch (_) {}
  throw WebApiException(response.statusCode, message, code);
}
