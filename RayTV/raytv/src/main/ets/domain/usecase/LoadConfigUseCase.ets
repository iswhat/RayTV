// LoadConfigUseCase.ets - 加载配置用例 // Load configuration use case
import Logger from '../../common/util/Logger';
import { AppConfig, PlayerConfig, DisplayConfig, NetworkConfig, SecurityConfig, AdBlockConfig, HarmonyConfig } from '../../data/bean/Config';
import { ConfigRepository } from '../../data/repository/ConfigRepository';
import { DeviceInfoRepository } from '../../data/repository/DeviceInfoRepository';
import { CacheRepository } from '../../data/repository/CacheRepository';

const TAG = 'LoadConfigUseCase';
const CONFIG_CACHE_KEY = 'app_config_cache';
const CONFIG_CACHE_EXPIRY = 24 * 60 * 60 * 1000; // 24小时缓存过期时间 // 24-hour cache expiry time

/**
 * 加载和管理应用配置的业务用例 // Business use case for loading and managing application configuration
 */
export class LoadConfigUseCase {
  private configRepository: ConfigRepository;
  private deviceInfoRepository: DeviceInfoRepository;
  private cacheRepository: CacheRepository;
  
  constructor(
    configRepository: ConfigRepository,
    deviceInfoRepository: DeviceInfoRepository,
    cacheRepository: CacheRepository
  ) {
    this.configRepository = configRepository;
    this.deviceInfoRepository = deviceInfoRepository;
    this.cacheRepository = cacheRepository;
  }
  
  /**
   * 加载应用配置 // Load application configuration
   * @param forceRefresh 是否强制刷新（跳过缓存） // Whether to force refresh (skip cache)
   * @returns 应用配置对象 // Application configuration object
   */
  public async loadAppConfig(forceRefresh: boolean = false): Promise<AppConfig> {
    try {
      Logger.info(TAG, 'Loading app configuration');
      
      // 如果不是强制刷新，尝试从缓存加载 // If not force refresh, try to load from cache
      if (!forceRefresh) {
        const cachedConfig = await this.getCachedConfig();
        if (cachedConfig) {
          Logger.info(TAG, 'Using cached configuration');
          return cachedConfig;
        }
      }
      
      // 从数据库加载配置 // Load configuration from database
      let config = await this.configRepository.getAppConfig();
      
      // 如果数据库中没有配置，使用默认配置 // If no configuration in database, use default configuration
      if (!config) {
        Logger.info(TAG, 'No configuration found, using default configuration');
        config = this.getDefaultConfig();
        // 保存默认配置到数据库 // Save default configuration to database
        await this.configRepository.saveAppConfig(config);
      }
      
      // 根据设备信息优化配置 // Optimize configuration based on device information
      config = await this.optimizeConfigForDevice(config);
      
      // 缓存配置 // Cache configuration
      await this.cacheConfig(config);
      
      Logger.info(TAG, 'Configuration loaded successfully');
      return config;
    } catch (error) {
      Logger.error(TAG, `Failed to load configuration: ${error}`);
      // 发生错误时返回默认配置 // Return default configuration when error occurs
      const defaultConfig = this.getDefaultConfig();
      await this.cacheConfig(defaultConfig);
      return defaultConfig;
    }
  }
  
  /**
   * 保存应用配置 // Save application configuration
   * @param config 应用配置对象 // Application configuration object
   */
  public async saveAppConfig(config: AppConfig): Promise<void> {
    try {
      Logger.info(TAG, 'Saving app configuration');
      
      // 验证配置 // Validate configuration
      this.validateConfig(config);
      
      // 保存到数据库 // Save to database
      await this.configRepository.saveAppConfig(config);
      
      // 更新缓存 // Update cache
      await this.cacheConfig(config);
      
      Logger.info(TAG, 'Configuration saved successfully');
    } catch (error) {
      Logger.error(TAG, `Failed to save configuration: ${error}`);
      throw error;
    }
  }
  
  /**
   * 更新播放器配置 // Update player configuration
   * @param playerConfig 播放器配置 // Player configuration
   * @returns 更新后的完整配置 // Updated complete configuration
   */
  public async updatePlayerConfig(playerConfig: Partial<PlayerConfig>): Promise<AppConfig> {
    try {
      Logger.info(TAG, 'Updating player configuration');
      
      const currentConfig = await this.loadAppConfig();
      
      const updatedConfig: AppConfig = {
        ...currentConfig,
        player: {
          ...currentConfig.player,
          ...playerConfig
        }
      };
      
      await this.saveAppConfig(updatedConfig);
      return updatedConfig;
    } catch (error) {
      Logger.error(TAG, `Failed to update player configuration: ${error}`);
      throw error;
    }
  }
  
  /**
   * 更新显示配置 // Update display configuration
   * @param displayConfig 显示配置 // Display configuration
   * @returns 更新后的完整配置 // Updated complete configuration
   */
  public async updateDisplayConfig(displayConfig: Partial<DisplayConfig>): Promise<AppConfig> {
    try {
      Logger.info(TAG, 'Updating display configuration');
      
      const currentConfig = await this.loadAppConfig();
      
      const updatedConfig: AppConfig = {
        ...currentConfig,
        display: {
          ...currentConfig.display,
          ...displayConfig
        }
      };
      
      await this.saveAppConfig(updatedConfig);
      return updatedConfig;
    } catch (error) {
      Logger.error(TAG, `Failed to update display configuration: ${error}`);
      throw error;
    }
  }
  
  /**
   * 更新网络配置 // Update network configuration
   * @param networkConfig 网络配置 // Network configuration
   * @returns 更新后的完整配置 // Updated complete configuration
   */
  public async updateNetworkConfig(networkConfig: Partial<NetworkConfig>): Promise<AppConfig> {
    try {
      Logger.info(TAG, 'Updating network configuration');
      
      const currentConfig = await this.loadAppConfig();
      
      const updatedConfig: AppConfig = {
        ...currentConfig,
        network: {
          ...currentConfig.network,
          ...networkConfig
        }
      };
      
      await this.saveAppConfig(updatedConfig);
      
      // 如果网络配置变化，清除网络相关缓存 // If network configuration changes, clear network-related cache
      await this.clearNetworkCache();
      
      return updatedConfig;
    } catch (error) {
      Logger.error(TAG, `Failed to update network configuration: ${error}`);
      throw error;
    }
  }
  
  /**
   * 重置配置到默认值 // Reset configuration to default values
   * @returns 默认配置 // Default configuration
   */
  public async resetToDefaultConfig(): Promise<AppConfig> {
    try {
      Logger.info(TAG, 'Resetting configuration to default values');
      
      const defaultConfig = this.getDefaultConfig();
      
      // 保存默认配置 // Save default configuration
      await this.configRepository.saveAppConfig(defaultConfig);
      
      // 更新缓存 // Update cache
      await this.cacheConfig(defaultConfig);
      
      // 清除所有相关缓存 // Clear all related cache
      await this.clearAllRelatedCache();
      
      return defaultConfig;
    } catch (error) {
      Logger.error(TAG, `Failed to reset configuration: ${error}`);
      throw error;
    }
  }
  
  /**
   * 获取默认配置 // Get default configuration
   * @returns 默认配置对象 // Default configuration object
   */
  private getDefaultConfig(): AppConfig {
    return {
      player: {
        defaultPlayer: 'avplayer',
        enableHardwareDecode: true,
        autoContinuePlay: true,
        rememberPosition: true,
        speedList: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 3.0]
      },
      display: {
        theme: 'system',
        fontSize: 16,
        autoFullScreen: true,
        enableGestures: true
      },
      network: {
        timeout: 30,
        retryCount: 3,
        enableCache: true,
        cacheSize: 50
      },
      security: {
        enableSandbox: true,
        allowThirdParty: false
      },
      adBlock: {
        enabled: false,
        rules: [],
        updateInterval: 24
      },
      harmony: {
        enableVoiceAssistant: true,
        enableDeviceFlow: true,
        enableGestureControl: true
      }
    };
  }
  
  /**
   * 验证配置有效性 // Validate configuration validity
   * @param config 需要验证的配置 // Configuration to validate
   */
  private validateConfig(config: AppConfig): void {
    // 验证播放器配置 // Validate player configuration
    if (config.player) {
      if (config.player.timeout && (config.player.timeout < 5 || config.player.timeout > 300)) {
        throw new Error('Player timeout must be between 5 and 300 seconds');
      }
      if (config.player.speedList.length === 0) {
        throw new Error('Player speed list cannot be empty');
      }
    }
    
    // 验证网络配置 // Validate network configuration
    if (config.network) {
      if (config.network.timeout < 5 || config.network.timeout > 300) {
        throw new Error('Network timeout must be between 5 and 300 seconds');
      }
      if (config.network.retryCount < 0 || config.network.retryCount > 10) {
        throw new Error('Retry count must be between 0 and 10');
      }
      if (config.network.cacheSize < 0 || config.network.cacheSize > 500) {
        throw new Error('Cache size must be between 0 and 500 MB');
      }
    }
  }
  
  /**
   * 根据设备信息优化配置 // Optimize configuration based on device information
   * @param config 初始配置 // Initial configuration
   * @returns 优化后的配置 // Optimized configuration
   */
  private async optimizeConfigForDevice(config: AppConfig): Promise<AppConfig> {
    try {
      const deviceInfo = await this.deviceInfoRepository.getDeviceInfo();
      
      // 根据设备类型调整配置 // Adjust configuration based on device type
      if (deviceInfo.isTvMode) {
        // TV模式下的优化配置 // Optimized configuration for TV mode
        config.display.enableGestures = false; // TV通常不使用手势 // TV usually doesn't use gestures
        config.display.autoFullScreen = true; // TV默认全屏 // TV defaults to full screen
        config.player.enableHardwareDecode = true; // TV优先使用硬件解码 // TV prioritizes hardware decoding
      }
      
      // 根据设备性能调整缓存大小 // Adjust cache size based on device performance
      if (deviceInfo.screenHeight > 2160) { // 4K设备 // 4K device
        config.network.cacheSize = Math.max(config.network.cacheSize, 100);
      }
      
      return config;
    } catch (error) {
      Logger.warn(TAG, `Failed to optimize config for device: ${error}`);
      return config;
    }
  }
  
  /**
   * 缓存配置 // Cache configuration
   */
  private async cacheConfig(config: AppConfig): Promise<void> {
    try {
      await this.cacheRepository.saveObject(CONFIG_CACHE_KEY, config, CONFIG_CACHE_EXPIRY);
    } catch (error) {
      Logger.warn(TAG, `Failed to cache configuration: ${error}`);
    }
  }
  
  /**
   * 获取缓存的配置 // Get cached configuration
   */
  private async getCachedConfig(): Promise<AppConfig | null> {
    try {
      return await this.cacheRepository.getObject<AppConfig>(CONFIG_CACHE_KEY);
    } catch (error) {
      Logger.warn(TAG, `Failed to get cached configuration: ${error}`);
      return null;
    }
  }
  
  /**
   * 清除网络相关缓存 // Clear network-related cache
   */
  private async clearNetworkCache(): Promise<void> {
    try {
      // 清除网络相关的缓存项 // Clear network-related cache items
      const cacheKeys = await this.cacheRepository.getAllKeys();
      const networkKeys = cacheKeys.filter(key => 
        key.includes('network_') || key.includes('http_') || key.includes('api_')
      );
      
      for (const key of networkKeys) {
        await this.cacheRepository.removeObject(key);
      }
    } catch (error) {
      Logger.warn(TAG, `Failed to clear network cache: ${error}`);
    }
  }
  
  /**
   * 清除所有相关缓存 // Clear all related cache
   */
  private async clearAllRelatedCache(): Promise<void> {
    try {
      // 清除配置缓存 // Clear configuration cache
      await this.cacheRepository.removeObject(CONFIG_CACHE_KEY);
      // 清除网络缓存 // Clear network cache
      await this.clearNetworkCache();
      // 清除其他可能受配置影响的缓存 // Clear other cache that may be affected by configuration
      await this.cacheRepository.removeObject('live_hot_keywords');
    } catch (error) {
      Logger.warn(TAG, `Failed to clear related cache: ${error}`);
    }
  }
}
