import { Worker, Job } from 'bullmq';
import { redisConnection } from './onboarding.queue';
import { runSunatOnboardingBot } from '../services/sunat.onboarding.bot';

interface OnboardingJobData {
  id_empresa: string;
  ruc: string;
  usuario_sol: string;
  clave_sol_encriptada: string;
}

async function processJob(job: Job<OnboardingJobData>): Promise<void> {
  const { id_empresa, ruc, usuario_sol, clave_sol_encriptada } = job.data;

  console.log(`[Worker] Procesando job #${job.id} — Empresa: ${id_empresa}, RUC: ${ruc}`);

  await runSunatOnboardingBot(id_empresa, {
    ruc,
    usuario_sol,
    clave_sol: clave_sol_encriptada,
  });
}

export const onboardingWorker = new Worker<OnboardingJobData>(
  'sunat-onboarding',
  processJob,
  {
    connection: redisConnection,
    concurrency: 1,
  },
);

onboardingWorker.on('completed', (job) => {
  console.log(`[Worker] ✅ Job #${job.id} completado exitosamente.`);
});

onboardingWorker.on('failed', (job, err) => {
  console.error(`[Worker] ❌ Job #${job?.id} falló: ${err.message}`);
});

console.log('[Worker] Onboarding Worker escuchando la cola "sunat-onboarding".');
