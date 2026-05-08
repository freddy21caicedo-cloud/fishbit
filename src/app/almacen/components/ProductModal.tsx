'use client';

import { useState, useMemo, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X, FlaskConical, Plus, AlertCircle } from 'lucide-react';
import { supabase } from '@/lib/supabase';
import { toast } from 'react-hot-toast';
import { PremiumInput } from '../../components/ui/PremiumInput';

const UNIT_OPTIONS = ['mg', 'gr', 'kg', 'ml', 'L', 'galones'];

const GALLON_TO_LITER = 3.78541;

interface ProductModalProps {
  isOpen: boolean;
  onClose: () => void;
  unitId: string;
  activeCat: 'farmacia' | 'insumos';
  onSuccess: () => void;
}

interface ProductForm {
  name: string;
  laboratorio: string;
  presentacion: string;
  cantidad: string;
  precio_unitario: string;
  hasIva: boolean;
  ivaPct: string;
}

const INITIAL_FORM: ProductForm = {
  name: '',
  laboratorio: '',
  presentacion: 'ml',
  cantidad: '',
  precio_unitario: '',
  hasIva: false,
  ivaPct: '19',
};

export function ProductModal({ isOpen, onClose, unitId, activeCat, onSuccess }: ProductModalProps) {
  const [form, setForm] = useState<ProductForm>(INITIAL_FORM);
  const [loading, setLoading] = useState(false);

  // Reset on open
  useEffect(() => {
    if (isOpen) setForm(INITIAL_FORM);
  }, [isOpen]);

  const setField = <K extends keyof ProductForm>(key: K, value: ProductForm[K]) => {
    setForm(prev => ({ ...prev, [key]: value }));
  };

  // Real-time total calculation
  const total = useMemo(() => {
    const qty = parseFloat(form.cantidad) || 0;
    const price = parseFloat(form.precio_unitario) || 0;
    const iva = form.hasIva ? parseFloat(form.ivaPct) / 100 : 0;
    return qty * price * (1 + iva);
  }, [form.cantidad, form.precio_unitario, form.hasIva, form.ivaPct]);

  const handleSave = async () => {
    if (!form.name.trim() || !form.cantidad || !form.precio_unitario) {
      toast.error('Completa los campos requeridos: Nombre, Cantidad y Precio.');
      return;
    }
    setLoading(true);
    try {
      let stockFinal = parseFloat(form.cantidad) || 0;
      let unitFinal = form.presentacion;

      // Convert gallons to liters before persisting
      if (form.presentacion === 'galones') {
        stockFinal = stockFinal * GALLON_TO_LITER;
        unitFinal = 'L';
      }

      const { error } = await supabase.from('inventory').insert([{
        unit_id: unitId,
        category: activeCat,
        name: form.name.trim(),
        laboratorio: form.laboratorio.trim() || null,
        presentacion: unitFinal,
        unit: unitFinal,
        current_stock: stockFinal,
        precio_unitario: parseFloat(form.precio_unitario),
        iva_pct: form.hasIva ? parseFloat(form.ivaPct) : 0,
        total_costo: total,
      }]);

      if (error) throw error;

      toast.success(`Producto "${form.name}" creado con éxito.`);
      onSuccess();
      onClose();
    } catch (err: any) {
      toast.error(`Error al guardar: ${err.message}`);
    } finally {
      setLoading(false);
    }
  };

  if (!isOpen) return null;

  return (
    <AnimatePresence>
      {isOpen && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          onClick={onClose}
          style={{
            position: 'fixed', inset: 0, zIndex: 9999,
            background: 'rgba(2, 6, 23, 0.6)',
            backdropFilter: 'blur(8px)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            padding: '1rem',
          }}
        >
          <motion.div
            initial={{ opacity: 0, scale: 0.95, y: 20 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.95, y: 20 }}
            transition={{ type: 'spring', damping: 25, stiffness: 300 }}
            onClick={e => e.stopPropagation()}
            className="card-premium"
            style={{
              width: '100%', maxWidth: '560px',
              padding: '2rem',
              maxHeight: '90vh',
              overflowY: 'auto',
              display: 'flex', flexDirection: 'column', gap: '1.5rem',
            }}
          >
            {/* Header */}
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                <div style={{ background: activeCat === 'farmacia' ? 'rgba(139,92,246,0.1)' : 'rgba(14,165,233,0.1)', color: activeCat === 'farmacia' ? '#8b5cf6' : '#0ea5e9', padding: '0.6rem', borderRadius: '10px' }}>
                  <FlaskConical size={20} />
                </div>
                <div>
                  <h2 style={{ fontWeight: 900, fontSize: '1.2rem' }}>Nuevo Producto</h2>
                  <p style={{ fontSize: '0.8rem', color: 'var(--muted-foreground)', fontWeight: 600, textTransform: 'capitalize' }}>{activeCat}</p>
                </div>
              </div>
              <button onClick={onClose} style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--muted-foreground)', padding: '0.4rem', borderRadius: '8px' }}>
                <X size={20} />
              </button>
            </div>

            {/* Form */}
            <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
              {/* Nombre */}
              <div className="premium-input-group">
                <label className="premium-label">Nombre del Producto *</label>
                <input
                  type="text"
                  value={form.name}
                  onChange={e => setField('name', e.target.value)}
                  placeholder="Ej: Oxitetraciclina 500mg"
                  className="premium-input"
                />
              </div>

              {/* Laboratorio */}
              <div className="premium-input-group">
                <label className="premium-label">Laboratorio</label>
                <input
                  type="text"
                  value={form.laboratorio}
                  onChange={e => setField('laboratorio', e.target.value)}
                  placeholder="Ej: Bayer, Pfizer..."
                  className="premium-input"
                />
              </div>

              {/* Presentación + Cantidad */}
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
                <div className="premium-input-group">
                  <label className="premium-label">Presentación</label>
                  <div className="premium-select-wrapper">
                    <select
                      value={form.presentacion}
                      onChange={e => setField('presentacion', e.target.value)}
                      className="premium-input"
                    >
                      {UNIT_OPTIONS.map(u => (
                        <option key={u} value={u}>{u}</option>
                      ))}
                    </select>
                  </div>
                  {form.presentacion === 'galones' && (
                    <p style={{ fontSize: '0.7rem', color: 'var(--primary)', marginTop: '4px', fontWeight: 700 }}>
                      Se guardará en Litros (× 3.785)
                    </p>
                  )}
                </div>
                <div className="premium-input-group">
                  <label className="premium-label">Cantidad *</label>
                  <input
                    type="number"
                    min="0"
                    value={form.cantidad}
                    onChange={e => setField('cantidad', e.target.value)}
                    placeholder="0"
                    className="premium-input"
                  />
                </div>
              </div>

              {/* Precio Unitario */}
              <div className="premium-input-group">
                <label className="premium-label">Precio Unitario (COP) *</label>
                <input
                  type="number"
                  min="0"
                  value={form.precio_unitario}
                  onChange={e => setField('precio_unitario', e.target.value)}
                  placeholder="0.00"
                  className="premium-input"
                />
              </div>

              {/* IVA Switch */}
              <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem', padding: '1.25rem', background: 'var(--secondary)', borderRadius: '12px', border: '1px solid var(--border)' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <label style={{ fontWeight: 800, fontSize: '0.85rem' }}>¿Tiene IVA?</label>
                  <button
                    type="button"
                    onClick={() => setField('hasIva', !form.hasIva)}
                    style={{
                      width: '48px', height: '26px',
                      borderRadius: '13px',
                      background: form.hasIva ? 'var(--primary)' : 'var(--border)',
                      border: 'none', cursor: 'pointer',
                      position: 'relative', transition: 'background 0.2s'
                    }}
                  >
                    <span style={{
                      position: 'absolute',
                      top: '3px',
                      left: form.hasIva ? '25px' : '3px',
                      width: '20px', height: '20px',
                      borderRadius: '50%',
                      background: 'white',
                      transition: 'left 0.2s',
                      boxShadow: '0 1px 4px rgba(0,0,0,0.2)'
                    }} />
                  </button>
                </div>
                {form.hasIva && (
                  <motion.div initial={{ opacity: 0, height: 0 }} animate={{ opacity: 1, height: 'auto' }} exit={{ opacity: 0, height: 0 }}>
                    <div className="premium-input-group">
                      <label className="premium-label">Porcentaje de IVA (%)</label>
                      <input
                        type="number"
                        min="0"
                        max="100"
                        value={form.ivaPct}
                        onChange={e => setField('ivaPct', e.target.value)}
                        className="premium-input"
                      />
                    </div>
                  </motion.div>
                )}
              </div>

              {/* Total calculado en tiempo real */}
              <div style={{
                padding: '1.25rem',
                borderRadius: '12px',
                background: 'linear-gradient(135deg, rgba(13,148,136,0.08), rgba(13,148,136,0.02))',
                border: '1px solid rgba(13,148,136,0.2)',
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center'
              }}>
                <div>
                  <div style={{ fontSize: '0.75rem', fontWeight: 800, color: 'var(--muted-foreground)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Total Calculado</div>
                  <div style={{ fontSize: '0.7rem', color: 'var(--muted-foreground)', marginTop: '2px' }}>
                    ({form.cantidad || 0} × ${form.precio_unitario || 0}){form.hasIva ? ` + ${form.ivaPct}% IVA` : ''}
                  </div>
                </div>
                <div style={{ fontSize: '1.75rem', fontWeight: 950, color: 'var(--primary)' }}>
                  ${total.toLocaleString('es-CO', { minimumFractionDigits: 0, maximumFractionDigits: 0 })}
                </div>
              </div>

              {/* Nota de conversión gallons */}
              {form.presentacion === 'galones' && parseFloat(form.cantidad) > 0 && (
                <div style={{ display: 'flex', gap: '0.5rem', alignItems: 'flex-start', padding: '0.75rem', background: 'rgba(13,148,136,0.05)', borderRadius: '8px', border: '1px solid rgba(13,148,136,0.15)' }}>
                  <AlertCircle size={14} style={{ color: 'var(--primary)', flexShrink: 0, marginTop: '2px' }} />
                  <span style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--primary)' }}>
                    {parseFloat(form.cantidad).toFixed(2)} galones = {(parseFloat(form.cantidad) * GALLON_TO_LITER).toFixed(2)} L en base de datos
                  </span>
                </div>
              )}
            </div>

            {/* Actions */}
            <div style={{ display: 'flex', gap: '1rem' }}>
              <button onClick={onClose} className="glass" style={{ flex: 1, padding: '0.85rem', borderRadius: '12px', fontWeight: 800, cursor: 'pointer', border: '1px solid var(--border)', fontSize: '0.9rem' }}>
                Cancelar
              </button>
              <button onClick={handleSave} disabled={loading} className="btn-primary" style={{ flex: 2, padding: '0.85rem', borderRadius: '12px', fontWeight: 900, fontSize: '0.9rem', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '0.5rem' }}>
                {loading ? (
                  <span style={{ animation: 'spin 1s linear infinite', display: 'inline-block' }}>⏳</span>
                ) : <Plus size={18} />}
                Guardar Producto
              </button>
            </div>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
