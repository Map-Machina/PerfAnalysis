import React from 'react';
import { RouterProvider } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { ReactQueryDevtools } from '@tanstack/react-query-devtools';
import { router } from './router';

// Create a client
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 30000, // 30 seconds
      retry: 1,
      refetchOnWindowFocus: false,
    },
  },
});

// App version for debugging
const APP_VERSION = import.meta.env.VITE_APP_VERSION || '0.1.0';
const BUILD_DATE = import.meta.env.VITE_BUILD_DATE || new Date().toISOString();

// Log version on load
if (import.meta.env.DEV) {
  console.log(`[PerfAnalysis] Dashboard v${APP_VERSION} (${BUILD_DATE})`);
}

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <RouterProvider router={router} />
      {import.meta.env.DEV && <ReactQueryDevtools initialIsOpen={false} />}
    </QueryClientProvider>
  );
}

export default App;
