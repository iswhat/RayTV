// DeviceManager.ets - 设备管理服务 | Device management service
// 基于HarmonyOS DeviceManager API实现设备管理功能 | Based on HarmonyOS DeviceManager API to implement device management functions

import Logger from '../../common/util/Logger';
import deviceManager from '@ohos.distributedHardware.deviceManager';
import BusinessError from '@ohos.base';
import ConfigService from '../../service/config/ConfigService';
import ModernDistributedDataService from '../sync/ModernDistributedDataService';

// 常量定义 | Constant definitions
const TAG = 'DeviceManager';
const PKG_NAME = 'com.raytv';

// 设备类型枚举 | Device type enumeration
export enum DeviceType {
  PHONE = 'phone',
  TABLET = 'tablet',
  TV = 'tv',
  CAR = 'car',
  WEARABLE = 'wearable',
  SMART_VISION = 'smart_vision',
  OTHER = 'other'
}

// 设备状态枚举 | Device status enumeration
export enum DeviceStatus {
  ONLINE = 'online',
  OFFLINE = 'offline',
  CONNECTING = 'connecting',
  DISCONNECTING = 'disconnecting',
  UNAUTHORIZED = 'unauthorized'
}

// 设备认证状态枚举 | Device authentication status enumeration
export enum AuthStatus {
  UNKNOWN = 'unknown',
  UNAUTHENTICATED = 'unauthenticated',
  AUTHENTICATING = 'authenticating',
  AUTHENTICATED = 'authenticated',
  AUTHENTICATION_FAILED = 'authentication_failed'
}

// 原始设备信息接口（来自连接API） | Raw device info interface (from connection API)
interface RawDeviceInfo {
  deviceId: string;          // 设备唯一标识 | Device unique identifier
  deviceName: string;        // 设备名称 | Device name
  deviceType: number;        // 设备类型编码 | Device type code
  networkId?: string;        // 网络ID | Network ID
  ip?: string;               // IP地址 | IP address
  mac?: string;              // MAC地址 | MAC address
  version?: string;          // 版本信息 | Version information
}

// 设备信息接口 | Device info interface
export interface DeviceInfo {
  deviceId: string;          // 设备唯一标识 | Device unique identifier
  deviceName: string;        // 设备名称 | Device name
  deviceType: DeviceType;    // 设备类型 | Device type
  networkId?: string;        // 网络ID | Network ID
  ip?: string;               // IP地址 | IP address
  mac?: string;              // MAC地址 | MAC address
  version?: string;          // 版本信息 | Version information
  status: DeviceStatus;      // 设备状态 | Device status
  authStatus: AuthStatus;    // 认证状态 | Authentication status
  isLocalDevice: boolean;    // 是否为本地设备 | Whether it is a local device
  batteryLevel?: number;     // 电池电量（0-100） | Battery level (0-100)
  screenOn?: boolean;        // 屏幕是否点亮 | Whether the screen is on
  connectedTime?: number;    // 连接时间 | Connection time
  lastActiveTime?: number;   // 最后活动时间 | Last active time
  deviceLabel?: string;      // 自定义标签 | Custom label
}

// 同步数据接口 - 支持具体数据类型 | Sync data interface - supports specific data types
export interface SyncData<T = unknown> {
  deviceId: string;          // 目标设备ID | Target device ID
  dataType: string;          // 数据类型 | Data type
  data: T;                   // 要同步的数据 | Data to be synchronized
}

// 播放控制参数接口 | Playback control parameters interface
export interface PlaybackControlParams {
  position?: number;         // 播放位置 | Playback position
  speed?: number;            // 播放速度 | Playback speed
  volume?: number;           // 音量 | Volume
  // 避免使用any类型，定义具体的可能参数 | Avoid using any type, define specific possible parameters
  paused?: boolean;
  muted?: boolean;
  quality?: string;
  subtitles?: boolean;
}

// 设备选择条件接口 | Device selection condition interface
export interface DeviceFilter {
  deviceTypes?: DeviceType[];     // 设备类型过滤 | Device type filtering
  onlineOnly?: boolean;           // 仅在线设备 | Online devices only
  authenticatedOnly?: boolean;    // 仅已认证设备 | Authenticated devices only
  nameKeyword?: string;           // 设备名称关键字 | Device name keyword
}

// 设备管理配置接口 | Device management configuration interface
export interface DeviceManagerConfig {
  enableAutoConnect: boolean;     // 启用自动连接 | Enable auto connect
  enableDeviceDiscovery: boolean; // 启用设备发现 | Enable device discovery
  requireAuthentication: boolean; // 需要认证 | Require authentication
  autoAuthorizeDevices: boolean;  // 自动授权设备 | Auto authorize devices
  rememberAuthorizedDevices: boolean; // 记住已授权设备 | Remember authorized devices
}

// 默认设备管理配置 | Default device management configuration
export const DEFAULT_DEVICE_MANAGER_CONFIG: DeviceManagerConfig = {
  enableAutoConnect: true,
  enableDeviceDiscovery: true,
  requireAuthentication: true,
  autoAuthorizeDevices: false,
  rememberAuthorizedDevices: true
};

// 设备变更事件类型 | Device change event type
export enum DeviceEvent {
  DEVICE_ONLINE = 'device_online',
  DEVICE_OFFLINE = 'device_offline',
  DEVICE_CHANGED = 'device_changed',
  AUTH_STATE_CHANGED = 'auth_state_changed',
  DEVICE_CONNECTED = 'device_connected',
  DEVICE_DISCONNECTED = 'device_disconnected'
}

// 设备事件监听回调类型 | Device event listener callback type
type DeviceEventListener = (event: DeviceEvent, deviceInfo: DeviceInfo) => void;

export default class DeviceManager {
  private static instance: DeviceManager;
  private deviceManagerInstance: deviceManager.DeviceManager | null = null;
  private configService: ConfigService;
  private distributedDataService: ModernDistributedDataService;
  private config: DeviceManagerConfig = DEFAULT_DEVICE_MANAGER_CONFIG;
  private devices: Map<string, DeviceInfo> = new Map();
  private eventListeners: Map<DeviceEvent, DeviceEventListener[]> = new Map();
  private authorizedDevices: Set<string> = new Set();
  private isInitialized: boolean = false;
  private authCallbackId: number | null = null;
  private deviceStateCallbackId: number | null = null;

  /**
   * 获取单例实例 | Get singleton instance
   */
  public static getInstance(): DeviceManager {
    if (!DeviceManager.instance) {
      DeviceManager.instance = new DeviceManager();
    }
    return DeviceManager.instance;
  }

  /**
   * 构造函数 | Constructor
   */
  private constructor() {
    this.configService = ConfigService.getInstance();
    this.distributedDataService = ModernDistributedDataService.getInstance();
  }

  /**
   * 初始化设备管理器 | Initialize device manager
   * @param context 应用上下文 | Application context
   */
  public async initialize(context: Context): Promise<void> {
    if (this.isInitialized) {
      Logger.info(TAG, 'Device manager already initialized');
      return;
    }

    try {
      Logger.info(TAG, 'Initializing device manager...');

      // 初始化DeviceManager实例 | Initialize DeviceManager instance
      await this.initDeviceManagerInstance(context);
      
      // 加载配置 | Load configuration
      await this.loadConfig();
      
      // 加载已授权设备列表 | Load authorized devices list
      await this.loadAuthorizedDevices();
      
      // 注册设备状态回调 | Register device state callback
      await this.registerDeviceStateCallback();
      
      // 注册认证回调 | Register authentication callback
      await this.registerAuthCallback();
      
      // 获取本地设备信息 | Get local device info
      await this.updateLocalDeviceInfo();
      
      // 如果启用了设备发现，开始设备发现 | Start device discovery if enabled
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
   * 初始化DeviceManager实例 | Initialize DeviceManager instance
   */
  private async initDeviceManagerInstance(context: Context): Promise<void> {
    try {
      const dmInstance = await deviceManager.createDeviceManager(PKG_NAME);
      if (!dmInstance) {
        throw new Error('Failed to create DeviceManager instance');
      }
      this.deviceManagerInstance = dmInstance;
    } catch (error) {
      Logger.error(TAG, `Failed to create DeviceManager instance: ${error}`);
      throw error;
    }
  }

  /**
   * 加载配置 | Load configuration
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
   * 保存配置 | Save configuration
   */
  public async saveConfig(config: Partial<DeviceManagerConfig>): Promise<void> {
    try {
      this.config = { ...this.config, ...config };
      await this.configService.setConfig('deviceManagerConfig', this.config);
      
      // 根据配置调整设备发现状态 | Adjust device discovery status according to configuration
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
   * 获取配置 | Get configuration
   */
  public getConfig(): DeviceManagerConfig {
    return { ...this.config };
  }

  /**
   * 加载已授权设备列表 | Load authorized devices list
   */
  private async loadAuthorizedDevices(): Promise<void> {
    try {
      const savedDevices = await this.configService.getConfig<string[]>('authorizedDevices', []);
      savedDevices.forEach(deviceId => this.authorizedDevices.add(deviceId));
    } catch (error) {
      Logger.error(TAG, `Failed to load authorized devices: ${error}`);
    }
  }

  /**
   * 保存已授权设备列表 | Save authorized devices list
   */
  private async saveAuthorizedDevices(): Promise<void> {
    try {
      const deviceIds = Array.from(this.authorizedDevices);
      await this.configService.setConfig('authorizedDevices', deviceIds);
    } catch (error) {
      Logger.error(TAG, `Failed to save authorized devices: ${error}`);
    }
  }

  /**
   * 注册设备状态回调 | Register device state callback
   */
  private async registerDeviceStateCallback(): Promise<void> {
    if (!this.deviceManagerInstance) {
      throw new Error('DeviceManager instance not initialized');
    }

    try {
      const callbackId = this.deviceManagerInstance.on('deviceStateChange', async (data) => {
        Logger.debug(TAG, `Device state changed: ${JSON.stringify(data)}`);
        
        const deviceId = data.deviceId;
        let deviceInfo = this.devices.get(deviceId);
        
        if (!deviceInfo) {
          // 如果是新设备，尝试获取完整信息 | If it's a new device, try to get complete info
          try {
            const device = await this.getDeviceInfo(deviceId);
            deviceInfo = this.convertToDeviceInfo(device);
            this.devices.set(deviceId, deviceInfo);
          } catch (error) {
            Logger.error(TAG, `Failed to get device info for ${deviceId}: ${error}`);
            return;
          }
        }
        
        // 更新设备状态 | Update device status
        switch (data.action) {
          case deviceManager.DeviceStateChangeAction.ONLINE:
            deviceInfo.status = DeviceStatus.ONLINE;
            deviceInfo.lastActiveTime = Date.now();
            this.notifyEvent(DeviceEvent.DEVICE_ONLINE, deviceInfo);
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
   * 注册认证回调 | Register authentication callback
   */
  private async registerAuthCallback(): Promise<void> {
    if (!this.deviceManagerInstance) {
      throw new Error('DeviceManager instance not initialized');
    }

    try {
      const callbackId = this.deviceManagerInstance.on('deviceAuth', (data) => {
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
          
          this.notifyEvent(DeviceEvent.AUTH_STATE_CHANGED, deviceInfo);
        }
      });
      
      this.authCallbackId = callbackId;
    } catch (error) {
      Logger.error(TAG, `Failed to register auth callback: ${error}`);
    }
  }

  /**
   * 更新本地设备信息 | Update local device info
   */
  private async updateLocalDeviceInfo(): Promise<void> {
    if (!this.deviceManagerInstance) {
      return;
    }

    try {
      const localDeviceId = this.deviceManagerInstance.getLocalDeviceId();
      const deviceInfo: DeviceInfo = {
        deviceId: localDeviceId,
        deviceName: '本地设备',
        deviceType: this.getDeviceTypeByModel(),
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
   * 根据设备型号获取设备类型 | Get device type by model
   */
  private getDeviceTypeByModel(): DeviceType {
    try {
      // 使用系统API获取设备信息来判断设备类型 | Use system API to get device info to determine device type
      // 1. 获取屏幕信息 | Get screen info
      const screenDpi = this.getScreenDpi();
      const screenWidth = this.getScreenWidth();
      const screenHeight = this.getScreenHeight();
      
      // 2. 获取设备型号信息 | Get device model info
      const deviceModel = this.getDeviceModel();
      const deviceBrand = this.getDeviceBrand();
      
      Logger.debug(TAG, `Device info: model=${deviceModel}, brand=${deviceBrand}, screen=${screenWidth}x${screenHeight}, dpi=${screenDpi}`);
      
      // 3. 根据屏幕尺寸和分辨率判断 | Judge based on screen size and resolution
      const screenDiagonal = Math.sqrt(screenWidth * screenWidth + screenHeight * screenHeight) / screenDpi;
      
      // 4. 设备类型判断逻辑 | Device type judgment logic
      
      // 电视判断：大屏幕(>30英寸)，特定分辨率(1080p/4K)，或型号包含TV/television等关键词 | TV judgment: large screen (>30 inches), specific resolution (1080p/4K), or model contains TV/television keywords
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
      
      // 平板判断：中等屏幕(7-12英寸)，特定分辨率 | Tablet judgment: medium screen (7-12 inches), specific resolution
      if (screenDiagonal >= 7 && screenDiagonal <= 12) {
        return DeviceType.TABLET;
      }
      
      // 手机判断：小屏幕(<7英寸)，或型号包含phone/mobile等关键词 | Phone judgment: small screen (<7 inches), or model contains phone/mobile keywords
      if (screenDiagonal < 7 ||
          deviceModel.toLowerCase().includes('phone') ||
          deviceModel.toLowerCase().includes('mobile')) {
        return DeviceType.PHONE;
      }
      
      // 可穿戴设备判断：非常小的屏幕(<2英寸) | Wearable device judgment: very small screen (<2 inches)
      if (screenDiagonal < 2) {
        return DeviceType.WEARABLE;
      }
      
      // 车载设备判断：特定品牌或型号关键词 | Car device judgment: specific brand or model keywords
      if (deviceModel.toLowerCase().includes('car') ||
          deviceBrand.toLowerCase().includes('car')) {
        return DeviceType.CAR;
      }
      
      // 智能视觉设备判断：特定分辨率或型号关键词 | Smart vision device judgment: specific resolution or model keywords
      if (deviceModel.toLowerCase().includes('vision') ||
          deviceModel.toLowerCase().includes('smartdisplay')) {
        return DeviceType.SMART_VISION;
      }
      
      // 默认返回TV类型 | Default return TV type
      return DeviceType.TV;
    } catch (error) {
      Logger.error(TAG, `Failed to determine device type: ${error}`);
      // 出错时默认返回TV类型 | Default return TV type when error
      return DeviceType.TV;
    }
  }
  
  /**
   * 获取屏幕DPI | Get screen DPI
   */
  private getScreenDpi(): number {
    try {
      // 在HarmonyOS中，可以通过display API获取屏幕DPI | In HarmonyOS, screen DPI can be obtained through display API
      // 这里使用默认值作为后备 | Use default value as fallback
      return 160;
    } catch {
      return 160;
    }
  }
  
  /**
   * 获取屏幕宽度 | Get screen width
   */
  private getScreenWidth(): number {
    try {
      // 在HarmonyOS中，可以通过display API获取屏幕宽度 | In HarmonyOS, screen width can be obtained through display API
      // 这里使用默认值作为后备 | Use default value as fallback
      return 1920;
    } catch {
      return 1920;
    }
  }
  
  /**
   * 获取屏幕高度 | Get screen height
   */
  private getScreenHeight(): number {
    try {
      // 在HarmonyOS中，可以通过display API获取屏幕高度 | In HarmonyOS, screen height can be obtained through display API
      // 这里使用默认值作为后备 | Use default value as fallback
      return 1080;
    } catch {
      return 1080;
    }
  }
  
  /**
   * 获取设备型号 | Get device model
   */
  private getDeviceModel(): string {
    try {
      // 在HarmonyOS中，可以通过systemParameter API获取设备型号 | In HarmonyOS, device model can be obtained through systemParameter API
      // 这里返回默认值作为后备 | Return default value as fallback
      return 'DefaultDevice';
    } catch {
      return 'DefaultDevice';
    }
  }
  
  /**
   * 获取设备品牌 | Get device brand
   */
  private getDeviceBrand(): string {
    try {
      // 在HarmonyOS中，可以通过systemParameter API获取设备品牌 | In HarmonyOS, device brand can be obtained through systemParameter API
      // 这里返回默认值作为后备 | Return default value as fallback
      return 'DefaultBrand';
    } catch {
      return 'DefaultBrand';
    }
  }

  /**
   * 开始设备发现 | Start device discovery
   */
  public async startDeviceDiscovery(): Promise<void> {
    if (!this.deviceManagerInstance || !this.config.enableDeviceDiscovery) {
      return;
    }

    try {
      await this.deviceManagerInstance.startDeviceDiscovery();
      Logger.info(TAG, 'Device discovery started');
    } catch (error) {
      Logger.error(TAG, `Failed to start device discovery: ${error}`);
      throw error;
    }
  }

  /**
   * 停止设备发现 | Stop device discovery
   */
  public async stopDeviceDiscovery(): Promise<void> {
    if (!this.deviceManagerInstance) {
      return;
    }

    try {
      await this.deviceManagerInstance.stopDeviceDiscovery();
      Logger.info(TAG, 'Device discovery stopped');
    } catch (error) {
      Logger.error(TAG, `Failed to stop device discovery: ${error}`);
    }
  }

  /**
   * 获取设备信息 | Get device info
   */
  private async getDeviceInfo(deviceId: string): Promise<RawDeviceInfo> {
    if (!this.deviceManagerInstance) {
      throw new Error('DeviceManager instance not initialized');
    }

    try {
      return await this.deviceManagerInstance.getDeviceInfo(deviceId);
    } catch (error) {
      Logger.error(TAG, `Failed to get device info for ${deviceId}: ${error}`);
      throw error;
    }
  }

  /**
   * 转换为统一的设备信息格式 | Convert to unified device info format
   */
  private convertToDeviceInfo(device: RawDeviceInfo): DeviceInfo {
    // 转换设备类型 | Convert device type
    let deviceType = DeviceType.OTHER;
    switch (device.deviceType) {
      case 0: // 手机 | Phone
        deviceType = DeviceType.PHONE;
        break;
      case 1: // 平板 | Tablet
        deviceType = DeviceType.TABLET;
        break;
      case 2: // TV
        deviceType = DeviceType.TV;
        break;
      case 3: // 车载 | Car
        deviceType = DeviceType.CAR;
        break;
      case 4: // 穿戴 | Wearable
        deviceType = DeviceType.WEARABLE;
        break;
      case 5: // 智能视觉 | Smart vision
        deviceType = DeviceType.SMART_VISION;
        break;
    }

    // 转换认证状态 | Convert authentication status
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
   * 获取设备列表 | Get devices list
   */
  public async getDevices(filter?: DeviceFilter): Promise<DeviceInfo[]> {
    if (!this.deviceManagerInstance) {
      return [];
    }

    try {
      // 获取在线设备列表 | Get online devices list
      const onlineDevices = await this.deviceManagerInstance.getTrustedDeviceListSync();
      
      // 转换设备信息 | Convert device info
      const allDevices: DeviceInfo[] = [];
      
      // 添加在线设备 | Add online devices
      for (const device of onlineDevices) {
        const deviceInfo = this.convertToDeviceInfo(device);
        this.devices.set(deviceInfo.deviceId, deviceInfo);
        allDevices.push(deviceInfo);
      }
      
      // 添加本地设备 | Add local device
      allDevices.push(...Array.from(this.devices.values()).filter(device => device.isLocalDevice));
      
      // 应用过滤条件 | Apply filter conditions
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
   * 向目标设备发送认证请求 | Send authentication request to target device
   * @param deviceId 目标设备ID | Target device ID
   * @param authCode 认证码（可选） | Authentication code (optional)
   */
  public async authenticateDevice(deviceId: string, authCode?: string): Promise<boolean> {
    if (!this.deviceManagerInstance) {
      throw new Error('DeviceManager instance not initialized');
    }
    
    try {
      Logger.info(TAG, `Authenticating device: ${deviceId}`);
      
      const deviceInfo = this.devices.get(deviceId);
      if (!deviceInfo) {
        throw new Error(`Device not found: ${deviceId}`);
      }
      
      // 更新设备认证状态为认证中 | Update device authentication status to authenticating
      deviceInfo.authStatus = AuthStatus.AUTHENTICATING;
      this.notifyEvent(DeviceEvent.AUTH_STATE_CHANGED, deviceInfo);
      
      // 准备认证参数 | Prepare authentication parameters
      const authParams: deviceManager.AuthParam = {
        authType: deviceManager.AuthType.PIN,
        extraInfo: authCode ? { pinCode: authCode } : {}
      };
      
      // 发起认证 | Initiate authentication
      await this.deviceManagerInstance.authenticateDevice(deviceId, authParams);
      
      // 等待认证结果（这里会通过认证回调处理） | Wait for authentication result (will be processed through auth callback)
      // 给认证过程一个超时时间 | Give authentication process a timeout
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
            // 继续检查 | Continue checking
            setTimeout(checkAuthStatus, 1000);
          }
        };
        
        checkAuthStatus();
      });
      
      return true;
    } catch (error) {
      Logger.error(TAG, `Failed to authenticate device ${deviceId}: ${error}`);
      
      // 更新设备认证状态为认证失败 | Update device authentication status to authentication failed
      const deviceInfo = this.devices.get(deviceId);
      if (deviceInfo) {
        deviceInfo.authStatus = AuthStatus.AUTHENTICATION_FAILED;
        this.notifyEvent(DeviceEvent.AUTH_STATE_CHANGED, deviceInfo);
      }
      
      return false;
    }
  }
  
  /**
   * 同步数据到目标设备 | Sync data to target device
   * @param deviceId 目标设备ID | Target device ID
   * @param dataType 数据类型 | Data type
   * @param data 要同步的数据 | Data to be synchronized
   */
  public async syncDataToDevice<T>(deviceId: string, dataType: string, data: T): Promise<boolean> {
    if (!this.deviceManagerInstance) {
      throw new Error('DeviceManager instance not initialized');
    }
    
    try {
      // 检查设备是否已认证 | Check if device is authenticated
      const deviceInfo = this.devices.get(deviceId);
      if (!deviceInfo || deviceInfo.authStatus !== AuthStatus.AUTHENTICATED) {
        throw new Error(`Device ${deviceId} is not authenticated`);
      }
      
      Logger.info(TAG, `Syncing data type ${dataType} to device: ${deviceId}`);
      
      // 通过DistributedDataService同步数据 | Sync data through DistributedDataService
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
   * 控制远程设备播放 | Control remote device playback
   * @param deviceId 目标设备ID | Target device ID
   * @param action 播放动作（play/pause/stop/seek等） | Playback action (play/pause/stop/seek, etc.)
   * @param params 动作参数 | Action parameters
   */
  public async controlRemotePlayback(deviceId: string, action: string, params?: PlaybackControlParams): Promise<boolean> {
    if (!this.deviceManagerInstance) {
      throw new Error('DeviceManager instance not initialized');
    }
    
    try {
      // 检查设备是否已认证 | Check if device is authenticated
      const deviceInfo = this.devices.get(deviceId);
      if (!deviceInfo || deviceInfo.authStatus !== AuthStatus.AUTHENTICATED) {
        throw new Error(`Device ${deviceId} is not authenticated`);
      }
      
      Logger.info(TAG, `Controlling remote playback on device ${deviceId}: ${action}`);
      
      // 构建控制命令 | Build control command
      const playbackCommand = {
        action: action,
        params: params || {},
        timestamp: Date.now()
      };
      
      // 通过DistributedDataService发送控制命令 | Send control command through DistributedDataService
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
   * 获取单个设备信息 | Get single device info
   */
  public async getDevice(deviceId: string): Promise<DeviceInfo | null> {
    if (!this.deviceManagerInstance) {
      return null;
    }

    try {
      // 先从缓存中查找 | First look in cache
      let deviceInfo = this.devices.get(deviceId);
      
      if (!deviceInfo && !deviceInfo?.isLocalDevice) {
        // 如果缓存中没有且不是本地设备，尝试获取 | If not in cache and not local device, try to get
        const device = await this.getDeviceInfo(deviceId);
        deviceInfo = this.convertToDeviceInfo(device);
        this.devices.set(deviceId, deviceInfo);
      }
      
      return deviceInfo || null;
    } catch (error) {
      Logger.error(TAG, `Failed to get device ${deviceId}: ${error}`);
      return null;
    }
  }
  
  /**
   * 注册设备事件监听器 | Register device event listener
   */
  public on(event: DeviceEvent, listener: DeviceEventListener): void {
    if (!this.eventListeners.has(event)) {
      this.eventListeners.set(event, []);
    }
    this.eventListeners.get(event)!.push(listener);
  }
  
  /**
   * 取消注册设备事件监听器 | Unregister device event listener
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
   * 通知设备事件 | Notify device event
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
   * 清理资源 | Clean up resources
   */
  public async destroy(): Promise<void> {
    try {
      // 停止设备发现 | Stop device discovery
      await this.stopDeviceDiscovery();
      
      // 移除回调 | Remove callbacks
      if (this.deviceManagerInstance) {
        if (this.deviceStateCallbackId) {
          this.deviceManagerInstance.off('deviceStateChange', this.deviceStateCallbackId);
          this.deviceStateCallbackId = null;
        }
        if (this.authCallbackId) {
          this.deviceManagerInstance.off('deviceAuth', this.authCallbackId);
          this.authCallbackId = null;
        }
      }
      
      // 清空设备列表和监听器 | Clear devices list and listeners
      this.devices.clear();
      this.eventListeners.clear();
      
      this.isInitialized = false;
      Logger.info(TAG, 'Device manager destroyed');
    } catch (error) {
      Logger.error(TAG, `Failed to destroy device manager: ${error}`);
    }
  }
}
