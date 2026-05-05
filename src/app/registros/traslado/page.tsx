'use client';

import { useEffect, useState, useMemo } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  ArrowRightLeft, 
  Calendar, 
  Waves, 
  ArrowLeft,
  ArrowRight,
  Info,
  ShieldCheck,
  TrendingDown,
  TrendingUp,
  Zap,
  Box,
  CornerRightDown
} from 'lucide-react';
import Link from 'next/link';
import { supabase } from '@/lib/supabase';

export default function TrasladoPage() {
  const [fecha, setFecha] = useState(new Date().toISOString().split('T')[0]);
  const [origenId, setOrigenId] = useState('');
  const [destinoId, setDestinoId] = useState('');
  const [traslados, setTraslados] = useState<any[]>([]);
  const [ponds, setPonds] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    fetchPonds();
  }, []);

  const fetchPonds = async () => {
    const activeUnitId = localStorage.getItem('active_unit_id');
    const { data } = await supabase
      .from('estanques')
      .select('*')
      .eq('unit_id', activeUnitId)
      .order('name');
    setPonds(data || []);
  };

  const fetchOrigenSpecies = async (pondId: string) => {
    setLoading(true);
    const { data } = await supabase.from('pond_species').select('*').eq('estanque_id', pondId);
    if (data && data.length > 0) {
      setTraslados(data.map(s => ({
        speciesId: s.id,
        speciesName: s.species_name,
        quantity: '',
        currentCount: s.current_count || 0
      })));
    } else {
      const p = ponds.find(pond => pond.id === pondId);
      setTraslados([{
        speciesId: null,
        speciesName: p?.current_species || 'Especie Principal',
        quantity: '',
        currentCount: p?.current_count || 0
      }]);
    }
    setLoading(false);
  };

  useEffect(() => {
    if (origenId) {
      fetchOrigenSpecies(origenId);
    } else {
      setTraslados([]);
    }
  }, [origenId, ponds]);

  const updateTraslado = (index: number, qty: string) => {
    const newTraslados = [...traslados];
    newTraslados[index].quantity = qty;
    setTraslados(newTraslados);
  };

  const handleRegisterTraslado = async () => {
    if (!origenId || !destinoId || traslados.every(t => !t.quantity || parseInt(t.quantity) <= 0)) {
      alert("Por favor complete los campos obligatorios.");
      return;
    }

    const activeUnitId = localStorage.getItem('active_unit_id');
    setLoading(true);

    try {
      for (const t of traslados) {
        const qty = parseInt(t.quantity) || 0;
        if (qty <= 0) continue;

        if (qty > t.currentCount) {
          alert(`La cantidad a trasladar de ${t.speciesName} excede la población actual.`);
          setLoading(false);
          return;
        }

        // 1. Log Transfer
        const { error: logError } = await supabase.from('transfers').insert([{
          origen_id: origenId,
          destino_id: destinoId,
          unit_id: activeUnitId,
          species_name: t.speciesName,
          quantity: qty,
          date: fecha
        }]);

        if (logError) throw logError;

        // 2. Update Origin (Species or Pond)
        if (t.speciesId) {
          await supabase.from('pond_species').update({ current_count: t.currentCount - qty }).eq('id', t.speciesId);
        }

        // 3. Update Destino (Logic to find or create species in destination)
        const { data: destSpecies } = await supabase
          .from('pond_species')
          .select('*')
          .eq('estanque_id', destinoId)
          .eq('species_name', t.speciesName)
          .single();
        
        if (destSpecies) {
          await supabase.from('pond_species').update({ current_count: (destSpecies.current_count || 0) + qty }).eq('id', destSpecies.id);
        } else {
          // If monoculture pond destination, check if it matches
          const dp = ponds.find(p => p.id === destinoId);
          if (dp && !dp.is_polyculture && dp.current_species === t.speciesName) {
            await supabase.from('estanques').update({ current_count: (dp.current_count || 0) + qty }).eq('id', destinoId);
          } else if (dp && dp.is_polyculture) {
            await supabase.from('pond_species').insert([{ estanque_id: destinoId, species_name: t.speciesName, current_count: qty, unit_id: activeUnitId }]);
          }
        }
      }

      // Update Global Pond Counts (Origen)
      const op = ponds.find(p => p.id === origenId);
      const totalMoved = traslados.reduce((acc, curr) => acc + (parseInt(curr.quantity) || 0), 0);
      await supabase.from('estanques').update({ current_count: (op?.current_count || 0) - totalMoved }).eq('id', origenId);

      alert("¡Traslado registrado con éxito!");
      setOrigenId('');
      setDestinoId('');
      fetchPonds();
    } catch (err: any) {
      alert("Error: " + err.message);
    }
    setLoading(false);
  };

  return (
    <div className="animate-fade-in" style={{ maxWidth: '1200px', margin: '0 auto', paddingBottom: '4rem' }}>
      <header style={{ marginBottom: '2.5rem', display: 'flex', alignItems: 'center', gap: '1rem' }}>
        <Link href="/registros" style={{ color: 'var(--muted-foreground)', display: 'flex', alignItems: 'center', justifyContent: 'center', width: '40px', height: '40px', borderRadius: '50%', background: 'var(--card)', border: '1px solid var(--border)' }}>
          <ArrowLeft size={20} />
        </Link>
        <div>
          <h1 style={{ fontSize: '1.875rem', fontWeight: 700 }}>Traslado de Peces</h1>
          <p style={{ color: 'var(--muted-foreground)' }}>Movimiento interno de biomasa entre estanques por especie.</p>
        </div>
      </header>

      <div style={{ display: 'grid', gridTemplateColumns: '1.5fr 1fr', gap: '2rem' }}>
        {/* Main Transfer Flow */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
          <div className="card-premium" style={{ padding: '2.5rem' }}>
            <div style={{ marginBottom: '2rem' }}>
              <label className="premium-label">Fecha del Traslado</label>
              <input type="date" value={fecha} onChange={(e) => setFecha(e.target.value)} className="premium-date-input" style={{ width: '200px' }} />
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 60px 1fr', gap: '1.5rem', alignItems: 'center', marginBottom: '2.5rem' }}>
              {/* Origen */}
              <div style={{ padding: '1.5rem', background: 'rgba(245, 158, 11, 0.05)', borderRadius: '20px', border: '2px solid rgba(245, 158, 11, 0.2)' }}>
                <label style={{ display: 'block', fontSize: '0.7rem', fontWeight: 800, color: '#f59e0b', textTransform: 'uppercase', marginBottom: '0.75rem' }}>Origen</label>
                <select 
                  value={origenId}
                  onChange={(e) => setOrigenId(e.target.value)}
                  style={{ width: '100%', padding: '0.75rem', borderRadius: '10px', border: '1px solid var(--border)', background: 'white', outline: 'none', fontWeight: 700 }}
                >
                  <option value="">Seleccionar...</option>
                  {ponds.map(p => <option key={p.id} value={p.id}>{p.name}</option>)}
                </select>
              </div>

              {/* Arrow */}
              <div style={{ display: 'flex', justifyContent: 'center' }}>
                <div style={{ width: '40px', height: '40px', borderRadius: '50%', background: 'var(--secondary)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#f59e0b' }}>
                  <ArrowRight size={24} />
                </div>
              </div>

              {/* Destino */}
              <div style={{ padding: '1.5rem', background: 'rgba(59, 130, 246, 0.05)', borderRadius: '20px', border: '2px solid rgba(59, 130, 246, 0.2)' }}>
                <label style={{ display: 'block', fontSize: '0.7rem', fontWeight: 800, color: '#3b82f6', textTransform: 'uppercase', marginBottom: '0.75rem' }}>Destino</label>
                <select 
                  value={destinoId}
                  onChange={(e) => setDestinoId(e.target.value)}
                  style={{ width: '100%', padding: '0.75rem', borderRadius: '10px', border: '1px solid var(--border)', background: 'white', outline: 'none', fontWeight: 700 }}
                >
                  <option value="">Seleccionar...</option>
                  {ponds.filter(p => p.id !== origenId).map(p => (
                    <option key={p.id} value={p.id}>{p.name} {p.status === 'vacio' ? '(Vacio)' : ''}</option>
                  ))}
                </select>
              </div>
            </div>

            <AnimatePresence>
              {origenId && (
                <motion.div 
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0 }}
                >
                  <h3 style={{ fontSize: '0.85rem', fontWeight: 800, color: 'var(--muted-foreground)', textTransform: 'uppercase', marginBottom: '1.5rem', borderTop: '1px solid var(--border)', paddingTop: '1.5rem' }}>Especies a Trasladar</h3>
                  
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem', marginBottom: '2.5rem' }}>
                    {traslados.map((t, index) => (
                      <div key={index} style={{ 
                        padding: '1.25rem', 
                        background: 'var(--secondary)', 
                        borderRadius: '12px', 
                        border: '1px solid var(--border)',
                        display: 'grid',
                        gridTemplateColumns: '2fr 1fr 1fr',
                        gap: '1rem',
                        alignItems: 'center'
                      }}>
                        <div>
                          <div style={{ fontWeight: 800, fontSize: '0.95rem' }}>{t.speciesName}</div>
                          <div style={{ fontSize: '0.75rem', color: 'var(--muted-foreground)' }}>En origen: {t.currentCount.toLocaleString()}</div>
                        </div>
                        <div>
                          <input 
                            type="number" 
                            value={t.quantity}
                            onChange={(e) => updateTraslado(index, e.target.value)}
                            placeholder="Cantidad"
                            style={{ width: '100%', padding: '0.5rem', borderRadius: '8px', border: '1px solid var(--border)', background: 'white', outline: 'none', fontWeight: 800 }}
                          />
                        </div>
                        <div style={{ textAlign: 'center' }}>
                          <CornerRightDown size={18} style={{ color: 'var(--primary)' }} />
                        </div>
                      </div>
                    ))}
                  </div>

                  <button 
                    onClick={handleRegisterTraslado}
                    disabled={loading || traslados.every(t => !t.quantity || parseInt(t.quantity) <= 0) || !destinoId}
                    className="btn-primary" 
                    style={{ width: '100%', padding: '1.25rem', borderRadius: '16px', background: '#f59e0b', fontSize: '1.1rem', fontWeight: 800, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '0.75rem', opacity: (loading || !destinoId || traslados.every(t => !t.quantity || parseInt(t.quantity) <= 0)) ? 0.6 : 1 }}
                  >
                    {loading ? <Activity className="animate-spin" size={22} /> : <ArrowRightLeft size={22} />}
                    Ejecutar Traslado Masivo
                  </button>
                </motion.div>
              )}
            </AnimatePresence>
          </div>
        </div>

        {/* Info Panel */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
          <div className="card-premium" style={{ padding: '2rem' }}>
            <h3 style={{ fontSize: '0.85rem', fontWeight: 800, color: 'var(--muted-foreground)', textTransform: 'uppercase', marginBottom: '1.5rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <ShieldCheck size={20} style={{ color: 'var(--primary)' }} />
              Reglas de Traslado
            </h3>
            <ul style={{ listStyle: 'none', padding: 0, display: 'flex', flexDirection: 'column', gap: '1rem' }}>
              <li style={{ display: 'flex', gap: '0.75rem', fontSize: '0.85rem', lineHeight: 1.4 }}>
                <Zap size={16} style={{ color: '#f59e0b', flexShrink: 0 }} />
                <span>La trazabilidad de alimentación se mantiene vinculada al lote (Batch ID) durante el traslado.</span>
              </li>
              <li style={{ display: 'flex', gap: '0.75rem', fontSize: '0.85rem', lineHeight: 1.4 }}>
                <Box size={16} style={{ color: '#3b82f6', flexShrink: 0 }} />
                <span>Si el destino está vacío, heredará automáticamente las propiedades de las especies trasladadas.</span>
              </li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  );
}
