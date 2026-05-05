'use client';
import { useEffect, useState, useMemo } from 'react';
import { 
  Calendar, 
  Waves, 
  Package, 
  Utensils, 
  ArrowLeft, 
  History, 
  TrendingUp 
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

  useEffect(() => {
    fetchBasicData();
  }, []);

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
    const { data: invData } = await supabase
      .from('inventory')
      .select('*')
      .eq('category', 'alimento');
    setFoodStock(invData || []);
  };

  const fetchPondDetails = async (id: string) => {
    // 1. Get Last Biometry
    const { data: bioData } = await supabase
      .from('biometrias')
      .select('*')
      .eq('estanque_id', id)
      .order('date', { ascending: false })
      .limit(1);
    
    const lastBio = bioData?.[0] || null;
    setLastBiometryData(lastBio);

    // 2. Get Total Food Consumed since that bio (or total if no bio)
    const query = supabase
      .from('alimentacion_diaria')
      .select('quantity_kg')
      .eq('estanque_id', id);
    
    if (lastBio) {
      query.gt('date', lastBio.date);
    }

    const { data: foodData } = await query;
    const total = (foodData || []).reduce((sum, item) => sum + (parseFloat(item.quantity_kg) || 0), 0);
    setTotalFoodSinceLastBio(total);
  };

  const handleRegisterAlimentacion = async () => {
    if (!estanqueId || !alimentoId || !cantidad) {
      alert("Por favor complete todos los campos.");
      return;
    }

    const qty = parseFloat(cantidad);
    const selectedFood = foodStock.find(f => f.id === alimentoId);

    if (selectedFood && parseFloat(selectedFood.current_stock) < qty) {
      alert("No hay suficiente alimento en inventario.");
      return;
    }

    // 1. Insert record
    const { error: regError } = await supabase.from('alimentacion_diaria').insert([{
      estanque_id: estanqueId,
      inventory_id: alimentoId,
      date: fecha,
      quantity_kg: qty
    }]);

    if (regError) {
      alert("Error al registrar alimentación: " + regError.message);
      return;
    }

    // 2. Update Inventory
    if (selectedFood) {
      await supabase
        .from('inventory')
        .update({ current_stock: parseFloat(selectedFood.current_stock) - qty })
        .eq('id', selectedFood.id);
    }

    alert("¡Alimentación registrada con éxito!");
    setCantidad('');
    fetchBasicData();
    fetchPondDetails(estanqueId);
  };

  // Dynamic Stock Calculation
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

      <div style={{ display: 'grid', gridTemplateColumns: '1.4fr 1fr', gap: '2rem' }}>
        {/* Main Form Card */}
        <div className="card-premium" style={{ padding: '2.5rem', position: 'relative', overflow: 'hidden' }}>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '2rem', marginBottom: '2rem' }}>
            <div>
              <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 700, marginBottom: '0.5rem', textTransform: 'uppercase', color: 'var(--muted-foreground)' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                   <Calendar size={14} /> Fecha
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
                  <Waves size={14} /> Estanque
                </div>
              </label>
              <select 
                value={estanqueId}
                onChange={(e) => setEstanqueId(e.target.value)}
                style={{ width: '100%', padding: '0.875rem', borderRadius: '12px', border: '1px solid var(--border)', background: 'var(--secondary)', outline: 'none', fontWeight: 600 }}
              >
                <option value="">Seleccionar Estanque...</option>
                {ponds.map(p => <option key={p.id} value={p.id}>{p.name} {p.is_polyculture ? '(Policultivo)' : `(${p.current_species})`}</option>)}
              </select>
            </div>
          </div>

          <div style={{ marginBottom: '2rem' }}>
            <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 700, marginBottom: '0.5rem', textTransform: 'uppercase', color: 'var(--muted-foreground)' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                <Package size={14} /> Alimento Disponible en Bodega
              </div>
            </label>
            <select 
              value={alimentoId}
              onChange={(e) => setAlimentoId(e.target.value)}
              disabled={!estanqueId}
              style={{ width: '100%', padding: '0.875rem', borderRadius: '12px', border: '1px solid var(--border)', background: 'var(--secondary)', outline: 'none', fontWeight: 600, opacity: !estanqueId ? 0.5 : 1 }}
            >
              <option value="">-- Seleccionar Alimento --</option>
              {foodStock.map(f => (
                <option key={f.id} value={f.id}>{f.name} ({f.current_stock} bultos)</option>
              ))}
            </select>
          </div>

          <div style={{ marginBottom: '2rem', display: 'flex', gap: '1.5rem', alignItems: 'flex-end' }}>
            <div style={{ flex: 1 }}>
              <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 700, marginBottom: '0.5rem', textTransform: 'uppercase', color: 'var(--muted-foreground)' }}>
                Cantidad a Suministrar (kg)
              </label>
              <input 
                type="number" 
                value={cantidad}
                onChange={(e) => setCantidad(e.target.value)}
                placeholder="0.00"
                style={{ width: '100%', padding: '1rem', fontSize: '1.5rem', borderRadius: '12px', border: '1px solid var(--border)', background: 'var(--secondary)', outline: 'none', fontWeight: 800 }} 
              />
            </div>
          </div>

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
        <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
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
      </div>
    </div>
  );
}
