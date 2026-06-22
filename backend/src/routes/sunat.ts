import { Router, Request, Response } from 'express';
import axios from 'axios';
import { onboardingQueue } from '../queue/onboarding.queue';
import { getAccessToken } from '../services/sunat.auth';
import { buildGuiaXml, EmitirGuiaPayload } from '../services/sunat.xml.builder';
import { generateGuiaPdf } from '../services/pdf.generator';
import { db, bucket } from '../config/firebase';
import { env } from '../config/env';
import AdmZip from 'adm-zip';

const router = Router();

/**
 * @openapi
 * /egapp/setup-sunat:
 *   post:
 *     tags: [SUNAT - Onboarding]
 *     summary: Configurar credenciales SUNAT
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/SetupSunatRequest'
 *     responses:
 *       202:
 *         description: Proceso encolado correctamente.
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/SetupSunatResponse'
 *       400:
 *         description: Parámetros faltantes.
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 */
router.post('/setup-sunat', async (req: Request, res: Response) => {
  const { id_empresa, ruc, usuario_sol, clave_sol } = req.body;

  if (!id_empresa || !ruc || !usuario_sol || !clave_sol) {
    return res.status(400).json({
      success: false,
      message: 'Faltan parámetros requeridos: id_empresa, ruc, usuario_sol, clave_sol.',
    });
  }

  await onboardingQueue.add('setup', {
    id_empresa,
    ruc,
    usuario_sol,
    clave_sol_encriptada: clave_sol,
  });

  return res.status(202).json({
    success: true,
    status: 'processing_in_background',
    message: 'El proceso de configuración ha sido encolado. Recibirás actualización en tiempo real vía Firestore.',
  });
});

/**
 * @openapi
 * /egapp/emitir-guia:
 *   post:
 *     tags: [SUNAT - Guías]
 *     summary: Emitir Guía de Remisión Electrónica
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/EmitirGuiaRequest'
 *     responses:
 *       200:
 *         description: Guía emitida exitosamente.
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/EmitirGuiaResponse'
 *       400:
 *         description: Parámetros faltantes o inválidos.
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 *       500:
 *         description: Error al comunicarse con SUNAT.
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 */
router.post('/emitir-guia', async (req: Request, res: Response) => {
  const payload = req.body as EmitirGuiaPayload;

  if (!payload.id_empresa || !payload.tipo_guia || !payload.datos_traslado || !payload.bienes_transportados?.length) {
    return res.status(400).json({
      success: false,
      message: 'Faltan parámetros requeridos: id_empresa, tipo_guia, datos_traslado, bienes_transportados.',
    });
  }

  const empresaDoc = await db.collection('empresas').doc(payload.id_empresa).get();
  const empresa = empresaDoc.data();

  if (!empresa) {
    return res.status(400).json({
      success: false,
      message: `Empresa con id '${payload.id_empresa}' no encontrada en Firestore.`,
    });
  }

  if (!empresa.sunat_client_id) {
    return res.status(400).json({
      success: false,
      message: 'Esta empresa aún no tiene credenciales SUNAT configuradas. Ejecuta /api/setup-sunat primero.',
    });
  }

  const accessToken = await getAccessToken(payload.id_empresa);
  const serie = payload.tipo_guia === 'REMITENTE' ? 'T001' : 'V001';

  const correlativoSnap = await db.collection('correlativosGuias').doc(payload.id_empresa).get();
  const correlativo = (correlativoSnap.data()?.ultimo_correlativo ?? 0) + 1;

  const xmlContent = buildGuiaXml(payload, empresa.ruc as string, serie, correlativo);
  const numeroGuia = `${serie}-${String(correlativo).padStart(8, '0')}`;
  const xmlFilename = `${empresa.ruc}-09-${numeroGuia}.xml`;
  const fechaEmision = new Date().toLocaleDateString('es-PE');

  const gemResponse = await axios.post(
    `${env.sunat.gemUrl}/contribuyente/gem/comprobantes/guiaremision`,
    {
      archivo: {
        nomArchivo: xmlFilename,
        arcGrec: Buffer.from(xmlContent, 'utf-8').toString('base64'),
        hashZip: '',
      },
    },
    {
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
    }
  );

  const sunatResp = gemResponse.data;
  const estadoSunat = sunatResp.codRespuesta === '0' ? 'aceptada' : 'rechazada';

  const pdfBuffer = await generateGuiaPdf({
    payload,
    ruc: empresa.ruc as string,
    razonSocial: empresa.razon_social as string ?? empresa.ruc as string,
    numeroGuia,
    serie,
    correlativo,
    fechaEmision,
    estadoSunat,
  });

  const storageBasePath = `guias/${empresa.ruc}/${numeroGuia}`;

  const xmlFile = bucket.file(`${storageBasePath}/${xmlFilename}`);
  await xmlFile.save(Buffer.from(xmlContent, 'utf-8'), { contentType: 'application/xml' });
  const [xmlUrl] = await xmlFile.getSignedUrl({ action: 'read', expires: '2099-01-01' });

  const pdfFile = bucket.file(`${storageBasePath}/guia.pdf`);
  await pdfFile.save(pdfBuffer, { contentType: 'application/pdf' });
  const [pdfUrl] = await pdfFile.getSignedUrl({ action: 'read', expires: '2099-01-01' });

  let cdrUrl: string | null = null;
  if (sunatResp.arcCdr) {
    const cdrZipBuffer = Buffer.from(sunatResp.arcCdr as string, 'base64');
    const zip = new AdmZip(cdrZipBuffer);
    const cdrFile = bucket.file(`${storageBasePath}/cdr.zip`);
    await cdrFile.save(cdrZipBuffer, { contentType: 'application/zip' });
    const [signedCdrUrl] = await cdrFile.getSignedUrl({ action: 'read', expires: '2099-01-01' });
    cdrUrl = signedCdrUrl;
    zip;
  }

  await db.collection('correlativosGuias').doc(payload.id_empresa).set(
    { ultimo_correlativo: correlativo },
    { merge: true }
  );

  const guiaRef = await db.collection('guias').add({
    id_empresa: payload.id_empresa,
    numero_guia: numeroGuia,
    tipo_guia: payload.tipo_guia,
    estado_sunat: estadoSunat,
    datos_traslado: payload.datos_traslado,
    bienes_transportados: payload.bienes_transportados,
    sunat_codigo_respuesta: sunatResp.codRespuesta,
    sunat_descripcion: sunatResp.desRespuesta,
    url_pdf: pdfUrl,
    url_xml: xmlUrl,
    url_cdr: cdrUrl,
    qr_data: `${empresa.ruc}|09|${numeroGuia}|${payload.datos_traslado.fecha_inicio}`,
    emitida_at: new Date(),
  });

  return res.json({
    success: true,
    estado_sunat: estadoSunat,
    numero_guia: numeroGuia,
    guia_id: guiaRef.id,
    documentos: {
      url_pdf: pdfUrl,
      url_xml: xmlUrl,
      url_cdr: cdrUrl,
    },
    qr_data: `${empresa.ruc}|09|${numeroGuia}|${payload.datos_traslado.fecha_inicio}`,
  });
});

export default router;
