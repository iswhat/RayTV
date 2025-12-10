// DeviceService - 设备服务�?import Logger from '../../common/util/Logger';
import { DeviceInfo, DeviceType, DeviceCapability } from '../../data/bean/DeviceInfo';
import { DeviceInfoRepository } from '../../data/repository/DeviceInfoRepository';
import ConfigService from '../../service/config/ConfigService';
import TypeSafetyUtil from '../../common/util/TypeSafetyUtil';
import deviceInfo from '@ohos.deviceInfo';
import i18n from '@ohos.i18n';
import connection from '@ohos.net.connection';
import display from '@ohos.display';

const TAG = 'DeviceService';

// 设备功能检测详情接�?export interface CapabilityDetails {
  capabilityType?: string;
  version?: string;
  maxValue?: number;
  minValue?: number;
  supportedFormats?: string[];
  properties?: Record<string, string | number | boolean>;
}

// 设备功能检测结�?export interface CapabilityCheckResult {
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
   * 初始化设备服�?   */
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
      Logger.error(TAG, 'Failed to initialize device service', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      // 创建基本的设备信息作为后�?      this.cachedDeviceInfo = this.createDefaultDeviceInfo();
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
        manufacturer: this.getManufacturer(),
        model: this.getModel(),
        osVersion: this.getOSVersion(),
        appVersion: this.getAppVersion(),
        screenResolution: this.getScreenResolution(),
        deviceLanguage: this.getDeviceLanguage(),
        timezone: this.getTimezone(),
        capabilities: await this.detectDeviceCapabilities(),
        lastActiveTime: Date.now(),
        firstActiveTime: Date.now(),
        usageCount: 1,
        storageInfo: await this.getStorageInfo(),
        memoryInfo: await this.getMemoryInfo(),
        networkInfo: await this.getNetworkInfo(),
        audioDevices: await this.getAudioDevices(),
        videoOutputs: await this.getVideoOutputs(),
        systemProperties: this.getSystemProperties(),
        customProperties: {}
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
    return {
      deviceId: 'unknown-device-' + Date.now(), deviceName: 'Unknown Device',
      deviceType: DeviceType.UNKNOWN,
      manufacturer: 'Unknown',
      model: 'Unknown',
      osVersion: 'Unknown',
      appVersion: '1.0.0',
      screenResolution: { width: 1920, height: 1080 },
      deviceLanguage: 'zh-CN',
      timezone: 'Asia/Shanghai',
      capabilities: [],
      lastActiveTime: Date.now( instanceof Error ? deviceName: 'Unknown Device',
      deviceType: DeviceType.UNKNOWN,
      manufacturer: 'Unknown',
      model: 'Unknown',
      osVersion: 'Unknown',
      appVersion: '1.0.0',
      screenResolution: { width: 1920, height: 1080 },
      deviceLanguage: 'zh-CN',
      timezone: 'Asia/Shanghai',
      capabilities: [],
      lastActiveTime: Date.now( : new Error(String(deviceName: 'Unknown Device',
      deviceType: DeviceType.UNKNOWN,
      manufacturer: 'Unknown',
      model: 'Unknown',
      osVersion: 'Unknown',
      appVersion: '1.0.0',
      screenResolution: { width: 1920, height: 1080 },
      deviceLanguage: 'zh-CN',
      timezone: 'Asia/Shanghai',
      capabilities: [],
      lastActiveTime: Date.now( instanceof Error ? deviceName: 'Unknown Device',
      deviceType: DeviceType.UNKNOWN,
      manufacturer: 'Unknown',
      model: 'Unknown',
      osVersion: 'Unknown',
      appVersion: '1.0.0',
      screenResolution: { width: 1920, height: 1080 },
      deviceLanguage: 'zh-CN',
      timezone: 'Asia/Shanghai',
      capabilities: [],
      lastActiveTime: Date.now( instanceof Error ? deviceName: 'Unknown Device',
      deviceType: DeviceType.UNKNOWN,
      manufacturer: 'Unknown',
      model: 'Unknown',
      osVersion: 'Unknown',
      appVersion: '1.0.0',
      screenResolution: { width: 1920, height: 1080 },
      deviceLanguage: 'zh-CN',
      timezone: 'Asia/Shanghai',
      capabilities: [],
      lastActiveTime: Date.now( : new Error(String(deviceName: 'Unknown Device',
      deviceType: DeviceType.UNKNOWN,
      manufacturer: 'Unknown',
      model: 'Unknown',
      osVersion: 'Unknown',
      appVersion: '1.0.0',
      screenResolution: { width: 1920, height: 1080 },
      deviceLanguage: 'zh-CN',
      timezone: 'Asia/Shanghai',
      capabilities: [],
      lastActiveTime: Date.now( : new Error(String(deviceName: 'Unknown Device',
      deviceType: DeviceType.UNKNOWN,
      manufacturer: 'Unknown',
      model: 'Unknown',
      osVersion: 'Unknown',
      appVersion: '1.0.0',
      screenResolution: { width: 1920, height: 1080 },
      deviceLanguage: 'zh-CN',
      timezone: 'Asia/Shanghai',
      capabilities: [],
      lastActiveTime: Date.now( instanceof Error ? deviceName: 'Unknown Device',
      deviceType: DeviceType.UNKNOWN,
      manufacturer: 'Unknown',
      model: 'Unknown',
      osVersion: 'Unknown',
      appVersion: '1.0.0',
      screenResolution: { width: 1920, height: 1080 },
      deviceLanguage: 'zh-CN',
      timezone: 'Asia/Shanghai',
      capabilities: [],
      lastActiveTime: Date.now( : new Error(String(deviceName: 'Unknown Device',
      deviceType: DeviceType.UNKNOWN,
      manufacturer: 'Unknown',
      model: 'Unknown',
      osVersion: 'Unknown',
      appVersion: '1.0.0',
      screenResolution: { width: 1920, height: 1080 },
      deviceLanguage: 'zh-CN',
      timezone: 'Asia/Shanghai',
      capabilities: [],
      lastActiveTime: Date.now( instanceof Error ? deviceName: 'Unknown Device',
      deviceType: DeviceType.UNKNOWN,
      manufacturer: 'Unknown',
      model: 'Unknown',
      osVersion: 'Unknown',
      appVersion: '1.0.0',
      screenResolution: { width: 1920, height: 1080 },
      deviceLanguage: 'zh-CN',
      timezone: 'Asia/Shanghai',
      capabilities: [],
      lastActiveTime: Date.now( instanceof Error ? deviceName: 'Unknown Device',
      deviceType: DeviceType.UNKNOWN,
      manufacturer: 'Unknown',
      model: 'Unknown',
      osVersion: 'Unknown',
      appVersion: '1.0.0',
      screenResolution: { width: 1920, height: 1080 },
      deviceLanguage: 'zh-CN',
      timezone: 'Asia/Shanghai',
      capabilities: [],
      lastActiveTime: Date.now( : new Error(String(deviceName: 'Unknown Device',
      deviceType: DeviceType.UNKNOWN,
      manufacturer: 'Unknown',
      model: 'Unknown',
      osVersion: 'Unknown',
      appVersion: '1.0.0',
      screenResolution: { width: 1920, height: 1080 },
      deviceLanguage: 'zh-CN',
      timezone: 'Asia/Shanghai',
      capabilities: [],
      lastActiveTime: Date.now( instanceof Error ? deviceName: 'Unknown Device',
      deviceType: DeviceType.UNKNOWN,
      manufacturer: 'Unknown',
      model: 'Unknown',
      osVersion: 'Unknown',
      appVersion: '1.0.0',
      screenResolution: { width: 1920, height: 1080 },
      deviceLanguage: 'zh-CN',
      timezone: 'Asia/Shanghai',
      capabilities: [],
      lastActiveTime: Date.now( instanceof Error ? deviceName: 'Unknown Device',
      deviceType: DeviceType.UNKNOWN,
      manufacturer: 'Unknown',
      model: 'Unknown',
      osVersion: 'Unknown',
      appVersion: '1.0.0',
      screenResolution: { width: 1920, height: 1080 },
      deviceLanguage: 'zh-CN',
      timezone: 'Asia/Shanghai',
      capabilities: [],
      lastActiveTime: Date.now( : new Error(String(deviceName: 'Unknown Device',
      deviceType: DeviceType.UNKNOWN,
      manufacturer: 'Unknown',
      model: 'Unknown',
      osVersion: 'Unknown',
      appVersion: '1.0.0',
      screenResolution: { width: 1920, height: 1080 },
      deviceLanguage: 'zh-CN',
      timezone: 'Asia/Shanghai',
      capabilities: [],
      lastActiveTime: Date.now( : new Error(String(deviceName: 'Unknown Device',
      deviceType: DeviceType.UNKNOWN,
      manufacturer: 'Unknown',
      model: 'Unknown',
      osVersion: 'Unknown',
      appVersion: '1.0.0',
      screenResolution: { width: 1920, height: 1080 },
      deviceLanguage: 'zh-CN',
      timezone: 'Asia/Shanghai',
      capabilities: [],
      lastActiveTime: Date.now( instanceof Error ? deviceName: 'Unknown Device',
      deviceType: DeviceType.UNKNOWN,
      manufacturer: 'Unknown',
      model: 'Unknown',
      osVersion: 'Unknown',
      appVersion: '1.0.0',
      screenResolution: { width: 1920, height: 1080 },
      deviceLanguage: 'zh-CN',
      timezone: 'Asia/Shanghai',
      capabilities: [],
      lastActiveTime: Date.now( : new Error(String(deviceName: 'Unknown Device',
      deviceType: DeviceType.UNKNOWN,
      manufacturer: 'Unknown',
      model: 'Unknown',
      osVersion: 'Unknown',
      appVersion: '1.0.0',
      screenResolution: { width: 1920, height: 1080 },
      deviceLanguage: 'zh-CN',
      timezone: 'Asia/Shanghai',
      capabilities: [],
      lastActiveTime: Date.now( : new Error(String(deviceName: 'Unknown Device',
      deviceType: DeviceType.UNKNOWN,
      manufacturer: 'Unknown',
      model: 'Unknown',
      osVersion: 'Unknown',
      appVersion: '1.0.0',
      screenResolution: { width: 1920, height: 1080 },
      deviceLanguage: 'zh-CN',
      timezone: 'Asia/Shanghai',
      capabilities: [],
      lastActiveTime: Date.now( instanceof Error ? deviceName: 'Unknown Device',
      deviceType: DeviceType.UNKNOWN,
      manufacturer: 'Unknown',
      model: 'Unknown',
      osVersion: 'Unknown',
      appVersion: '1.0.0',
      screenResolution: { width: 1920, height: 1080 },
      deviceLanguage: 'zh-CN',
      timezone: 'Asia/Shanghai',
      capabilities: [],
      lastActiveTime: Date.now( : new Error(String(deviceName: 'Unknown Device',
      deviceType: DeviceType.UNKNOWN,
      manufacturer: 'Unknown',
      model: 'Unknown',
      osVersion: 'Unknown',
      appVersion: '1.0.0',
      screenResolution: { width: 1920, height: 1080 },
      deviceLanguage: 'zh-CN',
      timezone: 'Asia/Shanghai',
      capabilities: [],
      lastActiveTime: Date.now( instanceof Error ? deviceName: 'Unknown Device',
      deviceType: DeviceType.UNKNOWN,
      manufacturer: 'Unknown',
      model: 'Unknown',
      osVersion: 'Unknown',
      appVersion: '1.0.0',
      screenResolution: { width: 1920, height: 1080 },
      deviceLanguage: 'zh-CN',
      timezone: 'Asia/Shanghai',
      capabilities: [],
      lastActiveTime: Date.now( instanceof Error ? deviceName: 'Unknown Device',
      deviceType: DeviceType.UNKNOWN,
      manufacturer: 'Unknown',
      model: 'Unknown',
      osVersion: 'Unknown',
      appVersion: '1.0.0',
      screenResolution: { width: 1920, height: 1080 },
      deviceLanguage: 'zh-CN',
      timezone: 'Asia/Shanghai',
      capabilities: [],
      lastActiveTime: Date.now( : new Error(String(deviceName: 'Unknown Device',
      deviceType: DeviceType.UNKNOWN,
      manufacturer: 'Unknown',
      model: 'Unknown',
      osVersion: 'Unknown',
      appVersion: '1.0.0',
      screenResolution: { width: 1920, height: 1080 },
      deviceLanguage: 'zh-CN',
      timezone: 'Asia/Shanghai',
      capabilities: [],
      lastActiveTime: Date.now( : new Error(String(deviceName: 'Unknown Device',
      deviceType: DeviceType.UNKNOWN,
      manufacturer: 'Unknown',
      model: 'Unknown',
      osVersion: 'Unknown',
      appVersion: '1.0.0',
      screenResolution: { width: 1920, height: 1080 },
      deviceLanguage: 'zh-CN',
      timezone: 'Asia/Shanghai',
      capabilities: [],
      lastActiveTime: Date.now( instanceof Error ? deviceName: 'Unknown Device',
      deviceType: DeviceType.UNKNOWN,
      manufacturer: 'Unknown',
      model: 'Unknown',
      osVersion: 'Unknown',
      appVersion: '1.0.0',
      screenResolution: { width: 1920, height: 1080 },
      deviceLanguage: 'zh-CN',
      timezone: 'Asia/Shanghai',
      capabilities: [],
      lastActiveTime: Date.now( : new Error(String(deviceName: 'Unknown Device',
      deviceType: DeviceType.UNKNOWN,
      manufacturer: 'Unknown',
      model: 'Unknown',
      osVersion: 'Unknown',
      appVersion: '1.0.0',
      screenResolution: { width: 1920, height: 1080 },
      deviceLanguage: 'zh-CN',
      timezone: 'Asia/Shanghai',
      capabilities: [],
      lastActiveTime: Date.now())))))),
      firstActiveTime: Date.now(),
      usageCount: 1,
      storageInfo: { total: 0, available: 0 },
      memoryInfo: { total: 0, available: 0 },
      networkInfo: { type: 'unknown', isConnected: false },
      audioDevices: [],
      videoOutputs: [],
      systemProperties: {},
      customProperties: {}
    };
  }

  /**
   * 生成设备唯一标识
   */
  private async generateDeviceId(): Promise<string> {
    try {
      // 尝试从存储获取已有ID
      const existingId = await this.deviceInfoRepository.getDeviceId();
      if (existingId) {
        return existingId;
      }
      
      // 生成新的设备ID（简化实现）
      const timestamp = Date.now();
      const random = Math.random().toString(36).substr(2, 9);
      const deviceId = `device-${timestamp}-${random}`;
      
      // 保存设备ID
      await this.deviceInfoRepository.saveDeviceId(deviceId);
      return deviceId;
    } catch (error) {
      Logger.error(TAG, 'Failed to generate device ID', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      return 'fallback-device-' + Date.now();
    }
  }

  /**
   * 检测设备类�?   */
  private detectDeviceType(): DeviceType {
    // 使用HarmonyOS设备信息API检测设备类�?    try {
      // 根据productModel或deviceType判断设备类型
      // 这里简化处理，实际应用中可根据具体的设备标识进行更精确判断
      const deviceModel = deviceInfo.productModel.toLowerCase();
      
      // 常见电视设备标识关键�?      const tvKeywords = ['smarttv', 'tizen', 'webos', 'tv', 'smart-tv'];
      // 常见平板设备标识关键�?      const tabletKeywords = ['tablet', 'pad', 'tab'];
      // 常见移动设备标识关键�?      const mobileKeywords = ['phone', 'mobile', 'cell'];
      
      if (tvKeywords.some(keyword => deviceModel.includes(keyword))) {
        return DeviceType.TV;
      }
      if (tabletKeywords.some(keyword => deviceModel.includes(keyword))) {
        return DeviceType.TABLET;
      }
      if (mobileKeywords.some(keyword => deviceModel.includes(keyword))) {
        return DeviceType.PHONE;
      }
      
      // 默认返回TV类型，因为这是TV应用
      return DeviceType.TV;
    } catch (error) {
      Logger.error(TAG, 'Failed to detect device type', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      return DeviceType.TV;
    }
  }

  /**
   * 获取设备名称
   */
  private getDeviceName(): string {
    try {
      // 使用HarmonyOS设备信息API获取设备名称
      return `${deviceInfo.manufacture} ${deviceInfo.productModel}` || 'RayTV Device';
    } catch (error) {
      Logger.error(TAG, 'Failed to get device name', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      return 'RayTV Device';
    }
  }

  /**
   * 获取制造商信息
   */
  private getManufacturer(): string {
    try {
      // 使用HarmonyOS设备信息API获取制造商
      return deviceInfo.manufacture || 'Unknown Manufacturer';
    } catch (error) {
      Logger.error(TAG, 'Failed to get manufacturer', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      return 'Unknown';
    }
  }

  /**
   * 获取设备型号
   */
  private getModel(): string {
    try {
      // 使用HarmonyOS设备信息API获取设备型号
      return deviceInfo.productModel || 'Unknown Model';
    } catch (error) {
      Logger.error(TAG, 'Failed to get device model', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      return 'Unknown';
    }
  }

  /**
   * 获取操作系统版本
   */
  private getOSVersion(): string {
    try {
      // 使用HarmonyOS设备信息API获取系统版本
      return deviceInfo.osFullName || deviceInfo.sdkApiVersion.toString() || 'Unknown';
    } catch (error) {
      Logger.error(TAG, 'Failed to get OS version', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      return 'Unknown';
    }
  }

  /**
   * 获取应用版本
   */
  private getAppVersion(): string {
    try {
      // 实际应用中从配置或清单文件获�?      return '1.0.0';
    } catch {
      return '1.0.0';
    }
  }

  /**
   * 获取屏幕分辨�?   */
  private getScreenResolution(): { width: number; height: number } {
    try {
      // 使用HarmonyOS display API获取屏幕分辨�?      const displays = display.getAllDisplays();
      if (displays && displays.length > 0) {
        const defaultDisplay = displays[0];
        return {
          width: defaultDisplay.width,
          height: defaultDisplay.height
        };
      }
      return { width: 1920, height: 1080 };
    } catch (error) {
      Logger.error(TAG, 'Failed to get screen resolution', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      return { width: 1920, height: 1080 };
    }
  }

  /**
   * 获取设备语言
   */
  private getDeviceLanguage(): string {
    try {
      // 使用HarmonyOS i18n模块获取设备语言
      return i18n.System.getSystemLanguageSync() || 'zh-CN';
    } catch (error) {
      Logger.error(TAG, 'Failed to get device language', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      return 'zh-CN';
    }
  }

  /**
   * 获取时区
   */
  private getTimezone(): string {
    try {
      return Intl.DateTimeFormat().resolvedOptions().timeZone || 'Asia/Shanghai';
    } catch {
      return 'Asia/Shanghai';
    }
  }

  /**
   * 检测设备能�?   */
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
    
    // 网络能力
    capabilities.push(DeviceCapability.WIFI_DIRECT);
    
    // 存储能力
    capabilities.push(DeviceCapability.FILE_SHARING);
    
    // 触摸能力检�?    if (await this.checkTouchCapability()) {
      capabilities.push(DeviceCapability.TOUCH_SCREEN);
    }
    
    // 键盘能力检�?    if (await this.checkKeyboardCapability()) {
      capabilities.push(DeviceCapability.KEYBOARD_INPUT);
    }
    
    // 遥控器能力检�?    capabilities.push(DeviceCapability.REMOTE_CONTROL);
    
    // 硬件解码能力检�?    if (await this.checkHardwareDecoding()) {
      capabilities.push(DeviceCapability.HIGHER_RESOLUTION);
    }
    
    // HDR能力检�?    if (await this.checkHDRCapability()) {
      capabilities.push(DeviceCapability.HDR_SUPPORT);
    }
    
    return capabilities;
  }

  /**
   * 检查音频能�?   */
  private async checkAudioCapability(): Promise<boolean> {
    try {
      // 简化实�?      return true;
    } catch {
      return false;
    }
  }

  /**
   * 检查视频能�?   */
  private async checkVideoCapability(): Promise<boolean> {
    try {
      // 简化实�?      return true;
    } catch {
      return false;
    }
  }

  /**
   * 检查触摸能�?   */
  private async checkTouchCapability(): Promise<boolean> {
    try {
      // HarmonyOS设备通常支持触摸，这里简化处�?      // 实际应用中可以通过多模态输入API进行更精确的检�?      return true;
    } catch (error) {
      Logger.error(TAG, 'Failed to check touch capability', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      return false;
    }
  }

  /**
   * 检查键盘能�?   */
  private async checkKeyboardCapability(): Promise<boolean> {
    try {
      // 简化实�?      return true;
    } catch {
      return false;
    }
  }

  /**
   * 检查硬件解码能�?   */
  private async checkHardwareDecoding(): Promise<boolean> {
    try {
      // 简化实�?      return true;
    } catch {
      return false;
    }
  }

  /**
   * 检查HDR能力
   */
  private async checkHDRCapability(): Promise<boolean> {
    try {
      // 简化实�?      return false;
    } catch {
      return false;
    }
  }

  /**
   * 获取存储信息
   */
  private async getStorageInfo(): Promise<{ total: number; available: number }> {
    try {
      // 简化实�?      return { total: 0, available: 0 };
    } catch {
      return { total: 0, available: 0 };
    }
  }

  /**
   * 获取内存信息
   */
  private async getMemoryInfo(): Promise<{ total: number; available: number }> {
    try {
      // 简化实�?      return { total: 0, available: 0 };
    } catch {
      return { total: 0, available: 0 };
    }
  }

  /**
   * 获取网络信息
   */
  private async getNetworkInfo(): Promise<{ type: string; isConnected: boolean }> {
    try {
      // 使用HarmonyOS网络连接API获取网络信息
      const netInfo = connection.getDefaultNetSync();
      if (netInfo) {
        const netCapabilities = connection.getNetCapabilitiesSync(netInfo);
        const bearerTypes = netCapabilities.bearerTypes || [];
        
        // 将网络类型转换为可读字符�?        let typeStr = 'unknown';
        if (bearerTypes.includes(connection.NetBearType.WIFI)) {
          typeStr = 'wifi';
        } else if (bearerTypes.includes(connection.NetBearType.CELLULAR)) {
          typeStr = 'cellular';
        } else if (bearerTypes.includes(connection.NetBearType.ETHERNET)) {
          typeStr = 'ethernet';
        }
        
        return {
          type: typeStr,
          isConnected: true
        };
      }
      return { type: 'unknown', isConnected: false };
    } catch (error) {
      Logger.error(TAG, 'Failed to get network info', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      return { type: 'unknown', isConnected: false };
    }
  }

  /**
   * 获取音频设备
   */
  private async getAudioDevices(): Promise<Array<{ id: string; name: string; type: string }>> {
    try {
      // 简化实�?      return [];
    } catch {
      return [];
    }
  }

  /**
   * 获取视频输出
   */
  private async getVideoOutputs(): Promise<Array<{ id: string; name: string; resolution: string }>> {
    try {
      // 简化实�?      return [];
    } catch {
      return [];
    }
  }

  /**
   * 获取系统属�?   */
  private getSystemProperties(): Record<string, string> {
    const properties: Record<string, string> = {};
    
    try {
      // 使用HarmonyOS设备信息API获取系统属�?      properties.manufacturer = deviceInfo.manufacture || '';
      properties.model = deviceInfo.productModel || '';
      properties.osFullName = deviceInfo.osFullName || '';
      properties.apiVersion = deviceInfo.sdkApiVersion.toString() || '';
      properties.deviceType = deviceInfo.deviceType || '';
      properties.language = i18n.System.getSystemLanguageSync() || '';
    } catch (error) {
      Logger.error(TAG, 'Error getting system properties', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
    }
    
    return properties;
  }

  /**
   * 计划设备信息更新
   */
  private scheduleDeviceInfoUpdate(): void {
    // 每小时更新一次设备信�?    setInterval(async () => {
      try {
        await this.updateDeviceInfo();
      } catch (error) {
        Logger.error(TAG, 'Failed to update device info scheduled', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      }
    }, 3600000);
  }

  /**
   * 更新设备信息
   */
  public async updateDeviceInfo(): Promise<DeviceInfo> {
    try {
      if (!this.cachedDeviceInfo) {
        this.cachedDeviceInfo = await this.collectDeviceInfo();
      } else {
        // 更新设备信息
        this.cachedDeviceInfo.lastActiveTime = Date.now();
        this.cachedDeviceInfo.usageCount += 1;
        this.cachedDeviceInfo.screenResolution = this.getScreenResolution();
        this.cachedDeviceInfo.deviceLanguage = this.getDeviceLanguage();
        this.cachedDeviceInfo.networkInfo = await this.getNetworkInfo();
        
        // 定期重新检测能力（每天一次）
        const now = Date.now();
        if (now - this.lastCapabilityCheckTime > 86400000) {
          this.cachedDeviceInfo.capabilities = await this.detectDeviceCapabilities();
          this.lastCapabilityCheckTime = now;
        }
      }
      
      // 保存更新后的信息
      await this.deviceInfoRepository.saveDeviceInfo(this.cachedDeviceInfo);
      
      // 通知监听�?      this.notifyDeviceInfoChanged();
      
      return this.cachedDeviceInfo;
    } catch (error) {
      Logger.error(TAG, 'Failed to update device information', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      throw error;
    }
  }

  /**
   * 获取设备信息
   */
  public async getDeviceInfo(): Promise<DeviceInfo> {
    if (!this.isInitialized) {
      await this.initialize();
    }
    
    // 更新活跃时间
    await this.updateDeviceInfo();
    
    return this.cachedDeviceInfo as DeviceInfo;
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
   * 检查设备是否支持特定能�?   */
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
   * 设置自定义设备属�?   */
  public async setCustomProperty<T extends string | number | boolean | object>(key: string, value: T): Promise<void> {
    if (!this.isInitialized) {
      await this.initialize();
    }
    
    if (this.cachedDeviceInfo) {
      // 使用类型安全的方式存储自定义属�?      this.cachedDeviceInfo.customProperties[key] = TypeSafetyUtil.safeStringify(value);
      await this.deviceInfoRepository.saveDeviceInfo(this.cachedDeviceInfo);
      this.notifyDeviceInfoChanged();
    }
  }

  /**
   * 获取自定义设备属�?   */
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
   * 注册设备信息变更监听�?   */
  public addDeviceInfoListener(listener: (info: DeviceInfo) => void): void {
    this.deviceListeners.push(listener);
  }

  /**
   * 移除设备信息变更监听�?   */
  public removeDeviceInfoListener(listener: (info: DeviceInfo) => void): void {
    this.deviceListeners = this.deviceListeners.filter(l => l !== listener);
  }

  /**
   * 通知设备信息变更
   */
  private notifyDeviceInfoChanged(): void {
    if (!this.cachedDeviceInfo) return;
    
    const infoCopy: Record<string, string | number | boolean | null> = { ... };
    this.deviceListeners.forEach(listener => {
      try {
        listener(infoCopy);
      } catch (error) {
        Logger.error(TAG, 'Error in device info listener', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      }
    });
  }

  /**
   * 检查设备存储空间是否充�?   */
  public async isStorageSufficient(minRequiredMB: number): Promise<boolean> {
    try {
      const storageInfo = await this.getStorageInfo();
      // 将字节转换为MB
      const availableMB = storageInfo.available / (1024 * 1024);
      return availableMB >= minRequiredMB;
    } catch (error) {
      Logger.error(TAG, 'Failed to check storage', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error  as Error)));
      return false;
    }
  }

  /**
   * 获取设备使用统计
   */
  public async getUsageStats(): Promise<{ usageCount: number; firstUsed: number; lastUsed: number }> {
    if (!this.isInitialized) {
      await this.initialize();
    }
    
    const deviceInfo = this.cachedDeviceInfo as DeviceInfo;
    return {
      usageCount: deviceInfo.usageCount,
      firstUsed: deviceInfo.firstActiveTime,
      lastUsed: deviceInfo.lastActiveTime
    };
  }
}


