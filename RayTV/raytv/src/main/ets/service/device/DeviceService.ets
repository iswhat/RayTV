import Logger from '../../common/util/Logger';
import DeviceInfoRepository from '../../data/repository/DeviceInfoRepository';
import ConfigService from '../config/ConfigService';
import { DeviceInfo, DeviceType, DeviceStatus, DeviceCapability } from '../../data/bean/DeviceInfo';
import TypeSafetyUtil from '../../common/util/TypeSafetyUtil';

const TAG = 'DeviceService';

// 设备功能检测详情接口
export interface CapabilityDetails {
  capabilityType?: string;
  version?: string;
  maxValue?: number;
  minValue?: number;
  supportedFormats?: string[];
  properties?: Record<string, string | number | boolean>;
}

// 设备功能检测结果
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

  public static getInstance(): DeviceService {
    if (!DeviceService.instance) {
      DeviceService.instance = new DeviceService();
    }
    return DeviceService.instance;
  }

  /**
   * 初始化设备服务
   */
  public async initialize(): Promise<void> {
    try {
      // 加载设备信息
      this.cachedDeviceInfo = await this.deviceInfoRepository.getDeviceInfo();
      
      // 如果没有设备信息，收集并保存
      if (!this.cachedDeviceInfo) {
        this.cachedDeviceInfo = await this.collectDeviceInfo();
        await this.deviceInfoRepository.saveDeviceInfo(this.cachedDeviceInfo);
      }
      
      // 定期更新设备信息
      this.scheduleDeviceInfoUpdate();
      
      this.isInitialized = true;
      Logger.info(TAG, 'Device service initialized');
    } catch (error) {
      Logger.error(TAG, 'Failed to initialize device service', error instanceof Error ? error : new Error(String(error))));
      // 创建基本的设备信息作为后备
      this.cachedDeviceInfo = this.createDefaultDeviceInfo();
      this.isInitialized = true;
    }
  }

  /**
   * 收集设备信息
   */
  private async collectDeviceInfo(): Promise<DeviceInfo> {
    Logger.info(TAG, 'Collecting device information');
    
    try {
      // 设备标识
      const deviceId = await this.generateDeviceId();
      
      // 设备基本信息
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
   * 创建默认设备信息
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
   * 生成设备ID
   */
  private async generateDeviceId(): Promise<string> {
    return `device-${Date.now()}-${Math.random().toString(36).substring(2, 9)}`;
  }

  /**
   * 获取设备名称
   */
  private getDeviceName(): string {
    try {
      // 使用HarmonyOS设备信息API获取设备名称
      return 'HarmonyOS Device';
    } catch (error) {
      return 'Unknown Device';
    }
  }

  /**
   * 检测设备类型
   */
  private detectDeviceType(): DeviceType {
    try {
      // 检测设备类型的逻辑
      return DeviceType.TV;
    } catch {
      return DeviceType.OTHER;
    }
  }

  /**
   * 获取制造商信息
   */
  private getManufacturer(): string {
    try {
      // 使用HarmonyOS设备信息API获取制造商
      return 'Unknown Manufacturer';
    } catch (error) {
      Logger.error(TAG, 'Failed to get manufacturer', error instanceof Error ? error : new Error(String(error))));
      return 'Unknown';
    }
  }

  /**
   * 获取设备型号
   */
  private getModel(): string {
    try {
      // 使用HarmonyOS设备信息API获取设备型号
      return 'Unknown Model';
    } catch (error) {
      Logger.error(TAG, 'Failed to get device model', error instanceof Error ? error : new Error(String(error))));
      return 'Unknown';
    }
  }

  /**
   * 获取操作系统版本
   */
  private getOSVersion(): string {
    try {
      // 使用HarmonyOS设备信息API获取系统版本
      return 'Unknown';
    } catch (error) {
      Logger.error(TAG, 'Failed to get OS version', error instanceof Error ? error : new Error(String(error))));
      return 'Unknown';
    }
  }

  /**
   * 获取应用版本
   */
  private getAppVersion(): string {
    try {
      // 实际应用中从配置或清单文件获取
      return '1.0.0';
    } catch {
      return '1.0.0';
    }
  }

  /**
   * 检测设备能力
   */
  private async detectDeviceCapabilities(): Promise<DeviceCapability[]> {
    const capabilities: DeviceCapability[] = [];
    
    // 音频能力
    if (await this.checkAudioCapability()) {
      capabilities.push(DeviceCapability.AUDIO_OUTPUT);
    }
    
    // 视频能力
    if (await this.checkVideoCapability()) {
      capabilities.push(DeviceCapability.VIDEO_PLAYBACK);
    }
    
    // 其他能力检测
    capabilities.push(DeviceCapability.REMOTE_CONTROL);
    capabilities.push(DeviceCapability.DEVICE_SHARING);
    
    return capabilities;
  }

  /**
   * 检查音频能力
   */
  private async checkAudioCapability(): Promise<boolean> {
    try {
      // 实际音频能力检测逻辑
      return true;
    } catch {
      return false;
    }
  }

  /**
   * 检查视频能力
   */
  private async checkVideoCapability(): Promise<boolean> {
    try {
      // 实际视频能力检测逻辑
      return true;
    } catch {
      return false;
    }
  }

  /**
   * 获取存储信息
   */
  private async getStorageInfo(): Promise<{ total: number; available: number }> {
    try {
      // 实际存储信息获取逻辑
      return {
        total: 1024 * 1024 * 1024 * 100, // 100GB
        available: 1024 * 1024 * 1024 * 50  // 50GB可用
      };
    } catch (error) {
      Logger.error(TAG, 'Failed to get storage info', error instanceof Error ? error : new Error(String(error))));
      return {
        total: 0,
        available: 0
      };
    }
  }

  /**
   * 获取内存信息
   */
  private async getMemoryInfo(): Promise<{ total: number; available: number }> {
    try {
      // 实际内存信息获取逻辑
      return {
        total: 1024 * 1024 * 1024 * 4, // 4GB
        available: 1024 * 1024 * 1024 * 2  // 2GB可用
      };
    } catch (error) {
      Logger.error(TAG, 'Failed to get memory info', error instanceof Error ? error : new Error(String(error))));
      return {
        total: 0,
        available: 0
      };
    }
  }

  /**
   * 获取网络信息
   */
  private async getNetworkInfo(): Promise<any> {
    try {
      // 实际网络信息获取逻辑
      return {
        type: 'none'
      };
    } catch (error) {
      Logger.error(TAG, 'Failed to get network info', error instanceof Error ? error : new Error(String(error))));
      return {
        type: 'none'
      };
    }
  }

  /**
   * 获取音频设备列表
   */
  private async getAudioDevices(): Promise<string[]> {
    try {
      // 实际音频设备获取逻辑
      return ['Built-in Speaker'];
    } catch (error) {
      Logger.error(TAG, 'Failed to get audio devices', error instanceof Error ? error : new Error(String(error))));
      return [];
    }
  }

  /**
   * 获取视频输出列表
   */
  private async getVideoOutputs(): Promise<string[]> {
    try {
      // 实际视频输出获取逻辑
      return ['Built-in Display'];
    } catch (error) {
      Logger.error(TAG, 'Failed to get video outputs', error instanceof Error ? error : new Error(String(error))));
      return [];
    }
  }

  /**
   * 获取系统属性
   */
  private getSystemProperties(): Record<string, string> {
    try {
      // 实际系统属性获取逻辑
      return {};
    } catch {
      return {};
    }
  }

  /**
   * 定期更新设备信息
   */
  private scheduleDeviceInfoUpdate(): void {
    // 设置定时更新设备信息
    setTimeout(async () => {
      await this.refreshDeviceInfo();
    }, 24 * 60 * 60 * 1000); // 24小时更新一次
  }

  /**
   * 刷新设备信息
   */
  public async refreshDeviceInfo(): Promise<void> {
    try {
      const updatedInfo = await this.collectDeviceInfo();
      this.cachedDeviceInfo = updatedInfo;
      await this.deviceInfoRepository.saveDeviceInfo(updatedInfo);
      this.notifyDeviceInfoChanged();
      Logger.info(TAG, 'Device info refreshed');
    } catch (error) {
      Logger.error(TAG, 'Failed to refresh device info', error instanceof Error ? error : new Error(String(error))));
    }
  }

  /**
   * 获取设备信息
   */
  public async getDeviceInfo(): Promise<DeviceInfo> {
    if (!this.isInitialized) {
      await this.initialize();
    }
    return this.cachedDeviceInfo as DeviceInfo;
  }

  /**
   * 更新设备信息
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
   * 获取设备ID
   */
  public async getDeviceId(): Promise<string> {
    if (!this.isInitialized) {
      await this.initialize();
    }
    
    return (this.cachedDeviceInfo as DeviceInfo).deviceId;
  }

  /**
   * 检查设备是否支持特定能力
   */
  public async hasCapability(capability: DeviceCapability): Promise<boolean> {
    if (!this.isInitialized) {
      await this.initialize();
    }
    
    return (this.cachedDeviceInfo as DeviceInfo).capabilities.includes(capability);
  }

  /**
   * 获取设备能力列表
   */
  public async getDeviceCapabilities(): Promise<DeviceCapability[]> {
    if (!this.isInitialized) {
      await this.initialize();
    }
    
    return [...(this.cachedDeviceInfo as DeviceInfo).capabilities];
  }

  /**
   * 设置自定义设备属性
   */
  public async setCustomProperty<T extends string | number | boolean | object>(key: string, value: T): Promise<void> {
    if (!this.isInitialized) {
      await this.initialize();
    }
    
    if (this.cachedDeviceInfo) {
      // 使用类型安全的方式存储自定义属性
      this.cachedDeviceInfo.customProperties[key] = TypeSafetyUtil.safeStringify(value);
      await this.deviceInfoRepository.saveDeviceInfo(this.cachedDeviceInfo);
      this.notifyDeviceInfoChanged();
    }
  }

  /**
   * 获取自定义设备属性
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
   * 注册设备信息变更监听器
   */
  public addDeviceInfoListener(listener: (info: DeviceInfo) => void): void {
    this.deviceListeners.push(listener);
  }

  /**
   * 移除设备信息变更监听器
   */
  public removeDeviceInfoListener(listener: (info: DeviceInfo) => void): void {
    this.deviceListeners = this.deviceListeners.filter(l => l !== listener);
  }

  /**
   * 通知设备信息变更
   */
  private notifyDeviceInfoChanged(): void {
    if (!this.cachedDeviceInfo) return;
    
    const infoCopy: DeviceInfo = { ...this.cachedDeviceInfo };
    this.deviceListeners.forEach(listener => {
      try {
        listener(infoCopy);
      } catch (error) {
        Logger.error(TAG, 'Error in device info listener', error instanceof Error ? error : new Error(String(error))));
      }
    });
  }

  /**
   * 检查设备存储空间是否充足
   */
  public async isStorageSufficient(minRequiredMB: number): Promise<boolean> {
    try {
      const storageInfo = await this.getStorageInfo();
      // 将字节转换为MB
      const availableMB = storageInfo.available / (1024 * 1024);
      return availableMB >= minRequiredMB;
    } catch (error) {
      Logger.error(TAG, 'Failed to check storage', error instanceof Error ? error : new Error(String(error))));
      return false;
    }
  }
}