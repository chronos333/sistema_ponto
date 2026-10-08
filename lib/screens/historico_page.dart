import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/ponto_service.dart';

class HistoricoPage extends StatefulWidget {
  const HistoricoPage({super.key});

  @override
  State<HistoricoPage> createState() => _HistoricoPageState();
}

class _HistoricoPageState extends State<HistoricoPage> {
  final PontoService _pontoService = PontoService();

  bool _carregando = true;
  String? _erro;
  List<Map<String, dynamic>> _registros = [];

  @override
  void initState() {
    super.initState();
    _carregarHistorico();
  }

  Future<void> _carregarHistorico() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final registros = await _pontoService.obterHistorico();

      if (!mounted) return;

      setState(() {
        _registros = registros;
        _carregando = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _carregando = false;
        _erro = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  DateTime? _dataRegistro(Map<String, dynamic> registro) {
    final valor = registro['registrado_em'];
    if (valor == null) return null;

    return DateTime.tryParse(valor.toString())?.toLocal();
  }

  String _tipoRegistro(Map<String, dynamic> registro) {
    final tipo = registro['tipo']?.toString().toLowerCase();

    if (tipo == 'entrada' || tipo == 'saida') {
      return tipo!;
    }

    return 'registro';
  }

  String _formatarData(DateTime data) {
    return DateFormat('dd/MM/yyyy').format(data);
  }

  String _formatarHora(DateTime data) {
    return DateFormat('HH:mm:ss').format(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: const Text('Histórico de registros'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _carregando ? null : _carregarHistorico,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_carregando) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_erro != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 56,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 14),
              Text(
                _erro!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _carregarHistorico,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (_registros.isEmpty) {
      return RefreshIndicator(
        onRefresh: _carregarHistorico,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 150),
            Icon(
              Icons.history_toggle_off_rounded,
              size: 72,
              color: Colors.black38,
            ),
            SizedBox(height: 18),
            Text(
              'Nenhum registro encontrado.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Seus registros de ponto aparecerão aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _carregarHistorico,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        itemCount: _registros.length,
        itemBuilder: (context, index) {
          final registro = _registros[index];
          final data = _dataRegistro(registro);

          if (data == null) {
            return const SizedBox.shrink();
          }

          final tipo = _tipoRegistro(registro);
          final entrada = tipo == 'entrada';
          final distancia = registro['distancia_m'];
          final precisao = registro['precisao_m'];
          final local = registro['local_nome']?.toString();

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(17),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: (entrada ? Colors.green : Colors.orange)
                          .withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      entrada
                          ? Icons.login_rounded
                          : Icons.logout_rounded,
                      color: entrada ? Colors.green.shade700 : Colors.orange.shade700,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entrada ? 'ENTRADA' : 'SAÍDA',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: entrada
                                ? Colors.green.shade700
                                : Colors.orange.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_formatarData(data)} • ${_formatarHora(data)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (local != null) ...[
                          const SizedBox(height: 5),
                          Text(
                            local,
                            style: const TextStyle(
                              color: Colors.black54,
                            ),
                          ),
                        ],
                        if (distancia is num || precisao is num) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 12,
                            children: [
                              if (distancia is num)
                                Text(
                                  'Distância: ${distancia.toDouble().toStringAsFixed(1)} m',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              if (precisao is num)
                                Text(
                                  'Precisão: ${precisao.toDouble().toStringAsFixed(1)} m',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
