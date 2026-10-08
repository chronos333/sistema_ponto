
const jwt = require('jsonwebtoken');
const pool = require('../config/database');

async function autenticar(req, res, next) {
  const authorization = req.headers.authorization;

  if (!authorization || !authorization.startsWith('Bearer ')) {
    return res.status(401).json({
      message: 'Token de autenticação não informado.',
    });
  }

  const token = authorization.slice(7).trim();

  if (!token) {
    return res.status(401).json({
      message: 'Token de autenticação inválido.',
    });
  }

  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET, {
      issuer: 'sistema-ponto-api',
      algorithms: ['HS256'],
    });

    if (!payload.sub || !/^\d+$/.test(payload.sub)) {
      return res.status(401).json({
        message: 'Token de autenticação inválido.',
      });
    }

    const resultado = await pool.query(
      `SELECT id, nome, nif, email, ativo
       FROM funcionarios
       WHERE id = $1`,
      [payload.sub]
    );

    if (resultado.rowCount === 0 || !resultado.rows[0].ativo) {
      return res.status(401).json({
        message: 'Conta inexistente ou desativada.',
      });
    }

    req.funcionario = resultado.rows[0];

    next();
  } catch (error) {
    if (
      error.name === 'JsonWebTokenError' ||
      error.name === 'TokenExpiredError' ||
      error.name === 'NotBeforeError'
    ) {
      return res.status(401).json({
        message: 'Token inválido ou expirado.',
      });
    }

    console.error('Erro ao autenticar:', error.message);

    return res.status(500).json({
      message: 'Erro interno de autenticação.',
    });
  }
}

module.exports = autenticar;