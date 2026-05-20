'use client';

import { useState, useMemo } from 'react';
import { motion } from 'framer-motion';
import { Calendar, Target, Scale, Hourglass, ArrowUpRight } from 'lucide-react';
import { PremiumCard } from '../../components/ui/PremiumCard';

interface HarvestEstimatorProps {
  selectedPondId: string;
  ponds: any[];
}

export function HarvestEstimator({ selectedPondId, ponds }: HarvestEstimatorProps) {
  const [targetWeight, setTargetWeight] = useState<number>(450); // Default commercial target weight in grams

  const activePond = useMemo(() => {
    return ponds.find(p => p.id === selectedPondId);
  }, [ponds, selectedPondId]);

  const projection = useMemo(() => {
    if (!activePond) return null;

    const biomass = parseFloat(activePond.current_biomass_kg) || 0;
    const count = parseInt(activePond.current_count) || 0;
    const species = activePond.species || 'Sin clasificar';

    // Calculate current average weight in grams
    const currentAvgWeight = count > 0 ? parseFloat(((biomass * 1000) / count).toFixed(1)) : 0;

    // Define growth rate based on species and current size (Standard aquaculture growth curves)
    let dailyGrowthGrams = 3.2; // default
    if (species.toLowerCase().includes('tilapia')) {
      dailyGrowthGrams = currentAvgWeight < 100 ? 2.5 : 3.8;
    } else if (species.toLowerCase().includes('trucha')) {
      dailyGrowthGrams = currentAvgWeight < 100 ? 3.0 : 4.5;
    }

    const weightDifference = targetWeight - currentAvgWeight;
    const daysRemaining = weightDifference > 0 ? Math.ceil(weightDifference / dailyGrowthGrams) : 0;

    // Calculate estimated harvest date
    const harvestDate = new Date();
    harvestDate.setDate(harvestDate.getDate() + daysRemaining);

    // Calculate percentage completion of commercial target weight
    const progressPct = Math.min(Math.round((currentAvgWeight / targetWeight) * 100), 100);

    return {
      currentAvgWeight,
      daysRemaining,
      harvestDate,
      progressPct,
      species,
      dailyGrowthGrams
    };
  }, [activePond, targetWeight]);

  if (!activePond) {
    return (
      <PremiumCard style={{ padding: '1.5rem', display: 'flex', alignItems: 'center', justifyContent: 'center', height: '100%', minHeight: '340px' }}>
        <p style={{ color: 'var(--muted-foreground)', fontSize: '0.8rem', fontWeight: 800, textTransform: 'uppercase', letterSpacing: '0.05em' }}>
          Selecciona un estanque activo para proyectar la cosecha
        </p>
      </PremiumCard>
    );
  }

  return (
    <PremiumCard style={{ 
      padding: '2rem', 
      background: 'var(--card)', 
      border: '1px solid var(--border)', 
      display: 'flex', 
      flexDirection: 'column', 
      justifyContent: 'space-between',
      gap: '1.25rem',
      minHeight: '340px'
    }}>
      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
        <div>
          <h4 style={{ fontSize: '0.8rem', fontWeight: 900, textTransform: 'uppercase', letterSpacing: '0.08em', color: 'var(--muted-foreground)' }}>
            Proyección de Crecimiento y Cosecha
          </h4>
          <h3 style={{ fontSize: '1.25rem', fontWeight: 950, letterSpacing: '-0.02em', marginTop: '0.2rem', color: 'var(--foreground)' }}>
            Estanque: {activePond.name}
          </h3>
        </div>
        <span style={{ 
          background: 'rgba(59, 130, 246, 0.1)', 
          color: '#3b82f6', 
          fontSize: '0.65rem', 
          padding: '4px 10px', 
          borderRadius: '8px', 
          fontWeight: 900,
          textTransform: 'uppercase'
        }}>
          {projection?.species}
        </span>
      </div>

      {projection ? (
        <>
          {/* Main projection metrics */}
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1.25rem', borderBottom: '1px solid var(--border)', paddingBottom: '1.25rem' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
              <div style={{ padding: '0.5rem', background: '#3b82f612', color: '#3b82f6', borderRadius: '10px' }}>
                <Scale size={20} />
              </div>
              <div>
                <div style={{ fontSize: '0.6rem', fontWeight: 800, color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Peso Prom. Actual</div>
                <div style={{ fontSize: '1.25rem', fontWeight: 950 }}>
                  {projection.currentAvgWeight} <span style={{ fontSize: '0.8rem', fontWeight: 800 }}>gr</span>
                </div>
              </div>
            </div>

            <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
              <div style={{ padding: '0.5rem', background: '#ef444412', color: '#ef4444', borderRadius: '10px' }}>
                <Target size={20} />
              </div>
              <div>
                <div style={{ fontSize: '0.6rem', fontWeight: 800, color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Peso Objetivo Comercial</div>
                <div style={{ fontSize: '1.25rem', fontWeight: 950 }}>
                  {targetWeight} <span style={{ fontSize: '0.8rem', fontWeight: 800 }}>gr</span>
                </div>
              </div>
            </div>
          </div>

          {/* Interactive target weight slider */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.7rem', fontWeight: 800, color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>
              <span>Ajustar peso objetivo</span>
              <span style={{ color: 'var(--primary)' }}>{targetWeight} gr</span>
            </div>
            <input 
              type="range" 
              min="300" 
              max="1000" 
              step="10"
              value={targetWeight} 
              onChange={(e) => setTargetWeight(parseInt(e.target.value))}
              style={{
                width: '100%',
                height: '6px',
                background: 'var(--secondary)',
                borderRadius: '3px',
                outline: 'none',
                accentColor: 'var(--primary)',
                cursor: 'pointer'
              }}
            />
          </div>

          {/* Weight Growth Progress bar */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.65rem', fontWeight: 700, color: 'var(--muted-foreground)' }}>
              <span>Progreso de engorde comercial</span>
              <span>{projection.progressPct}%</span>
            </div>
            <div style={{ width: '100%', height: '8px', background: 'var(--secondary)', borderRadius: '4px', overflow: 'hidden' }}>
              <motion.div
                initial={{ width: 0 }}
                animate={{ width: `${projection.progressPct}%` }}
                transition={{ duration: 1, ease: 'easeOut' }}
                style={{
                  height: '100%',
                  background: 'linear-gradient(90deg, #3b82f6, #0d9488)',
                  borderRadius: '4px'
                }}
              />
            </div>
          </div>

          {/* Estimated Harvest outputs */}
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem', background: 'var(--secondary)30', padding: '0.85rem', borderRadius: '16px', border: '1px solid var(--border)' }}>
            <div style={{ display: 'flex', gap: '0.5rem', alignItems: 'center' }}>
              <Hourglass size={18} color="#0d9488" />
              <div>
                <div style={{ fontSize: '0.55rem', fontWeight: 800, color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Días Restantes</div>
                <div style={{ fontSize: '0.95rem', fontWeight: 950, color: '#0d9488' }}>
                  {projection.daysRemaining} <span style={{ fontSize: '0.7rem', fontWeight: 800 }}>días</span>
                </div>
              </div>
            </div>

            <div style={{ display: 'flex', gap: '0.5rem', alignItems: 'center' }}>
              <Calendar size={18} color="var(--primary)" />
              <div>
                <div style={{ fontSize: '0.55rem', fontWeight: 800, color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Fecha de Cosecha</div>
                <div style={{ fontSize: '0.95rem', fontWeight: 950 }}>
                  {projection.harvestDate.toLocaleDateString('es-CO', { day: 'numeric', month: 'short' })}
                </div>
              </div>
            </div>
          </div>

          {/* Dynamic insights footer */}
          <div style={{ fontSize: '0.65rem', color: 'var(--muted-foreground)', fontWeight: 650, display: 'flex', alignItems: 'center', gap: '0.25rem', marginTop: '-0.25rem' }}>
            <span>📈 Asumiendo crecimiento de ~{projection.dailyGrowthGrams}g/día para {projection.species}.</span>
            <ArrowUpRight size={12} />
          </div>
        </>
      ) : (
        <div style={{ textAlign: 'center', color: 'var(--muted-foreground)', fontSize: '0.75rem', fontStyle: 'italic', padding: '2rem' }}>
          No hay datos de biometría disponibles en este estanque
        </div>
      )}
    </PremiumCard>
  );
}
