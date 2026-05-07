'use client';

import { useState, useMemo, useEffect } from 'react';
import { toast } from 'react-hot-toast';
import { supabase } from '@/lib/supabase';
import { useUnit } from '../components/providers/UnitProvider';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  ShoppingBag, 
  FlaskConical, 
  Beaker, 
  Fish, 
  Wind,
  Plus,
  Search,
  Package,
  TrendingUp,
  FileText,
  UserPlus
} from 'lucide-react';

// Components
import { InventoryTable } from './components/InventoryTable';
import { InvoicesTable } from './components/InvoicesTable';
import { InvoiceModal } from './components/InvoiceModal';
import { ProviderModal } from './components/ProviderModal';
import { PremiumCard } from '../components/ui/PremiumCard';
import { PremiumInput } from '../components/ui/PremiumInput';

interface InventoryItem {
  id: string;
  name: string;
  category: string;
  current_stock: string | number;
  unit: string;
  last_entry?: string;
  lote?: string;
  costo_promedio?: number;
}

export default function AlmacenPage() {
  const { activeUnitId } = useUnit();
  const [activeCat, setActiveCat] = useState('alimento');
  const [viewMode, setViewMode] = useState<'inventory' | 'invoices'>('inventory');
  const [isInvoiceModalOpen, setIsInvoiceModalOpen] = useState(false);
  const [isProviderModalOpen, setIsProviderModalOpen] = useState(false);
  const [isBadgeHovered, setIsBadgeHovered] = useState(false);
  const [inventory, setInventory] = useState<InventoryItem[]>([]);
  const [searchQuery, setSearchQuery] = useState('');
  const [isLoading, setIsLoading] = useState(true);

  // Providers & Invoices State
  const [providers, setProviders] = useState<any[]>([]);
  const [invoices, setInvoices] = useState<any[]>([]);

  useEffect(() => {
    if (activeUnitId) {
      fetchInventory(activeUnitId);
      fetchInvoices(activeUnitId);
      fetchProviders(activeUnitId);
    }
  }, [activeUnitId]);

  const fetchProviders = async (unitId: string) => {
    const { data } = await supabase.from('providers').select('*').eq('unit_id', unitId).order('name');
    if (data) setProviders(data);
  };

  const fetchInventory = async (unitId: string) => {
    setIsLoading(true);
    try {
      // 1. Traer inventario base
      const { data: invData, error: invError } = await supabase.from('inventory').select('*').eq('unit_id', unitId);
      if (invError) throw invError;

      // 2. Traer historial de ítems para cálculos de Lote y Costo Promedio
      const { data: historyData } = await supabase
        .from('invoice_items')
        .select('product_name, batch, unit_price, created_at')
        .eq('unit_id', unitId)
        .order('created_at', { ascending: false });

      // 3. Procesar datos combinados
      const processedInventory = (invData || []).map(item => {
        const itemHistory = (historyData || []).filter(h => h.product_name === item.name);
        
        // Último lote registrado
        const latestBatch = itemHistory[0]?.batch || 'N/A';
        
        // Costo promedio histórico
        const totalCost = itemHistory.reduce((sum, h) => sum + (Number(h.unit_price) || 0), 0);
        const avgCost = itemHistory.length > 0 ? totalCost / itemHistory.length : 0;

        return {
          ...item,
          lote: latestBatch,
          costo_promedio: avgCost
        };
      });

      setInventory(processedInventory);
    } catch (error: any) {
      toast.error("Error al cargar inventario");
    } finally {
      setIsLoading(false);
    }
  };

  const fetchInvoices = async (unitId: string) => {
    try {
      const { data, error } = await supabase.from('invoices').select(`*, providers (name)`).eq('unit_id', unitId).order('date', { ascending: false });
      if (error) throw error;
      setInvoices(data || []);
    } catch (error: any) {
      console.error("Error al cargar facturas");
    }
  };

  const categories = useMemo(() => [
    { 
      id: 'alimento', label: 'Alimento', icon: ShoppingBag, color: '#10b981', bg: 'rgba(16, 185, 129, 0.1)', 
      stock: inventory.filter(i => i.category === 'alimento').reduce((sum, i) => sum + (Number(i.current_stock) || 0), 0),
      unit: 'kg'
    },
    { 
      id: 'farmacia', label: 'Farmacia', icon: FlaskConical, color: '#8b5cf6', bg: 'rgba(139, 92, 246, 0.1)', 
      stock: inventory.filter(i => i.category === 'farmacia').reduce((sum, i) => sum + (Number(i.current_stock) || 0), 0),
      unit: 'Und'
    },
    { 
      id: 'insumos', label: 'Insumos', icon: Beaker, color: '#0ea5e9', bg: 'rgba(14, 165, 233, 0.1)', 
      stock: inventory.filter(i => i.category === 'insumos').reduce((sum, i) => sum + (Number(i.current_stock) || 0), 0),
      unit: 'Kg/Lt'
    },
    { 
      id: 'alevinos', label: 'Alevinos', icon: Fish, color: '#f43f5e', bg: 'rgba(244, 63, 94, 0.1)', 
      stock: inventory.filter(i => i.category === 'alevinos').reduce((sum, i) => sum + (Number(i.current_stock) || 0), 0),
      unit: 'Und'
    },
    { 
      id: 'aireadores', label: 'Aireadores', icon: Wind, color: '#f59e0b', bg: 'rgba(245, 158, 11, 0.1)', 
      stock: inventory.filter(i => i.category === 'aireadores').reduce((sum, i) => sum + (Number(i.current_stock) || 0), 0),
      unit: 'Und'
    }
  ], [inventory]);

  const currentCategory = categories.find(c => c.id === activeCat);
  const nearExpiryCount = useMemo(() => {
    const today = new Date();
    return invoices.filter(inv => {
      if (inv.status === 'pagada') return false;
      const vDate = new Date(inv.date);
      if (inv.credit_days) vDate.setDate(vDate.getDate() + inv.credit_days);
      const diffDays = Math.ceil((vDate.getTime() - today.getTime()) / (1000 * 60 * 60 * 24));
      return diffDays <= 3;
    }).length;
  }, [invoices]);

  const filteredInventory = useMemo(() => {
    return inventory.filter(item => 
      item.category === activeCat && item.name.toLowerCase().includes(searchQuery.toLowerCase())
    );
  }, [inventory, activeCat, searchQuery]);

  return (
    <div className="animate-fade-in page-container" style={{ padding: '1rem' }}>
      <header style={{ marginBottom: '2rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem' }}>
        <div>
          <h1 style={{ fontWeight: 900, fontSize: 'clamp(1.5rem, 5vw, 2.25rem)' }}>Almacén e Inventario</h1>
          <p style={{ color: 'var(--muted-foreground)' }}>Gestión centralizada de abastecimiento y stock.</p>
        </div>
        <div style={{ display: 'flex', gap: '0.75rem' }}>
          <button onClick={() => setIsProviderModalOpen(true)} className="glass" style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', padding: '0.6rem 1rem', borderRadius: '10px', border: '1px solid var(--border)', fontWeight: 700, cursor: 'pointer' }}>
            <UserPlus size={18} /> <span className="hidden md:inline">Proveedores</span>
          </button>
        </div>
      </header>

      {/* Responsive Top Tabs (Categories) */}
      <div style={{ 
        display: 'flex', 
        gap: '1rem', 
        marginBottom: '2rem', 
        overflowX: 'auto', 
        paddingBottom: '1rem',
        scrollbarWidth: 'none', 
        msOverflowStyle: 'none' 
      }} className="no-scrollbar">
        {categories.map((cat) => (
          <button
            key={cat.id}
            onClick={() => setActiveCat(cat.id)}
            style={{
              flexShrink: 0,
              padding: '1rem 1.5rem',
              borderRadius: '20px',
              border: '2px solid',
              borderColor: activeCat === cat.id ? cat.color : 'var(--border)',
              background: activeCat === cat.id ? 'white' : 'var(--card)',
              boxShadow: activeCat === cat.id ? `0 10px 20px ${cat.bg}` : 'none',
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              gap: '1rem',
              transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
              minWidth: '200px'
            }}
          >
            <div style={{ background: cat.bg, color: cat.color, padding: '0.75rem', borderRadius: '15px' }}>
              <cat.icon size={24} />
            </div>
            <div style={{ textAlign: 'left' }}>
              <div style={{ fontSize: '0.85rem', fontWeight: 800, color: activeCat === cat.id ? 'var(--foreground)' : 'var(--muted-foreground)' }}>{cat.label}</div>
              <div style={{ fontSize: '1.1rem', fontWeight: 950, color: cat.color }}>{cat.stock.toLocaleString()} <span style={{ fontSize: '0.7rem', opacity: 0.7 }}>{cat.unit}</span></div>
            </div>
          </button>
        ))}
      </div>

      <div className="card-premium" style={{ width: '100%', overflow: 'hidden' }}>
        <div style={{ padding: '1.5rem', borderBottom: '1px solid var(--border)', display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
            <div style={{ background: currentCategory?.bg, color: currentCategory?.color, padding: '0.6rem', borderRadius: '12px' }}>
              {currentCategory && <currentCategory.icon size={20} />}
            </div>
            <h3 style={{ fontSize: '1.25rem', fontWeight: 900 }}>Detalle de {currentCategory?.label}</h3>
          </div>
          
          <div style={{ display: 'flex', gap: '0.75rem', width: '100%', maxWidth: 'none', justifyContent: 'flex-end' }} className="flex-col md:flex-row">
            <button 
              onClick={() => setIsInvoiceModalOpen(true)}
              className="btn-primary"
              style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', padding: '0.6rem 1.25rem', borderRadius: '10px', fontWeight: 800, fontSize: '0.8rem', justifyContent: 'center' }}
            >
              <Plus size={18} /> Nueva Factura de {currentCategory?.label}
            </button>
            
            <button 
              onClick={() => setViewMode(viewMode === 'inventory' ? 'invoices' : 'inventory')}
              className="glass" 
              style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', padding: '0.6rem 1.25rem', borderRadius: '10px', border: '1px solid var(--border)', fontWeight: 800, fontSize: '0.8rem', background: viewMode === 'invoices' ? 'rgba(37, 99, 235, 0.1)' : 'white', color: viewMode === 'invoices' ? 'var(--primary)' : 'var(--foreground)', position: 'relative', justifyContent: 'center' }}
            >
              {viewMode === 'inventory' ? <FileText size={18} /> : <Package size={18} />}
              {viewMode === 'inventory' ? 'Mis Facturas' : 'Ver Inventario'}
              
              {nearExpiryCount > 0 && viewMode === 'inventory' && (
                <div 
                  onMouseEnter={() => setIsBadgeHovered(true)} onMouseLeave={() => setIsBadgeHovered(false)}
                  style={{ position: 'absolute', top: '-6px', right: '-6px', background: '#ef4444', color: 'white', fontSize: '0.65rem', fontWeight: 900, width: '18px', height: '18px', borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center', border: '2px solid white', boxShadow: '0 2px 4px rgba(0,0,0,0.2)' }}
                >
                  {nearExpiryCount}
                  <AnimatePresence>
                    {isBadgeHovered && (
                      <motion.div initial={{ opacity: 0, y: -10 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -5 }} style={{ position: 'absolute', top: '100%', left: '50%', transform: 'translateX(-50%)', marginTop: '10px', padding: '6px 10px', background: 'rgba(0, 0, 0, 0.9)', color: 'white', fontSize: '0.7rem', fontWeight: 700, borderRadius: '6px', whiteSpace: 'nowrap', zIndex: 100 }}>
                        Facturas por vencer
                      </motion.div>
                    )}
                  </AnimatePresence>
                </div>
              )}
            </button>
          </div>
        </div>

        <div style={{ padding: '0.75rem 1.5rem', background: 'rgba(37, 99, 235, 0.02)', borderBottom: '1px solid var(--border)', display: 'flex', gap: '1.5rem' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <Package size={14} style={{ color: 'var(--muted-foreground)' }} />
            <span style={{ fontSize: '0.75rem', fontWeight: 600 }}>{viewMode === 'inventory' ? `Items: ${filteredInventory.length}` : `Facturas: ${invoices.length}`}</span>
          </div>
        </div>

        {viewMode === 'inventory' ? (
          <>
            <div style={{ padding: '1rem 1.5rem' }}>
              <PremiumInput label={`Buscar en ${currentCategory?.label}...`} icon={Search} value={searchQuery} onChange={(e) => setSearchQuery(e.target.value)} />
            </div>
            <InventoryTable items={filteredInventory} category={activeCat} />
          </>
        ) : (
          <InvoicesTable 
            invoices={invoices.filter(i => i.category === activeCat)} 
            onRefresh={() => activeUnitId && fetchInvoices(activeUnitId)} 
          />
        )}
      </div>

      <InvoiceModal 
        isOpen={isInvoiceModalOpen} onClose={() => setIsInvoiceModalOpen(false)}
        unitId={activeUnitId || ''} activeCat={activeCat} providers={providers}
        onSuccess={() => activeUnitId && (fetchInvoices(activeUnitId), fetchInventory(activeUnitId))}
      />

      <ProviderModal
        isOpen={isProviderModalOpen}
        onClose={() => setIsProviderModalOpen(false)}
        unitId={activeUnitId || ''}
        onSuccess={() => activeUnitId && fetchProviders(activeUnitId)}
      />
    </div>
  );
}
