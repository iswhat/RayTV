import { AppNavigator, DetailParams } from '../navigation/AppNavigator';
import Logger from '../common/util/Logger';
import { MediaService } from '../service/media/MediaService';
import { PlaybackService } from '../service/playback/PlaybackService';
import { AVPlayerService } from '../service/playback/AVPlayerService';
import { SearchService } from '../service/search/SearchService';
import SubtitleService, { SubtitleTrack, SubtitleProvider, SubtitleLanguage } from '../service/media/SubtitleService';
import TimerManager from '../common/util/TimerManager';
import { ErrorHandler, ErrorType, ErrorSeverity } from '../common/util/ErrorHandler';

import CacheService, { CachePriority } from '../service/cache/CacheService';
import { getPlaybackViewModel, PlaybackViewModel } from '../viewmodel/PlaybackViewModel';
import display from '@ohos.display';
import { theme } from '../common/theme/ThemeConfig';

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
import {
  ParseLine,
  MediaInfo,
  AudioTrack,
  SubtitleStyle,
  PlaybackSettings,
  Episode,
  FocusStyle,
  PlaybackState,
  UiState,
  SubtitleState,
  AudioState,
  SkipState,
  LiveState,
  MediaState,
  PlaybackStateCallback
} from './playback/types/PlaybackTypes';

// 导入焦点管理器 | Import focus manager
import { FocusManager } from './playback/utils/FocusManager';

@Entry
@Component
struct PlaybackPage {
  private readonly TAG: string = 'PlaybackPage';

  // 统一状态管理 | Unified state management
  @State state: {
    media: MediaState;
    playback: PlaybackState;
    ui: UiState;
    subtitle: SubtitleState;
    audio: AudioState;
    skip: SkipState;
    live: LiveState;
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
      playbackSpeed: theme.getPlayback().defaultSpeed,
      isLoading: true,
      isError: false,
      errorMessage: '加载失败',
      hasResumePoint: false,
      resumeMessage: ''
    },
    ui: {
      isLandscape: false,
      screenWidth: 0,
      screenHeight: 0,
      showControls: false,
      showEpisodeList: true,
      showMoreOptions: false,
      showSubtitleOptions: false,
      showAudioTrackOptions: false,
      showSkipOptions: false,
      videoPlayerHeight: 0,
      controlHideTimer: null,
      currentFocusElement: '',
      showResumeDialog: false
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
      skipOpeningTime: theme.getPlayback().skipOpeningTime,
      skipEndingTime: theme.getPlayback().skipEndingTime,
      isSkipOpeningEnabled: true,
      isSkipEndingEnabled: true
    },
    live: {
      isLiveMode: false,
      showChannelList: false,
      showSettings: false
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
  private errorHandler: ErrorHandler = ErrorHandler.getInstance();

  // 生命周期 | Lifecycle
  aboutToAppear(): void {
    Logger.info(this.TAG, 'PlaybackPage about to appear');

    // 初始化屏幕信息 | Initialize screen information
    this.initScreenInfo();

    // 绑定ViewModel状态 | Bind ViewModel state
    this.bindViewModel();

    // 初始化播放 | Initialize playback
    this.initPlayback();
  }

  // 初始化屏幕信息 | Initialize screen information
  private initScreenInfo(): void {
    try {
      const displayInfo = display.getDefaultDisplaySync();
      const width: number = displayInfo.width;
      const height: number = displayInfo.height;

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
    this.viewModel.mediaState.subscribe((mediaState: MediaState) => {
      this.state.media = mediaState;
    });

    // 绑定播放控制状态
    this.viewModel.controlState.subscribe((controlState: PlaybackState) => {
      this.state.playback = controlState;
    });

    // 绑定UI状态
    this.viewModel.uiState.subscribe((uiState: UiState) => {
      this.state.ui = uiState;
    });

    // 绑定字幕状态
    this.viewModel.subtitleState.subscribe((subtitleState: SubtitleState) => {
      this.state.subtitle = subtitleState;
    });

    // 绑定音轨状态
    this.viewModel.audioState.subscribe((audioState: AudioState) => {
      this.state.audio = audioState;
    });

    // 绑定跳过设置状态
    this.viewModel.skipState.subscribe((skipState: SkipState) => {
      this.state.skip = skipState;
    });

    // 绑定直播状态
    this.viewModel.liveState.subscribe((liveState: LiveState) => {
      this.state.live = liveState;
    });

    Logger.info(this.TAG, 'ViewModel state binding completed');
  }

  // 初始化播放 | Initialize playback
  private async initPlayback(): Promise<void> {
    try {
      // 尝试从router获取参数（NAS播放）
      const routerParams: Record<string, string | number> = router.getParams() as Record<string, string | number>;
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
      const params: DetailParams = AppNavigator.getInstance().getCurrentRouteParams();

      if (!params || !params.id || !params.siteKey) {
        const error: Error = new Error('缺少必要的路由参数');
        this.errorHandler.handleError(error, ErrorType.PARAMETER, ErrorSeverity.MEDIUM, this.TAG);
        this.state.playback.isError = true;
        this.state.playback.errorMessage = '缺少必要的播放参数';
        this.state.playback.isLoading = false;
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
      this.errorHandler.handleError(error, ErrorType.PLAYBACK, ErrorSeverity.HIGH, this.TAG);
      this.state.playback.isError = true;
      this.state.playback.errorMessage = this.errorHandler.getFriendlyMessage(error);
      this.state.playback.isLoading = false;
    }
  }

  /**
   * 加载媒体信息 | Load media info
   */
  private async loadMediaInfo(): Promise<void> {
    try {
      this.state.playback.isLoading = true;
      this.state.playback.isError = false;

      // 获取路由参数并验证
      const params: DetailParams = AppNavigator.getInstance().getCurrentRouteParams();

      if (!params || !params.id || !params.siteKey) {
        const error: Error = new Error('缺少必要的路由参数');
        this.errorHandler.handleError(error, ErrorType.PARAMETER, ErrorSeverity.MEDIUM, this.TAG);
        this.state.playback.isError = true;
        this.state.playback.errorMessage = '缺少必要的播放参数';
        this.state.playback.isLoading = false;
        return;
      }

      Logger.info(this.TAG, `Loading media info for: ${params.id} from ${params.siteKey}`);

      // 生成缓存键 | Generate cache key
      const cacheKey: string = `media_info_${params.id}_${params.siteKey}_${params.type}`;

      // 尝试从缓存获取 | Try to get from cache
      try {
        const cachedInfo: MediaInfo | null = await this.cacheService.get<MediaInfo>(cacheKey);

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
      } catch (cacheError) {
        this.errorHandler.handleError(cacheError, ErrorType.CACHE, ErrorSeverity.LOW, this.TAG);
        Logger.warn(this.TAG, `Cache error, falling back to service: ${cacheError}`);
      }

      // 调用实际的MediaService获取媒体信息 | Call actual MediaService to get media info
      try {
        const result = await this.mediaService.getMediaDetail(params.id, params.siteKey, params.type);

        if (result.isSuccess() && result.data) {
          this.state.media.info = result.data;

          // 缓存结果 | Cache result
          try {
            await this.cacheService.set(cacheKey, this.state.media.info, {
              expiry: 86400000, // 24小时缓存
              priority: CachePriority.HIGH,
              tags: ['media', 'detail'],
              source: 'MediaService'
            });
          } catch (cacheError) {
            this.errorHandler.handleError(cacheError, ErrorType.CACHE, ErrorSeverity.LOW, this.TAG);
            Logger.warn(this.TAG, `Failed to cache media info: ${cacheError}`);
          }

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
          const error: Error = new Error(result.message || '加载媒体信息失败');
          this.errorHandler.handleError(error, ErrorType.MEDIA, ErrorSeverity.MEDIUM, this.TAG);
          this.state.playback.isError = true;
          this.state.playback.errorMessage = this.errorHandler.getFriendlyMessage(error);
          Logger.warn(this.TAG, `Failed to load media info: ${this.state.playback.errorMessage}`);
        }
      } catch (serviceError) {
        this.errorHandler.handleError(serviceError, ErrorType.NETWORK, ErrorSeverity.HIGH, this.TAG);
        this.state.playback.isError = true;
        this.state.playback.errorMessage = this.errorHandler.getFriendlyMessage(serviceError);
      }
    } catch (error) {
      this.errorHandler.handleError(error, ErrorType.UNKNOWN, ErrorSeverity.HIGH, this.TAG);
      this.state.playback.isError = true;
      this.state.playback.errorMessage = this.errorHandler.getFriendlyMessage(error);
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
  private async initPlaybackService(): Promise<void> {
    try {
      if (this.state.media.selectedEpisode && this.state.media.selectedLine) {
        // 调用实际的PlaybackService初始化播放
        await this.playbackService.initPlayback({
          episode: this.state.media.selectedEpisode,
          line: this.state.media.selectedLine,
          mediaInfo: this.state.media.info
        });

        // 监听播放状态
        this.playbackService.onPlaybackStateChange((state: PlaybackStateCallback) => {
          this.state.playback.isPlaying = state.isPlaying;
          this.state.playback.currentTime = state.currentTime;
          this.state.playback.duration = state.duration;
          this.state.playback.progress = state.progress;

          // 检查是否需要自动跳过
          this.checkAutoSkip();

          // 加载音轨信息
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
      // 验证剧集数据完整性
      if (!episode || !episode.id || !episode.title) {
        const error: Error = new Error('无效的剧集数据：缺少必要字段');
        this.errorHandler.handleError(error, ErrorType.PARAMETER, ErrorSeverity.MEDIUM, this.TAG);
        this.state.playback.isError = true;
        this.state.playback.errorMessage = '无效的剧集数据';
        return;
      }

      this.state.media.selectedEpisode = episode;
      // 更新剧集状态
      this.state.media.episodes.forEach((ep: Episode) => {
        ep.current = ep.id === episode.id;
      });

      // 显示加载状态
      this.state.playback.isLoading = true;
      this.state.playback.isError = false;

      // 验证playbackService是否可用
      if (!this.playbackService) {
        const error: Error = new Error('播放服务不可用');
        this.errorHandler.handleError(error, ErrorType.SERVICE, ErrorSeverity.HIGH, this.TAG);
        this.state.playback.isError = true;
        this.state.playback.errorMessage = '播放服务不可用，请重试';
        this.state.playback.isLoading = false;
        return;
      }

      // 调用实际的PlaybackService切换剧集
      try {
        const result = await this.playbackService.switchEpisode(episode);

        if (result && typeof result.isSuccess === 'function' && result.isSuccess()) {
          Logger.info(this.TAG, `Selected episode: ${episode.title}`);
        } else {
          const errorMessage: string = result && result.message ? result.message : '切换剧集失败';
          const error: Error = new Error(errorMessage);
          this.errorHandler.handleError(error, ErrorType.PLAYBACK, ErrorSeverity.MEDIUM, this.TAG);
          this.state.playback.isError = true;
          this.state.playback.errorMessage = this.errorHandler.getFriendlyMessage(error);
          Logger.warn(this.TAG, `Failed to switch episode: ${this.state.playback.errorMessage}`);
        }
      } catch (playbackError) {
        this.errorHandler.handleError(playbackError, ErrorType.PLAYBACK, ErrorSeverity.HIGH, this.TAG);
        this.state.playback.isError = true;
        this.state.playback.errorMessage = this.errorHandler.getFriendlyMessage(playbackError);
      }
    } catch (error) {
      this.errorHandler.handleError(error, ErrorType.UNKNOWN, ErrorSeverity.HIGH, this.TAG);
      this.state.playback.isError = true;
      this.state.playback.errorMessage = this.errorHandler.getFriendlyMessage(error);
    } finally {
      this.state.playback.isLoading = false;
    }
  }

  /**
   * 处理解析线路选择 | Handle parse line selection
   */
  private async handleLineSelect(line: ParseLine): Promise<void> {
    try {
      // 验证线路数据完整性
      if (!line || !line.id || !line.name) {
        const error: Error = new Error('无效的解析线路数据');
        this.errorHandler.handleError(error, ErrorType.PARAMETER, ErrorSeverity.MEDIUM, this.TAG);
        return;
      }

      // 更新选中的线路
      this.state.media.selectedLine = line;
      this.state.media.parseLines.forEach((l: ParseLine) => {
        l.selected = l.id === line.id;
      });

      Logger.info(this.TAG, `Selected parse line: ${line.name}`);

      // 重新初始化播放
      if (this.state.media.selectedEpisode) {
        await this.handleEpisodeSelect(this.state.media.selectedEpisode);
      }
    } catch (error) {
      this.errorHandler.handleError(error, ErrorType.PLAYBACK, ErrorSeverity.MEDIUM, this.TAG);
      Logger.error(this.TAG, `Failed to switch line: ${error}`);
    }
  }

  /**
   * 处理播放/暂停 | Handle play/pause
   */
  private handlePlayPause(): void {
    try {
      if (this.state.playback.isPlaying) {
        this.playbackService.pause();
      } else {
        this.playbackService.play();
      }
    } catch (error) {
      this.errorHandler.handleError(error, ErrorType.PLAYBACK, ErrorSeverity.LOW, this.TAG);
      Logger.error(this.TAG, `Failed to toggle play/pause: ${error}`);
    }
  }

  /**
   * 处理快进 | Handle fast forward
   */
  private handleFastForward(seconds: number): void {
    try {
      const newTime: number = Math.min(
        this.state.playback.currentTime + seconds,
        this.state.playback.duration
      );
      this.playbackService.seek(newTime);
      Logger.info(this.TAG, `Fast forward ${seconds}s to ${newTime}s`);
    } catch (error) {
      this.errorHandler.handleError(error, ErrorType.PLAYBACK, ErrorSeverity.LOW, this.TAG);
      Logger.error(this.TAG, `Failed to fast forward: ${error}`);
    }
  }

  /**
   * 处理快退 | Handle rewind
   */
  private handleRewind(seconds: number): void {
    try {
      const newTime: number = Math.max(this.state.playback.currentTime - seconds, 0);
      this.playbackService.seek(newTime);
      Logger.info(this.TAG, `Rewind ${seconds}s to ${newTime}s`);
    } catch (error) {
      this.errorHandler.handleError(error, ErrorType.PLAYBACK, ErrorSeverity.LOW, this.TAG);
      Logger.error(this.TAG, `Failed to rewind: ${error}`);
    }
  }

  /**
   * 处理返回 | Handle back
   */
  private handleBack(): void {
    try {
      // 停止播放
      this.playbackService.stop();
      // 返回上一页
      AppNavigator.getInstance().goBack();
    } catch (error) {
      this.errorHandler.handleError(error, ErrorType.NAVIGATION, ErrorSeverity.LOW, this.TAG);
      Logger.error(this.TAG, `Failed to go back: ${error}`);
    }
  }

  /**
   * 处理播放速度变化 | Handle playback speed change
   */
  private handleSpeedChange(speed: number): void {
    try {
      this.state.playback.playbackSpeed = speed;
      this.playbackService.setPlaybackSpeed(speed);
      Logger.info(this.TAG, `Playback speed changed to ${speed}x`);
    } catch (error) {
      this.errorHandler.handleError(error, ErrorType.PLAYBACK, ErrorSeverity.LOW, this.TAG);
      Logger.error(this.TAG, `Failed to change playback speed: ${error}`);
    }
  }

  /**
   * 处理字幕选择 | Handle subtitle selection
   */
  private handleSubtitleSelect(track: SubtitleTrack): void {
    try {
      this.state.subtitle.selectedTrack = track;
      this.playbackService.setSubtitle(track.id);
      Logger.info(this.TAG, `Selected subtitle: ${track.name}`);
    } catch (error) {
      this.errorHandler.handleError(error, ErrorType.MEDIA, ErrorSeverity.LOW, this.TAG);
      Logger.error(this.TAG, `Failed to select subtitle: ${error}`);
    }
  }

  /**
   * 处理字幕样式变化 | Handle subtitle style change
   */
  private handleSubtitleStyleChange(): void {
    try {
      // 实现字幕样式变化逻辑
      Logger.info(this.TAG, 'Subtitle style changed');
    } catch (error) {
      this.errorHandler.handleError(error, ErrorType.MEDIA, ErrorSeverity.LOW, this.TAG);
      Logger.error(this.TAG, `Failed to change subtitle style: ${error}`);
    }
  }

  /**
   * 处理跳过片头设置 | Handle skip opening settings
   */
  private handleSkipOpening(): void {
    try {
      // 实现跳过片头设置逻辑
      Logger.info(this.TAG, `Skip opening settings: ${this.state.skip.isSkipOpeningEnabled}, time: ${this.state.skip.skipOpeningTime}s`);
    } catch (error) {
      this.errorHandler.handleError(error, ErrorType.PLAYBACK, ErrorSeverity.LOW, this.TAG);
      Logger.error(this.TAG, `Failed to handle skip opening: ${error}`);
    }
  }

  /**
   * 处理跳过片尾设置 | Handle skip ending settings
   */
  private handleSkipEnding(): void {
    try {
      // 实现跳过片尾设置逻辑
      Logger.info(this.TAG, `Skip ending settings: ${this.state.skip.isSkipEndingEnabled}, time: ${this.state.skip.skipEndingTime}s`);
    } catch (error) {
      this.errorHandler.handleError(error, ErrorType.PLAYBACK, ErrorSeverity.LOW, this.TAG);
      Logger.error(this.TAG, `Failed to handle skip ending: ${error}`);
    }
  }

  /**
   * 处理其他线路搜索 | Handle other line search
   */
  private handleOtherLineSearch(): void {
    try {
      // 实现其他线路搜索逻辑
      Logger.info(this.TAG, 'Searching other lines...');
    } catch (error) {
      this.errorHandler.handleError(error, ErrorType.SEARCH, ErrorSeverity.LOW, this.TAG);
      Logger.error(this.TAG, `Failed to search other lines: ${error}`);
    }
  }

  /**
   * 加载字幕 | Load subtitles
   */
  private async loadSubtitles(): Promise<void> {
    try {
      if (!this.state.media.info) {
        return;
      }

      this.state.subtitle.isSearching = true;

      // 搜索字幕
      const result = await this.subtitleService.searchSubtitles({
        title: this.state.media.info.title,
        year: this.state.media.info.year,
        languages: ['zh', 'en']
      });

      if (result.isSuccess() && result.data) {
        this.state.subtitle.tracks = result.data;
        if (this.state.subtitle.tracks.length > 0 && !this.state.subtitle.selectedTrack) {
          this.state.subtitle.selectedTrack = this.state.subtitle.tracks[0];
        }
        Logger.info(this.TAG, `Loaded ${this.state.subtitle.tracks.length} subtitles`);
      } else {
        Logger.warn(this.TAG, `Failed to load subtitles: ${result.message}`);
      }
    } catch (error) {
      this.errorHandler.handleError(error, ErrorType.MEDIA, ErrorSeverity.LOW, this.TAG);
      Logger.error(this.TAG, `Failed to load subtitles: ${error}`);
    } finally {
      this.state.subtitle.isSearching = false;
    }
  }

  /**
   * 检查是否需要自动跳过 | Check if auto skip is needed
   */
  private async checkAutoSkip(): Promise<void> {
    try {
      if (!this.state.media.info) return;

      // 尝试从缓存加载跳过设置
      try {
        const cacheKey: string = `skip_settings_${this.state.media.info.id}`;
        const cachedSettings = await this.cacheService.get<{
          skipOpeningTime?: number;
          skipEndingTime?: number;
          isSkipOpeningEnabled?: boolean;
          isSkipEndingEnabled?: boolean;
        }>(cacheKey);

        if (cachedSettings) {
          this.state.skip.skipOpeningTime = cachedSettings.skipOpeningTime || 90;
          this.state.skip.skipEndingTime = cachedSettings.skipEndingTime || 300;
          this.state.skip.isSkipOpeningEnabled = cachedSettings.isSkipOpeningEnabled !== false;
          this.state.skip.isSkipEndingEnabled = cachedSettings.isSkipEndingEnabled !== false;
          Logger.info(this.TAG, `Loaded skip settings from cache`);
        }
      } catch (cacheError) {
        this.errorHandler.handleError(cacheError, ErrorType.CACHE, ErrorSeverity.LOW, this.TAG);
        Logger.warn(this.TAG, `Failed to load skip settings from cache: ${cacheError}`);
      }

      // 检查是否需要跳过片头
      if (this.state.skip.isSkipOpeningEnabled && this.state.playback.currentTime < 5) {
        try {
          await this.playbackService.seek(this.state.skip.skipOpeningTime);
          Logger.info(this.TAG, `Auto skipped opening to ${this.state.skip.skipOpeningTime}s`);
        } catch (seekError) {
          this.errorHandler.handleError(seekError, ErrorType.PLAYBACK, ErrorSeverity.LOW, this.TAG);
          Logger.warn(this.TAG, `Failed to skip opening: ${seekError}`);
        }
      }

      // 检查是否需要跳过片尾
      if (this.state.skip.isSkipEndingEnabled && this.state.playback.duration > 0) {
        const remainingTime: number = this.state.playback.duration - this.state.playback.currentTime;
        if (remainingTime <= this.state.skip.skipEndingTime + 2) {
          // 跳转到下一集
          const currentIndex: number = this.state.media.episodes.findIndex((ep: Episode) => ep.current);
          if (currentIndex < this.state.media.episodes.length - 1) {
            try {
              await this.handleEpisodeSelect(this.state.media.episodes[currentIndex + 1]);
              Logger.info(this.TAG, `Auto skipped ending, jumping to next episode`);
            } catch (episodeError) {
              this.errorHandler.handleError(episodeError, ErrorType.PLAYBACK, ErrorSeverity.MEDIUM, this.TAG);
              Logger.warn(this.TAG, `Failed to jump to next episode: ${episodeError}`);
            }
          }
        }
      }
    } catch (error) {
      this.errorHandler.handleError(error, ErrorType.UNKNOWN, ErrorSeverity.LOW, this.TAG);
      Logger.warn(this.TAG, `Failed to check auto skip: ${error}`);
    }
  }

  // 处理控制条显示 | Handle control bar show
  private showControlsWithTimer(): void {
    this.state.ui.showControls = true;
    this.resetControlHideTimer();
  }

  // 重置控制条隐藏计时器 | Reset control bar hide timer
  private resetControlHideTimer(): void {
    // 清除之前的计时器
    if (this.state.ui.controlHideTimer !== null) {
      this.timerManager.clearTimeout(this.state.ui.controlHideTimer);
    }

    // 设置新的计时器，5秒后隐藏控制条
    this.state.ui.controlHideTimer = this.timerManager.setTimeout(() => {
      this.state.ui.showControls = false;
    }, 5000, 'PlaybackPage.controlHide');
  }

  // 处理键盘事件 | Handle keyboard events
  private onKeyEvent(e: KeyEvent): boolean {
    if (e.type === KeyType.Down) {
      // 重置控制条隐藏计时器
      if (this.state.ui.showControls) {
        this.resetControlHideTimer();
      }

      // 直播模式处理
      if (this.state.live.isLiveMode) {
        switch (e.keyCode) {
          case KeyCode.Enter:
          case KeyCode.Space:
            // 显示进度条
            this.showControlsWithTimer();
            return true;
          case KeyCode.Back:
            // 处理返回键
            this.handleBack();
            return true;
          case KeyCode.Up:
            // 切换到上一个频道
            this.switchChannel(-1);
            return true;
          case KeyCode.Down:
            // 切换到下一个频道
            this.switchChannel(1);
            return true;
          case KeyCode.Left:
            // 显示频道列表
            this.state.ui.showChannelList = true;
            return true;
          case KeyCode.Right:
            // 显示直播设置
            this.state.ui.showSettings = true;
            return true;
          default:
            return false;
        }
      }

      // 非直播模式处理
      switch (e.keyCode) {
        case KeyCode.Enter:
        case KeyCode.Space:
          // 处理确认键
          return true;
        case KeyCode.Back:
          // 处理返回键
          this.handleBack();
          return true;
        case KeyCode.Up:
          // 处理上方向键
          if (this.state.ui.showControls) {
            this.focusManager.moveUp();
          }
          return true;
        case KeyCode.Down:
          // 处理下方向键
          if (!this.state.ui.showControls) {
            // 显示控制条
            this.showControlsWithTimer();
          } else {
            // 导航到下一个控制按钮
            this.focusManager.moveDown();
          }
          return true;
        case KeyCode.Left:
          // 处理左方向键
          if (!this.state.ui.showControls) {
            // 快退10秒
            this.handleRewind(10);
          } else {
            // 导航到左侧控制按钮
            this.focusManager.moveLeft();
          }
          return true;
        case KeyCode.Right:
          // 处理右方向键
          if (!this.state.ui.showControls) {
            // 快进30秒
            this.handleFastForward(30);
          } else {
            // 导航到右侧控制按钮
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
      case TouchType.Down:
        // 触摸开始
        this.resetControlHideTimer();
        break;
      case TouchType.Up:
        // 触摸结束
        break;
      case TouchType.Move:
        // 触摸移动
        break;
    }
  }

  // 处理手势事件 | Handle gesture events
  private onGestureEvent(e: GestureEvent): void {
    switch (e.type) {
      case GestureType.Swipe:
        // 处理滑动手势
        switch (e.direction) {
          case SwipeDirection.Left:
            // 向左滑动
            if (!this.state.ui.showControls) {
              this.handleFastForward(30);
            }
            break;
          case SwipeDirection.Right:
            // 向右滑动
            if (!this.state.ui.showControls) {
              this.handleRewind(10);
            }
            break;
          case SwipeDirection.Up:
            // 向上滑动
            break;
          case SwipeDirection.Down:
            // 向下滑动
            if (!this.state.ui.showControls) {
              this.showControlsWithTimer();
            }
            break;
        }
        break;
      case GestureType.Tap:
        // 处理点击手势
        if (!this.state.ui.showControls) {
          this.showControlsWithTimer();
        }
        break;
      case GestureType.LongPress:
        // 处理长按手势
        break;
    }
  }

  // 切换频道 | Switch channel
  private async switchChannel(direction: number): Promise<void> {
    try {
      // 实现频道切换逻辑
      Logger.info(this.TAG, `Switching channel ${direction > 0 ? 'up' : 'down'}`);
    } catch (error) {
      this.errorHandler.handleError(error, ErrorType.PLAYBACK, ErrorSeverity.LOW, this.TAG);
      Logger.error(this.TAG, `Failed to switch channel: ${error}`);
    }
  }

  // 清理资源 | Clean up resources
  aboutToDisappear(): void {
    Logger.info(this.TAG, 'PlaybackPage about to disappear');

    // 清除定时器
    if (this.state.ui.controlHideTimer !== null) {
      this.timerManager.clearTimeout(this.state.ui.controlHideTimer);
      this.state.ui.controlHideTimer = null;
    }

    // 停止播放
    if (this.playbackService) {
      this.playbackService.stop();
    }

    // 清理所有定时器
    this.timerManager.clearAll();

    // 清理ViewModel资源（保存进度和历史记录）
    this.viewModel.cleanup();
  }

  // 渲染视频播放区域 | Render video playback area
  @Builder
  renderVideoPlayer(): void {
    Column() {
      if (this.state.playback.isLoading) {
        Column() {
          // 加载动画
          Column() {
            Text('加载中...')
              .fontSize(24)
              .fontColor('#FFFFFF')
              .margin({ bottom: 20 })
            // 加载指示器
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
        .onTouch((e: TouchEvent) => this.onTouchEvent(e))
        .gesture(
          GestureGroup(GestureMode.Sequence,
            TapGesture({ count: 1 }),
            LongPressGesture({ duration: 500 })
          )
        )
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
          .onFocus(() => {
            Logger.info(this.TAG, 'Retry button focused');
          })

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
          .onFocus(() => {
            Logger.info(this.TAG, 'Back button focused');
          })
        }
        .justifyContent(FlexAlign.Center)
        .width('100%')
        .height(this.state.ui.videoPlayerHeight)
        .backgroundColor('rgba(0, 0, 0, 0.9)')
        .onTouch((e: TouchEvent) => this.onTouchEvent(e))
        .gesture(
          GestureGroup(GestureMode.Sequence,
            TapGesture({ count: 1 }),
            LongPressGesture({ duration: 500 })
          )
        )
      } else {
        Column() {
          // 视频播放区域
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
            .onTouch((e: TouchEvent) => this.onTouchEvent(e))
            .gesture(
              GestureGroup(GestureMode.Sequence,
                TapGesture({ count: 1 }),
                LongPressGesture({ duration: 500 })
              )
            )

            // 播放控制组件
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

          // 跳过设置组件
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
      // 顶部导航栏
      Row() {
        // 返回按钮
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

        // 标题
        Text('播放详情')
          .fontSize(22)
          .fontWeight(700)
          .fontColor('#333333')
          .flexGrow(1)
          .margin({ left: this.state.ui.isLandscape ? 40 : 30 })
          .textAlign(TextAlign.Start)

        // 更多按钮
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

      // 视频播放区域
      this.renderVideoPlayer()

      // 媒体信息组件
      if (this.state.media.info) {
        MediaInfoComponent({
          mediaInfo: this.state.media.info,
          parseLines: this.state.media.parseLines,
          isLandscape: this.state.ui.isLandscape,
          onLineSelect: (line: ParseLine) => this.handleLineSelect(line),
          focusStyle: this.focusStyle
        })
      }

      // 剧集列表组件
      EpisodeListComponent({
        episodes: this.state.media.episodes,
        isLandscape: this.state.ui.isLandscape,
        onEpisodeSelect: (episode: Episode) => this.handleEpisodeSelect(episode),
        onOtherLineSearch: () => this.handleOtherLineSearch()
      })

      // 播放速度选项组件
      PlaybackSpeedComponent({
        showMoreOptions: this.state.ui.showMoreOptions,
        playbackSpeed: this.state.playback.playbackSpeed,
        onSpeedChange: (speed: number) => this.handleSpeedChange(speed)
      })

      // 字幕选项组件
      SubtitleOptionsComponent({
        showSubtitleOptions: this.state.ui.showSubtitleOptions,
        subtitleTracks: this.state.subtitle.tracks,
        selectedSubtitle: this.state.subtitle.selectedTrack,
        isSearchingSubtitles: this.state.subtitle.isSearching,
        onSubtitleSelect: (track: SubtitleTrack) => this.handleSubtitleSelect(track),
        onSubtitleStyleChange: () => this.handleSubtitleStyleChange()
      })

      // 音轨选项组件
      AudioTrackOptionsComponent({
        showAudioTrackOptions: this.state.ui.showAudioTrackOptions,
        audioTracks: this.state.audio.tracks,
        selectedAudioTrack: this.state.audio.selectedTrack,
        onAudioTrackSelect: (track: AudioTrack) => {
          this.state.audio.selectedTrack = track;
          this.playbackService.setAudioTrack(track.id);
        }
      })

      // 断点续播对话框
      if (this.state.ui.showResumeDialog) {
        this.renderResumeDialog()
      }
    }
  }

  // 渲染断点续播对话框
  @Builder
  renderResumeDialog(): void {
    Column() {
      // 遮罩层
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.5)')
        .position({ x: 0, y: 0 })
        .onClick(() => {
          // 点击遮罩层关闭对话框
          this.state.ui.showResumeDialog = false;
        })

      // 对话框内容
      Column() {
        Text('继续观看')
          .fontSize(24)
          .fontWeight(700)
          .fontColor('#333333')
          .margin({ bottom: 20 })

        Text(this.state.playback.resumeMessage)
          .fontSize(16)
          .fontColor('#666666')
          .textAlign(TextAlign.Center)
          .margin({ bottom: 30, left: 20, right: 20 })

        Row() {
          Button() {
            Text('从头开始')
              .fontSize(16)
              .fontColor('#666666')
              .fontWeight(500)
          }
          .width(120)
          .height(44)
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .margin({ right: 20 })
          .onClick(() => {
            this.viewModel.startFromBeginning();
          })

          Button() {
            Text('继续观看')
              .fontSize(16)
              .fontColor('#FFFFFF')
              .fontWeight(500)
          }
          .width(120)
          .height(44)
          .backgroundColor('#4CAF50')
          .borderRadius(8)
          .onClick(() => {
            this.viewModel.resumeFromBreakpoint();
          })
        }
      }
      .width(320)
      .padding(24)
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
      .shadow({ radius: 10, color: 'rgba(0, 0, 0, 0.2)', offsetY: 4 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .position({ x: 0, y: 0 })
  }
}
