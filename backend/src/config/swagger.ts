import swaggerJsdoc from 'swagger-jsdoc';

const options: swaggerJsdoc.Options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'EGApp — Motor de Guías de Remisión SUNAT',
      version: '1.0.0',
      description: 'API Backend para emisión de Guías de Remisión Electrónicas (GRE) sin ingresar al portal SUNAT.',
      contact: {
        name: 'EGApp Dev Team',
      },
    },
    servers: [
      {
        url: '/',
        description: 'Servidor Actual',
      },
    ],
    tags: [
      { name: 'Sistema', description: 'Endpoints de estado del servidor' },
      { name: 'SUNAT - Onboarding', description: 'Configuración automática de credenciales SUNAT' },
      { name: 'SUNAT - Guías', description: 'Emisión de Guías de Remisión Electrónicas' },
    ],
    components: {
      schemas: {
        SuccessResponse: {
          type: 'object',
          properties: {
            success: { type: 'boolean', example: true },
          },
        },
        ErrorResponse: {
          type: 'object',
          properties: {
            success: { type: 'boolean', example: false },
            message: { type: 'string', example: 'Descripción del error.' },
          },
        },
        HealthResponse: {
          type: 'object',
          properties: {
            status: { type: 'string', example: 'ok' },
            project: { type: 'string', example: 'EGApp' },
            environment: { type: 'string', example: 'development' },
            timestamp: { type: 'string', format: 'date-time' },
          },
        },
        SetupSunatRequest: {
          type: 'object',
          required: ['id_empresa', 'ruc', 'usuario_sol', 'clave_sol'],
          properties: {
            id_empresa: { type: 'string', example: 'empresa_abc123' },
            ruc: { type: 'string', example: '20123456789' },
            usuario_sol: { type: 'string', example: 'MODDATOS' },
            clave_sol: { type: 'string', example: 'MiClaveSol123' },
          },
        },
        SetupSunatResponse: {
          type: 'object',
          properties: {
            success: { type: 'boolean', example: true },
            status: { type: 'string', example: 'processing_in_background' },
            message: { type: 'string', example: 'El proceso de configuración ha sido encolado.' },
          },
        },
        EmitirGuiaRequest: {
          type: 'object',
          required: ['id_empresa', 'tipo_guia', 'datos_traslado', 'bienes_transportados'],
          properties: {
            id_empresa: { type: 'string', example: 'empresa_abc123' },
            tipo_guia: {
              type: 'string',
              enum: ['REMITENTE', 'TRANSPORTISTA'],
              example: 'REMITENTE',
            },
            datos_traslado: {
              type: 'object',
              properties: {
                motivo_codigo: { type: 'string', example: '01' },
                modalidad: { type: 'string', enum: ['PRIVADO', 'PUBLICO'], example: 'PRIVADO' },
                fecha_inicio: { type: 'string', format: 'date', example: '2026-06-10' },
                peso_total_kg: { type: 'number', example: 1500 },
                punto_partida: {
                  type: 'object',
                  properties: {
                    ubigeo: { type: 'string', example: '150101' },
                    direccion: { type: 'string', example: 'Av. Industrial 123, Lima' },
                  },
                },
                punto_llegada: {
                  type: 'object',
                  nullable: true,
                  properties: {
                    ubigeo: { type: 'string', example: '040101' },
                    direccion: { type: 'string', example: 'Jr. Comercio 456, Arequipa' },
                  },
                },
              },
            },
            bienes_transportados: {
              type: 'array',
              items: {
                type: 'object',
                properties: {
                  codigo: { type: 'string', example: 'PROD001' },
                  descripcion: { type: 'string', example: 'Carga general - mercadería variada' },
                  cantidad: { type: 'number', example: 10 },
                  unidad_medida: { type: 'string', example: 'NIU' },
                },
              },
            },
          },
        },
        EmitirGuiaResponse: {
          type: 'object',
          properties: {
            success: { type: 'boolean', example: true },
            estado_sunat: { type: 'string', example: 'aceptada' },
            numero_guia: { type: 'string', example: 'T001-00000001' },
            url_pdf: { type: 'string', example: 'https://storage.firebase.com/egapp/guias/T001-00000001.pdf' },
            qr_data: { type: 'string', example: '20123456789|T001-00000001|...' },
          },
        },
      },
    },
  },
  apis: ['./src/routes/*.ts', './src/index.ts'],
};

export const swaggerSpec = swaggerJsdoc(options);
