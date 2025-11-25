const express = require('express');
const path = require('path');
const os = require('os');

const app = express();
const PORT = process.env.PORT || 3000;
const VERSION = process.env.VERSION || '1.1.0'; //Nueva version
const ENVIRONMENT = process.env.ENVIRONMENT || 'blue';

app.use(express.static('public'));

app.get('/', (req, res) => {
  res.json({
    message: '¡Hola desde Blue-Green Deployment! v4.0', 
    version: VERSION,
    environment: ENVIRONMENT,
    hostname: os.hostname(),
    timestamp: new Date().toISOString()
  });
});

app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    version: VERSION,
    environment: ENVIRONMENT,
    hostname: os.hostname(),
    timestamp: new Date().toISOString()
  });
});

app.get('/api/info', (req, res) => {
  res.json({
    version: VERSION,
    environment: ENVIRONMENT,
    hostname: os.hostname(),
    uptime: process.uptime(),
    memory: process.memoryUsage()
  });
});

app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`📦 Version: ${VERSION}`);
  console.log(`🎨 Environment: ${ENVIRONMENT}`);
});
