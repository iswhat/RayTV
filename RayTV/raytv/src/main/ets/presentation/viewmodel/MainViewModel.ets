// MainViewModel - 首页视图模型
import { observable, computed, action, makeObservable } from '@ohos:arkdata';
import Logger from '../../common/util/Logger';
import { Vod } from '../../data/bean/Vod';
import { Live } from '../../data/bean/Live';
import { History } from '../../data/bean/History';
import { Site } from '../../data/bean/Site';
import { PlayVodUseCase } from '../../domain/usecase/PlayVodUseCase';
import { PlayLiveUseCase } from '../../domain/usecase/PlayLiveUseCase';
import { LoadConfigUseCase } from '../../domain/usecase/LoadConfigUseCase';
import { SiteRepository } from '../../data/repository/SiteRepository';
import { HistoryRepository } from '../../data/repository/HistoryRepository';

const TAG = 'MainViewModel';

/**
 * 首页的视图模型
 */
export class MainViewModel {
  // 状态数据
  @observable private recentHistory: History[] = [];
  @observable private popularVod: Vod[] = [];
  @observable private liveGroups: { name: string; count: number }[] = [];
  @observable private favoriteLiveChannels: Live[] = [];
  @observable private enabledSites: Site[] = [];
  @observable private isLoading: boolean = false;
  @observable private errorMessage: string = '';
  @observable private currentTab: 'recommend' | 'history' | 'live' = 'recommend';
  
  // 用例和仓库
  private playVodUseCase: PlayVodUseCase;
  private playLiveUseCase: PlayLiveUseCase;
  private loadConfigUseCase: LoadConfigUseCase;
  private siteRepository: SiteRepository;
  private historyRepository: HistoryRepository;
  
  constructor(
    playVodUseCase: PlayVodUseCase,
    playLiveUseCase: PlayLiveUseCase,
    loadConfigUseCase: LoadConfigUseCase,
    siteRepository: SiteRepository,
    historyRepository: HistoryRepository
  ) {
    makeObservable(this);
    this.playVodUseCase = playVodUseCase;
    this.playLiveUseCase = playLiveUseCase;
    this.loadConfigUseCase = loadConfigUseCase;
    this.siteRepository = siteRepository;
    this.historyRepository = historyRepository;
  }
  
  // 计算属性
  @computed
  public get getRecentHistory(): History[] {
    return this.recentHistory;
  }
  
  @computed
  public get getPopularVod(): Vod[] {
    return this.popularVod;
  }
  
  @computed
  public get getLiveGroups(): { name: string; count: number }[] {
    return this.liveGroups;
  }
  
  @computed
  public get getFavoriteLiveChannels(): Live[] {
    return this.favoriteLiveChannels;
  }
  
  @computed
  public get getEnabledSites(): Site[] {
    return this.enabledSites;
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
  public get getCurrentTab(): 'recommend' | 'history' | 'live' {
    return this.currentTab;
  }
  
  /**
   * 初始化首页数据
   */
  @action
  public async initialize(): Promise<void> {
    try {
      this.isLoading = true;
      this.errorMessage = '';
      
      Logger.info(TAG, 'Initializing main view model');
      
      // 并行加载各种数据
      await Promise.all([
        this.loadRecentHistory(),
        this.loadPopularVod(),
        this.loadLiveGroups(),
        this.loadFavoriteLiveChannels(),
        this.loadEnabledSites()
      ]);
      
    } catch (error) {
      Logger.error(TAG, `Failed to initialize main view model: ${error}`);
      this.errorMessage = '初始化首页数据失败';
    } finally {
      this.isLoading = false;
    }
  }
  
  /**
   * 切换标签页
   * @param tab 标签页类型
   */
  @action
  public switchTab(tab: 'recommend' | 'history' | 'live'): void {
    this.currentTab = tab;
    Logger.info(TAG, `Switched to tab: ${tab}`);
    
    // 根据切换的标签页加载对应数据
    this.loadDataForCurrentTab();
  }
  
  /**
   * 加载当前标签页的数据
   */
  @action
  private async loadDataForCurrentTab(): Promise<void> {
    try {
      this.isLoading = true;
      
      switch (this.currentTab) {
        case 'recommend':
          await this.loadPopularVod();
          break;
        case 'history':
          await this.loadRecentHistory();
          break;
        case 'live':
          await Promise.all([
            this.loadLiveGroups(),
            this.loadFavoriteLiveChannels()
          ]);
          break;
      }
    } catch (error) {
      Logger.error(TAG, `Failed to load data for tab ${this.currentTab}: ${error}`);
    } finally {
      this.isLoading = false;
    }
  }
  
  /**
   * 加载最近观看历史
   */
  @action
  private async loadRecentHistory(): Promise<void> {
    try {
      Logger.info(TAG, 'Loading recent history');
      
      // 获取最近10条观看记录
      const history = await this.historyRepository.getRecentHistory(10);
      this.recentHistory = history;
      
    } catch (error) {
      Logger.error(TAG, `Failed to load recent history: ${error}`);
      this.recentHistory = [];
    }
  }
  
  /**
   * 加载热门点播内容
   */
  @action
  private async loadPopularVod(): Promise<void> {
    try {
      Logger.info(TAG, 'Loading popular VOD content');
      
      // 获取热门内容
      const popularContent = await this.playVodUseCase.getPopularContent(20);
      this.popularVod = popularContent;
      
    } catch (error) {
      Logger.error(TAG, `Failed to load popular VOD: ${error}`);
      this.popularVod = [];
    }
  }
  
  /**
   * 加载直播频道分组
   */
  @action
  private async loadLiveGroups(): Promise<void> {
    try {
      Logger.info(TAG, 'Loading live groups');
      
      const groups = await this.playLiveUseCase.getLiveGroups();
      this.liveGroups = groups;
      
    } catch (error) {
      Logger.error(TAG, `Failed to load live groups: ${error}`);
      this.liveGroups = [];
    }
  }
  
  /**
   * 加载收藏的直播频道
   */
  @action
  private async loadFavoriteLiveChannels(): Promise<void> {
    try {
      Logger.info(TAG, 'Loading favorite live channels');
      
      // 获取收藏的直播频道（这里需要在PlayLiveUseCase中实现对应的方法）
      // 暂时返回空数组，后续实现
      this.favoriteLiveChannels = [];
      
    } catch (error) {
      Logger.error(TAG, `Failed to load favorite live channels: ${error}`);
      this.favoriteLiveChannels = [];
    }
  }
  
  /**
   * 加载启用的站点
   */
  @action
  private async loadEnabledSites(): Promise<void> {
    try {
      Logger.info(TAG, 'Loading enabled sites');
      
      const sites = await this.siteRepository.getEnabled();
      this.enabledSites = sites;
      
    } catch (error) {
      Logger.error(TAG, `Failed to load enabled sites: ${error}`);
      this.enabledSites = [];
    }
  }
  
  /**
   * 刷新数据
   */
  @action
  public async refresh(): Promise<void> {
    await this.initialize();
  }
  
  /**
   * 清除错误信息
   */
  @action
  public clearError(): void {
    this.errorMessage = '';
  }
  
  /**
   * 加载更多推荐内容
   */
  @action
  public async loadMoreRecommendations(): Promise<void> {
    if (this.currentTab !== 'recommend' || this.isLoading) return;
    
    try {
      this.isLoading = true;
      
      Logger.info(TAG, 'Loading more recommendations');
      
      const currentCount = this.popularVod.length;
      const moreContent = await this.playVodUseCase.getPopularContent(
        currentCount + 20,
        currentCount
      );
      
      if (moreContent.length > 0) {
        this.popularVod = [...this.popularVod, ...moreContent];
      }
      
    } catch (error) {
      Logger.error(TAG, `Failed to load more recommendations: ${error}`);
    } finally {
      this.isLoading = false;
    }
  }
  
  /**
   * 检查是否有更多数据可加载
   */
  @computed
  public get hasMoreData(): boolean {
    // 根据当前标签页和数据量判断
    return this.popularVod.length >= 20;
  }
  
  /**
   * 获取站点统计信息
   */
  @computed
  public get getSiteStats(): { total: number; enabled: number } {
    return {
      total: this.enabledSites.length,
      enabled: this.enabledSites.filter(site => site.enabled).length
    };
  }
  
  /**
   * 重置状态
   */
  @action
  public reset(): void {
    this.recentHistory = [];
    this.popularVod = [];
    this.liveGroups = [];
    this.favoriteLiveChannels = [];
    this.enabledSites = [];
    this.isLoading = false;
    this.errorMessage = '';
    this.currentTab = 'recommend';
    
    Logger.info(TAG, 'ViewModel reset');
  }
}