'use client';

import { useEffect, useState, useMemo } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  Plus, 
  AlertTriangle, 
  Calendar, 
  Waves, 
  ArrowLeft,
  Activity,
  TrendingDown,
  TrendingUp,
  Skull,
  ShieldCheck,
  Info,
  Bug,
  History,
  AlertCircle
} from 'lucide-react';
import Link from 'next/link';
import { toast } from 'react-hot-toast';
import { supabase } from '@/lib/supabase';

const causasMuerte = [
  'Bajo Oxígeno',
  'Depredación (Aves/Otras)',
  'Enfermedad (Bacteriana/Fúngica)',
  'Manipulación (Muestreo/Traslado)',
  'Causa Desconocida',
  'Parámetros Físico-Químicos'
];

export default function MortalidadPage() {
  const [fecha, setFecha] = useState(new Date().toISOString().split('T')[0]);
  const [estanqueId, setEstanqueId] = useState('');
  const [mortalidades, setMortalidades] = useState<any[]>([]);
  const [causa, setCausa] = useState(causasMuerte[0]);
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
      .from('mortalidad')
      .select('*, estanques(name)')
      .eq('unit_id', activeUnitId)
      .order('date', { ascending: false })
      .limit(10);
    
    if (data) {
      // Resolve species name for each record based on its batch_id
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

      // Also get from active pond_species
      const { data: activeSpecies } = await supabase
        .from('pond_species')
        .select('batch_id, species_name')
        .eq('unit_id', activeUnitId);
      
      activeSpecies?.forEach((s: any) => {
        if (s.batch_id) {
          batchMap[s.batch_id] = s.species_name;
        }
      });

      const resolvedHistory = data.map((h: any) => ({
        ...h,
        species_name: h.batch_id ? (batchMap[h.batch_id] || 'Especie') : 'Global'
      }));

      setHistory(resolvedHistory);
    }
  };

  const fetchPonds = async () => {
    const activeUnitId = localStorage.getItem('active_unit_id');
    const { data } = await supabase
      .from('estanques')
      .select('*')
      .eq('status', 'con_peces')
      .eq('unit_id', activeUnitId);
    setPonds(data || []);
  };

  const fetchSpecies = async (pondId: string) => {
    setLoading(true);
    const activeUnitId = localStorage.getItem('active_unit_id');
    const { data } = await supabase
      .from('pond_species')
      .select('*')
      .eq('estanque_id', pondId)
      .eq('unit_id', activeUnitId);

    if (data && data.length > 0) {
      setMortalidades(data.map((s: any) => ({
        speciesId: s.id,
        speciesName: s.species_name,
        batchId: s.batch_id,
        quantity: '',
        currentCount: s.current_count || 0
      })));
    } else {
      const p = ponds.find(p => p.id === pondId);
      setMortalidades([{
        speciesId: null,
        speciesName: p?.current_species && p.current_species !== 'Policultivo' ? p.current_species : '',
        batchId: p?.current_batch_id || null,
        quantity: '',
        currentCount: p?.current_count || 0
      }]);
    }
    setLoading(false);
  };

  useEffect(() => {
    if (estanqueId) {
      fetchSpecies(estanqueId);
    } else {
      setMortalidades([]);
    }
  }, [estanqueId, ponds]);

  const updateMortality = (index: number, field: string, value: string) => {
    const newMorts = [...mortalidades];
    newMorts[index] = { ...newMorts[index], [field]: value };
    setMortalidades(newMorts);
  };

  const handleRegisterMortalidad = async () => {
    try {
      const activeUnitId = localStorage.getItem('active_unit_id');
      if (!estanqueId || !activeUnitId) throw new Error("Seleccione un estanque");

      const registerPromise = async () => {
        let totalPondMortality = 0;
        const operations = mortalidades.map(async (mort) => {
          const qty = parseInt(mort.quantity) || 0;
          if (qty <= 0) return;
          if (qty > mort.currentCount) throw new Error(`Bajas exceden población de ${mort.speciesName || 'especie'}`);

          totalPondMortality += qty;
          const { error: mortError } = await supabase.from('mortalidad').insert([{
            estanque_id: estanqueId,
            unit_id: activeUnitId,
            batch_id: mort.batchId || null,
            date: fecha,
            quantity: qty,
            cause: causa
          }]);
          if (mortError) throw mortError;

          if (mort.speciesId) {
            await supabase.from('pond_species').update({ current_count: mort.currentCount - qty }).eq('id', mort.speciesId);
          }
        });

        await Promise.all(operations);
        const p = ponds.find(pond => pond.id === estanqueId);
        if (p) {
          await supabase.from('estanques').update({ current_count: (p.current_count || 0) - totalPondMortality }).eq('id', estanqueId);
        }
        return true;
      };

      toast.promise(registerPromise(), {
        loading: 'Procesando...',
        success: () => {
          setEstanqueId('');
          fetchPonds();
          fetchHistory();
          return "¡Mortalidad registrada!";
        },
        error: (err) => `Error: ${err.message}`
      });
    } catch (err: any) { toast.error(err.message); }
  };

  const metrics = useMemo(() => {
    const p = ponds.find(pond => pond.id === estanqueId);
    if (!p) return null;
    const totalMort = mortalidades.reduce((acc, curr) => acc + (parseInt(curr.quantity) || 0), 0);
    const populationActual = (p.current_count || 0) - totalMort;
    const mortalityRate = (totalMort / (p.current_count || 1)) * 100;
    const survivalRate = 100 - mortalityRate;
    const limit = (p.current_species || '').toLowerCase().includes('trucha') ? 10 : 5;
    let alertLevel = 'normal';
    if (mortalityRate > limit) alertLevel = 'critical';
    else if (mortalityRate > limit * 0.8) alertLevel = 'warning';

    return { populationActual, mortalityRate, survivalRate, alertLevel, limit, totalMort };
  }, [estanqueId, ponds, mortalidades]);

  return (
    <div className="animate-fade-in page-container" style={{ maxWidth: '1200px', margin: '0 auto' }}>
      <header style={{ marginBottom: '2.5rem', display: 'flex', alignItems: 'center', gap: '1.5rem' }}>
        <Link href="/registros" className="btn-secondary" style={{ width: '48px', height: '48px', borderRadius: '16px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <ArrowLeft size={24} />
        </Link>
        <div>
          <h1 style={{ fontSize: '2.2rem', fontWeight: 900, letterSpacing: '-0.02em' }}>Control de Mortalidad</h1>
          <p style={{ color: 'var(--muted-foreground)', fontSize: '1rem' }}>Gestión sanitaria y seguimiento de supervivencia por especie.</p>
        </div>
      </header>

      <div style={{ display: 'grid', gridTemplateColumns: '1.2fr 0.8fr', gap: '2.5rem' }}>
        <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
          <section className="card-premium" style={{ padding: '2rem' }}>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1.5rem', marginBottom: '2rem' }}>
              <div className="premium-input-group">
                <label className="premium-label">Estanque</label>
                <select value={estanqueId} onChange={(e) => setEstanqueId(e.target.value)} className="premium-input" style={{ fontWeight: 700 }}>
                  <option value="">Seleccionar Estanque...</option>
                  {ponds.map(p => <option key={p.id} value={p.id}>{p.name}</option>)}
                </select>
              </div>
              <div className="premium-input-group">
                <label className="premium-label">Fecha del Suceso</label>
                <input type="date" value={fecha} onChange={(e) => setFecha(e.target.value)} className="premium-input" />
              </div>
            </div>

            <div className="premium-input-group" style={{ marginBottom: '2.5rem' }}>
              <label className="premium-label">Causa Probable Detectada</label>
              <select value={causa} onChange={(e) => setCausa(e.target.value)} className="premium-input">
                {causasMuerte.map(c => <option key={c} value={c}>{c}</option>)}
              </select>
            </div>

            <AnimatePresence>
              {estanqueId && (
                <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '1.5rem' }}>
                    <Activity size={20} style={{ color: 'var(--primary)' }} />
                    <h3 style={{ fontSize: '1.1rem', fontWeight: 800 }}>Muestreo por Especie</h3>
                  </div>
                  
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                    {mortalidades.map((mort, idx) => (
                      <div key={idx} style={{ 
                        display: 'grid', 
                        gridTemplateColumns: '1fr 140px', 
                        gap: '1.5rem', 
                        alignItems: 'center',
                        padding: '1.25rem',
                        background: 'var(--secondary)',
                        borderRadius: '20px',
                        border: '1px solid var(--border)'
                      }}>
                        <div>
                          <div style={{ fontSize: '1rem', fontWeight: 800 }}>
                            {mort.speciesName}
                            {mort.batchId && (
                              <span style={{ 
                                fontSize: '0.75rem', 
                                opacity: 0.9, 
                                color: 'var(--primary)', 
                                background: 'rgba(59, 130, 246, 0.1)', 
                                border: '1px solid rgba(59, 130, 246, 0.2)', 
                                padding: '2px 8px', 
                                borderRadius: '6px', 
                                marginLeft: '0.5rem',
                                display: 'inline-block'
                              }}>
                                {mort.batchId}
                              </span>
                            )}
                          </div>
                          <div style={{ fontSize: '0.8rem', color: 'var(--muted-foreground)' }}>Población actual: <strong>{mort.currentCount.toLocaleString()}</strong></div>
                        </div>
                        <div className="premium-input-group">
                          <label className="premium-label" style={{ fontSize: '0.75rem', fontWeight: 800 }}>Bajas</label>
                          <input 
                            type="number" 
                            value={mort.quantity} 
                            onChange={(e) => updateMortality(idx, 'quantity', e.target.value)} 
                            className="premium-input" 
                            placeholder="0"
                            style={{ textAlign: 'center', fontSize: '1.2rem', fontWeight: 900, color: '#ef4444' }} 
                          />
                        </div>
                      </div>
                    ))}
                  </div>

                  <button 
                    onClick={handleRegisterMortalidad}
                    className="btn-primary"
                    style={{ 
                      width: '100%', 
                      marginTop: '2.5rem', 
                      padding: '1.25rem', 
                      borderRadius: '18px', 
                      background: '#ef4444', 
                      fontSize: '1.1rem',
                      boxShadow: '0 10px 25px -5px rgba(239, 68, 68, 0.4)'
                    }}
                  >
                    <Skull size={20} /> Registrar Bajas Sanitarias
                  </button>
                </motion.div>
              )}
            </AnimatePresence>
          </section>

          <section className="card-premium" style={{ padding: '2rem' }}>
            <h3 style={{ fontSize: '1.2rem', fontWeight: 900, marginBottom: '1.5rem', display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
              <History size={22} style={{ color: 'var(--primary)' }} /> Historial de Bajas
            </h3>
            <div style={{ overflowX: 'auto' }}>
              <table style={{ width: '100%', borderCollapse: 'separate', borderSpacing: '0 0.5rem' }}>
                <thead>
                  <tr style={{ color: 'var(--muted-foreground)', fontSize: '0.8rem', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                    <th style={{ textAlign: 'left', padding: '0.5rem 1rem' }}>Especie / Lote</th>
                    <th style={{ textAlign: 'center', padding: '0.5rem 1rem' }}>Bajas</th>
                    <th style={{ textAlign: 'left', padding: '0.5rem 1rem' }}>Causa</th>
                    <th style={{ textAlign: 'right', padding: '0.5rem 1rem' }}>Fecha</th>
                  </tr>
                </thead>
                <tbody>
                  {history.map(h => (
                    <tr key={h.id} style={{ background: 'var(--secondary)', borderRadius: '12px' }}>
                      <td style={{ padding: '1rem', fontWeight: 800, borderRadius: '12px 0 0 12px' }}>
                        <div>{h.species_name}</div>
                        {h.batch_id && (
                          <div style={{ fontSize: '0.75rem', color: 'var(--primary)', fontWeight: 500, marginTop: '2px' }}>
                            {h.batch_id}
                          </div>
                        )}
                      </td>
                      <td style={{ padding: '1rem', textAlign: 'center', color: '#ef4444', fontWeight: 900 }}>{h.quantity}</td>
                      <td style={{ padding: '1rem', fontSize: '0.85rem' }}>{h.cause}</td>
                      <td style={{ padding: '1rem', textAlign: 'right', fontSize: '0.8rem', color: 'var(--muted-foreground)', borderRadius: '0 12px 12px 0' }}>
                        {new Date(h.date).toLocaleDateString()}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </section>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
          <section className="card-premium" style={{ padding: '2.5rem', textAlign: 'center', position: 'sticky', top: '2rem' }}>
            <h3 style={{ fontSize: '0.9rem', fontWeight: 800, color: 'var(--muted-foreground)', textTransform: 'uppercase', letterSpacing: '0.1em', marginBottom: '2.5rem' }}>Indicador de Supervivencia</h3>
            
            <div style={{ position: 'relative', width: '220px', height: '220px', margin: '0 auto 2.5rem' }}>
              <svg viewBox="0 0 100 100" style={{ transform: 'rotate(-90deg)', width: '100%', height: '100%' }}>
                <circle cx="50" cy="50" r="45" fill="none" stroke="var(--secondary)" strokeWidth="8" />
                <motion.circle 
                  cx="50" cy="50" r="45" fill="none" 
                  stroke={metrics?.alertLevel === 'critical' ? '#ef4444' : '#10b981'} 
                  strokeWidth="8" 
                  strokeDasharray="283"
                  initial={{ strokeDashoffset: 283 }}
                  animate={{ strokeDashoffset: 283 - (283 * (metrics?.survivalRate || 100) / 100) }}
                  transition={{ duration: 1.5, ease: "easeOut" }}
                  strokeLinecap="round"
                />
              </svg>
              <div style={{ position: 'absolute', top: '50%', left: '50%', transform: 'translate(-50%, -50%)', textAlign: 'center' }}>
                <div style={{ fontSize: '3rem', fontWeight: 900, color: metrics?.alertLevel === 'critical' ? '#ef4444' : '#10b981', lineHeight: 1 }}>
                  {metrics ? Math.round(metrics.survivalRate) : '--'}<span style={{ fontSize: '1.2rem' }}>%</span>
                </div>
                <div style={{ fontSize: '0.7rem', fontWeight: 800, color: 'var(--muted-foreground)', textTransform: 'uppercase', marginTop: '0.5rem' }}>Supervivencia</div>
              </div>
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1.5rem', background: 'var(--secondary)', padding: '1.5rem', borderRadius: '24px' }}>
              <div style={{ textAlign: 'left' }}>
                <div style={{ fontSize: '0.7rem', color: 'var(--muted-foreground)', fontWeight: 800, textTransform: 'uppercase', marginBottom: '0.5rem' }}>Pob. Anterior</div>
                <div style={{ fontSize: '1.2rem', fontWeight: 900 }}>{metrics ? (metrics.populationActual + metrics.totalMort).toLocaleString() : '--'}</div>
              </div>
              <div style={{ textAlign: 'right' }}>
                <div style={{ fontSize: '0.7rem', color: 'var(--muted-foreground)', fontWeight: 800, textTransform: 'uppercase', marginBottom: '0.5rem' }}>Pob. Estimada</div>
                <div style={{ fontSize: '1.2rem', fontWeight: 900, color: 'var(--primary)' }}>{metrics ? metrics.populationActual.toLocaleString() : '--'}</div>
              </div>
            </div>

            {metrics && metrics.alertLevel !== 'normal' && (
              <motion.div 
                initial={{ opacity: 0, y: 20 }} 
                animate={{ opacity: 1, y: 0 }}
                style={{ 
                  marginTop: '2rem', 
                  padding: '1.5rem', 
                  borderRadius: '20px', 
                  background: metrics.alertLevel === 'critical' ? 'rgba(239, 68, 68, 0.1)' : 'rgba(245, 158, 11, 0.1)',
                  border: `1px solid ${metrics.alertLevel === 'critical' ? '#ef4444' : '#f59e0b'}`,
                  textAlign: 'left',
                  display: 'flex',
                  gap: '1rem'
                }}
              >
                <AlertCircle size={24} style={{ color: metrics.alertLevel === 'critical' ? '#ef4444' : '#f59e0b', flexShrink: 0 }} />
                <div>
                  <div style={{ fontWeight: 900, fontSize: '0.85rem', color: metrics.alertLevel === 'critical' ? '#ef4444' : '#f59e0b', textTransform: 'uppercase', marginBottom: '0.25rem' }}>Alerta de Sanidad</div>
                  <p style={{ fontSize: '0.85rem', lineHeight: 1.4, color: 'var(--muted-foreground)' }}>
                    La mortalidad ha superado el {metrics.limit}%. Revise parámetros y bioseguridad.
                  </p>
                </div>
              </motion.div>
            )}
          </section>
        </div>
      </div>
    </div>
  );
}
