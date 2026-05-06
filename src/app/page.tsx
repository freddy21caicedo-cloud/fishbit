'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { supabase } from '@/lib/supabase';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  TrendingUp, 
  Users, 
  Activity, 
  AlertCircle,
  ArrowUpRight,
  Droplets,
  Thermometer,
  Wind,
  MessageSquare,
  X,
  ChevronRight,
  Utensils,
  Skull,
  Package,
  Fish,
  ShoppingBag,
  Loader2
} from 'lucide-react';
import { 
  LineChart, 
  Line, 
  XAxis, 
  YAxis, 
  CartesianGrid, 
  Tooltip, 
  ResponsiveContainer,
  AreaChart,
  Area,
  LabelList
} from 'recharts';
import { toast } from 'react-hot-toast';

const data = [
  { name: '00:00', oxygen: 6.5, temp: 24.2 },
  { name: '04:00', oxygen: 6.2, temp: 23.8 },
  { name: '08:00', oxygen: 6.8, temp: 24.5 },
  { name: '12:00', oxygen: 7.2, temp: 25.1 },
  { name: '16:00', oxygen: 6.9, temp: 25.4 },
  { name: '20:00', oxygen: 6.6, temp: 24.8 },
  { name: '23:59', oxygen: 6.4, temp: 24.3 },
];

const FlipCard = ({ title, value, change, icon: Icon, color, details, unit }: any) => {
  const [isFlipped, setIsFlipped] = useState(false);

  return (
    <div 
      style={{ perspective: '1000px', cursor: 'pointer', height: '180px' }}
      onClick={() => setIsFlipped(!isFlipped)}
    >
      <motion.div
        animate={{ rotateY: isFlipped ? 180 : 0 }}
        transition={{ duration: 0.6, type: 'spring', stiffness: 260, damping: 20 }}
        style={{ 
          width: '100%', 
          height: '100%', 
          position: 'relative', 
          transformStyle: 'preserve-3d' 
        }}
      >
        {/* Front */}
        <div style={{
          position: 'absolute',
          width: '100%',
          height: '100%',
          backfaceVisibility: 'hidden',
          WebkitBackfaceVisibility: 'hidden'
        }}>
          <div className="card-premium" style={{ padding: '1.5rem', height: '100%', display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
              <div style={{ padding: '0.6rem', background: `${color}15`, borderRadius: '12px', color: color }}>
                <Icon size={24} />
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.25rem', color: change.startsWith('+') ? '#10b981' : (change.startsWith('-') ? '#ef4444' : '#64748b'), fontSize: '0.75rem', fontWeight: 800 }}>
                {change}
                {change !== 'Estable' && change !== 'Óptimo' && <ArrowUpRight size={14} style={{ transform: change.startsWith('-') ? 'rotate(90deg)' : 'none' }} />}
              </div>
            </div>
            <div>
              <div style={{ fontSize: '1.75rem', fontWeight: 900, marginBottom: '0.1rem', letterSpacing: '-0.02em' }}>{value} <span style={{ fontSize: '0.9rem', fontWeight: 700, opacity: 0.6 }}>{unit}</span></div>
              <div style={{ fontSize: '0.75rem', color: 'var(--muted-foreground)', fontWeight: 800, textTransform: 'uppercase', letterSpacing: '0.05em' }}>{title}</div>
            </div>
          </div>
        </div>

        {/* Back */}
        <div style={{
          position: 'absolute',
          width: '100%',
          height: '100%',
          backfaceVisibility: 'hidden',
          WebkitBackfaceVisibility: 'hidden',
          transform: 'rotateY(180deg)'
        }}>
          <div className="card-premium" style={{ padding: '1.25rem', height: '100%', background: 'var(--card)', display: 'flex', flexDirection: 'column' }}>
            <h4 style={{ fontSize: '0.7rem', fontWeight: 900, textTransform: 'uppercase', color: 'var(--muted-foreground)', marginBottom: '0.75rem', letterSpacing: '0.05em', borderBottom: '1px solid var(--border)', paddingBottom: '0.4rem' }}>
              Detalle {title}
            </h4>
            <div style={{ flex: 1, overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
              {details && details.length > 0 ? details.map((item: any, idx: number) => (
                <div key={idx} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', fontSize: '0.8rem' }}>
                  <span style={{ fontWeight: 600, color: 'var(--muted-foreground)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', marginRight: '10px' }}>{item.label}</span>
                  <span style={{ fontWeight: 800, whiteSpace: 'nowrap' }}>{item.value} {item.unit || unit}</span>
                </div>
              )) : (
                <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '0.75rem', color: 'var(--muted-foreground)', fontStyle: 'italic' }}>
                  Sin datos detallados
                </div>
              )}
            </div>
          </div>
        </div>
      </motion.div>
    </div>
  );
};

export default function Dashboard() {
  const router = useRouter();
  const [authLoading, setAuthLoading] = useState(true);
  const [planType, setPlanType] = useState('basic');
  const [unitName, setUnitName] = useState('');

  // Removed redundant useEffect

  const [isSupportOpen, setIsSupportOpen] = useState(false);
  const [stats, setStats] = useState<any>({
    biomass: { total: 0, details: [] },
    consumption: { total: 0, details: [] },
    mortality: { total: 0, percent: 0, details: [] },
    inventory: { total: 0, details: [] }
  });
  const [ticketSubject, setTicketSubject] = useState('');
  const [ticketMessage, setTicketMessage] = useState('');
  const [sendingTicket, setSendingTicket] = useState(false);
  const [ponds, setPonds] = useState<any[]>([]);
  const [selectedPond, setSelectedPond] = useState<string>('');
  const [selectedParam, setSelectedParam] = useState<string>('oxigeno');
  const [chartData, setChartData] = useState<any[]>([]);
  const [isChartLoading, setIsChartLoading] = useState(false);
  const [selectedPondStatus, setSelectedPondStatus] = useState<string>('');
  const [pondStatusData, setPondStatusData] = useState<any>(null);
  const [isStatusLoading, setIsStatusLoading] = useState(false);
  const [financeData, setFinanceData] = useState<any>({ total: 0, food: 0, seeds: 0, pending: 0 });
  const [isFinanceLoading, setIsFinanceLoading] = useState(false);

  useEffect(() => {
    async function initDashboard() {
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) {
        router.push('/login');
        return;
      }
      
      setAuthLoading(false);

      const { data: userUnit } = await supabase
        .from('user_units')
        .select('unit_id, role')
        .eq('user_id', session.user.id)
        .limit(1)
        .single();
      
      if (userUnit) {
        if (userUnit.role === 'operario') {
          router.push('/registros');
          return;
        }
        const activeUnitId = userUnit.unit_id;
        localStorage.setItem('active_unit_id', activeUnitId);

        // Fetch basic info
        const [unitRes, subRes, pondsRes] = await Promise.all([
          supabase.from('units').select('name').eq('id', activeUnitId).single(),
          supabase.from('subscriptions').select('plan_type').eq('unit_id', activeUnitId).single(),
          supabase.from('estanques').select('id, name').eq('unit_id', activeUnitId).eq('status', 'con_peces')
        ]);

        if (unitRes.data) setUnitName(unitRes.data.name);
        if (subRes.data) setPlanType(subRes.data.plan_type);
        if (pondsRes.data) {
          setPonds(pondsRes.data);
          if (pondsRes.data.length > 0) {
            setSelectedPond(pondsRes.data[0].id);
            setSelectedPondStatus(pondsRes.data[0].id);
          }
        }

        // Fetch Stats
        fetchDetailedStats(activeUnitId);
      }
    }

    const fetchDetailedStats = async (unitId: string) => {
      try {
        // 1. Biomass by species (Source of Truth: pond_species + fallback to estanques)
        const [pondsRes, speciesRes] = await Promise.all([
          supabase.from('estanques').select('id, current_biomass_kg, current_species, is_polyculture').eq('unit_id', unitId),
          supabase.from('pond_species').select('estanque_id, species_name, current_biomass_kg').eq('unit_id', unitId)
        ]);

        const biomassMap: any = {};
        let totalBiomass = 0;
        const coveredPondIds = new Set();

        // A. Add data from species table
        speciesRes.data?.forEach(s => {
          const kg = parseFloat(s.current_biomass_kg) || 0;
          if (kg <= 0) return;
          totalBiomass += kg;
          const sp = s.species_name || 'Desconocida';
          biomassMap[sp] = (biomassMap[sp] || 0) + kg;
          coveredPondIds.add(s.estanque_id);
        });

        // B. Add data from ponds table for those not covered or not in polyculture
        pondsRes.data?.forEach(p => {
          if (coveredPondIds.has(p.id)) return; // Already counted via species table
          const kg = parseFloat(p.current_biomass_kg) || 0;
          if (kg <= 0) return;
          totalBiomass += kg;
          const sp = p.current_species || 'Sin Especie';
          // Avoid generic "Policultivo" label if we can
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

        // 2. Food Consumption (last 30 days)
        const thirtyDaysAgo = new Date();
        thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
        const { data: feed } = await supabase.from('alimentacion_diaria').select('quantity_kg, inventory(name)').eq('unit_id', unitId).gte('date', thirtyDaysAgo.toISOString());
        const feedMap: any = {};
        let totalFeed = 0;
        feed?.forEach(f => {
          const kg = Number(f.quantity_kg) || 0;
          totalFeed += kg;
          // Handle cases where relationship might return an array or an object
          const invData: any = f.inventory;
          const name = (Array.isArray(invData) ? invData[0]?.name : invData?.name) || 'Desconocido';
          feedMap[name] = (feedMap[name] || 0) + kg;
        });
        const feedDetails = Object.entries(feedMap).map(([name, val]: any) => ({ label: name, value: val.toFixed(0), unit: 'kg' }));

        // 3. Mortality
        const { data: mortData } = await supabase.from('mortality').select('quantity, estanques(name)').eq('unit_id', unitId);
        const { data: pondsPop } = await supabase.from('estanques').select('current_count').eq('unit_id', unitId);
        const totalPop = pondsPop?.reduce((sum, p) => sum + (p.current_count || 0), 0) || 1;
        const mortMap: any = {};
        let totalMort = 0;
        mortData?.forEach(m => {
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

        // 4. Inventory
        const { data: inv } = await supabase.from('inventory').select('name, current_stock').eq('unit_id', unitId).eq('category', 'alimento');
        let totalInv = 0;
        const invDetails = inv?.map(i => {
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

    const fetchChartData = async () => {
      if (!selectedPond || !selectedParam) return;
      setIsChartLoading(true);

      try {
        let data: any[] = [];
        const thirtyDaysAgo = new Date();
        thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

        if (selectedParam === 'oxigeno') {
          const { data: res } = await supabase
            .from('water_quality')
            .select('o2_mg_l, date, hour')
            .eq('estanque_id', selectedPond)
            .gte('date', thirtyDaysAgo.toISOString())
            .order('date', { ascending: true })
            .order('hour', { ascending: true });
          data = res?.map(r => ({ 
            name: `${r.date.split('-')[2]} ${r.hour}`, 
            value: parseFloat(parseFloat(r.o2_mg_l).toFixed(1)) 
          })) || [];
        } else if (selectedParam === 'mortalidad') {
          const { data: res } = await supabase
            .from('mortality')
            .select('quantity, date')
            .eq('estanque_id', selectedPond)
            .gte('date', thirtyDaysAgo.toISOString())
            .order('date', { ascending: true });
          data = res?.map(r => ({ 
            name: r.date.split('-')[2], 
            value: parseInt(r.quantity) 
          })) || [];
        } else if (selectedParam === 'biomasa') {
          const { data: res } = await supabase
            .from('biometrias')
            .select('total_biomass_kg, date')
            .eq('estanque_id', selectedPond)
            .gte('date', thirtyDaysAgo.toISOString())
            .order('date', { ascending: true });
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

    const fetchFinanceData = async (unitId: string) => {
      if (!unitId) return;
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

    initDashboard();
    fetchChartData();
    fetchFinanceData(localStorage.getItem('active_unit_id') || '');
  }, [router, selectedPond, selectedParam]);

  const getParamLabel = () => {
    switch(selectedParam) {
      case 'oxigeno': return 'Oxígeno (mg/L)';
      case 'mortalidad': return 'Mortalidad (Uds)';
      case 'biomasa': return 'Biomasa (kg)';
      case 'consumo': return 'Alimento (kg)';
      default: return 'Parámetro';
    }
  };

  const getParamColor = () => {
    switch(selectedParam) {
      case 'oxigeno': return '#3b82f6';
      case 'mortalidad': return '#ef4444';
      case 'biomasa': return '#10b981';
      case 'consumo': return '#8b5cf6';
      default: return '#3b82f6';
    }
  };

  const handleSendTicket = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!ticketSubject || !ticketMessage) {
      toast.error("Complete todos los campos.");
      return;
    }
    setSendingTicket(true);
    const sendPromise = async () => {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error("No hay sesión activa");

      const { error } = await supabase.from('support_tickets').insert([{
        user_id: user.id,
        subject: ticketSubject,
        description: ticketMessage,
        status: 'open',
        priority: 'medium'
      }]);

      if (error) throw error;
      return true;
    };

    toast.promise(sendPromise(), {
      loading: 'Enviando ticket...',
      success: () => {
        setIsSupportOpen(false);
        setTicketSubject('');
        setTicketMessage('');
        return "Ticket enviado con éxito. Te responderemos pronto.";
      },
      error: (err) => `Error: ${err.message}`
    }).finally(() => setSendingTicket(false));
  };

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
          <p style={{ color: 'var(--muted-foreground)', fontWeight: 600 }}>Unidad: <strong style={{ color: 'var(--foreground)' }}>{unitName || 'Cargando...'}</strong></p>
        </div>
        <div style={{ padding: '0.6rem 1.25rem', background: 'var(--secondary)', borderRadius: '14px', border: '1px solid var(--border)', fontSize: '0.85rem', fontWeight: 800 }}>
          {new Date().toLocaleDateString('es-ES', { weekday: 'long', day: 'numeric', month: 'long' })}
        </div>
      </header>

      <div className="responsive-grid-4" style={{ marginBottom: '2.5rem' }}>
        <FlipCard 
          title="Biomasa Total" 
          value={stats.biomass.total >= 1000 ? (Number(stats.biomass.total/1000).toFixed(1)) : stats.biomass.total} 
          unit={stats.biomass.total >= 1000 ? "Ton" : "kg"}
          change="+3.2%" 
          icon={Fish} 
          color="#3b82f6" 
          details={stats.biomass.details}
        />
        <FlipCard 
          title="Consumo Alimento" 
          value={Number(stats.consumption.total).toFixed(0)} 
          unit="kg"
          change="Mes" 
          icon={Utensils} 
          color="#8b5cf6" 
          details={stats.consumption.details}
        />
        <FlipCard 
          title="Mortalidad Finca" 
          value={`${stats.mortality.total}`} 
          unit={`uds (${stats.mortality.percent}%)`}
          change="Total" 
          icon={Skull} 
          color="#ef4444" 
          details={stats.mortality.details}
        />
        <FlipCard 
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
        <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
          <div className="card-premium" style={{ padding: '2rem' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '2rem', flexWrap: 'wrap', gap: '1rem' }}>
              <div>
                <h3 style={{ fontSize: '1.1rem', fontWeight: 900, letterSpacing: '-0.02em' }}>Tendencias de {getParamLabel()}</h3>
                <p style={{ fontSize: '0.8rem', color: 'var(--muted-foreground)', fontWeight: 600 }}>Basado en registros históricos del estanque</p>
              </div>
              <div style={{ display: 'flex', gap: '0.5rem', flexWrap: 'wrap' }}>
                <select 
                  value={selectedPond}
                  onChange={(e) => setSelectedPond(e.target.value)}
                  className="premium-input" 
                  style={{ width: 'auto', padding: '0.4rem 0.75rem', fontSize: '0.75rem', fontWeight: 800 }}
                >
                  <option value="">Estanque...</option>
                  {ponds.map(p => (
                    <option key={p.id} value={p.id}>{p.name}</option>
                  ))}
                </select>
                <select 
                  value={selectedParam}
                  onChange={(e) => setSelectedParam(e.target.value)}
                  className="premium-input" 
                  style={{ width: 'auto', padding: '0.4rem 0.75rem', fontSize: '0.75rem', fontWeight: 800, borderColor: getParamColor(), color: getParamColor() }}
                >
                  <option value="oxigeno">Oxígeno</option>
                  <option value="mortalidad">Mortalidad</option>
                  <option value="biomasa">Biomasa</option>
                  <option value="consumo">Alimento</option>
                </select>
              </div>
            </div>
            <div style={{ height: '320px', width: '100%', position: 'relative' }}>
              <AnimatePresence mode="wait">
                {isChartLoading ? (
                  <motion.div 
                    key="loader"
                    initial={{ opacity: 0 }}
                    animate={{ opacity: 1 }}
                    exit={{ opacity: 0 }}
                    style={{ position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center', background: 'rgba(255,255,255,0.5)', zIndex: 10, borderRadius: '14px' }}
                  >
                    <Loader2 className="animate-spin" size={32} color="var(--primary)" />
                  </motion.div>
                ) : null}
              </AnimatePresence>
              
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart data={chartData}>
                  <defs>
                    <linearGradient id="colorValue" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor={getParamColor()} stopOpacity={0.15}/>
                      <stop offset="95%" stopColor={getParamColor()} stopOpacity={0}/>
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="var(--border)" opacity={0.5} />
                  <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{ fontSize: 11, fill: 'var(--muted-foreground)', fontWeight: 600 }} dy={10} />
                  <YAxis axisLine={false} tickLine={false} tick={{ fontSize: 11, fill: 'var(--muted-foreground)', fontWeight: 600 }} dx={-10} />
                  <Tooltip 
                    contentStyle={{ 
                      background: 'var(--card)', 
                      border: '1px solid var(--border)', 
                      borderRadius: '14px', 
                      boxShadow: '0 10px 30px rgba(0,0,0,0.1)',
                      padding: '12px',
                      fontSize: '0.85rem',
                      fontWeight: 700
                    }} 
                  />
                  <Area type="monotone" dataKey="value" stroke={getParamColor()} strokeWidth={3} fillOpacity={1} fill="url(#colorValue)" animationDuration={1000}>
                    <LabelList 
                      dataKey="value" 
                      position="top" 
                      offset={12} 
                      style={{ fontSize: '10px', fontWeight: 800, fill: getParamColor(), opacity: 0.8 }} 
                    />
                  </Area>
                </AreaChart>
              </ResponsiveContainer>
              
              {chartData.length === 0 && !isChartLoading && (
                <div style={{ position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--muted-foreground)', fontWeight: 700, fontSize: '0.9rem' }}>
                  Sin datos registrados en los últimos 30 días
                </div>
              )}
            </div>
          </div>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
          <div className="card-premium" style={{ padding: '2rem' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
              <h3 style={{ fontSize: '0.85rem', fontWeight: 900, color: 'var(--muted-foreground)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Resumen Financiero</h3>
              <div style={{ padding: '0.4rem 0.75rem', background: 'rgba(16, 185, 129, 0.1)', color: '#10b981', borderRadius: '8px', fontSize: '0.7rem', fontWeight: 800 }}>
                {new Date().toLocaleDateString('es-CO', { month: 'long', year: 'numeric' }).toUpperCase()}
              </div>
            </div>
            
            <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem', position: 'relative' }}>
              {isFinanceLoading && (
                <div style={{ position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center', background: 'rgba(255,255,255,0.4)', zIndex: 5, borderRadius: '16px' }}>
                  <Loader2 className="animate-spin" size={24} color="var(--primary)" />
                </div>
              )}
              
              <div style={{ padding: '1.5rem', background: 'linear-gradient(135deg, #0d9488 0%, #0f766e 100%)', borderRadius: '20px', color: 'white', position: 'relative', overflow: 'hidden' }}>
                <div style={{ position: 'absolute', right: '-10px', bottom: '-10px', opacity: 0.1 }}>
                  <TrendingUp size={80} />
                </div>
                <div style={{ fontSize: '0.75rem', fontWeight: 700, opacity: 0.9, marginBottom: '0.25rem', textTransform: 'uppercase' }}>Inversión Total Finca</div>
                <div style={{ fontSize: '2rem', fontWeight: 950, letterSpacing: '-0.03em' }}>
                  ${financeData.total.toLocaleString('es-CO')}
                </div>
              </div>

              {[
                { label: 'Alimento Acumulado', value: financeData.food, color: '#10b981', icon: Utensils },
                { label: 'Siembra de Alevinos', value: financeData.seeds, color: '#3b82f6', icon: Fish },
                { label: 'Cuentas por Pagar', value: financeData.pending, color: '#ef4444', icon: AlertCircle }
              ].map((item, idx) => (
                <div key={idx} className="glass" style={{ display: 'flex', alignItems: 'center', gap: '1rem', padding: '1rem', borderRadius: '16px' }}>
                  <div style={{ padding: '0.6rem', background: `${item.color}15`, color: item.color, borderRadius: '10px' }}>
                    <item.icon size={18} />
                  </div>
                  <div style={{ flex: 1 }}>
                    <div style={{ fontSize: '0.8rem', color: 'var(--muted-foreground)', fontWeight: 700 }}>{item.label}</div>
                    <div style={{ fontSize: '1rem', fontWeight: 900 }}>${item.value.toLocaleString('es-CO')}</div>
                  </div>
                  <ArrowUpRight size={16} style={{ color: 'var(--muted-foreground)', opacity: 0.5 }} />
                </div>
              ))}
            </div>

            <Link href="/finanzas" style={{ textDecoration: 'none' }}>
              <button className="btn-primary" style={{ width: '100%', marginTop: '2rem', padding: '1rem', background: 'transparent', border: '1px solid var(--border)', color: 'var(--foreground)', borderRadius: '14px', fontWeight: 800, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '0.5rem' }}>
                Ir a Gestión Financiera <ChevronRight size={18} />
              </button>
            </Link>
          </div>
        </div>
      </div>

      <button 
        onClick={() => setIsSupportOpen(true)}
        style={{
          position: 'fixed',
          bottom: '2rem',
          right: '2rem',
          width: '64px',
          height: '64px',
          borderRadius: '22px',
          background: '#0d9488',
          color: 'white',
          border: 'none',
          boxShadow: '0 12px 30px rgba(13, 148, 136, 0.3)',
          cursor: 'pointer',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          zIndex: 100,
          transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)'
        }}
        onMouseEnter={(e) => {
          e.currentTarget.style.transform = 'translateY(-5px) scale(1.05)';
          e.currentTarget.style.boxShadow = '0 15px 35px rgba(13, 148, 136, 0.4)';
        }}
        onMouseLeave={(e) => {
          e.currentTarget.style.transform = 'translateY(0) scale(1)';
          e.currentTarget.style.boxShadow = '0 12px 30px rgba(13, 148, 136, 0.3)';
        }}
      >
        <MessageSquare size={32} />
      </button>

      <AnimatePresence>
        {isSupportOpen && (
          <div style={{ position: 'fixed', inset: 0, background: 'rgba(2, 6, 23, 0.7)', backdropFilter: 'blur(16px)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000, padding: '1.5rem' }}>
            <motion.div initial={{ scale: 0.9, opacity: 0 }} animate={{ scale: 1, opacity: 1 }} exit={{ scale: 0.9, opacity: 0 }} className="card-premium" style={{ width: '100%', maxWidth: '440px', padding: '3rem', position: 'relative', borderRadius: '32px' }}>
              <button onClick={() => setIsSupportOpen(false)} style={{ position: 'absolute', top: '1.5rem', right: '1.5rem', background: 'none', border: 'none', color: 'var(--muted-foreground)', cursor: 'pointer', padding: '0.5rem' }}>
                <X size={24} />
              </button>
              <h3 style={{ fontWeight: 900, fontSize: '1.75rem', marginBottom: '2.5rem', letterSpacing: '-0.04em' }}>Soporte FishBit</h3>
              <form onSubmit={handleSendTicket} style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '0.6rem' }}>
                  <label className="premium-label">¿En qué podemos ayudarte?</label>
                  <input 
                    required 
                    placeholder="Escribe el asunto aquí..." 
                    className="premium-input"
                    style={{ fontWeight: 600 }}
                    value={ticketSubject}
                    onChange={(e) => setTicketSubject(e.target.value)}
                  />
                </div>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '0.6rem' }}>
                  <label className="premium-label">Mensaje Detallado</label>
                  <textarea 
                    required 
                    rows={4} 
                    placeholder="Describe tu consulta..." 
                    className="premium-input"
                    style={{ resize: 'none', fontWeight: 600 }}
                    value={ticketMessage}
                    onChange={(e) => setTicketMessage(e.target.value)}
                  />
                </div>
                <button 
                  type="submit" 
                  disabled={sendingTicket}
                  className="btn-primary" 
                  style={{ width: '100%', padding: '1.25rem', fontWeight: 900, marginTop: '1rem', background: '#0d9488', borderRadius: '16px' }}
                >
                  {sendingTicket ? 'Enviando...' : 'Enviar Solicitud'}
                </button>
              </form>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </div>
  );
}
