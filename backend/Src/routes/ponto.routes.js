const express = require('express');
const pool = require('../config/database');
const autenticar = require('../middleware/auth.middleware');

const router = express.Router();

const RAIO_PADRAO_METROS = 100;

function calcularDistanciaMetros(lat1, lon1, lat2, lon2) {
  const raioTerra = 6371000;

  const toRadians = (graus) => graus * Math.PI / 180;

  const dLat = toRadians(lat2 - lat1);
  const dLon = toRadians(lon2 - lon1);

  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRadians(lat1)) *
      Math.cos(toRadians(lat2)) *
      Math.sin(dLon / 2) ** 2;

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return raioTerra * c;
}

/*
 * POST /api/ponto/registrar
 *
 * Registra um ponto para o funcionário autenticado.
 */
router.post('/registrar', autenticar, async (req, res) => {
  try {
    const { latitude, longitude, precisao_m } = req.body;

    if (
      typeof latitude !== 'number' ||
      typeof longitude !== 'number' ||
      typeof precisao_m !== 'number'
    ) {
      return res.status(400).json({
        message: 'Latitude, longitude e precisão são obrigatórias.',
      });
    }

    if (
      !Number.isFinite(latitude) ||
      !Number.isFinite(longitude) ||
      !Number.isFinite(precisao_m)
    ) {
      return res.status(400).json({
        message: 'Os dados de localização são inválidos.',
      });
    }

    if (latitude < -90 || latitude > 90) {
      return res.status(400).json({
        message: 'Latitude inválida.',
      });
    }

    if (longitude < -180 || longitude > 180) {
      return res.status(400).json({
        message: 'Longitude inválida.',
      });
    }

    if (precisao_m < 0) {
      return res.status(400).json({
        message: 'Precisão inválida.',
      });
    }

    /*
     * Busca o local de trabalho ativo.
     */
    const localResult = await pool.query(
      `SELECT id, nome, latitude, longitude, raio_permitido_m
       FROM locais_trabalho
       WHERE ativo = TRUE
       ORDER BY id
       LIMIT 1`
    );

    if (localResult.rowCount === 0) {
      return res.status(503).json({
        message: 'Nenhum local de trabalho ativo está configurado.',
      });
    }

    const local = localResult.rows[0];

    const raioPermitido =
      Number(local.raio_permitido_m) > 0
        ? Number(local.raio_permitido_m)
        : RAIO_PADRAO_METROS;

    /*
     * Calcula a distância entre o funcionário e o local.
     */
    const distancia = calcularDistanciaMetros(
      latitude,
      longitude,
      Number(local.latitude),
      Number(local.longitude)
    );

    /*
     * Impede o registro fora do raio permitido.
     */
    if (distancia > raioPermitido) {
      return res.status(403).json({
        message: 'Você está fora do local permitido para registrar o ponto.',
        distancia_m: Number(distancia.toFixed(2)),
        raio_permitido_m: raioPermitido,
      });
    }

    /*
     * O sistema alterna automaticamente entre entrada e saída
     * através da quantidade de registros.
     *
     * Isso não é gravado no banco porque a tabela atual
     * não possui uma coluna "tipo".
     */
    const quantidadeResult = await pool.query(
      `SELECT COUNT(*)::integer AS quantidade
       FROM registros_ponto
       WHERE funcionario_id = $1`,
      [req.funcionario.id]
    );

    const quantidade = quantidadeResult.rows[0].quantidade;

    const tipo = quantidade % 2 === 0 ? 'entrada' : 'saida';

    /*
     * Grava o ponto usando o horário do PostgreSQL.
     */
    const registroResult = await pool.query(
      `INSERT INTO registros_ponto (
        funcionario_id,
        local_id,
        registrado_em,
        latitude,
        longitude,
        precisao_m,
        distancia_m
      )
      VALUES (
        $1,
        $2,
        NOW(),
        $3,
        $4,
        $5,
        $6
      )
      RETURNING
        id,
        funcionario_id,
        local_id,
        registrado_em,
        latitude,
        longitude,
        precisao_m,
        distancia_m,
        criado_em`,
      [
        req.funcionario.id,
        local.id,
        latitude,
        longitude,
        precisao_m,
        distancia,
      ]
    );

    const registro = registroResult.rows[0];

    return res.status(201).json({
      message:
        tipo === 'entrada'
          ? 'Entrada registrada com sucesso.'
          : 'Saída registrada com sucesso.',
      tipo,
      registro,
      local: {
        id: local.id,
        nome: local.nome,
        raio_permitido_m: raioPermitido,
      },
    });
  } catch (error) {
    console.error('Erro ao registrar ponto:', error.message);

    return res.status(500).json({
      message: 'Não foi possível registrar o ponto.',
    });
  }
});

/*
 * GET /api/ponto/estado
 *
 * Retorna qual será o próximo registro:
 * entrada ou saída.
 */
router.get('/estado', autenticar, async (req, res) => {
  try {
    const resultado = await pool.query(
      `SELECT id, registrado_em
       FROM registros_ponto
       WHERE funcionario_id = $1
       ORDER BY registrado_em DESC, id DESC
       LIMIT 1`,
      [req.funcionario.id]
    );

    const quantidadeResult = await pool.query(
      `SELECT COUNT(*)::integer AS quantidade
       FROM registros_ponto
       WHERE funcionario_id = $1`,
      [req.funcionario.id]
    );

    const quantidade = quantidadeResult.rows[0].quantidade;
    const proximoTipo = quantidade % 2 === 0 ? 'entrada' : 'saida';

    return res.status(200).json({
      proximo_tipo: proximoTipo,
      ultimo_registro:
        resultado.rowCount > 0 ? resultado.rows[0] : null,
    });
  } catch (error) {
    console.error('Erro ao consultar estado do ponto:', error.message);

    return res.status(500).json({
      message: 'Não foi possível consultar o estado do ponto.',
    });
  }
});

/*
 * GET /api/ponto/historico
 *
 * Retorna o histórico somente do funcionário autenticado.
 */
router.get('/historico', autenticar, async (req, res) => {
  try {
    const resultado = await pool.query(
      `SELECT
        rp.id,
        rp.registrado_em,
        rp.latitude,
        rp.longitude,
        rp.precisao_m,
        rp.distancia_m,
        rp.local_id,
        lt.nome AS local_nome,
        CASE
          WHEN ROW_NUMBER() OVER (
            PARTITION BY rp.funcionario_id
            ORDER BY rp.registrado_em ASC, rp.id ASC
          ) % 2 = 1 THEN 'entrada'
          ELSE 'saida'
        END AS tipo
       FROM registros_ponto rp
       INNER JOIN locais_trabalho lt
         ON lt.id = rp.local_id
       WHERE rp.funcionario_id = $1
       ORDER BY rp.registrado_em DESC, rp.id DESC
       LIMIT 100`,
      [req.funcionario.id]
    );

    return res.status(200).json({
      registros: resultado.rows,
    });
  } catch (error) {
    console.error('Erro ao consultar histórico:', error.message);

    return res.status(500).json({
      message: 'Não foi possível consultar o histórico.',
    });
  }
});

module.exports = router;