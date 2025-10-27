// UserDto - 用户相关数据传输对象
import { UserRole } from '../model/User';
import ApiResponse from './ApiResponse';

/**
 * 登录请求参数接口
 */
export interface LoginRequest {
  username: string;                 // 用户名/邮箱/手机号
  password: string;                 // 密码
  rememberMe?: boolean;             // 是否记住登录状态
  deviceInfo?: DeviceInfo;          // 设备信息
  captcha?: string;                 // 验证码
  captchaKey?: string;              // 验证码密钥
  loginType?: 'normal' | 'sso' | 'third_party'; // 登录类型
}

/**
 * 注册请求参数接口
 */
export interface RegisterRequest {
  username: string;                 // 用户名
  email?: string;                   // 邮箱（可选）
  phone?: string;                   // 手机号（可选）
  password: string;                 // 密码
  confirmPassword: string;          // 确认密码
  nickname?: string;                // 昵称（可选）
  avatarUrl?: string;               // 头像URL（可选）
  captcha?: string;                 // 验证码
  captchaKey?: string;              // 验证码密钥
  agreeTerms: boolean;              // 是否同意用户协议
  referralCode?: string;            // 推荐码（可选）
}

/**
 * 忘记密码请求参数接口
 */
export interface ForgotPasswordRequest {
  email?: string;                   // 邮箱（可选）
  phone?: string;                   // 手机号（可选）
  captcha?: string;                 // 验证码
  captchaKey?: string;              // 验证码密钥
  newPassword: string;              // 新密码
  confirmNewPassword: string;       // 确认新密码
}

/**
 * 重置密码请求参数接口
 */
export interface ResetPasswordRequest {
  oldPassword: string;              // 旧密码
  newPassword: string;              // 新密码
  confirmNewPassword: string;       // 确认新密码
}

/**
 * 验证码请求参数接口
 */
export interface CaptchaRequest {
  type: 'login' | 'register' | 'forgot' | 'change_email' | 'change_phone'; // 验证码类型
  email?: string;                   // 邮箱（可选）
  phone?: string;                   // 手机号（可选）
  width?: number;                   // 图片宽度（可选）
  height?: number;                  // 图片高度（可选）
}

/**
 * 设备信息接口
 */
export interface DeviceInfo {
  deviceId: string;                 // 设备ID
  deviceName: string;               // 设备名称
  deviceType: 'phone' | 'tablet' | 'tv' | 'computer' | 'other'; // 设备类型
  os: string;                       // 操作系统
  osVersion: string;                // 操作系统版本
  appVersion: string;               // 应用版本
  screenWidth?: number;             // 屏幕宽度
  screenHeight?: number;            // 屏幕高度
  ipAddress?: string;               // IP地址
  userAgent?: string;               // 用户代理
}

/**
 * 认证响应数据接口
 */
export interface AuthResponseData {
  token: string;                    // JWT或其他认证令牌
  refreshToken?: string;            // 刷新令牌
  expiresIn: number;                // 令牌过期时间（秒）
  tokenType: string;                // 令牌类型
  user: UserInfo;                   // 用户信息
  permissions?: string[];           // 权限列表
  deviceId?: string;                // 设备ID
  loginAt: number;                  // 登录时间戳
  expiresAt: number;                // 令牌过期时间戳
}

/**
 * 用户基本信息接口
 */
export interface UserInfo {
  id: string;                       // 用户ID
  username: string;                 // 用户名
  nickname?: string;                // 昵称
  avatarUrl?: string;               // 头像URL
  email?: string;                   // 邮箱
  phone?: string;                   // 手机号
  role: UserRole;                   // 用户角色
  gender?: 'male' | 'female' | 'other'; // 性别
  birthDate?: string;               // 出生日期
  country?: string;                 // 国家/地区
  language?: string;                // 语言偏好
  bio?: string;                     // 个人简介
  isVerified: boolean;              // 是否已验证
  isActive: boolean;                // 是否激活
  isOnline?: boolean;               // 是否在线
  createdAt: number;                // 创建时间戳
  updatedAt: number;                // 更新时间戳
  lastLoginAt?: number;             // 最后登录时间戳
  totalWatchTime?: number;          // 总观看时长（分钟）
  favoriteCount?: number;           // 收藏数量
  historyCount?: number;            // 观看历史数量
  subscriptionStatus?: 'free' | 'premium' | 'expired'; // 订阅状态
  subscriptionExpiresAt?: number;   // 订阅过期时间戳
}

/**
 * 用户偏好设置接口
 */
export interface UserPreferences {
  theme: 'light' | 'dark' | 'auto'; // 主题设置
  language: string;                 // 语言设置
  subtitles: SubtitlePreferences;   // 字幕设置
  playback: PlaybackPreferences;    // 播放设置
  notification: NotificationPreferences; // 通知设置
  privacy: PrivacyPreferences;      // 隐私设置
  interface: InterfacePreferences;  // 界面设置
  parental: ParentalControlPreferences; // 家长控制设置
  recommendations: RecommendationPreferences; // 推荐设置
  custom?: Record<string, any>;     // 自定义偏好设置
  updatedAt: number;                // 更新时间戳
}

/**
 * 字幕偏好设置接口
 */
export interface SubtitlePreferences {
  enabled: boolean;                 // 是否启用字幕
  language: string;                 // 首选字幕语言
  size: 'small' | 'medium' | 'large' | number; // 字幕大小
  color: string;                    // 字幕颜色
  backgroundColor?: string;         // 背景颜色
  font: string;                     // 字体
  bold: boolean;                    // 是否粗体
  position: 'bottom' | 'top' | 'custom'; // 字幕位置
  delay?: number;                   // 字幕延迟（毫秒）
}

/**
 * 播放偏好设置接口
 */
export interface PlaybackPreferences {
  autoPlay: boolean;                // 是否自动播放
  autoNext: boolean;                // 是否自动播放下一集
  defaultQuality: string;           // 默认画质
  bandwidthSaving: boolean;         // 是否节省带宽
  rememberPosition: boolean;        // 是否记住播放位置
  volume: number;                   // 默认音量
  muted: boolean;                   // 是否默认静音
  maxResolution?: string;           // 最大分辨率限制
  playbackSpeed: number;            // 默认播放速度
}

/**
 * 通知偏好设置接口
 */
export interface NotificationPreferences {
  enabled: boolean;                 // 是否启用通知
  newReleases: boolean;             // 新内容通知
  recommendations: boolean;         // 推荐通知
  updates: boolean;                 // 更新通知
  promotions: boolean;              // 促销通知
  email: boolean;                   // 邮件通知
  push: boolean;                    // 推送通知
  frequency: 'immediate' | 'daily' | 'weekly'; // 通知频率
  categories?: string[];            // 关注的分类
}

/**
 * 隐私偏好设置接口
 */
export interface PrivacyPreferences {
  profileVisible: boolean;          // 个人资料是否可见
  watchHistoryVisible: boolean;     // 观看历史是否可见
  favoritesVisible: boolean;        // 收藏是否可见
  shareData: boolean;               // 是否允许分享数据用于改进服务
  targetedAds: boolean;             // 是否允许定向广告
  dataRetention?: number;           // 数据保留期限（天）
  analytics: boolean;               // 是否启用分析
}

/**
 * 界面偏好设置接口
 */
export interface InterfacePreferences {
  layout: 'grid' | 'list';          // 内容布局
  gridColumns: number;              // 网格列数
  showRatings: boolean;             // 是否显示评分
  showDescriptions: boolean;        // 是否显示描述
  posterSize: 'small' | 'medium' | 'large'; // 海报大小
  autoplayTrailers: boolean;        // 是否自动播放预告片
  defaultTab: string;               // 默认标签页
  displayMode: 'poster' | 'backdrop' | 'both'; // 显示模式
}

/**
 * 家长控制偏好设置接口
 */
export interface ParentalControlPreferences {
  enabled: boolean;                 // 是否启用家长控制
  pin: string;                      // PIN码（加密存储）
  contentRating: string;            // 内容分级限制
  hideAdultContent: boolean;        // 是否隐藏成人内容
  restrictPurchases: boolean;       // 是否限制购买
  viewingTimeLimit?: number;        // 每日观看时间限制（分钟）
  allowedCategories?: string[];     // 允许的内容分类
}

/**
 * 推荐偏好设置接口
 */
export interface RecommendationPreferences {
  enabled: boolean;                 // 是否启用推荐
  preferredGenres?: string[];       // 偏好的类型
  preferredDirectors?: string[];    // 偏好的导演
  preferredActors?: string[];       // 偏好的演员
  dislikedGenres?: string[];        // 不喜欢的类型
  excludeWatched: boolean;          // 是否排除已观看内容
  refreshFrequency?: number;        // 推荐刷新频率（小时）
}

/**
 * 用户个人资料更新请求参数接口
 */
export interface UpdateProfileRequest {
  nickname?: string;                // 昵称
  avatarUrl?: string;               // 头像URL
  gender?: 'male' | 'female' | 'other'; // 性别
  birthDate?: string;               // 出生日期
  country?: string;                 // 国家/地区
  language?: string;                // 语言偏好
  bio?: string;                     // 个人简介
}

/**
 * 更新偏好设置请求参数接口
 */
export interface UpdatePreferencesRequest {
  theme?: 'light' | 'dark' | 'auto'; // 主题设置
  language?: string;                // 语言设置
  subtitles?: Partial<SubtitlePreferences>; // 字幕设置
  playback?: Partial<PlaybackPreferences>; // 播放设置
  notification?: Partial<NotificationPreferences>; // 通知设置
  privacy?: Partial<PrivacyPreferences>; // 隐私设置
  interface?: Partial<InterfacePreferences>; // 界面设置
  parental?: Partial<ParentalControlPreferences>; // 家长控制设置
  recommendations?: Partial<RecommendationPreferences>; // 推荐设置
  custom?: Record<string, any>;     // 自定义偏好设置
}

/**
 * 刷新令牌请求参数接口
 */
export interface RefreshTokenRequest {
  refreshToken: string;             // 刷新令牌
  deviceId?: string;                // 设备ID
}

/**
 * 注销请求参数接口
 */
export interface LogoutRequest {
  token?: string;                   // 当前令牌
  deviceId?: string;                // 设备ID
  allDevices?: boolean;             // 是否注销所有设备
}

/**
 * 设备会话接口
 */
export interface DeviceSession {
  id: string;                       // 会话ID
  deviceId: string;                 // 设备ID
  deviceName: string;               // 设备名称
  deviceType: string;               // 设备类型
  os: string;                       // 操作系统
  loginAt: number;                  // 登录时间
  lastActiveAt: number;             // 最后活跃时间
  ipAddress?: string;               // IP地址
  location?: string;                // 位置信息
  isCurrent: boolean;               // 是否当前设备
}

/**
 * 设备会话列表响应接口
 */
export interface DeviceSessionsResponseData {
  sessions: DeviceSession[];        // 设备会话列表
  total: number;                    // 总数
  currentSessionId?: string;        // 当前会话ID
}

/**
 * 用户统计信息接口
 */
export interface UserStats {
  totalWatchTime: number;           // 总观看时长（分钟）
  favoriteCount: number;            // 收藏数量
  historyCount: number;             // 观看历史数量
  watchedMovies: number;            // 已观看电影数量
  watchedEpisodes: number;          // 已观看剧集数量
  averageRating?: number;           // 平均评分
  watchProgress?: number;           // 总观看进度
  genreDistribution?: Record<string, number>; // 类型分布
  activeDays?: number;              // 活跃天数
  currentStreak?: number;           // 当前连续活跃天数
  longestStreak?: number;           // 最长连续活跃天数
}

/**
 * 认证API响应
 */
export type AuthApiResponse = ApiResponse<AuthResponseData>;

/**
 * 用户信息API响应
 */
export type UserInfoApiResponse = ApiResponse<UserInfo>;

/**
 * 用户偏好设置API响应
 */
export type UserPreferencesApiResponse = ApiResponse<UserPreferences>;

/**
 * 设备会话API响应
 */
export type DeviceSessionsApiResponse = ApiResponse<DeviceSessionsResponseData>;

/**
 * 用户统计信息API响应
 */
export type UserStatsApiResponse = ApiResponse<UserStats>;

/**
 * 用户相关的工具方法
 */
export class UserUtils {
  /**
   * 获取用户显示名称
   */
  static getDisplayName(user: UserInfo): string {
    return user.nickname || user.username || '用户';
  }

  /**
   * 获取用户年龄
   */
  static getAge(birthDate?: string): number | null {
    if (!birthDate) {
      return null;
    }
    const birth = new Date(birthDate);
    const today = new Date();
    let age = today.getFullYear() - birth.getFullYear();
    const monthDiff = today.getMonth() - birth.getMonth();
    
    if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birth.getDate())) {
      age--;
    }
    
    return age >= 0 ? age : null;
  }

  /**
   * 验证密码强度
   */
  static validatePasswordStrength(password: string): {
    isValid: boolean;
    strength: 'weak' | 'medium' | 'strong';
    issues: string[];
  } {
    const issues: string[] = [];
    
    if (password.length < 6) {
      issues.push('密码长度至少为6个字符');
    } else if (password.length > 50) {
      issues.push('密码长度不能超过50个字符');
    }
    
    const hasLower = /[a-z]/.test(password);
    const hasUpper = /[A-Z]/.test(password);
    const hasNumber = /[0-9]/.test(password);
    const hasSpecial = /[!@#$%^&*(),.?":{}|<>]/.test(password);
    
    const charTypes = [hasLower, hasUpper, hasNumber, hasSpecial].filter(Boolean).length;
    
    // 计算密码强度
    let strength: 'weak' | 'medium' | 'strong' = 'weak';
    if (password.length >= 8 && charTypes >= 3) {
      strength = 'strong';
    } else if (password.length >= 6 && charTypes >= 2) {
      strength = 'medium';
    }
    
    return {
      isValid: issues.length === 0 && password.length >= 6,
      strength,
      issues
    };
  }

  /**
   * 验证邮箱格式
   */
  static isValidEmail(email: string): boolean {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  }

  /**
   * 验证手机号格式（简单验证，实际应根据国家/地区调整）
   */
  static isValidPhone(phone: string): boolean {
    // 简单的手机号验证，可根据需要增强
    const phoneRegex = /^[+]?[(]?[0-9]{1,4}[)]?[-\s.]?[0-9]{1,4}[-\s.]?[0-9]{1,9}$/;
    return phoneRegex.test(phone);
  }

  /**
   * 获取订阅状态的显示文本
   */
  static getSubscriptionStatusText(status?: 'free' | 'premium' | 'expired'): string {
    const statusMap: Record<string, string> = {
      'free': '免费用户',
      'premium': '高级会员',
      'expired': '会员已过期'
    };
    return statusMap[status || 'free'] || '免费用户';
  }

  /**
   * 获取角色的显示文本
   */
  static getRoleDisplayName(role: UserRole): string {
    const roleMap: Record<UserRole, string> = {
      [UserRole.ADMIN]: '管理员',
      [UserRole.USER]: '普通用户',
      [UserRole.VIP]: 'VIP用户',
      [UserRole.GUEST]: '访客',
      [UserRole.BANNED]: '已禁用',
      [UserRole.SUBSCRIBER]: '订阅用户'
    };
    return roleMap[role] || '未知角色';
  }

  /**
   * 格式化观看时长
   */
  static formatWatchTime(minutes: number): string {
    if (minutes < 60) {
      return `${minutes}分钟`;
    }
    const hours = Math.floor(minutes / 60);
    const mins = minutes % 60;
    if (mins === 0) {
      return `${hours}小时`;
    }
    return `${hours}小时${mins}分钟`;
  }

  /**
   * 创建默认的用户偏好设置
   */
  static createDefaultPreferences(): UserPreferences {
    return {
      theme: 'auto',
      language: 'zh-CN',
      subtitles: {
        enabled: true,
        language: 'zh-CN',
        size: 'medium',
        color: '#FFFFFF',
        backgroundColor: 'rgba(0,0,0,0.5)',
        font: 'Arial',
        bold: false,
        position: 'bottom',
        delay: 0
      },
      playback: {
        autoPlay: true,
        autoNext: true,
        defaultQuality: '1080p',
        bandwidthSaving: false,
        rememberPosition: true,
        volume: 80,
        muted: false,
        playbackSpeed: 1.0
      },
      notification: {
        enabled: true,
        newReleases: true,
        recommendations: true,
        updates: true,
        promotions: false,
        email: true,
        push: true,
        frequency: 'immediate'
      },
      privacy: {
        profileVisible: false,
        watchHistoryVisible: false,
        favoritesVisible: false,
        shareData: true,
        targetedAds: true,
        analytics: true
      },
      interface: {
        layout: 'grid',
        gridColumns: 3,
        showRatings: true,
        showDescriptions: false,
        posterSize: 'medium',
        autoplayTrailers: false,
        defaultTab: 'home',
        displayMode: 'poster'
      },
      parental: {
        enabled: false,
        pin: '',
        contentRating: 'all',
        hideAdultContent: true,
        restrictPurchases: true
      },
      recommendations: {
        enabled: true,
        excludeWatched: true
      },
      updatedAt: Date.now()
    };
  }
}