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
  MessageSquare,
  LogOut
} from "lucide-react";

export default function Sidebar() {
  const pathname = usePathname();
  const [isOpen, setIsOpen] = useState(false);
  const [isSuperAdmin, setIsSuperAdmin] = useState(false);

  const [userRole, setUserRole] = useState<string | null>(null);
  const [planType, setPlanType] = useState<string>('basic');

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
          .select('role, unit_id')
          .eq('user_id', user.id)
          .limit(1)
          .single();

        setUserRole(userUnit?.role || profile?.role || 'operario');

        // 3. Obtener plan de la unidad activa
        let activeUnitId = localStorage.getItem('active_unit_id');
        if (!activeUnitId && userUnit) {
          activeUnitId = userUnit.unit_id;
        }

        if (activeUnitId) {
          const { data: subscription } = await supabase
            .from('subscriptions')
            .select('plan_type')
            .eq('unit_id', activeUnitId)
            .single();
          
          if (subscription) {
            setPlanType(subscription.plan_type);
          }
        }
      }
    }
    checkRole();
  }, []);

  const handleSignOut = async () => {
    await supabase.auth.signOut();
    localStorage.removeItem('active_unit_id');
    window.location.href = '/login';
  };

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
          left: isOpen ? '230px' : '1.25rem', // Se desplaza con el sidebar si está abierto
          zIndex: 110,
          background: isOpen ? 'white' : 'white',
          border: '1px solid var(--border)',
          borderRadius: '10px',
          padding: '0.6rem',
          display: 'none', 
          alignItems: 'center',
          justifyContent: 'center',
          boxShadow: 'var(--shadow-md)',
          cursor: 'pointer',
          color: 'var(--foreground)',
          transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)'
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
          padding: '0.5rem 0.5rem' 
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
            <div style={{ display: 'flex', flexDirection: 'column' }}>
              <h2 style={{ fontSize: '1.1rem', fontWeight: 700, margin: 0 }}>FishBit {isSuperAdmin && <span style={{ fontSize: '0.6rem', verticalAlign: 'middle', background: 'rgba(37, 99, 235, 0.1)', color: 'var(--primary)', padding: '2px 6px', borderRadius: '4px', marginLeft: '4px' }}>SA</span>}</h2>
              {!isSuperAdmin && (
                <span style={{ 
                  fontSize: '0.6rem', 
                  fontWeight: 900, 
                  textTransform: 'uppercase', 
                  letterSpacing: '0.05em',
                  color: planType === 'premium' ? '#d97706' : 'var(--muted-foreground)',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '4px'
                }}>
                  <div style={{ width: '6px', height: '6px', borderRadius: '50%', background: planType === 'premium' ? '#f59e0b' : 'var(--muted-foreground)' }} />
                  Plan {planType}
                </span>
              )}
            </div>
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
              {/* Solo Admin y Técnico ven el Dashboard */}
              {userRole !== 'operario' && (
                <Link href="/" className={`nav-item ${pathname === '/' ? 'active' : ''}`} onClick={closeSidebar}>
                  <LayoutDashboard size={20} />
                  Panel de Control
                </Link>
              )}
              
              {/* Solo Admin y Técnico ven Estanques */}
              {userRole !== 'operario' && (
                <Link href="/estanques" className={`nav-item ${pathname === '/estanques' ? 'active' : ''}`} onClick={closeSidebar}>
                  <Waves size={20} />
                  Estanques
                </Link>
              )}
              
              {/* TODOS ven Registros (es la base del Operario) */}
              <Link href="/registros" className={`nav-item ${pathname === '/registros' ? 'active' : ''}`} onClick={closeSidebar}>
                <ClipboardList size={20} />
                Registros
              </Link>

              {/* Solo Admin y Técnico ven Almacén (Facturas/Inventario) */}
              {userRole !== 'operario' && (
                <Link href="/almacen" className={`nav-item ${pathname === '/almacen' ? 'active' : ''}`} onClick={closeSidebar}>
                  <Package size={20} />
                  Almacén
                </Link>
              )}

              {/* SOLO el Admin ve Finanzas */}
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
            {/* Solo Admin y Técnico entran a Configuración */}
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
            
            <button 
              onClick={handleSignOut}
              className="nav-item" 
              style={{ 
                marginTop: '1rem',
                width: '100%', 
                textAlign: 'left', 
                background: 'none', 
                border: 'none', 
                color: '#ef4444', 
                cursor: 'pointer',
                display: 'flex',
                alignItems: 'center',
                gap: '0.75rem'
              }}
            >
              <LogOut size={20} />
              Cerrar Sesión
            </button>
          </div>
        )}

        {isSuperAdmin && (
          <div style={{ marginTop: 'auto', paddingBottom: '1rem' }}>
            <button 
              onClick={handleSignOut}
              className="nav-item" 
              style={{ 
                width: '100%', 
                textAlign: 'left', 
                background: 'none', 
                border: 'none', 
                color: '#ef4444', 
                cursor: 'pointer',
                display: 'flex',
                alignItems: 'center',
                gap: '0.75rem'
              }}
            >
              <LogOut size={20} />
              Cerrar Sesión
            </button>
          </div>
        )}
      </aside>
    </>
  );
}
