# PerfAnalysis Frontend Implementation Plan

**Version**: 1.0
**Created**: 2026-01-11
**Status**: Planning

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Technology Stack](#2-technology-stack)
3. [Architecture Design](#3-architecture-design)
4. [Sprint Plan](#4-sprint-plan)
5. [Component Specifications](#5-component-specifications)
6. [API Integration](#6-api-integration)
7. [State Management](#7-state-management)
8. [Testing Strategy](#8-testing-strategy)
9. [Deployment Strategy](#9-deployment-strategy)
10. [Risk Mitigation](#10-risk-mitigation)

---

## 1. Project Overview

### 1.1 Objective

Build a modern, responsive frontend application to manage the PerfAnalysis performance monitoring ecosystem, replacing the legacy Dash-003 R Shiny dashboard.

### 1.2 Scope

| In Scope | Out of Scope |
|----------|--------------|
| Performance dashboard with time-series charts | Mobile native apps |
| Collector (machine) management | Real-time streaming (Phase 3) |
| Container metrics visualization | AI/ML-based anomaly detection |
| Report generation integration | Custom report builder |
| User authentication and preferences | Multi-language support |
| Collector comparison views | |

### 1.3 Success Criteria

- [ ] Dashboard loads in < 2 seconds
- [ ] All 17 existing API endpoints integrated
- [ ] 80%+ test coverage (unit + integration)
- [ ] Mobile-responsive design
- [ ] Accessibility (WCAG 2.1 AA)
- [ ] Zero critical security vulnerabilities

---

## 2. Technology Stack

### 2.1 Frontend Core

| Technology | Version | Purpose |
|------------|---------|---------|
| React | 18.2+ | UI framework |
| TypeScript | 5.3+ | Type safety |
| Vite | 5.0+ | Build tool |
| React Router | 6.x | Routing |

### 2.2 Styling & UI

| Technology | Version | Purpose |
|------------|---------|---------|
| TailwindCSS | 3.4+ | Utility-first CSS |
| Headless UI | 1.7+ | Accessible components |
| Heroicons | 2.x | Icon library |
| Plotly.js | 2.x | Charting library |

### 2.3 State & Data

| Technology | Version | Purpose |
|------------|---------|---------|
| Zustand | 4.x | Global state |
| TanStack Query | 5.x | Server state / caching |
| Axios | 1.6+ | HTTP client |
| date-fns | 3.x | Date manipulation |

### 2.4 Testing

| Technology | Version | Purpose |
|------------|---------|---------|
| Vitest | 1.x | Unit testing |
| React Testing Library | 14.x | Component testing |
| Playwright | 1.40+ | E2E testing |
| MSW | 2.x | API mocking |

### 2.5 Development Tools

| Technology | Version | Purpose |
|------------|---------|---------|
| ESLint | 8.x | Linting |
| Prettier | 3.x | Code formatting |
| Husky | 9.x | Git hooks |
| lint-staged | 15.x | Pre-commit checks |

---

## 3. Architecture Design

### 3.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         FRONTEND (React SPA)                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                      PRESENTATION LAYER                       │  │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐         │  │
│  │  │ Pages   │  │ Layouts │  │ Charts  │  │ Forms   │         │  │
│  │  └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘         │  │
│  └───────┼────────────┼────────────┼────────────┼───────────────┘  │
│          │            │            │            │                   │
│  ┌───────▼────────────▼────────────▼────────────▼───────────────┐  │
│  │                      BUSINESS LOGIC LAYER                     │  │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐         │  │
│  │  │ Hooks   │  │ Context │  │ Utils   │  │ Types   │         │  │
│  │  └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘         │  │
│  └───────┼────────────┼────────────┼────────────┼───────────────┘  │
│          │            │            │            │                   │
│  ┌───────▼────────────▼────────────▼────────────▼───────────────┐  │
│  │                      DATA ACCESS LAYER                        │  │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐                       │  │
│  │  │ API     │  │ Store   │  │ Cache   │                       │  │
│  │  │ Client  │  │ (Zustand)│ │(TanStack)│                      │  │
│  │  └────┬────┘  └─────────┘  └─────────┘                       │  │
│  └───────┼──────────────────────────────────────────────────────┘  │
│          │                                                          │
└──────────┼──────────────────────────────────────────────────────────┘
           │ HTTPS (JWT Bearer Token)
           ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    XATBACKEND (Django REST API)                      │
│                                                                      │
│  /api/v1/auth/*        - Authentication                             │
│  /dashboard/api/*      - Dashboard data                             │
│  /api/v1/collectors/*  - Collector management                       │
│  /api/v1/reports/*     - Report generation                          │
└─────────────────────────────────────────────────────────────────────┘
```

### 3.2 Directory Structure

```
perf-dashboard/
├── public/
│   ├── favicon.ico
│   └── assets/
├── src/
│   ├── api/                    # API client layer
│   │   ├── client.ts           # Axios instance with interceptors
│   │   ├── auth.ts             # Authentication endpoints
│   │   ├── collectors.ts       # Collector endpoints
│   │   ├── metrics.ts          # Metrics endpoints
│   │   ├── containers.ts       # Container endpoints
│   │   └── reports.ts          # Report endpoints
│   │
│   ├── components/             # Reusable components
│   │   ├── common/             # Shared UI components
│   │   │   ├── Button.tsx
│   │   │   ├── Card.tsx
│   │   │   ├── Loading.tsx
│   │   │   ├── ErrorBoundary.tsx
│   │   │   └── Modal.tsx
│   │   ├── charts/             # Chart components
│   │   │   ├── TimeSeriesChart.tsx
│   │   │   ├── RadarChart.tsx
│   │   │   ├── GaugeChart.tsx
│   │   │   └── ComparisonChart.tsx
│   │   ├── dashboard/          # Dashboard-specific components
│   │   │   ├── CollectorSelector.tsx
│   │   │   ├── TimeRangeSelector.tsx
│   │   │   ├── MetricsGrid.tsx
│   │   │   ├── StatsPanel.tsx
│   │   │   └── PercentileTable.tsx
│   │   ├── collectors/         # Collector management
│   │   │   ├── CollectorList.tsx
│   │   │   ├── CollectorCard.tsx
│   │   │   └── CollectorForm.tsx
│   │   ├── containers/         # Container views
│   │   │   ├── ContainerList.tsx
│   │   │   └── ContainerMetrics.tsx
│   │   └── layout/             # Layout components
│   │       ├── AppLayout.tsx
│   │       ├── Sidebar.tsx
│   │       ├── Header.tsx
│   │       └── Footer.tsx
│   │
│   ├── hooks/                  # Custom React hooks
│   │   ├── useAuth.ts
│   │   ├── useCollectors.ts
│   │   ├── useMetrics.ts
│   │   ├── useContainers.ts
│   │   ├── usePreferences.ts
│   │   └── useDebounce.ts
│   │
│   ├── pages/                  # Page components (routes)
│   │   ├── Dashboard.tsx
│   │   ├── Collectors.tsx
│   │   ├── CollectorDetail.tsx
│   │   ├── Containers.tsx
│   │   ├── Compare.tsx
│   │   ├── Reports.tsx
│   │   ├── Settings.tsx
│   │   ├── Login.tsx
│   │   └── NotFound.tsx
│   │
│   ├── store/                  # Zustand stores
│   │   ├── authStore.ts
│   │   ├── preferencesStore.ts
│   │   └── uiStore.ts
│   │
│   ├── types/                  # TypeScript definitions
│   │   ├── api.ts              # API response types
│   │   ├── models.ts           # Domain models
│   │   └── components.ts       # Component prop types
│   │
│   ├── utils/                  # Utility functions
│   │   ├── formatters.ts       # Number/date formatting
│   │   ├── validators.ts       # Input validation
│   │   ├── constants.ts        # App constants
│   │   └── helpers.ts          # General helpers
│   │
│   ├── App.tsx                 # Root component
│   ├── main.tsx                # Entry point
│   ├── router.tsx              # Route definitions
│   └── index.css               # Global styles (Tailwind)
│
├── tests/
│   ├── unit/                   # Unit tests
│   ├── integration/            # Integration tests
│   └── e2e/                    # Playwright E2E tests
│
├── .env.example                # Environment template
├── .eslintrc.cjs               # ESLint config
├── .prettierrc                 # Prettier config
├── index.html                  # HTML entry
├── package.json
├── tailwind.config.js
├── tsconfig.json
├── vite.config.ts
└── README.md
```

### 3.3 Routing Structure

| Route | Component | Description |
|-------|-----------|-------------|
| `/` | Dashboard | Main dashboard with overview |
| `/login` | Login | Authentication |
| `/collectors` | Collectors | List all collectors |
| `/collectors/:id` | CollectorDetail | Single collector metrics |
| `/collectors/:id/containers` | Containers | Container metrics |
| `/compare` | Compare | Multi-collector comparison |
| `/reports` | Reports | Report generation & gallery |
| `/settings` | Settings | User preferences |
| `*` | NotFound | 404 page |

---

## 4. Sprint Plan

### Sprint 1: Foundation (Weeks 1-2)

**Goal**: Project setup and authentication

| Task | Story Points | Owner |
|------|--------------|-------|
| Initialize Vite + React + TypeScript project | 2 | Frontend |
| Configure TailwindCSS + Headless UI | 2 | Frontend |
| Set up ESLint, Prettier, Husky | 1 | Frontend |
| Create API client with Axios | 3 | Frontend |
| Implement JWT auth endpoints in XATbackend | 5 | Backend |
| Build Login page | 3 | Frontend |
| Build AppLayout with Sidebar | 3 | Frontend |
| Set up Zustand auth store | 2 | Frontend |
| Implement token refresh logic | 3 | Frontend |
| Create protected route wrapper | 2 | Frontend |

**Deliverables**:
- Working login flow
- Authenticated API client
- Basic app shell with navigation

### Sprint 2: Core Dashboard (Weeks 3-4)

**Goal**: Main dashboard with time-series charts

| Task | Story Points | Owner |
|------|--------------|-------|
| Build CollectorSelector component | 3 | Frontend |
| Build TimeRangeSelector component | 2 | Frontend |
| Create TimeSeriesChart wrapper for Plotly | 5 | Frontend |
| Implement useCollectors hook | 3 | Frontend |
| Implement useMetrics hook | 3 | Frontend |
| Build CPU metrics chart | 3 | Frontend |
| Build Memory metrics chart | 3 | Frontend |
| Build Disk I/O chart | 3 | Frontend |
| Build Network chart | 3 | Frontend |
| Create MetricsGrid layout | 2 | Frontend |

**Deliverables**:
- Functional dashboard with 4 metric charts
- Collector selection
- Time range filtering

### Sprint 3: Statistics & Analysis (Weeks 5-6)

**Goal**: Statistics panels and percentile analysis

| Task | Story Points | Owner |
|------|--------------|-------|
| Build StatsPanel component | 3 | Frontend |
| Build PercentileTable component | 3 | Frontend |
| Create RadarChart component | 5 | Frontend |
| Implement collector detail page | 5 | Frontend |
| Add loading states and skeletons | 2 | Frontend |
| Implement error handling | 3 | Frontend |
| Build comparison page | 5 | Frontend |
| Create ComparisonChart component | 5 | Frontend |

**Deliverables**:
- Statistics panel with min/max/avg/p95/p99
- Percentile breakdown tables
- Collector comparison feature

### Sprint 4: Containers & Reports (Weeks 7-8)

**Goal**: Container metrics and R report integration

| Task | Story Points | Owner |
|------|--------------|-------|
| Build ContainerList component | 3 | Frontend |
| Build ContainerMetrics view | 5 | Frontend |
| Create container aggregate charts | 3 | Frontend |
| Implement report generation API | 5 | Backend |
| Build ReportGenerator UI | 5 | Frontend |
| Build ReportGallery component | 3 | Frontend |
| Add report download functionality | 2 | Frontend |
| Implement user preferences | 3 | Frontend |

**Deliverables**:
- Container metrics dashboard
- Report generation from UI
- Report gallery with downloads

### Sprint 5: Polish & Testing (Weeks 9-10)

**Goal**: Testing, optimization, and deployment

| Task | Story Points | Owner |
|------|--------------|-------|
| Write unit tests (80% coverage) | 8 | Frontend |
| Write E2E tests with Playwright | 5 | Frontend |
| Performance optimization | 3 | Frontend |
| Accessibility audit and fixes | 3 | Frontend |
| Mobile responsiveness | 3 | Frontend |
| Documentation | 2 | Frontend |
| CI/CD pipeline setup | 3 | DevOps |
| Production deployment | 3 | DevOps |

**Deliverables**:
- Production-ready application
- Complete test suite
- CI/CD pipeline

---

## 5. Component Specifications

### 5.1 TimeSeriesChart

**Purpose**: Reusable Plotly.js wrapper for time-series data

**Props**:
```typescript
interface TimeSeriesChartProps {
  data: {
    x: Date[];
    y: number[];
    name: string;
    color?: string;
  }[];
  title: string;
  yAxisLabel: string;
  yAxisRange?: [number, number];
  height?: number;
  showLegend?: boolean;
  annotations?: Annotation[];
}
```

**Features**:
- Zoom and pan
- Tooltip with values
- Export to PNG
- Responsive sizing
- Multiple series support

### 5.2 CollectorSelector

**Purpose**: Dropdown to select active collector

**Props**:
```typescript
interface CollectorSelectorProps {
  collectors: Collector[];
  selected: number | null;
  onSelect: (id: number) => void;
  loading?: boolean;
}
```

**Features**:
- Search/filter
- Show status indicator (online/offline)
- Display last update time
- Keyboard navigation

### 5.3 TimeRangeSelector

**Purpose**: Select time range for data queries

**Props**:
```typescript
interface TimeRangeSelectorProps {
  value: TimeRange;
  onChange: (range: TimeRange) => void;
  customRange?: boolean;
}

type TimeRange = '1h' | '6h' | '24h' | '7d' | '30d' | 'all' | 'custom';
```

**Features**:
- Preset buttons (1H, 6H, 24H, 7D, 30D, All)
- Custom date picker
- URL sync for bookmarking

### 5.4 StatsPanel

**Purpose**: Display summary statistics for metrics

**Props**:
```typescript
interface StatsPanelProps {
  stats: {
    min: number;
    max: number;
    avg: number;
    p95: number;
    p99: number;
    current: number;
  };
  label: string;
  unit: string;
  trend?: 'up' | 'down' | 'stable';
}
```

**Features**:
- Trend indicator
- Sparkline mini-chart
- Color coding (green/yellow/red)

### 5.5 PercentileTable

**Purpose**: Detailed percentile breakdown

**Props**:
```typescript
interface PercentileTableProps {
  data: {
    metric: string;
    p50: number;
    p75: number;
    p90: number;
    p95: number;
    p99: number;
    p100: number;
  }[];
  sortable?: boolean;
}
```

**Features**:
- Sortable columns
- Export to CSV
- Highlight outliers

---

## 6. API Integration

### 6.1 API Client Configuration

```typescript
// src/api/client.ts
import axios from 'axios';
import { useAuthStore } from '../store/authStore';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000';

export const apiClient = axios.create({
  baseURL: API_BASE_URL,
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor - add auth token
apiClient.interceptors.request.use((config) => {
  const token = useAuthStore.getState().accessToken;
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Response interceptor - handle 401 and refresh
apiClient.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config;

    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true;

      try {
        const newToken = await refreshAccessToken();
        originalRequest.headers.Authorization = `Bearer ${newToken}`;
        return apiClient(originalRequest);
      } catch (refreshError) {
        useAuthStore.getState().logout();
        window.location.href = '/login';
        return Promise.reject(refreshError);
      }
    }

    return Promise.reject(error);
  }
);
```

### 6.2 API Endpoints

```typescript
// src/api/collectors.ts
import { apiClient } from './client';
import { Collector, CollectorMetrics } from '../types/models';

export const collectorsApi = {
  list: () =>
    apiClient.get<Collector[]>('/dashboard/api/collectors/'),

  get: (id: number) =>
    apiClient.get<Collector>(`/dashboard/api/collectors/${id}/`),

  getCPU: (id: number, hours?: number) =>
    apiClient.get<CollectorMetrics>(`/dashboard/api/collectors/${id}/cpu/`, {
      params: { hours }
    }),

  getMemory: (id: number, hours?: number) =>
    apiClient.get<CollectorMetrics>(`/dashboard/api/collectors/${id}/memory/`, {
      params: { hours }
    }),

  getDisk: (id: number, hours?: number) =>
    apiClient.get<CollectorMetrics>(`/dashboard/api/collectors/${id}/disk/`, {
      params: { hours }
    }),

  getNetwork: (id: number, hours?: number) =>
    apiClient.get<CollectorMetrics>(`/dashboard/api/collectors/${id}/network/`, {
      params: { hours }
    }),

  getStats: (id: number, hours?: number) =>
    apiClient.get(`/dashboard/api/collectors/${id}/stats/`, {
      params: { hours }
    }),

  getPercentiles: (id: number, hours?: number) =>
    apiClient.get(`/dashboard/api/collectors/${id}/percentiles/`, {
      params: { hours }
    }),

  compare: (ids: number[], hours?: number) =>
    apiClient.get('/dashboard/api/compare/', {
      params: { collectors: ids.join(','), hours }
    }),
};
```

### 6.3 TanStack Query Hooks

```typescript
// src/hooks/useCollectors.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { collectorsApi } from '../api/collectors';

export function useCollectors() {
  return useQuery({
    queryKey: ['collectors'],
    queryFn: () => collectorsApi.list().then(res => res.data),
    staleTime: 30000, // 30 seconds
  });
}

export function useCollectorCPU(id: number, hours: number = 24) {
  return useQuery({
    queryKey: ['collector', id, 'cpu', hours],
    queryFn: () => collectorsApi.getCPU(id, hours).then(res => res.data),
    enabled: !!id,
    staleTime: 60000, // 1 minute
    refetchInterval: 60000, // Auto-refresh every minute
  });
}

export function useCollectorComparison(ids: number[], hours: number = 24) {
  return useQuery({
    queryKey: ['collectors', 'compare', ids, hours],
    queryFn: () => collectorsApi.compare(ids, hours).then(res => res.data),
    enabled: ids.length >= 2,
  });
}
```

---

## 7. State Management

### 7.1 Auth Store

```typescript
// src/store/authStore.ts
import { create } from 'zustand';
import { persist } from 'zustand/middleware';

interface AuthState {
  accessToken: string | null;
  refreshToken: string | null;
  user: User | null;
  isAuthenticated: boolean;
  login: (tokens: { access: string; refresh: string }, user: User) => void;
  logout: () => void;
  setAccessToken: (token: string) => void;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      accessToken: null,
      refreshToken: null,
      user: null,
      isAuthenticated: false,

      login: (tokens, user) => set({
        accessToken: tokens.access,
        refreshToken: tokens.refresh,
        user,
        isAuthenticated: true,
      }),

      logout: () => set({
        accessToken: null,
        refreshToken: null,
        user: null,
        isAuthenticated: false,
      }),

      setAccessToken: (token) => set({ accessToken: token }),
    }),
    {
      name: 'auth-storage',
      partialize: (state) => ({
        refreshToken: state.refreshToken,
        user: state.user,
      }),
    }
  )
);
```

### 7.2 Preferences Store

```typescript
// src/store/preferencesStore.ts
import { create } from 'zustand';
import { persist } from 'zustand/middleware';

interface PreferencesState {
  defaultTimeRange: TimeRange;
  defaultCollector: number | null;
  chartTheme: 'light' | 'dark';
  refreshInterval: number; // seconds
  setPreference: <K extends keyof PreferencesState>(
    key: K,
    value: PreferencesState[K]
  ) => void;
}

export const usePreferencesStore = create<PreferencesState>()(
  persist(
    (set) => ({
      defaultTimeRange: '24h',
      defaultCollector: null,
      chartTheme: 'light',
      refreshInterval: 60,

      setPreference: (key, value) => set({ [key]: value }),
    }),
    { name: 'preferences-storage' }
  )
);
```

---

## 8. Testing Strategy

### 8.1 Unit Tests (Vitest)

**Coverage Target**: 80%

```typescript
// tests/unit/hooks/useCollectors.test.ts
import { renderHook, waitFor } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { useCollectors } from '../../../src/hooks/useCollectors';
import { server } from '../../mocks/server';
import { rest } from 'msw';

const queryClient = new QueryClient({
  defaultOptions: { queries: { retry: false } },
});

const wrapper = ({ children }) => (
  <QueryClientProvider client={queryClient}>
    {children}
  </QueryClientProvider>
);

describe('useCollectors', () => {
  it('fetches collectors successfully', async () => {
    const { result } = renderHook(() => useCollectors(), { wrapper });

    await waitFor(() => expect(result.current.isSuccess).toBe(true));

    expect(result.current.data).toHaveLength(2);
    expect(result.current.data[0].name).toBe('pcc-test-vm');
  });

  it('handles error state', async () => {
    server.use(
      rest.get('/dashboard/api/collectors/', (req, res, ctx) => {
        return res(ctx.status(500));
      })
    );

    const { result } = renderHook(() => useCollectors(), { wrapper });

    await waitFor(() => expect(result.current.isError).toBe(true));
  });
});
```

### 8.2 Component Tests

```typescript
// tests/unit/components/TimeRangeSelector.test.tsx
import { render, screen, fireEvent } from '@testing-library/react';
import { TimeRangeSelector } from '../../../src/components/dashboard/TimeRangeSelector';

describe('TimeRangeSelector', () => {
  it('renders all time range options', () => {
    render(<TimeRangeSelector value="24h" onChange={() => {}} />);

    expect(screen.getByText('1H')).toBeInTheDocument();
    expect(screen.getByText('6H')).toBeInTheDocument();
    expect(screen.getByText('24H')).toBeInTheDocument();
    expect(screen.getByText('7D')).toBeInTheDocument();
    expect(screen.getByText('30D')).toBeInTheDocument();
    expect(screen.getByText('All')).toBeInTheDocument();
  });

  it('calls onChange when option selected', () => {
    const onChange = vi.fn();
    render(<TimeRangeSelector value="24h" onChange={onChange} />);

    fireEvent.click(screen.getByText('7D'));

    expect(onChange).toHaveBeenCalledWith('7d');
  });

  it('highlights the selected option', () => {
    render(<TimeRangeSelector value="7d" onChange={() => {}} />);

    const selectedButton = screen.getByText('7D');
    expect(selectedButton).toHaveClass('bg-blue-600');
  });
});
```

### 8.3 E2E Tests (Playwright)

```typescript
// tests/e2e/dashboard.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Dashboard', () => {
  test.beforeEach(async ({ page }) => {
    // Login first
    await page.goto('/login');
    await page.fill('[name="username"]', 'testuser');
    await page.fill('[name="password"]', 'testpass');
    await page.click('button[type="submit"]');
    await page.waitForURL('/');
  });

  test('displays collector list', async ({ page }) => {
    await expect(page.getByTestId('collector-selector')).toBeVisible();
    await expect(page.getByText('pcc-test-vm')).toBeVisible();
  });

  test('loads CPU chart when collector selected', async ({ page }) => {
    await page.click('[data-testid="collector-selector"]');
    await page.click('text=pcc-test-vm');

    await expect(page.getByTestId('cpu-chart')).toBeVisible();
    await expect(page.locator('.plotly')).toBeVisible();
  });

  test('time range changes update charts', async ({ page }) => {
    await page.click('[data-testid="collector-selector"]');
    await page.click('text=pcc-test-vm');

    // Wait for initial load
    await expect(page.getByTestId('cpu-chart')).toBeVisible();

    // Change time range
    await page.click('text=7D');

    // Verify API call was made with new range
    const request = await page.waitForRequest(
      (req) => req.url().includes('/cpu/') && req.url().includes('hours=168')
    );
    expect(request).toBeTruthy();
  });
});
```

---

## 9. Deployment Strategy

### 9.1 Build Configuration

```typescript
// vite.config.ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  build: {
    outDir: 'dist',
    sourcemap: true,
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['react', 'react-dom', 'react-router-dom'],
          charts: ['plotly.js'],
          query: ['@tanstack/react-query'],
        },
      },
    },
  },
  server: {
    proxy: {
      '/api': {
        target: 'http://localhost:8000',
        changeOrigin: true,
      },
      '/dashboard': {
        target: 'http://localhost:8000',
        changeOrigin: true,
      },
    },
  },
});
```

### 9.2 Docker Configuration

```dockerfile
# Dockerfile
FROM node:20-alpine as builder

WORKDIR /app
COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

```nginx
# nginx.conf
server {
    listen 80;
    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location /api {
        proxy_pass http://xatbackend:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location /dashboard/api {
        proxy_pass http://xatbackend:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### 9.3 CI/CD Pipeline (GitHub Actions)

```yaml
# .github/workflows/ci.yml
name: CI/CD

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - run: npm ci
      - run: npm run lint
      - run: npm run test:coverage
      - run: npm run build

      - name: Upload coverage
        uses: codecov/codecov-action@v3

  e2e:
    runs-on: ubuntu-latest
    needs: test
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - run: npm ci
      - run: npx playwright install --with-deps
      - run: npm run test:e2e

      - uses: actions/upload-artifact@v4
        if: failure()
        with:
          name: playwright-report
          path: playwright-report/

  deploy:
    runs-on: ubuntu-latest
    needs: [test, e2e]
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4

      - name: Build and push Docker image
        uses: docker/build-push-action@v5
        with:
          push: true
          tags: ${{ secrets.REGISTRY }}/perf-dashboard:${{ github.sha }}

      - name: Deploy to Azure
        uses: azure/webapps-deploy@v2
        with:
          app-name: perf-dashboard
          images: ${{ secrets.REGISTRY }}/perf-dashboard:${{ github.sha }}
```

---

## 10. Risk Mitigation

### 10.1 Technical Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| API performance with large datasets | Medium | High | Implement pagination, lazy loading, data sampling |
| Plotly.js bundle size | High | Medium | Dynamic imports, tree shaking, consider alternatives |
| Browser compatibility | Low | Medium | Test matrix, polyfills, CSS fallbacks |
| Real-time updates complexity | Medium | High | Start with polling, WebSocket in Phase 3 |

### 10.2 Project Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Scope creep | High | High | Strict sprint scope, feature flags |
| XATbackend API changes | Medium | Medium | API versioning, contract tests |
| Performance requirements | Medium | High | Early performance testing, budgets |
| Team availability | Medium | Medium | Cross-training, documentation |

### 10.3 Fallback Options

1. **Charting**: If Plotly.js too heavy, fallback to Chart.js or ECharts
2. **State**: If Zustand insufficient, migrate to Redux Toolkit
3. **Styling**: If TailwindCSS rejected, fallback to CSS Modules
4. **Auth**: If JWT complex, extend existing session auth

---

## Appendix A: Type Definitions

```typescript
// src/types/models.ts

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
  created_at: string;
  updated_at: string;
}

export interface MetricDataPoint {
  timestamp: string;
  value: number;
}

export interface CPUMetrics {
  user: MetricDataPoint[];
  system: MetricDataPoint[];
  idle: MetricDataPoint[];
  iowait: MetricDataPoint[];
  steal?: MetricDataPoint[];
}

export interface MemoryMetrics {
  used: MetricDataPoint[];
  available: MetricDataPoint[];
  cached: MetricDataPoint[];
  buffers: MetricDataPoint[];
  percent_used: MetricDataPoint[];
}

export interface DiskMetrics {
  read_bytes: MetricDataPoint[];
  write_bytes: MetricDataPoint[];
  read_ops: MetricDataPoint[];
  write_ops: MetricDataPoint[];
  utilization?: MetricDataPoint[];
}

export interface NetworkMetrics {
  rx_bytes: MetricDataPoint[];
  tx_bytes: MetricDataPoint[];
  rx_packets: MetricDataPoint[];
  tx_packets: MetricDataPoint[];
}

export interface Stats {
  min: number;
  max: number;
  avg: number;
  stddev: number;
  p50: number;
  p75: number;
  p90: number;
  p95: number;
  p99: number;
  p100: number;
}

export interface Container {
  id: number;
  container_id: string;
  name: string;
  image: string;
  status: string;
  collector_id: number;
  created_at: string;
}

export interface User {
  id: number;
  username: string;
  email: string;
  first_name?: string;
  last_name?: string;
}

export type TimeRange = '1h' | '6h' | '24h' | '7d' | '30d' | 'all' | 'custom';
```

---

## Appendix B: Environment Variables

```bash
# .env.example

# API Configuration
VITE_API_URL=http://localhost:8000
VITE_WS_URL=ws://localhost:8000

# Feature Flags
VITE_ENABLE_CONTAINERS=true
VITE_ENABLE_REPORTS=true
VITE_ENABLE_REALTIME=false

# Analytics (optional)
VITE_GA_TRACKING_ID=

# Sentry (optional)
VITE_SENTRY_DSN=

# Build Info
VITE_APP_VERSION=$npm_package_version
VITE_BUILD_DATE=$BUILD_DATE
```

---

**Document Version**: 1.0
**Last Updated**: 2026-01-11
**Next Review**: After Sprint 1 completion
