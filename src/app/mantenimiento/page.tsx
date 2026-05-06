'use client';

import { useEffect, useState, useMemo } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  Plus, 
  Trash2, 
  Calendar, 
  Clock, 
  Waves, 
  Settings, 
  AlertCircle,
  ArrowLeft,
  Wrench,
  CheckCircle2,
  Shovel,
  ShieldAlert
} from 'lucide-react';
import Link from 'next/link';
import { useSearchParams, useRouter } from 'next/navigation';
import { toast } from 'react-hot-toast';
import { supabase } from '@/lib/supabase';

interface MaintRow {
  id: string;
  producto_id: string;
  producto_nombre: string;
  cantidad: string;
  unidad: string;
}

export default function MantenimientoPage() {
  const searchParams = useSearchParams();
  const router = useRouter();
  const estanqueParam = searchParams.get('estanque');

  const [fecha, setFecha] = useState(new Date().toISOString().split('T')[0]);
  const [hora, setHora] = useState(new Date().toTimeString().slice(0, 5));
  const [estanqueId, setEstanqueId] = useState(estanqueParam || '');
  const [actividad, setActividad] = useState('Encalado');
  const [loading, setLoading] = useState(false);
  
  const [inventory, setInventory] = useState<any[]>([]);
  const [ponds, setPonds] = useState<any[]>([]);
  const [rows, setRows] = useState<MaintRow[]>([
    { id: '1', producto_id: '', producto_nombre: '', cantidad: '', unidad: 'kg' }
  ]);

  const [tasks, setTasks] = useState([
    { id: 't1', label: 'Lavado de paredes y fondo', done: false },
    { id: 't2', label: 'Secado al sol (Sanitización)', done: false },
    { id: 't3', label: 'Revisión de mallas y compuertas', done: false },
    { id: 't4', label: 'Reparación de filtraciones', done: false },
  ]);

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    try {
      const activeUnitId = localStorage.getItem('active_unit_id');
      const { data: invData } = await supabase.from('inventory').select('*').in('category', ['insumos', 'agrícola']).eq('unit_id', activeUnitId);
      setInventory(invData || []);

      const { data: pondData } = await supabase.from('estanques').select('*').eq('unit_id', activeUnitId);
      setPonds(pondData || []);
    } catch (error: any) {
      toast.error("Error al cargar datos: " + error.message);
    }
  };

  const selectedPond = useMemo(() => ponds.find(p => p.id === estanqueId), [estanqueId, ponds]);

  const toggleTask = (id: string) => {
    setTasks(tasks.map(t => t.id === id ? { ...t, done: !t.done } : t));
  };

  const addRow = () => {
    setRows([...rows, { id: Math.random().toString(), producto_id: '', producto_nombre: '', cantidad: '', unidad: 'kg' }]);
  };

  const removeRow = (id: string) => {
    if (rows.length > 1) {
      setRows(rows.filter(row => row.id !== id));
    }
  };

  const updateRow = (id: string, field: keyof MaintRow, value: string) => {
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

  const handleFinalizeMaintenance = async () => {
    const allTasksDone = tasks.every(t => t.done);
    const atLeastOneInsumo = rows.some(r => r.producto_id && (parseFloat(r.cantidad) || 0) > 0);

    if (!estanqueId) {
      toast.error("Por favor seleccione un estanque.");
      return;
    }

    if (!allTasksDone) {
      toast.error("Debe completar todas las tareas de la lista para garantizar la sanidad del estanque.");
      return;
    }

    setLoading(true);
    const registerPromise = async () => {
      const activeUnitId = localStorage.getItem('active_unit_id');
      
      const { error: logErr } = await supabase.from('mantenimiento_logs').insert([{
        estanque_id: estanqueId,
        unit_id: activeUnitId,
        type: actividad,
        description: `Actividad: ${actividad}. Tareas completadas: ${tasks.filter(t => t.done).map(t => t.label).join(', ')}`,
        date: fecha
      }]);

      if (logErr) throw logErr;

      const operations = rows.map(async (row) => {
        if (row.producto_id && row.cantidad) {
          const prod = inventory.find(i => i.id === row.producto_id);
          if (prod) {
            const qtyValue = parseFloat(row.cantidad) || 0;
            const newStock = (parseFloat(prod.current_stock) || 0) - qtyValue;
            const { error: invError } = await supabase.from('inventory').update({ current_stock: newStock }).eq('id', prod.id);
            if (invError) throw invError;
          }
        }
      });

      await Promise.all(operations);
    };

    toast.promise(registerPromise(), {
      loading: 'Registrando mantenimiento...',
      success: () => {
        setRows([{ id: '1', producto_id: '', producto_nombre: '', cantidad: '', unidad: 'kg' }]);
        setTasks(tasks.map(t => ({ ...t, done: false })));
        fetchData();
        return "¡Mantenimiento registrado con éxito!";
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
          <h1 style={{ fontSize: '2.2rem', fontWeight: 900, letterSpacing: '-0.02em' }}>Mantenimiento y Preparación</h1>
          <p style={{ color: 'var(--muted-foreground)', fontSize: '1rem' }}>Acondicionamiento de estanques para el próximo ciclo.</p>
        </div>
      </header>

      <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
        <div className="card-premium" style={{ padding: '2rem', display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '1.5rem', alignItems: 'center' }}>
          <div className="premium-input-group">
            <label className="premium-label">Estanque</label>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', padding: '0.75rem', background: 'rgba(71, 85, 105, 0.05)', borderRadius: '12px', border: '1px solid rgba(71, 85, 105, 0.1)', height: '56px' }}>
              <Waves size={20} style={{ color: 'var(--muted-foreground)' }} />
              <span style={{ fontSize: '1.1rem', fontWeight: 800 }}>
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
            <label className="premium-label">Actividad Principal</label>
            <select value={actividad} onChange={(e) => setActividad(e.target.value)} className="premium-input" style={{ fontWeight: 700 }}>
              <option value="Encalado">🧹 Encalado (Desinfección)</option>
              <option value="Maleza">🌿 Control de Malezas</option>
              <option value="Diques">🏗️ Reparación de Diques</option>
              <option value="Plagas">🚫 Control de Plagas</option>
            </select>
          </div>
        </div>

        <div className="responsive-grid-2">
          <div className="card-premium" style={{ padding: '2rem' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem', flexWrap: 'wrap', gap: '1rem' }}>
              <h2 style={{ fontSize: '1.1rem', fontWeight: 800, display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                <Shovel size={24} style={{ color: 'var(--primary)' }} />
                Insumos Aplicados
              </h2>
              <button onClick={addRow} style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', padding: '0.6rem 1.25rem', borderRadius: '10px', border: '1px solid var(--primary)', color: 'var(--primary)', background: 'transparent', fontWeight: 800, cursor: 'pointer' }}>
                <Plus size={18} />
                Añadir
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
                      className="glass"
                      style={{ 
                        display: 'grid', 
                        gridTemplateColumns: '1.2fr 1fr auto', 
                        gap: '1rem', 
                        alignItems: 'flex-end',
                        padding: '1.25rem',
                        borderRadius: '12px',
                        border: '1px solid var(--border)'
                      }}
                    >
                      <div>
                        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '0.4rem' }}>
                          <label className="premium-label">Producto</label>
                          <span style={{ fontSize: '0.65rem', fontWeight: 800, color: 'var(--primary)' }}>Stock: {stockAvailable} {unidad}</span>
                        </div>
                        <select 
                          value={row.producto_id}
                          onChange={(e) => updateRow(row.id, 'producto_id', e.target.value)}
                          className="premium-input"
                          style={{ width: '100%', fontWeight: 700 }}
                        >
                          <option value="">Seleccionar...</option>
                          {inventory.map(s => <option key={s.id} value={s.id}>{s.name}</option>)}
                        </select>
                      </div>
                      <div>
                        <label className="premium-label">Cantidad</label>
                        <div style={{ display: 'flex', alignItems: 'center', background: 'var(--secondary)', borderRadius: '10px', border: '1px solid var(--border)', paddingRight: '0.75rem' }}>
                          <input 
                            type="number" 
                            value={row.cantidad}
                            onChange={(e) => updateRow(row.id, 'cantidad', e.target.value)}
                            placeholder="0.0"
                            style={{ width: '100%', padding: '0.625rem', border: 'none', background: 'transparent', outline: 'none', fontWeight: 800 }}
                          />
                          <span style={{ fontWeight: 800, fontSize: '0.8rem', color: 'var(--muted-foreground)' }}>{unidad}</span>
                        </div>
                      </div>
                      <button 
                        onClick={() => removeRow(row.id)}
                        style={{ background: 'transparent', border: 'none', color: '#ef4444', cursor: 'pointer', opacity: rows.length > 1 ? 0.6 : 0.2, padding: '0.5rem' }}
                        disabled={rows.length <= 1}
                      >
                        <Trash2 size={20} />
                      </button>
                    </motion.div>
                  );
                })}
              </AnimatePresence>
            </div>
          </div>

          <div className="card-premium" style={{ padding: '2rem' }}>
            <h2 style={{ fontSize: '1.1rem', fontWeight: 800, display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '1.5rem' }}>
              <CheckCircle2 size={24} style={{ color: '#10b981' }} />
              Tareas Realizadas
            </h2>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
              {tasks.map((task) => (
                <motion.div 
                  key={task.id} 
                  whileTap={{ scale: 0.98 }}
                  onClick={() => toggleTask(task.id)}
                  style={{ 
                    padding: '1rem', 
                    borderRadius: '16px', 
                    background: task.done ? 'rgba(16, 185, 129, 0.05)' : 'var(--secondary)', 
                    border: '1px solid',
                    borderColor: task.done ? 'rgba(16, 185, 129, 0.2)' : 'var(--border)',
                    cursor: 'pointer',
                    display: 'flex',
                    alignItems: 'center',
                    gap: '1rem'
                  }}
                >
                  <div style={{ 
                    width: '24px', 
                    height: '24px', 
                    borderRadius: '6px', 
                    border: '2px solid', 
                    borderColor: task.done ? '#10b981' : 'var(--muted-foreground)',
                    background: task.done ? '#10b981' : 'transparent',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    color: 'white'
                  }}>
                    {task.done && <CheckCircle2 size={16} />}
                  </div>
                  <span style={{ 
                    fontSize: '0.9rem', 
                    fontWeight: 700, 
                    color: task.done ? 'var(--foreground)' : 'var(--muted-foreground)',
                    textDecoration: task.done ? 'line-through' : 'none'
                  }}>
                    {task.label}
                  </span>
                </motion.div>
              ))}
            </div>
          </div>
        </div>

        <div className="responsive-grid-2">
          <button 
            onClick={handleFinalizeMaintenance}
            disabled={loading}
            className="btn-primary" 
            style={{ height: 'auto', padding: '1.5rem', borderRadius: '24px', display: 'flex', flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: '1rem', fontSize: '1.1rem', fontWeight: 800 }}
          >
            <Wrench size={28} />
            {loading ? 'Finalizando...' : 'Finalizar Mantenimiento'}
          </button>

          <div style={{ 
            padding: '1.5rem', 
            borderRadius: '24px', 
            background: 'rgba(71, 85, 105, 0.05)', 
            border: '1px solid rgba(71, 85, 105, 0.1)',
            display: 'flex', 
            gap: '1.25rem', 
            alignItems: 'center'
          }}>
            <ShieldAlert size={32} style={{ color: '#475569', flexShrink: 0 }} />
            <div>
              <h4 style={{ fontWeight: 800, fontSize: '0.95rem', color: '#334155', marginBottom: '0.2rem' }}>SEGURIDAD INDUSTRIAL</h4>
              <p style={{ fontSize: '0.85rem', color: 'var(--muted-foreground)', lineHeight: 1.5 }}>
                El uso de <strong>EPP completo</strong> es obligatorio al manipular Cal Viva o químicos. Evite riesgos.
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
