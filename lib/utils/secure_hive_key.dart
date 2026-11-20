// import 'dart:convert';
// import 'dart:math';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
//
// /// VAPT Fix #4 & #5: Encrypted Hive database using Android Keystore-backed key
// /// - Replaces hardcoded AES key with a securely generated, stored key
// /// - Key is stored in FlutterSecureStorage (encryptedSharedPreferences = Android Keystore)
// /// - Key is never hardcoded in source code
// class SecureHiveKey {
//   static const _keyName = 'hive_encryption_key_v1';
//
//   static const _secureStorage = FlutterSecureStorage(
//     aOptions: AndroidOptions(encryptedSharedPreferences: true),
//   );
//
//   /// Returns a 32-byte encryption key for Hive AES cipher.
//   /// First run: generates a cryptographically random key and stores it securely.
//   /// Subsequent runs: retrieves the stored key.
//   static Future<List<int>> getEncryptionKey() async {
//     try {
//       final stored = await _secureStorage.read(key: _keyName);
//       if (stored != null && stored.isNotEmpty) {
//         final decoded = base64Decode(stored);
//         if (decoded.length == 32) return decoded;
//       }
//     } catch (_) {}
//
//     // Generate a new cryptographically secure 32-byte key
//     final key = _generateSecureKey(32);
//     await _secureStorage.write(
//       key: _keyName,
//       value: base64Encode(key),
//     );
//     return key;
//   }
//
//   static List<int> _generateSecureKey(int length) {
//     final rng = Random.secure();
//     return List<int>.generate(length, (_) => rng.nextInt(256));
//   }
// }
