'use client';

import { useState, useMemo, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  Plus, 
  Trash2, 
  Calendar, 
  Clock, 
  Waves, 
  Scale, 
  Fish, 
  AlertCircle,
  ArrowLeft,
  Package
} from 'lucide-react';
import Link from 'next/link';
import { useSearchParams } from 'next/navigation';

import { supabase } from '@/lib/supabase';

interface SpeciesRow {
  id: string;
  especie: string;
  cantidad: string;
  pesoPromedio: string;
}

export default function SiembraPage() {
  const searchParams = useSearchParams();
  const estanqueParam = searchParams.get('estanque');

  const [alevinosStock, setAlevinosStock] = useState<any[]>([]);
  const [fecha, setFecha] = useState(new Date().toISOString().split('T')[0]);
  const [hora, setHora] = useState(new Date().toTimeString().slice(0, 5));
  const [estanque, setEstanque] = useState(estanqueParam || '');

  const [estanquesList, setEstanquesList] = useState<any[]>([]);

  useEffect(() => {
    fetchAlevinosStock();
    fetchEstanques();
  }, []);

  const fetchAlevinosStock = async () => {
    const { data, error } = await supabase
      .from('inventory')
      .select('*')
      .eq('category', 'alevinos');
    
    if (error) console.error('Error fetching alevinos:', error);
    else {
      const formatted = (data || []).map(i => ({
        ...i,
        especie: i.name,
        stock: parseFloat(i.current_stock) || 0,
        unidad: i.unit || 'uds'
      }));
      setAlevinosStock(formatted);
      
      // Auto-set the first row species if it's still the default and we have stock
      if (formatted.length > 0 && rows.length === 1 && (rows[0].especie === 'Tilapia Roja' || !rows[0].especie)) {
        setRows([{ ...rows[0], especie: formatted[0].especie }]);
      }
    }
  };

  const fetchEstanques = async () => {
    const { data, error } = await supabase.from('estanques').select('*');
    if (error) console.error('Error fetching estanques:', error);
    else setEstanquesList(data || []);
  };

  const selectedPondRecord = useMemo(() => {
    return estanquesList.find(p => p.id === estanque);
  }, [estanque, estanquesList]);

  const handleFinalize = async () => {
    if (!estanque) {
      alert("Por favor seleccione un estanque.");
      return;
    }

    const pond = selectedPondRecord;
    if (!pond) {
      alert("El estanque seleccionado no existe.");
      return;
    }

    // Get active unit
    let activeUnitId = localStorage.getItem('active_unit_id');
    if (!activeUnitId) {
      const { data: { user } } = await supabase.auth.getUser();
      if (user) {
        const { data: uu } = await supabase.from('user_units').select('unit_id').eq('user_id', user.id).single();
        if (uu) { activeUnitId = uu.unit_id; localStorage.setItem('active_unit_id', uu.unit_id); }
      }
    }
    if (!activeUnitId) { alert("Error: No se detectó unidad vinculada."); return; }

    // 2. Create Seeding Header with Batch ID
    const batchId = `LOTE-${new Date().toISOString().slice(2,10).replace(/-/g,'')}-${pond.name.replace(/\s+/g,'').toUpperCase()}`;
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
        batch_id: batchId // Trazabilidad
      }])
      .select();

    if (siembraError || !siembraData) {
      alert("Error al registrar siembra: " + (siembraError?.message || "No se recibieron datos"));
      return;
    }

    const siembraId = siembraData[0].id;

    // 3. Register Details and Update Inventory
    const isPolyculture = rows.length > 1;
    
    for (const row of rows) {
      const qty = parseInt(row.cantidad) || 0;
      const weight = parseFloat(row.pesoPromedio) || 0;
      const bio = (qty * weight) / 1000;
      const stockItem = alevinosStock.find(s => s.especie === row.especie);

      // A. Insert siembra detail with inventory reference
      await supabase.from('siembra_details').insert([{
        siembra_id: siembraId,
        species_name: row.especie,
        quantity: qty,
        avg_weight_gr: weight,
        biomass_kg: bio,
        inventory_item_id: stockItem?.id // Referencia para restauración
      }]);

      // B. Update/Insert Pond Species Inventory
      // First check if it already exists (in case of supplemental seeding)
      const { data: existingSpec } = await supabase
        .from('pond_species')
        .select('*')
        .eq('estanque_id', pond.id)
        .eq('species_name', row.especie)
        .single();

      if (existingSpec) {
        await supabase.from('pond_species').update({
          current_count: existingSpec.current_count + qty,
          current_biomass_kg: parseFloat(existingSpec.current_biomass_kg) + bio,
          avg_weight_gr: weight, // Updated to latest seeding weight
          updated_at: new Date().toISOString()
        }).eq('id', existingSpec.id);
      } else {
        await supabase.from('pond_species').insert([{
          estanque_id: pond.id,
          species_name: row.especie,
          current_count: qty,
          current_biomass_kg: bio,
          avg_weight_gr: weight
        }]);
      }

      // C. Subtract from inventory
      const stockItem = alevinosStock.find(s => s.especie === row.especie);
      if (stockItem) {
        await supabase
          .from('inventory')
          .update({ current_stock: stockItem.stock - qty })
          .eq('id', stockItem.id);
      }
    }

    // 4. Update Pond Global Status
    await supabase
      .from('estanques')
      .update({
        status: 'con_peces',
        is_polyculture: isPolyculture,
        current_species: isPolyculture ? 'Policultivo' : rows[0].especie,
        current_count: (pond.current_count || 0) + totalQty,
        current_biomass_kg: (parseFloat(pond.current_biomass_kg) || 0) + totalBiomasa,
        current_batch_id: batchId
      })
      .eq('id', pond.id);

    alert("¡Siembra finalizada con éxito! El estanque ahora está activo y los inventarios actualizados.");
    window.location.href = '/estanques';
  };
  
  const [rows, setRows] = useState<SpeciesRow[]>([
    { id: '1', especie: '', cantidad: '', pesoPromedio: '' }
  ]);

  const addRow = () => {
    setRows([...rows, { id: Math.random().toString(), especie: 'Tilapia Roja', cantidad: '', pesoPromedio: '' }]);
  };

  const removeRow = (id: string) => {
    if (rows.length > 1) {
      setRows(rows.filter(row => row.id !== id));
    }
  };

  const updateRow = (id: string, field: keyof SpeciesRow, value: string) => {
    setRows(rows.map(row => row.id === id ? { ...row, [field]: value } : row));
  };

  const totalBiomasa = useMemo(() => {
    return rows.reduce((acc, row) => {
      const qty = parseFloat(row.cantidad) || 0;
      const weight = parseFloat(row.pesoPromedio) || 0;
      return acc + (qty * weight) / 1000;
    }, 0);
  }, [rows]);

  return (
    <div className="animate-fade-in" style={{ maxWidth: '1000px', margin: '0 auto', paddingBottom: '4rem' }}>
      <header style={{ marginBottom: '2rem', display: 'flex', alignItems: 'center', gap: '1rem' }}>
        <Link href="/estanques" style={{ color: 'var(--muted-foreground)', display: 'flex', alignItems: 'center', justifyContent: 'center', width: '40px', height: '40px', borderRadius: '50%', background: 'var(--card)', border: '1px solid var(--border)' }}>
          <ArrowLeft size={20} />
        </Link>
        <div>
          <h1 style={{ fontSize: '1.875rem', fontWeight: 700 }}>Nueva Siembra</h1>
          <p style={{ color: 'var(--muted-foreground)' }}>Vincular stock de alevinos del almacén con la producción.</p>
        </div>
      </header>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr', gap: '2rem' }}>
        {/* Global Config Card */}
        <div className="card-premium" style={{ padding: '2rem' }}>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '1.5rem', alignItems: 'center' }}>
            <div>
              <div style={{ fontSize: '0.75rem', fontWeight: 700, marginBottom: '0.5rem', textTransform: 'uppercase', color: 'var(--muted-foreground)' }}>Estanque Destino</div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', padding: '0.75rem', background: 'rgba(37, 99, 235, 0.05)', borderRadius: '8px', border: '1px solid rgba(37, 99, 235, 0.1)' }}>
                <Waves size={20} style={{ color: 'var(--primary)' }} />
                <span style={{ fontSize: '1.1rem', fontWeight: 800, color: 'var(--primary)' }}>
                  {selectedPondRecord ? selectedPondRecord.name : 'Estanque No Seleccionado'}
                </span>
              </div>
            </div>
            <div>
              <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 700, marginBottom: '0.5rem', textTransform: 'uppercase', color: 'var(--muted-foreground)' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                  <Calendar size={14} /> Fecha
                </div>
              </label>
              <input 
                type="date" 
                value={fecha}
                onChange={(e) => setFecha(e.target.value)}
                style={{ width: '100%', padding: '0.75rem', borderRadius: '8px', border: '1px solid var(--border)', background: 'var(--secondary)', outline: 'none' }} 
              />
            </div>
            <div>
              <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 700, marginBottom: '0.5rem', textTransform: 'uppercase', color: 'var(--muted-foreground)' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                  <Clock size={14} /> Hora
                </div>
              </label>
              <input 
                type="time" 
                value={hora}
                onChange={(e) => setHora(e.target.value)}
                style={{ width: '100%', padding: '0.75rem', borderRadius: '8px', border: '1px solid var(--border)', background: 'var(--secondary)', outline: 'none' }} 
              />
            </div>
          </div>
        </div>

        {/* Dynamic Rows Section */}
        <div className="card-premium" style={{ padding: '2rem' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
            <h2 style={{ fontSize: '1.25rem', fontWeight: 700, display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
              <Fish size={24} style={{ color: 'var(--primary)' }} />
              Detalle de Especies
            </h2>
            <button 
              onClick={addRow}
              style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', padding: '0.5rem 1rem', borderRadius: '8px', border: '1px solid var(--primary)', color: 'var(--primary)', background: 'transparent', fontWeight: 600, cursor: 'pointer' }}
            >
              <Plus size={18} />
              Añadir Especie
            </button>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
            <AnimatePresence mode="popLayout">
              {rows.map((row) => {
                const stockAvailable = alevinosStock.find(s => s.especie === row.especie)?.stock || 0;
                const isOverStock = (parseFloat(row.cantidad) || 0) > stockAvailable;

                return (
                  <motion.div 
                    key={row.id}
                    initial={{ opacity: 0, y: 10 }}
                    animate={{ opacity: 1, y: 0 }}
                    exit={{ opacity: 0, scale: 0.95 }}
                    style={{ 
                      display: 'grid', 
                      gridTemplateColumns: '2fr 1fr 1fr 1fr 40px', 
                      gap: '1rem', 
                      alignItems: 'flex-end',
                      padding: '1.5rem',
                      background: 'var(--card)',
                      borderRadius: '16px',
                      border: '1px solid var(--border)',
                      boxShadow: 'var(--shadow-sm)'
                    }}
                  >
                    <div>
                      <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '0.5rem' }}>
                        <label style={{ fontSize: '0.7rem', fontWeight: 700, color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Especie en Almacén</label>
                        <span style={{ fontSize: '0.7rem', fontWeight: 700, color: stockAvailable < 1000 ? '#ef4444' : '#10b981' }}>
                          Stock: {stockAvailable.toLocaleString()} uds
                        </span>
                      </div>
                      <select 
                        value={row.especie}
                        onChange={(e) => updateRow(row.id, 'especie', e.target.value)}
                        style={{ width: '100%', padding: '0.75rem', borderRadius: '8px', border: '1px solid var(--border)', background: 'var(--secondary)', outline: 'none', fontWeight: 600 }}
                      >
                        {alevinosStock.map(s => <option key={s.especie} value={s.especie}>{s.especie}</option>)}
                      </select>
                    </div>
                    <div>
                      <label style={{ fontSize: '0.7rem', fontWeight: 700, color: 'var(--muted-foreground)', marginBottom: '0.5rem', textTransform: 'uppercase', display: 'block' }}>Cantidad</label>
                      <input 
                        type="number" 
                        value={row.cantidad}
                        onChange={(e) => updateRow(row.id, 'cantidad', e.target.value)}
                        placeholder="0"
                        style={{ 
                          width: '100%', 
                          padding: '0.75rem', 
                          borderRadius: '8px', 
                          border: '1px solid', 
                          borderColor: isOverStock ? '#ef4444' : 'var(--border)',
                          background: 'var(--secondary)', 
                          outline: 'none',
                          fontWeight: 700
                        }}
                      />
                    </div>
                    <div>
                      <label style={{ fontSize: '0.7rem', fontWeight: 700, color: 'var(--muted-foreground)', marginBottom: '0.5rem', textTransform: 'uppercase', display: 'block' }}>Peso (gr)</label>
                      <input 
                        type="number" 
                        value={row.pesoPromedio}
                        onChange={(e) => updateRow(row.id, 'pesoPromedio', e.target.value)}
                        placeholder="0.0"
                        style={{ width: '100%', padding: '0.75rem', borderRadius: '8px', border: '1px solid var(--border)', background: 'var(--secondary)', outline: 'none' }}
                      />
                    </div>
                    <div>
                      <label style={{ fontSize: '0.7rem', fontWeight: 700, color: 'var(--muted-foreground)', marginBottom: '0.5rem', textTransform: 'uppercase', display: 'block' }}>Biomasa (kg)</label>
                      <div style={{ padding: '0.75rem', borderRadius: '8px', background: 'rgba(37, 99, 235, 0.05)', border: '1px solid rgba(37, 99, 235, 0.1)', fontWeight: 800, color: 'var(--primary)', textAlign: 'center' }}>
                        {((parseFloat(row.cantidad) || 0) * (parseFloat(row.pesoPromedio) || 0) / 1000).toFixed(2)}
                      </div>
                    </div>
                    <button 
                      onClick={() => removeRow(row.id)}
                      style={{ background: 'transparent', border: 'none', color: '#ef4444', cursor: 'pointer', opacity: rows.length > 1 ? 0.6 : 0.2, marginBottom: '10px' }}
                      disabled={rows.length <= 1}
                    >
                      <Trash2 size={20} />
                    </button>
                    {isOverStock && (
                      <div style={{ gridColumn: 'span 4', fontSize: '0.75rem', color: '#ef4444', fontWeight: 600, display: 'flex', alignItems: 'center', gap: '0.4rem', marginTop: '-0.5rem' }}>
                        <AlertCircle size={14} /> Stock insuficiente en almacén para esta cantidad.
                      </div>
                    )}
                  </motion.div>
                );
              })}
            </AnimatePresence>
          </div>

          {/* Total Summary */}
          <div style={{ marginTop: '2.5rem', padding: '2rem', background: 'linear-gradient(135deg, var(--primary) 0%, #1e40af 100%)', borderRadius: '24px', color: 'white', display: 'flex', justifyContent: 'space-between', alignItems: 'center', boxShadow: '0 20px 25px -5px rgba(37, 99, 235, 0.2)' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '1.25rem' }}>
              <div style={{ width: '56px', height: '56px', borderRadius: '16px', background: 'rgba(255, 255, 255, 0.2)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <Scale size={28} />
              </div>
              <div>
                <div style={{ fontSize: '0.85rem', fontWeight: 600, opacity: 0.9, textTransform: 'uppercase', letterSpacing: '0.05em' }}>Biomasa Consolidada</div>
                <div style={{ fontSize: '2rem', fontWeight: 800 }}>{totalBiomasa.toFixed(2)} kg</div>
              </div>
            </div>
            <button 
              onClick={handleFinalize}
              className="btn-primary" 
              style={{ background: 'white', color: 'var(--primary)', padding: '1rem 2.5rem', borderRadius: '50px', border: 'none', fontWeight: 800, fontSize: '1rem' }}
            >
              Finalizar Registro
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
