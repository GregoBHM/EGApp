export interface DatosTraslado {
  motivo_codigo: string;
  motivo_descripcion?: string; // Para el motivo '13' (Otros)
  modalidad: 'PRIVADO' | 'PUBLICO';
  fecha_inicio: string;
  peso_total_kg: number;
  punto_partida: { ubigeo: string; direccion: string };
  punto_llegada: { ubigeo: string; direccion: string } | null;
  // Campos Transporte Privado
  placa_vehiculo?: string;
  dni_chofer?: string;
  // Campos Transporte Público
  ruc_transportista?: string;
  razon_social_transportista?: string;
}

export interface BienTransportado {
  codigo: string;
  descripcion: string;
  cantidad: number;
  unidad_medida: string;
}

export interface EmitirGuiaPayload {
  id_empresa: string;
  tipo_guia: 'REMITENTE' | 'TRANSPORTISTA';
  datos_traslado: DatosTraslado;
  bienes_transportados: BienTransportado[];
}

export interface GuiaEmitidaResult {
  numero_guia: string;
  estado_sunat: string;
  url_pdf: string;
  qr_data: string;
}

export const motivoMap: Record<string, string> = {
  '01': 'VENTA',
  '02': 'COMPRA',
  '03': 'VENTA CON ENTREGA A TERCEROS',
  '04': 'TRASLADO ENTRE ESTABLECIMIENTOS DE LA MISMA EMPRESA',
  '08': 'IMPORTACION',
  '09': 'EXPORTACION',
  '13': 'OTROS',
  '14': 'VENTA SUJETA A CONFIRMACION DEL COMPRADOR',
  '18': 'TRASLADO EMISOR ITINERANTE CP',
  '19': 'TRASLADO A ZONA PRIMARIA',
  '21': 'DEVOLUCION',
  '22': 'RECOJO DE BIENES TRANSFORMADOS',
  '23': 'TRASLADO POR RECAUDACION (SUNAT)',
  '24': 'TRASLADO POR DEVOLUCION (RECAUDACION)',
};

export function buildGuiaXml(
  payload: EmitirGuiaPayload,
  ruc: string,
  serie: string,
  correlativo: number
): string {
  const numeroDoc = `${serie}-${String(correlativo).padStart(8, '0')}`;
  const motivoDescripcion = motivoMap[payload.datos_traslado.motivo_codigo] ?? 'OTROS';

  const items = payload.bienes_transportados.map((bien, i) => `
    <cac:DespatchLine>
      <cbc:ID>${i + 1}</cbc:ID>
      <cbc:DeliveredQuantity unitCode="${bien.unidad_medida}">${bien.cantidad}</cbc:DeliveredQuantity>
      <cac:Item>
        <cbc:Name><![CDATA[${bien.descripcion}]]></cbc:Name>
        <cac:SellersItemIdentification>
          <cbc:ID>${bien.codigo}</cbc:ID>
        </cac:SellersItemIdentification>
      </cac:Item>
    </cac:DespatchLine>`).join('');

  return `<?xml version="1.0" encoding="UTF-8"?>
<DespatchAdvice xmlns="urn:oasis:names:specification:ubl:schema:xsd:DespatchAdvice-2"
  xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"
  xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2"
  xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
  <cbc:UBLVersionID>2.1</cbc:UBLVersionID>
  <cbc:CustomizationID>2.0</cbc:CustomizationID>
  <cbc:ID>${numeroDoc}</cbc:ID>
  <cbc:IssueDate>${payload.datos_traslado.fecha_inicio}</cbc:IssueDate>
  <cbc:IssueTime>00:00:00</cbc:IssueTime>
  <cbc:DespatchAdviceTypeCode listAgencyName="PE:SUNAT" listName="Tipo de Documento" listURI="urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo01">09</cbc:DespatchAdviceTypeCode>
  <cbc:Note><![CDATA[${motivoDescripcion}]]></cbc:Note>
  <cac:Shipment>
    <cbc:ID>SUNAT</cbc:ID>
    <cbc:HandlingCode listAgencyName="PE:SUNAT" listName="Motivo de traslado" listURI="urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo20">${payload.datos_traslado.motivo_codigo}</cbc:HandlingCode>
    <cbc:GrossWeightMeasure unitCode="KGM">${payload.datos_traslado.peso_total_kg}</cbc:GrossWeightMeasure>
    <cbc:SplitConsignmentIndicator>false</cbc:SplitConsignmentIndicator>
    <cac:ShipmentStage>
      <cbc:TransportModeCode listAgencyName="PE:SUNAT" listName="Modalidad de traslado" listURI="urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo18">${payload.datos_traslado.modalidad === 'PRIVADO' ? '02' : '01'}</cbc:TransportModeCode>
      <cac:TransitPeriod>
        <cbc:StartDate>${payload.datos_traslado.fecha_inicio}</cbc:StartDate>
      </cac:TransitPeriod>
${payload.datos_traslado.modalidad === 'PRIVADO' ? `      <cac:TransportMeans>
        <cac:RoadTransport>
          <cbc:LicensePlateID>${payload.datos_traslado.placa_vehiculo ?? ''}</cbc:LicensePlateID>
        </cac:RoadTransport>
      </cac:TransportMeans>
      <cac:DriverPerson>
        <cbc:ID schemeID="1">${payload.datos_traslado.dni_chofer ?? ''}</cbc:ID>
      </cac:DriverPerson>` : `      <cac:CarrierParty>
        <cac:PartyIdentification>
          <cbc:ID schemeID="6">${payload.datos_traslado.ruc_transportista ?? ''}</cbc:ID>
        </cac:PartyIdentification>
        <cac:PartyName>
          <cbc:Name><![CDATA[${payload.datos_traslado.razon_social_transportista ?? ''}]]></cbc:Name>
        </cac:PartyName>
      </cac:CarrierParty>`}
    </cac:ShipmentStage>
    <cac:Delivery>
      <cac:DeliveryAddress>
        <cbc:ID schemeName="Ubigeos" schemeAgencyName="PE:INEI">${payload.datos_traslado.punto_llegada?.ubigeo ?? ''}</cbc:ID>
        <cbc:StreetName><![CDATA[${payload.datos_traslado.punto_llegada?.direccion ?? ''}]]></cbc:StreetName>
      </cac:DeliveryAddress>
    </cac:Delivery>
    <cac:OriginAddress>
      <cbc:ID schemeName="Ubigeos" schemeAgencyName="PE:INEI">${payload.datos_traslado.punto_partida.ubigeo}</cbc:ID>
      <cbc:StreetName><![CDATA[${payload.datos_traslado.punto_partida.direccion}]]></cbc:StreetName>
    </cac:OriginAddress>
  </cac:Shipment>
  <cac:DespatchSupplierParty>
    <cbc:CustomerAssignedAccountID>${ruc}</cbc:CustomerAssignedAccountID>
    <cac:Party>
      <cac:PartyIdentification>
        <cbc:ID schemeID="6" schemeName="Documento de Identidad" schemeAgencyName="PE:SUNAT">${ruc}</cbc:ID>
      </cac:PartyIdentification>
    </cac:Party>
  </cac:DespatchSupplierParty>${items}
</DespatchAdvice>`;
}
