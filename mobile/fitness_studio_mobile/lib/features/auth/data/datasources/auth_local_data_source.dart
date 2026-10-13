import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/auth_session_model.dart';
import '../models/account_session_model.dart';

class AuthLocalDataSource {
  const AuthLocalDataSource(this._secureStorage);

  static const _sessionKey = 'auth_session';
  static const _accountSessionKey = 'account_session';
  static const _lastStudioIdKey = 'last_studio_id';

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
      await _secureStorage.delete(key: _accountSessionKey);
    } on PlatformException catch (error) {
      throw AuthStorageException(error.message);
    }
  }

  Future<void> saveAccountSession(AccountSessionModel session) async {
    try {
      await _secureStorage.delete(key: _sessionKey);
      await _secureStorage.write(
        key: _accountSessionKey,
        value: jsonEncode(session.toJson()),
      );
    } on PlatformException catch (error) {
      throw AuthStorageException(error.message);
    }
  }

  Future<AccountSessionModel?> readAccountSession() async {
    try {
      final value = await _secureStorage.read(key: _accountSessionKey);
      if (value == null) return null;
      final json = jsonDecode(value);
      if (json is! Map<String, dynamic>) {
        throw const FormatException('Invalid account session.');
      }
      return AccountSessionModel.fromJson(json);
    } on PlatformException catch (error) {
      throw AuthStorageException(error.message);
    } on FormatException catch (error) {
      await clearSession();
      throw AuthStorageException(error.message);
    }
  }

  Future<void> saveLastStudioId(int studioId) async {
    try {
      await _secureStorage.write(key: _lastStudioIdKey, value: '$studioId');
    } on PlatformException catch (error) {
      throw AuthStorageException(error.message);
    }
  }

  Future<int?> readLastStudioId() async {
    try {
      return int.tryParse(
        await _secureStorage.read(key: _lastStudioIdKey) ?? '',
      );
    } on PlatformException catch (error) {
      throw AuthStorageException(error.message);
    }
  }
}

class AuthStorageException implements Exception {
  const AuthStorageException([this.message]);

  final String? message;
}
