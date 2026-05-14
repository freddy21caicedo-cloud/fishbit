'use client';

import { useEffect, useState } from 'react';
import { supabase } from '@/lib/supabase';
import { useUnit } from '../components/providers/UnitProvider';
import { 
  Utensils, 
  Skull, 
  Fish, 
  ShoppingBag,
  Loader2
} from 'lucide-react';
import { AnimatePresence } from 'framer-motion';

// UI Components
import { StatCard } from '../components/ui/StatCard';
import dynamic from 'next/dynamic';

const TrendsChart = dynamic(() => import('./components/TrendsChart').then(mod => mod.TrendsChart), { 
  ssr: false,
  loading: () => <div className="card-premium" style={{ height: '450px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><Loader2 className="animate-spin" /></div>
});

import { FinanceSummary } from './components/FinanceSummary';
import { FeedInventorySummary } from './components/FeedInventorySummary';

import { 
  Profile, 
  Pond, 
  DashboardStats, 
  AlertThresholds, 
  FinanceData, 
  ChartDataPoint,
} from '@/lib/database.types';

export default function Dashboard() {
  const { activeUnitId, activeUnit } = useUnit();
  
  const [userRole, setUserRole] = useState<Profile['role'] | null>(null);
  const [isLoadingRole, setIsLoadingRole] = useState(true);
  const [stats, setStats] = useState<DashboardStats>({
    biomass: { total: 0, details: [] },
    consumption: { total: 0, details: [] },
    mortality: { total: 0, percent: '0.0', details: [] },
    inventory: { total: 0, details: [] }
  });
  
  const [alertThresholds, setAlertThresholds] = useState<AlertThresholds>({
    oxygenMin: 4.5, oxygenMax: 9.0,
    tempMin: 26.0, tempMax: 31.0,
    phMin: 6.5, phMax: 8.5,
    mortalityMax: 5.0,
    inventoryMin: {}
  });

  const [ponds, setPonds] = useState<Pond[]>([]);
  const [selectedPond, setSelectedPond] = useState<string>('');
  const [selectedParam, setSelectedParam] = useState<string>('oxigeno');
  const [selectedSpecies, setSelectedSpecies] = useState<string>('Todas');
  const [pondSpecies, setPondSpecies] = useState<{ species_name: string }[]>([]);
  
  const [chartData, setChartData] = useState<ChartDataPoint[]>([]);
  const [isChartLoading, setIsChartLoading] = useState(false);
  
  const [financeData, setFinanceData] = useState<FinanceData>({ total: 0, food: 0, seeds: 0, pending: 0 });
  const [isFinanceLoading, setIsFinanceLoading] = useState(false);

  // 1. Initial Load: User Role
  useEffect(() => {
    const fetchUserRole = async () => {
      setIsLoadingRole(true);
      try {
        const { data: { user } } = await supabase.auth.getUser();
        if (user) {
          const { data: profile } = await supabase
            .from('profiles')
            .select('role')
            .eq('id', user.id)
            .single();
          if (profile) setUserRole(profile.role as Profile['role']);
        }
      } catch (error) {
        console.error("Error fetching user role:", error);
      } finally {
        setIsLoadingRole(false);
      }
    };
    fetchUserRole();
  }, []);

  // 2. Fetch Unit Data + Realtime subscription
  useEffect(() => {
    if (!activeUnitId) return;

    const fetchDashboardData = async () => {
      await Promise.all([
        fetchDetailedStats(activeUnitId),
        fetchFinanceData(activeUnitId),
        fetchPonds(activeUnitId),
        fetchThresholds(activeUnitId)
      ]);
    };

    fetchDashboardData();

    // Realtime: re-fetch stats when inventory or alimentacion_diaria changes
    const channel = supabase
      .channel(`dashboard-inventory-${activeUnitId}`)
      .on('postgres_changes', { event: '*', schema: 'public', table: 'inventory' }, () => {
        fetchDetailedStats(activeUnitId);
      })
      .on('postgres_changes', { event: '*', schema: 'public', table: 'alimentacion_diaria' }, () => {
        fetchDetailedStats(activeUnitId);
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [activeUnitId]);

  const fetchThresholds = async (unitId: string) => {
    try {
      const { data, error } = await supabase
        .from('unit_settings')
        .select('*')
        .eq('unit_id', unitId)
        .single();
      
      if (data && !error) {
        setAlertThresholds({
          oxygenMin: parseFloat(data.oxygen_min) || 4.5,
          oxygenMax: parseFloat(data.oxygen_max) || 9.0,
          tempMin: parseFloat(data.temp_min) || 26.0,
          tempMax: parseFloat(data.temp_max) || 31.0,
          phMin: parseFloat(data.ph_min) || 6.5,
          phMax: parseFloat(data.ph_max) || 8.5,
          mortalityMax: parseFloat(data.mortality_max) || 5.0,
          inventoryMin: data.inventory_min || {}
        });
      }
    } catch (err) {
      console.warn("Table unit_settings not found, using default thresholds.");
    }
  };

  const fetchPonds = async (unitId: string) => {
    const { data } = await supabase
      .from('estanques')
      .select('id, name, is_polyculture, status')
      .eq('unit_id', unitId)
      .eq('status', 'con_peces');
    
    if (data) {
      setPonds(data as Pond[]);
      if (data.length > 0 && !selectedPond) {
        setSelectedPond(data[0].id);
      }
    }
  };

  useEffect(() => {
    const fetchSpecies = async () => {
      if (!selectedPond) {
        setPondSpecies([]);
        setSelectedSpecies('Todas');
        return;
      }

      // Always query pond_species directly — do NOT rely on is_polyculture flag.
      // A pond where species were stocked on different dates (each with a single
      // row form) will have is_polyculture=false but multiple pond_species entries.
      const { data } = await supabase
        .from('pond_species')
        .select('species_name')
        .eq('estanque_id', selectedPond);

      if (data && data.length > 0) {
        // Deduplicate by species_name
        const unique = Array.from(
          new Map(data.map((s: any) => [s.species_name, s])).values()
        );
        setPondSpecies(unique);
        // Reset species filter whenever the pond changes
        setSelectedSpecies('Todas');
      } else {
        setPondSpecies([]);
        setSelectedSpecies('Todas');
      }
    };

    fetchSpecies();
  }, [selectedPond]);

  const fetchDetailedStats = async (unitId: string) => {
    try {
      // Fetch all active ponds for this unit
      const { data: pondsData } = await supabase
        .from('estanques')
        .select('id, name, current_biomass_kg, current_count')
        .eq('unit_id', unitId)
        .eq('status', 'con_peces');

      const activePonds = pondsData || [];

      // --- BIOMASS ---
      const biomassTotal = activePonds.reduce((s, p) => s + (parseFloat(p.current_biomass_kg) || 0), 0);
      const biomassDetails = activePonds.map(p => ({
        label: p.name,
        value: parseFloat((parseFloat(p.current_biomass_kg) || 0).toFixed(1)),
        unit: 'kg'
      }));

      // --- CONSUMPTION: total acumulado por referencia de producto (sin límite de fecha) ---
      const { data: alimentData } = await supabase
        .from('alimentacion_diaria')
        .select('quantity_kg, inventory_id, inventory(name)')
        .eq('unit_id', unitId);

      // Group by product reference
      const consumptionByProduct: Record<string, { name: string; total: number }> = {};
      (alimentData || []).forEach((r: any) => {
        const key = r.inventory_id || 'sin_ref';
        const productName = (r.inventory as any)?.name || 'Sin referencia';
        if (!consumptionByProduct[key]) {
          consumptionByProduct[key] = { name: productName, total: 0 };
        }
        consumptionByProduct[key].total += parseFloat(r.quantity_kg) || 0;
      });
      const consumptionTotal = Object.values(consumptionByProduct).reduce((s, v) => s + v.total, 0);
      const consumptionDetails = Object.values(consumptionByProduct).map(v => ({
        label: v.name,
        value: parseFloat(v.total.toFixed(1)),
        unit: 'kg'
      }));

      // --- MORTALITY ---
      const { data: mortData } = await supabase
        .from('mortality')
        .select('estanque_id, quantity, estanques(name)')
        .eq('unit_id', unitId);

      const mortalityByPond: Record<string, { name: string; total: number }> = {};
      activePonds.forEach(p => { mortalityByPond[p.id] = { name: p.name, total: 0 }; });
      (mortData || []).forEach((r: any) => {
        if (!mortalityByPond[r.estanque_id]) {
          mortalityByPond[r.estanque_id] = { name: r.estanques?.name || r.estanque_id, total: 0 };
        }
        mortalityByPond[r.estanque_id].total += parseInt(r.quantity) || 0;
      });
      const mortalityTotal = Object.values(mortalityByPond).reduce((s, v) => s + v.total, 0);
      const totalFishEver = activePonds.reduce((s, p) => s + (parseInt(p.current_count) || 0), 0) + mortalityTotal;
      const mortalityPct = totalFishEver > 0 ? ((mortalityTotal / totalFishEver) * 100).toFixed(1) : '0.0';
      const mortalityDetails = Object.values(mortalityByPond).map(v => ({
        label: v.name,
        value: v.total,
        unit: 'uds'
      }));

      // --- INVENTORY: total alimento en stock ---
      const { data: invData } = await supabase
        .from('inventory')
        .select('name, current_stock')
        .eq('unit_id', unitId)
        .eq('category', 'alimento');

      const inventoryTotal = (invData || []).reduce((s, i) => s + (parseFloat(i.current_stock) || 0), 0);
      const inventoryDetails = (invData || []).map(i => ({
        label: i.name,
        value: parseFloat((parseFloat(i.current_stock) || 0).toFixed(1)),
        unit: 'kg'
      }));

      setStats({
        biomass:     { total: parseFloat(biomassTotal.toFixed(1)),     details: biomassDetails },
        consumption: { total: parseFloat(consumptionTotal.toFixed(1)), details: consumptionDetails },
        mortality:   { total: mortalityTotal, percent: mortalityPct,   details: mortalityDetails },
        inventory:   { total: parseFloat(inventoryTotal.toFixed(1)),   details: inventoryDetails },
      });
    } catch (error: any) {
      console.error('fetchDetailedStats error:', error?.message);
    }
  };

  const fetchFinanceData = async (unitId: string) => {
    setIsFinanceLoading(true);
    try {
      // Assuming RPC 'get_unit_finance_summary'
      const { data, error } = await supabase.rpc('get_unit_finance_summary', { p_unit_id: unitId });
      
      if (error) throw error;
      if (data) {
        setFinanceData(data as FinanceData);
      }
    } catch (error: any) {
      console.error("RPC Error details (Finance):", {
        message: error?.message,
        code: error?.code,
        details: error?.details,
        hint: error?.hint,
      });
    } finally {
      setIsFinanceLoading(false);
    }
  };

  // 3. Dynamic Chart Load
  useEffect(() => {
    const fetchChartData = async () => {
      if (!selectedPond || !selectedParam) return;
      setIsChartLoading(true);

      try {
        let data: ChartDataPoint[] = [];

        const waterQualityParams = [
          'o2_mg_l', 'o2_perc', 'ph', 'temperature_c', 
          'alkalinity', 'ammonia_mg_l', 'nitrite_mg_l', 'nitrate_mg_l'
        ];

        if (selectedParam === 'oxigeno' || waterQualityParams.includes(selectedParam)) {
          const column = selectedParam === 'oxigeno' ? 'o2_mg_l' : selectedParam;
          const { data: res } = await supabase
            .from('water_quality')
            .select('*')
            .eq('estanque_id', selectedPond)
            .order('date', { ascending: true })
            .order('hour', { ascending: true });
          
          data = (res as any[])?.filter(r => r.date).map(r => ({ 
            name: `${r.date.split('-')[2]}/${r.date.split('-')[1]} ${r.hour || ''}`.trim(), 
            value: parseFloat(parseFloat(r[column] || 0).toFixed(2)) 
          })) || [];
        } else if (selectedParam === 'mortalidad') {
          let query = supabase
            .from('mortality')
            .select('quantity, date')
            .eq('estanque_id', selectedPond);
          
          if (selectedSpecies !== 'Todas') {
            query = query.eq('species_name', selectedSpecies);
          }

          const { data: res } = await query.order('date', { ascending: true });
          
          const grouped: Record<string, number> = {};
          (res || []).forEach(r => {
            if (!r.date) return;
            const dateKey = `${r.date.split('-')[2]}/${r.date.split('-')[1]}`;
            grouped[dateKey] = (grouped[dateKey] || 0) + (parseInt(r.quantity) || 0);
          });
          
          data = Object.entries(grouped).map(([name, value]) => ({ name, value }));
        } else if (selectedParam === 'biomasa') {
          let query = supabase
            .from('biometrias')
            .select('total_biomass_kg, date')
            .eq('estanque_id', selectedPond);

          if (selectedSpecies !== 'Todas') {
            query = query.eq('species_name', selectedSpecies);
          }

          const { data: res } = await query.order('date', { ascending: true });
          
          const grouped: Record<string, number> = {};
          (res || []).forEach(r => {
            if (!r.date) return;
            const dateKey = `${r.date.split('-')[2]}/${r.date.split('-')[1]}`;
            grouped[dateKey] = (grouped[dateKey] || 0) + (parseFloat(r.total_biomass_kg) || 0);
          });
          
          data = Object.entries(grouped).map(([name, value]) => ({ name, value: parseFloat(value.toFixed(1)) }));
        } else if (selectedParam === 'consumo') {
          const { data: res } = await supabase
            .from('alimentacion_diaria')
            .select('quantity_kg, date')
            .eq('estanque_id', selectedPond)
            .order('date', { ascending: true });
            
          const grouped: Record<string, number> = {};
          (res || []).forEach(r => {
            if (!r.date) return;
            const dateKey = `${r.date.split('-')[2]}/${r.date.split('-')[1]}`;
            grouped[dateKey] = (grouped[dateKey] || 0) + (parseFloat(r.quantity_kg) || 0);
          });
          
          data = Object.entries(grouped).map(([name, value]) => ({ name, value: parseFloat(value.toFixed(1)) }));

        } else if (selectedParam === 'peso_promedio') {
          // Growth curve starting from stocking weight (siembra) as point 0,
          // followed by biometria records in chronological order.

          // 1. Fetch all siembras for this pond with their details (stocking weights).
          //    Multiple siembras may exist if species were stocked on different dates.
          const { data: siembrasData } = await supabase
            .from('siembras')
            .select('date, siembra_details(species_name, avg_weight_gr)')
            .eq('estanque_id', selectedPond)
            .order('date', { ascending: true });

          // Ordered map to preserve chronological insertion order
          const orderedPoints: Map<string, { sum: number; count: number }> = new Map();

          // Add stocking weight points from each siembra
          (siembrasData || []).forEach((siembra: any) => {
            if (!siembra.date) return;
            const dateKey = `${siembra.date.split('-')[2]}/${siembra.date.split('-')[1]}`;
            const details: any[] = siembra.siembra_details || [];

            // Filter details by species if one is selected
            const relevantDetails = selectedSpecies !== 'Todas'
              ? details.filter((d: any) => d.species_name === selectedSpecies)
              : details;

            relevantDetails.forEach((d: any) => {
              const w = parseFloat(d.avg_weight_gr) || 0;
              if (w <= 0) return;
              if (!orderedPoints.has(dateKey)) orderedPoints.set(dateKey, { sum: 0, count: 0 });
              const pt = orderedPoints.get(dateKey)!;
              pt.sum += w;
              pt.count += 1;
            });
          });

          // 2. Fetch biometria records
          let bioQuery = supabase
            .from('biometrias')
            .select('avg_weight_gr, date, species_name')
            .eq('estanque_id', selectedPond);

          if (selectedSpecies !== 'Todas') {
            bioQuery = bioQuery.eq('species_name', selectedSpecies);
          }

          const { data: bioRes } = await bioQuery.order('date', { ascending: true });

          // Append biometria points (grouped + averaged per day)
          (bioRes || []).forEach((r: any) => {
            if (!r.date) return;
            const dateKey = `${r.date.split('-')[2]}/${r.date.split('-')[1]}`;
            if (!orderedPoints.has(dateKey)) orderedPoints.set(dateKey, { sum: 0, count: 0 });
            const pt = orderedPoints.get(dateKey)!;
            pt.sum += parseFloat(r.avg_weight_gr) || 0;
            pt.count += 1;
          });

          data = Array.from(orderedPoints.entries())
            .filter(([, { count }]) => count > 0)
            .map(([name, { sum, count }]) => ({
              name,
              value: parseFloat((sum / count).toFixed(1))
            }));
        }

        setChartData(data);
      } catch (error) {
        console.error("Error fetching chart data:", error);
      } finally {
        setIsChartLoading(false);
      }
    };

    fetchChartData();
  }, [selectedPond, selectedParam, selectedSpecies]);

  const planType = activeUnit?.subscriptions?.plan_type || 'basic';
  const currentPond = ponds.find(p => p.id === selectedPond);

  const isAdminOrOwner = userRole === 'admin' || userRole === 'propietario';

  // Alert Evaluation for Mortality
  const isMortalityAlert = parseFloat(stats.mortality.percent) > alertThresholds.mortalityMax;

  return (
    <div className="animate-fade-in page-container">
      <header style={{ marginBottom: '3rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1.5rem' }}>
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '0.5rem' }}>
            <h1 style={{ fontWeight: 900, letterSpacing: '-0.04em' }}>Hola 👋</h1>
            {planType === 'premium' && (
              <span style={{ background: 'linear-gradient(135deg, #f59e0b, #d97706)', color: 'white', padding: '4px 10px', borderRadius: '8px', fontSize: '0.65rem', fontWeight: 900, textTransform: 'uppercase', letterSpacing: '0.05em', boxShadow: '0 4px 12px rgba(217, 119, 6, 0.2)' }}>
                Premium
              </span>
            )}
          </div>
          <p style={{ color: 'var(--muted-foreground)', fontWeight: 600 }}>Unidad: <strong style={{ color: 'var(--foreground)' }}>{activeUnit?.name || 'Cargando...'}</strong></p>
        </div>
        <div style={{ padding: '0.6rem 1.25rem', background: 'var(--secondary)', borderRadius: '14px', border: '1px solid var(--border)', fontSize: '0.85rem', fontWeight: 800 }}>
          {new Date().toLocaleDateString('es-ES', { weekday: 'long', day: 'numeric', month: 'long' })}
        </div>
      </header>

      <div className="responsive-grid-4" style={{ marginBottom: '2.5rem' }}>
        <StatCard 
          title="Biomasa Total" 
          value={stats.biomass.total >= 1000 ? (Number(stats.biomass.total/1000).toFixed(1)) : stats.biomass.total} 
          unit={stats.biomass.total >= 1000 ? "Ton" : "kg"}
          change="+3.2%" 
          icon={Fish} 
          color="#3b82f6" 
          details={stats.biomass.details}
        />
        <StatCard 
          title="Consumo Alimento" 
          value={Number(stats.consumption.total).toFixed(0)} 
          unit="kg"
          change="Total" 
          icon={Utensils} 
          color="#8b5cf6" 
          details={stats.consumption.details}
        />
        <StatCard 
          title="Mortalidad Finca" 
          value={`${stats.mortality.total}`} 
          unit={`uds (${stats.mortality.percent}%)`}
          change="Total" 
          icon={Skull} 
          color="#ef4444" 
          details={stats.mortality.details}
          isAlert={isMortalityAlert}
        />
        <StatCard 
          title="Stock Concentrado" 
          value={Number(stats.inventory.total)} 
          unit="kg"
          change="Suficiente" 
          icon={ShoppingBag} 
          color="#10b981" 
          details={stats.inventory.details}
        />
      </div>

      <div className="responsive-grid-2">
        <TrendsChart 
          data={chartData}
          isLoading={isChartLoading}
          selectedPond={selectedPond}
          selectedParam={selectedParam}
          onPondChange={setSelectedPond}
          onParamChange={setSelectedParam}
          ponds={ponds}
          isPolyculture={pondSpecies.length > 1}
          pondSpecies={pondSpecies}
          selectedSpecies={selectedSpecies}
          setSelectedSpecies={setSelectedSpecies}
          thresholds={alertThresholds}
        />
        
        <AnimatePresence mode="wait">
          {isLoadingRole ? (
            <div className="card-premium" style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '100%' }}>
              <Loader2 className="animate-spin" color="var(--primary)" size={32} />
            </div>
          ) : isAdminOrOwner ? (
            <FinanceSummary 
              key="finance"
              data={financeData}
              isLoading={isFinanceLoading}
            />
          ) : (
            <FeedInventorySummary 
              key="inventory"
              data={stats.inventory.details}
              inventoryThresholds={alertThresholds.inventoryMin}
            />
          )}
        </AnimatePresence>
      </div>
    </div>
  );
}
