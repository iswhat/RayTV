// FileService - 文件服务类
import Logger from '../../common/util/Logger';
import StorageUtil from '../../common/util/StorageUtil';
import FileUtil, { FileInfo, FileStats } from '../../common/util/FileUtil';
import ConfigService from '../../service/config/ConfigService';
import HttpService from '../http/HttpService';
import { DownloadTask, DownloadStatus } from '../../service/download/DownloadService';

// 常量定义
const TAG = 'FileService';
const FILE_CONFIG_KEY = 'file_config';
const MAX_UPLOAD_SIZE = 100 * 1024 * 1024; // 100MB
const TEMP_FILE_EXPIRY = 3600000; // 1小时
const THUMBNAIL_CACHE_EXPIRY = 86400000; // 24小时

// 文件类型枚举
export enum FileType {
  VIDEO = 'video',
  AUDIO = 'audio',
  IMAGE = 'image',
  SUBTITLE = 'subtitle',
  DOCUMENT = 'document',
  ARCHIVE = 'archive',
  EXECUTABLE = 'executable',
  OTHER = 'other',
  UNKNOWN = 'unknown'
}

// 文件格式枚举
export enum FileFormat {
  // 视频格式
  MP4 = 'mp4',
  AVI = 'avi',
  MKV = 'mkv',
  FLV = 'flv',
  WMV = 'wmv',
  MOV = 'mov',
  WEBM = 'webm',
  TS = 'ts',
  MPG = 'mpg',
  MPEG = 'mpeg',
  VOB = 'vob',
  RMVB = 'rmvb',
  M4V = 'm4v',
  
  // 音频格式
  MP3 = 'mp3',
  WAV = 'wav',
  FLAC = 'flac',
  AAC = 'aac',
  OGG = 'ogg',
  WMA = 'wma',
  OPUS = 'opus',
  M4A = 'm4a',
  
  // 图像格式
  JPG = 'jpg',
  JPEG = 'jpeg',
  PNG = 'png',
  GIF = 'gif',
  WEBP = 'webp',
  SVG = 'svg',
  BMP = 'bmp',
  TIFF = 'tiff',
  HEIC = 'heic',
  
  // 字幕格式
  SRT = 'srt',
  VTT = 'vtt',
  ASS = 'ass',
  SSA = 'ssa',
  TTML = 'ttml',
  DFXP = 'dfxp',
  SBV = 'sbv',
  LRC = 'lrc',
  
  // 文档格式
  TXT = 'txt',
  PDF = 'pdf',
  DOC = 'doc',
  DOCX = 'docx',
  XLS = 'xls',
  XLSX = 'xlsx',
  PPT = 'ppt',
  PPTX = 'pptx',
  MD = 'md',
  HTML = 'html',
  XML = 'xml',
  JSON = 'json',
  
  // 压缩格式
  ZIP = 'zip',
  RAR = 'rar',
  7Z = '7z',
  TAR = 'tar',
  GZIP = 'gzip',
  BZIP2 = 'bzip2',
  ISO = 'iso',
  
  // 其他格式
  APK = 'apk',
  EXE = 'exe',
  DLL = 'dll',
  DYLIB = 'dylib',
  SO = 'so',
  
  // 未知格式
  UNKNOWN = 'unknown'
}

// 存储位置枚举
export enum StorageLocation {
  INTERNAL = 'internal',
  EXTERNAL = 'external',
  SD_CARD = 'sd_card',
  NETWORK = 'network',
  CLOUD = 'cloud',
  TEMP = 'temp'
}

// 文件权限枚举
export enum FilePermission {
  READ = 'read',
  WRITE = 'write',
  EXECUTE = 'execute',
  DELETE = 'delete',
  ALL = 'all',
  NONE = 'none'
}

// 文件操作模式枚举
export enum FileMode {
  READ = 'read',
  WRITE = 'write',
  APPEND = 'append',
  READ_WRITE = 'read_write',
  TRUNCATE = 'truncate'
}

// 文件排序方式枚举
export enum FileSortBy {
  NAME = 'name',
  SIZE = 'size',
  DATE = 'date',
  TYPE = 'type',
  EXTENSION = 'extension',
  NONE = 'none'
}

// 文件排序方向枚举
export enum FileSortDirection {
  ASCENDING = 'ascending',
  DESCENDING = 'descending'
}

// 文件配置接口
export interface FileConfig {
  defaultStorageLocation: StorageLocation;
  maxCacheSize: number; // 字节
  maxTempFileSize: number; // 字节
  enableAutoCleanup: boolean;
  cleanupInterval: number; // 毫秒
  thumbnailCacheSize: number; // 字节
  tempDir: string;
  cacheDir: string;
  downloadDir: string;
  uploadDir: string;
  documentDir: string;
  imageDir: string;
  videoDir: string;
  audioDir: string;
  subtitleDir: string;
  enableFileWatcher: boolean;
  fileWatcherInterval: number; // 毫秒
  supportedFormats: { [key in FileType]?: FileFormat[] };
  chunkSize: number; // 分块上传/下载的块大小
  maxConcurrentOperations: number;
  verifyFileIntegrity: boolean;
}

// 文件信息扩展接口
export interface ExtendedFileInfo extends FileInfo {
  type: FileType;
  format: FileFormat;
  storageLocation: StorageLocation;
  permissions: FilePermission[];
  metadata?: Record<string, any>;
  thumbnailUrl?: string;
  duration?: number; // 视频/音频时长
  width?: number; // 图像/视频宽度
  height?: number; // 图像/视频高度
  codec?: string; // 视频/音频编码
  bitrate?: number; // 视频/音频比特率
  frameRate?: number; // 视频帧率
  resolution?: string; // 视频分辨率
  aspectRatio?: number; // 视频宽高比
  tags?: Record<string, string>; // 文件标签
  checksum?: string; // 文件校验和
  owner?: string; // 文件所有者
  createdAt: number;
  modifiedAt: number;
  accessedAt: number;
}

// 文件搜索参数接口
export interface FileSearchParams {
  path: string;
  pattern?: string;
  recursive?: boolean;
  types?: FileType[];
  formats?: FileFormat[];
  minSize?: number;
  maxSize?: number;
  minDate?: number;
  maxDate?: number;
  sortBy?: FileSortBy;
  sortDirection?: FileSortDirection;
  limit?: number;
  offset?: number;
}

// 文件操作结果接口
export interface FileOperationResult {
  success: boolean;
  path?: string;
  error?: string;
  details?: any;
}

// 文件夹信息接口
export interface FolderInfo {
  path: string;
  name: string;
  parentPath?: string;
  storageLocation: StorageLocation;
  fileCount: number;
  folderCount: number;
  totalSize: number;
  createdAt: number;
  modifiedAt: number;
  accessedAt: number;
  permissions: FilePermission[];
}

// 存储设备信息接口
export interface StorageDeviceInfo {
  id: string;
  name: string;
  path: string;
  type: StorageLocation;
  totalSize: number;
  availableSize: number;
  usedSize: number;
  isRemovable: boolean;
  isReadOnly: boolean;
  mountPoint: string;
  fileSystem: string;
  model?: string;
  serialNumber?: string;
}

// 文件传输进度接口
export interface FileTransferProgress {
  id: string;
  source: string;
  destination: string;
  progress: number; // 0-100
  bytesTransferred: number;
  totalBytes: number;
  speed: number; // 字节/秒
  elapsedTime: number; // 毫秒
  remainingTime?: number; // 预估剩余毫秒
  status: 'pending' | 'in_progress' | 'completed' | 'failed' | 'canceled';
  error?: string;
}

// 默认文件配置
const DEFAULT_FILE_CONFIG: FileConfig = {
  defaultStorageLocation: StorageLocation.INTERNAL,
  maxCacheSize: 512 * 1024 * 1024, // 512MB
  maxTempFileSize: 100 * 1024 * 1024, // 100MB
  enableAutoCleanup: true,
  cleanupInterval: 3600000, // 1小时
  thumbnailCacheSize: 100 * 1024 * 1024, // 100MB
  tempDir: 'temp',
  cacheDir: 'cache',
  downloadDir: 'downloads',
  uploadDir: 'uploads',
  documentDir: 'documents',
  imageDir: 'images',
  videoDir: 'videos',
  audioDir: 'audio',
  subtitleDir: 'subtitles',
  enableFileWatcher: false,
  fileWatcherInterval: 5000,
  supportedFormats: {
    [FileType.VIDEO]: [
      FileFormat.MP4, FileFormat.AVI, FileFormat.MKV, FileFormat.FLV, 
      FileFormat.WMV, FileFormat.MOV, FileFormat.WEBM, FileFormat.TS,
      FileFormat.MPG, FileFormat.MPEG, FileFormat.VOB, FileFormat.RMVB,
      FileFormat.M4V
    ],
    [FileType.AUDIO]: [
      FileFormat.MP3, FileFormat.WAV, FileFormat.FLAC, FileFormat.AAC,
      FileFormat.OGG, FileFormat.WMA, FileFormat.OPUS, FileFormat.M4A
    ],
    [FileType.IMAGE]: [
      FileFormat.JPG, FileFormat.JPEG, FileFormat.PNG, FileFormat.GIF,
      FileFormat.WEBP, FileFormat.SVG, FileFormat.BMP, FileFormat.TIFF,
      FileFormat.HEIC
    ],
    [FileType.SUBTITLE]: [
      FileFormat.SRT, FileFormat.VTT, FileFormat.ASS, FileFormat.SSA,
      FileFormat.TTML, FileFormat.DFXP, FileFormat.SBV, FileFormat.LRC
    ],
    [FileType.DOCUMENT]: [
      FileFormat.TXT, FileFormat.PDF, FileFormat.DOC, FileFormat.DOCX,
      FileFormat.XLS, FileFormat.XLSX, FileFormat.PPT, FileFormat.PPTX,
      FileFormat.MD, FileFormat.HTML, FileFormat.XML, FileFormat.JSON
    ],
    [FileType.ARCHIVE]: [
      FileFormat.ZIP, FileFormat.RAR, FileFormat['7Z'], FileFormat.TAR,
      FileFormat.GZIP, FileFormat.BZIP2, FileFormat.ISO
    ]
  },
  chunkSize: 1024 * 1024, // 1MB
  maxConcurrentOperations: 5,
  verifyFileIntegrity: true
};

/**
 * 文件服务类
 * 负责管理文件操作、存储路径、文件格式转换等功能
 */
export default class FileService {
  private static instance: FileService;
  
  private fileConfig: FileConfig = { ...DEFAULT_FILE_CONFIG };
  private storageDevices: Map<string, StorageDeviceInfo> = new Map();
  private transferTasks: Map<string, FileTransferProgress> = new Map();
  private activeOperations: Set<string> = new Set();
  private fileWatchers: Map<string, number> = new Map();
  
  // 监听器
  private transferListeners: Map<string, Array<(progress: FileTransferProgress) => void>> = new Map();
  private storageListeners: Array<(devices: StorageDeviceInfo[]) => void> = [];
  private cleanupListeners: Array<(deletedCount: number, freedSpace: number) => void> = [];
  
  private cleanupTimer?: number;
  private isInitialized: boolean = false;

  /**
   * 构造函数（私有，防止外部实例化）
   */
  private constructor() {
    this.initialize();
  }

  /**
   * 获取单例实例
   */
  public static getInstance(): FileService {
    if (!FileService.instance) {
      FileService.instance = new FileService();
    }
    return FileService.instance;
  }

  /**
   * 初始化文件服务
   */
  private async initialize(): Promise<void> {
    try {
      Logger.info(TAG, 'Initializing file service...');
      
      // 加载文件配置
      const savedConfig = await StorageUtil.getObject<FileConfig>(FILE_CONFIG_KEY);
      if (savedConfig) {
        this.fileConfig = { ...DEFAULT_FILE_CONFIG, ...savedConfig };
      }
      
      // 创建必要的目录结构
      await this.createDirectoryStructure();
      
      // 扫描存储设备
      await this.scanStorageDevices();
      
      // 启动自动清理
      if (this.fileConfig.enableAutoCleanup) {
        this.startAutoCleanup();
      }
      
      // 启动文件监控（如果启用）
      if (this.fileConfig.enableFileWatcher) {
        this.startFileWatchers();
      }
      
      this.isInitialized = true;
      Logger.info(TAG, 'File service initialized successfully');
    } catch (error) {
      Logger.error(TAG, 'Failed to initialize file service', error);
    }
  }

  /**
   * 创建目录结构
   */
  private async createDirectoryStructure(): Promise<void> {
    try {
      const dirs = [
        this.fileConfig.tempDir,
        this.fileConfig.cacheDir,
        this.fileConfig.downloadDir,
        this.fileConfig.uploadDir,
        this.fileConfig.documentDir,
        this.fileConfig.imageDir,
        this.fileConfig.videoDir,
        this.fileConfig.audioDir,
        this.fileConfig.subtitleDir
      ];
      
      for (const dir of dirs) {
        await FileUtil.ensureDirectory(dir);
        Logger.debug(TAG, `Created directory: ${dir}`);
      }
    } catch (error) {
      Logger.error(TAG, 'Failed to create directory structure', error);
    }
  }

  /**
   * 扫描存储设备
   */
  private async scanStorageDevices(): Promise<void> {
    try {
      // 实际应用中，这里应该使用系统API扫描存储设备
      // 这里简化为模拟实现
      const devices: StorageDeviceInfo[] = [
        {
          id: 'internal',
          name: '内部存储',
          path: '/',
          type: StorageLocation.INTERNAL,
          totalSize: 50 * 1024 * 1024 * 1024, // 50GB
          availableSize: 20 * 1024 * 1024 * 1024, // 20GB
          usedSize: 30 * 1024 * 1024 * 1024, // 30GB
          isRemovable: false,
          isReadOnly: false,
          mountPoint: '/',
          fileSystem: 'ext4',
          model: 'Internal Storage',
          serialNumber: 'N/A'
        }
      ];
      
      // 清空现有设备
      this.storageDevices.clear();
      
      // 添加设备
      for (const device of devices) {
        this.storageDevices.set(device.id, device);
      }
      
      // 通知监听器
      this.notifyStorageDevicesChanged();
      
      Logger.info(TAG, `Scanned ${devices.length} storage devices`);
    } catch (error) {
      Logger.error(TAG, 'Failed to scan storage devices', error);
    }
  }

  /**
   * 保存文件配置
   */
  private async saveFileConfig(): Promise<void> {
    try {
      await StorageUtil.setObject(FILE_CONFIG_KEY, this.fileConfig);
      Logger.debug(TAG, 'Saved file config');
    } catch (error) {
      Logger.error(TAG, 'Failed to save file config', error);
    }
  }

  /**
   * 设置文件配置
   */
  public async setFileConfig(config: Partial<FileConfig>): Promise<FileConfig> {
    try {
      // 更新配置
      this.fileConfig = {
        ...this.fileConfig,
        ...config
      };
      
      // 保存配置
      await this.saveFileConfig();
      
      // 重新创建目录（如果目录配置变更）
      if (config.tempDir || config.cacheDir || config.downloadDir || 
          config.uploadDir || config.documentDir || config.imageDir || 
          config.videoDir || config.audioDir || config.subtitleDir) {
        await this.createDirectoryStructure();
      }
      
      // 重启自动清理（如果配置变更）
      if (config.enableAutoCleanup !== undefined || config.cleanupInterval !== undefined) {
        this.stopAutoCleanup();
        if (this.fileConfig.enableAutoCleanup) {
          this.startAutoCleanup();
        }
      }
      
      // 重启文件监控（如果配置变更）
      if (config.enableFileWatcher !== undefined || config.fileWatcherInterval !== undefined) {
        this.stopFileWatchers();
        if (this.fileConfig.enableFileWatcher) {
          this.startFileWatchers();
        }
      }
      
      Logger.info(TAG, 'Updated file config');
      return { ...this.fileConfig };
    } catch (error) {
      Logger.error(TAG, 'Failed to update file config', error);
      return { ...this.fileConfig };
    }
  }

  /**
   * 获取文件配置
   */
  public getFileConfig(): FileConfig {
    return { ...this.fileConfig };
  }

  /**
   * 重置文件配置为默认值
   */
  public async resetFileConfig(): Promise<FileConfig> {
    try {
      this.fileConfig = { ...DEFAULT_FILE_CONFIG };
      
      // 保存配置
      await this.saveFileConfig();
      
      // 重新创建目录结构
      await this.createDirectoryStructure();
      
      // 重启自动清理
      this.stopAutoCleanup();
      if (this.fileConfig.enableAutoCleanup) {
        this.startAutoCleanup();
      }
      
      // 重启文件监控
      this.stopFileWatchers();
      if (this.fileConfig.enableFileWatcher) {
        this.startFileWatchers();
      }
      
      Logger.info(TAG, 'Reset file config to default');
      return { ...this.fileConfig };
    } catch (error) {
      Logger.error(TAG, 'Failed to reset file config', error);
      return { ...this.fileConfig };
    }
  }

  /**
   * 开始自动清理
   */
  private startAutoCleanup(): void {
    try {
      this.stopAutoCleanup();
      
      this.cleanupTimer = setInterval(() => {
        this.performAutoCleanup();
      }, this.fileConfig.cleanupInterval);
      
      Logger.debug(TAG, `Started auto cleanup, interval: ${this.fileConfig.cleanupInterval}ms`);
    } catch (error) {
      Logger.error(TAG, 'Failed to start auto cleanup', error);
    }
  }

  /**
   * 停止自动清理
   */
  private stopAutoCleanup(): void {
    try {
      if (this.cleanupTimer) {
        clearInterval(this.cleanupTimer);
        this.cleanupTimer = undefined;
      }
    } catch (error) {
      Logger.error(TAG, 'Failed to stop auto cleanup', error);
    }
  }

  /**
   * 执行自动清理
   */
  private async performAutoCleanup(): Promise<void> {
    try {
      Logger.info(TAG, 'Performing auto cleanup...');
      
      let deletedCount = 0;
      let freedSpace = 0;
      
      // 清理临时文件
      const tempCleanup = await this.cleanupDirectory(
        this.fileConfig.tempDir,
        TEMP_FILE_EXPIRY
      );
      deletedCount += tempCleanup.deletedCount;
      freedSpace += tempCleanup.freedSpace;
      
      // 清理缩略图缓存
      const thumbCleanup = await this.cleanupDirectory(
        `${this.fileConfig.cacheDir}/thumbnails`,
        THUMBNAIL_CACHE_EXPIRY
      );
      deletedCount += thumbCleanup.deletedCount;
      freedSpace += thumbCleanup.freedSpace;
      
      // 检查缓存目录大小
      const cacheStats = await FileUtil.getDirectoryStats(this.fileConfig.cacheDir);
      if (cacheStats && cacheStats.totalSize > this.fileConfig.maxCacheSize) {
        const toDelete = cacheStats.totalSize - this.fileConfig.maxCacheSize;
        const cacheCleanup = await this.cleanupDirectoryBySize(
          this.fileConfig.cacheDir,
          toDelete
        );
        deletedCount += cacheCleanup.deletedCount;
        freedSpace += cacheCleanup.freedSpace;
      }
      
      // 检查临时目录大小
      const tempStats = await FileUtil.getDirectoryStats(this.fileConfig.tempDir);
      if (tempStats && tempStats.totalSize > this.fileConfig.maxTempFileSize) {
        const toDelete = tempStats.totalSize - this.fileConfig.maxTempFileSize;
        const tempSizeCleanup = await this.cleanupDirectoryBySize(
          this.fileConfig.tempDir,
          toDelete
        );
        deletedCount += tempSizeCleanup.deletedCount;
        freedSpace += tempSizeCleanup.freedSpace;
      }
      
      // 通知清理完成
      if (deletedCount > 0) {
        this.notifyCleanupCompleted(deletedCount, freedSpace);
      }
      
      Logger.info(TAG, `Auto cleanup completed: ${deletedCount} files deleted, ${this.formatSize(freedSpace)} freed`);
    } catch (error) {
      Logger.error(TAG, 'Failed to perform auto cleanup', error);
    }
  }

  /**
   * 清理目录中过期的文件
   */
  private async cleanupDirectory(
    directory: string,
    expiryTime: number
  ): Promise<{ deletedCount: number; freedSpace: number }> {
    try {
      const now = Date.now();
      const files = await FileUtil.readDirectory(directory, true);
      
      let deletedCount = 0;
      let freedSpace = 0;
      
      for (const file of files) {
        if (!file.isDirectory && file.modifiedAt && (now - file.modifiedAt > expiryTime)) {
          try {
            const stats = await FileUtil.getFileStats(file.path);
            await FileUtil.deleteFile(file.path);
            deletedCount++;
            freedSpace += stats?.size || 0;
          } catch (error) {
            Logger.warn(TAG, `Failed to delete expired file: ${file.path}`, error);
          }
        }
      }
      
      return { deletedCount, freedSpace };
    } catch (error) {
      Logger.error(TAG, `Failed to cleanup directory: ${directory}`, error);
      return { deletedCount: 0, freedSpace: 0 };
    }
  }

  /**
   * 按大小清理目录
   */
  private async cleanupDirectoryBySize(
    directory: string,
    bytesToDelete: number
  ): Promise<{ deletedCount: number; freedSpace: number }> {
    try {
      // 获取所有文件并按修改时间排序（最旧的先删除）
      const files = await FileUtil.readDirectory(directory, true);
      const fileList = files
        .filter(file => !file.isDirectory && file.modifiedAt)
        .sort((a, b) => (a.modifiedAt || 0) - (b.modifiedAt || 0));
      
      let deletedCount = 0;
      let freedSpace = 0;
      
      for (const file of fileList) {
        if (freedSpace >= bytesToDelete) {
          break;
        }
        
        try {
          const stats = await FileUtil.getFileStats(file.path);
          await FileUtil.deleteFile(file.path);
          deletedCount++;
          freedSpace += stats?.size || 0;
        } catch (error) {
          Logger.warn(TAG, `Failed to delete file by size: ${file.path}`, error);
        }
      }
      
      return { deletedCount, freedSpace };
    } catch (error) {
      Logger.error(TAG, `Failed to cleanup directory by size: ${directory}`, error);
      return { deletedCount: 0, freedSpace: 0 };
    }
  }

  /**
   * 开始文件监控
   */
  private startFileWatchers(): void {
    try {
      // 实际应用中，这里应该为重要目录添加文件监控
      Logger.debug(TAG, 'Started file watchers');
    } catch (error) {
      Logger.error(TAG, 'Failed to start file watchers', error);
    }
  }

  /**
   * 停止文件监控
   */
  private stopFileWatchers(): void {
    try {
      // 清除所有定时器
      for (const [, timer] of this.fileWatchers) {
        clearInterval(timer);
      }
      this.fileWatchers.clear();
    } catch (error) {
      Logger.error(TAG, 'Failed to stop file watchers', error);
    }
  }

  /**
   * 获取存储设备信息
   */
  public async getStorageDevices(): Promise<StorageDeviceInfo[]> {
    if (!this.isInitialized) {
      await this.initialize();
    }
    
    return Array.from(this.storageDevices.values());
  }

  /**
   * 获取存储设备信息
   */
  public async getStorageDevice(deviceId: string): Promise<StorageDeviceInfo | undefined> {
    if (!this.isInitialized) {
      await this.initialize();
    }
    
    return this.storageDevices.get(deviceId);
  }

  /**
   * 获取文件信息
   */
  public async getFileInfo(filePath: string): Promise<ExtendedFileInfo | null> {
    try {
      const fileInfo = await FileUtil.getFileInfo(filePath);
      if (!fileInfo) {
        return null;
      }
      
      // 扩展文件信息
      const extendedInfo: ExtendedFileInfo = {
        ...fileInfo,
        type: this.getFileType(filePath),
        format: this.getFileFormat(filePath),
        storageLocation: this.getStorageLocation(filePath),
        permissions: await this.getFilePermissions(filePath),
        createdAt: fileInfo.createdAt || Date.now(),
        modifiedAt: fileInfo.modifiedAt || Date.now(),
        accessedAt: fileInfo.accessedAt || Date.now()
      };
      
      // 对于媒体文件，尝试获取更多信息
      if (extendedInfo.type === FileType.VIDEO || extendedInfo.type === FileType.AUDIO) {
        // 实际应用中，这里应该使用媒体解析库获取详细信息
        // 这里简化为模拟数据
      }
      
      // 对于图像文件，尝试获取尺寸信息
      if (extendedInfo.type === FileType.IMAGE) {
        // 实际应用中，这里应该使用图像解析库获取尺寸
        // 这里简化为模拟数据
      }
      
      return extendedInfo;
    } catch (error) {
      Logger.error(TAG, `Failed to get file info: ${filePath}`, error);
      return null;
    }
  }

  /**
   * 获取文件类型
   */
  public getFileType(filePath: string): FileType {
    const extension = FileUtil.getExtension(filePath).toLowerCase();
    
    // 视频类型
    if ([
      'mp4', 'avi', 'mkv', 'flv', 'wmv', 'mov', 'webm', 'ts',
      'mpg', 'mpeg', 'vob', 'rmvb', 'm4v'
    ].includes(extension)) {
      return FileType.VIDEO;
    }
    
    // 音频类型
    if ([
      'mp3', 'wav', 'flac', 'aac', 'ogg', 'wma', 'opus', 'm4a'
    ].includes(extension)) {
      return FileType.AUDIO;
    }
    
    // 图像类型
    if ([
      'jpg', 'jpeg', 'png', 'gif', 'webp', 'svg', 'bmp', 'tiff', 'heic'
    ].includes(extension)) {
      return FileType.IMAGE;
    }
    
    // 字幕类型
    if ([
      'srt', 'vtt', 'ass', 'ssa', 'ttml', 'dfxp', 'sbv', 'lrc'
    ].includes(extension)) {
      return FileType.SUBTITLE;
    }
    
    // 文档类型
    if ([
      'txt', 'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx',
      'md', 'html', 'xml', 'json'
    ].includes(extension)) {
      return FileType.DOCUMENT;
    }
    
    // 压缩类型
    if ([
      'zip', 'rar', '7z', 'tar', 'gzip', 'gz', 'bzip2', 'bz2', 'iso'
    ].includes(extension)) {
      return FileType.ARCHIVE;
    }
    
    // 可执行类型
    if ([
      'exe', 'dll', 'so', 'dylib', 'apk'
    ].includes(extension)) {
      return FileType.EXECUTABLE;
    }
    
    return FileType.UNKNOWN;
  }

  /**
   * 获取文件格式
   */
  public getFileFormat(filePath: string): FileFormat {
    const extension = FileUtil.getExtension(filePath).toLowerCase();
    
    // 尝试将扩展名转换为枚举值
    const format = Object.values(FileFormat).find(f => f.toLowerCase() === extension);
    return format || FileFormat.UNKNOWN;
  }

  /**
   * 获取存储位置
   */
  public getStorageLocation(filePath: string): StorageLocation {
    // 实际应用中，这里应该根据文件路径判断存储位置
    // 这里简化为默认返回内部存储
    return StorageLocation.INTERNAL;
  }

  /**
   * 获取文件权限
   */
  public async getFilePermissions(filePath: string): Promise<FilePermission[]> {
    try {
      // 实际应用中，这里应该使用系统API获取文件权限
      // 这里简化为返回默认权限
      const exists = await FileUtil.fileExists(filePath);
      if (!exists) {
        return [FilePermission.NONE];
      }
      
      const canRead = await FileUtil.canRead(filePath);
      const canWrite = await FileUtil.canWrite(filePath);
      const canExecute = await FileUtil.canExecute(filePath);
      
      const permissions: FilePermission[] = [];
      if (canRead) permissions.push(FilePermission.READ);
      if (canWrite) permissions.push(FilePermission.WRITE);
      if (canExecute) permissions.push(FilePermission.EXECUTE);
      
      if (canRead && canWrite && canExecute) {
        permissions.push(FilePermission.ALL);
      }
      
      return permissions;
    } catch (error) {
      Logger.error(TAG, `Failed to get file permissions: ${filePath}`, error);
      return [FilePermission.NONE];
    }
  }

  /**
   * 检查文件是否支持
   */
  public isFileSupported(filePath: string): boolean {
    const type = this.getFileType(filePath);
    const format = this.getFileFormat(filePath);
    
    if (type === FileType.UNKNOWN || format === FileFormat.UNKNOWN) {
      return false;
    }
    
    const supportedFormats = this.fileConfig.supportedFormats[type];
    return supportedFormats ? supportedFormats.includes(format) : false;
  }

  /**
   * 搜索文件
   */
  public async searchFiles(params: FileSearchParams): Promise<ExtendedFileInfo[]> {
    try {
      // 验证路径
      const pathExists = await FileUtil.directoryExists(params.path);
      if (!pathExists) {
        Logger.warn(TAG, `Search path does not exist: ${params.path}`);
        return [];
      }
      
      // 读取目录
      const files = await FileUtil.readDirectory(params.path, params.recursive || false);
      
      // 过滤文件
      let filteredFiles = files.filter(file => !file.isDirectory);
      
      // 应用过滤器
      if (params.types && params.types.length > 0) {
        filteredFiles = filteredFiles.filter(file => 
          params.types!.includes(this.getFileType(file.path))
        );
      }
      
      if (params.formats && params.formats.length > 0) {
        filteredFiles = filteredFiles.filter(file => {
          const format = this.getFileFormat(file.path);
          return params.formats!.includes(format);
        });
      }
      
      if (params.minSize !== undefined) {
        filteredFiles = filteredFiles.filter(file => 
          (file.size || 0) >= params.minSize!
        );
      }
      
      if (params.maxSize !== undefined) {
        filteredFiles = filteredFiles.filter(file => 
          (file.size || 0) <= params.maxSize!
        );
      }
      
      if (params.minDate !== undefined) {
        filteredFiles = filteredFiles.filter(file => 
          (file.modifiedAt || 0) >= params.minDate!
        );
      }
      
      if (params.maxDate !== undefined) {
        filteredFiles = filteredFiles.filter(file => 
          (file.modifiedAt || 0) <= params.maxDate!
        );
      }
      
      if (params.pattern) {
        const regex = new RegExp(params.pattern, 'i');
        filteredFiles = filteredFiles.filter(file => 
          regex.test(file.name)
        );
      }
      
      // 排序
      if (params.sortBy && params.sortBy !== FileSortBy.NONE) {
        filteredFiles.sort((a, b) => {
          let compareResult = 0;
          
          switch (params.sortBy) {
            case FileSortBy.NAME:
              compareResult = a.name.localeCompare(b.name);
              break;
            case FileSortBy.SIZE:
              compareResult = (a.size || 0) - (b.size || 0);
              break;
            case FileSortBy.DATE:
              compareResult = (a.modifiedAt || 0) - (b.modifiedAt || 0);
              break;
            case FileSortBy.TYPE:
              compareResult = this.getFileType(a.path).localeCompare(this.getFileType(b.path));
              break;
            case FileSortBy.EXTENSION:
              const extA = FileUtil.getExtension(a.path).toLowerCase();
              const extB = FileUtil.getExtension(b.path).toLowerCase();
              compareResult = extA.localeCompare(extB);
              break;
          }
          
          // 应用排序方向
          if (params.sortDirection === FileSortDirection.DESCENDING) {
            compareResult = -compareResult;
          }
          
          return compareResult;
        });
      }
      
      // 分页
      if (params.offset !== undefined) {
        filteredFiles = filteredFiles.slice(params.offset);
      }
      
      if (params.limit !== undefined) {
        filteredFiles = filteredFiles.slice(0, params.limit);
      }
      
      // 转换为扩展信息
      const result: ExtendedFileInfo[] = [];
      for (const file of filteredFiles) {
        const info = await this.getFileInfo(file.path);
        if (info) {
          result.push(info);
        }
      }
      
      Logger.info(TAG, `Found ${result.length} files matching search criteria`);
      return result;
    } catch (error) {
      Logger.error(TAG, 'Failed to search files', error);
      return [];
    }
  }

  /**
   * 创建临时文件
   */
  public async createTempFile(prefix?: string, extension?: string): Promise<string | null> {
    try {
      const tempPath = this.fileConfig.tempDir;
      const fileName = `${prefix || 'temp'}_${Date.now()}_${Math.random().toString(36).substr(2, 9)}${extension ? '.' + extension : ''}`;
      const filePath = `${tempPath}/${fileName}`;
      
      await FileUtil.writeFile(filePath, '', { create: true });
      
      Logger.debug(TAG, `Created temporary file: ${filePath}`);
      return filePath;
    } catch (error) {
      Logger.error(TAG, 'Failed to create temporary file', error);
      return null;
    }
  }

  /**
   * 创建目录
   */
  public async createDirectory(path: string, recursive: boolean = true): Promise<FileOperationResult> {
    try {
      await FileUtil.ensureDirectory(path);
      
      Logger.debug(TAG, `Created directory: ${path}`);
      return {
        success: true,
        path
      };
    } catch (error) {
      Logger.error(TAG, `Failed to create directory: ${path}`, error);
      return {
        success: false,
        error: String(error)
      };
    }
  }

  /**
   * 删除文件
   */
  public async deleteFile(filePath: string): Promise<FileOperationResult> {
    try {
      // 检查文件是否存在
      const exists = await FileUtil.fileExists(filePath);
      if (!exists) {
        return {
          success: false,
          error: 'File does not exist'
        };
      }
      
      await FileUtil.deleteFile(filePath);
      
      Logger.debug(TAG, `Deleted file: ${filePath}`);
      return {
        success: true,
        path: filePath
      };
    } catch (error) {
      Logger.error(TAG, `Failed to delete file: ${filePath}`, error);
      return {
        success: false,
        error: String(error)
      };
    }
  }

  /**
   * 删除目录
   */
  public async deleteDirectory(path: string, recursive: boolean = false): Promise<FileOperationResult> {
    try {
      // 检查目录是否存在
      const exists = await FileUtil.directoryExists(path);
      if (!exists) {
        return {
          success: false,
          error: 'Directory does not exist'
        };
      }
      
      await FileUtil.deleteDirectory(path, recursive);
      
      Logger.debug(TAG, `Deleted directory: ${path}${recursive ? ' (recursive)' : ''}`);
      return {
        success: true,
        path
      };
    } catch (error) {
      Logger.error(TAG, `Failed to delete directory: ${path}`, error);
      return {
        success: false,
        error: String(error)
      };
    }
  }

  /**
   * 复制文件
   */
  public async copyFile(source: string, destination: string): Promise<FileOperationResult> {
    try {
      // 检查源文件是否存在
      const sourceExists = await FileUtil.fileExists(source);
      if (!sourceExists) {
        return {
          success: false,
          error: 'Source file does not exist'
        };
      }
      
      // 创建目标目录
      const destDir = FileUtil.getDirectory(destination);
      await FileUtil.ensureDirectory(destDir);
      
      // 复制文件
      await FileUtil.copyFile(source, destination);
      
      Logger.debug(TAG, `Copied file from ${source} to ${destination}`);
      return {
        success: true,
        path: destination
      };
    } catch (error) {
      Logger.error(TAG, `Failed to copy file from ${source} to ${destination}`, error);
      return {
        success: false,
        error: String(error)
      };
    }
  }

  /**
   * 移动文件
   */
  public async moveFile(source: string, destination: string): Promise<FileOperationResult> {
    try {
      // 检查源文件是否存在
      const sourceExists = await FileUtil.fileExists(source);
      if (!sourceExists) {
        return {
          success: false,
          error: 'Source file does not exist'
        };
      }
      
      // 创建目标目录
      const destDir = FileUtil.getDirectory(destination);
      await FileUtil.ensureDirectory(destDir);
      
      // 移动文件
      await FileUtil.moveFile(source, destination);
      
      Logger.debug(TAG, `Moved file from ${source} to ${destination}`);
      return {
        success: true,
        path: destination
      };
    } catch (error) {
      Logger.error(TAG, `Failed to move file from ${source} to ${destination}`, error);
      return {
        success: false,
        error: String(error)
      };
    }
  }

  /**
   * 重命名文件
   */
  public async renameFile(filePath: string, newName: string): Promise<FileOperationResult> {
    try {
      // 检查文件是否存在
      const exists = await FileUtil.fileExists(filePath);
      if (!exists) {
        return {
          success: false,
          error: 'File does not exist'
        };
      }
      
      // 获取目录路径
      const directory = FileUtil.getDirectory(filePath);
      const newPath = `${directory}/${newName}`;
      
      // 重命名文件
      await FileUtil.moveFile(filePath, newPath);
      
      Logger.debug(TAG, `Renamed file from ${filePath} to ${newPath}`);
      return {
        success: true,
        path: newPath
      };
    } catch (error) {
      Logger.error(TAG, `Failed to rename file: ${filePath} to ${newName}`, error);
      return {
        success: false,
        error: String(error)
      };
    }
  }

  /**
   * 读取文件内容
   */
  public async readFile(filePath: string, encoding: string = 'utf-8'): Promise<string | null> {
    try {
      const content = await FileUtil.readFile(filePath, encoding);
      return content;
    } catch (error) {
      Logger.error(TAG, `Failed to read file: ${filePath}`, error);
      return null;
    }
  }

  /**
   * 写入文件内容
   */
  public async writeFile(
    filePath: string,
    content: string | ArrayBuffer,
    options?: { create?: boolean; append?: boolean }
  ): Promise<FileOperationResult> {
    try {
      // 创建目录（如果需要）
      if (options?.create) {
        const directory = FileUtil.getDirectory(filePath);
        await FileUtil.ensureDirectory(directory);
      }
      
      await FileUtil.writeFile(filePath, content, options);
      
      Logger.debug(TAG, `Wrote to file: ${filePath}`);
      return {
        success: true,
        path: filePath
      };
    } catch (error) {
      Logger.error(TAG, `Failed to write to file: ${filePath}`, error);
      return {
        success: false,
        error: String(error)
      };
    }
  }

  /**
   * 格式化文件大小显示
   */
  private formatSize(bytes: number): string {
    if (bytes < 1024) {
      return `${bytes} B`;
    } else if (bytes < 1024 * 1024) {
      return `${(bytes / 1024).toFixed(2)} KB`;
    } else if (bytes < 1024 * 1024 * 1024) {
      return `${(bytes / (1024 * 1024)).toFixed(2)} MB`;
    } else {
      return `${(bytes / (1024 * 1024 * 1024)).toFixed(2)} GB`;
    }
  }

  /**
   * 计算文件校验和
   */
  public async calculateChecksum(filePath: string, algorithm: 'md5' | 'sha1' | 'sha256' = 'md5'): Promise<string | null> {
    try {
      // 实际应用中，这里应该计算文件的校验和
      // 这里简化为返回模拟数据
      Logger.debug(TAG, `Calculating ${algorithm} checksum for: ${filePath}`);
      return 'mock_checksum_value';
    } catch (error) {
      Logger.error(TAG, `Failed to calculate checksum for: ${filePath}`, error);
      return null;
    }
  }

  /**
   * 压缩文件/目录
   */
  public async compress(
    source: string,
    destination: string,
    format: 'zip' | 'tar' | 'gz' = 'zip'
  ): Promise<FileOperationResult> {
    try {
      // 实际应用中，这里应该实现文件压缩功能
      Logger.debug(TAG, `Compressing ${source} to ${destination} (format: ${format})`);
      
      // 模拟压缩操作
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      return {
        success: true,
        path: destination,
        details: {
          format,
          source
        }
      };
    } catch (error) {
      Logger.error(TAG, `Failed to compress ${source}`, error);
      return {
        success: false,
        error: String(error)
      };
    }
  }

  /**
   * 解压文件
   */
  public async decompress(
    source: string,
    destination: string
  ): Promise<FileOperationResult> {
    try {
      // 实际应用中，这里应该实现文件解压功能
      Logger.debug(TAG, `Decompressing ${source} to ${destination}`);
      
      // 模拟解压操作
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      return {
        success: true,
        path: destination,
        details: {
          source
        }
      };
    } catch (error) {
      Logger.error(TAG, `Failed to decompress ${source}`, error);
      return {
        success: false,
        error: String(error)
      };
    }
  }

  /**
   * 获取目录信息
   */
  public async getDirectoryInfo(path: string): Promise<FolderInfo | null> {
    try {
      const stats = await FileUtil.getDirectoryStats(path);
      if (!stats) {
        return null;
      }
      
      const folderInfo: FolderInfo = {
        path,
        name: FileUtil.getFileName(path),
        parentPath: FileUtil.getDirectory(path),
        storageLocation: this.getStorageLocation(path),
        fileCount: stats.fileCount,
        folderCount: stats.directoryCount,
        totalSize: stats.totalSize,
        createdAt: Date.now(),
        modifiedAt: stats.modifiedAt || Date.now(),
        accessedAt: Date.now(),
        permissions: await this.getFilePermissions(path)
      };
      
      return folderInfo;
    } catch (error) {
      Logger.error(TAG, `Failed to get directory info: ${path}`, error);
      return null;
    }
  }

  /**
   * 获取目录内容
   */
  public async getDirectoryContent(
    path: string,
    sortBy: FileSortBy = FileSortBy.NAME,
    sortDirection: FileSortDirection = FileSortDirection.ASCENDING
  ): Promise<{ files: ExtendedFileInfo[]; folders: FolderInfo[] }> {
    try {
      const contents = await FileUtil.readDirectory(path, false);
      
      // 分离文件和目录
      const fileList = contents.filter(item => !item.isDirectory);
      const folderList = contents.filter(item => item.isDirectory);
      
      // 处理文件信息
      const files: ExtendedFileInfo[] = [];
      for (const file of fileList) {
        const info = await this.getFileInfo(file.path);
        if (info) {
          files.push(info);
        }
      }
      
      // 处理目录信息
      const folders: FolderInfo[] = [];
      for (const folder of folderList) {
        const info = await this.getDirectoryInfo(folder.path);
        if (info) {
          folders.push(info);
        }
      }
      
      // 排序
      if (sortBy !== FileSortBy.NONE) {
        // 排序逻辑...
      }
      
      Logger.debug(TAG, `Retrieved ${files.length} files and ${folders.length} folders from ${path}`);
      return { files, folders };
    } catch (error) {
      Logger.error(TAG, `Failed to get directory content: ${path}`, error);
      return { files: [], folders: [] };
    }
  }

  /**
   * 清理临时文件
   */
  public async cleanupTempFiles(): Promise<{ deletedCount: number; freedSpace: number }> {
    return this.cleanupDirectory(this.fileConfig.tempDir, 0);
  }

  /**
   * 清理缓存文件
   */
  public async cleanupCache(): Promise<{ deletedCount: number; freedSpace: number }> {
    const result = await this.cleanupDirectory(this.fileConfig.cacheDir, 0);
    return result;
  }

  /**
   * 添加存储设备变更监听器
   */
  public addStorageListener(listener: (devices: StorageDeviceInfo[]) => void): () => void {
    this.storageListeners.push(listener);
    
    // 立即回调当前设备列表
    listener(Array.from(this.storageDevices.values()));
    
    // 返回取消监听函数
    return () => {
      const index = this.storageListeners.indexOf(listener);
      if (index > -1) {
        this.storageListeners.splice(index, 1);
      }
    };
  }

  /**
   * 添加传输进度监听器
   */
  public addTransferListener(
    taskId: string,
    listener: (progress: FileTransferProgress) => void
  ): () => void {
    if (!this.transferListeners.has(taskId)) {
      this.transferListeners.set(taskId, []);
    }
    
    const listeners = this.transferListeners.get(taskId)!;
    listeners.push(listener);
    
    // 立即回调当前进度
    const task = this.transferTasks.get(taskId);
    if (task) {
      listener({ ...task });
    }
    
    // 返回取消监听函数
    return () => {
      const index = listeners.indexOf(listener);
      if (index > -1) {
        listeners.splice(index, 1);
      }
      
      // 如果没有监听器了，清理Map
      if (listeners.length === 0) {
        this.transferListeners.delete(taskId);
      }
    };
  }

  /**
   * 添加清理监听器
   */
  public addCleanupListener(listener: (deletedCount: number, freedSpace: number) => void): () => void {
    this.cleanupListeners.push(listener);
    
    // 返回取消监听函数
    return () => {
      const index = this.cleanupListeners.indexOf(listener);
      if (index > -1) {
        this.cleanupListeners.splice(index, 1);
      }
    };
  }

  /**
   * 通知存储设备变更
   */
  private notifyStorageDevicesChanged(): void {
    const devices = Array.from(this.storageDevices.values());
    for (const listener of this.storageListeners) {
      try {
        listener(devices);
      } catch (error) {
        Logger.error(TAG, 'Error in storage listener', error);
      }
    }
  }

  /**
   * 通知传输进度变更
   */
  private notifyTransferProgressChanged(task: FileTransferProgress): void {
    if (!this.transferListeners.has(task.id)) return;
    
    const listeners = this.transferListeners.get(task.id)!;
    for (const listener of listeners) {
      try {
        listener({ ...task });
      } catch (error) {
        Logger.error(TAG, `Error in transfer listener for task ${task.id}`, error);
      }
    }
  }

  /**
   * 通知清理完成
   */
  private notifyCleanupCompleted(deletedCount: number, freedSpace: number): void {
    for (const listener of this.cleanupListeners) {
      try {
        listener(deletedCount, freedSpace);
      } catch (error) {
        Logger.error(TAG, 'Error in cleanup listener', error);
      }
    }
  }

  /**
   * 销毁文件服务
   */
  public async destroy(): Promise<void> {
    try {
      Logger.info(TAG, 'Destroying file service...');
      
      // 停止自动清理
      this.stopAutoCleanup();
      
      // 停止文件监控
      this.stopFileWatchers();
      
      // 清理临时文件（可选）
      if (this.fileConfig.enableAutoCleanup) {
        await this.cleanupTempFiles();
      }
      
      // 清除监听器
      this.storageListeners = [];
      this.transferListeners.clear();
      this.cleanupListeners = [];
      
      // 清除任务
      this.transferTasks.clear();
      this.activeOperations.clear();
      
      Logger.info(TAG, 'File service destroyed successfully');
    } catch (error) {
      Logger.error(TAG, 'Failed to destroy file service', error);
    }
  }
}