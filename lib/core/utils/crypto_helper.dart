import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart' as crypto;
import 'package:encrypt/encrypt.dart' as encrypt;
import '../constants/app_constants.dart';

class CryptoHelper {
  CryptoHelper._();

  /// OpenSSL-compatible AES-256-CBC encryption with random 8-byte salt ("Salted__").
  static String encryptPayload(
      String plainText, [
        String passphrase = AppConstants.encryptionKey,
      ]) {
    final salt = encrypt.IV.fromSecureRandom(8).bytes;
    final passBytes = utf8.encode(passphrase);

    final d1 = crypto.md5.convert([...passBytes, ...salt]).bytes;
    final d2 = crypto.md5.convert([...d1, ...passBytes, ...salt]).bytes;
    final d3 = crypto.md5.convert([...d2, ...passBytes, ...salt]).bytes;

    final key = encrypt.Key(Uint8List.fromList([...d1, ...d2]));
    final iv = encrypt.IV(Uint8List.fromList(d3));

    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: 'PKCS7'),
    );
    final encrypted = encrypter.encrypt(plainText, iv: iv);

    final saltedPrefix = utf8.encode('Salted__');
    final combined = Uint8List.fromList([
      ...saltedPrefix,
      ...salt,
      ...encrypted.bytes,
    ]);

    return base64.encode(combined);
  }
}