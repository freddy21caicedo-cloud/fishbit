'use client';

import { useState, useMemo, useEffect } from 'react';
import { 
  Plus, 
  Trash2, 
  Calendar, 
  Clock, 
  Waves, 
  Scale, 
  Fish, 
  AlertCircle,
  ArrowLeft
} from 'lucide-react';
import Link from 'next/link';
import { useRouter, useSearchParams } from 'next/navigation';
import { toast } from 'react-hot-toast';

import { supabase } from '@/lib/supabase';

interface InventoryItem {
  id: string;
  name: string;
  current_stock: string | number;
  unit: string;
  category: string;
  especie?: string;
  stock?: number;
}

interface Estanque {
  id: string;
  name: string;
  status: string;
  current_count?: number;
  current_biomass_kg?: string | number;
  costo_alevinos_acumulado?: string | number;
}

interface SpeciesRow {
  id: string;
  especie: string;
  cantidad: string;
  pesoPromedio: string;
}

export default function SiembraPage() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const estanqueParam = searchParams.get('estanque');

  const [alevinosStock, setAlevinosStock] = useState<InventoryItem[]>([]);
  const [fecha, setFecha] = useState(new Date().toISOString().split('T')[0]);
  const [hora, setHora] = useState(new Date().toTimeString().slice(0, 5));
  const [estanque, setEstanque] = useState(estanqueParam || '');
  const [estanquesList, setEstanquesList] = useState<Estanque[]>([]);

  // IMPORTANT: rows must be declared BEFORE fetchAlevinosStock to avoid stale-closure reference.
  const [rows, setRows] = useState<SpeciesRow[]>([
    { id: typeof crypto !== 'undefined' ? crypto.randomUUID() : '1', especie: '', cantidad: '', pesoPromedio: '' }
  ]);

  useEffect(() => {
    fetchAlevinosStock();
    fetchEstanques();
  }, []);

  const fetchAlevinosStock = async () => {
    try {
      const activeUnitId = typeof window !== 'undefined' ? localStorage.getItem('active_unit_id') : null;
      if (!activeUnitId) return;

      const { data, error } = await supabase
        .from('inventory')
        .select('*')
        .eq('category', 'alevinos')
        .eq('unit_id', activeUnitId); // SECURITY FIX
      
      if (error) throw error;
      
      const formatted: InventoryItem[] = (data || []).map(i => ({
        ...i,
        especie: i.name,
        stock: Number(i.current_stock) || 0,
        unidad: i.unit || 'uds'
      }));
      setAlevinosStock(formatted);
      
      if (formatted.length > 0 && rows.length === 1 && (!rows[0].especie)) {
        setRows([{ ...rows[0], especie: formatted[0].especie || '' }]);
      }
    } catch (error: any) {
      toast.error("Error al cargar stock: " + error.message);
    }
  };

  const fetchEstanques = async () => {
    try {
      const activeUnitId = typeof window !== 'undefined' ? localStorage.getItem('active_unit_id') : null;
      if (!activeUnitId) return; // Bug #13 fix: guard against null unitId
      const { data, error } = await supabase
        .from('estanques')
        .select('*')
        .eq('unit_id', activeUnitId);
      
      if (error) throw error;
      setEstanquesList(data || []);
    } catch (error: any) {
      toast.error("Error al cargar estanques: " + error.message);
    }
  };

  const selectedPondRecord = useMemo(() => {
    return estanquesList.find(p => p.id === estanque);
  }, [estanque, estanquesList]);

  const handleFinalize = async () => {
    if (!estanque) {
      toast.error("Por favor seleccione un estanque.");
      return;
    }

    const pond = selectedPondRecord;
    if (!pond) {
      toast.error("El estanque seleccionado no existe.");
      return;
    }

    const activeUnitId = typeof window !== 'undefined' ? localStorage.getItem('active_unit_id') : null;
    if (!activeUnitId) {
      toast.error("Error: No se detectó unidad vinculada.");
      return;
    }

    const finalizePromise = async () => {
      // 1. Create Seeding Header
      const speciesCode = rows.length === 1 ? rows[0].especie.slice(0, 3).toUpperCase() : 'POLI';
      const batchId = `LOTE-${new Date().toISOString().slice(2, 10).replace(/-/g, '')}-${speciesCode}-${pond.name.replace(/\s+/g, '').toUpperCase()}`;
      const totalQty = rows.reduce((acc, r) => acc + (parseInt(r.cantidad) || 0), 0);
      
      const { data: siembraData, error: siembraError } = await supabase
        .from('siembras')
        .insert([{
          estanque_id: pond.id,
          date: fecha,
          hour: hora,
          total_quantity: totalQty,
          total_biomass_kg: totalBiomasa,
          unit_id: activeUnitId,
          batch_id: batchId
        }])
        .select();

      if (siembraError || !siembraData || siembraData.length === 0) {
        throw siembraError || new Error("Error al crear cabecera de siembra");
      }

      const siembraId = siembraData[0].id;
      const isPolyculture = rows.length > 1;

        // 2. Prepare Details for Bulk Insert (with cost tracking per row)
        const detailsToInsert = await Promise.all(rows.map(async row => {
          const qty = parseInt(row.cantidad) || 0;
          const weight = parseFloat(row.pesoPromedio) || 0;
          const bio = (qty * weight) / 1000;
          const stockItem = alevinosStock.find(s => s.especie === row.especie);

          // Buscar costo promedio del alevino por unidad desde facturas
          const { data: invoiceItemsData } = await supabase
            .from('invoice_items')
            .select('quantity, unit_price, invoices!inner(category, unit_id)')
            .eq('invoices.category', 'alevinos')
            .eq('invoices.unit_id', activeUnitId)
            .ilike('product_name', `%${row.especie}%`);

          let costoUnitario = 0;
          if (invoiceItemsData && invoiceItemsData.length > 0) {
            const totalQty = invoiceItemsData.reduce((s: number, i: any) => s + (parseFloat(i.quantity) || 0), 0);
            const totalCost = invoiceItemsData.reduce((s: number, i: any) => s + ((parseFloat(i.quantity) || 0) * (parseFloat(i.unit_price) || 0)), 0);
            costoUnitario = totalQty > 0 ? totalCost / totalQty : 0;
          }

          const costoTotalLote = costoUnitario * qty;

          return {
            siembra_id: siembraId,
            species_name: row.especie,
            quantity: qty,
            avg_weight_gr: weight,
            biomass_kg: bio,
            inventory_item_id: stockItem?.id || null,
            costo_unitario_alevino: costoUnitario,
            costo_total_lote: costoTotalLote
          };
        }));

        const { error: detailsError } = await supabase
          .from('siembra_details')
          .insert(detailsToInsert);

        if (detailsError) throw detailsError;

        // Acumular costo total de alevinos en el estanque
        const costoAlevinosTotal = detailsToInsert.reduce((s: number, d: any) => s + (d.costo_total_lote || 0), 0);
        await supabase
          .from('estanques')
          .update({
            costo_alevinos_acumulado: (parseFloat(pond.costo_alevinos_acumulado as string) || 0) + costoAlevinosTotal
          })
          .eq('id', pond.id);

      // 3. Update Pond Species and Inventory
      for (const row of rows) {
        const qty = parseInt(row.cantidad) || 0;
        const weight = parseFloat(row.pesoPromedio) || 0;
        const bio = (qty * weight) / 1000;
        const stockItem = alevinosStock.find(s => s.especie === row.especie);

        // Update Pond Species
        const { data: existingSpec } = await supabase
          .from('pond_species')
          .select('*')
          .eq('estanque_id', pond.id)
          .eq('species_name', row.especie)
          .single();

        if (existingSpec) {
          await supabase.from('pond_species').update({
            current_count: (existingSpec.current_count || 0) + qty,
            current_biomass_kg: (parseFloat(existingSpec.current_biomass_kg) || 0) + bio,
            avg_weight_gr: weight,
            updated_at: new Date().toISOString()
          }).eq('id', existingSpec.id);
        } else {
          await supabase.from('pond_species').insert([{
            estanque_id: pond.id,
            unit_id: activeUnitId,
            species_name: row.especie,
            current_count: qty,
            current_biomass_kg: bio,
            avg_weight_gr: weight
          }]);
        }

        // Subtract from inventory
        if (stockItem) {
          await supabase.from('inventory')
            .update({ current_stock: (stockItem.stock || 0) - qty })
            .eq('id', stockItem.id);
        }
      }

      // 3. Update Pond Global Status
      // Query actual pond_species count AFTER all inserts/updates above,
      // so we correctly identify polyculture even when species were stocked
      // on different dates (each with a single-row form).
      const { data: allPondSpecies } = await supabase
        .from('pond_species')
        .select('id, species_name')
        .eq('estanque_id', pond.id)
        .eq('unit_id', activeUnitId);

      const totalSpeciesInPond = allPondSpecies?.length || 0;
      const finalIsPolyculture = totalSpeciesInPond > 1;
      const finalSpeciesLabel = finalIsPolyculture
        ? 'Policultivo'
        : (allPondSpecies?.[0]?.species_name || rows[0].especie);

      const { error: pondUpdateError } = await supabase
        .from('estanques')
        .update({
          status: 'con_peces',
          is_polyculture: finalIsPolyculture,
          current_species: finalSpeciesLabel,
          current_count: (pond.current_count || 0) + totalQty,
          current_biomass_kg: (parseFloat(pond.current_biomass_kg as string) || 0) + totalBiomasa,
          current_batch_id: batchId
        })
        .eq('id', pond.id);
      
      if (pondUpdateError) throw pondUpdateError;

      return true;
    };

    toast.promise(finalizePromise(), {
      loading: 'Registrando siembra...',
      success: () => {
        router.push('/estanques');
        return '¡Siembra finalizada con éxito!';
      },
      error: (err) => `Error: ${err.message}`
    });
  };
  
  // rows state is declared near the top of the component (before fetchAlevinosStock).

  const addRow = () => {
    const newId = typeof crypto !== 'undefined' ? crypto.randomUUID() : Math.random().toString();
    setRows(prev => [...prev, { id: newId, especie: alevinosStock[0]?.especie || '', cantidad: '', pesoPromedio: '' }]);
  };

  const removeRow = (id: string) => {
    if (rows.length > 1) {
      setRows(prev => prev.filter(row => row.id !== id));
    }
  };

  const updateRow = (id: string, field: keyof SpeciesRow, value: string) => {
    setRows(prevRows => prevRows.map(row => 
      row.id === id ? { ...row, [field]: value } : row
    ));
  };

  const totalBiomasa = useMemo(() => {
    return rows.reduce((acc, row) => {
      const qty = parseFloat(row.cantidad) || 0;
      const weight = parseFloat(row.pesoPromedio) || 0;
      return acc + (qty * weight) / 1000;
    }, 0);
  }, [rows]);

  const [expandedRows, setExpandedRows] = useState<Record<string, boolean>>({});

  const toggleRow = (id: string) => {
    setExpandedRows(prev => ({ ...prev, [id]: !prev[id] }));
  };

  return (
    <div className="animate-fade-in page-container">
      <header style={{ marginBottom: '2rem', display: 'flex', alignItems: 'center', gap: '1rem' }}>
        <Link href="/estanques" style={{ color: 'var(--muted-foreground)', display: 'flex', alignItems: 'center', justifyContent: 'center', width: '40px', height: '40px', borderRadius: '50%', background: 'var(--card)', border: '1px solid var(--border)' }}>
          <ArrowLeft size={20} />
        </Link>
        <div>
          <h1 style={{ fontWeight: 800 }}>Nueva Siembra</h1>
          <p style={{ color: 'var(--muted-foreground)', fontSize: '0.9rem' }}>Vincular stock de alevinos con la producción.</p>
        </div>
      </header>

      <div className="grid-container">
        {/* Global Config Card */}
        <div className="card-premium" style={{ marginBottom: '2rem', padding: '1.5rem' }}>
          <div className="responsive-grid-3" style={{ alignItems: 'flex-end' }}>
            <div className="premium-input-group">
              <label className="premium-label" style={{ display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
                <Waves size={14} /> Estanque de Destino
              </label>
              <div style={{ 
                height: '56px', 
                padding: '0 1.25rem', 
                borderRadius: '12px', 
                background: 'rgba(13, 148, 136, 0.05)', 
                border: '1px solid rgba(13, 148, 136, 0.1)', 
                display: 'flex', 
                alignItems: 'center', 
                gap: '0.75rem',
                fontSize: '1rem',
                fontWeight: 800,
                color: '#0f172a'
              }}>
                <Waves size={20} style={{ color: '#0d9488', opacity: 0.7 }} />
                {selectedPondRecord ? selectedPondRecord.name : 'Cargando...'}
              </div>
            </div>

            <div className="premium-input-group">
              <label className="premium-label" style={{ display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
                <Calendar size={14} /> Fecha de Siembra
              </label>
              <div className="premium-input-wrapper">
                <input 
                  type="date" 
                  value={fecha} 
                  onChange={(e) => setFecha(e.target.value)} 
                  className="premium-input" 
                  style={{ height: '56px' }}
                />
              </div>
            </div>

            <div className="premium-input-group">
              <label className="premium-label" style={{ display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
                <Clock size={14} /> Hora de Registro
              </label>
              <div className="premium-input-wrapper">
                <input 
                  type="time" 
                  value={hora} 
                  onChange={(e) => setHora(e.target.value)} 
                  className="premium-input" 
                  style={{ height: '56px' }}
                />
              </div>
            </div>
          </div>
        </div>

        {/* Dynamic Rows Section */}
        <div className="card-premium" style={{ padding: '2rem' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
            <h2 style={{ fontSize: '1.25rem', fontWeight: 950, display: 'flex', alignItems: 'center', gap: '0.8rem', letterSpacing: '-0.03em' }}>
              <Fish size={28} style={{ color: '#0d9488' }} />
              Especies a Sembrar
            </h2>
            <button 
              onClick={addRow}
              className="btn-primary"
              style={{ padding: '0.6rem 1.25rem', fontSize: '0.9rem' }}
            >
              <Plus size={18} /> Agregar Especie
            </button>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
            {rows.map((row) => {
              const stockAvailable = alevinosStock.find(s => s.especie === row.especie)?.stock || 0;
              const isOverStock = (parseFloat(row.cantidad) || 0) > stockAvailable;
              const isExpanded = expandedRows[row.id];

              return (
                <div 
                  key={row.id}
                  className="glass"
                  style={{ 
                    padding: '1.5rem',
                    borderRadius: '20px',
                    border: isOverStock ? '1.5px solid #ef4444' : '1px solid var(--border)',
                  }}
                >
                  <div className="siembra-row-grid">
                    <div className="premium-input-group">
                      <label className="premium-label">Especie</label>
                      <div className="premium-select-wrapper">
                        <select 
                          value={row.especie}
                          onChange={(e) => updateRow(row.id, 'especie', e.target.value)}
                          className="premium-input"
                        >
                          {alevinosStock.map(s => <option key={s.especie} value={s.especie}>{s.especie} ({s.stock} disp.)</option>)}
                        </select>
                      </div>
                    </div>
                    <div className="premium-input-group">
                      <label className="premium-label">Cantidad</label>
                      <input 
                        type="number" 
                        value={row.cantidad}
                        onChange={(e) => updateRow(row.id, 'cantidad', e.target.value)}
                        placeholder="0"
                        className="premium-input"
                        style={isOverStock ? { borderColor: '#ef4444', background: '#fef2f2' } : {}}
                      />
                    </div>
                    <div className="desktop-only premium-input-group">
                      <label className="premium-label">Peso Promedio (gr)</label>
                      <input 
                        type="number" 
                        value={row.pesoPromedio}
                        onChange={(e) => updateRow(row.id, 'pesoPromedio', e.target.value)}
                        placeholder="0.0"
                        className="premium-input"
                      />
                    </div>
                    <div className="desktop-only premium-input-group">
                      <label className="premium-label">Biomasa Total</label>
                      <div style={{ padding: '0.75rem', borderRadius: '10px', background: 'rgba(13, 148, 136, 0.05)', fontWeight: 900, color: '#0d9488', textAlign: 'center', border: '1px solid rgba(13, 148, 136, 0.1)', height: '56px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                        {((parseFloat(row.cantidad) || 0) * (parseFloat(row.pesoPromedio) || 0) / 1000).toFixed(1)} <span style={{ fontSize: '0.7rem', marginLeft: '4px' }}>KG</span>
                      </div>
                    </div>
                    <div style={{ display: 'flex', gap: '0.5rem', alignItems: 'flex-end' }}>
                      <button 
                        onClick={() => removeRow(row.id)}
                        style={{ width: '42px', height: '42px', background: 'rgba(239, 68, 68, 0.1)', border: 'none', borderRadius: '10px', color: '#ef4444', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', transition: 'all 0.2s ease' }}
                        onMouseEnter={(e) => e.currentTarget.style.background = '#ef4444' + '22'}
                        disabled={rows.length <= 1}
                      >
                        <Trash2 size={20} />
                      </button>
                    </div>

                    {/* Mobile Details Accordion */}
                    <div className={`siembra-detail-mobile ${isExpanded ? 'show' : ''}`}>
                      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem', marginTop: '1rem' }}>
                        <div className="premium-input-group">
                          <label className="premium-label">Peso (gr)</label>
                          <input 
                            type="number" 
                            value={row.pesoPromedio}
                            onChange={(e) => updateRow(row.id, 'pesoPromedio', e.target.value)}
                            className="premium-input"
                          />
                        </div>
                        <div className="premium-input-group">
                          <label className="premium-label">Biomasa (kg)</label>
                          <div style={{ padding: '0.75rem', borderRadius: '10px', background: 'rgba(13, 148, 136, 0.05)', fontWeight: 900, color: '#0d9488', textAlign: 'center', height: '56px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                            {((parseFloat(row.cantidad) || 0) * (parseFloat(row.pesoPromedio) || 0) / 1000).toFixed(1)}
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                  {isOverStock && (
                    <div style={{ fontSize: '0.75rem', color: '#ef4444', fontWeight: 800, display: 'flex', alignItems: 'center', gap: '0.4rem', marginTop: '0.75rem', padding: '0.5rem 0.75rem', background: '#fef2f2', borderRadius: '8px' }}>
                      <AlertCircle size={14} /> Stock insuficiente en inventario.
                    </div>
                  )}
                </div>
              );
            })}
          </div>


          {/* Consolidado */}
          <div style={{ marginTop: '2rem', padding: '1.5rem', background: 'var(--primary)', borderRadius: '16px', color: 'white', display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem' }}>
            <div>
              <div style={{ fontSize: '0.75rem', fontWeight: 600, opacity: 0.8, textTransform: 'uppercase' }}>Total Biomasa</div>
              <div style={{ fontSize: '1.75rem', fontWeight: 900 }}>{totalBiomasa.toFixed(1)} kg</div>
            </div>
            <button 
              onClick={handleFinalize}
              className="btn-primary" 
              style={{ background: 'white', color: 'var(--primary)', padding: '0.8rem 1.5rem', borderRadius: '10px', border: 'none', fontWeight: 800 }}
            >
              Finalizar
            </button>
          </div>
        </div>
        {/* Letrero Informativo Premium */}
        <div style={{ 
          marginTop: '1rem',
          padding: '1.5rem', 
          borderRadius: '20px', 
          background: 'linear-gradient(to right, rgba(37, 99, 235, 0.05), rgba(37, 99, 235, 0.01))', 
          borderLeft: '5px solid var(--primary)',
          display: 'flex', 
          gap: '1.25rem', 
          alignItems: 'center',
          boxShadow: 'var(--shadow-sm)'
        }}>
          <div style={{ 
            width: '45px', 
            height: '45px', 
            borderRadius: '12px', 
            background: 'white', 
            display: 'flex', 
            alignItems: 'center', 
            justifyContent: 'center',
            color: 'var(--primary)',
            boxShadow: '0 4px 6px -1px rgba(0,0,0,0.05)'
          }}>
            <AlertCircle size={28} />
          </div>
          <div style={{ flex: 1 }}>
            <h4 style={{ fontWeight: 800, fontSize: '1rem', marginBottom: '0.25rem', color: 'var(--primary)' }}>
              ⚠️ Recomendación Técnica Importante
            </h4>
            <p style={{ fontSize: '0.95rem', color: 'var(--muted-foreground)', lineHeight: 1.5 }}>
              Para asegurar la supervivencia de los peces, es fundamental realizar la <strong>toma de parámetros fisicoquímicos</strong> (Oxígeno, pH, Temperatura) y registrarlos en el <Link href="/registros" style={{ color: 'var(--primary)', fontWeight: 700, textDecoration: 'underline' }}>módulo de registros</Link> antes de iniciar la siembra.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
