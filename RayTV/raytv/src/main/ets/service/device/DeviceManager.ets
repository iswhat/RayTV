// DeviceManager.ets - 设备管理服务
// 基于HarmonyOS DeviceManager API实现设备管理功能

import Logger from '../../common/util/Logger';
import deviceManager from '@ohos.distributedHardware.deviceManager';
import BusinessError from '@ohos.base';
import ConfigService from '../../service/config/ConfigService';
import ModernDistributedDataService from '../sync/ModernDistributedDataService';

// 常量定义
const TAG = 'DeviceManager';
const PKG_NAME = 'com.raytv';

// 设备类型枚举
export enum DeviceType {
  PHONE = 'phone',
  TABLET = 'tablet',
  TV = 'tv',
  CAR = 'car',
  WEARABLE = 'wearable',
  SMART_VISION = 'smart_vision',
  OTHER = 'other'
}

// 设备状态枚�?
export enum DeviceStatus {
  ONLINE = 'online',
  OFFLINE = 'offline',
  CONNECTING = 'connecting',
  DISCONNECTING = 'disconnecting',
  UNAUTHORIZED = 'unauthorized'
}

// 设备认证状态枚�?
export enum AuthStatus {
  UNKNOWN = 'unknown',
  UNAUTHENTICATED = 'unauthenticated',
  AUTHENTICATING = 'authenticating',
  AUTHENTICATED = 'authenticated',
  AUTHENTICATION_FAILED = 'authentication_failed'
}

// 原始设备信息接口（来自系统API�?
interface RawDeviceInfo {
  deviceId: string;          // 设备唯一标识
  deviceName: string;        // 设备名称
  deviceType: number;        // 设备类型编号
  networkId?: string;        // 网络ID
  ip?: string;               // IP地址
  mac?: string;              // MAC地址
  version?: string;          // 版本信息
}

// 设备信息接口
export interface DeviceInfo {
  deviceId: string;          // 设备唯一标识
  deviceName: string;        // 设备名称
  deviceType: DeviceType;    // 设备类型
  networkId?: string;        // 网络ID
  ip?: string;               // IP地址
  mac?: string;              // MAC地址
  version?: string;          // 版本信息
  status: DeviceStatus;      // 设备状�?
  authStatus: AuthStatus;    // 认证状�?
  isLocalDevice: boolean;    // 是否为本�?
  batteryLevel?: number;     // 电池电量�?-100�?
  screenOn?: boolean;        // 屏幕是否点亮
  connectedTime?: number;    // 连接时间
  lastActiveTime?: number;   // 最后活跃时�?
  deviceLabel?: string;      // 自定义标�?
}

// 同步数据接口 - 支持具体数据类型
export interface SyncData<T = any> {
  deviceId: string;          // 目标设备ID
  dataType: string;          // 数据类型
  data: T;                   // 要同步的数据
}

// 播放控制参数接口
export interface PlaybackControlParams {
  position?: number;         // 播放位置
  speed?: number;            // 播放速度
  volume?: number;           // 音量
  // 避免使用any类型，定义具体的可能参数
  paused?: boolean;
  muted?: boolean;
  quality?: string;
  subtitles?: boolean;
}

// 设备选择条件接口
export interface DeviceFilter {
  deviceTypes?: DeviceType[];     // 设备类型过滤
  onlineOnly?: boolean;           // 仅在线设�?
  authenticatedOnly?: boolean;    // 仅已认证设备
  nameKeyword?: string;           // 设备名称关键�?
}

// 设备管理配置接口
export interface DeviceManagerConfig {
  enableAutoConnect: boolean;     // 启用自动连接
  enableDeviceDiscovery: boolean; // 启用设备发现
  requireAuthentication: boolean; // 需要认�?
  autoAuthorizeDevices: boolean;  // 自动授权设备
  rememberAuthorizedDevices: boolean; // 记住已授权设�?
}

// 默认设备管理配置
export const DEFAULT_DEVICE_MANAGER_CONFIG: DeviceManagerConfig = {
  enableAutoConnect: true,
  enableDeviceDiscovery: true,
  requireAuthentication: true,
  autoAuthorizeDevices: false,
  rememberAuthorizedDevices: true
};

// 设备变更事件类型
export enum DeviceEvent {
  DEVICE_ONLINE = 'device_online',
  DEVICE_OFFLINE = 'device_offline',
  DEVICE_CHANGED = 'device_changed',
  AUTH_STATE_CHANGED = 'auth_state_changed',
  DEVICE_CONNECTED = 'device_connected',
  DEVICE_DISCONNECTED = 'device_disconnected'
}

// 设备事件监听回调类型
type DeviceEventListener = (event: DeviceEvent, deviceInfo: DeviceInfo) => void;

export default class DeviceManager {
  private static instance: DeviceManager;
  private deviceManagerInstance: deviceManager.DeviceManager | null = null;
  private configService: ConfigService;
  private distributedDataService: DistributedDataService;
  private config: DeviceManagerConfig = DEFAULT_DEVICE_MANAGER_CONFIG;
  private devices: Map<string, DeviceInfo> = new Map();
  private eventListeners: Map<DeviceEvent, DeviceEventListener[]> = new Map();
  private authorizedDevices: Set<string> = new Set();
  private isInitialized: boolean = false;
  private authCallbackId: number | null = null;
  private deviceStateCallbackId: number | null = null;

  /**
   * 获取单例实例
   */
  public static getInstance(): DeviceManager {
    if (!DeviceManager.instance) {
      DeviceManager.instance = new DeviceManager();
    }
    return DeviceManager.instance;
  }

  /**
   * 构造函�?
   */
  private constructor() {
    this.configService = ConfigService.getInstance();
    this.distributedDataService = ModernDistributedDataService.getInstance();
  }

  /**
   * 初始化设备管理器
   * @param context 应用上下�?
   */
  public async initialize(context: Context): Promise<void> {
    if (this.isInitialized) {
      Logger.info(TAG, 'Device manager already initialized');
      return;
    }

    try {
      Logger.info(TAG, 'Initializing device manager...');

      // 初始化DeviceManager实例
      await this.initDeviceManagerInstance(context);
      
      // 加载配置
      await this.loadConfig();
      
      // 加载已授权设备列�?
      await this.loadAuthorizedDevices();
      
      // 注册设备状态回�?
      await this.registerDeviceStateCallback();
      
      // 注册认证回调
      await this.registerAuthCallback();
      
      // 获取本地设备信息
      await this.updateLocalDeviceInfo();
      
      // 如果启用了设备发现，开始发现设�?
      if (this.config.enableDeviceDiscovery) {
        await this.startDeviceDiscovery();
      }
      
      this.isInitialized = true;
      Logger.info(TAG, 'Device manager initialized successfully');
    } catch (error) {
      Logger.error(TAG, `Failed to initialize device manager: ${JSON.stringify(error)}`);
      throw error;
    }
  }

  /**
   * 初始化DeviceManager实例
   */
  private async initDeviceManagerInstance(context: Context): Promise<void> {
    try {
      const dmInstance = await deviceManager.createDeviceManager(PKG_NAME);
      if (!dmInstance) {
        throw new Error('Failed to create DeviceManager instance');
      }
      this.deviceManagerInstance = dmInstance;
    } catch (error) {
      Logger.error(TAG, `Failed to create DeviceManager instance: ${error}` instanceof Error ? `Failed to create DeviceManager instance: ${error}` : new Error(String(`Failed to create DeviceManager instance: ${error}` instanceof Error ? `Failed to create DeviceManager instance: ${error}` instanceof Error ? `Failed to create DeviceManager instance: ${error}` : new Error(String(`Failed to create DeviceManager instance: ${error}` : new Error(String(`Failed to create DeviceManager instance: ${error}` instanceof Error ? `Failed to create DeviceManager instance: ${error}` : new Error(String(`Failed to create DeviceManager instance: ${error}` instanceof Error ? `Failed to create DeviceManager instance: ${error}` instanceof Error ? `Failed to create DeviceManager instance: ${error}` : new Error(String(`Failed to create DeviceManager instance: ${error}` instanceof Error ? `Failed to create DeviceManager instance: ${error}` instanceof Error ? `Failed to create DeviceManager instance: ${error}` : new Error(String(`Failed to create DeviceManager instance: ${error}` : new Error(String(`Failed to create DeviceManager instance: ${error}` instanceof Error ? `Failed to create DeviceManager instance: ${error}` : new Error(String(`Failed to create DeviceManager instance: ${error}` : new Error(String(`Failed to create DeviceManager instance: ${error}` instanceof Error ? `Failed to create DeviceManager instance: ${error}` : new Error(String(`Failed to create DeviceManager instance: ${error}` instanceof Error ? `Failed to create DeviceManager instance: ${error}` instanceof Error ? `Failed to create DeviceManager instance: ${error}` : new Error(String(`Failed to create DeviceManager instance: ${error}` : new Error(String(`Failed to create DeviceManager instance: ${error}` instanceof Error ? `Failed to create DeviceManager instance: ${error}` : new Error(String(`Failed to create DeviceManager instance: ${error}`)))))));
      throw error;
    }
  }

  /**
   * 加载配置
   */
  private async loadConfig(): Promise<void> {
    try {
      const savedConfig = await this.configService.getConfig('deviceManagerConfig', DEFAULT_DEVICE_MANAGER_CONFIG);
      if (savedConfig) {
        this.config = { ...DEFAULT_DEVICE_MANAGER_CONFIG, ...savedConfig };
      }
    } catch (error) {
      Logger.error(TAG, `Failed to load device manager config: ${error}`);
    }
  }

  /**
   * 保存配置
   */
  public async saveConfig(config: Partial<DeviceManagerConfig>): Promise<void> {
    try {
      this.config = { ...this.config, ...config };
      await this.configService.setConfig('deviceManagerConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('deviceManagerConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('deviceManagerConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('deviceManagerConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('deviceManagerConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('deviceManagerConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('deviceManagerConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('deviceManagerConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('deviceManagerConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('deviceManagerConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('deviceManagerConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('deviceManagerConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('deviceManagerConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('deviceManagerConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('deviceManagerConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('deviceManagerConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('deviceManagerConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('deviceManagerConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('deviceManagerConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('deviceManagerConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('deviceManagerConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('deviceManagerConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('deviceManagerConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('deviceManagerConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('deviceManagerConfig', this.config instanceof Error ? ...config };
      await this.configService.setConfig('deviceManagerConfig', this.config : new Error(String(...config };
      await this.configService.setConfig('deviceManagerConfig', this.config)))))));
      
      // 根据配置调整设备发现状�?
      if (this.config.enableDeviceDiscovery && this.isInitialized) {
        await this.startDeviceDiscovery();
      } else {
        await this.stopDeviceDiscovery();
      }
    } catch (error) {
      Logger.error(TAG, `Failed to save device manager config: ${error}`);
      throw error;
    }
  }

  /**
   * 获取配置
   */
  public getConfig(): DeviceManagerConfig {
    return { ...this.config };
  }

  /**
   * 加载已授权设备列�?
   */
  private async loadAuthorizedDevices(): Promise<void> {
    try {
      const savedDevices = await this.configService.getConfig<string[]>('authorizedDevices', [] instanceof Error ? [] : new Error(String([] instanceof Error ? [] instanceof Error ? [] : new Error(String([] : new Error(String([] instanceof Error ? [] : new Error(String([] instanceof Error ? [] instanceof Error ? [] : new Error(String([] instanceof Error ? [] instanceof Error ? [] : new Error(String([] : new Error(String([] instanceof Error ? [] : new Error(String([] : new Error(String([] instanceof Error ? [] : new Error(String([] instanceof Error ? [] instanceof Error ? [] : new Error(String([] : new Error(String([] instanceof Error ? [] : new Error(String([])))))));
      savedDevices.forEach(deviceId => this.authorizedDevices.add(deviceId));
    } catch (error) {
      Logger.error(TAG, `Failed to load authorized devices: ${error}`);
    }
  }

  /**
   * 保存已授权设备列�?
   */
  private async saveAuthorizedDevices(): Promise<void> {
    try {
      const deviceIds = Array.from(this.authorizedDevices);
      await this.configService.setConfig('authorizedDevices', deviceIds instanceof Error ? deviceIds : new Error(String(deviceIds instanceof Error ? deviceIds instanceof Error ? deviceIds : new Error(String(deviceIds : new Error(String(deviceIds instanceof Error ? deviceIds : new Error(String(deviceIds instanceof Error ? deviceIds instanceof Error ? deviceIds : new Error(String(deviceIds instanceof Error ? deviceIds instanceof Error ? deviceIds : new Error(String(deviceIds : new Error(String(deviceIds instanceof Error ? deviceIds : new Error(String(deviceIds : new Error(String(deviceIds instanceof Error ? deviceIds : new Error(String(deviceIds instanceof Error ? deviceIds instanceof Error ? deviceIds : new Error(String(deviceIds : new Error(String(deviceIds instanceof Error ? deviceIds : new Error(String(deviceIds)))))));
    } catch (error) {
      Logger.error(TAG, `Failed to save authorized devices: ${error}`);
    }
  }

  /**
   * 注册设备状态回�?
   */
  private async registerDeviceStateCallback(): Promise<void> {
    if (!this.deviceManagerInstance) {
      throw new Error('DeviceManager instance not initialized');
    }

    try {
      const callbackId = this.deviceManagerInstance.on('deviceStateChange', async (data instanceof Error ? async (data : new Error(String(async (data instanceof Error ? async (data instanceof Error ? async (data : new Error(String(async (data : new Error(String(async (data instanceof Error ? async (data : new Error(String(async (data instanceof Error ? async (data instanceof Error ? async (data : new Error(String(async (data instanceof Error ? async (data instanceof Error ? async (data : new Error(String(async (data : new Error(String(async (data instanceof Error ? async (data : new Error(String(async (data : new Error(String(async (data instanceof Error ? async (data : new Error(String(async (data instanceof Error ? async (data instanceof Error ? async (data : new Error(String(async (data : new Error(String(async (data instanceof Error ? async (data : new Error(String(async (data))))))) => {
        Logger.debug(TAG, `Device state changed: ${JSON.stringify(data)}`);
        
        const deviceId = data.deviceId;
        let deviceInfo = this.devices.get(deviceId);
        
        if (!deviceInfo) {
          // 如果是新设备，尝试获取完整信�?
          try {
            const device = await this.getDeviceInfo(deviceId);
            deviceInfo = this.convertToDeviceInfo(device);
            this.devices.set(deviceId, deviceInfo);
          } catch (error) {
            Logger.error(TAG, `Failed to get device info for ${deviceId}: ${error}`);
            return;
          }
        }
        
        // 更新设备状�?
        switch (data.action) {
          case deviceManager.DeviceStateChangeAction.ONLINE:
            deviceInfo.status = DeviceStatus.ONLINE;
            deviceInfo.lastActiveTime = Date.now();
            this.notifyEvent(DeviceEvent.DEVICE_ONLINE, deviceInfo instanceof Error ? deviceInfo : new Error(String(deviceInfo instanceof Error ? deviceInfo instanceof Error ? deviceInfo : new Error(String(deviceInfo : new Error(String(deviceInfo instanceof Error ? deviceInfo : new Error(String(deviceInfo instanceof Error ? deviceInfo instanceof Error ? deviceInfo : new Error(String(deviceInfo instanceof Error ? deviceInfo instanceof Error ? deviceInfo : new Error(String(deviceInfo : new Error(String(deviceInfo instanceof Error ? deviceInfo : new Error(String(deviceInfo : new Error(String(deviceInfo instanceof Error ? deviceInfo : new Error(String(deviceInfo instanceof Error ? deviceInfo instanceof Error ? deviceInfo : new Error(String(deviceInfo : new Error(String(deviceInfo instanceof Error ? deviceInfo : new Error(String(deviceInfo)))))));
            break;
          case deviceManager.DeviceStateChangeAction.OFFLINE:
            deviceInfo.status = DeviceStatus.OFFLINE;
            this.notifyEvent(DeviceEvent.DEVICE_OFFLINE, deviceInfo);
            break;
          case deviceManager.DeviceStateChangeAction.CHANGE:
            this.notifyEvent(DeviceEvent.DEVICE_CHANGED, deviceInfo);
            break;
        }
      });
      
      this.deviceStateCallbackId = callbackId;
    } catch (error) {
      Logger.error(TAG, `Failed to register device state callback: ${error}`);
    }
  }

  /**
   * 注册认证回调
   */
  private async registerAuthCallback(): Promise<void> {
    if (!this.deviceManagerInstance) {
      throw new Error('DeviceManager instance not initialized');
    }

    try {
      const callbackId = this.deviceManagerInstance.on('deviceAuth', (data instanceof Error ? (data : new Error(String((data instanceof Error ? (data instanceof Error ? (data : new Error(String((data : new Error(String((data instanceof Error ? (data : new Error(String((data instanceof Error ? (data instanceof Error ? (data : new Error(String((data instanceof Error ? (data instanceof Error ? (data : new Error(String((data : new Error(String((data instanceof Error ? (data : new Error(String((data : new Error(String((data instanceof Error ? (data : new Error(String((data instanceof Error ? (data instanceof Error ? (data : new Error(String((data : new Error(String((data instanceof Error ? (data : new Error(String((data))))))) => {
        Logger.debug(TAG, `Device auth event: ${JSON.stringify(data)}`);
        
        const deviceId = data.deviceId;
        const deviceInfo = this.devices.get(deviceId);
        
        if (deviceInfo) {
          switch (data.result) {
            case deviceManager.DeviceAuthResult.SUCCESS:
              deviceInfo.authStatus = AuthStatus.AUTHENTICATED;
              this.authorizedDevices.add(deviceId);
              this.saveAuthorizedDevices().catch(error => {
                Logger.error(TAG, `Failed to save authorized devices: ${error}`);
              });
              break;
            case deviceManager.DeviceAuthResult.FAIL:
              deviceInfo.authStatus = AuthStatus.AUTHENTICATION_FAILED;
              break;
          }
          
          this.notifyEvent(DeviceEvent.AUTH_STATE_CHANGED, deviceInfo instanceof Error ? deviceInfo : new Error(String(deviceInfo instanceof Error ? deviceInfo instanceof Error ? deviceInfo : new Error(String(deviceInfo : new Error(String(deviceInfo instanceof Error ? deviceInfo : new Error(String(deviceInfo instanceof Error ? deviceInfo instanceof Error ? deviceInfo : new Error(String(deviceInfo instanceof Error ? deviceInfo instanceof Error ? deviceInfo : new Error(String(deviceInfo : new Error(String(deviceInfo instanceof Error ? deviceInfo : new Error(String(deviceInfo : new Error(String(deviceInfo instanceof Error ? deviceInfo : new Error(String(deviceInfo instanceof Error ? deviceInfo instanceof Error ? deviceInfo : new Error(String(deviceInfo : new Error(String(deviceInfo instanceof Error ? deviceInfo : new Error(String(deviceInfo)))))));
        }
      });
      
      this.authCallbackId = callbackId;
    } catch (error) {
      Logger.error(TAG, `Failed to register auth callback: ${error}`);
    }
  }

  /**
   * 更新本地设备信息
   */
  private async updateLocalDeviceInfo(): Promise<void> {
    if (!this.deviceManagerInstance) {
      return;
    }

    try {
      const localDeviceId = this.deviceManagerInstance.getLocalDeviceId();
      const deviceInfo: DeviceInfo = {
        deviceId: localDeviceId, deviceName: '本机',
        deviceType: this.getDeviceTypeByModel( instanceof Error ? deviceName: '本机',
        deviceType: this.getDeviceTypeByModel( : new Error(String(deviceName: '本机',
        deviceType: this.getDeviceTypeByModel( instanceof Error ? deviceName: '本机',
        deviceType: this.getDeviceTypeByModel( instanceof Error ? deviceName: '本机',
        deviceType: this.getDeviceTypeByModel( : new Error(String(deviceName: '本机',
        deviceType: this.getDeviceTypeByModel( : new Error(String(deviceName: '本机',
        deviceType: this.getDeviceTypeByModel( instanceof Error ? deviceName: '本机',
        deviceType: this.getDeviceTypeByModel( : new Error(String(deviceName: '本机',
        deviceType: this.getDeviceTypeByModel( instanceof Error ? deviceName: '本机',
        deviceType: this.getDeviceTypeByModel( instanceof Error ? deviceName: '本机',
        deviceType: this.getDeviceTypeByModel( : new Error(String(deviceName: '本机',
        deviceType: this.getDeviceTypeByModel( instanceof Error ? deviceName: '本机',
        deviceType: this.getDeviceTypeByModel( instanceof Error ? deviceName: '本机',
        deviceType: this.getDeviceTypeByModel( : new Error(String(deviceName: '本机',
        deviceType: this.getDeviceTypeByModel( : new Error(String(deviceName: '本机',
        deviceType: this.getDeviceTypeByModel( instanceof Error ? deviceName: '本机',
        deviceType: this.getDeviceTypeByModel( : new Error(String(deviceName: '本机',
        deviceType: this.getDeviceTypeByModel( : new Error(String(deviceName: '本机',
        deviceType: this.getDeviceTypeByModel( instanceof Error ? deviceName: '本机',
        deviceType: this.getDeviceTypeByModel( : new Error(String(deviceName: '本机',
        deviceType: this.getDeviceTypeByModel( instanceof Error ? deviceName: '本机',
        deviceType: this.getDeviceTypeByModel( instanceof Error ? deviceName: '本机',
        deviceType: this.getDeviceTypeByModel( : new Error(String(deviceName: '本机',
        deviceType: this.getDeviceTypeByModel( : new Error(String(deviceName: '本机',
        deviceType: this.getDeviceTypeByModel( instanceof Error ? deviceName: '本机',
        deviceType: this.getDeviceTypeByModel( : new Error(String(deviceName: '本机',
        deviceType: this.getDeviceTypeByModel())))))),
        status: DeviceStatus.ONLINE,
        authStatus: AuthStatus.AUTHENTICATED,
        isLocalDevice: true,
        lastActiveTime: Date.now(),
        connectedTime: Date.now()
      };
      
      this.devices.set(localDeviceId, deviceInfo);
    } catch (error) {
      Logger.error(TAG, `Failed to update local device info: ${error}`);
    }
  }

  /**
   * 根据设备型号获取设备类型
   */
  private getDeviceTypeByModel(): DeviceType {
    try {
      // 使用系统API获取设备信息来判断设备类�?
      // 1. 获取屏幕信息
      const screenDpi = this.getScreenDpi();
      const screenWidth = this.getScreenWidth();
      const screenHeight = this.getScreenHeight();
      
      // 2. 获取设备型号信息
      const deviceModel = this.getDeviceModel();
      const deviceBrand = this.getDeviceBrand();
      
      Logger.debug(TAG, `Device info: model=${deviceModel}, brand=${deviceBrand}, screen=${screenWidth}x${screenHeight}, dpi=${screenDpi}` instanceof Error ? `Device info: model=${deviceModel}, brand=${deviceBrand}, screen=${screenWidth}x${screenHeight}, dpi=${screenDpi}` : new Error(String(`Device info: model=${deviceModel}, brand=${deviceBrand}, screen=${screenWidth}x${screenHeight}, dpi=${screenDpi}` instanceof Error ? `Device info: model=${deviceModel}, brand=${deviceBrand}, screen=${screenWidth}x${screenHeight}, dpi=${screenDpi}` instanceof Error ? `Device info: model=${deviceModel}, brand=${deviceBrand}, screen=${screenWidth}x${screenHeight}, dpi=${screenDpi}` : new Error(String(`Device info: model=${deviceModel}, brand=${deviceBrand}, screen=${screenWidth}x${screenHeight}, dpi=${screenDpi}` : new Error(String(`Device info: model=${deviceModel}, brand=${deviceBrand}, screen=${screenWidth}x${screenHeight}, dpi=${screenDpi}` instanceof Error ? `Device info: model=${deviceModel}, brand=${deviceBrand}, screen=${screenWidth}x${screenHeight}, dpi=${screenDpi}` : new Error(String(`Device info: model=${deviceModel}, brand=${deviceBrand}, screen=${screenWidth}x${screenHeight}, dpi=${screenDpi}` instanceof Error ? `Device info: model=${deviceModel}, brand=${deviceBrand}, screen=${screenWidth}x${screenHeight}, dpi=${screenDpi}` instanceof Error ? `Device info: model=${deviceModel}, brand=${deviceBrand}, screen=${screenWidth}x${screenHeight}, dpi=${screenDpi}` : new Error(String(`Device info: model=${deviceModel}, brand=${deviceBrand}, screen=${screenWidth}x${screenHeight}, dpi=${screenDpi}` instanceof Error ? `Device info: model=${deviceModel}, brand=${deviceBrand}, screen=${screenWidth}x${screenHeight}, dpi=${screenDpi}` instanceof Error ? `Device info: model=${deviceModel}, brand=${deviceBrand}, screen=${screenWidth}x${screenHeight}, dpi=${screenDpi}` : new Error(String(`Device info: model=${deviceModel}, brand=${deviceBrand}, screen=${screenWidth}x${screenHeight}, dpi=${screenDpi}` : new Error(String(`Device info: model=${deviceModel}, brand=${deviceBrand}, screen=${screenWidth}x${screenHeight}, dpi=${screenDpi}` instanceof Error ? `Device info: model=${deviceModel}, brand=${deviceBrand}, screen=${screenWidth}x${screenHeight}, dpi=${screenDpi}` : new Error(String(`Device info: model=${deviceModel}, brand=${deviceBrand}, screen=${screenWidth}x${screenHeight}, dpi=${screenDpi}` : new Error(String(`Device info: model=${deviceModel}, brand=${deviceBrand}, screen=${screenWidth}x${screenHeight}, dpi=${screenDpi}` instanceof Error ? `Device info: model=${deviceModel}, brand=${deviceBrand}, screen=${screenWidth}x${screenHeight}, dpi=${screenDpi}` : new Error(String(`Device info: model=${deviceModel}, brand=${deviceBrand}, screen=${screenWidth}x${screenHeight}, dpi=${screenDpi}` instanceof Error ? `Device info: model=${deviceModel}, brand=${deviceBrand}, screen=${screenWidth}x${screenHeight}, dpi=${screenDpi}` instanceof Error ? `Device info: model=${deviceModel}, brand=${deviceBrand}, screen=${screenWidth}x${screenHeight}, dpi=${screenDpi}` : new Error(String(`Device info: model=${deviceModel}, brand=${deviceBrand}, screen=${screenWidth}x${screenHeight}, dpi=${screenDpi}` : new Error(String(`Device info: model=${deviceModel}, brand=${deviceBrand}, screen=${screenWidth}x${screenHeight}, dpi=${screenDpi}` instanceof Error ? `Device info: model=${deviceModel}, brand=${deviceBrand}, screen=${screenWidth}x${screenHeight}, dpi=${screenDpi}` : new Error(String(`Device info: model=${deviceModel}, brand=${deviceBrand}, screen=${screenWidth}x${screenHeight}, dpi=${screenDpi}`)))))));
      
      // 3. 根据屏幕尺寸和分辨率判断
      const screenDiagonal = Math.sqrt(screenWidth * screenWidth + screenHeight * screenHeight) / screenDpi;
      
      // 4. 设备类型判断逻辑
      
      // 电视判断：大屏幕(>30英寸)，特定分辨率(1080p/4K)，或型号包含TV/television等关键词
      if (screenDiagonal > 30 || 
          (screenWidth === 1920 && screenHeight === 1080) || 
          (screenWidth === 3840 && screenHeight === 2160) ||
          deviceModel.toLowerCase().includes('tv') ||
          deviceModel.toLowerCase().includes('television') ||
          deviceBrand.toLowerCase().includes('hisense') ||
          deviceBrand.toLowerCase().includes('tcl') ||
          deviceBrand.toLowerCase().includes('skyworth')) {
        return DeviceType.TV;
      }
      
      // 平板判断：中等屏�?7-12英寸)，特定分辨率
      if (screenDiagonal >= 7 && screenDiagonal <= 12) {
        return DeviceType.TABLET;
      }
      
      // 手机判断：小屏幕(<7英寸)，或型号包含phone/mobile等关键词
      if (screenDiagonal < 7 ||
          deviceModel.toLowerCase().includes('phone') ||
          deviceModel.toLowerCase().includes('mobile')) {
        return DeviceType.PHONE;
      }
      
      // 可穿戴设备判断：非常小的屏幕(<2英寸)
      if (screenDiagonal < 2) {
        return DeviceType.WEARABLE;
      }
      
      // 智能座舱判断：特定品牌或型号关键�?
      if (deviceModel.toLowerCase().includes('car') ||
          deviceBrand.toLowerCase().includes('car')) {
        return DeviceType.CAR;
      }
      
      // 智能视觉设备判断：特定分辨率或型号关键词
      if (deviceModel.toLowerCase().includes('vision') ||
          deviceModel.toLowerCase().includes('smartdisplay')) {
        return DeviceType.SMART_VISION;
      }
      
      // 默认返回TV类型
      return DeviceType.TV;
    } catch (error) {
      Logger.error(TAG, `Failed to determine device type: ${error}`);
      // 出错时默认返回TV类型
      return DeviceType.TV;
    }
  }
  
  /**
   * 获取屏幕DPI
   */
  private getScreenDpi(): number {
    try {
      // 在HarmonyOS中，可以通过display API获取屏幕DPI
      // 这里使用默认值作为后�?
      return 160;
    } catch {
      return 160;
    }
  }
  
  /**
   * 获取屏幕宽度
   */
  private getScreenWidth(): number {
    try {
      // 在HarmonyOS中，可以通过display API获取屏幕宽度
      // 这里使用默认值作为后�?
      return 1920;
    } catch {
      return 1920;
    }
  }
  
  /**
   * 获取屏幕高度
   */
  private getScreenHeight(): number {
    try {
      // 在HarmonyOS中，可以通过display API获取屏幕高度
      // 这里使用默认值作为后�?
      return 1080;
    } catch {
      return 1080;
    }
  }
  
  /**
   * 获取设备型号
   */
  private getDeviceModel(): string {
    try {
      // 在HarmonyOS中，可以通过systemParameter API获取设备型号
      // 这里返回默认值作为后�?
      return 'DefaultDevice';
    } catch {
      return 'DefaultDevice';
    }
  }
  
  /**
   * 获取设备品牌
   */
  private getDeviceBrand(): string {
    try {
      // 在HarmonyOS中，可以通过systemParameter API获取设备品牌
      // 这里返回默认值作为后�?
      return 'DefaultBrand';
    } catch {
      return 'DefaultBrand';
    }
  }

  /**
   * 开始设备发�?
   */
  public async startDeviceDiscovery(): Promise<void> {
    if (!this.deviceManagerInstance || !this.config.enableDeviceDiscovery) {
      return;
    }

    try {
      await this.deviceManagerInstance.startDeviceDiscovery();
      Logger.info(TAG, 'Device discovery started' instanceof Error ? 'Device discovery started' : new Error(String('Device discovery started' instanceof Error ? 'Device discovery started' instanceof Error ? 'Device discovery started' : new Error(String('Device discovery started' : new Error(String('Device discovery started' instanceof Error ? 'Device discovery started' : new Error(String('Device discovery started' instanceof Error ? 'Device discovery started' instanceof Error ? 'Device discovery started' : new Error(String('Device discovery started' instanceof Error ? 'Device discovery started' instanceof Error ? 'Device discovery started' : new Error(String('Device discovery started' : new Error(String('Device discovery started' instanceof Error ? 'Device discovery started' : new Error(String('Device discovery started' : new Error(String('Device discovery started' instanceof Error ? 'Device discovery started' : new Error(String('Device discovery started' instanceof Error ? 'Device discovery started' instanceof Error ? 'Device discovery started' : new Error(String('Device discovery started' : new Error(String('Device discovery started' instanceof Error ? 'Device discovery started' : new Error(String('Device discovery started')))))));
    } catch (error) {
      Logger.error(TAG, `Failed to start device discovery: ${error}`);
      throw error;
    }
  }

  /**
   * 停止设备发现
   */
  public async stopDeviceDiscovery(): Promise<void> {
    if (!this.deviceManagerInstance) {
      return;
    }

    try {
      await this.deviceManagerInstance.stopDeviceDiscovery();
      Logger.info(TAG, 'Device discovery stopped' instanceof Error ? 'Device discovery stopped' : new Error(String('Device discovery stopped' instanceof Error ? 'Device discovery stopped' instanceof Error ? 'Device discovery stopped' : new Error(String('Device discovery stopped' : new Error(String('Device discovery stopped' instanceof Error ? 'Device discovery stopped' : new Error(String('Device discovery stopped' instanceof Error ? 'Device discovery stopped' instanceof Error ? 'Device discovery stopped' : new Error(String('Device discovery stopped' instanceof Error ? 'Device discovery stopped' instanceof Error ? 'Device discovery stopped' : new Error(String('Device discovery stopped' : new Error(String('Device discovery stopped' instanceof Error ? 'Device discovery stopped' : new Error(String('Device discovery stopped' : new Error(String('Device discovery stopped' instanceof Error ? 'Device discovery stopped' : new Error(String('Device discovery stopped' instanceof Error ? 'Device discovery stopped' instanceof Error ? 'Device discovery stopped' : new Error(String('Device discovery stopped' : new Error(String('Device discovery stopped' instanceof Error ? 'Device discovery stopped' : new Error(String('Device discovery stopped')))))));
    } catch (error) {
      Logger.error(TAG, `Failed to stop device discovery: ${error}`);
    }
  }

  /**
   * 获取设备信息
   */
  private async getDeviceInfo(deviceId: string): Promise<RawDeviceInfo> {
    if (!this.deviceManagerInstance) {
      throw new Error('DeviceManager instance not initialized');
    }

    try {
      return await this.deviceManagerInstance.getDeviceInfo(deviceId);
    } catch (error) {
      Logger.error(TAG, `Failed to get device info for ${deviceId}: ${error}` instanceof Error ? `Failed to get device info for ${deviceId}: ${error}` : new Error(String(`Failed to get device info for ${deviceId}: ${error}` instanceof Error ? `Failed to get device info for ${deviceId}: ${error}` instanceof Error ? `Failed to get device info for ${deviceId}: ${error}` : new Error(String(`Failed to get device info for ${deviceId}: ${error}` : new Error(String(`Failed to get device info for ${deviceId}: ${error}` instanceof Error ? `Failed to get device info for ${deviceId}: ${error}` : new Error(String(`Failed to get device info for ${deviceId}: ${error}` instanceof Error ? `Failed to get device info for ${deviceId}: ${error}` instanceof Error ? `Failed to get device info for ${deviceId}: ${error}` : new Error(String(`Failed to get device info for ${deviceId}: ${error}` instanceof Error ? `Failed to get device info for ${deviceId}: ${error}` instanceof Error ? `Failed to get device info for ${deviceId}: ${error}` : new Error(String(`Failed to get device info for ${deviceId}: ${error}` : new Error(String(`Failed to get device info for ${deviceId}: ${error}` instanceof Error ? `Failed to get device info for ${deviceId}: ${error}` : new Error(String(`Failed to get device info for ${deviceId}: ${error}` : new Error(String(`Failed to get device info for ${deviceId}: ${error}` instanceof Error ? `Failed to get device info for ${deviceId}: ${error}` : new Error(String(`Failed to get device info for ${deviceId}: ${error}` instanceof Error ? `Failed to get device info for ${deviceId}: ${error}` instanceof Error ? `Failed to get device info for ${deviceId}: ${error}` : new Error(String(`Failed to get device info for ${deviceId}: ${error}` : new Error(String(`Failed to get device info for ${deviceId}: ${error}` instanceof Error ? `Failed to get device info for ${deviceId}: ${error}` : new Error(String(`Failed to get device info for ${deviceId}: ${error}`)))))));
      throw error;
    }
  }

  /**
   * 转换为统一的设备信息格�?
   */
  private convertToDeviceInfo(device: RawDeviceInfo): DeviceInfo {
    // 转换设备类型
    let deviceType = DeviceType.OTHER;
    switch (device.deviceType) {
      case 0: // 手机
        deviceType = DeviceType.PHONE;
        break;
      case 1: // 平板
        deviceType = DeviceType.TABLET;
        break;
      case 2: // TV
        deviceType = DeviceType.TV;
        break;
      case 3: // 车机
        deviceType = DeviceType.CAR;
        break;
      case 4: // 穿戴
        deviceType = DeviceType.WEARABLE;
        break;
      case 5: // 智能视觉
        deviceType = DeviceType.SMART_VISION;
        break;
    }

    // 转换认证状�?
    let authStatus = AuthStatus.UNAUTHENTICATED;
    if (this.authorizedDevices.has(device.deviceId)) {
      authStatus = AuthStatus.AUTHENTICATED;
    }

    return {
      deviceId: device.deviceId,
      deviceName: device.deviceName || '未知设备',
      deviceType: deviceType,
      networkId: device.networkId,
      status: DeviceStatus.ONLINE,
      authStatus: authStatus,
      isLocalDevice: false,
      lastActiveTime: Date.now(),
      connectedTime: Date.now()
    };
  }

  /**
   * 获取设备列表
   */
  public async getDevices(filter?: DeviceFilter): Promise<DeviceInfo[]> {
    if (!this.deviceManagerInstance) {
      return [];
    }

    try {
      // 获取在线设备列表
      const onlineDevices = await this.deviceManagerInstance.getTrustedDeviceListSync();
      
      // 转换设备信息
      const allDevices: DeviceInfo[] = [];
      
      // 添加在线设备
      for (const device of onlineDevices) {
        const deviceInfo = this.convertToDeviceInfo(device);
        this.devices.set(deviceInfo.deviceId, deviceInfo);
        allDevices.push(deviceInfo);
      }
      
      // 添加本地设备
      allDevices.push(...Array.from(this.devices.values()).filter(device => device.isLocalDevice));
      
      // 应用过滤条件
      let filteredDevices = allDevices;
      
      if (filter) {
        if (filter.deviceTypes && filter.deviceTypes.length > 0) {
          filteredDevices = filteredDevices.filter(device => 
            filter.deviceTypes!.includes(device.deviceType)
          );
        }
        
        if (filter.onlineOnly) {
          filteredDevices = filteredDevices.filter(device => 
            device.status === DeviceStatus.ONLINE
          );
        }
        
        if (filter.authenticatedOnly) {
          filteredDevices = filteredDevices.filter(device => 
            device.authStatus === AuthStatus.AUTHENTICATED || device.isLocalDevice
          );
        }
        
        if (filter.nameKeyword) {
          const keyword = filter.nameKeyword.toLowerCase();
          filteredDevices = filteredDevices.filter(device => 
            device.deviceName.toLowerCase().includes(keyword)
          );
        }
      }
      
      return filteredDevices;
    } catch (error) {
      Logger.error(TAG, `Failed to get devices: ${error}`);
      return [];
    }
  }
  
  /**
   * 向目标设备发起认证请�?
   * @param deviceId 目标设备ID
   * @param authCode 认证码（可选）
   */
  public async authenticateDevice(deviceId: string, authCode?: string instanceof Error ? authCode?: string : new Error(String(authCode?: string instanceof Error ? authCode?: string instanceof Error ? authCode?: string : new Error(String(authCode?: string : new Error(String(authCode?: string instanceof Error ? authCode?: string : new Error(String(authCode?: string instanceof Error ? authCode?: string instanceof Error ? authCode?: string : new Error(String(authCode?: string instanceof Error ? authCode?: string instanceof Error ? authCode?: string : new Error(String(authCode?: string : new Error(String(authCode?: string instanceof Error ? authCode?: string : new Error(String(authCode?: string : new Error(String(authCode?: string instanceof Error ? authCode?: string : new Error(String(authCode?: string instanceof Error ? authCode?: string instanceof Error ? authCode?: string : new Error(String(authCode?: string : new Error(String(authCode?: string instanceof Error ? authCode?: string : new Error(String(authCode?: string))))))): Promise<boolean> {
    if (!this.deviceManagerInstance) {
      throw new Error('DeviceManager instance not initialized');
    }
    
    try {
      Logger.info(TAG, `Authenticating device: ${deviceId}`);
      
      const deviceInfo = this.devices.get(deviceId);
      if (!deviceInfo) {
        throw new Error(`Device not found: ${deviceId}`);
      }
      
      // 更新设备认证状态为认证�?
      deviceInfo.authStatus = AuthStatus.AUTHENTICATING;
      this.notifyEvent(DeviceEvent.AUTH_STATE_CHANGED, deviceInfo);
      
      // 准备认证参数
      const authParams: deviceManager.AuthParam = {
        authType: deviceManager.AuthType.PIN,
        extraInfo: authCode ? { pinCode: authCode } : {}
      };
      
      // 发起认证
      await this.deviceManagerInstance.authenticateDevice(deviceId, authParams);
      
      // 等待认证结果（这里会通过认证回调处理�?
      // 给认证过程一个超时时�?
      await new Promise<void>((resolve, reject) => {
        const timeout = setTimeout(() => reject(new Error('Authentication timeout')), 30000);
        
        const checkAuthStatus = () => {
          const updatedDevice = this.devices.get(deviceId);
          if (updatedDevice?.authStatus === AuthStatus.AUTHENTICATED) {
            clearTimeout(timeout);
            resolve();
          } else if (updatedDevice?.authStatus === AuthStatus.AUTHENTICATION_FAILED) {
            clearTimeout(timeout);
            reject(new Error('Authentication failed'));
          } else {
            // 继续检�?
            setTimeout(checkAuthStatus, 1000);
          }
        };
        
        checkAuthStatus();
      });
      
      return true;
    } catch (error) {
      Logger.error(TAG, `Failed to authenticate device ${deviceId}: ${error}`);
      
      // 更新设备认证状态为认证失败
      const deviceInfo = this.devices.get(deviceId);
      if (deviceInfo) {
        deviceInfo.authStatus = AuthStatus.AUTHENTICATION_FAILED;
        this.notifyEvent(DeviceEvent.AUTH_STATE_CHANGED, deviceInfo instanceof Error ? deviceInfo : new Error(String(deviceInfo instanceof Error ? deviceInfo instanceof Error ? deviceInfo : new Error(String(deviceInfo : new Error(String(deviceInfo instanceof Error ? deviceInfo : new Error(String(deviceInfo instanceof Error ? deviceInfo instanceof Error ? deviceInfo : new Error(String(deviceInfo instanceof Error ? deviceInfo instanceof Error ? deviceInfo : new Error(String(deviceInfo : new Error(String(deviceInfo instanceof Error ? deviceInfo : new Error(String(deviceInfo : new Error(String(deviceInfo instanceof Error ? deviceInfo : new Error(String(deviceInfo instanceof Error ? deviceInfo instanceof Error ? deviceInfo : new Error(String(deviceInfo : new Error(String(deviceInfo instanceof Error ? deviceInfo : new Error(String(deviceInfo)))))));
      }
      
      return false;
    }
  }
  
  /**
   * 同步数据到目标设�?
   * @param deviceId 目标设备ID
   * @param dataType 数据类型
   * @param data 要同步的数据
   */
  public async syncDataToDevice<T>(deviceId: string, dataType: string, data: T): Promise<boolean> {
    if (!this.deviceManagerInstance) {
      throw new Error('DeviceManager instance not initialized');
    }
    
    try {
      // 检查设备是否已认证
      const deviceInfo = this.devices.get(deviceId);
      if (!deviceInfo || deviceInfo.authStatus !== AuthStatus.AUTHENTICATED) {
        throw new Error(`Device ${deviceId} is not authenticated`);
      }
      
      Logger.info(TAG, `Syncing data type ${dataType} to device: ${deviceId}`);
      
      // 通过DistributedDataService同步数据
      const syncResult = await this.distributedDataService.syncData({
        deviceId: deviceId,
        dataType: dataType,
        data: data
      });
      
      return syncResult;
    } catch (error) {
      Logger.error(TAG, `Failed to sync data to device ${deviceId}: ${error}`);
      return false;
    }
  }
  
  /**
   * 控制跨设备媒体播�?
   * @param deviceId 目标设备ID
   * @param action 播放动作（play/pause/stop/seek等）
   * @param params 动作参数
   */
  public async controlRemotePlayback(deviceId: string, action: string, params?: PlaybackControlParams instanceof Error ? action: string, params?: PlaybackControlParams : new Error(String(action: string, params?: PlaybackControlParams instanceof Error ? action: string, params?: PlaybackControlParams instanceof Error ? action: string, params?: PlaybackControlParams : new Error(String(action: string, params?: PlaybackControlParams : new Error(String(action: string, params?: PlaybackControlParams instanceof Error ? action: string, params?: PlaybackControlParams : new Error(String(action: string, params?: PlaybackControlParams instanceof Error ? action: string, params?: PlaybackControlParams instanceof Error ? action: string, params?: PlaybackControlParams : new Error(String(action: string, params?: PlaybackControlParams instanceof Error ? action: string, params?: PlaybackControlParams instanceof Error ? action: string, params?: PlaybackControlParams : new Error(String(action: string, params?: PlaybackControlParams : new Error(String(action: string, params?: PlaybackControlParams instanceof Error ? action: string, params?: PlaybackControlParams : new Error(String(action: string, params?: PlaybackControlParams : new Error(String(action: string, params?: PlaybackControlParams instanceof Error ? action: string, params?: PlaybackControlParams : new Error(String(action: string, params?: PlaybackControlParams instanceof Error ? action: string, params?: PlaybackControlParams instanceof Error ? action: string, params?: PlaybackControlParams : new Error(String(action: string, params?: PlaybackControlParams : new Error(String(action: string, params?: PlaybackControlParams instanceof Error ? action: string, params?: PlaybackControlParams : new Error(String(action: string, params?: PlaybackControlParams))))))): Promise<boolean> {
    if (!this.deviceManagerInstance) {
      throw new Error('DeviceManager instance not initialized');
    }
    
    try {
      // 检查设备是否已认证
      const deviceInfo = this.devices.get(deviceId);
      if (!deviceInfo || deviceInfo.authStatus !== AuthStatus.AUTHENTICATED) {
        throw new Error(`Device ${deviceId} is not authenticated`);
      }
      
      Logger.info(TAG, `Controlling remote playback on device ${deviceId}: ${action}`);
      
      // 构建控制命令
      const playbackCommand = {
        action: action,
        params: params || {},
        timestamp: Date.now()
      };
      
      // 通过DistributedDataService发送播放控制命�?
      const controlResult = await this.distributedDataService.syncData({
        deviceId: deviceId,
        dataType: 'playback_control',
        data: playbackCommand
      });
      
      return controlResult;
    } catch (error) {
      Logger.error(TAG, `Failed to control remote playback on device ${deviceId}: ${error}`);
      return false;
    }
  }
  
  /**
   * 获取单个设备信息
   */
  public async getDevice(deviceId: string): Promise<DeviceInfo | null> {
    if (!this.deviceManagerInstance) {
      return null;
    }

    try {
      // 先从缓存中查�?
      let deviceInfo = this.devices.get(deviceId);
      
      if (!deviceInfo && !deviceInfo?.isLocalDevice) {
        // 如果缓存中没有且不是本地设备，尝试获�?
        const device = await this.getDeviceInfo(deviceId);
        deviceInfo = this.convertToDeviceInfo(device);
        this.devices.set(deviceId, deviceInfo instanceof Error ? deviceInfo : new Error(String(deviceInfo instanceof Error ? deviceInfo instanceof Error ? deviceInfo : new Error(String(deviceInfo : new Error(String(deviceInfo instanceof Error ? deviceInfo : new Error(String(deviceInfo instanceof Error ? deviceInfo instanceof Error ? deviceInfo : new Error(String(deviceInfo instanceof Error ? deviceInfo instanceof Error ? deviceInfo : new Error(String(deviceInfo : new Error(String(deviceInfo instanceof Error ? deviceInfo : new Error(String(deviceInfo : new Error(String(deviceInfo instanceof Error ? deviceInfo : new Error(String(deviceInfo instanceof Error ? deviceInfo instanceof Error ? deviceInfo : new Error(String(deviceInfo : new Error(String(deviceInfo instanceof Error ? deviceInfo : new Error(String(deviceInfo)))))));
      }
      
      return deviceInfo || null;
    } catch (error) {
      Logger.error(TAG, `Failed to get device ${deviceId}: ${error}`);
      return null;
    }
  }
  
  /**
   * 注册设备事件监听�?
   */
  public on(event: DeviceEvent, listener: DeviceEventListener instanceof Error ? listener: DeviceEventListener : new Error(String(listener: DeviceEventListener instanceof Error ? listener: DeviceEventListener instanceof Error ? listener: DeviceEventListener : new Error(String(listener: DeviceEventListener : new Error(String(listener: DeviceEventListener instanceof Error ? listener: DeviceEventListener : new Error(String(listener: DeviceEventListener instanceof Error ? listener: DeviceEventListener instanceof Error ? listener: DeviceEventListener : new Error(String(listener: DeviceEventListener instanceof Error ? listener: DeviceEventListener instanceof Error ? listener: DeviceEventListener : new Error(String(listener: DeviceEventListener : new Error(String(listener: DeviceEventListener instanceof Error ? listener: DeviceEventListener : new Error(String(listener: DeviceEventListener : new Error(String(listener: DeviceEventListener instanceof Error ? listener: DeviceEventListener : new Error(String(listener: DeviceEventListener instanceof Error ? listener: DeviceEventListener instanceof Error ? listener: DeviceEventListener : new Error(String(listener: DeviceEventListener : new Error(String(listener: DeviceEventListener instanceof Error ? listener: DeviceEventListener : new Error(String(listener: DeviceEventListener))))))): void {
    if (!this.eventListeners.has(event)) {
      this.eventListeners.set(event, []);
    }
    this.eventListeners.get(event)!.push(listener);
  }
  
  /**
   * 取消注册设备事件监听�?
   */
  public off(event: DeviceEvent, listener: DeviceEventListener): void {
    if (this.eventListeners.has(event)) {
      const listeners = this.eventListeners.get(event)!;
      const index = listeners.indexOf(listener);
      if (index > -1) {
        listeners.splice(index, 1);
      }
    }
  }
  
  /**
   * 通知设备事件
   */
  private notifyEvent(event: DeviceEvent, deviceInfo: DeviceInfo): void {
    if (this.eventListeners.has(event)) {
      const listeners = this.eventListeners.get(event)!;
      for (const listener of listeners) {
        try {
          listener(event, deviceInfo);
        } catch (error) {
          Logger.error(TAG, `Error in event listener: ${error}`);
        }
      }
    }
  }
  
  /**
   * 清理资源
   */
  public async destroy(): Promise<void> {
    try {
      // 停止设备发现
      await this.stopDeviceDiscovery();
      
      // 移除回调
      if (this.deviceManagerInstance) {
        if (this.deviceStateCallbackId) {
          this.deviceManagerInstance.off('deviceStateChange', this.deviceStateCallbackId instanceof Error ? this.deviceStateCallbackId : new Error(String(this.deviceStateCallbackId instanceof Error ? this.deviceStateCallbackId instanceof Error ? this.deviceStateCallbackId : new Error(String(this.deviceStateCallbackId : new Error(String(this.deviceStateCallbackId instanceof Error ? this.deviceStateCallbackId : new Error(String(this.deviceStateCallbackId instanceof Error ? this.deviceStateCallbackId instanceof Error ? this.deviceStateCallbackId : new Error(String(this.deviceStateCallbackId instanceof Error ? this.deviceStateCallbackId instanceof Error ? this.deviceStateCallbackId : new Error(String(this.deviceStateCallbackId : new Error(String(this.deviceStateCallbackId instanceof Error ? this.deviceStateCallbackId : new Error(String(this.deviceStateCallbackId : new Error(String(this.deviceStateCallbackId instanceof Error ? this.deviceStateCallbackId : new Error(String(this.deviceStateCallbackId instanceof Error ? this.deviceStateCallbackId instanceof Error ? this.deviceStateCallbackId : new Error(String(this.deviceStateCallbackId : new Error(String(this.deviceStateCallbackId instanceof Error ? this.deviceStateCallbackId : new Error(String(this.deviceStateCallbackId)))))));
          this.deviceStateCallbackId = null;
        }
        if (this.authCallbackId) {
          this.deviceManagerInstance.off('deviceAuth', this.authCallbackId);
          this.authCallbackId = null;
        }
      }
      
      // 清空设备列表和监听器
      this.devices.clear();
      this.eventListeners.clear();
      
      this.isInitialized = false;
      Logger.info(TAG, 'Device manager destroyed');
    } catch (error) {
      Logger.error(TAG, `Failed to destroy device manager: ${error}`);
    }
  }
}


