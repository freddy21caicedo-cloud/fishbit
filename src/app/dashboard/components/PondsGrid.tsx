'use client';

import { motion } from 'framer-motion';
import { Fish, Thermometer, Droplet, Activity, Trash2, Settings } from 'lucide-react';
import { PremiumCard } from '../../components/ui/PremiumCard';

export interface EnhancedPond {
  id: string;
  name: string;
  status: 'vacio' | 'con_peces' | 'mantenimiento';
  current_biomass_kg?: number;
  current_count?: number;
  species?: string;
  speciesDetails?: Array<{
    species_name: string;
    current_count: number;
    current_biomass_kg: number;
    batch_id: string;
  }>;
  oxygen?: number;
  temperature?: number;
  ph?: number;
  healthState: 'healthy' | 'warning' | 'critical';
}

interface PondsGridProps {
  ponds: EnhancedPond[];
  selectedPond: string;
  onSelectPond: (id: string) => void;
}

export function PondsGrid({ ponds, selectedPond, onSelectPond }: PondsGridProps) {
  const healthConfig = {
    healthy: { 
      label: 'Saludable', 
      color: '#10b981', 
      bg: 'rgba(16, 185, 129, 0.08)', 
      border: 'rgba(16, 185, 129, 0.25)',
      glow: '0 0 15px rgba(16, 185, 129, 0.1)'
    },
    warning: { 
      label: 'Advertencia', 
      color: '#f59e0b', 
      bg: 'rgba(245, 158, 11, 0.08)', 
      border: 'rgba(245, 158, 11, 0.25)',
      glow: '0 0 15px rgba(245, 158, 11, 0.1)'
    },
    critical: { 
      label: 'Alerta', 
      color: '#ef4444', 
      bg: 'rgba(239, 68, 68, 0.08)', 
      border: 'rgba(239, 68, 68, 0.3)',
      glow: '0 0 15px rgba(239, 68, 68, 0.15)'
    }
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem', width: '100%' }}>
      <div>
        <h3 style={{ fontSize: '1.25rem', fontWeight: 950, letterSpacing: '-0.02em', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
          <Activity size={20} color="var(--primary)" /> Mapa Operativo de Estanques
        </h3>
        <p style={{ fontSize: '0.8rem', color: 'var(--muted-foreground)', fontWeight: 600 }}>
          Seleccione un estanque para ver sus tendencias detalladas e historial
        </p>
      </div>

      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fill, minmax(260px, 1fr))',
        gap: '1.25rem',
        width: '100%'
      }}>
        {ponds.length === 0 ? (
          <div style={{ 
            gridColumn: '1 / -1', 
            padding: '3rem', 
            textAlign: 'center', 
            background: 'var(--card)', 
            border: '1px dashed var(--border)', 
            borderRadius: '16px',
            color: 'var(--muted-foreground)',
            fontWeight: 700 
          }}>
            No hay estanques activos registrados
          </div>
        ) : (
          ponds.map((pond) => {
            const isSelected = selectedPond === pond.id;
            const health = healthConfig[pond.healthState] || healthConfig.healthy;

            return (
              <motion.div
                key={pond.id}
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
                onClick={() => onSelectPond(pond.id)}
                style={{ cursor: 'pointer' }}
              >
                <PremiumCard
                  hover={false}
                  style={{
                    height: '100%',
                    padding: '1.25rem',
                    display: 'flex',
                    flexDirection: 'column',
                    justifyContent: 'space-between',
                    gap: '1rem',
                    border: isSelected 
                      ? `2.5px solid var(--primary)` 
                      : `1px solid ${health.border}`,
                    background: isSelected 
                      ? 'var(--card)' 
                      : 'var(--card)',
                    boxShadow: isSelected 
                      ? `0 12px 30px rgba(27, 46, 94, 0.12), ${health.glow}`
                      : health.glow,
                    borderRadius: '20px',
                    transition: 'border 0.25s ease, box-shadow 0.25s ease',
                    position: 'relative'
                  }}
                >
                  {/* Status indicator bar top */}
                  <div style={{
                    position: 'absolute',
                    top: 0,
                    left: 0,
                    right: 0,
                    height: '5px',
                    background: health.color,
                    borderTopLeftRadius: '20px',
                    borderTopRightRadius: '20px'
                  }} />

                  {/* Header */}
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                    <div>
                      <h4 style={{ fontSize: '1.1rem', fontWeight: 900, letterSpacing: '-0.02em' }}>{pond.name}</h4>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', marginTop: '0.2rem' }}>
                        <span style={{ 
                          width: '8px', 
                          height: '8px', 
                          borderRadius: '50%', 
                          background: health.color,
                          display: 'inline-block',
                          animation: pond.healthState !== 'healthy' ? 'pulse 1.5s infinite' : 'none'
                        }} />
                        <span style={{ fontSize: '0.65rem', fontWeight: 800, color: 'var(--muted-foreground)' }}>
                          {pond.species || 'Sin especies'}
                        </span>
                      </div>
                    </div>
                    
                    <span style={{ 
                      fontSize: '0.55rem', 
                      background: health.bg, 
                      color: health.color, 
                      padding: '3px 8px', 
                      borderRadius: '8px', 
                      fontWeight: 950,
                      textTransform: 'uppercase',
                      letterSpacing: '0.05em',
                      border: `1px solid ${health.border}`
                    }}>
                      {health.label}
                    </span>
                  </div>

                  {/* Biomass & Population details */}
                  <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.75rem', borderBottom: '1px solid var(--border)', paddingBottom: '0.75rem' }}>
                    <div>
                      <div style={{ color: 'var(--muted-foreground)', fontWeight: 700, fontSize: '0.6rem', textTransform: 'uppercase' }}>Biomasa</div>
                      <div style={{ fontWeight: 900, fontSize: '0.9rem', display: 'flex', alignItems: 'baseline', gap: '0.1rem' }}>
                        {pond.current_biomass_kg ? pond.current_biomass_kg.toLocaleString('es-CO', { maximumFractionDigits: 1 }) : 0} 
                        <span style={{ fontSize: '0.65rem', fontWeight: 700, opacity: 0.7 }}>kg</span>
                      </div>
                    </div>
                    <div style={{ textAlign: 'right' }}>
                      <div style={{ color: 'var(--muted-foreground)', fontWeight: 700, fontSize: '0.6rem', textTransform: 'uppercase' }}>Población</div>
                      <div style={{ fontWeight: 900, fontSize: '0.9rem', display: 'flex', alignItems: 'baseline', gap: '0.1rem', justifyContent: 'flex-end' }}>
                        {pond.current_count ? pond.current_count.toLocaleString('es-CO') : 0}
                        <span style={{ fontSize: '0.65rem', fontWeight: 700, opacity: 0.7 }}>uds</span>
                      </div>
                    </div>
                  </div>

                  {/* Premium Glassmorphic Species & Batch breakdown */}
                  {pond.speciesDetails && pond.speciesDetails.length > 0 && (
                    <div style={{
                      background: 'rgba(13, 148, 136, 0.04)',
                      backdropFilter: 'blur(8px)',
                      border: '1px solid rgba(13, 148, 136, 0.15)',
                      borderRadius: '14px',
                      padding: '0.6rem 0.8rem',
                      display: 'flex',
                      flexDirection: 'column',
                      gap: '0.5rem',
                    }}>
                      <div style={{ 
                        fontWeight: 800, 
                        color: '#0d9488', 
                        fontSize: '0.55rem', 
                        textTransform: 'uppercase', 
                        letterSpacing: '0.05em',
                        display: 'flex',
                        alignItems: 'center',
                        gap: '0.25rem'
                      }}>
                        <Fish size={10} /> Desglose por Especie y Lote
                      </div>
                      <div style={{ display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
                        {pond.speciesDetails.map((spec, index) => (
                          <div 
                            key={index} 
                            style={{ 
                              display: 'flex', 
                              justifyContent: 'space-between', 
                              alignItems: 'center',
                              paddingBottom: index < pond.speciesDetails!.length - 1 ? '0.35rem' : '0',
                              borderBottom: index < pond.speciesDetails!.length - 1 ? '1px dashed rgba(13, 148, 136, 0.1)' : 'none',
                              fontSize: '0.7rem'
                            }}
                          >
                            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.05rem' }}>
                              <span style={{ fontWeight: 800, color: 'var(--foreground)' }}>
                                {spec.species_name}
                              </span>
                              <span style={{ 
                                fontSize: '0.58rem', 
                                color: 'var(--muted-foreground)', 
                                fontFamily: 'monospace',
                                letterSpacing: '-0.02em'
                              }}>
                                {spec.batch_id}
                              </span>
                            </div>
                            <div style={{ textAlign: 'right', fontWeight: 700 }}>
                              <div style={{ color: 'var(--foreground)' }}>
                                {spec.current_count.toLocaleString('es-CO')} <span style={{ fontSize: '0.55rem', opacity: 0.7 }}>uds</span>
                              </div>
                              <div style={{ fontSize: '0.65rem', color: '#0d9488' }}>
                                {spec.current_biomass_kg.toLocaleString('es-CO', { maximumFractionDigits: 1 })} <span style={{ fontSize: '0.55rem', opacity: 0.7 }}>kg</span>
                              </div>
                            </div>
                          </div>
                        ))}
                      </div>
                    </div>
                  )}

                  {/* Real-time Parameters */}
                  <div style={{ display: 'flex', justifyContent: 'space-between', gap: '0.5rem' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.3rem', flex: 1 }}>
                      <div style={{ padding: '0.35rem', background: '#3b82f612', color: '#3b82f6', borderRadius: '8px' }}>
                        <Droplet size={14} />
                      </div>
                      <div>
                        <div style={{ color: 'var(--muted-foreground)', fontSize: '0.55rem', fontWeight: 700, textTransform: 'uppercase' }}>O2</div>
                        <div style={{ fontSize: '0.75rem', fontWeight: 900 }}>
                          {pond.oxygen ? `${pond.oxygen.toFixed(1)} mg/L` : '--'}
                        </div>
                      </div>
                    </div>

                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.3rem', flex: 1 }}>
                      <div style={{ padding: '0.35rem', background: '#ef444412', color: '#ef4444', borderRadius: '8px' }}>
                        <Thermometer size={14} />
                      </div>
                      <div>
                        <div style={{ color: 'var(--muted-foreground)', fontSize: '0.55rem', fontWeight: 700, textTransform: 'uppercase' }}>Temp</div>
                        <div style={{ fontSize: '0.75rem', fontWeight: 900 }}>
                          {pond.temperature ? `${pond.temperature.toFixed(1)} °C` : '--'}
                        </div>
                      </div>
                    </div>

                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.3rem', flex: 1 }}>
                      <div style={{ padding: '0.35rem', background: '#8b5cf612', color: '#8b5cf6', borderRadius: '8px' }}>
                        <Settings size={14} />
                      </div>
                      <div>
                        <div style={{ color: 'var(--muted-foreground)', fontSize: '0.55rem', fontWeight: 700, textTransform: 'uppercase' }}>pH</div>
                        <div style={{ fontSize: '0.75rem', fontWeight: 900 }}>
                          {pond.ph ? pond.ph.toFixed(1) : '--'}
                        </div>
                      </div>
                    </div>
                  </div>
                </PremiumCard>
              </motion.div>
            );
          })
        )}
      </div>
    </div>
  );
}
