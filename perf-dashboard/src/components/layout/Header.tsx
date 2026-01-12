import React, { Fragment } from 'react';
import { Menu, Transition } from '@headlessui/react';
import { UserCircleIcon, ArrowRightOnRectangleIcon } from '@heroicons/react/24/outline';
import { useAuthStore } from '@store/authStore';
import { useLogout } from '@hooks/useAuth';

export const Header: React.FC = () => {
  const user = useAuthStore((state) => state.user);
  const { mutate: logout } = useLogout();

  return (
    <header className="sticky top-0 z-40 flex h-16 items-center justify-between border-b border-dashboard-border bg-white px-4 lg:px-6">
      {/* Left side - could add breadcrumbs or page title */}
      <div className="flex items-center gap-4">
        {/* Mobile menu button could go here */}
      </div>

      {/* Right side - user menu */}
      <div className="flex items-center gap-4">
        <Menu as="div" className="relative">
          <Menu.Button className="flex items-center gap-2 rounded-lg px-3 py-2 text-sm font-medium text-dashboard-text hover:bg-gray-50 transition-colors">
            <UserCircleIcon className="h-6 w-6 text-dashboard-muted" />
            <span className="hidden sm:block">{user?.username || 'User'}</span>
          </Menu.Button>

          <Transition
            as={Fragment}
            enter="transition ease-out duration-100"
            enterFrom="transform opacity-0 scale-95"
            enterTo="transform opacity-100 scale-100"
            leave="transition ease-in duration-75"
            leaveFrom="transform opacity-100 scale-100"
            leaveTo="transform opacity-0 scale-95"
          >
            <Menu.Items className="absolute right-0 mt-2 w-48 origin-top-right rounded-lg bg-white shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none">
              <div className="p-1">
                <div className="px-3 py-2 border-b border-dashboard-border">
                  <p className="text-sm font-medium text-dashboard-text">
                    {user?.first_name || user?.username}
                  </p>
                  <p className="text-xs text-dashboard-muted truncate">{user?.email}</p>
                </div>

                <Menu.Item>
                  {({ active }) => (
                    <button
                      onClick={() => logout()}
                      className={`${
                        active ? 'bg-gray-50' : ''
                      } flex w-full items-center gap-2 rounded-md px-3 py-2 text-sm text-red-600`}
                    >
                      <ArrowRightOnRectangleIcon className="h-4 w-4" />
                      Sign out
                    </button>
                  )}
                </Menu.Item>
              </div>
            </Menu.Items>
          </Transition>
        </Menu>
      </div>
    </header>
  );
};

export default Header;
