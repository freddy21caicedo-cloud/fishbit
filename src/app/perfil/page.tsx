'use client';

import { useEffect, useState } from 'react';
import { supabase } from '@/lib/supabase';
import { User, Mail, Shield, ArrowLeft, Camera, LogOut } from 'lucide-react';
import { useRouter } from 'next/navigation';
import { motion } from 'framer-motion';

export default function ProfilePage() {
  const router = useRouter();
  const [profile, setProfile] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function getProfile() {
      const { data: { user } } = await supabase.auth.getUser();
      if (user) {
        const { data } = await supabase
          .from('profiles')
          .select('*')
          .eq('id', user.id)
          .single();
        setProfile({ ...data, email: user.email });
      }
      setLoading(false);
    }
    getProfile();
  }, []);

  const handleLogout = async () => {
    await supabase.auth.signOut();
    router.push('/login');
  };

  if (loading) return null;

  return (
    <div className="animate-fade-in page-container">
      <header style={{ marginBottom: '3rem', display: 'flex', alignItems: 'center', gap: '1rem' }}>
        <button onClick={() => router.back()} className="glass" style={{ padding: '0.6rem', borderRadius: '12px', border: '1px solid var(--border)', cursor: 'pointer' }}>
          <ArrowLeft size={20} />
        </button>
        <h1 style={{ fontWeight: 900, letterSpacing: '-0.04em' }}>Mi Perfil</h1>
      </header>

      <div style={{ maxWidth: '900px', margin: '0 auto' }}>
        <div className="card-premium" style={{ padding: '3rem', position: 'relative', overflow: 'hidden' }}>
          {/* Cover Decor */}
          <div style={{ position: 'absolute', top: 0, left: 0, right: 0, height: '120px', background: 'linear-gradient(135deg, #0d9488 0%, #065f46 100%)', zIndex: 0 }} />
          
          <div style={{ position: 'relative', zIndex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
            <div style={{ position: 'relative', marginBottom: '1.5rem' }}>
              <div style={{ width: '120px', height: '120px', borderRadius: '40px', background: 'var(--card)', border: '6px solid var(--card)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#0d9488', boxShadow: '0 10px 30px rgba(0,0,0,0.1)' }}>
                <User size={64} />
              </div>
              <button style={{ position: 'absolute', bottom: '-5px', right: '-5px', background: 'white', color: '#0d9488', padding: '0.5rem', borderRadius: '12px', border: '1px solid var(--border)', cursor: 'pointer', boxShadow: 'var(--shadow-md)' }}>
                <Camera size={18} />
              </button>
            </div>
            
            <h2 style={{ fontSize: '2rem', fontWeight: 900, marginBottom: '0.25rem', letterSpacing: '-0.04em' }}>{profile?.full_name || 'Usuario FishBit'}</h2>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', color: 'var(--muted-foreground)', fontWeight: 700, fontSize: '0.9rem', marginBottom: '2.5rem' }}>
              <span className="glass" style={{ padding: '4px 12px', borderRadius: '20px', background: 'rgba(13, 148, 136, 0.1)', color: '#0d9488', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                {profile?.is_superadmin ? 'Super Administrador' : 'Administrador de Granja'}
              </span>
            </div>

            <div className="responsive-grid-2" style={{ width: '100%', textAlign: 'left', gap: '1.5rem' }}>
              <div className="glass" style={{ padding: '1.5rem', borderRadius: '20px' }}>
                <div style={{ color: 'var(--muted-foreground)', fontSize: '0.7rem', fontWeight: 900, textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: '0.75rem' }}>Email Principal</div>
                <div style={{ fontWeight: 800, display: 'flex', alignItems: 'center', gap: '0.75rem', fontSize: '1.05rem' }}>
                  <Mail size={20} style={{ color: '#0d9488' }} /> {profile?.email}
                </div>
              </div>
              <div className="glass" style={{ padding: '1.5rem', borderRadius: '20px' }}>
                <div style={{ color: 'var(--muted-foreground)', fontSize: '0.7rem', fontWeight: 900, textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: '0.75rem' }}>Nivel de Acceso</div>
                <div style={{ fontWeight: 800, display: 'flex', alignItems: 'center', gap: '0.75rem', fontSize: '1.05rem' }}>
                  <Shield size={20} style={{ color: '#0d9488' }} /> {profile?.is_superadmin ? 'Control Total' : 'Gestión Operativa'}
                </div>
              </div>
            </div>

            <div style={{ display: 'flex', gap: '1rem', width: '100%', marginTop: '3rem' }}>
              <button className="btn-primary" style={{ flex: 2, padding: '1.25rem', background: '#0d9488', borderRadius: '18px', fontWeight: 900 }}>
                Editar Información
              </button>
              <button onClick={handleLogout} className="glass" style={{ flex: 1, padding: '1.25rem', borderRadius: '18px', fontWeight: 900, color: '#ef4444', border: '1px solid rgba(239, 68, 68, 0.2)', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '0.5rem' }}>
                <LogOut size={20} /> Salir
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
