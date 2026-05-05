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
import { useSearchParams } from 'next/navigation';
import { supabase } from '@/lib/supabase';

export default function AireacionPage() {
  const searchParams = useSearchParams();
  const estanqueParam = searchParams.get('estanque');

  const [fecha, setFecha] = useState(new Date().toISOString().split('T')[0]);
  const [hora, setHora] = useState(new Date().toTimeString().slice(0, 5));
  const [estanqueId, setEstanqueId] = useState(estanqueParam || '');
  
  const [ponds, setPonds] = useState<any[]>([]);
  const [inventory, setInventory] = useState<any[]>([]);

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    const { data: pondData } = await supabase.from('estanques').select('*');
    setPonds(pondData || []);

    const { data: invData } = await supabase.from('inventory').select('*').eq('category', 'aireadores');
    setInventory(invData || []);
  };

  const selectedPond = useMemo(() => ponds.find(p => p.id === estanqueId), [estanqueId, ponds]);

  const [activeAireadores, setActiveAireadores] = useState([
    { id: '1', inventory_id: '', nombre: 'Aireador 01 - Splash 1HP', status: 'ON', hours: '12', consumption: '0.75' },
    { id: '2', inventory_id: '', nombre: 'Aireador 02 - Inyector 2HP', status: 'OFF', hours: '0', consumption: '1.5' },
  ]);

  const handleToggle = (id: string) => {
    setActiveAireadores(activeAireadores.map(a => a.id === id ? { ...a, status: a.status === 'ON' ? 'OFF' : 'ON' } : a));
  };

  const handleRemoveEquipment = async (id: string) => {
    const equipment = activeAireadores.find(a => a.id === id);
    if (!equipment) return;

    // 1. Find in inventory to restore stock
    // Since mock equipment might not have real inventory_id, we'll try to find by name
    const { data: invItem } = await supabase
      .from('inventory')
      .select('*')
      .ilike('name', `%${equipment.nombre.split(' - ')[1] || equipment.nombre}%`)
      .limit(1)
      .single();

    if (invItem) {
      await supabase
        .from('inventory')
        .update({ current_stock: (parseFloat(invItem.current_stock) || 0) + 1 })
        .eq('id', invItem.id);
      
      alert(`Equipo "${equipment.nombre}" desvinculado y devuelto al inventario.`);
    }

    setActiveAireadores(activeAireadores.filter(a => a.id !== id));
  };

  const handleRegisterAeration = async () => {
    if (!estanqueId) {
      alert("Por favor seleccione un estanque.");
      return;
    }

    // 1. Create Aeration Logs for each equipment state
    for (const air of activeAireadores) {
      await supabase.from('aireacion_logs').insert([{
        estanque_id: estanqueId,
        action: air.status,
        observations: `Equipo: ${air.nombre}. Consumo: ${air.consumption}kW. Horas: ${air.hours}h`,
        date: fecha,
        hour: hora
      }]);
    }

    alert("¡Configuración de aireación guardada y registrada en el historial!");
    window.location.href = '/estanques';
  };

  return (
    <div className="animate-fade-in" style={{ maxWidth: '1000px', margin: '0 auto', paddingBottom: '4rem' }}>
      <header style={{ marginBottom: '2.5rem', display: 'flex', alignItems: 'center', gap: '1rem' }}>
        <Link href="/estanques" style={{ color: 'var(--muted-foreground)', display: 'flex', alignItems: 'center', justifyContent: 'center', width: '40px', height: '40px', borderRadius: '50%', background: 'var(--card)', border: '1px solid var(--border)' }}>
          <ArrowLeft size={20} />
        </Link>
        <div>
          <h1 style={{ fontSize: '1.875rem', fontWeight: 700 }}>Control de Aireación</h1>
          <p style={{ color: 'var(--muted-foreground)' }}>Gestión de equipos y suministro de oxígeno disuelto.</p>
        </div>
      </header>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr', gap: '2rem' }}>
        {/* Contextual Info Card */}
        <div className="card-premium" style={{ padding: '2rem', display: 'grid', gridTemplateColumns: '1.5fr 1fr 1fr', gap: '1.5rem', alignItems: 'center' }}>
          <div>
            <div style={{ fontSize: '0.75rem', fontWeight: 700, marginBottom: '0.5rem', textTransform: 'uppercase', color: 'var(--muted-foreground)' }}>Estanque Destino</div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', padding: '0.75rem', background: 'rgba(6, 182, 212, 0.05)', borderRadius: '8px', border: '1px solid rgba(6, 182, 212, 0.1)' }}>
              <Waves size={20} style={{ color: '#06b6d4' }} />
              <span style={{ fontSize: '1.1rem', fontWeight: 800, color: '#06b6d4' }}>
                {selectedPond ? selectedPond.name : 'Seleccionado'}
              </span>
            </div>
          </div>
          <div>
            <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 700, marginBottom: '0.5rem', textTransform: 'uppercase', color: 'var(--muted-foreground)' }}>Fecha</label>
            <input 
              type="date" 
              value={fecha} 
              onChange={(e) => setFecha(e.target.value)}
              style={{ width: '100%', padding: '0.75rem', borderRadius: '8px', border: '1px solid var(--border)', background: 'var(--secondary)', outline: 'none' }} 
            />
          </div>
          <div>
            <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 700, marginBottom: '0.5rem', textTransform: 'uppercase', color: 'var(--muted-foreground)' }}>Hora</label>
            <input 
              type="time" 
              value={hora} 
              onChange={(e) => setHora(e.target.value)}
              style={{ width: '100%', padding: '0.75rem', borderRadius: '8px', border: '1px solid var(--border)', background: 'var(--secondary)', outline: 'none' }} 
            />
          </div>
        </div>

        {/* Equipment Grid */}
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '2rem' }}>
          {activeAireadores.map((a) => (
            <div key={a.id} className="card-premium" style={{ padding: '1.5rem', position: 'relative' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '1.5rem' }}>
                <div style={{ 
                  width: '48px', 
                  height: '48px', 
                  borderRadius: '12px', 
                  background: a.status === 'ON' ? 'rgba(6, 182, 212, 0.1)' : 'var(--secondary)',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  color: a.status === 'ON' ? '#06b6d4' : 'var(--muted-foreground)',
                  transition: 'all 0.3s ease'
                }}>
                  <Wind size={24} className={a.status === 'ON' ? 'animate-spin-slow' : ''} />
                </div>
                <div style={{ display: 'flex', gap: '0.5rem' }}>
                  <button 
                    onClick={() => handleRemoveEquipment(a.id)}
                    style={{ background: 'rgba(239, 68, 68, 0.1)', border: 'none', color: '#ef4444', padding: '0.4rem', borderRadius: '8px', cursor: 'pointer' }}
                    title="Quitar equipo y devolver al almacén"
                  >
                    <Trash2 size={16} />
                  </button>
                  <div style={{ 
                    padding: '0.35rem 0.75rem', 
                    borderRadius: '50px', 
                    fontSize: '0.7rem', 
                    fontWeight: 800, 
                    background: a.status === 'ON' ? '#10b981' : '#64748b', 
                    color: 'white' 
                  }}>
                    {a.status}
                  </div>
                </div>
              </div>

              <h3 style={{ fontSize: '1.1rem', fontWeight: 700, marginBottom: '0.5rem' }}>{a.nombre}</h3>
              
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem', marginBottom: '1.5rem' }}>
                <div style={{ padding: '0.75rem', background: 'var(--secondary)', borderRadius: '8px' }}>
                  <div style={{ fontSize: '0.65rem', color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Consumo</div>
                  <div style={{ fontWeight: 700 }}>{a.consumption} kW/h</div>
                </div>
                <div style={{ padding: '0.75rem', background: 'var(--secondary)', borderRadius: '8px' }}>
                  <div style={{ fontSize: '0.65rem', color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Tiempo Uso</div>
                  <input 
                    type="number" 
                    value={a.hours} 
                    onChange={(e) => setActiveAireadores(activeAireadores.map(item => item.id === a.id ? {...item, hours: e.target.value} : item))}
                    style={{ background: 'transparent', border: 'none', fontWeight: 700, width: '40px', outline: 'none' }}
                  /> h
                </div>
              </div>

              <button 
                onClick={() => handleToggle(a.id)}
                style={{ 
                  width: '100%', 
                  padding: '0.75rem', 
                  borderRadius: '10px', 
                  border: 'none', 
                  background: a.status === 'ON' ? 'rgba(239, 68, 68, 0.1)' : 'rgba(16, 185, 129, 0.1)',
                  color: a.status === 'ON' ? '#ef4444' : '#10b981',
                  fontWeight: 700,
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  gap: '0.5rem',
                  cursor: 'pointer'
                }}
              >
                <Power size={18} />
                {a.status === 'ON' ? 'Detener Equipo' : 'Arrancar Equipo'}
              </button>
            </div>
          ))}

          {/* Add Equipment Placeholder */}
          <button style={{ 
            border: '2px dashed var(--border)', 
            borderRadius: '24px', 
            background: 'transparent',
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            justifyContent: 'center',
            gap: '1rem',
            color: 'var(--muted-foreground)',
            cursor: 'pointer',
            padding: '2rem'
          }}>
            <Plus size={32} />
            <span style={{ fontWeight: 600 }}>Asignar Aireador del Almacén</span>
          </button>
        </div>

        {/* Global Action */}
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '2rem', marginTop: '1rem' }}>
          <div className="card-premium" style={{ padding: '1.5rem', display: 'flex', alignItems: 'center', gap: '1.25rem', borderLeft: '5px solid #06b6d4' }}>
            <Zap size={32} style={{ color: '#06b6d4' }} />
            <div>
              <div style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--muted-foreground)' }}>Impacto Energético Proyectado</div>
              <div style={{ fontSize: '1.25rem', fontWeight: 800 }}>$12,450.00 / día</div>
            </div>
          </div>
          <button 
            onClick={handleRegisterAeration}
            className="btn-primary" 
            style={{ padding: '1.5rem', borderRadius: '24px', fontSize: '1.1rem', fontWeight: 800, background: '#06b6d4' }}
          >
            Guardar Configuración
          </button>
        </div>

        {/* Info Banner */}
        <div style={{ 
          padding: '1.25rem', 
          borderRadius: '20px', 
          background: 'rgba(6, 182, 212, 0.05)', 
          border: '1px solid rgba(6, 182, 212, 0.1)',
          display: 'flex', 
          gap: '1rem', 
          alignItems: 'center'
        }}>
          <Activity size={24} style={{ color: '#06b6d4' }} />
          <p style={{ fontSize: '0.85rem', color: 'var(--muted-foreground)', lineHeight: 1.5 }}>
            La aireación mecánica aumenta la capacidad de carga del estanque hasta en un <strong>300%</strong>. Asegúrese de mantener los equipos limpios de algas para máxima eficiencia.
          </p>
        </div>
      </div>
      
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
