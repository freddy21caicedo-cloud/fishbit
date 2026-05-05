'use client';

import { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import { supabase } from '@/lib/supabase';
import { 
  CreditCard, 
  Search, 
  ArrowUpRight, 
  DollarSign, 
  Calendar, 
  CheckCircle2, 
  Clock, 
  AlertCircle,
  Loader2,
  Filter,
  FileText,
  TrendingUp
} from 'lucide-react';

export default function BillingManagementPage() {
  const [subscriptions, setSubscriptions] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchSubscriptions();
  }, []);

  const fetchSubscriptions = async () => {
    setLoading(true);
    const { data, error } = await supabase
      .from('subscriptions')
      .select(`
        *,
        units(name)
      `)
      .order('created_at', { ascending: false });

    if (!error) setSubscriptions(data);
    setLoading(false);
  };

  const stats = [
    { label: 'MRR (Mensual)', value: '$4,250.00', icon: DollarSign, color: '#10b981' },
    { label: 'Suscripciones Activas', value: '12', icon: CheckCircle2, color: '#3b82f6' },
    { label: 'Pagos Pendientes', value: '3', icon: Clock, color: '#f59e0b' },
    { label: 'Churn Rate', value: '2.4%', icon: TrendingUp, color: '#ef4444' }
  ];

  if (loading) {
    return (
      <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <Loader2 className="animate-spin" size={40} color="var(--primary)" />
      </div>
    );
  }

  return (
    <div style={{ padding: '2rem', maxWidth: '1200px', margin: '0 auto' }}>
      <header style={{ marginBottom: '3rem' }}>
        <h1 style={{ fontSize: '2rem', fontWeight: 800, marginBottom: '0.5rem' }}>Facturación y Suscripciones</h1>
        <p style={{ color: 'var(--muted-foreground)' }}>Gestión comercial y control de ingresos por unidad.</p>
      </header>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))', gap: '1.5rem', marginBottom: '3rem' }}>
        {stats.map((stat, i) => (
          <motion.div 
            key={i}
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: i * 0.1 }}
            className="card-premium"
            style={{ padding: '1.5rem', display: 'flex', alignItems: 'center', gap: '1.25rem' }}
          >
            <div style={{ padding: '0.75rem', background: `${stat.color}15`, borderRadius: '12px', color: stat.color }}>
              <stat.icon size={24} />
            </div>
            <div>
              <div style={{ fontSize: '0.875rem', color: 'var(--muted-foreground)', fontWeight: 600 }}>{stat.label}</div>
              <div style={{ fontSize: '1.5rem', fontWeight: 800 }}>{stat.value}</div>
            </div>
          </motion.div>
        ))}
      </div>

      <div className="card-premium" style={{ padding: 0, overflow: 'hidden' }}>
        <div style={{ padding: '1.5rem', borderBottom: '1px solid var(--border)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <h2 style={{ fontSize: '1.25rem', fontWeight: 700 }}>Historial de Suscripciones</h2>
          <div style={{ display: 'flex', gap: '1rem' }}>
            <div style={{ position: 'relative' }}>
              <Search size={16} style={{ position: 'absolute', left: '0.75rem', top: '50%', transform: 'translateY(-50%)', color: 'var(--muted-foreground)' }} />
              <input type="text" placeholder="Buscar factura..." style={{ padding: '0.5rem 0.75rem 0.5rem 2.25rem', borderRadius: '8px', border: '1px solid var(--border)', background: 'var(--secondary)', fontSize: '0.875rem', outline: 'none' }} />
            </div>
            <button style={{ padding: '0.5rem 1rem', borderRadius: '8px', border: '1px solid var(--border)', background: 'none', fontSize: '0.875rem', fontWeight: 600, display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <FileText size={16} />
              Exportar
            </button>
          </div>
        </div>
        <div style={{ overflowX: 'auto' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse' }}>
            <thead>
              <tr style={{ textAlign: 'left', background: 'rgba(0,0,0,0.01)' }}>
                <th style={{ padding: '1rem 1.5rem', fontSize: '0.75rem', fontWeight: 800, color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Unidad</th>
                <th style={{ padding: '1rem 1.5rem', fontSize: '0.75rem', fontWeight: 800, color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Plan</th>
                <th style={{ padding: '1rem 1.5rem', fontSize: '0.75rem', fontWeight: 800, color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Estado</th>
                <th style={{ padding: '1rem 1.5rem', fontSize: '0.75rem', fontWeight: 800, color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Próximo Pago</th>
                <th style={{ padding: '1rem 1.5rem', fontSize: '0.75rem', fontWeight: 800, color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Monto</th>
                <th style={{ padding: '1rem 1.5rem', textAlign: 'right' }}></th>
              </tr>
            </thead>
            <tbody>
              {subscriptions.length > 0 ? subscriptions.map((sub) => (
                <tr key={sub.id} style={{ borderTop: '1px solid var(--border)', transition: 'background 0.2s' }}>
                  <td style={{ padding: '1rem 1.5rem', fontWeight: 700 }}>{sub.units.name}</td>
                  <td style={{ padding: '1rem 1.5rem' }}>
                    <span style={{ textTransform: 'capitalize' }}>{sub.plan_type}</span>
                  </td>
                  <td style={{ padding: '1rem 1.5rem' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', color: sub.status === 'active' ? '#10b981' : '#ef4444', fontSize: '0.875rem', fontWeight: 600 }}>
                      <div style={{ width: '6px', height: '6px', borderRadius: '50%', background: 'currentColor' }}></div>
                      {sub.status === 'active' ? 'Pagado' : 'Pendiente'}
                    </div>
                  </td>
                  <td style={{ padding: '1rem 1.5rem', color: 'var(--muted-foreground)', fontSize: '0.875rem' }}>
                    {new Date(sub.next_billing_date).toLocaleDateString()}
                  </td>
                  <td style={{ padding: '1rem 1.5rem', fontWeight: 800 }}>${sub.price}</td>
                  <td style={{ padding: '1rem 1.5rem', textAlign: 'right' }}>
                    <button style={{ color: 'var(--primary)', background: 'none', border: 'none', fontWeight: 700, fontSize: '0.875rem', cursor: 'pointer' }}>Gestionar</button>
                  </td>
                </tr>
              )) : (
                <tr>
                  <td colSpan={6} style={{ padding: '3rem', textAlign: 'center', color: 'var(--muted-foreground)' }}>
                    <AlertCircle size={40} style={{ margin: '0 auto 1rem', opacity: 0.3 }} />
                    <p>No hay suscripciones registradas aún.</p>
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
