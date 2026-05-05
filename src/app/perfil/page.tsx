'use client';

import { useEffect, useState } from 'react';
import { supabase } from '@/lib/supabase';
import { User, Mail, Shield, ArrowLeft } from 'lucide-react';
import Link from 'next/link';

export default function ProfilePage() {
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

  if (loading) return <div style={{ padding: '2rem', textAlign: 'center' }}>Cargando perfil...</div>;

  return (
    <div style={{ padding: '2rem', maxWidth: '800px', margin: '0 auto' }}>
      <Link href="/" style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', color: 'var(--primary)', textDecoration: 'none', marginBottom: '2rem', fontWeight: 600 }}>
        <ArrowLeft size={18} /> Volver al Dashboard
      </Link>

      <div className="card-premium" style={{ padding: '3rem', textAlign: 'center' }}>
        <div style={{ width: '100px', height: '100px', borderRadius: '30px', background: 'linear-gradient(135deg, #3b82f6, #8b5cf6)', margin: '0 auto 1.5rem', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'white' }}>
          <User size={48} />
        </div>
        
        <h1 style={{ fontSize: '2rem', fontWeight: 900, marginBottom: '0.5rem' }}>{profile?.full_name || 'Usuario FishBit'}</h1>
        <p style={{ color: 'var(--muted-foreground)', marginBottom: '2rem' }}>{profile?.is_superadmin ? 'Super Administrador' : 'Productor Acuícola'}</p>

        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '1.5rem', textAlign: 'left' }}>
          <div style={{ padding: '1.5rem', background: 'var(--secondary)', borderRadius: '16px' }}>
            <div style={{ color: 'var(--muted-foreground)', fontSize: '0.75rem', fontWeight: 800, textTransform: 'uppercase', marginBottom: '0.5rem' }}>Email de Acceso</div>
            <div style={{ fontWeight: 600, display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <Mail size={16} /> {profile?.email}
            </div>
          </div>
          <div style={{ padding: '1.5rem', background: 'var(--secondary)', borderRadius: '16px' }}>
            <div style={{ color: 'var(--muted-foreground)', fontSize: '0.75rem', fontWeight: 800, textTransform: 'uppercase', marginBottom: '0.5rem' }}>Rol del Sistema</div>
            <div style={{ fontWeight: 600, display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <Shield size={16} /> {profile?.is_superadmin ? 'SuperAdmin' : 'Admin'}
            </div>
          </div>
        </div>

        <button className="btn-primary" style={{ marginTop: '3rem', padding: '1rem 2rem' }}>
          Editar Perfil
        </button>
      </div>
    </div>
  );
}
