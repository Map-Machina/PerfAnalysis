import { apiClient, buildQueryParams, timeRangeToHours } from './client';
import {
  Collector,
  CPUMetrics,
  MemoryMetrics,
  DiskMetrics,
  NetworkMetrics,
  CollectorStats,
  ComparisonData,
  TimeRange,
} from '@/types';

export const collectorsApi = {
  /**
   * List all collectors
   */
  list: async (): Promise<Collector[]> => {
    const response = await apiClient.get<Collector[]>('/dashboard/api/collectors/');
    return response.data;
  },

  /**
   * Get single collector details
   */
  get: async (id: number): Promise<Collector> => {
    const response = await apiClient.get<Collector>(`/dashboard/api/collectors/${id}/`);
    return response.data;
  },

  /**
   * Get CPU metrics for a collector
   */
  getCPU: async (id: number, timeRange: TimeRange = '24h'): Promise<CPUMetrics> => {
    const hours = timeRangeToHours(timeRange);
    const params = buildQueryParams({ hours });
    const response = await apiClient.get<CPUMetrics>(
      `/dashboard/api/collectors/${id}/cpu/${params}`
    );
    return response.data;
  },

  /**
   * Get Memory metrics for a collector
   */
  getMemory: async (id: number, timeRange: TimeRange = '24h'): Promise<MemoryMetrics> => {
    const hours = timeRangeToHours(timeRange);
    const params = buildQueryParams({ hours });
    const response = await apiClient.get<MemoryMetrics>(
      `/dashboard/api/collectors/${id}/memory/${params}`
    );
    return response.data;
  },

  /**
   * Get Disk metrics for a collector
   */
  getDisk: async (id: number, timeRange: TimeRange = '24h'): Promise<DiskMetrics> => {
    const hours = timeRangeToHours(timeRange);
    const params = buildQueryParams({ hours });
    const response = await apiClient.get<DiskMetrics>(
      `/dashboard/api/collectors/${id}/disk/${params}`
    );
    return response.data;
  },

  /**
   * Get Network metrics for a collector
   */
  getNetwork: async (id: number, timeRange: TimeRange = '24h'): Promise<NetworkMetrics> => {
    const hours = timeRangeToHours(timeRange);
    const params = buildQueryParams({ hours });
    const response = await apiClient.get<NetworkMetrics>(
      `/dashboard/api/collectors/${id}/network/${params}`
    );
    return response.data;
  },

  /**
   * Get statistics for a collector
   */
  getStats: async (id: number, timeRange: TimeRange = '24h'): Promise<CollectorStats> => {
    const hours = timeRangeToHours(timeRange);
    const params = buildQueryParams({ hours });
    const response = await apiClient.get<CollectorStats>(
      `/dashboard/api/collectors/${id}/stats/${params}`
    );
    return response.data;
  },

  /**
   * Get percentiles for a collector
   */
  getPercentiles: async (
    id: number,
    timeRange: TimeRange = '24h'
  ): Promise<Record<string, Record<string, number>>> => {
    const hours = timeRangeToHours(timeRange);
    const params = buildQueryParams({ hours });
    const response = await apiClient.get(
      `/dashboard/api/collectors/${id}/percentiles/${params}`
    );
    return response.data;
  },

  /**
   * Compare multiple collectors
   */
  compare: async (ids: number[], timeRange: TimeRange = '24h'): Promise<ComparisonData> => {
    const hours = timeRangeToHours(timeRange);
    const params = buildQueryParams({ collectors: ids, hours });
    const response = await apiClient.get<ComparisonData>(`/dashboard/api/compare/${params}`);
    return response.data;
  },

  /**
   * Create a new collector
   */
  create: async (data: Partial<Collector>): Promise<Collector> => {
    const response = await apiClient.post<Collector>('/api/v1/collectors/', data);
    return response.data;
  },

  /**
   * Update a collector
   */
  update: async (id: number, data: Partial<Collector>): Promise<Collector> => {
    const response = await apiClient.patch<Collector>(`/api/v1/collectors/${id}/`, data);
    return response.data;
  },

  /**
   * Delete a collector
   */
  delete: async (id: number): Promise<void> => {
    await apiClient.delete(`/api/v1/collectors/${id}/`);
  },
};
