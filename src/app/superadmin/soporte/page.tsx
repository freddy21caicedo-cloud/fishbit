'use client';

import { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import { supabase } from '@/lib/supabase';
import { 
  MessageSquare, 
  Search, 
  Clock, 
  CheckCircle2, 
  AlertCircle, 
  Loader2,
  Filter,
  User,
  MoreVertical,
  Flag
} from 'lucide-react';

export default function SupportManagementPage() {
  const [tickets, setTickets] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchTickets();
  }, []);

  const fetchTickets = async () => {
    setLoading(true);
    const { data, error } = await supabase
      .from('support_tickets')
      .select(`
        *,
        profiles:user_id(full_name)
      `)
      .order('created_at', { ascending: false });

    if (!error) setTickets(data);
    setLoading(false);
  };

  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case 'urgent': return '#ef4444';
      case 'high': return '#f59e0b';
      case 'medium': return '#3b82f6';
      default: return '#64748b';
    }
  };

  if (loading) {
    return (
      <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <Loader2 className="animate-spin" size={40} color="var(--primary)" />
      </div>
    );
  }

  return (
    <div style={{ padding: '2rem', maxWidth: '1200px', margin: '0 auto' }}>
      <header style={{ marginBottom: '3rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <h1 style={{ fontSize: '2rem', fontWeight: 800, marginBottom: '0.5rem' }}>Tickets de Soporte</h1>
          <p style={{ color: 'var(--muted-foreground)' }}>Atención al cliente y resolución de incidencias técnicas.</p>
        </div>
        <div style={{ display: 'flex', gap: '1rem' }}>
          <button className="btn-primary" style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', padding: '0.75rem 1.5rem' }}>
            <Filter size={18} />
            Filtrar Tickets
          </button>
        </div>
      </header>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr', gap: '1rem' }}>
        {tickets.length > 0 ? tickets.map((ticket) => (
          <motion.div 
            key={ticket.id}
            initial={{ opacity: 0, x: -10 }}
            animate={{ opacity: 1, x: 0 }}
            className="card-premium"
            style={{ padding: '1.25rem', display: 'flex', alignItems: 'center', gap: '1.5rem', cursor: 'pointer', transition: 'all 0.2s ease' }}
            onMouseEnter={(e) => e.currentTarget.style.borderColor = 'var(--primary)'}
            onMouseLeave={(e) => e.currentTarget.style.borderColor = 'transparent'}
          >
            <div style={{ 
              width: '48px', 
              height: '48px', 
              background: 'var(--secondary)', 
              borderRadius: '12px', 
              display: 'flex', 
              alignItems: 'center', 
              justifyContent: 'center', 
              color: getPriorityColor(ticket.priority)
            }}>
              <Flag size={24} />
            </div>

            <div style={{ flex: 1 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '0.25rem' }}>
                <h3 style={{ fontSize: '1.125rem', fontWeight: 700 }}>{ticket.subject}</h3>
                <span style={{ 
                  padding: '0.2rem 0.6rem', 
                  borderRadius: '12px', 
                  background: 'rgba(37, 99, 235, 0.1)', 
                  color: 'var(--primary)', 
                  fontSize: '0.65rem', 
                  fontWeight: 800,
                  textTransform: 'uppercase'
                }}>
                  {ticket.status}
                </span>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', color: 'var(--muted-foreground)', fontSize: '0.875rem' }}>
                <span style={{ display: 'flex', alignItems: 'center', gap: '0.25rem' }}>
                  <User size={14} />
                  {ticket.profiles?.full_name || 'Usuario desconocido'}
                </span>
                <span style={{ display: 'flex', alignItems: 'center', gap: '0.25rem' }}>
                  <Clock size={14} />
                  {new Date(ticket.created_at).toLocaleString()}
                </span>
              </div>
            </div>

            <div style={{ display: 'flex', alignItems: 'center', gap: '1.5rem' }}>
              <div style={{ textAlign: 'right' }}>
                <div style={{ fontSize: '0.7rem', fontWeight: 800, color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Prioridad</div>
                <div style={{ fontWeight: 700, color: getPriorityColor(ticket.priority), textTransform: 'capitalize' }}>{ticket.priority}</div>
              </div>
              <button style={{ background: 'none', border: 'none', color: 'var(--muted-foreground)', cursor: 'pointer' }}>
                <MoreVertical size={20} />
              </button>
            </div>
          </motion.div>
        )) : (
          <div className="card-premium" style={{ padding: '4rem', textAlign: 'center', color: 'var(--muted-foreground)' }}>
            <MessageSquare size={48} style={{ margin: '0 auto 1rem', opacity: 0.2 }} />
            <h3 style={{ fontSize: '1.25rem', fontWeight: 700, color: 'var(--foreground)' }}>Bandeja Vacía</h3>
            <p>No tienes tickets de soporte pendientes en este momento.</p>
          </div>
        )}
      </div>
    </div>
  );
}
