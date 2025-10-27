// LocalRepository - 本地数据仓库类
// 负责管理本地文件和存储相关操作，提供统一的数据访问接口

import Logger from '../../common/util/Logger';
import { FileUtil } from '../../utils/FileUtil';
import { StorageUtil } from '../../utils/StorageUtil';
import { EventBusUtil } from '../../utils/EventBusUtil';
import {
  LocalStorageType,
  LocalFileType,
  LocalFileFormat,
  LocalStorageLocation,
  FileMetadata,
  DirectoryInfo,
  StorageDevice,
  StorageOperationResult,
  SearchParams
} from '../model/LocalModel';

/**
 * 本地存储事件类型
 */
export const LocalStorageEventType = {
  FILE_ADDED: 'local:fileAdded',
  FILE_UPDATED: 'local:fileUpdated',
  FILE_DELETED: 'local:fileDeleted',
  DIRECTORY_CREATED: 'local:directoryCreated',
  DIRECTORY_DELETED: 'local:directoryDeleted',
  STORAGE_SCAN_STARTED: 'local:storageScanStarted',
  STORAGE_SCAN_COMPLETED: 'local:storageScanCompleted',
  STORAGE_SCAN_PROGRESS: 'local:storageScanProgress',
  STORAGE_DEVICE_CONNECTED: 'local:storageDeviceConnected',
  STORAGE_DEVICE_DISCONNECTED: 'local:storageDeviceDisconnected',
  STORAGE_ERROR: 'local:storageError'
} as const;

/**
 * 文件变更事件数据
 */
export interface FileChangeEvent {
  path: string;        // 文件路径
  fileType: LocalFileType; // 文件类型
  metadata?: FileMetadata;  // 文件元数据
}

/**
 * 目录变更事件数据
 */
export interface DirectoryChangeEvent {
  path: string;              // 目录路径
  directoryInfo?: DirectoryInfo; // 目录信息
}

/**
 * 扫描进度事件数据
 */
export interface ScanProgressEvent {
  deviceId: string;         // 设备ID
  path: string;             // 当前扫描路径
  progress: number;         // 进度百分比 (0-100)
  filesFound: number;       // 已发现文件数
  directoriesFound: number; // 已发现目录数
  totalSize: number;        // 总大小
}

/**
 * 本地数据仓库类
 */
export class LocalRepository {
  private static instance: LocalRepository;
  private logger = Logger.getInstance();
  private fileUtil = FileUtil.getInstance();
  private storageUtil = StorageUtil.getInstance();
  private eventBus = EventBusUtil.getInstance();
  
  // 存储设备列表
  private storageDevices: Map<string, StorageDevice> = new Map();
  
  // 最近扫描的文件缓存
  private recentScans: Map<string, { files: FileMetadata[]; directories: DirectoryInfo[]; timestamp: number }> = new Map();
  
  // 扫描任务状态
  private scanningTasks: Map<string, boolean> = new Map();
  
  // 默认扫描选项
  private defaultScanOptions = {
    recursive: true,
    fileTypes: [LocalFileType.VIDEO, LocalFileType.AUDIO, LocalFileType.IMAGE, LocalFileType.SUBTITLE],
    maxDepth: 10,
    followSymlinks: false
  };
  
  // 缓存过期时间（毫秒）
  private cacheExpiryTime = 30 * 60 * 1000; // 30分钟

  /**
   * 私有构造函数
   */
  private constructor() {
    this.logger.info('LocalRepository initialized');
    this.setupEventListeners();
  }

  /**
   * 获取LocalRepository单例实例
   */
  public static getInstance(): LocalRepository {
    if (!LocalRepository.instance) {
      LocalRepository.instance = new LocalRepository();
    }
    return LocalRepository.instance;
  }

  /**
   * 设置事件监听器
   */
  private setupEventListeners(): void {
    // 监听存储设备连接事件（模拟，实际应从系统获取）
    // 这里仅作为示例，真实实现应通过系统API监听
  }

  /**
   * 初始化本地数据仓库
   */
  public async initialize(): Promise<void> {
    try {
      // 初始化时刷新存储设备列表
      await this.refreshStorageDevices();
      
      // 加载设备信息缓存
      await this.loadDeviceCache();
      
      this.logger.info('LocalRepository initialized successfully');
    } catch (error) {
      this.logger.error('Failed to initialize LocalRepository', error as Error);
      
      // 发布存储错误事件
      this.eventBus.emit(LocalStorageEventType.STORAGE_ERROR, { error });
    }
  }

  /**
   * 获取所有存储设备
   */
  public async getStorageDevices(): Promise<StorageDevice[]> {
    await this.refreshStorageDevices();
    return Array.from(this.storageDevices.values());
  }

  /**
   * 获取特定存储设备
   * @param deviceId 设备ID
   */
  public getStorageDevice(deviceId: string): StorageDevice | undefined {
    return this.storageDevices.get(deviceId);
  }

  /**
   * 刷新存储设备列表
   */
  public async refreshStorageDevices(): Promise<void> {
    try {
      // 实际实现应该调用系统API获取存储设备
      // 这里仅作为示例，创建一些模拟的存储设备
      this.storageDevices.clear();
      
      // 模拟内部存储
      this.storageDevices.set('internal', {
        id: 'internal',
        name: 'Internal Storage',
        path: '/storage/emulated/0',
        type: LocalStorageLocation.INTERNAL,
        totalSize: 128 * 1024 * 1024 * 1024, // 128GB
        availableSize: 45 * 1024 * 1024 * 1024, // 45GB可用
        isRemovable: false,
        isMounted: true,
        fileSystem: 'ext4',
        lastAccessed: Date.now()
      });
      
      // 模拟SD卡
      this.storageDevices.set('sdcard', {
        id: 'sdcard',
        name: 'SD Card',
        path: '/storage/1234-5678',
        type: LocalStorageLocation.EXTERNAL,
        totalSize: 64 * 1024 * 1024 * 1024, // 64GB
        availableSize: 28 * 1024 * 1024 * 1024, // 28GB可用
        isRemovable: true,
        isMounted: true,
        fileSystem: 'FAT32',
        lastAccessed: Date.now()
      });
      
      // 发布设备连接事件（如果有新设备）
      // 实际实现应该比较前后的设备列表并发布相应事件
      
      this.logger.info(`Found ${this.storageDevices.size} storage devices`);
    } catch (error) {
      this.logger.error('Failed to refresh storage devices', error as Error);
      
      // 发布存储错误事件
      this.eventBus.emit(LocalStorageEventType.STORAGE_ERROR, { error });
    }
  }

  /**
   * 扫描指定目录
   * @param path 扫描路径
   * @param options 扫描选项
   */
  public async scanDirectory(
    path: string,
    options?: {
      recursive?: boolean;
      fileTypes?: LocalFileType[];
      maxDepth?: number;
      followSymlinks?: boolean;
      filters?: { extensions?: string[]; minSize?: number; maxSize?: number; modifiedAfter?: number; modifiedBefore?: number };
    }
  ): Promise<{
    files: FileMetadata[];
    directories: DirectoryInfo[];
  }> {
    try {
      // 检查路径是否存在
      if (!await this.fileUtil.exists(path)) {
        throw new Error(`Path does not exist: ${path}`);
      }
      
      // 检查路径是否为目录
      const isDirectory = await this.fileUtil.isDirectory(path);
      if (!isDirectory) {
        throw new Error(`Path is not a directory: ${path}`);
      }
      
      // 合并扫描选项
      const scanOptions = {
        ...this.defaultScanOptions,
        ...options,
        filters: {
          ...(options?.filters || {})
        }
      };
      
      // 生成扫描缓存键
      const cacheKey = `${path}_${JSON.stringify(scanOptions)}`;
      
      // 检查缓存是否有效
      const cachedResult = this.recentScans.get(cacheKey);
      if (cachedResult && Date.now() - cachedResult.timestamp < this.cacheExpiryTime) {
        this.logger.debug(`Using cached scan results for: ${path}`);
        return {
          files: cachedResult.files,
          directories: cachedResult.directories
        };
      }
      
      // 标记为正在扫描
      const scanId = `${Date.now()}_${path}`;
      this.scanningTasks.set(scanId, true);
      
      // 发布扫描开始事件
      this.eventBus.emit(LocalStorageEventType.STORAGE_SCAN_STARTED, {
        path,
        options: scanOptions
      });
      
      // 开始扫描
      const result = await this.performScan(path, scanOptions, scanId);
      
      // 缓存结果
      this.recentScans.set(cacheKey, {
        files: result.files,
        directories: result.directories,
        timestamp: Date.now()
      });
      
      // 清理过期缓存
      this.cleanupOldCache();
      
      // 发布扫描完成事件
      this.eventBus.emit(LocalStorageEventType.STORAGE_SCAN_COMPLETED, {
        path,
        result,
        scanTime: Date.now() - parseInt(scanId.split('_')[0])
      });
      
      // 移除扫描任务标记
      this.scanningTasks.delete(scanId);
      
      this.logger.info(`Scan completed for ${path}`, {
        filesFound: result.files.length,
        directoriesFound: result.directories.length
      });
      
      return result;
    } catch (error) {
      this.logger.error(`Failed to scan directory: ${path}`, error as Error);
      
      // 发布存储错误事件
      this.eventBus.emit(LocalStorageEventType.STORAGE_ERROR, { path, error });
      
      throw error;
    }
  }

  /**
   * 执行扫描（递归）
   */
  private async performScan(
    path: string,
    options: {
      recursive: boolean;
      fileTypes: LocalFileType[];
      maxDepth: number;
      followSymlinks: boolean;
      filters?: { extensions?: string[]; minSize?: number; maxSize?: number; modifiedAfter?: number; modifiedBefore?: number };
    },
    scanId: string,
    currentDepth: number = 0
  ): Promise<{
    files: FileMetadata[];
    directories: DirectoryInfo[];
  }> {
    const files: FileMetadata[] = [];
    const directories: DirectoryInfo[] = [];
    
    try {
      // 获取目录内容
      const entries = await this.fileUtil.readDirectory(path);
      
      let processedCount = 0;
      
      for (const entry of entries) {
        // 检查是否应该继续扫描
        if (!this.scanningTasks.get(scanId)) {
          break;
        }
        
        const entryPath = `${path}/${entry}`;
        
        try {
          // 获取文件信息
          const stats = await this.fileUtil.getFileStats(entryPath);
          
          if (stats.isDirectory) {
            // 处理目录
            const directoryInfo: DirectoryInfo = {
              path: entryPath,
              name: entry,
              createdAt: stats.createdAt,
              modifiedAt: stats.modifiedAt,
              size: 0, // 目录大小需要递归计算
              isSymlink: stats.isSymlink
            };
            
            directories.push(directoryInfo);
            
            // 递归扫描子目录
            if (options.recursive && currentDepth < options.maxDepth && 
                (options.followSymlinks || !stats.isSymlink)) {
              const subDirResult = await this.performScan(entryPath, options, scanId, currentDepth + 1);
              files.push(...subDirResult.files);
              directories.push(...subDirResult.directories);
            }
          } else {
            // 处理文件
            const fileExtension = this.fileUtil.getFileExtension(entry).toLowerCase();
            const fileType = this.detectFileType(fileExtension);
            
            // 检查文件类型过滤
            if (options.fileTypes.includes(fileType)) {
              // 检查其他过滤器
              if (this.matchesFilters(stats, fileExtension, options.filters)) {
                const fileMetadata: FileMetadata = {
                  path: entryPath,
                  name: entry,
                  extension: fileExtension,
                  type: fileType,
                  format: this.detectFileFormat(fileExtension),
                  size: stats.size,
                  createdAt: stats.createdAt,
                  modifiedAt: stats.modifiedAt,
                  isSymlink: stats.isSymlink
                };
                
                files.push(fileMetadata);
              }
            }
          }
        } catch (error) {
          this.logger.warn(`Failed to process entry: ${entryPath}`, error as Error);
        }
        
        // 更新进度
        processedCount++;
        if (processedCount % 10 === 0) {
          const progress = Math.floor((processedCount / entries.length) * 100);
          this.eventBus.emit(LocalStorageEventType.STORAGE_SCAN_PROGRESS, {
            path,
            progress,
            filesFound: files.length,
            directoriesFound: directories.length
          } as ScanProgressEvent);
        }
      }
      
      return { files, directories };
    } catch (error) {
      this.logger.error(`Error during scan of ${path}`, error as Error);
      return { files: [], directories: [] };
    }
  }

  /**
   * 停止正在进行的扫描
   */
  public stopScan(scanId?: string): void {
    if (scanId) {
      this.scanningTasks.delete(scanId);
      this.logger.info(`Stopped scan: ${scanId}`);
    } else {
      // 停止所有扫描
      this.scanningTasks.clear();
      this.logger.info('Stopped all scanning tasks');
    }
  }

  /**
   * 搜索本地文件
   * @param params 搜索参数
   */
  public async searchFiles(params: SearchParams): Promise<FileMetadata[]> {
    try {
      let results: FileMetadata[] = [];
      
      // 确定搜索位置
      const searchPaths = params.paths || [];
      
      // 如果没有指定路径，搜索所有可用存储设备
      if (searchPaths.length === 0) {
        const devices = await this.getStorageDevices();
        for (const device of devices) {
          if (device.isMounted) {
            searchPaths.push(device.path);
          }
        }
      }
      
      // 在每个路径中搜索
      for (const path of searchPaths) {
        // 先扫描目录（可能使用缓存）
        const scanResult = await this.scanDirectory(path, {
          recursive: params.recursive !== false,
          fileTypes: params.fileTypes || this.defaultScanOptions.fileTypes,
          maxDepth: params.maxDepth || this.defaultScanOptions.maxDepth,
          filters: params.filters
        });
        
        // 对扫描结果应用搜索条件
        const filteredResults = scanResult.files.filter(file => {
          // 名称搜索
          if (params.namePattern) {
            const regex = new RegExp(params.namePattern, 'i');
            if (!regex.test(file.name)) {
              return false;
            }
          }
          
          // 大小搜索
          if (params.minSize !== undefined && file.size < params.minSize) {
            return false;
          }
          if (params.maxSize !== undefined && file.size > params.maxSize) {
            return false;
          }
          
          // 时间搜索
          if (params.createdAfter !== undefined && file.createdAt < params.createdAfter) {
            return false;
          }
          if (params.createdBefore !== undefined && file.createdAt > params.createdBefore) {
            return false;
          }
          if (params.modifiedAfter !== undefined && file.modifiedAt < params.modifiedAfter) {
            return false;
          }
          if (params.modifiedBefore !== undefined && file.modifiedAt > params.modifiedBefore) {
            return false;
          }
          
          // 扩展名搜索
          if (params.extensions && params.extensions.length > 0) {
            if (!params.extensions.includes(file.extension)) {
              return false;
            }
          }
          
          return true;
        });
        
        results = results.concat(filteredResults);
      }
      
      // 排序结果
      if (params.sortBy) {
        results.sort((a, b) => {
          const aValue = a[params.sortBy as keyof FileMetadata];
          const bValue = b[params.sortBy as keyof FileMetadata];
          
          if (aValue < bValue) return params.sortOrder === 'desc' ? 1 : -1;
          if (aValue > bValue) return params.sortOrder === 'desc' ? -1 : 1;
          return 0;
        });
      }
      
      // 限制结果数量
      if (params.limit && params.limit > 0) {
        results = results.slice(0, params.limit);
      }
      
      this.logger.info('File search completed', {
        query: params.namePattern,
        resultsFound: results.length
      });
      
      return results;
    } catch (error) {
      this.logger.error('Failed to search files', error as Error);
      throw error;
    }
  }

  /**
   * 获取文件元数据
   * @param path 文件路径
   */
  public async getFileMetadata(path: string): Promise<FileMetadata | null> {
    try {
      // 检查文件是否存在
      if (!await this.fileUtil.exists(path)) {
        this.logger.warn(`File does not exist: ${path}`);
        return null;
      }
      
      // 检查是否为文件
      const isFile = await this.fileUtil.isFile(path);
      if (!isFile) {
        this.logger.warn(`Path is not a file: ${path}`);
        return null;
      }
      
      // 获取文件信息
      const stats = await this.fileUtil.getFileStats(path);
      const fileName = this.fileUtil.getFileName(path);
      const fileExtension = this.fileUtil.getFileExtension(path).toLowerCase();
      
      const metadata: FileMetadata = {
        path,
        name: fileName,
        extension: fileExtension,
        type: this.detectFileType(fileExtension),
        format: this.detectFileFormat(fileExtension),
        size: stats.size,
        createdAt: stats.createdAt,
        modifiedAt: stats.modifiedAt,
        isSymlink: stats.isSymlink
      };
      
      return metadata;
    } catch (error) {
      this.logger.error(`Failed to get file metadata: ${path}`, error as Error);
      return null;
    }
  }

  /**
   * 获取目录信息
   * @param path 目录路径
   */
  public async getDirectoryInfo(path: string): Promise<DirectoryInfo | null> {
    try {
      // 检查目录是否存在
      if (!await this.fileUtil.exists(path)) {
        this.logger.warn(`Directory does not exist: ${path}`);
        return null;
      }
      
      // 检查是否为目录
      const isDirectory = await this.fileUtil.isDirectory(path);
      if (!isDirectory) {
        this.logger.warn(`Path is not a directory: ${path}`);
        return null;
      }
      
      // 获取目录信息
      const stats = await this.fileUtil.getFileStats(path);
      const dirName = this.fileUtil.getDirectoryName(path);
      
      // 读取目录内容以获取子项数量
      const entries = await this.fileUtil.readDirectory(path);
      
      // 计算目录大小（简化实现，实际可能需要递归计算）
      let directorySize = 0;
      for (const entry of entries) {
        const entryPath = `${path}/${entry}`;
        try {
          const entryStats = await this.fileUtil.getFileStats(entryPath);
          if (!entryStats.isDirectory) {
            directorySize += entryStats.size;
          }
        } catch (error) {
          // 忽略无法访问的文件
        }
      }
      
      const dirInfo: DirectoryInfo = {
        path,
        name: dirName,
        createdAt: stats.createdAt,
        modifiedAt: stats.modifiedAt,
        size: directorySize,
        isSymlink: stats.isSymlink
      };
      
      return dirInfo;
    } catch (error) {
      this.logger.error(`Failed to get directory info: ${path}`, error as Error);
      return null;
    }
  }

  /**
   * 创建目录
   * @param path 目录路径
   * @param recursive 是否递归创建父目录
   */
  public async createDirectory(path: string, recursive: boolean = false): Promise<StorageOperationResult> {
    try {
      // 检查目录是否已存在
      if (await this.fileUtil.exists(path)) {
        return {
          success: false,
          error: 'Directory already exists'
        };
      }
      
      // 创建目录
      await this.fileUtil.createDirectory(path, recursive);
      
      // 获取目录信息
      const dirInfo = await this.getDirectoryInfo(path);
      
      // 发布目录创建事件
      this.eventBus.emit(LocalStorageEventType.DIRECTORY_CREATED, {
        path,
        directoryInfo: dirInfo || undefined
      } as DirectoryChangeEvent);
      
      this.logger.info(`Directory created: ${path}`);
      
      return {
        success: true,
        path
      };
    } catch (error) {
      this.logger.error(`Failed to create directory: ${path}`, error as Error);
      
      // 发布存储错误事件
      this.eventBus.emit(LocalStorageEventType.STORAGE_ERROR, { path, error });
      
      return {
        success: false,
        error: (error as Error).message
      };
    }
  }

  /**
   * 删除文件
   * @param path 文件路径
   */
  public async deleteFile(path: string): Promise<StorageOperationResult> {
    try {
      // 检查文件是否存在
      if (!await this.fileUtil.exists(path)) {
        return {
          success: false,
          error: 'File does not exist'
        };
      }
      
      // 检查是否为文件
      const isFile = await this.fileUtil.isFile(path);
      if (!isFile) {
        return {
          success: false,
          error: 'Path is not a file'
        };
      }
      
      // 获取文件元数据（删除前）
      const metadata = await this.getFileMetadata(path);
      
      // 删除文件
      await this.fileUtil.deleteFile(path);
      
      // 发布文件删除事件
      this.eventBus.emit(LocalStorageEventType.FILE_DELETED, {
        path,
        fileType: metadata?.type || LocalFileType.OTHER,
        metadata
      } as FileChangeEvent);
      
      this.logger.info(`File deleted: ${path}`);
      
      return {
        success: true,
        path
      };
    } catch (error) {
      this.logger.error(`Failed to delete file: ${path}`, error as Error);
      
      // 发布存储错误事件
      this.eventBus.emit(LocalStorageEventType.STORAGE_ERROR, { path, error });
      
      return {
        success: false,
        error: (error as Error).message
      };
    }
  }

  /**
   * 删除目录
   * @param path 目录路径
   * @param recursive 是否递归删除
   */
  public async deleteDirectory(path: string, recursive: boolean = false): Promise<StorageOperationResult> {
    try {
      // 检查目录是否存在
      if (!await this.fileUtil.exists(path)) {
        return {
          success: false,
          error: 'Directory does not exist'
        };
      }
      
      // 检查是否为目录
      const isDirectory = await this.fileUtil.isDirectory(path);
      if (!isDirectory) {
        return {
          success: false,
          error: 'Path is not a directory'
        };
      }
      
      // 获取目录信息（删除前）
      const dirInfo = await this.getDirectoryInfo(path);
      
      // 删除目录
      await this.fileUtil.deleteDirectory(path, recursive);
      
      // 发布目录删除事件
      this.eventBus.emit(LocalStorageEventType.DIRECTORY_DELETED, {
        path,
        directoryInfo: dirInfo || undefined
      } as DirectoryChangeEvent);
      
      this.logger.info(`Directory deleted: ${path}`);
      
      return {
        success: true,
        path
      };
    } catch (error) {
      this.logger.error(`Failed to delete directory: ${path}`, error as Error);
      
      // 发布存储错误事件
      this.eventBus.emit(LocalStorageEventType.STORAGE_ERROR, { path, error });
      
      return {
        success: false,
        error: (error as Error).message
      };
    }
  }

  /**
   * 重命名文件或目录
   * @param oldPath 旧路径
   * @param newPath 新路径
   */
  public async rename(oldPath: string, newPath: string): Promise<StorageOperationResult> {
    try {
      // 检查源路径是否存在
      if (!await this.fileUtil.exists(oldPath)) {
        return {
          success: false,
          error: 'Source path does not exist'
        };
      }
      
      // 检查目标路径是否已存在
      if (await this.fileUtil.exists(newPath)) {
        return {
          success: false,
          error: 'Destination path already exists'
        };
      }
      
      // 检查是文件还是目录
      const isFile = await this.fileUtil.isFile(oldPath);
      
      // 执行重命名
      await this.fileUtil.renameFile(oldPath, newPath);
      
      if (isFile) {
        // 获取新文件元数据
        const metadata = await this.getFileMetadata(newPath);
        
        // 发布文件更新事件
        this.eventBus.emit(LocalStorageEventType.FILE_UPDATED, {
          path: newPath,
          fileType: metadata?.type || LocalFileType.OTHER,
          metadata
        } as FileChangeEvent);
      } else {
        // 获取新目录信息
        const dirInfo = await this.getDirectoryInfo(newPath);
        
        // 发布目录变更事件
        this.eventBus.emit(LocalStorageEventType.DIRECTORY_CREATED, {
          path: newPath,
          directoryInfo: dirInfo || undefined
        } as DirectoryChangeEvent);
      }
      
      this.logger.info(`Renamed: ${oldPath} -> ${newPath}`);
      
      return {
        success: true,
        path: newPath
      };
    } catch (error) {
      this.logger.error(`Failed to rename: ${oldPath} -> ${newPath}`, error as Error);
      
      // 发布存储错误事件
      this.eventBus.emit(LocalStorageEventType.STORAGE_ERROR, { oldPath, newPath, error });
      
      return {
        success: false,
        error: (error as Error).message
      };
    }
  }

  /**
   * 移动文件或目录
   * @param sourcePath 源路径
   * @param destinationPath 目标路径
   */
  public async move(sourcePath: string, destinationPath: string): Promise<StorageOperationResult> {
    // 在许多文件系统中，移动操作实际上就是重命名
    // 这里简化实现，直接调用重命名方法
    return this.rename(sourcePath, destinationPath);
  }

  /**
   * 复制文件
   * @param sourcePath 源文件路径
   * @param destinationPath 目标文件路径
   */
  public async copyFile(sourcePath: string, destinationPath: string): Promise<StorageOperationResult> {
    try {
      // 检查源文件是否存在
      if (!await this.fileUtil.exists(sourcePath)) {
        return {
          success: false,
          error: 'Source file does not exist'
        };
      }
      
      // 检查源路径是否为文件
      const isFile = await this.fileUtil.isFile(sourcePath);
      if (!isFile) {
        return {
          success: false,
          error: 'Source path is not a file'
        };
      }
      
      // 检查目标路径是否已存在
      if (await this.fileUtil.exists(destinationPath)) {
        return {
          success: false,
          error: 'Destination file already exists'
        };
      }
      
      // 确保目标目录存在
      const destinationDir = this.fileUtil.getDirectoryPath(destinationPath);
      if (!await this.fileUtil.exists(destinationDir)) {
        await this.fileUtil.createDirectory(destinationDir, true);
      }
      
      // 复制文件
      await this.fileUtil.copyFile(sourcePath, destinationPath);
      
      // 获取新文件元数据
      const metadata = await this.getFileMetadata(destinationPath);
      
      // 发布文件添加事件
      this.eventBus.emit(LocalStorageEventType.FILE_ADDED, {
        path: destinationPath,
        fileType: metadata?.type || LocalFileType.OTHER,
        metadata
      } as FileChangeEvent);
      
      this.logger.info(`File copied: ${sourcePath} -> ${destinationPath}`);
      
      return {
        success: true,
        path: destinationPath
      };
    } catch (error) {
      this.logger.error(`Failed to copy file: ${sourcePath} -> ${destinationPath}`, error as Error);
      
      // 发布存储错误事件
      this.eventBus.emit(LocalStorageEventType.STORAGE_ERROR, { sourcePath, destinationPath, error });
      
      return {
        success: false,
        error: (error as Error).message
      };
    }
  }

  /**
   * 检查文件系统空间
   * @param path 要检查的路径
   */
  public async getFileSystemSpace(path: string): Promise<{ total: number; available: number } | null> {
    try {
      // 找到路径所属的存储设备
      const devices = await this.getStorageDevices();
      
      for (const device of devices) {
        if (device.isMounted && path.startsWith(device.path)) {
          return {
            total: device.totalSize,
            available: device.availableSize
          };
        }
      }
      
      this.logger.warn(`Could not determine storage device for path: ${path}`);
      return null;
    } catch (error) {
      this.logger.error(`Failed to get file system space for path: ${path}`, error as Error);
      return null;
    }
  }

  /**
   * 监听存储设备变更
   * @param callback 回调函数
   */
  public listenForDeviceChanges(callback: (event: 'connected' | 'disconnected', device: StorageDevice) => void): () => void {
    // 创建事件监听器
    const onConnected = (event: { device: StorageDevice }) => {
      callback('connected', event.device);
    };
    
    const onDisconnected = (event: { device: StorageDevice }) => {
      callback('disconnected', event.device);
    };
    
    // 注册事件
    this.eventBus.on(LocalStorageEventType.STORAGE_DEVICE_CONNECTED, onConnected);
    this.eventBus.on(LocalStorageEventType.STORAGE_DEVICE_DISCONNECTED, onDisconnected);
    
    // 返回清理函数
    return () => {
      this.eventBus.off(LocalStorageEventType.STORAGE_DEVICE_CONNECTED, onConnected);
      this.eventBus.off(LocalStorageEventType.STORAGE_DEVICE_DISCONNECTED, onDisconnected);
    };
  }

  // 私有辅助方法

  /**
   * 检测文件类型
   * @param extension 文件扩展名
   */
  private detectFileType(extension: string): LocalFileType {
    // 视频文件类型
    const videoExtensions = ['mp4', 'mkv', 'avi', 'mov', 'wmv', 'flv', 'webm', 'm4v', 'mpeg', 'mpg', '3gp'];
    if (videoExtensions.includes(extension)) {
      return LocalFileType.VIDEO;
    }
    
    // 音频文件类型
    const audioExtensions = ['mp3', 'wav', 'flac', 'aac', 'ogg', 'wma', 'm4a', 'opus'];
    if (audioExtensions.includes(extension)) {
      return LocalFileType.AUDIO;
    }
    
    // 图像文件类型
    const imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'tiff', 'svg', 'heic'];
    if (imageExtensions.includes(extension)) {
      return LocalFileType.IMAGE;
    }
    
    // 字幕文件类型
    const subtitleExtensions = ['srt', 'ass', 'ssa', 'sub', 'vtt'];
    if (subtitleExtensions.includes(extension)) {
      return LocalFileType.SUBTITLE;
    }
    
    // 文档文件类型
    const documentExtensions = ['txt', 'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'md'];
    if (documentExtensions.includes(extension)) {
      return LocalFileType.DOCUMENT;
    }
    
    // 压缩文件类型
    const archiveExtensions = ['zip', 'rar', '7z', 'tar', 'gz', 'bz2'];
    if (archiveExtensions.includes(extension)) {
      return LocalFileType.ARCHIVE;
    }
    
    // 应用程序文件类型
    const appExtensions = ['exe', 'apk', 'dmg', 'app', 'msi'];
    if (appExtensions.includes(extension)) {
      return LocalFileType.APPLICATION;
    }
    
    // 其他类型
    return LocalFileType.OTHER;
  }

  /**
   * 检测文件格式
   * @param extension 文件扩展名
   */
  private detectFileFormat(extension: string): LocalFileFormat {
    // 根据扩展名确定格式
    switch (extension) {
      case 'mp4':
        return LocalFileFormat.MP4;
      case 'mkv':
        return LocalFileFormat.MKV;
      case 'avi':
        return LocalFileFormat.AVI;
      case 'mp3':
        return LocalFileFormat.MP3;
      case 'jpg':
      case 'jpeg':
        return LocalFileFormat.JPEG;
      case 'png':
        return LocalFileFormat.PNG;
      case 'pdf':
        return LocalFileFormat.PDF;
      case 'txt':
        return LocalFileFormat.TEXT;
      case 'zip':
        return LocalFileFormat.ZIP;
      default:
        return LocalFileFormat.OTHER;
    }
  }

  /**
   * 检查文件是否匹配过滤器
   */
  private matchesFilters(
    stats: { size: number; modifiedAt: number },
    extension: string,
    filters?: { extensions?: string[]; minSize?: number; maxSize?: number; modifiedAfter?: number; modifiedBefore?: number }
  ): boolean {
    if (!filters) {
      return true;
    }
    
    // 检查扩展名
    if (filters.extensions && filters.extensions.length > 0) {
      if (!filters.extensions.includes(extension)) {
        return false;
      }
    }
    
    // 检查大小
    if (filters.minSize !== undefined && stats.size < filters.minSize) {
      return false;
    }
    if (filters.maxSize !== undefined && stats.size > filters.maxSize) {
      return false;
    }
    
    // 检查修改时间
    if (filters.modifiedAfter !== undefined && stats.modifiedAt < filters.modifiedAfter) {
      return false;
    }
    if (filters.modifiedBefore !== undefined && stats.modifiedAt > filters.modifiedBefore) {
      return false;
    }
    
    return true;
  }

  /**
   * 清理过期缓存
   */
  private cleanupOldCache(): void {
    const now = Date.now();
    const expiredKeys: string[] = [];
    
    this.recentScans.forEach((value, key) => {
      if (now - value.timestamp > this.cacheExpiryTime) {
        expiredKeys.push(key);
      }
    });
    
    for (const key of expiredKeys) {
      this.recentScans.delete(key);
    }
    
    if (expiredKeys.length > 0) {
      this.logger.debug(`Cleaned up ${expiredKeys.length} expired scan caches`);
    }
  }

  /**
   * 加载设备信息缓存
   */
  private async loadDeviceCache(): Promise<void> {
    try {
      // 从存储中加载设备信息
      const cachedDevices = await this.storageUtil.getObject<StorageDevice[]>('local_storage_devices', LocalStorageType.PERSISTENT);
      
      if (cachedDevices && cachedDevices.length > 0) {
        // 合并缓存的设备信息（如果有）
        for (const device of cachedDevices) {
          // 只合并已知设备的额外信息，不覆盖当前已检测到的设备状态
          const currentDevice = this.storageDevices.get(device.id);
          if (currentDevice) {
            this.storageDevices.set(device.id, {
              ...currentDevice,
              // 保留一些缓存的信息
              name: device.name,
              fileSystem: device.fileSystem || currentDevice.fileSystem
            });
          }
        }
      }
    } catch (error) {
      this.logger.warn('Failed to load device cache', error as Error);
    }
  }

  /**
   * 保存设备信息缓存
   */
  private async saveDeviceCache(): Promise<void> {
    try {
      // 保存设备信息到存储
      const devices = Array.from(this.storageDevices.values());
      await this.storageUtil.setObject('local_storage_devices', devices, LocalStorageType.PERSISTENT);
    } catch (error) {
      this.logger.warn('Failed to save device cache', error as Error);
    }
  }
}

// 导出默认实例
export default LocalRepository.getInstance();