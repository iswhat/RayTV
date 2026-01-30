// 设备服务 | Device service
// 提供设备信息管理、能力检测和状态监控功能 | Provides device information management, capability detection, and status monitoring functionality


import DeviceInfoRepository from '../../data/repository/DeviceInfoRepository';
import ConfigService from '../config/ConfigService';
import { DeviceInfo, DeviceType, DeviceStatus, DeviceCapability, DevicePermissionInfoImpl } from '../../data/bean/DeviceInfo';
import TypeSafetyHelper from '../../common/util/TypeSafetyHelper';



// 设备能力检查信息接口 | Device capability check information interface
export interface CapabilityDetails {
  capabilityType?: string;
  version?: string;
  maxValue?: number;
  minValue?: number;
  supportedFormats?: string[];
  // 移除索引签名，使用明确的属性 | Remove indexed signature, use explicit properties
  properties?: Map<string, string | number | boolean>;
}

// 设备能力检查结果 | Device capability check result
export interface CapabilityCheckResult {
  supported: boolean;
  details?: CapabilityDetails;
  error?: string;
}

export default class DeviceService {
  private static instance: DeviceService | null = null;
  private cachedDeviceInfo: DeviceInfo | null = null;
  private deviceListeners: Array<(info: DeviceInfo) => void> = [];
  private isInitialized: boolean = false;
  private lastCapabilityCheckTime: number = 0;

  private constructor() {
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
      this.cachedDeviceInfo = await DeviceInfoRepository.getInstance().getDeviceInfo();
      
      // 如果没有设备信息，收集并保存 | If no device information, collect and save
      if (!this.cachedDeviceInfo) {
        this.cachedDeviceInfo = await this.collectDeviceInfo();
        await DeviceInfoRepository.getInstance().saveDeviceInfo(this.cachedDeviceInfo);
      }
      
      // 定期更新设备信息 | Update device information regularly
      this.scheduleDeviceInfoUpdate();
      
      this.isInitialized = true;
      console.log('Device service initialized');
    } catch (error: Error) {
      console.error('Failed to initialize device service', error);
      // 创建基本的设备信息作为后备 | Create basic device information as fallback
      this.cachedDeviceInfo = this.createDefaultDeviceInfo();
      this.isInitialized = true;
    }
  }

  /**
   * 收集设备信息 | Collect device information
   */
  private async collectDeviceInfo(): Promise<DeviceInfo> {
    console.log('Collecting device information');
    
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
        devicePermissionInfo: new DevicePermissionInfoImpl(),
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
      
      console.log('Device information collected: ' + deviceInfo.deviceName + ' (' + deviceInfo.deviceType + ')');
      return deviceInfo;
    } catch (error: Error) {
      console.error('Error collecting device information: ' + error.message);
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
      devicePermissionInfo: new DevicePermissionInfoImpl(),
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
    return "device-" + Date.now() + "-" + Math.random().toString(36).substring(2, 9);
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
    } catch (error: Error) {
      console.error('Failed to get manufacturer', error);
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
    } catch (error: Error) {
      console.error('Failed to get device model', error);
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
    } catch (error: Error) {
      console.error('Failed to get OS version', error);
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
    } catch (error: Error) {
      console.error('Failed to get storage info', error);
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
    } catch (error: Error) {
      console.error('Failed to get memory info', error);
      return {
        total: 0,
        available: 0
      };
    }
  }

  /**
   * 获取网络信息 | Get network information
   */
  private async getNetworkInfo(): Promise<{ type: string }> {
    try {
      // 实际网络信息获取逻辑 | Actual network information获取 logic
      return {
        type: 'none'
      };
    } catch (error: Error) {
      console.error('Failed to get network info', error);
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
    } catch (error: Error) {
      console.error('Failed to get audio devices', error);
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
    } catch (error: Error) {
      console.error('Failed to get video outputs', error);
      return [];
    }
  }

  /**
   * 系统属性接口 | System properties interface
   */
  interface SystemProperties {
    // 使用Map替代索引签名 | Use Map instead of indexed signature
    properties: Map<string, string>;
  }
  
  /**
   * 获取系统属性 | Get system properties
   */
  private getSystemProperties(): SystemProperties {
    try {
      // 实际系统属性获取逻辑 | Actual system properties获取 logic
      return {
        properties: new Map()
      };
    } catch {
      return {
        properties: new Map()
      };
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
      await DeviceInfoRepository.getInstance().saveDeviceInfo(updatedInfo);
      this.notifyDeviceInfoChanged();
      console.log('Device info refreshed');
    } catch (error: Error) {
      console.error('Failed to refresh device info', error);
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
   * 设备信息更新接口 | Device info update interface
   */
  interface DeviceInfoUpdate {
    deviceName?: string;
    deviceType?: DeviceType;
    manufacturer?: string;
    model?: string;
    osVersion?: string;
    screenResolution?: string;
    screenDensity?: number;
    supportedVideoCodecs?: string[];
    supportedAudioCodecs?: string[];
    cpuCores?: number;
    memorySize?: number;
    storageSize?: number;
    ipAddress?: string;
    macAddress?: string;
    capabilities?: string[];
    properties?: Map<string, string | number | boolean>;
  }
  
  /**
   * 更新设备信息 | Update device information
   */
  public async updateDeviceInfo(info: DeviceInfoUpdate): Promise<void> {
    if (!this.isInitialized) {
      await this.initialize();
    }
    
    if (this.cachedDeviceInfo) {
      // 手动构建更新后的设备信息对象 | Manually construct updated device info object
      const updatedInfo = this.createUpdatedDeviceInfo(this.cachedDeviceInfo, info);
      updatedInfo.updatedAt = Date.now();
      this.cachedDeviceInfo = updatedInfo;
      await DeviceInfoRepository.getInstance().saveDeviceInfo(this.cachedDeviceInfo);
      this.notifyDeviceInfoChanged();
    }
  }

  /**
   * 创建更新后的设备信息对象 | Create updated device info object
   */
  private createUpdatedDeviceInfo(base: DeviceInfo, updates: DeviceInfoUpdate): DeviceInfo {
    // 手动复制基础对象 | Manually copy base object
    const result: DeviceInfo = {
      deviceId: base.deviceId,
      deviceName: base.deviceName,
      deviceType: base.deviceType,
      osVersion: base.osVersion,
      apiVersion: base.apiVersion,
      appVersion: base.appVersion,
      deviceNetworkInfo: base.deviceNetworkInfo,
      deviceHardwareInfo: base.deviceHardwareInfo,
      deviceDisplayInfo: base.deviceDisplayInfo,
      deviceMediaCapabilities: base.deviceMediaCapabilities,
      devicePermissionInfo: base.devicePermissionInfo,
      deviceAppInfo: base.deviceAppInfo,
      status: base.status,
      capabilities: base.capabilities,
      isTvMode: base.isTvMode,
      isRemoteControlAvailable: base.isRemoteControlAvailable,
      isMultiDeviceSupport: base.isMultiDeviceSupport,
      isPrimaryDevice: base.isPrimaryDevice,
      createdAt: base.createdAt,
      updatedAt: base.updatedAt,
      customProperties: base.customProperties
    };
    
    // 手动应用更新 | Manually apply updates
    if (updates.deviceId !== undefined) result.deviceId = updates.deviceId;
    if (updates.deviceName !== undefined) result.deviceName = updates.deviceName;
    if (updates.deviceType !== undefined) result.deviceType = updates.deviceType;
    if (updates.osVersion !== undefined) result.osVersion = updates.osVersion;
    if (updates.apiVersion !== undefined) result.apiVersion = updates.apiVersion;
    if (updates.appVersion !== undefined) result.appVersion = updates.appVersion;
    if (updates.deviceNetworkInfo !== undefined) result.deviceNetworkInfo = updates.deviceNetworkInfo;
    if (updates.deviceHardwareInfo !== undefined) result.deviceHardwareInfo = updates.deviceHardwareInfo;
    if (updates.deviceDisplayInfo !== undefined) result.deviceDisplayInfo = updates.deviceDisplayInfo;
    if (updates.deviceMediaCapabilities !== undefined) result.deviceMediaCapabilities = updates.deviceMediaCapabilities;
    if (updates.devicePermissionInfo !== undefined) result.devicePermissionInfo = updates.devicePermissionInfo;
    if (updates.deviceAppInfo !== undefined) result.deviceAppInfo = updates.deviceAppInfo;
    if (updates.status !== undefined) result.status = updates.status;
    if (updates.capabilities !== undefined) result.capabilities = updates.capabilities;
    if (updates.isTvMode !== undefined) result.isTvMode = updates.isTvMode;
    if (updates.isRemoteControlAvailable !== undefined) result.isRemoteControlAvailable = updates.isRemoteControlAvailable;
    if (updates.isMultiDeviceSupport !== undefined) result.isMultiDeviceSupport = updates.isMultiDeviceSupport;
    if (updates.isPrimaryDevice !== undefined) result.isPrimaryDevice = updates.isPrimaryDevice;
    if (updates.createdAt !== undefined) result.createdAt = updates.createdAt;
    if (updates.updatedAt !== undefined) result.updatedAt = updates.updatedAt;
    if (updates.customProperties !== undefined) result.customProperties = updates.customProperties;
    
    return result;
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
    
    // 手动复制数组 | Manually copy array
    const capabilities = (this.cachedDeviceInfo as DeviceInfo).capabilities;
    const result: DeviceCapability[] = [];
    for (let i = 0; i < capabilities.length; i++) {
      result.push(capabilities[i]);
    }
    return result;
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
      if (!this.cachedDeviceInfo.customProperties) {
        this.cachedDeviceInfo.customProperties = new Map();
      }
      this.cachedDeviceInfo.customProperties.set(key, JSON.stringify(value));
      await DeviceInfoRepository.getInstance().saveDeviceInfo(this.cachedDeviceInfo);
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
    
    if (this.cachedDeviceInfo && this.cachedDeviceInfo.customProperties) {
      const value = this.cachedDeviceInfo.customProperties.get(key);
      return value ? JSON.parse(value) as T : defaultValue;
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
    
    // 手动创建设备信息副本 | Manually create device info copy
    const infoCopy: DeviceInfo = {
      deviceId: this.cachedDeviceInfo.deviceId,
      deviceName: this.cachedDeviceInfo.deviceName,
      deviceType: this.cachedDeviceInfo.deviceType,
      osVersion: this.cachedDeviceInfo.osVersion,
      apiVersion: this.cachedDeviceInfo.apiVersion,
      appVersion: this.cachedDeviceInfo.appVersion,
      deviceNetworkInfo: this.cachedDeviceInfo.deviceNetworkInfo,
      deviceHardwareInfo: this.cachedDeviceInfo.deviceHardwareInfo,
      deviceDisplayInfo: this.cachedDeviceInfo.deviceDisplayInfo,
      deviceMediaCapabilities: this.cachedDeviceInfo.deviceMediaCapabilities,
      devicePermissionInfo: this.cachedDeviceInfo.devicePermissionInfo,
      deviceAppInfo: this.cachedDeviceInfo.deviceAppInfo,
      status: this.cachedDeviceInfo.status,
      capabilities: this.cachedDeviceInfo.capabilities,
      isTvMode: this.cachedDeviceInfo.isTvMode,
      isRemoteControlAvailable: this.cachedDeviceInfo.isRemoteControlAvailable,
      isMultiDeviceSupport: this.cachedDeviceInfo.isMultiDeviceSupport,
      isPrimaryDevice: this.cachedDeviceInfo.isPrimaryDevice,
      createdAt: this.cachedDeviceInfo.createdAt,
      updatedAt: this.cachedDeviceInfo.updatedAt,
      customProperties: this.cachedDeviceInfo.customProperties
    };
    
    this.deviceListeners.forEach(listener => {
      try {
        listener(infoCopy);
      } catch (error: Error) {
        console.error('Error in device info listener', error);
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
    } catch (error: Error) {
      console.error('Failed to check storage', error);
      return false;
    }
  }
}
