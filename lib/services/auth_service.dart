import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthService {
  // Troque pelo IPv4 do seu computador.
  static const String baseUrl = 'http://192.168.56.1:3000';

  static const _storage = FlutterSecureStorage();

  Future<Map<String, dynamic>> _enviar(
    String rota,
    Map<String, dynamic> dados, {
    required int statusEsperado,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/auth/$rota'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(dados),
        )
        .timeout(const Duration(seconds: 15));

    final Map<String, dynamic> resultado;

    try {
      resultado = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('A API retornou uma resposta inválida.');
    }

    if (response.statusCode != statusEsperado) {
      throw Exception(
        resultado['message'] ?? 'Não foi possível concluir a operação.',
      );
    }

    final token = resultado['token'];
    if (token is! String || token.isEmpty) {
      throw Exception('A API não retornou um token válido.');
    }

    await _storage.write(key: 'auth_token', value: token);

    final funcionario = resultado['funcionario'];
    if (funcionario is! Map) {
      throw Exception('Dados do funcionário não retornados pela API.');
    }

    return Map<String, dynamic>.from(funcionario);
  }

  Future<Map<String, dynamic>> login({
    required String identificador,
    required String senha,
  }) {
    return _enviar(
      'login',
      {'identificador': identificador.trim(), 'senha': senha},
      statusEsperado: 200,
    );
  }

  Future<Map<String, dynamic>> cadastrar({
    required String nome,
    required String nif,
    required String email,
    required String senha,
  }) {
    return _enviar(
      'register',
      {
        'nome': nome.trim(),
        'nif': nif.trim(),
        'email': email.trim(),
        'senha': senha,
      },
      statusEsperado: 201,
    );
  }

  Future<void> logout() => _storage.delete(key: 'auth_token');

  Future<String?> obterToken() => _storage.read(key: 'auth_token');
}