import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/auth_session_model.dart';

class AuthLocalDataSource {
  const AuthLocalDataSource(this._secureStorage);

  static const _sessionKey = 'auth_session';

  final FlutterSecureStorage _secureStorage;

  Future<void> saveSession(AuthSessionModel session) async {
    try {
      await _secureStorage.write(
        key: _sessionKey,
        value: jsonEncode(session.toJson()),
      );
    } on PlatformException catch (error) {
      throw AuthStorageException(error.message);
    }
  }

  Future<AuthSessionModel?> readSession() async {
    try {
      final value = await _secureStorage.read(key: _sessionKey);

      if (value == null) {
        return null;
      }

      final json = jsonDecode(value);

      if (json is! Map<String, dynamic>) {
        throw const FormatException('Invalid stored session.');
      }

      return AuthSessionModel.fromJson(json);
    } on PlatformException catch (error) {
      throw AuthStorageException(error.message);
    } on FormatException catch (error) {
      await clearSession();
      throw AuthStorageException(error.message);
    }
  }

  Future<void> clearSession() async {
    try {
      await _secureStorage.delete(key: _sessionKey);
    } on PlatformException catch (error) {
      throw AuthStorageException(error.message);
    }
  }
}

class AuthStorageException implements Exception {
  const AuthStorageException([this.message]);

  final String? message;
}
