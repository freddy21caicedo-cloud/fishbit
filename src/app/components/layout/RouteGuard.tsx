'use client';

import { usePathname } from 'next/navigation';
import { useAuth } from '../providers/AuthProvider';
import AppLayout from './AppLayout';

export function RouteGuard({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const { session, loading } = useAuth();
  
  const isAuthPage = pathname === '/' || pathname === '/signup';

  if (loading && !isAuthPage) {
    return (
      <div style={{ background: 'var(--background)', display: 'flex', alignItems: 'center', justifyContent: 'center', height: '100vh', width: '100%' }}>
        <div className="animate-spin" style={{ width: '40px', height: '40px', border: '4px solid var(--primary)', borderTopColor: 'transparent', borderRadius: '50%' }}></div>
      </div>
    );
  }

  if (!isAuthPage) {
    return (
      <AppLayout>
        {children}
      </AppLayout>
    );
  }

  return (
    <div style={{ width: '100%' }}>
      {children}
    </div>
  );
}
