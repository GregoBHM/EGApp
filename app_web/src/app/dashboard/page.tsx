'use client';

import { useEffect, useState } from 'react';
import { collection, query, orderBy, limit, getDocs, where, Timestamp } from 'firebase/firestore';
import { db } from '@/lib/firebase';

interface StatData {
  totalGuias: number;
  guiasHoy: number;
  empresasActivas: number;
  guiasError: number;
}

interface GuiaReciente {
  id: string;
  numero_guia: string;
  tipo_guia: string;
  estado_sunat: string;
  id_empresa: string;
  emitida_at: Timestamp;
}

export default function DashboardPage() {
  const [stats, setStats] = useState<StatData>({ totalGuias: 0, guiasHoy: 0, empresasActivas: 0, guiasError: 0 });
  const [guiasRecientes, setGuiasRecientes] = useState<GuiaReciente[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const guiasSnap = await getDocs(collection(db, 'guias'));
        const total = guiasSnap.size;

        const hoy = new Date();
        hoy.setHours(0, 0, 0, 0);
        const guiasHoySnap = await getDocs(
          query(collection(db, 'guias'), where('emitida_at', '>=', Timestamp.fromDate(hoy)))
        );

        const empresasSnap = await getDocs(
          query(collection(db, 'empresas'), where('estado_onboarding', '==', 'completado'))
        );

        const errorSnap = await getDocs(
          query(collection(db, 'guias'), where('estado_sunat', '==', 'rechazada'))
        );

        setStats({
          totalGuias: total,
          guiasHoy: guiasHoySnap.size,
          empresasActivas: empresasSnap.size,
          guiasError: errorSnap.size,
        });

        const recentSnap = await getDocs(
          query(collection(db, 'guias'), orderBy('emitida_at', 'desc'), limit(8))
        );
        const recientes = recentSnap.docs.map((d) => ({ id: d.id, ...d.data() })) as GuiaReciente[];
        setGuiasRecientes(recientes);
      } catch (err) {
        console.error('Error cargando dashboard:', err);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, []);

  const estadoBadge = (estado: string) => {
    if (estado === 'aceptada') return <span className="badge badge-success">✓ Aceptada</span>;
    if (estado === 'rechazada') return <span className="badge badge-danger">✗ Rechazada</span>;
    return <span className="badge badge-warning">⏳ Pendiente</span>;
  };

  if (loading) {
    return (
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '60vh' }}>
        <div className="spinner" />
      </div>
    );
  }

  return (
    <div className="animate-in">
      <div style={{ marginBottom: '32px' }}>
        <h1 style={{ fontSize: '24px', fontWeight: '700', color: '#f1f5f9', margin: '0 0 6px' }}>
          Resumen General
        </h1>
        <p style={{ color: '#94a3b8', fontSize: '14px', margin: 0 }}>
          Vista general del sistema de guías de remisión electrónicas.
        </p>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '16px', marginBottom: '32px' }}>
        <div className="stat-card">
          <div style={{ fontSize: '28px' }}>📄</div>
          <div className="stat-number">{stats.totalGuias}</div>
          <div className="stat-label">Total de guías emitidas</div>
        </div>
        <div className="stat-card">
          <div style={{ fontSize: '28px' }}>🕐</div>
          <div className="stat-number">{stats.guiasHoy}</div>
          <div className="stat-label">Guías hoy</div>
        </div>
        <div className="stat-card">
          <div style={{ fontSize: '28px' }}>🏢</div>
          <div className="stat-number">{stats.empresasActivas}</div>
          <div className="stat-label">Empresas configuradas</div>
        </div>
        <div className="stat-card">
          <div style={{ fontSize: '28px' }}>⚠️</div>
          <div className="stat-number" style={{ color: stats.guiasError > 0 ? '#ef4444' : '#22c55e' }}>
            {stats.guiasError}
          </div>
          <div className="stat-label">Guías rechazadas</div>
        </div>
      </div>

      <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
        <div style={{ padding: '20px 24px', borderBottom: '1px solid #1e1e2e' }}>
          <h2 style={{ fontSize: '16px', fontWeight: '600', color: '#f1f5f9', margin: 0 }}>
            Guías recientes
          </h2>
        </div>

        {guiasRecientes.length === 0 ? (
          <div style={{ padding: '48px', textAlign: 'center', color: '#94a3b8' }}>
            <div style={{ fontSize: '48px', marginBottom: '16px' }}>📭</div>
            <div>Aún no hay guías emitidas.</div>
          </div>
        ) : (
          <table>
            <thead>
              <tr>
                <th>Número</th>
                <th>Tipo</th>
                <th>Empresa</th>
                <th>Estado</th>
                <th>Fecha</th>
              </tr>
            </thead>
            <tbody>
              {guiasRecientes.map((g) => (
                <tr key={g.id}>
                  <td style={{ fontFamily: 'monospace', fontWeight: '600', color: '#818cf8' }}>{g.numero_guia}</td>
                  <td><span className="badge badge-info">{g.tipo_guia}</span></td>
                  <td style={{ color: '#94a3b8' }}>{g.id_empresa}</td>
                  <td>{estadoBadge(g.estado_sunat)}</td>
                  <td style={{ color: '#94a3b8' }}>
                    {g.emitida_at?.toDate?.()?.toLocaleDateString('es-PE') ?? '—'}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}
