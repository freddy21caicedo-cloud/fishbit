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
  const lastUserIdRef = useRef<string | null>(null);

  const fetchUserRole = useCallback(async (userId: string, unitId: string) => {
    setRoleLoading(true);
    try {
      // 1. Check unit specific role in user_units
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

      // 2. Fallback to profile role
      const { data: profileData, error: profileError } = await supabase
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .maybeSingle();

      if (!profileError && profileData?.role) {
        setUserRole(profileData.role);
      } else {
        setUserRole(null);
      }
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
      }
    } catch (err) {
      console.error('Error fetching unit data:', err);
    } finally {
      setLoading(false);
    }
  }, []);

  const setActiveUnitId = useCallback((id: string) => {
    localStorage.setItem('active_unit_id', id);
    setInternalActiveUnitId(id);
    fetchUnitData(id);
    if (session?.user) {
      fetchUserRole(session.user.id, id);
    }
  }, [fetchUnitData, fetchUserRole, session]);

  useEffect(() => {
    if (!session?.user) {
      const storedId = typeof window !== 'undefined' ? localStorage.getItem('active_unit_id') : null;
      const isAuthPage = typeof window !== 'undefined' && (window.location.pathname === '/' || window.location.pathname === '/signup');
      if (isAuthPage || !storedId) {
        lastUserIdRef.current = null;
        setInternalActiveUnitId(null);
        setActiveUnit(null);
        setUserRole(null);
        setRoleLoading(false);
        setLoading(false);
      }
      return;
    }

    if (lastUserIdRef.current === session.user.id && activeUnitId) {
      return;
    }
    lastUserIdRef.current = session.user.id;

    const initUnit = async () => {
      const storedId = localStorage.getItem('active_unit_id');
      
      if (storedId) {
        setInternalActiveUnitId(storedId);
        await Promise.all([
          fetchUnitData(storedId),
          fetchUserRole(session.user.id, storedId)
        ]);
      } else {
        // Fallback to first available unit
        const { data: userUnit } = await supabase
          .from('user_units')
          .select('unit_id')
          .eq('user_id', session.user.id)
          .limit(1)
          .single();
        
        if (userUnit) {
          setActiveUnitId(userUnit.unit_id);
        } else {
          setRoleLoading(false);
          setLoading(false);
        }
      }
    };

    initUnit();
  }, [session, fetchUnitData, fetchUserRole, setActiveUnitId]);

  return (
    <UnitContext.Provider value={{ 
      activeUnitId, 
      activeUnit, 
      loading, 
      userRole,
      roleLoading,
      setActiveUnitId,
      refreshUnitData: async () => {
        if (activeUnitId) {
          await fetchUnitData(activeUnitId);
          if (session?.user) {
            await fetchUserRole(session.user.id, activeUnitId);
          }
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
