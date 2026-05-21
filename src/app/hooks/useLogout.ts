'use client';

import { supabase } from '@/lib/supabase';

export function useLogout() {
  const logout = async () => {
    try {
      // Clear localStorage FIRST so that any synchronous re-renders see it immediately cleared
      localStorage.removeItem('active_unit_id');
      localStorage.removeItem('fishbit_last_active');
      
      // Call server-side logout route to clear HttpOnly cookies
      await fetch('/api/auth/logout', { method: 'POST' }).catch(err => {
        console.error('Server-side logout API call failed:', err);
      });
      
      // Invalidate client-side Supabase session
      await supabase.auth.signOut();
    } catch (err) {
      console.error('Error during signOut:', err);
    } finally {
      // Manually clear client-side Supabase cookies as a fallback to avoid race conditions with Next.js middleware
      if (typeof document !== 'undefined') {
        document.cookie.split(';').forEach(cookie => {
          const eqPos = cookie.indexOf('=');
          const name = eqPos > -1 ? cookie.substring(0, eqPos).trim() : cookie.trim();
          if (name.startsWith('sb-') || name.includes('auth-token')) {
            document.cookie = name + '=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;';
            if (typeof window !== 'undefined') {
              document.cookie = name + '=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/; domain=' + window.location.hostname + ';';
              document.cookie = name + '=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/; domain=.' + window.location.hostname + ';';
            }
          }
        });
      }

      // Avoid double redirection if we are already on '/' or redirecting to '/'
      if (typeof window !== 'undefined' && !(window as any).__redirectingToHome) {
        (window as any).__redirectingToHome = true;
        window.location.replace('/');
      }
    }
  };

  return logout;
}


