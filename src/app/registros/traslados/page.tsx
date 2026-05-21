'use client';
// Recompiling...

import { useEffect, useState, useMemo } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  ArrowRightLeft, 
  Calendar, 
  Waves, 
  ArrowLeft,
  ArrowRight,
  Activity,
  Info,
  ShieldCheck,
  TrendingDown,
  TrendingUp,
  Zap,
  Box,
  CornerRightDown,
  History,
  ChevronRight,
  Plus,
  AlertCircle
} from 'lucide-react';
import Link from 'next/link';
import { toast } from 'react-hot-toast';
import { supabase } from '@/lib/supabase';

export default function TrasladoPage() {
  const [fecha, setFecha] = useState(new Date().toISOString().split('T')[0]);
  const [origenId, setOrigenId] = useState('');
  const [destinoId, setDestinoId] = useState('');
  const [traslados, setTraslados] = useState<any[]>([]);
  const [ponds, setPonds] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);

  const [history, setHistory] = useState<any[]>([]);

  useEffect(() => {
    fetchPonds();
    fetchHistory();
  }, []);

  const fetchHistory = async () => {
    const activeUnitId = localStorage.getItem('active_unit_id');
    if (!activeUnitId) return;

    const { data } = await supabase
      .from('transfers')
      .select('*, origen:estanques!origen_id(name), destino:estanques!destino_id(name)')
      .eq('unit_id', activeUnitId)
      .order('date', { ascending: false })
      .limit(20);
    
    if (data) setHistory(data);
  };

  const fetchPonds = async () => {
    const activeUnitId = localStorage.getItem('active_unit_id');
    const { data } = await supabase
      .from('estanques')
      .select('*')
      .eq('unit_id', activeUnitId)
      .order('name');
    setPonds(data || []);
  };

  const fetchOrigenSpecies = async (pondId: string) => {
    setLoading(true);
    // Include current_biomass_kg so we can compute proportional biomass transfer
    const { data } = await supabase
      .from('pond_species')
      .select('id, species_name, current_count, current_biomass_kg, avg_weight_gr')
      .eq('estanque_id', pondId);
    if (data && data.length > 0) {
      setTraslados(data.map((s: any) => ({
        speciesId: s.id,
        speciesName: s.species_name,
        quantity: '',
        currentCount: s.current_count || 0,
        currentBiomassKg: parseFloat(s.current_biomass_kg) || 0,
        avgWeightGr: parseFloat(s.avg_weight_gr) || 0
      })));
    } else {
      const p = ponds.find(pond => pond.id === pondId);
      const totalCount = p?.current_count || 0;
      const totalBiomass = parseFloat(p?.current_biomass_kg) || 0;
      setTraslados([{
        speciesId: null,
        speciesName: p?.current_species || 'Especie Principal',
        quantity: '',
        currentCount: totalCount,
        currentBiomassKg: totalBiomass,
        avgWeightGr: totalCount > 0 ? (totalBiomass / totalCount) * 1000 : 0
      }]);
    }
    setLoading(false);
  };

  useEffect(() => {
    if (origenId) {
      fetchOrigenSpecies(origenId);
    } else {
      setTraslados([]);
    }
  }, [origenId, ponds]);

  const addNewSpeciesRow = () => {
    setTraslados([...traslados, {
      speciesId: null,
      speciesName: '',
      quantity: '',
      currentCount: 0,
      currentBiomassKg: 0,
      avgWeightGr: 0
    }]);
  };

  const removeSpeciesRow = (index: number) => {
    if (traslados.length > 1) {
      const newTras = [...traslados];
      newTras.splice(index, 1);
      setTraslados(newTras);
    }
  };

  const updateTraslado = (index: number, field: string, value: string) => {
    const newTraslados = [...traslados];
    newTraslados[index] = { ...newTraslados[index], [field]: value };
    setTraslados(newTraslados);
  };

  const handleRegisterTraslado = async () => {
    setLoading(true);
    try {
      const activeUnitId = localStorage.getItem('active_unit_id');
      if (!origenId || !destinoId || !activeUnitId) throw new Error('Complete los campos requeridos');

      const registerPromise = async () => {
        if (!origenId || !destinoId || !activeUnitId) throw new Error("Complete los campos requeridos");

        // 1. Obtener estado actual completo del origen
        const { data: origenData } = await supabase
          .from('estanques')
          .select('*')
          .eq('id', origenId)
          .single();

        if (!origenData) throw new Error("No se encontró el estanque origen");

        const totalPecesOrigen = origenData.current_count || 0;
        const totalBiomasaOrigen = parseFloat(origenData.current_biomass_kg) || 0;
        const costoAlevinosOrigen = parseFloat(origenData.costo_alevinos_acumulado) || 0;
        const consumoAcumuladoOrigen = parseFloat(origenData.consumo_alimento_acumulado_kg) || 0;
        const costoAlimentoOrigen = parseFloat(origenData.costo_alimento_acumulado) || 0;

        // 2. Calcular total de peces a trasladar
        const totalPecesTraslado = traslados.reduce((s: number, t: any) => s + (parseInt(t.quantity) || 0), 0);
        if (totalPecesTraslado <= 0) throw new Error("Ingrese al menos una cantidad a trasladar");
        if (totalPecesTraslado > totalPecesOrigen) throw new Error("La cantidad supera la población del estanque origen");

        // 3. Determinar si es traslado total o parcial
        const esTotal = totalPecesTraslado === totalPecesOrigen;
        const fraccion = totalPecesOrigen > 0 ? totalPecesTraslado / totalPecesOrigen : 1;

        // 4. Calcular valores proporcionales a trasladar
        const biomasaArrastrada = totalBiomasaOrigen * fraccion;
        const costoAlevinosArrastrado = costoAlevinosOrigen * fraccion;
        const consumoArrastrado = consumoAcumuladoOrigen * fraccion;
        const costoAlimentoArrastrado = costoAlimentoOrigen * fraccion;

        // 5. Guardar snapshot del origen antes de modificarlo
        const snapshotOrigen = {
          current_count: totalPecesOrigen,
          current_biomass_kg: totalBiomasaOrigen,
          costo_alevinos_acumulado: costoAlevinosOrigen,
          consumo_alimento_acumulado_kg: consumoAcumuladoOrigen,
          costo_alimento_acumulado: costoAlimentoOrigen,
          status: origenData.status,
          current_species: origenData.current_species,
          is_polyculture: origenData.is_polyculture,
          current_batch_id: origenData.current_batch_id
        };

        // 6. Registrar cada especie en transfers
        for (const t of traslados) {
          const qty = parseInt(t.quantity) || 0;
          if (qty <= 0) continue;

          // Calcular fracción de esta especie dentro del traslado total para distribuir costos
          const fraccionEspecie = qty / totalPecesTraslado;
          const costoAlevinosEspecie = costoAlevinosArrastrado * fraccionEspecie;
          const consumoEspecie = consumoArrastrado * fraccionEspecie;
          const costoAlimentoEspecie = costoAlimentoArrastrado * fraccionEspecie;

          const { error: logError } = await supabase.from('transfers').insert([{
            origen_id: origenId,
            destino_id: destinoId,
            unit_id: activeUnitId,
            species_name: t.speciesName,
            quantity: qty,
            date: fecha,
            batch_id_origen: origenData.current_batch_id,
            es_traslado_total: esTotal,
            consumo_kg_arrastrado: consumoEspecie,
            costo_alimento_arrastrado: costoAlimentoEspecie,
            costo_alevinos_arrastrado: costoAlevinosEspecie,
            snapshot_origen: snapshotOrigen,
            revertido: false
          }]);
          if (logError) throw logError;
        }

        // 7. Actualizar pond_species del origen
        for (const t of traslados) {
          const qty = parseInt(t.quantity) || 0;
          if (qty <= 0) continue;

          if (t.speciesId) {
            const newCount = (t.currentCount || 0) - qty;
            if (newCount <= 0) {
              await supabase.from('pond_species').delete().eq('id', t.speciesId);
            } else {
              await supabase.from('pond_species').update({ current_count: newCount }).eq('id', t.speciesId);
            }
          }
        }

        // 8. Actualizar estanque origen
        if (esTotal) {
          await supabase.from('estanques').update({
            status: 'vacio',
            current_count: 0,
            current_biomass_kg: 0,
            current_species: null,
            is_polyculture: false,
            current_batch_id: null,
            costo_alevinos_acumulado: 0,
            consumo_alimento_acumulado_kg: 0,
            costo_alimento_acumulado: 0
          }).eq('id', origenId);
        } else {
          await supabase.from('estanques').update({
            current_count: totalPecesOrigen - totalPecesTraslado,
            current_biomass_kg: totalBiomasaOrigen - biomasaArrastrada,
            costo_alevinos_acumulado: costoAlevinosOrigen - costoAlevinosArrastrado,
            consumo_alimento_acumulado_kg: consumoAcumuladoOrigen - consumoArrastrado,
            costo_alimento_acumulado: costoAlimentoOrigen - costoAlimentoArrastrado
          }).eq('id', origenId);
        }

        // 9. Actualizar estanque destino: sumar todo lo arrastrado
        const { data: destinoData } = await supabase
          .from('estanques')
          .select('*')
          .eq('id', destinoId)
          .single();

        if (!destinoData) throw new Error("No se encontró el estanque destino");

        const destinoEstabaVacio = destinoData.status === 'vacio' || (destinoData.current_count || 0) === 0;

        await supabase.from('estanques').update({
          status: 'con_peces',
          current_count: (destinoData.current_count || 0) + totalPecesTraslado,
          current_biomass_kg: (parseFloat(destinoData.current_biomass_kg) || 0) + biomasaArrastrada,
          costo_alevinos_acumulado: (parseFloat(destinoData.costo_alevinos_acumulado) || 0) + costoAlevinosArrastrado,
          consumo_alimento_acumulado_kg: (parseFloat(destinoData.consumo_alimento_acumulado_kg) || 0) + consumoArrastrado,
          costo_alimento_acumulado: (parseFloat(destinoData.costo_alimento_acumulado) || 0) + costoAlimentoArrastrado,
          current_species: destinoEstabaVacio
            ? (traslados.length > 1 ? 'Policultivo' : traslados[0].speciesName)
            : destinoData.current_species,
          is_polyculture: destinoEstabaVacio
            ? traslados.length > 1
            : (destinoData.is_polyculture || traslados.length > 1),
          current_batch_id: destinoEstabaVacio 
            ? origenData.current_batch_id 
            : destinoData.current_batch_id
        }).eq('id', destinoId);

        // 10. Actualizar pond_species del destino
        for (const t of traslados) {
          const qty = parseInt(t.quantity) || 0;
          if (qty <= 0) continue;

          const { data: destSpecies } = await supabase
            .from('pond_species')
            .select('*')
            .eq('estanque_id', destinoId)
            .eq('species_name', t.speciesName)
            .single();

          if (destSpecies) {
            await supabase.from('pond_species')
              .update({ current_count: (destSpecies.current_count || 0) + qty })
              .eq('id', destSpecies.id);
          } else {
            await supabase.from('pond_species').insert([{
              estanque_id: destinoId,
              species_name: t.speciesName,
              current_count: qty,
              unit_id: activeUnitId
            }]);
          }
        }

        return true;
      };

      toast.promise(registerPromise(), {
        loading: 'Procesando traslado...',
        success: () => {
          setOrigenId('');
          setDestinoId('');
          fetchPonds();
          fetchHistory();
          return '¡Traslado registrado con éxito!';
        },
        error: (err: any) => `Error: ${err.message}`
      });
    } catch (err: any) {
      toast.error(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleRevertirTraslado = async (transfer: any) => {
    if (!confirm(`¿Revertir este traslado? Los peces (${transfer.quantity?.toLocaleString()}) volverán al estanque origen.`)) return;

    const revertPromise = async () => {
      const activeUnitId = localStorage.getItem('active_unit_id');

      // Obtener estado actual del destino
      const { data: destinoActual } = await supabase
        .from('estanques')
        .select('*')
        .eq('id', transfer.destino_id)
        .single();

      if (!destinoActual) throw new Error("No se encontró el estanque destino");
      if ((destinoActual.current_count || 0) < transfer.quantity) {
        throw new Error("El destino ya no tiene suficientes peces para revertir");
      }

      const snap = transfer.snapshot_origen;

      // 1. Calcular biomasa y costos a devolver
      // Si el registro tiene los datos arrastrados (traslados nuevos), los usamos. 
      // Si no, hacemos cálculo proporcional (traslados viejos).
      const { data: origenActual } = await supabase.from('estanques').select('*').eq('id', transfer.origen_id).single();
      if (!origenActual) throw new Error("No se encontró el estanque origen");

      const biomasaDevuelta = snap 
        ? (transfer.quantity * (snap.current_biomass_kg / (snap.current_count || 1)))
        : (transfer.quantity * ((parseFloat(destinoActual.current_biomass_kg) || 0) / (destinoActual.current_count || 1)));

      const costoAlevinosDevuelto = transfer.costo_alevinos_arrastrado || 0;
      const consumoDevuelto = transfer.consumo_kg_arrastrado || 0;
      const costoAlimentoDevuelto = transfer.costo_alimento_arrastrado || 0;

      // 2. ACTUALIZAR ORIGEN (Sumar)
      await supabase.from('estanques').update({
        status: 'con_peces',
        current_count: (origenActual.current_count || 0) + transfer.quantity,
        current_biomass_kg: (parseFloat(origenActual.current_biomass_kg) || 0) + biomasaDevuelta,
        costo_alevinos_acumulado: (parseFloat(origenActual.costo_alevinos_acumulado) || 0) + costoAlevinosDevuelto,
        consumo_alimento_acumulado_kg: (parseFloat(origenActual.consumo_alimento_acumulado_kg) || 0) + consumoDevuelto,
        costo_alimento_acumulado: (parseFloat(origenActual.costo_alimento_acumulado) || 0) + costoAlimentoDevuelto,
        current_batch_id: origenActual.current_batch_id || transfer.batch_id_origen
      }).eq('id', transfer.origen_id);

      // Actualizar/crear pond_species en origen para esta especie específica
      const { data: origenSpecies } = await supabase
        .from('pond_species')
        .select('*')
        .eq('estanque_id', transfer.origen_id)
        .eq('species_name', transfer.species_name)
        .single();

      if (origenSpecies) {
        await supabase.from('pond_species')
          .update({ 
            current_count: (origenSpecies.current_count || 0) + transfer.quantity,
            current_biomass_kg: (parseFloat(origenSpecies.current_biomass_kg) || 0) + biomasaDevuelta
          })
          .eq('id', origenSpecies.id);
      } else {
        await supabase.from('pond_species').insert([{
          estanque_id: transfer.origen_id,
          species_name: transfer.species_name,
          current_count: transfer.quantity,
          current_biomass_kg: biomasaDevuelta,
          unit_id: activeUnitId || transfer.unit_id
        }]);
      }

      // 3. ACTUALIZAR DESTINO (Restar)
      const nuevoCountDestino = (destinoActual.current_count || 0) - transfer.quantity;
      await supabase.from('estanques').update({
        status: nuevoCountDestino <= 0 ? 'vacio' : 'con_peces',
        current_count: nuevoCountDestino,
        current_biomass_kg: Math.max(0, (parseFloat(destinoActual.current_biomass_kg) || 0) - biomasaDevuelta),
        costo_alevinos_acumulado: Math.max(0, (parseFloat(destinoActual.costo_alevinos_acumulado) || 0) - costoAlevinosDevuelto),
        consumo_alimento_acumulado_kg: Math.max(0, (parseFloat(destinoActual.consumo_alimento_acumulado_kg) || 0) - consumoDevuelto),
        costo_alimento_acumulado: Math.max(0, (parseFloat(destinoActual.costo_alimento_acumulado) || 0) - costoAlimentoDevuelto)
      }).eq('id', transfer.destino_id);

      // Actualizar pond_species en destino para esta especie específica (Restar o Eliminar)
      const { data: destinoSpecies } = await supabase
        .from('pond_species')
        .select('*')
        .eq('estanque_id', transfer.destino_id)
        .eq('species_name', transfer.species_name)
        .single();

      if (destinoSpecies) {
        const nuevoCountEspecie = (destinoSpecies.current_count || 0) - transfer.quantity;
        const nuevaBiomasaEspecie = Math.max(0, (parseFloat(destinoSpecies.current_biomass_kg) || 0) - biomasaDevuelta);
        
        if (nuevoCountEspecie <= 0) {
          await supabase.from('pond_species').delete().eq('id', destinoSpecies.id);
        } else {
          await supabase.from('pond_species').update({
            current_count: nuevoCountEspecie,
            current_biomass_kg: nuevaBiomasaEspecie
          }).eq('id', destinoSpecies.id);
        }
      }

      // 4. RECALCULAR ETIQUETAS Y ESTADO (Origen y Destino)
      const updatePondMetadata = async (pondId: string) => {
        const { data: specs } = await supabase.from('pond_species').select('species_name, current_count').eq('estanque_id', pondId);
        const activeSpecs = (specs || []).filter((s: any) => s.current_count > 0);
        
        const isPoly = activeSpecs.length > 1;
        let label = 'Vacío';
        if (activeSpecs.length === 1) label = activeSpecs[0].species_name;
        else if (activeSpecs.length > 1) label = 'Policultivo';

        await supabase.from('estanques').update({
          is_polyculture: isPoly,
          current_species: label,
          status: activeSpecs.length > 0 ? 'con_peces' : 'vacio'
        }).eq('id', pondId);
      };

      await updatePondMetadata(transfer.origen_id);
      await updatePondMetadata(transfer.destino_id);

      // 5. Marcar como revertido
      await supabase.from('transfers').update({
        revertido: true,
        revertido_at: new Date().toISOString()
      }).eq('id', transfer.id);
    };

    toast.promise(revertPromise(), {
      loading: 'Revirtiendo traslado...',
      success: () => { fetchHistory(); fetchPonds(); return 'Traslado revertido con éxito'; },
      error: (err: any) => `Error: ${err.message}`
    });
  };

  return (
    <div className="animate-fade-in page-container">
      <header style={{ marginBottom: '2rem', display: 'flex', alignItems: 'center', gap: '1rem' }}>
        <Link href="/registros" style={{ color: 'var(--muted-foreground)', display: 'flex', alignItems: 'center', justifyContent: 'center', width: '40px', height: '40px', borderRadius: '50%', background: 'var(--card)', border: '1px solid var(--border)' }}>
          <ArrowLeft size={20} />
        </Link>
        <div>
          <h1 style={{ fontWeight: 800 }}>Traslado de Peces</h1>
          <p style={{ color: 'var(--muted-foreground)', fontSize: '0.9rem' }}>Movimiento interno de biomasa.</p>
        </div>
      </header>

      <div className="responsive-grid-2">
        <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
          {/* Main Transfer Flow */}
          <div className="card-premium" style={{ padding: '1.5rem' }}>
            <div className="premium-input-group" style={{ marginBottom: '1.5rem' }}>
              <label className="premium-label">Fecha</label>
              <input type="date" value={fecha} onChange={(e) => setFecha(e.target.value)} className="premium-input" />
            </div>

            <div className="responsive-grid-2" style={{ marginBottom: '1.5rem' }}>
              <div className="premium-input-group">
                <label className="premium-label">Origen</label>
                <div className="premium-select-wrapper">
                  <select value={origenId} onChange={(e) => setOrigenId(e.target.value)} className="premium-input">
                    <option value="">Seleccionar...</option>
                    {ponds.map(p => <option key={p.id} value={p.id}>{p.name}</option>)}
                  </select>
                </div>
              </div>
              <div className="premium-input-group">
                <label className="premium-label">Destino</label>
                <div className="premium-select-wrapper">
                  <select value={destinoId} onChange={(e) => setDestinoId(e.target.value)} className="premium-input">
                    <option value="">Seleccionar...</option>
                    {ponds.filter(p => p.id !== origenId).map(p => <option key={p.id} value={p.id}>{p.name}</option>)}
                  </select>
                </div>
              </div>
            </div>

            <AnimatePresence>
              {origenId && (
                <motion.div 
                  initial={{ opacity: 0, y: 10 }} 
                  animate={{ opacity: 1, y: 0 }} 
                  exit={{ opacity: 0, y: -10 }}
                  key="traslado-form"
                >
                  {traslados.length > 1 && traslados.some(t => !t.speciesId) && (
                    <div style={{ 
                      padding: '1rem', 
                      borderRadius: '12px', 
                      background: 'rgba(245, 158, 11, 0.1)', 
                      border: '1px solid rgba(245, 158, 11, 0.2)',
                      display: 'flex',
                      gap: '0.75rem',
                      alignItems: 'center',
                      marginBottom: '1rem'
                    }}>
                      <AlertCircle size={20} style={{ color: '#f59e0b' }} />
                      <div style={{ fontSize: '0.85rem', color: '#92400e', lineHeight: 1.4 }}>
                        <strong>Aviso:</strong> No hay desglose de especies para este policultivo en origen. Puede definirlas a continuación.
                      </div>
                    </div>
                  )}

                  <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem', marginBottom: '2.5rem' }}>
                    {traslados.map((t, index) => (
                      <div key={index} className="traslado-row-grid" style={{ 
                        padding: '1.25rem', 
                        background: 'var(--secondary)', 
                        borderRadius: '12px', 
                        border: '1px solid var(--border)',
                        position: 'relative'
                      }}>
                        {traslados.length > 1 && (
                          <button 
                            onClick={() => removeSpeciesRow(index)}
                            style={{ position: 'absolute', top: '0.5rem', right: '0.5rem', color: '#ef4444', background: 'none', border: 'none', cursor: 'pointer', fontSize: '0.65rem', fontWeight: 800 }}
                          >
                            X
                          </button>
                        )}
                        <div>
                          {t.speciesId ? (
                            <div style={{ fontWeight: 800, fontSize: '0.95rem' }}>{t.speciesName}</div>
                          ) : (
                            <input 
                              type="text"
                              value={t.speciesName}
                              onChange={(e) => updateTraslado(index, 'speciesName', e.target.value)}
                              placeholder="Especie"
                              style={{ width: '100%', padding: '0.4rem', borderRadius: '6px', border: '1px solid var(--border)', fontSize: '0.85rem', fontWeight: 700 }}
                            />
                          )}
                          <div style={{ fontSize: '0.75rem', color: 'var(--muted-foreground)' }}>En origen: {t.currentCount.toLocaleString()}</div>
                        </div>
                        <div>
                          <input 
                            type="number" 
                            value={t.quantity}
                            onChange={(e) => updateTraslado(index, 'quantity', e.target.value)}
                            placeholder="Cant."
                            style={{ width: '100%', padding: '0.5rem', borderRadius: '8px', border: '1px solid var(--border)', background: 'white', outline: 'none', fontWeight: 800 }}
                          />
                        </div>
                        <div style={{ textAlign: 'center' }}>
                          <CornerRightDown size={18} style={{ color: 'var(--primary)' }} />
                        </div>
                      </div>
                    ))}

                    {traslados.length > 1 && (
                      <button 
                        onClick={addNewSpeciesRow}
                        style={{ 
                          width: '100%', 
                          padding: '0.75rem', 
                          borderRadius: '10px', 
                          border: '2px dashed var(--border)', 
                          background: 'none', 
                          color: 'var(--muted-foreground)', 
                          fontWeight: 700, 
                          cursor: 'pointer',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          gap: '0.5rem',
                          fontSize: '0.85rem'
                        }}
                      >
                        <Plus size={14} /> Agregar otra especie al traslado
                      </button>
                    )}
                  </div>

                  <button onClick={handleRegisterTraslado} className="btn-primary" disabled={loading} style={{ width: '100%', padding: '1rem', borderRadius: '12px', fontWeight: 800, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '0.5rem' }}>
                    {loading ? <Activity className="animate-spin" size={18} /> : <ArrowRightLeft size={18} />}
                    Registrar Traslado
                  </button>
                </motion.div>
              )}
            </AnimatePresence>
          </div>
        </div>

        {/* Info Panel */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
          <div className="card-premium" style={{ padding: '2rem' }}>
            <h3 style={{ fontSize: '0.85rem', fontWeight: 800, color: 'var(--muted-foreground)', textTransform: 'uppercase', marginBottom: '1.5rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <ShieldCheck size={20} style={{ color: 'var(--primary)' }} />
              Reglas de Traslado
            </h3>
            <ul style={{ listStyle: 'none', padding: 0, display: 'flex', flexDirection: 'column', gap: '1rem' }}>
              <li style={{ display: 'flex', gap: '0.75rem', fontSize: '0.85rem', lineHeight: 1.4 }}>
                <Zap size={16} style={{ color: '#f59e0b', flexShrink: 0 }} />
                <span>La trazabilidad de alimentación se mantiene vinculada al lote (Batch ID) durante el traslado.</span>
              </li>
              <li style={{ display: 'flex', gap: '0.75rem', fontSize: '0.85rem', lineHeight: 1.4 }}>
                <Box size={16} style={{ color: '#3b82f6', flexShrink: 0 }} />
                <span>Si el destino está vacío, heredará automáticamente las propiedades de las especies trasladadas.</span>
              </li>
            </ul>
          </div>
        </div>

        {/* Full Width History Table */}
        <div style={{ gridColumn: '1 / -1', marginTop: '3rem' }}>
          <div className="card-premium" style={{ padding: '2rem' }}>
            <h3 style={{ fontSize: '1.1rem', fontWeight: 800, marginBottom: '1.5rem', display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
              <History size={20} style={{ color: 'var(--primary)' }} />
              Historial de Traslados Recientes
            </h3>
            
            <div style={{ overflowX: 'auto' }}>
              <table style={{ width: '100%', borderCollapse: 'collapse', minWidth: '750px' }}>
                <thead>
                  <tr style={{ borderBottom: '2px solid var(--border)' }}>
                    <th style={{ textAlign: 'left', padding: '1rem', fontSize: '0.8rem', color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Especie</th>
                    <th style={{ textAlign: 'left', padding: '1rem', fontSize: '0.8rem', color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Cantidad</th>
                    <th style={{ textAlign: 'left', padding: '1rem', fontSize: '0.8rem', color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Flujo (Origen → Destino)</th>
                    <th style={{ textAlign: 'left', padding: '1rem', fontSize: '0.8rem', color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Alimento Trasladado</th>
                    <th style={{ textAlign: 'left', padding: '1rem', fontSize: '0.8rem', color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Fecha</th>
                    <th style={{ textAlign: 'left', padding: '1rem', fontSize: '0.8rem', color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Acciones</th>
                  </tr>
                </thead>
                <tbody>
                  {history.map((h) => (
                    <tr key={h.id} style={{ borderBottom: '1px solid var(--border)', opacity: h.revertido ? 0.55 : 1 }}>
                      <td style={{ padding: '1rem', fontWeight: 700 }}>{h.species_name}</td>
                      <td style={{ padding: '1rem', fontWeight: 800, color: '#f59e0b' }}>{h.quantity?.toLocaleString()}</td>
                      <td style={{ padding: '1rem' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                          <span style={{ padding: '0.25rem 0.6rem', background: 'rgba(245, 158, 11, 0.1)', borderRadius: '6px', fontSize: '0.8rem', fontWeight: 600, color: '#f59e0b' }}>
                            {h.origen?.name}
                          </span>
                          <ChevronRight size={14} style={{ color: 'var(--muted-foreground)' }} />
                          <span style={{ padding: '0.25rem 0.6rem', background: 'rgba(59, 130, 246, 0.1)', borderRadius: '6px', fontSize: '0.8rem', fontWeight: 600, color: '#3b82f6' }}>
                            {h.destino?.name}
                          </span>
                        </div>
                      </td>
                      <td style={{ padding: '1rem' }}>
                        {(h.consumo_kg_arrastrado != null || h.food_total_kg != null) ? (
                          <span style={{ fontSize: '0.8rem', fontWeight: 700, color: '#10b981' }}>
                            {parseFloat(h.consumo_kg_arrastrado ?? h.food_total_kg).toLocaleString('es-CO', { maximumFractionDigits: 2 })} kg
                          </span>
                        ) : (
                          <span style={{ fontSize: '0.75rem', color: 'var(--muted-foreground)' }}>—</span>
                        )}
                      </td>
                      <td style={{ padding: '1rem', fontSize: '0.85rem', color: 'var(--muted-foreground)' }}>
                        {new Date(h.date).toLocaleDateString()}
                      </td>
                      <td style={{ padding: '1rem' }}>
                        {!h.revertido ? (
                          <button
                            onClick={() => handleRevertirTraslado(h)}
                            style={{
                              padding: '0.4rem 0.8rem',
                              borderRadius: '8px',
                              border: '1px solid rgba(239, 68, 68, 0.3)',
                              background: 'rgba(239, 68, 68, 0.05)',
                              color: '#ef4444',
                              fontSize: '0.75rem',
                              fontWeight: 800,
                              cursor: 'pointer'
                            }}
                          >
                            Reversar
                          </button>
                        ) : (
                          <span style={{
                            padding: '0.3rem 0.7rem',
                            borderRadius: '8px',
                            background: 'rgba(239, 68, 68, 0.1)',
                            color: '#ef4444',
                            fontSize: '0.65rem',
                            fontWeight: 900
                          }}>
                            REVERTIDO
                          </span>
                        )}
                      </td>
                    </tr>
                  ))}
                  {history.length === 0 && (
                    <tr>
                      <td colSpan={6} style={{ padding: '3rem', textAlign: 'center', color: 'var(--muted-foreground)' }}>No hay movimientos registrados.</td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
