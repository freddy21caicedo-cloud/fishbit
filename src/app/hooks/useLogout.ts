'use client';

import { supabase } from '@/lib/supabase';

export function useLogout() {
  const logout = async () => {
    try {
      // Clear localStorage FIRST so that any synchronous re-renders see it immediately cleared
      localStorage.removeItem('active_unit_id');
      localStorage.removeItem('fishbit_last_active');
      await supabase.auth.signOut();
    } catch (err) {
      console.error('Error during signOut:', err);
    } finally {
      // Avoid double redirection if we are already on '/' or redirecting to '/'
      if (typeof window !== 'undefined' && window.location.pathname !== '/' && !(window as any).__redirectingToHome) {
        (window as any).__redirectingToHome = true;
        window.location.replace('/');
      }
    }
  };

  return logout;
}
