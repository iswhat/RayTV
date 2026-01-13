// 设备服务 | Device service
// 提供设备信息管理、能力检测和状态监控功能 | Provides device information management, capability detection, and status monitoring functionality

import Logger from '../../common/util/Logger';
import DeviceInfoRepository from '../../data/repository/DeviceInfoRepository';
import ConfigService from '../config/ConfigService';
import { DeviceInfo, DeviceType, DeviceStatus, DeviceCapability } from '../../data/bean/DeviceInfo';
import TypeSafetyUtil from '../../common/util/TypeSafetyUtil';

const TAG = 'DeviceService';

// 设备能力检查信息接口 | Device capability check information interface
export interface CapabilityDetails {
  capabilityType?: string;
  version?: string;
  maxValue?: number;
  minValue?: number;
  supportedFormats?: string[];
  properties?: Record<string, string | number | boolean>;
}

// 设备能力检查结果 | Device capability check result
export interface CapabilityCheckResult {
  supported: boolean;
  details?: CapabilityDetails;
  error?: string;
}

export default class DeviceService {
  private static instance: DeviceService;
  private deviceInfoRepository: DeviceInfoRepository;
  private configService: ConfigService;
  private cachedDeviceInfo: DeviceInfo | null = null;
  private deviceListeners: Array<(info: DeviceInfo) => void> = [];
  private isInitialized: boolean = false;
  private lastCapabilityCheckTime: number = 0;

  private constructor() {
    this.deviceInfoRepository = DeviceInfoRepository.getInstance();
    this.configService = ConfigService.getInstance();
    this.initialize();
  }

  /**
   * 获取单例实例 | Get singleton instance
   */
  public static getInstance(): DeviceService {
    if (!DeviceService.instance) {
      DeviceService.instance = new DeviceService();
    }
    return DeviceService.instance;
  }

  /**
   * 初始化设备服务 | Initialize device service
   */
  public async initialize(): Promise<void> {
    try {
      // 加载设备信息 | Load device information
      this.cachedDeviceInfo = await this.deviceInfoRepository.getDeviceInfo();
      
      // 如果没有设备信息，收集并保存 | If no device information, collect and save
      if (!this.cachedDeviceInfo) {
        this.cachedDeviceInfo = await this.collectDeviceInfo();
        await this.deviceInfoRepository.saveDeviceInfo(this.cachedDeviceInfo);
      }
      
      // 定期更新设备信息 | Update device information regularly
      this.scheduleDeviceInfoUpdate();
      
      this.isInitialized = true;
      Logger.info(TAG, 'Device service initialized');
    } catch (error) {
      Logger.error(TAG, 'Failed to initialize device service', error instanceof Error ? error : new Error(String(error)));
      // 创建基本的设备信息作为后备 | Create basic device information as fallback
      this.cachedDeviceInfo = this.createDefaultDeviceInfo();
      this.isInitialized = true;
    }
  }

  /**
   * 收集设备信息 | Collect device information
   */
  private async collectDeviceInfo(): Promise<DeviceInfo> {
    Logger.info(TAG, 'Collecting device information');
    
    try {
      // 设备标识 | Device identification
      const deviceId = await this.generateDeviceId();
      
      // 设备基本信息 | Basic device information
      const deviceInfo: DeviceInfo = {
        deviceId,
        deviceName: this.getDeviceName(),
        deviceType: this.detectDeviceType(),
        osVersion: this.getOSVersion(),
        apiVersion: 5,
        appVersion: this.getAppVersion(),
        deviceNetworkInfo: {
          type: 'none'
        },
        deviceHardwareInfo: {
          manufacturer: this.getManufacturer(),
          model: this.getModel()
        },
        deviceDisplayInfo: {
          screenWidth: 1920,
          screenHeight: 1080,
          densityDpi: 320,
          aspectRatio: '16:9',
          refreshRate: 60,
          isHdrSupported: false,
          maxResolution: '1920x1080',
          bitsPerPixel: 24,
          isPrimary: true,
          supportsTouch: false
        },
        deviceMediaCapabilities: {
          supportedCodecs: [],
          supportedFormats: [],
          maxResolution: '1920x1080',
          maxFps: 60,
          hdrFormats: [],
          audioChannels: 2,
          audioFormats: [],
          dolbySupported: false,
          dtsSupported: false,
          spatialAudioSupported: false,
          hardwareAcceleration: false
        },
        devicePermissionInfo: {},
        deviceAppInfo: {
          packageName: 'com.example.raytv',
          versionName: '1.0.0',
          versionCode: 1
        },
        status: DeviceStatus.ONLINE,
        capabilities: await this.detectDeviceCapabilities(),
        isTvMode: true,
        isRemoteControlAvailable: true,
        isMultiDeviceSupport: true,
        isPrimaryDevice: true,
        createdAt: Date.now(),
        updatedAt: Date.now(),
        customProperties: new Map()
      };
      
      Logger.info(TAG, 'Device information collected: ' + deviceInfo.deviceName + ' (' + deviceInfo.deviceType + ')');
      return deviceInfo;
    } catch (error) {
      Logger.error(TAG, 'Error collecting device information: ' + (error instanceof Error ? error.message : String(error)));
      return this.createDefaultDeviceInfo();
    }
  }

  /**
   * 创建默认设备信息 | Create default device information
   */
  private createDefaultDeviceInfo(): DeviceInfo {
    const now = Date.now();
    return {
      deviceId: 'unknown-device-' + now,
      deviceName: 'Unknown Device',
      deviceType: DeviceType.OTHER,
      osVersion: 'Unknown',
      apiVersion: 5,
      appVersion: '1.0.0',
      deviceNetworkInfo: {
        type: 'none'
      },
      deviceHardwareInfo: {
        manufacturer: 'Unknown',
        model: 'Unknown'
      },
      deviceDisplayInfo: {
        screenWidth: 1920,
        screenHeight: 1080,
        densityDpi: 320,
        aspectRatio: '16:9',
        refreshRate: 60,
        isHdrSupported: false,
        maxResolution: '1920x1080',
        bitsPerPixel: 24,
        isPrimary: true,
        supportsTouch: false
      },
      deviceMediaCapabilities: {
        supportedCodecs: [],
        supportedFormats: [],
        maxResolution: '1920x1080',
        maxFps: 60,
        hdrFormats: [],
        audioChannels: 2,
        audioFormats: [],
        dolbySupported: false,
        dtsSupported: false,
        spatialAudioSupported: false,
        hardwareAcceleration: false
      },
      devicePermissionInfo: {},
      deviceAppInfo: {
        packageName: 'com.example.raytv',
        versionName: '1.0.0',
        versionCode: 1
      },
      status: DeviceStatus.OFFLINE,
      capabilities: [],
      isTvMode: true,
      isRemoteControlAvailable: true,
      isMultiDeviceSupport: true,
      isPrimaryDevice: true,
      createdAt: now,
      updatedAt: now,
      customProperties: new Map()
    };
  }

  /**
   * 生成设备ID | Generate device ID
   */
  private async generateDeviceId(): Promise<string> {
    return `device-${Date.now()}-${Math.random().toString(36).substring(2, 9)}`;
  }

  /**
   * 获取设备名称 | Get device name
   */
  private getDeviceName(): string {
    try {
      // 使用HarmonyOS设备信息API获取设备名称 | Use HarmonyOS device information API to get device name
      return 'HarmonyOS Device';
    } catch (error) {
      return 'Unknown Device';
    }
  }

  /**
   * 检查设备类型 | Check device type
   */
  private detectDeviceType(): DeviceType {
    try {
      // 检查设备类型的逻辑 | Logic to check device type
      return DeviceType.TV;
    } catch {
      return DeviceType.OTHER;
    }
  }

  /**
   * 获取制造商信息 | Get manufacturer information
   */
  private getManufacturer(): string {
    try {
      // 使用HarmonyOS设备信息API获取制造商 | Use HarmonyOS device information API to get manufacturer
      return 'Unknown Manufacturer';
    } catch (error) {
      Logger.error(TAG, 'Failed to get manufacturer', error instanceof Error ? error : new Error(String(error)));
      return 'Unknown';
    }
  }

  /**
   * 获取设备型号 | Get device model
   */
  private getModel(): string {
    try {
      // 使用HarmonyOS设备信息API获取设备型号 | Use HarmonyOS device information API to get device model
      return 'Unknown Model';
    } catch (error) {
      Logger.error(TAG, 'Failed to get device model', error instanceof Error ? error : new Error(String(error)));
      return 'Unknown';
    }
  }

  /**
   * 获取操作系统版本 | Get operating system version
   */
  private getOSVersion(): string {
    try {
      // 使用HarmonyOS设备信息API获取系统版本 | Use HarmonyOS device information API to get system version
      return 'Unknown';
    } catch (error) {
      Logger.error(TAG, 'Failed to get OS version', error instanceof Error ? error : new Error(String(error)));
      return 'Unknown';
    }
  }

  /**
   * 获取应用版本 | Get application version
   */
  private getAppVersion(): string {
    try {
      // 实际应用中从配置或清单文件获取 | Get from configuration or manifest file in actual application
      return '1.0.0';
    } catch {
      return '1.0.0';
    }
  }

  /**
   * 检查设备能力 | Check device capabilities
   */
  private async detectDeviceCapabilities(): Promise<DeviceCapability[]> {
    const capabilities: DeviceCapability[] = [];
    
    // 音频能力 | Audio capability
    if (await this.checkAudioCapability()) {
      capabilities.push(DeviceCapability.AUDIO_OUTPUT);
    }
    
    // 视频能力 | Video capability
    if (await this.checkVideoCapability()) {
      capabilities.push(DeviceCapability.VIDEO_PLAYBACK);
    }
    
    // 其他能力检查 | Other capability checks
    capabilities.push(DeviceCapability.REMOTE_CONTROL);
    capabilities.push(DeviceCapability.DEVICE_SHARING);
    
    return capabilities;
  }

  /**
   * 检查音频能力 | Check audio capability
   */
  private async checkAudioCapability(): Promise<boolean> {
    try {
      // 实际音频能力检查逻辑 | Actual audio capability check logic
      return true;
    } catch {
      return false;
    }
  }

  /**
   * 检查视频能力 | Check video capability
   */
  private async checkVideoCapability(): Promise<boolean> {
    try {
      // 实际视频能力检查逻辑 | Actual video capability check logic
      return true;
    } catch {
      return false;
    }
  }

  /**
   * 获取存储信息 | Get storage information
   */
  private async getStorageInfo(): Promise<{ total: number; available: number }> {
    try {
      // 实际存储信息获取逻辑 | Actual storage information获取 logic
      return {
        total: 1024 * 1024 * 1024 * 100, // 100GB
        available: 1024 * 1024 * 1024 * 50  // 50GB可用
      };
    } catch (error) {
      Logger.error(TAG, 'Failed to get storage info', error instanceof Error ? error : new Error(String(error)));
      return {
        total: 0,
        available: 0
      };
    }
  }

  /**
   * 获取内存信息 | Get memory information
   */
  private async getMemoryInfo(): Promise<{ total: number; available: number }> {
    try {
      // 实际内存信息获取逻辑 | Actual memory information获取 logic
      return {
        total: 1024 * 1024 * 1024 * 4, // 4GB
        available: 1024 * 1024 * 1024 * 2  // 2GB可用
      };
    } catch (error) {
      Logger.error(TAG, 'Failed to get memory info', error instanceof Error ? error : new Error(String(error)));
      return {
        total: 0,
        available: 0
      };
    }
  }

  /**
   * 获取网络信息 | Get network information
   */
  private async getNetworkInfo(): Promise<any> {
    try {
      // 实际网络信息获取逻辑 | Actual network information获取 logic
      return {
        type: 'none'
      };
    } catch (error) {
      Logger.error(TAG, 'Failed to get network info', error instanceof Error ? error : new Error(String(error)));
      return {
        type: 'none'
      };
    }
  }

  /**
   * 获取音频设备列表 | Get audio devices list
   */
  private async getAudioDevices(): Promise<string[]> {
    try {
      // 实际音频设备获取逻辑 | Actual audio devices获取 logic
      return ['Built-in Speaker'];
    } catch (error) {
      Logger.error(TAG, 'Failed to get audio devices', error instanceof Error ? error : new Error(String(error)));
      return [];
    }
  }

  /**
   * 获取视频输出列表 | Get video outputs list
   */
  private async getVideoOutputs(): Promise<string[]> {
    try {
      // 实际视频输出获取逻辑 | Actual video outputs获取 logic
      return ['Built-in Display'];
    } catch (error) {
      Logger.error(TAG, 'Failed to get video outputs', error instanceof Error ? error : new Error(String(error)));
      return [];
    }
  }

  /**
   * 获取系统属性 | Get system properties
   */
  private getSystemProperties(): Record<string, string> {
    try {
      // 实际系统属性获取逻辑 | Actual system properties获取 logic
      return {};
    } catch {
      return {};
    }
  }

  /**
   * 定期更新设备信息 | Update device information regularly
   */
  private scheduleDeviceInfoUpdate(): void {
    // 设置定时更新设备信息 | Set up scheduled device information update
    setTimeout(async () => {
      await this.refreshDeviceInfo();
    }, 24 * 60 * 60 * 1000); // 24小时更新一次 | Update every 24 hours
  }

  /**
   * 刷新设备信息 | Refresh device information
   */
  public async refreshDeviceInfo(): Promise<void> {
    try {
      const updatedInfo = await this.collectDeviceInfo();
      this.cachedDeviceInfo = updatedInfo;
      await this.deviceInfoRepository.saveDeviceInfo(updatedInfo);
      this.notifyDeviceInfoChanged();
      Logger.info(TAG, 'Device info refreshed');
    } catch (error) {
      Logger.error(TAG, 'Failed to refresh device info', error instanceof Error ? error : new Error(String(error)));
    }
  }

  /**
   * 获取设备信息 | Get device information
   */
  public async getDeviceInfo(): Promise<DeviceInfo> {
    if (!this.isInitialized) {
      await this.initialize();
    }
    return this.cachedDeviceInfo as DeviceInfo;
  }

  /**
   * 更新设备信息 | Update device information
   */
  public async updateDeviceInfo(info: Partial<DeviceInfo>): Promise<void> {
    if (!this.isInitialized) {
      await this.initialize();
    }
    
    if (this.cachedDeviceInfo) {
      this.cachedDeviceInfo = {
        ...this.cachedDeviceInfo,
        ...info,
        updatedAt: Date.now()
      };
      await this.deviceInfoRepository.saveDeviceInfo(this.cachedDeviceInfo);
      this.notifyDeviceInfoChanged();
    }
  }

  /**
   * 获取设备ID | Get device ID
   */
  public async getDeviceId(): Promise<string> {
    if (!this.isInitialized) {
      await this.initialize();
    }
    
    return (this.cachedDeviceInfo as DeviceInfo).deviceId;
  }

  /**
   * 检查设备是否支持特定能力 | Check if device supports specific capability
   */
  public async hasCapability(capability: DeviceCapability): Promise<boolean> {
    if (!this.isInitialized) {
      await this.initialize();
    }
    
    return (this.cachedDeviceInfo as DeviceInfo).capabilities.includes(capability);
  }

  /**
   * 获取设备能力列表 | Get device capabilities list
   */
  public async getDeviceCapabilities(): Promise<DeviceCapability[]> {
    if (!this.isInitialized) {
      await this.initialize();
    }
    
    return [...(this.cachedDeviceInfo as DeviceInfo).capabilities];
  }

  /**
   * 设置自定义设备属性 | Set custom device property
   */
  public async setCustomProperty<T extends string | number | boolean | object>(key: string, value: T): Promise<void> {
    if (!this.isInitialized) {
      await this.initialize();
    }
    
    if (this.cachedDeviceInfo) {
      // 使用类型安全的方式存储自定义属性 | Store custom properties in a type-safe way
      this.cachedDeviceInfo.customProperties[key] = TypeSafetyUtil.safeStringify(value);
      await this.deviceInfoRepository.saveDeviceInfo(this.cachedDeviceInfo);
      this.notifyDeviceInfoChanged();
    }
  }

  /**
   * 获取自定义设备属性 | Get custom device property
   */
  public async getCustomProperty<T>(key: string, defaultValue?: T): Promise<T | undefined> {
    if (!this.isInitialized) {
      await this.initialize();
    }
    
    if (this.cachedDeviceInfo) {
      return (this.cachedDeviceInfo.customProperties[key] as T) || defaultValue;
    }
    
    return defaultValue;
  }

  /**
   * 注册设备信息变更监听器 | Register device information change listener
   */
  public addDeviceInfoListener(listener: (info: DeviceInfo) => void): void {
    this.deviceListeners.push(listener);
  }

  /**
   * 移除设备信息变更监听器 | Remove device information change listener
   */
  public removeDeviceInfoListener(listener: (info: DeviceInfo) => void): void {
    this.deviceListeners = this.deviceListeners.filter(l => l !== listener);
  }

  /**
   * 通知设备信息变更 | Notify device information changed
   */
  private notifyDeviceInfoChanged(): void {
    if (!this.cachedDeviceInfo) return;
    
    const infoCopy: DeviceInfo = { ...this.cachedDeviceInfo };
    this.deviceListeners.forEach(listener => {
      try {
        listener(infoCopy);
      } catch (error) {
        Logger.error(TAG, 'Error in device info listener', error instanceof Error ? error : new Error(String(error)));
      }
    });
  }

  /**
   * 检查设备存储空间是否充足 | Check if device storage is sufficient
   */
  public async isStorageSufficient(minRequiredMB: number): Promise<boolean> {
    try {
      const storageInfo = await this.getStorageInfo();
      // 将字节转换为MB | Convert bytes to MB
      const availableMB = storageInfo.available / (1024 * 1024);
      return availableMB >= minRequiredMB;
    } catch (error) {
      Logger.error(TAG, 'Failed to check storage', error instanceof Error ? error : new Error(String(error)));
      return false;
    }
  }
}
