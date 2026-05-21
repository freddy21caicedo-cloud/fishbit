'use client';

import { useEffect, useState } from 'react';
import { supabase } from '@/lib/supabase';
import { useUnit } from '../components/providers/UnitProvider';
import { useAuth } from '../components/providers/AuthProvider';
import { 
  Utensils, 
  Skull, 
  Fish, 
  ShoppingBag,
  Loader2,
  BrainCircuit
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
import { HarvestEstimator } from './components/HarvestEstimator';
import { AlertsPanel, AlertItem } from './components/AlertsPanel';
import { PondsGrid, EnhancedPond } from './components/PondsGrid';
import { TasksChecklist } from './components/TasksChecklist';

import { 
  Profile, 
  Pond, 
  DashboardStats, 
  AlertThresholds, 
  FinanceData, 
  ChartDataPoint,
  StatDetail
} from '@/lib/database.types';

// Helper to evaluate pond health based on limits
const evaluateHealthState = (oxygen?: number, temp?: number, ph?: number, thresholds?: AlertThresholds) => {
  if (!thresholds) return 'healthy';
  
  if (oxygen !== undefined) {
    if (oxygen < thresholds.oxygenMin || oxygen > thresholds.oxygenMax) return 'critical';
    if (oxygen < thresholds.oxygenMin + 0.5 || oxygen > thresholds.oxygenMax - 0.5) return 'warning';
  }
  if (temp !== undefined) {
    if (temp < thresholds.tempMin || temp > thresholds.tempMax) return 'critical';
    if (temp < thresholds.tempMin + 1.0 || temp > thresholds.tempMax - 1.0) return 'warning';
  }
  if (ph !== undefined) {
    if (ph < thresholds.phMin || ph > thresholds.phMax) return 'critical';
    if (ph < thresholds.phMin + 0.3 || ph > thresholds.phMax - 0.3) return 'warning';
  }
  return 'healthy';
};

export default function Dashboard() {
  const { session, isSuperAdmin } = useAuth();
  const { activeUnitId, activeUnit, userRole, roleLoading: isLoadingRole } = useUnit();
  
  const [userUnits, setUserUnits] = useState<any[]>([]);

  // Fetch units for standard admin/client users to see if they have multiple
  useEffect(() => {
    if (!session?.user?.id || isSuperAdmin) return;

    const fetchUserUnits = async () => {
      try {
        const { data: userUnitRows } = await supabase
          .from('user_units')
          .select('unit_id')
          .eq('user_id', session.user.id);

        if (!userUnitRows || userUnitRows.length === 0) return;

        const unitIds = userUnitRows.map((r: any) => r.unit_id).filter(Boolean);

        const { data: unitRows } = await supabase
          .from('units')
          .select('id, name, location')
          .in('id', unitIds);

        if (unitRows) {
          setUserUnits(unitRows);
        }
      } catch (err) {
        console.error('Dashboard: error fetching user units:', err);
      }
    };

    fetchUserUnits();
  }, [session?.user?.id, isSuperAdmin]);
  
  const [stats, setStats] = useState<DashboardStats>({
    biomass: { total: 0, details: [] },
    consumption: { total: 0, details: [] },
    mortality: { total: 0, percent: '0.0', details: [] },
    inventory: { total: 0, details: [] }
  });
  
  const [fcr, setFcr] = useState<{ total: number; details: StatDetail[] }>({ total: 0, details: [] });
  const [enhancedPonds, setEnhancedPonds] = useState<EnhancedPond[]>([]);
  const [activeAlerts, setActiveAlerts] = useState<AlertItem[]>([]);
  const [isPondsLoading, setIsPondsLoading] = useState(false);

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
      .on('postgres_changes', { event: '*', schema: 'public', table: 'inventory', filter: 'unit_id=eq.' + activeUnitId }, () => {
        fetchDetailedStats(activeUnitId);
      })
      .on('postgres_changes', { event: '*', schema: 'public', table: 'alimentacion_diaria', filter: 'unit_id=eq.' + activeUnitId }, () => {
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
    try {
      const { data, error } = await supabase
        .from('estanques')
        .select('id, name, is_polyculture, status')
        .eq('unit_id', unitId)
        .eq('status', 'con_peces');
      
      if (error) throw error;
      
      if (data) {
        setPonds(data as Pond[]);
        if (data.length > 0 && !selectedPond) {
          setSelectedPond(data[0].id);
        }
      }
    } catch (err) {
      console.error('fetchPonds error:', err);
    }
  };

  useEffect(() => {
    const fetchSpecies = async () => {
      if (!selectedPond) {
        setPondSpecies([]);
        setSelectedSpecies('Todas');
        return;
      }

      const { data } = await supabase
        .from('pond_species')
        .select('species_name')
        .eq('estanque_id', selectedPond);

      if (data && data.length > 0) {
        const unique = Array.from(
          new Map(data.map((s: any) => [s.species_name, s])).values()
        );
        setPondSpecies(unique as { species_name: string }[]);
        setSelectedSpecies('Todas');
      } else {
        setPondSpecies([]);
        setSelectedSpecies('Todas');
      }
    };

    fetchSpecies();
  }, [selectedPond]);

  const fetchDetailedStats = async (unitId: string) => {
    setIsPondsLoading(true);
    try {
      // 1. Fetch active ponds
      const { data: pondsData } = await supabase
        .from('estanques')
        .select('id, name, current_biomass_kg, current_count, status')
        .eq('unit_id', unitId)
        .eq('status', 'con_peces');

      const activePonds: any[] = pondsData || [];

      if (activePonds.length === 0) {
        setStats({
          biomass: { total: 0, details: [] },
          consumption: { total: 0, details: [] },
          mortality: { total: 0, percent: '0.0', details: [] },
          inventory: { total: 0, details: [] }
        });
        setFcr({ total: 0, details: [] });
        setEnhancedPonds([]);
        setActiveAlerts([]);
        return;
      }

      // 2. Fetch latest water quality records for active ponds
      const { data: wqData } = await supabase
        .from('water_quality')
        .select('estanque_id, o2_mg_l, temperature_c, ph')
        .in('estanque_id', activePonds.map((p: any) => p.id))
        .order('date', { ascending: false })
        .order('hour', { ascending: false });

      const wqMap: Record<string, any> = {};
      if (wqData) {
        wqData.forEach((r: any) => {
          if (!wqMap[r.estanque_id]) wqMap[r.estanque_id] = r;
        });
      }

      // 3. Fetch active species per pond
      const { data: speciesData } = await supabase
        .from('pond_species')
        .select('estanque_id, species_name')
        .in('estanque_id', activePonds.map((p: any) => p.id));

      const speciesMap: Record<string, string[]> = {};
      if (speciesData) {
        speciesData.forEach((s: any) => {
          if (!speciesMap[s.estanque_id]) speciesMap[s.estanque_id] = [];
          speciesMap[s.estanque_id].push(s.species_name);
        });
      }

      // --- BIOMASS ---
      const biomassTotal = activePonds.reduce((s, p) => s + (parseFloat(p.current_biomass_kg as any) || 0), 0);
      const biomassDetails = activePonds.map(p => ({
        label: p.name,
        value: parseFloat((parseFloat(p.current_biomass_kg as any) || 0).toFixed(1)),
        unit: 'kg'
      }));

      // --- CONSUMPTION ---
      const { data: alimentData } = await supabase
        .from('alimentacion_diaria')
        .select('quantity_kg, inventory_id, estanque_id, inventory(name)')
        .eq('unit_id', unitId);

      const consumptionByProduct: Record<string, { name: string; total: number }> = {};
      const pondConsumption: Record<string, number> = {};

      (alimentData || []).forEach((r: any) => {
        const key = r.inventory_id || 'sin_ref';
        const productName = (r.inventory as any)?.name || 'Sin referencia';
        if (!consumptionByProduct[key]) {
          consumptionByProduct[key] = { name: productName, total: 0 };
        }
        consumptionByProduct[key].total += parseFloat(r.quantity_kg) || 0;
        
        if (r.estanque_id) {
          pondConsumption[r.estanque_id] = (pondConsumption[r.estanque_id] || 0) + (parseFloat(r.quantity_kg) || 0);
        }
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
      const totalFishEver = activePonds.reduce((s, p) => s + (parseInt(p.current_count as any) || 0), 0) + mortalityTotal;
      const mortalityPct = totalFishEver > 0 ? ((mortalityTotal / totalFishEver) * 100).toFixed(1) : '0.0';
      const mortalityDetails = Object.values(mortalityByPond).map(v => ({
        label: v.name,
        value: v.total,
        unit: 'uds'
      }));

      // --- INVENTORY ---
      const { data: invData } = await supabase
        .from('inventory')
        .select('name, current_stock')
        .eq('unit_id', unitId)
        .eq('category', 'alimento');

      const inventoryTotal = (invData || []).reduce((s: any, i: any) => s + (parseFloat(i.current_stock) || 0), 0);
      const inventoryDetails = (invData || []).map((i: any) => ({
        label: i.name,
        value: parseFloat((parseFloat(i.current_stock) || 0).toFixed(1)),
        unit: 'kg'
      }));

      // --- FCR / ICA ---
      const globalFCRVal = biomassTotal > 0 ? parseFloat((consumptionTotal / biomassTotal).toFixed(2)) : 0;
      const fcrDetails = activePonds.map(p => {
        const pondBio = parseFloat(p.current_biomass_kg as any) || 0;
        const pondFood = pondConsumption[p.id] || 0;
        const pondFcrVal = pondBio > 0 ? parseFloat((pondFood / pondBio).toFixed(2)) : 0;
        return {
          label: p.name,
          value: pondFcrVal,
          unit: 'ICA'
        };
      });

      setStats({
        biomass:     { total: parseFloat(biomassTotal.toFixed(1)),     details: biomassDetails },
        consumption: { total: parseFloat(consumptionTotal.toFixed(1)), details: consumptionDetails },
        mortality:   { total: mortalityTotal, percent: mortalityPct,   details: mortalityDetails },
        inventory:   { total: parseFloat(inventoryTotal.toFixed(1)),   details: inventoryDetails },
      });

      setFcr({
        total: globalFCRVal,
        details: fcrDetails
      });

      // --- ALERTS & ENHANCED PONDS ---
      const alertsList: AlertItem[] = [];
      const enhancedList: EnhancedPond[] = activePonds.map(p => {
        const wq = wqMap[p.id];
        const oxygen = wq ? parseFloat(wq.o2_mg_l) : undefined;
        const temperature = wq ? parseFloat(wq.temperature_c) : undefined;
        const ph = wq ? parseFloat(wq.ph) : undefined;
        const speciesList = speciesMap[p.id] || [];
        const speciesText = speciesList.length > 0 ? speciesList.join(', ') : 'Sin clasificar';

        const healthState = evaluateHealthState(oxygen, temperature, ph, alertThresholds);

        if (oxygen !== undefined && oxygen < alertThresholds.oxygenMin) {
          alertsList.push({
            id: `${p.id}-o2-low`,
            pondId: p.id,
            pondName: p.name,
            type: 'oxigeno',
            severity: oxygen < alertThresholds.oxygenMin - 0.8 ? 'critical' : 'warning',
            message: `Oxígeno por debajo del límite seguro: ${oxygen.toFixed(1)} mg/L`,
            value: oxygen,
            unit: 'mg/L'
          });
        }
        
        const mCount = mortalityByPond[p.id]?.total || 0;
        const mPondTotal = (parseInt(p.current_count as any) || 0) + mCount;
        const mortPondPct = mPondTotal > 0 ? (mCount / mPondTotal) * 100 : 0;
        if (mortPondPct > alertThresholds.mortalityMax) {
          alertsList.push({
            id: `${p.id}-mort-high`,
            pondId: p.id,
            pondName: p.name,
            type: 'mortalidad',
            severity: 'critical',
            message: `Mortalidad acumulada sobrepasa el límite: ${mortPondPct.toFixed(1)}%`,
            value: parseFloat(mortPondPct.toFixed(1)),
            unit: '%'
          });
        }

        return {
          id: p.id,
          name: p.name,
          status: p.status as any,
          current_biomass_kg: parseFloat(p.current_biomass_kg as any) || 0,
          current_count: parseInt(p.current_count as any) || 0,
          species: speciesText,
          oxygen,
          temperature,
          ph,
          healthState
        };
      });

      setEnhancedPonds(enhancedList);
      setActiveAlerts(alertsList);

    } catch (error: any) {
      console.error('fetchDetailedStats error:', error?.message);
    } finally {
      setIsPondsLoading(false);
    }
  };

  const fetchFinanceData = async (unitId: string) => {
    setIsFinanceLoading(true);
    try {
      const { data, error } = await supabase.rpc('get_unit_finance_summary', { p_unit_id: unitId });
      if (error) throw error;
      if (data) {
        setFinanceData(data as FinanceData);
      }
    } catch (error: any) {
      console.error("RPC Error details (Finance):", error?.message);
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
          (res || []).forEach((r: any) => {
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
          (res || []).forEach((r: any) => {
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
          (res || []).forEach((r: any) => {
            if (!r.date) return;
            const dateKey = `${r.date.split('-')[2]}/${r.date.split('-')[1]}`;
            grouped[dateKey] = (grouped[dateKey] || 0) + (parseFloat(r.quantity_kg) || 0);
          });
          
          data = Object.entries(grouped).map(([name, value]) => ({ name, value: parseFloat(value.toFixed(1)) }));

        } else if (selectedParam === 'peso_promedio') {
          const { data: siembrasData } = await supabase
            .from('siembras')
            .select('date, siembra_details(species_name, avg_weight_gr)')
            .eq('estanque_id', selectedPond)
            .order('date', { ascending: true });

          const orderedPoints: Map<string, { sum: number; count: number }> = new Map();

          (siembrasData || []).forEach((siembra: any) => {
            if (!siembra.date) return;
            const dateKey = `${siembra.date.split('-')[2]}/${siembra.date.split('-')[1]}`;
            const details: any[] = siembra.siembra_details || [];

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

          let bioQuery = supabase
            .from('biometrias')
            .select('avg_weight_gr, date, species_name')
            .eq('estanque_id', selectedPond);

          if (selectedSpecies !== 'Todas') {
            bioQuery = bioQuery.eq('species_name', selectedSpecies);
          }

          const { data: bioRes } = await bioQuery.order('date', { ascending: true });

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

  const currentPond = ponds.find(p => p.id === selectedPond);
  const isAdminOrOwner = userRole === 'admin' || userRole === 'propietario';
  const isMortalityAlert = parseFloat(stats.mortality.percent) > alertThresholds.mortalityMax;

  return (
    <div className="animate-fade-in page-container">
      <header style={{ marginBottom: '2.5rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1.5rem' }}>
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '0.5rem' }}>
            <h1 style={{ fontWeight: 900, letterSpacing: '-0.04em' }}>Hola 👋</h1>
            <span style={{ background: 'linear-gradient(135deg, #0d9488, #10b981)', color: 'white', padding: '4px 10px', borderRadius: '8px', fontSize: '0.65rem', fontWeight: 900, textTransform: 'uppercase', letterSpacing: '0.05em', boxShadow: '0 4px 12px rgba(13, 148, 136, 0.2)' }}>
              Plan Único
            </span>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginTop: '0.25rem' }}>
            <span style={{ color: 'var(--muted-foreground)', fontWeight: 600, fontSize: '0.95rem' }}>Unidad:</span>
            {!isSuperAdmin && userUnits.length > 1 ? (
              <div style={{ position: 'relative', display: 'inline-block' }}>
                <select
                  value={activeUnitId || ''}
                  onChange={(e) => {
                    const newUnitId = e.target.value;
                    if (newUnitId && newUnitId !== activeUnitId) {
                      localStorage.setItem('active_unit_id', newUnitId);
                      window.location.reload();
                    }
                  }}
                  style={{
                    background: 'var(--card)',
                    color: 'var(--foreground)',
                    border: '1px solid var(--border)',
                    borderRadius: '12px',
                    padding: '0.5rem 2.25rem 0.5rem 1rem',
                    fontSize: '0.9rem',
                    fontWeight: 700,
                    cursor: 'pointer',
                    outline: 'none',
                    appearance: 'none',
                    backgroundImage: 'url("data:image/svg+xml;charset=UTF-8,%3csvg xmlns=\'http://www.w3.org/2000/svg\' viewBox=\'0 0 24 24\' fill=\'none\' stroke=\'%230d9488\' stroke-width=\'3\' stroke-linecap=\'round\' stroke-linejoin=\'round\'%3e%3cpolyline points=\'6 9 12 15 18 9\'%3e%3c/polyline%3e%3c/svg%3e")',
                    backgroundRepeat: 'no-repeat',
                    backgroundPosition: 'right 0.75rem center',
                    backgroundSize: '0.9rem',
                    transition: 'all 0.2s ease',
                    boxShadow: 'var(--shadow-sm)',
                  }}
                >
                  {userUnits.map((u: any) => (
                    <option key={u.id} value={u.id} style={{ background: 'var(--card)', color: 'var(--foreground)' }}>
                      {u.name}
                    </option>
                  ))}
                </select>
              </div>
            ) : (
              <strong style={{ color: 'var(--foreground)', fontWeight: 850, fontSize: '0.95rem' }}>
                {activeUnit?.name || 'Cargando...'}
              </strong>
            )}
          </div>
        </div>
        <div suppressHydrationWarning={true} style={{ padding: '0.6rem 1.25rem', background: 'var(--secondary)', borderRadius: '14px', border: '1px solid var(--border)', fontSize: '0.85rem', fontWeight: 800 }}>
          {new Date().toLocaleDateString('es-ES', { weekday: 'long', day: 'numeric', month: 'long' })}
        </div>
      </header>

      {/* Harvest Estimator & Realtime Alerts panel */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))', gap: '1.5rem', marginBottom: '2.5rem' }}>
        <HarvestEstimator selectedPondId={selectedPond} ponds={enhancedPonds} />
        <AlertsPanel alerts={activeAlerts} onViewPond={setSelectedPond} />
      </div>

      {/* Ponds Map Grid */}
      <div style={{ marginBottom: '2.5rem' }}>
        {isPondsLoading ? (
          <div className="card-premium" style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '180px' }}>
            <Loader2 className="animate-spin" color="var(--primary)" size={32} />
          </div>
        ) : (
          <PondsGrid 
            ponds={enhancedPonds} 
            selectedPond={selectedPond} 
            onSelectPond={setSelectedPond} 
          />
        )}
      </div>

      {/* KPI Stats Cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '1.5rem', marginBottom: '2.5rem' }}>
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
          title="Conversión (FCR)" 
          value={fcr.total} 
          unit="ICA"
          change={fcr.total > 0 && fcr.total < 1.5 ? "Óptimo" : (fcr.total >= 1.8 ? "Alto" : "Normal")} 
          icon={BrainCircuit} 
          color="#f59e0b" 
          details={fcr.details}
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

      {/* Daily Tasks Checklist */}
      <div style={{ marginBottom: '2.5rem' }}>
        <TasksChecklist />
      </div>

      {/* Trends Graph and summaries */}
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
