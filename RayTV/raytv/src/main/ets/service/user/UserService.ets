// UserService.ets - 用户服务
// 用户服务�?// 负责处理用户认证、用户信息管理和用户数据同步
import Logger from '../../common/util/Logger';
import StorageUtil from '../../common/util/StorageUtil';
import DateUtil from '../../common/util/DateUtil';
import NetworkUtil from '../../common/util/NetworkUtil';
import ConfigService from '../config/ConfigService';
import DatabaseManager from '../../data/db/DatabaseManager';
import RepositoryFactory from '../../data/repository/RepositoryFactory';
import NetworkRepository from '../../data/repository/NetworkRepository';
import DatabaseRepository from '../../data/repository/DatabaseRepository';
import { BusinessError } from '@ohos.base';
import http from '@ohos.net.http';

// 常量定义
const TAG = 'UserService';
const USER_DATA_KEY = 'user_data';
const AUTH_TOKEN_KEY = 'auth_token';
const USER_PREFERENCES_KEY = 'user_preferences';
const AUTO_LOGIN_KEY = 'auto_login_enabled';
const SESSION_EXPIRY_TIME = 7 * 24 * 60 * 60 * 1000; // 7�?
// 认证相关的API端点
const API_ENDPOINTS: Record<string, string | number | boolean | null> = { ... };

// 用户角色枚举
export enum UserRole {
  GUEST = 0,              // 访客
  REGISTERED = 1,         // 注册用户
  PREMIUM = 2,            // 高级用户
  ADMIN = 3               // 管理�?}

// 登录类型枚举
export enum LoginType {
  LOCAL = 0,              // 本地登录
  WECHAT = 1,             // 微信登录
  QQ = 2,                 // QQ登录
  PHONE = 3,              // 手机号登�?  EMAIL = 4               // 邮箱登录
}

// 认证状态枚�?export enum AuthStatus {
  UNAUTHENTICATED = 0,    // 未认�?  AUTHENTICATING = 1,     // 认证�?  AUTHENTICATED = 2,      // 已认�?  EXPIRED = 3,            // 认证过期
  ERROR = 4               // 认证错误
}

// 性别枚举
export enum Gender {
  MALE = 0,
  FEMALE = 1,
  OTHER = 2
}

// 用户状态枚�?export enum UserStatus {
  ACTIVE = 0,             // 活跃
  INACTIVE = 1,           // 非活�?  SUSPENDED = 2,          // 暂停
  BANNED = 3              // 封禁
}

// 用户接口
export interface User {
  id: string;             // 用户ID
  username: string;       // 用户�?  email?: string;         // 邮箱（可选）
  phone?: string;         // 手机号（可选）
  nickname: string;       // 昵称
  avatar?: string;        // 头像URL
  gender?: Gender;        // 性别
  birthday?: string;      // 生日
  location?: string;      // 所在地
  bio?: string;           // 个人简�?  role: UserRole;         // 用户角色
  status: UserStatus;     // 用户状�?  createdAt: number;      // 创建时间
  updatedAt: number;      // 更新时间
  lastLoginAt?: number;   // 最后登录时�?  loginCount: number;     // 登录次数
  preferences?: UserPreferences; // 用户偏好设置
  statistics?: UserStatistics;   // 用户统计信息
}

// 认证令牌接口
export interface AuthToken {
  accessToken: string;    // 访问令牌
  refreshToken: string;   // 刷新令牌
  tokenType: string;      // 令牌类型
  expiresIn: number;      // 过期时间（秒�?  issuedAt: number;       // 颁发时间
  scope?: string;         // 权限范围
  userId: string;         // 用户ID
}

// 用户偏好设置接口
export interface UserPreferences {
  theme: string;          // 主题设置
  language: string;       // 语言设置
  playQuality: string;    // 播放质量偏好
  subtitleEnabled: boolean; // 是否启用字幕
  subtitleLanguage: string; // 字幕语言
  autoPlay: boolean;      // 是否自动播放
  bandwidthSaver: boolean; // 是否启用流量节省
  parentalControlEnabled: boolean; // 是否启用家长控制
  parentalControlPin?: string; // 家长控制PIN�?  notificationEnabled: boolean; // 是否启用通知
  downloadQuality: string; // 下载质量偏好
  downloadWifiOnly: boolean; // 是否仅WiFi下载
}

// 用户统计信息接口
export interface UserStatistics {
  totalWatchTime: number; // 总观看时长（秒）
  watchedMovies: number;  // 已观看电影数
  favoriteMovies: number; // 收藏电影�?  downloadCount: number;  // 下载次数
  totalDownloadSize: number; // 总下载大小（字节�?  lastWatchDate?: number; // 最后观看时�?  mostWatchedGenre?: string; // 最常观看的类型
  currentStreak: number;  // 当前连续观看天数
  longestStreak: number;  // 最长连续观看天�?}

// 登录请求接口
export interface LoginRequest {
  username: string;       // 用户�?手机�?邮箱
  password?: string;      // 密码（如果是账号密码登录�?  code?: string;          // 验证码（如果是验证码登录�?  type: LoginType;        // 登录类型
  deviceId?: string;      // 设备ID
  deviceInfo?: DeviceInfo; // 设备信息
}

// 注册请求接口
export interface RegisterRequest {
  username: string;       // 用户�?  email?: string;         // 邮箱（可选）
  phone?: string;         // 手机号（可选）
  password: string;       // 密码
  confirmPassword: string; // 确认密码
  nickname?: string;      // 昵称（可选）
  agreeToTerms: boolean;  // 是否同意条款
  inviteCode?: string;    // 邀请码（可选）
}

// 设备信息接口
export interface DeviceInfo {
  deviceId: string;       // 设备ID
  deviceName: string;     // 设备名称
  deviceModel: string;    // 设备型号
  osVersion: string;      // 操作系统版本
  appVersion: string;     // 应用版本
  platform: string;       // 平台（HarmonyOS等）
  screenWidth: number;    // 屏幕宽度
  screenHeight: number;   // 屏幕高度
}

// 用户资料更新请求接口
export interface UpdateProfileRequest {
  nickname?: string;      // 昵称
  avatar?: string;        // 头像
  gender?: Gender;        // 性别
  birthday?: string;      // 生日
  location?: string;      // 所在地
  bio?: string;           // 个人简�?}

// 密码重置请求接口
export interface ResetPasswordRequest {
  oldPassword?: string;   // 旧密码（可选，如果是修改密码）
  newPassword: string;    // 新密�?  confirmPassword: string; // 确认新密�?  resetToken?: string;    // 重置令牌（如果是忘记密码�?}

// 认证响应接口
export interface AuthResponse {
  success: boolean;       // 是否成功
  user?: User;            // 用户信息
  token?: AuthToken;      // 认证令牌
  error?: string;         // 错误信息
  errorCode?: number;     // 错误�?}

// 默认用户偏好设置
const DEFAULT_USER_PREFERENCES: UserPreferences = {
  theme: 'dark',
  language: 'zh_CN',
  playQuality: 'auto',
  subtitleEnabled: true,
  subtitleLanguage: 'zh_CN',
  autoPlay: true,
  bandwidthSaver: false,
  parentalControlEnabled: false,
  notificationEnabled: true,
  downloadQuality: 'high',
  downloadWifiOnly: true
};

// 默认用户统计信息
const DEFAULT_USER_STATISTICS: UserStatistics = {
  totalWatchTime: 0,
  watchedMovies: 0,
  favoriteMovies: 0,
  downloadCount: 0,
  totalDownloadSize: 0,
  currentStreak: 0,
  longestStreak: 0
};

// 访客用户
const GUEST_USER: User = {
  id: 'guest',
  username: 'guest',
  nickname: '访客',
  role: UserRole.GUEST,
  status: UserStatus.ACTIVE,
  createdAt: Date.now(),
  updatedAt: Date.now(),
  loginCount: 0,
  preferences: DEFAULT_USER_PREFERENCES,
  statistics: DEFAULT_USER_STATISTICS
};

export default class UserService {
  private static instance: UserService;
  private configService: ConfigService;
  private databaseManager: DatabaseManager;
  private networkRepo: NetworkRepository;
  private databaseRepo: DatabaseRepository;
  private currentUser: User | null = null;
  private authToken: AuthToken | null = null;
  private authStatus: AuthStatus = AuthStatus.UNAUTHENTICATED;
  private autoLoginEnabled: boolean = false;
  private isInitialized: boolean = false;
  private loginAttempts: number = 0;
  private lastLoginAttempt: number = 0;
  private deviceInfo: DeviceInfo | null = null;
  private tokenRefreshTimer: number | null = null;
  
  // 监听�?  private userChangeListeners: Array<(user: User | null) => void> = [];
  private authStatusListeners: Array<(status: AuthStatus) => void> = [];
  private preferenceListeners: Array<(preferences: UserPreferences) => void> = [];
  private statisticsListeners: Array<(statistics: UserStatistics) => void> = [];

  /**
   * 获取单例实例
   */
  public static getInstance(): UserService {
    if (!UserService.instance) {
      UserService.instance = new UserService();
    }
    return UserService.instance;
  }

  /**
   * 构造函�?   */
  private constructor() {
    this.configService = ConfigService.getInstance();
    this.databaseManager = DatabaseManager.getInstance();
    this.networkRepo = RepositoryFactory.getRepository('network') as NetworkRepository;
    this.databaseRepo = RepositoryFactory.getRepository('database') as DatabaseRepository;
    this.initializeDeviceInfo();
  }
  
  /**
   * 初始化设备信�?   */
  private async initializeDeviceInfo(): Promise<void> {
    try {
      // 尝试从存储中获取设备ID
      let deviceId = await StorageUtil.getString('device_id');
      
      if (!deviceId) {
        // 生成新的设备ID
        deviceId = this.generateDeviceId();
        await StorageUtil.setString('device_id', deviceId);
      }

      // 构建设备信息
      this.deviceInfo = {
        deviceId,
        deviceName: this.getDeviceName(),
        deviceModel: this.getDeviceModel(),
        osVersion: this.getOSVersion(),
        appVersion: this.getAppVersion(),
        platform: this.getPlatform(),
        screenWidth: this.getScreenWidth(),
        screenHeight: this.getScreenHeight()
      };

      Logger.info(TAG, `Device initialized: ${JSON.stringify(this.deviceInfo)}`);
    } catch (error) {
      Logger.error(TAG, 'Failed to initialize device info', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
    }
  }
  
  /**
   * 生成设备ID
   */
  private generateDeviceId(): string {
    const timestamp = Date.now().toString(36);
    const random = Math.random().toString(36).substring(2, 11);
    return `device_${timestamp}_${random}`;
  }
  
  /**
   * 获取设备名称
   */
  private getDeviceName(): string {
    try {
      return 'HarmonyOS Device';
    } catch {
      return 'Unknown Device';
    }
  }
  
  /**
   * 获取设备型号
   */
  private getDeviceModel(): string {
    try {
      return 'HarmonyOS Model';
    } catch {
      return 'Unknown Model';
    }
  }
  
  /**
   * 获取操作系统版本
   */
  private getOSVersion(): string {
    try {
      return 'HarmonyOS 3.0';
    } catch {
      return 'Unknown OS';
    }
  }
  
  /**
   * 获取应用版本
   */
  private getAppVersion(): string {
    try {
      return '1.0.0';
    } catch {
      return 'Unknown Version';
    }
  }
  
  /**
   * 获取平台信息
   */
  private getPlatform(): string {
    return 'HarmonyOS';
  }
  
  /**
   * 获取屏幕宽度
   */
  private getScreenWidth(): number {
    try {
      return 1080;
    } catch {
      return 0;
    }
  }
  
  /**
   * 获取屏幕高度
   */
  private getScreenHeight(): number {
    try {
      return 1920;
    } catch {
      return 0;
    }
  }

  /**
   * 初始化用户服�?   */
  public async initialize(): Promise<void> {
    if (this.isInitialized) {
      Logger.info(TAG, 'User service already initialized');
      return;
    }

    try {
      Logger.info(TAG, 'Initializing user service...');
      
      // 加载自动登录设置
      this.autoLoginEnabled = await StorageUtil.getBoolean(AUTO_LOGIN_KEY, false);
      
      // 尝试恢复用户会话
      if (this.autoLoginEnabled) {
        await this.restoreSession();
      } else {
        // 如果未启用自动登录，使用访客模式
        this.setGuestMode();
      }
      
      this.isInitialized = true;
      Logger.info(TAG, 'User service initialized successfully');
    } catch (error) {
      Logger.error(TAG, `Failed to initialize user service: ${error}`);
      // 初始化失败时使用访客模式
      this.setGuestMode();
      this.isInitialized = true;
    }
  }
  
  /**
   * 设置令牌自动刷新
   */
  private setupTokenRefresh(): void {
    // 清除现有的定时器
    this.clearTokenRefreshTimer();
    
    if (!this.authToken) return;
    
    // 计算刷新时间（在令牌过期�?分钟�?    const refreshTime = (this.authToken.expiresIn * 1000) - (5 * 60 * 1000);
    
    if (refreshTime > 0) {
      this.tokenRefreshTimer = setTimeout(async () => {
        await this.refreshToken();
      }, refreshTime instanceof Error ? refreshTime : new Error(String(refreshTime instanceof Error ? refreshTime instanceof Error ? refreshTime : new Error(String(refreshTime : new Error(String(refreshTime instanceof Error ? refreshTime : new Error(String(refreshTime instanceof Error ? refreshTime instanceof Error ? refreshTime : new Error(String(refreshTime instanceof Error ? refreshTime instanceof Error ? refreshTime : new Error(String(refreshTime : new Error(String(refreshTime instanceof Error ? refreshTime : new Error(String(refreshTime : new Error(String(refreshTime instanceof Error ? refreshTime : new Error(String(refreshTime instanceof Error ? refreshTime instanceof Error ? refreshTime : new Error(String(refreshTime : new Error(String(refreshTime instanceof Error ? refreshTime : new Error(String(refreshTime)))))));
      
      Logger.info(TAG, `Token refresh scheduled in ${refreshTime}ms`);
    }
  }
  
  /**
   * 清除令牌刷新定时�?   */
  private clearTokenRefreshTimer(): void {
    if (this.tokenRefreshTimer) {
      clearTimeout(this.tokenRefreshTimer);
      this.tokenRefreshTimer = null;
    }
  }

  /**
   * 设置访客模式
   */
  private setGuestMode(): void {
    this.currentUser = GUEST_USER;
    this.authToken = null;
    this.authStatus = AuthStatus.UNAUTHENTICATED;
    this.notifyUserChanged();
    this.notifyAuthStatusChanged();
  }

  /**
   * 恢复用户会话
   */
  private async restoreSession(): Promise<boolean> {
    try {
      // 从存储中加载用户数据和令�?      const savedUser = await StorageUtil.getObject<User>(USER_DATA_KEY);
      const savedToken = await StorageUtil.getObject<AuthToken>(AUTH_TOKEN_KEY);
      
      if (savedUser && savedToken) {
        // 检查令牌是否过�?        const now = Date.now();
        const expiresAt = savedToken.issuedAt + (savedToken.expiresIn * 1000);
        
        if (now < expiresAt) {
          // 令牌有效，恢复用户会�?          this.currentUser = savedUser;
          this.authToken = savedToken;
          this.authStatus = AuthStatus.AUTHENTICATED;
          
          // 验证会话有效性（可选：向服务器验证�?          // const isValid = await this.validateSession();
          // if (!isValid) {
          //   this.logout();
          //   return false;
          // }
          
          this.notifyUserChanged();
          this.notifyAuthStatusChanged();
          
          Logger.info(TAG, 'Session restored successfully');
          return true;
        } else {
          // 令牌已过期，尝试刷新
          if (await this.refreshToken(savedToken.refreshToken)) {
            Logger.info(TAG, 'Session restored after token refresh');
            return true;
          }
        }
      }
      
      // 无法恢复会话，使用访客模�?      this.setGuestMode();
      return false;
    } catch (error) {
      Logger.error(TAG, `Failed to restore session: ${error}`);
      this.setGuestMode();
      return false;
    }
  }

  /**
   * 登录
   */
  public async login(request: LoginRequest): Promise<AuthResponse> {
    try {
      Logger.info(TAG, 'Attempting login...', { username: request.username } instanceof Error ? 'Attempting login...', { username: request.username } : new Error(String('Attempting login...', { username: request.username } instanceof Error ? 'Attempting login...', { username: request.username } instanceof Error ? 'Attempting login...', { username: request.username } : new Error(String('Attempting login...', { username: request.username } : new Error(String('Attempting login...', { username: request.username } instanceof Error ? 'Attempting login...', { username: request.username } : new Error(String('Attempting login...', { username: request.username } instanceof Error ? 'Attempting login...', { username: request.username } instanceof Error ? 'Attempting login...', { username: request.username } : new Error(String('Attempting login...', { username: request.username } instanceof Error ? 'Attempting login...', { username: request.username } instanceof Error ? 'Attempting login...', { username: request.username } : new Error(String('Attempting login...', { username: request.username } : new Error(String('Attempting login...', { username: request.username } instanceof Error ? 'Attempting login...', { username: request.username } : new Error(String('Attempting login...', { username: request.username } : new Error(String('Attempting login...', { username: request.username } instanceof Error ? 'Attempting login...', { username: request.username } : new Error(String('Attempting login...', { username: request.username } instanceof Error ? 'Attempting login...', { username: request.username } instanceof Error ? 'Attempting login...', { username: request.username } : new Error(String('Attempting login...', { username: request.username } : new Error(String('Attempting login...', { username: request.username } instanceof Error ? 'Attempting login...', { username: request.username } : new Error(String('Attempting login...', { username: request.username })))))));
      
      // 检查登录尝试频�?      if (!this.canAttemptLogin()) {
        return {
          success: false,
          error: '登录尝试过于频繁，请稍后再试',
          errorCode: 429
        };
      }
      
      // 更新登录尝试信息
      this.loginAttempts++;
      this.lastLoginAttempt = Date.now();
      
      // 设置认证状态为认证�?      this.authStatus = AuthStatus.AUTHENTICATING;
      this.notifyAuthStatusChanged();
      
      // 添加设备信息到登录请�?      const loginData: Record<string, string | number | boolean | null> = { ... };
      
      // 调用实际的登录API
      try {
        const apiResponse = await this.networkRepo.request<ApiResponse<AuthResponseData>>({
          url: API_ENDPOINTS.LOGIN,
          method: 'POST',
          data: loginData
        });
        
        if (apiResponse.isSuccess() && apiResponse.data) {
          const { user, token } = apiResponse.data;
          
          if (user && token) {
            // 直接使用API返回的用户数据，确保符合内部User接口
            const internalUser: User = {
              id: user.id,
              username: user.username,
              email: user.email,
              phone: user.phone,
              nickname: user.nickname,
              avatar: user.avatar,
              gender: user.gender,
              birthday: user.birthday,
              location: user.location,
              bio: user.bio,
              role: user.role,
              status: user.status,
              createdAt: user.createdAt,
              updatedAt: user.updatedAt,
              lastLoginAt: user.lastLoginAt,
              loginCount: user.loginCount,
              preferences: user.preferences,
              statistics: user.statistics
            };
            
            // 登录成功
            this.currentUser = internalUser;
            this.authToken = token;
            this.authStatus = AuthStatus.AUTHENTICATED;
            this.loginAttempts = 0;
            
            // 更新最后登录信�?            this.currentUser.lastLoginAt = Date.now();
            this.currentUser.loginCount++;
            this.currentUser.updatedAt = Date.now();
            
            // 保存用户数据和令�?            await this.saveUserData();
            await this.saveAuthToken();
            
            // 设置令牌自动刷新
            this.setupTokenRefresh();
            
            // 同步用户信息到本地数据库
            await this.syncUserInfo(user);
            
            // 通知监听�?            this.notifyUserChanged();
            this.notifyAuthStatusChanged();
            
            Logger.info(TAG, 'Login successful');
            return {
              success: true,
              user: this.currentUser,
              token: this.authToken
            };
          }
        }
        
        // 登录失败
        Logger.warn(TAG, `Login failed with status: ${apiResponse.code}`);
        this.authStatus = AuthStatus.UNAUTHENTICATED;
        this.notifyAuthStatusChanged();
        
        return {
          success: false,
          error: apiResponse.message || '登录失败，请检查用户名和密�?,
          errorCode: apiResponse.code || 401
        };
      } catch (apiError) {
        // API调用失败，使用模拟登录（开发环境）
        Logger.warn(TAG, 'API login failed, using mock login for development', apiError);
        
        // 模拟登录响应
        const response = await this.mockLoginResponse(request);
        
        if (response.success && response.user && response.token) {
          // 登录成功
          this.currentUser = response.user;
          this.authToken = response.token;
          this.authStatus = AuthStatus.AUTHENTICATED;
          this.loginAttempts = 0;
          
          // 更新最后登录信�?          this.currentUser.lastLoginAt = Date.now();
          this.currentUser.loginCount++;
          this.currentUser.updatedAt = Date.now();
          
          // 保存用户数据和令�?          await this.saveUserData();
          await this.saveAuthToken();
          
          // 设置令牌自动刷新
          this.setupTokenRefresh();
          
          // 同步用户数据
        await this.syncUserData();
        
        // 通知监听�?        this.notifyUserChanged();
        this.notifyAuthStatusChanged();
        
        Logger.info(TAG, `User logged in successfully: ${this.currentUser.username}`);
        return response;
      } else {
        // 登录失败
        this.authStatus = AuthStatus.ERROR;
        this.notifyAuthStatusChanged();
        
        Logger.error(TAG, `Login failed: ${response.error || 'Unknown error'}`);
        return response;
      }
    } catch (error) {
      Logger.error(TAG, `Login error: ${error}` instanceof Error ? `Login error: ${error}` : new Error(String(`Login error: ${error}` instanceof Error ? `Login error: ${error}` instanceof Error ? `Login error: ${error}` : new Error(String(`Login error: ${error}` : new Error(String(`Login error: ${error}` instanceof Error ? `Login error: ${error}` : new Error(String(`Login error: ${error}` instanceof Error ? `Login error: ${error}` instanceof Error ? `Login error: ${error}` : new Error(String(`Login error: ${error}` instanceof Error ? `Login error: ${error}` instanceof Error ? `Login error: ${error}` : new Error(String(`Login error: ${error}` : new Error(String(`Login error: ${error}` instanceof Error ? `Login error: ${error}` : new Error(String(`Login error: ${error}` : new Error(String(`Login error: ${error}` instanceof Error ? `Login error: ${error}` : new Error(String(`Login error: ${error}` instanceof Error ? `Login error: ${error}` instanceof Error ? `Login error: ${error}` : new Error(String(`Login error: ${error}` : new Error(String(`Login error: ${error}` instanceof Error ? `Login error: ${error}` : new Error(String(`Login error: ${error}`)))))));
      
      this.authStatus = AuthStatus.ERROR;
      this.notifyAuthStatusChanged();
      
      return {
        success: false,
        error: error instanceof Error ? error.message : '登录失败，请稍后再试',
        errorCode: 500
      };
    }
  }

  /**
   * 检查是否可以尝试登�?   */
  private canAttemptLogin(): boolean {
    // 限制登录尝试频率：每10分钟最�?次尝�?    const now = Date.now();
    const tenMinutesAgo = now - (10 * 60 * 1000);
    
    // 如果最后一次尝试是10分钟前，重置计数�?    if (this.lastLoginAttempt < tenMinutesAgo) {
      this.loginAttempts = 0;
    }
    
    return this.loginAttempts < 5;
  }

  /**
   * 模拟登录响应（用于演示）
   */
  private async mockLoginResponse(request: LoginRequest): Promise<AuthResponse> {
    // 模拟网络延迟
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    // 简单的验证逻辑
    if (request.type === LoginType.LOCAL && request.username === 'test' && request.password === '123456') {
      const user: User = {
        id: 'user_123',
        username: 'test',
        email: 'test@example.com',
        nickname: '测试用户',
        avatar: 'https://example.com/avatar.jpg',
        gender: Gender.MALE,
        role: UserRole.PREMIUM,
        status: UserStatus.ACTIVE,
        createdAt: Date.now() - 30 * 24 * 60 * 60 * 1000, // 30天前
        updatedAt: Date.now(),
        lastLoginAt: Date.now(),
        loginCount: 15,
        preferences: DEFAULT_USER_PREFERENCES,
        statistics: DEFAULT_USER_STATISTICS
      };
      
      const token: AuthToken = {
        accessToken: 'mock_access_token_' + Date.now(),
        refreshToken: 'mock_refresh_token_' + Date.now(),
        tokenType: 'Bearer',
        expiresIn: 24 * 60 * 60, // 24小时
        issuedAt: Date.now(),
        userId: user.id
      };
      
      return {
        success: true,
        user,
        token
      };
    }
    
    return {
      success: false,
      error: '用户名或密码错误',
      errorCode: 401
    };
  }

  /**
   * 执行实际的登录请求（待实现）
   */
  private async performLoginRequest(request: LoginRequest): Promise<AuthResponse> {
    // TODO: 实现实际的登录API调用
    throw new Error('Not implemented');
  }

  /**
   * 注册新用�?   */
  public async register(request: RegisterRequest): Promise<AuthResponse> {
    try {
      // 验证注册信息
      if (!request.username || request.username.length < 3) {
        return {
          success: false,
          error: '用户名长度至少为3个字�?,
          errorCode: 400
        };
      }
      
      if (!request.password || request.password.length < 6) {
        return {
          success: false,
          error: '密码长度至少�?个字�?,
          errorCode: 400
        };
      }
      
      if (request.password !== request.confirmPassword) {
        return {
          success: false,
          error: '两次输入的密码不一�?,
          errorCode: 400
        };
      }
      
      if (!request.agreeToTerms) {
        return {
          success: false,
          error: '请同意服务条款和隐私政策',
          errorCode: 400
        };
      }
      
      // 模拟注册请求
      // const response = await this.performRegisterRequest(request);
      
      // 模拟注册响应
      const response = await this.mockRegisterResponse(request);
      
      if (response.success && response.user && response.token) {
        // 注册成功，自动登�?        this.currentUser = response.user;
        this.authToken = response.token;
        this.authStatus = AuthStatus.AUTHENTICATED;
        
        // 保存用户数据和令�?        await this.saveUserData();
        await this.saveAuthToken();
        
        // 通知监听�?        this.notifyUserChanged();
        this.notifyAuthStatusChanged();
        
        Logger.info(TAG, `User registered successfully: ${this.currentUser.username}`);
        return response;
      } else {
        Logger.error(TAG, `Registration failed: ${response.error || 'Unknown error'}`);
        return response;
      }
    } catch (error) {
      Logger.error(TAG, `Registration error: ${error}` instanceof Error ? `Registration error: ${error}` : new Error(String(`Registration error: ${error}` instanceof Error ? `Registration error: ${error}` instanceof Error ? `Registration error: ${error}` : new Error(String(`Registration error: ${error}` : new Error(String(`Registration error: ${error}` instanceof Error ? `Registration error: ${error}` : new Error(String(`Registration error: ${error}` instanceof Error ? `Registration error: ${error}` instanceof Error ? `Registration error: ${error}` : new Error(String(`Registration error: ${error}` instanceof Error ? `Registration error: ${error}` instanceof Error ? `Registration error: ${error}` : new Error(String(`Registration error: ${error}` : new Error(String(`Registration error: ${error}` instanceof Error ? `Registration error: ${error}` : new Error(String(`Registration error: ${error}` : new Error(String(`Registration error: ${error}` instanceof Error ? `Registration error: ${error}` : new Error(String(`Registration error: ${error}` instanceof Error ? `Registration error: ${error}` instanceof Error ? `Registration error: ${error}` : new Error(String(`Registration error: ${error}` : new Error(String(`Registration error: ${error}` instanceof Error ? `Registration error: ${error}` : new Error(String(`Registration error: ${error}`)))))));
      return {
        success: false,
        error: error instanceof Error ? error.message : '注册失败，请稍后再试',
        errorCode: 500
      };
    }
  }

  /**
   * 模拟注册响应（用于演示）
   */
  private async mockRegisterResponse(request: RegisterRequest): Promise<AuthResponse> {
    // 模拟网络延迟
    await new Promise(resolve => setTimeout(resolve, 1500));
    
    // 检查用户名是否已存在（简单模拟）
    if (request.username === 'test') {
      return {
        success: false,
        error: '用户名已存在',
        errorCode: 409
      };
    }
    
    const user: User = {
      id: 'user_' + Date.now(),
      username: request.username,
      email: request.email,
      phone: request.phone,
      nickname: request.nickname || request.username,
      role: UserRole.REGISTERED,
      status: UserStatus.ACTIVE,
      createdAt: Date.now(),
      updatedAt: Date.now(),
      loginCount: 0,
      preferences: DEFAULT_USER_PREFERENCES,
      statistics: DEFAULT_USER_STATISTICS
    };
    
    const token: AuthToken = {
      accessToken: 'mock_access_token_' + Date.now(),
      refreshToken: 'mock_refresh_token_' + Date.now(),
      tokenType: 'Bearer',
      expiresIn: 24 * 60 * 60,
      issuedAt: Date.now(),
      userId: user.id
    };
    
    return {
      success: true,
      user,
      token
    };
  }

  /**
   * 登出
   */
  public async logout(): Promise<boolean> {
    try {
      Logger.info(TAG, 'User logging out');
      
      // 如果有令牌，调用登出API（可选）
      if (this.authToken) {
        // await this.performLogoutRequest();
      }
      
      // 清除用户数据和令�?      await this.clearUserData();
      
      // 重置状�?      this.setGuestMode();
      
      Logger.info(TAG, 'User logged out successfully');
      return true;
    } catch (error) {
      Logger.error(TAG, `Logout error: ${error}`);
      
      // 即使出错，也要清理本地数�?      await this.clearUserData();
      this.setGuestMode();
      
      return false;
    }
  }

  /**
   * 刷新令牌
   */
  public async refreshToken(refreshToken: string): Promise<boolean> {
    try {
      // 模拟刷新令牌请求
      // const response = await this.performRefreshTokenRequest(refreshToken);
      
      // 模拟刷新令牌成功
      await new Promise(resolve => setTimeout(resolve, 500 instanceof Error ? 500 : new Error(String(500 instanceof Error ? 500 instanceof Error ? 500 : new Error(String(500 : new Error(String(500 instanceof Error ? 500 : new Error(String(500 instanceof Error ? 500 instanceof Error ? 500 : new Error(String(500 instanceof Error ? 500 instanceof Error ? 500 : new Error(String(500 : new Error(String(500 instanceof Error ? 500 : new Error(String(500 : new Error(String(500 instanceof Error ? 500 : new Error(String(500 instanceof Error ? 500 instanceof Error ? 500 : new Error(String(500 : new Error(String(500 instanceof Error ? 500 : new Error(String(500))))))));
      
      if (this.currentUser) {
        const newToken: AuthToken = {
          accessToken: 'mock_access_token_' + Date.now(),
          refreshToken: 'mock_refresh_token_' + Date.now(),
          tokenType: 'Bearer',
          expiresIn: 24 * 60 * 60,
          issuedAt: Date.now(),
          userId: this.currentUser.id
        };
        
        this.authToken = newToken;
        await this.saveAuthToken();
        
        Logger.info(TAG, 'Token refreshed successfully');
        return true;
      }
      
      return false;
    } catch (error) {
      Logger.error(TAG, `Token refresh error: ${error}`);
      return false;
    }
  }

  /**
   * 保存用户数据
   */
  private async saveUserData(): Promise<void> {
    if (this.currentUser) {
      await StorageUtil.setObject(USER_DATA_KEY, this.currentUser instanceof Error ? this.currentUser : new Error(String(this.currentUser instanceof Error ? this.currentUser instanceof Error ? this.currentUser : new Error(String(this.currentUser : new Error(String(this.currentUser instanceof Error ? this.currentUser : new Error(String(this.currentUser instanceof Error ? this.currentUser instanceof Error ? this.currentUser : new Error(String(this.currentUser instanceof Error ? this.currentUser instanceof Error ? this.currentUser : new Error(String(this.currentUser : new Error(String(this.currentUser instanceof Error ? this.currentUser : new Error(String(this.currentUser : new Error(String(this.currentUser instanceof Error ? this.currentUser : new Error(String(this.currentUser instanceof Error ? this.currentUser instanceof Error ? this.currentUser : new Error(String(this.currentUser : new Error(String(this.currentUser instanceof Error ? this.currentUser : new Error(String(this.currentUser)))))));
    }
  }

  /**
   * 保存认证令牌
   */
  private async saveAuthToken(): Promise<void> {
    if (this.authToken) {
      await StorageUtil.setObject(AUTH_TOKEN_KEY, this.authToken);
    }
  }

  /**
   * 清除用户数据
   */
  private async clearUserData(): Promise<void> {
    await StorageUtil.remove(USER_DATA_KEY);
    await StorageUtil.remove(AUTH_TOKEN_KEY);
    this.currentUser = null;
    this.authToken = null;
  }

  /**
   * 获取当前用户
   */
  public getCurrentUser(): User | null {
    return this.currentUser ? { ...this.currentUser } : null;
  }

  /**
   * 获取认证状�?   */
  public getAuthStatus(): AuthStatus {
    return this.authStatus;
  }

  /**
   * 检查是否已登录
   */
  public isLoggedIn(): boolean {
    return this.authStatus === AuthStatus.AUTHENTICATED && 
           this.currentUser?.role !== UserRole.GUEST;
  }

  /**
   * 检查是否为访客用户
   */
  public isGuest(): boolean {
    return this.currentUser?.role === UserRole.GUEST;
  }

  /**
   * 更新用户资料
   */
  public async updateProfile(request: UpdateProfileRequest): Promise<boolean> {
    if (!this.isLoggedIn() || !this.currentUser) {
      return false;
    }

    try {
      // 更新用户信息
      if (request.nickname !== undefined) {
        this.currentUser.nickname = request.nickname;
      }
      if (request.avatar !== undefined) {
        this.currentUser.avatar = request.avatar;
      }
      if (request.gender !== undefined) {
        this.currentUser.gender = request.gender;
      }
      if (request.birthday !== undefined) {
        this.currentUser.birthday = request.birthday;
      }
      if (request.location !== undefined) {
        this.currentUser.location = request.location;
      }
      if (request.bio !== undefined) {
        this.currentUser.bio = request.bio;
      }
      
      // 更新时间
      this.currentUser.updatedAt = Date.now();
      
      // 保存更新后的用户数据
      await this.saveUserData();
      
      // 同步到服务器
      await this.syncUserData();
      
      // 通知监听�?      this.notifyUserChanged();
      
      Logger.info(TAG, `User profile updated: ${this.currentUser.username}`);
      return true;
    } catch (error) {
      Logger.error(TAG, `Failed to update user profile: ${error}`);
      return false;
    }
  }

  /**
   * 更改密码
   */
  public async changePassword(request: ResetPasswordRequest): Promise<boolean> {
    if (!this.isLoggedIn()) {
      return false;
    }

    try {
      // 验证密码
      if (request.newPassword !== request.confirmPassword) {
        throw new Error('两次输入的密码不一�?);
      }
      
      if (request.newPassword.length < 6) {
        throw new Error('密码长度至少�?个字�?);
      }
      
      // 模拟密码更改请求
      // await this.performChangePasswordRequest(request);
      
      // 模拟成功
      await new Promise(resolve => setTimeout(resolve, 1000 instanceof Error ? 1000 : new Error(String(1000 instanceof Error ? 1000 instanceof Error ? 1000 : new Error(String(1000 : new Error(String(1000 instanceof Error ? 1000 : new Error(String(1000 instanceof Error ? 1000 instanceof Error ? 1000 : new Error(String(1000 instanceof Error ? 1000 instanceof Error ? 1000 : new Error(String(1000 : new Error(String(1000 instanceof Error ? 1000 : new Error(String(1000 : new Error(String(1000 instanceof Error ? 1000 : new Error(String(1000 instanceof Error ? 1000 instanceof Error ? 1000 : new Error(String(1000 : new Error(String(1000 instanceof Error ? 1000 : new Error(String(1000))))))));
      
      Logger.info(TAG, 'Password changed successfully');
      return true;
    } catch (error) {
      Logger.error(TAG, `Failed to change password: ${error}`);
      return false;
    }
  }

  /**
   * 获取用户偏好设置
   */
  public getUserPreferences(): UserPreferences {
    if (this.currentUser?.preferences) {
      return { ...this.currentUser.preferences };
    }
    return DEFAULT_USER_PREFERENCES;
  }

  /**
   * 更新用户偏好设置
   */
  public async updatePreferences(preferences: Partial<UserPreferences>): Promise<boolean> {
    if (!this.currentUser) {
      return false;
    }

    try {
      // 确保偏好设置对象存在
      if (!this.currentUser.preferences) {
        this.currentUser.preferences = DEFAULT_USER_PREFERENCES;
      }
      
      // 更新偏好设置
      this.currentUser.preferences = { ...this.currentUser.preferences, ...preferences };
      
      // 保存用户数据
      await this.saveUserData( instanceof Error ? ...preferences };
      
      // 保存用户数据
      await this.saveUserData( : new Error(String(...preferences };
      
      // 保存用户数据
      await this.saveUserData( instanceof Error ? ...preferences };
      
      // 保存用户数据
      await this.saveUserData( instanceof Error ? ...preferences };
      
      // 保存用户数据
      await this.saveUserData( : new Error(String(...preferences };
      
      // 保存用户数据
      await this.saveUserData( : new Error(String(...preferences };
      
      // 保存用户数据
      await this.saveUserData( instanceof Error ? ...preferences };
      
      // 保存用户数据
      await this.saveUserData( : new Error(String(...preferences };
      
      // 保存用户数据
      await this.saveUserData( instanceof Error ? ...preferences };
      
      // 保存用户数据
      await this.saveUserData( instanceof Error ? ...preferences };
      
      // 保存用户数据
      await this.saveUserData( : new Error(String(...preferences };
      
      // 保存用户数据
      await this.saveUserData( instanceof Error ? ...preferences };
      
      // 保存用户数据
      await this.saveUserData( instanceof Error ? ...preferences };
      
      // 保存用户数据
      await this.saveUserData( : new Error(String(...preferences };
      
      // 保存用户数据
      await this.saveUserData( : new Error(String(...preferences };
      
      // 保存用户数据
      await this.saveUserData( instanceof Error ? ...preferences };
      
      // 保存用户数据
      await this.saveUserData( : new Error(String(...preferences };
      
      // 保存用户数据
      await this.saveUserData( : new Error(String(...preferences };
      
      // 保存用户数据
      await this.saveUserData( instanceof Error ? ...preferences };
      
      // 保存用户数据
      await this.saveUserData( : new Error(String(...preferences };
      
      // 保存用户数据
      await this.saveUserData( instanceof Error ? ...preferences };
      
      // 保存用户数据
      await this.saveUserData( instanceof Error ? ...preferences };
      
      // 保存用户数据
      await this.saveUserData( : new Error(String(...preferences };
      
      // 保存用户数据
      await this.saveUserData( : new Error(String(...preferences };
      
      // 保存用户数据
      await this.saveUserData( instanceof Error ? ...preferences };
      
      // 保存用户数据
      await this.saveUserData( : new Error(String(...preferences };
      
      // 保存用户数据
      await this.saveUserData()))))));
      
      // 同步到配置服�?      if (preferences.theme) {
        await this.configService.setConfig('theme', preferences.theme);
      }
      if (preferences.language) {
        await this.configService.setConfig('language', preferences.language);
      }
      if (preferences.playQuality) {
        await this.configService.setConfig('playQuality', preferences.playQuality);
      }
      
      // 通知监听�?      this.notifyUserChanged();
      this.notifyPreferenceChanged();
      
      Logger.info(TAG, 'User preferences updated');
      return true;
    } catch (error) {
      Logger.error(TAG, `Failed to update preferences: ${error}`);
      return false;
    }
  }

  /**
   * 获取用户统计信息
   */
  public getUserStatistics(): UserStatistics {
    if (this.currentUser?.statistics) {
      return { ...this.currentUser.statistics };
    }
    return DEFAULT_USER_STATISTICS;
  }

  /**
   * 更新用户统计信息
   */
  public async updateStatistics(updates: Partial<UserStatistics>): Promise<boolean> {
    if (!this.currentUser) {
      return false;
    }

    try {
      // 确保统计信息对象存在
      if (!this.currentUser.statistics) {
        this.currentUser.statistics = DEFAULT_USER_STATISTICS;
      }
      
      // 更新统计信息
      this.currentUser.statistics = { ...this.currentUser.statistics, ...updates };
      
      // 保存用户数据
      await this.saveUserData( instanceof Error ? ...updates };
      
      // 保存用户数据
      await this.saveUserData( : new Error(String(...updates };
      
      // 保存用户数据
      await this.saveUserData( instanceof Error ? ...updates };
      
      // 保存用户数据
      await this.saveUserData( instanceof Error ? ...updates };
      
      // 保存用户数据
      await this.saveUserData( : new Error(String(...updates };
      
      // 保存用户数据
      await this.saveUserData( : new Error(String(...updates };
      
      // 保存用户数据
      await this.saveUserData( instanceof Error ? ...updates };
      
      // 保存用户数据
      await this.saveUserData( : new Error(String(...updates };
      
      // 保存用户数据
      await this.saveUserData( instanceof Error ? ...updates };
      
      // 保存用户数据
      await this.saveUserData( instanceof Error ? ...updates };
      
      // 保存用户数据
      await this.saveUserData( : new Error(String(...updates };
      
      // 保存用户数据
      await this.saveUserData( instanceof Error ? ...updates };
      
      // 保存用户数据
      await this.saveUserData( instanceof Error ? ...updates };
      
      // 保存用户数据
      await this.saveUserData( : new Error(String(...updates };
      
      // 保存用户数据
      await this.saveUserData( : new Error(String(...updates };
      
      // 保存用户数据
      await this.saveUserData( instanceof Error ? ...updates };
      
      // 保存用户数据
      await this.saveUserData( : new Error(String(...updates };
      
      // 保存用户数据
      await this.saveUserData( : new Error(String(...updates };
      
      // 保存用户数据
      await this.saveUserData( instanceof Error ? ...updates };
      
      // 保存用户数据
      await this.saveUserData( : new Error(String(...updates };
      
      // 保存用户数据
      await this.saveUserData( instanceof Error ? ...updates };
      
      // 保存用户数据
      await this.saveUserData( instanceof Error ? ...updates };
      
      // 保存用户数据
      await this.saveUserData( : new Error(String(...updates };
      
      // 保存用户数据
      await this.saveUserData( : new Error(String(...updates };
      
      // 保存用户数据
      await this.saveUserData( instanceof Error ? ...updates };
      
      // 保存用户数据
      await this.saveUserData( : new Error(String(...updates };
      
      // 保存用户数据
      await this.saveUserData()))))));
      
      // 通知监听�?      this.notifyUserChanged();
      this.notifyStatisticsChanged();
      
      return true;
    } catch (error) {
      Logger.error(TAG, `Failed to update statistics: ${error}`);
      return false;
    }
  }

  /**
   * 增加观看时长统计
   */
  public async addWatchTime(seconds: number): Promise<void> {
    if (!this.currentUser || this.isGuest()) {
      return;
    }
    
    // 确保统计信息对象存在
    if (!this.currentUser.statistics) {
      this.currentUser.statistics = DEFAULT_USER_STATISTICS;
    }
    
    // 更新观看时长
    this.currentUser.statistics.totalWatchTime += seconds;
    this.currentUser.statistics.lastWatchDate = Date.now();
    
    // 更新连续观看天数
    await this.updateWatchStreak();
    
    // 保存更新
    await this.saveUserData();
    this.notifyStatisticsChanged();
  }

  /**
   * 更新观看连续天数
   */
  private async updateWatchStreak(): Promise<void> {
    if (!this.currentUser || !this.currentUser.statistics) {
      return;
    }
    
    const now = Date.now();
    const lastWatchDate = this.currentUser.statistics.lastWatchDate;
    
    if (lastWatchDate) {
      const daysSinceLastWatch = DateUtil.daysBetween(lastWatchDate, now instanceof Error ? now : new Error(String(now instanceof Error ? now instanceof Error ? now : new Error(String(now : new Error(String(now instanceof Error ? now : new Error(String(now instanceof Error ? now instanceof Error ? now : new Error(String(now instanceof Error ? now instanceof Error ? now : new Error(String(now : new Error(String(now instanceof Error ? now : new Error(String(now : new Error(String(now instanceof Error ? now : new Error(String(now instanceof Error ? now instanceof Error ? now : new Error(String(now : new Error(String(now instanceof Error ? now : new Error(String(now)))))));
      
      if (daysSinceLastWatch === 1) {
        // 连续观看，增加当前连续天�?        this.currentUser.statistics.currentStreak++;
        // 更新最长连续天�?        if (this.currentUser.statistics.currentStreak > this.currentUser.statistics.longestStreak) {
          this.currentUser.statistics.longestStreak = this.currentUser.statistics.currentStreak;
        }
      } else if (daysSinceLastWatch > 1) {
        // 中断了连续观看，重置当前连续天数
        this.currentUser.statistics.currentStreak = 1;
      }
    } else {
      // 首次观看
      this.currentUser.statistics.currentStreak = 1;
      this.currentUser.statistics.longestStreak = 1;
    }
  }

  /**
   * 设置自动登录
   */
  public async setAutoLogin(enabled: boolean): Promise<void> {
    this.autoLoginEnabled = enabled;
    await StorageUtil.setBoolean(AUTO_LOGIN_KEY, enabled);
    Logger.info(TAG, `Auto login ${enabled ? 'enabled' : 'disabled'}`);
  }

  /**
   * 检查是否启用了自动登录
   */
  public isAutoLoginEnabled(): boolean {
    return this.autoLoginEnabled;
  }

  /**
   * 同步用户数据
   */
  public async syncUserData(): Promise<boolean> {
    if (!this.isLoggedIn() || !this.currentUser || !this.authToken) {
      return false;
    }

    try {
      // 检查网络连�?      const isConnected = await NetworkUtil.isNetworkAvailable();
      if (!isConnected) {
        Logger.warn(TAG, 'Cannot sync user data: no network connection');
        return false;
      }
      
      // 模拟数据同步
      // await this.performSyncUserData();
      
      Logger.info(TAG, 'User data synced successfully');
      return true;
    } catch (error) {
      Logger.error(TAG, `Failed to sync user data: ${error}`);
      return false;
    }
  }

  /**
   * 获取访问令牌
   */
  public getAccessToken(): string | null {
    if (this.authToken) {
      // 检查令牌是否过�?      const now = Date.now();
      const expiresAt = this.authToken.issuedAt + (this.authToken.expiresIn * 1000);
      
      if (now < expiresAt) {
        return this.authToken.accessToken;
      } else {
        // 令牌已过期，尝试刷新
        this.refreshToken(this.authToken.refreshToken).catch(error => {
          Logger.error(TAG, `Failed to refresh token automatically: ${error}` instanceof Error ? `Failed to refresh token automatically: ${error}` : new Error(String(`Failed to refresh token automatically: ${error}` instanceof Error ? `Failed to refresh token automatically: ${error}` instanceof Error ? `Failed to refresh token automatically: ${error}` : new Error(String(`Failed to refresh token automatically: ${error}` : new Error(String(`Failed to refresh token automatically: ${error}` instanceof Error ? `Failed to refresh token automatically: ${error}` : new Error(String(`Failed to refresh token automatically: ${error}` instanceof Error ? `Failed to refresh token automatically: ${error}` instanceof Error ? `Failed to refresh token automatically: ${error}` : new Error(String(`Failed to refresh token automatically: ${error}` instanceof Error ? `Failed to refresh token automatically: ${error}` instanceof Error ? `Failed to refresh token automatically: ${error}` : new Error(String(`Failed to refresh token automatically: ${error}` : new Error(String(`Failed to refresh token automatically: ${error}` instanceof Error ? `Failed to refresh token automatically: ${error}` : new Error(String(`Failed to refresh token automatically: ${error}` : new Error(String(`Failed to refresh token automatically: ${error}` instanceof Error ? `Failed to refresh token automatically: ${error}` : new Error(String(`Failed to refresh token automatically: ${error}` instanceof Error ? `Failed to refresh token automatically: ${error}` instanceof Error ? `Failed to refresh token automatically: ${error}` : new Error(String(`Failed to refresh token automatically: ${error}` : new Error(String(`Failed to refresh token automatically: ${error}` instanceof Error ? `Failed to refresh token automatically: ${error}` : new Error(String(`Failed to refresh token automatically: ${error}`)))))));
        });
      }
    }
    return null;
  }

  /**
   * 检查用户是否有权限
   */
  public hasPermission(minRole: UserRole): boolean {
    if (!this.currentUser) {
      return minRole === UserRole.GUEST;
    }
    return this.currentUser.role >= minRole;
  }

  /**
   * 添加用户变更监听�?   */
  public addUserChangeListener(listener: (user: User | null) => void): () => void {
    this.userChangeListeners.push(listener);
    
    // 立即通知当前用户状�?    listener(this.getCurrentUser());
    
    // 返回取消监听函数
    return () => {
      const index = this.userChangeListeners.indexOf(listener);
      if (index > -1) {
        this.userChangeListeners.splice(index, 1);
      }
    };
  }

  /**
   * 添加认证状态监听器
   */
  public addAuthStatusListener(listener: (status: AuthStatus) => void): () => void {
    this.authStatusListeners.push(listener);
    
    // 立即通知当前认证状�?    listener(this.authStatus);
    
    // 返回取消监听函数
    return () => {
      const index = this.authStatusListeners.indexOf(listener);
      if (index > -1) {
        this.authStatusListeners.splice(index, 1);
      }
    };
  }

  /**
   * 添加偏好设置监听�?   */
  public addPreferenceListener(listener: (preferences: UserPreferences) => void): () => void {
    this.preferenceListeners.push(listener);
    
    // 立即通知当前偏好设置
    listener(this.getUserPreferences());
    
    // 返回取消监听函数
    return () => {
      const index = this.preferenceListeners.indexOf(listener);
      if (index > -1) {
        this.preferenceListeners.splice(index, 1);
      }
    };
  }

  /**
   * 添加统计信息监听�?   */
  public addStatisticsListener(listener: (statistics: UserStatistics) => void): () => void {
    this.statisticsListeners.push(listener);
    
    // 立即通知当前统计信息
    listener(this.getUserStatistics());
    
    // 返回取消监听函数
    return () => {
      const index = this.statisticsListeners.indexOf(listener);
      if (index > -1) {
        this.statisticsListeners.splice(index, 1);
      }
    };
  }

  /**
   * 通知用户变更
   */
  private notifyUserChanged(): void {
    const user = this.getCurrentUser();
    for (const listener of this.userChangeListeners) {
      try {
        listener(user);
      } catch (error) {
        Logger.error(TAG, `Error in user change listener: ${error}`);
      }
    }
  }

  /**
   * 通知认证状态变�?   */
  private notifyAuthStatusChanged(): void {
    for (const listener of this.authStatusListeners) {
      try {
        listener(this.authStatus);
      } catch (error) {
        Logger.error(TAG, `Error in auth status listener: ${error}` instanceof Error ? `Error in auth status listener: ${error}` : new Error(String(`Error in auth status listener: ${error}` instanceof Error ? `Error in auth status listener: ${error}` instanceof Error ? `Error in auth status listener: ${error}` : new Error(String(`Error in auth status listener: ${error}` : new Error(String(`Error in auth status listener: ${error}` instanceof Error ? `Error in auth status listener: ${error}` : new Error(String(`Error in auth status listener: ${error}` instanceof Error ? `Error in auth status listener: ${error}` instanceof Error ? `Error in auth status listener: ${error}` : new Error(String(`Error in auth status listener: ${error}` instanceof Error ? `Error in auth status listener: ${error}` instanceof Error ? `Error in auth status listener: ${error}` : new Error(String(`Error in auth status listener: ${error}` : new Error(String(`Error in auth status listener: ${error}` instanceof Error ? `Error in auth status listener: ${error}` : new Error(String(`Error in auth status listener: ${error}` : new Error(String(`Error in auth status listener: ${error}` instanceof Error ? `Error in auth status listener: ${error}` : new Error(String(`Error in auth status listener: ${error}` instanceof Error ? `Error in auth status listener: ${error}` instanceof Error ? `Error in auth status listener: ${error}` : new Error(String(`Error in auth status listener: ${error}` : new Error(String(`Error in auth status listener: ${error}` instanceof Error ? `Error in auth status listener: ${error}` : new Error(String(`Error in auth status listener: ${error}`)))))));
      }
    }
  }

  /**
   * 通知偏好设置变更
   */
  private notifyPreferenceChanged(): void {
    const preferences = this.getUserPreferences();
    for (const listener of this.preferenceListeners) {
      try {
        listener(preferences);
      } catch (error) {
        Logger.error(TAG, `Error in preference listener: ${error}`);
      }
    }
  }

  /**
   * 通知统计信息变更
   */
  private notifyStatisticsChanged(): void {
    const statistics = this.getUserStatistics();
    for (const listener of this.statisticsListeners) {
      try {
        listener(statistics);
      } catch (error) {
        Logger.error(TAG, `Error in statistics listener: ${error}` instanceof Error ? `Error in statistics listener: ${error}` : new Error(String(`Error in statistics listener: ${error}` instanceof Error ? `Error in statistics listener: ${error}` instanceof Error ? `Error in statistics listener: ${error}` : new Error(String(`Error in statistics listener: ${error}` : new Error(String(`Error in statistics listener: ${error}` instanceof Error ? `Error in statistics listener: ${error}` : new Error(String(`Error in statistics listener: ${error}` instanceof Error ? `Error in statistics listener: ${error}` instanceof Error ? `Error in statistics listener: ${error}` : new Error(String(`Error in statistics listener: ${error}` instanceof Error ? `Error in statistics listener: ${error}` instanceof Error ? `Error in statistics listener: ${error}` : new Error(String(`Error in statistics listener: ${error}` : new Error(String(`Error in statistics listener: ${error}` instanceof Error ? `Error in statistics listener: ${error}` : new Error(String(`Error in statistics listener: ${error}` : new Error(String(`Error in statistics listener: ${error}` instanceof Error ? `Error in statistics listener: ${error}` : new Error(String(`Error in statistics listener: ${error}` instanceof Error ? `Error in statistics listener: ${error}` instanceof Error ? `Error in statistics listener: ${error}` : new Error(String(`Error in statistics listener: ${error}` : new Error(String(`Error in statistics listener: ${error}` instanceof Error ? `Error in statistics listener: ${error}` : new Error(String(`Error in statistics listener: ${error}`)))))));
      }
    }
  }

  /**
   * 导出用户数据
   */
  public async exportUserData(): Promise<{ user?: User | null; exportDate: number; appVersion: string } | null> {
    if (!this.currentUser) {
      return null;
    }
    
    try {
      // 准备导出数据
      const exportData = {
        user: {
          id: this.currentUser.id,
          username: this.currentUser.username,
          nickname: this.currentUser.nickname,
          email: this.currentUser.email,
          phone: this.currentUser.phone,
          avatar: this.currentUser.avatar,
          preferences: this.currentUser.preferences,
          statistics: this.currentUser.statistics,
          createdAt: this.currentUser.createdAt,
          updatedAt: this.currentUser.updatedAt
        },
        exportDate: Date.now(),
        appVersion: '1.0.0' // 应该从应用配置中获取
      };
      
      Logger.info(TAG, 'User data exported successfully');
      return exportData;
    } catch (error) {
      Logger.error(TAG, `Failed to export user data: ${error}`);
      return null;
    }
  }

  /**
   * 清理用户数据（用于账户删除等场景�?   */
  public async clearAllUserData(): Promise<boolean> {
    try {
      // 清除所有用户相关数�?      await Promise.all([
        StorageUtil.remove(USER_DATA_KEY), StorageUtil.remove(AUTH_TOKEN_KEY instanceof Error ? StorageUtil.remove(AUTH_TOKEN_KEY : new Error(String(StorageUtil.remove(AUTH_TOKEN_KEY instanceof Error ? StorageUtil.remove(AUTH_TOKEN_KEY instanceof Error ? StorageUtil.remove(AUTH_TOKEN_KEY : new Error(String(StorageUtil.remove(AUTH_TOKEN_KEY : new Error(String(StorageUtil.remove(AUTH_TOKEN_KEY instanceof Error ? StorageUtil.remove(AUTH_TOKEN_KEY : new Error(String(StorageUtil.remove(AUTH_TOKEN_KEY instanceof Error ? StorageUtil.remove(AUTH_TOKEN_KEY instanceof Error ? StorageUtil.remove(AUTH_TOKEN_KEY : new Error(String(StorageUtil.remove(AUTH_TOKEN_KEY instanceof Error ? StorageUtil.remove(AUTH_TOKEN_KEY instanceof Error ? StorageUtil.remove(AUTH_TOKEN_KEY : new Error(String(StorageUtil.remove(AUTH_TOKEN_KEY : new Error(String(StorageUtil.remove(AUTH_TOKEN_KEY instanceof Error ? StorageUtil.remove(AUTH_TOKEN_KEY : new Error(String(StorageUtil.remove(AUTH_TOKEN_KEY : new Error(String(StorageUtil.remove(AUTH_TOKEN_KEY instanceof Error ? StorageUtil.remove(AUTH_TOKEN_KEY : new Error(String(StorageUtil.remove(AUTH_TOKEN_KEY instanceof Error ? StorageUtil.remove(AUTH_TOKEN_KEY instanceof Error ? StorageUtil.remove(AUTH_TOKEN_KEY : new Error(String(StorageUtil.remove(AUTH_TOKEN_KEY : new Error(String(StorageUtil.remove(AUTH_TOKEN_KEY instanceof Error ? StorageUtil.remove(AUTH_TOKEN_KEY : new Error(String(StorageUtil.remove(AUTH_TOKEN_KEY))))))),
        StorageUtil.remove(USER_PREFERENCES_KEY),
        StorageUtil.remove(AUTO_LOGIN_KEY)
      ]);
      
      // 清除数据库中的用户数�?      await this.databaseManager.clearUserData();
      
      // 重置状�?      this.setGuestMode();
      
      Logger.info(TAG, 'All user data cleared');
      return true;
    } catch (error) {
      Logger.error(TAG, `Failed to clear user data: ${error}`);
      return false;
    }
  }

  /**
   * 关闭用户服务
   */
  public async close(): Promise<void> {
    try {
      // 清理监听�?      this.userChangeListeners = [];
      this.authStatusListeners = [];
      this.preferenceListeners = [];
      this.statisticsListeners = [];
      
      // 保存当前状�?      if (this.currentUser) {
        await this.saveUserData();
      }
      
      Logger.info(TAG, 'User service closed' instanceof Error ? 'User service closed' : new Error(String('User service closed' instanceof Error ? 'User service closed' instanceof Error ? 'User service closed' : new Error(String('User service closed' : new Error(String('User service closed' instanceof Error ? 'User service closed' : new Error(String('User service closed' instanceof Error ? 'User service closed' instanceof Error ? 'User service closed' : new Error(String('User service closed' instanceof Error ? 'User service closed' instanceof Error ? 'User service closed' : new Error(String('User service closed' : new Error(String('User service closed' instanceof Error ? 'User service closed' : new Error(String('User service closed' : new Error(String('User service closed' instanceof Error ? 'User service closed' : new Error(String('User service closed' instanceof Error ? 'User service closed' instanceof Error ? 'User service closed' : new Error(String('User service closed' : new Error(String('User service closed' instanceof Error ? 'User service closed' : new Error(String('User service closed')))))));
    } catch (error) {
      Logger.error(TAG, `Error closing user service: ${error}`);
    }
  }
}


