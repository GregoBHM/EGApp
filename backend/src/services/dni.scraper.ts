import axios from 'axios';

export interface DniInfo {
  dni: string;
  nombres: string;
  apellidoPaterno: string;
  apellidoMaterno: string;
  codigoVerificacion: string;
}

/**
 * Calcula el código de verificación de un DNI peruano (algoritmo Módulo 11)
 */
function calcularCodigoVerificacion(dni: string): string {
  const multipliers = [3, 2, 7, 6, 5, 4, 3, 2];
  const hash = [6, 5, 4, 3, 2, 1, 1, 0, 9, 8, 7];
  
  let sum = 0;
  for (let i = 0; i < 8; i++) {
    sum += parseInt(dni[i], 10) * multipliers[i];
  }
  
  const remainder = sum % 11;
  return hash[remainder].toString();
}

/**
 * Consulta la API de apis.net.pe para obtener los datos de un DNI.
 * @param dni Número de DNI de 8 dígitos
 */
export async function scrapeDni(dni: string): Promise<DniInfo | null> {
  if (!/^\d{8}$/.test(dni)) {
    throw new Error('DNI inválido. Debe contener exactamente 8 dígitos numéricos.');
  }

  try {
    const response = await axios.get(`https://api.apis.net.pe/v1/dni?numero=${dni}`, {
      timeout: 10000,
    });

    const data = response.data;

    if (!data || !data.nombres) {
      return null;
    }

    return {
      dni: data.numeroDocumento || dni,
      nombres: data.nombres,
      apellidoPaterno: data.apellidoPaterno,
      apellidoMaterno: data.apellidoMaterno,
      codigoVerificacion: calcularCodigoVerificacion(dni),
    };

  } catch (error: any) {
    if (error.response && error.response.status === 404) {
      return null; // DNI no encontrado
    }
    console.error('Error al consultar DNI en apis.net.pe:', error.message);
    throw new Error('No se pudo validar el DNI en este momento. Inténtelo más tarde.');
  }
}
