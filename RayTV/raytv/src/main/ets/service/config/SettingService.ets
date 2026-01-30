// SettingService.ets - 设置服务 | Setting Service
// 提供应用配置管理、主题设置、语言切换等功能 | Provides app configuration management, theme settings, language switching, etc.
import StorageUtil from '../../common/util/StorageUtil';
import ConfigService from './ConfigService';
import UserService, { UserPreferences } from '../../service/user/UserService';
import DatabaseManager from '../../data/db/DatabaseManager';
import { BusinessError } from '@ohos.base';
import type { ApplicationInfo } from '@ohos.bundle.bundleManager';

// 自定义主题接口 | Custom theme interface
export interface CustomTheme {
  primaryColor?: string;
  secondaryColor?: string;
  backgroundColor?: string;
  textColor?: string;
  borderColor?: string;
}

// 用户设置映射接口 | User settings map interface
export interface UserSettingsMap {
  // 使用Map类型替代索引签名 | Use Map type instead of index signature
  settingsMap: Map<string, AppSettings>;
}

// 常量定义 | Constant definitions
const TAG = 'SettingService';
const SETTINGS_STORAGE_KEY = 'app_settings';
const USER_SETTINGS_KEY_PREFIX = 'user_settings_';

// 设置类型定义 | Setting type definitions
export enum SettingType {
  APPLICATION = 0,     // 应用级设置 | Application level settings
  USER = 1,            // 用户级设置 | User level settings
  DEVICE = 2,          // 设备级设置 | Device level settings
  CUSTOM = 3           // 自定义设置 | Custom settings
}

// 设置值类型别名 | Setting value type alias
export type SettingValue = ThemeMode | string | boolean | number | LanguageCode | PlaybackQuality | SubtitleSize | SubtitleStyle | NetworkType | NotificationCategory | Array<NotificationCategory>;

// 主题模式定义 | Theme mode definitions
export enum ThemeMode {
  LIGHT = 0,           // 浅色模式 | Light mode
  DARK = 1,            // 深色模式 | Dark mode
  AUTO = 2,            // 自动（跟随系统） | Auto (follow system)
  SEPia = 3            // 复古模式 | Sepia mode
}

// 语言代码定义 | Language code definitions
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

// 播放质量定义 | Playback quality definitions
export enum PlaybackQuality {
  LOW = 'low',         // 标清 | Low quality
  MEDIUM = 'medium',   // 高清 | Medium quality
  HIGH = 'high',       // 超清 | High quality
  ULTRA_HIGH = 'uhd',  // 超高清 | Ultra high quality
  AUTO = 'auto'        // 自动 | Auto
}

// 字幕大小定义 | Subtitle size definitions
export enum SubtitleSize {
  SMALL = 'small',     // 小 | Small
  MEDIUM = 'medium',   // 中 | Medium
  LARGE = 'large',     // 大 | Large
  X_LARGE = 'xlarge'   // 超大 | Extra large
}

// 字幕样式定义 | Subtitle style definitions
export enum SubtitleStyle {
  NORMAL = 'normal',   // 正常 | Normal
  BOLD = 'bold',       // 粗体 | Bold
  ITALIC = 'italic',   // 斜体 | Italic
  SHADOWED = 'shadowed' // 阴影 | Shadowed
}

// 网络类型定义 | Network type definitions
export enum NetworkType {
  ALL = 0,             // 所有网络 | All networks
  WIFI_ONLY = 1,       // 仅限WiFi | WiFi only
  MOBILE_ONLY = 2,     // 仅限移动网络 | Mobile only
  NO_MOBILE_HIGH_SPEED = 3 // 禁止高速移动网络 | No high-speed mobile
}

// 通知类型定义 | Notification type definitions
export enum NotificationCategory {
  ALL = 0,             // 所有通知 | All notifications
  UPDATES = 1,         // 更新通知 | Update notifications
  RECOMMENDATIONS = 2, // 推荐通知 | Recommendation notifications
  LIVE = 3,            // 直播通知 | Live notifications
  SYSTEM = 4           // 系统通知 | System notifications
}



// 设置项接口 | Setting item interface
export interface SettingItem<T> {
  key: string;         // 设置键名 | Setting key
  value: T;            // 设置值 | Setting value
  type: SettingType;   // 设置类型 | Setting type
  defaultValue: T;     // 默认值 | Default value
  description?: string; // 设置描述 | Setting description
  minValue?: number;   // 最小值（数字类型） | Minimum value (number type)
  maxValue?: number;   // 最大值（数字类型） | Maximum value (number type)
  options?: T[];       // 可选值列表 | Option list
  readOnly?: boolean;  // 是否只读 | Whether read-only
  requiresRestart?: boolean; // 是否需要重启 | Whether restart required
  lastUpdated?: number; // 最后更新时间 | Last updated time
}

// 应用设置接口 | App settings interface
export interface AppSettings {
  // 主题相关 | Theme related
  themeMode: ThemeMode;
  accentColor: string;
  darkThemeAccentColor: string;
  customTheme?: CustomTheme;
  
  // 语言相关 | Language related
  language: LanguageCode;
  autoDetectLanguage: boolean;
  
  // 播放相关 | Playback related
  defaultPlaybackQuality: PlaybackQuality;
  autoPlayNext: boolean;
  rememberPlaybackPosition: boolean;
  playbackSpeed: number;
  defaultVolume: number;
  
  // 字幕相关 | Subtitle related
  subtitleEnabled: boolean;
  subtitleLanguage: string;
  subtitleSize: SubtitleSize;
  subtitleStyle: SubtitleStyle;
  subtitleColor: string;
  subtitleBackgroundColor: string;
  
  // 存储相关 | Storage related
  downloadPath: string;
  cacheSizeLimit: number;
  autoClearCache: boolean;
  cacheClearInterval: number;
  
  // 网络相关 | Network related
  networkTypeForPlayback: NetworkType;
  networkTypeForDownload: NetworkType;
  bandwidthSaver: boolean;
  preloadEnabled: boolean;
  preloadLimit: number;
  
  // 通知相关 | Notification related
  notificationsEnabled: boolean;
  notificationCategories: NotificationCategory[];
  pushEnabled: boolean;
  
  // 外观相关 | Appearance related
  gridLayoutColumns: number;
  showFileExtensions: boolean;
  showHiddenFiles: boolean;
  defaultSortBy: string;
  defaultSortOrder: 'asc' | 'desc';
  
  // 设备相关 | Device related
  enableHardwareAcceleration: boolean;
  enableDolbyAudio: boolean;
  enableHDR: boolean;
  screenTimeout: number;
  
  // 其他设置 | Other settings
  crashReportingEnabled: boolean;
  usageAnalyticsEnabled: boolean;
  backgroundPlayEnabled: boolean;
  startupPage: string;
  enableGestureControl: boolean;
}

// 设置组接口 | Setting group interface
export interface SettingGroup {
  id: string;
  title: string;
  description?: string;
  settings: Array<SettingItem<ThemeMode | string | boolean | number | LanguageCode | PlaybackQuality | SubtitleSize | SubtitleStyle | NetworkType | NotificationCategory | Array<NotificationCategory>>>;
  icon?: string;
}

// 设置变更事件接口 | Setting change event interface
export interface SettingChangeEvent<T> {
  key: string;
  oldValue: T;
  newValue: T;
  timestamp: number;
  userInitiated: boolean;
}

// 默认应用设置 | Default app settings
const DEFAULT_APP_SETTINGS: AppSettings = {
  // 主题相关 | Theme related
  themeMode: ThemeMode.DARK,
  accentColor: '#007AFF',
  darkThemeAccentColor: '#0A84FF',
  
  // 语言相关 | Language related
  language: LanguageCode.SIMPLIFIED_CHINESE,
  autoDetectLanguage: true,
  
  // 播放相关 | Playback related
  defaultPlaybackQuality: PlaybackQuality.AUTO,
  autoPlayNext: true,
  rememberPlaybackPosition: true,
  playbackSpeed: 1.0,
  defaultVolume: 80,
  
  // 字幕相关 | Subtitle related
  subtitleEnabled: true,
  subtitleLanguage: 'zh_CN',
  subtitleSize: SubtitleSize.MEDIUM,
  subtitleStyle: SubtitleStyle.NORMAL,
  subtitleColor: '#FFFFFF',
  subtitleBackgroundColor: 'rgba(0, 0, 0, 0.5)',
  
  // 存储相关 | Storage related
  downloadPath: '',
  cacheSizeLimit: 1024 * 1024 * 1024 * 10, // 10GB
  autoClearCache: true,
  cacheClearInterval: 7 * 24 * 60 * 60 * 1000, // 7天 | 7 days
  
  // 网络相关 | Network related
  networkTypeForPlayback: NetworkType.ALL,
  networkTypeForDownload: NetworkType.WIFI_ONLY,
  bandwidthSaver: false,
  preloadEnabled: true,
  preloadLimit: 3,
  
  // 通知相关 | Notification related
  notificationsEnabled: true,
  notificationCategories: [
    NotificationCategory.UPDATES,
    NotificationCategory.RECOMMENDATIONS,
    NotificationCategory.LIVE,
    NotificationCategory.SYSTEM
  ],
  pushEnabled: true,
  

  
  // 外观相关 | Appearance related
  gridLayoutColumns: 3,
  showFileExtensions: false,
  showHiddenFiles: false,
  defaultSortBy: 'name',
  defaultSortOrder: 'asc',
  
  // 设备相关 | Device related
  enableHardwareAcceleration: true,
  enableDolbyAudio: false,
  enableHDR: false,
  screenTimeout: 30000, // 30秒 | 30 seconds
  
  // 其他设置 | Other settings
  crashReportingEnabled: true,
  usageAnalyticsEnabled: true,
  backgroundPlayEnabled: false,
  startupPage: 'home',
  enableGestureControl: true
};

export default class SettingService {
  private static instance: SettingService;
  
  /**
   * 检查对象是否包含指定属性 | Check if object contains specified property
   */
  private hasOwnProperty(obj: object, key: string): boolean {
    // ArkTS兼容实现：避免使用Object.prototype和call方法 | ArkTS compatible: avoid using Object.prototype and call method
    try {
      const keys = this.getOwnPropertyKeys(obj);
      for (const k of keys) {
        if (k === key) {
          return true;
        }
      }
      return false;
    } catch {
      return false;
    }
  }
  
  /**
   * 获取对象的所有自有属性键 | Get all own property keys of object
   */
  private getOwnPropertyKeys(obj: object): string[] {
    // ArkTS兼容实现：使用Object.keys | ArkTS compatible: use Object.keys
    return Object.keys(obj);
  }
  // 服务实例将在需要时直接调用 | Service instances will be called directly when needed
  private appSettings: AppSettings = DEFAULT_APP_SETTINGS;
  private userSettings: Map<string, AppSettings> = new Map();
  private isInitialized: boolean = false;
  
  // 监听器 | Listeners
  private generalListeners: Array<() => void> = [];
  private specificListeners: Map<string, Array<(event: SettingChangeEvent<SettingValue>) => void>> = new Map();
  private themeListeners: Array<(themeMode: ThemeMode, accentColor: string) => void> = [];
  private languageListeners: Array<(language: LanguageCode) => void> = [];

  /**
   * 获取单例实例 | Get singleton instance
   */
  public static getInstance(): SettingService {
    if (!SettingService.instance) {
      SettingService.instance = new SettingService();
    }
    return SettingService.instance;
  }

  /**
   * 构造函数 | Constructor
   */
  private constructor() {
    // 构造函数中不调用异步方法，由外部手动调用initialize
  }

  /**
   * 初始化设置服务 | Initialize setting service
   */
  public async initialize(): Promise<void> {
    if (this.isInitialized) {
      console.info(TAG + `: 设置服务已初始化 | Setting service already initialized`);
      return;
    }

    try {
      console.info(TAG + `: 正在初始化设置服务... | Initializing setting service...`);
      
      // 加载默认下载路径 | Load default download path
      this.appSettings.downloadPath = await this.getDefaultDownloadPath();
      
      // 加载应用全局设置 | Load app global settings
      await this.loadSettings();
      
      // 加载用户设置（如果已登录） | Load user settings (if logged in)
      const currentUser = UserService.getInstance().getCurrentUser();
      if (currentUser && !UserService.getInstance().isGuest()) {
        await this.loadUserSettings(currentUser.id);
      }
      
      // 应用当前主题和语言 | Apply current theme and language
      await this.applyTheme();
      await this.applyLanguage();
      
      // 添加用户变更监听器，以便在用户切换时加载相应的设置 | Add user change listener to load corresponding settings when user changes
      UserService.getInstance().addUserChangeListener(async (user) => {
        if (user && !UserService.getInstance().isGuest()) {
          await this.loadUserSettings(user.id);
          await this.applyTheme();
          await this.applyLanguage();
        }
      });
      
      this.isInitialized = true;
      console.info(TAG + `: 设置服务初始化成功 | Setting service initialized successfully`);
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      console.error(TAG + `: 设置服务初始化失败: | Failed to initialize setting service: `, err);
      // 使用默认设置继续 | Continue with default settings
      // 手动复制对象，兼容ArkTS
      this.appSettings = {
        // 主题相关 | Theme related
        themeMode: DEFAULT_APP_SETTINGS.themeMode,
        accentColor: DEFAULT_APP_SETTINGS.accentColor,
        darkThemeAccentColor: DEFAULT_APP_SETTINGS.darkThemeAccentColor,
        customTheme: DEFAULT_APP_SETTINGS.customTheme,
        
        // 语言相关 | Language related
        language: DEFAULT_APP_SETTINGS.language,
        autoDetectLanguage: DEFAULT_APP_SETTINGS.autoDetectLanguage,
        
        // 播放相关 | Playback related
        defaultPlaybackQuality: DEFAULT_APP_SETTINGS.defaultPlaybackQuality,
        autoPlayNext: DEFAULT_APP_SETTINGS.autoPlayNext,
        rememberPlaybackPosition: DEFAULT_APP_SETTINGS.rememberPlaybackPosition,
        playbackSpeed: DEFAULT_APP_SETTINGS.playbackSpeed,
        defaultVolume: DEFAULT_APP_SETTINGS.defaultVolume,
        
        // 字幕相关 | Subtitle related
        subtitleEnabled: DEFAULT_APP_SETTINGS.subtitleEnabled,
        subtitleLanguage: DEFAULT_APP_SETTINGS.subtitleLanguage,
        subtitleSize: DEFAULT_APP_SETTINGS.subtitleSize,
        subtitleStyle: DEFAULT_APP_SETTINGS.subtitleStyle,
        subtitleColor: DEFAULT_APP_SETTINGS.subtitleColor,
        subtitleBackgroundColor: DEFAULT_APP_SETTINGS.subtitleBackgroundColor,
        
        // 存储相关 | Storage related
        downloadPath: DEFAULT_APP_SETTINGS.downloadPath,
        cacheSizeLimit: DEFAULT_APP_SETTINGS.cacheSizeLimit,
        autoClearCache: DEFAULT_APP_SETTINGS.autoClearCache,
        cacheClearInterval: DEFAULT_APP_SETTINGS.cacheClearInterval,
        
        // 网络相关 | Network related
        networkTypeForPlayback: DEFAULT_APP_SETTINGS.networkTypeForPlayback,
        networkTypeForDownload: DEFAULT_APP_SETTINGS.networkTypeForDownload,
        bandwidthSaver: DEFAULT_APP_SETTINGS.bandwidthSaver,
        preloadEnabled: DEFAULT_APP_SETTINGS.preloadEnabled,
        preloadLimit: DEFAULT_APP_SETTINGS.preloadLimit,
        
        // 通知相关 | Notification related
        notificationsEnabled: DEFAULT_APP_SETTINGS.notificationsEnabled,
        notificationCategories: DEFAULT_APP_SETTINGS.notificationCategories.slice(),
        pushEnabled: DEFAULT_APP_SETTINGS.pushEnabled,
        

        
        // 外观相关 | Appearance related
        gridLayoutColumns: DEFAULT_APP_SETTINGS.gridLayoutColumns,
        showFileExtensions: DEFAULT_APP_SETTINGS.showFileExtensions,
        showHiddenFiles: DEFAULT_APP_SETTINGS.showHiddenFiles,
        defaultSortBy: DEFAULT_APP_SETTINGS.defaultSortBy,
        defaultSortOrder: DEFAULT_APP_SETTINGS.defaultSortOrder,
        
        // 设备相关 | Device related
        enableHardwareAcceleration: DEFAULT_APP_SETTINGS.enableHardwareAcceleration,
        enableDolbyAudio: DEFAULT_APP_SETTINGS.enableDolbyAudio,
        enableHDR: DEFAULT_APP_SETTINGS.enableHDR,
        screenTimeout: DEFAULT_APP_SETTINGS.screenTimeout,
        
        // 其他设置 | Other settings
        crashReportingEnabled: DEFAULT_APP_SETTINGS.crashReportingEnabled,
        usageAnalyticsEnabled: DEFAULT_APP_SETTINGS.usageAnalyticsEnabled,
        backgroundPlayEnabled: DEFAULT_APP_SETTINGS.backgroundPlayEnabled,
        startupPage: DEFAULT_APP_SETTINGS.startupPage,
        enableGestureControl: DEFAULT_APP_SETTINGS.enableGestureControl
      };
      this.isInitialized = true;
    }
  }

  /**
   * 获取默认下载路径 | Get default download path
   */
  private async getDefaultDownloadPath(): Promise<string> {
    try {
      // ArkTS兼容实现：使用内置的存储API获取路径 | ArkTS compatible: use built-in storage API to get path
      // 这里使用简化实现，返回应用缓存目录 | Simplified implementation, return app cache directory
      // 实际应用中应使用HarmonyOS提供的文件系统API | In actual app, use HarmonyOS file system API
      const cacheDir = '/data/storage/el2/base/cache';
      const downloadPath = `${cacheDir}/Download/RayTV`;
      
      console.info(TAG + `: 获取默认下载路径成功: ${downloadPath} | Default download path obtained: ${downloadPath}`);
      return downloadPath;
    } catch (error) {
      console.error(TAG + `: 获取默认下载路径失败: | Failed to get default download path: `, error);
      return '/tmp';
    }
  }

  /**
   * 加载应用设置 | Load app settings
   */
  private async loadSettings(): Promise<void> {
    try {
      const savedSettingsStr = await StorageUtil.getString(SETTINGS_STORAGE_KEY);
      if (savedSettingsStr) {
        const savedSettings = JSON.parse(savedSettingsStr) as AppSettings;
        // 手动合并设置，兼容ArkTS
        this.appSettings = {
          // 主题相关 | Theme related
          themeMode: savedSettings.themeMode || DEFAULT_APP_SETTINGS.themeMode,
          accentColor: savedSettings.accentColor || DEFAULT_APP_SETTINGS.accentColor,
          darkThemeAccentColor: savedSettings.darkThemeAccentColor || DEFAULT_APP_SETTINGS.darkThemeAccentColor,
          customTheme: savedSettings.customTheme || DEFAULT_APP_SETTINGS.customTheme,
          
          // 语言相关 | Language related
          language: savedSettings.language || DEFAULT_APP_SETTINGS.language,
          autoDetectLanguage: savedSettings.autoDetectLanguage !== undefined ? savedSettings.autoDetectLanguage : DEFAULT_APP_SETTINGS.autoDetectLanguage,
          
          // 播放相关 | Playback related
          defaultPlaybackQuality: savedSettings.defaultPlaybackQuality || DEFAULT_APP_SETTINGS.defaultPlaybackQuality,
          autoPlayNext: savedSettings.autoPlayNext !== undefined ? savedSettings.autoPlayNext : DEFAULT_APP_SETTINGS.autoPlayNext,
          rememberPlaybackPosition: savedSettings.rememberPlaybackPosition !== undefined ? savedSettings.rememberPlaybackPosition : DEFAULT_APP_SETTINGS.rememberPlaybackPosition,
          playbackSpeed: savedSettings.playbackSpeed || DEFAULT_APP_SETTINGS.playbackSpeed,
          defaultVolume: savedSettings.defaultVolume || DEFAULT_APP_SETTINGS.defaultVolume,
          
          // 字幕相关 | Subtitle related
          subtitleEnabled: savedSettings.subtitleEnabled !== undefined ? savedSettings.subtitleEnabled : DEFAULT_APP_SETTINGS.subtitleEnabled,
          subtitleLanguage: savedSettings.subtitleLanguage || DEFAULT_APP_SETTINGS.subtitleLanguage,
          subtitleSize: savedSettings.subtitleSize || DEFAULT_APP_SETTINGS.subtitleSize,
          subtitleStyle: savedSettings.subtitleStyle || DEFAULT_APP_SETTINGS.subtitleStyle,
          subtitleColor: savedSettings.subtitleColor || DEFAULT_APP_SETTINGS.subtitleColor,
          subtitleBackgroundColor: savedSettings.subtitleBackgroundColor || DEFAULT_APP_SETTINGS.subtitleBackgroundColor,
          
          // 存储相关 | Storage related
          downloadPath: savedSettings.downloadPath || DEFAULT_APP_SETTINGS.downloadPath,
          cacheSizeLimit: savedSettings.cacheSizeLimit || DEFAULT_APP_SETTINGS.cacheSizeLimit,
          autoClearCache: savedSettings.autoClearCache !== undefined ? savedSettings.autoClearCache : DEFAULT_APP_SETTINGS.autoClearCache,
          cacheClearInterval: savedSettings.cacheClearInterval || DEFAULT_APP_SETTINGS.cacheClearInterval,
          
          // 网络相关 | Network related
          networkTypeForPlayback: savedSettings.networkTypeForPlayback || DEFAULT_APP_SETTINGS.networkTypeForPlayback,
          networkTypeForDownload: savedSettings.networkTypeForDownload || DEFAULT_APP_SETTINGS.networkTypeForDownload,
          bandwidthSaver: savedSettings.bandwidthSaver !== undefined ? savedSettings.bandwidthSaver : DEFAULT_APP_SETTINGS.bandwidthSaver,
          preloadEnabled: savedSettings.preloadEnabled !== undefined ? savedSettings.preloadEnabled : DEFAULT_APP_SETTINGS.preloadEnabled,
          preloadLimit: savedSettings.preloadLimit || DEFAULT_APP_SETTINGS.preloadLimit,
          
          // 通知相关 | Notification related
          notificationsEnabled: savedSettings.notificationsEnabled !== undefined ? savedSettings.notificationsEnabled : DEFAULT_APP_SETTINGS.notificationsEnabled,
          notificationCategories: savedSettings.notificationCategories || DEFAULT_APP_SETTINGS.notificationCategories.slice(),
          pushEnabled: savedSettings.pushEnabled !== undefined ? savedSettings.pushEnabled : DEFAULT_APP_SETTINGS.pushEnabled,
          

          
          // 外观相关 | Appearance related
          gridLayoutColumns: savedSettings.gridLayoutColumns || DEFAULT_APP_SETTINGS.gridLayoutColumns,
          showFileExtensions: savedSettings.showFileExtensions !== undefined ? savedSettings.showFileExtensions : DEFAULT_APP_SETTINGS.showFileExtensions,
          showHiddenFiles: savedSettings.showHiddenFiles !== undefined ? savedSettings.showHiddenFiles : DEFAULT_APP_SETTINGS.showHiddenFiles,
          defaultSortBy: savedSettings.defaultSortBy || DEFAULT_APP_SETTINGS.defaultSortBy,
          defaultSortOrder: savedSettings.defaultSortOrder || DEFAULT_APP_SETTINGS.defaultSortOrder,
          
          // 设备相关 | Device related
          enableHardwareAcceleration: savedSettings.enableHardwareAcceleration !== undefined ? savedSettings.enableHardwareAcceleration : DEFAULT_APP_SETTINGS.enableHardwareAcceleration,
          enableDolbyAudio: savedSettings.enableDolbyAudio !== undefined ? savedSettings.enableDolbyAudio : DEFAULT_APP_SETTINGS.enableDolbyAudio,
          enableHDR: savedSettings.enableHDR !== undefined ? savedSettings.enableHDR : DEFAULT_APP_SETTINGS.enableHDR,
          screenTimeout: savedSettings.screenTimeout || DEFAULT_APP_SETTINGS.screenTimeout,
          
          // 其他设置 | Other settings
          crashReportingEnabled: savedSettings.crashReportingEnabled !== undefined ? savedSettings.crashReportingEnabled : DEFAULT_APP_SETTINGS.crashReportingEnabled,
          usageAnalyticsEnabled: savedSettings.usageAnalyticsEnabled !== undefined ? savedSettings.usageAnalyticsEnabled : DEFAULT_APP_SETTINGS.usageAnalyticsEnabled,
          backgroundPlayEnabled: savedSettings.backgroundPlayEnabled !== undefined ? savedSettings.backgroundPlayEnabled : DEFAULT_APP_SETTINGS.backgroundPlayEnabled,
          startupPage: savedSettings.startupPage || DEFAULT_APP_SETTINGS.startupPage,
          enableGestureControl: savedSettings.enableGestureControl !== undefined ? savedSettings.enableGestureControl : DEFAULT_APP_SETTINGS.enableGestureControl
        };
        console.info(TAG + '应用设置已从存储加载 | App settings loaded from storage');
      }
    } catch (error) {
      console.error(TAG + "加载应用设置失败: | Failed to load app settings: ", error);
    }
  }

  /**
   * 加载用户设置 | Load user settings
   */
  private async loadUserSettings(userId: string): Promise<void> {
    try {
      const userSettingsKey = `${USER_SETTINGS_KEY_PREFIX}${userId}`;
      const savedSettingsStr = await StorageUtil.getString(userSettingsKey);
      
      if (savedSettingsStr) {
        const savedSettings = JSON.parse(savedSettingsStr) as AppSettings;
        // 手动合并设置，兼容ArkTS
        const mergedSettings: AppSettings = {
          // 主题相关 | Theme related
          themeMode: savedSettings.themeMode || DEFAULT_APP_SETTINGS.themeMode,
          accentColor: savedSettings.accentColor || DEFAULT_APP_SETTINGS.accentColor,
          darkThemeAccentColor: savedSettings.darkThemeAccentColor || DEFAULT_APP_SETTINGS.darkThemeAccentColor,
          customTheme: savedSettings.customTheme || DEFAULT_APP_SETTINGS.customTheme,
          
          // 语言相关 | Language related
          language: savedSettings.language || DEFAULT_APP_SETTINGS.language,
          autoDetectLanguage: savedSettings.autoDetectLanguage !== undefined ? savedSettings.autoDetectLanguage : DEFAULT_APP_SETTINGS.autoDetectLanguage,
          
          // 播放相关 | Playback related
          defaultPlaybackQuality: savedSettings.defaultPlaybackQuality || DEFAULT_APP_SETTINGS.defaultPlaybackQuality,
          autoPlayNext: savedSettings.autoPlayNext !== undefined ? savedSettings.autoPlayNext : DEFAULT_APP_SETTINGS.autoPlayNext,
          rememberPlaybackPosition: savedSettings.rememberPlaybackPosition !== undefined ? savedSettings.rememberPlaybackPosition : DEFAULT_APP_SETTINGS.rememberPlaybackPosition,
          playbackSpeed: savedSettings.playbackSpeed || DEFAULT_APP_SETTINGS.playbackSpeed,
          defaultVolume: savedSettings.defaultVolume || DEFAULT_APP_SETTINGS.defaultVolume,
          
          // 字幕相关 | Subtitle related
          subtitleEnabled: savedSettings.subtitleEnabled !== undefined ? savedSettings.subtitleEnabled : DEFAULT_APP_SETTINGS.subtitleEnabled,
          subtitleLanguage: savedSettings.subtitleLanguage || DEFAULT_APP_SETTINGS.subtitleLanguage,
          subtitleSize: savedSettings.subtitleSize || DEFAULT_APP_SETTINGS.subtitleSize,
          subtitleStyle: savedSettings.subtitleStyle || DEFAULT_APP_SETTINGS.subtitleStyle,
          subtitleColor: savedSettings.subtitleColor || DEFAULT_APP_SETTINGS.subtitleColor,
          subtitleBackgroundColor: savedSettings.subtitleBackgroundColor || DEFAULT_APP_SETTINGS.subtitleBackgroundColor,
          
          // 存储相关 | Storage related
          downloadPath: savedSettings.downloadPath || DEFAULT_APP_SETTINGS.downloadPath,
          cacheSizeLimit: savedSettings.cacheSizeLimit || DEFAULT_APP_SETTINGS.cacheSizeLimit,
          autoClearCache: savedSettings.autoClearCache !== undefined ? savedSettings.autoClearCache : DEFAULT_APP_SETTINGS.autoClearCache,
          cacheClearInterval: savedSettings.cacheClearInterval || DEFAULT_APP_SETTINGS.cacheClearInterval,
          
          // 网络相关 | Network related
          networkTypeForPlayback: savedSettings.networkTypeForPlayback || DEFAULT_APP_SETTINGS.networkTypeForPlayback,
          networkTypeForDownload: savedSettings.networkTypeForDownload || DEFAULT_APP_SETTINGS.networkTypeForDownload,
          bandwidthSaver: savedSettings.bandwidthSaver !== undefined ? savedSettings.bandwidthSaver : DEFAULT_APP_SETTINGS.bandwidthSaver,
          preloadEnabled: savedSettings.preloadEnabled !== undefined ? savedSettings.preloadEnabled : DEFAULT_APP_SETTINGS.preloadEnabled,
          preloadLimit: savedSettings.preloadLimit || DEFAULT_APP_SETTINGS.preloadLimit,
          
          // 通知相关 | Notification related
          notificationsEnabled: savedSettings.notificationsEnabled !== undefined ? savedSettings.notificationsEnabled : DEFAULT_APP_SETTINGS.notificationsEnabled,
          notificationCategories: savedSettings.notificationCategories || DEFAULT_APP_SETTINGS.notificationCategories.slice(),
          pushEnabled: savedSettings.pushEnabled !== undefined ? savedSettings.pushEnabled : DEFAULT_APP_SETTINGS.pushEnabled,
          

          
          // 外观相关 | Appearance related
          gridLayoutColumns: savedSettings.gridLayoutColumns || DEFAULT_APP_SETTINGS.gridLayoutColumns,
          showFileExtensions: savedSettings.showFileExtensions !== undefined ? savedSettings.showFileExtensions : DEFAULT_APP_SETTINGS.showFileExtensions,
          showHiddenFiles: savedSettings.showHiddenFiles !== undefined ? savedSettings.showHiddenFiles : DEFAULT_APP_SETTINGS.showHiddenFiles,
          defaultSortBy: savedSettings.defaultSortBy || DEFAULT_APP_SETTINGS.defaultSortBy,
          defaultSortOrder: savedSettings.defaultSortOrder || DEFAULT_APP_SETTINGS.defaultSortOrder,
          
          // 设备相关 | Device related
          enableHardwareAcceleration: savedSettings.enableHardwareAcceleration !== undefined ? savedSettings.enableHardwareAcceleration : DEFAULT_APP_SETTINGS.enableHardwareAcceleration,
          enableDolbyAudio: savedSettings.enableDolbyAudio !== undefined ? savedSettings.enableDolbyAudio : DEFAULT_APP_SETTINGS.enableDolbyAudio,
          enableHDR: savedSettings.enableHDR !== undefined ? savedSettings.enableHDR : DEFAULT_APP_SETTINGS.enableHDR,
          screenTimeout: savedSettings.screenTimeout || DEFAULT_APP_SETTINGS.screenTimeout,
          
          // 其他设置 | Other settings
          crashReportingEnabled: savedSettings.crashReportingEnabled !== undefined ? savedSettings.crashReportingEnabled : DEFAULT_APP_SETTINGS.crashReportingEnabled,
          usageAnalyticsEnabled: savedSettings.usageAnalyticsEnabled !== undefined ? savedSettings.usageAnalyticsEnabled : DEFAULT_APP_SETTINGS.usageAnalyticsEnabled,
          backgroundPlayEnabled: savedSettings.backgroundPlayEnabled !== undefined ? savedSettings.backgroundPlayEnabled : DEFAULT_APP_SETTINGS.backgroundPlayEnabled,
          startupPage: savedSettings.startupPage || DEFAULT_APP_SETTINGS.startupPage,
          enableGestureControl: savedSettings.enableGestureControl !== undefined ? savedSettings.enableGestureControl : DEFAULT_APP_SETTINGS.enableGestureControl
        };
        this.userSettings.set(userId, mergedSettings);
        console.info(TAG + "已加载用户设置，用户ID: " + userId + " | User settings loaded for user: " + userId);
      }
    } catch (error) {
      console.error(TAG + "加载用户设置失败: | Failed to load user settings: ", error);
    }
  }

  /**
   * 保存应用设置 | Save app settings
   */
  private async saveSettings(): Promise<void> {
    try {
      const settingsStr = JSON.stringify(this.appSettings);
      await StorageUtil.putString(SETTINGS_STORAGE_KEY, settingsStr);
      console.info(TAG + '应用设置已保存到存储 | App settings saved to storage');
    } catch (error) {
      console.error(TAG + "保存应用设置失败: | Failed to save app settings: ", error);
    }
  }

  /**
   * 保存用户设置 | Save user settings
   */
  private async saveUserSettings(userId: string): Promise<void> {
    try {
      const userSettings = this.userSettings.get(userId);
      if (userSettings) {
        const userSettingsKey = `${USER_SETTINGS_KEY_PREFIX}${userId}`;
        const settingsStr = JSON.stringify(userSettings);
        await StorageUtil.putString(userSettingsKey, settingsStr);
        console.info(TAG + "已保存用户设置，用户ID: " + userId + " | User settings saved for user: " + userId);
      }
    } catch (error) {
      console.error(TAG + "保存用户设置失败: | Failed to save user settings: ", error);
    }
  }

  /**
   * 获取当前设置（考虑用户设置覆盖） | Get current settings (consider user settings override)
   */
  public getSettings(): AppSettings {
    const currentUser = UserService.getInstance().getCurrentUser();
    
    if (currentUser && !UserService.getInstance().isGuest()) {
      const userSettings = this.userSettings.get(currentUser.id);
      if (userSettings) {
        // 手动复制对象，兼容ArkTS
        return {
          // 主题相关 | Theme related
          themeMode: userSettings.themeMode,
          accentColor: userSettings.accentColor,
          darkThemeAccentColor: userSettings.darkThemeAccentColor,
          customTheme: userSettings.customTheme,
          
          // 语言相关 | Language related
          language: userSettings.language,
          autoDetectLanguage: userSettings.autoDetectLanguage,
          
          // 播放相关 | Playback related
          defaultPlaybackQuality: userSettings.defaultPlaybackQuality,
          autoPlayNext: userSettings.autoPlayNext,
          rememberPlaybackPosition: userSettings.rememberPlaybackPosition,
          playbackSpeed: userSettings.playbackSpeed,
          defaultVolume: userSettings.defaultVolume,
          
          // 字幕相关 | Subtitle related
          subtitleEnabled: userSettings.subtitleEnabled,
          subtitleLanguage: userSettings.subtitleLanguage,
          subtitleSize: userSettings.subtitleSize,
          subtitleStyle: userSettings.subtitleStyle,
          subtitleColor: userSettings.subtitleColor,
          subtitleBackgroundColor: userSettings.subtitleBackgroundColor,
          
          // 存储相关 | Storage related
          downloadPath: userSettings.downloadPath,
          cacheSizeLimit: userSettings.cacheSizeLimit,
          autoClearCache: userSettings.autoClearCache,
          cacheClearInterval: userSettings.cacheClearInterval,
          
          // 网络相关 | Network related
          networkTypeForPlayback: userSettings.networkTypeForPlayback,
          networkTypeForDownload: userSettings.networkTypeForDownload,
          bandwidthSaver: userSettings.bandwidthSaver,
          preloadEnabled: userSettings.preloadEnabled,
          preloadLimit: userSettings.preloadLimit,
          
          // 通知相关 | Notification related
          notificationsEnabled: userSettings.notificationsEnabled,
          notificationCategories: userSettings.notificationCategories.slice(),
          pushEnabled: userSettings.pushEnabled,
          

          
          // 外观相关 | Appearance related
          gridLayoutColumns: userSettings.gridLayoutColumns,
          showFileExtensions: userSettings.showFileExtensions,
          showHiddenFiles: userSettings.showHiddenFiles,
          defaultSortBy: userSettings.defaultSortBy,
          defaultSortOrder: userSettings.defaultSortOrder,
          
          // 设备相关 | Device related
          enableHardwareAcceleration: userSettings.enableHardwareAcceleration,
          enableDolbyAudio: userSettings.enableDolbyAudio,
          enableHDR: userSettings.enableHDR,
          screenTimeout: userSettings.screenTimeout,
          
          // 其他设置 | Other settings
          crashReportingEnabled: userSettings.crashReportingEnabled,
          usageAnalyticsEnabled: userSettings.usageAnalyticsEnabled,
          backgroundPlayEnabled: userSettings.backgroundPlayEnabled,
          startupPage: userSettings.startupPage,
          enableGestureControl: userSettings.enableGestureControl
        };
      }
    }
    
    const appSettings = this.appSettings;
    // 手动复制对象，兼容ArkTS
    return {
      // 主题相关 | Theme related
      themeMode: appSettings.themeMode,
      accentColor: appSettings.accentColor,
      darkThemeAccentColor: appSettings.darkThemeAccentColor,
      customTheme: appSettings.customTheme,
      
      // 语言相关 | Language related
      language: appSettings.language,
      autoDetectLanguage: appSettings.autoDetectLanguage,
      
      // 播放相关 | Playback related
      defaultPlaybackQuality: appSettings.defaultPlaybackQuality,
      autoPlayNext: appSettings.autoPlayNext,
      rememberPlaybackPosition: appSettings.rememberPlaybackPosition,
      playbackSpeed: appSettings.playbackSpeed,
      defaultVolume: appSettings.defaultVolume,
      
      // 字幕相关 | Subtitle related
      subtitleEnabled: appSettings.subtitleEnabled,
      subtitleLanguage: appSettings.subtitleLanguage,
      subtitleSize: appSettings.subtitleSize,
      subtitleStyle: appSettings.subtitleStyle,
      subtitleColor: appSettings.subtitleColor,
      subtitleBackgroundColor: appSettings.subtitleBackgroundColor,
      
      // 存储相关 | Storage related
      downloadPath: appSettings.downloadPath,
      cacheSizeLimit: appSettings.cacheSizeLimit,
      autoClearCache: appSettings.autoClearCache,
      cacheClearInterval: appSettings.cacheClearInterval,
      
      // 网络相关 | Network related
      networkTypeForPlayback: appSettings.networkTypeForPlayback,
      networkTypeForDownload: appSettings.networkTypeForDownload,
      bandwidthSaver: appSettings.bandwidthSaver,
      preloadEnabled: appSettings.preloadEnabled,
      preloadLimit: appSettings.preloadLimit,
      
      // 通知相关 | Notification related
      notificationsEnabled: appSettings.notificationsEnabled,
      notificationCategories: appSettings.notificationCategories.slice(),
      pushEnabled: appSettings.pushEnabled,
      

      
      // 外观相关 | Appearance related
      gridLayoutColumns: appSettings.gridLayoutColumns,
      showFileExtensions: appSettings.showFileExtensions,
      showHiddenFiles: appSettings.showHiddenFiles,
      defaultSortBy: appSettings.defaultSortBy,
      defaultSortOrder: appSettings.defaultSortOrder,
      
      // 设备相关 | Device related
      enableHardwareAcceleration: appSettings.enableHardwareAcceleration,
      enableDolbyAudio: appSettings.enableDolbyAudio,
      enableHDR: appSettings.enableHDR,
      screenTimeout: appSettings.screenTimeout,
      
      // 其他设置 | Other settings
      crashReportingEnabled: appSettings.crashReportingEnabled,
      usageAnalyticsEnabled: appSettings.usageAnalyticsEnabled,
      backgroundPlayEnabled: appSettings.backgroundPlayEnabled,
      startupPage: appSettings.startupPage,
      enableGestureControl: appSettings.enableGestureControl
    };
  }

  /**
   * 获取指定设置值 | Get specified setting value
   */
  public getSetting<K extends keyof AppSettings>(key: K): AppSettings[K] {
    const settings = this.getSettings();
    return settings[key];
  }

  /**
   * 设置指定设置值 | Set specified setting value
   */
  public async setSetting<K extends keyof AppSettings>(key: K, value: AppSettings[K], userInitiated: boolean = true): Promise<boolean> {
    try {
      const oldValue = this.getSetting(key);
      
      // 检查是否需要特殊处理 | Check if special handling is needed
      if (oldValue === value) {
        return true; // 值未变化 | Value unchanged
      }
      
      // 确定是应用设置还是用户设置 | Determine if it's app setting or user setting
      const currentUser = UserService.getInstance().getCurrentUser();
      const isUserSetting = currentUser && !UserService.getInstance().isGuest();
      
      if (isUserSetting) {
        // 确保用户设置对象存在 | Ensure user settings object exists
        let userSettings = this.userSettings.get(currentUser.id);
        if (!userSettings) {
          // 手动复制对象，兼容ArkTS
          userSettings = {
            // 主题相关 | Theme related
            themeMode: DEFAULT_APP_SETTINGS.themeMode,
            accentColor: DEFAULT_APP_SETTINGS.accentColor,
            darkThemeAccentColor: DEFAULT_APP_SETTINGS.darkThemeAccentColor,
            customTheme: DEFAULT_APP_SETTINGS.customTheme,
            
            // 语言相关 | Language related
            language: DEFAULT_APP_SETTINGS.language,
            autoDetectLanguage: DEFAULT_APP_SETTINGS.autoDetectLanguage,
            
            // 播放相关 | Playback related
            defaultPlaybackQuality: DEFAULT_APP_SETTINGS.defaultPlaybackQuality,
            autoPlayNext: DEFAULT_APP_SETTINGS.autoPlayNext,
            rememberPlaybackPosition: DEFAULT_APP_SETTINGS.rememberPlaybackPosition,
            playbackSpeed: DEFAULT_APP_SETTINGS.playbackSpeed,
            defaultVolume: DEFAULT_APP_SETTINGS.defaultVolume,
            
            // 字幕相关 | Subtitle related
            subtitleEnabled: DEFAULT_APP_SETTINGS.subtitleEnabled,
            subtitleLanguage: DEFAULT_APP_SETTINGS.subtitleLanguage,
            subtitleSize: DEFAULT_APP_SETTINGS.subtitleSize,
            subtitleStyle: DEFAULT_APP_SETTINGS.subtitleStyle,
            subtitleColor: DEFAULT_APP_SETTINGS.subtitleColor,
            subtitleBackgroundColor: DEFAULT_APP_SETTINGS.subtitleBackgroundColor,
            
            // 存储相关 | Storage related
            downloadPath: DEFAULT_APP_SETTINGS.downloadPath,
            cacheSizeLimit: DEFAULT_APP_SETTINGS.cacheSizeLimit,
            autoClearCache: DEFAULT_APP_SETTINGS.autoClearCache,
            cacheClearInterval: DEFAULT_APP_SETTINGS.cacheClearInterval,
            
            // 网络相关 | Network related
            networkTypeForPlayback: DEFAULT_APP_SETTINGS.networkTypeForPlayback,
            networkTypeForDownload: DEFAULT_APP_SETTINGS.networkTypeForDownload,
            bandwidthSaver: DEFAULT_APP_SETTINGS.bandwidthSaver,
            preloadEnabled: DEFAULT_APP_SETTINGS.preloadEnabled,
            preloadLimit: DEFAULT_APP_SETTINGS.preloadLimit,
            
            // 通知相关 | Notification related
            notificationsEnabled: DEFAULT_APP_SETTINGS.notificationsEnabled,
            notificationCategories: DEFAULT_APP_SETTINGS.notificationCategories.slice(),
            pushEnabled: DEFAULT_APP_SETTINGS.pushEnabled,
            

            
            // 外观相关 | Appearance related
            gridLayoutColumns: DEFAULT_APP_SETTINGS.gridLayoutColumns,
            showFileExtensions: DEFAULT_APP_SETTINGS.showFileExtensions,
            showHiddenFiles: DEFAULT_APP_SETTINGS.showHiddenFiles,
            defaultSortBy: DEFAULT_APP_SETTINGS.defaultSortBy,
            defaultSortOrder: DEFAULT_APP_SETTINGS.defaultSortOrder,
            
            // 设备相关 | Device related
            enableHardwareAcceleration: DEFAULT_APP_SETTINGS.enableHardwareAcceleration,
            enableDolbyAudio: DEFAULT_APP_SETTINGS.enableDolbyAudio,
            enableHDR: DEFAULT_APP_SETTINGS.enableHDR,
            screenTimeout: DEFAULT_APP_SETTINGS.screenTimeout,
            
            // 其他设置 | Other settings
            crashReportingEnabled: DEFAULT_APP_SETTINGS.crashReportingEnabled,
            usageAnalyticsEnabled: DEFAULT_APP_SETTINGS.usageAnalyticsEnabled,
            backgroundPlayEnabled: DEFAULT_APP_SETTINGS.backgroundPlayEnabled,
            startupPage: DEFAULT_APP_SETTINGS.startupPage,
            enableGestureControl: DEFAULT_APP_SETTINGS.enableGestureControl
          };
          this.userSettings.set(currentUser.id, userSettings);
        }
        // 更新用户设置 | Update user settings
        userSettings[key] = value;
        this.userSettings.set(currentUser.id, userSettings);
        await this.saveUserSettings(currentUser.id);
      } else {
        // 更新应用设置 | Update app settings
        this.appSettings[key] = value;
        await this.saveSettings();
      }
      
      // 触发设置变更事件 | Trigger setting change event
      this.notifySettingChanged(key as string, oldValue, value, userInitiated);
      
      // 处理特殊设置项的应用 | Handle special setting application
      await this.handleSpecialSetting(key, value);
      
      console.info(TAG + "设置项 " + key + " 已更新为: " + String(value) + " | Setting " + key + " updated to: " + String(value));
      return true;
    } catch (error) {
      console.error(TAG + "设置项 " + key + " 更新失败: | Failed to set setting " + key + ": ", error);
      return false;
    }
  }

  /**
   * 批量设置多个设置值 | Batch set multiple setting values
   */
  public async setMultipleSettings(updates: Partial<AppSettings>, userInitiated: boolean = true): Promise<boolean> {
    try {
      const changedKeys: Array<{ key: string, oldValue: SettingValue, newValue: SettingValue }> = [];
      
      // 收集所有要修改的设置 | Collect all settings to modify
      const keys = this.getOwnPropertyKeys(updates);
      for (const key of keys) {
        if (this.hasOwnProperty(updates, key)) {
          // 避免使用any类型，使用更具体的类型断言 | Avoid using any type, use more specific type assertion
          const newValue = updates[key as keyof AppSettings];
          const oldValue = this.getSetting(key as keyof AppSettings);
          if (oldValue !== newValue) {
            changedKeys.push({ key, oldValue, newValue });
          }
        }
      }
      
      if (changedKeys.length === 0) {
        return true; // 没有需要修改的设置 | No settings need to be modified
      }
      
      // 确定是应用设置还是用户设置 | Determine if it's app setting or user setting
      const currentUser = UserService.getInstance().getCurrentUser();
      const isUserSetting = currentUser && !UserService.getInstance().isGuest();
      
      // 批量更新设置 | Batch update settings
      for (let i = 0; i < changedKeys.length; i++) {
        const change = changedKeys[i];
        const key = change.key;
        const newValue = change.newValue;
        if (isUserSetting) {
          let userSettings = this.userSettings.get(currentUser.id);
          if (!userSettings) {
            // 手动复制对象，兼容ArkTS
            userSettings = {
              // 主题相关 | Theme related
              themeMode: DEFAULT_APP_SETTINGS.themeMode,
              accentColor: DEFAULT_APP_SETTINGS.accentColor,
              darkThemeAccentColor: DEFAULT_APP_SETTINGS.darkThemeAccentColor,
              customTheme: DEFAULT_APP_SETTINGS.customTheme,
              
              // 语言相关 | Language related
              language: DEFAULT_APP_SETTINGS.language,
              autoDetectLanguage: DEFAULT_APP_SETTINGS.autoDetectLanguage,
              
              // 播放相关 | Playback related
              defaultPlaybackQuality: DEFAULT_APP_SETTINGS.defaultPlaybackQuality,
              autoPlayNext: DEFAULT_APP_SETTINGS.autoPlayNext,
              rememberPlaybackPosition: DEFAULT_APP_SETTINGS.rememberPlaybackPosition,
              playbackSpeed: DEFAULT_APP_SETTINGS.playbackSpeed,
              defaultVolume: DEFAULT_APP_SETTINGS.defaultVolume,
              
              // 字幕相关 | Subtitle related
              subtitleEnabled: DEFAULT_APP_SETTINGS.subtitleEnabled,
              subtitleLanguage: DEFAULT_APP_SETTINGS.subtitleLanguage,
              subtitleSize: DEFAULT_APP_SETTINGS.subtitleSize,
              subtitleStyle: DEFAULT_APP_SETTINGS.subtitleStyle,
              subtitleColor: DEFAULT_APP_SETTINGS.subtitleColor,
              subtitleBackgroundColor: DEFAULT_APP_SETTINGS.subtitleBackgroundColor,
              
              // 存储相关 | Storage related
              downloadPath: DEFAULT_APP_SETTINGS.downloadPath,
              cacheSizeLimit: DEFAULT_APP_SETTINGS.cacheSizeLimit,
              autoClearCache: DEFAULT_APP_SETTINGS.autoClearCache,
              cacheClearInterval: DEFAULT_APP_SETTINGS.cacheClearInterval,
              
              // 网络相关 | Network related
              networkTypeForPlayback: DEFAULT_APP_SETTINGS.networkTypeForPlayback,
              networkTypeForDownload: DEFAULT_APP_SETTINGS.networkTypeForDownload,
              bandwidthSaver: DEFAULT_APP_SETTINGS.bandwidthSaver,
              preloadEnabled: DEFAULT_APP_SETTINGS.preloadEnabled,
              preloadLimit: DEFAULT_APP_SETTINGS.preloadLimit,
              
              // 通知相关 | Notification related
              notificationsEnabled: DEFAULT_APP_SETTINGS.notificationsEnabled,
              notificationCategories: DEFAULT_APP_SETTINGS.notificationCategories.slice(),
              pushEnabled: DEFAULT_APP_SETTINGS.pushEnabled,
              

              
              // 外观相关 | Appearance related
              gridLayoutColumns: DEFAULT_APP_SETTINGS.gridLayoutColumns,
              showFileExtensions: DEFAULT_APP_SETTINGS.showFileExtensions,
              showHiddenFiles: DEFAULT_APP_SETTINGS.showHiddenFiles,
              defaultSortBy: DEFAULT_APP_SETTINGS.defaultSortBy,
              defaultSortOrder: DEFAULT_APP_SETTINGS.defaultSortOrder,
              
              // 设备相关 | Device related
              enableHardwareAcceleration: DEFAULT_APP_SETTINGS.enableHardwareAcceleration,
              enableDolbyAudio: DEFAULT_APP_SETTINGS.enableDolbyAudio,
              enableHDR: DEFAULT_APP_SETTINGS.enableHDR,
              screenTimeout: DEFAULT_APP_SETTINGS.screenTimeout,
              
              // 其他设置 | Other settings
              crashReportingEnabled: DEFAULT_APP_SETTINGS.crashReportingEnabled,
              usageAnalyticsEnabled: DEFAULT_APP_SETTINGS.usageAnalyticsEnabled,
              backgroundPlayEnabled: DEFAULT_APP_SETTINGS.backgroundPlayEnabled,
              startupPage: DEFAULT_APP_SETTINGS.startupPage,
              enableGestureControl: DEFAULT_APP_SETTINGS.enableGestureControl
            };
            this.userSettings.set(currentUser.id, userSettings);
          }
          userSettings[key as keyof AppSettings] = newValue as AppSettings[keyof AppSettings];
          this.userSettings.set(currentUser.id, userSettings);
        } else {
          this.appSettings[key as keyof AppSettings] = newValue as AppSettings[keyof AppSettings];
        }
      }
      
      // 保存设置 | Save settings
      if (isUserSetting) {
        await this.saveUserSettings(currentUser.id);
      } else {
        await this.saveSettings();
      }
      
      // 触发设置变更事件 | Trigger setting change events
      for (let i = 0; i < changedKeys.length; i++) {
        const change = changedKeys[i];
        const key = change.key;
        const oldValue = change.oldValue;
        const newValue = change.newValue;
        this.notifySettingChanged(key, oldValue, newValue, userInitiated);
        // 处理特殊设置项 | Handle special setting items
        await this.handleSpecialSetting(key as keyof AppSettings, newValue as AppSettings[keyof AppSettings]);
      }
      
      // 触发通用设置变更事件 | Trigger general setting change event
      this.notifySettingsChanged();
      
      console.info(TAG + "已批量更新 " + changedKeys.length + " 个设置项 | Batch updated " + changedKeys.length + " settings");
      return true;
    } catch (error) {
      console.error(TAG + "批量更新设置失败: | Failed to set multiple settings: ", error);
      return false;
    }
  }

  /**
   * 处理需要特殊应用的设置项 | Handle setting items that need special application
   */
  private async handleSpecialSetting<K extends keyof AppSettings>(key: K, value: AppSettings[K]): Promise<void> {
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
      case 'downloadPath':
        // 验证下载路径是否有效 | Validate if download path is valid
        await this.validateDownloadPath(value as string);
        break;
    }
  }

  /**
   * 应用当前主题设置 | Apply current theme settings
   */
  private async applyTheme(): Promise<void> {
    const themeMode = this.getSetting('themeMode');
    const accentColor = themeMode === ThemeMode.DARK 
      ? this.getSetting('darkThemeAccentColor') 
      : this.getSetting('accentColor');
    
    try {
      // ArkTS兼容实现：不使用globalThis.uiService，直接通知监听器 | ArkTS compatible: don't use globalThis.uiService, directly notify listeners
      console.info(TAG + "正在应用主题: " + themeMode + ", 强调色: " + accentColor + " | Applying theme: " + themeMode + ", accent color: " + accentColor);
      
      // 通知主题监听器 | Notify theme listeners
      this.notifyThemeChanged(themeMode, accentColor);
    } catch (error) {
      console.error(TAG + "应用主题失败: | Failed to apply theme: ", error);
    }
  }

  /**
   * 应用当前语言设置 | Apply current language settings
   */
  private async applyLanguage(): Promise<void> {
    let language = this.getSetting('language');
    
    if (this.getSetting('autoDetectLanguage')) {
      // 尝试检测系统语言 | Try to detect system language
      const systemLanguage = await this.detectSystemLanguage();
      if (systemLanguage) {
        language = systemLanguage;
      }
    }
    
    try {
      // ArkTS兼容实现：不使用globalThis.appContext，直接通知监听器 | ArkTS compatible: don't use globalThis.appContext, directly notify listeners
      console.info(TAG + "正在应用语言: " + language + " | Applying language: " + language);
      
      // 通知语言监听器 | Notify language listeners
      this.notifyLanguageChanged(language);
    } catch (error) {
      console.error(TAG + "应用语言失败: | Failed to apply language: ", error);
    }
  }

  /**
   * 检测系统语言 | Detect system language
   */
  private async detectSystemLanguage(): Promise<LanguageCode | null> {
    try {
      // ArkTS兼容实现：返回默认语言，不使用globalThis.appContext | ArkTS compatible: return default language, don't use globalThis.appContext
      // 实际应用中应使用HarmonyOS提供的国际化API | In actual app, use HarmonyOS internationalization API
      console.info(TAG + "检测到系统语言: zh_CN | System language detected: zh_CN");
      return LanguageCode.SIMPLIFIED_CHINESE;
    } catch (error) {
      console.error(TAG + "检测系统语言失败: | Failed to detect system language: ", error);
      return null;
    }
  }

  /**
   * 验证下载路径 | Validate download path
   */
  private async validateDownloadPath(path: string): Promise<boolean> {
    try {
      // ArkTS兼容实现：简化验证，不使用globalThis.fileManager | ArkTS compatible: simplified validation, don't use globalThis.fileManager
      if (!path || path.length < 3) {
        throw new Error('Invalid download path');
      }
      
      // 基本路径格式验证 | Basic path format validation
      if (!path.startsWith('/')) {
        throw new Error('Download path must be absolute');
      }
      
      console.info(TAG + "下载路径验证通过: " + path + " | Validated download path: " + path);
      return true;
    } catch (error) {
      console.error(TAG + "无效的下载路径: | Invalid download path: ", error);
      // 恢复默认路径 | Restore default path
      this.setSetting('downloadPath', await this.getDefaultDownloadPath(), false);
      return false;
    }
  }

  /**
   * 重置所有设置为默认值 | Reset all settings to default values
   */
  public async resetAllSettings(): Promise<boolean> {
    try {
      // 重置应用设置 | Reset app settings
      // 手动复制对象，兼容ArkTS
      this.appSettings = {
        // 主题相关 | Theme related
        themeMode: DEFAULT_APP_SETTINGS.themeMode,
        accentColor: DEFAULT_APP_SETTINGS.accentColor,
        darkThemeAccentColor: DEFAULT_APP_SETTINGS.darkThemeAccentColor,
        customTheme: DEFAULT_APP_SETTINGS.customTheme,
        
        // 语言相关 | Language related
        language: DEFAULT_APP_SETTINGS.language,
        autoDetectLanguage: DEFAULT_APP_SETTINGS.autoDetectLanguage,
        
        // 播放相关 | Playback related
        defaultPlaybackQuality: DEFAULT_APP_SETTINGS.defaultPlaybackQuality,
        autoPlayNext: DEFAULT_APP_SETTINGS.autoPlayNext,
        rememberPlaybackPosition: DEFAULT_APP_SETTINGS.rememberPlaybackPosition,
        playbackSpeed: DEFAULT_APP_SETTINGS.playbackSpeed,
        defaultVolume: DEFAULT_APP_SETTINGS.defaultVolume,
        
        // 字幕相关 | Subtitle related
        subtitleEnabled: DEFAULT_APP_SETTINGS.subtitleEnabled,
        subtitleLanguage: DEFAULT_APP_SETTINGS.subtitleLanguage,
        subtitleSize: DEFAULT_APP_SETTINGS.subtitleSize,
        subtitleStyle: DEFAULT_APP_SETTINGS.subtitleStyle,
        subtitleColor: DEFAULT_APP_SETTINGS.subtitleColor,
        subtitleBackgroundColor: DEFAULT_APP_SETTINGS.subtitleBackgroundColor,
        
        // 存储相关 | Storage related
        downloadPath: DEFAULT_APP_SETTINGS.downloadPath,
        cacheSizeLimit: DEFAULT_APP_SETTINGS.cacheSizeLimit,
        autoClearCache: DEFAULT_APP_SETTINGS.autoClearCache,
        cacheClearInterval: DEFAULT_APP_SETTINGS.cacheClearInterval,
        
        // 网络相关 | Network related
        networkTypeForPlayback: DEFAULT_APP_SETTINGS.networkTypeForPlayback,
        networkTypeForDownload: DEFAULT_APP_SETTINGS.networkTypeForDownload,
        bandwidthSaver: DEFAULT_APP_SETTINGS.bandwidthSaver,
        preloadEnabled: DEFAULT_APP_SETTINGS.preloadEnabled,
        preloadLimit: DEFAULT_APP_SETTINGS.preloadLimit,
        
        // 通知相关 | Notification related
        notificationsEnabled: DEFAULT_APP_SETTINGS.notificationsEnabled,
        notificationCategories: DEFAULT_APP_SETTINGS.notificationCategories.slice(),
        pushEnabled: DEFAULT_APP_SETTINGS.pushEnabled,
        

        
        // 外观相关 | Appearance related
        gridLayoutColumns: DEFAULT_APP_SETTINGS.gridLayoutColumns,
        showFileExtensions: DEFAULT_APP_SETTINGS.showFileExtensions,
        showHiddenFiles: DEFAULT_APP_SETTINGS.showHiddenFiles,
        defaultSortBy: DEFAULT_APP_SETTINGS.defaultSortBy,
        defaultSortOrder: DEFAULT_APP_SETTINGS.defaultSortOrder,
        
        // 设备相关 | Device related
        enableHardwareAcceleration: DEFAULT_APP_SETTINGS.enableHardwareAcceleration,
        enableDolbyAudio: DEFAULT_APP_SETTINGS.enableDolbyAudio,
        enableHDR: DEFAULT_APP_SETTINGS.enableHDR,
        screenTimeout: DEFAULT_APP_SETTINGS.screenTimeout,
        
        // 其他设置 | Other settings
        crashReportingEnabled: DEFAULT_APP_SETTINGS.crashReportingEnabled,
        usageAnalyticsEnabled: DEFAULT_APP_SETTINGS.usageAnalyticsEnabled,
        backgroundPlayEnabled: DEFAULT_APP_SETTINGS.backgroundPlayEnabled,
        startupPage: DEFAULT_APP_SETTINGS.startupPage,
        enableGestureControl: DEFAULT_APP_SETTINGS.enableGestureControl
      };
      this.appSettings.downloadPath = await this.getDefaultDownloadPath();
      await this.saveSettings();
      
      // 重置当前用户设置 | Reset current user settings
      const currentUser = UserService.getInstance().getCurrentUser();
      if (currentUser && !UserService.getInstance().isGuest()) {
        // 手动复制对象，兼容ArkTS
        const defaultUserSettings: AppSettings = {
          // 主题相关 | Theme related
          themeMode: DEFAULT_APP_SETTINGS.themeMode,
          accentColor: DEFAULT_APP_SETTINGS.accentColor,
          darkThemeAccentColor: DEFAULT_APP_SETTINGS.darkThemeAccentColor,
          customTheme: DEFAULT_APP_SETTINGS.customTheme,
          
          // 语言相关 | Language related
          language: DEFAULT_APP_SETTINGS.language,
          autoDetectLanguage: DEFAULT_APP_SETTINGS.autoDetectLanguage,
          
          // 播放相关 | Playback related
          defaultPlaybackQuality: DEFAULT_APP_SETTINGS.defaultPlaybackQuality,
          autoPlayNext: DEFAULT_APP_SETTINGS.autoPlayNext,
          rememberPlaybackPosition: DEFAULT_APP_SETTINGS.rememberPlaybackPosition,
          playbackSpeed: DEFAULT_APP_SETTINGS.playbackSpeed,
          defaultVolume: DEFAULT_APP_SETTINGS.defaultVolume,
          
          // 字幕相关 | Subtitle related
          subtitleEnabled: DEFAULT_APP_SETTINGS.subtitleEnabled,
          subtitleLanguage: DEFAULT_APP_SETTINGS.subtitleLanguage,
          subtitleSize: DEFAULT_APP_SETTINGS.subtitleSize,
          subtitleStyle: DEFAULT_APP_SETTINGS.subtitleStyle,
          subtitleColor: DEFAULT_APP_SETTINGS.subtitleColor,
          subtitleBackgroundColor: DEFAULT_APP_SETTINGS.subtitleBackgroundColor,
          
          // 存储相关 | Storage related
          downloadPath: DEFAULT_APP_SETTINGS.downloadPath,
          cacheSizeLimit: DEFAULT_APP_SETTINGS.cacheSizeLimit,
          autoClearCache: DEFAULT_APP_SETTINGS.autoClearCache,
          cacheClearInterval: DEFAULT_APP_SETTINGS.cacheClearInterval,
          
          // 网络相关 | Network related
          networkTypeForPlayback: DEFAULT_APP_SETTINGS.networkTypeForPlayback,
          networkTypeForDownload: DEFAULT_APP_SETTINGS.networkTypeForDownload,
          bandwidthSaver: DEFAULT_APP_SETTINGS.bandwidthSaver,
          preloadEnabled: DEFAULT_APP_SETTINGS.preloadEnabled,
          preloadLimit: DEFAULT_APP_SETTINGS.preloadLimit,
          
          // 通知相关 | Notification related
          notificationsEnabled: DEFAULT_APP_SETTINGS.notificationsEnabled,
          notificationCategories: DEFAULT_APP_SETTINGS.notificationCategories.slice(),
          pushEnabled: DEFAULT_APP_SETTINGS.pushEnabled,
          

          
          // 外观相关 | Appearance related
          gridLayoutColumns: DEFAULT_APP_SETTINGS.gridLayoutColumns,
          showFileExtensions: DEFAULT_APP_SETTINGS.showFileExtensions,
          showHiddenFiles: DEFAULT_APP_SETTINGS.showHiddenFiles,
          defaultSortBy: DEFAULT_APP_SETTINGS.defaultSortBy,
          defaultSortOrder: DEFAULT_APP_SETTINGS.defaultSortOrder,
          
          // 设备相关 | Device related
          enableHardwareAcceleration: DEFAULT_APP_SETTINGS.enableHardwareAcceleration,
          enableDolbyAudio: DEFAULT_APP_SETTINGS.enableDolbyAudio,
          enableHDR: DEFAULT_APP_SETTINGS.enableHDR,
          screenTimeout: DEFAULT_APP_SETTINGS.screenTimeout,
          
          // 其他设置 | Other settings
          crashReportingEnabled: DEFAULT_APP_SETTINGS.crashReportingEnabled,
          usageAnalyticsEnabled: DEFAULT_APP_SETTINGS.usageAnalyticsEnabled,
          backgroundPlayEnabled: DEFAULT_APP_SETTINGS.backgroundPlayEnabled,
          startupPage: DEFAULT_APP_SETTINGS.startupPage,
          enableGestureControl: DEFAULT_APP_SETTINGS.enableGestureControl
        };
        // 更新下载路径为最新的默认路径 | Update download path to latest default path
        defaultUserSettings.downloadPath = this.appSettings.downloadPath;
        // 使用Map的set方法更新用户设置 | Use Map's set method to update user settings
        this.userSettings.set(currentUser.id, defaultUserSettings);
        await this.saveUserSettings(currentUser.id);
      }
      
      // 应用默认主题和语言 | Apply default theme and language
      await this.applyTheme();
      await this.applyLanguage();
      
      // 通知设置变更 | Notify setting changes
      this.notifySettingsChanged();
      
      console.info(TAG + '所有设置已重置为默认值 | All settings reset to default');
      return true;
    } catch (error) {
      console.error(TAG + "重置设置失败: | Failed to reset settings: ", error);
      return false;
    }
  }

  /**
   * 获取设置项的默认值 | Get default value of setting item
   */
  public getDefaultSetting<K extends keyof AppSettings>(key: K): AppSettings[K] {
    return DEFAULT_APP_SETTINGS[key];
  }

  /**
   * 检查设置是否被修改（与默认值比较） | Check if setting is modified (compared to default value)
   */
  public isSettingModified<K extends keyof AppSettings>(key: K): boolean {
    return this.getSetting(key) !== DEFAULT_APP_SETTINGS[key];
  }

  /**
   * 获取所有被修改的设置项 | Get all modified setting items
   */
  public getModifiedSettings(): Partial<AppSettings> {
    const modified: Partial<AppSettings> = {};
    const settings = this.getSettings();
    
    // 手动检查每个设置项，避免使用索引签名 | Manually check each setting item, avoid using index signature
    const settingKeys: Array<keyof AppSettings> = [
      'themeMode', 'accentColor', 'darkThemeAccentColor', 'customTheme',
      'language', 'autoDetectLanguage',
      'defaultPlaybackQuality', 'autoPlayNext', 'rememberPlaybackPosition', 'playbackSpeed', 'defaultVolume',
      'subtitleEnabled', 'subtitleLanguage', 'subtitleSize', 'subtitleStyle', 'subtitleColor', 'subtitleBackgroundColor',
      'downloadPath', 'cacheSizeLimit', 'autoClearCache', 'cacheClearInterval',
      'networkTypeForPlayback', 'networkTypeForDownload', 'bandwidthSaver', 'preloadEnabled', 'preloadLimit',
      'notificationsEnabled', 'notificationCategories', 'pushEnabled',
      'gridLayoutColumns', 'showFileExtensions', 'showHiddenFiles', 'defaultSortBy', 'defaultSortOrder',
      'enableHardwareAcceleration', 'enableDolbyAudio', 'enableHDR', 'screenTimeout',
      'crashReportingEnabled', 'usageAnalyticsEnabled', 'backgroundPlayEnabled', 'startupPage', 'enableGestureControl'
    ];
    
    for (const key of settingKeys) {
      if (settings[key] !== DEFAULT_APP_SETTINGS[key]) {
        modified[key] = settings[key];
      }
    }
    
    return modified;
  }

  /**
   * 导出设置为JSON | Export settings as JSON
   */
  public exportSettings(): string {
    const settings = this.getSettings();
    // 手动复制对象，兼容ArkTS
    const exportData: Record<string, SettingValue> = {};
    
    // 手动检查每个设置项，避免使用索引签名 | Manually check each setting item, avoid using index signature
    const settingKeys: Array<keyof AppSettings> = [
      'themeMode', 'accentColor', 'darkThemeAccentColor', 'customTheme',
      'language', 'autoDetectLanguage',
      'defaultPlaybackQuality', 'autoPlayNext', 'rememberPlaybackPosition', 'playbackSpeed', 'defaultVolume',
      'subtitleEnabled', 'subtitleLanguage', 'subtitleSize', 'subtitleStyle', 'subtitleColor', 'subtitleBackgroundColor',
      'downloadPath', 'cacheSizeLimit', 'autoClearCache', 'cacheClearInterval',
      'networkTypeForPlayback', 'networkTypeForDownload', 'bandwidthSaver', 'preloadEnabled', 'preloadLimit',
      'notificationsEnabled', 'notificationCategories', 'pushEnabled',
      'gridLayoutColumns', 'showFileExtensions', 'showHiddenFiles', 'defaultSortBy', 'defaultSortOrder',
      'enableHardwareAcceleration', 'enableDolbyAudio', 'enableHDR', 'screenTimeout',
      'crashReportingEnabled', 'usageAnalyticsEnabled', 'backgroundPlayEnabled', 'startupPage', 'enableGestureControl'
    ];
    
    for (const key of settingKeys) {
      exportData[key] = settings[key] as SettingValue;
    }
    
    return JSON.stringify(exportData, null, 2);
  }

  /**
   * 从JSON导入设置 | Import settings from JSON
   */
  public async importSettings(jsonString: string): Promise<boolean> {
    try {
      const importData = JSON.parse(jsonString);
      
      if (!importData || typeof importData !== 'object') {
        throw new Error('Invalid import data format');
      }
      
      // 验证导入数据的有效性 | Validate imported data validity
      await this.validateImportedSettings(importData as Partial<AppSettings>);
      
      // 手动转换导入数据，避免使用 any 类型 | Manually convert imported data, avoid using any type
      const settingsToApply: Partial<AppSettings> = {};
      
      // 手动检查每个设置项，避免使用索引签名 | Manually check each setting item, avoid using index signature
      const settingKeys: Array<keyof AppSettings> = [
        'themeMode', 'accentColor', 'darkThemeAccentColor', 'customTheme',
        'language', 'autoDetectLanguage',
        'defaultPlaybackQuality', 'autoPlayNext', 'rememberPlaybackPosition', 'playbackSpeed', 'defaultVolume',
        'subtitleEnabled', 'subtitleLanguage', 'subtitleSize', 'subtitleStyle', 'subtitleColor', 'subtitleBackgroundColor',
        'downloadPath', 'cacheSizeLimit', 'autoClearCache', 'cacheClearInterval',
        'networkTypeForPlayback', 'networkTypeForDownload', 'bandwidthSaver', 'preloadEnabled', 'preloadLimit',
        'notificationsEnabled', 'notificationCategories', 'pushEnabled',
        'gridLayoutColumns', 'showFileExtensions', 'showHiddenFiles', 'defaultSortBy', 'defaultSortOrder',
        'enableHardwareAcceleration', 'enableDolbyAudio', 'enableHDR', 'screenTimeout',
        'crashReportingEnabled', 'usageAnalyticsEnabled', 'backgroundPlayEnabled', 'startupPage', 'enableGestureControl'
      ];
      
      for (const key of settingKeys) {
        if (Object.hasOwnProperty.call(importData, key)) {
          settingsToApply[key] = importData[key];
        }
      }
      
      // 应用导入的设置 | Apply imported settings
      await this.setMultipleSettings(settingsToApply, false);
      
      console.info(TAG + '设置导入成功 | Settings imported successfully');
      return true;
    } catch (error) {
      console.error(TAG + "导入设置失败: | Failed to import settings: ", error);
      return false;
    }
  }

  /**
   * 验证导入的设置 | Validate imported settings
   */
  private async validateImportedSettings(settings: Partial<AppSettings>): Promise<void> {
    // 验证必要的设置项 | Validate required setting items
    if (settings.themeMode !== undefined && (settings.themeMode < 0 || settings.themeMode > 3)) {
      throw new Error('Invalid theme mode in imported settings');
    }
    
    const validLanguageCodes = ['zh_CN', 'zh_TW', 'en_US', 'ja_JP', 'ko_KR', 'de_DE'];
    if (settings.language && !validLanguageCodes.includes(settings.language)) {
      throw new Error('Invalid language in imported settings');
    }
    
    // 验证下载路径 | Validate download path
    if (settings.downloadPath) {
      await this.validateDownloadPath(settings.downloadPath);
    }
    
    // 验证数值范围 | Validate numeric ranges
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
   * 应用用户偏好设置 | Apply user preferences
   */
  public async applyUserPreferences(preferences: UserPreferences): Promise<void> {
    const settingsToApply: Partial<AppSettings> = {};
    
    // 映射用户偏好到应用设置 | Map user preferences to app settings
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
      // 这里可以添加下载质量的映射 | Can add download quality mapping here
    }
    
    if (preferences.downloadWifiOnly !== undefined) {
      settingsToApply.networkTypeForDownload = preferences.downloadWifiOnly 
        ? NetworkType.WIFI_ONLY 
        : NetworkType.ALL;
    }
    
    // 应用设置 | Apply settings
    if (this.getOwnPropertyKeys(settingsToApply).length > 0) {
      await this.setMultipleSettings(settingsToApply, false);
    }
  }

  /**
   * 从配置服务加载设置 | Load settings from config service
   */
  public async loadSettingsFromConfig(): Promise<void> {
    try {
      // 从配置服务加载关键设置 | Load key settings from config service
      const themeMode = await ConfigService.getInstance().getConfig<ThemeMode>('themeMode');
      const language = await ConfigService.getInstance().getConfig<LanguageCode>('language');
      const defaultPlaybackQuality = await ConfigService.getInstance().getConfig<PlaybackQuality>('playQuality');
      
      // 应用这些设置（但不触发用户发起的通知） | Apply these settings (without triggering user-initiated notifications)
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
      
      if (this.getOwnPropertyKeys(settingsToApply).length > 0) {
        await this.setMultipleSettings(settingsToApply, false);
      }
    } catch (error) {
      console.error(TAG + "从配置服务加载设置失败: | Failed to load settings from config: ", error);
    }
  }

  /**
   * 获取设置分组列表 | Get setting group list
   */
  public getSettingGroups(): SettingGroup[] {
    const currentSettings = this.getSettings();
    
    return [
      {
        id: 'appearance', title: '外观',
        description: '自定义应用外观和显示设置 | Customize app appearance and display settings',
        icon: 'ic_settings_appearance',
        settings: [
          this.createSettingItem('themeMode', currentSettings.themeMode),
          this.createSettingItem('accentColor', currentSettings.accentColor),
          this.createSettingItem('darkThemeAccentColor', currentSettings.darkThemeAccentColor),
          this.createSettingItem('gridLayoutColumns', currentSettings.gridLayoutColumns),
        ]
      },
      {
        id: 'playback',
        title: '播放',
        description: '调整播放相关设置 | Adjust playback related settings',
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
        description: '配置字幕显示选项 | Configure subtitle display options',
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
        description: '管理网络使用和下载设置 | Manage network usage and download settings',
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
        description: '管理缓存和下载存储 | Manage cache and download storage',
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
        description: '配置应用通知选项 | Configure app notification options',
        icon: 'ic_settings_notification',
        settings: [
          this.createSettingItem('notificationsEnabled', currentSettings.notificationsEnabled),
          this.createSettingItem('notificationCategories', currentSettings.notificationCategories),
          this.createSettingItem('pushEnabled', currentSettings.pushEnabled),
        ]
      },

    ];
  }

  /**
   * 创建设置项 | Create setting item
   */
  private createSettingItem<T>(key: string, value: T): SettingItem<T> {
    // 这里需要根据key获取默认值和其他配置 | Need to get default value and other configurations based on key
    // 简化实现，返回基本结构 | Simplified implementation, return basic structure
    const settingItem: SettingItem<T> = {
      key,
      value,
      type: SettingType.APPLICATION,
      defaultValue: value,
    };
    return settingItem;
  }

  /**
   * 通知设置变更 | Notify setting change
   */
  private notifySettingChanged(key: string, oldValue: SettingValue, newValue: SettingValue, userInitiated: boolean): void {
    const event: SettingChangeEvent<SettingValue> = {
      key,
      oldValue,
      newValue,
      timestamp: Date.now(),
      userInitiated,
    };

    // 触发指定设置的监听器 | Trigger specified setting listeners
    const specificListeners = this.specificListeners.get(key);
    if (specificListeners) {
      specificListeners.forEach(listener => {
        try {
          listener(event);
        } catch (error) {
          console.error(TAG + "特定设置监听器错误，键: " + key + ": " + error + " | Error in specific setting listener for " + key + ": " + error);
        }
      });
    }
  }

  /**
   * 通知所有设置变更 | Notify all setting changes
   */
  private notifySettingsChanged(): void {
    this.generalListeners.forEach(listener => {
      try {
        listener();
      } catch (error) {
        console.error(TAG + "通用设置监听器错误: " + error + " | Error in general setting listener: " + error);
      }
    });
  }

  /**
   * 通知主题变更 | Notify theme change
   */
  private notifyThemeChanged(themeMode: ThemeMode, accentColor: string): void {
    this.themeListeners.forEach(listener => {
      try {
        listener(themeMode, accentColor);
      } catch (error) {
        console.error(TAG + "主题监听器错误: " + error + " | Error in theme listener: " + error);
      }
    });
  }

  /**
   * 通知语言变更 | Notify language change
   */
  private notifyLanguageChanged(language: LanguageCode): void {
    this.languageListeners.forEach(listener => {
      try {
        listener(language);
      } catch (error) {
        console.error(TAG + "语言监听器错误: " + error + " | Error in language listener: " + error);
      }
    });
  }

  /**
   * 添加通用设置监听器 | Add general setting listener
   */
  public addGeneralListener(listener: () => void): void {
    this.generalListeners.push(listener);
  }

  /**
   * 移除通用设置监听器 | Remove general setting listener
   */
  public removeGeneralListener(listener: () => void): void {
    const index = this.generalListeners.indexOf(listener);
    if (index > -1) {
      this.generalListeners.splice(index, 1);
    }
  }

  /**
   * 添加指定设置监听器 | Add specified setting listener
   */
  public addSpecificListener(key: string, listener: (event: SettingChangeEvent<SettingValue>) => void): void {
    let listeners = this.specificListeners.get(key);
    if (!listeners) {
      listeners = [];
      this.specificListeners.set(key, listeners);
    }
    listeners.push(listener);
  }

  /**
   * 移除指定设置监听器 | Remove specified setting listener
   */
  public removeSpecificListener(key: string, listener: (event: SettingChangeEvent<SettingValue>) => void): void {
    const listeners = this.specificListeners.get(key);
    if (listeners) {
      const index = listeners.indexOf(listener);
      if (index > -1) {
        listeners.splice(index, 1);
      }
    }
  }

  /**
   * 添加主题监听器 | Add theme listener
   */
  public addThemeListener(listener: (themeMode: ThemeMode, accentColor: string) => void): void {
    this.themeListeners.push(listener);
  }

  /**
   * 移除主题监听器 | Remove theme listener
   */
  public removeThemeListener(listener: (themeMode: ThemeMode, accentColor: string) => void): void {
    const index = this.themeListeners.indexOf(listener);
    if (index > -1) {
      this.themeListeners.splice(index, 1);
    }
  }

  /**
   * 添加语言监听器 | Add language listener
   */
  public addLanguageListener(listener: (language: LanguageCode) => void): void {
    this.languageListeners.push(listener);
  }

  /**
   * 移除语言监听器 | Remove language listener
   */
  public removeLanguageListener(listener: (language: LanguageCode) => void): void {
    const index = this.languageListeners.indexOf(listener);
    if (index > -1) {
      this.languageListeners.splice(index, 1);
    }
  }

  /**
   * 获取对象键，解决TypeScript的Object.keys类型问题 | Get object keys, resolve TypeScript Object.keys type issue
   */
  private getObjectKeys<T extends object>(obj: T): Array<keyof T> {
    return this.getOwnPropertyKeys(obj) as Array<keyof T>;
  }
}

