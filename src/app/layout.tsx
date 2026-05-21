import type { Metadata, Viewport } from "next";
import Script from "next/script";
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
        <Script id="strip-bis-skin-checked" strategy="beforeInteractive">
          {`
            (function() {
              function cleanup() {
                document.querySelectorAll('[bis_skin_checked]').forEach((el) => {
                  el.removeAttribute('bis_skin_checked');
                });
              }
              cleanup();
              if (document.readyState === 'loading') {
                document.addEventListener('DOMContentLoaded', cleanup);
              }

              const observer = new MutationObserver((mutations) => {
                for (const mutation of mutations) {
                  if (mutation.type === 'childList') {
                    for (const node of mutation.addedNodes) {
                      if (node.nodeType === 1) {
                        if (node.hasAttribute('bis_skin_checked')) {
                          node.removeAttribute('bis_skin_checked');
                        }
                        node.querySelectorAll('[bis_skin_checked]').forEach((el) => {
                          el.removeAttribute('bis_skin_checked');
                        });
                      }
                    }
                  } else if (mutation.type === 'attributes' && mutation.attributeName === 'bis_skin_checked') {
                    if (mutation.target.nodeType === 1 && mutation.target.hasAttribute('bis_skin_checked')) {
                      mutation.target.removeAttribute('bis_skin_checked');
                    }
                  }
                }
              });

              observer.observe(document.documentElement, {
                childList: true,
                subtree: true,
                attributes: true,
                attributeFilter: ['bis_skin_checked']
              });
            })();
          `}
        </Script>
        <Providers>
          <RouteGuard>
            {children}
          </RouteGuard>
        </Providers>
      </body>
    </html>
  );
}
