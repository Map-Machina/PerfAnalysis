import React, { Fragment } from 'react';
import { Listbox, Transition } from '@headlessui/react';
import { CheckIcon, ChevronUpDownIcon, ServerIcon } from '@heroicons/react/20/solid';
import { Collector } from '@/types';

interface CollectorSelectorProps {
  collectors: Collector[];
  selected: Collector | null;
  onSelect: (collector: Collector) => void;
  loading?: boolean;
  className?: string;
}

export const CollectorSelector: React.FC<CollectorSelectorProps> = ({
  collectors,
  selected,
  onSelect,
  loading = false,
  className = '',
}) => {
  const getStatusColor = (status: Collector['status']) => {
    switch (status) {
      case 'online':
        return 'bg-green-400';
      case 'offline':
        return 'bg-red-400';
      default:
        return 'bg-gray-400';
    }
  };

  if (loading) {
    return (
      <div className={`animate-pulse ${className}`}>
        <div className="h-10 bg-gray-200 rounded-lg w-64"></div>
      </div>
    );
  }

  return (
    <Listbox value={selected} onChange={onSelect}>
      {({ open }) => (
        <div className={`relative ${className}`}>
          <Listbox.Button className="relative w-full cursor-pointer rounded-lg bg-white py-2 pl-3 pr-10 text-left border border-dashboard-border shadow-sm focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-primary-500 sm:text-sm">
            <span className="flex items-center">
              {selected ? (
                <>
                  <span
                    className={`inline-block h-2 w-2 flex-shrink-0 rounded-full ${getStatusColor(
                      selected.status
                    )}`}
                  />
                  <span className="ml-3 block truncate font-medium">{selected.name}</span>
                  <span className="ml-2 text-gray-500 truncate">{selected.hostname}</span>
                </>
              ) : (
                <>
                  <ServerIcon className="h-5 w-5 text-gray-400" />
                  <span className="ml-3 block text-gray-500">Select a collector...</span>
                </>
              )}
            </span>
            <span className="pointer-events-none absolute inset-y-0 right-0 flex items-center pr-2">
              <ChevronUpDownIcon className="h-5 w-5 text-gray-400" aria-hidden="true" />
            </span>
          </Listbox.Button>

          <Transition
            show={open}
            as={Fragment}
            leave="transition ease-in duration-100"
            leaveFrom="opacity-100"
            leaveTo="opacity-0"
          >
            <Listbox.Options className="absolute z-10 mt-1 max-h-60 w-full overflow-auto rounded-lg bg-white py-1 text-base shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none sm:text-sm">
              {collectors.length === 0 ? (
                <div className="relative cursor-default select-none py-2 px-4 text-gray-700">
                  No collectors found
                </div>
              ) : (
                collectors.map((collector) => (
                  <Listbox.Option
                    key={collector.id}
                    className={({ active }) =>
                      `relative cursor-pointer select-none py-2 pl-3 pr-9 ${
                        active ? 'bg-primary-50 text-primary-900' : 'text-gray-900'
                      }`
                    }
                    value={collector}
                  >
                    {({ selected: isSelected, active }) => (
                      <>
                        <div className="flex items-center">
                          <span
                            className={`inline-block h-2 w-2 flex-shrink-0 rounded-full ${getStatusColor(
                              collector.status
                            )}`}
                          />
                          <span
                            className={`ml-3 block truncate ${
                              isSelected ? 'font-semibold' : 'font-normal'
                            }`}
                          >
                            {collector.name}
                          </span>
                          <span
                            className={`ml-2 truncate ${
                              active ? 'text-primary-700' : 'text-gray-500'
                            }`}
                          >
                            {collector.hostname}
                          </span>
                        </div>

                        {isSelected && (
                          <span
                            className={`absolute inset-y-0 right-0 flex items-center pr-4 ${
                              active ? 'text-primary-600' : 'text-primary-600'
                            }`}
                          >
                            <CheckIcon className="h-5 w-5" aria-hidden="true" />
                          </span>
                        )}
                      </>
                    )}
                  </Listbox.Option>
                ))
              )}
            </Listbox.Options>
          </Transition>
        </div>
      )}
    </Listbox>
  );
};

export default CollectorSelector;
