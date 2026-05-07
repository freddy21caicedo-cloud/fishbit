'use client';

import { useEffect, useState, useMemo } from 'react';
import { useRouter } from 'next/navigation';
import { supabase } from '@/lib/supabase';
import { useUnit } from '../components/providers/UnitProvider';
import { 
  Utensils, 
  Skull, 
  Fish, 
  ShoppingBag,
  Loader2
} from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import { toast } from 'react-hot-toast';

// UI Components
import { StatCard } from '../components/ui/StatCard';
import { PremiumInput } from '../components/ui/PremiumInput';
import { TrendsChart } from './components/TrendsChart';
import { FinanceSummary } from './components/FinanceSummary';
import { FeedInventorySummary } from './components/FeedInventorySummary';

export default function Dashboard() {
  const router = useRouter();
  const { activeUnitId, activeUnit } = useUnit();
  
  const [userRole, setUserRole] = useState<string>('cargando...');
  const [stats, setStats] = useState<any>({
    biomass: { total: 0, details: [] },
    consumption: { total: 0, details: [] },
    mortality: { total: 0, percent: 0, details: [] },
    inventory: { total: 0, details: [] }
  });
  
  const [alertThresholds, setAlertThresholds] = useState<any>({
    oxygenMin: 4.5, oxygenMax: 9.0,
    tempMin: 26.0, tempMax: 31.0,
    phMin: 6.5, phMax: 8.5,
    mortalityMax: 5.0,
    inventoryMin: {} // Map of reference -> min stock
  });

  const [ponds, setPonds] = useState<any[]>([]);
  const [selectedPond, setSelectedPond] = useState<string>('');
  const [selectedParam, setSelectedParam] = useState<string>('oxigeno');
  const [selectedSpecies, setSelectedSpecies] = useState<string>('Todas');
  const [pondSpecies, setPondSpecies] = useState<any[]>([]);
  
  const [chartData, setChartData] = useState<any[]>([]);
  const [isChartLoading, setIsChartLoading] = useState(false);
  
  const [financeData, setFinanceData] = useState<any>({ total: 0, food: 0, seeds: 0, pending: 0 });
  const [isFinanceLoading, setIsFinanceLoading] = useState(false);

  // 1. Initial Load: User Role, Unit Stats, Finance, and Thresholds
  useEffect(() => {
    const fetchUserRole = async () => {
      const { data: { user } } = await supabase.auth.getUser();
      if (user) {
        const { data: profile } = await supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();
        if (profile) setUserRole(profile.role);
      }
    };
    fetchUserRole();
  }, []);

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
      .select('id, name, is_polyculture')
      .eq('unit_id', unitId)
      .eq('status', 'con_peces');
    
    if (data) {
      setPonds(data);
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

      const currentPond = ponds.find(p => p.id === selectedPond);
      if (currentPond?.is_polyculture) {
        const { data } = await supabase
          .from('pond_species')
          .select('species_name')
          .eq('estanque_id', selectedPond);
        
        if (data) {
          setPondSpecies(data);
        }
      } else {
        setPondSpecies([]);
        setSelectedSpecies('Todas');
      }
    };

    fetchSpecies();
  }, [selectedPond, ponds]);

  const fetchDetailedStats = async (unitId: string) => {
    try {
      const [pondsRes, speciesRes] = await Promise.all([
        supabase.from('estanques').select('id, current_biomass_kg, current_species, is_polyculture').eq('unit_id', unitId),
        supabase.from('pond_species').select('estanque_id, species_name, current_biomass_kg').eq('unit_id', unitId)
      ]);

      const biomassMap: any = {};
      let totalBiomass = 0;
      const coveredPondIds = new Set();

      speciesRes.data?.forEach(s => {
        const kg = parseFloat(s.current_biomass_kg) || 0;
        if (kg <= 0) return;
        totalBiomass += kg;
        const sp = s.species_name || 'Desconocida';
        biomassMap[sp] = (biomassMap[sp] || 0) + kg;
        coveredPondIds.add(s.estanque_id);
      });

      pondsRes.data?.forEach(p => {
        if (coveredPondIds.has(p.id)) return;
        const kg = parseFloat(p.current_biomass_kg) || 0;
        if (kg <= 0) return;
        totalBiomass += kg;
        const sp = p.current_species || 'Sin Especie';
        if (sp === 'Policultivo') {
           biomassMap['Otros (Policultivo)'] = (biomassMap['Otros (Policultivo)'] || 0) + kg;
        } else {
           biomassMap[sp] = (biomassMap[sp] || 0) + kg;
        }
      });

      const biomassDetails = Object.entries(biomassMap).map(([sp, val]: any) => ({ 
        label: sp, 
        value: val >= 1000 ? (val/1000).toFixed(1) : val.toFixed(0), 
        unit: val >= 1000 ? 'Ton' : 'kg' 
      }));

      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
      
      const [feed, mortData, pondsPop, inv] = await Promise.all([
        supabase.from('alimentacion_diaria').select('quantity_kg, inventory(name)').eq('unit_id', unitId).gte('date', thirtyDaysAgo.toISOString()),
        supabase.from('mortality').select('quantity, estanques(name)').eq('unit_id', unitId),
        supabase.from('estanques').select('current_count').eq('unit_id', unitId),
        supabase.from('inventory').select('name, current_stock').eq('unit_id', unitId).eq('category', 'alimento')
      ]);

      // Process Feed
      const feedMap: any = {};
      let totalFeed = 0;
      feed.data?.forEach(f => {
        const kg = Number(f.quantity_kg) || 0;
        totalFeed += kg;
        const invData: any = f.inventory;
        const name = (Array.isArray(invData) ? invData[0]?.name : invData?.name) || 'Desconocido';
        feedMap[name] = (feedMap[name] || 0) + kg;
      });
      const feedDetails = Object.entries(feedMap).map(([name, val]: any) => ({ label: name, value: val.toFixed(0), unit: 'kg' }));

      // Process Mortality
      const totalPop = pondsPop.data?.reduce((sum, p) => sum + (p.current_count || 0), 0) || 1;
      const mortMap: any = {};
      let totalMort = 0;
      mortData.data?.forEach(m => {
        const qty = Number(m.quantity) || 0;
        totalMort += qty;
        const estData: any = m.estanques;
        const pName = (Array.isArray(estData) ? estData[0]?.name : estData?.name) || 'Desconocido';
        mortMap[pName] = (mortMap[pName] || 0) + qty;
      });
      const mortDetails = Object.entries(mortMap).map(([name, val]: any) => ({ 
        label: name, 
        value: `${val} (${((val/totalPop)*100).toFixed(1)}%)`,
        unit: 'uds' 
      }));

      // Process Inventory
      let totalInv = 0;
      const invDetails = inv.data?.map(i => {
        const stock = Number(i.current_stock) || 0;
        totalInv += stock;
        return { label: i.name, value: stock.toFixed(0), unit: 'kg' };
      }) || [];

      setStats({
        biomass: { total: totalBiomass, details: biomassDetails },
        consumption: { total: totalFeed, details: feedDetails },
        mortality: { total: totalMort, percent: (totalMort / totalPop * 100).toFixed(1), details: mortDetails },
        inventory: { total: totalInv, details: invDetails }
      });
    } catch (error) {
      console.error("Error fetching stats:", error);
    }
  };

  const fetchFinanceData = async (unitId: string) => {
    setIsFinanceLoading(true);
    try {
      const { data: invoices } = await supabase
        .from('invoices')
        .select('*')
        .eq('unit_id', unitId);
      
      if (invoices) {
        const total = invoices.reduce((acc, inv) => acc + (Number(inv.total) || 0), 0);
        const food = invoices.filter(inv => inv.category === 'alimento').reduce((acc, inv) => acc + (Number(inv.total) || 0), 0);
        const seeds = invoices.filter(inv => inv.category === 'alevinos').reduce((acc, inv) => acc + (Number(inv.total) || 0), 0);
        const pending = invoices.filter(inv => inv.status === 'pendiente').reduce((acc, inv) => acc + (Number(inv.total) || 0), 0);
        
        setFinanceData({ total, food, seeds, pending });
      }
    } catch (error) {
      console.error("Error fetching finance data:", error);
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
        let data: any[] = [];
        const thirtyDaysAgo = new Date();
        thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

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
            .gte('date', thirtyDaysAgo.toISOString())
            .order('date', { ascending: true })
            .order('hour', { ascending: true });
          
          data = (res as any[])?.map(r => ({ 
            name: `${r.date.split('-')[2]} ${r.hour}`, 
            value: parseFloat(parseFloat(r[column]).toFixed(2)) 
          })) || [];
        } else if (selectedParam === 'mortalidad') {
          let query = supabase
            .from('mortality')
            .select('quantity, date')
            .eq('estanque_id', selectedPond)
            .gte('date', thirtyDaysAgo.toISOString());
          
          if (selectedSpecies !== 'Todas') {
            query = query.eq('species_name', selectedSpecies);
          }

          const { data: res } = await query.order('date', { ascending: true });
          data = res?.map(r => ({ 
            name: r.date.split('-')[2], 
            value: parseInt(r.quantity) 
          })) || [];
        } else if (selectedParam === 'biomasa') {
          let query = supabase
            .from('biometrias')
            .select('total_biomass_kg, date')
            .eq('estanque_id', selectedPond)
            .gte('date', thirtyDaysAgo.toISOString());

          if (selectedSpecies !== 'Todas') {
            query = query.eq('species_name', selectedSpecies);
          }

          const { data: res } = await query.order('date', { ascending: true });
          data = res?.map(r => ({ 
            name: r.date.split('-')[2], 
            value: parseFloat(parseFloat(r.total_biomass_kg).toFixed(1)) 
          })) || [];
        } else if (selectedParam === 'consumo') {
          const { data: res } = await supabase
            .from('alimentacion_diaria')
            .select('quantity_kg, date')
            .eq('estanque_id', selectedPond)
            .gte('date', thirtyDaysAgo.toISOString())
            .order('date', { ascending: true });
          data = res?.map(r => ({ 
            name: r.date.split('-')[2], 
            value: parseFloat(parseFloat(r.quantity_kg).toFixed(1)) 
          })) || [];
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
  const isOperatorOrTech = userRole === 'tecnico' || userRole === 'operario';

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
          change="Mes" 
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
          isPolyculture={currentPond?.is_polyculture || false}
          pondSpecies={pondSpecies}
          selectedSpecies={selectedSpecies}
          setSelectedSpecies={setSelectedSpecies}
          thresholds={alertThresholds}
        />
        
        <AnimatePresence mode="wait">
          {userRole === 'cargando...' ? (
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
