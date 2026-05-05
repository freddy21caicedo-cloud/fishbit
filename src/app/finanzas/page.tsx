'use client';

import { motion } from 'framer-motion';
import { 
  TrendingUp, 
  DollarSign, 
  ArrowUpRight, 
  Wallet,
  PieChart,
  BarChart3
} from 'lucide-react';

export default function FinanzasPage() {
  return (
    <div className="animate-fade-in">
      <header style={{ marginBottom: '2.5rem' }}>
        <h1 style={{ fontSize: '1.875rem', fontWeight: 700, marginBottom: '0.5rem' }}>Gestión Financiera</h1>
        <p style={{ color: 'var(--muted-foreground)' }}>Control de ingresos, egresos y proyecciones de rentabilidad.</p>
      </header>

      {/* Main Investment Card */}
      <div style={{ marginBottom: '3rem' }}>
        <motion.div 
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="card-premium"
          style={{ 
            padding: '2rem', 
            background: 'linear-gradient(135deg, var(--card) 0%, rgba(37, 99, 235, 0.05) 100%)',
            border: '1px solid var(--border)',
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            overflow: 'hidden',
            position: 'relative'
          }}
        >
          {/* Decorative Glow */}
          <div style={{ 
            position: 'absolute', 
            top: '-50px', 
            right: '-50px', 
            width: '200px', 
            height: '200px', 
            background: 'rgba(37, 99, 235, 0.1)', 
            borderRadius: '50%', 
            filter: 'blur(60px)',
            zIndex: 0
          }} />

          <div style={{ position: 'relative', zIndex: 1 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '1rem', color: 'var(--muted-foreground)' }}>
              <div style={{ 
                width: '40px', 
                height: '40px', 
                borderRadius: '10px', 
                background: 'rgba(37, 99, 235, 0.1)', 
                color: 'var(--primary)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center'
              }}>
                <Wallet size={20} />
              </div>
              <span style={{ fontWeight: 600, fontSize: '0.9rem', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Inversión Total de la Unidad</span>
            </div>
            
            <div style={{ display: 'flex', alignItems: 'baseline', gap: '0.5rem' }}>
              <span style={{ fontSize: '3rem', fontWeight: 800, color: 'var(--foreground)' }}>$45,280.00</span>
              <span style={{ fontSize: '1rem', fontWeight: 600, color: '#10b981', display: 'flex', alignItems: 'center', gap: '0.25rem' }}>
                <TrendingUp size={16} />
                +12% este mes
              </span>
            </div>
          </div>

          <div style={{ position: 'relative', zIndex: 1, textAlign: 'right' }}>
            <div style={{ 
              padding: '1rem 1.5rem', 
              background: 'var(--secondary)', 
              borderRadius: 'var(--radius)', 
              border: '1px solid var(--border)',
              display: 'inline-flex',
              flexDirection: 'column',
              alignItems: 'flex-end'
            }}>
              <span style={{ fontSize: '0.75rem', color: 'var(--muted-foreground)', fontWeight: 600, marginBottom: '0.25rem' }}>Retorno Estimado (ROI)</span>
              <span style={{ fontSize: '1.25rem', fontWeight: 700, color: 'var(--primary)' }}>24.5%</span>
            </div>
          </div>
        </motion.div>
      </div>

      {/* Grid for more stats later */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))', gap: '1.5rem' }}>
        <div className="card-premium" style={{ padding: '1.5rem', border: '1px dashed var(--border)', display: 'flex', alignItems: 'center', justifyContent: 'center', minHeight: '150px', color: 'var(--muted-foreground)' }}>
          <div style={{ textAlign: 'center' }}>
            <PieChart size={32} style={{ margin: '0 auto 1rem', opacity: 0.3 }} />
            <p style={{ fontSize: '0.875rem' }}>Distribución de Gastos (Próximamente)</p>
          </div>
        </div>
        <div className="card-premium" style={{ padding: '1.5rem', border: '1px dashed var(--border)', display: 'flex', alignItems: 'center', justifyContent: 'center', minHeight: '150px', color: 'var(--muted-foreground)' }}>
          <div style={{ textAlign: 'center' }}>
            <BarChart3 size={32} style={{ margin: '0 auto 1rem', opacity: 0.3 }} />
            <p style={{ fontSize: '0.875rem' }}>Proyección de Ventas (Próximamente)</p>
          </div>
        </div>
      </div>
    </div>
  );
}
