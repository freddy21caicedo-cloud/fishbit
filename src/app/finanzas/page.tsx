'use client';

import { useEffect, useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { useSearchParams } from 'next/navigation';
import { DollarSign, LayoutDashboard, Users, BarChart3, ShoppingCart, FileSpreadsheet } from 'lucide-react';
import { useUnit } from '../components/providers/UnitProvider';
import { PanelGeneral } from './components/PanelGeneral';
import { NominaJornales } from './components/NominaJornales';
import { CostosPorEstanque } from './components/CostosPorEstanque';
import { ModuloVentas } from './components/ModuloVentas';
import { ExportarReporte } from './components/ExportarReporte';

const TABS = [
  { id: 'panel',    label: 'Panel General',     icon: LayoutDashboard },
  { id: 'nomina',   label: 'Nómina & Jornales', icon: Users },
  { id: 'costos',   label: 'Costos / Estanque', icon: BarChart3 },
  { id: 'ventas',   label: 'Ventas',            icon: ShoppingCart },
  { id: 'exportar', label: 'Exportar',          icon: FileSpreadsheet },
];

export default function FinanzasPage() {
  const { activeUnitId } = useUnit();
  const searchParams = useSearchParams();
  const [activeTab, setActiveTab] = useState(searchParams.get('tab') || 'panel');

  useEffect(() => {
    const tab = searchParams.get('tab');
    if (tab && TABS.some(t => t.id === tab)) {
      setActiveTab(tab);
    }
  }, [searchParams]);

  return (
    <div className="animate-fade-in page-container">
      <header style={{ marginBottom: '2rem' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', marginBottom: '0.5rem' }}>
          <div style={{ width: '48px', height: '48px', background: 'linear-gradient(135deg, #059669, #10b981)', borderRadius: '14px', color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 8px 24px rgba(16,185,129,0.3)' }}>
            <DollarSign size={26} />
          </div>
          <div>
            <h1 style={{ fontWeight: 900, letterSpacing: '-0.04em' }}>Gestión Financiera</h1>
            <p style={{ color: 'var(--muted-foreground)', fontWeight: 600, fontSize: '0.9rem' }}>Control de costos, ventas y rentabilidad en tiempo real</p>
          </div>
        </div>
      </header>

      {/* Tab Navigation */}
      <div style={{ display: 'flex', gap: '0.5rem', flexWrap: 'wrap', marginBottom: '2rem', padding: '0.4rem', background: 'var(--secondary)', borderRadius: '14px', width: 'fit-content' }}>
        {TABS.map(tab => {
          const Icon = tab.icon;
          const isActive = activeTab === tab.id;
          return (
            <button key={tab.id} onClick={() => setActiveTab(tab.id)}
              style={{
                display: 'flex', alignItems: 'center', gap: '0.5rem',
                padding: '0.6rem 1.1rem', borderRadius: '10px', border: 'none', cursor: 'pointer',
                fontWeight: 800, fontSize: '0.82rem', transition: 'all 0.2s ease',
                background: isActive ? 'var(--card)' : 'transparent',
                color: isActive ? 'var(--primary)' : 'var(--muted-foreground)',
                boxShadow: isActive ? '0 2px 8px rgba(0,0,0,0.08)' : 'none',
              }}>
              <Icon size={15} />
              {tab.label}
            </button>
          );
        })}
      </div>

      {/* Tab Content */}
      <AnimatePresence mode="wait">
        <motion.div key={activeTab} initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -8 }} transition={{ duration: 0.2 }}>
          {!activeUnitId ? (
            <div className="card-premium" style={{ padding: '3rem', textAlign: 'center', color: 'var(--muted-foreground)' }}>
              Selecciona una unidad acuícola para ver los datos financieros.
            </div>
          ) : activeTab === 'panel' ? (
            <PanelGeneral unitId={activeUnitId} />
          ) : activeTab === 'nomina' ? (
            <NominaJornales unitId={activeUnitId} />
          ) : activeTab === 'costos' ? (
            <CostosPorEstanque unitId={activeUnitId} />
          ) : activeTab === 'ventas' ? (
            <ModuloVentas unitId={activeUnitId} />
          ) : (
            <ExportarReporte unitId={activeUnitId} />
          )}
        </motion.div>
      </AnimatePresence>
    </div>
  );
}
