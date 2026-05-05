'use client';

import { useEffect, useState } from "react";
import { usePathname, useRouter } from "next/navigation";
import { supabase } from "@/lib/supabase";
import "./globals.css";
import Sidebar from "./components/Sidebar";
import Header from "./components/Header";

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  const pathname = usePathname();
  const router = useRouter();
  const [session, setSession] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    document.title = "FishBit | Gestión Acuícola Premium";
    const checkSession = async () => {
      const { data: { session } } = await supabase.auth.getSession();
      setSession(session);
      setLoading(false);
      
      if (!session && pathname !== '/login') {
        router.push('/login');
      }
    };

    checkSession();

    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      setSession(session);
      if (!session && pathname !== '/login') {
        router.push('/login');
      }
    });

    return () => subscription.unsubscribe();
  }, [pathname, router]);

  const isLoginPage = pathname === '/login';

  return (
    <html lang="es" suppressHydrationWarning>
      <body className="antialiased" suppressHydrationWarning>
        {loading && !isLoginPage ? (
          <div style={{ background: 'var(--background)', display: 'flex', alignItems: 'center', justifyContent: 'center', height: '100vh', width: '100%' }}>
            <div className="animate-spin" style={{ width: '40px', height: '40px', border: '4px solid var(--primary)', borderTopColor: 'transparent', borderRadius: '50%' }}></div>
          </div>
        ) : !isLoginPage && session ? (
          <div className="layout-container">
            <Sidebar />
            <main className="main-content">
              <Header />
              {children}
            </main>
          </div>
        ) : (
          <div style={{ width: '100%' }}>
            {children}
          </div>
        )}
      </body>
    </html>
  );
}
