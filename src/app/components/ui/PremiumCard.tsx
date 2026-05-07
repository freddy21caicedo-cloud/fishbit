'use client';

import { motion } from 'framer-motion';

interface PremiumCardProps {
  children: React.ReactNode;
  className?: string;
  style?: React.CSSProperties;
  hover?: boolean;
}

export function PremiumCard({ children, className = '', style = {}, hover = true }: PremiumCardProps) {
  return (
    <motion.div
      whileHover={hover ? { translateY: -4, boxShadow: 'var(--shadow-lg)' } : {}}
      className={`card-premium ${className}`}
      style={{
        padding: '1.5rem',
        borderRadius: 'var(--radius)',
        background: 'var(--card)',
        border: '1px solid var(--border)',
        boxShadow: 'var(--shadow)',
        transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
        ...style
      }}
    >
      {children}
    </motion.div>
  );
}
