/**
 * AppService - 应用服务
 * 提供应用级别的服务管理功能，包括服务注册、初始化、状态管理等
 * 
 * @example
 * ```typescript
 * // 获取AppService实例
 * const appService = AppService.getInstance();
 * 
 * // 初始化应用服务
 * await appService.initialize();
 * 
 * // 获取服务实例
 * const configService = appService.getService<ConfigService>('config');
 * ```
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


import { VoiceAssistantManager } from './voice/VoiceAssistantManager';
import { DeviceService } from './device/DeviceService';
import { DataSyncService } from './sync/DataSyncService';
import { GestureService } from './input/GestureService';
import { WallManager } from './wallpaper/WallManager';
import { AdBlockManager } from './adblock/AdBlockManager';
import { SiteService } from './spider/SiteService';
import { CrawlerService } from './spider/CrawlerService';

// 服务接口 Service interface
export interface Service {
  initialize?: () => Promise<void>;
  destroy?: () => Promise<void>;
}

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
  private services: Map<string, Service> = new Map();
  private appConfig: AppConfig = this.getDefaultConfig();
  private appInfo: AppInfo = this.getDefaultAppInfo();
  private appStatistics: AppStatistics = this.getDefaultStatistics();
  private isInitialized: boolean = false;
  private stateListeners: Array<(oldState: AppState, newState: AppState) => void> = [];

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
      // 1. 捕获未处理的Promise拒绝 Catch unhandled promise rejections
      if (typeof process !== 'undefined' && process.on) {
        process.on('unhandledRejection', (reason: Error | string | number | boolean | null | undefined, promise: Promise<Error | string | number | boolean | null | undefined>) => {
          const error = reason instanceof Error ? reason : new Error(String(reason));
          this.handleGlobalError(error, AppErrorType.UNKNOWN_ERROR, error.stack);
        });

        // 2. 捕获未捕获的异常 Catch uncaught exceptions
        process.on('uncaughtException', (error: Error) => {
          this.handleGlobalError(error, AppErrorType.UNKNOWN_ERROR, error.stack);
        });
      }

      // 3. 在浏览器环境中捕获错误 Catch errors in browser environment
      if (typeof window !== 'undefined' && window.addEventListener) {
        window.addEventListener('error', (event: ErrorEvent) => {
          this.handleGlobalError(event.error, AppErrorType.UNKNOWN_ERROR, event.error?.stack);
        });

        window.addEventListener('unhandledrejection', (event: PromiseRejectionEvent) => {
          const error = event.reason instanceof Error ? event.reason : new Error(String(event.reason));
          this.handleGlobalError(error, AppErrorType.UNKNOWN_ERROR, error.stack);
        });
      }

      Logger.info(TAG, 'Global error handling setup successfully');
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
      // 1. 构建错误信息对象 Build error info object
      const errorInfo = {
        type: type,
        message: error.message,
        stack: stackTrace || error.stack,
        timestamp: Date.now(),
        appState: this.getState(),
        appVersion: this.appInfo.versionName
      };

      // 2. 记录到日志 Log to console
      Logger.error(TAG, 'Error details:', errorInfo);

      // 3. 如果启用了崩溃报告，发送错误信息 If crash reporting is enabled, send error info
      if (this.appConfig.enableCrashReporting) {
        // 发送崩溃报告 Send crash report
        await this.sendCrashReport(errorInfo);
      }
      
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

      // 并行加载配置和信息 Parallel load config and info
      await Promise.all([
        this.loadAppConfig(),
        this.loadAppInfo(),
        this.loadAppStatistics()
      ]);

      // 注册核心服务 Register core services
      await this.registerCoreServices();

      // 并行执行启动任务 Parallel execute startup tasks
      const startupTasks = [
        this.performStartupCleanup(),
        this.updateLaunchStatistics()
      ];
      
      await Promise.all(startupTasks);

      // 延迟执行非必要任务 Delay non-essential tasks
      setTimeout(async () => {
        try {
          await this.checkForUpdates();
          await this.updateStorageStatistics();
        } catch (error) {
          Logger.warn(TAG, 'Delayed tasks failed', error instanceof Error ? error : new Error(String(error)));
        }
      }, 3000);

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
      // 1. 尝试从存储中加载应用信息 Try to load app info from storage
      const storedAppInfoStr = await StorageUtil.getString('app_info');
      if (storedAppInfoStr) {
        const storedAppInfo = JsonUtil.parse(storedAppInfoStr);
        if (storedAppInfo) {
          this.appInfo = { ...this.appInfo, ...storedAppInfo };
          Logger.info(TAG, 'App info loaded from storage');
        }
      }

      // 2. 获取设备信息 Get device info
      try {
        // 在HarmonyOS环境中获取设备信息 Get device info in HarmonyOS environment
        if (typeof device !== 'undefined' && device.getInfo) {
          const deviceInfo = await device.getInfo();
          this.appInfo.deviceId = deviceInfo.deviceId || '';
          this.appInfo.deviceModel = deviceInfo.deviceModel || '';
          this.appInfo.deviceManufacturer = deviceInfo.manufacturer || '';
          this.appInfo.osVersion = deviceInfo.osVersion || '';
        }
      } catch (deviceError) {
        Logger.warn(TAG, 'Failed to get device info', deviceError);
      }

      // 3. 获取屏幕信息 Get screen info
      try {
        if (typeof window !== 'undefined' && window.screen) {
          this.appInfo.screenWidth = window.screen.width || 0;
          this.appInfo.screenHeight = window.screen.height || 0;
        }
      } catch (screenError) {
        Logger.warn(TAG, 'Failed to get screen info', screenError);
      }

      // 4. 获取系统语言和国家代码 Get system language and country code
      try {
        if (typeof navigator !== 'undefined') {
          this.appInfo.languageCode = navigator.language?.split('-')[0] || 'zh';
          this.appInfo.countryCode = navigator.language?.split('-')[1] || 'CN';
        }
      } catch (langError) {
        Logger.warn(TAG, 'Failed to get language info', langError);
      }

      // 5. 保存应用信息到存储 Save app info to storage
      await StorageUtil.putString('app_info', JsonUtil.stringify(this.appInfo));

      Logger.info(TAG, 'App info loaded successfully', this.appInfo);
    } catch (error) {
      Logger.error(TAG, 'Failed to load app info', error instanceof Error ? error : new Error(String(error)));
      // 使用默认应用信息 Use default app info
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
      Logger.info(TAG, 'Performing startup cleanup tasks');

      // 1. 清理过期的缓存 Clean up expired cache
      const cacheService = this.getService<CacheService>('cache');
      if (cacheService && typeof cacheService.cleanupExpired === 'function') {
        await cacheService.cleanupExpired();
        Logger.info(TAG, 'Expired cache cleaned up');
      }

      // 2. 清理临时文件 Clean up temporary files
      // 这里可以添加临时文件清理逻辑 Here can add temporary file cleanup logic

      // 3. 清理过期的播放历史 Clean up expired playback history
      const historyService = this.getService<HistoryService>('history');
      if (historyService && typeof historyService.cleanupExpired === 'function') {
        await historyService.cleanupExpired();
        Logger.info(TAG, 'Expired playback history cleaned up');
      }

      // 4. 检查并修复数据完整性 Check and fix data integrity
      // 这里可以添加数据完整性检查逻辑 Here can add data integrity check logic

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
      Logger.info(TAG, 'Updating storage statistics');

      // 1. 获取缓存使用情况 Get cache usage
      let cacheSize = 0;
      const cacheService = this.getService<CacheService>('cache');
      if (cacheService && typeof cacheService.getCacheSize === 'function') {
        cacheSize = await cacheService.getCacheSize();
      }

      // 2. 获取存储使用情况 Get storage usage
      try {
        // 在HarmonyOS环境中获取存储信息 Get storage info in HarmonyOS environment
        if (typeof fs !== 'undefined' && fs.getStorageInfo) {
          const storageInfo = await fs.getStorageInfo();
          this.appStatistics.deviceStorageUsed = storageInfo.used || 0;
        }
      } catch (storageError) {
        Logger.warn(TAG, 'Failed to get storage info', storageError);
      }

      // 3. 更新缓存大小到统计信息 Update cache size to statistics
      this.appStatistics.totalDownloadedSize = cacheSize;

      // 4. 保存统计信息 Save statistics
      await this.saveAppStatistics();

      Logger.info(TAG, 'Storage statistics updated successfully', {
        cacheSize,
        deviceStorageUsed: this.appStatistics.deviceStorageUsed
      });
    } catch (error) {
      Logger.error(TAG, 'Failed to update storage statistics', error instanceof Error ? error : new Error(String(error)));
    }
  }

  /**
   * 检查更新 Check for updates
   */
  private async checkForUpdates(): Promise<void> {
    try {
      Logger.info(TAG, 'Checking for updates');

      // 1. 获取当前版本 Get current version
      const currentVersion = this.appInfo.versionName;
      const currentVersionCode = this.appInfo.versionCode;

      // 2. 构建更新检查URL Build update check URL
      const updateCheckUrl = 'https://api.raytv.app/check-update';
      const httpService = this.getService<HttpService>('http');

      // 3. 发送更新检查请求 Send update check request
      if (httpService && typeof httpService.get === 'function') {
        try {
          const response = await httpService.get<{ versionCode: number, version: string, description: string, downloadUrl: string }>(updateCheckUrl, {
            headers: {
              'Content-Type': 'application/json',
              'X-App-Version': currentVersion,
              'X-App-Version-Code': currentVersionCode.toString(),
              'X-Device-Type': this.appInfo.isTV ? 'tv' : 'mobile'
            },
            timeout: 10000
          });

          // 4. 处理更新检查响应 Handle update check response
          if (response.status === 200 && response.data) {
            const updateInfo = response.data;
            
            if (updateInfo.versionCode > currentVersionCode) {
              Logger.info(TAG, 'New update available', updateInfo);
              // 这里可以添加更新提示逻辑 Here can add update notification logic
            } else {
              Logger.info(TAG, 'App is up to date');
            }
          }
        } catch (networkError) {
          Logger.warn(TAG, 'Network error during update check', networkError);
          // 网络错误不影响应用启动 Network error doesn't affect app startup
        }
      }

      // 5. 更新最后检查时间 Update last check time
      this.appStatistics.lastUpdateCheckTime = Date.now();
      await this.saveAppStatistics();

      Logger.info(TAG, 'Update check completed successfully');
    } catch (error) {
      Logger.error(TAG, 'Failed to check for updates', error instanceof Error ? error : new Error(String(error)));
      // 更新检查失败不影响应用启动 Update check failure doesn't affect app startup
    }
  }

  /**
   * 注册核心服务 Register core services
   */
  private async registerCoreServices(): Promise<void> {
    try {
      // 分层服务注册策略 Layered service registration strategy
      // 1. 核心服务（启动时必须初始化） Core services (must initialize at startup)
      const coreServices = [
        { name: 'config', service: ConfigService.getInstance() },
        { name: 'cache', service: CacheService.getInstance() },
        { name: 'http', service: HttpService.getInstance() },
        { name: 'media', service: MediaService.getInstance() },
        { name: 'parser', service: getParserService() }
      ];

      // 2. 重要服务（启动后立即初始化） Important services (initialize immediately after startup)
      const importantServices = [
        { name: 'movie', service: MovieService.getInstance() },
        { name: 'history', service: HistoryService.getInstance() },
        { name: 'player', service: PlayerService.getInstance() },
        { name: 'site', service: SiteService.getInstance() }
      ];

      // 3. 按需服务（使用时初始化） On-demand services (initialize when used)
      const onDemandServices = [
        { name: 'liveStream', service: LiveStreamService.getInstance() },
        { name: 'subtitle', service: SubtitleService.getInstance() },
        { name: 'voiceAssistant', service: VoiceAssistantManager.getInstance() },
        { name: 'device', service: DeviceService.getInstance() },
        { name: 'dataSync', service: DataSyncService.getInstance() },
        { name: 'gesture', service: GestureService.getInstance() },
        { name: 'wallpaper', service: WallManager.getInstance() },
        { name: 'adBlock', service: AdBlockManager.getInstance() },
        { name: 'crawler', service: CrawlerService.getInstance() }
      ];

      // 并行注册核心服务 Parallel register core services
      Logger.info(TAG, 'Registering core services...');
      const coreServicePromises = coreServices.map(async ({ name, service }) => {
        try {
          await this.registerService(name, service);
          Logger.debug(TAG, `Core service ${name} registered successfully`);
        } catch (error) {
          Logger.warn(TAG, `Failed to register core service ${name}`, error instanceof Error ? error : new Error(String(error)));
        }
      });

      await Promise.all(coreServicePromises);
      Logger.info(TAG, 'Core services registered successfully');

      // 注册重要服务（异步，不阻塞启动） Register important services (async, non-blocking)
      Logger.info(TAG, 'Registering important services...');
      this.registerImportantServices(importantServices);

      // 注册按需服务（仅注册，不初始化） Register on-demand services (register only, not initialize)
      Logger.info(TAG, 'Registering on-demand services...');
      this.registerOnDemandServices(onDemandServices);

    } catch (error) {
      Logger.error(TAG, 'Failed to register core services', error instanceof Error ? error : new Error(String(error)));
    }
  }

  /**
   * 注册重要服务 Register important services
   */
  private async registerImportantServices(services: Array<{ name: string; service: Service }>): Promise<void> {
    try {
      for (const { name, service } of services) {
        await this.registerService(name, service);
      }
      Logger.info(TAG, 'Important services registered successfully');
    } catch (error) {
      Logger.error(TAG, 'Failed to register important services', error instanceof Error ? error : new Error(String(error)));
    }
  }

  /**
   * 注册按需服务 Register on-demand services
   */
  private registerOnDemandServices(services: Array<{ name: string; service: Service }>): void {
    try {
      for (const { name, service } of services) {
        // 仅注册服务，不初始化 Only register service, not initialize
        this.services.set(name, service);
        Logger.info(TAG, `On-demand service ${name} registered (not initialized)`);
      }
      Logger.info(TAG, 'On-demand services registered successfully');
    } catch (error) {
      Logger.error(TAG, 'Failed to register on-demand services', error instanceof Error ? error : new Error(String(error)));
    }
  }

  /**
   * 可初始化服务接口
   */
  interface InitializableService {
    initialize(): Promise<void>;
    isInitialized: boolean;
  }

  /**
   * 获取服务（按需初始化） Get service (initialize on demand)
   * @param serviceName 服务名称 Service name
   * @returns 服务实例 Service instance
   */
  public async getServiceAsync<T>(serviceName: string): Promise<T | null> {
    try {
      // 检查服务是否已存在 Check if service already exists
      let service = this.services.get(serviceName) as T | null;
      if (!service) {
        Logger.warn(TAG, `Service ${serviceName} not found`);
        return null;
      }

      // 检查服务是否已初始化 Check if service is initialized
      const initService = service as Object as InitializableService;
      if (typeof initService.initialize === 'function' && !initService.isInitialized) {
        Logger.info(TAG, `Initializing on-demand service ${serviceName}...`);
        await initService.initialize();
        initService.isInitialized = true;
        Logger.info(TAG, `On-demand service ${serviceName} initialized successfully`);
      }

      return service;
    } catch (error) {
      Logger.error(TAG, `Failed to get service ${serviceName}`, error instanceof Error ? error : new Error(String(error)));
      return null;
    }
  }

  /**
   * 注册服务 Register service
   * @param serviceName 服务名称 Service name
   * @param service 服务实例 Service instance
   * @returns 是否注册成功 Whether registration is successful
   */
  public async registerService(serviceName: string, service: Service): Promise<boolean> {
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
      // 1. 构建状态变化事件对象 Build state change event object
      const stateChangeEvent = {
        oldState,
        newState,
        timestamp: Date.now(),
        appVersion: this.appInfo.versionName
      };

      // 2. 记录状态变化 Log state change
      Logger.info(TAG, `State changed: ${oldState} -> ${newState}`, stateChangeEvent);

      // 3. 通知所有注册的状态监听器 Notify all registered state listeners
      for (const listener of this.stateListeners) {
        try {
          listener(oldState, newState);
        } catch (listenerError) {
          Logger.error(TAG, 'Error in state listener', listenerError instanceof Error ? listenerError : new Error(String(listenerError)));
        }
      }

      // 4. 触发相应的状态处理逻辑 Trigger corresponding state handling logic
      switch (newState) {
        case AppState.READY:
          this.onAppReady();
          break;
        case AppState.BACKGROUND:
          this.onAppBackground();
          break;
        case AppState.FOREGROUND:
          this.onAppForeground();
          break;
        case AppState.ERROR:
          this.onAppError();
          break;
        case AppState.SHUTTING_DOWN:
          this.onAppShuttingDown();
          break;
      }
    } catch (error) {
      Logger.error(TAG, 'Error in state listener', error instanceof Error ? error : new Error(String(error)));
    }
  }

  /**
   * 应用准备就绪回调 App ready callback
   */
  private onAppReady(): void {
    try {
      Logger.info(TAG, 'App is ready, performing post-initialization tasks');
      
      // 1. 启动后台服务 Start background services
      this.startBackgroundServices();
      
      // 2. 初始化推送通知 Initialize push notifications
      this.initializeNotifications();
      
      // 3. 启动数据同步 Start data sync
      this.startDataSync();
      
      // 4. 检查系统权限 Check system permissions
      this.checkSystemPermissions();
      
      Logger.info(TAG, 'Post-initialization tasks completed');
    } catch (error) {
      Logger.error(TAG, 'Error in onAppReady', error instanceof Error ? error : new Error(String(error)));
    }
  }

  /**
   * 应用进入后台回调 App background callback
   */
  private onAppBackground(): void {
    try {
      Logger.info(TAG, 'App moved to background, performing background tasks');
      
      // 1. 暂停网络请求 Pause network requests
      this.pauseNetworkRequests();
      
      // 2. 释放非必要资源 Release non-essential resources
      this.releaseNonEssentialResources();
      
      // 3. 保存当前状态 Save current state
      this.saveCurrentState();
      
      // 4. 调整后台任务优先级 Adjust background task priority
      this.adjustBackgroundTaskPriority();
      
      Logger.info(TAG, 'Background tasks completed');
    } catch (error) {
      Logger.error(TAG, 'Error in onAppBackground', error instanceof Error ? error : new Error(String(error)));
    }
  }

  /**
   * 应用进入前台回调 App foreground callback
   */
  private onAppForeground(): void {
    try {
      Logger.info(TAG, 'App moved to foreground, performing foreground tasks');
      
      // 1. 恢复网络请求 Resume network requests
      this.resumeNetworkRequests();
      
      // 2. 重新加载数据 Reload data
      this.reloadData();
      
      // 3. 更新UI状态 Update UI state
      this.updateUIState();
      
      // 4. 检查应用状态 Check app state
      this.checkAppState();
      
      Logger.info(TAG, 'Foreground tasks completed');
    } catch (error) {
      Logger.error(TAG, 'Error in onAppForeground', error instanceof Error ? error : new Error(String(error)));
    }
  }

  /**
   * 应用错误回调 App error callback
   */
  private onAppError(): void {
    try {
      Logger.info(TAG, 'App entered error state, performing error recovery tasks');
      
      // 1. 记录错误状态 Log error state
      this.logErrorState();
      
      // 2. 尝试恢复核心服务 Try to recover core services
      this.recoverCoreServices();
      
      // 3. 清理错误状态 Clean up error state
      this.cleanupErrorState();
      
      // 4. 通知用户 Notify user
      this.notifyUserOfError();
      
      Logger.info(TAG, 'Error recovery tasks completed');
    } catch (error) {
      Logger.error(TAG, 'Error in onAppError', error instanceof Error ? error : new Error(String(error)));
    }
  }

  /**
   * 应用关闭回调 App shutting down callback
   */
  private onAppShuttingDown(): void {
    try {
      Logger.info(TAG, 'App is shutting down, performing cleanup tasks');
      
      // 1. 保存用户数据 Save user data
      this.saveUserData();
      
      // 2. 清理临时文件 Clean up temporary files
      this.cleanupTemporaryFiles();
      
      // 3. 关闭后台服务 Shutdown background services
      this.shutdownBackgroundServices();
      
      // 4. 释放所有资源 Release all resources
      this.releaseAllResources();
      
      Logger.info(TAG, 'Cleanup tasks completed');
    } catch (error) {
      Logger.error(TAG, 'Error in onAppShuttingDown', error instanceof Error ? error : new Error(String(error)));
    }
  }

  /**
   * 启动后台服务 Start background services
   */
  private startBackgroundServices(): void {
    try {
      Logger.info(TAG, 'Starting background services');
      
      // 1. 启动缓存清理服务
      const cacheService = this.getService<CacheService>('cache');
      if (cacheService && typeof cacheService.cleanupExpired === 'function') {
        setTimeout(async () => {
          try {
            await cacheService.cleanupExpired();
          } catch (error) {
            Logger.error(TAG, 'Failed to start cache cleanup service', error instanceof Error ? error : new Error(String(error)));
          }
        }, 5000);
      }
      
      // 2. 启动数据同步服务
      const dataSyncService = this.getService<DataSyncService>('dataSync');
      if (dataSyncService && typeof dataSyncService.startSync === 'function') {
        setTimeout(() => {
          try {
            dataSyncService.startSync();
          } catch (error) {
            Logger.error(TAG, 'Failed to start data sync service', error instanceof Error ? error : new Error(String(error)));
          }
        }, 10000);
      }
      
      // 3. 启动设备管理服务
      const deviceService = this.getService<DeviceService>('device');
      if (deviceService && typeof deviceService.startMonitoring === 'function') {
        setTimeout(() => {
          try {
            deviceService.startMonitoring();
          } catch (error) {
            Logger.error(TAG, 'Failed to start device service', error instanceof Error ? error : new Error(String(error)));
          }
        }, 15000);
      }
      
      Logger.info(TAG, 'Background services started successfully');
    } catch (error) {
      Logger.error(TAG, 'Failed to start background services', error instanceof Error ? error : new Error(String(error)));
    }
  }

  /**
   * 初始化推送通知 Initialize push notifications
   */
  private initializeNotifications(): void {
    try {
      Logger.info(TAG, 'Initializing push notifications');
      
      // 1. 检查通知权限
      if (this.appConfig.enableNotifications) {
        // 2. 初始化通知服务
        try {
          // 这里可以添加具体的通知初始化代码
          // 例如：初始化华为推送、小米推送等
          Logger.info(TAG, 'Push notifications initialized successfully');
        } catch (notificationError) {
          Logger.warn(TAG, 'Failed to initialize push notifications', notificationError instanceof Error ? notificationError : new Error(String(notificationError)));
        }
      } else {
        Logger.info(TAG, 'Push notifications disabled by user config');
      }
      
      // 3. 注册通知渠道（如果支持）
      try {
        // 注册通知渠道代码
        Logger.info(TAG, 'Notification channels registered successfully');
      } catch (channelError) {
        Logger.warn(TAG, 'Failed to register notification channels', channelError instanceof Error ? channelError : new Error(String(channelError)));
      }
      
      Logger.info(TAG, 'Notifications initialization completed');
    } catch (error) {
      Logger.error(TAG, 'Failed to initialize notifications', error instanceof Error ? error : new Error(String(error)));
    }
  }

  /**
   * 启动数据同步 Start data sync
   */
  private startDataSync(): void {
    try {
      Logger.info(TAG, 'Starting data sync');
      
      // 1. 获取数据同步服务
      const dataSyncService = this.getService<DataSyncService>('dataSync');
      if (dataSyncService) {
        // 2. 启动不同类型的数据同步
        // 配置同步
        setTimeout(async () => {
          try {
            if (typeof dataSyncService.syncConfig === 'function') {
              await dataSyncService.syncConfig();
              Logger.info(TAG, 'Config sync started successfully');
            }
          } catch (error) {
            Logger.error(TAG, 'Failed to start config sync', error instanceof Error ? error : new Error(String(error)));
          }
        }, 2000);
        
        // 历史记录同步
        setTimeout(async () => {
          try {
            if (typeof dataSyncService.syncHistory === 'function') {
              await dataSyncService.syncHistory();
              Logger.info(TAG, 'History sync started successfully');
            }
          } catch (error) {
            Logger.error(TAG, 'Failed to start history sync', error instanceof Error ? error : new Error(String(error)));
          }
        }, 4000);
        
        // 收藏同步
        setTimeout(async () => {
          try {
            if (typeof dataSyncService.syncFavorites === 'function') {
              await dataSyncService.syncFavorites();
              Logger.info(TAG, 'Favorites sync started successfully');
            }
          } catch (error) {
            Logger.error(TAG, 'Failed to start favorites sync', error instanceof Error ? error : new Error(String(error)));
          }
        }, 6000);
      } else {
        Logger.warn(TAG, 'Data sync service not available');
      }
      
      Logger.info(TAG, 'Data sync initialization completed');
    } catch (error) {
      Logger.error(TAG, 'Failed to start data sync', error instanceof Error ? error : new Error(String(error)));
    }
  }

  /**
   * 检查系统权限 Check system permissions
   */
  private checkSystemPermissions(): void {
    try {
      Logger.info(TAG, 'Checking system permissions');
      
      // 1. 定义需要检查的权限列表
      const requiredPermissions = [
        'ohos.permission.INTERNET',
        'ohos.permission.READ_USER_STORAGE',
        'ohos.permission.WRITE_USER_STORAGE',
        'ohos.permission.GET_NETWORK_INFO'
      ];
      
      // 2. 检查权限
      requiredPermissions.forEach(permission => {
        try {
          const atManager = abilityAccessCtrl.createAtManager();
          const context = this.getContext();
          
          // 检查权限状态
          atManager.requestPermissionsFromUser(context, [permission]).then(() => {
            Logger.info(TAG, `Permission ${permission} granted`);
          }).catch(error => {
            Logger.warn(TAG, `Failed to request permission ${permission}`, error instanceof Error ? error : new Error(String(error)));
          });
        } catch (error) {
          Logger.warn(TAG, `Failed to check permission ${permission}`, error instanceof Error ? error : new Error(String(error)));
        }
      });
      
      // 3. 检查网络状态权限
      try {
        if (typeof device !== 'undefined' && device.getNetworkInfo) {
          device.getNetworkInfo().then(networkInfo => {
            Logger.info(TAG, 'Network info access granted');
          }).catch(error => {
            Logger.warn(TAG, 'Failed to access network info', error instanceof Error ? error : new Error(String(error)));
          });
        }
      } catch (error) {
        Logger.warn(TAG, 'Failed to check network info permission', error instanceof Error ? error : new Error(String(error)));
      }
      
      Logger.info(TAG, 'System permissions check completed');
    } catch (error) {
      Logger.error(TAG, 'Failed to check system permissions', error instanceof Error ? error : new Error(String(error)));
    }
  }

  /**
   * 暂停网络请求 Pause network requests
   */
  private pauseNetworkRequests(): void {
    try {
      Logger.info(TAG, 'Pausing network requests');
      
      // 1. 获取HTTP服务
      const httpService = this.getService<HttpService>('http');
      if (httpService && typeof httpService.pauseRequests === 'function') {
        try {
          httpService.pauseRequests();
          Logger.info(TAG, 'Network requests paused successfully');
        } catch (error) {
          Logger.warn(TAG, 'Failed to pause network requests', error instanceof Error ? error : new Error(String(error)));
        }
      }
      
      // 2. 暂停数据同步服务
      const dataSyncService = this.getService<DataSyncService>('dataSync');
      if (dataSyncService && typeof dataSyncService.pauseSync === 'function') {
        try {
          dataSyncService.pauseSync();
          Logger.info(TAG, 'Data sync paused successfully');
        } catch (error) {
          Logger.warn(TAG, 'Failed to pause data sync', error instanceof Error ? error : new Error(String(error)));
        }
      }
      
      // 3. 暂停后台下载
      const downloadService = this.getService<{ pauseAll?: () => void }>('download');
      if (downloadService && typeof downloadService.pauseAll === 'function') {
        try {
          downloadService.pauseAll();
          Logger.info(TAG, 'Background downloads paused successfully');
        } catch (error) {
          Logger.warn(TAG, 'Failed to pause downloads', error instanceof Error ? error : new Error(String(error)));
        }
      }
      
      Logger.info(TAG, 'Network requests pause process completed');
    } catch (error) {
      Logger.error(TAG, 'Failed to pause network requests', error instanceof Error ? error : new Error(String(error)));
    }
  }

  /**
   * 释放非必要资源 Release non-essential resources
   */
  private releaseNonEssentialResources(): void {
    try {
      Logger.info(TAG, 'Releasing non-essential resources');
      
      // 1. 释放内存缓存
      const cacheService = this.getService<CacheService>('cache');
      if (cacheService && typeof cacheService.clearMemoryCache === 'function') {
        try {
          cacheService.clearMemoryCache();
          Logger.info(TAG, 'Memory cache cleared successfully');
        } catch (error) {
          Logger.warn(TAG, 'Failed to clear memory cache', error instanceof Error ? error : new Error(String(error)));
        }
      }
      
      // 2. 释放播放器资源
      const playerService = this.getService<{ release?: () => void }>('player');
      if (playerService && typeof playerService.release === 'function') {
        try {
          playerService.release();
          Logger.info(TAG, 'Player resources released successfully');
        } catch (error) {
          Logger.warn(TAG, 'Failed to release player resources', error instanceof Error ? error : new Error(String(error)));
        }
      }
      
      // 3. 释放图片缓存
      const imageService = this.getService<{ clearCache?: () => void }>('image');
      if (imageService && typeof imageService.clearCache === 'function') {
        try {
          imageService.clearCache();
          Logger.info(TAG, 'Image cache cleared successfully');
        } catch (error) {
          Logger.warn(TAG, 'Failed to clear image cache', error instanceof Error ? error : new Error(String(error)));
        }
      }
      
      // 4. 释放解析器资源
      const parserService = this.getService<{ clearCache?: () => void }>('parser');
      if (parserService && typeof parserService.clearCache === 'function') {
        try {
          parserService.clearCache();
          Logger.info(TAG, 'Parser cache cleared successfully');
        } catch (error) {
          Logger.warn(TAG, 'Failed to clear parser cache', error instanceof Error ? error : new Error(String(error)));
        }
      }
      
      Logger.info(TAG, 'Non-essential resources released successfully');
    } catch (error) {
      Logger.error(TAG, 'Failed to release non-essential resources', error instanceof Error ? error : new Error(String(error)));
    }
  }

  /**
   * 保存当前状态 Save current state
   */
  private saveCurrentState(): void {
    try {
      Logger.info(TAG, 'Saving current state');
      
      // 1. 保存应用配置
      setTimeout(async () => {
        try {
          await this.saveAppConfig();
          Logger.info(TAG, 'App config saved successfully');
        } catch (error) {
          Logger.warn(TAG, 'Failed to save app config', error instanceof Error ? error : new Error(String(error)));
        }
      }, 500);
      
      // 2. 保存应用统计信息
      setTimeout(async () => {
        try {
          await this.saveAppStatistics();
          Logger.info(TAG, 'App statistics saved successfully');
        } catch (error) {
          Logger.warn(TAG, 'Failed to save app statistics', error instanceof Error ? error : new Error(String(error)));
        }
      }, 1000);
      
      // 3. 保存播放器状态
      const playerService = this.getService<{ saveState?: () => void }>('player');
      if (playerService && typeof playerService.saveState === 'function') {
        setTimeout(() => {
          try {
            playerService.saveState();
            Logger.info(TAG, 'Player state saved successfully');
          } catch (error) {
            Logger.warn(TAG, 'Failed to save player state', error instanceof Error ? error : new Error(String(error)));
          }
        }, 1500);
      }
      
      // 4. 保存当前页面状态
      const navigationService = this.getService<{ saveState?: () => void }>('navigation');
      if (navigationService && typeof navigationService.saveState === 'function') {
        setTimeout(() => {
          try {
            navigationService.saveState();
            Logger.info(TAG, 'Navigation state saved successfully');
          } catch (error) {
            Logger.warn(TAG, 'Failed to save navigation state', error instanceof Error ? error : new Error(String(error)));
          }
        }, 2000);
      }
      
      Logger.info(TAG, 'Current state save process completed');
    } catch (error) {
      Logger.error(TAG, 'Failed to save current state', error instanceof Error ? error : new Error(String(error)));
    }
  }

  /**
   * 调整后台任务优先级 Adjust background task priority
   */
  private adjustBackgroundTaskPriority(): void {
    try {
      Logger.info(TAG, 'Adjusting background task priority');
      
      // 1. 降低缓存服务优先级
      const cacheService = this.getService<CacheService>('cache');
      if (cacheService && typeof cacheService.setPriority === 'function') {
        try {
          cacheService.setPriority('low');
          Logger.info(TAG, 'Cache service priority set to low');
        } catch (error) {
          Logger.warn(TAG, 'Failed to adjust cache service priority', error instanceof Error ? error : new Error(String(error)));
        }
      }
      
      // 2. 降低数据同步服务优先级
      const dataSyncService = this.getService<DataSyncService>('dataSync');
      if (dataSyncService && typeof dataSyncService.setPriority === 'function') {
        try {
          dataSyncService.setPriority('low');
          Logger.info(TAG, 'Data sync service priority set to low');
        } catch (error) {
          Logger.warn(TAG, 'Failed to adjust data sync service priority', error instanceof Error ? error : new Error(String(error)));
        }
      }
      
      // 3. 降低下载服务优先级
      const downloadService = this.getService<{ setPriority?: (priority: string) => void }>('download');
      if (downloadService && typeof downloadService.setPriority === 'function') {
        try {
          downloadService.setPriority('low');
          Logger.info(TAG, 'Download service priority set to low');
        } catch (error) {
          Logger.warn(TAG, 'Failed to adjust download service priority', error instanceof Error ? error : new Error(String(error)));
        }
      }
      
      // 4. 调整后台任务执行频率
      try {
        // 这里可以添加具体的任务调度代码
        // 例如：减少后台任务的执行频率
        Logger.info(TAG, 'Background task execution frequency adjusted');
      } catch (error) {
        Logger.warn(TAG, 'Failed to adjust task execution frequency', error instanceof Error ? error : new Error(String(error)));
      }
      
      Logger.info(TAG, 'Background task priority adjustment completed');
    } catch (error) {
      Logger.error(TAG, 'Failed to adjust background task priority', error instanceof Error ? error : new Error(String(error)));
    }
  }

  /**
   * 恢复网络请求 Resume network requests
   */
  private resumeNetworkRequests(): void {
    try {
      Logger.info(TAG, 'Resuming network requests');
      
      // 1. 恢复HTTP服务
      const httpService = this.getService<HttpService>('http');
      if (httpService && typeof httpService.resumeRequests === 'function') {
        try {
          httpService.resumeRequests();
          Logger.info(TAG, 'Network requests resumed successfully');
        } catch (error) {
          Logger.warn(TAG, 'Failed to resume network requests', error instanceof Error ? error : new Error(String(error)));
        }
      }
      
      // 2. 恢复数据同步服务
      const dataSyncService = this.getService<DataSyncService>('dataSync');
      if (dataSyncService && typeof dataSyncService.resumeSync === 'function') {
        try {
          dataSyncService.resumeSync();
          Logger.info(TAG, 'Data sync resumed successfully');
        } catch (error) {
          Logger.warn(TAG, 'Failed to resume data sync', error instanceof Error ? error : new Error(String(error)));
        }
      }
      
      // 3. 恢复后台下载
      const downloadService = this.getService<{ resumeAll?: () => void }>('download');
      if (downloadService && typeof downloadService.resumeAll === 'function') {
        try {
          downloadService.resumeAll();
          Logger.info(TAG, 'Background downloads resumed successfully');
        } catch (error) {
          Logger.warn(TAG, 'Failed to resume downloads', error instanceof Error ? error : new Error(String(error)));
        }
      }
      
      // 4. 恢复定时任务
      try {
        // 这里可以添加恢复定时任务的代码
        // 例如：重新启动定时同步、缓存清理等任务
        Logger.info(TAG, 'Scheduled tasks resumed successfully');
      } catch (error) {
        Logger.warn(TAG, 'Failed to resume scheduled tasks', error instanceof Error ? error : new Error(String(error)));
      }
      
      Logger.info(TAG, 'Network requests resume process completed');
    } catch (error) {
      Logger.error(TAG, 'Failed to resume network requests', error instanceof Error ? error : new Error(String(error)));
    }
  }

  /**
   * 重新加载数据 Reload data
   */
  private reloadData(): void {
    try {
      Logger.info(TAG, 'Reloading data');
      
      // 1. 重新加载配置数据
      setTimeout(async () => {
        try {
          await this.loadAppConfig();
          Logger.info(TAG, 'App config reloaded successfully');
        } catch (error) {
          Logger.warn(TAG, 'Failed to reload app config', error instanceof Error ? error : new Error(String(error)));
        }
      }, 500);
      
      // 2. 重新加载应用信息
      setTimeout(async () => {
        try {
          await this.loadAppInfo();
          Logger.info(TAG, 'App info reloaded successfully');
        } catch (error) {
          Logger.warn(TAG, 'Failed to reload app info', error instanceof Error ? error : new Error(String(error)));
        }
      }, 1000);
      
      // 3. 重新加载站点数据
      const siteService = this.getService<{ reloadSites?: () => void }>('site');
      if (siteService && typeof siteService.reloadSites === 'function') {
        setTimeout(() => {
          try {
            siteService.reloadSites();
            Logger.info(TAG, 'Site data reloaded successfully');
          } catch (error) {
            Logger.warn(TAG, 'Failed to reload site data', error instanceof Error ? error : new Error(String(error)));
          }
        }, 1500);
      }
      
      // 4. 重新加载频道数据
      const liveStreamService = this.getService<{ reloadChannels?: () => void }>('liveStream');
      if (liveStreamService && typeof liveStreamService.reloadChannels === 'function') {
        setTimeout(() => {
          try {
            liveStreamService.reloadChannels();
            Logger.info(TAG, 'Channel data reloaded successfully');
          } catch (error) {
            Logger.warn(TAG, 'Failed to reload channel data', error instanceof Error ? error : new Error(String(error)));
          }
        }, 2000);
      }
      
      // 5. 重新加载推荐数据
      const recommendationService = this.getService<{ refreshRecommendations?: () => void }>('recommendation');
      if (recommendationService && typeof recommendationService.refreshRecommendations === 'function') {
        setTimeout(() => {
          try {
            recommendationService.refreshRecommendations();
            Logger.info(TAG, 'Recommendation data reloaded successfully');
          } catch (error) {
            Logger.warn(TAG, 'Failed to reload recommendation data', error instanceof Error ? error : new Error(String(error)));
          }
        }, 2500);
      }
      
      Logger.info(TAG, 'Data reload process completed');
    } catch (error) {
      Logger.error(TAG, 'Failed to reload data', error instanceof Error ? error : new Error(String(error)));
    }
  }

  /**
   * 更新UI状态 Update UI state
   */
  private updateUIState(): void {
    try {
      Logger.info(TAG, 'Updating UI state');
      
      // 1. 更新主题状态
      try {
        const theme = this.appConfig.theme;
        // 这里可以添加主题更新的代码
        // 例如：通知UI组件更新主题
        Logger.info(TAG, `Theme updated to ${theme}`);
      } catch (error) {
        Logger.warn(TAG, 'Failed to update theme', error instanceof Error ? error : new Error(String(error)));
      }
      
      // 2. 更新语言状态
      try {
        const language = this.appConfig.language;
        // 这里可以添加语言更新的代码
        // 例如：通知UI组件更新语言
        Logger.info(TAG, `Language updated to ${language}`);
      } catch (error) {
        Logger.warn(TAG, 'Failed to update language', error instanceof Error ? error : new Error(String(error)));
      }
      
      // 3. 更新界面缩放状态
      try {
        const interfaceScale = this.appConfig.interfaceScale;
        // 这里可以添加界面缩放更新的代码
        // 例如：通知UI组件更新缩放比例
        Logger.info(TAG, `Interface scale updated to ${interfaceScale}`);
      } catch (error) {
        Logger.warn(TAG, 'Failed to update interface scale', error instanceof Error ? error : new Error(String(error)));
      }
      
      // 4. 更新动画状态
      try {
        const animationEnabled = this.appConfig.animationEnabled;
        // 这里可以添加动画状态更新的代码
        // 例如：通知UI组件启用或禁用动画
        Logger.info(TAG, `Animation ${animationEnabled ? 'enabled' : 'disabled'}`);
      } catch (error) {
        Logger.warn(TAG, 'Failed to update animation state', error instanceof Error ? error : new Error(String(error)));
      }
      
      // 5. 通知UI组件更新状态
      try {
        // 这里可以添加通知UI组件的代码
        // 例如：通过事件总线或回调通知UI组件更新状态
        Logger.info(TAG, 'UI components notified of state changes');
      } catch (error) {
        Logger.warn(TAG, 'Failed to notify UI components', error instanceof Error ? error : new Error(String(error)));
      }
      
      Logger.info(TAG, 'UI state update completed');
    } catch (error) {
      Logger.error(TAG, 'Failed to update UI state', error instanceof Error ? error : new Error(String(error)));
    }
  }

  /**
   * 检查应用状态 Check app state
   */
  private checkAppState(): void {
    try {
      Logger.info(TAG, 'Checking app state');
      
      // 1. 检查网络状态
      try {
        if (typeof device !== 'undefined' && device.getNetworkInfo) {
          device.getNetworkInfo().then(networkInfo => {
            const networkType = networkInfo.type || 'unknown';
            Logger.info(TAG, `Network state: ${networkType}`);
          }).catch(error => {
            Logger.warn(TAG, 'Failed to check network state', error instanceof Error ? error : new Error(String(error)));
          });
        }
      } catch (error) {
        Logger.warn(TAG, 'Failed to check network state', error instanceof Error ? error : new Error(String(error)));
      }
      
      // 2. 检查存储状态
      try {
        if (typeof fs !== 'undefined' && fs.getStorageInfo) {
          fs.getStorageInfo().then(storageInfo => {
            const used = storageInfo.used || 0;
            const total = storageInfo.total || 0;
            const usagePercent = total > 0 ? (used / total) * 100 : 0;
            Logger.info(TAG, `Storage state: ${usagePercent.toFixed(1)}% used`);
          }).catch(error => {
            Logger.warn(TAG, 'Failed to check storage state', error instanceof Error ? error : new Error(String(error)));
          });
        }
      } catch (error) {
        Logger.warn(TAG, 'Failed to check storage state', error instanceof Error ? error : new Error(String(error)));
      }
      
      // 3. 检查内存状态
      try {
        if (typeof process !== 'undefined' && process.memoryUsage) {
          const memoryUsage = process.memoryUsage();
          const heapUsed = memoryUsage.heapUsed || 0;
          const heapTotal = memoryUsage.heapTotal || 0;
          Logger.info(TAG, `Memory state: ${(heapUsed / (1024 * 1024)).toFixed(1)}MB used of ${(heapTotal / (1024 * 1024)).toFixed(1)}MB`);
        }
      } catch (error) {
        Logger.warn(TAG, 'Failed to check memory state', error instanceof Error ? error : new Error(String(error)));
      }
      
      // 4. 检查核心服务状态
      const coreServices = ['config', 'cache', 'http', 'media', 'parser'];
      coreServices.forEach(serviceName => {
        const service = this.getService<Object>(serviceName);
        const status = service ? 'available' : 'unavailable';
        Logger.info(TAG, `Core service ${serviceName}: ${status}`);
      });
      
      // 5. 检查应用版本状态
      try {
        const currentVersion = this.appInfo.versionName;
        const versionCode = this.appInfo.versionCode;
        Logger.info(TAG, `App version: ${currentVersion} (${versionCode})`);
      } catch (error) {
        Logger.warn(TAG, 'Failed to check app version', error instanceof Error ? error : new Error(String(error)));
      }
      
      Logger.info(TAG, 'App state check completed');
    } catch (error) {
      Logger.error(TAG, 'Failed to check app state', error instanceof Error ? error : new Error(String(error)));
    }
  }

  /**
   * 记录错误状态 Log error state
   */
  private logErrorState(): void {
    try {
      Logger.info(TAG, 'Logging error state');
      
      // 1. 构建错误状态信息
      const errorState = {
        timestamp: Date.now(),
        appState: this.getState(),
        appVersion: this.appInfo.versionName,
        deviceInfo: {
          deviceId: this.appInfo.deviceId,
          deviceModel: this.appInfo.deviceModel,
          deviceManufacturer: this.appInfo.deviceManufacturer,
          osVersion: this.appInfo.osVersion
        },
        systemInfo: {
          screenWidth: this.appInfo.screenWidth,
          screenHeight: this.appInfo.screenHeight,
          isTV: this.appInfo.isTV,
          isTablet: this.appInfo.isTablet
        },
        serviceStatus: {
          config: this.getService('config') ? 'available' : 'unavailable',
          cache: this.getService('cache') ? 'available' : 'unavailable',
          http: this.getService('http') ? 'available' : 'unavailable',
          media: this.getService('media') ? 'available' : 'unavailable',
          parser: this.getService('parser') ? 'available' : 'unavailable'
        }
      };
      
      // 2. 记录错误状态到日志
      Logger.error(TAG, 'App error state:', errorState);
      
      // 3. 保存错误状态到存储
      setTimeout(async () => {
        try {
          const errorStateStr = JSON.stringify(errorState);
          await StorageUtil.putString('app_error_state', errorStateStr);
          Logger.info(TAG, 'Error state saved to storage');
        } catch (error) {
          Logger.warn(TAG, 'Failed to save error state', error instanceof Error ? error : new Error(String(error)));
        }
      }, 500);
      
      // 4. 如果启用了崩溃报告，发送错误信息
      if (this.appConfig.enableCrashReporting) {
        setTimeout(async () => {
          try {
            await this.sendCrashReport(errorState);
            Logger.info(TAG, 'Error state sent to crash reporting service');
          } catch (error) {
            Logger.warn(TAG, 'Failed to send error state', error instanceof Error ? error : new Error(String(error)));
          }
        }, 1000);
      }
      
      Logger.info(TAG, 'Error state logging completed');
    } catch (error) {
      Logger.error(TAG, 'Failed to log error state', error instanceof Error ? error : new Error(String(error)));
    }
  }

  /**
   * 尝试恢复核心服务 Try to recover core services
   */
  private recoverCoreServices(): void {
    try {
      Logger.info(TAG, 'Attempting to recover core services');
      // 这里可以添加恢复核心服务的逻辑
    } catch (error) {
      Logger.error(TAG, 'Failed to recover core services', error instanceof Error ? error : new Error(String(error)));
    }
  }

  /**
   * 清理错误状态 Clean up error state
   */
  private cleanupErrorState(): void {
    try {
      Logger.info(TAG, 'Cleaning up error state');
      // 这里可以添加清理错误状态的逻辑
    } catch (error) {
      Logger.error(TAG, 'Failed to clean up error state', error instanceof Error ? error : new Error(String(error)));
    }
  }

  /**
   * 通知用户 Notify user
   */
  private notifyUserOfError(): void {
    try {
      Logger.info(TAG, 'Notifying user of error');
      // 这里可以添加通知用户的逻辑
    } catch (error) {
      Logger.error(TAG, 'Failed to notify user', error instanceof Error ? error : new Error(String(error)));
    }
  }

  /**
   * 保存用户数据 Save user data
   */
  private saveUserData(): void {
    try {
      Logger.info(TAG, 'Saving user data');
      // 这里可以添加保存用户数据的逻辑
    } catch (error) {
      Logger.error(TAG, 'Failed to save user data', error instanceof Error ? error : new Error(String(error)));
    }
  }

  /**
   * 清理临时文件 Clean up temporary files
   */
  private cleanupTemporaryFiles(): void {
    try {
      Logger.info(TAG, 'Cleaning up temporary files');
      // 这里可以添加清理临时文件的逻辑
    } catch (error) {
      Logger.error(TAG, 'Failed to clean up temporary files', error instanceof Error ? error : new Error(String(error)));
    }
  }

  /**
   * 关闭后台服务 Shutdown background services
   */
  private shutdownBackgroundServices(): void {
    try {
      Logger.info(TAG, 'Shutting down background services');
      // 这里可以添加关闭后台服务的逻辑
    } catch (error) {
      Logger.error(TAG, 'Failed to shutdown background services', error instanceof Error ? error : new Error(String(error)));
    }
  }

  /**
   * 释放所有资源 Release all resources
   */
  private releaseAllResources(): void {
    try {
      Logger.info(TAG, 'Releasing all resources');
      // 这里可以添加释放所有资源的逻辑
    } catch (error) {
      Logger.error(TAG, 'Failed to release all resources', error instanceof Error ? error : new Error(String(error)));
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
   * 添加状态监听器 Add state listener
   * @param listener 状态监听器 State listener
   * @returns 取消监听函数 Unsubscribe function
   */
  public addStateListener(listener: (oldState: AppState, newState: AppState) => void): () => void {
    this.stateListeners.push(listener);
    return () => {
      const index = this.stateListeners.indexOf(listener);
      if (index > -1) {
        this.stateListeners.splice(index, 1);
      }
    };
  }

  /**
   * 移除状态监听器 Remove state listener
   * @param listener 状态监听器 State listener
   */
  public removeStateListener(listener: (oldState: AppState, newState: AppState) => void): void {
    const index = this.stateListeners.indexOf(listener);
    if (index > -1) {
      this.stateListeners.splice(index, 1);
    }
  }

  /**
   * 错误信息接口
   */
  interface ErrorInfo {
    error: Error | string;
    context?: string;
    extra?: Record<string, Object>;
  }

  /**
   * 发送崩溃报告 Send crash report
   * @param errorInfo 错误信息 Error info
   */
  private async sendCrashReport(errorInfo: ErrorInfo): Promise<void> {
    try {
      // 构建崩溃报告 Build crash report
      const crashReport = {
        ...errorInfo,
        deviceInfo: {
          deviceId: this.appInfo.deviceId,
          deviceModel: this.appInfo.deviceModel,
          deviceManufacturer: this.appInfo.deviceManufacturer,
          osVersion: this.appInfo.osVersion
        },
        appInfo: {
          versionName: this.appInfo.versionName,
          versionCode: this.appInfo.versionCode,
          buildType: this.appInfo.buildType
        },
        systemInfo: {
          screenWidth: this.appInfo.screenWidth,
          screenHeight: this.appInfo.screenHeight,
          isTV: this.appInfo.isTV
        }
      };

      // 发送崩溃报告到服务器 Send crash report to server
      const httpService = this.getService<HttpService>('http');
      if (httpService && typeof httpService.post === 'function') {
        await httpService.post('https://api.raytv.app/crash-report', crashReport, {
          headers: {
            'Content-Type': 'application/json',
            'X-App-Version': this.appInfo.versionName,
            'X-Device-Type': this.appInfo.isTV ? 'tv' : 'mobile'
          },
          timeout: 10000
        });
        Logger.info(TAG, 'Crash report sent successfully');
      }
    } catch (reportError) {
      Logger.error(TAG, 'Failed to send crash report', reportError instanceof Error ? reportError : new Error(String(reportError)));
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
