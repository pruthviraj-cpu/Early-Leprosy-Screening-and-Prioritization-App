// src/server.js - ES Module version
import dotenv from 'dotenv';
import app from './app.js';  // Note: .js extension and default import

dotenv.config();

// Validate required environment variables
const requiredEnvVars = ['JWT_SECRET', 'SUPABASE_URL', 'SUPABASE_ANON_KEY'];
requiredEnvVars.forEach(varName => {
  if (!process.env[varName]) {
    console.error(`Missing required environment variable: ${varName}`);
    process.exit(1);
  }
});

const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
  console.log(`✅ Server running on port ${PORT}`);
  console.log(`✅ Supabase connected`);
  console.log(`✅ Health check: http://localhost:${PORT}/health`);
});