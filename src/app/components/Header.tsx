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

export default function Header() {
  const pathname = usePathname();
  const router = useRouter();
  const [isSuperAdmin, setIsSuperAdmin] = useState(false);
  const [showNotifications, setShowNotifications] = useState(false);
  const [showProfileMenu, setShowProfileMenu] = useState(false);
  const [notifications, setNotifications] = useState([
    { id: 1, text: "Nueva Unidad 'Piscícola Norte' creada", time: "Hace 5 min", type: "success" },
    { id: 2, text: "Ticket de soporte de Freddy pendiente", time: "Hace 12 min", type: "alert" }
  ]);

  const profileRef = useRef<HTMLDivElement>(null);
  const notifRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    async function checkRole() {
      const { data: { user } } = await supabase.auth.getUser();
      if (user) {
        const { data } = await supabase
          .from('profiles')
          .select('is_superadmin')
          .eq('id', user.id)
          .single();
        setIsSuperAdmin(data?.is_superadmin || false);
      }
    }
    checkRole();

    const handleClickOutside = (event: MouseEvent) => {
      if (profileRef.current && !profileRef.current.contains(event.target as Node)) setShowProfileMenu(false);
      if (notifRef.current && !notifRef.current.contains(event.target as Node)) setShowNotifications(false);
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const handleSignOut = async () => {
    await supabase.auth.signOut();
    localStorage.removeItem('active_unit_id');
    router.refresh();
    router.push('/login');
  };

  const hiddenPages = ['/estanques', '/siembra', '/tratamiento', '/mantenimiento', '/aireacion', '/biometria', '/mortalidad', '/traslado', '/almacen', '/finanzas', '/configuracion', '/ayuda'];
  if (hiddenPages.includes(pathname) || pathname.startsWith('/registros')) return null;

  return (
    <header className="header" style={{ position: 'relative', zIndex: 60 }}>
      <div>
        <h1 style={{ fontSize: '1.5rem', marginBottom: '0.25rem' }}>Bienvenido de nuevo, Freddy</h1>
        <p style={{ color: 'var(--muted-foreground)', fontSize: '0.875rem', marginBottom: isSuperAdmin ? '0' : '1rem' }}>
          {isSuperAdmin 
            ? "Aquí está el resumen global de tu plataforma FishBit."
            : "Aquí está lo que está pasando en tu granja hoy."
          }
        </p>
        
        {!isSuperAdmin && (
          <div style={{ display: 'inline-flex', alignItems: 'center', gap: '0.75rem', padding: '0.5rem 1rem', background: 'var(--secondary)', borderRadius: 'var(--radius)', border: '1px solid var(--border)', cursor: 'pointer' }}>
            <span style={{ fontSize: '0.875rem', fontWeight: 500, color: 'var(--foreground)' }}>Estanque Global (Todos)</span>
            <ChevronDown size={14} style={{ color: 'var(--muted-foreground)' }} />
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
            <span style={{ position: 'absolute', top: '8px', right: '8px', width: '8px', height: '8px', background: 'var(--destructive)', borderRadius: '50%', border: '2px solid var(--card)' }}></span>
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
                  <span style={{ fontSize: '0.7rem', color: 'var(--primary)', fontWeight: 700, cursor: 'pointer' }}>Limpiar</span>
                </div>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
                  {notifications.map(n => (
                    <div key={n.id} style={{ display: 'flex', gap: '0.75rem', padding: '0.75rem', borderRadius: '12px', background: 'var(--secondary)' }}>
                      <div style={{ color: n.type === 'success' ? '#10b981' : '#3b82f6' }}>
                        {n.type === 'success' ? <CheckCircle2 size={18} /> : <AlertCircle size={18} />}
                      </div>
                      <div>
                        <div style={{ fontSize: '0.85rem', fontWeight: 600, lineHeight: 1.3 }}>{n.text}</div>
                        <div style={{ fontSize: '0.7rem', color: 'var(--muted-foreground)', marginTop: '0.2rem' }}>{n.time}</div>
                      </div>
                    </div>
                  ))}
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
                  <div style={{ fontWeight: 800, fontSize: '0.9rem' }}>Freddy</div>
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
                  onClick={handleSignOut}
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
