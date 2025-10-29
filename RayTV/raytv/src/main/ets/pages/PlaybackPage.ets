import { useState, useEffect, onMounted, onUnmounted } from '@kit.ArkUI';
import { Stack, Video, Image, Text, Button, Slider, List, ListItem, LoadingProgress, Toast } from '@kit.ArkUI';
import { Router } from '@kit.AbilityKit';
import Logger from '../common/util/Logger.ets';playbackService } from '../service/media/PlaybackService';
import { historyService } from '../service/media/HistoryService';
import { mediaService } from '../service/media/MediaService';
import { configService } from '../service/config/ConfigService';
import { PlaybackState, PlaybackSpeed } from '../service/media/PlaybackService';
import Logger from '@ohos/base/Logger';

/**
 * 播放页面组件
 * 实现视频播放控制界面，包含播放/暂停、进度控制、音量控制、速度调整等功能
 */
@Component
struct PlaybackPage {
  private readonly TAG: string = 'PlaybackPage';
  
  // 路由参数
  private mediaId: string = '';
  private siteKey: string = '';
  private episodeId?: string;
  private initialPosition: number = 0;
  private mediaTitle: string = '';
  private episodeName: string = '';
  private playSource?: PlaySource;
  private playSourceIndex: number = 0;
  
  // 状态管理
  @State playbackState: PlaybackState = PlaybackState.IDLE;
  @State currentTime: number = 0;
  @State duration: number = 0;
  @State isPlaying: boolean = false;
  @State volume: number = 1.0;
  @State isMuted: boolean = false;
  @State playbackSpeed: PlaybackSpeed = PlaybackSpeed.NORMAL;
  @State isBuffering: boolean = false;
  @State bufferPercentage: number = 0;
  @State showControls: boolean = true;
  @State showSpeedMenu: boolean = false;
  @State showSourceMenu: boolean = false;
  @State showSubtitleMenu: boolean = false;
  @State playSources: PlaySource[] = [];
  @State subtitles: Subtitle[] = [];
  @State selectedSubtitle: Subtitle | null = null;
  @State isFullscreen: boolean = false;
  @State errorMessage: string = '';
  @State isLoading: boolean = true;
  @State controlsTimeout: NodeJS.Timeout | null = null;
  @State lastProgressSaveTime: number = 0;
  @State saveProgressInterval: number = 30000; // 30秒保存一次进度
  private autoSwitchSourceOnError: boolean = true; // 是否自动切换片源
  private lastSaveTime: number = 0; // 上次保存进度的时间(毫秒)
  private currentPosition: number = 0; // 当前播放位置
  private totalTime: number = 0;
  
  // 初始化
  onMounted(() => {
    Logger.info(this.TAG, 'PlaybackPage mounted');
    
    // 获取路由参数
    const params = Router.getParams();
    this.mediaId = params?.['mediaId'] || '';
    this.siteKey = params?.['siteKey'] || '';
    this.episodeId = params?.['episodeId'];
    this.initialPosition = params?.['currentTime'] || params?.['startPosition'] || 0;
    this.mediaTitle = params?.['mediaTitle'] || '正在播放';
    this.episodeName = params?.['episodeName'] || '';
    this.playSource = params?.['playSource'];
    this.playSourceIndex = params?.['playSourceIndex'] || 0;
    this.autoSwitchSourceOnError = params?.['autoSwitchSourceOnError'] !== false; // 默认开启
    
    Logger.info(this.TAG, `Starting playback for: ${this.siteKey}:${this.mediaId}${this.episodeId ? ` episode: ${this.episodeId}` : ''}, startPosition=${this.initialPosition}`);
    
    // 初始化播放器
    this.initializePlayback();
    
    // 设置控制栏自动隐藏
    this.startControlsTimeout();
  });
  
  // 清理资源
  aboutToDisappear() {
    Logger.info(this.TAG, 'PlaybackPage unmounted');
    
    // 移除播放监听器
    this.removePlaybackListeners();
    
    // 保存最终播放进度
    this.savePlayProgress(this.currentPosition).catch(error => {
      Logger.error(this.TAG, `Failed to save final progress: ${error}`);
    });
    
    // 停止控制栏超时
    this.stopControlsTimeout();
    
    // 释放播放器资源
    this.releasePlayer();
    playbackService.stop();
    playbackService.destroy();
  }
  
  /**
   * 初始化播放
   */
  private async initializePlayback(): Promise<void> {
    if (!this.mediaId || !this.siteKey) {
      this.errorMessage = '缺少必要参数';
      this.isLoading = false;
      this.playbackState = PlaybackState.ERROR;
      return;
    }
    
    try {
      // 加载播放源
      await this.loadPlaySources();
      
      // 设置播放源并开始播放
      if (this.playSource) {
        await this.setupPlayback(this.playSource);
      } else if (this.playSources.length > 0 && this.playSourceIndex < this.playSources.length) {
        await this.setupPlayback(this.playSources[this.playSourceIndex]);
      } else {
        this.errorMessage = '无可用播放源';
        this.isLoading = false;
        this.playbackState = PlaybackState.ERROR;
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to initialize playback: ${error}`);
      this.errorMessage = '播放初始化失败';
      this.isLoading = false;
      this.playbackState = PlaybackState.ERROR;
    }
  }
  
  /**
   * 加载播放源
   */
  private async loadPlaySources(): Promise<void> {
    try {
      // 如果没有传入播放源，则从服务获取
      if (!this.playSource || this.playSources.length === 0) {
        this.playSources = await mediaService.getPlaySources(
          this.mediaId,
          this.siteKey,
          this.episodeId
        );
        Logger.info(this.TAG, `Loaded ${this.playSources.length} play sources`);
      }
      
      // 如果只有一个播放源，则使用它
      if (this.playSources.length === 1 && !this.playSource) {
        this.playSource = this.playSources[0];
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to load play sources: ${error}`);
      throw error;
    }
  }
  
  /**
   * 设置播放
   */
  private async setupPlayback(source: PlaySource): Promise<void> {
    try {
      // 添加播放监听器
      this.addPlaybackListeners();
      
      // 设置播放源
      await playbackService.setSource(source, {
        autoPlay: true,
        startPosition: this.initialPosition,
        volume: this.volume,
        isMuted: this.isMuted,
        playbackSpeed: this.playbackSpeed
      });
      
      this.playSource = source;
      this.isLoading = false;
    } catch (error) {
      Logger.error(this.TAG, `Failed to setup playback: ${error}`);
      
      // 尝试自动切换到下一个片源
      if (this.autoSwitchSourceOnError) {
        await this.handlePlaybackError(error);
      } else {
        throw error;
      }
    }
  }
  
  /**
   * 添加播放监听器
   */
  private addPlaybackListeners(): void {
    playbackService.addListener({
      onStateChanged: (state) => {
        this.playbackState = state;
        this.isPlaying = state === PlaybackState.PLAYING;
        
        if (state === PlaybackState.COMPLETED) {
          this.handlePlaybackCompleted();
        } else if (state === PlaybackState.ERROR) {
          this.errorMessage = '播放出错';
        }
        
        this.showControls = true;
        this.restartControlsTimeout();
      },
      
      onError: async (error: Error) => {
        Logger.error(this.TAG, `Playback error: ${error}`);
        
        // 尝试自动切换片源
        if (this.autoSwitchSourceOnError) {
          await this.handlePlaybackError(error);
        } else {
          this.errorMessage = `播放错误: ${error.message || '未知错误'}`;
        }
      },
      
      // 定期保存播放进度
      onTimeUpdate: async (currentTime, duration) => {
        this.currentTime = currentTime;
        this.currentPosition = currentTime;
        this.duration = duration;
        this.totalTime = duration || this.totalTime;
        
        // 每10秒保存一次播放进度
        if (this.lastSaveTime === 0 || currentTime - this.lastSaveTime > 10000) {
          await this.savePlayProgress(currentTime);
          this.lastSaveTime = currentTime;
        }
      },
      
      onError: (error) => {
        Logger.error(this.TAG, `Playback error: ${error.message}`);
        this.errorMessage = error.message || '播放出错';
        this.isLoading = false;
      },
      
      onCompleted: () => {
        Logger.info(this.TAG, 'Playback completed');
      },
      
      onBufferUpdate: (bufferPercentage) => {
        this.bufferPercentage = bufferPercentage;
      },
      
      onSeekCompleted: (seekTime) => {
        Logger.info(this.TAG, `Seek completed to ${seekTime}s`);
      }
    });
  }
  
  /**
   * 处理播放完成
   */
  private async handlePlaybackCompleted(): Promise<void> {
    try {
      // 保存完成的播放状态
      await historyService.updateProgress(
        this.mediaId,
        this.siteKey,
        this.duration, // 标记为已完成
        this.episodeId,
        true // 标记为已完成
      );
      
      // 可以在这里处理下一集逻辑
      Toast.show('播放完成');
    } catch (error) {
      Logger.error(this.TAG, `Failed to handle playback completed: ${error}`);
    }
  }
  
  /**
   * 保存播放进度
   */
  private async savePlaybackProgress(): Promise<void> {
    try {
      await playbackService.savePlaybackPosition(
        this.mediaId,
        this.siteKey,
        this.episodeId
      );
    } catch (error) {
      Logger.error(this.TAG, `Failed to save playback progress: ${error}`);
    }
  }
  
  /**
   * 切换播放/暂停
   */
  private async togglePlayPause(): Promise<void> {
    try {
      if (this.isPlaying) {
        await playbackService.pause();
      } else {
        await playbackService.play();
      }
      
      this.showControls = true;
      this.restartControlsTimeout();
    } catch (error) {
      Logger.error(this.TAG, `Failed to toggle play/pause: ${error}`);
    }
  }
  
  /**
   * 处理进度条变化
   */
  private async handleProgressChange(value: number): Promise<void> {
    try {
      const seekTime = (value / 100) * this.duration;
      await playbackService.seekTo(seekTime);
      
      this.showControls = true;
      this.restartControlsTimeout();
    } catch (error) {
      Logger.error(this.TAG, `Failed to seek: ${error}`);
    }
  }
  
  /**
   * 处理音量变化
   */
  private async handleVolumeChange(value: number): Promise<void> {
    try {
      this.volume = value;
      if (this.isMuted && value > 0) {
        this.isMuted = false;
      }
      await playbackService.setVolume(value);
    } catch (error) {
      Logger.error(this.TAG, `Failed to set volume: ${error}`);
    }
  }
  
  /**
   * 切换静音
   */
  private async toggleMute(): Promise<void> {
    try {
      this.isMuted = !this.isMuted;
      await playbackService.setMuted(this.isMuted);
    } catch (error) {
      Logger.error(this.TAG, `Failed to toggle mute: ${error}`);
    }
  }
  
  /**
   * 设置播放速度
   */
  private async setPlaybackSpeed(speed: PlaybackSpeed): Promise<void> {
    try {
      this.playbackSpeed = speed;
      await playbackService.setPlaybackSpeed(speed);
      this.showSpeedMenu = false;
    } catch (error) {
      Logger.error(this.TAG, `Failed to set playback speed: ${error}`);
    }
  }
  
  /**
   * 保存播放进度
   */
  private async savePlayProgress(position: number): Promise<void> {
    if (!this.mediaId || !this.siteKey || !this.episodeId) return;
    
    try {
      const duration = this.totalTime || this.duration;
      
      // 保存播放进度到历史记录
      await historyService.saveWatchProgress(
        this.mediaId,
        this.siteKey,
        this.episodeId,
        position,
        duration
      );
      
      Logger.info(this.TAG, `Saved playback progress: ${position}ms of ${duration}ms`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to save play progress: ${error}`);
    }
  }
  
  /**
   * 处理播放错误，尝试切换到下一个可用片源
   */
  private async handlePlaybackError(error: Error): Promise<void> {
    if (!this.playSources || this.playSources.length <= 1) {
      this.errorMessage = '播放失败，暂无可用备用片源';
      this.isLoading = false;
      return;
    }
    
    // 查找当前片源的索引
    const currentIndex = this.playSources.findIndex(s => 
      s.id === this.playSource?.id || 
      (s.name === this.playSource?.name && s.url === this.playSource?.url)
    );
    
    // 选择下一个可用的片源
    let nextIndex = (currentIndex + 1) % this.playSources.length;
    
    if (currentIndex !== -1) {
      Logger.info(this.TAG, `尝试切换到下一个片源: ${nextIndex}，原片源: ${currentIndex}`);
      
      // 显示切换提示
      this.errorMessage = `当前片源播放失败，正在尝试切换到备用片源(${nextIndex + 1}/${this.playSources.length})...`;
      
      // 等待一小段时间再切换
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      try {
        // 保存当前播放位置
        const currentPosition = this.currentPosition;
        
        // 切换到下一个片源
        this.initialPosition = currentPosition; // 保持相同的播放位置
        await this.setupPlayback(this.playSources[nextIndex]);
        this.errorMessage = '';
      } catch (nextError) {
        // 如果下一个片源也失败，继续尝试下一个
        if (nextIndex !== currentIndex) {
          await this.handlePlaybackError(nextError);
        } else {
          this.errorMessage = '所有片源播放失败，请稍后重试';
          this.isLoading = false;
        }
      }
    } else {
      this.errorMessage = '播放失败，无法识别当前片源';
      this.isLoading = false;
    }
  }
  
  /**
   * 切换播放源
   */
  private async switchPlaySource(source: PlaySource): Promise<void> {
    try {
      this.isLoading = true;
      
      // 保存当前播放位置
      const currentPosition = this.currentPosition;
      
      // 切换到新片源并恢复播放位置
      this.initialPosition = currentPosition;
      await this.setupPlayback(source);
      
      this.showSourceMenu = false;
    } catch (error) {
      Logger.error(this.TAG, `Failed to switch play source: ${error}`);
      this.errorMessage = '切换播放源失败';
      this.isLoading = false;
    }
  }
  
  /**
   * 切换全屏
   */
  private toggleFullscreen(): void {
    this.isFullscreen = !this.isFullscreen;
    // 这里需要处理实际的全屏逻辑，可能需要调用系统API
    Logger.info(this.TAG, `Fullscreen mode: ${this.isFullscreen}`);
  }
  
  /**
   * 处理返回
   */
  private handleBack(): void {
    // 先保存进度
    this.savePlaybackProgress().finally(() => {
      Router.back();
    });
  }
  
  /**
   * 处理屏幕点击
   */
  private handleScreenTap(): void {
    this.showControls = !this.showControls;
    if (this.showControls) {
      this.restartControlsTimeout();
    } else {
      this.stopControlsTimeout();
    }
  }
  
  /**
   * 开始控制栏超时隐藏
   */
  private startControlsTimeout(): void {
    this.stopControlsTimeout();
    this.controlsTimeout = setTimeout(() => {
      if (this.isPlaying && this.playbackState !== PlaybackState.ERROR) {
        this.showControls = false;
      }
    }, 3000); // 3秒后隐藏
  }
  
  /**
   * 重新开始控制栏超时
   */
  private restartControlsTimeout(): void {
    this.startControlsTimeout();
  }
  
  /**
   * 停止控制栏超时
   */
  private stopControlsTimeout(): void {
    if (this.controlsTimeout) {
      clearTimeout(this.controlsTimeout);
      this.controlsTimeout = null;
    }
  }
  
  /**
   * 释放播放器资源
   */
  private async releasePlayer(): Promise<void> {
    try {
      await playbackService.release();
    } catch (error) {
      Logger.error(this.TAG, `Failed to release player: ${error}`);
    }
  }
  
  /**
   * 格式化时间
   */
  private formatTime(seconds: number): string {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const secs = Math.floor(seconds % 60);
    
    if (hours > 0) {
      return `${hours}:${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
    }
    return `${minutes}:${secs.toString().padStart(2, '0')}`;
  }
  
  /**
   * 渲染加载状态
   */
  @Builder
  private renderLoading(): void {
    <Stack className="loading-overlay">
      <LoadingProgress className="loading-progress" color="#FF4500" />
      <Text className="loading-text">正在加载...</Text>
      {this.bufferPercentage > 0 && (
        <Text className="buffer-text">已缓冲 {this.bufferPercentage}%</Text>
      )}
    </Stack>
  }
  
  /**
   * 渲染错误状态
   */
  @Builder
  private renderError(): void {
    <Stack className="error-overlay">
      <Text className="error-icon">⚠️</Text>
      <Text className="error-message">{this.errorMessage}</Text>
      <Button className="retry-button" onClick={() => this.initializePlayback()}>
        重试
      </Button>
    </Stack>
  }
  
  /**
   * 渲染顶部控制栏
   */
  @Builder
  private renderTopControls(): void {
    <Stack className="top-controls">
      <Button className="back-button" onClick={this.handleBack}>
        ← 返回
      </Button>
      <Stack className="title-container">
        <Text className="media-title" numberOfLines={1}>{this.mediaTitle}</Text>
        {this.episodeName && (
          <Text className="episode-name" numberOfLines={1}>{this.episodeName}</Text>
        )}
      </Stack>
      <Button className="settings-button" onClick={() => this.showSpeedMenu = !this.showSpeedMenu}>
        {this.playbackSpeed}x
      </Button>
    </Stack>
  }
  
  /**
   * 渲染底部控制栏
   */
  @Builder
  private renderBottomControls(): void {
    <Stack className="bottom-controls">
      <Button className="play-pause-button" onClick={this.togglePlayPause}>
        {this.isPlaying ? '⏸' : '▶'}
      </Button>
      
      <Stack className="progress-container">
        <Slider
          className="progress-slider"
          value={(this.currentTime / this.duration) * 100 || 0}
          min={0}
          max={100}
          onChange={this.handleProgressChange}
        />
        <Flex className="time-display">
          <Text className="current-time">{this.formatTime(this.currentTime)}</Text>
          <Text className="duration">{this.formatTime(this.duration)}</Text>
        </Flex>
      </Stack>
      
      <Button className="mute-button" onClick={this.toggleMute}>
        {this.isMuted ? '🔇' : '🔊'}
      </Button>
      
      <Stack className="volume-container">
        <Slider
          className="volume-slider"
          value={this.volume * 100}
          min={0}
          max={100}
          onChange={this.handleVolumeChange}
        />
      </Stack>
      
      <Button className="source-button" onClick={() => this.showSourceMenu = !this.showSourceMenu}>
        源
      </Button>
      
      <Button className="fullscreen-button" onClick={this.toggleFullscreen}>
        {this.isFullscreen ? '⤢' : '⤡'}
      </Button>
    </Stack>
  }
  
  /**
   * 渲染播放速度菜单
   */
  @Builder
  private renderSpeedMenu(): void {
    if (!this.showSpeedMenu) return;
    
    <Stack className="speed-menu">
      {playbackService.getSupportedPlaybackSpeeds().map((speed) => (
        <Button
          key={speed}
          className={`speed-option ${this.playbackSpeed === speed ? 'selected' : ''}`}
          onClick={() => this.setPlaybackSpeed(speed)}
        >
          {playbackService.getPlaybackSpeedText(speed)}
        </Button>
      ))}
    </Stack>
  }
  
  /**
   * 渲染播放源菜单
   */
  @Builder
  private renderSourceMenu(): void {
    if (!this.showSourceMenu || this.playSources.length === 0) return;
    
    <List className="source-menu">
      {this.playSources.map((source, index) => (
        <ListItem 
          key={index} 
          onClick={() => this.switchPlaySource(source)}
          className={this.playSource?.url === source.url ? 'selected' : ''}
        >
          <Text className="source-name">{source.name || `播放源${index + 1}`}</Text>
          {source.quality && <Text className="source-quality">{source.quality}</Text>}
        </ListItem>
      ))}
    </List>
  }
  
  /**
   * 组件渲染
   */
  build() {
    <Stack className={`playback-page ${this.isFullscreen ? 'fullscreen' : ''}`} onClick={this.handleScreenTap}>
      {/* 视频播放区域 */}
      <Stack className="video-container">
        {/* 这里应该使用实际的视频播放器组件 */}
        {/* 由于HarmonyOS的Video组件具体API可能不同，这里用占位符表示 */}
        <Image 
          src="https://via.placeholder.com/1920x1080?text=Video+Player" 
          className="video-placeholder"
          objectFit="cover"
        />
        
        {/* 加载状态 */}
        {this.isLoading && this.renderLoading()}
        
        {/* 错误状态 */}
        {this.errorMessage && this.renderError()}
        
        {/* 播放控制界面 */}
        {this.showControls && (
          <Stack className="controls-overlay">
            {this.renderTopControls()}
            {this.renderBottomControls()}
          </Stack>
        )}
        
        {/* 播放速度菜单 */}
        {this.renderSpeedMenu()}
        
        {/* 播放源菜单 */}
        {this.renderSourceMenu()}
      </Stack>
    </Stack>
  }
}

export default PlaybackPage;