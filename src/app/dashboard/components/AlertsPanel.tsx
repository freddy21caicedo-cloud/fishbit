'use client';

import { motion, AnimatePresence } from 'framer-motion';
import { AlertTriangle, AlertOctagon, ArrowRight, ShieldCheck } from 'lucide-react';

export interface AlertItem {
  id: string;
  pondId: string;
  pondName: string;
  type: 'oxigeno' | 'temperatura' | 'ph' | 'mortalidad';
  severity: 'warning' | 'critical';
  message: string;
  value: number;
  unit: string;
}

interface AlertsPanelProps {
  alerts: AlertItem[];
  onViewPond?: (pondId: string) => void;
}

export function AlertsPanel({ alerts, onViewPond }: AlertsPanelProps) {
  if (alerts.length === 0) {
    return (
      <motion.div 
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        className="glass"
        style={{ 
          padding: '1.25rem 1.5rem', 
          borderRadius: '16px', 
          display: 'flex', 
          alignItems: 'center', 
          gap: '1rem', 
          background: 'rgba(16, 185, 129, 0.06)',
          border: '1px solid rgba(16, 185, 129, 0.15)',
          color: '#10b981'
        }}
      >
        <div style={{ padding: '0.5rem', background: 'rgba(16, 185, 129, 0.1)', borderRadius: '10px' }}>
          <ShieldCheck size={20} />
        </div>
        <div>
          <h4 style={{ fontSize: '0.85rem', fontWeight: 800 }}>Todos los estanques óptimos</h4>
          <p style={{ fontSize: '0.75rem', opacity: 0.8, fontWeight: 600 }}>Parámetros físicos y químicos dentro de los límites seguros.</p>
        </div>
      </motion.div>
    );
  }

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <h4 style={{ fontSize: '0.8rem', fontWeight: 900, textTransform: 'uppercase', letterSpacing: '0.05em', color: 'var(--muted-foreground)' }}>
          Alertas Activas ({alerts.length})
        </h4>
      </div>
      
      <AnimatePresence>
        {alerts.map((alert) => {
          const isCritical = alert.severity === 'critical';
          const primaryColor = isCritical ? '#ef4444' : '#f59e0b';
          const bgColor = isCritical ? 'rgba(239, 68, 68, 0.08)' : 'rgba(245, 158, 11, 0.08)';
          const borderColor = isCritical ? 'rgba(239, 68, 68, 0.2)' : 'rgba(245, 158, 11, 0.2)';
          const Icon = isCritical ? AlertOctagon : AlertTriangle;

          return (
            <motion.div
              key={alert.id}
              initial={{ opacity: 0, x: -10 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: 10 }}
              layout
              className="glass"
              style={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                padding: '1rem 1.25rem',
                borderRadius: '16px',
                background: bgColor,
                border: `1px solid ${borderColor}`,
                boxShadow: isCritical ? '0 10px 20px rgba(239, 68, 68, 0.05)' : 'none',
                gap: '1rem',
                flexWrap: 'wrap'
              }}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', flex: 1, minWidth: '200px' }}>
                <div style={{ 
                  padding: '0.5rem', 
                  background: `${primaryColor}20`, 
                  color: primaryColor, 
                  borderRadius: '10px',
                  animation: isCritical ? 'pulse 1.5s infinite' : 'none'
                }}>
                  <Icon size={18} />
                </div>
                <div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                    <span style={{ fontSize: '0.85rem', fontWeight: 900, color: 'var(--foreground)' }}>{alert.pondName}</span>
                    <span style={{ 
                      fontSize: '0.55rem', 
                      background: primaryColor, 
                      color: 'white', 
                      padding: '1px 5px', 
                      borderRadius: '4px', 
                      fontWeight: 950,
                      textTransform: 'uppercase'
                    }}>
                      {isCritical ? 'CRÍTICO' : 'ADVERTENCIA'}
                    </span>
                  </div>
                  <p style={{ fontSize: '0.75rem', color: 'var(--muted-foreground)', fontWeight: 600, marginTop: '0.1rem' }}>
                    {alert.message}
                  </p>
                </div>
              </div>

              <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                <div style={{ textAlign: 'right' }}>
                  <div style={{ fontSize: '1rem', fontWeight: 950, color: primaryColor }}>
                    {alert.value} <span style={{ fontSize: '0.7rem', fontWeight: 800 }}>{alert.unit}</span>
                  </div>
                </div>
                {onViewPond && (
                  <button
                    onClick={() => onViewPond(alert.pondId)}
                    style={{
                      padding: '0.4rem 0.8rem',
                      background: 'var(--card)',
                      border: '1px solid var(--border)',
                      borderRadius: '10px',
                      color: 'var(--foreground)',
                      fontSize: '0.7rem',
                      fontWeight: 800,
                      cursor: 'pointer',
                      display: 'flex',
                      alignItems: 'center',
                      gap: '0.25rem',
                      transition: 'all 0.2s'
                    }}
                    onMouseEnter={(e) => {
                      e.currentTarget.style.borderColor = primaryColor;
                      e.currentTarget.style.color = primaryColor;
                    }}
                    onMouseLeave={(e) => {
                      e.currentTarget.style.borderColor = 'var(--border)';
                      e.currentTarget.style.color = 'var(--foreground)';
                    }}
                  >
                    Atender <ArrowRight size={12} />
                  </button>
                )}
              </div>
            </motion.div>
          );
        })}
      </AnimatePresence>
    </div>
  );
}
