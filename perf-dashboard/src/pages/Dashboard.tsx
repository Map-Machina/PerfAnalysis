import React, { useState, useEffect } from 'react';
import { useSearchParams } from 'react-router-dom';
import {
  useCollectors,
  useCollectorCPU,
  useCollectorMemory,
  useCollectorDisk,
  useCollectorNetwork,
} from '@hooks/useCollectors';
import { usePreferencesStore } from '@store/preferencesStore';
import { Collector, TimeRange } from '@/types';
import CollectorSelector from '@components/dashboard/CollectorSelector';
import TimeRangeSelector from '@components/dashboard/TimeRangeSelector';
import TimeSeriesChart from '@components/charts/TimeSeriesChart';
import { ChartSkeleton } from '@components/common/Loading';

const CHART_COLORS = {
  cpu: {
    user: '#3b82f6',
    system: '#ef4444',
    iowait: '#f59e0b',
    idle: '#10b981',
  },
  memory: {
    used: '#8b5cf6',
    cached: '#06b6d4',
    buffers: '#84cc16',
  },
  disk: {
    read: '#3b82f6',
    write: '#ef4444',
  },
  network: {
    rx: '#3b82f6',
    tx: '#10b981',
  },
};

export const Dashboard: React.FC = () => {
  const [searchParams, setSearchParams] = useSearchParams();

  // Get preferences
  const defaultTimeRange = usePreferencesStore((state) => state.defaultTimeRange);
  const defaultCollectorId = usePreferencesStore((state) => state.defaultCollectorId);
  const setDefaultCollector = usePreferencesStore((state) => state.setDefaultCollector);

  // Local state
  const [selectedCollector, setSelectedCollector] = useState<Collector | null>(null);
  const [timeRange, setTimeRange] = useState<TimeRange>(
    (searchParams.get('range') as TimeRange) || defaultTimeRange
  );

  // Fetch collectors
  const { data: collectors, isLoading: collectorsLoading } = useCollectors();

  // Set initial collector from URL or preferences
  useEffect(() => {
    if (collectors && collectors.length > 0 && !selectedCollector) {
      const urlCollectorId = searchParams.get('collector');
      const targetId = urlCollectorId
        ? parseInt(urlCollectorId, 10)
        : defaultCollectorId;

      const collector = collectors.find((c) => c.id === targetId) || collectors[0];
      setSelectedCollector(collector);
    }
  }, [collectors, defaultCollectorId, searchParams, selectedCollector]);

  // Update URL when selection changes
  useEffect(() => {
    if (selectedCollector) {
      const params = new URLSearchParams(searchParams);
      params.set('collector', String(selectedCollector.id));
      params.set('range', timeRange);
      setSearchParams(params, { replace: true });
    }
  }, [selectedCollector, timeRange, setSearchParams, searchParams]);

  // Fetch metrics
  const collectorId = selectedCollector?.id ?? null;
  const { data: cpuData, isLoading: cpuLoading } = useCollectorCPU(collectorId, timeRange);
  const { data: memoryData, isLoading: memoryLoading } = useCollectorMemory(collectorId, timeRange);
  const { data: diskData, isLoading: diskLoading } = useCollectorDisk(collectorId, timeRange);
  const { data: networkData, isLoading: networkLoading } = useCollectorNetwork(collectorId, timeRange);

  const handleCollectorSelect = (collector: Collector) => {
    setSelectedCollector(collector);
    setDefaultCollector(collector.id);
  };

  const handleTimeRangeChange = (range: TimeRange) => {
    setTimeRange(range);
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-dashboard-text">Performance Dashboard</h1>
          <p className="text-sm text-dashboard-muted mt-1">
            Real-time performance metrics for your infrastructure
          </p>
        </div>

        <div className="flex flex-col sm:flex-row items-start sm:items-center gap-3">
          <CollectorSelector
            collectors={collectors || []}
            selected={selectedCollector}
            onSelect={handleCollectorSelect}
            loading={collectorsLoading}
            className="w-full sm:w-72"
          />
          <TimeRangeSelector value={timeRange} onChange={handleTimeRangeChange} />
        </div>
      </div>

      {/* Charts Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* CPU Chart */}
        {cpuLoading || !cpuData ? (
          <ChartSkeleton />
        ) : (
          <div className="card p-4">
            <TimeSeriesChart
              data={[
                {
                  x: cpuData.timestamps,
                  y: cpuData.user,
                  name: 'User',
                  color: CHART_COLORS.cpu.user,
                },
                {
                  x: cpuData.timestamps,
                  y: cpuData.system,
                  name: 'System',
                  color: CHART_COLORS.cpu.system,
                },
                {
                  x: cpuData.timestamps,
                  y: cpuData.iowait,
                  name: 'I/O Wait',
                  color: CHART_COLORS.cpu.iowait,
                },
              ]}
              title="CPU Utilization"
              yAxisLabel="%"
              yAxisRange={[0, 100]}
              stacked
            />
          </div>
        )}

        {/* Memory Chart */}
        {memoryLoading || !memoryData ? (
          <ChartSkeleton />
        ) : (
          <div className="card p-4">
            <TimeSeriesChart
              data={[
                {
                  x: memoryData.timestamps,
                  y: memoryData.percent_used,
                  name: 'Used',
                  color: CHART_COLORS.memory.used,
                },
              ]}
              title="Memory Utilization"
              yAxisLabel="%"
              yAxisRange={[0, 100]}
            />
          </div>
        )}

        {/* Disk I/O Chart */}
        {diskLoading || !diskData ? (
          <ChartSkeleton />
        ) : (
          <div className="card p-4">
            <TimeSeriesChart
              data={
                diskData.devices.length > 0
                  ? [
                      {
                        x: diskData.timestamps,
                        y: diskData.devices[0].read_ops,
                        name: `${diskData.devices[0].name} Read IOPS`,
                        color: CHART_COLORS.disk.read,
                      },
                      {
                        x: diskData.timestamps,
                        y: diskData.devices[0].write_ops,
                        name: `${diskData.devices[0].name} Write IOPS`,
                        color: CHART_COLORS.disk.write,
                      },
                    ]
                  : []
              }
              title="Disk I/O"
              yAxisLabel="IOPS"
            />
          </div>
        )}

        {/* Network Chart */}
        {networkLoading || !networkData ? (
          <ChartSkeleton />
        ) : (
          <div className="card p-4">
            <TimeSeriesChart
              data={
                networkData.interfaces.length > 0
                  ? [
                      {
                        x: networkData.timestamps,
                        y: networkData.interfaces[0].rx_bytes.map((b) => b / 1024 / 1024),
                        name: `${networkData.interfaces[0].name} RX`,
                        color: CHART_COLORS.network.rx,
                      },
                      {
                        x: networkData.timestamps,
                        y: networkData.interfaces[0].tx_bytes.map((b) => b / 1024 / 1024),
                        name: `${networkData.interfaces[0].name} TX`,
                        color: CHART_COLORS.network.tx,
                      },
                    ]
                  : []
              }
              title="Network Throughput"
              yAxisLabel="MB/s"
            />
          </div>
        )}
      </div>

      {/* Collector Info */}
      {selectedCollector && (
        <div className="card p-4">
          <h3 className="text-sm font-medium text-dashboard-muted mb-3">Collector Details</h3>
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-4 text-sm">
            <div>
              <p className="text-dashboard-muted">Hostname</p>
              <p className="font-medium">{selectedCollector.hostname}</p>
            </div>
            <div>
              <p className="text-dashboard-muted">IP Address</p>
              <p className="font-medium font-mono">{selectedCollector.ip_address}</p>
            </div>
            <div>
              <p className="text-dashboard-muted">CPU Model</p>
              <p className="font-medium truncate" title={selectedCollector.cpu_model}>
                {selectedCollector.cpu_model || 'Unknown'}
              </p>
            </div>
            <div>
              <p className="text-dashboard-muted">Memory</p>
              <p className="font-medium">
                {selectedCollector.memory_total_gb
                  ? `${selectedCollector.memory_total_gb} GB`
                  : 'Unknown'}
              </p>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Dashboard;
