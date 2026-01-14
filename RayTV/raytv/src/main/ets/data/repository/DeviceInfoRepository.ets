// DeviceInfoRepository.ets - 璁惧淇℃伅鏁版嵁浠撳簱
// 璐熻矗璁惧淇℃伅鐨勬敹闆嗐€佸瓨鍌ㄥ拰绠＄悊

import { SQLiteHelper, QueryCondition } from '../db/SQLiteHelper';
import { DeviceInfo, DeviceType, DeviceCapability, DeviceNetworkInfo } from '../bean/DeviceInfo';
import { Serializable } from '../../types/commonTypes';
import Logger from '../../common/util/Logger';
import StorageUtil, { StorageType } from '../../common/util/StorageUtil';
import BusinessError from '@ohos.base';

const TAG = 'DeviceInfoRepository';

// 妯℃嫙缂栬В鐮佸櫒妫€娴嬬被
class MockCodecDetector {
  /**
   * 妯℃嫙鑾峰彇缂栬В鐮佸櫒鍒楄〃
   */
  static async getCodecList(codecName: string): Promise<string[]> {
    Logger.info(TAG, `Checking support for codec: ${codecName}`);
    
    // 妯℃嫙缂栬В鐮佸櫒鏀寔妫€娴?    const supportedCodecs: Record<string, string[]> = {
      // 瑙嗛缂栬В鐮佸櫒
      'h264': ['h264'],
      'h265': ['h265'],
      'vp8': ['vp8'],
      'vp9': ['vp9'],
      'av1': [], // 妯℃嫙涓嶆敮鎸丄V1
      'mpeg4': ['mpeg4'],
      
      // 闊抽缂栬В鐮佸櫒
      'aac': ['aac'],
      'mp3': ['mp3'],
      'opus': ['opus'],
      'flac': ['flac'],
      'vorbis': ['vorbis'],
      'ac3': [], // 妯℃嫙涓嶆敮鎸丄C3
      'eac3': []  // 妯℃嫙涓嶆敮鎸丒AC3
    };
    
    // 杩斿洖妯℃嫙鐨勭紪瑙ｇ爜鍣ㄥ垪琛?    return supportedCodecs[codecName.toLowerCase()] || [];
  }
}

// 璁惧淇℃伅閿父閲?export const DeviceInfoKeys: Record<string, string> = {
  DEVICE_ID: 'device_id',
  DEVICE_NAME: 'device_name',
  DEVICE_TYPE: 'device_type',
  DEVICE_MODEL: 'device_model',
  DEVICE_BRAND: 'device_brand',
  OS_VERSION: 'os_version',
  APP_VERSION: 'app_version',
  SUPPORTED_VIDEO_CODECS: 'supported_video_codecs',
  SUPPORTED_AUDIO_CODECS: 'supported_audio_codecs',
  MAX_RESOLUTION: 'max_resolution',
  HDR_SUPPORTED: 'hdr_supported',
  DOLBY_ATMOS_SUPPORTED: 'dolby_atmos_supported',
  SCREEN_WIDTH: 'screen_width',
  SCREEN_HEIGHT: 'screen_height',
  SCREEN_DPI: 'screen_dpi',
  NETWORK_INFO: 'network_info',
  LAST_UPDATED: 'last_updated',
  FIRST_USE_TIME: 'first_use_time'
};

// 璁惧淇℃伅琛ㄥ畾涔?const DEVICE_INFO_TABLE = {
  TABLE_NAME: 'device_info',
  COLUMNS: {
    KEY: 'key',
    VALUE: 'value',
    IS_OBJECT: 'is_object',
    UPDATED_AT: 'updated_at'
  }
};

export class DeviceInfoRepository {
  private static instance: DeviceInfoRepository;
  private sqliteHelper: SQLiteHelper;
  private deviceInfoCache: Map<string, Serializable> = new Map();
  private deviceInfo: DeviceInfo | null = null;
  private isInitialized: boolean = false;
  
  private constructor() {
    this.sqliteHelper = SQLiteHelper.getInstance();
  }
  
  /**
   * 鑾峰彇璁惧淇℃伅浠撳簱鍗曚緥瀹炰緥
   */
  public static getInstance(): DeviceInfoRepository {
    if (!DeviceInfoRepository.instance) {
      DeviceInfoRepository.instance = new DeviceInfoRepository();
    }
    return DeviceInfoRepository.instance;
  }
  
  /**
   * 鍒濆鍖栬澶囦俊鎭粨搴?   * 鍔犺浇宸插瓨鍌ㄧ殑璁惧淇℃伅骞舵敹闆嗗綋鍓嶈澶囦俊鎭?   */
  public async initialize(): Promise<void> {
    if (this.isInitialized) {
      return;
    }
    
    try {
      Logger.info(TAG, 'Initializing device info repository');
      
      // 鍔犺浇宸插瓨鍌ㄧ殑璁惧淇℃伅
      await this.loadStoredDeviceInfo();
      
      // 鏀堕泦褰撳墠璁惧淇℃伅
      await this.collectDeviceInfo();
      
      // 妫€鏌ラ娆′娇鐢ㄦ椂闂?      await this.checkFirstUseTime();
      
      this.isInitialized = true;
      Logger.info(TAG, 'Device info repository initialized successfully');
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to initialize device info repository: ${errorMsg}`);
    }
  }
  
  /**
   * 浠庢暟鎹簱鍔犺浇宸插瓨鍌ㄧ殑璁惧淇℃伅
   */
  private async loadStoredDeviceInfo(): Promise<void> {
    try {
      // 浠庢暟鎹簱鏌ヨ鎵€鏈夎澶囦俊鎭褰?      const records = await this.sqliteHelper.query(DEVICE_INFO_TABLE.TABLE_NAME, ['*']);
      
      for (const record of records) {
        const key = record[DEVICE_INFO_TABLE.COLUMNS.KEY];
        let value = record[DEVICE_INFO_TABLE.COLUMNS.VALUE];
        const isObject = record[DEVICE_INFO_TABLE.COLUMNS.IS_OBJECT] === 1;
        
        if (isObject) {
          try {
            value = JSON.parse(value);
          } catch (e) {
            const errorMsg = e instanceof Error ? e.message : 'Unknown error';
            Logger.error(TAG, `Failed to parse device info JSON for key ${key}: ${errorMsg}`);
          }
        }
        
        this.deviceInfoCache.set(key, value);
      }
      
      Logger.debug(TAG, `Loaded ${this.deviceInfoCache.size} device info records`);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to load stored device info: ${errorMsg}`);
    }
  }
  
  /**
   * 鏀堕泦褰撳墠璁惧淇℃伅
   * 鍦℉armonyOS鐜涓嬶紝鍙互閫氳繃鐩稿叧API鑾峰彇璁惧淇℃伅
   */
  private async collectDeviceInfo(): Promise<void> {
    try {
      // 浣跨敤HarmonyOS API鑾峰彇璁惧淇℃伅
      const collectedInfo: Record<string, Serializable> = {
        // 璁惧鍩虹淇℃伅
        [DeviceInfoKeys.DEVICE_TYPE]: DeviceType.SMART_TV,
        [DeviceInfoKeys.DEVICE_MODEL]: this.getSafeValue(DeviceInfoKeys.DEVICE_MODEL, 'Unknown Model'),
        [DeviceInfoKeys.DEVICE_BRAND]: this.getSafeValue(DeviceInfoKeys.DEVICE_BRAND, 'Unknown Brand'),
        [DeviceInfoKeys.OS_VERSION]: this.getSafeValue(DeviceInfoKeys.OS_VERSION, '1.0.0'),
        [DeviceInfoKeys.APP_VERSION]: this.getSafeValue(DeviceInfoKeys.APP_VERSION, '1.0.0'),
        
        // 璁惧鑳藉姏 - 浣跨敤妯℃嫙缂栬В鐮佸櫒妫€娴?        [DeviceInfoKeys.SUPPORTED_VIDEO_CODECS]: await this.detectSupportedVideoCodecs(),
        [DeviceInfoKeys.SUPPORTED_AUDIO_CODECS]: await this.detectSupportedAudioCodecs(),
        [DeviceInfoKeys.MAX_RESOLUTION]: await this.detectMaxResolution(),
        [DeviceInfoKeys.HDR_SUPPORTED]: await this.detectHDRSupport(),
        [DeviceInfoKeys.DOLBY_ATMOS_SUPPORTED]: await this.detectDolbySupport(),
        
        // 灞忓箷淇℃伅
        [DeviceInfoKeys.SCREEN_WIDTH]: this.getSafeValue(DeviceInfoKeys.SCREEN_WIDTH, 1920),
        [DeviceInfoKeys.SCREEN_HEIGHT]: this.getSafeValue(DeviceInfoKeys.SCREEN_HEIGHT, 1080),
        [DeviceInfoKeys.SCREEN_DPI]: this.getSafeValue(DeviceInfoKeys.SCREEN_DPI, 96),
        
        // 鏇存柊鏃堕棿
        [DeviceInfoKeys.LAST_UPDATED]: Date.now()
      };
      
      // 鍒涘缓鎴栨洿鏂拌澶囧敮涓€鏍囪瘑
      const deviceId = await this.getOrCreateDeviceId();
      collectedInfo[DeviceInfoKeys.DEVICE_ID] = deviceId;
      collectedInfo[DeviceInfoKeys.DEVICE_NAME] = `${collectedInfo[DeviceInfoKeys.DEVICE_BRAND]} ${collectedInfo[DeviceInfoKeys.DEVICE_MODEL]}`;
      
      // 淇濆瓨鏀堕泦鍒扮殑璁惧淇℃伅
      for (const [key, value] of Object.entries(collectedInfo)) {
        await this.setDeviceInfo(key, value);
      }
      
      // 鏋勫缓瀹屾暣鐨凞eviceInfo瀵硅薄
      this.buildDeviceInfoObject();
      
      Logger.info(TAG, `Device info collected: ${deviceId}`);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to collect device info: ${errorMsg}`);
    }
  }
  
  /**
   * 鑾峰彇鎴栧垱寤鸿澶囧敮涓€鏍囪瘑
   */
  private async getOrCreateDeviceId(): Promise<string> {
    try {
      // 灏濊瘯浠庡瓨鍌ㄤ腑鑾峰彇璁惧ID
      let deviceId = await this.getDeviceInfo<string>(DeviceInfoKeys.DEVICE_ID);
      
      if (!deviceId) {
        // 濡傛灉涓嶅瓨鍦紝鐢熸垚鏂扮殑璁惧ID
        deviceId = this.generateDeviceId();
        // 浣跨敤瀹夊叏瀛樺偍淇濆瓨璁惧ID
        await this.setDeviceInfo(DeviceInfoKeys.DEVICE_ID, deviceId);
        
        Logger.info(TAG, `Created new device ID: ${deviceId}`);
      }
      
      return deviceId;
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to get or create device ID: ${errorMsg}`);
      return `unknown_${Date.now()}`;
    }
  }
  
  /**
   * 鐢熸垚璁惧鍞竴鏍囪瘑
   */
  private generateDeviceId(): string {
    const timestamp = Date.now();
    const random = Math.random().toString(36).substring(2, 15);
    return `tv_${timestamp}_${random}`;
  }
  
  /**
   * 妫€鏌ラ娆′娇鐢ㄦ椂闂?   */
  private async checkFirstUseTime(): Promise<void> {
    try {
      const firstUseTime = await this.getDeviceInfo<number>(DeviceInfoKeys.FIRST_USE_TIME);
      
      if (!firstUseTime) {
        // 璁板綍棣栨浣跨敤鏃堕棿
        const now = Date.now();
        await this.setDeviceInfo(DeviceInfoKeys.FIRST_USE_TIME, now);
        Logger.info(TAG, `First use time recorded: ${now}`);
      }
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to check first use time: ${errorMsg}`);
    }
  }
  
  /**
   * 鏋勫缓瀹屾暣鐨凞eviceInfo瀵硅薄
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
      Logger.error(TAG, `Failed to build device info object: ${errorMsg}`);
    }
  }
  
  /**
   * 淇濆瓨璁惧淇℃伅
   * @param key 淇℃伅閿?   * @param value 淇℃伅鍊?   * @returns 鏄惁淇濆瓨鎴愬姛
   */
  public async setDeviceInfo(key: string, value: Serializable): Promise<boolean> {
    try {
      Logger.debug(TAG, `Setting device info: ${key}`);
      
      // 搴忓垪鍖栧€?      const valueStr = typeof value === 'object' ? JSON.stringify(value) : String(value);
      const isObject = typeof value === 'object';
      
      const infoData: Record<string, string | number | boolean | null> = {
        [DEVICE_INFO_TABLE.COLUMNS.KEY]: key,
        [DEVICE_INFO_TABLE.COLUMNS.VALUE]: valueStr,
        [DEVICE_INFO_TABLE.COLUMNS.IS_OBJECT]: isObject ? 1 : 0,
        [DEVICE_INFO_TABLE.COLUMNS.UPDATED_AT]: Date.now()
      };
      
      // 妫€鏌ユ槸鍚﹀凡瀛樺湪
      const exists = await this.hasDeviceInfo(key);
      
      if (exists) {
        // 鏇存柊鐜版湁璁板綍
        const conditions: QueryCondition[] = [{
          column: DEVICE_INFO_TABLE.COLUMNS.KEY,
          value: key
        }];
        const result = await this.sqliteHelper.update(DEVICE_INFO_TABLE.TABLE_NAME, infoData, conditions);
        
        if (result.success) {
          // 鏇存柊缂撳瓨
          this.deviceInfoCache.set(key, value);
        }
        
        return result.success;
      } else {
        // 鎻掑叆鏂拌褰?        const result = await this.sqliteHelper.insert(DEVICE_INFO_TABLE.TABLE_NAME, infoData);
        
        if (result.success) {
          // 鏇存柊缂撳瓨
          this.deviceInfoCache.set(key, value);
        }
        
        return result.success;
      }
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to set device info ${key}: ${errorMsg}`);
      return false;
    }
  }
  
  /**
   * 鑾峰彇璁惧淇℃伅
   * @param key 淇℃伅閿?   * @param defaultValue 榛樿鍊?   * @returns 璁惧淇℃伅鍊兼垨榛樿鍊?   */
  public async getDeviceInfo<T = Serializable>(key: string, defaultValue?: T): Promise<T | null> {
    try {
      // 浼樺厛浠庣紦瀛樿幏鍙?      if (this.deviceInfoCache.has(key)) {
        return this.deviceInfoCache.get(key) as T;
      }
      
      // 浠庢暟鎹簱鏌ヨ
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
      
      let value: Serializable = record[DEVICE_INFO_TABLE.COLUMNS.VALUE];
      const isObject = record[DEVICE_INFO_TABLE.COLUMNS.IS_OBJECT] === 1;
      
      if (isObject) {
        try {
          value = JSON.parse(value as string);
        } catch (e) {
          const errorMsg = e instanceof Error ? e.message : 'Unknown error';
          Logger.error(TAG, `Failed to parse device info JSON for key ${key}: ${errorMsg}`);
        }
      }
      
      // 鏇存柊缂撳瓨
      this.deviceInfoCache.set(key, value);
      
      return value as T;
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to get device info ${key}: ${errorMsg}`);
      return defaultValue !== undefined ? defaultValue : null;
    }
  }
  
  /**
   * 浠庣紦瀛樿幏鍙栬澶囦俊鎭紙瀹夊叏鐗堟湰锛?   * @param key 淇℃伅閿?   * @param defaultValue 榛樿鍊?   * @returns 璁惧淇℃伅鍊兼垨榛樿鍊?   */
  private getSafeValue<T>(key: string, defaultValue: T): T {
    return this.deviceInfoCache.get(key) as T || defaultValue;
  }
  
  /**
   * 妫€鏌ヨ澶囦俊鎭槸鍚﹀瓨鍦?   * @param key 淇℃伅閿?   * @returns 鏄惁瀛樺湪
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
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to check device info existence for key ${key}: ${errorMsg}`);
      return false;
    }
  }
  
  /**
   * 鍒犻櫎璁惧淇℃伅
   * @param key 淇℃伅閿?   * @returns 鏄惁鍒犻櫎鎴愬姛
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
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to remove device info ${key}: ${errorMsg}`);
      return false;
    }
  }
  
  /**
   * 鑾峰彇瀹屾暣鐨勮澶囦俊鎭璞?   */
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
   * 鑾峰彇璁惧ID
   */
  public async getDeviceId(): Promise<string> {
    return await this.getOrCreateDeviceId();
  }
  
  /**
   * 鑾峰彇璁惧鑳藉姏
   */
  public async getDeviceCapabilities(): Promise<DeviceCapability[] | null> {
    if (!this.isInitialized) {
      await this.initialize();
    }
    
    return this.deviceInfo?.capabilities || null;
  }
  
  /**
   * 鏇存柊缃戠粶淇℃伅
   * @param networkInfo 缃戠粶淇℃伅
   */
  public async updateNetworkInfo(networkInfo: DeviceNetworkInfo): Promise<boolean> {
    return await this.setDeviceInfo(DeviceInfoKeys.NETWORK_INFO, networkInfo);
  }
  
  /**
   * 鑾峰彇缃戠粶淇℃伅
   */
  public async getNetworkInfo(): Promise<DeviceNetworkInfo | null> {
    return await this.getDeviceInfo<DeviceNetworkInfo>(DeviceInfoKeys.NETWORK_INFO);
  }
  
  /**
   * 妫€娴嬭澶囨敮鎸佺殑瑙嗛缂栬В鐮佸櫒
   */
  private async detectSupportedVideoCodecs(): Promise<string[]> {
    try {
      // 甯歌瑙嗛缂栬В鐮佸櫒鍒楄〃
      const videoCodecs = ['h264', 'h265', 'vp8', 'vp9', 'av1', 'mpeg4'];
      const supportedCodecs: string[] = [];
      
      // 浣跨敤妯℃嫙缂栬В鐮佸櫒妫€娴?      for (const codecName of videoCodecs) {
        try {
          // 妫€鏌ユ槸鍚︽敮鎸佽缂栬В鐮佸櫒鐨勮В鐮佽兘鍔?          const isSupported = await this.checkCodecSupport(codecName, 0); // 0琛ㄧず瑙ｇ爜鍣ㄦā寮?          if (isSupported) {
            supportedCodecs.push(codecName);
          }
        } catch (error) {
          const errorMsg = error instanceof Error ? error.message : 'Unknown error';
          Logger.warn(TAG, `Failed to check support for codec ${codecName}: ${errorMsg}`);
        }
      }
      
      // 濡傛灉妯℃嫙妫€娴嬪け璐ワ紝鍥為€€鍒板熀鏈紪瑙ｇ爜鍣ㄥ垪琛?      return supportedCodecs.length > 0 ? supportedCodecs : ['h264', 'h265', 'vp9'];
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to detect video codecs: ${errorMsg}`);
      return ['h264', 'h265', 'vp9']; // 榛樿鍥為€€鍊?    }
  }
  
  /**
   * 妫€娴嬭澶囨敮鎸佺殑闊抽缂栬В鐮佸櫒
   */
  private async detectSupportedAudioCodecs(): Promise<string[]> {
    try {
      // 甯歌闊抽缂栬В鐮佸櫒鍒楄〃
      const audioCodecs = ['aac', 'mp3', 'opus', 'flac', 'vorbis', 'ac3', 'eac3'];
      const supportedCodecs: string[] = [];
      
      // 浣跨敤妯℃嫙缂栬В鐮佸櫒妫€娴?      for (const codecName of audioCodecs) {
        try {
          // 妫€鏌ユ槸鍚︽敮鎸佽缂栬В鐮佸櫒鐨勮В鐮佽兘鍔?          const isSupported = await this.checkCodecSupport(codecName, 0); // 0琛ㄧず瑙ｇ爜鍣ㄦā寮?          if (isSupported) {
            supportedCodecs.push(codecName);
          }
        } catch (error) {
          const errorMsg = error instanceof Error ? error.message : 'Unknown error';
          Logger.warn(TAG, `Failed to check support for codec ${codecName}: ${errorMsg}`);
        }
      }
      
      // 濡傛灉妯℃嫙妫€娴嬪け璐ワ紝鍥為€€鍒板熀鏈紪瑙ｇ爜鍣ㄥ垪琛?      return supportedCodecs.length > 0 ? supportedCodecs : ['aac', 'mp3', 'opus'];
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to detect audio codecs: ${errorMsg}`);
      return ['aac', 'mp3', 'opus']; // 榛樿鍥為€€鍊?    }
  }
  
  /**
   * 妫€娴嬭澶囨渶澶ф敮鎸佺殑鍒嗚鲸鐜?   */
  private async detectMaxResolution(): Promise<string> {
    try {
      // 杩欓噷鍙互娣诲姞瀹為檯鐨勫垎杈ㄧ巼妫€娴嬮€昏緫
      // 鏆傛椂鏍规嵁璁惧灞忓箷灏哄杩涜浼扮畻
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
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to detect max resolution: ${errorMsg}`);
      return '1080p'; // 榛樿鍥為€€鍊?    }
  }
  
  /**
   * 妫€娴嬭澶囨槸鍚︽敮鎸丠DR
   */
  private async detectHDRSupport(): Promise<boolean> {
    try {
      // 杩欓噷鍙互浣跨敤绯荤粺API妫€娴婬DR鏀寔
      // 鏆傛椂杩斿洖鍩轰簬灞忓箷鍒嗚鲸鐜囩殑浼扮畻鍊?      const screenWidth = this.getSafeValue(DeviceInfoKeys.SCREEN_WIDTH, 1920);
      return screenWidth >= 3840; // 鍋囪4K灞忓箷閫氬父鏀寔HDR
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to detect HDR support: ${errorMsg}`);
      return false; // 榛樿涓嶆敮鎸?    }
  }
  
  /**
   * 妫€娴嬭澶囨槸鍚︽敮鎸丏olby Atmos
   */
  private async detectDolbySupport(): Promise<boolean> {
    try {
      // 杩欓噷鍙互浣跨敤闊抽API妫€娴婦olby鏀寔
      // 鏆傛椂杩斿洖涓€涓粯璁ゅ€?      return false; // 榛樿涓嶆敮鎸侊紝瀹為檯搴旂敤涓渶瑕佷娇鐢ㄧ郴缁烝PI妫€娴?    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to detect Dolby support: ${errorMsg}`);
      return false; // 榛樿涓嶆敮鎸?    }
  }
  
  /**
   * 妫€鏌ョ壒瀹氱紪瑙ｇ爜鍣ㄧ殑鏀寔鎯呭喌
   */
  private async checkCodecSupport(codecName: string, mode: number): Promise<boolean> {
    try {
      // 浣跨敤妯℃嫙缂栬В鐮佸櫒妫€娴嬪櫒鏌ヨ缂栬В鐮佸櫒淇℃伅
      const codecInfos = await MockCodecDetector.getCodecList(codecName);
      return codecInfos.length > 0;
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.warn(TAG, `Error checking codec ${codecName} support: ${errorMsg}`);
      return false;
    }
  }
  
  /**
   * 妫€鏌ヨ澶囨槸鍚︽敮鎸佹寚瀹氱殑瑙嗛缂栬В鐮佸櫒
   * @param codec 瑙嗛缂栬В鐮佸櫒
   */
  public async isVideoCodecSupported(codec: string): Promise<boolean> {
    const codecs = await this.getDeviceInfo<string[]>(DeviceInfoKeys.SUPPORTED_VIDEO_CODECS, []);
    return codecs.includes(codec.toLowerCase());
  }
  
  /**
   * 妫€鏌ヨ澶囨槸鍚︽敮鎸佹寚瀹氱殑闊抽缂栬В鐮佸櫒
   * @param codec 闊抽缂栬В鐮佸櫒
   */
  public async isAudioCodecSupported(codec: string): Promise<boolean> {
    const codecs = await this.getDeviceInfo<string[]>(DeviceInfoKeys.SUPPORTED_AUDIO_CODECS, []);
    return codecs.includes(codec.toLowerCase());
  }
  
  /**
   * 鏇存柊搴旂敤鐗堟湰淇℃伅
   * @param appVersion 搴旂敤鐗堟湰
   */
  public async updateAppVersion(appVersion: string): Promise<boolean> {
    return await this.setDeviceInfo(DeviceInfoKeys.APP_VERSION, appVersion);
  }
  
  /**
   * 娓呯┖鎵€鏈夎澶囦俊鎭紙璋ㄦ厧浣跨敤锛?   */
  public async clearAllDeviceInfo(): Promise<boolean> {
    try {
      Logger.warning(TAG, 'Clearing all device info');
      
      // 淇濈暀璁惧ID鍜岄娆′娇鐢ㄦ椂闂?      const deviceId = await this.getDeviceId();
      const firstUseTime = await this.getDeviceInfo<number>(DeviceInfoKeys.FIRST_USE_TIME);
      
      // 鍒犻櫎鏁版嵁搴撲腑鐨勬墍鏈夎褰?      await this.sqliteHelper.delete(DEVICE_INFO_TABLE.TABLE_NAME);
      
      // 娓呯┖缂撳瓨
      this.deviceInfoCache.clear();
      this.deviceInfo = null;
      
      // 閲嶆柊淇濆瓨閲嶈淇℃伅
      if (deviceId) {
        await this.setDeviceInfo(DeviceInfoKeys.DEVICE_ID, deviceId);
      }
      if (firstUseTime) {
        await this.setDeviceInfo(DeviceInfoKeys.FIRST_USE_TIME, firstUseTime);
      }
      
      // 閲嶆柊鏀堕泦璁惧淇℃伅
      await this.collectDeviceInfo();
      
      Logger.info(TAG, 'All device info cleared and reinitialized');
      return true;
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      Logger.error(TAG, `Failed to clear all device info: ${errorMsg}`);
      return false;
    }
  }
  
  /**
   * 鑾峰彇璁惧浣跨敤缁熻淇℃伅
   */
  public async getUsageStatistics(): Promise<{
    deviceAge: number; // 璁惧浣跨敤澶╂暟
    lastActive: number; // 鏈€鍚庢椿璺冩椂闂?  }> {
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
      Logger.error(TAG, `Failed to get usage statistics: ${errorMsg}`);
      return {
        deviceAge: 0,
        lastActive: Date.now()
      };
    }
  }
}


