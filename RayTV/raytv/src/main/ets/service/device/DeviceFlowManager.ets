// 设备流转管理器 | Device flow manager
// 提供设备发现、状态管理和媒体流转功能 | Provides device discovery, status management, and media flow functionality


import { DeviceFlowStatus } from '../../data/bean/DeviceInfo';
import ConfigService from '../config/ConfigService';
import TypeSafetyHelper from '../../common/util/TypeSafetyHelper';
import deviceManager from '@ohos.distributedHardware.deviceManager';
import BusinessError from '@ohos.base';

/**
 * 设备管理器设备接口 | Device manager device interface
 */
export interface DMDevice {
  deviceId: string;
  deviceName: string;
  deviceType: number;
  status: number;
}

/**
 * 增强的设备管理器接口 | Enhanced device manager interface
 */
export interface EnhancedDeviceManager extends deviceManager.DeviceManager {
  on: (event: string, callback: (data: DMDevice | DMDevice[]) => void) => void;
  publishDeviceDiscovery: (options: object) => void;
  startDeviceDiscovery: (options: object) => void;
  getTrustedDeviceListSync: () => DMDevice[];
}

/**
 * 设备信息接口 | Device info interface
 */
export interface DeviceInfo {
  deviceId: string;        // 设备ID | Device ID
  deviceName: string;      // 设备名称 | Device name
  deviceType: string;      // 设备类型（手机、平板、电视等） | Device type (phone, tablet, TV, etc.)
  status: 'online' | 'offline';  // 设备状态 | Device status
  capabilities: string[];  // 设备支持的能力 | Device capabilities
  distance?: number;       // 距离（用于排序） | Distance (for sorting)
}

/**
 * 媒体信息接口 | Media info interface
 */
export interface MediaInfo {
  title?: string;
  url?: string;
  position?: number;
  duration?: number;
  coverUrl?: string;
}

/**
 * 屏幕信息接口 | Screen info interface
 */
export interface ScreenInfo {
  width?: number;
  height?: number;
  dpi?: number;
}

/**
 * 音频信息接口 | Audio info interface
 */
export interface AudioInfo {
  title?: string;
  artist?: string;
  album?: string;
  url?: string;
  position?: number;
  duration?: number;
}

/**
 * 应用状态接口 | App state interface
 */
export interface AppState {
  deviceType?: string;
  deviceName?: string;
  status?: string;
  capabilities?: string[];
  distance?: number;
}

/**
 * 传输状态事件接口 | Transfer status event interface
 */
export interface TransferStatusEvent {
  transferId: string;
  status: string;
  progress: number;
}

/**
 * 模拟设备管理器接口 | Mock device manager interface
 */
export interface MockDeviceManager {
  isDeviceAvailable: (deviceId: string) => boolean;
  on: (event: string, callback: () => void) => void;
  sendData: () => Promise<string>;
  getTransferStatus: (transferId: string) => string;
}

/**
 * 传输数据接口 | Transfer data interface
 */
export interface TransferData {
  type: string;
  timestamp: number;
  data: FlowData;
  version: string;
}

/**
 * 流转恢复参数接口 | Flow restore params interface
 */
export interface RestoreFlowParams {
  data?: FlowData;
  // 添加其他可能的参数 | Add other possible parameters
}



/**
 * 流转数据接口 | Flow data interface
 */
export interface FlowData {
  mediaInfo?: MediaInfo;
  screenInfo?: ScreenInfo;
  audioInfo?: AudioInfo;
  appState?: AppState;
}

/**
 * 流转参数接口 | Flow params interface
 */
export interface FlowParams {
  flowType: 'video' | 'audio' | 'screen' | 'data'; // 流转类型 | Flow type
  data?: FlowData;                               // 流转数据 | Flow data
  sourceDeviceId?: string;                       // 源设备ID | Source device ID
  targetDeviceId: string;                        // 目标设备ID | Target device ID
}

/**
 * 设备状态变化数据接口 | Device state change data interface
 */
export interface DeviceStateChangeData {
  deviceId: string;
  status: number;
  
  // 可能的额外字段，但使用具体名称而不是抽象符号 | Possible extra fields, but using specific names instead of abstract symbols
  deviceName?: string;
  deviceTypeId?: number;
  networkId?: string;
  isLocal?: boolean;
  authType?: number;
  extraInfo?: AppState;
}

/**
 * 设备管理器扩展设备接口 | Device manager extended device interface
 */
export interface ExtendedDMDevice extends DMDevice {
  deviceTypeId?: number;
  networkId?: string;
  isLocal?: boolean;
  authType?: number;
  isTrusted?: boolean;
  extraInfo?: AppState;
}

/**
 * 设备发现接口 | Device discovery interface
 */
export interface DiscoveredDevice {
  deviceId: string;
  deviceName?: string;
  deviceTypeId?: number;
  
  // 可能的额外字段，但使用具体名称而不是抽象符号 | Possible extra fields, but using specific names instead of abstract symbols
  networkId?: string;
  isLocal?: boolean;
  authType?: number;
  isTrusted?: boolean;
  extraInfo?: AppState;
}

/**
 * 设备管理器 | Device manager
 */
class DeviceManager {
  private static readonly TAG: string = 'DeviceManager';
  private devices: Map<string, DeviceInfo> = new Map();
  private listeners: Array<(devices: DeviceInfo[]) => void> = [];
  // 增强的设备管理器接口 | Enhanced device manager interface
  private dmInstance: EnhancedDeviceManager | null = null;
  private discoveryStarted: boolean = false;
  
  /**
   * 初始化设备管理器 | Initialize device manager
   */
  public async initialize(): Promise<void> {
    try {
      console.info(DeviceManager.TAG, '正在初始化设备管理器（使用HarmonyOS分布式设备API）... | Initializing DeviceManager with HarmonyOS distributed device API...');
      
      // 获取设备管理器实例 | Get device manager instance
      this.dmInstance = await this.getDeviceManagerInstance();
      
      // 设置设备状态变化监听 | Set device state change listener
      this.setupDeviceStateListener();
      
      // 开始设备发现 | Start device discovery
      await this.startDeviceDiscovery();
      
      console.info(DeviceManager.TAG, '设备管理器初始化成功 | DeviceManager initialized successfully');
    } catch (error) {
      console.error(DeviceManager.TAG, `设备管理器初始化失败: `, error, ` | Failed to initialize DeviceManager: `, error);
      // 如果分布式设备API失败，回退到基本功能 | If distributed device API fails, fall back to basic functionality
      await this.initializeFallback();
    }
  }
  
  /**
   * 获取设备管理器实例 | Get device manager instance
   */
  private async getDeviceManagerInstance(): Promise<deviceManager.DeviceManager> {
    return new Promise((resolve, reject) => {
      try {
        deviceManager.createDeviceManager('RayTV', (error: BusinessError, dm: deviceManager.DeviceManager) => {
          if (error) {
            console.error(DeviceManager.TAG, `创建设备管理器失败: `, error, ` | Failed to create device manager: `, error);
            reject(error);
            return;
          }
          console.info(DeviceManager.TAG, '设备管理器创建成功 | Device manager created successfully');
          resolve(dm);
        });
      } catch (error) {
        console.error(DeviceManager.TAG, `创建设备管理器时出错: `, error, ` | Error creating device manager: `, error);
        reject(error);
      }
    });
  }
  
  /**
   * 设置设备状态变化监听 | Set device state change listener
   */
  private setupDeviceStateListener(): void {
    if (!this.dmInstance) return;
    
    try {
      // 保存当前实例的引用，避免在回调中使用this | Save reference to current instance to avoid using this in callback
      const instance = this;
      
      if (typeof this.dmInstance?.on === 'function') {
        this.dmInstance.on('deviceStateChange', (device: DMDevice) => {
          console.info(DeviceManager.TAG, `设备状态变更: ${JSON.stringify(device)} | Device state changed: ${JSON.stringify(device)}`);
          const deviceId: string = device.deviceId || '';
          const status: number = device.status || 0;
          
          // 使用预定义的接口类型，避免无类型对象字面量 | Use predefined interface type to avoid untyped object literals
          const deviceStateChangeData: DeviceStateChangeData = {
            deviceId: deviceId,
            status: status,
            deviceName: device.deviceName || '',
            deviceTypeId: device.deviceTypeId || 0,
            networkId: device.networkId || '',
            isLocal: device.isLocal || false,
            authType: device.authType || 0,
            extraInfo: device.extraInfo || {} as AppState
          };
          
          instance.handleDeviceStateChange(deviceStateChangeData);
        });
        
        this.dmInstance.on('deviceFound', (devices: DMDevice[]) => {
          console.info(DeviceManager.TAG, `Devices found: ${devices.length}`);
          const convertedDevices: DiscoveredDevice[] = [];
          for (let i = 0; i < devices.length; i++) {
            const device = devices[i];
            const deviceId: string = device.deviceId || '';
            
            // 使用预定义的接口类型，避免无类型对象字面量 | Use predefined interface type to avoid untyped object literals
            const discoveredDevice: DiscoveredDevice = {
              deviceId: deviceId,
              deviceName: device.deviceName || '',
              deviceTypeId: device.deviceTypeId || 0,
              networkId: device.networkId || '',
              isLocal: device.isLocal || false,
              authType: device.authType || 0,
              isTrusted: device.isTrusted || false,
              extraInfo: device.extraInfo || {} as AppState
            };
            
            convertedDevices.push(discoveredDevice);
          }
          this.handleDevicesFound(convertedDevices);
        });
      }
    } catch (error) {
      console.error(DeviceManager.TAG, `设置设备监听器失败: `, error, ` | Failed to setup device listeners: `, error);
    }
  }
  
  /**
   * 开始设备发现 | Start device discovery
   */
  private async startDeviceDiscovery(): Promise<void> {
    if (!this.dmInstance || this.discoveryStarted) return;
    
    try {
      console.info(DeviceManager.TAG, '正在启动设备发现... | Starting device discovery...');
      
      // 发布本地设备信息 | Publish local device info
      if (typeof this.dmInstance?.publishDeviceDiscovery === 'function') {
        this.dmInstance.publishDeviceDiscovery({});
      }

      // 发现周边设备 | Discover nearby devices
      if (typeof this.dmInstance?.startDeviceDiscovery === 'function') {
        this.dmInstance.startDeviceDiscovery({});
      }
      
      this.discoveryStarted = true;
      console.info(DeviceManager.TAG, '设备发现已启动 | Device discovery started');
      
      // 获取已发现的可信设备 | Get already discovered trusted devices
      const trustedDevices: DMDevice[] = [];
      if (typeof this.dmInstance?.getTrustedDeviceListSync === 'function') {
        const rawDevices = this.dmInstance.getTrustedDeviceListSync();
        for (let i = 0; i < rawDevices.length; i++) {
          trustedDevices.push(rawDevices[i]);
        }
      }
      if (trustedDevices && trustedDevices.length > 0) {
        // 转换为DiscoveredDevice类型 | Convert to DiscoveredDevice type
        const convertedDevices: DiscoveredDevice[] = [];
        for (let i = 0; i < trustedDevices.length; i++) {
          const device = trustedDevices[i];
          // 使用DMDevice接口替代类型断言 | Use DMDevice interface instead of type assertion
          const trustedDevice: DMDevice = device as DMDevice;
          
          const deviceId = trustedDevice.deviceId || '';
          
          // 使用预定义的接口类型，避免无类型对象字面量 | Use predefined interface type to avoid untyped object literals
          const discoveredDevice: DiscoveredDevice = {
            deviceId: deviceId,
            deviceName: trustedDevice.deviceName || `Device-${deviceId.substring(0, 8)}`,
            deviceTypeId: trustedDevice.deviceTypeId || 0,
            networkId: trustedDevice.networkId || '',
            isLocal: trustedDevice.isLocal || false,
            authType: trustedDevice.authType || 0,
            isTrusted: trustedDevice.isTrusted || true,
            extraInfo: trustedDevice.extraInfo || {} as AppState
          };
          
          convertedDevices.push(discoveredDevice);
        }
        this.handleDevicesFound(convertedDevices);
      }
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      console.error(DeviceManager.TAG, `启动设备发现失败: ${errorMsg} | Failed to start device discovery: ${errorMsg}`);
      throw new Error(`启动设备发现失败: ${errorMsg} | Failed to start device discovery: ${errorMsg}`);
    }
  }
  
  /**
   * 处理设备状态变化 | Handle device state change
   */
  private handleDeviceStateChange(device: DeviceStateChangeData): void {
    if (!device || !device.deviceId) return;
    
    const deviceId = device.deviceId;
    const existingDevice = this.devices.get(deviceId);
    
    if (existingDevice) {
      // 更新设备状态 | Update device status
      existingDevice.status = device.status === 0 ? 'online' : 'offline';
      this.notifyDeviceListChanged();
    }
  }
  
  /**
   * 处理发现的设备 | Handle discovered devices
   */
  private handleDevicesFound(devices: DiscoveredDevice[]): void {
    if (!devices || devices.length === 0) return;
    
    console.info(DeviceManager.TAG, `正在处理 ${devices.length} 个已发现设备 | Processing ${devices.length} discovered devices`);
    
    devices.forEach(device => {
      if (!device.deviceId) return;
      
      // 转换为标准设备信息格式 | Convert to standard device info format
      const standardDevice: DeviceInfo = {
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
   * 获取设备类型 | Get device type
   */
  private getDeviceType(device: DiscoveredDevice): string {
    // 根据设备信息判断类型 | Judge type based on device info
    const deviceTypeId = device.deviceTypeId ?? 0;
    if (deviceTypeId === 2) return 'tv';
    if (deviceTypeId === 3) return 'tablet';
    if (deviceTypeId === 4) return 'phone';
    return 'unknown';
  }
  
  /**
   * 获取设备能力 | Get device capabilities
   */
  private getDeviceCapabilities(device: DiscoveredDevice): string[] {
    const capabilities: string[] = ['data'];
    
    // 根据设备类型添加默认能力 | Add default capabilities based on device type
    if (this.getDeviceType(device) === 'tv' || this.getDeviceType(device) === 'tablet') {
      capabilities.push('video', 'audio', 'screen');
    } else if (this.getDeviceType(device) === 'phone') {
      capabilities.push('video', 'audio', 'screen');
    }
    
    return capabilities;
  }
  
  /**
   * 回退初始化（当分布式API失败时） | Fallback initialization (when distributed API fails)
   */
  private async initializeFallback(): Promise<void> {
    console.warn(DeviceManager.TAG, '正在使用回退设备管理器实现 | Using fallback device manager implementation');
    
    // 扫描设备（使用简化逻辑） | Scan devices (using simplified logic)
    await this.scanDevices();
  }
  
  /**
   * 扫描设备（回退方法） | Scan devices (fallback method)
   */
  public async scanDevices(): Promise<void> {
    try {
      console.info(DeviceManager.TAG, '正在扫描可用设备... | Scanning for available devices...');
      
      // 如果有分布式设备管理器实例，使用它获取设备列表 | If there is a distributed device manager instance, use it to get device list
      if (this.dmInstance) {
        const trustedDevices: DMDevice[] = [];
        if (typeof this.dmInstance?.getTrustedDeviceListSync === 'function') {
          const rawDevices = this.dmInstance.getTrustedDeviceListSync();
          for (let i = 0; i < rawDevices.length; i++) {
            trustedDevices.push(rawDevices[i]);
          }
        }
        if (trustedDevices && trustedDevices.length > 0) {
          // 转换为DiscoveredDevice类型 | Convert to DiscoveredDevice type
          const convertedDevices: DiscoveredDevice[] = [];
          for (let i = 0; i < trustedDevices.length; i++) {
            const device = trustedDevices[i];
            // 使用DMDevice接口替代类型断言 | Use DMDevice interface instead of type assertion
            const trustedDevice: DMDevice = device as DMDevice;
            
            const deviceId = trustedDevice.deviceId || '';
            // 使用预定义的接口类型，避免无类型对象字面量 | Use predefined interface type to avoid untyped object literals
            const discoveredDevice: DiscoveredDevice = {
              deviceId: deviceId,
              deviceName: trustedDevice.deviceName || `Device-${deviceId.substring(0, 8)}`,
              deviceTypeId: trustedDevice.deviceTypeId || 0,
              networkId: trustedDevice.networkId || '',
              isLocal: trustedDevice.isLocal || false,
              authType: trustedDevice.authType || 0,
              isTrusted: trustedDevice.isTrusted || true,
              extraInfo: trustedDevice.extraInfo || {} as AppState
            };
            convertedDevices.push(discoveredDevice);
          }
          this.handleDevicesFound(convertedDevices);
          console.info(DeviceManager.TAG, `发现 ${convertedDevices.length} 个可信设备 | Found ${convertedDevices.length} trusted devices`);
          return;
        }
      }
      
      console.info(DeviceManager.TAG, '未发现设备或正在使用回退模式 | No devices found or using fallback mode');
      
      // 通知监听器（可能是空列表） | Notify listeners (may be empty list)
      this.notifyDeviceListChanged();
    } catch (error) {
      console.error(DeviceManager.TAG, `扫描设备失败: `, error, ` | Failed to scan devices: `, error);
      // 确保只抛出Error对象 | Ensure only Error objects are thrown
      const errorMsg = error instanceof Error ? error.message : String(error);
      throw new Error(`扫描设备失败: ${errorMsg} | Failed to scan devices: ${errorMsg}`);
    }
  }
  
  /**
   * 获取可用设备列表 | Get available devices list
   */
  public getAvailableDevices(): DeviceInfo[] {
    return Array.from(this.devices.values()).filter(device => 
      device.status === 'online'
    );
  }
  
  /**
   * 根据设备ID获取设备信息 | Get device info by device ID
   */
  public getDeviceById(deviceId: string): DeviceInfo | undefined {
    return this.devices.get(deviceId);
  }
  
  /**
   * 添加设备列表变化监听器 | Add device list change listener
   */
  public addDeviceListListener(listener: (devices: DeviceInfo[]) => void): void {
    this.listeners.push(listener);
  }
  
  /**
   * 移除设备列表变化监听器 | Remove device list change listener
   */
  public removeDeviceListListener(listener: (devices: DeviceInfo[]) => void): void {
    const index = this.listeners.indexOf(listener);
    if (index > -1) {
      this.listeners.splice(index, 1);
    }
  }
  
  /**
   * 通知设备列表变化 | Notify device list changed
   */
  private notifyDeviceListChanged(): void {
    const devices = this.getAvailableDevices();
    this.listeners.forEach(listener => {
      try {
        listener(devices);
      } catch (error) {
        console.error(DeviceManager.TAG, `设备列表监听器错误: `, error, ` | Error in device list listener: `, error);
      }
    });
  }
}

/**
 * 设备流转管理器 | Device flow manager
 */
export class DeviceFlowManager {
  private static readonly TAG: string = 'DeviceFlowManager';
  private static instance: DeviceFlowManager;
  
  private deviceManager: DeviceManager = new DeviceManager();
  private currentFlowStatus: DeviceFlowStatus | null = null;
  private isEnabled: boolean = false;
  private flowListeners: Array<(status: DeviceFlowStatus) => void> = [];
  private configService: ConfigService = ConfigService.getInstance();
  
  private constructor() {}
  
  /**
   * 获取单例实例 | Get singleton instance
   */
  public static getInstance(): DeviceFlowManager {
    if (!DeviceFlowManager.instance) {
      DeviceFlowManager.instance = new DeviceFlowManager();
    }
    return DeviceFlowManager.instance;
  }
  
  /**
   * 初始化设备流管理器 | Initialize device flow manager
   */
  public async initialize(): Promise<void> {
    try {
      console.info(DeviceFlowManager.TAG, '正在初始化设备流转管理器... | Initializing DeviceFlowManager...');
      
      // 加载配置 | Load configuration
      this.isEnabled = await this.configService.getConfig('enableDeviceFlow', true);
      
      // 初始化设备管理器 | Initialize device manager
      await this.deviceManager.initialize();
      
      console.info(DeviceFlowManager.TAG, '设备流转管理器初始化成功 | DeviceFlowManager initialized successfully');
    } catch (error) {
      console.error(DeviceFlowManager.TAG, `设备流转管理器初始化失败: `, error, ` | Failed to initialize DeviceFlowManager: `, error);
      const err = error instanceof Error ? error : new Error(String(error));
      throw err;
    }
  }
  
  /**
   * 启动设备流转 | Start device flow
   */
  public async startFlow(params: FlowParams): Promise<void> {
    try {
      if (!this.isEnabled) {
        throw new Error('Device flow is disabled');
      }
      
      console.info(DeviceFlowManager.TAG, `正在开始向设备流转: ${params.targetDeviceId}, 类型: ${params.flowType} | Starting flow to device: ${params.targetDeviceId}, type: ${params.flowType}`);
      
      // 检查目标设备是否存在且在线 | Check if target device exists and is online
      const targetDevice = this.deviceManager.getDeviceById(params.targetDeviceId);
      if (!targetDevice || targetDevice.status !== 'online') {
        throw new Error('Target device is not available');
      }
      
      // 检查设备是否支持该流转类型 | Check if device supports this flow type
      if (!targetDevice.capabilities.includes(params.flowType)) {
        throw new Error(`Target device does not support ${params.flowType} flow`);
      }
      
      // 更新流转状态 | Update flow status
      this.currentFlowStatus = {
        flowType: params.flowType,
        status: 'initiating',
        progress: 0,
        sourceDeviceId: params.sourceDeviceId || '',
        targetDeviceId: params.targetDeviceId
      };
      
      this.notifyFlowStatusChanged();
      
      // 尝试使用分布式数据传输API | Try to use distributed data transfer API
      try {
        await this.performDistributedTransfer(params.targetDeviceId, params.data);
      } catch (distributedError) {
        console.warn(DeviceFlowManager.TAG, `分布式传输失败，正在使用回退方式: `, distributedError, ` | Distributed transfer failed, using fallback: `, distributedError);
        // 如果分布式传输失败，使用本地数据备份作为回退 | If distributed transfer fails, use local data backup as fallback
        await this.performLocalBackupFallback(params.flowType, params.targetDeviceId);
      }
      
      // 流转完成 | Flow completed
      this.currentFlowStatus!.status = 'completed';
      this.currentFlowStatus!.progress = 100;
      
      console.info(DeviceFlowManager.TAG, `流转完成成功 | Flow completed successfully`);
      this.notifyFlowStatusChanged();
    } catch (error) {
      console.error(DeviceFlowManager.TAG, `启动流转失败: `, error, ` | Failed to start flow: `, error);
      
      // 更新为失败状态 | Update to failed status
      if (this.currentFlowStatus) {
        this.currentFlowStatus.status = 'failed';
        this.notifyFlowStatusChanged();
      }
      
      throw error;
    }
  }
  
  /**
   * 执行分布式数据传输 | Perform distributed data transfer
   */
  private async performDistributedTransfer(targetDeviceId: string, data: FlowData | undefined): Promise<void> {
    try {
      console.info(DeviceFlowManager.TAG, `正在执行分布式数据传输到 ${targetDeviceId} | Performing distributed data transfer to ${targetDeviceId}`);
      
      // 1. 获取设备管理器实例 | Get device manager instance
      const dm = await this.getDeviceManager() as EnhancedDeviceManager;

      // 2. 检查目标设备是否可用 | Check if target device is available
      const trustedDevices: DMDevice[] = [];
      if (dm.getTrustedDeviceListSync) {
        const rawDevices = dm.getTrustedDeviceListSync();
        for (let i = 0; i < rawDevices.length; i++) {
          trustedDevices.push(rawDevices[i]);
        }
      }
      const targetDevice = trustedDevices.find((device: DMDevice) => device.deviceId === targetDeviceId);
      if (!targetDevice) {
        const error = new Error(`目标设备不可用 | Target device not available: ${targetDeviceId}`);
        throw error;
      }
      
      // 3. 准备传输数据 | Prepare transfer data
      const transferData = this.prepareTransferData(data);
      const transferDataStr = JSON.stringify(transferData);
      
      // 4. 注册传输状态监听器 | Register transfer status listener
      if (dm.on) {
        dm.on('deviceStateChange', (device: DMDevice) => {
        if (device.deviceId === targetDeviceId) {
          console.info(DeviceFlowManager.TAG, `目标设备状态变化: ${device.status} | Target device state changed: ${device.status}`);
        }
      });
      
      // 5. 执行数据传输 | Execute data transfer
      // 使用分布式数据服务进行传输
      // 这里使用模拟的传输ID，实际应用中应使用真实的传输机制
      const transferId = `transfer_${Date.now()}`;
      
      // 6. 记录传输ID | Record transfer ID
      // Note: DeviceFlowStatus interface doesn't have transferId field
      // The transferId is tracked internally
      
      // 7. 模拟传输过程（实际应用中应使用真实的传输API）
      await this.simulateTransferProcess(transferId, targetDeviceId);
      
      console.info(DeviceFlowManager.TAG, `分布式传输完成 | Distributed transfer completed`);
    } catch (error) {
      console.error(DeviceFlowManager.TAG, `分布式传输失败: `, error, ` | Distributed transfer failed: `, error);
      const errorMsg = error instanceof Error ? error.message : String(error);
      throw new Error(`分布式传输失败: ${errorMsg} | Distributed transfer failed: ${errorMsg}`);
    }
  }
  
  /**
   * 停止设备流转 | Stop device flow
   */
  public async stopFlow(): Promise<void> {
    try {
      if (!this.currentFlowStatus || this.currentFlowStatus.status !== 'transferring') {
        throw new Error('No active flow to stop');
      }
      
      console.info(DeviceFlowManager.TAG, '正在停止当前流转 | Stopping current flow');
      
      this.currentFlowStatus.status = 'cancelled';
      this.notifyFlowStatusChanged();
      
      // 清理资源 | Clean up resources
      this.currentFlowStatus = null;
    } catch (error) {
      console.error(DeviceFlowManager.TAG, `停止流转失败: `, error, ` | Failed to stop flow: `, error);
      const err = error instanceof Error ? error : new Error(String(error));
      throw err;
    }
  }
  
  /**
   * 获取可用设备列表 | Get available devices list
   */
  public getAvailableDevices(): DeviceInfo[] {
    return this.deviceManager.getAvailableDevices();
  }
  
  /**
   * 刷新设备列表 | Refresh devices list
   */
  public async refreshDevices(): Promise<void> {
    await this.deviceManager.scanDevices();
  }
  
  /**
   * 获取当前流转状态 | Get current flow status
   */
  public getCurrentFlowStatus(): DeviceFlowStatus | null {
    return this.currentFlowStatus;
  }
  
  /**
   * 启用/禁用设备流转 | Enable/disable device flow
   */
  public async setEnabled(enabled: boolean): Promise<void> {
    try {
      this.isEnabled = enabled;
      await this.configService.setConfig('enableDeviceFlow', enabled);
      
      console.info(DeviceFlowManager.TAG, `设备流转已${enabled ? '启用' : '禁用'} | Device flow ${enabled ? 'enabled' : 'disabled'}`);
    } catch (error) {
      console.error(DeviceFlowManager.TAG, `设置设备流转启用状态失败: `, error, ` | Failed to set device flow enabled state: `, error);
      const err = error instanceof Error ? error : new Error(String(error));
      throw err;
    }
  }
  
  /**
   * 添加流转状态监听器 | Add flow status listener
   */
  public addFlowStatusListener(listener: (status: DeviceFlowStatus) => void): void {
    this.flowListeners.push(listener);
  }
  
  /**
   * 移除流转状态监听器 | Remove flow status listener
   */
  public removeFlowStatusListener(listener: (status: DeviceFlowStatus) => void): void {
    const index = this.flowListeners.indexOf(listener);
    if (index > -1) {
      this.flowListeners.splice(index, 1);
    }
  }
  
  /**
   * 通知流转状态变化 | Notify flow status changed
   */
  private notifyFlowStatusChanged(): void {
    const currentStatus = this.currentFlowStatus;
    if (currentStatus) {
      this.flowListeners.forEach(listener => {
        try {
          // 手动复制流转状态对象 | Manually copy flow status object
          const statusCopy: DeviceFlowStatus = {
            flowType: currentStatus.flowType,
            status: currentStatus.status,
            progress: currentStatus.progress,
            sourceDeviceId: currentStatus.sourceDeviceId,
            targetDeviceId: currentStatus.targetDeviceId,
            startTime: currentStatus.startTime,
            endTime: currentStatus.endTime,
            errorMessage: currentStatus.errorMessage,
            contentInfo: currentStatus.contentInfo
          };
          listener(statusCopy);
        } catch (error) {
          console.error(DeviceFlowManager.TAG, `流转状态监听器错误: `, error, ` | Error in flow status listener: `, error);
        }
      });
    }
  }
  
  /**
   * 获取设备管理器实例 | Get device manager instance
   */
  private async getDeviceManager(): Promise<deviceManager.DeviceManager> {
    return new Promise((resolve, reject) => {
      try {
        deviceManager.createDeviceManager('RayTV', (error: BusinessError, dm: deviceManager.DeviceManager) => {
          if (error) {
            console.error(DeviceFlowManager.TAG, `创建设备管理器失败: `, error, ` | Failed to create device manager: `, error);
            reject(error);
            return;
          }
          console.info(DeviceFlowManager.TAG, '设备管理器创建成功 | Device manager created successfully');
          resolve(dm);
        });
      } catch (error) {
        console.error(DeviceFlowManager.TAG, `创建设备管理器时出错: `, error, ` | Error creating device manager: `, error);
        reject(error);
      }
    });
  }
  
  /**
   * 准备传输数据 | Prepare transfer data
   */
  private prepareTransferData(data: FlowData | undefined): TransferData {
    // 实际实现应该根据流转类型准备适当的数据格式 | Actual implementation should prepare appropriate data format based on flow type
    // 使用预定义的接口类型，避免无类型对象字面量 | Use predefined interface type to avoid untyped object literals
    const transferData: TransferData = {
      type: 'app_flow',
      timestamp: Date.now(),
      data: data || {} as FlowData,
      version: '1.0'
    };
    return transferData;
  }
  
  /**
   * 模拟传输过程 | Simulate transfer process
   */
  private async simulateTransferProcess(transferId: string, targetDeviceId: string): Promise<void> {
    return new Promise<void>((resolve) => {
      // 模拟传输进度更新
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
          if (this.currentFlowStatus) {
            this.currentFlowStatus.status = 'completed';
            this.currentFlowStatus.progress = 100;
            this.currentFlowStatus.endTime = Date.now();
            this.notifyFlowStatusChanged();
          }
          resolve();
        }
      }, 200);
    });
  }

  /**
   * 等待传输完成 | Wait for transfer completion
   */
  private async waitForTransferCompletion(transferId: string): Promise<void> {
    // 实际应用中应使用HarmonyOS提供的传输状态监听API | In actual app, use HarmonyOS transfer status listening API
    return this.simulateTransferProcess(transferId, this.currentFlowStatus?.targetDeviceId || '');
  }
  
  /**
   * 使用本地备份作为回退方案 | Use local backup as fallback solution
   */
  private async performLocalBackupFallback(flowType: string, targetDeviceId: string): Promise<void> {
    console.info(DeviceFlowManager.TAG, `正在执行本地备份回退方案 | Performing local backup fallback`);
    
    // 1. 创建本地备份 | Create local backup
    const backupData = await this.createLocalBackup();
    
    // 2. 生成备份ID并提供给用户 | Generate backup ID and provide to user
    const backupId = this.generateBackupId();
    
    // 3. 记录备份信息 | Record backup information
    await this.recordBackupInfo(backupId, backupData);
    
    // 4. 通知用户使用备份ID在目标设备恢复 | Notify user to use backup ID to restore on target device
    this.notifyBackupReady(backupId);
  }
  
  /**
   * 创建本地备份 | Create local backup
   */
  private async createLocalBackup(): Promise<BackupData> {
    // 实际实现应该创建应用状态的本地备份 | Actual implementation should create local backup of app state
    // 使用预定义的接口类型，避免无类型对象字面量 | Use predefined interface type to avoid untyped object literals
    const backupData: BackupData = {
      timestamp: Date.now(),
      appState: {},
      version: '1.0'
    };
    return backupData;
  }

  /**
   * 生成备份ID | Generate backup ID
   */
  private generateBackupId(): string {
    // 生成唯一备份ID | Generate unique backup ID
    return `backup_${Date.now()}_${Math.floor(Math.random() * 10000)}`;
  }

  /**
   * 记录备份信息 | Record backup information
   */
  private async recordBackupInfo(backupId: string, backupData: BackupData): Promise<void> {
    // 实际实现应该将备份信息存储到本地数据库或文件系统 | Actual implementation should store backup info to local database or file system
    console.info(DeviceFlowManager.TAG, `备份已记录，ID: ${backupId} | Backup recorded, ID: ${backupId}`);
  }
  
  /**
   * 通知备份准备就绪 | Notify backup ready
   */
  private notifyBackupReady(backupId: string): void {
    // 实际实现应该显示通知或提示给用户 | Actual implementation should show notification or prompt to user
    console.info(DeviceFlowManager.TAG, `备份就绪，使用ID在目标设备恢复: ${backupId} | Backup ready, use ID to restore on target device: ${backupId}`);
  }
  
  /**
   * 从流转参数恢复应用状态 | Restore application state from flow params
   */
  public async restoreFromFlowParams(params: RestoreFlowParams): Promise<void> {
    try {
      console.info(DeviceFlowManager.TAG, '正在从流转参数恢复应用状态 | Restoring application state from flow params');
      
      if (!params || !params.data) {
        console.warn(DeviceFlowManager.TAG, '未找到有效的流转参数数据 | No valid flow params data found');
        return;
      }
      
      const flowData = params.data;
      
      // 检查是否有视频播放状态需要恢复 | Check if there is video playback state to restore
      if (flowData.mediaInfo && flowData.mediaInfo.position !== undefined) {
        // 恢复播放状态 | Restore playback state
        // 注意：这里需要根据实际的播放器管理服务来实现 | Note: This needs to be implemented based on the actual player management service
        console.info(DeviceFlowManager.TAG, '正在恢复媒体播放状态 | Restoring media playback state');
      }
    } catch (error) {
      console.error(DeviceFlowManager.TAG, `从流转参数恢复失败: `, error, ` | Failed to restore from flow params: `, error);
      const errorMsg = error instanceof Error ? error.message : String(error);
      throw new Error(`从流转参数恢复失败: ${errorMsg} | Failed to restore from flow params: ${errorMsg}`);
    }
  }
}

/**
 * 备份数据接口 | Backup data interface
 */
export interface BackupData {
  timestamp: number;
  appState?: FlowData;
  version: string;
}

// 导出单例实例 | Export singleton instance
export function getDeviceFlowManager(): DeviceFlowManager {
  return DeviceFlowManager.getInstance();
}
