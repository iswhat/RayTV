// LocalRepository - 本地存储仓库
// 负责处理本地文件和存储相关的操作

import Logger from '../../common/util/Logger';
import StorageUtil from '../../common/util/StorageUtil';
import FileUtil from '../../common/util/FileUtil';
import { LocalStorageType, FileMetadata } from '../model/LocalModel';
import { FileService } from '../service/FileService';

/**
 * 本地存储仓库类
 * 封装所有本地存储和文件操作
 */
class LocalRepository {
  private static instance: LocalRepository;
  private fileService: FileService;
  private initialized: boolean = false;

  // 私有构造函数
  private constructor() {
    this.fileService = FileService.getInstance();
    this.initialize();
  }

  /**
   * 获取LocalRepository实例
   * @returns LocalRepository单例实例
   */
  public static getInstance(): LocalRepository {
    if (!LocalRepository.instance) {
      LocalRepository.instance = new LocalRepository();
    }
    return LocalRepository.instance;
  }

  /**
   * 初始化本地仓库
   */
  public async initialize(): Promise<void> {
    try {
      Logger.info('Initializing local repository');
      
      // 确保必要的目录存在
      await this.ensureDirectories();
      
      this.initialized = true;
      Logger.info('Local repository initialized successfully');
    } catch (error) {
      Logger.error('Failed to initialize local repository', error);
      this.initialized = false;
    }
  }

  /**
   * 确保必要的目录存在
   */
  private async ensureDirectories(): Promise<void> {
    try {
      // 确保缓存目录存在
      await this.fileService.ensureDirectoryExists('cache');
      // 确保下载目录存在
      await this.fileService.ensureDirectoryExists('downloads');
      // 确保字幕目录存在
      await this.fileService.ensureDirectoryExists('subtitles');
      // 确保用户数据目录存在
      await this.fileService.ensureDirectoryExists('user_data');
    } catch (error) {
      Logger.error('Failed to ensure directories', error);
      throw error;
    }
  }

  /**
   * 保存数据到本地存储
   * @param key 存储键名
   * @param value 存储值
   * @param type 存储类型
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
          // 持久化存储使用文件
          const filePath = await this.getPersistentFilePath(key);
          await FileUtil.writeFile(filePath, JSON.stringify(value));
          break;
      }
      
      Logger.debug(`Data saved: ${key}, type: ${LocalStorageType[type]}`);
    } catch (error) {
      Logger.error(`Failed to save data: ${key}`, error);
      throw error;
    }
  }

  /**
   * 从本地存储读取数据
   * @param key 存储键名
   * @param type 存储类型
   * @returns 存储的数据或null
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
      Logger.error(`Failed to get data: ${key}`, error);
      return null;
    }
  }

  /**
   * 删除本地存储数据
   * @param key 存储键名
   * @param type 存储类型
   * @returns 是否删除成功
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
      Logger.error(`Failed to remove data: ${key}`, error);
      return false;
    }
  }

  /**
   * 检查键是否存在
   * @param key 存储键名
   * @param type 存储类型
   * @returns 是否存在
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
      Logger.error(`Failed to check data existence: ${key}`, error);
      return false;
    }
  }

  /**
   * 获取带前缀的键名
   * @param key 原始键名
   * @param type 存储类型
   * @returns 带前缀的键名
   */
  private getPrefixedKey(key: string, type: LocalStorageType): string {
    const prefixes = {
      [LocalStorageType.DEFAULT]: 'default_',
      [LocalStorageType.TEMPORARY]: 'temp_',
      [LocalStorageType.SECURE]: 'secure_',
      [LocalStorageType.PERSISTENT]: 'persist_'
    };
    return `${prefixes[type]}${key}`;
  }

  /**
   * 获取持久化文件路径
   * @param key 存储键名
   * @returns 文件路径
   */
  private async getPersistentFilePath(key: string): Promise<string> {
    const dirPath = await this.fileService.getDirectoryPath('user_data');
    return `${dirPath}/${this.sanitizeFileName(key)}.json`;
  }

  /**
   * 清理文件名
   * @param fileName 原始文件名
   * @returns 清理后的文件名
   */
  private sanitizeFileName(fileName: string): string {
    return fileName.replace(/[^a-zA-Z0-9_-]/g, '_');
  }

  /**
   * 保存文本文件
   * @param filePath 文件路径
   * @param content 文件内容
   * @returns 是否保存成功
   */
  public async saveTextFile(filePath: string, content: string): Promise<boolean> {
    try {
      await FileUtil.writeFile(filePath, content);
      Logger.debug(`Text file saved: ${filePath}`);
      return true;
    } catch (error) {
      Logger.error(`Failed to save text file: ${filePath}`, error);
      return false;
    }
  }

  /**
   * 读取文本文件
   * @param filePath 文件路径
   * @returns 文件内容或null
   */
  public async readTextFile(filePath: string): Promise<string | null> {
    try {
      if (await FileUtil.exists(filePath)) {
        const content = await FileUtil.readFile(filePath);
        return content;
      }
      return null;
    } catch (error) {
      Logger.error(`Failed to read text file: ${filePath}`, error);
      return null;
    }
  }

  /**
   * 保存JSON文件
   * @param filePath 文件路径
   * @param data JSON数据
   * @returns 是否保存成功
   */
  public async saveJsonFile(filePath: string, data: string | number | boolean | null): Promise<boolean> {
    try {
      const jsonString = JSON.stringify(data, null, 2);
      return await this.saveTextFile(filePath, jsonString);
    } catch (error) {
      Logger.error(`Failed to save JSON file: ${filePath}`, error);
      return false;
    }
  }

  /**
   * 读取JSON文件
   * @param filePath 文件路径
   * @returns JSON数据或null
   */
  public async readJsonFile<T>(filePath: string): Promise<T | null> {
    try {
      const content = await this.readTextFile(filePath);
      if (content) {
        return JSON.parse(content) as T;
      }
      return null;
    } catch (error) {
      Logger.error(`Failed to read JSON file: ${filePath}`, error);
      return null;
    }
  }

  /**
   * 获取文件元数据
   * @param filePath 文件路径
   * @returns 文件元数据或null
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
      Logger.error(`Failed to get file metadata: ${filePath}`, error);
      return null;
    }
  }

  /**
   * 列出目录内容
   * @param dirPath 目录路径
   * @returns 文件列表
   */
  public async listDirectory(dirPath: string): Promise<string[]> {
    try {
      return await FileUtil.listFiles(dirPath);
    } catch (error) {
      Logger.error(`Failed to list directory: ${dirPath}`, error);
      return [];
    }
  }

  /**
   * 创建目录
   * @param dirPath 目录路径
   * @returns 是否创建成功
   */
  public async createDirectory(dirPath: string): Promise<boolean> {
    try {
      await FileUtil.createDirectory(dirPath);
      Logger.debug(`Directory created: ${dirPath}`);
      return true;
    } catch (error) {
      Logger.error(`Failed to create directory: ${dirPath}`, error);
      return false;
    }
  }

  /**
   * 删除文件或目录
   * @param path 文件或目录路径
   * @returns 是否删除成功
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
      Logger.error(`Failed to delete: ${path}`, error);
      return false;
    }
  }

  /**
   * 复制文件
   * @param sourcePath 源文件路径
   * @param destPath 目标文件路径
   * @returns 是否复制成功
   */
  public async copyFile(sourcePath: string, destPath: string): Promise<boolean> {
    try {
      await FileUtil.copyFile(sourcePath, destPath);
      Logger.debug(`File copied from ${sourcePath} to ${destPath}`);
      return true;
    } catch (error) {
      Logger.error(`Failed to copy file from ${sourcePath} to ${destPath}`, error);
      return false;
    }
  }

  /**
   * 移动文件
   * @param sourcePath 源文件路径
   * @param destPath 目标文件路径
   * @returns 是否移动成功
   */
  public async moveFile(sourcePath: string, destPath: string): Promise<boolean> {
    try {
      await FileUtil.moveFile(sourcePath, destPath);
      Logger.debug(`File moved from ${sourcePath} to ${destPath}`);
      return true;
    } catch (error) {
      Logger.error(`Failed to move file from ${sourcePath} to ${destPath}`, error);
      return false;
    }
  }

  /**
   * 清空临时存储
   */
  public async clearTemporaryStorage(): Promise<void> {
    try {
      // 获取所有临时键并删除
      const allKeys = await StorageUtil.getAllKeys();
      const tempKeys = allKeys.filter(key => key.startsWith('temp_'));
      
      for (const key of tempKeys) {
        await StorageUtil.remove(key);
      }
      
      // 清空临时目录
      const tempDir = await this.fileService.getDirectoryPath('cache');
      const files = await this.listDirectory(tempDir);
      
      for (const file of files) {
        await this.delete(`${tempDir}/${file}`);
      }
      
      Logger.info('Temporary storage cleared');
    } catch (error) {
      Logger.error('Failed to clear temporary storage', error);
    }
  }

  /**
   * 重置仓库
   */
  public async reset(): Promise<void> {
    try {
      Logger.info('Resetting local repository');
      
      // 清空所有存储
      await this.clearTemporaryStorage();
      
      // 重置其他必要的状态
      
      Logger.info('Local repository reset completed');
    } catch (error) {
      Logger.error('Failed to reset local repository', error);
      throw error;
    }
  }

  /**
   * 获取存储使用情况
   * @returns 使用情况统计
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
      Logger.error('Failed to get storage usage', error);
      return {};
    }
  }
}

export default LocalRepository;
