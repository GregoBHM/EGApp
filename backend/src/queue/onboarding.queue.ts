import { Queue } from 'bullmq';
import { env } from '../config/env';

export const redisConnection = {
  host: env.redis.host,
  port: env.redis.port,
};

export const onboardingQueue = new Queue('sunat-onboarding', {
  connection: redisConnection,
  defaultJobOptions: {
    attempts: 3,
    backoff: {
      type: 'exponential',
      delay: 1000,
    },
    removeOnComplete: { count: 100 },
    removeOnFail: { count: 200 },
  },
});

console.log('[Queue] Cola "sunat-onboarding" lista.');
