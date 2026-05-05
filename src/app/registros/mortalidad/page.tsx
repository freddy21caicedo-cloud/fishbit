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
  Bug
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
  const [especieId, setEspecieId] = useState(''); // Note: Using species name directly from pond status for now
  const [cantidad, setCantidad] = useState('');
  const [causa, setCausa] = useState(causasMuerte[0]);
  const [ponds, setPonds] = useState<any[]>([]);
  const [pondSpecies, setPondSpecies] = useState<any[]>([]);
  const [loadingSpecies, setLoadingSpecies] = useState(false);

  useEffect(() => {
    fetchPonds();
  }, []);

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
    setLoadingSpecies(true);
    const { data } = await supabase.from('pond_species').select('*').eq('estanque_id', pondId);
    setPondSpecies(data || []);
    if (data && data.length > 0) {
      setEspecieId(data[0].species_name);
    } else {
      setEspecieId('');
    }
    setLoadingSpecies(false);
  };

  useEffect(() => {
    if (estanqueId) {
      const p = ponds.find(p => p.id === estanqueId);
      if (p?.is_polyculture) {
        fetchSpecies(estanqueId);
      } else {
        setEspecieId(p?.current_species || '');
        setPondSpecies([]);
      }
    }
  }, [estanqueId, ponds]);

  const selectedPond = useMemo(() => ponds.find(p => p.id === estanqueId), [ponds, estanqueId]);
  const selectedSpeciesData = useMemo(() => pondSpecies.find(s => s.species_name === especieId), [pondSpecies, especieId]);

  const handleRegisterMortalidad = async () => {
    if (!estanqueId || !cantidad || (selectedPond?.is_polyculture && !especieId)) {
      alert("Por favor complete los campos obligatorios.");
      return;
    }

    const qty = parseInt(cantidad);
    const maxQty = selectedPond?.is_polyculture 
      ? (selectedSpeciesData?.current_count || 0) 
      : (selectedPond?.current_count || 0);

    if (qty > maxQty) {
      alert(`La cantidad de bajas excede la población actual de ${especieId || 'el estanque'}.`);
      return;
    }

    const activeUnitId = localStorage.getItem('active_unit_id');
    if (!activeUnitId) return;

    // 1. Insert Mortality Record
    const { error: mortError } = await supabase.from('mortality').insert([{
      estanque_id: estanqueId,
      unit_id: activeUnitId,
      species_name: especieId,
      date: fecha,
      quantity: qty,
      cause: causa
    }]);

    if (mortError) {
      alert("Error al registrar mortalidad: " + mortError.message);
      return;
    }

    // 2. Update Pond Species Count (if polyculture)
    if (selectedPond?.is_polyculture && selectedSpeciesData) {
      await supabase
        .from('pond_species')
        .update({ 
          current_count: selectedSpeciesData.current_count - qty,
          updated_at: new Date().toISOString()
        })
        .eq('id', selectedSpeciesData.id);
    }

    // 3. Update Global Pond Count
    const { error: pondError } = await supabase
      .from('estanques')
      .update({ current_count: (selectedPond?.current_count || 0) - qty })
      .eq('id', estanqueId);

    if (pondError) {
      alert("Error al actualizar población global del estanque: " + pondError.message);
    } else {
      alert("¡Mortalidad registrada con éxito!");
      setCantidad('');
      fetchPonds();
      if (selectedPond?.is_polyculture) fetchSpecies(estanqueId);
    }
  };

  // Calculations
  const metrics = useMemo(() => {
    if (!selectedPond) return null;
    
    const count = parseInt(cantidad) || 0;
    // We don't have initial seeding count here easily, but let's assume current + mortality for rate
    // Actually, it's better to show real rate if we have it. For now, simple logic:
    const populationActual = selectedPond.current_count - count;
    const mortalityRate = (count / (selectedPond.current_count || 1)) * 100;
    const survivalRate = 100 - mortalityRate;

    // Parameterized thresholds
    const limit = (selectedPond.current_species || '').toLowerCase().includes('trucha') ? 10 : 5;
    
    let alertLevel = 'normal';
    if (mortalityRate > limit) alertLevel = 'critical';
    else if (mortalityRate > limit * 0.8) alertLevel = 'warning';

    return {
      populationActual,
      mortalityRate: mortalityRate.toFixed(2),
      survivalRate: survivalRate.toFixed(2),
      alertLevel,
      limit
    };
  }, [selectedPond, cantidad]);

  return (
    <div className="animate-fade-in" style={{ maxWidth: '1200px', margin: '0 auto', paddingBottom: '4rem' }}>
      <header style={{ marginBottom: '2.5rem', display: 'flex', alignItems: 'center', gap: '1rem' }}>
        <Link href="/registros" style={{ color: 'var(--muted-foreground)', display: 'flex', alignItems: 'center', justifyContent: 'center', width: '40px', height: '40px', borderRadius: '50%', background: 'var(--card)', border: '1px solid var(--border)' }}>
          <ArrowLeft size={20} />
        </Link>
        <div>
          <h1 style={{ fontSize: '1.875rem', fontWeight: 700 }}>Registro de Mortalidad</h1>
          <p style={{ color: 'var(--muted-foreground)' }}>Seguimiento de bajas y análisis de supervivencia.</p>
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
                    onChange={(e) => {
                      setEstanqueId(e.target.value);
                      setEspecieId('');
                    }}
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

            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '1.5rem', marginBottom: '2rem' }}>
              <div className="premium-input-group">
                <label className="premium-label">Especie Afectada</label>
                <div className="premium-input-wrapper">
                  <select 
                    value={especieId}
                    onChange={(e) => setEspecieId(e.target.value)}
                    disabled={!estanqueId}
                    style={{ width: '100%', background: 'transparent', border: 'none', outline: 'none', fontWeight: 700, opacity: !estanqueId ? 0.5 : 1 }}
                  >
                    <option value="">Seleccionar Especie...</option>
                    {selectedPond?.is_polyculture ? (
                      pondSpecies.map(s => <option key={s.id} value={s.species_name}>{s.species_name} ({s.current_count})</option>)
                    ) : (
                      selectedPond && <option value={selectedPond.current_species}>{selectedPond.current_species}</option>
                    )}
                  </select>
                </div>
              </div>
              <div className="premium-input-group">
                <label className="premium-label">Causa de la Baja</label>
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
            </div>

            <div style={{ marginBottom: '2.5rem' }}>
              <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 700, marginBottom: '0.5rem', textTransform: 'uppercase', color: 'var(--muted-foreground)' }}>Número de Individuos Muertos</label>
              <input 
                type="number" 
                value={cantidad}
                onChange={(e) => setCantidad(e.target.value)}
                placeholder="0"
                style={{ width: '100%', padding: '1rem', fontSize: '1.5rem', borderRadius: '12px', border: '1px solid var(--border)', background: 'var(--secondary)', outline: 'none', fontWeight: 800, color: '#ef4444' }} 
              />
            </div>

            <button 
              onClick={handleRegisterMortalidad}
              className="btn-primary" 
              style={{ width: '100%', padding: '1.25rem', borderRadius: '16px', background: '#ef4444', fontSize: '1.1rem', fontWeight: 800, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '0.75rem' }}
            >
              <Skull size={22} />
              Registrar Mortalidad
            </button>
          </div>

          {/* Critical Threshold Alert */}
          {metrics && metrics.alertLevel !== 'normal' && (
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
                <div style={{ fontSize: '0.7rem', color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Población Anterior ({selectedPond?.is_polyculture ? especieId : 'Total'})</div>
                <div style={{ fontWeight: 800 }}>{(selectedPond?.is_polyculture ? (selectedSpeciesData?.current_count || 0) : (selectedPond?.current_count || 0)).toLocaleString()}</div>
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
      </div>
    </div>
  );
}
