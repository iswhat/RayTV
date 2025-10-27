// DownloadService - 下载服务类
// 负责管理视频下载相关的业务逻辑，包括下载任务的创建、暂停、恢复、取消、查询等功能

import Logger from '../common/util/Logger';
import { EventBusUtil, GlobalEventType } from '../common/util/EventBusUtil';
import StorageUtil from '../common/util/StorageUtil';
import FileUtil from '../common/util/FileUtil';
import { ConfigRepository } from '../data/repository/ConfigRepository';
import { LocalStorageType, FileType, StorageDevice } from '../data/model/LocalModel';
import { LiveStream, LiveStreamQuality } from './LiveStreamService';

/**
 * 下载状态枚举
 */
export enum DownloadStatus {
  QUEUED = 'QUEUED',           // 队列中
  DOWNLOADING = 'DOWNLOADING', // 下载中
  PAUSED = 'PAUSED',           // 已暂停
  COMPLETED = 'COMPLETED',     // 已完成
  FAILED = 'FAILED',           // 失败
  CANCELLED = 'CANCELLED',     // 已取消
  VERIFYING = 'VERIFYING',     // 验证中
  EXTRACTING = 'EXTRACTING'    // 解压中
}

/**
 * 下载优先级枚举
 */
export enum DownloadPriority {
  LOW = 0,
  NORMAL = 1,
  HIGH = 2,
  URGENT = 3
}

/**
 * 下载错误类型枚举
 */
export enum DownloadErrorType {
  NETWORK_ERROR = 'NETWORK_ERROR',        // 网络错误
  STORAGE_ERROR = 'STORAGE_ERROR',        // 存储错误
  SERVER_ERROR = 'SERVER_ERROR',          // 服务器错误
  INVALID_URL = 'INVALID_URL',            // 无效URL
  FILE_NOT_FOUND = 'FILE_NOT_FOUND',      // 文件未找到
  DISK_FULL = 'DISK_FULL',                // 磁盘空间不足
  PERMISSION_DENIED = 'PERMISSION_DENIED', // 权限被拒绝
  CANCELLED = 'CANCELLED',                // 取消
  UNKNOWN_ERROR = 'UNKNOWN_ERROR'         // 未知错误
}

/**
 * 下载错误接口
 */
export interface DownloadError {
  type: DownloadErrorType;     // 错误类型
  message: string;             // 错误信息
  code?: number;               // 错误代码
  timestamp: number;           // 错误时间戳
  retryable: boolean;          // 是否可重试
}

/**
 * 下载任务接口
 */
export interface DownloadTask {
  id: string;                  // 任务ID
  streamId: string;            // 直播流ID
  title: string;               // 标题
  url: string;                 // 下载URL
  quality: LiveStreamQuality;  // 下载质量
  filePath: string;            // 本地文件路径
  fileSize: number;            // 文件大小（字节）
  downloadedBytes: number;     // 已下载字节数
  speed: number;               // 当前下载速度（字节/秒）
  estimatedTime: number;       // 预计剩余时间（秒）
  status: DownloadStatus;      // 下载状态
  priority: DownloadPriority;  // 优先级
  progress: number;            // 进度百分比（0-100）
  startTime: number;           // 开始时间戳
  endTime?: number;            // 结束时间戳
  error?: DownloadError;       // 错误信息
  metadata: {                  // 元数据
    thumbnailUrl?: string;     // 缩略图URL
    duration?: number;         // 时长（秒）
    codec?: string;            // 编码
    resolution?: string;       // 分辨率
    description?: string;      // 描述
    tags?: string[];           // 标签
    category?: string;         // 分类
  };
}

/**
 * 下载配置接口
 */
export interface DownloadConfig {
  maxConcurrentDownloads: number;  // 最大并发下载数
  maxRetryCount: number;           // 最大重试次数
  retryDelay: number;              // 重试延迟（毫秒）
  bufferSize: number;              // 缓冲区大小（字节）
  downloadDirectory: string;       // 下载目录
  autoResume: boolean;             // 自动恢复未完成的下载
  autoDeleteFailed: boolean;       // 自动删除失败的下载
  speedLimit?: number;             // 速度限制（字节/秒）
  useWifiOnly: boolean;            // 仅在WiFi下下载
  batteryLevelThreshold: number;   // 电池电量阈值（%）
  storageDeviceId?: string;        // 存储设备ID
}

/**
 * 下载统计接口
 */
export interface DownloadStatistics {
  totalDownloads: number;          // 总下载任务数
  completedDownloads: number;      // 已完成下载数
  failedDownloads: number;         // 失败下载数
  activeDownloads: number;         // 活跃下载数
  pausedDownloads: number;         // 暂停下载数
  totalDownloadSize: number;       // 总下载大小（字节）
  totalDownloadTime: number;       // 总下载时间（秒）
  averageSpeed: number;            // 平均下载速度（字节/秒）
  currentSpeed: number;            // 当前下载速度（字节/秒）
  storageUsed: number;             // 已使用存储空间（字节）
  storageAvailable: number;        // 可用存储空间（字节）
}

/**
 * 下载过滤器接口
 */
export interface DownloadFilter {
  status?: DownloadStatus | DownloadStatus[]; // 状态过滤
  quality?: LiveStreamQuality | LiveStreamQuality[]; // 质量过滤
  minProgress?: number;            // 最小进度
  maxProgress?: number;            // 最大进度
  searchTerm?: string;             // 搜索关键词
  sortBy?: 'startTime' | 'progress' | 'fileSize' | 'title'; // 排序字段
  sortOrder?: 'asc' | 'desc';      // 排序顺序
  limit?: number;                  // 限制数量
  offset?: number;                 // 偏移量
}

/**
 * 下载服务类
 */
export class DownloadService {
  private static instance: DownloadService;
  private logger = Logger.getInstance();
  private eventBus = EventBusUtil.getInstance();
  private storageUtil = StorageUtil.getInstance();
  private fileUtil = FileUtil.getInstance();
  private configRepository = ConfigRepository.getInstance();
  
  // 下载任务列表
  private tasks: Map<string, DownloadTask> = new Map();
  // 下载队列
  private queue: string[] = [];
  // 正在下载的任务ID列表
  private activeDownloads: string[] = [];
  // 下载配置
  private config: DownloadConfig = {
    maxConcurrentDownloads: 3,
    maxRetryCount: 3,
    retryDelay: 5000,
    bufferSize: 8192,
    downloadDirectory: '/storage/emulated/0/Download/RayTV',
    autoResume: true,
    autoDeleteFailed: false,
    useWifiOnly: true,
    batteryLevelThreshold: 20
  };
  // 下载统计
  private statistics: DownloadStatistics = {
    totalDownloads: 0,
    completedDownloads: 0,
    failedDownloads: 0,
    activeDownloads: 0,
    pausedDownloads: 0,
    totalDownloadSize: 0,
    totalDownloadTime: 0,
    averageSpeed: 0,
    currentSpeed: 0,
    storageUsed: 0,
    storageAvailable: 0
  };
  // 任务重试计数
  private retryCounts: Map<string, number> = new Map();
  // 下载速度计时器
  private speedTimers: Map<string, NodeJS.Timeout> = new Map();
  // 临时数据存储
  private tempData: Map<string, any> = new Map();

  /**
   * 私有构造函数
   */
  private constructor() {
    this.logger.info('DownloadService initialized');
    this.initialize();
  }

  /**
   * 获取DownloadService单例实例
   */
  public static getInstance(): DownloadService {
    if (!DownloadService.instance) {
      DownloadService.instance = new DownloadService();
    }
    return DownloadService.instance;
  }

  /**
   * 初始化服务
   */
  private async initialize(): Promise<void> {
    try {
      // 加载下载配置
      await this.loadConfig();
      
      // 确保下载目录存在
      await this.ensureDownloadDirectoryExists();
      
      // 加载下载任务
      await this.loadTasks();
      
      // 更新统计数据
      this.updateStatistics();
      
      // 初始化事件监听
      this.setupEventListeners();
      
      // 恢复未完成的下载（如果配置了自动恢复）
      if (this.config.autoResume) {
        this.resumePendingDownloads();
      }
      
      this.logger.info('DownloadService initialized successfully');
    } catch (error) {
      this.logger.error('Failed to initialize DownloadService', error as Error);
    }
  }

  /**
   * 设置事件监听器
   */
  private setupEventListeners(): void {
    // 监听网络状态变化
    this.eventBus.on(GlobalEventType.NETWORK_STATUS_CHANGE, (status) => {
      this.handleNetworkStatusChange(status);
    });
    
    // 监听配置变化
    this.eventBus.on(GlobalEventType.CONFIG_CHANGE, (config) => {
      if (config?.download) {
        this.updateConfig(config.download);
      }
    });
    
    // 监听应用暂停/恢复
    this.eventBus.on(GlobalEventType.APP_PAUSE, () => {
      this.handleAppPause();
    });
    
    this.eventBus.on(GlobalEventType.APP_RESUME, () => {
      this.handleAppResume();
    });
  }

  /**
   * 创建下载任务
   * @param stream 直播流信息
   * @param quality 下载质量
   * @param priority 优先级
   */
  public async createDownload(stream: LiveStream, quality: LiveStreamQuality = LiveStreamQuality.HIGH, priority: DownloadPriority = DownloadPriority.NORMAL): Promise<DownloadTask> {
    try {
      this.logger.debug(`Creating download for stream: ${stream.id}, quality: ${quality}`);
      
      // 检查是否已存在相同的下载任务
      const existingTask = this.findExistingTask(stream.id, quality);
      if (existingTask) {
        this.logger.warn(`Download task already exists for stream: ${stream.id}, quality: ${quality}`);
        return existingTask;
      }
      
      // 检查网络状态
      if (!await this.checkNetworkAndStorage()) {
        throw new Error('Network or storage conditions not met');
      }
      
      // 生成任务ID
      const taskId = `dl_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
      
      // 生成文件名和路径
      const fileName = this.generateFileName(stream, quality);
      const filePath = this.fileUtil.joinPath(this.config.downloadDirectory, fileName);
      
      // 获取下载URL
      const downloadUrl = await this.getDownloadUrl(stream, quality);
      
      // 创建下载任务
      const task: DownloadTask = {
        id: taskId,
        streamId: stream.id,
        title: stream.title,
        url: downloadUrl,
        quality,
        filePath,
        fileSize: 0, // 初始大小为0，将在下载开始时获取
        downloadedBytes: 0,
        speed: 0,
        estimatedTime: 0,
        status: DownloadStatus.QUEUED,
        priority,
        progress: 0,
        startTime: Date.now(),
        metadata: {
          thumbnailUrl: stream.thumbnailUrl,
          duration: stream.statistics?.duration || 0,
          resolution: this.getResolutionFromQuality(quality),
          description: stream.description,
          tags: stream.categories,
          category: stream.category
        }
      };
      
      // 添加到任务列表
      this.tasks.set(taskId, task);
      
      // 添加到下载队列
      this.addToQueue(taskId, priority);
      
      // 保存任务
      await this.saveTasks();
      
      // 更新统计数据
      this.updateStatistics();
      
      // 发布任务创建事件
      this.eventBus.emit('download:taskCreated', task);
      
      // 尝试开始下载
      this.processQueue();
      
      this.logger.info(`Download task created: ${taskId} for stream: ${stream.id}`);
      
      return task;
    } catch (error) {
      this.logger.error(`Failed to create download task for stream: ${stream.id}`, error as Error);
      throw error;
    }
  }

  /**
   * 批量创建下载任务
   * @param streams 直播流列表
   * @param quality 下载质量
   * @param priority 优先级
   */
  public async createBatchDownloads(streams: LiveStream[], quality: LiveStreamQuality = LiveStreamQuality.HIGH, priority: DownloadPriority = DownloadPriority.NORMAL): Promise<DownloadTask[]> {
    const createdTasks: DownloadTask[] = [];
    
    for (const stream of streams) {
      try {
        const task = await this.createDownload(stream, quality, priority);
        createdTasks.push(task);
      } catch (error) {
        this.logger.error(`Failed to create download for stream: ${stream.id}`, error as Error);
      }
    }
    
    // 尝试开始下载
    this.processQueue();
    
    return createdTasks;
  }

  /**
   * 开始下载任务
   * @param taskId 任务ID
   */
  public async startDownload(taskId: string): Promise<void> {
    try {
      const task = this.tasks.get(taskId);
      if (!task) {
        throw new Error(`Task not found: ${taskId}`);
      }
      
      this.logger.debug(`Starting download task: ${taskId}`);
      
      // 检查任务状态
      if (task.status === DownloadStatus.COMPLETED) {
        throw new Error('Task already completed');
      }
      
      if (task.status === DownloadStatus.DOWNLOADING) {
        this.logger.warn(`Task already downloading: ${taskId}`);
        return;
      }
      
      // 更新任务状态
      task.status = DownloadStatus.QUEUED;
      
      // 重置错误信息
      delete task.error;
      
      // 添加到队列
      this.addToQueue(taskId, task.priority);
      
      // 保存任务
      await this.saveTasks();
      
      // 更新统计数据
      this.updateStatistics();
      
      // 发布任务状态变化事件
      this.eventBus.emit('download:taskStatusChanged', task);
      
      // 尝试开始下载
      this.processQueue();
      
      this.logger.info(`Download task started: ${taskId}`);
    } catch (error) {
      this.logger.error(`Failed to start download task: ${taskId}`, error as Error);
      throw error;
    }
  }

  /**
   * 暂停下载任务
   * @param taskId 任务ID
   */
  public async pauseDownload(taskId: string): Promise<void> {
    try {
      const task = this.tasks.get(taskId);
      if (!task) {
        throw new Error(`Task not found: ${taskId}`);
      }
      
      this.logger.debug(`Pausing download task: ${taskId}`);
      
      // 检查任务状态
      if (task.status !== DownloadStatus.DOWNLOADING && task.status !== DownloadStatus.QUEUED) {
        this.logger.warn(`Cannot pause task: ${taskId}, current status: ${task.status}`);
        return;
      }
      
      // 从队列中移除
      this.removeFromQueue(taskId);
      
      // 停止实际下载过程
      await this.cancelDownloadInternal(taskId);
      
      // 更新任务状态
      task.status = DownloadStatus.PAUSED;
      task.speed = 0;
      
      // 停止速度计时器
      this.stopSpeedTimer(taskId);
      
      // 保存任务
      await this.saveTasks();
      
      // 更新统计数据
      this.updateStatistics();
      
      // 发布任务状态变化事件
      this.eventBus.emit('download:taskStatusChanged', task);
      
      // 尝试开始队列中的下一个任务
      this.processQueue();
      
      this.logger.info(`Download task paused: ${taskId}`);
    } catch (error) {
      this.logger.error(`Failed to pause download task: ${taskId}`, error as Error);
      throw error;
    }
  }

  /**
   * 暂停所有下载任务
   */
  public async pauseAllDownloads(): Promise<void> {
    const activeTaskIds = [...this.activeDownloads];
    const queuedTaskIds = [...this.queue];
    
    // 暂停所有活跃的下载
    for (const taskId of activeTaskIds) {
      try {
        await this.pauseDownload(taskId);
      } catch (error) {
        this.logger.error(`Failed to pause task: ${taskId}`, error as Error);
      }
    }
    
    // 暂停所有队列中的任务
    for (const taskId of queuedTaskIds) {
      try {
        await this.pauseDownload(taskId);
      } catch (error) {
        this.logger.error(`Failed to pause task: ${taskId}`, error as Error);
      }
    }
    
    this.logger.info(`All downloads paused`);
  }

  /**
   * 恢复下载任务
   * @param taskId 任务ID
   */
  public async resumeDownload(taskId: string): Promise<void> {
    try {
      const task = this.tasks.get(taskId);
      if (!task) {
        throw new Error(`Task not found: ${taskId}`);
      }
      
      this.logger.debug(`Resuming download task: ${taskId}`);
      
      // 检查任务状态
      if (task.status !== DownloadStatus.PAUSED) {
        this.logger.warn(`Cannot resume task: ${taskId}, current status: ${task.status}`);
        return;
      }
      
      // 更新任务状态
      task.status = DownloadStatus.QUEUED;
      
      // 添加到队列
      this.addToQueue(taskId, task.priority);
      
      // 保存任务
      await this.saveTasks();
      
      // 更新统计数据
      this.updateStatistics();
      
      // 发布任务状态变化事件
      this.eventBus.emit('download:taskStatusChanged', task);
      
      // 尝试开始下载
      this.processQueue();
      
      this.logger.info(`Download task resumed: ${taskId}`);
    } catch (error) {
      this.logger.error(`Failed to resume download task: ${taskId}`, error as Error);
      throw error;
    }
  }

  /**
   * 取消下载任务
   * @param taskId 任务ID
   * @param deleteFile 是否删除已下载的文件
   */
  public async cancelDownload(taskId: string, deleteFile: boolean = true): Promise<void> {
    try {
      const task = this.tasks.get(taskId);
      if (!task) {
        throw new Error(`Task not found: ${taskId}`);
      }
      
      this.logger.debug(`Cancelling download task: ${taskId}, deleteFile: ${deleteFile}`);
      
      // 从队列中移除
      this.removeFromQueue(taskId);
      
      // 停止实际下载过程
      await this.cancelDownloadInternal(taskId);
      
      // 更新任务状态
      task.status = DownloadStatus.CANCELLED;
      task.speed = 0;
      task.endTime = Date.now();
      
      // 停止速度计时器
      this.stopSpeedTimer(taskId);
      
      // 删除文件（如果需要）
      if (deleteFile && task.filePath) {
        try {
          await this.fileUtil.deleteFile(task.filePath);
          this.logger.debug(`Deleted partially downloaded file: ${task.filePath}`);
        } catch (error) {
          this.logger.error(`Failed to delete file: ${task.filePath}`, error as Error);
        }
      }
      
      // 保存任务
      await this.saveTasks();
      
      // 更新统计数据
      this.updateStatistics();
      
      // 发布任务状态变化事件
      this.eventBus.emit('download:taskCancelled', task);
      
      // 尝试开始队列中的下一个任务
      this.processQueue();
      
      this.logger.info(`Download task cancelled: ${taskId}`);
    } catch (error) {
      this.logger.error(`Failed to cancel download task: ${taskId}`, error as Error);
      throw error;
    }
  }

  /**
   * 删除下载任务
   * @param taskId 任务ID
   * @param deleteFile 是否删除文件
   */
  public async deleteDownload(taskId: string, deleteFile: boolean = true): Promise<void> {
    try {
      const task = this.tasks.get(taskId);
      if (!task) {
        throw new Error(`Task not found: ${taskId}`);
      }
      
      this.logger.debug(`Deleting download task: ${taskId}, deleteFile: ${deleteFile}`);
      
      // 如果任务正在下载，先取消
      if (task.status === DownloadStatus.DOWNLOADING || task.status === DownloadStatus.QUEUED) {
        await this.cancelDownload(taskId, deleteFile);
      } else if (deleteFile && task.filePath) {
        try {
          await this.fileUtil.deleteFile(task.filePath);
          this.logger.debug(`Deleted downloaded file: ${task.filePath}`);
        } catch (error) {
          this.logger.error(`Failed to delete file: ${task.filePath}`, error as Error);
        }
      }
      
      // 从任务列表中移除
      this.tasks.delete(taskId);
      
      // 清理相关数据
      this.retryCounts.delete(taskId);
      this.stopSpeedTimer(taskId);
      this.tempData.delete(taskId);
      
      // 保存任务列表
      await this.saveTasks();
      
      // 更新统计数据
      this.updateStatistics();
      
      // 发布任务删除事件
      this.eventBus.emit('download:taskDeleted', { taskId });
      
      this.logger.info(`Download task deleted: ${taskId}`);
    } catch (error) {
      this.logger.error(`Failed to delete download task: ${taskId}`, error as Error);
      throw error;
    }
  }

  /**
   * 批量删除下载任务
   * @param taskIds 任务ID列表
   * @param deleteFiles 是否删除文件
   */
  public async deleteDownloads(taskIds: string[], deleteFiles: boolean = true): Promise<void> {
    for (const taskId of taskIds) {
      try {
        await this.deleteDownload(taskId, deleteFiles);
      } catch (error) {
        this.logger.error(`Failed to delete task: ${taskId}`, error as Error);
      }
    }
  }

  /**
   * 获取下载任务
   * @param taskId 任务ID
   */
  public getTask(taskId: string): DownloadTask | undefined {
    return this.tasks.get(taskId);
  }

  /**
   * 获取所有下载任务
   */
  public getAllTasks(): DownloadTask[] {
    return Array.from(this.tasks.values());
  }

  /**
   * 根据过滤器获取下载任务
   * @param filter 过滤条件
   */
  public getTasksByFilter(filter: DownloadFilter): DownloadTask[] {
    let tasks = Array.from(this.tasks.values());
    
    // 应用过滤条件
    if (filter.status) {
      const statuses = Array.isArray(filter.status) ? filter.status : [filter.status];
      tasks = tasks.filter(task => statuses.includes(task.status));
    }
    
    if (filter.quality) {
      const qualities = Array.isArray(filter.quality) ? filter.quality : [filter.quality];
      tasks = tasks.filter(task => qualities.includes(task.quality));
    }
    
    if (filter.minProgress !== undefined) {
      tasks = tasks.filter(task => task.progress >= filter.minProgress!);
    }
    
    if (filter.maxProgress !== undefined) {
      tasks = tasks.filter(task => task.progress <= filter.maxProgress!);
    }
    
    if (filter.searchTerm) {
      const term = filter.searchTerm.toLowerCase();
      tasks = tasks.filter(task => 
        task.title.toLowerCase().includes(term) ||
        task.metadata.description?.toLowerCase().includes(term) ||
        task.metadata.tags?.some(tag => tag.toLowerCase().includes(term))
      );
    }
    
    // 应用排序
    if (filter.sortBy) {
      tasks.sort((a, b) => {
        let aValue: any = a[filter.sortBy!];
        let bValue: any = b[filter.sortBy!];
        
        // 处理特殊情况
        if (filter.sortBy === 'title') {
          return aValue.localeCompare(bValue);
        }
        
        // 处理数字比较
        if (filter.sortOrder === 'asc') {
          return aValue - bValue;
        } else {
          return bValue - aValue;
        }
      });
    }
    
    // 应用分页
    if (filter.offset !== undefined) {
      tasks = tasks.slice(filter.offset);
    }
    
    if (filter.limit !== undefined) {
      tasks = tasks.slice(0, filter.limit);
    }
    
    return tasks;
  }

  /**
   * 获取下载统计数据
   */
  public getStatistics(): DownloadStatistics {
    return { ...this.statistics };
  }

  /**
   * 更新下载配置
   * @param newConfig 新配置
   */
  public async updateConfig(newConfig: Partial<DownloadConfig>): Promise<void> {
    try {
      this.logger.debug('Updating download config:', newConfig);
      
      // 合并配置
      this.config = { ...this.config, ...newConfig };
      
      // 如果下载目录改变，确保新目录存在
      if (newConfig.downloadDirectory) {
        await this.ensureDownloadDirectoryExists();
      }
      
      // 保存配置
      await this.saveConfig();
      
      // 更新统计数据（存储相关）
      await this.updateStorageStatistics();
      
      // 根据新配置调整下载行为
      this.adjustDownloadsBasedOnConfig();
      
      this.logger.info('Download config updated successfully');
    } catch (error) {
      this.logger.error('Failed to update download config', error as Error);
      throw error;
    }
  }

  /**
   * 获取下载配置
   */
  public getConfig(): DownloadConfig {
    return { ...this.config };
  }

  /**
   * 检查任务是否可下载
   * @param stream 直播流
   * @param quality 质量
   */
  public async checkDownloadable(stream: LiveStream, quality: LiveStreamQuality = LiveStreamQuality.HIGH): Promise<{ downloadable: boolean; reason?: string }> {
    try {
      // 检查网络和存储条件
      if (!await this.checkNetworkAndStorage()) {
        return { downloadable: false, reason: '网络或存储条件不满足' };
      }
      
      // 检查是否已存在相同的下载
      const existingTask = this.findExistingTask(stream.id, quality);
      if (existingTask && existingTask.status === DownloadStatus.COMPLETED) {
        return { downloadable: false, reason: '已存在相同的下载' };
      }
      
      // 检查直播流是否支持下载
      if (!stream.downloadable) {
        return { downloadable: false, reason: '该直播流不支持下载' };
      }
      
      // 检查存储空间是否充足（预估）
      const estimatedSize = stream.statistics?.fileSize || 0;
      if (estimatedSize > 0 && this.statistics.storageAvailable < estimatedSize) {
        return { downloadable: false, reason: '存储空间不足' };
      }
      
      return { downloadable: true };
    } catch (error) {
      this.logger.error('Failed to check downloadability', error as Error);
      return { downloadable: false, reason: '检查失败' };
    }
  }

  // 私有辅助方法

  /**
   * 将任务添加到队列
   * @param taskId 任务ID
   * @param priority 优先级
   */
  private addToQueue(taskId: string, priority: DownloadPriority): void {
    // 检查是否已在队列中
    if (this.queue.includes(taskId)) {
      return;
    }
    
    // 根据优先级插入到适当位置
    let inserted = false;
    for (let i = 0; i < this.queue.length; i++) {
      const queuedTask = this.tasks.get(this.queue[i]);
      if (queuedTask && priority > queuedTask.priority) {
        this.queue.splice(i, 0, taskId);
        inserted = true;
        break;
      }
    }
    
    // 如果没有插入，添加到队列末尾
    if (!inserted) {
      this.queue.push(taskId);
    }
    
    this.logger.debug(`Task ${taskId} added to queue with priority: ${priority}`);
  }

  /**
   * 从队列中移除任务
   * @param taskId 任务ID
   */
  private removeFromQueue(taskId: string): void {
    const index = this.queue.indexOf(taskId);
    if (index > -1) {
      this.queue.splice(index, 1);
      this.logger.debug(`Task ${taskId} removed from queue`);
    }
  }

  /**
   * 从活跃下载列表中移除任务
   * @param taskId 任务ID
   */
  private removeFromActiveDownloads(taskId: string): void {
    const index = this.activeDownloads.indexOf(taskId);
    if (index > -1) {
      this.activeDownloads.splice(index, 1);
      this.logger.debug(`Task ${taskId} removed from active downloads`);
    }
  }

  /**
   * 处理下载队列
   */
  private async processQueue(): Promise<void> {
    // 检查是否有空闲下载槽位
    const availableSlots = this.config.maxConcurrentDownloads - this.activeDownloads.length;
    
    if (availableSlots <= 0) {
      this.logger.debug('No available download slots');
      return;
    }
    
    // 检查网络和存储条件
    if (!await this.checkNetworkAndStorage()) {
      this.logger.debug('Network or storage conditions not met, cannot start new downloads');
      return;
    }
    
    // 启动队列中的任务
    let startedTasks = 0;
    
    while (this.queue.length > 0 && startedTasks < availableSlots) {
      const taskId = this.queue.shift();
      if (taskId) {
        try {
          await this.startDownloadInternal(taskId);
          startedTasks++;
        } catch (error) {
          this.logger.error(`Failed to start task from queue: ${taskId}`, error as Error);
        }
      }
    }
  }

  /**
   * 内部开始下载方法
   * @param taskId 任务ID
   */
  private async startDownloadInternal(taskId: string): Promise<void> {
    const task = this.tasks.get(taskId);
    if (!task) {
      throw new Error(`Task not found: ${taskId}`);
    }
    
    try {
      // 更新任务状态
      task.status = DownloadStatus.DOWNLOADING;
      
      // 添加到活跃下载列表
      this.activeDownloads.push(taskId);
      
      // 重置重试计数
      this.retryCounts.set(taskId, 0);
      
      // 保存任务
      await this.saveTasks();
      
      // 更新统计数据
      this.updateStatistics();
      
      // 发布任务状态变化事件
      this.eventBus.emit('download:taskStatusChanged', task);
      
      // 开始速度计时
      this.startSpeedTimer(taskId);
      
      // 开始实际下载过程（模拟）
      await this.downloadFile(taskId);
    } catch (error) {
      this.handleDownloadError(taskId, error as Error);
    }
  }

  /**
   * 内部取消下载方法
   * @param taskId 任务ID
   */
  private async cancelDownloadInternal(taskId: string): Promise<void> {
    // 这里应该停止实际的下载过程
    // 在实际应用中，需要取消正在进行的网络请求
    
    // 从活跃下载列表中移除
    this.removeFromActiveDownloads(taskId);
    
    // 停止速度计时器
    this.stopSpeedTimer(taskId);
  }

  /**
   * 模拟下载文件过程
   * @param taskId 任务ID
   */
  private async downloadFile(taskId: string): Promise<void> {
    const task = this.tasks.get(taskId);
    if (!task) {
      return;
    }
    
    try {
      // 模拟下载过程
      this.logger.debug(`Starting download for task: ${taskId}`);
      
      // 模拟获取文件大小
      if (task.fileSize === 0) {
        task.fileSize = this.simulateFileSize(task.quality);
      }
      
      // 模拟下载进度
      const chunkSize = 1024 * 1024; // 1MB chunks
      const interval = 1000; // 每秒更新一次
      
      // 模拟下载循环
      const downloadInterval = setInterval(async () => {
        if (!task || task.status !== DownloadStatus.DOWNLOADING) {
          clearInterval(downloadInterval);
          return;
        }
        
        // 模拟下载速度（根据网络质量）
        const simulatedSpeed = this.simulateDownloadSpeed();
        const bytesToAdd = simulatedSpeed / 10; // 因为是每秒10次更新
        
        task.downloadedBytes += bytesToAdd;
        task.speed = simulatedSpeed;
        
        // 计算进度
        if (task.fileSize > 0) {
          task.progress = Math.min(100, Math.round((task.downloadedBytes / task.fileSize) * 100));
        }
        
        // 计算预计时间
        if (simulatedSpeed > 0 && task.fileSize > task.downloadedBytes) {
          task.estimatedTime = Math.round((task.fileSize - task.downloadedBytes) / simulatedSpeed);
        }
        
        // 检查是否下载完成
        if (task.downloadedBytes >= task.fileSize) {
          clearInterval(downloadInterval);
          
          // 更新任务状态
          task.downloadedBytes = task.fileSize;
          task.progress = 100;
          task.status = DownloadStatus.COMPLETED;
          task.endTime = Date.now();
          task.speed = 0;
          task.estimatedTime = 0;
          
          // 清理资源
          this.removeFromActiveDownloads(taskId);
          this.stopSpeedTimer(taskId);
          
          // 保存任务
          await this.saveTasks();
          
          // 更新统计数据
          this.updateStatistics();
          
          // 发布下载完成事件
          this.eventBus.emit('download:taskCompleted', task);
          
          this.logger.info(`Download completed for task: ${taskId}`);
          
          // 继续处理队列
          this.processQueue();
        }
        
        // 定期保存进度
        if (Math.random() > 0.7) { // 30%的概率保存，避免频繁IO
          await this.saveTasks();
        }
        
        // 发布进度更新事件
        this.eventBus.emit('download:taskProgress', task);
      }, interval / 10); // 更频繁地更新以获得更平滑的进度
      
      // 存储interval ID以便后续取消
      this.tempData.set(`interval_${taskId}`, downloadInterval);
    } catch (error) {
      this.handleDownloadError(taskId, error as Error);
    }
  }

  /**
   * 处理下载错误
   * @param taskId 任务ID
   * @param error 错误对象
   */
  private async handleDownloadError(taskId: string, error: Error): Promise<void> {
    const task = this.tasks.get(taskId);
    if (!task) {
      return;
    }
    
    // 获取重试计数
    const retryCount = (this.retryCounts.get(taskId) || 0) + 1;
    this.retryCounts.set(taskId, retryCount);
    
    // 清理资源
    this.removeFromActiveDownloads(taskId);
    this.stopSpeedTimer(taskId);
    
    // 检查是否可以重试
    if (retryCount <= this.config.maxRetryCount) {
      this.logger.warn(`Download failed for task: ${taskId}, retrying (${retryCount}/${this.config.maxRetryCount})`, error);
      
      // 更新任务错误信息
      task.error = {
        type: DownloadErrorType.NETWORK_ERROR,
        message: error.message,
        timestamp: Date.now(),
        retryable: true
      };
      
      // 等待延迟后重试
      setTimeout(async () => {
        // 检查任务是否仍然存在并且状态没有改变
        const currentTask = this.tasks.get(taskId);
        if (currentTask && currentTask.status === DownloadStatus.DOWNLOADING) {
          currentTask.status = DownloadStatus.QUEUED;
          this.addToQueue(taskId, currentTask.priority);
          await this.saveTasks();
          this.processQueue();
        }
      }, this.config.retryDelay);
    } else {
      this.logger.error(`Download failed for task: ${taskId}, max retries reached`, error);
      
      // 更新任务状态为失败
      task.status = DownloadStatus.FAILED;
      task.endTime = Date.now();
      task.speed = 0;
      
      // 更新错误信息
      task.error = {
        type: DownloadErrorType.NETWORK_ERROR,
        message: error.message,
        timestamp: Date.now(),
        retryable: false
      };
      
      // 保存任务
      await this.saveTasks();
      
      // 更新统计数据
      this.updateStatistics();
      
      // 发布错误事件
      this.eventBus.emit('download:taskFailed', task);
      
      // 自动删除失败的下载（如果配置了）
      if (this.config.autoDeleteFailed) {
        await this.deleteDownload(taskId, true);
      }
      
      // 继续处理队列
      this.processQueue();
    }
  }

  /**
   * 开始速度计时器
   * @param taskId 任务ID
   */
  private startSpeedTimer(taskId: string): void {
    this.stopSpeedTimer(taskId);
    
    // 每5秒重置一次速度统计
    const timer = setInterval(() => {
      const task = this.tasks.get(taskId);
      if (task && task.status === DownloadStatus.DOWNLOADING) {
        // 速度会在下载过程中实时更新
      }
    }, 5000);
    
    this.speedTimers.set(taskId, timer);
  }

  /**
   * 停止速度计时器
   * @param taskId 任务ID
   */
  private stopSpeedTimer(taskId: string): void {
    const timer = this.speedTimers.get(taskId);
    if (timer) {
      clearInterval(timer);
      this.speedTimers.delete(taskId);
    }
    
    // 清理临时interval
    const downloadInterval = this.tempData.get(`interval_${taskId}`);
    if (downloadInterval) {
      clearInterval(downloadInterval);
      this.tempData.delete(`interval_${taskId}`);
    }
  }

  /**
   * 恢复未完成的下载
   */
  private resumePendingDownloads(): void {
    const pendingTasks = this.tasks.values().filter(task => 
      task.status === DownloadStatus.PAUSED ||
      task.status === DownloadStatus.FAILED
    );
    
    for (const task of pendingTasks) {
      if (task.status === DownloadStatus.PAUSED) {
        this.addToQueue(task.id, task.priority);
      }
    }
    
    // 处理队列
    this.processQueue();
    
    this.logger.info(`Resumed ${pendingTasks.length} pending downloads`);
  }

  /**
   * 确保下载目录存在
   */
  private async ensureDownloadDirectoryExists(): Promise<void> {
    try {
      await this.fileUtil.ensureDirectoryExists(this.config.downloadDirectory);
      this.logger.debug(`Download directory ensured: ${this.config.downloadDirectory}`);
    } catch (error) {
      this.logger.error(`Failed to create download directory: ${this.config.downloadDirectory}`, error as Error);
      throw error;
    }
  }

  /**
   * 加载下载配置
   */
  private async loadConfig(): Promise<void> {
    try {
      // 尝试从配置仓库加载
      const config = await this.configRepository.getConfig<DownloadConfig>('download');
      if (config) {
        this.config = { ...this.config, ...config };
      }
      
      // 尝试从本地存储加载（兼容性）
      const legacyConfig = await this.storageUtil.get<DownloadConfig>('download_config', LocalStorageType.PERSISTENT);
      if (legacyConfig) {
        this.config = { ...this.config, ...legacyConfig };
      }
      
      this.logger.info('Download config loaded successfully');
    } catch (error) {
      this.logger.error('Failed to load download config', error as Error);
    }
  }

  /**
   * 保存下载配置
   */
  private async saveConfig(): Promise<void> {
    try {
      // 保存到配置仓库
      await this.configRepository.setConfig('download', this.config);
      
      // 保存到本地存储（兼容性）
      await this.storageUtil.set('download_config', this.config, LocalStorageType.PERSISTENT);
      
      this.logger.debug('Download config saved');
    } catch (error) {
      this.logger.error('Failed to save download config', error as Error);
    }
  }

  /**
   * 加载下载任务
   */
  private async loadTasks(): Promise<void> {
    try {
      const tasksData = await this.storageUtil.get<Record<string, DownloadTask>>('download_tasks', LocalStorageType.PERSISTENT) || {};
      this.tasks = new Map(Object.entries(tasksData));
      
      this.logger.info(`Loaded ${this.tasks.size} download tasks`);
    } catch (error) {
      this.logger.error('Failed to load download tasks', error as Error);
      this.tasks = new Map();
    }
  }

  /**
   * 保存下载任务
   */
  private async saveTasks(): Promise<void> {
    try {
      const tasksData = Object.fromEntries(this.tasks);
      await this.storageUtil.set('download_tasks', tasksData, LocalStorageType.PERSISTENT);
      
      this.logger.debug(`Saved ${this.tasks.size} download tasks`);
    } catch (error) {
      this.logger.error('Failed to save download tasks', error as Error);
    }
  }

  /**
   * 更新统计数据
   */
  private updateStatistics(): void {
    const tasks = Array.from(this.tasks.values());
    
    this.statistics = {
      totalDownloads: tasks.length,
      completedDownloads: tasks.filter(t => t.status === DownloadStatus.COMPLETED).length,
      failedDownloads: tasks.filter(t => t.status === DownloadStatus.FAILED).length,
      activeDownloads: this.activeDownloads.length,
      pausedDownloads: tasks.filter(t => t.status === DownloadStatus.PAUSED).length,
      totalDownloadSize: tasks.reduce((sum, t) => sum + t.fileSize, 0),
      totalDownloadTime: tasks.reduce((sum, t) => {
        if (t.endTime && t.startTime) {
          return sum + (t.endTime - t.startTime);
        }
        if (t.status === DownloadStatus.DOWNLOADING && t.startTime) {
          return sum + (Date.now() - t.startTime);
        }
        return sum;
      }, 0) / 1000, // 转换为秒
      averageSpeed: this.calculateAverageSpeed(),
      currentSpeed: this.calculateCurrentSpeed(),
      storageUsed: this.statistics.storageUsed,
      storageAvailable: this.statistics.storageAvailable
    };
    
    // 发布统计数据更新事件
    this.eventBus.emit('download:statisticsUpdated', this.statistics);
  }

  /**
   * 更新存储统计数据
   */
  private async updateStorageStatistics(): Promise<void> {
    try {
      // 在实际应用中，这里应该调用系统API获取存储空间信息
      // 这里模拟获取存储信息
      const storageInfo = await this.simulateStorageInfo();
      
      this.statistics.storageUsed = storageInfo.used;
      this.statistics.storageAvailable = storageInfo.available;
      
      // 发布统计数据更新事件
      this.eventBus.emit('download:statisticsUpdated', this.statistics);
    } catch (error) {
      this.logger.error('Failed to update storage statistics', error as Error);
    }
  }

  /**
   * 计算平均下载速度
   */
  private calculateAverageSpeed(): number {
    const activeTasks = this.activeDownloads.map(id => this.tasks.get(id)).filter(Boolean) as DownloadTask[];
    if (activeTasks.length === 0) {
      return 0;
    }
    
    const totalSpeed = activeTasks.reduce((sum, task) => sum + task.speed, 0);
    return totalSpeed / activeTasks.length;
  }

  /**
   * 计算当前总下载速度
   */
  private calculateCurrentSpeed(): number {
    const activeTasks = this.activeDownloads.map(id => this.tasks.get(id)).filter(Boolean) as DownloadTask[];
    return activeTasks.reduce((sum, task) => sum + task.speed, 0);
  }

  /**
   * 检查网络和存储条件
   */
  private async checkNetworkAndStorage(): Promise<boolean> {
    try {
      // 检查网络状态（在实际应用中应该调用真实的网络检测API）
      const isNetworkAvailable = await this.simulateNetworkCheck();
      if (!isNetworkAvailable) {
        return false;
      }
      
      // 如果配置为仅WiFi，检查是否在WiFi下（模拟）
      if (this.config.useWifiOnly && !await this.simulateIsWifiConnected()) {
        return false;
      }
      
      // 检查存储空间
      await this.updateStorageStatistics();
      if (this.statistics.storageAvailable < 100 * 1024 * 1024) { // 至少需要100MB可用空间
        return false;
      }
      
      return true;
    } catch (error) {
      this.logger.error('Failed to check network and storage conditions', error as Error);
      return false;
    }
  }

  /**
   * 查找已存在的相同任务
   */
  private findExistingTask(streamId: string, quality: LiveStreamQuality): DownloadTask | undefined {
    return Array.from(this.tasks.values()).find(task => 
      task.streamId === streamId && 
      task.quality === quality &&
      task.status !== DownloadStatus.CANCELLED
    );
  }

  /**
   * 生成文件名
   */
  private generateFileName(stream: LiveStream, quality: LiveStreamQuality): string {
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const qualitySuffix = this.getQualitySuffix(quality);
    const safeTitle = stream.title.replace(/[^a-zA-Z0-9\u4e00-\u9fa5]/g, '_');
    return `${safeTitle}_${stream.id}_${timestamp}_${qualitySuffix}.mp4`;
  }

  /**
   * 获取下载URL
   */
  private async getDownloadUrl(stream: LiveStream, quality: LiveStreamQuality): Promise<string> {
    // 在实际应用中，这里应该调用API获取真实的下载URL
    // 这里模拟返回一个URL
    return `https://api.raytv.com/download/${stream.id}?quality=${quality}`;
  }

  /**
   * 获取质量后缀
   */
  private getQualitySuffix(quality: LiveStreamQuality): string {
    switch (quality) {
      case LiveStreamQuality.LOW:
        return '360p';
      case LiveStreamQuality.MEDIUM:
        return '480p';
      case LiveStreamQuality.HIGH:
        return '720p';
      case LiveStreamQuality.FULL_HD:
        return '1080p';
      case LiveStreamQuality.UHD:
        return '4k';
      default:
        return 'sd';
    }
  }

  /**
   * 根据质量获取分辨率
   */
  private getResolutionFromQuality(quality: LiveStreamQuality): string {
    switch (quality) {
      case LiveStreamQuality.LOW:
        return '640x360';
      case LiveStreamQuality.MEDIUM:
        return '854x480';
      case LiveStreamQuality.HIGH:
        return '1280x720';
      case LiveStreamQuality.FULL_HD:
        return '1920x1080';
      case LiveStreamQuality.UHD:
        return '3840x2160';
      default:
        return '640x360';
    }
  }

  /**
   * 根据配置调整下载行为
   */
  private adjustDownloadsBasedOnConfig(): void {
    // 检查并发下载数配置
    if (this.activeDownloads.length > this.config.maxConcurrentDownloads) {
      // 需要暂停一些任务
      const excessCount = this.activeDownloads.length - this.config.maxConcurrentDownloads;
      for (let i = 0; i < excessCount && this.activeDownloads.length > 0; i++) {
        const taskId = this.activeDownloads[this.activeDownloads.length - 1];
        this.pauseDownload(taskId).catch(error => {
          this.logger.error(`Failed to pause task when adjusting for config: ${taskId}`, error as Error);
        });
      }
    }
    
    // 检查WiFi-only配置
    if (this.config.useWifiOnly) {
      // 在实际应用中，这里应该检查网络类型并调整
    }
  }

  /**
   * 处理网络状态变化
   */
  private async handleNetworkStatusChange(status: any): Promise<void> {
    this.logger.debug('Network status changed:', status);
    
    if (status === 'offline') {
      // 网络断开，暂停所有下载
      await this.pauseAllDownloads();
    } else if (status === 'online') {
      // 网络恢复，尝试恢复下载
      if (this.config.autoResume) {
        this.resumePendingDownloads();
      }
    }
  }

  /**
   * 处理应用暂停
   */
  private async handleAppPause(): Promise<void> {
    this.logger.debug('App paused, pausing all downloads');
    
    // 暂停所有下载
    await this.pauseAllDownloads();
  }

  /**
   * 处理应用恢复
   */
  private handleAppResume(): Promise<void> {
    this.logger.debug('App resumed, checking download conditions');
    
    // 检查条件并尝试恢复下载
    this.checkNetworkAndStorage().then(canDownload => {
      if (canDownload && this.config.autoResume) {
        this.resumePendingDownloads();
      }
    });
    
    return Promise.resolve();
  }

  // 模拟方法

  /**
   * 模拟网络检查
   */
  private async simulateNetworkCheck(): Promise<boolean> {
    // 模拟网络检查，95%的概率返回true
    return new Promise(resolve => {
      setTimeout(() => resolve(Math.random() > 0.05), 100);
    });
  }

  /**
   * 模拟WiFi连接检查
   */
  private async simulateIsWifiConnected(): Promise<boolean> {
    // 模拟WiFi连接，80%的概率返回true
    return new Promise(resolve => {
      setTimeout(() => resolve(Math.random() > 0.2), 50);
    });
  }

  /**
   * 模拟存储信息
   */
  private async simulateStorageInfo(): Promise<{ used: number; available: number }> {
    // 模拟存储信息，假设总空间为100GB
    const totalSpace = 100 * 1024 * 1024 * 1024;
    const used = Math.floor(totalSpace * 0.6); // 已使用60%
    const available = totalSpace - used;
    
    return { used, available };
  }

  /**
   * 模拟文件大小
   */
  private simulateFileSize(quality: LiveStreamQuality): number {
    // 根据质量模拟文件大小
    const baseSize = 100 * 1024 * 1024; // 100MB基础大小
    
    switch (quality) {
      case LiveStreamQuality.LOW:
        return baseSize * 0.3;
      case LiveStreamQuality.MEDIUM:
        return baseSize * 0.5;
      case LiveStreamQuality.HIGH:
        return baseSize;
      case LiveStreamQuality.FULL_HD:
        return baseSize * 2;
      case LiveStreamQuality.UHD:
        return baseSize * 5;
      default:
        return baseSize;
    }
  }

  /**
   * 模拟下载速度
   */
  private simulateDownloadSpeed(): number {
    // 模拟下载速度，范围在50KB/s到5MB/s之间
    const minSpeed = 50 * 1024;
    const maxSpeed = 5 * 1024 * 1024;
    return minSpeed + Math.random() * (maxSpeed - minSpeed);
  }
}

// 导出默认实例
export default DownloadService.getInstance();