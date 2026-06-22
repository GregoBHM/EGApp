import { env } from './config/env';
import './config/firebase';
import './queue/worker';
import sunatRouter from './routes/sunat';
import dniRouter from './routes/dni';

import express, { Request, Response, NextFunction } from 'express';
import cors from 'cors';
import swaggerUi from 'swagger-ui-express';
import { swaggerSpec } from './config/swagger';

const app = express();

app.use(cors());
app.use(express.json());

app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec, {
  customSiteTitle: 'EGApp API Docs',
  customCss: '.swagger-ui .topbar { background-color: #1a1a2e; } .swagger-ui .topbar-wrapper img { content: none; }',
  swaggerOptions: {
    persistAuthorization: true,
    displayRequestDuration: true,
  },
}));

app.get('/api-docs.json', (_req: Request, res: Response) => {
  res.setHeader('Content-Type', 'application/json');
  res.send(swaggerSpec);
});

/**
 * @openapi
 * /health:
 *   get:
 *     tags: [Sistema]
 *     summary: Estado del servidor
 *     responses:
 *       200:
 *         description: Servidor funcionando correctamente.
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/HealthResponse'
 */
app.get('/health', (_req: Request, res: Response) => {
  res.json({
    status: 'ok',
    project: 'EGApp',
    environment: env.nodeEnv,
    timestamp: new Date().toISOString(),
  });
});

app.use('/egapp', sunatRouter);
app.use('/egapp', dniRouter);

app.use((err: Error, _req: Request, res: Response, _next: NextFunction) => {
  console.error('[Server] Error no manejado:', err.message);
  res.status(500).json({
    success: false,
    message: 'Error interno del servidor.',
  });
});

app.listen(env.port, () => {
  console.log('================================================');
  console.log(`  EGApp Backend — Motor SUNAT`);
  console.log(`  Ambiente : ${env.nodeEnv}`);
  console.log(`  Puerto   : ${env.port}`);
  console.log(`  Health   : http://localhost:${env.port}/health`);
  console.log(`  API Docs : http://localhost:${env.port}/api-docs`);
  console.log('================================================');
});

export default app;
