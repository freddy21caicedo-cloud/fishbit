'use client';

import { 
  AreaChart, 
  Area, 
  XAxis, 
  YAxis, 
  CartesianGrid, 
  Tooltip, 
  ResponsiveContainer,
  LabelList,
  ReferenceLine
} from 'recharts';
import { AnimatePresence, motion } from 'framer-motion';
import { useEffect, useState, useMemo } from 'react';
import { Loader2 } from 'lucide-react';
import { PremiumCard } from '../../components/ui/PremiumCard';

interface TrendsChartProps {
  data: any[];
  isLoading: boolean;
  selectedPond: string;
  selectedParam: string;
  onPondChange: (val: string) => void;
  onParamChange: (val: string) => void;
  ponds: any[];
  isPolyculture?: boolean;
  pondSpecies?: any[];
  selectedSpecies?: string;
  setSelectedSpecies?: (val: string) => void;
  thresholds?: any;
}

const CustomTooltip = ({ active, payload, label, unit }: any) => {
  if (active && payload && payload.length) {
    return (
      <div className="glass" style={{ 
        padding: '1rem', 
        borderRadius: '18px', 
        background: 'white',
        border: '1px solid rgba(0,0,0,0.05)',
        boxShadow: '0 15px 35px rgba(0,0,0,0.1)',
        minWidth: '140px'
      }}>
        <div style={{ fontSize: '0.65rem', fontWeight: 900, color: '#94a3b8', textTransform: 'uppercase', marginBottom: '0.4rem', letterSpacing: '0.05em' }}>
          {label}
        </div>
        <div style={{ display: 'flex', alignItems: 'baseline', gap: '0.25rem' }}>
          <div style={{ fontSize: '1.5rem', fontWeight: 950, color: payload[0].color }}>
            {payload[0].value}
          </div>
          <div style={{ fontSize: '0.75rem', fontWeight: 800, color: '#64748b' }}>{unit}</div>
        </div>
      </div>
    );
  }
  return null;
};

export function TrendsChart({ 
  data, 
  isLoading, 
  selectedPond, 
  selectedParam, 
  onPondChange, 
  onParamChange, 
  ponds,
  isPolyculture,
  pondSpecies = [],
  selectedSpecies = 'Todas',
  setSelectedSpecies,
  thresholds
}: TrendsChartProps) {
  
  const getParamLabel = () => {
    switch(selectedParam) {
      case 'o2_mg_l': case 'oxigeno': return 'Oxígeno (mg/L)';
      case 'o2_perc': return 'Saturación O2 (%)';
      case 'ph': return 'pH';
      case 'temperature_c': return 'Temperatura (°C)';
      case 'alkalinity': return 'Alcalinidad';
      case 'ammonia_mg_l': return 'Amonio (mg/L)';
      case 'nitrite_mg_l': return 'Nitrito (mg/L)';
      case 'nitrate_mg_l': return 'Nitrato (mg/L)';
      case 'mortalidad': return 'Mortalidad (Uds)';
      case 'biomasa': return 'Biomasa (kg)';
      case 'consumo': return 'Alimento (kg)';
      default: return 'Parámetro';
    }
  };

  const getParamUnit = () => {
    switch(selectedParam) {
      case 'o2_mg_l': case 'oxigeno': return 'mg/L';
      case 'o2_perc': return '%';
      case 'ph': return '';
      case 'temperature_c': return '°C';
      case 'alkalinity': return 'mg/L';
      case 'ammonia_mg_l': return 'mg/L';
      case 'nitrite_mg_l': return 'mg/L';
      case 'nitrate_mg_l': return 'mg/L';
      case 'mortalidad': return 'Uds';
      case 'biomasa': return 'kg';
      case 'consumo': return 'kg';
      default: return '';
    }
  };

  const getParamColor = () => {
    switch(selectedParam) {
      case 'o2_mg_l': case 'oxigeno': return '#3b82f6';
      case 'ph': return '#8b5cf6';
      case 'temperature_c': return '#ef4444';
      case 'ammonia_mg_l': return '#f59e0b';
      case 'mortalidad': return '#ef4444';
      case 'biomasa': return '#10b981';
      case 'consumo': return '#ec4899';
      default: return '#6366f1';
    }
  };

  const currentThresholds = useMemo(() => {
    if (!thresholds) return null;
    if (selectedParam === 'o2_mg_l' || selectedParam === 'oxigeno') 
      return { min: thresholds.oxygenMin, max: thresholds.oxygenMax };
    if (selectedParam === 'temperature_c') 
      return { min: thresholds.tempMin, max: thresholds.tempMax };
    if (selectedParam === 'ph') 
      return { min: thresholds.phMin, max: thresholds.phMax };
    return null;
  }, [selectedParam, thresholds]);

    const displayData = useMemo(() => {
    if (data.length > 0) return data;
    if (currentThresholds) {
      // Return a ghost point to force axis rendering
      return [{ name: 'S/D', value: null }];
    }
    return [];
  }, [data, currentThresholds]);

  const showSpeciesFilter = isPolyculture && (selectedParam === 'mortalidad' || selectedParam === 'biomasa');

  return (
    <PremiumCard style={{ padding: 'clamp(1rem, 3vw, 2.5rem)' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '2.5rem', flexWrap: 'wrap', gap: '1.5rem' }}>
        <div>
          <h3 style={{ fontSize: '1.35rem', fontWeight: 950, letterSpacing: '-0.03em', color: 'var(--foreground)' }}>
            Tendencias de {getParamLabel()}
          </h3>
          <p style={{ fontSize: '0.85rem', color: 'var(--muted-foreground)', fontWeight: 600, marginTop: '0.2rem' }}>
            Visualización avanzada de registros históricos
          </p>
        </div>
        <div style={{ display: 'flex', gap: '0.75rem', flexWrap: 'wrap', width: '100%', justifyContent: 'flex-start', maxWidth: '600px' }}>
          {showSpeciesFilter && setSelectedSpecies && (
            <select 
              value={selectedSpecies}
              onChange={(e) => setSelectedSpecies(e.target.value)}
              className="premium-input" 
              style={{ flex: 1, minWidth: '140px', padding: '0.5rem 1rem', fontSize: '0.8rem', fontWeight: 800, borderRadius: '12px', borderColor: 'var(--primary)', color: 'var(--primary)', background: 'rgba(13, 148, 136, 0.05)' }}
            >
              <option value="Todas">Todas las especies</option>
              {pondSpecies.map(s => (
                <option key={s.species_name} value={s.species_name}>{s.species_name}</option>
              ))}
            </select>
          )}

          <select 
            value={selectedPond}
            onChange={(e) => onPondChange(e.target.value)}
            className="premium-input" 
            style={{ flex: 1, minWidth: '140px', padding: '0.5rem 1rem', fontSize: '0.8rem', fontWeight: 800, borderRadius: '12px' }}
          >
            <option value="">Estanque...</option>
            {ponds.map(p => (
              <option key={p.id} value={p.id}>{p.name}</option>
            ))}
          </select>
          
          <select 
            value={selectedParam}
            onChange={(e) => onParamChange(e.target.value)}
            className="premium-input" 
            style={{ 
              flex: '1.5',
              minWidth: '180px',
              padding: '0.5rem 1rem', 
              fontSize: '0.8rem', 
              fontWeight: 800, 
              borderRadius: '12px',
              borderColor: getParamColor(), 
              color: getParamColor(),
              background: `${getParamColor()}08`
            }}
          >
            <optgroup label="Básicos">
              <option value="o2_mg_l">Oxígeno (mg/L)</option>
              <option value="temperature_c">Temperatura (°C)</option>
              <option value="ph">pH</option>
            </optgroup>
            <optgroup label="Química Avanzada">
              <option value="o2_perc">Saturación O2 (%)</option>
              <option value="alkalinity">Alcalinidad</option>
              <option value="ammonia_mg_l">Amonio (mg/L)</option>
              <option value="nitrite_mg_l">Nitrito (mg/L)</option>
              <option value="nitrate_mg_l">Nitrato (mg/L)</option>
            </optgroup>
            <optgroup label="Producción">
              <option value="mortalidad">Mortalidad</option>
              <option value="biomasa">Biomasa</option>
              <option value="consumo">Alimento</option>
            </optgroup>
          </select>
        </div>
      </div>

      <div style={{ height: '380px', width: '100%', position: 'relative' }}>
        <AnimatePresence mode="wait">
          {isLoading && (
            <motion.div 
              key="loader"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              style={{ position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center', background: 'rgba(255,255,255,0.7)', zIndex: 10, borderRadius: '20px', backdropFilter: 'blur(4px)' }}
            >
              <Loader2 className="animate-spin" size={40} color={getParamColor()} />
            </motion.div>
          )}
        </AnimatePresence>
        
        <ResponsiveContainer width="100%" height="100%">
          <AreaChart data={displayData} margin={{ top: 30, right: 10, left: 0, bottom: 0 }}>
            <defs>
              <linearGradient id="colorGradient" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor={getParamColor()} stopOpacity={0.3}/>
                <stop offset="95%" stopColor={getParamColor()} stopOpacity={0}/>
              </linearGradient>
            </defs>
            <CartesianGrid 
              strokeDasharray="3 3" 
              vertical={false} 
              stroke="#e2e8f0" 
              opacity={0.6} 
            />
            {currentThresholds && (
              <>
                <ReferenceLine 
                  y={currentThresholds.min} 
                  stroke="#ef4444" 
                  strokeDasharray="6 6" 
                  strokeWidth={2} 
                  label={{ position: 'insideBottomLeft', value: `Mín: ${currentThresholds.min}`, fill: '#ef4444', fontSize: 10, fontWeight: 900 }} 
                />
                <ReferenceLine 
                  y={currentThresholds.max} 
                  stroke="#ef4444" 
                  strokeDasharray="6 6" 
                  strokeWidth={2} 
                  label={{ position: 'insideTopLeft', value: `Máx: ${currentThresholds.max}`, fill: '#ef4444', fontSize: 10, fontWeight: 900 }} 
                />
              </>
            )}
            <XAxis 
              dataKey="name" 
              axisLine={false} 
              tickLine={false} 
              tick={{ fontSize: 11, fill: '#94a3b8', fontWeight: 700 }} 
              dy={15}
            />
            <YAxis 
              axisLine={false} 
              tickLine={false} 
              tick={{ fontSize: 11, fill: '#94a3b8', fontWeight: 700 }} 
              dx={-10}
              domain={[
                (dataMin: number) => {
                  const min = currentThresholds ? currentThresholds.min : dataMin;
                  if (isNaN(dataMin) || dataMin === Infinity) return min - 1;
                  return Math.min(dataMin, min - 0.5);
                },
                (dataMax: number) => {
                  const max = currentThresholds ? currentThresholds.max : dataMax;
                  if (isNaN(dataMax) || dataMax === -Infinity) return max + 1;
                  return Math.max(dataMax, max + 0.5);
                }
              ]}
            />
            <Tooltip 
              content={<CustomTooltip unit={getParamUnit()} />}
              cursor={{ stroke: getParamColor(), strokeWidth: 1, strokeDasharray: '5 5' }}
            />
            <Area 
              type="monotone" 
              dataKey="value" 
              stroke={getParamColor()} 
              strokeWidth={4} 
              fillOpacity={1} 
              fill="url(#colorGradient)" 
              animationDuration={1500}
              activeDot={{ r: 8, strokeWidth: 0, fill: getParamColor() }}
              dot={{ r: 4, strokeWidth: 2, fill: 'white', stroke: getParamColor() }}
            >
              <LabelList 
                dataKey="value" 
                position="top" 
                offset={15} 
                style={{ 
                  fill: '#64748b', 
                  fontSize: '12px', 
                  fontWeight: '900',
                  opacity: 0.9
                }} 
              />
            </Area>
          </AreaChart>
        </ResponsiveContainer>
        
        {data.length === 0 && !isLoading && (
          <div style={{ position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center', flexDirection: 'column', gap: '0.5rem', pointerEvents: 'none', zIndex: 5 }}>
            <p style={{ color: 'rgba(148, 163, 184, 0.5)', fontWeight: 900, fontSize: '0.8rem', textTransform: 'uppercase', letterSpacing: '0.1em' }}>
              Sin registros en este periodo
            </p>
          </div>
        )}
      </div>
    </PremiumCard>
  );
}
