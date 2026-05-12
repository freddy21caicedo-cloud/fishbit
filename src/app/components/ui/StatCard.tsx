'use client';

import { useState } from 'react';
import { motion } from 'framer-motion';
import { LucideIcon, ArrowUpRight } from 'lucide-react';
import { PremiumCard } from './PremiumCard';

interface StatCardProps {
  title: string;
  value: string | number;
  unit?: string;
  change?: string;
  icon: LucideIcon;
  color: string;
  details?: { label: string; value: string | number; unit?: string }[];
  isAlert?: boolean;
}

export function StatCard({ title, value, unit, change, icon: Icon, color, details, isAlert }: StatCardProps) {
  const [isFlipped, setIsFlipped] = useState(false);
  
  const displayColor = isAlert ? '#ef4444' : 'inherit';

  const formatNumber = (val: string | number) => {
    if (typeof val === 'number') return val.toLocaleString('es-CO', { maximumFractionDigits: 2 });
    if (typeof val === 'string' && !isNaN(Number(val)) && val.trim() !== '') {
      return Number(val).toLocaleString('es-CO', { maximumFractionDigits: 2 });
    }
    return val;
  };

  const displayValue = formatNumber(value);

  return (
    <div 
      style={{ perspective: '1000px', cursor: 'pointer', height: '180px' }}
      onClick={() => setIsFlipped(!isFlipped)}
    >
      <motion.div
        animate={{ rotateY: isFlipped ? 180 : 0 }}
        transition={{ duration: 0.6, type: 'spring', stiffness: 260, damping: 20 }}
        style={{ 
          width: '100%', 
          height: '100%', 
          position: 'relative', 
          transformStyle: 'preserve-3d' 
        }}
      >
        {/* Front */}
        <div style={{
          position: 'absolute',
          width: '100%',
          height: '100%',
          backfaceVisibility: 'hidden',
          WebkitBackfaceVisibility: 'hidden'
        }}>
          <PremiumCard hover={false} style={{ height: '100%', display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
              <div style={{ padding: '0.6rem', background: `${color}15`, borderRadius: '12px', color: color }}>
                <Icon size={24} />
              </div>
              {change && (
                <div style={{ 
                  display: 'flex', 
                  alignItems: 'center', 
                  gap: '0.25rem', 
                  color: change.startsWith('+') ? '#10b981' : (change.startsWith('-') ? '#ef4444' : '#64748b'), 
                  fontSize: '0.75rem', 
                  fontWeight: 800 
                }}>
                  {change}
                  {!['Estable', 'Óptimo', 'Total', 'Mes', 'Suficiente'].includes(change) && (
                    <ArrowUpRight size={14} style={{ transform: change.startsWith('-') ? 'rotate(90deg)' : 'none' }} />
                  )}
                </div>
              )}
            </div>
            <div>
              <div style={{ fontSize: 'clamp(1.3rem, 5vw, 1.75rem)', fontWeight: 900, marginBottom: '0.1rem', letterSpacing: '-0.02em', color: displayColor, display: 'flex', alignItems: 'center', gap: '0.4rem', flexWrap: 'wrap', lineHeight: 1.1 }}>
                <span>{displayValue}</span>
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', flexWrap: 'wrap' }}>
                  <span style={{ fontSize: 'clamp(0.7rem, 2.5vw, 0.9rem)', fontWeight: 700, opacity: 0.6, color: isAlert ? '#ef4444' : 'inherit' }}>{unit}</span>
                  {isAlert && (
                    <span style={{ background: '#ef4444', color: 'white', padding: '2px 6px', borderRadius: '6px', fontSize: '0.6rem', fontWeight: 950, letterSpacing: '0.05em' }}>ALTO</span>
                  )}
                </div>
              </div>
              <div style={{ fontSize: '0.75rem', color: 'var(--muted-foreground)', fontWeight: 800, textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                {title}
              </div>
            </div>
          </PremiumCard>
        </div>

        {/* Back */}
        <div style={{
          position: 'absolute',
          width: '100%',
          height: '100%',
          backfaceVisibility: 'hidden',
          WebkitBackfaceVisibility: 'hidden',
          transform: 'rotateY(180deg)'
        }}>
          <PremiumCard hover={false} style={{ height: '100%', display: 'flex', flexDirection: 'column' }}>
            <h4 style={{ 
              fontSize: '0.7rem', 
              fontWeight: 900, 
              textTransform: 'uppercase', 
              color: 'var(--muted-foreground)', 
              marginBottom: '0.75rem', 
              letterSpacing: '0.05em', 
              borderBottom: '1px solid var(--border)', 
              paddingBottom: '0.4rem' 
            }}>
              Detalle {title}
            </h4>
            <div style={{ flex: 1, overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
              {details && details.length > 0 ? details.map((item, idx) => (
                <div key={idx} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', fontSize: '0.8rem' }}>
                  <span style={{ fontWeight: 600, color: 'var(--muted-foreground)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', marginRight: '10px' }}>
                    {item.label}
                  </span>
                  <span style={{ fontWeight: 800, whiteSpace: 'nowrap' }}>
                    {formatNumber(item.value)} {item.unit || unit}
                  </span>

                </div>
              )) : (
                <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '0.75rem', color: 'var(--muted-foreground)', fontStyle: 'italic' }}>
                  Sin datos detallados
                </div>
              )}
            </div>
          </PremiumCard>
        </div>
      </motion.div>
    </div>
  );
}
