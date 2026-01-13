// LocalRepository - 鏈湴瀛樺偍浠撳簱
// 璐熻矗澶勭悊鏈湴鏂囦欢鍜屽瓨鍌ㄧ浉鍏崇殑鎿嶄綔

import Logger from '../../common/util/Logger';
import StorageUtil from '../../common/util/StorageUtil';
import FileUtil from '../../common/util/FileUtil';
import { LocalStorageType, FileMetadata } from '../model/LocalModel';
import { FileService } from '../../service/storage/FileService';

/**
 * 鏈湴瀛樺偍浠撳簱
 * 灏佽鎵€鏈夋湰鍦板瓨鍌ㄥ拰鏂囦欢鎿嶄綔
 */
class LocalRepository {
  private static instance: LocalRepository;
  private fileService: FileService;
  private initialized: boolean = false;

  // 绉佹湁鏋勯€犲嚱鏁?  private constructor() {
    this.fileService = FileService.getInstance();
    this.initialize();
  }

  /**
   * 鑾峰彇LocalRepository瀹炰緥
   * @returns LocalRepository鍗曚緥瀹炰緥
   */
  public static getInstance(): LocalRepository {
    if (!LocalRepository.instance) {
      LocalRepository.instance = new LocalRepository();
    }
    return LocalRepository.instance;
  }

  /**
   * 鍒濆鍖栨湰鍦颁粨搴?   */
  public async initialize(): Promise<void> {
    try {
      Logger.info('Initializing local repository');
      
      // 纭繚蹇呰鐨勭洰褰曞瓨鍦?      await this.ensureDirectories();
      
      this.initialized = true;
      Logger.info('Local repository initialized successfully');
    } catch (error) {
      Logger.error('Failed to initialize local repository', error as Error);
      this.initialized = false;
    }
  }

  /**
   * 纭繚蹇呰鐨勭洰褰曞瓨鍦?   */
  private async ensureDirectories(): Promise<void> {
    try {
      // 纭繚缂撳瓨鐩綍瀛樺湪
      await this.fileService.ensureDirectoryExists('cache');
      // 纭繚涓嬭浇鐩綍瀛樺湪
      await this.fileService.ensureDirectoryExists('downloads');
      // 纭繚瀛楀箷鐩綍瀛樺湪
      await this.fileService.ensureDirectoryExists('subtitles');
      // 纭繚鐢ㄦ埛鏁版嵁鐩綍瀛樺湪
      await this.fileService.ensureDirectoryExists('user_data');
    } catch (error) {
      Logger.error('Failed to ensure directories', error as Error);
      throw error;
    }
  }

  /**
   * 淇濆瓨鏁版嵁鍒版湰鍦板瓨鍌?   * @param key 瀛樺偍閿悕
   * @param value 瀛樺偍鍊?   * @param type 瀛樺偍绫诲瀷
   */
  public async saveData(key: string, value: string | number | boolean | null, type: LocalStorageType = LocalStorageType.DEFAULT): Promise<void> {
    try {
      const prefixedKey = this.getPrefixedKey(key, type);
      
      switch (type) {
        case LocalStorageType.DEFAULT:
        case LocalStorageType.TEMPORARY:
        case LocalStorageType.SECURE:
          await StorageUtil.setObject(prefixedKey, value);
          break;
        case LocalStorageType.PERSISTENT:
          // 鎸佷箙鍖栧瓨鍌ㄤ娇鐢ㄦ枃浠?          const filePath = await this.getPersistentFilePath(key);
          await FileUtil.writeFile(filePath, JSON.stringify(value));
          break;
      }
      
      Logger.debug(`Data saved: ${key}, type: ${LocalStorageType[type]}`);
    } catch (error) {
      Logger.error(`Failed to save data: ${key}`, error as Error);
      throw error;
    }
  }

  /**
   * 浠庢湰鍦板瓨鍌ㄨ鍙栨暟鎹?   * @param key 瀛樺偍閿悕
   * @param type 瀛樺偍绫诲瀷
   * @returns 瀛樺偍鐨勬暟鎹垨null
   */
  public async getData<T>(key: string, type: LocalStorageType = LocalStorageType.DEFAULT): Promise<T | null> {
    try {
      const prefixedKey = this.getPrefixedKey(key, type);
      
      switch (type) {
        case LocalStorageType.DEFAULT:
        case LocalStorageType.TEMPORARY:
        case LocalStorageType.SECURE:
          return await StorageUtil.getObject<T>(prefixedKey);
        case LocalStorageType.PERSISTENT:
          const filePath = await this.getPersistentFilePath(key);
          if (await FileUtil.exists(filePath)) {
            const content = await FileUtil.readFile(filePath);
            return JSON.parse(content) as T;
          }
          return null;
      }
    } catch (error) {
      Logger.error(`Failed to get data: ${key}`, error as Error);
      return null;
    }
  }

  /**
   * 鍒犻櫎鏈湴瀛樺偍鏁版嵁
   * @param key 瀛樺偍閿悕
   * @param type 瀛樺偍绫诲瀷
   * @returns 鏄惁鍒犻櫎鎴愬姛
   */
  public async removeData(key: string, type: LocalStorageType = LocalStorageType.DEFAULT): Promise<boolean> {
    try {
      const prefixedKey = this.getPrefixedKey(key, type);
      
      switch (type) {
        case LocalStorageType.DEFAULT:
        case LocalStorageType.TEMPORARY:
        case LocalStorageType.SECURE:
          await StorageUtil.remove(prefixedKey);
          break;
        case LocalStorageType.PERSISTENT:
          const filePath = await this.getPersistentFilePath(key);
          if (await FileUtil.exists(filePath)) {
            await FileUtil.deleteFile(filePath);
          }
          break;
      }
      
      Logger.debug(`Data removed: ${key}, type: ${LocalStorageType[type]}`);
      return true;
    } catch (error) {
      Logger.error(`Failed to remove data: ${key}`, error as Error);
      return false;
    }
  }

  /**
   * 妫€鏌ラ敭鏄惁瀛樺湪
   * @param key 瀛樺偍閿悕
   * @param type 瀛樺偍绫诲瀷
   * @returns 鏄惁瀛樺湪
   */
  public async hasData(key: string, type: LocalStorageType = LocalStorageType.DEFAULT): Promise<boolean> {
    try {
      const prefixedKey = this.getPrefixedKey(key, type);
      
      switch (type) {
        case LocalStorageType.DEFAULT:
        case LocalStorageType.TEMPORARY:
        case LocalStorageType.SECURE:
          return await StorageUtil.hasKey(prefixedKey);
        case LocalStorageType.PERSISTENT:
          const filePath = await this.getPersistentFilePath(key);
          return await FileUtil.exists(filePath);
      }
    } catch (error) {
      Logger.error(`Failed to check data existence: ${key}`, error as Error);
      return false;
    }
  }

  /**
   * 鑾峰彇甯﹀墠缂€鐨勯敭鍚?   * @param key 鍘熷閿悕
   * @param type 瀛樺偍绫诲瀷
   * @returns 甯﹀墠缂€鐨勯敭鍚?   */
  private getPrefixedKey(key: string, type: LocalStorageType): string {
    const prefixes: Record<LocalStorageType, string> = {
      [LocalStorageType.DEFAULT]: 'default_',
      [LocalStorageType.TEMPORARY]: 'temp_',
      [LocalStorageType.SECURE]: 'secure_',
      [LocalStorageType.PERSISTENT]: 'persistent_'
    };
    return `${prefixes[type]}${key}`;
  }

  /**
   * 鑾峰彇鎸佷箙鍖栨枃浠惰矾寰?   * @param key 瀛樺偍閿悕
   * @returns 鏂囦欢璺緞
   */
  private async getPersistentFilePath(key: string): Promise<string> {
    const dirPath = await this.fileService.getDirectoryPath('user_data');
    return `${dirPath}/${this.sanitizeFileName(key)}.json`;
  }

  /**
   * 娓呯悊鏂囦欢鍚?   * @param fileName 鍘熷鏂囦欢鍚?   * @returns 娓呯悊鍚庣殑鏂囦欢鍚?   */
  private sanitizeFileName(fileName: string): string {
    return fileName.replace(/[^a-zA-Z0-9_-]/g, '_');
  }

  /**
   * 淇濆瓨鏂囨湰鏂囦欢
   * @param filePath 鏂囦欢璺緞
   * @param content 鏂囦欢鍐呭
   * @returns 鏄惁淇濆瓨鎴愬姛
   */
  public async saveTextFile(filePath: string, content: string): Promise<boolean> {
    try {
      await FileUtil.writeFile(filePath, content);
      Logger.debug(`Text file saved: ${filePath}`);
      return true;
    } catch (error) {
      Logger.error(`Failed to save text file: ${filePath}`, error as Error);
      return false;
    }
  }

  /**
   * 璇诲彇鏂囨湰鏂囦欢
   * @param filePath 鏂囦欢璺緞
   * @returns 鏂囦欢鍐呭鎴杗ull
   */
  public async readTextFile(filePath: string): Promise<string | null> {
    try {
      if (await FileUtil.exists(filePath)) {
        const content = await FileUtil.readFile(filePath);
        return content;
      }
      return null;
    } catch (error) {
      Logger.error(`Failed to read text file: ${filePath}`, error as Error);
      return null;
    }
  }

  /**
   * 淇濆瓨JSON鏂囦欢
   * @param filePath 鏂囦欢璺緞
   * @param data JSON鏁版嵁
   * @returns 鏄惁淇濆瓨鎴愬姛
   */
  public async saveJsonFile(filePath: string, data: string | number | boolean | null): Promise<boolean> {
    try {
      const jsonString = JSON.stringify(data, null, 2);
      return await this.saveTextFile(filePath, jsonString);
    } catch (error) {
      Logger.error(`Failed to save JSON file: ${filePath}`, error as Error);
      return false;
    }
  }

  /**
   * 璇诲彇JSON鏂囦欢
   * @param filePath 鏂囦欢璺緞
   * @returns JSON鏁版嵁鎴杗ull
   */
  public async readJsonFile<T>(filePath: string): Promise<T | null> {
    try {
      const content = await this.readTextFile(filePath);
      if (content) {
        return JSON.parse(content) as T;
      }
      return null;
    } catch (error) {
      Logger.error(`Failed to read JSON file: ${filePath}`, error as Error);
      return null;
    }
  }

  /**
   * 鑾峰彇鏂囦欢鍏冩暟鎹?   * @param filePath 鏂囦欢璺緞
   * @returns 鏂囦欢鍏冩暟鎹垨null
   */
  public async getFileMetadata(filePath: string): Promise<FileMetadata | null> {
    try {
      if (await FileUtil.exists(filePath)) {
        const stats = await FileUtil.getFileStats(filePath);
        return {
          path: filePath,
          name: FileUtil.getFileName(filePath),
          size: stats.size,
          modifiedAt: stats.mtimeMs,
          isDirectory: stats.isDirectory
        };
      }
      return null;
    } catch (error) {
      Logger.error(`Failed to get file metadata: ${filePath}`, error as Error);
      return null;
    }
  }

  /**
   * 鍒楀嚭鐩綍鍐呭
   * @param dirPath 鐩綍璺緞
   * @returns 鏂囦欢鍒楄〃
   */
  public async listDirectory(dirPath: string): Promise<string[]> {
    try {
      return await FileUtil.listFiles(dirPath);
    } catch (error) {
      Logger.error(`Failed to list directory: ${dirPath}`, error as Error);
      return [];
    }
  }

  /**
   * 鍒涘缓鐩綍
   * @param dirPath 鐩綍璺緞
   * @returns 鏄惁鍒涘缓鎴愬姛
   */
  public async createDirectory(dirPath: string): Promise<boolean> {
    try {
      await FileUtil.createDirectory(dirPath);
      Logger.debug(`Directory created: ${dirPath}`);
      return true;
    } catch (error) {
      Logger.error(`Failed to create directory: ${dirPath}`, error as Error);
      return false;
    }
  }

  /**
   * 鍒犻櫎鏂囦欢鎴栫洰褰?   * @param path 鏂囦欢鎴栫洰褰曡矾寰?   * @returns 鏄惁鍒犻櫎鎴愬姛
   */
  public async delete(path: string): Promise<boolean> {
    try {
      if (await FileUtil.exists(path)) {
        const stats = await FileUtil.getFileStats(path);
        if (stats.isDirectory) {
          await FileUtil.deleteDirectory(path);
          Logger.debug(`Directory deleted: ${path}`);
        } else {
          await FileUtil.deleteFile(path);
          Logger.debug(`File deleted: ${path}`);
        }
        return true;
      }
      return false;
    } catch (error) {
      Logger.error(`Failed to delete: ${path}`, error as Error);
      return false;
    }
  }

  /**
   * 澶嶅埗鏂囦欢
   * @param sourcePath 婧愭枃浠惰矾寰?   * @param destPath 鐩爣鏂囦欢璺緞
   * @returns 鏄惁澶嶅埗鎴愬姛
   */
  public async copyFile(sourcePath: string, destPath: string): Promise<boolean> {
    try {
      await FileUtil.copyFile(sourcePath, destPath);
      Logger.debug(`File copied from ${sourcePath} to ${destPath}`);
      return true;
    } catch (error) {
      Logger.error(`Failed to copy file from ${sourcePath} to ${destPath}`, error as Error);
      return false;
    }
  }

  /**
   * 绉诲姩鏂囦欢
   * @param sourcePath 婧愭枃浠惰矾寰?   * @param destPath 鐩爣鏂囦欢璺緞
   * @returns 鏄惁绉诲姩鎴愬姛
   */
  public async moveFile(sourcePath: string, destPath: string): Promise<boolean> {
    try {
      await FileUtil.moveFile(sourcePath, destPath);
      Logger.debug(`File moved from ${sourcePath} to ${destPath}`);
      return true;
    } catch (error) {
      Logger.error(`Failed to move file from ${sourcePath} to ${destPath}`, error as Error);
      return false;
    }
  }

  /**
   * 娓呯┖涓存椂瀛樺偍
   */
  public async clearTemporaryStorage(): Promise<void> {
    try {
      // 鑾峰彇鎵€鏈変复鏃堕敭骞跺垹闄?      const allKeys = await StorageUtil.getAllKeys();
      const tempKeys = allKeys.filter(key => key.startsWith('temp_'));
      
      for (const key of tempKeys) {
        await StorageUtil.remove(key);
      }
      
      // 娓呯┖涓存椂鐩綍
      const tempDir = await this.fileService.getDirectoryPath('cache');
      const files = await this.listDirectory(tempDir);
      
      for (const file of files) {
        await this.delete(`${tempDir}/${file}`);
      }
      
      Logger.info('Temporary storage cleared');
    } catch (error) {
      Logger.error('Failed to clear temporary storage', error as Error);
    }
  }

  /**
   * 閲嶇疆浠撳簱
   */
  public async reset(): Promise<void> {
    try {
      Logger.info('Resetting local repository');
      
      // 娓呯┖鎵€鏈夊瓨鍌?      await this.clearTemporaryStorage();
      
      // 閲嶇疆鍏朵粬蹇呰鐨勭姸鎬?      
      Logger.info('Local repository reset completed');
    } catch (error) {
      Logger.error('Failed to reset local repository', error as Error);
      throw error;
    }
  }

  /**
   * 鑾峰彇瀛樺偍浣跨敤鎯呭喌
   * @returns 浣跨敤鎯呭喌缁熻
   */
  public async getStorageUsage(): Promise<Record<string, number>> {
    try {
      const usage: Record<string, number> = {};
      const directories = ['cache', 'downloads', 'subtitles', 'user_data'];
      
      for (const dir of directories) {
        const dirPath = await this.fileService.getDirectoryPath(dir);
        if (await FileUtil.exists(dirPath)) {
          const size = await FileUtil.getDirectorySize(dirPath);
          usage[dir] = size;
        }
      }
      
      return usage;
    } catch (error) {
      Logger.error('Failed to get storage usage', error as Error);
      return {};
    }
  }
}

export default LocalRepository;



