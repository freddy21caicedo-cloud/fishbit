'use client';

import { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import { supabase } from '@/lib/supabase';
import { 
  Navigation, 
  ArrowRight, 
  Loader2,
  LogOut,
  Waves,
  Building2
} from 'lucide-react';
import { useRouter } from 'next/navigation';

export default function SelectUnitPage() {
  const router = useRouter();
  const [units, setUnits] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchUserUnits();
  }, []);

  const fetchUserUnits = async () => {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) {
      router.push('/login');
      return;
    }

    const { data, error } = await supabase
      .from('user_units')
      .select('unit_id, units(id, name, location)')
      .eq('user_id', user.id);

    if (data && data.length > 0) {
      setUnits(data.map((d: any) => d.units));
    }
    setLoading(false);
  };

  const handleSelectUnit = (unitId: string) => {
    // Store selected unit in local storage or cookie
    localStorage.setItem('active_unit_id', unitId);
    router.refresh();
    router.push('/');
  };

  const handleLogout = async () => {
    await supabase.auth.signOut();
    router.push('/login');
  };

  if (loading) {
    return (
      <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', background: 'var(--background)' }}>
        <Loader2 className="animate-spin" size={40} color="var(--primary)" />
      </div>
    );
  }

  return (
    <div style={{ 
      minHeight: '100vh', 
      display: 'flex', 
      flexDirection: 'column',
      background: 'radial-gradient(circle at top right, #f8fafc, #eff6ff)',
      padding: '2rem'
    }}>
      <div style={{ maxWidth: '600px', margin: 'auto', width: '100%' }}>
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
            boxShadow: '0 10px 25px rgba(37, 99, 235, 0.2)'
          }}>
            <Building2 color="white" size={32} />
          </div>
          <h1 style={{ fontSize: '2rem', fontWeight: 800, color: '#1e293b', marginBottom: '0.5rem' }}>Selecciona tu Unidad</h1>
          <p style={{ color: 'var(--muted-foreground)' }}>Tienes acceso a múltiples unidades acuícolas. Por favor elige una para continuar.</p>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
          {units.map((unit, index) => (
            <motion.button
              key={unit.id}
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: index * 0.1 }}
              onClick={() => handleSelectUnit(unit.id)}
              className="card-premium"
              style={{ 
                width: '100%', 
                padding: '1.5rem', 
                display: 'flex', 
                alignItems: 'center', 
                gap: '1.5rem', 
                textAlign: 'left',
                cursor: 'pointer',
                border: '1px solid transparent',
                transition: 'all 0.2s ease'
              }}
              onMouseEnter={(e) => {
                e.currentTarget.style.borderColor = 'var(--primary)';
                e.currentTarget.style.transform = 'translateY(-2px)';
              }}
              onMouseLeave={(e) => {
                e.currentTarget.style.borderColor = 'transparent';
                e.currentTarget.style.transform = 'translateY(0)';
              }}
            >
              <div style={{ 
                width: '48px', 
                height: '48px', 
                background: 'rgba(37, 99, 235, 0.05)', 
                borderRadius: '12px', 
                display: 'flex', 
                alignItems: 'center', 
                justifyContent: 'center', 
                color: 'var(--primary)' 
              }}>
                <Navigation size={24} />
              </div>
              <div style={{ flex: 1 }}>
                <h3 style={{ fontSize: '1.125rem', fontWeight: 700, marginBottom: '0.25rem' }}>{unit.name}</h3>
                <p style={{ fontSize: '0.875rem', color: 'var(--muted-foreground)' }}>{unit.location || 'Sin ubicación registrada'}</p>
              </div>
              <ArrowRight size={20} style={{ color: 'var(--muted-foreground)' }} />
            </motion.button>
          ))}
        </div>

        <button 
          onClick={handleLogout}
          style={{ 
            marginTop: '3rem', 
            width: '100%', 
            padding: '1rem', 
            display: 'flex', 
            alignItems: 'center', 
            justifyContent: 'center', 
            gap: '0.75rem', 
            background: 'none', 
            border: 'none', 
            color: 'var(--muted-foreground)', 
            fontWeight: 700, 
            cursor: 'pointer' 
          }}
        >
          <LogOut size={20} />
          Cerrar Sesión
        </button>
      </div>
    </div>
  );
}
