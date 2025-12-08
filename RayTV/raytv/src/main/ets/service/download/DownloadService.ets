// DownloadService - 下载服务�?import Logger from '../../common/util/Logger';
import StorageUtil from '../../common/util/StorageUtil';
import DateUtil from '../../common/util/DateUtil';
import FileUtil from '../../common/util/FileUtil';
import NetworkUtil from '../../common/util/NetworkUtil';
import RepositoryFactory from '../../data/repository/RepositoryFactory';
import DatabaseRepository from '../../data/repository/DatabaseRepository';
import NetworkRepository from '../../data/repository/NetworkRepository';
import ConfigService from '../config/ConfigService';

// 导入模型和DTO
import ApiResponse, { ResponseCode } from '../dto/ApiResponse';
import Movie, { VideoSource, VideoType } from '../model/Movie';

// 常量定义
const TAG = 'DownloadService';
const DOWNLOAD_QUEUE_KEY = 'download_queue';
const DOWNLOAD_SETTINGS_KEY = 'download_settings';

// 下载状态枚�?export enum DownloadStatus {
  QUEUED = 'queued',        // 已加入队�?  DOWNLOADING = 'downloading',  // 下载�?  PAUSED = 'paused',        // 暂停
  COMPLETED = 'completed',    // 完成
  FAILED = 'failed',        // 失败
  CANCELLED = 'cancelled'    // 取消
}

// 下载错误类型枚举
export enum DownloadErrorType {
  NETWORK_ERROR = 'network_error',
  STORAGE_ERROR = 'storage_error',
  PERMISSION_ERROR = 'permission_error',
  SERVER_ERROR = 'server_error',
  TIMEOUT_ERROR = 'timeout_error',
  INVALID_URL_ERROR = 'invalid_url_error',
  DISK_FULL_ERROR = 'disk_full_error',
  UNKNOWN_ERROR = 'unknown_error'
}

// 下载任务接口
export interface DownloadTask {
  id: string;              // 任务唯一标识
  movieId: string;          // 电影ID
  movieTitle: string;        // 电影标题
  episodeTitle?: string;     // 剧集标题（可选）
  seasonNumber?: number;      // 季数（可选）
  episodeNumber?: number;     // 集数（可选）
  videoType: VideoType;       // 视频类型
  videoSource: VideoSource;    // 视频�?  videoQuality: string;       // 视频质量
  videoUrl: string;          // 视频URL
  coverUrl?: string;         // 封面URL
  totalSize: number;         // 总大小（字节�?  downloadedSize: number;      // 已下载大小（字节�?  progress: number;          // 下载进度�?-100�?  status: DownloadStatus;     // 下载状�?  downloadSpeed: number;      // 下载速度（字�?秒）
  startTime?: number;         // 开始时�?  endTime?: number;          // 结束时间
  errorType?: DownloadErrorType; // 错误类型
  errorMessage?: string;      // 错误信息
  downloadPath: string;       // 下载文件路径
  tempFilePath: string;       // 临时文件路径
  resumedFrom: number;        // 续传起始位置
  isActive: boolean;          // 是否为活动任�?  isHighPriority: boolean;     // 是否高优先级
  networkType: 'all' | 'wifi' | 'cellular'; // 网络类型限制
  autoStart: boolean;         // 是否自动开�?  userData?: Record<string, any>; // 用户自定义数�?}

// 下载设置接口
export interface DownloadSettings {
  maxConcurrentDownloads: number; // 最大并发下载数
  downloadNetworkType: 'all' | 'wifi' | 'cellular'; // 允许的网络类�?  autoResumeDownloads: boolean; // 是否自动恢复下载
  autoDeleteFailedDownloads: boolean; // 是否自动删除失败下载
  autoPlayCompletedDownloads: boolean; // 是否自动播放完成的下�?  downloadFolder: string; // 下载文件�?  maxDownloadSize: number; // 最大下载大小（MB�?  allowBackgroundDownloads: boolean; // 是否允许后台下载
  showNotifications: boolean; // 是否显示通知
  playWhileDownloading: boolean; // 是否允许边下边播
  verifyDownloads: boolean; // 是否验证下载
  deleteSourceFiles: boolean; // 是否删除源文�?  cleanTempFiles: boolean; // 是否清理临时文件
}

// 默认下载设置
export const DEFAULT_DOWNLOAD_SETTINGS: DownloadSettings = {
  maxConcurrentDownloads: 3,
  downloadNetworkType: 'all',
  autoResumeDownloads: true,
  autoDeleteFailedDownloads: false,
  autoPlayCompletedDownloads: false,
  downloadFolder: '', // 将在初始化时设置
  maxDownloadSize: 5000, // 5GB
  allowBackgroundDownloads: true,
  showNotifications: true,
  playWhileDownloading: false,
  verifyDownloads: true,
  deleteSourceFiles: false,
  cleanTempFiles: true
};

/**
 * 下载服务�? * 负责管理视频下载任务和下载队�? */
export default class DownloadService {
  private static instance: DownloadService;
  private databaseRepo: DatabaseRepository;
  private networkRepo: NetworkRepository;
  private configService: ConfigService;
  
  private downloadQueue: DownloadTask[] = [];
  private activeTasks: Set<string> = new Set();
  private settings: DownloadSettings = { ...DEFAULT_DOWNLOAD_SETTINGS };
  private isInitialized: boolean = false;
  private pauseDownloadsOnQueueFull: boolean = false;
  
  // 任务监听�?  private taskListeners: Map<string, Array<(task: DownloadTask) => void>> = new Map();
  private queueListeners: Array<(queue: DownloadTask[]) => void> = [];
  private statusListeners: Map<DownloadStatus, Array<(task: DownloadTask) => void>> = new Map();

  /**
   * 构造函数（私有，防止外部实例化�?   */
  private constructor() {
    this.databaseRepo = RepositoryFactory.getRepository('database') as DatabaseRepository;
    this.networkRepo = RepositoryFactory.getRepository('network') as NetworkRepository;
    this.configService = ConfigService.getInstance();
    this.initialize();
  }

  /**
   * 获取单例实例
   */
  public static getInstance(): DownloadService {
    if (!DownloadService.instance) {
      DownloadService.instance = new DownloadService();
    }
    return DownloadService.instance;
  }

  /**
   * 初始化下载服�?   */
  public async initialize(): Promise<void> {
    try {
      Logger.info(TAG, 'Initializing download service...');
      
      // 设置默认下载文件�?      this.settings.downloadFolder = await FileUtil.getDownloadDirectory('RayTV');
      
      // 从数据库加载下载队列
      const savedQueue = await this.databaseRepo.getDownloadQueue();
      if (savedQueue && savedQueue.length > 0) {
        this.downloadQueue = savedQueue;
        Logger.info(TAG, `Loaded ${this.downloadQueue.length} download tasks from database`);
      }
      
      // 从配置服务加载设�?      await this.loadSettingsFromConfig();
      
      // 从本地存储加载设置（兼容旧版本）
      const savedSettings = await StorageUtil.getObject<DownloadSettings>(DOWNLOAD_SETTINGS_KEY);
      if (savedSettings) {
        this.settings = { ...this.settings, ...savedSettings };
      }
      
      // 清理已完成的临时文件
      if (this.settings.cleanTempFiles) {
        await this.cleanupTempFiles();
      }
      
      // 检查下载文件夹是否存在
      const exists = await FileUtil.directoryExists(this.settings.downloadFolder);
      if (!exists) {
        await FileUtil.createDirectory(this.settings.downloadFolder);
      }
      
      // 启动等待中的任务
      if (this.settings.autoResumeDownloads) {
        await this.startPendingDownloads();
      }
      
      this.isInitialized = true;
      Logger.info(TAG, 'Download service initialized successfully');
    } catch (error) {
      Logger.error(TAG, 'Failed to initialize download service', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))));
    }
  }

  /**
   * 从配置服务加载设�?   */
  private async loadSettingsFromConfig(): Promise<void> {
    try {
      const maxDownloads = await this.configService.getConfig('maxConcurrentDownloads');
      if (maxDownloads.isSuccess() && typeof maxDownloads.data === 'number') {
        this.settings.maxConcurrentDownloads = maxDownloads.data;
      }
      
      const networkType = await this.configService.getConfig('downloadNetworkType');
      if (networkType.isSuccess() && 
          (networkType.data === 'all' || networkType.data === 'wifi' || networkType.data === 'cellular')) {
        this.settings.downloadNetworkType = networkType.data;
      }
      
      const cacheLimit = await this.configService.getConfig('cacheLimit');
      if (cacheLimit.isSuccess() && typeof cacheLimit.data === 'number') {
        this.settings.maxDownloadSize = cacheLimit.data;
      }
    } catch (error) {
      Logger.error(TAG, 'Failed to load settings from config', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))));
    }
  }

  /**
   * 添加下载任务
   */
  public async addDownloadTask(
    movie: Movie,
    videoSource: VideoSource,
    videoQuality: string,
    options?: {
      episodeTitle?: string;
      seasonNumber?: number;
      episodeNumber?: number;
      isHighPriority?: boolean;
      autoStart?: boolean;
      userData?: Record<string, unknown>;
    }
  ): Promise<ApiResponse<DownloadTask>> {
    try {
      // 检查网络状�?      const networkAvailable = await NetworkUtil.isNetworkAvailable();
      if (!networkAvailable) {
        return ApiResponse.error(ResponseCode.NETWORK_ERROR, '网络不可用，无法开始下�?);
      }
      
      // 检查网络类型限�?      const networkType = await NetworkUtil.getNetworkType();
      if (this.settings.downloadNetworkType === 'wifi' && networkType !== 'wifi') {
        return ApiResponse.error(ResponseCode.NETWORK_ERROR, '仅在WiFi网络下允许下�?);
      }
      
      if (this.settings.downloadNetworkType === 'cellular' && networkType !== 'cellular') {
        return ApiResponse.error(ResponseCode.NETWORK_ERROR, '仅在移动网络下允许下�?);
      }
      
      // 检查存储空�?      const freeSpace = await FileUtil.getFreeSpace();
      if (freeSpace <= 0) {
        return ApiResponse.error(ResponseCode.STORAGE_ERROR, '无法获取可用存储空间');
      }
      
      // 创建任务ID
      const taskId = `download_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
      
      // 生成文件路径
      const fileName = FileUtil.sanitizeFileName(`${movie.title}${options?.episodeTitle ? `_${options.episodeTitle}` : ''}_${videoQuality}`);
      const fileExtension = videoSource.url.split('.').pop() || 'mp4';
      const downloadPath = `${this.settings.downloadFolder}/${fileName}.${fileExtension}`;
      const tempFilePath = `${downloadPath}.temp`;
      
      // 创建下载任务
      const task: DownloadTask = {
        id: taskId,
        movieId: movie.id,
        movieTitle: movie.title,
        episodeTitle: options?.episodeTitle,
        seasonNumber: options?.seasonNumber,
        episodeNumber: options?.episodeNumber,
        videoType: movie.type,
        videoSource: videoSource,
        videoQuality: videoQuality,
        videoUrl: videoSource.url,
        coverUrl: movie.coverUrl,
        totalSize: videoSource.size || 0,
        downloadedSize: 0,
        progress: 0,
        status: DownloadStatus.QUEUED,
        downloadSpeed: 0,
        downloadPath: downloadPath,
        tempFilePath: tempFilePath,
        resumedFrom: 0,
        isActive: false,
        isHighPriority: options?.isHighPriority || false,
        networkType: this.settings.downloadNetworkType,
        autoStart: options?.autoStart !== undefined ? options.autoStart : true,
        userData: options?.userData
      };
      
      // 检查文件是否已存在
      const fileExists = await FileUtil.fileExists(downloadPath);
      if (fileExists) {
        const fileSize = await FileUtil.getFileSize(downloadPath);
        if (videoSource.size && fileSize === videoSource.size) {
          // 文件已存在且大小匹配，标记为已完�?          task.status = DownloadStatus.COMPLETED;
          task.progress = 100;
          task.downloadedSize = fileSize;
          task.totalSize = fileSize;
        } else if (this.settings.verifyDownloads) {
          // 文件存在但不完整，删除旧文件
          await FileUtil.deleteFile(downloadPath);
        }
      }
      
      // 添加到下载队�?      if (task.isHighPriority) {
        this.downloadQueue.unshift(task);
      } else {
        this.downloadQueue.push(task);
      }
      
      // 保存队列到数据库
      await this.saveDownloadQueue();
      
      // 通知队列变更
      this.notifyQueueChanged();
      
      // 自动开始下�?      if (task.autoStart && task.status === DownloadStatus.QUEUED) {
        await this.startDownload(task.id);
      }
      
      Logger.info(TAG, `Added download task: ${task.id} - ${task.movieTitle}`);
      return ApiResponse.success(task, '添加下载任务成功');
    } catch (error) {
      Logger.error(TAG, 'Failed to add download task', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))));
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '添加下载任务失败');
    }
  }

  /**
   * 开始下载任�?   */
  public async startDownload(taskId: string): Promise<ApiResponse<DownloadTask>> {
    try {
      Logger.info(TAG, `Starting download task: ${taskId}`);
      
      const taskIndex = this.downloadQueue.findIndex(task => task.id === taskId);
      if (taskIndex === -1) {
        return ApiResponse.error(ResponseCode.NOT_FOUND, '下载任务不存�?);
      }
      
      const task = this.downloadQueue[taskIndex];
      
      // 检查任务状�?      if (task.status === DownloadStatus.COMPLETED) {
        return ApiResponse.success(task, '任务已经完成');
      }
      
      if (task.status === DownloadStatus.DOWNLOADING) {
        return ApiResponse.success(task, '任务已经在下载中');
      }
      
      if (task.status === DownloadStatus.CANCELLED) {
        return ApiResponse.error(ResponseCode.INVALID_OPERATION, '已取消的任务无法重新开�?);
      }
      
      // 检查活动任务数�?      if (this.activeTasks.size >= this.settings.maxConcurrentDownloads) {
        this.pauseDownloadsOnQueueFull = true;
        return ApiResponse.error(ResponseCode.LIMIT_EXCEEDED, '下载队列已满，请等待当前任务完成');
      }
      
      // 更新任务状�?      task.status = DownloadStatus.DOWNLOADING;
      task.isActive = true;
      if (!task.startTime) {
        task.startTime = Date.now();
      }
      
      // 添加到活动任务集
      this.activeTasks.add(taskId);
      
      // 更新队列并保�?      this.downloadQueue[taskIndex] = task;
      await this.saveDownloadQueue();
      
      // 通知任务状态变�?      this.notifyTaskChanged(task);
      this.notifyStatusChanged(DownloadStatus.DOWNLOADING, task);
      this.notifyQueueChanged();
      
      // 启动下载（异步）
      this.performDownload(taskId).catch(error => {
        Logger.error(TAG, `Download failed for task: ${taskId}`, error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))));
      });
      
      return ApiResponse.success(task, '开始下载成�?);
    } catch (error) {
      Logger.error(TAG, `Failed to start download task: ${taskId}`, error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))));
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '开始下载失�?);
    }
  }

  /**
   * 执行下载任务（内部方法）
   */
  private async performDownload(taskId: string): Promise<void> {
    try {
      const taskIndex = this.downloadQueue.findIndex(task => task.id === taskId);
      if (taskIndex === -1 || !this.downloadQueue[taskIndex].isActive) {
        return;
      }
      
      let task = this.downloadQueue[taskIndex];
      
      // 检查临时文件是否存在，用于续传
      const tempFileExists = await FileUtil.fileExists(task.tempFilePath);
      if (tempFileExists) {
        const tempSize = await FileUtil.getFileSize(task.tempFilePath);
        task.downloadedSize = tempSize;
        task.resumedFrom = tempSize;
      }
      
      // 开始下�?      const startTime = Date.now();
      let lastProgressUpdate = startTime;
      let lastDownloadedSize = task.downloadedSize;
      
      // 这里应该实现实际的下载逻辑
      // 由于这是模拟实现，我们用一个简单的进度更新代替
      const updateInterval = setInterval(async () => {
        if (!task.isActive || task.status !== DownloadStatus.DOWNLOADING) {
          clearInterval(updateInterval);
          return;
        }
        
        // 更新下载进度（模拟）
        const currentTime = Date.now();
        const elapsedTime = currentTime - lastProgressUpdate;
        
        if (elapsedTime >= 1000) { // 每秒更新一�?          // 模拟下载速度�?0KB/s - 2MB/s�?          const simulatedSpeed = 50 * 1024 + Math.random() * 1.95 * 1024 * 1024;
          const downloadedBytes = Math.floor(simulatedSpeed * (elapsedTime / 1000));
          
          task.downloadedSize += downloadedBytes;
          task.downloadSpeed = simulatedSpeed;
          
          // 计算进度
          if (task.totalSize > 0) {
            task.progress = Math.min(100, Math.floor((task.downloadedSize / task.totalSize) * 100));
          }
          
          // 更新队列
          this.downloadQueue[taskIndex] = task;
          
          // �?秒保存一次进�?          if (currentTime - startTime >= 5000) {
            await this.saveDownloadQueue();
          }
          
          // 通知进度更新
          this.notifyTaskChanged(task);
          
          lastProgressUpdate = currentTime;
          lastDownloadedSize = task.downloadedSize;
        }
        
        // 检查下载是否完�?        if (task.totalSize > 0 && task.downloadedSize >= task.totalSize) {
          clearInterval(updateInterval);
          
          // 标记任务完成
          await this.completeDownload(taskId);
        }
      }, 100); // �?00ms检查一�?      
      // 模拟下载完成
      // 在实际应用中，这里应该是真实的下载实�?      // 这里只是为了演示
    } catch (error) {
      Logger.error(TAG, `Error performing download for task: ${taskId}`, error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))));
      await this.failDownload(taskId, DownloadErrorType.UNKNOWN_ERROR, String(error));
    }
  }

  /**
   * 暂停下载任务
   */
  public async pauseDownload(taskId: string): Promise<ApiResponse<DownloadTask>> {
    try {
      Logger.info(TAG, `Pausing download task: ${taskId}`);
      
      const taskIndex = this.downloadQueue.findIndex(task => task.id === taskId);
      if (taskIndex === -1) {
        return ApiResponse.error(ResponseCode.NOT_FOUND, '下载任务不存�?);
      }
      
      const task = this.downloadQueue[taskIndex];
      
      // 检查任务状�?      if (task.status !== DownloadStatus.DOWNLOADING) {
        return ApiResponse.error(ResponseCode.INVALID_OPERATION, `任务状态不允许暂停: ${task.status}`);
      }
      
      // 更新任务状�?      task.status = DownloadStatus.PAUSED;
      task.isActive = false;
      
      // 从活动任务集中移�?      this.activeTasks.delete(taskId);
      
      // 更新队列并保�?      this.downloadQueue[taskIndex] = task;
      await this.saveDownloadQueue();
      
      // 通知任务状态变�?      this.notifyTaskChanged(task);
      this.notifyStatusChanged(DownloadStatus.PAUSED, task);
      this.notifyQueueChanged();
      
      // 检查是否有等待的任务可以开�?      if (this.pauseDownloadsOnQueueFull) {
        await this.startNextTaskInQueue();
      }
      
      return ApiResponse.success(task, '暂停下载成功');
    } catch (error) {
      Logger.error(TAG, `Failed to pause download task: ${taskId}`, error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))));
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '暂停下载失败');
    }
  }

  /**
   * 恢复下载任务
   */
  public async resumeDownload(taskId: string): Promise<ApiResponse<DownloadTask>> {
    try {
      Logger.info(TAG, `Resuming download task: ${taskId}`);
      
      const taskIndex = this.downloadQueue.findIndex(task => task.id === taskId);
      if (taskIndex === -1) {
        return ApiResponse.error(ResponseCode.NOT_FOUND, '下载任务不存�?);
      }
      
      const task = this.downloadQueue[taskIndex];
      
      // 检查任务状�?      if (task.status !== DownloadStatus.PAUSED) {
        return ApiResponse.error(ResponseCode.INVALID_OPERATION, `任务状态不允许恢复: ${task.status}`);
      }
      
      // 检查网络状�?      const networkAvailable = await NetworkUtil.isNetworkAvailable();
      if (!networkAvailable) {
        return ApiResponse.error(ResponseCode.NETWORK_ERROR, '网络不可用，无法恢复下载');
      }
      
      // 检查网络类型限�?      const networkType = await NetworkUtil.getNetworkType();
      if (task.networkType === 'wifi' && networkType !== 'wifi') {
        return ApiResponse.error(ResponseCode.NETWORK_ERROR, '仅在WiFi网络下允许下�?);
      }
      
      if (task.networkType === 'cellular' && networkType !== 'cellular') {
        return ApiResponse.error(ResponseCode.NETWORK_ERROR, '仅在移动网络下允许下�?);
      }
      
      // 更新任务状�?      task.status = DownloadStatus.DOWNLOADING;
      task.isActive = true;
      
      // 添加到活动任务集
      this.activeTasks.add(taskId);
      
      // 更新队列并保�?      this.downloadQueue[taskIndex] = task;
      await this.saveDownloadQueue();
      
      // 通知任务状态变�?      this.notifyTaskChanged(task);
      this.notifyStatusChanged(DownloadStatus.DOWNLOADING, task);
      this.notifyQueueChanged();
      
      // 重新开始下�?      this.performDownload(taskId).catch(error => {
        Logger.error(TAG, `Failed to resume download for task: ${taskId}`, error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))));
      });
      
      return ApiResponse.success(task, '恢复下载成功');
    } catch (error) {
      Logger.error(TAG, `Failed to resume download task: ${taskId}`, error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))));
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '恢复下载失败');
    }
  }

  /**
   * 取消下载任务
   */
  public async cancelDownload(taskId: string, deleteFiles: boolean = true): Promise<ApiResponse<boolean>> {
    try {
      Logger.info(TAG, `Cancelling download task: ${taskId}, deleteFiles: ${deleteFiles}`);
      
      const taskIndex = this.downloadQueue.findIndex(task => task.id === taskId);
      if (taskIndex === -1) {
        return ApiResponse.error(ResponseCode.NOT_FOUND, '下载任务不存�?);
      }
      
      const task = this.downloadQueue[taskIndex];
      
      // 停止下载
      task.status = DownloadStatus.CANCELLED;
      task.isActive = false;
      task.endTime = Date.now();
      
      // 从活动任务集中移�?      this.activeTasks.delete(taskId);
      
      // 删除文件
      if (deleteFiles) {
        try {
          if (await FileUtil.fileExists(task.tempFilePath)) {
            await FileUtil.deleteFile(task.tempFilePath);
          }
          if (await FileUtil.fileExists(task.downloadPath)) {
            await FileUtil.deleteFile(task.downloadPath);
          }
        } catch (fileError) {
          Logger.error(TAG, `Failed to delete files for task: ${taskId}`, fileError instanceof Error ? fileError : new Error(String(fileError instanceof Error ? fileError instanceof Error ? fileError : new Error(String(fileError : new Error(String(fileError instanceof Error ? fileError : new Error(String(fileError instanceof Error ? fileError instanceof Error ? fileError : new Error(String(fileError instanceof Error ? fileError instanceof Error ? fileError : new Error(String(fileError : new Error(String(fileError instanceof Error ? fileError : new Error(String(fileError : new Error(String(fileError instanceof Error ? fileError : new Error(String(fileError instanceof Error ? fileError instanceof Error ? fileError : new Error(String(fileError : new Error(String(fileError instanceof Error ? fileError : new Error(String(fileError)))))));
        }
      }
      
      // 从队列中移除
      this.downloadQueue.splice(taskIndex, 1);
      
      // 保存队列
      await this.saveDownloadQueue();
      
      // 通知任务状态变�?      this.notifyTaskChanged(task);
      this.notifyStatusChanged(DownloadStatus.CANCELLED, task);
      this.notifyQueueChanged();
      
      // 启动下一个等待的任务
      await this.startNextTaskInQueue();
      
      return ApiResponse.success(true, '取消下载成功');
    } catch (error) {
      Logger.error(TAG, `Failed to cancel download task: ${taskId}`, error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))));
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '取消下载失败');
    }
  }

  /**
   * 完成下载任务
   */
  private async completeDownload(taskId: string): Promise<void> {
    try {
      Logger.info(TAG, `Completing download task: ${taskId}`);
      
      const taskIndex = this.downloadQueue.findIndex(task => task.id === taskId);
      if (taskIndex === -1) {
        return;
      }
      
      let task = this.downloadQueue[taskIndex];
      
      // 更新任务状�?      task.status = DownloadStatus.COMPLETED;
      task.isActive = false;
      task.progress = 100;
      task.endTime = Date.now();
      
      // 从活动任务集中移�?      this.activeTasks.delete(taskId);
      
      // 如果有临时文件，重命名为最终文�?      if (await FileUtil.fileExists(task.tempFilePath)) {
        await FileUtil.moveFile(task.tempFilePath, task.downloadPath);
      }
      
      // 更新队列并保�?      this.downloadQueue[taskIndex] = task;
      await this.saveDownloadQueue();
      
      // 通知任务状态变�?      this.notifyTaskChanged(task);
      this.notifyStatusChanged(DownloadStatus.COMPLETED, task);
      this.notifyQueueChanged();
      
      // 自动播放完成的下�?      if (this.settings.autoPlayCompletedDownloads) {
        // 这里可以触发播放事件
        Logger.info(TAG, `Auto-playing completed download: ${task.id}`);
      }
      
      // 启动下一个等待的任务
      await this.startNextTaskInQueue();
      
      Logger.info(TAG, `Download completed successfully: ${taskId}`);
    } catch (error) {
      Logger.error(TAG, `Failed to complete download task: ${taskId}`, error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))));
      await this.failDownload(taskId, DownloadErrorType.UNKNOWN_ERROR, String(error));
    }
  }

  /**
   * 标记下载任务失败
   */
  private async failDownload(
    taskId: string, 
    errorType: DownloadErrorType, 
    errorMessage: string
  ): Promise<void> {
    try {
      Logger.error(TAG, `Download failed for task: ${taskId}`, { errorType, errorMessage } instanceof Error ? { errorType, errorMessage } : new Error(String({ errorType, errorMessage } instanceof Error ? { errorType, errorMessage } instanceof Error ? { errorType, errorMessage } : new Error(String({ errorType, errorMessage } : new Error(String({ errorType, errorMessage } instanceof Error ? { errorType, errorMessage } : new Error(String({ errorType, errorMessage } instanceof Error ? { errorType, errorMessage } instanceof Error ? { errorType, errorMessage } : new Error(String({ errorType, errorMessage } instanceof Error ? { errorType, errorMessage } instanceof Error ? { errorType, errorMessage } : new Error(String({ errorType, errorMessage } : new Error(String({ errorType, errorMessage } instanceof Error ? { errorType, errorMessage } : new Error(String({ errorType, errorMessage } : new Error(String({ errorType, errorMessage } instanceof Error ? { errorType, errorMessage } : new Error(String({ errorType, errorMessage } instanceof Error ? { errorType, errorMessage } instanceof Error ? { errorType, errorMessage } : new Error(String({ errorType, errorMessage } : new Error(String({ errorType, errorMessage } instanceof Error ? { errorType, errorMessage } : new Error(String({ errorType, errorMessage })))))));
      
      const taskIndex = this.downloadQueue.findIndex(task => task.id === taskId);
      if (taskIndex === -1) {
        return;
      }
      
      let task = this.downloadQueue[taskIndex];
      
      // 更新任务状�?      task.status = DownloadStatus.FAILED;
      task.isActive = false;
      task.errorType = errorType;
      task.errorMessage = errorMessage;
      task.endTime = Date.now();
      
      // 从活动任务集中移�?      this.activeTasks.delete(taskId);
      
      // 自动删除失败的下�?      if (this.settings.autoDeleteFailedDownloads) {
        try {
          if (await FileUtil.fileExists(task.tempFilePath)) {
            await FileUtil.deleteFile(task.tempFilePath);
          }
          // 从队列中移除
          this.downloadQueue.splice(taskIndex, 1);
        } catch (fileError) {
          Logger.error(TAG, `Failed to delete failed download files for task: ${taskId}`, fileError instanceof Error ? fileError : new Error(String(fileError instanceof Error ? fileError instanceof Error ? fileError : new Error(String(fileError : new Error(String(fileError instanceof Error ? fileError : new Error(String(fileError instanceof Error ? fileError instanceof Error ? fileError : new Error(String(fileError instanceof Error ? fileError instanceof Error ? fileError : new Error(String(fileError : new Error(String(fileError instanceof Error ? fileError : new Error(String(fileError : new Error(String(fileError instanceof Error ? fileError : new Error(String(fileError instanceof Error ? fileError instanceof Error ? fileError : new Error(String(fileError : new Error(String(fileError instanceof Error ? fileError : new Error(String(fileError)))))));
        }
      } else {
        // 更新队列
        this.downloadQueue[taskIndex] = task;
      }
      
      // 保存队列
      await this.saveDownloadQueue();
      
      // 通知任务状态变�?      this.notifyTaskChanged(task);
      this.notifyStatusChanged(DownloadStatus.FAILED, task);
      this.notifyQueueChanged();
      
      // 启动下一个等待的任务
      await this.startNextTaskInQueue();
    } catch (error) {
      Logger.error(TAG, `Failed to update failed download task: ${taskId}`, error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))));
    }
  }

  /**
   * 启动队列中的下一个任�?   */
  private async startNextTaskInQueue(): Promise<void> {
    try {
      // 检查是否有空闲下载�?      if (this.activeTasks.size >= this.settings.maxConcurrentDownloads) {
        return;
      }
      
      // 查找优先级最高的等待任务
      const nextTask = this.downloadQueue.find(task => 
        (task.status === DownloadStatus.QUEUED || task.status === DownloadStatus.PAUSED) && 
        !task.isActive
      );
      
      if (nextTask) {
        this.pauseDownloadsOnQueueFull = false;
        await this.startDownload(nextTask.id);
        Logger.info(TAG, `Started next task in queue: ${nextTask.id}`);
      }
    } catch (error) {
      Logger.error(TAG, 'Failed to start next task in queue', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))));
    }
  }

  /**
   * 启动所有等待中的任�?   */
  public async startAllDownloads(): Promise<ApiResponse<{ started: number; failed: number }>> {
    try {
      Logger.info(TAG, 'Starting all download tasks');
      
      let started = 0;
      let failed = 0;
      
      // 获取所有等待中的任�?      const pendingTasks = this.downloadQueue.filter(task => 
        (task.status === DownloadStatus.QUEUED || task.status === DownloadStatus.PAUSED) && 
        !task.isActive
      );
      
      // 启动任务，受最大并发限�?      for (const task of pendingTasks) {
        if (this.activeTasks.size >= this.settings.maxConcurrentDownloads) {
          break;
        }
        
        const result = await this.startDownload(task.id);
        if (result.isSuccess()) {
          started++;
        } else {
          failed++;
        }
      }
      
      return ApiResponse.success(
        { started, failed },
        `开始下载完成，成功${started}项，失败${failed}项`
      );
    } catch (error) {
      Logger.error(TAG, 'Failed to start all downloads', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))));
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '开始所有下载失�?);
    }
  }

  /**
   * 暂停所有下载任�?   */
  public async pauseAllDownloads(): Promise<ApiResponse<{ paused: number; failed: number }>> {
    try {
      Logger.info(TAG, 'Pausing all download tasks');
      
      let paused = 0;
      let failed = 0;
      
      // 获取所有正在下载的任务
      const activeTasks = this.downloadQueue.filter(task => 
        task.status === DownloadStatus.DOWNLOADING
      );
      
      // 暂停任务
      for (const task of activeTasks) {
        const result = await this.pauseDownload(task.id);
        if (result.isSuccess()) {
          paused++;
        } else {
          failed++;
        }
      }
      
      return ApiResponse.success(
        { paused, failed },
        `暂停下载完成，成�?{paused}项，失败${failed}项`
      );
    } catch (error) {
      Logger.error(TAG, 'Failed to pause all downloads', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))));
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '暂停所有下载失�?);
    }
  }

  /**
   * 获取下载任务
   */
  public async getDownloadTask(taskId: string): Promise<ApiResponse<DownloadTask>> {
    try {
      const task = this.downloadQueue.find(task => task.id === taskId);
      
      if (!task) {
        return ApiResponse.error(ResponseCode.NOT_FOUND, '下载任务不存�?);
      }
      
      return ApiResponse.success(task, '获取下载任务成功');
    } catch (error) {
      Logger.error(TAG, `Failed to get download task: ${taskId}`, error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))));
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '获取下载任务失败');
    }
  }

  /**
   * 获取下载队列
   */
  public async getDownloadQueue(
    status?: DownloadStatus,
    videoType?: VideoType
  ): Promise<ApiResponse<DownloadTask[]>> {
    try {
      let tasks = [...this.downloadQueue];
      
      // 按状态过�?      if (status) {
        tasks = tasks.filter(task => task.status === status);
      }
      
      // 按视频类型过�?      if (videoType) {
        tasks = tasks.filter(task => task.videoType === videoType);
      }
      
      // 按优先级和状态排�?      tasks.sort((a, b) => {
        // 高优先级任务排在前面
        if (a.isHighPriority !== b.isHighPriority) {
          return a.isHighPriority ? -1 : 1;
        }
        
        // 下载中的任务排在前面
        if (a.status === DownloadStatus.DOWNLOADING && b.status !== DownloadStatus.DOWNLOADING) {
          return -1;
        }
        if (b.status === DownloadStatus.DOWNLOADING && a.status !== DownloadStatus.DOWNLOADING) {
          return 1;
        }
        
        // 暂停的任务排在队列任务前�?        if (a.status === DownloadStatus.PAUSED && b.status === DownloadStatus.QUEUED) {
          return -1;
        }
        if (b.status === DownloadStatus.PAUSED && a.status === DownloadStatus.QUEUED) {
          return 1;
        }
        
        // 其他状态按添加时间排序
        return 0;
      });
      
      return ApiResponse.success(tasks, `获取下载队列成功，共${tasks.length}项`);
    } catch (error) {
      Logger.error(TAG, 'Failed to get download queue', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))));
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '获取下载队列失败');
    }
  }

  /**
   * 获取下载统计信息
   */
  public async getDownloadStatistics(): Promise<ApiResponse<{
    totalTasks: number;
    activeTasks: number;
    completedTasks: number;
    pausedTasks: number;
    failedTasks: number;
    queuedTasks: number;
    totalDownloadedSize: number;
    totalSize: number;
    totalProgress: number;
    averageSpeed: number;
  }>> {
    try {
      const stats: Record<string, string | number | boolean | null> = { ... };
      
      // 计算总大小和总进�?      const activeTasks = this.downloadQueue.filter(t => t.isActive);
      stats.totalSize = this.downloadQueue.reduce((sum, t) => sum + (t.totalSize || 0), 0);
      stats.averageSpeed = activeTasks.length > 0 
        ? activeTasks.reduce((sum, t) => sum + t.downloadSpeed, 0) / activeTasks.length 
        : 0;
      
      if (stats.totalSize > 0) {
        stats.totalProgress = Math.floor((stats.totalDownloadedSize / stats.totalSize) * 100);
      }
      
      return ApiResponse.success(stats, '获取下载统计成功');
    } catch (error) {
      Logger.error(TAG, 'Failed to get download statistics', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))));
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '获取下载统计失败');
    }
  }

  /**
   * 清理临时文件
   */
  private async cleanupTempFiles(): Promise<void> {
    try {
      const tempFiles = await FileUtil.getFilesWithExtension(this.settings.downloadFolder, '.temp');
      
      for (const file of tempFiles) {
        try {
          await FileUtil.deleteFile(file);
          Logger.info(TAG, `Cleaned up temp file: ${file}`);
        } catch (error) {
          Logger.error(TAG, `Failed to delete temp file: ${file}`, error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))));
        }
      }
    } catch (error) {
      Logger.error(TAG, 'Failed to cleanup temp files', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))));
    }
  }

  /**
   * 保存下载队列到数据库
   */
  private async saveDownloadQueue(): Promise<void> {
    try {
      await this.databaseRepo.saveDownloadQueue(this.downloadQueue);
      await StorageUtil.setObject(DOWNLOAD_QUEUE_KEY, this.downloadQueue);
    } catch (error) {
      Logger.error(TAG, 'Failed to save download queue', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))));
    }
  }

  /**
   * 启动等待中的下载任务
   */
  private async startPendingDownloads(): Promise<void> {
    try {
      const pendingTasks = this.downloadQueue.filter(task => 
        task.status === DownloadStatus.QUEUED && !task.isActive
      );
      
      // 启动适量的任�?      const maxToStart = Math.min(pendingTasks.length, this.settings.maxConcurrentDownloads);
      
      for (let i = 0; i < maxToStart; i++) {
        await this.startDownload(pendingTasks[i].id);
      }
    } catch (error) {
      Logger.error(TAG, 'Failed to start pending downloads', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))));
    }
  }

  // ========== 事件监听相关 ==========

  /**
   * 添加下载任务监听�?   */
  public addTaskListener(taskId: string, listener: (task: DownloadTask) => void): () => void {
    if (!this.taskListeners.has(taskId)) {
      this.taskListeners.set(taskId, []);
    }
    
    const listeners = this.taskListeners.get(taskId)!;
    listeners.push(listener);
    
    // 返回取消监听函数
    return () => {
      const index = listeners.indexOf(listener);
      if (index > -1) {
        listeners.splice(index, 1);
      }
    };
  }

  /**
   * 添加下载队列监听�?   */
  public addQueueListener(listener: (queue: DownloadTask[]) => void): () => void {
    this.queueListeners.push(listener);
    
    // 返回取消监听函数
    return () => {
      const index = this.queueListeners.indexOf(listener);
      if (index > -1) {
        this.queueListeners.splice(index, 1);
      }
    };
  }

  /**
   * 添加下载状态监听器
   */
  public addStatusListener(status: DownloadStatus, listener: (task: DownloadTask) => void): () => void {
    if (!this.statusListeners.has(status)) {
      this.statusListeners.set(status, []);
    }
    
    const listeners = this.statusListeners.get(status)!;
    listeners.push(listener);
    
    // 返回取消监听函数
    return () => {
      const index = listeners.indexOf(listener);
      if (index > -1) {
        listeners.splice(index, 1);
      }
    };
  }

  /**
   * 通知任务变更
   */
  private notifyTaskChanged(task: DownloadTask): void {
    // 通知特定任务的监听器
    if (this.taskListeners.has(task.id)) {
      const listeners = this.taskListeners.get(task.id)!;
      for (const listener of listeners) {
        try {
          listener(task);
        } catch (error) {
          Logger.error(TAG, `Error in task listener for ${task.id}`, error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))));
        }
      }
    }
  }

  /**
   * 通知队列变更
   */
  private notifyQueueChanged(): void {
    for (const listener of this.queueListeners) {
      try {
        listener([...this.downloadQueue]);
      } catch (error) {
        Logger.error(TAG, 'Error in queue listener', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))));
      }
    }
  }

  /**
   * 通知状态变�?   */
  private notifyStatusChanged(status: DownloadStatus, task: DownloadTask): void {
    if (this.statusListeners.has(status)) {
      const listeners = this.statusListeners.get(status)!;
      for (const listener of listeners) {
        try {
          listener(task);
        } catch (error) {
          Logger.error(TAG, `Error in status listener for ${status}`, error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))));
        }
      }
    }
  }

  // ========== 下载设置管理 ==========

  /**
   * 获取下载设置
   */
  public getDownloadSettings(): DownloadSettings {
    return { ...this.settings };
  }

  /**
   * 更新下载设置
   */
  public async updateDownloadSettings(
    newSettings: Partial<DownloadSettings>
  ): Promise<ApiResponse<DownloadSettings>> {
    try {
      // 更新设置
      this.settings = { ...this.settings, ...newSettings };
      
      // 保存设置
      await StorageUtil.setObject(DOWNLOAD_SETTINGS_KEY, this.settings);
      
      // 如果更新了最大并发数，可能需要启动或暂停任务
      if (newSettings.maxConcurrentDownloads !== undefined) {
        const currentActiveCount = this.activeTasks.size;
        const maxConcurrent = newSettings.maxConcurrentDownloads;
        
        // 如果当前活动任务超过新限制，暂停多余的任�?        if (currentActiveCount > maxConcurrent) {
          const activeTasks = this.downloadQueue.filter(task => task.isActive);
          const tasksToPause = activeTasks.slice(maxConcurrent);
          
          for (const task of tasksToPause) {
            await this.pauseDownload(task.id);
          }
        }
        // 如果有空闲槽位，启动等待的任�?        else if (currentActiveCount < maxConcurrent) {
          await this.startNextTaskInQueue();
        }
      }
      
      Logger.info(TAG, 'Download settings updated', newSettings);
      return ApiResponse.success(this.settings, '更新下载设置成功');
    } catch (error) {
      Logger.error(TAG, 'Failed to update download settings', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))));
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '更新下载设置失败');
    }
  }

  /**
   * 重置下载设置为默认�?   */
  public async resetDownloadSettings(): Promise<ApiResponse<DownloadSettings>> {
    try {
      this.settings = { ...DEFAULT_DOWNLOAD_SETTINGS };
      
      // 确保下载文件夹有�?      this.settings.downloadFolder = await FileUtil.getDownloadDirectory('RayTV');
      
      // 保存设置
      await StorageUtil.setObject(DOWNLOAD_SETTINGS_KEY, this.settings);
      
      Logger.info(TAG, 'Download settings reset to default');
      return ApiResponse.success(this.settings, '重置下载设置成功');
    } catch (error) {
      Logger.error(TAG, 'Failed to reset download settings', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))));
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '重置下载设置失败');
    }
  }
}


