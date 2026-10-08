import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../services/biometric_service.dart';
import '../services/location_service.dart';
import '../services/ponto_service.dart';

class RegistroPontoPage extends StatefulWidget {
  const RegistroPontoPage({super.key});

  @override
  State<RegistroPontoPage> createState() => _RegistroPontoPageState();
}

class _RegistroPontoPageState extends State<RegistroPontoPage> {
  final LocationService _locationService = LocationService();
  final BiometricService _biometricService = BiometricService();
  final PontoService _pontoService = PontoService();

  bool _carregando = false;

  String _status = 'Pronto para registrar seu ponto.';
  String? _tipoProximo;
  double? _precisao;
  double? _distancia;

  @override
  void initState() {
    super.initState();
    _carregarEstado();
  }

  Future<void> _carregarEstado() async {
    try {
      final estado = await _pontoService.obterEstado();

      if (!mounted) return;

      setState(() {
        _tipoProximo = estado['proximo_tipo']?.toString();
      });
    } catch (_) {
      // O usuário ainda poderá tentar registrar.
    }
  }

  Future<void> _registrarPonto() async {
    if (_carregando) return;

    setState(() {
      _carregando = true;
      _status = 'Verificando biometria...';
      _distancia = null;
      _precisao = null;
    });

    try {
      // 1. Verifica se o aparelho possui biometria.
      final possuiBiometria =
          await _biometricService.dispositivoPossuiBiometria();

      if (!possuiBiometria) {
        throw Exception(
          'Este dispositivo não possui uma biometria disponível.',
        );
      }

      // 2. Solicita a autenticação biométrica.
      final autenticado = await _biometricService.autenticar();

      if (!autenticado) {
        throw Exception(
          'A autenticação biométrica não foi realizada.',
        );
      }

      if (!mounted) return;

      setState(() {
        _status = 'Obtendo sua localização...';
      });

      // 3. Obtém a localização.
      final Position posicao =
          await _locationService.obterLocalizacao();

      if (!mounted) return;

      setState(() {
        _precisao = posicao.accuracy;
        _status = 'Validando localização...';
      });

      // 4. Envia localização para o backend.
      final resultado = await _pontoService.registrarPonto(
        latitude: posicao.latitude,
        longitude: posicao.longitude,
        precisaoMetros: posicao.accuracy,
      );

      if (!mounted) return;

      final tipo = resultado['tipo']?.toString();

      final registro = resultado['registro'];

      if (registro is Map) {
        final distancia = registro['distancia_m'];

        if (distancia is num) {
          _distancia = distancia.toDouble();
        }
      }

      setState(() {
        _tipoProximo = tipo == 'entrada' ? 'saida' : 'entrada';
        _status =
            resultado['message']?.toString() ??
            'Ponto registrado com sucesso.';
      });

      await _mostrarSucesso(
        resultado['message']?.toString() ??
            'Ponto registrado com sucesso.',
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _status = error
            .toString()
            .replaceFirst('Exception: ', '');
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_status),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  Future<void> _mostrarSucesso(String mensagem) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
              ),
              SizedBox(width: 10),
              Text('Ponto registrado'),
            ],
          ),
          content: Text(mensagem),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  String _textoTipo() {
    if (_tipoProximo == 'saida') {
      return 'Registrar saída';
    }

    return 'Registrar entrada';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de ponto'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              const Icon(
                Icons.access_time,
                size: 80,
              ),

              const SizedBox(height: 24),

              const Text(
                'Registro de ponto',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                _status,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 30),

              if (_tipoProximo != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        const Text(
                          'Próximo registro',
                          style: TextStyle(
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _tipoProximo == 'entrada'
                              ? 'ENTRADA'
                              : 'SAÍDA',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              if (_precisao != null)
                Text(
                  'Precisão do GPS: ${_precisao!.toStringAsFixed(1)} m',
                  textAlign: TextAlign.center,
                ),

              if (_distancia != null)
                Text(
                  'Distância do local: ${_distancia!.toStringAsFixed(1)} m',
                  textAlign: TextAlign.center,
                ),

              const Spacer(),

              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed:
                      _carregando ? null : _registrarPonto,
                  icon: _carregando
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.fingerprint),
                  label: Text(
                    _carregando
                        ? 'Processando...'
                        : _textoTipo(),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'A biometria será solicitada antes do registro. '
                'O ponto só será aceito dentro do raio permitido '
                'do local de trabalho.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}