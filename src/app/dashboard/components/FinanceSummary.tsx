'use client';

import Link from 'next/link';
import { ChevronRight, Utensils, Fish, AlertCircle, TrendingUp, Loader2, ArrowUpRight } from 'lucide-react';
import { PremiumCard } from '../../components/ui/PremiumCard';

interface FinanceSummaryProps {
  data: {
    total: number;
    food: number;
    seeds: number;
    pending: number;
  };
  isLoading: boolean;
}

export function FinanceSummary({ data, isLoading }: FinanceSummaryProps) {
  return (
    <PremiumCard style={{ padding: '2rem' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
        <h3 style={{ fontSize: '0.85rem', fontWeight: 900, color: 'var(--muted-foreground)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Resumen Financiero</h3>
        <div style={{ padding: '0.4rem 0.75rem', background: 'rgba(16, 185, 129, 0.1)', color: '#10b981', borderRadius: '8px', fontSize: '0.7rem', fontWeight: 800 }}>
          {new Date().toLocaleDateString('es-CO', { month: 'long', year: 'numeric' }).toUpperCase()}
        </div>
      </div>
      
      <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem', position: 'relative' }}>
        {isLoading && (
          <div style={{ position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center', background: 'rgba(255,255,255,0.4)', zIndex: 5, borderRadius: '16px' }}>
            <Loader2 className="animate-spin" size={24} color="var(--primary)" />
          </div>
        )}
        
        <div style={{ padding: '1.5rem', background: 'linear-gradient(135deg, #0d9488 0%, #0f766e 100%)', borderRadius: '20px', color: 'white', position: 'relative', overflow: 'hidden' }}>
          <div style={{ position: 'absolute', right: '-10px', bottom: '-10px', opacity: 0.1 }}>
            <TrendingUp size={80} />
          </div>
          <div style={{ fontSize: '0.75rem', fontWeight: 700, opacity: 0.9, marginBottom: '0.25rem', textTransform: 'uppercase' }}>Inversión Total Finca</div>
          <div style={{ fontSize: '2rem', fontWeight: 950, letterSpacing: '-0.03em' }}>
            ${data.total.toLocaleString('es-CO')}
          </div>
        </div>

        {[
          { label: 'Alimento Acumulado', value: data.food, color: '#10b981', icon: Utensils },
          { label: 'Siembra de Alevinos', value: data.seeds, color: '#3b82f6', icon: Fish },
          { label: 'Cuentas por Pagar', value: data.pending, color: '#ef4444', icon: AlertCircle }
        ].map((item, idx) => (
          <div key={idx} className="glass" style={{ display: 'flex', alignItems: 'center', gap: '1rem', padding: '1rem', borderRadius: '16px' }}>
            <div style={{ padding: '0.6rem', background: `${item.color}15`, color: item.color, borderRadius: '10px' }}>
              <item.icon size={18} />
            </div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: '0.8rem', color: 'var(--muted-foreground)', fontWeight: 700 }}>{item.label}</div>
              <div style={{ fontSize: '1rem', fontWeight: 900 }}>${item.value.toLocaleString('es-CO')}</div>
            </div>
            <ArrowUpRight size={16} style={{ color: 'var(--muted-foreground)', opacity: 0.5 }} />
          </div>
        ))}
      </div>

      <Link href="/finanzas" style={{ textDecoration: 'none' }}>
        <button className="btn-primary" style={{ width: '100%', marginTop: '2rem', padding: '1rem', background: 'transparent', border: '1px solid var(--border)', color: 'var(--foreground)', borderRadius: '14px', fontWeight: 800, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '0.5rem' }}>
          Ir a Gestión Financiera <ChevronRight size={18} />
        </button>
      </Link>
    </PremiumCard>
  );
}
