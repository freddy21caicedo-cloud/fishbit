'use client';

import { useEffect, useState, useMemo } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  Plus, 
  Trash2, 
  Calendar, 
  Clock, 
  Waves, 
  Wind, 
  AlertCircle,
  ArrowLeft,
  Power,
  Zap,
  Activity
} from 'lucide-react';
import Link from 'next/link';
import { useSearchParams, useRouter } from 'next/navigation';
import { toast } from 'react-hot-toast';
import { supabase } from '@/lib/supabase';

export default function AireacionPage() {
  const searchParams = useSearchParams();
  const router = useRouter();
  const estanqueParam = searchParams.get('estanque');

  const [fecha, setFecha] = useState(new Date().toISOString().split('T')[0]);
  const [hora, setHora] = useState(new Date().toTimeString().slice(0, 5));
  const [estanqueId, setEstanqueId] = useState(estanqueParam || '');
  
  const [ponds, setPonds] = useState<any[]>([]);
  const [inventory, setInventory] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);

  const [activeAireadores, setActiveAireadores] = useState<any[]>([]);
  const [isModalOpen, setIsModalOpen] = useState(false);

  const fetchData = async () => {
    try {
      const activeUnitId = localStorage.getItem('active_unit_id');
      const { data: pondData } = await supabase.from('estanques').select('*').eq('unit_id', activeUnitId);
      setPonds(pondData || []);

      const { data: invData } = await supabase.from('inventory').select('*').eq('category', 'aireadores').eq('unit_id', activeUnitId);
      setInventory(invData || []);

      // Load persistent configuration from Supabase
      if (estanqueId) {
        const { data: configData } = await supabase
          .from('aireacion_config')
          .select('aireadores')
          .eq('estanque_id', estanqueId)
          .single();

        setActiveAireadores(configData?.aireadores || []);
      }
    } catch (error: any) {
      toast.error("Error al cargar datos: " + error.message);
    }
  };

  useEffect(() => {
    fetchData();
  }, [estanqueId]);

  const selectedPond = useMemo(() => ponds.find(p => p.id === estanqueId), [estanqueId, ponds]);

  const projectedCost = useMemo(() => {
    const kwhPrice = 650; // Precio ref
    const totalKwh = activeAireadores.reduce((sum, a) => {
      if (a.status === 'OFF') return sum;
      return sum + (Number(a.consumption) || 0) * (Number(a.hours) || 24);
    }, 0);
    return totalKwh * kwhPrice;
  }, [activeAireadores]);

  const handleToggle = (id: string) => {
    setActiveAireadores(activeAireadores.map(a => a.id === id ? { ...a, status: a.status === 'ON' ? 'OFF' : 'ON' } : a));
  };

  const handleRemoveEquipment = (id: string) => {
    setActiveAireadores(prev => prev.filter(a => a.id !== id));
    toast.success("Equipo desvinculado de la sesión.");
  };

  const handleAddFromInventory = (item: any) => {
    const hpMatch = item.name.match(/(\d+\.?\d*)\s*HP/i);
    const hp = hpMatch ? Number(hpMatch[1]) : 1;
    const consumption = (hp * 0.745).toFixed(2); // HP to kW approx

    setActiveAireadores([...activeAireadores, {
      id: Math.random().toString(),
      inventory_id: item.id,
      nombre: item.name,
      status: 'OFF',
      hours: '0',
      consumption: consumption
    }]);
    setIsModalOpen(false);
    toast.success(`${item.name} asignado.`);
  };

  const handleRegisterAeration = async () => {
    if (!estanqueId) {
      toast.error("Por favor seleccione un estanque.");
      return;
    }

    setLoading(true);
    const registerPromise = async () => {
      const activeUnitId = localStorage.getItem('active_unit_id');
      
      // Persist configuration to Supabase
      await supabase
        .from('aireacion_config')
        .upsert(
          { estanque_id: estanqueId, unit_id: activeUnitId, aireadores: activeAireadores, updated_at: new Date().toISOString() },
          { onConflict: 'estanque_id' }
        );

      const operations = activeAireadores.map(async (air) => {
        const { error } = await supabase.from('aireacion_logs').insert([{
          estanque_id: estanqueId,
          unit_id: activeUnitId,
          action: air.status,
          observations: `Equipo: ${air.nombre}. Consumo: ${air.consumption}kW. Horas: ${air.hours}h`,
          date: fecha,
          hour: hora
        }]);
        if (error) throw error;
      });

      await Promise.all(operations);
    };

    toast.promise(registerPromise(), {
      loading: 'Guardando configuración...',
      success: () => {
        router.push('/registros');
        return "¡Configuración de aireación guardada!";
      },
      error: (err) => `Error: ${err.message}`
    }).finally(() => setLoading(false));
  };

  return (
    <div className="animate-fade-in page-container">
      <header style={{ marginBottom: '2.5rem', display: 'flex', alignItems: 'center', gap: '1.5rem' }}>
        <Link href="/registros" className="btn-secondary" style={{ width: '48px', height: '48px', borderRadius: '16px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <ArrowLeft size={24} />
        </Link>
        <div>
          <h1 style={{ fontSize: '2.2rem', fontWeight: 900, letterSpacing: '-0.02em' }}>Control de Aireación</h1>
          <p style={{ color: 'var(--muted-foreground)', fontSize: '1rem' }}>Gestión de equipos y suministro de oxígeno disuelto.</p>
        </div>
      </header>

      <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
        <div className="card-premium" style={{ padding: '2rem', display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '1.5rem', alignItems: 'center' }}>
          <div className="premium-input-group">
            <label className="premium-label">Estanque Destino</label>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', padding: '0.75rem', background: 'rgba(6, 182, 212, 0.05)', borderRadius: '12px', border: '1px solid rgba(6, 182, 212, 0.1)', height: '56px' }}>
              <Waves size={20} style={{ color: '#06b6d4' }} />
              <span style={{ fontSize: '1.1rem', fontWeight: 800, color: '#06b6d4' }}>
                {selectedPond ? selectedPond.name : '---'}
              </span>
            </div>
          </div>
          <div className="premium-input-group">
            <label className="premium-label">Fecha de Registro</label>
            <input type="date" value={fecha} onChange={(e) => setFecha(e.target.value)} className="premium-input" />
          </div>
          <div className="premium-input-group">
            <label className="premium-label">Hora de Inicio</label>
            <input type="time" value={hora} onChange={(e) => setHora(e.target.value)} className="premium-input" />
          </div>
        </div>

        <div className="responsive-grid-2">
          <AnimatePresence>
            {activeAireadores.map((a) => (
              <motion.div 
                key={a.id} 
                initial={{ opacity: 0, scale: 0.95 }}
                animate={{ opacity: 1, scale: 1 }}
                exit={{ opacity: 0, scale: 0.9, x: -20 }}
                className="card-premium" 
                style={{ padding: '1.5rem', position: 'relative', border: a.status === 'ON' ? '1px solid rgba(16, 185, 129, 0.3)' : '1px solid var(--border)' }}
              >
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '1.5rem' }}>
                  <div style={{ 
                    width: '56px', 
                    height: '56px', 
                    borderRadius: '16px', 
                    background: a.status === 'ON' ? 'rgba(16, 185, 129, 0.1)' : 'var(--secondary)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    color: a.status === 'ON' ? '#10b981' : 'var(--muted-foreground)',
                    boxShadow: a.status === 'ON' ? '0 0 20px rgba(16, 185, 129, 0.2)' : 'none'
                  }}>
                    <Wind size={28} className={a.status === 'ON' ? 'animate-spin-slow' : ''} />
                  </div>
                  <div style={{ display: 'flex', gap: '0.75rem', alignItems: 'center' }}>
                    <button 
                      onClick={() => handleRemoveEquipment(a.id)} 
                      style={{ background: 'rgba(239, 68, 68, 0.1)', border: 'none', color: '#ef4444', width: '36px', height: '36px', borderRadius: '10px', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }}
                    >
                      <Trash2 size={18} />
                    </button>
                    <div style={{ padding: '0.4rem 1rem', borderRadius: '50px', fontSize: '0.75rem', fontWeight: 900, background: a.status === 'ON' ? '#10b981' : '#64748b', color: 'white', letterSpacing: '0.05em' }}>
                      {a.status}
                    </div>
                  </div>
                </div>

                <h3 style={{ fontSize: '1.2rem', fontWeight: 900, marginBottom: '0.75rem' }}>{a.nombre}</h3>
                
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem', marginBottom: '1.5rem' }}>
                  <div className="premium-input-group" style={{ background: 'var(--secondary)', borderRadius: '12px', padding: '0.75rem' }}>
                    <label className="premium-label" style={{ position: 'static', marginBottom: '0.25rem', fontSize: '0.65rem' }}>Consumo</label>
                    <div style={{ fontWeight: 900, fontSize: '1.1rem' }}>{a.consumption} <span style={{ fontSize: '0.8rem', color: 'var(--muted-foreground)' }}>kW/h</span></div>
                  </div>
                  <div className="premium-input-group" style={{ background: 'var(--secondary)', borderRadius: '12px', padding: '0.75rem' }}>
                    <label className="premium-label" style={{ position: 'static', marginBottom: '0.25rem', fontSize: '0.65rem' }}>Tiempo Uso</label>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.25rem' }}>
                      <input 
                        type="number" 
                        value={a.hours} 
                        onChange={(e) => setActiveAireadores(activeAireadores.map(item => item.id === a.id ? {...item, hours: e.target.value} : item))} 
                        style={{ background: 'transparent', border: 'none', fontWeight: 900, width: '50px', outline: 'none', fontSize: '1.1rem' }} 
                      />
                      <span style={{ fontWeight: 900, fontSize: '0.9rem' }}>h</span>
                    </div>
                  </div>
                </div>

                <button 
                  onClick={() => handleToggle(a.id)} 
                  className="btn-secondary" 
                  style={{ 
                    width: '100%', 
                    padding: '0.85rem', 
                    borderRadius: '14px', 
                    border: '1px solid var(--border)',
                    color: a.status === 'ON' ? '#ef4444' : '#10b981', 
                    fontWeight: 900, 
                    display: 'flex', 
                    alignItems: 'center', 
                    justifyContent: 'center', 
                    gap: '0.75rem',
                    background: 'var(--card)'
                  }}
                >
                  <Power size={20} />
                  {a.status === 'ON' ? 'Detener Equipo' : 'Arrancar Equipo'}
                </button>
              </motion.div>
            ))}
          </AnimatePresence>

          <button 
            onClick={() => setIsModalOpen(true)}
            className="card-premium" 
            style={{ 
              border: '2px dashed var(--border)', 
              borderRadius: '28px', 
              background: 'rgba(6, 182, 212, 0.02)', 
              display: 'flex', 
              flexDirection: 'column', 
              alignItems: 'center', 
              justifyContent: 'center', 
              gap: '1.25rem', 
              color: 'var(--muted-foreground)', 
              cursor: 'pointer', 
              padding: '3rem',
              transition: 'all 0.3s ease'
            }}
          >
            <div style={{ width: '64px', height: '64px', borderRadius: '50%', background: 'var(--card)', display: 'flex', alignItems: 'center', justifyContent: 'center', border: '1px solid var(--border)' }}>
              <Plus size={32} />
            </div>
            <span style={{ fontWeight: 900, fontSize: '1.1rem' }}>Asignar Aireador</span>
          </button>
        </div>

        <div className="responsive-grid-2" style={{ marginTop: '1rem', alignItems: 'center' }}>
          <div className="card-premium" style={{ padding: '1.5rem', display: 'flex', alignItems: 'center', gap: '1.5rem', borderLeft: '6px solid #06b6d4', background: 'linear-gradient(to right, rgba(6, 182, 212, 0.05), transparent)' }}>
            <div style={{ width: '56px', height: '56px', borderRadius: '16px', background: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#06b6d4', boxShadow: 'var(--shadow-sm)' }}>
              <Zap size={32} />
            </div>
            <div>
              <div style={{ fontSize: '0.75rem', fontWeight: 800, color: 'var(--muted-foreground)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Impacto Energético Proyectado</div>
              <div style={{ fontSize: '1.6rem', fontWeight: 950, color: '#06b6d4' }}>
                ${projectedCost.toLocaleString('es-CO', { minimumFractionDigits: 2 })} 
                <span style={{ fontSize: '0.9rem', color: 'var(--muted-foreground)', fontWeight: 700 }}> / día</span>
              </div>
            </div>
          </div>
          <button 
            onClick={handleRegisterAeration} 
            disabled={loading} 
            className="btn-primary" 
            style={{ 
              padding: '1.5rem', 
              borderRadius: '24px', 
              fontSize: '1.2rem', 
              fontWeight: 900, 
              background: '#06b6d4',
              boxShadow: '0 10px 25px -5px rgba(6, 182, 212, 0.4)'
            }}
          >
            {loading ? <Activity className="animate-spin" size={24} /> : <Activity size={24} />}
            Guardar Configuración
          </button>
        </div>

        <div style={{ 
          padding: '1.5rem', 
          borderRadius: '28px', 
          background: 'var(--card)', 
          border: '1px solid var(--border)', 
          display: 'flex', 
          gap: '1.5rem', 
          alignItems: 'center' 
        }}>
          <div style={{ width: '56px', height: '56px', borderRadius: '50%', background: 'rgba(6, 182, 212, 0.1)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
            <Activity size={32} style={{ color: '#06b6d4' }} />
          </div>
          <p style={{ fontSize: '0.95rem', color: 'var(--muted-foreground)', lineHeight: 1.6 }}>
            La aireación mecánica aumenta la capacidad de carga del estanque hasta en un <strong>300%</strong>. Asegúrese de realizar mantenimiento preventivo cada 500 horas de uso.
          </p>
        </div>
      </div>

      {/* Inventory Modal */}
      <AnimatePresence>
        {isModalOpen && (
          <div style={{ position: 'fixed', inset: 0, zIndex: 100, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '1rem' }}>
            <motion.div 
              initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
              onClick={() => setIsModalOpen(false)}
              style={{ position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.4)', backdropFilter: 'blur(4px)' }}
            />
            <motion.div 
              initial={{ opacity: 0, scale: 0.9, y: 20 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.9, y: 20 }}
              className="card-premium"
              style={{ position: 'relative', width: '100%', maxWidth: '500px', padding: '2rem', maxHeight: '80vh', overflowY: 'auto' }}
            >
              <h2 style={{ fontSize: '1.5rem', fontWeight: 900, marginBottom: '1.5rem', display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                <Wind size={28} style={{ color: '#06b6d4' }} />
                Aireadores Disponibles
              </h2>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                {inventory.length === 0 ? (
                  <div style={{ textAlign: 'center', padding: '2rem', color: 'var(--muted-foreground)' }}>
                    No hay aireadores disponibles en el almacén.
                  </div>
                ) : (
                  inventory.map(item => (
                    <button 
                      key={item.id}
                      onClick={() => handleAddFromInventory(item)}
                      style={{ 
                        display: 'flex', 
                        justifyContent: 'space-between', 
                        alignItems: 'center', 
                        padding: '1.25rem', 
                        background: 'var(--secondary)', 
                        border: '1px solid var(--border)', 
                        borderRadius: '16px',
                        cursor: 'pointer',
                        textAlign: 'left'
                      }}
                    >
                      <div>
                        <div style={{ fontWeight: 800, fontSize: '1rem' }}>{item.name}</div>
                        <div style={{ fontSize: '0.75rem', color: 'var(--muted-foreground)' }}>Marca: {item.brand || '---'}</div>
                      </div>
                      <div style={{ background: '#06b6d4', color: 'white', padding: '0.4rem 0.8rem', borderRadius: '10px', fontSize: '0.75rem', fontWeight: 900 }}>
                        STOCK: {item.current_stock}
                      </div>
                    </button>
                  ))
                )}
              </div>
              <button 
                onClick={() => setIsModalOpen(false)}
                className="btn-secondary" 
                style={{ width: '100%', marginTop: '2rem', padding: '1rem', borderRadius: '14px', fontWeight: 800 }}
              >
                Cancelar
              </button>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
      
      <style jsx>{`
        @keyframes spin-slow {
          from { transform: rotate(0deg); }
          to { transform: rotate(360deg); }
        }
        .animate-spin-slow {
          animation: spin-slow 3s linear infinite;
        }
      `}</style>
    </div>
  );
}
