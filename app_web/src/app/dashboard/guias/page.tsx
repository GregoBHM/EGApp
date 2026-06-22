'use client';

import { useEffect, useState } from 'react';
import { collection, query, orderBy, getDocs, Timestamp } from 'firebase/firestore';
import { db } from '@/lib/firebase';

interface Guia {
  id: string;
  numero_guia: string;
  tipo_guia: string;
  estado_sunat: string;
  id_empresa: string;
  sunat_descripcion?: string;
  emitida_at: Timestamp;
}

export default function GuiasPage() {
  const [guias, setGuias] = useState<Guia[]>([]);
  const [loading, setLoading] = useState(true);
  const [filtro, setFiltro] = useState('');

  useEffect(() => {
    const fetchGuias = async () => {
      try {
        const snap = await getDocs(query(collection(db, 'guias'), orderBy('emitida_at', 'desc')));
        setGuias(snap.docs.map((d) => ({ id: d.id, ...d.data() })) as Guia[]);
      } catch (err) {
        console.error('Error cargando guías:', err);
      } finally {
        setLoading(false);
      }
    };
    fetchGuias();
  }, []);

  const filtradas = guias.filter(
    (g) =>
      g.numero_guia?.toLowerCase().includes(filtro.toLowerCase()) ||
      g.id_empresa?.toLowerCase().includes(filtro.toLowerCase())
  );

  const estadoBadge = (estado: string) => {
    if (estado === 'aceptada') return <span className="badge badge-success">✓ Aceptada</span>;
    if (estado === 'rechazada') return <span className="badge badge-danger">✗ Rechazada</span>;
    return <span className="badge badge-warning">⏳ {estado}</span>;
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
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '32px' }}>
        <div>
          <h1 style={{ fontSize: '24px', fontWeight: '700', color: '#f1f5f9', margin: '0 0 6px' }}>
            Guías Emitidas
          </h1>
          <p style={{ color: '#94a3b8', fontSize: '14px', margin: 0 }}>
            {guias.length} guía{guias.length !== 1 ? 's' : ''} en total
          </p>
        </div>
        <input
          className="input-field"
          style={{ width: '260px' }}
          placeholder="Buscar por número o empresa..."
          value={filtro}
          onChange={(e) => setFiltro(e.target.value)}
        />
      </div>

      <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
        {filtradas.length === 0 ? (
          <div style={{ padding: '64px', textAlign: 'center', color: '#94a3b8' }}>
            <div style={{ fontSize: '48px', marginBottom: '16px' }}>📭</div>
            <div style={{ fontSize: '16px', fontWeight: '500', marginBottom: '8px' }}>Sin resultados</div>
            <div style={{ fontSize: '14px' }}>
              {filtro ? 'No hay guías que coincidan con tu búsqueda.' : 'Aún no hay guías emitidas.'}
            </div>
          </div>
        ) : (
          <table>
            <thead>
              <tr>
                <th>N° Guía</th>
                <th>Tipo</th>
                <th>Empresa</th>
                <th>Estado SUNAT</th>
                <th>Descripción</th>
                <th>Fecha</th>
              </tr>
            </thead>
            <tbody>
              {filtradas.map((g) => (
                <tr key={g.id}>
                  <td style={{ fontFamily: 'monospace', fontWeight: '600', color: '#818cf8' }}>
                    {g.numero_guia}
                  </td>
                  <td><span className="badge badge-info">{g.tipo_guia}</span></td>
                  <td style={{ color: '#94a3b8', fontFamily: 'monospace', fontSize: '12px' }}>{g.id_empresa}</td>
                  <td>{estadoBadge(g.estado_sunat)}</td>
                  <td style={{ color: '#94a3b8', fontSize: '12px', maxWidth: '200px', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                    {g.sunat_descripcion ?? '—'}
                  </td>
                  <td style={{ color: '#94a3b8', fontSize: '13px' }}>
                    {g.emitida_at?.toDate?.()?.toLocaleString('es-PE') ?? '—'}
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
