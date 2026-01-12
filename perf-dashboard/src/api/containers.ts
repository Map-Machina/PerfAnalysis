import { apiClient, buildQueryParams, timeRangeToHours } from './client';
import { Container, ContainerMetrics, TimeRange } from '@/types';

export const containersApi = {
  /**
   * List containers for a collector
   */
  list: async (collectorId: number): Promise<Container[]> => {
    const response = await apiClient.get<Container[]>(
      `/dashboard/api/collectors/${collectorId}/containers/`
    );
    return response.data;
  },

  /**
   * Get container details
   */
  get: async (collectorId: number, containerId: number): Promise<Container> => {
    const response = await apiClient.get<Container>(
      `/dashboard/api/collectors/${collectorId}/containers/${containerId}/`
    );
    return response.data;
  },

  /**
   * Get container CPU metrics
   */
  getCPU: async (
    collectorId: number,
    containerId: number,
    timeRange: TimeRange = '24h'
  ): Promise<ContainerMetrics> => {
    const hours = timeRangeToHours(timeRange);
    const params = buildQueryParams({ hours });
    const response = await apiClient.get<ContainerMetrics>(
      `/dashboard/api/collectors/${collectorId}/containers/${containerId}/cpu/${params}`
    );
    return response.data;
  },

  /**
   * Get container memory metrics
   */
  getMemory: async (
    collectorId: number,
    containerId: number,
    timeRange: TimeRange = '24h'
  ): Promise<ContainerMetrics> => {
    const hours = timeRangeToHours(timeRange);
    const params = buildQueryParams({ hours });
    const response = await apiClient.get<ContainerMetrics>(
      `/dashboard/api/collectors/${collectorId}/containers/${containerId}/memory/${params}`
    );
    return response.data;
  },

  /**
   * Get container network metrics
   */
  getNetwork: async (
    collectorId: number,
    containerId: number,
    timeRange: TimeRange = '24h'
  ): Promise<ContainerMetrics> => {
    const hours = timeRangeToHours(timeRange);
    const params = buildQueryParams({ hours });
    const response = await apiClient.get<ContainerMetrics>(
      `/dashboard/api/collectors/${collectorId}/containers/${containerId}/network/${params}`
    );
    return response.data;
  },

  /**
   * Get aggregate container metrics for a collector
   */
  getAggregate: async (
    collectorId: number,
    timeRange: TimeRange = '24h'
  ): Promise<{
    total_containers: number;
    running_containers: number;
    total_cpu_percent: number[];
    total_memory_mb: number[];
    timestamps: string[];
  }> => {
    const hours = timeRangeToHours(timeRange);
    const params = buildQueryParams({ hours });
    const response = await apiClient.get(
      `/dashboard/api/collectors/${collectorId}/containers/aggregate/${params}`
    );
    return response.data;
  },
};
