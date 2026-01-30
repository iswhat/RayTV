// ConfigLoader - 配置加载器 | Config loader

import http from '@ohos.net.http';
import fs from '@ohos.file.fs';
import { Site } from '../../data/bean/Site';
import { AppConfig } from '../../data/bean/Config';

/**
 * 配置对象接口，用于规范化处理各种配置格式 | Config object interface for standardized processing of various config formats
 */
interface ConfigObject {
  sites?: Site[];
  data?: Site[];
  appConfig?: AppConfig;
  // 移除any类型的通用键名，使用更具体的属性定义 | Remove generic any type keys, use more specific property definitions
}



/**
 * 配置加载器，提供多源配置加载能力 | Config loader, providing multi-source config loading capability
 */
export class ConfigLoader {
  private static instance: ConfigLoader | null = null;
  private cachePath: string;
  
  private constructor() {
    // 初始化缓存路径 | Initialize cache path
    this.cachePath = this.getCachePath();
  }
  
  /**
   * 获取单例实例 | Get singleton instance
   */
  public static getInstance(): ConfigLoader {
    if (!ConfigLoader.instance) {
      ConfigLoader.instance = new ConfigLoader();
    }
    return ConfigLoader.instance;
  }
  
  /**
   * 从URL加载配置 | Load config from URL
   * @param url 配置URL | Config URL
   * @param cacheHours 缓存时间（小时），默认使用默认值 | Cache time (hours), default to use default value
   * @param forceRefresh 是否强制刷新（绕过缓存） | Whether to force refresh (bypass cache)
   */
  public async loadFromUrl(url: string, cacheHours?: number, forceRefresh: boolean = false): Promise<string> {
    try {
      console.log(`Loading config from URL: ${url}`);
      
      // 验证缓存时间 | Validate cache time
      const normalizedCacheHours = this.normalizeCacheTime(cacheHours);
      
      // 如果不是强制刷新，先尝试从缓存加载 | If not force refresh, try to load from cache first
      if (!forceRefresh) {
        try {
          const cachedContent = await this.loadFromCache(url, normalizedCacheHours);
          if (cachedContent) {
            console.log(`Using cached config (${normalizedCacheHours}h)`);
            return cachedContent;
          }
        } catch (cacheError: Error) {
          console.error(`Failed to load cached config: ${cacheError.message}`);
        }
      } else {
        console.log(`Force refresh enabled, bypassing cache`);
      }
      
      // 创建HTTP请求 | Create HTTP request
      const request = http.createHttp();
      const response = await request.request(url, {
        method: http.RequestMethod.GET,
        header: {
          'Content-Type': 'application/json',
          'User-Agent': 'RayTV-HarmonyOS'
        },
        readTimeout: 15000,
        connectTimeout: 10000
      });
      
      if (response.responseCode === 200) {
        const configContent = response.result as string;
        console.log(`Successfully loaded config from URL`);
        
        // 缓存配置 | Cache config
        await this.cacheConfig(url, configContent);
        
        return configContent;
      } else {
        throw new Error(`Failed to load config, status code: ${response.responseCode}`);
      }
    } catch (error: Error) {
      console.error(`Failed to load config from URL`, error);
      
      // 尝试从缓存加载 | Try to load from cache
      try {
        const cachedContent = await this.loadFromCache(url);
        if (cachedContent) {
          console.warn(`Using cached config since network failed`);
          return cachedContent;
        }
      } catch (cacheError: Error) {
        console.error(`Failed to load cached config`, cacheError);
      }
      
      throw error;
    }
  }
  
  /**
   * 从本地文件加载配置 | Load config from local file
   * @param filePath 文件路径 | File path
   */
  public async loadFromFile(filePath: string): Promise<string> {
    try {
      console.log(`Loading config from file: ${filePath}`);
      
      // 检查文件是否存在 | Check if file exists
      const fileInfo = await fs.getFileStat(filePath);
      if (!fileInfo.isFile) {
        throw new Error('Path is not a file');
      }
      
      // 读取文件内容 | Read file content
      const file = await fs.open(filePath, fs.OpenMode.READ_ONLY);
      const fileContent = await fs.readText(file.fd);
      await fs.close(file.fd);
      
      console.log(`Successfully loaded config from file`);
      return fileContent;
    } catch (error: Error) {
      console.error(`Failed to load config from file`, error);
      throw error;
    }
  }
  
  /**
   * 解析配置内容 | Parse config content
   * @param content 配置内容 | Config content
   */
  public parseConfig(content: string): { sites: Site[]; appConfig?: AppConfig } {
    try {
      console.log('Parsing config content');
      
      // 尝试解析为纯JSON | Try to parse as pure JSON
      try {
        const config = JSON.parse(content) as ConfigObject | Site[];
        return this.processConfigObject(config);
      } catch (jsonError) {
        // 如果不是纯JSON，尝试解析为JavaScript格式 | If not pure JSON, try to parse as JavaScript format
        console.log('Not pure JSON, trying to parse as JavaScript');
        return this.parseJavaScriptConfig(content);
      }
    } catch (error: Error) {
      console.error(`Failed to parse config`, error);
      throw new Error('Invalid config format');
    }
  }
  
  /**
   * 处理配置对象 | Process config object
   * @param config 配置对象 | Config object
   */
  private processConfigObject(config: ConfigObject | Site[]): { sites: Site[]; appConfig?: AppConfig } {
    const sites: Site[] = [];
    let appConfig: AppConfig | undefined;
    
    // 检查是否为Site数组 | Check if it's Site array
    if (Array.isArray(config)) {
      // 直接是站点数组 | Directly site array
      for (let i = 0; i < config.length; i++) {
        sites.push(config[i]);
      }
    } else {
      // 处理站点配置 | Process site config
      if (config.sites && Array.isArray(config.sites)) {
        for (let i = 0; i < config.sites.length; i++) {
          sites.push(config.sites[i]);
        }
      } else if (config.data && Array.isArray(config.data)) {
        // 兼容旧版配置格式 | Compatible with old config format
        for (let i = 0; i < config.data.length; i++) {
          sites.push(config.data[i]);
        }
      }
      
      // 处理应用配置 | Process app config
      if (config.appConfig) {
        appConfig = config.appConfig;
      }
    }
    
    console.log(`Processed ${sites.length} sites`);
    return { sites, appConfig };
  }
  
  /**
   * 解析JavaScript格式配置 | Parse JavaScript format config
   * @param content JavaScript配置内容 | JavaScript config content
   */
  private parseJavaScriptConfig(content: string): { sites: Site[]; appConfig?: AppConfig } {
    try {
      // 尝试提取config变量 | Try to extract config variable
      const configMatch = content.match(/var\s+config\s*=\s*([\s\S]*?);/);
      if (configMatch && configMatch[1]) {
        const configObj = JSON.parse(configMatch[1]) as ConfigObject | Site[];
        return this.processConfigObject(configObj);
      }
      
      // 尝试提取data变量 | Try to extract data variable
      const dataMatch = content.match(/var\s+data\s*=\s*([\s\S]*?);/);
      if (dataMatch && dataMatch[1]) {
        const dataObj = JSON.parse(dataMatch[1]) as ConfigObject | Site[];
        return this.processConfigObject(dataObj);
      }
      
      throw new Error('Could not find valid JavaScript config');
    } catch (error: Error) {
      console.error(`Failed to parse JavaScript config`, error);
      throw new Error('Invalid JavaScript config format');
    }
  }
  
  /**
   * 缓存配置 | Cache config
   * @param url 配置URL | Config URL
   * @param content 配置内容 | Config content
   */
  private async cacheConfig(url: string, content: string): Promise<void> {
    try {
      // 生成缓存文件名 | Generate cache file name
      const cacheFileName = this.getCacheFileName(url);
      const cacheFilePath = `${this.cachePath}/${cacheFileName}`;
      
      // 确保缓存目录存在 | Ensure cache directory exists
      await this.ensureCacheDir();
      
      // 写入缓存文件 | Write to cache file
      const file = await fs.open(cacheFilePath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY | fs.OpenMode.TRUNCATE);
      await fs.writeText(file.fd, content);
      await fs.close(file.fd);
      
      console.debug(`Config cached to ${cacheFilePath}`);
    } catch (error: Error) {
      console.warn(`Failed to cache config`, error);
      // 缓存失败不影响主要功能 | Cache failure does not affect main functionality
    }
  }
  
  // 缓存过期时间配置（小时） | Cache expiration time configuration (hours)
  private minCacheHours: number = 24;     // 最小24小时 | Minimum 24 hours
  private maxCacheHours: number = 72;     // 最大72小时 | Maximum 72 hours
  private defaultCacheHours: number = 24; // 默认24小时 | Default 24 hours

  /**
   * 从缓存加载配置 | Load config from cache
   * @param url 配置URL | Config URL
   * @param cacheHours 缓存时间（小时） | Cache time (hours)
   */
  private async loadFromCache(url: string, cacheHours: number = this.defaultCacheHours): Promise<string | null> {
    try {
      const cacheFileName = this.getCacheFileName(url);
      const cacheFilePath = `${this.cachePath}/${cacheFileName}`;
      
      // 检查缓存文件是否存在 | Check if cache file exists
      try {
        await fs.getFileStat(cacheFilePath);
      } catch {
        return null;
      }
      
      // 读取缓存文件 | Read cache file
      const file = await fs.open(cacheFilePath, fs.OpenMode.READ_ONLY);
      const content = await fs.readText(file.fd);
      await fs.close(file.fd);
      
      // 检查缓存是否过期 | Check if cache is expired
      const cacheInfo = await fs.getFileStat(cacheFilePath);
      const cacheTime = cacheInfo.mtimeMs || cacheInfo.ctimeMs || Date.now();
      const now = Date.now();
      const cacheExpiry = this.normalizeCacheTime(cacheHours) * 60 * 60 * 1000; // 转换为毫秒 | Convert to milliseconds
      if (now - cacheTime > cacheExpiry) {
        console.debug(`Cache expired, ignoring`);
        return null;
      }
      
      console.debug(`Loaded config from cache`);
      return content;
    } catch (error: Error) {
      console.warn(`Failed to load from cache`, error);
      return null;
    }
  }
  
  /**
   * 保存站点配置为文件 | Save site config to file
   * @param sites 站点配置 | Site config
   * @param filePath 保存路径 | Save path
   */
  public async saveConfigToFile(sites: Site[], filePath: string): Promise<void> {
    try {
      console.log(`Saving config to file: ${filePath}`);
      
      // 创建配置对象 | Create config object
      const config = { sites };
      
      // 转换为JSON | Convert to JSON
      const configJson = JSON.stringify(config, null, 2);
      
      // 写入文件 | Write to file
      const file = await fs.open(filePath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY | fs.OpenMode.TRUNCATE);
      await fs.writeText(file.fd, configJson);
      await fs.close(file.fd);
      
      console.log(`Successfully saved config to file`);
    } catch (error: Error) {
      console.error(`Failed to save config to file`, error);
      throw error;
    }
  }
  
  /**
   * 获取缓存路径 | Get cache path
   */
  private getCachePath(): string {
    // 在实际应用中，这里应该使用应用的缓存目录 | In actual application, should use app's cache directory
    // 这里简化处理 | Simplify here
    return '/data/storage/el2/base/cache/raytv/config';
  }
  
  /**
   * 确保缓存目录存在 | Ensure cache directory exists
   */
  private async ensureCacheDir(): Promise<void> {
    try {
      // 检查目录是否存在 | Check if directory exists
      try {
        const dirInfo = await fs.getFileStat(this.cachePath);
        if (!dirInfo.isDir) {
          await fs.unlink(this.cachePath);
        }
      } catch {
        // 目录不存在，创建目录 | Directory not exists, create directory
        await fs.mkdir(this.cachePath, true);
      }
    } catch (error: Error) {
      console.error(`Failed to ensure cache directory`, error);
      throw error;
    }
  }
  
  /**
   * 生成缓存文件名 | Generate cache file name
   * @param url URL
   */
  private getCacheFileName(url: string): string {
    // 简单的URL哈希作为缓存文件名 | Simple URL hash as cache file name
    const hash = this.simpleHash(url);
    return `config_${hash}.json`;
  }
  
  /**
   * 简单的字符串哈希函数 | Simple string hash function
   * @param str 输入字符串 | Input string
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
   * 清除配置缓存 | Clear config cache
   */
  public async clearCache(): Promise<void> {
    try {
      console.log('Clearing config cache');
      
      // 读取缓存目录 | Read cache directory
      const files = await fs.listFile(this.cachePath);
      
      // 删除所有缓存文件 | Delete all cache files
      for (const file of files) {
        if (file.name.startsWith('config_') && file.name.endsWith('.json')) {
          const filePath = `${this.cachePath}/${file.name}`;
          await fs.unlink(filePath);
          console.debug(`Deleted cache file: ${file.name}`);
        }
      }
      
      console.log('Cache cleared successfully');
    } catch (error: Error) {
      console.error(`Failed to clear cache`, error);
      throw error;
    }
  }
  
  /**
   * 清理过期缓存 | Clean expired cache
   * @param cacheHours 使用的缓存时间阈值（小时），默认使用最小缓存时间 | Used cache time threshold (hours), default to use minimum cache time
   */
  public async cleanExpiredCache(cacheHours: number = this.minCacheHours): Promise<void> {
    try {
      console.log(`Cleaning expired cache (threshold: ${cacheHours}h)`);
      
      // 读取缓存目录 | Read cache directory
      const files = await fs.listFile(this.cachePath);
      const now = Date.now();
      const cacheExpiry = this.normalizeCacheTime(cacheHours) * 60 * 60 * 1000;
      
      // 删除过期缓存文件 | Delete expired cache files
      for (const file of files) {
        if (file.name.startsWith('config_') && file.name.endsWith('.json')) {
          const filePath = `${this.cachePath}/${file.name}`;
          try {
            const fileInfo = await fs.getFileStat(filePath);
            const cacheTime = fileInfo.mtimeMs || fileInfo.ctimeMs || Date.now();
            
            if (now - cacheTime > cacheExpiry) {
              await fs.unlink(filePath);
              console.debug(`Deleted expired cache file: ${file.name}`);
            }
          } catch (fileError: Error) {
            console.error(`Failed to check/delete cache file ${file.name}`, fileError);
          }
        }
      }
      
      console.log('Expired cache cleaned successfully');
    } catch (error: Error) {
      console.error('Failed to clean expired cache', error);
    }
  }
  
  /**
   * 获取缓存信息 | Get cache info
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
    } catch (error: Error) {
      console.error('Failed to get cache info', error);
      return {
        cacheSize: 0,
        cacheFiles: 0,
        lastCacheTime: 0
      };
    }
  }
  
  /**
   * 规范化缓存时间 | Normalize cache time
   * @param hours 缓存时间（小时） | Cache time (hours)
   */
  private normalizeCacheTime(hours?: number): number {
    if (hours === undefined) {
      return this.defaultCacheHours;
    }
    return Math.max(this.minCacheHours, Math.min(this.maxCacheHours, Math.floor(hours)));
  }
  
  /**
   * 设置缓存时间范围 | Set cache time range
   * @param minHours 最小缓存时间（小时） | Minimum cache time (hours)
   * @param maxHours 最大缓存时间（小时） | Maximum cache time (hours)
   */
  public setCacheTimeRange(minHours: number, maxHours: number): void {
    this.minCacheHours = Math.max(24, minHours);
    this.maxCacheHours = Math.min(72, Math.max(this.minCacheHours, maxHours));
    this.defaultCacheHours = this.minCacheHours; // 默认使用最小缓存时间 | Default to use minimum cache time
    console.log(`Cache time range set to ${this.minCacheHours}-${this.maxCacheHours} hours`);
  }
}
