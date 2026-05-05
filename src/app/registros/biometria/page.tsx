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
  Info 
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

  useEffect(() => {
    fetchEstanques();
  }, []);

  const fetchEstanques = async () => {
    const { data, error } = await supabase
      .from('estanques')
      .select('*')
      .eq('status', 'con_peces');
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
    const { data } = await supabase.from('pond_species').select('*').eq('estanque_id', pondId);
    if (data) {
      setBiometrias(data.map(s => ({
        speciesName: s.species_name,
        speciesId: s.id,
        pesoCaptura: '',
        pecesCapturados: '',
        poblacionTotal: s.current_count || 0,
        biomasaInicial: parseFloat(s.current_biomass_kg) || 0
      })));
    }
    setLoading(false);
  };

  const updateBiometria = (index: number, field: string, value: string) => {
    const newBiometrias = [...biometrias];
    newBiometrias[index] = { ...newBiometrias[index], [field]: value };
    setBiometrias(newBiometrias);
  };

  const handleRegisterBiometria = async () => {
    if (!estanqueId || biometrias.length === 0) return;

    setLoading(true);
    let totalPondBiomass = 0;

    for (let i = 0; i < biometrias.length; i++) {
      const bio = totals[i];
      const raw = biometrias[i];
      const avgWeight = parseFloat(bio.pesoPromedio);
      const totalBio = parseFloat(bio.biomasaActual);
      totalPondBiomass += totalBio;

      // 1. Insert record
      const { error: bioError } = await supabase.from('biometrias').insert([{
        estanque_id: estanqueId,
        species_name: raw.speciesName,
        date: fecha,
        avg_weight_gr: avgWeight,
        total_biomass_kg: totalBio
      }]);

      if (bioError) {
        alert(`Error al registrar biometría para ${raw.speciesName}: ${bioError.message}`);
        continue;
      }

      // 2. Update Species Table if applicable
      if (raw.speciesId) {
        await supabase
          .from('pond_species')
          .update({
            current_biomass_kg: totalBio,
            avg_weight_gr: avgWeight,
            updated_at: new Date().toISOString()
          })
          .eq('id', raw.speciesId);
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
            <div>
              <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 700, marginBottom: '0.5rem', textTransform: 'uppercase', color: 'var(--muted-foreground)' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                  <Calendar size={14} /> Fecha de Muestreo
                </div>
              </label>
              <input 
                type="date" 
                value={fecha}
                onChange={(e) => setFecha(e.target.value)}
                style={{ width: '100%', padding: '0.875rem', borderRadius: '12px', border: '1px solid var(--border)', background: 'var(--secondary)', outline: 'none' }} 
              />
            </div>
            <div>
              <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 700, marginBottom: '0.5rem', textTransform: 'uppercase', color: 'var(--muted-foreground)' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                  <Waves size={14} /> Seleccionar Estanque
                </div>
              </label>
              <select 
                value={estanqueId}
                onChange={(e) => setEstanqueId(e.target.value)}
                style={{ width: '100%', padding: '0.875rem', borderRadius: '12px', border: '1px solid var(--border)', background: 'var(--secondary)', outline: 'none', fontWeight: 600 }}
              >
                <option value="">-- Seleccionar --</option>
                {estanquesList.map(p => <option key={p.id} value={p.id}>{p.name} {p.is_polyculture ? '(Policultivo)' : ''}</option>)}
              </select>
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
                  {totals.map((bio, index) => (
                    <div key={bio.speciesName} style={{ 
                      padding: '1.5rem', 
                      background: 'var(--secondary)', 
                      borderRadius: '16px', 
                      border: '1px solid var(--border)',
                      display: 'grid',
                      gridTemplateColumns: 'repeat(auto-fit, minmax(140px, 1fr))',
                      gap: '1.5rem',
                      alignItems: 'center'
                    }}>
                      <div>
                        <div style={{ fontSize: '0.7rem', fontWeight: 700, color: '#8b5cf6', textTransform: 'uppercase', marginBottom: '0.25rem' }}>Especie</div>
                        <div style={{ fontWeight: 800, fontSize: '1rem', color: 'var(--foreground)' }}>{bio.speciesName}</div>
                        <div style={{ fontSize: '0.75rem', color: 'var(--muted-foreground)' }}>Pob. estimada: {bio.poblacionTotal.toLocaleString()}</div>
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
      </div>
    </div>
  );
}
