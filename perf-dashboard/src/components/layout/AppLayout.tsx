import React from 'react';
import { Outlet } from 'react-router-dom';
import Sidebar from './Sidebar';
import Header from './Header';
import { usePreferencesStore } from '@store/preferencesStore';

export const AppLayout: React.FC = () => {
  const sidebarCollapsed = usePreferencesStore((state) => state.sidebarCollapsed);

  return (
    <div className="min-h-screen bg-dashboard-bg">
      <Sidebar />

      <div
        className={`transition-all duration-300 ${
          sidebarCollapsed ? 'lg:pl-16' : 'lg:pl-64'
        }`}
      >
        <Header />

        <main className="p-4 lg:p-6">
          <Outlet />
        </main>
      </div>
    </div>
  );
};

export default AppLayout;
