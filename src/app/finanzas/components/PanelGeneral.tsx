'use client';
import { useEffect, useState } from 'react';
import { supabase } from '@/lib/supabase';
import { TrendingUp, DollarSign, Wallet, Fish, BarChart3 } from 'lucide-react';

const cop = (v: number) => v.toLocaleString('es-CO', { style: 'currency', currency: 'COP', maximumFractionDigits: 0 });

export function PanelGeneral({ unitId }: { unitId: string }) {
  const [data, setData] = useState<any>(null);

  useEffect(() => {
    if (!unitId) return;
    (async () => {
      const [pondsRes, ventasRes, nominaRes, jornalesRes, alimentRes, invoiceItemsRes] = await Promise.all([
        supabase.from('estanques').select('id, name, current_biomass_kg').eq('unit_id', unitId).eq('status', 'con_peces'),
        supabase.from('ventas').select('total, estado_pago').eq('unit_id', unitId),
        supabase.from('nomina').select('monto').eq('unit_id', unitId),
        supabase.from('jornales').select('total').eq('unit_id', unitId),
        supabase.from('alimentacion_diaria').select('quantity_kg').eq('unit_id', unitId),
        supabase.from('invoice_items').select('product_name, unit_price, flete_per_unit, iva_percent, quantity, kilos').eq('unit_id', unitId),
      ]);

      const ingresos = (ventasRes.data || []).reduce((s: number, v: any) => s + (parseFloat(v.total) || 0), 0);
      const porCobrar = (ventasRes.data || []).filter((v: any) => v.estado_pago === 'pendiente').reduce((s: number, v: any) => s + (parseFloat(v.total) || 0), 0);
      const totalNomina = (nominaRes.data || []).reduce((s: number, n: any) => s + (parseFloat(n.monto) || 0), 0);
      const totalJornales = (jornalesRes.data || []).reduce((s: number, j: any) => s + (parseFloat(j.total) || 0), 0);

      // Costo alimento = suma de (bultos × precio_bulto_con_iva_y_flete) por cada item de factura
      let costoAlimento = 0;
      (invoiceItemsRes.data || []).forEach((r: any) => {
        const qty = parseFloat(r.quantity) || 0;
        const unitPrice = parseFloat(r.unit_price) || 0;
        const flete = parseFloat(r.flete_per_unit) || 0;
        const iva = parseFloat(r.iva_percent) || 0;
        costoAlimento += qty * (unitPrice + flete) * (1 + iva / 100);
      });

      const totalBiomasa = (pondsRes.data || []).reduce((s: number, p: any) => s + (parseFloat(p.current_biomass_kg) || 0), 0);
      const totalCostos = costoAlimento + totalNomina + totalJornales;
      const margen = ingresos - totalCostos;
      const flujoCaja = ingresos - porCobrar - totalCostos;

      setData({ ingresos, totalCostos, margen, flujoCaja, porCobrar, totalBiomasa, costoAlimento, totalNomina, totalJornales });
    })();
  }, [unitId]);

  if (!data) return <div className="card-premium" style={{ padding: '2rem', textAlign: 'center', color: 'var(--muted-foreground)' }}>Cargando panel...</div>;

  const stats = [
    { label: 'Ingresos Totales', value: cop(data.ingresos), color: '#10b981', icon: TrendingUp, sub: `Por cobrar: ${cop(data.porCobrar)}` },
    { label: 'Costos Acumulados', value: cop(data.totalCostos), color: '#ef4444', icon: BarChart3, sub: `Alimento: ${cop(data.costoAlimento)} · Nómina: ${cop(data.totalNomina)}` },
    { label: 'Margen Contribución', value: cop(data.margen), color: data.margen >= 0 ? '#3b82f6' : '#ef4444', icon: DollarSign, sub: data.ingresos > 0 ? `${((data.margen / data.ingresos) * 100).toFixed(1)}% sobre ingresos` : 'Sin ventas aún' },
    { label: 'Flujo de Caja', value: cop(data.flujoCaja), color: '#f59e0b', icon: Wallet, sub: `Biomasa activa: ${data.totalBiomasa.toFixed(1)} kg` },
  ];

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))', gap: '1rem' }}>
        {stats.map((s) => (
          <div key={s.label} className="card-premium" style={{ padding: '1.5rem', borderLeft: `4px solid ${s.color}` }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '1rem' }}>
              <div style={{ padding: '0.5rem', background: `${s.color}15`, borderRadius: '10px', color: s.color }}><s.icon size={20} /></div>
              <div style={{ fontSize: '0.7rem', fontWeight: 800, color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>{s.label}</div>
            </div>
            <div style={{ fontSize: '1.6rem', fontWeight: 900, color: s.color, letterSpacing: '-0.02em', marginBottom: '0.25rem' }}>{s.value}</div>
            <div style={{ fontSize: '0.72rem', color: 'var(--muted-foreground)', fontWeight: 600 }}>{s.sub}</div>
          </div>
        ))}
      </div>

      <div className="card-premium" style={{ padding: '1.5rem' }}>
        <h3 style={{ fontWeight: 800, fontSize: '0.9rem', marginBottom: '1rem', textTransform: 'uppercase', color: 'var(--muted-foreground)' }}>Desglose de Costos</h3>
        <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
          {[
            { label: 'Alimento', value: data.costoAlimento, pct: data.totalCostos > 0 ? (data.costoAlimento / data.totalCostos) * 100 : 0, color: '#8b5cf6' },
            { label: 'Nómina', value: data.totalNomina, pct: data.totalCostos > 0 ? (data.totalNomina / data.totalCostos) * 100 : 0, color: '#3b82f6' },
            { label: 'Jornales', value: data.totalJornales, pct: data.totalCostos > 0 ? (data.totalJornales / data.totalCostos) * 100 : 0, color: '#f59e0b' },
          ].map((item) => (
            <div key={item.label}>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '0.25rem' }}>
                <span style={{ fontSize: '0.8rem', fontWeight: 700 }}>{item.label}</span>
                <span style={{ fontSize: '0.8rem', fontWeight: 900, color: item.color }}>{cop(item.value)} ({item.pct.toFixed(1)}%)</span>
              </div>
              <div style={{ height: '6px', background: 'var(--secondary)', borderRadius: '3px', overflow: 'hidden' }}>
                <div style={{ width: `${item.pct}%`, height: '100%', background: item.color, borderRadius: '3px', transition: 'width 1s ease' }} />
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
