'use client';

import { motion } from 'framer-motion';
import { 
  BookOpen, 
  Search, 
  MessageCircle, 
  PlayCircle, 
  HelpCircle,
  ChevronRight,
  Lightbulb,
  ShieldCheck
} from 'lucide-react';

const categories = [
  { id: 1, title: 'Primeros Pasos', icon: BookOpen, color: '#3b82f6', bg: 'rgba(37, 99, 235, 0.05)', count: '5 Guías' },
  { id: 2, title: 'Gestión de Estanques', icon: PlayCircle, color: '#10b981', bg: 'rgba(16, 185, 129, 0.05)', count: '8 Guías' },
  { id: 3, title: 'Configuración Técnica', icon: Lightbulb, color: '#f59e0b', bg: 'rgba(245, 158, 11, 0.05)', count: '4 Guías' },
  { id: 4, title: 'Seguridad y Cuenta', icon: ShieldCheck, color: '#8b5cf6', bg: 'rgba(139, 92, 246, 0.05)', count: '3 Guías' },
];

export default function AyudaPage() {
  return (
    <div className="animate-fade-in">
      <header style={{ marginBottom: '3rem', textAlign: 'center' }}>
        <h1 style={{ fontSize: '2.25rem', fontWeight: 800, marginBottom: '1rem' }}>¿Cómo podemos ayudarte hoy?</h1>
        <div style={{ position: 'relative', maxWidth: '600px', margin: '0 auto' }}>
          <Search size={20} style={{ position: 'absolute', left: '1.25rem', top: '50%', transform: 'translateY(-50%)', color: 'var(--muted-foreground)' }} />
          <input 
            type="text" 
            placeholder="Busca guías, tutoriales o solución de problemas..." 
            style={{ 
              width: '100%', 
              padding: '1rem 1rem 1rem 3.5rem', 
              borderRadius: '50px', 
              border: '1px solid var(--border)', 
              background: 'var(--card)',
              outline: 'none',
              fontSize: '1.1rem',
              boxShadow: 'var(--shadow-sm)'
            }}
          />
        </div>
      </header>

      {/* Categories Grid */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))', gap: '1.5rem', marginBottom: '4rem' }}>
        {categories.map((cat, index) => (
          <motion.div
            key={cat.id}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: index * 0.1 }}
            whileHover={{ y: -5, scale: 1.02 }}
            className="card-premium"
            style={{ padding: '2rem', textAlign: 'center', cursor: 'pointer' }}
          >
            <div style={{ 
              width: '60px', 
              height: '60px', 
              borderRadius: '16px', 
              background: cat.bg, 
              color: cat.color, 
              display: 'flex', 
              alignItems: 'center', 
              justifyContent: 'center',
              margin: '0 auto 1.5rem'
            }}>
              <cat.icon size={30} />
            </div>
            <h3 style={{ fontSize: '1.1rem', fontWeight: 700, marginBottom: '0.5rem' }}>{cat.title}</h3>
            <span style={{ fontSize: '0.875rem', color: 'var(--muted-foreground)', fontWeight: 600 }}>{cat.count}</span>
          </motion.div>
        ))}
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(400px, 1fr))', gap: '2rem' }}>
        {/* Popular Articles */}
        <div>
          <h2 style={{ fontSize: '1.5rem', fontWeight: 700, marginBottom: '1.5rem', display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
            <HelpCircle size={24} style={{ color: 'var(--primary)' }} />
            Artículos Populares
          </h2>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
            {[
              'Cómo crear tu primer estanque',
              'Configuración de alertas de oxígeno',
              'Gestión de inventario de alimento',
              'Interpretación de gráficos de rentabilidad'
            ].map((text, i) => (
              <div 
                key={i} 
                className="glass"
                style={{ 
                  padding: '1.25rem', 
                  borderRadius: '12px', 
                  display: 'flex', 
                  justifyContent: 'space-between', 
                  alignItems: 'center',
                  cursor: 'pointer',
                  border: '1px solid var(--border)'
                }}
              >
                <span style={{ fontWeight: 600 }}>{text}</span>
                <ChevronRight size={18} style={{ color: 'var(--muted-foreground)' }} />
              </div>
            ))}
          </div>
        </div>

        {/* Support Section */}
        <div style={{ 
          background: 'linear-gradient(135deg, var(--primary) 0%, #1e40af 100%)', 
          borderRadius: '24px', 
          padding: '2.5rem', 
          color: 'white',
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'center',
          alignItems: 'center',
          textAlign: 'center'
        }}>
          <div style={{ 
            width: '64px', 
            height: '64px', 
            background: 'rgba(255, 255, 255, 0.2)', 
            borderRadius: '50%', 
            display: 'flex', 
            alignItems: 'center', 
            justifyContent: 'center',
            marginBottom: '1.5rem'
          }}>
            <MessageCircle size={32} />
          </div>
          <h2 style={{ fontSize: '1.75rem', fontWeight: 800, marginBottom: '1rem' }}>¿Aún tienes dudas?</h2>
          <p style={{ opacity: 0.9, marginBottom: '2rem', lineHeight: 1.6 }}>
            Nuestro equipo de soporte técnico está disponible para ayudarte con cualquier problema o consulta que tengas.
          </p>
          <button style={{ 
            background: 'white', 
            color: 'var(--primary)', 
            padding: '1rem 2rem', 
            borderRadius: '50px', 
            border: 'none', 
            fontWeight: 700, 
            fontSize: '1rem',
            cursor: 'pointer',
            boxShadow: '0 10px 15px -3px rgba(0, 0, 0, 0.1)'
          }}>
            Hablar con Soporte
          </button>
        </div>
      </div>
    </div>
  );
}
