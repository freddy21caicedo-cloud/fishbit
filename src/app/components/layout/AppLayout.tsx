'use client';

import { useState, useEffect } from 'react';
import Link from "next/link";
import { usePathname } from "next/navigation";
import { supabase } from '@/lib/supabase';
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
  Home
} from "lucide-react";

interface AppLayoutProps {
  children: React.ReactNode;
}

export default function AppLayout({ children }: AppLayoutProps) {
  const pathname = usePathname();
  const [width, setWidth] = useState(typeof window !== 'undefined' ? window.innerWidth : 1200);
  const [userRole, setUserRole] = useState<string | null>(null);
  const [isSuperAdmin, setIsSuperAdmin] = useState(false);
  const [planType, setPlanType] = useState('basic');

  useEffect(() => {
    const handleResize = () => setWidth(window.innerWidth);
    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, []);

  useEffect(() => {
    async function checkRole() {
      const { data: { user } } = await supabase.auth.getUser();
      if (user) {
        const { data: profile } = await supabase.from('profiles').select('is_superadmin, role').eq('id', user.id).single();
        setIsSuperAdmin(profile?.is_superadmin || false);
        
        const { data: userUnit } = await supabase.from('user_units').select('role, unit_id').eq('user_id', user.id).limit(1).single();
        setUserRole(userUnit?.role || profile?.role || 'operario');

        const activeUnitId = localStorage.getItem('active_unit_id') || userUnit?.unit_id;
        if (activeUnitId) {
          const { data: sub } = await supabase.from('subscriptions').select('plan_type').eq('unit_id', activeUnitId).single();
          if (sub) setPlanType(sub.plan_type);
        }
      }
    }
    checkRole();
  }, []);

  const isMobile = width < 768;
  const isTablet = width >= 768 && width <= 1024;
  const isDesktop = width > 1024;

  const sidebarWidth = isDesktop ? '240px' : isTablet ? '64px' : '0px';

  const menuItems = [
    { label: 'Panel', icon: LayoutDashboard, href: '/', roles: ['admin', 'tecnico'] },
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

  const handleLogout = async () => {
    await supabase.auth.signOut();
    localStorage.removeItem('active_unit_id');
    window.location.href = '/login';
  };

  return (
    <div style={{ display: 'flex', minHeight: '100vh', background: 'var(--background)' }}>
      {/* Sidebar - Desktop & Tablet */}
      {!isMobile && (
        <aside style={{
          width: sidebarWidth,
          background: 'var(--card)',
          borderRight: '1px solid var(--border)',
          display: 'flex',
          flexDirection: 'column',
          position: 'fixed',
          height: '100vh',
          zIndex: 100,
          transition: 'width 0.3s ease',
          overflow: 'hidden'
        }}>
          <div style={{ padding: '1.5rem', display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '1rem' }}>
            <div style={{ background: 'var(--primary)', minWidth: '32px', height: '32px', borderRadius: '8px', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'white' }}>
              <Fish size={20} />
            </div>
            {isDesktop && (
              <div style={{ display: 'flex', flexDirection: 'column', gap: '0.1rem' }}>
                <span style={{ fontWeight: 900, fontSize: '1.4rem', lineHeight: 1.1, letterSpacing: '-0.03em' }}>FishBit</span>
                <span style={{ 
                  fontSize: '0.75rem', 
                  fontWeight: 900, 
                  textTransform: 'uppercase', 
                  letterSpacing: '0.08em',
                  color: (planType || 'premium').toLowerCase() === 'premium' ? '#b45309' : 'var(--muted-foreground)',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '6px',
                  marginTop: '0.2rem'
                }}>
                  <div style={{ width: '8px', height: '8px', borderRadius: '50%', background: (planType || 'premium').toLowerCase() === 'premium' ? '#f59e0b' : 'var(--muted-foreground)' }} />
                  PLAN {(planType || 'PREMIUM').toUpperCase()}
                </span>
                {isSuperAdmin && <span style={{ fontSize: '0.6rem', fontWeight: 900, color: 'var(--primary)', textTransform: 'uppercase', marginTop: '0.25rem' }}>SuperAdmin Hub</span>}
              </div>
            )}
          </div>

          <nav style={{ flex: 1, padding: '0.5rem', display: 'flex', flexDirection: 'column', gap: '0.25rem' }}>
            {filteredMenu.map((item) => {
              const Icon = item.icon;
              const active = pathname === item.href;
              return (
                <Link 
                  key={item.href} 
                  href={item.href}
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
                  {isDesktop && <span>{item.label}</span>}
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
                  {isDesktop && <span>{item.label}</span>}
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
              {isDesktop && <span>Cerrar Sesión</span>}
            </button>
          </div>
        </aside>
      )}

      {/* Main Content */}
      <main style={{ 
        flex: 1, 
        marginLeft: isMobile ? '0' : sidebarWidth,
        paddingBottom: isMobile ? '70px' : '0',
        transition: 'margin-left 0.3s ease'
      }}>
        {children}
      </main>

      {/* Bottom Navigation - Mobile Only */}
      {isMobile && (
        <nav style={{
          position: 'fixed',
          bottom: 0,
          left: 0,
          right: 0,
          height: '64px',
          background: 'rgba(255, 255, 255, 0.8)',
          backdropFilter: 'blur(10px)',
          borderTop: '1px solid var(--border)',
          display: 'flex',
          justifyContent: 'space-around',
          alignItems: 'center',
          zIndex: 1000,
          padding: '0 0.5rem'
        }}>
          {filteredMenu.slice(0, 4).map((item) => {
            const Icon = item.icon;
            const active = pathname === item.href;
            return (
              <Link 
                key={item.href} 
                href={item.href}
                style={{
                  display: 'flex',
                  flexDirection: 'column',
                  alignItems: 'center',
                  gap: '4px',
                  color: active ? 'var(--primary)' : 'var(--muted-foreground)',
                  textDecoration: 'none',
                  fontSize: '0.65rem',
                  fontWeight: 800,
                  flex: 1
                }}
              >
                <Icon size={20} />
                <span>{item.label.split(' ')[0]}</span>
              </Link>
            );
          })}
          <button
            onClick={handleLogout}
            style={{
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              gap: '4px',
              color: '#ef4444',
              background: 'transparent',
              border: 'none',
              fontSize: '0.65rem',
              fontWeight: 800,
              flex: 1
            }}
          >
            <LogOut size={20} />
            <span>Salir</span>
          </button>
        </nav>
      )}
    </div>
  );
}
