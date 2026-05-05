'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { supabase } from '@/lib/supabase';
import { motion } from 'framer-motion';
import { 
  TrendingUp, 
  Users, 
  Activity, 
  AlertCircle,
  ArrowUpRight,
  Droplets,
  Thermometer,
  Wind,
  MessageSquare,
  X
} from 'lucide-react';
import { 
  LineChart, 
  Line, 
  XAxis, 
  YAxis, 
  CartesianGrid, 
  Tooltip, 
  ResponsiveContainer,
  AreaChart,
  Area
} from 'recharts';

const data = [
  { name: '00:00', oxygen: 6.5, temp: 24.2 },
  { name: '04:00', oxygen: 6.2, temp: 23.8 },
  { name: '08:00', oxygen: 6.8, temp: 24.5 },
  { name: '12:00', oxygen: 7.2, temp: 25.1 },
  { name: '16:00', oxygen: 6.9, temp: 25.4 },
  { name: '20:00', oxygen: 6.6, temp: 24.8 },
  { name: '23:59', oxygen: 6.4, temp: 24.3 },
];

const StatCard = ({ title, value, change, icon: Icon, color }: any) => (
  <motion.div 
    initial={{ opacity: 0, y: 20 }}
    animate={{ opacity: 1, y: 0 }}
    className="card-premium stat-card"
  >
    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
      <div style={{ padding: '0.5rem', background: `${color}15`, borderRadius: '0.5rem', color: color }}>
        <Icon size={24} />
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: '0.25rem', color: '#10b981', fontSize: '0.75rem', fontWeight: 600 }}>
        {change}
        <ArrowUpRight size={14} />
      </div>
    </div>
    <div className="stat-value">{value}</div>
    <div className="stat-label">{title}</div>
  </motion.div>
);

export default function Dashboard() {
  const router = useRouter();
  const [authLoading, setAuthLoading] = useState(true);

  useEffect(() => {
    async function initDashboard() {
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) {
        router.push('/login');
        return;
      }
      
      setAuthLoading(false);

      // Fetch user's unit and role
      const { data: userUnit } = await supabase
        .from('user_units')
        .select('unit_id, role')
        .eq('user_id', session.user.id)
        .limit(1)
        .single();
      
      if (userUnit) {
        if (userUnit.role === 'operario') {
          router.push('/registros');
          return;
        }
        localStorage.setItem('active_unit_id', userUnit.unit_id);
      }
    }
    initDashboard();
  }, [router]);

  const [isSupportOpen, setIsSupportOpen] = useState(false);
  const [ticketSubject, setTicketSubject] = useState('');
  const [ticketMessage, setTicketMessage] = useState('');
  const [sendingTicket, setSendingTicket] = useState(false);

  const handleSendTicket = async (e: React.FormEvent) => {
    e.preventDefault();
    setSendingTicket(true);
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error("No hay sesión activa");

      const { error } = await supabase.from('support_tickets').insert([{
        user_id: user.id,
        subject: ticketSubject,
        description: ticketMessage,
        status: 'open',
        priority: 'medium'
      }]);

      if (error) throw error;
      
      alert("Ticket enviado con éxito. Te responderemos pronto.");
      setIsSupportOpen(false);
      setTicketSubject('');
      setTicketMessage('');
    } catch (err: any) {
      alert("Error al enviar ticket: " + err.message);
    } finally {
      setSendingTicket(false);
    }
  };

  if (authLoading) return null;

  return (
    <div className="animate-fade-in" style={{ paddingBottom: '5rem' }}>
      <div className="dashboard-grid">
        <StatCard 
          title="Biomasa Total" 
          value="12,450 kg" 
          change="+4.2%" 
          icon={TrendingUp} 
          color="#3b82f6" 
        />
        <StatCard 
          title="Eficiencia de Alimentación" 
          value="1.2 FCA" 
          change="+2.1%" 
          icon={Activity} 
          color="#8b5cf6" 
        />
        <StatCard 
          title="Tanques Activos" 
          value="24 / 28" 
          change="Estable" 
          icon={Users} 
          color="#10b981" 
        />
        <StatCard 
          title="Salud del Sistema" 
          value="98.2%" 
          change="Óptimo" 
          icon={AlertCircle} 
          color="#f59e0b" 
        />
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: '1.5rem', marginBottom: '2rem' }}>
        <div className="card-premium" style={{ padding: '1.5rem' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem' }}>
            <h3 style={{ fontSize: '1.125rem' }}>Tendencias de Calidad del Agua</h3>
            <select style={{ background: 'var(--secondary)', border: 'none', padding: '0.4rem 0.8rem', borderRadius: 'var(--radius)', fontSize: '0.875rem' }}>
              <option>Últimas 24 Horas</option>
              <option>Últimos 7 Días</option>
            </select>
          </div>
          <div style={{ height: '300px', width: '100%' }}>
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={data}>
                <defs>
                  <linearGradient id="colorOxygen" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.1}/>
                    <stop offset="95%" stopColor="#3b82f6" stopOpacity={0}/>
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="var(--border)" />
                <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{ fontSize: 12, fill: 'var(--muted-foreground)' }} />
                <YAxis axisLine={false} tickLine={false} tick={{ fontSize: 12, fill: 'var(--muted-foreground)' }} />
                <Tooltip 
                  contentStyle={{ background: 'var(--card)', border: '1px solid var(--border)', borderRadius: 'var(--radius)', boxShadow: 'var(--shadow-md)' }}
                />
                <Area type="monotone" dataKey="oxygen" stroke="#3b82f6" strokeWidth={2} fillOpacity={1} fill="url(#colorOxygen)" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
          <div className="card-premium" style={{ padding: '1.5rem', flex: 1 }}>
            <h3 style={{ fontSize: '1.125rem', marginBottom: '1rem' }}>Estado de la Granja</h3>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                <div style={{ padding: '0.5rem', background: '#ecfdf5', color: '#10b981', borderRadius: '0.5rem' }}>
                  <Thermometer size={20} />
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: '0.875rem', fontWeight: 500 }}>Temperatura</div>
                  <div style={{ fontSize: '0.75rem', color: 'var(--muted-foreground)' }}>Promedio General</div>
                </div>
                <div style={{ fontWeight: 700 }}>24.5°C</div>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                <div style={{ padding: '0.5rem', background: '#eff6ff', color: '#3b82f6', borderRadius: '0.5rem' }}>
                  <Wind size={20} />
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: '0.875rem', fontWeight: 500 }}>Oxígeno Disuelto</div>
                  <div style={{ fontSize: '0.75rem', color: 'var(--muted-foreground)' }}>Promedio General</div>
                </div>
                <div style={{ fontWeight: 700 }}>6.8 mg/L</div>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                <div style={{ padding: '0.5rem', background: '#fef2f2', color: '#ef4444', borderRadius: '0.5rem' }}>
                  <Droplets size={20} />
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: '0.875rem', fontWeight: 500 }}>Nivel de pH</div>
                  <div style={{ fontSize: '0.75rem', color: 'var(--muted-foreground)' }}>Promedio General</div>
                </div>
                <div style={{ fontWeight: 700 }}>7.2</div>
              </div>
            </div>
          </div>
          
          <button className="btn-primary" style={{ width: '100%' }}>
            Generar Reporte Completo
          </button>
        </div>
      </div>

      {/* Floating Support Button */}
      <button 
        onClick={() => setIsSupportOpen(true)}
        style={{
          position: 'fixed',
          bottom: '2rem',
          right: '2rem',
          width: '64px',
          height: '64px',
          borderRadius: '20px',
          background: 'var(--primary)',
          color: 'white',
          border: 'none',
          boxShadow: '0 10px 25px rgba(37, 99, 235, 0.4)',
          cursor: 'pointer',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          zIndex: 100,
          transition: 'transform 0.2s ease'
        }}
        onMouseEnter={(e) => e.currentTarget.style.transform = 'scale(1.1)'}
        onMouseLeave={(e) => e.currentTarget.style.transform = 'scale(1)'}
      >
        <MessageSquare size={32} />
      </button>

      {/* Support Modal */}
      {isSupportOpen && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(15, 23, 42, 0.4)', backdropFilter: 'blur(8px)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000, padding: '1rem' }}>
          <motion.div initial={{ scale: 0.9, opacity: 0 }} animate={{ scale: 1, opacity: 1 }} className="card-premium" style={{ width: '100%', maxWidth: '400px', padding: '2rem', position: 'relative' }}>
            <button onClick={() => setIsSupportOpen(false)} style={{ position: 'absolute', top: '1rem', right: '1rem', background: 'none', border: 'none', color: 'var(--muted-foreground)', cursor: 'pointer' }}>
              <X size={20} />
            </button>
            <h3 style={{ fontWeight: 800, fontSize: '1.25rem', marginBottom: '1.5rem' }}>Soporte Técnico FishBit</h3>
            <form onSubmit={handleSendTicket} style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
                <label style={{ fontSize: '0.75rem', fontWeight: 800, color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Asunto</label>
                <input 
                  required 
                  placeholder="¿En qué podemos ayudarte?" 
                  style={{ width: '100%', padding: '0.75rem', borderRadius: '10px', border: '1px solid var(--border)', background: 'var(--secondary)', outline: 'none' }}
                  value={ticketSubject}
                  onChange={(e: React.ChangeEvent<HTMLInputElement>) => setTicketSubject(e.target.value)}
                />
              </div>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
                <label style={{ fontSize: '0.75rem', fontWeight: 800, color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Mensaje</label>
                <textarea 
                  required 
                  rows={4} 
                  placeholder="Describe tu problema o duda aquí..." 
                  style={{ width: '100%', padding: '0.75rem', borderRadius: '10px', border: '1px solid var(--border)', background: 'var(--secondary)', outline: 'none', resize: 'none' }}
                  value={ticketMessage}
                  onChange={(e: React.ChangeEvent<HTMLTextAreaElement>) => setTicketMessage(e.target.value)}
                />
              </div>
              <button 
                type="submit" 
                disabled={sendingTicket}
                className="btn-primary" 
                style={{ width: '100%', padding: '0.8rem', fontWeight: 800, marginTop: '1rem' }}
              >
                {sendingTicket ? 'Enviando...' : 'Enviar Solicitud'}
              </button>
            </form>
          </motion.div>
        </div>
      )}
    </div>
  );
}
