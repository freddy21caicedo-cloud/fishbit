'use client';
import { useEffect, useState } from 'react';
import { supabase } from '@/lib/supabase';

const cop = (v: number) => v.toLocaleString('es-CO', { style: 'currency', currency: 'COP', maximumFractionDigits: 0 });

export function CostosPorEstanque({ unitId }: { unitId: string }) {
  const [cards, setCards] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!unitId) return;
    (async () => {
      setLoading(true);
      const [pondsRes, nominaRes, jornalesRes, alimentRes, speciesRes] = await Promise.all([
        supabase.from('estanques').select('id, name, current_biomass_kg, current_count, current_species, is_polyculture').eq('unit_id', unitId).eq('status', 'con_peces'),
        supabase.from('nomina').select('monto').eq('unit_id', unitId),
        supabase.from('jornales').select('total, estanque_id').eq('unit_id', unitId),
        supabase.from('alimentacion_diaria').select('quantity_kg, inventory_id, estanque_id, inventory(costo_por_bulto, name)').eq('unit_id', unitId),
        supabase.from('pond_species').select('estanque_id, species_name, current_biomass_kg').eq('unit_id', unitId),
      ]);

      const ponds = pondsRes.data || [];
      const totalBiomasa = ponds.reduce((s: number, p: any) => s + parseFloat(p.current_biomass_kg || 0), 0);
      const totalNomina = (nominaRes.data || []).reduce((s: number, n: any) => s + parseFloat(n.monto || 0), 0);
      const jornalesGenerales = (jornalesRes.data || []).filter((j: any) => !j.estanque_id).reduce((s: number, j: any) => s + parseFloat(j.total || 0), 0);

      // Food cost per pond
      const alimentByPond: Record<string, number> = {};
      (alimentRes.data || []).forEach((r: any) => {
        const inv = r.inventory as any;
        const costoPorBulto = parseFloat(inv?.costo_por_bulto || 0);
        if (costoPorBulto === 0) return;
        const bagWeight = parseInt((inv?.name || '').match(/(\d+)\s*kg/i)?.[1] || '40');
        const cost = (parseFloat(r.quantity_kg) || 0) * (costoPorBulto / bagWeight);
        alimentByPond[r.estanque_id] = (alimentByPond[r.estanque_id] || 0) + cost;
      });

      const result = ponds.map((p: any) => {
        const biomasa = parseFloat(p.current_biomass_kg || 0);
        const fraccionBiomasa = totalBiomasa > 0 ? biomasa / totalBiomasa : 0;

        const costoAlimento = alimentByPond[p.id] || 0;
        const nominaProrr = totalNomina * fraccionBiomasa;
        const jornalesProrr = jornalesGenerales * fraccionBiomasa;
        const jornalesDirectos = (jornalesRes.data || []).filter((j: any) => j.estanque_id === p.id).reduce((s: number, j: any) => s + parseFloat(j.total || 0), 0);
        const totalCosto = costoAlimento + nominaProrr + jornalesProrr + jornalesDirectos;
        const costoPorKg = biomasa > 0 ? totalCosto / biomasa : 0;

        // Per-species breakdown for polycultures
        let especies: any[] = [];
        if (p.is_polyculture) {
          const pondSpecies = (speciesRes.data || []).filter((s: any) => s.estanque_id === p.id);
          const totalBiomasaEstanque = pondSpecies.reduce((s: number, sp: any) => s + parseFloat(sp.current_biomass_kg || 0), 0);
          especies = pondSpecies.map((sp: any) => {
            const fracEsp = totalBiomasaEstanque > 0 ? parseFloat(sp.current_biomass_kg || 0) / totalBiomasaEstanque : 0;
            const costoEsp = totalCosto * fracEsp;
            const bioEsp = parseFloat(sp.current_biomass_kg || 0);
            return { name: sp.species_name, biomasa: bioEsp, costoPorKg: bioEsp > 0 ? costoEsp / bioEsp : 0, total: costoEsp };
          });
        }

        return { ...p, biomasa, costoAlimento, nominaProrr, jornalesProrr, jornalesDirectos, totalCosto, costoPorKg, especies };
      });

      setCards(result);
      setLoading(false);
    })();
  }, [unitId]);

  if (loading) return <div style={{ padding: '2rem', textAlign: 'center', color: 'var(--muted-foreground)' }}>Calculando costos...</div>;

  return (
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))', gap: '1.25rem' }}>
      {cards.map(p => (
        <div key={p.id} className="card-premium" style={{ padding: '1.5rem' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '1rem' }}>
            <h3 style={{ fontWeight: 900, fontSize: '1.1rem' }}>{p.name}</h3>
            <div style={{ textAlign: 'right' }}>
              <div style={{ fontSize: '1.5rem', fontWeight: 900, color: 'var(--primary)' }}>{cop(p.costoPorKg)}</div>
              <div style={{ fontSize: '0.65rem', color: 'var(--muted-foreground)', fontWeight: 700 }}>por kg</div>
            </div>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.4rem', marginBottom: '1rem' }}>
            {[
              { label: 'Alimento', value: p.costoAlimento, color: '#8b5cf6' },
              { label: 'Nómina (prorr.)', value: p.nominaProrr, color: '#3b82f6' },
              { label: 'Jornales generales', value: p.jornalesProrr, color: '#f59e0b' },
              { label: 'Jornales directos', value: p.jornalesDirectos, color: '#ef4444' },
            ].map(item => (
              <div key={item.label} style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.78rem' }}>
                <span style={{ color: 'var(--muted-foreground)', fontWeight: 600 }}>{item.label}</span>
                <span style={{ fontWeight: 800, color: item.color }}>{cop(item.value)}</span>
              </div>
            ))}
            <div style={{ borderTop: '1px solid var(--border)', paddingTop: '0.4rem', display: 'flex', justifyContent: 'space-between', fontSize: '0.85rem' }}>
              <span style={{ fontWeight: 800 }}>Total Costo</span>
              <span style={{ fontWeight: 900, color: 'var(--foreground)' }}>{cop(p.totalCosto)}</span>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.78rem', color: 'var(--muted-foreground)' }}>
              <span>Biomasa actual</span>
              <span style={{ fontWeight: 700 }}>{p.biomasa.toFixed(1)} kg</span>
            </div>
          </div>

          {p.is_polyculture && p.especies.length > 0 && (
            <div style={{ borderTop: '1px solid var(--border)', paddingTop: '1rem' }}>
              <div style={{ fontSize: '0.65rem', fontWeight: 900, color: 'var(--muted-foreground)', textTransform: 'uppercase', marginBottom: '0.5rem' }}>Desglose por Especie</div>
              {p.especies.map((esp: any) => (
                <div key={esp.name} style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.78rem', padding: '0.3rem 0' }}>
                  <span style={{ fontWeight: 700 }}>{esp.name}</span>
                  <span style={{ fontWeight: 900, color: '#10b981' }}>{cop(esp.costoPorKg)}/kg <span style={{ fontSize: '0.65rem', opacity: 0.7 }}>({esp.biomasa.toFixed(1)} kg)</span></span>
                </div>
              ))}
            </div>
          )}
        </div>
      ))}
    </div>
  );
}
