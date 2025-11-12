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
  private async initialize(): Promise<void> {
    try {
      // 加载配置
      await this.loadConfig();
      
      // 恢复认证状态
      await this.restoreAuthState();
      
      // 设置令牌过期检查
      this.setupTokenExpiryCheck();
      
      // 设置会话超时
      this.setupSessionTimeout();
      
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
    
    // 监听权限相关事件
    this.eventBus.on('auth:permissionDenied', (event: AuthEvent) => {
      this.logger.warn(`Permission denied: ${event.data?.permissionId}`, event.error);
      // 这里可以记录权限拒绝事件，用于后续分析
    });
    
    // 监听配置变更事件
    this.eventBus.on('auth:configChanged', (event: AuthEvent) => {
      // 配置变更时，更新相关设置
      this.applyConfigChanges(event.data as AuthConfig);
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
      
      // 应用配置变更
      this.applyConfigChanges(updatedConfig);
      
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
   * 应用配置变更
   */
  private applyConfigChanges(config: AuthConfig): void {
    // 根据配置调整行为
    if (config.sessionTimeout > 0) {
      // 重新设置会话超时
      this.setupSessionTimeout();
    }
    
    // 如果启用了生物认证，验证设备支持
    if (config.enableBiometricAuth) {
      this.checkBiometricSupport().catch(err => {
        this.logger.warn('Biometric authentication not supported', err);
        // 禁用生物认证
        this.setConfig({ enableBiometricAuth: false }).catch(setConfigErr => {
          this.logger.error('Failed to disable biometric auth', setConfigErr);
        });
      });
    }
  }

  /**
   * 检查生物认证支持
   */
  private async checkBiometricSupport(): Promise<boolean> {
    try {
      // 在实际应用中，这里应该调用设备的生物认证API
      // 由于是示例实现，返回false
      this.logger.debug('Checking biometric support');
      return false;
    } catch (error) {
      this.logger.warn('Error checking biometric support', error as Error);
      return false;
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
            
            // 加载用户权限
            await this.loadUserPermissions(savedUser.id);
            
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
      
      // 如果选择记住我，保存凭证（加密）
      if (rememberMe && this.cachedConfig?.enableAutoLogin) {
        await this.saveRememberMeCredentials(credentials);
      }
      
      // 加载用户权限
      await this.loadUserPermissions(authResponse.user.id);
      
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
   * 保存记住我凭证
   */
  private async saveRememberMeCredentials(credentials: UserCredentials): Promise<void> {
    try {
      // 在实际应用中，这里应该对凭证进行加密存储
      // 为了安全，密码不应该直接存储，而是存储一个令牌或标识符
      const rememberMeData = {
        username: credentials.username,
        // 注意：实际应用中不应该存储密码，这里仅作示例
        // 应该使用一个特殊的令牌或标识符
        savedAt: Date.now()
      };
      
      await this.storageUtil.setObject(
        this.storageKeys.rememberMeCredentials,
        rememberMeData,
        LocalStorageType.SECURE
      );
      
      this.logger.debug('Remember me credentials saved');
    } catch (error) {
      this.logger.warn('Failed to save remember me credentials', error as Error);
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
      
      // 如果有活跃的令牌，调用登出API（异步，不阻塞）
      if (this.cachedToken) {
        this.networkUtil.post(
          `${this.apiEndpoints.baseUrl}${this.apiEndpoints.logout}`,
          null,
          {
            headers: {
              'Authorization': `${this.cachedToken.tokenType} ${this.cachedToken.accessToken}`
            }
          }
        ).catch(err => {
          // 记录错误但不中断登出流程
          this.logger.warn('Failed to call logout API', err);
        });
      }
      
      // 清除认证状态
      await this.resetAuthState();
      
      // 清除记住我凭证
      await this.clearRememberMeCredentials();
      
      // 更新认证状态变更事件
      this.emitAuthStatusChange(AuthStatus.UNAUTHENTICATED);
      
      // 发布登出成功事件
      this.eventBus.emit(AuthEventType.LOGOUT_SUCCESS, {
        type: AuthEventType.LOGOUT_SUCCESS,
        timestamp: Date.now()
      } as AuthEvent);
      
      this.logger.info('User logged out successfully');
    } catch (error) {
      this.logger.error('Logout failed', error as Error);
      
      // 构建认证错误
      const authError: AuthError = {
        code: error instanceof Error ? error.name : 'UNKNOWN_ERROR',
        message: error instanceof Error ? error.message : 'Logout failed',
        timestamp: Date.now()
      };
      
      // 发布登出失败事件
      this.eventBus.emit(AuthEventType.LOGOUT_FAILURE, {
        type: AuthEventType.LOGOUT_FAILURE,
        timestamp: Date.now(),
        error: authError
      } as AuthEvent);
      
      // 即使出错，也要尝试重置认证状态
      await this.resetAuthState().catch(resetErr => {
        this.logger.error('Failed to reset auth state during logout failure', resetErr);
      });
    }
  }

  /**
   * 清除记住我凭证
   */
  private async clearRememberMeCredentials(): Promise<void> {
    try {
      await this.storageUtil.remove(
        this.storageKeys.rememberMeCredentials,
        LocalStorageType.SECURE
      );
      
      this.logger.debug('Remember me credentials cleared');
    } catch (error) {
      this.logger.warn('Failed to clear remember me credentials', error as Error);
    }
  }

  /**
   * 刷新认证令牌
   */
  public async refreshToken(): Promise<RefreshTokenResponse> {
    try {
      // 检查是否正在刷新令牌，避免重复请求
      if (this.isRefreshingToken) {
        this.logger.warn('Token refresh already in progress');
        // 等待当前刷新完成（这里简化处理，实际应使用Promise队列）
        throw new Error('Token refresh already in progress');
      }
      
      // 检查是否有刷新令牌
      if (!this.cachedToken || !this.cachedToken.refreshToken) {
        this.logger.warn('No refresh token available');
        throw new Error('No refresh token available');
      }
      
      // 设置刷新标志
      this.isRefreshingToken = true;
      
      // 更新状态为刷新中
      this.updateAuthStatus(AuthStatus.REFRESHING);
      
      // 发布令牌刷新开始事件
      this.eventBus.emit(AuthEventType.TOKEN_REFRESH_START, {
        type: AuthEventType.TOKEN_REFRESH_START,
        timestamp: Date.now()
      } as AuthEvent);
      
      // 调用刷新令牌API
      const response = await this.networkUtil.post<RefreshTokenResponse>(
        `${this.apiEndpoints.baseUrl}${this.apiEndpoints.refreshToken}`,
        { refreshToken: this.cachedToken.refreshToken }
      );
      
      const refreshResponse = response.data;
      
      // 更新令牌
      this.cachedToken = refreshResponse.token;
      
      // 保存新令牌
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
      
      // 构建认证错误
      const authError: AuthError = {
        code: error instanceof Error ? error.name : 'UNKNOWN_ERROR',
        message: error instanceof Error ? error.message : 'Token refresh failed',
        timestamp: Date.now()
      };
      
      // 发布令牌刷新失败事件
      this.eventBus.emit(AuthEventType.TOKEN_REFRESH_FAILURE, {
        type: AuthEventType.TOKEN_REFRESH_FAILURE,
        timestamp: Date.now(),
        error: authError
      } as AuthEvent);
      
      // 刷新失败，清除认证状态
      await this.resetAuthState().catch(resetErr => {
        this.logger.error('Failed to reset auth state after token refresh failure', resetErr);
      });
      
      throw authError;
    } finally {
      // 重置刷新标志
      this.isRefreshingToken = false;
    }
  }

  /**
   * 处理令牌过期
   */
  private async handleTokenExpiry(): Promise<void> {
    try {
      // 尝试刷新令牌
      await this.refreshToken();
    } catch (error) {
      this.logger.error('Failed to handle token expiry', error as Error);
      
      // 刷新失败，清除认证状态
      await this.resetAuthState();
      
      // 发布会话过期事件
      this.eventBus.emit(AuthEventType.SESSION_EXPIRED, {
        type: AuthEventType.SESSION_EXPIRED,
        timestamp: Date.now(),
        error: error as Error
      } as AuthEvent);
    }
  }

  /**
   * 检查是否需要刷新令牌
   */
  public async refreshTokenIfNeeded(): Promise<boolean> {
    if (!this.cachedToken) {
      return false;
    }
    
    // 检查令牌是否即将过期
    if (this.isTokenExpiredSoon() && !this.isRefreshingToken) {
      try {
        await this.refreshToken();
        return true;
      } catch (error) {
        this.logger.error('Failed to refresh token when needed', error as Error);
        return false;
      }
    }
    
    return false;
  }

  /**
   * 检查令牌是否过期
   */
  public isTokenExpired(): boolean {
    if (!this.cachedToken) {
      return true;
    }
    
    const now = Date.now() / 1000; // 转换为秒
    const expiresAt = this.cachedToken.issuedAt + this.cachedToken.expiresIn;
    
    return now >= expiresAt;
  }

  /**
   * 检查令牌是否即将过期
   */
  public isTokenExpiredSoon(): boolean {
    if (!this.cachedToken || !this.cachedConfig) {
      return false;
    }
    
    const now = Date.now() / 1000; // 转换为秒
    const expiresAt = this.cachedToken.issuedAt + this.cachedToken.expiresIn;
    const threshold = this.cachedConfig.tokenRefreshThreshold;
    
    return now >= (expiresAt - threshold);
  }

  /**
   * 设置令牌过期检查
   */
  private setupTokenExpiryCheck(): void {
    // 每30秒检查一次令牌是否需要刷新
    setInterval(() => {
      if (this.cachedToken && this.isTokenExpiredSoon() && !this.isRefreshingToken) {
        this.refreshTokenIfNeeded().catch(err => {
          this.logger.warn('Failed to refresh token during periodic check', err);
        });
      }
    }, 30000);
  }

  /**
   * 设置会话超时
   */
  private setupSessionTimeout(): void {
    if (!this.cachedConfig || this.cachedConfig.sessionTimeout <= 0) {
      return;
    }
    
    // 会话超时定时器
    let sessionTimeoutTimer: number | null = null;
    
    // 重置超时计时器的函数
    const resetTimeout = () => {
      if (sessionTimeoutTimer) {
        clearTimeout(sessionTimeoutTimer);
      }
      
      sessionTimeoutTimer = setTimeout(() => {
        // 会话超时，自动登出
        this.logout().catch(err => {
          this.logger.warn('Failed to logout on session timeout', err);
        });
      }, this.cachedConfig!.sessionTimeout * 1000);
    };
    
    // 初始设置超时
    resetTimeout();
    
    // 监听用户活动，重置超时计时器
    this.eventBus.on('user:activity', resetTimeout);
  }

  /**
   * 用户注册
   */
  public async register(userInfo: UserRegisterInfo): Promise<{ user: UserInfo; requiresVerification: boolean }> {
    try {
      // 调用注册API
      const response = await this.networkUtil.post<{
        user: UserInfo;
        requiresVerification: boolean;
      }>(
        `${this.apiEndpoints.baseUrl}${this.apiEndpoints.register}`,
        userInfo
      );
      
      const registerResponse = response.data;
      
      // 发布注册成功事件
      this.eventBus.emit(AuthEventType.REGISTRATION_SUCCESS, {
        type: AuthEventType.REGISTRATION_SUCCESS,
        timestamp: Date.now(),
        data: registerResponse
      } as AuthEvent);
      
      this.logger.info(`User ${registerResponse.user.username} registered successfully`);
      
      return registerResponse;
    } catch (error) {
      this.logger.error('Registration failed', error as Error);
      
      // 构建认证错误
      const authError: AuthError = {
        code: error instanceof Error ? error.name : 'UNKNOWN_ERROR',
        message: error instanceof Error ? error.message : 'Registration failed',
        timestamp: Date.now()
      };
      
      throw authError;
    }
  }

  /**
   * 发送密码重置请求
   */
  public async sendPasswordResetRequest(email: string): Promise<{ success: boolean; message: string }> {
    try {
      // 调用忘记密码API
      const response = await this.networkUtil.post<{ success: boolean; message: string }>(
        `${this.apiEndpoints.baseUrl}${this.apiEndpoints.forgotPassword}`,
        { email }
      );
      
      // 发布密码重置请求事件
      this.eventBus.emit(AuthEventType.PASSWORD_RESET_REQUEST, {
        type: AuthEventType.PASSWORD_RESET_REQUEST,
        timestamp: Date.now(),
        data: { email, success: response.data.success }
      } as AuthEvent);
      
      this.logger.info(`Password reset request sent for email: ${email}`);
      
      return response.data;
    } catch (error) {
      this.logger.error('Failed to send password reset request', error as Error);
      throw error;
    }
  }

  /**
   * 重置密码
   */
  public async resetPassword(token: string, newPassword: string): Promise<{ success: boolean; message: string }> {
    try {
      // 调用重置密码API
      const response = await this.networkUtil.post<{ success: boolean; message: string }>(
        `${this.apiEndpoints.baseUrl}${this.apiEndpoints.resetPassword}`,
        { token, newPassword }
      );
      
      // 发布密码重置成功事件
      this.eventBus.emit(AuthEventType.PASSWORD_RESET_SUCCESS, {
        type: AuthEventType.PASSWORD_RESET_SUCCESS,
        timestamp: Date.now(),
        data: response.data
      } as AuthEvent);
      
      this.logger.info('Password reset successful');
      
      return response.data;
    } catch (error) {
      this.logger.error('Password reset failed', error as Error);
      throw error;
    }
  }

  /**
   * 验证邮箱
   */
  public async verifyEmail(token: string): Promise<{ success: boolean; message: string }> {
    try {
      // 调用邮箱验证API
      const response = await this.networkUtil.post<{ success: boolean; message: string }>(
        `${this.apiEndpoints.baseUrl}${this.apiEndpoints.verifyEmail}`,
        { token }
      );
      
      this.logger.info('Email verification successful');
      
      return response.data;
    } catch (error) {
      this.logger.error('Email verification failed', error as Error);
      throw error;
    }
  }

  /**
   * 重新发送验证邮件
   */
  public async resendVerificationEmail(email: string): Promise<{ success: boolean; message: string }> {
    try {
      // 调用重新发送验证邮件API
      const response = await this.networkUtil.post<{ success: boolean; message: string }>(
        `${this.apiEndpoints.baseUrl}${this.apiEndpoints.resendVerification}`,
        { email }
      );
      
      this.logger.info(`Verification email resent to: ${email}`);
      
      return response.data;
    } catch (error) {
      this.logger.error('Failed to resend verification email', error as Error);
      throw error;
    }
  }

  /**
   * 检查用户是否已认证
   */
  public isAuthenticated(): boolean {
    return this.currentStatus === AuthStatus.AUTHENTICATED && 
           !!this.cachedToken && 
           !this.isTokenExpired();
  }

  /**
   * 获取当前认证状态
   */
  public getAuthStatus(): AuthStatus {
    return this.currentStatus;
  }

  /**
   * 更新认证状态
   */
  private updateAuthStatus(status: AuthStatus): void {
    if (this.currentStatus !== status) {
      this.currentStatus = status;
      
      // 保存状态
      this.storageUtil.setString(
        this.storageKeys.authStatus,
        status,
        LocalStorageType.DEFAULT
      ).catch(err => {
        this.logger.warn('Failed to save auth status', err);
      });
    }
  }

  /**
   * 发布认证状态变更事件
   */
  private emitAuthStatusChange(status: AuthStatus): void {
    this.eventBus.emit(AuthEventType.AUTH_STATUS_CHANGED, {
      type: AuthEventType.AUTH_STATUS_CHANGED,
      timestamp: Date.now(),
      data: {
        status,
        user: this.cachedUser,
        isAuthenticated: status === AuthStatus.AUTHENTICATED
      }
    } as AuthEvent);
  }

  /**
   * 获取当前用户
   */
  public getCurrentUser(): UserInfo | null {
    // 确保用户已认证且令牌未过期
    if (!this.isAuthenticated()) {
      return null;
    }
    
    return this.cachedUser;
  }

  /**
   * 获取认证令牌
   */
  public getAuthToken(): string | null {
    // 确保令牌有效
    if (!this.cachedToken || this.isTokenExpired()) {
      return null;
    }
    
    return `${this.cachedToken.tokenType} ${this.cachedToken.accessToken}`;
  }

  /**
   * 获取原始访问令牌
   */
  public getAccessToken(): string | null {
    // 确保令牌有效
    if (!this.cachedToken || this.isTokenExpired()) {
      return null;
    }
    
    return this.cachedToken.accessToken;
  }

  /**
   * 获取刷新令牌
   */
  public getRefreshToken(): string | null {
    return this.cachedToken?.refreshToken || null;
  }

  /**
   * 加载用户权限
   */
  private async loadUserPermissions(userId: string): Promise<void> {
    try {
      // 尝试从缓存获取
      const cachedPermissions = await this.cacheService.getCache<UserPermissions>(`user_permissions:${userId}`);
      
      if (cachedPermissions) {
        this.cachedUserPermissions = cachedPermissions;
        return;
      }
      
      // 调用API获取用户权限
      const response = await this.networkUtil.get<UserPermissions>(
        `${this.apiEndpoints.baseUrl}${this.apiEndpoints.userPermissions}/${userId}`,
        {
          headers: {
            'Authorization': this.getAuthToken() || ''
          }
        }
      );
      
      const userPermissions = response.data;
      
      // 保存到缓存
      await this.cacheService.setCache(
        `user_permissions:${userId}`,
        userPermissions,
        {
          type: CacheType.MEMORY,
          expiry: 3600000 // 1小时
        }
      );
      
      // 保存到本地存储
      await this.storageUtil.setObject(
        this.storageKeys.userPermissions,
        userPermissions,
        LocalStorageType.DEFAULT
      );
      
      this.cachedUserPermissions = userPermissions;
      
      this.logger.debug(`User permissions loaded for ${userId}`);
    } catch (error) {
      this.logger.warn(`Failed to load user permissions for ${userId}, using local data`, error as Error);
      
      // 尝试从本地存储加载
      const localPermissions = await this.storageUtil.getObject<UserPermissions>(
        this.storageKeys.userPermissions,
        LocalStorageType.DEFAULT
      );
      
      if (localPermissions) {
        this.cachedUserPermissions = localPermissions;
      }
    }
  }

  /**
   * 检查用户权限
   */
  public async checkPermission(permissionId: string, context?: string | number | boolean | null): Promise<boolean> {
    try {
      // 确保用户已认证
      if (!this.isAuthenticated() || !this.cachedUser) {
        return false;
      }
      
      // 确保已加载用户权限
      if (!this.cachedUserPermissions) {
        await this.loadUserPermissions(this.cachedUser.id);
      }
      
      // 检查用户是否直接被授予权限
      if (this.cachedUserPermissions?.grantedPermissions.includes(permissionId)) {
        return true;
      }
      
      // 检查用户是否被拒绝权限
      if (this.cachedUserPermissions?.deniedPermissions.includes(permissionId)) {
        return false;
      }
      
      // 检查用户角色权限
      for (const role of this.cachedUserPermissions?.roles || []) {
        if (role.permissions.includes(permissionId) && role.isEnabled) {
          return true;
        }
      }
      
      // 检查用户拥有的权限列表
      const permission = this.cachedUserPermissions?.permissions.find(p => p.id === permissionId);
      if (permission && permission.isEnabled) {
        return true;
      }
      
      // 如果本地检查失败，尝试从服务器检查
      try {
        const response = await this.networkUtil.post<{ hasPermission: boolean }>(
          `${this.apiEndpoints.baseUrl}${this.apiEndpoints.checkPermission}`,
          { permissionId, userId: this.cachedUser.id, context },
          {
            headers: {
              'Authorization': this.getAuthToken() || ''
            }
          }
        );
        
        return response.data.hasPermission;
      } catch (serverError) {
        this.logger.warn(`Failed to check permission from server for ${permissionId}`, serverError as Error);
        // 服务器检查失败，返回本地检查结果（false）
        return false;
      }
    } catch (error) {
      this.logger.error(`Failed to check permission for ${permissionId}`, error as Error);
      
      // 发布权限拒绝事件
      this.eventBus.emit(AuthEventType.PERMISSION_DENIED, {
        type: AuthEventType.PERMISSION_DENIED,
        timestamp: Date.now(),
        error: error as Error,
        data: { permissionId, context }
      } as AuthEvent);
      
      return false;
    }
  }

  /**
   * 获取用户所有权限
   */
  public async getUserPermissions(): Promise<string[]> {
    try {
      // 确保用户已认证
      if (!this.isAuthenticated() || !this.cachedUser) {
        return [];
      }
      
      // 确保已加载用户权限
      if (!this.cachedUserPermissions) {
        await this.loadUserPermissions(this.cachedUser.id);
      }
      
      // 构建权限集合
      const permissions = new Set<string>();
      
      // 添加直接授予的权限
      this.cachedUserPermissions?.grantedPermissions.forEach(perm => permissions.add(perm));
      
      // 添加角色权限（排除被拒绝的权限）
      this.cachedUserPermissions?.roles.forEach(role => {
        if (role.isEnabled) {
          role.permissions.forEach(perm => {
            if (!this.cachedUserPermissions?.deniedPermissions.includes(perm)) {
              permissions.add(perm);
            }
          });
        }
      });
      
      // 添加拥有的权限（排除被拒绝的权限）
      this.cachedUserPermissions?.permissions.forEach(perm => {
        if (perm.isEnabled && !this.cachedUserPermissions?.deniedPermissions.includes(perm.id)) {
          permissions.add(perm.id);
        }
      });
      
      return Array.from(permissions);
    } catch (error) {
      this.logger.error('Failed to get user permissions', error as Error);
      return [];
    }
  }

  /**
   * 获取用户角色
   */
  public async getUserRoles(): Promise<Role[]> {
    try {
      // 确保用户已认证
      if (!this.isAuthenticated() || !this.cachedUser) {
        return [];
      }
      
      // 确保已加载用户权限
      if (!this.cachedUserPermissions) {
        await this.loadUserPermissions(this.cachedUser.id);
      }
      
      return [...(this.cachedUserPermissions?.roles || [])];
    } catch (error) {
      this.logger.error('Failed to get user roles', error as Error);
      return [];
    }
  }

  /**
   * 生物认证登录
   */
  public async biometricLogin(): Promise<boolean> {
    try {
      // 检查是否启用了生物认证
      const config = await this.getConfig();
      if (!config.enableBiometricAuth) {
        throw new Error('Biometric authentication is not enabled');
      }
      
      // 检查设备是否支持生物认证
      const isSupported = await this.checkBiometricSupport();
      if (!isSupported) {
        throw new Error('Biometric authentication is not supported on this device');
      }
      
      // 获取保存的生物认证数据
      const biometricData = await this.storageUtil.getObject<{
        username: string;
        biometricToken: string;
      }>(
        this.storageKeys.biometricData,
        LocalStorageType.SECURE
      );
      
      if (!biometricData) {
        throw new Error('No biometric authentication data found');
      }
      
      // 在实际应用中，这里应该调用设备的生物认证API进行验证
      // 由于是示例实现，假设验证成功
      const isAuthenticated = true; // 模拟生物认证成功
      
      if (!isAuthenticated) {
        throw new Error('Biometric authentication failed');
      }
      
      // 调用服务器验证生物认证令牌
      const response = await this.networkUtil.post<AuthResponse>(
        `${this.apiEndpoints.baseUrl}${this.apiEndpoints.biometricAuth}`,
        {
          username: biometricData.username,
          biometricToken: biometricData.biometricToken
        }
      );
      
      // 保存认证状态
      await this.saveAuthState(response.data.token, response.data.user);
      
      // 发布生物认证成功事件
      this.eventBus.emit(AuthEventType.BIOMETRIC_AUTH_SUCCESS, {
        type: AuthEventType.BIOMETRIC_AUTH_SUCCESS,
        timestamp: Date.now(),
        data: { user: response.data.user }
      } as AuthEvent);
      
      // 更新认证状态
      this.updateAuthStatus(AuthStatus.AUTHENTICATED);
      this.emitAuthStatusChange(AuthStatus.AUTHENTICATED);
      
      this.logger.info(`User ${response.data.user.username} logged in via biometric authentication`);
      
      return true;
    } catch (error) {
      this.logger.error('Biometric authentication failed', error as Error);
      
      // 发布生物认证失败事件
      this.eventBus.emit(AuthEventType.BIOMETRIC_AUTH_FAILURE, {
        type: AuthEventType.BIOMETRIC_AUTH_FAILURE,
        timestamp: Date.now(),
        error: error as Error
      } as AuthEvent);
      
      return false;
    }
  }

  /**
   * 设置生物认证
   */
  public async setupBiometricAuth(enabled: boolean): Promise<boolean> {
    try {
      // 确保用户已认证
      if (!this.isAuthenticated() || !this.cachedUser) {
        throw new Error('User must be authenticated to setup biometric authentication');
      }
      
      if (enabled) {
        // 检查设备是否支持生物认证
        const isSupported = await this.checkBiometricSupport();
        if (!isSupported) {
          throw new Error('Biometric authentication is not supported on this device');
        }
        
        // 在实际应用中，这里应该调用设备的生物认证API进行验证
        // 由于是示例实现，假设验证成功
        const isAuthenticated = true; // 模拟生物认证成功
        
        if (!isAuthenticated) {
          throw new Error('Biometric authentication failed');
        }
        
        // 调用服务器注册生物认证
        const response = await this.networkUtil.post<{ biometricToken: string }>(
          `${this.apiEndpoints.baseUrl}${this.apiEndpoints.biometricAuth}/register`,
          { username: this.cachedUser.username },
          {
            headers: {
              'Authorization': this.getAuthToken() || ''
            }
          }
        );
        
        // 保存生物认证数据
        await this.storageUtil.setObject(
          this.storageKeys.biometricData,
          {
            username: this.cachedUser.username,
            biometricToken: response.data.biometricToken
          },
          LocalStorageType.SECURE
        );
        
        // 更新配置
        await this.setConfig({ enableBiometricAuth: true });
        
        this.logger.info(`Biometric authentication enabled for user ${this.cachedUser.username}`);
      } else {
        // 禁用生物认证，清除数据
        await this.storageUtil.remove(
          this.storageKeys.biometricData,
          LocalStorageType.SECURE
        );
        
        // 更新配置
        await this.setConfig({ enableBiometricAuth: false });
        
        this.logger.info(`Biometric authentication disabled for user ${this.cachedUser.username}`);
      }
      
      return true;
    } catch (error) {
      this.logger.error('Failed to setup biometric authentication', error as Error);
      return false;
    }
  }

  /**
   * 导出认证数据（用于调试或分析）
   */
  public async exportAuthData(): Promise<{
    status: AuthStatus;
    user: UserInfo | null;
    token: Partial<AuthToken> | null;
    permissions: UserPermissions | null;
    config: AuthConfig;
    loginAttempts: number;
    lastLogin: number | null;
    exportTime: number;
  }> {
    try {
      // 获取最后登录时间
      const lastLogin = await this.storageUtil.getNumber(
        this.storageKeys.lastLoginTimestamp,
        LocalStorageType.DEFAULT
      );
      
      // 注意：在导出时，不应包含敏感信息如完整令牌
      const tokenInfo = this.cachedToken ? {
        tokenType: this.cachedToken.tokenType,
        issuedAt: this.cachedToken.issuedAt,
        expiresIn: this.cachedToken.expiresIn,
        scope: this.cachedToken.scope
        // 不包含accessToken和refreshToken
      } : null;
      
      const data = {
        status: this.currentStatus,
        user: this.cachedUser,
        token: tokenInfo,
        permissions: this.cachedUserPermissions,
        config: await this.getConfig(),
        loginAttempts: this.loginAttempts,
        lastLogin,
        exportTime: Date.now()
      };
      
      this.logger.info('Auth data exported (sensitive information removed)');
      
      return data;
    } catch (error) {
      this.logger.error('Failed to export auth data', error as Error);
      throw error;
    }
  }
}

// 导出默认实例
export default AuthRepository.getInstance();