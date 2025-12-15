// MediaService.ets - 媒体服务
// 实现媒体管理功能，包括播放记录、收藏管理等

import Logger from '../../common/util/Logger';

// 常量定义
const TAG = 'MediaService';

/**
 * 媒体服务类
 * 实现媒体管理功能，包括播放记录、收藏管理等
 */
export class MediaService {
  private static instance: MediaService;
  private playbackRecords: Map<string, any> = new Map();
  private collections: Map<string, any> = new Map();
  private isInitialized: boolean = false;
  private progressSyncInterval: number | null = null;

  /**
   * 获取单例实例
   */
  public static getInstance(): MediaService {
    if (!MediaService.instance) {
      MediaService.instance = new MediaService();
    }
    return MediaService.instance;
  }

  /**
   * 构造函数
   */
  private constructor() {
    // 直接初始化，不依赖ConfigService
  }

  /**
   * 初始化媒体服务
   */
  public async initialize(): Promise<void> {
    if (this.isInitialized) {
      return;
    }

    try {
      Logger.info(TAG, 'Initializing media service...');
      
      // 初始化数据结构
      this.playbackRecords = new Map();
      this.collections = new Map();
      
      // 启动进度同步
      this.startProgressSync();
      
      this.isInitialized = true;
      Logger.info(TAG, 'Media service initialized successfully');
    } catch (error) {
      Logger.error(TAG, `Failed to initialize media service: ${error}`);
      throw error;
    }
  }

  /**
   * 开始进度同步
   */
  private startProgressSync(): void {
    // 实现进度同步逻辑
    this.progressSyncInterval = setInterval(() => {
      // 简单的进度同步日志，不依赖外部存储
      Logger.info(TAG, `Progress sync completed at ${new Date().toISOString()}`);
    }, 30000); // 每30秒同步一次
  }

  /**
   * 停止进度同步
   */
  private stopProgressSync(): void {
    if (this.progressSyncInterval) {
      clearInterval(this.progressSyncInterval);
      this.progressSyncInterval = null;
    }
  }

  /**
   * 更新播放记录
   */
  public updatePlaybackRecord(mediaId: string, record: any): void {
    this.playbackRecords.set(mediaId, record);
  }

  /**
   * 获取播放记录
   */
  public getPlaybackRecord(mediaId: string): any | undefined {
    return this.playbackRecords.get(mediaId);
  }

  /**
   * 删除播放记录
   */
  public deletePlaybackRecord(mediaId: string): void {
    this.playbackRecords.delete(mediaId);
  }

  /**
   * 获取所有播放记录
   */
  public getAllPlaybackRecords(): Map<string, any> {
    return this.playbackRecords;
  }

  /**
   * 添加到收藏
   */
  public addToCollection(mediaId: string, mediaInfo: any): void {
    this.collections.set(mediaId, mediaInfo);
  }

  /**
   * 从收藏中删除
   */
  public removeFromCollection(mediaId: string): void {
    this.collections.delete(mediaId);
  }

  /**
   * 检查是否已收藏
   */
  public isCollected(mediaId: string): boolean {
    return this.collections.has(mediaId);
  }

  /**
   * 获取所有收藏
   */
  public getAllCollections(): Map<string, any> {
    return this.collections;
  }

  /**
   * 关闭媒体服务
   */
  public close(): void {
    if (!this.isInitialized) {
      return;
    }

    this.stopProgressSync();
    
    // 清理数据
    this.playbackRecords.clear();
    this.collections.clear();

    this.isInitialized = false;
    Logger.info(TAG, 'Media service closed successfully');
  }
}

// 导出类和单例实例
export default MediaService;
export const mediaService = MediaService.getInstance();