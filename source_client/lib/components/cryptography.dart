import 'package:fast_rsa/fast_rsa.dart';

class Cryptography {
  static String? _publicKey;

  static String? _privateKey;

  static Future<String> encryptText(String text) {
    return RSA.encryptPKCS1v15(text, _publicKey!);
  }

  static Future<String> decryptText(String encryptedBase64) {
    return RSA.decryptPKCS1v15(encryptedBase64, _privateKey!);
  }

  static Future updatePrivateKey(String privateKey) async {
    _privateKey = privateKey;
  }

  static Future updatePublicKey(String publicKey) async {
    _publicKey = publicKey;
  }

  static Map<String, String> exportKeys() {
    return {"publickey": _publicKey!, "privatekey": _privateKey!};
  }

  static Future<Map<String, String>> generateRSAKeyPair() async {
    final keys = await RSA.generate(2048);

    return {
      "privatekey": await RSA.convertPrivateKeyToPKCS1(keys.privateKey),
      "publickey": await RSA.convertPublicKeyToPKCS1(keys.publicKey),
    };
  }
}
