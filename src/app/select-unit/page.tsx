'use client';

import { useEffect, useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { supabase } from '@/lib/supabase';
import { 
  Navigation, 
  ArrowRight, 
  Loader2,
  LogOut,
  Building2,
  Waves,
  ChevronRight
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
      <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', background: '#f8fafc' }}>
        <Loader2 className="animate-spin" size={48} color="#0d9488" />
      </div>
    );
  }

  return (
    <div style={{ 
      minHeight: '100vh', 
      display: 'flex', 
      flexDirection: 'column',
      background: 'radial-gradient(circle at 0% 0%, #f0fdfa 0%, #f8fafc 100%)',
      padding: '2rem'
    }}>
      <div style={{ maxWidth: '500px', margin: 'auto', width: '100%' }}>
        <div style={{ textAlign: 'center', marginBottom: '3.5rem' }}>
          <motion.div 
            initial={{ scale: 0.8, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            style={{ 
              width: '80px', 
              height: '80px', 
              background: '#0d9488', 
              borderRadius: '24px', 
              display: 'flex', 
              alignItems: 'center', 
              justifyContent: 'center',
              margin: '0 auto 2rem',
              boxShadow: '0 20px 40px rgba(13, 148, 136, 0.2)',
              color: 'white'
            }}
          >
            <Building2 size={40} />
          </motion.div>
          <h1 style={{ fontSize: '2.5rem', fontWeight: 950, color: '#0f172a', marginBottom: '1rem', letterSpacing: '-0.04em' }}>Tus Unidades</h1>
          <p style={{ color: 'var(--muted-foreground)', fontWeight: 600, fontSize: '1.1rem' }}>Selecciona la granja que deseas gestionar hoy.</p>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
          <AnimatePresence>
            {units.map((unit, index) => (
              <motion.button
                key={unit.id}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: index * 0.1 }}
                onClick={() => handleSelectUnit(unit.id)}
                className="card-premium"
                style={{ 
                  width: '100%', 
                  padding: '1.75rem', 
                  display: 'flex', 
                  alignItems: 'center', 
                  gap: '1.5rem', 
                  textAlign: 'left',
                  cursor: 'pointer',
                  border: '1px solid var(--border)',
                  transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
                  position: 'relative',
                  overflow: 'hidden'
                }}
                onMouseEnter={(e) => {
                  e.currentTarget.style.borderColor = '#0d9488';
                  e.currentTarget.style.transform = 'translateY(-4px)';
                  e.currentTarget.style.boxShadow = '0 20px 40px rgba(0,0,0,0.05)';
                }}
                onMouseLeave={(e) => {
                  e.currentTarget.style.borderColor = 'var(--border)';
                  e.currentTarget.style.transform = 'translateY(0)';
                  e.currentTarget.style.boxShadow = 'var(--shadow-sm)';
                }}
              >
                <div style={{ 
                  width: '56px', 
                  height: '56px', 
                  background: 'rgba(13, 148, 136, 0.1)', 
                  borderRadius: '16px', 
                  display: 'flex', 
                  alignItems: 'center', 
                  justifyContent: 'center', 
                  color: '#0d9488' 
                }}>
                  <Navigation size={28} />
                </div>
                <div style={{ flex: 1 }}>
                  <h3 style={{ fontSize: '1.25rem', fontWeight: 900, marginBottom: '0.25rem', letterSpacing: '-0.02em' }}>{unit.name}</h3>
                  <p style={{ fontSize: '0.9rem', color: 'var(--muted-foreground)', fontWeight: 600 }}>{unit.location || 'Sede Principal'}</p>
                </div>
                <ChevronRight size={24} style={{ color: 'var(--border)' }} />
              </motion.button>
            ))}
          </AnimatePresence>
        </div>

        <button 
          onClick={handleLogout}
          style={{ 
            marginTop: '4rem', 
            width: '100%', 
            padding: '1rem', 
            display: 'flex', 
            alignItems: 'center', 
            justifyContent: 'center', 
            gap: '0.75rem', 
            background: 'none', 
            border: 'none', 
            color: 'var(--muted-foreground)', 
            fontWeight: 800, 
            cursor: 'pointer',
            fontSize: '0.95rem'
          }}
        >
          <LogOut size={20} />
          Cerrar Sesión Activa
        </button>
      </div>
    </div>
  );
}
