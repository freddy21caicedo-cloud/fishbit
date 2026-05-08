'use client';

import { Package, ArrowRight } from 'lucide-react';
import { PremiumCard } from '../../components/ui/PremiumCard';
import { useMemo, useState } from 'react';
import { useRouter } from 'next/navigation';

interface FeedItem {
  label: string;
  value: string | number;
  unit: string;
}

interface FeedInventorySummaryProps {
  data: FeedItem[];
  inventoryThresholds?: Record<string, number>;
}

export function FeedInventorySummary({ data, inventoryThresholds }: FeedInventorySummaryProps) {
  const router = useRouter();
  const [isHovered, setIsHovered] = useState(false);

  const processedData = useMemo(() => {
    return data.map(item => {
      const weightMatch = item.label.match(/(\d+)\s*kg/i);
      const bagWeight = weightMatch ? parseInt(weightMatch[1]) : 40;
      const bultos = Number((Number(item.value) / bagWeight).toFixed(1));
      return { ...item, bultos, bagWeight };
    });
  }, [data]);

  // Use threshold*4 as the "full" reference for progress bar
  const getBarPercent = (bultos: number, threshold: number) => {
    const max = Math.max(threshold * 4, bultos, 1);
    return Math.min((bultos / max) * 100, 100);
  };

  const getStatus = (bultos: number, threshold: number) => {
    if (bultos < threshold * 0.33) return 'critico';
    if (bultos < threshold) return 'bajo';
    return 'optimo';
  };

  const statusConfig = {
    critico: { label: 'CRÍTICO', bg: 'rgba(239,68,68,0.15)', color: '#dc2626', bar: 'linear-gradient(90deg, #fca5a5, #dc2626)' },
    bajo:    { label: 'BAJO',    bg: 'rgba(245,158,11,0.15)', color: '#d97706', bar: 'linear-gradient(90deg, #fcd34d, #f59e0b)' },
    optimo:  { label: 'ÓPTIMO', bg: 'rgba(16,185,129,0.12)', color: '#10b981', bar: 'linear-gradient(90deg, #34d399, #10b981)' },
  };

  return (
    <PremiumCard style={{ padding: '2rem' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
        <div>
          <h3 style={{ fontSize: '1.1rem', fontWeight: 900, letterSpacing: '-0.02em' }}>Disponibilidad de Alimento (Bultos)</h3>
          <p style={{ fontSize: '0.8rem', color: 'var(--muted-foreground)', fontWeight: 600 }}>Basado en el peso neto por referencia</p>
        </div>
        <div style={{ background: 'rgba(16, 185, 129, 0.1)', color: '#10b981', padding: '0.6rem', borderRadius: '12px' }}>
          <Package size={20} />
        </div>
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
        {processedData.length === 0 ? (
          <div style={{ padding: '2rem', textAlign: 'center', color: 'var(--muted-foreground)', fontWeight: 700 }}>
            No hay registros de alimento en inventario
          </div>
        ) : (
          processedData.map((item, idx) => {
            const threshold = inventoryThresholds?.[item.label] ?? 10;
            const bultosNum = parseFloat(String(item.bultos));
            const status = getStatus(bultosNum, threshold);
            const cfg = statusConfig[status];
            const barPct = getBarPercent(bultosNum, threshold);

            return (
              <div key={idx} style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                    <span style={{ fontSize: '0.85rem', fontWeight: 800 }}>{item.label}</span>
                    <span style={{ background: cfg.bg, color: cfg.color, fontSize: '0.6rem', padding: '2px 6px', borderRadius: '4px', fontWeight: 900,
                      animation: status !== 'optimo' ? 'pulse 2s infinite' : 'none' }}>
                      {cfg.label}
                    </span>
                  </div>
                  <div style={{ textAlign: 'right' }}>
                    <div style={{ fontSize: '1rem', fontWeight: 950, color: status === 'optimo' ? 'var(--foreground)' : cfg.color }}>
                      {bultosNum.toLocaleString('es-CO', { maximumFractionDigits: 1 })} <span style={{ fontSize: '0.7rem', opacity: 0.7 }}>bultos</span>
                    </div>
                  </div>
                </div>

                {/* Progress Bar */}
                <div style={{ width: '100%', height: '8px', background: 'var(--secondary)', borderRadius: '4px', overflow: 'hidden' }}>
                  <div
                    style={{
                      width: `${barPct}%`,
                      height: '100%',
                      background: cfg.bar,
                      borderRadius: '4px',
                      transition: 'width 1s ease-in-out'
                    }}
                  />
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.65rem', fontWeight: 700, color: 'var(--muted-foreground)' }}>
                  <span>Stock: {Number(item.value).toLocaleString('es-CO', { maximumFractionDigits: 1 })} kg (Sacos de {item.bagWeight}kg)</span>
                  <span style={{ color: status !== 'optimo' ? cfg.color : undefined }}>
                    Límite alerta: {threshold} bultos
                  </span>
                </div>
              </div>
            );
          })
        )}
      </div>

      <button 
        onClick={() => router.push('/almacen')}
        onMouseEnter={() => setIsHovered(true)}
        onMouseLeave={() => setIsHovered(false)}
        className="glass" 
        style={{ 
          width: '100%', 
          padding: '0.8rem', 
          borderRadius: '12px', 
          border: '1px solid var(--border)', 
          fontSize: '0.75rem', 
          fontWeight: 800, 
          color: isHovered ? 'white' : 'var(--primary)', 
          background: isHovered ? 'var(--primary)' : 'white',
          marginTop: '2rem', 
          display: 'flex', 
          alignItems: 'center', 
          justifyContent: 'center', 
          gap: '0.5rem', 
          cursor: 'pointer',
          transition: 'all 0.2s ease-in-out',
          boxShadow: isHovered ? '0 4px 12px rgba(13, 148, 136, 0.2)' : 'none'
        }}
      >
        Ver inventario completo <ArrowRight size={14} style={{ transform: isHovered ? 'translateX(3px)' : 'none', transition: 'transform 0.2s ease' }} />
      </button>
    </PremiumCard>
  );
}
