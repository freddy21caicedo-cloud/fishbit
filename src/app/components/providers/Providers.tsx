'use client';

import { AuthProvider } from './AuthProvider';
import { UnitProvider } from './UnitProvider';
import { Toaster } from 'react-hot-toast';

export function Providers({ children }: { children: React.ReactNode }) {
  return (
    <AuthProvider>
      <UnitProvider>
        <Toaster position="top-right" />
        {children}
      </UnitProvider>
    </AuthProvider>
  );
}
