import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import compression from 'compression';
import path from 'path';
import { config } from './config';
import { connectDB } from './config/database';
import routes from './routes';
import { errorHandler, notFoundHandler } from './middleware/errorHandler';

const app = express();

// Middleware
app.use(compression()); // Enable gzip compression for all responses
app.use(helmet({
  crossOriginResourcePolicy: { policy: "cross-origin" },
}));
app.use(cors({
  origin: config.corsOrigin,
  credentials: true,
}));
app.use(morgan('tiny')); // Use 'tiny' format for less logging overhead
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve static files for exercise images
app.use('/images', express.static(path.join(__dirname, '../../public/images')));
app.use('/images', express.static(path.join(__dirname, '../public/images')));

// API Routes
app.use('/api', routes);

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'Healthcare API Server',
    version: '1.0.0',
    endpoints: {
      health: '/api/health',
      auth: '/api/auth',
      exercises: '/api/exercises',
      recipes: '/api/recipes',
      foods: '/api/foods',
      meals: '/api/meals',
      tracking: '/api/tracking',
      plans: '/api/plans',
    },
  });
});

// Error handlers
app.use(notFoundHandler);
app.use(errorHandler);

// Start server
const startServer = async () => {
  try {
    await connectDB();

    // Listen on 0.0.0.0 to allow connections from Android Emulator (10.0.2.2)
    app.listen(config.port, '0.0.0.0', () => {
      console.log('');
      console.log('🚀 ================================================');
      console.log('   Healthcare API Server');
      console.log('   ================================================');
      console.log(`   🌐 Server:     http://0.0.0.0:${config.port}`);
      console.log(`   📦 API Base:   http://localhost:${config.port}/api`);
      console.log(`   📱 Android:    http://10.0.2.2:${config.port}/api`);
      console.log(`   🔧 Mode:       ${config.nodeEnv}`);
      console.log('   ================================================');
      console.log('');
    });
  } catch (error) {
    console.error('❌ Failed to start server:', error);
    process.exit(1);
  }
};

startServer();

export default app;
