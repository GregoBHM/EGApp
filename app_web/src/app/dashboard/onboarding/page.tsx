'use client';

import { useState, FormEvent } from 'react';

interface FormData {
  id_empresa: string;
  ruc: string;
  usuario_sol: string;
  clave_sol: string;
}

type StatusType = 'idle' | 'loading' | 'success' | 'error';

export default function OnboardingPage() {
  const [form, setForm] = useState<FormData>({ id_empresa: '', ruc: '', usuario_sol: '', clave_sol: '' });
  const [status, setStatus] = useState<StatusType>('idle');
  const [message, setMessage] = useState('');

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setForm({ ...form, [e.target.name]: e.target.value });
  };

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setStatus('loading');
    setMessage('');

    try {
      const res = await fetch(`${process.env.NEXT_PUBLIC_BACKEND_URL}/api/setup-sunat`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(form),
      });

      const data = await res.json();

      if (res.ok) {
        setStatus('success');
        setMessage('El bot está procesando las credenciales en segundo plano. El estado se actualizará automáticamente en Firestore.');
        setForm({ id_empresa: '', ruc: '', usuario_sol: '', clave_sol: '' });
      } else {
        setStatus('error');
        setMessage(data.message ?? 'Error desconocido.');
      }
    } catch {
      setStatus('error');
      setMessage('No se pudo conectar con el backend. Verifica que esté corriendo en http://localhost:3000.');
    }
  };

  const fields: { name: keyof FormData; label: string; placeholder: string; type?: string }[] = [
    { name: 'id_empresa', label: 'ID Empresa (Firestore)', placeholder: 'empresa_abc123' },
    { name: 'ruc', label: 'RUC', placeholder: '20123456789' },
    { name: 'usuario_sol', label: 'Usuario SOL', placeholder: 'MODDATOS' },
    { name: 'clave_sol', label: 'Clave SOL', placeholder: '••••••••', type: 'password' },
  ];

  return (
    <div className="animate-in" style={{ maxWidth: '600px' }}>
      <div style={{ marginBottom: '32px' }}>
        <h1 style={{ fontSize: '24px', fontWeight: '700', color: '#f1f5f9', margin: '0 0 6px' }}>
          Configurar SUNAT
        </h1>
        <p style={{ color: '#94a3b8', fontSize: '14px', margin: 0 }}>
          El bot ingresará automáticamente al portal SUNAT y obtendrá las credenciales API de la empresa.
        </p>
      </div>

      <div className="card" style={{
        marginBottom: '20px',
        background: 'rgba(99,102,241,0.05)',
        borderColor: 'rgba(99,102,241,0.3)',
      }}>
        <div style={{ display: 'flex', gap: '12px', alignItems: 'flex-start' }}>
          <span style={{ fontSize: '20px' }}>ℹ️</span>
          <div style={{ fontSize: '13px', color: '#94a3b8', lineHeight: '1.6' }}>
            <strong style={{ color: '#818cf8' }}>¿Cómo funciona?</strong><br />
            Al enviar este formulario, el servidor encola un trabajo en segundo plano. Un bot de Playwright
            abre el portal SUNAT, navega hasta la sección de credenciales API y extrae el{' '}
            <code style={{ color: '#818cf8' }}>client_id</code> y{' '}
            <code style={{ color: '#818cf8' }}>client_secret</code>, que se guardan encriptados con AES-256.
          </div>
        </div>
      </div>

      <div className="card">
        <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '18px' }}>
          {fields.map((f) => (
            <div key={f.name}>
              <label style={{ display: 'block', fontSize: '13px', fontWeight: '500', color: '#94a3b8', marginBottom: '6px' }}>
                {f.label}
              </label>
              <input
                name={f.name}
                type={f.type ?? 'text'}
                className="input-field"
                placeholder={f.placeholder}
                value={form[f.name]}
                onChange={handleChange}
                required
              />
            </div>
          ))}

          {status === 'success' && (
            <div style={{
              background: 'rgba(34,197,94,0.1)',
              border: '1px solid rgba(34,197,94,0.3)',
              borderRadius: '8px',
              padding: '14px',
              fontSize: '13px',
              color: '#22c55e',
              display: 'flex',
              gap: '10px',
            }}>
              <span>✅</span> {message}
            </div>
          )}

          {status === 'error' && (
            <div style={{
              background: 'rgba(239,68,68,0.1)',
              border: '1px solid rgba(239,68,68,0.3)',
              borderRadius: '8px',
              padding: '14px',
              fontSize: '13px',
              color: '#ef4444',
              display: 'flex',
              gap: '10px',
            }}>
              <span>❌</span> {message}
            </div>
          )}

          <button type="submit" className="btn-primary" disabled={status === 'loading'}>
            {status === 'loading' ? (
              <><div className="spinner" /> Procesando...</>
            ) : (
              <>⚙️ Iniciar configuración</>
            )}
          </button>
        </form>
      </div>
    </div>
  );
}
