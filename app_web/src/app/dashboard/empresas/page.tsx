'use client';

import { useEffect, useState } from 'react';
import { collection, getDocs, Timestamp } from 'firebase/firestore';
import { db } from '@/lib/firebase';

interface Empresa {
  id: string;
  ruc?: string;
  razon_social?: string;
  estado_onboarding?: string;
  onboarding_completado_at?: Timestamp;
  onboarding_error?: string;
}

export default function EmpresasPage() {
  const [empresas, setEmpresas] = useState<Empresa[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchEmpresas = async () => {
      try {
        const snap = await getDocs(collection(db, 'empresas'));
        setEmpresas(snap.docs.map((d) => ({ id: d.id, ...d.data() })) as Empresa[]);
      } catch (err) {
        console.error('Error cargando empresas:', err);
      } finally {
        setLoading(false);
      }
    };
    fetchEmpresas();
  }, []);

  const estadoBadge = (estado?: string) => {
    if (estado === 'completado') return <span className="badge badge-success">✓ Configurada</span>;
    if (estado === 'procesando') return <span className="badge badge-warning">⏳ Procesando</span>;
    if (estado === 'error') return <span className="badge badge-danger">✗ Error</span>;
    return <span className="badge badge-info">⬡ Pendiente</span>;
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
          Empresas
        </h1>
        <p style={{ color: '#94a3b8', fontSize: '14px', margin: 0 }}>
          {empresas.length} empresa{empresas.length !== 1 ? 's' : ''} registrada{empresas.length !== 1 ? 's' : ''}
        </p>
      </div>

      <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
        {empresas.length === 0 ? (
          <div style={{ padding: '64px', textAlign: 'center', color: '#94a3b8' }}>
            <div style={{ fontSize: '48px', marginBottom: '16px' }}>🏢</div>
            <div style={{ fontSize: '16px', fontWeight: '500', marginBottom: '8px' }}>Sin empresas</div>
            <div style={{ fontSize: '14px' }}>
              Crea documentos en la colección <code style={{ color: '#818cf8' }}>empresas</code> de Firestore.
            </div>
          </div>
        ) : (
          <table>
            <thead>
              <tr>
                <th>ID Empresa</th>
                <th>RUC</th>
                <th>Razón Social</th>
                <th>Estado SUNAT</th>
                <th>Configurada el</th>
                <th>Error</th>
              </tr>
            </thead>
            <tbody>
              {empresas.map((e) => (
                <tr key={e.id}>
                  <td style={{ fontFamily: 'monospace', fontSize: '12px', color: '#818cf8' }}>{e.id}</td>
                  <td style={{ fontFamily: 'monospace', fontWeight: '600' }}>{e.ruc ?? '—'}</td>
                  <td>{e.razon_social ?? '—'}</td>
                  <td>{estadoBadge(e.estado_onboarding)}</td>
                  <td style={{ color: '#94a3b8', fontSize: '13px' }}>
                    {e.onboarding_completado_at?.toDate?.()?.toLocaleDateString('es-PE') ?? '—'}
                  </td>
                  <td style={{ color: '#ef4444', fontSize: '12px', maxWidth: '180px', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                    {e.onboarding_error ?? '—'}
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
