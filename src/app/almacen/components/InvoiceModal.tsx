'use client';

import { motion, AnimatePresence } from 'framer-motion';
import { X, Calendar, Hash, DollarSign, Plus, Trash2, Loader2, Truck, Package } from 'lucide-react';
import { useState, useEffect, useMemo } from 'react';
import { supabase } from '@/lib/supabase';
import { toast } from 'react-hot-toast';
import { PremiumInput } from '../../components/ui/PremiumInput';

interface InvoiceModalProps {
  isOpen: boolean;
  onClose: () => void;
  unitId: string;
  activeCat: string;
  onSuccess: () => void;
  providers: any[];
}

const CAT_PRODUCTS: Record<string, string[]> = {
  alimento: [
    'Aquatilapia Preiniciador 48% ME 20kg',
    'Aquatilapia 45% E 40kg',
    'Aquatilapia 38% E 40kg',
    'Aquatilapia 34% E 40kg',
    'Aquatilapia 32% E 40kg',
    'Aquatilapia 30% E 40kg',
    'Aquatilapia 25% E 40kg',
    'Aquatilapia 20% E 40kg',
    'Aquatropico 22% E 40 kg',
    'Aquatrucha Super Iniciación 50% E 40 kg',
    'Aquatrucha Levante 45% E Pig 40 kg',
    'Aquatrucha Finalización 45% E Pig 40 kg'
  ].sort(),
  farmacia: [
    'Oxitetraciclina 50%',
    'Florfenicol 30%',
    'Enrofloxacina 10%',
    'Vitamina C Estabilizada',
    'Complejo B Acuático',
    'Desinfectante (Yodo Polivinil)',
    'Probiótico de Estanque'
  ].sort(),
  alevinos: [
    'Tilapia Roja', 'Tilapia Nilótica', 'Cachama', 'Trucha Arcoíris', 'Bocachico', 'Yamú', 'Carpa', 'Sábalo', 'Bagre Omnivoro'
  ].sort(),
  insumos: [
    'Cal Dolomita', 'Melaza', 'Sal Marina', 'Cal Viva', 'Bicarbonato'
  ].sort(),
  aireadores: [
    'Splash de 1/2 HP', 'Splash de 1 HP', 'Splash de 1.5 HP', 'Splash de 2 HP', 'Blower 1.0 HP', 'Blower 2.0 HP'
  ].sort()
};

export function InvoiceModal({ isOpen, onClose, unitId, activeCat, onSuccess, providers }: InvoiceModalProps) {
  const [loading, setLoading] = useState(false);
  const [nroFactura, setNroFactura] = useState('');
  const [proveedorId, setProveedorId] = useState('');
  const [fechaFactura, setFechaFactura] = useState(new Date().toISOString().split('T')[0]);
  const [isCredit, setIsCredit] = useState(false);
  const [diasCredito, setDiasCredito] = useState('30');
  const [flete, setFlete] = useState('');

  const [items, setItems] = useState([
    { id: Date.now(), product: '', batch: '', quantity: '', kilos: '', unitPrice: '', hasIva: false, ivaPercent: '19' }
  ]);

  // Catalog State
  const [focusedRowId, setFocusedRowId] = useState<number | null>(null);

  // Filter Providers by activeCat
  const filteredProviders = useMemo(() => {
    return providers.filter(p => {
      const pCats = p.types || p.categories || [];
      const pCat = p.category;
      
      // Include if no restrictions or matches current category
      if (!pCat && (!pCats || pCats.length === 0)) return true;
      if (pCat === activeCat) return true;
      if (Array.isArray(pCats) && pCats.includes(activeCat)) return true;
      return false;
    });
  }, [providers, activeCat]);

  // Auto-reset provider if no longer valid for the category
  useEffect(() => {
    if (proveedorId && !filteredProviders.find(p => p.id === proveedorId)) {
      setProveedorId('');
    }
  }, [filteredProviders, proveedorId]);

  useEffect(() => {
    if (isOpen) {
      setItems([{ id: Date.now(), product: '', batch: '', quantity: '', kilos: '', unitPrice: '', hasIva: false, ivaPercent: '19' }]);
      setNroFactura('');
      setProveedorId('');
      setFlete('');
      setFechaFactura(new Date().toISOString().split('T')[0]);
    }
  }, [isOpen]);

  const updateItem = (id: number, field: string, value: any) => {
    setItems(prev => prev.map(item => {
      if (item.id !== id) return item;
      const updated = { ...item, [field]: value };
      
      // Auto-calculate Kilos for Food
      if (activeCat === 'alimento' && (field === 'product' || field === 'quantity')) {
        const weightMatch = updated.product.match(/(\d+)\s*kg/i);
        const weightPerBag = weightMatch ? parseInt(weightMatch[1]) : 40;
        const qty = parseFloat(updated.quantity) || 0;
        updated.kilos = (qty * weightPerBag).toString();
      }
      return updated;
    }));
  };

  const totalBultos = useMemo(() => items.reduce((sum, item) => sum + (parseFloat(item.quantity) || 0), 0), [items]);
  const fleteNum = parseFloat(flete) || 0;
  const fletePorBulto = totalBultos > 0 ? fleteNum / totalBultos : 0;

  const totalFactura = useMemo(() => {
    return items.reduce((sum, item) => {
      const qty = parseFloat(item.quantity) || 0;
      const price = parseFloat(item.unitPrice) || 0;
      const ivaRate = activeCat === 'alimento' ? 0.05 : (item.hasIva ? (parseFloat(item.ivaPercent) || 0) / 100 : 0);
      return sum + (qty * price * (1 + ivaRate));
    }, 0);
  }, [items, activeCat]);

  const handleRegister = async () => {
    if (!proveedorId || !nroFactura || items.some(i => !i.product || !i.quantity)) {
      toast.error("Complete todos los campos obligatorios");
      return;
    }

    setLoading(true);
    try {
      const { data: invData, error: invError } = await supabase.from('invoices').insert([{
        invoice_number: nroFactura, provider_id: proveedorId, category: activeCat,
        date: fechaFactura, total: totalFactura, flete: fleteNum,
        is_credit: isCredit, credit_days: parseInt(diasCredito) || 0,
        status: isCredit ? 'pendiente' : 'pagada', unit_id: unitId
      }]).select();

      if (invError || !invData) throw invError;
      const invoiceId = invData[0].id;
      
      for (const item of items) {
        const qty = parseFloat(item.quantity) || 0;
        const price = parseFloat(item.unitPrice) || 0;
        const ivaP = activeCat === 'alimento' ? 5 : (item.hasIva ? parseFloat(item.ivaPercent) || 0 : 0);
        
        let finalBatch = item.batch;
        if (activeCat === 'alevinos') {
          const provName = providers.find(p => p.id === proveedorId)?.name?.split(' ')[0] || 'PROV';
          const espName = item.product.split(' ')[0] || 'ESP';
          const dateStr = fechaFactura.replace(/-/g, '').slice(2);
          finalBatch = `LOTE-${dateStr}-${espName}-${provName}`.toUpperCase();
        }

        await supabase.from('invoice_items').insert([{
          invoice_id: invoiceId, unit_id: unitId, product_name: item.product,
          batch: finalBatch, quantity: qty, kilos: parseFloat(item.kilos) || 0,
          unit_price: price, flete_per_unit: fletePorBulto, total_price: qty * price,
          has_iva: activeCat === 'alimento' ? true : item.hasIva, iva_percent: ivaP
        }]);

        const { data: existing } = await supabase.from('inventory').select('*').eq('category', activeCat).eq('name', item.product).eq('unit_id', unitId).single();
        const qtyToAdd = activeCat === 'alimento' ? (parseFloat(item.kilos) || 0) : qty;
        
        if (existing) {
          await supabase.from('inventory').update({ current_stock: (Number(existing.current_stock) || 0) + qtyToAdd, last_entry: new Date().toISOString() }).eq('id', existing.id);
        } else {
          await supabase.from('inventory').insert([{
            category: activeCat, name: item.product, current_stock: qtyToAdd,
            unit: activeCat === 'alimento' ? 'kg' : activeCat === 'alevinos' ? 'unidades' : 'uds',
            unit_id: unitId, last_entry: new Date().toISOString()
          }]);
        }
      }
      toast.success("Factura e Inventario actualizados");
      onSuccess(); onClose();
    } catch (error: any) {
      toast.error("Error: " + error.message);
    } finally {
      setLoading(false);
    }
  };

  if (!isOpen) return null;

  return (
    <div style={{ position: 'fixed', inset: 0, zIndex: 1000, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '1rem' }}>
      <motion.div 
        initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
        onClick={onClose}
        style={{ position: 'absolute', inset: 0, background: 'rgba(2, 6, 23, 0.7)', backdropFilter: 'blur(10px)' }} 
      />
      <motion.div 
        initial={{ scale: 0.9, opacity: 0, y: 20 }} animate={{ scale: 1, opacity: 1, y: 0 }}
        className="card-premium" 
        style={{ width: '100%', maxWidth: '980px', maxHeight: '90vh', position: 'relative', zIndex: 10, padding: '2rem', overflow: 'hidden', display: 'flex', flexDirection: 'column', border: '1px solid rgba(255,255,255,0.1)' }}
      >
        <button onClick={onClose} style={{ position: 'absolute', top: '1.5rem', right: '1.5rem', background: 'none', border: 'none', color: 'var(--muted-foreground)', cursor: 'pointer', zIndex: 20 }}><X size={24} /></button>

        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '2rem', paddingRight: '2rem' }}>
          <div>
            <h2 style={{ fontSize: '1.5rem', fontWeight: 900, letterSpacing: '-0.02em', marginBottom: '0.25rem' }}>Ingreso de Factura</h2>
            <p style={{ color: 'var(--muted-foreground)', fontSize: '0.85rem', fontWeight: 600 }}>Carga masiva para <strong style={{ color: 'var(--primary)' }}>{activeCat.toUpperCase()}</strong></p>
          </div>
          <div style={{ background: 'var(--secondary)', padding: '0.75rem 1.25rem', borderRadius: '14px', border: '1px solid var(--border)', textAlign: 'right' }}>
            <div style={{ fontSize: '0.65rem', fontWeight: 900, color: 'var(--muted-foreground)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Total Factura</div>
            <div style={{ fontSize: '1.5rem', fontWeight: 950, color: 'var(--primary)' }}>${totalFactura.toLocaleString()}</div>
          </div>
        </div>

        <div style={{ flex: 1, overflowY: 'auto', paddingRight: '0.5rem', display: 'flex', flexDirection: 'column', gap: '1.5rem', paddingBottom: '180px' }}>
          {/* Header Section */}
          <section style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))', gap: '1rem', background: 'var(--secondary)', padding: '1.25rem', borderRadius: '18px' }}>
            <PremiumInput label="NRO. FACTURA" value={nroFactura} onChange={(e) => setNroFactura(e.target.value)} placeholder="Ej: INV-001" icon={Hash} />
            <PremiumInput as="select" label="PROVEEDOR" value={proveedorId} onChange={(e) => setProveedorId(e.target.value)} icon={Truck}>
              <option value="">Seleccione...</option>
              {filteredProviders.map(p => <option key={p.id} value={p.id}>{p.name}</option>)}
            </PremiumInput>
            <PremiumInput type="date" label="FECHA" value={fechaFactura} onChange={(e) => setFechaFactura(e.target.value)} icon={Calendar} />
          </section>

          {/* Flete Section */}
          {activeCat === 'alimento' && (
            <section style={{ background: 'rgba(245, 158, 11, 0.05)', border: '1px solid rgba(245, 158, 11, 0.2)', borderRadius: '18px', padding: '1.25rem', display: 'flex', alignItems: 'center', gap: '2rem', flexWrap: 'wrap' }}>
              <div style={{ flex: 1, minWidth: '200px' }}>
                <PremiumInput 
                  type="number" 
                  label="🚚 FLETE TOTAL (EXTERNO)" 
                  value={flete} 
                  onChange={(e) => setFlete(e.target.value)} 
                  placeholder="0" 
                  style={{ background: 'white', color: '#d97706' }}
                />
              </div>
              {fleteNum > 0 && totalBultos > 0 && (
                <div style={{ textAlign: 'center' }}>
                  <div style={{ fontSize: '0.65rem', fontWeight: 900, color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Flete / Bulto</div>
                  <div style={{ fontSize: '1.25rem', fontWeight: 900, color: '#d97706' }}>${fletePorBulto.toLocaleString(undefined, {maximumFractionDigits:0})}</div>
                </div>
              )}
            </section>
          )}

          {/* Items Section */}
          <div style={{ width: '100%', overflowX: 'auto', paddingBottom: '1rem' }}>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem', minWidth: '800px' }}>
            {items.map((item) => (
              <div key={item.id} className="glass" style={{ padding: '1.25rem', borderRadius: '18px', display: 'grid', gridTemplateColumns: activeCat === 'alimento' ? '2fr 1fr 1fr 1fr 1.5fr 50px' : '2.5fr 1.5fr 1fr 1.5fr 50px', gap: '1rem', alignItems: 'end', background: 'var(--card)', position: 'relative', zIndex: focusedRowId === item.id ? 50 : 1 }}>
                <div style={{ position: 'relative' }}>
                  <PremiumInput 
                    label="PRODUCTO"
                    placeholder="Buscar..." 
                    icon={Package}
                    value={item.product}
                    onChange={(e) => updateItem(item.id, 'product', e.target.value)}
                    onFocus={() => setFocusedRowId(item.id)}
                    onBlur={() => setTimeout(() => setFocusedRowId(null), 200)}
                    style={{ fontWeight: 700 }}
                  />

                  {/* Product Catalog Dropdown */}
                  <AnimatePresence>
                    {focusedRowId === item.id && (
                      <motion.div 
                        initial={{ opacity: 0, y: -10, scale: 0.95 }} animate={{ opacity: 1, y: 0, scale: 1 }} exit={{ opacity: 0, y: -10, scale: 0.95 }}
                        style={{ position: 'absolute', top: 'calc(100% + 5px)', left: 0, width: '100%', background: 'white', borderRadius: '14px', boxShadow: '0 20px 60px rgba(0,0,0,0.3)', zIndex: 9999, maxHeight: '200px', overflowY: 'auto', border: '1px solid var(--border)', padding: '6px' }}
                      >
                        {(CAT_PRODUCTS[activeCat] || [])
                          .filter(p => p.toLowerCase().includes(item.product.toLowerCase()))
                          .map(p => (
                            <div key={p} onClick={() => updateItem(item.id, 'product', p)} style={{ padding: '0.75rem 1rem', fontSize: '0.85rem', cursor: 'pointer', borderRadius: '10px', fontWeight: 700, color: 'var(--foreground)', transition: 'all 0.2s ease' }} onMouseEnter={(e) => (e.currentTarget.style.background = 'var(--primary)', e.currentTarget.style.color = 'white')} onMouseLeave={(e) => (e.currentTarget.style.background = 'transparent', e.currentTarget.style.color = 'var(--foreground)')}>{p}</div>
                          ))
                        }
                      </motion.div>
                    )}
                  </AnimatePresence>
                </div>
                <PremiumInput 
                  label="LOTE" 
                  placeholder={activeCat === 'alevinos' ? "Auto-generado" : "Lot..."} 
                  value={activeCat === 'alevinos' ? "AUTO" : item.batch} 
                  onChange={(e) => updateItem(item.id, 'batch', e.target.value)} 
                  disabled={activeCat === 'alevinos'} 
                />
                <PremiumInput type="number" label={activeCat === 'alimento' ? 'BULTOS' : 'CANT'} placeholder="0" value={item.quantity} onChange={(e) => updateItem(item.id, 'quantity', e.target.value)} style={{ fontWeight: 900 }} />
                {activeCat === 'alimento' && <PremiumInput type="number" label="KILOS" placeholder="Kg" value={item.kilos} onChange={(e) => updateItem(item.id, 'kilos', e.target.value)} style={{ fontWeight: 900 }} />}
                <PremiumInput type="number" label="VLR UNIT" placeholder="0" value={item.unitPrice} onChange={(e) => updateItem(item.id, 'unitPrice', e.target.value)} style={{ fontWeight: 900, color: 'var(--primary)' }} icon={DollarSign} />
                <button onClick={() => setItems(items.filter(i => i.id !== item.id))} style={{ height: '48px', background: 'rgba(239, 68, 68, 0.05)', border: '1px solid rgba(239, 68, 68, 0.1)', color: '#ef4444', borderRadius: '12px', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }} disabled={items.length === 1}><Trash2 size={18} /></button>
              </div>
            ))}
            <button onClick={() => setItems([...items, { id: Date.now(), product: '', batch: '', quantity: '', kilos: '', unitPrice: '', hasIva: false, ivaPercent: '19' }])} style={{ padding: '1rem', borderRadius: '16px', border: '2px dashed var(--primary)', background: 'transparent', color: 'var(--primary)', fontWeight: 800, fontSize: '0.9rem', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '0.75rem' }}><Plus size={20} /> Agregar Ítem a la Factura</button>
          </div>
          </div>
        </div>

        <div style={{ display: 'flex', gap: '1rem', marginTop: '1.5rem', paddingTop: '1.25rem', borderTop: '1px solid var(--border)' }}>
          <button onClick={onClose} className="btn-secondary" style={{ flex: 1, padding: '1rem' }}>Cancelar</button>
          <button onClick={handleRegister} className="btn-primary" style={{ flex: 2, padding: '1rem', fontSize: '1rem' }} disabled={loading}>{loading ? <Loader2 className="animate-spin" /> : 'Registrar Factura'}</button>
        </div>
      </motion.div>
    </div>
  );
}
