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
  ChevronRight,
  Trash2,
  Loader2
} from 'lucide-react';
import Link from 'next/link';
import { supabase } from '@/lib/supabase';
import { toast } from 'react-hot-toast';
import { useUnit } from '../components/providers/UnitProvider';

const recordTypes = [
  { id: 'alimentacion', label: 'Alimentación', icon: Utensils, color: '#10b981', bg: 'rgba(16, 185, 129, 0.1)' },
  { id: 'biometria', label: 'Biometría', icon: Scale, color: '#8b5cf6', bg: 'rgba(139, 92, 246, 0.1)' },
  { id: 'calidad-agua', label: 'Calidad de Agua', icon: Droplets, color: '#3b82f6', bg: 'rgba(59, 130, 246, 0.1)' },
  { id: 'mortalidad', label: 'Mortalidad', icon: AlertTriangle, color: '#ef4444', bg: 'rgba(239, 68, 68, 0.1)' },
  { id: 'traslados', label: 'Traslado', icon: ArrowRightLeft, color: '#f59e0b', bg: 'rgba(245, 158, 11, 0.1)' },
];

const ActionCard = ({ type }: any) => (
  <Link href={`/registros/${type.id}`} style={{ textDecoration: 'none' }}>
    <motion.div
      whileHover={{ scale: 1.02, x: 5 }}
      whileTap={{ scale: 0.98 }}
      className="card-premium"
      style={{
        padding: '1rem 1.25rem',
        display: 'flex',
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'space-between',
        cursor: 'pointer',
        border: '1px solid var(--border)',
        transition: 'all 0.2s ease'
      }}
    >
      <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
        <div style={{
          width: '44px',
          height: '44px',
          borderRadius: '12px',
          background: type.bg,
          color: type.color,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          flexShrink: 0
        }}>
          <type.icon size={22} />
        </div>
        <span style={{ fontWeight: 800, fontSize: '0.95rem', color: 'var(--foreground)', letterSpacing: '-0.02em' }}>
          {type.label}
        </span>
      </div>
      
      <div style={{ 
        width: '32px', 
        height: '32px', 
        borderRadius: '50%', 
        background: 'var(--secondary)', 
        display: 'flex', 
        alignItems: 'center', 
        justifyContent: 'center',
        color: 'var(--primary)'
      }}>
        <Plus size={18} strokeWidth={3} />
      </div>
    </motion.div>
  </Link>
);

export default function RegistrosPage() {
  const { userRole } = useUnit();
  const [selectedPond, setSelectedPond] = useState('Todos los Estanques');
  const [ponds, setPonds] = useState<any[]>(['Todos los Estanques']);
  const [activities, setActivities] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [isDeleting, setIsDeleting] = useState<string | null>(null);
  const [fechaDesde, setFechaDesde] = useState('');
  const [fechaHasta, setFechaHasta] = useState('');

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
      setPonds(['Todos los Estanques', ...pondsData.map((p: any) => p.name)]);
    }

    // 2. Fetch Activity from all tables
    const [alimentacion, biometrias, calidadAgua, mortalidad, traslados] = await Promise.all([
      supabase.from('alimentacion_diaria').select('*, estanques(name), inventory(name)').eq('unit_id', activeUnitId).order('date', { ascending: false }).limit(30),
      supabase.from('biometrias').select('*, estanques(name)').eq('unit_id', activeUnitId).order('date', { ascending: false }).limit(30),
      supabase.from('water_quality').select('*, estanques(name)').eq('unit_id', activeUnitId).order('date', { ascending: false }).limit(30),
      supabase.from('mortalidad').select('*, estanques(name)').eq('unit_id', activeUnitId).order('date', { ascending: false }).limit(30),
      supabase.from('transfers').select('*, origen:estanques!origen_id(name), destino:estanques!destino_id(name)').eq('unit_id', activeUnitId).order('created_at', { ascending: false }).limit(30),
    ]);

    // Build batch to species name map
    const { data: siembrasData } = await supabase
      .from('siembras')
      .select('batch_id, siembra_details(species_name)')
      .eq('unit_id', activeUnitId);

    const batchMap: Record<string, string> = {};
    siembrasData?.forEach((s: any) => {
      if (s.batch_id && s.siembra_details && s.siembra_details.length > 0) {
        batchMap[s.batch_id] = s.siembra_details[0].species_name;
      }
    });

    const { data: activeSpecies } = await supabase
      .from('pond_species')
      .select('batch_id, species_name')
      .eq('unit_id', activeUnitId);
    
    activeSpecies?.forEach((s: any) => {
      if (s.batch_id) {
        batchMap[s.batch_id] = s.species_name;
      }
    });

    // Helper: format water quality params
    const formatWQ = (c: any) => {
      const params: string[] = [];
      if (c.o2_mg_l != null) params.push(`O₂: ${c.o2_mg_l} mg/L`);
      if (c.ph != null) params.push(`pH: ${c.ph}`);
      if (c.temperature_c != null) params.push(`T°: ${c.temperature_c}°C`);
      if (c.alkalinity != null) params.push(`Alc: ${c.alkalinity}`);
      if (c.ammonia_mg_l != null) params.push(`NH₃: ${c.ammonia_mg_l}`);
      if (c.nitrite_mg_l != null) params.push(`NO₂: ${c.nitrite_mg_l}`);
      if (c.nitrate_mg_l != null) params.push(`NO₃: ${c.nitrate_mg_l}`);
      if (params.length <= 3) return params.join(' | ');
      return params.slice(0, 3).join(' | ') + ` + ${params.length - 3} más`;
    };

    const combined: any[] = [
      ...(alimentacion.data || []).map((a: any) => ({
        id: `ali-${a.id}`,
        type: 'alimentacion',
        pond: a.estanques?.name,
        detail: `${(a.inventory as any)?.name || 'Alimento'} · ${a.quantity_kg} kg`,
        rawDate: a.date || a.created_at,
        originalId: a.id
      })),
      ...(biometrias.data || []).map((b: any) => ({
        id: `bio-${b.id}`,
        type: 'biometria',
        pond: b.estanques?.name,
        detail: `${b.species_name || 'Esp.'} · ${b.avg_weight_gr || b.average_weight_g || '—'} g/ud · ${b.total_biomass_kg || '—'} kg biomasa`,
        rawDate: b.date || b.created_at,
        originalId: b.id
      })),
      ...(calidadAgua.data || []).map((c: any) => ({
        id: `cal-${c.id}`,
        type: 'calidad-agua',
        pond: c.estanques?.name,
        detail: formatWQ(c),
        rawDate: c.date || c.created_at,
        originalId: c.id
      })),
      ...(mortalidad.data || []).map((m: any) => ({
        id: `mor-${m.id}`,
        type: 'mortalidad',
        pond: m.estanques?.name,
        detail: `${m.batch_id ? (batchMap[m.batch_id] || 'Especie') : 'Especie'} ${m.batch_id ? `(${m.batch_id})` : ''} · ${m.quantity} baja(s) · ${m.cause || ''}`,
        rawDate: m.date || m.created_at,
        originalId: m.id
      })),
      ...(traslados.data || [])
        .filter((t: any) => !t.revertido) // Punto 5.2: Ocultar traslados revertidos
        .map((t: any) => ({
        id: `tra-${t.id}`,
        type: 'traslado',
        pond: (t.origen as any)?.name,
        detail: `${t.quantity} ${t.species_name || 'uds'} · de ${(t.origen as any)?.name || '—'} → ${(t.destino as any)?.name || '—'}`,
        rawDate: t.date || t.created_at,
        originalId: t.id
      })),
    ].sort((a: any, b: any) => new Date(b.rawDate).getTime() - new Date(a.rawDate).getTime());

    setActivities(combined);
    setLoading(false);
  };

  const filteredActivity = activities.filter(a => {
    const matchPond = selectedPond === 'Todos los Estanques' || a.pond === selectedPond;
    const matchDesde = !fechaDesde || a.rawDate >= fechaDesde;
    const matchHasta = !fechaHasta || a.rawDate <= fechaHasta + 'T23:59:59';
    return matchPond && matchDesde && matchHasta;
  });

  const handleDeleteRecord = async (e: React.MouseEvent, record: any) => {
    e.stopPropagation();
    if (!confirm('¿Estás seguro de que deseas eliminar este registro? Esta acción no se puede deshacer.')) return;
    
    setIsDeleting(record.id);
    try {
      let tableName = '';
      if (record.type === 'alimentacion') tableName = 'alimentacion_diaria';
      if (record.type === 'biometria') tableName = 'biometrias';
      if (record.type === 'calidad-agua') tableName = 'water_quality';
      if (record.type === 'mortalidad') tableName = 'mortalidad';
      if (record.type === 'traslado') tableName = 'transfers';

      if (!tableName || !record.originalId) throw new Error('Tipo de registro no soportado o ID inválido');

      const { error } = await supabase.from(tableName).delete().eq('id', record.originalId);
      if (error) throw error;
      
      toast.success('Registro eliminado exitosamente');
      setActivities(prev => prev.filter(a => a.id !== record.id));
    } catch (error: any) {
      toast.error('Error al eliminar: ' + error.message);
    } finally {
      setIsDeleting(null);
    }
  };

  return (
    <div className="animate-fade-in page-container">
      <header style={{ marginBottom: '2.5rem' }}>
        <h1 style={{ fontWeight: 800 }}>Bitácora de Registros</h1>
        <p style={{ color: 'var(--muted-foreground)' }}>Selecciona el tipo de registro que deseas ingresar hoy.</p>
      </header>

      {/* Modern Compact Grid */}
      <div style={{ 
        display: 'grid', 
        gridTemplateColumns: 'repeat(auto-fit, minmax(260px, 1fr))', 
        gap: '1rem', 
        marginBottom: '3.5rem' 
      }}>
        {recordTypes.map(type => (
          <ActionCard key={type.id} type={type} />
        ))}
      </div>

      {/* Recent Activity Section */}
      <div style={{ marginBottom: '1.5rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
          <History size={20} style={{ color: 'var(--primary)' }} />
          <h2 style={{ fontSize: '1.25rem', fontWeight: 600 }}>Actividad Reciente</h2>
        </div>
        
        {/* Pond Selector + Date Filters */}
        <div style={{ display: 'flex', gap: '0.75rem', flexWrap: 'wrap', alignItems: 'center' }}>
          {/* Pond selector */}
          <div style={{ position: 'relative' }}>
            <select 
              value={selectedPond}
              onChange={(e) => setSelectedPond(e.target.value)}
              style={{ appearance: 'none', padding: '0.625rem 2.5rem 0.625rem 1rem', borderRadius: '8px', border: '1px solid var(--border)', background: 'var(--card)', outline: 'none', fontSize: '0.875rem', fontWeight: 600, cursor: 'pointer', color: 'var(--foreground)', minWidth: '180px' }}
            >
              {ponds.map(pond => (
                <option key={pond} value={pond}>{pond}</option>
              ))}
            </select>
            <ChevronDown size={16} style={{ position: 'absolute', right: '0.75rem', top: '50%', transform: 'translateY(-50%)', color: 'var(--muted-foreground)', pointerEvents: 'none' }} />
          </div>

          {/* Date from */}
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
            <span style={{ fontSize: '0.78rem', fontWeight: 700, color: 'var(--muted-foreground)', whiteSpace: 'nowrap' }}>Desde</span>
            <input
              type="date"
              value={fechaDesde}
              onChange={(e) => setFechaDesde(e.target.value)}
              style={{ padding: '0.5rem 0.75rem', borderRadius: '8px', border: '1px solid var(--border)', background: 'var(--card)', fontSize: '0.85rem', fontWeight: 600, color: 'var(--foreground)', outline: 'none', cursor: 'pointer' }}
            />
          </div>

          {/* Date to */}
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
            <span style={{ fontSize: '0.78rem', fontWeight: 700, color: 'var(--muted-foreground)', whiteSpace: 'nowrap' }}>Hasta</span>
            <input
              type="date"
              value={fechaHasta}
              onChange={(e) => setFechaHasta(e.target.value)}
              style={{ padding: '0.5rem 0.75rem', borderRadius: '8px', border: '1px solid var(--border)', background: 'var(--card)', fontSize: '0.85rem', fontWeight: 600, color: 'var(--foreground)', outline: 'none', cursor: 'pointer' }}
            />
          </div>

          {/* Clear button */}
          {(fechaDesde || fechaHasta) && (
            <button
              onClick={() => { setFechaDesde(''); setFechaHasta(''); }}
              style={{ padding: '0.5rem 0.9rem', borderRadius: '8px', border: '1px solid var(--border)', background: 'var(--card)', fontSize: '0.8rem', fontWeight: 700, color: 'var(--muted-foreground)', cursor: 'pointer' }}
            >
              Limpiar
            </button>
          )}
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
                    <div style={{ fontSize: '0.72rem', color: 'var(--muted-foreground)', marginTop: '0.1rem' }}>
                      {activity.rawDate ? new Date(activity.rawDate).toLocaleDateString('es-CO', { day: '2-digit', month: 'short', year: 'numeric' }) : ''}
                    </div>
                  </div>
                  <div style={{ textAlign: 'right', fontSize: '0.75rem', color: 'var(--muted-foreground)', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                    {userRole !== 'operario' && (
                      <button 
                        onClick={(e) => handleDeleteRecord(e, activity)}
                        disabled={isDeleting === activity.id}
                        style={{ 
                          background: 'none', border: 'none', cursor: 'pointer', color: '#ef4444', 
                          padding: '0.4rem', borderRadius: '8px', display: 'flex', alignItems: 'center',
                          justifyContent: 'center', transition: 'background 0.2s ease'
                        }}
                        onMouseEnter={(e) => e.currentTarget.style.background = 'rgba(239, 68, 68, 0.1)'}
                        onMouseLeave={(e) => e.currentTarget.style.background = 'transparent'}
                        title="Eliminar Registro"
                      >
                        {isDeleting === activity.id ? <Loader2 size={18} className="animate-spin" /> : <Trash2 size={18} />}
                      </button>
                    )}
                    <ChevronRight size={18} style={{ color: 'var(--border)' }} />
                  </div>
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
