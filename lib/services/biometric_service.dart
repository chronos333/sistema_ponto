import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> dispositivoPossuiBiometria() async {
    try {
      final disponivel = await _auth.canCheckBiometrics;
      final suportado = await _auth.isDeviceSupported();

      return disponivel && suportado;
    } catch (_) {
      return false;
    }
  }

  Future<bool> autenticar() async {
    try {
      return await _auth.authenticate(
        localizedReason:
            'Confirme sua identidade para registrar o ponto.',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }
}