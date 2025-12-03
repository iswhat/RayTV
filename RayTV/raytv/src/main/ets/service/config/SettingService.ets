// SettingService.ets - 设置服务
// 负责应用配置管理、主题设置、语言切换等功�?

import Logger from '../../common/util/Logger';
import StorageUtil from '../../common/util/StorageUtil';
import ConfigService from '../../service/config/ConfigService';
import UserService, { UserPreferences } from '../../service/user/UserService';
import DatabaseManager from '../../data/db/DatabaseManager';
import { BusinessError } from '@ohos.base';
import type { ApplicationInfo } from '@ohos.bundle.bundleManager';

// 常量定义
const TAG = 'SettingService';
const SETTINGS_STORAGE_KEY = 'app_settings';
const USER_SETTINGS_KEY_PREFIX = 'user_settings_';

// 设置类型枚举
export enum SettingType {
  APPLICATION = 0,     // 应用级设�?
  USER = 1,            // 用户级设�?
  DEVICE = 2,          // 设备级设�?
  CUSTOM = 3           // 自定义设�?
}

// 主题模式枚举
export enum ThemeMode {
  LIGHT = 0,           // 浅色模式
  DARK = 1,            // 深色模式
  AUTO = 2,            // 自动（跟随系统）
  SEPia = 3            // 护眼模式
}

// 语言代码枚举
export enum LanguageCode {
  SIMPLIFIED_CHINESE = 'zh_CN',
  TRADITIONAL_CHINESE = 'zh_TW',
  ENGLISH = 'en_US',
  JAPANESE = 'ja_JP',
  KOREAN = 'ko_KR',
  GERMAN = 'de_DE',
  FRENCH = 'fr_FR',
  SPANISH = 'es_ES'
}

// 播放质量枚举
export enum PlaybackQuality {
  LOW = 'low',         // 流畅
  MEDIUM = 'medium',   // 标清
  HIGH = 'high',       // 高清
  ULTRA_HIGH = 'uhd',  // 超清
  AUTO = 'auto'        // 自动
}

// 字幕大小枚举
export enum SubtitleSize {
  SMALL = 'small',     // �?
  MEDIUM = 'medium',   // �?
  LARGE = 'large',     // �?
  X_LARGE = 'xlarge'   // 超大
}

// 字幕样式枚举
export enum SubtitleStyle {
  NORMAL = 'normal',   // 普�?
  BOLD = 'bold',       // 粗体
  ITALIC = 'italic',   // 斜体
  SHADOWED = 'shadowed' // 阴影
}

// 网络类型枚举
export enum NetworkType {
  ALL = 0,             // 所有网�?
  WIFI_ONLY = 1,       // 仅WiFi
  MOBILE_ONLY = 2,     // 仅移动网�?
  NO_MOBILE_HIGH_SPEED = 3 // 非高速移动网�?
}

// 通知类型枚举
export enum NotificationCategory {
  ALL = 0,             // 所有通知
  UPDATES = 1,         // 更新通知
  RECOMMENDATIONS = 2, // 推荐通知
  LIVE = 3,            // 直播通知
  SYSTEM = 4           // 系统通知
}

// 家长控制级别枚举
export enum ParentalControlLevel {
  OFF = 0,             // 关闭
  G = 1,               // 一般观�?
  PG = 2,              // 建议家长指导
  PG_13 = 3,           // 13岁以�?
  R = 4,               // 限制�?
  NC_17 = 5            // 17岁以�?
}

// 设置项接�?
export interface SettingItem<T> {
  key: string;         // 设置键名
  value: T;            // 设置�?
  type: SettingType;   // 设置类型
  defaultValue: T;     // 默认�?
  description?: string; // 设置描述
  minValue?: number;   // 最小值（数值类型）
  maxValue?: number;   // 最大值（数值类型）
  options?: T[];       // 可选值列�?
  readOnly?: boolean;  // 是否只读
  requiresRestart?: boolean; // 是否需要重�?
  lastUpdated?: number; // 最后更新时�?
}

// 应用设置接口
export interface AppSettings {
  // 主题相关
  themeMode: ThemeMode;
  accentColor: string;
  darkThemeAccentColor: string;
  customTheme?: Record<string, string>;
  
  // 语言相关
  language: LanguageCode;
  autoDetectLanguage: boolean;
  
  // 播放相关
  defaultPlaybackQuality: PlaybackQuality;
  autoPlayNext: boolean;
  rememberPlaybackPosition: boolean;
  playbackSpeed: number;
  defaultVolume: number;
  
  // 字幕相关
  subtitleEnabled: boolean;
  subtitleLanguage: string;
  subtitleSize: SubtitleSize;
  subtitleStyle: SubtitleStyle;
  subtitleColor: string;
  subtitleBackgroundColor: string;
  
  // 存储相关
  downloadPath: string;
  cacheSizeLimit: number;
  autoClearCache: boolean;
  cacheClearInterval: number;
  
  // 网络相关
  networkTypeForPlayback: NetworkType;
  networkTypeForDownload: NetworkType;
  bandwidthSaver: boolean;
  preloadEnabled: boolean;
  preloadLimit: number;
  
  // 通知相关
  notificationsEnabled: boolean;
  notificationCategories: NotificationCategory[];
  pushEnabled: boolean;
  
  // 家长控制
  parentalControlEnabled: boolean;
  parentalControlLevel: ParentalControlLevel;
  parentalControlPin?: string;
  
  // 外观相关
  gridLayoutColumns: number;
  showFileExtensions: boolean;
  showHiddenFiles: boolean;
  defaultSortBy: string;
  defaultSortOrder: 'asc' | 'desc';
  
  // 设备相关
  enableHardwareAcceleration: boolean;
  enableDolbyAudio: boolean;
  enableHDR: boolean;
  screenTimeout: number;
  
  // 其他设置
  crashReportingEnabled: boolean;
  usageAnalyticsEnabled: boolean;
  backgroundPlayEnabled: boolean;
  startupPage: string;
  enableGestureControl: boolean;
}

// 设置组接�?
export interface SettingGroup {
  id: string;
  title: string;
  description?: string;
  settings: SettingItem<unknown>[];
  icon?: string;
}

// 设置变更事件接口
export interface SettingChangeEvent<T> {
  key: string;
  oldValue: T;
  newValue: T;
  timestamp: number;
  userInitiated: boolean;
}

// 默认应用设置
const DEFAULT_APP_SETTINGS: AppSettings = {
  // 主题相关
  themeMode: ThemeMode.DARK,
  accentColor: '#007AFF',
  darkThemeAccentColor: '#0A84FF',
  
  // 语言相关
  language: LanguageCode.SIMPLIFIED_CHINESE,
  autoDetectLanguage: true,
  
  // 播放相关
  defaultPlaybackQuality: PlaybackQuality.AUTO,
  autoPlayNext: true,
  rememberPlaybackPosition: true,
  playbackSpeed: 1.0,
  defaultVolume: 80,
  
  // 字幕相关
  subtitleEnabled: true,
  subtitleLanguage: 'zh_CN',
  subtitleSize: SubtitleSize.MEDIUM,
  subtitleStyle: SubtitleStyle.NORMAL,
  subtitleColor: '#FFFFFF',
  subtitleBackgroundColor: 'rgba(0, 0, 0, 0.5)',
  
  // 存储相关
  downloadPath: '',
  cacheSizeLimit: 1024 * 1024 * 1024 * 10, // 10GB
  autoClearCache: true,
  cacheClearInterval: 7 * 24 * 60 * 60 * 1000, // 7�?
  
  // 网络相关
  networkTypeForPlayback: NetworkType.ALL,
  networkTypeForDownload: NetworkType.WIFI_ONLY,
  bandwidthSaver: false,
  preloadEnabled: true,
  preloadLimit: 3,
  
  // 通知相关
  notificationsEnabled: true,
  notificationCategories: [
    NotificationCategory.UPDATES,
    NotificationCategory.RECOMMENDATIONS,
    NotificationCategory.LIVE,
    NotificationCategory.SYSTEM
  ],
  pushEnabled: true,
  
  // 家长控制
  parentalControlEnabled: false,
  parentalControlLevel: ParentalControlLevel.OFF,
  
  // 外观相关
  gridLayoutColumns: 3,
  showFileExtensions: false,
  showHiddenFiles: false,
  defaultSortBy: 'name',
  defaultSortOrder: 'asc',
  
  // 设备相关
  enableHardwareAcceleration: true,
  enableDolbyAudio: false,
  enableHDR: false,
  screenTimeout: 30000, // 30�?
  
  // 其他设置
  crashReportingEnabled: true,
  usageAnalyticsEnabled: true,
  backgroundPlayEnabled: false,
  startupPage: 'home',
  enableGestureControl: true
};

export default class SettingService {
  private static instance: SettingService;
  
  /**
   * 检查对象是否包含指定属�?
   */
  private hasOwnProperty(obj: object, key: string): boolean {
    return Object.getOwnPropertyNames(obj).includes(key);
  }
  
  /**
   * 获取对象的所有自身属性键
   */
  private getOwnPropertyKeys(obj: object): string[] {
    return Object.getOwnPropertyNames(obj);
  }
  private configService: ConfigService;
  private userService: UserService;
  private databaseManager: DatabaseManager;
  private appSettings: AppSettings = DEFAULT_APP_SETTINGS;
  private userSettings: Record<string, AppSettings> = {};
  private isInitialized: boolean = false;
  
  // 监听�?
  private generalListeners: Array<() => void> = [];
  private specificListeners: Map<string, Array<(event: SettingChangeEvent<unknown>) => void>> = new Map();
  private themeListeners: Array<(themeMode: ThemeMode, accentColor: string) => void> = [];
  private languageListeners: Array<(language: LanguageCode) => void> = [];

  /**
   * 获取单例实例
   */
  public static getInstance(): SettingService {
    if (!SettingService.instance) {
      SettingService.instance = new SettingService();
    }
    return SettingService.instance;
  }

  /**
   * 构造函�?
   */
  private constructor() {
    this.configService = ConfigService.getInstance();
    this.userService = UserService.getInstance();
    this.databaseManager = DatabaseManager.getInstance();
  }

  /**
   * 初始化设置服�?
   */
  public async initialize(): Promise<void> {
    if (this.isInitialized) {
      Logger.info(TAG, 'Setting service already initialized');
      return;
    }

    try {
      Logger.info(TAG, 'Initializing setting service...');
      
      // 加载默认下载路径
      this.appSettings.downloadPath = await this.getDefaultDownloadPath();
      
      // 加载应用全局设置
      await this.loadSettings();
      
      // 加载用户设置（如果已登录�?
      const currentUser = this.userService.getCurrentUser();
      if (currentUser && !this.userService.isGuest()) {
        await this.loadUserSettings(currentUser.id);
      }
      
      // 应用当前主题和语言
      await this.applyTheme();
      await this.applyLanguage();
      
      // 添加用户变更监听器，以便在用户切换时加载对应的设�?
      this.userService.addUserChangeListener(async (user) => {
        if (user && !this.userService.isGuest()) {
          await this.loadUserSettings(user.id);
          await this.applyTheme();
          await this.applyLanguage();
        }
      });
      
      this.isInitialized = true;
      Logger.info(TAG, 'Setting service initialized successfully');
    } catch (error) {
      Logger.error(TAG, `Failed to initialize setting service: ${error}`);
      // 使用默认设置继续
      this.appSettings = DEFAULT_APP_SETTINGS;
      this.isInitialized = true;
    }
  }

  /**
   * 获取默认下载路径
   */
  private async getDefaultDownloadPath(): Promise<string> {
    try {
      // 这里应该使用应用的文件系统API获取可用的下载目�?
      // 以下是模拟实�?
      return '/storage/emulated/0/Download/RayTV';
    } catch (error) {
      Logger.error(TAG, `Failed to get default download path: ${error}` instanceof Error ? `Failed to get default download path: ${error}` : new Error(String(`Failed to get default download path: ${error}` instanceof Error ? `Failed to get default download path: ${error}` instanceof Error ? `Failed to get default download path: ${error}` : new Error(String(`Failed to get default download path: ${error}` : new Error(String(`Failed to get default download path: ${error}` instanceof Error ? `Failed to get default download path: ${error}` : new Error(String(`Failed to get default download path: ${error}` instanceof Error ? `Failed to get default download path: ${error}` instanceof Error ? `Failed to get default download path: ${error}` : new Error(String(`Failed to get default download path: ${error}` instanceof Error ? `Failed to get default download path: ${error}` instanceof Error ? `Failed to get default download path: ${error}` : new Error(String(`Failed to get default download path: ${error}` : new Error(String(`Failed to get default download path: ${error}` instanceof Error ? `Failed to get default download path: ${error}` : new Error(String(`Failed to get default download path: ${error}` : new Error(String(`Failed to get default download path: ${error}` instanceof Error ? `Failed to get default download path: ${error}` : new Error(String(`Failed to get default download path: ${error}` instanceof Error ? `Failed to get default download path: ${error}` instanceof Error ? `Failed to get default download path: ${error}` : new Error(String(`Failed to get default download path: ${error}` : new Error(String(`Failed to get default download path: ${error}` instanceof Error ? `Failed to get default download path: ${error}` : new Error(String(`Failed to get default download path: ${error}`)))))));
      return '/tmp';
    }
  }

  /**
   * 加载应用设置
   */
  private async loadSettings(): Promise<void> {
    try {
      const savedSettings = await StorageUtil.getObject<AppSettings>(SETTINGS_STORAGE_KEY);
      if (savedSettings) {
        this.appSettings = { ...DEFAULT_APP_SETTINGS, ...savedSettings };
        Logger.info(TAG, 'App settings loaded from storage');
      }
    } catch (error) {
      Logger.error(TAG, `Failed to load app settings: ${error}`);
    }
  }

  /**
   * 加载用户设置
   */
  private async loadUserSettings(userId: string): Promise<void> {
    try {
      const userSettingsKey = `${USER_SETTINGS_KEY_PREFIX}${userId}`;
      const savedSettings = await StorageUtil.getObject<AppSettings>(userSettingsKey);
      
      if (savedSettings) {
        this.userSettings[userId] = { ...DEFAULT_APP_SETTINGS, ...savedSettings };
        Logger.info(TAG, `User settings loaded for user: ${userId}` instanceof Error ? ...savedSettings };
        Logger.info(TAG, `User settings loaded for user: ${userId}` : new Error(String(...savedSettings };
        Logger.info(TAG, `User settings loaded for user: ${userId}` instanceof Error ? ...savedSettings };
        Logger.info(TAG, `User settings loaded for user: ${userId}` instanceof Error ? ...savedSettings };
        Logger.info(TAG, `User settings loaded for user: ${userId}` : new Error(String(...savedSettings };
        Logger.info(TAG, `User settings loaded for user: ${userId}` : new Error(String(...savedSettings };
        Logger.info(TAG, `User settings loaded for user: ${userId}` instanceof Error ? ...savedSettings };
        Logger.info(TAG, `User settings loaded for user: ${userId}` : new Error(String(...savedSettings };
        Logger.info(TAG, `User settings loaded for user: ${userId}` instanceof Error ? ...savedSettings };
        Logger.info(TAG, `User settings loaded for user: ${userId}` instanceof Error ? ...savedSettings };
        Logger.info(TAG, `User settings loaded for user: ${userId}` : new Error(String(...savedSettings };
        Logger.info(TAG, `User settings loaded for user: ${userId}` instanceof Error ? ...savedSettings };
        Logger.info(TAG, `User settings loaded for user: ${userId}` instanceof Error ? ...savedSettings };
        Logger.info(TAG, `User settings loaded for user: ${userId}` : new Error(String(...savedSettings };
        Logger.info(TAG, `User settings loaded for user: ${userId}` : new Error(String(...savedSettings };
        Logger.info(TAG, `User settings loaded for user: ${userId}` instanceof Error ? ...savedSettings };
        Logger.info(TAG, `User settings loaded for user: ${userId}` : new Error(String(...savedSettings };
        Logger.info(TAG, `User settings loaded for user: ${userId}` : new Error(String(...savedSettings };
        Logger.info(TAG, `User settings loaded for user: ${userId}` instanceof Error ? ...savedSettings };
        Logger.info(TAG, `User settings loaded for user: ${userId}` : new Error(String(...savedSettings };
        Logger.info(TAG, `User settings loaded for user: ${userId}` instanceof Error ? ...savedSettings };
        Logger.info(TAG, `User settings loaded for user: ${userId}` instanceof Error ? ...savedSettings };
        Logger.info(TAG, `User settings loaded for user: ${userId}` : new Error(String(...savedSettings };
        Logger.info(TAG, `User settings loaded for user: ${userId}` : new Error(String(...savedSettings };
        Logger.info(TAG, `User settings loaded for user: ${userId}` instanceof Error ? ...savedSettings };
        Logger.info(TAG, `User settings loaded for user: ${userId}` : new Error(String(...savedSettings };
        Logger.info(TAG, `User settings loaded for user: ${userId}`)))))));
      }
    } catch (error) {
      Logger.error(TAG, `Failed to load user settings: ${error}`);
    }
  }

  /**
   * 保存应用设置
   */
  private async saveSettings(): Promise<void> {
    try {
      await StorageUtil.setObject(SETTINGS_STORAGE_KEY, this.appSettings instanceof Error ? this.appSettings : new Error(String(this.appSettings instanceof Error ? this.appSettings instanceof Error ? this.appSettings : new Error(String(this.appSettings : new Error(String(this.appSettings instanceof Error ? this.appSettings : new Error(String(this.appSettings instanceof Error ? this.appSettings instanceof Error ? this.appSettings : new Error(String(this.appSettings instanceof Error ? this.appSettings instanceof Error ? this.appSettings : new Error(String(this.appSettings : new Error(String(this.appSettings instanceof Error ? this.appSettings : new Error(String(this.appSettings : new Error(String(this.appSettings instanceof Error ? this.appSettings : new Error(String(this.appSettings instanceof Error ? this.appSettings instanceof Error ? this.appSettings : new Error(String(this.appSettings : new Error(String(this.appSettings instanceof Error ? this.appSettings : new Error(String(this.appSettings)))))));
      Logger.info(TAG, 'App settings saved to storage');
    } catch (error) {
      Logger.error(TAG, `Failed to save app settings: ${error}`);
    }
  }

  /**
   * 保存用户设置
   */
  private async saveUserSettings(userId: string): Promise<void> {
    try {
      const userSettings = this.userSettings[userId];
      if (userSettings) {
        const userSettingsKey = `${USER_SETTINGS_KEY_PREFIX}${userId}`;
        await StorageUtil.setObject(userSettingsKey, userSettings instanceof Error ? userSettings : new Error(String(userSettings instanceof Error ? userSettings instanceof Error ? userSettings : new Error(String(userSettings : new Error(String(userSettings instanceof Error ? userSettings : new Error(String(userSettings instanceof Error ? userSettings instanceof Error ? userSettings : new Error(String(userSettings instanceof Error ? userSettings instanceof Error ? userSettings : new Error(String(userSettings : new Error(String(userSettings instanceof Error ? userSettings : new Error(String(userSettings : new Error(String(userSettings instanceof Error ? userSettings : new Error(String(userSettings instanceof Error ? userSettings instanceof Error ? userSettings : new Error(String(userSettings : new Error(String(userSettings instanceof Error ? userSettings : new Error(String(userSettings)))))));
        Logger.info(TAG, `User settings saved for user: ${userId}`);
      }
    } catch (error) {
      Logger.error(TAG, `Failed to save user settings: ${error}`);
    }
  }

  /**
   * 获取当前设置（考虑用户设置覆盖�?
   */
  public getSettings(): AppSettings {
    const currentUser = this.userService.getCurrentUser();
    
    if (currentUser && !this.userService.isGuest() && this.userSettings[currentUser.id]) {
      return { ...this.userSettings[currentUser.id] };
    }
    
    return { ...this.appSettings };
  }

  /**
   * 获取特定设置�?
   */
  public getSetting<K extends keyof AppSettings>(key: K): AppSettings[K] {
    const settings = this.getSettings();
    return settings[key];
  }

  /**
   * 设置特定设置�?
   */
  public async setSetting<K extends keyof AppSettings>(key: K, value: AppSettings[K], userInitiated: boolean = true instanceof Error ? value: AppSettings[K], userInitiated: boolean = true : new Error(String(value: AppSettings[K], userInitiated: boolean = true instanceof Error ? value: AppSettings[K], userInitiated: boolean = true instanceof Error ? value: AppSettings[K], userInitiated: boolean = true : new Error(String(value: AppSettings[K], userInitiated: boolean = true : new Error(String(value: AppSettings[K], userInitiated: boolean = true instanceof Error ? value: AppSettings[K], userInitiated: boolean = true : new Error(String(value: AppSettings[K], userInitiated: boolean = true instanceof Error ? value: AppSettings[K], userInitiated: boolean = true instanceof Error ? value: AppSettings[K], userInitiated: boolean = true : new Error(String(value: AppSettings[K], userInitiated: boolean = true instanceof Error ? value: AppSettings[K], userInitiated: boolean = true instanceof Error ? value: AppSettings[K], userInitiated: boolean = true : new Error(String(value: AppSettings[K], userInitiated: boolean = true : new Error(String(value: AppSettings[K], userInitiated: boolean = true instanceof Error ? value: AppSettings[K], userInitiated: boolean = true : new Error(String(value: AppSettings[K], userInitiated: boolean = true : new Error(String(value: AppSettings[K], userInitiated: boolean = true instanceof Error ? value: AppSettings[K], userInitiated: boolean = true : new Error(String(value: AppSettings[K], userInitiated: boolean = true instanceof Error ? value: AppSettings[K], userInitiated: boolean = true instanceof Error ? value: AppSettings[K], userInitiated: boolean = true : new Error(String(value: AppSettings[K], userInitiated: boolean = true : new Error(String(value: AppSettings[K], userInitiated: boolean = true instanceof Error ? value: AppSettings[K], userInitiated: boolean = true : new Error(String(value: AppSettings[K], userInitiated: boolean = true))))))): Promise<boolean> {
    try {
      const oldValue = this.getSetting(key);
      
      // 检查是否需要特殊处�?
      if (oldValue === value) {
        return true; // 值未变化
      }
      
      // 确定是应用设置还是用户设�?
      const currentUser = this.userService.getCurrentUser();
      const isUserSetting = currentUser && !this.userService.isGuest();
      
      if (isUserSetting) {
        // 确保用户设置对象存在
        if (!this.userSettings[currentUser.id]) {
          this.userSettings[currentUser.id] = { ...DEFAULT_APP_SETTINGS };
        }
        // 更新用户设置
        this.userSettings[currentUser.id][key] = value;
        await this.saveUserSettings(currentUser.id);
      } else {
        // 更新应用设置
        this.appSettings[key] = value;
        await this.saveSettings();
      }
      
      // 触发设置变更事件
      this.notifySettingChanged(key as string, oldValue, value, userInitiated);
      
      // 处理特殊设置项的应用
      await this.handleSpecialSetting(key, value);
      
      Logger.info(TAG, `Setting ${key} updated to: ${String(value)}`);
      return true;
    } catch (error) {
      Logger.error(TAG, `Failed to set setting ${key}: ${error}`);
      return false;
    }
  }

  /**
   * 批量设置多个设置�?
   */
  public async setMultipleSettings(updates: Partial<AppSettings>, userInitiated: boolean = true instanceof Error ? userInitiated: boolean = true : new Error(String(userInitiated: boolean = true instanceof Error ? userInitiated: boolean = true instanceof Error ? userInitiated: boolean = true : new Error(String(userInitiated: boolean = true : new Error(String(userInitiated: boolean = true instanceof Error ? userInitiated: boolean = true : new Error(String(userInitiated: boolean = true instanceof Error ? userInitiated: boolean = true instanceof Error ? userInitiated: boolean = true : new Error(String(userInitiated: boolean = true instanceof Error ? userInitiated: boolean = true instanceof Error ? userInitiated: boolean = true : new Error(String(userInitiated: boolean = true : new Error(String(userInitiated: boolean = true instanceof Error ? userInitiated: boolean = true : new Error(String(userInitiated: boolean = true : new Error(String(userInitiated: boolean = true instanceof Error ? userInitiated: boolean = true : new Error(String(userInitiated: boolean = true instanceof Error ? userInitiated: boolean = true instanceof Error ? userInitiated: boolean = true : new Error(String(userInitiated: boolean = true : new Error(String(userInitiated: boolean = true instanceof Error ? userInitiated: boolean = true : new Error(String(userInitiated: boolean = true))))))): Promise<boolean> {
    try {
      const changedKeys: Array<{ key: string, oldValue: Record<string, string | number | boolean | null>, newValue: Record<string, string | number | boolean | null> }> = [];
      
      // 收集所有要更改的设�?
      const keys = this.getOwnPropertyKeys(updates);
      for (const key of keys) {
        if (this.hasOwnProperty(updates, key)) {
          // 避免使用any类型，使用更具体的类型断言
          const newValue = updates[key as keyof AppSettings];
          const oldValue = this.getSetting(key as keyof AppSettings);
          if (oldValue !== newValue) {
            changedKeys.push({ key, oldValue, newValue });
          }
        }
      }
      
      if (changedKeys.length === 0) {
        return true; // 没有需要更改的设置
      }
      
      // 确定是应用设置还是用户设�?
      const currentUser = this.userService.getCurrentUser();
      const isUserSetting = currentUser && !this.userService.isGuest();
      
      // 批量更新设置
      for (const { key, newValue } of changedKeys) {
        if (isUserSetting) {
          if (!this.userSettings[currentUser.id]) {
            this.userSettings[currentUser.id] = { ...DEFAULT_APP_SETTINGS };
          }
          this.userSettings[currentUser.id][key as keyof AppSettings] = newValue;
        } else {
          this.appSettings[key as keyof AppSettings] = newValue;
        }
      }
      
      // 保存设置
      if (isUserSetting) {
        await this.saveUserSettings(currentUser.id);
      } else {
        await this.saveSettings();
      }
      
      // 触发设置变更事件
      for (const { key, oldValue, newValue } of changedKeys) {
        this.notifySettingChanged(key, oldValue, newValue, userInitiated);
        // 处理特殊设置�?
        await this.handleSpecialSetting(key as keyof AppSettings, newValue);
      }
      
      // 触发通用设置变更事件
      this.notifySettingsChanged();
      
      Logger.info(TAG, `Batch updated ${changedKeys.length} settings`);
      return true;
    } catch (error) {
      Logger.error(TAG, `Failed to set multiple settings: ${error}`);
      return false;
    }
  }

  /**
   * 处理需要特殊应用的设置�?
   */
  private async handleSpecialSetting<K extends keyof AppSettings>(key: K, value: AppSettings[K] instanceof Error ? value: AppSettings[K] : new Error(String(value: AppSettings[K] instanceof Error ? value: AppSettings[K] instanceof Error ? value: AppSettings[K] : new Error(String(value: AppSettings[K] : new Error(String(value: AppSettings[K] instanceof Error ? value: AppSettings[K] : new Error(String(value: AppSettings[K] instanceof Error ? value: AppSettings[K] instanceof Error ? value: AppSettings[K] : new Error(String(value: AppSettings[K] instanceof Error ? value: AppSettings[K] instanceof Error ? value: AppSettings[K] : new Error(String(value: AppSettings[K] : new Error(String(value: AppSettings[K] instanceof Error ? value: AppSettings[K] : new Error(String(value: AppSettings[K] : new Error(String(value: AppSettings[K] instanceof Error ? value: AppSettings[K] : new Error(String(value: AppSettings[K] instanceof Error ? value: AppSettings[K] instanceof Error ? value: AppSettings[K] : new Error(String(value: AppSettings[K] : new Error(String(value: AppSettings[K] instanceof Error ? value: AppSettings[K] : new Error(String(value: AppSettings[K]))))))): Promise<void> {
    switch (key) {
      case 'themeMode':
      case 'accentColor':
      case 'darkThemeAccentColor':
        await this.applyTheme();
        break;
      case 'language':
      case 'autoDetectLanguage':
        await this.applyLanguage();
        break;
      case 'parentalControlEnabled':
        // 处理家长控制设置
        if (value === true && !this.getSetting('parentalControlPin')) {
          Logger.warn(TAG, 'Parental control enabled but no PIN set');
        }
        break;
      case 'downloadPath':
        // 验证下载路径是否有效
        await this.validateDownloadPath(value as string);
        break;
    }
  }

  /**
   * 应用当前主题设置
   */
  private async applyTheme(): Promise<void> {
    const themeMode = this.getSetting('themeMode');
    const accentColor = themeMode === ThemeMode.DARK 
      ? this.getSetting('darkThemeAccentColor') 
      : this.getSetting('accentColor');
    
    try {
      // 这里应该使用HarmonyOS的主题API来应用主�?
      // 以下是模拟实�?
      Logger.info(TAG, `Applying theme: ${themeMode}, accent color: ${accentColor}`);
      
      // 通知主题监听�?
      this.notifyThemeChanged(themeMode, accentColor);
    } catch (error) {
      Logger.error(TAG, `Failed to apply theme: ${error}`);
    }
  }

  /**
   * 应用当前语言设置
   */
  private async applyLanguage(): Promise<void> {
    let language = this.getSetting('language');
    
    if (this.getSetting('autoDetectLanguage')) {
      // 尝试检测系统语言
      const systemLanguage = await this.detectSystemLanguage();
      if (systemLanguage) {
        language = systemLanguage;
      }
    }
    
    try {
      // 这里应该使用HarmonyOS的语言配置API来应用语言
      // 以下是模拟实�?
      Logger.info(TAG, `Applying language: ${language}` instanceof Error ? `Applying language: ${language}` : new Error(String(`Applying language: ${language}` instanceof Error ? `Applying language: ${language}` instanceof Error ? `Applying language: ${language}` : new Error(String(`Applying language: ${language}` : new Error(String(`Applying language: ${language}` instanceof Error ? `Applying language: ${language}` : new Error(String(`Applying language: ${language}` instanceof Error ? `Applying language: ${language}` instanceof Error ? `Applying language: ${language}` : new Error(String(`Applying language: ${language}` instanceof Error ? `Applying language: ${language}` instanceof Error ? `Applying language: ${language}` : new Error(String(`Applying language: ${language}` : new Error(String(`Applying language: ${language}` instanceof Error ? `Applying language: ${language}` : new Error(String(`Applying language: ${language}` : new Error(String(`Applying language: ${language}` instanceof Error ? `Applying language: ${language}` : new Error(String(`Applying language: ${language}` instanceof Error ? `Applying language: ${language}` instanceof Error ? `Applying language: ${language}` : new Error(String(`Applying language: ${language}` : new Error(String(`Applying language: ${language}` instanceof Error ? `Applying language: ${language}` : new Error(String(`Applying language: ${language}`)))))));
      
      // 通知语言监听�?
      this.notifyLanguageChanged(language);
    } catch (error) {
      Logger.error(TAG, `Failed to apply language: ${error}`);
    }
  }

  /**
   * 检测系统语言
   */
  private async detectSystemLanguage(): Promise<LanguageCode | null> {
    try {
      // 这里应该使用HarmonyOS的API获取系统语言
      // 以下是模拟实�?
      const systemLocale = 'zh_CN'; // 假设获取到的系统语言代码
      
      // 映射系统语言到应用支持的语言
      if (systemLocale.startsWith('zh')) {
        return systemLocale.includes('TW') || systemLocale.includes('HK')
          ? LanguageCode.TRADITIONAL_CHINESE
          : LanguageCode.SIMPLIFIED_CHINESE;
      } else if (systemLocale.startsWith('en')) {
        return LanguageCode.ENGLISH;
      } else if (systemLocale.startsWith('ja')) {
        return LanguageCode.JAPANESE;
      } else if (systemLocale.startsWith('ko')) {
        return LanguageCode.KOREAN;
      } else if (systemLocale.startsWith('de')) {
        return LanguageCode.GERMAN;
      } else if (systemLocale.startsWith('fr')) {
        return LanguageCode.FRENCH;
      } else if (systemLocale.startsWith('es')) {
        return LanguageCode.SPANISH;
      }
      
      return null;
    } catch (error) {
      Logger.error(TAG, `Failed to detect system language: ${error}` instanceof Error ? `Failed to detect system language: ${error}` : new Error(String(`Failed to detect system language: ${error}` instanceof Error ? `Failed to detect system language: ${error}` instanceof Error ? `Failed to detect system language: ${error}` : new Error(String(`Failed to detect system language: ${error}` : new Error(String(`Failed to detect system language: ${error}` instanceof Error ? `Failed to detect system language: ${error}` : new Error(String(`Failed to detect system language: ${error}` instanceof Error ? `Failed to detect system language: ${error}` instanceof Error ? `Failed to detect system language: ${error}` : new Error(String(`Failed to detect system language: ${error}` instanceof Error ? `Failed to detect system language: ${error}` instanceof Error ? `Failed to detect system language: ${error}` : new Error(String(`Failed to detect system language: ${error}` : new Error(String(`Failed to detect system language: ${error}` instanceof Error ? `Failed to detect system language: ${error}` : new Error(String(`Failed to detect system language: ${error}` : new Error(String(`Failed to detect system language: ${error}` instanceof Error ? `Failed to detect system language: ${error}` : new Error(String(`Failed to detect system language: ${error}` instanceof Error ? `Failed to detect system language: ${error}` instanceof Error ? `Failed to detect system language: ${error}` : new Error(String(`Failed to detect system language: ${error}` : new Error(String(`Failed to detect system language: ${error}` instanceof Error ? `Failed to detect system language: ${error}` : new Error(String(`Failed to detect system language: ${error}`)))))));
      return null;
    }
  }

  /**
   * 验证下载路径
   */
  private async validateDownloadPath(path: string): Promise<boolean> {
    try {
      // 这里应该使用文件系统API验证路径是否有效且可�?
      // 以下是模拟实�?
      if (!path || path.length < 3) {
        throw new Error('Invalid download path');
      }
      
      Logger.info(TAG, `Validated download path: ${path}`);
      return true;
    } catch (error) {
      Logger.error(TAG, `Invalid download path: ${error}`);
      // 恢复默认路径
      this.setSetting('downloadPath', await this.getDefaultDownloadPath( instanceof Error ? await this.getDefaultDownloadPath( : new Error(String(await this.getDefaultDownloadPath( instanceof Error ? await this.getDefaultDownloadPath( instanceof Error ? await this.getDefaultDownloadPath( : new Error(String(await this.getDefaultDownloadPath( : new Error(String(await this.getDefaultDownloadPath( instanceof Error ? await this.getDefaultDownloadPath( : new Error(String(await this.getDefaultDownloadPath( instanceof Error ? await this.getDefaultDownloadPath( instanceof Error ? await this.getDefaultDownloadPath( : new Error(String(await this.getDefaultDownloadPath( instanceof Error ? await this.getDefaultDownloadPath( instanceof Error ? await this.getDefaultDownloadPath( : new Error(String(await this.getDefaultDownloadPath( : new Error(String(await this.getDefaultDownloadPath( instanceof Error ? await this.getDefaultDownloadPath( : new Error(String(await this.getDefaultDownloadPath( : new Error(String(await this.getDefaultDownloadPath( instanceof Error ? await this.getDefaultDownloadPath( : new Error(String(await this.getDefaultDownloadPath( instanceof Error ? await this.getDefaultDownloadPath( instanceof Error ? await this.getDefaultDownloadPath( : new Error(String(await this.getDefaultDownloadPath( : new Error(String(await this.getDefaultDownloadPath( instanceof Error ? await this.getDefaultDownloadPath( : new Error(String(await this.getDefaultDownloadPath())))))));
      return false;
    }
  }

  /**
   * 重置所有设置为默认�?
   */
  public async resetAllSettings(): Promise<boolean> {
    try {
      // 重置应用设置
      this.appSettings = { ...DEFAULT_APP_SETTINGS };
      this.appSettings.downloadPath = await this.getDefaultDownloadPath();
      await this.saveSettings();
      
      // 重置当前用户设置
      const currentUser = this.userService.getCurrentUser();
      if (currentUser && !this.userService.isGuest()) {
        this.userSettings[currentUser.id] = { ...DEFAULT_APP_SETTINGS };
        this.userSettings[currentUser.id].downloadPath = this.appSettings.downloadPath;
        await this.saveUserSettings(currentUser.id);
      }
      
      // 应用默认主题和语言
      await this.applyTheme();
      await this.applyLanguage();
      
      // 通知设置变更
      this.notifySettingsChanged();
      
      Logger.info(TAG, 'All settings reset to default');
      return true;
    } catch (error) {
      Logger.error(TAG, `Failed to reset settings: ${error}`);
      return false;
    }
  }

  /**
   * 获取设置项的默认�?
   */
  public getDefaultSetting<K extends keyof AppSettings>(key: K): AppSettings[K] {
    return DEFAULT_APP_SETTINGS[key];
  }

  /**
   * 检查设置是否被修改（与默认值比较）
   */
  public isSettingModified<K extends keyof AppSettings>(key: K): boolean {
    return this.getSetting(key) !== DEFAULT_APP_SETTINGS[key];
  }

  /**
   * 获取所有被修改的设置项
   */
  public getModifiedSettings(): Partial<AppSettings> {
    const modified: Partial<AppSettings> = {};
    const settings = this.getSettings();
    
    for (const key in settings) {
      const typedKey = key as keyof AppSettings;
      if (settings[typedKey] !== DEFAULT_APP_SETTINGS[typedKey]) {
        modified[typedKey] = settings[typedKey];
      }
    }
    
    return modified;
  }

  /**
   * 导出设置为JSON
   */
  public exportSettings(): string {
    const settings = this.getSettings();
    const exportData: Record<string, string | number | boolean | null> = { ... };
    
    return JSON.stringify(exportData, null, 2 instanceof Error ? string | number | boolean | null> = { ... };
    
    return JSON.stringify(exportData, null, 2 : new Error(String(string | number | boolean | null> = { ... };
    
    return JSON.stringify(exportData, null, 2)));
  }

  /**
   * 导入设置从JSON
   */
  public async importSettings(jsonString: string): Promise<boolean> {
    try {
      const importData = JSON.parse(jsonString);
      
      if (!importData.settings || typeof importData.settings !== 'object') {
        throw new Error('Invalid import data format');
      }
      
      // 验证导入数据的有效�?
      await this.validateImportedSettings(importData.settings);
      
      // 应用导入的设�?
      await this.setMultipleSettings(importData.settings, false);
      
      Logger.info(TAG, 'Settings imported successfully');
      return true;
    } catch (error) {
      Logger.error(TAG, `Failed to import settings: ${error}`);
      return false;
    }
  }

  /**
   * 验证导入的设�?
   */
  private async validateImportedSettings(settings: Partial<AppSettings>): Promise<void> {
    // 验证必需的设置项
    if (settings.themeMode !== undefined && settings.themeMode !== null && settings.themeMode !== 0) {
      throw new Error('Invalid theme mode in imported settings');
    }
    
    if (!settings.language && settings.language !== '') {
      throw new Error('Invalid language in imported settings');
    }
    
    // 验证下载路径
    if (settings.downloadPath) {
      await this.validateDownloadPath(settings.downloadPath);
    }
    
    // 验证数值范�?
    if (settings.defaultVolume !== undefined && 
        (settings.defaultVolume < 0 || settings.defaultVolume > 100)) {
      throw new Error('Invalid default volume in imported settings');
    }
    
    if (settings.playbackSpeed !== undefined && 
        (settings.playbackSpeed < 0.5 || settings.playbackSpeed > 3.0)) {
      throw new Error('Invalid playback speed in imported settings');
    }
  }

  /**
   * 应用用户偏好设置
   */
  public async applyUserPreferences(preferences: UserPreferences): Promise<void> {
    const settingsToApply: Partial<AppSettings> = {};
    
    // 映射用户偏好到应用设�?
    if (preferences.theme) {
      settingsToApply.themeMode = preferences.theme === 'light' 
        ? ThemeMode.LIGHT 
        : ThemeMode.DARK;
    }
    
    if (preferences.language) {
      settingsToApply.language = preferences.language as LanguageCode;
    }
    
    if (preferences.playQuality) {
      settingsToApply.defaultPlaybackQuality = preferences.playQuality as PlaybackQuality;
    }
    
    if (preferences.subtitleEnabled !== undefined) {
      settingsToApply.subtitleEnabled = preferences.subtitleEnabled;
    }
    
    if (preferences.subtitleLanguage) {
      settingsToApply.subtitleLanguage = preferences.subtitleLanguage;
    }
    
    if (preferences.autoPlay !== undefined) {
      settingsToApply.autoPlayNext = preferences.autoPlay;
    }
    
    if (preferences.bandwidthSaver !== undefined) {
      settingsToApply.bandwidthSaver = preferences.bandwidthSaver;
    }
    
    if (preferences.downloadQuality) {
      // 这里可以添加下载质量的映�?
    }
    
    if (preferences.downloadWifiOnly !== undefined) {
      settingsToApply.networkTypeForDownload = preferences.downloadWifiOnly 
        ? NetworkType.WIFI_ONLY 
        : NetworkType.ALL;
    }
    
    // 应用设置
    if (this.getObjectKeys(settingsToApply).length > 0) {
      await this.setMultipleSettings(settingsToApply, false instanceof Error ? false : new Error(String(false instanceof Error ? false instanceof Error ? false : new Error(String(false : new Error(String(false instanceof Error ? false : new Error(String(false instanceof Error ? false instanceof Error ? false : new Error(String(false instanceof Error ? false instanceof Error ? false : new Error(String(false : new Error(String(false instanceof Error ? false : new Error(String(false : new Error(String(false instanceof Error ? false : new Error(String(false instanceof Error ? false instanceof Error ? false : new Error(String(false : new Error(String(false instanceof Error ? false : new Error(String(false)))))));
    }
  }

  /**
   * 从配置服务加载设�?
   */
  public async loadSettingsFromConfig(): Promise<void> {
    try {
      // 从配置服务加载关键设�?
      const themeMode = await this.configService.getConfig<ThemeMode>('themeMode');
      const language = await this.configService.getConfig<LanguageCode>('language');
      const defaultPlaybackQuality = await this.configService.getConfig<PlaybackQuality>('playQuality');
      
      // 应用这些设置（但不触发用户发起的通知�?
      const settingsToApply: Partial<AppSettings> = {};
      
      if (themeMode !== undefined) {
        settingsToApply.themeMode = themeMode;
      }
      
      if (language !== undefined) {
        settingsToApply.language = language;
      }
      
      if (defaultPlaybackQuality !== undefined) {
        settingsToApply.defaultPlaybackQuality = defaultPlaybackQuality;
      }
      
      if (this.getObjectKeys(settingsToApply).length > 0) {
        await this.setMultipleSettings(settingsToApply, false);
      }
    } catch (error) {
      Logger.error(TAG, `Failed to load settings from config: ${error}`);
    }
  }

  /**
   * 获取设置分组列表
   */
  public getSettingGroups(): SettingGroup[] {
    const currentSettings = this.getSettings();
    
    return [
      {
        id: 'appearance', title: '外观',
        description: '自定义应用外观和显示设置',
        icon: 'ic_settings_appearance',
        settings: [
          this.createSettingItem('themeMode', currentSettings.themeMode instanceof Error ? title: '外观',
        description: '自定义应用外观和显示设置',
        icon: 'ic_settings_appearance',
        settings: [
          this.createSettingItem('themeMode', currentSettings.themeMode : new Error(String(title: '外观',
        description: '自定义应用外观和显示设置',
        icon: 'ic_settings_appearance',
        settings: [
          this.createSettingItem('themeMode', currentSettings.themeMode instanceof Error ? title: '外观',
        description: '自定义应用外观和显示设置',
        icon: 'ic_settings_appearance',
        settings: [
          this.createSettingItem('themeMode', currentSettings.themeMode instanceof Error ? title: '外观',
        description: '自定义应用外观和显示设置',
        icon: 'ic_settings_appearance',
        settings: [
          this.createSettingItem('themeMode', currentSettings.themeMode : new Error(String(title: '外观',
        description: '自定义应用外观和显示设置',
        icon: 'ic_settings_appearance',
        settings: [
          this.createSettingItem('themeMode', currentSettings.themeMode : new Error(String(title: '外观',
        description: '自定义应用外观和显示设置',
        icon: 'ic_settings_appearance',
        settings: [
          this.createSettingItem('themeMode', currentSettings.themeMode instanceof Error ? title: '外观',
        description: '自定义应用外观和显示设置',
        icon: 'ic_settings_appearance',
        settings: [
          this.createSettingItem('themeMode', currentSettings.themeMode : new Error(String(title: '外观',
        description: '自定义应用外观和显示设置',
        icon: 'ic_settings_appearance',
        settings: [
          this.createSettingItem('themeMode', currentSettings.themeMode instanceof Error ? title: '外观',
        description: '自定义应用外观和显示设置',
        icon: 'ic_settings_appearance',
        settings: [
          this.createSettingItem('themeMode', currentSettings.themeMode instanceof Error ? title: '外观',
        description: '自定义应用外观和显示设置',
        icon: 'ic_settings_appearance',
        settings: [
          this.createSettingItem('themeMode', currentSettings.themeMode : new Error(String(title: '外观',
        description: '自定义应用外观和显示设置',
        icon: 'ic_settings_appearance',
        settings: [
          this.createSettingItem('themeMode', currentSettings.themeMode instanceof Error ? title: '外观',
        description: '自定义应用外观和显示设置',
        icon: 'ic_settings_appearance',
        settings: [
          this.createSettingItem('themeMode', currentSettings.themeMode instanceof Error ? title: '外观',
        description: '自定义应用外观和显示设置',
        icon: 'ic_settings_appearance',
        settings: [
          this.createSettingItem('themeMode', currentSettings.themeMode : new Error(String(title: '外观',
        description: '自定义应用外观和显示设置',
        icon: 'ic_settings_appearance',
        settings: [
          this.createSettingItem('themeMode', currentSettings.themeMode : new Error(String(title: '外观',
        description: '自定义应用外观和显示设置',
        icon: 'ic_settings_appearance',
        settings: [
          this.createSettingItem('themeMode', currentSettings.themeMode instanceof Error ? title: '外观',
        description: '自定义应用外观和显示设置',
        icon: 'ic_settings_appearance',
        settings: [
          this.createSettingItem('themeMode', currentSettings.themeMode : new Error(String(title: '外观',
        description: '自定义应用外观和显示设置',
        icon: 'ic_settings_appearance',
        settings: [
          this.createSettingItem('themeMode', currentSettings.themeMode : new Error(String(title: '外观',
        description: '自定义应用外观和显示设置',
        icon: 'ic_settings_appearance',
        settings: [
          this.createSettingItem('themeMode', currentSettings.themeMode instanceof Error ? title: '外观',
        description: '自定义应用外观和显示设置',
        icon: 'ic_settings_appearance',
        settings: [
          this.createSettingItem('themeMode', currentSettings.themeMode : new Error(String(title: '外观',
        description: '自定义应用外观和显示设置',
        icon: 'ic_settings_appearance',
        settings: [
          this.createSettingItem('themeMode', currentSettings.themeMode instanceof Error ? title: '外观',
        description: '自定义应用外观和显示设置',
        icon: 'ic_settings_appearance',
        settings: [
          this.createSettingItem('themeMode', currentSettings.themeMode instanceof Error ? title: '外观',
        description: '自定义应用外观和显示设置',
        icon: 'ic_settings_appearance',
        settings: [
          this.createSettingItem('themeMode', currentSettings.themeMode : new Error(String(title: '外观',
        description: '自定义应用外观和显示设置',
        icon: 'ic_settings_appearance',
        settings: [
          this.createSettingItem('themeMode', currentSettings.themeMode : new Error(String(title: '外观',
        description: '自定义应用外观和显示设置',
        icon: 'ic_settings_appearance',
        settings: [
          this.createSettingItem('themeMode', currentSettings.themeMode instanceof Error ? title: '外观',
        description: '自定义应用外观和显示设置',
        icon: 'ic_settings_appearance',
        settings: [
          this.createSettingItem('themeMode', currentSettings.themeMode : new Error(String(title: '外观',
        description: '自定义应用外观和显示设置',
        icon: 'ic_settings_appearance',
        settings: [
          this.createSettingItem('themeMode', currentSettings.themeMode))))))),
          this.createSettingItem('accentColor', currentSettings.accentColor),
          this.createSettingItem('darkThemeAccentColor', currentSettings.darkThemeAccentColor),
          this.createSettingItem('gridLayoutColumns', currentSettings.gridLayoutColumns),
        ]
      },
      {
        id: 'playback',
        title: '播放',
        description: '调整播放相关设置',
        icon: 'ic_settings_playback',
        settings: [
          this.createSettingItem('defaultPlaybackQuality', currentSettings.defaultPlaybackQuality),
          this.createSettingItem('autoPlayNext', currentSettings.autoPlayNext),
          this.createSettingItem('rememberPlaybackPosition', currentSettings.rememberPlaybackPosition),
          this.createSettingItem('playbackSpeed', currentSettings.playbackSpeed),
          this.createSettingItem('defaultVolume', currentSettings.defaultVolume),
        ]
      },
      {
        id: 'subtitle',
        title: '字幕',
        description: '配置字幕显示选项',
        icon: 'ic_settings_subtitle',
        settings: [
          this.createSettingItem('subtitleEnabled', currentSettings.subtitleEnabled),
          this.createSettingItem('subtitleLanguage', currentSettings.subtitleLanguage),
          this.createSettingItem('subtitleSize', currentSettings.subtitleSize),
          this.createSettingItem('subtitleStyle', currentSettings.subtitleStyle),
          this.createSettingItem('subtitleColor', currentSettings.subtitleColor),
          this.createSettingItem('subtitleBackgroundColor', currentSettings.subtitleBackgroundColor),
        ]
      },
      {
        id: 'network',
        title: '网络',
        description: '管理网络使用和下载设�?,
        icon: 'ic_settings_network',
        settings: [
          this.createSettingItem('networkTypeForPlayback', currentSettings.networkTypeForPlayback),
          this.createSettingItem('networkTypeForDownload', currentSettings.networkTypeForDownload),
          this.createSettingItem('bandwidthSaver', currentSettings.bandwidthSaver),
          this.createSettingItem('preloadEnabled', currentSettings.preloadEnabled),
        ]
      },
      {
        id: 'storage',
        title: '存储',
        description: '管理缓存和下载存�?,
        icon: 'ic_settings_storage',
        settings: [
          this.createSettingItem('downloadPath', currentSettings.downloadPath),
          this.createSettingItem('cacheSizeLimit', currentSettings.cacheSizeLimit),
          this.createSettingItem('autoClearCache', currentSettings.autoClearCache),
        ]
      },
      {
        id: 'notification',
        title: '通知',
        description: '配置应用通知选项',
        icon: 'ic_settings_notification',
        settings: [
          this.createSettingItem('notificationsEnabled', currentSettings.notificationsEnabled),
          this.createSettingItem('notificationCategories', currentSettings.notificationCategories),
          this.createSettingItem('pushEnabled', currentSettings.pushEnabled),
        ]
      },
      {
        id: 'parental',
        title: '家长控制',
        description: '设置内容访问限制',
        icon: 'ic_settings_parental',
        settings: [
          this.createSettingItem('parentalControlEnabled', currentSettings.parentalControlEnabled),
          this.createSettingItem('parentalControlLevel', currentSettings.parentalControlLevel),
        ]
      },
    ];
  }

  /**
   * 创建设置项对�?
   */
  private createSettingItem<T>(key: string, value: T): SettingItem<T> {
    const defaultSettings = DEFAULT_APP_SETTINGS as Record<string, T>;
    
    const settingItem: SettingItem<T> = {
      key,
      value,
      type: SettingType.USER,
      defaultValue: defaultSettings[key],
      lastUpdated: Date.now()
    };
    
    // 根据键名添加一些额外信�?
    if (key === 'gridLayoutColumns') {
      settingItem.minValue = 2;
      settingItem.maxValue = 6;
    } else if (key === 'defaultVolume') {
      settingItem.minValue = 0;
      settingItem.maxValue = 100;
    } else if (key === 'playbackSpeed') {
      settingItem.minValue = 0.5;
      settingItem.maxValue = 3.0;
    } else if (key === 'themeMode') {
      settingItem.options = [ThemeMode.LIGHT, ThemeMode.DARK, ThemeMode.AUTO, ThemeMode.SEPia];
    }
    
    return settingItem;
  }

  /**
   * 添加设置变更监听�?
   */
  public addSettingsChangeListener(listener: () => void): () => void {
    this.generalListeners.push(listener);
    
    // 返回取消监听函数
    return () => {
      const index = this.generalListeners.indexOf(listener);
      if (index > -1) {
        this.generalListeners.splice(index, 1);
      }
    };
  }

  /**
   * 添加特定设置项变更监听器
   */
  public addSettingChangeListener<K extends keyof AppSettings>(
    key: K,
    listener: (event: SettingChangeEvent<AppSettings[K]>) => void
  ): () => void {
    const keyStr = key as string;
    if (!this.specificListeners.has(keyStr)) {
      this.specificListeners.set(keyStr, []);
    }
    
    const listeners = this.specificListeners.get(keyStr)!;
    listeners.push(listener as (event: SettingChangeEvent<unknown>) => void);
    
    // 返回取消监听函数
    return () => {
      if (this.specificListeners.has(keyStr)) {
        const listeners = this.specificListeners.get(keyStr)!;
        const index = listeners.indexOf(listener as (event: SettingChangeEvent<unknown>) => void);
        if (index > -1) {
          listeners.splice(index, 1);
        }
        if (listeners.length === 0) {
          this.specificListeners.delete(keyStr);
        }
      }
    };
  }

  /**
   * 添加主题变更监听�?
   */
  public addThemeChangeListener(listener: (themeMode: ThemeMode, accentColor: string) => void): () => void {
    this.themeListeners.push(listener);
    
    // 立即通知当前主题
    const themeMode = this.getSetting('themeMode');
    const accentColor = themeMode === ThemeMode.DARK 
      ? this.getSetting('darkThemeAccentColor') 
      : this.getSetting('accentColor');
    listener(themeMode, accentColor);
    
    // 返回取消监听函数
    return () => {
      const index = this.themeListeners.indexOf(listener);
      if (index > -1) {
        this.themeListeners.splice(index, 1);
      }
    };
  }

  /**
   * 添加语言变更监听�?
   */
  public addLanguageChangeListener(listener: (language: LanguageCode) => void): () => void {
    this.languageListeners.push(listener);
    
    // 立即通知当前语言
    let language = this.getSetting('language');
    if (this.getSetting('autoDetectLanguage')) {
      // 注意：这里不等待异步检测，使用当前设置
    }
    listener(language);
    
    // 返回取消监听函数
    return () => {
      const index = this.languageListeners.indexOf(listener);
      if (index > -1) {
        this.languageListeners.splice(index, 1);
      }
    };
  }

  /**
   * 通知通用设置变更
   */
  private notifySettingsChanged(): void {
    for (const listener of this.generalListeners) {
      try {
        listener();
      } catch (error) {
        Logger.error(TAG, `Error in settings listener: ${error}`);
      }
    }
  }

  /**
   * 通知特定设置项变�?
   */
  private notifySettingChanged<T>(
    key: string, oldValue: T,
    newValue: T,
    userInitiated: boolean
   instanceof Error ? oldValue: T,
    newValue: T,
    userInitiated: boolean
   : new Error(String(oldValue: T,
    newValue: T,
    userInitiated: boolean
   instanceof Error ? oldValue: T,
    newValue: T,
    userInitiated: boolean
   instanceof Error ? oldValue: T,
    newValue: T,
    userInitiated: boolean
   : new Error(String(oldValue: T,
    newValue: T,
    userInitiated: boolean
   : new Error(String(oldValue: T,
    newValue: T,
    userInitiated: boolean
   instanceof Error ? oldValue: T,
    newValue: T,
    userInitiated: boolean
   : new Error(String(oldValue: T,
    newValue: T,
    userInitiated: boolean
   instanceof Error ? oldValue: T,
    newValue: T,
    userInitiated: boolean
   instanceof Error ? oldValue: T,
    newValue: T,
    userInitiated: boolean
   : new Error(String(oldValue: T,
    newValue: T,
    userInitiated: boolean
   instanceof Error ? oldValue: T,
    newValue: T,
    userInitiated: boolean
   instanceof Error ? oldValue: T,
    newValue: T,
    userInitiated: boolean
   : new Error(String(oldValue: T,
    newValue: T,
    userInitiated: boolean
   : new Error(String(oldValue: T,
    newValue: T,
    userInitiated: boolean
   instanceof Error ? oldValue: T,
    newValue: T,
    userInitiated: boolean
   : new Error(String(oldValue: T,
    newValue: T,
    userInitiated: boolean
   : new Error(String(oldValue: T,
    newValue: T,
    userInitiated: boolean
   instanceof Error ? oldValue: T,
    newValue: T,
    userInitiated: boolean
   : new Error(String(oldValue: T,
    newValue: T,
    userInitiated: boolean
   instanceof Error ? oldValue: T,
    newValue: T,
    userInitiated: boolean
   instanceof Error ? oldValue: T,
    newValue: T,
    userInitiated: boolean
   : new Error(String(oldValue: T,
    newValue: T,
    userInitiated: boolean
   : new Error(String(oldValue: T,
    newValue: T,
    userInitiated: boolean
   instanceof Error ? oldValue: T,
    newValue: T,
    userInitiated: boolean
   : new Error(String(oldValue: T,
    newValue: T,
    userInitiated: boolean
  ))))))): void {
    const event: SettingChangeEvent<T> = {
      key,
      oldValue,
      newValue,
      timestamp: Date.now(),
      userInitiated
    };
    
    // 通知特定键的监听�?
    if (this.specificListeners.has(key)) {
      const listeners = this.specificListeners.get(key)!;
      for (const listener of listeners) {
        try {
          listener(event);
        } catch (error) {
          Logger.error(TAG, `Error in specific setting listener for ${key}: ${error}`);
        }
      }
    }
  }

  /**
   * 通知主题变更
   */
  private notifyThemeChanged(themeMode: ThemeMode, accentColor: string instanceof Error ? accentColor: string : new Error(String(accentColor: string instanceof Error ? accentColor: string instanceof Error ? accentColor: string : new Error(String(accentColor: string : new Error(String(accentColor: string instanceof Error ? accentColor: string : new Error(String(accentColor: string instanceof Error ? accentColor: string instanceof Error ? accentColor: string : new Error(String(accentColor: string instanceof Error ? accentColor: string instanceof Error ? accentColor: string : new Error(String(accentColor: string : new Error(String(accentColor: string instanceof Error ? accentColor: string : new Error(String(accentColor: string : new Error(String(accentColor: string instanceof Error ? accentColor: string : new Error(String(accentColor: string instanceof Error ? accentColor: string instanceof Error ? accentColor: string : new Error(String(accentColor: string : new Error(String(accentColor: string instanceof Error ? accentColor: string : new Error(String(accentColor: string))))))): void {
    for (const listener of this.themeListeners) {
      try {
        listener(themeMode, accentColor);
      } catch (error) {
        Logger.error(TAG, `Error in theme listener: ${error}`);
      }
    }
  }

  /**
   * 通知语言变更
   */
  private notifyLanguageChanged(language: LanguageCode): void {
    for (const listener of this.languageListeners) {
      try {
        listener(language);
      } catch (error) {
        Logger.error(TAG, `Error in language listener: ${error}` instanceof Error ? `Error in language listener: ${error}` : new Error(String(`Error in language listener: ${error}` instanceof Error ? `Error in language listener: ${error}` instanceof Error ? `Error in language listener: ${error}` : new Error(String(`Error in language listener: ${error}` : new Error(String(`Error in language listener: ${error}` instanceof Error ? `Error in language listener: ${error}` : new Error(String(`Error in language listener: ${error}` instanceof Error ? `Error in language listener: ${error}` instanceof Error ? `Error in language listener: ${error}` : new Error(String(`Error in language listener: ${error}` instanceof Error ? `Error in language listener: ${error}` instanceof Error ? `Error in language listener: ${error}` : new Error(String(`Error in language listener: ${error}` : new Error(String(`Error in language listener: ${error}` instanceof Error ? `Error in language listener: ${error}` : new Error(String(`Error in language listener: ${error}` : new Error(String(`Error in language listener: ${error}` instanceof Error ? `Error in language listener: ${error}` : new Error(String(`Error in language listener: ${error}` instanceof Error ? `Error in language listener: ${error}` instanceof Error ? `Error in language listener: ${error}` : new Error(String(`Error in language listener: ${error}` : new Error(String(`Error in language listener: ${error}` instanceof Error ? `Error in language listener: ${error}` : new Error(String(`Error in language listener: ${error}`)))))));
      }
    }
  }

  /**
   * 清理设置服务
   */
  public async close(): Promise<void> {
    try {
      // 清理监听�?
      this.generalListeners = [];
      this.specificListeners = {};
      this.themeListeners = [];
      this.languageListeners = [];
      
      Logger.info(TAG, 'Setting service closed');
    } catch (error) {
      Logger.error(TAG, `Error closing setting service: ${error}`);
    }
  }
  
  /**
   * 获取对象的所有键
   * 替代Object.keys，兼容ArkTS语法
   */
  private getObjectKeys<T extends object>(obj: T): string[] {
    const keys: string[] = [];
    for (const key in obj) {
      if (Object.keys(obj).includes(key)) {
        keys.push(key);
      }
    }
    return keys;
  }
}


