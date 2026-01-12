import React from 'react';
import { TimeRange } from '@/types';

interface TimeRangeSelectorProps {
  value: TimeRange;
  onChange: (range: TimeRange) => void;
  className?: string;
}

const TIME_RANGES: { value: TimeRange; label: string }[] = [
  { value: '1h', label: '1H' },
  { value: '6h', label: '6H' },
  { value: '24h', label: '24H' },
  { value: '7d', label: '7D' },
  { value: '30d', label: '30D' },
  { value: 'all', label: 'All' },
];

export const TimeRangeSelector: React.FC<TimeRangeSelectorProps> = ({
  value,
  onChange,
  className = '',
}) => {
  return (
    <div
      className={`inline-flex rounded-lg bg-gray-100 p-1 ${className}`}
      role="group"
      aria-label="Time range selection"
    >
      {TIME_RANGES.map(({ value: rangeValue, label }) => (
        <button
          key={rangeValue}
          type="button"
          onClick={() => onChange(rangeValue)}
          className={`
            px-3 py-1.5 text-xs font-medium rounded-md transition-all
            ${
              value === rangeValue
                ? 'bg-white text-primary-700 shadow-sm'
                : 'text-gray-600 hover:text-gray-900 hover:bg-gray-50'
            }
          `}
          aria-pressed={value === rangeValue}
        >
          {label}
        </button>
      ))}
    </div>
  );
};

export default TimeRangeSelector;
