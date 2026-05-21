import { useEffect, useState, useRef } from "react";
import { usePathname, useRouter } from "next/navigation";
import { supabase } from "@/lib/supabase";
import { 
  Bell,
  ChevronDown,
  LogOut,
  User,
  Settings,
  X,
  CheckCircle2,
  AlertCircle
} from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";
import { useAuth } from "./providers/AuthProvider";
import { useUnit } from "./providers/UnitProvider";
import { useLogout } from "../hooks/useLogout";

export default function Header() {
  const pathname = usePathname();
  const router = useRouter();
  const { session, isSuperAdmin, profile } = useAuth();
  const { userRole, activeUnit } = useUnit();
  const logout = useLogout();
  const [showNotifications, setShowNotifications] = useState(false);
  const [showProfileMenu, setShowProfileMenu] = useState(false);
  const [showUnitsMenu, setShowUnitsMenu] = useState(false);
  const [notifications, setNotifications] = useState<any[]>([]);
  const [units, setUnits] = useState<any[]>([]);

  const profileRef = useRef<HTMLDivElement>(null);
  const notifRef = useRef<HTMLDivElement>(null);
  const unitsRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (profileRef.current && !profileRef.current.contains(event.target as Node)) setShowProfileMenu(false);
      if (notifRef.current && !notifRef.current.contains(event.target as Node)) setShowNotifications(false);
      if (unitsRef.current && !unitsRef.current.contains(event.target as Node)) setShowUnitsMenu(false);
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  useEffect(() => {
    if (!session?.user?.id || isSuperAdmin) return;

    const fetchUnits = async () => {
      try {
        // Step 1: get unit_ids for this user
        const { data: userUnitRows } = await supabase
          .from('user_units')
          .select('unit_id')
          .eq('user_id', session.user.id);

        if (!userUnitRows || userUnitRows.length === 0) return;

        const unitIds = userUnitRows.map((r: any) => r.unit_id).filter(Boolean);

        // Step 2: fetch full unit data directly (avoid unreliable FK join)
        const { data: unitRows } = await supabase
          .from('units')
          .select('id, name, location')
          .in('id', unitIds);

        if (unitRows) setUnits(unitRows);
      } catch (err) {
        console.error('Header: error fetching units:', err);
      }
    };

    fetchUnits();
  }, [session?.user?.id, isSuperAdmin]);
  const hiddenPages = ['/estanques', '/siembra', '/tratamiento', '/mantenimiento', '/aireacion', '/biometria', '/mortalidad', '/traslado', '/almacen', '/finanzas', '/configuracion', '/ayuda'];
  if (hiddenPages.includes(pathname) || pathname.startsWith('/registros')) return null;

  return (
    <header className="header" style={{ position: 'relative', zIndex: 60 }}>
      <div>
        <h1 style={{ fontSize: '1.5rem', marginBottom: '0.25rem' }}>
          Bienvenido de nuevo, {profile?.full_name || session?.user?.email?.split('@')[0] || "Usuario"}
        </h1>
        <p style={{ color: 'var(--muted-foreground)', fontSize: '0.875rem', marginBottom: isSuperAdmin ? '0' : '1rem' }}>
          {isSuperAdmin 
            ? "Aquí está el resumen global de tu plataforma FishBit."
            : "Aquí está lo que está pasando en tu granja hoy."
          }
        </p>
        
        {!isSuperAdmin && (
          <div ref={unitsRef} style={{ position: 'relative', display: 'inline-block' }}>
            {units.length > 1 ? (
              <>
                <div 
                  onClick={() => setShowUnitsMenu(!showUnitsMenu)}
                  style={{ display: 'inline-flex', alignItems: 'center', gap: '0.75rem', padding: '0.5rem 1rem', background: showUnitsMenu ? 'var(--card)' : 'var(--secondary)', borderRadius: 'var(--radius)', border: '1px solid var(--border)', cursor: 'pointer', transition: 'all 0.2s' }}
                >
                  <span style={{ fontSize: '0.875rem', fontWeight: 600, color: 'var(--foreground)' }}>
                    {activeUnit?.name || 'Seleccionando Unidad...'}
                  </span>
                  <ChevronDown size={14} style={{ color: 'var(--muted-foreground)', transform: showUnitsMenu ? 'rotate(180deg)' : 'none', transition: 'transform 0.2s' }} />
                </div>

                <AnimatePresence>
                  {showUnitsMenu && (
                    <motion.div 
                      initial={{ opacity: 0, y: 10, scale: 0.95 }}
                      animate={{ opacity: 1, y: 0, scale: 1 }}
                      exit={{ opacity: 0, y: 10, scale: 0.95 }}
                      style={{ position: 'absolute', top: '120%', left: 0, width: '260px', background: 'var(--card)', border: '1px solid var(--border)', borderRadius: '16px', boxShadow: 'var(--shadow-xl)', padding: '0.5rem', zIndex: 100 }}
                    >
                      <div style={{ padding: '0.5rem 0.75rem', fontSize: '0.75rem', fontWeight: 800, textTransform: 'uppercase', color: 'var(--muted-foreground)', letterSpacing: '0.05em' }}>
                        Tus Granjas
                      </div>
                      <div style={{ display: 'flex', flexDirection: 'column', gap: '0.25rem' }}>
                        {units.map((u: any) => (
                          <button
                            key={u.id}
                            onClick={() => {
                              if (u.id !== activeUnit?.id) {
                                localStorage.setItem('active_unit_id', u.id);
                                window.location.reload(); // Recargar para limpiar estado global y forzar al UnitProvider a cargar la nueva
                              }
                              setShowUnitsMenu(false);
                            }}
                            style={{
                              width: '100%',
                              textAlign: 'left',
                              padding: '0.75rem',
                              borderRadius: '8px',
                              border: 'none',
                              background: u.id === activeUnit?.id ? 'rgba(13, 148, 136, 0.1)' : 'transparent',
                              cursor: 'pointer',
                              display: 'flex',
                              flexDirection: 'column',
                              gap: '0.15rem'
                            }}
                            onMouseEnter={(e) => {
                              if (u.id !== activeUnit?.id) e.currentTarget.style.background = 'var(--secondary)';
                            }}
                            onMouseLeave={(e) => {
                              if (u.id !== activeUnit?.id) e.currentTarget.style.background = 'transparent';
                            }}
                          >
                            <span style={{ fontWeight: 700, color: u.id === activeUnit?.id ? '#0d9488' : 'var(--foreground)', fontSize: '0.9rem' }}>
                              {u.name}
                            </span>
                            <span style={{ fontSize: '0.75rem', color: 'var(--muted-foreground)' }}>
                              {u.location || 'Sede Principal'}
                            </span>
                          </button>
                        ))}
                      </div>
                    </motion.div>
                  )}
                </AnimatePresence>
              </>
            ) : (
              <div 
                style={{ display: 'inline-flex', alignItems: 'center', gap: '0.75rem', padding: '0.5rem 1rem', background: 'var(--secondary)', borderRadius: 'var(--radius)', border: '1px solid var(--border)', cursor: 'default' }}
              >
                <span style={{ fontSize: '0.875rem', fontWeight: 600, color: 'var(--foreground)' }}>
                  {activeUnit?.name || 'Seleccionando Unidad...'}
                </span>
              </div>
            )}
          </div>
        )}
      </div>

      <div style={{ display: 'flex', gap: '1rem', alignItems: 'center' }}>
        {/* Notifications */}
        <div ref={notifRef} style={{ position: 'relative' }}>
          <button 
            className="glass" 
            onClick={() => setShowNotifications(!showNotifications)}
            style={{ padding: '0.6rem', borderRadius: '12px', border: '1px solid var(--border)', cursor: 'pointer', position: 'relative', background: showNotifications ? 'var(--secondary)' : 'var(--card)' }}
          >
            <Bell size={20} />
            {notifications.length > 0 && (
              <span style={{ position: 'absolute', top: '8px', right: '8px', width: '8px', height: '8px', background: 'var(--destructive)', borderRadius: '50%', border: '2px solid var(--card)' }}></span>
            )}
          </button>

          <AnimatePresence>
            {showNotifications && (
              <motion.div 
                initial={{ opacity: 0, y: 10, scale: 0.95 }}
                animate={{ opacity: 1, y: 0, scale: 1 }}
                exit={{ opacity: 0, y: 10, scale: 0.95 }}
                style={{ position: 'absolute', top: '120%', right: 0, width: '320px', background: 'var(--card)', border: '1px solid var(--border)', borderRadius: '16px', boxShadow: 'var(--shadow-xl)', padding: '1rem', zIndex: 100 }}
              >
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
                  <h4 style={{ fontWeight: 800 }}>Notificaciones</h4>
                  {notifications.length > 0 && (
                    <span 
                      onClick={() => setNotifications([])}
                      style={{ fontSize: '0.7rem', color: 'var(--primary)', fontWeight: 700, cursor: 'pointer' }}
                    >
                      Limpiar
                    </span>
                  )}
                </div>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
                  {notifications.length > 0 ? (
                    notifications.map(n => (
                      <div key={n.id} style={{ display: 'flex', gap: '0.75rem', padding: '0.75rem', borderRadius: '12px', background: 'var(--secondary)' }}>
                        <div style={{ color: n.type === 'success' ? '#10b981' : '#3b82f6' }}>
                          {n.type === 'success' ? <CheckCircle2 size={18} /> : <AlertCircle size={18} />}
                        </div>
                        <div>
                          <div style={{ fontSize: '0.85rem', fontWeight: 600, lineHeight: 1.3 }}>{n.text}</div>
                          <div style={{ fontSize: '0.7rem', color: 'var(--muted-foreground)', marginTop: '0.2rem' }}>{n.time}</div>
                        </div>
                      </div>
                    ))
                  ) : (
                    <div style={{ textAlign: 'center', padding: '1.5rem', color: 'var(--muted-foreground)', fontSize: '0.85rem' }}>
                      No tienes notificaciones pendientes.
                    </div>
                  )}
                </div>
              </motion.div>
            )}
          </AnimatePresence>
        </div>

        {/* Profile Menu */}
        <div ref={profileRef} style={{ position: 'relative' }}>
          <div 
            onClick={() => setShowProfileMenu(!showProfileMenu)}
            style={{ width: '42px', height: '42px', borderRadius: '14px', background: 'linear-gradient(135deg, #3b82f6, #8b5cf6)', cursor: 'pointer', border: '2px solid var(--border)', transition: 'transform 0.2s' }}
            onMouseEnter={(e) => e.currentTarget.style.transform = 'scale(1.05)'}
            onMouseLeave={(e) => e.currentTarget.style.transform = 'scale(1)'}
          />
          
          <AnimatePresence>
            {showProfileMenu && (
              <motion.div 
                initial={{ opacity: 0, y: 10, scale: 0.95 }}
                animate={{ opacity: 1, y: 0, scale: 1 }}
                exit={{ opacity: 0, y: 10, scale: 0.95 }}
                style={{ position: 'absolute', top: '120%', right: 0, width: '220px', background: 'var(--card)', border: '1px solid var(--border)', borderRadius: '16px', boxShadow: 'var(--shadow-xl)', padding: '0.5rem', zIndex: 100 }}
              >
                <div style={{ padding: '0.75rem', borderBottom: '1px solid var(--border)', marginBottom: '0.5rem' }}>
                  <div style={{ fontWeight: 800, fontSize: '0.9rem' }}>
                    {profile?.full_name || session?.user?.email?.split('@')[0] || "Usuario"}
                  </div>
                  <div style={{ fontSize: '0.75rem', color: 'var(--muted-foreground)' }}>{isSuperAdmin ? 'Super Administrador' : 'Administrador'}</div>
                </div>
                <button 
                  onClick={() => { router.push('/perfil'); setShowProfileMenu(false); }}
                  className="nav-item" 
                  style={{ width: '100%', border: 'none', background: 'none', justifyContent: 'flex-start', padding: '0.75rem', cursor: 'pointer' }}
                >
                  <User size={18} />
                  Mi Perfil
                </button>
                <button 
                  onClick={() => { router.push('/configuracion'); setShowProfileMenu(false); }}
                  className="nav-item" 
                  style={{ width: '100%', border: 'none', background: 'none', justifyContent: 'flex-start', padding: '0.75rem', cursor: 'pointer' }}
                >
                  <Settings size={18} />
                  Ajustes
                </button>
                <div style={{ height: '1px', background: 'var(--border)', margin: '0.5rem 0' }}></div>
                <button 
                  onClick={logout}
                  className="nav-item" 
                  style={{ width: '100%', border: 'none', background: 'none', justifyContent: 'flex-start', padding: '0.75rem', cursor: 'pointer', color: '#ef4444' }}
                >
                  <LogOut size={18} />
                  Cerrar Sesión
                </button>
              </motion.div>
            )}
          </AnimatePresence>
        </div>
      </div>
    </header>
  );
}
