// DeviceService - 设备服务类
import Logger from '../../common/util/Logger';
import { DeviceInfo, DeviceType, DeviceCapability } from '../bean/DeviceInfo';
import DeviceInfoRepository from '../repository/DeviceInfoRepository';
import ConfigService from './ConfigService';

const TAG = 'DeviceService';

// 设备功能检测结果
interface CapabilityCheckResult {
  supported: boolean;
  details?: any;
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
  private async initialize(): Promise<void> {
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
      Logger.error(TAG, 'Failed to initialize device service', error);
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
      
      Logger.info(TAG, `Device information collected: ${deviceInfo.deviceName} (${deviceInfo.deviceType})`);
      return deviceInfo;
    } catch (error) {
      Logger.error(TAG, 'Error collecting device information', error);
      return this.createDefaultDeviceInfo();
    }
  }

  /**
   * 创建默认设备信息
   */
  private createDefaultDeviceInfo(): DeviceInfo {
    return {
      deviceId: 'unknown-device-' + Date.now(),
      deviceName: 'Unknown Device',
      deviceType: DeviceType.UNKNOWN,
      manufacturer: 'Unknown',
      model: 'Unknown',
      osVersion: 'Unknown',
      appVersion: '1.0.0',
      screenResolution: { width: 1920, height: 1080 },
      deviceLanguage: 'zh-CN',
      timezone: 'Asia/Shanghai',
      capabilities: [],
      lastActiveTime: Date.now(),
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
      Logger.error(TAG, 'Failed to generate device ID', error);
      return 'fallback-device-' + Date.now();
    }
  }

  /**
   * 检测设备类型
   */
  private detectDeviceType(): DeviceType {
    // 在实际应用中，根据设备特性检测设备类型
    // 这里简化处理
    const userAgent = typeof window !== 'undefined' ? navigator.userAgent : '';
    
    if (userAgent.includes('SmartTV') || userAgent.includes('Tizen') || userAgent.includes('webOS')) {
      return DeviceType.SMART_TV;
    }
    if (userAgent.includes('Android') && userAgent.includes('Mobile')) {
      return DeviceType.MOBILE;
    }
    if (userAgent.includes('Android')) {
      return DeviceType.TABLET;
    }
    if (userAgent.includes('iPad')) {
      return DeviceType.TABLET;
    }
    if (userAgent.includes('iPhone')) {
      return DeviceType.MOBILE;
    }
    
    return DeviceType.DESKTOP;
  }

  /**
   * 获取设备名称
   */
  private getDeviceName(): string {
    try {
      // 在实际应用中，使用设备API获取设备名称
      return 'RayTV Device';
    } catch {
      return 'Unknown Device';
    }
  }

  /**
   * 获取制造商信息
   */
  private getManufacturer(): string {
    try {
      // 简化实现
      return 'Unknown Manufacturer';
    } catch {
      return 'Unknown';
    }
  }

  /**
   * 获取设备型号
   */
  private getModel(): string {
    try {
      // 简化实现
      return 'Unknown Model';
    } catch {
      return 'Unknown';
    }
  }

  /**
   * 获取操作系统版本
   */
  private getOSVersion(): string {
    try {
      if (typeof navigator !== 'undefined') {
        return navigator.appVersion || 'Unknown';
      }
      return 'Unknown';
    } catch {
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
   * 获取屏幕分辨率
   */
  private getScreenResolution(): { width: number; height: number } {
    try {
      if (typeof window !== 'undefined') {
        return {
          width: window.screen.width,
          height: window.screen.height
        };
      }
      return { width: 1920, height: 1080 };
    } catch {
      return { width: 1920, height: 1080 };
    }
  }

  /**
   * 获取设备语言
   */
  private getDeviceLanguage(): string {
    try {
      if (typeof navigator !== 'undefined') {
        return navigator.language || 'zh-CN';
      }
      return 'zh-CN';
    } catch {
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
   * 检测设备能力
   */
  private async detectDeviceCapabilities(): Promise<DeviceCapability[]> {
    const capabilities: DeviceCapability[] = [];
    
    // 音频能力
    if (await this.checkAudioCapability()) {
      capabilities.push(DeviceCapability.AUDIO_PLAYBACK);
    }
    
    // 视频能力
    if (await this.checkVideoCapability()) {
      capabilities.push(DeviceCapability.VIDEO_PLAYBACK);
    }
    
    // 网络能力
    capabilities.push(DeviceCapability.NETWORK);
    
    // 存储能力
    capabilities.push(DeviceCapability.STORAGE);
    
    // 触摸能力检测
    if (await this.checkTouchCapability()) {
      capabilities.push(DeviceCapability.TOUCH);
    }
    
    // 键盘能力检测
    if (await this.checkKeyboardCapability()) {
      capabilities.push(DeviceCapability.KEYBOARD);
    }
    
    // 遥控器能力检测
    capabilities.push(DeviceCapability.REMOTE_CONTROL);
    
    // 硬件解码能力检测
    if (await this.checkHardwareDecoding()) {
      capabilities.push(DeviceCapability.HARDWARE_DECODING);
    }
    
    // HDR能力检测
    if (await this.checkHDRCapability()) {
      capabilities.push(DeviceCapability.HDR);
    }
    
    return capabilities;
  }

  /**
   * 检查音频能力
   */
  private async checkAudioCapability(): Promise<boolean> {
    try {
      // 简化实现
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
      // 简化实现
      return true;
    } catch {
      return false;
    }
  }

  /**
   * 检查触摸能力
   */
  private async checkTouchCapability(): Promise<boolean> {
    try {
      if (typeof window !== 'undefined') {
        return 'ontouchstart' in window || navigator.maxTouchPoints > 0;
      }
      return false;
    } catch {
      return false;
    }
  }

  /**
   * 检查键盘能力
   */
  private async checkKeyboardCapability(): Promise<boolean> {
    try {
      // 简化实现
      return true;
    } catch {
      return false;
    }
  }

  /**
   * 检查硬件解码能力
   */
  private async checkHardwareDecoding(): Promise<boolean> {
    try {
      // 简化实现
      return true;
    } catch {
      return false;
    }
  }

  /**
   * 检查HDR能力
   */
  private async checkHDRCapability(): Promise<boolean> {
    try {
      // 简化实现
      return false;
    } catch {
      return false;
    }
  }

  /**
   * 获取存储信息
   */
  private async getStorageInfo(): Promise<{ total: number; available: number }> {
    try {
      // 简化实现
      return { total: 0, available: 0 };
    } catch {
      return { total: 0, available: 0 };
    }
  }

  /**
   * 获取内存信息
   */
  private async getMemoryInfo(): Promise<{ total: number; available: number }> {
    try {
      // 简化实现
      return { total: 0, available: 0 };
    } catch {
      return { total: 0, available: 0 };
    }
  }

  /**
   * 获取网络信息
   */
  private async getNetworkInfo(): Promise<{ type: string; isConnected: boolean }> {
    try {
      if (typeof navigator !== 'undefined' && 'connection' in navigator) {
        const connection = (navigator as any).connection;
        return {
          type: connection.effectiveType || 'unknown',
          isConnected: true
        };
      }
      return { type: 'unknown', isConnected: true };
    } catch {
      return { type: 'unknown', isConnected: false };
    }
  }

  /**
   * 获取音频设备
   */
  private async getAudioDevices(): Promise<Array<{ id: string; name: string; type: string }>> {
    try {
      // 简化实现
      return [];
    } catch {
      return [];
    }
  }

  /**
   * 获取视频输出
   */
  private async getVideoOutputs(): Promise<Array<{ id: string; name: string; resolution: string }>> {
    try {
      // 简化实现
      return [];
    } catch {
      return [];
    }
  }

  /**
   * 获取系统属性
   */
  private getSystemProperties(): Record<string, string> {
    const properties: Record<string, string> = {};
    
    try {
      if (typeof navigator !== 'undefined') {
        properties.userAgent = navigator.userAgent;
        properties.platform = navigator.platform;
        properties.language = navigator.language;
      }
    } catch (error) {
      Logger.error(TAG, 'Error getting system properties', error);
    }
    
    return properties;
  }

  /**
   * 计划设备信息更新
   */
  private scheduleDeviceInfoUpdate(): void {
    // 每小时更新一次设备信息
    setInterval(async () => {
      try {
        await this.updateDeviceInfo();
      } catch (error) {
        Logger.error(TAG, 'Failed to update device info scheduled', error);
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
      
      // 通知监听器
      this.notifyDeviceInfoChanged();
      
      return this.cachedDeviceInfo;
    } catch (error) {
      Logger.error(TAG, 'Failed to update device information', error);
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
  public async setCustomProperty(key: string, value: any): Promise<void> {
    if (!this.isInitialized) {
      await this.initialize();
    }
    
    if (this.cachedDeviceInfo) {
      this.cachedDeviceInfo.customProperties[key] = value;
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
    
    const infoCopy = { ...this.cachedDeviceInfo };
    this.deviceListeners.forEach(listener => {
      try {
        listener(infoCopy);
      } catch (error) {
        Logger.error(TAG, 'Error in device info listener', error);
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
      Logger.error(TAG, 'Failed to check storage', error);
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