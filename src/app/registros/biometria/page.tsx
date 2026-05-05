'use client';
import { useEffect, useState, useMemo } from 'react';
import { 
  Calendar, 
  Waves, 
  Scale, 
  Plus, 
  ArrowLeft, 
  Activity, 
  TrendingUp, 
  Info,
  History,
  AlertCircle
} from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import Link from 'next/link';
import { useSearchParams } from 'next/navigation';
import { supabase } from '@/lib/supabase';

export default function BiometriaPage() {
  const searchParams = useSearchParams();
  const estanqueParam = searchParams.get('estanque');

  const [fecha, setFecha] = useState(new Date().toISOString().split('T')[0]);
  const [estanqueId, setEstanqueId] = useState(estanqueParam || '');
  const [estanquesList, setEstanquesList] = useState<any[]>([]);
  const [biometrias, setBiometrias] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);

  const [history, setHistory] = useState<any[]>([]);

  useEffect(() => {
    fetchEstanques();
    fetchHistory();
  }, []);

  const fetchHistory = async () => {
    const activeUnitId = localStorage.getItem('active_unit_id');
    if (!activeUnitId) return;

    const { data } = await supabase
      .from('biometria')
      .select('*, estanques(name)')
      .eq('unit_id', activeUnitId)
      .order('date', { ascending: false })
      .limit(10);
    
    if (data) setHistory(data);
  };

  const fetchEstanques = async () => {
    const activeUnitId = localStorage.getItem('active_unit_id');
    const { data, error } = await supabase
      .from('estanques')
      .select('*')
      .eq('status', 'con_peces')
      .eq('unit_id', activeUnitId);
    if (error) console.error('Error fetching estanques:', error);
    else setEstanquesList(data || []);
  };

  const selectedPond = estanquesList.find(p => p.id === estanqueId);

  // Update rows when pond changes
  useEffect(() => {
    if (selectedPond) {
      if (selectedPond.is_polyculture) {
        fetchPondSpecies(selectedPond.id);
      } else {
        setBiometrias([{
          speciesName: selectedPond.current_species || 'Desconocida',
          pesoCaptura: '',
          pecesCapturados: '',
          poblacionTotal: selectedPond.current_count || 0,
          biomasaInicial: parseFloat(selectedPond.current_biomass_kg) || 0
        }]);
      }
    } else {
      setBiometrias([]);
    }
  }, [estanqueId, selectedPond]);

  const fetchPondSpecies = async (pondId: string) => {
    setLoading(true);
    const activeUnitId = localStorage.getItem('active_unit_id');
    const { data } = await supabase
      .from('pond_species')
      .select('*')
      .eq('estanque_id', pondId)
      .eq('unit_id', activeUnitId);

    if (data && data.length > 0) {
      setBiometrias(data.map(s => ({
        speciesName: s.species_name,
        speciesId: s.id,
        pesoCaptura: '',
        pecesCapturados: '',
        poblacionTotal: s.current_count || 0,
        biomasaInicial: parseFloat(s.current_biomass_kg) || 0
      })));
    } else {
      const pond = estanquesList.find(p => p.id === pondId);
      if (pond?.is_polyculture) {
        // Warning: No species details found for a polyculture pond
        console.warn("No se encontraron detalles de especies para este policultivo.");
      }
      setBiometrias([{
        speciesName: pond?.current_species && pond.current_species !== 'Policultivo' ? pond.current_species : '',
        speciesId: null,
        pesoCaptura: '',
        pecesCapturados: '',
        poblacionTotal: pond?.current_count || 0,
        biomasaInicial: parseFloat(pond?.current_biomass_kg) || 0
      }]);
    }
    setLoading(false);
  };

  const addNewSpeciesRow = () => {
    setBiometrias([...biometrias, {
      speciesName: '',
      speciesId: null,
      pesoCaptura: '',
      pecesCapturados: '',
      poblacionTotal: 0,
      biomasaInicial: 0
    }]);
  };

  const removeSpeciesRow = (index: number) => {
    if (biometrias.length > 1) {
      const newBios = [...biometrias];
      newBios.splice(index, 1);
      setBiometrias(newBios);
    }
  };

  const updateBiometria = (index: number, field: string, value: string) => {
    const newBiometrias = [...biometrias];
    newBiometrias[index] = { ...newBiometrias[index], [field]: value };
    setBiometrias(newBiometrias);
  };

  const handleRegisterBiometria = async () => {
    if (!estanqueId || biometrias.length === 0) return;

    setLoading(true);
    const activeUnitId = localStorage.getItem('active_unit_id');
    let totalPondBiomass = 0;

    for (let i = 0; i < biometrias.length; i++) {
      const bio = totals[i];
      const raw = biometrias[i];
      const avgWeight = parseFloat(bio.pesoPromedio);
      const totalBio = parseFloat(bio.biomasaActual);
      totalPondBiomass += totalBio;

      // 1. Insert record
      const { error: bioError } = await supabase.from('biometria').insert([{
        estanque_id: estanqueId,
        unit_id: activeUnitId,
        species_name: raw.speciesName,
        date: fecha,
        avg_weight_gr: avgWeight,
        average_weight_g: avgWeight, // Keep both for compatibility
        total_biomass_kg: totalBio
      }]);

      if (bioError) {
        alert(`Error al registrar biometría para ${raw.speciesName}: ${bioError.message}`);
        continue;
      }

      // 2. Update or Create Species Record
      if (raw.speciesId) {
        await supabase
          .from('pond_species')
          .update({
            current_biomass_kg: totalBio,
            avg_weight_gr: avgWeight,
            updated_at: new Date().toISOString()
          })
          .eq('id', raw.speciesId);
      } else if (raw.speciesName) {
        // If it's a new species name, create it in pond_species
        await supabase.from('pond_species').insert([{
          estanque_id: estanqueId,
          unit_id: activeUnitId,
          species_name: raw.speciesName,
          current_count: raw.poblacionTotal,
          current_biomass_kg: totalBio,
          avg_weight_gr: avgWeight
        }]);
      }
    }

    // 3. Update Pond Status (Total Biomass)
    await supabase
      .from('estanques')
      .update({
        current_biomass_kg: totalPondBiomass
      })
      .eq('id', estanqueId);

    alert("¡Biometría registrada con éxito! Los datos han sido actualizados.");
    setLoading(false);
    fetchEstanques();
    fetchHistory();
  };


  const totals = useMemo(() => {
    return biometrias.map(b => {
      const pCaptura = parseFloat(b.pesoCaptura) || 0;
      const nCaptura = parseFloat(b.pecesCapturados) || 0;
      const pesoPromedioKg = nCaptura > 0 ? (pCaptura / nCaptura) : 0;
      const pesoPromedioGramos = pesoPromedioKg * 1000;
      const biomasaActualKg = b.poblacionTotal * pesoPromedioKg;

      return {
        ...b,
        pesoPromedio: pesoPromedioGramos.toFixed(1),
        biomasaActual: biomasaActualKg.toFixed(1)
      };
    });
  }, [biometrias]);

  const biomasaTotalActual = totals.reduce((acc, curr) => acc + parseFloat(curr.biomasaActual), 0);
  const biomasaTotalInicial = biometrias.reduce((acc, curr) => acc + curr.biomasaInicial, 0);

  return (
    <div className="animate-fade-in" style={{ maxWidth: '1200px', margin: '0 auto', paddingBottom: '4rem' }}>
      <header style={{ marginBottom: '2.5rem', display: 'flex', alignItems: 'center', gap: '1rem' }}>
        <Link href="/registros" style={{ color: 'var(--muted-foreground)', display: 'flex', alignItems: 'center', justifyContent: 'center', width: '40px', height: '40px', borderRadius: '50%', background: 'var(--card)', border: '1px solid var(--border)' }}>
          <ArrowLeft size={20} />
        </Link>
        <div>
          <h1 style={{ fontSize: '1.875rem', fontWeight: 700 }}>Registro de Biometría</h1>
          <p style={{ color: 'var(--muted-foreground)' }}>Muestreo de pesos y control de crecimiento biológico.</p>
        </div>
      </header>

      <div className="responsive-container">
        <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem', flex: 1.5 }}>
          {/* Header Form */}
          <div className="card-premium" style={{ padding: '2rem', display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '2rem' }}>
            <div className="premium-input-group">
              <label className="premium-label">
                <Calendar size={14} /> Fecha de Muestreo
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
            <div className="premium-input-group">
              <label className="premium-label">
                <Waves size={14} /> Seleccionar Estanque
              </label>
              <div className="premium-input-wrapper">
                <select 
                  value={estanqueId}
                  onChange={(e) => setEstanqueId(e.target.value)}
                  style={{ width: '100%', background: 'transparent', border: 'none', outline: 'none', fontWeight: 700 }}
                >
                  <option value="">-- Seleccionar --</option>
                  {estanquesList.map(p => <option key={p.id} value={p.id}>{p.name} {p.is_polyculture ? '(Policultivo)' : ''}</option>)}
                </select>
              </div>
            </div>
          </div>

          {/* Biometry Table Section */}
          <AnimatePresence mode="wait">
            {estanqueId ? (
              <motion.div 
                key={estanqueId}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -20 }}
                className="card-premium" 
                style={{ padding: '2rem' }}
              >
                <h2 style={{ fontSize: '1.1rem', fontWeight: 700, marginBottom: '1.5rem', display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                  <Scale size={20} style={{ color: '#8b5cf6' }} />
                  Detalle de Población Cultivada
                </h2>

                {/* Species Inventory Summary */}
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(200px, 1fr))', gap: '1rem', marginBottom: '2.5rem' }}>
                  {biometrias.map((bio, idx) => (
                    <div key={idx} style={{ padding: '1rem', borderRadius: '12px', background: 'rgba(139, 92, 246, 0.05)', border: '1px solid rgba(139, 92, 246, 0.1)' }}>
                      <div style={{ fontSize: '0.65rem', fontWeight: 800, color: '#8b5cf6', textTransform: 'uppercase', marginBottom: '0.5rem' }}>{bio.speciesName}</div>
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                        <div>
                          <div style={{ fontSize: '1rem', fontWeight: 800 }}>{bio.poblacionTotal.toLocaleString()}</div>
                          <div style={{ fontSize: '0.65rem', color: 'var(--muted-foreground)' }}>Individuos</div>
                        </div>
                        <div style={{ textAlign: 'right' }}>
                          <div style={{ fontSize: '1rem', fontWeight: 800 }}>{bio.biomasaInicial.toLocaleString()} kg</div>
                          <div style={{ fontSize: '0.65rem', color: 'var(--muted-foreground)' }}>Biomasa Act.</div>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>

                <h2 style={{ fontSize: '1.1rem', fontWeight: 700, marginBottom: '1.5rem', display: 'flex', alignItems: 'center', gap: '0.75rem', borderTop: '1px solid var(--border)', paddingTop: '1.5rem' }}>
                  <Activity size={20} style={{ color: 'var(--primary)' }} />
                  Nuevos Datos de Captura (Muestreo)
                </h2>

                <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
                  {selectedPond?.is_polyculture && biometrias.some(b => !b.speciesId) && (
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
                        <strong>Aviso:</strong> No encontramos el desglose de especies para este policultivo. Puede definirlas a continuación o revisarlas en el módulo de Siembra.
                      </div>
                    </div>
                  )}
                  {totals.map((bio, index) => (
                    <div key={index} style={{ 
                      padding: '1.5rem', 
                      background: 'var(--secondary)', 
                      borderRadius: '16px', 
                      border: '1px solid var(--border)',
                      display: 'grid',
                      gridTemplateColumns: 'repeat(auto-fit, minmax(140px, 1fr))',
                      gap: '1.5rem',
                      alignItems: 'center',
                      position: 'relative'
                    }}>
                      {biometrias.length > 1 && (
                        <button 
                          onClick={() => removeSpeciesRow(index)}
                          style={{ position: 'absolute', top: '1rem', right: '1rem', color: '#ef4444', background: 'none', border: 'none', cursor: 'pointer', fontSize: '0.7rem', fontWeight: 800 }}
                        >
                          Eliminar
                        </button>
                      )}
                      
                      <div>
                        <div style={{ fontSize: '0.7rem', fontWeight: 700, color: '#8b5cf6', textTransform: 'uppercase', marginBottom: '0.25rem' }}>Especie</div>
                        {bio.speciesId ? (
                          <div style={{ fontWeight: 800, fontSize: '1rem', color: 'var(--foreground)' }}>{bio.speciesName}</div>
                        ) : (
                          <input 
                            type="text"
                            value={bio.speciesName}
                            onChange={(e) => updateBiometria(index, 'speciesName', e.target.value)}
                            placeholder="Nombre de Especie"
                            style={{ width: '100%', padding: '0.4rem', borderRadius: '6px', border: '1px solid var(--border)', fontSize: '0.9rem', fontWeight: 700 }}
                          />
                        )}
                        <div style={{ fontSize: '0.75rem', color: 'var(--muted-foreground)', marginTop: '0.25rem' }}>
                          Pob: {bio.poblacionTotal?.toLocaleString() || '0'}
                        </div>
                      </div>
                      
                      <div>
                        <label style={{ display: 'block', fontSize: '0.7rem', fontWeight: 700, color: 'var(--muted-foreground)', marginBottom: '0.4rem', textTransform: 'uppercase' }}>Peso Captura (kg)</label>
                        <input 
                          type="number" 
                          value={bio.pesoCaptura}
                          onChange={(e) => updateBiometria(index, 'pesoCaptura', e.target.value)}
                          placeholder="0.00"
                          style={{ width: '100%', padding: '0.6rem', borderRadius: '8px', border: '1px solid var(--border)', background: 'white', outline: 'none', fontWeight: 700 }}
                        />
                      </div>

                      <div>
                        <label style={{ display: 'block', fontSize: '0.7rem', fontWeight: 700, color: 'var(--muted-foreground)', marginBottom: '0.4rem', textTransform: 'uppercase' }}>Peces Capturados</label>
                        <input 
                          type="number" 
                          value={bio.pecesCapturados}
                          onChange={(e) => updateBiometria(index, 'pecesCapturados', e.target.value)}
                          placeholder="0"
                          style={{ width: '100%', padding: '0.6rem', borderRadius: '8px', border: '1px solid var(--border)', background: 'white', outline: 'none', fontWeight: 700 }}
                        />
                      </div>

                      <div style={{ background: 'white', padding: '0.75rem', borderRadius: '10px', border: '1px solid var(--border)', textAlign: 'center' }}>
                        <div style={{ fontSize: '0.65rem', fontWeight: 700, color: 'var(--muted-foreground)', textTransform: 'uppercase', marginBottom: '0.1rem' }}>Peso Promedio</div>
                        <div style={{ fontSize: '1.1rem', fontWeight: 900, color: '#8b5cf6' }}>{bio.pesoPromedio} <span style={{ fontSize: '0.7rem' }}>g</span></div>
                      </div>
                    </div>
                  ))}

                  {selectedPond?.is_polyculture && (
                    <button 
                      onClick={addNewSpeciesRow}
                      style={{ 
                        width: '100%', 
                        padding: '1rem', 
                        borderRadius: '12px', 
                        border: '2px dashed var(--border)', 
                        background: 'none', 
                        color: 'var(--muted-foreground)', 
                        fontWeight: 700, 
                        cursor: 'pointer',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        gap: '0.5rem'
                      }}
                    >
                      <Plus size={16} /> Agregar otra especie al muestreo
                    </button>
                  )}
                </div>

                <div style={{ marginTop: '2.5rem', paddingTop: '2rem', borderTop: '1px solid var(--border)' }}>
                  <button 
                    onClick={handleRegisterBiometria}
                    className="btn-primary" 
                    style={{ width: '100%', padding: '1.25rem', borderRadius: '16px', background: '#8b5cf6', fontSize: '1.1rem', fontWeight: 800, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '0.75rem' }}
                  >
                    <Plus size={22} />
                    Guardar Registro de Biometría
                  </button>
                </div>
              </motion.div>
            ) : null}
          </AnimatePresence>
        </div>

        {/* Sidebar Summary */}
        <div className="responsive-side-panel" style={{ display: 'flex', flexDirection: 'column', gap: '2rem', flex: 1 }}>
          {/* Biomass Stats Card */}
          <div className="card-premium" style={{ padding: '2rem', background: 'linear-gradient(135deg, #ffffff 0%, #f9fafb 100%)' }}>
            <h3 style={{ fontSize: '0.85rem', fontWeight: 700, color: 'var(--muted-foreground)', textTransform: 'uppercase', marginBottom: '1.5rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <Activity size={18} style={{ color: '#8b5cf6' }} /> Análisis de Carga
            </h3>
            
            <div style={{ marginBottom: '2rem' }}>
              <div style={{ fontSize: '0.75rem', color: 'var(--muted-foreground)', marginBottom: '0.25rem' }}>Biomasa Inicial (Siembra)</div>
              <div style={{ fontSize: '1.5rem', fontWeight: 800, color: 'var(--foreground)' }}>{estanqueId ? biomasaTotalInicial.toFixed(1) : '--'} <span style={{ fontSize: '0.8rem' }}>kg</span></div>
            </div>

            <div style={{ marginBottom: '2rem' }}>
              <div style={{ fontSize: '0.75rem', color: 'var(--muted-foreground)', marginBottom: '0.25rem' }}>Biomasa Actual Proyectada</div>
              <motion.div 
                key={biomasaTotalActual}
                initial={{ scale: 1 }}
                animate={{ scale: [1, 1.05, 1] }}
                style={{ fontSize: '2.25rem', fontWeight: 900, color: '#8b5cf6' }}
              >
                {estanqueId ? biomasaTotalActual.toFixed(1) : '--'} <span style={{ fontSize: '1rem' }}>kg</span>
              </motion.div>
            </div>

            <div style={{ padding: '1rem', background: 'rgba(139, 92, 246, 0.05)', borderRadius: '12px', border: '1px solid rgba(139, 92, 246, 0.1)' }}>
              <div style={{ fontSize: '0.7rem', fontWeight: 700, color: '#8b5cf6', textTransform: 'uppercase', marginBottom: '0.25rem' }}>Incremento de Biomasa</div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', fontWeight: 800, fontSize: '1.1rem', color: '#10b981' }}>
                <TrendingUp size={18} />
                +{estanqueId ? (biomasaTotalActual - biomasaTotalInicial).toFixed(1) : '0'} kg
              </div>
            </div>
          </div>

          {/* Technical Info Card */}
          <div style={{ 
            padding: '1.5rem', 
            borderRadius: '20px', 
            background: 'var(--card)', 
            border: '1px solid var(--border)',
            display: 'flex', 
            gap: '1rem'
          }}>
            <Info size={20} style={{ color: 'var(--primary)', flexShrink: 0 }} />
            <p style={{ fontSize: '0.85rem', color: 'var(--muted-foreground)', lineHeight: 1.5 }}>
              Un muestreo del <strong>5% al 10%</strong> de la población es recomendado para obtener un peso promedio estadísticamente confiable.
            </p>
          </div>
        </div>

        {/* Full Width History Table */}
        <div style={{ gridColumn: '1 / -1', marginTop: '3rem' }}>
          <div className="card-premium" style={{ padding: '2rem' }}>
            <h3 style={{ fontSize: '1.1rem', fontWeight: 800, marginBottom: '1.5rem', display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
              <History size={20} style={{ color: 'var(--primary)' }} />
              Historial de Biometrías Recientes
            </h3>
            
            <div style={{ overflowX: 'auto' }}>
              <table style={{ width: '100%', borderCollapse: 'collapse', minWidth: '600px' }}>
                <thead>
                  <tr style={{ borderBottom: '2px solid var(--border)' }}>
                    <th style={{ textAlign: 'left', padding: '1rem', fontSize: '0.8rem', color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Especie</th>
                    <th style={{ textAlign: 'left', padding: '1rem', fontSize: '0.8rem', color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Peso Promedio (g)</th>
                    <th style={{ textAlign: 'left', padding: '1rem', fontSize: '0.8rem', color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Biomasa Total (kg)</th>
                    <th style={{ textAlign: 'left', padding: '1rem', fontSize: '0.8rem', color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Estanque</th>
                    <th style={{ textAlign: 'left', padding: '1rem', fontSize: '0.8rem', color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Fecha</th>
                  </tr>
                </thead>
                <tbody>
                  {history.map((h) => (
                    <tr key={h.id} style={{ borderBottom: '1px solid var(--border)' }}>
                      <td style={{ padding: '1rem', fontWeight: 700 }}>{h.species_name}</td>
                      <td style={{ padding: '1rem', fontWeight: 800, color: '#8b5cf6' }}>{h.avg_weight_gr || h.average_weight_g} g</td>
                      <td style={{ padding: '1rem', fontWeight: 600 }}>{h.total_biomass_kg} kg</td>
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
                      <td colSpan={5} style={{ padding: '3rem', textAlign: 'center', color: 'var(--muted-foreground)' }}>No hay registros recientes.</td>
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
