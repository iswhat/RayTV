import Logger from '../common/util/Logger';
import { MediaService } from '../service/media/MediaService';
import { PlaybackService } from '../service/playback/PlaybackService';
import { CacheService } from '../service/cache/CacheService';
import { PlaybackHistoryService } from '../service/playback/PlaybackHistoryService';
import { ErrorHandler, ErrorType, ErrorSeverity } from '../common/util/ErrorHandler';
import { MediaInfo, Episode, ParseLine, AudioTrack, SubtitleTrack, PlaybackHistory, PlaybackProgress } from '../pages/playback/types/PlaybackTypes';

// 媒体状态接口
interface MediaState {
  info: MediaInfo | null;
  episodes: Episode[];
  parseLines: ParseLine[];
  selectedEpisode: Episode | null;
  selectedLine: ParseLine | null;
}

// 播放控制状态接口
interface ControlState {
  isPlaying: boolean;
  currentTime: number;
  duration: number;
  progress: number;
  playbackSpeed: number;
  isLoading: boolean;
  isError: boolean;
  errorMessage: string;
  hasResumePoint: boolean;
  resumeMessage: string;
}

// UI状态接口
interface UiState {
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
  showResumeDialog: boolean;
}

// 字幕状态接口
interface SubtitleState {
  tracks: SubtitleTrack[];
  selectedTrack: SubtitleTrack | null;
  languages: string[];
  isSearching: boolean;
}

// 音轨状态接口
interface AudioState {
  tracks: AudioTrack[];
  selectedTrack: AudioTrack | null;
}

// 跳过设置状态接口
interface SkipState {
  skipOpeningTime: number;
  skipEndingTime: number;
  isSkipOpeningEnabled: boolean;
  isSkipEndingEnabled: boolean;
}

// 直播状态接口
interface LiveState {
  isLiveMode: boolean;
  showChannelList: boolean;
  showSettings: boolean;
}

// 初始化参数接口
interface InitParams {
  id: string;
  siteKey: string;
  type: string;
}

// 播放状态回调接口
interface PlaybackStateCallback {
  isPlaying: boolean;
  currentTime: number;
  duration: number;
  progress: number;
  audioTracks?: AudioTrack[];
}

export class PlaybackViewModel {
  private static instance: PlaybackViewModel;
  private readonly TAG: string = 'PlaybackViewModel';

  // 状态
  private _mediaState: MediaState = {
    info: null,
    episodes: [],
    parseLines: [],
    selectedEpisode: null,
    selectedLine: null
  };

  private _controlState: ControlState = {
    isPlaying: true,
    currentTime: 0,
    duration: 0,
    progress: 0,
    playbackSpeed: 1.0,
    isLoading: true,
    isError: false,
    errorMessage: '加载失败',
    hasResumePoint: false,
    resumeMessage: ''
  };

  private _uiState: UiState = {
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
  };

  private _subtitleState: SubtitleState = {
    tracks: [],
    selectedTrack: null,
    languages: [],
    isSearching: false
  };

  private _audioState: AudioState = {
    tracks: [],
    selectedTrack: null
  };

  private _skipState: SkipState = {
    skipOpeningTime: 90,
    skipEndingTime: 300,
    isSkipOpeningEnabled: true,
    isSkipEndingEnabled: true
  };

  private _liveState: LiveState = {
    isLiveMode: false,
    showChannelList: false,
    showSettings: false
  };

  // 服务实例
  private mediaService: MediaService = MediaService.getInstance();
  private playbackService: PlaybackService = PlaybackService.getInstance();
  private cacheService: CacheService = CacheService.getInstance();
  private historyService: PlaybackHistoryService = PlaybackHistoryService.getInstance();
  private errorHandler: ErrorHandler = ErrorHandler.getInstance();

  // 当前播放的媒体信息
  private currentMediaId: string = '';
  private currentEpisodeId: string = '';
  private currentSiteKey: string = '';

  // 状态订阅者
  private mediaStateSubscribers: ((state: MediaState) => void)[] = [];
  private controlStateSubscribers: ((state: ControlState) => void)[] = [];
  private uiStateSubscribers: ((state: UiState) => void)[] = [];
  private subtitleStateSubscribers: ((state: SubtitleState) => void)[] = [];
  private audioStateSubscribers: ((state: AudioState) => void)[] = [];
  private skipStateSubscribers: ((state: SkipState) => void)[] = [];
  private liveStateSubscribers: ((state: LiveState) => void)[] = [];

  // 进度保存定时器
  private progressSaveTimer: number | null = null;
  private readonly PROGRESS_SAVE_INTERVAL: number = 5000; // 5秒

  private constructor() {}

  public static getInstance(): PlaybackViewModel {
    if (!PlaybackViewModel.instance) {
      PlaybackViewModel.instance = new PlaybackViewModel();
    }
    return PlaybackViewModel.instance;
  }

  // 状态访问器
  get mediaState() {
    return {
      subscribe: (callback: (state: MediaState) => void) => {
        this.mediaStateSubscribers.push(callback);
        callback(this._mediaState);
      }
    };
  }

  get controlState() {
    return {
      subscribe: (callback: (state: ControlState) => void) => {
        this.controlStateSubscribers.push(callback);
        callback(this._controlState);
      }
    };
  }

  get uiState() {
    return {
      subscribe: (callback: (state: UiState) => void) => {
        this.uiStateSubscribers.push(callback);
        callback(this._uiState);
      }
    };
  }

  get subtitleState() {
    return {
      subscribe: (callback: (state: SubtitleState) => void) => {
        this.subtitleStateSubscribers.push(callback);
        callback(this._subtitleState);
      }
    };
  }

  get audioState() {
    return {
      subscribe: (callback: (state: AudioState) => void) => {
        this.audioStateSubscribers.push(callback);
        callback(this._audioState);
      }
    };
  }

  get skipState() {
    return {
      subscribe: (callback: (state: SkipState) => void) => {
        this.skipStateSubscribers.push(callback);
        callback(this._skipState);
      }
    };
  }

  get liveState() {
    return {
      subscribe: (callback: (state: LiveState) => void) => {
        this.liveStateSubscribers.push(callback);
        callback(this._liveState);
      }
    };
  }

  // 更新屏幕信息
  public updateScreenInfo(width: number, height: number): void {
    this._uiState.screenWidth = width;
    this._uiState.screenHeight = height;
    this._uiState.isLandscape = width > height;
    this._uiState.videoPlayerHeight = this._uiState.isLandscape ? height * 0.8 : width * 9 / 16;
    this.notifyUiState();
  }

  // 初始化
  public async initialize(params: InitParams): Promise<void> {
    try {
      this._controlState.isLoading = true;
      this._controlState.isError = false;
      this.notifyControlState();

      // 保存当前媒体信息
      this.currentMediaId = params.id;
      this.currentSiteKey = params.siteKey;

      // 加载媒体信息
      await this.loadMediaInfo(params);

      // 加载剧集列表
      this.loadEpisodes();

      // 加载解析线路
      this.loadParseLines();

      // 检查是否有断点续播
      if (this._mediaState.selectedEpisode) {
        this.currentEpisodeId = this._mediaState.selectedEpisode.id;
        await this.checkResumePoint();
      }

      // 初始化播放
      await this.initPlayback();

      // 加载字幕
      await this.loadSubtitles();

      // 启动进度保存定时器
      this.startProgressSaveTimer();

      this._controlState.isLoading = false;
      this.notifyControlState();

      Logger.info(this.TAG, 'PlaybackViewModel initialized successfully');
    } catch (error) {
      this.errorHandler.handleError(error, ErrorType.PLAYBACK, ErrorSeverity.HIGH, this.TAG);
      this._controlState.isError = true;
      this._controlState.errorMessage = this.errorHandler.getFriendlyMessage(error);
      this._controlState.isLoading = false;
      this.notifyControlState();
    }
  }

  // 检查断点续播
  private async checkResumePoint(): Promise<void> {
    try {
      const hasResumePoint: boolean = await this.historyService.hasResumePoint(
        this.currentMediaId,
        this.currentEpisodeId
      );

      if (hasResumePoint) {
        const resumeMessage: string = await this.historyService.getResumeMessage(
          this.currentMediaId,
          this.currentEpisodeId
        );

        this._controlState.hasResumePoint = true;
        this._controlState.resumeMessage = resumeMessage;
        this._uiState.showResumeDialog = true;

        this.notifyControlState();
        this.notifyUiState();

        Logger.info(this.TAG, `Found resume point: ${resumeMessage}`);
      }
    } catch (error) {
      this.errorHandler.handleError(error, ErrorType.STORAGE, ErrorSeverity.LOW, this.TAG);
      Logger.warn(this.TAG, `Failed to check resume point: ${error}`);
    }
  }

  // 继续从断点播放
  public async resumeFromBreakpoint(): Promise<void> {
    try {
      const progress: number = await this.historyService.getProgress(
        this.currentMediaId,
        this.currentEpisodeId
      );

      if (progress > 0) {
        await this.playbackService.seek(progress);
        this._controlState.currentTime = progress;
        this.notifyControlState();

        Logger.info(this.TAG, `Resumed from breakpoint: ${progress}s`);
      }

      // 隐藏断点续播对话框
      this._uiState.showResumeDialog = false;
      this.notifyUiState();
    } catch (error) {
      this.errorHandler.handleError(error, ErrorType.PLAYBACK, ErrorSeverity.LOW, this.TAG);
      Logger.error(this.TAG, `Failed to resume from breakpoint: ${error}`);
    }
  }

  // 从头开始播放
  public async startFromBeginning(): Promise<void> {
    try {
      // 隐藏断点续播对话框
      this._uiState.showResumeDialog = false;
      this.notifyUiState();

      // 重置进度
      await this.playbackService.seek(0);
      this._controlState.currentTime = 0;
      this.notifyControlState();

      Logger.info(this.TAG, 'Started from beginning');
    } catch (error) {
      this.errorHandler.handleError(error, ErrorType.PLAYBACK, ErrorSeverity.LOW, this.TAG);
      Logger.error(this.TAG, `Failed to start from beginning: ${error}`);
    }
  }

  // 启动进度保存定时器
  private startProgressSaveTimer(): void {
    this.stopProgressSaveTimer();

    this.progressSaveTimer = setInterval(() => {
      this.saveCurrentProgress();
    }, this.PROGRESS_SAVE_INTERVAL);
  }

  // 停止进度保存定时器
  private stopProgressSaveTimer(): void {
    if (this.progressSaveTimer) {
      clearInterval(this.progressSaveTimer);
      this.progressSaveTimer = null;
    }
  }

  // 保存当前进度
  private async saveCurrentProgress(): Promise<void> {
    try {
      if (this.currentMediaId && this.currentEpisodeId && this._controlState.duration > 0) {
        const progress: PlaybackProgress = {
          mediaId: this.currentMediaId,
          episodeId: this.currentEpisodeId,
          currentTime: this._controlState.currentTime,
          duration: this._controlState.duration,
          updatedAt: Date.now()
        };

        await this.historyService.saveProgress(progress);
      }
    } catch (error) {
      this.errorHandler.handleError(error, ErrorType.STORAGE, ErrorSeverity.LOW, this.TAG);
      Logger.warn(this.TAG, `Failed to save progress: ${error}`);
    }
  }

  // 添加播放历史记录
  private async addPlaybackHistory(): Promise<void> {
    try {
      if (this.currentMediaId && this.currentEpisodeId && this._mediaState.info) {
        const history: PlaybackHistory = {
          mediaId: this.currentMediaId,
          episodeId: this.currentEpisodeId,
          siteKey: this.currentSiteKey,
          title: this._mediaState.info.title,
          episodeTitle: this._mediaState.selectedEpisode?.title || '',
          currentTime: this._controlState.currentTime,
          duration: this._controlState.duration,
          lastPlayedAt: Date.now(),
          cover: this._mediaState.info.cover
        };

        await this.historyService.addHistory(history);
        Logger.info(this.TAG, `Added playback history: ${history.title}`);
      }
    } catch (error) {
      this.errorHandler.handleError(error, ErrorType.STORAGE, ErrorSeverity.LOW, this.TAG);
      Logger.warn(this.TAG, `Failed to add playback history: ${error}`);
    }
  }

  // 加载媒体信息
  private async loadMediaInfo(params: InitParams): Promise<void> {
    try {
      // 生成缓存键
      const cacheKey: string = `media_info_${params.id}_${params.siteKey}_${params.type}`;

      // 尝试从缓存获取
      try {
        const cachedInfo: MediaInfo | null = await this.cacheService.get<MediaInfo>(cacheKey);
        if (cachedInfo) {
          this._mediaState.info = cachedInfo;
          Logger.info(this.TAG, `Loaded media info from cache: ${cachedInfo.title}`);
          this.notifyMediaState();
          return;
        }
      } catch (cacheError) {
        this.errorHandler.handleError(cacheError, ErrorType.CACHE, ErrorSeverity.LOW, this.TAG);
        Logger.warn(this.TAG, `Cache error, falling back to service: ${cacheError}`);
      }

      // 从服务获取
      const result = await this.mediaService.getMediaDetail(params.id, params.siteKey, params.type);
      if (result.isSuccess() && result.data) {
        this._mediaState.info = result.data;

        // 缓存结果
        try {
          await this.cacheService.set(cacheKey, result.data, {
            expiry: 86400000, // 24小时
            priority: 'high',
            tags: ['media', 'detail'],
            source: 'MediaService'
          });
        } catch (cacheError) {
          this.errorHandler.handleError(cacheError, ErrorType.CACHE, ErrorSeverity.LOW, this.TAG);
          Logger.warn(this.TAG, `Failed to cache media info: ${cacheError}`);
        }

        Logger.info(this.TAG, `Loaded media info from service: ${result.data.title}`);
        this.notifyMediaState();
      } else {
        const error: Error = new Error(result.message || '加载媒体信息失败');
        this.errorHandler.handleError(error, ErrorType.MEDIA, ErrorSeverity.MEDIUM, this.TAG);
        throw error;
      }
    } catch (error) {
      this.errorHandler.handleError(error, ErrorType.NETWORK, ErrorSeverity.HIGH, this.TAG);
      throw error;
    }
  }

  // 加载剧集列表
  private loadEpisodes(): void {
    if (this._mediaState.info && this._mediaState.info.episodes) {
      this._mediaState.episodes = this._mediaState.info.episodes.map((ep, index: number) => ({
        id: ep.id || `ep_${index}`,
        title: ep.title || `第${ep.episode || (index + 1)}集`,
        episode: ep.episode || (index + 1),
        duration: ep.duration,
        played: ep.played || false,
        current: index === 0
      }));
      this._mediaState.selectedEpisode = this._mediaState.episodes[0];
      Logger.info(this.TAG, `Loaded ${this._mediaState.episodes.length} episodes`);
      this.notifyMediaState();
    } else {
      this._mediaState.episodes = [];
      this._mediaState.selectedEpisode = null;
      this.notifyMediaState();
    }
  }

  // 加载解析线路
  private loadParseLines(): void {
    if (this._mediaState.info && this._mediaState.info.parseLines) {
      this._mediaState.parseLines = this._mediaState.info.parseLines.map((line, index: number) => ({
        id: line.id || `line_${index}`,
        name: line.name || `线路${index + 1}`,
        selected: index === 0
      }));
      this._mediaState.selectedLine = this._mediaState.parseLines[0];
      Logger.info(this.TAG, `Loaded ${this._mediaState.parseLines.length} parse lines`);
      this.notifyMediaState();
    } else {
      this._mediaState.parseLines = [{
        id: 'line_1',
        name: '默认线路',
        selected: true
      }];
      this._mediaState.selectedLine = this._mediaState.parseLines[0];
      this.notifyMediaState();
    }
  }

  // 初始化播放
  private async initPlayback(): Promise<void> {
    try {
      if (this._mediaState.selectedEpisode && this._mediaState.selectedLine) {
        await this.playbackService.initPlayback({
          episode: this._mediaState.selectedEpisode,
          line: this._mediaState.selectedLine,
          mediaInfo: this._mediaState.info
        });

        // 监听播放状态
        this.playbackService.onPlaybackStateChange((state: PlaybackStateCallback) => {
          this._controlState.isPlaying = state.isPlaying;
          this._controlState.currentTime = state.currentTime;
          this._controlState.duration = state.duration;
          this._controlState.progress = state.progress;

          // 加载音轨信息
          if (state.audioTracks && state.audioTracks.length > 0) {
            this._audioState.tracks = state.audioTracks;
            if (!this._audioState.selectedTrack && this._audioState.tracks.length > 0) {
              this._audioState.selectedTrack = this._audioState.tracks[0];
            }
            this.notifyAudioState();
          }

          this.notifyControlState();
        });

        Logger.info(this.TAG, 'Playback initialized successfully');
      }
    } catch (error) {
      this.errorHandler.handleError(error, ErrorType.PLAYBACK, ErrorSeverity.HIGH, this.TAG);
      throw error;
    }
  }

  // 加载字幕
  private async loadSubtitles(): Promise<void> {
    try {
      // 这里可以实现字幕加载逻辑
      this._subtitleState.tracks = [];
      this._subtitleState.selectedTrack = null;
      this._subtitleState.languages = ['中文', '英文', '日语'];
      this.notifySubtitleState();
    } catch (error) {
      this.errorHandler.handleError(error, ErrorType.MEDIA, ErrorSeverity.LOW, this.TAG);
      Logger.warn(this.TAG, `Failed to load subtitles: ${error}`);
    }
  }

  // 切换剧集
  public async switchEpisode(episode: Episode): Promise<{ isSuccess: () => boolean; message?: string }> {
    try {
      if (!episode || !episode.id || !episode.title) {
        throw new Error('无效的剧集数据');
      }

      // 保存当前剧集的进度
      await this.saveCurrentProgress();
      await this.addPlaybackHistory();

      // 更新当前剧集ID
      this.currentEpisodeId = episode.id;

      // 更新选中的剧集
      this._mediaState.selectedEpisode = episode;
      this._mediaState.episodes.forEach((ep: Episode) => {
        ep.current = ep.id === episode.id;
      });
      this.notifyMediaState();

      // 检查新剧集是否有断点续播
      await this.checkResumePoint();

      // 调用播放服务切换剧集
      const result = await this.playbackService.switchEpisode(episode);
      return result;
    } catch (error) {
      this.errorHandler.handleError(error, ErrorType.PLAYBACK, ErrorSeverity.MEDIUM, this.TAG);
      return {
        isSuccess: () => false,
        message: this.errorHandler.getFriendlyMessage(error)
      };
    }
  }

  // 切换解析线路
  public async switchLine(line: ParseLine): Promise<{ isSuccess: () => boolean; message?: string }> {
    try {
      if (!line || !line.id || !line.name) {
        throw new Error('无效的解析线路数据');
      }

      // 更新选中的线路
      this._mediaState.selectedLine = line;
      this._mediaState.parseLines.forEach((l: ParseLine) => {
        l.selected = l.id === line.id;
      });
      this.notifyMediaState();

      // 这里可以实现切换线路的逻辑
      return {
        isSuccess: () => true
      };
    } catch (error) {
      this.errorHandler.handleError(error, ErrorType.PLAYBACK, ErrorSeverity.MEDIUM, this.TAG);
      return {
        isSuccess: () => false,
        message: this.errorHandler.getFriendlyMessage(error)
      };
    }
  }

  // 清理资源
  public async cleanup(): Promise<void> {
    try {
      // 停止进度保存定时器
      this.stopProgressSaveTimer();

      // 保存当前进度
      await this.saveCurrentProgress();

      // 添加播放历史记录
      await this.addPlaybackHistory();

      Logger.info(this.TAG, 'PlaybackViewModel cleaned up');
    } catch (error) {
      this.errorHandler.handleError(error, ErrorType.UNKNOWN, ErrorSeverity.LOW, this.TAG);
      Logger.warn(this.TAG, `Failed to cleanup: ${error}`);
    }
  }

  // 通知状态更新
  private notifyMediaState(): void {
    this.mediaStateSubscribers.forEach((callback: (state: MediaState) => void) => callback(this._mediaState));
  }

  private notifyControlState(): void {
    this.controlStateSubscribers.forEach((callback: (state: ControlState) => void) => callback(this._controlState));
  }

  private notifyUiState(): void {
    this.uiStateSubscribers.forEach((callback: (state: UiState) => void) => callback(this._uiState));
  }

  private notifySubtitleState(): void {
    this.subtitleStateSubscribers.forEach((callback: (state: SubtitleState) => void) => callback(this._subtitleState));
  }

  private notifyAudioState(): void {
    this.audioStateSubscribers.forEach((callback: (state: AudioState) => void) => callback(this._audioState));
  }

  private notifySkipState(): void {
    this.skipStateSubscribers.forEach((callback: (state: SkipState) => void) => callback(this._skipState));
  }

  private notifyLiveState(): void {
    this.liveStateSubscribers.forEach((callback: (state: LiveState) => void) => callback(this._liveState));
  }
}

// 导出单例实例
export function getPlaybackViewModel(): PlaybackViewModel {
  return PlaybackViewModel.getInstance();
}
