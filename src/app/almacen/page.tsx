import { useState, useMemo, useEffect, useRef } from 'react';

export default function AlmacenPage() {
  const { activeUnitId } = useUnit();
  const [activeCat, setActiveCat] = useState('alimento');
  const [isInvoiceModalOpen, setIsInvoiceModalOpen] = useState(false);
  const [isProviderModalOpen, setIsProviderModalOpen] = useState(false);
  const [isBadgeHovered, setIsBadgeHovered] = useState(false);
  const [inventory, setInventory] = useState<InventoryItem[]>([]);
  const [searchQuery, setSearchQuery] = useState('');
  const [isLoading, setIsLoading] = useState(true);

  // Refs for scrolling
  const section1Ref = useRef<HTMLDivElement>(null);
  const section2Ref = useRef<HTMLDivElement>(null);
  const section3Ref = useRef<HTMLDivElement>(null);

  // Responsive Hook
  const [isMobile, setIsMobile] = useState(false);
  useEffect(() => {
    const check = () => setIsMobile(window.innerWidth < 768);
    check();
    window.addEventListener('resize', check);
    return () => window.removeEventListener('resize', check);
  }, []);

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
      const { data: invData, error: invError } = await supabase.from('inventory').select('*').eq('unit_id', unitId);
      if (invError) throw invError;
      const { data: historyData } = await supabase
        .from('invoice_items')
        .select('product_name, batch, unit_price, created_at')
        .eq('unit_id', unitId)
        .order('created_at', { ascending: false });
      const processedInventory = (invData || []).map(item => {
        const itemHistory = (historyData || []).filter(h => h.product_name === item.name);
        const latestBatch = itemHistory[0]?.batch || 'N/A';
        const totalCost = itemHistory.reduce((sum, h) => sum + (Number(h.unit_price) || 0), 0);
        const avgCost = itemHistory.length > 0 ? totalCost / itemHistory.length : 0;
        return { ...item, lote: latestBatch, costo_promedio: avgCost };
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

  const handleCategorySelect = (id: string) => {
    setActiveCat(id);
    setTimeout(() => {
      section2Ref.current?.scrollIntoView({ behavior: 'smooth' });
    }, 100);
  };

  const scrollToTop = () => {
    section1Ref.current?.scrollIntoView({ behavior: 'smooth' });
  };

  const Separator = () => (
    <div style={{
      margin: '2.5rem 0',
      height: '2px',
      background: 'linear-gradient(to right, transparent, var(--border), transparent)'
    }} />
  );

  return (
    <div className="animate-fade-in page-container" style={{ padding: isMobile ? '0.5rem' : '2rem' }}>
      
      {/* Sección 1: Hero de Categorías */}
      <section ref={section1Ref} style={{ marginBottom: '3rem' }}>
        <header style={{ 
          marginBottom: '2rem', 
          display: 'flex', 
          justifyContent: 'space-between', 
          alignItems: 'center',
          position: isMobile ? 'sticky' : 'static',
          top: 0,
          zIndex: 100,
          background: isMobile ? 'var(--background)' : 'transparent',
          padding: isMobile ? '1rem 0' : 0
        }}>
          <div>
            <h1 style={{ fontWeight: 950, fontSize: isMobile ? '1.5rem' : '2.5rem', letterSpacing: '-0.03em' }}>Almacén Central</h1>
            {!isMobile && <p style={{ color: 'var(--muted-foreground)' }}>Stock consolidado de la granja.</p>}
          </div>
          <button 
            onClick={() => setIsProviderModalOpen(true)} 
            className="glass" 
            style={{ 
              display: 'flex', 
              alignItems: 'center', 
              gap: '0.5rem', 
              padding: '0.75rem 1.25rem', 
              borderRadius: '12px', 
              border: '1px solid var(--border)', 
              fontWeight: 800, 
              cursor: 'pointer',
              background: 'white',
              boxShadow: 'var(--shadow-sm)'
            }}
          >
            <UserPlus size={18} /> <span>{isMobile ? '' : 'Proveedores'}</span>
          </button>
        </header>

        <div style={{ 
          display: 'grid', 
          gridTemplateColumns: isMobile ? 'repeat(2, 1fr)' : 'repeat(5, 1fr)', 
          gap: isMobile ? '0.75rem' : '1.25rem' 
        }}>
          {categories.map((cat, idx) => (
            <button
              key={cat.id}
              onClick={() => handleCategorySelect(cat.id)}
              className="card-premium"
              style={{
                gridColumn: (isMobile && idx === 4) ? 'span 2' : 'span 1',
                padding: '1.5rem',
                border: '2px solid',
                borderColor: activeCat === cat.id ? cat.color : 'transparent',
                background: activeCat === cat.id ? 'white' : 'var(--card)',
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                gap: '1rem',
                cursor: 'pointer',
                transition: 'all 0.4s cubic-bezier(0.4, 0, 0.2, 1)',
                transform: activeCat === cat.id ? 'scale(1.02)' : 'scale(1)'
              }}
            >
              <div style={{ background: cat.bg, color: cat.color, padding: '1rem', borderRadius: '18px' }}>
                <cat.icon size={isMobile ? 28 : 32} />
              </div>
              <div style={{ textAlign: 'center' }}>
                <div style={{ fontSize: '0.85rem', fontWeight: 800, color: 'var(--muted-foreground)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>{cat.label}</div>
                <div style={{ fontSize: '1.25rem', fontWeight: 950, color: cat.color, marginTop: '0.25rem' }}>
                  {cat.stock.toLocaleString()} <span style={{ fontSize: '0.7rem', opacity: 0.7 }}>{cat.unit}</span>
                </div>
              </div>
            </button>
          ))}
        </div>
      </section>

      <Separator />

      {/* Sección 2: Detalle de Inventario */}
      <section ref={section2Ref} style={{ scrollMarginTop: '2rem' }}>
        <div style={{ 
          display: 'flex', 
          justifyContent: 'space-between', 
          alignItems: 'center', 
          marginBottom: '2rem',
          flexDirection: isMobile ? 'column' : 'row',
          gap: '1.5rem'
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', width: isMobile ? '100%' : 'auto' }}>
            <div style={{ background: currentCategory?.bg, color: currentCategory?.color, padding: '0.75rem', borderRadius: '15px' }}>
              {currentCategory && <currentCategory.icon size={24} />}
            </div>
            <h2 style={{ fontSize: isMobile ? '1.5rem' : '2rem', fontWeight: 900 }}>{currentCategory?.label} — Inventario</h2>
          </div>
          
          <button 
            onClick={() => setIsInvoiceModalOpen(true)}
            className="btn-primary"
            style={{ 
              display: 'flex', 
              alignItems: 'center', 
              gap: '0.6rem', 
              padding: '0.8rem 1.5rem', 
              borderRadius: '12px', 
              fontWeight: 900, 
              fontSize: '0.9rem', 
              boxShadow: `0 8px 16px ${currentCategory?.bg}`,
              width: isMobile ? '100%' : 'auto',
              justifyContent: 'center'
            }}
          >
            <Plus size={20} /> Nueva Factura
          </button>
        </div>

        <div className="card-premium" style={{ marginBottom: '1.5rem' }}>
          <div style={{ padding: '1.5rem' }}>
            <PremiumInput 
              label={`Buscar en ${currentCategory?.label}...`} 
              icon={Search} 
              value={searchQuery} 
              onChange={(e) => setSearchQuery(e.target.value)} 
            />
          </div>
          <div style={{ width: '100%', overflowX: 'auto' }} className="no-scrollbar">
            <InventoryTable items={filteredInventory} category={activeCat} />
          </div>
        </div>

        <div style={{ display: 'flex', justifyContent: 'center' }}>
          <button onClick={scrollToTop} className="glass" style={{ padding: '0.6rem 1.2rem', borderRadius: '10px', fontSize: '0.8rem', fontWeight: 700, cursor: 'pointer', border: '1px solid var(--border)' }}>
            ↑ Volver al inicio
          </button>
        </div>
      </section>

      <Separator />

      {/* Sección 3: Facturas */}
      <section ref={section3Ref} style={{ scrollMarginTop: '2rem', paddingBottom: '4rem' }}>
        <div style={{ 
          display: 'flex', 
          justifyContent: 'space-between', 
          alignItems: 'center', 
          marginBottom: '2rem'
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
            <div style={{ background: 'rgba(37, 99, 235, 0.1)', color: 'var(--primary)', padding: '0.75rem', borderRadius: '15px' }}>
              <FileText size={24} />
            </div>
            <h2 style={{ fontSize: isMobile ? '1.5rem' : '2rem', fontWeight: 900 }}>Facturas de {currentCategory?.label}</h2>
            
            {nearExpiryCount > 0 && (
              <div style={{ background: '#ef4444', color: 'white', padding: '0.25rem 0.75rem', borderRadius: '20px', fontSize: '0.75rem', fontWeight: 900, display: 'flex', alignItems: 'center', gap: '0.4rem', border: '2px solid white', boxShadow: 'var(--shadow-sm)' }}>
                <TrendingUp size={14} /> {nearExpiryCount} por vencer
              </div>
            )}
          </div>
        </div>

        <div className="card-premium">
          <div style={{ width: '100%', overflowX: 'auto' }} className="no-scrollbar">
            <InvoicesTable 
              invoices={invoices.filter(i => i.category === activeCat)} 
              onRefresh={() => activeUnitId && fetchInvoices(activeUnitId)} 
            />
          </div>
        </div>

        <div style={{ display: 'flex', justifyContent: 'center', marginTop: '2rem' }}>
          <button onClick={scrollToTop} className="glass" style={{ padding: '0.6rem 1.2rem', borderRadius: '10px', fontSize: '0.8rem', fontWeight: 700, cursor: 'pointer', border: '1px solid var(--border)' }}>
            ↑ Volver al inicio
          </button>
        </div>
      </section>

      {/* Modals */}
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
