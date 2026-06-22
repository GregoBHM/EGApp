import { chromium } from 'playwright';
import { env } from '../config/env';

export interface DniInfo {
  dni: string;
  nombres: string;
  apellidoPaterno: string;
  apellidoMaterno: string;
  codigoVerificacion: string;
}

/**
 * Scrapea el portal público para obtener los datos de un DNI.
 * @param dni Número de DNI de 8 dígitos
 */
export async function scrapeDni(dni: string): Promise<DniInfo | null> {
  // Validar formato básico de DNI
  if (!/^\d{8}$/.test(dni)) {
    throw new Error('DNI inválido. Debe contener exactamente 8 dígitos numéricos.');
  }

  const browser = await chromium.launch({
    headless: true, // Ejecutar en modo invisible
    args: ['--no-sandbox', '--disable-setuid-sandbox'], // Necesario para entornos Docker
  });

  const context = await browser.newContext();
  const page = await context.newPage();

  try {
    // 1. Navegar a la página
    await page.goto('https://dniperu.com/buscar-dni-nombres-apellidos/', {
      waitUntil: 'domcontentloaded',
      timeout: 15000,
    });

    // 2. Llenar el formulario
    await page.fill('#cc_nombres_1dni', dni);
    
    // 3. Hacer clic en buscar
    await page.click('.js-cc-submit');

    // 4. Esperar a que aparezca el contenedor de resultados y extraer el texto
    // El texto aparece dentro de un textarea con la clase .js-cc-copy-source
    const resultSelector = '.js-cc-copy-source';
    await page.waitForSelector(resultSelector, { state: 'visible', timeout: 10000 });
    
    const rawText = await page.inputValue(resultSelector);

    if (!rawText || rawText.trim() === '') {
      return null;
    }

    // 5. Parsear el texto extraído
    // Formato esperado:
    // Numero de DNI: 12345678
    // Nombres: JUAN PEREZ
    // Apellido Paterno: PEREZ
    // Apellido Materno: PEREZ
    // Codigo de Verificacion: 1
    
    const extractLine = (text: string, prefix: string) => {
      const match = text.match(new RegExp(`${prefix}:\\s*(.+)`, 'i'));
      return match ? match[1].trim() : '';
    };

    const info: DniInfo = {
      dni: extractLine(rawText, 'Numero de DNI'),
      nombres: extractLine(rawText, 'Nombres'),
      apellidoPaterno: extractLine(rawText, 'Apellido Paterno'),
      apellidoMaterno: extractLine(rawText, 'Apellido Materno'),
      codigoVerificacion: extractLine(rawText, 'Codigo de Verificacion'),
    };

    if (!info.nombres && !info.apellidoPaterno) {
       return null; // Si no extrajo nada coherente
    }

    return info;

  } catch (error) {
    console.error('Error durante el scraping del DNI:', error);
    throw new Error('No se pudo validar el DNI en este momento. Inténtelo más tarde.');
  } finally {
    await browser.close();
  }
}
