// DeviceInfoRepository.ets - 设备信息数据仓库
// 负责设备信息的收集、存储和管理

import { SQLiteHelper, QueryCondition } from '../db/SQLiteHelper';
import { DEVICE_INFO_TABLE } from '../db/TableSchema';
import { DeviceInfo, DeviceType, DeviceCapability, DeviceNetworkInfo } from '../bean/DeviceInfo';
import Logger from '../../common/util/Logger';
import StorageUtil, { LocalStorageType } from '../../common/util/StorageUtil';
// import codec from '@ohos.media.codec'; // 暂时注释，等待SDK支持
import BusinessError from '@ohos.base';

const TAG = 'DeviceInfoRepository';

// 模拟编解码器检测类
class MockCodecDetector {
  /**
   * 模拟获取编解码器列表
   */
  static async getCodecList(codecName: string): Promise<string[]> {
    Logger.info('MockCodecDetector', `Checking support for codec: ${codecName}`);
    
    // 模拟编解码器支持检测
    const supportedCodecs: Record<string, string[]> = {
      // 视频编解码器
      'h264': ['h264'],
      'h265': ['h265'],
      'vp8': ['vp8'],
      'vp9': ['vp9'],
      'av1': [], // 模拟不支持AV1
      'mpeg4': ['mpeg4'],
      
      // 音频编解码器
      'aac': ['aac'],
      'mp3': ['mp3'],
      'opus': ['opus'],
      'flac': ['flac'],
      'vorbis': ['vorbis'],
      'ac3': [], // 模拟不支持AC3
      'eac3': []  // 模拟不支持EAC3
    };
    
    // 返回模拟的编解码器列表
    return supportedCodecs[codecName.toLowerCase()] || [];
  }
}

// 设备信息键常量
export const DeviceInfoKeys = {
  // 设备基础信息
  DEVICE_ID: 'device_id',
  DEVICE_NAME: 'device_name',
  DEVICE_TYPE: 'device_type',
  DEVICE_MODEL: 'device_model',
  DEVICE_BRAND: 'device_brand',
  OS_VERSION: 'os_version',
  APP_VERSION: 'app_version',
  
  // 设备能力
  DEVICE_CAPABILITIES: 'device_capabilities',
  SUPPORTED_VIDEO_CODECS: 'supported_video_codecs',
  SUPPORTED_AUDIO_CODECS: 'supported_audio_codecs',
  MAX_RESOLUTION: 'max_resolution',
  HDR_SUPPORTED: 'hdr_supported',
  DOLBY_ATMOS_SUPPORTED: 'dolby_atmos_supported',
  
  // 网络信息
  NETWORK_INFO: 'network_info',
  DEFAULT_NETWORK_TYPE: 'default_network_type',
  
  // 存储信息
  STORAGE_INFO: 'storage_info',
  AVAILABLE_STORAGE: 'available_storage',
  TOTAL_STORAGE: 'total_storage',
  
  // 屏幕信息
  SCREEN_INFO: 'screen_info',
  SCREEN_WIDTH: 'screen_width',
  SCREEN_HEIGHT: 'screen_height',
  SCREEN_DPI: 'screen_dpi',
  
  // 性能信息
  PERFORMANCE_INFO: 'performance_info',
  CPU_CORES: 'cpu_cores',
  RAM_SIZE: 'ram_size',
  GPU_INFO: 'gpu_info',
  
  // 设备标识
  MAC_ADDRESS: 'mac_address',
  SERIAL_NUMBER: 'serial_number',
  UUID: 'uuid',
  
  // 最后更新时间
  LAST_UPDATED: 'last_updated',
  
  // 首次使用时间
  FIRST_USE_TIME: 'first_use_time'
};

export class DeviceInfoRepository {
  private static instance: DeviceInfoRepository;
  private sqliteHelper: SQLiteHelper;
  private storageUtil: StorageUtil;
  private deviceInfoCache: Map<string, unknown> = new Map();
  private deviceInfo: DeviceInfo | null = null;
  private isInitialized: boolean = false;
  
  private constructor() {
    this.sqliteHelper = SQLiteHelper.getInstance();
    this.storageUtil = StorageUtil.getInstance();
  }
  
  /**
   * 获取设备信息仓库单例实例
   */
  public static getInstance(): DeviceInfoRepository {
    if (!DeviceInfoRepository.instance) {
      DeviceInfoRepository.instance = new DeviceInfoRepository();
    }
    return DeviceInfoRepository.instance;
  }
  
  /**
   * 初始化设备信息仓库
   * 加载已存储的设备信息并收集当前设备信息
   */
  public async initialize(): Promise<void> {
    if (this.isInitialized) {
      return;
    }
    
    try {
      Logger.info(TAG, 'Initializing device info repository');
      
      // 加载已存储的设备信息
      await this.loadStoredDeviceInfo();
      
      // 收集当前设备信息
      await this.collectDeviceInfo();
      
      // 检查首次使用时间
      await this.checkFirstUseTime();
      
      this.isInitialized = true;
      Logger.info(TAG, 'Device info repository initialized successfully');
    } catch (error) {
      Logger.error(TAG, `Failed to initialize device info repository: ${JSON.stringify(error)}`);
    }
  }
  
  /**
   * 从数据库加载已存储的设备信息
   */
  private async loadStoredDeviceInfo(): Promise<void> {
    try {
      // 从数据库查询所有设备信息记录
      const records = await this.sqliteHelper.query(DEVICE_INFO_TABLE.TABLE_NAME, ['*']);
      
      for (const record of records) {
        const key = record[DEVICE_INFO_TABLE.COLUMNS.KEY];
        let value = record[DEVICE_INFO_TABLE.COLUMNS.VALUE];
        const isObject = record[DEVICE_INFO_TABLE.COLUMNS.IS_OBJECT] === 1;
        
        if (isObject) {
          try {
            value = JSON.parse(value);
          } catch (e) {
            Logger.error(TAG, `Failed to parse device info JSON for key ${key}: ${JSON.stringify(e)}`);
          }
        }
        
        this.deviceInfoCache.set(key, value);
      }
      
      Logger.debug(TAG, `Loaded ${this.deviceInfoCache.size} device info records`);
    } catch (error) {
      Logger.error(TAG, `Failed to load stored device info: ${JSON.stringify(error)}`);
    }
  }
  
  /**
   * 收集当前设备信息
   * 在HarmonyOS环境下，可以通过相关API获取设备信息
   */
  private async collectDeviceInfo(): Promise<void> {
    try {
      // 使用HarmonyOS API获取设备信息
      const collectedInfo: Record<string, unknown> = {
        // 设备基础信息
        [DeviceInfoKeys.DEVICE_TYPE]: DeviceType.SMART_TV,
        [DeviceInfoKeys.DEVICE_MODEL]: this.getSafeValue(DeviceInfoKeys.DEVICE_MODEL, 'Unknown Model'),
        [DeviceInfoKeys.DEVICE_BRAND]: this.getSafeValue(DeviceInfoKeys.DEVICE_BRAND, 'Unknown Brand'),
        [DeviceInfoKeys.OS_VERSION]: this.getSafeValue(DeviceInfoKeys.OS_VERSION, '1.0.0'),
        [DeviceInfoKeys.APP_VERSION]: this.getSafeValue(DeviceInfoKeys.APP_VERSION, '1.0.0'),
        
        // 设备能力 - 使用模拟编解码器检测
        [DeviceInfoKeys.SUPPORTED_VIDEO_CODECS]: await this.detectSupportedVideoCodecs(),
        [DeviceInfoKeys.SUPPORTED_AUDIO_CODECS]: await this.detectSupportedAudioCodecs(),
        [DeviceInfoKeys.MAX_RESOLUTION]: await this.detectMaxResolution(),
        [DeviceInfoKeys.HDR_SUPPORTED]: await this.detectHDRSupport(),
        [DeviceInfoKeys.DOLBY_ATMOS_SUPPORTED]: await this.detectDolbySupport(),
        
        // 屏幕信息
        [DeviceInfoKeys.SCREEN_WIDTH]: this.getSafeValue(DeviceInfoKeys.SCREEN_WIDTH, 1920),
        [DeviceInfoKeys.SCREEN_HEIGHT]: this.getSafeValue(DeviceInfoKeys.SCREEN_HEIGHT, 1080),
        [DeviceInfoKeys.SCREEN_DPI]: this.getSafeValue(DeviceInfoKeys.SCREEN_DPI, 96),
        
        // 更新时间
        [DeviceInfoKeys.LAST_UPDATED]: Date.now()
      };
      
      // 创建或更新设备唯一标识
      const deviceId = await this.getOrCreateDeviceId();
      collectedInfo[DeviceInfoKeys.DEVICE_ID] = deviceId;
      collectedInfo[DeviceInfoKeys.DEVICE_NAME] = `${collectedInfo[DeviceInfoKeys.DEVICE_BRAND]} ${collectedInfo[DeviceInfoKeys.DEVICE_MODEL]}`;
      
      // 保存收集到的设备信息
      for (const [key, value] of Object.entries(collectedInfo)) {
        await this.setDeviceInfo(key, value);
      }
      
      // 构建完整的DeviceInfo对象
      this.buildDeviceInfoObject();
      
      Logger.info(TAG, `Device info collected: ${deviceId}`);
    } catch (error) {
      Logger.error(TAG, `Failed to collect device info: ${JSON.stringify(error)}`);
    }
  }
  
  /**
   * 获取或创建设备唯一标识
   */
  private async getOrCreateDeviceId(): Promise<string> {
    try {
      // 尝试从存储中获取设备ID
      let deviceId = await this.getDeviceInfo(DeviceInfoKeys.DEVICE_ID);
      
      if (!deviceId) {
        // 如果不存在，生成新的设备ID
        deviceId = this.generateDeviceId();
        // 使用安全存储保存设备ID
        await this.storageUtil.save(DeviceInfoKeys.DEVICE_ID, deviceId, LocalStorageType.SECURE);
        await this.setDeviceInfo(DeviceInfoKeys.DEVICE_ID, deviceId);
        
        Logger.info(TAG, `Created new device ID: ${deviceId}`);
      }
      
      return deviceId;
    } catch (error) {
      Logger.error(TAG, `Failed to get or create device ID: ${JSON.stringify(error)}`);
      return `unknown_${Date.now()}`;
    }
  }
  
  /**
   * 生成设备唯一标识
   */
  private generateDeviceId(): string {
    const timestamp = Date.now();
    const random = Math.random().toString(36).substring(2, 15);
    return `tv_${timestamp}_${random}`;
  }
  
  /**
   * 检查首次使用时间
   */
  private async checkFirstUseTime(): Promise<void> {
    try {
      const firstUseTime = await this.getDeviceInfo(DeviceInfoKeys.FIRST_USE_TIME);
      
      if (!firstUseTime) {
        // 记录首次使用时间
        const now = Date.now();
        await this.setDeviceInfo(DeviceInfoKeys.FIRST_USE_TIME, now);
        Logger.info(TAG, `First use time recorded: ${now}`);
      }
    } catch (error) {
      Logger.error(TAG, `Failed to check first use time: ${JSON.stringify(error)}`);
    }
  }
  
  /**
   * 构建完整的DeviceInfo对象
   */
  private buildDeviceInfoObject(): void {
    try {
      this.deviceInfo = {
        deviceId: this.getSafeValue(DeviceInfoKeys.DEVICE_ID, 'unknown'),
        deviceName: this.getSafeValue(DeviceInfoKeys.DEVICE_NAME, 'Unknown Device'),
        deviceType: this.getSafeValue(DeviceInfoKeys.DEVICE_TYPE, DeviceType.OTHER),
        deviceModel: this.getSafeValue(DeviceInfoKeys.DEVICE_MODEL, 'Unknown Model'),
        deviceBrand: this.getSafeValue(DeviceInfoKeys.DEVICE_BRAND, 'Unknown Brand'),
        osVersion: this.getSafeValue(DeviceInfoKeys.OS_VERSION, 'Unknown'),
        appVersion: this.getSafeValue(DeviceInfoKeys.APP_VERSION, 'Unknown'),
        
        capabilities: {
          supportedVideoCodecs: this.getSafeValue(DeviceInfoKeys.SUPPORTED_VIDEO_CODECS, []),
          supportedAudioCodecs: this.getSafeValue(DeviceInfoKeys.SUPPORTED_AUDIO_CODECS, []),
          maxResolution: this.getSafeValue(DeviceInfoKeys.MAX_RESOLUTION, '1080p'),
          hdrSupported: this.getSafeValue(DeviceInfoKeys.HDR_SUPPORTED, false),
          dolbyAtmosSupported: this.getSafeValue(DeviceInfoKeys.DOLBY_ATMOS_SUPPORTED, false)
        },
        
        screenInfo: {
          width: this.getSafeValue(DeviceInfoKeys.SCREEN_WIDTH, 1280),
          height: this.getSafeValue(DeviceInfoKeys.SCREEN_HEIGHT, 720),
          dpi: this.getSafeValue(DeviceInfoKeys.SCREEN_DPI, 96)
        },
        
        networkInfo: this.getSafeValue(DeviceInfoKeys.NETWORK_INFO, null),
        
        lastUpdated: this.getSafeValue(DeviceInfoKeys.LAST_UPDATED, Date.now()),
        firstUseTime: this.getSafeValue(DeviceInfoKeys.FIRST_USE_TIME, Date.now())
      };
    } catch (error) {
      Logger.error(TAG, `Failed to build device info object: ${JSON.stringify(error)}`);
    }
  }
  
  /**
   * 保存设备信息
   * @param key 信息键
   * @param value 信息值
   * @returns 是否保存成功
   */
  public async setDeviceInfo(key: string, value: unknown): Promise<boolean> {
    try {
      Logger.debug(TAG, `Setting device info: ${key}`);
      
      // 序列化值
      const valueStr = typeof value === 'object' ? JSON.stringify(value) : String(value);
      const isObject = typeof value === 'object';
      
      const infoData = {
        [DEVICE_INFO_TABLE.COLUMNS.KEY]: key,
        [DEVICE_INFO_TABLE.COLUMNS.VALUE]: valueStr,
        [DEVICE_INFO_TABLE.COLUMNS.IS_OBJECT]: isObject ? 1 : 0,
        [DEVICE_INFO_TABLE.COLUMNS.UPDATE_TIME]: Date.now()
      };
      
      // 检查是否已存在
      const exists = await this.hasDeviceInfo(key);
      
      if (exists) {
        // 更新现有记录
        const conditions: QueryCondition[] = [{
          column: DEVICE_INFO_TABLE.COLUMNS.KEY,
          value: key
        }];
        const result = await this.sqliteHelper.update(DEVICE_INFO_TABLE.TABLE_NAME, infoData, conditions);
        
        if (result.success) {
          // 更新缓存
          this.deviceInfoCache.set(key, value);
        }
        
        return result.success;
      } else {
        // 插入新记录
        const result = await this.sqliteHelper.insert(DEVICE_INFO_TABLE.TABLE_NAME, infoData);
        
        if (result.success) {
          // 更新缓存
          this.deviceInfoCache.set(key, value);
        }
        
        return result.success;
      }
    } catch (error) {
      Logger.error(TAG, `Failed to set device info ${key}: ${JSON.stringify(error)}`);
      return false;
    }
  }
  
  /**
   * 获取设备信息
   * @param key 信息键
   * @param defaultValue 默认值
   * @returns 设备信息值或默认值
   */
  public async getDeviceInfo<T = unknown>(key: string, defaultValue?: T): Promise<T | null> {
    try {
      // 优先从缓存获取
      if (this.deviceInfoCache.has(key)) {
        return this.deviceInfoCache.get(key) as T;
      }
      
      // 从数据库查询
      const conditions: QueryCondition[] = [{
        column: DEVICE_INFO_TABLE.COLUMNS.KEY,
        value: key
      }];
      
      const record = await this.sqliteHelper.getFirst(
        DEVICE_INFO_TABLE.TABLE_NAME,
        ['*'],
        conditions
      );
      
      if (!record) {
        return defaultValue !== undefined ? defaultValue : null;
      }
      
      let value: unknown = record[DEVICE_INFO_TABLE.COLUMNS.VALUE];
      const isObject = record[DEVICE_INFO_TABLE.COLUMNS.IS_OBJECT] === 1;
      
      if (isObject) {
        try {
          value = JSON.parse(value);
        } catch (e) {
          Logger.error(TAG, `Failed to parse device info JSON for key ${key}: ${JSON.stringify(e)}`);
        }
      }
      
      // 更新缓存
      this.deviceInfoCache.set(key, value);
      
      return value as T;
    } catch (error) {
      Logger.error(TAG, `Failed to get device info ${key}: ${JSON.stringify(error)}`);
      return defaultValue !== undefined ? defaultValue : null;
    }
  }
  
  /**
   * 从缓存获取设备信息（安全版本）
   * @param key 信息键
   * @param defaultValue 默认值
   * @returns 设备信息值或默认值
   */
  private getSafeValue<T>(key: string, defaultValue: T): T {
    return this.deviceInfoCache.get(key) ?? defaultValue;
  }
  
  /**
   * 检查设备信息是否存在
   * @param key 信息键
   * @returns 是否存在
   */
  public async hasDeviceInfo(key: string): Promise<boolean> {
    try {
      if (this.deviceInfoCache.has(key)) {
        return true;
      }
      
      const conditions: QueryCondition[] = [{
        column: DEVICE_INFO_TABLE.COLUMNS.KEY,
        value: key
      }];
      
      return await this.sqliteHelper.exists(DEVICE_INFO_TABLE.TABLE_NAME, conditions);
    } catch (error) {
      Logger.error(TAG, `Failed to check device info existence for key ${key}: ${JSON.stringify(error)}`);
      return false;
    }
  }
  
  /**
   * 删除设备信息
   * @param key 信息键
   * @returns 是否删除成功
   */
  public async removeDeviceInfo(key: string): Promise<boolean> {
    try {
      Logger.debug(TAG, `Removing device info: ${key}`);
      
      const conditions: QueryCondition[] = [{
        column: DEVICE_INFO_TABLE.COLUMNS.KEY,
        value: key
      }];
      
      const result = await this.sqliteHelper.delete(DEVICE_INFO_TABLE.TABLE_NAME, conditions);
      
      if (result.success) {
        this.deviceInfoCache.delete(key);
      }
      
      return result.success;
    } catch (error) {
      Logger.error(TAG, `Failed to remove device info ${key}: ${JSON.stringify(error)}`);
      return false;
    }
  }
  
  /**
   * 获取完整的设备信息对象
   */
  public async getFullDeviceInfo(): Promise<DeviceInfo | null> {
    if (!this.isInitialized) {
      await this.initialize();
    }
    
    if (!this.deviceInfo) {
      this.buildDeviceInfoObject();
    }
    
    return this.deviceInfo;
  }
  
  /**
   * 获取设备ID
   */
  public async getDeviceId(): Promise<string> {
    return await this.getOrCreateDeviceId();
  }
  
  /**
   * 获取设备能力
   */
  public async getDeviceCapabilities(): Promise<DeviceCapability | null> {
    if (!this.isInitialized) {
      await this.initialize();
    }
    
    return this.deviceInfo?.capabilities || null;
  }
  
  /**
   * 更新网络信息
   * @param networkInfo 网络信息
   */
  public async updateNetworkInfo(networkInfo: DeviceNetworkInfo): Promise<boolean> {
    return await this.setDeviceInfo(DeviceInfoKeys.NETWORK_INFO, networkInfo);
  }
  
  /**
   * 获取网络信息
   */
  public async getNetworkInfo(): Promise<DeviceNetworkInfo | null> {
    return await this.getDeviceInfo<DeviceNetworkInfo>(DeviceInfoKeys.NETWORK_INFO);
  }
  
  /**
   * 检测设备支持的视频编解码器
   */
  private async detectSupportedVideoCodecs(): Promise<string[]> {
    try {
      // 常见视频编解码器列表
      const videoCodecs = ['h264', 'h265', 'vp8', 'vp9', 'av1', 'mpeg4'];
      const supportedCodecs: string[] = [];
      
      // 使用模拟编解码器检测
      for (const codecName of videoCodecs) {
        try {
          // 检查是否支持该编解码器的解码能力
          const isSupported = await this.checkCodecSupport(codecName, 0); // 0表示解码器模式
          if (isSupported) {
            supportedCodecs.push(codecName);
          }
        } catch (error) {
          Logger.warn(TAG, `Failed to check support for codec ${codecName}: ${error}`);
        }
      }
      
      // 如果模拟检测失败，回退到基本编解码器列表
      return supportedCodecs.length > 0 ? supportedCodecs : ['h264', 'h265', 'vp9'];
    } catch (error) {
      Logger.error(TAG, `Failed to detect video codecs: ${error}`);
      return ['h264', 'h265', 'vp9']; // 默认回退值
    }
  }
  
  /**
   * 检测设备支持的音频编解码器
   */
  private async detectSupportedAudioCodecs(): Promise<string[]> {
    try {
      // 常见音频编解码器列表
      const audioCodecs = ['aac', 'mp3', 'opus', 'flac', 'vorbis', 'ac3', 'eac3'];
      const supportedCodecs: string[] = [];
      
      // 使用模拟编解码器检测
      for (const codecName of audioCodecs) {
        try {
          // 检查是否支持该编解码器的解码能力
          const isSupported = await this.checkCodecSupport(codecName, 0); // 0表示解码器模式
          if (isSupported) {
            supportedCodecs.push(codecName);
          }
        } catch (error) {
          Logger.warn(TAG, `Failed to check support for codec ${codecName}: ${error}`);
        }
      }
      
      // 如果模拟检测失败，回退到基本编解码器列表
      return supportedCodecs.length > 0 ? supportedCodecs : ['aac', 'mp3', 'opus'];
    } catch (error) {
      Logger.error(TAG, `Failed to detect audio codecs: ${error}`);
      return ['aac', 'mp3', 'opus']; // 默认回退值
    }
  }
  
  /**
   * 检测设备最大支持的分辨率
   */
  private async detectMaxResolution(): Promise<string> {
    try {
      // 这里可以添加实际的分辨率检测逻辑
      // 暂时根据设备屏幕尺寸进行估算
      const screenWidth = this.getSafeValue(DeviceInfoKeys.SCREEN_WIDTH, 1920);
      
      if (screenWidth >= 3840) {
        return '4K';
      } else if (screenWidth >= 2560) {
        return '2K';
      } else if (screenWidth >= 1920) {
        return '1080p';
      } else {
        return '720p';
      }
    } catch (error) {
      Logger.error(TAG, `Failed to detect max resolution: ${error}`);
      return '1080p'; // 默认回退值
    }
  }
  
  /**
   * 检测设备是否支持HDR
   */
  private async detectHDRSupport(): Promise<boolean> {
    try {
      // 这里可以使用系统API检测HDR支持
      // 暂时返回基于屏幕分辨率的估算值
      const screenWidth = this.getSafeValue(DeviceInfoKeys.SCREEN_WIDTH, 1920);
      return screenWidth >= 3840; // 假设4K屏幕通常支持HDR
    } catch (error) {
      Logger.error(TAG, `Failed to detect HDR support: ${error}`);
      return false; // 默认不支持
    }
  }
  
  /**
   * 检测设备是否支持Dolby Atmos
   */
  private async detectDolbySupport(): Promise<boolean> {
    try {
      // 这里可以使用音频API检测Dolby支持
      // 暂时返回一个默认值
      return false; // 默认不支持，实际应用中需要使用系统API检测
    } catch (error) {
      Logger.error(TAG, `Failed to detect Dolby support: ${error}`);
      return false; // 默认不支持
    }
  }
  
  /**
   * 检查特定编解码器的支持情况
   */
  private async checkCodecSupport(codecName: string, mode: number): Promise<boolean> {
    try {
      // 使用模拟编解码器检测器查询编解码器信息
      const codecInfos = await MockCodecDetector.getCodecList(codecName);
      return codecInfos.length > 0;
    } catch (error) {
      Logger.warn(TAG, `Error checking codec ${codecName} support: ${error}`);
      return false;
    }
  }
  
  /**
   * 检查设备是否支持指定的视频编解码器
   * @param codec 视频编解码器
   */
  public async isVideoCodecSupported(codec: string): Promise<boolean> {
    const codecs = await this.getDeviceInfo<string[]>(DeviceInfoKeys.SUPPORTED_VIDEO_CODECS, []);
    return codecs.includes(codec.toLowerCase());
  }
  
  /**
   * 检查设备是否支持指定的音频编解码器
   * @param codec 音频编解码器
   */
  public async isAudioCodecSupported(codec: string): Promise<boolean> {
    const codecs = await this.getDeviceInfo<string[]>(DeviceInfoKeys.SUPPORTED_AUDIO_CODECS, []);
    return codecs.includes(codec.toLowerCase());
  }
  
  /**
   * 更新应用版本信息
   * @param appVersion 应用版本
   */
  public async updateAppVersion(appVersion: string): Promise<boolean> {
    return await this.setDeviceInfo(DeviceInfoKeys.APP_VERSION, appVersion);
  }
  
  /**
   * 清空所有设备信息（谨慎使用）
   */
  public async clearAllDeviceInfo(): Promise<boolean> {
    try {
      Logger.warning(TAG, 'Clearing all device info');
      
      // 保留设备ID和首次使用时间
      const deviceId = await this.getDeviceId();
      const firstUseTime = await this.getDeviceInfo(DeviceInfoKeys.FIRST_USE_TIME);
      
      // 删除数据库中的所有记录
      await this.sqliteHelper.delete(DEVICE_INFO_TABLE.TABLE_NAME);
      
      // 清空缓存
      this.deviceInfoCache.clear();
      this.deviceInfo = null;
      
      // 重新保存重要信息
      if (deviceId) {
        await this.setDeviceInfo(DeviceInfoKeys.DEVICE_ID, deviceId);
      }
      if (firstUseTime) {
        await this.setDeviceInfo(DeviceInfoKeys.FIRST_USE_TIME, firstUseTime);
      }
      
      // 重新收集设备信息
      await this.collectDeviceInfo();
      
      Logger.info(TAG, 'All device info cleared and reinitialized');
      return true;
    } catch (error) {
      Logger.error(TAG, `Failed to clear all device info: ${JSON.stringify(error)}`);
      return false;
    }
  }
  
  /**
   * 获取设备使用统计信息
   */
  public async getUsageStatistics(): Promise<{
    deviceAge: number; // 设备使用天数
    lastActive: number; // 最后活跃时间
  }> {
    try {
      const firstUseTime = await this.getDeviceInfo<number>(DeviceInfoKeys.FIRST_USE_TIME, Date.now());
      const lastUpdated = await this.getDeviceInfo<number>(DeviceInfoKeys.LAST_UPDATED, Date.now());
      
      const now = Date.now();
      const deviceAge = Math.floor((now - firstUseTime) / (1000 * 60 * 60 * 24));
      
      return {
        deviceAge,
        lastActive: lastUpdated
      };
    } catch (error) {
      Logger.error(TAG, `Failed to get usage statistics: ${JSON.stringify(error)}`);
      return {
        deviceAge: 0,
        lastActive: Date.now()
      };
    }
  }
}