'use client';

import { FileText, Calendar, User, DollarSign, Clock, Trash2, CheckCircle2, TrendingUp, Eye, Loader2, X, Package, Hash } from 'lucide-react';
import { supabase } from '@/lib/supabase';
import { toast } from 'react-hot-toast';
import { useMemo, useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';

interface Invoice {
  id: string;
  invoice_number: string;
  date: string;
  total: number;
  category: string;
  status: string;
  unit_id: string;
  providers: {
    name: string;
  } | null;
  credit_days?: number;
}

interface InvoicesTableProps {
  invoices: Invoice[];
  onRefresh: () => void;
}

export function InvoicesTable({ invoices, onRefresh }: InvoicesTableProps) {
  const [invoiceToView, setInvoiceToView] = useState<Invoice | null>(null);
  const [activeTab, setActiveTab] = useState<'pendientes' | 'historial'>('pendientes');

  // 1. Calcular métricas: Total Pendiente
  const totalPendiente = useMemo(() => {
    return invoices
      .filter(inv => inv.status === 'pendiente')
      .reduce((sum, inv) => sum + (inv.total || 0), 0);
  }, [invoices]);

  const displayedInvoices = useMemo(() => {
    return invoices.filter(inv => activeTab === 'pendientes' ? inv.status === 'pendiente' : inv.status === 'pagada');
  }, [invoices, activeTab]);

  // 2. Función para pagar factura y registrar en histórico
  const handleMarcarComoPagada = async (invoice: Invoice) => {
    try {
      const { error: updateError } = await supabase
        .from('invoices')
        .update({ status: 'pagada' })
        .eq('id', invoice.id);

      if (updateError) throw updateError;

      const { error: historyError } = await supabase
        .from('historial_gastos')
        .insert([{
          invoice_id: invoice.id,
          monto: invoice.total,
          fecha_pago: new Date().toISOString(),
          concepto: `Pago de factura ${invoice.invoice_number} - Proveedor: ${invoice.providers?.name || 'N/A'}`,
          unit_id: invoice.unit_id,
          categoria: invoice.category
        }]);

      if (historyError) {
        console.warn("No se pudo registrar en historial_gastos. Verifica si la tabla existe.", historyError);
      }

      toast.success("Factura pagada y movida al historial");
      onRefresh();
    } catch (error: any) {
      toast.error("Error al procesar el pago: " + error.message);
    }
  };

  const handleDelete = async (invoice: Invoice) => {
    if (!confirm(`¿Eliminar factura ${invoice.invoice_number}? Se revertirá el stock ingresado.`)) return;
    
    try {
      const { data: items } = await supabase.from('invoice_items').select('*').eq('invoice_id', invoice.id);
      
      if (items) {
        for (const item of items) {
          const { data: invItem } = await supabase.from('inventory')
            .select('*').eq('name', item.product_name).eq('unit_id', invoice.unit_id).maybeSingle();
          
          if (invItem) {
            const qtyToRemove = invoice.category === 'alimento' ? item.kilos : item.quantity;
            await supabase.from('inventory').update({
              current_stock: Math.max(0, (Number(invItem.current_stock) || 0) - qtyToRemove)
            }).eq('id', invItem.id);
          }
        }
      }

      await supabase.from('invoices').delete().eq('id', invoice.id);
      toast.success("Factura eliminada y stock revertido");
      onRefresh();
    } catch (e) {
      toast.error("Error al eliminar");
    }
  };

  return (
    <div style={{ flex: 1, overflowY: 'auto', padding: '0 1.5rem 1.5rem', display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
      
      {/* Indicador de Total Pendiente y Tabs */}
      <div style={{ display: 'flex', flexWrap: 'wrap', gap: '1.5rem', marginTop: '1rem', alignItems: 'center', justifyContent: 'space-between' }}>
        <div className="glass" style={{ padding: '1.5rem', borderRadius: '20px', borderLeft: '6px solid #ef4444', display: 'flex', alignItems: 'center', gap: '1.25rem', minWidth: '250px' }}>
          <div style={{ background: 'rgba(239, 68, 68, 0.1)', color: '#ef4444', padding: '0.75rem', borderRadius: '12px' }}>
            <TrendingUp size={28} />
          </div>
          <div>
            <div style={{ fontSize: '0.75rem', fontWeight: 800, color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Cuentas por Pagar</div>
            <div style={{ fontSize: '1.5rem', fontWeight: 950, color: '#ef4444' }}>${totalPendiente.toLocaleString()}</div>
          </div>
        </div>

        <div style={{ display: 'flex', background: 'rgba(2, 6, 23, 0.03)', padding: '0.3rem', borderRadius: '16px', border: '1px solid var(--border)' }}>
          <button 
            onClick={() => setActiveTab('pendientes')}
            style={{ 
              padding: '0.6rem 1.25rem', 
              borderRadius: '12px', 
              border: 'none', 
              background: activeTab === 'pendientes' ? 'white' : 'transparent', 
              color: activeTab === 'pendientes' ? 'var(--foreground)' : 'var(--muted-foreground)', 
              fontWeight: 800, 
              cursor: 'pointer', 
              transition: 'all 0.2s ease',
              boxShadow: activeTab === 'pendientes' ? 'var(--shadow-sm)' : 'none',
              display: 'flex',
              alignItems: 'center',
              gap: '0.5rem'
            }}
          >
            <Clock size={16} /> Pendientes
          </button>
          <button 
            onClick={() => setActiveTab('historial')}
            style={{ 
              padding: '0.6rem 1.25rem', 
              borderRadius: '12px', 
              border: 'none', 
              background: activeTab === 'historial' ? 'white' : 'transparent', 
              color: activeTab === 'historial' ? 'var(--foreground)' : 'var(--muted-foreground)', 
              fontWeight: 800, 
              cursor: 'pointer', 
              transition: 'all 0.2s ease',
              boxShadow: activeTab === 'historial' ? 'var(--shadow-sm)' : 'none',
              display: 'flex',
              alignItems: 'center',
              gap: '0.5rem'
            }}
          >
            <CheckCircle2 size={16} /> Historial
          </button>
        </div>
      </div>

      <div className="glass" style={{ borderRadius: '20px', overflow: 'hidden' }}>
        <div style={{ overflowX: 'auto' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse', minWidth: '600px' }}>
            <thead>
              <tr style={{ fontSize: '0.75rem', textTransform: 'uppercase', color: 'var(--muted-foreground)', textAlign: 'left', background: 'rgba(2, 6, 23, 0.02)' }}>
                <th style={{ padding: '1.25rem' }}>Factura / Proveedor</th>
                <th style={{ padding: '1.25rem' }}>Monto</th>
                <th style={{ padding: '1.25rem' }}>Vencimiento</th>
                <th style={{ padding: '1.25rem', textAlign: 'right' }}>Acciones</th>
              </tr>
            </thead>
            <tbody>
              {displayedInvoices.length === 0 ? (
                <tr>
                  <td colSpan={4} style={{ padding: '3rem', textAlign: 'center', color: 'var(--muted-foreground)' }}>
                    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '1rem' }}>
                      <FileText size={48} opacity={0.2} />
                      <p style={{ fontWeight: 600 }}>No hay facturas en esta vista.</p>
                    </div>
                  </td>
                </tr>
              ) : (
                displayedInvoices.map((inv) => {
                  const today = new Date();
                  const vDate = new Date(inv.date);
                  if (inv.credit_days) vDate.setDate(vDate.getDate() + inv.credit_days);
                  const diffDays = Math.ceil((vDate.getTime() - today.getTime()) / (1000 * 60 * 60 * 24));
                  
                  let color = inv.status === 'pagada' ? 'var(--muted-foreground)' : (diffDays <= 0 ? '#ef4444' : (diffDays <= 3 ? '#f59e0b' : '#10b981'));

                  return (
                    <tr key={inv.id} style={{ borderTop: '1px solid var(--border)', background: inv.status === 'pagada' ? 'rgba(2, 6, 23, 0.01)' : 'transparent', transition: 'all 0.2s ease' }}>
                      <td style={{ padding: '1.25rem' }}>
                        <div style={{ fontWeight: 800, fontSize: '0.95rem' }}>{inv.invoice_number}</div>
                        <div style={{ fontSize: '0.75rem', color: 'var(--muted-foreground)', display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
                          <User size={12} /> {inv.providers?.name || 'Proveedor Desconocido'}
                        </div>
                      </td>
                      <td style={{ padding: '1.25rem' }}>
                        <div style={{ fontWeight: 950, fontSize: '1rem', color: 'var(--foreground)' }}>${inv.total.toLocaleString()}</div>
                      </td>
                      <td style={{ padding: '1.25rem' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', color, fontWeight: 800, fontSize: '0.85rem' }}>
                          <Clock size={14} /> {vDate.toLocaleDateString()}
                        </div>
                        <div style={{ fontSize: '0.65rem', color, fontWeight: 900, marginTop: '0.2rem' }}>
                          {inv.status === 'pagada' ? 'COMPLETADA' : (diffDays <= 0 ? 'VENCIDA' : `EN ${diffDays} DÍAS`)}
                        </div>
                      </td>
                      <td style={{ padding: '1.25rem', textAlign: 'right' }}>
                        <div style={{ display: 'flex', gap: '0.5rem', justifyContent: 'flex-end' }}>
                          <button 
                            onClick={() => setInvoiceToView(inv)}
                            className="glass"
                            style={{ padding: '0.6rem', borderRadius: '10px', border: '1px solid var(--border)', color: 'var(--muted-foreground)', cursor: 'pointer', transition: 'all 0.2s ease' }}
                            title="Ver Detalle"
                          >
                            <Eye size={16} />
                          </button>

                          {inv.status === 'pendiente' && (
                            <button 
                              onClick={() => handleMarcarComoPagada(inv)} 
                              className="btn-primary"
                              style={{ padding: '0.5rem 1rem', borderRadius: '10px', fontSize: '0.75rem', fontWeight: 800, display: 'flex', alignItems: 'center', gap: '0.5rem', background: '#10b981', boxShadow: '0 4px 12px rgba(16, 185, 129, 0.2)' }}
                            >
                              <CheckCircle2 size={14} /> <span className="hidden sm:inline">Marcar como Paga</span>
                            </button>
                          )}
                          <button 
                            onClick={() => handleDelete(inv)} 
                            style={{ padding: '0.6rem', borderRadius: '10px', border: '1px solid rgba(239, 68, 68, 0.1)', color: '#ef4444', background: 'rgba(239, 68, 68, 0.05)', cursor: 'pointer', transition: 'all 0.2s ease' }}
                          >
                            <Trash2 size={16} />
                          </button>
                        </div>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </div>

      <AnimatePresence>
        {invoiceToView && (
          <InvoiceDetailModal 
            invoice={invoiceToView} 
            onClose={() => setInvoiceToView(null)} 
          />
        )}
      </AnimatePresence>
    </div>
  );
}

function InvoiceDetailModal({ invoice, onClose }: { invoice: Invoice, onClose: () => void }) {
  const [items, setItems] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchItems = async () => {
      setLoading(true);
      try {
        const { data, error } = await supabase
          .from('invoice_items')
          .select('*')
          .eq('invoice_id', invoice.id);
        
        if (error) throw error;
        setItems(data || []);
      } catch (err) {
        toast.error("Error al cargar ítems");
      } finally {
        setLoading(false);
      }
    };

    fetchItems();
  }, [invoice.id]);

  return (
    <div style={{ position: 'fixed', inset: 0, zIndex: 1100, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '1rem' }}>
      <motion.div 
        initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
        onClick={onClose}
        style={{ position: 'absolute', inset: 0, background: 'rgba(2, 6, 23, 0.6)', backdropFilter: 'blur(10px)' }} 
      />
      <motion.div 
        initial={{ scale: 0.9, opacity: 0, y: 20 }} animate={{ scale: 1, opacity: 1, y: 0 }} exit={{ scale: 0.9, opacity: 0, y: 20 }}
        className="card-premium" 
        style={{ width: '100%', maxWidth: '800px', maxHeight: '85vh', position: 'relative', zIndex: 10, padding: '2rem', overflow: 'hidden', display: 'flex', flexDirection: 'column' }}
      >
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '1.5rem' }}>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '0.25rem' }}>
              <div style={{ background: 'rgba(13, 148, 136, 0.1)', color: 'var(--primary)', padding: '0.5rem', borderRadius: '10px' }}>
                <FileText size={24} />
              </div>
              <h2 style={{ fontSize: '1.5rem', fontWeight: 950 }}>Factura {invoice.invoice_number}</h2>
            </div>
            <div style={{ display: 'flex', gap: '1rem', color: 'var(--muted-foreground)', fontSize: '0.85rem', fontWeight: 600 }}>
              <span style={{ display: 'flex', alignItems: 'center', gap: '0.3rem' }}><User size={14} /> {invoice.providers?.name}</span>
              <span style={{ display: 'flex', alignItems: 'center', gap: '0.3rem' }}><Calendar size={14} /> {new Date(invoice.date).toLocaleDateString()}</span>
            </div>
          </div>
          <button onClick={onClose} style={{ background: 'var(--secondary)', border: 'none', color: 'var(--muted-foreground)', padding: '0.5rem', borderRadius: '10px', cursor: 'pointer' }}><X size={20} /></button>
        </div>

        <div style={{ flex: 1, overflowY: 'auto' }}>
          {loading ? (
            <div style={{ padding: '4rem', display: 'flex', justifyContent: 'center' }}><Loader2 className="animate-spin" size={32} color="var(--primary)" /></div>
          ) : (
            <div className="glass" style={{ borderRadius: '16px', overflow: 'hidden' }}>
              <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                <thead>
                  <tr style={{ fontSize: '0.65rem', textTransform: 'uppercase', color: 'var(--muted-foreground)', textAlign: 'left', background: 'rgba(2, 6, 23, 0.02)' }}>
                    <th style={{ padding: '1rem' }}>Producto / Lote</th>
                    <th style={{ padding: '1rem', textAlign: 'center' }}>Cantidad</th>
                    <th style={{ padding: '1rem', textAlign: 'right' }}>Vlr Unit</th>
                    <th style={{ padding: '1rem', textAlign: 'right' }}>Subtotal</th>
                  </tr>
                </thead>
                <tbody>
                  {items.map((item) => (
                    <tr key={item.id} style={{ borderTop: '1px solid var(--border)' }}>
                      <td style={{ padding: '1rem' }}>
                        <div style={{ fontWeight: 800, fontSize: '0.85rem' }}>{item.product_name}</div>
                        <div style={{ fontSize: '0.7rem', color: 'var(--muted-foreground)', display: 'flex', alignItems: 'center', gap: '0.2rem' }}>
                          <Hash size={10} /> {item.batch || 'S/L'}
                        </div>
                      </td>
                      <td style={{ padding: '1rem', textAlign: 'center', fontWeight: 800, fontSize: '0.9rem' }}>
                        {item.quantity} <span style={{ fontSize: '0.7rem', color: 'var(--muted-foreground)' }}>{invoice.category === 'alimento' ? 'bultos' : 'uds'}</span>
                        {item.kilos > 0 && <div style={{ fontSize: '0.7rem', opacity: 0.6 }}>({item.kilos} kg)</div>}
                      </td>
                      <td style={{ padding: '1rem', textAlign: 'right', fontWeight: 700 }}>${Number(item.unit_price).toLocaleString()}</td>
                      <td style={{ padding: '1rem', textAlign: 'right', fontWeight: 900, color: 'var(--primary)' }}>${(item.quantity * item.unit_price).toLocaleString()}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>

        <div style={{ marginTop: '1.5rem', paddingTop: '1.25rem', borderTop: '1px solid var(--border)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div>
            <div style={{ fontSize: '0.7rem', fontWeight: 800, color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Total Factura (IVA incl.)</div>
            <div style={{ fontSize: '1.5rem', fontWeight: 950, color: 'var(--primary)' }}>${invoice.total.toLocaleString()}</div>
          </div>
          <button onClick={onClose} className="btn-primary" style={{ padding: '0.75rem 2rem' }}>Entendido</button>
        </div>
      </motion.div>
    </div>
  );
}
