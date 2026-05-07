'use client';

import { motion, AnimatePresence } from 'framer-motion';
import { Users, X, UserPlus, Loader2 } from 'lucide-react';
import { useState } from 'react';
import { supabase } from '@/lib/supabase';
import { toast } from 'react-hot-toast';
import { PremiumInput } from '../../components/ui/PremiumInput';

interface ProviderModalProps {
  isOpen: boolean;
  onClose: () => void;
  unitId: string;
  onSuccess: () => void;
}

export function ProviderModal({ isOpen, onClose, unitId, onSuccess }: ProviderModalProps) {
  const [loading, setLoading] = useState(false);
  const [newProvider, setNewProvider] = useState({ name: '', nit: '', types: [] as string[] });

  const saveProvider = async () => {
    if (!newProvider.name || !newProvider.nit) {
      toast.error("Por favor complete nombre y NIT.");
      return;
    }

    setLoading(true);
    try {
      const { error } = await supabase.from('providers').insert([{
        ...newProvider,
        unit_id: unitId
      }]);

      if (error) {
        if (error.code === '23505') toast.error("Ya existe un proveedor con este NIT.");
        else throw error;
        return;
      }

      toast.success("¡Proveedor registrado!");
      setNewProvider({ name: '', nit: '', types: [] });
      onSuccess();
      onClose();
    } catch (error: any) {
      toast.error("Error: " + error.message);
    } finally {
      setLoading(false);
    }
  };

  if (!isOpen) return null;

  return (
    <div style={{ position: 'fixed', inset: 0, zIndex: 1000, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '1rem' }}>
      <motion.div 
        initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
        onClick={onClose}
        style={{ position: 'absolute', inset: 0, background: 'rgba(255,255,255,0.1)', backdropFilter: 'blur(20px)' }} 
      />
      <motion.div 
        initial={{ scale: 0.9, opacity: 0, y: 30 }} animate={{ scale: 1, opacity: 1, y: 0 }}
        className="card-premium" 
        style={{ width: '100%', maxWidth: '450px', position: 'relative', zIndex: 10, padding: '2.5rem', boxShadow: '0 0 80px rgba(0,0,0,0.2)' }}
      >
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '2rem' }}>
          <h2 style={{ fontSize: '1.5rem', fontWeight: 800, display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
            <Users size={28} style={{ color: 'var(--primary)' }} /> Nuevo Proveedor
          </h2>
          <button onClick={onClose} style={{ background: 'transparent', border: 'none', color: 'var(--muted-foreground)', cursor: 'pointer' }}><X size={24} /></button>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
          <PremiumInput label="Nombre de Empresa / Persona" placeholder="Ej: Italcol S.A." value={newProvider.name} onChange={(e) => setNewProvider({...newProvider, name: e.target.value})} />
          <PremiumInput label="NIT o Cédula" placeholder="900.123.456-7" value={newProvider.nit} onChange={(e) => setNewProvider({...newProvider, nit: e.target.value})} />

          <div>
            <label className="premium-label">Categorías que Suministra</label>
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: '0.5rem' }}>
              {['alimento', 'farmacia', 'insumos', 'alevinos', 'equipos'].map(type => (
                <button
                  key={type}
                  onClick={() => {
                    const types = newProvider.types.includes(type) ? newProvider.types.filter(t => t !== type) : [...newProvider.types, type];
                    setNewProvider({...newProvider, types});
                  }}
                  style={{
                    padding: '0.5rem 0.75rem', borderRadius: '10px', border: '1.5px solid', 
                    borderColor: newProvider.types.includes(type) ? 'var(--primary)' : 'var(--border)',
                    background: newProvider.types.includes(type) ? 'rgba(13, 148, 136, 0.05)' : 'white',
                    color: newProvider.types.includes(type) ? 'var(--primary)' : 'var(--muted-foreground)',
                    fontSize: '0.75rem', fontWeight: 800, cursor: 'pointer', textTransform: 'capitalize'
                  }}
                >
                  {type}
                </button>
              ))}
            </div>
          </div>
          
          <button onClick={saveProvider} className="btn-primary" style={{ width: '100%', padding: '1rem' }} disabled={loading}>
            {loading ? <Loader2 className="animate-spin" /> : 'Registrar Proveedor'}
          </button>
        </div>
      </motion.div>
    </div>
  );
}
