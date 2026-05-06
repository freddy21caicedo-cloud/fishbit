'use client';

import { useEffect, useState, useMemo } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  Plus, 
  Trash2, 
  Calendar, 
  Clock, 
  Waves, 
  FlaskConical, 
  AlertCircle,
  ArrowLeft,
  Activity,
  Syringe,
  Scale
} from 'lucide-react';
import Link from 'next/link';
import { useSearchParams, useRouter } from 'next/navigation';
import { toast } from 'react-hot-toast';
import { supabase } from '@/lib/supabase';

interface TreatmentRow {
  id: string;
  producto_id: string;
  producto_nombre: string;
  dosis: string;
  unidad: string;
}

export default function TratamientoPage() {
  const searchParams = useSearchParams();
  const router = useRouter();
  const estanqueParam = searchParams.get('estanque');

  const [fecha, setFecha] = useState(new Date().toISOString().split('T')[0]);
  const [hora, setHora] = useState(new Date().toTimeString().slice(0, 5));
  const [estanqueId, setEstanqueId] = useState(estanqueParam || '');
  const [tipo, setTipo] = useState('Preventivo');
  const [loading, setLoading] = useState(false);
  
  const [inventory, setInventory] = useState<any[]>([]);
  const [ponds, setPonds] = useState<any[]>([]);
  const [rows, setRows] = useState<TreatmentRow[]>([
    { id: '1', producto_id: '', producto_nombre: '', dosis: '', unidad: 'gr' }
  ]);

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    try {
      const activeUnitId = localStorage.getItem('active_unit_id');
      const { data: invData } = await supabase
        .from('inventory')
        .select('*')
        .in('category', ['farmacia', 'insumos'])
        .eq('unit_id', activeUnitId);
      setInventory(invData || []);

      const { data: pondData } = await supabase.from('estanques').select('*').eq('unit_id', activeUnitId);
      setPonds(pondData || []);
    } catch (error: any) {
      toast.error("Error al cargar datos: " + error.message);
    }
  };

  const selectedPond = useMemo(() => ponds.find(p => p.id === estanqueId), [estanqueId, ponds]);

  const addRow = () => {
    setRows([...rows, { id: Math.random().toString(), producto_id: '', producto_nombre: '', dosis: '', unidad: 'gr' }]);
  };

  const removeRow = (id: string) => {
    if (rows.length > 1) {
      setRows(rows.filter(row => row.id !== id));
    }
  };

  const updateRow = (id: string, field: keyof TreatmentRow, value: string) => {
    if (field === 'producto_id') {
      const prod = inventory.find(i => i.id === value);
      setRows(rows.map(row => row.id === id ? { 
        ...row, 
        producto_id: value, 
        producto_nombre: prod?.name || '', 
        unidad: prod?.unit || 'uds' 
      } : row));
    } else {
      setRows(rows.map(row => row.id === id ? { ...row, [field]: value } : row));
    }
  };

  const handleRegisterTreatment = async () => {
    if (!estanqueId || rows.some(r => !r.producto_id || !r.dosis)) {
      toast.error("Por favor complete todos los campos.");
      return;
    }

    setLoading(true);
    const registerPromise = async () => {
      const activeUnitId = localStorage.getItem('active_unit_id');
      
      const { data: tData, error: tErr } = await supabase
        .from('tratamientos')
        .insert([{
          estanque_id: estanqueId,
          unit_id: activeUnitId,
          type: tipo,
          date: fecha,
          hour: hora,
          observations: `Tratamiento ${tipo} aplicado.`
        }])
        .select();

      if (tErr || !tData) throw tErr || new Error("Error al registrar cabecera");

      const tratamientoId = tData[0].id;

      const operations = rows.map(async (row) => {
        const prod = inventory.find(i => i.id === row.producto_id);
        if (prod) {
          const dosageValue = parseFloat(row.dosis) || 0;
          
          const { error: detailError } = await supabase.from('tratamiento_details').insert([{
            tratamiento_id: tratamientoId,
            unit_id: activeUnitId,
            inventory_id: row.producto_id,
            product_name: row.producto_nombre,
            dosage: dosageValue,
            unit: row.unidad
          }]);
          if (detailError) throw detailError;

          const newStock = (Number(prod.current_stock) || 0) - dosageValue;
          const { error: invError } = await supabase.from('inventory').update({ current_stock: newStock }).eq('id', prod.id);
          if (invError) throw invError;
        }
      });

      await Promise.all(operations);
    };

    toast.promise(registerPromise(), {
      loading: 'Registrando tratamiento...',
      success: () => {
        setRows([{ id: '1', producto_id: '', producto_nombre: '', dosis: '', unidad: 'gr' }]);
        fetchData(); // Refresh inventory
        return "¡Tratamiento registrado con éxito!";
      },
      error: (err) => `Error: ${err.message}`
    }).finally(() => setLoading(false));
  };

  return (
    <div className="animate-fade-in page-container">
      <header style={{ marginBottom: '2.5rem', display: 'flex', alignItems: 'center', gap: '1.5rem' }}>
        <Link href="/registros" className="btn-secondary" style={{ width: '48px', height: '48px', borderRadius: '16px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <ArrowLeft size={24} />
        </Link>
        <div>
          <h1 style={{ fontSize: '2.2rem', fontWeight: 900, letterSpacing: '-0.02em' }}>Registro de Tratamiento</h1>
          <p style={{ color: 'var(--muted-foreground)', fontSize: '1rem' }}>Gestión sanitaria y aplicación de insumos de farmacia.</p>
        </div>
      </header>

      <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
        <div className="card-premium" style={{ padding: '2rem', display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '1.5rem', alignItems: 'center' }}>
          <div className="premium-input-group">
            <label className="premium-label">Estanque</label>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', padding: '0.75rem', background: 'rgba(13, 148, 136, 0.05)', borderRadius: '12px', border: '1px solid rgba(13, 148, 136, 0.1)', height: '56px' }}>
              <Waves size={20} style={{ color: '#0d9488' }} />
              <span style={{ fontSize: '1.1rem', fontWeight: 800, color: '#0d9488' }}>
                {selectedPond ? selectedPond.name : '---'}
              </span>
            </div>
          </div>
          <div className="premium-input-group">
            <label className="premium-label">Fecha</label>
            <input type="date" value={fecha} onChange={(e) => setFecha(e.target.value)} className="premium-input" />
          </div>
          <div className="premium-input-group">
            <label className="premium-label">Hora</label>
            <input type="time" value={hora} onChange={(e) => setHora(e.target.value)} className="premium-input" />
          </div>
          <div className="premium-input-group">
            <label className="premium-label">Tipo de Tratamiento</label>
            <select value={tipo} onChange={(e) => setTipo(e.target.value)} className="premium-input" style={{ fontWeight: 700 }}>
              <option value="Preventivo">🛡️ Preventivo</option>
              <option value="Curativo">💊 Curativo</option>
              <option value="Desinfección">✨ Desinfección</option>
            </select>
          </div>
        </div>

        <div className="card-premium" style={{ padding: '2rem' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2.5rem' }}>
            <h2 style={{ fontSize: '1.3rem', fontWeight: 900, display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
              <Syringe size={28} style={{ color: '#0d9488' }} />
              Insumos Aplicados
            </h2>
            <button onClick={addRow} className="btn-secondary" style={{ padding: '0.75rem 1.5rem', borderRadius: '12px', fontSize: '0.9rem', fontWeight: 800 }}>
              <Plus size={20} /> Añadir Insumo
            </button>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
            <AnimatePresence mode="popLayout">
              {rows.map((row) => {
                const stockItem = inventory.find(s => s.id === row.producto_id);
                const stockAvailable = stockItem?.current_stock || 0;
                const unidad = stockItem?.unit || 'uds';

                return (
                  <motion.div 
                    key={row.id}
                    initial={{ opacity: 0, x: -20 }}
                    animate={{ opacity: 1, x: 0 }}
                    exit={{ opacity: 0, x: 20 }}
                    style={{ 
                      display: 'grid', 
                      gridTemplateColumns: '1.5fr 1fr auto', 
                      gap: '1.5rem', 
                      alignItems: 'center',
                      padding: '1.5rem',
                      background: 'var(--secondary)',
                      borderRadius: '20px',
                      border: '1px solid var(--border)',
                    }}
                  >
                    <div className="premium-input-group">
                      <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '0.5rem', position: 'absolute', top: '-25px', right: '5px', width: 'auto' }}>
                        <span style={{ fontSize: '0.7rem', fontWeight: 900, color: stockAvailable < 10 ? '#ef4444' : '#0d9488', background: 'var(--card)', padding: '2px 8px', borderRadius: '4px', border: '1px solid var(--border)' }}>
                          STOCK: {Number(stockAvailable).toLocaleString()} {unidad}
                        </span>
                      </div>
                      <label className="premium-label">Producto / Insumo</label>
                      <select 
                        value={row.producto_id}
                        onChange={(e) => updateRow(row.id, 'producto_id', e.target.value)}
                        className="premium-input"
                        style={{ fontWeight: 800 }}
                      >
                        <option value="">Seleccionar...</option>
                        {inventory.map(s => <option key={s.id} value={s.id}>{s.name}</option>)}
                      </select>
                    </div>
                    <div className="premium-input-group">
                      <label className="premium-label">Dosis / Cantidad</label>
                      <div style={{ display: 'flex', alignItems: 'center', background: 'var(--card)', borderRadius: '12px', border: '1px solid var(--border)', paddingRight: '1rem' }}>
                        <input 
                          type="number" 
                          value={row.dosis}
                          onChange={(e) => updateRow(row.id, 'dosis', e.target.value)}
                          placeholder="0.0"
                          style={{ width: '100%', padding: '0.85rem', border: 'none', background: 'transparent', outline: 'none', fontWeight: 900, fontSize: '1.1rem' }}
                        />
                        <span style={{ fontWeight: 900, fontSize: '0.9rem', color: 'var(--muted-foreground)' }}>{unidad}</span>
                      </div>
                    </div>
                    <button 
                      onClick={() => removeRow(row.id)}
                      style={{ background: 'transparent', border: 'none', color: '#ef4444', cursor: 'pointer', opacity: rows.length > 1 ? 0.8 : 0.2, padding: '0.5rem' }}
                      disabled={rows.length <= 1}
                    >
                      <Trash2 size={24} />
                    </button>
                  </motion.div>
                );
              })}
            </AnimatePresence>
          </div>

          <div style={{ marginTop: '3rem', padding: '1.5rem', background: 'rgba(13, 148, 136, 0.05)', borderRadius: '20px', border: '1px solid rgba(13, 148, 136, 0.1)', display: 'flex', alignItems: 'center', gap: '1.5rem' }}>
            <div style={{ width: '56px', height: '56px', borderRadius: '16px', background: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#0d9488', boxShadow: 'var(--shadow-sm)' }}>
              <Scale size={32} />
            </div>
            <div>
              <div style={{ fontSize: '0.8rem', fontWeight: 800, color: 'var(--muted-foreground)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Biomasa de Referencia</div>
              <div style={{ fontSize: '1.5rem', fontWeight: 900, color: '#0d9488' }}>
                {selectedPond ? `${Number(selectedPond.current_biomass_kg).toFixed(2)} kg` : '-- kg'}
              </div>
            </div>
          </div>
          
          <button 
            onClick={handleRegisterTreatment}
            disabled={loading}
            className="btn-primary" 
            style={{ 
              width: '100%', 
              marginTop: '2.5rem', 
              padding: '1.5rem', 
              background: '#0d9488', 
              fontSize: '1.2rem', 
              fontWeight: 900, 
              borderRadius: '20px',
              boxShadow: '0 10px 25px -5px rgba(13, 148, 136, 0.4)'
            }}
          >
            {loading ? <Activity className="animate-spin" size={20} /> : <Syringe size={20} />}
            Registrar Aplicación Médica
          </button>
        </div>

        <div style={{ 
          padding: '2rem', 
          borderRadius: '28px', 
          background: 'var(--card)', 
          border: '1px solid var(--border)',
          display: 'flex', 
          gap: '1.5rem', 
          alignItems: 'center'
        }}>
          <div style={{ width: '56px', height: '56px', borderRadius: '50%', background: 'rgba(245, 158, 11, 0.1)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
            <AlertCircle size={32} style={{ color: '#f59e0b' }} />
          </div>
          <div>
            <h4 style={{ fontWeight: 900, fontSize: '1.1rem', color: '#b45309', marginBottom: '0.4rem' }}>Protocolo de Bioseguridad</h4>
            <p style={{ fontSize: '0.95rem', color: 'var(--muted-foreground)', lineHeight: 1.6 }}>
              Asegúrese de documentar el lote de los insumos y respetar los tiempos de retiro antes de la cosecha. Mantenga la aireación constante.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
