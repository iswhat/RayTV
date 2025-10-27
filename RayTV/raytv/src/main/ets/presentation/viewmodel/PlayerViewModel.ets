// PlayerViewModel - 播放器页面视图模型
import { observable, computed, action, makeObservable } from '@ohos:arkdata';
import Logger from '../../common/util/Logger';
import { Vod } from '../../data/bean/Vod';
import { Live } from '../../data/bean/Live';
import { PlayVodUseCase } from '../../domain/usecase/PlayVodUseCase';
import { PlayLiveUseCase } from '../../domain/usecase/PlayLiveUseCase';
import { LoadConfigUseCase } from '../../domain/usecase/LoadConfigUseCase';

const TAG = 'PlayerViewModel';

/**
 * 播放类型枚举
 */
export enum PlayType {
  VOD = 'VOD',
  LIVE = 'LIVE'
}

/**
 * 播放器状态枚举
 */
export enum PlayerStatus {
  IDLE = 'IDLE',
  LOADING = 'LOADING',
  PLAYING = 'PLAYING',
  PAUSED = 'PAUSED',
  BUFFERING = 'BUFFERING',
  ERROR = 'ERROR',
  COMPLETED = 'COMPLETED'
}

/**
 * 播放器页面的视图模型
 */
export class PlayerViewModel {
  // 状态数据
  @observable private playType: PlayType | null = null;
  @observable private vodItem: Vod | null = null;
  @observable private liveItem: Live | null = null;
  @observable private currentSourceIndex: number = 0;
  @observable private currentEpisodeIndex: number = 0;
  @observable private playerStatus: PlayerStatus = PlayerStatus.IDLE;
  @observable private currentPosition: number = 0;
  @observable private duration: number = 0;
  @observable private bufferProgress: number = 0;
  @observable private isFullScreen: boolean = false;
  @observable private isFavorite: boolean = false;
  @observable private isMuted: boolean = false;
  @observable private volume: number = 1.0;
  @observable private playbackSpeed: number = 1.0;
  @observable private errorMessage: string = '';
  @observable private isLoading: boolean = false;
  @observable private videoSources: string[] = [];
  @observable private epgList: Array<{ start: string; end: string; title: string }> = [];
  
  // 用例
  private playVodUseCase: PlayVodUseCase;
  private playLiveUseCase: PlayLiveUseCase;
  private loadConfigUseCase: LoadConfigUseCase;
  
  constructor(
    playVodUseCase: PlayVodUseCase,
    playLiveUseCase: PlayLiveUseCase,
    loadConfigUseCase: LoadConfigUseCase
  ) {
    makeObservable(this);
    this.playVodUseCase = playVodUseCase;
    this.playLiveUseCase = playLiveUseCase;
    this.loadConfigUseCase = loadConfigUseCase;
  }
  
  // 计算属性
  @computed
  public get getPlayType(): PlayType | null {
    return this.playType;
  }
  
  @computed
  public get getVodItem(): Vod | null {
    return this.vodItem;
  }
  
  @computed
  public get getLiveItem(): Live | null {
    return this.liveItem;
  }
  
  @computed
  public get getCurrentSourceIndex(): number {
    return this.currentSourceIndex;
  }
  
  @computed
  public get getCurrentEpisodeIndex(): number {
    return this.currentEpisodeIndex;
  }
  
  @computed
  public get getPlayerStatus(): PlayerStatus {
    return this.playerStatus;
  }
  
  @computed
  public get getCurrentPosition(): number {
    return this.currentPosition;
  }
  
  @computed
  public get getDuration(): number {
    return this.duration;
  }
  
  @computed
  public get getBufferProgress(): number {
    return this.bufferProgress;
  }
  
  @computed
  public get getIsFullScreen(): boolean {
    return this.isFullScreen;
  }
  
  @computed
  public get getIsFavorite(): boolean {
    return this.isFavorite;
  }
  
  @computed
  public get getIsMuted(): boolean {
    return this.isMuted;
  }
  
  @computed
  public get getVolume(): number {
    return this.volume;
  }
  
  @computed
  public get getPlaybackSpeed(): number {
    return this.playbackSpeed;
  }
  
  @computed
  public get getErrorMessage(): string {
    return this.errorMessage;
  }
  
  @computed
  public get getIsLoading(): boolean {
    return this.isLoading;
  }
  
  @computed
  public get getVideoSources(): string[] {
    return this.videoSources;
  }
  
  @computed
  public get getEpgList(): Array<{ start: string; end: string; title: string }> {
    return this.epgList;
  }
  
  @computed
  public get getCurrentTitle(): string {
    if (this.playType === PlayType.VOD && this.vodItem) {
      return this.vodItem.name || '点播节目';
    } else if (this.playType === PlayType.LIVE && this.liveItem) {
      return this.liveItem.name || '直播频道';
    }
    return '未知节目';
  }
  
  @computed
  public get getCurrentSourceUrl(): string {
    if (this.videoSources.length > 0 && this.currentSourceIndex < this.videoSources.length) {
      return this.videoSources[this.currentSourceIndex];
    }
    return '';
  }
  
  @computed
  public get getProgress(): number {
    if (this.duration > 0) {
      return (this.currentPosition / this.duration) * 100;
    }
    return 0;
  }
  
  /**
   * 初始化播放器
   * @param type 播放类型
   * @param id 内容ID
   */
  @action
  public async initializePlayer(type: PlayType, id: string): Promise<void> {
    try {
      this.isLoading = true;
      this.errorMessage = '';
      this.playType = type;
      
      Logger.info(TAG, `Initializing player for ${type} with id: ${id}`);
      
      if (type === PlayType.VOD) {
        await this.initializeVodPlayer(id);
      } else if (type === PlayType.LIVE) {
        await this.initializeLivePlayer(id);
      }
      
    } catch (error) {
      Logger.error(TAG, `Failed to initialize player: ${error}`);
      this.errorMessage = '播放器初始化失败';
      this.playerStatus = PlayerStatus.ERROR;
    } finally {
      this.isLoading = false;
    }
  }
  
  /**
   * 初始化点播播放器
   * @param id 点播ID
   */
  @action
  private async initializeVodPlayer(id: string): Promise<void> {
    try {
      // 加载详情
      const vodDetail = await this.playVodUseCase.loadVodDetail(id);
      this.vodItem = vodDetail;
      
      // 准备播放
      const result = await this.playVodUseCase.preparePlayback(id);
      this.videoSources = result.sources;
      
      // 检查收藏状态
      this.isFavorite = await this.playVodUseCase.isFavorited(id);
      
      // 加载播放进度
      const progress = await this.playVodUseCase.loadPlaybackProgress(id);
      if (progress > 0) {
        this.currentPosition = progress;
      }
      
      Logger.info(TAG, `VOD player initialized with ${result.sources.length} sources`);
    } catch (error) {
      Logger.error(TAG, `Failed to initialize VOD player: ${error}`);
      throw error;
    }
  }
  
  /**
   * 初始化直播播放器
   * @param id 直播ID
   */
  @action
  private async initializeLivePlayer(id: string): Promise<void> {
    try {
      // 准备播放
      const result = await this.playLiveUseCase.preparePlayback(id);
      this.liveItem = result.channel;
      this.videoSources = result.sources;
      
      // 检查收藏状态
      this.isFavorite = await this.playLiveUseCase.isFavorited(id);
      
      // 加载EPG
      const epgResult = await this.playLiveUseCase.getLiveEpg(id);
      this.epgList = epgResult.programs || [];
      
      Logger.info(TAG, `Live player initialized with ${result.sources.length} sources and ${this.epgList.length} EPG items`);
    } catch (error) {
      Logger.error(TAG, `Failed to initialize live player: ${error}`);
      throw error;
    }
  }
  
  /**
   * 更新播放器状态
   * @param status 播放器状态
   */
  @action
  public updatePlayerStatus(status: PlayerStatus): void {
    this.playerStatus = status;
    
    // 当播放完成时保存进度
    if (status === PlayerStatus.COMPLETED && this.playType === PlayType.VOD && this.vodItem) {
      this.savePlaybackProgress();
    }
    
    Logger.debug(TAG, `Player status updated to: ${status}`);
  }
  
  /**
   * 更新播放进度
   * @param position 当前位置（毫秒）
   * @param duration 总时长（毫秒）
   */
  @action
  public updatePlaybackProgress(position: number, duration: number): void {
    this.currentPosition = position;
    this.duration = duration;
    
    // 每30秒自动保存进度
    if (position % 30000 < 1000) {
      this.savePlaybackProgress();
    }
  }
  
  /**
   * 更新缓冲进度
   * @param progress 缓冲进度（0-100）
   */
  @action
  public updateBufferProgress(progress: number): void {
    this.bufferProgress = progress;
  }
  
  /**
   * 切换全屏状态
   */
  @action
  public toggleFullScreen(): void {
    this.isFullScreen = !this.isFullScreen;
    Logger.info(TAG, `Full screen mode: ${this.isFullScreen}`);
  }
  
  /**
   * 设置全屏状态
   * @param isFull 是否全屏
   */
  @action
  public setFullScreen(isFull: boolean): void {
    this.isFullScreen = isFull;
  }
  
  /**
   * 切换收藏状态
   */
  @action
  public async toggleFavorite(): Promise<void> {
    try {
      if (this.playType === PlayType.VOD && this.vodItem) {
        if (this.isFavorite) {
          await this.playVodUseCase.unfavorite(this.vodItem.id);
        } else {
          await this.playVodUseCase.favorite(this.vodItem.id);
        }
      } else if (this.playType === PlayType.LIVE && this.liveItem) {
        if (this.isFavorite) {
          await this.playLiveUseCase.unfavorite(this.liveItem.id);
        } else {
          await this.playLiveUseCase.favorite(this.liveItem.id);
        }
      }
      
      this.isFavorite = !this.isFavorite;
      Logger.info(TAG, `Favorite toggled: ${this.isFavorite}`);
    } catch (error) {
      Logger.error(TAG, `Failed to toggle favorite: ${error}`);
      this.errorMessage = '操作失败，请重试';
    }
  }
  
  /**
   * 切换静音状态
   */
  @action
  public toggleMute(): void {
    this.isMuted = !this.isMuted;
    Logger.info(TAG, `Mute toggled: ${this.isMuted}`);
  }
  
  /**
   * 设置音量
   * @param value 音量值（0-1）
   */
  @action
  public setVolume(value: number): void {
    this.volume = Math.max(0, Math.min(1, value));
    if (value > 0) {
      this.isMuted = false;
    }
    Logger.debug(TAG, `Volume set to: ${this.volume}`);
  }
  
  /**
   * 设置播放速度
   * @param speed 播放速度
   */
  @action
  public setPlaybackSpeed(speed: number): void {
    this.playbackSpeed = speed;
    Logger.info(TAG, `Playback speed set to: ${speed}`);
  }
  
  /**
   * 切换视频源
   * @param index 视频源索引
   */
  @action
  public async switchVideoSource(index: number): Promise<void> {
    if (index < 0 || index >= this.videoSources.length) {
      Logger.error(TAG, `Invalid source index: ${index}`);
      return;
    }
    
    try {
      this.currentSourceIndex = index;
      
      // 重置播放位置
      this.currentPosition = 0;
      this.bufferProgress = 0;
      
      Logger.info(TAG, `Switched to video source ${index + 1}/${this.videoSources.length}`);
    } catch (error) {
      Logger.error(TAG, `Failed to switch video source: ${error}`);
      this.errorMessage = '切换视频源失败';
    }
  }
  
  /**
   * 切换剧集
   * @param index 剧集索引
   */
  @action
  public async switchEpisode(index: number): Promise<void> {
    if (this.playType !== PlayType.VOD || !this.vodItem) {
      return;
    }
    
    try {
      this.currentEpisodeIndex = index;
      this.currentPosition = 0;
      this.bufferProgress = 0;
      
      Logger.info(TAG, `Switched to episode ${index + 1}`);
      
      // 准备新剧集的播放
      const result = await this.playVodUseCase.preparePlayback(this.vodItem.id, index);
      this.videoSources = result.sources;
      
      // 加载该剧集的播放进度
      const progress = await this.playVodUseCase.loadPlaybackProgress(
        this.vodItem.id,
        index
      );
      if (progress > 0) {
        this.currentPosition = progress;
      }
    } catch (error) {
      Logger.error(TAG, `Failed to switch episode: ${error}`);
      this.errorMessage = '切换剧集失败';
    }
  }
  
  /**
   * 保存播放进度
   */
  @action
  private async savePlaybackProgress(): Promise<void> {
    if (this.playType !== PlayType.VOD || !this.vodItem) {
      return;
    }
    
    try {
      await this.playVodUseCase.savePlaybackProgress(
        this.vodItem.id,
        this.currentPosition,
        this.currentEpisodeIndex
      );
      
      Logger.debug(TAG, `Playback progress saved: ${this.currentPosition}ms`);
    } catch (error) {
      Logger.error(TAG, `Failed to save playback progress: ${error}`);
    }
  }
  
  /**
   * 跳转播放位置
   * @param position 目标位置（毫秒）
   */
  @action
  public seekTo(position: number): void {
    this.currentPosition = Math.max(0, Math.min(position, this.duration));
    Logger.debug(TAG, `Seek to position: ${this.currentPosition}ms`);
  }
  
  /**
   * 刷新直播源
   */
  @action
  public async refreshLiveSource(): Promise<void> {
    if (this.playType !== PlayType.LIVE || !this.liveItem) {
      return;
    }
    
    try {
      this.isLoading = true;
      this.errorMessage = '';
      
      Logger.info(TAG, `Refreshing live source for: ${this.liveItem.name}`);
      
      const result = await this.playLiveUseCase.refreshLiveSource(this.liveItem.id);
      this.videoSources = result.sources;
      
      // 重置播放位置
      this.currentPosition = 0;
      this.bufferProgress = 0;
      
    } catch (error) {
      Logger.error(TAG, `Failed to refresh live source: ${error}`);
      this.errorMessage = '刷新直播源失败';
    } finally {
      this.isLoading = false;
    }
  }
  
  /**
   * 清理播放器资源
   */
  @action
  public cleanup(): void {
    // 保存最后播放进度
    if (this.playType === PlayType.VOD && this.vodItem && this.currentPosition > 0) {
      this.savePlaybackProgress();
    }
    
    // 重置状态
    this.playerStatus = PlayerStatus.IDLE;
    this.isFullScreen = false;
    this.errorMessage = '';
    
    Logger.info(TAG, 'Player resources cleaned up');
  }
  
  /**
   * 重置播放器
   */
  @action
  public reset(): void {
    this.playType = null;
    this.vodItem = null;
    this.liveItem = null;
    this.currentSourceIndex = 0;
    this.currentEpisodeIndex = 0;
    this.playerStatus = PlayerStatus.IDLE;
    this.currentPosition = 0;
    this.duration = 0;
    this.bufferProgress = 0;
    this.isFullScreen = false;
    this.isFavorite = false;
    this.isMuted = false;
    this.volume = 1.0;
    this.playbackSpeed = 1.0;
    this.errorMessage = '';
    this.isLoading = false;
    this.videoSources = [];
    this.epgList = [];
    
    Logger.info(TAG, 'PlayerViewModel reset');
  }
}