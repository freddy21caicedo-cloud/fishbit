import type { Metadata, Viewport } from "next";
import "./globals.css";
import { Providers } from "./components/providers/Providers";
import { RouteGuard } from "./components/layout/RouteGuard";

export const metadata: Metadata = {
  title: "FishBit | Gestión Acuícola Premium",
  description: "Plataforma premium para la gestión y monitoreo de granjas acuícolas.",
  manifest: "/manifest.json",
  icons: {
    icon: "/favicon.ico",
  },
};

export const viewport: Viewport = {
  themeColor: "#2563eb",
  width: "device-width",
  initialScale: 1,
  maximumScale: 1,
  userScalable: false,
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="es" suppressHydrationWarning>
      <body className="antialiased" suppressHydrationWarning>
        <Providers>
          <RouteGuard>
            {children}
          </RouteGuard>
        </Providers>
      </body>
    </html>
  );
}
