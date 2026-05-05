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

  useEffect(() => {
    fetchPonds();
  }, []);

  const fetchPonds = async () => {
    const { data } = await supabase.from('estanques').select('*').order('name');
    setPondsList(data || []);
  };

  const handleSave = async () => {
    if (!estanqueId) {
      alert("Por favor seleccione un estanque.");
      return;
    }

    const { error } = await supabase.from('water_quality').insert([{
      estanque_id: estanqueId,
      date: fecha,
      hour: hora,
      o2_mg_l: parseFloat(oxigeno) || 0,
      o2_perc: parseFloat(oxigenoPorc) || 0,
      ph: parseFloat(ph) || 0,
      ammonia_mg_l: parseFloat(amonia) || 0,
      nitrite_mg_l: parseFloat(nitrito) || 0,
      nitrate_mg_l: parseFloat(nitrato) || 0
    }]);

    if (error) {
      alert("Error al guardar: " + error.message);
    } else {
      alert("¡Registro de calidad de agua guardado con éxito!");
      // Reset fields
      setOxigeno('');
      setOxigenoPorc('');
      setPh('');
      setAmonia('');
      setNitrito('');
      setNitrato('');
    }
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
    <div className="animate-fade-in" style={{ maxWidth: '1200px', margin: '0 auto', paddingBottom: '4rem' }}>
      <header style={{ marginBottom: '2.5rem', display: 'flex', alignItems: 'center', gap: '1rem' }}>
        <Link href="/registros" style={{ color: 'var(--muted-foreground)', display: 'flex', alignItems: 'center', justifyContent: 'center', width: '40px', height: '40px', borderRadius: '50%', background: 'var(--card)', border: '1px solid var(--border)' }}>
          <ArrowLeft size={20} />
        </Link>
        <div>
          <h1 style={{ fontSize: '1.875rem', fontWeight: 700 }}>Calidad de Agua</h1>
          <p style={{ color: 'var(--muted-foreground)' }}>Monitoreo de parámetros físico-químicos del cultivo.</p>
        </div>
      </header>

      <div className="responsive-container">
        {/* Main Form Section */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem', flex: 1.5 }}>
          <div className="card-premium" style={{ padding: '2.5rem' }}>
            {/* Header Info */}
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(150px, 1fr))', gap: '1.5rem', marginBottom: '2.5rem' }}>
              <div className="premium-input-group">
                <label className="premium-label">Estanque</label>
                <div className="premium-input-wrapper">
                  <select
                    value={estanqueId}
                    onChange={(e) => setEstanqueId(e.target.value)}
                    style={{ width: '100%', background: 'transparent', border: 'none', outline: 'none', fontWeight: 700 }}
                  >
                    <option value="">Seleccionar...</option>
                    {pondsList.map(p => <option key={p.id} value={p.id}>{p.name}</option>)}
                  </select>
                </div>
              </div>
              <div className="premium-input-group">
                <label className="premium-label">
                  <Calendar size={14} /> Fecha
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
                  <Clock size={14} /> Hora
                </label>
                <div className="premium-input-wrapper">
                  <input 
                    type="time" 
                    value={hora} 
                    onChange={(e) => setHora(e.target.value)} 
                    className="premium-date-input"
                  />
                </div>
              </div>
            </div>

            {/* Parameters Grid */}
            <h2 style={{ fontSize: '1rem', fontWeight: 700, marginBottom: '1.5rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <FlaskConical size={20} style={{ color: 'var(--primary)' }} />
              Mediciones Técnicas
            </h2>

            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: '2rem' }}>
              {/* Column 1: Oxygen & pH */}
              <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
                <div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '0.5rem' }}>
                    <label style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Oxígeno Disuelto (mg/L)</label>
                    <span style={{ fontSize: '0.7rem', fontWeight: 700, color: '#3b82f6' }}>Rango: 5.0 - 8.0</span>
                  </div>
                  <input
                    type="number"
                    value={oxigeno}
                    onChange={(e) => setOxigeno(e.target.value)}
                    placeholder="0.0"
                    style={{ width: '100%', padding: '1rem', fontSize: '1.25rem', borderRadius: '12px', border: '1px solid', borderColor: parseFloat(oxigeno) < ranges.oxigeno.min ? '#ef4444' : 'var(--border)', background: 'var(--secondary)', outline: 'none', fontWeight: 800 }}
                  />
                </div>
                <div>
                  <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 700, marginBottom: '0.5rem', textTransform: 'uppercase', color: 'var(--muted-foreground)' }}>Concentración O2 (%)</label>
                  <input
                    type="number"
                    value={oxigenoPorc}
                    onChange={(e) => setOxigenoPorc(e.target.value)}
                    placeholder="0.0"
                    style={{ width: '100%', padding: '1rem', fontSize: '1.25rem', borderRadius: '12px', border: '1px solid var(--border)', background: 'var(--secondary)', outline: 'none', fontWeight: 800 }}
                  />
                </div>
                <div>
                  <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 700, marginBottom: '0.5rem', textTransform: 'uppercase', color: 'var(--muted-foreground)' }}>Nivel de pH</label>
                  <input
                    type="number"
                    value={ph}
                    onChange={(e) => setPh(e.target.value)}
                    placeholder="7.0"
                    style={{ width: '100%', padding: '1rem', fontSize: '1.25rem', borderRadius: '12px', border: '1px solid', borderColor: (parseFloat(ph) < ranges.ph.min || parseFloat(ph) > ranges.ph.max) ? '#f59e0b' : 'var(--border)', background: 'var(--secondary)', outline: 'none', fontWeight: 800 }}
                  />
                </div>
              </div>

              {/* Column 2: Nitrogen Compounds */}
              <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
                <div>
                  <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 700, marginBottom: '0.5rem', textTransform: 'uppercase', color: 'var(--muted-foreground)' }}>Amonia / Amonio (mg/L)</label>
                  <input
                    type="number"
                    value={amonia}
                    onChange={(e) => setAmonia(e.target.value)}
                    placeholder="0.00"
                    style={{ width: '100%', padding: '1rem', fontSize: '1.25rem', borderRadius: '12px', border: '1px solid var(--border)', background: 'var(--secondary)', outline: 'none', fontWeight: 800 }}
                  />
                </div>
                <div>
                  <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 700, marginBottom: '0.5rem', textTransform: 'uppercase', color: 'var(--muted-foreground)' }}>Nitrito (mg/L)</label>
                  <input
                    type="number"
                    value={nitrito}
                    onChange={(e) => setNitrito(e.target.value)}
                    placeholder="0.00"
                    style={{ width: '100%', padding: '1rem', fontSize: '1.25rem', borderRadius: '12px', border: '1px solid', borderColor: parseFloat(nitrito) > ranges.nitrito.max ? '#ef4444' : 'var(--border)', background: 'var(--secondary)', outline: 'none', fontWeight: 800 }}
                  />
                </div>
                <div>
                  <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 700, marginBottom: '0.5rem', textTransform: 'uppercase', color: 'var(--muted-foreground)' }}>Nitrato (mg/L)</label>
                  <input
                    type="number"
                    value={nitrato}
                    onChange={(e) => setNitrato(e.target.value)}
                    placeholder="0.00"
                    style={{ width: '100%', padding: '1rem', fontSize: '1.25rem', borderRadius: '12px', border: '1px solid var(--border)', background: 'var(--secondary)', outline: 'none', fontWeight: 800 }}
                  />
                </div>
              </div>
            </div>

            <button
              onClick={handleSave}
              className="btn-primary"
              style={{ width: '100%', marginTop: '3rem', padding: '1.25rem', borderRadius: '16px', background: 'var(--primary)', fontSize: '1.1rem', fontWeight: 800, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '0.75rem' }}
            >
              <Droplets size={22} />
              Guardar Registro de Agua
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
