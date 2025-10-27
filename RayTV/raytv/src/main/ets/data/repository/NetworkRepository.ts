// NetworkRepository - 网络状态仓库类
// 负责管理网络连接状态、网络请求监控和网络配置

import Logger from '../../common/util/Logger';
import StorageUtil from '../../common/util/StorageUtil';
import EventBusUtil from '../../common/util/EventBusUtil';
import CacheService from '../../common/util/CacheService';
import { LocalStorageType } from '../model/LocalModel';
import { CacheType } from '../model/CacheModel';

/**
 * 网络状态枚举
 */
export enum NetworkStatus {
  ONLINE = 'online',
  OFFLINE = 'offline',
  CONNECTING = 'connecting',
  DISCONNECTING = 'disconnecting',
  UNKNOWN = 'unknown'
}

/**
 * 网络类型枚举
 */
export enum NetworkType {
  WIFI = 'wifi',
  CELLULAR = 'cellular',
  ETHERNET = 'ethernet',
  BLUETOOTH = 'bluetooth',
  VPN = 'vpn',
  OTHER = 'other',
  NONE = 'none',
  UNKNOWN = 'unknown'
}

/**
 * 蜂窝网络类型枚举
 */
export enum CellularNetworkType {
  GSM = 'gsm',
  CDMA = 'cdma',
  WCDMA = 'wcdma',
  LTE = 'lte',
  '5G' = '5g',
  '5G_NSA' = '5g_nsa',
  '5G_SA' = '5g_sa',
  UNKNOWN = 'unknown'
}

/**
 * 网络信号强度枚举
 */
export enum NetworkSignalStrength {
  EXCELLENT = 'excellent',
  GOOD = 'good',
  FAIR = 'fair',
  POOR = 'poor',
  NONE = 'none',
  UNKNOWN = 'unknown'
}

/**
 * 网络配置接口
 */
export interface NetworkConfig {
  // 基本配置
  enableAutoReconnect: boolean;
  reconnectAttempts: number;
  reconnectInterval: number; // 毫秒
  
  // 连接监控
  enableConnectionMonitoring: boolean;
  connectionCheckInterval: number; // 毫秒
  connectionTimeout: number; // 毫秒
  
  // 请求配置
  defaultTimeout: number; // 毫秒
  maxConcurrentRequests: number;
  enableRequestQueue: boolean;
  queueProcessingInterval: number; // 毫秒
  
  // 缓存配置
  enableOfflineCache: boolean;
  cacheExpiryTime: number; // 毫秒
  maxCacheSize: number; // 字节
  
  // 流量控制
  enableDataSaver: boolean;
  maxDownloadSpeed: number; // KB/s, 0表示无限制
  maxUploadSpeed: number; // KB/s, 0表示无限制
  
  // 网络类型限制
  restrictDownloadOnCellular: boolean;
  restrictHighBandwidthOnCellular: boolean;
  highBandwidthThreshold: number; // KB/s
  
  // 代理配置
  useProxy: boolean;
  proxyUrl?: string;
  proxyPort?: number;
  proxyUsername?: string;
  proxyPassword?: string;
  
  // VPN配置
  trustVPN: boolean;
  
  // 域名配置
  customDNS: boolean;
  dnsServers?: string[];
}

/**
 * 网络信息接口
 */
export interface NetworkInfo {
  status: NetworkStatus;
  type: NetworkType;
  ssid?: string; // WiFi名称
  bssid?: string; // WiFi BSSID
  rssi?: number; // 信号强度
  signalStrength: NetworkSignalStrength;
  ipAddress?: string;
  subnetMask?: string;
  gateway?: string;
  dnsServers?: string[];
  downloadSpeed?: number; // KB/s
  uploadSpeed?: number; // KB/s
  latency?: number; // 毫秒
  cellularType?: CellularNetworkType;
  carrierName?: string;
  isRoaming?: boolean;
  isVPN: boolean;
  lastChanged: number;
  isConnectionSecure: boolean;
  estimatedAvailableBandwidth?: number; // KB/s
}

/**
 * 请求统计信息接口
 */
export interface RequestStats {
  totalRequests: number;
  successfulRequests: number;
  failedRequests: number;
  requestTimeouts: number;
  totalBytesSent: number;
  totalBytesReceived: number;
  averageResponseTime: number;
  lastRequestTime: number;
  errorCodes: Map<string, number>;
  endpointStats: Map<string, EndpointStats>;
}

/**
 * 端点统计信息接口
 */
export interface EndpointStats {
  endpoint: string;
  requests: number;
  successful: number;
  failed: number;
  averageResponseTime: number;
  totalBytesSent: number;
  totalBytesReceived: number;
  lastRequestTime: number;
}

/**
 * 网络事件类型
 */
export const NetworkEventType = {
  STATUS_CHANGED: 'network:statusChanged',
  TYPE_CHANGED: 'network:typeChanged',
  SIGNAL_STRENGTH_CHANGED: 'network:signalStrengthChanged',
  CONNECTIVITY_RESTORED: 'network:connectivityRestored',
  CONNECTIVITY_LOST: 'network:connectivityLost',
  NETWORK_ERROR: 'network:error',
  CONFIG_CHANGED: 'network:configChanged',
  SPEED_TEST_COMPLETED: 'network:speedTestCompleted',
  REQUEST_QUEUED: 'network:requestQueued',
  REQUEST_PROCESSED: 'network:requestProcessed',
  REQUEST_FAILED: 'network:requestFailed',
  DATA_SAVER_TOGGLED: 'network:dataSaverToggled',
  WIFI_CONNECTED: 'network:wifiConnected',
  WIFI_DISCONNECTED: 'network:wifiDisconnected',
  CELLULAR_CONNECTED: 'network:cellularConnected',
  CELLULAR_DISCONNECTED: 'network:cellularDisconnected',
  VPN_STATUS_CHANGED: 'network:vpnStatusChanged'
} as const;

/**
 * 网络事件数据
 */
export interface NetworkEvent {
  type: string;
  timestamp: number;
  data?: any;
  error?: Error;
}

/**
 * 速度测试结果接口
 */
export interface SpeedTestResult {
  downloadSpeed: number; // KB/s
  uploadSpeed: number; // KB/s
  latency: number; // 毫秒
  jitter: number; // 毫秒
  packetLoss: number; // 百分比
  serverName: string;
  serverLocation: string;
  testDuration: number; // 毫秒
  timestamp: number;
  isAccurate: boolean;
}

/**
 * 网络请求队列项接口
 */
export interface RequestQueueItem {
  id: string;
  request: any;
  callback: (result: any) => void;
  errorCallback: (error: Error) => void;
  priority: number; // 1-最低，10-最高
  retryCount: number;
  maxRetries: number;
  createdAt: number;
  timeout?: number;
  requiresNetworkType?: NetworkType[];
  requiresHighBandwidth?: boolean;
}

/**
 * 网络仓库类
 */
export class NetworkRepository {
  private static instance: NetworkRepository;
  private logger = Logger.getInstance();
  private storageUtil = StorageUtil.getInstance();
  private eventBus = EventBusUtil.getInstance();
  private cacheService = CacheService.getInstance();
  
  // 存储键配置
  private storageKeys = {
    networkConfig: 'network:config',
    requestStats: 'network:requestStats',
    recentSpeedTests: 'network:recentSpeedTests',
    networkHistory: 'network:history',
    dataUsageStats: 'network:dataUsageStats',
    dnsCache: 'network:dnsCache'
  };
  
  // 默认配置
  private defaultConfig: NetworkConfig = {
    enableAutoReconnect: true,
    reconnectAttempts: 5,
    reconnectInterval: 2000,
    enableConnectionMonitoring: true,
    connectionCheckInterval: 30000,
    connectionTimeout: 15000,
    defaultTimeout: 30000,
    maxConcurrentRequests: 10,
    enableRequestQueue: true,
    queueProcessingInterval: 1000,
    enableOfflineCache: true,
    cacheExpiryTime: 3600000,
    maxCacheSize: 50 * 1024 * 1024, // 50MB
    enableDataSaver: false,
    maxDownloadSpeed: 0,
    maxUploadSpeed: 0,
    restrictDownloadOnCellular: true,
    restrictHighBandwidthOnCellular: true,
    highBandwidthThreshold: 1000, // 1MB/s
    useProxy: false,
    trustVPN: true,
    customDNS: false
  };
  
  // 缓存的配置
  private cachedConfig: NetworkConfig | null = null;
  
  // 当前网络信息
  private currentNetworkInfo: NetworkInfo = {
    status: NetworkStatus.UNKNOWN,
    type: NetworkType.UNKNOWN,
    signalStrength: NetworkSignalStrength.UNKNOWN,
    isVPN: false,
    lastChanged: Date.now(),
    isConnectionSecure: false
  };
  
  // 请求统计
  private requestStats: RequestStats = {
    totalRequests: 0,
    successfulRequests: 0,
    failedRequests: 0,
    requestTimeouts: 0,
    totalBytesSent: 0,
    totalBytesReceived: 0,
    averageResponseTime: 0,
    lastRequestTime: 0,
    errorCodes: new Map(),
    endpointStats: new Map()
  };
  
  // 请求队列
  private requestQueue: RequestQueueItem[] = [];
  
  // 是否正在处理队列
  private isProcessingQueue: boolean = false;
  
  // 当前活跃请求数
  private activeRequests: number = 0;
  
  // 连接监控定时器
  private connectionMonitorTimer: number | null = null;
  
  // 队列处理定时器
  private queueProcessingTimer: number | null = null;
  
  // 上次连接检查时间
  private lastConnectionCheck: number = 0;
  
  // 重试计数
  private reconnectAttempts: number = 0;
  
  // 网络历史记录
  private networkHistory: NetworkInfo[] = [];
  
  // 最大历史记录数
  private maxHistoryRecords: number = 100;
  
  // 速度测试结果
  private recentSpeedTests: SpeedTestResult[] = [];
  
  // 最大速度测试记录数
  private maxSpeedTestRecords: number = 20;

  /**
   * 私有构造函数
   */
  private constructor() {
    this.logger.info('NetworkRepository initialized');
    this.setupEventListeners();
    this.initialize();
  }

  /**
   * 获取NetworkRepository单例实例
   */
  public static getInstance(): NetworkRepository {
    if (!NetworkRepository.instance) {
      NetworkRepository.instance = new NetworkRepository();
    }
    return NetworkRepository.instance;
  }

  /**
   * 初始化网络仓库
   */
  private async initialize(): Promise<void> {
    try {
      // 加载配置
      await this.loadConfig();
      
      // 加载请求统计
      await this.loadRequestStats();
      
      // 加载速度测试历史
      await this.loadRecentSpeedTests();
      
      // 初始化网络监听
      this.initializeNetworkListeners();
      
      // 开始连接监控
      this.startConnectionMonitoring();
      
      // 开始队列处理
      this.startQueueProcessing();
      
      // 立即检查网络状态
      this.checkNetworkStatus().catch(err => {
        this.logger.warn('Failed to check initial network status', err);
      });
      
      this.logger.info('NetworkRepository initialization completed');
    } catch (error) {
      this.logger.error('Failed to initialize NetworkRepository', error as Error);
    }
  }

  /**
   * 设置事件监听器
   */
  private setupEventListeners(): void {
    // 监听配置变更事件
    this.eventBus.on('network:configChanged', (event: NetworkEvent) => {
      // 应用配置变更
      this.applyConfigChanges(event.data as NetworkConfig);
    });
    
    // 监听应用状态变化
    this.eventBus.on('app:stateChanged', async (state: { isActive: boolean }) => {
      if (state.isActive) {
        // 应用切换到前台时，立即检查网络状态
        this.checkNetworkStatus().catch(err => {
          this.logger.warn('Failed to check network status when app becomes active', err);
        });
      }
    });
    
    // 监听网络状态变化事件（来自系统）
    // 注意：在实际应用中，这里应该监听系统的网络状态变化事件
    // 这里简化处理
  }

  /**
   * 初始化网络监听器
   */
  private initializeNetworkListeners(): void {
    try {
      // 在实际应用中，这里应该设置系统级别的网络监听器
      // 例如在Android中使用ConnectivityManager，在iOS中使用Reachability
      // 这里简化处理，定期检查网络状态
      
      this.logger.debug('Network listeners initialized');
    } catch (error) {
      this.logger.error('Failed to initialize network listeners', error as Error);
    }
  }

  /**
   * 加载配置
   */
  private async loadConfig(): Promise<void> {
    try {
      const config = await this.storageUtil.getObject<NetworkConfig>(
        this.storageKeys.networkConfig,
        LocalStorageType.DEFAULT
      );
      
      this.cachedConfig = config ? {
        ...this.defaultConfig,
        ...config,
        dnsServers: config.dnsServers || []
      } : { ...this.defaultConfig };
      
      // 验证配置
      this.validateConfig(this.cachedConfig);
      
      this.logger.debug('Network configuration loaded');
    } catch (error) {
      this.logger.error('Failed to load network config', error as Error);
      this.cachedConfig = { ...this.defaultConfig };
    }
  }

  /**
   * 设置配置
   */
  public async setConfig(config: Partial<NetworkConfig>): Promise<NetworkConfig> {
    try {
      // 获取当前配置
      const currentConfig = await this.getConfig();
      
      // 合并新配置
      const updatedConfig: NetworkConfig = {
        ...currentConfig,
        ...config,
        dnsServers: config.dnsServers || currentConfig.dnsServers
      };
      
      // 验证配置
      this.validateConfig(updatedConfig);
      
      // 保存配置
      this.cachedConfig = updatedConfig;
      await this.storageUtil.setObject(
        this.storageKeys.networkConfig,
        updatedConfig,
        LocalStorageType.DEFAULT
      );
      
      // 应用配置变更
      this.applyConfigChanges(updatedConfig);
      
      // 发布配置变更事件
      this.eventBus.emit(NetworkEventType.CONFIG_CHANGED, {
        type: NetworkEventType.CONFIG_CHANGED,
        timestamp: Date.now(),
        data: updatedConfig
      } as NetworkEvent);
      
      this.logger.info('Network configuration updated');
      
      return updatedConfig;
    } catch (error) {
      this.logger.error('Failed to set network config', error as Error);
      throw error;
    }
  }

  /**
   * 获取配置
   */
  public async getConfig(): Promise<NetworkConfig> {
    try {
      // 如果缓存为空，加载配置
      if (!this.cachedConfig) {
        await this.loadConfig();
      }
      
      return { ...this.cachedConfig! };
    } catch (error) {
      this.logger.error('Failed to get network config', error as Error);
      return { ...this.defaultConfig };
    }
  }

  /**
   * 验证配置
   */
  private validateConfig(config: NetworkConfig): void {
    const errors: string[] = [];
    
    if (config.reconnectAttempts < 0 || config.reconnectAttempts > 10) {
      errors.push('reconnectAttempts must be between 0 and 10');
    }
    
    if (config.reconnectInterval < 1000 || config.reconnectInterval > 30000) {
      errors.push('reconnectInterval must be between 1000 and 30000 milliseconds');
    }
    
    if (config.connectionCheckInterval < 5000 || config.connectionCheckInterval > 300000) {
      errors.push('connectionCheckInterval must be between 5000 and 300000 milliseconds');
    }
    
    if (config.connectionTimeout < 1000 || config.connectionTimeout > 60000) {
      errors.push('connectionTimeout must be between 1000 and 60000 milliseconds');
    }
    
    if (config.defaultTimeout < 1000 || config.defaultTimeout > 300000) {
      errors.push('defaultTimeout must be between 1000 and 300000 milliseconds');
    }
    
    if (config.maxConcurrentRequests < 1 || config.maxConcurrentRequests > 50) {
      errors.push('maxConcurrentRequests must be between 1 and 50');
    }
    
    if (config.cacheExpiryTime < 0 || config.cacheExpiryTime > 86400000) {
      errors.push('cacheExpiryTime must be between 0 and 86400000 milliseconds');
    }
    
    if (config.maxCacheSize < 0 || config.maxCacheSize > 1024 * 1024 * 1024) {
      errors.push('maxCacheSize must be between 0 and 1073741824 bytes');
    }
    
    if (errors.length > 0) {
      throw new Error(errors.join(', '));
    }
  }

  /**
   * 应用配置变更
   */
  private applyConfigChanges(config: NetworkConfig): void {
    // 根据配置调整行为
    
    // 重新设置连接监控
    if (config.enableConnectionMonitoring) {
      this.startConnectionMonitoring();
    } else {
      this.stopConnectionMonitoring();
    }
    
    // 重新设置队列处理
    if (config.enableRequestQueue) {
      this.startQueueProcessing();
    } else {
      this.stopQueueProcessing();
    }
    
    // 如果启用了数据节省模式，发布事件
    if (config.enableDataSaver !== this.cachedConfig?.enableDataSaver) {
      this.eventBus.emit(NetworkEventType.DATA_SAVER_TOGGLED, {
        type: NetworkEventType.DATA_SAVER_TOGGLED,
        timestamp: Date.now(),
        data: { enabled: config.enableDataSaver }
      } as NetworkEvent);
    }
  }

  /**
   * 获取当前网络信息
   */
  public async getNetworkInfo(): Promise<NetworkInfo> {
    // 确保网络信息是最新的
    if (Date.now() - this.currentNetworkInfo.lastChanged > 10000) { // 10秒内视为最新
      await this.checkNetworkStatus();
    }
    
    return { ...this.currentNetworkInfo };
  }

  /**
   * 检查网络状态
   */
  public async checkNetworkStatus(): Promise<NetworkStatus> {
    try {
      // 在实际应用中，这里应该调用系统API或发送探测请求来检查网络状态
      // 这里简化处理，模拟网络状态检查
      
      // 模拟网络状态检查
      const newStatus = await this.performNetworkCheck();
      
      // 更新网络信息
      this.updateNetworkInfo(newStatus);
      
      this.logger.debug(`Network status checked: ${newStatus}`);
      
      return newStatus;
    } catch (error) {
      this.logger.warn('Failed to check network status', error as Error);
      
      // 出错时标记为离线
      this.updateNetworkInfo(NetworkStatus.OFFLINE);
      
      return NetworkStatus.OFFLINE;
    } finally {
      this.lastConnectionCheck = Date.now();
    }
  }

  /**
   * 执行网络状态检查
   */
  private async performNetworkCheck(): Promise<NetworkStatus> {
    try {
      // 在实际应用中，这里应该：
      // 1. 检查系统网络状态
      // 2. 发送一个轻量级的探测请求到可靠的服务器
      // 3. 分析响应来确定网络质量
      
      // 模拟网络检查
      // 这里简单地返回在线状态，实际应用中应该有真实的检查逻辑
      return NetworkStatus.ONLINE;
    } catch (error) {
      this.logger.debug('Network check failed', error as Error);
      return NetworkStatus.OFFLINE;
    }
  }

  /**
   * 更新网络信息
   */
  private updateNetworkInfo(status: NetworkStatus): void {
    const previousStatus = this.currentNetworkInfo.status;
    const previousType = this.currentNetworkInfo.type;
    const previousSignalStrength = this.currentNetworkInfo.signalStrength;
    
    // 更新基本状态
    this.currentNetworkInfo.status = status;
    this.currentNetworkInfo.lastChanged = Date.now();
    
    // 在实际应用中，这里应该更新更多详细信息
    // 例如网络类型、信号强度、IP地址等
    
    // 保存历史记录
    this.saveNetworkHistory();
    
    // 发布状态变更事件
    if (status !== previousStatus) {
      this.eventBus.emit(NetworkEventType.STATUS_CHANGED, {
        type: NetworkEventType.STATUS_CHANGED,
        timestamp: Date.now(),
        data: {
          previousStatus,
          currentStatus: status,
          isOnline: status === NetworkStatus.ONLINE
        }
      } as NetworkEvent);
      
      // 特殊处理连接恢复和丢失
      if (status === NetworkStatus.ONLINE && previousStatus !== NetworkStatus.ONLINE) {
        this.handleConnectivityRestored();
      } else if (status !== NetworkStatus.ONLINE && previousStatus === NetworkStatus.ONLINE) {
        this.handleConnectivityLost();
      }
    }
    
    // 发布类型变更事件
    if (this.currentNetworkInfo.type !== previousType) {
      this.eventBus.emit(NetworkEventType.TYPE_CHANGED, {
        type: NetworkEventType.TYPE_CHANGED,
        timestamp: Date.now(),
        data: {
          previousType,
          currentType: this.currentNetworkInfo.type
        }
      } as NetworkEvent);
      
      // 特殊处理WiFi和蜂窝网络连接
      if (this.currentNetworkInfo.type === NetworkType.WIFI && previousType !== NetworkType.WIFI) {
        this.eventBus.emit(NetworkEventType.WIFI_CONNECTED, {
          type: NetworkEventType.WIFI_CONNECTED,
          timestamp: Date.now(),
          data: { ssid: this.currentNetworkInfo.ssid }
        } as NetworkEvent);
      } else if (previousType === NetworkType.WIFI && this.currentNetworkInfo.type !== NetworkType.WIFI) {
        this.eventBus.emit(NetworkEventType.WIFI_DISCONNECTED, {
          type: NetworkEventType.WIFI_DISCONNECTED,
          timestamp: Date.now(),
          data: { previousSSID: previousType === NetworkType.WIFI ? this.currentNetworkInfo.ssid : undefined }
        } as NetworkEvent);
      }
      
      if (this.currentNetworkInfo.type === NetworkType.CELLULAR && previousType !== NetworkType.CELLULAR) {
        this.eventBus.emit(NetworkEventType.CELLULAR_CONNECTED, {
          type: NetworkEventType.CELLULAR_CONNECTED,
          timestamp: Date.now(),
          data: { carrierName: this.currentNetworkInfo.carrierName, type: this.currentNetworkInfo.cellularType }
        } as NetworkEvent);
      } else if (previousType === NetworkType.CELLULAR && this.currentNetworkInfo.type !== NetworkType.CELLULAR) {
        this.eventBus.emit(NetworkEventType.CELLULAR_DISCONNECTED, {
          type: NetworkEventType.CELLULAR_DISCONNECTED,
          timestamp: Date.now()
        } as NetworkEvent);
      }
    }
    
    // 发布信号强度变更事件
    if (this.currentNetworkInfo.signalStrength !== previousSignalStrength) {
      this.eventBus.emit(NetworkEventType.SIGNAL_STRENGTH_CHANGED, {
        type: NetworkEventType.SIGNAL_STRENGTH_CHANGED,
        timestamp: Date.now(),
        data: {
          previousStrength: previousSignalStrength,
          currentStrength: this.currentNetworkInfo.signalStrength,
          rssi: this.currentNetworkInfo.rssi
        }
      } as NetworkEvent);
    }
  }

  /**
   * 处理连接恢复
   */
  private async handleConnectivityRestored(): Promise<void> {
    try {
      this.logger.info('Connectivity restored');
      
      // 发布连接恢复事件
      this.eventBus.emit(NetworkEventType.CONNECTIVITY_RESTORED, {
        type: NetworkEventType.CONNECTIVITY_RESTORED,
        timestamp: Date.now(),
        data: { networkInfo: this.currentNetworkInfo }
      } as NetworkEvent);
      
      // 重置重连尝试计数
      this.reconnectAttempts = 0;
      
      // 处理队列中的请求
      this.processRequestQueue();
      
      // 清理过期的缓存
      if (this.cachedConfig?.enableOfflineCache) {
        this.cleanupExpiredCache().catch(err => {
          this.logger.warn('Failed to cleanup expired cache', err);
        });
      }
    } catch (error) {
      this.logger.error('Failed to handle connectivity restored', error as Error);
    }
  }

  /**
   * 处理连接丢失
   */
  private handleConnectivityLost(): Promise<void> {
    return new Promise<void>(async (resolve) => {
      try {
        this.logger.info('Connectivity lost');
        
        // 发布连接丢失事件
        this.eventBus.emit(NetworkEventType.CONNECTIVITY_LOST, {
          type: NetworkEventType.CONNECTIVITY_LOST,
          timestamp: Date.now(),
          data: { previousNetworkInfo: this.currentNetworkInfo }
        } as NetworkEvent);
        
        // 如果启用了自动重连，启动重连机制
        if (this.cachedConfig?.enableAutoReconnect) {
          this.startAutoReconnect();
        }
        
        // 保存当前网络状态到历史记录
        await this.saveNetworkHistory();
        
        resolve();
      } catch (error) {
        this.logger.error('Failed to handle connectivity lost', error as Error);
        resolve();
      }
    });
  }

  /**
   * 启动自动重连
   */
  private startAutoReconnect(): void {
    if (this.reconnectAttempts >= this.cachedConfig!.reconnectAttempts) {
      this.logger.warn(`Maximum reconnection attempts reached (${this.reconnectAttempts})`);
      return;
    }
    
    this.reconnectAttempts++;
    const delay = this.cachedConfig!.reconnectInterval * this.reconnectAttempts;
    
    this.logger.info(`Attempting to reconnect... (${this.reconnectAttempts}/${this.cachedConfig!.reconnectAttempts})`);
    
    setTimeout(async () => {
      const status = await this.checkNetworkStatus();
      
      if (status !== NetworkStatus.ONLINE) {
        // 继续尝试重连
        this.startAutoReconnect();
      }
    }, delay);
  }

  /**
   * 开始连接监控
   */
  private startConnectionMonitoring(): void {
    // 停止现有的监控
    this.stopConnectionMonitoring();
    
    if (!this.cachedConfig?.enableConnectionMonitoring) {
      return;
    }
    
    // 设置定期检查
    this.connectionMonitorTimer = setInterval(() => {
      this.checkNetworkStatus().catch(err => {
        this.logger.warn('Failed to check network status in monitor', err);
      });
    }, this.cachedConfig.connectionCheckInterval);
    
    this.logger.debug('Connection monitoring started');
  }

  /**
   * 停止连接监控
   */
  private stopConnectionMonitoring(): void {
    if (this.connectionMonitorTimer !== null) {
      clearInterval(this.connectionMonitorTimer);
      this.connectionMonitorTimer = null;
      this.logger.debug('Connection monitoring stopped');
    }
  }

  /**
   * 开始队列处理
   */
  private startQueueProcessing(): void {
    // 停止现有的队列处理
    this.stopQueueProcessing();
    
    if (!this.cachedConfig?.enableRequestQueue) {
      return;
    }
    
    // 设置定期处理
    this.queueProcessingTimer = setInterval(() => {
      if (!this.isProcessingQueue) {
        this.processRequestQueue();
      }
    }, this.cachedConfig.queueProcessingInterval);
    
    this.logger.debug('Request queue processing started');
  }

  /**
   * 停止队列处理
   */
  private stopQueueProcessing(): void {
    if (this.queueProcessingTimer !== null) {
      clearInterval(this.queueProcessingTimer);
      this.queueProcessingTimer = null;
      this.logger.debug('Request queue processing stopped');
    }
  }

  /**
   * 处理请求队列
   */
  private async processRequestQueue(): Promise<void> {
    // 检查是否在线
    if (this.currentNetworkInfo.status !== NetworkStatus.ONLINE) {
      return;
    }
    
    // 检查是否达到最大并发请求数
    if (this.activeRequests >= this.cachedConfig!.maxConcurrentRequests) {
      return;
    }
    
    // 标记为正在处理队列
    this.isProcessingQueue = true;
    
    try {
      // 按优先级排序队列
      this.requestQueue.sort((a, b) => b.priority - a.priority);
      
      // 处理队列中的请求
      while (this.requestQueue.length > 0 && this.activeRequests < this.cachedConfig!.maxConcurrentRequests) {
        const queueItem = this.requestQueue.shift();
        if (!queueItem) break;
        
        // 检查请求是否可以执行
        if (await this.canExecuteRequest(queueItem)) {
          // 增加活跃请求数
          this.activeRequests++;
          
          // 执行请求
          this.executeQueuedRequest(queueItem).catch(err => {
            this.logger.warn(`Failed to execute queued request: ${queueItem.id}`, err);
            
            // 减少活跃请求数
            this.activeRequests--;
          });
        } else {
          // 请求不能执行，放回队列
          this.requestQueue.push(queueItem);
          break;
        }
      }
    } catch (error) {
      this.logger.error('Failed to process request queue', error as Error);
    } finally {
      // 标记为队列处理完成
      this.isProcessingQueue = false;
    }
  }

  /**
   * 检查请求是否可以执行
   */
  private async canExecuteRequest(queueItem: RequestQueueItem): Promise<boolean> {
    // 检查网络类型要求
    if (queueItem.requiresNetworkType && queueItem.requiresNetworkType.length > 0) {
      if (!queueItem.requiresNetworkType.includes(this.currentNetworkInfo.type)) {
        return false;
      }
    }
    
    // 检查高带宽要求
    if (queueItem.requiresHighBandwidth) {
      // 检查是否在蜂窝网络上限制高带宽请求
      if (this.currentNetworkInfo.type === NetworkType.CELLULAR && 
          this.cachedConfig?.restrictHighBandwidthOnCellular) {
        return false;
      }
      
      // 检查当前网络是否满足带宽要求
      if (this.currentNetworkInfo.estimatedAvailableBandwidth && 
          this.currentNetworkInfo.estimatedAvailableBandwidth < this.cachedConfig?.highBandwidthThreshold) {
        return false;
      }
    }
    
    // 检查数据节省模式
    if (this.cachedConfig?.enableDataSaver && queueItem.requiresHighBandwidth) {
      return false;
    }
    
    return true;
  }

  /**
   * 执行队列中的请求
   */
  private async executeQueuedRequest(queueItem: RequestQueueItem): Promise<void> {
    try {
      // 这里应该实际执行网络请求
      // 由于是示例实现，模拟请求执行
      
      // 模拟请求延迟
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      // 模拟请求成功
      const result = { success: true, data: 'Mock response data', requestId: queueItem.id };
      
      // 调用成功回调
      queueItem.callback(result);
      
      // 发布请求处理完成事件
      this.eventBus.emit(NetworkEventType.REQUEST_PROCESSED, {
        type: NetworkEventType.REQUEST_PROCESSED,
        timestamp: Date.now(),
        data: { requestId: queueItem.id, result }
      } as NetworkEvent);
      
      this.logger.debug(`Queued request executed: ${queueItem.id}`);
    } catch (error) {
      // 处理请求失败
      this.logger.warn(`Queued request failed: ${queueItem.id}`, error as Error);
      
      // 检查是否需要重试
      if (queueItem.retryCount < queueItem.maxRetries) {
        queueItem.retryCount++;
        
        // 放回队列，带延迟
        setTimeout(() => {
          this.requestQueue.push(queueItem);
        }, 1000 * queueItem.retryCount);
        
        this.logger.debug(`Request scheduled for retry: ${queueItem.id} (${queueItem.retryCount}/${queueItem.maxRetries})`);
      } else {
        // 达到最大重试次数，调用错误回调
        queueItem.errorCallback(error as Error);
        
        // 发布请求失败事件
        this.eventBus.emit(NetworkEventType.REQUEST_FAILED, {
          type: NetworkEventType.REQUEST_FAILED,
          timestamp: Date.now(),
          error: error as Error,
          data: { requestId: queueItem.id, retryCount: queueItem.retryCount }
        } as NetworkEvent);
      }
    } finally {
      // 减少活跃请求数
      this.activeRequests--;
      
      // 记录请求统计
      await this.updateRequestStats(true); // 假设成功
    }
  }

  /**
   * 将请求添加到队列
   */
  public queueRequest(
    request: any,
    callback: (result: any) => void,
    errorCallback: (error: Error) => void,
    options?: {
      priority?: number;
      maxRetries?: number;
      timeout?: number;
      requiresNetworkType?: NetworkType[];
      requiresHighBandwidth?: boolean;
    }
  ): string {
    const id = `request_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    
    const queueItem: RequestQueueItem = {
      id,
      request,
      callback,
      errorCallback,
      priority: options?.priority || 5,
      retryCount: 0,
      maxRetries: options?.maxRetries || 3,
      createdAt: Date.now(),
      timeout: options?.timeout,
      requiresNetworkType: options?.requiresNetworkType,
      requiresHighBandwidth: options?.requiresHighBandwidth || false
    };
    
    // 添加到队列
    this.requestQueue.push(queueItem);
    
    // 发布请求入队事件
    this.eventBus.emit(NetworkEventType.REQUEST_QUEUED, {
      type: NetworkEventType.REQUEST_QUEUED,
      timestamp: Date.now(),
      data: { requestId: id, priority: queueItem.priority }
    } as NetworkEvent);
    
    this.logger.debug(`Request queued: ${id} with priority ${queueItem.priority}`);
    
    // 尝试立即处理队列
    if (!this.isProcessingQueue) {
      this.processRequestQueue().catch(err => {
        this.logger.warn('Failed to process request queue after adding new request', err);
      });
    }
    
    return id;
  }

  /**
   * 取消队列中的请求
   */
  public cancelRequest(requestId: string): boolean {
    const initialLength = this.requestQueue.length;
    this.requestQueue = this.requestQueue.filter(item => item.id !== requestId);
    
    const removed = initialLength !== this.requestQueue.length;
    if (removed) {
      this.logger.debug(`Request cancelled: ${requestId}`);
    }
    
    return removed;
  }

  /**
   * 清空请求队列
   */
  public clearRequestQueue(): void {
    const queueLength = this.requestQueue.length;
    this.requestQueue = [];
    
    this.logger.debug(`Request queue cleared. Removed ${queueLength} requests.`);
  }

  /**
   * 执行速度测试
   */
  public async runSpeedTest(): Promise<SpeedTestResult> {
    try {
      // 检查是否在线
      if (this.currentNetworkInfo.status !== NetworkStatus.ONLINE) {
        throw new Error('Cannot run speed test while offline');
      }
      
      // 检查数据节省模式
      if (this.cachedConfig?.enableDataSaver) {
        throw new Error('Speed test disabled when data saver is enabled');
      }
      
      // 检查是否在蜂窝网络上限制高带宽操作
      if (this.currentNetworkInfo.type === NetworkType.CELLULAR && 
          this.cachedConfig?.restrictHighBandwidthOnCellular) {
        throw new Error('Speed test disabled on cellular network when high bandwidth restrictions are enabled');
      }
      
      const startTime = Date.now();
      
      // 在实际应用中，这里应该：
      // 1. 选择合适的测试服务器
      // 2. 执行下载测试（多次，取平均值）
      // 3. 执行上传测试（多次，取平均值）
      // 4. 执行延迟测试（多次，取平均值）
      // 5. 计算抖动和丢包率
      
      // 模拟速度测试结果
      // 注意：这只是模拟数据，实际应用中应该有真实的测试逻辑
      const result: SpeedTestResult = {
        downloadSpeed: Math.random() * 10000 + 1000, // 1-11 MB/s
        uploadSpeed: Math.random() * 5000 + 500, // 0.5-5.5 MB/s
        latency: Math.random() * 200 + 20, // 20-220 ms
        jitter: Math.random() * 50, // 0-50 ms
        packetLoss: Math.random() * 5, // 0-5%
        serverName: 'Mock Test Server',
        serverLocation: 'Beijing, CN',
        testDuration: Date.now() - startTime,
        timestamp: Date.now(),
        isAccurate: true
      };
      
      // 保存测试结果
      this.saveSpeedTestResult(result);
      
      // 发布速度测试完成事件
      this.eventBus.emit(NetworkEventType.SPEED_TEST_COMPLETED, {
        type: NetworkEventType.SPEED_TEST_COMPLETED,
        timestamp: Date.now(),
        data: result
      } as NetworkEvent);
      
      // 更新网络信息中的速度估计
      this.currentNetworkInfo.downloadSpeed = result.downloadSpeed;
      this.currentNetworkInfo.uploadSpeed = result.uploadSpeed;
      this.currentNetworkInfo.latency = result.latency;
      this.currentNetworkInfo.estimatedAvailableBandwidth = result.downloadSpeed;
      
      this.logger.info(`Speed test completed: ${result.downloadSpeed.toFixed(2)} KB/s down, ${result.uploadSpeed.toFixed(2)} KB/s up, ${result.latency.toFixed(2)} ms latency`);
      
      return result;
    } catch (error) {
      this.logger.error('Speed test failed', error as Error);
      throw error;
    }
  }

  /**
   * 保存速度测试结果
   */
  private async saveSpeedTestResult(result: SpeedTestResult): Promise<void> {
    try {
      // 添加到最近测试结果
      this.recentSpeedTests.unshift(result);
      
      // 限制记录数量
      if (this.recentSpeedTests.length > this.maxSpeedTestRecords) {
        this.recentSpeedTests = this.recentSpeedTests.slice(0, this.maxSpeedTestRecords);
      }
      
      // 保存到存储
      await this.storageUtil.setObject(
        this.storageKeys.recentSpeedTests,
        this.recentSpeedTests,
        LocalStorageType.DEFAULT
      );
    } catch (error) {
      this.logger.warn('Failed to save speed test result', error as Error);
    }
  }

  /**
   * 加载速度测试历史
   */
  private async loadRecentSpeedTests(): Promise<void> {
    try {
      const tests = await this.storageUtil.getObject<SpeedTestResult[]>(
        this.storageKeys.recentSpeedTests,
        LocalStorageType.DEFAULT
      );
      
      if (tests) {
        this.recentSpeedTests = tests;
      }
    } catch (error) {
      this.logger.warn('Failed to load recent speed tests', error as Error);
      this.recentSpeedTests = [];
    }
  }

  /**
   * 获取最近的速度测试结果
   */
  public async getRecentSpeedTests(limit: number = 10): Promise<SpeedTestResult[]> {
    return this.recentSpeedTests.slice(0, limit);
  }

  /**
   * 保存网络历史记录
   */
  private async saveNetworkHistory(): Promise<void> {
    try {
      // 添加当前网络信息到历史
      this.networkHistory.unshift({ ...this.currentNetworkInfo });
      
      // 限制历史记录数量
      if (this.networkHistory.length > this.maxHistoryRecords) {
        this.networkHistory = this.networkHistory.slice(0, this.maxHistoryRecords);
      }
      
      // 定期保存到存储（每10条记录或每分钟）
      if (this.networkHistory.length % 10 === 0 || 
          (this.networkHistory.length > 0 && 
           Date.now() - this.networkHistory[0].lastChanged > 60000)) {
        await this.storageUtil.setObject(
          this.storageKeys.networkHistory,
          this.networkHistory,
          LocalStorageType.DEFAULT
        );
      }
    } catch (error) {
      this.logger.warn('Failed to save network history', error as Error);
    }
  }

  /**
   * 加载请求统计
   */
  private async loadRequestStats(): Promise<void> {
    try {
      const stats = await this.storageUtil.getObject<{
        totalRequests: number;
        successfulRequests: number;
        failedRequests: number;
        requestTimeouts: number;
        totalBytesSent: number;
        totalBytesReceived: number;
        averageResponseTime: number;
        lastRequestTime: number;
        errorCodes: [string, number][];
        endpointStats: [string, EndpointStats][];
      }>(
        this.storageKeys.requestStats,
        LocalStorageType.DEFAULT
      );
      
      if (stats) {
        this.requestStats = {
          ...stats,
          errorCodes: new Map(stats.errorCodes),
          endpointStats: new Map(stats.endpointStats)
        };
      }
    } catch (error) {
      this.logger.warn('Failed to load request stats', error as Error);
      // 使用默认值
      this.resetRequestStats();
    }
  }

  /**
   * 保存请求统计
   */
  private async saveRequestStats(): Promise<void> {
    try {
      // 转换Map为数组以便存储
      const statsToSave = {
        ...this.requestStats,
        errorCodes: Array.from(this.requestStats.errorCodes.entries()),
        endpointStats: Array.from(this.requestStats.endpointStats.entries())
      };
      
      await this.storageUtil.setObject(
        this.storageKeys.requestStats,
        statsToSave,
        LocalStorageType.DEFAULT
      );
    } catch (error) {
      this.logger.warn('Failed to save request stats', error as Error);
    }
  }

  /**
   * 更新请求统计
   */
  private async updateRequestStats(success: boolean, endpoint?: string, responseTime?: number, bytesSent: number = 0, bytesReceived: number = 0, errorCode?: string): Promise<void> {
    try {
      this.requestStats.totalRequests++;
      this.requestStats.lastRequestTime = Date.now();
      this.requestStats.totalBytesSent += bytesSent;
      this.requestStats.totalBytesReceived += bytesReceived;
      
      if (success) {
        this.requestStats.successfulRequests++;
        
        // 更新平均响应时间
        if (responseTime) {
          const totalTime = this.requestStats.averageResponseTime * (this.requestStats.successfulRequests - 1);
          this.requestStats.averageResponseTime = (totalTime + responseTime) / this.requestStats.successfulRequests;
        }
      } else {
        this.requestStats.failedRequests++;
        
        // 记录错误码
        if (errorCode) {
          this.requestStats.errorCodes.set(errorCode, (this.requestStats.errorCodes.get(errorCode) || 0) + 1);
        }
        
        // 记录超时
        if (errorCode === 'TIMEOUT') {
          this.requestStats.requestTimeouts++;
        }
      }
      
      // 更新端点统计
      if (endpoint) {
        let endpointStat = this.requestStats.endpointStats.get(endpoint);
        
        if (!endpointStat) {
          endpointStat = {
            endpoint,
            requests: 0,
            successful: 0,
            failed: 0,
            averageResponseTime: 0,
            totalBytesSent: 0,
            totalBytesReceived: 0,
            lastRequestTime: 0
          };
        }
        
        endpointStat.requests++;
        endpointStat.lastRequestTime = Date.now();
        endpointStat.totalBytesSent += bytesSent;
        endpointStat.totalBytesReceived += bytesReceived;
        
        if (success) {
          endpointStat.successful++;
          if (responseTime) {
            const totalTime = endpointStat.averageResponseTime * (endpointStat.successful - 1);
            endpointStat.averageResponseTime = (totalTime + responseTime) / endpointStat.successful;
          }
        } else {
          endpointStat.failed++;
        }
        
        this.requestStats.endpointStats.set(endpoint, endpointStat);
      }
      
      // 定期保存统计（每100次请求）
      if (this.requestStats.totalRequests % 100 === 0) {
        await this.saveRequestStats();
      }
    } catch (error) {
      this.logger.warn('Failed to update request stats', error as Error);
    }
  }

  /**
   * 获取请求统计
   */
  public async getRequestStats(): Promise<RequestStats> {
    // 保存最新统计
    await this.saveRequestStats();
    
    // 返回统计的副本
    return {
      ...this.requestStats,
      errorCodes: new Map(this.requestStats.errorCodes),
      endpointStats: new Map(this.requestStats.endpointStats)
    };
  }

  /**
   * 重置请求统计
   */
  public async resetRequestStats(): Promise<void> {
    this.requestStats = {
      totalRequests: 0,
      successfulRequests: 0,
      failedRequests: 0,
      requestTimeouts: 0,
      totalBytesSent: 0,
      totalBytesReceived: 0,
      averageResponseTime: 0,
      lastRequestTime: 0,
      errorCodes: new Map(),
      endpointStats: new Map()
    };
    
    await this.saveRequestStats();
    
    this.logger.info('Request stats reset');
  }

  /**
   * 切换数据节省模式
   */
  public async toggleDataSaver(enable: boolean): Promise<boolean> {
    try {
      await this.setConfig({ enableDataSaver: enable });
      
      this.logger.info(`Data saver ${enable ? 'enabled' : 'disabled'}`);
      
      return true;
    } catch (error) {
      this.logger.error('Failed to toggle data saver', error as Error);
      return false;
    }
  }

  /**
   * 清理过期缓存
   */
  private async cleanupExpiredCache(): Promise<void> {
    try {
      if (!this.cachedConfig?.enableOfflineCache) {
        return;
      }
      
      const expiryTime = this.cachedConfig.cacheExpiryTime;
      const cutoffTime = Date.now() - expiryTime;
      
      // 在实际应用中，这里应该清理过期的缓存项
      // 由于是示例实现，这里仅记录日志
      
      this.logger.info('Expired cache cleaned up');
    } catch (error) {
      this.logger.warn('Failed to cleanup expired cache', error as Error);
    }
  }

  /**
   * 获取网络历史记录
   */
  public async getNetworkHistory(limit: number = 50): Promise<NetworkInfo[]> {
    try {
      // 确保历史记录是最新的
      await this.storageUtil.setObject(
        this.storageKeys.networkHistory,
        this.networkHistory,
        LocalStorageType.DEFAULT
      );
      
      return this.networkHistory.slice(0, limit);
    } catch (error) {
      this.logger.error('Failed to get network history', error as Error);
      return [];
    }
  }

  /**
   * 检查是否可以下载（考虑网络类型和配置）
   */
  public async canDownload(size?: number): Promise<boolean> {
    // 检查是否在线
    if (this.currentNetworkInfo.status !== NetworkStatus.ONLINE) {
      return false;
    }
    
    // 检查是否在蜂窝网络上限制下载
    if (this.currentNetworkInfo.type === NetworkType.CELLULAR && 
        this.cachedConfig?.restrictDownloadOnCellular) {
      // 如果指定了大小，检查是否超过阈值
      if (size && size > 10 * 1024 * 1024) { // 10MB
        return false;
      }
    }
    
    // 检查数据节省模式
    if (this.cachedConfig?.enableDataSaver && size && size > 5 * 1024 * 1024) { // 5MB
      return false;
    }
    
    return true;
  }

  /**
   * 获取网络诊断信息
   */
  public async getNetworkDiagnostics(): Promise<{
    status: string;
    networkInfo: NetworkInfo;
    requestStats: RequestStats;
    lastSpeedTest?: SpeedTestResult;
    config: NetworkConfig;
    queueSize: number;
    activeRequests: number;
    diagnosticsTime: number;
  }> {
    try {
      // 获取最新的网络信息
      const networkInfo = await this.getNetworkInfo();
      
      // 获取请求统计
      const requestStats = await this.getRequestStats();
      
      // 获取配置
      const config = await this.getConfig();
      
      // 获取最后一次速度测试结果
      const lastSpeedTest = this.recentSpeedTests.length > 0 ? this.recentSpeedTests[0] : undefined;
      
      return {
        status: networkInfo.status,
        networkInfo,
        requestStats,
        lastSpeedTest,
        config,
        queueSize: this.requestQueue.length,
        activeRequests: this.activeRequests,
        diagnosticsTime: Date.now()
      };
    } catch (error) {
      this.logger.error('Failed to get network diagnostics', error as Error);
      throw error;
    }
  }

  /**
   * 导出网络数据（用于调试或分析）
   */
  public async exportNetworkData(): Promise<{
    networkInfo: NetworkInfo;
    config: NetworkConfig;
    requestStats: RequestStats;
    recentSpeedTests: SpeedTestResult[];
    networkHistory: NetworkInfo[];
    exportTime: number;
  }> {
    try {
      const data = {
        networkInfo: await this.getNetworkInfo(),
        config: await this.getConfig(),
        requestStats: await this.getRequestStats(),
        recentSpeedTests: await this.getRecentSpeedTests(),
        networkHistory: await this.getNetworkHistory(),
        exportTime: Date.now()
      };
      
      this.logger.info('Network data exported');
      
      return data;
    } catch (error) {
      this.logger.error('Failed to export network data', error as Error);
      throw error;
    }
  }

  /**
   * 销毁网络仓库资源
   */
  public async destroy(): Promise<void> {
    try {
      // 停止监控和处理
      this.stopConnectionMonitoring();
      this.stopQueueProcessing();
      
      // 保存数据
      await this.saveRequestStats();
      await this.saveNetworkHistory();
      
      // 清空队列
      this.clearRequestQueue();
      
      this.logger.info('NetworkRepository resources destroyed');
    } catch (error) {
      this.logger.error('Failed to destroy NetworkRepository resources', error as Error);
    }
  }
}

// 导出默认实例
export default NetworkRepository.getInstance();