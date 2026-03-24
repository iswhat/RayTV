// ConfigLoader - 閰嶇疆鍔犺浇鍣?| Config loader

import http from '@ohos.net.http';
import fs from '@ohos.file.fs';
import { Site } from '../../data/bean/Site';
import { AppConfig } from '../../data/bean/Config';

/**
 * 閰嶇疆瀵硅薄鎺ュ彛锛岀敤浜庤鑼冨寲澶勭悊鍚勭閰嶇疆鏍煎紡 | Config object interface for standardized processing of various config formats
 */
interface ConfigObject {
  sites?: Site[];
  data?: Site[];
  appConfig?: AppConfig;
  // 绉婚櫎any绫诲瀷鐨勯€氱敤閿悕锛屼娇鐢ㄦ洿鍏蜂綋鐨勫睘鎬у畾涔?| Remove generic any type keys, use more specific property definitions
}



/**
 * 閰嶇疆鍔犺浇鍣紝鎻愪緵澶氭簮閰嶇疆鍔犺浇鑳藉姏 | Config loader, providing multi-source config loading capability
 */
export class ConfigLoader {
  private static instance: ConfigLoader | null = null;
  private cachePath: string;
  
  private constructor() {
    // 鍒濆鍖栫紦瀛樿矾寰?| Initialize cache path
    this.cachePath = this.getCachePath();
  }
  
  /**
   * 鑾峰彇鍗曚緥瀹炰緥 | Get singleton instance
   */
  public static getInstance(): ConfigLoader {
    if (!ConfigLoader.instance) {
      ConfigLoader.instance = new ConfigLoader();
    }
    return ConfigLoader.instance;
  }
  
  /**
   * 浠嶶RL鍔犺浇閰嶇疆 | Load config from URL
   * @param url 閰嶇疆URL | Config URL
   * @param cacheHours 缂撳瓨鏃堕棿锛堝皬鏃讹級锛岄粯璁や娇鐢ㄩ粯璁ゅ€?| Cache time (hours), default to use default value
   * @param forceRefresh 鏄惁寮哄埗鍒锋柊锛堢粫杩囩紦瀛橈級 | Whether to force refresh (bypass cache)
   */
  public async loadFromUrl(url: string, cacheHours?: number, forceRefresh: boolean = false): Promise<string> {
    try {
      console.log(`Loading config from URL: ${url}`);
      
      // 楠岃瘉缂撳瓨鏃堕棿 | Validate cache time
      const normalizedCacheHours = this.normalizeCacheTime(cacheHours);
      
      // 濡傛灉涓嶆槸寮哄埗鍒锋柊锛屽厛灏濊瘯浠庣紦瀛樺姞杞?| If not force refresh, try to load from cache first
      if (!forceRefresh) {
        try {
          const cachedContent = await this.loadFromCache(url, normalizedCacheHours);
          if (cachedContent) {
            console.log(`Using cached config (${normalizedCacheHours}h)`);
            return cachedContent;
          }
        } catch (cacheError) {
          console.error(`Failed to load cached config: ${cacheError instanceof Error ? cacheError.message : String(cacheError)}`);
        }
      } else {
        console.log(`Force refresh enabled, bypassing cache`);
      }
      
      // 鍒涘缓HTTP璇锋眰 | Create HTTP request
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
        
        // 缂撳瓨閰嶇疆 | Cache config
        await this.cacheConfig(url, configContent);
        
        return configContent;
      } else {
        throw new Error(`Failed to load config, status code: ${response.responseCode}`);
      }
    } catch (error) {
      console.error(`Failed to load config from URL`, error);
      
      // 灏濊瘯浠庣紦瀛樺姞杞?| Try to load from cache
      try {
        const cachedContent = await this.loadFromCache(url);
        if (cachedContent) {
          console.warn(`Using cached config since network failed`);
          return cachedContent;
        }
      } catch (cacheError) {
        console.error(`Failed to load cached config`, cacheError);
      }
      
      throw error;
    }
  }
  
  /**
   * 浠庢湰鍦版枃浠跺姞杞介厤缃?| Load config from local file
   * @param filePath 鏂囦欢璺緞 | File path
   */
  public async loadFromFile(filePath: string): Promise<string> {
    try {
      console.log(`Loading config from file: ${filePath}`);
      
      // 妫€鏌ユ枃浠舵槸鍚﹀瓨鍦?| Check if file exists
      const fileInfo = await fs.getFileStat(filePath);
      if (!fileInfo.isFile) {
        throw new Error('Path is not a file');
      }
      
      // 璇诲彇鏂囦欢鍐呭 | Read file content
      const file = await fs.open(filePath, fs.OpenMode.READ_ONLY);
      const fileContent = await fs.readText(file.fd);
      await fs.close(file.fd);
      
      console.log(`Successfully loaded config from file`);
      return fileContent;
    } catch (error) {
      console.error(`Failed to load config from file`, error);
      throw error;
    }
  }
  
  /**
   * 瑙ｆ瀽閰嶇疆鍐呭 | Parse config content
   * @param content 閰嶇疆鍐呭 | Config content
   */
  public parseConfig(content: string): { sites: Site[]; appConfig?: AppConfig } {
    try {
      console.log('Parsing config content');
      
      // 灏濊瘯瑙ｆ瀽涓虹函JSON | Try to parse as pure JSON
      try {
        const config = JSON.parse(content) as ConfigObject | Site[];
        return this.processConfigObject(config);
      } catch (jsonError) {
        // 濡傛灉涓嶆槸绾疛SON锛屽皾璇曡В鏋愪负JavaScript鏍煎紡 | If not pure JSON, try to parse as JavaScript format
        console.log('Not pure JSON, trying to parse as JavaScript');
        return this.parseJavaScriptConfig(content);
      }
    } catch (error) {
      console.error(`Failed to parse config`, error);
      throw new Error('Invalid config format');
    }
  }
  
  /**
   * 澶勭悊閰嶇疆瀵硅薄 | Process config object
   * @param config 閰嶇疆瀵硅薄 | Config object
   */
  private processConfigObject(config: ConfigObject | Site[]): { sites: Site[]; appConfig?: AppConfig } {
    const sites: Site[] = [];
    let appConfig: AppConfig | undefined;
    
    // 妫€鏌ユ槸鍚︿负Site鏁扮粍 | Check if it's Site array
    if (Array.isArray(config)) {
      // 鐩存帴鏄珯鐐规暟缁?| Directly site array
      for (let i = 0; i < config.length; i++) {
        sites.push(config[i]);
      }
    } else {
      // 澶勭悊绔欑偣閰嶇疆 | Process site config
      if (config.sites && Array.isArray(config.sites)) {
        for (let i = 0; i < config.sites.length; i++) {
          sites.push(config.sites[i]);
        }
      } else if (config.data && Array.isArray(config.data)) {
        // 鍏煎鏃х増閰嶇疆鏍煎紡 | Compatible with old config format
        for (let i = 0; i < config.data.length; i++) {
          sites.push(config.data[i]);
        }
      }
      
      // 澶勭悊搴旂敤閰嶇疆 | Process app config
      if (config.appConfig) {
        appConfig = config.appConfig;
      }
    }
    
    console.log(`Processed ${sites.length} sites`);
    return { sites, appConfig };
  }
  
  /**
   * 瑙ｆ瀽JavaScript鏍煎紡閰嶇疆 | Parse JavaScript format config
   * @param content JavaScript閰嶇疆鍐呭 | JavaScript config content
   */
  private parseJavaScriptConfig(content: string): { sites: Site[]; appConfig?: AppConfig } {
    try {
      // 灏濊瘯鎻愬彇config鍙橀噺 | Try to extract config variable
      const configMatch = content.match(/var\s+config\s*=\s*([\s\S]*?);/);
      if (configMatch && configMatch[1]) {
        const configObj = JSON.parse(configMatch[1]) as ConfigObject | Site[];
        return this.processConfigObject(configObj);
      }
      
      // 灏濊瘯鎻愬彇data鍙橀噺 | Try to extract data variable
      const dataMatch = content.match(/var\s+data\s*=\s*([\s\S]*?);/);
      if (dataMatch && dataMatch[1]) {
        const dataObj = JSON.parse(dataMatch[1]) as ConfigObject | Site[];
        return this.processConfigObject(dataObj);
      }
      
      throw new Error('Could not find valid JavaScript config');
    } catch (error) {
      console.error(`Failed to parse JavaScript config`, error);
      throw new Error('Invalid JavaScript config format');
    }
  }
  
  /**
   * 缂撳瓨閰嶇疆 | Cache config
   * @param url 閰嶇疆URL | Config URL
   * @param content 閰嶇疆鍐呭 | Config content
   */
  private async cacheConfig(url: string, content: string): Promise<void> {
    try {
      // 鐢熸垚缂撳瓨鏂囦欢鍚?| Generate cache file name
      const cacheFileName = this.getCacheFileName(url);
      const cacheFilePath = `${this.cachePath}/${cacheFileName}`;
      
      // 纭繚缂撳瓨鐩綍瀛樺湪 | Ensure cache directory exists
      await this.ensureCacheDir();
      
      // 鍐欏叆缂撳瓨鏂囦欢 | Write to cache file
      const file = await fs.open(cacheFilePath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY | fs.OpenMode.TRUNCATE);
      await fs.writeText(file.fd, content);
      await fs.close(file.fd);
      
      console.debug(`Config cached to ${cacheFilePath}`);
    } catch (error) {
      console.warn(`Failed to cache config`, error);
      // 缂撳瓨澶辫触涓嶅奖鍝嶄富瑕佸姛鑳?| Cache failure does not affect main functionality
    }
  }
  
  // 缂撳瓨杩囨湡鏃堕棿閰嶇疆锛堝皬鏃讹級 | Cache expiration time configuration (hours)
  private minCacheHours: number = 24;     // 鏈€灏?4灏忔椂 | Minimum 24 hours
  private maxCacheHours: number = 72;     // 鏈€澶?2灏忔椂 | Maximum 72 hours
  private defaultCacheHours: number = 24; // 榛樿24灏忔椂 | Default 24 hours

  /**
   * 浠庣紦瀛樺姞杞介厤缃?| Load config from cache
   * @param url 閰嶇疆URL | Config URL
   * @param cacheHours 缂撳瓨鏃堕棿锛堝皬鏃讹級 | Cache time (hours)
   */
  private async loadFromCache(url: string, cacheHours: number = this.defaultCacheHours): Promise<string | null> {
    try {
      const cacheFileName = this.getCacheFileName(url);
      const cacheFilePath = `${this.cachePath}/${cacheFileName}`;
      
      // 妫€鏌ョ紦瀛樻枃浠舵槸鍚﹀瓨鍦?| Check if cache file exists
      try {
        await fs.getFileStat(cacheFilePath);
      } catch {
        return null;
      }
      
      // 璇诲彇缂撳瓨鏂囦欢 | Read cache file
      const file = await fs.open(cacheFilePath, fs.OpenMode.READ_ONLY);
      const content = await fs.readText(file.fd);
      await fs.close(file.fd);
      
      // 妫€鏌ョ紦瀛樻槸鍚﹁繃鏈?| Check if cache is expired
      const cacheInfo = await fs.getFileStat(cacheFilePath);
      const cacheTime = cacheInfo.mtimeMs || cacheInfo.ctimeMs || Date.now();
      const now = Date.now();
      const cacheExpiry = this.normalizeCacheTime(cacheHours) * 60 * 60 * 1000; // 杞崲涓烘绉?| Convert to milliseconds
      if (now - cacheTime > cacheExpiry) {
        console.debug(`Cache expired, ignoring`);
        return null;
      }
      
      console.debug(`Loaded config from cache`);
      return content;
    } catch (error) {
      console.warn(`Failed to load from cache`, error);
      return null;
    }
  }
  
  /**
   * 淇濆瓨绔欑偣閰嶇疆涓烘枃浠?| Save site config to file
   * @param sites 绔欑偣閰嶇疆 | Site config
   * @param filePath 淇濆瓨璺緞 | Save path
   */
  public async saveConfigToFile(sites: Site[], filePath: string): Promise<void> {
    try {
      console.log(`Saving config to file: ${filePath}`);
      
      // 鍒涘缓閰嶇疆瀵硅薄 | Create config object
      const config = { sites };
      
      // 杞崲涓篔SON | Convert to JSON
      const configJson = JSON.stringify(config, null, 2);
      
      // 鍐欏叆鏂囦欢 | Write to file
      const file = await fs.open(filePath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY | fs.OpenMode.TRUNCATE);
      await fs.writeText(file.fd, configJson);
      await fs.close(file.fd);
      
      console.log(`Successfully saved config to file`);
    } catch (error) {
      console.error(`Failed to save config to file`, error);
      throw error;
    }
  }
  
  /**
   * 鑾峰彇缂撳瓨璺緞 | Get cache path
   */
  private getCachePath(): string {
    // 鍦ㄥ疄闄呭簲鐢ㄤ腑锛岃繖閲屽簲璇ヤ娇鐢ㄥ簲鐢ㄧ殑缂撳瓨鐩綍 | In actual application, should use app's cache directory
    // 杩欓噷绠€鍖栧鐞?| Simplify here
    return '/data/storage/el2/base/cache/raytv/config';
  }
  
  /**
   * 纭繚缂撳瓨鐩綍瀛樺湪 | Ensure cache directory exists
   */
  private async ensureCacheDir(): Promise<void> {
    try {
      // 妫€鏌ョ洰褰曟槸鍚﹀瓨鍦?| Check if directory exists
      try {
        const dirInfo = await fs.getFileStat(this.cachePath);
        if (!dirInfo.isDir) {
          await fs.unlink(this.cachePath);
        }
      } catch {
        // 鐩綍涓嶅瓨鍦紝鍒涘缓鐩綍 | Directory not exists, create directory
        await fs.mkdir(this.cachePath, true);
      }
    } catch (error) {
      console.error(`Failed to ensure cache directory`, error);
      throw error;
    }
  }
  
  /**
   * 鐢熸垚缂撳瓨鏂囦欢鍚?| Generate cache file name
   * @param url URL
   */
  private getCacheFileName(url: string): string {
    // 绠€鍗曠殑URL鍝堝笇浣滀负缂撳瓨鏂囦欢鍚?| Simple URL hash as cache file name
    const hash = this.simpleHash(url);
    return `config_${hash}.json`;
  }
  
  /**
   * 绠€鍗曠殑瀛楃涓插搱甯屽嚱鏁?| Simple string hash function
   * @param str 杈撳叆瀛楃涓?| Input string
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
   * 娓呴櫎閰嶇疆缂撳瓨 | Clear config cache
   */
  public async clearCache(): Promise<void> {
    try {
      console.log('Clearing config cache');
      
      // 璇诲彇缂撳瓨鐩綍 | Read cache directory
      const files = await fs.listFile(this.cachePath);
      
      // 鍒犻櫎鎵€鏈夌紦瀛樻枃浠?| Delete all cache files
      for (const file of files) {
        if (file.name.startsWith('config_') && file.name.endsWith('.json')) {
          const filePath = `${this.cachePath}/${file.name}`;
          await fs.unlink(filePath);
          console.debug(`Deleted cache file: ${file.name}`);
        }
      }
      
      console.log('Cache cleared successfully');
    } catch (error) {
      console.error(`Failed to clear cache`, error);
      throw error;
    }
  }
  
  /**
   * 娓呯悊杩囨湡缂撳瓨 | Clean expired cache
   * @param cacheHours 浣跨敤鐨勭紦瀛樻椂闂撮槇鍊硷紙灏忔椂锛夛紝榛樿浣跨敤鏈€灏忕紦瀛樻椂闂?| Used cache time threshold (hours), default to use minimum cache time
   */
  public async cleanExpiredCache(cacheHours: number = this.minCacheHours): Promise<void> {
    try {
      console.log(`Cleaning expired cache (threshold: ${cacheHours}h)`);
      
      // 璇诲彇缂撳瓨鐩綍 | Read cache directory
      const files = await fs.listFile(this.cachePath);
      const now = Date.now();
      const cacheExpiry = this.normalizeCacheTime(cacheHours) * 60 * 60 * 1000;
      
      // 鍒犻櫎杩囨湡缂撳瓨鏂囦欢 | Delete expired cache files
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
          } catch (fileError) {
            console.error(`Failed to check/delete cache file ${file.name}`, fileError);
          }
        }
      }
      
      console.log('Expired cache cleaned successfully');
    } catch (error) {
      console.error('Failed to clean expired cache', error);
    }
  }
  
  /**
   * 鑾峰彇缂撳瓨淇℃伅 | Get cache info
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
      console.error('Failed to get cache info', error);
      return {
        cacheSize: 0,
        cacheFiles: 0,
        lastCacheTime: 0
      };
    }
  }
  
  /**
   * 瑙勮寖鍖栫紦瀛樻椂闂?| Normalize cache time
   * @param hours 缂撳瓨鏃堕棿锛堝皬鏃讹級 | Cache time (hours)
   */
  private normalizeCacheTime(hours?: number): number {
    if (hours === undefined) {
      return this.defaultCacheHours;
    }
    return Math.max(this.minCacheHours, Math.min(this.maxCacheHours, Math.floor(hours)));
  }
  
  /**
   * 璁剧疆缂撳瓨鏃堕棿鑼冨洿 | Set cache time range
   * @param minHours 鏈€灏忕紦瀛樻椂闂达紙灏忔椂锛?| Minimum cache time (hours)
   * @param maxHours 鏈€澶х紦瀛樻椂闂达紙灏忔椂锛?| Maximum cache time (hours)
   */
  public setCacheTimeRange(minHours: number, maxHours: number): void {
    this.minCacheHours = Math.max(24, minHours);
    this.maxCacheHours = Math.min(72, Math.max(this.minCacheHours, maxHours));
    this.defaultCacheHours = this.minCacheHours; // 榛樿浣跨敤鏈€灏忕紦瀛樻椂闂?| Default to use minimum cache time
    console.log(`Cache time range set to ${this.minCacheHours}-${this.maxCacheHours} hours`);
  }
}
