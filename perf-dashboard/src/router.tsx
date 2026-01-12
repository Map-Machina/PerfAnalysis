import React from 'react';
import { createBrowserRouter, Navigate } from 'react-router-dom';
import { useAuthStore } from '@store/authStore';
import AppLayout from '@components/layout/AppLayout';
import Login from '@pages/Login';
import Dashboard from '@pages/Dashboard';

// Protected route wrapper
const ProtectedRoute: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const isAuthenticated = useAuthStore((state) => state.isAuthenticated);
  const isLoading = useAuthStore((state) => state.isLoading);

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-dashboard-bg">
        <div className="animate-spin h-8 w-8 border-4 border-primary-600 border-t-transparent rounded-full" />
      </div>
    );
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }

  return <>{children}</>;
};

// Placeholder pages for routes not yet implemented
const PlaceholderPage: React.FC<{ title: string }> = ({ title }) => (
  <div className="flex flex-col items-center justify-center h-96">
    <h1 className="text-2xl font-bold text-dashboard-text mb-2">{title}</h1>
    <p className="text-dashboard-muted">This page is under construction</p>
  </div>
);

const Collectors: React.FC = () => <PlaceholderPage title="Collectors" />;
const CollectorDetail: React.FC = () => <PlaceholderPage title="Collector Detail" />;
const Containers: React.FC = () => <PlaceholderPage title="Containers" />;
const Compare: React.FC = () => <PlaceholderPage title="Compare Collectors" />;
const Reports: React.FC = () => <PlaceholderPage title="Reports" />;
const Settings: React.FC = () => <PlaceholderPage title="Settings" />;
const NotFound: React.FC = () => <PlaceholderPage title="404 - Page Not Found" />;

export const router = createBrowserRouter([
  {
    path: '/login',
    element: <Login />,
  },
  {
    path: '/',
    element: (
      <ProtectedRoute>
        <AppLayout />
      </ProtectedRoute>
    ),
    children: [
      {
        index: true,
        element: <Dashboard />,
      },
      {
        path: 'collectors',
        element: <Collectors />,
      },
      {
        path: 'collectors/:id',
        element: <CollectorDetail />,
      },
      {
        path: 'containers',
        element: <Containers />,
      },
      {
        path: 'compare',
        element: <Compare />,
      },
      {
        path: 'reports',
        element: <Reports />,
      },
      {
        path: 'settings',
        element: <Settings />,
      },
    ],
  },
  {
    path: '*',
    element: <NotFound />,
  },
]);

export default router;
