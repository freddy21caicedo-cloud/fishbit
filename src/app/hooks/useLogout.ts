'use client';

import { supabase } from '@/lib/supabase';
import { useRouter } from 'next/navigation';

export function useLogout() {
  const router = useRouter();

  const logout = async () => {
    try {
      await supabase.auth.signOut();
    } catch (err) {
      console.error('Error during signOut:', err);
    } finally {
      localStorage.removeItem('active_unit_id');
      localStorage.removeItem('fishbit_last_active');
      router.push('/');
    }
  };

  return logout;
}
