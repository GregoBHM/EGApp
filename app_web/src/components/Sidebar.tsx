'use client';

import Link from 'next/link';
import { useAuth } from '@/context/AuthContext';
import { useRouter } from 'next/navigation';

interface NavItem {
  href: string;
  label: string;
  icon: string;
}

const navItems: NavItem[] = [
  { href: '/dashboard', label: 'Resumen', icon: '◈' },
  { href: '/dashboard/guias', label: 'Guías emitidas', icon: '📄' },
  { href: '/dashboard/onboarding', label: 'Configurar SUNAT', icon: '⚙️' },
  { href: '/dashboard/empresas', label: 'Empresas', icon: '🏢' },
];

export default function Sidebar({ currentPath }: { currentPath: string }) {
  const { user, logout } = useAuth();
  const router = useRouter();

  const handleLogout = async () => {
    await logout();
    router.replace('/login');
  };

  return (
    <aside style={{
      width: '240px',
      minHeight: '100vh',
      background: '#0d0d14',
      borderRight: '1px solid #1e1e2e',
      display: 'flex',
      flexDirection: 'column',
      padding: '24px 16px',
      flexShrink: 0,
    }}>
      <div style={{ marginBottom: '32px', padding: '0 8px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
          <div style={{
            width: '36px',
            height: '36px',
            background: 'linear-gradient(135deg, #6366f1, #818cf8)',
            borderRadius: '10px',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            fontSize: '18px',
          }}>
            📋
          </div>
          <div>
            <div style={{ fontSize: '15px', fontWeight: '700', color: '#f1f5f9' }}>EGApp</div>
            <div style={{ fontSize: '11px', color: '#6366f1' }}>Motor SUNAT</div>
          </div>
        </div>
      </div>

      <nav style={{ display: 'flex', flexDirection: 'column', gap: '4px', flex: 1 }}>
        {navItems.map((item) => (
          <Link
            key={item.href}
            href={item.href}
            className={`sidebar-link ${currentPath === item.href ? 'active' : ''}`}
          >
            <span style={{ fontSize: '16px' }}>{item.icon}</span>
            {item.label}
          </Link>
        ))}
      </nav>

      <div style={{ borderTop: '1px solid #1e1e2e', paddingTop: '16px' }}>
        <div style={{ padding: '0 8px', marginBottom: '12px' }}>
          <div style={{ fontSize: '13px', color: '#f1f5f9', fontWeight: '500', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
            {user?.email}
          </div>
          <div style={{ fontSize: '11px', color: '#6366f1', marginTop: '2px' }}>Administrador</div>
        </div>
        <button className="sidebar-link" onClick={handleLogout} style={{ color: '#ef4444' }}>
          <span>↩</span> Cerrar sesión
        </button>
      </div>
    </aside>
  );
}
