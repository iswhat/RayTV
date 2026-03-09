import { AppNavigator, DetailParams } from '../navigation/AppNavigator';
import Logger from '../common/util/Logger';
import { MediaService } from '../service/media/MediaService';
import { PlaybackService } from '../service/playback/PlaybackService';
import { AVPlayerService } from '../service/playback/AVPlayerService';
import { SearchService } from '../service/search/SearchService';
import SubtitleService, { SubtitleTrack, SubtitleProvider, SubtitleLanguage } from '../service/media/SubtitleService';
import TimerManager from '../common/util/TimerManager';

import CacheService, { CachePriority } from '../service/cache/CacheService';
import { getPlaybackViewModel, PlaybackViewModel } from '../viewmodel/PlaybackViewModel';
import display from '@ohos.display';
import { ScrollDirection, BarState, FlexAlign, FlexDirection, ImageFit, TextAlign, VerticalAlign, HorizontalAlign, FlexWrap, KeyEvent, FocusStyle, TouchEvent, GestureEvent, Curve, Scroller, Column, Row, Text, Button, Image, Stack } from '@ohos/arkui';

// 导入子组件 | Import sub-components
import { PlaybackControls } from './playback/PlaybackControls';
import { SkipSettings } from './playback/SkipSettings';

// 导入新创建的组件 | Import newly created components
import { MediaInfoComponent } from './playback/components/MediaInfoComponent';
import { EpisodeListComponent } from './playback/components/EpisodeListComponent';
import { SubtitleOptionsComponent } from './playback/components/SubtitleOptionsComponent';
import { AudioTrackOptionsComponent } from './playback/components/AudioTrackOptionsComponent';
import { PlaybackSpeedComponent } from './playback/components/PlaybackSpeedComponent';

// 导入类型定义 | Import type definitions
import { ParseLine, MediaInfo, AudioTrack, SubtitleStyle, PlaybackSettings, Episode } from './playback/types/PlaybackTypes';

// 导入焦点管理器 | Import focus manager
import { FocusManager } from './playback/utils/FocusManager';

@Entry
@Component
struct PlaybackPage {
  private readonly TAG: string = 'PlaybackPage';
  
  // 统一状态管理 | Unified state management
  @State state: {
    // 媒体信息状态 | Media info state
    media: {
      info: MediaInfo | null;
      episodes: Episode[];
      parseLines: ParseLine[];
      selectedEpisode: Episode | null;
      selectedLine: ParseLine | null;
    };
    // 播放状态 | Playback state
    playback: {
      isPlaying: boolean;
      currentTime: number;
      duration: number;
      progress: number;
      playbackSpeed: number;
      isLoading: boolean;
      isError: boolean;
      errorMessage: string;
    };
    // UI状态 | UI state
    ui: {
      isLandscape: boolean;
      screenWidth: number;
      screenHeight: number;
      showControls: boolean;
      showEpisodeList: boolean;
      showMoreOptions: boolean;
      showSubtitleOptions: boolean;
      showAudioTrackOptions: boolean;
      showSkipOptions: boolean;
      videoPlayerHeight: number;
      controlHideTimer: number | null;
      currentFocusElement: string;
    };
    // 字幕状态 | Subtitle state
    subtitle: {
      tracks: SubtitleTrack[];
      selectedTrack: SubtitleTrack | null;
      languages: SubtitleLanguage[];
      isSearching: boolean;
    };
    // 音轨状态 | Audio track state
    audio: {
      tracks: AudioTrack[];
      selectedTrack: AudioTrack | null;
    };
    // 跳过设置状态 | Skip settings state
    skip: {
      skipOpeningTime: number;
      skipEndingTime: number;
      isSkipOpeningEnabled: boolean;
      isSkipEndingEnabled: boolean;
    };
    // 直播状态 | Live state
    live: {
      isLiveMode: boolean;
      showChannelList: boolean;
      showSettings: boolean;
    };
  } = {
    media: {
      info: null,
      episodes: [],
      parseLines: [],
      selectedEpisode: null,
      selectedLine: null
    },
    playback: {
      isPlaying: true,
      currentTime: 0,
      duration: 0,
      progress: 0,
      playbackSpeed: 1.0,
      isLoading: true,
      isError: false,
      errorMessage: '加载失败'
    },
    ui: {
      isLandscape: false,
      screenWidth: 0,
      screenHeight: 0,
      showControls: false, // 默认隐藏控制条
      showEpisodeList: true,
      showMoreOptions: false,
      showSubtitleOptions: false,
      showAudioTrackOptions: false,
      showSkipOptions: false,
      videoPlayerHeight: 0,
      controlHideTimer: null,
      currentFocusElement: ''
    },
    subtitle: {
      tracks: [],
      selectedTrack: null,
      languages: [],
      isSearching: false
    },
    audio: {
      tracks: [],
      selectedTrack: null
    },
    skip: {
      skipOpeningTime: 90, // 默认跳过片头时间（秒）
      skipEndingTime: 300, // 默认跳过片尾时间（秒）
      isSkipOpeningEnabled: true,
      isSkipEndingEnabled: true
    },
    live: {
      isLiveMode: false, // 是否为直播模式
      showChannelList: false, // 是否显示直播频道列表
      showSettings: false, // 是否显示直播设置
    }
  };
  
  // ViewModel实例 | ViewModel instance
  private viewModel: PlaybackViewModel = getPlaybackViewModel();
  
  // 焦点样式 | Focus style
  private focusStyle: FocusStyle = {
    border: {
      width: 3,
      color: '#4CAF50',
      radius: 8
    },
    shadow: {
      color: '#4CAF50',
      radius: 10,
      offsetX: 0,
      offsetY: 0
    }
  };
  
  // 焦点管理 | Focus management
  private focusManager: FocusManager = new FocusManager();
  
  // 服务实例 | Service instances
  private cacheService: CacheService = CacheService.getInstance();
  private playbackService: PlaybackService = PlaybackService.getInstance();
  private subtitleService: SubtitleService = SubtitleService.getInstance();
  private searchService: SearchService = SearchService.getInstance();
  private timerManager: TimerManager = TimerManager.getInstance();
  
  // 生命周期 | Lifecycle
  aboutToAppear() {
    Logger.info(this.TAG, 'PlaybackPage about to appear');
    
    // 初始化屏幕信息 | Initialize screen information
    this.initScreenInfo();
    
    // 绑定ViewModel状态 | Bind ViewModel state
    this.bindViewModel();
    
    // 初始化播放 | Initialize playback
    this.initPlayback();
  }
  
  // 初始化屏幕信息 | Initialize screen information
  private initScreenInfo() {
    try {
      const displayInfo = display.getDefaultDisplaySync();
      const width = displayInfo.width;
      const height = displayInfo.height;
      
      // 更新ViewModel屏幕信息
      this.viewModel.updateScreenInfo(width, height);
      
      Logger.info(this.TAG, `Screen info: width=${width}, height=${height}`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to get screen info: ${error}`);
      // 默认值 | Default values
      this.viewModel.updateScreenInfo(1920, 1080);
    }
  }
  
  // 绑定ViewModel状态 | Bind ViewModel state
  private bindViewModel(): void {
    // 绑定媒体状态
    this.viewModel.mediaState.subscribe((mediaState) => {
      this.state.media = {
        info: mediaState.info,
        episodes: mediaState.episodes,
        parseLines: mediaState.parseLines,
        selectedEpisode: mediaState.selectedEpisode,
        selectedLine: mediaState.selectedLine
      };
    });
    
    // 绑定播放控制状态
    this.viewModel.controlState.subscribe((controlState) => {
      this.state.playback = {
        isPlaying: controlState.isPlaying,
        currentTime: controlState.currentTime,
        duration: controlState.duration,
        progress: controlState.progress,
        playbackSpeed: controlState.playbackSpeed,
        isLoading: controlState.isLoading,
        isError: controlState.isError,
        errorMessage: controlState.errorMessage
      };
    });
    
    // 绑定UI状态
    this.viewModel.uiState.subscribe((uiState) => {
      this.state.ui = {
        isLandscape: uiState.isLandscape,
        screenWidth: uiState.screenWidth,
        screenHeight: uiState.screenHeight,
        showControls: uiState.showControls,
        showEpisodeList: uiState.showEpisodeList,
        showMoreOptions: uiState.showMoreOptions,
        showSubtitleOptions: uiState.showSubtitleOptions,
        showAudioTrackOptions: uiState.showAudioTrackOptions,
        showSkipOptions: uiState.showSkipOptions,
        videoPlayerHeight: uiState.videoPlayerHeight,
        controlHideTimer: uiState.controlHideTimer,
        currentFocusElement: uiState.currentFocusElement
      };
    });
    
    // 绑定字幕状态
    this.viewModel.subtitleState.subscribe((subtitleState) => {
      this.state.subtitle = {
        tracks: subtitleState.tracks,
        selectedTrack: subtitleState.selectedTrack,
        languages: subtitleState.languages,
        isSearching: subtitleState.isSearching
      };
    });
    
    // 绑定音轨状态
    this.viewModel.audioState.subscribe((audioState) => {
      this.state.audio = {
        tracks: audioState.tracks,
        selectedTrack: audioState.selectedTrack
      };
    });
    
    // 绑定跳过设置状态
    this.viewModel.skipState.subscribe((skipState) => {
      this.state.skip = {
        skipOpeningTime: skipState.skipOpeningTime,
        skipEndingTime: skipState.skipEndingTime,
        isSkipOpeningEnabled: skipState.isSkipOpeningEnabled,
        isSkipEndingEnabled: skipState.isSkipEndingEnabled
      };
    });
    
    // 绑定直播状态
    this.viewModel.liveState.subscribe((liveState) => {
      this.state.live = {
        isLiveMode: liveState.isLiveMode,
        showChannelList: liveState.showChannelList,
        showSettings: liveState.showSettings
      };
    });
    
    Logger.info(this.TAG, 'ViewModel state binding completed');
  }
  
  // 初始化播放 | Initialize playback
  private async initPlayback(): Promise<void> {
    try {
      // 尝试从router获取参数（NAS播放）
      const routerParams = router.getParams();
      if (routerParams && routerParams.url && routerParams.title) {
        // NAS视频播放
        Logger.info(this.TAG, `NAS video playback: ${routerParams.title}, URL: ${routerParams.url}`);
        
        // 直接使用AVPlayerService播放
        // 这里需要实现AVPlayerService的初始化
        // 暂时模拟播放状态
        this.state.playback.isLoading = false;
        this.state.playback.isError = false;
        this.state.playback.isPlaying = true;
        this.state.playback.duration = 3600; // 模拟1小时视频
        this.state.playback.currentTime = 0;
        this.state.playback.progress = 0;
        
        return;
      }
      
      // 常规视频播放（从AppNavigator获取参数）
      const params = AppNavigator.getInstance().getCurrentRouteParams();
      
      if (!params || !params.id || !params.siteKey) {
        Logger.error(this.TAG, 'Missing required route parameters');
        return;
      }
      
      // 初始化ViewModel
      await this.viewModel.initialize({
        id: params.id,
        siteKey: params.siteKey,
        type: params.type || 'movie'
      });
      
      Logger.info(this.TAG, 'Playback initialized successfully');
    } catch (error) {
      Logger.error(this.TAG, `Failed to initialize playback: ${error}`);
    }
  }
  
  /**
   * 加载媒体信息 | Load media info
   */
  private async loadMediaInfo(): Promise<void> {
    try {
      this.state.playback.isLoading = true;
      this.state.playback.isError = false;

      // 修复问题2：获取路由参数并验证 - 检查params是否存在
      // Get route parameters and validate - check if params exists
      const params: DetailParams = AppNavigator.getInstance().getCurrentRouteParams();

      if (!params || !params.id || !params.siteKey) {
        this.state.playback.isError = true;
        this.state.playback.errorMessage = '缺少必要的参数';
        Logger.error(this.TAG, 'Missing required route parameters');
        this.state.playback.isLoading = false;
        return;
      }

      Logger.info(this.TAG, `Loading media info for: ${params.id} from ${params.siteKey}`);

      // 生成缓存键 | Generate cache key
      const cacheKey = `media_info_${params.id}_${params.siteKey}_${params.type}`;
      
      // 尝试从缓存获取 | Try to get from cache
      const cachedInfo = await this.cacheService.get<MediaInfo>(cacheKey);
      
      if (cachedInfo) {
        this.state.media.info = cachedInfo;
        
        // 加载剧集列表 | Load episode list
        this.loadEpisodes();
        // 加载解析线路 | Load parse lines
        this.loadParseLines();
        
        // 初始化播放 | Initialize playback
        await this.initPlayback();
        
        // 加载字幕 | Load subtitles
        await this.loadSubtitles();
        
        Logger.info(this.TAG, `Loaded media info from cache: ${this.state.media.info.title}`);
        this.state.playback.isLoading = false;
        return;
      }
      
      // 调用实际的MediaService获取媒体信息 | Call actual MediaService to get media info
      const result = await this.mediaService.getMediaDetail(params.id, params.siteKey, params.type);
      
      if (result.isSuccess() && result.data) {
        this.state.media.info = result.data;
        
        // 缓存结果 | Cache result
        await this.cacheService.set(cacheKey, this.state.media.info, {
          expiry: 86400000, // 24小时缓存 24 hours cache
          priority: CachePriority.HIGH,
          tags: ['media', 'detail'],
          source: 'MediaService'
        });
        
        // 加载剧集列表 | Load episode list
        this.loadEpisodes();
        // 加载解析线路 | Load parse lines
        this.loadParseLines();
        
        // 初始化播放 | Initialize playback
        await this.initPlayback();
        
        // 加载字幕 | Load subtitles
        await this.loadSubtitles();
        
        Logger.info(this.TAG, `Loaded media info from service: ${this.state.media.info.title}`);
      } else {
        this.state.playback.isError = true;
        this.state.playback.errorMessage = result.message || '加载失败';
        Logger.warn(this.TAG, `Failed to load media info: ${this.state.playback.errorMessage}`);
      }
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      Logger.error(this.TAG, `Failed to load media info: ${errorMsg}`);
      this.state.playback.isError = true;
      this.state.playback.errorMessage = errorMsg;
    } finally {
      this.state.playback.isLoading = false;
    }
  }
  
  /**
   * 加载剧集列表 | Load episode list
   */
  private loadEpisodes(): void {
    if (this.state.media.info && this.state.media.info.episodes) {
      this.state.media.episodes = this.state.media.info.episodes.map((ep, index: number) => ({
        id: ep.id || `ep_${index}`,
        title: ep.title || `第${ep.episode || (index + 1)}集`,
        episode: ep.episode || (index + 1),
        duration: ep.duration,
        played: ep.played || false,
        current: index === 0
      }));
      this.state.media.selectedEpisode = this.state.media.episodes[0];
      Logger.info(this.TAG, `Loaded ${this.state.media.episodes.length} episodes`);
    } else {
      this.state.media.episodes = [];
    }
  }
  
  /**
   * 加载解析线路 | Load parse lines
   */
  private loadParseLines(): void {
    if (this.state.media.info && this.state.media.info.parseLines) {
      this.state.media.parseLines = this.state.media.info.parseLines.map((line, index: number) => ({
        id: line.id || `line_${index}`,
        name: line.name || `线路${index + 1}`,
        selected: index === 0
      }));
      this.state.media.selectedLine = this.state.media.parseLines[0];
      Logger.info(this.TAG, `Loaded ${this.state.media.parseLines.length} parse lines`);
    } else {
      this.state.media.parseLines = [{
        id: 'line_1',
        name: '默认线路',
        selected: true
      }];
      this.state.media.selectedLine = this.state.media.parseLines[0];
    }
  }
  
  /**
   * 初始化播放 | Initialize playback
   */
  private async initPlayback(): Promise<void> {
    try {
      if (this.state.media.selectedEpisode && this.state.media.selectedLine) {
        // 调用实际的PlaybackService初始化播放 | Call actual PlaybackService to initialize playback
        await this.playbackService.initPlayback({
          episode: this.state.media.selectedEpisode,
          line: this.state.media.selectedLine,
          mediaInfo: this.state.media.info
        });
        
        // 监听播放状态 | Listen to playback state
        this.playbackService.onPlaybackStateChange((state) => {
          this.state.playback.isPlaying = state.isPlaying;
          this.state.playback.currentTime = state.currentTime;
          this.state.playback.duration = state.duration;
          this.state.playback.progress = state.progress;
          
          // 检查是否需要自动跳过 | Check if auto skip is needed
          this.checkAutoSkip();
          
          // 加载音轨信息 | Load audio track info
          if (state.audioTracks && state.audioTracks.length > 0) {
            this.state.audio.tracks = state.audioTracks;
            if (!this.state.audio.selectedTrack && this.state.audio.tracks.length > 0) {
              this.state.audio.selectedTrack = this.state.audio.tracks[0];
            }
          }
        });
        
        Logger.info(this.TAG, 'Playback initialized successfully');
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to initialize playback: ${error}`);
    }
  }
  
  /**
   * 处理剧集选择 | Handle episode selection
   */
  private async handleEpisodeSelect(episode: Episode): Promise<void> {
    try {
      // 验证剧集数据完整性 | Validate episode data integrity
      if (!episode || !episode.id || !episode.title) {
        Logger.error(this.TAG, 'Invalid episode data: missing required fields');
        this.state.playback.isError = true;
        this.state.playback.errorMessage = '无效的剧集数据';
        return;
      }

      this.state.media.selectedEpisode = episode;
      // 更新剧集状态 | Update episode state
      this.state.media.episodes.forEach(ep => {
        ep.current = ep.id === episode.id;
      });
      
      // 显示加载状态 | Show loading state
      this.state.playback.isLoading = true;
      this.state.playback.isError = false;
      
      // 验证playbackService是否可用
      if (!this.playbackService) {
        throw new Error('Playback service not available');
      }
      
      // 调用实际的PlaybackService切换剧集 | Call actual PlaybackService to switch episode
      const result = await this.playbackService.switchEpisode(episode);
      
      if (result && typeof result.isSuccess === 'function' && result.isSuccess()) {
        Logger.info(this.TAG, `Selected episode: ${episode.title}`);
      } else {
        const errorMessage = result && result.message ? result.message : '切换剧集失败';
        Logger.error(this.TAG, `Failed to switch episode: ${errorMessage}`);
        this.state.playback.isError = true;
        this.state.playback.errorMessage = errorMessage;
      }
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      Logger.error(this.TAG, `Failed to switch episode: ${errorMsg}`);
      this.state.playback.isError = true;
      this.state.playback.errorMessage = errorMsg;
    } finally {
      this.state.playback.isLoading = false;
    }
  }
  
  /**
   * 处理解析线路选择 | Handle parse line selection
   */
  private async handleLineSelect(line: ParseLine): Promise<void> {
    try {
      // 验证线路数据完整性 | Validate parse line data integrity
      if (!line || !line.id || !line.name) {
        Logger.error(this.TAG, 'Invalid parse line data: missing required fields');
        this.state.playback.isError = true;
        this.state.playback.errorMessage = '无效的解析线路数据';
        return;
      }

      this.state.media.selectedLine = line;
      // 更新线路状态 | Update line state
      this.state.media.parseLines.forEach(l => {
        l.selected = l.id === line.id;
      });
      
      // 显示加载状态 | Show loading state
      this.state.playback.isLoading = true;
      this.state.playback.isError = false;
      
      // 验证playbackService是否可用
      if (!this.playbackService) {
        throw new Error('Playback service not available');
      }
      
      // 调用实际的PlaybackService切换解析线路 | Call actual PlaybackService to switch parse line
      const result = await this.playbackService.switchParseLine(line);
      
      if (result && typeof result.isSuccess === 'function' && result.isSuccess()) {
        Logger.info(this.TAG, `Selected parse line: ${line.name}`);
      } else {
        const errorMessage = result && result.message ? result.message : '切换解析线路失败';
        Logger.error(this.TAG, `Failed to switch parse line: ${errorMessage}`);
        this.state.playback.isError = true;
        this.state.playback.errorMessage = errorMessage;
      }
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      Logger.error(this.TAG, `Failed to switch parse line: ${errorMsg}`);
      this.state.playback.isError = true;
      this.state.playback.errorMessage = errorMsg;
    } finally {
      this.state.playback.isLoading = false;
    }
  }
  
  /**
   * 处理播放/暂停 | Handle play/pause
   */
  private async handlePlayPause(): Promise<void> {
    try {
      // 检查是否是NAS视频播放
      const routerParams = router.getParams();
      if (routerParams && routerParams.url) {
        // NAS视频播放控制
        this.state.playback.isPlaying = !this.state.playback.isPlaying;
        Logger.info(this.TAG, `NAS video ${this.state.playback.isPlaying ? 'playing' : 'paused'}`);
        return;
      }
      
      // 常规视频播放控制
      // 验证playbackService是否可用
      if (!this.playbackService) {
        Logger.error(this.TAG, 'Playback service not available');
        this.state.playback.isError = true;
        this.state.playback.errorMessage = '播放服务不可用';
        return;
      }
      
      let result: { isSuccess: () => boolean; message?: string };
      if (this.state.playback.isPlaying) {
        result = await this.playbackService.pause();
      } else {
        result = await this.playbackService.play();
      }
      
      if (result && typeof result.isSuccess === 'function' && result.isSuccess()) {
        this.state.playback.isPlaying = !this.state.playback.isPlaying;
        
        Logger.info(this.TAG, `${this.state.playback.isPlaying ? 'Playing' : 'Paused'}`);
      } else {
        const errorMessage = result && result.message ? result.message : '切换播放状态失败';
        Logger.error(this.TAG, `Failed to toggle playback: ${errorMessage}`);
        this.state.playback.isError = true;
        this.state.playback.errorMessage = errorMessage;
      }
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      Logger.error(this.TAG, `Failed to toggle playback: ${errorMsg}`);
      this.state.playback.isError = true;
      this.state.playback.errorMessage = errorMsg;
    }
  }
  
  /**
   * 处理播放速度调整 | Handle playback speed adjustment
   */
  private async handleSpeedChange(speed: number): Promise<void> {
    try {
      // 调用实际的PlaybackService调整播放速度 | Call actual PlaybackService to adjust playback speed
      const result = await this.playbackService.setPlaybackSpeed(speed);
      
      if (result.isSuccess()) {
        this.state.playback.playbackSpeed = speed;
        Logger.info(this.TAG, `Playback speed set to: ${speed}x`);
      } else {
        Logger.error(this.TAG, `Failed to change playback speed: ${result.message}`);
      }
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      Logger.error(this.TAG, `Failed to change playback speed: ${errorMsg}`);
    }
  }
  
  /**
   * 处理快进 | Handle fast forward
   */
  private async handleFastForward(seconds: number = 30): Promise<void> {
    try {
      // 检查是否是NAS视频播放
      const routerParams = router.getParams();
      if (routerParams && routerParams.url) {
        // NAS视频快进
        const targetTime = Math.min(this.state.playback.duration, this.state.playback.currentTime + seconds);
        this.state.playback.currentTime = targetTime;
        this.state.playback.progress = (targetTime / this.state.playback.duration) * 100;
        Logger.info(this.TAG, `NAS video fast forward ${seconds} seconds to ${targetTime}`);
        return;
      }
      
      // 常规视频快进
      const targetTime = this.state.playback.currentTime + seconds;
      // 调用实际的PlaybackService快进 | Call actual PlaybackService to fast forward
      const result = await this.playbackService.seek(targetTime);
      
      if (result.isSuccess()) {
        Logger.info(this.TAG, `Fast forward ${seconds} seconds`);
      } else {
        Logger.error(this.TAG, `Failed to fast forward: ${result.message}`);
      }
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      Logger.error(this.TAG, `Failed to fast forward: ${errorMsg}`);
    }
  }
  
  /**
   * 处理快退 | Handle rewind
   */
  private async handleRewind(seconds: number = 10): Promise<void> {
    try {
      // 检查是否是NAS视频播放
      const routerParams = router.getParams();
      if (routerParams && routerParams.url) {
        // NAS视频快退
        const targetTime = Math.max(0, this.state.playback.currentTime - seconds);
        this.state.playback.currentTime = targetTime;
        this.state.playback.progress = (targetTime / this.state.playback.duration) * 100;
        Logger.info(this.TAG, `NAS video rewind ${seconds} seconds to ${targetTime}`);
        return;
      }
      
      // 常规视频快退
      const targetTime = Math.max(0, this.state.playback.currentTime - seconds);
      // 调用实际的PlaybackService快退 | Call actual PlaybackService to rewind
      const result = await this.playbackService.seek(targetTime);
      
      if (result.isSuccess()) {
        Logger.info(this.TAG, `Rewind ${seconds} seconds`);
      } else {
        Logger.error(this.TAG, `Failed to rewind: ${result.message}`);
      }
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      Logger.error(this.TAG, `Failed to rewind: ${errorMsg}`);
    }
  }
  
  /**
   * 加载字幕 | Load subtitles
   */
  private async loadSubtitles(): Promise<void> {
    try {
      if (this.state.media.info) {
        this.state.subtitle.isSearching = true;
        Logger.info(this.TAG, `Searching subtitles for: ${this.state.media.info.title}`);
        
        // 生成缓存键 | Generate cache key
        const cacheKey = `subtitles_${this.state.media.info.id}_${this.state.media.info.title}`;
        
        // 尝试从缓存获取 | Try to get from cache
        const cachedTracks = await this.cacheService.get<SubtitleTrack[]>(cacheKey);
        
        if (cachedTracks && cachedTracks.length > 0) {
          this.state.subtitle.tracks = cachedTracks;
          this.state.subtitle.languages = this.subtitleService.getSupportedLanguages();
          
          Logger.info(this.TAG, `Found ${this.state.subtitle.tracks.length} subtitle tracks from cache`);
          this.state.subtitle.isSearching = false;
          return;
        }
        
        // 搜索字幕 | Search subtitles
        const result = await this.subtitleService.searchSubtitles({
          title: this.state.media.info.title,
          year: this.state.media.info.year,
          languages: ['zh', 'en']
        });
        
        if (result.isSuccess() && result.data) {
          // 合并所有提供商的字幕轨道 | Merge subtitle tracks from all providers
          const allTracks: SubtitleTrack[] = [];
          result.data.forEach((tracks) => {
            allTracks.push(...tracks);
          });
          
          this.state.subtitle.tracks = allTracks;
          this.state.subtitle.languages = this.subtitleService.getSupportedLanguages();
          
          // 缓存结果 | Cache result
          await this.cacheService.set(cacheKey, this.state.subtitle.tracks, {
            expiry: 604800000, // 7天缓存 7 days cache
            priority: CachePriority.NORMAL,
            tags: ['subtitles', 'media'],
            source: 'SubtitleService'
          });
          
          Logger.info(this.TAG, `Found ${this.state.subtitle.tracks.length} subtitle tracks from service`);
        } else {
          Logger.warn(this.TAG, `Failed to search subtitles: ${result.message}`);
        }
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to load subtitles: ${error}`);
    } finally {
      this.state.subtitle.isSearching = false;
    }
  }
  
  /**
   * 处理字幕选择 | Handle subtitle selection
   */
  private async handleSubtitleSelect(track: SubtitleTrack): Promise<void> {
    try {
      this.state.subtitle.selectedTrack = track;
      Logger.info(this.TAG, `Selected subtitle: ${track.name}`);
      
      // 如果是外部字幕，需要下载 | If external subtitle, need to download
      if (track.isExternal && track.url) {
        const downloadResult = await this.subtitleService.downloadSubtitle(track);
        if (downloadResult.isSuccess() && downloadResult.data) {
          const task = downloadResult.data;
          if (task.status === 'completed' && task.localPath) {
            // 更新字幕轨道的本地路径 | Update subtitle track's local path
            track.localPath = task.localPath;
            // 设置字幕 | Set subtitle
            await this.playbackService.setSubtitle(track);
          }
        }
      } else {
        // 直接设置字幕 | Set subtitle directly
        await this.playbackService.setSubtitle(track);
      }
      
      // 添加到历史记录 | Add to history
      if (this.state.media.info) {
        await this.subtitleService.addToHistory(this.state.media.info.id, track);
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to select subtitle: ${error}`);
    }
  }
  
  /**
   * 处理字幕样式设置 | Handle subtitle style setting
   */
  private async handleSubtitleStyleChange(): Promise<void> {
    try {
      const defaultStyle: SubtitleStyle = {
        fontSize: 24,
        fontFamily: 'sans-serif',
        fontWeight: 'normal',
        color: '#FFFFFF',
        backgroundColor: 'rgba(0, 0, 0, 0.7)',
        opacity: 1.0,
        borderWidth: 1,
        borderColor: '#000000'
      };
      await this.subtitleService.setSubtitleStyle(defaultStyle);
      await this.playbackService.updateSubtitleStyle(defaultStyle);
      Logger.info(this.TAG, 'Updated subtitle style');
    } catch (error) {
      Logger.error(this.TAG, `Failed to update subtitle style: ${error}`);
    }
  }
  
  /**
   * 处理其他线路搜索 | Handle other line search
   */
  private async handleOtherLineSearch(): Promise<void> {
    try {
      if (this.state.media.info) {
        // 调用实际的SearchService搜索其他线路 | Call actual SearchService to search other lines
        const result = await this.searchService.searchOtherSources(this.state.media.info.title);
        
        if (result.isSuccess() && result.data && result.data.length > 0) {
          // 这里可以显示其他线路的搜索结果 | Can show other line search results here
          Logger.info(this.TAG, `Found ${result.data.length} other sources for ${this.state.media.info.title}`);
        }
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to search other lines: ${error}`);
    }
  }
  
  /**
   * 处理返回 | Handle back
   */
  private async handleBack(): Promise<void> {
    try {
      // 停止播放 | Stop playback
      if (this.playbackService) {
        await this.playbackService.stop();
      }
      
      // 导航返回 | Navigate back
      const navigator = AppNavigator.getInstance();
      if (navigator) {
        await navigator.navigateToBack();
        Logger.info(this.TAG, 'Navigating back');
      } else {
        Logger.error(this.TAG, 'AppNavigator instance not available');
      }
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      Logger.error(this.TAG, `Failed to navigate back: ${errorMsg}`);
      // 即使出错也要尝试返回，确保用户可以退出页面
      try {
        const navigator = AppNavigator.getInstance();
        if (navigator) {
          await navigator.navigateToBack();
        }
      } catch (navError) {
        Logger.error(this.TAG, `Failed to navigate back even after error: ${navError}`);
      }
    }
  }
  
  // 格式化时间 | Format time
  private formatTime(seconds: number): string {
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  }
  
  /**
   * 处理跳过片头 | Handle skip opening
   */
  private async handleSkipOpening(): Promise<void> {
    try {
      // 记录当前时间作为跳过片头时间点 | Record current time as skip opening time
      this.state.skip.skipOpeningTime = Math.floor(this.state.playback.currentTime);
      this.state.skip.isSkipOpeningEnabled = true;
      
      // 保存到缓存 | Save to cache
      if (this.state.media.info) {
        const cacheKey = `skip_settings_${this.state.media.info.id}`;
        await this.cacheService.set(cacheKey, {
          skipOpeningTime: this.state.skip.skipOpeningTime,
          skipEndingTime: this.state.skip.skipEndingTime,
          isSkipOpeningEnabled: this.state.skip.isSkipOpeningEnabled,
          isSkipEndingEnabled: this.state.skip.isSkipEndingEnabled
        }, {
          expiry: 2592000000, // 30天缓存 | 30 days cache
          priority: CachePriority.HIGH,
          tags: ['skip_settings', 'media']
        });
      }
      
      // 立即跳转到当前时间 | Jump to current time immediately
      await this.playbackService.seek(this.state.playback.currentTime);
      Logger.info(this.TAG, `Skip opening time recorded: ${this.state.skip.skipOpeningTime}s`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to handle skip opening: ${error}`);
    }
  }
  
  /**
   * 处理跳过片尾 | Handle skip ending
   */
  private async handleSkipEnding(): Promise<void> {
    try {
      // 计算剩余时间作为跳过片尾时间点 | Calculate remaining time as skip ending time
      const remainingTime = Math.floor(this.state.playback.duration - this.state.playback.currentTime);
      this.state.skip.skipEndingTime = remainingTime;
      this.state.skip.isSkipEndingEnabled = true;
      
      // 保存到缓存 | Save to cache
      if (this.state.media.info) {
        const cacheKey = `skip_settings_${this.state.media.info.id}`;
        await this.cacheService.set(cacheKey, {
          skipOpeningTime: this.state.skip.skipOpeningTime,
          skipEndingTime: this.state.skip.skipEndingTime,
          isSkipOpeningEnabled: this.state.skip.isSkipOpeningEnabled,
          isSkipEndingEnabled: this.state.skip.isSkipEndingEnabled
        }, {
          expiry: 2592000000, // 30天缓存 | 30 days cache
          priority: CachePriority.HIGH,
          tags: ['skip_settings', 'media']
        });
      }
      
      Logger.info(this.TAG, `Skip ending time recorded: ${this.state.skip.skipEndingTime}s`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to handle skip ending: ${error}`);
    }
  }
  
  /**
   * 检查是否需要自动跳过 | Check if auto skip is needed
   */
  private async checkAutoSkip(): Promise<void> {
    try {
      if (!this.state.media.info) return;
      
      // 尝试从缓存加载跳过设置 | Try to load skip settings from cache
      const cacheKey = `skip_settings_${this.state.media.info.id}`;
      const cachedSettings = await this.cacheService.get<{ skipOpeningTime?: number; skipEndingTime?: number; isSkipOpeningEnabled?: boolean; isSkipEndingEnabled?: boolean }>(cacheKey);
      
      if (cachedSettings) {
        this.state.skip.skipOpeningTime = cachedSettings.skipOpeningTime || 90;
        this.state.skip.skipEndingTime = cachedSettings.skipEndingTime || 300;
        this.state.skip.isSkipOpeningEnabled = cachedSettings.isSkipOpeningEnabled !== false;
        this.state.skip.isSkipEndingEnabled = cachedSettings.isSkipEndingEnabled !== false;
        Logger.info(this.TAG, `Loaded skip settings from cache`);
      }
      
      // 检查是否需要跳过片头 | Check if need to skip opening
      if (this.state.skip.isSkipOpeningEnabled && this.state.playback.currentTime < 5) {
        await this.playbackService.seek(this.state.skip.skipOpeningTime);
        Logger.info(this.TAG, `Auto skipped opening to ${this.state.skip.skipOpeningTime}s`);
      }
      
      // 检查是否需要跳过片尾 | Check if need to skip ending
      if (this.state.skip.isSkipEndingEnabled && this.state.playback.duration > 0) {
        const remainingTime = this.state.playback.duration - this.state.playback.currentTime;
        if (remainingTime <= this.state.skip.skipEndingTime + 2) {
          // 跳转到下一集 | Jump to next episode
          const currentIndex = this.state.media.episodes.findIndex(ep => ep.current);
          if (currentIndex < this.state.media.episodes.length - 1) {
            await this.handleEpisodeSelect(this.state.media.episodes[currentIndex + 1]);
          }
          Logger.info(this.TAG, `Auto skipped ending, jumping to next episode`);
        }
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to check auto skip: ${error}`);
    }
  }
  
  // 处理控制条显示 | Handle control bar show
  private showControlsWithTimer(): void {
    this.state.ui.showControls = true;
    this.resetControlHideTimer();
  }
  
  // 重置控制条隐藏计时器 | Reset control bar hide timer
  private resetControlHideTimer(): void {
    // 清除之前的计时器 | Clear previous timer
    if (this.state.ui.controlHideTimer !== null) {
      this.timerManager.clearTimeout(this.state.ui.controlHideTimer);
    }

    // 设置新的计时器，5秒后隐藏控制条 | Set new timer to hide controls after 5 seconds
    this.state.ui.controlHideTimer = this.timerManager.setTimeout(() => {
      this.state.ui.showControls = false;
    }, 5000, 'PlaybackPage.controlHide');
  }
  
  // 处理键盘事件 | Handle keyboard events
  private onKeyEvent(e: KeyEvent): boolean {
    if (e.type === KeyEvent.KeyType.DOWN) {
      // 重置控制条隐藏计时器 | Reset control bar hide timer on any key press
      if (this.state.ui.showControls) {
        this.resetControlHideTimer();
      }
      
      // 直播模式处理 | Live mode handling
      if (this.state.live.isLiveMode) {
        switch (e.keyCode) {
          case KeyEvent.KeyCode.KEY_ENTER:
          case KeyEvent.KeyCode.KEY_SPACE:
            // 显示进度条 | Show progress bar
            this.showControlsWithTimer();
            return true;
          case KeyEvent.KeyCode.KEY_BACK:
            // 处理返回键 | Handle back key
            this.handleBack();
            return true;
          case KeyEvent.KeyCode.KEY_UP:
            // 切换到上一个频道 | Switch to previous channel
            this.switchChannel(-1);
            return true;
          case KeyEvent.KeyCode.KEY_DOWN:
            // 切换到下一个频道 | Switch to next channel
            this.switchChannel(1);
            return true;
          case KeyEvent.KeyCode.KEY_LEFT:
            // 显示频道列表 | Show channel list
            this.state.live.showChannelList = true;
            return true;
          case KeyEvent.KeyCode.KEY_RIGHT:
            // 显示直播设置 | Show live settings
            this.state.live.showSettings = true;
            return true;
          default:
            return false;
        }
      }
      
      // 非直播模式处理 | Non-live mode handling
      switch (e.keyCode) {
        case KeyEvent.KeyCode.KEY_ENTER:
        case KeyEvent.KeyCode.KEY_SPACE:
          // 处理确认键 | Handle confirm key
          return true;
        case KeyEvent.KeyCode.KEY_BACK:
          // 处理返回键 | Handle back key
          this.handleBack();
          return true;
        case KeyEvent.KeyCode.KEY_UP:
          // 处理上方向键 | Handle up arrow
          if (this.state.ui.showControls) {
            this.focusManager.moveUp();
          }
          return true;
        case KeyEvent.KeyCode.KEY_DOWN:
          // 处理下方向键 | Handle down arrow
          if (!this.state.ui.showControls) {
            // 显示控制条 | Show controls
            this.showControlsWithTimer();
          } else {
            // 导航到下一个控制按钮 | Navigate to next control button
            this.focusManager.moveDown();
          }
          return true;
        case KeyEvent.KeyCode.KEY_LEFT:
          // 处理左方向键 | Handle left arrow
          if (!this.state.ui.showControls) {
            // 快退10秒 | Rewind 10 seconds
            this.handleRewind(10);
          } else {
            // 导航到左侧控制按钮 | Navigate to left control button
            this.focusManager.moveLeft();
          }
          return true;
        case KeyEvent.KeyCode.KEY_RIGHT:
          // 处理右方向键 | Handle right arrow
          if (!this.state.ui.showControls) {
            // 快进30秒 | Fast forward 30 seconds
            this.handleFastForward(30);
          } else {
            // 导航到右侧控制按钮 | Navigate to right control button
            this.focusManager.moveRight();
          }
          return true;
        default:
          return false;
      }
    }
    return false;
  }
  
  // 处理触摸事件 | Handle touch events
  private onTouchEvent(e: TouchEvent): void {
    switch (e.type) {
      case TouchEvent.TouchType.DOWN:
        // 触摸开始 | Touch start
        this.resetControlHideTimer();
        break;
      case TouchEvent.TouchType.UP:
        // 触摸结束 | Touch end
        break;
      case TouchEvent.TouchType.MOVE:
        // 触摸移动 | Touch move
        break;
    }
  }
  
  // 处理手势事件 | Handle gesture events
  private onGestureEvent(e: GestureEvent): void {
    switch (e.type) {
      case GestureEvent.GestureType.SWIPE:
        // 处理滑动手势 | Handle swipe gesture
        switch (e.direction) {
          case GestureEvent.Direction.LEFT:
            // 向左滑动 | Swipe left
            if (!this.state.ui.showControls) {
              this.handleFastForward(30);
            }
            break;
          case GestureEvent.Direction.RIGHT:
            // 向右滑动 | Swipe right
            if (!this.state.ui.showControls) {
              this.handleRewind(10);
            }
            break;
          case GestureEvent.Direction.UP:
            // 向上滑动 | Swipe up
            break;
          case GestureEvent.Direction.DOWN:
            // 向下滑动 | Swipe down
            if (!this.state.ui.showControls) {
              this.showControlsWithTimer();
            }
            break;
        }
        break;
      case GestureEvent.GestureType.TAP:
        // 处理点击手势 | Handle tap gesture
        if (!this.state.ui.showControls) {
          this.showControlsWithTimer();
        }
        break;
      case GestureEvent.GestureType.LONG_PRESS:
        // 处理长按手势 | Handle long press gesture
        break;
    }
  }
  
  // 切换频道 | Switch channel
  private async switchChannel(direction: number): Promise<void> {
    try {
      // 实现频道切换逻辑 | Implement channel switching logic
      Logger.info(this.TAG, `Switching channel ${direction > 0 ? 'up' : 'down'}`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to switch channel: ${error}`);
    }
  }
  
  // 清理资源 | Clean up resources
  aboutToDisappear(): void {
    Logger.info(this.TAG, 'PlaybackPage about to disappear');
    
    // 清除定时器 | Clear timer
    if (this.state.ui.controlHideTimer !== null) {
      this.timerManager.clearTimeout(this.state.ui.controlHideTimer);
      this.state.ui.controlHideTimer = null;
    }
    
    // 停止播放 | Stop playback
    if (this.playbackService) {
      this.playbackService.stop();
    }
    
    // 清理所有定时器 | Clear all timers
    this.timerManager.clearAll();
  }
  
  // 渲染视频播放区域 | Render video playback area
  @Builder
  renderVideoPlayer() {
    Column() {
      if (this.state.playback.isLoading) {
        Column() {
          // 加载动画 | Loading animation
          Column() {
            Text('加载中...')
              .fontSize(24)
              .fontColor('#FFFFFF')
              .margin({ bottom: 20 })
            // 加载指示器 | Loading indicator
            Row() {
              ForEach([1, 2, 3, 4, 5], (item: number) => {
                Column() {
                  Text('.')
                    .fontSize(32)
                    .fontColor('#4CAF50')
                    .fontWeight(700)
                }
                .animation({
                  duration: 800,
                  tempo: 1,
                  curve: Curve.EaseInOut,
                  iterations: -1,
                  delay: item * 100
                })
              })
            }
          }
        }
        .justifyContent(FlexAlign.Center)
        .width('100%')
        .height(this.state.ui.videoPlayerHeight)
        .backgroundColor('rgba(0, 0, 0, 0.9)')
        .touchEventListener((e) => this.onTouchEvent(e))
        .gestureEventListener((e) => this.onGestureEvent(e))
      } else if (this.state.playback.isError) {
        Column() {
          Text('播放失败')
            .fontSize(28)
            .fontColor('#FF5722')
            .fontWeight(700)
            .margin({ top: 20 })
          Text(this.state.playback.errorMessage)
            .fontSize(18)
            .fontColor('#FFFFFF')
            .margin({ top: 12, left: 40, right: 40 })
            .textAlign(TextAlign.Center)
          Button() {
            Text('重试')
              .fontSize(18)
              .fontColor('#FFFFFF')
              .fontWeight(600)
          }
          .padding({ left: 40, right: 40, top: 15, bottom: 15 })
          .backgroundColor('#4CAF50')
          .borderRadius(16)
          .margin({ top: 30 })
          .onClick(() => {
            this.state.playback.isError = false;
            this.loadMediaInfo();
          })
          .focusable(true)
          .focusStyle(this.focusStyle)
          .onFocus(() => {
            Logger.info(this.TAG, 'Retry button focused');
          })
          .keyEventListener((e) => this.onKeyEvent(e))
          Button() {
            Text('返回')
              .fontSize(18)
              .fontColor('#FFFFFF')
              .fontWeight(600)
          }
          .padding({ left: 40, right: 40, top: 15, bottom: 15 })
          .backgroundColor('#607D8B')
          .borderRadius(16)
          .margin({ top: 15 })
          .onClick(() => this.handleBack())
          .focusable(true)
          .focusStyle(this.focusStyle)
          .onFocus(() => {
            Logger.info(this.TAG, 'Back button focused');
          })
          .keyEventListener((e) => this.onKeyEvent(e))
        }
        .justifyContent(FlexAlign.Center)
        .width('100%')
        .height(this.state.ui.videoPlayerHeight)
        .backgroundColor('rgba(0, 0, 0, 0.9)')
        .touchEventListener((e) => this.onTouchEvent(e))
        .gestureEventListener((e) => this.onGestureEvent(e))
      } else {
        Column() {
          // 视频播放区域 | Video playback area
          Stack() {
            Column() {
              Text('视频播放区域')
                .fontSize(20)
                .fontColor('#FFFFFF')
            }
            .width('100%')
            .height(this.state.ui.videoPlayerHeight - 80)
            .backgroundColor('#000000')
            .justifyContent(FlexAlign.Center)
            .touchEventListener((e) => this.onTouchEvent(e))
            .gestureEventListener((e) => this.onGestureEvent(e))
            
            // 播放控制组件 | Playback controls component
            PlaybackControls({
              isPlaying: this.state.playback.isPlaying,
              currentTime: this.state.playback.currentTime,
              duration: this.state.playback.duration,
              progress: this.state.playback.progress,
              showControls: this.state.ui.showControls,
              selectedSubtitle: this.state.subtitle.selectedTrack,
              showSkipOptions: this.state.ui.showSkipOptions,
              showSubtitleOptions: this.state.ui.showSubtitleOptions,
              showAudioTrackOptions: this.state.ui.showAudioTrackOptions,
              audioTracks: this.state.audio.tracks,
              selectedAudioTrack: this.state.audio.selectedTrack,
              videoPlayerHeight: this.state.ui.videoPlayerHeight,
              onPlayPause: () => this.handlePlayPause(),
              onFastForward: (seconds: number) => this.handleFastForward(seconds),
              onRewind: (seconds: number) => this.handleRewind(seconds),
              onShowSkipOptions: () => this.state.ui.showSkipOptions = !this.state.ui.showSkipOptions,
              onShowSubtitleOptions: () => this.state.ui.showSubtitleOptions = !this.state.ui.showSubtitleOptions,
              onShowAudioTrackOptions: () => this.state.ui.showAudioTrackOptions = !this.state.ui.showAudioTrackOptions,
              onKeyEvent: (e: KeyEvent) => this.onKeyEvent(e)
            })
          }
          
          // 跳过设置组件 | Skip settings component
          SkipSettings({
            showSkipOptions: this.state.ui.showSkipOptions,
            isSkipOpeningEnabled: this.state.skip.isSkipOpeningEnabled,
            isSkipEndingEnabled: this.state.skip.isSkipEndingEnabled,
            skipOpeningTime: this.state.skip.skipOpeningTime,
            skipEndingTime: this.state.skip.skipEndingTime,
            onToggleSkipOpening: () => this.state.skip.isSkipOpeningEnabled = !this.state.skip.isSkipOpeningEnabled,
            onToggleSkipEnding: () => this.state.skip.isSkipEndingEnabled = !this.state.skip.isSkipEndingEnabled,
            onSetSkipOpeningTime: () => this.handleSkipOpening(),
            onSetSkipEndingTime: () => this.handleSkipEnding()
          })
        }
      }
    }
  }
  
  build() {
    Column() {
      // 顶部导航栏 | Top navigation bar
      Row() {
        // 返回按钮 | Back button
        Button() {
          Text('返回')
            .fontSize(18)
            .fontColor('#FFFFFF')
            .fontWeight(500)
        }
        .width(100)
        .height(60)
        .backgroundColor('#4CAF50')
        .borderRadius(12)
        .margin({ left: this.state.ui.isLandscape ? 40 : 30 })
        .onClick(() => this.handleBack())
        .focusable(true)
        .onFocus(() => {
          Logger.info(this.TAG, 'Back button focused');
        })
        
        // 标题 | Title
        Text('播放详情')
          .fontSize(22)
          .fontWeight(700)
          .fontColor('#333333')
          .flexGrow(1)
          .margin({ left: this.state.ui.isLandscape ? 40 : 30 })
          .textAlign(TextAlign.Start)
        
        // 更多按钮 | More button
        Button() {
          Text('更多')
            .fontSize(16)
            .fontColor('#FFFFFF')
            .fontWeight(500)
        }
        .width(100)
        .height(60)
        .backgroundColor('#2196F3')
        .borderRadius(12)
        .margin({ right: this.state.ui.isLandscape ? 40 : 30 })
        .onClick(() => this.state.ui.showMoreOptions = !this.state.ui.showMoreOptions)
        .focusable(true)
        .onFocus(() => {
          Logger.info(this.TAG, 'More button focused');
        })
      }
      .width('100%')
      .height(80)
      .alignItems(VerticalAlign.Center)
      .backgroundColor('#FFFFFF')
      .borderBottomWidth(2)
      .borderBottomColor('#E0E0E0')
      .shadow({ radius: 4, color: 'rgba(0, 0, 0, 0.1)', offsetY: 2 })
      
      // 视频播放区域 | Video playback area
      this.renderVideoPlayer()
      
      // 媒体信息组件 | Media info component
      if (this.state.media.info) {
        MediaInfoComponent({
          mediaInfo: this.state.media.info,
          parseLines: this.state.media.parseLines,
          isLandscape: this.state.ui.isLandscape,
          onLineSelect: (line: ParseLine) => this.handleLineSelect(line),
          focusStyle: this.focusStyle
        })
      }
      
      // 剧集列表组件 | Episode list component
      EpisodeListComponent({
        episodes: this.state.media.episodes,
        isLandscape: this.state.ui.isLandscape,
        onEpisodeSelect: (episode: Episode) => this.handleEpisodeSelect(episode),
        onOtherLineSearch: () => this.handleOtherLineSearch()
      })
      
      // 播放速度选项组件 | Playback speed component
      PlaybackSpeedComponent({
        showMoreOptions: this.state.ui.showMoreOptions,
        playbackSpeed: this.state.playback.playbackSpeed,
        onSpeedChange: (speed: number) => this.handleSpeedChange(speed)
      })
      
      // 字幕选项组件 | Subtitle options component
      SubtitleOptionsComponent({
        showSubtitleOptions: this.state.ui.showSubtitleOptions,
        subtitleTracks: this.state.subtitle.tracks,
        selectedSubtitle: this.state.subtitle.selectedTrack,
        isSearchingSubtitles: this.state.subtitle.isSearching,
        onSubtitleSelect: (track: SubtitleTrack) => this.handleSubtitleSelect(track),
        onSubtitleStyleChange: () => this.handleSubtitleStyleChange()
      })
      
      // 音轨选项组件 | Audio track options component
      AudioTrackOptionsComponent({
        showAudioTrackOptions: this.state.ui.showAudioTrackOptions,
        audioTracks: this.state.audio.tracks,
        selectedAudioTrack: this.state.audio.selectedTrack,
        onAudioTrackSelect: (track: AudioTrack) => {
          this.state.audio.selectedTrack = track;
          this.playbackService.setAudioTrack(track.id);
        }
      })
    }
  }
}
