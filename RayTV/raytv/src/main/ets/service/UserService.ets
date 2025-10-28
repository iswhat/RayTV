// 用户服务
// 管理用户信息、认证和偏好设置

import { StorageUtil, StorageType } from '../common/util/StorageUtil';
import { HttpService } from './HttpService';

/**
 * 用户信息接口
 */
export interface UserInfo {
  userId?: string;
  username?: string;
  avatar?: string;
  email?: string;
  phone?: string;
  nickname?: string;
  gender?: 'male' | 'female' | 'other';
  birthDate?: string;
  registerDate?: string;
  lastLoginDate?: string;
  isGuest?: boolean;
  preferences?: UserPreferences;
}

/**
 * 用户偏好设置接口
 */
export interface UserPreferences {
  theme?: 'light' | 'dark' | 'system';
  language?: string;
  playbackSpeed?: number;
  defaultQuality?: string;
  subtitles?: boolean;
  autoPlay?: boolean;
  danmakuEnabled?: boolean;
  notifications?: boolean;
  favoriteCategories?: string[];
  watchedHistoryEnabled?: boolean;
  searchHistoryEnabled?: boolean;
}

/**
 * 认证信息接口
 */
export interface AuthInfo {
  token?: string;
  refreshToken?: string;
  expiresIn?: number;
  tokenType?: string;
}

/**
 * 用户服务实现类
 */
export class UserService {
  private static instance: UserService;
  private storageUtil: StorageUtil;
  private httpService: HttpService;
  private userInfo: UserInfo | null = null;
  private authInfo: AuthInfo | null = null;
  private initialized: boolean = false;
  
  private constructor() {
    this.storageUtil = StorageUtil.getInstance();
    this.httpService = HttpService.getInstance();
  }
  
  public static getInstance(): UserService {
    if (!UserService.instance) {
      UserService.instance = new UserService();
    }
    return UserService.instance;
  }
  
  /**
   * 初始化用户服务
   */
  public async initialize(): Promise<void> {
    if (this.initialized) return;
    
    try {
      // 加载存储的用户信息
      await this.loadUserData();
      // 检查token是否过期
      await this.validateAuth();
      this.initialized = true;
    } catch (error) {
      console.error('Failed to initialize user service:', error);
      // 初始化失败时清理用户数据，确保应用能正常运行
      await this.clearUserData();
      this.initialized = true;
    }
  }
  
  /**
   * 加载存储的用户数据
   */
  private async loadUserData(): Promise<void> {
    try {
      // 加载用户信息
      const savedUserInfo = await this.storageUtil.get(StorageType.USER_DATA, 'user_info');
      if (savedUserInfo) {
        this.userInfo = savedUserInfo;
      }
      
      // 加载认证信息
      const savedAuthInfo = await this.storageUtil.get(StorageType.USER_DATA, 'auth_info');
      if (savedAuthInfo) {
        this.authInfo = savedAuthInfo;
      }
    } catch (error) {
      console.error('Failed to load user data:', error);
      throw error;
    }
  }
  
  /**
   * 保存用户数据到存储
   */
  private async saveUserData(): Promise<void> {
    try {
      if (this.userInfo) {
        await this.storageUtil.save(StorageType.USER_DATA, 'user_info', this.userInfo);
      }
      
      if (this.authInfo) {
        await this.storageUtil.save(StorageType.USER_DATA, 'auth_info', this.authInfo);
      }
    } catch (error) {
      console.error('Failed to save user data:', error);
      throw error;
    }
  }
  
  /**
   * 清理用户数据
   */
  private async clearUserData(): Promise<void> {
    this.userInfo = null;
    this.authInfo = null;
    
    try {
      await this.storageUtil.remove(StorageType.USER_DATA, 'user_info');
      await this.storageUtil.remove(StorageType.USER_DATA, 'auth_info');
    } catch (error) {
      console.error('Failed to clear user data:', error);
    }
  }
  
  /**
   * 验证认证信息
   */
  private async validateAuth(): Promise<boolean> {
    if (!this.authInfo || !this.authInfo.token) {
      return false;
    }
    
    try {
      // 检查token是否过期
      const isExpired = this.isTokenExpired();
      if (isExpired) {
        // 如果有刷新token，尝试刷新token
        if (this.authInfo.refreshToken) {
          await this.refreshToken();
          return true;
        } else {
          // 没有刷新token，清理认证信息
          await this.clearAuth();
          return false;
        }
      }
      
      return true;
    } catch (error) {
      console.error('Failed to validate auth:', error);
      await this.clearAuth();
      return false;
    }
  }
  
  /**
   * 检查token是否过期
   */
  private isTokenExpired(): boolean {
    if (!this.authInfo || !this.authInfo.expiresIn) {
      return true;
    }
    
    // 在实际应用中，这里应该根据token的过期时间进行检查
    // 现在简单返回false，表示token未过期
    return false;
  }
  
  /**
   * 刷新token
   */
  private async refreshToken(): Promise<void> {
    try {
      if (!this.authInfo?.refreshToken) {
        throw new Error('No refresh token available');
      }
      
      // 在实际应用中，这里应该调用API刷新token
      // 现在模拟刷新成功
      console.log('Token refreshed successfully');
    } catch (error) {
      console.error('Failed to refresh token:', error);
      throw error;
    }
  }
  
  /**
   * 清除认证信息
   */
  private async clearAuth(): Promise<void> {
    if (this.authInfo) {
      this.authInfo = null;
      await this.storageUtil.remove(StorageType.USER_DATA, 'auth_info');
    }
  }
  
  /**
   * 创建访客用户
   */
  public async createGuestUser(): Promise<UserInfo> {
    const guestUser: UserInfo = {
      userId: `guest_${Date.now()}`,
      username: '访客用户',
      isGuest: true,
      registerDate: new Date().toISOString(),
      lastLoginDate: new Date().toISOString(),
      preferences: this.getDefaultPreferences()
    };
    
    this.userInfo = guestUser;
    await this.saveUserData();
    return guestUser;
  }
  
  /**
   * 获取默认偏好设置
   */
  private getDefaultPreferences(): UserPreferences {
    return {
      theme: 'system',
      language: 'auto',
      playbackSpeed: 1.0,
      defaultQuality: 'auto',
      subtitles: false,
      autoPlay: true,
      danmakuEnabled: true,
      notifications: true,
      favoriteCategories: [],
      watchedHistoryEnabled: true,
      searchHistoryEnabled: true
    };
  }
  
  /**
   * 用户登录
   */
  public async login(username: string, password: string): Promise<UserInfo> {
    try {
      // 在实际应用中，这里应该调用API进行登录验证
      // 现在模拟登录成功
      const mockUser: UserInfo = {
        userId: 'user_123',
        username: username,
        nickname: username,
        avatar: 'https://example.com/avatar.jpg',
        registerDate: '2023-01-01T00:00:00Z',
        lastLoginDate: new Date().toISOString(),
        isGuest: false,
        preferences: this.getDefaultPreferences()
      };
      
      const mockAuth: AuthInfo = {
        token: 'mock_token_123456',
        refreshToken: 'mock_refresh_token_123456',
        expiresIn: 3600,
        tokenType: 'Bearer'
      };
      
      this.userInfo = mockUser;
      this.authInfo = mockAuth;
      
      await this.saveUserData();
      
      return mockUser;
    } catch (error) {
      console.error('Login failed:', error);
      throw new Error('登录失败，请检查用户名和密码');
    }
  }
  
  /**
   * 用户注册
   */
  public async register(username: string, password: string, email: string): Promise<UserInfo> {
    try {
      // 在实际应用中，这里应该调用API进行注册
      // 现在模拟注册成功
      const mockUser: UserInfo = {
        userId: `user_${Date.now()}`,
        username: username,
        email: email,
        nickname: username,
        registerDate: new Date().toISOString(),
        lastLoginDate: new Date().toISOString(),
        isGuest: false,
        preferences: this.getDefaultPreferences()
      };
      
      const mockAuth: AuthInfo = {
        token: `mock_token_${Date.now()}`,
        refreshToken: `mock_refresh_token_${Date.now()}`,
        expiresIn: 3600,
        tokenType: 'Bearer'
      };
      
      this.userInfo = mockUser;
      this.authInfo = mockAuth;
      
      await this.saveUserData();
      
      return mockUser;
    } catch (error) {
      console.error('Registration failed:', error);
      throw new Error('注册失败，请稍后重试');
    }
  }
  
  /**
   * 用户登出
   */
  public async logout(): Promise<void> {
    try {
      // 在实际应用中，这里应该调用API进行登出
      console.log('User logged out');
    } catch (error) {
      console.error('Logout failed:', error);
    } finally {
      // 无论如何都清理本地用户数据
      await this.clearUserData();
    }
  }
  
  /**
   * 获取当前用户信息
   */
  public async getCurrentUser(): Promise<UserInfo | null> {
    await this.initialize();
    
    // 如果没有用户信息，创建访客用户
    if (!this.userInfo) {
      await this.createGuestUser();
    }
    
    return this.userInfo;
  }
  
  /**
   * 检查用户是否已登录（非访客）
   */
  public async isLoggedIn(): Promise<boolean> {
    await this.initialize();
    return !!this.userInfo && !this.userInfo.isGuest;
  }
  
  /**
   * 更新用户信息
   */
  public async updateUserInfo(updates: Partial<UserInfo>): Promise<UserInfo> {
    await this.initialize();
    
    if (!this.userInfo) {
      throw new Error('No user logged in');
    }
    
    try {
      // 合并更新信息
      this.userInfo = { ...this.userInfo, ...updates };
      
      // 在实际应用中，这里应该调用API更新用户信息
      
      await this.saveUserData();
      return this.userInfo;
    } catch (error) {
      console.error('Failed to update user info:', error);
      throw new Error('更新用户信息失败');
    }
  }
  
  /**
   * 更新用户偏好设置
   */
  public async updatePreferences(preferences: Partial<UserPreferences>): Promise<UserPreferences> {
    await this.initialize();
    
    if (!this.userInfo) {
      throw new Error('No user logged in');
    }
    
    try {
      // 确保preferences对象存在
      if (!this.userInfo.preferences) {
        this.userInfo.preferences = this.getDefaultPreferences();
      }
      
      // 合并偏好设置
      this.userInfo.preferences = { 
        ...this.userInfo.preferences, 
        ...preferences 
      };
      
      await this.saveUserData();
      return this.userInfo.preferences!;
    } catch (error) {
      console.error('Failed to update preferences:', error);
      throw new Error('更新偏好设置失败');
    }
  }
  
  /**
   * 获取用户偏好设置
   */
  public async getPreferences(): Promise<UserPreferences> {
    await this.initialize();
    
    if (!this.userInfo || !this.userInfo.preferences) {
      // 如果没有用户或偏好设置，返回默认设置
      const defaultPrefs = this.getDefaultPreferences();
      
      // 如果有用户，更新其偏好设置
      if (this.userInfo) {
        this.userInfo.preferences = defaultPrefs;
        await this.saveUserData();
      }
      
      return defaultPrefs;
    }
    
    return this.userInfo.preferences;
  }
  
  /**
   * 重置密码
   */
  public async resetPassword(email: string): Promise<boolean> {
    try {
      // 在实际应用中，这里应该调用API发送重置密码邮件
      console.log('Password reset email sent to:', email);
      return true;
    } catch (error) {
      console.error('Failed to reset password:', error);
      throw new Error('发送重置密码邮件失败');
    }
  }
  
  /**
   * 修改密码
   */
  public async changePassword(oldPassword: string, newPassword: string): Promise<boolean> {
    await this.initialize();
    
    if (!await this.isLoggedIn()) {
      throw new Error('请先登录');
    }
    
    try {
      // 在实际应用中，这里应该调用API修改密码
      console.log('Password changed successfully');
      
      // 更新登录时间
      if (this.userInfo) {
        this.userInfo.lastLoginDate = new Date().toISOString();
        await this.saveUserData();
      }
      
      return true;
    } catch (error) {
      console.error('Failed to change password:', error);
      throw new Error('修改密码失败');
    }
  }
  
  /**
   * 获取认证token
   */
  public async getAuthToken(): Promise<string | null> {
    await this.initialize();
    
    // 验证认证信息
    const isValid = await this.validateAuth();
    
    if (isValid && this.authInfo?.token) {
      return `${this.authInfo.tokenType || 'Bearer'} ${this.authInfo.token}`;
    }
    
    return null;
  }
  
  /**
   * 添加收藏
   */
  public async addFavorite(item: { id: string; type: string; title: string; cover: string }): Promise<boolean> {
    await this.initialize();
    
    if (!this.userInfo) {
      throw new Error('No user logged in');
    }
    
    try {
      // 获取用户的收藏列表
      let favorites = await this.storageUtil.get(StorageType.USER_DATA, `favorites_${this.userInfo.userId}`) || [];
      
      if (!Array.isArray(favorites)) {
        favorites = [];
      }
      
      // 检查是否已存在
      const exists = favorites.some((fav: any) => fav.id === item.id && fav.type === item.type);
      if (!exists) {
        // 添加到收藏列表
        favorites.unshift({
          ...item,
          addTime: new Date().toISOString()
        });
        
        // 保存收藏列表
        await this.storageUtil.save(StorageType.USER_DATA, `favorites_${this.userInfo.userId}`, favorites);
      }
      
      return true;
    } catch (error) {
      console.error('Failed to add favorite:', error);
      throw new Error('添加收藏失败');
    }
  }
  
  /**
   * 移除收藏
   */
  public async removeFavorite(itemId: string, itemType: string): Promise<boolean> {
    await this.initialize();
    
    if (!this.userInfo) {
      throw new Error('No user logged in');
    }
    
    try {
      // 获取用户的收藏列表
      let favorites = await this.storageUtil.get(StorageType.USER_DATA, `favorites_${this.userInfo.userId}`) || [];
      
      if (!Array.isArray(favorites)) {
        favorites = [];
      }
      
      // 过滤掉要移除的项目
      const newFavorites = favorites.filter((fav: any) => !(fav.id === itemId && fav.type === itemType));
      
      // 保存更新后的收藏列表
      await this.storageUtil.save(StorageType.USER_DATA, `favorites_${this.userInfo.userId}`, newFavorites);
      
      return true;
    } catch (error) {
      console.error('Failed to remove favorite:', error);
      throw new Error('移除收藏失败');
    }
  }
  
  /**
   * 获取收藏列表
   */
  public async getFavorites(type?: string): Promise<any[]> {
    await this.initialize();
    
    if (!this.userInfo) {
      return [];
    }
    
    try {
      // 获取用户的收藏列表
      let favorites = await this.storageUtil.get(StorageType.USER_DATA, `favorites_${this.userInfo.userId}`) || [];
      
      if (!Array.isArray(favorites)) {
        favorites = [];
      }
      
      // 如果指定了类型，过滤结果
      if (type) {
        favorites = favorites.filter((fav: any) => fav.type === type);
      }
      
      return favorites;
    } catch (error) {
      console.error('Failed to get favorites:', error);
      return [];
    }
  }
  
  /**
   * 检查是否已收藏
   */
  public async isFavorite(itemId: string, itemType: string): Promise<boolean> {
    await this.initialize();
    
    if (!this.userInfo) {
      return false;
    }
    
    try {
      // 获取用户的收藏列表
      const favorites = await this.getFavorites();
      return favorites.some((fav: any) => fav.id === itemId && fav.type === itemType);
    } catch (error) {
      console.error('Failed to check favorite status:', error);
      return false;
    }
  }
}

// 导出类型别名
export type { UserInfo as User };
export type { UserPreferences as Preferences };