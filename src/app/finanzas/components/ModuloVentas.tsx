'use client';
import { useEffect, useState } from 'react';
import { supabase } from '@/lib/supabase';
import { toast } from 'react-hot-toast';
import { Plus, CheckCircle, Clock, X } from 'lucide-react';

const cop = (v: number) => v.toLocaleString('es-CO', { style: 'currency', currency: 'COP', maximumFractionDigits: 0 });

export function ModuloVentas({ unitId }: { unitId: string }) {
  const [ponds, setPonds] = useState<any[]>([]);
  const [clientes, setClientes] = useState<any[]>([]);
  const [ventas, setVentas] = useState<any[]>([]);
  const [showClienteModal, setShowClienteModal] = useState(false);
  const [newClienteName, setNewClienteName] = useState('');
  const [newClientePhone, setNewClientePhone] = useState('');

  const [form, setForm] = useState({ cliente_id: '', estanque_id: '', species_name: '', tipo_venta: 'vivo', cantidad_kg: '', precio_kg: '', fecha: new Date().toISOString().split('T')[0], notas: '' });
  const [pondSpecies, setPondSpecies] = useState<string[]>([]);
  const [pondBiomasa, setPondBiomasa] = useState(0);

  useEffect(() => {
    if (!unitId) return;
    fetchAll();
  }, [unitId]);

  const fetchAll = async () => {
    const [p, c, v] = await Promise.all([
      supabase.from('estanques').select('id, name, current_biomass_kg, current_species, is_polyculture, current_count').eq('unit_id', unitId).eq('status', 'con_peces'),
      supabase.from('clientes').select('*').eq('unit_id', unitId).order('name'),
      supabase.from('ventas').select('*, clientes(name), estanques(name)').eq('unit_id', unitId).order('fecha', { ascending: false }).limit(50),
    ]);
    setPonds(p.data || []);
    setClientes(c.data || []);
    setVentas(v.data || []);
  };

  const handlePondChange = async (pondId: string) => {
    setForm(f => ({ ...f, estanque_id: pondId, species_name: '' }));
    const pond = ponds.find(p => p.id === pondId);
    if (!pond) return;
    setPondBiomasa(parseFloat(pond.current_biomass_kg || 0));
    if (pond.is_polyculture) {
      const { data } = await supabase.from('pond_species').select('species_name').eq('estanque_id', pondId);
      setPondSpecies((data || []).map((s: any) => s.species_name));
    } else {
      setPondSpecies(pond.current_species ? [pond.current_species] : []);
    }
  };

  const saveVenta = async () => {
    const { cliente_id, estanque_id, species_name, tipo_venta, cantidad_kg, precio_kg, fecha } = form;
    if (!estanque_id || !species_name || !cantidad_kg || !precio_kg) return toast.error('Completa todos los campos requeridos');
    const kgNum = parseFloat(cantidad_kg);

    if (kgNum > pondBiomasa) {
      toast('⚠️ Cantidad supera la biomasa registrada. Se ajustará el inventario.', { icon: '⚠️', duration: 4000 });
    }

    const { error } = await supabase.from('ventas').insert([{ unit_id: unitId, cliente_id: cliente_id || null, estanque_id, species_name, tipo_venta, cantidad_kg: kgNum, precio_kg: parseFloat(precio_kg), fecha, notas: form.notas }]);
    if (error) return toast.error('Error: ' + error.message);

    // Update pond biomass
    await supabase.from('estanques').update({ current_biomass_kg: Math.max(0, pondBiomasa - kgNum) }).eq('id', estanque_id);
    toast.success('Venta registrada correctamente');
    setForm({ cliente_id: '', estanque_id: '', species_name: '', tipo_venta: 'vivo', cantidad_kg: '', precio_kg: '', fecha: new Date().toISOString().split('T')[0], notas: '' });
    setPondSpecies([]); setPondBiomasa(0);
    fetchAll();
  };

  const togglePago = async (id: string, current: string) => {
    const next = current === 'pendiente' ? 'pagado' : 'pendiente';
    await supabase.from('ventas').update({ estado_pago: next }).eq('id', id);
    fetchAll();
  };

  const saveCliente = async () => {
    if (!newClienteName) return;
    const { data } = await supabase.from('clientes').insert([{ unit_id: unitId, name: newClienteName, phone: newClientePhone }]).select().single();
    if (data) { setClientes(c => [...c, data]); setForm(f => ({ ...f, cliente_id: data.id })); }
    setShowClienteModal(false); setNewClienteName(''); setNewClientePhone('');
  };

  const tipoLabels: Record<string, string> = { vivo: 'Vivo', eviscerado_media: 'Eviscr. Media tripa', eviscerado_completo: 'Eviscr. Completo' };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
      {/* Form */}
      <div className="card-premium" style={{ padding: '1.5rem' }}>
        <h3 style={{ fontWeight: 800, marginBottom: '1.25rem', fontSize: '1rem' }}>Nueva Venta</h3>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '1rem' }}>
          {/* Cliente */}
          <div className="premium-input-group">
            <label className="premium-label">Cliente</label>
            <div style={{ display: 'flex', gap: '0.5rem' }}>
              <select value={form.cliente_id} onChange={e => setForm(f => ({ ...f, cliente_id: e.target.value }))} className="premium-input" style={{ flex: 1 }}>
                <option value="">Sin cliente</option>
                {clientes.map(c => <option key={c.id} value={c.id}>{c.name}</option>)}
              </select>
              <button onClick={() => setShowClienteModal(true)} style={{ padding: '0 0.75rem', background: 'var(--primary)', color: 'white', border: 'none', borderRadius: '10px', cursor: 'pointer', fontWeight: 800 }}>+</button>
            </div>
          </div>

          <div className="premium-input-group">
            <label className="premium-label">Fecha</label>
            <input type="date" value={form.fecha} onChange={e => setForm(f => ({ ...f, fecha: e.target.value }))} className="premium-input" />
          </div>

          <div className="premium-input-group">
            <label className="premium-label">Estanque</label>
            <select value={form.estanque_id} onChange={e => handlePondChange(e.target.value)} className="premium-input">
              <option value="">Seleccionar...</option>
              {ponds.map(p => <option key={p.id} value={p.id}>{p.name} ({parseFloat(p.current_biomass_kg || 0).toFixed(1)} kg disp.)</option>)}
            </select>
          </div>

          <div className="premium-input-group">
            <label className="premium-label">Especie</label>
            <select value={form.species_name} onChange={e => setForm(f => ({ ...f, species_name: e.target.value }))} className="premium-input">
              <option value="">Seleccionar...</option>
              {pondSpecies.map(s => <option key={s} value={s}>{s}</option>)}
            </select>
          </div>

          <div className="premium-input-group">
            <label className="premium-label">Tipo de Venta</label>
            <select value={form.tipo_venta} onChange={e => setForm(f => ({ ...f, tipo_venta: e.target.value }))} className="premium-input">
              {Object.entries(tipoLabels).map(([k, v]) => <option key={k} value={k}>{v}</option>)}
            </select>
          </div>

          <div className="premium-input-group">
            <label className="premium-label">Cantidad (kg)</label>
            <input type="number" value={form.cantidad_kg} onChange={e => setForm(f => ({ ...f, cantidad_kg: e.target.value }))} className="premium-input"
              style={parseFloat(form.cantidad_kg) > pondBiomasa && pondBiomasa > 0 ? { borderColor: '#f59e0b' } : {}} placeholder="0" />
            {parseFloat(form.cantidad_kg) > pondBiomasa && pondBiomasa > 0 && <div style={{ fontSize: '0.7rem', color: '#f59e0b', fontWeight: 700, marginTop: '4px' }}>⚠️ Supera biomasa registrada ({pondBiomasa.toFixed(1)} kg)</div>}
          </div>

          <div className="premium-input-group">
            <label className="premium-label">Precio/kg (COP)</label>
            <input type="number" value={form.precio_kg} onChange={e => setForm(f => ({ ...f, precio_kg: e.target.value }))} className="premium-input" placeholder="0" />
          </div>

          <div className="premium-input-group">
            <label className="premium-label">Notas</label>
            <input type="text" value={form.notas} onChange={e => setForm(f => ({ ...f, notas: e.target.value }))} className="premium-input" placeholder="Opcional" />
          </div>
        </div>

        {form.cantidad_kg && form.precio_kg && (
          <div style={{ marginTop: '1rem', padding: '0.75rem 1rem', background: 'rgba(16,185,129,0.08)', borderRadius: '10px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontWeight: 700, color: 'var(--muted-foreground)' }}>Total Venta</span>
            <span style={{ fontSize: '1.25rem', fontWeight: 900, color: '#10b981' }}>{cop(parseFloat(form.cantidad_kg) * parseFloat(form.precio_kg))}</span>
          </div>
        )}
        <button onClick={saveVenta} className="btn-primary" style={{ marginTop: '1rem', width: '100%', borderRadius: '10px' }}>
          <Plus size={16} /> Registrar Venta
        </button>
      </div>

      {/* History table */}
      <div className="card-premium" style={{ padding: '1.5rem', overflowX: 'auto' }}>
        <h3 style={{ fontWeight: 800, marginBottom: '1.25rem' }}>Historial de Ventas</h3>
        <table style={{ width: '100%', borderCollapse: 'collapse', minWidth: '700px' }}>
          <thead>
            <tr style={{ borderBottom: '2px solid var(--border)', color: 'var(--muted-foreground)', fontSize: '0.75rem', textTransform: 'uppercase' }}>
              {['Fecha', 'Cliente', 'Estanque', 'Especie', 'Tipo', 'Cantidad', 'Precio/kg', 'Total', 'Estado'].map(h => (
                <th key={h} style={{ textAlign: 'left', padding: '0.6rem 0.75rem' }}>{h}</th>
              ))}
            </tr>
          </thead>
          <tbody>
            {ventas.length === 0 ? (
              <tr><td colSpan={9} style={{ padding: '2rem', textAlign: 'center', color: 'var(--muted-foreground)' }}>Sin ventas registradas</td></tr>
            ) : ventas.map(v => (
              <tr key={v.id} style={{ borderBottom: '1px solid var(--border)' }}>
                <td style={{ padding: '0.75rem' }}>{v.fecha}</td>
                <td style={{ padding: '0.75rem', fontWeight: 700 }}>{(v.clientes as any)?.name || '—'}</td>
                <td style={{ padding: '0.75rem' }}>{(v.estanques as any)?.name || '—'}</td>
                <td style={{ padding: '0.75rem' }}>{v.species_name}</td>
                <td style={{ padding: '0.75rem', fontSize: '0.78rem' }}>{tipoLabels[v.tipo_venta]}</td>
                <td style={{ padding: '0.75rem', fontWeight: 700 }}>{parseFloat(v.cantidad_kg).toLocaleString('es-CO')} kg</td>
                <td style={{ padding: '0.75rem' }}>{cop(parseFloat(v.precio_kg))}</td>
                <td style={{ padding: '0.75rem', fontWeight: 900, color: '#10b981' }}>{cop(parseFloat(v.total))}</td>
                <td style={{ padding: '0.75rem' }}>
                  <button onClick={() => togglePago(v.id, v.estado_pago)}
                    style={{ display: 'flex', alignItems: 'center', gap: '0.3rem', padding: '4px 10px', borderRadius: '6px', border: 'none', cursor: 'pointer', fontWeight: 800, fontSize: '0.72rem',
                      background: v.estado_pago === 'pagado' ? 'rgba(16,185,129,0.12)' : 'rgba(245,158,11,0.12)',
                      color: v.estado_pago === 'pagado' ? '#10b981' : '#d97706' }}>
                    {v.estado_pago === 'pagado' ? <CheckCircle size={12} /> : <Clock size={12} />}
                    {v.estado_pago === 'pagado' ? 'Pagado' : 'Pendiente'}
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Modal nuevo cliente */}
      {showClienteModal && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.5)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000 }}>
          <div className="card-premium" style={{ padding: '2rem', width: '100%', maxWidth: '400px', borderRadius: '20px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '1.5rem' }}>
              <h3 style={{ fontWeight: 900 }}>Nuevo Cliente</h3>
              <button onClick={() => setShowClienteModal(false)} style={{ background: 'none', border: 'none', cursor: 'pointer' }}><X size={20} /></button>
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
              <div className="premium-input-group"><label className="premium-label">Nombre *</label><input value={newClienteName} onChange={e => setNewClienteName(e.target.value)} className="premium-input" placeholder="Nombre del cliente" /></div>
              <div className="premium-input-group"><label className="premium-label">Teléfono</label><input value={newClientePhone} onChange={e => setNewClientePhone(e.target.value)} className="premium-input" placeholder="+57..." /></div>
              <button onClick={saveCliente} className="btn-primary" style={{ borderRadius: '10px' }}>Guardar Cliente</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
