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
      .from('mortality')
      .select('*, estanques(name)')
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
      setMortalidades(data.map(s => ({
        speciesId: s.id,
        speciesName: s.species_name,
        quantity: '',
        currentCount: s.current_count || 0
      })));
    } else {
      const p = ponds.find(p => p.id === pondId);
      setMortalidades([{
        speciesId: null,
        speciesName: p?.current_species && p.current_species !== 'Policultivo' ? p.current_species : '',
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

  const addNewSpeciesRow = () => {
    setMortalidades([...mortalidades, {
      speciesId: null,
      speciesName: '',
      quantity: '',
      currentCount: 0
    }]);
  };

  const removeSpeciesRow = (index: number) => {
    if (mortalidades.length > 1) {
      const newMorts = [...mortalidades];
      newMorts.splice(index, 1);
      setMortalidades(newMorts);
    }
  };

  const updateMortality = (index: number, field: string, value: string) => {
    const newMorts = [...mortalidades];
    newMorts[index] = { ...newMorts[index], [field]: value };
    setMortalidades(newMorts);
  };

  const handleRegisterMortalidad = async () => {
    const activeUnitId = localStorage.getItem('active_unit_id');
    if (!estanqueId || !activeUnitId) return;

    setLoading(true);
    let totalPondMortality = 0;

    for (const mort of mortalidades) {
      const qty = parseInt(mort.quantity) || 0;
      if (qty <= 0) continue;

      if (qty > mort.currentCount) {
        alert(`La cantidad de bajas para ${mort.speciesName} excede la población actual.`);
        setLoading(false);
        return;
      }

      totalPondMortality += qty;

      // 1. Insert Mortality Record
      const { error: mortError } = await supabase.from('mortality').insert([{
        estanque_id: estanqueId,
        unit_id: activeUnitId,
        species_name: mort.speciesName,
        date: fecha,
        quantity: qty,
        cause: causa
      }]);

      if (mortError) {
        alert("Error al registrar mortalidad: " + mortError.message);
        continue;
      }

      // 2. Update Species Count if polyculture
      if (mort.speciesId) {
        await supabase
          .from('pond_species')
          .update({ current_count: mort.currentCount - qty })
          .eq('id', mort.speciesId);
      }
    }

    // 3. Update Global Pond Count
    const p = ponds.find(pond => pond.id === estanqueId);
    if (p) {
      await supabase
        .from('estanques')
        .update({ current_count: (p.current_count || 0) - totalPondMortality })
        .eq('id', estanqueId);
    }

    alert("¡Registro de mortalidad procesado con éxito!");
    setLoading(false);
    fetchPonds();
    setEstanqueId('');
  };

  // Calculations
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

    return {
      populationActual,
      mortalityRate: mortalityRate.toFixed(2),
      survivalRate: survivalRate.toFixed(2),
      alertLevel,
      limit,
      totalMort
    };
  }, [estanqueId, ponds, mortalidades]);

  return (
    <div className="animate-fade-in" style={{ maxWidth: '1200px', margin: '0 auto', paddingBottom: '4rem' }}>
      <header style={{ marginBottom: '2.5rem', display: 'flex', alignItems: 'center', gap: '1rem' }}>
        <Link href="/registros" style={{ color: 'var(--muted-foreground)', display: 'flex', alignItems: 'center', justifyContent: 'center', width: '40px', height: '40px', borderRadius: '50%', background: 'var(--card)', border: '1px solid var(--border)' }}>
          <ArrowLeft size={20} />
        </Link>
        <div>
          <h1 style={{ fontSize: '1.875rem', fontWeight: 700 }}>Registro de Mortalidad</h1>
          <p style={{ color: 'var(--muted-foreground)' }}>Seguimiento de bajas y análisis de supervivencia por especie.</p>
        </div>
      </header>

      <div className="responsive-container">
        {/* Main Form Section */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem', flex: 1.5 }}>
          <div className="card-premium" style={{ padding: 'clamp(1.5rem, 5vw, 2.5rem)' }}>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '1.5rem', marginBottom: '2rem' }}>
              <div className="premium-input-group">
                <label className="premium-label">
                  <Waves size={14} /> Estanque
                </label>
                <div className="premium-input-wrapper">
                  <select 
                    value={estanqueId}
                    onChange={(e) => setEstanqueId(e.target.value)}
                    style={{ width: '100%', background: 'transparent', border: 'none', outline: 'none', fontWeight: 700 }}
                  >
                    <option value="">Seleccionar Estanque...</option>
                    {ponds.map(p => <option key={p.id} value={p.id}>{p.name} {p.is_polyculture ? '(Policultivo)' : ''}</option>)}
                  </select>
                </div>
              </div>
              
              <div className="premium-input-group">
                <label className="premium-label">
                  <Calendar size={14} /> Fecha de Registro
                </label>
                <div className="premium-input-wrapper">
                  <input 
                    type="date" 
                    value={fecha} 
                    onChange={(e) => setFecha(e.target.value)} 
                    className="premium-date-input"
                  />
                </div>
              </div>
            </div>

            <div className="premium-input-group" style={{ marginBottom: '2rem' }}>
              <label className="premium-label">Causa General de la Baja</label>
              <div className="premium-input-wrapper">
                <select 
                  value={causa}
                  onChange={(e) => setCausa(e.target.value)}
                  style={{ width: '100%', background: 'transparent', border: 'none', outline: 'none', fontWeight: 700 }}
                >
                  {causasMuerte.map(c => <option key={c} value={c}>{c}</option>)}
                </select>
              </div>
            </div>

            <AnimatePresence>
              {estanqueId && (
                <motion.div 
                  initial={{ opacity: 0, height: 0 }}
                  animate={{ opacity: 1, height: 'auto' }}
                  exit={{ opacity: 0, height: 0 }}
                >
                  <h3 style={{ fontSize: '0.85rem', fontWeight: 800, color: 'var(--muted-foreground)', textTransform: 'uppercase', marginBottom: '1rem', borderTop: '1px solid var(--border)', paddingTop: '1.5rem' }}>Especies en Estanque</h3>
                  
                  {ponds.find(p => p.id === estanqueId)?.is_polyculture && mortalidades.some(m => !m.speciesId) && (
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
                        <strong>Aviso:</strong> No hay desglose de especies para este policultivo. Puede definirlas a continuación o en Siembra.
                      </div>
                    </div>
                  )}

                  <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem', marginBottom: '2.5rem' }}>
                    {mortalidades.map((mort, index) => (
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
                        {mortalidades.length > 1 && (
                          <button 
                            onClick={() => removeSpeciesRow(index)}
                            style={{ position: 'absolute', top: '0.5rem', right: '0.5rem', color: '#ef4444', background: 'none', border: 'none', cursor: 'pointer', fontSize: '0.65rem', fontWeight: 800 }}
                          >
                            X
                          </button>
                        )}
                        <div>
                          {mort.speciesId ? (
                            <div style={{ fontWeight: 800, fontSize: '0.95rem' }}>{mort.speciesName}</div>
                          ) : (
                            <input 
                              type="text"
                              value={mort.speciesName}
                              onChange={(e) => updateMortality(index, 'speciesName', e.target.value)}
                              placeholder="Nombre Especie"
                              style={{ width: '100%', padding: '0.4rem', borderRadius: '6px', border: '1px solid var(--border)', fontSize: '0.85rem', fontWeight: 700 }}
                            />
                          )}
                          <div style={{ fontSize: '0.75rem', color: 'var(--muted-foreground)' }}>Pob. actual: {mort.currentCount.toLocaleString()}</div>
                        </div>
                        <div>
                          <div style={{ fontSize: '0.65rem', fontWeight: 700, color: 'var(--muted-foreground)', textTransform: 'uppercase', marginBottom: '0.25rem' }}>Bajas</div>
                          <input 
                            type="number" 
                            value={mort.quantity}
                            onChange={(e) => updateMortality(index, 'quantity', e.target.value)}
                            placeholder="0"
                            style={{ width: '100%', padding: '0.5rem', borderRadius: '8px', border: '1px solid var(--border)', background: 'white', outline: 'none', fontWeight: 800 }}
                          />
                        </div>
                        <div style={{ textAlign: 'center' }}>
                          <div style={{ fontSize: '0.65rem', fontWeight: 700, color: 'var(--muted-foreground)', textTransform: 'uppercase', marginBottom: '0.25rem' }}>Quedan</div>
                          <div style={{ fontWeight: 800, color: 'var(--primary)' }}>
                            {(mort.currentCount - (parseInt(mort.quantity) || 0)).toLocaleString()}
                          </div>
                        </div>
                      </div>
                    ))}

                    {ponds.find(p => p.id === estanqueId)?.is_polyculture && (
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
                        <Plus size={14} /> Agregar otra especie al registro
                      </button>
                    )}
                  </div>

                  <button 
                    onClick={handleRegisterMortalidad}
                    disabled={loading || mortalidades.every(m => !m.quantity || parseInt(m.quantity) <= 0)}
                    className="btn-primary" 
                    style={{ width: '100%', padding: '1.25rem', borderRadius: '16px', background: '#ef4444', fontSize: '1.1rem', fontWeight: 800, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '0.75rem', opacity: (loading || mortalidades.every(m => !m.quantity || parseInt(m.quantity) <= 0)) ? 0.6 : 1 }}
                  >
                    {loading ? <Activity className="animate-spin" size={22} /> : <Skull size={22} />}
                    Registrar Bajas Seleccionadas
                  </button>
                </motion.div>
              )}
            </AnimatePresence>
          </div>

          {/* Critical Threshold Alert */}
          {metrics && metrics.alertLevel !== 'normal' && metrics.totalMort > 0 && (
            <motion.div 
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              style={{ 
                padding: '1.5rem', 
                borderRadius: '20px', 
                background: metrics.alertLevel === 'critical' ? 'rgba(239, 68, 68, 0.1)' : 'rgba(245, 158, 11, 0.1)', 
                border: '1px solid',
                borderColor: metrics.alertLevel === 'critical' ? '#ef4444' : '#f59e0b',
                display: 'flex', 
                gap: '1.25rem', 
                alignItems: 'center'
              }}
            >
              <div style={{ 
                width: '48px', 
                height: '48px', 
                borderRadius: '12px', 
                background: metrics.alertLevel === 'critical' ? '#ef4444' : '#f59e0b', 
                display: 'flex', 
                alignItems: 'center', 
                justifyContent: 'center',
                color: 'white'
              }}>
                <AlertTriangle size={28} />
              </div>
              <div>
                <h4 style={{ fontWeight: 800, color: metrics.alertLevel === 'critical' ? '#991b1b' : '#92400e', marginBottom: '0.2rem' }}>
                  ALERTA SANITARIA: UMBRAL EXCEDIDO
                </h4>
                <p style={{ fontSize: '0.85rem', color: 'var(--muted-foreground)', lineHeight: 1.5 }}>
                  La mortalidad acumulada ({metrics.mortalityRate}%) ha superado el límite técnico permitido para esta especie ({metrics.limit}%). Se recomienda una auditoría inmediata.
                </p>
              </div>
            </motion.div>
          )}
        </div>

        {/* Survival Metrics Sidebar */}
        <div className="responsive-side-panel" style={{ display: 'flex', flexDirection: 'column', gap: '2rem', flex: 1 }}>
          {/* Survival Rate Card */}
          <div className="card-premium" style={{ padding: '2rem', textAlign: 'center' }}>
            <h3 style={{ fontSize: '0.85rem', fontWeight: 700, color: 'var(--muted-foreground)', textTransform: 'uppercase', marginBottom: '1.5rem' }}>Tasa de Supervivencia</h3>
            
            <div style={{ position: 'relative', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', marginBottom: '1.5rem' }}>
              <div style={{ 
                width: '150px', 
                height: '150px', 
                borderRadius: '50%', 
                border: '12px solid #f1f5f9',
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                justifyContent: 'center'
              }}>
                <div style={{ fontSize: '2.5rem', fontWeight: 900, color: '#10b981' }}>
                  {metrics ? `${metrics.survivalRate}%` : '--'}
                </div>
              </div>
              {/* Progress Ring logic would go here in SVG */}
            </div>

            <div style={{ display: 'flex', justifyContent: 'space-between', padding: '1rem', background: 'var(--secondary)', borderRadius: '12px' }}>
              <div style={{ textAlign: 'left' }}>
                <div style={{ fontSize: '0.7rem', color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Población Anterior</div>
                <div style={{ fontWeight: 800 }}>{(ponds.find(p => p.id === estanqueId)?.current_count || 0).toLocaleString()}</div>
              </div>
              <div style={{ textAlign: 'right' }}>
                <div style={{ fontSize: '0.7rem', color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Población Proyectada</div>
                <div style={{ fontWeight: 800, color: '#3b82f6' }}>{metrics?.populationActual.toLocaleString() || '--'}</div>
              </div>
            </div>
          </div>

          {/* Mortality Stats Card */}
          <div className="card-premium" style={{ padding: '2rem' }}>
            <h3 style={{ fontSize: '0.85rem', fontWeight: 700, color: 'var(--muted-foreground)', textTransform: 'uppercase', marginBottom: '1.5rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <TrendingDown size={18} style={{ color: '#ef4444' }} /> Impacto de Bajas
            </h3>
            
            <div style={{ marginBottom: '1.5rem' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.85rem', marginBottom: '0.5rem' }}>
                <span>Mortalidad Acumulada</span>
                <span style={{ fontWeight: 800, color: '#ef4444' }}>{metrics ? `${metrics.mortalityRate}%` : '--'}</span>
              </div>
              <div style={{ width: '100%', height: '8px', background: 'var(--secondary)', borderRadius: '4px', overflow: 'hidden' }}>
                <motion.div 
                  initial={{ width: 0 }}
                  animate={{ width: metrics ? `${metrics.mortalityRate}%` : 0 }}
                  style={{ height: '100%', background: '#ef4444' }}
                />
              </div>
            </div>

            <div style={{ display: 'flex', gap: '1rem', alignItems: 'center', padding: '1rem', background: 'rgba(239, 68, 68, 0.05)', borderRadius: '12px', border: '1px solid rgba(239, 68, 68, 0.1)' }}>
              <Bug size={20} style={{ color: '#ef4444' }} />
              <div style={{ fontSize: '0.8rem', color: 'var(--muted-foreground)' }}>
                <strong>Causa Principal:</strong><br />
                {causa}
              </div>
            </div>
          </div>

          {/* Quick Recommendation */}
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
              Un registro oportuno de bajas permite detectar brotes de enfermedades en etapas tempranas.
            </p>
          </div>
        </div>

        {/* Full Width History Table */}
        <div style={{ gridColumn: '1 / -1', marginTop: '3rem' }}>
          <div className="card-premium" style={{ padding: '2rem' }}>
            <h3 style={{ fontSize: '1.1rem', fontWeight: 800, marginBottom: '1.5rem', display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
              <History size={20} style={{ color: 'var(--primary)' }} />
              Historial de Bajas Recientes
            </h3>
            
            <div style={{ overflowX: 'auto' }}>
              <table style={{ width: '100%', borderCollapse: 'collapse', minWidth: '600px' }}>
                <thead>
                  <tr style={{ borderBottom: '2px solid var(--border)' }}>
                    <th style={{ textAlign: 'left', padding: '1rem', fontSize: '0.8rem', color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Especie</th>
                    <th style={{ textAlign: 'left', padding: '1rem', fontSize: '0.8rem', color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Cantidad</th>
                    <th style={{ textAlign: 'left', padding: '1rem', fontSize: '0.8rem', color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Estanque</th>
                    <th style={{ textAlign: 'left', padding: '1rem', fontSize: '0.8rem', color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Fecha</th>
                  </tr>
                </thead>
                <tbody>
                  {history.map((h) => (
                    <tr key={h.id} style={{ borderBottom: '1px solid var(--border)' }}>
                      <td style={{ padding: '1rem', fontWeight: 700 }}>{h.species_name}</td>
                      <td style={{ padding: '1rem', fontWeight: 800, color: '#ef4444' }}>{h.quantity}</td>
                      <td style={{ padding: '1rem' }}>
                        <span style={{ padding: '0.25rem 0.6rem', background: 'var(--secondary)', borderRadius: '6px', fontSize: '0.85rem', fontWeight: 600 }}>
                          {h.estanques?.name}
                        </span>
                      </td>
                      <td style={{ padding: '1rem', fontSize: '0.85rem', color: 'var(--muted-foreground)' }}>
                        {new Date(h.date).toLocaleDateString()}
                      </td>
                    </tr>
                  ))}
                  {history.length === 0 && (
                    <tr>
                      <td colSpan={4} style={{ padding: '3rem', textAlign: 'center', color: 'var(--muted-foreground)' }}>No hay registros recientes.</td>
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
