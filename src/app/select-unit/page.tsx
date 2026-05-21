'use client';

import { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import { supabase } from '@/lib/supabase';
import { 
  Loader2,
  LogOut,
  Building2,
  Waves,
  ChevronRight,
  AlertCircle
} from 'lucide-react';
import { useLogout } from '../hooks/useLogout';
import { useAuth } from '../components/providers/AuthProvider';
import { FishBitWordmark } from '../components/FishBitLogo';

interface UnitOption {
  id: string;
  name: string;
  location?: string;
}

export default function SelectUnitPage() {
  const logout = useLogout();
  const { session, loading: authLoading } = useAuth();
  const [units, setUnits] = useState<UnitOption[]>([]);
  const [pageLoading, setPageLoading] = useState(true);
  const [selecting, setSelecting] = useState<string | null>(null);
  const [fetchError, setFetchError] = useState<string | null>(null);

  useEffect(() => {
    // Wait for auth to initialize before doing anything
    if (authLoading) return;

    if (!session?.user) {
      window.location.replace('/');
      return;
    }

    let cancelled = false;

    const fetchUserUnits = async () => {
      try {
        // Step 1: Get unit_ids for this user
        const { data: userUnitRows, error: userUnitError } = await supabase
          .from('user_units')
          .select('unit_id')
          .eq('user_id', session.user.id);

        if (cancelled) return;

        if (userUnitError) {
          console.error('Error fetching user_units:', userUnitError);
          setFetchError('No se pudo cargar la lista de granjas. Intenta de nuevo.');
          setPageLoading(false);
          return;
        }

        if (!userUnitRows || userUnitRows.length === 0) {
          setFetchError('Tu cuenta no tiene granjas asignadas.');
          setPageLoading(false);
          return;
        }

        const unitIds = userUnitRows.map((r: any) => r.unit_id).filter(Boolean);

        // Step 2: Fetch full unit data by ids (avoid relying on PostgREST FK join)
        const { data: unitRows, error: unitError } = await supabase
          .from('units')
          .select('id, name, location')
          .in('id', unitIds);

        if (cancelled) return;

        if (unitError) {
          console.error('Error fetching units:', unitError);
          setFetchError('No se pudo cargar los detalles de las granjas.');
          setPageLoading(false);
          return;
        }

        const fetchedUnits = (unitRows || []) as UnitOption[];

        // Single unit → auto-select and redirect without showing the selector
        if (fetchedUnits.length === 1) {
          localStorage.setItem('active_unit_id', fetchedUnits[0].id);
          window.location.replace('/dashboard');
          return;
        }

        setUnits(fetchedUnits);
      } catch (err) {
        console.error('Error in fetchUserUnits:', err);
        setFetchError('Error inesperado al cargar tus granjas.');
      } finally {
        if (!cancelled) setPageLoading(false);
      }
    };

    fetchUserUnits();
    return () => { cancelled = true; };
  }, [authLoading, session]);

  const handleSelectUnit = (unitId: string) => {
    if (selecting) return; // Prevent double-tap
    setSelecting(unitId);
    localStorage.setItem('active_unit_id', unitId);
    window.location.replace('/dashboard');
  };

  // --- Loading State ---
  if (authLoading || pageLoading) {
    return (
      <div style={{ 
        minHeight: '100vh', 
        display: 'flex', 
        alignItems: 'center', 
        justifyContent: 'center', 
        background: 'radial-gradient(circle at 20% 20%, rgba(13,148,136,0.08) 0%, #f8fafc 80%)'
      }}>
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '1rem' }}>
          <Loader2 className="animate-spin" size={40} color="#0d9488" />
          <span style={{ color: '#64748b', fontWeight: 600, fontSize: '0.9rem' }}>Cargando tus granjas...</span>
        </div>
      </div>
    );
  }

  // --- Error State ---
  if (fetchError) {
    return (
      <div style={{
        minHeight: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        background: 'radial-gradient(circle at 20% 20%, rgba(13,148,136,0.08) 0%, #f8fafc 80%)',
        padding: '2rem'
      }}>
        <div style={{
          maxWidth: '400px',
          width: '100%',
          background: 'white',
          border: '1px solid #fee2e2',
          borderRadius: '16px',
          padding: '2rem',
          textAlign: 'center',
          boxShadow: '0 4px 16px rgba(0,0,0,0.06)'
        }}>
          <AlertCircle size={40} color="#ef4444" style={{ margin: '0 auto 1rem' }} />
          <h2 style={{ fontWeight: 800, color: '#0f172a', marginBottom: '0.5rem' }}>Error al cargar granjas</h2>
          <p style={{ color: '#64748b', fontSize: '0.9rem', marginBottom: '1.5rem' }}>{fetchError}</p>
          <button
            onClick={logout}
            style={{
              padding: '0.75rem 1.5rem',
              background: 'none',
              border: '1px solid #e2e8f0',
              borderRadius: '10px',
              color: '#ef4444',
              fontWeight: 700,
              cursor: 'pointer',
              fontSize: '0.9rem',
              display: 'inline-flex',
              alignItems: 'center',
              gap: '0.5rem'
            }}
          >
            <LogOut size={16} />
            Cerrar Sesión
          </button>
        </div>
      </div>
    );
  }

  // --- Main UI ---
  return (
    <div style={{ 
      minHeight: '100vh', 
      display: 'flex', 
      flexDirection: 'column',
      background: 'radial-gradient(circle at 20% 20%, rgba(13,148,136,0.08) 0%, #f8fafc 80%)',
      padding: '2rem'
    }}>
      {/* Top logo bar */}
      <div style={{ display: 'flex', justifyContent: 'center', marginBottom: '2rem' }}>
        <FishBitWordmark size={22} />
      </div>

      <div style={{ maxWidth: '520px', margin: 'auto', width: '100%' }}>
        {/* Header */}
        <motion.div
          initial={{ opacity: 0, y: -16 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.4 }}
          style={{ textAlign: 'center', marginBottom: '2.5rem' }}
        >
          <div style={{ 
            width: '72px', 
            height: '72px', 
            background: 'linear-gradient(135deg, #0d9488 0%, #0f766e 100%)', 
            borderRadius: '20px', 
            display: 'flex', 
            alignItems: 'center', 
            justifyContent: 'center',
            margin: '0 auto 1.5rem',
            boxShadow: '0 16px 32px rgba(13, 148, 136, 0.25)',
            color: 'white'
          }}>
            <Waves size={36} />
          </div>
          <h1 style={{ 
            fontSize: '1.85rem', 
            fontWeight: 900, 
            color: '#0f172a', 
            marginBottom: '0.6rem', 
            letterSpacing: '-0.03em' 
          }}>
            Selecciona tu Granja
          </h1>
          <p style={{ color: '#64748b', fontWeight: 500, fontSize: '0.95rem', lineHeight: 1.6 }}>
            Tienes acceso a <strong style={{ color: '#0d9488' }}>{units.length}</strong> granjas acuícolas.
            <br />Elige cuál deseas gestionar hoy.
          </p>
        </motion.div>

        {/* Units list */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '0.875rem' }}>
          {units.map((unit, index) => {
            const isSelected = selecting === unit.id;
            const isDisabled = !!selecting && !isSelected;

            return (
              <motion.button
                key={unit.id}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: index * 0.07, duration: 0.3 }}
                onClick={() => handleSelectUnit(unit.id)}
                disabled={!!selecting}
                style={{ 
                  width: '100%', 
                  padding: '1.25rem 1.5rem', 
                  display: 'flex', 
                  alignItems: 'center', 
                  gap: '1.125rem', 
                  textAlign: 'left',
                  cursor: selecting ? 'wait' : 'pointer',
                  background: isSelected ? 'rgba(13,148,136,0.04)' : 'white',
                  border: '1.5px solid',
                  borderColor: isSelected ? '#0d9488' : '#e2e8f0',
                  borderRadius: '14px',
                  boxShadow: isSelected 
                    ? '0 6px 20px rgba(13,148,136,0.12)' 
                    : '0 1px 4px rgba(0,0,0,0.04)',
                  transition: 'all 0.2s ease',
                  opacity: isDisabled ? 0.45 : 1,
                }}
                onMouseEnter={(e) => {
                  if (!selecting) {
                    e.currentTarget.style.borderColor = '#0d9488';
                    e.currentTarget.style.transform = 'translateY(-2px)';
                    e.currentTarget.style.boxShadow = '0 8px 24px rgba(13,148,136,0.14)';
                  }
                }}
                onMouseLeave={(e) => {
                  if (!selecting) {
                    e.currentTarget.style.borderColor = '#e2e8f0';
                    e.currentTarget.style.transform = 'translateY(0)';
                    e.currentTarget.style.boxShadow = '0 1px 4px rgba(0,0,0,0.04)';
                  }
                }}
              >
                {/* Icon */}
                <div style={{ 
                  width: '46px', 
                  height: '46px', 
                  background: isSelected ? 'rgba(13,148,136,0.14)' : 'rgba(13,148,136,0.07)', 
                  borderRadius: '12px', 
                  display: 'flex', 
                  alignItems: 'center', 
                  justifyContent: 'center', 
                  color: '#0d9488',
                  flexShrink: 0,
                  transition: 'background 0.2s'
                }}>
                  {isSelected ? (
                    <Loader2 size={20} className="animate-spin" />
                  ) : (
                    <Building2 size={20} />
                  )}
                </div>

                {/* Info */}
                <div style={{ flex: 1, minWidth: 0 }}>
                  <h3 style={{ 
                    fontSize: '1rem', 
                    fontWeight: 800, 
                    marginBottom: '0.15rem', 
                    letterSpacing: '-0.01em',
                    color: '#0f172a',
                    whiteSpace: 'nowrap',
                    overflow: 'hidden',
                    textOverflow: 'ellipsis'
                  }}>
                    {unit.name}
                  </h3>
                  <p style={{ fontSize: '0.82rem', color: '#94a3b8', fontWeight: 500, margin: 0 }}>
                    📍 {unit.location || 'Sede Principal'}
                  </p>
                </div>

                {/* Arrow */}
                <ChevronRight 
                  size={18} 
                  style={{ 
                    color: isSelected ? '#0d9488' : '#cbd5e1', 
                    flexShrink: 0,
                    transition: 'color 0.2s'
                  }} 
                />
              </motion.button>
            );
          })}
        </div>

        {/* No units fallback */}
        {units.length === 0 && !pageLoading && (
          <div style={{
            textAlign: 'center',
            padding: '3rem 1rem',
            color: '#94a3b8'
          }}>
            <Building2 size={48} style={{ margin: '0 auto 1rem', opacity: 0.4 }} />
            <p style={{ fontWeight: 600 }}>No se encontraron granjas asignadas.</p>
          </div>
        )}

        {/* Logout button */}
        <button 
          onClick={logout}
          disabled={!!selecting}
          style={{ 
            marginTop: '2.5rem', 
            width: '100%', 
            padding: '0.875rem', 
            display: 'flex', 
            alignItems: 'center', 
            justifyContent: 'center', 
            gap: '0.625rem', 
            background: 'none', 
            border: '1px solid #e2e8f0', 
            borderRadius: '12px',
            color: '#94a3b8', 
            fontWeight: 700, 
            cursor: selecting ? 'not-allowed' : 'pointer',
            fontSize: '0.875rem',
            transition: 'all 0.2s',
            opacity: selecting ? 0.5 : 1
          }}
          onMouseEnter={(e) => {
            if (!selecting) {
              e.currentTarget.style.borderColor = '#fca5a5';
              e.currentTarget.style.color = '#ef4444';
              e.currentTarget.style.background = 'rgba(239,68,68,0.03)';
            }
          }}
          onMouseLeave={(e) => {
            if (!selecting) {
              e.currentTarget.style.borderColor = '#e2e8f0';
              e.currentTarget.style.color = '#94a3b8';
              e.currentTarget.style.background = 'none';
            }
          }}
        >
          <LogOut size={16} />
          Cerrar Sesión
        </button>
      </div>
    </div>
  );
}
