'use client';

import { useEffect, useState, useCallback, useMemo } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  Settings, 
  Bell, 
  Users, 
  Activity, 
  Thermometer, 
  Wind,
  Save,
  DollarSign,
  CreditCard,
  Trash2,
  Mail,
  UserCircle,
  Info,
  RefreshCw,
  X,
  ChevronRight,
  Shield,
  Droplets,
  AlertTriangle,
  Package,
  ShoppingBag,
  Loader2
} from 'lucide-react';
import { supabase } from '@/lib/supabase';
import { toast } from 'react-hot-toast';

// Official Feed Catalog based on Invoices
const FEED_CATALOG = [
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
];

export default function ConfiguracionPage() {
  const [userRole, setUserRole] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState('parametros');
  const [isSuperAdmin, setIsSuperAdmin] = useState(false);
  const [loading, setLoading] = useState(true);
  const [prices, setPrices] = useState({ basic: 18, premium: 30 });

  // Thresholds state (mock for UI)
  const [thresholds, setThresholds] = useState({
    o2_mg_l_min: '4.5', o2_mg_l_max: '9.0',
    o2_perc_min: '80', o2_perc_max: '120',
    ph_min: '6.5', ph_max: '8.5',
    temperature_c_min: '26.0', temperature_c_max: '31.0',
    alkalinity_min: '50', alkalinity_max: '150',
    ammonia_mg_l_min: '0', ammonia_mg_l_max: '0.02',
    nitrite_mg_l_min: '0', nitrite_mg_l_max: '0.1',
    nitrate_mg_l_min: '0', nitrate_mg_l_max: '50',
    warmMortality: '5', coldMortality: '10'
  });

  const handleThresholdChange = (key: string, value: string) => {
    setThresholds(prev => ({ ...prev, [key]: value }));
  };  const fetchSettings = useCallback(async () => {
    const activeUnitId = localStorage.getItem('active_unit_id');
    if (!activeUnitId) return;

    try {
      const { data } = await supabase
        .from('unit_settings')
        .select('thresholds')
        .eq('unit_id', activeUnitId)
        .single();

      if (data?.thresholds) {
        const t = data.thresholds;
        setThresholds({
          o2_mg_l_min: t.o2_mg_l_min?.toString() || '4.5',
          o2_mg_l_max: t.o2_mg_l_max?.toString() || '9.0',
          o2_perc_min: t.o2_perc_min?.toString() || '80',
          o2_perc_max: t.o2_perc_max?.toString() || '120',
          ph_min: t.ph_min?.toString() || '6.5',
          ph_max: t.ph_max?.toString() || '8.5',
          temperature_c_min: t.temperature_c_min?.toString() || '26.0',
          temperature_c_max: t.temperature_c_max?.toString() || '31.0',
          alkalinity_min: t.alkalinity_min?.toString() || '50',
          alkalinity_max: t.alkalinity_max?.toString() || '150',
          ammonia_mg_l_min: t.ammonia_mg_l_min?.toString() || '0',
          ammonia_mg_l_max: t.ammonia_mg_l_max?.toString() || '0.02',
          nitrite_mg_l_min: t.nitrite_mg_l_min?.toString() || '0',
          nitrite_mg_l_max: t.nitrite_mg_l_max?.toString() || '0.1',
          nitrate_mg_l_min: t.nitrate_mg_l_min?.toString() || '0',
          nitrate_mg_l_max: t.nitrate_mg_l_max?.toString() || '50',
          warmMortality: t.warm_mortality_max?.toString() || '5',
          coldMortality: t.cold_mortality_max?.toString() || '10',
        });
      }
    } catch (err) {
      console.error("Error loading settings:", err);
    }
  }, []);

  const saveSettings = async () => {
    const activeUnitId = localStorage.getItem('active_unit_id');
    if (!activeUnitId) {
      toast.error("No se identificó la unidad activa.");
      return;
    }

    const savePromise = async () => {
      const thresholdsPayload = {
        o2_mg_l_min: parseFloat(thresholds.o2_mg_l_min),
        o2_mg_l_max: parseFloat(thresholds.o2_mg_l_max),
        o2_perc_min: parseFloat(thresholds.o2_perc_min),
        o2_perc_max: parseFloat(thresholds.o2_perc_max),
        ph_min: parseFloat(thresholds.ph_min),
        ph_max: parseFloat(thresholds.ph_max),
        temperature_c_min: parseFloat(thresholds.temperature_c_min),
        temperature_c_max: parseFloat(thresholds.temperature_c_max),
        alkalinity_min: parseFloat(thresholds.alkalinity_min),
        alkalinity_max: parseFloat(thresholds.alkalinity_max),
        ammonia_mg_l_min: parseFloat(thresholds.ammonia_mg_l_min),
        ammonia_mg_l_max: parseFloat(thresholds.ammonia_mg_l_max),
        nitrite_mg_l_min: parseFloat(thresholds.nitrite_mg_l_min),
        nitrite_mg_l_max: parseFloat(thresholds.nitrite_mg_l_max),
        nitrate_mg_l_min: parseFloat(thresholds.nitrate_mg_l_min),
        nitrate_mg_l_max: parseFloat(thresholds.nitrate_mg_l_max),
        warm_mortality_max: parseFloat(thresholds.warmMortality),
        cold_mortality_max: parseFloat(thresholds.coldMortality),
      };

      const { error } = await supabase
        .from('unit_settings')
        .upsert(
          { unit_id: activeUnitId, thresholds: thresholdsPayload, updated_at: new Date().toISOString() },
          { onConflict: 'unit_id' }
        );

      if (error) throw error;
    };

    toast.promise(savePromise(), {
      loading: 'Guardando configuración...',
      success: 'Parámetros actualizados correctamente.',
      error: 'Error al guardar los rangos.',
    });
  };

  useEffect(() => {
    async function checkRole() {
      const { data: { user } } = await supabase.auth.getUser();
      if (user) {
        const { data: profile } = await supabase
          .from('profiles')
          .select('is_superadmin, role')
          .eq('id', user.id)
          .single();
        
        const superStatus = profile?.is_superadmin || false;
        setIsSuperAdmin(superStatus);

        const { data: userUnit } = await supabase
          .from('user_units')
          .select('unit_id, role')
          .eq('user_id', user.id)
          .limit(1)
          .single();

        const finalRole = userUnit?.role || profile?.role || 'operario';
        setUserRole(finalRole);
        
        if (userUnit?.unit_id) {
           localStorage.setItem('active_unit_id', userUnit.unit_id);
           fetchSettings();
        }

        if (superStatus) {
          setActiveTab('negocio');
        } else if (finalRole === 'admin') {
          setActiveTab('equipo');
        } else {
          setActiveTab('parametros');
        }
      }
      setLoading(false);
    }
    checkRole();
  }, [fetchSettings]);

  const getTabs = () => {
    if (isSuperAdmin) {
      return [
        { id: 'negocio', label: 'Planes', icon: DollarSign },
        { id: 'general', label: 'Sistema', icon: Settings },
      ];
    }

    const baseTabs = [
      { id: 'parametros', label: 'Alertas', icon: Activity },
      { id: 'notificaciones', label: 'Notificaciones', icon: Bell },
    ];

    if (userRole === 'admin') {
      baseTabs.push({ id: 'equipo', label: 'Equipo', icon: Users });
    }

    if (userRole === 'operario') {
      return [{ id: 'parametros', label: 'Estado', icon: Activity }];
    }

    return baseTabs;
  };

  const tabs = getTabs();

  if (loading) {
    return (
      <div style={{ minHeight: '80vh', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <RefreshCw className="animate-spin" size={48} color="#0d9488" />
      </div>
    );
  }

  return (
    <div className="animate-fade-in page-container">
      <header style={{ marginBottom: '3rem' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', marginBottom: '0.5rem' }}>
          <div style={{ width: '48px', height: '48px', background: 'var(--primary)', borderRadius: '14px', color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
             <Settings size={24} />
          </div>
          <h1 style={{ fontWeight: 900, letterSpacing: '-0.04em' }}>
            {isSuperAdmin ? 'Panel de Control FishBit' : 'Configuración'}
          </h1>
        </div>
        <p style={{ color: 'var(--muted-foreground)', fontWeight: 600 }}>
          {isSuperAdmin 
            ? 'Gestión global de la plataforma y modelos de negocio.' 
            : 'Personaliza los parámetros técnicos de tu unidad acuícola.'}
        </p>
      </header>

      <div style={{ display: 'flex', gap: '0.4rem', padding: '0.4rem', background: 'var(--secondary)', borderRadius: '18px', width: 'fit-content', marginBottom: '2.5rem', flexWrap: 'wrap' }}>
        {tabs.map(tab => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id)}
            style={{
              padding: '0.75rem 1.4rem',
              borderRadius: '14px',
              background: activeTab === tab.id ? 'var(--primary)' : 'transparent',
              color: activeTab === tab.id ? 'white' : 'var(--muted-foreground)',
              border: 'none',
              cursor: 'pointer',
              fontWeight: 800,
              display: 'flex',
              alignItems: 'center',
              gap: '0.6rem',
              transition: 'all 0.25s ease',
              fontSize: '0.85rem'
            }}
          >
            <tab.icon size={18} />
            {tab.label}
          </button>
        ))}
      </div>

      <div className="card-premium" style={{ padding: 'clamp(1rem, 3vw, 2.5rem)' }}>
        <AnimatePresence mode="wait">
          <motion.div 
            key={activeTab}
            initial={{ opacity: 0, x: 10 }} 
            animate={{ opacity: 1, x: 0 }} 
            exit={{ opacity: 0, x: -10 }}
            transition={{ duration: 0.2 }}
          >
            {isSuperAdmin && activeTab === 'negocio' && (
              <div>
                <div style={{ marginBottom: '2.5rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem' }}>
                  <div>
                    <h2 style={{ fontSize: '1.4rem', fontWeight: 900, letterSpacing: '-0.02em', marginBottom: '0.25rem' }}>Estructura de Precios</h2>
                    <p style={{ fontSize: '0.85rem', color: 'var(--muted-foreground)', fontWeight: 600 }}>Ajusta las suscripciones globales.</p>
                  </div>
                  <button className="btn-primary" style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', background: '#0d9488' }}>
                    <Save size={18} /> Guardar Tarifas
                  </button>
                </div>
                <div className="responsive-grid-2">
                  <PriceCard title="Suscripción Básica" icon={CreditCard} value={prices.basic} onChange={(v: number) => setPrices({...prices, basic: v})} />
                  <PriceCard title="Suscripción Premium" icon={DollarSign} value={prices.premium} onChange={(v: number) => setPrices({...prices, premium: v})} color="#f59e0b" />
                </div>
              </div>
            )}

            {isSuperAdmin && activeTab === 'general' && (
              <div>
                <div style={{ marginBottom: '2.5rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem' }}>
                  <div>
                    <h2 style={{ fontSize: '1.4rem', fontWeight: 900, letterSpacing: '-0.02em', marginBottom: '0.25rem' }}>Sistema Maestro</h2>
                    <p style={{ fontSize: '0.85rem', color: 'var(--muted-foreground)', fontWeight: 600 }}>Reglas de negocio y soporte.</p>
                  </div>
                  <button className="btn-primary" style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', background: '#0d9488' }}>
                    <Save size={18} /> Aplicar Cambios
                  </button>
                </div>
                <div className="responsive-grid-3">
                  <SystemInput label="Moneda de Transacción" type="select" options={['COP', 'USD', 'MXN']} />
                  <SystemInput label="WhatsApp Central" type="text" placeholder="+57 300 000 0000" />
                  <SystemInput label="Gracia (Días)" type="number" defaultValue="3" />
                </div>
              </div>
            )}

            {!isSuperAdmin && activeTab === 'parametros' && (
              <div>
                <div style={{ marginBottom: '2.5rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem' }}>
                  <div>
                    <h2 style={{ fontSize: '1.4rem', fontWeight: 950, letterSpacing: '-0.03em', marginBottom: '0.25rem' }}>Configuración de Alertas y Umbrales</h2>
                    <p style={{ fontSize: '0.85rem', color: 'var(--muted-foreground)', fontWeight: 600 }}>Personaliza los límites operativos de tu producción.</p>
                  </div>
                  <button onClick={saveSettings} className="btn-primary" style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                    <Save size={18} /> Guardar Rangos
                  </button>
                </div>

                <div style={{ display: 'flex', flexDirection: 'column', gap: '3rem' }}>
                  {/* Bloque 1: Calidad de Agua */}
                  <ThresholdSection title="Calidad de Agua (Físico-Químicos y Nitrógeno)" icon={Droplets} color="#3b82f6">
                    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: '1.5rem' }}>
                      <ParamInput 
                        label="Oxígeno Disuelto (mg/L)" icon={Wind} color="#3b82f6" 
                        min={thresholds.o2_mg_l_min} max={thresholds.o2_mg_l_max}
                        onMinChange={(v: string) => handleThresholdChange('o2_mg_l_min', v)}
                        onMaxChange={(v: string) => handleThresholdChange('o2_mg_l_max', v)}
                      />
                      <ParamInput 
                        label="Saturación O2 (%)" icon={Activity} color="#0ea5e9" 
                        min={thresholds.o2_perc_min} max={thresholds.o2_perc_max}
                        onMinChange={(v: string) => handleThresholdChange('o2_perc_min', v)}
                        onMaxChange={(v: string) => handleThresholdChange('o2_perc_max', v)}
                      />
                      <ParamInput 
                        label="Temperatura (°C)" icon={Thermometer} color="#ef4444" 
                        min={thresholds.temperature_c_min} max={thresholds.temperature_c_max}
                        onMinChange={(v: string) => handleThresholdChange('temperature_c_min', v)}
                        onMaxChange={(v: string) => handleThresholdChange('temperature_c_max', v)}
                      />
                      <ParamInput 
                        label="pH" icon={Activity} color="#8b5cf6" 
                        min={thresholds.ph_min} max={thresholds.ph_max}
                        onMinChange={(v: string) => handleThresholdChange('ph_min', v)}
                        onMaxChange={(v: string) => handleThresholdChange('ph_max', v)}
                      />
                      <ParamInput 
                        label="Alcalinidad (mg/L)" icon={Shield} color="#10b981" 
                        min={thresholds.alkalinity_min} max={thresholds.alkalinity_max}
                        onMinChange={(v: string) => handleThresholdChange('alkalinity_min', v)}
                        onMaxChange={(v: string) => handleThresholdChange('alkalinity_max', v)}
                      />
                      <ParamInput 
                        label="Amonio (mg/L)" icon={AlertTriangle} color="#f59e0b" 
                        min={thresholds.ammonia_mg_l_min} max={thresholds.ammonia_mg_l_max}
                        onMinChange={(v: string) => handleThresholdChange('ammonia_mg_l_min', v)}
                        onMaxChange={(v: string) => handleThresholdChange('ammonia_mg_l_max', v)}
                      />
                      <ParamInput 
                        label="Nitrito (mg/L)" icon={AlertTriangle} color="#f97316" 
                        min={thresholds.nitrite_mg_l_min} max={thresholds.nitrite_mg_l_max}
                        onMinChange={(v: string) => handleThresholdChange('nitrite_mg_l_min', v)}
                        onMaxChange={(v: string) => handleThresholdChange('nitrite_mg_l_max', v)}
                      />
                      <ParamInput 
                        label="Nitrato (mg/L)" icon={AlertTriangle} color="#ea580c" 
                        min={thresholds.nitrate_mg_l_min} max={thresholds.nitrate_mg_l_max}
                        onMinChange={(v: string) => handleThresholdChange('nitrate_mg_l_min', v)}
                        onMaxChange={(v: string) => handleThresholdChange('nitrate_mg_l_max', v)}
                      />
                    </div>
                  </ThresholdSection>

                  {/* Bloque 2: Mortalidad Aceptable */}
                  <ThresholdSection title="Límites de Mortalidad (%)" icon={AlertTriangle} color="#ef4444">
                    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))', gap: '1.5rem' }}>
                      <div style={{ display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
                        <label className="premium-label" style={{ position: 'static', fontWeight: 700 }}>Especies Cálidas (Cachama/Tilapia) %</label>
                        <input 
                          type="number"
                          className="premium-input" 
                          value={thresholds.warmMortality} 
                          onChange={(e) => handleThresholdChange('warmMortality', e.target.value)}
                          style={{ fontWeight: 800 }} 
                        />
                      </div>
                      <div style={{ display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
                        <label className="premium-label" style={{ position: 'static', fontWeight: 700 }}>Especies Frías (Trucha) %</label>
                        <input 
                          type="number"
                          className="premium-input" 
                          value={thresholds.coldMortality} 
                          onChange={(e) => handleThresholdChange('coldMortality', e.target.value)}
                          style={{ fontWeight: 800 }} 
                        />
                      </div>
                    </div>
                  </ThresholdSection>

                  {/* Bloque 3: Alerta de Desabastecimiento (Inventario) */}
                  <ThresholdSection title="Alertas de Desabastecimiento de Alimento" icon={ShoppingBag} color="#10b981">
                    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))', gap: '1.5rem' }}>
                      {FEED_CATALOG.map((item) => (
                        <div key={item} style={{ display: 'flex', flexDirection: 'column', gap: '0.4rem' }} className="glass p-4 rounded-xl border border-slate-200">
                          <label className="premium-label">{item}</label>
                          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.2rem' }}>
                             <span style={{ fontSize: '0.65rem', fontWeight: 900, color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Stock Mínimo (Bultos)</span>
                             <input type="number" defaultValue="10" className="premium-input" style={{ fontWeight: 900, width: '100%' }} />
                          </div>
                        </div>
                      ))}
                    </div>
                  </ThresholdSection>
                </div>
              </div>
            )}

            {!isSuperAdmin && activeTab === 'equipo' && <TeamManagement />}

            {(activeTab === 'notificaciones') && (
              <div style={{ padding: '6rem 2rem', textAlign: 'center' }}>
                <Bell size={48} style={{ margin: '0 auto 1.5rem', opacity: 0.1, color: 'var(--primary)' }} />
                <h3 style={{ fontWeight: 900, color: 'var(--muted-foreground)' }}>Canales de Notificación</h3>
                <p style={{ fontSize: '0.9rem', color: 'var(--muted-foreground)', fontWeight: 600 }}>Próximamente: Integración con WhatsApp y Push Notifications.</p>
              </div>
            )}
          </motion.div>
        </AnimatePresence>
      </div>
    </div>
  );
}

// --- Corrected Structural Components ---

const ThresholdSection = ({ title, icon: Icon, color, children }: any) => (
  <div className="glass" style={{ padding: 'clamp(1rem, 3vw, 2.5rem)', borderRadius: '24px', border: `1px solid ${color}15` }}>
    <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '2rem' }}>
      <div style={{ background: `${color}15`, color, padding: '0.75rem', borderRadius: '14px' }}>
        <Icon size={24} />
      </div>
      <h3 style={{ fontSize: '1.25rem', fontWeight: 950, letterSpacing: '-0.02em', color: 'var(--foreground)' }}>{title}</h3>
    </div>
    {children}
  </div>
);

const ParamInput = ({ label, icon: Icon, color, min, max, onMinChange, onMaxChange }: any) => (
  <div className="glass" style={{ padding: '1.5rem', borderRadius: '16px', border: `1px solid ${color}15`, display: 'flex', flexDirection: 'column', gap: '1rem' }}>
    <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', color }}>
      <Icon size={18} /> <span style={{ fontWeight: 900, fontSize: '0.9rem' }}>{label}</span>
    </div>
    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
      {/* Contenedor Mínimo */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
        <label className="premium-label" style={{ position: 'static', color: 'var(--muted-foreground)', fontWeight: 700, fontSize: '0.65rem', textTransform: 'uppercase' }}>Mínimo</label>
        <input 
          type="number" 
          step="0.01"
          value={min} 
          onChange={(e) => onMinChange(e.target.value)}
          className="premium-input" 
          style={{ fontWeight: 800, width: '100%', fontSize: '0.9rem' }} 
        />
      </div>
      {/* Contenedor Máximo */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
        <label className="premium-label" style={{ position: 'static', color: 'var(--muted-foreground)', fontWeight: 700, fontSize: '0.65rem', textTransform: 'uppercase' }}>Máximo</label>
        <input 
          type="number" 
          step="0.01"
          value={max} 
          onChange={(e) => onMaxChange(e.target.value)}
          className="premium-input" 
          style={{ fontWeight: 800, width: '100%', fontSize: '0.9rem' }} 
        />
      </div>
    </div>
  </div>
);

const PriceCard = ({ title, icon: Icon, value, onChange, color }: any) => (
  <div className="glass" style={{ padding: '2rem', borderRadius: '24px' }}>
    <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '1.5rem', color: color || 'var(--primary)' }}>
      <Icon size={24} /> <span style={{ fontWeight: 950, fontSize: '1.1rem' }}>{title}</span>
    </div>
    <div style={{ display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
      <label className="premium-label" style={{ position: 'static', fontWeight: 700 }}>Valor Mensual (USD)</label>
      <div style={{ position: 'relative' }}>
        <span style={{ position: 'absolute', left: '1.25rem', top: '50%', transform: 'translateY(-50%)', fontWeight: 900, color: 'var(--muted-foreground)' }}>$</span>
        <input type="number" value={value} onChange={e => onChange(Number(e.target.value))} className="premium-input" style={{ paddingLeft: '2.5rem', fontSize: '1.25rem', fontWeight: 950 }} />
      </div>
    </div>
  </div>
);

const SystemInput = ({ label, type, options, placeholder, defaultValue }: any) => (
  <div className="glass" style={{ padding: '1.5rem', borderRadius: '20px', display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
    <label className="premium-label" style={{ position: 'static', fontWeight: 700 }}>{label}</label>
    {type === 'select' ? (
      <select className="premium-input" style={{ fontWeight: 800 }}>
        {options.map((o: any) => <option key={o} value={o}>{o}</option>)}
      </select>
    ) : (
      <input type={type} placeholder={placeholder} defaultValue={defaultValue} className="premium-input" style={{ fontWeight: 800 }} />
    )}
  </div>
);

const InputGroup = ({ label, placeholder, value, onChange, defaultValue }: any) => (
  <div style={{ display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
    <label className="premium-label" style={{ position: 'static', fontWeight: 700 }}>{label}</label>
    <input 
      required 
      placeholder={placeholder} 
      value={value} 
      defaultValue={defaultValue}
      onChange={e => onChange?.(e.target.value)} 
      className="premium-input" 
      style={{ fontWeight: 800, width: '100%' }} 
    />
  </div>
);

const TeamManagement = () => {
  const [members, setMembers] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [showInviteModal, setShowInviteModal] = useState(false);
  const [inviteData, setInviteData] = useState({ email: '', fullName: '', role: 'tecnico' });
  const [inviting, setInviting] = useState(false);
  const [planType, setPlanType] = useState('basic');

  const fetchTeam = useCallback(async (isManual = false) => {
    if (isManual) setRefreshing(true);
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      const { data: myProfile } = await supabase.from('profiles').select('email').eq('id', user.id).single();
      if (myProfile && !myProfile.email && user.email) {
        await supabase.from('profiles').update({ email: user.email }).eq('id', user.id);
      }

      let activeUnitId = localStorage.getItem('active_unit_id');
      
      if (!activeUnitId) {
        const { data: uu } = await supabase.from('user_units').select('unit_id').eq('user_id', user.id).limit(1).single();
        if (uu) {
          activeUnitId = uu.unit_id;
          localStorage.setItem('active_unit_id', activeUnitId as string);
        }
      }

      if (!activeUnitId) {
        setLoading(false);
        return;
      }

      const [subRes, uuRes] = await Promise.all([
        supabase.from('subscriptions').select('plan_type').eq('unit_id', activeUnitId).single(),
        supabase.from('user_units').select('user_id, role').eq('unit_id', activeUnitId)
      ]);

      if (subRes.data) setPlanType(subRes.data.plan_type);
      if (uuRes.error) throw uuRes.error;

      const userUnits = uuRes.data || [];

      if (userUnits.length === 0) {
        setMembers([]);
        return;
      }

      const userIds = userUnits.map(uu => uu.user_id);
      const { data: profiles, error: pError } = await supabase
        .from('profiles')
        .select('*')
        .in('id', userIds);

      const processedMembers = userUnits.map((uu: any) => {
        const profile = profiles?.find(p => p.id === uu.user_id) || {};
        return {
          ...profile,
          id: uu.user_id,
          full_name: profile.full_name || profile.nombre || (uu.role === 'admin' ? 'Administrador' : 'Miembro Invitado'),
          email: profile.email || profile.correo || 'Pendiente de registro',
          role: uu.role || profile.role || 'operario',
          isGhost: !profile.id
        };
      });

      setMembers(processedMembers);
    } catch (err: any) { 
      toast.error("Error al cargar equipo.");
    } finally { 
      setLoading(false); 
      setRefreshing(false);
    }
  }, []);

  useEffect(() => {
    fetchTeam();
    const activeUnitId = localStorage.getItem('active_unit_id');
    if (!activeUnitId) return;

    const channel = supabase.channel(`team_sync_${activeUnitId}`)
      .on('postgres_changes', { 
        event: '*', 
        schema: 'public', 
        table: 'user_units', 
        filter: `unit_id=eq.${activeUnitId}` 
      }, () => fetchTeam(true))
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, [fetchTeam]);

  const handleInvite = async (e: React.FormEvent) => {
    e.preventDefault();
    setInviting(true);
    const invitePromise = async () => {
      if (planType === 'basic') {
        const countByRole = members.filter(m => m.role === inviteData.role).length;
        if (countByRole >= 1) { 
          throw new Error("Límite de Plan Básico: Solo 1 usuario por rol.");
        }
      }
      let activeUnitId = localStorage.getItem('active_unit_id');
      if (!activeUnitId) throw new Error("Unidad no identificada.");

      const { data, error: authError } = await supabase.auth.signUp({ 
        email: inviteData.email, 
        password: 'FishBit2026!', 
        options: { data: { full_name: inviteData.fullName } } 
      });

      if (authError) throw authError;

      if (data.user) {
        await supabase.from('profiles').insert([{ 
          id: data.user.id, 
          full_name: inviteData.fullName, 
          email: inviteData.email, 
          role: inviteData.role, 
          is_superadmin: false 
        }]);

        await supabase.from('user_units').insert([{ 
          user_id: data.user.id, 
          unit_id: activeUnitId,
          role: inviteData.role 
        }]);
        
        setShowInviteModal(false);
        setInviteData({ email: '', fullName: '', role: 'tecnico' });
        fetchTeam(true);
      }
    };

    toast.promise(invitePromise(), {
      loading: 'Enviando invitación...',
      success: 'Miembro invitado correctamente.',
      error: (err) => err.message
    }).finally(() => setInviting(false));
  };

  const handleDelete = async (userId: string) => {
    if (!confirm("¿Eliminar acceso para este miembro?")) return;
    
    const deletePromise = async () => {
      const activeUnitId = localStorage.getItem('active_unit_id');
      await supabase.from('user_units').delete().eq('user_id', userId).eq('unit_id', activeUnitId);
      fetchTeam(true);
    };

    toast.promise(deletePromise(), {
      loading: 'Eliminando...',
      success: 'Acceso revocado.',
      error: 'Error al eliminar.'
    });
  };

  const handleUpdateRole = async (userId: string, newRole: string) => {
    setMembers(prev => prev.map(m => m.id === userId ? { ...m, role: newRole } : m));
    
    const updatePromise = async () => {
      const activeUnitId = localStorage.getItem('active_unit_id');
      const { error } = await supabase
        .from('user_units')
        .update({ role: newRole })
        .eq('user_id', userId)
        .eq('unit_id', activeUnitId);
      
      if (error) throw error;
    };

    toast.promise(updatePromise(), {
      loading: 'Actualizando rol...',
      success: 'Rol actualizado.',
      error: 'Error al cambiar rol.'
    });
  };

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2.5rem', flexWrap: 'wrap', gap: '1.5rem' }}>
        <div>
          <h2 style={{ fontSize: '1.4rem', fontWeight: 900, letterSpacing: '-0.02em' }}>Gestión de Personal</h2>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.6rem', marginTop: '0.4rem' }}>
            <span style={{ 
              padding: '4px 12px', 
              borderRadius: '20px', 
              fontSize: '0.65rem', 
              fontWeight: 900, 
              background: planType === 'premium' ? 'rgba(245, 158, 11, 0.1)' : 'rgba(13, 148, 136, 0.1)',
              color: planType === 'premium' ? '#d97706' : '#0d9488',
              textTransform: 'uppercase',
              letterSpacing: '0.05em'
            }}>
              {planType === 'premium' ? 'Premium: Ilimitado' : 'Básico: 1 por rol'}
            </span>
          </div>
        </div>
        <div style={{ display: 'flex', gap: '0.75rem' }}>
          <button 
            onClick={() => fetchTeam(true)} 
            disabled={refreshing}
            style={{ padding: '0.8rem', borderRadius: '12px', border: '1px solid var(--border)', background: 'var(--secondary)', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }}
          >
            <RefreshCw size={20} className={refreshing ? 'animate-spin' : ''} />
          </button>
          <button onClick={() => setShowInviteModal(true)} className="btn-primary" style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', borderRadius: '12px', padding: '0.8rem 1.4rem' }}>
            <Users size={20} /> Invitar Miembro
          </button>
        </div>
      </div>
      
      <div className="responsive-grid-2" style={{ opacity: refreshing ? 0.6 : 1, transition: 'opacity 0.2s' }}>
        {members.map(member => (
          <div key={member.id} className="glass" style={{ display: 'flex', alignItems: 'center', gap: '1.25rem', padding: '1.5rem', borderRadius: '20px' }}>
            <div style={{ width: '56px', height: '56px', borderRadius: '16px', background: '#0d9488', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'white' }}>
              <UserCircle size={32} />
            </div>
            <div style={{ flex: 1 }}>
              <div style={{ fontWeight: 900, fontSize: '1.1rem', letterSpacing: '-0.02em' }}>{member.full_name}</div>
              <div style={{ fontSize: '0.8rem', color: 'var(--muted-foreground)', fontWeight: 600 }}>{member.email}</div>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
              {member.role !== 'admin' ? (
                <select value={member.role} onChange={(e) => handleUpdateRole(member.id, e.target.value)} className="premium-input" style={{ width: 'auto', padding: '0.4rem 0.75rem', fontSize: '0.75rem', fontWeight: 800 }}>
                  <option value="tecnico">Técnico</option>
                  <option value="operario">Operario</option>
                </select>
              ) : <div className="glass" style={{ padding: '0.4rem 1rem', borderRadius: '8px', background: '#0d9488', color: 'white', fontSize: '0.65rem', fontWeight: 900 }}>OWNER</div>}
              {member.role !== 'admin' && (
                <button onClick={() => handleDelete(member.id)} style={{ color: '#ef4444', background: 'rgba(239, 68, 68, 0.05)', border: 'none', borderRadius: '10px', padding: '0.6rem', cursor: 'pointer' }}>
                  <Trash2 size={18} />
                </button>
              )}
            </div>
          </div>
        ))}
      </div>

      <AnimatePresence>
        {showInviteModal && (
          <div style={{ position: 'fixed', inset: 0, background: 'rgba(2, 6, 23, 0.7)', backdropFilter: 'blur(16px)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000, padding: '1.5rem' }}>
            <motion.div initial={{ scale: 0.9, opacity: 0 }} animate={{ scale: 1, opacity: 1 }} className="card-premium" style={{ width: '100%', maxWidth: '460px', padding: '3rem', borderRadius: '32px', position: 'relative' }}>
              <button onClick={() => setShowInviteModal(false)} style={{ position: 'absolute', top: '1.5rem', right: '1.5rem', background: 'none', border: 'none', color: 'var(--muted-foreground)', cursor: 'pointer', padding: '0.5rem' }}>
                <X size={24} />
              </button>
              <h3 style={{ fontWeight: 900, fontSize: '1.75rem', marginBottom: '2.5rem', letterSpacing: '-0.04em' }}>Invitar Miembro</h3>
              <form onSubmit={handleInvite} style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
                <InputGroup label="Nombre Completo" placeholder="Ej. Juan Pérez" value={inviteData.fullName} onChange={(v:any) => setInviteData({...inviteData, fullName: v})} />
                <InputGroup label="Correo Electrónico" placeholder="juan@fishbit.app" value={inviteData.email} onChange={(v:any) => setInviteData({...inviteData, email: v})} />
                <div style={{ display: 'flex', flexDirection: 'column', gap: '0.6rem' }}>
                  <label className="premium-label">Rol Asignado</label>
                  <select value={inviteData.role} onChange={(e) => setInviteData({...inviteData, role: e.target.value})} className="premium-input" style={{ fontWeight: 700 }}>
                    <option value="tecnico">Técnico Operativo</option>
                    <option value="operario">Personal de Campo</option>
                  </select>
                </div>
                <div style={{ display: 'flex', gap: '1rem', marginTop: '1rem' }}>
                  <button type="button" onClick={() => setShowInviteModal(false)} className="glass" style={{ flex: 1, padding: '1.1rem', borderRadius: '16px', fontWeight: 800, border: '1px solid var(--border)' }}>Cancelar</button>
                  <button type="submit" disabled={inviting} className="btn-primary" style={{ flex: 1, background: '#0d9488', borderRadius: '16px' }}>
                    {inviting ? 'Invitando...' : 'Confirmar'}
                  </button>
                </div>
              </form>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </div>
  );
};
