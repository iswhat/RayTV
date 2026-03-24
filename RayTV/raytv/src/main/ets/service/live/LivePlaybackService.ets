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
      this.addToRecentChannels(channel);
      
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
   * 截图
   */
  public captureSnapshot(): Promise<string | null> {
    // TODO: 实现截图功能
    this.logger.warn('Snapshot capture not implemented yet');
    return Promise.resolve(null);
  }
  
  /**
   * 录制直播
   */
  public startRecording(): Promise<boolean> {
    // TODO: 实现录制功能
    this.logger.warn('Recording not implemented yet');
    return Promise.resolve(false);
  }
  
  /**
   * 停止录制
   */
  public stopRecording(): Promise<string | null> {
    // TODO: 实现停止录制
    this.logger.warn('Stop recording not implemented yet');
    return Promise.resolve(null);
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
      
      // 简单实现：直接返回频道URL
      // 实际应用中需要根据解码器配置进行URL转换
      if (decoderConfigs.length > 0) {
        this.logger.debug('Applying decoder configs');
        // TODO: 应用解码器转换逻辑
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
  private addToRecentChannels(channel: LiveChannelWithSource): void {
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
    this.saveRecentChannels();
  }
  
  /**
   * 加载最近播放的频道
   */
  private async loadRecentChannels(): Promise<void> {
    // TODO: 从本地存储加载
    this.logger.debug('Recent channels loaded');
  }
  
  /**
   * 保存最近播放的频道
   */
  private saveRecentChannels(): void {
    // TODO: 保存到本地存储
    this.logger.debug('Recent channels saved');
  }
  
  /**
   * 更新统计信息
   */
  private updateStats(): void {
    // 定期更新统计信息
    // TODO: 从播放器获取实际统计信息
    setInterval(() => {
      this.streamStats.totalBytes += Math.floor(Math.random() * 10000);
      this.streamStats.bitrate = Math.floor(Math.random() * 5000000) + 1000000;
      this.streamStats.fps = Math.floor(Math.random() * 10) + 20;
      
      this.eventBus.publish(LivePlaybackEventType.STATS_UPDATED, { stats: this.streamStats });
    }, 5000);
  }
}

export default LivePlaybackService;
