// ConfigLoader - 配置加载器
import Logger from '../../common/util/Logger';
import http from '@ohos.net.http';
import HttpMethod from '@ohos.net.http';
import fs from '@ohos.file.fs';
import { Site } from '../../data/bean/Site';
import { AppConfig } from '../../data/bean/Config';

/**
 * 配置对象接口，用于规范化处理各种配置格式
 */
interface ConfigObject {
  sites?: Site[];
  data?: Site[];
  appConfig?: AppConfig;
  // 移除了any类型的索引签名，使用更具体的属性定义
}

const TAG = 'ConfigLoader';

/**
 * 配置加载器，提供多源配置加载能力
 */
export class ConfigLoader {
  private static instance: ConfigLoader;
  private cachePath: string;
  
  private constructor() {
    // 初始化缓存路径
    this.cachePath = this.getCachePath();
  }
  
  /**
   * 获取单例实例
   */
  public static getInstance(): ConfigLoader {
    if (!ConfigLoader.instance) {
      ConfigLoader.instance = new ConfigLoader();
    }
    return ConfigLoader.instance;
  }
  
  /**
   * 从URL加载配置
   * @param url 配置URL
   * @param cacheHours 缓存时间（小时），默认使用默认值
   * @param forceRefresh 是否强制刷新（忽略缓存）
   */
  public async loadFromUrl(url: string, cacheHours?: number, forceRefresh: boolean = false): Promise<string> {
    try {
      Logger.info(TAG, `Loading config from URL: ${url}`);
      
      // 验证缓存时间
      const normalizedCacheHours = this.normalizeCacheTime(cacheHours);
      
      // 如果不是强制刷新，先尝试从缓存加载
      if (!forceRefresh) {
        try {
          const cachedContent = await this.loadFromCache(url, normalizedCacheHours);
          if (cachedContent) {
            Logger.info(TAG, `Using cached config (${normalizedCacheHours}h)`);
            return cachedContent;
          }
        } catch (cacheError) {
          Logger.error(TAG, `Failed to load cached config: ${cacheError}`);
        }
      } else {
        Logger.info(TAG, `Force refresh enabled, bypassing cache`);
      }
      
      // 创建HTTP请求
      const request = http.createHttp();
      const response = await request.request(url, {
        method: HttpMethod.GET,
        header: {
          'Content-Type': 'application/json',
          'User-Agent': 'RayTV-HarmonyOS'
        },
        readTimeout: 15000,
        connectTimeout: 10000
      });
      
      if (response.responseCode === 200) {
        const configContent = response.result as string;
        Logger.info(TAG, `Successfully loaded config from URL`);
        
        // 缓存配置
        await this.cacheConfig(url, configContent);
        
        return configContent;
      } else {
        throw new Error(`Failed to load config, status code: ${response.responseCode}`);
      }
    } catch (error) {
      Logger.error(TAG, `Failed to load config from URL: ${error}`);
      
      // 尝试从缓存加载
      try {
        const cachedContent = await this.loadFromCache(url);
        if (cachedContent) {
          Logger.warn(TAG, `Using cached config since network failed`);
          return cachedContent;
        }
      } catch (cacheError) {
        Logger.error(TAG, `Failed to load cached config: ${cacheError}`);
      }
      
      throw error;
    }
  }
  
  /**
   * 从本地文件加载配置
   * @param filePath 文件路径
   */
  public async loadFromFile(filePath: string): Promise<string> {
    try {
      Logger.info(TAG, `Loading config from file: ${filePath}`);
      
      // 检查文件是否存在
      const fileInfo = await fs.getFileStat(filePath);
      if (!fileInfo.isFile) {
        throw new Error('Path is not a file');
      }
      
      // 读取文件内容
      const file = await fs.open(filePath, fs.OpenMode.READ_ONLY);
      const fileContent = await fs.readText(file.fd);
      await fs.close(file.fd);
      
      Logger.info(TAG, `Successfully loaded config from file`);
      return fileContent;
    } catch (error) {
      Logger.error(TAG, `Failed to load config from file: ${error}`);
      throw error;
    }
  }
  
  /**
   * 解析配置内容
   * @param content 配置内容
   */
  public parseConfig(content: string): { sites: Site[]; appConfig?: AppConfig } {
    try {
      Logger.info(TAG, 'Parsing config content');
      
      // 尝试解析为纯JSON
      try {
        const config = JSON.parse(content) as ConfigObject | Site[];
        return this.processConfigObject(config);
      } catch (jsonError) {
        // 如果不是纯JSON，尝试解析为JavaScript格式
        Logger.info(TAG, 'Not pure JSON, trying to parse as JavaScript');
        return this.parseJavaScriptConfig(content);
      }
    } catch (error) {
      Logger.error(TAG, `Failed to parse config: ${error}`);
      throw new Error('Invalid config format');
    }
  }
  
  /**
   * 处理配置对象
   * @param config 配置对象
   */
  private processConfigObject(config: ConfigObject | Site[]): { sites: Site[]; appConfig?: AppConfig } {
    const sites: Site[] = [];
    let appConfig: AppConfig | undefined;
    
    // 检查是否为Site数组
    if (Array.isArray(config)) {
      // 直接是站点数组
      sites.push(...config);
    } else {
      // 处理站点配置
      if (config.sites && Array.isArray(config.sites)) {
        sites.push(...config.sites);
      } else if (config.data && Array.isArray(config.data)) {
        // 兼容旧版配置格式
        sites.push(...config.data);
      }
      
      // 处理应用配置
      if (config.appConfig) {
        appConfig = config.appConfig;
      }
    }
    
    Logger.info(TAG, `Processed ${sites.length} sites`);
    return { sites, appConfig };
  }
  
  /**
   * 解析JavaScript格式配置
   * @param content JavaScript配置内容
   */
  private parseJavaScriptConfig(content: string): { sites: Site[]; appConfig?: AppConfig } {
    try {
      // 尝试提取config变量
      const configMatch = content.match(/var\s+config\s*=\s*([\s\S]*?);/);
      if (configMatch && configMatch[1]) {
        const configObj = JSON.parse(configMatch[1]) as ConfigObject | Site[];
        return this.processConfigObject(configObj);
      }
      
      // 尝试提取data变量
      const dataMatch = content.match(/var\s+data\s*=\s*([\s\S]*?);/);
      if (dataMatch && dataMatch[1]) {
        const dataObj = JSON.parse(dataMatch[1]) as ConfigObject | Site[];
        return this.processConfigObject(dataObj);
      }
      
      throw new Error('Could not find valid JavaScript config');
    } catch (error) {
      Logger.error(TAG, `Failed to parse JavaScript config: ${error}`);
      throw new Error('Invalid JavaScript config format');
    }
  }
  
  /**
   * 缓存配置
   * @param url 配置URL
   * @param content 配置内容
   */
  private async cacheConfig(url: string, content: string): Promise<void> {
    try {
      // 生成缓存文件名
      const cacheFileName = this.getCacheFileName(url);
      const cacheFilePath = `${this.cachePath}/${cacheFileName}`;
      
      // 确保缓存目录存在
      await this.ensureCacheDir();
      
      // 写入缓存文件
      const file = await fs.open(cacheFilePath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY | fs.OpenMode.TRUNCATE);
      await fs.writeText(file.fd, content);
      await fs.close(file.fd);
      
      Logger.debug(TAG, `Config cached to ${cacheFilePath}`);
    } catch (error) {
      Logger.warn(TAG, `Failed to cache config: ${error}`);
      // 缓存失败不影响主要功能
    }
  }
  
  // 缓存过期时间配置（小时）
  private minCacheHours: number = 24;     // 最小24小时
  private maxCacheHours: number = 72;     // 最大72小时
  private defaultCacheHours: number = 24; // 默认24小时

  /**
   * 从缓存加载配置
   * @param url 配置URL
   * @param cacheHours 缓存时间（小时）
   */
  private async loadFromCache(url: string, cacheHours: number = this.defaultCacheHours): Promise<string | null> {
    try {
      const cacheFileName = this.getCacheFileName(url);
      const cacheFilePath = `${this.cachePath}/${cacheFileName}`;
      
      // 检查缓存文件是否存在
      try {
        await fs.getFileStat(cacheFilePath);
      } catch {
        return null;
      }
      
      // 读取缓存文件
      const file = await fs.open(cacheFilePath, fs.OpenMode.READ_ONLY);
      const content = await fs.readText(file.fd);
      await fs.close(file.fd);
      
      // 检查缓存是否过期
      const cacheInfo = await fs.getFileStat(cacheFilePath);
      const cacheTime = cacheInfo.mtimeMs || cacheInfo.ctimeMs || Date.now();
      const now = Date.now();
      const cacheExpiry = this.normalizeCacheTime(cacheHours) * 60 * 60 * 1000; // 转换为毫秒
      
      if (now - cacheTime > cacheExpiry) {
        Logger.debug(TAG, `Cache expired, ignoring`);
        return null;
      }
      
      Logger.debug(TAG, `Loaded config from cache`);
      return content;
    } catch (error) {
      Logger.warn(TAG, `Failed to load from cache: ${error}`);
      return null;
    }
  }
  
  /**
   * 保存站点配置为文件
   * @param sites 站点配置
   * @param filePath 保存路径
   */
  public async saveConfigToFile(sites: Site[], filePath: string): Promise<void> {
    try {
      Logger.info(TAG, `Saving config to file: ${filePath}`);
      
      // 创建配置对象
      const config = {
        sites: sites,
        exportTime: new Date().toISOString(),
        version: '1.0'
      };
      
      // 转换为JSON
      const configJson = JSON.stringify(config, null, 2);
      
      // 写入文件
      const file = await fs.open(filePath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY | fs.OpenMode.TRUNCATE);
      await fs.writeText(file.fd, configJson);
      await fs.close(file.fd);
      
      Logger.info(TAG, `Successfully saved config to file`);
    } catch (error) {
      Logger.error(TAG, `Failed to save config to file: ${error}`);
      throw error;
    }
  }
  
  /**
   * 获取缓存路径
   */
  private getCachePath(): string {
    // 在实际应用中，这里应该使用应用的缓存目录
    // 这里简化处理
    return '/data/storage/el2/base/cache/raytv/config';
  }
  
  /**
   * 确保缓存目录存在
   */
  private async ensureCacheDir(): Promise<void> {
    try {
      // 检查目录是否存在
      try {
        const dirInfo = await fs.getFileStat(this.cachePath);
        if (!dirInfo.isDir) {
          await fs.unlink(this.cachePath);
        }
      } catch {
        // 目录不存在，创建目录
        await fs.mkdir(this.cachePath, true);
      }
    } catch (error) {
      Logger.error(TAG, `Failed to ensure cache directory: ${error}`);
      throw error;
    }
  }
  
  /**
   * 生成缓存文件名
   * @param url URL
   */
  private getCacheFileName(url: string): string {
    // 简单的URL哈希作为缓存文件名
    const hash = this.simpleHash(url);
    return `config_${hash}.json`;
  }
  
  /**
   * 简单的字符串哈希函数
   * @param str 输入字符串
   */
  private simpleHash(str: string): string {
    let hash = 0;
    for (let i = 0; i < str.length; i++) {
      const char = str.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash;
    }
    return Math.abs(hash).toString(36);
  }
  
  /**
   * 清除配置缓存
   */
  public async clearCache(): Promise<void> {
    try {
      Logger.info(TAG, 'Clearing config cache');
      
      // 读取缓存目录
      const files = await fs.listFile(this.cachePath);
      
      // 删除所有缓存文件
      for (const file of files) {
        if (file.name.startsWith('config_') && file.name.endsWith('.json')) {
          const filePath = `${this.cachePath}/${file.name}`;
          await fs.unlink(filePath);
          Logger.debug(TAG, `Deleted cache file: ${file.name}`);
        }
      }
      
      Logger.info(TAG, 'Cache cleared successfully');
    } catch (error) {
      Logger.error(TAG, `Failed to clear cache: ${error}`);
      throw error;
    }
  }
  
  /**
   * 清理过期缓存
   * @param cacheHours 使用的缓存时间阈值（小时），默认使用最小缓存时间
   */
  public async cleanExpiredCache(cacheHours: number = this.minCacheHours): Promise<void> {
    try {
      Logger.info(TAG, `Cleaning expired cache (threshold: ${cacheHours}h)`);
      
      // 读取缓存目录
      const files = await fs.listFile(this.cachePath);
      const now = Date.now();
      const cacheExpiry = this.normalizeCacheTime(cacheHours) * 60 * 60 * 1000;
      
      // 删除过期缓存文件
      for (const file of files) {
        if (file.name.startsWith('config_') && file.name.endsWith('.json')) {
          const filePath = `${this.cachePath}/${file.name}`;
          try {
            const fileInfo = await fs.getFileStat(filePath);
            const cacheTime = fileInfo.mtimeMs || fileInfo.ctimeMs || Date.now();
            
            if (now - cacheTime > cacheExpiry) {
              await fs.unlink(filePath);
              Logger.debug(TAG, `Deleted expired cache file: ${file.name}`);
            }
          } catch (fileError) {
            Logger.error(TAG, `Failed to check/delete cache file ${file.name}: ${fileError}`);
          }
        }
      }
      
      Logger.info(TAG, 'Expired cache cleaned successfully');
    } catch (error) {
      Logger.error(TAG, `Failed to clean expired cache: ${error}`);
    }
  }
  
  /**
   * 获取缓存信息
   */
  public async getCacheInfo(): Promise<{
    cacheSize: number;
    cacheFiles: number;
    lastCacheTime: number;
  }> {
    try {
      const files = await fs.listFile(this.cachePath);
      const configFiles = files.filter(file => 
        file.name.startsWith('config_') && file.name.endsWith('.json')
      );
      
      let totalSize = 0;
      let lastTime = 0;
      
      for (const file of configFiles) {
        const fileInfo = await fs.getFileStat(`${this.cachePath}/${file.name}`);
        totalSize += fileInfo.size || 0;
        const fileTime = fileInfo.mtimeMs || fileInfo.ctimeMs || 0;
        if (fileTime > lastTime) {
          lastTime = fileTime;
        }
      }
      
      return {
        cacheSize: totalSize,
        cacheFiles: configFiles.length,
        lastCacheTime: lastTime
      };
    } catch (error) {
      Logger.error(TAG, `Failed to get cache info: ${error}`);
      return {
        cacheSize: 0,
        cacheFiles: 0,
        lastCacheTime: 0
      };
    }
  }
  
  /**
   * 规范化缓存时间
   * @param hours 缓存时间（小时）
   */
  private normalizeCacheTime(hours?: number): number {
    if (hours === undefined) {
      return this.defaultCacheHours;
    }
    return Math.max(this.minCacheHours, Math.min(this.maxCacheHours, Math.floor(hours)));
  }
  
  /**
   * 设置缓存时间范围
   * @param minHours 最小缓存时间（小时）
   * @param maxHours 最大缓存时间（小时）
   */
  public setCacheTimeRange(minHours: number, maxHours: number): void {
    this.minCacheHours = Math.max(24, minHours);
    this.maxCacheHours = Math.min(72, Math.max(this.minCacheHours, maxHours));
    this.defaultCacheHours = this.minCacheHours; // 默认使用最小缓存时间
    Logger.info(TAG, `Cache time range set to ${this.minCacheHours}-${this.maxCacheHours} hours`);
  }
}