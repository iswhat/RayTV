import { Stack, Video, Image, Button, Slider, List, ListItem, LoadingProgress, Toast, PromptAction } from '@kit.ArkUI';
import Router from '@ohos.router';
import Logger from '../common/util/Logger';
import { playbackService } from '../service/media/PlaybackService';
import { historyService } from '../service/media/HistoryService';
import { mediaService } from '../service/media/MediaService';
import { configService } from '../service/config/ConfigService';
import { PlaybackState, PlaybackSpeed, PlaySource, Subtitle } from '../service/media/PlaybackService';

/**
 * 播放页面组件
 * 实现视频播放控制界面，包含播�?暂停、进度控制、音量控制、速度调整等功�? */
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
  
  // 状态管�?  @State playbackState: PlaybackState = PlaybackState.IDLE;
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
  @State saveProgressInterval: number = 30000; // 30秒保存一次进�?  @State searchFocused: boolean = false;
  private autoSwitchSourceOnError: boolean = true; // 是否自动切换片源
  private lastSaveTime: number = 0; // 上次保存进度的时�?毫秒)
  private currentPosition: number = 0; // 当前播放位置
  private totalTime: number = 0;
  
  // 初始�?  /**
   * 页面加载时调�?   */
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
    this.autoSwitchSourceOnError = params?.autoSwitchSourceOnError !== false; // 默认开�?    
    Logger.info(this.TAG, `Starting playback for: ${this.siteKey}:${this.mediaId}${this.episodeId ? ` episode: ${this.episodeId}` : ''}, startPosition=${this.initialPosition}`);
    
    // 初始化播放器
    this.initializePlayback();
    
    // 设置控制栏自动隐�?    this.startControlsTimeout();
  }
  
  /**
     * 页面卸载时调�?     */
    aboutToDisappear(): void {
      Logger.info(this.TAG, 'PlaybackPage disappeared');
      this.cleanupPlayer();
    }

    /**
     * 清理播放器资�?     */
    private cleanupPlayer(): void {
      // 移除播放监听�?      playbackService.removeAllListeners();
      
      // 保存最终播放进�?    this.savePlayProgress(this.currentPosition);
    
    // 停止控制栏超�?    this.stopControlsTimeout();
    
    // 释放播放器资�?    this.releasePlayer();
    playbackService.stop();
    playbackService.destroy();
  }
  
  /**
   * 初始化播�?   */
  private initializePlayback(): void {
    if (!this.mediaId || !this.siteKey) {
      this.errorMessage = '缺少必要参数';
      this.isLoading = false;
      this.playbackState = PlaybackState.ERROR;
      return;
    }
    
    try {
      // 加载播放�?      this.loadPlaySources().then(() => {
        // 初始化过滤后的片源列�?        this.filteredSources = [...this.playSources];
        
        // 设置播放源并开始播�?        if (this.playSource) {
          this.setupPlayback(this.playSource);
        } else if (this.playSources.length > 0 && this.playSourceIndex < this.playSources.length) {
          this.setupPlayback(this.playSources[this.playSourceIndex]);
        } else {
          this.errorMessage = '无可用播放源';
          this.isLoading = false;
          this.playbackState = PlaybackState.ERROR;
        }
      }).catch((error) => {
        Logger.error(this.TAG, 'Failed to initialize playback', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))))));
        this.errorMessage = '播放初始化失�?;
        this.isLoading = false;
        this.playbackState = PlaybackState.ERROR;
      });
    } catch (error) {
      Logger.error(this.TAG, `Failed to initialize playback: ${error}`);
      this.errorMessage = '播放初始化失�?;
      this.isLoading = false;
      this.playbackState = PlaybackState.ERROR;
    }
  }
  
  /**
   * 加载播放�?   */
  private loadPlaySources(): Promise<void> {
    return new Promise<void>((resolve, reject instanceof Error ? reject : new Error(String(reject instanceof Error ? reject instanceof Error ? reject : new Error(String(reject : new Error(String(reject instanceof Error ? reject : new Error(String(reject instanceof Error ? reject instanceof Error ? reject : new Error(String(reject instanceof Error ? reject instanceof Error ? reject : new Error(String(reject : new Error(String(reject instanceof Error ? reject : new Error(String(reject : new Error(String(reject instanceof Error ? reject : new Error(String(reject instanceof Error ? reject instanceof Error ? reject : new Error(String(reject : new Error(String(reject instanceof Error ? reject : new Error(String(reject))))))) => {
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
            
            // 如果只有一个播放源，则使用�?            if (this.playSources.length === 1 && !this.playSource) {
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
        Logger.error(this.TAG, `Failed to load play sources: ${error}` instanceof Error ? `Failed to load play sources: ${error}` : new Error(String(`Failed to load play sources: ${error}` instanceof Error ? `Failed to load play sources: ${error}` instanceof Error ? `Failed to load play sources: ${error}` : new Error(String(`Failed to load play sources: ${error}` : new Error(String(`Failed to load play sources: ${error}` instanceof Error ? `Failed to load play sources: ${error}` : new Error(String(`Failed to load play sources: ${error}` instanceof Error ? `Failed to load play sources: ${error}` instanceof Error ? `Failed to load play sources: ${error}` : new Error(String(`Failed to load play sources: ${error}` instanceof Error ? `Failed to load play sources: ${error}` instanceof Error ? `Failed to load play sources: ${error}` : new Error(String(`Failed to load play sources: ${error}` : new Error(String(`Failed to load play sources: ${error}` instanceof Error ? `Failed to load play sources: ${error}` : new Error(String(`Failed to load play sources: ${error}` : new Error(String(`Failed to load play sources: ${error}` instanceof Error ? `Failed to load play sources: ${error}` : new Error(String(`Failed to load play sources: ${error}` instanceof Error ? `Failed to load play sources: ${error}` instanceof Error ? `Failed to load play sources: ${error}` : new Error(String(`Failed to load play sources: ${error}` : new Error(String(`Failed to load play sources: ${error}` instanceof Error ? `Failed to load play sources: ${error}` : new Error(String(`Failed to load play sources: ${error}`)))))));
        reject(error);
      }
    });
  }
  
  /**
   * 设置播放
   */
  private setupPlayback(source: PlaySource): void {
    try {
      // 添加播放监听�?      this.addPlaybackListeners();
      
      // 设置播放�?      playbackService.setSource(source, {
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
        
        // 尝试自动切换到下一个片�?        if (this.autoSwitchSourceOnError) {
          this.handlePlaybackError(error);
        } else {
          this.errorMessage = '播放设置失败';
          this.isLoading = false;
          this.playbackState = PlaybackState.ERROR;
        }
      });
    } catch (error) {
      Logger.error(this.TAG, `Failed to setup playback: ${error}` instanceof Error ? `Failed to setup playback: ${error}` : new Error(String(`Failed to setup playback: ${error}` instanceof Error ? `Failed to setup playback: ${error}` instanceof Error ? `Failed to setup playback: ${error}` : new Error(String(`Failed to setup playback: ${error}` : new Error(String(`Failed to setup playback: ${error}` instanceof Error ? `Failed to setup playback: ${error}` : new Error(String(`Failed to setup playback: ${error}` instanceof Error ? `Failed to setup playback: ${error}` instanceof Error ? `Failed to setup playback: ${error}` : new Error(String(`Failed to setup playback: ${error}` instanceof Error ? `Failed to setup playback: ${error}` instanceof Error ? `Failed to setup playback: ${error}` : new Error(String(`Failed to setup playback: ${error}` : new Error(String(`Failed to setup playback: ${error}` instanceof Error ? `Failed to setup playback: ${error}` : new Error(String(`Failed to setup playback: ${error}` : new Error(String(`Failed to setup playback: ${error}` instanceof Error ? `Failed to setup playback: ${error}` : new Error(String(`Failed to setup playback: ${error}` instanceof Error ? `Failed to setup playback: ${error}` instanceof Error ? `Failed to setup playback: ${error}` : new Error(String(`Failed to setup playback: ${error}` : new Error(String(`Failed to setup playback: ${error}` instanceof Error ? `Failed to setup playback: ${error}` : new Error(String(`Failed to setup playback: ${error}`)))))));
      
      // 尝试自动切换到下一个片�?      if (this.autoSwitchSourceOnError) {
        this.handlePlaybackError(error);
      } else {
        this.errorMessage = '播放设置失败';
        this.isLoading = false;
        this.playbackState = PlaybackState.ERROR;
      }
    }
  }
  
  /**
   * 添加播放监听�?   */
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
      }, // 定期保存播放进度
      onTimeUpdate: (currentTime, duration instanceof Error ? // 定期保存播放进度
      onTimeUpdate: (currentTime, duration : new Error(String(// 定期保存播放进度
      onTimeUpdate: (currentTime, duration instanceof Error ? // 定期保存播放进度
      onTimeUpdate: (currentTime, duration instanceof Error ? // 定期保存播放进度
      onTimeUpdate: (currentTime, duration : new Error(String(// 定期保存播放进度
      onTimeUpdate: (currentTime, duration : new Error(String(// 定期保存播放进度
      onTimeUpdate: (currentTime, duration instanceof Error ? // 定期保存播放进度
      onTimeUpdate: (currentTime, duration : new Error(String(// 定期保存播放进度
      onTimeUpdate: (currentTime, duration instanceof Error ? // 定期保存播放进度
      onTimeUpdate: (currentTime, duration instanceof Error ? // 定期保存播放进度
      onTimeUpdate: (currentTime, duration : new Error(String(// 定期保存播放进度
      onTimeUpdate: (currentTime, duration instanceof Error ? // 定期保存播放进度
      onTimeUpdate: (currentTime, duration instanceof Error ? // 定期保存播放进度
      onTimeUpdate: (currentTime, duration : new Error(String(// 定期保存播放进度
      onTimeUpdate: (currentTime, duration : new Error(String(// 定期保存播放进度
      onTimeUpdate: (currentTime, duration instanceof Error ? // 定期保存播放进度
      onTimeUpdate: (currentTime, duration : new Error(String(// 定期保存播放进度
      onTimeUpdate: (currentTime, duration : new Error(String(// 定期保存播放进度
      onTimeUpdate: (currentTime, duration instanceof Error ? // 定期保存播放进度
      onTimeUpdate: (currentTime, duration : new Error(String(// 定期保存播放进度
      onTimeUpdate: (currentTime, duration instanceof Error ? // 定期保存播放进度
      onTimeUpdate: (currentTime, duration instanceof Error ? // 定期保存播放进度
      onTimeUpdate: (currentTime, duration : new Error(String(// 定期保存播放进度
      onTimeUpdate: (currentTime, duration : new Error(String(// 定期保存播放进度
      onTimeUpdate: (currentTime, duration instanceof Error ? // 定期保存播放进度
      onTimeUpdate: (currentTime, duration : new Error(String(// 定期保存播放进度
      onTimeUpdate: (currentTime, duration))))))) => {
        this.currentTime = currentTime;
        this.currentPosition = currentTime;
        this.duration = duration;
        this.totalTime = duration || this.totalTime;
        
        // �?0秒保存一次播放进�?        if (this.lastSaveTime === 0 || currentTime - this.lastSaveTime > 10000) {
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
      // 保存完成的播放状�?      historyService.updateProgress(
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
      Logger.error(this.TAG, `Failed to handle playback completed: ${error}` instanceof Error ? `Failed to handle playback completed: ${error}` : new Error(String(`Failed to handle playback completed: ${error}` instanceof Error ? `Failed to handle playback completed: ${error}` instanceof Error ? `Failed to handle playback completed: ${error}` : new Error(String(`Failed to handle playback completed: ${error}` : new Error(String(`Failed to handle playback completed: ${error}` instanceof Error ? `Failed to handle playback completed: ${error}` : new Error(String(`Failed to handle playback completed: ${error}` instanceof Error ? `Failed to handle playback completed: ${error}` instanceof Error ? `Failed to handle playback completed: ${error}` : new Error(String(`Failed to handle playback completed: ${error}` instanceof Error ? `Failed to handle playback completed: ${error}` instanceof Error ? `Failed to handle playback completed: ${error}` : new Error(String(`Failed to handle playback completed: ${error}` : new Error(String(`Failed to handle playback completed: ${error}` instanceof Error ? `Failed to handle playback completed: ${error}` : new Error(String(`Failed to handle playback completed: ${error}` : new Error(String(`Failed to handle playback completed: ${error}` instanceof Error ? `Failed to handle playback completed: ${error}` : new Error(String(`Failed to handle playback completed: ${error}` instanceof Error ? `Failed to handle playback completed: ${error}` instanceof Error ? `Failed to handle playback completed: ${error}` : new Error(String(`Failed to handle playback completed: ${error}` : new Error(String(`Failed to handle playback completed: ${error}` instanceof Error ? `Failed to handle playback completed: ${error}` : new Error(String(`Failed to handle playback completed: ${error}`)))))));
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
      Logger.error(this.TAG, `Failed to save playback progress: ${error}` instanceof Error ? `Failed to save playback progress: ${error}` : new Error(String(`Failed to save playback progress: ${error}` instanceof Error ? `Failed to save playback progress: ${error}` instanceof Error ? `Failed to save playback progress: ${error}` : new Error(String(`Failed to save playback progress: ${error}` : new Error(String(`Failed to save playback progress: ${error}` instanceof Error ? `Failed to save playback progress: ${error}` : new Error(String(`Failed to save playback progress: ${error}` instanceof Error ? `Failed to save playback progress: ${error}` instanceof Error ? `Failed to save playback progress: ${error}` : new Error(String(`Failed to save playback progress: ${error}` instanceof Error ? `Failed to save playback progress: ${error}` instanceof Error ? `Failed to save playback progress: ${error}` : new Error(String(`Failed to save playback progress: ${error}` : new Error(String(`Failed to save playback progress: ${error}` instanceof Error ? `Failed to save playback progress: ${error}` : new Error(String(`Failed to save playback progress: ${error}` : new Error(String(`Failed to save playback progress: ${error}` instanceof Error ? `Failed to save playback progress: ${error}` : new Error(String(`Failed to save playback progress: ${error}` instanceof Error ? `Failed to save playback progress: ${error}` instanceof Error ? `Failed to save playback progress: ${error}` : new Error(String(`Failed to save playback progress: ${error}` : new Error(String(`Failed to save playback progress: ${error}` instanceof Error ? `Failed to save playback progress: ${error}` : new Error(String(`Failed to save playback progress: ${error}`)))))));
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
      // 如果搜索文本为空，显示所有片�?      this.filteredSources = [...this.playSources];
    }
  }
  
  /**
   * 处理搜索框焦点变�?   */
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
          Logger.error(this.TAG, `Failed to play: ${error}` instanceof Error ? `Failed to play: ${error}` : new Error(String(`Failed to play: ${error}` instanceof Error ? `Failed to play: ${error}` instanceof Error ? `Failed to play: ${error}` : new Error(String(`Failed to play: ${error}` : new Error(String(`Failed to play: ${error}` instanceof Error ? `Failed to play: ${error}` : new Error(String(`Failed to play: ${error}` instanceof Error ? `Failed to play: ${error}` instanceof Error ? `Failed to play: ${error}` : new Error(String(`Failed to play: ${error}` instanceof Error ? `Failed to play: ${error}` instanceof Error ? `Failed to play: ${error}` : new Error(String(`Failed to play: ${error}` : new Error(String(`Failed to play: ${error}` instanceof Error ? `Failed to play: ${error}` : new Error(String(`Failed to play: ${error}` : new Error(String(`Failed to play: ${error}` instanceof Error ? `Failed to play: ${error}` : new Error(String(`Failed to play: ${error}` instanceof Error ? `Failed to play: ${error}` instanceof Error ? `Failed to play: ${error}` : new Error(String(`Failed to play: ${error}` : new Error(String(`Failed to play: ${error}` instanceof Error ? `Failed to play: ${error}` : new Error(String(`Failed to play: ${error}`)))))));
        });
      }
      
      this.showControls = true;
      this.restartControlsTimeout();
    } catch (error) {
      Logger.error(this.TAG, `Failed to toggle play/pause: ${error}`);
    }
  }
  
  /**
   * 处理进度条变�?   */
  private handleProgressChange(value: number): void {
    try {
      const seekTime = (value / 100) * this.duration;
      playbackService.seekTo(seekTime).then(() => {
        this.showControls = true;
        this.restartControlsTimeout();
      }).catch((error) => {
        Logger.error(this.TAG, `Failed to seek: ${error}` instanceof Error ? `Failed to seek: ${error}` : new Error(String(`Failed to seek: ${error}` instanceof Error ? `Failed to seek: ${error}` instanceof Error ? `Failed to seek: ${error}` : new Error(String(`Failed to seek: ${error}` : new Error(String(`Failed to seek: ${error}` instanceof Error ? `Failed to seek: ${error}` : new Error(String(`Failed to seek: ${error}` instanceof Error ? `Failed to seek: ${error}` instanceof Error ? `Failed to seek: ${error}` : new Error(String(`Failed to seek: ${error}` instanceof Error ? `Failed to seek: ${error}` instanceof Error ? `Failed to seek: ${error}` : new Error(String(`Failed to seek: ${error}` : new Error(String(`Failed to seek: ${error}` instanceof Error ? `Failed to seek: ${error}` : new Error(String(`Failed to seek: ${error}` : new Error(String(`Failed to seek: ${error}` instanceof Error ? `Failed to seek: ${error}` : new Error(String(`Failed to seek: ${error}` instanceof Error ? `Failed to seek: ${error}` instanceof Error ? `Failed to seek: ${error}` : new Error(String(`Failed to seek: ${error}` : new Error(String(`Failed to seek: ${error}` instanceof Error ? `Failed to seek: ${error}` : new Error(String(`Failed to seek: ${error}`)))))));
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
        Logger.error(this.TAG, `Failed to set volume: ${error}` instanceof Error ? `Failed to set volume: ${error}` : new Error(String(`Failed to set volume: ${error}` instanceof Error ? `Failed to set volume: ${error}` instanceof Error ? `Failed to set volume: ${error}` : new Error(String(`Failed to set volume: ${error}` : new Error(String(`Failed to set volume: ${error}` instanceof Error ? `Failed to set volume: ${error}` : new Error(String(`Failed to set volume: ${error}` instanceof Error ? `Failed to set volume: ${error}` instanceof Error ? `Failed to set volume: ${error}` : new Error(String(`Failed to set volume: ${error}` instanceof Error ? `Failed to set volume: ${error}` instanceof Error ? `Failed to set volume: ${error}` : new Error(String(`Failed to set volume: ${error}` : new Error(String(`Failed to set volume: ${error}` instanceof Error ? `Failed to set volume: ${error}` : new Error(String(`Failed to set volume: ${error}` : new Error(String(`Failed to set volume: ${error}` instanceof Error ? `Failed to set volume: ${error}` : new Error(String(`Failed to set volume: ${error}` instanceof Error ? `Failed to set volume: ${error}` instanceof Error ? `Failed to set volume: ${error}` : new Error(String(`Failed to set volume: ${error}` : new Error(String(`Failed to set volume: ${error}` instanceof Error ? `Failed to set volume: ${error}` : new Error(String(`Failed to set volume: ${error}`)))))));
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
        Logger.error(this.TAG, `Failed to toggle mute: ${error}` instanceof Error ? `Failed to toggle mute: ${error}` : new Error(String(`Failed to toggle mute: ${error}` instanceof Error ? `Failed to toggle mute: ${error}` instanceof Error ? `Failed to toggle mute: ${error}` : new Error(String(`Failed to toggle mute: ${error}` : new Error(String(`Failed to toggle mute: ${error}` instanceof Error ? `Failed to toggle mute: ${error}` : new Error(String(`Failed to toggle mute: ${error}` instanceof Error ? `Failed to toggle mute: ${error}` instanceof Error ? `Failed to toggle mute: ${error}` : new Error(String(`Failed to toggle mute: ${error}` instanceof Error ? `Failed to toggle mute: ${error}` instanceof Error ? `Failed to toggle mute: ${error}` : new Error(String(`Failed to toggle mute: ${error}` : new Error(String(`Failed to toggle mute: ${error}` instanceof Error ? `Failed to toggle mute: ${error}` : new Error(String(`Failed to toggle mute: ${error}` : new Error(String(`Failed to toggle mute: ${error}` instanceof Error ? `Failed to toggle mute: ${error}` : new Error(String(`Failed to toggle mute: ${error}` instanceof Error ? `Failed to toggle mute: ${error}` instanceof Error ? `Failed to toggle mute: ${error}` : new Error(String(`Failed to toggle mute: ${error}` : new Error(String(`Failed to toggle mute: ${error}` instanceof Error ? `Failed to toggle mute: ${error}` : new Error(String(`Failed to toggle mute: ${error}`)))))));
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
        Logger.error(this.TAG, `Failed to set playback speed: ${error}` instanceof Error ? `Failed to set playback speed: ${error}` : new Error(String(`Failed to set playback speed: ${error}` instanceof Error ? `Failed to set playback speed: ${error}` instanceof Error ? `Failed to set playback speed: ${error}` : new Error(String(`Failed to set playback speed: ${error}` : new Error(String(`Failed to set playback speed: ${error}` instanceof Error ? `Failed to set playback speed: ${error}` : new Error(String(`Failed to set playback speed: ${error}` instanceof Error ? `Failed to set playback speed: ${error}` instanceof Error ? `Failed to set playback speed: ${error}` : new Error(String(`Failed to set playback speed: ${error}` instanceof Error ? `Failed to set playback speed: ${error}` instanceof Error ? `Failed to set playback speed: ${error}` : new Error(String(`Failed to set playback speed: ${error}` : new Error(String(`Failed to set playback speed: ${error}` instanceof Error ? `Failed to set playback speed: ${error}` : new Error(String(`Failed to set playback speed: ${error}` : new Error(String(`Failed to set playback speed: ${error}` instanceof Error ? `Failed to set playback speed: ${error}` : new Error(String(`Failed to set playback speed: ${error}` instanceof Error ? `Failed to set playback speed: ${error}` instanceof Error ? `Failed to set playback speed: ${error}` : new Error(String(`Failed to set playback speed: ${error}` : new Error(String(`Failed to set playback speed: ${error}` instanceof Error ? `Failed to set playback speed: ${error}` : new Error(String(`Failed to set playback speed: ${error}`)))))));
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
      
      // 保存播放进度到历史记�?      historyService.saveWatchProgress(
        this.mediaId, this.siteKey,
        this.episodeId,
        position,
        duration
       instanceof Error ? this.siteKey,
        this.episodeId,
        position,
        duration
       : new Error(String(this.siteKey,
        this.episodeId,
        position,
        duration
       instanceof Error ? this.siteKey,
        this.episodeId,
        position,
        duration
       instanceof Error ? this.siteKey,
        this.episodeId,
        position,
        duration
       : new Error(String(this.siteKey,
        this.episodeId,
        position,
        duration
       : new Error(String(this.siteKey,
        this.episodeId,
        position,
        duration
       instanceof Error ? this.siteKey,
        this.episodeId,
        position,
        duration
       : new Error(String(this.siteKey,
        this.episodeId,
        position,
        duration
       instanceof Error ? this.siteKey,
        this.episodeId,
        position,
        duration
       instanceof Error ? this.siteKey,
        this.episodeId,
        position,
        duration
       : new Error(String(this.siteKey,
        this.episodeId,
        position,
        duration
       instanceof Error ? this.siteKey,
        this.episodeId,
        position,
        duration
       instanceof Error ? this.siteKey,
        this.episodeId,
        position,
        duration
       : new Error(String(this.siteKey,
        this.episodeId,
        position,
        duration
       : new Error(String(this.siteKey,
        this.episodeId,
        position,
        duration
       instanceof Error ? this.siteKey,
        this.episodeId,
        position,
        duration
       : new Error(String(this.siteKey,
        this.episodeId,
        position,
        duration
       : new Error(String(this.siteKey,
        this.episodeId,
        position,
        duration
       instanceof Error ? this.siteKey,
        this.episodeId,
        position,
        duration
       : new Error(String(this.siteKey,
        this.episodeId,
        position,
        duration
       instanceof Error ? this.siteKey,
        this.episodeId,
        position,
        duration
       instanceof Error ? this.siteKey,
        this.episodeId,
        position,
        duration
       : new Error(String(this.siteKey,
        this.episodeId,
        position,
        duration
       : new Error(String(this.siteKey,
        this.episodeId,
        position,
        duration
       instanceof Error ? this.siteKey,
        this.episodeId,
        position,
        duration
       : new Error(String(this.siteKey,
        this.episodeId,
        position,
        duration
      ))))))).then(() => {
        Logger.info(this.TAG, `Saved playback progress: ${position}ms of ${duration}ms`);
      }).catch((error) => {
        Logger.error(this.TAG, `Failed to save play progress: ${error}`);
      });
    } catch (error) {
      Logger.error(this.TAG, `Failed to save play progress: ${error}` instanceof Error ? `Failed to save play progress: ${error}` : new Error(String(`Failed to save play progress: ${error}` instanceof Error ? `Failed to save play progress: ${error}` instanceof Error ? `Failed to save play progress: ${error}` : new Error(String(`Failed to save play progress: ${error}` : new Error(String(`Failed to save play progress: ${error}` instanceof Error ? `Failed to save play progress: ${error}` : new Error(String(`Failed to save play progress: ${error}` instanceof Error ? `Failed to save play progress: ${error}` instanceof Error ? `Failed to save play progress: ${error}` : new Error(String(`Failed to save play progress: ${error}` instanceof Error ? `Failed to save play progress: ${error}` instanceof Error ? `Failed to save play progress: ${error}` : new Error(String(`Failed to save play progress: ${error}` : new Error(String(`Failed to save play progress: ${error}` instanceof Error ? `Failed to save play progress: ${error}` : new Error(String(`Failed to save play progress: ${error}` : new Error(String(`Failed to save play progress: ${error}` instanceof Error ? `Failed to save play progress: ${error}` : new Error(String(`Failed to save play progress: ${error}` instanceof Error ? `Failed to save play progress: ${error}` instanceof Error ? `Failed to save play progress: ${error}` : new Error(String(`Failed to save play progress: ${error}` : new Error(String(`Failed to save play progress: ${error}` instanceof Error ? `Failed to save play progress: ${error}` : new Error(String(`Failed to save play progress: ${error}`)))))));
    }
  }
  
  /**
   * 处理播放错误，尝试切换到下一个可用片�?   */
  private handlePlaybackError(error: Error): void {
    if (!this.playSources || this.playSources.length <= 1) {
      this.errorMessage = '播放失败，暂无可用备用片�?;
      this.isLoading = false;
      return;
    }
    
    // 查找当前片源的索�?    const currentIndex = this.playSources.findIndex(s => 
      s.id === this.playSource?.id || 
      (s.name === this.playSource?.name && s.url === this.playSource?.url)
    );
    
    // 选择下一个可用的片源
    let nextIndex = (currentIndex + 1) % this.playSources.length;
    
    if (currentIndex !== -1) {
      Logger.info(this.TAG, `尝试切换到下一个片�? ${nextIndex}，原片源: ${currentIndex}`);
      
      // 显示切换提示
      this.errorMessage = `当前片源播放失败，正在尝试切换到备用片源(${nextIndex + 1}/${this.playSources.length})...`;
      
      // 保存当前播放位置
      const currentPosition = this.currentPosition;
      
      // 切换到下一个片�?      this.initialPosition = currentPosition; // 保持相同的播放位�?      this.setupPlayback(this.playSources[nextIndex]);
      this.errorMessage = '';
    } else {
      this.errorMessage = '播放失败，无法识别当前片�?;
      this.isLoading = false;
    }
  }
  
  /**
   * 切换播放�?   */
  private switchPlaySource(source: PlaySource): void {
    try {
      this.isLoading = true;
      this.playbackState = PlaybackState.BUFFERING;
      
      // 保存当前播放位置
      const currentPosition = this.currentPosition;
      
      // 设置新的播放�?      this.setupPlayback(source);
      
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
      Logger.error(this.TAG, `Failed to switch play source: ${error}` instanceof Error ? `Failed to switch play source: ${error}` : new Error(String(`Failed to switch play source: ${error}` instanceof Error ? `Failed to switch play source: ${error}` instanceof Error ? `Failed to switch play source: ${error}` : new Error(String(`Failed to switch play source: ${error}` : new Error(String(`Failed to switch play source: ${error}` instanceof Error ? `Failed to switch play source: ${error}` : new Error(String(`Failed to switch play source: ${error}` instanceof Error ? `Failed to switch play source: ${error}` instanceof Error ? `Failed to switch play source: ${error}` : new Error(String(`Failed to switch play source: ${error}` instanceof Error ? `Failed to switch play source: ${error}` instanceof Error ? `Failed to switch play source: ${error}` : new Error(String(`Failed to switch play source: ${error}` : new Error(String(`Failed to switch play source: ${error}` instanceof Error ? `Failed to switch play source: ${error}` : new Error(String(`Failed to switch play source: ${error}` : new Error(String(`Failed to switch play source: ${error}` instanceof Error ? `Failed to switch play source: ${error}` : new Error(String(`Failed to switch play source: ${error}` instanceof Error ? `Failed to switch play source: ${error}` instanceof Error ? `Failed to switch play source: ${error}` : new Error(String(`Failed to switch play source: ${error}` : new Error(String(`Failed to switch play source: ${error}` instanceof Error ? `Failed to switch play source: ${error}` : new Error(String(`Failed to switch play source: ${error}`)))))));
      this.errorMessage = '切换播放源失�?;
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
    // 先保存进�?    this.savePlaybackProgress();
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
   * 停止控制栏超�?   */
  private stopControlsTimeout(): void {
    if (this.controlsTimeout) {
      clearTimeout(this.controlsTimeout);
      this.controlsTimeout = null;
    }
  }
  
  /**
   * 释放播放器资�?   */
  private releasePlayer(): void {
    try {
      // 保存当前播放进度
      this.savePlaybackProgress();
      
      // 移除播放监听�?      playbackService.removeAllListeners();
      
      // 释放播放器资�?      playbackService.release().catch((error) => {
        Logger.error(this.TAG, `Failed to release player: ${error}`);
      });
    } catch (error) {
      Logger.error(this.TAG, `Failed to release player: ${error}` instanceof Error ? `Failed to release player: ${error}` : new Error(String(`Failed to release player: ${error}` instanceof Error ? `Failed to release player: ${error}` instanceof Error ? `Failed to release player: ${error}` : new Error(String(`Failed to release player: ${error}` : new Error(String(`Failed to release player: ${error}` instanceof Error ? `Failed to release player: ${error}` : new Error(String(`Failed to release player: ${error}` instanceof Error ? `Failed to release player: ${error}` instanceof Error ? `Failed to release player: ${error}` : new Error(String(`Failed to release player: ${error}` instanceof Error ? `Failed to release player: ${error}` instanceof Error ? `Failed to release player: ${error}` : new Error(String(`Failed to release player: ${error}` : new Error(String(`Failed to release player: ${error}` instanceof Error ? `Failed to release player: ${error}` : new Error(String(`Failed to release player: ${error}` : new Error(String(`Failed to release player: ${error}` instanceof Error ? `Failed to release player: ${error}` : new Error(String(`Failed to release player: ${error}` instanceof Error ? `Failed to release player: ${error}` instanceof Error ? `Failed to release player: ${error}` : new Error(String(`Failed to release player: ${error}` : new Error(String(`Failed to release player: ${error}` instanceof Error ? `Failed to release player: ${error}` : new Error(String(`Failed to release player: ${error}`)))))));
    }
  }
  
  /**
   * 格式化时�?   */
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
   * 渲染加载状�?   */
  @Builder
  private renderLoading(): void {
    Stack({ className: "loading-overlay" }) {
      LoadingProgress({ className: "loading-progress", color: "#FF4500" })
      Text("正在加载...").className("loading-text")
      if (this.bufferPercentage > 0) {
        Text(`已缓�?${this.bufferPercentage}%`).className("buffer-text")
      }
    }
  }
  
  /**
   * 渲染错误状�?   */
  @Builder
  private renderError(): void {
    Stack({ className: "error-overlay" }) {
      Text("⚠️").className("error-icon")
      Text(this.errorMessage).className("error-message")
      Button({ className: "retry-button", onClick: () => this.initializePlayback() }) {
        Text("重试")
      }
    }
  }
  
  /**
   * 渲染顶部控制�?   */
  @Builder
  private renderTopControls(): void {
    Stack({ className: "top-controls" }) {
      Button({ className: "back-button", onClick: this.handleBack }) {
        Text("�?返回")
      }
      Stack({ className: "title-container" }) {
        Text(this.mediaTitle).className("media-title").numberOfLines(1)
        if (this.episodeName) {
          Text(this.episodeName).className("episode-name").numberOfLines(1)
        }
      }
      Button({ className: "settings-button", onClick: () => this.showSpeedMenu = !this.showSpeedMenu }) {
        Text(`${this.playbackSpeed}x`)
      }
    }
  }
  
  /**
   * 渲染底部控制�?   */
  @Builder
  private renderBottomControls(): void {
    Stack({ className: "bottom-controls" }) {
      Button({ className: "play-pause-button", onClick: this.togglePlayPause }) {
        Text(this.isPlaying ? '�? : '�?)
      }
      
      Stack({ className: "progress-container" }) {
        Slider({ 
          className: "progress-slider",
          value: (this.currentTime / this.duration) * 100 || 0,
          min: 0,
          max: 100,
          onChange: this.handleProgressChange 
        })
        Flex({ className: "time-display" }) {
          Text(this.formatTime(this.currentTime)).className("current-time")
          Text(this.formatTime(this.duration)).className("duration")
        }
      }
      
      Button({ className: "mute-button", onClick: this.toggleMute }) {
        Text(this.isMuted ? '🔇' : '🔊')
      }
      
      Stack({ className: "volume-container" }) {
        Slider({ 
          className: "volume-slider",
          value: this.volume * 100,
          min: 0,
          max: 100,
          onChange: this.handleVolumeChange 
        })
      }
      
      Button({ className: "source-button", onClick: () => this.showSourceMenu = !this.showSourceMenu }) {
        Text("�?)
      }
      
      Button({ className: "fullscreen-button", onClick: this.toggleFullscreen }) {
        Text(this.isFullscreen ? '�? : '�?)
      }
    }
  }
  
  /**
   * 渲染播放速度菜单
   */
  @Builder
  private renderSpeedMenu(): void {
    if (!this.showSpeedMenu) return;
    
    Stack({ className: "speed-menu" }) {
      playbackService.getSupportedPlaybackSpeeds().forEach((speed) => {
        Button({ 
          key: speed.toString(),
          className: `speed-option ${this.playbackSpeed === speed ? 'selected' : ''}`,
          onClick: () => this.setPlaybackSpeed(speed) 
        }) {
          Text(playbackService.getPlaybackSpeedText(speed))
        }
      })
    }
  }
  
  /**
   * 渲染播放源菜�?   */
  @Builder
  private renderSourceMenu(): void {
    if (!this.showSourceMenu) return;
    
    Stack({
      style: {
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
      }
    }) {
      // 菜单标题
      Flex({
        style: {
          flexDirection: 'row',
          alignItems: 'center',
          justifyContent: 'space-between',
          marginBottom: 20
        }
      }) {
        Text('切换片源')
          .fontSize(28)
          .fontColor('#FFFFFF')
          .fontWeight(700)
        Button({
          style: {
            backgroundColor: 'transparent'
          },
          onClick: () => this.showSourceMenu = false
        }) {
          Text('�?)
            .fontSize(24)
            .fontColor('#FFFFFF')
        }
      }
    
      // 搜索�?      Stack({
        style: {
          flexDirection: 'row',
          alignItems: 'center',
          backgroundColor: '#FFFFFF',
          borderRadius: 25,
          paddingHorizontal: 20,
          marginBottom: 20,
          height: 50
        }
      }) {
        Text('🔍')
          .fontSize(24)
          .fontColor('#999999')
          .margin({ right: 10 })
        TextInput({
          style: {
            flex: 1,
            fontSize: 24,
            color: '#333333'
          },
          value: this.searchText,
          onChange: (text) => this.handleSearchChange(text),
          onFocusChange: (focused) => this.handleSearchFocusChange(focused),
          placeholder: '搜索片源...',
          placeholderColor: '#999999'
        })
        if (this.searchText.length > 0) {
          Button({
            style: {
              backgroundColor: 'transparent'
            },
            onClick: () => this.clearSearchText()
          }) {
            Text('�?)
          .fontSize(24)
          .fontColor('#999999')
          }
        }
      }
      
      // 搜索结果数量提示
      Text(`共找�?${this.filteredSources.length} 个片源`)
        .fontSize(24)
        .fontColor('#FFFFFF')
        .fontWeight(600)
        .margin({ bottom: 10 })
    
      // 片源列表
      List({
        style: {
          flex: 1,
          backgroundColor: 'transparent'
        },
        divider: {
          strokeWidth: 1,
          color: '#FFFFFF',
          startMargin: 0,
          endMargin: 0
        }
      }) {
        this.filteredSources.forEach((source, index) => {
          ListItem({
            key: source.id,
            style: {
              backgroundColor: this.playSource?.id === source.id ? '#FFFFFF' : 'transparent',
              borderRadius: 10,
              marginBottom: 10,
              padding: 15
            },
            onClick: () => this.switchPlaySource(source)
          }) {
            Flex({
              style: {
                flexDirection: 'row',
                alignItems: 'center',
                justifyContent: 'space-between'
              }
            }) {
              // 片源信息
              Flex({
                style: {
                  flexDirection: 'column',
                  alignItems: 'flex-start',
                  flex: 1
                }
              }) {
                Text(source.name || `播放�?{index + 1}`)
                  .fontSize(26)
                  .fontColor(this.playSource?.id === source.id ? '#4CAF50' : '#FFFFFF')
                  .fontWeight(600)
                  .margin({ bottom: 5 })
                Text(source.url)
                  .fontSize(22)
                  .fontColor(this.playSource?.id === source.id ? '#666666' : '#CCCCCC')
              }
              
              // 质量标签
              if (source.quality) {
                Flex({
                  style: {
                    backgroundColor: '#FFEB3B',
                    paddingHorizontal: 12,
                    paddingVertical: 4,
                    borderRadius: 12
                  }
                }) {
                  Text(source.quality)
                    .fontSize(20)
                    .fontColor('#000000')
                    .fontWeight(700)
                }
              }
              
              // 选中标记
              if (this.playSource?.id === source.id) {
                Text('�?)
                  .fontSize(24)
                  .fontColor('#4CAF50')
              }
            }
          }
        }
    }
  }
  
  /**
   * 组件渲染
   */
  build() {
    Stack({ className: `playback-page ${this.isFullscreen ? 'fullscreen' : ''}`, onClick: this.handleScreenTap }) {
      // 视频播放区域
      Stack({ className: "video-container" }) {
        // 这里应该使用实际的视频播放器组件
        // 由于HarmonyOS的Video组件具体API可能不同，这里用占位符表�?        Image("https://via.placeholder.com/1920x1080?text=Video+Player")
          .className("video-placeholder")
          .objectFit("cover")
        
        // 加载状�?        if (this.isLoading) {
          this.renderLoading();
        }
        
        // 错误状�?        if (this.errorMessage) {
          this.renderError();
        }
        
        // 播放控制界面
        if (this.showControls) {
          Stack({ className: "controls-overlay" }) {
            this.renderTopControls();
            this.renderBottomControls();
          }
        }
        
        // 播放速度菜单
        this.renderSpeedMenu();
        
        // 播放源菜�?        this.renderSourceMenu();
      }
    }
  }
}

export default PlaybackPage;


