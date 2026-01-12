import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { collectorsApi } from '@api/collectors';
import { Collector, TimeRange } from '@/types';

// Query keys
export const collectorKeys = {
  all: ['collectors'] as const,
  lists: () => [...collectorKeys.all, 'list'] as const,
  list: () => [...collectorKeys.lists()] as const,
  details: () => [...collectorKeys.all, 'detail'] as const,
  detail: (id: number) => [...collectorKeys.details(), id] as const,
  metrics: (id: number) => [...collectorKeys.detail(id), 'metrics'] as const,
  cpu: (id: number, timeRange: TimeRange) =>
    [...collectorKeys.metrics(id), 'cpu', timeRange] as const,
  memory: (id: number, timeRange: TimeRange) =>
    [...collectorKeys.metrics(id), 'memory', timeRange] as const,
  disk: (id: number, timeRange: TimeRange) =>
    [...collectorKeys.metrics(id), 'disk', timeRange] as const,
  network: (id: number, timeRange: TimeRange) =>
    [...collectorKeys.metrics(id), 'network', timeRange] as const,
  stats: (id: number, timeRange: TimeRange) =>
    [...collectorKeys.metrics(id), 'stats', timeRange] as const,
  percentiles: (id: number, timeRange: TimeRange) =>
    [...collectorKeys.metrics(id), 'percentiles', timeRange] as const,
  compare: (ids: number[], timeRange: TimeRange) =>
    [...collectorKeys.all, 'compare', ids, timeRange] as const,
};

/**
 * Hook to fetch all collectors
 */
export function useCollectors() {
  return useQuery({
    queryKey: collectorKeys.list(),
    queryFn: collectorsApi.list,
    staleTime: 30000, // 30 seconds
    refetchInterval: 60000, // Auto-refresh every minute
  });
}

/**
 * Hook to fetch a single collector
 */
export function useCollector(id: number | null) {
  return useQuery({
    queryKey: collectorKeys.detail(id!),
    queryFn: () => collectorsApi.get(id!),
    enabled: id !== null,
    staleTime: 30000,
  });
}

/**
 * Hook to fetch CPU metrics
 */
export function useCollectorCPU(id: number | null, timeRange: TimeRange = '24h') {
  return useQuery({
    queryKey: collectorKeys.cpu(id!, timeRange),
    queryFn: () => collectorsApi.getCPU(id!, timeRange),
    enabled: id !== null,
    staleTime: 60000, // 1 minute
    refetchInterval: 60000,
  });
}

/**
 * Hook to fetch Memory metrics
 */
export function useCollectorMemory(id: number | null, timeRange: TimeRange = '24h') {
  return useQuery({
    queryKey: collectorKeys.memory(id!, timeRange),
    queryFn: () => collectorsApi.getMemory(id!, timeRange),
    enabled: id !== null,
    staleTime: 60000,
    refetchInterval: 60000,
  });
}

/**
 * Hook to fetch Disk metrics
 */
export function useCollectorDisk(id: number | null, timeRange: TimeRange = '24h') {
  return useQuery({
    queryKey: collectorKeys.disk(id!, timeRange),
    queryFn: () => collectorsApi.getDisk(id!, timeRange),
    enabled: id !== null,
    staleTime: 60000,
    refetchInterval: 60000,
  });
}

/**
 * Hook to fetch Network metrics
 */
export function useCollectorNetwork(id: number | null, timeRange: TimeRange = '24h') {
  return useQuery({
    queryKey: collectorKeys.network(id!, timeRange),
    queryFn: () => collectorsApi.getNetwork(id!, timeRange),
    enabled: id !== null,
    staleTime: 60000,
    refetchInterval: 60000,
  });
}

/**
 * Hook to fetch collector statistics
 */
export function useCollectorStats(id: number | null, timeRange: TimeRange = '24h') {
  return useQuery({
    queryKey: collectorKeys.stats(id!, timeRange),
    queryFn: () => collectorsApi.getStats(id!, timeRange),
    enabled: id !== null,
    staleTime: 60000,
  });
}

/**
 * Hook to fetch collector percentiles
 */
export function useCollectorPercentiles(id: number | null, timeRange: TimeRange = '24h') {
  return useQuery({
    queryKey: collectorKeys.percentiles(id!, timeRange),
    queryFn: () => collectorsApi.getPercentiles(id!, timeRange),
    enabled: id !== null,
    staleTime: 60000,
  });
}

/**
 * Hook to compare multiple collectors
 */
export function useCollectorComparison(ids: number[], timeRange: TimeRange = '24h') {
  return useQuery({
    queryKey: collectorKeys.compare(ids, timeRange),
    queryFn: () => collectorsApi.compare(ids, timeRange),
    enabled: ids.length >= 2,
    staleTime: 60000,
  });
}

/**
 * Hook to create a collector
 */
export function useCreateCollector() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: collectorsApi.create,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: collectorKeys.lists() });
    },
  });
}

/**
 * Hook to update a collector
 */
export function useUpdateCollector() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, data }: { id: number; data: Partial<Collector> }) =>
      collectorsApi.update(id, data),
    onSuccess: (_, { id }) => {
      queryClient.invalidateQueries({ queryKey: collectorKeys.detail(id) });
      queryClient.invalidateQueries({ queryKey: collectorKeys.lists() });
    },
  });
}

/**
 * Hook to delete a collector
 */
export function useDeleteCollector() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: collectorsApi.delete,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: collectorKeys.lists() });
    },
  });
}
