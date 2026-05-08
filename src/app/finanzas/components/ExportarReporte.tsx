'use client';
import { useState } from 'react';
import { supabase } from '@/lib/supabase';
import { FileSpreadsheet, Download } from 'lucide-react';
import * as XLSX from 'xlsx';

const cop = (v: number) => v.toLocaleString('es-CO', { style: 'currency', currency: 'COP', maximumFractionDigits: 0 });

export function ExportarReporte({ unitId }: { unitId: string }) {
  const [loading, setLoading] = useState(false);

  const generate = async () => {
    setLoading(true);
    try {
      const [pondsRes, ventasRes, nominaRes, jornalesRes, alimentRes, invItemsRes, invRes] = await Promise.all([
        supabase.from('estanques').select('id, name, current_biomass_kg').eq('unit_id', unitId).eq('status', 'con_peces'),
        supabase.from('ventas').select('*, estanques(name)').eq('unit_id', unitId),
        supabase.from('nomina').select('monto').eq('unit_id', unitId),
        supabase.from('jornales').select('total, estanque_id').eq('unit_id', unitId),
        supabase.from('alimentacion_diaria').select('quantity_kg, estanque_id').eq('unit_id', unitId),
        supabase.from('invoice_items').select('product_name, unit_price, flete_per_unit, iva_percent, quantity, kilos').eq('unit_id', unitId),
        supabase.from('inventory').select('name, current_stock, costo_por_bulto, category').eq('unit_id', unitId).eq('category', 'alimento'),
      ]);

      const ponds = pondsRes.data || [];
      const totalBiomasa = ponds.reduce((s: number, p: any) => s + parseFloat(p.current_biomass_kg || 0), 0);
      const totalNomina = (nominaRes.data || []).reduce((s: number, n: any) => s + parseFloat(n.monto || 0), 0);
      const jornalesGenerales = (jornalesRes.data || []).filter((j: any) => !j.estanque_id).reduce((s: number, j: any) => s + parseFloat(j.total || 0), 0);

      // Costo promedio por kg de alimento desde facturas
      let costoKgTotal = 0; let costoKgCount = 0;
      (invItemsRes.data || []).forEach((r: any) => {
        const kilos = parseFloat(r.kilos) || 0;
        if (kilos === 0) return;
        const qty = parseFloat(r.quantity) || 0;
        const unitPrice = parseFloat(r.unit_price) || 0;
        const flete = parseFloat(r.flete_per_unit) || 0;
        const iva = parseFloat(r.iva_percent) || 0;
        costoKgTotal += (qty * (unitPrice + flete) * (1 + iva / 100)) / kilos;
        costoKgCount++;
      });
      const costoKgPromedio = costoKgCount > 0 ? costoKgTotal / costoKgCount : 0;

      const kgByPond: Record<string, number> = {};
      (alimentRes.data || []).forEach((r: any) => { kgByPond[r.estanque_id] = (kgByPond[r.estanque_id] || 0) + (parseFloat(r.quantity_kg) || 0); });

      // SHEET 1: Rentabilidad por estanque
      const hoja1 = ponds.map((p: any) => {
        const biomasa = parseFloat(p.current_biomass_kg || 0);
        const frac = totalBiomasa > 0 ? biomasa / totalBiomasa : 0;
        const costoAlim = alimentByPond[p.id] || 0;
        const costoProrr = (totalNomina + jornalesGenerales) * frac;
        const jornDir = (jornalesRes.data || []).filter((j: any) => j.estanque_id === p.id).reduce((s: number, j: any) => s + parseFloat(j.total || 0), 0);
        const totalCosto = costoAlim + costoProrr + jornDir;
        const ingresos = (ventasRes.data || []).filter((v: any) => v.estanque_id === p.id).reduce((s: number, v: any) => s + parseFloat(v.total || 0), 0);
        const margen = ingresos - totalCosto;
        return { Estanque: p.name, 'Biomasa (kg)': biomasa.toFixed(1), 'Costo Alimento': cop(costoAlim), 'Costo Nómina/Jornales': cop(costoProrr + jornDir), 'Costo Total': cop(totalCosto), 'Ingresos Ventas': cop(ingresos), 'Margen': cop(margen), '% Margen': ingresos > 0 ? ((margen / ingresos) * 100).toFixed(1) + '%' : '—' };
      });

      // SHEET 2: Eficiencia FCA
      const alimentQtyByPond: Record<string, number> = {};
      (alimentRes.data || []).forEach((r: any) => { alimentQtyByPond[r.estanque_id] = (alimentQtyByPond[r.estanque_id] || 0) + parseFloat(r.quantity_kg || 0); });
      const hoja2 = ponds.map((p: any) => {
        const consumoKg = alimentQtyByPond[p.id] || 0;
        const biomasa = parseFloat(p.current_biomass_kg || 0);
        const fca = biomasa > 0 ? (consumoKg / biomasa).toFixed(2) : '—';
        const costoAlim = (kgByPond[p.id] || 0) * costoKgPromedio;
        const costoPorKgProducido = biomasa > 0 ? costoAlim / biomasa : 0;
        return { Estanque: p.name, 'Consumo Total (kg)': consumoKg.toFixed(1), 'Biomasa Actual (kg)': biomasa.toFixed(1), 'FCA': fca, 'Costo Alimento/kg Prod.': cop(costoPorKgProducido) };
      });

      // SHEET 3: Punto de equilibrio
      const hoja3 = ponds.map((p: any) => {
        const biomasa = parseFloat(p.current_biomass_kg || 0);
        const frac = totalBiomasa > 0 ? biomasa / totalBiomasa : 0;
        const costoAlim = alimentByPond[p.id] || 0;
        const costoProrr = (totalNomina + jornalesGenerales) * frac;
        const jornDir = (jornalesRes.data || []).filter((j: any) => j.estanque_id === p.id).reduce((s: number, j: any) => s + parseFloat(j.total || 0), 0);
        const totalCosto = costoAlim + costoProrr + jornDir;
        const precioMin = biomasa > 0 ? totalCosto / biomasa : 0;
        return { Estanque: p.name, 'Biomasa Actual (kg)': biomasa.toFixed(1), 'Costo Total Acumulado': cop(totalCosto), 'Precio Mínimo/kg': cop(precioMin), 'Nota': 'Precio mínimo para cubrir costos actuales' };
      });

      // SHEET 4: Inventario crítico
      const hoja4 = (invRes.data || []).map((i: any) => {
        const bagW = parseInt((i.name || '').match(/(\d+)\s*kg/i)?.[1] || '40');
        const bultos = parseFloat(i.current_stock || 0) / bagW;
        return { Producto: i.name, 'Stock (kg)': parseFloat(i.current_stock || 0).toFixed(1), 'Bultos': bultos.toFixed(1), 'Costo/Bulto': cop(parseFloat(i.costo_por_bulto || 0)), 'Estado': bultos < 10 ? '⚠️ BAJO' : '✅ OK' };
      });

      const wb = XLSX.utils.book_new();
      XLSX.utils.book_append_sheet(wb, XLSX.utils.json_to_sheet(hoja1), 'Rentabilidad');
      XLSX.utils.book_append_sheet(wb, XLSX.utils.json_to_sheet(hoja2), 'Eficiencia FCA');
      XLSX.utils.book_append_sheet(wb, XLSX.utils.json_to_sheet(hoja3), 'Punto de Equilibrio');
      XLSX.utils.book_append_sheet(wb, XLSX.utils.json_to_sheet(hoja4), 'Inventario Critico');
      XLSX.writeFile(wb, `FishBit_Reporte_${new Date().toISOString().slice(0, 10)}.xlsx`);
    } catch (e: any) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem', alignItems: 'center', padding: '3rem 1rem' }}>
      <div style={{ width: '80px', height: '80px', background: 'rgba(16,185,129,0.1)', borderRadius: '24px', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#10b981' }}>
        <FileSpreadsheet size={40} />
      </div>
      <div style={{ textAlign: 'center' }}>
        <h2 style={{ fontWeight: 900, fontSize: '1.5rem', marginBottom: '0.5rem' }}>Exportar Reporte Excel</h2>
        <p style={{ color: 'var(--muted-foreground)', fontWeight: 600, maxWidth: '480px' }}>Genera un Excel con 4 hojas de análisis financiero: rentabilidad por estanque, eficiencia FCA, punto de equilibrio e inventario crítico.</p>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: '1rem', maxWidth: '500px', width: '100%' }}>
        {['📊 Rentabilidad por Estanque', '⚡ Eficiencia de Conversión (FCA)', '💰 Punto de Equilibrio por Lote', '📦 Inventario Crítico de Alimento'].map(item => (
          <div key={item} className="card-premium" style={{ padding: '1rem', fontSize: '0.82rem', fontWeight: 700, textAlign: 'center' }}>{item}</div>
        ))}
      </div>

      <button onClick={generate} disabled={loading}
        className="btn-primary"
        style={{ padding: '1rem 2.5rem', borderRadius: '14px', fontSize: '1rem', fontWeight: 900, display: 'flex', alignItems: 'center', gap: '0.75rem', opacity: loading ? 0.7 : 1 }}>
        <Download size={20} />
        {loading ? 'Generando...' : 'Generar y Descargar Excel'}
      </button>
    </div>
  );
}
