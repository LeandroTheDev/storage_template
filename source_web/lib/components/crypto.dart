import 'package:encrypt/encrypt.dart';
import 'package:pointycastle/asymmetric/api.dart';

class Crypto {
  static final RSAAsymmetricKey _publicKey =
      RSAKeyParser().parse('''-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAmO8Jj6+2IgYHgT7UIybp
iBVdqGUV7h5m1zrDm5y9Cs94Bgy6yulgjQ8dOW88VVdCsZQfFhLqdllMq0rylOx4
bAOW9PdDwmV5npAbM1N7bBmdSnCIfPobpRF4VS+QC3QNYO4dAbqVbadaqL1NWhxp
0oO3A3XS3D1XO6Hj26K3WvSrFlQ32K+QkFlb9E9k5REAyiOkbPhTqNnvv/9fdVMr
fIDasxz92pFvWUR2HowX2i1O8QUUD6530skFyvJ3IgBUfKdSVR/FPrR90q3Tci7T
hX4zW4VqmRJHqRrPRiXGLfPUOjthGWt4ev8ogRliO6QNxgLmXOmuwq3FlJ4sXEn7
xQIDAQAB
-----END PUBLIC KEY-----''');

  static String encryptText(String text) {
    final encrypter = Encrypter(RSA(
        publicKey: RSAPublicKey(_publicKey.modulus!, _publicKey.exponent!)));
    final encrypted = encrypter.encrypt(text);
    return encrypted.base64;
  }
}
