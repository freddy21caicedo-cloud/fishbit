'use client';

import { useEffect, useState, useMemo } from 'react';
import { useSearchParams } from 'next/navigation';
import { supabase } from '@/lib/supabase';
import { toast } from 'react-hot-toast';
import { 
  Plus, 
  CheckCircle, 
  Clock, 
  X, 
  TrendingUp, 
  Scale, 
  DollarSign, 
  AlertTriangle, 
  MessageSquare,
  Printer,
  ChevronRight,
  Sparkles,
  Info
} from 'lucide-react';

const cop = (v: number) => v.toLocaleString('es-CO', { style: 'currency', currency: 'COP', maximumFractionDigits: 0 });

const PRECIOS_SUGERIDOS: Record<string, Record<string, number>> = {
  'Tilapia Roja': { vivo: 8500, eviscerado_media: 10500, eviscerado_completo: 11000 },
  'Tilapia Plateada': { vivo: 7800, eviscerado_media: 9800, eviscerado_completo: 10300 },
  'Trucha': { vivo: 13000, eviscerado_media: 16000, eviscerado_completo: 17000 },
  'Cachama': { vivo: 7000, eviscerado_media: 8800, eviscerado_completo: 9300 },
  'Camarón': { vivo: 18000, eviscerado_media: 21000, eviscerado_completo: 22000 },
  'default': { vivo: 8000, eviscerado_media: 10000, eviscerado_completo: 10500 }
};

interface Venta {
  id: string;
  fecha: string;
  cliente_id: string | null;
  estanque_id: string;
  species_name: string;
  tipo_venta: string;
  cantidad_kg: number;
  precio_kg: number;
  total: number;
  estado_pago: 'pendiente' | 'pagado';
  notas?: string;
  clientes?: { name: string; phone?: string };
  estanques?: { name: string };
}

export function ModuloVentas({ unitId }: { unitId: string }) {
  const [ponds, setPonds] = useState<any[]>([]);
  const [clientes, setClientes] = useState<any[]>([]);
  const [ventas, setVentas] = useState<Venta[]>([]);
  
  // Modales
  const [showClienteModal, setShowClienteModal] = useState(false);
  const [showInvoiceModal, setShowInvoiceModal] = useState(false);
  const [selectedVentaForInvoice, setSelectedVentaForInvoice] = useState<Venta | null>(null);
  
  // Form Cliente
  const [newClienteName, setNewClienteName] = useState('');
  const [newClientePhone, setNewClientePhone] = useState('');

  // Form Principal
  const [form, setForm] = useState({ 
    cliente_id: '', 
    estanque_id: '', 
    species_name: '', 
    tipo_venta: 'vivo', 
    cantidad_kg: '', 
    peso_promedio_gr: '', 
    precio_kg: '', 
    fecha: new Date().toISOString().split('T')[0], 
    notas: '' 
  });
  
  const [costoProduccionKg, setCostoProduccionKg] = useState('5500'); // Costo estimado de producción base COP/kg
  const [pondSpecies, setPondSpecies] = useState<string[]>([]);
  const [pondBiomasa, setPondBiomasa] = useState(0);
  const searchParams = useSearchParams();

  useEffect(() => {
    if (!unitId) return;
    fetchAll();
  }, [unitId]);

  // Autocompletar precio sugerido dinámicamente
  useEffect(() => {
    if (!form.species_name) return;
    const catalogo = PRECIOS_SUGERIDOS[form.species_name] || PRECIOS_SUGERIDOS['default'];
    const precioSugerido = catalogo[form.tipo_venta] || catalogo['vivo'];
    setForm(f => ({ ...f, precio_kg: precioSugerido.toString() }));
  }, [form.species_name, form.tipo_venta]);

  const handlePondChange = async (pondId: string, currentPonds = ponds) => {
    setForm(f => ({ ...f, estanque_id: pondId, species_name: '' }));
    const pond = currentPonds.find(p => p.id === pondId);
    if (!pond) return;
    setPondBiomasa(parseFloat(pond.current_biomass_kg || 0));
    if (pond.is_polyculture) {
      const { data } = await supabase.from('pond_species').select('species_name').eq('estanque_id', pondId);
      setPondSpecies((data || []).map((s: any) => s.species_name));
    } else {
      setPondSpecies(pond.current_species ? [pond.current_species] : []);
    }
  };

  const fetchAll = async () => {
    const [p, c, v] = await Promise.all([
      supabase.from('estanques').select('id, name, current_biomass_kg, current_species, is_polyculture, current_count').eq('unit_id', unitId).eq('status', 'con_peces'),
      supabase.from('clientes').select('*').eq('unit_id', unitId).order('name'),
      supabase.from('ventas').select('*, clientes(name, phone), estanques(name)').eq('unit_id', unitId).order('fecha', { ascending: false }).limit(100),
    ]);
    setPonds(p.data || []);
    setClientes(c.data || []);
    setVentas(v.data || []);

    const estanqueParam = searchParams.get('estanque');
    if (estanqueParam && (p.data || []).find(pd => pd.id === estanqueParam)) {
      handlePondChange(estanqueParam, p.data || []);
    }
  };

  // KPIs Calculados reactivamente
  const metrics = useMemo(() => {
    let totalIngresos = 0;
    let totalKg = 0;
    let pendienteCobro = 0;
    
    ventas.forEach(v => {
      totalIngresos += parseFloat(v.total as any || 0);
      totalKg += parseFloat(v.cantidad_kg as any || 0);
      if (v.estado_pago === 'pendiente') {
        pendienteCobro += parseFloat(v.total as any || 0);
      }
    });

    const precioPromedio = totalKg > 0 ? totalIngresos / totalKg : 0;

    return {
      totalIngresos,
      totalKg,
      pendienteCobro,
      precioPromedio
    };
  }, [ventas]);

  // Cálculos de Margen en el Formulario
  const marginCalculation = useMemo(() => {
    if (!form.cantidad_kg || !form.precio_kg) return null;
    const kg = parseFloat(form.cantidad_kg);
    const precio = parseFloat(form.precio_kg);
    const costo = parseFloat(costoProduccionKg) || 0;
    
    const ingresoTotal = kg * precio;
    const costoTotal = kg * costo;
    const margenNeto = ingresoTotal - costoTotal;
    const porcentajeMargen = precio > 0 ? ((precio - costo) / precio) * 100 : 0;

    return {
      ingresoTotal,
      costoTotal,
      margenNeto,
      porcentajeMargen
    };
  }, [form.cantidad_kg, form.precio_kg, costoProduccionKg]);

  const saveVenta = async () => {
    const { cliente_id, estanque_id, species_name, tipo_venta, cantidad_kg, peso_promedio_gr, precio_kg, fecha } = form;
    if (!estanque_id || !species_name || !cantidad_kg || !precio_kg || !peso_promedio_gr) return toast.error('Completa todos los campos requeridos');
    const kgNum = parseFloat(cantidad_kg);
    const pesoPromedioNum = parseFloat(peso_promedio_gr);
    const cantidadPeces = Math.round((kgNum * 1000) / pesoPromedioNum);

    if (kgNum > pondBiomasa) {
      toast('⚠️ Cantidad supera la biomasa registrada. Se ajustará el inventario.', { icon: '⚠️', duration: 4000 });
    }

    const margenPorc = marginCalculation ? marginCalculation.porcentajeMargen.toFixed(1) : '0';
    const notasAmpliadas = form.notas 
      ? `${form.notas} | Proyección: ~${cantidadPeces} peces (${pesoPromedioNum}g) | Margen Est: ${margenPorc}%` 
      : `Proyección: ~${cantidadPeces} peces (${pesoPromedioNum}g) | Margen Est: ${margenPorc}%`;

    const { error } = await supabase.from('ventas').insert([{ 
      unit_id: unitId, 
      cliente_id: cliente_id || null, 
      estanque_id, 
      species_name, 
      tipo_venta, 
      cantidad_kg: kgNum, 
      precio_kg: parseFloat(precio_kg), 
      fecha, 
      notas: notasAmpliadas 
    }]);
    if (error) return toast.error('Error: ' + error.message);

    // Update pond biomass & count
    const pond = ponds.find(p => p.id === estanque_id);
    const newBiomasa = Math.max(0, pondBiomasa - kgNum);
    const newCount = Math.max(0, (pond?.current_count || 0) - cantidadPeces);

    await supabase.from('estanques').update({ current_biomass_kg: newBiomasa, current_count: newCount }).eq('id', estanque_id);

    // Update pond_species
    const { data: speciesData } = await supabase.from('pond_species').select('id, current_count, current_biomass_kg').eq('estanque_id', estanque_id).eq('species_name', species_name).single();
    if (speciesData) {
      const newSpeciesCount = Math.max(0, (speciesData.current_count || 0) - cantidadPeces);
      const newSpeciesBiomasa = Math.max(0, parseFloat(speciesData.current_biomass_kg || '0') - kgNum);
      if (newSpeciesCount <= 0) {
        await supabase.from('pond_species').delete().eq('id', speciesData.id);
      } else {
        await supabase.from('pond_species').update({ current_count: newSpeciesCount, current_biomass_kg: newSpeciesBiomasa }).eq('id', speciesData.id);
      }
    }

    toast.success(`Venta registrada. Se descontaron ~${cantidadPeces} peces.`);
    setForm({ cliente_id: '', estanque_id: '', species_name: '', tipo_venta: 'vivo', cantidad_kg: '', peso_promedio_gr: '', precio_kg: '', fecha: new Date().toISOString().split('T')[0], notas: '' });
    setPondSpecies([]); setPondBiomasa(0);
    fetchAll();
  };

  const togglePago = async (id: string, current: string) => {
    const next = current === 'pendiente' ? 'pagado' : 'pendiente';
    await supabase.from('ventas').update({ estado_pago: next }).eq('id', id);
    fetchAll();
    toast.success(`Estado de pago actualizado a: ${next === 'pagado' ? 'Pagado' : 'Pendiente'}`);
  };

  const saveCliente = async () => {
    if (!newClienteName) return;
    const { data, error } = await supabase.from('clientes').insert([{ unit_id: unitId, name: newClienteName, phone: newClientePhone }]).select().single();
    if (error) return toast.error('Error al guardar cliente: ' + error.message);
    if (data) { 
      setClientes(c => [...c, data]); 
      setForm(f => ({ ...f, cliente_id: data.id })); 
      toast.success('Cliente registrado exitosamente');
    }
    setShowClienteModal(false); setNewClienteName(''); setNewClientePhone('');
  };

  // Crear link de cobranza personalizado
  const handleWhatsAppReminder = (v: Venta) => {
    const rawPhone = v.clientes?.phone;
    if (!rawPhone) {
      toast.error('Este cliente no tiene un teléfono registrado. Edita el cliente en su panel o agrega uno con celular para enviar cobranza.');
      return;
    }
    const cleanPhone = rawPhone.replace(/\D/g, '');
    const message = `Hola *${v.clientes?.name}*, espero te encuentres muy bien. Te escribimos de la Granja Acuícola para recordarte amablemente el saldo pendiente de *${cop(v.total)}* correspondiente a la venta de *${v.cantidad_kg.toLocaleString('es-CO')} kg* de *${v.species_name}* realizada el *${v.fecha}*.\n\nAgradecemos tu colaboración con la confirmación de pago. ¡Feliz día!`;
    const url = `https://wa.me/${cleanPhone}?text=${encodeURIComponent(message)}`;
    window.open(url, '_blank');
  };

  const handlePrintRemision = (v: Venta) => {
    setSelectedVentaForInvoice(v);
    setShowInvoiceModal(true);
  };

  const tipoLabels: Record<string, string> = { 
    vivo: 'Vivo', 
    eviscerado_media: 'Eviscr. Media tripa', 
    eviscerado_completo: 'Eviscr. Completo' 
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
      
      {/* 1. KPIs de Ventas Avanzadas */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '1.25rem' }}>
        
        {/* Total Ingresos */}
        <div className="card-premium" style={{ 
          padding: '1.5rem', 
          background: 'linear-gradient(135deg, rgba(5, 150, 105, 0.08), rgba(16, 185, 129, 0.02))',
          border: '1px solid rgba(16, 185, 129, 0.15)',
          display: 'flex',
          alignItems: 'center',
          gap: '1rem'
        }}>
          <div style={{ width: '48px', height: '48px', borderRadius: '12px', background: 'rgba(16, 185, 129, 0.1)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#10b981' }}>
            <DollarSign size={24} />
          </div>
          <div>
            <span style={{ fontSize: '0.75rem', fontWeight: 800, color: 'var(--muted-foreground)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Ingresos Registrados</span>
            <h3 style={{ fontSize: '1.5rem', fontWeight: 900, color: '#10b981', marginTop: '0.1rem' }}>{cop(metrics.totalIngresos)}</h3>
          </div>
        </div>

        {/* Volumen total */}
        <div className="card-premium" style={{ 
          padding: '1.5rem', 
          background: 'linear-gradient(135deg, rgba(6, 182, 212, 0.08), rgba(6, 182, 212, 0.02))',
          border: '1px solid rgba(6, 182, 212, 0.15)',
          display: 'flex',
          alignItems: 'center',
          gap: '1rem'
        }}>
          <div style={{ width: '48px', height: '48px', borderRadius: '12px', background: 'rgba(6, 182, 212, 0.1)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#06b6d4' }}>
            <Scale size={24} />
          </div>
          <div>
            <span style={{ fontSize: '0.75rem', fontWeight: 800, color: 'var(--muted-foreground)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Biomasa Comercializada</span>
            <h3 style={{ fontSize: '1.5rem', fontWeight: 900, color: '#06b6d4', marginTop: '0.1rem' }}>{metrics.totalKg.toLocaleString('es-CO')} kg</h3>
          </div>
        </div>

        {/* Cuentas por Cobrar */}
        <div className="card-premium" style={{ 
          padding: '1.5rem', 
          background: 'linear-gradient(135deg, rgba(245, 158, 11, 0.08), rgba(245, 158, 11, 0.02))',
          border: '1px solid rgba(245, 158, 11, 0.15)',
          display: 'flex',
          alignItems: 'center',
          gap: '1rem'
        }}>
          <div style={{ width: '48px', height: '48px', borderRadius: '12px', background: 'rgba(245, 158, 11, 0.1)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#f59e0b' }}>
            <Clock size={24} />
          </div>
          <div>
            <span style={{ fontSize: '0.75rem', fontWeight: 800, color: 'var(--muted-foreground)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Cartera Pendiente</span>
            <h3 style={{ fontSize: '1.5rem', fontWeight: 900, color: '#f59e0b', marginTop: '0.1rem' }}>{cop(metrics.pendienteCobro)}</h3>
          </div>
        </div>

        {/* Precio Promedio */}
        <div className="card-premium" style={{ 
          padding: '1.5rem', 
          background: 'linear-gradient(135deg, rgba(139, 92, 246, 0.08), rgba(139, 92, 246, 0.02))',
          border: '1px solid rgba(139, 92, 246, 0.15)',
          display: 'flex',
          alignItems: 'center',
          gap: '1rem'
        }}>
          <div style={{ width: '48px', height: '48px', borderRadius: '12px', background: 'rgba(139, 92, 246, 0.1)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#8b5cf6' }}>
            <TrendingUp size={24} />
          </div>
          <div>
            <span style={{ fontSize: '0.75rem', fontWeight: 800, color: 'var(--muted-foreground)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Precio Promedio / kg</span>
            <h3 style={{ fontSize: '1.5rem', fontWeight: 900, color: '#8b5cf6', marginTop: '0.1rem' }}>{cop(metrics.precioPromedio)}</h3>
          </div>
        </div>

      </div>

      {/* 2. Formulario y Gestión */}
      <div className="card-premium" style={{ padding: '2rem' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '1.5rem' }}>
          <Sparkles style={{ color: 'var(--primary)' }} size={20} />
          <h3 style={{ fontWeight: 800, fontSize: '1.1rem' }}>Registrar Nueva Transacción de Venta</h3>
        </div>
        
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '1.25rem' }}>
          
          {/* Cliente */}
          <div className="premium-input-group">
            <label className="premium-label">Cliente Comprador</label>
            <div style={{ display: 'flex', gap: '0.5rem' }}>
              <select value={form.cliente_id} onChange={e => setForm(f => ({ ...f, cliente_id: e.target.value }))} className="premium-input" style={{ flex: 1 }}>
                <option value="">Consumidor Final (Sin registrar)</option>
                {clientes.map(c => <option key={c.id} value={c.id}>{c.name}</option>)}
              </select>
              <button onClick={() => setShowClienteModal(true)} style={{ padding: '0 0.85rem', background: 'var(--primary)', color: 'white', border: 'none', borderRadius: '10px', cursor: 'pointer', fontWeight: 900, fontSize: '1.1rem', display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 4px 12px rgba(13,148,136,0.2)' }}>+</button>
            </div>
          </div>

          {/* Fecha */}
          <div className="premium-input-group">
            <label className="premium-label">Fecha de Entrega</label>
            <input type="date" value={form.fecha} onChange={e => setForm(f => ({ ...f, fecha: e.target.value }))} className="premium-input" />
          </div>

          {/* Estanque */}
          <div className="premium-input-group">
            <label className="premium-label">Estanque de Cosecha</label>
            <select value={form.estanque_id} onChange={e => handlePondChange(e.target.value)} className="premium-input">
              <option value="">Seleccionar estanque...</option>
              {ponds.map(p => <option key={p.id} value={p.id}>{p.name} ({parseFloat(p.current_biomass_kg || 0).toFixed(1)} kg disp.)</option>)}
            </select>
          </div>

          {/* Especie */}
          <div className="premium-input-group">
            <label className="premium-label">Especie Cosechada</label>
            <select value={form.species_name} onChange={e => setForm(f => ({ ...f, species_name: e.target.value }))} className="premium-input">
              <option value="">Seleccionar especie...</option>
              {pondSpecies.map(s => <option key={s} value={s}>{s}</option>)}
            </select>
          </div>

          {/* Tipo de Venta */}
          <div className="premium-input-group">
            <label className="premium-label">Procesamiento / Tipo</label>
            <select value={form.tipo_venta} onChange={e => setForm(f => ({ ...f, tipo_venta: e.target.value }))} className="premium-input">
              {Object.entries(tipoLabels).map(([k, v]) => <option key={k} value={k}>{v}</option>)}
            </select>
          </div>

          {/* Cantidad kg */}
          <div className="premium-input-group">
            <label className="premium-label">Cantidad Cosechada (kg)</label>
            <input type="number" step="any" value={form.cantidad_kg} onChange={e => setForm(f => ({ ...f, cantidad_kg: e.target.value }))} className="premium-input"
              style={parseFloat(form.cantidad_kg) > pondBiomasa && pondBiomasa > 0 ? { borderColor: '#f59e0b', boxShadow: '0 0 0 1px rgba(245,158,11,0.2)' } : {}} placeholder="0.0" />
            {parseFloat(form.cantidad_kg) > pondBiomasa && pondBiomasa > 0 && (
              <div style={{ fontSize: '0.72rem', color: '#f59e0b', fontWeight: 800, marginTop: '4px', display: 'flex', alignItems: 'center', gap: '2px' }}>
                <AlertTriangle size={12} /> Supera la biomasa actual ({pondBiomasa.toFixed(1)} kg)
              </div>
            )}
          </div>

          {/* Peso Promedio */}
          <div className="premium-input-group">
            <label className="premium-label">Peso Promedio (g) por pez</label>
            <input type="number" value={form.peso_promedio_gr} onChange={e => setForm(f => ({ ...f, peso_promedio_gr: e.target.value }))} className="premium-input" placeholder="Ej: 500" />
            {form.cantidad_kg && form.peso_promedio_gr && (
              <div style={{ fontSize: '0.72rem', color: 'var(--primary)', fontWeight: 800, marginTop: '4px', display: 'flex', alignItems: 'center', gap: '3px' }}>
                <Sparkles size={11} /> Proyección: ~{Math.round((parseFloat(form.cantidad_kg) * 1000) / parseFloat(form.peso_promedio_gr))} peces a descontar
              </div>
            )}
          </div>

          {/* Precio de Venta */}
          <div className="premium-input-group">
            <label className="premium-label" style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
              Precio de Venta/kg (COP) 
              {form.species_name && (
                <span style={{ fontSize: '0.65rem', background: 'rgba(13,148,136,0.1)', color: 'var(--primary)', padding: '1px 5px', borderRadius: '4px' }}>Sugerido</span>
              )}
            </label>
            <input type="number" value={form.precio_kg} onChange={e => setForm(f => ({ ...f, precio_kg: e.target.value }))} className="premium-input" placeholder="0" />
          </div>

          {/* Costo de Producción (Simulación de Margen) */}
          <div className="premium-input-group">
            <label className="premium-label" style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
              Costo de Prod. estimado/kg
              <span style={{ cursor: 'pointer', color: 'var(--primary)' }} title="Configura tu costo real de concentrado, alevines y mano de obra por kilo producido para simular tu rentabilidad."><Info size={11} /></span>
            </label>
            <input type="number" value={costoProduccionKg} onChange={e => setCostoProduccionKg(e.target.value)} className="premium-input" placeholder="5500" />
          </div>

          {/* Notas */}
          <div className="premium-input-group" style={{ gridColumn: 'span 2' }}>
            <label className="premium-label">Notas Adicionales / Remisión</label>
            <input type="text" value={form.notas} onChange={e => setForm(f => ({ ...f, notas: e.target.value }))} className="premium-input" placeholder="Especificaciones de transporte, calidad del pez, etc." />
          </div>

        </div>

        {/* 3. Previsualizador de Cosecha & Margen de Utilidad */}
        {marginCalculation && (
          <div style={{ 
            marginTop: '1.5rem', 
            padding: '1.25rem', 
            background: 'linear-gradient(135deg, rgba(2,6,23,0.02), rgba(2,6,23,0.06))', 
            borderRadius: '12px',
            border: '1px solid var(--border)',
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))',
            gap: '1.5rem'
          }}>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.2rem' }}>
              <span style={{ fontSize: '0.72rem', fontWeight: 800, color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Ingreso Total Bruto</span>
              <span style={{ fontSize: '1.4rem', fontWeight: 900, color: '#10b981' }}>{cop(marginCalculation.ingresoTotal)}</span>
            </div>
            
            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.2rem' }}>
              <span style={{ fontSize: '0.72rem', fontWeight: 800, color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Costo de Producción Est.</span>
              <span style={{ fontSize: '1.4rem', fontWeight: 900, color: '#ef4444' }}>{cop(marginCalculation.costoTotal)}</span>
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.2rem' }}>
              <span style={{ fontSize: '0.72rem', fontWeight: 800, color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Utilidad Neta Cosecha</span>
              <span style={{ fontSize: '1.4rem', fontWeight: 900, color: marginCalculation.margenNeto >= 0 ? 'var(--primary)' : '#ef4444' }}>
                {cop(marginCalculation.margenNeto)}
              </span>
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.2rem' }}>
              <span style={{ fontSize: '0.72rem', fontWeight: 800, color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Margen de Rentabilidad</span>
              <span style={{ 
                fontSize: '1.4rem', 
                fontWeight: 900, 
                color: marginCalculation.porcentajeMargen >= 20 ? '#10b981' : marginCalculation.porcentajeMargen >= 0 ? 'var(--primary)' : '#ef4444',
                display: 'flex',
                alignItems: 'center',
                gap: '4px'
              }}>
                {marginCalculation.porcentajeMargen.toFixed(1)}%
                {marginCalculation.porcentajeMargen >= 0 && <TrendingUp size={16} />}
              </span>
            </div>
          </div>
        )}

        <button onClick={saveVenta} className="btn-primary" style={{ marginTop: '1.5rem', width: '100%', borderRadius: '12px', padding: '0.9rem', fontSize: '0.95rem', fontWeight: 800, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '0.5rem', boxShadow: '0 6px 20px rgba(13,148,136,0.2)' }}>
          <Plus size={18} /> Registrar Venta y Descontar Inventario
        </button>
      </div>

      {/* 4. Tabla de Historial con Acciones */}
      <div className="card-premium" style={{ padding: '2rem', overflowX: 'auto' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem' }}>
          <h3 style={{ fontWeight: 900, fontSize: '1.1rem' }}>Historial y Registro Maestro de Ventas</h3>
          <span style={{ fontSize: '0.75rem', background: 'var(--secondary)', color: 'var(--muted-foreground)', padding: '0.3rem 0.8rem', borderRadius: '20px', fontWeight: 700 }}>Últimos 100 despachos</span>
        </div>
        
        <table style={{ width: '100%', borderCollapse: 'collapse', minWidth: '850px' }}>
          <thead>
            <tr style={{ borderBottom: '2px solid var(--border)', color: 'var(--muted-foreground)', fontSize: '0.72rem', textTransform: 'uppercase', fontWeight: 800 }}>
              <th style={{ textAlign: 'left', padding: '0.75rem' }}>Fecha</th>
              <th style={{ textAlign: 'left', padding: '0.75rem' }}>Comprador</th>
              <th style={{ textAlign: 'left', padding: '0.75rem' }}>Estanque</th>
              <th style={{ textAlign: 'left', padding: '0.75rem' }}>Especie</th>
              <th style={{ textAlign: 'left', padding: '0.75rem' }}>Procesamiento</th>
              <th style={{ textAlign: 'right', padding: '0.75rem' }}>Peso (kg)</th>
              <th style={{ textAlign: 'right', padding: '0.75rem' }}>Precio/kg</th>
              <th style={{ textAlign: 'right', padding: '0.75rem' }}>Valor Facturado</th>
              <th style={{ textAlign: 'center', padding: '0.75rem' }}>Estatus de Recaudo</th>
              <th style={{ textAlign: 'center', padding: '0.75rem' }}>Acciones</th>
            </tr>
          </thead>
          <tbody>
            {ventas.length === 0 ? (
              <tr>
                <td colSpan={10} style={{ padding: '3rem', textAlign: 'center', color: 'var(--muted-foreground)', fontWeight: 600 }}>
                  Aún no registras ninguna venta en esta unidad acuícola.
                </td>
              </tr>
            ) : ventas.map(v => (
              <tr key={v.id} style={{ borderBottom: '1px solid var(--border)', fontSize: '0.88rem' }} className="table-row-hover">
                <td style={{ padding: '0.85rem 0.75rem', fontWeight: 600, color: 'var(--muted-foreground)' }}>{v.fecha}</td>
                <td style={{ padding: '0.85rem 0.75rem' }}>
                  <div style={{ display: 'flex', flexDirection: 'column' }}>
                    <span style={{ fontWeight: 800 }}>{v.clientes?.name || 'Venta de Mostrador / Pasajero'}</span>
                    {v.clientes?.phone && (
                      <span style={{ fontSize: '0.7rem', color: 'var(--muted-foreground)' }}>{v.clientes.phone}</span>
                    )}
                  </div>
                </td>
                <td style={{ padding: '0.85rem 0.75rem', fontWeight: 600 }}>{v.estanques?.name || '—'}</td>
                <td style={{ padding: '0.85rem 0.75rem' }}>
                  <span style={{ background: 'var(--secondary)', color: 'var(--foreground)', padding: '2px 8px', borderRadius: '6px', fontSize: '0.75rem', fontWeight: 800 }}>
                    {v.species_name}
                  </span>
                </td>
                <td style={{ padding: '0.85rem 0.75rem', fontSize: '0.78rem', fontWeight: 600 }}>{tipoLabels[v.tipo_venta] || v.tipo_venta}</td>
                <td style={{ padding: '0.85rem 0.75rem', textAlign: 'right', fontWeight: 800 }}>{parseFloat(v.cantidad_kg as any).toLocaleString('es-CO')} kg</td>
                <td style={{ padding: '0.85rem 0.75rem', textAlign: 'right' }}>{cop(v.precio_kg)}</td>
                <td style={{ padding: '0.85rem 0.75rem', textAlign: 'right', fontWeight: 900, color: '#10b981' }}>{cop(v.total)}</td>
                <td style={{ padding: '0.85rem 0.75rem', textAlign: 'center' }}>
                  <div style={{ display: 'flex', justifyContent: 'center' }}>
                    <button onClick={() => togglePago(v.id, v.estado_pago)}
                      style={{ 
                        display: 'flex', alignItems: 'center', gap: '0.3rem', padding: '4px 10px', borderRadius: '8px', border: 'none', cursor: 'pointer', fontWeight: 800, fontSize: '0.7rem', transition: 'all 0.2s',
                        background: v.estado_pago === 'pagado' ? 'rgba(16, 185, 129, 0.12)' : 'rgba(245, 158, 11, 0.12)',
                        color: v.estado_pago === 'pagado' ? '#10b981' : '#d97706',
                        boxShadow: '0 2px 4px rgba(0,0,0,0.02)'
                      }}>
                      {v.estado_pago === 'pagado' ? <CheckCircle size={12} /> : <Clock size={12} />}
                      {v.estado_pago === 'pagado' ? 'Recaudado / Listo' : 'Pendiente / Crédito'}
                    </button>
                  </div>
                </td>
                <td style={{ padding: '0.85rem 0.75rem' }}>
                  <div style={{ display: 'flex', gap: '0.4rem', justifyContent: 'center' }}>
                    
                    {/* Botón WhatsApp Cobranza (Si está pendiente) */}
                    {v.estado_pago === 'pendiente' && (
                      <button 
                        onClick={() => handleWhatsAppReminder(v)} 
                        title="Enviar recordatorio de cobro por WhatsApp"
                        style={{ 
                          background: 'rgba(37, 211, 102, 0.1)', 
                          border: 'none', 
                          borderRadius: '8px', 
                          width: '32px', 
                          height: '32px', 
                          display: 'flex', 
                          alignItems: 'center', 
                          justifyContent: 'center', 
                          cursor: 'pointer',
                          color: '#25d366'
                        }}
                      >
                        <MessageSquare size={16} />
                      </button>
                    )}

                    {/* Botón Imprimir Remisión */}
                    <button 
                      onClick={() => handlePrintRemision(v)} 
                      title="Imprimir remisión de cosecha / despacho"
                      style={{ 
                        background: 'var(--secondary)', 
                        border: 'none', 
                        borderRadius: '8px', 
                        width: '32px', 
                        height: '32px', 
                        display: 'flex', 
                        alignItems: 'center', 
                        justifyContent: 'center', 
                        cursor: 'pointer',
                        color: 'var(--muted-foreground)'
                      }}
                    >
                      <Printer size={16} />
                    </button>

                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* 5. Modal Nuevo Cliente */}
      {showClienteModal && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(2, 6, 23, 0.65)', backdropFilter: 'blur(4px)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000 }}>
          <div className="card-premium animate-scale-in" style={{ padding: '2.5rem', width: '100%', maxWidth: '420px', background: 'var(--card)' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem' }}>
              <h3 style={{ fontWeight: 900, fontSize: '1.2rem', display: 'flex', alignItems: 'center', gap: '6px' }}>
                <Plus style={{ color: 'var(--primary)' }} />
                Registrar Nuevo Comprador
              </h3>
              <button onClick={() => setShowClienteModal(false)} style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--muted-foreground)' }}><X size={20} /></button>
            </div>
            
            <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
              <div className="premium-input-group">
                <label className="premium-label">Nombre del Cliente / Empresa *</label>
                <input value={newClienteName} onChange={e => setNewClienteName(e.target.value)} className="premium-input" placeholder="Ej: Comercializadora del Pez" />
              </div>
              <div className="premium-input-group">
                <label className="premium-label">Celular WhatsApp (Con indicativo de país)</label>
                <input value={newClientePhone} onChange={e => setNewClientePhone(e.target.value)} className="premium-input" placeholder="Ej: +573123456789" />
                <span style={{ fontSize: '0.68rem', color: 'var(--muted-foreground)', marginTop: '2px' }}>Obligatorio para recordatorios de cobro automáticos.</span>
              </div>
              
              <button onClick={saveCliente} className="btn-primary" style={{ borderRadius: '12px', padding: '0.8rem', fontWeight: 800, marginTop: '0.5rem' }}>
                Guardar Cliente y Seleccionar
              </button>
            </div>
          </div>
        </div>
      )}

      {/* 6. Modal Remisión / Recibo Premium Imprimible */}
      {showInvoiceModal && selectedVentaForInvoice && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(2, 6, 23, 0.7)', backdropFilter: 'blur(5px)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000 }}>
          <div className="card-premium animate-scale-in" style={{ padding: '2.5rem', width: '100%', maxWidth: '650px', background: 'var(--card)', maxHeight: '90vh', overflowY: 'auto' }}>
            
            {/* Header del Modal */}
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem', borderBottom: '1px solid var(--border)', paddingBottom: '1rem' }} className="no-print">
              <h3 style={{ fontWeight: 900, fontSize: '1.2rem', display: 'flex', alignItems: 'center', gap: '6px' }}>
                <Printer style={{ color: 'var(--primary)' }} />
                Previsualización de Remisión de Despacho
              </h3>
              <button onClick={() => { setShowInvoiceModal(false); setSelectedVentaForInvoice(null); }} style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--muted-foreground)' }}><X size={20} /></button>
            </div>

            {/* Recibo Formateado para Impresión */}
            <div id="print-area" style={{ padding: '1.5rem', border: '2px solid #e2e8f0', borderRadius: '12px', background: 'white', color: '#0f172a', fontFamily: 'monospace, sans-serif' }}>
              
              {/* Encabezado Principal */}
              <div style={{ display: 'flex', justifyContent: 'space-between', borderBottom: '2px double #cbd5e1', paddingBottom: '1rem', marginBottom: '1.5rem' }}>
                <div>
                  <h2 style={{ fontSize: '1.4rem', fontWeight: 900, color: '#0d9488', margin: 0, letterSpacing: '-0.02em' }}>FISHBIT GRUPAL</h2>
                  <p style={{ fontSize: '0.75rem', margin: '4px 0', color: '#64748b' }}>Gestión Tecnológica Acuícola</p>
                  <p style={{ fontSize: '0.75rem', margin: '2px 0', color: '#64748b' }}>Remisión Comercial Oficial</p>
                </div>
                <div style={{ textAlign: 'right' }}>
                  <h4 style={{ margin: 0, fontSize: '0.85rem' }}>DOCUMENTO DE DESPACHO</h4>
                  <p style={{ fontSize: '0.75rem', fontWeight: 700, margin: '4px 0', color: '#0d9488' }}>ID: REM-{selectedVentaForInvoice.id.slice(0, 8).toUpperCase()}</p>
                  <p style={{ fontSize: '0.75rem', margin: '2px 0' }}>Fecha: {selectedVentaForInvoice.fecha}</p>
                </div>
              </div>

              {/* Info Cliente */}
              <div style={{ background: '#f8fafc', padding: '1rem', borderRadius: '8px', marginBottom: '1.5rem', fontSize: '0.8rem', display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
                <div>
                  <span style={{ fontWeight: 800, color: '#475569', textTransform: 'uppercase', fontSize: '0.7rem' }}>Comprador / Destino:</span>
                  <p style={{ fontSize: '0.9rem', fontWeight: 700, margin: '4px 0' }}>{selectedVentaForInvoice.clientes?.name || 'Cliente de Mostrador (Pasajero)'}</p>
                  {selectedVentaForInvoice.clientes?.phone && (
                    <p style={{ margin: '2px 0', color: '#64748b' }}>Tel: {selectedVentaForInvoice.clientes.phone}</p>
                  )}
                </div>
                <div style={{ textAlign: 'right' }}>
                  <span style={{ fontWeight: 800, color: '#475569', textTransform: 'uppercase', fontSize: '0.7rem' }}>Origen Cosecha:</span>
                  <p style={{ fontSize: '0.9rem', fontWeight: 700, margin: '4px 0' }}>{selectedVentaForInvoice.estanques?.name || 'Estanque Principal'}</p>
                  <p style={{ margin: '2px 0', color: '#64748b' }}>Unidad Acuícola FishBit</p>
                </div>
              </div>

              {/* Tabla de Productos */}
              <table style={{ width: '100%', borderCollapse: 'collapse', marginBottom: '2rem', fontSize: '0.85rem' }}>
                <thead>
                  <tr style={{ borderBottom: '2px solid #0f172a', fontWeight: 800 }}>
                    <th style={{ textAlign: 'left', padding: '8px 4px' }}>Descripción</th>
                    <th style={{ textAlign: 'center', padding: '8px 4px' }}>Tipo</th>
                    <th style={{ textAlign: 'right', padding: '8px 4px' }}>Peso (kg)</th>
                    <th style={{ textAlign: 'right', padding: '8px 4px' }}>Precio Unitario</th>
                    <th style={{ textAlign: 'right', padding: '8px 4px' }}>Total COP</th>
                  </tr>
                </thead>
                <tbody>
                  <tr style={{ borderBottom: '1px solid #cbd5e1' }}>
                    <td style={{ padding: '12px 4px', fontWeight: 700 }}>
                      Pescado Fresco - {selectedVentaForInvoice.species_name}
                    </td>
                    <td style={{ padding: '12px 4px', textAlign: 'center' }}>
                      {tipoLabels[selectedVentaForInvoice.tipo_venta] || selectedVentaForInvoice.tipo_venta}
                    </td>
                    <td style={{ padding: '12px 4px', textAlign: 'right', fontWeight: 700 }}>
                      {selectedVentaForInvoice.cantidad_kg.toLocaleString('es-CO')} kg
                    </td>
                    <td style={{ padding: '12px 4px', textAlign: 'right' }}>
                      {cop(selectedVentaForInvoice.precio_kg)}
                    </td>
                    <td style={{ padding: '12px 4px', textAlign: 'right', fontWeight: 800 }}>
                      {cop(selectedVentaForInvoice.total)}
                    </td>
                  </tr>
                </tbody>
              </table>

              {/* Total y Notas */}
              <div style={{ display: 'grid', gridTemplateColumns: '1.2fr 0.8fr', gap: '1.5rem', marginBottom: '2rem' }}>
                <div style={{ fontSize: '0.75rem', color: '#475569' }}>
                  <strong>Notas del Despacho:</strong>
                  <p style={{ margin: '4px 0', fontStyle: 'italic', background: '#f8fafc', padding: '8px', borderRadius: '6px' }}>
                    {selectedVentaForInvoice.notas || 'Sin especificaciones o novedades cargadas en la entrega.'}
                  </p>
                </div>
                <div style={{ textAlign: 'right', display: 'flex', flexDirection: 'column', gap: '0.4rem', justifyContent: 'flex-start' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.85rem' }}>
                    <span style={{ color: '#64748b' }}>Subtotal:</span>
                    <span>{cop(selectedVentaForInvoice.total)}</span>
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.85rem' }}>
                    <span style={{ color: '#64748b' }}>Retenciones:</span>
                    <span>$0 COP</span>
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '1.05rem', fontWeight: 900, borderTop: '2px solid #0f172a', paddingTop: '6px', color: '#0d9488' }}>
                    <span>TOTAL FACTURA:</span>
                    <span>{cop(selectedVentaForInvoice.total)}</span>
                  </div>
                  <div style={{ fontSize: '0.7rem', fontWeight: 800, color: selectedVentaForInvoice.estado_pago === 'pagado' ? '#10b981' : '#d97706', marginTop: '6px' }}>
                    Estatus: {selectedVentaForInvoice.estado_pago === 'pagado' ? 'PAGADO COMPLETO' : 'PENDIENTE DE RECAUDO / CRÉDITO'}
                  </div>
                </div>
              </div>

              {/* Firmas de Control */}
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '3rem', marginTop: '4rem', borderTop: '1px dashed #cbd5e1', paddingTop: '1.5rem', fontSize: '0.75rem' }}>
                <div style={{ textAlign: 'center' }}>
                  <div style={{ width: '180px', borderBottom: '1px solid #0f172a', margin: '0 auto 8px' }}></div>
                  <strong>Firma Despachador Granja</strong>
                  <p style={{ margin: '2px 0', color: '#64748b' }}>Responsable de Pesca y Calidad</p>
                </div>
                <div style={{ textAlign: 'center' }}>
                  <div style={{ width: '180px', borderBottom: '1px solid #0f172a', margin: '0 auto 8px' }}></div>
                  <strong>Firma Comprador / Conductor</strong>
                  <p style={{ margin: '2px 0', color: '#64748b' }}>Recibido a Satisfacción y Conteo</p>
                </div>
              </div>

            </div>

            {/* Acciones del Modal */}
            <div style={{ display: 'flex', gap: '1rem', marginTop: '2rem', justifyContent: 'flex-end' }} className="no-print">
              <button 
                onClick={() => { setShowInvoiceModal(false); setSelectedVentaForInvoice(null); }} 
                className="btn-secondary" 
                style={{ borderRadius: '10px', fontWeight: 800 }}
              >
                Cerrar Previsualización
              </button>
              
              <button 
                onClick={() => window.print()} 
                className="btn-primary" 
                style={{ borderRadius: '10px', fontWeight: 850, display: 'flex', alignItems: 'center', gap: '6px', background: 'var(--primary)' }}
              >
                <Printer size={16} />
                Imprimir o Guardar PDF
              </button>
            </div>

          </div>
        </div>
      )}

      {/* CSS específico de Impresión para ocultar elementos web en papel */}
      <style jsx global>{`
        @media print {
          body * {
            visibility: hidden;
          }
          #print-area, #print-area * {
            visibility: visible;
          }
          #print-area {
            position: absolute;
            left: 0;
            top: 0;
            width: 100%;
            border: none !important;
            padding: 0 !important;
          }
          .no-print {
            display: none !important;
          }
        }
      `}</style>

    </div>
  );
}
