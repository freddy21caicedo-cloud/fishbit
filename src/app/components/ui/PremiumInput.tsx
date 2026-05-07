'use client';

import { LucideIcon } from 'lucide-react';

interface PremiumInputProps extends React.InputHTMLAttributes<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement> {
  label: string;
  icon?: LucideIcon;
  as?: 'input' | 'select' | 'textarea';
  options?: { value: string; label: string }[];
  rows?: number;
  cols?: number;
}

export function PremiumInput({ 
  label, 
  icon: Icon, 
  as = 'input', 
  options = [], 
  className = '', 
  rows,
  cols,
  ...props 
}: PremiumInputProps) {
  const Component = as as any;

  return (
    <div className="premium-input-group">
      <label className="premium-label">
        {label}
      </label>
      <div className="premium-input-wrapper">
        {Icon && <Icon size={18} className="premium-input-icon" />}
        {as === 'input' ? (
          <input 
            className={`premium-input ${className}`}
            {...(props as React.InputHTMLAttributes<HTMLInputElement>)}
          />
        ) : as === 'select' ? (
          <select 
            className={`premium-input ${className}`}
            {...(props as React.SelectHTMLAttributes<HTMLSelectElement>)}
          >
            {options.map(opt => (
              <option key={opt.value} value={opt.value}>{opt.label}</option>
            ))}
            {props.children}
          </select>
        ) : (
          <textarea 
            className={`premium-input ${className}`}
            rows={rows}
            cols={cols}
            {...(props as React.TextareaHTMLAttributes<HTMLTextAreaElement>)}
          />
        )}
      </div>
    </div>
  );
}
