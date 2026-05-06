'use client';

import { useState, useMemo, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { toast } from 'react-hot-toast';
import { supabase } from '@/lib/supabase';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  ShoppingBag, 
  FlaskConical, 
  Beaker, 
  Fish, 
  Wind,
  Plus,
  Search,
  MoreVertical,
  Package,
  TrendingUp,
  AlertCircle,
  FileText,
  CheckCircle2,
  Clock,
  ChevronLeft,
  ChevronRight,
  Users,
  UserPlus,
  Trash2,
  Calendar,
  ArrowDown,
  ArrowUp
} from 'lucide-react';

interface InventoryItem {
  id: string;
  name: string;
  category: string;
  current_stock: string | number;
  unit: string;
  min_stock?: number;
  brand?: string;
  last_entry?: string;
}




export default function AlmacenPage() {
  const [activeCat, setActiveCat] = useState('alimento');
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isInvoiceListOpen, setIsInvoiceListOpen] = useState(false);
  const [isProviderModalOpen, setIsProviderModalOpen] = useState(false);
  const [isBadgeHovered, setIsBadgeHovered] = useState(false);
  const [isSidebarCollapsed, setIsSidebarCollapsed] = useState(false);
  const [hoveredCatId, setHoveredCatId] = useState<string | null>(null);
  const [focusedItemId, setFocusedItemId] = useState<string | null>(null);
  const [focusedRowId, setFocusedRowId] = useState<number | null>(null);
  const [dropdownPos, setDropdownPos] = useState<{ top: number; left: number; width: number } | null>(null);

  // Providers & Invoices State
  const [providers, setProviders] = useState<any[]>([]);
  const [invoices, setInvoices] = useState<any[]>([]);
  const [inventory, setInventory] = useState<InventoryItem[]>([]);

  const [newProvider, setNewProvider] = useState({ name: '', nit: '', types: [] as string[] });
  const [newInvoice, setNewInvoice] = useState({ 
    invoice_number: '', 
    provider_id: '', 
    date: new Date().toISOString().split('T')[0],
    items: [{ name: '', category: 'alimento', quantity: '', unit: 'uds', price: '' }]
  });

  useEffect(() => {
    const activeUnitId = typeof window !== 'undefined' ? localStorage.getItem('active_unit_id') : null;
    if (activeUnitId) {
      fetchProviders(activeUnitId);
      fetchInvoices(activeUnitId);
      fetchInventory(activeUnitId);
    }
  }, []);

  const fetchProviders = async (unitId: string) => {
    try {
      const { data, error } = await supabase
        .from('providers')
        .select('*')
        .eq('unit_id', unitId)
        .order('name');
      
      if (error) throw error;
      setProviders(data || []);
    } catch (error: any) {
      toast.error("Error al cargar proveedores: " + error.message);
    }
  };

  const fetchInventory = async (unitId: string) => {
    try {
      const { data, error } = await supabase
        .from('inventory')
        .select('*')
        .eq('unit_id', unitId);
      
      if (error) throw error;
      setInventory(data || []);
    } catch (error: any) {
      toast.error("Error al cargar inventario: " + error.message);
    }
  };

  const fetchInvoices = async (unitId: string) => {
    try {
      const { data, error } = await supabase
        .from('invoices')
        .select(`*, providers (name)`)
        .eq('unit_id', unitId)
        .order('date', { ascending: false });
      
      if (error) throw error;
      
      const formatted = (data || []).map(inv => ({
        ...inv,
        nro: inv.invoice_number,
        proveedor: inv.providers?.name || 'Desconocido',
        monto: inv.total,
        vencimiento: inv.date,
        status: inv.status === 'pagada' ? 'Pagada' : 'Pendiente'
      }));
      setInvoices(formatted);
    } catch (error: any) {
      toast.error("Error al cargar facturas: " + error.message);
    }
  };

  const saveProvider = async () => {
    if (!newProvider.name || !newProvider.nit) {
      toast.error("Por favor complete nombre y NIT.");
      return;
    }

    const activeUnitId = typeof window !== 'undefined' ? localStorage.getItem('active_unit_id') : null;
    if (!activeUnitId) {
      toast.error("No se detectó unidad activa.");
      return;
    }

    const payload = {
      ...newProvider,
      unit_id: activeUnitId
    };

    try {
      const { data, error } = await supabase.from('providers').insert([payload]).select();
      if (error) {
        if (error.code === '23505') {
          toast.error("Ya existe un proveedor con este NIT.");
        } else {
          throw error;
        }
        return;
      }
      setProviders(prev => [...prev, ...(data || [])]);
      setNewProvider({ name: '', nit: '', types: [] });
      setIsProviderModalOpen(false);
      toast.success("¡Proveedor registrado!");
    } catch (error: any) {
      toast.error("Error al guardar: " + error.message);
    }
  };

  const handleCreateProvider = async () => {
    if (!newProvider.name || !newProvider.nit) {
      toast.error("Por favor complete nombre y NIT.");
      return;
    }
    const { data, error } = await supabase.from('providers').insert([newProvider]).select();
    if (error) {
      toast.error('Error al crear proveedor: ' + error.message);
    } else {
      setProviders([...providers, ...(data || [])]);
      setNewProvider({ name: '', nit: '', types: [] });
      setIsProviderModalOpen(false);
      toast.success('¡Proveedor registrado con éxito!');
    }
  };

  const categories = useMemo(() => [
    { 
      id: 'alimento', 
      label: 'Alimento', 
      icon: ShoppingBag, 
      color: '#10b981', 
      bg: 'rgba(16, 185, 129, 0.1)', 
      stock: inventory.filter(i => i.category === 'alimento').reduce((sum, i) => sum + (Number(i.current_stock) || 0), 0),
      unit: 'Btos'
    },
    { 
      id: 'farmacia', 
      label: 'Farmacia', 
      icon: FlaskConical, 
      color: '#8b5cf6', 
      bg: 'rgba(139, 92, 246, 0.1)', 
      stock: inventory.filter(i => i.category === 'farmacia').reduce((sum, i) => sum + (Number(i.current_stock) || 0), 0),
      unit: 'Und'
    },
    { 
      id: 'insumos', 
      label: 'Insumos', 
      icon: Beaker, 
      color: '#3b82f6', 
      bg: 'rgba(59, 130, 246, 0.1)', 
      stock: inventory.filter(i => i.category === 'insumos').reduce((sum, i) => sum + (Number(i.current_stock) || 0), 0),
      unit: 'Reg'
    },
    { 
      id: 'alevinos', 
      label: 'Alevinos', 
      icon: Fish, 
      color: '#06b6d4', 
      bg: 'rgba(6, 182, 212, 0.1)', 
      stock: inventory.filter(i => i.category === 'alevinos').reduce((sum, i) => sum + (Number(i.current_stock) || 0), 0),
      unit: 'Und'
    },
    { 
      id: 'aireadores', 
      label: 'Aireadores', 
      icon: Wind, 
      color: '#f59e0b', 
      bg: 'rgba(245, 158, 11, 0.1)', 
      stock: inventory.filter(i => i.category === 'aireadores').reduce((sum, i) => sum + (Number(i.current_stock) || 0), 0),
      unit: 'Equip'
    },
  ], [inventory]);

  const currentCategory = categories.find(c => c.id === activeCat);

  const nearExpiryCount = useMemo(() => {
    const today = new Date();
    return invoices.filter(inv => {
      if (inv.status === 'Pagada') return false;
      const vDate = new Date(inv.vencimiento);
      const diffTime = vDate.getTime() - today.getTime();
      const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
      return diffDays <= 3;
    }).length;
  }, [invoices]);

  // Invoice Header States
  const [nroFactura, setNroFactura] = useState('');
  const [proveedor, setProveedor] = useState('');
  const [fechaFactura, setFechaFactura] = useState(new Date().toISOString().split('T')[0]);
  const [isCredit, setIsCredit] = useState(false);
  const [diasCredito, setDiasCredito] = useState('30');
  const [flete, setFlete] = useState('');

  // Invoice Items State
  const [items, setItems] = useState([
    { id: Date.now(), product: '', batch: '', quantity: '', kilos: '', unitPrice: '', expiry: '', hpEnergy: '', sortCaudal: '', hasIva: false, ivaPercent: '19' }
  ]);

  const updateItem = (id: number, field: string, value: string) => {
    setItems(prev => prev.map(item => {
      if (item.id !== id) return item;
      
      const updatedItem = { ...item, [field]: value === 'true' ? true : value === 'false' ? false : value };
      
      // Auto-calculate Kilos for Food
      if (activeCat === 'alimento' && (field === 'product' || field === 'quantity')) {
        const weightMatch = updatedItem.product.match(/(\d+)\s*kg/i);
        const weightPerBag = weightMatch ? parseInt(weightMatch[1]) : 40; // Default to 40kg
        const qty = parseFloat(updatedItem.quantity) || 0;
        updatedItem.kilos = (qty * weightPerBag).toString();
      }
      
      return updatedItem;
    }));
  };

  const addItem = () => {
    setItems([...items, { id: Date.now(), product: '', batch: '', quantity: '', kilos: '', unitPrice: '', expiry: '', hpEnergy: '', sortCaudal: '', hasIva: false, ivaPercent: '19' }]);
  };

  const removeItem = (id: number) => {
    if (items.length > 1) {
      setItems(items.filter(item => item.id !== id));
    }
  };

  // Flete calculations
  const totalBultos = useMemo(() => items.reduce((sum, item) => sum + (parseFloat(item.quantity) || 0), 0), [items]);
  const fleteNum = parseFloat(flete) || 0;
  const fletePorBulto = totalBultos > 0 ? fleteNum / totalBultos : 0;

  const totalFactura = useMemo(() => {
    // Each item: qty * unitPrice (sin flete â€” flete es externo)
    const subtotal = items.reduce((sum, item) => {
      const qty = parseFloat(item.quantity) || 0;
      const price = parseFloat(item.unitPrice) || 0;
      // IVA: 5% auto para alimento, manual para el resto
      const ivaRate = activeCat === 'alimento' ? 0.05 : (item.hasIva ? (parseFloat(item.ivaPercent) || 0) / 100 : 0);
      return sum + (qty * price * (1 + ivaRate));
    }, 0);
    return subtotal; // Flete NO incluido en factura
  }, [items, activeCat]);

  // Costo real por bulto (para info interna, incluye flete distribuido)
  const costoRealPorBulto = useMemo(() => {
    if (items.length === 0 || totalBultos === 0) return 0;
    const firstItem = items[0];
    const price = parseFloat(firstItem.unitPrice) || 0;
    const ivaRate = activeCat === 'alimento' ? 0.05 : (firstItem.hasIva ? (parseFloat(firstItem.ivaPercent) || 0) / 100 : 0);
    return price * (1 + ivaRate) + fletePorBulto;
  }, [items, activeCat, fletePorBulto, totalBultos]);


  const handleRegisterInvoice = async () => {
    const providerObj = providers.find(p => p.name === proveedor);
    if (!providerObj) { toast.error("Por favor seleccione un proveedor válido."); return; }
    if (!nroFactura) { toast.error("Por favor ingrese el número de factura."); return; }

    const activeUnitId = typeof window !== 'undefined' ? localStorage.getItem('active_unit_id') : null;
    if (!activeUnitId) { toast.error("No se detectó unidad activa."); return; }

    const registerPromise = async () => {
      // 1. Insert Invoice
      const { data: invData, error: invError } = await supabase
        .from('invoices')
        .insert([{
          invoice_number: nroFactura,
          provider_id: providerObj.id,
          category: activeCat,
          date: fechaFactura,
          total: totalFactura,
          flete: fleteNum,
          is_credit: isCredit,
          credit_days: parseInt(diasCredito) || 0,
          status: isCredit ? 'pendiente' : 'pagada',
          unit_id: activeUnitId
        }])
        .select();

      if (invError || !invData) throw invError || new Error("Error al registrar cabecera de factura");

      const invoiceId = invData[0].id;
      
      // 2. Prepare items and inventory updates
      const operations = items.map(async (item) => {
        const qty = parseFloat(item.quantity) || 0;
        const price = parseFloat(item.unitPrice) || 0;
        const ivaP = activeCat === 'alimento' ? 5 : (item.hasIva ? parseFloat(item.ivaPercent) || 0 : 0);
        
        // A. Insert Item
        const { error: itemError } = await supabase.from('invoice_items').insert([{
          invoice_id: invoiceId,
          unit_id: activeUnitId,
          product_name: item.product,
          batch: item.batch,
          quantity: qty,
          kilos: parseFloat(item.kilos) || 0,
          unit_price: price,
          flete_per_unit: fletePorBulto,
          total_price: qty * price,
          hp_energy: item.hpEnergy,
          sort_caudal: item.sortCaudal,
          has_iva: activeCat === 'alimento' ? true : item.hasIva,
          iva_percent: ivaP
        }]);
        if (itemError) throw itemError;

        // B. Update Inventory
        if (item.product) {
          const { data: existing } = await supabase
            .from('inventory')
            .select('*')
            .eq('category', activeCat)
            .eq('name', item.product)
            .eq('unit_id', activeUnitId)
            .single();
          
          const qtyToAdd = activeCat === 'alimento' ? (parseFloat(item.kilos) || 0) : qty;
          
          if (existing) {
            await supabase.from('inventory').update({ 
              current_stock: (Number(existing.current_stock) || 0) + qtyToAdd, 
              last_entry: new Date().toISOString()
            }).eq('id', existing.id);
          } else {
            await supabase.from('inventory').insert([{
              category: activeCat,
              name: item.product,
              current_stock: qtyToAdd,
              unit: activeCat === 'alimento' ? 'kg' : activeCat === 'alevinos' ? 'unidades' : 'uds',
              unit_id: activeUnitId,
              last_entry: new Date().toISOString()
            }]);
          }
        }
      });

      await Promise.all(operations);
      return true;
    };

    toast.promise(registerPromise(), {
      loading: 'Registrando factura e inventario...',
      success: () => {
        fetchInvoices(activeUnitId);
        fetchInventory(activeUnitId);
        resetForm();
        return `¡Factura registrada con éxito!`;
      },
      error: (err) => `Error: ${err.message}`
    });
  };

  const handleDeleteInvoice = async (invoiceId: string, invoiceNumber: string, category: string) => {
    if (!confirm(`¿Eliminar la factura ${invoiceNumber}? Esta acción restará el stock ingresado y no se puede deshacer.`)) return;

    const activeUnitId = typeof window !== 'undefined' ? localStorage.getItem('active_unit_id') : null;
    if (!activeUnitId) { toast.error("No se detectó unidad activa."); return; }

    const deletePromise = async () => {
      // 1. Get items to reverse stock
      const { data: items, error: itemsError } = await supabase
        .from('invoice_items')
        .select('*')
        .eq('invoice_id', invoiceId);
      
      if (itemsError) throw itemsError;

      // 2. Reverse stock in parallel
      const reverseOps = (items || []).map(async (item) => {
        const { data: inventoryItem } = await supabase
          .from('inventory')
          .select('*')
          .eq('name', item.product_name)
          .eq('category', category)
          .eq('unit_id', activeUnitId)
          .single();
        
        if (inventoryItem) {
          const qtyToRemove = category === 'alimento' ? (parseFloat(item.kilos) || 0) : (parseFloat(item.quantity) || 0);
          const newStock = Math.max(0, (Number(inventoryItem.current_stock) || 0) - qtyToRemove);
          await supabase
            .from('inventory')
            .update({ current_stock: newStock })
            .eq('id', inventoryItem.id);
        }
      });

      await Promise.all(reverseOps);

      // 3. Delete items (handled by DB cascade ideally, but explicit here)
      await supabase.from('invoice_items').delete().eq('invoice_id', invoiceId);

      // 4. Delete invoice
      const { error: delError } = await supabase.from('invoices').delete().eq('id', invoiceId);
      if (delError) throw delError;

      return true;
    };

    toast.promise(deletePromise(), {
      loading: `Eliminando factura ${invoiceNumber}...`,
      success: () => {
        fetchInvoices(activeUnitId);
        fetchInventory(activeUnitId);
        return "Factura eliminada y stock revertido.";
      },
      error: (err) => `Error al eliminar: ${err.message}`
    });
  };

  const handleRegisterAlimento = () => handleRegisterInvoice();
  const handleRegisterFarmacia = () => handleRegisterInvoice();
  const handleRegisterInsumos = () => handleRegisterInvoice();
  const handleRegisterGeneric = () => handleRegisterInvoice();

  const resetForm = () => {
    setItems([{ id: Date.now(), product: '', batch: '', quantity: '', kilos: '', unitPrice: '', expiry: '', hpEnergy: '', sortCaudal: '', hasIva: false, ivaPercent: '19' }]);
    setNroFactura('');
    setProveedor('');
    setFlete('');
    setFechaFactura(new Date().toISOString().split('T')[0]);
    setIsCredit(false);
    setDiasCredito('30');
    setIsModalOpen(false);
  };

  const openNewInvoice = () => {
    setItems([{ id: Date.now(), product: '', batch: '', quantity: '', kilos: '', unitPrice: '', expiry: '', hpEnergy: '', sortCaudal: '', hasIva: false, ivaPercent: '19' }]);
    setNroFactura('');
    setProveedor('');
    setFechaFactura(new Date().toISOString().split('T')[0]);
    setIsCredit(false);
    setDiasCredito('30');
    setIsModalOpen(true);
  };

  const foodTypes = [
    'Aquatilapia Preiniciador 48% ME 20kg',
    'Aquatilapia 45% E 40kg',
    'Aquatilapia 38% E 40kg',
    'Aquatilapia 34% E 40kg',
    'Aquatilapia 32% E 40kg',
    'Aquatilapia 30% E 40kg',
    'Aquatilapia 25% E 40kg',
    'Aquatilapia 20% E 40kg',
    'Aquatropico 22% E 40 kg',
    'Aquatrucha Super Iniciación 50% E 40 kg',
    'Aquatrucha Levante 45% E Pig 40 kg',
    'Aquatrucha Finalización 45% E Pig 40 kg'
  ];

  const pharmaProducts = [
    'Oxitetraciclina 50%',
    'Florfenicol 30%',
    'Enrofloxacina 10%',
    'Vitamina C Estabilizada',
    'Complejo B Acuático',
    'Desinfectante (Yodo Polivinil)',
    'Probiótico de Estanque'
  ];

  const laboratorios = ['Bayer (Elanco)', 'MSD Animal Health', 'Vet-Tech', 'Pronavet', 'Virbac'];

  return (
    <div className="animate-fade-in page-container">
      <header style={{ marginBottom: '2rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem' }}>
        <div>
          <h1 style={{ fontWeight: 900 }}>Almacén e Inventario</h1>
          <p style={{ color: 'var(--muted-foreground)' }}>Gestión centralizada de abastecimiento y stock.</p>
        </div>
        <div style={{ display: 'flex', gap: '0.75rem' }}>
          <button 
            onClick={() => setIsProviderModalOpen(true)}
            className="btn-secondary" 
            style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', background: 'var(--card)', padding: '0.6rem 1rem', borderRadius: '10px', border: '1px solid var(--border)', fontWeight: 700, cursor: 'pointer' }}
          >
            <UserPlus size={18} />
            Proveedores
          </button>
          <button 
            onClick={openNewInvoice}
            className="btn-primary" 
            style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', background: 'var(--primary)', color: 'white', padding: '0.6rem 1rem', borderRadius: '10px', border: 'none', fontWeight: 700, cursor: 'pointer' }}
          >
            <Plus size={18} />
            Nueva Factura
          </button>
        </div>
      </header>

      <div className="responsive-grid-2">
        {/* Internal Sidebar - Navigation Categories */}
        <div className="almacen-sidebar-categories" style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
          <h3 style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--muted-foreground)', textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: '0.5rem' }}>Categorías de Almacén</h3>
          {categories.map(cat => (
            <button
              key={cat.id}
              onClick={() => setActiveCat(cat.id)}
              onMouseEnter={() => setHoveredCatId(cat.id)}
              onMouseLeave={() => setHoveredCatId(null)}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: isSidebarCollapsed ? '0' : '1rem',
                padding: isSidebarCollapsed ? '0.75rem' : '1rem',
                justifyContent: isSidebarCollapsed ? 'center' : 'flex-start',
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
                minWidth: isSidebarCollapsed ? '50px' : 'auto'
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
              {!isSidebarCollapsed && (
                <div style={{ flex: 1, overflow: 'hidden' }}>
                  <div style={{ fontWeight: 700, fontSize: '0.9rem' }}>{cat.label}</div>
                  <div style={{ fontSize: '0.75rem', fontWeight: 800, color: cat.stock === 0 ? '#ef4444' : 'var(--muted-foreground)', marginTop: '0.2rem' }}>
                    {cat.stock.toLocaleString()} {cat.unit}
                  </div>
                </div>
              )}

              {/* Tooltip for Collapsed Sidebar */}
              <AnimatePresence>
                {isSidebarCollapsed && hoveredCatId === cat.id && (
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
                    {/* Arrow pointing left */}
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

        {/* Main Content Area */}
        <div className="card-premium almacen-inventory-card" style={{ background: 'var(--card)', display: 'flex', flexDirection: 'column' }}>
          
          {/* Content Header */}
          <div style={{ padding: '1.5rem', borderBottom: '1px solid var(--border)', display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
              <div style={{ color: currentCategory?.color, background: 'var(--secondary)', padding: '0.5rem', borderRadius: '10px' }}>
                {currentCategory && <currentCategory.icon size={20} />}
              </div>
              <h2 style={{ fontSize: '1.1rem', fontWeight: 800 }}>Inventario de {currentCategory?.label}</h2>
            </div>
            <div className="inventory-header-actions" style={{ display: 'flex', gap: '0.75rem' }}>
              <button 
                onClick={() => setIsInvoiceListOpen(true)}
                style={{ 
                  display: 'flex', 
                  alignItems: 'center', 
                  gap: '0.5rem', 
                  padding: '0.6rem 1.25rem', 
                  borderRadius: '10px', 
                  border: '1px solid var(--border)', 
                  background: 'white', 
                  color: 'var(--foreground)', 
                  fontWeight: 700, 
                  cursor: 'pointer',
                  position: 'relative'
                }}
              >
                <FileText size={18} />
                Mis Facturas
                {nearExpiryCount > 0 && (
                  <div 
                    onMouseEnter={() => setIsBadgeHovered(true)}
                    onMouseLeave={() => setIsBadgeHovered(false)}
                    style={{ 
                      position: 'absolute', 
                      top: '-6px', 
                      right: '-6px', 
                      background: '#ef4444', 
                      color: 'white', 
                      fontSize: '0.65rem', 
                      fontWeight: 900, 
                      width: '18px', 
                      height: '18px', 
                      borderRadius: '50%', 
                      display: 'flex', 
                      alignItems: 'center', 
                      justifyContent: 'center',
                      border: '2px solid white',
                      boxShadow: '0 2px 4px rgba(0,0,0,0.2)',
                      zIndex: 10
                    }}
                  >
                    {nearExpiryCount}
                    
                    <AnimatePresence>
                      {isBadgeHovered && (
                        <motion.div
                          initial={{ opacity: 0, y: -10, scale: 0.9, x: '-50%' }}
                          animate={{ opacity: 1, y: 0, scale: 1, x: '-50%' }}
                          exit={{ opacity: 0, y: -5, scale: 0.9, x: '-50%' }}
                          style={{
                            position: 'absolute',
                            top: '100%',
                            left: '50%',
                            marginTop: '10px',
                            padding: '6px 10px',
                            background: 'rgba(0, 0, 0, 0.9)',
                            color: 'white',
                            fontSize: '0.7rem',
                            fontWeight: 700,
                            borderRadius: '6px',
                            whiteSpace: 'nowrap',
                            pointerEvents: 'none',
                            boxShadow: '0 10px 15px -3px rgba(0, 0, 0, 0.3)',
                            zIndex: 100
                          }}
                        >
                          Tienes facturas por vencer
                          <div style={{
                            position: 'absolute',
                            bottom: '100%',
                            left: '50%',
                            transform: 'translateX(-50%)',
                            borderLeft: '6px solid transparent',
                            borderRight: '6px solid transparent',
                            borderBottom: '6px solid rgba(0, 0, 0, 0.9)'
                          }} />
                        </motion.div>
                      )}
                    </AnimatePresence>
                  </div>
                )}
              </button>
              <button 
                onClick={openNewInvoice}
                className="btn-primary" 
                style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}
              >
                <Plus size={20} />
                Registrar Factura
              </button>
            </div>
          </div>

          {/* Quick Stats Bar */}
          <div style={{ padding: '0.75rem 1.5rem', background: 'rgba(37, 99, 235, 0.02)', borderBottom: '1px solid var(--border)', display: 'flex', gap: '1.5rem', flexWrap: 'wrap' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <Package size={14} style={{ color: 'var(--muted-foreground)' }} />
              <span style={{ fontSize: '0.75rem', fontWeight: 600 }}>
                <span className="stat-item-text">Total Items: </span>
                <span style={{ color: 'var(--primary)' }}>{inventory.filter(i => i.category === activeCat && (parseFloat(i.current_stock) || 0) > 0).length}</span>
              </span>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              {(() => {
                const catItems = inventory.filter(i => i.category === activeCat && (parseFloat(i.current_stock) || 0) > 0);
                const isEmpty = catItems.length === 0;
                const isLow = catItems.some(i => parseFloat(i.current_stock) <= 5);
                
                const color = isEmpty || isLow ? '#ef4444' : '#10b981';
                const text = isEmpty ? 'Sin Stock' : (isLow ? 'Bajo Stock' : 'Saludable');
                
                return (
                  <>
                    <TrendingUp size={14} style={{ color }} />
                    <span style={{ fontSize: '0.75rem', fontWeight: 600 }}>
                      <span className="stat-item-text">Estado: </span>
                      <span style={{ color }}>{text}</span>
                    </span>
                  </>
                );
              })()}
            </div>
          </div>

          {/* Search & Table Area */}
          <div style={{ flex: 1, display: 'flex', flexDirection: 'column', overflow: 'auto' }}>
            <div style={{ padding: '1rem 1.5rem' }}>
              <div className="premium-input-wrapper">
                <Search size={18} className="premium-input-icon" />
                <input 
                  type="text" 
                  placeholder={`Buscar en ${currentCategory?.label}...`}
                  className="premium-input"
                />
              </div>
            </div>

            <div style={{ flex: 1, overflowY: 'auto', padding: '0 1.5rem 1.5rem' }}>
              <table className="almacen-table-responsive" style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
                <thead>
                  <tr style={{ borderBottom: '1px solid var(--border)', fontSize: '0.75rem', textTransform: 'uppercase', color: 'var(--muted-foreground)', letterSpacing: '0.05em' }}>
                    <th style={{ padding: '0.75rem 0', fontWeight: 700 }}>Producto</th>
                    <th style={{ padding: '0.75rem 0', fontWeight: 700 }}>Marca</th>
                    <th style={{ padding: '0.75rem 0', fontWeight: 700 }}>Stock Actual</th>
                    <th style={{ padding: '0.75rem 0', fontWeight: 700 }}>Último Ingreso</th>
                    <th style={{ padding: '0.75rem 0', fontWeight: 700, textAlign: 'right' }}></th>
                  </tr>
                </thead>
                <tbody>
                  {inventory
                    .filter(i => i.category === activeCat && (parseFloat(i.current_stock as string) || 0) > 0)
                    .map((item) => {
                      const stockVal = parseFloat(item.current_stock as string) || 0;
                      const isLowStock = stockVal <= (item.min_stock || 100); // Dynamic threshold

                      return (
                        <tr key={item.id} style={{ borderBottom: '1px solid var(--border)', fontSize: '0.9rem' }}>
                          <td style={{ padding: '1rem 0', fontWeight: 600 }}>{item.name}</td>
                          <td style={{ padding: '1rem 0', color: 'var(--muted-foreground)' }}>{item.brand || 'Genérico'}</td>
                          <td style={{ padding: '1rem 0' }}>
                            <span style={{ 
                              padding: '0.25rem 0.75rem', 
                              borderRadius: '6px', 
                              background: isLowStock ? 'rgba(239, 68, 68, 0.1)' : 'rgba(16, 185, 129, 0.1)',
                              color: isLowStock ? '#ef4444' : '#10b981',
                              fontWeight: 700,
                              fontSize: '0.85rem'
                            }}>
                              {stockVal.toLocaleString()} {item.unit}
                              {isLowStock && <AlertCircle size={12} style={{ marginLeft: '4px', display: 'inline' }} />}
                            </span>
                          </td>
                          <td style={{ padding: '1rem 0', color: 'var(--muted-foreground)' }}>
                            {item.last_entry ? new Date(item.last_entry).toLocaleDateString() : 'N/A'}
                          </td>
                          <td style={{ padding: '1rem 0', textAlign: 'right' }}>
                            <button style={{ background: 'transparent', border: 'none', color: 'var(--muted-foreground)', cursor: 'pointer' }}>
                              <MoreVertical size={18} />
                            </button>
                          </td>
                        </tr>
                      );
                    })
                  }
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>

      {/* Modal: Registrar Factura Almacén */}
      <AnimatePresence>
        {isModalOpen && (
          <div style={{ position: 'fixed', inset: 0, zIndex: 999, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '1rem' }}>
            <motion.div 
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setIsModalOpen(false)}
              style={{ 
                position: 'absolute', 
                inset: 0, 
                background: 'rgba(255,255,255,0.3)', 
                backdropFilter: 'blur(40px) saturate(180%)',
                WebkitBackdropFilter: 'blur(40px) saturate(180%)'
              }} 
            />
            <motion.div 
              initial={{ scale: 0.9, opacity: 0, y: 30 }}
              animate={{ scale: 1, opacity: 1, y: 0 }}
              exit={{ scale: 0.9, opacity: 0, y: 30 }}
              className="card-premium" 
              style={{ 
                width: '95%', 
                maxWidth: '900px', 
                maxHeight: '95vh', 
                position: 'relative', 
                zIndex: 10, 
                padding: '2rem', 
                display: 'flex', 
                flexDirection: 'column', 
                overflow: 'hidden',
                boxShadow: '0 0 80px rgba(0,0,0,0.3)',
                border: '1px solid rgba(255,255,255,0.1)'
              }}
            >
              {/* Header */}
              <div style={{ marginBottom: '1.5rem', display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                <div>
                  <h2 style={{ fontSize: '1.5rem', fontWeight: 800, marginBottom: '0.25rem' }}>Ingreso de Factura</h2>
                  <p style={{ color: 'var(--muted-foreground)', fontSize: '0.9rem' }}>Carga masiva de inventario por proveedor.</p>
                </div>
                <div style={{ background: 'rgba(37, 99, 235, 0.05)', padding: '1rem', borderRadius: '12px', border: '1px solid var(--primary)', textAlign: 'right' }}>
                  <div style={{ fontSize: '0.7rem', fontWeight: 700, color: 'var(--primary)', textTransform: 'uppercase' }}>Total Factura</div>
                  <div style={{ fontSize: '1.5rem', fontWeight: 900, color: 'var(--primary)' }}>${totalFactura.toLocaleString()}</div>
                </div>
              </div>

              {/* Invoice Meta */}
              <div style={{ background: 'var(--secondary)', borderRadius: '16px', padding: '1.25rem', marginBottom: '2rem' }}>
                <div style={{ 
                  display: 'grid', 
                  gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', 
                  gap: '1.25rem', 
                  marginBottom: '1.25rem' 
                }}>
                  <div className="premium-input-group">
                    <label className="premium-label">Nro. Factura</label>
                    <div className="premium-input-wrapper">
                      <input 
                        type="text" 
                        value={nroFactura} 
                        onChange={(e) => setNroFactura(e.target.value)} 
                        placeholder="Ej: BQAE 258328" 
                        className="premium-input"
                        style={{ fontWeight: 700 }}
                      />
                    </div>
                  </div>
                  <div className="premium-input-group">
                    <label className="premium-label">Proveedor</label>
                    <div className="premium-input-wrapper">
                      <select 
                        value={proveedor} 
                        onChange={(e) => setProveedor(e.target.value)} 
                        className="premium-input"
                        style={{ fontWeight: 700 }}
                      >
                        <option value="">Seleccione proveedor...</option>
                        {providers
                          .filter(p => {
                            const searchType = activeCat === 'farmacia' ? 'medicamentos' : activeCat;
                            return p.types.includes(searchType);
                          })
                          .map(p => (
                            <option key={p.id} value={p.name}>{p.name}</option>
                          ))
                        }
                      </select>
                    </div>
                  </div>
                  <div className="premium-input-group">
                    <label className="premium-label">
                      <Calendar size={14} /> Fecha
                    </label>
                    <div className="premium-input-wrapper">
                      <input 
                        type="date" 
                        value={fechaFactura} 
                        onChange={(e) => setFechaFactura(e.target.value)} 
                        className="premium-date-input"
                      />
                    </div>
                  </div>
                </div>

                {activeCat !== 'insumos' && activeCat !== 'aireadores' && activeCat !== 'alevinos' && (
                  <div style={{ display: 'flex', alignItems: 'center', gap: '2rem', borderTop: '1px solid var(--border)', paddingTop: '1rem' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', cursor: 'pointer' }} onClick={() => setIsCredit(!isCredit)}>
                      <div style={{ 
                        width: '40px', 
                        height: '22px', 
                        borderRadius: '11px', 
                        background: isCredit ? 'var(--primary)' : 'var(--border)', 
                        position: 'relative',
                        transition: 'all 0.3s ease'
                      }}>
                        <div style={{ 
                          width: '18px', 
                          height: '18px', 
                          borderRadius: '50%', 
                          background: 'white', 
                          position: 'absolute', 
                          top: '2px', 
                          left: isCredit ? '20px' : '2px',
                          transition: 'all 0.3s ease',
                          boxShadow: '0 2px 4px rgba(0,0,0,0.2)'
                        }} />
                      </div>
                       <span style={{ fontSize: '0.85rem', fontWeight: 700, color: isCredit ? 'var(--primary)' : 'var(--muted-foreground)' }}>Compra a Crédito</span>
                    </div>

                    <AnimatePresence>
                      {isCredit && (
                        <motion.div 
                          initial={{ opacity: 0, x: -20 }}
                          animate={{ opacity: 1, x: 0 }}
                          exit={{ opacity: 0, x: -20 }}
                          style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}
                        >
                           <label style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--muted-foreground)' }}>PLAZO (DÍAS):</label>
                          <select 
                            value={diasCredito}
                            onChange={(e) => setDiasCredito(e.target.value)}
                            style={{ padding: '0.4rem 0.75rem', borderRadius: '6px', border: '1px solid var(--primary)', background: 'white', fontWeight: 800, color: 'var(--primary)', outline: 'none' }}
                          >
                            <option value="15">15 Días</option>
                            <option value="30">30 Días</option>
                            <option value="45">45 Días</option>
                            <option value="60">60 Días</option>
                            <option value="90">90 Días</option>
                          </select>
                        </motion.div>
                      )}
                    </AnimatePresence>
                  </div>
                )}
              </div>

              {/* Flete + Costo Real */}
              {activeCat === 'alimento' && (
                <div style={{ background: 'rgba(245, 158, 11, 0.05)', border: '1px solid rgba(245, 158, 11, 0.3)', borderRadius: '12px', padding: '1rem', marginBottom: '1rem', display: 'flex', alignItems: 'center', gap: '2rem', flexWrap: 'wrap' }}>
                  <div style={{ flex: 1, minWidth: '180px' }}>
                    <label style={{ display: 'block', fontSize: '0.7rem', fontWeight: 700, marginBottom: '0.4rem', color: '#d97706', textTransform: 'uppercase' }}>🚚 Flete (COP) — Externo, no va en factura</label>
                    <input
                      type="text"
                      value={flete ? parseInt(flete).toLocaleString() : ''}
                      onChange={(e) => setFlete(e.target.value.replace(/\D/g, ''))}
                      placeholder="0"
                      style={{ width: '100%', padding: '0.6rem', borderRadius: '8px', border: '1px solid rgba(245, 158, 11, 0.5)', background: 'white', fontWeight: 700, outline: 'none', color: '#d97706' }}
                    />
                  </div>
                  {fleteNum > 0 && totalBultos > 0 && (
                    <div style={{ display: 'flex', gap: '1.5rem' }}>
                      <div style={{ textAlign: 'center' }}>
                        <div style={{ fontSize: '0.65rem', fontWeight: 700, color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Flete / Bulto</div>
                        <div style={{ fontSize: '1.1rem', fontWeight: 900, color: '#d97706' }}>${fletePorBulto.toLocaleString(undefined, {maximumFractionDigits: 0})}</div>
                      </div>
                      <div style={{ textAlign: 'center' }}>
                        <div style={{ fontSize: '0.65rem', fontWeight: 700, color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Costo Real / Bulto</div>
                        <div style={{ fontSize: '1.1rem', fontWeight: 900, color: '#10b981' }}>${costoRealPorBulto.toLocaleString(undefined, {maximumFractionDigits: 0})}</div>
                      </div>
                    </div>
                  )}
                </div>
              )}

              {/* Items Table Container */}
              <div style={{ flex: 1, overflowY: 'auto', marginBottom: '1.5rem', paddingRight: '0.5rem' }}>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                  {/* Header labels (hidden on mobile) */}
                  <div className="desktop-only" style={{ display: 'grid', gridTemplateColumns: activeCat === 'alimento' ? '2fr 1fr 1fr 1fr 1.5fr' : '2.5fr 1.5fr 1fr 1.5fr', gap: '1rem', padding: '0 0.5rem', marginBottom: '-0.5rem' }}>
                    <div style={{ fontSize: '0.65rem', fontWeight: 900, color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>{activeCat === 'aireadores' ? 'Equipo / Marca' : activeCat === 'alevinos' ? 'Especie' : 'Producto'}</div>
                    <div style={{ fontSize: '0.65rem', fontWeight: 900, color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>{activeCat === 'alevinos' ? 'Tipo / Etapa' : activeCat === 'insumos' ? 'Presentación' : activeCat === 'aireadores' ? 'HP / Energía' : 'Lote'}</div>
                    <div style={{ fontSize: '0.65rem', fontWeight: 900, color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>{activeCat === 'alimento' ? 'Cant (BTO)' : 'Cant'}</div>
                    {activeCat === 'alimento' && <div style={{ fontSize: '0.65rem', fontWeight: 900, color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Kilos</div>}
                    <div style={{ fontSize: '0.65rem', fontWeight: 900, color: 'var(--muted-foreground)', textTransform: 'uppercase' }}>Vlr. Unit ($)</div>
                  </div>
                  
                  {items.map((item) => (
                    <div key={item.id} className="card-premium" style={{ 
                      padding: '1rem', 
                      display: 'grid', 
                      gridTemplateColumns: 'repeat(auto-fit, minmax(140px, 1fr))', 
                      gap: '1rem',
                      alignItems: 'center',
                      background: 'var(--secondary)'
                    }}>
                      {/* Producto */}
                      <div style={{ position: 'relative' }}>
                        <label className="mobile-only" style={{ display: 'block', fontSize: '0.6rem', fontWeight: 900, marginBottom: '0.25rem', color: 'var(--muted-foreground)' }}>PRODUCTO</label>
                        <input 
                          type="text" 
                          id={`input-${item.id}`}
                          value={item.product} 
                          onChange={(e) => updateItem(item.id, 'product', e.target.value)} 
                          onFocus={(e) => {
                            const rect = e.currentTarget.getBoundingClientRect();
                            setDropdownPos({ top: rect.bottom + 5, left: rect.left, width: rect.width });
                            setFocusedItemId(`${item.id}-product`);
                            setFocusedRowId(item.id);
                          }}
                          onBlur={() => setTimeout(() => setFocusedItemId(null), 200)}
                          placeholder="Buscar..." 
                          style={{ width: '100%', padding: '0.6rem', borderRadius: '8px', border: '1px solid var(--border)', background: 'var(--card)', outline: 'none', fontSize: '0.85rem', fontWeight: 700 }} 
                        />
                      </div>

                      {/* Lote / Tipo */}
                      <div>
                        <label className="mobile-only" style={{ display: 'block', fontSize: '0.6rem', fontWeight: 900, marginBottom: '0.25rem', color: 'var(--muted-foreground)' }}>{activeCat === 'alevinos' ? 'TIPO' : 'LOTE'}</label>
                        {activeCat === 'alevinos' ? (
                          <select 
                            value={item.batch} 
                            onChange={(e) => updateItem(item.id, 'batch', e.target.value)}
                            style={{ width: '100%', padding: '0.6rem', borderRadius: '8px', border: '1px solid var(--border)', background: 'var(--card)', outline: 'none', fontSize: '0.85rem' }}
                          >
                            <option value="">Seleccionar...</option>
                            <option value="ova">Ova</option>
                            <option value="larva">Larva</option>
                            <option value="alevino">Alevino</option>
                          </select>
                        ) : activeCat === 'insumos' ? (
                          <select 
                            value={item.batch} 
                            onChange={(e) => updateItem(item.id, 'batch', e.target.value)}
                            style={{ width: '100%', padding: '0.6rem', borderRadius: '8px', border: '1px solid var(--border)', background: 'var(--card)', outline: 'none', fontSize: '0.85rem' }}
                          >
                            <option value="gramos">Gramos (g)</option>
                            <option value="kg">Kilogramos (kg)</option>
                            <option value="ml">Mililitros (mL)</option>
                            <option value="litros">Litros (L)</option>
                            <option value="unidades">Unidades</option>
                          </select>
                        ) : (
                          <input type="text" value={item.batch} onChange={(e) => updateItem(item.id, 'batch', e.target.value)} placeholder="Ej: Lote" style={{ width: '100%', padding: '0.6rem', borderRadius: '8px', border: '1px solid var(--border)', background: 'var(--card)', outline: 'none', fontSize: '0.85rem' }} />
                        )}
                      </div>

                      {/* Cantidad */}
                      <div style={{ display: 'flex', gap: '0.5rem' }}>
                        <div style={{ flex: 1 }}>
                          <label className="mobile-only" style={{ display: 'block', fontSize: '0.6rem', fontWeight: 900, marginBottom: '0.25rem', color: 'var(--muted-foreground)' }}>CANT</label>
                          <input type="number" value={item.quantity} onChange={(e) => updateItem(item.id, 'quantity', e.target.value)} placeholder="0" style={{ width: '100%', padding: '0.6rem', borderRadius: '8px', border: '1px solid var(--border)', background: 'var(--card)', outline: 'none', fontSize: '0.85rem', fontWeight: 900 }} />
                        </div>
                        {activeCat === 'alimento' && (
                          <div style={{ flex: 1.2 }}>
                            <label className="mobile-only" style={{ display: 'block', fontSize: '0.6rem', fontWeight: 900, marginBottom: '0.25rem', color: 'var(--muted-foreground)' }}>KILOS</label>
                            <input type="number" value={item.kilos} onChange={(e) => updateItem(item.id, 'kilos', e.target.value)} placeholder="Kg" style={{ width: '100%', padding: '0.6rem', borderRadius: '8px', border: '1px solid var(--border)', background: 'var(--card)', outline: 'none', fontSize: '0.85rem', fontWeight: 900 }} />
                          </div>
                        )}
                      </div>

                      {/* Precio Unitario */}
                      <div style={{ position: 'relative' }}>
                        <label className="mobile-only" style={{ display: 'block', fontSize: '0.6rem', fontWeight: 900, marginBottom: '0.25rem', color: 'var(--muted-foreground)' }}>VALOR UNIT</label>
                        <div style={{ position: 'relative' }}>
                          <span style={{ position: 'absolute', left: '0.5rem', top: '50%', transform: 'translateY(-50%)', fontSize: '0.75rem', fontWeight: 700, color: 'var(--muted-foreground)' }}>$</span>
                          <input 
                            type="text" 
                            value={item.unitPrice ? parseInt(item.unitPrice).toLocaleString() : ''} 
                            onChange={(e) => updateItem(item.id, 'unitPrice', e.target.value.replace(/\D/g, ''))} 
                            placeholder="0" 
                            style={{ width: '100%', padding: '0.6rem 0.6rem 0.6rem 1.2rem', borderRadius: '8px', border: '1px solid var(--border)', background: 'var(--card)', outline: 'none', fontSize: '0.85rem', fontWeight: 800, color: 'var(--primary)' }} 
                          />
                        </div>
                      </div>

                      {/* Botón Eliminar */}
                      <div style={{ width: '40px', display: 'flex', justifyContent: 'center' }}>
                        <button 
                          onClick={() => removeItem(item.id)}
                          style={{ background: 'rgba(239, 68, 68, 0.1)', border: 'none', color: '#ef4444', padding: '0.5rem', borderRadius: '8px', cursor: 'pointer' }}
                        >
                          <Trash2 size={16} />
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
                                <button 
                  onClick={addItem}
                  style={{ marginTop: '1rem', padding: '0.6rem 1.25rem', borderRadius: '8px', border: '1px dashed var(--primary)', background: 'transparent', color: 'var(--primary)', fontWeight: 700, fontSize: '0.85rem', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '0.5rem' }}
                >
                  <Plus size={16} /> Agregar Ítem a Factura
                </button>
              </div>

              {/* Footer */}
              <div style={{ display: 'flex', gap: '1rem', borderTop: '1px solid var(--border)', paddingTop: '1.5rem', flexWrap: 'wrap' }}>
                <button onClick={() => setIsModalOpen(false)} style={{ flex: 1, minWidth: '120px', padding: '1rem', borderRadius: '12px', border: '1px solid var(--border)', background: 'transparent', fontWeight: 700, cursor: 'pointer' }}>Cancelar</button>
                <button 
                  onClick={handleRegisterInvoice}
                  className="btn-primary" 
                  style={{ 
                    flex: 2, 
                    padding: '1rem', 
                    borderRadius: '12px', 
                    fontWeight: 800,
                    background: activeCat === 'alimento' ? 'var(--primary)' : 
                               activeCat === 'farmacia' ? '#10b981' : 
                               activeCat === 'insumos' ? '#f59e0b' : 'var(--primary)'
                  }}
                >
                  Registrar {activeCat === 'alimento' ? 'Factura Alimento' : activeCat === 'farmacia' ? 'Medicamentos' : 'en Inventario'}
                </button>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

      {/* Modal: Mis Facturas / Cuentas por Pagar */}
      <AnimatePresence>
        {isInvoiceListOpen && (
          <div style={{ position: 'fixed', inset: 0, zIndex: 1000, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '1rem' }}>
            <motion.div 
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setIsInvoiceListOpen(false)}
              style={{ position: 'absolute', inset: 0, background: 'rgba(255,255,255,0.1)', backdropFilter: 'blur(20px)' }} 
            />
            <motion.div 
              initial={{ scale: 0.9, opacity: 0, y: 30 }}
              animate={{ scale: 1, opacity: 1, y: 0 }}
              exit={{ scale: 0.9, opacity: 0, y: 30 }}
              className="card-premium" 
              style={{ width: '95%', maxWidth: '800px', maxHeight: '85vh', position: 'relative', zIndex: 10, padding: 'clamp(1rem, 5vw, 2.5rem)', display: 'flex', flexDirection: 'column', boxShadow: '0 0 80px rgba(0,0,0,0.2)' }}
            >
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '2rem' }}>
                <div>
                  <h2 style={{ fontSize: '1.5rem', fontWeight: 800, display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                    <FileText size={28} style={{ color: 'var(--primary)' }} />
                    Cuentas por Pagar (Facturas)
                  </h2>
                   <p style={{ color: 'var(--muted-foreground)' }}>Gestión de vencimientos y pagos a proveedores.</p>
                </div>
                <button onClick={() => setIsInvoiceListOpen(false)} style={{ background: 'transparent', border: 'none', color: 'var(--muted-foreground)', cursor: 'pointer', fontSize: '1.5rem' }}>&times;</button>
              </div>

              <div style={{ flex: 1, overflow: 'auto' }}>
                <table style={{ width: '100%', borderCollapse: 'collapse', minWidth: '600px' }}>
                  <thead>
                    <tr style={{ textAlign: 'left', fontSize: '0.75rem', textTransform: 'uppercase', color: 'var(--muted-foreground)', borderBottom: '1px solid var(--border)' }}>
                      <th style={{ padding: '0.75rem' }}>Factura / Proveedor</th>
                      <th style={{ padding: '0.75rem' }}>Monto</th>
                      <th style={{ padding: '0.75rem' }}>Vencimiento</th>
                      <th style={{ padding: '0.75rem', textAlign: 'right' }}>Acción</th>
                    </tr>
                  </thead>
                  <tbody>
                    {invoices
                      .filter(inv => inv.category === activeCat)
                      .sort((a, b) => new Date(a.vencimiento).getTime() - new Date(b.vencimiento).getTime())
                      .map((inv) => {
                      const today = new Date();
                      const vDate = new Date(inv.vencimiento);
                      const diffTime = vDate.getTime() - today.getTime();
                      const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
                      
                      let color = '#10b981'; // Green
                      if (inv.status === 'Pagada') color = 'var(--muted-foreground)';
                      else if (diffDays <= 0) color = '#ef4444'; // Overdue
                      else if (diffDays <= 3) color = '#f59e0b'; // Near

                      return (
                        <tr key={inv.id} style={{ borderBottom: '1px solid var(--border)', opacity: inv.status === 'Pagada' ? 0.6 : 1 }}>
                          <td style={{ padding: '1rem 0.75rem' }}>
                            <div style={{ fontWeight: 800, fontSize: '0.95rem' }}>{inv.nro}</div>
                            <div style={{ fontSize: '0.75rem', color: 'var(--muted-foreground)' }}>{inv.proveedor}</div>
                          </td>
                          <td style={{ padding: '1rem 0.75rem', fontWeight: 700 }}>${inv.monto.toLocaleString()}</td>
                          <td style={{ padding: '1rem 0.75rem' }}>
                            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', color, fontWeight: 700 }}>
                              <Clock size={14} />
                              {inv.vencimiento}
                            </div>
                            <div style={{ fontSize: '0.65rem', color }}>
                              {inv.status === 'Pagada' ? 'PAGADA' : diffDays <= 0 ? 'VENCIDA' : `Vence en ${diffDays} días`}
                            </div>
                          </td>
                          <td style={{ padding: '1rem 0.75rem', textAlign: 'right' }}>
                            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', justifyContent: 'flex-end' }}>
                              {inv.status !== 'Pagada' ? (
                                <button 
                                  onClick={async () => {
                                    const { error } = await supabase.from('invoices').update({ status: 'pagada' }).eq('id', inv.id);
                                    if (error) toast.error('Error: ' + error.message);
                                    else fetchInvoices();
                                  }}
                                  style={{ padding: '0.5rem 1rem', borderRadius: '8px', border: '1px solid #10b981', background: 'rgba(16, 185, 129, 0.05)', color: '#10b981', fontSize: '0.75rem', fontWeight: 800, cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '0.4rem' }}
                                >
                                  <CheckCircle2 size={14} /> Pagada
                                </button>
                              ) : (
                                <div style={{ color: '#10b981', display: 'flex', alignItems: 'center', gap: '0.4rem', fontSize: '0.75rem', fontWeight: 800 }}>
                                  <CheckCircle2 size={16} /> Pagada
                                </div>
                              )}
                              <button
                                onClick={() => handleDeleteInvoice(inv.id, inv.nro, activeCat)}
                                style={{ padding: '0.5rem', borderRadius: '8px', border: '1px solid rgba(239,68,68,0.3)', background: 'rgba(239,68,68,0.05)', color: '#ef4444', cursor: 'pointer', display: 'flex', alignItems: 'center' }}
                                title="Eliminar factura"
                              >
                                <Trash2 size={14} />
                              </button>
                            </div>
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

      {/* Modal: Crear Proveedor */}
      <AnimatePresence>
        {isProviderModalOpen && (
          <div style={{ position: 'fixed', inset: 0, zIndex: 1000, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '1rem' }}>
            <motion.div 
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setIsProviderModalOpen(false)}
              style={{ position: 'absolute', inset: 0, background: 'rgba(255,255,255,0.1)', backdropFilter: 'blur(20px)' }} 
            />
            <motion.div 
              initial={{ scale: 0.9, opacity: 0, y: 30 }}
              animate={{ scale: 1, opacity: 1, y: 0 }}
              exit={{ scale: 0.9, opacity: 0, y: 30 }}
              className="card-premium" 
              style={{ width: '100%', maxWidth: '450px', position: 'relative', zIndex: 10, padding: '2.5rem', boxShadow: '0 0 80px rgba(0,0,0,0.2)' }}
            >
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '2rem' }}>
                <div>
                  <h2 style={{ fontSize: '1.5rem', fontWeight: 800, display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                    <Users size={28} style={{ color: 'var(--primary)' }} />
                    Nuevo Proveedor
                  </h2>
                </div>
                <button onClick={() => setIsProviderModalOpen(false)} style={{ background: 'transparent', border: 'none', color: 'var(--muted-foreground)', cursor: 'pointer', fontSize: '1.5rem' }}>&times;</button>
              </div>

              <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
                <div className="premium-input-group">
                  <label className="premium-label">Nombre de Empresa / Persona</label>
                  <input 
                    type="text" 
                    placeholder="Ej: Italcol S.A."
                    value={newProvider.name}
                    onChange={(e) => setNewProvider({...newProvider, name: e.target.value})}
                    className="premium-input"
                  />
                </div>

                <div className="premium-input-group">
                  <label className="premium-label">NIT o Cédula</label>
                  <input 
                    type="text" 
                    placeholder="900.123.456-7"
                    value={newProvider.nit}
                    onChange={(e) => setNewProvider({...newProvider, nit: e.target.value})}
                    className="premium-input"
                  />
                </div>

                <div>
                  <label className="premium-label">Categorías que Suministra</label>
                  <div style={{ display: 'flex', flexWrap: 'wrap', gap: '0.75rem' }}>
                    {['alimento', 'farmacia', 'insumos', 'alevinos', 'equipos'].map(type => (
                      <button
                        key={type}
                        onClick={() => {
                          const types = newProvider.types.includes(type)
                            ? newProvider.types.filter(t => t !== type)
                            : [...newProvider.types, type];
                          setNewProvider({...newProvider, types});
                        }}
                        style={{
                          padding: '0.6rem 1rem',
                          borderRadius: '10px',
                          border: '1.5px solid',
                          borderColor: newProvider.types.includes(type) ? 'var(--primary)' : 'var(--border)',
                          background: newProvider.types.includes(type) ? 'rgba(13, 148, 136, 0.05)' : 'white',
                          color: newProvider.types.includes(type) ? 'var(--primary)' : 'var(--muted-foreground)',
                          fontSize: '0.85rem',
                          fontWeight: 800,
                          cursor: 'pointer',
                          transition: 'all 0.2s ease',
                          textTransform: 'capitalize'
                        }}
                      >
                        {type}
                      </button>
                    ))}
                  </div>
                </div>
                <button 
                  onClick={saveProvider}
                  className="btn-primary" 
                  style={{ width: '100%', padding: '1rem', marginTop: '0.5rem' }}
                >
                  Registrar Proveedor
                </button>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>



      {/* Persistent Product Catalog (Fixed Position) */}
      <AnimatePresence>
        {focusedItemId?.includes('-product') && dropdownPos && focusedRowId !== null && (
          <motion.div 
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0, scale: 0.95 }}
            style={{ 
              position: 'fixed', 
              top: dropdownPos.top, 
              left: dropdownPos.left, 
              width: dropdownPos.width,
              background: 'white', 
              borderRadius: '12px', 
              boxShadow: '0 20px 50px rgba(0,0,0,0.3)', 
              zIndex: 99999, 
              maxHeight: '250px', 
              overflowY: 'auto',
              border: '1px solid var(--border)',
              padding: '5px'
            }}
          >
            {(activeCat === 'alimento' ? foodTypes : 
              activeCat === 'farmacia' ? pharmaProducts :
              activeCat === 'insumos' ? ['Cal Dolomita', 'Melaza', 'Sal Marina', 'Cal Viva', 'Bicarbonato'] :
              activeCat === 'alevinos' ? ['Tilapia Roja', 'Tilapia Nilótica', 'Cachama', 'Trucha Arcoíris', 'Bocachico', 'Yamú', 'Carpa', 'Sábalo', 'Bagre Omnivoro'] :
              ['Splash de 1/2 HP', 'Splash de 1 HP', 'Splash de 1.5 HP', 'Splash de 2 HP', 'Blower 1.0 HP', 'Blower 2.0 HP']
            ).filter(p => {
              const item = items.find(it => it.id === focusedRowId);
              return !item || p.toLowerCase().includes(item.product.toLowerCase());
            }).map(p => (
              <div 
                key={p}
                onClick={() => {
                  updateItem(focusedRowId, 'product', p);
                  setFocusedItemId(null);
                }}
                style={{ 
                  padding: '0.8rem 1rem', 
                  fontSize: '0.85rem', 
                  cursor: 'pointer',
                  borderRadius: '8px',
                  marginBottom: '2px',
                  transition: 'all 0.2s ease',
                  color: 'var(--foreground)',
                  fontWeight: 600
                }}
                onMouseEnter={(e) => {
                  e.currentTarget.style.background = 'var(--primary)';
                  e.currentTarget.style.color = 'white';
                }}
                onMouseLeave={(e) => {
                  e.currentTarget.style.background = 'transparent';
                  e.currentTarget.style.color = 'var(--foreground)';
                }}
              >
                {p}
              </div>
            ))}
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
