'use client';

import { supabase } from '@/lib/supabase';

export function useLogout() {
  const logout = async () => {
    try {
      // 1. Aggressively clear localStorage unit keys and all Supabase auth keys
      if (typeof window !== 'undefined') {
        try {
          localStorage.removeItem('active_unit_id');
          localStorage.removeItem('fishbit_last_active');
          
          const keysToRemove: string[] = [];
          for (let i = 0; i < localStorage.length; i++) {
            const key = localStorage.key(i);
            if (key && (key.startsWith('sb-') || key.includes('auth-token') || key.includes('supabase.auth'))) {
              keysToRemove.push(key);
            }
          }
          keysToRemove.forEach(key => localStorage.removeItem(key));
        } catch (storageErr) {
          console.error('Error clearing localStorage auth keys:', storageErr);
        }

        try {
          const sessionKeysToRemove: string[] = [];
          for (let i = 0; i < sessionStorage.length; i++) {
            const key = sessionStorage.key(i);
            if (key && (key.startsWith('sb-') || key.includes('auth-token') || key.includes('supabase.auth'))) {
              sessionKeysToRemove.push(key);
            }
          }
          sessionKeysToRemove.forEach(key => sessionStorage.removeItem(key));
        } catch (sessionStorageErr) {
          console.error('Error clearing sessionStorage auth keys:', sessionStorageErr);
        }
      }
      
      // 2. Call server-side logout route to clear HttpOnly cookies (with a quick 1000ms timeout)
      try {
        await Promise.race([
          fetch('/api/auth/logout', { method: 'POST' }),
          new Promise((_, reject) => setTimeout(() => reject(new Error('Timeout')), 1000))
        ]);
      } catch (err) {
        console.warn('Server-side logout API call timed out or failed:', err);
      }
      
      // 3. Invalidate client-side Supabase session (with a quick 1000ms timeout)
      try {
        await Promise.race([
          supabase.auth.signOut(),
          new Promise((resolve) => setTimeout(resolve, 1000))
        ]);
      } catch (err) {
        console.warn('Client-side Supabase signOut timed out or failed:', err);
      }
    } catch (err) {
      console.error('Error during logout sequence:', err);
    } finally {
      // 4. Manually clear client-side cookies across all domains
      if (typeof document !== 'undefined') {
        try {
          document.cookie.split(';').forEach(cookie => {
            const eqPos = cookie.indexOf('=');
            const name = eqPos > -1 ? cookie.substring(0, eqPos).trim() : cookie.trim();
            if (name.startsWith('sb-') || name.includes('auth-token')) {
              // 4a. Clear exact default domain cookie
              document.cookie = name + '=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;';
              
              if (typeof window !== 'undefined') {
                const host = window.location.hostname;
                // 4b. Clear exact hostname cookie
                document.cookie = name + '=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/; domain=' + host + ';';
                // 4c. Clear wildcard hostname cookie
                document.cookie = name + '=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/; domain=.' + host + ';';
                
                // 4d. If subdomain (e.g. app.fishbit.co), clear parent domain (fishbit.co)
                const parts = host.split('.');
                if (parts.length > 2) {
                  const parent = parts.slice(-2).join('.');
                  document.cookie = name + '=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/; domain=' + parent + ';';
                  document.cookie = name + '=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/; domain=.' + parent + ';';
                }
              }
            }
          });
        } catch (cookieErr) {
          console.error('Error clearing client cookies:', cookieErr);
        }
      }

      // 5. Final redirect to home page (done in finally block so it always completes)
      if (typeof window !== 'undefined' && !(window as any).__redirectingToHome) {
        (window as any).__redirectingToHome = true;
        window.location.replace('/');
      }
    }
  };

  return logout;
}
