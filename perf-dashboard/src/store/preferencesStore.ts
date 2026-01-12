import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';
import { TimeRange } from '@/types';

interface PreferencesState {
  // Dashboard preferences
  defaultTimeRange: TimeRange;
  defaultCollectorId: number | null;
  chartTheme: 'light' | 'dark';
  refreshIntervalSeconds: number;
  showContainers: boolean;
  visibleMetrics: ('cpu' | 'memory' | 'disk' | 'network')[];

  // UI preferences
  sidebarCollapsed: boolean;
  compactMode: boolean;

  // Actions
  setDefaultTimeRange: (range: TimeRange) => void;
  setDefaultCollector: (id: number | null) => void;
  setChartTheme: (theme: 'light' | 'dark') => void;
  setRefreshInterval: (seconds: number) => void;
  setShowContainers: (show: boolean) => void;
  setVisibleMetrics: (metrics: ('cpu' | 'memory' | 'disk' | 'network')[]) => void;
  toggleSidebar: () => void;
  setCompactMode: (compact: boolean) => void;
  resetToDefaults: () => void;
}

const defaultPreferences = {
  defaultTimeRange: '24h' as TimeRange,
  defaultCollectorId: null,
  chartTheme: 'light' as const,
  refreshIntervalSeconds: 60,
  showContainers: true,
  visibleMetrics: ['cpu', 'memory', 'disk', 'network'] as const,
  sidebarCollapsed: false,
  compactMode: false,
};

export const usePreferencesStore = create<PreferencesState>()(
  persist(
    (set) => ({
      // Initial state
      ...defaultPreferences,

      // Actions
      setDefaultTimeRange: (range: TimeRange) =>
        set({ defaultTimeRange: range }),

      setDefaultCollector: (id: number | null) =>
        set({ defaultCollectorId: id }),

      setChartTheme: (theme: 'light' | 'dark') =>
        set({ chartTheme: theme }),

      setRefreshInterval: (seconds: number) =>
        set({ refreshIntervalSeconds: seconds }),

      setShowContainers: (show: boolean) =>
        set({ showContainers: show }),

      setVisibleMetrics: (metrics: ('cpu' | 'memory' | 'disk' | 'network')[]) =>
        set({ visibleMetrics: [...metrics] }),

      toggleSidebar: () =>
        set((state) => ({ sidebarCollapsed: !state.sidebarCollapsed })),

      setCompactMode: (compact: boolean) =>
        set({ compactMode: compact }),

      resetToDefaults: () =>
        set({ ...defaultPreferences }),
    }),
    {
      name: 'preferences-storage',
      storage: createJSONStorage(() => localStorage),
    }
  )
);

// Selector hooks
export const useTimeRange = () => usePreferencesStore((state) => state.defaultTimeRange);
export const useChartTheme = () => usePreferencesStore((state) => state.chartTheme);
export const useSidebarCollapsed = () => usePreferencesStore((state) => state.sidebarCollapsed);
