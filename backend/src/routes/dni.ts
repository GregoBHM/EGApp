import { Router, Request, Response } from 'express';
import { scrapeDni } from '../services/dni.scraper';

const router = Router();

/**
 * @openapi
 * /api/dni/{dni}:
 *   get:
 *     tags: [Validación]
 *     summary: Consultar datos de un DNI peruano
 *     parameters:
 *       - in: path
 *         name: dni
 *         required: true
 *         schema:
 *           type: string
 *         description: Número de DNI de 8 dígitos
 *     responses:
 *       200:
 *         description: Datos obtenidos correctamente.
 *       400:
 *         description: Formato de DNI inválido.
 *       404:
 *         description: DNI no encontrado o no válido.
 *       500:
 *         description: Error en el servicio de scraping.
 */
router.get('/dni/:dni', async (req: Request, res: Response) => {
  const { dni } = req.params;

  if (!/^\d{8}$/.test(dni)) {
    return res.status(400).json({
      success: false,
      message: 'El DNI proporcionado es inválido. Debe contener 8 dígitos numéricos.',
    });
  }

  try {
    const info = await scrapeDni(dni);

    if (!info) {
      return res.status(404).json({
        success: false,
        message: 'No se encontraron datos para este DNI.',
      });
    }

    return res.json({
      success: true,
      data: info,
    });
  } catch (error: any) {
    return res.status(500).json({
      success: false,
      message: error.message || 'Error al consultar el DNI.',
    });
  }
});

export default router;
