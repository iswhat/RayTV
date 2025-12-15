import { Stack, Video, Image, Button, Slider, List, ListItem, LoadingProgress, Toast, PromptAction, VideoFit } from '@kit.ArkUI';
import Router from '@ohos.router';
import Logger from '../common/util/Logger';
import { playbackService } from '../service/media/PlaybackService';
import { historyService } from '../service/media/HistoryService';
import { mediaService } from '../service/media/MediaService';
import { configService } from '../service/config/ConfigService';
import { PlaybackState, PlaybackSpeed, PlaySource, Subtitle } from '../service/media/PlaybackService';

/**
 * 播放页面组件
 * 实现视频播放控制界面，包含播放暂停、进度控制、音量控制、速度调整等功能 */
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
  private lastSaveTime: number = 0; // 上次保存进度的时�?毫秒)
  private currentPosition: number = 0; // 当前播放位置
  private totalTime: number = 0;
  
  // 初始�?  /**
   * 页面加载时调�?   */
  aboutToAppear(): void {
    Logger.info(this.TAG, 'PlaybackPage appeared');
    
    // 获取路由参数
    const params = Router.getParams();
    this.mediaId = (params?.mediaId as string) || '';
    this.siteKey = (params?.siteKey as string) || '';
    this.episodeId = params?.episodeId;
    this.initialPosition = (params?.currentTime as number) || (params?.startPosition as number) || 0;
    this.mediaTitle = (params?.mediaTitle as string) || '正在播放';
    this.episodeName = (params?.episodeName as string) || '';
    this.playSource = params?.playSource;
    this.playSourceIndex = (params?.playSourceIndex as number) || 0;
    this.autoSwitchSourceOnError = params?.autoSwitchSourceOnError !== false; // 默认开�?    
    Logger.info(this.TAG, `Starting playback for: ${this.siteKey}:${this.mediaId}`, `${this.episodeId ? ` episode: ${this.episodeId}` : ''}, startPosition=${this.initialPosition}`);
    
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
        Logger.error(this.TAG, 'Failed to initialize playback', error as Error);
        this.errorMessage = '播放初始化失�?;
        this.isLoading = false;
        this.playbackState = PlaybackState.ERROR;
      });
    } catch (error) {
      Logger.error(this.TAG, `Failed to initialize playback`, `${error}`);
      this.errorMessage = '播放初始化失�?;
      this.isLoading = false;
      this.playbackState = PlaybackState.ERROR;
    }
  }
  
  /**
   * 加载播放�?   */
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
            
            // 如果只有一个播放源，则使用�?            if (this.playSources.length === 1 && !this.playSource) {
              this.playSource = this.playSources[0];
            }
            resolve();
          }).catch((error) => {
            Logger.error(this.TAG, `Failed to load play sources`, `${error}`);
            reject(error);
          });
        } else {
          resolve();
        }
      } catch (error) {
        Logger.error(this.TAG, `Failed to load play sources`, `${error}`);
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
        Logger.error(this.TAG, `Failed to setup playback`, `${error}`);
        
        // 尝试自动切换到下一个片�?        if (this.autoSwitchSourceOnError) {
          this.handlePlaybackError(error);
        } else {
          this.errorMessage = '播放设置失败';
          this.isLoading = false;
          this.playbackState = PlaybackState.ERROR;
        }
      });
    } catch (error) {
      Logger.error(this.TAG, `Failed to setup playback`, `${error}`);
      
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
        Logger.error(this.TAG, `Playback error`, `${error}`);
        
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
        Logger.error(this.TAG, `Failed to handle playback completed`, `${error}`);
        Toast.show('播放完成');
      });
    } catch (error) {
      Logger.error(this.TAG, `Failed to handle playback completed`, `${error}`);
      Toast.show('播放完成');
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
        Logger.error(this.TAG, `Failed to save play progress`, `${error}`);
      });
    } catch (error) {
      Logger.error(this.TAG, `Failed to save play progress`, `${error}`);
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
          Logger.error(this.TAG, `Failed to pause playback`, `${error}`);
        });
      } else {
        playbackService.play().catch((error) => {
          Logger.error(this.TAG, `Failed to play`, `${error}`);
        });
      }
      
      this.showControls = true;
      this.restartControlsTimeout();
    } catch (error) {
      Logger.error(this.TAG, `Failed to toggle play/pause`, `${error}`);
    }
  }
  
  /**
   * 处理进度条变�?   */
  private handleProgressChange(value: number): void {
    try {
      const seekTime = (value / 100) * this.duration;
      playbackService.seekTo(seekTime).catch((error) => {
        Logger.error(this.TAG, `Failed to seek`, `${error}`);
      });
    } catch (error) {
      Logger.error(this.TAG, `Failed to seek`, `${error}`);
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
        Logger.error(this.TAG, `Failed to set volume`, `${error}`);
      });
    } catch (error) {
      Logger.error(this.TAG, `Failed to set volume`, `${error}`);
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
        Logger.error(this.TAG, `Failed to toggle mute`, `${error}`);
      });
    } catch (error) {
      Logger.error(this.TAG, `Failed to toggle mute`, `${error}`);
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
        Logger.error(this.TAG, `Failed to set playback speed`, `${error}`);
      });
    } catch (error) {
      Logger.error(this.TAG, `Failed to set playback speed`, `${error}`);
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
      Logger.info(this.TAG, `尝试切换到下一个片源 ${nextIndex}，原片源: ${currentIndex}`);
      
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
        playbackService.seekTo(currentPosition).catch((error) => {
          Logger.error(this.TAG, `Failed to seek to position after switching source: ${error}`);
        });
      }
      
      this.isLoading = false;
      this.showSourceMenu = false;
      
      // 显示切换成功提示
      Toast.show('片源切换成功');
    } catch (error) {
      Logger.error(this.TAG, `Failed to switch play source`, `${error}`);
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
    // 先保存进�?    this.savePlayProgress(this.currentPosition);
    Router.back();
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
      this.savePlayProgress(this.currentPosition);
      
      // 移除播放监听�?      playbackService.removeAllListeners();
      
      // 释放播放器资�?      playbackService.release().catch((error) => {
        Logger.error(this.TAG, `Failed to release player`, `${error}`);
      });
    } catch (error) {
      Logger.error(this.TAG, `Failed to release player`, `${error}`);
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
   * 渲染加载状态
   */
  @Builder
  private renderLoading(): void {
    Stack() {
      LoadingProgress({ color: "#FF4500" })
      Text("正在加载...")
      if (this.bufferPercentage > 0) {
        Text(`已缓存${this.bufferPercentage}%`)
      }
    }
  }
  
  /**
   * 渲染错误状态
   */
  @Builder
  private renderError(): void {
    Stack() {
      Text("⚠️")
      Text(this.errorMessage)
      Button() {
        Text("重试")
      }
      .onClick(() => this.initializePlayback())
    }
  }
  
  /**
   * 渲染顶部控制栏
   */
  @Builder
  private renderTopControls(): void {
    Stack() {
      Button() {
        Text("返回")
      }
      .onClick(this.handleBack)
      Stack() {
        Text(this.mediaTitle).numberOfLines(1)
        if (this.episodeName) {
          Text(this.episodeName).numberOfLines(1)
        }
      }
      Button() {
        Text(`${this.playbackSpeed}x`)
      }
      .onClick(() => this.showSpeedMenu = !this.showSpeedMenu)
    }
  }
  
  /**
   * 渲染底部控制栏
   */
  @Builder
  private renderBottomControls(): void {
    Stack() {
      Button() {
        Text(this.isPlaying ? '暂停' : '播放')
      }
      .onClick(this.togglePlayPause)
      
      Stack() {
        Slider({ 
          value: (this.currentTime / this.duration) * 100 || 0,
          min: 0,
          max: 100,
          onChange: this.handleProgressChange 
        })
        Flex() {
          Text(this.formatTime(this.currentTime))
          Text(this.formatTime(this.duration))
        }
      }
      
      Button() {
        Text(this.isMuted ? '🔇' : '🔊')
      }
      .onClick(this.toggleMute)
      
      Stack() {
        Slider({ 
          value: this.volume * 100,
          min: 0,
          max: 100,
          onChange: this.handleVolumeChange 
        })
      }
      
      Button() {
        Text("切换源")
      }
      .onClick(() => this.showSourceMenu = !this.showSourceMenu)
      
      Button() {
        Text(this.isFullscreen ? '退出全屏' : '全屏')
      }
      .onClick(this.toggleFullscreen)
    }
  }
  
  /**
   * 渲染播放速度菜单
   */
  @Builder
  private renderSpeedMenu(): void {
    if (!this.showSpeedMenu) return;
    
    Stack() {
      playbackService.getSupportedPlaybackSpeeds().forEach((speed) => {
        Button() {
          Text(playbackService.getPlaybackSpeedText(speed))
        }
        .onClick(() => this.setPlaybackSpeed(speed))
      })
    }
  }
  
  /**
   * 渲染播放源菜单
   */
  @Builder
  private renderSourceMenu(): void {
    if (!this.showSourceMenu) return;
    
    Stack() {
      // 菜单标题
      Flex() {
        Text('切换片源')
          .fontSize(28)
          .fontColor('#FFFFFF')
          .fontWeight(700)
        Button() {
          Text('关闭')
            .fontSize(24)
            .fontColor('#FFFFFF')
        }
        .onClick(() => this.showSourceMenu = false)
      }
    
      // 搜索框
      Stack() {
        Text('🔍')
          .fontSize(24)
          .fontColor('#999999')
          .margin({ right: 10 })
        TextInput({
          value: this.searchText,
          placeholder: '搜索片源...',
          placeholderColor: '#999999'
        })
        .onChange((text) => this.handleSearchChange(text))
        .onFocusChange((focused) => this.handleSearchFocusChange(focused))
        if (this.searchText.length > 0) {
          Button() {
            Text('清除')
            .fontSize(24)
            .fontColor('#999999')
          }
          .onClick(() => this.clearSearchText())
        }
      }
      
      // 搜索结果数量提示
      Text(`共找到${this.filteredSources.length} 个片源`)
        .fontSize(24)
        .fontColor('#FFFFFF')
        .fontWeight(600)
        .margin({ bottom: 10 })
    
      // 片源列表
      List() {
        ForEach(this.filteredSources, (source, index) => {
          ListItem() {
            Flex() {
              // 片源信息
              Flex() {
                Text(source.name || `片源 ${index + 1}`)
                  .fontSize(24)
                  .fontColor(this.playSource?.id === source.id ? '#333333' : '#FFFFFF')
                  .fontWeight(700)
                if (source.description) {
                  Text(source.description)
                    .fontSize(18)
                    .fontColor(this.playSource?.id === source.id ? '#666666' : '#CCCCCC')
                    .margin({ top: 5 })
                    .numberOfLines(2)
                }
              }
              
              // 当前播放标记
              if (this.playSource?.id === source.id) {
                Text('正在播放')
                  .fontSize(18)
                  .fontColor('#FF4500')
                  .fontWeight(700)
                  .backgroundColor('#FFFF00')
                  .padding({ left: 10, right: 10, top: 5, bottom: 5 })
                  .borderRadius(15)
              }
            }
          }
          .onClick(() => this.switchPlaySource(source))
        })
      }
    }
  }
  
  /**
   * 渲染字幕菜单
   */
  @Builder
  private renderSubtitleMenu(): void {
    if (!this.showSubtitleMenu) return;
    
    Stack() {
      Text("字幕菜单")
        .fontSize(24)
        .fontColor("#FFFFFF")
        .margin({ bottom: 20 })
      
      Button() {
        Text("关闭菜单")
      }
      .onClick(() => this.showSubtitleMenu = false)
    }
  }
  
  /**
   * 渲染播放控制界面
   */
  build() {
    Stack()
    .onClick(this.handleScreenTap) {
      // 视频播放区域
      Video({
        src: this.playSource?.url || "",
        autoPlay: true,
        objectFit: VideoFit.COVER
      })
      
      // 加载状态
      if (this.isLoading && this.playbackState !== PlaybackState.ERROR) {
        this.renderLoading();
      }
      
      // 错误状态
      if (this.playbackState === PlaybackState.ERROR) {
        this.renderError();
      }
      
      // 控制栏
      if (this.showControls) {
        // 顶部控制栏
        this.renderTopControls();
        
        // 底部控制栏
        this.renderBottomControls();
      }
      
      // 速度菜单
      this.renderSpeedMenu();
      
      // 播放源菜单
      this.renderSourceMenu();
      
      // 字幕菜单
      this.renderSubtitleMenu();
    }
  }
}