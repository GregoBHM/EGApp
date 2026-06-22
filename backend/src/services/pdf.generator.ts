import { chromium } from 'playwright';
import QRCode from 'qrcode';
import { EmitirGuiaPayload, motivoMap } from './sunat.xml.builder';

interface PdfGuiaOptions {
  payload: EmitirGuiaPayload;
  ruc: string;
  razonSocial: string;
  numeroGuia: string;
  serie: string;
  correlativo: number;
  fechaEmision: string;
  estadoSunat: string;
}

async function generateGuiaPdf(options: PdfGuiaOptions): Promise<Buffer> {
  const { payload, ruc, razonSocial, numeroGuia, fechaEmision, estadoSunat } = options;
  const traslado = payload.datos_traslado;

  const qrString = `${ruc}|09|${numeroGuia}|${traslado.fecha_inicio}`;
  const qrDataUrl = await QRCode.toDataURL(qrString, { width: 150, margin: 1 });

  const bienesList = payload.bienes_transportados
    .map(
      (b, i) => `
      <tr class="${i % 2 === 0 ? 'even' : 'odd'}">
        <td>${b.codigo}</td>
        <td>${b.descripcion}</td>
        <td>${b.unidad_medida}</td>
        <td style="text-align:center">${b.cantidad}</td>
      </tr>`
    )
    .join('');

  const estadoColor = estadoSunat === 'aceptada' ? '#16a34a' : '#dc2626';
  const estadoLabel = estadoSunat === 'aceptada' ? '✓ ACEPTADA POR SUNAT' : '✗ RECHAZADA POR SUNAT';
  const motivoLabel = motivoMap[traslado.motivo_codigo] ?? 'OTROS';
  const modalidadLabel = traslado.modalidad === 'PRIVADO' ? 'Transporte Privado' : 'Transporte Público';

  const html = `<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8"/>
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { font-family: 'Arial', sans-serif; font-size: 11px; color: #111; background: #fff; padding: 24px; }
  .header { display: flex; justify-content: space-between; align-items: flex-start; padding-bottom: 16px; border-bottom: 2px solid #4f46e5; margin-bottom: 16px; }
  .logo-area { display: flex; flex-direction: column; gap: 2px; }
  .logo-title { font-size: 22px; font-weight: 800; color: #4f46e5; letter-spacing: -1px; }
  .logo-subtitle { font-size: 10px; color: #6b7280; }
  .company-box { text-align: right; }
  .company-name { font-size: 13px; font-weight: 700; }
  .company-ruc { font-size: 11px; color: #6b7280; }
  .doc-box { border: 2px solid #4f46e5; border-radius: 8px; padding: 10px 16px; text-align: center; margin-top: 8px; }
  .doc-type { font-size: 10px; color: #4f46e5; font-weight: 600; text-transform: uppercase; letter-spacing: 0.05em; }
  .doc-number { font-size: 16px; font-weight: 800; color: #111; }
  .status-badge { display: inline-block; background: ${estadoColor}; color: #fff; font-size: 10px; font-weight: 700; padding: 3px 10px; border-radius: 999px; margin-top: 4px; }
  .section { margin-bottom: 14px; }
  .section-title { font-size: 10px; font-weight: 700; color: #4f46e5; text-transform: uppercase; letter-spacing: 0.08em; margin-bottom: 6px; padding-bottom: 3px; border-bottom: 1px solid #e5e7eb; }
  .info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 6px 20px; }
  .info-row { display: flex; flex-direction: column; gap: 1px; }
  .info-label { font-size: 9px; color: #9ca3af; text-transform: uppercase; letter-spacing: 0.05em; }
  .info-value { font-size: 11px; color: #111; font-weight: 500; }
  .addresses { display: grid; grid-template-columns: 1fr auto 1fr; gap: 12px; align-items: center; margin-bottom: 14px; }
  .addr-box { background: #f9fafb; border: 1px solid #e5e7eb; border-radius: 6px; padding: 10px; }
  .addr-label { font-size: 9px; font-weight: 700; color: #4f46e5; text-transform: uppercase; margin-bottom: 4px; }
  .arrow { font-size: 20px; color: #9ca3af; text-align: center; }
  table { width: 100%; border-collapse: collapse; font-size: 10px; }
  thead tr { background: #4f46e5; color: white; }
  thead th { padding: 7px 10px; text-align: left; font-weight: 600; font-size: 9px; text-transform: uppercase; }
  tbody tr.even { background: #f9fafb; }
  tbody tr.odd { background: #fff; }
  tbody td { padding: 7px 10px; border-bottom: 1px solid #e5e7eb; }
  .footer { display: flex; justify-content: space-between; align-items: flex-end; margin-top: 20px; padding-top: 16px; border-top: 1px solid #e5e7eb; }
  .qr-area { text-align: center; }
  .qr-label { font-size: 9px; color: #9ca3af; margin-top: 4px; }
  .legal-text { font-size: 9px; color: #9ca3af; max-width: 360px; line-height: 1.5; }
</style>
</head>
<body>
  <div class="header">
    <div class="logo-area">
      <div class="logo-title">EGApp</div>
      <div class="logo-subtitle">Motor de Comprobantes Electrónicos</div>
    </div>
    <div class="company-box">
      <div class="company-name">${razonSocial}</div>
      <div class="company-ruc">RUC: ${ruc}</div>
      <div class="doc-box">
        <div class="doc-type">Guía de Remisión Electrónica</div>
        <div class="doc-number">${numeroGuia}</div>
        <div class="status-badge">${estadoLabel}</div>
      </div>
    </div>
  </div>

  <div class="section">
    <div class="section-title">Datos del Traslado</div>
    <div class="info-grid">
      <div class="info-row"><span class="info-label">Motivo</span><span class="info-value">${motivoLabel}</span></div>
      <div class="info-row"><span class="info-label">Fecha de inicio</span><span class="info-value">${traslado.fecha_inicio}</span></div>
      <div class="info-row"><span class="info-label">Modalidad</span><span class="info-value">${modalidadLabel}</span></div>
      <div class="info-row"><span class="info-label">Peso bruto (kg)</span><span class="info-value">${traslado.peso_total_kg}</span></div>
      ${traslado.placa_vehiculo ? `<div class="info-row"><span class="info-label">Placa vehículo</span><span class="info-value">${traslado.placa_vehiculo}</span></div>` : ''}
      <div class="info-row"><span class="info-label">Fecha de emisión</span><span class="info-value">${fechaEmision}</span></div>
    </div>
  </div>

  <div class="addresses">
    <div class="addr-box">
      <div class="addr-label">📍 Origen</div>
      <div class="info-value">${traslado.punto_partida.ubigeo} — ${traslado.punto_partida.direccion}</div>
    </div>
    <div class="arrow">→</div>
    <div class="addr-box">
      <div class="addr-label">📍 Destino</div>
      <div class="info-value">${traslado.punto_llegada?.ubigeo ?? '—'} — ${traslado.punto_llegada?.direccion ?? '—'}</div>
    </div>
  </div>

  <div class="section">
    <div class="section-title">Bienes Transportados</div>
    <table>
      <thead>
        <tr>
          <th>Código</th>
          <th>Descripción</th>
          <th>Unidad</th>
          <th>Cantidad</th>
        </tr>
      </thead>
      <tbody>${bienesList}</tbody>
    </table>
  </div>

  <div class="footer">
    <div class="legal-text">
      Representación impresa generada por EGApp.<br/>
      Verificar autenticidad en: <strong>www.sunat.gob.pe</strong><br/>
      Emisión: ${fechaEmision} | RUC Emisor: ${ruc}
    </div>
    <div class="qr-area">
      <img src="${qrDataUrl}" width="100" height="100" />
      <div class="qr-label">Código QR SUNAT</div>
    </div>
  </div>
</body>
</html>`;

  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  await page.setContent(html, { waitUntil: 'networkidle' });
  const pdfBuffer = await page.pdf({
    format: 'A4',
    margin: { top: '0', bottom: '0', left: '0', right: '0' },
    printBackground: true,
  });
  await browser.close();

  return Buffer.from(pdfBuffer);
}

export { generateGuiaPdf, PdfGuiaOptions };
