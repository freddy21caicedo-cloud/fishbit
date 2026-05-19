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

  // Global settings state
  const [systemSettings, setSystemSettings] = useState({
    price_cop: 100000,
    support_whatsapp: '+573000000000',
    free_trial_days: 30,
    grace_days: 3,
    support_email: 'soporte@fishbit.co'
  });

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

  const [notificationSettings, setNotificationSettings] = useState({
    whatsapp_enabled: false,
    whatsapp_number: '',
    whatsapp_alert_oxygen: true,
    whatsapp_alert_temp: true,
    whatsapp_alert_mortality: true,
    whatsapp_alert_inventory: true,
    email_enabled: false,
    email_address: '',
    email_daily_summary: true,
    email_non_compliance: false,
    push_enabled: false,
    push_frequency: 'instant'
  });

  const handleThresholdChange = (key: string, value: string) => {
    setThresholds(prev => ({ ...prev, [key]: value }));
  };

  const fetchGlobalSettings = useCallback(async () => {
    try {
      const { data, error } = await supabase
        .from('app_config')
        .select('value')
        .eq('key', 'global_settings')
        .maybeSingle();

      if (data?.value) {
        const parsed = typeof data.value === 'string' ? JSON.parse(data.value) : data.value;
        setSystemSettings({
          price_cop: parsed.price ?? 100000,
          support_whatsapp: parsed.support_whatsapp ?? '+573000000000',
          free_trial_days: parsed.trial_days ?? 30,
          grace_days: parsed.grace_days ?? 3,
          support_email: parsed.support_email ?? 'soporte@fishbit.co'
        });
      }
    } catch (err) {
      console.error("Error fetching global settings:", err);
    }
  }, []);

  const saveGlobalSettings = async (updatedSettings = systemSettings) => {
    const savePromise = async () => {
      const payload = {
        price: updatedSettings.price_cop,
        support_whatsapp: updatedSettings.support_whatsapp,
        trial_days: updatedSettings.free_trial_days,
        grace_days: updatedSettings.grace_days,
        support_email: updatedSettings.support_email
      };

      const { error } = await supabase
        .from('app_config')
        .upsert({
          key: 'global_settings',
          value: payload
        });

      if (error) throw error;
    };

    toast.promise(savePromise(), {
      loading: 'Guardando configuración global...',
      success: 'Configuración guardada correctamente.',
      error: 'Error al guardar la configuración global.',
    });
  };

  const fetchSettings = useCallback(async () => {
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

        if (t.notification_settings) {
          setNotificationSettings(prev => ({
            ...prev,
            ...t.notification_settings
          }));
        }
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
      const { data: currentData } = await supabase
        .from('unit_settings')
        .select('thresholds')
        .eq('unit_id', activeUnitId)
        .maybeSingle();

      const existingThresholds = currentData?.thresholds || {};

      const thresholdsPayload = {
        ...existingThresholds,
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

  const saveNotificationSettings = async (settingsToSave = notificationSettings) => {
    const activeUnitId = localStorage.getItem('active_unit_id');
    if (!activeUnitId) {
      toast.error("No se identificó la unidad activa.");
      return;
    }

    const savePromise = async () => {
      const { data: currentData } = await supabase
        .from('unit_settings')
        .select('thresholds')
        .eq('unit_id', activeUnitId)
        .maybeSingle();

      const existingThresholds = currentData?.thresholds || {};

      const thresholdsPayload = {
        ...existingThresholds,
        notification_settings: settingsToSave
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
      loading: 'Guardando canales de notificación...',
      success: 'Canales de notificación guardados correctamente.',
      error: 'Error al guardar los canales.',
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
          fetchGlobalSettings();
        } else if (finalRole === 'admin') {
          setActiveTab('equipo');
        } else {
          setActiveTab('parametros');
        }
      }
      setLoading(false);
    }
    checkRole();
  }, [fetchSettings, fetchGlobalSettings]);

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
                    <h2 style={{ fontSize: '1.4rem', fontWeight: 900, letterSpacing: '-0.02em', marginBottom: '0.25rem' }}>Estructura de Precios (Plan Único)</h2>
                    <p style={{ fontSize: '0.85rem', color: 'var(--muted-foreground)', fontWeight: 600 }}>Ajusta la tarifa de suscripción global para el Plan Único FishBit.</p>
                  </div>
                  <button 
                    onClick={() => saveGlobalSettings()} 
                    className="btn-primary" 
                    style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', background: '#0d9488' }}
                  >
                    <Save size={18} /> Guardar Tarifas
                  </button>
                </div>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr', gap: '2rem' }}>
                  <div className="glass" style={{ padding: '2.5rem', borderRadius: '24px', position: 'relative', overflow: 'hidden' }}>
                    <div style={{
                      position: 'absolute', top: 0, right: 0, width: '150px', height: '150px',
                      background: 'radial-gradient(circle, rgba(13, 148, 136, 0.15) 0%, transparent 70%)',
                      pointerEvents: 'none'
                    }} />
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '2rem', color: '#0d9488', flexWrap: 'wrap' }}>
                      <CreditCard size={28} /> 
                      <span style={{ fontWeight: 950, fontSize: '1.3rem', letterSpacing: '-0.02em' }}>Plan Único FishBit</span>
                      <span style={{
                        padding: '4px 12px', borderRadius: '20px', fontSize: '0.65rem', fontWeight: 900,
                        background: 'rgba(13, 148, 136, 0.1)', color: '#0d9488', textTransform: 'uppercase',
                        letterSpacing: '0.05em'
                      }}>
                        Acceso Completo Ilimitado
                      </span>
                    </div>

                    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: '2rem' }}>
                      <div style={{ display: 'flex', flexDirection: 'column', gap: '0.6rem' }}>
                        <label className="premium-label" style={{ position: 'static', fontWeight: 700 }}>Moneda Plan</label>
                        <select className="premium-input" disabled style={{ fontWeight: 800, background: 'var(--secondary)', cursor: 'not-allowed' }}>
                          <option value="COP">COP (Pesos Colombianos) - Exclusivo</option>
                        </select>
                        <span style={{ fontSize: '0.7rem', color: 'var(--muted-foreground)', fontWeight: 600 }}>De acuerdo a las reglas de negocio, solo se maneja moneda colombiana.</span>
                      </div>

                      <div style={{ display: 'flex', flexDirection: 'column', gap: '0.6rem' }}>
                        <label className="premium-label" style={{ position: 'static', fontWeight: 700 }}>Valor Mensual (COP)</label>
                        <div style={{ position: 'relative' }}>
                          <span style={{ position: 'absolute', left: '1.25rem', top: '50%', transform: 'translateY(-50%)', fontWeight: 900, color: 'var(--muted-foreground)' }}>$</span>
                          <input 
                            type="number" 
                            value={systemSettings.price_cop} 
                            onChange={e => setSystemSettings({...systemSettings, price_cop: Number(e.target.value)})} 
                            className="premium-input" 
                            style={{ paddingLeft: '2.5rem', fontSize: '1.25rem', fontWeight: 950 }} 
                          />
                        </div>
                        <span style={{ fontSize: '0.7rem', color: 'var(--muted-foreground)', fontWeight: 600 }}>Valor sugerido: $100.000 COP</span>
                      </div>
                    </div>

                    <div style={{
                      marginTop: '2.5rem', background: 'rgba(255, 255, 255, 0.02)',
                      border: '1px solid var(--border)', borderRadius: '16px', padding: '1.5rem'
                    }}>
                      <h4 style={{ fontWeight: 900, fontSize: '0.9rem', marginBottom: '0.75rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                        <Info size={16} color="#0d9488" /> Detalles del Plan
                      </h4>
                      <p style={{ fontSize: '0.85rem', color: 'var(--muted-foreground)', lineHeight: '1.5', fontWeight: 500 }}>
                        Este plan otorga acceso ilimitado a todas las herramientas de gestión acuícola: Estanques, Siembras, Parámetros Técnicos, Almacén, Finanzas y Personal. La facturación es realizada manualmente por el equipo de administración y el acceso se suspende automáticamente si el plazo expira más allá de los días de gracia permitidos.
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {isSuperAdmin && activeTab === 'general' && (
              <div>
                <div style={{ marginBottom: '2.5rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem' }}>
                  <div>
                    <h2 style={{ fontSize: '1.4rem', fontWeight: 900, letterSpacing: '-0.02em', marginBottom: '0.25rem' }}>Sistema Maestro</h2>
                    <p style={{ fontSize: '0.85rem', color: 'var(--muted-foreground)', fontWeight: 600 }}>Parámetros de soporte técnico, días de cortesía y grace periods.</p>
                  </div>
                  <button 
                    onClick={() => saveGlobalSettings()} 
                    className="btn-primary" 
                    style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', background: '#0d9488' }}
                  >
                    <Save size={18} /> Aplicar Cambios
                  </button>
                </div>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: '2rem' }}>
                  <div className="glass" style={{ padding: '1.5rem', borderRadius: '20px', display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
                    <label className="premium-label" style={{ position: 'static', fontWeight: 700 }}>WhatsApp de Soporte Central</label>
                    <input 
                      type="text" 
                      placeholder="+573000000000" 
                      value={systemSettings.support_whatsapp} 
                      onChange={e => setSystemSettings({...systemSettings, support_whatsapp: e.target.value})} 
                      className="premium-input" 
                      style={{ fontWeight: 800 }} 
                    />
                    <span style={{ fontSize: '0.7rem', color: 'var(--muted-foreground)', fontWeight: 600 }}>WhatsApp del administrador al que los clientes suspendidos contactarán. Incluir código de país.</span>
                  </div>

                  <div className="glass" style={{ padding: '1.5rem', borderRadius: '20px', display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
                    <label className="premium-label" style={{ position: 'static', fontWeight: 700 }}>Correo de Soporte Central</label>
                    <input 
                      type="email" 
                      placeholder="soporte@fishbit.co" 
                      value={systemSettings.support_email} 
                      onChange={e => setSystemSettings({...systemSettings, support_email: e.target.value})} 
                      className="premium-input" 
                      style={{ fontWeight: 800 }} 
                    />
                    <span style={{ fontSize: '0.7rem', color: 'var(--muted-foreground)', fontWeight: 600 }}>Correo electrónico secundario de soporte que se mostrará en pantalla de bloqueo.</span>
                  </div>

                  <div className="glass" style={{ padding: '1.5rem', borderRadius: '20px', display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
                    <label className="premium-label" style={{ position: 'static', fontWeight: 700 }}>Periodo de Cortesía (Días de Prueba)</label>
                    <input 
                      type="number" 
                      value={systemSettings.free_trial_days} 
                      onChange={e => setSystemSettings({...systemSettings, free_trial_days: Number(e.target.value)})} 
                      className="premium-input" 
                      style={{ fontWeight: 800 }} 
                    />
                    <span style={{ fontSize: '0.7rem', color: 'var(--muted-foreground)', fontWeight: 600 }}>Días de prueba gratis de bienvenida para nuevos clientes al iniciar.</span>
                  </div>

                  <div className="glass" style={{ padding: '1.5rem', borderRadius: '20px', display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
                    <label className="premium-label" style={{ position: 'static', fontWeight: 700 }}>Días de Gracia (Grace Period)</label>
                    <input 
                      type="number" 
                      value={systemSettings.grace_days} 
                      onChange={e => setSystemSettings({...systemSettings, grace_days: Number(e.target.value)})} 
                      className="premium-input" 
                      style={{ fontWeight: 800 }} 
                    />
                    <span style={{ fontSize: '0.7rem', color: 'var(--muted-foreground)', fontWeight: 600 }}>Días adicionales permitidos tras el vencimiento de la fecha de pago antes del bloqueo.</span>
                  </div>
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
              <div>
                <div style={{ marginBottom: '2.5rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem' }}>
                  <div>
                    <h2 style={{ fontSize: '1.4rem', fontWeight: 950, letterSpacing: '-0.03em', marginBottom: '0.25rem' }}>Canales y Alertas de Notificación</h2>
                    <p style={{ fontSize: '0.85rem', color: 'var(--muted-foreground)', fontWeight: 600 }}>Configura cómo y cuándo deseas recibir alertas críticas de tu producción.</p>
                  </div>
                  <button onClick={() => saveNotificationSettings()} className="btn-primary" style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                    <Save size={18} /> Guardar Canales
                  </button>
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))', gap: '2rem' }}>
                  
                  {/* WhatsApp Business Card */}
                  <div className="glass" style={{
                    padding: '2.5rem',
                    borderRadius: '24px',
                    border: '1px solid rgba(37, 211, 102, 0.15)',
                    position: 'relative',
                    overflow: 'hidden',
                    display: 'flex',
                    flexDirection: 'column',
                    gap: '1.5rem'
                  }}>
                    <div style={{
                      position: 'absolute', top: 0, right: 0, width: '120px', height: '120px',
                      background: 'radial-gradient(circle, rgba(37, 211, 102, 0.1) 0%, transparent 70%)',
                      pointerEvents: 'none'
                    }} />
                    
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                        <div style={{ background: 'rgba(37, 211, 102, 0.1)', color: '#25d366', padding: '0.6rem', borderRadius: '12px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                          <svg viewBox="0 0 24 24" width="22" height="22" fill="currentColor">
                            <path d="M.057 24l1.687-6.163c-1.041-1.804-1.588-3.849-1.587-5.946C.003 5.419 5.422.002 12.079.002c3.223.001 6.253 1.257 8.531 3.539 2.279 2.28 3.532 5.312 3.53 8.534-.005 6.658-5.424 12.077-12.081 12.077-2.007-.001-3.98-.502-5.733-1.45L0 24zm6.59-4.846c1.62.963 3.223 1.442 4.93 1.443 5.348 0 9.697-4.35 9.7-9.699.003-2.593-1.002-5.031-2.83-6.86C16.618 2.21 14.183 1.2 11.59 1.2 6.241 1.2 1.893 5.55 1.89 10.899c0 1.761.462 3.327 1.34 4.883l-.991 3.613 3.808-.941zm11.238-5.597c-.301-.15-1.78-.879-2.056-.979-.275-.1-.475-.15-.675.15-.2.3-.775.979-.95 1.179-.175.2-.35.225-.65.075-1.041-.521-1.745-1.004-2.434-2.185-.59-.99-.785-1.98-.95-2.18-.16-.2.13-.245.33-.445.1-.1.2-.225.3-.325.1-.1.125-.175.187-.3.063-.125.031-.24-.015-.34-.047-.1-.475-1.144-.65-1.569-.17-.412-.34-.356-.475-.362-.122-.006-.262-.007-.402-.007-.14 0-.368.053-.56.262-.193.21-.735.719-.735 1.753s.75 2.032.855 2.172c.105.14 1.474 2.25 3.57 3.153.499.215.888.343 1.192.439.502.159.96.137 1.32.083.402-.06 1.78-.727 2.03-1.429.25-.701.25-1.3.175-1.429-.075-.13-.275-.23-.575-.38z"/>
                          </svg>
                        </div>
                        <div>
                          <h3 style={{ fontSize: '1.15rem', fontWeight: 900, letterSpacing: '-0.02em', margin: 0 }}>Notificaciones WhatsApp</h3>
                          <span style={{ fontSize: '0.75rem', fontWeight: 700, color: notificationSettings.whatsapp_enabled ? '#25d366' : 'var(--muted-foreground)' }}>
                            {notificationSettings.whatsapp_enabled ? 'CONECTADO' : 'INACTIVO'}
                          </span>
                        </div>
                      </div>
                      <PremiumSwitch
                        checked={notificationSettings.whatsapp_enabled}
                        onChange={(val) => {
                          const updated = { ...notificationSettings, whatsapp_enabled: val };
                          setNotificationSettings(updated);
                          saveNotificationSettings(updated);
                        }}
                      />
                    </div>

                    <div style={{ display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
                      <label className="premium-label" style={{ position: 'static', fontWeight: 700 }}>Número Móvil de Alerta</label>
                      <div style={{ position: 'relative' }}>
                        <span style={{ position: 'absolute', left: '1.25rem', top: '50%', transform: 'translateY(-50%)', fontWeight: 800, color: 'var(--muted-foreground)' }}>🇨🇴 +57</span>
                        <input
                          type="tel"
                          placeholder="300 123 4567"
                          value={notificationSettings.whatsapp_number}
                          onChange={(e) => setNotificationSettings(prev => ({ ...prev, whatsapp_number: e.target.value }))}
                          disabled={!notificationSettings.whatsapp_enabled}
                          className="premium-input"
                          style={{
                            paddingLeft: '4.5rem',
                            fontWeight: 800,
                            background: !notificationSettings.whatsapp_enabled ? 'rgba(255, 255, 255, 0.02)' : 'transparent',
                            cursor: !notificationSettings.whatsapp_enabled ? 'not-allowed' : 'text'
                          }}
                        />
                      </div>
                      <span style={{ fontSize: '0.7rem', color: 'var(--muted-foreground)', fontWeight: 600 }}>Solo números de Colombia. Formato de 10 dígitos.</span>
                    </div>

                    <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem', marginTop: '0.5rem' }}>
                      <span style={{ fontSize: '0.75rem', fontWeight: 900, color: 'var(--muted-foreground)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Eventos a reportar</span>
                      
                      <PremiumCheckbox
                        checked={notificationSettings.whatsapp_alert_oxygen}
                        label="Oxígeno Crítico (< 4.5 mg/L)"
                        onChange={(val) => {
                          const u = { ...notificationSettings, whatsapp_alert_oxygen: val };
                          setNotificationSettings(u);
                          if (notificationSettings.whatsapp_enabled) saveNotificationSettings(u);
                        }}
                      />
                      <PremiumCheckbox
                        checked={notificationSettings.whatsapp_alert_temp}
                        label="Límites de Temperatura superados"
                        onChange={(val) => {
                          const u = { ...notificationSettings, whatsapp_alert_temp: val };
                          setNotificationSettings(u);
                          if (notificationSettings.whatsapp_enabled) saveNotificationSettings(u);
                        }}
                      />
                      <PremiumCheckbox
                        checked={notificationSettings.whatsapp_alert_mortality}
                        label="Picos inusuales de Mortalidad"
                        onChange={(val) => {
                          const u = { ...notificationSettings, whatsapp_alert_mortality: val };
                          setNotificationSettings(u);
                          if (notificationSettings.whatsapp_enabled) saveNotificationSettings(u);
                        }}
                      />
                      <PremiumCheckbox
                        checked={notificationSettings.whatsapp_alert_inventory}
                        label="Desabastecimiento de Alimento"
                        onChange={(val) => {
                          const u = { ...notificationSettings, whatsapp_alert_inventory: val };
                          setNotificationSettings(u);
                          if (notificationSettings.whatsapp_enabled) saveNotificationSettings(u);
                        }}
                      />
                    </div>
                  </div>

                  {/* Email Notifications Card */}
                  <div className="glass" style={{
                    padding: '2.5rem',
                    borderRadius: '24px',
                    border: '1px solid rgba(99, 102, 241, 0.15)',
                    position: 'relative',
                    overflow: 'hidden',
                    display: 'flex',
                    flexDirection: 'column',
                    gap: '1.5rem'
                  }}>
                    <div style={{
                      position: 'absolute', top: 0, right: 0, width: '120px', height: '120px',
                      background: 'radial-gradient(circle, rgba(99, 102, 241, 0.1) 0%, transparent 70%)',
                      pointerEvents: 'none'
                    }} />

                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                        <div style={{ background: 'rgba(99, 102, 241, 0.1)', color: '#6366f1', padding: '0.6rem', borderRadius: '12px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                          <Mail size={22} />
                        </div>
                        <div>
                          <h3 style={{ fontSize: '1.15rem', fontWeight: 900, letterSpacing: '-0.02em', margin: 0 }}>Notificaciones E-mail</h3>
                          <span style={{ fontSize: '0.75rem', fontWeight: 700, color: notificationSettings.email_enabled ? '#6366f1' : 'var(--muted-foreground)' }}>
                            {notificationSettings.email_enabled ? 'ACTIVO' : 'INACTIVO'}
                          </span>
                        </div>
                      </div>
                      <PremiumSwitch
                        checked={notificationSettings.email_enabled}
                        onChange={(val) => {
                          const updated = { ...notificationSettings, email_enabled: val };
                          setNotificationSettings(updated);
                          saveNotificationSettings(updated);
                        }}
                      />
                    </div>

                    <div style={{ display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
                      <label className="premium-label" style={{ position: 'static', fontWeight: 700 }}>Correo de Alertas</label>
                      <div style={{ position: 'relative' }}>
                        <input
                          type="email"
                          placeholder="gerencia@granja.co"
                          value={notificationSettings.email_address}
                          onChange={(e) => setNotificationSettings(prev => ({ ...prev, email_address: e.target.value }))}
                          disabled={!notificationSettings.email_enabled}
                          className="premium-input"
                          style={{
                            fontWeight: 800,
                            background: !notificationSettings.email_enabled ? 'rgba(255, 255, 255, 0.02)' : 'transparent',
                            cursor: !notificationSettings.email_enabled ? 'not-allowed' : 'text'
                          }}
                        />
                      </div>
                      <span style={{ fontSize: '0.7rem', color: 'var(--muted-foreground)', fontWeight: 600 }}>Dirección e-mail principal para informes maestros.</span>
                    </div>

                    <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem', marginTop: '0.5rem' }}>
                      <span style={{ fontSize: '0.75rem', fontWeight: 900, color: 'var(--muted-foreground)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Reportes Recurrentes</span>

                      <PremiumCheckbox
                        checked={notificationSettings.email_daily_summary}
                        label="Resumen Financiero Diario al cierre"
                        onChange={(val) => {
                          const u = { ...notificationSettings, email_daily_summary: val };
                          setNotificationSettings(u);
                          if (notificationSettings.email_enabled) saveNotificationSettings(u);
                        }}
                      />
                      <PremiumCheckbox
                        checked={notificationSettings.email_non_compliance}
                        label="Alerta de Omisión Técnica (Sin registros antes de las 18:00)"
                        onChange={(val) => {
                          const u = { ...notificationSettings, email_non_compliance: val };
                          setNotificationSettings(u);
                          if (notificationSettings.email_enabled) saveNotificationSettings(u);
                        }}
                      />
                    </div>
                  </div>

                  {/* Browser Push & API Status Card */}
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
                    
                    {/* Browser Push Card */}
                    <div className="glass" style={{
                      padding: '2.2rem',
                      borderRadius: '24px',
                      border: '1px solid rgba(255, 255, 255, 0.06)',
                      display: 'flex',
                      flexDirection: 'column',
                      gap: '1.25rem'
                    }}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                          <div style={{ background: 'rgba(255, 255, 255, 0.05)', color: 'var(--foreground)', padding: '0.6rem', borderRadius: '12px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                            <Bell size={22} />
                          </div>
                          <div>
                            <h3 style={{ fontSize: '1.15rem', fontWeight: 900, letterSpacing: '-0.02em', margin: 0 }}>Push en Navegador</h3>
                            <span style={{ fontSize: '0.75rem', fontWeight: 700, color: notificationSettings.push_enabled ? 'var(--primary)' : 'var(--muted-foreground)' }}>
                              {notificationSettings.push_enabled ? 'Suscrito' : 'Inactivo'}
                            </span>
                          </div>
                        </div>
                        <PremiumSwitch
                          checked={notificationSettings.push_enabled}
                          onChange={(val) => {
                            const updated = { ...notificationSettings, push_enabled: val };
                            setNotificationSettings(updated);
                            saveNotificationSettings(updated);
                            if (val) {
                              toast.success("¡Permiso de notificaciones push concedido!");
                            }
                          }}
                        />
                      </div>
                      
                      {notificationSettings.push_enabled && (
                        <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem', marginTop: '0.25rem' }}>
                          <span style={{ fontSize: '0.75rem', fontWeight: 900, color: 'var(--muted-foreground)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Frecuencia de Notificaciones</span>
                          <div style={{ display: 'flex', gap: '1rem' }}>
                            <button
                              type="button"
                              onClick={() => {
                                const u = { ...notificationSettings, push_frequency: 'instant' };
                                setNotificationSettings(u);
                                saveNotificationSettings(u);
                              }}
                              style={{
                                flex: 1,
                                padding: '0.6rem',
                                borderRadius: '10px',
                                background: notificationSettings.push_frequency === 'instant' ? 'rgba(37, 99, 235, 0.1)' : 'transparent',
                                border: notificationSettings.push_frequency === 'instant' ? '1px solid var(--primary)' : '1px solid var(--border)',
                                color: notificationSettings.push_frequency === 'instant' ? 'var(--primary)' : 'var(--muted-foreground)',
                                fontWeight: 800,
                                cursor: 'pointer',
                                fontSize: '0.75rem',
                                transition: 'all 0.2s',
                                paddingLeft: 0,
                                paddingRight: 0
                              }}
                            >
                              Instantáneas
                            </button>
                            <button
                              type="button"
                              onClick={() => {
                                const u = { ...notificationSettings, push_frequency: 'digest' };
                                setNotificationSettings(u);
                                saveNotificationSettings(u);
                              }}
                              style={{
                                flex: 1,
                                padding: '0.6rem',
                                borderRadius: '10px',
                                background: notificationSettings.push_frequency === 'digest' ? 'rgba(37, 99, 235, 0.1)' : 'transparent',
                                border: notificationSettings.push_frequency === 'digest' ? '1px solid var(--primary)' : '1px solid var(--border)',
                                color: notificationSettings.push_frequency === 'digest' ? 'var(--primary)' : 'var(--muted-foreground)',
                                fontWeight: 800,
                                cursor: 'pointer',
                                fontSize: '0.75rem',
                                transition: 'all 0.2s',
                                paddingLeft: 0,
                                paddingRight: 0
                              }}
                            >
                              Resumen Diario
                            </button>
                          </div>
                        </div>
                      )}
                    </div>

                    {/* Gateway Status Card */}
                    <div className="glass" style={{
                      padding: '2.2rem',
                      borderRadius: '24px',
                      border: '1px solid rgba(255, 255, 255, 0.06)',
                      background: 'linear-gradient(135deg, rgba(13, 148, 136, 0.05) 0%, rgba(2, 6, 23, 0.4) 100%)',
                      display: 'flex',
                      flexDirection: 'column',
                      gap: '1rem'
                    }}>
                      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                        <span style={{ fontSize: '0.75rem', fontWeight: 900, color: 'var(--muted-foreground)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Pasarela de Notificaciones</span>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
                          <div style={{ width: '8px', height: '8px', borderRadius: '50%', background: '#10b981', boxShadow: '0 0 8px #10b981' }} />
                          <span style={{ fontSize: '0.65rem', fontWeight: 900, color: '#10b981' }}>ONLINE</span>
                        </div>
                      </div>
                      
                      <div style={{ display: 'flex', flexDirection: 'column', gap: '0.3rem' }}>
                        <span style={{ fontSize: '0.75rem', color: 'var(--muted-foreground)', fontWeight: 600 }}>API Endpoint:</span>
                        <code style={{ fontSize: '0.7rem', padding: '0.4rem 0.6rem', borderRadius: '8px', background: 'rgba(0,0,0,0.3)', color: 'var(--primary)', fontFamily: 'monospace', fontWeight: 700, wordBreak: 'break-all' }}>
                          https://api.fishbit.co/v1/notifications
                        </code>
                      </div>

                      <p style={{ fontSize: '0.75rem', color: 'var(--muted-foreground)', lineHeight: '1.4', margin: 0, fontWeight: 500 }}>
                        Conectado a la pasarela distribuida de FishBit. Garantiza una entrega de alertas de parámetros en menos de 5 segundos tras registrarse una medición fuera de rango.
                      </p>
                    </div>

                  </div>

                </div>
              </div>
            )}
          </motion.div>
        </AnimatePresence>
      </div>
    </div>
  );
}

// --- Dynamic Notification Components ---

const PremiumSwitch = ({ checked, onChange }: { checked: boolean, onChange: (val: boolean) => void }) => {
  return (
    <button
      type="button"
      onClick={() => onChange(!checked)}
      style={{
        width: '50px',
        height: '26px',
        borderRadius: '999px',
        background: checked ? 'var(--primary)' : 'rgba(255, 255, 255, 0.1)',
        border: '1px solid rgba(255, 255, 255, 0.08)',
        position: 'relative',
        cursor: 'pointer',
        transition: 'background 0.3s ease',
        padding: 0,
        display: 'flex',
        alignItems: 'center'
      }}
    >
      <motion.div
        animate={{ x: checked ? 25 : 3 }}
        transition={{ type: 'spring', stiffness: 500, damping: 30 }}
        style={{
          width: '18px',
          height: '18px',
          borderRadius: '50%',
          background: 'white',
          boxShadow: '0 2px 4px rgba(0,0,0,0.2)'
        }}
      />
    </button>
  );
};

const PremiumCheckbox = ({ checked, label, onChange }: { checked: boolean, label: string, onChange: (val: boolean) => void }) => {
  return (
    <label style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', cursor: 'pointer', userSelect: 'none', margin: '0.4rem 0' }}>
      <button
        type="button"
        onClick={() => onChange(!checked)}
        style={{
          width: '20px',
          height: '20px',
          borderRadius: '6px',
          background: checked ? 'var(--primary)' : 'rgba(255, 255, 255, 0.05)',
          border: checked ? '1px solid var(--primary)' : '1px solid rgba(255, 255, 255, 0.1)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          color: 'white',
          cursor: 'pointer',
          padding: 0
        }}
      >
        {checked && <span style={{ fontSize: '0.65rem', fontWeight: 900 }}>✓</span>}
      </button>
      <span style={{ fontSize: '0.85rem', fontWeight: 600, color: checked ? 'var(--foreground)' : 'var(--muted-foreground)', transition: 'color 0.2s' }}>
        {label}
      </span>
    </label>
  );
};

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
      let activeUnitId = localStorage.getItem('active_unit_id');
      if (!activeUnitId) throw new Error("Unidad no identificada.");

      const response = await fetch('/api/users', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: inviteData.email,
          fullName: inviteData.fullName,
          role: inviteData.role,
          unitId: activeUnitId
        })
      });

      const res = await response.json();
      if (!response.ok || res.error) {
        throw new Error(res.error || 'Error al invitar miembro');
      }

      const generatedPassword = res.password;
      if (generatedPassword) {
        try {
          await navigator.clipboard.writeText(generatedPassword);
          toast.success(`Contraseña temporal copiada al portapapeles: ${generatedPassword}`, { duration: 10000 });
        } catch {
          alert(`Miembro creado. Contraseña temporal: ${generatedPassword}\n\nPor favor, cópiala ahora.`);
        }
      }

      setShowInviteModal(false);
      setInviteData({ email: '', fullName: '', role: 'tecnico' });
      fetchTeam(true);
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
              background: 'rgba(13, 148, 136, 0.1)',
              color: '#0d9488',
              textTransform: 'uppercase',
              letterSpacing: '0.05em'
            }}>
              Plan Único: Ilimitado
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
