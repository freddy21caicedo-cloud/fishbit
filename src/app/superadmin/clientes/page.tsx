'use client';

import { useEffect, useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { supabase } from '@/lib/supabase';
import { toast } from 'react-hot-toast';
import { 
  Users, 
  Search, 
  UserPlus, 
  MoreVertical, 
  Mail, 
  Shield, 
  Building2, 
  CheckCircle2, 
  XCircle,
  Loader2,
  Filter
} from 'lucide-react';

export default function ClientsManagementPage() {
  const [profiles, setProfiles] = useState<any[]>([]);
  const [units, setUnits] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [isAssignModalOpen, setIsAssignModalOpen] = useState(false);
  const [selectedUser, setSelectedUser] = useState<any>(null);
  const [selectedUnitId, setSelectedUnitId] = useState('');
  const [selectedRole, setSelectedRole] = useState('admin');

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    setLoading(true);
    // Fetch all profiles and their unit assignments
    const { data: pData } = await supabase
      .from('profiles')
      .select(`
        *,
        user_units(
          role,
          units(name)
        )
      `)
      .order('created_at', { ascending: false });
    
    const { data: uData } = await supabase.from('units').select('*');
    
    setProfiles(pData || []);
    setUnits(uData || []);
    setLoading(false);
  };

  const handleAssignUnit = async (e: React.FormEvent) => {
    e.preventDefault();
    const { error } = await supabase
      .from('user_units')
      .insert([{ 
        user_id: selectedUser.id, 
        unit_id: selectedUnitId, 
        role: selectedRole 
      }]);

    if (!error) {
      setIsAssignModalOpen(false);
      fetchData();
      toast.success('Unidad asignada correctamente.');
    } else {
      toast.error("Error: " + error.message);
    }
  };

  if (loading) {
    return (
      <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <Loader2 className="animate-spin" size={40} color="var(--primary)" />
      </div>
    );
  }

  return (
    <div style={{ padding: '2rem', maxWidth: '1200px', margin: '0 auto' }}>
      <header style={{ marginBottom: '3rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <h1 style={{ fontSize: '2rem', fontWeight: 800, marginBottom: '0.5rem' }}>Gestión de Clientes</h1>
          <p style={{ color: 'var(--muted-foreground)' }}>Administra el acceso de los productores a sus unidades acuícolas.</p>
        </div>
        <div style={{ display: 'flex', gap: '1rem' }}>
          <div style={{ position: 'relative' }}>
            <Search size={18} style={{ position: 'absolute', left: '1rem', top: '50%', transform: 'translateY(-50%)', color: 'var(--muted-foreground)' }} />
            <input 
              type="text" 
              placeholder="Buscar por nombre o ID..." 
              style={{ padding: '0.75rem 1rem 0.75rem 2.75rem', borderRadius: '12px', border: '1px solid var(--border)', background: 'var(--card)', width: '300px', outline: 'none' }}
            />
          </div>
          <button className="btn-primary" style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', padding: '0.75rem 1.5rem' }}>
            <Filter size={18} />
            Filtros
          </button>
        </div>
      </header>

      <div className="card-premium" style={{ padding: 0, overflow: 'hidden' }}>
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <thead>
            <tr style={{ textAlign: 'left', background: 'rgba(0,0,0,0.02)' }}>
              <th style={{ padding: '1.25rem 1.5rem', fontSize: '0.75rem', fontWeight: 800, color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Usuario</th>
              <th style={{ padding: '1.25rem 1.5rem', fontSize: '0.75rem', fontWeight: 800, color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Estado / Rol</th>
              <th style={{ padding: '1.25rem 1.5rem', fontSize: '0.75rem', fontWeight: 800, color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Unidades Asignadas</th>
              <th style={{ padding: '1.25rem 1.5rem', textAlign: 'right' }}>Acciones</th>
            </tr>
          </thead>
          <tbody>
            {profiles.map((profile) => (
              <tr key={profile.id} style={{ borderTop: '1px solid var(--border)', transition: 'background 0.2s' }}>
                <td style={{ padding: '1.25rem 1.5rem' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                    <div style={{ width: '40px', height: '40px', borderRadius: '12px', background: 'var(--secondary)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 700, color: 'var(--primary)' }}>
                      {profile.full_name?.[0] || 'U'}
                    </div>
                    <div>
                      <div style={{ fontWeight: 700 }}>{profile.full_name || 'Sin nombre'}</div>
                      <div style={{ fontSize: '0.75rem', color: 'var(--muted-foreground)', display: 'flex', alignItems: 'center', gap: '0.25rem' }}>
                        <Mail size={12} />
                        {profile.id.slice(0, 8)}...
                      </div>
                    </div>
                  </div>
                </td>
                <td style={{ padding: '1.25rem 1.5rem' }}>
                  {profile.is_superadmin ? (
                    <span style={{ padding: '0.25rem 0.75rem', borderRadius: '20px', background: 'rgba(37, 99, 235, 0.1)', color: 'var(--primary)', fontSize: '0.7rem', fontWeight: 800 }}>SuperAdmin</span>
                  ) : (
                    <span style={{ padding: '0.25rem 0.75rem', borderRadius: '20px', background: 'rgba(16, 185, 129, 0.1)', color: '#10b981', fontSize: '0.7rem', fontWeight: 800 }}>Cliente Activo</span>
                  )}
                </td>
                <td style={{ padding: '1.25rem 1.5rem' }}>
                  <div style={{ display: 'flex', flexWrap: 'wrap', gap: '0.5rem' }}>
                    {profile.user_units?.length > 0 ? (
                      profile.user_units.map((uu: any, idx: number) => (
                        <div key={idx} style={{ padding: '0.25rem 0.5rem', background: 'var(--secondary)', borderRadius: '6px', fontSize: '0.75rem', display: 'flex', alignItems: 'center', gap: '0.25rem' }}>
                          <Building2 size={12} />
                          {uu.units.name} ({uu.role})
                        </div>
                      ))
                    ) : (
                      <span style={{ fontSize: '0.75rem', color: 'var(--muted-foreground)', fontStyle: 'italic' }}>Sin asignar</span>
                    )}
                  </div>
                </td>
                <td style={{ padding: '1.25rem 1.5rem', textAlign: 'right' }}>
                  <button 
                    onClick={() => {
                      setSelectedUser(profile);
                      setIsAssignModalOpen(true);
                    }}
                    style={{ padding: '0.5rem 1rem', borderRadius: '8px', border: '1px solid var(--primary)', background: 'transparent', color: 'var(--primary)', fontWeight: 700, fontSize: '0.8rem', cursor: 'pointer', display: 'inline-flex', alignItems: 'center', gap: '0.4rem' }}
                  >
                    <UserPlus size={16} />
                    Asignar Unidad
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Assign Modal */}
      <AnimatePresence>
        {isAssignModalOpen && (
          <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.5)', backdropFilter: 'blur(4px)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 200 }}>
            <motion.div 
              initial={{ scale: 0.95, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.95, opacity: 0 }}
              className="card-premium" 
              style={{ width: '100%', maxWidth: '450px', padding: '2rem' }}
            >
              <h2 style={{ fontSize: '1.5rem', fontWeight: 800, marginBottom: '0.5rem' }}>Asignar Unidad</h2>
              <p style={{ color: 'var(--muted-foreground)', fontSize: '0.9rem', marginBottom: '2rem' }}>Asigna a <b>{selectedUser?.full_name}</b> a una unidad de producción.</p>
              
              <form onSubmit={handleAssignUnit} style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
                <div>
                  <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 800, color: 'var(--muted-foreground)', marginBottom: '0.5rem', textTransform: 'uppercase' }}>Seleccionar Unidad</label>
                  <select 
                    required 
                    value={selectedUnitId}
                    onChange={(e) => setSelectedUnitId(e.target.value)}
                    style={{ width: '100%', padding: '0.75rem 1rem', borderRadius: '10px', border: '1px solid var(--border)', background: 'var(--secondary)', outline: 'none' }}
                  >
                    <option value="">Selecciona una unidad...</option>
                    {units.map(u => (
                      <option key={u.id} value={u.id}>{u.name}</option>
                    ))}
                  </select>
                </div>
                <div>
                  <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 800, color: 'var(--muted-foreground)', marginBottom: '0.5rem', textTransform: 'uppercase' }}>Rol en la Unidad</label>
                  <select 
                    value={selectedRole}
                    onChange={(e) => setSelectedRole(e.target.value)}
                    style={{ width: '100%', padding: '0.75rem 1rem', borderRadius: '10px', border: '1px solid var(--border)', background: 'var(--secondary)', outline: 'none' }}
                  >
                    <option value="admin">Administrador</option>
                    <option value="tecnico">Técnico Acuícola</option>
                    <option value="operario">Operario</option>
                  </select>
                </div>
                <div style={{ display: 'flex', gap: '1rem', marginTop: '1rem' }}>
                  <button type="button" onClick={() => setIsAssignModalOpen(false)} style={{ flex: 1, padding: '0.75rem', borderRadius: '10px', border: '1px solid var(--border)', background: 'none', fontWeight: 700, cursor: 'pointer' }}>Cancelar</button>
                  <button type="submit" className="btn-primary" style={{ flex: 1, padding: '0.75rem', borderRadius: '10px', fontWeight: 700 }}>Confirmar Asignación</button>
                </div>
              </form>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </div>
  );
}
