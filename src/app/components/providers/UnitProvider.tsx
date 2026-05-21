'use client';

import { createContext, useContext, useEffect, useState, useCallback, useRef } from 'react';
import { supabase } from '@/lib/supabase';
import { useAuth } from './AuthProvider';
import type { Unit } from '@/lib/database.types';

interface UnitContextType {
  activeUnitId: string | null;
  activeUnit: Unit | null;
  loading: boolean;
  userRole: 'admin' | 'propietario' | 'tecnico' | 'operario' | null;
  roleLoading: boolean;
  setActiveUnitId: (id: string) => void;
  refreshUnitData: () => Promise<void>;
}

const UnitContext = createContext<UnitContextType | null>(null);

export function UnitProvider({ children }: { children: React.ReactNode }) {
  const { session } = useAuth();
  const [activeUnitId, setInternalActiveUnitId] = useState<string | null>(null);
  const [activeUnit, setActiveUnit] = useState<Unit | null>(null);
  const [loading, setLoading] = useState(true);
  const [userRole, setUserRole] = useState<'admin' | 'propietario' | 'tecnico' | 'operario' | null>(null);
  const [roleLoading, setRoleLoading] = useState(true);

  // Prevent re-initialization if the same user is already loaded
  const lastUserIdRef = useRef<string | null>(null);
  const initializingRef = useRef(false);

  const fetchUserRole = useCallback(async (userId: string, unitId: string) => {
    setRoleLoading(true);
    try {
      // Fetch unit-specific role from user_units
      const { data: unitRoleData, error: unitError } = await supabase
        .from('user_units')
        .select('role')
        .eq('user_id', userId)
        .eq('unit_id', unitId)
        .maybeSingle();

      if (!unitError && unitRoleData?.role) {
        setUserRole(unitRoleData.role);
        return;
      }

      // Fallback to global profile role
      const { data: profileData } = await supabase
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .maybeSingle();

      setUserRole(profileData?.role ?? null);
    } catch (err) {
      console.error('Error fetching user role in UnitProvider:', err);
      setUserRole(null);
    } finally {
      setRoleLoading(false);
    }
  }, []);

  const fetchUnitData = useCallback(async (unitId: string) => {
    setLoading(true);
    try {
      const { data, error } = await supabase
        .from('units')
        .select('*, subscriptions(plan_type, status, next_billing_date, price, trial_activated_at)')
        .eq('id', unitId)
        .single();
      
      if (!error && data) {
        setActiveUnit(data);
        return data;
      } else {
        setActiveUnit(null);
        return null;
      }
    } catch (err) {
      console.error('Error fetching unit data:', err);
      setActiveUnit(null);
      return null;
    } finally {
      setLoading(false);
    }
  }, []);

  // Public setter used by unit selector dropdown
  const setActiveUnitId = useCallback((id: string) => {
    localStorage.setItem('active_unit_id', id);
    setInternalActiveUnitId(id);
    if (session?.user) {
      // Run in parallel, no await needed here — UI will respond as data loads
      fetchUnitData(id);
      fetchUserRole(session.user.id, id);
    }
  }, [fetchUnitData, fetchUserRole, session]);

  useEffect(() => {
    // No session → reset everything immediately (e.g. after logout)
    if (!session?.user) {
      lastUserIdRef.current = null;
      initializingRef.current = false;
      setInternalActiveUnitId(null);
      setActiveUnit(null);
      setUserRole(null);
      setRoleLoading(false);
      setLoading(false);
      return;
    }

    // Same user already initialized → skip re-init
    if (lastUserIdRef.current === session.user.id && !initializingRef.current) {
      return;
    }

    // Prevent double-init (e.g. React Strict Mode double-invocation)
    if (initializingRef.current) return;
    initializingRef.current = true;
    lastUserIdRef.current = session.user.id;

    // Fail-safe: if init takes >2.5s, force-clear loading so user isn't stuck
    const failSafeTimeout = setTimeout(() => {
      console.warn('UnitProvider: fail-safe timeout fired.');
      setLoading(false);
      setRoleLoading(false);
      initializingRef.current = false;
    }, 2500);

    const initUnit = async () => {
      try {
        let storedId = localStorage.getItem('active_unit_id');
        if (storedId === 'null' || storedId === 'undefined') {
          storedId = null;
          localStorage.removeItem('active_unit_id');
        }
        
        let loadedUnit = null;
        if (storedId) {
          setInternalActiveUnitId(storedId);
          // Wait for unit data and user role loading
          const [unitRes] = await Promise.all([
            fetchUnitData(storedId),
            fetchUserRole(session.user.id, storedId)
          ]);
          loadedUnit = unitRes;
        }

        // Fallback: No stored unit ID, or the stored unit failed to load/doesn't exist
        if (!loadedUnit) {
          const { data: userUnit } = await supabase
            .from('user_units')
            .select('unit_id')
            .eq('user_id', session.user.id)
            .limit(1)
            .maybeSingle();
          
          if (userUnit?.unit_id) {
            const unitId = userUnit.unit_id;
            localStorage.setItem('active_unit_id', unitId);
            setInternalActiveUnitId(unitId);
            await Promise.all([
              fetchUnitData(unitId),
              fetchUserRole(session.user.id, unitId)
            ]);
          } else {
            // User has no units assigned
            setLoading(false);
            setRoleLoading(false);
          }
        }
      } catch (err) {
        console.error('Error in UnitProvider initUnit:', err);
        setLoading(false);
        setRoleLoading(false);
      } finally {
        clearTimeout(failSafeTimeout);
        initializingRef.current = false;
      }
    };

    initUnit();

    return () => {
      clearTimeout(failSafeTimeout);
    };
  // Intentionally minimal deps: only re-init when the user changes
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [session?.user?.id]);

  return (
    <UnitContext.Provider value={{ 
      activeUnitId, 
      activeUnit, 
      loading, 
      userRole,
      roleLoading,
      setActiveUnitId,
      refreshUnitData: async () => {
        if (activeUnitId && session?.user) {
          await Promise.all([
            fetchUnitData(activeUnitId),
            fetchUserRole(session.user.id, activeUnitId)
          ]);
        }
      }
    }}>
      {children}
    </UnitContext.Provider>
  );
}

export const useUnit = () => {
  const context = useContext(UnitContext);
  if (!context) {
    throw new Error('useUnit must be used within a UnitProvider');
  }
  return context;
};
