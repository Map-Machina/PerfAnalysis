// API Response types
export interface ApiResponse<T> {
  data: T;
  status: number;
  message?: string;
}

export interface ApiError {
  error: string;
  message: string;
  status: number;
}

// Authentication
export interface User {
  id: number;
  username: string;
  email: string;
  first_name?: string;
  last_name?: string;
}

export interface AuthTokens {
  access: string;
  refresh: string;
}

export interface LoginCredentials {
  username: string;
  password: string;
}

// Collectors (Machines)
export interface Collector {
  id: number;
  name: string;
  hostname: string;
  ip_address: string;
  status: 'online' | 'offline' | 'unknown';
  last_seen: string;
  os_info?: string;
  cpu_model?: string;
  cpu_count?: number;
  memory_total_gb?: number;
  cloud_provider?: 'azure' | 'oci' | 'aws' | 'gcp' | 'on-premise';
  region?: string;
  instance_type?: string;
  created_at: string;
  updated_at: string;
}

// Metric data points
export interface MetricDataPoint {
  timestamp: string;
  value: number;
}

export interface MetricSeries {
  name: string;
  data: MetricDataPoint[];
  color?: string;
}

// CPU Metrics
export interface CPUMetrics {
  timestamps: string[];
  user: number[];
  system: number[];
  idle: number[];
  iowait: number[];
  steal?: number[];
  irq?: number[];
  softirq?: number[];
}

// Memory Metrics
export interface MemoryMetrics {
  timestamps: string[];
  used: number[];
  available: number[];
  cached: number[];
  buffers: number[];
  percent_used: number[];
  total_gb: number;
}

// Disk Metrics
export interface DiskMetrics {
  timestamps: string[];
  devices: {
    name: string;
    read_bytes: number[];
    write_bytes: number[];
    read_ops: number[];
    write_ops: number[];
    utilization?: number[];
  }[];
}

// Network Metrics
export interface NetworkMetrics {
  timestamps: string[];
  interfaces: {
    name: string;
    rx_bytes: number[];
    tx_bytes: number[];
    rx_packets: number[];
    tx_packets: number[];
    utilization?: number[];
  }[];
}

// Statistics
export interface MetricStats {
  min: number;
  max: number;
  avg: number;
  stddev: number;
  current: number;
}

export interface PercentileStats {
  p50: number;
  p75: number;
  p90: number;
  p95: number;
  p97_5: number;
  p99: number;
  p100: number;
}

export interface CollectorStats {
  cpu: {
    user: MetricStats & PercentileStats;
    system: MetricStats & PercentileStats;
    iowait: MetricStats & PercentileStats;
  };
  memory: {
    percent_used: MetricStats & PercentileStats;
  };
  disk: {
    [device: string]: {
      read_ops: MetricStats & PercentileStats;
      write_ops: MetricStats & PercentileStats;
    };
  };
  network: {
    [interface_name: string]: {
      rx_bytes: MetricStats & PercentileStats;
      tx_bytes: MetricStats & PercentileStats;
    };
  };
}

// Containers
export interface Container {
  id: number;
  container_id: string;
  name: string;
  image: string;
  status: 'running' | 'stopped' | 'paused' | 'exited';
  collector_id: number;
  cpu_percent: number;
  memory_percent: number;
  memory_usage_mb: number;
  network_rx_bytes: number;
  network_tx_bytes: number;
  created_at: string;
  updated_at: string;
}

export interface ContainerMetrics {
  timestamps: string[];
  cpu_percent: number[];
  memory_percent: number[];
  memory_usage_mb: number[];
  network_rx_bytes: number[];
  network_tx_bytes: number[];
}

// Comparison
export interface ComparisonData {
  collectors: Collector[];
  metrics: {
    cpu: {
      [collectorId: number]: CPUMetrics;
    };
    memory: {
      [collectorId: number]: MemoryMetrics;
    };
  };
  stats: {
    [collectorId: number]: CollectorStats;
  };
}

// Reports
export interface Report {
  id: number;
  name: string;
  collector_id: number;
  collector_name: string;
  status: 'pending' | 'generating' | 'completed' | 'failed';
  format: 'html' | 'pdf';
  file_url?: string;
  file_size_bytes?: number;
  time_range_hours: number;
  created_at: string;
  completed_at?: string;
  error_message?: string;
}

export interface ReportGenerateRequest {
  collector_id: number;
  format: 'html' | 'pdf';
  time_range_hours: number;
  include_containers?: boolean;
}

// User Preferences
export interface DashboardPreferences {
  default_time_range: TimeRange;
  default_collector_id?: number;
  chart_theme: 'light' | 'dark';
  refresh_interval_seconds: number;
  show_containers: boolean;
  visible_metrics: ('cpu' | 'memory' | 'disk' | 'network')[];
}

// Time ranges
export type TimeRange = '1h' | '6h' | '24h' | '7d' | '30d' | 'all' | 'custom';

export interface CustomTimeRange {
  start: Date;
  end: Date;
}

// UI State
export interface LoadingState {
  isLoading: boolean;
  error: string | null;
}

export interface PaginationState {
  page: number;
  pageSize: number;
  totalItems: number;
  totalPages: number;
}

// Chart configuration
export interface ChartConfig {
  title: string;
  yAxisLabel: string;
  yAxisRange?: [number, number];
  showLegend?: boolean;
  height?: number;
}
