'use client';

import { motion } from 'framer-motion';
import { 
  TrendingUp, 
  DollarSign, 
  ArrowUpRight, 
  Wallet,
  PieChart,
  BarChart3,
  TrendingDown,
  ChevronRight,
  ArrowRightLeft
} from 'lucide-react';

export default function FinanzasPage() {
  return (
    <div className="animate-fade-in page-container">
      <header style={{ marginBottom: '3rem' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', marginBottom: '0.5rem' }}>
          <div style={{ width: '48px', height: '48px', background: '#059669', borderRadius: '14px', color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
             <DollarSign size={26} />
          </div>
          <h1 style={{ fontWeight: 900, letterSpacing: '-0.04em' }}>Gestión Financiera</h1>
        </div>
        <p style={{ color: 'var(--muted-foreground)', fontWeight: 600 }}>Balance general, flujos de caja y proyecciones de rentabilidad.</p>
      </header>

      {/* Main Investment Summary */}
      <div style={{ marginBottom: '2.5rem' }}>
        <motion.div 
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="card-premium"
          style={{ 
            padding: '2.5rem', 
            background: 'linear-gradient(135deg, var(--card) 0%, rgba(16, 185, 129, 0.05) 100%)',
            border: '1px solid var(--border)',
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            overflow: 'hidden',
            position: 'relative',
            flexWrap: 'wrap',
            gap: '2rem'
          }}
        >
          {/* Decorative Glow */}
          <div style={{ 
            position: 'absolute', 
            top: '-50px', 
            right: '-50px', 
            width: '200px', 
            height: '200px', 
            background: 'rgba(16, 185, 129, 0.1)', 
            borderRadius: '50%', 
            filter: 'blur(60px)',
            zIndex: 0
          }} />

          <div style={{ position: 'relative', zIndex: 1 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '1.25rem' }}>
              <div style={{ 
                padding: '0.6rem',
                borderRadius: '12px', 
                background: 'rgba(16, 185, 129, 0.1)', 
                color: '#059669'
              }}>
                <Wallet size={22} />
              </div>
              <span style={{ fontWeight: 800, fontSize: '0.85rem', color: 'var(--muted-foreground)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Inversión Total Acumulada</span>
            </div>
            
            <div style={{ display: 'flex', alignItems: 'baseline', gap: '0.75rem' }}>
              <span style={{ fontSize: '3.5rem', fontWeight: 950, color: 'var(--foreground)', letterSpacing: '-0.04em' }}>$45,280</span>
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.25rem', color: '#10b981', background: 'rgba(16, 185, 129, 0.1)', padding: '4px 10px', borderRadius: '8px', fontSize: '0.85rem', fontWeight: 800 }}>
                <TrendingUp size={16} />
                +12.4%
              </div>
            </div>
            <p style={{ marginTop: '0.75rem', fontSize: '0.9rem', color: 'var(--muted-foreground)', fontWeight: 600 }}>Actualizado hoy a las 08:30 AM</p>
          </div>

          <div style={{ position: 'relative', zIndex: 1, display: 'flex', gap: '1.5rem' }}>
            <div className="glass" style={{ padding: '1.25rem 1.75rem', borderRadius: '20px', border: '1px solid var(--border)', textAlign: 'center' }}>
              <span style={{ fontSize: '0.75rem', color: 'var(--muted-foreground)', fontWeight: 800, textTransform: 'uppercase', marginBottom: '0.4rem', display: 'block' }}>ROI Estimado</span>
              <span style={{ fontSize: '1.5rem', fontWeight: 900, color: '#059669' }}>24.5%</span>
            </div>
            <div className="glass" style={{ padding: '1.25rem 1.75rem', borderRadius: '20px', border: '1px solid var(--border)', textAlign: 'center' }}>
              <span style={{ fontSize: '0.75rem', color: 'var(--muted-foreground)', fontWeight: 800, textTransform: 'uppercase', marginBottom: '0.4rem', display: 'block' }}>Margen</span>
              <span style={{ fontSize: '1.5rem', fontWeight: 900, color: '#059669' }}>32.1%</span>
            </div>
          </div>
        </motion.div>
      </div>

      <div className="responsive-grid-3" style={{ marginBottom: '2.5rem' }}>
        <FinStatCard title="Ingresos Mensuales" value="$18,400" change="+8.2%" icon={TrendingUp} color="#10b981" />
        <FinStatCard title="Gastos Operativos" value="$12,150" change="-3.5%" icon={TrendingDown} color="#ef4444" />
        <FinStatCard title="Caja Disponible" value="$6,250" change="+15%" icon={ArrowRightLeft} color="#3b82f6" />
      </div>

      <div className="responsive-grid-2">
        <div className="card-premium" style={{ padding: '2rem', minHeight: '300px', display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <h3 style={{ fontWeight: 900, fontSize: '1.1rem', letterSpacing: '-0.02em' }}>Distribución de Costos</h3>
            <PieChart size={20} style={{ color: 'var(--muted-foreground)' }} />
          </div>
          <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', border: '2px dashed var(--border)', borderRadius: '24px' }}>
            <div style={{ textAlign: 'center' }}>
              <p style={{ fontSize: '0.9rem', color: 'var(--muted-foreground)', fontWeight: 600 }}>Visualización en desarrollo...</p>
              <button className="btn-primary" style={{ marginTop: '1rem', padding: '0.6rem 1.2rem', background: 'transparent', border: '1px solid var(--border)', color: 'var(--foreground)', borderRadius: '12px', fontSize: '0.8rem', fontWeight: 800 }}>Conectar ERP</button>
            </div>
          </div>
        </div>

        <div className="card-premium" style={{ padding: '2rem', minHeight: '300px', display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <h3 style={{ fontWeight: 900, fontSize: '1.1rem', letterSpacing: '-0.02em' }}>Proyección de Cosecha</h3>
            <BarChart3 size={20} style={{ color: 'var(--muted-foreground)' }} />
          </div>
          <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', border: '2px dashed var(--border)', borderRadius: '24px' }}>
            <div style={{ textAlign: 'center' }}>
              <p style={{ fontSize: '0.9rem', color: 'var(--muted-foreground)', fontWeight: 600 }}>Datos históricos insuficientes</p>
              <button className="btn-primary" style={{ marginTop: '1rem', padding: '0.6rem 1.2rem', background: 'transparent', border: '1px solid var(--border)', color: 'var(--foreground)', borderRadius: '12px', fontSize: '0.8rem', fontWeight: 800 }}>Analizar Tendencias</button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

const FinStatCard = ({ title, value, change, icon: Icon, color }: any) => (
  <div className="card-premium" style={{ padding: '1.5rem' }}>
    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '1rem' }}>
      <div style={{ padding: '0.6rem', background: `${color}15`, borderRadius: '12px', color: color }}>
        <Icon size={22} />
      </div>
      <div style={{ fontSize: '0.75rem', fontWeight: 900, color: change.startsWith('+') ? '#10b981' : '#ef4444', background: `${change.startsWith('+') ? '#10b981' : '#ef4444'}10`, padding: '4px 8px', borderRadius: '6px' }}>
        {change}
      </div>
    </div>
    <div style={{ fontSize: '1.5rem', fontWeight: 900, marginBottom: '0.25rem', letterSpacing: '-0.02em' }}>{value}</div>
    <div style={{ fontSize: '0.8rem', color: 'var(--muted-foreground)', fontWeight: 700, textTransform: 'uppercase' }}>{title}</div>
  </div>
);
