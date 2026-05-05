'use client';

import { useEffect, useState, useCallback } from 'react';
import { motion } from 'framer-motion';
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
  RefreshCw
} from 'lucide-react';
import { supabase } from '@/lib/supabase';

export default function ConfiguracionPage() {
  const [userRole, setUserRole] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState('parametros');
  const [isSuperAdmin, setIsSuperAdmin] = useState(false);
  const [loading, setLoading] = useState(true);
  const [prices, setPrices] = useState({ basic: 18, premium: 30 });

  useEffect(() => {
    async function checkRole() {
      const { data: { user } } = await supabase.auth.getUser();
      if (user) {
        // 1. Verificar si es SuperAdmin
        const { data: profile } = await supabase
          .from('profiles')
          .select('is_superadmin, role')
          .eq('id', user.id)
          .single();
        
        const superStatus = profile?.is_superadmin || false;
        setIsSuperAdmin(superStatus);

        // 2. Obtener rol de la unidad
        const { data: userUnit } = await supabase
          .from('user_units')
          .select('role')
          .eq('user_id', user.id)
          .limit(1)
          .single();

        const finalRole = userUnit?.role || profile?.role || 'operario';
        setUserRole(finalRole);

        // Redirección inicial basada en rol
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
  }, []);

  // ASIGNACIÓN DE VISTAS POR ROL
  const getTabs = () => {
    if (isSuperAdmin) {
      return [
        { id: 'negocio', label: 'Tarifas y Planes', icon: DollarSign },
        { id: 'general', label: 'Sistema', icon: Settings },
      ];
    }

    const baseTabs = [
      { id: 'parametros', label: 'Límites de Alerta', icon: Activity },
      { id: 'notificaciones', label: 'Notificaciones', icon: Bell },
    ];

    if (userRole === 'admin') {
      baseTabs.push({ id: 'equipo', label: 'Gestión de Equipo', icon: Users });
    }

    // El Operario solo ve parámetros (lectura)
    if (userRole === 'operario') {
      return [{ id: 'parametros', label: 'Estado de Alertas', icon: Activity }];
    }

    return baseTabs;
  };

  const tabs = getTabs();

  if (loading) return <div style={{ padding: '2rem', textAlign: 'center' }}>Cargando configuración...</div>;

  const inputStyle = { width: '100%', padding: '0.625rem', borderRadius: '8px', border: '1px solid var(--border)', background: 'var(--secondary)', outline: 'none' };

  return (
    <div className="animate-fade-in">
      <header style={{ marginBottom: '2.5rem' }}>
        <h1 style={{ fontSize: '1.875rem', fontWeight: 700, marginBottom: '0.5rem' }}>
          {isSuperAdmin ? 'Configuración de Negocio' : 'Configuración'}
        </h1>
        <p style={{ color: 'var(--muted-foreground)' }}>
          {isSuperAdmin 
            ? 'Administra los precios de los planes y parámetros globales de la plataforma.' 
            : 'Personaliza el comportamiento y los parámetros técnicos de FishBit.'}
        </p>
      </header>

      <div style={{ display: 'flex', gap: '0.5rem', marginBottom: '2rem', borderBottom: '1px solid var(--border)', paddingBottom: '0.5rem' }}>
        {tabs.map(tab => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id)}
            style={{
              padding: '0.75rem 1.25rem',
              borderRadius: '8px',
              background: activeTab === tab.id ? 'var(--secondary)' : 'transparent',
              color: activeTab === tab.id ? 'var(--primary)' : 'var(--muted-foreground)',
              border: 'none',
              cursor: 'pointer',
              fontWeight: 600,
              display: 'flex',
              alignItems: 'center',
              gap: '0.625rem',
              transition: 'all 0.2s ease'
            }}
          >
            <tab.icon size={18} />
            {tab.label}
          </button>
        ))}
      </div>

      <div className="card-premium" style={{ padding: '2rem', background: 'var(--card)' }}>
        {isSuperAdmin && activeTab === 'negocio' && (
          <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }}>
            <div style={{ marginBottom: '2rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div>
                <h2 style={{ fontSize: '1.25rem', fontWeight: 700, marginBottom: '0.25rem' }}>Ajuste de Precios de Planes</h2>
                <p style={{ fontSize: '0.875rem', color: 'var(--muted-foreground)' }}>Define cuánto cobrarás por cada nivel de servicio.</p>
              </div>
              <button className="btn-primary" style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}><Save size={18} /> Guardar Tarifas</button>
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: '1.5rem' }}>
              <PriceCard title="Plan Básico" icon={CreditCard} value={prices.basic} onChange={(v: number) => setPrices({...prices, basic: v})} />
              <PriceCard title="Plan Premium" icon={DollarSign} value={prices.premium} onChange={(v: number) => setPrices({...prices, premium: v})} color="#f59e0b" />
            </div>
          </motion.div>
        )}

        {isSuperAdmin && activeTab === 'general' && (
          <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }}>
            <div style={{ marginBottom: '2rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div>
                <h2 style={{ fontSize: '1.25rem', fontWeight: 700, marginBottom: '0.25rem' }}>Parámetros del Sistema</h2>
                <p style={{ fontSize: '0.875rem', color: 'var(--muted-foreground)' }}>Configura las reglas globales de FishBit.</p>
              </div>
              <button className="btn-primary" style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}><Save size={18} /> Guardar Configuración</button>
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: '1.5rem' }}>
              <SystemInput label="Moneda Principal" type="select" options={['COP', 'USD']} />
              <SystemInput label="WhatsApp de Soporte" type="text" placeholder="+57 300 000 0000" />
              <SystemInput label="Días de Gracia" type="number" defaultValue="3" />
            </div>
          </motion.div>
        )}

        {!isSuperAdmin && activeTab === 'parametros' && (
          <motion.div initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }}>
            <div style={{ marginBottom: '2rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div>
                <h2 style={{ fontSize: '1.25rem', fontWeight: 700, marginBottom: '0.25rem' }}>Rangos Óptimos de Calidad de Agua</h2>
                <p style={{ fontSize: '0.875rem', color: 'var(--muted-foreground)' }}>Define los límites técnicos de tu granja.</p>
              </div>
              <button className="btn-primary" style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}><Save size={18} /> Guardar Cambios</button>
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))', gap: '1.5rem' }}>
              <ParamInput label="Oxígeno Disuelto (mg/L)" icon={Wind} color="#3b82f6" min="4.5" max="9.0" />
              <ParamInput label="Temperatura (°C)" icon={Thermometer} color="#ef4444" min="26.0" max="31.0" />
            </div>
          </motion.div>
        )}

        {!isSuperAdmin && activeTab === 'equipo' && <TeamManagement />}

        {(activeTab === 'notificaciones') && (
          <div style={{ padding: '4rem 2rem', textAlign: 'center', color: 'var(--muted-foreground)' }}>
            <p>Sección de configuración adicional en desarrollo...</p>
          </div>
        )}
      </div>
    </div>
  );
}

const PriceCard = ({ title, icon: Icon, value, onChange, color }: any) => (
  <div style={{ padding: '1.5rem', borderRadius: '16px', border: '1px solid var(--border)', background: 'var(--secondary)' }}>
    <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '1.25rem', color: color || 'var(--primary)' }}>
      <Icon size={20} /> <span style={{ fontWeight: 800 }}>{title}</span>
    </div>
    <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 800, color: 'var(--muted-foreground)', marginBottom: '0.5rem', textTransform: 'uppercase' }}>Precio Mensual (USD)</label>
    <div style={{ position: 'relative' }}>
      <span style={{ position: 'absolute', left: '1rem', top: '50%', transform: 'translateY(-50%)', fontWeight: 700, color: 'var(--muted-foreground)' }}>$</span>
      <input type="number" value={value} onChange={e => onChange(Number(e.target.value))} style={{ width: '100%', padding: '0.75rem 0.75rem 0.75rem 2rem', borderRadius: '10px', border: '1px solid var(--border)', background: 'var(--card)', outline: 'none', fontWeight: 800, fontSize: '1.1rem' }} />
    </div>
  </div>
);

const SystemInput = ({ label, type, options, placeholder, defaultValue }: any) => (
  <div style={{ padding: '1.5rem', borderRadius: '16px', border: '1px solid var(--border)', background: 'var(--secondary)' }}>
    <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 800, color: 'var(--muted-foreground)', marginBottom: '0.5rem', textTransform: 'uppercase' }}>{label}</label>
    {type === 'select' ? (
      <select style={{ width: '100%', padding: '0.75rem', borderRadius: '10px', border: '1px solid var(--border)', background: 'var(--card)', outline: 'none', fontWeight: 600 }}>
        {options.map((o: any) => <option key={o} value={o}>{o}</option>)}
      </select>
    ) : (
      <input type={type} placeholder={placeholder} defaultValue={defaultValue} style={{ width: '100%', padding: '0.75rem', borderRadius: '10px', border: '1px solid var(--border)', background: 'var(--card)', outline: 'none', fontWeight: 600 }} />
    )}
  </div>
);

const ParamInput = ({ label, icon: Icon, color, min, max }: any) => (
  <div style={{ padding: '1.5rem', borderRadius: '12px', border: '1px solid var(--border)', background: `${color}05` }}>
    <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '1.25rem', color }}>
      <Icon size={20} /> <span style={{ fontWeight: 700 }}>{label}</span>
    </div>
    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
      <input type="number" defaultValue={min} style={{ width: '100%', padding: '0.625rem', borderRadius: '8px', border: '1px solid var(--border)', background: 'var(--secondary)', outline: 'none' }} />
      <input type="number" defaultValue={max} style={{ width: '100%', padding: '0.625rem', borderRadius: '8px', border: '1px solid var(--border)', background: 'var(--secondary)', outline: 'none' }} />
    </div>
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

      // --- AUTO-REPARACIÓN PARA EL ADMIN ---
      // Si el Admin logueado no tiene email en su perfil, lo guardamos ahora
      const { data: myProfile } = await supabase.from('profiles').select('email').eq('id', user.id).single();
      if (myProfile && !myProfile.email && user.email) {
        await supabase.from('profiles').update({ email: user.email }).eq('id', user.id);
      }
      // -------------------------------------

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

      // Carga paralela para máxima velocidad
      const [subRes, uuRes] = await Promise.all([
        supabase.from('subscriptions').select('plan_type').eq('unit_id', activeUnitId).single(),
        supabase.from('user_units').select('user_id, role').eq('unit_id', activeUnitId)
      ]);

      if (subRes.data) setPlanType(subRes.data.plan_type);
      if (uuRes.error) throw uuRes.error;

      const userUnits = uuRes.data || [];

      if (!userUnits || userUnits.length === 0) {
        setMembers([]);
        return;
      }

      const userIds = userUnits.map(uu => uu.user_id);
      const { data: profiles, error: pError } = await supabase
        .from('profiles')
        .select('*')
        .in('id', userIds);

      if (pError) console.error("Error al cargar perfiles (Posible RLS):", pError);

      // Procesamiento blindado contra nulos y variantes de columnas
      const processedMembers = userUnits.map((uu: any) => {
        const profile = profiles?.find(p => p.id === uu.user_id) || {};
        return {
          ...profile,
          id: uu.user_id,
          full_name: profile.full_name || profile.nombre || (uu.role === 'admin' ? 'Administrador' : 'Miembro Invitado'),
          email: profile.email || profile.correo || profile.mail || 'Pendiente de registro',
          role: uu.role || profile.role || 'operario',
          isGhost: !profile.id
        };
      });

      setMembers(processedMembers);
    } catch (err: any) { 
      console.error("Error en Auditoría de Equipo:", err.message); 
    } finally { 
      setLoading(false); 
      setRefreshing(false);
    }
  }, []);

  const handleRepairProfile = async (member: any) => {
    const name = prompt("Corregir Nombre:", member.full_name === 'Miembro Invitado' ? '' : member.full_name);
    const email = prompt("Corregir Correo:", member.email.includes('N/A') || member.email.includes('Pendiente') ? '' : member.email);
    
    if (name && email) {
      setRefreshing(true);
      try {
        const { error } = await supabase.from('profiles').upsert({
          id: member.id,
          full_name: name,
          email: email,
          role: member.role,
          is_superadmin: false
        }, { onConflict: 'id' });

        if (error) {
          if (error.message.includes('schema cache')) {
            alert("Base de datos actualizada. Por favor, recarga la página completa (F5) para que el sistema reconozca los nuevos cambios.");
          } else {
            throw error;
          }
        } else {
          alert("¡Perfil actualizado con éxito!");
          window.location.reload(); // Forzar recarga para limpiar caché de esquema
        }
      } catch (err: any) {
        alert("Error al actualizar: " + err.message);
      } finally {
        setRefreshing(false);
      }
    }
  };

  useEffect(() => {
    fetchTeam();
    
    const activeUnitId = localStorage.getItem('active_unit_id');
    if (!activeUnitId) return;

    // Sincronización en tiempo real para actualizaciones instantáneas
    const channel = supabase.channel(`team_sync_${activeUnitId}`)
      .on('postgres_changes', { 
        event: '*', 
        schema: 'public', 
        table: 'user_units', 
        filter: `unit_id=eq.${activeUnitId}` 
      }, () => fetchTeam(true))
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [fetchTeam]);

  const handleInvite = async (e: React.FormEvent) => {
    e.preventDefault();
    setInviting(true);
    try {
      if (planType === 'basic') {
        const countByRole = members.filter(m => m.role === inviteData.role).length;
        if (countByRole >= 1) { 
          alert(`🚫 LÍMITE DE PLAN BÁSICO:\n\nTu plan actual solo permite 1 usuario de tipo ${inviteData.role.toUpperCase()}.\n\nPara gestionar un equipo más grande e invitar a múltiples técnicos y operarios, por favor contacta a soporte para activar tu PLAN PREMIUM.`); 
          return; 
        }
      }
      let activeUnitId = localStorage.getItem('active_unit_id');
      
      // Fallback para obtener la unidad si no está en localStorage
      if (!activeUnitId) {
        const { data: { user: currentUser } } = await supabase.auth.getUser();
        if (currentUser) {
          const { data: uu } = await supabase.from('user_units').select('unit_id').eq('user_id', currentUser.id).limit(1).single();
          if (uu) activeUnitId = uu.unit_id;
        }
      }

      if (!activeUnitId) {
        alert("Error: No se pudo determinar tu unidad de producción. Por favor, vuelve al Dashboard e intenta de nuevo.");
        return;
      }

      // Registro en Auth
      const { data, error: authError } = await supabase.auth.signUp({ 
        email: inviteData.email, 
        password: 'FishBit2026!', 
        options: { data: { full_name: inviteData.fullName } } 
      });

      if (authError) throw authError;

      if (data.user) {
        // 1. Crear Perfil
        const { error: pError } = await supabase.from('profiles').insert([{ 
          id: data.user.id, 
          full_name: inviteData.fullName, 
          email: inviteData.email, 
          role: inviteData.role, 
          is_superadmin: false 
        }]);
        if (pError) console.warn("Aviso: El perfil podría requerir permisos RLS adicionales:", pError.message);

        // 2. Vincular a Unidad (CRÍTICO)
        const { error: uuError } = await supabase.from('user_units').insert([{ 
          user_id: data.user.id, 
          unit_id: activeUnitId,
          role: inviteData.role 
        }]);
        
        if (uuError) {
          alert("Error al vincular el usuario a la granja: " + uuError.message);
          return;
        }

        alert(`¡Invitación Exitosa para ${inviteData.fullName}!\n\nDatos de acceso:\nCorreo: ${inviteData.email}\nClave: FishBit2026!\n\nYa puedes ver al nuevo miembro en la lista.`);
        setShowInviteModal(false);
        setInviteData({ email: '', fullName: '', role: 'tecnico' });
        fetchTeam(true);
      }
    } catch (err: any) { alert(err.message); } finally { setInviting(false); }
  };

  const handleDelete = async (userId: string) => {
    if (!confirm("¿Estás seguro de eliminar a este miembro?")) return;
    setRefreshing(true);
    try {
      const activeUnitId = localStorage.getItem('active_unit_id');
      await supabase.from('user_units').delete().eq('user_id', userId).eq('unit_id', activeUnitId);
      fetchTeam(true);
    } catch (err) { alert("Error al eliminar"); setRefreshing(false); }
  };

  const handleUpdateRole = async (userId: string, newRole: string) => {
    setRefreshing(true);
    try {
      await supabase.from('profiles').update({ role: newRole }).eq('id', userId);
      fetchTeam(true);
    } catch (err) { alert("Error al cambiar rol"); setRefreshing(false); }
  };

  if (loading) return <div style={{ padding: '2rem', textAlign: 'center' }}>Cargando equipo...</div>;

  return (
    <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2.5rem' }}>
        <div>
          <h2 style={{ fontSize: '1.25rem', fontWeight: 800 }}>Gestión de Personal</h2>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginTop: '0.25rem' }}>
            <span style={{ 
              padding: '2px 8px', 
              borderRadius: '20px', 
              fontSize: '0.65rem', 
              fontWeight: 900, 
              background: planType === 'premium' ? 'rgba(245, 158, 11, 0.1)' : 'rgba(37, 99, 235, 0.1)',
              color: planType === 'premium' ? '#d97706' : 'var(--primary)',
              border: planType === 'premium' ? '1px solid rgba(245, 158, 11, 0.3)' : '1px solid rgba(37, 99, 235, 0.3)',
              textTransform: 'uppercase'
            }}>
              {planType === 'premium' ? 'Plan Premium: Ilimitado' : 'Plan Básico: 1 por rol'}
            </span>
          </div>
        </div>
        <div style={{ display: 'flex', gap: '0.75rem' }}>
          <button 
            onClick={() => fetchTeam(true)} 
            disabled={refreshing}
            style={{ padding: '0.75rem', borderRadius: '12px', border: '1px solid var(--border)', background: 'var(--secondary)', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }}
            title="Actualizar lista"
          >
            <RefreshCw size={18} className={refreshing ? 'animate-spin' : ''} />
          </button>
          <button onClick={() => setShowInviteModal(true)} className="btn-primary" style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}><Users size={18} /> Invitar</button>
        </div>
      </div>
      
      <div style={{ display: 'grid', gap: '1rem', opacity: refreshing ? 0.6 : 1, transition: 'opacity 0.2s' }}>
        {members.map(member => (
          <div key={member.id} className="card-premium" style={{ display: 'flex', alignItems: 'center', gap: '1.5rem', padding: '1.25rem', background: 'var(--secondary)', border: '1px solid var(--border)' }}>
            <div style={{ width: '48px', height: '48px', borderRadius: '16px', background: 'var(--card)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--primary)' }}><UserCircle size={24} /></div>
            <div style={{ flex: 1 }}>
              <div style={{ fontWeight: 800, display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                {member.full_name}
                {member.isGhost && (
                  <button 
                    onClick={() => handleRepairProfile(member)} 
                    style={{ color: '#f59e0b', background: 'none', border: 'none', cursor: 'pointer', display: 'flex' }} 
                    title="Completar perfil (Faltan datos)"
                  >
                    <Info size={14} />
                  </button>
                )}
              </div>
              <div style={{ fontSize: '0.8rem', color: 'var(--muted-foreground)' }}><Mail size={12} /> {member.email}</div>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
              {member.role !== 'admin' ? (
                <select value={member.role} onChange={(e: React.ChangeEvent<HTMLSelectElement>) => handleUpdateRole(member.id, e.target.value)} style={{ padding: '0.4rem', borderRadius: '8px', background: 'var(--card)', fontSize: '0.75rem', fontWeight: 700, outline: 'none', cursor: 'pointer' }}>
                  <option value="tecnico">Técnico</option>
                  <option value="operario">Operario</option>
                </select>
              ) : <div style={{ padding: '0.4rem 1rem', borderRadius: '8px', background: 'var(--primary)', color: 'white', fontSize: '0.7rem', fontWeight: 800 }}>ADMIN</div>}
              {member.role !== 'admin' && <button onClick={() => handleDelete(member.id)} style={{ color: '#ef4444', background: 'none', border: 'none', cursor: 'pointer' }}><Trash2 size={18} /></button>}
            </div>
          </div>
        ))}
      </div>
      {showInviteModal && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(15,23,42,0.4)', backdropFilter: 'blur(10px)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000 }}>
          <div className="card-premium" style={{ width: '100%', maxWidth: '420px', padding: '2.5rem' }}>
            <h3 style={{ fontWeight: 900, fontSize: '1.5rem', marginBottom: '1.5rem' }}>Nuevo Miembro</h3>
            <form onSubmit={handleInvite} style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
              <InputGroup label="Nombre" placeholder="Nombre completo" value={inviteData.fullName} onChange={(v:any) => setInviteData({...inviteData, fullName: v})} />
              <InputGroup label="Email" placeholder="correo@ejemplo.com" value={inviteData.email} onChange={(v:any) => setInviteData({...inviteData, email: v})} />
              <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                <label style={{ fontSize: '0.75rem', fontWeight: 900, textTransform: 'uppercase' }}>Rol</label>
                <select value={inviteData.role} onChange={(e: React.ChangeEvent<HTMLSelectElement>) => setInviteData({...inviteData, role: e.target.value})} style={{ width: '100%', padding: '0.875rem', borderRadius: '12px', background: 'var(--secondary)', outline: 'none', fontWeight: 600 }}>
                  <option value="tecnico">Técnico</option>
                  <option value="operario">Operario</option>
                </select>
              </div>
              <div style={{ display: 'flex', gap: '1rem', marginTop: '1rem' }}>
                <button type="button" onClick={() => setShowInviteModal(false)} style={{ flex: 1, padding: '0.875rem', borderRadius: '12px', border: '1px solid var(--border)', background: 'none' }}>Cancelar</button>
                <button type="submit" disabled={inviting} className="btn-primary" style={{ flex: 1 }}>Invitar</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </motion.div>
  );
};

const InputGroup = ({ label, placeholder, value, onChange }: any) => (
  <div style={{ display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
    <label style={{ fontSize: '0.75rem', fontWeight: 900, color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>{label}</label>
    <input required placeholder={placeholder} value={value} onChange={e => onChange(e.target.value)} style={{ width: '100%', padding: '0.75rem', borderRadius: '10px', border: '1px solid var(--border)', background: 'var(--secondary)', outline: 'none' }} />
  </div>
);
