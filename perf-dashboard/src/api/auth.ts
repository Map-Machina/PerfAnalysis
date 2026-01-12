import { apiClient } from './client';
import { AuthTokens, LoginCredentials, User } from '@/types';

export const authApi = {
  /**
   * Login with username and password
   */
  login: async (credentials: LoginCredentials): Promise<{ tokens: AuthTokens; user: User }> => {
    const response = await apiClient.post<{ access: string; refresh: string; user: User }>(
      '/api/v1/auth/token/',
      credentials
    );
    return {
      tokens: {
        access: response.data.access,
        refresh: response.data.refresh,
      },
      user: response.data.user,
    };
  },

  /**
   * Refresh access token
   */
  refreshToken: async (refreshToken: string): Promise<{ access: string }> => {
    const response = await apiClient.post<{ access: string }>(
      '/api/v1/auth/token/refresh/',
      { refresh: refreshToken }
    );
    return response.data;
  },

  /**
   * Get current user info
   */
  getCurrentUser: async (): Promise<User> => {
    const response = await apiClient.get<User>('/api/v1/auth/user/');
    return response.data;
  },

  /**
   * Logout - revoke token
   */
  logout: async (): Promise<void> => {
    await apiClient.post('/api/v1/auth/logout/');
  },

  /**
   * Change password
   */
  changePassword: async (oldPassword: string, newPassword: string): Promise<void> => {
    await apiClient.post('/api/v1/auth/password/change/', {
      old_password: oldPassword,
      new_password: newPassword,
    });
  },

  /**
   * Request password reset
   */
  requestPasswordReset: async (email: string): Promise<void> => {
    await apiClient.post('/api/v1/auth/password/reset/', { email });
  },
};
