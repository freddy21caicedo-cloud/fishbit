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
import { useSearchParams, useRouter } from 'next/navigation';
import { toast } from 'react-hot-toast';
import { supabase } from '@/lib/supabase';

export default function BiometriaPage() {
  const searchParams = useSearchParams();
  const router = useRouter();
  const estanqueParam = searchParams.get('estanque');

  const [fecha, setFecha] = useState(new Date().toISOString().split('T')[0]);
  const [estanqueId, setEstanqueId] = useState(estanqueParam || '');
  const [estanquesList, setEstanquesList] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);
  const [showHistory, setShowHistory] = useState(false);
  const [history, setHistory] = useState<any[]>([]);
  const [biometrias, setBiometrias] = useState<any[]>([]);

  useEffect(() => {
    fetchEstanques();
    fetchHistory();
  }, []);

  const fetchHistory = async () => {
    const activeUnitId = localStorage.getItem('active_unit_id');
    if (!activeUnitId) return;

    const { data } = await supabase
      .from('biometrias')
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

    // 2. Fetch Latest Siembra Details to get stocking weights
    const { data: siembraData } = await supabase
      .from('siembras')
      .select('*, siembra_details(*)')
      .eq('estanque_id', pondId)
      .order('date', { ascending: false })
      .limit(1);
    
    const stockingWeights: Record<string, number> = {};
    siembraData?.[0]?.siembra_details?.forEach((sd: any) => {
      stockingWeights[sd.species_name] = Number(sd.avg_weight_gr) || 0;
    });

    if (data && data.length > 0) {
      setBiometrias(data.map(s => ({
        speciesName: s.species_name,
        speciesId: s.id,
        pesoCaptura: '',
        pecesCapturados: '',
        poblacionTotal: s.current_count || 0,
        biomasaInicial: Number(s.current_biomass_kg) || 0,
        pesoSiembra: stockingWeights[s.species_name] || Number(s.avg_weight_gr) || 0
      })));
    } else {
      const pond = estanquesList.find(p => p.id === pondId);
      const spName = pond?.current_species && pond.current_species !== 'Policultivo' ? pond.current_species : '';
      setBiometrias([{
        speciesName: spName,
        speciesId: null,
        pesoCaptura: '',
        pecesCapturados: '',
        poblacionTotal: pond?.current_count || 0,
        biomasaInicial: Number(pond?.current_biomass_kg) || 0,
        pesoSiembra: stockingWeights[spName] || 0
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
    if (!estanqueId || biometrias.length === 0) {
      toast.error("Seleccione un estanque y complete los datos.");
      return;
    }

    const activeUnitId = typeof window !== 'undefined' ? localStorage.getItem('active_unit_id') : null;
    if (!activeUnitId) { toast.error("No se detectó unidad activa."); return; }

    const registerPromise = async () => {
      let totalPondBiomass = 0;
      
      const operations = totals.map(async (bio, i) => {
        const raw = biometrias[i];
        const avgWeight = parseFloat(bio.pesoPromedio);
        const totalBio = parseFloat(bio.biomasaActual);
        totalPondBiomass += totalBio;

        // A. Insert Record
        // 0. Get Pond Current Batch
        const { data: pondData } = await supabase.from('estanques').select('current_batch_id').eq('id', estanqueId).single();

        // A. Insert Record
        const { error: bioError } = await supabase.from('biometrias').insert([{
          estanque_id: estanqueId,
          unit_id: activeUnitId,
          batch_id: pondData?.current_batch_id,
          species_name: raw.speciesName,
          date: fecha,
          avg_weight_gr: avgWeight,
          total_biomass_kg: totalBio
        }]);
        if (bioError) throw bioError;

        // B. Update Species
        if (raw.speciesId) {
          await supabase.from('pond_species').update({
            current_biomass_kg: totalBio,
            avg_weight_gr: avgWeight,
            updated_at: new Date().toISOString()
          }).eq('id', raw.speciesId);
        } else if (raw.speciesName) {
          await supabase.from('pond_species').insert([{
            estanque_id: estanqueId,
            unit_id: activeUnitId,
            species_name: raw.speciesName,
            current_count: raw.poblacionTotal,
            current_biomass_kg: totalBio,
            avg_weight_gr: avgWeight
          }]);
        }
      });

      await Promise.all(operations);

      // 3. Update Pond Total
      await supabase.from('estanques').update({
        current_biomass_kg: totalPondBiomass
      }).eq('id', estanqueId);

      return true;
    };

    toast.promise(registerPromise(), {
      loading: 'Registrando biometría...',
      success: () => {
        fetchEstanques();
        fetchHistory();
        return '¡Biometría registrada con éxito!';
      },
      error: (err) => `Error: ${err.message}`
    });
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
    <div className="animate-fade-in page-container">
      <header style={{ marginBottom: '2rem', display: 'flex', alignItems: 'center', gap: '1rem' }}>
        <Link href="/registros" style={{ color: 'var(--muted-foreground)', display: 'flex', alignItems: 'center', justifyContent: 'center', width: '40px', height: '40px', borderRadius: '50%', background: 'var(--card)', border: '1px solid var(--border)' }}>
          <ArrowLeft size={20} />
        </Link>
        <div>
          <h1 style={{ fontWeight: 800 }}>Biometría de Peces</h1>
          <p style={{ color: 'var(--muted-foreground)', fontSize: '0.9rem' }}>Muestreo de pesos y control biológico.</p>
        </div>
      </header>

      <div className="responsive-grid-2">
        <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
          <div className="card-premium" style={{ padding: '1.5rem' }}>
            <div style={{ display: 'grid', gridTemplateColumns: '1.5fr 1fr', gap: '1.25rem', marginBottom: '1.5rem' }}>
              <div className="premium-input-group">
                <label className="premium-label"><Waves size={14} /> Estanque</label>
                <select value={estanqueId} onChange={(e) => setEstanqueId(e.target.value)} className="premium-input" style={{ width: '100%', fontWeight: 700 }}>
                  <option value="">Seleccionar...</option>
                  {estanquesList.map(p => <option key={p.id} value={p.id}>{p.name}</option>)}
                </select>
              </div>
              <div className="premium-input-group">
                <label className="premium-label"><Calendar size={14} /> Fecha</label>
                <input type="date" value={fecha} onChange={(e) => setFecha(e.target.value)} className="premium-input" style={{ width: '100%' }} />
              </div>
            </div>

            <AnimatePresence>
              {estanqueId && (
                <motion.div initial={{ opacity: 0, height: 0 }} animate={{ opacity: 1, height: 'auto' }} exit={{ opacity: 0, height: 0 }}>
                  <h3 style={{ fontSize: '0.85rem', fontWeight: 800, marginBottom: '1rem', borderTop: '1px solid var(--border)', paddingTop: '1.5rem' }}>Muestreo por Especie</h3>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem', marginBottom: '1.5rem' }}>
                    {biometrias.map((b, idx) => (
                      <div key={idx} style={{ padding: '1.5rem 1rem 1rem 1rem', background: 'var(--secondary)', borderRadius: '12px', border: '1px solid var(--border)', position: 'relative' }}>
                        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '1rem' }}>
                          <span style={{ fontWeight: 800, fontSize: '0.9rem', color: 'var(--primary)' }}>{b.speciesName}</span>
                          <span style={{ fontSize: '0.75rem', fontWeight: 600, color: 'var(--muted-foreground)' }}>Pob: {b.poblacionTotal}</span>
                        </div>
                        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
                          <div className="premium-input-group">
                            <label className="premium-label" style={{ fontSize: '0.8rem', fontWeight: 700 }}>Peso Muestra (kg)</label>
                            <input type="number" step="0.01" value={b.pesoCaptura} onChange={(e) => updateBiometria(idx, 'pesoCaptura', e.target.value)} placeholder="0.00" className="premium-input" style={{ width: '100%' }} />
                          </div>
                          <div className="premium-input-group">
                            <label className="premium-label" style={{ fontSize: '0.8rem', fontWeight: 700 }}>Cant. Peces Muestreados</label>
                            <input type="number" value={b.pecesCapturados} onChange={(e) => updateBiometria(idx, 'pecesCapturados', e.target.value)} placeholder="0" className="premium-input" style={{ width: '100%' }} />
                          </div>
                        </div>
                        <div style={{ marginTop: '1rem', display: 'flex', justifyContent: 'space-between', fontSize: '0.75rem', background: 'rgba(59, 130, 246, 0.08)', padding: '0.75rem', borderRadius: '8px', flexWrap: 'wrap', gap: '0.5rem' }}>
                          <div style={{ color: 'var(--muted-foreground)' }}>Peso Siembra: <span style={{ fontWeight: 800 }}>{b.pesoSiembra}g</span></div>
                          <div style={{ color: 'var(--muted-foreground)' }}>Peso Prom: <span style={{ fontWeight: 800, color: 'var(--primary)' }}>{totals[idx]?.pesoPromedio}g</span></div>
                          <div style={{ color: 'var(--muted-foreground)' }}>Biomasa Est: <span style={{ fontWeight: 800, color: 'var(--primary)' }}>{totals[idx]?.biomasaActual}kg</span></div>
                        </div>
                      </div>
                    ))}
                  </div>
                </motion.div>
              )}
            </AnimatePresence>

            <button onClick={handleRegisterBiometria} className="btn-primary" disabled={loading} style={{ width: '100%', padding: '1rem', borderRadius: '12px', fontWeight: 800, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '0.5rem' }}>
              {loading ? <Activity className="animate-spin" size={18} /> : <Scale size={18} />}
              Registrar Biometría
            </button>
          </div>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
          <div className="card-premium" style={{ padding: '1.5rem', background: 'linear-gradient(135deg, #ffffff 0%, #f9fafb 100%)' }}>
            <h3 style={{ fontSize: '0.75rem', fontWeight: 800, color: 'var(--muted-foreground)', textTransform: 'uppercase', marginBottom: '1.5rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <Activity size={18} style={{ color: '#8b5cf6' }} /> Análisis de Carga
            </h3>
            
            <div style={{ marginBottom: '1.5rem' }}>
              <div style={{ fontSize: '0.7rem', color: 'var(--muted-foreground)', marginBottom: '0.2rem' }}>Biomasa Inicial</div>
              <div style={{ fontSize: '1.25rem', fontWeight: 800 }}>{estanqueId ? biomasaTotalInicial.toFixed(1) : '--'} <span style={{ fontSize: '0.7rem' }}>kg</span></div>
            </div>

            <div style={{ marginBottom: '1.5rem' }}>
              <div style={{ fontSize: '0.7rem', color: 'var(--muted-foreground)', marginBottom: '0.2rem' }}>Biomasa Actual</div>
              <div style={{ fontSize: '2rem', fontWeight: 900, color: '#8b5cf6' }}>
                {estanqueId ? biomasaTotalActual.toFixed(1) : '--'} <span style={{ fontSize: '0.9rem' }}>kg</span>
              </div>
            </div>

            <div style={{ padding: '1rem', background: 'rgba(139, 92, 246, 0.05)', borderRadius: '12px', border: '1px solid rgba(139, 92, 246, 0.1)' }}>
              <div style={{ fontSize: '0.65rem', fontWeight: 700, color: '#8b5cf6', textTransform: 'uppercase', marginBottom: '0.25rem' }}>Incremento</div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', fontWeight: 800, fontSize: '1rem', color: '#10b981' }}>
                <TrendingUp size={16} />
                +{estanqueId ? (biomasaTotalActual - biomasaTotalInicial).toFixed(1) : '0'} kg
              </div>
            </div>
          </div>
        </div>
      </div>

      <div style={{ marginTop: '2rem' }}>
        <div className="card-premium" style={{ padding: '1.5rem' }}>
          <h3 style={{ fontSize: '1rem', fontWeight: 800, marginBottom: '1.5rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <History size={18} style={{ color: 'var(--primary)' }} /> Historial Reciente
          </h3>
          <div style={{ overflowX: 'auto' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse' }}>
              <thead>
                <tr style={{ borderBottom: '2px solid var(--border)' }}>
                  <th style={{ textAlign: 'left', padding: '0.75rem', fontSize: '0.75rem', color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Especie</th>
                  <th style={{ textAlign: 'left', padding: '0.75rem', fontSize: '0.75rem', color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Peso (g)</th>
                  <th style={{ textAlign: 'left', padding: '0.75rem', fontSize: '0.75rem', color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Estanque</th>
                  <th style={{ textAlign: 'left', padding: '0.75rem', fontSize: '0.75rem', color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Fecha</th>
                </tr>
              </thead>
              <tbody>
                {history.map((h) => (
                  <tr key={h.id} style={{ borderBottom: '1px solid var(--border)' }}>
                    <td style={{ padding: '0.75rem', fontWeight: 700 }}>{h.species_name}</td>
                    <td style={{ padding: '0.75rem', fontWeight: 800, color: '#8b5cf6' }}>{h.avg_weight_gr} g</td>
                    <td style={{ padding: '0.75rem' }}><span style={{ padding: '0.2rem 0.5rem', background: 'var(--secondary)', borderRadius: '6px', fontSize: '0.8rem' }}>{h.estanques?.name}</span></td>
                    <td style={{ padding: '0.75rem', fontSize: '0.8rem', color: 'var(--muted-foreground)' }}>{new Date(h.date).toLocaleDateString()}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <div className="mobile-only" style={{ display: 'none', flexDirection: 'column', gap: '1rem' }}>
            {history.map((h) => (
              <div key={h.id} style={{ padding: '1rem', borderRadius: '12px', border: '1px solid var(--border)', background: 'var(--secondary)' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '0.5rem' }}>
                  <span style={{ fontWeight: 800 }}>{h.species_name}</span>
                  <span style={{ fontSize: '0.75rem', color: 'var(--muted-foreground)' }}>{new Date(h.date).toLocaleDateString()}</span>
                </div>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.5rem' }}>
                  <div style={{ fontSize: '0.85rem' }}>Peso: <strong style={{ color: '#8b5cf6' }}>{h.avg_weight_gr}g</strong></div>
                  <div style={{ fontSize: '0.85rem' }}>Bio: <strong>{h.total_biomass_kg}kg</strong></div>
                  <div style={{ fontSize: '0.85rem', gridColumn: 'span 2' }}>Estanque: <strong>{h.estanques?.name}</strong></div>
                </div>
              </div>
            ))}
          </div>

          {history.length === 0 && (
            <div style={{ padding: '2rem', textAlign: 'center', color: 'var(--muted-foreground)' }}>No hay registros recientes.</div>
          )}
        </div>
      </div>
    </div>
  );
}
