// AppService - 应用服务类
import Logger from '../../common/util/Logger';
import StorageUtil from '../../common/util/StorageUtil';
import JsonUtil from '../../common/util/JsonUtil';
import ConfigService from './config/ConfigService';
import CacheService from './cache/CacheService';
import HttpService from './HttpService';
import AuthService from './user/UserService';
import MovieService from './media/MovieService';
import HistoryService from './media/HistoryService';
import CollectionService from './collection/CollectionService';
import DownloadService from './download/DownloadService';
import PlayerService from './player/PlayerService';
import LiveStreamService from './live/LiveStreamService';
import SubtitleService from './media/SubtitleService';
import FileService from './storage/FileService';
import RepositoryFactory from '../repository/RepositoryFactory';
import { parserService } from './parser/index';

// 常量定义
const TAG = 'AppService';
const APP_STATE_KEY = 'app_state';
const APP_VERSION_KEY = 'app_version';
const INITIALIZATION_TIMEOUT = 30000; // 30秒

// 应用状态枚举
export enum AppState {
  CREATED = 'created',
  INITIALIZING = 'initializing',
  READY = 'ready',
  BACKGROUND = 'background',
  FOREGROUND = 'foreground',
  SUSPENDED = 'suspended',
  SHUTTING_DOWN = 'shutting_down',
  ERROR = 'error'
}

// 应用错误类型枚举
export enum AppErrorType {
  INITIALIZATION_FAILED = 'initialization_failed',
  SERVICE_ERROR = 'service_error',
  NETWORK_ERROR = 'network_error',
  STORAGE_ERROR = 'storage_error',
  PERMISSION_ERROR = 'permission_error',
  UNKNOWN_ERROR = 'unknown_error'
}

// 应用信息接口
export interface AppInfo {
  appName: string;
  packageName: string;
  versionName: string;
  versionCode: number;
  buildType: 'debug' | 'release';
  targetSdkVersion: number;
  minSdkVersion: number;
  deviceId: string;
  deviceModel: string;
  deviceManufacturer: string;
  osVersion: string;
  screenWidth: number;
  screenHeight: number;
  isTablet: boolean;
  isTV: boolean;
  countryCode: string;
  languageCode: string;
  isRooted: boolean;
  installTime: number;
  lastUpdateTime: number;
  firstLaunchTime: number;
  launchCount: number;
  totalRunningTime: number;
  lastLaunchTime: number;
}

// 应用配置接口
export interface AppConfig {
  enableAnalytics: boolean;
  enableCrashReporting: boolean;
  enableAutoUpdate: boolean;
  enableBackgroundSync: boolean;
  enableNotifications: boolean;
  enableNightMode: boolean;
  enableHardwareAcceleration: boolean;
  enableGestureNavigation: boolean;
  enableDataSaver: boolean;
  autoPlayNextVideo: boolean;
  autoResumePlayback: boolean;
  maxVideoQuality: 'low' | 'medium' | 'high' | 'auto';
  defaultSubtitleLanguage: string;
  defaultAudioLanguage: string;
  playbackSpeed: number;
  theme: 'light' | 'dark' | 'system';
  language: string;
  interfaceScale: 'small' | 'medium' | 'large';
  animationEnabled: boolean;
  cacheEnabled: boolean;
  networkTimeout: number;
  retryCount: number;
}

// 应用统计接口
export interface AppStatistics {
  totalLaunches: number;
  totalPlaybackTime: number;
  totalDownloadedSize: number;
  totalUploadedSize: number;
  totalSearchQueries: number;
  totalContentViews: number;
  totalFavorites: number;
  totalHistoryItems: number;
  lastCleanupTime: number;
  lastBackupTime: number;
  lastRestoreTime: number;
  lastUpdateCheckTime: number;
  deviceStorageUsed: number;
  deviceStorageTotal: number;
}

// 应用错误接口
export interface AppError {
  type: AppErrorType;
  code: string;
  message: string;
  stackTrace?: string;
  timestamp: number;
  context?: any;
}

// 应用事件类型枚举
export enum AppEventType {
  INITIALIZED = 'initialized',
  READY = 'ready',
  BACKGROUND = 'background',
  FOREGROUND = 'foreground',
  SHUTDOWN = 'shutdown',
  ERROR = 'error',
  UPDATE_AVAILABLE = 'update_available',
  CONFIG_CHANGED = 'config_changed',
  USER_LOGIN = 'user_login',
  USER_LOGOUT = 'user_logout',
  NETWORK_CHANGE = 'network_change',
  STORAGE_WARNING = 'storage_warning',
  CLEANUP_COMPLETED = 'cleanup_completed'
}

// 应用事件接口
export interface AppEvent {
  type: AppEventType;
  data?: any;
  timestamp: number;
}

// 应用备份选项接口
export interface AppBackupOptions {
  includeUserData: boolean;
  includeSettings: boolean;
  includeHistory: boolean;
  includeCollections: boolean;
  includeDownloads: boolean;
  includeCache: boolean;
  excludeKeys?: string[];
  password?: string;
  compress: boolean;
}

// 应用恢复选项接口
export interface AppRestoreOptions {
  overwriteExisting: boolean;
  includeUserData: boolean;
  includeSettings: boolean;
  includeHistory: boolean;
  includeCollections: boolean;
  includeDownloads: boolean;
  includeCache: boolean;
  password?: string;
  validateOnly: boolean;
}

// 应用备份信息接口
export interface AppBackupInfo {
  version: string;
  timestamp: number;
  size: number;
  description?: string;
  deviceInfo?: string;
  includes: {
    userData: boolean;
    settings: boolean;
    history: boolean;
    collections: boolean;
    downloads: boolean;
    cache: boolean;
  };
  hash?: string;
  encrypted: boolean;
}

// 默认应用配置
const DEFAULT_APP_CONFIG: AppConfig = {
  enableAnalytics: true,
  enableCrashReporting: true,
  enableAutoUpdate: true,
  enableBackgroundSync: true,
  enableNotifications: true,
  enableNightMode: false,
  enableHardwareAcceleration: true,
  enableGestureNavigation: true,
  enableDataSaver: false,
  autoPlayNextVideo: true,
  autoResumePlayback: true,
  maxVideoQuality: 'high',
  defaultSubtitleLanguage: 'auto',
  defaultAudioLanguage: 'auto',
  playbackSpeed: 1.0,
  theme: 'system',
  language: 'auto',
  interfaceScale: 'medium',
  animationEnabled: true,
  cacheEnabled: true,
  networkTimeout: 30000,
  retryCount: 3
};

/**
 * 应用服务类
 * 负责管理应用程序的全局状态、生命周期和通用功能
 */
export default class AppService {
  private static instance: AppService;
  
  private currentState: AppState = AppState.CREATED;
  private appInfo: AppInfo | null = null;
  private appConfig: AppConfig = { ...DEFAULT_APP_CONFIG };
  private appStatistics: AppStatistics = this.createDefaultStatistics();
  private errorHistory: AppError[] = [];
  private eventHistory: AppEvent[] = [];
  
  // 服务引用
  private services: Map<string, any> = new Map();
  
  // 初始化状态
  private initializationPromise: Promise<void> | null = null;
  private initializationStartTime: number = 0;
  private isInitialized: boolean = false;
  
  // 监听器
  private stateListeners: Array<(newState: AppState, oldState: AppState) => void> = [];
  private eventListeners: Array<(event: AppEvent) => void> = [];
  private errorListeners: Array<(error: AppError) => void> = [];
  
  // 应用启动时间
  private startTime: number = Date.now();
  
  // 版本信息
  private currentVersion: string = '1.0.0';
  private buildNumber: number = 1;

  /**
   * 构造函数（私有，防止外部实例化）
   */
  private constructor() {
    // 捕获全局错误
    this.setupGlobalErrorHandling();
    
    // 记录启动时间
    this.startTime = Date.now();
    
    Logger.info(TAG, `Application started, version: ${this.currentVersion}, build: ${this.buildNumber}`);
  }

  /**
   * 获取单例实例
   */
  public static getInstance(): AppService {
    if (!AppService.instance) {
      AppService.instance = new AppService();
    }
    return AppService.instance;
  }

  /**
   * 创建默认统计信息
   */
  private createDefaultStatistics(): AppStatistics {
    return {
      totalLaunches: 0,
      totalPlaybackTime: 0,
      totalDownloadedSize: 0,
      totalUploadedSize: 0,
      totalSearchQueries: 0,
      totalContentViews: 0,
      totalFavorites: 0,
      totalHistoryItems: 0,
      lastCleanupTime: 0,
      lastBackupTime: 0,
      lastRestoreTime: 0,
      lastUpdateCheckTime: 0,
      deviceStorageUsed: 0,
      deviceStorageTotal: 0
    };
  }

  /**
   * 设置全局错误处理
   */
  private setupGlobalErrorHandling(): void {
    try {
      // 捕获未处理的Promise错误
      globalThis.addEventListener('unhandledrejection', (event) => {
        this.handleGlobalError(new Error(`Unhandled Promise rejection: ${String(event.reason)}`), AppErrorType.UNKNOWN_ERROR);
      });
      
      // 捕获未捕获的异常
      globalThis.addEventListener('error', (event) => {
        this.handleGlobalError(new Error(`${event.message || 'Unknown error'}`), AppErrorType.UNKNOWN_ERROR, event.error?.stack);
      });
    } catch (error) {
      Logger.error(TAG, 'Failed to setup global error handling', error);
    }
  }

  /**
   * 处理全局错误
   */
  private handleGlobalError(error: Error, type: AppErrorType, stackTrace?: string): void {
    try {
      const appError: AppError = {
        type,
        code: 'GLOBAL_ERROR',
        message: error.message || String(error),
        stackTrace: stackTrace || error.stack,
        timestamp: Date.now(),
        context: { source: 'global' }
      };
      
      this.recordError(appError);
      
      // 记录到日志
      Logger.error(TAG, 'Global error occurred', error);
    } catch (logError) {
      // 避免错误处理自身出错
      console.error('Failed to log global error', logError);
    }
  }

  /**
   * 初始化应用服务
   */
  public async initialize(): Promise<boolean> {
    // 防止重复初始化
    if (this.initializationPromise) {
      return this.initializationPromise.then(() => this.isInitialized);
    }
    
    this.initializationPromise = this.doInitialize();
    return this.initializationPromise.then(() => this.isInitialized);
  }

  /**
   * 执行初始化过程
   */
  private async doInitialize(): Promise<void> {
    try {
      // 更新状态
      this.setState(AppState.INITIALIZING);
      this.initializationStartTime = Date.now();
      
      Logger.info(TAG, 'Starting application initialization...');
      
      // 1. 加载设备信息
      await this.loadAppInfo();
      
      // 2. 加载应用配置
      await this.loadAppConfig();
      
      // 3. 加载应用统计
      await this.loadAppStatistics();
      
      // 4. 初始化存储服务
      const fileService = FileService.getInstance();
      await fileService.initialize();
      this.services.set('fileService', fileService);
      
      // 5. 初始化仓库工厂
      const repositoryFactory = RepositoryFactory.getInstance();
      await repositoryFactory.initialize();
      this.services.set('repositoryFactory', repositoryFactory);
      
      // 6. 初始化配置服务
      const configService = ConfigService.getInstance();
      await configService.initialize();
      this.services.set('configService', configService);
      
      // 7. 初始化缓存服务
      const cacheService = CacheService.getInstance();
      await cacheService.initialize();
      this.services.set('cacheService', cacheService);
      
      // 8. 初始化网络服务
      const httpService = HttpService.getInstance();
    await httpService.initialize();
    this.services.set('httpService', httpService);
      
      // 9. 初始化认证服务
      const authService = AuthService.getInstance();
      await authService.initialize();
      this.services.set('authService', authService);
      
      // 10. 初始化电影服务
      const movieService = MovieService.getInstance();
      await movieService.initialize();
      this.services.set('movieService', movieService);
      
      // 11. 初始化历史服务
      const historyService = HistoryService.getInstance();
      await historyService.initialize();
      this.services.set('historyService', historyService);
      
      // 12. 初始化收藏服务
      const collectionService = CollectionService.getInstance();
      await collectionService.initialize();
      this.services.set('collectionService', collectionService);
      
      // 13. 初始化下载服务
      const downloadService = DownloadService.getInstance();
      await downloadService.initialize();
      this.services.set('downloadService', downloadService);
      
      // 14. 初始化播放器服务
      const playerService = PlayerService.getInstance();
      await playerService.initialize();
      this.services.set('playerService', playerService);
      
      // 15. 初始化直播流服务
      const liveStreamService = LiveStreamService.getInstance();
      await liveStreamService.initialize();
      this.services.set('liveStreamService', liveStreamService);
      
      // 16. 初始化字幕服务
      const subtitleService = SubtitleService.getInstance();
      await subtitleService.initialize();
      this.services.set('subtitleService', subtitleService);
      
      // 17. 初始化解析器服务
      await parserService.initialize();
      this.services.set('parserService', parserService);
      
      // 18. 更新统计信息
      await this.updateLaunchStatistics();
      
      // 19. 执行启动时清理
      await this.performStartupCleanup();
      
      // 20. 检查更新
      if (this.appConfig.enableAutoUpdate) {
        await this.checkForUpdates();
      }
      
      // 21. 发送初始化完成事件
      this.isInitialized = true;
      this.setState(AppState.READY);
      
      const initDuration = Date.now() - this.initializationStartTime;
      Logger.info(TAG, `Application initialized successfully in ${initDuration}ms`);
      
      // 发布初始化完成事件
      this.publishEvent(AppEventType.INITIALIZED, { duration: initDuration });
      this.publishEvent(AppEventType.READY, { version: this.currentVersion });
    } catch (error) {
      Logger.error(TAG, 'Application initialization failed', error);
      
      const appError: AppError = {
        type: AppErrorType.INITIALIZATION_FAILED,
        code: 'INITIALIZATION_ERROR',
        message: String(error),
        stackTrace: (error as Error).stack,
        timestamp: Date.now()
      };
      
      this.recordError(appError);
      this.setState(AppState.ERROR);
      
      throw error;
    }
  }

  /**
   * 加载应用信息
   */
  private async loadAppInfo(): Promise<void> {
    try {
      // 在实际应用中，这里会从系统API获取真实的设备和应用信息
      // 这里使用模拟数据
      this.appInfo = {
        appName: 'RayTV',
        packageName: 'com.example.raytv',
        versionName: this.currentVersion,
        versionCode: this.buildNumber,
        buildType: 'debug',
        targetSdkVersion: 34,
        minSdkVersion: 28,
        deviceId: 'device-123456',
        deviceModel: 'Device Model',
        deviceManufacturer: 'Device Manufacturer',
        osVersion: '13.0',
        screenWidth: 1920,
        screenHeight: 1080,
        isTablet: false,
        isTV: true,
        countryCode: 'CN',
        languageCode: 'zh',
        isRooted: false,
        installTime: Date.now() - 86400000 * 30, // 30天前
        lastUpdateTime: Date.now() - 86400000 * 7, // 7天前
        firstLaunchTime: await StorageUtil.getNumber('first_launch_time', Date.now()),
        launchCount: await StorageUtil.getNumber('launch_count', 0),
        totalRunningTime: await StorageUtil.getNumber('total_running_time', 0),
        lastLaunchTime: await StorageUtil.getNumber('last_launch_time', 0)
      };
      
      Logger.debug(TAG, `Loaded app info: ${this.appInfo.appName} v${this.appInfo.versionName}`);
    } catch (error) {
      Logger.error(TAG, 'Failed to load app info', error);
      throw error;
    }
  }

  /**
   * 加载应用配置
   */
  private async loadAppConfig(): Promise<void> {
    try {
      const savedConfig = await StorageUtil.getObject<AppConfig>('app_config');
      if (savedConfig) {
        this.appConfig = { ...DEFAULT_APP_CONFIG, ...savedConfig };
      }
      
      Logger.debug(TAG, 'Loaded app configuration');
    } catch (error) {
      Logger.error(TAG, 'Failed to load app config', error);
      // 使用默认配置
      this.appConfig = { ...DEFAULT_APP_CONFIG };
    }
  }

  /**
   * 保存应用配置
   */
  private async saveAppConfig(): Promise<void> {
    try {
      await StorageUtil.setObject('app_config', this.appConfig);
      Logger.debug(TAG, 'Saved app configuration');
    } catch (error) {
      Logger.error(TAG, 'Failed to save app config', error);
    }
  }

  /**
   * 加载应用统计
   */
  private async loadAppStatistics(): Promise<void> {
    try {
      const savedStats = await StorageUtil.getObject<AppStatistics>('app_statistics');
      if (savedStats) {
        this.appStatistics = { ...this.appStatistics, ...savedStats };
      }
      
      Logger.debug(TAG, 'Loaded app statistics');
    } catch (error) {
      Logger.error(TAG, 'Failed to load app statistics', error);
      // 使用默认统计
      this.appStatistics = this.createDefaultStatistics();
    }
  }

  /**
   * 保存应用统计
   */
  private async saveAppStatistics(): Promise<void> {
    try {
      await StorageUtil.setObject('app_statistics', this.appStatistics);
      Logger.debug(TAG, 'Saved app statistics');
    } catch (error) {
      Logger.error(TAG, 'Failed to save app statistics', error);
    }
  }

  /**
   * 更新启动统计信息
   */
  private async updateLaunchStatistics(): Promise<void> {
    try {
      // 更新启动次数
      const currentLaunchCount = await StorageUtil.getNumber('launch_count', 0) + 1;
      await StorageUtil.setNumber('launch_count', currentLaunchCount);
      this.appStatistics.totalLaunches = currentLaunchCount;
      
      // 更新最后启动时间
      await StorageUtil.setNumber('last_launch_time', Date.now());
      
      // 如果是首次启动，记录首次启动时间
      if (!await StorageUtil.contains('first_launch_time')) {
        await StorageUtil.setNumber('first_launch_time', Date.now());
      }
      
      Logger.info(TAG, `Launch count: ${currentLaunchCount}`);
    } catch (error) {
      Logger.error(TAG, 'Failed to update launch statistics', error);
    }
  }

  /**
   * 执行启动时清理
   */
  private async performStartupCleanup(): Promise<void> {
    try {
      // 清理过期的缓存
      const cacheService = CacheService.getInstance();
      await cacheService.clear({ expiredOnly: true });
      
      // 清理临时文件
      const fileService = FileService.getInstance();
      await fileService.cleanupTempFiles();
      
      // 更新存储统计
      await this.updateStorageStatistics();
      
      Logger.debug(TAG, 'Performed startup cleanup');
    } catch (error) {
      Logger.error(TAG, 'Failed to perform startup cleanup', error);
    }
  }

  /**
   * 更新存储统计
   */
  private async updateStorageStatistics(): Promise<void> {
    try {
      const fileService = FileService.getInstance();
      const storageInfo = await fileService.getStorageInfo();
      
      this.appStatistics.deviceStorageUsed = storageInfo.used;
      this.appStatistics.deviceStorageTotal = storageInfo.total;
      
      // 检查存储空间警告
      if (storageInfo.used > storageInfo.total * 0.9) {
        this.publishEvent(AppEventType.STORAGE_WARNING, {
          used: storageInfo.used,
          total: storageInfo.total,
          percentage: (storageInfo.used / storageInfo.total) * 100
        });
      }
    } catch (error) {
      Logger.error(TAG, 'Failed to update storage statistics', error);
    }
  }

  /**
   * 检查更新
   */
  private async checkForUpdates(): Promise<void> {
    try {
      // 在实际应用中，这里会调用更新检查API
      // 这里使用模拟数据
      const hasUpdate = false;
      const latestVersion = this.currentVersion;
      
      if (hasUpdate) {
        this.publishEvent(AppEventType.UPDATE_AVAILABLE, {
          currentVersion: this.currentVersion,
          latestVersion,
          releaseNotes: 'Bug fixes and performance improvements'
        });
      }
      
      // 更新检查时间
      this.appStatistics.lastUpdateCheckTime = Date.now();
      await this.saveAppStatistics();
      
      Logger.debug(TAG, 'Checked for updates');
    } catch (error) {
      Logger.error(TAG, 'Failed to check for updates', error);
    }
  }

  /**
   * 设置应用状态
   */
  private setState(newState: AppState): void {
    const oldState = this.currentState;
    this.currentState = newState;
    
    Logger.debug(TAG, `App state changed: ${oldState} -> ${newState}`);
    
    // 通知状态监听器
    for (const listener of this.stateListeners) {
      try {
        listener(newState, oldState);
      } catch (error) {
        Logger.error(TAG, 'Error in state listener', error);
      }
    }
  }

  /**
   * 发布应用事件
   */
  private publishEvent(type: AppEventType, data?: any): void {
    const event: AppEvent = {
      type,
      data,
      timestamp: Date.now()
    };
    
    // 添加到事件历史
    this.eventHistory.push(event);
    // 限制历史记录大小
    if (this.eventHistory.length > 1000) {
      this.eventHistory.shift();
    }
    
    Logger.debug(TAG, `Published event: ${type}`);
    
    // 通知事件监听器
    for (const listener of this.eventListeners) {
      try {
        listener(event);
      } catch (error) {
        Logger.error(TAG, 'Error in event listener', error);
      }
    }
  }

  /**
   * 记录错误
   */
  private recordError(error: AppError): void {
    // 添加到错误历史
    this.errorHistory.push(error);
    // 限制历史记录大小
    if (this.errorHistory.length > 100) {
      this.errorHistory.shift();
    }
    
    // 更新错误统计
    this.appStatistics.totalPlaybackTime = this.appStatistics.totalPlaybackTime; // 保持不变
    
    Logger.error(TAG, `Recorded error: ${error.type} - ${error.message}`);
    
    // 通知错误监听器
    for (const listener of this.errorListeners) {
      try {
        listener(error);
      } catch (listenerError) {
        Logger.error(TAG, 'Error in error listener', listenerError);
      }
    }
  }

  /**
   * 获取当前应用状态
   */
  public getState(): AppState {
    return this.currentState;
  }

  /**
   * 获取应用信息
   */
  public getAppInfo(): AppInfo | null {
    return this.appInfo;
  }

  /**
   * 获取应用配置
   */
  public getAppConfig(): AppConfig {
    return { ...this.appConfig };
  }

  /**
   * 更新应用配置
   */
  public async updateAppConfig(config: Partial<AppConfig>): Promise<AppConfig> {
    try {
      // 更新配置
      this.appConfig = {
        ...this.appConfig,
        ...config
      };
      
      // 保存配置
      await this.saveAppConfig();
      
      // 发布配置变更事件
      this.publishEvent(AppEventType.CONFIG_CHANGED, { ...this.appConfig });
      
      Logger.info(TAG, 'Updated app configuration');
      return { ...this.appConfig };
    } catch (error) {
      Logger.error(TAG, 'Failed to update app config', error);
      return { ...this.appConfig };
    }
  }

  /**
   * 重置应用配置
   */
  public async resetAppConfig(): Promise<AppConfig> {
    try {
      this.appConfig = { ...DEFAULT_APP_CONFIG };
      
      // 保存配置
      await this.saveAppConfig();
      
      // 发布配置变更事件
      this.publishEvent(AppEventType.CONFIG_CHANGED, { ...this.appConfig });
      
      Logger.info(TAG, 'Reset app configuration to default');
      return { ...this.appConfig };
    } catch (error) {
      Logger.error(TAG, 'Failed to reset app config', error);
      return { ...this.appConfig };
    }
  }

  /**
   * 获取应用统计信息
   */
  public getAppStatistics(): AppStatistics {
    return { ...this.appStatistics };
  }

  /**
   * 更新应用统计信息
   */
  public async updateAppStatistics(updates: Partial<AppStatistics>): Promise<void> {
    try {
      this.appStatistics = {
        ...this.appStatistics,
        ...updates
      };
      
      await this.saveAppStatistics();
      Logger.debug(TAG, 'Updated app statistics');
    } catch (error) {
      Logger.error(TAG, 'Failed to update app statistics', error);
    }
  }

  /**
   * 重置应用统计
   */
  public async resetAppStatistics(): Promise<void> {
    try {
      this.appStatistics = this.createDefaultStatistics();
      
      await this.saveAppStatistics();
      Logger.info(TAG, 'Reset app statistics');
    } catch (error) {
      Logger.error(TAG, 'Failed to reset app statistics', error);
    }
  }

  /**
   * 获取服务实例
   */
  public getService<T>(serviceName: string): T | null {
    const service = this.services.get(serviceName);
    if (!service) {
      Logger.warn(TAG, `Service not found: ${serviceName}`);
    }
    return service as T;
  }

  /**
   * 注册自定义服务
   */
  public registerService(serviceName: string, serviceInstance: any): boolean {
    try {
      this.services.set(serviceName, serviceInstance);
      Logger.info(TAG, `Registered custom service: ${serviceName}`);
      return true;
    } catch (error) {
      Logger.error(TAG, `Failed to register service: ${serviceName}`, error);
      return false;
    }
  }

  /**
   * 注销自定义服务
   */
  public unregisterService(serviceName: string): boolean {
    try {
      this.services.delete(serviceName);
      Logger.info(TAG, `Unregistered service: ${serviceName}`);
      return true;
    } catch (error) {
      Logger.error(TAG, `Failed to unregister service: ${serviceName}`, error);
      return false;
    }
  }

  /**
   * 添加状态监听器
   */
  public addStateListener(listener: (newState: AppState, oldState: AppState) => void): () => void {
    this.stateListeners.push(listener);
    
    // 返回取消监听函数
    return () => {
      const index = this.stateListeners.indexOf(listener);
      if (index > -1) {
        this.stateListeners.splice(index, 1);
      }
    };
  }

  /**
   * 添加事件监听器
   */
  public addEventListener(listener: (event: AppEvent) => void): () => void {
    this.eventListeners.push(listener);
    
    // 返回取消监听函数
    return () => {
      const index = this.eventListeners.indexOf(listener);
      if (index > -1) {
        this.eventListeners.splice(index, 1);
      }
    };
  }

  /**
   * 添加错误监听器
   */
  public addErrorListener(listener: (error: AppError) => void): () => void {
    this.errorListeners.push(listener);
    
    // 返回取消监听函数
    return () => {
      const index = this.errorListeners.indexOf(listener);
      if (index > -1) {
        this.errorListeners.splice(index, 1);
      }
    };
  }

  /**
   * 处理应用进入前台
   */
  public onAppForeground(): void {
    try {
      if (this.currentState !== AppState.ERROR) {
        this.setState(AppState.FOREGROUND);
        this.publishEvent(AppEventType.FOREGROUND);
        
        // 恢复必要的服务
        this.resumeServices();
      }
      
      Logger.info(TAG, 'Application moved to foreground');
    } catch (error) {
      Logger.error(TAG, 'Failed to handle app foreground', error);
    }
  }

  /**
   * 处理应用进入后台
   */
  public onAppBackground(): void {
    try {
      if (this.currentState !== AppState.ERROR && this.currentState !== AppState.SHUTTING_DOWN) {
        this.setState(AppState.BACKGROUND);
        this.publishEvent(AppEventType.BACKGROUND);
        
        // 暂停非必要的服务
        this.pauseServices();
        
        // 保存状态
        this.saveAppState();
      }
      
      Logger.info(TAG, 'Application moved to background');
    } catch (error) {
      Logger.error(TAG, 'Failed to handle app background', error);
    }
  }

  /**
   * 恢复服务
   */
  private async resumeServices(): Promise<void> {
    try {
      // 恢复网络服务
      const httpService = this.getService<HttpService>('httpService');
    if (httpService) {
      await httpService.resume();
      }
      
      // 恢复下载服务
      const downloadService = this.getService<DownloadService>('downloadService');
      if (downloadService) {
        await downloadService.resumeAllDownloads();
      }
      
      Logger.debug(TAG, 'Resumed services');
    } catch (error) {
      Logger.error(TAG, 'Failed to resume services', error);
    }
  }

  /**
   * 暂停服务
   */
  private async pauseServices(): Promise<void> {
    try {
      // 暂停下载服务
      const downloadService = this.getService<DownloadService>('downloadService');
      if (downloadService) {
        await downloadService.pauseAllDownloads();
      }
      
      // 暂停网络服务的非必要连接
      const httpService = this.getService<HttpService>('httpService');
    if (httpService) {
      await httpService.pause();
      }
      
      Logger.debug(TAG, 'Paused services');
    } catch (error) {
      Logger.error(TAG, 'Failed to pause services', error);
    }
  }

  /**
   * 保存应用状态
   */
  private async saveAppState(): Promise<void> {
    try {
      const appState = {
        version: this.currentVersion,
        state: this.currentState,
        timestamp: Date.now(),
        lastActiveTime: Date.now()
      };
      
      await StorageUtil.setObject(APP_STATE_KEY, appState);
      
      // 更新总运行时间
      const currentRunningTime = await StorageUtil.getNumber('total_running_time', 0);
      const thisSessionTime = Date.now() - this.startTime;
      await StorageUtil.setNumber('total_running_time', currentRunningTime + thisSessionTime);
      
      // 保存统计信息
      await this.saveAppStatistics();
      
      Logger.debug(TAG, 'Saved app state');
    } catch (error) {
      Logger.error(TAG, 'Failed to save app state', error);
    }
  }

  /**
   * 加载应用状态
   */
  private async loadAppState(): Promise<any> {
    try {
      const appState = await StorageUtil.getObject(APP_STATE_KEY);
      Logger.debug(TAG, 'Loaded app state');
      return appState;
    } catch (error) {
      Logger.error(TAG, 'Failed to load app state', error);
      return null;
    }
  }

  /**
   * 执行应用清理
   */
  public async performCleanup(deepClean: boolean = false): Promise<{ deletedCount: number; freedSpace: number }> {
    try {
      let totalDeleted = 0;
      let totalFreed = 0;
      
      // 清理缓存
      const cacheService = CacheService.getInstance();
      const cacheResult = await cacheService.clear({
        force: deepClean,
        expiredOnly: !deepClean
      });
      totalDeleted += cacheResult.deletedCount;
      totalFreed += cacheResult.freedSpace;
      
      // 清理临时文件
      const fileService = FileService.getInstance();
      const tempResult = await fileService.cleanupTempFiles();
      totalDeleted += tempResult.deletedCount;
      totalFreed += tempResult.freedSpace;
      
      // 清理下载的临时文件
      const downloadService = DownloadService.getInstance();
      const downloadResult = await downloadService.cleanupFailedDownloads();
      totalDeleted += downloadResult.deletedCount;
      totalFreed += downloadResult.freedSpace;
      
      // 更新统计信息
      this.appStatistics.lastCleanupTime = Date.now();
      await this.saveAppStatistics();
      
      // 发布清理完成事件
      this.publishEvent(AppEventType.CLEANUP_COMPLETED, {
        deletedCount: totalDeleted,
        freedSpace: totalFreed
      });
      
      Logger.info(TAG, `Cleanup completed: ${totalDeleted} items deleted, ${this.formatSize(totalFreed)} freed`);
      return { deletedCount: totalDeleted, freedSpace: totalFreed };
    } catch (error) {
      Logger.error(TAG, 'Failed to perform cleanup', error);
      return { deletedCount: 0, freedSpace: 0 };
    }
  }

  /**
   * 创建应用备份
   */
  public async createBackup(options: AppBackupOptions): Promise<string | null> {
    try {
      const backupTime = Date.now();
      const backupFileName = `raytv_backup_${backupTime}.zip`;
      const backupFilePath = `${this.getService<FileService>('fileService')?.getBackupDir()}/${backupFileName}`;
      
      // 创建备份信息
      const backupInfo: AppBackupInfo = {
        version: this.currentVersion,
        timestamp: backupTime,
        size: 0, // 将在备份完成后更新
        description: 'RayTV application backup',
        deviceInfo: `${this.appInfo?.deviceManufacturer} ${this.appInfo?.deviceModel}`,
        includes: {
          userData: options.includeUserData,
          settings: options.includeSettings,
          history: options.includeHistory,
          collections: options.includeCollections,
          downloads: options.includeDownloads,
          cache: options.includeCache
        },
        hash: '', // 将在备份完成后计算
        encrypted: !!options.password
      };
      
      // 在实际应用中，这里会执行真实的备份逻辑
      // 这里只是模拟备份过程
      
      // 保存备份信息
      const backupInfoPath = `${backupFilePath}.info`;
      await StorageUtil.setObject(backupInfoPath, backupInfo);
      
      // 更新统计信息
      this.appStatistics.lastBackupTime = backupTime;
      await this.saveAppStatistics();
      
      Logger.info(TAG, `Created backup: ${backupFileName}`);
      return backupFilePath;
    } catch (error) {
      Logger.error(TAG, 'Failed to create backup', error);
      return null;
    }
  }

  /**
   * 恢复应用备份
   */
  public async restoreBackup(backupFilePath: string, options: AppRestoreOptions): Promise<boolean> {
    try {
      // 验证备份文件
      if (!await this.getService<FileService>('fileService')?.fileExists(backupFilePath)) {
        throw new Error('Backup file not found');
      }
      
      // 读取备份信息
      const backupInfoPath = `${backupFilePath}.info`;
      const backupInfo = await StorageUtil.getObject<AppBackupInfo>(backupInfoPath);
      
      if (!backupInfo) {
        throw new Error('Invalid backup file');
      }
      
      // 如果只是验证
      if (options.validateOnly) {
        Logger.info(TAG, `Validated backup: ${backupFilePath}`);
        return true;
      }
      
      // 在实际应用中，这里会执行真实的恢复逻辑
      // 这里只是模拟恢复过程
      
      // 更新统计信息
      this.appStatistics.lastRestoreTime = Date.now();
      await this.saveAppStatistics();
      
      Logger.info(TAG, `Restored backup: ${backupFilePath}`);
      return true;
    } catch (error) {
      Logger.error(TAG, 'Failed to restore backup', error);
      return false;
    }
  }

  /**
   * 格式化大小显示
   */
  private formatSize(bytes: number): string {
    if (bytes < 1024) {
      return `${bytes} B`;
    } else if (bytes < 1024 * 1024) {
      return `${(bytes / 1024).toFixed(2)} KB`;
    } else if (bytes < 1024 * 1024 * 1024) {
      return `${(bytes / (1024 * 1024)).toFixed(2)} MB`;
    } else {
      return `${(bytes / (1024 * 1024 * 1024)).toFixed(2)} GB`;
    }
  }

  /**
   * 关闭应用服务
   */
  public async shutdown(): Promise<void> {
    try {
      this.setState(AppState.SHUTTING_DOWN);
      Logger.info(TAG, 'Shutting down application...');
      
      // 保存状态
      await this.saveAppState();
      
      // 关闭所有服务
      const servicesToShutdown = [...this.services.values()];
      for (const service of servicesToShutdown) {
        try {
          if (typeof service.shutdown === 'function') {
            await service.shutdown();
          }
        } catch (error) {
          Logger.error(TAG, 'Failed to shutdown service', error);
        }
      }
      
      // 清空服务映射
      this.services.clear();
      
      // 发布关闭事件
      this.publishEvent(AppEventType.SHUTDOWN);
      
      Logger.info(TAG, 'Application shutdown completed');
    } catch (error) {
      Logger.error(TAG, 'Failed to shutdown application', error);
    }
  }

  /**
   * 获取错误历史
   */
  public getErrorHistory(limit: number = 10): AppError[] {
    return this.errorHistory.slice(-limit);
  }

  /**
   * 获取事件历史
   */
  public getEventHistory(limit: number = 100): AppEvent[] {
    return this.eventHistory.slice(-limit);
  }

  /**
   * 清除错误历史
   */
  public clearErrorHistory(): void {
    this.errorHistory = [];
    Logger.debug(TAG, 'Cleared error history');
  }

  /**
   * 清除事件历史
   */
  public clearEventHistory(): void {
    this.eventHistory = [];
    Logger.debug(TAG, 'Cleared event history');
  }

  /**
   * 检查应用是否处于健康状态
   */
  public isHealthy(): boolean {
    return this.currentState === AppState.READY || 
           this.currentState === AppState.FOREGROUND || 
           this.currentState === AppState.BACKGROUND;
  }

  /**
   * 获取应用运行时间
   */
  public getUptime(): number {
    return Date.now() - this.startTime;
  }
}