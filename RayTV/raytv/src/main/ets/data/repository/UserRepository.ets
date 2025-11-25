// UserRepository - 用户数据仓库类
// 负责管理用户相关数据，包括用户信息、权限、收藏、历史记录等

import Logger from '../../common/util/Logger';
import StorageUtil from '../../common/util/StorageUtil';
import NetworkUtil from '../../common/util/NetworkUtil';
import EventBusUtil from '../../common/util/EventBusUtil';
import CacheService from '../../service/cache/CacheService';
import {
  UserRole,
  UserStatus,
  RegisterRequest,
  LoginRequest,
  UserInfo,
  UserProfile,
  UserSettings,
  UserPermission,
  ChangePasswordRequest,
  UpdateProfileRequest,
  UpdateSettingsRequest,
  UserStatistics,
  UserActivity
} from '../dto/UserDto';
import { LocalStorageType } from '../model/LocalModel';
import { CacheType } from '../model/CacheModel';

/**
 * 用户事件类型
 */
export const UserEventType = {
  USER_LOGIN: 'user:login',
  USER_LOGOUT: 'user:logout',
  USER_REGISTERED: 'user:registered',
  USER_PROFILE_UPDATED: 'user:profileUpdated',
  USER_SETTINGS_UPDATED: 'user:settingsUpdated',
  USER_PERMISSIONS_CHANGED: 'user:permissionsChanged',
  USER_STATUS_CHANGED: 'user:statusChanged',
  USER_ACTIVITY_LOGGED: 'user:activityLogged',
  USER_ERROR: 'user:error'
} as const;

/**
 * 用户状态变更事件数据
 */
export interface UserStatusChangeEvent {
  userId: string;
  oldStatus: UserStatus;
  newStatus: UserStatus;
  timestamp: number;
}

/**
 * 权限变更事件数据
 */
export interface PermissionChangeEvent {
  userId: string;
  addedPermissions?: UserPermission[];
  removedPermissions?: UserPermission[];
  timestamp: number;
}

/**
 * 用户活动事件数据
 */
export interface UserActivityEvent {
  userId: string;
  activity: UserActivity;
  timestamp: number;
}

/**
 * 用户数据仓库类
 */
export class UserRepository {
  private static instance: UserRepository;
  private logger = Logger.getInstance();
  private storageUtil = StorageUtil.getInstance();
  private networkUtil = NetworkUtil.getInstance();
  private eventBus = EventBusUtil.getInstance();
  private cacheService = CacheService.getInstance();
  
  // 当前登录用户
  private currentUser: UserInfo | null = null;
  
  // 认证令牌
  private authToken: string | null = null;
  
  // 会话过期时间
  private sessionExpiry: number | null = null;
  
  // API端点配置
  private apiEndpoints = {
    baseUrl: 'https://api.raytv.example.com',
    register: '/auth/register',
    login: '/auth/login',
    logout: '/auth/logout',
    refreshToken: '/auth/refresh',
    userProfile: '/user/profile',
    userSettings: '/user/settings',
    userStatistics: '/user/statistics',
    userActivity: '/user/activity',
    changePassword: '/user/change-password'
  };
  
  // 缓存键配置
  private cacheKeys = {
    currentUser: 'user:current',
    authToken: 'user:authToken',
    sessionExpiry: 'user:sessionExpiry',
    userCache: 'user:cache:',
    userSettings: 'user:settings:',
    userStatistics: 'user:statistics:'
  };

  /**
   * 私有构造函数
   */
  private constructor() {
    this.logger.info('UserRepository initialized');
    this.setupEventListeners();
    this.initialize();
  }

  /**
   * 获取UserRepository单例实例
   */
  public static getInstance(): UserRepository {
    if (!UserRepository.instance) {
      UserRepository.instance = new UserRepository();
    }
    return UserRepository.instance;
  }

  /**
   * 初始化用户仓库
   */
  public async initialize(): Promise<void> {
    try {
      // 从存储中恢复用户会话
      await this.restoreUserSession();
      
      // 注册会话过期检查
      this.setupSessionExpiryCheck();
      
      this.logger.info('UserRepository initialization completed');
    } catch (error) {
      this.logger.error('Failed to initialize UserRepository', error as Error);
      
      // 发布用户错误事件
      this.eventBus.emit(UserEventType.USER_ERROR, { error: error as Error });
    }
  }

  /**
   * 设置事件监听器
   */
  private setupEventListeners(): void {
    // 监听应用退出事件，保存用户状态
    this.eventBus.on('app:exit', async () => {
      await this.saveUserSession();
    });
    
    // 监听网络状态变化，处理离线/在线切换
    this.eventBus.on('network:statusChanged', async (status: { isOnline: boolean }) => {
      if (status.isOnline && this.currentUser) {
        // 重新同步用户数据
        await this.syncUserData();
      }
    });
  }

  /**
   * 用户注册
   * @param request 注册请求
   */
  public async register(request: RegisterRequest): Promise<UserInfo> {
    try {
      // 验证注册请求
      this.validateRegisterRequest(request);
      
      // 调用API注册
      const response = await this.networkUtil.post<UserInfo>(
        `${this.apiEndpoints.baseUrl}${this.apiEndpoints.register}`,
        request
      );
      
      const userInfo = response.data;
      
      // 发布用户注册事件
      this.eventBus.emit(UserEventType.USER_REGISTERED, userInfo);
      
      this.logger.info(`User registered successfully: ${userInfo.username}`);
      
      return userInfo;
    } catch (error) {
      this.logger.error('User registration failed', error as Error);
      
      // 发布用户错误事件
      this.eventBus.emit(UserEventType.USER_ERROR, { 
        operation: 'register', 
        error: (error as Error).message 
      });
      
      throw error;
    }
  }

  /**
   * 用户登录
   * @param request 登录请求
   */
  public async login(request: LoginRequest): Promise<UserInfo> {
    try {
      // 验证登录请求
      this.validateLoginRequest(request);
      
      // 调用API登录
      const response = await this.networkUtil.post<{
        user: UserInfo;
        token: string;
        expiresIn: number;
      }>(
        `${this.apiEndpoints.baseUrl}${this.apiEndpoints.login}`,
        request
      );
      
      const { user, token, expiresIn } = response.data;
      
      // 设置当前用户和认证信息
      this.setCurrentUser(user, token, expiresIn);
      
      // 保存会话
      await this.saveUserSession();
      
      // 加载用户设置和统计信息
      await this.loadUserSettings();
      await this.loadUserStatistics();
      
      // 发布用户登录事件
      this.eventBus.emit(UserEventType.USER_LOGIN, user);
      
      this.logger.info(`User logged in successfully: ${user.username}`);
      
      return user;
    } catch (error) {
      this.logger.error('User login failed', error as Error);
      
      // 发布用户错误事件
      this.eventBus.emit(UserEventType.USER_ERROR, { 
        operation: 'login', 
        error: (error as Error).message 
      });
      
      throw error;
    }
  }

  /**
   * 用户登出
   */
  public async logout(): Promise<void> {
    try {
      if (!this.isLoggedIn()) {
        return;
      }
      
      const userId = this.currentUser?.id;
      
      try {
        // 尝试调用API登出
        await this.networkUtil.post(
          `${this.apiEndpoints.baseUrl}${this.apiEndpoints.logout}`,
          {},
          {
            headers: {
              'Authorization': `Bearer ${this.authToken}`
            }
          }
        );
      } catch (error) {
        // API调用失败时记录日志但不抛出错误
        this.logger.warn('API logout failed, continuing with local logout', error as Error);
      }
      
      // 清除本地会话数据
      this.clearUserSession();
      
      // 发布用户登出事件
      this.eventBus.emit(UserEventType.USER_LOGOUT, { userId });
      
      this.logger.info(`User logged out: ${userId}`);
    } catch (error) {
      this.logger.error('User logout failed', error as Error);
      
      // 即使出错也要清理本地会话
      this.clearUserSession();
      
      throw error;
    }
  }

  /**
   * 刷新认证令牌
   */
  public async refreshToken(): Promise<boolean> {
    try {
      if (!this.authToken || !this.currentUser) {
        return false;
      }
      
      const response = await this.networkUtil.post<{
        token: string;
        expiresIn: number;
      }>(
        `${this.apiEndpoints.baseUrl}${this.apiEndpoints.refreshToken}`,
        {},
        {
          headers: {
            'Authorization': `Bearer ${this.authToken}`
          }
        }
      );
      
      const { token, expiresIn } = response.data;
      
      // 更新令牌信息
      this.authToken = token;
      this.sessionExpiry = Date.now() + expiresIn * 1000;
      
      // 保存更新后的令牌
      await this.storageUtil.setString(this.cacheKeys.authToken, token, LocalStorageType.SECURE);
      await this.storageUtil.setNumber(this.cacheKeys.sessionExpiry, this.sessionExpiry, LocalStorageType.SECURE);
      
      this.logger.info('Auth token refreshed successfully');
      
      return true;
    } catch (error) {
      this.logger.error('Failed to refresh auth token', error as Error);
      
      // 令牌刷新失败，可能需要重新登录
      await this.logout();
      
      return false;
    }
  }

  /**
   * 获取当前用户信息
   */
  public async getCurrentUser(forceRefresh: boolean = false): Promise<UserInfo | null> {
    if (!this.isLoggedIn()) {
      return null;
    }
    
    // 如果强制刷新或用户信息不存在，从API获取
    if (forceRefresh || !this.currentUser) {
      await this.loadCurrentUserProfile();
    }
    
    return this.currentUser;
  }

  /**
   * 更新用户资料
   * @param request 更新资料请求
   */
  public async updateProfile(request: UpdateProfileRequest): Promise<UserProfile> {
    try {
      if (!this.isLoggedIn()) {
        throw new Error('User not logged in');
      }
      
      const response = await this.networkUtil.put<UserProfile>(
        `${this.apiEndpoints.baseUrl}${this.apiEndpoints.userProfile}`,
        request,
        {
          headers: {
            'Authorization': `Bearer ${this.authToken}`
          }
        }
      );
      
      const updatedProfile = response.data;
      
      // 更新当前用户的资料信息
      if (this.currentUser) {
        this.currentUser.profile = { ...this.currentUser.profile, ...updatedProfile };
        
        // 更新缓存
        await this.cacheService.setCache(
          `${this.cacheKeys.userCache}${this.currentUser.id}`,
          this.currentUser,
          {
            type: CacheType.MEMORY_DISK,
            expiry: 3600 * 1000 // 1小时
          }
        );
      }
      
      // 发布用户资料更新事件
      this.eventBus.emit(UserEventType.USER_PROFILE_UPDATED, updatedProfile);
      
      this.logger.info(`User profile updated: ${this.currentUser?.username}`);
      
      return updatedProfile;
    } catch (error) {
      this.logger.error('Failed to update user profile', error as Error);
      
      // 发布用户错误事件
      this.eventBus.emit(UserEventType.USER_ERROR, { 
        operation: 'updateProfile', 
        error: (error as Error).message 
      });
      
      throw error;
    }
  }

  /**
   * 获取用户设置
   */
  public async getUserSettings(): Promise<UserSettings | null> {
    if (!this.isLoggedIn()) {
      return null;
    }
    
    return await this.loadUserSettings();
  }

  /**
   * 更新用户设置
   * @param request 更新设置请求
   */
  public async updateSettings(request: UpdateSettingsRequest): Promise<UserSettings> {
    try {
      if (!this.isLoggedIn()) {
        throw new Error('User not logged in');
      }
      
      const response = await this.networkUtil.put<UserSettings>(
        `${this.apiEndpoints.baseUrl}${this.apiEndpoints.userSettings}`,
        request,
        {
          headers: {
            'Authorization': `Bearer ${this.authToken}`
          }
        }
      );
      
      const updatedSettings = response.data;
      
      // 保存更新后的设置
      const settingsKey = `${this.cacheKeys.userSettings}${this.currentUser!.id}`;
      await this.cacheService.setCache(
        settingsKey,
        updatedSettings,
        {
          type: CacheType.MEMORY_DISK,
          expiry: 86400 * 1000 // 24小时
        }
      );
      
      // 发布用户设置更新事件
      this.eventBus.emit(UserEventType.USER_SETTINGS_UPDATED, updatedSettings);
      
      this.logger.info(`User settings updated: ${this.currentUser?.username}`);
      
      return updatedSettings;
    } catch (error) {
      this.logger.error('Failed to update user settings', error as Error);
      
      // 发布用户错误事件
      this.eventBus.emit(UserEventType.USER_ERROR, { 
        operation: 'updateSettings', 
        error: (error as Error).message 
      });
      
      throw error;
    }
  }

  /**
   * 修改密码
   * @param request 修改密码请求
   */
  public async changePassword(request: ChangePasswordRequest): Promise<boolean> {
    try {
      if (!this.isLoggedIn()) {
        throw new Error('User not logged in');
      }
      
      await this.networkUtil.post(
        `${this.apiEndpoints.baseUrl}${this.apiEndpoints.changePassword}`,
        request,
        {
          headers: {
            'Authorization': `Bearer ${this.authToken}`
          }
        }
      );
      
      this.logger.info(`Password changed successfully for user: ${this.currentUser?.username}`);
      
      // 记录用户活动
      await this.logUserActivity({
        type: 'password_changed',
        details: { timestamp: Date.now() }
      });
      
      return true;
    } catch (error) {
      this.logger.error('Failed to change password', error as Error);
      
      // 发布用户错误事件
      this.eventBus.emit(UserEventType.USER_ERROR, { 
        operation: 'changePassword', 
        error: (error as Error).message 
      });
      
      throw error;
    }
  }

  /**
   * 获取用户统计信息
   */
  public async getUserStatistics(): Promise<UserStatistics | null> {
    if (!this.isLoggedIn()) {
      return null;
    }
    
    return await this.loadUserStatistics();
  }

  /**
   * 检查用户是否已登录
   */
  public isLoggedIn(): boolean {
    // 检查用户信息和令牌是否存在，以及会话是否未过期
    return this.currentUser !== null && 
           this.authToken !== null && 
           (this.sessionExpiry === null || Date.now() < this.sessionExpiry);
  }

  /**
   * 检查用户是否有特定权限
   * @param permission 权限名称
   */
  public hasPermission(permission: UserPermission): boolean {
    if (!this.currentUser) {
      return false;
    }
    
    // 超级管理员拥有所有权限
    if (this.currentUser.role === UserRole.ADMINISTRATOR) {
      return true;
    }
    
    // 检查用户权限列表
    return this.currentUser.permissions?.includes(permission) || false;
  }

  /**
   * 检查用户是否有特定角色
   * @param role 角色名称
   */
  public hasRole(role: UserRole): boolean {
    if (!this.currentUser) {
      return false;
    }
    
    // 角色有层级关系，高级角色包含低级角色的权限
    switch (role) {
      case UserRole.USER:
        return true; // 所有已登录用户都至少有USER角色
      case UserRole.PREMIUM:
        return this.currentUser.role === UserRole.PREMIUM || 
               this.currentUser.role === UserRole.ADMINISTRATOR;
      case UserRole.ADMINISTRATOR:
        return this.currentUser.role === UserRole.ADMINISTRATOR;
      default:
        return false;
    }
  }

  /**
   * 获取认证令牌
   */
  public getAuthToken(): string | null {
    return this.authToken;
  }

  /**
   * 设置当前用户和认证信息
   */
  private setCurrentUser(user: UserInfo, token: string, expiresIn: number): void {
    this.currentUser = user;
    this.authToken = token;
    this.sessionExpiry = Date.now() + expiresIn * 1000;
  }

  /**
   * 保存用户会话到存储
   */
  private async saveUserSession(): Promise<void> {
    try {
      if (this.currentUser) {
        // 保存用户信息（不包含敏感数据）
        await this.storageUtil.setObject(
          this.cacheKeys.currentUser, 
          this.sanitizeUserInfo(this.currentUser),
          LocalStorageType.SECURE
        );
      }
      
      if (this.authToken) {
        // 保存认证令牌
        await this.storageUtil.setString(this.cacheKeys.authToken, this.authToken, LocalStorageType.SECURE);
      }
      
      if (this.sessionExpiry) {
        // 保存会话过期时间
        await this.storageUtil.setNumber(this.cacheKeys.sessionExpiry, this.sessionExpiry, LocalStorageType.SECURE);
      }
    } catch (error) {
      this.logger.warn('Failed to save user session', error as Error);
    }
  }

  /**
   * 从存储恢复用户会话
   */
  private async restoreUserSession(): Promise<void> {
    try {
      // 读取用户信息
      const savedUser = await this.storageUtil.getObject<UserInfo>(this.cacheKeys.currentUser, LocalStorageType.SECURE);
      const savedToken = await this.storageUtil.getString(this.cacheKeys.authToken, LocalStorageType.SECURE);
      const savedExpiry = await this.storageUtil.getNumber(this.cacheKeys.sessionExpiry, LocalStorageType.SECURE);
      
      // 检查会话是否有效
      if (savedUser && savedToken && savedExpiry && Date.now() < savedExpiry) {
        this.currentUser = savedUser;
        this.authToken = savedToken;
        this.sessionExpiry = savedExpiry;
        
        this.logger.info(`Restored user session: ${savedUser.username}`);
        
        // 验证令牌是否仍然有效
        try {
          await this.loadCurrentUserProfile();
        } catch (error) {
          // 令牌可能已过期，尝试刷新
          const refreshed = await this.refreshToken();
          if (!refreshed) {
            // 刷新失败，清除会话
            this.clearUserSession();
          }
        }
      } else {
        // 会话无效，清除存储的会话数据
        await this.clearStoredSession();
      }
    } catch (error) {
      this.logger.warn('Failed to restore user session', error as Error);
      await this.clearStoredSession();
    }
  }

  /**
   * 清除用户会话
   */
  private clearUserSession(): void {
    this.currentUser = null;
    this.authToken = null;
    this.sessionExpiry = null;
    
    // 清除内存缓存
    this.cacheService.removeCache(this.cacheKeys.currentUser);
    
    // 异步清除存储的会话数据
    this.clearStoredSession().catch(err => {
      this.logger.warn('Failed to clear stored session', err);
    });
  }

  /**
   * 清除存储的会话数据
   */
  private async clearStoredSession(): Promise<void> {
    await this.storageUtil.remove(this.cacheKeys.currentUser, LocalStorageType.SECURE);
    await this.storageUtil.remove(this.cacheKeys.authToken, LocalStorageType.SECURE);
    await this.storageUtil.remove(this.cacheKeys.sessionExpiry, LocalStorageType.SECURE);
  }

  /**
   * 设置会话过期检查
   */
  private setupSessionExpiryCheck(): void {
    // 每60秒检查一次会话是否过期
    setInterval(async () => {
      if (this.sessionExpiry && Date.now() > this.sessionExpiry) {
        // 会话已过期，尝试刷新令牌
        const refreshed = await this.refreshToken();
        if (!refreshed) {
          this.logger.info('Session expired and token refresh failed, logging out');
          
          // 发布用户登出事件
          this.eventBus.emit(UserEventType.USER_LOGOUT, { userId: this.currentUser?.id });
          
          this.clearUserSession();
        }
      }
    }, 60000);
  }

  /**
   * 加载当前用户资料
   */
  private async loadCurrentUserProfile(): Promise<void> {
    try {
      if (!this.isLoggedIn()) {
        return;
      }
      
      const response = await this.networkUtil.get<UserInfo>(
        `${this.apiEndpoints.baseUrl}${this.apiEndpoints.userProfile}`,
        {
          headers: {
            'Authorization': `Bearer ${this.authToken}`
          }
        }
      );
      
      this.currentUser = response.data;
      
      // 缓存用户信息
      await this.cacheService.setCache(
        `${this.cacheKeys.userCache}${this.currentUser.id}`,
        this.currentUser,
        {
          type: CacheType.MEMORY_DISK,
          expiry: 3600 * 1000 // 1小时
        }
      );
      
      this.logger.debug(`Loaded user profile: ${this.currentUser.username}`);
    } catch (error) {
      this.logger.error('Failed to load user profile', error as Error);
      throw error;
    }
  }

  /**
   * 加载用户设置
   */
  private async loadUserSettings(): Promise<UserSettings | null> {
    try {
      if (!this.currentUser) {
        return null;
      }
      
      const settingsKey = `${this.cacheKeys.userSettings}${this.currentUser.id}`;
      
      // 尝试从缓存获取
      let settings = await this.cacheService.getCache<UserSettings>(settingsKey);
      
      if (!settings) {
        // 从API获取
        const response = await this.networkUtil.get<UserSettings>(
          `${this.apiEndpoints.baseUrl}${this.apiEndpoints.userSettings}`,
          {
            headers: {
              'Authorization': `Bearer ${this.authToken}`
            }
          }
        );
        
        settings = response.data;
        
        // 缓存设置
        await this.cacheService.setCache(
          settingsKey,
          settings,
          {
            type: CacheType.MEMORY_DISK,
            expiry: 86400 * 1000 // 24小时
          }
        );
      }
      
      return settings;
    } catch (error) {
      this.logger.warn('Failed to load user settings', error as Error);
      return null;
    }
  }

  /**
   * 加载用户统计信息
   */
  private async loadUserStatistics(): Promise<UserStatistics | null> {
    try {
      if (!this.currentUser) {
        return null;
      }
      
      const statsKey = `${this.cacheKeys.userStatistics}${this.currentUser.id}`;
      
      // 尝试从缓存获取（统计信息可以缓存5分钟）
      let statistics = await this.cacheService.getCache<UserStatistics>(statsKey);
      
      if (!statistics) {
        // 从API获取
        const response = await this.networkUtil.get<UserStatistics>(
          `${this.apiEndpoints.baseUrl}${this.apiEndpoints.userStatistics}`,
          {
            headers: {
              'Authorization': `Bearer ${this.authToken}`
            }
          }
        );
        
        statistics = response.data;
        
        // 缓存统计信息
        await this.cacheService.setCache(
          statsKey,
          statistics,
          {
            type: CacheType.MEMORY,
            expiry: 300000 // 5分钟
          }
        );
      }
      
      return statistics;
    } catch (error) {
      this.logger.warn('Failed to load user statistics', error as Error);
      return null;
    }
  }

  /**
   * 同步用户数据（在线时）
   */
  private async syncUserData(): Promise<void> {
    try {
      if (!this.isLoggedIn()) {
        return;
      }
      
      // 重新加载用户资料、设置和统计信息
      await Promise.all([
        this.loadCurrentUserProfile(),
        this.loadUserSettings(),
        this.loadUserStatistics()
      ]);
      
      this.logger.debug('User data synchronized');
    } catch (error) {
      this.logger.warn('Failed to synchronize user data', error as Error);
    }
  }

  /**
   * 记录用户活动
   * @param activity 活动信息
   */
  private async logUserActivity(activity: UserActivity): Promise<void> {
    try {
      if (!this.isLoggedIn()) {
        return;
      }
      
      // 发布用户活动事件
      this.eventBus.emit(UserEventType.USER_ACTIVITY_LOGGED, {
        userId: this.currentUser!.id,
        activity,
        timestamp: Date.now()
      } as UserActivityEvent);
      
      // 异步发送到服务器
      this.networkUtil.post(
        `${this.apiEndpoints.baseUrl}${this.apiEndpoints.userActivity}`,
        {
          ...activity,
          timestamp: Date.now()
        },
        {
          headers: {
            'Authorization': `Bearer ${this.authToken}`
          }
        }
      ).catch(error => {
        this.logger.warn('Failed to send user activity to server', error as Error);
      });
    } catch (error) {
      this.logger.warn('Failed to log user activity', error as Error);
    }
  }

  /**
   * 验证注册请求
   */
  private validateRegisterRequest(request: RegisterRequest): void {
    const errors: string[] = [];
    
    if (!request.username || request.username.trim().length < 3) {
      errors.push('Username must be at least 3 characters long');
    }
    
    if (!request.email || !this.isValidEmail(request.email)) {
      errors.push('Invalid email address');
    }
    
    if (!request.password || request.password.length < 6) {
      errors.push('Password must be at least 6 characters long');
    }
    
    if (request.password !== request.confirmPassword) {
      errors.push('Passwords do not match');
    }
    
    if (errors.length > 0) {
      throw new Error(errors.join(', '));
    }
  }

  /**
   * 验证登录请求
   */
  private validateLoginRequest(request: LoginRequest): void {
    const errors: string[] = [];
    
    if (!request.usernameOrEmail) {
      errors.push('Username or email is required');
    }
    
    if (!request.password) {
      errors.push('Password is required');
    }
    
    if (errors.length > 0) {
      throw new Error(errors.join(', '));
    }
  }

  /**
   * 简单的邮箱格式验证
   */
  private isValidEmail(email: string): boolean {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  }

  /**
   * 清理用户信息，移除敏感数据
   */
  private sanitizeUserInfo(userInfo: UserInfo): UserInfo {
    const sanitized = { ...userInfo };
    
    // 移除敏感信息（如果有）
    if (sanitized) {
        delete (sanitized as Record<string, unknown>).password;
        delete (sanitized as Record<string, unknown>).resetToken;
        delete (sanitized as Record<string, unknown>).verificationToken;
    }
    
    return sanitized;
  }
}

// 导出默认实例
export default UserRepository.getInstance();