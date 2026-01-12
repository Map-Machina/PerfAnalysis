import React from 'react';
import { ArrowTrendingUpIcon, ArrowTrendingDownIcon, MinusIcon } from '@heroicons/react/20/solid';
import { MetricStats } from '@/types';

interface StatsPanelProps {
  stats: MetricStats;
  label: string;
  unit: string;
  trend?: 'up' | 'down' | 'stable';
  trendValue?: number;
  colorScale?: {
    good: [number, number];
    warning: [number, number];
    critical: [number, number];
  };
  className?: string;
}

export const StatsPanel: React.FC<StatsPanelProps> = ({
  stats,
  label,
  unit,
  trend,
  trendValue,
  colorScale,
  className = '',
}) => {
  const getValueColor = (value: number) => {
    if (!colorScale) return 'text-dashboard-text';

    if (value >= colorScale.critical[0] && value <= colorScale.critical[1]) {
      return 'text-red-600';
    }
    if (value >= colorScale.warning[0] && value <= colorScale.warning[1]) {
      return 'text-yellow-600';
    }
    if (value >= colorScale.good[0] && value <= colorScale.good[1]) {
      return 'text-green-600';
    }
    return 'text-dashboard-text';
  };

  const getTrendIcon = () => {
    switch (trend) {
      case 'up':
        return <ArrowTrendingUpIcon className="h-4 w-4 text-red-500" />;
      case 'down':
        return <ArrowTrendingDownIcon className="h-4 w-4 text-green-500" />;
      case 'stable':
        return <MinusIcon className="h-4 w-4 text-gray-400" />;
      default:
        return null;
    }
  };

  const formatValue = (value: number) => {
    if (value >= 1000000) {
      return `${(value / 1000000).toFixed(1)}M`;
    }
    if (value >= 1000) {
      return `${(value / 1000).toFixed(1)}K`;
    }
    return value.toFixed(1);
  };

  return (
    <div className={`card p-4 ${className}`}>
      <div className="flex items-center justify-between mb-3">
        <h3 className="text-sm font-medium text-dashboard-muted">{label}</h3>
        {trend && (
          <div className="flex items-center gap-1">
            {getTrendIcon()}
            {trendValue !== undefined && (
              <span className="text-xs text-dashboard-muted">
                {trendValue > 0 ? '+' : ''}
                {trendValue.toFixed(1)}%
              </span>
            )}
          </div>
        )}
      </div>

      <div className="mb-4">
        <span className={`text-3xl font-bold ${getValueColor(stats.current)}`}>
          {formatValue(stats.current)}
        </span>
        <span className="ml-1 text-sm text-dashboard-muted">{unit}</span>
      </div>

      <div className="grid grid-cols-4 gap-2 text-xs">
        <div>
          <p className="text-dashboard-muted">Min</p>
          <p className="font-medium">{formatValue(stats.min)}</p>
        </div>
        <div>
          <p className="text-dashboard-muted">Max</p>
          <p className="font-medium">{formatValue(stats.max)}</p>
        </div>
        <div>
          <p className="text-dashboard-muted">Avg</p>
          <p className="font-medium">{formatValue(stats.avg)}</p>
        </div>
        <div>
          <p className="text-dashboard-muted">StdDev</p>
          <p className="font-medium">{formatValue(stats.stddev)}</p>
        </div>
      </div>
    </div>
  );
};

export default StatsPanel;
