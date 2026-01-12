import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';
import { User, AuthTokens } from '@/types';

interface AuthState {
  // State
  accessToken: string | null;
  refreshToken: string | null;
  user: User | null;
  isAuthenticated: boolean;
  isLoading: boolean;

  // Actions
  login: (tokens: AuthTokens, user: User) => void;
  logout: () => void;
  setAccessToken: (token: string) => void;
  setLoading: (loading: boolean) => void;
  setUser: (user: User) => void;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      // Initial state
      accessToken: null,
      refreshToken: null,
      user: null,
      isAuthenticated: false,
      isLoading: true, // Start loading until we check persisted state

      // Actions
      login: (tokens: AuthTokens, user: User) =>
        set({
          accessToken: tokens.access,
          refreshToken: tokens.refresh,
          user,
          isAuthenticated: true,
          isLoading: false,
        }),

      logout: () =>
        set({
          accessToken: null,
          refreshToken: null,
          user: null,
          isAuthenticated: false,
          isLoading: false,
        }),

      setAccessToken: (token: string) =>
        set({
          accessToken: token,
        }),

      setLoading: (loading: boolean) =>
        set({
          isLoading: loading,
        }),

      setUser: (user: User) =>
        set({
          user,
        }),
    }),
    {
      name: 'auth-storage',
      storage: createJSONStorage(() => localStorage),
      // Only persist these fields
      partialize: (state) => ({
        refreshToken: state.refreshToken,
        user: state.user,
        isAuthenticated: state.isAuthenticated,
      }),
      // Rehydrate callback
      onRehydrateStorage: () => (state) => {
        if (state) {
          state.setLoading(false);
        }
      },
    }
  )
);

// Selector hooks for common patterns
export const useIsAuthenticated = () => useAuthStore((state) => state.isAuthenticated);
export const useCurrentUser = () => useAuthStore((state) => state.user);
export const useAuthLoading = () => useAuthStore((state) => state.isLoading);
