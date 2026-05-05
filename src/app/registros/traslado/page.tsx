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
  const [especieId, setEspecieId] = useState('');
  const [cantidad, setCantidad] = useState('');
  const [ponds, setPonds] = useState<any[]>([]);
  const [origenSpecies, setOrigenSpecies] = useState<any[]>([]);

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
    const { data } = await supabase.from('pond_species').select('*').eq('estanque_id', pondId);
    setOrigenSpecies(data || []);
    if (data && data.length > 0) setEspecieId(data[0].species_name);
    else setEspecieId('');
  };

  useEffect(() => {
    if (origenId) {
      const p = ponds.find(p => p.id === origenId);
      if (p?.is_polyculture) {
        fetchOrigenSpecies(origenId);
      } else {
        setEspecieId(p?.current_species || '');
        setOrigenSpecies([]);
      }
    }
  }, [origenId, ponds]);

  const origenPond = useMemo(() => ponds.find(p => p.id === origenId), [ponds, origenId]);
  const destinoPond = useMemo(() => ponds.find(p => p.id === destinoId), [ponds, destinoId]);
  const selectedSpeciesData = useMemo(() => origenSpecies.find(s => s.species_name === especieId), [origenSpecies, especieId]);

  // Validation
  const canTransfer = useMemo(() => {
    if (!origenPond || !cantidad) return false;
    const qty = parseInt(cantidad) || 0;
    const maxQty = origenPond.is_polyculture ? (selectedSpeciesData?.current_count || 0) : (origenPond.current_count || 0);
    return qty > 0 && qty <= maxQty;
  }, [origenPond, selectedSpeciesData, cantidad]);

  const handleRegisterTraslado = async () => {
    if (!origenId || !destinoId || !cantidad || !especieId) {
      alert("Por favor complete todos los campos.");
      return;
    }

    const qty = parseInt(cantidad);
    const activeUnitId = localStorage.getItem('active_unit_id');
    
    // 0. Obtener Batch ID y Acumulado de alimentación del origen
    let batchId = origenPond?.current_batch_id;
    let feedAccumulated = 0;

    if (batchId) {
      const { data: feedData } = await supabase
        .from('alimentacion_diaria')
        .select('quantity_kg')
        .eq('estanque_id', origenId)
        .eq('batch_id', batchId);
      
      if (feedData) {
        feedAccumulated = feedData.reduce((acc, curr) => acc + (parseFloat(curr.quantity_kg) || 0), 0);
      }
    }

    // 1. Log Transfer with Batch and Feed
    const { error: logError } = await supabase.from('transfers').insert([{
      origen_id: origenId,
      destino_id: destinoId,
      unit_id: activeUnitId,
      species_name: especieId,
      quantity: qty,
      date: fecha,
      batch_id: batchId,
      accumulated_feed: feedAccumulated
    }]);

    if (logError) {
      alert("Error al registrar traslado: " + logError.message);
      return;
    }

    // 2. Update Source Species (if polyculture)
    if (origenPond?.is_polyculture && selectedSpeciesData) {
      await supabase.from('pond_species')
        .update({ current_count: selectedSpeciesData.current_count - qty })
        .eq('id', selectedSpeciesData.id);
    }

    // 3. Update Source Pond Total
    const newSourceCount = (origenPond?.current_count || 0) - qty;
    await supabase.from('estanques').update({
      current_count: newSourceCount,
      status: newSourceCount <= 0 ? 'vacio' : 'con_peces',
      ...(newSourceCount <= 0 ? { current_batch_id: null } : {})
    }).eq('id', origenId);

    // 4. Update Destination Species
    const { data: destSpecies } = await supabase.from('pond_species')
      .select('*')
      .eq('estanque_id', destinoId)
      .eq('species_name', especieId)
      .single();

    if (destSpecies) {
      await supabase.from('pond_species')
        .update({ 
          current_count: destSpecies.current_count + qty,
          batch_id: batchId // Heredar lote
        })
        .eq('id', destSpecies.id);
    } else {
      await supabase.from('pond_species').insert([{
        estanque_id: destinoId,
        species_name: especieId,
        current_count: qty,
        batch_id: batchId // Heredar lote
      }]);
    }

    // 5. Update Destination Pond Total
    const newDestCount = (destinoPond?.current_count || 0) + qty;
    await supabase.from('estanques').update({
      current_count: newDestCount,
      status: 'con_peces',
      current_batch_id: batchId, // El estanque ahora tiene este lote
      ...( (destinoPond?.current_count || 0) === 0 ? { current_species: especieId } : {} )
    }).eq('id', destinoId);

    alert("¡Traslado completado con éxito!");
    setCantidad('');
    setOrigenId('');
    setDestinoId('');
    fetchPonds();
  };

  return (
    <div className="animate-fade-in" style={{ maxWidth: '1200px', margin: '0 auto', paddingBottom: '4rem' }}>
      <header style={{ marginBottom: '2.5rem', display: 'flex', alignItems: 'center', gap: '1rem' }}>
        <Link href="/registros" style={{ color: 'var(--muted-foreground)', display: 'flex', alignItems: 'center', justifyContent: 'center', width: '40px', height: '40px', borderRadius: '50%', background: 'var(--card)', border: '1px solid var(--border)' }}>
          <ArrowLeft size={20} />
        </Link>
        <div>
          <h1 style={{ fontSize: '1.875rem', fontWeight: 700 }}>Traslado de Peces</h1>
          <p style={{ color: 'var(--muted-foreground)' }}>Movimiento interno de biomasa entre estanques.</p>
        </div>
      </header>

      <div style={{ display: 'grid', gridTemplateColumns: '1.5fr 1fr', gap: '2rem' }}>
        {/* Main Transfer Flow */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
          <div className="card-premium" style={{ padding: '2.5rem' }}>
            <div style={{ marginBottom: '2rem' }}>
              <label style={{ display: 'block', fontSize: '0.7rem', fontWeight: 700, marginBottom: '0.5rem', textTransform: 'uppercase', color: 'var(--muted-foreground)' }}>Fecha del Traslado</label>
              <input type="date" value={fecha} onChange={(e) => setFecha(e.target.value)} style={{ width: '200px', padding: '0.75rem', borderRadius: '10px', border: '1px solid var(--border)', background: 'var(--secondary)', outline: 'none' }} />
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 60px 1fr', gap: '1.5rem', alignItems: 'center', marginBottom: '2.5rem' }}>
              {/* Source */}
              <div style={{ padding: '1.5rem', background: 'rgba(245, 158, 11, 0.05)', borderRadius: '20px', border: '2px solid rgba(245, 158, 11, 0.2)' }}>
                <label style={{ display: 'block', fontSize: '0.7rem', fontWeight: 800, color: '#f59e0b', textTransform: 'uppercase', marginBottom: '0.75rem' }}>Estanque de Origen</label>
                <select 
                  value={origenId}
                  onChange={(e) => {
                    setOrigenId(e.target.value);
                    setEspecieId('');
                  }}
                  style={{ width: '100%', padding: '0.75rem', borderRadius: '10px', border: '1px solid var(--border)', background: 'white', outline: 'none', fontWeight: 700 }}
                >
                  <option value="">Seleccionar...</option>
                  {ponds.map(p => <option key={p.id} value={p.id}>{p.name} {p.is_polyculture ? '(Policultivo)' : ''}</option>)}
                </select>

                 {origenPond && (
                   <div style={{ marginTop: '1.5rem' }}>
                     <label style={{ display: 'block', fontSize: '0.7rem', fontWeight: 700, color: 'var(--muted-foreground)', textTransform: 'uppercase', marginBottom: '0.4rem' }}>Especie a Trasladar</label>
                     {origenPond.is_polyculture ? (
                       <select 
                         value={especieId}
                         onChange={(e) => setEspecieId(e.target.value)}
                         style={{ width: '100%', padding: '0.6rem', borderRadius: '8px', border: '1px solid var(--border)', background: 'white', fontWeight: 600, outline: 'none' }}
                       >
                         <option value="">Seleccionar Especie...</option>
                         {origenSpecies.map(s => <option key={s.id} value={s.species_name}>{s.species_name} ({s.current_count})</option>)}
                       </select>
                     ) : (
                       <div style={{ padding: '0.6rem', borderRadius: '8px', border: '1px solid var(--border)', background: 'white', fontWeight: 600 }}>
                         {origenPond.current_species || 'Vacio'} ({origenPond.current_count || 0})
                       </div>
                     )}
                   </div>
                 )}
              </div>

              {/* Arrow */}
              <div style={{ display: 'flex', justifyContent: 'center' }}>
                <div style={{ width: '40px', height: '40px', borderRadius: '50%', background: 'var(--secondary)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#f59e0b' }}>
                  <ArrowRight size={24} />
                </div>
              </div>

              {/* Destination */}
              <div style={{ padding: '1.5rem', background: 'rgba(59, 130, 246, 0.05)', borderRadius: '20px', border: '2px solid rgba(59, 130, 246, 0.2)' }}>
                <label style={{ display: 'block', fontSize: '0.7rem', fontWeight: 800, color: '#3b82f6', textTransform: 'uppercase', marginBottom: '0.75rem' }}>Estanque de Destino</label>
                <select 
                  value={destinoId}
                  onChange={(e) => setDestinoId(e.target.value)}
                  style={{ width: '100%', padding: '0.75rem', borderRadius: '10px', border: '1px solid var(--border)', background: 'white', outline: 'none', fontWeight: 700 }}
                >
                  <option value="">Seleccionar...</option>
                  {ponds.filter(p => p.id !== origenId).map(p => (
                    <option key={p.id} value={p.id}>{p.name} {p.status === 'vacio' ? '(Vacio)' : p.is_polyculture ? '(Policultivo)' : `(${p.current_species})`}</option>
                  ))}
                </select>
                <div style={{ marginTop: '1.5rem', fontSize: '0.75rem', color: 'var(--muted-foreground)' }}>
                  {destinoPond ? `Destino seleccionado: ${destinoPond.name}` : 'Seleccione un destino válido.'}
                </div>
              </div>
            </div>

            <div style={{ marginBottom: '2.5rem', maxWidth: '400px' }}>
              <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 700, marginBottom: '0.5rem', textTransform: 'uppercase', color: 'var(--muted-foreground)' }}>Cantidad de Individuos a Trasladar</label>
              <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                <input 
                  type="number" 
                  value={cantidad}
                  onChange={(e) => setCantidad(e.target.value)}
                  placeholder="0"
                  style={{ flex: 1, padding: '1rem', fontSize: '1.5rem', borderRadius: '12px', border: '1px solid var(--border)', background: 'var(--secondary)', outline: 'none', fontWeight: 800 }} 
                />
                {origenPond && (
                  <div style={{ fontSize: '0.8rem', color: 'var(--muted-foreground)' }}>
                    de {(origenPond.current_count || 0).toLocaleString()} disponibles
                  </div>
                )}
              </div>
            </div>

            <button 
              onClick={handleRegisterTraslado}
              className="btn-primary" 
              disabled={!canTransfer || !destinoId}
              style={{ width: '100%', padding: '1.25rem', borderRadius: '16px', background: '#f59e0b', fontSize: '1.1rem', fontWeight: 800, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '0.75rem', opacity: (!canTransfer || !destinoId) ? 0.5 : 1 }}
            >
              <ArrowRightLeft size={22} />
              Confirmar Traslado
            </button>
          </div>
        </div>

        {/* Impact Analysis Sidebar */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
          {/* Inventory Preview Card */}
          <div className="card-premium" style={{ padding: '2rem' }}>
            <h3 style={{ fontSize: '0.85rem', fontWeight: 700, color: 'var(--muted-foreground)', textTransform: 'uppercase', marginBottom: '1.5rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <Box size={18} style={{ color: '#f59e0b' }} /> Vista Previa de Inventario
            </h3>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
              <div style={{ padding: '1rem', background: 'var(--secondary)', borderRadius: '12px' }}>
                <div style={{ fontSize: '0.7rem', fontWeight: 700, color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Origen ({origenPond?.name || '--'})</div>
                <div style={{ fontSize: '1.1rem', fontWeight: 800, color: '#ef4444', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                  {origenPond ? (origenPond.current_count - (parseInt(cantidad) || 0)).toLocaleString() : '--'}
                  <TrendingDown size={16} />
                </div>
              </div>

              <div style={{ display: 'flex', justifyContent: 'center' }}>
                <CornerRightDown size={24} style={{ color: 'var(--muted-foreground)', opacity: 0.3 }} />
              </div>

              <div style={{ padding: '1rem', background: 'var(--secondary)', borderRadius: '12px' }}>
                <div style={{ fontSize: '0.7rem', fontWeight: 700, color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Destino ({destinoPond?.name || '--'})</div>
                <div style={{ fontSize: '1.1rem', fontWeight: 800, color: '#10b981', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                  {destinoPond ? ((destinoPond.current_count || 0) + (parseInt(cantidad) || 0)).toLocaleString() : '--'}
                  <TrendingUp size={16} />
                </div>
              </div>
            </div>
          </div>

          {/* Quick Warning */}
          {!canTransfer && cantidad && origenPond && (
            <div style={{ 
              padding: '1.25rem', 
              borderRadius: '16px', 
              background: 'rgba(239, 68, 68, 0.1)', 
              border: '1px solid #ef4444',
              display: 'flex', 
              gap: '1rem',
              alignItems: 'center'
            }}>
              <Info size={20} style={{ color: '#ef4444', flexShrink: 0 }} />
              <p style={{ fontSize: '0.85rem', color: '#991b1b', fontWeight: 600 }}>
                Cantidad excede la población disponible en el origen.
              </p>
            </div>
          )}

          {/* Safety Recommendation */}
          <div style={{ 
            padding: '1.5rem', 
            borderRadius: '20px', 
            background: 'var(--card)', 
            border: '1px solid var(--border)',
            display: 'flex', 
            gap: '1rem'
          }}>
            <ShieldCheck size={20} style={{ color: '#10b981', flexShrink: 0 }} />
            <p style={{ fontSize: '0.85rem', color: 'var(--muted-foreground)', lineHeight: 1.5 }}>
              Realice los traslados preferiblemente en <strong>horas frescas</strong> para reducir el estrés metabólico de los peces.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
