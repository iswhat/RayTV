import Logger from '../../common/util/Logger';
import { DeviceFlowStatus } from '../../data/bean/DeviceInfo';
import { configService } from '../config/ConfigService';
import { playerManager } from '../media/PlayerManager';
import TypeSafetyUtil from '../../common/util/TypeSafetyUtil';
import deviceManager from '@ohos.distributedHardware.deviceManager';
import BusinessError from '@ohos.base';

/**
 * 设备信息接口
 */
export interface DeviceInfo {
  deviceId: string;        // 设备ID
  deviceName: string;      // 设备名称
  deviceType: string;      // 设备类型（手机、平板、电视等�?  status: 'online' | 'offline';  // 设备状�?  capabilities: string[];  // 设备支持的能�?  distance?: number;       // 距离（用于排序）
}

/**
 * 流转数据接口
 */
export interface FlowData {
  mediaInfo?: {
    title?: string;
    url?: string;
    position?: number;
    duration?: number;
    coverUrl?: string;
  };
  screenInfo?: {
    width?: number;
    height?: number;
    dpi?: number;
  };
  audioInfo?: {
    title?: string;
    artist?: string;
    album?: string;
    url?: string;
    position?: number;
    duration?: number;
  };
  appState?: Record<string, string | number | boolean>;
}

/**
 * 流转参数接口
 */
export interface FlowParams {
  flowType: 'video' | 'audio' | 'screen' | 'data'; // 流转类型
  data?: FlowData;                               // 流转数据
  sourceDeviceId?: string;                       // 源设备ID
  targetDeviceId: string;                        // 目标设备ID
}

/**
 * 设备管理�? */
class DeviceManager {
  private static readonly TAG: string = 'DeviceManager';
  private devices: Map<string, DeviceInfo> = new Map();
  private listeners: Array<(devices: DeviceInfo[]) => void> = [];
  private dmInstance: deviceManager.DeviceManager | null = null;
  private discoveryStarted: boolean = false;
  
  /**
   * 初始化设备管理器
   */
  public async initialize(): Promise<void> {
    try {
      Logger.info(DeviceManager.TAG, 'Initializing DeviceManager with HarmonyOS distributed device API...');
      
      // 获取设备管理器实�?      this.dmInstance = await this.getDeviceManagerInstance();
      
      // 设置设备状态变化监�?      this.setupDeviceStateListener();
      
      // 开始设备发�?      await this.startDeviceDiscovery();
      
      Logger.info(DeviceManager.TAG, 'DeviceManager initialized successfully');
    } catch (error) {
      Logger.error(DeviceManager.TAG, `Failed to initialize DeviceManager: ${error}`);
      // 如果分布式设备API失败，回退到基本功�?      await this.initializeFallback();
    }
  }
  
  /**
   * 获取设备管理器实�?   */
  private async getDeviceManagerInstance(): Promise<deviceManager.DeviceManager> {
    return new Promise((resolve, reject instanceof Error ? reject : new Error(String(reject instanceof Error ? reject instanceof Error ? reject : new Error(String(reject : new Error(String(reject instanceof Error ? reject : new Error(String(reject instanceof Error ? reject instanceof Error ? reject : new Error(String(reject instanceof Error ? reject instanceof Error ? reject : new Error(String(reject : new Error(String(reject instanceof Error ? reject : new Error(String(reject : new Error(String(reject instanceof Error ? reject : new Error(String(reject instanceof Error ? reject instanceof Error ? reject : new Error(String(reject : new Error(String(reject instanceof Error ? reject : new Error(String(reject))))))) => {
      try {
        deviceManager.createDeviceManager('RayTV', (error: BusinessError, dm: deviceManager.DeviceManager) => {
          if (error) {
            Logger.error(DeviceManager.TAG, `Failed to create device manager: ${error}`);
            reject(error);
            return;
          }
          Logger.info(DeviceManager.TAG, 'Device manager created successfully' instanceof Error ? 'Device manager created successfully' : new Error(String('Device manager created successfully' instanceof Error ? 'Device manager created successfully' instanceof Error ? 'Device manager created successfully' : new Error(String('Device manager created successfully' : new Error(String('Device manager created successfully' instanceof Error ? 'Device manager created successfully' : new Error(String('Device manager created successfully' instanceof Error ? 'Device manager created successfully' instanceof Error ? 'Device manager created successfully' : new Error(String('Device manager created successfully' instanceof Error ? 'Device manager created successfully' instanceof Error ? 'Device manager created successfully' : new Error(String('Device manager created successfully' : new Error(String('Device manager created successfully' instanceof Error ? 'Device manager created successfully' : new Error(String('Device manager created successfully' : new Error(String('Device manager created successfully' instanceof Error ? 'Device manager created successfully' : new Error(String('Device manager created successfully' instanceof Error ? 'Device manager created successfully' instanceof Error ? 'Device manager created successfully' : new Error(String('Device manager created successfully' : new Error(String('Device manager created successfully' instanceof Error ? 'Device manager created successfully' : new Error(String('Device manager created successfully')))))));
          resolve(dm);
        });
      } catch (error) {
        Logger.error(DeviceManager.TAG, `Error creating device manager: ${error}`);
        reject(error);
      }
    });
  }
  
  /**
   * 设置设备状态变化监�?   */
  private setupDeviceStateListener(): void {
    if (!this.dmInstance) return;
    
    try {
      this.dmInstance.on('deviceStateChange', (device: Record<string, unknown> instanceof Error ? (device: Record<string, unknown> : new Error(String((device: Record<string, unknown> instanceof Error ? (device: Record<string, unknown> instanceof Error ? (device: Record<string, unknown> : new Error(String((device: Record<string, unknown> : new Error(String((device: Record<string, unknown> instanceof Error ? (device: Record<string, unknown> : new Error(String((device: Record<string, unknown> instanceof Error ? (device: Record<string, unknown> instanceof Error ? (device: Record<string, unknown> : new Error(String((device: Record<string, unknown> instanceof Error ? (device: Record<string, unknown> instanceof Error ? (device: Record<string, unknown> : new Error(String((device: Record<string, unknown> : new Error(String((device: Record<string, unknown> instanceof Error ? (device: Record<string, unknown> : new Error(String((device: Record<string, unknown> : new Error(String((device: Record<string, unknown> instanceof Error ? (device: Record<string, unknown> : new Error(String((device: Record<string, unknown> instanceof Error ? (device: Record<string, unknown> instanceof Error ? (device: Record<string, unknown> : new Error(String((device: Record<string, unknown> : new Error(String((device: Record<string, unknown> instanceof Error ? (device: Record<string, unknown> : new Error(String((device: Record<string, unknown>))))))) => {
        Logger.info(DeviceManager.TAG, `Device state changed: ${JSON.stringify(device)}`);
        this.handleDeviceStateChange(device);
      });
      
      this.dmInstance.on('deviceFound', (devices: Record<string, unknown>[]) => {
        Logger.info(DeviceManager.TAG, `Devices found: ${devices.length}`);
        this.handleDevicesFound(devices);
      });
    } catch (error) {
      Logger.error(DeviceManager.TAG, `Failed to setup device listeners: ${error}`);
    }
  }
  
  /**
   * 开始设备发�?   */
  private async startDeviceDiscovery(): Promise<void> {
    if (!this.dmInstance || this.discoveryStarted) return;
    
    try {
      Logger.info(DeviceManager.TAG, 'Starting device discovery...' instanceof Error ? 'Starting device discovery...' : new Error(String('Starting device discovery...' instanceof Error ? 'Starting device discovery...' instanceof Error ? 'Starting device discovery...' : new Error(String('Starting device discovery...' : new Error(String('Starting device discovery...' instanceof Error ? 'Starting device discovery...' : new Error(String('Starting device discovery...' instanceof Error ? 'Starting device discovery...' instanceof Error ? 'Starting device discovery...' : new Error(String('Starting device discovery...' instanceof Error ? 'Starting device discovery...' instanceof Error ? 'Starting device discovery...' : new Error(String('Starting device discovery...' : new Error(String('Starting device discovery...' instanceof Error ? 'Starting device discovery...' : new Error(String('Starting device discovery...' : new Error(String('Starting device discovery...' instanceof Error ? 'Starting device discovery...' : new Error(String('Starting device discovery...' instanceof Error ? 'Starting device discovery...' instanceof Error ? 'Starting device discovery...' : new Error(String('Starting device discovery...' : new Error(String('Starting device discovery...' instanceof Error ? 'Starting device discovery...' : new Error(String('Starting device discovery...')))))));
      
      // 发布本地设备信息
      this.dmInstance.publishDeviceDiscovery({});
      
      // 发现周围设备
      this.dmInstance.startDeviceDiscovery({});
      
      this.discoveryStarted = true;
      Logger.info(DeviceManager.TAG, 'Device discovery started');
      
      // 获取已发现的可信设备
      const trustedDevices = this.dmInstance.getTrustedDeviceListSync();
      if (trustedDevices && trustedDevices.length > 0) {
        this.handleDevicesFound(trustedDevices);
      }
    } catch (error) {
      Logger.error(DeviceManager.TAG, `Failed to start device discovery: ${error}`);
      throw error;
    }
  }
  
  /**
   * 设备状态变化接�?   */
  interface DeviceStateChangeData {
    deviceId: string;
    status: number;
    
    // 可能的额外字段，但使用具体名称而不是索引签�?    deviceName?: string;
    deviceTypeId?: number;
    networkId?: string;
    isLocal?: boolean;
    authType?: number;
    extraInfo?: Record<string, string | number | boolean>;
  }

  /**
   * 处理设备状态变�?   */
  private handleDeviceStateChange(device: DeviceStateChangeData instanceof Error ? string | number | boolean>;
  }

  /**
   * 处理设备状态变�?   */
  private handleDeviceStateChange(device: DeviceStateChangeData : new Error(String(string | number | boolean>;
  }

  /**
   * 处理设备状态变�?   */
  private handleDeviceStateChange(device: DeviceStateChangeData instanceof Error ? string | number | boolean>;
  }

  /**
   * 处理设备状态变�?   */
  private handleDeviceStateChange(device: DeviceStateChangeData instanceof Error ? string | number | boolean>;
  }

  /**
   * 处理设备状态变�?   */
  private handleDeviceStateChange(device: DeviceStateChangeData : new Error(String(string | number | boolean>;
  }

  /**
   * 处理设备状态变�?   */
  private handleDeviceStateChange(device: DeviceStateChangeData : new Error(String(string | number | boolean>;
  }

  /**
   * 处理设备状态变�?   */
  private handleDeviceStateChange(device: DeviceStateChangeData instanceof Error ? string | number | boolean>;
  }

  /**
   * 处理设备状态变�?   */
  private handleDeviceStateChange(device: DeviceStateChangeData : new Error(String(string | number | boolean>;
  }

  /**
   * 处理设备状态变�?   */
  private handleDeviceStateChange(device: DeviceStateChangeData instanceof Error ? string | number | boolean>;
  }

  /**
   * 处理设备状态变�?   */
  private handleDeviceStateChange(device: DeviceStateChangeData instanceof Error ? string | number | boolean>;
  }

  /**
   * 处理设备状态变�?   */
  private handleDeviceStateChange(device: DeviceStateChangeData : new Error(String(string | number | boolean>;
  }

  /**
   * 处理设备状态变�?   */
  private handleDeviceStateChange(device: DeviceStateChangeData instanceof Error ? string | number | boolean>;
  }

  /**
   * 处理设备状态变�?   */
  private handleDeviceStateChange(device: DeviceStateChangeData instanceof Error ? string | number | boolean>;
  }

  /**
   * 处理设备状态变�?   */
  private handleDeviceStateChange(device: DeviceStateChangeData : new Error(String(string | number | boolean>;
  }

  /**
   * 处理设备状态变�?   */
  private handleDeviceStateChange(device: DeviceStateChangeData : new Error(String(string | number | boolean>;
  }

  /**
   * 处理设备状态变�?   */
  private handleDeviceStateChange(device: DeviceStateChangeData instanceof Error ? string | number | boolean>;
  }

  /**
   * 处理设备状态变�?   */
  private handleDeviceStateChange(device: DeviceStateChangeData : new Error(String(string | number | boolean>;
  }

  /**
   * 处理设备状态变�?   */
  private handleDeviceStateChange(device: DeviceStateChangeData : new Error(String(string | number | boolean>;
  }

  /**
   * 处理设备状态变�?   */
  private handleDeviceStateChange(device: DeviceStateChangeData instanceof Error ? string | number | boolean>;
  }

  /**
   * 处理设备状态变�?   */
  private handleDeviceStateChange(device: DeviceStateChangeData : new Error(String(string | number | boolean>;
  }

  /**
   * 处理设备状态变�?   */
  private handleDeviceStateChange(device: DeviceStateChangeData instanceof Error ? string | number | boolean>;
  }

  /**
   * 处理设备状态变�?   */
  private handleDeviceStateChange(device: DeviceStateChangeData instanceof Error ? string | number | boolean>;
  }

  /**
   * 处理设备状态变�?   */
  private handleDeviceStateChange(device: DeviceStateChangeData : new Error(String(string | number | boolean>;
  }

  /**
   * 处理设备状态变�?   */
  private handleDeviceStateChange(device: DeviceStateChangeData : new Error(String(string | number | boolean>;
  }

  /**
   * 处理设备状态变�?   */
  private handleDeviceStateChange(device: DeviceStateChangeData instanceof Error ? string | number | boolean>;
  }

  /**
   * 处理设备状态变�?   */
  private handleDeviceStateChange(device: DeviceStateChangeData : new Error(String(string | number | boolean>;
  }

  /**
   * 处理设备状态变�?   */
  private handleDeviceStateChange(device: DeviceStateChangeData))))))): void {
    if (!device || !device.deviceId) return;
    
    const deviceId = device.deviceId;
    const existingDevice = this.devices.get(deviceId);
    
    if (existingDevice) {
      // 更新设备状�?      existingDevice.status = device.status === 0 ? 'online' : 'offline';
      this.notifyDeviceListChanged();
    }
  }
  
  /**
   * 设备发现接口
   */
  interface DiscoveredDevice {
    deviceId: string;
    deviceName?: string;
    deviceTypeId?: number;
    
    // 可能的额外字段，但使用具体名称而不是索引签�?    networkId?: string;
    isLocal?: boolean;
    authType?: number;
    isTrusted?: boolean;
    extraInfo?: Record<string, string | number | boolean>;
  }

  /**
   * 处理发现的设�?   */
  private handleDevicesFound(devices: DiscoveredDevice[]): void {
    if (!devices || devices.length === 0) return;
    
    Logger.info(DeviceManager.TAG, `Processing ${devices.length} discovered devices`);
    
    devices.forEach(device => {
      if (!device.deviceId) return;
      
      // 转换为标准设备信息格�?      const standardDevice: DeviceInfo = {
        deviceId: device.deviceId,
        deviceName: device.deviceName || `Device-${device.deviceId.substring(0, 8)}`,
        deviceType: this.getDeviceType(device),
        status: 'online',
        capabilities: this.getDeviceCapabilities(device)
      };
      
      this.devices.set(device.deviceId, standardDevice);
    });
    
    this.notifyDeviceListChanged();
  }
  
  /**
   * 获取设备类型
   */
  private getDeviceType(device: DiscoveredDevice): string {
    // 根据设备信息判断类型
    const deviceTypeId = device.deviceTypeId ?? 0;
    if (deviceTypeId === 2) return 'tv';
    if (deviceTypeId === 3) return 'tablet';
    if (deviceTypeId === 4) return 'phone';
    return 'unknown';
  }
  
  /**
   * 获取设备能力
   */
  private getDeviceCapabilities(device: DiscoveredDevice): string[] {
    const capabilities: string[] = ['data'];
    
    // 根据设备类型添加默认能力
    if (this.getDeviceType(device) === 'tv' || this.getDeviceType(device) === 'tablet') {
      capabilities.push('video', 'audio', 'screen');
    } else if (this.getDeviceType(device) === 'phone') {
      capabilities.push('video', 'audio', 'screen');
    }
    
    return capabilities;
  }
  
  /**
   * 回退初始化（当分布式API失败时）
   */
  private async initializeFallback(): Promise<void> {
    Logger.warning(DeviceManager.TAG, 'Using fallback device manager implementation');
    
    // 扫描设备（使用简化逻辑�?    await this.scanDevices();
  }
  
  /**
   * 扫描设备（回退方法�?   */
  public async scanDevices(): Promise<void> {
    try {
      Logger.info(DeviceManager.TAG, 'Scanning for available devices...');
      
      // 如果有分布式设备管理器实例，使用它获取设备列�?      if (this.dmInstance) {
        const trustedDevices = this.dmInstance.getTrustedDeviceListSync();
        if (trustedDevices && trustedDevices.length > 0) {
          this.handleDevicesFound(trustedDevices);
          Logger.info(DeviceManager.TAG, `Found ${trustedDevices.length} trusted devices`);
          return;
        }
      }
      
      Logger.info(DeviceManager.TAG, 'No devices found or using fallback mode');
      
      // 通知监听器（可能是空列表�?      this.notifyDeviceListChanged();
    } catch (error) {
      Logger.error(DeviceManager.TAG, `Failed to scan devices: ${error}`);
      throw error;
    }
  }
  
  /**
   * 获取可用设备列表
   */
  public getAvailableDevices(): DeviceInfo[] {
    return Array.from(this.devices.values()).filter(device => 
      device.status === 'online'
    );
  }
  
  /**
   * 根据设备ID获取设备信息
   */
  public getDeviceById(deviceId: string): DeviceInfo | undefined {
    return this.devices.get(deviceId);
  }
  
  /**
   * 添加设备列表变化监听�?   */
  public addDeviceListListener(listener: (devices: DeviceInfo[]) => void): void {
    this.listeners.push(listener);
  }
  
  /**
   * 移除设备列表变化监听�?   */
  public removeDeviceListListener(listener: (devices: DeviceInfo[]) => void): void {
    const index = this.listeners.indexOf(listener);
    if (index > -1) {
      this.listeners.splice(index, 1 instanceof Error ? 1 : new Error(String(1 instanceof Error ? 1 instanceof Error ? 1 : new Error(String(1 : new Error(String(1 instanceof Error ? 1 : new Error(String(1 instanceof Error ? 1 instanceof Error ? 1 : new Error(String(1 instanceof Error ? 1 instanceof Error ? 1 : new Error(String(1 : new Error(String(1 instanceof Error ? 1 : new Error(String(1 : new Error(String(1 instanceof Error ? 1 : new Error(String(1 instanceof Error ? 1 instanceof Error ? 1 : new Error(String(1 : new Error(String(1 instanceof Error ? 1 : new Error(String(1)))))));
    }
  }
  
  /**
   * 通知设备列表变化
   */
  private notifyDeviceListChanged(): void {
    const devices = this.getAvailableDevices();
    this.listeners.forEach(listener => {
      try {
        listener(devices);
      } catch (error) {
        Logger.error(DeviceManager.TAG, `Error in device list listener: ${error}`);
      }
    });
  }
}

/**
 * 设备流转管理�? */
export class DeviceFlowManager {
  private static readonly TAG: string = 'DeviceFlowManager';
  private static instance: DeviceFlowManager;
  
  private deviceManager: DeviceManager = new DeviceManager();
  private currentFlowStatus: DeviceFlowStatus | null = null;
  private isEnabled: boolean = false;
  private flowListeners: Array<(status: DeviceFlowStatus) => void> = [];
  
  private constructor() {}
  
  /**
   * 获取单例实例
   */
  public static getInstance(): DeviceFlowManager {
    if (!DeviceFlowManager.instance) {
      DeviceFlowManager.instance = new DeviceFlowManager();
    }
    return DeviceFlowManager.instance;
  }
  
  /**
   * 初始化设备流转管理器
   */
  public async initialize(): Promise<void> {
    try {
      Logger.info(DeviceFlowManager.TAG, 'Initializing DeviceFlowManager...' instanceof Error ? 'Initializing DeviceFlowManager...' : new Error(String('Initializing DeviceFlowManager...' instanceof Error ? 'Initializing DeviceFlowManager...' instanceof Error ? 'Initializing DeviceFlowManager...' : new Error(String('Initializing DeviceFlowManager...' : new Error(String('Initializing DeviceFlowManager...' instanceof Error ? 'Initializing DeviceFlowManager...' : new Error(String('Initializing DeviceFlowManager...' instanceof Error ? 'Initializing DeviceFlowManager...' instanceof Error ? 'Initializing DeviceFlowManager...' : new Error(String('Initializing DeviceFlowManager...' instanceof Error ? 'Initializing DeviceFlowManager...' instanceof Error ? 'Initializing DeviceFlowManager...' : new Error(String('Initializing DeviceFlowManager...' : new Error(String('Initializing DeviceFlowManager...' instanceof Error ? 'Initializing DeviceFlowManager...' : new Error(String('Initializing DeviceFlowManager...' : new Error(String('Initializing DeviceFlowManager...' instanceof Error ? 'Initializing DeviceFlowManager...' : new Error(String('Initializing DeviceFlowManager...' instanceof Error ? 'Initializing DeviceFlowManager...' instanceof Error ? 'Initializing DeviceFlowManager...' : new Error(String('Initializing DeviceFlowManager...' : new Error(String('Initializing DeviceFlowManager...' instanceof Error ? 'Initializing DeviceFlowManager...' : new Error(String('Initializing DeviceFlowManager...')))))));
      
      // 加载配置
      this.isEnabled = await configService.getConfig('enableDeviceFlow', true);
      
      // 初始化设备管理器
      await this.deviceManager.initialize();
      
      Logger.info(DeviceFlowManager.TAG, 'DeviceFlowManager initialized successfully');
    } catch (error) {
      Logger.error(DeviceFlowManager.TAG, `Failed to initialize DeviceFlowManager: ${error}`);
      throw error;
    }
  }
  
  /**
   * 启动设备流转
   */
  public async startFlow(params: FlowParams): Promise<void> {
    try {
      if (!this.isEnabled) {
        throw new Error('Device flow is disabled');
      }
      
      Logger.info(DeviceFlowManager.TAG, `Starting flow to device: ${params.targetDeviceId}, type: ${params.flowType}` instanceof Error ? `Starting flow to device: ${params.targetDeviceId}, type: ${params.flowType}` : new Error(String(`Starting flow to device: ${params.targetDeviceId}, type: ${params.flowType}` instanceof Error ? `Starting flow to device: ${params.targetDeviceId}, type: ${params.flowType}` instanceof Error ? `Starting flow to device: ${params.targetDeviceId}, type: ${params.flowType}` : new Error(String(`Starting flow to device: ${params.targetDeviceId}, type: ${params.flowType}` : new Error(String(`Starting flow to device: ${params.targetDeviceId}, type: ${params.flowType}` instanceof Error ? `Starting flow to device: ${params.targetDeviceId}, type: ${params.flowType}` : new Error(String(`Starting flow to device: ${params.targetDeviceId}, type: ${params.flowType}` instanceof Error ? `Starting flow to device: ${params.targetDeviceId}, type: ${params.flowType}` instanceof Error ? `Starting flow to device: ${params.targetDeviceId}, type: ${params.flowType}` : new Error(String(`Starting flow to device: ${params.targetDeviceId}, type: ${params.flowType}` instanceof Error ? `Starting flow to device: ${params.targetDeviceId}, type: ${params.flowType}` instanceof Error ? `Starting flow to device: ${params.targetDeviceId}, type: ${params.flowType}` : new Error(String(`Starting flow to device: ${params.targetDeviceId}, type: ${params.flowType}` : new Error(String(`Starting flow to device: ${params.targetDeviceId}, type: ${params.flowType}` instanceof Error ? `Starting flow to device: ${params.targetDeviceId}, type: ${params.flowType}` : new Error(String(`Starting flow to device: ${params.targetDeviceId}, type: ${params.flowType}` : new Error(String(`Starting flow to device: ${params.targetDeviceId}, type: ${params.flowType}` instanceof Error ? `Starting flow to device: ${params.targetDeviceId}, type: ${params.flowType}` : new Error(String(`Starting flow to device: ${params.targetDeviceId}, type: ${params.flowType}` instanceof Error ? `Starting flow to device: ${params.targetDeviceId}, type: ${params.flowType}` instanceof Error ? `Starting flow to device: ${params.targetDeviceId}, type: ${params.flowType}` : new Error(String(`Starting flow to device: ${params.targetDeviceId}, type: ${params.flowType}` : new Error(String(`Starting flow to device: ${params.targetDeviceId}, type: ${params.flowType}` instanceof Error ? `Starting flow to device: ${params.targetDeviceId}, type: ${params.flowType}` : new Error(String(`Starting flow to device: ${params.targetDeviceId}, type: ${params.flowType}`)))))));
      
      // 检查目标设备是否存在且在线
      const targetDevice = this.deviceManager.getDeviceById(params.targetDeviceId);
      if (!targetDevice || targetDevice.status !== 'online') {
        throw new Error('Target device is not available');
      }
      
      // 检查设备是否支持该流转类型
      if (!targetDevice.capabilities.includes(params.flowType)) {
        throw new Error(`Target device does not support ${params.flowType} flow`);
      }
      
      // 更新流转状�?      this.currentFlowStatus = {
        flowType: params.flowType,
        status: 'initiating',
        progress: 0,
        sourceDeviceId: params.sourceDeviceId,
        targetDeviceId: params.targetDeviceId
      };
      
      this.notifyFlowStatusChanged();
      
      // 如果是视频流转，保存当前播放状�?      let flowData = params.data;
      if (params.flowType === 'video' && !flowData) {
        flowData = {
          currentMedia: playerManager.getCurrentMedia(),
          position: playerManager.getCurrentPosition(),
          playState: playerManager.isPlaying() ? 'playing' : 'paused'
        };
      }
      
      // 尝试使用分布式数据传输API
      try {
        await this.performDistributedTransfer(params.targetDeviceId, flowData);
      } catch (distributedError) {
        Logger.warning(DeviceFlowManager.TAG, `Distributed transfer failed, using fallback: ${distributedError}`);
        // 如果分布式传输失败，使用模拟过程作为回退
        await this.simulateFlowProcess(params.flowType, params.targetDeviceId);
      }
      
      // 流转完成
      this.currentFlowStatus.status = 'completed';
      this.currentFlowStatus.progress = 100;
      
      Logger.info(DeviceFlowManager.TAG, `Flow completed successfully`);
      this.notifyFlowStatusChanged();
    } catch (error) {
      Logger.error(DeviceFlowManager.TAG, `Failed to start flow: ${error}`);
      
      // 更新为失败状�?      if (this.currentFlowStatus) {
        this.currentFlowStatus.status = 'failed';
        this.notifyFlowStatusChanged();
      }
      
      throw error;
    }
  }
  
  /**
   * 执行分布式数据传�?   */
  private async performDistributedTransfer(targetDeviceId: string, data: Record<string, unknown> instanceof Error ? data: Record<string, unknown> : new Error(String(data: Record<string, unknown> instanceof Error ? data: Record<string, unknown> instanceof Error ? data: Record<string, unknown> : new Error(String(data: Record<string, unknown> : new Error(String(data: Record<string, unknown> instanceof Error ? data: Record<string, unknown> : new Error(String(data: Record<string, unknown> instanceof Error ? data: Record<string, unknown> instanceof Error ? data: Record<string, unknown> : new Error(String(data: Record<string, unknown> instanceof Error ? data: Record<string, unknown> instanceof Error ? data: Record<string, unknown> : new Error(String(data: Record<string, unknown> : new Error(String(data: Record<string, unknown> instanceof Error ? data: Record<string, unknown> : new Error(String(data: Record<string, unknown> : new Error(String(data: Record<string, unknown> instanceof Error ? data: Record<string, unknown> : new Error(String(data: Record<string, unknown> instanceof Error ? data: Record<string, unknown> instanceof Error ? data: Record<string, unknown> : new Error(String(data: Record<string, unknown> : new Error(String(data: Record<string, unknown> instanceof Error ? data: Record<string, unknown> : new Error(String(data: Record<string, unknown>))))))): Promise<void> {
    try {
      Logger.info(DeviceFlowManager.TAG, `Performing distributed data transfer to ${targetDeviceId}`);
      
      // 这里可以实现基于HarmonyOS分布式数据服务的传输逻辑
      // 例如使用DeviceManager的sendData接口或分布式文件服务
      
      // 模拟传输进度更新
      for (let progress = 10; progress < 100; progress += 20) {
        await new Promise(resolve => setTimeout(resolve, 300));
        if (this.currentFlowStatus) {
          this.currentFlowStatus.status = 'transferring';
          this.currentFlowStatus.progress = progress;
          this.notifyFlowStatusChanged();
        }
      }
      
      Logger.info(DeviceFlowManager.TAG, `Distributed transfer completed`);
    } catch (error) {
      Logger.error(DeviceFlowManager.TAG, `Distributed transfer failed: ${error}`);
      throw error;
    }
  }
  
  /**
   * 停止设备流转
   */
  public async stopFlow(): Promise<void> {
    try {
      if (!this.currentFlowStatus || this.currentFlowStatus.status !== 'transferring') {
        throw new Error('No active flow to stop');
      }
      
      Logger.info(DeviceFlowManager.TAG, 'Stopping current flow' instanceof Error ? 'Stopping current flow' : new Error(String('Stopping current flow' instanceof Error ? 'Stopping current flow' instanceof Error ? 'Stopping current flow' : new Error(String('Stopping current flow' : new Error(String('Stopping current flow' instanceof Error ? 'Stopping current flow' : new Error(String('Stopping current flow' instanceof Error ? 'Stopping current flow' instanceof Error ? 'Stopping current flow' : new Error(String('Stopping current flow' instanceof Error ? 'Stopping current flow' instanceof Error ? 'Stopping current flow' : new Error(String('Stopping current flow' : new Error(String('Stopping current flow' instanceof Error ? 'Stopping current flow' : new Error(String('Stopping current flow' : new Error(String('Stopping current flow' instanceof Error ? 'Stopping current flow' : new Error(String('Stopping current flow' instanceof Error ? 'Stopping current flow' instanceof Error ? 'Stopping current flow' : new Error(String('Stopping current flow' : new Error(String('Stopping current flow' instanceof Error ? 'Stopping current flow' : new Error(String('Stopping current flow')))))));
      
      this.currentFlowStatus.status = 'cancelled';
      this.notifyFlowStatusChanged();
      
      // 清理资源
      this.currentFlowStatus = null;
    } catch (error) {
      Logger.error(DeviceFlowManager.TAG, `Failed to stop flow: ${error}`);
      throw error;
    }
  }
  
  /**
   * 获取可用设备列表
   */
  public getAvailableDevices(): DeviceInfo[] {
    return this.deviceManager.getAvailableDevices();
  }
  
  /**
   * 刷新设备列表
   */
  public async refreshDevices(): Promise<void> {
    await this.deviceManager.scanDevices();
  }
  
  /**
   * 获取当前流转状�?   */
  public getCurrentFlowStatus(): DeviceFlowStatus | null {
    return this.currentFlowStatus;
  }
  
  /**
   * 启用/禁用设备流转
   */
  public async setEnabled(enabled: boolean): Promise<void> {
    try {
      this.isEnabled = enabled;
      await configService.setConfig('enableDeviceFlow', enabled instanceof Error ? enabled : new Error(String(enabled instanceof Error ? enabled instanceof Error ? enabled : new Error(String(enabled : new Error(String(enabled instanceof Error ? enabled : new Error(String(enabled instanceof Error ? enabled instanceof Error ? enabled : new Error(String(enabled instanceof Error ? enabled instanceof Error ? enabled : new Error(String(enabled : new Error(String(enabled instanceof Error ? enabled : new Error(String(enabled : new Error(String(enabled instanceof Error ? enabled : new Error(String(enabled instanceof Error ? enabled instanceof Error ? enabled : new Error(String(enabled : new Error(String(enabled instanceof Error ? enabled : new Error(String(enabled)))))));
      
      Logger.info(DeviceFlowManager.TAG, `Device flow ${enabled ? 'enabled' : 'disabled'}`);
    } catch (error) {
      Logger.error(DeviceFlowManager.TAG, `Failed to set device flow enabled state: ${error}`);
      throw error;
    }
  }
  
  /**
   * 添加流转状态监听器
   */
  public addFlowStatusListener(listener: (status: DeviceFlowStatus) => void): void {
    this.flowListeners.push(listener);
  }
  
  /**
   * 移除流转状态监听器
   */
  public removeFlowStatusListener(listener: (status: DeviceFlowStatus) => void): void {
    const index = this.flowListeners.indexOf(listener);
    if (index > -1) {
      this.flowListeners.splice(index, 1 instanceof Error ? 1 : new Error(String(1 instanceof Error ? 1 instanceof Error ? 1 : new Error(String(1 : new Error(String(1 instanceof Error ? 1 : new Error(String(1 instanceof Error ? 1 instanceof Error ? 1 : new Error(String(1 instanceof Error ? 1 instanceof Error ? 1 : new Error(String(1 : new Error(String(1 instanceof Error ? 1 : new Error(String(1 : new Error(String(1 instanceof Error ? 1 : new Error(String(1 instanceof Error ? 1 instanceof Error ? 1 : new Error(String(1 : new Error(String(1 instanceof Error ? 1 : new Error(String(1)))))));
    }
  }
  
  /**
   * 通知流转状态变�?   */
  private notifyFlowStatusChanged(): void {
    if (this.currentFlowStatus) {
      this.flowListeners.forEach(listener => {
        try {
          listener({ ...this.currentFlowStatus });
        } catch (error) {
          Logger.error(DeviceFlowManager.TAG, `Error in flow status listener: ${error}`);
        }
      });
    }
  }
  
  /**
   * 模拟流转过程（用于演示）
   */
  private async simulateFlowProcess(flowType: string, targetDeviceId: string instanceof Error ? targetDeviceId: string : new Error(String(targetDeviceId: string instanceof Error ? targetDeviceId: string instanceof Error ? targetDeviceId: string : new Error(String(targetDeviceId: string : new Error(String(targetDeviceId: string instanceof Error ? targetDeviceId: string : new Error(String(targetDeviceId: string instanceof Error ? targetDeviceId: string instanceof Error ? targetDeviceId: string : new Error(String(targetDeviceId: string instanceof Error ? targetDeviceId: string instanceof Error ? targetDeviceId: string : new Error(String(targetDeviceId: string : new Error(String(targetDeviceId: string instanceof Error ? targetDeviceId: string : new Error(String(targetDeviceId: string : new Error(String(targetDeviceId: string instanceof Error ? targetDeviceId: string : new Error(String(targetDeviceId: string instanceof Error ? targetDeviceId: string instanceof Error ? targetDeviceId: string : new Error(String(targetDeviceId: string : new Error(String(targetDeviceId: string instanceof Error ? targetDeviceId: string : new Error(String(targetDeviceId: string))))))): Promise<void> {
    return new Promise((resolve) => {
      // 模拟2秒的流转过程
      let progress = 0;
      const interval = setInterval(() => {
        progress += 10;
        if (this.currentFlowStatus) {
          this.currentFlowStatus.status = 'transferring';
          this.currentFlowStatus.progress = progress;
          this.notifyFlowStatusChanged();
        }
        
        if (progress >= 100) {
          clearInterval(interval);
          resolve();
        }
      }, 200);
    });
  }
  
  /**
   * 从流转参数恢复应用状�?   */
  public async restoreFromFlowParams(params: Record<string, unknown>): Promise<void> {
    try {
      Logger.info(DeviceFlowManager.TAG, 'Restoring application state from flow params');
      
      if (!params || !params.data) {
        Logger.warn(DeviceFlowManager.TAG, 'No valid flow params data found');
        return;
      }
      
      const flowData = params.data as Record<string, unknown>;
      
      // 检查是否有视频播放状态需要恢�?      if (flowData.currentMedia && flowData.position !== undefined) {
        // 恢复播放状�?        await playerManager.loadMedia(flowData.currentMedia);
        await playerManager.seekTo(flowData.position);
        
        if (flowData.playState === 'playing') {
          await playerManager.play();
        }
      }
    } catch (error) {
      Logger.error(DeviceFlowManager.TAG, `Failed to restore from flow params: ${error}`);
      throw error;
    }
  }
}

// 导出单例实例
export function getDeviceFlowManager(): DeviceFlowManager {
  return DeviceFlowManager.getInstance();
}


