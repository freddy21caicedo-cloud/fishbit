'use client';

import { useEffect, useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  ClipboardList, 
  Utensils, 
  Scale, 
  Droplets, 
  AlertTriangle, 
  ArrowRightLeft,
  Plus,
  History,
  ChevronDown,
  Waves,
  ChevronRight
} from 'lucide-react';
import Link from 'next/link';
import { supabase } from '@/lib/supabase';

const recordTypes = [
  { id: 'alimentacion', label: 'Alimentación', icon: Utensils, color: '#10b981', bg: 'rgba(16, 185, 129, 0.1)' },
  { id: 'biometria', label: 'Biometría', icon: Scale, color: '#8b5cf6', bg: 'rgba(139, 92, 246, 0.1)' },
  { id: 'calidad-agua', label: 'Calidad de Agua', icon: Droplets, color: '#3b82f6', bg: 'rgba(59, 130, 246, 0.1)' },
  { id: 'mortalidad', label: 'Mortalidad', icon: AlertTriangle, color: '#ef4444', bg: 'rgba(239, 68, 68, 0.1)' },
  { id: 'traslado', label: 'Traslado', icon: ArrowRightLeft, color: '#f59e0b', bg: 'rgba(245, 158, 11, 0.1)' },
];

const ActionCard = ({ type }: any) => (
  <Link href={`/registros/${type.id}`} style={{ flex: 1, textDecoration: 'none' }}>
    <motion.div
      whileHover={{ y: -5, scale: 1.02 }}
      whileTap={{ scale: 0.98 }}
      style={{
        background: 'var(--card)',
        border: '1px solid var(--border)',
        borderRadius: 'var(--radius)',
        padding: '1.25rem',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        gap: '1rem',
        cursor: 'pointer',
        textAlign: 'center',
        transition: 'box-shadow 0.2s ease',
        boxShadow: 'var(--shadow-sm)',
        minWidth: '160px',
      }}
    >
      <div style={{
        width: '48px',
        height: '48px',
        borderRadius: '12px',
        background: type.bg,
        color: type.color,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center'
      }}>
        <type.icon size={24} />
      </div>
      <span style={{ fontWeight: 600, fontSize: '0.9rem', color: 'var(--foreground)' }}>{type.label}</span>
      <div style={{ display: 'flex', alignItems: 'center', gap: '0.25rem', fontSize: '0.75rem', color: 'var(--muted-foreground)', fontWeight: 500 }}>
        <Plus size={14} />
        Nuevo
      </div>
    </motion.div>
  </Link>
);

export default function RegistrosPage() {
  const [selectedPond, setSelectedPond] = useState('Todos los Estanques');
  const [ponds, setPonds] = useState<any[]>(['Todos los Estanques']);
  const [activities, setActivities] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchInitialData();
  }, []);

  const fetchInitialData = async () => {
    setLoading(true);
    const activeUnitId = localStorage.getItem('active_unit_id');
    if (!activeUnitId) { setLoading(false); return; }

    // 1. Fetch Ponds
    const { data: pondsData } = await supabase
      .from('estanques')
      .select('name')
      .eq('unit_id', activeUnitId)
      .order('name');
    
    if (pondsData) {
      setPonds(['Todos los Estanques', ...pondsData.map(p => p.name)]);
    }

    // 2. Fetch Activity from all tables
    const [alimentacion, biometrias, calidadAgua, mortalidad, traslados] = await Promise.all([
      supabase.from('alimentacion_diaria').select('*, estanques(name)').eq('unit_id', activeUnitId).order('created_at', { ascending: false }).limit(5),
      supabase.from('biometria').select('*, estanques(name)').eq('unit_id', activeUnitId).order('created_at', { ascending: false }).limit(5),
      supabase.from('water_quality').select('*, estanques(name)').eq('unit_id', activeUnitId).order('created_at', { ascending: false }).limit(5),
      supabase.from('mortality').select('*, estanques(name)').eq('unit_id', activeUnitId).order('created_at', { ascending: false }).limit(5),
      supabase.from('transfers').select('*, origen:estanques!origen_id(name), destino:estanques!destino_id(name)').eq('unit_id', activeUnitId).order('created_at', { ascending: false }).limit(5),
    ]);

    const combined: any[] = [
      ...(alimentacion.data || []).map(a => ({
        id: `ali-${a.id}`,
        type: 'alimentacion',
        pond: a.estanques?.name,
        species: a.species_name,
        detail: `Suministro de ${a.quantity_kg}kg (${a.species_name})`,
        time: new Date(a.created_at).toLocaleString(),
        rawDate: a.created_at
      })),
      ...(biometrias.data || []).map(b => ({
        id: `bio-${b.id}`,
        type: 'biometria',
        pond: b.estanques?.name,
        species: b.species_name,
        detail: `Peso: ${b.avg_weight_gr || b.average_weight_g}g (${b.species_name})`,
        time: new Date(b.created_at).toLocaleString(),
        rawDate: b.created_at
      })),
      ...(calidadAgua.data || []).map(c => ({
        id: `cal-${c.id}`,
        type: 'calidad-agua',
        pond: c.estanques?.name,
        species: 'N/A',
        detail: `O2: ${c.o2_mg_l}mg/L | pH: ${c.ph}`,
        time: new Date(c.created_at).toLocaleString(),
        rawDate: c.created_at
      })),
      ...(mortalidad.data || []).map(m => ({
        id: `mor-${m.id}`,
        type: 'mortalidad',
        pond: m.estanques?.name,
        species: m.species_name,
        detail: `Baja de ${m.quantity} (${m.species_name})`,
        time: new Date(m.created_at).toLocaleString(),
        rawDate: m.created_at
      })),
      ...(traslados.data || []).map(t => ({
        id: `tra-${t.id}`,
        type: 'traslado',
        pond: t.origen?.name,
        species: t.species_name,
        detail: `Traslado de ${t.quantity} (${t.species_name}) hacia ${t.destino?.name}`,
        time: new Date(t.created_at).toLocaleString(),
        rawDate: t.created_at
      })),
    ].sort((a, b) => new Date(b.rawDate).getTime() - new Date(a.rawDate).getTime());

    setActivities(combined);
    setLoading(false);
  };

  const filteredActivity = selectedPond === 'Todos los Estanques' 
    ? activities 
    : activities.filter(a => a.pond === selectedPond);

  return (
    <div className="animate-fade-in">
      <header style={{ marginBottom: '2.5rem' }}>
        <h1 style={{ fontSize: '1.875rem', fontWeight: 700, marginBottom: '0.5rem' }}>Bitácora de Registros</h1>
        <p style={{ color: 'var(--muted-foreground)' }}>Selecciona el tipo de registro que deseas ingresar hoy.</p>
      </header>

      {/* Action Cards Grid */}
      <div style={{ 
        display: 'flex', 
        gap: '1rem', 
        marginBottom: '3rem',
        overflowX: 'auto',
        paddingBottom: '1rem' 
      }}>
        {recordTypes.map(type => (
          <ActionCard key={type.id} type={type} />
        ))}
      </div>

      {/* Recent Activity Section */}
      <div style={{ marginBottom: '1.5rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
          <History size={20} style={{ color: 'var(--primary)' }} />
          <h2 style={{ fontSize: '1.25rem', fontWeight: 600 }}>Actividad Reciente</h2>
        </div>
        
        {/* Pond Selector */}
        <div style={{ position: 'relative' }}>
          <select 
            value={selectedPond}
            onChange={(e) => setSelectedPond(e.target.value)}
            style={{ 
              appearance: 'none',
              padding: '0.625rem 2.5rem 0.625rem 1rem', 
              borderRadius: '8px', 
              border: '1px solid var(--border)', 
              background: 'var(--card)',
              outline: 'none',
              fontSize: '0.875rem',
              fontWeight: 600,
              cursor: 'pointer',
              color: 'var(--foreground)',
              minWidth: '200px'
            }}
          >
            {ponds.map(pond => (
              <option key={pond} value={pond}>{pond}</option>
            ))}
          </select>
          <ChevronDown size={16} style={{ position: 'absolute', right: '0.75rem', top: '50%', transform: 'translateY(-50%)', color: 'var(--muted-foreground)', pointerEvents: 'none' }} />
        </div>
      </div>

      <div className="card-premium" style={{ padding: '0.5rem', overflow: 'hidden' }}>
        {loading ? (
          <div style={{ padding: '4rem 2rem', textAlign: 'center', color: 'var(--muted-foreground)' }}>
            Cargando bitácora...
          </div>
        ) : filteredActivity.length > 0 ? (
          <div style={{ display: 'flex', flexDirection: 'column' }}>
            {filteredActivity.map((activity, index) => {
              const type = recordTypes.find(t => t.id === activity.type);
              return (
                <div 
                  key={activity.id} 
                  style={{ 
                    display: 'flex', 
                    alignItems: 'center', 
                    padding: '1.25rem', 
                    borderBottom: index === filteredActivity.length - 1 ? 'none' : '1px solid var(--border)',
                    transition: 'background 0.2s ease',
                    cursor: 'pointer'
                  }}
                  onMouseEnter={(e) => e.currentTarget.style.background = 'var(--secondary)'}
                  onMouseLeave={(e) => e.currentTarget.style.background = 'transparent'}
                >
                  <div style={{ 
                    width: '40px', 
                    height: '40px', 
                    borderRadius: '10px', 
                    background: type?.bg, 
                    color: type?.color,
                    display: 'flex', 
                    alignItems: 'center', 
                    justifyContent: 'center',
                    marginRight: '1rem',
                    flexShrink: 0
                  }}>
                    {type && <type.icon size={20} />}
                  </div>
                  <div style={{ flex: 1 }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '0.125rem' }}>
                      <span style={{ fontWeight: 700, fontSize: '0.95rem' }}>{type?.label}</span>
                      <span style={{ fontSize: '0.75rem', padding: '0.125rem 0.375rem', background: 'var(--secondary)', borderRadius: '4px', color: 'var(--muted-foreground)', fontWeight: 600 }}>{activity.pond}</span>
                      {activity.species && activity.species !== 'N/A' && (
                        <span style={{ fontSize: '0.75rem', padding: '0.125rem 0.375rem', background: 'rgba(59, 130, 246, 0.1)', borderRadius: '4px', color: '#3b82f6', fontWeight: 800 }}>{activity.species}</span>
                      )}
                    </div>
                    <div style={{ fontSize: '0.875rem', color: 'var(--muted-foreground)' }}>{activity.detail}</div>
                  </div>
                  <div style={{ textAlign: 'right', fontSize: '0.75rem', color: 'var(--muted-foreground)' }}>
                    <div style={{ fontWeight: 600, color: 'var(--foreground)', marginBottom: '0.125rem' }}>{activity.time}</div>
                  </div>
                  <ChevronRight size={18} style={{ marginLeft: '1rem', color: 'var(--border)' }} />
                </div>
              );
            })}
          </div>
        ) : (
          <div style={{ padding: '4rem 2rem', textAlign: 'center' }}>
            <div style={{ color: 'var(--muted-foreground)', marginBottom: '1rem' }}>
              <ClipboardList size={48} style={{ margin: '0 auto', opacity: 0.3 }} />
            </div>
            <p style={{ color: 'var(--muted-foreground)' }}>No hay actividad registrada para {selectedPond}.</p>
          </div>
        )}
      </div>
    </div>
  );
}
