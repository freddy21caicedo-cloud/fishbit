'use client';

import { useEffect, useState } from 'react';
import { supabase } from '@/lib/supabase';
import { User, Mail, Shield, ArrowLeft, Camera, LogOut, Pencil, X, Save, Lock, Eye, EyeOff, CheckCircle2 } from 'lucide-react';
import { useRouter } from 'next/navigation';
import { motion, AnimatePresence } from 'framer-motion';
import { toast } from 'react-hot-toast';
import { useLogout } from '../hooks/useLogout';

export default function ProfilePage() {
  const router = useRouter();
  const logout = useLogout();
  const [profile, setProfile] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  // Edit modal state
  const [isEditOpen, setIsEditOpen] = useState(false);
  const [editName, setEditName] = useState('');
  const [isSavingName, setIsSavingName] = useState(false);

  // Password change state
  const [currentPassword, setCurrentPassword] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showCurrent, setShowCurrent] = useState(false);
  const [showNew, setShowNew] = useState(false);
  const [showConfirm, setShowConfirm] = useState(false);
  const [isSavingPassword, setIsSavingPassword] = useState(false);
  const [passwordSuccess, setPasswordSuccess] = useState(false);

  useEffect(() => {
    async function getProfile() {
      const { data: { user } } = await supabase.auth.getUser();
      if (user) {
        const { data } = await supabase
          .from('profiles')
          .select('*')
          .eq('id', user.id)
          .single();
        setProfile({ ...data, email: user.email });
      }
      setLoading(false);
    }
    getProfile();
  }, []);

  const handleOpenEdit = () => {
    setEditName(profile?.full_name || '');
    setCurrentPassword('');
    setNewPassword('');
    setConfirmPassword('');
    setPasswordSuccess(false);
    setIsEditOpen(true);
  };

  const handleSaveName = async () => {
    if (!editName.trim()) return;
    setIsSavingName(true);
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) { setIsSavingName(false); return; }

    const { error } = await supabase
      .from('profiles')
      .update({ full_name: editName.trim() })
      .eq('id', user.id);

    if (error) {
      toast.error('Error al guardar el nombre.');
    } else {
      setProfile((prev: any) => ({ ...prev, full_name: editName.trim() }));
      toast.success('Nombre actualizado correctamente.');
    }
    setIsSavingName(false);
  };

  const handleChangePassword = async () => {
    if (!newPassword || newPassword.length < 6) {
      toast.error('La contraseña debe tener al menos 6 caracteres.');
      return;
    }
    if (newPassword !== confirmPassword) {
      toast.error('Las contraseñas nuevas no coinciden.');
      return;
    }
    setIsSavingPassword(true);
    const { error } = await supabase.auth.updateUser({ password: newPassword });
    if (error) {
      toast.error('Error al cambiar la contraseña: ' + error.message);
    } else {
      setPasswordSuccess(true);
      setCurrentPassword('');
      setNewPassword('');
      setConfirmPassword('');
      toast.success('¡Contraseña actualizada exitosamente!');
    }
    setIsSavingPassword(false);
  };


  if (loading) return null;

  const inputStyle: React.CSSProperties = {
    width: '100%',
    padding: '0.85rem 1rem',
    borderRadius: '12px',
    border: '1px solid var(--border)',
    background: 'var(--secondary)',
    color: 'var(--foreground)',
    fontSize: '0.95rem',
    fontWeight: 600,
    outline: 'none',
    boxSizing: 'border-box',
  };

  return (
    <div className="animate-fade-in page-container">
      <header style={{ marginBottom: '3rem', display: 'flex', alignItems: 'center', gap: '1rem' }}>
        <button onClick={() => router.back()} className="glass" style={{ padding: '0.6rem', borderRadius: '12px', border: '1px solid var(--border)', cursor: 'pointer' }}>
          <ArrowLeft size={20} />
        </button>
        <h1 style={{ fontWeight: 900, letterSpacing: '-0.04em' }}>Mi Perfil</h1>
      </header>

      <div style={{ maxWidth: '900px', margin: '0 auto' }}>
        <div className="card-premium" style={{ padding: '3rem', position: 'relative', overflow: 'hidden' }}>
          {/* Cover Decor */}
          <div style={{ position: 'absolute', top: 0, left: 0, right: 0, height: '120px', background: 'linear-gradient(135deg, #0d9488 0%, #065f46 100%)', zIndex: 0 }} />

          <div style={{ position: 'relative', zIndex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
            <div style={{ position: 'relative', marginBottom: '1.5rem' }}>
              <div style={{ width: '120px', height: '120px', borderRadius: '40px', background: 'var(--card)', border: '6px solid var(--card)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#0d9488', boxShadow: '0 10px 30px rgba(0,0,0,0.1)' }}>
                <User size={64} />
              </div>
              <button style={{ position: 'absolute', bottom: '-5px', right: '-5px', background: 'white', color: '#0d9488', padding: '0.5rem', borderRadius: '12px', border: '1px solid var(--border)', cursor: 'pointer', boxShadow: 'var(--shadow-md)' }}>
                <Camera size={18} />
              </button>
            </div>

            <h2 style={{ fontSize: '2rem', fontWeight: 900, marginBottom: '0.25rem', letterSpacing: '-0.04em' }}>
              {profile?.full_name || 'Usuario FishBit'}
            </h2>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', color: 'var(--muted-foreground)', fontWeight: 700, fontSize: '0.9rem', marginBottom: '2.5rem' }}>
              <span className="glass" style={{ padding: '4px 12px', borderRadius: '20px', background: 'rgba(13, 148, 136, 0.1)', color: '#0d9488', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                {profile?.is_superadmin ? 'Super Administrador' : 'Administrador de Granja'}
              </span>
            </div>

            <div className="responsive-grid-2" style={{ width: '100%', textAlign: 'left', gap: '1.5rem' }}>
              <div className="glass" style={{ padding: '1.5rem', borderRadius: '20px' }}>
                <div style={{ color: 'var(--muted-foreground)', fontSize: '0.7rem', fontWeight: 900, textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: '0.75rem' }}>Email Principal</div>
                <div style={{ fontWeight: 800, display: 'flex', alignItems: 'center', gap: '0.75rem', fontSize: '1.05rem' }}>
                  <Mail size={20} style={{ color: '#0d9488' }} /> {profile?.email}
                </div>
              </div>
              <div className="glass" style={{ padding: '1.5rem', borderRadius: '20px' }}>
                <div style={{ color: 'var(--muted-foreground)', fontSize: '0.7rem', fontWeight: 900, textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: '0.75rem' }}>Nivel de Acceso</div>
                <div style={{ fontWeight: 800, display: 'flex', alignItems: 'center', gap: '0.75rem', fontSize: '1.05rem' }}>
                  <Shield size={20} style={{ color: '#0d9488' }} /> {profile?.is_superadmin ? 'Control Total' : 'Gestión Operativa'}
                </div>
              </div>
            </div>

            <div style={{ display: 'flex', gap: '1rem', width: '100%', marginTop: '3rem' }}>
              <button
                id="perfil-edit-btn"
                onClick={handleOpenEdit}
                className="btn-primary"
                style={{ flex: 2, padding: '1.25rem', background: '#0d9488', borderRadius: '18px', fontWeight: 900, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '0.5rem' }}
              >
                <Pencil size={18} /> Editar Información
              </button>
              <button
                onClick={logout}
                className="glass"
                style={{ flex: 1, padding: '1.25rem', borderRadius: '18px', fontWeight: 900, color: '#ef4444', border: '1px solid rgba(239, 68, 68, 0.2)', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '0.5rem' }}
              >
                <LogOut size={20} /> Salir
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Edit Modal */}
      <AnimatePresence>
        {isEditOpen && (
          <div style={{ position: 'fixed', inset: 0, zIndex: 200, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '1rem' }}>
            {/* Backdrop */}
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setIsEditOpen(false)}
              style={{ position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.5)', backdropFilter: 'blur(6px)' }}
            />

            {/* Modal */}
            <motion.div
              initial={{ opacity: 0, scale: 0.93, y: 24 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.93, y: 24 }}
              transition={{ type: 'spring', stiffness: 300, damping: 28 }}
              className="card-premium"
              style={{ position: 'relative', width: '100%', maxWidth: '520px', padding: '2.5rem', maxHeight: '90vh', overflowY: 'auto' }}
            >
              {/* Header */}
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
                <div>
                  <h2 style={{ fontSize: '1.4rem', fontWeight: 950, letterSpacing: '-0.03em', margin: 0 }}>Editar Información</h2>
                  <p style={{ fontSize: '0.82rem', color: 'var(--muted-foreground)', fontWeight: 600, margin: '0.25rem 0 0' }}>Actualiza tu nombre o cambia tu contraseña de acceso.</p>
                </div>
                <button
                  onClick={() => setIsEditOpen(false)}
                  style={{ background: 'var(--secondary)', border: 'none', borderRadius: '10px', padding: '0.5rem', cursor: 'pointer', color: 'var(--muted-foreground)', display: 'flex', alignItems: 'center' }}
                >
                  <X size={20} />
                </button>
              </div>

              {/* — Section 1: Name — */}
              <div style={{ marginBottom: '2rem' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '1rem' }}>
                  <div style={{ width: '32px', height: '32px', borderRadius: '8px', background: 'rgba(13,148,136,0.1)', color: '#0d9488', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                    <User size={16} />
                  </div>
                  <h3 style={{ fontSize: '0.95rem', fontWeight: 900, margin: 0 }}>Nombre Completo</h3>
                </div>

                <div style={{ display: 'flex', gap: '0.75rem' }}>
                  <input
                    id="perfil-name-input"
                    type="text"
                    value={editName}
                    onChange={(e) => setEditName(e.target.value)}
                    placeholder="Tu nombre completo"
                    style={inputStyle}
                    onKeyDown={(e) => e.key === 'Enter' && handleSaveName()}
                  />
                  <button
                    id="perfil-save-name-btn"
                    onClick={handleSaveName}
                    disabled={isSavingName || !editName.trim() || editName.trim() === profile?.full_name}
                    style={{
                      padding: '0.85rem 1.25rem',
                      borderRadius: '12px',
                      border: 'none',
                      background: 'linear-gradient(135deg, #0d9488, #10b981)',
                      color: 'white',
                      fontWeight: 900,
                      cursor: 'pointer',
                      display: 'flex',
                      alignItems: 'center',
                      gap: '0.4rem',
                      fontSize: '0.85rem',
                      whiteSpace: 'nowrap',
                      opacity: (isSavingName || !editName.trim() || editName.trim() === profile?.full_name) ? 0.5 : 1,
                      transition: 'opacity 0.2s'
                    }}
                  >
                    <Save size={16} />
                    {isSavingName ? 'Guardando...' : 'Guardar'}
                  </button>
                </div>
              </div>

              {/* Divider */}
              <div style={{ height: '1px', background: 'var(--border)', margin: '0 0 2rem' }} />

              {/* — Section 2: Password — */}
              <div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '1rem' }}>
                  <div style={{ width: '32px', height: '32px', borderRadius: '8px', background: 'rgba(139,92,246,0.1)', color: '#8b5cf6', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                    <Lock size={16} />
                  </div>
                  <h3 style={{ fontSize: '0.95rem', fontWeight: 900, margin: 0 }}>Cambiar Contraseña</h3>
                </div>

                {passwordSuccess ? (
                  <motion.div
                    initial={{ opacity: 0, y: 8 }}
                    animate={{ opacity: 1, y: 0 }}
                    style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', padding: '1rem 1.25rem', background: 'rgba(16,185,129,0.08)', border: '1px solid rgba(16,185,129,0.2)', borderRadius: '14px', color: '#10b981', fontWeight: 700, fontSize: '0.9rem' }}
                  >
                    <CheckCircle2 size={20} />
                    ¡Contraseña actualizada exitosamente!
                  </motion.div>
                ) : (
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '0.85rem' }}>
                    {/* New Password */}
                    {([
                      { id: 'perfil-new-pwd', label: 'Nueva contraseña', value: newPassword, setter: setNewPassword, show: showNew, toggleShow: () => setShowNew(v => !v) },
                      { id: 'perfil-confirm-pwd', label: 'Confirmar nueva contraseña', value: confirmPassword, setter: setConfirmPassword, show: showConfirm, toggleShow: () => setShowConfirm(v => !v) },
                    ] as const).map((field) => (
                      <div key={field.id} style={{ position: 'relative' }}>
                        <label style={{ display: 'block', fontSize: '0.72rem', fontWeight: 800, color: 'var(--muted-foreground)', textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: '0.4rem' }}>
                          {field.label}
                        </label>
                        <div style={{ position: 'relative' }}>
                          <input
                            id={field.id}
                            type={field.show ? 'text' : 'password'}
                            value={field.value}
                            onChange={(e) => field.setter(e.target.value)}
                            placeholder="••••••••"
                            style={{ ...inputStyle, paddingRight: '3rem' }}
                          />
                          <button
                            type="button"
                            onClick={field.toggleShow}
                            style={{ position: 'absolute', right: '1rem', top: '50%', transform: 'translateY(-50%)', background: 'none', border: 'none', cursor: 'pointer', color: 'var(--muted-foreground)', display: 'flex', alignItems: 'center' }}
                          >
                            {field.show ? <EyeOff size={18} /> : <Eye size={18} />}
                          </button>
                        </div>
                      </div>
                    ))}

                    {/* Password strength hint */}
                    {newPassword && (
                      <div style={{ fontSize: '0.72rem', fontWeight: 700, color: newPassword.length >= 8 ? '#10b981' : '#f59e0b', display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
                        {newPassword.length >= 8 ? <CheckCircle2 size={13} /> : '⚠️'}
                        {newPassword.length >= 8 ? 'Contraseña segura' : `Mínimo 8 caracteres (${newPassword.length}/8)`}
                      </div>
                    )}

                    {/* Confirm match hint */}
                    {confirmPassword && newPassword !== confirmPassword && (
                      <div style={{ fontSize: '0.72rem', fontWeight: 700, color: '#ef4444' }}>
                        ⚠️ Las contraseñas no coinciden
                      </div>
                    )}

                    <button
                      id="perfil-save-pwd-btn"
                      onClick={handleChangePassword}
                      disabled={isSavingPassword || !newPassword || !confirmPassword || newPassword !== confirmPassword || newPassword.length < 6}
                      style={{
                        marginTop: '0.5rem',
                        width: '100%',
                        padding: '1rem',
                        borderRadius: '14px',
                        border: 'none',
                        background: 'linear-gradient(135deg, #8b5cf6, #7c3aed)',
                        color: 'white',
                        fontWeight: 900,
                        fontSize: '0.95rem',
                        cursor: 'pointer',
                        opacity: (isSavingPassword || !newPassword || !confirmPassword || newPassword !== confirmPassword || newPassword.length < 6) ? 0.45 : 1,
                        transition: 'opacity 0.2s',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        gap: '0.5rem',
                        boxShadow: '0 4px 15px rgba(139,92,246,0.25)'
                      }}
                    >
                      <Lock size={17} />
                      {isSavingPassword ? 'Actualizando...' : 'Actualizar Contraseña'}
                    </button>
                  </div>
                )}
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </div>
  );
}
