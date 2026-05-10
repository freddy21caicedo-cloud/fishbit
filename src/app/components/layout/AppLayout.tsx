'use client';

import { useState, useEffect } from 'react';
import Link from "next/link";
import { usePathname } from "next/navigation";
import { supabase } from '@/lib/supabase';
import { useAuth } from '../providers/AuthProvider';
import { useUnit } from '../providers/UnitProvider';
import { 
  LayoutDashboard, 
  Waves, 
  ClipboardList, 
  Coins, 
  Settings, 
  HelpCircle,
  Fish,
  Package,
  Shield,
  LogOut,
  Menu,
  X
} from "lucide-react";

interface AppLayoutProps {
  children: React.ReactNode;
}

export default function AppLayout({ children }: AppLayoutProps) {
  const pathname = usePathname();
  const { session } = useAuth();
  const { activeUnit } = useUnit();
  const [width, setWidth] = useState(typeof window !== 'undefined' ? window.innerWidth : 1200);
  const [userRole, setUserRole] = useState<string | null>(null);
  const [isSuperAdmin, setIsSuperAdmin] = useState(false);
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);

  useEffect(() => {
    let timeoutId: NodeJS.Timeout;
    const handleResize = () => {
      clearTimeout(timeoutId);
      timeoutId = setTimeout(() => setWidth(window.innerWidth), 150);
    };
    window.addEventListener('resize', handleResize);
    return () => {
      window.removeEventListener('resize', handleResize);
      clearTimeout(timeoutId);
    };
  }, []);
  
  const handleLogout = async () => {
    await supabase.auth.signOut();
    localStorage.removeItem('active_unit_id');
    localStorage.removeItem('fishbit_last_active');
    window.location.href = '/';
  };

  useEffect(() => {
    if (!session?.user) return;
    const user = session.user;

    async function checkRole() {
      const userId = user.id;
      const [profileRes, unitRes] = await Promise.all([
        supabase.from('profiles').select('is_superadmin, role').eq('id', userId).single(),
        supabase.from('user_units').select('role').eq('user_id', userId).limit(1).single()
      ]);

      if (profileRes.data) {
        setIsSuperAdmin(profileRes.data.is_superadmin || false);
      }
      
      if (unitRes.data) {
        setUserRole(unitRes.data.role || profileRes.data?.role || 'operario');
      }
    }
    checkRole();
  }, [session?.user?.id]);

  const isMobile = width < 768;
  const isTablet = width >= 768 && width <= 1024;
  const isDesktop = width > 1024;

  const sidebarWidth = isDesktop ? '240px' : isTablet ? '64px' : '0px';
  const planType = activeUnit?.subscriptions?.plan_type || 'premium';

  const menuItems = [
    { label: 'Panel', icon: LayoutDashboard, href: '/dashboard', roles: ['admin', 'tecnico'] },
    { label: 'Estanques', icon: Waves, href: '/estanques', roles: ['admin', 'tecnico'] },
    { label: 'Registros', icon: ClipboardList, href: '/registros', roles: ['admin', 'tecnico', 'operario'] },
    { label: 'Almacén', icon: Package, href: '/almacen', roles: ['admin', 'tecnico'] },
    { label: 'Finanzas', icon: Coins, href: '/finanzas', roles: ['admin'] },
  ];

  const secondaryItems = [
    { label: 'Configuración', icon: Settings, href: '/configuracion', roles: ['admin', 'tecnico'] },
    { label: 'Centro de Ayuda', icon: HelpCircle, href: '/ayuda', roles: ['admin', 'tecnico', 'operario'] },
  ];

  const filteredMenu = isSuperAdmin 
    ? [{ label: 'SuperAdmin Hub', icon: Shield, href: '/superadmin' }]
    : menuItems.filter(item => item.roles.includes(userRole || ''));

  const filteredSecondary = isSuperAdmin
    ? [{ label: 'Configuración', icon: Settings, href: '/configuracion' }]
    : secondaryItems.filter(item => item.roles.includes(userRole || ''));

  return (
    <div style={{ display: 'flex', minHeight: '100vh', background: 'var(--background)' }}>
      {/* Mobile Menu Backdrop */}
      {isMobile && isMobileMenuOpen && (
        <div 
          onClick={() => setIsMobileMenuOpen(false)}
          style={{
            position: 'fixed',
            inset: 0,
            background: 'rgba(0,0,0,0.5)',
            zIndex: 998,
            backdropFilter: 'blur(4px)'
          }}
        />
      )}

      {/* Sidebar - Desktop, Tablet & Mobile Drawer */}
      <aside style={{
        width: isMobile ? '240px' : sidebarWidth,
        transform: isMobile ? (isMobileMenuOpen ? 'translateX(0)' : 'translateX(-100%)') : 'none',
        background: 'var(--card)',
        borderRight: '1px solid var(--border)',
        display: 'flex',
        flexDirection: 'column',
        position: 'fixed',
        height: '100vh',
        zIndex: 999,
        transition: 'transform 0.3s cubic-bezier(0.4, 0, 0.2, 1), width 0.3s ease',
        overflow: 'hidden',
        left: 0,
        top: 0
      }}>
        <div style={{ padding: '1.5rem', display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '1rem' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
            <div style={{ background: 'var(--primary)', minWidth: '32px', height: '32px', borderRadius: '8px', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'white' }}>
              <Fish size={20} />
            </div>
            {(isDesktop || isMobile) && (
              <div style={{ display: 'flex', flexDirection: 'column', gap: '0.1rem' }}>
                <span style={{ fontWeight: 900, fontSize: '1.4rem', lineHeight: 1.1, letterSpacing: '-0.03em' }}>FishBit</span>
                <span style={{ 
                  fontSize: '0.75rem', 
                  fontWeight: 900, 
                  textTransform: 'uppercase', 
                  letterSpacing: '0.08em',
                  color: planType.toLowerCase() === 'premium' ? '#b45309' : 'var(--muted-foreground)',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '6px',
                  marginTop: '0.2rem'
                }}>
                  <div style={{ width: '8px', height: '8px', borderRadius: '50%', background: planType.toLowerCase() === 'premium' ? '#f59e0b' : 'var(--muted-foreground)' }} />
                  PLAN {planType.toUpperCase()}
                </span>
                {isSuperAdmin && <span style={{ fontSize: '0.6rem', fontWeight: 900, color: 'var(--primary)', textTransform: 'uppercase', marginTop: '0.25rem' }}>SuperAdmin Hub</span>}
              </div>
            )}
          </div>
          {isMobile && (
            <button onClick={() => setIsMobileMenuOpen(false)} style={{ background: 'transparent', border: 'none', color: 'var(--muted-foreground)', cursor: 'pointer' }}>
              <X size={24} />
            </button>
          )}
        </div>

        <nav style={{ flex: 1, padding: '0.5rem', display: 'flex', flexDirection: 'column', gap: '0.25rem', overflowY: 'auto' }}>
          {filteredMenu.map((item) => {
            const Icon = item.icon;
            const active = pathname === item.href;
            return (
              <Link 
                key={item.href} 
                href={item.href}
                onClick={() => isMobile && setIsMobileMenuOpen(false)}
                className={`nav-item ${active ? 'active' : ''}`}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '0.75rem',
                  padding: '0.75rem',
                  borderRadius: '8px',
                  color: active ? 'var(--primary)' : 'var(--muted-foreground)',
                  background: active ? 'rgba(37, 99, 235, 0.1)' : 'transparent',
                  textDecoration: 'none',
                  fontWeight: active ? 700 : 500,
                  whiteSpace: 'nowrap'
                }}
                title={isTablet ? item.label : ''}
              >
                <Icon size={20} />
                {(isDesktop || isMobile) && <span>{item.label}</span>}
              </Link>
            );
          })}

          <div style={{ margin: '1rem 0.5rem', height: '1px', background: 'var(--border)', opacity: 0.5 }} />
          
          {filteredSecondary.map((item) => {
            const Icon = item.icon;
            const active = pathname === item.href;
            return (
              <Link 
                key={item.href} 
                href={item.href}
                onClick={() => isMobile && setIsMobileMenuOpen(false)}
                className={`nav-item ${active ? 'active' : ''}`}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '0.75rem',
                  padding: '0.75rem',
                  borderRadius: '8px',
                  color: active ? 'var(--primary)' : 'var(--muted-foreground)',
                  background: active ? 'rgba(37, 99, 235, 0.1)' : 'transparent',
                  textDecoration: 'none',
                  fontWeight: active ? 700 : 500,
                  whiteSpace: 'nowrap'
                }}
                title={isTablet ? item.label : ''}
              >
                <Icon size={20} />
                {(isDesktop || isMobile) && <span>{item.label}</span>}
              </Link>
            );
          })}
        </nav>

        <div style={{ padding: '0.5rem', borderTop: '1px solid var(--border)' }}>
          <button
            onClick={handleLogout}
            style={{
              width: '100%',
              display: 'flex',
              alignItems: 'center',
              gap: '0.75rem',
              padding: '0.75rem',
              borderRadius: '8px',
              color: '#ef4444',
              background: 'transparent',
              border: 'none',
              cursor: 'pointer',
              fontWeight: 600,
              whiteSpace: 'nowrap',
              transition: 'background 0.2s'
            }}
            onMouseEnter={(e) => e.currentTarget.style.background = 'rgba(239, 68, 68, 0.05)'}
            onMouseLeave={(e) => e.currentTarget.style.background = 'transparent'}
          >
            <LogOut size={20} />
            {(isDesktop || isMobile) && <span>Cerrar Sesión</span>}
          </button>
        </div>
      </aside>

      {/* Main Content */}
      <main style={{ 
        flex: 1, 
        marginLeft: isMobile ? '0' : sidebarWidth,
        transition: 'margin-left 0.3s ease'
      }}>
        {/* Mobile menu FAB toggle */}
        {isMobile && !isMobileMenuOpen && (
          <button 
            onClick={() => setIsMobileMenuOpen(true)}
            className="mobile-menu-fab"
            title="Abrir Menú"
          >
            <Menu size={24} />
          </button>
        )}
        {children}
      </main>

    </div>
  );
}
