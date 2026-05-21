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
  UserPlus,
  Calendar,
  Sparkles
} from 'lucide-react';
import { useSearchParams, useRouter } from 'next/navigation';
import Link from 'next/link';
import { toast } from 'react-hot-toast';
import { useAuth } from '../components/providers/AuthProvider';

interface SuperAdminUnit {
  id: string;
  name: string;
  location: string;
  created_at?: string;
  subscriptions: any[];
  user_units: { count: number }[];
}

interface SuperAdminProfile {
  id: string;
  full_name: string;
  email: string;
  role: string;
  is_superadmin: boolean;
  user_units: {
    user_id: string;
    unit_id: string;
    role: string;
    units: { name: string };
  }[];
}

interface SuperAdminSubscription {
  id: string;
  unit_id: string;
  units: SuperAdminUnit;
  plan_type: string;
  status: string;
  next_billing_date: string;
  client_name: string;
}

interface SuperAdminTicket {
  id: string;
  subject: string;
  priority: string;
  description: string;
  status: string;
  created_at: string;
  user_id: string;
  profiles: { full_name: string };
}

type Tab = 'overview' | 'units' | 'clients' | 'billing' | 'support';

export default function SuperAdminHub() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const initialTab = (searchParams.get('tab') as Tab) || 'overview';
  const { session, loading: authLoading, profileLoading, isSuperAdmin } = useAuth();
  
  // State
  const [activeTab, setActiveTab] = useState<Tab>(initialTab);
  const [loading, setLoading] = useState(true);
  const [units, setUnits] = useState<SuperAdminUnit[]>([]);
  const [profiles, setProfiles] = useState<SuperAdminProfile[]>([]);
  const [totalRevenue, setTotalRevenue] = useState(0);
  const [subscriptions, setSubscriptions] = useState<SuperAdminSubscription[]>([]);
  const [tickets, setTickets] = useState<SuperAdminTicket[]>([]);
  
  // Modal States
  const [isUnitModalOpen, setIsUnitModalOpen] = useState(false);
  const [isEditUnitModalOpen, setIsEditUnitModalOpen] = useState(false);
  const [isUserModalOpen, setIsUserModalOpen] = useState(false);
  const [isAssignModalOpen, setIsAssignModalOpen] = useState(false);
  
  // Form States
  const [selectedUser, setSelectedUser] = useState<any>(null);
  const [selectedUnitId, setSelectedUnitId] = useState('');
  const [selectedRole, setSelectedRole] = useState('admin');
  const [newUnit, setNewUnit] = useState({ name: '', location: '' });
  const [editUnit, setEditUnit] = useState({ id: '', name: '', location: '' });
  const [newUser, setNewUser] = useState({ email: '', password: '', fullName: '' });

  const fetchAllData = useCallback(async (showLoader = false) => {
    if (showLoader) setLoading(true);
    try {
      const results = await Promise.allSettled([
        supabase.from('units').select('*'),
        supabase.from('profiles').select('*'),
        supabase.from('user_units').select('*'),
        supabase.from('subscriptions').select('*'),
        supabase.from('support_tickets').select('*')
      ]);

      const allUnitsData = (results[0].status === 'fulfilled' ? results[0].value.data : []) || [];
      const unitsData = allUnitsData.filter((u: any) => u.id !== '00000000-0000-0000-0000-000000000000');
      const profilesData = (results[1].status === 'fulfilled' ? results[1].value.data : []) || [];
      const uuData = (results[2].status === 'fulfilled' ? results[2].value.data : []) || [];
      const subsData = (results[3].status === 'fulfilled' ? results[3].value.data : []) || [];
      const ticketsData = (results[4].status === 'fulfilled' ? results[4].value.data : []) || [];

      const processedProfiles = profilesData.map((p: any) => ({
        ...p,
        user_units: uuData.filter((uu: any) => uu.user_id === p.id).map((uu: any) => ({
          ...uu,
          units: unitsData.find((u: any) => u.id === uu.unit_id) || { name: 'Unidad Desconocida' }
        }))
      }));

      const processedUnits = unitsData.map((u: any) => ({
        ...u,
        subscriptions: subsData.filter((s: any) => s.unit_id === u.id),
        user_units: [{ count: uuData.filter((uu: any) => uu.unit_id === u.id).length }]
      }));

      const processedSubs = unitsData.map((u: any) => {
        const sub = subsData.find((s: any) => s.unit_id === u.id);
        const unitAdminRelation = uuData.find((uu: any) => uu.unit_id === u.id && uu.role === 'admin');
        const adminProfile = profilesData.find((p: any) => p.id === unitAdminRelation?.user_id);
        
        return {
          id: sub?.id || `temp-${u.id}`,
          unit_id: u.id,
          units: u,
          plan_type: sub?.plan_type || 'Sin Plan',
          status: sub?.status || 'inactive',
          next_billing_date: sub?.next_billing_date || new Date().toISOString(),
          client_name: adminProfile?.full_name || 'Sin asignar',
          price: sub?.price ?? 0,
          trial_activated_at: sub?.trial_activated_at || null
        };
      });

      const processedTickets = ticketsData.map((t: any) => ({
        ...t,
        profiles: profilesData.find((p: any) => p.id === t.user_id) || { full_name: 'Usuario' }
      }));

      setUnits(processedUnits);
      setProfiles(processedProfiles);
      setSubscriptions(processedSubs);
      setTickets(processedTickets);

      // Bug #14 fix: compute total revenue from active subscriptions
      const revenue = subsData.reduce((sum: number, s: any) => sum + (parseFloat(s.price) || 0), 0);
      setTotalRevenue(revenue);
    } catch (err: any) {
      toast.error("Error al sincronizar datos maestro.");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    if (authLoading || profileLoading) return;

    if (!session) {
      router.push('/');
      return;
    }

    if (!isSuperAdmin) {
      toast.error('Acceso denegado. Permisos insuficientes.');
      router.push('/dashboard');
      return;
    }

    const tab = searchParams.get('tab') as Tab;
    if (tab) setActiveTab(tab);
    fetchAllData(true);
  }, [authLoading, profileLoading, session, isSuperAdmin, searchParams, fetchAllData, router]);

  // Handlers
  const handleCreateUnit = async (e: React.FormEvent) => {
    e.preventDefault();
    const createPromise = async () => {
      const { data, error } = await supabase.from('units').insert([newUnit]).select().single();
      if (error) throw error;
      
      await supabase.from('subscriptions').insert([{
        unit_id: data.id,
        plan_type: 'basic',
        status: 'active',
        price: 0, // First month free promotion
        next_billing_date: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString()
      }]);

      setIsUnitModalOpen(false);
      setNewUnit({ name: '', location: '' });
      await fetchAllData();
      return true;
    };

    toast.promise(createPromise(), {
      loading: 'Creando unidad...',
      success: 'Unidad creada y suscrita.',
      error: (err) => `Error: ${err.message}`
    });
  };

  const handleUpdateUnit = async (e: React.FormEvent) => {
    e.preventDefault();
    const updatePromise = async () => {
      const { data, error } = await supabase
        .from('units')
        .update({ name: editUnit.name, location: editUnit.location })
        .eq('id', editUnit.id)
        .select();
      if (error) throw error;
      
      setIsEditUnitModalOpen(false);
      await fetchAllData();
      return data;
    };

    toast.promise(updatePromise(), {
      loading: 'Actualizando unidad...',
      success: 'Unidad actualizada exitosamente.',
      error: 'Error al actualizar unidad.'
    });
  };

  const handleCreateUser = async (e: React.FormEvent) => {
    e.preventDefault();
    const registerPromise = async () => {
      const response = await fetch('/api/users', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: newUser.email,
          fullName: newUser.fullName,
          password: newUser.password,
          role: 'admin'
        })
      });

      const res = await response.json();
      if (!response.ok || res.error) {
        throw new Error(res.error || 'Error al registrar cliente');
      }

      setIsUserModalOpen(false);
      setNewUser({ email: '', password: '', fullName: '' });
      await fetchAllData();
      return true;
    };

    toast.promise(registerPromise(), {
      loading: 'Registrando cliente...',
      success: 'Cliente registrado correctamente.',
      error: (err) => `Error: ${err.message}`
    });
  };

  const handleAssignUnit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedUser || !selectedUnitId) return;
    
    const assignPromise = async () => {
      const { error } = await supabase.from('user_units').insert([{
        user_id: selectedUser.id,
        unit_id: selectedUnitId,
        role: selectedRole
      }]);
      if (error) throw error;
      setIsAssignModalOpen(false);
      await fetchAllData();
      return true;
    };

    toast.promise(assignPromise(), {
      loading: 'Vinculando usuario...',
      success: 'Vínculo establecido.',
      error: (err) => `Error: ${err.message}`
    });
  };

  const handleDeleteUser = async (id: string) => {
    if (!confirm("¿Eliminar usuario definitivamente?")) return;
    
    const deletePromise = async () => {
      const response = await fetch('/api/users/delete', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ userId: id })
      });

      const res = await response.json();
      if (!response.ok || res.error) {
        throw new Error(res.error || 'Error al eliminar usuario');
      }
      await fetchAllData();
      return true;
    };

    toast.promise(deletePromise(), {
      loading: 'Eliminando...',
      success: 'Usuario eliminado del sistema.',
      error: (err) => `Error: ${err.message}`
    });
  };

  const handleDeleteUnit = async (id: string) => {
    if (!confirm("¿Eliminar unidad y todos sus datos?")) return;
    
    const deletePromise = async () => {
      // 1. Get siembras for this unit to delete siembra_details
      const { data: siembras, error: fetchSiembrasErr } = await supabase
        .from('siembras')
        .select('id')
        .eq('unit_id', id);
      
      if (fetchSiembrasErr && fetchSiembrasErr.code !== 'PGRST205') {
        throw fetchSiembrasErr;
      }

      const siembraIds = (siembras || []).map((s: any) => s.id);
      if (siembraIds.length > 0) {
        const { error: delSiembraDetailsErr } = await supabase
          .from('siembra_details')
          .delete()
          .in('siembra_id', siembraIds);
        
        if (delSiembraDetailsErr && delSiembraDetailsErr.code !== 'PGRST205') {
          throw delSiembraDetailsErr;
        }
      }

      // 2. Delete detail/leaf tables that have unit_id
      const leafTables = [
        'aireacion_logs',
        'alimentacion_diaria',
        'biometrias',
        'mortalidad',
        'mortality',
        'invoice_items',
        'historial_gastos',
        'pond_species',
        'transfers',
        'ventas',
        'water_quality',
        'mantenimiento_logs',
        'tratamiento_details',
        'jornales',
        'nomina'
      ];

      for (const table of leafTables) {
        const { error: err } = await supabase.from(table).delete().eq('unit_id', id);
        if (err && err.code !== 'PGRST205') {
          console.warn(`Warning deleting from ${table}:`, err);
        }
      }

      // 3. Delete parent tables that have unit_id
      const parentTables = [
        'aireacion_config',
        'siembras',
        'tratamientos',
        'invoices',
        'inventory',
        'providers',
        'clientes',
        'estanques',
        'unit_settings',
        'cierres_lote',
        'subscriptions',
        'user_units'
      ];

      for (const table of parentTables) {
        const { error: err } = await supabase.from(table).delete().eq('unit_id', id);
        if (err && err.code !== 'PGRST205') {
          console.warn(`Warning deleting from parent table ${table}:`, err);
        }
      }

      // 4. Finally delete the unit itself!
      const { error: unitDelErr } = await supabase.from('units').delete().eq('id', id);
      if (unitDelErr) throw unitDelErr;

      await fetchAllData();
      return true;
    };

    toast.promise(deletePromise(), {
      loading: 'Borrando unidad...',
      success: 'Unidad eliminada.',
      error: (err) => `Error al borrar: ${err.message || 'Error desconocido'}`
    });
  };

  if (authLoading || profileLoading || loading) {
    return (
      <div style={{ minHeight: '80vh', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <div style={{ textAlign: 'center' }}>
          <Loader2 className="animate-spin" size={48} color="#0d9488" style={{ margin: '0 auto 1rem' }} />
          <p style={{ fontWeight: 700, color: 'var(--muted-foreground)' }}>Auditando Ecosistema...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="animate-fade-in page-container">
      <header style={{ marginBottom: '3rem' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2.5rem', flexWrap: 'wrap', gap: '1.5rem' }}>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', marginBottom: '0.5rem' }}>
              <div style={{ width: '48px', height: '48px', background: '#0d9488', borderRadius: '14px', color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 8px 16px rgba(13,148,136,0.2)' }}>
                <Shield size={24} />
              </div>
              <h1 style={{ fontWeight: 900, letterSpacing: '-0.04em' }}>SuperAdmin Hub</h1>
            </div>
            <p style={{ color: 'var(--muted-foreground)', fontWeight: 600, fontSize: '0.9rem' }}>Centro de control maestro FishBit.</p>
          </div>
          <div style={{ display: 'flex', gap: '1rem', alignItems: 'center' }}>
             <Link 
                href="/configuracion" 
                style={{ 
                  display: 'flex', 
                  alignItems: 'center', 
                  gap: '0.5rem', 
                  padding: '0.8rem 1.5rem', 
                  background: 'var(--secondary)', 
                  border: '1px solid var(--border)',
                  color: 'var(--foreground)',
                  borderRadius: '12px',
                  textDecoration: 'none',
                  fontWeight: 800,
                  fontSize: '0.9rem',
                  transition: 'all 0.2s'
                }}
             >
                <Settings size={20} /> Configuración Global
             </Link>
             <button onClick={() => setIsUnitModalOpen(true)} className="btn-primary" style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', padding: '0.8rem 1.5rem', background: '#0d9488', borderRadius: '12px' }}>
                <Plus size={20} /> Nueva Unidad
             </button>
          </div>
        </div>

        <div style={{ display: 'flex', gap: '0.4rem', padding: '0.4rem', background: 'var(--secondary)', borderRadius: '18px', width: 'fit-content', flexWrap: 'wrap' }}>
          <TabNav id="overview" label="Dashboard" icon={LayoutDashboard} active={activeTab} setActive={setActiveTab} />
          <TabNav id="units" label="Granjas" icon={Globe} active={activeTab} setActive={setActiveTab} />
          <TabNav id="clients" label="Clientes" icon={Users} active={activeTab} setActive={setActiveTab} />
          <TabNav id="billing" label="Pagos" icon={CreditCard} active={activeTab} setActive={setActiveTab} />
          <TabNav id="support" label="Soporte" icon={MessageSquare} active={activeTab} setActive={setActiveTab} />
        </div>
      </header>

      <AnimatePresence mode="wait">
        <motion.div
          key={activeTab}
          initial={{ opacity: 0, y: 15 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, y: -15 }}
          transition={{ duration: 0.2 }}
        >
          {activeTab === 'overview' && <OverviewTab units={units} profiles={profiles} tickets={tickets} revenue={totalRevenue} />}
          {activeTab === 'units' && <UnitsTab units={units} onDelete={handleDeleteUnit} onEdit={(u: any) => { setEditUnit({ id: u.id, name: u.name, location: u.location }); setIsEditUnitModalOpen(true); }} />}
          {activeTab === 'clients' && (
            <ClientsTab 
              profiles={profiles.filter((p: any) => 
                !p.is_superadmin && (
                  (!p.user_units || p.user_units.length === 0) || 
                  p.user_units.some((uu: any) => uu.role === 'admin')
                )
              )} 
              onRegister={() => setIsUserModalOpen(true)} 
              onAssign={(p: any) => { setSelectedUser(p); setIsAssignModalOpen(true); }}
              onDelete={handleDeleteUser}
            />
          )}
          {activeTab === 'billing' && <BillingTab subscriptions={subscriptions} onRefresh={fetchAllData} />}
          {activeTab === 'support' && <SupportTab tickets={tickets} onRefresh={fetchAllData} />}
        </motion.div>
      </AnimatePresence>

      <AnimatePresence>
        {isUnitModalOpen && (
          <Modal title="Nueva Unidad" onClose={() => setIsUnitModalOpen(false)}>
            <form onSubmit={handleCreateUnit} style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
              <InputGroup label="Nombre Comercial" placeholder="FishBit Central" value={newUnit.name} onChange={(v: string) => setNewUnit({...newUnit, name: v})} />
              <InputGroup label="Región / País" placeholder="Antioquia, Colombia" value={newUnit.location} onChange={(v: string) => setNewUnit({...newUnit, location: v})} />
              <button type="submit" className="btn-primary" style={{ padding: '1.25rem', fontWeight: 800, background: '#0d9488', borderRadius: '14px' }}>Confirmar Apertura</button>
            </form>
          </Modal>
        )}

        {isEditUnitModalOpen && (
          <Modal title="Editar Unidad" onClose={() => setIsEditUnitModalOpen(false)}>
            <form onSubmit={handleUpdateUnit} style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
              <InputGroup label="Nombre Comercial" placeholder="FishBit Central" value={editUnit.name} onChange={(v: string) => setEditUnit({...editUnit, name: v})} />
              <InputGroup label="Región / País" placeholder="Antioquia, Colombia" value={editUnit.location} onChange={(v: string) => setEditUnit({...editUnit, location: v})} />
              <button type="submit" className="btn-primary" style={{ padding: '1.25rem', fontWeight: 800, background: '#0d9488', borderRadius: '14px' }}>Guardar Cambios</button>
            </form>
          </Modal>
        )}

        {isUserModalOpen && (
          <Modal title="Registro Cliente" onClose={() => setIsUserModalOpen(false)}>
            <form onSubmit={handleCreateUser} style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
              <InputGroup label="Nombre Titular" placeholder="Carlos Mendoza" value={newUser.fullName} onChange={(v: string) => setNewUser({...newUser, fullName: v})} />
              <InputGroup label="Correo Corporativo" type="email" placeholder="carlos@fishbit.app" value={newUser.email} onChange={(v: string) => setNewUser({...newUser, email: v})} />
              <InputGroup label="Acceso Provisional" type="password" placeholder="••••••••" value={newUser.password} onChange={(v: string) => setNewUser({...newUser, password: v})} />
              <button type="submit" className="btn-primary" style={{ padding: '1.25rem', fontWeight: 800, background: '#0d9488', borderRadius: '14px' }}>Crear Cuenta</button>
            </form>
          </Modal>
        )}

        {isAssignModalOpen && (
          <Modal title="Vinculación" onClose={() => setIsAssignModalOpen(false)}>
            <form onSubmit={handleAssignUnit} style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
              <div className="glass" style={{ padding: '1rem', borderRadius: '12px', marginBottom: '0.5rem' }}>
                <p style={{ fontSize: '0.85rem', color: 'var(--muted-foreground)', marginBottom: '0.2rem' }}>Usuario Destino</p>
                <p style={{ fontWeight: 800 }}>{selectedUser?.full_name}</p>
              </div>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                <label className="premium-label">Granja Asignada</label>
                <select required value={selectedUnitId} onChange={(e) => setSelectedUnitId(e.target.value)} className="premium-input">
                  <option value="">Seleccionar...</option>
                  {units.map((u: any) => <option key={u.id} value={u.id}>{u.name}</option>)}
                </select>
              </div>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                <label className="premium-label">Nivel de Privilegio</label>
                <select value={selectedRole} onChange={(e) => setSelectedRole(e.target.value)} className="premium-input">
                  <option value="admin">Administrador General</option>
                  <option value="tecnico">Técnico Operativo</option>
                  <option value="operario">Personal de Planta</option>
                </select>
              </div>
              <button type="submit" className="btn-primary" style={{ padding: '1.25rem', fontWeight: 800, background: '#0d9488', borderRadius: '14px' }}>Confirmar Vínculo</button>
            </form>
          </Modal>
        )}
      </AnimatePresence>
    </div>
  );
}

const TabNav = ({ id, label, icon: Icon, active, setActive }: any) => (
  <button 
    onClick={() => setActive(id)}
    style={{
      display: 'flex', alignItems: 'center', gap: '0.6rem', padding: '0.75rem 1.4rem', borderRadius: '14px', border: 'none',
      background: active === id ? '#0d9488' : 'transparent',
      color: active === id ? 'white' : 'var(--muted-foreground)',
      fontWeight: 800, cursor: 'pointer', transition: 'all 0.25s cubic-bezier(0.4, 0, 0.2, 1)',
      fontSize: '0.85rem'
    }}
  >
    <Icon size={18} /> {label}
  </button>
);

const OverviewTab = ({ units, profiles, tickets, revenue }: any) => {
  // Filter for clients (Administradores only, excluding SuperAdmins and technicians/operators)
  const clientProfiles = profiles.filter((p: any) => 
    !p.is_superadmin && (
      (!p.user_units || p.user_units.length === 0) || 
      p.user_units.some((uu: any) => uu.role === 'admin')
    )
  );

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))', gap: '1.5rem' }}>
        <StatCard label="Granjas" value={units.length} icon={Globe} color="#0d9488" />
        <StatCard label="Usuarios" value={clientProfiles.length} icon={Users} color="#0d9488" />
        <StatCard label="Soporte" value={tickets.length} icon={MessageSquare} color="#f59e0b" />
        <StatCard label="Ingresos (COP)" value={`$${revenue.toLocaleString('es-CO')}`} icon={DollarSign} color="#8b5cf6" />
      </div>
      <div className="responsive-grid-2">
        <SectionCard title="Unidades Acuícolas Recientes">
          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
            {units.slice(0, 5).map((u: any) => {
              const sub = u.subscriptions?.[0];
              const isExpired = sub ? new Date(sub.next_billing_date) < new Date() : true;
              const isSuspended = sub ? (sub.status === 'canceled' || sub.status === 'suspended') : true;
              const statusText = isSuspended ? 'SUSPENDIDO' : (isExpired ? 'VENCIDO' : 'ACTIVO');
              const statusColor = isSuspended || isExpired ? '#ef4444' : '#10b981';
              const statusBg = isSuspended || isExpired ? 'rgba(239, 68, 68, 0.1)' : 'rgba(16, 185, 129, 0.1)';

              const unitProfiles = profiles.filter((p: any) => p.user_units?.some((uu: any) => uu.unit_id === u.id));
              let latestProfile: any = null;
              let maxTime = 0;
              
              unitProfiles.forEach((p: any) => {
                const time = new Date(p.updated_at || p.created_at || u.created_at).getTime();
                if (time > maxTime) {
                  maxTime = time;
                  latestProfile = p;
                }
              });

              const lastAccessDate = latestProfile ? new Date(maxTime) : new Date(u.created_at);
              const lastAccessStr = lastAccessDate.toLocaleDateString('es-CO', { 
                day: '2-digit', 
                month: 'short', 
                hour: '2-digit', 
                minute: '2-digit' 
              });

              const uuRelation = latestProfile?.user_units?.find((uu: any) => uu.unit_id === u.id);
              const roleLabel = uuRelation 
                ? (uuRelation.role === 'admin' ? 'Admin' : uuRelation.role === 'tecnico' ? 'Técnico' : 'Operario')
                : (latestProfile?.is_superadmin ? 'SuperAdmin' : 'Cliente');
              
              const whoAccess = latestProfile 
                ? ` (${latestProfile.full_name?.split(' ')[0] || 'Usuario'} - ${roleLabel})` 
                : '';

              return (
                <div key={u.id} className="glass" style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '1rem', borderRadius: '14px', gap: '1rem' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', width: '38px', height: '38px', borderRadius: '10px', background: 'rgba(13,148,136,0.1)', color: '#0d9488' }}>
                      <Navigation size={18} />
                    </div>
                    <div>
                      <div style={{ fontWeight: 800, fontSize: '0.95rem' }}>{u.name}</div>
                      <div style={{ fontSize: '0.75rem', color: 'var(--muted-foreground)', display: 'flex', alignItems: 'center', gap: '0.4rem', marginTop: '2px' }}>
                        <Calendar size={12} />
                        <span>Acceso: {lastAccessStr}{whoAccess}</span>
                      </div>
                    </div>
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                    <span style={{ 
                      padding: '4px 10px', 
                      borderRadius: '10px', 
                      background: statusBg, 
                      color: statusColor, 
                      fontSize: '0.65rem', 
                      fontWeight: 900,
                      letterSpacing: '0.05em'
                    }}>
                      {statusText}
                    </span>
                  </div>
                </div>
              );
            })}
          </div>
        </SectionCard>
        <SectionCard title="Usuarios Recientes">
          <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
            {clientProfiles.slice(0, 5).map((p: any) => {
              const unitText = p.is_superadmin 
                ? 'PLATFORM OWNER' 
                : (!p.user_units || p.user_units.length === 0) 
                  ? 'Sin unidad asignada' 
                  : p.user_units.map((uu: any) => uu.units.name).join(', ');

              return (
                <div key={p.id} style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                  <div style={{ width: '40px', height: '40px', borderRadius: '12px', background: '#0d9488', color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '0.9rem', fontWeight: 900 }}>{p.full_name?.[0] || 'U'}</div>
                  <div>
                    <div style={{ fontWeight: 800, fontSize: '0.95rem' }}>{p.full_name}</div>
                    <div style={{ fontSize: '0.7rem', color: 'var(--muted-foreground)', fontWeight: 700 }}>{unitText}</div>
                  </div>
                </div>
              );
            })}
          </div>
        </SectionCard>
      </div>
    </div>
  );
};

const UnitsTab = ({ units, onDelete, onEdit }: any) => (
  <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))', gap: '1.5rem' }}>
    {units.map((u: any) => (
      <div key={u.id} className="card-premium" style={{ padding: '2rem' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '1.5rem' }}>
          <div style={{ padding: '0.75rem', background: 'rgba(13,148,136,0.1)', borderRadius: '12px', color: '#0d9488' }}><Navigation size={24} /></div>
          <button onClick={() => onDelete(u.id)} style={{ color: '#ef4444', background: 'none', border: 'none', cursor: 'pointer', padding: '0.5rem' }}><Trash2 size={20} /></button>
        </div>
        <h3 style={{ fontSize: '1.4rem', fontWeight: 900, marginBottom: '0.25rem', letterSpacing: '-0.02em' }}>{u.name}</h3>
        <p style={{ fontSize: '0.9rem', color: 'var(--muted-foreground)', marginBottom: '1.5rem', fontWeight: 600 }}>{u.location}</p>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem', marginBottom: '1.5rem' }}>
          <div className="glass" style={{ padding: '1rem', borderRadius: '12px', textAlign: 'center' }}>
            <div style={{ fontSize: '0.65rem', fontWeight: 900, color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Staff</div>
            <div style={{ fontWeight: 900, fontSize: '1.25rem' }}>{u.user_units?.[0]?.count || 0}</div>
          </div>
          <div className="glass" style={{ padding: '1rem', borderRadius: '12px', textAlign: 'center' }}>
            <div style={{ fontSize: '0.65rem', fontWeight: 900, color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Estatus</div>
            <div style={{ fontWeight: 900, fontSize: '1rem', color: '#0d9488' }}>OPEN</div>
          </div>
        </div>
        <button onClick={() => onEdit(u)} className="btn-primary" style={{ width: '100%', padding: '1rem', borderRadius: '12px', background: 'transparent', border: '1px solid var(--border)', color: 'var(--foreground)', fontWeight: 800, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '0.5rem' }}>
          Configurar <Settings size={16} />
        </button>
      </div>
    ))}
  </div>
);

const ClientsTab = ({ profiles, onRegister, onAssign, onDelete }: any) => (
  <div className="card-premium" style={{ padding: 0, overflow: 'hidden' }}>
    <div style={{ padding: '2rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderBottom: '1px solid var(--border)', flexWrap: 'wrap', gap: '1rem' }}>
      <div>
        <h3 style={{ fontWeight: 900, fontSize: '1.4rem' }}>Base Maestro</h3>
        <p style={{ fontSize: '0.85rem', color: 'var(--muted-foreground)', fontWeight: 600 }}>Gestión de identidades y accesos.</p>
      </div>
      <button onClick={onRegister} className="btn-primary" style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', padding: '0.8rem 1.4rem', background: '#0d9488', borderRadius: '12px' }}>
        <UserPlus size={20} /> Nuevo Cliente
      </button>
    </div>
    <div style={{ overflowX: 'auto' }}>
      <table style={{ width: '100%', borderCollapse: 'collapse' }}>
        <thead>
          <tr style={{ background: 'var(--secondary)', textAlign: 'left' }}>
            <th style={tableHeaderStyle}>Identidad</th>
            <th style={tableHeaderStyle}>Permisos</th>
            <th style={tableHeaderStyle}>Asignaciones</th>
            <th style={{ ...tableHeaderStyle, textAlign: 'right' }}>Acciones</th>
          </tr>
        </thead>
        <tbody>
          {profiles.map((p: any) => (
            <tr key={p.id} style={{ borderBottom: '1px solid var(--border)' }}>
              <td style={tableCellStyle}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                  <div style={{ width: '32px', height: '32px', borderRadius: '8px', background: '#0d9488', color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '0.75rem', fontWeight: 900 }}>{p.full_name?.[0]}</div>
                  <div>
                    <div style={{ fontWeight: 900, fontSize: '0.95rem' }}>{p.full_name}</div>
                    <div style={{ fontSize: '0.7rem', color: 'var(--muted-foreground)', fontWeight: 600 }}>{p.email}</div>
                  </div>
                </div>
              </td>
              <td style={tableCellStyle}>
                <span style={{ padding: '0.3rem 0.8rem', borderRadius: '8px', background: p.is_superadmin ? 'rgba(13,148,136,0.1)' : 'var(--secondary)', color: p.is_superadmin ? '#0d9488' : 'inherit', fontSize: '0.65rem', fontWeight: 900 }}>
                  {p.is_superadmin ? 'ROOT ACCESS' : 'STANDARD CLIENT'}
                </span>
              </td>
              <td style={tableCellStyle}>
                <div style={{ display: 'flex', gap: '0.4rem', flexWrap: 'wrap' }}>
                  {p.user_units?.map((uu: any, i: number) => (
                    <span key={i} className="glass" style={{ padding: '4px 10px', borderRadius: '8px', fontSize: '0.65rem', fontWeight: 800 }}>{uu.units.name}</span>
                  ))}
                  {(!p.user_units || p.user_units.length === 0) && <span style={{ fontSize: '0.75rem', color: 'var(--muted-foreground)', fontWeight: 600 }}>Sin Granjas</span>}
                </div>
              </td>
              <td style={{ ...tableCellStyle, textAlign: 'right' }}>
                <div style={{ display: 'flex', gap: '0.5rem', justifyContent: 'flex-end' }}>
                  <button onClick={() => onAssign(p)} className="btn-primary" style={{ padding: '0.5rem 1rem', fontSize: '0.75rem', background: '#0d9488', borderRadius: '8px' }}>Asignar</button>
                  <button onClick={() => onDelete(p.id)} style={{ padding: '0.5rem', color: '#ef4444', background: 'rgba(239, 68, 68, 0.05)', border: 'none', borderRadius: '8px', cursor: 'pointer' }}><Trash2 size={18} /></button>
                </div>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  </div>
);

const BillingTab = ({ subscriptions, onRefresh }: { subscriptions: SuperAdminSubscription[], onRefresh: () => void }) => {
  const [planPrice, setPlanPrice] = useState(100000);

  useEffect(() => {
    async function loadPrice() {
      try {
        const { data } = await supabase
          .from('app_config')
          .select('value')
          .eq('key', 'global_settings')
          .maybeSingle();
        if (data?.value) {
          const parsed = typeof data.value === 'string' ? JSON.parse(data.value) : data.value;
          setPlanPrice(parsed.price ?? 100000);
        }
      } catch (err) {
        console.error("Error loading plan price in BillingTab:", err);
      }
    }
    loadPrice();
  }, []);

  const handleStartFreeTrial = async (sub: any) => {
    if (!confirm(`¿Confirmas iniciar periodo de prueba gratis de 30 días para ${sub.units.name}?`)) return;
    
    const trialPromise = async () => {
      const nextBillingDate = new Date();
      nextBillingDate.setDate(nextBillingDate.getDate() + 30);

      const subscriptionData = {
        unit_id: sub.unit_id,
        plan_type: 'basic',
        status: 'active',
        price: 0,
        next_billing_date: nextBillingDate.toISOString(),
        trial_activated_at: new Date().toISOString()
      };

      if (sub.id.startsWith('temp-')) {
        const { error } = await supabase.from('subscriptions').insert([subscriptionData]);
        if (error) throw error;
      } else {
        const { error } = await supabase.from('subscriptions').update(subscriptionData).eq('id', sub.id);
        if (error) throw error;
      }
      onRefresh();
    };

    toast.promise(trialPromise(), {
      loading: 'Iniciando periodo gratis...',
      success: 'Periodo de prueba gratis de 30 días iniciado con éxito.',
      error: 'Error al iniciar periodo de prueba gratis.'
    });
  };

  const handleManualRenewal = async (sub: any) => {
    if (!confirm(`¿Confirmas renovación manual de $${planPrice.toLocaleString('es-CO')} COP para ${sub.units.name}?`)) return;
    
    const renewPromise = async () => {
      const newNextDate = new Date();
      newNextDate.setDate(newNextDate.getDate() + 30);

      if (sub.id.startsWith('temp-')) {
        const { error } = await supabase.from('subscriptions').insert([{ 
          unit_id: sub.unit_id,
          status: 'active', 
          plan_type: 'basic',
          next_billing_date: newNextDate.toISOString(),
          price: planPrice
        }]);
        if (error) throw error;
      } else {
        const { error } = await supabase.from('subscriptions').update({ 
          status: 'active', 
          next_billing_date: newNextDate.toISOString(),
          price: planPrice
        }).eq('id', sub.id);
        if (error) throw error;
      }
      onRefresh();
    };

    toast.promise(renewPromise(), {
      loading: 'Registrando pago manual...',
      success: 'Suscripción renovada por 30 días.',
      error: 'Error al renovar suscripción.'
    });
  };

  const handleToggleStatus = async (sub: any, currentStatus: string) => {
    const isCurrentlyActive = currentStatus === 'active';
    const newStatus = isCurrentlyActive ? 'canceled' : 'active';
    const actionText = isCurrentlyActive ? 'suspender' : 'activar';
    
    if (!confirm(`¿Confirmas ${actionText} la suscripción para ${sub.units.name}?`)) return;
    
    const toggleStatusPromise = async () => {
      if (sub.id.startsWith('temp-')) {
        const nextDate = new Date();
        nextDate.setDate(nextDate.getDate() + 30);
        const { error } = await supabase.from('subscriptions').insert([{
          unit_id: sub.unit_id,
          status: newStatus,
          plan_type: 'basic',
          price: 0, // First month free welcome promotion
          next_billing_date: nextDate.toISOString()
        }]);
        if (error) throw error;
      } else {
        const { error } = await supabase.from('subscriptions').update({
          status: newStatus
        }).eq('id', sub.id);
        if (error) throw error;
      }
      onRefresh();
    };

    toast.promise(toggleStatusPromise(), {
      loading: `${isCurrentlyActive ? 'Suspendiendo' : 'Activando'} acceso...`,
      success: `Suscripción ${isCurrentlyActive ? 'suspendida' : 'activada'} correctamente.`,
      error: 'Error al cambiar estado de acceso.'
    });
  };

  const handleResetAllSubscriptions = async () => {
    if (!confirm("¿Confirmas que deseas REINICIAR todas las suscripciones a estado INACTIVO (cancelado)? Esto establecerá las suscripciones actuales en tarifa de $0 COP para que puedan comenzar su mes de bienvenida gratis al activar su acceso.")) return;
    
    const resetPromise = async () => {
      // 1. Obtener todas las suscripciones existentes
      const { data: subs, error: fetchError } = await supabase
        .from('subscriptions')
        .select('id');
      
      if (fetchError) throw fetchError;
      
      if (subs && subs.length > 0) {
        // 2. Actualizar cada una a estado inactivo (canceled) y tarifa de $0 COP (mes gratis de bienvenida)
        const promises = subs.map((s: any) => 
          supabase
            .from('subscriptions')
            .update({
              status: 'canceled',
              price: 0,
              next_billing_date: new Date().toISOString()
            })
            .eq('id', s.id)
        );
        
        const results = await Promise.all(promises);
        const firstError = results.find((r: any) => r.error)?.error;
        if (firstError) throw firstError;
      }
      
      onRefresh();
    };

    toast.promise(resetPromise(), {
      loading: 'Restableciendo suscripciones a inactivas...',
      success: 'Todas las suscripciones han sido reiniciadas. Listas para activar el mes gratis.',
      error: 'Error al reiniciar suscripciones.'
    });
  };

  return (
    <div className="card-premium" style={{ padding: 0 }}>
       <div style={{ 
         padding: '2rem', 
         borderBottom: '1px solid var(--border)',
         display: 'flex',
         justifyContent: 'space-between',
         alignItems: 'center',
         flexWrap: 'wrap',
         gap: '1rem'
       }}>
          <div>
             <h3 style={{ fontWeight: 900, fontSize: '1.4rem' }}>Facturación Global (COP)</h3>
             <p style={{ fontSize: '0.85rem', color: 'var(--muted-foreground)', fontWeight: 600 }}>Recaudación manual y control de accesos de clientes.</p>
          </div>
          <button
            onClick={handleResetAllSubscriptions}
            style={{
              padding: '0.6rem 1.25rem',
              fontSize: '0.75rem',
              fontWeight: 800,
              borderRadius: '8px',
              border: '1px solid #ef4444',
              background: 'rgba(239, 68, 68, 0.1)',
              color: '#ef4444',
              cursor: 'pointer',
              transition: 'all 0.2s'
            }}
            onMouseOver={(e) => {
              e.currentTarget.style.background = 'rgba(239, 68, 68, 0.2)';
            }}
            onMouseOut={(e) => {
              e.currentTarget.style.background = 'rgba(239, 68, 68, 0.1)';
            }}
          >
            Reiniciar Facturación (Vaciar DB)
          </button>
       </div>
       <div style={{ overflowX: 'auto' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse' }}>
             <thead style={{ background: 'var(--secondary)', textAlign: 'left' }}>
               <tr>
                 <th style={tableHeaderStyle}>Granja / Cliente</th>
                 <th style={tableHeaderStyle}>Plan / Tarifa</th>
                 <th style={tableHeaderStyle}>Estatus de Acceso</th>
                 <th style={tableHeaderStyle}>Próximo Cobro</th>
                 <th style={{ ...tableHeaderStyle, textAlign: 'right' }}>Acciones Maestras</th>
               </tr>
             </thead>
             <tbody>
               {subscriptions.map((s: any) => {
                 const isExpired = new Date(s.next_billing_date) < new Date();
                 const isSuspended = s.status === 'canceled' || s.status === 'suspended';
                 const isActive = s.status === 'active' && !isExpired;
                 
                 return (
                   <tr key={s.id} style={{ borderBottom: '1px solid var(--border)' }}>
                     <td style={tableCellStyle}>
                        <div style={{ fontWeight: 900, fontSize: '0.95rem' }}>{s.units.name}</div>
                        <div style={{ fontSize: '0.7rem', color: 'var(--muted-foreground)', fontWeight: 700 }}>TITULAR: {s.client_name}</div>
                     </td>
                     <td style={tableCellStyle}>
                        <div style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
                           <span style={{ 
                             padding: '4px 10px', 
                             borderRadius: '12px', 
                             background: s.price === 0 ? 'linear-gradient(135deg, #10b981, #059669)' : 'rgba(13,148,136,0.1)', 
                             color: s.price === 0 ? 'white' : '#0d9488', 
                             fontSize: '0.65rem', 
                             fontWeight: 900,
                             width: 'fit-content',
                             letterSpacing: '0.05em'
                           }}>
                             {s.price === 0 ? 'MES GRATIS DE CORTESÍA' : 'PLAN ÚNICO'}
                           </span>
                           <span style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--muted-foreground)' }}>
                             {s.price === 0 ? 'Próxima renovación: $100.000 COP' : `$${(s.price || 0).toLocaleString('es-CO')} COP/mes`}
                           </span>
                        </div>
                     </td>
                     <td style={tableCellStyle}>
                       <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', color: isExpired || isSuspended ? '#ef4444' : '#10b981', fontWeight: 900, fontSize: '0.75rem' }}>
                         {isExpired || isSuspended ? <AlertCircle size={14} /> : <CheckCircle2 size={14} />}
                         {isSuspended ? 'SUSPENDIDO' : (isExpired ? 'VENCIDO' : 'ACTIVO')}
                       </div>
                     </td>
                     <td style={tableCellStyle}>
                        <span style={{ fontWeight: 700, fontSize: '0.85rem', color: isExpired ? '#ef4444' : 'inherit' }}>
                          {new Date(s.next_billing_date).toLocaleDateString('es-CO')}
                        </span>
                     </td>
                     <td style={{ ...tableCellStyle, textAlign: 'right' }}>
                       <div style={{ display: 'flex', gap: '0.6rem', justifyContent: 'flex-end', alignItems: 'center' }}>
                         {(!s.trial_activated_at || s.status !== 'active') && (
                           <button 
                             onClick={() => handleStartFreeTrial(s)}
                             style={{ 
                               padding: '0.6rem 1.1rem', 
                               fontSize: '0.75rem', 
                               fontWeight: 800,
                               borderRadius: '8px',
                               border: '1px solid #8b5cf6',
                               background: 'rgba(139, 92, 246, 0.1)',
                               color: '#a78bfa',
                               cursor: 'pointer',
                               transition: 'all 0.2s',
                               display: 'flex',
                               alignItems: 'center',
                               gap: '0.4rem'
                             }}
                             onMouseOver={(e) => {
                               e.currentTarget.style.background = 'rgba(139, 92, 246, 0.2)';
                             }}
                             onMouseOut={(e) => {
                               e.currentTarget.style.background = 'rgba(139, 92, 246, 0.1)';
                             }}
                           >
                             <Sparkles size={14} /> Iniciar periodo gratis
                           </button>
                         )}
                         <button 
                           onClick={() => handleToggleStatus(s, s.status)}
                           style={{ 
                             padding: '0.6rem 1.1rem', 
                             fontSize: '0.75rem', 
                             fontWeight: 800,
                             borderRadius: '8px',
                             border: `1px solid ${s.status === 'active' ? '#ef4444' : '#10b981'}`,
                             background: 'transparent',
                             color: s.status === 'active' ? '#ef4444' : '#10b981',
                             cursor: 'pointer',
                             transition: 'all 0.2s'
                           }}
                         >
                           {s.status === 'active' ? 'Suspender Acceso' : 'Activar Acceso'}
                         </button>
                         <button 
                           onClick={() => handleManualRenewal(s)}
                           className="btn-primary" 
                           style={{ 
                             padding: '0.6rem 1.25rem', 
                             fontSize: '0.75rem', 
                             display: 'flex', 
                             alignItems: 'center', 
                             gap: '0.4rem', 
                             background: '#0d9488', 
                             borderRadius: '8px',
                             fontWeight: 800
                           }}
                         >
                           <DollarSign size={14} /> Registrar Pago
                         </button>
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

const SupportTab = ({ tickets, onRefresh }: { tickets: SuperAdminTicket[], onRefresh: () => void }) => {
  const [selectedTicket, setSelectedTicket] = useState<SuperAdminTicket | null>(null);
  const [response, setResponse] = useState('');

  const handleUpdateStatus = async (id: string, newStatus: string) => {
    const { error } = await supabase.from('support_tickets').update({ status: newStatus }).eq('id', id);
    if (!error) {
      toast.success("Ticket actualizado.");
      onRefresh();
    }
  };

  const handleSendResponse = async () => {
    toast.success(`Respuesta enviada a ${selectedTicket?.profiles?.full_name}`);
    if (selectedTicket) {
      await handleUpdateStatus(selectedTicket.id, 'resolved');
    }
    setSelectedTicket(null);
    setResponse('');
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
      {tickets.map((t: SuperAdminTicket) => (
        <div key={t.id} className="card-premium" style={{ padding: '2rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: '2rem', flexWrap: 'wrap' }}>
          <div style={{ display: 'flex', gap: '1.5rem', alignItems: 'center' }}>
            <div style={{ 
              width: '56px', height: '56px', 
              background: t.priority === 'high' ? 'rgba(239, 68, 68, 0.1)' : 'rgba(13, 148, 136, 0.1)', 
              color: t.priority === 'high' ? '#ef4444' : '#0d9488', 
              borderRadius: '16px', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 
            }}>
              <MessageSquare size={28} />
            </div>
            <div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', marginBottom: '0.4rem' }}>
                <h4 style={{ fontWeight: 900, fontSize: '1.25rem', letterSpacing: '-0.02em' }}>{t.subject}</h4>
                <span className="glass" style={{ fontSize: '0.65rem', fontWeight: 900, padding: '4px 10px', borderRadius: '6px' }}>#{t.id.slice(0, 5).toUpperCase()}</span>
              </div>
              <p style={{ fontSize: '0.9rem', color: 'var(--muted-foreground)', marginBottom: '0.75rem', fontWeight: 600, lineHeight: 1.5 }}>{t.description}</p>
              <div style={{ display: 'flex', gap: '1.5rem', alignItems: 'center', flexWrap: 'wrap' }}>
                <span style={{ fontSize: '0.75rem', color: '#0d9488', fontWeight: 900 }}>BY: {t.profiles?.full_name?.toUpperCase()}</span>
                <span style={{ fontSize: '0.75rem', fontWeight: 900, color: t.status === 'open' ? '#f59e0b' : '#0d9488' }}>• STATUS: {t.status.toUpperCase()}</span>
              </div>
            </div>
          </div>
          <div style={{ display: 'flex', gap: '0.75rem' }}>
            <button 
              onClick={() => setSelectedTicket(t)}
              className="btn-primary" 
              style={{ padding: '0.8rem 1.6rem', fontSize: '0.9rem', fontWeight: 900, background: '#0d9488', borderRadius: '12px' }}
            >
              Atender Ticket
            </button>
            {t.status !== 'resolved' && (
              <button 
                onClick={() => handleUpdateStatus(t.id, 'resolved')}
                style={{ padding: '0.8rem', borderRadius: '12px', border: '1px solid var(--border)', background: 'transparent', cursor: 'pointer' }}
              >
                <CheckCircle2 size={22} color="#0d9488" />
              </button>
            )}
          </div>
        </div>
      ))}
      
      {tickets.length === 0 && (
        <div style={{ textAlign: 'center', padding: '8rem 2rem', background: 'var(--secondary)', borderRadius: '32px', border: '2px dashed var(--border)' }}>
          <MessageSquare size={56} style={{ margin: '0 auto 2rem', opacity: 0.15 }} />
          <h3 style={{ fontWeight: 900, color: 'var(--muted-foreground)', fontSize: '1.5rem' }}>Bandeja Vacía</h3>
          <p style={{ fontSize: '1rem', color: 'var(--muted-foreground)', fontWeight: 600 }}>No hay tickets que requieran atención inmediata.</p>
        </div>
      )}

      <AnimatePresence>
        {selectedTicket && (
          <Modal title="Responder Ticket" onClose={() => setSelectedTicket(null)}>
            <div style={{ marginBottom: '2rem' }}>
              <p style={{ fontSize: '0.75rem', fontWeight: 900, color: 'var(--muted-foreground)', textTransform: 'uppercase', marginBottom: '0.75rem' }}>Consulta Original</p>
              <div className="glass" style={{ padding: '1.25rem', borderRadius: '14px', fontSize: '0.95rem', fontWeight: 600, fontStyle: 'italic', lineHeight: 1.5 }}>
                "{selectedTicket.description}"
              </div>
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem', marginBottom: '2.5rem' }}>
              <label className="premium-label">Tu Respuesta Técnica</label>
              <textarea 
                rows={5} 
                placeholder="Detalla aquí la solución..." 
                value={response}
                onChange={(e) => setResponse(e.target.value)}
                className="premium-input"
                style={{ resize: 'none', fontWeight: 600 }}
              />
            </div>
            <button 
              onClick={handleSendResponse}
              disabled={!response}
              className="btn-primary" 
              style={{ width: '100%', padding: '1.25rem', fontWeight: 900, background: '#0d9488', borderRadius: '16px', opacity: response ? 1 : 0.4 }}
            >
              Enviar y Cerrar Ticket
            </button>
          </Modal>
        )}
      </AnimatePresence>
    </div>
  );
};

const StatCard = ({ label, value, icon: Icon, color }: any) => (
  <div className="card-premium" style={{ padding: '1.75rem', display: 'flex', alignItems: 'center', gap: '1.5rem' }}>
    <div style={{ padding: '0.8rem', background: `${color}10`, borderRadius: '16px', color }}><Icon size={28} /></div>
    <div>
      <div style={{ fontSize: '0.75rem', color: 'var(--muted-foreground)', fontWeight: 900, textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: '0.2rem' }}>{label}</div>
      <div style={{ fontSize: '2rem', fontWeight: 900, letterSpacing: '-0.03em' }}>{value}</div>
    </div>
  </div>
);

const SectionCard = ({ title, children }: any) => (
  <div className="card-premium" style={{ padding: '2rem' }}>
    <h3 style={{ fontWeight: 900, fontSize: '1.2rem', marginBottom: '2rem', letterSpacing: '-0.02em' }}>{title}</h3>
    {children}
  </div>
);

const Modal = ({ title, children, onClose }: any) => (
  <div style={{ position: 'fixed', inset: 0, background: 'rgba(2, 6, 23, 0.7)', backdropFilter: 'blur(16px)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000, padding: '1.5rem' }}>
    <motion.div initial={{ scale: 0.9, opacity: 0 }} animate={{ scale: 1, opacity: 1 }} className="card-premium" style={{ width: '100%', maxWidth: '520px', padding: '3rem', position: 'relative', borderRadius: '32px' }}>
      <button onClick={onClose} style={{ position: 'absolute', top: '2rem', right: '2rem', background: 'none', border: 'none', color: 'var(--muted-foreground)', cursor: 'pointer' }}><X size={28} /></button>
      <h2 style={{ fontSize: '2rem', fontWeight: 900, marginBottom: '2.5rem', letterSpacing: '-0.04em' }}>{title}</h2>
      {children}
    </motion.div>
  </div>
);

const InputGroup = ({ label, value, onChange, type = 'text', placeholder }: any) => (
  <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
    <label className="premium-label">{label}</label>
    <input type={type} placeholder={placeholder} value={value} onChange={(e) => onChange(e.target.value)} className="premium-input" style={{ fontWeight: 600 }} required />
  </div>
);

const labelStyle = { fontSize: '0.75rem', fontWeight: 900, color: 'var(--muted-foreground)', textTransform: 'uppercase' as const, letterSpacing: '0.05em' };
const inputStyle = { width: '100%', padding: '1rem 1.4rem', borderRadius: '14px', border: '1px solid var(--border)', background: 'var(--secondary)', outline: 'none', fontSize: '1rem' };
const tableHeaderStyle = { padding: '1.25rem 2rem', fontSize: '0.75rem', fontWeight: 900, color: 'var(--muted-foreground)', textTransform: 'uppercase' as const, letterSpacing: '0.05em' };
const tableCellStyle = { padding: '1.5rem 2rem' };
