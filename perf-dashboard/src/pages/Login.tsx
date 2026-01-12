import React, { useState } from 'react';
import { Navigate } from 'react-router-dom';
import { ChartBarIcon, ExclamationCircleIcon } from '@heroicons/react/24/outline';
import { useLogin, useIsAuthenticated } from '@hooks/useAuth';

export const Login: React.FC = () => {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const { mutate: login, isPending, error } = useLogin();
  const isAuthenticated = useIsAuthenticated();

  // Redirect if already logged in
  if (isAuthenticated) {
    return <Navigate to="/" replace />;
  }

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    login({ username, password });
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-dashboard-bg px-4">
      <div className="max-w-md w-full">
        {/* Logo and title */}
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center h-16 w-16 rounded-2xl bg-primary-600 mb-4">
            <ChartBarIcon className="h-10 w-10 text-white" />
          </div>
          <h1 className="text-2xl font-bold text-dashboard-text">PerfAnalysis</h1>
          <p className="text-sm text-dashboard-muted mt-1">
            Sign in to access the performance dashboard
          </p>
        </div>

        {/* Login form */}
        <div className="card p-6">
          <form onSubmit={handleSubmit} className="space-y-4">
            {/* Error message */}
            {error && (
              <div className="flex items-center gap-2 p-3 bg-red-50 border border-red-200 rounded-lg text-sm text-red-700">
                <ExclamationCircleIcon className="h-5 w-5 flex-shrink-0" />
                <span>Invalid username or password. Please try again.</span>
              </div>
            )}

            {/* Username field */}
            <div>
              <label htmlFor="username" className="label">
                Username
              </label>
              <input
                id="username"
                name="username"
                type="text"
                autoComplete="username"
                required
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                className="input"
                placeholder="Enter your username"
                disabled={isPending}
              />
            </div>

            {/* Password field */}
            <div>
              <label htmlFor="password" className="label">
                Password
              </label>
              <input
                id="password"
                name="password"
                type="password"
                autoComplete="current-password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="input"
                placeholder="Enter your password"
                disabled={isPending}
              />
            </div>

            {/* Submit button */}
            <button
              type="submit"
              disabled={isPending}
              className="btn-primary w-full py-2.5"
            >
              {isPending ? (
                <span className="flex items-center justify-center gap-2">
                  <svg
                    className="animate-spin h-4 w-4"
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
                      d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"
                    />
                  </svg>
                  Signing in...
                </span>
              ) : (
                'Sign in'
              )}
            </button>
          </form>
        </div>

        {/* Footer */}
        <p className="text-center text-xs text-dashboard-muted mt-6">
          PerfAnalysis Performance Monitoring Dashboard
        </p>
      </div>
    </div>
  );
};

export default Login;
