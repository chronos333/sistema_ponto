import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position> obterLocalizacao() async {
    bool servicoAtivo = await Geolocator.isLocationServiceEnabled();

    if (!servicoAtivo) {
      throw Exception(
        'O serviço de localização está desativado. '
        'Ative o GPS para continuar.',
      );
    }

    LocationPermission permissao = await Geolocator.checkPermission();

    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();

      if (permissao == LocationPermission.denied) {
        throw Exception('Permissão de localização negada.');
      }
    }

    if (permissao == LocationPermission.deniedForever) {
      throw Exception(
        'A permissão de localização foi negada permanentemente. '
        'Ative-a nas configurações do aplicativo.',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }
}