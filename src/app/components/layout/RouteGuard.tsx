'use client';

import { usePathname } from 'next/navigation';
import { useAuth } from '../providers/AuthProvider';
import AppLayout from './AppLayout';

// Pages that render WITHOUT the sidebar/app shell
const STANDALONE_PATHS = new Set(['', '/', '/signup', '/select-unit']);

export function RouteGuard({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const { loading } = useAuth();
  
  const normalizedPathname = (pathname || '').replace(/\/$/, '') || '/';
  
  const isStandalonePage = 
    STANDALONE_PATHS.has(normalizedPathname) ||
    normalizedPathname.startsWith('/select-unit/');

  // Only show a full-screen spinner on protected routes while auth is resolving.
  // Standalone pages (login, select-unit) handle their own loading state.
  if (loading && !isStandalonePage) {
    return (
      <div style={{ 
        background: '#06101e', 
        display: 'flex', 
        alignItems: 'center', 
        justifyContent: 'center', 
        height: '100vh', 
        width: '100%' 
      }}>
        <div 
          className="animate-spin" 
          style={{ 
            width: '36px', 
            height: '36px', 
            border: '3px solid rgba(30, 202, 212, 0.3)', 
            borderTopColor: '#1ECAD4', 
            borderRadius: '50%' 
          }} 
        />
      </div>
    );
  }

  if (!isStandalonePage) {
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
