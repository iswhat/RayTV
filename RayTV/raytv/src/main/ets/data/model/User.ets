/**
 * User - User entity class | 用户实体类
 * Define user data structure | 定义用户数据结构
 */

/**
 * User role enum | 用户角色枚举
 */
export enum UserRole {
  ADMIN = 'admin',        // Administrator | 管理员
  USER = 'user',         // Regular user | 普通用户
  GUEST = 'guest',       // Guest user | 访客
  PREMIUM = 'premium'     // Premium user | 高级用户
}

/**
 * User status enum | 用户状态枚举
 */
export enum UserStatus {
  ACTIVE = 'active',     // Active | 活跃
  INACTIVE = 'inactive', // Inactive | 不活跃
  SUSPENDED = 'suspended', // Suspended | 已暂停
  DELETED = 'deleted'    // Deleted | 已删除
}

/**
 * User params interface | 用户参数接口
 * Used for user construction parameters | 用于用户构造参数
 */
export interface UserParams {
  id: string;
  username: string;
  email?: string;
  nickname?: string;
  avatarUrl?: string;
  role?: UserRole;
  lastLoginTime?: string;
  registrationDate?: string;
  status?: UserStatus;
  isVerified?: boolean;
  subscriptionEndDate?: string;
  watchHistoryEnabled?: boolean;
  favoritesEnabled?: boolean;
  totalWatchTime?: number;
}

/**
 * User entity class | 用户实体类
 */
export default class User {
  /**
   * User ID | 用户ID
   */
  id: string;
  
  /**
   * Username | 用户名
   */
  username: string;
  
  /**
   * Email | 邮箱
   */
  email?: string;
  
  /**
   * Nickname | 昵称
   */
  nickname?: string;
  
  /**
   * Avatar URL | 头像URL
   */
  avatarUrl?: string;
  
  /**
   * User role | 用户角色
   */
  role: UserRole;
  
  /**
   * Last login time | 最后登录时间
   */
  lastLoginTime?: string;
  
  /**
   * Registration date | 注册日期
   */
  registrationDate: string;
  
  /**
   * User status | 用户状态
   */
  status: UserStatus;
  
  /**
   * Is verified | 是否已验证
   */
  isVerified: boolean;
  
  /**
   * Subscription end date | 订阅结束日期
   */
  subscriptionEndDate?: string;
  
  /**
   * Watch history enabled | 是否启用观看历史
   */
  watchHistoryEnabled: boolean;
  
  /**
   * Favorites enabled | 是否启用收藏
   */
  favoritesEnabled: boolean;
  
  /**
   * Total watch time (in seconds) | 总观看时间（秒）
   */
  totalWatchTime: number;
  
  /**
   * Constructor | 构造函数
   */
  constructor(params: UserParams) {
    this.id = params.id;
    this.username = params.username;
    this.email = params.email;
    this.nickname = params.nickname;
    this.avatarUrl = params.avatarUrl;
    this.role = params.role || UserRole.USER;
    this.lastLoginTime = params.lastLoginTime;
    this.registrationDate = params.registrationDate || new Date().toISOString();
    this.status = params.status || UserStatus.ACTIVE;
    this.isVerified = params.isVerified || false;
    this.subscriptionEndDate = params.subscriptionEndDate;
    this.watchHistoryEnabled = params.watchHistoryEnabled !== false;
    this.favoritesEnabled = params.favoritesEnabled !== false;
    this.totalWatchTime = params.totalWatchTime || 0;
  }
}