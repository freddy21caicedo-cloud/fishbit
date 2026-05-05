'use client';

import { useEffect, useState } from 'react';
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
  Menu,
  X,
  Shield,
  Users,
  Globe,
  CreditCard,
  MessageSquare
} from "lucide-react";

export default function Sidebar() {
  const pathname = usePathname();
  const [isOpen, setIsOpen] = useState(false);
  const [isSuperAdmin, setIsSuperAdmin] = useState(false);

  const [userRole, setUserRole] = useState<string | null>(null);

  useEffect(() => {
    async function checkRole() {
      const { data: { user } } = await supabase.auth.getUser();
      if (user) {
        // 1. Perfil base
        const { data: profile } = await supabase
          .from('profiles')
          .select('is_superadmin, role')
          .eq('id', user.id)
          .single();
        
        setIsSuperAdmin(profile?.is_superadmin || false);

        // 2. Rol específico de la unidad (más preciso)
        const { data: userUnit } = await supabase
          .from('user_units')
          .select('role')
          .eq('user_id', user.id)
          .limit(1)
          .single();

        setUserRole(userUnit?.role || profile?.role || 'operario');
      }
    }
    checkRole();
  }, []);

  const toggleSidebar = () => setIsOpen(!isOpen);
  const closeSidebar = () => setIsOpen(false);

  return (
    <>
      {/* ... Mobile Toggle Button remains same ... */}
      <button 
        onClick={toggleSidebar}
        style={{
          position: 'fixed',
          top: '1.25rem',
          left: '1.25rem',
          zIndex: 110,
          background: isOpen ? 'transparent' : 'white',
          border: isOpen ? 'none' : '1px solid var(--border)',
          borderRadius: '10px',
          padding: '0.6rem',
          display: 'none', 
          alignItems: 'center',
          justifyContent: 'center',
          boxShadow: isOpen ? 'none' : 'var(--shadow-md)',
          cursor: 'pointer',
          color: isOpen ? 'white' : 'var(--foreground)',
          transition: 'all 0.3s ease'
        }}
        className="mobile-toggle"
      >
        {isOpen ? <X size={22} color="var(--muted-foreground)" /> : <Menu size={22} />}
      </button>

      {/* Backdrop for mobile */}
      {isOpen && (
        <div 
          onClick={closeSidebar}
          style={{
            position: 'fixed',
            inset: 0,
            background: 'rgba(15, 23, 42, 0.4)',
            backdropFilter: 'blur(8px)',
            zIndex: 90
          }}
        />
      )}

      <aside 
        className={`sidebar ${isOpen ? 'open' : ''}`}
        style={{ zIndex: 100 }}
      >
        <div style={{ 
          display: 'flex', 
          alignItems: 'center', 
          justifyContent: 'space-between',
          marginBottom: '2.5rem', 
          padding: '0 0.5rem' 
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
            <div style={{ 
              background: isSuperAdmin ? 'var(--primary)' : 'var(--primary)', 
              width: '36px', 
              height: '36px', 
              borderRadius: '8px',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              color: 'white'
            }}>
              {isSuperAdmin ? <Shield size={20} /> : <Fish size={20} />}
            </div>
            <h2 style={{ fontSize: '1.25rem', fontWeight: 700, margin: 0 }}>FishBit {isSuperAdmin && <span style={{ fontSize: '0.6rem', verticalAlign: 'middle', background: 'rgba(37, 99, 235, 0.1)', color: 'var(--primary)', padding: '2px 6px', borderRadius: '4px', marginLeft: '4px' }}>SA</span>}</h2>
          </div>
        </div>

        <nav style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
          {isSuperAdmin ? (
            <Link href="/superadmin" className={`nav-item ${pathname.startsWith('/superadmin') ? 'active' : ''}`} onClick={closeSidebar}>
              <LayoutDashboard size={20} />
              SuperAdmin Hub
            </Link>
          ) : (
            <>
              <Link href="/" className={`nav-item ${pathname === '/' ? 'active' : ''}`} onClick={closeSidebar}>
                <LayoutDashboard size={20} />
                Panel de Control
              </Link>
              
              <Link href="/estanques" className={`nav-item ${pathname === '/estanques' ? 'active' : ''}`} onClick={closeSidebar}>
                <Waves size={20} />
                Estanques
              </Link>
              
              <Link href="/registros" className={`nav-item ${pathname === '/registros' ? 'active' : ''}`} onClick={closeSidebar}>
                <ClipboardList size={20} />
                Registros
              </Link>

              {/* Vistas restringidas */}
              {userRole !== 'operario' && (
                <Link href="/almacen" className={`nav-item ${pathname === '/almacen' ? 'active' : ''}`} onClick={closeSidebar}>
                  <Package size={20} />
                  Almacén
                </Link>
              )}

              {userRole === 'admin' && (
                <Link href="/finanzas" className={`nav-item ${pathname === '/finanzas' ? 'active' : ''}`} onClick={closeSidebar}>
                  <Coins size={20} />
                  Finanzas
                </Link>
              )}
            </>
          )}
        </nav>

        {!isSuperAdmin && (
          <div style={{ marginTop: 'auto', display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
            {/* Solo Admin y Técnico entran a Configuración (con sus respectivas vistas internas) */}
            {userRole !== 'operario' && (
              <Link href="/configuracion" className={`nav-item ${pathname === '/configuracion' ? 'active' : ''}`} onClick={closeSidebar}>
                <Settings size={20} />
                Configuración
              </Link>
            )}
            <Link href="/ayuda" className={`nav-item ${pathname === '/ayuda' ? 'active' : ''}`} onClick={closeSidebar}>
              <HelpCircle size={20} />
              Centro de Ayuda
            </Link>
          </div>
        )}
      </aside>
    </>
  );
}
