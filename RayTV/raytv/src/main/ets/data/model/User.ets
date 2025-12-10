// User - 用户实体�?import Logger from '../../common/util/Logger';
import DateUtil from '../../common/util/DateUtil';

const TAG = 'User';

/**
 * 用户角色枚举
 */
export enum UserRole {
  GUEST,      // 访客
  REGULAR,    // 普通用�?  VIP,        // VIP用户
  ADMIN       // 管理�?}

/**
 * 用户偏好设置接口
 */
export interface UserPreferences {
  theme?: 'light' | 'dark' | 'system';  // 主题偏好
  language?: string;                    // 语言偏好
  playerDefaultQuality?: string;        // 默认播放质量
  autoplay?: boolean;                   // 是否自动播放
  subtitleEnabled?: boolean;            // 是否启用字幕
  defaultSubtitleLanguage?: string;     // 默认字幕语言
  audioLanguage?: string;               // 音频语言
  maxConcurrentDownloads?: number;      // 最大并发下载数
  parentalControlEnabled?: boolean;     // 是否启用家长控制
  parentalControlLevel?: number;        // 家长控制级别
  searchHistoryEnabled?: boolean;       // 是否保存搜索历史
  playbackSpeed?: number;               // 默认播放速度
  // 移除索引签名，符合ArkTS规范
}

/**
 * 设备信息接口
 */
export interface DeviceInfo {
  deviceId: string;         // 设备唯一标识
  deviceName: string;       // 设备名称
  deviceType: string;       // 设备类型
  lastActiveTime: string;   // 最后活跃时�?  osVersion?: string;       // 操作系统版本
  appVersion?: string;      // 应用版本
  ipAddress?: string;       // IP地址（可选，用于显示�?}

/**
 * 用户设置类型定义
 * 替换索引签名为具体属性，符合ArkTS规范
 */
export interface UserSettings {
  // 预定义常见设置项，避免使用索引签�?  notificationsEnabled?: boolean;
  autoPlayEnabled?: boolean;
  defaultLanguage?: string;
  themePreference?: string;
  subtitleSize?: number;
  // 其他设置使用Map存储，提供类型安全的访问方法
}

/**
 * 用户序列化数据接�? * 定义toSerializable方法返回的对象结�? */
export interface UserSerializableData {
  id: string | null;
  username: string | null;
  nickname: string | null;
  email: string | null;
  avatarUrl: string | null;
  role: number;
  preferences: UserPreferences | null;
  lastLoginTime: string | null;
  registrationDate: string | null;
  activeDevices: DeviceInfo[] | null;
  isVerified: boolean;
  status: string;
  subscriptionEndDate: string | null;
  watchHistoryEnabled: boolean;
  favoritesEnabled: boolean;
  totalWatchTime: number;
  settings: UserSettings | null;
}

/**
 * 用户实体�? * 定义用户的基本信息和相关操作
 */
export default class User {
  id: string;                    // 用户唯一标识
  username: string;              // 用户�?  nickname?: string;             // 昵称
  email?: string;                // 邮箱
  avatarUrl?: string;            // 头像URL
  role: UserRole;                // 用户角色
  preferences?: UserPreferences; // 用户偏好设置
  lastLoginTime?: string;        // 最后登录时�?  registrationDate?: string;     // 注册日期
  activeDevices?: DeviceInfo[];  // 活跃设备列表
  isVerified?: boolean;          // 是否已验�?  status?: 'active' | 'inactive' | 'suspended'; // 账户状�?  subscriptionEndDate?: string;  // 订阅到期日期
  watchHistoryEnabled?: boolean; // 是否启用观看历史
  favoritesEnabled?: boolean;    // 是否启用收藏
  totalWatchTime?: number;       // 总观看时长（分钟�?  settings?: UserSettings; // 其他设置

  /**
   * 构造函�?   */
  constructor(data: Partial<User>) {
    // 创建局部变量存储ID和用户名，避免直接使用User类作为对�?    const defaultId = `user_${DateUtil.getTimestamp()}_${Math.random().toString(36).substr(2, 9)}`;
    const defaultUsername = `user_${Math.random().toString(36).substr(2, 8)}`;
    
    // 修复undefined赋值问题，使用??运算符替代||
    this.id = data.id ?? defaultId;
    this.username = data.username ?? defaultUsername;
    this.nickname = data.nickname ?? this.username;
    this.email = data.email;
    this.avatarUrl = data.avatarUrl;
    this.role = data.role ?? UserRole.REGULAR;
    this.preferences = data.preferences ?? this.getDefaultPreferences();
    this.lastLoginTime = data.lastLoginTime ?? DateUtil.format(new Date());
    this.registrationDate = data.registrationDate ?? DateUtil.format(new Date());
    this.activeDevices = data.activeDevices ?? [];
    this.isVerified = data.isVerified ?? false;
    this.status = data.status ?? 'active';
    this.subscriptionEndDate = data.subscriptionEndDate;
    this.watchHistoryEnabled = data.watchHistoryEnabled !== undefined ? data.watchHistoryEnabled : true;
    this.favoritesEnabled = data.favoritesEnabled !== undefined ? data.favoritesEnabled : true;
    this.totalWatchTime = data.totalWatchTime ?? 0;
    
    // 安全处理settings对象，避免类作为对象使用和直接类型断言
    if (data.settings && typeof data.settings === 'object' && !Array.isArray(data.settings)) {
      // 创建一个新的符合UserSettings接口的对�?      this.settings = this.createSafeUserSettings(data.settings);
    } else {
      // 使用明确的空对象，不进行类型断言
      this.settings = {};
    }
  }

  /**
   * 获取默认偏好设置
   * @returns 默认偏好设置
   */
  private getDefaultPreferences(): UserPreferences {
    const result: UserPreferences = {} as UserPreferences;
    result.theme = 'system';
    result.language = 'zh-CN';
    result.playerDefaultQuality = 'HD';
    result.autoplay = true;
    result.subtitleEnabled = false;
    result.defaultSubtitleLanguage = 'zh-CN';
    result.audioLanguage = 'zh-CN';
    result.maxConcurrentDownloads = 3;
    result.parentalControlEnabled = false;
    result.parentalControlLevel = 0;
    result.searchHistoryEnabled = true;
    result.playbackSpeed = 1.0;
    return result;
  }

  /**
   * 合并偏好设置（替代Object.assign�?   * @param base 基础偏好设置
   * @param updates 要更新的偏好设置
   * @returns 合并后的偏好设置
   */
  private mergePreferences(base: UserPreferences, updates: Partial<UserPreferences> | null | undefined): UserPreferences {
    // 安全检查更新对�?    if (!updates || typeof updates !== 'object') {
      // 手动复制属性，替代展开操作�?      return {
        theme: base.theme,
        language: base.language,
        playerDefaultQuality: base.playerDefaultQuality,
        autoplay: base.autoplay,
        subtitleEnabled: base.subtitleEnabled,
        defaultSubtitleLanguage: base.defaultSubtitleLanguage,
        audioLanguage: base.audioLanguage,
        maxConcurrentDownloads: base.maxConcurrentDownloads,
        parentalControlEnabled: base.parentalControlEnabled,
        parentalControlLevel: base.parentalControlLevel,
        searchHistoryEnabled: base.searchHistoryEnabled,
        playbackSpeed: base.playbackSpeed
      };
    }
    
    // 确保基础偏好设置存在
    if (!base || typeof base !== 'object') {
      return this.getDefaultPreferences();
    }
    
    // 不使用展开操作符，手动创建并复制属�?    const result: UserPreferences = {
      theme: base.theme,
      language: base.language,
      playerDefaultQuality: base.playerDefaultQuality,
      autoplay: base.autoplay,
      subtitleEnabled: base.subtitleEnabled,
      defaultSubtitleLanguage: base.defaultSubtitleLanguage,
      audioLanguage: base.audioLanguage,
      maxConcurrentDownloads: base.maxConcurrentDownloads,
      parentalControlEnabled: base.parentalControlEnabled,
      parentalControlLevel: base.parentalControlLevel,
      searchHistoryEnabled: base.searchHistoryEnabled,
      playbackSpeed: base.playbackSpeed
    };
    
    // 手动合并每个属�?    if (updates.theme !== undefined) result.theme = updates.theme;
    if (updates.language !== undefined) result.language = updates.language;
    if (updates.playerDefaultQuality !== undefined) result.playerDefaultQuality = updates.playerDefaultQuality;
    if (updates.autoplay !== undefined) result.autoplay = updates.autoplay;
    if (updates.subtitleEnabled !== undefined) result.subtitleEnabled = updates.subtitleEnabled;
    if (updates.defaultSubtitleLanguage !== undefined) result.defaultSubtitleLanguage = updates.defaultSubtitleLanguage;
    if (updates.audioLanguage !== undefined) result.audioLanguage = updates.audioLanguage;
    if (updates.maxConcurrentDownloads !== undefined) result.maxConcurrentDownloads = updates.maxConcurrentDownloads;
    if (updates.parentalControlEnabled !== undefined) result.parentalControlEnabled = updates.parentalControlEnabled;
    if (updates.parentalControlLevel !== undefined) result.parentalControlLevel = updates.parentalControlLevel;
    if (updates.searchHistoryEnabled !== undefined) result.searchHistoryEnabled = updates.searchHistoryEnabled;
    if (updates.playbackSpeed !== undefined) result.playbackSpeed = updates.playbackSpeed;
    
    return result;
  }

  /**
   * 更新用户偏好设置
   * @param preferences 要更新的偏好设置
   */
  public updatePreferences(preferences: Partial<UserPreferences>): void {
    if (!this.preferences) {
      this.preferences = this.getDefaultPreferences();
    }
    this.preferences = this.mergePreferences(this.preferences, preferences);
  }

  /**
   * 获取用户显示名称（优先使用昵称）
   * @returns 显示名称
   */
  public getDisplayName(): string {
    return this.nickname || this.username || '未命名用�?;
  }

  /**
   * 检查用户是否为VIP
   * @returns 是否为VIP
   */
  public isVip(): boolean {
    if (this.role === UserRole.ADMIN || this.role === UserRole.VIP) {
      // 如果是VIP或管理员角色，进一步检查订阅是否过�?      if (!this.subscriptionEndDate) {
        return true; // 没有订阅期限的VIP永久有效
      }
      
      const now = new Date();
      const endDate = new Date(this.subscriptionEndDate);
      return now <= endDate;
    }
    return false;
  }

  /**
   * 获取用户角色的文本描�?   * @returns 角色描述
   */
  public getRoleDescription(): string {
    switch (this.role) {
      case UserRole.ADMIN:
        return '管理�?;
      case UserRole.VIP:
        return this.isVip() ? 'VIP用户' : 'VIP已过�?;
      case UserRole.REGULAR:
        return '普通用�?;
      case UserRole.GUEST:
        return '访客';
      default:
        return '未知角色';
    }
  }

  /**
   * 更新登录时间
   */
  public updateLastLoginTime(): void {
    this.lastLoginTime = DateUtil.format(new Date());
  }

  /**
   * 添加活跃设备
   * @param deviceInfo 设备信息
   */
  public addActiveDevice(deviceInfo: DeviceInfo): void {
    if (!this.activeDevices) {
      this.activeDevices = [];
    }

    // 检查设备是否已存在
    const existingIndex = this.activeDevices.findIndex(device => device.deviceId === deviceInfo.deviceId);
    
    if (existingIndex >= 0) {
      // 更新现有设备的信�?      const existingDevice = this.activeDevices[existingIndex];
      this.activeDevices[existingIndex] = {
        deviceId: deviceInfo.deviceId || existingDevice.deviceId,
        deviceName: deviceInfo.deviceName || existingDevice.deviceName,
        deviceType: deviceInfo.deviceType || existingDevice.deviceType,
        lastActiveTime: DateUtil.format(new Date()),
        osVersion: deviceInfo.osVersion || existingDevice.osVersion,
        appVersion: deviceInfo.appVersion || existingDevice.appVersion,
        ipAddress: deviceInfo.ipAddress || existingDevice.ipAddress
      };
    } else {
      // 添加新设�?      const newDevice: DeviceInfo = {
        deviceId: deviceInfo.deviceId,
        deviceName: deviceInfo.deviceName,
        deviceType: deviceInfo.deviceType,
        lastActiveTime: DateUtil.format(new Date()),
        osVersion: deviceInfo.osVersion,
        appVersion: deviceInfo.appVersion,
        ipAddress: deviceInfo.ipAddress
      };
      this.activeDevices.push(newDevice);
    }
  }

  /**
   * 移除活跃设备
   * @param deviceId 设备ID
   * @returns 是否成功移除
   */
  public removeActiveDevice(deviceId: string): boolean {
    if (!this.activeDevices) {
      return false;
    }

    const initialLength = this.activeDevices.length;
    this.activeDevices = this.activeDevices.filter(device => device.deviceId !== deviceId);
    return this.activeDevices.length < initialLength;
  }

  /**
   * 更新总观看时�?   * @param minutes 增加的分钟数
   */
  public updateWatchTime(minutes: number): void {
    this.totalWatchTime = (this.totalWatchTime || 0) + minutes;
  }

  /**
   * 获取格式化的总观看时�?   * @returns 格式化的时长字符�?   */
  public getFormattedWatchTime(): string {
    const totalMinutes = this.totalWatchTime || 0;
    const hours = Math.floor(totalMinutes / 60);
    const minutes = totalMinutes % 60;

    if (hours > 0) {
      return `${hours}小时${minutes > 0 ? ` ${minutes}分钟` : ''}`;
    }
    return `${minutes}分钟`;
  }

  /**
   * 检查用户是否有权限访问特定功能
   * @param permission 权限标识
   * @returns 是否有权�?   */
  public hasPermission(permission: string): boolean {
    // 基础权限映射 - 使用switch语句替代索引访问
    let userPermissions: string[] = [];
    
    switch (this.role) {
      case UserRole.GUEST:
        userPermissions = ['basic_view', 'limited_search'];
        break;
      case UserRole.REGULAR:
        userPermissions = ['basic_view', 'full_search', 'watch_history', 'favorites', 'download_basic'];
        break;
      case UserRole.VIP:
        userPermissions = ['basic_view', 'full_search', 'watch_history', 'favorites', 'download_full', 'hd_content', 'ad_free', 'exclusive_content'];
        break;
      case UserRole.ADMIN:
        userPermissions = ['*'];
        break;
      default:
        userPermissions = [];
    }
    
    // 管理员拥有所有权�?    if (userPermissions.includes('*')) {
      return true;
    }

    // VIP权限检查：如果是VIP但订阅已过期，降级为普通用户权�?    if (this.role === UserRole.VIP && !this.isVip()) {
      const regularPermissions = ['basic_view', 'full_search', 'watch_history', 'favorites', 'download_basic'];
      return regularPermissions.includes(permission);
    }

    return userPermissions.includes(permission);
  }

  /**
   * 设置用户状�?   * @param status 新状�?   */
  public setStatus(status: 'active' | 'inactive' | 'suspended'): void {
    this.status = status;
  }

  /**
   * 检查用户账户是否有�?   * @returns 是否有效
   */
  public isAccountActive(): boolean {
    return this.status === 'active' && 
           (!this.isVip() || (this.isVip() && this.status === 'active'));
  }

  /**
   * 序列化对象（用于存储�?   * @returns 序列化后的对�?   */
  public toSerializable(): UserSerializableData {
    // 确保所有属性都不是undefined，使用null替代undefined
    const result: UserSerializableData = {
      id: this.id || null,
      username: this.username || null,
      nickname: this.nickname || null,
      email: this.email || null,
      avatarUrl: this.avatarUrl || null,
      role: this.role || 0,
      preferences: this.preferences || null,
      lastLoginTime: this.lastLoginTime || null,
      registrationDate: this.registrationDate || null,
      activeDevices: this.activeDevices || null,
      isVerified: this.isVerified || false,
      status: this.status || 'active',
      subscriptionEndDate: this.subscriptionEndDate || null,
      watchHistoryEnabled: this.watchHistoryEnabled || false,
      favoritesEnabled: this.favoritesEnabled || false,
      totalWatchTime: this.totalWatchTime || 0,
      settings: this.settings || null
    };
    return result;
  }

  /**
   * 从序列化数据创建对象
   * @param data 序列化数�?   * @returns User对象
   */
  public static fromSerializable(data: UserSerializableData): User {
    // 准备构造函数参�?    const userId = typeof data.id === 'string' ? data.id : `user_${DateUtil.getTimestamp()}_${Math.random().toString(36).substr(2, 9)}`;
    const userName = typeof data.username === 'string' ? data.username : `user_${Math.random().toString(36).substr(2, 8)}`;
    
    // 使用构造函数直接创建实�?    const instance = new User({
      id: userId,
      username: userName,
      nickname: typeof data.nickname === 'string' ? data.nickname : undefined,
      email: typeof data.email === 'string' ? data.email : undefined,
      avatarUrl: typeof data.avatarUrl === 'string' ? data.avatarUrl : undefined,
      role: typeof data.role === 'number' ? data.role : UserRole.REGULAR,
      lastLoginTime: typeof data.lastLoginTime === 'string' ? data.lastLoginTime : DateUtil.format(new Date()),
      registrationDate: typeof data.registrationDate === 'string' ? data.registrationDate : DateUtil.format(new Date()),
      isVerified: typeof data.isVerified === 'boolean' ? data.isVerified : false,
      status: typeof data.status === 'string' ? 
        (['active', 'inactive', 'suspended'].includes(data.status) ? data.status as 'active' | 'inactive' | 'suspended' : 'active') : 
        'active',
      subscriptionEndDate: typeof data.subscriptionEndDate === 'string' ? data.subscriptionEndDate : undefined,
      watchHistoryEnabled: typeof data.watchHistoryEnabled === 'boolean' ? data.watchHistoryEnabled : true,
      favoritesEnabled: typeof data.favoritesEnabled === 'boolean' ? data.favoritesEnabled : true,
      totalWatchTime: typeof data.totalWatchTime === 'number' ? data.totalWatchTime : 0
    });
    
    // 处理preferences
    if (data.preferences && typeof data.preferences === 'object' && !Array.isArray(data.preferences)) {
      instance.preferences = User.safeCastToUserPreferences(data.preferences);
    } else {
      instance.preferences = instance.getDefaultPreferences();
    }
    
    // 处理activeDevices
    if (Array.isArray(data.activeDevices)) {
      instance.activeDevices = [];
      for (let i = 0; i < data.activeDevices.length; i++) {
        const item = data.activeDevices[i];
        if (item && typeof item === 'object' && !Array.isArray(item)) {
          // 使用类型保护确保item是DeviceInfo类型
          if ('deviceId' in item && 'deviceName' in item && 'deviceType' in item && 'lastActiveTime' in item) {
            const deviceItem = item as DeviceInfo;
            // 创建DeviceInfo对象，使用显式类型初始化
            const deviceInfo: DeviceInfo = {
              deviceId: typeof deviceItem.deviceId === 'string' ? deviceItem.deviceId : '',
              deviceName: typeof deviceItem.deviceName === 'string' ? deviceItem.deviceName : '',
              deviceType: typeof deviceItem.deviceType === 'string' ? deviceItem.deviceType : '',
              lastActiveTime: typeof deviceItem.lastActiveTime === 'string' ? deviceItem.lastActiveTime : ''
            };
            instance.activeDevices.push(deviceInfo);
          }
        }
      }
    } else {
      instance.activeDevices = [];
    }
    
    // 处理settings
    if (data.settings && typeof data.settings === 'object' && !Array.isArray(data.settings)) {
      // 创建UserSettings对象，使用显式类型初始化
      const userSettings: UserSettings = {
        notificationsEnabled: typeof data.settings.notificationsEnabled === 'boolean' ? data.settings.notificationsEnabled : undefined,
        autoPlayEnabled: typeof data.settings.autoPlayEnabled === 'boolean' ? data.settings.autoPlayEnabled : undefined,
        defaultLanguage: typeof data.settings.defaultLanguage === 'string' ? data.settings.defaultLanguage : undefined,
        themePreference: typeof data.settings.themePreference === 'string' ? data.settings.themePreference : undefined,
        subtitleSize: typeof data.settings.subtitleSize === 'number' ? data.settings.subtitleSize : undefined
      };
      instance.settings = userSettings;
    } else {
      instance.settings = {
        notificationsEnabled: undefined,
        autoPlayEnabled: undefined,
        defaultLanguage: undefined,
        themePreference: undefined,
        subtitleSize: undefined
      };
    }
    
    return instance;
  }
  
  /**
   * 安全地将对象转换为UserPreferences类型
   * @param obj 要转换的对象
   * @returns 转换后的UserPreferences对象
   */
  private static safeCastToUserPreferences(obj: Record<string, string | number | boolean | null>): UserPreferences {
    // 创建符合UserPreferences接口的对�?    const result: UserPreferences = {} as UserPreferences;
    
    // 安全地设置每个属�?    if (typeof obj.theme === 'string' && ['light', 'dark', 'system'].includes(obj.theme)) {
      result.theme = obj.theme as 'light' | 'dark' | 'system';
    }
    if (typeof obj.language === 'string') {
      result.language = obj.language;
    }
    if (typeof obj.playerDefaultQuality === 'string') {
      result.playerDefaultQuality = obj.playerDefaultQuality;
    }
    if (typeof obj.autoplay === 'boolean') {
      result.autoplay = obj.autoplay;
    }
    if (typeof obj.subtitleEnabled === 'boolean') {
      result.subtitleEnabled = obj.subtitleEnabled;
    }
    if (typeof obj.defaultSubtitleLanguage === 'string') {
      result.defaultSubtitleLanguage = obj.defaultSubtitleLanguage;
    }
    if (typeof obj.audioLanguage === 'string') {
      result.audioLanguage = obj.audioLanguage;
    }
    if (typeof obj.maxConcurrentDownloads === 'number') {
      result.maxConcurrentDownloads = obj.maxConcurrentDownloads;
    }
    if (typeof obj.parentalControlEnabled === 'boolean') {
      result.parentalControlEnabled = obj.parentalControlEnabled;
    }
    if (typeof obj.parentalControlLevel === 'number') {
      result.parentalControlLevel = obj.parentalControlLevel;
    }
    if (typeof obj.searchHistoryEnabled === 'boolean') {
      result.searchHistoryEnabled = obj.searchHistoryEnabled;
    }
    if (typeof obj.playbackSpeed === 'number') {
      result.playbackSpeed = obj.playbackSpeed;
    }
    
    return result;
  }

  /**
   * 克隆UserPreferences对象
   * @param preferences 要克隆的UserPreferences对象
   * @returns 克隆后的对象
   */
  private static cloneUserPreferences(preferences: UserPreferences): UserPreferences {
    const cloned: UserPreferences = {
      theme: preferences.theme,
      language: preferences.language,
      playerDefaultQuality: preferences.playerDefaultQuality,
      autoplay: preferences.autoplay,
      subtitleEnabled: preferences.subtitleEnabled,
      defaultSubtitleLanguage: preferences.defaultSubtitleLanguage,
      audioLanguage: preferences.audioLanguage,
      maxConcurrentDownloads: preferences.maxConcurrentDownloads,
      parentalControlEnabled: preferences.parentalControlEnabled,
      parentalControlLevel: preferences.parentalControlLevel,
      searchHistoryEnabled: preferences.searchHistoryEnabled,
      playbackSpeed: preferences.playbackSpeed
    };
    return cloned;
  }

  /**
   * 克隆DeviceInfo数组
   * @param devices 要克隆的DeviceInfo数组
   * @returns 克隆后的数组
   */
  private static cloneActiveDevices(devices: DeviceInfo[]): DeviceInfo[] {
    const cloned: DeviceInfo[] = [];
    for (let i = 0; i < devices.length; i++) {
      const device = devices[i];
      cloned.push({
        deviceId: device.deviceId,
        deviceName: device.deviceName,
        deviceType: device.deviceType,
        lastActiveTime: device.lastActiveTime,
        osVersion: device.osVersion,
        appVersion: device.appVersion,
        ipAddress: device.ipAddress
      });
    }
    return cloned;
  }

  /**
   * 克隆UserSettings对象
   * @param settings 要克隆的UserSettings对象
   * @returns 克隆后的对象
   */
  private static cloneUserSettings(settings: UserSettings): UserSettings {
    const cloned: UserSettings = {
      notificationsEnabled: settings.notificationsEnabled,
      autoPlayEnabled: settings.autoPlayEnabled,
      defaultLanguage: settings.defaultLanguage,
      themePreference: settings.themePreference,
      subtitleSize: settings.subtitleSize
    };
    return cloned;
  }
  
  /**
   * 安全地创建符合UserSettings接口的对�?   * 避免类作为对象使用的警告
   * @param settingsObj 输入的settings对象
   * @returns 安全的UserSettings对象
   */
  private createSafeUserSettings(settingsObj: Record<string, string | number | boolean | null>): UserSettings {
    const result: UserSettings = {
      notificationsEnabled: undefined,
      autoPlayEnabled: undefined,
      defaultLanguage: undefined,
      themePreference: undefined,
      subtitleSize: undefined
    };
    
    // 只复制UserSettings接口中定义的有效属�?    if (typeof settingsObj.notificationsEnabled === 'boolean') {
      result.notificationsEnabled = settingsObj.notificationsEnabled;
    }
    if (typeof settingsObj.autoPlayEnabled === 'boolean') {
      result.autoPlayEnabled = settingsObj.autoPlayEnabled;
    }
    if (typeof settingsObj.defaultLanguage === 'string') {
      result.defaultLanguage = settingsObj.defaultLanguage;
    }
    if (typeof settingsObj.themePreference === 'string') {
      result.themePreference = settingsObj.themePreference;
    }
    if (typeof settingsObj.subtitleSize === 'number') {
      result.subtitleSize = settingsObj.subtitleSize;
    }
    
    return result;
  }

  /**
   * 克隆User实例
   * @returns 克隆后的实例
   */
  public clone(): User {
    // 使用构造函数创建完整实例，避免空对象字面量
    const instance = new User({
      id: this.id,
      username: this.username,
      nickname: this.nickname,
      email: this.email,
      avatarUrl: this.avatarUrl,
      role: this.role,
      lastLoginTime: this.lastLoginTime,
      registrationDate: this.registrationDate,
      isVerified: this.isVerified,
      status: this.status,
      subscriptionEndDate: this.subscriptionEndDate,
      watchHistoryEnabled: this.watchHistoryEnabled,
      favoritesEnabled: this.favoritesEnabled,
      totalWatchTime: this.totalWatchTime
    });
    
    // 手动处理复杂类型属�?    instance.preferences = this.preferences ? User.cloneUserPreferences(this.preferences) : undefined;
    instance.activeDevices = this.activeDevices ? User.cloneActiveDevices(this.activeDevices) : undefined;
    instance.settings = this.settings ? User.cloneUserSettings(this.settings) : undefined;
    
    return instance;
  }
}

