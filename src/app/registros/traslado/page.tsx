'use client';

import { useEffect, useState, useMemo } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  ArrowRightLeft, 
  Calendar, 
  Waves, 
  ArrowLeft,
  ArrowRight,
  Activity,
  Info,
  ShieldCheck,
  TrendingDown,
  TrendingUp,
  Zap,
  Box,
  CornerRightDown,
  History,
  ChevronRight,
  Plus,
  AlertCircle
} from 'lucide-react';
import Link from 'next/link';
import { toast } from 'react-hot-toast';
import { supabase } from '@/lib/supabase';

export default function TrasladoPage() {
  const [fecha, setFecha] = useState(new Date().toISOString().split('T')[0]);
  const [origenId, setOrigenId] = useState('');
  const [destinoId, setDestinoId] = useState('');
  const [traslados, setTraslados] = useState<any[]>([]);
  const [ponds, setPonds] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);

  const [history, setHistory] = useState<any[]>([]);

  useEffect(() => {
    fetchPonds();
    fetchHistory();
  }, []);

  const fetchHistory = async () => {
    const activeUnitId = localStorage.getItem('active_unit_id');
    if (!activeUnitId) return;

    const { data } = await supabase
      .from('transfers')
      .select('*, origen:estanques!origen_id(name), destino:estanques!destino_id(name)')
      .eq('unit_id', activeUnitId)
      .order('date', { ascending: false })
      .limit(10);
    
    if (data) setHistory(data);
  };

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

  const addNewSpeciesRow = () => {
    setTraslados([...traslados, {
      speciesId: null,
      speciesName: '',
      quantity: '',
      currentCount: 0
    }]);
  };

  const removeSpeciesRow = (index: number) => {
    if (traslados.length > 1) {
      const newTras = [...traslados];
      newTras.splice(index, 1);
      setTraslados(newTras);
    }
  };

  const updateTraslado = (index: number, field: string, value: string) => {
    const newTraslados = [...traslados];
    newTraslados[index] = { ...newTraslados[index], [field]: value };
    setTraslados(newTraslados);
  };

  const handleRegisterTraslado = async () => {
    setLoading(true);
    try {
      const activeUnitId = localStorage.getItem('active_unit_id');
      if (!origenId || !destinoId || !activeUnitId) throw new Error("Complete los campos requeridos");

      const registerPromise = async () => {
        let totalMoved = 0;
        const operations = traslados.map(async (t) => {
          const qty = parseInt(t.quantity) || 0;
          if (qty <= 0) return;

          if (qty > t.currentCount) {
            throw new Error(`La cantidad de ${t.speciesName} excede la población actual.`);
          }

          totalMoved += qty;

          const { error: logError } = await supabase.from('transfers').insert([{
            origen_id: origenId,
            destino_id: destinoId,
            unit_id: activeUnitId,
            species_name: t.speciesName,
            quantity: qty,
            date: fecha
          }]);
          if (logError) throw logError;

          if (t.speciesId) {
            await supabase.from('pond_species').update({ current_count: t.currentCount - qty }).eq('id', t.speciesId);
          }

          const { data: destSpecies } = await supabase
            .from('pond_species')
            .select('*')
            .eq('estanque_id', destinoId)
            .eq('species_name', t.speciesName)
            .single();
          
          if (destSpecies) {
            await supabase.from('pond_species').update({ current_count: (destSpecies.current_count || 0) + qty }).eq('id', destSpecies.id);
          } else {
            const dp = ponds.find(p => p.id === destinoId);
            if (dp && !dp.is_polyculture && dp.current_species === t.speciesName) {
              await supabase.from('estanques').update({ current_count: (dp.current_count || 0) + qty }).eq('id', destinoId);
            } else {
              await supabase.from('pond_species').insert([{ estanque_id: destinoId, species_name: t.speciesName, current_count: qty, unit_id: activeUnitId }]);
            }
          }
        });

        await Promise.all(operations);

        const op = ponds.find(p => p.id === origenId);
        if (op) {
          await supabase.from('estanques').update({ current_count: (op.current_count || 0) - totalMoved }).eq('id', origenId);
        }
        return true;
      };

      toast.promise(registerPromise(), {
        loading: 'Procesando traslado...',
        success: () => {
          setOrigenId('');
          setDestinoId('');
          fetchPonds();
          fetchHistory();
          return "¡Traslado registrado con éxito!";
        },
        error: (err) => `Error: ${err.message}`
      });
    } catch (err: any) {
      toast.error(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="animate-fade-in page-container">
      <header style={{ marginBottom: '2rem', display: 'flex', alignItems: 'center', gap: '1rem' }}>
        <Link href="/registros" style={{ color: 'var(--muted-foreground)', display: 'flex', alignItems: 'center', justifyContent: 'center', width: '40px', height: '40px', borderRadius: '50%', background: 'var(--card)', border: '1px solid var(--border)' }}>
          <ArrowLeft size={20} />
        </Link>
        <div>
          <h1 style={{ fontWeight: 800 }}>Traslado de Peces</h1>
          <p style={{ color: 'var(--muted-foreground)', fontSize: '0.9rem' }}>Movimiento interno de biomasa.</p>
        </div>
      </header>

      <div className="responsive-grid-2">
        <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
          {/* Main Transfer Flow */}
          <div className="card-premium" style={{ padding: '1.5rem' }}>
            <div className="premium-input-group" style={{ marginBottom: '1.5rem' }}>
              <label className="premium-label">Fecha</label>
              <input type="date" value={fecha} onChange={(e) => setFecha(e.target.value)} className="premium-input" />
            </div>

            <div className="responsive-grid-2" style={{ marginBottom: '1.5rem' }}>
              <div className="premium-input-group">
                <label className="premium-label">Origen</label>
                <div className="premium-select-wrapper">
                  <select value={origenId} onChange={(e) => setOrigenId(e.target.value)} className="premium-input">
                    <option value="">Seleccionar...</option>
                    {ponds.map(p => <option key={p.id} value={p.id}>{p.name}</option>)}
                  </select>
                </div>
              </div>
              <div className="premium-input-group">
                <label className="premium-label">Destino</label>
                <div className="premium-select-wrapper">
                  <select value={destinoId} onChange={(e) => setDestinoId(e.target.value)} className="premium-input">
                    <option value="">Seleccionar...</option>
                    {ponds.filter(p => p.id !== origenId).map(p => <option key={p.id} value={p.id}>{p.name}</option>)}
                  </select>
                </div>
              </div>
            </div>

            <AnimatePresence>
              {origenId && (
                <motion.div 
                  initial={{ opacity: 0, y: 10 }} 
                  animate={{ opacity: 1, y: 0 }} 
                  exit={{ opacity: 0, y: -10 }}
                  key="traslado-form"
                >
                  {ponds.find(p => p.id === origenId)?.is_polyculture && traslados.some(t => !t.speciesId) && (
                    <div style={{ 
                      padding: '1rem', 
                      borderRadius: '12px', 
                      background: 'rgba(245, 158, 11, 0.1)', 
                      border: '1px solid rgba(245, 158, 11, 0.2)',
                      display: 'flex',
                      gap: '0.75rem',
                      alignItems: 'center',
                      marginBottom: '1rem'
                    }}>
                      <AlertCircle size={20} style={{ color: '#f59e0b' }} />
                      <div style={{ fontSize: '0.85rem', color: '#92400e', lineHeight: 1.4 }}>
                        <strong>Aviso:</strong> No hay desglose de especies para este policultivo en origen. Puede definirlas a continuación.
                      </div>
                    </div>
                  )}

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
                        alignItems: 'center',
                        position: 'relative'
                      }}>
                        {traslados.length > 1 && (
                          <button 
                            onClick={() => removeSpeciesRow(index)}
                            style={{ position: 'absolute', top: '0.5rem', right: '0.5rem', color: '#ef4444', background: 'none', border: 'none', cursor: 'pointer', fontSize: '0.65rem', fontWeight: 800 }}
                          >
                            X
                          </button>
                        )}
                        <div>
                          {t.speciesId ? (
                            <div style={{ fontWeight: 800, fontSize: '0.95rem' }}>{t.speciesName}</div>
                          ) : (
                            <input 
                              type="text"
                              value={t.speciesName}
                              onChange={(e) => updateTraslado(index, 'speciesName', e.target.value)}
                              placeholder="Especie"
                              style={{ width: '100%', padding: '0.4rem', borderRadius: '6px', border: '1px solid var(--border)', fontSize: '0.85rem', fontWeight: 700 }}
                            />
                          )}
                          <div style={{ fontSize: '0.75rem', color: 'var(--muted-foreground)' }}>En origen: {t.currentCount.toLocaleString()}</div>
                        </div>
                        <div>
                          <input 
                            type="number" 
                            value={t.quantity}
                            onChange={(e) => updateTraslado(index, 'quantity', e.target.value)}
                            placeholder="Cant."
                            style={{ width: '100%', padding: '0.5rem', borderRadius: '8px', border: '1px solid var(--border)', background: 'white', outline: 'none', fontWeight: 800 }}
                          />
                        </div>
                        <div style={{ textAlign: 'center' }}>
                          <CornerRightDown size={18} style={{ color: 'var(--primary)' }} />
                        </div>
                      </div>
                    ))}

                    {ponds.find(p => p.id === origenId)?.is_polyculture && (
                      <button 
                        onClick={addNewSpeciesRow}
                        style={{ 
                          width: '100%', 
                          padding: '0.75rem', 
                          borderRadius: '10px', 
                          border: '2px dashed var(--border)', 
                          background: 'none', 
                          color: 'var(--muted-foreground)', 
                          fontWeight: 700, 
                          cursor: 'pointer',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          gap: '0.5rem',
                          fontSize: '0.85rem'
                        }}
                      >
                        <Plus size={14} /> Agregar otra especie al traslado
                      </button>
                    )}
                  </div>

                  <button onClick={handleRegisterTraslado} className="btn-primary" disabled={loading} style={{ width: '100%', padding: '1rem', borderRadius: '12px', fontWeight: 800, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '0.5rem' }}>
                    {loading ? <Activity className="animate-spin" size={18} /> : <ArrowRightLeft size={18} />}
                    Registrar Traslado
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

        {/* Full Width History Table */}
        <div style={{ gridColumn: '1 / -1', marginTop: '3rem' }}>
          <div className="card-premium" style={{ padding: '2rem' }}>
            <h3 style={{ fontSize: '1.1rem', fontWeight: 800, marginBottom: '1.5rem', display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
              <History size={20} style={{ color: 'var(--primary)' }} />
              Historial de Traslados Recientes
            </h3>
            
            <div style={{ overflowX: 'auto' }}>
              <table style={{ width: '100%', borderCollapse: 'collapse', minWidth: '700px' }}>
                <thead>
                  <tr style={{ borderBottom: '2px solid var(--border)' }}>
                    <th style={{ textAlign: 'left', padding: '1rem', fontSize: '0.8rem', color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Especie</th>
                    <th style={{ textAlign: 'left', padding: '1rem', fontSize: '0.8rem', color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Cantidad</th>
                    <th style={{ textAlign: 'left', padding: '1rem', fontSize: '0.8rem', color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Flujo (Origen → Destino)</th>
                    <th style={{ textAlign: 'left', padding: '1rem', fontSize: '0.8rem', color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Fecha</th>
                  </tr>
                </thead>
                <tbody>
                  {history.map((h) => (
                    <tr key={h.id} style={{ borderBottom: '1px solid var(--border)' }}>
                      <td style={{ padding: '1rem', fontWeight: 700 }}>{h.species_name}</td>
                      <td style={{ padding: '1rem', fontWeight: 800, color: '#f59e0b' }}>{h.quantity}</td>
                      <td style={{ padding: '1rem' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                          <span style={{ padding: '0.25rem 0.6rem', background: 'rgba(245, 158, 11, 0.1)', borderRadius: '6px', fontSize: '0.8rem', fontWeight: 600, color: '#f59e0b' }}>
                            {h.origen?.name}
                          </span>
                          <ChevronRight size={14} style={{ color: 'var(--muted-foreground)' }} />
                          <span style={{ padding: '0.25rem 0.6rem', background: 'rgba(59, 130, 246, 0.1)', borderRadius: '6px', fontSize: '0.8rem', fontWeight: 600, color: '#3b82f6' }}>
                            {h.destino?.name}
                          </span>
                        </div>
                      </td>
                      <td style={{ padding: '1rem', fontSize: '0.85rem', color: 'var(--muted-foreground)' }}>
                        {new Date(h.date).toLocaleDateString()}
                      </td>
                    </tr>
                  ))}
                  {history.length === 0 && (
                    <tr>
                      <td colSpan={4} style={{ padding: '3rem', textAlign: 'center', color: 'var(--muted-foreground)' }}>No hay movimientos registrados.</td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
