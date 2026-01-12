import React, { useMemo } from 'react';
import Plot from 'react-plotly.js';
import { usePreferencesStore } from '@store/preferencesStore';

interface DataSeries {
  x: (Date | string)[];
  y: number[];
  name: string;
  color?: string;
  fill?: 'none' | 'tozeroy' | 'tonexty';
}

interface TimeSeriesChartProps {
  data: DataSeries[];
  title: string;
  yAxisLabel: string;
  yAxisRange?: [number, number];
  height?: number;
  showLegend?: boolean;
  stacked?: boolean;
  className?: string;
}

export const TimeSeriesChart: React.FC<TimeSeriesChartProps> = ({
  data,
  title,
  yAxisLabel,
  yAxisRange,
  height = 300,
  showLegend = true,
  stacked = false,
  className = '',
}) => {
  const chartTheme = usePreferencesStore((state) => state.chartTheme);
  const isDark = chartTheme === 'dark';

  const plotData = useMemo(() => {
    return data.map((series, index) => ({
      x: series.x,
      y: series.y,
      name: series.name,
      type: 'scatter' as const,
      mode: 'lines' as const,
      fill: stacked ? (index === 0 ? 'tozeroy' : 'tonexty') : series.fill || 'none',
      line: {
        color: series.color,
        width: 1.5,
      },
      hovertemplate: `%{x}<br>${series.name}: %{y:.2f}<extra></extra>`,
    }));
  }, [data, stacked]);

  const layout = useMemo(
    () => ({
      title: {
        text: title,
        font: {
          size: 14,
          color: isDark ? '#e2e8f0' : '#1e293b',
        },
      },
      xaxis: {
        type: 'date' as const,
        tickformat: '%H:%M',
        tickfont: {
          size: 10,
          color: isDark ? '#94a3b8' : '#64748b',
        },
        gridcolor: isDark ? '#334155' : '#e2e8f0',
        linecolor: isDark ? '#334155' : '#e2e8f0',
      },
      yaxis: {
        title: {
          text: yAxisLabel,
          font: {
            size: 11,
            color: isDark ? '#94a3b8' : '#64748b',
          },
        },
        range: yAxisRange,
        tickfont: {
          size: 10,
          color: isDark ? '#94a3b8' : '#64748b',
        },
        gridcolor: isDark ? '#334155' : '#e2e8f0',
        linecolor: isDark ? '#334155' : '#e2e8f0',
        zeroline: false,
      },
      legend: {
        orientation: 'h' as const,
        yanchor: 'bottom' as const,
        y: 1.02,
        xanchor: 'right' as const,
        x: 1,
        font: {
          size: 10,
          color: isDark ? '#e2e8f0' : '#1e293b',
        },
      },
      showlegend: showLegend,
      margin: {
        l: 50,
        r: 20,
        t: 40,
        b: 40,
      },
      paper_bgcolor: 'transparent',
      plot_bgcolor: 'transparent',
      hovermode: 'x unified' as const,
      hoverlabel: {
        bgcolor: isDark ? '#1e293b' : '#ffffff',
        bordercolor: isDark ? '#334155' : '#e2e8f0',
        font: {
          color: isDark ? '#e2e8f0' : '#1e293b',
          size: 11,
        },
      },
    }),
    [title, yAxisLabel, yAxisRange, showLegend, isDark]
  );

  const config = useMemo(
    () => ({
      responsive: true,
      displayModeBar: true,
      modeBarButtonsToRemove: [
        'select2d',
        'lasso2d',
        'autoScale2d',
        'toggleSpikelines',
      ] as const,
      displaylogo: false,
    }),
    []
  );

  return (
    <div className={`w-full ${className}`}>
      <Plot
        data={plotData}
        layout={layout}
        config={config}
        style={{ width: '100%', height }}
        useResizeHandler
      />
    </div>
  );
};

export default TimeSeriesChart;
