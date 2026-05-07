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
      // Extraer peso del saco del nombre (ej: "Alimento Iniciador 20kg" -> 20)
      const weightMatch = item.label.match(/(\d+)\s*kg/i);
      const bagWeight = weightMatch ? parseInt(weightMatch[1]) : 40;
      
      // Calcular bultos con 1 decimal
      const bultos = (Number(item.value) / bagWeight).toFixed(1);
      
      return {
        ...item,
        bultos,
        bagWeight
      };
    });
  }, [data]);

  const maxStock = useMemo(() => {
    return Math.max(...data.map(item => Number(item.value)), 1);
  }, [data]);

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
            const percentage = (Number(item.value) / maxStock) * 100;
            const bultosNum = parseFloat(item.bultos);
            const threshold = inventoryThresholds?.[item.label] ?? 10; // Default to 10 if not set
            const isLow = bultosNum < threshold;

            return (
              <div key={idx} style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                    <span style={{ fontSize: '0.85rem', fontWeight: 800 }}>{item.label}</span>
                    {isLow ? (
                      <span style={{ background: 'rgba(239, 68, 68, 0.1)', color: '#ef4444', fontSize: '0.6rem', padding: '2px 6px', borderRadius: '4px', fontWeight: 900 }}>BAJO</span>
                    ) : (
                      <span style={{ background: 'rgba(16, 185, 129, 0.1)', color: '#10b981', fontSize: '0.6rem', padding: '2px 6px', borderRadius: '4px', fontWeight: 900 }}>ÓPTIMO</span>
                    )}
                  </div>
                  <div style={{ textAlign: 'right' }}>
                    <div style={{ fontSize: '1rem', fontWeight: 950, color: isLow ? '#ef4444' : 'var(--foreground)' }}>
                      {item.bultos} <span style={{ fontSize: '0.7rem', opacity: 0.7 }}>bultos</span>
                    </div>
                  </div>
                </div>
                
                {/* Progress Bar */}
                <div style={{ width: '100%', height: '8px', background: 'var(--secondary)', borderRadius: '4px', overflow: 'hidden' }}>
                  <div 
                    style={{ 
                      width: `${percentage}%`, 
                      height: '100%', 
                      background: isLow ? 'linear-gradient(90deg, #f87171, #ef4444)' : 'linear-gradient(90deg, #34d399, #10b981)',
                      borderRadius: '4px',
                      transition: 'width 1s ease-in-out'
                    }} 
                  />
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.65rem', fontWeight: 700, color: 'var(--muted-foreground)' }}>
                  <span>Stock: {Number(item.value).toLocaleString()} kg (Sacos de {item.bagWeight}kg)</span>
                  <span>{percentage.toFixed(0)}%</span>
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
