'use client';

import { useEffect, useState, useMemo } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import Link from 'next/link';
import { toast } from 'react-hot-toast';
import {
  Plus,
  X,
  Calculator,
  Waves,
  Box,
  Fish,
  FlaskConical,
  Settings,
  Wind,
  Calendar,
  Hash,
  Dna,
  Pencil,
  Trash2,
  BadgeDollarSign,
  Info,
  ArrowRightLeft,
  History
} from 'lucide-react';
import { supabase } from '@/lib/supabase';

// Helper Components
const PondIcon = ({ size = 24, color = 'currentColor' }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <path d="M2 12C2 7 6 3 12 3C18 3 22 7 22 12C22 17 18 21 12 21C6 21 2 17 2 12Z" fill="rgba(37, 99, 235, 0.1)" stroke="none" />
    <path d="M12 3C18 3 22 7 22 12C22 17 18 21 12 21C6 21 2 17 2 12C2 7 6 3 12 3Z" />
    <path d="M16 12C16 13.5 14.5 15 12 15C10.5 15 9 14.5 8 13.5L6 15V9L8 10.5C9 9.5 10.5 9 12 9C14.5 9 16 10.5 16 12Z" fill={color} stroke="none" />
    <circle cx="18" cy="18" r="1.5" fill="var(--muted-foreground)" stroke="none" />
    <circle cx="6" cy="6" r="1" fill="#10b981" stroke="none" />
  </svg>
);

const EditTooltip = ({ label, onClick }: { label: string, onClick?: () => void }) => {
  const [isHovered, setIsHovered] = useState(false);
  return (
    <>
      <AnimatePresence>
        {isHovered && (
          <motion.div
            initial={{ opacity: 0, y: -10, scale: 0.9 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: -5, scale: 0.9 }}
            style={{
              position: 'absolute',
              bottom: '100%',
              marginBottom: '8px',
              padding: '6px 10px',
              background: 'rgba(0, 0, 0, 0.85)',
              color: 'white',
              fontSize: '0.7rem',
              fontWeight: 700,
              borderRadius: '6px',
              whiteSpace: 'nowrap',
              pointerEvents: 'none',
              zIndex: 50,
              boxShadow: '0 10px 15px -3px rgba(0, 0, 0, 0.1)'
            }}
          >
            {label}
            <div style={{
              position: 'absolute',
              top: '100%',
              left: '50%',
              transform: 'translateX(-50%)',
              borderLeft: '5px solid transparent',
              borderRight: '5px solid transparent',
              borderTop: '5px solid rgba(0, 0, 0, 0.85)'
            }} />
          </motion.div>
        )}
      </AnimatePresence>
      <button
        onMouseEnter={() => setIsHovered(true)}
        onMouseLeave={() => setIsHovered(false)}
        onClick={onClick}
        className="glass"
        style={{ padding: '0.4rem', borderRadius: '6px', border: '1px solid var(--border)', cursor: 'pointer', color: 'var(--muted-foreground)' }}
      >
        <Pencil size={14} />
      </button>
    </>
  );
};

const DeleteTooltip = ({ label, onClick }: { label: string, onClick?: () => void }) => {
  const [isHovered, setIsHovered] = useState(false);
  return (
    <>
      <AnimatePresence>
        {isHovered && (
          <motion.div
            initial={{ opacity: 0, y: -10, scale: 0.9 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: -5, scale: 0.9 }}
            style={{
              position: 'absolute',
              bottom: '100%',
              marginBottom: '8px',
              padding: '6px 10px',
              background: '#ef4444',
              color: 'white',
              fontSize: '0.7rem',
              fontWeight: 700,
              borderRadius: '6px',
              whiteSpace: 'nowrap',
              pointerEvents: 'none',
              zIndex: 50,
              boxShadow: '0 10px 15px -3px rgba(239, 68, 68, 0.2)'
            }}
          >
            {label}
            <div style={{
              position: 'absolute',
              top: '100%',
              left: '50%',
              transform: 'translateX(-50%)',
              borderLeft: '5px solid transparent',
              borderRight: '5px solid transparent',
              borderTop: '5px solid #ef4444'
            }} />
          </motion.div>
        )}
      </AnimatePresence>
      <button
        onMouseEnter={() => setIsHovered(true)}
        onMouseLeave={() => setIsHovered(false)}
        onClick={(e) => {
          e.preventDefault();
          e.stopPropagation();
          onClick?.();
        }}
        className="glass"
        style={{ padding: '0.4rem', borderRadius: '6px', border: '1px solid rgba(239, 68, 68, 0.2)', cursor: 'pointer', color: '#ef4444' }}
      >
        <Trash2 size={14} />
      </button>
    </>
  );
};

const DetailTooltip = ({ label, onClick }: { label: string, onClick?: () => void }) => {
  const [isHovered, setIsHovered] = useState(false);
  return (
    <>
      <AnimatePresence>
        {isHovered && (
          <motion.div
            initial={{ opacity: 0, y: -10, scale: 0.9 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: -5, scale: 0.9 }}
            style={{
              position: 'absolute',
              bottom: '100%',
              marginBottom: '8px',
              padding: '6px 10px',
              background: 'rgba(37, 99, 235, 0.85)',
              color: 'white',
              fontSize: '0.7rem',
              fontWeight: 700,
              borderRadius: '6px',
              whiteSpace: 'nowrap',
              pointerEvents: 'none',
              zIndex: 50,
              boxShadow: '0 10px 15px -3px rgba(37, 99, 235, 0.1)'
            }}
          >
            {label}
            <div style={{
              position: 'absolute',
              top: '100%',
              left: '50%',
              transform: 'translateX(-50%)',
              borderLeft: '5px solid transparent',
              borderRight: '5px solid transparent',
              borderTop: '5px solid rgba(37, 99, 235, 0.85)'
            }} />
          </motion.div>
        )}
      </AnimatePresence>
      <button
        onMouseEnter={() => setIsHovered(true)}
        onMouseLeave={() => setIsHovered(false)}
        onClick={(e) => {
          e.preventDefault();
          e.stopPropagation();
          onClick?.();
        }}
        className="glass"
        style={{ padding: '0.4rem', borderRadius: '6px', border: '1px solid rgba(37, 99, 235, 0.2)', cursor: 'pointer', color: 'var(--primary)' }}
      >
        <Info size={14} />
      </button>
    </>
  );
};

const ActionButton = ({ icon: Icon, label, color }: { icon: any, label: string, color?: string }) => {
  const [isHovered, setIsHovered] = useState(false);

  return (
    <div style={{ position: 'relative', display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
      <AnimatePresence>
        {isHovered && (
          <motion.div
            initial={{ opacity: 0, y: 10, scale: 0.9 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: 5, scale: 0.9 }}
            style={{
              position: 'absolute',
              bottom: '100%',
              marginBottom: '8px',
              padding: '6px 10px',
              background: 'rgba(0, 0, 0, 0.85)',
              color: 'white',
              fontSize: '0.7rem',
              fontWeight: 700,
              borderRadius: '6px',
              whiteSpace: 'nowrap',
              pointerEvents: 'none',
              zIndex: 50,
              boxShadow: '0 10px 15px -3px rgba(0, 0, 0, 0.1)'
            }}
          >
            {label}
            <div style={{
              position: 'absolute',
              top: '100%',
              left: '50%',
              transform: 'translateX(-50%)',
              borderLeft: '5px solid transparent',
              borderRight: '5px solid transparent',
              borderTop: '5px solid rgba(0, 0, 0, 0.85)'
            }} />
          </motion.div>
        )}
      </AnimatePresence>
      <button
        onMouseEnter={() => setIsHovered(true)}
        onMouseLeave={() => setIsHovered(false)}
        className="glass"
        style={{
          padding: '0.625rem',
          borderRadius: '10px',
          border: '1px solid var(--border)',
          cursor: 'pointer',
          color: color || 'var(--muted-foreground)',
          transition: 'all 0.2s ease',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          background: 'var(--card)'
        }}
      >
        <Icon size={18} />
      </button>
    </div>
  );
};

const AnimatedWaves = () => (
  <div style={{ position: 'fixed', bottom: 0, left: 0, width: '100%', height: '100px', overflow: 'hidden', zIndex: -1, opacity: 0.4, pointerEvents: 'none' }}>
    <svg viewBox="0 0 1440 120" preserveAspectRatio="none" style={{ width: '200%', height: '100%', display: 'block' }}>
      <motion.path animate={{ x: [0, -1440] }} transition={{ duration: 15, repeat: Infinity, ease: "linear" }} fill="url(#wave-gradient)" d="M0,64L48,64C96,64,192,64,288,69.3C384,75,480,85,576,85.3C672,85,768,75,864,64C960,53,1056,43,1152,42.7C1248,43,1344,53,1392,58.7L1440,64L1440,120L1392,120C1344,120,1248,120,1152,120C1056,120,960,120,864,120C768,120,672,120,576,120C480,120,384,120,288,120C192,120,96,120,48,120L0,120Z" />
      <defs>
        <linearGradient id="wave-gradient" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="rgba(37, 99, 235, 0.15)" />
          <stop offset="100%" stopColor="rgba(37, 99, 235, 0)" />
        </linearGradient>
      </defs>
      <motion.path animate={{ x: [0, -1440] }} transition={{ duration: 20, repeat: Infinity, ease: "linear" }} fill="rgba(37, 99, 235, 0.1)" d="M0,64L48,64C96,64,192,64,288,69.3C384,75,480,85,576,85.3C672,85,768,75,864,64C960,53,1056,43,1152,42.7C1248,43,1344,53,1392,58.7L1440,64L1440,120L1392,120C1344,120,1248,120,1152,120C1056,120,960,120,864,120C768,120,672,120,576,120C480,120,384,120,288,120C192,120,96,120,48,120L0,120Z" />
    </svg>
  </div>
);

const PondCard = ({ pond, handleDeleteSiembra, handleEditClick }: any) => {
  const [isFlipped, setIsFlipped] = useState(false);
  const [kpis, setKpis] = useState<{ diasLote: string; consumo: string; fca: string; mortalidad: string; costoTotal: string } | null>(null);
  const [loadingKpis, setLoadingKpis] = useState(false);

  // Reset cached KPIs whenever core pond data changes so stale values are never shown
  useEffect(() => {
    setKpis(null);
    setIsFlipped(false);
  }, [pond.current_count, pond.current_biomass_kg, pond.status]);

  const density = pond.status === 'con_peces' && pond.volume > 0
    ? (pond.current_count / pond.volume).toFixed(2)
    : null;

  const stopProp = (e: React.MouseEvent) => e.stopPropagation();

  const handleFlip = async () => {
    const next = !isFlipped;
    setIsFlipped(next);
    // Always reload KPIs when flipping to back — never serve stale cache
    if (next && pond.status === 'con_peces') {
      setLoadingKpis(true);
      try {
        const { data: siembra } = await supabase
          .from('siembras')
          .select('id, date')
          .eq('estanque_id', pond.id)
          .order('date', { ascending: false })
          .limit(1)
          .single();

        let diasLote = '0 días';
        let consumoTotal = 0;
        let mortalidadTotal = 0;

        if (siembra?.date) {
          const diff = Math.floor((Date.now() - new Date(siembra.date).getTime()) / 86400000);
          diasLote = `${diff} días`;
          const [alimentRes, mortRes, transferRes] = await Promise.all([
            supabase.from('alimentacion_diaria').select('quantity_kg').eq('estanque_id', pond.id),
            supabase.from('mortality').select('quantity').eq('estanque_id', pond.id),
            // Lee ambas columnas: consumo_kg_arrastrado (traslados nuevos) y food_total_kg (traslados viejos)
            supabase.from('transfers').select('food_total_kg, consumo_kg_arrastrado').eq('destino_id', pond.id)
          ]);
          const directFood = (alimentRes.data || []).reduce((s: number, r: any) => s + parseFloat(r.quantity_kg || 0), 0);
          // Preferir consumo_kg_arrastrado; si no existe, usar food_total_kg (compatibilidad hacia atrás)
          const inheritedFood = (transferRes.data || []).reduce((s: number, r: any) => {
            const nuevo = parseFloat(r.consumo_kg_arrastrado || 0);
            const viejo = parseFloat(r.food_total_kg || 0);
            return s + (nuevo > 0 ? nuevo : viejo);
          }, 0);
          consumoTotal = directFood + inheritedFood;
          mortalidadTotal = (mortRes.data || []).reduce((s: number, r: any) => s + parseInt(r.quantity || 0), 0);
        }

        const biomasa = pond.current_biomass_kg || 1;
        const fca = consumoTotal > 0 ? (consumoTotal / biomasa).toFixed(2) : '0.00';
        const totalPeces = pond.current_count + mortalidadTotal;
        const mortPct = totalPeces > 0 ? ((mortalidadTotal / totalPeces) * 100).toFixed(2) : '0.00';

        // Costo total acumulado del estanque
        const { data: costoData } = await supabase
          .from('estanques')
          .select('costo_alevinos_acumulado, consumo_alimento_acumulado_kg, costo_alimento_acumulado')
          .eq('id', pond.id)
          .single();

        const costoAlevinos = parseFloat(costoData?.costo_alevinos_acumulado) || 0;
        const costoAlimento = parseFloat(costoData?.costo_alimento_acumulado) || 0;
        const costoTotal = costoAlevinos + costoAlimento;
        const costoTotalFormateado = costoTotal > 0
          ? '$' + costoTotal.toLocaleString('es-CO', { maximumFractionDigits: 0 })
          : '$0';

        setKpis({
          diasLote,
          consumo: consumoTotal.toLocaleString('es-CO', { maximumFractionDigits: 2 }) + ' kg',
          fca,
          mortalidad: mortPct + '%',
          costoTotal: costoTotalFormateado
        });
      } catch {
        setKpis({ diasLote: 'Error', consumo: 'Error', fca: 'Error', mortalidad: 'Error', costoTotal: 'Error' });
      } finally {
        setLoadingKpis(false);
      }
    }
  };

  const kpiItems = [
    { label: 'DÍAS DE LOTE', value: kpis?.diasLote ?? '—', color: '#3b82f6' },
    { label: 'CONSUMO TOTAL', value: kpis?.consumo ?? '—', color: '#8b5cf6' },
    { label: 'FCA', value: kpis?.fca ?? '—', color: '#f59e0b' },
    { label: 'MORTALIDAD', value: kpis?.mortalidad ?? '—', color: '#ef4444' },
    { label: 'COSTO TOTAL', value: kpis?.costoTotal ?? '—', color: '#8b5cf6' },
  ];

  return (
    <motion.div whileHover={{ y: -4 }} style={{ perspective: '1000px', cursor: 'pointer', height: '100%', display: 'flex', flexDirection: 'column' }} onClick={handleFlip}>
      <motion.div
        animate={{ rotateY: isFlipped ? 180 : 0 }}
        transition={{ duration: 0.6, type: 'spring', stiffness: 260, damping: 20 }}
        style={{ position: 'relative', transformStyle: 'preserve-3d', flex: 1, display: 'grid' }}
      >
        {/* FRENTE */}
        <div style={{ gridArea: '1 / 1', backfaceVisibility: 'hidden', WebkitBackfaceVisibility: 'hidden', display: 'flex', flexDirection: 'column', height: '100%', opacity: isFlipped ? 0 : 1, pointerEvents: isFlipped ? 'none' : 'auto', transition: 'opacity 0.3s ease' }}>
          <div className="card-premium" style={{ padding: '1.5rem', display: 'flex', flexDirection: 'column', gap: '1rem', border: `2px solid ${pond.color}`, borderRadius: '16px', height: '100%', backfaceVisibility: 'hidden', WebkitBackfaceVisibility: 'hidden' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <h3 style={{ fontSize: '1.25rem', fontWeight: 800 }}>{pond.name}</h3>
              <div style={{ display: 'flex', gap: '0.5rem' }}>
                <div onClick={stopProp}><DetailTooltip label="Ver Detalle" onClick={() => pond.onDetailClick?.(pond)} /></div>
                {pond.status === 'con_peces' && <div onClick={stopProp}><DeleteTooltip label="Borrar Siembra" onClick={() => handleDeleteSiembra(pond)} /></div>}
                <div onClick={stopProp}><EditTooltip label="Editar" onClick={() => handleEditClick(pond)} /></div>
              </div>
            </div>
            <div style={{ display: 'flex', gap: '0.5rem', flexWrap: 'wrap', alignItems: 'center' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', fontSize: '0.7rem', fontWeight: 900, color: pond.color, background: `${pond.color}18`, padding: '4px 10px', borderRadius: '20px', alignSelf: 'flex-start' }}>
                <span style={{ width: '6px', height: '6px', borderRadius: '50%', background: pond.color }}></span>
                {pond.statusLabel.toUpperCase()}
              </div>
              {pond.status === 'con_peces' && pond.current_batch_id && (
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', fontSize: '0.65rem', fontWeight: 900, color: 'var(--primary)', background: 'var(--secondary)', padding: '4px 10px', borderRadius: '20px', border: '1px solid var(--border)' }}>
                  <Hash size={10} strokeWidth={3} />
                  <span style={{ opacity: 0.8 }}>LOTE:</span> {pond.current_batch_id.toString().slice(0, 8).toUpperCase()}
                </div>
              )}
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem', margin: '0.5rem 0' }}>
              <div>
                <div style={{ fontSize: '0.65rem', fontWeight: 800, color: 'var(--muted-foreground)' }}>VOLUMEN</div>
                <div style={{ fontWeight: 800, fontSize: '1.1rem' }}>{pond.volume} <span style={{ fontSize: '0.7rem' }}>m³</span></div>
              </div>
              <div>
                <div style={{ fontSize: '0.65rem', fontWeight: 800, color: 'var(--muted-foreground)' }}>BIOMASA</div>
                <div style={{ fontWeight: 800, fontSize: '1.1rem' }}>{pond.current_biomass_kg} <span style={{ fontSize: '0.7rem' }}>kg</span></div>
              </div>
            </div>
            {pond.status === 'con_peces' ? (
              <div style={{ background: 'var(--secondary)', borderRadius: '12px', padding: '1rem' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.5rem' }}>
                  <span style={{ fontSize: '0.65rem', fontWeight: 800, color: 'var(--muted-foreground)' }}>ESPECIE / CANTIDAD</span>
                  {pond.speciesRows?.length > 1 && (
                    <span style={{ fontSize: '0.6rem', background: 'var(--primary)', color: 'white', padding: '2px 6px', borderRadius: '4px' }}>POLICULTIVO</span>
                  )}
                </div>

                {/* Per-species tags — one per row in pond_species */}
                {pond.speciesRows?.length > 0 ? (
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '0.35rem', marginBottom: '0.5rem' }}>
                    {pond.speciesRows.map((s: any, i: number) => (
                      <div key={i} style={{ display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
                        <span style={{
                          display: 'inline-block',
                          width: '7px', height: '7px', borderRadius: '50%',
                          background: i === 0 ? '#10b981' : i === 1 ? '#3b82f6' : '#f59e0b',
                          flexShrink: 0
                        }} />
                        <span style={{ fontWeight: 700, fontSize: '0.85rem' }}>{s.species_name}</span>
                        <span style={{ fontSize: '0.7rem', color: 'var(--muted-foreground)', marginLeft: 'auto' }}>
                          {(s.current_count || 0).toLocaleString()} uds
                        </span>
                      </div>
                    ))}
                  </div>
                ) : (
                  <div style={{ fontWeight: 700, fontSize: '0.9rem', marginBottom: '0.5rem' }}>{pond.especie}</div>
                )}

                <div style={{ fontSize: '1.25rem', fontWeight: 900, color: 'var(--primary)', marginTop: '0.25rem' }}>
                  {pond.current_count.toLocaleString()} <span style={{ fontSize: '0.8rem', color: 'var(--muted-foreground)' }}>uds total</span>
                </div>
                {density !== null && (
                <div style={{ marginTop: '0.75rem', paddingTop: '0.75rem', borderTop: '1px solid var(--border)', display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
                  <span style={{ fontSize: '0.65rem', fontWeight: 800, color: 'var(--muted-foreground)' }}>DENSIDAD:</span>
                  <span style={{ fontSize: '0.85rem', fontWeight: 900, color: '#8b5cf6' }}>{density} <span style={{ fontSize: '0.65rem', color: 'var(--muted-foreground)' }}>uds/m³</span></span>
                </div>
              )}
              </div>
            ) : null}
            <div style={{ display: 'flex', gap: '0.5rem', borderTop: '1px solid var(--border)', paddingTop: '1rem', marginTop: 'auto', flexWrap: 'wrap' }}>
              <div onClick={stopProp}><Link href={`/siembra?estanque=${pond.id}`}><ActionButton icon={Fish} label="Siembra" color="#10b981" /></Link></div>
              <div onClick={stopProp}><Link href={`/tratamiento?estanque=${pond.id}`}><ActionButton icon={FlaskConical} label="Tratamiento" color="#f59e0b" /></Link></div>
              <div onClick={stopProp}><Link href={`/mantenimiento?estanque=${pond.id}`}><ActionButton icon={Settings} label="Mantenimiento" color="#3b82f6" /></Link></div>
              <div onClick={stopProp}><Link href={`/aireacion?estanque=${pond.id}`}><ActionButton icon={Wind} label="Aireación" color="#06b6d4" /></Link></div>
            </div>
          </div>
        </div>

        {/* REVERSO */}
        <div style={{ gridArea: '1 / 1', backfaceVisibility: 'hidden', WebkitBackfaceVisibility: 'hidden', transform: 'rotateY(180deg)', display: 'flex', flexDirection: 'column', height: '100%', opacity: !isFlipped ? 0 : 1, pointerEvents: !isFlipped ? 'none' : 'auto', transition: 'opacity 0.3s ease' }}>
          <div className="card-premium" style={{ padding: '1.5rem', display: 'flex', flexDirection: 'column', gap: '1rem', border: `2px solid ${pond.color}`, borderRadius: '16px', height: '100%', backfaceVisibility: 'hidden', WebkitBackfaceVisibility: 'hidden' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <h3 style={{ fontSize: '1.1rem', fontWeight: 900, color: 'var(--primary)' }}>{pond.name} · KPIs</h3>
              <div style={{ display: 'flex', gap: '0.4rem', alignItems: 'center' }}>
                {pond.current_batch_id && (
                  <div style={{ fontSize: '0.65rem', fontWeight: 900, color: 'var(--muted-foreground)', background: 'var(--secondary)', padding: '4px 10px', borderRadius: '20px', border: '1px solid var(--border)' }}>
                    #{pond.current_batch_id.toString().slice(0, 6).toUpperCase()}
                  </div>
                )}
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', fontSize: '0.7rem', fontWeight: 900, color: pond.color, background: `${pond.color}18`, padding: '4px 10px', borderRadius: '20px' }}>
                  <span style={{ width: '6px', height: '6px', borderRadius: '50%', background: pond.color }}></span>
                  {pond.statusLabel.toUpperCase()}
                </div>
              </div>
            </div>

            {loadingKpis ? (
              <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <div style={{ width: '32px', height: '32px', border: `3px solid ${pond.color}`, borderTopColor: 'transparent', borderRadius: '50%', animation: 'spin 0.8s linear infinite' }} />
              </div>
            ) : pond.status !== 'con_peces' ? (
              <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--muted-foreground)', fontWeight: 700, fontSize: '0.85rem', textAlign: 'center' }}>
                Sin producción activa.<br />Realiza una siembra para ver KPIs.
              </div>
            ) : (
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(120px, 1fr))', gap: '0.75rem', flex: 1 }}>
                {kpiItems.map((item) => (
                  <div key={item.label} className="glass" style={{ padding: '1rem', borderRadius: '12px', border: `1px solid ${item.color}22`, background: `${item.color}08` }}>
                    <div style={{ fontSize: '0.6rem', fontWeight: 900, color: 'var(--muted-foreground)', textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: '0.4rem' }}>{item.label}</div>
                    <div style={{ fontSize: '1.1rem', fontWeight: 900, color: item.color, lineHeight: 1.1 }}>{item.value}</div>
                  </div>
                ))}
              </div>
            )}

            <div style={{ display: 'flex', justifyContent: 'flex-end', borderTop: '1px solid var(--border)', paddingTop: '1rem', gap: '0.5rem' }}>
              {pond.status === 'con_peces' ? (
                <>
                  <div onClick={stopProp}>
                    <Link href={`/finanzas?tab=ventas&estanque=${pond.id}`}><ActionButton icon={BadgeDollarSign} label="Vender" color="#10b981" /></Link>
                  </div>
                  <div onClick={(e) => { stopProp(e); pond.onLiquidarClick?.(pond); }}>
                    <ActionButton icon={Box} label="Liquidar Lote" color="#8b5cf6" />
                  </div>
                </>
              ) : (
                <div onClick={() => toast.error(`"${pond.name}" no tiene peces activos.`, { duration: 3500 })}>
                  <ActionButton icon={BadgeDollarSign} label="Liquidar" color="#94a3b8" />
                </div>
              )}
            </div>
          </div>
        </div>
      </motion.div>
    </motion.div>
  );
};

const LiquidationModal = ({ pond, onClose, fetchEstanques }: { pond: any, onClose: () => void, fetchEstanques: () => void }) => {
  const [kpis, setKpis] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [closing, setClosing] = useState(false);

  useEffect(() => {
    fetchKPIs();
  }, [pond.id]);

  const fetchKPIs = async () => {
    setLoading(true);
    try {
      const { data: alimentRes } = await supabase.from('alimentacion_diaria').select('quantity_kg, total_cost').eq('estanque_id', pond.id);
      const feedKg = (alimentRes || []).reduce((s: number, r: any) => s + parseFloat(r.quantity_kg || 0), 0);
      
      const { data: mortRes } = await supabase.from('mortality').select('quantity').eq('estanque_id', pond.id);
      const mort = (mortRes || []).reduce((s: number, r: any) => s + parseInt(r.quantity || 0), 0);

      const { data: salesRes } = await supabase.from('ventas').select('cantidad_kg, cantidad_peces, precio_kg').eq('estanque_id', pond.id);
      const salesKg = (salesRes || []).reduce((s: number, r: any) => s + parseFloat(r.cantidad_kg || 0), 0);
      const salesIncome = (salesRes || []).reduce((s: number, r: any) => s + (parseFloat(r.cantidad_kg || 0) * parseFloat(r.precio_kg || 0)), 0);
      const salesUnits = (salesRes || []).reduce((s: number, r: any) => s + parseInt(r.cantidad_peces || 0), 0);

      const fca = salesKg > 0 ? (feedKg / salesKg).toFixed(2) : '0.00';
      const totalCostos = parseFloat(pond.costo_alevinos_acumulado || 0) + parseFloat(pond.costo_alimento_acumulado || 0);
      const costPerKg = salesKg > 0 ? (totalCostos / salesKg).toFixed(0) : '0';
      
      const startingPopulation = salesUnits + mort + (pond.current_count || 0);
      const mortalityPct = startingPopulation > 0 ? ((mort / startingPopulation) * 100).toFixed(2) : '0.00';

      const profit = salesIncome - totalCostos;

      setKpis({ feedKg, salesKg, salesIncome, salesUnits, fca, costPerKg, mortalityPct, profit, totalCostos, mort });
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const handleCloseBatch = async () => {
    setClosing(true);
    try {
      const activeUnitId = localStorage.getItem('active_unit_id');
      const cierreData = {
        unit_id: activeUnitId,
        estanque_id: pond.id,
        batch_id: pond.current_batch_id,
        fecha_cierre: new Date().toISOString().split('T')[0],
        fca: parseFloat(kpis.fca),
        mortalidad_pct: parseFloat(kpis.mortalityPct),
        costo_por_kg: parseFloat(kpis.costPerKg),
        rentabilidad: kpis.profit,
        ingresos_totales: kpis.salesIncome,
        costos_totales: kpis.totalCostos,
        kilos_vendidos: kpis.salesKg
      };
      
      // Ignorar error si la tabla no existe aún
      await supabase.from('cierres_lote').insert([cierreData]);

      await supabase.from('pond_species').delete().eq('estanque_id', pond.id);

      const { error } = await supabase.from('estanques').update({
        status: 'vacio',
        is_polyculture: false,
        current_species: null,
        current_count: 0,
        current_biomass_kg: 0,
        costo_alevinos_acumulado: 0,
        consumo_alimento_acumulado_kg: 0,
        costo_alimento_acumulado: 0,
        current_batch_id: null
      }).eq('id', pond.id);

      if (error) throw error;

      toast.success('Lote cerrado y estanque reseteado con éxito.');
      fetchEstanques();
      onClose();
    } catch (err: any) {
      toast.error('Error al cerrar lote: ' + err.message);
    } finally {
      setClosing(false);
    }
  };

  return (
    <div style={{ position: 'fixed', top: 0, left: 0, width: '100vw', height: '100vh', zIndex: 10000, pointerEvents: 'none' }}>
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        onClick={onClose}
        style={{ position: 'absolute', inset: 0, background: 'rgba(15, 23, 42, 0.6)', backdropFilter: 'blur(10px)', pointerEvents: 'auto' }}
      />
      <motion.div
        initial={{ scale: 0.9, opacity: 0, x: '-50%', y: '-40%' }}
        animate={{ scale: 1, opacity: 1, x: '-50%', y: '-50%' }}
        exit={{ scale: 0.9, opacity: 0, x: '-50%', y: '-40%' }}
        className="card-premium"
        style={{ position: 'absolute', top: '50%', left: '50%', width: '95%', maxWidth: '500px', padding: '2rem', pointerEvents: 'auto', zIndex: 10001 }}
      >
        <button onClick={onClose} style={{ position: 'absolute', top: '1rem', right: '1rem', background: 'none', border: 'none', color: 'var(--muted-foreground)', cursor: 'pointer' }}><X size={24} /></button>
        <h2 style={{ fontWeight: 900, marginBottom: '1.5rem', color: '#8b5cf6', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
          <Box size={24} /> Liquidación de Lote
        </h2>
        
        {loading ? (
          <div style={{ textAlign: 'center', padding: '2rem' }}>Calculando KPIs del lote...</div>
        ) : kpis ? (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
            <p style={{ fontSize: '0.9rem', color: 'var(--muted-foreground)', marginBottom: '1rem' }}>
              Revisa los KPIs finales de <strong>{pond.name}</strong> antes de cerrar el lote. Esta acción guardará el histórico y reseteará el estanque a cero.
            </p>
            
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
              <div style={{ padding: '1rem', background: 'var(--secondary)', borderRadius: '12px' }}>
                <div style={{ fontSize: '0.7rem', color: 'var(--muted-foreground)', fontWeight: 700 }}>FCA FINAL</div>
                <div style={{ fontSize: '1.5rem', fontWeight: 900, color: '#f59e0b' }}>{kpis.fca}</div>
              </div>
              <div style={{ padding: '1rem', background: 'var(--secondary)', borderRadius: '12px' }}>
                <div style={{ fontSize: '0.7rem', color: 'var(--muted-foreground)', fontWeight: 700 }}>MORTALIDAD</div>
                <div style={{ fontSize: '1.5rem', fontWeight: 900, color: '#ef4444' }}>{kpis.mortalityPct}%</div>
              </div>
              <div style={{ padding: '1rem', background: 'var(--secondary)', borderRadius: '12px' }}>
                <div style={{ fontSize: '0.7rem', color: 'var(--muted-foreground)', fontWeight: 700 }}>COSTO POR KG</div>
                <div style={{ fontSize: '1.25rem', fontWeight: 900, color: '#8b5cf6' }}>${kpis.costPerKg}</div>
              </div>
              <div style={{ padding: '1rem', background: 'var(--secondary)', borderRadius: '12px' }}>
                <div style={{ fontSize: '0.7rem', color: 'var(--muted-foreground)', fontWeight: 700 }}>KILOS VENDIDOS</div>
                <div style={{ fontSize: '1.25rem', fontWeight: 900 }}>{kpis.salesKg.toLocaleString()} kg</div>
              </div>
            </div>

            <div style={{ padding: '1rem', background: 'rgba(16,185,129,0.1)', borderRadius: '12px', border: '1px solid rgba(16,185,129,0.2)', marginTop: '1rem' }}>
              <div style={{ fontSize: '0.8rem', color: '#10b981', fontWeight: 800 }}>RENTABILIDAD (UTILIDAD BRUTA)</div>
              <div style={{ fontSize: '2rem', fontWeight: 900, color: '#10b981' }}>
                ${kpis.profit.toLocaleString('es-CO', { maximumFractionDigits: 0 })}
              </div>
              <div style={{ fontSize: '0.75rem', color: 'var(--muted-foreground)', marginTop: '0.25rem' }}>
                Ingresos: ${kpis.salesIncome.toLocaleString()} - Costos: ${kpis.totalCostos.toLocaleString()}
              </div>
            </div>

            <button onClick={handleCloseBatch} disabled={closing} className="btn-primary" style={{ width: '100%', marginTop: '1rem', background: '#8b5cf6', borderColor: '#8b5cf6' }}>
              {closing ? 'Cerrando Lote...' : 'Finalizar y Cerrar Lote'}
            </button>
          </div>
        ) : null}
      </motion.div>
    </div>
  );
};

const PondDetailModal = ({ pond, onClose }: { pond: any, onClose: () => void }) => {
  const [history, setHistory] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchTraceability();
  }, [pond.id]);

  const fetchTraceability = async () => {
    setLoading(true);
    try {
      const { data: transfers } = await supabase
        .from('transfers')
        .select('*, origen:estanques!origen_id(name), destino:estanques!destino_id(name)')
        .or(`origen_id.eq.${pond.id},destino_id.eq.${pond.id}`)
        .order('date', { ascending: false })
        .limit(10);

      const formattedHistory = (transfers || []).map((t: any) => ({
        type: t.origen_id === pond.id ? 'Salida' : 'Entrada',
        date: t.date,
        quantity: t.quantity,
        species: t.species_name,
        otherPond: t.origen_id === pond.id ? t.destino?.name : t.origen?.name,
        revertido: t.revertido
      }));

      setHistory(formattedHistory);
    } catch (error) {
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{ position: 'fixed', top: 0, left: 0, width: '100vw', height: '100vh', zIndex: 10000, pointerEvents: 'none' }}>
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        onClick={onClose}
        style={{ position: 'absolute', inset: 0, background: 'rgba(15, 23, 42, 0.6)', backdropFilter: 'blur(10px)', pointerEvents: 'auto' }}
      />
      <motion.div
        initial={{ scale: 0.9, opacity: 0, x: '-50%', y: '-40%' }}
        animate={{ scale: 1, opacity: 1, x: '-50%', y: '-50%' }}
        exit={{ scale: 0.9, opacity: 0, x: '-50%', y: '-40%' }}
        className="card-premium"
        style={{
          position: 'absolute',
          top: '50%',
          left: '50%',
          width: '95%',
          maxWidth: '600px',
          maxHeight: '90vh',
          overflowY: 'auto',
          padding: '2rem',
          pointerEvents: 'auto',
          boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.5)',
          zIndex: 10001
        }}
      >
        <button onClick={onClose} style={{ position: 'absolute', top: '1rem', right: '1rem', background: 'none', border: 'none', color: 'var(--muted-foreground)', cursor: 'pointer' }}><X size={24} /></button>
        
        <div style={{ marginBottom: '2rem' }}>
          <h2 style={{ fontWeight: 950, fontSize: '1.75rem', letterSpacing: '-0.04em', display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
            <Waves size={32} style={{ color: 'var(--primary)' }} />
            {pond.name}
          </h2>
          <div style={{ display: 'flex', gap: '0.5rem', marginTop: '0.5rem' }}>
             {pond.current_batch_id && (
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', fontSize: '0.75rem', fontWeight: 900, color: 'var(--primary)', background: 'var(--secondary)', padding: '6px 12px', borderRadius: '20px', border: '1px solid var(--border)' }}>
                  <Hash size={12} strokeWidth={3} />
                  <span style={{ opacity: 0.8 }}>LOTE:</span> {pond.current_batch_id}
                </div>
              )}
          </div>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem', marginBottom: '2rem' }}>
          <div className="glass" style={{ padding: '1.25rem', borderRadius: '16px', border: '1px solid var(--border)' }}>
            <div style={{ fontSize: '0.7rem', fontWeight: 800, color: 'var(--muted-foreground)', textTransform: 'uppercase', marginBottom: '0.5rem' }}>Población Actual</div>
            <div style={{ fontSize: '1.5rem', fontWeight: 950 }}>{pond.current_count?.toLocaleString()} <span style={{ fontSize: '0.8rem', opacity: 0.6 }}>uds</span></div>
          </div>
          <div className="glass" style={{ padding: '1.25rem', borderRadius: '16px', border: '1px solid var(--border)' }}>
            <div style={{ fontSize: '0.7rem', fontWeight: 800, color: 'var(--muted-foreground)', textTransform: 'uppercase', marginBottom: '0.5rem' }}>Biomasa Estimada</div>
            <div style={{ fontSize: '1.5rem', fontWeight: 950 }}>{parseFloat(pond.current_biomass_kg || 0).toFixed(1)} <span style={{ fontSize: '0.8rem', opacity: 0.6 }}>kg</span></div>
          </div>
        </div>

        <div style={{ marginBottom: '2rem' }}>
          <h3 style={{ fontSize: '0.85rem', fontWeight: 900, color: 'var(--muted-foreground)', textTransform: 'uppercase', marginBottom: '1rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <Fish size={16} /> Desglose de Especies
          </h3>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
            {pond.speciesRows?.map((s: any, i: number) => (
              <div key={i} className="glass" style={{ padding: '1rem', borderRadius: '12px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                  <div style={{ width: '10px', height: '10px', borderRadius: '50%', background: 'var(--primary)' }} />
                  <span style={{ fontWeight: 800 }}>{s.species_name}</span>
                </div>
                <div style={{ textAlign: 'right' }}>
                  <div style={{ fontWeight: 900 }}>{s.current_count.toLocaleString()} uds</div>
                  <div style={{ fontSize: '0.75rem', opacity: 0.6 }}>{s.current_biomass_kg.toFixed(1)} kg</div>
                </div>
              </div>
            ))}
          </div>
        </div>

        <div>
          <h3 style={{ fontSize: '0.85rem', fontWeight: 900, color: 'var(--muted-foreground)', textTransform: 'uppercase', marginBottom: '1rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <History size={16} /> Trazabilidad de Movimientos
          </h3>
          {loading ? (
            <div style={{ padding: '2rem', textAlign: 'center' }}>Cargando historial...</div>
          ) : history.length === 0 ? (
            <div style={{ padding: '2rem', textAlign: 'center', opacity: 0.5 }}>No hay movimientos registrados para este lote.</div>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
              {history.map((h, i) => (
                <div key={i} style={{ 
                  padding: '1rem', 
                  borderRadius: '12px', 
                  background: h.revertido ? 'rgba(239, 68, 68, 0.05)' : 'var(--secondary)',
                  border: `1px solid ${h.revertido ? 'rgba(239, 68, 68, 0.1)' : 'var(--border)'}`,
                  opacity: h.revertido ? 0.6 : 1,
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'center'
                }}>
                  <div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                      {h.type === 'Salida' ? <ArrowRightLeft size={14} style={{ color: '#ef4444' }} /> : <ArrowRightLeft size={14} style={{ color: '#10b981' }} />}
                      <span style={{ fontWeight: 800, fontSize: '0.9rem' }}>{h.type} {h.type === 'Salida' ? 'a' : 'desde'} {h.otherPond}</span>
                    </div>
                    <div style={{ fontSize: '0.75rem', color: 'var(--muted-foreground)' }}>{new Date(h.date).toLocaleDateString()} · {h.species}</div>
                  </div>
                  <div style={{ textAlign: 'right' }}>
                    <div style={{ fontWeight: 900, color: h.type === 'Salida' ? '#ef4444' : '#10b981' }}>{h.type === 'Salida' ? '-' : '+'}{h.quantity.toLocaleString()}</div>
                    {h.revertido && <div style={{ fontSize: '0.65rem', color: '#ef4444', fontWeight: 900 }}>REVERTIDO</div>}
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </motion.div>
    </div>
  );
};

export default function EstanquesPage() {
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [selectedDetailPond, setSelectedDetailPond] = useState<any | null>(null);
  const [selectedLiquidationPond, setSelectedLiquidationPond] = useState<any>(null);
  const [ponds, setPonds] = useState<any[]>([]);
  const [editingPond, setEditingPond] = useState<any | null>(null);
  const [formData, setFormData] = useState({ numero: '', largo: '', ancho: '', profundidad: '' });
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    fetchEstanques();

    // Realtime: auto-refresh cards when estanques or pond_species change
    // (triggered by traslado, siembra, biometría, mortalidad, etc.)
    const activeUnitId = localStorage.getItem('active_unit_id');
    if (!activeUnitId) return;

    const channel = supabase
      .channel(`estanques-live-${activeUnitId}`)
      .on('postgres_changes', { event: '*', schema: 'public', table: 'estanques', filter: `unit_id=eq.${activeUnitId}` }, () => fetchEstanques())
      .on('postgres_changes', { event: '*', schema: 'public', table: 'pond_species' }, () => fetchEstanques())
      .subscribe();

    return () => { supabase.removeChannel(channel); };
  }, []);

  const fetchEstanques = async () => {
    const activeUnitId = localStorage.getItem('active_unit_id');
    if (!activeUnitId) return;

    try {
      // Fetch ponds AND their species in a single query via the relation
      const { data: pondsData, error: pErr } = await supabase
        .from('estanques')
        .select('*, pond_species(species_name, current_count, current_biomass_kg)')
        .eq('unit_id', activeUnitId)
        .order('name');

      if (pErr) throw pErr;

      const formatted = (pondsData || []).map((p: any) => {
        let color = '#64748b';
        let statusLabel = 'Vacío';
        if (p.status === 'con_peces') {
          color = '#10b981';
          statusLabel = 'En Producción';
        } else if (p.status === 'mantenimiento') {
          color = '#f59e0b';
          statusLabel = 'Mantenimiento';
        }

        // Build species label from real pond_species rows.
        // Deduplicate by species_name (same species stocked on different dates
        // creates multiple pond_species rows — we sum them into one).
        const rawSpeciesRows: any[] = (p.pond_species || []).filter((s: any) => (s.current_count || 0) > 0);

        // Override status visually: if no active fish, treat as vacío even if DB says con_peces
        const effectiveCount = p.current_count || 0;
        const effectiveStatus = (effectiveCount === 0 && rawSpeciesRows.length === 0) ? 'vacio' : p.status;
        if (effectiveStatus === 'vacio') {
          color = '#64748b';
          statusLabel = 'Vacío';
        }
        const speciesMap = new Map<string, { species_name: string; current_count: number; current_biomass_kg: number }>();
        for (const s of rawSpeciesRows) {
          if (speciesMap.has(s.species_name)) {
            const existing = speciesMap.get(s.species_name)!;
            existing.current_count += (s.current_count || 0);
            existing.current_biomass_kg += (parseFloat(s.current_biomass_kg) || 0);
          } else {
            speciesMap.set(s.species_name, {
              species_name: s.species_name,
              current_count: s.current_count || 0,
              current_biomass_kg: parseFloat(s.current_biomass_kg) || 0
            });
          }
        }
        const speciesRows = Array.from(speciesMap.values());
        let especieLabel: string;
        if (speciesRows.length > 1) {
          especieLabel = speciesRows.map((s: any) => s.species_name).join(' + ');
        } else if (speciesRows.length === 1) {
          especieLabel = speciesRows[0].species_name;
        } else {
          // Fallback to legacy column if pond_species is still empty
          especieLabel = p.current_species || 'N/A';
        }

        return {
          ...p,
          status: effectiveStatus,
          color,
          statusLabel,
          volume: p.capacity_m3 || 0,
          especie: especieLabel,
          speciesRows,          // pass through for rich rendering in card
          current_count: p.current_count || 0,
          current_biomass_kg: p.current_biomass_kg || 0,
          onDetailClick: (pnd: any) => setSelectedDetailPond(pnd)
        };
      });
      setPonds(formatted);
    } catch (error: any) {
      toast.error(`Error al cargar estanques: ${error.message}`);
    }
  };

  const volumen = useMemo(() => {
    const l = parseFloat(formData.largo) || 0;
    const a = parseFloat(formData.ancho) || 0;
    const p = parseFloat(formData.profundidad) || 0;
    return (l * a * p).toFixed(2);
  }, [formData.largo, formData.ancho, formData.profundidad]);

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
  };

  const resetForm = () => {
    setFormData({ numero: '', largo: '', ancho: '', profundidad: '' });
    setEditingPond(null);
    setIsModalOpen(false);
  };

  const handleEditClick = (pond: any) => {
    const num = pond.name.split('-')[1] || '';
    setFormData({
      numero: num,
      largo: '',
      ancho: '',
      profundidad: (pond.capacity_m3 || 0).toString()
    });
    setEditingPond(pond);
    setIsModalOpen(true);
  };

  const handleCreateEstanque = async () => {
    if (!formData.numero) {
      toast.error("Por favor asigne un número al estanque.");
      return;
    }

    setLoading(true);
    const createPromise = async () => {
      const name = `Est-${formData.numero.padStart(2, '0')}`;
      const vol = parseFloat(volumen);
      let activeUnitId = localStorage.getItem('active_unit_id');

      if (!activeUnitId) throw new Error("No se detectó unidad activa.");

      if (editingPond) {
        const { error } = await supabase
          .from('estanques')
          .update({ name, capacity_m3: vol })
          .eq('id', editingPond.id);
        if (error) throw error;
      } else {
        const { error } = await supabase.from('estanques').insert([{
          name,
          capacity_m3: vol,
          status: 'vacio',
          unit_id: activeUnitId
        }]);
        if (error) throw error;
      }
    };

    toast.promise(createPromise(), {
      loading: editingPond ? 'Actualizando estanque...' : 'Creando estanque...',
      success: () => {
        resetForm();
        fetchEstanques();
        return editingPond ? 'Estanque actualizado' : 'Estanque creado';
      },
      error: (err) => `Error: ${err.message}`
    }).finally(() => setLoading(false));
  };

  const handleDeleteSiembra = async (pond: any) => {
    const deletePromise = async () => {
      const { data: siembras, error: sErr } = await supabase
        .from('siembras')
        .select('*, siembra_details(*)')
        .eq('estanque_id', pond.id)
        .order('created_at', { ascending: false })
        .limit(1);

      if (sErr) throw sErr;

      if (!siembras || siembras.length === 0) {
        await supabase.from('estanques').update({
          status: 'vacio', 
          is_polyculture: false, 
          current_species: null, 
          current_count: 0, 
          current_biomass_kg: 0,
          costo_alevinos_acumulado: 0,
          consumo_alimento_acumulado_kg: 0,
          costo_alimento_acumulado: 0,
          current_batch_id: null
        }).eq('id', pond.id);
        await supabase.from('pond_species').delete().eq('estanque_id', pond.id);
        return;
      }

      const lastSiembra = siembras[0];
      
      let totalQtyDeleted = 0;
      let totalBiomassDeleted = 0;
      let totalCostoAlevinosDeleted = 0;

      const inventoryOps = (lastSiembra.siembra_details || []).map(async (detail: any) => {
        totalQtyDeleted += detail.quantity || 0;
        totalBiomassDeleted += parseFloat(detail.biomass_kg) || 0;
        totalCostoAlevinosDeleted += parseFloat(detail.costo_total_lote) || 0;

        // 1. Devolver al inventario
        if (detail.inventory_item_id) {
          const { data: inv } = await supabase.from('inventory').select('*').eq('id', detail.inventory_item_id).single();
          if (inv) {
            await supabase.from('inventory').update({ current_stock: (parseFloat(inv.current_stock) || 0) + detail.quantity }).eq('id', inv.id);
          }
        }

        // 2. Descontar de pond_species (o eliminar si llega a 0)
        if (detail.species_name) {
          const { data: pSpec } = await supabase.from('pond_species').select('*')
            .eq('estanque_id', pond.id)
            .eq('species_name', detail.species_name)
            .single();
          
          if (pSpec) {
            const newCount = (pSpec.current_count || 0) - (detail.quantity || 0);
            const newBio = Math.max(0, (parseFloat(pSpec.current_biomass_kg) || 0) - (parseFloat(detail.biomass_kg) || 0));
            if (newCount <= 0) {
              await supabase.from('pond_species').delete().eq('id', pSpec.id);
            } else {
              await supabase.from('pond_species').update({ current_count: newCount, current_biomass_kg: newBio }).eq('id', pSpec.id);
            }
          }
        }
      });

      await Promise.all(inventoryOps);

      // 3. Actualizar estado global del estanque
      const { data: remainingSpecs } = await supabase.from('pond_species').select('species_name, current_count').eq('estanque_id', pond.id);
      const activeSpecs = (remainingSpecs || []).filter((s: any) => s.current_count > 0);
      
      const newPondCount = Math.max(0, (pond.current_count || 0) - totalQtyDeleted);
      const newPondBiomass = Math.max(0, (parseFloat(pond.current_biomass_kg) || 0) - totalBiomassDeleted);
      const newCostoAlevinos = Math.max(0, (parseFloat(pond.costo_alevinos_acumulado) || 0) - totalCostoAlevinosDeleted);
      
      const isPoly = activeSpecs.length > 1;
      let label = null;
      if (activeSpecs.length === 1) label = activeSpecs[0].species_name;
      else if (activeSpecs.length > 1) label = 'Policultivo';

      await Promise.all([
        supabase.from('estanques').update({ 
          status: newPondCount > 0 ? 'con_peces' : 'vacio', 
          is_polyculture: isPoly, 
          current_species: label, 
          current_count: newPondCount, 
          current_biomass_kg: newPondBiomass,
          costo_alevinos_acumulado: newCostoAlevinos,
          // Mantenemos consumo_alimento_acumulado_kg y costo_alimento_acumulado intactos según la regla de negocio
          current_batch_id: newPondCount > 0 ? pond.current_batch_id : null
        }).eq('id', pond.id),
        supabase.from('siembras').delete().eq('id', lastSiembra.id)
      ]);
    };

    toast.promise(deletePromise(), {
      loading: 'Eliminando siembra...',
      success: () => { fetchEstanques(); return 'Siembra eliminada con éxito'; },
      error: (err) => `Error: ${err.message}`
    });
  };

  return (
    <div className="animate-fade-in page-container">
      <header style={{ marginBottom: '2.5rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem' }}>
        <div>
          <h1 style={{ fontWeight: 800 }}>Gestión de Estanques</h1>
          <p style={{ color: 'var(--muted-foreground)', fontSize: '0.9rem' }}>Supervisión y administración de infraestructura.</p>
        </div>
        <button className="btn-primary" onClick={() => setIsModalOpen(true)} style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', fontWeight: 700 }}>
          <Plus size={20} />
          Crear Estanque
        </button>
      </header>

      <div className="responsive-grid-3">
        {ponds.map((pond) => (
          <PondCard
            key={pond.id}
            pond={{...pond, onDetailClick: setSelectedDetailPond, onLiquidarClick: setSelectedLiquidationPond}}
            handleDeleteSiembra={handleDeleteSiembra}
            handleEditClick={handleEditClick}
          />
        ))}
      </div>

      <AnimatePresence>
        {isModalOpen && (
          <div style={{ position: 'fixed', top: 0, left: 0, width: '100vw', height: '100vh', zIndex: 9999, pointerEvents: 'none' }}>
            {/* Backdrop */}
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={resetForm}
              style={{ position: 'absolute', inset: 0, background: 'rgba(15, 23, 42, 0.5)', backdropFilter: 'blur(8px)', pointerEvents: 'auto' }}
            />

            {/* Modal Centrado */}
            <motion.div
              initial={{ scale: 0.9, opacity: 0, x: '-50%', y: '-40%' }}
              animate={{ scale: 1, opacity: 1, x: '-50%', y: '-50%' }}
              exit={{ scale: 0.9, opacity: 0, x: '-50%', y: '-40%' }}
              className="card-premium"
              style={{
                position: 'absolute',
                top: '50%',
                left: '50%',
                width: '90%',
                maxWidth: '450px',
                maxHeight: '85vh',
                overflowY: 'auto',
                padding: '2rem',
                pointerEvents: 'auto',
                display: 'flex',
                flexDirection: 'column',
                gap: '1.5rem',
                boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.5)'
              }}
            >
              <button onClick={resetForm} style={{ position: 'absolute', top: '1rem', right: '1rem', background: 'none', border: 'none', color: 'var(--muted-foreground)', cursor: 'pointer' }}><X size={20} /></button>
              <h2 style={{ fontWeight: 800 }}>{editingPond ? 'Editar Estanque' : 'Nuevo Estanque'}</h2>

              <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
                <div className="premium-input-group">
                  <label className="premium-label"><Hash size={14} /> Número de Estanque</label>
                  <div className="premium-input-wrapper">
                    <span style={{ fontWeight: 800, color: 'var(--muted-foreground)', marginRight: '0.5rem' }}>Est-</span>
                    <input
                      type="number"
                      name="numero"
                      value={formData.numero}
                      onChange={handleInputChange}
                      placeholder="01"
                      className="premium-input"
                      style={{ paddingLeft: 0 }}
                    />
                  </div>
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '0.75rem' }}>
                  <div className="premium-input-group">
                    <label className="premium-label">Largo (m)</label>
                    <input type="number" name="largo" value={formData.largo} onChange={handleInputChange} placeholder="0.0" className="premium-input" />
                  </div>
                  <div className="premium-input-group">
                    <label className="premium-label">Ancho (m)</label>
                    <input type="number" name="ancho" value={formData.ancho} onChange={handleInputChange} placeholder="0.0" className="premium-input" />
                  </div>
                  <div className="premium-input-group">
                    <label className="premium-label">Prof. (m)</label>
                    <input type="number" name="profundidad" value={formData.profundidad} onChange={handleInputChange} placeholder="0.0" className="premium-input" />
                  </div>
                </div>

                <div style={{ padding: '1.25rem', background: 'rgba(37, 99, 235, 0.05)', borderRadius: '12px', border: '1px solid rgba(37, 99, 235, 0.1)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <div>
                    <div style={{ fontSize: '0.65rem', fontWeight: 800, color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Capacidad Estimada</div>
                    <div style={{ fontSize: '1.5rem', fontWeight: 900, color: 'var(--primary)' }}>{volumen} <span style={{ fontSize: '0.8rem' }}>m³</span></div>
                  </div>
                  <Box size={32} style={{ color: 'var(--primary)', opacity: 0.2 }} />
                </div>

                <button className="btn-primary" disabled={loading} onClick={handleCreateEstanque} style={{ padding: '1rem', fontWeight: 800, height: '56px' }}>
                  {loading ? 'Procesando...' : editingPond ? 'Guardar Cambios' : 'Crear Estanque'}
                </button>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

      <AnimatePresence>
        {selectedDetailPond && (
          <PondDetailModal 
            pond={selectedDetailPond} 
            onClose={() => setSelectedDetailPond(null)} 
          />
        )}
        {selectedLiquidationPond && (
          <LiquidationModal 
            pond={selectedLiquidationPond} 
            onClose={() => setSelectedLiquidationPond(null)} 
            fetchEstanques={fetchEstanques}
          />
        )}
      </AnimatePresence>

      <AnimatedWaves />
    </div>
  );
}
