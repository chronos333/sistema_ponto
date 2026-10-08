
const express = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const pool = require('../config/database');
const autenticar = require('../middleware/auth.middleware');

const router = express.Router();

function gerarToken(funcionario) {
  return jwt.sign(
    {
      sub: String(funcionario.id),
    },
    process.env.JWT_SECRET,
    {
      expiresIn: '8h',
      issuer: 'sistema-ponto-api',
    }
  );
}

// Cadastro público de funcionários
router.post('/register', async (req, res) => {
  try {
    const { nome, nif, email, senha } = req.body;

    if (
      typeof nome !== 'string' ||
      typeof nif !== 'string' ||
      typeof email !== 'string' ||
      typeof senha !== 'string'
    ) {
      return res.status(400).json({
        message: 'Informe nome, NIF, e-mail e senha.',
      });
    }

    const nomeNormalizado = nome.trim();
    const nifNormalizado = nif.trim();
    const emailNormalizado = email.trim().toLowerCase();

    if (nomeNormalizado.length < 2 || nomeNormalizado.length > 120) {
      return res.status(400).json({
        message: 'O nome deve ter entre 2 e 120 caracteres.',
      });
    }

    if (
      nifNormalizado.length < 1 ||
      nifNormalizado.length > 30
    ) {
      return res.status(400).json({
        message: 'Informe um NIF válido.',
      });
    }

    if (
      emailNormalizado.length > 255 ||
      !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(emailNormalizado)
    ) {
      return res.status(400).json({
        message: 'Informe um e-mail válido.',
      });
    }

    if (senha.length < 8 || senha.length > 72) {
      return res.status(400).json({
        message: 'A senha deve ter entre 8 e 72 caracteres.',
      });
    }

    const existente = await pool.query(
      `SELECT id
       FROM funcionarios
       WHERE LOWER(email) = $1 OR nif = $2
       LIMIT 1`,
      [emailNormalizado, nifNormalizado]
    );

    if (existente.rowCount > 0) {
      return res.status(409).json({
        message: 'Este e-mail ou NIF já está cadastrado.',
      });
    }

    const senhaHash = await bcrypt.hash(senha, 12);

    const resultado = await pool.query(
      `INSERT INTO funcionarios (nome, nif, email, senha_hash)
       VALUES ($1, $2, $3, $4)
       RETURNING id, nome, nif, email, criado_em`,
      [nomeNormalizado, nifNormalizado, emailNormalizado, senhaHash]
    );

    const funcionario = resultado.rows[0];

    return res.status(201).json({
      message: 'Conta criada com sucesso.',
      funcionario,
      token: gerarToken(funcionario),
    });
  } catch (error) {
    if (error.code === '23505') {
      return res.status(409).json({
        message: 'Este e-mail ou NIF já está cadastrado.',
      });
    }

    console.error('Erro no cadastro:', error.message);

    return res.status(500).json({
      message: 'Não foi possível criar a conta.',
    });
  }
});

// Login com e-mail ou NIF
router.post('/login', async (req, res) => {
  try {
    const { identificador, senha } = req.body;

    if (
      typeof identificador !== 'string' ||
      typeof senha !== 'string' ||
      identificador.trim().length === 0 ||
      senha.length === 0
    ) {
      return res.status(400).json({
        message: 'Informe seu e-mail ou NIF e sua senha.',
      });
    }

    const valor = identificador.trim();

    const resultado = await pool.query(
      `SELECT id, nome, nif, email, senha_hash
       FROM funcionarios
       WHERE LOWER(email) = LOWER($1) OR nif = $1
       LIMIT 1`,
      [valor]
    );

    if (resultado.rowCount === 0) {
      return res.status(401).json({
        message: 'Credenciais inválidas.',
      });
    }

    const funcionario = resultado.rows[0];

    const senhaCorreta = await bcrypt.compare(
      senha,
      funcionario.senha_hash
    );

    if (!senhaCorreta) {
      return res.status(401).json({
        message: 'Credenciais inválidas.',
      });
    }

    const { senha_hash, ...dadosFuncionario } = funcionario;

    return res.status(200).json({
      message: 'Login realizado com sucesso.',
      funcionario: dadosFuncionario,
      token: gerarToken(funcionario),
    });
  } catch (error) {
    console.error('Erro no login:', error.message);

    return res.status(500).json({
      message: 'Não foi possível realizar o login.',
    });
  }
});

router.get('/me', autenticar, (req, res) => {
  return res.status(200).json({
    funcionario: req.funcionario,
  });
});

module.exports = router;