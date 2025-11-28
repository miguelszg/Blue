const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;
const VERSION = process.env.VERSION || 'unknown';
const ENV = process.env.NODE_ENV || 'development';

app.get('/', (req, res) => {
  res.json({
    deployNumber: 6,
    message: 'Hello from Blue-Green Deployment! 6.0',
    version: VERSION,
    environment: ENV,
    hostname: require('os').hostname(),
    timestamp: new Date().toISOString()
  });
});

app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    version: VERSION,
    environment: VERSION,
    hostname: require('os').hostname(),
    timestamp: new Date().toISOString()
  });
});

// ✨ NUEVA RUTA - Deployment Status
app.get('/deployment-status', (req, res) => {
  res.json({
    status: 'active',
    version: VERSION,
    environment: VERSION,
    port: PORT,
    student: 'Miguel',  // ← TU NOMBRE
    hostname: require('os').hostname(),
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`📦 Version: ${VERSION}`);
  console.log(`🎨 Environment: ${ENV}`);
});