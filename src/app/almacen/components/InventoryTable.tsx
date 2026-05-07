'use client';

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

interface InventoryTableProps {
  items: InventoryItem[];
  category: string;
}

export function InventoryTable({ items, category }: InventoryTableProps) {
  return (
    <div style={{ width: '100%', overflowX: 'auto', padding: '0 1.5rem 1.5rem' }} className="no-scrollbar">
      <table className="almacen-table-responsive" style={{ width: '100%', minWidth: '800px', borderCollapse: 'collapse', textAlign: 'left' }}>
        <thead>
          <tr style={{ borderBottom: '1px solid var(--border)', fontSize: '0.75rem', textTransform: 'uppercase', color: 'var(--muted-foreground)', letterSpacing: '0.05em' }}>
            <th style={{ padding: '1rem 0.5rem', fontWeight: 800 }}>Producto</th>
            <th style={{ padding: '1rem 0.5rem', fontWeight: 800 }}>Lote</th>
            <th style={{ padding: '1rem 0.5rem', fontWeight: 800 }}>Stock Actual</th>
            <th style={{ padding: '1rem 0.5rem', fontWeight: 800 }}>Unidad</th>
            <th style={{ padding: '1rem 0.5rem', fontWeight: 800 }}>Costo Promedio</th>
            <th style={{ padding: '1rem 0.5rem', fontWeight: 800 }}>Último Ingreso</th>
          </tr>
        </thead>
        <tbody>
          {items.length > 0 ? items.map((item) => (
            <tr key={item.id} style={{ borderBottom: '1px solid var(--border)', transition: 'background 0.2s' }} onMouseEnter={(e) => e.currentTarget.style.background = 'rgba(2, 6, 23, 0.01)'} onMouseLeave={(e) => e.currentTarget.style.background = 'transparent'}>
              <td style={{ padding: '1.25rem 0.5rem', fontWeight: 800, color: 'var(--foreground)' }}>{item.name}</td>
              <td style={{ padding: '1.25rem 0.5rem', color: 'var(--muted-foreground)', fontWeight: 600, fontSize: '0.85rem' }}>{item.lote || '---'}</td>
              <td style={{ padding: '1.25rem 0.5rem' }}>
                <span style={{ 
                  padding: '6px 12px', 
                  borderRadius: '8px', 
                  background: Number(item.current_stock) <= 10 ? 'rgba(239, 68, 68, 0.1)' : 'rgba(16, 185, 129, 0.1)',
                  color: Number(item.current_stock) <= 10 ? '#ef4444' : '#10b981',
                  fontWeight: 900,
                  fontSize: '0.9rem',
                  display: 'inline-block'
                }}>
                  {Number(item.current_stock).toLocaleString()}
                </span>
              </td>
              <td style={{ padding: '1.25rem 0.5rem', color: 'var(--muted-foreground)', fontWeight: 700, fontSize: '0.85rem' }}>{item.unit}</td>
              <td style={{ padding: '1.25rem 0.5rem', fontWeight: 800, color: 'var(--primary)' }}>
                {item.costo_promedio ? `$${item.costo_promedio.toLocaleString()}` : '---'}
              </td>
              <td style={{ padding: '1.25rem 0.5rem', color: 'var(--muted-foreground)', fontSize: '0.85rem', fontWeight: 600 }}>
                {item.last_entry ? new Date(item.last_entry).toLocaleDateString() : 'N/A'}
              </td>
            </tr>
          )) : (
            <tr>
              <td colSpan={6} style={{ padding: '5rem 0', textAlign: 'center', color: 'var(--muted-foreground)', fontWeight: 700 }}>
                No hay productos registrados en esta categoría.
              </td>
            </tr>
          )}
        </tbody>
      </table>
    </div>
  );
}
