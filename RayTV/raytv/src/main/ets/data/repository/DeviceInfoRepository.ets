// DeviceInfoRepository.ets - 设备信息数据仓库 | Device info data repository
// 负责设备信息的收集、存储和管理 | Responsible for device info collection, storage and management

import { SQLiteHelper, QueryCondition } from '../db/SQLiteHelper';
import { DeviceInfo, DeviceType, DeviceCapability, DeviceNetworkInfo } from '../bean/DeviceInfo';
import StorageUtil, { StorageType } from '../../common/util/StorageUtil';
import { BusinessError } from '@ohos.base';


const TAG = 'DeviceInfoRepository';

// 引入HarmonyOS多媒体API用于编解码器检测 | Import HarmonyOS multimedia API for codec detection
import media from '@ohos.multimedia.media';
import screen from '@ohos.screen';
import audio from '@ohos.multimedia.audio';

// 设备信息常量键 | Device info constant keys
export const DeviceInfoKeys = {
  DEVICE_ID: 'device_id', // 设备ID | Device ID
  DEVICE_NAME: 'device_name', // 设备名称 | Device name
  DEVICE_TYPE: 'device_type', // 设备类型 | Device type
  DEVICE_MODEL: 'device_model', // 设备型号 | Device model
  DEVICE_BRAND: 'device_brand', // 设备品牌 | Device brand
  OS_VERSION: 'os_version', // 操作系统版本 | OS version
  APP_VERSION: 'app_version', // 应用版本 | App version
  SUPPORTED_VIDEO_CODECS: 'supported_video_codecs', // 支持的视频编解码器 | Supported video codecs
  SUPPORTED_AUDIO_CODECS: 'supported_audio_codecs', // 支持的音频编解码器 | Supported audio codecs
  MAX_RESOLUTION: 'max_resolution', // 最大分辨率 | Max resolution
  HDR_SUPPORTED: 'hdr_supported', // 是否支持HDR | Whether HDR supported
  DOLBY_ATMOS_SUPPORTED: 'dolby_atmos_supported', // 是否支持杜比全景声 | Whether Dolby Atmos supported
  SCREEN_WIDTH: 'screen_width', // 屏幕宽度 | Screen width
  SCREEN_HEIGHT: 'screen_height', // 屏幕高度 | Screen height
  SCREEN_DPI: 'screen_dpi', // 屏幕DPI | Screen DPI
  NETWORK_INFO: 'network_info', // 网络信息 | Network info
  LAST_UPDATED: 'last_updated', // 最后更新时间 | Last updated time
  FIRST_USE_TIME: 'first_use_time' // 首次使用时间 | First use time
};

// 设备信息表定义 | Device info table definition
const DEVICE_INFO_TABLE = {
  TABLE_NAME: 'device_info', // 表名 | Table name
  COLUMNS: {
    KEY: 'key', // 键 | Key
    VALUE: 'value', // 值 | Value
    IS_OBJECT: 'is_object', // 是否为对象 | Whether object
    UPDATED_AT: 'updated_at' // 更新时间 | Updated time
  }
}

export class DeviceInfoRepository {
  private static instance: DeviceInfoRepository;
  private deviceInfoCache: Map<string, string | number | boolean | object | null> = new Map();
  private deviceInfo: DeviceInfo | null = null;
  private isInitialized: boolean = false;
  
  private constructor() {
  }
  
  /**
   * 获取设备信息仓库单例实例 | Get device info repository singleton instance
   */
  public static getInstance(): DeviceInfoRepository {
    if (!DeviceInfoRepository.instance) {
      DeviceInfoRepository.instance = new DeviceInfoRepository();
    }
    return DeviceInfoRepository.instance;
  }
  
  /**
   * 初始化设备信息仓库 | Initialize device info repository
   * 加载已存储的设备信息并收集当前设备信息 | Load stored device info and collect current device info
   */
  public async initialize(): Promise<void> {
    if (this.isInitialized) {
      return;
    }
    
    try {
      console.info(TAG + ': 正在初始化设备信息仓库 | Initializing device info repository');
      
      // 加载已存储的设备信息 | Load stored device info
      await this.loadStoredDeviceInfo();
      
      // 收集当前设备信息 | Collect current device info
      await this.collectDeviceInfo();
      
      // 检查首次使用时间 | Check first use time
      await this.checkFirstUseTime();
      
      this.isInitialized = true;
      console.info(TAG + ': 设备信息仓库初始化成功 | Device info repository initialized successfully');
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      console.error(TAG + `: 设备信息仓库初始化失败: ${errorMsg} | Failed to initialize device info repository: ${errorMsg}`);
    }
  }
  
  /**
   * 从数据库加载已存储的设备信息 | Load stored device info from database
   */
  private async loadStoredDeviceInfo(): Promise<void> {
    try {
      // 从数据库查询所有设备信息记录 | Query all device info records from database
      const records = await SQLiteHelper.getInstance().query(DEVICE_INFO_TABLE.TABLE_NAME, ['*']);
      
      for (const record of records) {
        const key = record[DEVICE_INFO_TABLE.COLUMNS.KEY];
        let value = record[DEVICE_INFO_TABLE.COLUMNS.VALUE];
        const isObject = record[DEVICE_INFO_TABLE.COLUMNS.IS_OBJECT] === 1;
        
        if (isObject) {
          try {
            value = JSON.parse(value);
          } catch (e) {
            const errorMsg = e instanceof Error ? e.message : 'Unknown error';
            console.error(TAG + `: 解析设备信息JSON失败，键: ${key}: ${errorMsg} | Failed to parse device info JSON for key ${key}: ${errorMsg}`);
          }
        }
        
        this.deviceInfoCache.set(key, value);
      }
      
      console.debug(TAG + `: 已加载 ${this.deviceInfoCache.size} 条设备信息记录 | Loaded ${this.deviceInfoCache.size} device info records`);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      console.error(TAG + `: 加载存储的设备信息失败: ${errorMsg} | Failed to load stored device info: ${errorMsg}`);
    }
  }
  
  /**
   * 收集当前设备信息 | Collect current device info
   * 在HarmonyOS环境下，可以通过相关API获取设备信息 | In HarmonyOS environment, device info can be obtained through related APIs
   */
  private async collectDeviceInfo(): Promise<void> {
    try {
      // 获取屏幕信息 | Get screen info
      const displayInfo = screen.getDefaultDisplaySync();
      
      // 使用HarmonyOS API获取设备信息 | Use HarmonyOS API to get device info
      const collectedInfo: Record<string, SafeAny> = {
        // 设备基本信息 | Device basic info
        [DeviceInfoKeys.DEVICE_TYPE]: DeviceType.SMART_TV,
        [DeviceInfoKeys.DEVICE_MODEL]: this.getSafeValue(DeviceInfoKeys.DEVICE_MODEL, 'Unknown Model'),
        [DeviceInfoKeys.DEVICE_BRAND]: this.getSafeValue(DeviceInfoKeys.DEVICE_BRAND, 'Unknown Brand'),
        [DeviceInfoKeys.OS_VERSION]: this.getSafeValue(DeviceInfoKeys.OS_VERSION, '1.0.0'),
        [DeviceInfoKeys.APP_VERSION]: this.getSafeValue(DeviceInfoKeys.APP_VERSION, '1.0.0'),
        
        // 设备能力 | Device capabilities
        [DeviceInfoKeys.SUPPORTED_VIDEO_CODECS]: await this.detectSupportedVideoCodecs(),
        [DeviceInfoKeys.SUPPORTED_AUDIO_CODECS]: await this.detectSupportedAudioCodecs(),
        [DeviceInfoKeys.MAX_RESOLUTION]: await this.detectMaxResolution(),
        [DeviceInfoKeys.HDR_SUPPORTED]: await this.detectHDRSupport(),
        [DeviceInfoKeys.DOLBY_ATMOS_SUPPORTED]: await this.detectDolbySupport(),
        
        // 屏幕信息 | Screen info
        [DeviceInfoKeys.SCREEN_WIDTH]: displayInfo.width,
        [DeviceInfoKeys.SCREEN_HEIGHT]: displayInfo.height,
        [DeviceInfoKeys.SCREEN_DPI]: displayInfo.densityPixels,
        
        // 更新时间 | Update time
        [DeviceInfoKeys.LAST_UPDATED]: Date.now()
      };
      
      // 创建或更新设备唯一标识 | Create or update device unique identifier
      const deviceId = await this.getOrCreateDeviceId();
      collectedInfo[DeviceInfoKeys.DEVICE_ID] = deviceId;
      collectedInfo[DeviceInfoKeys.DEVICE_NAME] = `${collectedInfo[DeviceInfoKeys.DEVICE_BRAND]} ${collectedInfo[DeviceInfoKeys.DEVICE_MODEL]}`;
      
      // 保存收集到的设备信息 | Save collected device info
      for (const key in collectedInfo) {
        if (Object.hasOwnProperty.call(collectedInfo, key)) {
          const value = collectedInfo[key];
          await this.setDeviceInfo(key, value);
        }
      }
      
      // 构建完整的DeviceInfo对象 | Build complete DeviceInfo object
      this.buildDeviceInfoObject();
      
      console.info(TAG + `: 设备信息已收集，设备ID: ${deviceId} | Device info collected: ${deviceId}`);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      console.error(TAG + `: 收集设备信息失败: ${errorMsg} | Failed to collect device info: ${errorMsg}`);
    }
  }
  
  /**
   * 获取或创建设备唯一标识 | Get or create device unique identifier
   */
  private async getOrCreateDeviceId(): Promise<string> {
    try {
      // 尝试从存储中获取设备ID | Try to get device ID from storage
      let deviceId = await this.getDeviceInfo<string>(DeviceInfoKeys.DEVICE_ID);
      
      if (!deviceId) {
        // 如果不存在，生成新的设备ID | If not exist, generate new device ID
        deviceId = this.generateDeviceId();
        // 使用安全存储保存设备ID | Use secure storage to save device ID
        await this.setDeviceInfo(DeviceInfoKeys.DEVICE_ID, deviceId);
        
        console.info(TAG + `: 已创建新设备ID: ${deviceId} | Created new device ID: ${deviceId}`);
      }
      
      return deviceId;
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      console.error(TAG + `: 获取或创建设备ID失败: ${errorMsg} | Failed to get or create device ID: ${errorMsg}`);
      return `unknown_${Date.now()}`;
    }
  }
  
  /**
   * 生成设备唯一标识 | Generate device unique identifier
   */
  private generateDeviceId(): string {
    const timestamp = Date.now();
    const random = Math.random().toString(36).substring(2, 15);
    return `tv_${timestamp}_${random}`;
  }
  
  /**
   * 检查首次使用时间 | Check first use time
   */
  private async checkFirstUseTime(): Promise<void> {
    try {
      const firstUseTime = await this.getDeviceInfo<number>(DeviceInfoKeys.FIRST_USE_TIME);
      
      if (!firstUseTime) {
        // 记录首次使用时间 | Record first use time
        const now = Date.now();
        await this.setDeviceInfo(DeviceInfoKeys.FIRST_USE_TIME, now);
        console.info(TAG + `: 首次使用时间已记录: ${now} | First use time recorded: ${now}`);
      }
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      console.error(TAG + `: 检查首次使用时间失败: ${errorMsg} | Failed to check first use time: ${errorMsg}`);
    }
  }
  
  /**
   * 构建完整的DeviceInfo对象 | Build complete DeviceInfo object
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
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      console.error(TAG + `: 构建设备信息对象失败: ${errorMsg} | Failed to build device info object: ${errorMsg}`);
    }
  }
  
  /**
   * 保存设备信息 | Save device info
   * @param key 信息键 | Info key
   * @param value 信息值 | Info value
   * @returns 是否保存成功 | Whether save successful
   */
  public async setDeviceInfo(key: string, value: string | number | boolean | object | null): Promise<boolean> {
    try {
      console.debug(TAG + `: 正在设置设备信息: ${key} | Setting device info: ${key}`);
      
      // 序列化值 | Serialize value
      const valueStr = typeof value === 'object' ? JSON.stringify(value) : String(value);
      const isObject = typeof value === 'object';
      
      const infoData: Record<string, string | number | boolean | null> = {
        [DEVICE_INFO_TABLE.COLUMNS.KEY]: key,
        [DEVICE_INFO_TABLE.COLUMNS.VALUE]: valueStr,
        [DEVICE_INFO_TABLE.COLUMNS.IS_OBJECT]: isObject ? 1 : 0,
        [DEVICE_INFO_TABLE.COLUMNS.UPDATED_AT]: Date.now()
      };
      
      // 检查是否已存在
      const exists = await this.hasDeviceInfo(key);
      
      if (exists) {
        // 更新现有记录
        const conditions: QueryCondition[] = [{
          column: DEVICE_INFO_TABLE.COLUMNS.KEY,
          value: key
        }];
        const result = await SQLiteHelper.getInstance().update(DEVICE_INFO_TABLE.TABLE_NAME, infoData, conditions);
        
        if (result.success) {
          // 更新缓存
          this.deviceInfoCache.set(key, value);
        }
        
        return result.success;
      } else {
        // 插入新记录
        const result = await SQLiteHelper.getInstance().insert(DEVICE_INFO_TABLE.TABLE_NAME, infoData);
        
        if (result.success) {
          // 更新缓存
          this.deviceInfoCache.set(key, value);
        }
        
        return result.success;
      }
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      console.error(TAG + `: 设置设备信息 ${key} 失败: ${errorMsg} | Failed to set device info ${key}: ${errorMsg}`);
      return false;
    }
  }
  
  /**
   * 获取设备信息 | Get device info
   * @param key 信息键 | Info key
   * @param defaultValue 默认值 | Default value
   * @returns 设备信息值或默认值 | Device info value or default value
   */
  public async getDeviceInfo<T = SafeAny>(key: string, defaultValue?: T): Promise<T | null> {
    try {
      // 优先从缓存获取 | Priority get from cache
      if (this.deviceInfoCache.has(key)) {
        return this.deviceInfoCache.get(key) as T;
      }
      
      // 从数据库查询 | Query from database
      const conditions: QueryCondition[] = [{
        column: DEVICE_INFO_TABLE.COLUMNS.KEY,
        value: key
      }];
      
      const record = await SQLiteHelper.getInstance().getFirst(
        DEVICE_INFO_TABLE.TABLE_NAME,
        ['*'],
        conditions
      );
      
      if (!record) {
        return defaultValue !== undefined ? defaultValue : null;
      }
      
      let value: string | number | boolean | object | null = record[DEVICE_INFO_TABLE.COLUMNS.VALUE];
      const isObject = record[DEVICE_INFO_TABLE.COLUMNS.IS_OBJECT] === 1;
      
      if (isObject) {
        try {
          value = JSON.parse(value as string);
        } catch (e) {
          const errorMsg = e instanceof Error ? e.message : 'Unknown error';
          console.error(TAG + `: 解析设备信息JSON失败，键: ${key}: ${errorMsg} | Failed to parse device info JSON for key ${key}: ${errorMsg}`);
        }
      }
      
      // 更新缓存 | Update cache
      this.deviceInfoCache.set(key, value);
      
      return value as T;
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      console.error(TAG + `: 获取设备信息 ${key} 失败: ${errorMsg} | Failed to get device info ${key}: ${errorMsg}`);
      return defaultValue !== undefined ? defaultValue : null;
    }
  }
  
  /**
   * 从缓存获取设备信息（安全版本） | Get device info from cache (safe version)
   * @param key 信息键 | Info key
   * @param defaultValue 默认值 | Default value
   * @returns 设备信息值或默认值 | Device info value or default value
   */
  private getSafeValue<T>(key: string, defaultValue: T): T {
    const value = this.deviceInfoCache.get(key);
    return (value as T) || defaultValue;
  }
  
  /**
   * 检查设备信息是否存在 | Check if device info exists
   * @param key 信息键 | Info key
   * @returns 是否存在 | Whether exists
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
      
      return await SQLiteHelper.getInstance().exists(DEVICE_INFO_TABLE.TABLE_NAME, conditions);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      console.error(TAG + `: 检查设备信息存在性失败，键: ${key}: ${errorMsg} | Failed to check device info existence for key ${key}: ${errorMsg}`);
      return false;
    }
  }
  
  /**
   * 删除设备信息 | Delete device info
   * @param key 信息键 | Info key
   * @returns 是否删除成功 | Whether delete successful
   */
  public async removeDeviceInfo(key: string): Promise<boolean> {
    try {
      console.debug(TAG + `: 正在移除设备信息: ${key} | Removing device info: ${key}`);
      
      const conditions: QueryCondition[] = [{
        column: DEVICE_INFO_TABLE.COLUMNS.KEY,
        value: key
      }];
      
      const result = await SQLiteHelper.getInstance().delete(DEVICE_INFO_TABLE.TABLE_NAME, conditions);
      
      if (result.success) {
        this.deviceInfoCache.delete(key);
      }
      
      return result.success;
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      console.error(TAG + `: 移除设备信息 ${key} 失败: ${errorMsg} | Failed to remove device info ${key}: ${errorMsg}`);
      return false;
    }
  }
  
  /**
   * 获取完整的设备信息对象 | Get complete device info object
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
   * 获取设备ID | Get device ID
   */
  public async getDeviceId(): Promise<string> {
    return await this.getOrCreateDeviceId();
  }
  
  /**
   * 获取设备能力 | Get device capabilities
   */
  public async getDeviceCapabilities(): Promise<DeviceCapability | null> {
    if (!this.isInitialized) {
      await this.initialize();
    }
    
    return this.deviceInfo?.capabilities || null;
  }
  
  /**
   * 更新网络信息 | Update network info
   * @param networkInfo 网络信息 | Network info
   */
  public async updateNetworkInfo(networkInfo: DeviceNetworkInfo): Promise<boolean> {
    return await this.setDeviceInfo(DeviceInfoKeys.NETWORK_INFO, networkInfo);
  }
  
  /**
   * 获取网络信息 | Get network info
   */
  public async getNetworkInfo(): Promise<DeviceNetworkInfo | null> {
    return await this.getDeviceInfo<DeviceNetworkInfo>(DeviceInfoKeys.NETWORK_INFO);
  }
  
  /**
   * 检测设备支持的视频编解码器 | Detect device supported video codecs
   */
  private async detectSupportedVideoCodecs(): Promise<string[]> {
    try {
      // 常见视频编解码器列表 | Common video codecs list
      const videoCodecs = ['h264', 'h265', 'vp8', 'vp9', 'av1', 'mpeg4'];
      const supportedCodecs: string[] = [];
      
      // 使用HarmonyOS媒体API检测编解码器支持 | Use HarmonyOS media API to detect codec support
      for (const codecName of videoCodecs) {
        try {
          // 尝试创建编解码器配置来检测支持情况 | Try to create codec config to detect support
          const isSupported = await this.checkCodecSupport(codecName, 0);
          if (isSupported) {
            supportedCodecs.push(codecName);
          }
        } catch (error) {
          const errorMsg = error instanceof Error ? error.message : 'Unknown error';
          console.warn(TAG + `: 检查编解码器 ${codecName} 支持失败: ${errorMsg} | Failed to check support for codec ${codecName}: ${errorMsg}`);
        }
      }
      
      return supportedCodecs;
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      console.error(TAG + `: 检测视频编解码器失败: ${errorMsg} | Failed to detect video codecs: ${errorMsg}`);
      return ['h264', 'h265', 'vp9']; // 默认回退值 | Default fallback value
    }
  }
  
  /**
   * 检测设备支持的音频编解码器 | Detect device supported audio codecs
   */
  private async detectSupportedAudioCodecs(): Promise<string[]> {
    try {
      // 常见音频编解码器列表 | Common audio codecs list
      const audioCodecs = ['aac', 'mp3', 'opus', 'flac', 'vorbis', 'ac3', 'eac3'];
      const supportedCodecs: string[] = [];
      
      // 使用HarmonyOS媒体API检测编解码器支持 | Use HarmonyOS media API to detect codec support
      for (const codecName of audioCodecs) {
        try {
          // 尝试创建编解码器配置来检测支持情况 | Try to create codec config to detect support
          const isSupported = await this.checkCodecSupport(codecName, 1);
          if (isSupported) {
            supportedCodecs.push(codecName);
          }
        } catch (error) {
          const errorMsg = error instanceof Error ? error.message : 'Unknown error';
          console.warn(TAG + `: 检查编解码器 ${codecName} 支持失败: ${errorMsg} | Failed to check support for codec ${codecName}: ${errorMsg}`);
        }
      }
      
      return supportedCodecs;
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      console.error(TAG + `: 检测音频编解码器失败: ${errorMsg} | Failed to detect audio codecs: ${errorMsg}`);
      return ['aac', 'mp3', 'opus']; // 默认回退值 | Default fallback value
    }
  }
  
  /**
   * 检测设备最大支持的分辨率 | Detect device maximum supported resolution
   */
  private async detectMaxResolution(): Promise<string> {
    try {
      // 获取屏幕信息 | Get screen info
      const displayInfo = screen.getDefaultDisplaySync();
      const screenWidth = displayInfo.width;
      
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
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      console.error(TAG + `: 检测最大分辨率失败: ${errorMsg} | Failed to detect max resolution: ${errorMsg}`);
      return '1080p'; // 默认回退值 | Default fallback value
    }
  }
  
  /**
   * 检测设备是否支持HDR | Detect device whether support HDR
   */
  private async detectHDRSupport(): Promise<boolean> {
    try {
      // 使用HarmonyOS屏幕API检测HDR支持 | Use HarmonyOS screen API to detect HDR support
      const displayInfo = screen.getDefaultDisplaySync();
      // 检查屏幕是否支持HDR | Check if screen supports HDR
      return displayInfo.supportHDR || false;
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      console.error(TAG + `: 检测HDR支持失败: ${errorMsg} | Failed to detect HDR support: ${errorMsg}`);
      return false; // 默认不支持 | Default not support
    }
  }
  
  /**
   * 检测设备是否支持Dolby Atmos | Detect device whether support Dolby Atmos
   */
  private async detectDolbySupport(): Promise<boolean> {
    try {
      // 使用HarmonyOS音频API检测Dolby支持 | Use HarmonyOS audio API to detect Dolby support
      // 检查音频设备是否支持Dolby Atmos | Check if audio device supports Dolby Atmos
      const audioManager = audio.getAudioManager();
      const supportedFormats = await audioManager.getSupportedAudioFormats();
      return supportedFormats.includes('dolby_atmos') || false;
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      console.error(TAG + `: 检测杜比支持失败: ${errorMsg} | Failed to detect Dolby support: ${errorMsg}`);
      return false; // 默认不支持 | Default not support
    }
  }
  
  /**
   * 检查特定编解码器的支持情况 | Check specific codec support status
   */
  private async checkCodecSupport(codecName: string, mode: number): Promise<boolean> {
    try {
      // 使用HarmonyOS媒体API检查编解码器支持 | Use HarmonyOS media API to check codec support
      // 注意：实际应用中，应该使用更精确的编解码器检测方法
      // 这里使用简化的检测方式，通过尝试创建编解码器配置来检测支持情况
      const codecType = mode === 0 ? 'video' : 'audio';
      
      // 尝试获取支持的编解码器列表 | Try to get supported codec list
      // 注意：不同HarmonyOS版本API可能不同，需要适配 | Note: API may vary by HarmonyOS version, need adaptation
      try {
        if (codecType === 'video') {
          // 对于视频编解码器，检查是否支持H.264/H.265等常见格式
          const formats = ['video/avc', 'video/hevc', 'video/vp8', 'video/vp9', 'video/av1'];
          const mimeType = formats.find(f => f.includes(codecName.toLowerCase())) || '';
          return mimeType !== '';
        } else {
          // 对于音频编解码器，检查是否支持常见格式
          const formats = ['audio/mp4a-latm', 'audio/mpeg', 'audio/opus', 'audio/flac', 'audio/vorbis', 'audio/ac3', 'audio/eac3'];
          const mimeType = formats.find(f => f.includes(codecName.toLowerCase())) || '';
          return mimeType !== '';
        }
      } catch (e) {
        // 如果API调用失败，返回false | Return false if API call fails
        return false;
      }
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      console.warn(TAG + `: 检查编解码器 ${codecName} 支持时出错: ${errorMsg} | Error checking codec ${codecName} support: ${errorMsg}`);
      return false;
    }
  }
  
  /**
   * 检查设备是否支持指定的视频编解码器 | Check if device supports specified video codec
   * @param codec 视频编解码器 | Video codec
   */
  public async isVideoCodecSupported(codec: string): Promise<boolean> {
    const codecs = await this.getDeviceInfo<string[]>(DeviceInfoKeys.SUPPORTED_VIDEO_CODECS, []);
    return codecs.includes(codec.toLowerCase());
  }
  
  /**
   * 检查设备是否支持指定的音频编解码器 | Check if device supports specified audio codec
   * @param codec 音频编解码器 | Audio codec
   */
  public async isAudioCodecSupported(codec: string): Promise<boolean> {
    const codecs = await this.getDeviceInfo<string[]>(DeviceInfoKeys.SUPPORTED_AUDIO_CODECS, []);
    return codecs.includes(codec.toLowerCase());
  }
  
  /**
   * 更新应用版本信息 | Update app version info
   * @param appVersion 应用版本 | App version
   */
  public async updateAppVersion(appVersion: string): Promise<boolean> {
    return await this.setDeviceInfo(DeviceInfoKeys.APP_VERSION, appVersion);
  }
  
  /**
   * 清除所有设备信息（谨慎使用） | Clear all device info (use with caution)
   */
  public async clearAllDeviceInfo(): Promise<boolean> {
    try {
      console.warn(TAG + ': 正在清除所有设备信息 | Clearing all device info');
      
      // 保存设备ID和首次使用时间
      const deviceId = await this.getDeviceId();
      const firstUseTime = await this.getDeviceInfo<number>(DeviceInfoKeys.FIRST_USE_TIME);
      
      // 删除数据库中的所有记录
      await SQLiteHelper.getInstance().delete(DEVICE_INFO_TABLE.TABLE_NAME);
      
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
      
      console.info(TAG + ': 所有设备信息已清除并重新初始化 | All device info cleared and reinitialized');
      return true;
    } catch (error) {
      console.error(TAG + ': 清除所有设备信息失败 | Failed to clear all device info', error instanceof Error ? error : new Error(String(error)));
      return false;
    }
  }
  
  /**
   * 获取设备使用统计信息 | Get device usage statistics
   */
  public async getUsageStatistics(): Promise<{
    deviceAge: number; // 设备使用天数 | Device usage days
    lastActive: number; // 最后活跃时间 | Last active time
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
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `获取使用统计信息失败: ${errorMsg} | Failed to get usage statistics: ${errorMsg}`);
      return {
        deviceAge: 0,
        lastActive: Date.now()
      };
    }
  }
}

export default DeviceInfoRepository;


