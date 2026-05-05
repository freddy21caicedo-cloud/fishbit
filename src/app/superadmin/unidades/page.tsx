'use client';

import { useEffect, useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { supabase } from '@/lib/supabase';
import { 
  Globe, 
  Search, 
  Plus, 
  MapPin, 
  Activity, 
  TrendingUp, 
  MoreVertical,
  Navigation,
  Loader2,
  Filter,
  Users
} from 'lucide-react';

export default function UnitsManagementPage() {
  const [units, setUnits] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => {
    fetchUnits();
  }, []);

  const fetchUnits = async () => {
    setLoading(true);
    const { data, error } = await supabase
      .from('units')
      .select(`
        *,
        user_units(count),
        subscriptions(status, plan_type)
      `)
      .order('created_at', { ascending: false });

    if (!error) setUnits(data);
    setLoading(false);
  };

  if (loading) {
    return (
      <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <Loader2 className="animate-spin" size={40} color="var(--primary)" />
      </div>
    );
  }

  return (
    <div style={{ padding: '2rem', maxWidth: '1200px', margin: '0 auto' }}>
      <header style={{ marginBottom: '3rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <h1 style={{ fontSize: '2rem', fontWeight: 800, marginBottom: '0.5rem' }}>Unidades Acuícolas</h1>
          <p style={{ color: 'var(--muted-foreground)' }}>Supervisión y control de todas las sedes productivas activas.</p>
        </div>
        <div style={{ display: 'flex', gap: '1rem' }}>
          <div style={{ position: 'relative' }}>
            <Search size={18} style={{ position: 'absolute', left: '1rem', top: '50%', transform: 'translateY(-50%)', color: 'var(--muted-foreground)' }} />
            <input 
              type="text" 
              placeholder="Buscar unidad..." 
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              style={{ padding: '0.75rem 1rem 0.75rem 2.75rem', borderRadius: '12px', border: '1px solid var(--border)', background: 'var(--card)', width: '250px', outline: 'none' }}
            />
          </div>
          <button className="btn-primary" style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', padding: '0.75rem 1.5rem' }}>
            <Plus size={20} />
            Nueva Unidad
          </button>
        </div>
      </header>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(350px, 1fr))', gap: '1.5rem' }}>
        {units.map((unit) => (
          <motion.div 
            key={unit.id}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="card-premium"
            style={{ padding: '1.5rem', position: 'relative' }}
          >
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '1.5rem' }}>
              <div style={{ padding: '0.75rem', background: 'rgba(37, 99, 235, 0.1)', borderRadius: '12px', color: 'var(--primary)' }}>
                <Navigation size={24} />
              </div>
              <div style={{ display: 'flex', gap: '0.5rem' }}>
                <span style={{ 
                  padding: '0.25rem 0.625rem', 
                  borderRadius: '20px', 
                  background: unit.subscriptions?.[0]?.status === 'active' ? 'rgba(16, 185, 129, 0.1)' : 'rgba(245, 158, 11, 0.1)', 
                  color: unit.subscriptions?.[0]?.status === 'active' ? '#10b981' : '#f59e0b',
                  fontSize: '0.65rem', 
                  fontWeight: 800,
                  textTransform: 'uppercase'
                }}>
                  {unit.subscriptions?.[0]?.plan_type || 'FREE'}
                </span>
                <button style={{ background: 'none', border: 'none', color: 'var(--muted-foreground)', cursor: 'pointer' }}>
                  <MoreVertical size={20} />
                </button>
              </div>
            </div>

            <h3 style={{ fontSize: '1.25rem', fontWeight: 800, marginBottom: '0.5rem' }}>{unit.name}</h3>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', color: 'var(--muted-foreground)', fontSize: '0.875rem', marginBottom: '1.5rem' }}>
              <MapPin size={16} />
              {unit.location || 'Ubicación no especificada'}
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem', padding: '1rem', background: 'var(--secondary)', borderRadius: '12px' }}>
              <div>
                <div style={{ fontSize: '0.7rem', fontWeight: 800, color: 'var(--muted-foreground)', textTransform: 'uppercase', marginBottom: '0.25rem' }}>Equipo</div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', fontWeight: 700 }}>
                  <Users size={14} />
                  {unit.user_units?.[0]?.count || 0} Miembros
                </div>
              </div>
              <div>
                <div style={{ fontSize: '0.7rem', fontWeight: 800, color: 'var(--muted-foreground)', textTransform: 'uppercase', marginBottom: '0.25rem' }}>Estado</div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', fontWeight: 700, color: '#10b981' }}>
                  <Activity size={14} />
                  Operativo
                </div>
              </div>
            </div>

            <div style={{ marginTop: '1.5rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <span style={{ fontSize: '0.75rem', color: 'var(--muted-foreground)' }}>ID: {unit.id.slice(0, 8)}...</span>
              <button style={{ color: 'var(--primary)', fontWeight: 700, background: 'none', border: 'none', fontSize: '0.875rem', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '0.25rem' }}>
                Ver Detalles
                <TrendingUp size={14} />
              </button>
            </div>
          </motion.div>
        ))}
      </div>
    </div>
  );
}
