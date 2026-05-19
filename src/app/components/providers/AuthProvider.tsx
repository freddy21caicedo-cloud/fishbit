'use client';

import { createContext, useContext, useEffect, useState, useCallback } from 'react';
import { supabase } from '@/lib/supabase';
import { useRouter, usePathname } from 'next/navigation';
import type { Session } from '@supabase/supabase-js';

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
  const [loading, setLoading] = useState(true);
  const [profile, setProfile] = useState<Profile | null>(null);
  const [profileLoading, setProfileLoading] = useState(true);
  const router = useRouter();
  const pathname = usePathname();

  const fetchProfile = useCallback(async (userId: string, forceLoading: boolean = false) => {
    if (forceLoading) {
      setProfileLoading(true);
    }
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
      if (forceLoading) {
        setProfileLoading(false);
      }
    }
  }, []);

  const refreshProfile = useCallback(async () => {
    if (session?.user?.id) {
      await fetchProfile(session.user.id, false);
    }
  }, [session, fetchProfile]);

  useEffect(() => {
    // Check session once on mount
    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session);
      if (session?.user) {
        fetchProfile(session.user.id, true);
      } else {
        setProfileLoading(false);
      }
      setLoading(false);
    });

    // Listen for auth changes
    const { data: { subscription } } = supabase.auth.onAuthStateChange(async (event, session) => {
      setSession(session);
      if (session?.user) {
        const shouldForceLoading = event === 'SIGNED_IN' || event === 'INITIAL_SESSION';
        await fetchProfile(session.user.id, shouldForceLoading);
      } else {
        setProfile(null);
        setProfileLoading(false);
      }
      const isAuthPage = pathname === '/' || pathname === '/signup';
      if (!session && !isAuthPage) {
        router.push('/');
      }
    });

    return () => subscription.unsubscribe();
  }, [pathname, fetchProfile, router]);

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
