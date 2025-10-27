// DetailViewModel - 详情页视图模型
import { observable, computed, action, makeObservable } from '@ohos:arkdata';
import Logger from '../../common/util/Logger';
import { Vod } from '../../data/bean/Vod';
import { PlayVodUseCase } from '../../domain/usecase/PlayVodUseCase';
import { LoadConfigUseCase } from '../../domain/usecase/LoadConfigUseCase';

const TAG = 'DetailViewModel';

/**
 * 详情页面的视图模型
 */
export class DetailViewModel {
  // 状态数据
  @observable private vodDetail: Vod | null = null;
  @observable private isLoading: boolean = false;
  @observable private errorMessage: string = '';
  @observable private isCollected: boolean = false;
  @observable private selectedSourceIndex: number = 0;
  @observable private selectedEpisodeIndex: number = 0;
  @observable private lastPlayPosition: number = 0;
  
  // 用例
  private playVodUseCase: PlayVodUseCase;
  private loadConfigUseCase: LoadConfigUseCase;
  
  constructor(
    playVodUseCase: PlayVodUseCase,
    loadConfigUseCase: LoadConfigUseCase
  ) {
    makeObservable(this);
    this.playVodUseCase = playVodUseCase;
    this.loadConfigUseCase = loadConfigUseCase;
  }
  
  // 计算属性
  @computed
  public get getVodDetail(): Vod | null {
    return this.vodDetail;
  }
  
  @computed
  public get getIsLoading(): boolean {
    return this.isLoading;
  }
  
  @computed
  public get getErrorMessage(): string {
    return this.errorMessage;
  }
  
  @computed
  public get getIsCollected(): boolean {
    return this.isCollected;
  }
  
  @computed
  public get getSelectedSourceIndex(): number {
    return this.selectedSourceIndex;
  }
  
  @computed
  public get getSelectedEpisodeIndex(): number {
    return this.selectedEpisodeIndex;
  }
  
  @computed
  public get getLastPlayPosition(): number {
    return this.lastPlayPosition;
  }
  
  @computed
  public get getCurrentEpisode() {
    if (!this.vodDetail || !this.vodDetail.episodeList) {
      return null;
    }
    return this.vodDetail.episodeList[this.selectedEpisodeIndex] || null;
  }
  
  @computed
  public get getCurrentSource() {
    const episode = this.getCurrentEpisode;
    if (!episode || !episode.sourceList) {
      return null;
    }
    return episode.sourceList[this.selectedSourceIndex] || null;
  }
  
  /**
   * 加载内容详情
   * @param vodId 内容ID
   * @param sourceKey 数据源标识
   */
  @action
  public async loadVodDetail(vodId: string, sourceKey: string): Promise<void> {
    try {
      this.isLoading = true;
      this.errorMessage = '';
      
      Logger.info(TAG, `Loading detail for vodId: ${vodId}, sourceKey: ${sourceKey}`);
      
      // 加载内容详情
      const detail = await this.playVodUseCase.loadVodDetail(vodId, sourceKey);
      
      // 更新详情数据
      this.vodDetail = detail;
      
      // 检查收藏状态
      this.isCollected = await this.playVodUseCase.isVodCollected(vodId, sourceKey);
      
      // 获取最后播放进度
      const history = await this.playVodUseCase.getPlayHistory(vodId, sourceKey);
      if (history) {
        this.lastPlayPosition = history.position;
        
        // 如果有上次播放的剧集信息，尝试定位到该剧集
        if (history.episodeName && detail.episodeList) {
          const episodeIndex = detail.episodeList.findIndex(
            ep => ep.name === history.episodeName
          );
          if (episodeIndex >= 0) {
            this.selectedEpisodeIndex = episodeIndex;
          }
        }
      }
      
    } catch (error) {
      Logger.error(TAG, `Failed to load vod detail: ${error}`);
      this.errorMessage = error.message || '加载详情失败';
    } finally {
      this.isLoading = false;
    }
  }
  
  /**
   * 切换收藏状态
   */
  @action
  public async toggleCollection(): Promise<void> {
    if (!this.vodDetail) return;
    
    try {
      const newCollectionStatus = await this.playVodUseCase.toggleCollection(this.vodDetail);
      this.isCollected = newCollectionStatus;
      
      Logger.info(TAG, `${newCollectionStatus ? 'Collected' : 'Uncollected'} vod: ${this.vodDetail.name}`);
    } catch (error) {
      Logger.error(TAG, `Failed to toggle collection: ${error}`);
      this.errorMessage = error.message || '操作收藏失败';
    }
  }
  
  /**
   * 选择视频源
   * @param sourceIndex 视频源索引
   */
  @action
  public selectVideoSource(sourceIndex: number): void {
    if (!this.vodDetail || !this.vodDetail.episodeList) return;
    
    // 验证索引有效性
    const currentEpisode = this.vodDetail.episodeList[this.selectedEpisodeIndex];
    if (currentEpisode && currentEpisode.sourceList && 
        sourceIndex >= 0 && sourceIndex < currentEpisode.sourceList.length) {
      this.selectedSourceIndex = sourceIndex;
      Logger.info(TAG, `Selected video source index: ${sourceIndex}`);
    }
  }
  
  /**
   * 选择剧集
   * @param episodeIndex 剧集索引
   */
  @action
  public async selectEpisode(episodeIndex: number): Promise<void> {
    if (!this.vodDetail || !this.vodDetail.episodeList) return;
    
    // 验证索引有效性
    if (episodeIndex >= 0 && episodeIndex < this.vodDetail.episodeList.length) {
      this.selectedEpisodeIndex = episodeIndex;
      
      // 重置视频源索引
      this.selectedSourceIndex = 0;
      
      Logger.info(TAG, `Selected episode index: ${episodeIndex}`);
      
      // 获取该剧集的播放历史
      const episode = this.vodDetail.episodeList[episodeIndex];
      const history = await this.playVodUseCase.getPlayHistory(
        this.vodDetail.id,
        this.vodDetail.sourceKey,
        episode.name
      );
      
      if (history) {
        this.lastPlayPosition = history.position;
      } else {
        this.lastPlayPosition = 0;
      }
    }
  }
  
  /**
   * 准备播放
   * @returns 准备好的播放信息
   */
  @action
  public async preparePlayback(): Promise<any> {
    if (!this.vodDetail || !this.getCurrentEpisode || !this.getCurrentSource) {
      throw new Error('No valid episode or source selected');
    }
    
    try {
      this.isLoading = true;
      
      Logger.info(TAG, `Preparing playback for episode: ${this.getCurrentEpisode.name}`);
      
      // 准备播放
      const playInfo = await this.playVodUseCase.preparePlayback(
        this.vodDetail,
        this.selectedEpisodeIndex,
        this.selectedSourceIndex
      );
      
      // 更新播放历史
      await this.playVodUseCase.updatePlayHistory(
        this.vodDetail.id,
        this.vodDetail.sourceKey,
        this.getCurrentEpisode.name,
        this.lastPlayPosition
      );
      
      return playInfo;
    } catch (error) {
      Logger.error(TAG, `Failed to prepare playback: ${error}`);
      this.errorMessage = error.message || '准备播放失败';
      throw error;
    } finally {
      this.isLoading = false;
    }
  }
  
  /**
   * 分享内容
   * @returns 分享信息
   */
  @action
  public async getShareInfo(): Promise<{title: string; content: string; url: string}> {
    if (!this.vodDetail) {
      throw new Error('No content to share');
    }
    
    return {
      title: this.vodDetail.name,
      content: `我正在观看《${this.vodDetail.name}》${this.vodDetail.year || ''} ${this.vodDetail.score ? `评分:${this.vodDetail.score}` : ''}`,
      url: `${this.vodDetail.url || ''}`
    };
  }
  
  /**
   * 重置状态
   */
  @action
  public reset(): void {
    this.vodDetail = null;
    this.isLoading = false;
    this.errorMessage = '';
    this.isCollected = false;
    this.selectedSourceIndex = 0;
    this.selectedEpisodeIndex = 0;
    this.lastPlayPosition = 0;
    
    Logger.info(TAG, 'ViewModel reset');
  }
  
  /**
   * 刷新数据
   */
  @action
  public async refresh(): Promise<void> {
    if (!this.vodDetail) return;
    
    await this.loadVodDetail(this.vodDetail.id, this.vodDetail.sourceKey);
  }
  
  /**
   * 获取相关推荐
   * @param limit 限制数量
   */
  @action
  public async getRecommendations(limit: number = 10): Promise<Vod[]> {
    if (!this.vodDetail) {
      return [];
    }
    
    try {
      Logger.info(TAG, 'Loading recommendations');
      
      // 基于类型和标签获取推荐
      const recommendations = await this.playVodUseCase.getRecommendations(
        this.vodDetail.type || '',
        this.vodDetail.tag || '',
        limit
      );
      
      // 过滤掉当前正在查看的内容
      return recommendations.filter(vod => vod.id !== this.vodDetail!.id);
    } catch (error) {
      Logger.error(TAG, `Failed to load recommendations: ${error}`);
      return [];
    }
  }
}