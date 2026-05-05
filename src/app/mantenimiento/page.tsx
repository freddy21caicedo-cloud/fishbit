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
import { useSearchParams } from 'next/navigation';
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
  const estanqueParam = searchParams.get('estanque');

  const [fecha, setFecha] = useState(new Date().toISOString().split('T')[0]);
  const [hora, setHora] = useState(new Date().toTimeString().slice(0, 5));
  const [estanqueId, setEstanqueId] = useState(estanqueParam || '');
  const [actividad, setActividad] = useState('Encalado');
  
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
    const { data: invData } = await supabase.from('inventory').select('*').in('category', ['insumos', 'agrícola']);
    setInventory(invData || []);

    const { data: pondData } = await supabase.from('estanques').select('*');
    setPonds(pondData || []);
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
    if (!estanqueId) return;

    // 1. Create Maintenance Log
    const { error: logErr } = await supabase.from('mantenimiento_logs').insert([{
      estanque_id: estanqueId,
      type: actividad,
      description: `Actividad: ${actividad}. Tareas completadas: ${tasks.filter(t => t.done).map(t => t.label).join(', ')}`,
      date: fecha
    }]);

    if (logErr) {
      alert("Error al registrar mantenimiento: " + logErr.message);
      return;
    }

    // 2. Deduct Inventory
    for (const row of rows) {
      if (row.producto_id && row.cantidad) {
        const prod = inventory.find(i => i.id === row.producto_id);
        if (prod) {
          const newStock = (parseFloat(prod.current_stock) || 0) - (parseFloat(row.cantidad) || 0);
          await supabase.from('inventory').update({ current_stock: newStock }).eq('id', prod.id);
        }
      }
    }

    alert("¡Mantenimiento registrado con éxito! El historial e inventario han sido actualizados.");
    window.location.href = '/estanques';
  };

  return (
    <div className="animate-fade-in" style={{ maxWidth: '1000px', margin: '0 auto', paddingBottom: '4rem' }}>
      <header style={{ marginBottom: '2.5rem', display: 'flex', alignItems: 'center', gap: '1rem' }}>
        <Link href="/estanques" style={{ color: 'var(--muted-foreground)', display: 'flex', alignItems: 'center', justifyContent: 'center', width: '40px', height: '40px', borderRadius: '50%', background: 'var(--card)', border: '1px solid var(--border)' }}>
          <ArrowLeft size={20} />
        </Link>
        <div>
          <h1 style={{ fontSize: '1.875rem', fontWeight: 700 }}>Mantenimiento y Preparación</h1>
          <p style={{ color: 'var(--muted-foreground)' }}>Acondicionamiento de estanques para el próximo ciclo de producción.</p>
        </div>
      </header>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr', gap: '2rem' }}>
        {/* Contextual Info Card */}
        <div className="card-premium" style={{ padding: '2rem', display: 'grid', gridTemplateColumns: '1.2fr 1fr 1fr 1.2fr', gap: '1.5rem', alignItems: 'center' }}>
          <div>
            <div style={{ fontSize: '0.75rem', fontWeight: 700, marginBottom: '0.5rem', textTransform: 'uppercase', color: 'var(--muted-foreground)' }}>Estanque</div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', padding: '0.75rem', background: 'rgba(71, 85, 105, 0.05)', borderRadius: '8px', border: '1px solid rgba(71, 85, 105, 0.1)' }}>
              <Waves size={20} style={{ color: 'var(--muted-foreground)' }} />
              <span style={{ fontSize: '1.1rem', fontWeight: 800, color: 'var(--foreground)' }}>
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
            <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 700, marginBottom: '0.5rem', textTransform: 'uppercase', color: 'var(--muted-foreground)' }}>Actividad</label>
            <select value={actividad} onChange={(e) => setActividad(e.target.value)} style={{ width: '100%', padding: '0.75rem', borderRadius: '8px', border: '1px solid var(--border)', background: 'var(--secondary)', outline: 'none', fontWeight: 600 }}>
              <option value="Encalado">🧹 Encalado (Desinfección)</option>
              <option value="Maleza">🌿 Control de Malezas</option>
              <option value="Diques">🏗️ Reparación de Diques</option>
              <option value="Plagas">🚫 Control de Plagas</option>
            </select>
          </div>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: '1.5fr 1fr', gap: '2rem' }}>
          {/* Agri Inputs Card */}
          <div className="card-premium" style={{ padding: '2rem' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
              <h2 style={{ fontSize: '1.25rem', fontWeight: 700, display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                <Shovel size={24} style={{ color: 'var(--primary)' }} />
                Insumos Aplicados
              </h2>
              <button onClick={addRow} style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', padding: '0.5rem 1rem', borderRadius: '8px', border: '1px solid var(--primary)', color: 'var(--primary)', background: 'transparent', fontWeight: 600, cursor: 'pointer' }}>
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
                        gridTemplateColumns: '2fr 1fr 40px', 
                        gap: '1rem', 
                        alignItems: 'flex-end',
                        padding: '1.25rem',
                        background: 'var(--card)',
                        borderRadius: '12px',
                        border: '1px solid var(--border)'
                      }}
                    >
                      <div>
                        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '0.4rem' }}>
                          <label style={{ fontSize: '0.7rem', fontWeight: 700, color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Producto Agrícola</label>
                          <span style={{ fontSize: '0.7rem', fontWeight: 700, color: 'var(--primary)' }}>Stock: {stockAvailable} {unidad}</span>
                        </div>
                        <select 
                          value={row.producto_id}
                          onChange={(e) => updateRow(row.id, 'producto_id', e.target.value)}
                          style={{ width: '100%', padding: '0.625rem', borderRadius: '8px', border: '1px solid var(--border)', background: 'var(--secondary)', outline: 'none', fontWeight: 600 }}
                        >
                          <option value="">-- Seleccionar --</option>
                          {inventory.map(s => <option key={s.id} value={s.id}>{s.name}</option>)}
                        </select>
                      </div>
                      <div>
                        <label style={{ fontSize: '0.7rem', fontWeight: 700, color: 'var(--muted-foreground)', marginBottom: '0.4rem', textTransform: 'uppercase', display: 'block' }}>Cantidad</label>
                        <div style={{ display: 'flex', alignItems: 'center', background: 'var(--secondary)', borderRadius: '8px', border: '1px solid var(--border)', paddingRight: '0.75rem' }}>
                          <input 
                            type="number" 
                            value={row.cantidad}
                            onChange={(e) => updateRow(row.id, 'cantidad', e.target.value)}
                            placeholder="0.0"
                            style={{ width: '100%', padding: '0.625rem', border: 'none', background: 'transparent', outline: 'none', fontWeight: 700 }}
                          />
                          <span style={{ fontWeight: 700, fontSize: '0.8rem', color: 'var(--muted-foreground)' }}>{unidad}</span>
                        </div>
                      </div>
                      <button 
                        onClick={() => removeRow(row.id)}
                        style={{ background: 'transparent', border: 'none', color: '#ef4444', cursor: 'pointer', opacity: rows.length > 1 ? 0.6 : 0.2, marginBottom: '8px' }}
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

          {/* Task Checklist Card */}
          <div className="card-premium" style={{ padding: '2rem' }}>
            <h2 style={{ fontSize: '1.25rem', fontWeight: 700, display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '1.5rem' }}>
              <CheckCircle2 size={24} style={{ color: '#10b981' }} />
              Tareas de Preparación
            </h2>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
              {tasks.map((task) => (
                <div 
                  key={task.id} 
                  onClick={() => toggleTask(task.id)}
                  style={{ 
                    padding: '1rem', 
                    borderRadius: '12px', 
                    background: task.done ? 'rgba(16, 185, 129, 0.05)' : 'var(--secondary)', 
                    border: '1px solid',
                    borderColor: task.done ? 'rgba(16, 185, 129, 0.2)' : 'var(--border)',
                    cursor: 'pointer',
                    display: 'flex',
                    alignItems: 'center',
                    gap: '0.75rem',
                    transition: 'all 0.2s ease'
                  }}
                >
                  <div style={{ 
                    width: '20px', 
                    height: '20px', 
                    borderRadius: '4px', 
                    border: '2px solid', 
                    borderColor: task.done ? '#10b981' : 'var(--muted-foreground)',
                    background: task.done ? '#10b981' : 'transparent',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    color: 'white'
                  }}>
                    {task.done && <CheckCircle2 size={14} />}
                  </div>
                  <span style={{ 
                    fontSize: '0.9rem', 
                    fontWeight: 600, 
                    color: task.done ? 'var(--foreground)' : 'var(--muted-foreground)',
                    textDecoration: task.done ? 'line-through' : 'none'
                  }}>
                    {task.label}
                  </span>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Action and Safety Section */}
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1.5fr', gap: '2rem', alignItems: 'stretch' }}>
          <button 
            onClick={handleFinalizeMaintenance}
            className="btn-primary" 
            style={{ height: 'auto', padding: '1.5rem', borderRadius: '20px', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: '0.5rem', fontSize: '1.1rem', fontWeight: 800 }}
          >
            <Wrench size={28} />
            Finalizar Mantenimiento
          </button>

          <div style={{ 
            padding: '1.5rem', 
            borderRadius: '20px', 
            background: 'linear-gradient(to right, rgba(71, 85, 105, 0.08), rgba(71, 85, 105, 0.02))', 
            borderLeft: '5px solid #475569',
            display: 'flex', 
            gap: '1.25rem', 
            alignItems: 'center'
          }}>
            <div style={{ 
              width: '45px', 
              height: '45px', 
              borderRadius: '12px', 
              background: 'white', 
              display: 'flex', 
              alignItems: 'center', 
              justifyContent: 'center',
              color: '#475569',
              boxShadow: 'var(--shadow-sm)'
            }}>
              <ShieldAlert size={28} />
            </div>
            <div style={{ flex: 1 }}>
              <h4 style={{ fontWeight: 800, fontSize: '0.95rem', marginBottom: '0.2rem', color: '#334155' }}>
                SEGURIDAD INDUSTRIAL (EPP)
              </h4>
              <p style={{ fontSize: '0.85rem', color: 'var(--muted-foreground)', lineHeight: 1.5 }}>
                El uso de <strong style={{ color: '#1e293b' }}>MASCARILLA, GUANTES Y PROTECCIÓN OCULAR</strong> es obligatorio al manipular Cal Viva o insumos químicos para evitar quemaduras e irritaciones.
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
