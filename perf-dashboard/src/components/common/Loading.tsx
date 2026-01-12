import React from 'react';

interface LoadingProps {
  size?: 'sm' | 'md' | 'lg';
  text?: string;
  fullScreen?: boolean;
  className?: string;
}

export const Loading: React.FC<LoadingProps> = ({
  size = 'md',
  text,
  fullScreen = false,
  className = '',
}) => {
  const sizeClasses = {
    sm: 'h-4 w-4',
    md: 'h-8 w-8',
    lg: 'h-12 w-12',
  };

  const spinner = (
    <div className={`flex flex-col items-center justify-center gap-3 ${className}`}>
      <svg
        className={`animate-spin text-primary-600 ${sizeClasses[size]}`}
        xmlns="http://www.w3.org/2000/svg"
        fill="none"
        viewBox="0 0 24 24"
      >
        <circle
          className="opacity-25"
          cx="12"
          cy="12"
          r="10"
          stroke="currentColor"
          strokeWidth="4"
        />
        <path
          className="opacity-75"
          fill="currentColor"
          d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
        />
      </svg>
      {text && <p className="text-sm text-dashboard-muted">{text}</p>}
    </div>
  );

  if (fullScreen) {
    return (
      <div className="fixed inset-0 flex items-center justify-center bg-dashboard-bg/80 backdrop-blur-sm z-50">
        {spinner}
      </div>
    );
  }

  return spinner;
};

export const LoadingSkeleton: React.FC<{ className?: string }> = ({ className = '' }) => {
  return <div className={`animate-pulse bg-gray-200 rounded ${className}`} />;
};

export const ChartSkeleton: React.FC<{ height?: number }> = ({ height = 300 }) => {
  return (
    <div className="card p-4">
      <LoadingSkeleton className="h-4 w-32 mb-4" />
      <LoadingSkeleton className={`w-full`} style={{ height }} />
    </div>
  );
};

export const StatsSkeleton: React.FC = () => {
  return (
    <div className="card p-4">
      <LoadingSkeleton className="h-4 w-24 mb-3" />
      <LoadingSkeleton className="h-8 w-20 mb-4" />
      <div className="grid grid-cols-4 gap-2">
        {[...Array(4)].map((_, i) => (
          <div key={i}>
            <LoadingSkeleton className="h-3 w-8 mb-1" />
            <LoadingSkeleton className="h-4 w-12" />
          </div>
        ))}
      </div>
    </div>
  );
};

export default Loading;
