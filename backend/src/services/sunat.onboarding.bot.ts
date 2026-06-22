import { chromium } from 'playwright';
import { env } from '../config/env';
import { encrypt } from '../utils/crypto';
import { db } from '../config/firebase';

export interface OnboardingCredentials {
  ruc: string;
  usuario_sol: string;
  clave_sol: string;
}

export interface OnboardingResult {
  client_id: string;
  client_secret: string;
}

export async function runSunatOnboardingBot(
  id_empresa: string,
  credentials: OnboardingCredentials
): Promise<void> {
  await db.collection('empresas').doc(id_empresa).update({
    estado_onboarding: 'procesando',
    onboarding_iniciado_at: new Date(),
    onboarding_error: null,
  });

  const browser = await chromium.launch({ headless: env.playwright.headless });

  try {
    const context = await browser.newContext({
      userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
    });
    const page = await context.newPage();

    await page.goto(`${env.sunat.portalUrl}/cl-ti-itmenu/MenuInternet.htm`);

    await page.fill('#txtRuc', credentials.ruc);
    await page.fill('#txtUsuario', credentials.usuario_sol);
    await page.fill('#txtContrasena', credentials.clave_sol);
    await page.click('#btnAceptar');

    await page.waitForNavigation({ waitUntil: 'networkidle', timeout: 30000 });

    await page.goto(`${env.sunat.portalUrl}/ol-ti-itgiecrferegistro/GCREFERegistroServlet?accion=cargarRegistro`);
    await page.waitForLoadState('networkidle', { timeout: 30000 });

    const clientIdEl = await page.waitForSelector('#clientId', { timeout: 15000 });
    const clientSecretEl = await page.waitForSelector('#clientSecret', { timeout: 15000 });

    const client_id = (await clientIdEl.inputValue()).trim();
    const client_secret = (await clientSecretEl.inputValue()).trim();

    if (!client_id || !client_secret) {
      throw new Error('No se encontraron credenciales API en el portal SUNAT.');
    }

    const client_secret_encriptado = encrypt(client_secret);

    await db.collection('empresas').doc(id_empresa).update({
      sunat_client_id: client_id,
      sunat_client_secret_enc: client_secret_encriptado,
      estado_onboarding: 'completado',
      onboarding_completado_at: new Date(),
    });
  } catch (error) {
    const mensaje = error instanceof Error ? error.message : 'Error desconocido en el bot.';
    await db.collection('empresas').doc(id_empresa).update({
      estado_onboarding: 'error',
      onboarding_error: mensaje,
    });
    throw error;
  } finally {
    await browser.close();
  }
}
