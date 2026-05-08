export interface Profile {
  id: string;
  role: 'admin' | 'propietario' | 'tecnico' | 'operario';
  is_superadmin: boolean;
  full_name?: string;
  email?: string;
}

export interface Pond {
  id: string;
  name: string;
  is_polyculture: boolean;
  status: 'vacio' | 'con_peces' | 'mantenimiento';
  current_biomass_kg?: number;
  current_species?: string;
  current_count?: number;
  unit_id: string;
}

export interface PondSpecies {
  estanque_id: string;
  species_name: string;
  current_biomass_kg: number;
  unit_id: string;
}

export interface StatDetail {
  label: string;
  value: string | number;
  unit: string;
}

export interface DashboardStats {
  biomass: {
    total: number;
    details: StatDetail[];
  };
  consumption: {
    total: number;
    details: StatDetail[];
  };
  mortality: {
    total: number;
    percent: string;
    details: StatDetail[];
  };
  inventory: {
    total: number;
    details: StatDetail[];
  };
}

export interface AlertThresholds {
  oxygenMin: number;
  oxygenMax: number;
  tempMin: number;
  tempMax: number;
  phMin: number;
  phMax: number;
  mortalityMax: number;
  inventoryMin: Record<string, number>;
}

export interface FinanceData {
  total: number;
  food: number;
  seeds: number;
  pending: number;
}

export interface ChartDataPoint {
  name: string;
  value: number;
}

export interface WaterQualityRecord {
  id: string;
  estanque_id: string;
  date: string;
  hour: string;
  o2_mg_l: number;
  o2_perc: number;
  ph: number;
  temperature_c: number;
  alkalinity?: number;
  ammonia_mg_l?: number;
  nitrite_mg_l?: number;
  nitrate_mg_l?: number;
}

export interface Unit {
  id: string;
  name: string;
  subscriptions?: {
    plan_type: 'basic' | 'premium';
  };
}
