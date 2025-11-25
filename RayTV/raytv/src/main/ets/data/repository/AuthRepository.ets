// AuthRepository - 认证授权仓库类
// 负责处理用户认证、授权和会话管理相关的业务逻辑

import Logger from '../../common/util/Logger';
import StorageUtil from '../../common/util/StorageUtil';
import NetworkUtil from '../../common/util/NetworkUtil';
import EventBusUtil from '../../common/util/EventBusUtil';
import CacheService from '../../service/cache/CacheService';
import { LocalStorageType } from '../model/LocalModel';
import { CacheType } from '../model/CacheModel';
import { UserInfo, UserCredentials, UserRegisterInfo } from '../../service/user/UserService';

/**
 * 认证状态枚举
 */
export enum AuthStatus {
  UNAUTHENTICATED = 'unauthenticated',
  AUTHENTICATING = 'authenticating',
  AUTHENTICATED = 'authenticated',
  TOKEN_EXPIRED = 'token_expired',
  REFRESHING = 'refreshing',
  ERROR = 'error'
}

/**
 * 认证令牌接口
 */
export interface AuthToken {
  accessToken: string;
  refreshToken: string;
  expiresIn: number; // 过期时间（秒）
  tokenType: string;
  scope: string;
  issuedAt: number; // 签发时间戳
}

/**
 * 认证响应接口
 */
export interface AuthResponse {
  token: AuthToken;
  user: UserInfo;
  expiresAt: number;
  isFirstLogin?: boolean;
  sessionId?: string;
}

/**
 * 刷新令牌响应接口
 */
export interface RefreshTokenResponse {
  token: AuthToken;
  expiresAt: number;
}

/**
 * 认证错误接口
 */
export interface AuthError {
  code: string;
  message: string;
  details?: string | number | boolean | null;
  timestamp: number;
}

/**
 * 认证配置接口
 */
export interface AuthConfig {
  enableBiometricAuth: boolean;
  enableAutoLogin: boolean;
  autoLoginTimeout: number; // 自动登录超时时间（毫秒）
  tokenRefreshThreshold: number; // 令牌刷新阈值（秒）
  sessionTimeout: number; // 会话超时时间（秒）
  rememberMeDuration: number; // 记住我持续时间（秒）
  enableTokenRotation: boolean; // 是否启用令牌轮换
  secureTokenStorage: boolean; // 是否使用安全存储
}

/**
 * 认证事件类型
 */
export const AuthEventType = {
  LOGIN_START: 'auth:loginStart',
  LOGIN_SUCCESS: 'auth:loginSuccess',
  LOGIN_FAILURE: 'auth:loginFailure',
  LOGOUT_START: 'auth:logoutStart',
  LOGOUT_SUCCESS: 'auth:logoutSuccess',
  LOGOUT_FAILURE: 'auth:logoutFailure',
  TOKEN_REFRESH_START: 'auth:tokenRefreshStart',
  TOKEN_REFRESH_SUCCESS: 'auth:tokenRefreshSuccess',
  TOKEN_REFRESH_FAILURE: 'auth:tokenRefreshFailure',
  SESSION_EXPIRED: 'auth:sessionExpired',
  PERMISSION_DENIED: 'auth:permissionDenied',
  AUTH_STATUS_CHANGED: 'auth:statusChanged',
  AUTH_CONFIG_CHANGED: 'auth:configChanged',
  PASSWORD_RESET_REQUEST: 'auth:passwordResetRequest',
  PASSWORD_RESET_SUCCESS: 'auth:passwordResetSuccess',
  REGISTRATION_SUCCESS: 'auth:registrationSuccess',
  BIOMETRIC_AUTH_SUCCESS: 'auth:biometricAuthSuccess',
  BIOMETRIC_AUTH_FAILURE: 'auth:biometricAuthFailure'
} as const;

/**
 * 认证事件数据
 */
export interface AuthEvent {
  type: string;
  timestamp: number;
  data?: string | number | boolean | null;
  error?: AuthError;
}

/**
 * 权限接口
 */
export interface Permission {
  id: string;
  name: string;
  description: string;
  category: string;
  level: number; // 权限级别：1-最低，10-最高
  isEnabled: boolean;
}

/**
 * 角色接口
 */
export interface Role {
  id: string;
  name: string;
  description: string;
  permissions: string[]; // 权限ID列表
  isDefault: boolean;
  level: number; // 角色级别
}

/**
 * 用户权限接口
 */
export interface UserPermissions {
  userId: string;
  roles: Role[];
  permissions: Permission[];
  grantedPermissions: string[]; // 用户直接授予的权限ID列表
  deniedPermissions: string[]; // 用户被拒绝的权限ID列表
  updatedAt: number;
}

/**
 * 权限检查请求
 */
export interface PermissionCheckRequest {
  permissionId: string;
  userId?: string;
  context?: string | number | boolean | null;
}

/**
 * 认证仓库类
 */
export class AuthRepository {
  private static instance: AuthRepository;

  private logger = Logger.getInstance();
  private storageUtil = StorageUtil.getInstance();
  private networkUtil = NetworkUtil.getInstance();
  private eventBus = EventBusUtil.getInstance();
  private cacheService = CacheService.getInstance();
  
  // API端点配置
  private apiEndpoints = {
    baseUrl: 'https://api.raytv.example.com',
    login: '/auth/login',
    logout: '/auth/logout',
    refreshToken: '/auth/refresh',
    register: '/auth/register',
    forgotPassword: '/auth/forgot-password',
    resetPassword: '/auth/reset-password',
    verifyEmail: '/auth/verify-email',
    resendVerification: '/auth/resend-verification',
    userPermissions: '/auth/permissions',
    checkPermission: '/auth/permissions/check',
    roles: '/auth/roles',
    biometricAuth: '/auth/biometric'
  };
  
  // 存储键配置
  private storageKeys = {
    authToken: 'auth:token',
    currentUser: 'auth:currentUser',
    authConfig: 'auth:config',
    lastLoginTimestamp: 'auth:lastLoginTimestamp',
    rememberMeCredentials: 'auth:rememberMeCredentials',
    userPermissions: 'auth:userPermissions',
    authStatus: 'auth:status',
    sessionId: 'auth:sessionId',
    biometricData: 'auth:biometricData'
  };
  
  // 默认配置
  private defaultConfig: AuthConfig = {
    enableBiometricAuth: false,
    enableAutoLogin: false,
    autoLoginTimeout: 1800000, // 30分钟
    tokenRefreshThreshold: 300, // 5分钟
    sessionTimeout: 3600, // 1小时
    rememberMeDuration: 604800, // 7天
    enableTokenRotation: true,
    secureTokenStorage: true
  };
  
  // 缓存的配置
  private cachedConfig: AuthConfig | null = null;
  
  // 当前认证状态
  private currentStatus: AuthStatus = AuthStatus.UNAUTHENTICATED;
  
  // 缓存的认证令牌
  private cachedToken: AuthToken | null = null;
  
  // 缓存的用户信息
  private cachedUser: UserInfo | null = null;
  
  // 缓存的用户权限
  private cachedUserPermissions: UserPermissions | null = null;
  
  // 令牌刷新中标志
  private isRefreshingToken: boolean = false;
  
  // 登录尝试次数
  private loginAttempts: number = 0;
  
  // 上次登录时间
  private lastLoginAttempt: number = 0;

  /**
   * 私有构造函数
   */
  private constructor() {
    this.logger.info('AuthRepository initialized');
    this.setupEventListeners();
    this.initialize();
  }

  /**
   * 获取AuthRepository单例实例
   */
  public static getInstance(): AuthRepository {
    if (!AuthRepository.instance) {
      AuthRepository.instance = new AuthRepository();
    }
    return AuthRepository.instance;
  }

  /**
   * 初始化认证仓库
   */
  public async initialize(): Promise<void> {
    try {
      // 加载配置
      await this.loadConfig();
      
      // 恢复认证状态
      await this.restoreAuthState();
      
      this.logger.info('AuthRepository initialization completed');
    } catch (error) {
      this.logger.error('Failed to initialize AuthRepository', error as Error);
      // 出错时重置认证状态
      await this.resetAuthState();
    }
  }

  /**
   * 设置事件监听器
   */
  private setupEventListeners(): void {
    // 监听网络状态变化
    this.eventBus.on('network:statusChanged', async (status: { isOnline: boolean }) => {
      if (status.isOnline && this.cachedToken && this.isTokenExpiredSoon()) {
        // 网络恢复且令牌即将过期时，尝试刷新令牌
        this.refreshTokenIfNeeded().catch(err => {
          this.logger.warn('Failed to refresh token after network recovery', err);
        });
      }
    });
    
    // 监听应用前台/后台切换
    this.eventBus.on('app:stateChanged', async (state: { isActive: boolean }) => {
      if (state.isActive && this.cachedToken) {
        // 应用切换到前台时，检查令牌是否过期
        if (this.isTokenExpired()) {
          this.handleTokenExpiry().catch(err => {
            this.logger.warn('Failed to handle token expiry when app becomes active', err);
          });
        } else if (this.isTokenExpiredSoon()) {
          // 令牌即将过期，尝试刷新
          this.refreshTokenIfNeeded().catch(err => {
            this.logger.warn('Failed to refresh token when app becomes active', err);
          });
        }
      }
    });
  }

  /**
   * 加载配置
   */
  private async loadConfig(): Promise<void> {
    try {
      const config = await this.storageUtil.getObject<AuthConfig>(
        this.storageKeys.authConfig,
        LocalStorageType.DEFAULT
      );
      
      this.cachedConfig = config ? {
        ...this.defaultConfig,
        ...config
      } : { ...this.defaultConfig };
      
      // 验证配置
      this.validateConfig(this.cachedConfig);
      
      this.logger.debug('Auth configuration loaded');
    } catch (error) {
      this.logger.error('Failed to load auth config', error as Error);
      this.cachedConfig = { ...this.defaultConfig };
    }
  }

  /**
   * 设置配置
   */
  public async setConfig(config: Partial<AuthConfig>): Promise<AuthConfig> {
    try {
      // 获取当前配置
      const currentConfig = await this.getConfig();
      
      // 合并新配置
      const updatedConfig: AuthConfig = {
        ...currentConfig,
        ...config
      };
      
      // 验证配置
      this.validateConfig(updatedConfig);
      
      // 保存配置
      this.cachedConfig = updatedConfig;
      await this.storageUtil.setObject(
        this.storageKeys.authConfig,
        updatedConfig,
        LocalStorageType.DEFAULT
      );
      
      // 发布配置变更事件
      this.eventBus.emit(AuthEventType.AUTH_CONFIG_CHANGED, {
        type: AuthEventType.AUTH_CONFIG_CHANGED,
        timestamp: Date.now(),
        data: updatedConfig
      } as AuthEvent);
      
      this.logger.info('Auth configuration updated');
      
      return updatedConfig;
    } catch (error) {
      this.logger.error('Failed to set auth config', error as Error);
      throw error;
    }
  }

  /**
   * 获取配置
   */
  public async getConfig(): Promise<AuthConfig> {
    try {
      // 如果缓存为空，加载配置
      if (!this.cachedConfig) {
        await this.loadConfig();
      }
      
      return { ...this.cachedConfig! };
    } catch (error) {
      this.logger.error('Failed to get auth config', error as Error);
      return { ...this.defaultConfig };
    }
  }

  /**
   * 验证配置
   */
  private validateConfig(config: AuthConfig): void {
    const errors: string[] = [];
    
    if (config.autoLoginTimeout < 0) {
      errors.push('autoLoginTimeout must be non-negative');
    }
    
    if (config.tokenRefreshThreshold < 0 || config.tokenRefreshThreshold > 3600) {
      errors.push('tokenRefreshThreshold must be between 0 and 3600');
    }
    
    if (config.sessionTimeout < 0) {
      errors.push('sessionTimeout must be non-negative');
    }
    
    if (config.rememberMeDuration < 0) {
      errors.push('rememberMeDuration must be non-negative');
    }
    
    if (errors.length > 0) {
      throw new Error(errors.join(', '));
    }
  }

  /**
   * 恢复认证状态
   */
  private async restoreAuthState(): Promise<void> {
    try {
      // 加载令牌
      const savedToken = await this.storageUtil.getObject<AuthToken>(
        this.storageKeys.authToken,
        this.cachedConfig?.secureTokenStorage ? LocalStorageType.SECURE : LocalStorageType.DEFAULT
      );
      
      if (savedToken) {
        this.cachedToken = savedToken;
        
        // 检查令牌是否已过期
        if (this.isTokenExpired()) {
          this.logger.warn('Restored token is expired');
          this.currentStatus = AuthStatus.TOKEN_EXPIRED;
          
          // 尝试刷新令牌
          this.handleTokenExpiry().catch(err => {
            this.logger.warn('Failed to refresh expired token during restore', err);
          });
        } else {
          // 加载用户信息
          const savedUser = await this.storageUtil.getObject<UserInfo>(
            this.storageKeys.currentUser,
            this.cachedConfig?.secureTokenStorage ? LocalStorageType.SECURE : LocalStorageType.DEFAULT
          );
          
          if (savedUser) {
            this.cachedUser = savedUser;
            this.currentStatus = AuthStatus.AUTHENTICATED;
            
            this.logger.info('Auth state restored successfully');
            
            // 发布认证状态变更事件
            this.emitAuthStatusChange(AuthStatus.AUTHENTICATED);
          } else {
            // 只有令牌但没有用户信息，清除令牌
            this.logger.warn('Token exists but user info is missing, clearing auth state');
            await this.resetAuthState();
          }
        }
      }
      
      // 加载认证状态
      const savedStatus = await this.storageUtil.getString(
        this.storageKeys.authStatus,
        LocalStorageType.DEFAULT
      );
      
      if (savedStatus && this.getAuthStatusValues().includes(savedStatus)) {
        this.currentStatus = savedStatus as AuthStatus;
      }
      
    } catch (error) {
      this.logger.error('Failed to restore auth state', error as Error);
      await this.resetAuthState();
    }
  }

  /**
   * 获取AuthStatus枚举的所有有效值（ArkTS兼容方法）
   */
  private getAuthStatusValues(): string[] {
    return [
      AuthStatus.UNAUTHENTICATED,
      AuthStatus.AUTHENTICATING,
      AuthStatus.AUTHENTICATED,
      AuthStatus.TOKEN_EXPIRED,
      AuthStatus.REFRESHING,
      AuthStatus.ERROR
    ];
  }

  /**
   * 保存认证状态
   */
  private async saveAuthState(token: AuthToken, user: UserInfo): Promise<void> {
    try {
      // 保存令牌
      await this.storageUtil.setObject(
        this.storageKeys.authToken,
        token,
        this.cachedConfig?.secureTokenStorage ? LocalStorageType.SECURE : LocalStorageType.DEFAULT
      );
      
      // 保存用户信息
      await this.storageUtil.setObject(
        this.storageKeys.currentUser,
        user,
        this.cachedConfig?.secureTokenStorage ? LocalStorageType.SECURE : LocalStorageType.DEFAULT
      );
      
      // 保存认证状态
      await this.storageUtil.setString(
        this.storageKeys.authStatus,
        AuthStatus.AUTHENTICATED,
        LocalStorageType.DEFAULT
      );
      
      // 更新缓存
      this.cachedToken = token;
      this.cachedUser = user;
      this.currentStatus = AuthStatus.AUTHENTICATED;
      
      // 记录登录时间
      await this.storageUtil.setNumber(
        this.storageKeys.lastLoginTimestamp,
        Date.now(),
        LocalStorageType.DEFAULT
      );
      
      this.logger.info('Auth state saved successfully');
    } catch (error) {
      this.logger.error('Failed to save auth state', error as Error);
      throw error;
    }
  }

  /**
   * 重置认证状态
   */
  private async resetAuthState(): Promise<void> {
    try {
      // 清除令牌
      await this.storageUtil.remove(
        this.storageKeys.authToken,
        this.cachedConfig?.secureTokenStorage ? LocalStorageType.SECURE : LocalStorageType.DEFAULT
      );
      
      // 清除用户信息
      await this.storageUtil.remove(
        this.storageKeys.currentUser,
        this.cachedConfig?.secureTokenStorage ? LocalStorageType.SECURE : LocalStorageType.DEFAULT
      );
      
      // 清除用户权限
      await this.storageUtil.remove(
        this.storageKeys.userPermissions,
        LocalStorageType.DEFAULT
      );
      
      // 清除认证状态
      await this.storageUtil.remove(
        this.storageKeys.authStatus,
        LocalStorageType.DEFAULT
      );
      
      // 清除会话ID
      await this.storageUtil.remove(
        this.storageKeys.sessionId,
        LocalStorageType.DEFAULT
      );
      
      // 重置缓存
      this.cachedToken = null;
      this.cachedUser = null;
      this.cachedUserPermissions = null;
      this.currentStatus = AuthStatus.UNAUTHENTICATED;
      
      // 清除登录尝试计数
      this.loginAttempts = 0;
      this.lastLoginAttempt = 0;
      
      this.logger.info('Auth state reset successfully');
    } catch (error) {
      this.logger.error('Failed to reset auth state', error as Error);
    }
  }

  /**
   * 用户登录
   */
  public async login(credentials: UserCredentials, rememberMe: boolean = false): Promise<AuthResponse> {
    try {
      // 检查登录频率限制
      this.checkLoginRateLimit();
      
      // 记录登录尝试
      this.loginAttempts++;
      this.lastLoginAttempt = Date.now();
      
      // 发布登录开始事件
      this.eventBus.emit(AuthEventType.LOGIN_START, {
        type: AuthEventType.LOGIN_START,
        timestamp: Date.now(),
        data: { username: credentials.username, rememberMe }
      } as AuthEvent);
      
      // 更新状态为认证中
      this.updateAuthStatus(AuthStatus.AUTHENTICATING);
      
      // 调用登录API
      const response = await this.networkUtil.post<AuthResponse>(
        `${this.apiEndpoints.baseUrl}${this.apiEndpoints.login}`,
        { ...credentials, rememberMe }
      );
      
      const authResponse = response.data;
      
      // 保存认证状态
      await this.saveAuthState(authResponse.token, authResponse.user);
      
      // 保存会话ID
      if (authResponse.sessionId) {
        await this.storageUtil.setString(
          this.storageKeys.sessionId,
          authResponse.sessionId,
          LocalStorageType.DEFAULT
        );
      }
      
      // 重置登录尝试计数
      this.loginAttempts = 0;
      
      // 更新状态为已认证
      this.updateAuthStatus(AuthStatus.AUTHENTICATED);
      
      // 发布登录成功事件
      this.eventBus.emit(AuthEventType.LOGIN_SUCCESS, {
        type: AuthEventType.LOGIN_SUCCESS,
        timestamp: Date.now(),
        data: authResponse
      } as AuthEvent);
      
      // 更新认证状态变更事件
      this.emitAuthStatusChange(AuthStatus.AUTHENTICATED);
      
      this.logger.info(`User ${authResponse.user.username} logged in successfully`);
      
      return authResponse;
    } catch (error) {
      this.logger.error('Login failed', error as Error);
      
      // 更新状态为未认证
      this.updateAuthStatus(AuthStatus.UNAUTHENTICATED);
      
      // 构建认证错误
      const authError: AuthError = {
        code: error instanceof Error ? error.name : 'UNKNOWN_ERROR',
        message: error instanceof Error ? error.message : 'Login failed',
        timestamp: Date.now()
      };
      
      // 发布登录失败事件
      this.eventBus.emit(AuthEventType.LOGIN_FAILURE, {
        type: AuthEventType.LOGIN_FAILURE,
        timestamp: Date.now(),
        error: authError,
        data: { username: credentials.username, loginAttempts: this.loginAttempts }
      } as AuthEvent);
      
      throw authError;
    }
  }

  /**
   * 检查登录频率限制
   */
  private checkLoginRateLimit(): void {
    // 如果登录尝试次数过多，应用临时锁定
    const MAX_ATTEMPTS = 5;
    const LOCK_DURATION = 300000; // 5分钟
    
    if (this.loginAttempts >= MAX_ATTEMPTS) {
      const timeSinceLastAttempt = Date.now() - this.lastLoginAttempt;
      
      if (timeSinceLastAttempt < LOCK_DURATION) {
        const remainingTime = Math.ceil((LOCK_DURATION - timeSinceLastAttempt) / 1000);
        throw new Error(`Too many login attempts. Please try again in ${remainingTime} seconds.`);
      } else {
        // 锁定时间已过，重置尝试计数
        this.loginAttempts = 0;
      }
    }
  }

  /**
   * 用户登出
   */
  public async logout(): Promise<void> {
    try {
      // 发布登出开始事件
      this.eventBus.emit(AuthEventType.LOGOUT_START, {
        type: AuthEventType.LOGOUT_START,
        timestamp: Date.now()
      } as AuthEvent);
      
      // 如果有令牌，调用登出API
      if (this.cachedToken) {
        try {
          await this.networkUtil.post(
            `${this.apiEndpoints.baseUrl}${this.apiEndpoints.logout}`,
            { token: this.cachedToken.accessToken }
          );
        } catch (error) {
          // 登出API调用失败不影响本地登出
          this.logger.warn('Logout API call failed, proceeding with local logout', error);
        }
      }
      
      // 重置认证状态
      await this.resetAuthState();
      
      // 更新状态为未认证
      this.updateAuthStatus(AuthStatus.UNAUTHENTICATED);
      
      // 发布登出成功事件
      this.eventBus.emit(AuthEventType.LOGOUT_SUCCESS, {
        type: AuthEventType.LOGOUT_SUCCESS,
        timestamp: Date.now()
      } as AuthEvent);
      
      // 更新认证状态变更事件
      this.emitAuthStatusChange(AuthStatus.UNAUTHENTICATED);
      
      this.logger.info('User logged out successfully');
    } catch (error) {
      this.logger.error('Logout failed', error as Error);
      
      // 发布登出失败事件
      this.eventBus.emit(AuthEventType.LOGOUT_FAILURE, {
        type: AuthEventType.LOGOUT_FAILURE,
        timestamp: Date.now(),
        error: {
          code: error instanceof Error ? error.name : 'UNKNOWN_ERROR',
          message: error instanceof Error ? error.message : 'Logout failed',
          timestamp: Date.now()
        }
      } as AuthEvent);
      
      throw error;
    }
  }

  /**
   * 获取当前认证状态
   */
  public getAuthStatus(): AuthStatus {
    return this.currentStatus;
  }

  /**
   * 获取当前用户信息
   */
  public getCurrentUser(): UserInfo | null {
    return this.cachedUser;
  }

  /**
   * 获取当前令牌
   */
  public getCurrentToken(): AuthToken | null {
    return this.cachedToken;
  }

  /**
   * 检查是否已认证
   */
  public isAuthenticated(): boolean {
    return this.currentStatus === AuthStatus.AUTHENTICATED && 
           this.cachedToken !== null && 
           this.cachedUser !== null;
  }

  /**
   * 检查令牌是否过期
   */
  public isTokenExpired(): boolean {
    if (!this.cachedToken) {
      return true;
    }
    
    const now = Date.now();
    const expiryTime = this.cachedToken.issuedAt + (this.cachedToken.expiresIn * 1000);
    return now >= expiryTime;
  }

  /**
   * 检查令牌是否即将过期
   */
  public isTokenExpiredSoon(): boolean {
    if (!this.cachedToken) {
      return true;
    }
    
    const now = Date.now();
    const expiryTime = this.cachedToken.issuedAt + (this.cachedToken.expiresIn * 1000);
    const threshold = this.cachedConfig?.tokenRefreshThreshold || 300;
    
    return (expiryTime - now) <= (threshold * 1000);
  }

  /**
   * 刷新令牌
   */
  public async refreshToken(): Promise<RefreshTokenResponse> {
    if (this.isRefreshingToken) {
      throw new Error('Token refresh already in progress');
    }
    
    if (!this.cachedToken?.refreshToken) {
      throw new Error('No refresh token available');
    }
    
    this.isRefreshingToken = true;
    
    try {
      // 发布令牌刷新开始事件
      this.eventBus.emit(AuthEventType.TOKEN_REFRESH_START, {
        type: AuthEventType.TOKEN_REFRESH_START,
        timestamp: Date.now()
      } as AuthEvent);
      
      // 更新状态为刷新中
      this.updateAuthStatus(AuthStatus.REFRESHING);
      
      // 调用刷新令牌API
      const response = await this.networkUtil.post<RefreshTokenResponse>(
        `${this.apiEndpoints.baseUrl}${this.apiEndpoints.refreshToken}`,
        { refreshToken: this.cachedToken.refreshToken }
      );
      
      const refreshResponse = response.data;
      
      // 更新令牌
      this.cachedToken = refreshResponse.token;
      
      // 保存新的令牌
      await this.storageUtil.setObject(
        this.storageKeys.authToken,
        refreshResponse.token,
        this.cachedConfig?.secureTokenStorage ? LocalStorageType.SECURE : LocalStorageType.DEFAULT
      );
      
      // 更新状态为已认证
      this.updateAuthStatus(AuthStatus.AUTHENTICATED);
      
      // 发布令牌刷新成功事件
      this.eventBus.emit(AuthEventType.TOKEN_REFRESH_SUCCESS, {
        type: AuthEventType.TOKEN_REFRESH_SUCCESS,
        timestamp: Date.now(),
        data: refreshResponse
      } as AuthEvent);
      
      this.logger.info('Token refreshed successfully');
      
      return refreshResponse;
    } catch (error) {
      this.logger.error('Token refresh failed', error as Error);
      
      // 更新状态为令牌过期
      this.updateAuthStatus(AuthStatus.TOKEN_EXPIRED);
      
      // 发布令牌刷新失败事件
      this.eventBus.emit(AuthEventType.TOKEN_REFRESH_FAILURE, {
        type: AuthEventType.TOKEN_REFRESH_FAILURE,
        timestamp: Date.now(),
        error: {
          code: error instanceof Error ? error.name : 'UNKNOWN_ERROR',
          message: error instanceof Error ? error.message : 'Token refresh failed',
          timestamp: Date.now()
        }
      } as AuthEvent);
      
      throw error;
    } finally {
      this.isRefreshingToken = false;
    }
  }

  /**
   * 如果需要，刷新令牌
   */
  public async refreshTokenIfNeeded(): Promise<boolean> {
    if (this.isTokenExpiredSoon() && !this.isTokenExpired()) {
      try {
        await this.refreshToken();
        return true;
      } catch (error) {
        this.logger.warn('Token refresh not needed or failed', error);
        return false;
      }
    }
    return false;
  }

  /**
   * 处理令牌过期
   */
  private async handleTokenExpiry(): Promise<void> {
    try {
      // 尝试刷新令牌
      await this.refreshToken();
    } catch (error) {
      // 刷新失败，发布会话过期事件
      this.eventBus.emit(AuthEventType.SESSION_EXPIRED, {
        type: AuthEventType.SESSION_EXPIRED,
        timestamp: Date.now(),
        error: {
          code: 'SESSION_EXPIRED',
          message: 'Session has expired, please login again',
          timestamp: Date.now()
        }
      } as AuthEvent);
      
      // 重置认证状态
      await this.resetAuthState();
      
      this.logger.warn('Session expired, user needs to login again');
    }
  }

  /**
   * 更新认证状态
   */
  private updateAuthStatus(status: AuthStatus): void {
    if (this.currentStatus !== status) {
      this.currentStatus = status;
      
      // 保存状态到存储
      this.storageUtil.setString(
        this.storageKeys.authStatus,
        status,
        LocalStorageType.DEFAULT
      ).catch(err => {
        this.logger.warn('Failed to save auth status', err);
      });
      
      this.emitAuthStatusChange(status);
    }
  }

  /**
   * 发布认证状态变更事件
   */
  private emitAuthStatusChange(status: AuthStatus): void {
    this.eventBus.emit(AuthEventType.AUTH_STATUS_CHANGED, {
      type: AuthEventType.AUTH_STATUS_CHANGED,
      timestamp: Date.now(),
      data: { status }
    } as AuthEvent);
  }

  /**
   * 用户注册
   */
  public async register(userInfo: UserRegisterInfo): Promise<AuthResponse> {
    try {
      // 调用注册API
      const response = await this.networkUtil.post<AuthResponse>(
        `${this.apiEndpoints.baseUrl}${this.apiEndpoints.register}`,
        userInfo
      );
      
      const authResponse = response.data;
      
      // 保存认证状态
      await this.saveAuthState(authResponse.token, authResponse.user);
      
      // 发布注册成功事件
      this.eventBus.emit(AuthEventType.REGISTRATION_SUCCESS, {
        type: AuthEventType.REGISTRATION_SUCCESS,
        timestamp: Date.now(),
        data: authResponse
      } as AuthEvent);
      
      this.logger.info(`User ${authResponse.user.username} registered successfully`);
      
      return authResponse;
    } catch (error) {
      this.logger.error('Registration failed', error as Error);
      throw error;
    }
  }

  /**
   * 忘记密码
   */
  public async forgotPassword(email: string): Promise<void> {
    try {
      // 调用忘记密码API
      await this.networkUtil.post(
        `${this.apiEndpoints.baseUrl}${this.apiEndpoints.forgotPassword}`,
        { email }
      );
      
      // 发布忘记密码请求事件
      this.eventBus.emit(AuthEventType.PASSWORD_RESET_REQUEST, {
        type: AuthEventType.PASSWORD_RESET_REQUEST,
        timestamp: Date.now(),
        data: { email }
      } as AuthEvent);
      
      this.logger.info(`Password reset request sent for ${email}`);
    } catch (error) {
      this.logger.error('Forgot password request failed', error as Error);
      throw error;
    }
  }

  /**
   * 重置密码
   */
  public async resetPassword(token: string, newPassword: string): Promise<void> {
    try {
      // 调用重置密码API
      await this.networkUtil.post(
        `${this.apiEndpoints.baseUrl}${this.apiEndpoints.resetPassword}`,
        { token, newPassword }
      );
      
      // 发布密码重置成功事件
      this.eventBus.emit(AuthEventType.PASSWORD_RESET_SUCCESS, {
        type: AuthEventType.PASSWORD_RESET_SUCCESS,
        timestamp: Date.now(),
        data: { token }
      } as AuthEvent);
      
      this.logger.info('Password reset successfully');
    } catch (error) {
      this.logger.error('Password reset failed', error as Error);
      throw error;
    }
  }

  /**
   * 验证邮箱
   */
  public async verifyEmail(token: string): Promise<void> {
    try {
      // 调用验证邮箱API
      await this.networkUtil.post(
        `${this.apiEndpoints.baseUrl}${this.apiEndpoints.verifyEmail}`,
        { token }
      );
      
      this.logger.info('Email verified successfully');
    } catch (error) {
      this.logger.error('Email verification failed', error as Error);
      throw error;
    }
  }

  /**
   * 重新发送验证邮件
   */
  public async resendVerification(email: string): Promise<void> {
    try {
      // 调用重新发送验证邮件API
      await this.networkUtil.post(
        `${this.apiEndpoints.baseUrl}${this.apiEndpoints.resendVerification}`,
        { email }
      );
      
      this.logger.info(`Verification email resent to ${email}`);
    } catch (error) {
      this.logger.error('Failed to resend verification email', error as Error);
      throw error;
    }
  }

  /**
   * 检查权限
   */
  public async checkPermission(request: PermissionCheckRequest): Promise<boolean> {
    try {
      // 调用权限检查API
      const response = await this.networkUtil.post<{ hasPermission: boolean }>(
        `${this.apiEndpoints.baseUrl}${this.apiEndpoints.checkPermission}`,
        request
      );
      
      return response.data.hasPermission;
    } catch (error) {
      this.logger.error('Permission check failed', error as Error);
      return false;
    }
  }

  /**
   * 获取用户权限
   */
  public async getUserPermissions(userId: string): Promise<UserPermissions | null> {
    try {
      // 如果缓存中有权限信息，直接返回
      if (this.cachedUserPermissions && this.cachedUserPermissions.userId === userId) {
        return this.cachedUserPermissions;
      }
      
      // 调用获取用户权限API
      const response = await this.networkUtil.get<UserPermissions>(
        `${this.apiEndpoints.baseUrl}${this.apiEndpoints.userPermissions}/${userId}`
      );
      
      this.cachedUserPermissions = response.data;
      
      // 保存到存储
      await this.storageUtil.setObject(
        this.storageKeys.userPermissions,
        this.cachedUserPermissions,
        LocalStorageType.DEFAULT
      );
      
      return this.cachedUserPermissions;
    } catch (error) {
      this.logger.error('Failed to get user permissions', error as Error);
      return null;
    }
  }

  /**
   * 加载用户权限
   */
  private async loadUserPermissions(userId: string): Promise<void> {
    try {
      // 从存储加载权限信息
      const savedPermissions = await this.storageUtil.getObject<UserPermissions>(
        this.storageKeys.userPermissions,
        LocalStorageType.DEFAULT
      );
      
      if (savedPermissions && savedPermissions.userId === userId) {
        this.cachedUserPermissions = savedPermissions;
      } else {
        // 从API获取权限信息
        await this.getUserPermissions(userId);
      }
    } catch (error) {
      this.logger.warn('Failed to load user permissions', error as Error);
    }
  }

  /**
   * 获取所有角色
   */
  public async getRoles(): Promise<Role[]> {
    try {
      // 调用获取角色API
      const response = await this.networkUtil.get<Role[]>(
        `${this.apiEndpoints.baseUrl}${this.apiEndpoints.roles}`
      );
      
      return response.data;
    } catch (error) {
      this.logger.error('Failed to get roles', error as Error);
      return [];
    }
  }

  /**
   * 生物认证
   */
  public async authenticateWithBiometric(): Promise<AuthResponse> {
    try {
      // 检查是否启用生物认证
      const config = await this.getConfig();
      if (!config.enableBiometricAuth) {
        throw new Error('Biometric authentication is not enabled');
      }
      
      // 在实际应用中，这里应该调用设备的生物认证API
      // 由于是示例实现，返回错误
      throw new Error('Biometric authentication not implemented');
    } catch (error) {
      this.logger.error('Biometric authentication failed', error as Error);
      
      // 发布生物认证失败事件
      this.eventBus.emit(AuthEventType.BIOMETRIC_AUTH_FAILURE, {
        type: AuthEventType.BIOMETRIC_AUTH_FAILURE,
        timestamp: Date.now(),
        error: {
          code: error instanceof Error ? error.name : 'UNKNOWN_ERROR',
          message: error instanceof Error ? error.message : 'Biometric authentication failed',
          timestamp: Date.now()
        }
      } as AuthEvent);
      
      throw error;
    }
  }

  /**
   * 清理资源
   */
  public async cleanup(): Promise<void> {
    try {
      // 移除事件监听器
      this.eventBus.removeAllListeners('network:statusChanged');
      this.eventBus.removeAllListeners('app:stateChanged');
      
      // 重置实例
      AuthRepository.instance = null as any;
      
      this.logger.info('AuthRepository cleanup completed');
    } catch (error) {
      this.logger.error('Failed to cleanup AuthRepository', error as Error);
    }
  }
}