'use client';

import { motion, AnimatePresence } from 'framer-motion';
import { LucideIcon } from 'lucide-react';
import { useState } from 'react';

interface Category {
  id: string;
  label: string;
  icon: LucideIcon;
  color: string;
  bg: string;
  stock: number;
  unit: string;
}

interface CategorySidebarProps {
  categories: Category[];
  activeCat: string;
  onCategoryChange: (id: string) => void;
  isCollapsed: boolean;
}

export function CategorySidebar({ categories, activeCat, onCategoryChange, isCollapsed }: CategorySidebarProps) {
  const [hoveredCatId, setHoveredCatId] = useState<string | null>(null);

  return (
    <div className="almacen-sidebar-categories" style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
      <h3 style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--muted-foreground)', textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: '0.5rem' }}>
        Categorías de Almacén
      </h3>
      {categories.map(cat => (
        <button
          key={cat.id}
          onClick={() => onCategoryChange(cat.id)}
          onMouseEnter={() => setHoveredCatId(cat.id)}
          onMouseLeave={() => setHoveredCatId(null)}
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: isCollapsed ? '0' : '1rem',
            padding: isCollapsed ? '0.75rem' : '1rem',
            justifyContent: isCollapsed ? 'center' : 'flex-start',
            borderRadius: '12px',
            border: '1px solid',
            borderColor: activeCat === cat.id ? 'var(--primary)' : 'var(--border)',
            background: activeCat === cat.id ? 'rgba(37, 99, 235, 0.05)' : 'var(--card)',
            color: activeCat === cat.id ? 'var(--primary)' : 'var(--foreground)',
            cursor: 'pointer',
            textAlign: 'left',
            transition: 'all 0.2s ease',
            position: 'relative',
            overflow: 'visible',
            minWidth: isCollapsed ? '50px' : 'auto'
          }}
        >
          <div style={{ 
            width: '40px', 
            height: '40px', 
            borderRadius: '8px', 
            background: cat.bg, 
            color: cat.color,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            flexShrink: 0
          }}>
            <cat.icon size={20} />
          </div>
          {!isCollapsed && (
            <div style={{ flex: 1, overflow: 'hidden' }}>
              <div style={{ fontWeight: 700, fontSize: '0.9rem' }}>{cat.label}</div>
              <div style={{ fontSize: '0.75rem', fontWeight: 800, color: cat.stock === 0 ? '#ef4444' : 'var(--muted-foreground)', marginTop: '0.2rem' }}>
                {cat.stock.toLocaleString()} {cat.unit}
              </div>
            </div>
          )}

          <AnimatePresence>
            {isCollapsed && hoveredCatId === cat.id && (
              <motion.div
                initial={{ opacity: 0, x: -10, scale: 0.9 }}
                animate={{ opacity: 1, x: 10, scale: 1 }}
                exit={{ opacity: 0, x: -5, scale: 0.9 }}
                style={{
                  position: 'absolute',
                  left: '100%',
                  marginLeft: '15px',
                  padding: '8px 12px',
                  background: 'rgba(0, 0, 0, 0.9)',
                  color: 'white',
                  fontSize: '0.8rem',
                  fontWeight: 800,
                  borderRadius: '8px',
                  whiteSpace: 'nowrap',
                  pointerEvents: 'none',
                  boxShadow: '0 10px 20px rgba(0,0,0,0.3)',
                  zIndex: 9999,
                  display: 'flex',
                  alignItems: 'center'
                }}
              >
                {cat.label}
                <div style={{
                  position: 'absolute',
                  right: '100%',
                  top: '50%',
                  transform: 'translateY(-50%)',
                  borderTop: '6px solid transparent',
                  borderBottom: '6px solid transparent',
                  borderRight: '6px solid rgba(0, 0, 0, 0.9)'
                }} />
              </motion.div>
            )}
          </AnimatePresence>
        </button>
      ))}
    </div>
  );
}
