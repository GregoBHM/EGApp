# EGApp — Sistema de Guías de Remisión Electrónica (SUNAT)

Plataforma SaaS para la emisión de Guías de Remisión Electrónicas (GRE) sin necesidad de entrar al portal web de la SUNAT.

## Estructura del Proyecto (Monorepo)

```
EGApp/
├── backend/       → Servidor Node.js + Express + Playwright (El Motor)
├── app_web/       → Dashboard Next.js (Panel de Administración)
└── app_movil/     → Aplicación Flutter (App del Conductor)
```

## Tecnologías

| Capa | Tecnología |
|---|---|
| Backend | Node.js, Express, Playwright, BullMQ, Redis |
| Base de Datos | Firebase (Cloud Firestore) |
| Autenticación | Firebase Authentication |
| App Web | Next.js |
| App Móvil | Flutter (Dart) + Riverpod |

## Fases del Proyecto

- [x] Fase 0: Análisis y Diseño Arquitectónico
- [/] Fase 1: Infraestructura y Entorno
- [ ] Fase 2: Backend (El Motor)
- [ ] Fase 3: App Web (Dashboard)
- [ ] Fase 4: App Móvil (Flutter)
- [ ] Fase 5: Integración y Pruebas con SUNAT

## Normativa aplicable

- Resolución de Superintendencia N.° 097-2012/SUNAT (SEE)
- Resolución de Superintendencia N.° 255-2015/SUNAT (GRE por evento)
- Resolución de Superintendencia N.° 000108-2026/SUNAT (Última actualización)
