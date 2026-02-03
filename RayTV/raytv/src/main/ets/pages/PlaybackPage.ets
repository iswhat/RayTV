import { AppNavigator, DetailParams } from '../navigation/AppNavigator';
import Logger from '../common/util/Logger';
import { MediaService } from '../service/media/MediaService';
import { PlaybackService } from '../service/playback/PlaybackService';
import { AVPlayerService } from '../service/playback/AVPlayerService';
import { SearchService } from '../service/search/SearchService';
import SubtitleService, { SubtitleTrack, SubtitleProvider, SubtitleLanguage } from '../service/media/SubtitleService';
import TimerManager from '../common/util/TimerManager';

import CacheService, { CachePriority } from '../service/cache/CacheService';
import display from '@ohos.display';
import { ScrollDirection, BarState, FlexAlign, FlexDirection, ImageFit, TextAlign, VerticalAlign, HorizontalAlign, FlexWrap, KeyEvent, FocusStyle, TouchEvent, GestureEvent, Curve } from '@ohos/arkui';

// 导入子组件 | Import sub-components
import { PlaybackControls } from './playback/PlaybackControls';
import { SkipSettings } from './playback/SkipSettings';
import { EpisodeList } from './playback/EpisodeList';

// 解析线路 | Parse line
interface ParseLine {
  id: string;
  name: string;
  selected: boolean;
}

// 媒体信息接口 | Media info interface
export interface MediaInfo {
  id: string;
  title: string;
  cover?: string;
  description?: string;
  episodes: Array<{
    id: string;
    title: string;
    episode: number;
    duration?: string;
    played?: boolean;
  }>;
  parseLines: Array<{
    id: string;
    name: string;
  }>;
  type: string;
  siteKey: string;
  rating?: string;
  year?: string;
  region?: string;
  director?: string;
  actor?: string;
}

// 音频轨道接口 | Audio track interface
export interface AudioTrack {
  id: string;
  name: string;
  language?: string;
  selected?: boolean;
}

// 字幕样式接口 | Subtitle style interface
export interface SubtitleStyle {
  fontSize: number;
  fontFamily: string;
  fontWeight: string;
  color: string;
  backgroundColor: string;
  opacity: number;
  borderWidth: number;
  borderColor: string;
}

// 播放设置接口 | Playback settings interface
export interface PlaybackSettings {
  playbackSpeed: number;
  subtitleStyle: SubtitleStyle;
  selectedSubtitleId?: string;
  selectedAudioTrackId?: string;
  skipOpening: boolean;
  skipEnding: boolean;
}

@Entry
@Component
struct PlaybackPage {
  private readonly TAG: string = 'PlaybackPage';
  private scroller: Scroller = new Scroller();
  private episodeScroller: Scroller = new Scroller();
  
  // 状态管理 | State management
  
  // 媒体信息状态 | Media info state
  @State mediaState: {
    info: MediaInfo | null;
    episodes: Episode[];
    parseLines: ParseLine[];
    selectedEpisode: Episode | null;
    selectedLine: ParseLine | null;
  } = {
    info: null,
    episodes: [],
    parseLines: [],
    selectedEpisode: null,
    selectedLine: null
  };
  
  // 播放状态 | Playback state
  @State playbackState: {
    isPlaying: boolean;
    currentTime: number;
    duration: number;
    progress: number;
    playbackSpeed: number;
    isLoading: boolean;
    isError: boolean;
    errorMessage: string;
  } = {
    isPlaying: true,
    currentTime: 0,
    duration: 0,
    progress: 0,
    playbackSpeed: 1.0,
    isLoading: true,
    isError: false,
    errorMessage: '加载失败'
  };
  
  // UI状态 | UI state
  @State uiState: {
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
  } = {
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
  };
  
  // 字幕状态 | Subtitle state
  @State subtitleState: {
    tracks: SubtitleTrack[];
    selectedTrack: SubtitleTrack | null;
    languages: SubtitleLanguage[];
    isSearching: boolean;
  } = {
    tracks: [],
    selectedTrack: null,
    languages: [],
    isSearching: false
  };
  
  // 音轨状态 | Audio track state
  @State audioState: {
    tracks: AudioTrack[];
    selectedTrack: AudioTrack | null;
  } = {
    tracks: [],
    selectedTrack: null
  };
  
  // 跳过设置状态 | Skip settings state
  @State skipState: {
    skipOpeningTime: number;
    skipEndingTime: number;
    isSkipOpeningEnabled: boolean;
    isSkipEndingEnabled: boolean;
  } = {
    skipOpeningTime: 90, // 默认跳过片头时间（秒）
    skipEndingTime: 300, // 默认跳过片尾时间（秒）
    isSkipOpeningEnabled: true,
    isSkipEndingEnabled: true
  };
  
  // 直播状态 | Live state
  @State liveState: {
    isLiveMode: boolean;
    showChannelList: boolean;
    showSettings: boolean;
  } = {
    isLiveMode: false, // 是否为直播模式
    showChannelList: false, // 是否显示直播频道列表
    showSettings: false, // 是否显示直播设置
  };
  // 服务实例 | Service instances
  private mediaService: MediaService = MediaService.getInstance();
  private playbackService: PlaybackService = PlaybackService.getInstance();
  private avPlayerService: AVPlayerService = AVPlayerService.getInstance();
  private timerManager: TimerManager = TimerManager.getInstance();
  private searchService: SearchService = SearchService.getInstance();
  private subtitleService: SubtitleService = SubtitleService.getInstance();

  private cacheService: CacheService = CacheService.getInstance();
  
  // 生命周期 | Lifecycle
  aboutToAppear() {
    Logger.info(this.TAG, 'PlaybackPage about to appear');
    

    
    // 初始化屏幕信息 | Initialize screen information
    this.initScreenInfo();
    
    // 加载媒体信息 | Load media info
    this.loadMediaInfo();
  }
  
  // 初始化屏幕信息 | Initialize screen information
  private initScreenInfo() {
    try {
      const displayInfo = display.getDefaultDisplaySync();
      this.uiState.screenWidth = displayInfo.width;
      this.uiState.screenHeight = displayInfo.height;
      this.uiState.isLandscape = this.uiState.screenWidth > this.uiState.screenHeight;
      
      // 计算视频播放器高度 | Calculate video player height
      if (this.uiState.isLandscape) {
        // 横屏模式：占据屏幕高度的60% | Landscape mode: 60% of screen height
        this.uiState.videoPlayerHeight = this.uiState.screenHeight * 0.6;
      } else {
        // 竖屏模式：固定高度 | Portrait mode: fixed height
        this.uiState.videoPlayerHeight = 400;
      }
      
      Logger.info(this.TAG, `Screen info: width=${this.uiState.screenWidth}, height=${this.uiState.screenHeight}, landscape=${this.uiState.isLandscape}, playerHeight=${this.uiState.videoPlayerHeight}`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to get screen info: ${error}`);
      // 默认值 | Default values
      this.uiState.screenWidth = 1920;
      this.uiState.screenHeight = 1080;
      this.uiState.isLandscape = true;
      this.uiState.videoPlayerHeight = 648; // 1080 * 0.6
    }
  }
  
  /**
   * 加载媒体信息 | Load media info
   */
  private async loadMediaInfo(): Promise<void> {
    try {
      this.playbackState.isLoading = true;
      this.playbackState.isError = false;

      // 修复问题2：获取路由参数并验证 - 检查params是否存在
      // Get route parameters and validate - check if params exists
      const params: DetailParams = AppNavigator.getInstance().getCurrentRouteParams();

      if (!params || !params.id || !params.siteKey) {
        this.playbackState.isError = true;
        this.playbackState.errorMessage = '缺少必要的参数';
        Logger.error(this.TAG, 'Missing required route parameters');
        this.playbackState.isLoading = false;
        return;
      }

      Logger.info(this.TAG, `Loading media info for: ${params.id} from ${params.siteKey}`);

      // 生成缓存键 | Generate cache key
      const cacheKey = `media_info_${params.id}_${params.siteKey}_${params.type}`;
      
      // 尝试从缓存获取 | Try to get from cache
      const cachedInfo = await this.cacheService.get<MediaInfo>(cacheKey);
      
      if (cachedInfo) {
        this.mediaState.info = cachedInfo;
        
        // 加载剧集列表 | Load episode list
        this.loadEpisodes();
        // 加载解析线路 | Load parse lines
        this.loadParseLines();
        
        // 初始化播放 | Initialize playback
        await this.initPlayback();
        
        // 加载字幕 | Load subtitles
        await this.loadSubtitles();
        
        Logger.info(this.TAG, `Loaded media info from cache: ${this.mediaState.info.title}`);
        this.playbackState.isLoading = false;
        return;
      }
      
      // 调用实际的MediaService获取媒体信息 | Call actual MediaService to get media info
      const result = await this.mediaService.getMediaDetail(params.id, params.siteKey, params.type);
      
      if (result.isSuccess() && result.data) {
        this.mediaState.info = result.data;
        
        // 缓存结果 | Cache result
        await this.cacheService.set(cacheKey, this.mediaState.info, {
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
        
        Logger.info(this.TAG, `Loaded media info from service: ${this.mediaState.info.title}`);
      } else {
        this.playbackState.isError = true;
        this.playbackState.errorMessage = result.message || '加载失败';
        Logger.warn(this.TAG, `Failed to load media info: ${this.playbackState.errorMessage}`);
      }
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      Logger.error(this.TAG, `Failed to load media info: ${errorMsg}`);
      this.playbackState.isError = true;
      this.playbackState.errorMessage = errorMsg;
    } finally {
      this.playbackState.isLoading = false;
    }
  }
  
  /**
   * 加载剧集列表 | Load episode list
   */
  private loadEpisodes(): void {
    if (this.mediaState.info && this.mediaState.info.episodes) {
      this.mediaState.episodes = this.mediaState.info.episodes.map((ep, index: number) => ({
        id: ep.id || `ep_${index}`,
        title: ep.title || `第${ep.episode || (index + 1)}集`,
        episode: ep.episode || (index + 1),
        duration: ep.duration,
        played: ep.played || false,
        current: index === 0
      }));
      this.mediaState.selectedEpisode = this.mediaState.episodes[0];
      Logger.info(this.TAG, `Loaded ${this.mediaState.episodes.length} episodes`);
    } else {
      this.mediaState.episodes = [];
    }
  }
  
  /**
   * 加载解析线路 | Load parse lines
   */
  private loadParseLines(): void {
    if (this.mediaState.info && this.mediaState.info.parseLines) {
      this.mediaState.parseLines = this.mediaState.info.parseLines.map((line, index: number) => ({
        id: line.id || `line_${index}`,
        name: line.name || `线路${index + 1}`,
        selected: index === 0
      }));
      this.mediaState.selectedLine = this.mediaState.parseLines[0];
      Logger.info(this.TAG, `Loaded ${this.mediaState.parseLines.length} parse lines`);
    } else {
      this.mediaState.parseLines = [{
        id: 'line_1',
        name: '默认线路',
        selected: true
      }];
      this.mediaState.selectedLine = this.mediaState.parseLines[0];
    }
  }
  
  /**
   * 初始化播放 | Initialize playback
   */
  private async initPlayback(): Promise<void> {
    try {
      if (this.mediaState.selectedEpisode && this.mediaState.selectedLine) {
        // 调用实际的PlaybackService初始化播放 | Call actual PlaybackService to initialize playback
        await this.playbackService.initPlayback({
          episode: this.mediaState.selectedEpisode,
          line: this.mediaState.selectedLine,
          mediaInfo: this.mediaState.info
        });
        
        // 监听播放状态 | Listen to playback state
        this.playbackService.onPlaybackStateChange((state) => {
          this.playbackState.isPlaying = state.isPlaying;
          this.playbackState.currentTime = state.currentTime;
          this.playbackState.duration = state.duration;
          this.playbackState.progress = state.progress;
          
          // 检查是否需要自动跳过 | Check if auto skip is needed
          this.checkAutoSkip();
          
          // 加载音轨信息 | Load audio track info
          if (state.audioTracks && state.audioTracks.length > 0) {
            this.audioState.tracks = state.audioTracks;
            if (!this.audioState.selectedTrack && this.audioState.tracks.length > 0) {
              this.audioState.selectedTrack = this.audioState.tracks[0];
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
      this.mediaState.selectedEpisode = episode;
      // 更新剧集状态 | Update episode state
      this.mediaState.episodes.forEach(ep => {
        ep.current = ep.id === episode.id;
      });
      
      // 显示加载状态 | Show loading state
      this.playbackState.isLoading = true;
      
      // 调用实际的PlaybackService切换剧集 | Call actual PlaybackService to switch episode
      const result = await this.playbackService.switchEpisode(episode);
      
      if (result.isSuccess()) {
        Logger.info(this.TAG, `Selected episode: ${episode.title}`);
      } else {
        Logger.error(this.TAG, `Failed to switch episode: ${result.message}`);
        this.playbackState.isError = true;
        this.playbackState.errorMessage = result.message || '切换剧集失败';
      }
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      Logger.error(this.TAG, `Failed to switch episode: ${errorMsg}`);
      this.playbackState.isError = true;
      this.playbackState.errorMessage = errorMsg;
    } finally {
      this.playbackState.isLoading = false;
    }
  }
  
  /**
   * 处理解析线路选择 | Handle parse line selection
   */
  private async handleLineSelect(line: ParseLine): Promise<void> {
    try {
      this.mediaState.selectedLine = line;
      // 更新线路状态 | Update line state
      this.mediaState.parseLines.forEach(l => {
        l.selected = l.id === line.id;
      });
      
      // 显示加载状态 | Show loading state
      this.playbackState.isLoading = true;
      
      // 调用实际的PlaybackService切换解析线路 | Call actual PlaybackService to switch parse line
      const result = await this.playbackService.switchParseLine(line);
      
      if (result.isSuccess()) {
        Logger.info(this.TAG, `Selected parse line: ${line.name}`);
      } else {
        Logger.error(this.TAG, `Failed to switch parse line: ${result.message}`);
        this.playbackState.isError = true;
        this.playbackState.errorMessage = result.message || '切换解析线路失败';
      }
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      Logger.error(this.TAG, `Failed to switch parse line: ${errorMsg}`);
      this.playbackState.isError = true;
      this.playbackState.errorMessage = errorMsg;
    } finally {
      this.playbackState.isLoading = false;
    }
  }
  
  /**
   * 处理播放/暂停 | Handle play/pause
   */
  private async handlePlayPause(): Promise<void> {
    try {
      let result: { isSuccess: () => boolean };
      if (this.playbackState.isPlaying) {
        result = await this.playbackService.pause();
      } else {
        result = await this.playbackService.play();
      }
      
      if (result.isSuccess()) {
        this.playbackState.isPlaying = !this.playbackState.isPlaying;
        
        Logger.info(this.TAG, `${this.playbackState.isPlaying ? 'Playing' : 'Paused'}`);
      } else {
        Logger.error(this.TAG, `Failed to toggle playback: ${result.message}`);
      }
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      Logger.error(this.TAG, `Failed to toggle playback: ${errorMsg}`);
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
        this.playbackState.playbackSpeed = speed;
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
      const targetTime = this.playbackState.currentTime + seconds;
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
      const targetTime = Math.max(0, this.playbackState.currentTime - seconds);
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
      if (this.mediaState.info) {
        this.subtitleState.isSearching = true;
        Logger.info(this.TAG, `Searching subtitles for: ${this.mediaState.info.title}`);
        
        // 生成缓存键 | Generate cache key
        const cacheKey = `subtitles_${this.mediaState.info.id}_${this.mediaState.info.title}`;
        
        // 尝试从缓存获取 | Try to get from cache
        const cachedTracks = await this.cacheService.get<SubtitleTrack[]>(cacheKey);
        
        if (cachedTracks && cachedTracks.length > 0) {
          this.subtitleState.tracks = cachedTracks;
          this.subtitleState.languages = this.subtitleService.getSupportedLanguages();
          
          Logger.info(this.TAG, `Found ${this.subtitleState.tracks.length} subtitle tracks from cache`);
          this.subtitleState.isSearching = false;
          return;
        }
        
        // 搜索字幕 | Search subtitles
        const result = await this.subtitleService.searchSubtitles({
          title: this.mediaState.info.title,
          year: this.mediaState.info.year,
          languages: ['zh', 'en']
        });
        
        if (result.isSuccess() && result.data) {
          // 合并所有提供商的字幕轨道 | Merge subtitle tracks from all providers
          const allTracks: SubtitleTrack[] = [];
          result.data.forEach((tracks) => {
            allTracks.push(...tracks);
          });
          
          this.subtitleState.tracks = allTracks;
          this.subtitleState.languages = this.subtitleService.getSupportedLanguages();
          
          // 缓存结果 | Cache result
          await this.cacheService.set(cacheKey, this.subtitleState.tracks, {
            expiry: 604800000, // 7天缓存 7 days cache
            priority: CachePriority.NORMAL,
            tags: ['subtitles', 'media'],
            source: 'SubtitleService'
          });
          
          Logger.info(this.TAG, `Found ${this.subtitleState.tracks.length} subtitle tracks from service`);
        } else {
          Logger.warn(this.TAG, `Failed to search subtitles: ${result.message}`);
        }
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to load subtitles: ${error}`);
    } finally {
      this.subtitleState.isSearching = false;
    }
  }
  
  /**
   * 处理字幕选择 | Handle subtitle selection
   */
  private async handleSubtitleSelect(track: SubtitleTrack): Promise<void> {
    try {
      this.subtitleState.selectedTrack = track;
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
      if (this.mediaState.info) {
        await this.subtitleService.addToHistory(this.mediaState.info.id, track);
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to select subtitle: ${error}`);
    }
  }
  
  /**
   * 处理字幕样式设置 | Handle subtitle style setting
   */
  private async handleSubtitleStyleChange(style: SubtitleStyle): Promise<void> {
    try {
      await this.subtitleService.setSubtitleStyle(style);
      await this.playbackService.updateSubtitleStyle(style);
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
      if (this.mediaState.info) {
        // 调用实际的SearchService搜索其他线路 | Call actual SearchService to search other lines
        const result = await this.searchService.searchOtherSources(this.mediaState.info.title);
        
        if (result.isSuccess() && result.data && result.data.length > 0) {
          // 这里可以显示其他线路的搜索结果 | Can show other line search results here
          Logger.info(this.TAG, `Found ${result.data.length} other sources for ${this.mediaState.info.title}`);
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
      await this.playbackService.stop();
      
      // 导航返回 | Navigate back
      await AppNavigator.getInstance().navigateToBack();
      Logger.info(this.TAG, 'Navigating back');
    } catch (error) {
      Logger.error(this.TAG, `Failed to navigate back: ${error}`);
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
      this.skipState.skipOpeningTime = Math.floor(this.playbackState.currentTime);
      this.skipState.isSkipOpeningEnabled = true;
      
      // 保存到缓存 | Save to cache
      if (this.mediaState.info) {
        const cacheKey = `skip_settings_${this.mediaState.info.id}`;
        await this.cacheService.set(cacheKey, {
          skipOpeningTime: this.skipState.skipOpeningTime,
          skipEndingTime: this.skipState.skipEndingTime,
          isSkipOpeningEnabled: this.skipState.isSkipOpeningEnabled,
          isSkipEndingEnabled: this.skipState.isSkipEndingEnabled
        }, {
          expiry: 2592000000, // 30天缓存 | 30 days cache
          priority: CachePriority.HIGH,
          tags: ['skip_settings', 'media']
        });
      }
      
      // 立即跳转到当前时间 | Jump to current time immediately
      await this.playbackService.seek(this.playbackState.currentTime);
      Logger.info(this.TAG, `Skip opening time recorded: ${this.skipState.skipOpeningTime}s`);
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
      const remainingTime = Math.floor(this.playbackState.duration - this.playbackState.currentTime);
      this.skipState.skipEndingTime = remainingTime;
      this.skipState.isSkipEndingEnabled = true;
      
      // 保存到缓存 | Save to cache
      if (this.mediaState.info) {
        const cacheKey = `skip_settings_${this.mediaState.info.id}`;
        await this.cacheService.set(cacheKey, {
          skipOpeningTime: this.skipState.skipOpeningTime,
          skipEndingTime: this.skipState.skipEndingTime,
          isSkipOpeningEnabled: this.skipState.isSkipOpeningEnabled,
          isSkipEndingEnabled: this.skipState.isSkipEndingEnabled
        }, {
          expiry: 2592000000, // 30天缓存 | 30 days cache
          priority: CachePriority.HIGH,
          tags: ['skip_settings', 'media']
        });
      }
      
      Logger.info(this.TAG, `Skip ending time recorded: ${this.skipState.skipEndingTime}s`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to handle skip ending: ${error}`);
    }
  }
  
  /**
   * 检查是否需要自动跳过 | Check if auto skip is needed
   */
  private async checkAutoSkip(): Promise<void> {
    try {
      if (!this.mediaState.info) return;
      
      // 尝试从缓存加载跳过设置 | Try to load skip settings from cache
      const cacheKey = `skip_settings_${this.mediaState.info.id}`;
      const cachedSettings = await this.cacheService.get<{ skipOpeningTime?: number; skipEndingTime?: number; isSkipOpeningEnabled?: boolean; isSkipEndingEnabled?: boolean }>(cacheKey);
      
      if (cachedSettings) {
        this.skipState.skipOpeningTime = cachedSettings.skipOpeningTime || 90;
        this.skipState.skipEndingTime = cachedSettings.skipEndingTime || 300;
        this.skipState.isSkipOpeningEnabled = cachedSettings.isSkipOpeningEnabled !== false;
        this.skipState.isSkipEndingEnabled = cachedSettings.isSkipEndingEnabled !== false;
        Logger.info(this.TAG, `Loaded skip settings from cache`);
      }
      
      // 检查是否需要跳过片头 | Check if need to skip opening
      if (this.skipState.isSkipOpeningEnabled && this.playbackState.currentTime < 5) {
        await this.playbackService.seek(this.skipState.skipOpeningTime);
        Logger.info(this.TAG, `Auto skipped opening to ${this.skipState.skipOpeningTime}s`);
      }
      
      // 检查是否需要跳过片尾 | Check if need to skip ending
      if (this.skipState.isSkipEndingEnabled && this.playbackState.duration > 0) {
        const remainingTime = this.playbackState.duration - this.playbackState.currentTime;
        if (remainingTime <= this.skipState.skipEndingTime + 2) {
          // 跳转到下一集 | Jump to next episode
          const currentIndex = this.mediaState.episodes.findIndex(ep => ep.current);
          if (currentIndex < this.mediaState.episodes.length - 1) {
            await this.handleEpisodeSelect(this.mediaState.episodes[currentIndex + 1]);
          }
          Logger.info(this.TAG, `Auto skipped ending, jumping to next episode`);
        }
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to check auto skip: ${error}`);
    }
  }
  
  // 渲染跳过选项 | Render skip options
  @Builder
  renderSkipOptions() {
    if (this.uiState.showSkipOptions) {
      Column() {
        Text('跳过设置')
          .fontSize(18)
          .fontColor('#333333')
          .fontWeight(600)
          .margin({ bottom: 15 })
        
        // 跳过片头设置 | Skip opening settings
        Column() {
          Text('跳过片头')
            .fontSize(16)
            .fontColor('#666666')
            .fontWeight(500)
            .margin({ bottom: 10, left: 10 })
          
          Row() {
            Button() {
              Text(this.skipState.isSkipOpeningEnabled ? '已开启' : '未开启')
                .fontSize(14)
                .fontColor(this.skipState.isSkipOpeningEnabled ? '#4CAF50' : '#9E9E9E')
                .fontWeight(500)
            }
            .width(120)
            .height(40)
            .backgroundColor(this.skipState.isSkipOpeningEnabled ? '#E8F5E9' : '#F5F5F5')
            .borderRadius(8)
            .margin({ left: 10, right: 15 })
            .onClick(() => this.skipState.isSkipOpeningEnabled = !this.skipState.isSkipOpeningEnabled)
            .focusable(true)
            .onFocus(() => {
              Logger.info(this.TAG, 'Skip opening toggle focused');
            })
            
            Button() {
              Text('设置当前点')
                .fontSize(14)
                .fontColor('#FFFFFF')
                .fontWeight(500)
            }
            .width(150)
            .height(40)
            .backgroundColor('#2196F3')
            .borderRadius(8)
            .onClick(() => this.handleSkipOpening())
            .focusable(true)
            .onFocus(() => {
              Logger.info(this.TAG, 'Set opening point button focused');
            })
          }
          
          Text(`当前跳过时间: ${this.formatTime(this.skipState.skipOpeningTime)}`)
            .fontSize(14)
            .fontColor('#666666')
            .margin({ top: 8, left: 10 })
        }
        .width('100%')
        .margin({ bottom: 20 })
        
        // 跳过片尾设置 | Skip ending settings
        Column() {
          Text('跳过片尾')
            .fontSize(16)
            .fontColor('#666666')
            .fontWeight(500)
            .margin({ bottom: 10, left: 10 })
          
          Row() {
            Button() {
              Text(this.skipState.isSkipEndingEnabled ? '已开启' : '未开启')
                .fontSize(14)
                .fontColor(this.skipState.isSkipEndingEnabled ? '#4CAF50' : '#9E9E9E')
                .fontWeight(500)
            }
            .width(120)
            .height(40)
            .backgroundColor(this.skipState.isSkipEndingEnabled ? '#E8F5E9' : '#F5F5F5')
            .borderRadius(8)
            .margin({ left: 10, right: 15 })
            .onClick(() => this.skipState.isSkipEndingEnabled = !this.skipState.isSkipEndingEnabled)
            .focusable(true)
            .onFocus(() => {
              Logger.info(this.TAG, 'Skip ending toggle focused');
            })
            
            Button() {
              Text('设置当前点')
                .fontSize(14)
                .fontColor('#FFFFFF')
                .fontWeight(500)
            }
            .width(150)
            .height(40)
            .backgroundColor('#2196F3')
            .borderRadius(8)
            .onClick(() => this.handleSkipEnding())
            .focusable(true)
            .onFocus(() => {
              Logger.info(this.TAG, 'Set ending point button focused');
            })
          }
          
          Text(`当前跳过时间: ${this.formatTime(this.skipState.skipEndingTime)}`)
            .fontSize(14)
            .fontColor('#666666')
            .margin({ top: 8, left: 10 })
        }
        .width('100%')
      }
      .width('100%')
      .padding(25)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .margin({ top: 15, right: 30, left: 30 })
      .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.15)', offsetY: 4 })
    }
  }
  
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
  
  // 处理控制条显示 | Handle control bar show
  private showControlsWithTimer(): void {
    this.uiState.showControls = true;
    this.resetControlHideTimer();
  }
  
  // 重置控制条隐藏计时器 | Reset control bar hide timer
  private resetControlHideTimer(): void {
    // 清除之前的计时器 | Clear previous timer
    if (this.uiState.controlHideTimer !== null) {
      this.timerManager.clearTimeout(this.uiState.controlHideTimer);
    }

    // 设置新的计时器，5秒后隐藏控制条 | Set new timer to hide controls after 5 seconds
    this.uiState.controlHideTimer = this.timerManager.setTimeout(() => {
      this.uiState.showControls = false;
    }, 5000, 'PlaybackPage.controlHide');
  }
  
  // 处理键盘事件 | Handle keyboard events
  private onKeyEvent(e: KeyEvent): boolean {
    if (e.type === KeyEvent.KeyType.DOWN) {
      // 重置控制条隐藏计时器 | Reset control bar hide timer on any key press
      if (this.uiState.showControls) {
        this.resetControlHideTimer();
      }
      
      // 直播模式处理 | Live mode handling
      if (this.liveState.isLiveMode) {
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
            this.liveState.showChannelList = true;
            return true;
          case KeyEvent.KeyCode.KEY_RIGHT:
            // 显示直播设置 | Show live settings
            this.liveState.showSettings = true;
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
          if (this.uiState.showControls) {
            this.focusManager.moveUp();
          }
          return true;
        case KeyEvent.KeyCode.KEY_DOWN:
          // 处理下方向键 | Handle down arrow
          if (!this.uiState.showControls) {
            // 显示控制条 | Show controls
            this.showControlsWithTimer();
          } else {
            // 导航到下一个控制按钮 | Navigate to next control button
            this.focusManager.moveDown();
          }
          return true;
        case KeyEvent.KeyCode.KEY_LEFT:
          // 处理左方向键 | Handle left arrow
          if (!this.uiState.showControls) {
            // 快退10秒 | Rewind 10 seconds
            this.handleRewind(10);
          } else {
            // 导航到左侧控制按钮 | Navigate to left control button
            this.focusManager.moveLeft();
          }
          return true;
        case KeyEvent.KeyCode.KEY_RIGHT:
          // 处理右方向键 | Handle right arrow
          if (!this.uiState.showControls) {
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
            if (!this.uiState.showControls) {
              this.handleFastForward(30);
            }
            break;
          case GestureEvent.Direction.RIGHT:
            // 向右滑动 | Swipe right
            if (!this.uiState.showControls) {
              this.handleRewind(10);
            }
            break;
          case GestureEvent.Direction.UP:
            // 向上滑动 | Swipe up
            break;
          case GestureEvent.Direction.DOWN:
            // 向下滑动 | Swipe down
            if (!this.uiState.showControls) {
              this.showControlsWithTimer();
            }
            break;
        }
        break;
      case GestureEvent.GestureType.TAP:
        // 处理点击手势 | Handle tap gesture
        if (!this.uiState.showControls) {
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
  
  // 渲染直播频道列表 | Render live channel list
  @Builder
  renderLiveChannelList() {
    if (this.liveState.showChannelList && this.liveState.isLiveMode) {
      Column() {
        Text('频道列表')
          .fontSize(18)
          .fontColor('#333333')
          .fontWeight(600)
          .margin({ bottom: 15 })
        
        // 频道列表内容 | Channel list content
        // 这里应该从直播服务获取频道列表 | Should get channel list from live service
      }
      .width('300px')
      .height('100%')
      .padding(25)
      .backgroundColor('rgba(0, 0, 0, 0.8)')
      .borderRadius(12)
      .position({ left: 0, top: 0 })
    }
  }
  
  // 渲染直播设置 | Render live settings
  @Builder
  renderLiveSettings() {
    if (this.liveState.showSettings && this.liveState.isLiveMode) {
      Column() {
        Text('直播设置')
          .fontSize(18)
          .fontColor('#333333')
          .fontWeight(600)
          .margin({ bottom: 15 })
        
        // 响应超时设置 | Response timeout settings
        Column() {
          Text('响应超时设置')
            .fontSize(16)
            .fontColor('#666666')
            .fontWeight(500)
            .margin({ bottom: 10, left: 10 })
          
          Text('超时时间: 5秒')
            .fontSize(14)
            .fontColor('#FFFFFF')
            .margin({ left: 10, bottom: 5 })
          
          Text('超时后切换到下一个频道')
            .fontSize(14)
            .fontColor('#FFFFFF')
            .margin({ left: 10 })
        }
        .width('100%')
        .margin({ bottom: 20 })
      }
      .width('300px')
      .height('100%')
      .padding(25)
      .backgroundColor('rgba(0, 0, 0, 0.8)')
      .borderRadius(12)
      .position({ right: 0, top: 0 })
    }
  }
  
  // 焦点管理器类 | Focus manager class
  class FocusManager {
    private currentFocusIndex: number = 0;
    private focusableElements: FocusableElement[] = [];
    
    // 添加可焦点元素 | Add focusable element
    addElement(element: FocusableElement): void {
      this.focusableElements.push(element);
    }
    
    // 移动焦点上 | Move focus up
    moveUp(): void {
      // 实现向上导航逻辑 | Implement up navigation logic
      this.currentFocusIndex = Math.max(0, this.currentFocusIndex - 1);
      this.updateFocus();
    }
    
    // 移动焦点下 | Move focus down
    moveDown(): void {
      // 实现向下导航逻辑 | Implement down navigation logic
      this.currentFocusIndex = Math.min(this.focusableElements.length - 1, this.currentFocusIndex + 1);
      this.updateFocus();
    }
    
    // 移动焦点左 | Move focus left
    moveLeft(): void {
      // 实现向左导航逻辑 | Implement left navigation logic
      this.currentFocusIndex = Math.max(0, this.currentFocusIndex - 1);
      this.updateFocus();
    }
    
    // 移动焦点右 | Move focus right
    moveRight(): void {
      // 实现向右导航逻辑 | Implement right navigation logic
      this.currentFocusIndex = Math.min(this.focusableElements.length - 1, this.currentFocusIndex + 1);
      this.updateFocus();
    }
    
    // 更新焦点 | Update focus
    private updateFocus(): void {
      // 实现焦点更新逻辑 | Implement focus update logic
      console.log(`Focus updated to index: ${this.currentFocusIndex}`);
    }
  }
  
  // 可焦点元素接口 | Focusable element interface
  interface FocusableElement {
    id: string;
    type: string;
    focus(): void;
    blur(): void;
  }
  
  // 渲染视频播放区域 | Render video playback area
  @Builder
  renderVideoPlayer() {
    Column() {
      if (this.playbackState.isLoading) {
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
            .height(this.uiState.videoPlayerHeight)
            .backgroundColor('rgba(0, 0, 0, 0.9)')
            .touchEventListener((e) => this.onTouchEvent(e))
            .gestureEventListener((e) => this.onGestureEvent(e))
          } else if (this.playbackState.isError) {
            Column() {
              Text('播放失败')
                .fontSize(28)
                .fontColor('#FF5722')
                .fontWeight(700)
                .margin({ top: 20 })
              Text(this.playbackState.errorMessage)
                .fontSize(18)
                .fontColor('#FFFFFF')
                .margin({ top: 12, left: 40, right: 40 })
                .textAlign(TextAlign.Center)
              Button('重试')
                .onClick(() => {
                  this.playbackState.isError = false;
                  this.loadMediaInfo();
                })
                .backgroundColor('#4CAF50')
                .fontColor('white')
                .borderRadius(16)
                .padding({ left: 40, right: 40, top: 15, bottom: 15 })
                .margin({ top: 30 })
                .fontSize(18)
                .fontWeight(600)
                .focusable(true)
                .focusStyle(this.focusStyle)
                .onFocus(() => {
                  Logger.info(this.TAG, 'Retry button focused');
                })
                .keyEventListener((e) => this.onKeyEvent(e))
              Button('返回')
                .onClick(() => this.handleBack())
                .backgroundColor('#607D8B')
                .fontColor('white')
                .borderRadius(16)
                .padding({ left: 40, right: 40, top: 15, bottom: 15 })
                .margin({ top: 15 })
                .fontSize(18)
                .fontWeight(600)
                .focusable(true)
                .focusStyle(this.focusStyle)
                .onFocus(() => {
                  Logger.info(this.TAG, 'Back button focused');
                })
                .keyEventListener((e) => this.onKeyEvent(e))
            }
            .justifyContent(FlexAlign.Center)
            .width('100%')
            .height(this.uiState.videoPlayerHeight)
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
            .height(this.uiState.videoPlayerHeight - 80)
            .backgroundColor('#000000')
            .justifyContent(FlexAlign.Center)
            .touchEventListener((e) => this.onTouchEvent(e))
            .gestureEventListener((e) => this.onGestureEvent(e))
            
            // 播放控制组件 | Playback controls component
            PlaybackControls({
              isPlaying: this.playbackState.isPlaying,
              currentTime: this.playbackState.currentTime,
              duration: this.playbackState.duration,
              progress: this.playbackState.progress,
              showControls: this.uiState.showControls,
              selectedSubtitle: this.subtitleState.selectedTrack,
              showSkipOptions: this.uiState.showSkipOptions,
              showSubtitleOptions: this.uiState.showSubtitleOptions,
              showAudioTrackOptions: this.uiState.showAudioTrackOptions,
              audioTracks: this.audioState.tracks,
              selectedAudioTrack: this.audioState.selectedTrack,
              videoPlayerHeight: this.uiState.videoPlayerHeight,
              onPlayPause: () => this.handlePlayPause(),
              onFastForward: (seconds: number) => this.handleFastForward(seconds),
              onRewind: (seconds: number) => this.handleRewind(seconds),
              onShowSkipOptions: () => this.uiState.showSkipOptions = !this.uiState.showSkipOptions,
              onShowSubtitleOptions: () => this.uiState.showSubtitleOptions = !this.uiState.showSubtitleOptions,
              onShowAudioTrackOptions: () => this.uiState.showAudioTrackOptions = !this.uiState.showAudioTrackOptions,
              onKeyEvent: (e: KeyEvent) => this.onKeyEvent(e)
            })
          }
          
          // 跳过设置组件 | Skip settings component
          SkipSettings({
            showSkipOptions: this.uiState.showSkipOptions,
            isSkipOpeningEnabled: this.skipState.isSkipOpeningEnabled,
            isSkipEndingEnabled: this.skipState.isSkipEndingEnabled,
            skipOpeningTime: this.skipState.skipOpeningTime,
            skipEndingTime: this.skipState.skipEndingTime,
            onToggleSkipOpening: () => this.skipState.isSkipOpeningEnabled = !this.skipState.isSkipOpeningEnabled,
            onToggleSkipEnding: () => this.skipState.isSkipEndingEnabled = !this.skipState.isSkipEndingEnabled,
            onSetSkipOpeningTime: () => this.handleSkipOpening(),
            onSetSkipEndingTime: () => this.handleSkipEnding()
          })
        }
      }
    }
  }
  
  // 渲染剧集列表 | Render episode list
  @Builder
  renderEpisodeList() {
    EpisodeList({
      episodes: this.mediaState.episodes,
      selectedEpisode: this.mediaState.selectedEpisode,
      showEpisodeList: this.uiState.showEpisodeList,
      onEpisodeSelect: (episode: Episode) => this.handleEpisodeSelect(episode)
    })
  }
  
  // 渲染媒体信息 | Render media info
  @Builder
  renderMediaInfo() {
    if (this.mediaState.info) {
      Column() {
        Row() {
          // 封面 | Cover
          Image(this.mediaState.info.cover || 'https://via.placeholder.com/200x300?text=No+Image')
            .width(this.uiState.isLandscape ? 200 : 150)
            .height(this.uiState.isLandscape ? 300 : 200)
            .objectFit(ImageFit.Cover)
            .borderRadius(12)
            .backgroundColor('#F5F5F5')
            .margin({ left: this.uiState.isLandscape ? 40 : 30, right: 25 })
          
          // 信息 | Info
          Column() {
            Text(this.mediaState.info.title)
              .fontSize(this.uiState.isLandscape ? 28 : 24)
              .fontWeight(700)
              .fontColor('#333333')
              .margin({ bottom: 15 })
            
            Text(this.mediaState.info.description || '暂无简介')
              .fontSize(16)
              .fontColor('#666666')
              .maxLines(this.uiState.isLandscape ? 4 : 3)
              .margin({ bottom: 15 })
            
            Row() {
              Text(`类型: ${this.mediaState.info.type || '未知'}`)
                .fontSize(16)
                .fontColor('#666666')
                .margin({ right: 25 })
              Text(`评分: ${this.mediaState.info.rating || '暂无'}`)
                .fontSize(16)
                .fontColor('#FF9800')
                .fontWeight(500)
            }
          }
        }
      }
    }
  }
  
  // 渲染解析线路选择 | Render parse line selection
  @Builder
  renderParseLineSelection() {
    if (this.mediaState.info) {
      Column() {
        Row() {
          Text('解析线路:')
            .fontSize(18)
            .fontColor('#333333')
            .fontWeight(500)
            .margin({ right: 15, top: 20 })
          
          Scroll(this.scroller) {
            Row() {
              ForEach(this.mediaState.parseLines, (line: ParseLine) => {
                Button() {
                  Text(line.name)
                    .fontSize(14)
                    .fontColor(line.selected ? '#FFFFFF' : '#333333')
                    .fontWeight(500)
                }
                .width(100)
                .height(40)
                .backgroundColor(line.selected ? '#2196F3' : '#F5F5F5')
                .borderRadius(8)
                .margin({ right: 10 })
                .onClick(() => this.handleLineSelect(line))
                .focusable(true)
                .focusStyle(this.focusStyle)
                .onFocus(() => {
                  Logger.info(this.TAG, `Parse line ${line.name} focused`);
                })
                .keyEventListener((e) => this.onKeyEvent(e))
              })
            }
          }
          .width('70%')
          .height(60)
        }
      }
    }
  }
  
  // 渲染内容信息 | Render content info
  @Builder
  renderContentInfo() {
    if (this.mediaInfo) {
      Column() {
        Row() {
          // 封面 | Cover
          Image(this.mediaInfo.cover || 'https://via.placeholder.com/200x300?text=No+Image')
            .width(this.isLandscape ? 200 : 150)
            .height(this.isLandscape ? 300 : 200)
            .objectFit(ImageFit.Cover)
            .borderRadius(12)
            .backgroundColor('#F5F5F5')
            .margin({ left: this.isLandscape ? 40 : 30, right: 25 })
          
          // 信息 | Info
          Column() {
            Text(this.mediaInfo.title)
              .fontSize(this.isLandscape ? 28 : 24)
              .fontWeight(700)
              .fontColor('#333333')
              .margin({ bottom: 15 })
            
            Text(this.mediaInfo.description || '暂无简介')
              .fontSize(16)
              .fontColor('#666666')
              .maxLines(this.isLandscape ? 4 : 3)
              .margin({ bottom: 15 })
            
            Row() {
              Text(`类型: ${this.mediaInfo.type || '未知'}`)
                .fontSize(16)
                .fontColor('#666666')
                .margin({ right: 25 })
              Text(`评分: ${this.mediaInfo.rating || '暂无'}`)
                .fontSize(16)
                .fontColor('#FF9800')
                .fontWeight(500)
            }
            
            // 解析线路选择 | Parse line selection
            Row() {
              Text('解析线路:')
                .fontSize(18)
                .fontColor('#333333')
                .fontWeight(500)
                .margin({ right: 15, top: 20 })
              
              Scroll(this.scroller) {
                Row() {
                  ForEach(this.parseLines, (line: ParseLine) => {
                    Button() {
                      Text(line.name)
                        .fontSize(14)
                        .fontColor(line.selected ? '#FFFFFF' : '#333333')
                        .fontWeight(line.selected ? 600 : 400)
                    }
                    .padding({ left: 20, right: 20, top: 10, bottom: 10 })
                    .backgroundColor(line.selected ? '#4CAF50' : '#F5F5F5')
                    .borderRadius(20)
                    .margin({ right: 12, top: 20 })
                    .onClick(() => this.handleLineSelect(line))
                    .focusable(true)
                    .onFocus(() => {
                      Logger.info(this.TAG, `Parse line focused: ${line.name}`);
                    })
                  })
                }
                .width('100%')
                .flexWrap(FlexWrap.Wrap)
              }
              .scrollDirection(ScrollDirection.Horizontal)
              .scrollBar(BarState.Auto)
              .flexGrow(1)
            }
          }
          .flexGrow(1)
          .margin({ right: this.isLandscape ? 40 : 30 })
        }
        .width('100%')
        .padding({ top: 25, bottom: 25 })
        .backgroundColor('#FFFFFF')
      }
    }
  }
  
  // 渲染剧集列表 | Render episode list
  @Builder
  renderEpisodeList() {
    if (this.episodes.length > 0) {
      Column() {
        Row() {
          Text('剧集列表')
            .fontSize(20)
            .fontWeight(700)
            .fontColor('#333333')
            .margin({ left: this.isLandscape ? 40 : 30 })
          
          Button() {
            Text('其他线路搜索')
              .fontSize(16)
              .fontColor('#FFFFFF')
              .fontWeight(500)
          }
          .width(150)
          .height(50)
          .backgroundColor('#2196F3')
          .borderRadius(8)
          .margin({ right: this.isLandscape ? 40 : 30 })
          .onClick(() => this.handleOtherLineSearch())
          .focusable(true)
          .onFocus(() => {
            Logger.info(this.TAG, 'Other lines button focused');
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .alignItems(VerticalAlign.Center)
        .margin({ bottom: 20 })
        
        Scroll(this.episodeScroller) {
          Row() {
            ForEach(this.episodes, (episode: Episode) => {
              Button() {
                Text(`第${episode.episode}集`)
                  .fontSize(14)
                  .fontColor(episode.current ? '#FFFFFF' : episode.played ? '#4CAF50' : '#333333')
                  .fontWeight(episode.current ? 600 : 400)
              }
              .width(90)
              .height(45)
              .backgroundColor(episode.current ? '#4CAF50' : episode.played ? '#E8F5E9' : '#F5F5F5')
              .borderRadius(8)
              .margin({ left: this.isLandscape ? 40 : 30, right: 12, bottom: 15 })
              .onClick(() => this.handleEpisodeSelect(episode))
              .focusable(true)
              .onFocus(() => {
                Logger.info(this.TAG, `Episode ${episode.episode} focused`);
              })
            })
          }
          .width('100%')
          .padding({ bottom: 40 })
          .flexWrap(FlexWrap.Wrap)
        }
        .scrollBar(BarState.Auto)
        .flexGrow(1)
      }
      .width('100%')
      .padding({ top: 25 })
      .backgroundColor('#F5F5F5')
    }
  }
  
  // 渲染播放速度选项 | Render playback speed options
  @Builder
  renderSpeedOptions() {
    if (this.showMoreOptions) {
      Column() {
        Text('播放速度')
          .fontSize(18)
          .fontColor('#333333')
          .fontWeight(600)
          .margin({ bottom: 15 })
        
        Row() {
          ForEach([0.5, 0.75, 1.0, 1.25, 1.5, 2.0], (speed: number) => {
            Button() {
              Text(`${speed}x`)
                .fontSize(16)
                .fontColor(speed === this.playbackSpeed ? '#FFFFFF' : '#333333')
                .fontWeight(speed === this.playbackSpeed ? 600 : 400)
            }
            .padding({ left: 20, right: 20, top: 12, bottom: 12 })
            .backgroundColor(speed === this.playbackSpeed ? '#4CAF50' : '#F5F5F5')
            .borderRadius(20)
            .margin({ right: 15 })
            .onClick(() => this.handleSpeedChange(speed))
            .focusable(true)
            .onFocus(() => {
              Logger.info(this.TAG, `Speed ${speed}x focused`);
            })
          })
        }
      }
      .width('100%')
      .padding(25)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .margin({ top: 15, right: 30, left: 30 })
      .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.15)', offsetY: 4 })
    }
  }
  
  // 渲染字幕选项 | Render subtitle options
  @Builder
  renderSubtitleOptions() {
    if (this.showSubtitleOptions) {
      Column() {
        Text('字幕选项')
          .fontSize(18)
          .fontColor('#333333')
          .fontWeight(600)
          .margin({ bottom: 15 })
        
        // 字幕轨道列表 | Subtitle track list
        Column() {
          Text('可用字幕')
            .fontSize(16)
            .fontColor('#666666')
            .fontWeight(500)
            .margin({ bottom: 10, left: 10 })
          
          if (this.isSearchingSubtitles) {
            Text('搜索字幕中...')
              .fontSize(14)
              .fontColor('#999999')
              .margin({ left: 10 })
          } else if (this.subtitleTracks.length === 0) {
            Text('未找到字幕')
              .fontSize(14)
              .fontColor('#999999')
              .margin({ left: 10 })
          } else {
            ForEach(this.subtitleTracks, (track: SubtitleTrack) => {
              Button() {
                Text(track.name)
                  .fontSize(14)
                  .fontColor(track.id === this.selectedSubtitle?.id ? '#FFFFFF' : '#333333')
                  .fontWeight(track.id === this.selectedSubtitle?.id ? 600 : 400)
              }
              .padding({ left: 20, right: 20, top: 10, bottom: 10 })
              .backgroundColor(track.id === this.selectedSubtitle?.id ? '#4CAF50' : '#F5F5F5')
              .borderRadius(12)
              .margin({ bottom: 8, left: 10, right: 10 })
              .onClick(() => this.handleSubtitleSelect(track))
              .focusable(true)
              .onFocus(() => {
                Logger.info(this.TAG, `Subtitle track focused: ${track.name}`);
              })
            })
          }
        }
        .width('100%')
        .margin({ bottom: 20 })
        
        // 字幕样式设置 | Subtitle style settings
        Column() {
          Text('字幕样式')
            .fontSize(16)
            .fontColor('#666666')
            .fontWeight(500)
            .margin({ bottom: 10, left: 10 })
          
          Row() {
            Button() {
              Text('默认样式')
                .fontSize(14)
                .fontColor('#FFFFFF')
                .fontWeight(500)
            }
            .padding({ left: 20, right: 20, top: 10, bottom: 10 })
            .backgroundColor('#2196F3')
            .borderRadius(12)
            .margin({ left: 10, right: 10 })
            .onClick(() => this.handleSubtitleStyleChange({}))
            .focusable(true)
            .onFocus(() => {
              Logger.info(this.TAG, 'Default style button focused');
            })
          }
        }
        .width('100%')
      }
      .width('100%')
      .padding(25)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .margin({ top: 15, right: 30, left: 30 })
      .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.15)', offsetY: 4 })
    }
  }
  
  /**
   * 处理音轨选择 | Handle audio track selection
   */
  private async handleAudioTrackSelect(track: AudioTrack): Promise<void> {
    try {
      this.selectedAudioTrack = track;
      // 调用实际的PlaybackService切换音轨 | Call actual PlaybackService to switch audio track
      await this.playbackService.setAudioTrack(track.id);
      Logger.info(this.TAG, `Selected audio track: ${track.name}`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to select audio track: ${error}`);
    }
  }
  
  // 渲染音轨选项 | Render audio track options
  @Builder
  renderAudioTrackOptions() {
    if (this.showAudioTrackOptions) {
      Column() {
        Text('音轨选择')
          .fontSize(18)
          .fontColor('#333333')
          .fontWeight(600)
          .margin({ bottom: 15 })
        
        if (this.audioTracks.length === 0) {
          Text('未检测到多音轨')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ left: 10 })
        } else {
          ForEach(this.audioTracks, (track: AudioTrack) => {
            Button() {
              Text(track.name || `音轨 ${track.id}`)
                .fontSize(14)
                .fontColor(track.id === this.selectedAudioTrack?.id ? '#FFFFFF' : '#333333')
                .fontWeight(track.id === this.selectedAudioTrack?.id ? 600 : 400)
            }
            .padding({ left: 20, right: 20, top: 10, bottom: 10 })
            .backgroundColor(track.id === this.selectedAudioTrack?.id ? '#4CAF50' : '#F5F5F5')
            .borderRadius(12)
            .margin({ bottom: 8, left: 10, right: 10 })
            .onClick(() => this.handleAudioTrackSelect(track))
            .focusable(true)
            .onFocus(() => {
              Logger.info(this.TAG, `Audio track focused: ${track.name}`);
            })
          })
        }
      }
      .width('100%')
      .padding(25)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .margin({ top: 15, right: 30, left: 30 })
      .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.15)', offsetY: 4 })
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
        .margin({ left: this.isLandscape ? 40 : 30 })
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
          .margin({ left: this.isLandscape ? 40 : 30 })
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
        .margin({ right: this.isLandscape ? 40 : 30 })
        .onClick(() => this.showControls = !this.showControls)
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
      
      // 内容信息 | Content info
      this.renderContentInfo()
      
      // 剧集列表 | Episode list
      this.renderEpisodeList()
      
      // 播放速度选项 | Playback speed options
      this.renderSpeedOptions()
      
      // 字幕选项 | Subtitle options
      this.renderSubtitleOptions()
      

      
      // 音轨选项 | Audio track options
      this.renderAudioTrackOptions()
      
      // 跳过选项 | Skip options
      this.renderSkipOptions()
      
      // 直播频道列表 | Live channel list
      this.renderLiveChannelList()
      
      // 直播设置 | Live settings
      this.renderLiveSettings()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
