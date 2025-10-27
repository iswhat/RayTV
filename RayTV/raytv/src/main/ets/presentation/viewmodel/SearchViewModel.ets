// SearchViewModel - 搜索页视图模型
import { observable, computed, action, makeObservable } from '@ohos:arkdata';
import Logger from '../../common/util/Logger';
import { Vod } from '../../data/bean/Vod';
import { Live } from '../../data/bean/Live';
import { SearchVodUseCase } from '../../domain/usecase/SearchVodUseCase';
import { SearchLiveUseCase } from '../../domain/usecase/SearchLiveUseCase';
import { LoadConfigUseCase } from '../../domain/usecase/LoadConfigUseCase';

const TAG = 'SearchViewModel';

/**
 * 搜索页面的视图模型
 */
export class SearchViewModel {
  // 状态数据
  @observable private searchKeyword: string = '';
  @observable private searchResults: {
    vodResults: Vod[];
    liveResults: Live[];
  } = { vodResults: [], liveResults: [] };
  @observable private hotKeywords: string[] = [];
  @observable private searchHistory: string[] = [];
  @observable private searchSuggestions: string[] = [];
  @observable private isSearching: boolean = false;
  @observable private isLoading: boolean = false;
  @observable private errorMessage: string = '';
  @observable private selectedTab: 'all' | 'vod' | 'live' = 'all';
  @observable private showSuggestions: boolean = false;
  
  // 用例
  private searchVodUseCase: SearchVodUseCase;
  private searchLiveUseCase: SearchLiveUseCase;
  private loadConfigUseCase: LoadConfigUseCase;
  
  constructor(
    searchVodUseCase: SearchVodUseCase,
    searchLiveUseCase: SearchLiveUseCase,
    loadConfigUseCase: LoadConfigUseCase
  ) {
    makeObservable(this);
    this.searchVodUseCase = searchVodUseCase;
    this.searchLiveUseCase = searchLiveUseCase;
    this.loadConfigUseCase = loadConfigUseCase;
  }
  
  // 计算属性
  @computed
  public get getSearchKeyword(): string {
    return this.searchKeyword;
  }
  
  @computed
  public get getSearchResults(): { vodResults: Vod[]; liveResults: Live[] } {
    return this.searchResults;
  }
  
  @computed
  public get getHotKeywords(): string[] {
    return this.hotKeywords;
  }
  
  @computed
  public get getSearchHistory(): string[] {
    return this.searchHistory;
  }
  
  @computed
  public get getSearchSuggestions(): string[] {
    return this.searchSuggestions;
  }
  
  @computed
  public get getIsSearching(): boolean {
    return this.isSearching;
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
  public get getSelectedTab(): 'all' | 'vod' | 'live' {
    return this.selectedTab;
  }
  
  @computed
  public get getShowSuggestions(): boolean {
    return this.showSuggestions;
  }
  
  @computed
  public get getDisplayResults() {
    switch (this.selectedTab) {
      case 'vod':
        return { items: this.searchResults.vodResults, type: 'vod' };
      case 'live':
        return { items: this.searchResults.liveResults, type: 'live' };
      default:
        // 全部标签下，合并显示，vod在前，live在后
        return { 
          items: [...this.searchResults.vodResults, ...this.searchResults.liveResults], 
          type: 'all' 
        };
    }
  }
  
  /**
   * 初始化搜索页面数据
   */
  @action
  public async initialize(): Promise<void> {
    try {
      this.isLoading = true;
      this.errorMessage = '';
      
      Logger.info(TAG, 'Initializing search view model');
      
      // 并行加载热门关键词和搜索历史
      await Promise.all([
        this.loadHotKeywords(),
        this.loadSearchHistory()
      ]);
      
    } catch (error) {
      Logger.error(TAG, `Failed to initialize search view model: ${error}`);
    } finally {
      this.isLoading = false;
    }
  }
  
  /**
   * 设置搜索关键词
   * @param keyword 搜索关键词
   */
  @action
  public setSearchKeyword(keyword: string): void {
    this.searchKeyword = keyword;
    
    // 如果关键词不为空，显示搜索建议
    if (keyword.trim().length > 0) {
      this.showSuggestions = true;
      this.loadSearchSuggestions(keyword);
    } else {
      this.showSuggestions = false;
      this.searchSuggestions = [];
    }
  }
  
  /**
   * 执行搜索
   */
  @action
  public async performSearch(): Promise<void> {
    const keyword = this.searchKeyword.trim();
    if (!keyword) {
      this.errorMessage = '请输入搜索关键词';
      return;
    }
    
    try {
      this.isSearching = true;
      this.errorMessage = '';
      this.showSuggestions = false;
      
      Logger.info(TAG, `Performing search for keyword: ${keyword}`);
      
      // 根据选中的标签执行对应搜索
      switch (this.selectedTab) {
        case 'vod':
          await this.searchVod(keyword);
          break;
        case 'live':
          await this.searchLive(keyword);
          break;
        default:
          // 全部搜索，并行执行
          await Promise.all([
            this.searchVod(keyword),
            this.searchLive(keyword)
          ]);
      }
      
    } catch (error) {
      Logger.error(TAG, `Failed to perform search: ${error}`);
      this.errorMessage = '搜索失败，请重试';
    } finally {
      this.isSearching = false;
    }
  }
  
  /**
   * 搜索点播内容
   * @param keyword 搜索关键词
   */
  @action
  private async searchVod(keyword: string): Promise<void> {
    try {
      const result = await this.searchVodUseCase.searchVod(keyword);
      this.searchResults.vodResults = result.items;
      
      Logger.info(TAG, `Found ${result.items.length} VOD results for: ${keyword}`);
    } catch (error) {
      Logger.error(TAG, `Failed to search VOD: ${error}`);
      this.searchResults.vodResults = [];
    }
  }
  
  /**
   * 搜索直播内容
   * @param keyword 搜索关键词
   */
  @action
  private async searchLive(keyword: string): Promise<void> {
    try {
      const result = await this.searchLiveUseCase.searchLive(keyword);
      this.searchResults.liveResults = result.channels;
      
      Logger.info(TAG, `Found ${result.channels.length} live results for: ${keyword}`);
    } catch (error) {
      Logger.error(TAG, `Failed to search live: ${error}`);
      this.searchResults.liveResults = [];
    }
  }
  
  /**
   * 加载热门关键词
   */
  @action
  private async loadHotKeywords(): Promise<void> {
    try {
      Logger.info(TAG, 'Loading hot keywords');
      
      // 根据当前选中的标签加载对应类型的热门关键词
      let keywords: string[] = [];
      
      if (this.selectedTab === 'all' || this.selectedTab === 'vod') {
        const vodKeywords = await this.searchVodUseCase.getHotKeywords(5);
        keywords = [...keywords, ...vodKeywords];
      }
      
      if (this.selectedTab === 'all' || this.selectedTab === 'live') {
        const liveKeywords = await this.searchLiveUseCase.getHotKeywords(5);
        keywords = [...new Set([...keywords, ...liveKeywords])]; // 去重
      }
      
      this.hotKeywords = keywords.slice(0, 10); // 最多显示10个
    } catch (error) {
      Logger.error(TAG, `Failed to load hot keywords: ${error}`);
      this.hotKeywords = [];
    }
  }
  
  /**
   * 加载搜索历史
   */
  @action
  private async loadSearchHistory(): Promise<void> {
    try {
      Logger.info(TAG, 'Loading search history');
      
      // 根据当前选中的标签加载对应类型的搜索历史
      let history: string[] = [];
      
      if (this.selectedTab === 'all' || this.selectedTab === 'vod') {
        const vodHistory = await this.searchVodUseCase.getSearchHistory(10);
        history = [...history, ...vodHistory];
      }
      
      if (this.selectedTab === 'all' || this.selectedTab === 'live') {
        const liveHistory = await this.searchLiveUseCase.getSearchHistory(10);
        history = [...new Set([...history, ...liveHistory])]; // 去重
      }
      
      this.searchHistory = history.slice(0, 15); // 最多显示15条
    } catch (error) {
      Logger.error(TAG, `Failed to load search history: ${error}`);
      this.searchHistory = [];
    }
  }
  
  /**
   * 加载搜索建议
   * @param keyword 搜索前缀
   */
  @action
  private async loadSearchSuggestions(keyword: string): Promise<void> {
    try {
      Logger.info(TAG, `Loading search suggestions for: ${keyword}`);
      
      // 根据当前选中的标签加载对应类型的搜索建议
      let suggestions: string[] = [];
      
      if (this.selectedTab === 'all' || this.selectedTab === 'vod') {
        const vodSuggestions = await this.searchVodUseCase.getSearchSuggestions(keyword, 3);
        suggestions = [...suggestions, ...vodSuggestions];
      }
      
      if (this.selectedTab === 'all' || this.selectedTab === 'live') {
        const liveSuggestions = await this.searchLiveUseCase.getSearchSuggestions(keyword, 3);
        suggestions = [...new Set([...suggestions, ...liveSuggestions])]; // 去重
      }
      
      this.searchSuggestions = suggestions.slice(0, 6); // 最多显示6个建议
    } catch (error) {
      Logger.error(TAG, `Failed to load search suggestions: ${error}`);
      this.searchSuggestions = [];
    }
  }
  
  /**
   * 切换标签页
   * @param tab 标签页类型
   */
  @action
  public switchTab(tab: 'all' | 'vod' | 'live'): void {
    this.selectedTab = tab;
    this.errorMessage = '';
    
    // 清空搜索结果
    this.searchResults = { vodResults: [], liveResults: [] };
    
    // 重新加载热门关键词和搜索历史
    this.loadHotKeywords();
    this.loadSearchHistory();
    
    Logger.info(TAG, `Switched to search tab: ${tab}`);
  }
  
  /**
   * 使用热门关键词搜索
   * @param keyword 热门关键词
   */
  @action
  public searchWithHotKeyword(keyword: string): void {
    this.searchKeyword = keyword;
    this.performSearch();
  }
  
  /**
   * 使用搜索建议搜索
   * @param suggestion 搜索建议
   */
  @action
  public searchWithSuggestion(suggestion: string): void {
    this.searchKeyword = suggestion;
    this.showSuggestions = false;
    this.performSearch();
  }
  
  /**
   * 清除搜索历史
   */
  @action
  public async clearSearchHistory(): Promise<void> {
    try {
      this.isLoading = true;
      
      Logger.info(TAG, 'Clearing search history');
      
      // 根据当前选中的标签清除对应类型的搜索历史
      if (this.selectedTab === 'all' || this.selectedTab === 'vod') {
        await this.searchVodUseCase.clearSearchHistory();
      }
      
      if (this.selectedTab === 'all' || this.selectedTab === 'live') {
        await this.searchLiveUseCase.clearSearchHistory();
      }
      
      this.searchHistory = [];
      
    } catch (error) {
      Logger.error(TAG, `Failed to clear search history: ${error}`);
      this.errorMessage = '清除搜索历史失败';
    } finally {
      this.isLoading = false;
    }
  }
  
  /**
   * 删除单条搜索历史
   * @param keyword 要删除的关键词
   */
  @action
  public async removeHistoryItem(keyword: string): Promise<void> {
    try {
      Logger.info(TAG, `Removing history item: ${keyword}`);
      
      // 尝试从两个类型的历史中删除
      await Promise.all([
        this.searchVodUseCase.removeFromHistory(keyword),
        this.searchLiveUseCase.removeFromHistory(keyword)
      ]);
      
      // 更新本地历史列表
      this.searchHistory = this.searchHistory.filter(item => item !== keyword);
      
    } catch (error) {
      Logger.error(TAG, `Failed to remove history item: ${error}`);
    }
  }
  
  /**
   * 清除搜索
   */
  @action
  public clearSearch(): void {
    this.searchKeyword = '';
    this.searchResults = { vodResults: [], liveResults: [] };
    this.searchSuggestions = [];
    this.showSuggestions = false;
    this.errorMessage = '';
    
    Logger.info(TAG, 'Search cleared');
  }
  
  /**
   * 刷新数据
   */
  @action
  public async refresh(): Promise<void> {
    await this.initialize();
  }
  
  /**
   * 重置状态
   */
  @action
  public reset(): void {
    this.searchKeyword = '';
    this.searchResults = { vodResults: [], liveResults: [] };
    this.hotKeywords = [];
    this.searchHistory = [];
    this.searchSuggestions = [];
    this.isSearching = false;
    this.isLoading = false;
    this.errorMessage = '';
    this.selectedTab = 'all';
    this.showSuggestions = false;
    
    Logger.info(TAG, 'ViewModel reset');
  }
}