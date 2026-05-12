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
import { toast } from 'react-hot-toast';

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
    }
  }, [estanqueId, ponds]);

  const handleRegisterAlimentacion = async () => {
    if (!estanqueId || !alimentoId || !cantidad || parseFloat(cantidad) <= 0) {
      toast.error("Por favor complete todos los campos obligatorios.");
      return;
    }

    const totalQty = parseFloat(cantidad);
    const selectedFood = foodStock.find(f => f.id === alimentoId);

    if (selectedFood && parseFloat(selectedFood.current_stock) < totalQty) {
      toast.error("No hay suficiente alimento en inventario.");
      return;
    }

    try {
      const activeUnitId = localStorage.getItem('active_unit_id');
      if (!activeUnitId) throw new Error("No hay unidad activa");

      const registerPromise = async () => {
        const { data: pondData } = await supabase.from('estanques').select('current_batch_id').eq('id', estanqueId).single();
        
        const { error: regError } = await supabase.from('alimentacion_diaria').insert([{
          estanque_id: estanqueId,
          inventory_id: alimentoId,
          quantity_kg: totalQty,
          date: fecha,
          unit_id: activeUnitId,
          batch_id: pondData?.current_batch_id
        }]);

        if (regError) throw regError;

        if (selectedFood) {
          const { error: invError } = await supabase
            .from('inventory')
            .update({ current_stock: parseFloat(selectedFood.current_stock) - totalQty })
            .eq('id', selectedFood.id);
          if (invError) throw invError;
        }
        return true;
      };

      toast.promise(registerPromise(), {
        loading: 'Registrando alimentación...',
        success: () => {
          setEstanqueId('');
          setAlimentoId('');
          setCantidad('');
          fetchBasicData();
          fetchHistory();
          return "¡Alimentación registrada con éxito!";
        },
        error: (err) => `Error: ${err.message}`
      });
    } catch (err: any) {
      toast.error("Error: " + err.message);
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
    <div className="animate-fade-in page-container">
      <header style={{ marginBottom: '2rem', display: 'flex', alignItems: 'center', gap: '1rem' }}>
        <Link href="/registros" style={{ color: 'var(--muted-foreground)', display: 'flex', alignItems: 'center', justifyContent: 'center', width: '40px', height: '40px', borderRadius: '50%', background: 'var(--card)', border: '1px solid var(--border)' }}>
          <ArrowLeft size={20} />
        </Link>
        <div>
          <h1 style={{ fontWeight: 800 }}>Registro de Alimentación</h1>
          <p style={{ color: 'var(--muted-foreground)', fontSize: '0.9rem' }}>Bitácora diaria de nutrición por estanque.</p>
        </div>
      </header>

      <div className="responsive-grid-2" style={{ minWidth: 0 }}>
        {/* Registration Form */}
        <div className="card-premium" style={{ padding: 'clamp(1rem, 3vw, 1.5rem)', minWidth: 0 }}>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(150px, 1fr))', gap: '1.25rem', marginBottom: '1.5rem' }}>
            <div className="premium-input-group">
              <label className="premium-label"><Calendar size={14} /> Fecha</label>
              <input type="date" value={fecha} onChange={(e) => setFecha(e.target.value)} className="premium-input" />
            </div>
            <div className="premium-input-group">
              <label className="premium-label"><Waves size={14} /> Estanque</label>
              <select value={estanqueId} onChange={(e) => setEstanqueId(e.target.value)} className="premium-input" style={{ fontWeight: 700 }}>
                <option value="">Seleccionar...</option>
                {ponds.map(p => <option key={p.id} value={p.id}>{p.name}</option>)}
              </select>
            </div>
          </div>
          <div className="premium-input-group" style={{ marginBottom: '1.5rem' }}>
            <label className="premium-label"><Package size={14} /> Tipo de Alimento</label>
            <select value={alimentoId} onChange={(e) => setAlimentoId(e.target.value)} className="premium-input" style={{ fontWeight: 700 }}>
              <option value="">Seleccionar...</option>
              {foodStock.map(f => (
                <option key={f.id} value={f.id}>{f.name} ({f.current_stock} kg)</option>
              ))}
            </select>
          </div>

          <div className="premium-input-group" style={{ marginBottom: '1.5rem' }}>
            <label className="premium-label"><Utensils size={14} /> Cantidad Total Suministrada</label>
            <div style={{ position: 'relative' }}>
              <input 
                type="number" 
                value={cantidad} 
                onChange={(e) => setCantidad(e.target.value)} 
                className="premium-input" 
                placeholder="0.0" 
                style={{ paddingRight: '3rem' }}
              />
              <span style={{ position: 'absolute', right: '1rem', top: '50%', transform: 'translateY(-50%)', fontWeight: 700, color: 'var(--muted-foreground)' }}>kg</span>
            </div>
          </div>

          <button 
            onClick={handleRegisterAlimentacion} 
            className="btn-primary" 
            style={{ width: '100%', marginTop: '1rem', padding: '1rem', borderRadius: '12px', fontWeight: 800, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '0.5rem' }}
          >
            <Utensils size={18} />
            Registrar Alimentación
          </button>
        </div>

        {/* Info & Metrics */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
          {fcaInfo && (
            <div className="card-premium" style={{ padding: '1.5rem', borderLeft: `5px solid ${fcaInfo.color}` }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                <div>
                  <div style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--muted-foreground)', textTransform: 'uppercase', marginBottom: '0.5rem' }}>FCA Proyectado</div>
                  <div style={{ fontSize: '2.5rem', fontWeight: 900, color: fcaInfo.color }}>{fcaInfo.value}</div>
                </div>
                <div style={{ background: `${fcaInfo.color}15`, color: fcaInfo.color, padding: '0.4rem 0.75rem', borderRadius: '8px', fontSize: '0.75rem', fontWeight: 800 }}>
                  {fcaInfo.status}
                </div>
              </div>
              <p style={{ fontSize: '0.85rem', color: 'var(--muted-foreground)', marginTop: '0.5rem' }}>ConversiÃ³n Alimenticia estimada segÃºn Ãºltima biometrÃ­a.</p>
            </div>
          )}
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
            <h3 style={{ fontSize: '0.85rem', fontWeight: 700, color: 'var(--muted-foreground)', textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: '1.5rem' }}>Factor de ConversiÃ³n (F.C.A.)</h3>
            
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
                <span style={{ fontSize: '0.75rem', color: 'var(--muted-foreground)' }}>Basado en biometrÃ­a del {lastBiometryData?.date}</span>
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
                  {estanqueId ? 'No hay biometrÃ­as previas' : 'Seleccione un estanque'}
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
        <div style={{ gridColumn: '1 / -1', marginTop: '3rem', minWidth: 0 }}>
          <div className="card-premium" style={{ padding: 'clamp(1rem, 3vw, 2rem)', minWidth: 0 }}>
            <h3 style={{ fontSize: '1.1rem', fontWeight: 800, marginBottom: '1.5rem', display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
              <History size={20} style={{ color: 'var(--primary)' }} />
              BitÃ¡cora de AlimentaciÃ³n Diaria
            </h3>
            
            <div style={{ overflowX: 'auto' }}>
              <table style={{ width: '100%', borderCollapse: 'collapse', minWidth: '700px' }}>
                <thead>
                  <tr style={{ borderBottom: '2px solid var(--border)' }}>
                    <th style={{ textAlign: 'left', padding: '1rem', fontSize: '0.8rem', color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Cantidad (kg)</th>
                    <th style={{ textAlign: 'left', padding: '1rem', fontSize: '0.8rem', color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Alimento</th>
                    <th style={{ textAlign: 'left', padding: '1rem', fontSize: '0.8rem', color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Estanque</th>
                    <th style={{ textAlign: 'left', padding: '1rem', fontSize: '0.8rem', color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Fecha</th>
                  </tr>
                </thead>
                <tbody>
                  {history.map((h) => (
                    <tr key={h.id} style={{ borderBottom: '1px solid var(--border)' }}>
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
                      <td colSpan={5} style={{ padding: '3rem', textAlign: 'center', color: 'var(--muted-foreground)' }}>No hay registros de alimentaciÃ³n recientes.</td>
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
