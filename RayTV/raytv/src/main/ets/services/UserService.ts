// UserService - 用户服务类
// 负责管理用户相关的业务逻辑，包括用户注册、登录、信息管理、权限控制等

import Logger from '../common/util/Logger';
import { EventBusUtil } from '../utils/EventBusUtil';
import { StorageUtil } from '../utils/StorageUtil';
import { NetworkUtil } from '../utils/NetworkUtil';
import { ValidatorUtil } from '../utils/ValidatorUtil';
import { ConfigRepository } from '../data/repository/ConfigRepository';
import { LocalStorageType } from '../data/model/LocalModel';
import { UserRole, UserStatus } from '../data/model/DatabaseModel';

/**
 * 用户信息接口
 */
export interface UserInfo {
  id: string;                  // 用户ID
  username: string;            // 用户名
  email: string;               // 邮箱
  phone?: string;              // 手机号（可选）
  nickname?: string;           // 昵称（可选）
  avatar?: string;             // 头像URL（可选）
  role: UserRole;              // 用户角色
  status: UserStatus;          // 用户状态
  createdAt: number;           // 创建时间戳
  updatedAt: number;           // 更新时间戳
  lastLoginAt?: number;        // 最后登录时间戳（可选）
  settings?: UserSettings;     // 用户设置（可选）
  profile?: UserProfile;       // 用户资料（可选）
  statistics?: UserStatistics; // 用户统计信息（可选）
}

/**
 * 用户设置接口
 */
export interface UserSettings {
  language: string;            // 语言偏好
  theme: 'light' | 'dark' | 'system'; // 主题设置
  notifications: {
    push: boolean;             // 推送通知
    email: boolean;            // 邮件通知
    sms: boolean;              // 短信通知
  };
  playback: {
    defaultQuality: string;    // 默认播放质量
    autoPlay: boolean;         // 自动播放
    rememberPosition: boolean; // 记住播放位置
  };
  interface: {
    fontSize: 'small' | 'medium' | 'large'; // 字体大小
    layout: string;            // 布局设置
  };
}

/**
 * 用户资料接口
 */
export interface UserProfile {
  bio?: string;                // 个人简介（可选）
  location?: string;           // 位置（可选）
  website?: string;            // 个人网站（可选）
  socialLinks?: {
    twitter?: string;          // Twitter链接（可选）
    facebook?: string;         // Facebook链接（可选）
    instagram?: string;        // Instagram链接（可选）
    youtube?: string;          // YouTube链接（可选）
  };
  birthday?: number;           // 生日时间戳（可选）
  gender?: 'male' | 'female' | 'other'; // 性别（可选）
  interests?: string[];        // 兴趣爱好（可选）
}

/**
 * 用户统计信息接口
 */
export interface UserStatistics {
  watchTime: number;           // 观看时长（秒）
  streamsWatched: number;      // 观看的直播流数量
  favoritesCount: number;      // 收藏数量
  downloadsCount: number;      // 下载数量
  commentsCount: number;       // 评论数量
  loginCount: number;          // 登录次数
  level?: number;              // 用户等级（可选）
  points?: number;             // 用户积分（可选）
  badges?: UserBadge[];        // 用户徽章（可选）
}

/**
 * 用户徽章接口
 */
export interface UserBadge {
  id: string;                  // 徽章ID
  name: string;                // 徽章名称
  description: string;         // 徽章描述
  icon: string;                // 徽章图标URL
  earnedAt: number;            // 获取时间戳
}

/**
 * 注册请求接口
 */
export interface RegisterRequest {
  username: string;            // 用户名
  email: string;               // 邮箱
  password: string;            // 密码
  phone?: string;              // 手机号（可选）
  nickname?: string;           // 昵称（可选）
  agreeTerms: boolean;         // 同意服务条款
}

/**
 * 登录请求接口
 */
export interface LoginRequest {
  email: string;               // 邮箱或用户名
  password: string;            // 密码
  rememberMe: boolean;         // 记住我
  deviceInfo?: DeviceInfo;     // 设备信息（可选）
}

/**
 * 设备信息接口
 */
export interface DeviceInfo {
  deviceId: string;            // 设备ID
  deviceName: string;          // 设备名称
  deviceType: string;          // 设备类型
  osVersion: string;           // 操作系统版本
  appVersion: string;          // 应用版本
  ipAddress?: string;          // IP地址（可选）
}

/**
 * 认证信息接口
 */
export interface AuthInfo {
  accessToken: string;         // 访问令牌
  refreshToken: string;        // 刷新令牌
  expiresIn: number;           // 过期时间（秒）
  tokenType: string;           // 令牌类型
  userId: string;              // 用户ID
}

/**
 * 密码重置请求接口
 */
export interface PasswordResetRequest {
  email: string;               // 邮箱
}

/**
 * 密码更新请求接口
 */
export interface PasswordUpdateRequest {
  oldPassword: string;         // 旧密码
  newPassword: string;         // 新密码
  confirmPassword: string;     // 确认新密码
}

/**
 * 用户服务类
 */
export class UserService {
  private static instance: UserService;
  private logger = Logger.getInstance();
  private eventBus = EventBusUtil.getInstance();
  private storageUtil = StorageUtil.getInstance();
  private networkUtil = NetworkUtil.getInstance();
  private validatorUtil = ValidatorUtil.getInstance();
  private configRepository = ConfigRepository.getInstance();
  
  // 当前登录用户
  private currentUser: UserInfo | null = null;
  // 认证信息
  private authInfo: AuthInfo | null = null;
  // 是否正在刷新令牌
  private isRefreshingToken: boolean = false;
  // 令牌刷新队列
  private tokenRefreshQueue: ((error?: Error) => void)[] = [];
  // 设备信息
  private deviceInfo: DeviceInfo | null = null;

  /**
   * 私有构造函数
   */
  private constructor() {
    this.logger.info('UserService initialized');
    this.initialize();
  }

  /**
   * 获取UserService单例实例
   */
  public static getInstance(): UserService {
    if (!UserService.instance) {
      UserService.instance = new UserService();
    }
    return UserService.instance;
  }

  /**
   * 初始化服务
   */
  private async initialize(): Promise<void> {
    try {
      // 加载保存的认证信息
      await this.loadAuthInfo();
      
      // 初始化设备信息
      this.initializeDeviceInfo();
      
      // 设置事件监听
      this.setupEventListeners();
      
      // 如果有保存的认证信息，尝试自动登录
      if (this.authInfo) {
        await this.validateAndRefreshToken();
      }
      
      this.logger.info('UserService initialized successfully');
    } catch (error) {
      this.logger.error('Failed to initialize UserService', error as Error);
    }
  }

  /**
   * 设置事件监听器
   */
  private setupEventListeners(): void {
    // 监听应用退出事件
    this.eventBus.on(GlobalEventType.APP_EXIT, () => {
      this.handleAppExit();
    });
    
    // 监听网络状态变化
    this.eventBus.on(GlobalEventType.NETWORK_STATUS_CHANGE, (status) => {
      this.handleNetworkStatusChange(status);
    });
  }

  /**
   * 用户注册
   * @param request 注册请求
   */
  public async register(request: RegisterRequest): Promise<UserInfo> {
    try {
      this.logger.debug('Registering new user', { username: request.username, email: request.email });
      
      // 验证注册信息
      this.validateRegisterRequest(request);
      
      // 检查用户名是否已存在
      const usernameExists = await this.checkUsernameExists(request.username);
      if (usernameExists) {
        throw new Error('用户名已被使用');
      }
      
      // 检查邮箱是否已存在
      const emailExists = await this.checkEmailExists(request.email);
      if (emailExists) {
        throw new Error('邮箱已被注册');
      }
      
      // 调用API注册用户
      // 在实际应用中，这里应该调用真实的注册API
      const userInfo = await this.simulateRegister(request);
      
      // 发布用户注册事件
      this.eventBus.emit('user:registered', userInfo);
      
      this.logger.info(`User registered successfully: ${userInfo.username} (${userInfo.id})`);
      
      return userInfo;
    } catch (error) {
      this.logger.error('Failed to register user', error as Error);
      throw error;
    }
  }

  /**
   * 用户登录
   * @param request 登录请求
   */
  public async login(request: LoginRequest): Promise<{ user: UserInfo; auth: AuthInfo }> {
    try {
      this.logger.debug('User login attempt', { email: request.email, rememberMe: request.rememberMe });
      
      // 验证登录信息
      this.validateLoginRequest(request);
      
      // 准备登录数据，包括设备信息
      const loginData = {
        ...request,
        deviceInfo: request.deviceInfo || this.deviceInfo
      };
      
      // 调用API登录
      // 在实际应用中，这里应该调用真实的登录API
      const { user, auth } = await this.simulateLogin(loginData);
      
      // 保存认证信息
      this.authInfo = auth;
      this.currentUser = user;
      
      // 根据rememberMe决定存储类型
      const storageType = request.rememberMe ? LocalStorageType.PERSISTENT : LocalStorageType.TEMPORARY;
      await this.saveAuthInfo(auth, storageType);
      await this.saveUserInfo(user, storageType);
      
      // 更新最后登录时间
      await this.updateLastLoginTime(user.id);
      
      // 发布用户登录事件
      this.eventBus.emit(GlobalEventType.USER_LOGIN, user);
      
      this.logger.info(`User logged in successfully: ${user.username} (${user.id})`);
      
      return { user, auth };
    } catch (error) {
      this.logger.error('Failed to login user', error as Error);
      throw error;
    }
  }

  /**
   * 用户登出
   */
  public async logout(): Promise<void> {
    try {
      const userId = this.currentUser?.id;
      
      this.logger.debug('User logout attempt', { userId });
      
      // 如果有刷新令牌，调用API使令牌失效
      if (this.authInfo?.refreshToken) {
        try {
          // 在实际应用中，这里应该调用真实的登出API
          await this.simulateLogout(this.authInfo.refreshToken);
        } catch (error) {
          // 登出API失败不应该阻止本地登出过程
          this.logger.warn('Failed to call logout API', error as Error);
        }
      }
      
      // 清理本地数据
      this.currentUser = null;
      this.authInfo = null;
      
      // 移除存储的认证信息和用户信息
      await this.storageUtil.remove('auth_info', LocalStorageType.TEMPORARY);
      await this.storageUtil.remove('auth_info', LocalStorageType.PERSISTENT);
      await this.storageUtil.remove('user_info', LocalStorageType.TEMPORARY);
      await this.storageUtil.remove('user_info', LocalStorageType.PERSISTENT);
      
      // 清理令牌刷新队列
      this.clearTokenRefreshQueue();
      
      // 发布用户登出事件
      this.eventBus.emit(GlobalEventType.USER_LOGOUT, { userId });
      
      this.logger.info(`User logged out successfully: ${userId}`);
    } catch (error) {
      this.logger.error('Failed to logout user', error as Error);
      throw error;
    }
  }

  /**
   * 获取当前登录用户信息
   */
  public async getCurrentUser(): Promise<UserInfo | null> {
    // 如果没有当前用户，但有认证信息，尝试刷新用户信息
    if (!this.currentUser && this.authInfo) {
      try {
        await this.refreshCurrentUser();
      } catch (error) {
        this.logger.error('Failed to refresh current user', error as Error);
        // 刷新失败可能意味着令牌已失效，执行登出
        await this.logout();
      }
    }
    
    return this.currentUser;
  }

  /**
   * 更新用户信息
   * @param updates 更新的用户信息
   */
  public async updateUserInfo(updates: Partial<UserInfo>): Promise<UserInfo> {
    try {
      if (!this.currentUser || !this.authInfo) {
        throw new Error('用户未登录');
      }
      
      this.logger.debug('Updating user info', { userId: this.currentUser.id, updates });
      
      // 验证更新信息
      this.validateUserInfoUpdates(updates);
      
      // 调用API更新用户信息
      // 在实际应用中，这里应该调用真实的API
      const updatedUser = await this.simulateUpdateUser(this.currentUser.id, updates);
      
      // 更新本地用户信息
      this.currentUser = updatedUser;
      
      // 保存更新后的用户信息
      await this.saveUserInfo(updatedUser, LocalStorageType.PERSISTENT);
      
      // 发布用户信息更新事件
      this.eventBus.emit('user:infoUpdated', updatedUser);
      
      this.logger.info(`User info updated successfully: ${updatedUser.id}`);
      
      return updatedUser;
    } catch (error) {
      this.logger.error('Failed to update user info', error as Error);
      throw error;
    }
  }

  /**
   * 更新用户设置
   * @param settings 用户设置
   */
  public async updateUserSettings(settings: Partial<UserSettings>): Promise<UserSettings> {
    try {
      if (!this.currentUser || !this.authInfo) {
        throw new Error('用户未登录');
      }
      
      this.logger.debug('Updating user settings', { userId: this.currentUser.id });
      
      // 合并设置
      const currentSettings = this.currentUser.settings || this.getDefaultUserSettings();
      const updatedSettings = { ...currentSettings, ...settings };
      
      // 调用API更新设置
      // 在实际应用中，这里应该调用真实的API
      const savedSettings = await this.simulateUpdateSettings(this.currentUser.id, updatedSettings);
      
      // 更新本地用户设置
      this.currentUser.settings = savedSettings;
      
      // 保存更新后的用户信息
      await this.saveUserInfo(this.currentUser, LocalStorageType.PERSISTENT);
      
      // 更新配置仓库
      await this.configRepository.setConfig('user_settings', savedSettings);
      
      // 发布设置更新事件
      this.eventBus.emit('user:settingsUpdated', savedSettings);
      
      this.logger.info(`User settings updated successfully: ${this.currentUser.id}`);
      
      return savedSettings;
    } catch (error) {
      this.logger.error('Failed to update user settings', error as Error);
      throw error;
    }
  }

  /**
   * 更新用户密码
   * @param request 密码更新请求
   */
  public async updatePassword(request: PasswordUpdateRequest): Promise<void> {
    try {
      if (!this.currentUser || !this.authInfo) {
        throw new Error('用户未登录');
      }
      
      this.logger.debug('Updating user password', { userId: this.currentUser.id });
      
      // 验证密码更新请求
      this.validatePasswordUpdateRequest(request);
      
      // 调用API更新密码
      // 在实际应用中，这里应该调用真实的API
      await this.simulateUpdatePassword(this.currentUser.id, request);
      
      // 发布密码更新事件
      this.eventBus.emit('user:passwordUpdated', { userId: this.currentUser.id });
      
      // 注意：密码更新后，可能需要重新登录或刷新令牌
      // 这里简单处理，不做额外操作
      
      this.logger.info(`User password updated successfully: ${this.currentUser.id}`);
    } catch (error) {
      this.logger.error('Failed to update user password', error as Error);
      throw error;
    }
  }

  /**
   * 发送密码重置邮件
   * @param email 用户邮箱
   */
  public async requestPasswordReset(email: string): Promise<void> {
    try {
      this.logger.debug('Requesting password reset', { email });
      
      // 验证邮箱
      if (!this.validatorUtil.isValidEmail(email)) {
        throw new Error('无效的邮箱地址');
      }
      
      // 调用API发送重置邮件
      // 在实际应用中，这里应该调用真实的API
      await this.simulatePasswordResetRequest(email);
      
      // 发布密码重置请求事件
      this.eventBus.emit('user:passwordResetRequested', { email });
      
      this.logger.info(`Password reset email sent to: ${email}`);
    } catch (error) {
      this.logger.error('Failed to request password reset', error as Error);
      throw error;
    }
  }

  /**
   * 验证用户是否已登录
   */
  public isLoggedIn(): boolean {
    return this.currentUser !== null && this.authInfo !== null;
  }

  /**
   * 检查用户权限
   * @param requiredRole 所需角色
   */
  public hasPermission(requiredRole: UserRole): boolean {
    if (!this.currentUser) {
      return false;
    }
    
    // 定义角色权限层次
    const roleHierarchy = {
      [UserRole.ADMIN]: 3,
      [UserRole.MODERATOR]: 2,
      [UserRole.PREMIUM]: 1,
      [UserRole.USER]: 0
    };
    
    const userRoleLevel = roleHierarchy[this.currentUser.role] || 0;
    const requiredRoleLevel = roleHierarchy[requiredRole] || 0;
    
    return userRoleLevel >= requiredRoleLevel;
  }

  /**
   * 获取用户统计信息
   */
  public async getUserStatistics(): Promise<UserStatistics | null> {
    try {
      if (!this.currentUser || !this.authInfo) {
        return null;
      }
      
      this.logger.debug('Getting user statistics', { userId: this.currentUser.id });
      
      // 调用API获取统计信息
      // 在实际应用中，这里应该调用真实的API
      const statistics = await this.simulateGetUserStatistics(this.currentUser.id);
      
      // 更新本地用户统计信息
      if (this.currentUser) {
        this.currentUser.statistics = statistics;
        await this.saveUserInfo(this.currentUser, LocalStorageType.PERSISTENT);
      }
      
      this.logger.info(`Retrieved user statistics for: ${this.currentUser.id}`);
      
      return statistics;
    } catch (error) {
      this.logger.error('Failed to get user statistics', error as Error);
      return null;
    }
  }

  /**
   * 刷新用户信息
   */
  public async refreshCurrentUser(): Promise<UserInfo> {
    try {
      if (!this.authInfo) {
        throw new Error('没有认证信息');
      }
      
      this.logger.debug('Refreshing current user info', { userId: this.authInfo.userId });
      
      // 调用API获取用户信息
      // 在实际应用中，这里应该调用真实的API
      const userInfo = await this.simulateGetUserInfo(this.authInfo.userId);
      
      // 更新本地用户信息
      this.currentUser = userInfo;
      
      // 保存更新后的用户信息
      await this.saveUserInfo(userInfo, LocalStorageType.PERSISTENT);
      
      this.logger.info(`Current user info refreshed: ${userInfo.id}`);
      
      return userInfo;
    } catch (error) {
      this.logger.error('Failed to refresh current user', error as Error);
      throw error;
    }
  }

  /**
   * 刷新访问令牌
   */
  public async refreshToken(): Promise<AuthInfo> {
    // 如果已经在刷新中，加入队列等待
    if (this.isRefreshingToken) {
      return new Promise((resolve, reject) => {
        this.tokenRefreshQueue.push((error?: Error) => {
          if (error) {
            reject(error);
          } else if (this.authInfo) {
            resolve(this.authInfo);
          } else {
            reject(new Error('Token refresh failed'));
          }
        });
      });
    }
    
    try {
      if (!this.authInfo?.refreshToken) {
        throw new Error('没有刷新令牌');
      }
      
      this.logger.debug('Refreshing access token', { userId: this.authInfo.userId });
      
      // 标记正在刷新
      this.isRefreshingToken = true;
      
      // 调用API刷新令牌
      // 在实际应用中，这里应该调用真实的API
      const newAuthInfo = await this.simulateRefreshToken(this.authInfo.refreshToken);
      
      // 更新认证信息
      this.authInfo = newAuthInfo;
      
      // 保存更新后的认证信息
      await this.saveAuthInfo(newAuthInfo, LocalStorageType.PERSISTENT);
      
      this.logger.info(`Access token refreshed successfully for user: ${newAuthInfo.userId}`);
      
      // 通知队列中的回调
      this.resolveTokenRefreshQueue();
      
      return newAuthInfo;
    } catch (error) {
      this.logger.error('Failed to refresh access token', error as Error);
      
      // 通知队列中的回调失败
      this.rejectTokenRefreshQueue(error as Error);
      
      // 刷新失败，执行登出
      await this.logout();
      
      throw error;
    } finally {
      // 重置刷新状态
      this.isRefreshingToken = false;
    }
  }

  // 私有辅助方法

  /**
   * 初始化设备信息
   */
  private initializeDeviceInfo(): void {
    // 在实际应用中，这里应该获取真实的设备信息
    this.deviceInfo = {
      deviceId: `device_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      deviceName: 'TV Device',
      deviceType: 'tv',
      osVersion: 'HarmonyOS 2.0',
      appVersion: '1.0.0'
    };
    
    this.logger.debug('Device info initialized', this.deviceInfo);
  }

  /**
   * 加载认证信息
   */
  private async loadAuthInfo(): Promise<void> {
    try {
      // 尝试从临时存储加载（会话级）
      let authInfo = await this.storageUtil.get<AuthInfo>('auth_info', LocalStorageType.TEMPORARY);
      let userInfo = await this.storageUtil.get<UserInfo>('user_info', LocalStorageType.TEMPORARY);
      
      // 如果临时存储没有，尝试从持久化存储加载
      if (!authInfo) {
        authInfo = await this.storageUtil.get<AuthInfo>('auth_info', LocalStorageType.PERSISTENT);
      }
      
      if (!userInfo) {
        userInfo = await this.storageUtil.get<UserInfo>('user_info', LocalStorageType.PERSISTENT);
      }
      
      if (authInfo && userInfo) {
        this.authInfo = authInfo;
        this.currentUser = userInfo;
        
        this.logger.info(`Loaded saved auth info for user: ${userInfo.username} (${userInfo.id})`);
      }
    } catch (error) {
      this.logger.error('Failed to load auth info', error as Error);
      // 清理可能损坏的数据
      this.clearStoredAuthData();
    }
  }

  /**
   * 保存认证信息
   */
  private async saveAuthInfo(authInfo: AuthInfo, storageType: LocalStorageType): Promise<void> {
    try {
      await this.storageUtil.set('auth_info', authInfo, storageType);
      this.logger.debug('Auth info saved successfully');
    } catch (error) {
      this.logger.error('Failed to save auth info', error as Error);
    }
  }

  /**
   * 保存用户信息
   */
  private async saveUserInfo(userInfo: UserInfo, storageType: LocalStorageType): Promise<void> {
    try {
      await this.storageUtil.set('user_info', userInfo, storageType);
      this.logger.debug('User info saved successfully');
    } catch (error) {
      this.logger.error('Failed to save user info', error as Error);
    }
  }

  /**
   * 清理存储的认证数据
   */
  private async clearStoredAuthData(): Promise<void> {
    try {
      await this.storageUtil.remove('auth_info', LocalStorageType.TEMPORARY);
      await this.storageUtil.remove('auth_info', LocalStorageType.PERSISTENT);
      await this.storageUtil.remove('user_info', LocalStorageType.TEMPORARY);
      await this.storageUtil.remove('user_info', LocalStorageType.PERSISTENT);
    } catch (error) {
      this.logger.error('Failed to clear stored auth data', error as Error);
    }
  }

  /**
   * 验证并刷新令牌
   */
  private async validateAndRefreshToken(): Promise<void> {
    if (!this.authInfo) {
      return;
    }
    
    // 检查令牌是否即将过期（例如，在5分钟内）
    const expiresIn = this.authInfo.expiresIn;
    const timeSinceCreation = (Date.now() - (this.authInfo.expiresIn * 1000)) / 1000;
    const timeRemaining = expiresIn - timeSinceCreation;
    
    if (timeRemaining < 300) { // 5分钟
      try {
        await this.refreshToken();
      } catch (error) {
        this.logger.error('Failed to refresh token during validation', error as Error);
        await this.logout();
      }
    }
  }

  /**
   * 清除令牌刷新队列
   */
  private clearTokenRefreshQueue(): void {
    this.tokenRefreshQueue.forEach(callback => callback(new Error('Session terminated')));
    this.tokenRefreshQueue = [];
  }

  /**
   * 解析令牌刷新队列
   */
  private resolveTokenRefreshQueue(): void {
    this.tokenRefreshQueue.forEach(callback => callback());
    this.tokenRefreshQueue = [];
  }

  /**
   * 拒绝令牌刷新队列
   */
  private rejectTokenRefreshQueue(error: Error): void {
    this.tokenRefreshQueue.forEach(callback => callback(error));
    this.tokenRefreshQueue = [];
  }

  /**
   * 更新最后登录时间
   */
  private async updateLastLoginTime(userId: string): Promise<void> {
    try {
      // 在实际应用中，这里应该调用API更新最后登录时间
      if (this.currentUser) {
        this.currentUser.lastLoginAt = Date.now();
        await this.saveUserInfo(this.currentUser, LocalStorageType.PERSISTENT);
      }
    } catch (error) {
      this.logger.error('Failed to update last login time', error as Error);
    }
  }

  /**
   * 处理应用退出
   */
  private async handleAppExit(): Promise<void> {
    this.logger.debug('Handling app exit');
    
    // 这里可以添加应用退出时的清理逻辑
    // 例如，保存用户状态等
  }

  /**
   * 处理网络状态变化
   */
  private handleNetworkStatusChange(status: any): void {
    this.logger.debug('Network status changed during user session', status);
    
    // 这里可以根据网络状态调整用户相关功能
  }

  // 验证方法

  /**
   * 验证注册请求
   */
  private validateRegisterRequest(request: RegisterRequest): void {
    // 验证用户名
    if (!request.username || request.username.length < 3 || request.username.length > 20) {
      throw new Error('用户名长度必须在3-20个字符之间');
    }
    
    if (!/^[a-zA-Z0-9_\u4e00-\u9fa5]+$/.test(request.username)) {
      throw new Error('用户名只能包含字母、数字、下划线和中文');
    }
    
    // 验证邮箱
    if (!this.validatorUtil.isValidEmail(request.email)) {
      throw new Error('无效的邮箱地址');
    }
    
    // 验证密码
    if (!this.validatorUtil.isValidPassword(request.password)) {
      throw new Error('密码必须包含至少8个字符，包括字母和数字');
    }
    
    // 验证手机号（如果提供）
    if (request.phone && !this.validatorUtil.isValidPhone(request.phone)) {
      throw new Error('无效的手机号');
    }
    
    // 验证服务条款
    if (!request.agreeTerms) {
      throw new Error('必须同意服务条款');
    }
  }

  /**
   * 验证登录请求
   */
  private validateLoginRequest(request: LoginRequest): void {
    // 验证邮箱/用户名不为空
    if (!request.email) {
      throw new Error('请输入邮箱或用户名');
    }
    
    // 验证密码不为空
    if (!request.password) {
      throw new Error('请输入密码');
    }
  }

  /**
   * 验证用户信息更新
   */
  private validateUserInfoUpdates(updates: Partial<UserInfo>): void {
    // 验证邮箱（如果更新）
    if (updates.email && !this.validatorUtil.isValidEmail(updates.email)) {
      throw new Error('无效的邮箱地址');
    }
    
    // 验证手机号（如果更新）
    if (updates.phone && !this.validatorUtil.isValidPhone(updates.phone)) {
      throw new Error('无效的手机号');
    }
    
    // 验证昵称（如果更新）
    if (updates.nickname && (updates.nickname.length < 1 || updates.nickname.length > 30)) {
      throw new Error('昵称长度必须在1-30个字符之间');
    }
  }

  /**
   * 验证密码更新请求
   */
  private validatePasswordUpdateRequest(request: PasswordUpdateRequest): void {
    // 验证旧密码不为空
    if (!request.oldPassword) {
      throw new Error('请输入旧密码');
    }
    
    // 验证新密码
    if (!this.validatorUtil.isValidPassword(request.newPassword)) {
      throw new Error('密码必须包含至少8个字符，包括字母和数字');
    }
    
    // 验证确认密码
    if (request.newPassword !== request.confirmPassword) {
      throw new Error('两次输入的密码不一致');
    }
  }

  /**
   * 获取默认用户设置
   */
  private getDefaultUserSettings(): UserSettings {
    return {
      language: 'zh-CN',
      theme: 'system',
      notifications: {
        push: true,
        email: false,
        sms: false
      },
      playback: {
        defaultQuality: 'high',
        autoPlay: true,
        rememberPosition: true
      },
      interface: {
        fontSize: 'medium',
        layout: 'default'
      }
    };
  }

  // 模拟方法

  /**
   * 模拟检查用户名是否存在
   */
  private async checkUsernameExists(username: string): Promise<boolean> {
    // 模拟API调用，这里简单返回false（假设用户名可用）
    return false;
  }

  /**
   * 模拟检查邮箱是否存在
   */
  private async checkEmailExists(email: string): Promise<boolean> {
    // 模拟API调用，这里简单返回false（假设邮箱可用）
    return false;
  }

  /**
   * 模拟注册
   */
  private async simulateRegister(request: RegisterRequest): Promise<UserInfo> {
    // 模拟API调用延迟
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    // 创建模拟用户信息
    const userInfo: UserInfo = {
      id: `user_${Date.now()}`,
      username: request.username,
      email: request.email,
      phone: request.phone,
      nickname: request.nickname || request.username,
      role: UserRole.USER,
      status: UserStatus.ACTIVE,
      createdAt: Date.now(),
      updatedAt: Date.now(),
      settings: this.getDefaultUserSettings(),
      statistics: {
        watchTime: 0,
        streamsWatched: 0,
        favoritesCount: 0,
        downloadsCount: 0,
        commentsCount: 0,
        loginCount: 0
      }
    };
    
    return userInfo;
  }

  /**
   * 模拟登录
   */
  private async simulateLogin(request: LoginRequest): Promise<{ user: UserInfo; auth: AuthInfo }> {
    // 模拟API调用延迟
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    // 模拟登录验证
    // 在实际应用中，这里应该验证真实的用户凭据
    
    // 创建模拟用户信息
    const user: UserInfo = {
      id: 'user_123456',
      username: 'testuser',
      email: request.email,
      nickname: '测试用户',
      avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=testuser',
      role: UserRole.USER,
      status: UserStatus.ACTIVE,
      createdAt: Date.now() - 86400000 * 7, // 7天前
      updatedAt: Date.now(),
      lastLoginAt: Date.now(),
      settings: this.getDefaultUserSettings(),
      statistics: {
        watchTime: 3600,
        streamsWatched: 12,
        favoritesCount: 5,
        downloadsCount: 2,
        commentsCount: 3,
        loginCount: 15
      }
    };
    
    // 创建模拟认证信息
    const auth: AuthInfo = {
      accessToken: `access_token_${Date.now()}_${Math.random().toString(36).substr(2, 10)}`,
      refreshToken: `refresh_token_${Date.now()}_${Math.random().toString(36).substr(2, 10)}`,
      expiresIn: 3600, // 1小时
      tokenType: 'Bearer',
      userId: user.id
    };
    
    return { user, auth };
  }

  /**
   * 模拟登出
   */
  private async simulateLogout(refreshToken: string): Promise<void> {
    // 模拟API调用延迟
    await new Promise(resolve => setTimeout(resolve, 500));
    
    // 模拟登出操作
    this.logger.debug('Simulated logout API call', { refreshToken });
  }

  /**
   * 模拟更新用户信息
   */
  private async simulateUpdateUser(userId: string, updates: Partial<UserInfo>): Promise<UserInfo> {
    // 模拟API调用延迟
    await new Promise(resolve => setTimeout(resolve, 800));
    
    // 如果有当前用户，基于当前用户信息更新
    if (this.currentUser && this.currentUser.id === userId) {
      return {
        ...this.currentUser,
        ...updates,
        updatedAt: Date.now()
      };
    }
    
    // 否则创建一个模拟的更新后的用户
    return {
      id: userId,
      username: updates.username || 'testuser',
      email: updates.email || 'test@example.com',
      nickname: updates.nickname || '测试用户',
      role: UserRole.USER,
      status: UserStatus.ACTIVE,
      createdAt: Date.now() - 86400000 * 7,
      updatedAt: Date.now(),
      settings: this.getDefaultUserSettings(),
      ...updates
    };
  }

  /**
   * 模拟更新用户设置
   */
  private async simulateUpdateSettings(userId: string, settings: UserSettings): Promise<UserSettings> {
    // 模拟API调用延迟
    await new Promise(resolve => setTimeout(resolve, 500));
    
    // 直接返回设置（模拟成功保存）
    return settings;
  }

  /**
   * 模拟更新密码
   */
  private async simulateUpdatePassword(userId: string, request: PasswordUpdateRequest): Promise<void> {
    // 模拟API调用延迟
    await new Promise(resolve => setTimeout(resolve, 800));
    
    // 模拟密码验证
    // 在实际应用中，这里应该验证旧密码是否正确
    
    if (request.oldPassword === 'wrong_old_password') {
      throw new Error('旧密码不正确');
    }
  }

  /**
   * 模拟密码重置请求
   */
  private async simulatePasswordResetRequest(email: string): Promise<void> {
    // 模拟API调用延迟
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    // 模拟发送邮件
    this.logger.debug('Simulated password reset email sent', { email });
  }

  /**
   * 模拟获取用户统计信息
   */
  private async simulateGetUserStatistics(userId: string): Promise<UserStatistics> {
    // 模拟API调用延迟
    await new Promise(resolve => setTimeout(resolve, 600));
    
    // 返回模拟的统计数据
    return {
      watchTime: Math.floor(Math.random() * 3600 * 10), // 0-10小时
      streamsWatched: Math.floor(Math.random() * 100),
      favoritesCount: Math.floor(Math.random() * 50),
      downloadsCount: Math.floor(Math.random() * 20),
      commentsCount: Math.floor(Math.random() * 30),
      loginCount: Math.floor(Math.random() * 100),
      level: Math.floor(Math.random() * 10) + 1,
      points: Math.floor(Math.random() * 1000),
      badges: []
    };
  }

  /**
   * 模拟获取用户信息
   */
  private async simulateGetUserInfo(userId: string): Promise<UserInfo> {
    // 模拟API调用延迟
    await new Promise(resolve => setTimeout(resolve, 800));
    
    // 返回模拟的用户信息
    return {
      id: userId,
      username: 'testuser',
      email: 'test@example.com',
      nickname: '测试用户',
      avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=testuser',
      role: UserRole.USER,
      status: UserStatus.ACTIVE,
      createdAt: Date.now() - 86400000 * 7,
      updatedAt: Date.now(),
      lastLoginAt: Date.now() - 3600000,
      settings: this.getDefaultUserSettings(),
      statistics: {
        watchTime: 3600,
        streamsWatched: 12,
        favoritesCount: 5,
        downloadsCount: 2,
        commentsCount: 3,
        loginCount: 15
      }
    };
  }

  /**
   * 模拟刷新令牌
   */
  private async simulateRefreshToken(refreshToken: string): Promise<AuthInfo> {
    // 模拟API调用延迟
    await new Promise(resolve => setTimeout(resolve, 800));
    
    // 创建新的令牌信息
    return {
      accessToken: `access_token_${Date.now()}_${Math.random().toString(36).substr(2, 10)}`,
      refreshToken: refreshToken, // 在实际应用中，可能会生成新的刷新令牌
      expiresIn: 3600,
      tokenType: 'Bearer',
      userId: this.authInfo?.userId || 'user_123456'
    };
  }
}

// 导出默认实例
export default UserService.getInstance();