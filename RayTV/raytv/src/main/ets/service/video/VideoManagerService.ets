// 视频管理服务
// 管理视频播放、缓存和历史记录

import { StorageUtil, StorageType } from '../../common/util/StorageUtil';
import { UserService } from '../UserService';
import { CommonUtil } from '../../common/util/CommonUtil';

/**
 * 视频播放记录接口
 */
export interface VideoPlayHistory {
  /** 视频ID */
  videoId: string;
  /** 视频标题 */
  title: string;
  /** 封面URL */
  cover?: string;
  /** 当前播放位置（秒） */
  position: number;
  /** 视频总时长（秒） */
  duration: number;
  /** 最后播放时间 */
  lastPlayTime: string;
  /** 播放进度百分比 */
  progress?: number;
  /** 视频类型 */
  type?: 'movie' | 'series' | 'live';
  /** 剧集信息（如果是剧集） */
  episode?: {
    /** 剧集ID */
    id?: string;
    /** 剧集名称 */
    name?: string;
    /** 季数 */
    season?: number;
    /** 集数 */
    episode?: number;
  };
}

/**
 * 视频缓存信息接口
 */
export interface VideoCacheInfo {
  /** 缓存ID */
  cacheId: string;
  /** 视频ID */
  videoId: string;
  /** 视频标题 */
  title: string;
  /** 视频URL */
  videoUrl: string;
  /** 缓存路径 */
  filePath?: string;
  /** 缓存大小（字节） */
  size: number;
  /** 缓存进度（0-1） */
  progress: number;
  /** 缓存状态 */
  status: 'pending' | 'downloading' | 'completed' | 'failed' | 'paused';
  /** 开始缓存时间 */
  startTime: string;
  /** 完成时间 */
  endTime?: string;
  /** 错误信息 */
  error?: string;
  /** 视频类型 */
  type?: 'movie' | 'series' | 'live';
  /** 剧集信息 */
  episode?: {
    /** 剧集ID */
    id?: string;
    /** 剧集名称 */
    name?: string;
  };
}

/**
 * 视频播放配置接口
 */
export interface VideoPlayConfig {
  /** 是否自动播放 */
  autoPlay?: boolean;
  /** 默认音量 */
  volume?: number;
  /** 是否静音 */
  muted?: boolean;
  /** 播放速率 */
  playbackRate?: number;
  /** 是否循环播放 */
  loop?: boolean;
  /** 是否记住播放位置 */
  rememberPosition?: boolean;
  /** 默认清晰度 */
  defaultQuality?: string;
  /** 是否使用硬件加速 */
  hardwareAcceleration?: boolean;
}

/**
 * 视频源接口
 */
export interface VideoSource {
  /** 源ID */
  id: string;
  /** 源名称 */
  name: string;
  /** 视频URL */
  url: string;
  /** 清晰度 */
  quality: string;
  /** 格式 */
  format?: string;
  /** 大小 */
  size?: number;
  /** 码率 */
  bitrate?: number;
  /** 是否为默认源 */
  isDefault?: boolean;
}

/**
 * 视频管理服务
 */
export class VideoManagerService {
  private static instance: VideoManagerService;
  private storageUtil: StorageUtil;
  private userService: UserService;
  private commonUtil: CommonUtil;
  private currentPlayingVideo: VideoPlayHistory | null = null;
  private playConfigs: Map<string, VideoPlayConfig> = new Map();
  private initialized: boolean = false;
  
  private constructor() {
    this.storageUtil = StorageUtil.getInstance();
    this.userService = UserService.getInstance();
    this.commonUtil = CommonUtil.getInstance();
  }
  
  /**
   * 获取实例
   */
  public static getInstance(): VideoManagerService {
    if (!VideoManagerService.instance) {
      VideoManagerService.instance = new VideoManagerService();
    }
    return VideoManagerService.instance;
  }
  
  /**
   * 初始化视频管理服务
   */
  public async initialize(): Promise<void> {
    if (this.initialized) return;
    
    try {
      // 加载用户偏好设置
      const preferences = await this.userService.getPreferences();
      
      // 初始化默认播放配置
      this.setDefaultPlayConfig({
        autoPlay: preferences.autoPlay ?? true,
        volume: 1.0,
        muted: false,
        playbackRate: preferences.playbackSpeed ?? 1.0,
        loop: false,
        rememberPosition: true,
        defaultQuality: preferences.defaultQuality ?? 'auto',
        hardwareAcceleration: true
      });
      
      this.initialized = true;
    } catch (error) {
      console.error('Failed to initialize video manager service:', error);
      this.initialized = true; // 即使初始化失败，也标记为已初始化，确保服务能正常运行
    }
  }
  
  /**
   * 设置默认播放配置
   */
  public setDefaultPlayConfig(config: Partial<VideoPlayConfig>): void {
    const defaultConfig: VideoPlayConfig = {
      autoPlay: true,
      volume: 1.0,
      muted: false,
      playbackRate: 1.0,
      loop: false,
      rememberPosition: true,
      defaultQuality: 'auto',
      hardwareAcceleration: true,
      ...config
    };
    
    this.playConfigs.set('default', defaultConfig);
  }
  
  /**
   * 获取视频播放配置
   */
  public getPlayConfig(videoId?: string): VideoPlayConfig {
    if (videoId && this.playConfigs.has(videoId)) {
      return this.playConfigs.get(videoId)!;
    }
    
    return this.playConfigs.get('default') || {
      autoPlay: true,
      volume: 1.0,
      muted: false,
      playbackRate: 1.0,
      loop: false,
      rememberPosition: true,
      defaultQuality: 'auto',
      hardwareAcceleration: true
    };
  }
  
  /**
   * 保存视频播放配置
   */
  public setPlayConfig(videoId: string, config: Partial<VideoPlayConfig>): void {
    const currentConfig = this.getPlayConfig(videoId);
    const newConfig = { ...currentConfig, ...config };
    this.playConfigs.set(videoId, newConfig);
  }
  
  /**
   * 开始播放视频
   */
  public async startPlayVideo(videoId: string, title: string, cover?: string): Promise<VideoPlayHistory | null> {
    await this.initialize();
    
    try {
      // 获取用户信息
      const user = await this.userService.getCurrentUser();
      
      // 如果用户启用了播放历史功能，尝试获取播放记录
      if (user?.preferences?.watchedHistoryEnabled) {
        const history = await this.getPlayHistory(videoId);
        
        // 创建或更新当前播放记录
        this.currentPlayingVideo = history || {
          videoId,
          title,
          cover,
          position: 0,
          duration: 0,
          lastPlayTime: new Date().toISOString(),
          progress: 0,
          type: 'movie'
        };
        
        return this.currentPlayingVideo;
      }
      
      return null;
    } catch (error) {
      console.error('Failed to start playing video:', error);
      return null;
    }
  }
  
  /**
   * 更新播放进度
   */
  public async updatePlayProgress(videoId: string, position: number, duration: number): Promise<void> {
    await this.initialize();
    
    try {
      // 计算播放进度
      const progress = duration > 0 ? (position / duration) * 100 : 0;
      
      // 更新当前播放记录
      if (this.currentPlayingVideo && this.currentPlayingVideo.videoId === videoId) {
        this.currentPlayingVideo.position = position;
        this.currentPlayingVideo.duration = duration;
        this.currentPlayingVideo.progress = progress;
        this.currentPlayingVideo.lastPlayTime = new Date().toISOString();
      }
      
      // 获取用户信息
      const user = await this.userService.getCurrentUser();
      
      // 如果用户启用了播放历史功能，保存播放记录
      if (user?.preferences?.watchedHistoryEnabled) {
        // 只有当播放进度超过1%或已经有播放记录时才保存
        if (progress >= 1 || await this.hasPlayHistory(videoId)) {
          await this.savePlayHistory({
            videoId,
            title: this.currentPlayingVideo?.title || '',
            cover: this.currentPlayingVideo?.cover,
            position,
            duration,
            lastPlayTime: new Date().toISOString(),
            progress,
            type: this.currentPlayingVideo?.type || 'movie',
            episode: this.currentPlayingVideo?.episode
          });
        }
      }
    } catch (error) {
      console.error('Failed to update play progress:', error);
    }
  }
  
  /**
   * 结束播放
   */
  public async endPlayVideo(): Promise<void> {
    await this.initialize();
    
    try {
      if (this.currentPlayingVideo) {
        // 保存最终播放进度
        await this.updatePlayProgress(
          this.currentPlayingVideo.videoId,
          this.currentPlayingVideo.position,
          this.currentPlayingVideo.duration
        );
        
        // 清除当前播放记录
        this.currentPlayingVideo = null;
      }
    } catch (error) {
      console.error('Failed to end play video:', error);
    }
  }
  
  /**
   * 保存播放历史
   */
  private async savePlayHistory(history: VideoPlayHistory): Promise<void> {
    try {
      // 获取用户ID
      const user = await this.userService.getCurrentUser();
      if (!user?.userId) return;
      
      // 获取现有历史记录
      const historyList = await this.getPlayHistoryList() || [];
      
      // 查找是否已存在记录
      const existingIndex = historyList.findIndex(item => 
        item.videoId === history.videoId && 
        (!item.episode?.id || !history.episode?.id || item.episode.id === history.episode.id)
      );
      
      if (existingIndex >= 0) {
        // 更新现有记录
        historyList[existingIndex] = history;
      } else {
        // 添加新记录到开头
        historyList.unshift(history);
      }
      
      // 限制历史记录数量
      const maxHistoryCount = 100; // 最多保存100条记录
      if (historyList.length > maxHistoryCount) {
        historyList.splice(maxHistoryCount);
      }
      
      // 保存到存储
      await this.storageUtil.save(StorageType.USER_DATA, `play_history_${user.userId}`, historyList);
    } catch (error) {
      console.error('Failed to save play history:', error);
      throw error;
    }
  }
  
  /**
   * 获取单个视频的播放历史
   */
  public async getPlayHistory(videoId: string, episodeId?: string): Promise<VideoPlayHistory | null> {
    try {
      // 获取用户ID
      const user = await this.userService.getCurrentUser();
      if (!user?.userId) return null;
      
      // 获取历史记录列表
      const historyList = await this.getPlayHistoryList() || [];
      
      // 查找指定视频的记录
      if (episodeId) {
        return historyList.find(item => 
          item.videoId === videoId && item.episode?.id === episodeId
        ) || null;
      } else {
        // 如果没有指定剧集ID，返回最新的该视频记录
        return historyList.find(item => 
          item.videoId === videoId && !item.episode?.id
        ) || null;
      }
    } catch (error) {
      console.error('Failed to get play history:', error);
      return null;
    }
  }
  
  /**
   * 获取所有播放历史
   */
  public async getPlayHistoryList(limit: number = 50): Promise<VideoPlayHistory[]> {
    try {
      // 获取用户ID
      const user = await this.userService.getCurrentUser();
      if (!user?.userId) return [];
      
      // 从存储获取历史记录
      const historyList = await this.storageUtil.get(StorageType.USER_DATA, `play_history_${user.userId}`) || [];
      
      if (!Array.isArray(historyList)) {
        return [];
      }
      
      // 按最后播放时间排序
      return historyList
        .sort((a: VideoPlayHistory, b: VideoPlayHistory) => 
          new Date(b.lastPlayTime).getTime() - new Date(a.lastPlayTime).getTime()
        )
        .slice(0, limit);
    } catch (error) {
      console.error('Failed to get play history list:', error);
      return [];
    }
  }
  
  /**
   * 检查是否有播放历史
   */
  public async hasPlayHistory(videoId: string, episodeId?: string): Promise<boolean> {
    const history = await this.getPlayHistory(videoId, episodeId);
    return history !== null;
  }
  
  /**
   * 删除播放历史
   */
  public async deletePlayHistory(videoId: string, episodeId?: string): Promise<boolean> {
    try {
      // 获取用户ID
      const user = await this.userService.getCurrentUser();
      if (!user?.userId) return false;
      
      // 获取历史记录列表
      let historyList = await this.getPlayHistoryList() || [];
      
      if (!Array.isArray(historyList)) {
        return false;
      }
      
      if (episodeId) {
        // 删除指定视频的指定剧集记录
        historyList = historyList.filter(item => 
          !(item.videoId === videoId && item.episode?.id === episodeId)
        );
      } else {
        // 删除指定视频的所有记录
        historyList = historyList.filter(item => item.videoId !== videoId);
      }
      
      // 保存到存储
      await this.storageUtil.save(StorageType.USER_DATA, `play_history_${user.userId}`, historyList);
      
      return true;
    } catch (error) {
      console.error('Failed to delete play history:', error);
      return false;
    }
  }
  
  /**
   * 清空所有播放历史
   */
  public async clearAllPlayHistory(): Promise<boolean> {
    try {
      // 获取用户ID
      const user = await this.userService.getCurrentUser();
      if (!user?.userId) return false;
      
      // 从存储中移除历史记录
      await this.storageUtil.remove(StorageType.USER_DATA, `play_history_${user.userId}`);
      
      return true;
    } catch (error) {
      console.error('Failed to clear all play history:', error);
      return false;
    }
  }
  
  /**
   * 开始缓存视频
   */
  public async startCacheVideo(
    videoId: string,
    title: string,
    videoUrl: string,
    type: 'movie' | 'series' | 'live' = 'movie',
    episode?: { id?: string; name?: string }
  ): Promise<string> {
    try {
      // 创建缓存信息
      const cacheId = this.commonUtil.generateUniqueId('cache');
      const cacheInfo: VideoCacheInfo = {
        cacheId,
        videoId,
        title,
        videoUrl,
        size: 0,
        progress: 0,
        status: 'pending',
        startTime: new Date().toISOString(),
        type,
        episode
      };
      
      // 获取用户ID
      const user = await this.userService.getCurrentUser();
      if (!user?.userId) {
        throw new Error('用户未登录');
      }
      
      // 获取现有缓存列表
      const cacheList = await this.getCacheList() || [];
      
      // 添加新缓存项
      cacheList.push(cacheInfo);
      
      // 保存到存储
      await this.storageUtil.save(StorageType.CACHE_DATA, `video_caches_${user.userId}`, cacheList);
      
      // 在实际应用中，这里应该启动后台下载任务
      // 现在模拟开始下载
      setTimeout(async () => {
        await this.updateCacheProgress(cacheId, 0.5, 1024 * 1024 * 50); // 模拟50MB，50%进度
      }, 2000);
      
      return cacheId;
    } catch (error) {
      console.error('Failed to start cache video:', error);
      throw new Error(`开始缓存失败: ${error instanceof Error ? error.message : String(error)}`);
    }
  }
  
  /**
   * 更新缓存进度
   */
  public async updateCacheProgress(cacheId: string, progress: number, size: number): Promise<void> {
    try {
      // 获取用户ID
      const user = await this.userService.getCurrentUser();
      if (!user?.userId) return;
      
      // 获取缓存列表
      const cacheList = await this.getCacheList() || [];
      
      // 查找缓存项
      const cacheIndex = cacheList.findIndex(item => item.cacheId === cacheId);
      if (cacheIndex === -1) return;
      
      // 更新缓存信息
      cacheList[cacheIndex].progress = Math.max(0, Math.min(1, progress));
      cacheList[cacheIndex].size = size;
      cacheList[cacheIndex].status = progress >= 1 ? 'completed' : 'downloading';
      
      if (progress >= 1) {
        cacheList[cacheIndex].endTime = new Date().toISOString();
      }
      
      // 保存到存储
      await this.storageUtil.save(StorageType.CACHE_DATA, `video_caches_${user.userId}`, cacheList);
    } catch (error) {
      console.error('Failed to update cache progress:', error);
    }
  }
  
  /**
   * 暂停缓存
   */
  public async pauseCache(cacheId: string): Promise<boolean> {
    return this.updateCacheStatus(cacheId, 'paused');
  }
  
  /**
   * 恢复缓存
   */
  public async resumeCache(cacheId: string): Promise<boolean> {
    return this.updateCacheStatus(cacheId, 'downloading');
  }
  
  /**
   * 取消缓存
   */
  public async cancelCache(cacheId: string): Promise<boolean> {
    return this.updateCacheStatus(cacheId, 'failed', '缓存已取消');
  }
  
  /**
   * 更新缓存状态
   */
  private async updateCacheStatus(cacheId: string, status: VideoCacheInfo['status'], error?: string): Promise<boolean> {
    try {
      // 获取用户ID
      const user = await this.userService.getCurrentUser();
      if (!user?.userId) return false;
      
      // 获取缓存列表
      const cacheList = await this.getCacheList() || [];
      
      // 查找缓存项
      const cacheIndex = cacheList.findIndex(item => item.cacheId === cacheId);
      if (cacheIndex === -1) return false;
      
      // 更新状态
      cacheList[cacheIndex].status = status;
      if (error) {
        cacheList[cacheIndex].error = error;
      }
      
      if (status === 'failed' || status === 'completed') {
        cacheList[cacheIndex].endTime = new Date().toISOString();
      }
      
      // 保存到存储
      await this.storageUtil.save(StorageType.CACHE_DATA, `video_caches_${user.userId}`, cacheList);
      
      return true;
    } catch (error) {
      console.error('Failed to update cache status:', error);
      return false;
    }
  }
  
  /**
   * 获取缓存列表
   */
  public async getCacheList(): Promise<VideoCacheInfo[]> {
    try {
      // 获取用户ID
      const user = await this.userService.getCurrentUser();
      if (!user?.userId) return [];
      
      // 从存储获取缓存列表
      const cacheList = await this.storageUtil.get(StorageType.CACHE_DATA, `video_caches_${user.userId}`) || [];
      
      return Array.isArray(cacheList) ? cacheList : [];
    } catch (error) {
      console.error('Failed to get cache list:', error);
      return [];
    }
  }
  
  /**
   * 获取缓存详情
   */
  public async getCacheInfo(cacheId: string): Promise<VideoCacheInfo | null> {
    try {
      const cacheList = await this.getCacheList();
      return cacheList.find(item => item.cacheId === cacheId) || null;
    } catch (error) {
      console.error('Failed to get cache info:', error);
      return null;
    }
  }
  
  /**
   * 删除缓存
   */
  public async deleteCache(cacheId: string): Promise<boolean> {
    try {
      // 获取用户ID
      const user = await this.userService.getCurrentUser();
      if (!user?.userId) return false;
      
      // 获取缓存列表
      let cacheList = await this.getCacheList() || [];
      
      // 过滤掉要删除的缓存项
      cacheList = cacheList.filter(item => item.cacheId !== cacheId);
      
      // 保存到存储
      await this.storageUtil.save(StorageType.CACHE_DATA, `video_caches_${user.userId}`, cacheList);
      
      // 在实际应用中，这里应该删除本地缓存文件
      console.log('Cache deleted:', cacheId);
      
      return true;
    } catch (error) {
      console.error('Failed to delete cache:', error);
      return false;
    }
  }
  
  /**
   * 清空所有缓存
   */
  public async clearAllCache(): Promise<boolean> {
    try {
      // 获取用户ID
      const user = await this.userService.getCurrentUser();
      if (!user?.userId) return false;
      
      // 从存储中移除缓存列表
      await this.storageUtil.remove(StorageType.CACHE_DATA, `video_caches_${user.userId}`);
      
      // 在实际应用中，这里应该删除所有本地缓存文件
      console.log('All caches cleared');
      
      return true;
    } catch (error) {
      console.error('Failed to clear all cache:', error);
      return false;
    }
  }
  
  /**
   * 获取缓存总大小
   */
  public async getTotalCacheSize(): Promise<number> {
    try {
      const cacheList = await this.getCacheList();
      return cacheList.reduce((total, cache) => total + cache.size, 0);
    } catch (error) {
      console.error('Failed to get total cache size:', error);
      return 0;
    }
  }
  
  /**
   * 格式化视频源列表
   */
  public formatVideoSources(sources: any[]): VideoSource[] {
    // 根据不同的源格式进行标准化处理
    return sources.map((source, index) => {
      // 如果已经是标准格式，直接返回
      if (source.id && source.url && source.quality) {
        return source as VideoSource;
      }
      
      // 否则进行转换
      return {
        id: source.id || `source_${index}`,
        name: source.name || `源 ${index + 1}`,
        url: source.url || source.src || '',
        quality: source.quality || source.label || '未知',
        format: source.format,
        size: source.size,
        bitrate: source.bitrate,
        isDefault: source.isDefault || index === 0
      };
    }).filter(source => source.url); // 过滤掉无效的源
  }
  
  /**
   * 选择合适的视频源
   */
  public selectVideoSource(sources: VideoSource[], preferredQuality?: string): VideoSource | null {
    if (!sources || sources.length === 0) {
      return null;
    }
    
    // 如果指定了偏好清晰度，尝试匹配
    if (preferredQuality && preferredQuality !== 'auto') {
      const matchedSource = sources.find(source => 
        source.quality.toLowerCase().includes(preferredQuality.toLowerCase())
      );
      if (matchedSource) {
        return matchedSource;
      }
    }
    
    // 返回默认源
    const defaultSource = sources.find(source => source.isDefault);
    if (defaultSource) {
      return defaultSource;
    }
    
    // 返回第一个源
    return sources[0];
  }
  
  /**
   * 检查视频是否已缓存
   */
  public async isVideoCached(videoId: string, episodeId?: string): Promise<boolean> {
    try {
      const cacheList = await this.getCacheList();
      
      if (episodeId) {
        return cacheList.some(item => 
          item.videoId === videoId && 
          item.episode?.id === episodeId && 
          item.status === 'completed'
        );
      } else {
        return cacheList.some(item => 
          item.videoId === videoId && 
          !item.episode?.id && 
          item.status === 'completed'
        );
      }
    } catch (error) {
      console.error('Failed to check if video is cached:', error);
      return false;
    }
  }
  
  /**
   * 获取已缓存视频的本地路径
   */
  public async getCachedVideoPath(videoId: string, episodeId?: string): Promise<string | null> {
    try {
      const cacheList = await this.getCacheList();
      
      let cachedVideo: VideoCacheInfo | undefined;
      
      if (episodeId) {
        cachedVideo = cacheList.find(item => 
          item.videoId === videoId && 
          item.episode?.id === episodeId && 
          item.status === 'completed'
        );
      } else {
        cachedVideo = cacheList.find(item => 
          item.videoId === videoId && 
          !item.episode?.id && 
          item.status === 'completed'
        );
      }
      
      return cachedVideo?.filePath || null;
    } catch (error) {
      console.error('Failed to get cached video path:', error);
      return null;
    }
  }
}

// 导出视频管理服务单例
export const videoManagerService = VideoManagerService.getInstance();

// 导出类型别名
export type { VideoPlayHistory as PlayHistory };
export type { VideoCacheInfo as CacheInfo };
export type { VideoPlayConfig as PlayConfig };
export type { VideoSource as Source };