import React from 'react';
import { NavLink } from 'react-router-dom';
import {
  ChartBarIcon,
  ServerStackIcon,
  CubeIcon,
  ArrowsRightLeftIcon,
  DocumentChartBarIcon,
  Cog6ToothIcon,
  ChevronLeftIcon,
  ChevronRightIcon,
} from '@heroicons/react/24/outline';
import { usePreferencesStore } from '@store/preferencesStore';

interface NavItem {
  name: string;
  href: string;
  icon: React.ComponentType<React.SVGProps<SVGSVGElement>>;
}

const navigation: NavItem[] = [
  { name: 'Dashboard', href: '/', icon: ChartBarIcon },
  { name: 'Collectors', href: '/collectors', icon: ServerStackIcon },
  { name: 'Containers', href: '/containers', icon: CubeIcon },
  { name: 'Compare', href: '/compare', icon: ArrowsRightLeftIcon },
  { name: 'Reports', href: '/reports', icon: DocumentChartBarIcon },
];

const secondaryNavigation: NavItem[] = [
  { name: 'Settings', href: '/settings', icon: Cog6ToothIcon },
];

export const Sidebar: React.FC = () => {
  const sidebarCollapsed = usePreferencesStore((state) => state.sidebarCollapsed);
  const toggleSidebar = usePreferencesStore((state) => state.toggleSidebar);

  return (
    <>
      {/* Mobile sidebar backdrop */}
      <div className="lg:hidden fixed inset-0 z-40 bg-black/50 hidden" />

      {/* Sidebar */}
      <aside
        className={`fixed inset-y-0 left-0 z-50 flex flex-col bg-white border-r border-dashboard-border transition-all duration-300 ${
          sidebarCollapsed ? 'w-16' : 'w-64'
        } hidden lg:flex`}
      >
        {/* Logo */}
        <div className="flex h-16 items-center justify-between px-4 border-b border-dashboard-border">
          {!sidebarCollapsed && (
            <div className="flex items-center gap-2">
              <div className="h-8 w-8 rounded-lg bg-primary-600 flex items-center justify-center">
                <ChartBarIcon className="h-5 w-5 text-white" />
              </div>
              <span className="font-semibold text-dashboard-text">PerfAnalysis</span>
            </div>
          )}
          {sidebarCollapsed && (
            <div className="h-8 w-8 rounded-lg bg-primary-600 flex items-center justify-center mx-auto">
              <ChartBarIcon className="h-5 w-5 text-white" />
            </div>
          )}
        </div>

        {/* Navigation */}
        <nav className="flex-1 overflow-y-auto py-4">
          <ul className="space-y-1 px-2">
            {navigation.map((item) => (
              <li key={item.name}>
                <NavLink
                  to={item.href}
                  className={({ isActive }) =>
                    `flex items-center gap-3 px-3 py-2 rounded-lg text-sm font-medium transition-colors ${
                      isActive
                        ? 'bg-primary-50 text-primary-700'
                        : 'text-dashboard-muted hover:bg-gray-50 hover:text-dashboard-text'
                    } ${sidebarCollapsed ? 'justify-center' : ''}`
                  }
                  title={sidebarCollapsed ? item.name : undefined}
                >
                  <item.icon className="h-5 w-5 flex-shrink-0" />
                  {!sidebarCollapsed && <span>{item.name}</span>}
                </NavLink>
              </li>
            ))}
          </ul>

          <div className="mt-6 pt-6 border-t border-dashboard-border mx-2">
            <ul className="space-y-1 px-2">
              {secondaryNavigation.map((item) => (
                <li key={item.name}>
                  <NavLink
                    to={item.href}
                    className={({ isActive }) =>
                      `flex items-center gap-3 px-3 py-2 rounded-lg text-sm font-medium transition-colors ${
                        isActive
                          ? 'bg-primary-50 text-primary-700'
                          : 'text-dashboard-muted hover:bg-gray-50 hover:text-dashboard-text'
                      } ${sidebarCollapsed ? 'justify-center' : ''}`
                    }
                    title={sidebarCollapsed ? item.name : undefined}
                  >
                    <item.icon className="h-5 w-5 flex-shrink-0" />
                    {!sidebarCollapsed && <span>{item.name}</span>}
                  </NavLink>
                </li>
              ))}
            </ul>
          </div>
        </nav>

        {/* Collapse toggle */}
        <div className="p-2 border-t border-dashboard-border">
          <button
            onClick={toggleSidebar}
            className="w-full flex items-center justify-center p-2 rounded-lg text-dashboard-muted hover:bg-gray-50 hover:text-dashboard-text transition-colors"
            title={sidebarCollapsed ? 'Expand sidebar' : 'Collapse sidebar'}
          >
            {sidebarCollapsed ? (
              <ChevronRightIcon className="h-5 w-5" />
            ) : (
              <ChevronLeftIcon className="h-5 w-5" />
            )}
          </button>
        </div>
      </aside>
    </>
  );
};

export default Sidebar;
