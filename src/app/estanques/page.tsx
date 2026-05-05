'use client';

import { useEffect, useState, useMemo } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import Link from 'next/link';
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
  MoreVertical,
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
    </svg>
  </div>
);

export default function EstanquesPage() {
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [ponds, setPonds] = useState<any[]>([]);
  const [editingPond, setEditingPond] = useState<any | null>(null);
  const [formData, setFormData] = useState({ numero: '', largo: '', ancho: '', profundidad: '' });

  useEffect(() => {
    fetchEstanques();
  }, []);

  const fetchEstanques = async () => {
    const activeUnitId = localStorage.getItem('active_unit_id');
    if (!activeUnitId) return;

    // 1. Fetch Ponds
    const { data: pondsData, error: pErr } = await supabase
      .from('estanques')
      .select('*')
      .eq('unit_id', activeUnitId)
      .order('name');
    
    if (pErr) {
      console.error('Error fetching ponds:', pErr);
      return;
    }

    // 2. Fetch Species Inventory for all ponds
    const { data: speciesData, error: sErr } = await supabase
      .from('pond_species')
      .select('*');
    
    if (sErr) {
      console.error('Error fetching pond species details:', sErr.message || sErr);
    }

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

      const speciesList = (speciesData || []).filter(s => s.estanque_id === p.id);

      return {
        ...p,
        color,
        statusLabel,
        volume: p.capacity_m3 || 0,
        dims: 'Personalizada',
        especie: p.is_polyculture ? 'Policultivo' : (p.current_species || 'N/A'),
        speciesDetails: speciesList,
        fechaSiembra: p.status === 'con_peces' ? 'Activo' : 'N/A',
        cantidad: `${p.current_count || 0} uds`
      };
    });
    setPonds(formatted);
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
    // If we have capacity and dimensions, we could backfill largo/ancho/profundidad
    // For now let's just allow editing the number/name and assume 1x1x(vol) or keep empty
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
      alert("Por favor asigne un número al estanque.");
      return;
    }

    const name = `Est-${formData.numero.padStart(2, '0')}`;
    const vol = parseFloat(volumen);
    let activeUnitId = localStorage.getItem('active_unit_id');

    // Si no está en localStorage, lo buscamos en la DB (Resiliencia total)
    if (!activeUnitId) {
      const { data: { user } } = await supabase.auth.getUser();
      if (user) {
        const { data: uu } = await supabase.from('user_units').select('unit_id').eq('user_id', user.id).single();
        if (uu) {
          activeUnitId = uu.unit_id;
          localStorage.setItem('active_unit_id', uu.unit_id);
        }
      }
    }

    if (!activeUnitId) {
      alert("Error: No se ha detectado una unidad productiva vinculada a su cuenta.");
      return;
    }

    if (editingPond) {
      const { error } = await supabase
        .from('estanques')
        .update({ name, capacity_m3: vol, unit_id: activeUnitId })
        .eq('id', editingPond.id);

      if (error) {
        if (error.code === '23505') {
          alert("Conflicto de Nomenclatura: No es posible renombrar el estanque con esta identificación porque ya se encuentra en uso dentro de esta unidad.");
        } else {
          alert("Error Operativo: " + error.message);
        }
      } else {
        alert("¡Estanque actualizado con éxito!");
        resetForm();
        fetchEstanques();
      }
    } else {
      const { error } = await supabase.from('estanques').insert([{
        name,
        capacity_m3: vol,
        status: 'vacio',
        unit_id: activeUnitId
      }]);

      if (error) {
        if (error.code === '23505') {
          alert("Conflicto de Infraestructura: Ya existe un estanque con esta identificación en la unidad activa. Por favor, verifique el número de estanque.");
        } else {
          alert("Error de Sincronización: " + error.message);
        }
      } else {
        alert("¡Estanque creado con éxito!");
        resetForm();
        fetchEstanques();
      }
    }
  };

  const handleDeleteSiembra = async (pond: any) => {
    if (!confirm(`¿Estás seguro de eliminar la siembra del estanque ${pond.name}? Esto devolverá los peces al inventario del almacén.`)) return;

    const { data: siembras, error: sErr } = await supabase
      .from('siembras')
      .select('*, siembra_details(*)')
      .eq('estanque_id', pond.id)
      .order('created_at', { ascending: false })
      .limit(1);

    if (sErr || !siembras || siembras.length === 0) {
      if (confirm("No se encontró un registro de siembra detallado para este estanque. ¿Deseas restablecer el estado del estanque a 'Vacío' de todas formas? (Esto no devolverá peces al almacén)")) {
        await supabase
          .from('estanques')
          .update({
            status: 'vacio',
            is_polyculture: false,
            current_species: null,
            current_count: 0,
            current_biomass_kg: 0
          })
          .eq('id', pond.id);
        
        await supabase.from('pond_species').delete().eq('estanque_id', pond.id);
        alert("Estado del estanque restablecido.");
        fetchEstanques();
      }
      return;
    }

    const lastSiembra = siembras[0];

    for (const detail of lastSiembra.siembra_details || []) {
      const { data: inv } = await supabase
        .from('inventory')
        .select('*')
        .eq('name', detail.species_name)
        .eq('category', 'alevinos')
        .single();
      
      if (inv) {
        await supabase
          .from('inventory')
          .update({ current_stock: (parseFloat(inv.current_stock) || 0) + detail.quantity })
          .eq('id', inv.id);
      }
    }

    await supabase
      .from('estanques')
      .update({
        status: 'vacio',
        is_polyculture: false,
        current_species: null,
        current_count: 0,
        current_biomass_kg: 0
      })
      .eq('id', pond.id);

    await supabase.from('pond_species').delete().eq('estanque_id', pond.id);
    await supabase.from('siembras').delete().eq('id', lastSiembra.id);

    alert("¡Siembra eliminada y peces devueltos al almacén con éxito!");
    fetchEstanques();
  };

  return (
    <div className="animate-fade-in" style={{ position: 'relative', minHeight: 'calc(100vh - 4rem)', paddingBottom: '100px' }}>
      <header style={{ marginBottom: '2.5rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <h1 style={{ fontSize: '1.875rem', fontWeight: 700, marginBottom: '0.5rem' }}>Gestión de Estanques</h1>
          <p style={{ color: 'var(--muted-foreground)' }}>Supervisa y administra tus unidades de producción en tiempo real.</p>
        </div>
        <button className="btn-primary" onClick={() => setIsModalOpen(true)} style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
          <Plus size={20} />
          Crear Estanque
        </button>
      </header>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))', gap: '2rem' }}>
        {ponds.map((pond) => (
          <motion.div
            key={pond.id}
            whileHover={{ y: -8, scale: 1.02 }}
            transition={{ type: 'spring', stiffness: 300, damping: 20 }}
            className="card-premium"
            style={{ padding: '1.5rem', display: 'flex', flexDirection: 'column', gap: '1.5rem', position: 'relative', overflow: 'hidden' }}
          >
            <div style={{ position: 'absolute', top: 0, left: 0, width: '4px', height: '100%', background: pond.color }} />

            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
              <div style={{ width: '48px', height: '48px', borderRadius: '12px', background: 'var(--secondary)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--primary)' }}>
                <PondIcon size={32} />
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                <div style={{ position: 'relative', display: 'flex', justifyContent: 'center', gap: '0.4rem' }}>
                  {pond.status === 'con_peces' && (
                    <DeleteTooltip 
                      label="Eliminar siembra" 
                      onClick={() => handleDeleteSiembra(pond)} 
                    />
                  )}
                  <EditTooltip 
                    label="Editar estanque" 
                    onClick={() => handleEditClick(pond)} 
                  />
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', fontSize: '0.75rem', fontWeight: 700, color: pond.color, background: `${pond.color}10`, padding: '4px 8px', borderRadius: '6px' }}>
                  <span style={{ width: '8px', height: '8px', borderRadius: '50%', background: pond.color }}></span>
                  {pond.statusLabel}
                </div>
              </div>
            </div>

            <div>
              <h3 style={{ fontSize: '1.5rem', fontWeight: 700, marginBottom: '0.75rem', display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                {pond.name}
                {pond.is_polyculture && <span style={{ fontSize: '0.65rem', background: 'var(--primary)', color: 'white', padding: '2px 8px', borderRadius: '4px', textTransform: 'uppercase' }}>Policultivo</span>}
              </h3>
              
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.75rem', marginBottom: '1rem' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', color: 'var(--muted-foreground)', fontSize: '0.8rem' }}>
                  <Box size={14} />
                  <span>Volumen: <strong>{pond.volume} m³</strong></span>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', color: 'var(--muted-foreground)', fontSize: '0.8rem' }}>
                  <Waves size={14} />
                  <span>Biomasa: <strong>{(pond.current_biomass_kg || 0).toLocaleString()} kg</strong></span>
                </div>
              </div>

              {/* Species Breakdown Section */}
              <div style={{ background: 'var(--secondary)', borderRadius: '12px', padding: '1rem', marginBottom: '1rem' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', fontSize: '0.7rem', fontWeight: 800, color: 'var(--muted-foreground)', textTransform: 'uppercase', marginBottom: '0.75rem' }}>
                  <Dna size={12} /> Composición Biológica
                </div>
                
                {pond.is_polyculture ? (
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                    {pond.speciesDetails?.map((s: any) => (
                      <div key={s.id} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '0.5rem 0.75rem', background: 'white', borderRadius: '8px', border: '1px solid var(--border)' }}>
                        <span style={{ fontWeight: 700, fontSize: '0.85rem' }}>{s.species_name}</span>
                        <span style={{ fontSize: '0.85rem', fontWeight: 800, color: 'var(--primary)' }}>{s.current_count.toLocaleString()} <span style={{ fontSize: '0.7rem', color: 'var(--muted-foreground)', fontWeight: 600 }}>uds</span></span>
                      </div>
                    ))}
                  </div>
                ) : (
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '0.5rem 0.75rem', background: 'white', borderRadius: '8px', border: '1px solid var(--border)' }}>
                    <span style={{ fontWeight: 700, fontSize: '0.85rem' }}>{pond.especie}</span>
                    <span style={{ fontSize: '0.85rem', fontWeight: 800, color: 'var(--primary)' }}>{pond.current_count.toLocaleString()} <span style={{ fontSize: '0.7rem', color: 'var(--muted-foreground)', fontWeight: 600 }}>uds</span></span>
                  </div>
                )}
              </div>

              <div style={{ display: 'flex', justifyContent: 'center', gap: '1rem', fontSize: '0.75rem', color: 'var(--muted-foreground)' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
                  <Calendar size={12} /> Siembra: <strong>{pond.fechaSiembra}</strong>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
                  <Calculator size={12} /> <strong>{pond.dims}</strong>
                </div>
              </div>
            </div>

            <div style={{ display: 'flex', gap: '0.75rem', borderTop: '1px solid var(--border)', paddingTop: '1.25rem' }}>
              <Link href={`/siembra?estanque=${pond.id}`}>
                <ActionButton icon={Fish} label="Siembra" color="#10b981" />
              </Link>
              <Link href={`/tratamiento?estanque=${pond.id}`}>
                <ActionButton icon={FlaskConical} label="Tratamiento" color="#f59e0b" />
              </Link>
              <Link href={`/mantenimiento?estanque=${pond.id}`}>
                <ActionButton icon={Settings} label="Mantenimiento" color="#3b82f6" />
              </Link>
              <Link href={`/aireacion?estanque=${pond.id}`}>
                <ActionButton icon={Wind} label="Adicionar aireación" color="#06b6d4" />
              </Link>
            </div>
          </motion.div>
        ))}
      </div>

      <AnimatedWaves />

      {/* Modal Form */}
      <AnimatePresence>
        {isModalOpen && (
          <>
            <motion.div 
              initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
              onClick={resetForm}
              style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, background: 'rgba(0, 0, 0, 0.4)', backdropFilter: 'blur(4px)', zIndex: 100 }} 
            />
            <motion.div 
              initial={{ opacity: 0, scale: 0.9, y: 40 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.9, y: 40 }}
              style={{ position: 'fixed', top: '10%', left: '50%', x: '-50%', width: '100%', maxWidth: '550px', zIndex: 101, maxHeight: '85vh', overflowY: 'auto' }}
            >
              <div className="card-premium" style={{ padding: '2rem', background: 'var(--card)' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem' }}>
                  <h2 style={{ fontSize: '1.5rem', fontWeight: 700 }}>
                    {editingPond ? `Editar Estanque ${editingPond.name}` : 'Crear Nuevo Estanque'}
                  </h2>
                  <button onClick={resetForm} style={{ background: 'transparent', border: 'none', cursor: 'pointer', color: 'var(--muted-foreground)' }}>
                    <X size={24} />
                  </button>
                </div>

                <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
                  {/* Identificación */}
                  <div>
                    <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, marginBottom: '0.5rem', textTransform: 'uppercase', color: 'var(--muted-foreground)' }}>Número de Estanque</label>
                    <div style={{ display: 'flex', alignItems: 'center', background: 'var(--secondary)', borderRadius: '8px', border: '1px solid var(--border)', padding: '0 0.75rem' }}>
                      <span style={{ color: 'var(--muted-foreground)', fontWeight: 600 }}>Est-</span>
                      <input 
                        type="number" 
                        name="numero"
                        value={formData.numero}
                        onChange={handleInputChange}
                        placeholder="01" 
                        style={{ border: 'none', background: 'transparent', outline: 'none', padding: '0.75rem 0.25rem', width: '100%', color: 'inherit', fontWeight: 600 }} 
                      />
                    </div>
                  </div>

                  {/* Medidas */}
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '1rem' }}>
                    <div>
                      <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, marginBottom: '0.5rem', textTransform: 'uppercase', color: 'var(--muted-foreground)' }}>Largo (m)</label>
                      <input type="number" name="largo" value={formData.largo} onChange={handleInputChange} placeholder="0.0" style={{ width: '100%', padding: '0.75rem', borderRadius: '8px', border: '1px solid var(--border)', background: 'var(--secondary)', outline: 'none' }} />
                    </div>
                    <div>
                      <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, marginBottom: '0.5rem', textTransform: 'uppercase', color: 'var(--muted-foreground)' }}>Ancho (m)</label>
                      <input type="number" name="ancho" value={formData.ancho} onChange={handleInputChange} placeholder="0.0" style={{ width: '100%', padding: '0.75rem', borderRadius: '8px', border: '1px solid var(--border)', background: 'var(--secondary)', outline: 'none' }} />
                    </div>
                    <div>
                      <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 700, marginBottom: '0.5rem', textTransform: 'uppercase', color: 'var(--muted-foreground)' }}>Prof (m)</label>
                      <input type="number" name="profundidad" value={formData.profundidad} onChange={handleInputChange} placeholder="0.0" style={{ width: '100%', padding: '0.75rem', borderRadius: '8px', border: '1px solid var(--border)', background: 'var(--secondary)', outline: 'none' }} />
                    </div>
                  </div>

                  <div style={{ padding: '1.25rem', background: 'rgba(37, 99, 235, 0.05)', borderRadius: '12px', border: '1px solid rgba(37, 99, 235, 0.1)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                      <Box size={28} style={{ color: 'var(--primary)' }} />
                      <div>
                        <div style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Capacidad del Estanque</div>
                        <div style={{ fontSize: '1.5rem', fontWeight: 800, color: 'var(--primary)' }}>{volumen} m³</div>
                      </div>
                    </div>
                  </div>

                  <button className="btn-primary" style={{ width: '100%', padding: '1rem', fontSize: '1rem', fontWeight: 700, marginTop: '0.5rem' }} onClick={handleCreateEstanque}>
                    {editingPond ? 'Guardar Cambios' : 'Crear Infraestructura'}
                  </button>
                </div>
              </div>
            </motion.div>
          </>
        )}
      </AnimatePresence>
    </div>
  );
}
