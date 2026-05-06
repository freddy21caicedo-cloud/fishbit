'use client';

import { useEffect, useState, useMemo } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import Link from 'next/link';
import { toast } from 'react-hot-toast';
import { 
  Plus, 
  X, 
  Calculator, 
  Waves, 
  Box, 
  Fish, 
  FlaskConical, 
  Settings, 
  Wind,
  Calendar,
  Hash,
  Dna,
  Pencil,
  Trash2
} from 'lucide-react';
import { supabase } from '@/lib/supabase';

// Helper Components
const PondIcon = ({ size = 24, color = 'currentColor' }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <path d="M2 12C2 7 6 3 12 3C18 3 22 7 22 12C22 17 18 21 12 21C6 21 2 17 2 12Z" fill="rgba(37, 99, 235, 0.1)" stroke="none" />
    <path d="M12 3C18 3 22 7 22 12C22 17 18 21 12 21C6 21 2 17 2 12C2 7 6 3 12 3Z" />
    <path d="M16 12C16 13.5 14.5 15 12 15C10.5 15 9 14.5 8 13.5L6 15V9L8 10.5C9 9.5 10.5 9 12 9C14.5 9 16 10.5 16 12Z" fill={color} stroke="none" />
    <circle cx="18" cy="18" r="1.5" fill="var(--muted-foreground)" stroke="none" />
    <circle cx="6" cy="6" r="1" fill="#10b981" stroke="none" />
  </svg>
);

const EditTooltip = ({ label, onClick }: { label: string, onClick?: () => void }) => {
  const [isHovered, setIsHovered] = useState(false);
  return (
    <>
      <AnimatePresence>
        {isHovered && (
          <motion.div
            initial={{ opacity: 0, y: -10, scale: 0.9 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: -5, scale: 0.9 }}
            style={{
              position: 'absolute',
              bottom: '100%',
              marginBottom: '8px',
              padding: '6px 10px',
              background: 'rgba(0, 0, 0, 0.85)',
              color: 'white',
              fontSize: '0.7rem',
              fontWeight: 700,
              borderRadius: '6px',
              whiteSpace: 'nowrap',
              pointerEvents: 'none',
              zIndex: 50,
              boxShadow: '0 10px 15px -3px rgba(0, 0, 0, 0.1)'
            }}
          >
            {label}
            <div style={{
              position: 'absolute',
              top: '100%',
              left: '50%',
              transform: 'translateX(-50%)',
              borderLeft: '5px solid transparent',
              borderRight: '5px solid transparent',
              borderTop: '5px solid rgba(0, 0, 0, 0.85)'
            }} />
          </motion.div>
        )}
      </AnimatePresence>
      <button 
        onMouseEnter={() => setIsHovered(true)}
        onMouseLeave={() => setIsHovered(false)}
        onClick={onClick}
        className="glass" 
        style={{ padding: '0.4rem', borderRadius: '6px', border: '1px solid var(--border)', cursor: 'pointer', color: 'var(--muted-foreground)' }}
      >
        <Pencil size={14} />
      </button>
    </>
  );
};

const DeleteTooltip = ({ label, onClick }: { label: string, onClick?: () => void }) => {
  const [isHovered, setIsHovered] = useState(false);
  return (
    <>
      <AnimatePresence>
        {isHovered && (
          <motion.div
            initial={{ opacity: 0, y: -10, scale: 0.9 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: -5, scale: 0.9 }}
            style={{
              position: 'absolute',
              bottom: '100%',
              marginBottom: '8px',
              padding: '6px 10px',
              background: '#ef4444',
              color: 'white',
              fontSize: '0.7rem',
              fontWeight: 700,
              borderRadius: '6px',
              whiteSpace: 'nowrap',
              pointerEvents: 'none',
              zIndex: 50,
              boxShadow: '0 10px 15px -3px rgba(239, 68, 68, 0.2)'
            }}
          >
            {label}
            <div style={{
              position: 'absolute',
              top: '100%',
              left: '50%',
              transform: 'translateX(-50%)',
              borderLeft: '5px solid transparent',
              borderRight: '5px solid transparent',
              borderTop: '5px solid #ef4444'
            }} />
          </motion.div>
        )}
      </AnimatePresence>
      <button 
        onMouseEnter={() => setIsHovered(true)}
        onMouseLeave={() => setIsHovered(false)}
        onClick={(e) => {
          e.preventDefault();
          e.stopPropagation();
          onClick?.();
        }}
        className="glass" 
        style={{ padding: '0.4rem', borderRadius: '6px', border: '1px solid rgba(239, 68, 68, 0.2)', cursor: 'pointer', color: '#ef4444' }}
      >
        <Trash2 size={14} />
      </button>
    </>
  );
};

const ActionButton = ({ icon: Icon, label, color }: { icon: any, label: string, color?: string }) => {
  const [isHovered, setIsHovered] = useState(false);

  return (
    <div style={{ position: 'relative', display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
      <AnimatePresence>
        {isHovered && (
          <motion.div
            initial={{ opacity: 0, y: 10, scale: 0.9 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: 5, scale: 0.9 }}
            style={{
              position: 'absolute',
              bottom: '100%',
              marginBottom: '8px',
              padding: '6px 10px',
              background: 'rgba(0, 0, 0, 0.85)',
              color: 'white',
              fontSize: '0.7rem',
              fontWeight: 700,
              borderRadius: '6px',
              whiteSpace: 'nowrap',
              pointerEvents: 'none',
              zIndex: 50,
              boxShadow: '0 10px 15px -3px rgba(0, 0, 0, 0.1)'
            }}
          >
            {label}
            <div style={{
              position: 'absolute',
              top: '100%',
              left: '50%',
              transform: 'translateX(-50%)',
              borderLeft: '5px solid transparent',
              borderRight: '5px solid transparent',
              borderTop: '5px solid rgba(0, 0, 0, 0.85)'
            }} />
          </motion.div>
        )}
      </AnimatePresence>
      <button 
        onMouseEnter={() => setIsHovered(true)}
        onMouseLeave={() => setIsHovered(false)}
        className="glass" 
        style={{ 
          padding: '0.625rem', 
          borderRadius: '10px', 
          border: '1px solid var(--border)', 
          cursor: 'pointer',
          color: color || 'var(--muted-foreground)',
          transition: 'all 0.2s ease',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          background: 'var(--card)'
        }}
      >
        <Icon size={18} />
      </button>
    </div>
  );
};

const AnimatedWaves = () => (
  <div style={{ position: 'fixed', bottom: 0, left: 0, width: '100%', height: '100px', overflow: 'hidden', zIndex: -1, opacity: 0.4, pointerEvents: 'none' }}>
    <svg viewBox="0 0 1440 120" preserveAspectRatio="none" style={{ width: '200%', height: '100%', display: 'block' }}>
      <motion.path animate={{ x: [0, -1440] }} transition={{ duration: 15, repeat: Infinity, ease: "linear" }} fill="url(#wave-gradient)" d="M0,64L48,64C96,64,192,64,288,69.3C384,75,480,85,576,85.3C672,85,768,75,864,64C960,53,1056,43,1152,42.7C1248,43,1344,53,1392,58.7L1440,64L1440,120L1392,120C1344,120,1248,120,1152,120C1056,120,960,120,864,120C768,120,672,120,576,120C480,120,384,120,288,120C192,120,96,120,48,120L0,120Z" />
      <defs>
        <linearGradient id="wave-gradient" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="rgba(37, 99, 235, 0.15)" />
          <stop offset="100%" stopColor="rgba(37, 99, 235, 0)" />
        </linearGradient>
      </defs>
      <motion.path animate={{ x: [0, -1440] }} transition={{ duration: 20, repeat: Infinity, ease: "linear" }} fill="rgba(37, 99, 235, 0.1)" d="M0,64L48,64C96,64,192,64,288,69.3C384,75,480,85,576,85.3C672,85,768,75,864,64C960,53,1056,43,1152,42.7C1248,43,1344,53,1392,58.7L1440,64L1440,120L1392,120C1344,120,1248,120,1152,120C1056,120,960,120,864,120C768,120,672,120,576,120C480,120,384,120,288,120C192,120,96,120,48,120L0,120Z" />
    </svg>
  </div>
);

export default function EstanquesPage() {
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [ponds, setPonds] = useState<any[]>([]);
  const [editingPond, setEditingPond] = useState<any | null>(null);
  const [formData, setFormData] = useState({ numero: '', largo: '', ancho: '', profundidad: '' });
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    fetchEstanques();
  }, []);

  const fetchEstanques = async () => {
    const activeUnitId = localStorage.getItem('active_unit_id');
    if (!activeUnitId) return;

    try {
      const { data: pondsData, error: pErr } = await supabase
        .from('estanques')
        .select('*')
        .eq('unit_id', activeUnitId)
        .order('name');
      
      if (pErr) throw pErr;

      const formatted = (pondsData || []).map(p => {
        let color = '#64748b';
        let statusLabel = 'Vacío';
        if (p.status === 'con_peces') {
          color = '#10b981';
          statusLabel = 'En Producción';
        } else if (p.status === 'mantenimiento') {
          color = '#f59e0b';
          statusLabel = 'Mantenimiento';
        }

        return {
          ...p,
          color,
          statusLabel,
          volume: p.capacity_m3 || 0,
          especie: p.is_polyculture ? 'Policultivo' : (p.current_species || 'N/A'),
          current_count: p.current_count || 0,
          current_biomass_kg: p.current_biomass_kg || 0
        };
      });
      setPonds(formatted);
    } catch (error: any) {
      toast.error(`Error al cargar estanques: ${error.message}`);
    }
  };

  const volumen = useMemo(() => {
    const l = parseFloat(formData.largo) || 0;
    const a = parseFloat(formData.ancho) || 0;
    const p = parseFloat(formData.profundidad) || 0;
    return (l * a * p).toFixed(2);
  }, [formData.largo, formData.ancho, formData.profundidad]);

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
  };

  const resetForm = () => {
    setFormData({ numero: '', largo: '', ancho: '', profundidad: '' });
    setEditingPond(null);
    setIsModalOpen(false);
  };

  const handleEditClick = (pond: any) => {
    const num = pond.name.split('-')[1] || '';
    setFormData({ 
      numero: num, 
      largo: '', 
      ancho: '', 
      profundidad: (pond.capacity_m3 || 0).toString() 
    });
    setEditingPond(pond);
    setIsModalOpen(true);
  };

  const handleCreateEstanque = async () => {
    if (!formData.numero) {
      toast.error("Por favor asigne un número al estanque.");
      return;
    }

    setLoading(true);
    const createPromise = async () => {
      const name = `Est-${formData.numero.padStart(2, '0')}`;
      const vol = parseFloat(volumen);
      let activeUnitId = localStorage.getItem('active_unit_id');

      if (!activeUnitId) throw new Error("No se detectó unidad activa.");

      if (editingPond) {
        const { error } = await supabase
          .from('estanques')
          .update({ name, capacity_m3: vol })
          .eq('id', editingPond.id);
        if (error) throw error;
      } else {
        const { error } = await supabase.from('estanques').insert([{
          name,
          capacity_m3: vol,
          status: 'vacio',
          unit_id: activeUnitId
        }]);
        if (error) throw error;
      }
    };

    toast.promise(createPromise(), {
      loading: editingPond ? 'Actualizando estanque...' : 'Creando estanque...',
      success: () => {
        resetForm();
        fetchEstanques();
        return editingPond ? 'Estanque actualizado' : 'Estanque creado';
      },
      error: (err) => `Error: ${err.message}`
    }).finally(() => setLoading(false));
  };

  const handleDeleteSiembra = async (pond: any) => {
    const deletePromise = async () => {
      const { data: siembras, error: sErr } = await supabase
        .from('siembras')
        .select('*, siembra_details(*)')
        .eq('estanque_id', pond.id)
        .order('created_at', { ascending: false })
        .limit(1);

      if (sErr) throw sErr;

      if (!siembras || siembras.length === 0) {
        await supabase.from('estanques').update({
          status: 'vacio', is_polyculture: false, current_species: null, current_count: 0, current_biomass_kg: 0
        }).eq('id', pond.id);
        await supabase.from('pond_species').delete().eq('estanque_id', pond.id);
        return;
      }

      const lastSiembra = siembras[0];
      const inventoryOps = (lastSiembra.siembra_details || []).map(async (detail: any) => {
        const { data: inv } = await supabase.from('inventory').select('*').eq('id', detail.inventory_item_id).single();
        if (inv) {
          await supabase.from('inventory').update({ current_stock: (parseFloat(inv.current_stock) || 0) + detail.quantity }).eq('id', inv.id);
        }
      });

      await Promise.all([
        ...inventoryOps,
        supabase.from('estanques').update({ status: 'vacio', is_polyculture: false, current_species: null, current_count: 0, current_biomass_kg: 0 }).eq('id', pond.id),
        supabase.from('pond_species').delete().eq('estanque_id', pond.id),
        supabase.from('siembras').delete().eq('id', lastSiembra.id)
      ]);
    };

    toast.promise(deletePromise(), {
      loading: 'Eliminando siembra...',
      success: () => { fetchEstanques(); return 'Siembra eliminada con éxito'; },
      error: (err) => `Error: ${err.message}`
    });
  };

  return (
    <div className="animate-fade-in page-container">
      <header style={{ marginBottom: '2.5rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem' }}>
        <div>
          <h1 style={{ fontWeight: 800 }}>Gestión de Estanques</h1>
          <p style={{ color: 'var(--muted-foreground)', fontSize: '0.9rem' }}>Supervisión y administración de infraestructura.</p>
        </div>
        <button className="btn-primary" onClick={() => setIsModalOpen(true)} style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', fontWeight: 700 }}>
          <Plus size={20} />
          Crear Estanque
        </button>
      </header>

      <div className="responsive-grid-3">
        {ponds.map((pond) => (
          <motion.div key={pond.id} whileHover={{ y: -4 }} className="card-premium" style={{ padding: '1.5rem', display: 'flex', flexDirection: 'column', gap: '1rem', position: 'relative' }}>
            <div style={{ position: 'absolute', top: 0, left: 0, width: '100%', height: '4px', background: pond.color }} />

            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <h3 style={{ fontSize: '1.25rem', fontWeight: 800 }}>{pond.name}</h3>
              <div style={{ display: 'flex', gap: '0.5rem' }}>
                {pond.status === 'con_peces' && <DeleteTooltip label="Borrar Siembra" onClick={() => handleDeleteSiembra(pond)} />}
                <EditTooltip label="Editar" onClick={() => handleEditClick(pond)} />
              </div>
            </div>

            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', fontSize: '0.7rem', fontWeight: 900, color: pond.color, background: `${pond.color}10`, padding: '4px 10px', borderRadius: '20px', alignSelf: 'flex-start' }}>
              <span style={{ width: '6px', height: '6px', borderRadius: '50%', background: pond.color }}></span>
              {pond.statusLabel.toUpperCase()}
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem', margin: '0.5rem 0' }}>
              <div>
                <div style={{ fontSize: '0.65rem', fontWeight: 800, color: 'var(--muted-foreground)' }}>VOLUMEN</div>
                <div style={{ fontWeight: 800, fontSize: '1.1rem' }}>{pond.volume} <span style={{ fontSize: '0.7rem' }}>m³</span></div>
              </div>
              <div>
                <div style={{ fontSize: '0.65rem', fontWeight: 800, color: 'var(--muted-foreground)' }}>BIOMASA</div>
                <div style={{ fontWeight: 800, fontSize: '1.1rem' }}>{pond.current_biomass_kg} <span style={{ fontSize: '0.7rem' }}>kg</span></div>
              </div>
            </div>

            <div style={{ background: 'var(--secondary)', borderRadius: '12px', padding: '1rem' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '0.5rem' }}>
                <span style={{ fontSize: '0.65rem', fontWeight: 800, color: 'var(--muted-foreground)' }}>ESPECIE / CANTIDAD</span>
                {pond.is_polyculture && <span style={{ fontSize: '0.6rem', background: 'var(--primary)', color: 'white', padding: '2px 6px', borderRadius: '4px' }}>POLI</span>}
              </div>
              <div style={{ fontWeight: 700, fontSize: '0.9rem' }}>{pond.especie}</div>
              <div style={{ fontSize: '1.25rem', fontWeight: 900, color: 'var(--primary)', marginTop: '0.25rem' }}>{pond.current_count.toLocaleString()} <span style={{ fontSize: '0.8rem', color: 'var(--muted-foreground)' }}>uds</span></div>
            </div>

            <div style={{ display: 'flex', gap: '0.5rem', borderTop: '1px solid var(--border)', paddingTop: '1rem', marginTop: 'auto' }}>
              <Link href={`/siembra?estanque=${pond.id}`}><ActionButton icon={Fish} label="Siembra" color="#10b981" /></Link>
              <Link href={`/tratamiento?estanque=${pond.id}`}><ActionButton icon={FlaskConical} label="Tratamiento" color="#f59e0b" /></Link>
              <Link href={`/mantenimiento?estanque=${pond.id}`}><ActionButton icon={Settings} label="Mantenimiento" color="#3b82f6" /></Link>
              <Link href={`/aireacion?estanque=${pond.id}`}><ActionButton icon={Wind} label="Aireación" color="#06b6d4" /></Link>
            </div>
          </motion.div>
        ))}
      </div>

      <AnimatePresence>
        {isModalOpen && (
          <div style={{ position: 'fixed', inset: 0, zIndex: 1000, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '1rem' }}>
            <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} onClick={resetForm} style={{ position: 'absolute', inset: 0, background: 'rgba(15, 23, 42, 0.4)', backdropFilter: 'blur(8px)' }} />
            <motion.div initial={{ scale: 0.9, opacity: 0, y: 20 }} animate={{ scale: 1, opacity: 1, y: 0 }} exit={{ scale: 0.9, opacity: 0, y: 20 }} className="card-premium" style={{ width: '100%', maxWidth: '450px', padding: '2rem', position: 'relative' }}>
              <button onClick={resetForm} style={{ position: 'absolute', top: '1rem', right: '1rem', background: 'none', border: 'none', color: 'var(--muted-foreground)', cursor: 'pointer' }}><X size={20} /></button>
              <h2 style={{ fontWeight: 800, marginBottom: '1.5rem' }}>{editingPond ? 'Editar Estanque' : 'Nuevo Estanque'}</h2>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
                <div className="premium-input-group">
                  <label className="premium-label"><Hash size={14} /> Número de Estanque</label>
                  <div className="premium-input-wrapper">
                    <span style={{ fontWeight: 800, color: 'var(--muted-foreground)', marginRight: '0.5rem' }}>Est-</span>
                    <input 
                      type="number" 
                      name="numero" 
                      value={formData.numero} 
                      onChange={handleInputChange} 
                      placeholder="01" 
                      className="premium-input"
                      style={{ paddingLeft: 0 }}
                    />
                  </div>
                </div>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '0.75rem' }}>
                  <div className="premium-input-group">
                    <label className="premium-label">Largo (m)</label>
                    <input type="number" name="largo" value={formData.largo} onChange={handleInputChange} placeholder="0.0" className="premium-input" />
                  </div>
                  <div className="premium-input-group">
                    <label className="premium-label">Ancho (m)</label>
                    <input type="number" name="ancho" value={formData.ancho} onChange={handleInputChange} placeholder="0.0" className="premium-input" />
                  </div>
                  <div className="premium-input-group">
                    <label className="premium-label">Prof. (m)</label>
                    <input type="number" name="profundidad" value={formData.profundidad} onChange={handleInputChange} placeholder="0.0" className="premium-input" />
                  </div>
                </div>
                <div style={{ padding: '1.25rem', background: 'rgba(37, 99, 235, 0.05)', borderRadius: '12px', border: '1px solid rgba(37, 99, 235, 0.1)', display: 'flex', justifyContent: 'space-between', alignItems: 'center', height: '80px' }}>
                  <div>
                    <div style={{ fontSize: '0.65rem', fontWeight: 800, color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Capacidad Estimada</div>
                    <div style={{ fontSize: '1.5rem', fontWeight: 900, color: 'var(--primary)' }}>{volumen} <span style={{ fontSize: '0.8rem' }}>m³</span></div>
                  </div>
                  <Box size={32} style={{ color: 'var(--primary)', opacity: 0.2 }} />
                </div>
                <button className="btn-primary" disabled={loading} onClick={handleCreateEstanque} style={{ padding: '1rem', fontWeight: 800, height: '56px' }}>
                  {loading ? 'Procesando...' : editingPond ? 'Guardar Cambios' : 'Crear Estanque'}
                </button>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
      <AnimatedWaves />
    </div>
  );
}
