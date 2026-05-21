'use client';

import { createContext, useContext, useEffect, useState, useCallback, useRef } from 'react';
import { supabase } from '@/lib/supabase';
import type { Session, AuthChangeEvent } from '@supabase/supabase-js';

export interface Profile {
  id: string;
  role: 'admin' | 'propietario' | 'tecnico' | 'operario';
  is_superadmin: boolean;
  full_name?: string;
  email?: string;
}

const AuthContext = createContext<{
  session: Session | null;
  loading: boolean;
  isSuperAdmin: boolean;
  profile: Profile | null;
  profileLoading: boolean;
  refreshProfile: () => Promise<void>;
} | null>(null);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [session, setSession] = useState<Session | null>(null);
  // Start NOT loading — we resolve synchronously from localStorage first, then hydrate
  const [loading, setLoading] = useState(true);
  const [profile, setProfile] = useState<Profile | null>(null);
  const [profileLoading, setProfileLoading] = useState(true);

  // Guard to prevent concurrent profile fetches (e.g. getSession + INITIAL_SESSION both fire)
  const fetchingProfileRef = useRef(false);
  const initializedRef = useRef(false);

  const fetchProfile = useCallback(async (userId: string) => {
    // Prevent concurrent fetches for the same user
    if (fetchingProfileRef.current) return;
    fetchingProfileRef.current = true;
    setProfileLoading(true);
    try {
      const { data, error } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', userId)
        .maybeSingle();
      if (!error && data) {
        setProfile(data);
      } else {
        setProfile(null);
      }
    } catch (err) {
      console.error('Error fetching profile in AuthProvider:', err);
      setProfile(null);
    } finally {
      fetchingProfileRef.current = false;
      setProfileLoading(false);
    }
  }, []);

  const refreshProfile = useCallback(async () => {
    if (session?.user?.id) {
      fetchingProfileRef.current = false; // Allow forced refresh
      await fetchProfile(session.user.id);
    }
  }, [session, fetchProfile]);

  useEffect(() => {
    let active = true;

    // Fail-safe: guarantee loading clears within 3s regardless of network state
    const failSafeTimeout = setTimeout(() => {
      if (active) {
        console.warn('AuthProvider: fail-safe timeout fired.');
        setLoading(false);
        setProfileLoading(false);
      }
    }, 3000);

    // Listen for auth changes — this fires INITIAL_SESSION immediately on mount
    const { data: { subscription } } = supabase.auth.onAuthStateChange(async (event: AuthChangeEvent, newSession: Session | null) => {
      if (!active) return;

      const prevSession = session;
      setSession(newSession);
      setLoading(false);
      clearTimeout(failSafeTimeout);

      if (newSession?.user) {
        // Only fetch profile if user changed or we haven't fetched yet
        if (!initializedRef.current || prevSession?.user?.id !== newSession.user.id) {
          initializedRef.current = true;
          await fetchProfile(newSession.user.id);
        }
      } else {
        setProfile(null);
        setProfileLoading(false);
        initializedRef.current = false;

        // Redirect to login if not already there
        if (typeof window !== 'undefined') {
          const isAuthPage = window.location.pathname === '/' || window.location.pathname === '/signup';
          if (!isAuthPage && !(window as any).__redirectingToHome) {
            (window as any).__redirectingToHome = true;
            window.location.replace('/');
          }
        }
      }
    });

    return () => {
      active = false;
      clearTimeout(failSafeTimeout);
      subscription.unsubscribe();
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const isSuperAdmin = !!session?.user?.app_metadata?.is_superadmin || profile?.is_superadmin || false;

  return (
    <AuthContext.Provider value={{ 
      session, 
      loading, 
      isSuperAdmin, 
      profile, 
      profileLoading, 
      refreshProfile 
    }}>
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
