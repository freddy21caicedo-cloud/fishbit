'use client';

import { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { supabase } from '@/lib/supabase';
import { useRouter } from 'next/navigation';
import { 
  Fish, 
  Mail, 
  Lock, 
  ArrowRight, 
  AlertCircle,
  Loader2
} from 'lucide-react';

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      const { data, error: authError } = await supabase.auth.signInWithPassword({
        email,
        password,
      });

      if (authError) throw authError;

      // 1. Fetch Profile to check if SuperAdmin
      let { data: profile } = await supabase
        .from('profiles')
        .select('is_superadmin')
        .eq('id', data.user.id)
        .single();

      if (profile?.is_superadmin) {
        router.push('/superadmin');
        return;
      }

      // 2. Fetch Units for regular users
      const { data: userUnits, error: unitsError } = await supabase
        .from('user_units')
        .select('unit_id')
        .eq('user_id', data.user.id);

      if (unitsError) {
        setError(`Error de acceso: No se pudo leer tu vinculación.`);
        await supabase.auth.signOut();
        return;
      }

      if (!userUnits || userUnits.length === 0) {
        setError('Acceso denegado: Tu cuenta no está vinculada a ninguna granja activa.');
        await supabase.auth.signOut();
        return;
      }

      if (userUnits.length > 1) {
        router.push('/select-unit');
      } else {
        localStorage.setItem('active_unit_id', userUnits[0].unit_id);
        router.refresh();
        router.push('/dashboard');
      }
    } catch (err: any) {
      setError(err.message || 'Error al iniciar sesión');
    } finally {
      setLoading(false);
    }
  };

  const handleForgotPassword = (e: React.MouseEvent) => {
    e.preventDefault();
    const subject = encodeURIComponent("Recuperación de Contraseña FishBit");
    const body = encodeURIComponent(`Hola, necesito recuperar mi acceso a FishBit.\n\nMi correo de usuario es: ${email || '[Escribe tu correo aquí]'}`);
    window.location.href = `mailto:especialistaacuicola@gmail.com?subject=${subject}&body=${body}`;
  };

  const handleContactSupport = (e: React.MouseEvent) => {
    e.preventDefault();
    const message = encodeURIComponent("Hola FishBit, me gustaría solicitar una cuenta o soporte para mi granja acuícola.");
    window.open(`https://wa.me/573000000000?text=${message}`, '_blank');
  };

  return (
    <div style={{ 
      minHeight: '100vh', 
      display: 'flex', 
      background: 'radial-gradient(circle at top right, #f8fafc, #f0fdfa)',
      position: 'relative',
      overflow: 'hidden'
    }}>
      <div style={{ position: 'absolute', top: '-10%', right: '-10%', width: '40%', height: '40%', background: 'rgba(13, 148, 136, 0.03)', borderRadius: '50%', filter: 'blur(80px)' }} />
      <div style={{ position: 'absolute', bottom: '-10%', left: '-10%', width: '40%', height: '40%', background: 'rgba(13, 148, 136, 0.03)', borderRadius: '50%', filter: 'blur(80px)' }} />

      <div style={{ 
        flex: 1, 
        display: 'flex', 
        flexDirection: 'column', 
        alignItems: 'center', 
        justifyContent: 'center',
        padding: '2rem',
        zIndex: 1
      }}>
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          style={{ width: '100%', maxWidth: '420px' }}
        >
          <div style={{ textAlign: 'center', marginBottom: '3rem' }}>
            <div style={{ 
              width: '64px', 
              height: '64px', 
              background: 'var(--primary)', 
              borderRadius: '16px', 
              display: 'flex', 
              alignItems: 'center', 
              justifyContent: 'center',
              margin: '0 auto 1.5rem',
              boxShadow: '0 10px 25px rgba(13, 148, 136, 0.2)',
              position: 'relative'
            }}>
              <Fish color="white" size={32} />
              <motion.div 
                animate={{ scale: [1, 1.2, 1], opacity: [0.5, 0.2, 0.5] }}
                transition={{ duration: 3, repeat: Infinity }}
                style={{ position: 'absolute', inset: -8, border: '2px solid var(--primary)', borderRadius: '20px' }} 
              />
            </div>
            <h1 style={{ fontSize: '2.25rem', fontWeight: 800, color: '#1e293b', letterSpacing: '-0.02em', marginBottom: '0.5rem' }}>FishBit</h1>
            <p style={{ color: 'var(--muted-foreground)', fontSize: '0.9rem', fontWeight: 600 }}>Gestión Acuícola de Siguiente Generación</p>
          </div>

          <div className="card-premium" style={{ padding: '2.5rem', boxShadow: '0 20px 50px rgba(0,0,0,0.05)' }}>
            <form onSubmit={handleLogin} style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                <label style={{ fontSize: '0.75rem', fontWeight: 800, color: 'var(--muted-foreground)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Correo Electrónico</label>
                <div style={{ position: 'relative' }}>
                  <Mail size={18} style={{ position: 'absolute', left: '1rem', top: '50%', transform: 'translateY(-50%)', color: 'var(--muted-foreground)' }} />
                  <input 
                    type="email" 
                    required
                    placeholder="admin@unidad.com"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    className="premium-input"
                    style={{ paddingLeft: '3rem' }}
                  />
                </div>
              </div>

              <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <label style={{ fontSize: '0.75rem', fontWeight: 800, color: 'var(--muted-foreground)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Contraseña</label>
                  <button 
                    type="button"
                    onClick={handleForgotPassword}
                    style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--primary)', background: 'none', border: 'none', cursor: 'pointer', padding: 0 }}
                  >
                    ¿La olvidaste?
                  </button>
                </div>
                <div style={{ position: 'relative' }}>
                  <Lock size={18} style={{ position: 'absolute', left: '1rem', top: '50%', transform: 'translateY(-50%)', color: 'var(--muted-foreground)' }} />
                  <input 
                    type="password" 
                    required
                    placeholder="••••••••"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    className="premium-input"
                    style={{ paddingLeft: '3rem' }}
                  />
                </div>
              </div>

              <AnimatePresence>
                {error && (
                  <motion.div 
                    initial={{ opacity: 0, height: 0 }}
                    animate={{ opacity: 1, height: 'auto' }}
                    exit={{ opacity: 0, height: 0 }}
                    style={{ 
                      padding: '0.75rem 1rem', 
                      borderRadius: '8px', 
                      background: 'rgba(239, 68, 68, 0.05)', 
                      border: '1px solid rgba(239, 68, 68, 0.1)', 
                      color: '#ef4444', 
                      fontSize: '0.85rem',
                      display: 'flex',
                      alignItems: 'center',
                      gap: '0.5rem'
                    }}
                  >
                    <AlertCircle size={16} />
                    {error}
                  </motion.div>
                )}
              </AnimatePresence>

              <button 
                type="submit" 
                disabled={loading}
                className="btn-primary" 
                style={{ 
                  padding: '1rem', 
                  fontSize: '1rem', 
                  fontWeight: 700, 
                  display: 'flex', 
                  alignItems: 'center', 
                  justifyContent: 'center', 
                  gap: '0.75rem',
                  marginTop: '0.5rem'
                }}
              >
                {loading ? (
                  <Loader2 size={20} className="animate-spin" />
                ) : (
                  <>
                    Entrar a FishBit
                    <ArrowRight size={20} />
                  </>
                )}
              </button>
            </form>
          </div>

          <p style={{ textAlign: 'center', marginTop: '2rem', color: 'var(--muted-foreground)', fontSize: '0.9rem' }}>
            ¿No tienes una cuenta? <button onClick={handleContactSupport} style={{ background: 'none', border: 'none', color: 'var(--primary)', fontWeight: 700, cursor: 'pointer', padding: 0 }}>Contactar Soporte</button>
          </p>
        </motion.div>
      </div>
    </div>
  );
}
