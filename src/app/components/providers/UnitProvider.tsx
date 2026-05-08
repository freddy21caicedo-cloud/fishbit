'use client';

import { createContext, useContext, useEffect, useState, useCallback } from 'react';
import { supabase } from '@/lib/supabase';
import { useAuth } from './AuthProvider';
import type { Unit } from '@/lib/database.types';

interface UnitContextType {
  activeUnitId: string | null;
  activeUnit: Unit | null;
  loading: boolean;
  setActiveUnitId: (id: string) => void;
  refreshUnitData: () => Promise<void>;
}

const UnitContext = createContext<UnitContextType | null>(null);

export function UnitProvider({ children }: { children: React.ReactNode }) {
  const { session } = useAuth();
  const [activeUnitId, setInternalActiveUnitId] = useState<string | null>(null);
  const [activeUnit, setActiveUnit] = useState<Unit | null>(null);
  const [loading, setLoading] = useState(true);

  const fetchUnitData = useCallback(async (unitId: string) => {
    setLoading(true);
    try {
      const { data, error } = await supabase
        .from('units')
        .select('*, subscriptions(plan_type)')
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
  }, [fetchUnitData]);

  useEffect(() => {
    if (!session?.user) {
      setInternalActiveUnitId(null);
      setActiveUnit(null);
      setLoading(false);
      return;
    }

    const initUnit = async () => {
      const storedId = localStorage.getItem('active_unit_id');
      
      if (storedId) {
        setInternalActiveUnitId(storedId);
        await fetchUnitData(storedId);
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
          setLoading(false);
        }
      }
    };

    initUnit();
  }, [session, fetchUnitData, setActiveUnitId]);

  return (
    <UnitContext.Provider value={{ 
      activeUnitId, 
      activeUnit, 
      loading, 
      setActiveUnitId,
      refreshUnitData: () => activeUnitId ? fetchUnitData(activeUnitId) : Promise.resolve()
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
