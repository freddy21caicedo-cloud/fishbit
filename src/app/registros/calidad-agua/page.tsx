'use client';

import { useEffect, useState, useMemo } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  Plus,
  Droplets,
  Calendar,
  Clock,
  Waves,
  ArrowLeft,
  Activity,
  AlertTriangle,
  TrendingDown,
  TrendingUp,
  Thermometer,
  ShieldCheck,
  FlaskConical
} from 'lucide-react';
import Link from 'next/link';
import { toast } from 'react-hot-toast';
import { supabase } from '@/lib/supabase';

// Mock Ranges for Safety
const ranges = {
  oxigeno: { min: 4, opt: 6, max: 10 },
  ph: { min: 6.5, opt: 7.5, max: 8.5 },
  amonio: { max: 0.1 },
  nitrito: { max: 0.5 },
};

export default function CalidadAguaPage() {
  const [fecha, setFecha] = useState(new Date().toISOString().split('T')[0]);
  const [hora, setHora] = useState(new Date().toTimeString().slice(0, 5));
  const [estanqueId, setEstanqueId] = useState('');
  const [pondsList, setPondsList] = useState<any[]>([]);

  // Parameters
  const [oxigeno, setOxigeno] = useState('');
  const [oxigenoPorc, setOxigenoPorc] = useState('');
  const [ph, setPh] = useState('');
  const [amonia, setAmonia] = useState('');
  const [nitrito, setNitrito] = useState('');
  const [nitrato, setNitrato] = useState('');
  const [temperatura, setTemperatura] = useState('');
  const [alcalinidad, setAlcalinidad] = useState('');

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
    setPondsList(data || []);
  };

  const handleSave = async () => {
    if (!estanqueId) {
      toast.error("Por favor seleccione un estanque.");
      return;
    }

    const activeUnitId = localStorage.getItem('active_unit_id');

    toast.promise(
      (async () => {
        const { error } = await supabase.from('water_quality').insert([{
          estanque_id: estanqueId,
          unit_id: activeUnitId,
          date: fecha,
          hour: hora,
          o2_mg_l: parseFloat(oxigeno) || 0,
          o2_perc: parseFloat(oxigenoPorc) || 0,
          ph: parseFloat(ph) || 0,
          temperature_c: parseFloat(temperatura) || 0,
          alkalinity: parseFloat(alcalinidad) || 0,
          ammonia_mg_l: parseFloat(amonia) || 0,
          nitrite_mg_l: parseFloat(nitrito) || 0,
          nitrate_mg_l: parseFloat(nitrato) || 0
        }]);

        if (error) throw error;
        
        // Reset fields
        setOxigeno('');
        setOxigenoPorc('');
        setPh('');
        setAmonia('');
        setNitrito('');
        setNitrato('');
        setTemperatura('');
        setAlcalinidad('');
      })(),
      {
        loading: 'Guardando registro...',
        success: '¡Calidad de agua registrada con éxito!',
        error: (err) => `Error: ${err.message}`
      }
    );
  };

  // Status Analysis
  const analysis = useMemo(() => {
    const o2Val = parseFloat(oxigeno);
    const phVal = parseFloat(ph);
    const niVal = parseFloat(nitrito);

    let status = 'Estable';
    let color = '#10b981';
    let advice = 'Los parámetros se encuentran dentro de los rangos óptimos de producción.';

    if (o2Val && o2Val < ranges.oxigeno.min) {
      status = 'Crítico';
      color = '#ef4444';
      advice = 'Oxígeno bajo detectado. Active aireación de emergencia y suspenda alimentación.';
    } else if (phVal && (phVal < ranges.ph.min || phVal > ranges.ph.max)) {
      status = 'Alerta';
      color = '#f59e0b';
      advice = 'Nivel de pH fuera de rango. Verifique la alcalinidad y considere un recambio parcial de agua.';
    } else if (niVal && niVal > ranges.nitrito.max) {
      status = 'Peligro';
      color = '#ef4444';
      advice = 'Niveles de Nitrito elevados (tóxicos). Incremente la aireación y aplique sal si es necesario.';
    }

    return { status, color, advice };
  }, [oxigeno, ph, nitrito]);

  return (
    <div className="animate-fade-in page-container">
      <header style={{ marginBottom: '2rem', display: 'flex', alignItems: 'center', gap: '1rem' }}>
        <Link href="/registros" style={{ color: 'var(--muted-foreground)', display: 'flex', alignItems: 'center', justifyContent: 'center', width: '40px', height: '40px', borderRadius: '50%', background: 'var(--card)', border: '1px solid var(--border)' }}>
          <ArrowLeft size={20} />
        </Link>
        <div>
          <h1 style={{ fontWeight: 800 }}>Calidad de Agua</h1>
          <p style={{ color: 'var(--muted-foreground)', fontSize: '0.9rem' }}>Monitoreo de parámetros físico-químicos.</p>
        </div>
      </header>

      <div className="responsive-grid-2">
        <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
          <div className="card-premium" style={{ padding: '1.5rem' }}>
            <div style={{ display: 'grid', gridTemplateColumns: '1.5fr 1fr 1fr', gap: '1rem', marginBottom: '1.5rem' }}>
              <div className="premium-input-group">
                <label className="premium-label"><Waves size={14} /> Estanque</label>
                <select value={estanqueId} onChange={(e) => setEstanqueId(e.target.value)} className="premium-input" style={{ fontWeight: 700 }}>
                  <option value="">Seleccionar...</option>
                  {pondsList.map(p => <option key={p.id} value={p.id}>{p.name}</option>)}
                </select>
              </div>
              <div className="premium-input-group">
                <label className="premium-label"><Calendar size={14} /> Fecha</label>
                <input type="date" value={fecha} onChange={(e) => setFecha(e.target.value)} className="premium-input" />
              </div>
              <div className="premium-input-group">
                <label className="premium-label"><Clock size={14} /> Hora</label>
                <input type="time" value={hora} onChange={(e) => setHora(e.target.value)} className="premium-input" />
              </div>
            </div>

            <div className="responsive-grid-2">
              <div className="premium-input-group">
                <label className="premium-label"><Droplets size={14} /> Oxígeno (mg/L)</label>
                <input type="number" step="0.1" value={oxigeno} onChange={(e) => setOxigeno(e.target.value)} placeholder="0.0" className="premium-input" />
              </div>
            </div>

            <div className="responsive-grid-3">
              <div className="premium-input-group">
                <label className="premium-label">pH</label>
                <input type="number" step="0.1" value={ph} onChange={(e) => setPh(e.target.value)} placeholder="7.0" className="premium-input" />
              </div>
              <div className="premium-input-group">
                <label className="premium-label">Temperatura (°C)</label>
                <input type="number" step="0.1" value={temperatura} onChange={(e) => setTemperatura(e.target.value)} placeholder="28.5" className="premium-input" />
              </div>
              <div className="premium-input-group">
                <label className="premium-label">Alcalinidad</label>
                <input type="number" value={alcalinidad} onChange={(e) => setAlcalinidad(e.target.value)} placeholder="120" className="premium-input" />
              </div>
            </div>

            <div className="responsive-grid-3" style={{ marginTop: '1.5rem', marginBottom: '1.5rem' }}>
              <div className="premium-input-group">
                <label className="premium-label">Amonio (mg/L)</label>
                <input type="number" step="0.01" value={amonia} onChange={(e) => setAmonia(e.target.value)} placeholder="0.00" className="premium-input" />
              </div>
              <div className="premium-input-group">
                <label className="premium-label">Nitrito (mg/L)</label>
                <input type="number" step="0.01" value={nitrito} onChange={(e) => setNitrito(e.target.value)} placeholder="0.00" className="premium-input" />
              </div>
              <div className="premium-input-group">
                <label className="premium-label">Nitrato (mg/L)</label>
                <input type="number" step="0.01" value={nitrato} onChange={(e) => setNitrato(e.target.value)} placeholder="0.00" className="premium-input" />
              </div>
            </div>

            <button onClick={handleSave} className="btn-primary" style={{ width: '100%', padding: '1rem', borderRadius: '12px', fontWeight: 800, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '0.5rem' }}>
              <ShieldCheck size={18} />
              Guardar Registro
            </button>
          </div>
        </div>

        {/* Status & Analysis Sidebar */}
        <div className="responsive-side-panel" style={{ display: 'flex', flexDirection: 'column', gap: '2rem', flex: 1 }}>
          {/* Real-time Analysis Card */}
          <div className="card-premium" style={{ padding: '2rem', textAlign: 'center' }}>
            <h3 style={{ fontSize: '0.85rem', fontWeight: 700, color: 'var(--muted-foreground)', textTransform: 'uppercase', marginBottom: '1.5rem' }}>Estado del Estanque</h3>

            <div style={{ position: 'relative', marginBottom: '1.5rem' }}>
              <motion.div
                animate={{ scale: [1, 1.02, 1] }}
                transition={{ duration: 2, repeat: Infinity }}
                style={{
                  fontSize: '2rem',
                  fontWeight: 900,
                  color: analysis.color,
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  gap: '0.75rem'
                }}
              >
                {analysis.status === 'Estable' ? <ShieldCheck size={40} /> : <AlertTriangle size={40} />}
                {analysis.status}
              </motion.div>
            </div>

            <div style={{
              padding: '1.25rem',
              borderRadius: '16px',
              background: 'var(--secondary)',
              border: '1px solid var(--border)',
              textAlign: 'left'
            }}>
              <div style={{ fontWeight: 800, fontSize: '0.85rem', color: analysis.color, marginBottom: '0.5rem', textTransform: 'uppercase' }}>Recomendación Técnica:</div>
              <p style={{ fontSize: '0.85rem', color: 'var(--muted-foreground)', lineHeight: 1.5 }}>
                {analysis.advice}
              </p>
            </div>
          </div>

          {/* Parameters Guide Card */}
          <div className="card-premium" style={{ padding: '1.5rem' }}>
            <h3 style={{ fontSize: '0.85rem', fontWeight: 700, color: 'var(--muted-foreground)', textTransform: 'uppercase', marginBottom: '1rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <TrendingUp size={16} /> Rangos de Referencia
            </h3>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.85rem', borderBottom: '1px solid var(--border)', paddingBottom: '0.5rem' }}>
                <span>Oxígeno (mg/L)</span>
                <span style={{ fontWeight: 700 }}>5.0 - 8.0</span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.85rem', borderBottom: '1px solid var(--border)', paddingBottom: '0.5rem' }}>
                <span>pH</span>
                <span style={{ fontWeight: 700 }}>7.0 - 8.0</span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.85rem', borderBottom: '1px solid var(--border)', paddingBottom: '0.5rem' }}>
                <span>Amonio (mg/L)</span>
                <span style={{ fontWeight: 700 }}>&lt; 0.05</span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.85rem' }}>
                <span>Nitrito (mg/L)</span>
                <span style={{ fontWeight: 700 }}>&lt; 0.1</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
