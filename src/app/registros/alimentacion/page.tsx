'use client';
import { useEffect, useState, useMemo } from 'react';
import { 
  Calendar, 
  Waves, 
  Package, 
  Utensils, 
  ArrowLeft, 
  History, 
  TrendingUp,
  Plus,
  AlertCircle
} from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import Link from 'next/link';
import { useSearchParams } from 'next/navigation';
import { supabase } from '@/lib/supabase';

export default function AlimentacionPage() {
  const searchParams = useSearchParams();
  const estanqueParam = searchParams.get('estanque');

  const [fecha, setFecha] = useState(new Date().toISOString().split('T')[0]);
  const [estanqueId, setEstanqueId] = useState(estanqueParam || '');
  const [alimentoId, setAlimentoId] = useState('');
  const [cantidad, setCantidad] = useState('');
  
  const [ponds, setPonds] = useState<any[]>([]);
  const [foodStock, setFoodStock] = useState<any[]>([]);
  const [lastBiometryData, setLastBiometryData] = useState<any>(null);
  const [totalFoodSinceLastBio, setTotalFoodSinceLastBio] = useState(0);
  const [alimentaciones, setAlimentaciones] = useState<any[]>([]);

  const [history, setHistory] = useState<any[]>([]);

  useEffect(() => {
    fetchBasicData();
    fetchHistory();
  }, []);

  const fetchHistory = async () => {
    const activeUnitId = localStorage.getItem('active_unit_id');
    if (!activeUnitId) return;

    const { data } = await supabase
      .from('alimentacion_diaria')
      .select('*, estanques(name), inventory(name)')
      .eq('unit_id', activeUnitId)
      .order('date', { ascending: false })
      .limit(10);
    
    if (data) setHistory(data);
  };

  useEffect(() => {
    if (estanqueId) {
      fetchPondDetails(estanqueId);
    }
  }, [estanqueId]);

  const fetchBasicData = async () => {
    // 1. Fetch Ponds with Fish
    const { data: pondsData } = await supabase
      .from('estanques')
      .select('*')
      .eq('status', 'con_peces');
    setPonds(pondsData || []);

    // 2. Fetch Alimento Inventory
    const activeUnitId = localStorage.getItem('active_unit_id');
    const { data: invData } = await supabase
      .from('inventory')
      .select('*')
      .eq('category', 'alimento')
      .eq('unit_id', activeUnitId);
    setFoodStock(invData || []);
  };

  const fetchSpecies = async (pondId: string) => {
    const activeUnitId = localStorage.getItem('active_unit_id');
    const { data } = await supabase
      .from('pond_species')
      .select('*')
      .eq('estanque_id', pondId)
      .eq('unit_id', activeUnitId);

    if (data && data.length > 0) {
      setAlimentaciones(data.map(s => ({
        speciesId: s.id,
        speciesName: s.species_name,
        quantity: ''
      })));
    } else {
      const p = ponds.find(pond => pond.id === pondId);
      setAlimentaciones([{
        speciesId: null,
        speciesName: p?.current_species && p.current_species !== 'Policultivo' ? p.current_species : '',
        quantity: ''
      }]);
    }
  };

  const fetchPondDetails = async (id: string) => {
    // 0. Get Pond Current Batch
    const { data: pondData } = await supabase.from('estanques').select('current_batch_id').eq('id', id).single();
    const activeBatchId = pondData?.current_batch_id;

    // 1. Get Last Biometry
    const { data: bioData } = await supabase
      .from('biometrias')
      .select('*')
      .eq('estanque_id', id)
      .order('date', { ascending: false })
      .limit(1);
    
    const lastBio = bioData?.[0] || null;
    setLastBiometryData(lastBio);

    // 2. Get Total Food Consumed ONLY FOR THIS BATCH
    let query = supabase
      .from('alimentacion_diaria')
      .select('quantity_kg')
      .eq('estanque_id', id);
    
    if (activeBatchId) {
      query = query.eq('batch_id', activeBatchId);
    }

    if (lastBio) {
      query = query.gt('date', lastBio.date);
    }

    const { data: foodData } = await query;
    const total = (foodData || []).reduce((sum, item) => sum + (parseFloat(item.quantity_kg) || 0), 0);
    setTotalFoodSinceLastBio(total);
  };

  useEffect(() => {
    if (estanqueId) {
      fetchPondDetails(estanqueId);
      fetchSpecies(estanqueId);
    } else {
      setAlimentaciones([]);
    }
  }, [estanqueId, ponds]);

  const handleRegisterAlimentacion = async () => {
    if (!estanqueId || !alimentoId || alimentaciones.every(a => !a.quantity || parseFloat(a.quantity) <= 0)) {
      alert("Por favor complete todos los campos obligatorios.");
      return;
    }

    const totalQty = alimentaciones.reduce((sum, a) => sum + (parseFloat(a.quantity) || 0), 0);
    const selectedFood = foodStock.find(f => f.id === alimentoId);

    if (selectedFood && parseFloat(selectedFood.current_stock) < totalQty) {
      alert("No hay suficiente alimento en inventario.");
      return;
    }

    const activeUnitId = localStorage.getItem('active_unit_id');
    if (!activeUnitId) return;

    const { data: pondData } = await supabase.from('estanques').select('current_batch_id').eq('id', estanqueId).single();

    try {
      for (const alim of alimentaciones) {
        const qty = parseFloat(alim.quantity) || 0;
        if (qty <= 0) continue;

        const { error: regError } = await supabase.from('alimentacion_diaria').insert([{
          estanque_id: estanqueId,
          inventory_id: alimentoId,
          quantity_kg: qty,
          species_name: alim.speciesName,
          date: fecha,
          unit_id: activeUnitId,
          batch_id: pondData?.current_batch_id
        }]);

        if (regError) throw regError;
      }

      if (selectedFood) {
        await supabase
          .from('inventory')
          .update({ current_stock: parseFloat(selectedFood.current_stock) - totalQty })
          .eq('id', selectedFood.id);
      }

      alert("¡Alimentación registrada con éxito!");
      setEstanqueId('');
      setAlimentoId('');
      fetchBasicData();
      fetchHistory();
    } catch (err: any) {
      alert("Error: " + err.message);
    }
  };

  const remainingStock = useMemo(() => {
    const selectedFood = foodStock.find(f => f.id === alimentoId);
    if (!selectedFood) return 0;
    const inputQty = parseFloat(cantidad) || 0;
    return Math.max(0, (parseFloat(selectedFood.current_stock) || 0) - inputQty);
  }, [foodStock, alimentoId, cantidad]);

  // FCA Projection Logic
  const fcaInfo = useMemo(() => {
    if (!estanqueId || !cantidad || !lastBiometryData) return null;
    const newQty = parseFloat(cantidad) || 0;
    const totalFood = totalFoodSinceLastBio + newQty;
    
    // Formula: (Total food consumed) / current total biomass
    const currentFCA = totalFood / (parseFloat(lastBiometryData.total_biomass_kg) || 1); 
    
    let color = '#10b981'; // Green
    let status = 'Eficiente';
    if (currentFCA > 1.8) {
      color = '#ef4444'; // Red
      status = 'Crítico';
    } else if (currentFCA > 1.4) {
      color = '#f59e0b'; // Yellow
      status = 'Alerta';
    }
    
    return { value: currentFCA.toFixed(2), color, status };
  }, [estanqueId, cantidad, lastBiometryData, totalFoodSinceLastBio]);

  return (
    <div className="animate-fade-in" style={{ maxWidth: '1200px', margin: '0 auto', paddingBottom: '4rem' }}>
      <header style={{ marginBottom: '2.5rem', display: 'flex', alignItems: 'center', gap: '1rem' }}>
        <Link href="/registros" style={{ color: 'var(--muted-foreground)', display: 'flex', alignItems: 'center', justifyContent: 'center', width: '40px', height: '40px', borderRadius: '50%', background: 'var(--card)', border: '1px solid var(--border)' }}>
          <ArrowLeft size={20} />
        </Link>
        <div>
          <h1 style={{ fontSize: '1.875rem', fontWeight: 700 }}>Registro de Alimentación</h1>
          <p style={{ color: 'var(--muted-foreground)' }}>Control nutricional y seguimiento de conversión alimenticia.</p>
        </div>
      </header>

      <div className="responsive-container">
        {/* Main Form Card */}
        <div className="card-premium" style={{ flex: 1.4, padding: 'clamp(1.5rem, 5vw, 2.5rem)', position: 'relative', overflow: 'hidden' }}>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '1.5rem', marginBottom: '2rem' }}>
            <div className="premium-input-group">
              <label className="premium-label">
                <Calendar size={14} /> Fecha de Suministro
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
                <Waves size={14} /> Estanque Seleccionado
              </label>
              <div className="premium-input-wrapper">
                <select 
                  value={estanqueId}
                  onChange={(e) => setEstanqueId(e.target.value)}
                  style={{ width: '100%', background: 'transparent', border: 'none', outline: 'none', fontWeight: 700 }}
                >
                  <option value="">Seleccionar Estanque...</option>
                  {ponds.map(p => <option key={p.id} value={p.id}>{p.name} {p.is_polyculture ? '(Policultivo)' : `(${p.current_species})`}</option>)}
                </select>
              </div>
            </div>
          </div>

          <div className="premium-input-group" style={{ marginBottom: '2rem' }}>
            <label className="premium-label">
              <Package size={14} /> Alimento Disponible en Bodega
            </label>
            <div className="premium-input-wrapper" style={{ opacity: !estanqueId ? 0.5 : 1 }}>
              <select 
                value={alimentoId}
                onChange={(e) => setAlimentoId(e.target.value)}
                disabled={!estanqueId}
                style={{ width: '100%', background: 'transparent', border: 'none', outline: 'none', fontWeight: 700 }}
              >
                <option value="">-- Seleccionar Alimento --</option>
                {foodStock.map(f => (
                  <option key={f.id} value={f.id}>{f.name} ({parseFloat(f.current_stock).toLocaleString()} kg)</option>
                ))}
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
                <h3 style={{ fontSize: '0.85rem', fontWeight: 800, color: 'var(--muted-foreground)', textTransform: 'uppercase', marginBottom: '1.5rem', borderTop: '1px solid var(--border)', paddingTop: '1.5rem' }}>Detalle de Alimentación por Especie</h3>
                
                {ponds.find(p => p.id === estanqueId)?.is_polyculture && alimentaciones.some(a => !a.speciesId) && (
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

                <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem', marginBottom: '2rem' }}>
                  {alimentaciones.map((alim, index) => (
                    <div key={index} style={{ 
                      padding: '1.25rem', 
                      background: 'var(--secondary)', 
                      borderRadius: '12px', 
                      border: '1px solid var(--border)',
                      display: 'grid',
                      gridTemplateColumns: '2fr 1fr 40px',
                      gap: '1rem',
                      alignItems: 'center',
                      position: 'relative'
                    }}>
                      {alimentaciones.length > 1 && (
                        <button 
                          onClick={() => removeSpeciesRow(index)}
                          style={{ position: 'absolute', top: '0.5rem', right: '0.5rem', color: '#ef4444', background: 'none', border: 'none', cursor: 'pointer', fontSize: '0.65rem', fontWeight: 800 }}
                        >
                          X
                        </button>
                      )}
                      <div>
                        {alim.speciesId ? (
                          <div style={{ fontWeight: 800, fontSize: '0.95rem' }}>{alim.speciesName}</div>
                        ) : (
                          <input 
                            type="text"
                            value={alim.speciesName}
                            onChange={(e) => updateAlimentacion(index, 'speciesName', e.target.value)}
                            placeholder="Especie"
                            style={{ width: '100%', padding: '0.4rem', borderRadius: '6px', border: '1px solid var(--border)', fontSize: '0.85rem', fontWeight: 700 }}
                          />
                        )}
                        <div style={{ fontSize: '0.7rem', color: 'var(--muted-foreground)' }}>Asignar kg para esta especie</div>
                      </div>
                      <div>
                        <input 
                          type="number" 
                          value={alim.quantity}
                          onChange={(e) => updateAlimentacion(index, 'quantity', e.target.value)}
                          placeholder="kg"
                          style={{ width: '100%', padding: '0.5rem', borderRadius: '8px', border: '1px solid var(--border)', background: 'white', outline: 'none', fontWeight: 800, fontSize: '1.1rem' }}
                        />
                      </div>
                      <div style={{ textAlign: 'center' }}>
                        <Utensils size={18} style={{ color: alim.quantity > 0 ? '#10b981' : 'var(--border)' }} />
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
              </motion.div>
            )}
          </AnimatePresence>

          <button 
            onClick={handleRegisterAlimentacion}
            className="btn-primary" 
            style={{ width: '100%', padding: '1.25rem', borderRadius: '16px', fontSize: '1.1rem', fontWeight: 800, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '0.75rem', marginBottom: '1.5rem' }}
          >
            <Utensils size={22} />
            Registrar Alimentación
          </button>

          {/* Static Detailed Fish Silhouette in corner */}
          <div style={{ position: 'absolute', bottom: '-10px', right: '-10px', opacity: 0.05, pointerEvents: 'none' }}>
            <svg width="200" height="120" viewBox="0 0 200 120" fill="none" xmlns="http://www.w3.org/2000/svg">
              <path 
                d="M10 60C10 35 40 15 80 15C100 15 130 25 150 40L180 10V110L150 80C130 95 100 105 80 105C40 105 10 85 10 60Z" 
                fill="currentColor" 
              />
              <path d="M150 40C155 45 155 75 150 80" stroke="white" strokeWidth="2" strokeOpacity="0.3" />
              <circle cx="45" cy="45" r="4" fill="white" fillOpacity="0.5" />
            </svg>
          </div>
        </div>

        {/* FCA & Analysis Sidebar */}
        <div className="responsive-side-panel" style={{ display: 'flex', flexDirection: 'column', gap: '2rem', flex: 1 }}>
          {/* FCA Gauge Card */}
          <div className="card-premium" style={{ padding: '2rem', textAlign: 'center' }}>
            <h3 style={{ fontSize: '0.85rem', fontWeight: 700, color: 'var(--muted-foreground)', textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: '1.5rem' }}>Factor de Conversión (F.C.A.)</h3>
            
            <div style={{ position: 'relative', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', marginBottom: '1rem' }}>
              <motion.div 
                animate={{ scale: fcaInfo ? [1, 1.05, 1] : 1 }}
                style={{ 
                  width: '140px', 
                  height: '140px', 
                  borderRadius: '50%', 
                  border: `12px solid ${fcaInfo ? fcaInfo.color : 'var(--border)'}`,
                  display: 'flex',
                  flexDirection: 'column',
                  alignItems: 'center',
                  justifyContent: 'center',
                  transition: 'all 0.5s cubic-bezier(0.4, 0, 0.2, 1)'
                }}>
                <div style={{ fontSize: '2.5rem', fontWeight: 800, color: fcaInfo ? fcaInfo.color : 'var(--muted-foreground)' }}>
                  {fcaInfo ? fcaInfo.value : '--'}
                </div>
              </motion.div>
            </div>

            {fcaInfo && (
              <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem', alignItems: 'center' }}>
                <div style={{ padding: '0.4rem 1.25rem', borderRadius: '50px', background: fcaInfo.color, color: 'white', fontWeight: 800, fontSize: '0.85rem' }}>
                  {fcaInfo.status}
                </div>
                <span style={{ fontSize: '0.75rem', color: 'var(--muted-foreground)' }}>Basado en biometría del {lastBiometryData?.date}</span>
              </div>
            )}
          </div>

          {/* FCA History List */}
          <div className="card-premium" style={{ padding: '1.5rem' }}>
            <h3 style={{ fontSize: '0.85rem', fontWeight: 700, color: 'var(--muted-foreground)', textTransform: 'uppercase', marginBottom: '1rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <History size={16} /> Historial F.C.A. (Tendencia)
            </h3>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
              {estanqueId && lastBiometryData ? (
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '0.5rem 0.75rem', background: 'var(--secondary)', borderRadius: '8px' }}>
                  <span style={{ fontSize: '0.8rem', fontWeight: 600, color: 'var(--muted-foreground)' }}>{lastBiometryData.date}</span>
                  <span style={{ fontSize: '0.9rem', fontWeight: 800, color: '#10b981' }}>{fcaInfo?.value}</span>
                </div>
              ) : (
                <div style={{ fontSize: '0.8rem', color: 'var(--muted-foreground)', textAlign: 'center', padding: '1rem' }}>
                  {estanqueId ? 'No hay biometrías previas' : 'Seleccione un estanque'}
                </div>
              )}
            </div>
          </div>

          {/* Alert Banner */}
          <div style={{ 
            padding: '1.25rem', 
            borderRadius: '20px', 
            background: 'linear-gradient(to right, rgba(37, 99, 235, 0.05), rgba(37, 99, 235, 0.01))', 
            border: '1px solid var(--border)',
            display: 'flex', 
            gap: '1rem', 
            alignItems: 'center'
          }}>
            <TrendingUp size={24} style={{ color: 'var(--primary)' }} />
            <div>
              <div style={{ fontWeight: 700, fontSize: '0.9rem' }}>Ahorro Proyectado</div>
              <p style={{ fontSize: '0.75rem', color: 'var(--muted-foreground)' }}>Cada 0.1 de mejora en F.C.A. representa un ahorro del 8% en alimento.</p>
            </div>
          </div>
        </div>

        {/* Full Width History Table */}
        <div style={{ gridColumn: '1 / -1', marginTop: '3rem' }}>
          <div className="card-premium" style={{ padding: '2rem' }}>
            <h3 style={{ fontSize: '1.1rem', fontWeight: 800, marginBottom: '1.5rem', display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
              <History size={20} style={{ color: 'var(--primary)' }} />
              Bitácora de Alimentación Diaria
            </h3>
            
            <div style={{ overflowX: 'auto' }}>
              <table style={{ width: '100%', borderCollapse: 'collapse', minWidth: '700px' }}>
                <thead>
                  <tr style={{ borderBottom: '2px solid var(--border)' }}>
                    <th style={{ textAlign: 'left', padding: '1rem', fontSize: '0.8rem', color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Especie</th>
                    <th style={{ textAlign: 'left', padding: '1rem', fontSize: '0.8rem', color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Cantidad (kg)</th>
                    <th style={{ textAlign: 'left', padding: '1rem', fontSize: '0.8rem', color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Alimento</th>
                    <th style={{ textAlign: 'left', padding: '1rem', fontSize: '0.8rem', color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Estanque</th>
                    <th style={{ textAlign: 'left', padding: '1rem', fontSize: '0.8rem', color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Fecha</th>
                  </tr>
                </thead>
                <tbody>
                  {history.map((h) => (
                    <tr key={h.id} style={{ borderBottom: '1px solid var(--border)' }}>
                      <td style={{ padding: '1rem', fontWeight: 700 }}>{h.species_name || 'Especie'}</td>
                      <td style={{ padding: '1rem', fontWeight: 800, color: '#10b981' }}>{h.quantity_kg} kg</td>
                      <td style={{ padding: '1rem', fontSize: '0.9rem' }}>{h.inventory?.name}</td>
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
                      <td colSpan={5} style={{ padding: '3rem', textAlign: 'center', color: 'var(--muted-foreground)' }}>No hay registros de alimentación recientes.</td>
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
