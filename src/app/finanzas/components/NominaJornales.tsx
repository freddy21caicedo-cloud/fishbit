'use client';
import { useState, useEffect } from 'react';
import { supabase } from '@/lib/supabase';
import { toast } from 'react-hot-toast';
import { Plus, Trash2, Users, Wrench } from 'lucide-react';

const cop = (v: number) => v.toLocaleString('es-CO', { style: 'currency', currency: 'COP', maximumFractionDigits: 0 });

export function NominaJornales({ unitId }: { unitId: string }) {
  const [ponds, setPonds] = useState<any[]>([]);
  const [nominas, setNominas] = useState<any[]>([]);
  const [jornales, setJornales] = useState<any[]>([]);
  const [tab, setTab] = useState<'nomina' | 'jornales'>('nomina');

  // Nómina form
  const [mes, setMes] = useState(new Date().toISOString().slice(0, 7));
  const [monto, setMonto] = useState('');
  const [descNom, setDescNom] = useState('');

  // Jornales form
  const [fecha, setFecha] = useState(new Date().toISOString().split('T')[0]);
  const [cantJornales, setCantJornales] = useState('1');
  const [valorJornal, setValorJornal] = useState('');
  const [descJor, setDescJor] = useState('');
  const [estanqueJor, setEstanqueJor] = useState('');

  useEffect(() => {
    if (!unitId) return;
    supabase.from('estanques').select('id, name').eq('unit_id', unitId).eq('status', 'con_peces').then(({ data }: any) => setPonds(data || []));
    fetchNominas();
    fetchJornales();
  }, [unitId]);

  const fetchNominas = async () => {
    const { data } = await supabase.from('nomina').select('*').eq('unit_id', unitId).order('mes', { ascending: false });
    setNominas(data || []);
  };

  const fetchJornales = async () => {
    const { data } = await supabase.from('jornales').select('*, estanques(name)').eq('unit_id', unitId).order('fecha', { ascending: false });
    setJornales(data || []);
  };

  const saveNomina = async () => {
    if (!monto) return toast.error('Ingresa el monto de nómina');
    const { error } = await supabase.from('nomina').insert([{ unit_id: unitId, mes: `${mes}-01`, monto: parseFloat(monto), descripcion: descNom }]);
    if (error) return toast.error('Error al guardar: ' + error.message);
    toast.success('Nómina registrada');
    setMonto(''); setDescNom('');
    fetchNominas();
  };

  const saveJornal = async () => {
    if (!valorJornal) return toast.error('Ingresa el valor del jornal');
    const { error } = await supabase.from('jornales').insert([{
      unit_id: unitId,
      estanque_id: estanqueJor || null,
      fecha, cantidad_jornales: parseInt(cantJornales), valor_jornal: parseFloat(valorJornal),
      descripcion: descJor
    }]);
    if (error) return toast.error('Error: ' + error.message);
    toast.success('Jornal registrado');
    setValorJornal(''); setDescJor(''); setEstanqueJor('');
    fetchJornales();
  };

  const deleteItem = async (table: string, id: string, refresh: () => void) => {
    await supabase.from(table).delete().eq('id', id);
    refresh();
  };

  const totalNomina = nominas.reduce((s, n) => s + parseFloat(n.monto || 0), 0);
  const totalJornales = jornales.reduce((s, j) => s + parseFloat(j.total || 0), 0);

  return (
    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1.5fr', gap: '1.5rem' }}>
      {/* Form panel */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
        <div style={{ display: 'flex', gap: '0.5rem' }}>
          {(['nomina', 'jornales'] as const).map(t => (
            <button key={t} onClick={() => setTab(t)}
              style={{ flex: 1, padding: '0.6rem', borderRadius: '10px', border: 'none', fontWeight: 800, fontSize: '0.8rem', cursor: 'pointer',
                background: tab === t ? 'var(--primary)' : 'var(--secondary)', color: tab === t ? 'white' : 'var(--foreground)' }}>
              {t === 'nomina' ? '👥 Nómina' : '🔧 Jornales'}
            </button>
          ))}
        </div>

        <div className="card-premium" style={{ padding: '1.5rem', display: 'flex', flexDirection: 'column', gap: '1rem' }}>
          {tab === 'nomina' ? (
            <>
              <h3 style={{ fontWeight: 800, fontSize: '1rem' }}>Registrar Nómina Mensual</h3>
              <div className="premium-input-group">
                <label className="premium-label">Mes</label>
                <input type="month" value={mes} onChange={e => setMes(e.target.value)} className="premium-input" />
              </div>
              <div className="premium-input-group">
                <label className="premium-label">Monto Total (COP)</label>
                <input type="number" value={monto} onChange={e => setMonto(e.target.value)} placeholder="0" className="premium-input" />
              </div>
              <div className="premium-input-group">
                <label className="premium-label">Descripción</label>
                <input type="text" value={descNom} onChange={e => setDescNom(e.target.value)} placeholder="Nómina operarios mayo..." className="premium-input" />
              </div>
              <div style={{ padding: '0.75rem', background: 'rgba(59,130,246,0.08)', borderRadius: '8px', fontSize: '0.75rem', color: '#3b82f6', fontWeight: 700 }}>
                💡 Se prorrateará entre estanques activos según biomasa al calcular costos
              </div>
              <button onClick={saveNomina} className="btn-primary" style={{ borderRadius: '10px' }}>
                <Plus size={16} /> Guardar Nómina
              </button>
            </>
          ) : (
            <>
              <h3 style={{ fontWeight: 800, fontSize: '1rem' }}>Registrar Jornal</h3>
              <div className="premium-input-group">
                <label className="premium-label">Fecha</label>
                <input type="date" value={fecha} onChange={e => setFecha(e.target.value)} className="premium-input" />
              </div>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.75rem' }}>
                <div className="premium-input-group">
                  <label className="premium-label">Cantidad Jornales</label>
                  <input type="number" value={cantJornales} onChange={e => setCantJornales(e.target.value)} className="premium-input" min="1" />
                </div>
                <div className="premium-input-group">
                  <label className="premium-label">Valor/Jornal (COP)</label>
                  <input type="number" value={valorJornal} onChange={e => setValorJornal(e.target.value)} placeholder="0" className="premium-input" />
                </div>
              </div>
              <div className="premium-input-group">
                <label className="premium-label">Estanque (dejar vacío = general)</label>
                <select value={estanqueJor} onChange={e => setEstanqueJor(e.target.value)} className="premium-input">
                  <option value="">🌐 Gasto General (todos los estanques)</option>
                  {ponds.map(p => <option key={p.id} value={p.id}>{p.name}</option>)}
                </select>
              </div>
              <div className="premium-input-group">
                <label className="premium-label">Descripción</label>
                <input type="text" value={descJor} onChange={e => setDescJor(e.target.value)} placeholder="Ej: Limpieza Est-03" className="premium-input" />
              </div>
              {cantJornales && valorJornal && (
                <div style={{ padding: '0.75rem', background: 'rgba(16,185,129,0.08)', borderRadius: '8px', fontSize: '0.85rem', fontWeight: 800, color: '#10b981' }}>
                  Total: {cop(parseInt(cantJornales) * parseFloat(valorJornal))}
                </div>
              )}
              <button onClick={saveJornal} className="btn-primary" style={{ borderRadius: '10px' }}>
                <Plus size={16} /> Guardar Jornal
              </button>
            </>
          )}
        </div>
      </div>

      {/* History */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
        <div className="card-premium" style={{ padding: '1.5rem' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '1rem' }}>
            <h3 style={{ fontWeight: 800, display: 'flex', alignItems: 'center', gap: '0.5rem' }}><Users size={18} /> Nóminas — {cop(totalNomina)}</h3>
          </div>
          <div style={{ maxHeight: '200px', overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
            {nominas.length === 0 ? <p style={{ color: 'var(--muted-foreground)', fontSize: '0.85rem' }}>Sin registros</p> : nominas.map(n => (
              <div key={n.id} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '0.75rem', background: 'var(--secondary)', borderRadius: '8px' }}>
                <div>
                  <div style={{ fontWeight: 800, fontSize: '0.85rem' }}>{cop(parseFloat(n.monto))}</div>
                  <div style={{ fontSize: '0.7rem', color: 'var(--muted-foreground)' }}>{n.mes?.slice(0, 7)} {n.descripcion && `· ${n.descripcion}`}</div>
                </div>
                <button onClick={() => deleteItem('nomina', n.id, fetchNominas)} style={{ background: 'none', border: 'none', cursor: 'pointer', color: '#ef4444', padding: '4px' }}><Trash2 size={14} /></button>
              </div>
            ))}
          </div>
        </div>

        <div className="card-premium" style={{ padding: '1.5rem' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '1rem' }}>
            <h3 style={{ fontWeight: 800, display: 'flex', alignItems: 'center', gap: '0.5rem' }}><Wrench size={18} /> Jornales — {cop(totalJornales)}</h3>
          </div>
          <div style={{ maxHeight: '250px', overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
            {jornales.length === 0 ? <p style={{ color: 'var(--muted-foreground)', fontSize: '0.85rem' }}>Sin registros</p> : jornales.map(j => (
              <div key={j.id} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '0.75rem', background: 'var(--secondary)', borderRadius: '8px' }}>
                <div>
                  <div style={{ fontWeight: 800, fontSize: '0.85rem' }}>{cop(parseFloat(j.total))} · {j.cantidad_jornales} jornales</div>
                  <div style={{ fontSize: '0.7rem', color: 'var(--muted-foreground)' }}>
                    {j.fecha} · {(j.estanques as any)?.name || 'General'} {j.descripcion && `· ${j.descripcion}`}
                  </div>
                </div>
                <button onClick={() => deleteItem('jornales', j.id, fetchJornales)} style={{ background: 'none', border: 'none', cursor: 'pointer', color: '#ef4444', padding: '4px' }}><Trash2 size={14} /></button>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
