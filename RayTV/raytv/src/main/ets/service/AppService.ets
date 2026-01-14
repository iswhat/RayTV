/**
 * AppService - 应用服务 Application service
 * 提供应用级别的服务管理功能 Provides application-level service management functionality
 */
import Logger from '../../common/util/Logger';
import StorageUtil from '../../common/util/StorageUtil';
import JsonUtil from '../../common/util/JsonUtil';
import ConfigService from './config/ConfigService';
import CacheService from './cache/CacheService';
import HttpService from './HttpService';

import MovieService from './media/MovieService';
import HistoryService from './media/HistoryService';
import MediaService from './media/MediaService';

import PlayerService from './player/PlayerService';
import LiveStreamService from './live/LiveStreamService';
import SubtitleService from './media/SubtitleService';
import RepositoryFactory from '../../data/repository/RepositoryFactory';
import { getParserService } from './parser/index';

import { AnalyticsService } from './analytics/AnalyticsService';
import { VoiceAssistantManager } from './voice/VoiceAssistantManager';
import { DeviceService } from './device/DeviceService';
import { DataSyncService } from './sync/DataSyncService';
import { GestureService } from './input/GestureService';
import { WallManager } from './wallpaper/WallManager';
import { AdBlockManager } from './adblock/AdBlockManager';
import { SiteService } from './spider/SiteService';
import { CrawlerService } from './spider/CrawlerService';

// 常量定义 Constants
const TAG = 'AppService';
const APP_STATE_KEY = 'app_state';
const APP_VERSION_KEY = 'app_version';
const INITIALIZATION_TIMEOUT = 30000; // 30秒 30 seconds

// 应用状态枚举 App state enum
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

// 应用错误类型枚举 App error type enum
export enum AppErrorType {
  INITIALIZATION_FAILED = 'initialization_failed',
  SERVICE_ERROR = 'service_error',
  NETWORK_ERROR = 'network_error',
  STORAGE_ERROR = 'storage_error',
  PERMISSION_ERROR = 'permission_error',
  UNKNOWN_ERROR = 'unknown_error'
}

// 应用信息接口 App info interface
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

// 应用配置接口 App config interface
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

// 应用统计信息接口 App statistics interface
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
}

/**
 * 应用服务类 Application service class
 */
export default class AppService {
  private static instance: AppService | null = null;
  private state: AppState = AppState.CREATED;
  private services: Map<string, any> = new Map();
  private appConfig: AppConfig = this.getDefaultConfig();
  private appInfo: AppInfo = this.getDefaultAppInfo();
  private appStatistics: AppStatistics = this.getDefaultStatistics();
  private isInitialized: boolean = false;

  /**
   * 获取应用服务实例 Get application service instance
   * @returns 应用服务实例 Application service instance
   */
  public static getInstance(): AppService {
    if (!AppService.instance) {
      AppService.instance = new AppService();
    }
    return AppService.instance;
  }

  /**
   * 构造函数 Constructor
   */
  private constructor() {
    this.setupGlobalErrorHandling();
  }

  /**
   * 设置全局错误处理 Set up global error handling
   */
  private setupGlobalErrorHandling(): void {
    try {
      // 设置全局错误处理逻辑 Set up global error handling logic
      // 这里可以添加具体的错误处理代码 Here can add specific error handling code
    } catch (error) {
      Logger.error(TAG, 'Failed to setup global error handling', error instanceof Error ? error : new Error(String(error)));
    }
  }

  /**
   * 处理全局错误 Handle global error
   * @param error 错误对象 Error object
   * @param type 错误类型 Error type
   * @param stackTrace 堆栈跟踪 Stack trace
   */
  private handleGlobalError(error: Error, type: AppErrorType, stackTrace?: string): void {
    try {
      Logger.error(TAG, `Global error occurred: ${type}`, error);
      
      // 记录错误信息 Log error information
      // 这里可以添加具体的错误记录逻辑 Here can add specific error logging logic
      
      // 更新应用状态 Update app state
      this.setState(AppState.ERROR);
    } catch (handlerError) {
      Logger.error(TAG, 'Failed to handle global error', handlerError instanceof Error ? handlerError : new Error(String(handlerError)));
    }
  }

  /**
   * 初始化应用服务 Initialize application service
   * @returns 是否初始化成功 Whether initialization is successful
   */
  public async initialize(): Promise<boolean> {
    try {
      Logger.info(TAG, 'Initializing AppService...');
      this.setState(AppState.INITIALIZING);

      // 初始化存储服务 Initialize storage service
      const storageInitialized = await StorageUtil.initialize();
      if (!storageInitialized) {
        Logger.error(TAG, 'Failed to initialize storage service');
        return false;
      }

      // 加载应用配置 Load app config
      await this.loadAppConfig();

      // 加载应用信息 Load app info
      await this.loadAppInfo();

      // 加载应用统计信息 Load app statistics
      await this.loadAppStatistics();

      // 注册核心服务 Register core services
      await this.registerCoreServices();

      // 执行启动清理 Execute startup cleanup
      await this.performStartupCleanup();

      // 更新启动统计 Update launch statistics
      await this.updateLaunchStatistics();

      // 检查更新 Check for updates
      await this.checkForUpdates();

      // 更新存储统计 Update storage statistics
      await this.updateStorageStatistics();

      this.isInitialized = true;
      this.setState(AppState.READY);
      Logger.info(TAG, 'AppService initialized successfully');
      return true;
    } catch (error) {
      Logger.error(TAG, 'Application initialization failed', error instanceof Error ? error : new Error(String(error)));
      this.setState(AppState.ERROR);
      return false;
    }
  }

  /**
   * 获取默认配置 Get default config
   * @returns 默认配置 Default config
   */
  private getDefaultConfig(): AppConfig {
    return {
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
      maxVideoQuality: 'auto',
      defaultSubtitleLanguage: 'zh-CN',
      defaultAudioLanguage: 'zh-CN',
      playbackSpeed: 1.0,
      theme: 'system',
      language: 'zh-CN',
      interfaceScale: 'medium',
      animationEnabled: true,
      cacheEnabled: true,
      networkTimeout: 30000,
      retryCount: 3
    };
  }

  /**
   * 获取默认应用信息 Get default app info
   * @returns 默认应用信息 Default app info
   */
  private getDefaultAppInfo(): AppInfo {
    return {
      appName: 'RayTV',
      packageName: 'com.raytv.app',
      versionName: '1.0.0',
      versionCode: 1,
      buildType: 'debug',
      targetSdkVersion: 9,
      minSdkVersion: 7,
      deviceId: '',
      deviceModel: '',
      deviceManufacturer: '',
      osVersion: '',
      screenWidth: 0,
      screenHeight: 0,
      isTablet: false,
      isTV: true,
      countryCode: 'CN',
      languageCode: 'zh',
      isRooted: false,
      installTime: Date.now(),
      lastUpdateTime: Date.now(),
      firstLaunchTime: Date.now(),
      launchCount: 1,
      totalRunningTime: 0,
      lastLaunchTime: Date.now()
    };
  }

  /**
   * 创建默认统计信息 Create default statistics
   * @returns 默认统计信息 Default statistics
   */
  private getDefaultStatistics(): AppStatistics {
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
      deviceStorageUsed: 0
    };
  }

  /**
   * 加载应用配置 Load app config
   */
  private async loadAppConfig(): Promise<void> {
    try {
      const configStr = await StorageUtil.getString('app_config');
      if (configStr) {
        const loadedConfig = JsonUtil.parse(configStr);
        if (loadedConfig) {
          this.appConfig = { ...this.appConfig, ...loadedConfig };
        }
      }
      Logger.info(TAG, 'App config loaded successfully');
    } catch (error) {
      Logger.error(TAG, 'Failed to load app config', error instanceof Error ? error : new Error(String(error)));
      // 使用默认配置 Use default config
    }
  }

  /**
   * 保存应用配置 Save app config
   */
  private async saveAppConfig(): Promise<void> {
    try {
      const configStr = JsonUtil.stringify(this.appConfig);
      await StorageUtil.putString('app_config', configStr);
      Logger.info(TAG, 'App config saved successfully');
    } catch (error) {
      Logger.error(TAG, 'Failed to save app config', error instanceof Error ? error : new Error(String(error)));
    }
  }

  /**
   * 加载应用信息 Load app info
   */
  private async loadAppInfo(): Promise<void> {
    try {
      // 这里可以添加获取设备和应用信息的逻辑 Here can add logic to get device and app info
      Logger.info(TAG, 'App info loaded successfully');
    } catch (error) {
      Logger.error(TAG, 'Failed to load app info', error instanceof Error ? error : new Error(String(error)));
      // 确保抛出的总是Error类型，并添加更有用的错误信息 Ensure always throw Error type, and add more useful error information
    }
  }

  /**
   * 加载应用统计信息 Load app statistics
   */
  private async loadAppStatistics(): Promise<void> {
    try {
      const statsStr = await StorageUtil.getString('app_statistics');
      if (statsStr) {
        const loadedStats = JsonUtil.parse(statsStr);
        if (loadedStats) {
          this.appStatistics = { ...this.appStatistics, ...loadedStats };
        }
      }
      Logger.info(TAG, 'App statistics loaded successfully');
    } catch (error) {
      Logger.error(TAG, 'Failed to load app statistics', error instanceof Error ? error : new Error(String(error)));
      // 使用默认统计 Use default statistics
    }
  }

  /**
   * 保存应用统计信息 Save app statistics
   */
  private async saveAppStatistics(): Promise<void> {
    try {
      const statsStr = JsonUtil.stringify(this.appStatistics);
      await StorageUtil.putString('app_statistics', statsStr);
      Logger.info(TAG, 'App statistics saved successfully');
    } catch (error) {
      Logger.error(TAG, 'Failed to save app statistics', error instanceof Error ? error : new Error(String(error)));
    }
  }

  /**
   * 更新启动统计 Update launch statistics
   */
  private async updateLaunchStatistics(): Promise<void> {
    try {
      this.appStatistics.totalLaunches++;
      this.appStatistics.lastLaunchTime = Date.now();
      await this.saveAppStatistics();
      Logger.info(TAG, 'Launch statistics updated successfully');
    } catch (error) {
      Logger.error(TAG, 'Failed to update launch statistics', error instanceof Error ? error : new Error(String(error)));
    }
  }

  /**
   * 执行启动清理 Perform startup cleanup
   */
  private async performStartupCleanup(): Promise<void> {
    try {
      // 这里可以添加启动清理逻辑 Here can add startup cleanup logic
      Logger.info(TAG, 'Startup cleanup completed successfully');
    } catch (error) {
      Logger.error(TAG, 'Failed to perform startup cleanup', error instanceof Error ? error : new Error(String(error)));
    }
  }

  /**
   * 更新存储统计 Update storage statistics
   */
  private async updateStorageStatistics(): Promise<void> {
    try {
      // 这里可以添加存储统计更新逻辑 Here can add storage statistics update logic
      Logger.info(TAG, 'Storage statistics updated successfully');
    } catch (error) {
      Logger.error(TAG, 'Failed to update storage statistics', error instanceof Error ? error : new Error(String(error)));
    }
  }

  /**
   * 检查更新 Check for updates
   */
  private async checkForUpdates(): Promise<void> {
    try {
      // 这里可以添加检查更新逻辑 Here can add update checking logic
      Logger.info(TAG, 'Update check completed successfully');
    } catch (error) {
      Logger.error(TAG, 'Failed to check for updates', error instanceof Error ? error : new Error(String(error)));
    }
  }

  /**
   * 注册核心服务 Register core services
   */
  private async registerCoreServices(): Promise<void> {
    try {
      // 注册核心服务 Register core services
      const coreServices = [
        { name: 'config', service: ConfigService.getInstance() },
        { name: 'cache', service: CacheService.getInstance() },
        { name: 'http', service: HttpService.getInstance() },
        { name: 'movie', service: MovieService.getInstance() },
        { name: 'media', service: MediaService.getInstance() },
        { name: 'history', service: HistoryService.getInstance() },
        { name: 'player', service: PlayerService.getInstance() },
        { name: 'liveStream', service: LiveStreamService.getInstance() },
        { name: 'subtitle', service: SubtitleService.getInstance() },
        { name: 'parser', service: getParserService() },
        { name: 'analytics', service: AnalyticsService.getInstance() },
        { name: 'voiceAssistant', service: VoiceAssistantManager.getInstance() },
        { name: 'device', service: DeviceService.getInstance() },
        { name: 'dataSync', service: DataSyncService.getInstance() },
        { name: 'gesture', service: GestureService.getInstance() },
        { name: 'wallpaper', service: WallManager.getInstance() },
        { name: 'adBlock', service: AdBlockManager.getInstance() },
        { name: 'site', service: SiteService.getInstance() },
        { name: 'crawler', service: CrawlerService.getInstance() }
      ];

      for (const { name, service } of coreServices) {
        await this.registerService(name, service);
      }
      Logger.info(TAG, 'Core services registered successfully');
    } catch (error) {
      Logger.error(TAG, 'Failed to register core services', error instanceof Error ? error : new Error(String(error)));
    }
  }

  /**
   * 注册服务 Register service
   * @param serviceName 服务名称 Service name
   * @param service 服务实例 Service instance
   * @returns 是否注册成功 Whether registration is successful
   */
  public async registerService(serviceName: string, service: any): Promise<boolean> {
    try {
      if (!service || !serviceName) {
        Logger.error(TAG, 'Invalid service or service name');
        return false;
      }

      // 检查服务是否已存在 Check if service already exists
      if (this.services.has(serviceName)) {
        Logger.warn(TAG, `Service ${serviceName} already registered`);
        return true;
      }

      // 初始化服务 Initialize service
      if (typeof service.initialize === 'function') {
        await service.initialize();
      }

      // 注册服务 Register service
      this.services.set(serviceName, service);
      Logger.info(TAG, `Service ${serviceName} registered successfully`);
      return true;
    } catch (error) {
      Logger.error(TAG, `Failed to register service: ${serviceName}`, error instanceof Error ? error : new Error(String(error)));
      return false;
    }
  }

  /**
   * 注销服务 Unregister service
   * @param serviceName 服务名称 Service name
   * @returns 是否注销成功 Whether unregistration is successful
   */
  public async unregisterService(serviceName: string): Promise<boolean> {
    try {
      const service = this.services.get(serviceName);
      if (!service) {
        Logger.warn(TAG, `Service ${serviceName} not found`);
        return false;
      }

      // 销毁服务 Destroy service
      if (typeof service.destroy === 'function') {
        await service.destroy();
      }

      // 移除服务 Remove service
      this.services.delete(serviceName);
      Logger.info(TAG, `Service ${serviceName} unregistered successfully`);
      return true;
    } catch (error) {
      Logger.error(TAG, `Failed to unregister service: ${serviceName}`, error instanceof Error ? error : new Error(String(error)));
      return false;
    }
  }

  /**
   * 获取服务 Get service
   * @param serviceName 服务名称 Service name
   * @returns 服务实例 Service instance
   */
  public getService<T>(serviceName: string): T | null {
    return this.services.get(serviceName) as T | null;
  }

  /**
   * 获取应用状态 Get app state
   * @returns 应用状态 App state
   */
  public getState(): AppState {
    return this.state;
  }

  /**
   * 设置应用状态 Set app state
   * @param newState 新状态 New state
   */
  public setState(newState: AppState): void {
    if (this.state !== newState) {
      const oldState = this.state;
      this.state = newState;
      Logger.info(TAG, `App state changed: ${oldState} -> ${newState}`);
      
      // 触发状态变化事件 Trigger state change event
      this.notifyStateChange(oldState, newState);
    }
  }

  /**
   * 通知状态变化 Notify state change
   * @param oldState 旧状态 Old state
   * @param newState 新状态 New state
   */
  private notifyStateChange(oldState: AppState, newState: AppState): void {
    try {
      // 这里可以添加状态变化通知逻辑 Here can add state change notification logic
    } catch (error) {
      Logger.error(TAG, 'Error in state listener', error instanceof Error ? error : new Error(String(error)));
    }
  }

  /**
   * 获取应用配置 Get app config
   * @returns 应用配置 App config
   */
  public getConfig(): AppConfig {
    return { ...this.appConfig };
  }

  /**
   * 更新应用配置 Update app config
   * @param config 更新的配置 Updated config
   * @returns 更新后的配置 Updated config
   */
  public async updateConfig(config: Partial<AppConfig>): Promise<AppConfig> {
    try {
      this.appConfig = { ...this.appConfig, ...config };
      await this.saveAppConfig();
      Logger.info(TAG, 'App config updated successfully');
      return { ...this.appConfig };
    } catch (error) {
      Logger.error(TAG, 'Failed to update app config', error instanceof Error ? error : new Error(String(error)));
      return { ...this.appConfig };
    }
  }

  /**
   * 重置应用配置 Reset app config
   * @returns 重置后的配置 Reset config
   */
  public async resetConfig(): Promise<AppConfig> {
    try {
      this.appConfig = this.getDefaultConfig();
      await this.saveAppConfig();
      Logger.info(TAG, 'App config reset successfully');
      return { ...this.appConfig };
    } catch (error) {
      Logger.error(TAG, 'Failed to reset app config', error instanceof Error ? error : new Error(String(error)));
      return { ...this.appConfig };
    }
  }

  /**
   * 获取应用信息 Get app info
   * @returns 应用信息 App info
   */
  public getAppInfo(): AppInfo {
    return { ...this.appInfo };
  }

  /**
   * 获取应用统计信息 Get app statistics
   * @returns 应用统计信息 App statistics
   */
  public getStatistics(): AppStatistics {
    return { ...this.appStatistics };
  }

  /**
   * 更新应用统计信息 Update app statistics
   * @param statistics 更新的统计信息 Updated statistics
   * @returns 更新后的统计信息 Updated statistics
   */
  public async updateStatistics(statistics: Partial<AppStatistics>): Promise<AppStatistics> {
    try {
      this.appStatistics = { ...this.appStatistics, ...statistics };
      await this.saveAppStatistics();
      Logger.info(TAG, 'App statistics updated successfully');
      return { ...this.appStatistics };
    } catch (error) {
      Logger.error(TAG, 'Failed to update app statistics', error instanceof Error ? error : new Error(String(error)));
      return { ...this.appStatistics };
    }
  }

  /**
   * 重置应用统计信息 Reset app statistics
   * @returns 重置后的统计信息 Reset statistics
   */
  public async resetStatistics(): Promise<AppStatistics> {
    try {
      this.appStatistics = this.getDefaultStatistics();
      await this.saveAppStatistics();
      Logger.info(TAG, 'App statistics reset successfully');
      return { ...this.appStatistics };
    } catch (error) {
      Logger.error(TAG, 'Failed to reset app statistics', error instanceof Error ? error : new Error(String(error)));
      return { ...this.appStatistics };
    }
  }

  /**
   * 处理应用前台事件 Handle app foreground event
   */
  public async handleAppForeground(): Promise<void> {
    try {
      this.setState(AppState.FOREGROUND);
      Logger.info(TAG, 'App moved to foreground');
    } catch (error) {
      Logger.error(TAG, 'Failed to handle app foreground', error instanceof Error ? error : new Error(String(error)));
    }
  }

  /**
   * 处理应用后台事件 Handle app background event
   */
  public async handleAppBackground(): Promise<void> {
    try {
      this.setState(AppState.BACKGROUND);
      Logger.info(TAG, 'App moved to background');
    } catch (error) {
      Logger.error(TAG, 'Failed to handle app background', error instanceof Error ? error : new Error(String(error)));
    }
  }

  /**
   * 退出应用 Exit app
   */
  public async exit(): Promise<void> {
    try {
      this.setState(AppState.SHUTTING_DOWN);
      Logger.info(TAG, 'Exiting app...');
      
      // 保存应用状态 Save app state
      await this.saveAppConfig();
      await this.saveAppStatistics();
      
      // 注销所有服务 Unregister all services
      for (const [serviceName] of this.services) {
        await this.unregisterService(serviceName);
      }
      
      Logger.info(TAG, 'App exited successfully');
    } catch (error) {
      Logger.error(TAG, 'Failed to exit app', error instanceof Error ? error : new Error(String(error)));
    }
  }
}
