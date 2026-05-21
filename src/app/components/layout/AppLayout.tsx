'use client';

import { useState, useEffect } from 'react';
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { supabase } from '@/lib/supabase';
import { useAuth } from '../providers/AuthProvider';
import { useUnit } from '../providers/UnitProvider';
import { useLogout } from '../../hooks/useLogout';
import { FishBitIcon, FishBitWordmark } from '../FishBitLogo';
import { 
  LayoutDashboard, 
  Waves, 
  ClipboardList, 
  Coins, 
  Settings, 
  HelpCircle,
  Package,
  Shield,
  LogOut,
  Menu,
  X,
  Lock,
  ShieldAlert,
  Loader2,
} from "lucide-react";
import { toast } from 'react-hot-toast';

interface AppLayoutProps {
  children: React.ReactNode;
}

export default function AppLayout({ children }: AppLayoutProps) {
  const pathname = usePathname();
  const router = useRouter();
  const { session, profileLoading, isSuperAdmin } = useAuth();
  const { activeUnit, loading: unitLoading, refreshUnitData, userRole, roleLoading } = useUnit();
  const logout = useLogout();
  const [width, setWidth] = useState(typeof window !== 'undefined' ? window.innerWidth : 1200);
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
  const [activatingFreeTrial, setActivatingFreeTrial] = useState(false);

  // Global settings from database
  const [globalSettings, setGlobalSettings] = useState({
    price_cop: 100000,
    support_whatsapp: '+573000000000',
    free_trial_days: 30,
    grace_days: 3,
    support_email: 'soporte@fishbit.co'
  });

  useEffect(() => {
    async function loadGlobalSettings() {
      try {
        const { data, error } = await supabase
          .from('app_config')
          .select('value')
          .eq('key', 'global_settings')
          .maybeSingle();
        if (data?.value) {
          const parsed = typeof data.value === 'string' ? JSON.parse(data.value) : data.value;
          setGlobalSettings({
            price_cop: parsed.price ?? 100000,
            support_whatsapp: parsed.support_whatsapp ?? '+573000000000',
            free_trial_days: parsed.trial_days ?? 30,
            grace_days: parsed.grace_days ?? 3,
            support_email: parsed.support_email ?? 'soporte@fishbit.co'
          });
        }
      } catch (err) {
        console.error("Error loading system settings in AppLayout:", err);
      }
    }
    loadGlobalSettings();
  }, []);

  const handleStartFreeTrial = async () => {
    if (!activeUnit?.id) return;
    setActivatingFreeTrial(true);
    
    const startTrialPromise = async () => {
      const response = await fetch('/api/subscriptions/trial', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ unitId: activeUnit.id })
      });
      
      const result = await response.json();
      if (!response.ok || result.error) {
        throw new Error(result.error || 'Error al activar mes gratis.');
      }
      
      await refreshUnitData();
    };

    try {
      await toast.promise(startTrialPromise(), {
        loading: 'Iniciando mes gratis de bienvenida...',
        success: '¡Mes de prueba gratis activado exitosamente!',
        error: (err) => err?.message || 'Error al activar mes gratis.'
      });
    } catch (err) {
      console.error('Error starting free trial:', err);
    } finally {
      setActivatingFreeTrial(false);
    }
  };

  // isInitialized pattern removed — providers manage their own fail-safe timeouts

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

  // Strict frontend route protection for operarios
  useEffect(() => {
    if (!profileLoading && !roleLoading && !isSuperAdmin && userRole === 'operario') {
      const allowedPaths = ['/registros', '/ayuda'];
      const currentPath = pathname || '';
      
      const isAllowed = allowedPaths.some(allowed => currentPath === allowed || currentPath.startsWith(allowed + '/'));
      
      if (!isAllowed) {
        toast.error('Acceso denegado: Tu rol de Operario solo permite registrar datos.');
        router.replace('/registros');
      }
    }
  }, [profileLoading, roleLoading, isSuperAdmin, userRole, pathname, router]);

  const isMobile = width < 768;
  const isTablet = width >= 768 && width <= 1024;
  const isDesktop = width > 1024;

  const sidebarWidth = isDesktop ? '240px' : isTablet ? '64px' : '0px';
  
  const rawSub = activeUnit?.subscriptions;
  const sub = Array.isArray(rawSub) ? rawSub[0] : rawSub;
  const planType = sub?.plan_type || 'basic';

  const hasNoSubscription = !sub || !sub.plan_type || sub.plan_type === 'Sin Plan';
  const isSuspended = sub?.status === 'canceled';
  const isExpired = sub?.next_billing_date ? (() => {
    const billingDate = new Date(sub.next_billing_date);
    const graceDate = new Date(billingDate);
    graceDate.setDate(billingDate.getDate() + (globalSettings.grace_days ?? 3));
    return graceDate < new Date();
  })() : false;
  
  // Only apply subscription block if user is not SuperAdmin and activeUnit is loaded
  const isBlocked = !isSuperAdmin && !unitLoading && !profileLoading && !roleLoading && !!activeUnit && (hasNoSubscription || isSuspended || isExpired);
  
  // Can start free trial if the unit is blocked and has never activated a trial before
  const canStartFreeTrial = isBlocked && !sub?.trial_activated_at;

  const menuItems = [
    { label: 'Panel', icon: LayoutDashboard, href: '/dashboard', roles: ['admin', 'propietario', 'tecnico'] },
    { label: 'Estanques', icon: Waves, href: '/estanques', roles: ['admin', 'propietario', 'tecnico'] },
    { label: 'Registros', icon: ClipboardList, href: '/registros', roles: ['admin', 'propietario', 'tecnico', 'operario'] },
    { label: 'Almacén', icon: Package, href: '/almacen', roles: ['admin', 'propietario', 'tecnico'] },
    { label: 'Finanzas', icon: Coins, href: '/finanzas', roles: ['admin', 'propietario'] },
  ];

  const secondaryItems = [
    { label: 'Configuración', icon: Settings, href: '/configuracion', roles: ['admin', 'propietario', 'tecnico'] },
    { label: 'Centro de Ayuda', icon: HelpCircle, href: '/ayuda', roles: ['admin', 'propietario', 'tecnico', 'operario'] },
  ];

  const filteredMenu = isSuperAdmin 
    ? [{ label: 'SuperAdmin Hub', icon: Shield, href: '/superadmin' }]
    : menuItems.filter(item => item.roles.includes(userRole || ''));

  const filteredSecondary = isSuperAdmin
    ? [{ label: 'Configuración', icon: Settings, href: '/configuracion' }]
    : secondaryItems.filter(item => item.roles.includes(userRole || ''));

  // Show a slim loading overlay only on first render when unit data hasn't arrived yet.
  // The providers have internal fail-safe timeouts so this can't show for more than 2.5s.
  if (unitLoading && !activeUnit) {
    return (
      <div style={{
        minHeight: '100vh',
        width: '100vw',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        background: '#06101e',
        color: '#e8f0fb',
        fontFamily: 'var(--font-sans)',
      }}>
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '1.5rem' }}>
          <FishBitIcon size={72} style={{ filter: 'drop-shadow(0 0 16px rgba(30,202,212,0.35))' }} />
          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '0.2rem' }}>
            <span style={{ fontWeight: 900, fontSize: '1.5rem', letterSpacing: '-0.03em', color: '#e8f0fb', fontFamily: 'var(--font-heading)' }}>
              Fish<span style={{ color: '#1ECAD4' }}>Bit</span>
            </span>
            <span style={{ fontSize: '0.7rem', color: '#7a9bbf', fontWeight: 600, letterSpacing: '0.1em', textTransform: 'uppercase' }}>Cargando...</span>
          </div>
        </div>
      </div>
    );
  }

  if (isBlocked) {
    return (
      <div style={{
        minHeight: '100vh',
        width: '100vw',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        background: 'radial-gradient(circle at 10% 20%, rgba(45, 201, 216, 0.12) 0%, rgba(6, 16, 30, 1) 90%)',
        backgroundColor: '#06101e',
        color: '#e8f0fb',
        fontFamily: 'var(--font-sans)',
        padding: '1.5rem',
        boxSizing: 'border-box',
        position: 'fixed',
        top: 0,
        left: 0,
        zIndex: 99999,
        overflowY: 'auto'
      }}>
        {/* Beautiful glassmorphic card container */}
        <div style={{
          maxWidth: '520px',
          width: '100%',
          background: 'rgba(13, 27, 46, 0.72)',
          backdropFilter: 'blur(20px)',
          WebkitBackdropFilter: 'blur(20px)',
          border: '1px solid rgba(255, 255, 255, 0.08)',
          borderRadius: '24px',
          padding: '2.5rem',
          boxShadow: '0 20px 50px rgba(0, 0, 0, 0.4), inset 0 1px 0 rgba(255, 255, 255, 0.1)',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          textAlign: 'center',
          gap: '1.5rem'
        }}>
          {/* Logo */}
          <FishBitWordmark size={26} textColor="#ffffff" />

          {/* Icon Badge */}
          <div style={{
            width: '80px',
            height: '80px',
            borderRadius: '50%',
            background: isExpired ? 'rgba(239, 68, 68, 0.1)' : 'rgba(20, 184, 166, 0.1)',
            border: isExpired ? '1px solid rgba(239, 68, 68, 0.2)' : '1px solid rgba(20, 184, 166, 0.2)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            color: isExpired ? '#ef4444' : '#14b8a6',
            boxShadow: isExpired ? '0 0 20px rgba(239, 68, 68, 0.1)' : '0 0 20px rgba(20, 184, 166, 0.1)',
            marginBottom: '0.5rem'
          }}>
            {isExpired ? <ShieldAlert size={40} /> : <Lock size={40} />}
          </div>

          {/* Heading */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
            <h2 style={{ fontSize: '1.5rem', fontWeight: 800, letterSpacing: '-0.025em', color: '#ffffff' }}>
              {isExpired ? 'Acceso Vencido' : 'Acceso Restringido'}
            </h2>
            <p style={{ color: '#94a3b8', fontSize: '0.925rem', lineHeight: '1.6' }}>
              {isExpired 
                ? `La suscripción para la unidad acuícola "${activeUnit?.name}" venció el ${sub?.next_billing_date ? new Date(sub.next_billing_date).toLocaleDateString('es-CO', { day: 'numeric', month: 'long', year: 'numeric' }) : ''}.`
                : isSuspended
                ? `El acceso a la unidad acuícola "${activeUnit?.name}" ha sido suspendido por el administrador.`
                : `La unidad acuícola "${activeUnit?.name}" no cuenta con una suscripción activa.`}
            </p>
          </div>

          {/* Eligible for free trial */}
          {canStartFreeTrial ? (
            <div style={{
              width: '100%',
              background: 'rgba(13, 148, 136, 0.08)',
              border: '1px solid rgba(13, 148, 136, 0.2)',
              borderRadius: '16px',
              padding: '1.25rem',
              textAlign: 'left',
              display: 'flex',
              flexDirection: 'column',
              gap: '0.75rem',
              boxShadow: 'inset 0 1px 0 rgba(255, 255, 255, 0.05)'
            }}>
              <span style={{ fontSize: '0.8rem', fontWeight: 800, color: '#14b8a6', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                ¡Mes de Prueba Gratis Disponible!
              </span>
              <p style={{ fontSize: '0.85rem', color: '#cbd5e1', lineHeight: '1.5' }}>
                Te damos la bienvenida a FishBit. Activa tu primer mes gratis para gestionar estanques, alimentación, finanzas y más.
              </p>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '0.4rem', fontSize: '0.8rem', color: '#94a3b8' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                  <span style={{ color: '#10b981' }}>✓</span> 30 días de acceso completo sin costo
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                  <span style={{ color: '#10b981' }}>✓</span> Sin necesidad de tarjeta de crédito
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                  <span style={{ color: '#10b981' }}>✓</span> Activación instantánea
                </div>
              </div>
              <button
                onClick={handleStartFreeTrial}
                disabled={activatingFreeTrial}
                style={{
                  width: '100%',
                  minHeight: '48px',
                  background: 'linear-gradient(135deg, #0d9488 0%, #0f766e 100%)',
                  color: 'white',
                  border: 'none',
                  borderRadius: '10px',
                  fontWeight: 600,
                  fontSize: '0.9rem',
                  cursor: 'pointer',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  gap: '0.5rem',
                  transition: 'all 0.2s',
                  boxShadow: '0 4px 12px rgba(13, 148, 136, 0.3)'
                }}
              >
                {activatingFreeTrial ? (
                  <>
                    <Loader2 className="animate-spin" size={18} />
                    Activando Periodo Gratis...
                  </>
                ) : (
                  'Iniciar Mes de Prueba Gratis'
                )}
              </button>
            </div>
          ) : (
            <div style={{
              width: '100%',
              background: 'rgba(255, 255, 255, 0.03)',
              border: '1px solid rgba(255, 255, 255, 0.06)',
              borderRadius: '16px',
              padding: '1.25rem',
              display: 'flex',
              flexDirection: 'column',
              gap: '0.75rem'
            }}>
              <span style={{ fontSize: '0.8rem', fontWeight: 800, color: '#ef4444', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                Suscripción Requerida
              </span>
              <p style={{ fontSize: '0.85rem', color: '#cbd5e1', lineHeight: '1.5' }}>
                Para reactivar el acceso al Plan Único ($${globalSettings.price_cop.toLocaleString('es-CO')} COP/mes), ponte en contacto con soporte técnico para registrar tu pago manual.
              </p>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem', width: '100%' }}>
                <a
                  href={`https://wa.me/${globalSettings.support_whatsapp.replace(/\+/g, '').replace(/\s/g, '')}?text=Hola%20quiero%20reactivar%20mi%20suscripcion%20de%20FishBit`}
                  target="_blank"
                  rel="noreferrer"
                  style={{
                    width: '100%',
                    minHeight: '44px',
                    background: '#25d366',
                    color: 'white',
                    border: 'none',
                    borderRadius: '10px',
                    fontWeight: 600,
                    fontSize: '0.85rem',
                    cursor: 'pointer',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    gap: '0.5rem',
                    textDecoration: 'none',
                    transition: 'opacity 0.2s',
                    textAlign: 'center',
                    lineHeight: '44px'
                  }}
                  onMouseEnter={(e) => e.currentTarget.style.opacity = '0.9'}
                  onMouseLeave={(e) => e.currentTarget.style.opacity = '1'}
                >
                  Contactar por WhatsApp
                </a>
                <a
                  href={`mailto:${globalSettings.support_email}?subject=Reactivación%20de%20Suscripción%20FishBit`}
                  style={{
                    width: '100%',
                    minHeight: '44px',
                    background: 'rgba(255, 255, 255, 0.08)',
                    color: 'white',
                    border: '1px solid rgba(255, 255, 255, 0.1)',
                    borderRadius: '10px',
                    fontWeight: 600,
                    fontSize: '0.85rem',
                    cursor: 'pointer',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    gap: '0.5rem',
                    textDecoration: 'none',
                    transition: 'background 0.2s',
                    textAlign: 'center',
                    lineHeight: '44px'
                  }}
                  onMouseEnter={(e) => e.currentTarget.style.background = 'rgba(255, 255, 255, 0.12)'}
                  onMouseLeave={(e) => e.currentTarget.style.background = 'rgba(255, 255, 255, 0.08)'}
                >
                  Enviar Correo a Soporte
                </a>
              </div>
            </div>
          )}

          {/* Divider */}
          <div style={{ width: '100%', height: '1px', background: 'rgba(255, 255, 255, 0.08)' }} />

          {/* Action buttons */}
          <div style={{ display: 'flex', justifyContent: 'center', width: '100%' }}>
            <button
              onClick={logout}
              style={{
                background: 'transparent',
                border: 'none',
                color: '#ef4444',
                fontWeight: 600,
                fontSize: '0.9rem',
                cursor: 'pointer',
                display: 'flex',
                alignItems: 'center',
                gap: '0.5rem',
                padding: '0.5rem 1rem',
                borderRadius: '8px',
                transition: 'background 0.2s'
              }}
              onMouseEnter={(e) => e.currentTarget.style.background = 'rgba(239, 68, 68, 0.08)'}
              onMouseLeave={(e) => e.currentTarget.style.background = 'transparent'}
            >
              <LogOut size={18} />
              Cerrar Sesión
            </button>
          </div>
        </div>
      </div>
    );
  }

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
          {(isDesktop || isMobile) ? (
            <FishBitWordmark size={20} />
          ) : (
            <FishBitIcon size={32} />
          )}
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
                  background: active ? 'rgba(27, 46, 94, 0.08)' : 'transparent',
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
                  background: active ? 'rgba(27, 46, 94, 0.08)' : 'transparent',
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
            onClick={logout}
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
