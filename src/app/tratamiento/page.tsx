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
import { useSearchParams } from 'next/navigation';
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
  const estanqueParam = searchParams.get('estanque');

  const [fecha, setFecha] = useState(new Date().toISOString().split('T')[0]);
  const [hora, setHora] = useState(new Date().toTimeString().slice(0, 5));
  const [estanqueId, setEstanqueId] = useState(estanqueParam || '');
  const [tipo, setTipo] = useState('Preventivo');
  
  const [inventory, setInventory] = useState<any[]>([]);
  const [ponds, setPonds] = useState<any[]>([]);
  const [rows, setRows] = useState<TreatmentRow[]>([
    { id: '1', producto_id: '', producto_nombre: '', dosis: '', unidad: 'gr' }
  ]);

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    const { data: invData } = await supabase.from('inventory').select('*').in('category', ['medicamentos', 'insumos']);
    setInventory(invData || []);

    const { data: pondData } = await supabase.from('estanques').select('*');
    setPonds(pondData || []);
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
      alert("Por favor complete todos los campos.");
      return;
    }

    // 1. Create Treatment Header
    const { data: tData, error: tErr } = await supabase
      .from('tratamientos')
      .insert([{
        estanque_id: estanqueId,
        type: tipo,
        date: fecha,
        hour: hora,
        observations: `Tratamiento ${tipo} aplicado.`
      }])
      .select();

    if (tErr || !tData) {
      alert("Error al registrar cabecera: " + tErr.message);
      return;
    }

    const tratamientoId = tData[0].id;

    // 2. Register Details and Update Inventory
    for (const row of rows) {
      const prod = inventory.find(i => i.id === row.producto_id);
      if (prod) {
        // A. Insert Detail
        await supabase.from('tratamiento_details').insert([{
          tratamiento_id: tratamientoId,
          inventory_id: row.producto_id,
          product_name: row.producto_nombre,
          dosage: parseFloat(row.dosis) || 0,
          unit: row.unidad
        }]);

        // B. Update Inventory
        const newStock = (parseFloat(prod.current_stock) || 0) - (parseFloat(row.dosis) || 0);
        await supabase.from('inventory').update({ current_stock: newStock }).eq('id', prod.id);
      }
    }

    alert("¡Tratamiento registrado con éxito! El historial y el inventario han sido actualizados.");
    window.location.href = '/estanques';
  };

  return (
    <div className="animate-fade-in" style={{ maxWidth: '1000px', margin: '0 auto', paddingBottom: '4rem' }}>
      <header style={{ marginBottom: '2.5rem', display: 'flex', alignItems: 'center', gap: '1rem' }}>
        <Link href="/estanques" style={{ color: 'var(--muted-foreground)', display: 'flex', alignItems: 'center', justifyContent: 'center', width: '40px', height: '40px', borderRadius: '50%', background: 'var(--card)', border: '1px solid var(--border)' }}>
          <ArrowLeft size={20} />
        </Link>
        <div>
          <h1 style={{ fontSize: '1.875rem', fontWeight: 700 }}>Registro de Tratamiento</h1>
          <p style={{ color: 'var(--muted-foreground)' }}>Gestión sanitaria y aplicación de insumos de farmacia.</p>
        </div>
      </header>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr', gap: '2rem' }}>
        {/* Contextual Info Card */}
        <div className="card-premium" style={{ padding: '2rem', display: 'grid', gridTemplateColumns: '1.2fr 1fr 1fr 1.2fr', gap: '1.5rem', alignItems: 'center' }}>
          <div>
            <div style={{ fontSize: '0.75rem', fontWeight: 700, marginBottom: '0.5rem', textTransform: 'uppercase', color: 'var(--muted-foreground)' }}>Estanque</div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', padding: '0.75rem', background: 'rgba(13, 148, 136, 0.05)', borderRadius: '8px', border: '1px solid rgba(13, 148, 136, 0.1)' }}>
              <Waves size={20} style={{ color: '#0d9488' }} />
              <span style={{ fontSize: '1.1rem', fontWeight: 800, color: '#0d9488' }}>
                {selectedPond ? selectedPond.name : 'Seleccionado'}
              </span>
            </div>
          </div>
          <div>
            <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 700, marginBottom: '0.5rem', textTransform: 'uppercase', color: 'var(--muted-foreground)' }}>Fecha</label>
            <input type="date" value={fecha} onChange={(e) => setFecha(e.target.value)} style={{ width: '100%', padding: '0.75rem', borderRadius: '8px', border: '1px solid var(--border)', background: 'var(--secondary)', outline: 'none' }} />
          </div>
          <div>
            <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 700, marginBottom: '0.5rem', textTransform: 'uppercase', color: 'var(--muted-foreground)' }}>Hora</label>
            <input type="time" value={hora} onChange={(e) => setHora(e.target.value)} style={{ width: '100%', padding: '0.75rem', borderRadius: '8px', border: '1px solid var(--border)', background: 'var(--secondary)', outline: 'none' }} />
          </div>
          <div>
            <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 700, marginBottom: '0.5rem', textTransform: 'uppercase', color: 'var(--muted-foreground)' }}>Tipo</label>
            <select value={tipo} onChange={(e) => setTipo(e.target.value)} style={{ width: '100%', padding: '0.75rem', borderRadius: '8px', border: '1px solid var(--border)', background: 'var(--secondary)', outline: 'none', fontWeight: 600 }}>
              <option value="Preventivo">🛡️ Preventivo</option>
              <option value="Curativo">💊 Curativo</option>
              <option value="Desinfección">✨ Desinfección</option>
            </select>
          </div>
        </div>

        {/* Pharmacy Details Card */}
        <div className="card-premium" style={{ padding: '2rem' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
            <h2 style={{ fontSize: '1.25rem', fontWeight: 700, display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
              <Syringe size={24} style={{ color: '#0d9488' }} />
              Insumos de Farmacia Aplicados
            </h2>
            <button onClick={addRow} style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', padding: '0.5rem 1rem', borderRadius: '8px', border: '1px solid #0d9488', color: '#0d9488', background: 'transparent', fontWeight: 600, cursor: 'pointer' }}>
              <Plus size={18} />
              Añadir Insumo
            </button>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
            <AnimatePresence mode="popLayout">
              {rows.map((row) => {
                const stockItem = inventory.find(s => s.id === row.producto_id);
                const stockAvailable = stockItem?.current_stock || 0;
                const unidad = stockItem?.unit || 'uds';

                return (
                  <motion.div 
                    key={row.id}
                    initial={{ opacity: 0, y: 10 }}
                    animate={{ opacity: 1, y: 0 }}
                    exit={{ opacity: 0, scale: 0.95 }}
                    style={{ 
                      display: 'grid', 
                      gridTemplateColumns: '2fr 1.5fr 40px', 
                      gap: '1.5rem', 
                      alignItems: 'flex-end',
                      padding: '1.5rem',
                      background: 'var(--card)',
                      borderRadius: '16px',
                      border: '1px solid var(--border)',
                      boxShadow: 'var(--shadow-sm)'
                    }}
                  >
                    <div>
                      <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '0.5rem' }}>
                        <label style={{ fontSize: '0.7rem', fontWeight: 700, color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Producto Farmacéutico</label>
                        <span style={{ fontSize: '0.7rem', fontWeight: 700, color: stockAvailable < 10 ? '#ef4444' : '#0d9488' }}>
                          Stock: {stockAvailable.toLocaleString()} {unidad}
                        </span>
                      </div>
                      <select 
                        value={row.producto_id}
                        onChange={(e) => updateRow(row.id, 'producto_id', e.target.value)}
                        style={{ width: '100%', padding: '0.75rem', borderRadius: '8px', border: '1px solid var(--border)', background: 'var(--secondary)', outline: 'none', fontWeight: 600 }}
                      >
                        <option value="">-- Seleccionar --</option>
                        {inventory.map(s => <option key={s.id} value={s.id}>{s.name}</option>)}
                      </select>
                    </div>
                    <div>
                      <label style={{ fontSize: '0.7rem', fontWeight: 700, color: 'var(--muted-foreground)', marginBottom: '0.5rem', textTransform: 'uppercase', display: 'block' }}>Dosis / Cantidad</label>
                      <div style={{ display: 'flex', alignItems: 'center', background: 'var(--secondary)', borderRadius: '8px', border: '1px solid var(--border)', paddingRight: '0.75rem' }}>
                        <input 
                          type="number" 
                          value={row.dosis}
                          onChange={(e) => updateRow(row.id, 'dosis', e.target.value)}
                          placeholder="0.0"
                          style={{ width: '100%', padding: '0.75rem', border: 'none', background: 'transparent', outline: 'none', fontWeight: 700 }}
                        />
                        <span style={{ fontWeight: 700, fontSize: '0.8rem', color: 'var(--muted-foreground)' }}>{unidad}</span>
                      </div>
                    </div>
                    <button 
                      onClick={() => removeRow(row.id)}
                      style={{ background: 'transparent', border: 'none', color: '#ef4444', cursor: 'pointer', opacity: rows.length > 1 ? 0.6 : 0.2, marginBottom: '10px' }}
                      disabled={rows.length <= 1}
                    >
                      <Trash2 size={20} />
                    </button>
                  </motion.div>
                );
              })}
            </AnimatePresence>
          </div>

          <div style={{ marginTop: '2rem', padding: '1.25rem', background: 'rgba(13, 148, 136, 0.05)', borderRadius: '12px', border: '1px solid rgba(13, 148, 136, 0.1)', display: 'flex', alignItems: 'center', gap: '1rem' }}>
            <Scale size={24} style={{ color: '#0d9488' }} />
            <div>
              <div style={{ fontSize: '0.7rem', fontWeight: 700, color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Referencia de Biomasa en Estanque</div>
              <div style={{ fontSize: '1.1rem', fontWeight: 800, color: '#0d9488' }}>
                {selectedPond ? `${parseFloat(selectedPond.current_biomass_kg).toFixed(2)} kg` : '-- kg'}
              </div>
            </div>
          </div>
          
          <button 
            onClick={handleRegisterTreatment}
            className="btn-primary" 
            style={{ width: '100%', marginTop: '2rem', padding: '1rem', background: '#0d9488', border: 'none', fontSize: '1rem', fontWeight: 700 }}
          >
            Registrar Aplicación Médica
          </button>
        </div>

        {/* Safety Recommendation Banner */}
        <div style={{ 
          padding: '1.5rem', 
          borderRadius: '20px', 
          background: 'linear-gradient(to right, rgba(245, 158, 11, 0.05), rgba(245, 158, 11, 0.01))', 
          borderLeft: '5px solid #f59e0b',
          display: 'flex', 
          gap: '1.25rem', 
          alignItems: 'center',
          boxShadow: 'var(--shadow-sm)'
        }}>
          <div style={{ 
            width: '45px', 
            height: '45px', 
            borderRadius: '12px', 
            background: 'white', 
            display: 'flex', 
            alignItems: 'center', 
            justifyContent: 'center',
            color: '#f59e0b',
            boxShadow: '0 4px 6px -1px rgba(0,0,0,0.05)'
          }}>
            <AlertCircle size={28} />
          </div>
          <div style={{ flex: 1 }}>
            <h4 style={{ fontWeight: 800, fontSize: '1rem', marginBottom: '0.25rem', color: '#f59e0b' }}>
              ⚠️ Recordatorio de Seguridad Sanitaria
            </h4>
            <p style={{ fontSize: '0.95rem', color: 'var(--muted-foreground)', lineHeight: 1.5 }}>
              Verifica si el tratamiento requiere <strong>suspender la alimentación</strong> y asegúrate de mantener la aireación al máximo durante la aplicación. Monitorea el comportamiento de los peces cada 30 minutos.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
