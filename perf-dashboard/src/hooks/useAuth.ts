import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useNavigate } from 'react-router-dom';
import { authApi } from '@api/auth';
import { useAuthStore } from '@store/authStore';
import { LoginCredentials } from '@/types';

/**
 * Hook for login mutation
 */
export function useLogin() {
  const navigate = useNavigate();
  const login = useAuthStore((state) => state.login);

  return useMutation({
    mutationFn: async (credentials: LoginCredentials) => {
      const { tokens, user } = await authApi.login(credentials);
      return { tokens, user };
    },
    onSuccess: ({ tokens, user }) => {
      login(tokens, user);
      navigate('/');
    },
  });
}

/**
 * Hook for logout
 */
export function useLogout() {
  const navigate = useNavigate();
  const logout = useAuthStore((state) => state.logout);
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async () => {
      try {
        await authApi.logout();
      } catch {
        // Ignore logout API errors
      }
    },
    onSettled: () => {
      logout();
      queryClient.clear();
      navigate('/login');
    },
  });
}

/**
 * Hook to fetch current user
 */
export function useCurrentUser() {
  const isAuthenticated = useAuthStore((state) => state.isAuthenticated);
  const setUser = useAuthStore((state) => state.setUser);

  return useQuery({
    queryKey: ['auth', 'user'],
    queryFn: async () => {
      const user = await authApi.getCurrentUser();
      setUser(user);
      return user;
    },
    enabled: isAuthenticated,
    staleTime: 5 * 60 * 1000, // 5 minutes
  });
}

/**
 * Hook for password change
 */
export function useChangePassword() {
  return useMutation({
    mutationFn: ({ oldPassword, newPassword }: { oldPassword: string; newPassword: string }) =>
      authApi.changePassword(oldPassword, newPassword),
  });
}

/**
 * Hook for password reset request
 */
export function useRequestPasswordReset() {
  return useMutation({
    mutationFn: (email: string) => authApi.requestPasswordReset(email),
  });
}

/**
 * Check if user is authenticated (sync)
 */
export function useIsAuthenticated() {
  return useAuthStore((state) => state.isAuthenticated);
}

/**
 * Get auth loading state
 */
export function useAuthLoading() {
  return useAuthStore((state) => state.isLoading);
}
