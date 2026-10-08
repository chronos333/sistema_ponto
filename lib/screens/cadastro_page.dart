import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'home_page.dart';

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _nif = TextEditingController();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  final _confirmarSenha = TextEditingController();
  final _authService = AuthService();

  bool _carregando = false;
  bool _mostrarSenha = false;

  @override
  void dispose() {
    _nome.dispose();
    _nif.dispose();
    _email.dispose();
    _senha.dispose();
    _confirmarSenha.dispose();
    super.dispose();
  }

  Future<void> _cadastrar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _carregando = true);

    try {
      final funcionario = await _authService.cadastrar(
        nome: _nome.text,
        nif: _nif.text,
        email: _email.text,
        senha: _senha.text,
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => HomePage(funcionario: funcionario),
        ),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  InputDecoration _decoracao(String titulo, IconData icone) {
    return InputDecoration(
      labelText: titulo,
      prefixIcon: Icon(icone),
      border: const OutlineInputBorder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    const azul = Color(0xFF174A78);

    return Scaffold(
      appBar: AppBar(title: const Text('Criar conta')),
      backgroundColor: const Color(0xFFF4F7FB),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.person_add_alt_1,
                      size: 60,
                      color: azul,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Cadastro de funcionário',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: azul,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nome,
                      textCapitalization: TextCapitalization.words,
                      decoration: _decoracao('Nome completo', Icons.person),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Informe seu nome.'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _nif,
                      decoration: _decoracao('NIF', Icons.badge_outlined),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Informe seu NIF.'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _decoracao('E-mail', Icons.email_outlined),
                      validator: (v) {
                        if (v == null ||
                            !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                .hasMatch(v.trim())) {
                          return 'Informe um e-mail válido.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _senha,
                      obscureText: !_mostrarSenha,
                      decoration: _decoracao(
                        'Senha (mínimo 8 caracteres)',
                        Icons.lock_outline,
                      ).copyWith(
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => _mostrarSenha = !_mostrarSenha,
                          ),
                          icon: Icon(
                            _mostrarSenha
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.length < 8) {
                          return 'A senha deve ter pelo menos 8 caracteres.';
                        }
                        if (v.length > 72) {
                          return 'A senha deve ter no máximo 72 caracteres.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _confirmarSenha,
                      obscureText: true,
                      decoration: _decoracao(
                        'Confirmar senha',
                        Icons.lock_reset,
                      ),
                      validator: (v) => v != _senha.text
                          ? 'As senhas não coincidem.'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: _carregando ? null : _cadastrar,
                        style: FilledButton.styleFrom(
                          backgroundColor: azul,
                        ),
                        child: _carregando
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text('Criar conta'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}