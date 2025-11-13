import { Stack, Video, Image, Text, Button, Slider, List, ListItem, LoadingProgress, Toast, PromptAction } from '@kit.ArkUI';
import Router from '@ohos.router';
import Logger from '../common/util/Logger';
import { playbackService } from '../service/media/PlaybackService';
import { historyService } from '../service/media/HistoryService';
import { mediaService } from '../service/media/MediaService';
import { configService } from '../service/config/ConfigService';
import { PlaybackState, PlaybackSpeed, PlaySource, Subtitle } from '../service/media/PlaybackService';

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
  @State filteredSources: PlaySource[] = [];
  @State searchText: string = '';
  @State subtitles: Subtitle[] = [];
  @State selectedSubtitle: Subtitle | null = null;
  @State isFullscreen: boolean = false;
  @State errorMessage: string = '';
  @State isLoading: boolean = true;
  @State controlsTimeout: number | null = null;
  @State lastProgressSaveTime: number = 0;
  @State saveProgressInterval: number = 30000; // 30秒保存一次进度
  @State searchFocused: boolean = false;
  private autoSwitchSourceOnError: boolean = true; // 是否自动切换片源
  private lastSaveTime: number = 0; // 上次保存进度的时间(毫秒)
  private currentPosition: number = 0; // 当前播放位置
  private totalTime: number = 0;
  
  // 初始化
  /**
   * 页面加载时调用
   */
  aboutToAppear(): void {
    Logger.info(this.TAG, 'PlaybackPage appeared');
    
    // 获取路由参数
    const params = this.context.router.getParams();
    this.mediaId = (params?.mediaId as string) || '';
    this.siteKey = (params?.siteKey as string) || '';
    this.episodeId = params?.episodeId;
    this.initialPosition = (params?.currentTime as number) || (params?.startPosition as number) || 0;
    this.mediaTitle = (params?.mediaTitle as string) || '正在播放';
    this.episodeName = (params?.episodeName as string) || '';
    this.playSource = params?.playSource;
    this.playSourceIndex = (params?.playSourceIndex as number) || 0;
    this.autoSwitchSourceOnError = params?.autoSwitchSourceOnError !== false; // 默认开启
    
    Logger.info(this.TAG, `Starting playback for: ${this.siteKey}:${this.mediaId}${this.episodeId ? ` episode: ${this.episodeId}` : ''}, startPosition=${this.initialPosition}`);
    
    // 初始化播放器
    this.initializePlayback();
    
    // 设置控制栏自动隐藏
    this.startControlsTimeout();
  }
  
  /**
     * 页面卸载时调用
     */
    aboutToDisappear(): void {
      Logger.info(this.TAG, 'PlaybackPage disappeared');
      this.cleanupPlayer();
    }

    /**
     * 清理播放器资源
     */
    private cleanupPlayer(): void {
      // 移除播放监听器
      playbackService.removeAllListeners();
      
      // 保存最终播放进度
    this.savePlayProgress(this.currentPosition);
    
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
  private initializePlayback(): void {
    if (!this.mediaId || !this.siteKey) {
      this.errorMessage = '缺少必要参数';
      this.isLoading = false;
      this.playbackState = PlaybackState.ERROR;
      return;
    }
    
    try {
      // 加载播放源
      this.loadPlaySources().then(() => {
        // 初始化过滤后的片源列表
        this.filteredSources = [...this.playSources];
        
        // 设置播放源并开始播放
        if (this.playSource) {
          this.setupPlayback(this.playSource);
        } else if (this.playSources.length > 0 && this.playSourceIndex < this.playSources.length) {
          this.setupPlayback(this.playSources[this.playSourceIndex]);
        } else {
          this.errorMessage = '无可用播放源';
          this.isLoading = false;
          this.playbackState = PlaybackState.ERROR;
        }
      }).catch((error) => {
        Logger.error(this.TAG, `Failed to initialize playback: ${error}`);
        this.errorMessage = '播放初始化失败';
        this.isLoading = false;
        this.playbackState = PlaybackState.ERROR;
      });
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
  private loadPlaySources(): Promise<void> {
    return new Promise<void>((resolve, reject) => {
      try {
        // 如果没有传入播放源，则从服务获取
        if (!this.playSource || this.playSources.length === 0) {
          mediaService.getPlaySources(
            this.mediaId,
            this.siteKey,
            this.episodeId
          ).then((sources) => {
            this.playSources = sources;
            Logger.info(this.TAG, `Loaded ${this.playSources.length} play sources`);
            
            // 如果只有一个播放源，则使用它
            if (this.playSources.length === 1 && !this.playSource) {
              this.playSource = this.playSources[0];
            }
            resolve();
          }).catch((error) => {
            Logger.error(this.TAG, `Failed to load play sources: ${error}`);
            reject(error);
          });
        } else {
          resolve();
        }
      } catch (error) {
        Logger.error(this.TAG, `Failed to load play sources: ${error}`);
        reject(error);
      }
    });
  }
  
  /**
   * 设置播放
   */
  private setupPlayback(source: PlaySource): void {
    try {
      // 添加播放监听器
      this.addPlaybackListeners();
      
      // 设置播放源
      playbackService.setSource(source, {
        autoPlay: true,
        startPosition: this.initialPosition,
        volume: this.volume,
        isMuted: this.isMuted,
        playbackSpeed: this.playbackSpeed
      }).then(() => {
        this.playSource = source;
        this.isLoading = false;
      }).catch((error) => {
        Logger.error(this.TAG, `Failed to setup playback: ${error}`);
        
        // 尝试自动切换到下一个片源
        if (this.autoSwitchSourceOnError) {
          this.handlePlaybackError(error);
        } else {
          this.errorMessage = '播放设置失败';
          this.isLoading = false;
          this.playbackState = PlaybackState.ERROR;
        }
      });
    } catch (error) {
      Logger.error(this.TAG, `Failed to setup playback: ${error}`);
      
      // 尝试自动切换到下一个片源
      if (this.autoSwitchSourceOnError) {
        this.handlePlaybackError(error);
      } else {
        this.errorMessage = '播放设置失败';
        this.isLoading = false;
        this.playbackState = PlaybackState.ERROR;
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
      
      onError: (error: Error) => {
        Logger.error(this.TAG, `Playback error: ${error}`);
        
        // 尝试自动切换片源
        if (this.autoSwitchSourceOnError) {
          this.handlePlaybackError(error);
        } else {
          this.errorMessage = `播放错误: ${error.message || '未知错误'}`;
        }
      },
      
      // 定期保存播放进度
      onTimeUpdate: (currentTime, duration) => {
        this.currentTime = currentTime;
        this.currentPosition = currentTime;
        this.duration = duration;
        this.totalTime = duration || this.totalTime;
        
        // 每10秒保存一次播放进度
        if (this.lastSaveTime === 0 || currentTime - this.lastSaveTime > 10000) {
          this.savePlayProgress(currentTime);
          this.lastSaveTime = currentTime;
        }
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
  private handlePlaybackCompleted(): void {
    try {
      // 保存完成的播放状态
      historyService.updateProgress(
        this.mediaId,
        this.siteKey,
        this.duration, // 标记为已完成
        this.episodeId,
        true // 标记为已完成
      ).then(() => {
        Toast.show('播放完成');
      }).catch((error) => {
        Logger.error(this.TAG, `Failed to handle playback completed: ${error}`);
        Toast.show('播放完成');
      });
    } catch (error) {
      Logger.error(this.TAG, `Failed to handle playback completed: ${error}`);
      Toast.show('播放完成');
    }
  }
  
  /**
   * 保存播放进度
   */
  private savePlaybackProgress(): void {
    try {
      playbackService.savePlaybackPosition(
        this.mediaId,
        this.siteKey,
        this.episodeId
      ).catch((error) => {
        Logger.error(this.TAG, `Failed to save playback progress: ${error}`);
      });
    } catch (error) {
      Logger.error(this.TAG, `Failed to save playback progress: ${error}`);
    }
  }
  
  /**
   * 处理搜索文本变化
   */
  private handleSearchChange(text: string) {
    this.searchText = text;
    
    // 根据搜索文本过滤片源
    if (text.trim()) {
      const searchLower = text.toLowerCase();
      this.filteredSources = this.playSources.filter(source => 
        (source.name && source.name.toLowerCase().includes(searchLower)) ||
        (source.description && source.description.toLowerCase().includes(searchLower))
      );
    } else {
      // 如果搜索文本为空，显示所有片源
      this.filteredSources = [...this.playSources];
    }
  }
  
  /**
   * 处理搜索框焦点变化
   */
  private handleSearchFocusChange(focused: boolean) {
    this.searchFocused = focused;
  }
  
  /**
   * 清除搜索文本
   */
  private clearSearchText() {
    this.searchText = '';
    this.filteredSources = [...this.playSources];
  }
  
  /**
   * 切换播放/暂停
   */
  private togglePlayPause(): void {
    try {
      if (this.isPlaying) {
        playbackService.pause().catch((error) => {
          Logger.error(this.TAG, `Failed to pause playback: ${error}`);
        });
      } else {
        playbackService.play().catch((error) => {
          Logger.error(this.TAG, `Failed to play: ${error}`);
        });
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
  private handleProgressChange(value: number): void {
    try {
      const seekTime = (value / 100) * this.duration;
      playbackService.seekTo(seekTime).then(() => {
        this.showControls = true;
        this.restartControlsTimeout();
      }).catch((error) => {
        Logger.error(this.TAG, `Failed to seek: ${error}`);
      });
    } catch (error) {
      Logger.error(this.TAG, `Failed to seek: ${error}`);
    }
  }
  
  /**
   * 处理音量变化
   */
  private handleVolumeChange(value: number): void {
    try {
      this.volume = value;
      if (this.isMuted && value > 0) {
        this.isMuted = false;
      }
      playbackService.setVolume(value).catch((error) => {
        Logger.error(this.TAG, `Failed to set volume: ${error}`);
      });
    } catch (error) {
      Logger.error(this.TAG, `Failed to set volume: ${error}`);
    }
  }
  
  /**
   * 切换静音
   */
  private toggleMute(): void {
    try {
      const newMuteState = !this.isMuted;
      playbackService.setMuted(newMuteState).then(() => {
        this.isMuted = newMuteState;
      }).catch((error) => {
        Logger.error(this.TAG, `Failed to toggle mute: ${error}`);
      });
    } catch (error) {
      Logger.error(this.TAG, `Failed to toggle mute: ${error}`);
    }
  }
  
  /**
   * 设置播放速度
   */
  private setPlaybackSpeed(speed: PlaybackSpeed): void {
    try {
      this.playbackSpeed = speed;
      playbackService.setPlaybackSpeed(speed).then(() => {
        this.showSpeedMenu = false;
      }).catch((error) => {
        Logger.error(this.TAG, `Failed to set playback speed: ${error}`);
      });
    } catch (error) {
      Logger.error(this.TAG, `Failed to set playback speed: ${error}`);
    }
  }
  
  /**
   * 保存播放进度
   */
  private savePlayProgress(position: number): void {
    if (!this.mediaId || !this.siteKey || !this.episodeId) return;
    
    try {
      const duration = this.totalTime || this.duration;
      
      // 保存播放进度到历史记录
      historyService.saveWatchProgress(
        this.mediaId,
        this.siteKey,
        this.episodeId,
        position,
        duration
      ).then(() => {
        Logger.info(this.TAG, `Saved playback progress: ${position}ms of ${duration}ms`);
      }).catch((error) => {
        Logger.error(this.TAG, `Failed to save play progress: ${error}`);
      });
    } catch (error) {
      Logger.error(this.TAG, `Failed to save play progress: ${error}`);
    }
  }
  
  /**
   * 处理播放错误，尝试切换到下一个可用片源
   */
  private handlePlaybackError(error: Error): void {
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
      
      // 保存当前播放位置
      const currentPosition = this.currentPosition;
      
      // 切换到下一个片源
      this.initialPosition = currentPosition; // 保持相同的播放位置
      this.setupPlayback(this.playSources[nextIndex]);
      this.errorMessage = '';
    } else {
      this.errorMessage = '播放失败，无法识别当前片源';
      this.isLoading = false;
    }
  }
  
  /**
   * 切换播放源
   */
  private switchPlaySource(source: PlaySource): void {
    try {
      this.isLoading = true;
      this.playbackState = PlaybackState.BUFFERING;
      
      // 保存当前播放位置
      const currentPosition = this.currentPosition;
      
      // 设置新的播放源
      this.setupPlayback(source);
      
      // 恢复播放位置
      if (currentPosition > 0) {
        playbackService.seek(currentPosition).catch((error) => {
          Logger.error(this.TAG, `Failed to seek to position after switching source: ${error}`);
        });
      }
      
      this.isLoading = false;
      this.showSourceMenu = false;
      
      // 显示切换成功提示
      Toast.show('片源切换成功');
    } catch (error) {
      Logger.error(this.TAG, `Failed to switch play source: ${error}`);
      this.errorMessage = '切换播放源失败';
      this.isLoading = false;
      this.playbackState = PlaybackState.ERROR;
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
    this.savePlaybackProgress();
    this.context.router.back();
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
  private releasePlayer(): void {
    try {
      // 保存当前播放进度
      this.savePlaybackProgress();
      
      // 移除播放监听器
      playbackService.removeAllListeners();
      
      // 释放播放器资源
      playbackService.release().catch((error) => {
        Logger.error(this.TAG, `Failed to release player: ${error}`);
      });
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
    Stack.create();
    Stack.className("loading-overlay");
    LoadingProgress.create();
    LoadingProgress.className("loading-progress");
    LoadingProgress.color("#FF4500");
    LoadingProgress.pop();
    Text.create();
    Text.className("loading-text");
    Text.content("正在加载...");
    Text.pop();
    if (this.bufferPercentage > 0) {
      Text.create();
      Text.className("buffer-text");
      Text.content(`已缓冲 ${this.bufferPercentage}%`);
      Text.pop();
    }
    Stack.pop();
  }
  
  /**
   * 渲染错误状态
   */
  @Builder
  private renderError(): void {
    Stack.create();
    Stack.className("error-overlay");
    Text.create();
    Text.className("error-icon");
    Text.content("⚠️");
    Text.pop();
    Text.create();
    Text.className("error-message");
    Text.content(this.errorMessage);
    Text.pop();
    Button.create();
    Button.className("retry-button");
    Button.onClick(() => this.initializePlayback());
    Text.create();
    Text.content("重试");
    Text.pop();
    Button.pop();
    Stack.pop();
  }
  
  /**
   * 渲染顶部控制栏
   */
  @Builder
  private renderTopControls(): void {
    Stack.create();
    Stack.className("top-controls");
    Button.create();
    Button.className("back-button");
    Button.onClick(this.handleBack);
    Text.create();
    Text.content("← 返回");
    Text.pop();
    Button.pop();
    Stack.create();
    Stack.className("title-container");
    Text.create();
    Text.className("media-title");
    Text.numberOfLines(1);
    Text.content(this.mediaTitle);
    Text.pop();
    if (this.episodeName) {
      Text.create();
      Text.className("episode-name");
      Text.numberOfLines(1);
      Text.content(this.episodeName);
      Text.pop();
    }
    Stack.pop();
    Button.create();
    Button.className("settings-button");
    Button.onClick(() => this.showSpeedMenu = !this.showSpeedMenu);
    Text.create();
    Text.content(`${this.playbackSpeed}x`);
    Text.pop();
    Button.pop();
    Stack.pop();
  }
  
  /**
   * 渲染底部控制栏
   */
  @Builder
  private renderBottomControls(): void {
    Stack.create();
    Stack.className("bottom-controls");
    Button.create();
    Button.className("play-pause-button");
    Button.onClick(this.togglePlayPause);
    Text.create();
    Text.content(this.isPlaying ? '⏸' : '▶');
    Text.pop();
    Button.pop();
    
    Stack.create();
    Stack.className("progress-container");
    Slider.create();
    Slider.className("progress-slider");
    Slider.value((this.currentTime / this.duration) * 100 || 0);
    Slider.min(0);
    Slider.max(100);
    Slider.onChange(this.handleProgressChange);
    Slider.pop();
    Flex.create();
    Flex.className("time-display");
    Text.create();
    Text.className("current-time");
    Text.content(this.formatTime(this.currentTime));
    Text.pop();
    Text.create();
    Text.className("duration");
    Text.content(this.formatTime(this.duration));
    Text.pop();
    Flex.pop();
    Stack.pop();
    
    Button.create();
    Button.className("mute-button");
    Button.onClick(this.toggleMute);
    Text.create();
    Text.content(this.isMuted ? '🔇' : '🔊');
    Text.pop();
    Button.pop();
    
    Stack.create();
    Stack.className("volume-container");
    Slider.create();
    Slider.className("volume-slider");
    Slider.value(this.volume * 100);
    Slider.min(0);
    Slider.max(100);
    Slider.onChange(this.handleVolumeChange);
    Slider.pop();
    Stack.pop();
    
    Button.create();
    Button.className("source-button");
    Button.onClick(() => this.showSourceMenu = !this.showSourceMenu);
    Text.create();
    Text.content("源");
    Text.pop();
    Button.pop();
    
    Button.create();
    Button.className("fullscreen-button");
    Button.onClick(this.toggleFullscreen);
    Text.create();
    Text.content(this.isFullscreen ? '⤢' : '⤡');
    Text.pop();
    Button.pop();
    Stack.pop();
  }
  
  /**
   * 渲染播放速度菜单
   */
  @Builder
  private renderSpeedMenu(): void {
    if (!this.showSpeedMenu) return;
    
    Stack.create();
    Stack.className("speed-menu");
    playbackService.getSupportedPlaybackSpeeds().forEach((speed) => {
      Button.create();
      Button.key(speed.toString());
      Button.className(`speed-option ${this.playbackSpeed === speed ? 'selected' : ''}`);
      Button.onClick(() => this.setPlaybackSpeed(speed));
      Text.create();
      Text.content(playbackService.getPlaybackSpeedText(speed));
      Text.pop();
      Button.pop();
    });
    Stack.pop();
  }
  
  /**
   * 渲染播放源菜单
   */
  @Builder
  private renderSourceMenu(): void {
    if (!this.showSourceMenu) return;
    
    Stack.create();
    Stack.style({
      position: 'absolute',
      bottom: 0,
      left: 0,
      right: 0,
      backgroundColor: '#4CAF50',
      height: '80%',
      borderTopLeftRadius: 20,
      borderTopRightRadius: 20,
      padding: 20,
      zIndex: 1000
    });
    
    // 菜单标题
    Flex.create();
    Flex.style({
      flexDirection: 'row',
      alignItems: 'center',
      justifyContent: 'space-between',
      marginBottom: 20
    });
    Text.create();
    Text.style({
      fontSize: 28,
      color: '#FFFFFF',
      fontWeight: 700
    });
    Text.content('切换片源');
    Text.pop();
    Button.create();
    Button.style({
      backgroundColor: 'transparent'
    });
    Button.onClick(() => this.showSourceMenu = false);
    Text.create();
    Text.style({
      fontSize: 24,
      color: '#FFFFFF'
    });
    Text.content('✕');
    Text.pop();
    Button.pop();
    Flex.pop();
    
    // 搜索框
    Stack.create();
    Stack.style({
      flexDirection: 'row',
      alignItems: 'center',
      backgroundColor: '#FFFFFF',
      borderRadius: 25,
      paddingHorizontal: 20,
      marginBottom: 20,
      height: 50
    });
    Text.create();
    Text.style({
      fontSize: 24,
      color: '#999999',
      marginRight: 10
    });
    Text.content('🔍');
    Text.pop();
    TextInput.create();
    TextInput.style({
      flex: 1,
      fontSize: 24,
      color: '#333333'
    });
    TextInput.value(this.searchText);
    TextInput.onChange((text) => this.handleSearchChange(text));
    TextInput.onFocusChange((focused) => this.handleSearchFocusChange(focused));
    TextInput.placeholder('搜索片源...');
    TextInput.placeholderColor('#999999');
    TextInput.pop();
    if (this.searchText.length > 0) {
      Button.create();
      Button.style({
        backgroundColor: 'transparent'
      });
      Button.onClick(() => this.clearSearchText());
      Text.create();
      Text.style({
        fontSize: 24,
        color: '#999999'
      });
      Text.content('✕');
      Text.pop();
      Button.pop();
    }
    Stack.pop();
    
    // 搜索结果数量提示
    Text.create();
    Text.style({
      fontSize: 24,
      color: '#FFFFFF',
      fontWeight: 600,
      marginBottom: 10
    });
    Text.content(`共找到 ${this.filteredSources.length} 个片源`);
    Text.pop();
    
    // 片源列表
    if (this.filteredSources.length === 0) {
      Stack.create();
      Stack.style({
        flex: 1,
        justifyContent: 'center',
        alignItems: 'center'
      });
      Text.create();
      Text.style({
        fontSize: 24,
        color: '#FFFFFF'
      });
      Text.content('暂无匹配的片源');
      Text.pop();
      Stack.pop();
    } else {
      List.create();
      List.style({
        flex: 1
      });
      this.filteredSources.forEach((source, index) => {
        ListItem.create();
        ListItem.key(index.toString());
        ListItem.style({
          paddingVertical: 15
        });
        Button.create();
        Button.style({
          backgroundColor: '#66BB6A',
          padding: 20,
          borderRadius: 10,
          width: '100%'
        });
        Button.onClick(() => {
          this.switchPlaySource(source);
          this.showSourceMenu = false;
        });
        Flex.create();
        Flex.style({
          flexDirection: 'row',
          alignItems: 'center',
          justifyContent: 'space-between',
          width: '100%'
        });
        Text.create();
        Text.style({
          fontSize: 26,
          color: '#FFFFFF',
          fontWeight: 600
        });
        Text.content(source.name || `播放源${index + 1}`);
        Text.pop();
        if (source.quality) {
          Flex.create();
          Flex.style({
            backgroundColor: '#FFEB3B',
            paddingHorizontal: 12,
            paddingVertical: 4,
            borderRadius: 12
          });
          Text.create();
          Text.style({
            fontSize: 20,
            color: '#000000',
            fontWeight: 700
          });
          Text.content(source.quality);
          Text.pop();
          Flex.pop();
        }
        Flex.pop();
        Button.pop();
        ListItem.pop();
      });
      List.pop();
    }
    
    Stack.pop();
  }
  
  /**
   * 组件渲染
   */
  build() {
    Stack.create();
    Stack.className(`playback-page ${this.isFullscreen ? 'fullscreen' : ''}`);
    Stack.onClick(this.handleScreenTap);
    
    // 视频播放区域
    Stack.create();
    Stack.className("video-container");
    
    // 这里应该使用实际的视频播放器组件
    // 由于HarmonyOS的Video组件具体API可能不同，这里用占位符表示
    Image.create();
    Image.src("https://via.placeholder.com/1920x1080?text=Video+Player");
    Image.className("video-placeholder");
    Image.objectFit("cover");
    Image.pop();
    
    // 加载状态
    if (this.isLoading) {
      this.renderLoading();
    }
    
    // 错误状态
    if (this.errorMessage) {
      this.renderError();
    }
    
    // 播放控制界面
    if (this.showControls) {
      Stack.create();
      Stack.className("controls-overlay");
      this.renderTopControls();
      this.renderBottomControls();
      Stack.pop();
    }
    
    // 播放速度菜单
    this.renderSpeedMenu();
    
    // 播放源菜单
    this.renderSourceMenu();
    
    Stack.pop();
    Stack.pop();
  }
}

export default PlaybackPage;