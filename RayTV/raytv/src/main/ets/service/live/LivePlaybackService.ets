/**
 * LivePlaybackService - 完整的直播播放服务
 * 
 * 基于HarmonyOS AVPlayer实现直播流播放功能
 * 支持RTMP/HLS/DASH等协议，提供频道切换、播放控制等完整功能
 */

import Logger from '../../common/util/Logger';
import PlayerService, { PlayerStatus, PlayerEvent, PlayerConfig } from '../player/PlayerService';
import ContentAccessService from './ContentAccessService';
import { LiveChannelWithSource } from './SourcePoolManager';
import EventBusUtil from '../../common/util/EventBusUtil';
import StorageUtil from '../../common/util/StorageUtil';

// ========================================
// 直播播放相关接口
// ========================================

/**
 * 直播播放状态
 */
export enum LivePlaybackStatus {
  IDLE = 'idle',
  CONNECTING = 'connecting',
  PLAYING = 'playing',
  PAUSED = 'paused',
  BUFFERING = 'buffering',
  ERROR = 'error',
  STOPPED = 'stopped'
}

/**
 * 直播质量选项
 */
export interface LiveQualityOption {
  label: string;
  bandwidth: number;  // 带宽要求 (bps)
  url?: string;        // 可选的特定URL
  resolution: string;  // 分辨率，如 '1920x1080'
}

/**
 * 直播统计信息
 */
export interface LiveStreamStats {
  bitrate: number;           // 当前码率
  fps: number;              // 帧率
  resolution: string;       // 分辨率
  bufferLength: number;     // 缓冲长度（秒）
  droppedFrames: number;    // 丢帧数
  decodedFrames: number;    // 解码帧数
  totalBytes: number;       // 总接收字节数
}

/**
 * 直播播放配置
 */
export interface LivePlaybackConfig {
  autoReconnect: boolean;      // 自动重连
  maxReconnectAttempts: number; // 最大重连次数
  reconnectDelay: number;       // 重连延迟（毫秒）
  bufferTime: number;           // 缓冲时间（秒）
  preferQuality: string;        // 偏好质量
  enableLowLatency: boolean;    // 启用低延迟模式
  fallbackUrl: string;          // 备用URL
}

// 默认配置
export const DEFAULT_LIVE_CONFIG: LivePlaybackConfig = {
  autoReconnect: true,
  maxReconnectAttempts: 3,
  reconnectDelay: 3000,
  bufferTime: 3,
  preferQuality: 'auto',
  enableLowLatency: true,
  fallbackUrl: ''
};

/**
 * 直播播放事件
 */
export const LivePlaybackEventType = {
  STATUS_CHANGED: 'live:statusChanged',
  CHANNEL_SWITCHED: 'live:channelSwitched',
  QUALITY_CHANGED: 'live:qualityChanged',
  BUFFER_UPDATED: 'live:bufferUpdated',
  STATS_UPDATED: 'live:statsUpdated',
  ERROR: 'live:error',
  RECONNECTING: 'live:reconnecting',
  RECONNECTED: 'live:reconnected'
} as const;

/**
 * 直播播放事件数据
 */
export interface LivePlaybackEventData {
  status?: LivePlaybackStatus;
  channel?: LiveChannelWithSource;
  quality?: string;
  stats?: LiveStreamStats;
  error?: { code: number; message: string };
  attempt?: number;
}

/**
 * 播放历史项
 */
export interface PlaybackHistoryItem {
  channelId: string;
  channelName: string;
  startTime: number;
  endTime: number;
  watchTime: number; // 观看时长（秒）
  quality: string;
  bitrate: number;
}

/**
 * 播放统计信息
 */
export interface PlaybackStats {
  totalWatchTime: number; // 总观看时长（秒）
  channelWatchTime: Map<string, number>; // 每个频道的观看时长
  dailyWatchTime: Map<string, number>; // 每日观看时长
  weeklyWatchTime: Map<string, number>; // 每周观看时长
  mostWatchedChannels: Array<{ channelId: string; channelName: string; watchTime: number }>; // 观看最多的频道
  averageWatchTime: number; // 平均观看时长（秒）
}

// ========================================
// 直播播放服务类
// ========================================

export class LivePlaybackService {
  private static instance: LivePlaybackService;
  private logger: Logger;
  private playerService: PlayerService;
  private contentService: ContentAccessService;
  private eventBus: EventBusUtil;
  
  // 播放状态
  private currentStatus: LivePlaybackStatus = LivePlaybackStatus.IDLE;
  private currentChannel: LiveChannelWithSource | null = null;
  private currentConfig: LivePlaybackConfig = DEFAULT_LIVE_CONFIG;
  private reconnectAttempts: number = 0;
  private reconnectTimer: number = 0;
  
  // 统计信息
  private streamStats: LiveStreamStats = {
    bitrate: 0,
    fps: 0,
    resolution: '',
    bufferLength: 0,
    droppedFrames: 0,
    decodedFrames: 0,
    totalBytes: 0
  };
  
  // 质量选项
  private qualityOptions: LiveQualityOption[] = [];
  private currentQuality: string = 'auto';
  
  // 播放历史
  private recentChannels: LiveChannelWithSource[] = [];
  private maxRecentChannels: number = 20;
  
  // 收藏频道
  private favoriteChannels: LiveChannelWithSource[] = [];
  
  // 播放历史记录
  private playbackHistory: PlaybackHistoryItem[] = [];
  private maxHistoryItems: number = 100;
  
  // 播放统计
  private playbackStats: PlaybackStats = {
    totalWatchTime: 0,
    channelWatchTime: new Map(),
    dailyWatchTime: new Map(),
    weeklyWatchTime: new Map(),
    mostWatchedChannels: [],
    averageWatchTime: 0
  };
  
  private constructor() {
    this.logger = Logger.getInstance('LivePlaybackService');
    this.playerService = PlayerService.getInstance();
    this.contentService = ContentAccessService.getInstance();
    this.eventBus = EventBusUtil.getInstance();
    
    this.setupPlayerListeners();
    this.logger.info('LivePlaybackService initialized');
  }
  
  /**
   * 获取单例实例
   */
  public static getInstance(): LivePlaybackService {
    if (!LivePlaybackService.instance) {
      LivePlaybackService.instance = new LivePlaybackService();
    }
    return LivePlaybackService.instance;
  }
  
  /**
   * 初始化服务
   */
  public async initialize(): Promise<void> {
    try {
      await this.playerService.initialize();
      await this.loadRecentChannels();
      await this.loadFavoriteChannels();
      await this.loadPlaybackHistory();
      await this.loadPlaybackStats();
      this.logger.info('LivePlaybackService initialized successfully');
    } catch (error) {
      this.logger.error('Failed to initialize LivePlaybackService', error as Error);
      throw error;
    }
  }
  
  /**
   * 播放直播频道
   */
  public async playChannel(channel: LiveChannelWithSource): Promise<boolean> {
    try {
      this.logger.info(`Playing channel: ${channel.name} (${channel.url})`);
      
      // 更新状态
      this.updateStatus(LivePlaybackStatus.CONNECTING);
      
      // 加载到最近播放
      await this.addToRecentChannels(channel);
      
      // 获取播放URL（支持解码器配置）
      const playUrl = await this.getPlayUrl(channel);
      
      if (!playUrl) {
        throw new Error('Failed to get play URL');
      }
      
      // 配置播放器
      const playerConfig: Partial<PlayerConfig> = {
        autoPlay: true,
        volume: 1.0,
        loop: true  // 直播循环播放
      };
      
      // 播放媒体
      await this.playerService.playMedia(channel.id, playUrl, playerConfig);
      
      // 保存当前频道
      this.currentChannel = channel;
      this.reconnectAttempts = 0;
      
      // 发布频道切换事件
      this.eventBus.publish(LivePlaybackEventType.CHANNEL_SWITCHED, { channel });
      
      this.logger.info(`Channel ${channel.name} started successfully`);
      return true;
    } catch (error) {
      this.logger.error(`Failed to play channel ${channel.name}`, error as Error);
      this.updateStatus(LivePlaybackStatus.ERROR);
      
      // 发布错误事件
      this.eventBus.publish(LivePlaybackEventType.ERROR, {
        error: {
          code: -1,
          message: String(error)
        }
      });
      
      // 尝试重连
      if (this.currentConfig.autoReconnect) {
        this.attemptReconnect(channel);
      }
      
      return false;
    }
  }
  
  /**
   * 停止播放
   */
  public stop(): void {
    try {
      this.playerService.stop();
      this.updateStatus(LivePlaybackStatus.STOPPED);
      this.clearReconnectTimer();
      this.logger.info('Live playback stopped');
    } catch (error) {
      this.logger.error('Failed to stop live playback', error as Error);
    }
  }
  
  /**
   * 暂停播放
   */
  public pause(): void {
    try {
      this.playerService.pause();
      this.updateStatus(LivePlaybackStatus.PAUSED);
      this.logger.info('Live playback paused');
    } catch (error) {
      this.logger.error('Failed to pause live playback', error as Error);
    }
  }
  
  /**
   * 恢复播放
   */
  public resume(): void {
    try {
      this.playerService.play();
      this.updateStatus(LivePlaybackStatus.PLAYING);
      this.logger.info('Live playback resumed');
    } catch (error) {
      this.logger.error('Failed to resume live playback', error as Error);
    }
  }
  
  /**
   * 切换频道
   */
  public async switchChannel(channel: LiveChannelWithSource): Promise<boolean> {
    this.logger.info(`Switching to channel: ${channel.name}`);
    
    // 停止当前播放
    this.stop();
    
    // 播放新频道
    return await this.playChannel(channel);
  }
  
  /**
   * 切换到下一个频道
   */
  public async switchToNextChannel(): Promise<boolean> {
    const channels = this.contentService.getAllLiveChannels();
    
    if (!this.currentChannel || channels.length === 0) {
      return false;
    }
    
    // 找到当前频道索引
    const currentIndex = channels.findIndex(c => c.id === this.currentChannel.id);
    if (currentIndex === -1) {
      return false;
    }
    
    // 切换到下一个频道（循环）
    const nextIndex = (currentIndex + 1) % channels.length;
    return await this.switchChannel(channels[nextIndex]);
  }
  
  /**
   * 切换到上一个频道
   */
  public async switchToPreviousChannel(): Promise<boolean> {
    const channels = this.contentService.getAllLiveChannels();
    
    if (!this.currentChannel || channels.length === 0) {
      return false;
    }
    
    // 找到当前频道索引
    const currentIndex = channels.findIndex(c => c.id === this.currentChannel.id);
    if (currentIndex === -1) {
      return false;
    }
    
    // 切换到上一个频道（循环）
    const prevIndex = (currentIndex - 1 + channels.length) % channels.length;
    return await this.switchChannel(channels[prevIndex]);
  }
  
  /**
   * 设置音量
   */
  public setVolume(volume: number): void {
    this.playerService.setVolume(volume);
    this.logger.debug(`Volume set to ${volume}`);
  }
  
  /**
   * 获取音量
   */
  public getVolume(): number {
    return this.playerService.getVolume();
  }
  
  /**
   * 静音/取消静音
   */
  public setMute(mute: boolean): void {
    if (mute) {
      this.playerService.mute();
    } else {
      this.playerService.unmute();
    }
    this.logger.debug(`Mute set to ${mute}`);
  }
  
  /**
   * 获取当前播放状态
   */
  public getStatus(): LivePlaybackStatus {
    return this.currentStatus;
  }
  
  /**
   * 获取当前频道
   */
  public getCurrentChannel(): LiveChannelWithSource | null {
    return this.currentChannel;
  }
  
  /**
   * 获取直播统计信息
   */
  public getStreamStats(): LiveStreamStats {
    return { ...this.streamStats };
  }
  
  /**
   * 获取最近播放的频道列表
   */
  public getRecentChannels(): LiveChannelWithSource[] {
    return [...this.recentChannels];
  }
  
  /**
   * 设置播放配置
   */
  public setConfig(config: Partial<LivePlaybackConfig>): void {
    this.currentConfig = { ...this.currentConfig, ...config };
    this.logger.info('Live playback config updated');
  }
  
  /**
   * 获取播放配置
   */
  public getConfig(): LivePlaybackConfig {
    return { ...this.currentConfig };
  }
  
  /**
   * 设置播放质量
   */
  public setQuality(quality: string): void {
    this.currentQuality = quality;
    this.eventBus.publish(LivePlaybackEventType.QUALITY_CHANGED, { quality });
    this.logger.info(`Quality set to ${quality}`);
  }
  
  /**
   * 获取当前质量
   */
  public getQuality(): string {
    return this.currentQuality;
  }
  
  /**
   * 获取可用质量选项
   */
  public getQualityOptions(): LiveQualityOption[] {
    return [...this.qualityOptions];
  }
  
  /**
   * 收藏频道
   */
  public async addToFavorites(channel: LiveChannelWithSource): Promise<boolean> {
    try {
      // 检查是否已收藏
      if (this.isFavorite(channel)) {
        this.logger.info(`Channel ${channel.name} is already in favorites`);
        return false;
      }
      
      // 添加到收藏列表
      this.favoriteChannels.push(channel);
      
      // 保存到存储
      await this.saveFavoriteChannels();
      
      this.logger.info(`Added channel ${channel.name} to favorites`);
      return true;
    } catch (error) {
      this.logger.error('Failed to add channel to favorites', error as Error);
      return false;
    }
  }
  
  /**
   * 取消收藏频道
   */
  public async removeFromFavorites(channel: LiveChannelWithSource): Promise<boolean> {
    try {
      // 检查是否在收藏列表中
      const index = this.favoriteChannels.findIndex(c => c.id === channel.id);
      if (index === -1) {
        this.logger.info(`Channel ${channel.name} is not in favorites`);
        return false;
      }
      
      // 从收藏列表中移除
      this.favoriteChannels.splice(index, 1);
      
      // 保存到存储
      await this.saveFavoriteChannels();
      
      this.logger.info(`Removed channel ${channel.name} from favorites`);
      return true;
    } catch (error) {
      this.logger.error('Failed to remove channel from favorites', error as Error);
      return false;
    }
  }
  
  /**
   * 获取收藏的频道列表
   */
  public getFavoriteChannels(): LiveChannelWithSource[] {
    return [...this.favoriteChannels];
  }
  
  /**
   * 检查频道是否已收藏
   */
  public isFavorite(channel: LiveChannelWithSource): boolean {
    return this.favoriteChannels.some(c => c.id === channel.id);
  }
  
  /**
   * 切换频道收藏状态
   */
  public async toggleFavorite(channel: LiveChannelWithSource): Promise<boolean> {
    if (this.isFavorite(channel)) {
      return await this.removeFromFavorites(channel);
    } else {
      return await this.addToFavorites(channel);
    }
  }
  
  /**
   * 开始播放记录
   */
  public startPlaybackRecord(channel: LiveChannelWithSource): void {
    // 这里可以记录开始时间，实际实现会在playChannel方法中调用
    this.logger.info(`Started playback record for channel: ${channel.name}`);
  }
  
  /**
   * 结束播放记录
   */
  public async endPlaybackRecord(channel: LiveChannelWithSource, watchTime: number): Promise<void> {
    try {
      const historyItem: PlaybackHistoryItem = {
        channelId: channel.id,
        channelName: channel.name,
        startTime: Date.now() - watchTime * 1000,
        endTime: Date.now(),
        watchTime,
        quality: this.currentQuality,
        bitrate: this.streamStats.bitrate
      };
      
      // 添加到历史记录
      this.playbackHistory.unshift(historyItem);
      
      // 限制历史记录数量
      if (this.playbackHistory.length > this.maxHistoryItems) {
        this.playbackHistory = this.playbackHistory.slice(0, this.maxHistoryItems);
      }
      
      // 更新统计信息
      await this.updatePlaybackStats(historyItem);
      
      // 保存历史记录和统计信息
      await this.savePlaybackHistory();
      await this.savePlaybackStats();
      
      this.logger.info(`Ended playback record for channel: ${channel.name}, watch time: ${watchTime}s`);
    } catch (error) {
      this.logger.error('Failed to end playback record', error as Error);
    }
  }
  
  /**
   * 获取播放历史记录
   */
  public getPlaybackHistory(): PlaybackHistoryItem[] {
    return [...this.playbackHistory];
  }
  
  /**
   * 获取播放统计信息
   */
  public getPlaybackStats(): PlaybackStats {
    return {
      ...this.playbackStats,
      channelWatchTime: new Map(this.playbackStats.channelWatchTime),
      dailyWatchTime: new Map(this.playbackStats.dailyWatchTime),
      weeklyWatchTime: new Map(this.playbackStats.weeklyWatchTime),
      mostWatchedChannels: [...this.playbackStats.mostWatchedChannels]
    };
  }
  
  /**
   * 分析播放模式
   */
  public analyzePlaybackPatterns(): {
    mostWatchedTimeOfDay: number;
    mostWatchedDayOfWeek: number;
    averageSessionDuration: number;
    watchFrequency: number;
  } {
    if (this.playbackHistory.length === 0) {
      return {
        mostWatchedTimeOfDay: 0,
        mostWatchedDayOfWeek: 0,
        averageSessionDuration: 0,
        watchFrequency: 0
      };
    }
    
    // 分析一天中最常观看的时间
    const hourlyWatches = new Map<number, number>();
    // 分析一周中最常观看的日子
    const dailyWatches = new Map<number, number>();
    // 计算平均会话时长
    let totalSessionDuration = 0;
    
    this.playbackHistory.forEach(item => {
      const startDate = new Date(item.startTime);
      const hour = startDate.getHours();
      const dayOfWeek = startDate.getDay();
      
      hourlyWatches.set(hour, (hourlyWatches.get(hour) || 0) + 1);
      dailyWatches.set(dayOfWeek, (dailyWatches.get(dayOfWeek) || 0) + 1);
      totalSessionDuration += item.watchTime;
    });
    
    // 找出最常观看的时间
    let mostWatchedTimeOfDay = 0;
    let maxHourlyWatches = 0;
    hourlyWatches.forEach((count, hour) => {
      if (count > maxHourlyWatches) {
        maxHourlyWatches = count;
        mostWatchedTimeOfDay = hour;
      }
    });
    
    // 找出最常观看的日子
    let mostWatchedDayOfWeek = 0;
    let maxDailyWatches = 0;
    dailyWatches.forEach((count, day) => {
      if (count > maxDailyWatches) {
        maxDailyWatches = count;
        mostWatchedDayOfWeek = day;
      }
    });
    
    const averageSessionDuration = totalSessionDuration / this.playbackHistory.length;
    const watchFrequency = this.playbackHistory.length / 7; // 假设一周的数据
    
    return {
      mostWatchedTimeOfDay,
      mostWatchedDayOfWeek,
      averageSessionDuration,
      watchFrequency
    };
  }
  
  /**
   * 清除播放历史
   */
  public async clearPlaybackHistory(): Promise<void> {
    try {
      this.playbackHistory = [];
      this.playbackStats = {
        totalWatchTime: 0,
        channelWatchTime: new Map(),
        dailyWatchTime: new Map(),
        weeklyWatchTime: new Map(),
        mostWatchedChannels: [],
        averageWatchTime: 0
      };
      
      await StorageUtil.remove('playback_history');
      await StorageUtil.remove('playback_stats');
      
      this.logger.info('Playback history cleared');
    } catch (error) {
      this.logger.error('Failed to clear playback history', error as Error);
    }
  }
  
  /**
   * 截图
   */
  public captureSnapshot(): Promise<string | null> {
    try {
      this.logger.info('Capturing snapshot');
      // 使用播放器服务进行截图
      return this.playerService.captureSnapshot();
    } catch (error) {
      this.logger.error('Failed to capture snapshot', error as Error);
      return Promise.resolve(null);
    }
  }
  
  /**
   * 录制直播
   */
  public startRecording(): Promise<boolean> {
    try {
      this.logger.info('Starting recording');
      // 使用播放器服务开始录制
      return this.playerService.startRecording();
    } catch (error) {
      this.logger.error('Failed to start recording', error as Error);
      return Promise.resolve(false);
    }
  }
  
  /**
   * 停止录制
   */
  public stopRecording(): Promise<string | null> {
    try {
      this.logger.info('Stopping recording');
      // 使用播放器服务停止录制
      return this.playerService.stopRecording();
    } catch (error) {
      this.logger.error('Failed to stop recording', error as Error);
      return Promise.resolve(null);
    }
  }
  
  // ========================================
  // 私有方法
  // ========================================
  
  /**
   * 获取播放URL（支持解码器配置）
   */
  private async getPlayUrl(channel: LiveChannelWithSource): Promise<string | null> {
    try {
      // 检查是否需要使用解码器
      const decoderConfigs = this.contentService.getDecoderConfigs();
      
      // 应用解码器转换逻辑
      if (decoderConfigs.length > 0) {
        this.logger.debug('Applying decoder configs');
        
        // 遍历解码器配置，找到适合当前频道的解码器
        for (const config of decoderConfigs) {
          if (this.isDecoderSuitable(config, channel)) {
            this.logger.debug(`Using decoder: ${config.name}`);
            // 应用解码器转换
            return this.applyDecoderTransform(config, channel.url);
          }
        }
      }
      
      return channel.url;
    } catch (error) {
      this.logger.error('Failed to get play URL', error as Error);
      return null;
    }
  }
  
  /**
   * 更新播放状态
   */
  private updateStatus(status: LivePlaybackStatus): void {
    const oldStatus = this.currentStatus;
    this.currentStatus = status;
    
    // 发布状态变更事件
    this.eventBus.publish(LivePlaybackEventType.STATUS_CHANGED, { status, oldStatus });
    
    this.logger.debug(`Playback status changed from ${oldStatus} to ${status}`);
  }
  
  /**
   * 设置播放器事件监听
   */
  private setupPlayerListeners(): void {
    // 监听播放器状态变化
    this.playerService.on(PlayerEvent.STATUS_CHANGED, (status: PlayerStatus) => {
      this.handlePlayerStatusChange(status);
    });
    
    // 监听错误事件
    this.playerService.on(PlayerEvent.ERROR, (error: { code: number; message: string }) => {
      this.logger.error(`Player error: ${error.message}`);
      this.updateStatus(LivePlaybackStatus.ERROR);
      
      // 发布错误事件
      this.eventBus.publish(LivePlaybackEventType.ERROR, { error });
      
      // 尝试重连
      if (this.currentConfig.autoReconnect && this.currentChannel) {
        this.attemptReconnect(this.currentChannel);
      }
    });
    
    // 监听播放完成事件
    this.playerService.on(PlayerEvent.COMPLETED, () => {
      // 直播不应该触发完成事件，如果触发说明可能有问题
      this.logger.warn('Live stream playback completed unexpectedly');
    });
  }
  
  /**
   * 处理播放器状态变化
   */
  private handlePlayerStatusChange(playerStatus: PlayerStatus): void {
    switch (playerStatus) {
      case PlayerStatus.PLAYING:
        this.updateStatus(LivePlaybackStatus.PLAYING);
        break;
      case PlayerStatus.PAUSED:
        this.updateStatus(LivePlaybackStatus.PAUSED);
        break;
      case PlayerStatus.BUFFERING:
        this.updateStatus(LivePlaybackStatus.BUFFERING);
        break;
      case PlayerStatus.STOPPED:
        this.updateStatus(LivePlaybackStatus.STOPPED);
        break;
      case PlayerStatus.ERROR:
        this.updateStatus(LivePlaybackStatus.ERROR);
        break;
      default:
        break;
    }
  }
  
  /**
   * 尝试重连
   */
  private attemptReconnect(channel: LiveChannelWithSource): void {
    if (this.reconnectAttempts >= this.currentConfig.maxReconnectAttempts) {
      this.logger.error(`Max reconnect attempts (${this.currentConfig.maxReconnectAttempts}) reached`);
      return;
    }
    
    this.reconnectAttempts++;
    this.logger.info(`Attempting reconnect (${this.reconnectAttempts}/${this.currentConfig.maxReconnectAttempts})...`);
    
    // 发布重连事件
    this.eventBus.publish(LivePlaybackEventType.RECONNECTING, { attempt: this.reconnectAttempts });
    
    // 延迟重连
    this.clearReconnectTimer();
    this.reconnectTimer = setTimeout(async () => {
      const success = await this.playChannel(channel);
      if (success) {
        this.eventBus.publish(LivePlaybackEventType.RECONNECTED, { attempt: this.reconnectAttempts });
        this.logger.info('Reconnected successfully');
      }
    }, this.currentConfig.reconnectDelay);
  }
  
  /**
   * 清除重连定时器
   */
  private clearReconnectTimer(): void {
    if (this.reconnectTimer !== 0) {
      clearTimeout(this.reconnectTimer);
      this.reconnectTimer = 0;
    }
  }
  
  /**
   * 添加到最近播放
   */
  private async addToRecentChannels(channel: LiveChannelWithSource): Promise<void> {
    // 移除已存在的相同频道
    const index = this.recentChannels.findIndex(c => c.id === channel.id);
    if (index !== -1) {
      this.recentChannels.splice(index, 1);
    }
    
    // 添加到开头
    this.recentChannels.unshift(channel);
    
    // 限制数量
    if (this.recentChannels.length > this.maxRecentChannels) {
      this.recentChannels = this.recentChannels.slice(0, this.maxRecentChannels);
    }
    
    // 保存到存储
    await this.saveRecentChannels();
  }
  
  /**
   * 加载最近播放的频道
   */
  private async loadRecentChannels(): Promise<void> {
    try {
      const stored = await StorageUtil.get('recent_channels');
      if (stored) {
        try {
          const channels = JSON.parse(stored) as LiveChannelWithSource[];
          this.recentChannels = channels;
          this.logger.debug(`Loaded ${channels.length} recent channels`);
        } catch (parseError) {
          this.logger.error('Failed to parse recent channels', parseError as Error);
          this.recentChannels = [];
        }
      }
    } catch (error) {
      this.logger.error('Failed to load recent channels', error as Error);
      this.recentChannels = [];
    }
    this.logger.debug('Recent channels loaded');
  }
  
  /**
   * 保存最近播放的频道
   */
  private async saveRecentChannels(): Promise<void> {
    try {
      const data = JSON.stringify(this.recentChannels);
      await StorageUtil.set('recent_channels', data);
      this.logger.debug(`Saved ${this.recentChannels.length} recent channels`);
    } catch (error) {
      this.logger.error('Failed to save recent channels', error as Error);
    }
  }
  
  /**
   * 加载收藏的频道
   */
  private async loadFavoriteChannels(): Promise<void> {
    try {
      const stored = await StorageUtil.get('favorite_channels');
      if (stored) {
        try {
          const channels = JSON.parse(stored) as LiveChannelWithSource[];
          this.favoriteChannels = channels;
          this.logger.debug(`Loaded ${channels.length} favorite channels`);
        } catch (parseError) {
          this.logger.error('Failed to parse favorite channels', parseError as Error);
          this.favoriteChannels = [];
        }
      }
    } catch (error) {
      this.logger.error('Failed to load favorite channels', error as Error);
      this.favoriteChannels = [];
    }
    this.logger.debug('Favorite channels loaded');
  }
  
  /**
   * 保存收藏的频道
   */
  private async saveFavoriteChannels(): Promise<void> {
    try {
      const data = JSON.stringify(this.favoriteChannels);
      await StorageUtil.set('favorite_channels', data);
      this.logger.debug(`Saved ${this.favoriteChannels.length} favorite channels`);
    } catch (error) {
      this.logger.error('Failed to save favorite channels', error as Error);
    }
  }
  
  /**
   * 检查解码器是否适合当前频道
   */
  private isDecoderSuitable(config: any, channel: LiveChannelWithSource): boolean {
    // 检查解码器是否支持当前频道的协议
    if (config.supportedProtocols) {
      const url = channel.url.toLowerCase();
      for (const protocol of config.supportedProtocols) {
        if (url.includes(protocol.toLowerCase())) {
          return true;
        }
      }
    }
    
    // 检查解码器是否支持当前频道的编码格式
    if (config.supportedCodecs && channel.codec) {
      for (const codec of config.supportedCodecs) {
        if (channel.codec.toLowerCase().includes(codec.toLowerCase())) {
          return true;
        }
      }
    }
    
    return false;
  }
  
  /**
   * 应用解码器转换
   */
  private applyDecoderTransform(config: any, url: string): string {
    // 根据解码器配置转换URL
    if (config.transformUrl) {
      try {
        return config.transformUrl(url);
      } catch (error) {
        this.logger.error('Failed to transform URL with decoder', error as Error);
        return url;
      }
    }
    
    // 默认转换：添加解码器参数
    if (config.params) {
      const separator = url.includes('?') ? '&' : '?';
      const params = Object.entries(config.params)
        .map(([key, value]) => `${key}=${encodeURIComponent(value)}`)
        .join('&');
      return `${url}${separator}${params}`;
    }
    
    return url;
  }
  
  /**
   * 加载播放历史
   */
  private async loadPlaybackHistory(): Promise<void> {
    try {
      const stored = await StorageUtil.get('playback_history');
      if (stored) {
        try {
          const history = JSON.parse(stored) as PlaybackHistoryItem[];
          this.playbackHistory = history;
          this.logger.debug(`Loaded ${history.length} playback history items`);
        } catch (parseError) {
          this.logger.error('Failed to parse playback history', parseError as Error);
          this.playbackHistory = [];
        }
      }
    } catch (error) {
      this.logger.error('Failed to load playback history', error as Error);
      this.playbackHistory = [];
    }
  }
  
  /**
   * 保存播放历史
   */
  private async savePlaybackHistory(): Promise<void> {
    try {
      const data = JSON.stringify(this.playbackHistory);
      await StorageUtil.set('playback_history', data);
      this.logger.debug(`Saved ${this.playbackHistory.length} playback history items`);
    } catch (error) {
      this.logger.error('Failed to save playback history', error as Error);
    }
  }
  
  /**
   * 加载播放统计
   */
  private async loadPlaybackStats(): Promise<void> {
    try {
      const stored = await StorageUtil.get('playback_stats');
      if (stored) {
        try {
          const stats = JSON.parse(stored);
          this.playbackStats = {
            totalWatchTime: stats.totalWatchTime,
            channelWatchTime: new Map(stats.channelWatchTime),
            dailyWatchTime: new Map(stats.dailyWatchTime),
            weeklyWatchTime: new Map(stats.weeklyWatchTime),
            mostWatchedChannels: stats.mostWatchedChannels,
            averageWatchTime: stats.averageWatchTime
          };
          this.logger.debug('Loaded playback stats');
        } catch (parseError) {
          this.logger.error('Failed to parse playback stats', parseError as Error);
          this.resetPlaybackStats();
        }
      }
    } catch (error) {
      this.logger.error('Failed to load playback stats', error as Error);
      this.resetPlaybackStats();
    }
  }
  
  /**
   * 保存播放统计
   */
  private async savePlaybackStats(): Promise<void> {
    try {
      const data = JSON.stringify({
        totalWatchTime: this.playbackStats.totalWatchTime,
        channelWatchTime: Array.from(this.playbackStats.channelWatchTime.entries()),
        dailyWatchTime: Array.from(this.playbackStats.dailyWatchTime.entries()),
        weeklyWatchTime: Array.from(this.playbackStats.weeklyWatchTime.entries()),
        mostWatchedChannels: this.playbackStats.mostWatchedChannels,
        averageWatchTime: this.playbackStats.averageWatchTime
      });
      await StorageUtil.set('playback_stats', data);
      this.logger.debug('Saved playback stats');
    } catch (error) {
      this.logger.error('Failed to save playback stats', error as Error);
    }
  }
  
  /**
   * 更新播放统计
   */
  private async updatePlaybackStats(historyItem: PlaybackHistoryItem): Promise<void> {
    // 更新总观看时长
    this.playbackStats.totalWatchTime += historyItem.watchTime;
    
    // 更新频道观看时长
    const currentChannelTime = this.playbackStats.channelWatchTime.get(historyItem.channelId) || 0;
    this.playbackStats.channelWatchTime.set(historyItem.channelId, currentChannelTime + historyItem.watchTime);
    
    // 更新每日观看时长
    const date = new Date(historyItem.startTime).toISOString().split('T')[0];
    const currentDailyTime = this.playbackStats.dailyWatchTime.get(date) || 0;
    this.playbackStats.dailyWatchTime.set(date, currentDailyTime + historyItem.watchTime);
    
    // 更新每周观看时长
    const weekStart = this.getWeekStartDate(historyItem.startTime);
    const currentWeeklyTime = this.playbackStats.weeklyWatchTime.get(weekStart) || 0;
    this.playbackStats.weeklyWatchTime.set(weekStart, currentWeeklyTime + historyItem.watchTime);
    
    // 更新观看最多的频道
    this.updateMostWatchedChannels();
    
    // 更新平均观看时长
    this.playbackStats.averageWatchTime = this.playbackStats.totalWatchTime / this.playbackHistory.length;
  }
  
  /**
   * 更新观看最多的频道
   */
  private updateMostWatchedChannels(): void {
    const channelWatchTimeArray = Array.from(this.playbackStats.channelWatchTime.entries())
      .map(([channelId, watchTime]) => {
        const channel = this.contentService.getLiveChannelById(channelId);
        return {
          channelId,
          channelName: channel ? channel.name : channelId,
          watchTime
        };
      })
      .sort((a, b) => b.watchTime - a.watchTime)
      .slice(0, 10); // 只保留前10个
    
    this.playbackStats.mostWatchedChannels = channelWatchTimeArray;
  }
  
  /**
   * 重置播放统计
   */
  private resetPlaybackStats(): void {
    this.playbackStats = {
      totalWatchTime: 0,
      channelWatchTime: new Map(),
      dailyWatchTime: new Map(),
      weeklyWatchTime: new Map(),
      mostWatchedChannels: [],
      averageWatchTime: 0
    };
  }
  
  /**
   * 获取周开始日期
   */
  private getWeekStartDate(timestamp: number): string {
    const date = new Date(timestamp);
    const dayOfWeek = date.getDay();
    const diff = date.getDate() - dayOfWeek + (dayOfWeek === 0 ? -6 : 1);
    const weekStart = new Date(date.setDate(diff));
    return weekStart.toISOString().split('T')[0];
  }
  
  /**
   * 更新统计信息
   */
  private updateStats(): void {
    // 定期更新统计信息
    setInterval(async () => {
      try {
        // 从播放器获取实际统计信息
        const playerStats = await this.playerService.getStats();
        if (playerStats) {
          this.streamStats = {
            bitrate: playerStats.bitrate || this.streamStats.bitrate,
            fps: playerStats.fps || this.streamStats.fps,
            resolution: playerStats.resolution || this.streamStats.resolution,
            bufferLength: playerStats.bufferLength || this.streamStats.bufferLength,
            droppedFrames: playerStats.droppedFrames || this.streamStats.droppedFrames,
            decodedFrames: playerStats.decodedFrames || this.streamStats.decodedFrames,
            totalBytes: playerStats.totalBytes || this.streamStats.totalBytes
          };
        } else {
          // 模拟统计信息（当播放器无法提供时）
          this.streamStats.totalBytes += Math.floor(Math.random() * 10000);
          this.streamStats.bitrate = Math.floor(Math.random() * 5000000) + 1000000;
          this.streamStats.fps = Math.floor(Math.random() * 10) + 20;
        }
        
        this.eventBus.publish(LivePlaybackEventType.STATS_UPDATED, { stats: this.streamStats });
      } catch (error) {
        this.logger.error('Failed to update stats', error as Error);
      }
    }, 5000);
  }
}

export default LivePlaybackService;
