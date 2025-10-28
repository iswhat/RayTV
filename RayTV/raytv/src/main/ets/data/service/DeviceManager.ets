// DeviceManager.ets - 设备管理服务
// 基于HarmonyOS DeviceManager API实现设备管理功能

import Logger from '../../common/util/Logger';
import deviceManager from '@ohos.distributedHardware.deviceManager';
import { BusinessError } from '@ohos.base';
import ConfigService from '../../service/config/ConfigService';
import DistributedDataService from './DistributedDataService';

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

// 设备状态枚举
export enum DeviceStatus {
  ONLINE = 'online',
  OFFLINE = 'offline',
  CONNECTING = 'connecting',
  DISCONNECTING = 'disconnecting',
  UNAUTHORIZED = 'unauthorized'
}

// 设备认证状态枚举
export enum AuthStatus {
  UNKNOWN = 'unknown',
  UNAUTHENTICATED = 'unauthenticated',
  AUTHENTICATING = 'authenticating',
  AUTHENTICATED = 'authenticated',
  AUTHENTICATION_FAILED = 'authentication_failed'
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
  status: DeviceStatus;      // 设备状态
  authStatus: AuthStatus;    // 认证状态
  isLocalDevice: boolean;    // 是否为本机
  batteryLevel?: number;     // 电池电量（0-100）
  screenOn?: boolean;        // 屏幕是否点亮
  connectedTime?: number;    // 连接时间
  lastActiveTime?: number;   // 最后活跃时间
  deviceLabel?: string;      // 自定义标签
}

// 设备选择条件接口
export interface DeviceFilter {
  deviceTypes?: DeviceType[];     // 设备类型过滤
  onlineOnly?: boolean;           // 仅在线设备
  authenticatedOnly?: boolean;    // 仅已认证设备
  nameKeyword?: string;           // 设备名称关键字
}

// 设备管理配置接口
export interface DeviceManagerConfig {
  enableAutoConnect: boolean;     // 启用自动连接
  enableDeviceDiscovery: boolean; // 启用设备发现
  requireAuthentication: boolean; // 需要认证
  autoAuthorizeDevices: boolean;  // 自动授权设备
  rememberAuthorizedDevices: boolean; // 记住已授权设备
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
   * 构造函数
   */
  private constructor() {
    this.configService = ConfigService.getInstance();
    this.distributedDataService = DistributedDataService.getInstance();
  }

  /**
   * 初始化设备管理器
   * @param context 应用上下文
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
      
      // 加载已授权设备列表
      await this.loadAuthorizedDevices();
      
      // 注册设备状态回调
      await this.registerDeviceStateCallback();
      
      // 注册认证回调
      await this.registerAuthCallback();
      
      // 获取本地设备信息
      await this.updateLocalDeviceInfo();
      
      // 如果启用了设备发现，开始发现设备
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
      Logger.error(TAG, `Failed to create DeviceManager instance: ${error}`);
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
      await this.configService.setConfig('deviceManagerConfig', this.config);
      
      // 根据配置调整设备发现状态
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
   * 加载已授权设备列表
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
   * 保存已授权设备列表
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
   * 注册设备状态回调
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
          // 如果是新设备，尝试获取完整信息
          try {
            const device = await this.getDeviceInfo(deviceId);
            deviceInfo = this.convertToDeviceInfo(device);
            this.devices.set(deviceId, deviceInfo);
          } catch (error) {
            Logger.error(TAG, `Failed to get device info for ${deviceId}: ${error}`);
            return;
          }
        }
        
        // 更新设备状态
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
   * 注册认证回调
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
   * 更新本地设备信息
   */
  private async updateLocalDeviceInfo(): Promise<void> {
    if (!this.deviceManagerInstance) {
      return;
    }

    try {
      const localDeviceId = this.deviceManagerInstance.getLocalDeviceId();
      const deviceInfo: DeviceInfo = {
        deviceId: localDeviceId,
        deviceName: '本机',
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
   * 根据设备型号获取设备类型
   */
  private getDeviceTypeByModel(): DeviceType {
    // 这里简化处理，实际应用中需要根据设备型号、分辨率等信息判断
    // TODO: 实现更准确的设备类型判断逻辑
    return DeviceType.TV;
  }

  /**
   * 开始设备发现
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
   * 停止设备发现
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
   * 获取设备信息
   */
  private async getDeviceInfo(deviceId: string): Promise<any> {
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
   * 转换为统一的设备信息格式
   */
  private convertToDeviceInfo(device: any): DeviceInfo {
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

    // 转换认证状态
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
   * 获取单个设备信息
   */
  public async getDevice(deviceId: string): Promise<DeviceInfo | null> {
    if (!this.deviceManagerInstance) {
      return null;
    }

    try {
      // 先从缓存中查找
      let deviceInfo = this.devices.get(deviceId);
      
      if (!deviceInfo && !deviceInfo?.isLocalDevice) {
        // 如果缓存中没有且不是本地设备，尝试获取
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
   * 认证设备
   */
  public async authenticateDevice(deviceId: string): Promise<boolean> {
    if (!this.deviceManagerInstance) {
      throw new Error('DeviceManager instance not initialized');
    }

    try {
      const device = this.devices.get(deviceId);
      if (!device) {
        throw new Error(`Device ${deviceId} not found`);
      }

      device.authStatus = AuthStatus.AUTHENTICATING;
      
      // 发起设备认证
      await this.deviceManagerInstance.authenticateDevice(deviceId);
      
      // 认证是异步过程，这里只返回发起认证成功
      return true;
    } catch (error) {
      Logger.error(TAG, `Failed to authenticate device ${deviceId}: ${error}`);
      return false;
    }
  }

  /**
   * 解除设备认证
   */
  public async unauthenticateDevice(deviceId: string): Promise<void> {
    if (!this.deviceManagerInstance) {
      throw new Error('DeviceManager instance not initialized');
    }

    try {
      // 移除已授权设备列表
      this.authorizedDevices.delete(deviceId);
      await this.saveAuthorizedDevices();
      
      // 更新设备认证状态
      const device = this.devices.get(deviceId);
      if (device) {
        device.authStatus = AuthStatus.UNAUTHENTICATED;
        this.notifyEvent(DeviceEvent.AUTH_STATE_CHANGED, device);
      }
      
      Logger.info(TAG, `Uauthenticated device: ${deviceId}`);
    } catch (error) {
      Logger.error(TAG, `Failed to unauthenticate device ${deviceId}: ${error}`);
      throw error;
    }
  }

  /**
   * 连接设备
   */
  public async connectDevice(deviceId: string): Promise<boolean> {
    if (!this.deviceManagerInstance) {
      throw new Error('DeviceManager instance not initialized');
    }

    try {
      const device = this.devices.get(deviceId);
      if (!device) {
        throw new Error(`Device ${deviceId} not found`);
      }

      device.status = DeviceStatus.CONNECTING;
      
      // 检查认证状态
      if (this.config.requireAuthentication && 
          device.authStatus !== AuthStatus.AUTHENTICATED && 
          !device.isLocalDevice) {
        throw new Error(`Device ${deviceId} is not authenticated`);
      }

      // 这里只是模拟连接，实际连接逻辑可能需要根据具体业务需求实现
      // 对于DeviceManager来说，认证后通常就可以进行业务操作了
      device.status = DeviceStatus.ONLINE;
      device.connectedTime = Date.now();
      
      this.notifyEvent(DeviceEvent.DEVICE_CONNECTED, device);
      Logger.info(TAG, `Connected to device: ${deviceId}`);
      
      return true;
    } catch (error) {
      Logger.error(TAG, `Failed to connect to device ${deviceId}: ${error}`);
      
      const device = this.devices.get(deviceId);
      if (device) {
        device.status = DeviceStatus.DISCONNECTING;
        setTimeout(() => {
          device.status = DeviceStatus.OFFLINE;
          this.notifyEvent(DeviceEvent.DEVICE_DISCONNECTED, device);
        }, 1000);
      }
      
      return false;
    }
  }

  /**
   * 断开设备连接
   */
  public async disconnectDevice(deviceId: string): Promise<void> {
    try {
      const device = this.devices.get(deviceId);
      if (!device || device.isLocalDevice) {
        return;
      }

      device.status = DeviceStatus.DISCONNECTING;
      
      // 模拟断开连接
      setTimeout(() => {
        device.status = DeviceStatus.OFFLINE;
        this.notifyEvent(DeviceEvent.DEVICE_DISCONNECTED, device);
      }, 500);
      
      Logger.info(TAG, `Disconnected from device: ${deviceId}`);
    } catch (error) {
      Logger.error(TAG, `Failed to disconnect from device ${deviceId}: ${error}`);
    }
  }

  /**
   * 设置设备标签
   */
  public async setDeviceLabel(deviceId: string, label: string): Promise<void> {
    try {
      const device = this.devices.get(deviceId);
      if (!device) {
        throw new Error(`Device ${deviceId} not found`);
      }

      device.deviceLabel = label;
      
      // 保存设备标签到配置
      const labelsConfig = await this.configService.getConfig<Record<string, string>>('deviceLabels', {});
      labelsConfig[deviceId] = label;
      await this.configService.setConfig('deviceLabels', labelsConfig);
      
      this.notifyEvent(DeviceEvent.DEVICE_CHANGED, device);
    } catch (error) {
      Logger.error(TAG, `Failed to set device label for ${deviceId}: ${error}`);
      throw error;
    }
  }

  /**
   * 添加设备事件监听
   */
  public addDeviceEventListener(event: DeviceEvent, listener: DeviceEventListener): void {
    if (!this.eventListeners.has(event)) {
      this.eventListeners.set(event, []);
    }
    
    this.eventListeners.get(event)!.push(listener);
    Logger.debug(TAG, `Added device event listener for ${event}`);
  }

  /**
   * 移除设备事件监听
   */
  public removeDeviceEventListener(event: DeviceEvent, listener: DeviceEventListener): void {
    if (this.eventListeners.has(event)) {
      const listeners = this.eventListeners.get(event)!;
      const index = listeners.indexOf(listener);
      
      if (index > -1) {
        listeners.splice(index, 1);
        Logger.debug(TAG, `Removed device event listener for ${event}`);
      }
    }
  }

  /**
   * 通知事件
   */
  private notifyEvent(event: DeviceEvent, deviceInfo: DeviceInfo): void {
    if (this.eventListeners.has(event)) {
      const listeners = this.eventListeners.get(event)!;
      for (const listener of listeners) {
        try {
          listener(event, { ...deviceInfo });
        } catch (error) {
          Logger.error(TAG, `Error in device event listener: ${error}`);
        }
      }
    }
  }

  /**
   * 向设备发送消息
   */
  public async sendMessage(deviceId: string, message: any): Promise<boolean> {
    try {
      Logger.info(TAG, `Sending message to device ${deviceId}: ${JSON.stringify(message)}`);
      
      // 这里使用分布式数据服务来传输消息
      // 实际应用中可能需要根据具体需求选择合适的通信方式
      await this.distributedDataService.saveSyncData(
        'DEVICE_INFO',
        `message_${Date.now()}`,
        {
          senderId: this.deviceManagerInstance?.getLocalDeviceId(),
          timestamp: Date.now(),
          content: message
        },
        deviceId
      );
      
      return true;
    } catch (error) {
      Logger.error(TAG, `Failed to send message to device ${deviceId}: ${error}`);
      return false;
    }
  }

  /**
   * 关闭设备管理器
   */
  public close(): void {
    if (!this.isInitialized) {
      return;
    }

    // 移除回调
    if (this.deviceManagerInstance) {
      if (this.deviceStateCallbackId !== null) {
        this.deviceManagerInstance.off('deviceStateChange', this.deviceStateCallbackId);
      }
      if (this.authCallbackId !== null) {
        this.deviceManagerInstance.off('deviceAuth', this.authCallbackId);
      }
    }

    // 停止设备发现
    this.stopDeviceDiscovery().catch(error => {
      Logger.error(TAG, `Error stopping device discovery: ${error}`);
    });

    this.isInitialized = false;
    Logger.info(TAG, 'Device manager closed');
  }
}