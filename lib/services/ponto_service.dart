import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class PontoService {
  static const String baseUrl = 'http://192.168.56.1:3000/api/ponto';

  static const _storage = FlutterSecureStorage();

  Future<String> _obterToken() async {
    final token = await _storage.read(key: 'auth_token');

    if (token == null || token.isEmpty) {
      throw Exception('Usuário não autenticado.');
    }

    return token;
  }

  Future<Map<String, dynamic>> registrarPonto({
    required double latitude,
    required double longitude,
    required double precisaoMetros,
  }) async {
    final token = await _obterToken();

    final response = await http
        .post(
          Uri.parse('$baseUrl/registrar'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'latitude': latitude,
            'longitude': longitude,
            'precisao_m': precisaoMetros,
          }),
        )
        .timeout(const Duration(seconds: 15));

    final dados = _decodificarResposta(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        dados['message']?.toString() ??
            'Não foi possível registrar o ponto.',
      );
    }

    return dados;
  }

  Future<Map<String, dynamic>> obterEstado() async {
    final token = await _obterToken();

    final response = await http
        .get(
          Uri.parse('$baseUrl/estado'),
          headers: {
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 15));

    final dados = _decodificarResposta(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        dados['message']?.toString() ??
            'Não foi possível consultar o estado do ponto.',
      );
    }

    return dados;
  }

  Future<List<Map<String, dynamic>>> obterHistorico() async {
    final token = await _obterToken();

    final response = await http
        .get(
          Uri.parse('$baseUrl/historico'),
          headers: {
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 15));

    final dados = _decodificarResposta(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        dados['message']?.toString() ??
            'Não foi possível consultar o histórico.',
      );
    }

    final registros = dados['registros'];

    if (registros is! List) {
      return [];
    }

    return registros
        .whereType<Map>()
        .map(
          (registro) => Map<String, dynamic>.from(registro),
        )
        .toList();
  }

  Map<String, dynamic> _decodificarResposta(http.Response response) {
    try {
      final corpo = jsonDecode(response.body);

      if (corpo is Map<String, dynamic>) {
        return corpo;
      }

      return {
        'message': 'Resposta inválida do servidor.',
      };
    } catch (_) {
      return {
        'message': 'Resposta inválida do servidor.',
      };
    }
  }
}