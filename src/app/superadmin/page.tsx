'use client';

import { useState, useEffect, useMemo, useCallback } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { supabase } from '@/lib/supabase';
import { 
  Shield, 
  Plus, 
  Users, 
  LayoutDashboard, 
  Settings, 
  ArrowRight,
  Database,
  Search,
  CheckCircle2,
  AlertCircle,
  Loader2,
  Globe,
  Navigation,
  CreditCard,
  MessageSquare,
  TrendingUp,
  DollarSign,
  Flag,
  X,
  Trash2,
  ChevronRight,
  UserPlus
} from 'lucide-react';
import { useSearchParams } from 'next/navigation';

type Tab = 'overview' | 'units' | 'clients' | 'billing' | 'support';

export default function SuperAdminHub() {
  const searchParams = useSearchParams();
  const initialTab = (searchParams.get('tab') as Tab) || 'overview';
  
  // State
  const [activeTab, setActiveTab] = useState<Tab>(initialTab);
  const [loading, setLoading] = useState(true);
  const [units, setUnits] = useState<any[]>([]);
  const [profiles, setProfiles] = useState<any[]>([]);
  const [totalRevenue, setTotalRevenue] = useState(0);
  const [subscriptions, setSubscriptions] = useState<any[]>([]);
  const [tickets, setTickets] = useState<any[]>([]);
  
  // Modal States
  const [isUnitModalOpen, setIsUnitModalOpen] = useState(false);
  const [isUserModalOpen, setIsUserModalOpen] = useState(false);
  const [isAssignModalOpen, setIsAssignModalOpen] = useState(false);
  
  // Form States
  const [selectedUser, setSelectedUser] = useState<any>(null);
  const [selectedUnitId, setSelectedUnitId] = useState('');
  const [selectedRole, setSelectedRole] = useState('admin');
  const [newUnit, setNewUnit] = useState({ name: '', location: '' });
  const [newUser, setNewUser] = useState({ email: '', password: '', fullName: '' });


  const fetchAllData = useCallback(async () => {
    setLoading(true);
    try {
      const results = await Promise.allSettled([
        supabase.from('units').select('*'),
        supabase.from('profiles').select('*'),
        supabase.from('user_units').select('*'),
        supabase.from('subscriptions').select('*'),
        supabase.from('support_tickets').select('*')
      ]);

      const unitsData = (results[0].status === 'fulfilled' ? results[0].value.data : []) || [];
      const profilesData = (results[1].status === 'fulfilled' ? results[1].value.data : []) || [];
      const uuData = (results[2].status === 'fulfilled' ? results[2].value.data : []) || [];
      const subsData = (results[3].status === 'fulfilled' ? results[3].value.data : []) || [];
      const ticketsData = (results[4].status === 'fulfilled' ? results[4].value.data : []) || [];

      // Mapeo inteligente en el frontend
      const processedProfiles = profilesData.map(p => ({
        ...p,
        user_units: uuData.filter(uu => uu.user_id === p.id).map(uu => ({
          ...uu,
          units: unitsData.find(u => u.id === uu.unit_id) || { name: 'Unidad Desconocida' }
        }))
      }));

      const processedUnits = unitsData.map(u => ({
        ...u,
        subscriptions: subsData.filter(s => s.unit_id === u.id),
        user_units: [{ count: uuData.filter(uu => uu.unit_id === u.id).length }]
      }));

      const processedSubs = unitsData.map(u => {
        const sub = subsData.find(s => s.unit_id === u.id);
        const unitAdminRelation = uuData.find(uu => uu.unit_id === u.id && uu.role === 'admin');
        const adminProfile = profilesData.find(p => p.id === unitAdminRelation?.user_id);
        
        return {
          id: sub?.id || `temp-${u.id}`,
          unit_id: u.id,
          units: u,
          plan_type: sub?.plan_type || 'Sin Plan',
          status: sub?.status || 'inactive',
          next_billing_date: sub?.next_billing_date || new Date().toISOString(),
          client_name: adminProfile?.full_name || 'Sin asignar'
        };
      });

      const processedTickets = ticketsData.map(t => ({
        ...t,
        profiles: profilesData.find(p => p.id === t.user_id) || { full_name: 'Usuario' }
      }));

      setUnits(processedUnits);
      setProfiles(processedProfiles);
      setSubscriptions(processedSubs);
      setTickets(processedTickets);
    } catch (err) {
      console.error("Error en auditoría de datos:", err);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    const tab = searchParams.get('tab') as Tab;
    if (tab) setActiveTab(tab);
    fetchAllData();
  }, [searchParams, fetchAllData]);

  // Handlers
  const handleCreateUnit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const { data, error } = await supabase.from('units').insert([newUnit]).select().single();
      if (error) throw error;
      
      // Auto-suscripción
      await supabase.from('subscriptions').insert([{
        unit_id: data.id,
        plan_type: 'basic',
        status: 'active',
        price: 18,
        next_billing_date: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString()
      }]);

      setIsUnitModalOpen(false);
      setNewUnit({ name: '', location: '' });
      fetchAllData();
      alert("Unidad creada y suscrita al Plan Básico.");
    } catch (err: any) {
      alert("Error: " + err.message);
    }
  };

  const handleCreateUser = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const { data, error } = await supabase.auth.signUp({
        email: newUser.email,
        password: newUser.password,
        options: { data: { full_name: newUser.fullName } }
      });
      if (error) throw error;

      if (data.user) {
        await supabase.from('profiles').insert([{
          id: data.user.id,
          full_name: newUser.fullName,
          email: newUser.email,
          is_superadmin: false
        }]);
      }

      setIsUserModalOpen(false);
      setNewUser({ email: '', password: '', fullName: '' });
      fetchAllData();
      alert("Cliente registrado. Su perfil ha sido creado.");
    } catch (err: any) {
      alert("Error al registrar: " + err.message);
    }
  };

  const handleAssignUnit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedUser || !selectedUnitId) return;
    try {
      const { error } = await supabase.from('user_units').insert([{
        user_id: selectedUser.id,
        unit_id: selectedUnitId,
        role: selectedRole
      }]);
      if (error) throw error;
      setIsAssignModalOpen(false);
      fetchAllData();
      alert(`Asignación completada para ${selectedUser.full_name}`);
    } catch (err: any) {
      alert("Error: " + err.message);
    }
  };

  const handleDeleteUser = async (id: string) => {
    if (!confirm("¿Eliminar usuario? Esta acción borrará su perfil y asignaciones.")) return;
    try {
      await supabase.from('user_units').delete().eq('user_id', id);
      const { error } = await supabase.from('profiles').delete().eq('id', id);
      if (error) throw error;
      fetchAllData();
    } catch (err: any) {
      alert(err.message);
    }
  };

  const handleDeleteUnit = async (id: string) => {
    if (!confirm("¿Eliminar unidad acuícola? Se perderán todos los datos asociados.")) return;
    try {
      const { error } = await supabase.from('units').delete().eq('id', id);
      if (error) throw error;
      fetchAllData();
    } catch (err: any) {
      alert(err.message);
    }
  };

  if (loading) {
    return (
      <div style={{ minHeight: '80vh', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <div style={{ textAlign: 'center' }}>
          <Loader2 className="animate-spin" size={48} color="var(--primary)" style={{ margin: '0 auto 1rem' }} />
          <p style={{ fontWeight: 600, color: 'var(--muted-foreground)' }}>Auditando y cargando Hub...</p>
        </div>
      </div>
    );
  }

  return (
    <div style={{ padding: '2rem', maxWidth: '1400px', margin: '0 auto' }}>
      {/* Header */}
      <header style={{ marginBottom: '3rem' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', marginBottom: '0.5rem' }}>
              <div style={{ width: '48px', height: '48px', background: 'var(--primary)', borderRadius: '12px', color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 8px 16px rgba(37,99,235,0.2)' }}>
                <Shield size={24} />
              </div>
              <h1 style={{ fontSize: '2.25rem', fontWeight: 900, letterSpacing: '-0.03em' }}>SuperAdmin Hub</h1>
            </div>
            <p style={{ color: 'var(--muted-foreground)', fontWeight: 500 }}>Control maestro de la plataforma FishBit</p>
          </div>
          <div style={{ display: 'flex', gap: '1rem' }}>
             <button onClick={() => setIsUnitModalOpen(true)} className="btn-primary" style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', padding: '0.75rem 1.25rem' }}>
                <Plus size={20} /> Nueva Unidad
             </button>
          </div>
        </div>

        {/* Tabs */}
        <div style={{ display: 'flex', gap: '0.5rem', padding: '0.5rem', background: 'var(--secondary)', borderRadius: '16px', width: 'fit-content' }}>
          <TabNav id="overview" label="Global" icon={LayoutDashboard} active={activeTab} setActive={setActiveTab} />
          <TabNav id="units" label="Unidades" icon={Globe} active={activeTab} setActive={setActiveTab} />
          <TabNav id="clients" label="Clientes" icon={Users} active={activeTab} setActive={setActiveTab} />
          <TabNav id="billing" label="Facturación" icon={CreditCard} active={activeTab} setActive={setActiveTab} />
          <TabNav id="support" label="Soporte" icon={MessageSquare} active={activeTab} setActive={setActiveTab} />
        </div>
      </header>

      {/* Content */}
      <AnimatePresence mode="wait">
        <motion.div
          key={activeTab}
          initial={{ opacity: 0, y: 15 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, y: -15 }}
          transition={{ duration: 0.2 }}
        >
          {activeTab === 'overview' && <OverviewTab units={units} profiles={profiles} tickets={tickets} revenue={totalRevenue} />}
          {activeTab === 'units' && <UnitsTab units={units} onDelete={handleDeleteUnit} />}
          {activeTab === 'clients' && (
            <ClientsTab 
              profiles={profiles} 
              onRegister={() => setIsUserModalOpen(true)} 
              onAssign={(p: any) => { setSelectedUser(p); setIsAssignModalOpen(true); }}
              onDelete={handleDeleteUser}
            />
          )}
          {activeTab === 'billing' && <BillingTab subscriptions={subscriptions} onRefresh={fetchAllData} />}
          {activeTab === 'support' && <SupportTab tickets={tickets} onRefresh={fetchAllData} />}
        </motion.div>
      </AnimatePresence>

      {/* Modals */}
      <AnimatePresence>
        {isUnitModalOpen && (
          <Modal title="Crear Unidad Acuícola" onClose={() => setIsUnitModalOpen(false)}>
            <form onSubmit={handleCreateUnit} style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
              <InputGroup label="Nombre de la Granja" placeholder="Ej. FishBit Central" value={newUnit.name} onChange={(v: string) => setNewUnit({...newUnit, name: v})} />
              <InputGroup label="Ubicación Geográfica" placeholder="Ej. Antioquia, Colombia" value={newUnit.location} onChange={(v: string) => setNewUnit({...newUnit, location: v})} />
              <button type="submit" className="btn-primary" style={{ padding: '1rem', fontWeight: 800 }}>Confirmar Creación</button>
            </form>
          </Modal>
        )}

        {isUserModalOpen && (
          <Modal title="Registrar Administrador" onClose={() => setIsUserModalOpen(false)}>
            <form onSubmit={handleCreateUser} style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
              <InputGroup label="Nombre Completo" placeholder="Ej. Carlos Mendoza" value={newUser.fullName} onChange={(v: string) => setNewUser({...newUser, fullName: v})} />
              <InputGroup label="Email de Acceso" type="email" placeholder="carlos@email.com" value={newUser.email} onChange={(v: string) => setNewUser({...newUser, email: v})} />
              <InputGroup label="Contraseña Temporal" type="password" placeholder="••••••••" value={newUser.password} onChange={(v: string) => setNewUser({...newUser, password: v})} />
              <button type="submit" className="btn-primary" style={{ padding: '1rem', fontWeight: 800 }}>Registrar en FishBit</button>
            </form>
          </Modal>
        )}

        {isAssignModalOpen && (
          <Modal title="Vincular a Unidad" onClose={() => setIsAssignModalOpen(false)}>
            <form onSubmit={handleAssignUnit} style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
              <p style={{ fontSize: '0.9rem', color: 'var(--muted-foreground)' }}>Asignando a: <strong style={{ color: 'var(--foreground)' }}>{selectedUser?.full_name}</strong></p>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                <label style={labelStyle}>Seleccionar Unidad</label>
                <select required value={selectedUnitId} onChange={(e: React.ChangeEvent<HTMLSelectElement>) => setSelectedUnitId(e.target.value)} style={inputStyle}>
                  <option value="">-- Elige una granja --</option>
                  {units.map((u: any) => <option key={u.id} value={u.id}>{u.name}</option>)}
                </select>
              </div>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                <label style={labelStyle}>Rol del Usuario</label>
                <select value={selectedRole} onChange={(e: React.ChangeEvent<HTMLSelectElement>) => setSelectedRole(e.target.value)} style={inputStyle}>
                  <option value="admin">Administrador Principal</option>
                  <option value="tecnico">Técnico Especialista</option>
                  <option value="operario">Operario de Campo</option>
                </select>
              </div>
              <button type="submit" className="btn-primary" style={{ padding: '1rem', fontWeight: 800 }}>Confirmar Vínculo</button>
            </form>
          </Modal>
        )}
      </AnimatePresence>
    </div>
  );
}

// Sub-components
const TabNav = ({ id, label, icon: Icon, active, setActive }: any) => (
  <button 
    onClick={() => setActive(id)}
    style={{
      display: 'flex', alignItems: 'center', gap: '0.6rem', padding: '0.75rem 1.25rem', borderRadius: '12px', border: 'none',
      background: active === id ? 'var(--primary)' : 'transparent',
      color: active === id ? 'white' : 'var(--muted-foreground)',
      fontWeight: 700, cursor: 'pointer', transition: 'all 0.2s ease'
    }}
  >
    <Icon size={18} /> {label}
  </button>
);

const OverviewTab = ({ units, profiles, tickets, revenue }: any) => (
  <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))', gap: '1.5rem' }}>
      <StatCard label="Unidades Totales" value={units.length} icon={Globe} color="#3b82f6" />
      <StatCard label="Usuarios Activos" value={profiles.length} icon={Users} color="#10b981" />
      <StatCard label="Tickets Abiertos" value={tickets.length} icon={MessageSquare} color="#ef4444" />
      <StatCard label="Ingresos Mensuales" value={`$${revenue.toLocaleString()}`} icon={DollarSign} color="#8b5cf6" />
    </div>
    <div style={{ display: 'grid', gridTemplateColumns: '1.5fr 1fr', gap: '2rem' }}>
      <SectionCard title="Unidades Recientes">
        {units.slice(0, 5).map((u: any) => (
          <div key={u.id} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '1rem', background: 'var(--secondary)', borderRadius: '12px', marginBottom: '0.75rem' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
              <Navigation size={20} color="var(--primary)" />
              <div>
                <div style={{ fontWeight: 700 }}>{u.name}</div>
                <div style={{ fontSize: '0.75rem', color: 'var(--muted-foreground)' }}>{u.location}</div>
              </div>
            </div>
            <ChevronRight size={18} color="var(--muted-foreground)" />
          </div>
        ))}
      </SectionCard>
      <SectionCard title="Usuarios Recientes">
        {profiles.slice(0, 5).map((p: any) => (
          <div key={p.id} style={{ display: 'flex', alignItems: 'center', gap: '1rem', marginBottom: '1.25rem' }}>
            <div style={{ width: '36px', height: '36px', borderRadius: '50%', background: 'var(--primary)', color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '0.8rem', fontWeight: 800 }}>{p.full_name?.[0] || 'U'}</div>
            <div>
              <div style={{ fontWeight: 700, fontSize: '0.9rem' }}>{p.full_name}</div>
              <div style={{ fontSize: '0.7rem', color: 'var(--muted-foreground)' }}>{p.is_superadmin ? 'SuperAdmin' : 'Cliente'}</div>
            </div>
          </div>
        ))}
      </SectionCard>
    </div>
  </div>
);

const UnitsTab = ({ units, onDelete }: any) => (
  <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(350px, 1fr))', gap: '1.5rem' }}>
    {units.map((u: any) => (
      <div key={u.id} className="card-premium" style={{ padding: '1.5rem' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '1rem' }}>
          <div style={{ padding: '0.6rem', background: 'rgba(37,99,235,0.1)', borderRadius: '10px', color: 'var(--primary)' }}><Navigation size={22} /></div>
          <button onClick={() => onDelete(u.id)} style={{ color: '#ef4444', background: 'none', border: 'none', cursor: 'pointer' }}><Trash2 size={18} /></button>
        </div>
        <h3 style={{ fontSize: '1.25rem', fontWeight: 800, marginBottom: '0.25rem' }}>{u.name}</h3>
        <p style={{ fontSize: '0.85rem', color: 'var(--muted-foreground)', marginBottom: '1.5rem' }}>{u.location}</p>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.75rem', marginBottom: '1.5rem' }}>
          <div style={{ padding: '0.75rem', background: 'var(--secondary)', borderRadius: '10px', textAlign: 'center' }}>
            <div style={{ fontSize: '0.65rem', fontWeight: 800, color: 'var(--muted-foreground)' }}>MIEMBROS</div>
            <div style={{ fontWeight: 800, fontSize: '1.1rem' }}>{u.user_units?.[0]?.count || 0}</div>
          </div>
          <div style={{ padding: '0.75rem', background: 'var(--secondary)', borderRadius: '10px', textAlign: 'center' }}>
            <div style={{ fontSize: '0.65rem', fontWeight: 800, color: 'var(--muted-foreground)' }}>ESTADO</div>
            <div style={{ fontWeight: 800, fontSize: '1.1rem', color: '#10b981' }}>ACTIVO</div>
          </div>
        </div>
        <button style={{ width: '100%', padding: '0.75rem', borderRadius: '10px', border: '1px solid var(--primary)', background: 'none', color: 'var(--primary)', fontWeight: 800, cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '0.5rem' }}>
          Configuración Técnica <TrendingUp size={16} />
        </button>
      </div>
    ))}
  </div>
);

const ClientsTab = ({ profiles, onRegister, onAssign, onDelete }: any) => (
  <div className="card-premium" style={{ padding: 0, overflow: 'hidden' }}>
    <div style={{ padding: '1.5rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderBottom: '1px solid var(--border)' }}>
      <h3 style={{ fontWeight: 800, fontSize: '1.25rem' }}>Base de Clientes</h3>
      <button onClick={onRegister} className="btn-primary" style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', padding: '0.6rem 1rem' }}>
        <UserPlus size={18} /> Registrar Cliente
      </button>
    </div>
    <div style={{ overflowX: 'auto' }}>
      <table style={{ width: '100%', borderCollapse: 'collapse' }}>
        <thead>
          <tr style={{ background: 'var(--secondary)', textAlign: 'left' }}>
            <th style={tableHeaderStyle}>Usuario</th>
            <th style={tableHeaderStyle}>Rango</th>
            <th style={tableHeaderStyle}>Unidades Vinculadas</th>
            <th style={{ ...tableHeaderStyle, textAlign: 'right' }}>Acciones</th>
          </tr>
        </thead>
        <tbody>
          {profiles.map((p: any) => (
            <tr key={p.id} style={{ borderBottom: '1px solid var(--border)' }}>
              <td style={tableCellStyle}>
                <div style={{ fontWeight: 800 }}>{p.full_name}</div>
                <div style={{ fontSize: '0.75rem', color: 'var(--muted-foreground)' }}>{p.id.slice(0, 8)}...</div>
              </td>
              <td style={tableCellStyle}>
                <span style={{ padding: '0.25rem 0.6rem', borderRadius: '6px', background: p.is_superadmin ? 'rgba(37,99,235,0.1)' : 'rgba(0,0,0,0.05)', color: p.is_superadmin ? 'var(--primary)' : 'inherit', fontSize: '0.75rem', fontWeight: 800 }}>
                  {p.is_superadmin ? 'SUPERADMIN' : 'ADMINISTRADOR'}
                </span>
              </td>
              <td style={tableCellStyle}>
                <div style={{ display: 'flex', gap: '0.4rem', flexWrap: 'wrap' }}>
                  {p.user_units?.map((uu: any, i: number) => (
                    <span key={i} style={{ padding: '2px 8px', background: 'var(--secondary)', borderRadius: '6px', fontSize: '0.7rem', fontWeight: 700 }}>{uu.units.name}</span>
                  ))}
                  {(!p.user_units || p.user_units.length === 0) && <span style={{ fontSize: '0.75rem', color: 'var(--muted-foreground)' }}>Sin vinculación</span>}
                </div>
              </td>
              <td style={{ ...tableCellStyle, textAlign: 'right' }}>
                <div style={{ display: 'flex', gap: '0.5rem', justifyContent: 'flex-end' }}>
                  <button onClick={() => onAssign(p)} className="btn-primary" style={{ padding: '0.5rem 0.75rem', fontSize: '0.75rem' }}>Asignar</button>
                  <button onClick={() => onDelete(p.id)} style={{ padding: '0.5rem', color: '#ef4444', background: 'rgba(239, 68, 68, 0.1)', border: 'none', borderRadius: '8px', cursor: 'pointer' }}><Trash2 size={16} /></button>
                </div>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  </div>
);

const BillingTab = ({ subscriptions, onRefresh }: { subscriptions: any[], onRefresh: () => void }) => {
  const PLAN_PRICES: Record<string, number> = {
    basic: 18,
    premium: 30
  };

  const handleManualRenewal = async (sub: any) => {
    if (!confirm(`¿Confirmas que recibiste el pago de ${sub.units.name} por WhatsApp y quieres renovar 30 días?`)) return;
    
    try {
      const newNextDate = new Date();
      newNextDate.setDate(newNextDate.getDate() + 30);
      const price = PLAN_PRICES[sub.plan_type] || 0;

      if (sub.id.startsWith('temp-')) {
        const { error } = await supabase.from('subscriptions').insert([{ 
          unit_id: sub.unit_id,
          status: 'active', 
          plan_type: 'basic',
          next_billing_date: newNextDate.toISOString(),
          price: PLAN_PRICES.basic
        }]);
        if (error) throw error;
      } else {
        const { error } = await supabase.from('subscriptions').update({ 
          status: 'active', 
          next_billing_date: newNextDate.toISOString(),
          price: price
        }).eq('id', sub.id);
        if (error) throw error;
      }
      onRefresh();
      alert(`¡Suscripción de ${sub.units.name} renovada con éxito!`);
    } catch (err: any) {
      alert("Error al renovar: " + err.message);
    }
  };

  const handleTogglePlan = async (sub: any) => {
    const newPlan = sub.plan_type === 'premium' ? 'basic' : 'premium';
    if (!confirm(`¿Cambiar el plan de ${sub.units.name} a ${newPlan.toUpperCase()}?`)) return;
    
    try {
      if (sub.id.startsWith('temp-')) {
        // Si no existe en la DB, creamos la suscripción
        const { error } = await supabase.from('subscriptions').insert([{ 
          unit_id: sub.unit_id,
          plan_type: newPlan,
          status: 'active',
          price: newPlan === 'premium' ? 30 : 18,
          next_billing_date: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString()
        }]);
        if (error) throw error;
      } else {
        // Si existe, actualizamos
        const { error } = await supabase
          .from('subscriptions')
          .update({ 
            plan_type: newPlan,
            price: newPlan === 'premium' ? 30 : 18 
          })
          .eq('id', sub.id);
        if (error) throw error;
      }
      
      onRefresh();
      alert(`¡Éxito! El plan ahora es ${newPlan.toUpperCase()}.`);
    } catch (err: any) {
      alert("Error: " + err.message);
    }
  };

  const handleSuspend = async (sub: any) => {
    if (!confirm(`¿Estás seguro de suspender la suscripción de ${sub.units.name}? El servicio se detendrá.`)) return;
    try {
      const { error } = await supabase
        .from('subscriptions')
        .update({ status: 'canceled' })
        .eq('id', sub.id);
      if (error) throw error;
      onRefresh();
      alert("Suscripción suspendida.");
    } catch (err: any) {
      alert(err.message);
    }
  };

  return (
    <div className="card-premium" style={{ padding: 0 }}>
       <div style={{ padding: '1.5rem', borderBottom: '1px solid var(--border)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div>
            <h3 style={{ fontWeight: 800 }}>Control de Suscripciones</h3>
            <p style={{ fontSize: '0.8rem', color: 'var(--muted-foreground)' }}>Gestiona los pagos, planes y estados de servicio.</p>
          </div>
       </div>
       <div style={{ overflowX: 'auto' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse' }}>
             <thead style={{ background: 'var(--secondary)', textAlign: 'left' }}>
               <tr>
                 <th style={tableHeaderStyle}>Unidad Acuícola</th>
                 <th style={tableHeaderStyle}>Plan</th>
                 <th style={tableHeaderStyle}>Estado</th>
                 <th style={tableHeaderStyle}>Próximo Cobro</th>
                 <th style={{ ...tableHeaderStyle, textAlign: 'right' }}>Acciones</th>
               </tr>
             </thead>
             <tbody>
               {subscriptions.map((s: any) => {
                 const isExpired = new Date(s.next_billing_date) < new Date();
                 const isActive = s.status === 'active' && !isExpired;
                 
                 return (
                   <tr key={s.id} style={{ borderBottom: '1px solid var(--border)' }}>
                     <td style={tableCellStyle}>
                        <div style={{ fontWeight: 800 }}>{s.units.name}</div>
                        <div style={{ fontSize: '0.7rem', color: 'var(--muted-foreground)' }}>Responsable: {s.client_name}</div>
                     </td>
                     <td style={tableCellStyle}>
                        <button 
                          onClick={() => handleTogglePlan(s)}
                          style={{ 
                            padding: '4px 10px', 
                            borderRadius: '20px', 
                            background: s.plan_type === 'premium' ? 'linear-gradient(135deg, #f59e0b, #d97706)' : 'rgba(37,99,235,0.1)', 
                            color: s.plan_type === 'premium' ? 'white' : 'var(--primary)', 
                            fontSize: '0.65rem', 
                            fontWeight: 900,
                            border: 'none',
                            cursor: 'pointer',
                            display: 'flex',
                            alignItems: 'center',
                            gap: '4px'
                          }}
                        >
                          {s.plan_type === 'premium' && <Flag size={10} />}
                          {s.plan_type.toUpperCase()}
                        </button>
                     </td>
                     <td style={tableCellStyle}>
                       <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', color: isExpired || s.status === 'canceled' ? '#ef4444' : '#10b981', fontWeight: 800, fontSize: '0.8rem' }}>
                         {isExpired || s.status === 'canceled' ? <AlertCircle size={14} /> : <CheckCircle2 size={14} />}
                         {s.status === 'canceled' ? 'SUSPENDIDO' : (isExpired ? 'VENCIDO' : 'ACTIVO')}
                       </div>
                     </td>
                     <td style={tableCellStyle}>{new Date(s.next_billing_date).toLocaleDateString()}</td>
                     <td style={{ ...tableCellStyle, textAlign: 'right' }}>
                       <div style={{ display: 'flex', gap: '0.5rem', justifyContent: 'flex-end' }}>
                         {!isActive ? (
                           <button 
                             onClick={() => handleManualRenewal(s)}
                             className="btn-primary" 
                             style={{ padding: '0.5rem 1rem', fontSize: '0.75rem', display: 'flex', alignItems: 'center', gap: '0.4rem' }}
                           >
                             <DollarSign size={14} /> Activar / Renovar
                           </button>
                         ) : (
                           <button 
                             onClick={() => handleSuspend(s)}
                             style={{ padding: '0.5rem 1rem', background: 'rgba(239, 68, 68, 0.1)', color: '#ef4444', border: 'none', borderRadius: '8px', fontSize: '0.75rem', fontWeight: 700, cursor: 'pointer' }}
                           >
                             Suspender
                           </button>
                         )}
                       </div>
                     </td>
                   </tr>
                 );
               })}
             </tbody>
          </table>
       </div>
    </div>
  );
};

const SupportTab = ({ tickets, onRefresh }: { tickets: any[], onRefresh: () => void }) => {
  const [selectedTicket, setSelectedTicket] = useState<any>(null);
  const [response, setResponse] = useState('');

  const handleUpdateStatus = async (id: string, newStatus: string) => {
    const { error } = await supabase.from('support_tickets').update({ status: newStatus }).eq('id', id);
    if (!error) onRefresh();
  };

  const handleSendResponse = async () => {
    alert(`Enviando respuesta a ${selectedTicket.profiles?.full_name}: "${response}"\n\n(En producción esto enviaría un correo o notificación push).`);
    await handleUpdateStatus(selectedTicket.id, 'resolved');
    setSelectedTicket(null);
    setResponse('');
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
      {tickets.map((t: any) => (
        <div key={t.id} className="card-premium" style={{ padding: '1.5rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div style={{ display: 'flex', gap: '1.25rem', alignItems: 'center' }}>
            <div style={{ 
              width: '48px', height: '48px', 
              background: t.priority === 'high' ? 'rgba(239, 68, 68, 0.1)' : 'rgba(37, 99, 235, 0.1)', 
              color: t.priority === 'high' ? '#ef4444' : 'var(--primary)', 
              borderRadius: '12px', display: 'flex', alignItems: 'center', justifyContent: 'center' 
            }}>
              <MessageSquare size={24} />
            </div>
            <div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '0.25rem' }}>
                <h4 style={{ fontWeight: 800, fontSize: '1.1rem' }}>{t.subject}</h4>
                <span style={{ fontSize: '0.65rem', fontWeight: 900, padding: '2px 6px', borderRadius: '4px', background: 'var(--secondary)', color: 'var(--muted-foreground)' }}>
                  #{t.id.slice(0, 5).toUpperCase()}
                </span>
              </div>
              <p style={{ fontSize: '0.85rem', color: 'var(--muted-foreground)', marginBottom: '0.5rem' }}>{t.description || 'Sin descripción'}</p>
              <div style={{ display: 'flex', gap: '1rem', alignItems: 'center' }}>
                <span style={{ fontSize: '0.75rem', color: 'var(--primary)', fontWeight: 700 }}>👤 {t.profiles?.full_name}</span>
                <span style={{ fontSize: '0.75rem', color: 'var(--muted-foreground)' }}>Status: <strong style={{ color: t.status === 'open' ? '#f59e0b' : '#10b981' }}>{t.status.toUpperCase()}</strong></span>
              </div>
            </div>
          </div>
          <div style={{ display: 'flex', gap: '0.5rem' }}>
            <button 
              onClick={() => setSelectedTicket(t)}
              className="btn-primary" 
              style={{ padding: '0.6rem 1.25rem', fontSize: '0.85rem', fontWeight: 800 }}
            >
              Atender
            </button>
            {t.status !== 'resolved' && (
              <button 
                onClick={() => handleUpdateStatus(t.id, 'resolved')}
                style={{ padding: '0.6rem', borderRadius: '10px', border: '1px solid var(--border)', background: 'none', cursor: 'pointer' }}
                title="Marcar como resuelto"
              >
                <CheckCircle2 size={18} color="#10b981" />
              </button>
            )}
          </div>
        </div>
      ))}
      
      {tickets.length === 0 && (
        <div style={{ textAlign: 'center', padding: '6rem 2rem', background: 'var(--secondary)', borderRadius: '24px', border: '2px dashed var(--border)' }}>
          <MessageSquare size={48} style={{ margin: '0 auto 1.5rem', opacity: 0.2 }} />
          <h3 style={{ fontWeight: 800, color: 'var(--muted-foreground)' }}>Bandeja de Entrada Limpia</h3>
          <p style={{ fontSize: '0.9rem', color: 'var(--muted-foreground)' }}>No hay tickets pendientes de atención en este momento.</p>
        </div>
      )}

      {/* Modal de Respuesta */}
      <AnimatePresence>
        {selectedTicket && (
          <Modal title="Responder Ticket" onClose={() => setSelectedTicket(null)}>
            <div style={{ marginBottom: '1.5rem' }}>
              <p style={{ fontSize: '0.85rem', color: 'var(--muted-foreground)', marginBottom: '0.5rem' }}>Mensaje original:</p>
              <div style={{ padding: '1rem', background: 'var(--secondary)', borderRadius: '12px', fontSize: '0.9rem', fontStyle: 'italic' }}>
                "{selectedTicket.description}"
              </div>
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.6rem', marginBottom: '2rem' }}>
              <label style={labelStyle}>Tu Respuesta</label>
              <textarea 
                rows={4} 
                placeholder="Escribe aquí la solución o respuesta para el cliente..." 
                value={response}
                onChange={(e: React.ChangeEvent<HTMLTextAreaElement>) => setResponse(e.target.value)}
                style={{ ...inputStyle, resize: 'none' }}
              />
            </div>
            <button 
              onClick={handleSendResponse}
              disabled={!response}
              className="btn-primary" 
              style={{ width: '100%', padding: '1rem', fontWeight: 800, opacity: response ? 1 : 0.5 }}
            >
              Enviar Respuesta y Cerrar Ticket
            </button>
          </Modal>
        )}
      </AnimatePresence>
    </div>
  );
};

// Helpers
const StatCard = ({ label, value, icon: Icon, color }: any) => (
  <div className="card-premium" style={{ padding: '1.5rem', display: 'flex', alignItems: 'center', gap: '1.25rem' }}>
    <div style={{ padding: '0.75rem', background: `${color}15`, borderRadius: '14px', color }}><Icon size={26} /></div>
    <div>
      <div style={{ fontSize: '0.8rem', color: 'var(--muted-foreground)', fontWeight: 700, textTransform: 'uppercase' }}>{label}</div>
      <div style={{ fontSize: '1.75rem', fontWeight: 900 }}>{value}</div>
    </div>
  </div>
);

const SectionCard = ({ title, children }: any) => (
  <div className="card-premium" style={{ padding: '1.5rem' }}>
    <h3 style={{ fontWeight: 900, fontSize: '1.1rem', marginBottom: '1.5rem', letterSpacing: '-0.02em' }}>{title}</h3>
    {children}
  </div>
);

const Modal = ({ title, children, onClose }: any) => (
  <div style={{ position: 'fixed', inset: 0, background: 'rgba(15, 23, 42, 0.6)', backdropFilter: 'blur(12px)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000, padding: '1rem' }}>
    <motion.div initial={{ scale: 0.95, opacity: 0 }} animate={{ scale: 1, opacity: 1 }} className="card-premium" style={{ width: '100%', maxWidth: '480px', padding: '2.5rem', position: 'relative' }}>
      <button onClick={onClose} style={{ position: 'absolute', top: '1.5rem', right: '1.5rem', background: 'none', border: 'none', color: 'var(--muted-foreground)', cursor: 'pointer' }}><X size={24} /></button>
      <h2 style={{ fontSize: '1.75rem', fontWeight: 900, marginBottom: '2rem', letterSpacing: '-0.03em' }}>{title}</h2>
      {children}
    </motion.div>
  </div>
);

const InputGroup = ({ label, value, onChange, type = 'text', placeholder }: any) => (
  <div style={{ display: 'flex', flexDirection: 'column', gap: '0.6rem' }}>
    <label style={labelStyle}>{label}</label>
    <input type={type} placeholder={placeholder} value={value} onChange={(e: React.ChangeEvent<HTMLInputElement>) => onChange(e.target.value)} style={inputStyle} required />
  </div>
);

const labelStyle = { fontSize: '0.75rem', fontWeight: 900, color: 'var(--muted-foreground)', textTransform: 'uppercase' as const, letterSpacing: '0.05em' };
const inputStyle = { width: '100%', padding: '0.9rem 1.25rem', borderRadius: '12px', border: '1px solid var(--border)', background: 'var(--secondary)', outline: 'none', fontSize: '1rem', transition: 'all 0.2s ease' };
const tableHeaderStyle = { padding: '1rem 1.5rem', fontSize: '0.75rem', fontWeight: 900, color: 'var(--muted-foreground)', textTransform: 'uppercase' as const };
const tableCellStyle = { padding: '1.25rem 1.5rem' };
