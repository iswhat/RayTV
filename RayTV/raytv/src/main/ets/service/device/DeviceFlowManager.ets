import Logger from '@ohos/base/Logger';
import { DeviceFlowStatus } from '../../data/bean/DeviceInfo';
import { configService } from '../config/ConfigService';
import { playerManager } from '../media/PlayerManager';

/**
 * 设备信息接口
 */
export interface DeviceInfo {
  deviceId: string;        // 设备ID
  deviceName: string;      // 设备名称
  deviceType: string;      // 设备类型（手机、平板、电视等）
  status: 'online' | 'offline';  // 设备状态
  capabilities: string[];  // 设备支持的能力
  distance?: number;       // 距离（用于排序）
}

/**
 * 流转参数接口
 */
export interface FlowParams {
  flowType: 'video' | 'audio' | 'screen' | 'data'; // 流转类型
  data?: any;              // 流转数据
  sourceDeviceId?: string; // 源设备ID
  targetDeviceId: string;  // 目标设备ID
}

/**
 * 设备管理器
 */
class DeviceManager {
  private static readonly TAG: string = 'DeviceManager';
  private devices: Map<string, DeviceInfo> = new Map();
  private listeners: Array<(devices: DeviceInfo[]) => void> = [];
  
  /**
   * 初始化设备管理器
   */
  public async initialize(): Promise<void> {
    try {
      Logger.info(DeviceManager.TAG, 'Initializing DeviceManager...');
      
      // 这里应该调用HarmonyOS的分布式设备API
      // 暂时使用模拟数据
      await this.scanDevices();
      
      Logger.info(DeviceManager.TAG, 'DeviceManager initialized successfully');
    } catch (error) {
      Logger.error(DeviceManager.TAG, `Failed to initialize DeviceManager: ${error}`);
      throw error;
    }
  }
  
  /**
   * 扫描设备
   */
  public async scanDevices(): Promise<void> {
    try {
      Logger.info(DeviceManager.TAG, 'Scanning for available devices...');
      
      // 模拟扫描到的设备
      const mockDevices: DeviceInfo[] = [
        {
          deviceId: 'device1',
          deviceName: '客厅电视',
          deviceType: 'tv',
          status: 'online',
          capabilities: ['video', 'audio', 'screen']
        },
        {
          deviceId: 'device2',
          deviceName: '卧室平板',
          deviceType: 'tablet',
          status: 'online',
          capabilities: ['video', 'audio', 'data']
        },
        {
          deviceId: 'device3',
          deviceName: '手机',
          deviceType: 'phone',
          status: 'online',
          capabilities: ['video', 'audio', 'screen', 'data']
        }
      ];
      
      // 更新设备列表
      this.devices.clear();
      mockDevices.forEach(device => {
        this.devices.set(device.deviceId, device);
      });
      
      // 通知监听器
      this.notifyDeviceListChanged();
      
      Logger.info(DeviceManager.TAG, `Found ${mockDevices.length} devices`);
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
   * 添加设备列表变化监听器
   */
  public addDeviceListListener(listener: (devices: DeviceInfo[]) => void): void {
    this.listeners.push(listener);
  }
  
  /**
   * 移除设备列表变化监听器
   */
  public removeDeviceListListener(listener: (devices: DeviceInfo[]) => void): void {
    const index = this.listeners.indexOf(listener);
    if (index > -1) {
      this.listeners.splice(index, 1);
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
 * 设备流转管理器
 */
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
      Logger.info(DeviceFlowManager.TAG, 'Initializing DeviceFlowManager...');
      
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
      
      Logger.info(DeviceFlowManager.TAG, `Starting flow to device: ${params.targetDeviceId}, type: ${params.flowType}`);
      
      // 检查目标设备是否存在且在线
      const targetDevice = this.deviceManager.getDeviceById(params.targetDeviceId);
      if (!targetDevice || targetDevice.status !== 'online') {
        throw new Error('Target device is not available');
      }
      
      // 检查设备是否支持该流转类型
      if (!targetDevice.capabilities.includes(params.flowType)) {
        throw new Error(`Target device does not support ${params.flowType} flow`);
      }
      
      // 更新流转状态
      this.currentFlowStatus = {
        flowType: params.flowType,
        status: 'initiating',
        progress: 0,
        sourceDeviceId: params.sourceDeviceId,
        targetDeviceId: params.targetDeviceId
      };
      
      this.notifyFlowStatusChanged();
      
      // 如果是视频流转，保存当前播放状态
      let flowData = params.data;
      if (params.flowType === 'video' && !flowData) {
        flowData = {
          currentMedia: playerManager.getCurrentMedia(),
          position: playerManager.getCurrentPosition(),
          playState: playerManager.isPlaying() ? 'playing' : 'paused'
        };
      }
      
      // 模拟流转过程
      await this.simulateFlowProcess(params.flowType, params.targetDeviceId);
      
      // 流转完成
      this.currentFlowStatus.status = 'completed';
      this.currentFlowStatus.progress = 100;
      
      Logger.info(DeviceFlowManager.TAG, `Flow completed successfully`);
      this.notifyFlowStatusChanged();
    } catch (error) {
      Logger.error(DeviceFlowManager.TAG, `Failed to start flow: ${error}`);
      
      // 更新为失败状态
      if (this.currentFlowStatus) {
        this.currentFlowStatus.status = 'failed';
        this.notifyFlowStatusChanged();
      }
      
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
      
      Logger.info(DeviceFlowManager.TAG, 'Stopping current flow');
      
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
   * 获取当前流转状态
   */
  public getCurrentFlowStatus(): DeviceFlowStatus | null {
    return this.currentFlowStatus;
  }
  
  /**
   * 启用/禁用设备流转
   */
  public async setEnabled(enabled: boolean): Promise<void> {
    try {
      this.isEnabled = enabled;
      await configService.setConfig('enableDeviceFlow', enabled);
      
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
      this.flowListeners.splice(index, 1);
    }
  }
  
  /**
   * 通知流转状态变化
   */
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
  private async simulateFlowProcess(flowType: string, targetDeviceId: string): Promise<void> {
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
   * 从流转参数恢复应用状态
   */
  public async restoreFromFlowParams(params: any): Promise<void> {
    try {
      Logger.info(DeviceFlowManager.TAG, 'Restoring application state from flow params');
      
      // 检查是否有视频播放状态需要恢复
      if (params.currentMedia && params.position !== undefined) {
        // 恢复播放状态
        await playerManager.loadMedia(params.currentMedia);
        await playerManager.seekTo(params.position);
        
        if (params.playState === 'playing') {
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
export const deviceFlowManager = DeviceFlowManager.getInstance();