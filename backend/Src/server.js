
require('dotenv').config();

const express = require('express');
const cors = require('cors');
const pool = require('./config/database');
const authRoutes = require('./routes/auth.routes');
const pontoRoutes = require('./routes/ponto.routes');

const app = express();
const PORT = Number(process.env.PORT || 3000);

app.use(cors());
app.use(express.json());

app.use('/api/auth', authRoutes);
app.use('/api/ponto', pontoRoutes);

app.get('/', (req, res) => {
  res.json({
    message: 'API Sistema de Ponto',
    status: 'online',
  });
});

app.get('/api/health', async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT NOW() AS horario, current_database() AS banco'
    );

    res.status(200).json({
      status: 'ok',
      database: 'connected',
      banco: result.rows[0].banco,
      horario: result.rows[0].horario,
    });
  } catch (error) {
    console.error('Falha ao verificar o banco:', error.message);

    res.status(503).json({
      status: 'error',
      message: 'Não foi possível conectar ao banco de dados.',
    });
  }
});

const server = app.listen(PORT, '0.0.0.0', () => {
  console.log(`API disponível na porta ${PORT}`);
});

async function encerrar() {
  server.close(async () => {
    await pool.end();
    process.exit(0);
  });
}

process.on('SIGINT', encerrar);
process.on('SIGTERM', encerrar);