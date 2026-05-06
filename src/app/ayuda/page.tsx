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
  ShieldCheck,
  LifeBuoy
} from 'lucide-react';

const categories = [
  { id: 1, title: 'Primeros Pasos', icon: BookOpen, color: '#0d9488', bg: 'rgba(13, 148, 136, 0.05)', count: '5 Guías' },
  { id: 2, title: 'Gestión de Estanques', icon: PlayCircle, color: '#3b82f6', bg: 'rgba(59, 130, 246, 0.05)', count: '8 Guías' },
  { id: 3, title: 'Configuración Técnica', icon: Lightbulb, color: '#f59e0b', bg: 'rgba(245, 158, 11, 0.05)', count: '4 Guías' },
  { id: 4, title: 'Seguridad y Cuenta', icon: ShieldCheck, color: '#8b5cf6', bg: 'rgba(139, 92, 246, 0.05)', count: '3 Guías' },
];

export default function AyudaPage() {
  return (
    <div className="animate-fade-in page-container">
      <header style={{ marginBottom: '4rem', textAlign: 'center' }}>
        <div style={{ 
          width: '56px', 
          height: '56px', 
          background: '#0d9488', 
          borderRadius: '16px', 
          display: 'flex', 
          alignItems: 'center', 
          justifyContent: 'center',
          margin: '0 auto 1.5rem',
          color: 'white',
          boxShadow: '0 10px 25px rgba(13, 148, 136, 0.2)'
        }}>
          <LifeBuoy size={32} />
        </div>
        <h1 style={{ fontSize: '2.75rem', fontWeight: 950, marginBottom: '1.25rem', letterSpacing: '-0.04em' }}>Centro de Ayuda</h1>
        <p style={{ color: 'var(--muted-foreground)', fontWeight: 600, fontSize: '1.1rem', marginBottom: '2.5rem' }}>¿En qué podemos apoyarte con tu producción hoy?</p>
        
        <div style={{ position: 'relative', maxWidth: '650px', margin: '0 auto' }}>
          <Search size={22} style={{ position: 'absolute', left: '1.5rem', top: '50%', transform: 'translateY(-50%)', color: 'var(--muted-foreground)' }} />
          <input 
            type="text" 
            placeholder="Busca guías, tutoriales o soluciones..." 
            className="premium-input"
            style={{ 
              paddingLeft: '4rem',
              borderRadius: '50px', 
              fontSize: '1.1rem',
              fontWeight: 600,
              boxShadow: 'var(--shadow-md)'
            }}
          />
        </div>
      </header>

      {/* Categories Grid */}
      <div className="responsive-grid-4" style={{ marginBottom: '4rem' }}>
        {categories.map((cat, index) => (
          <motion.div
            key={cat.id}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: index * 0.1 }}
            whileHover={{ y: -8, scale: 1.02 }}
            className="card-premium"
            style={{ padding: '2.5rem', textAlign: 'center', cursor: 'pointer', border: '1px solid var(--border)' }}
          >
            <div style={{ 
              width: '64px', 
              height: '64px', 
              borderRadius: '20px', 
              background: cat.bg, 
              color: cat.color, 
              display: 'flex', 
              alignItems: 'center', 
              justifyContent: 'center',
              margin: '0 auto 1.5rem'
            }}>
              <cat.icon size={32} />
            </div>
            <h3 style={{ fontSize: '1.15rem', fontWeight: 900, marginBottom: '0.5rem', letterSpacing: '-0.02em' }}>{cat.title}</h3>
            <span style={{ fontSize: '0.85rem', color: 'var(--muted-foreground)', fontWeight: 800, textTransform: 'uppercase', letterSpacing: '0.05em' }}>{cat.count}</span>
          </motion.div>
        ))}
      </div>

      <div className="responsive-grid-2" style={{ gap: '3rem' }}>
        {/* Popular Articles */}
        <div>
          <h2 style={{ fontSize: '1.6rem', fontWeight: 950, marginBottom: '2rem', display: 'flex', alignItems: 'center', gap: '0.8rem', letterSpacing: '-0.03em' }}>
            <HelpCircle size={28} style={{ color: '#0d9488' }} />
            Artículos Destacados
          </h2>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
            {[
              'Guía de inicio rápido para nuevos operarios',
              'Cómo calibrar tus sensores de oxígeno',
              'Optimización del factor de conversión (FCA)',
              'Gestión de inventarios y alertas de stock bajo'
            ].map((text, i) => (
              <div 
                key={i} 
                className="glass"
                style={{ 
                  padding: '1.5rem', 
                  borderRadius: '18px', 
                  display: 'flex', 
                  justifyContent: 'space-between', 
                  alignItems: 'center',
                  cursor: 'pointer',
                  border: '1px solid var(--border)',
                  transition: 'all 0.2s ease'
                }}
                onMouseEnter={(e) => {
                  e.currentTarget.style.borderColor = '#0d9488';
                  e.currentTarget.style.background = 'var(--card)';
                }}
                onMouseLeave={(e) => {
                  e.currentTarget.style.borderColor = 'var(--border)';
                  e.currentTarget.style.background = 'transparent';
                }}
              >
                <span style={{ fontWeight: 800, fontSize: '0.95rem' }}>{text}</span>
                <ChevronRight size={20} style={{ color: 'var(--muted-foreground)' }} />
              </div>
            ))}
          </div>
        </div>

        {/* Support Section */}
        <div style={{ 
          background: 'linear-gradient(135deg, #0d9488 0%, #065f46 100%)', 
          borderRadius: '32px', 
          padding: '3.5rem', 
          color: 'white',
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'center',
          alignItems: 'center',
          textAlign: 'center',
          boxShadow: '0 25px 50px -12px rgba(13, 148, 136, 0.4)'
        }}>
          <div style={{ 
            width: '72px', 
            height: '72px', 
            background: 'rgba(255, 255, 255, 0.15)', 
            borderRadius: '24px', 
            display: 'flex', 
            alignItems: 'center', 
            justifyContent: 'center',
            marginBottom: '2rem',
            backdropFilter: 'blur(10px)'
          }}>
            <MessageCircle size={36} />
          </div>
          <h2 style={{ fontSize: '2rem', fontWeight: 950, marginBottom: '1rem', letterSpacing: '-0.04em' }}>Asistencia Directa</h2>
          <p style={{ opacity: 0.9, marginBottom: '2.5rem', lineHeight: 1.6, fontWeight: 600, fontSize: '1.05rem' }}>
            Si no encuentras lo que buscas, nuestro equipo técnico está listo para asistirte en tiempo real.
          </p>
          <button style={{ 
            background: 'white', 
            color: '#0d9488', 
            padding: '1.25rem 2.5rem', 
            borderRadius: '18px', 
            border: 'none', 
            fontWeight: 900, 
            fontSize: '1rem',
            cursor: 'pointer',
            boxShadow: '0 15px 30px rgba(0, 0, 0, 0.15)',
            transition: 'transform 0.2s ease'
          }}
          onMouseEnter={(e) => e.currentTarget.style.transform = 'translateY(-3px)'}
          onMouseLeave={(e) => e.currentTarget.style.transform = 'translateY(0)'}
          >
            Hablar con un Experto
          </button>
        </div>
      </div>
    </div>
  );
}
