
import { Router } from '@ohos.router';
import Logger from '../common/util/Logger';
import { MediaItem } from '../data/bean/MediaItem';
import { SearchHistoryItem } from '../../data/repository/SearchHistoryRepository';
import { mediaService } from '../service/media/MediaService';
import { SearchType, SearchFilter, SearchSort } from '../data/dto/SearchDto';

/**
 * 搜索页面组件
 * 实现媒体搜索功能，包括搜索输入、结果展示、历史搜索等
 */
@Component
struct SearchPage {
  private readonly TAG: string = 'SearchPage';
  
  // 状态管理
  @State searchQuery: string = '';
  @State searchResults: MediaItem[] = [];
  @State hotKeywords: string[] = [];
  @State searchHistory: SearchHistoryItem[] = [];
  @State isLoading: boolean = false;
  @State isSearching: boolean = false;
  @State errorMessage: string = '';
  @State currentPage: number = 1;
  @State hasMoreResults: boolean = true;
  @State showHistory: boolean = true;
  @State displayMode: 'list' | 'grid' = 'list'; // 显示模式：列表或网格
  @State showFilterPanel: boolean = false; // 是否显示筛选面板
  @State filters: SearchFilter = {}; // 当前筛选条件
  
  // 分页配置
  private pageSize: number = 20;
  private searchDebounceTimer: number | null = null;
  
  /**
   * 页面加载时调用
   */
  aboutToAppear(): void {
    Logger.info(this.TAG, 'SearchPage appeared');
    
    // 获取路由参数中的搜索词
    const params = Router.getParams();
    if (params?.['query']) {
      this.searchQuery = params['query'];
      this.performSearch();
    } else {
      // 加载热门搜索词
      this.loadHotKeywords();
    }
    
    // 加载搜索历史
    this.loadSearchHistory();
  }
  
  /**
   * 页面卸载时调用
   */
  aboutToDisappear(): void {
    Logger.info(this.TAG, 'SearchPage disappeared');
    
    // 清理定时器
    if (this.searchDebounceTimer) {
      clearTimeout(this.searchDebounceTimer);
    }
  }
  
  /**
   * 加载热门搜索词
   */
  private loadHotKeywords(): void {
    try {
      mediaService.getHotSearchKeywords(10).then((data) => {
        this.hotKeywords = data;
        Logger.info(this.TAG, `Loaded ${this.hotKeywords.length} hot keywords`);
      });
    } catch (error) {
      Logger.error(this.TAG, `Failed to load hot keywords: ${error}`);
      // 使用默认热门关键词
      this.hotKeywords = ['热门电影', '最新剧集', '经典动漫', '科幻大片', '爱情喜剧'];
    }
  }
  
  /**
   * 加载搜索历史
   */
  private loadSearchHistory(): void {
    try {
      // 这里应该从本地存储中读取搜索历史
      // 暂时使用模拟数据
      const history = ['复仇者联盟', '海贼王', '星际穿越'];
      this.searchHistory = history;
      Logger.info(this.TAG, `Loaded ${this.searchHistory.length} search history items`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to load search history: ${error}`);
      this.searchHistory = [];
    }
  }
  
  /**
   * 保存搜索历史
   */
  private saveSearchHistory(keyword: string): void {
    try {
      // 去重并限制数量
      let history = this.searchHistory.filter(item => item !== keyword);
      history.unshift(keyword);
      history = history.slice(0, 10); // 最多保存10条
      
      this.searchHistory = history;
      
      // 这里应该保存到本地存储
      Logger.info(this.TAG, `Search history saved: ${keyword}`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to save search history: ${error}`);
    }
  }
  
  /**
   * 清除搜索历史
   */
  private clearSearchHistory(): void {
    try {
      this.searchHistory = [];
      // 这里应该清除本地存储中的搜索历史
      Logger.info(this.TAG, 'Search history cleared');
    } catch (error) {
      Logger.error(this.TAG, `Failed to clear search history: ${error}`);
    }
  }
  
  /**
   * 处理搜索输入变化
   */
  private handleSearchInputChange(value: string): void {
    this.searchQuery = value;
    
    // 防抖处理
    if (this.searchDebounceTimer) {
      clearTimeout(this.searchDebounceTimer);
    }
    
    // 输入停止300ms后执行搜索
    this.searchDebounceTimer = setTimeout(() => {
      if (value.trim().length >= 2) {
        this.performSearch();
      } else if (value.trim().length === 0) {
        this.resetSearchState();
      }
    }, 300);
  }
  
  /**
   * 执行搜索
   */
  private performSearch(): void {
    const query = this.searchQuery.trim();
    if (!query) return;
    
    this.isSearching = true;
    this.isLoading = true;
    this.errorMessage = '';
    this.showHistory = false;
    this.currentPage = 1;
    
    try {
      // 保存搜索历史
      this.saveSearchHistory(query);
      
      // 执行搜索，传递筛选条件
      Logger.info(this.TAG, `Searching for: ${query} with filters:`, JSON.stringify(this.filters));
      
      // 构建搜索参数，包含筛选条件
      const searchParams = {
        keyword: query,
        type: SearchType.All,
        page: this.currentPage,
        pageSize: this.pageSize,
        ...this.filters // 合并筛选条件
      };
      
      mediaService.searchMedia(searchParams).then((result) => {
        // 处理搜索结果
        this.searchResults = result.items || [];
        this.hasMoreResults = result.hasMore || false;
        
        Logger.info(this.TAG, `Search completed, found ${this.searchResults.length} results`);
        this.isLoading = false;
        this.isSearching = false;
      }).catch((error) => {
        Logger.error(this.TAG, `Search failed: ${error}`);
        this.errorMessage = '搜索失败，请稍后重试';
        this.searchResults = [];
        this.hasMoreResults = false;
        this.isLoading = false;
        this.isSearching = false;
      });
    } catch (error) {
      Logger.error(this.TAG, `Search failed: ${error}`);
      this.errorMessage = '搜索失败，请稍后重试';
      this.searchResults = [];
      this.hasMoreResults = false;
      this.isLoading = false;
      this.isSearching = false;
    }
  }
  
  /**
   * 加载更多搜索结果
   */
  private loadMoreResults(): void {
    if (!this.hasMoreResults || this.isLoading || !this.searchQuery.trim()) return;
    
    this.isLoading = true;
    this.currentPage++;
    
    try {
      const query = this.searchQuery.trim();
      Logger.info(this.TAG, `Loading more results for: ${query}, page ${this.currentPage}`);
      
      // 构建搜索参数，包含筛选条件
      const searchParams = {
        keyword: query,
        type: SearchType.All,
        page: this.currentPage,
        pageSize: this.pageSize,
        ...this.filters // 合并筛选条件
      };
      
      mediaService.searchMedia(searchParams).then((result) => {
        if (result && result.items && result.items.length > 0) {
          this.searchResults = [...this.searchResults, ...result.items];
          this.hasMoreResults = result.hasMore || false;
        } else {
          this.hasMoreResults = false;
        }
        this.isLoading = false;
      }).catch((error) => {
        Logger.error(this.TAG, `Failed to load more results: ${error}`);
        this.errorMessage = '加载更多结果失败';
        this.isLoading = false;
      });
    } catch (error) {
      Logger.error(this.TAG, `Failed to load more results: ${error}`);
      this.errorMessage = '加载更多结果失败';
      this.isLoading = false;
    }
  }
  
  /**
   * 重置搜索状态
   */
  private resetSearchState(): void {
    this.searchResults = [];
    this.showHistory = true;
    this.errorMessage = '';
    this.currentPage = 1;
    this.hasMoreResults = true;
  }
  
  /**
   * 处理关键词点击
   */
  private handleKeywordClick(keyword: string): void {
    this.searchQuery = keyword;
    this.performSearch();
  }
  
  /**
   * 处理搜索结果项点击
   */
  private handleSearchResultClick(media: MediaItem): void {
    Logger.info(this.TAG, `Search result clicked: ${media.title}`);
    // 跳转到详情页
    Router.push({
      url: 'pages/MediaDetailPage',
      params: {
        mediaId: media.id,
        siteKey: media.siteKey
      }
    });
  }
  
  /**
   * 处理清除按钮点击
   */
  private handleClearInput(): void {
    this.searchQuery = '';
    this.resetSearchState();
  }
  
  /**
   * 处理返回
   */
  private handleBack(): void {
    Router.back();
  }
  
  /**
   * 渲染搜索输入框
   */
  @Builder
  private renderSearchInput(): void {
    Stack.create();
    Stack.className("search-input-container");
    Button.create();
    Button.className("back-button");
    Button.onClick(this.handleBack);
    Text.create();
    Text.content("←");
    Text.pop();
    Button.pop();
    Flex.create();
    Flex.className("search-input-wrapper");
    Text.create();
    Text.className("search-icon");
    Text.content("🔍");
    Text.pop();
    TextInput.create();
    TextInput.className("search-input");
    TextInput.value(this.searchQuery);
    TextInput.onChange(this.handleSearchInputChange);
    TextInput.onSubmit(this.performSearch);
    TextInput.placeholder("搜索电影、电视剧、动漫...");
    TextInput.enterKeyType("search");
    TextInput.autoFocus(true);
    TextInput.pop();
    if (this.searchQuery) {
      Button.create();
      Button.className("clear-button");
      Button.onClick(this.handleClearInput);
      Text.create();
      Text.content("✕");
      Text.pop();
      Button.pop();
    }
    Flex.pop();
    Button.create();
    Button.className("search-button");
    Button.onClick(this.performSearch);
    Text.create();
    Text.content("搜索");
    Text.pop();
    Button.pop();
    Stack.pop();
  }
  
  /**
   * 渲染热门搜索
   */
  @Builder
  private renderHotKeywords(): void {
    Stack.create();
    Stack.className("hot-keywords-section");
    Flex.create();
    Flex.className("section-header");
    Text.create();
    Text.className("section-title");
    Text.content("热门搜索");
    Text.pop();
    Flex.pop();
    Flex.create();
    Flex.className("keywords-container");
    Flex.wrap("wrap");
    this.hotKeywords.forEach((keyword, index) => {
      Tag.create();
      Tag.key(`hot-${index}`);
      Tag.className("keyword-tag hot");
      Tag.onClick(() => this.handleKeywordClick(keyword));
      Text.create();
      Text.className("keyword-rank");
      Text.content((index + 1).toString());
      Text.pop();
      Text.create();
      Text.content(keyword);
      Text.pop();
      Tag.pop();
    });
    Flex.pop();
    Stack.pop();
  }
  
  /**
   * 渲染搜索历史
   */
  @Builder
  private renderSearchHistory(): void {
    if (this.searchHistory.length === 0) return;
    
    Stack.create();
    Stack.className("search-history-section");
    Flex.create();
    Flex.className("section-header");
    Text.create();
    Text.className("section-title");
    Text.content("搜索历史");
    Text.pop();
    Button.create();
    Button.className("clear-history-button");
    Button.onClick(this.clearSearchHistory);
    Text.create();
    Text.content("清除");
    Text.pop();
    Button.pop();
    Flex.pop();
    Flex.create();
    Flex.className("keywords-container");
    Flex.wrap("wrap");
    this.searchHistory.forEach((keyword, index) => {
      Tag.create();
      Tag.key(`history-${index}`);
      Tag.className("keyword-tag history");
      Tag.onClick(() => this.handleKeywordClick(keyword));
      Text.create();
      Text.className("history-icon");
      Text.content("🕐");
      Text.pop();
      Text.create();
      Text.content(keyword);
      Text.pop();
      Tag.pop();
    });
    Flex.pop();
    Stack.pop();
  }
  
  /**
   * 渲染搜索结果项
   */
  @Builder
  private renderSearchResultItem(media: MediaItem): void {
    ListItem.create();
    ListItem.onClick(() => this.handleSearchResultClick(media));
    Flex.create();
    Flex.className("search-result-item");
    Image.create();
    Image.src(media.coverUrl || "https://via.placeholder.com/100x150?text=No+Image");
    Image.className("result-cover");
    Image.objectFit("cover");
    Image.pop();
    Flex.create();
    Flex.className("result-info");
    Flex.direction("column");
    Text.create();
    Text.className("result-title");
    Text.numberOfLines(2);
    Text.content(media.title);
    Text.pop();
    Flex.create();
    Flex.className("result-meta");
    if (media.year) {
      Tag.create();
      Tag.className("meta-tag");
      Text.create();
      Text.content(media.year);
      Text.pop();
      Tag.pop();
    }
    if (media.type) {
      Tag.create();
      Tag.className("meta-tag");
      Text.create();
      Text.content(media.type);
      Text.pop();
      Tag.pop();
    }
    if (media.score) {
      Tag.create();
      Tag.className("meta-tag score");
      Text.create();
      Text.content(media.score);
      Text.pop();
      Tag.pop();
    }
    Flex.pop();
    if (media.description) {
      Text.create();
      Text.className("result-description");
      Text.numberOfLines(2);
      Text.content(media.description);
      Text.pop();
    }
    if (media.directors && media.directors.length > 0) {
      Text.create();
      Text.className("result-directors");
      Text.numberOfLines(1);
      Text.content(`导演: ${media.directors.slice(0, 3).join(', ')}`);
      Text.pop();
    }
    if (media.actors && media.actors.length > 0) {
      Text.create();
      Text.className("result-actors");
      Text.numberOfLines(1);
      Text.content(`主演: ${media.actors.slice(0, 3).join(', ')}`);
      Text.pop();
    }
    Flex.pop();
    Flex.pop();
    ListItem.pop();
  }
  
  /**
   * 渲染显示模式切换按钮
   */
  @Builder
  private renderDisplayModeToggle(): void {
    Button.create();
    Button.className("display-mode-toggle");
    Button.onClick(this.toggleDisplayMode);
    Button.type("circle");
    Button.size("small");
    Text.create();
    Text.content(this.displayMode === 'list' ? '网格' : '列表');
    Text.pop();
    Button.pop();
  }
  
  /**
   * 渲染筛选按钮
   */
  @Builder
  private renderFilterButton(): void {
    Button.create();
    Button.className("filter-button");
    Button.onClick(this.toggleFilterPanel);
    Button.type("text");
    Button.size("small");
    Text.create();
    Text.content("筛选");
    Text.pop();
    Button.pop();
  }
  
  /**
   * 渲染筛选面板
   */
  @Builder
  private renderFilterPanel(): void {
    if (!this.showFilterPanel) return;
    
    Stack.create();
    Stack.className("filter-panel-overlay");
    Stack.onClick(this.toggleFilterPanel);
    Stack.create();
    Stack.className("filter-panel");
    Stack.onClick((e) => e.stopPropagation());
    Stack.create();
    Stack.className("filter-header");
    Text.create();
    Text.className("filter-title");
    Text.content("筛选条件");
    Text.pop();
    Button.create();
    Button.onClick(this.toggleFilterPanel);
    Button.type("text");
    Button.size("small");
    Button.pop();
    Stack.pop();
    
    ScrollView.create();
    ScrollView.className("filter-content");
    // 媒体类型筛选
    Stack.create();
    Stack.className("filter-section");
    Text.create();
    Text.className("filter-section-title");
    Text.content("媒体类型");
    Text.pop();
    Flex.create();
    Flex.className("filter-options");
    CheckboxGroup.create();
    Checkbox.create();
    Checkbox.value("movie");
    Checkbox.onChange((value) => this.updateMediaTypeFilter('movie', value));
    Text.create();
    Text.content("电影");
    Text.pop();
    Checkbox.pop();
    Checkbox.create();
    Checkbox.value("tv");
    Checkbox.onChange((value) => this.updateMediaTypeFilter('tv', value));
    Text.create();
    Text.content("电视剧");
    Text.pop();
    Checkbox.pop();
    Checkbox.create();
    Checkbox.value("anime");
    Checkbox.onChange((value) => this.updateMediaTypeFilter('anime', value));
    Text.create();
    Text.content("动漫");
    Text.pop();
    Checkbox.pop();
    Checkbox.create();
    Checkbox.value("variety");
    Checkbox.onChange((value) => this.updateMediaTypeFilter('variety', value));
    Text.create();
    Text.content("综艺");
    Text.pop();
    Checkbox.pop();
    CheckboxGroup.pop();
    Flex.pop();
    Stack.pop();
    
    // 排序方式
    Stack.create();
    Stack.className("filter-section");
    Text.create();
    Text.className("filter-section-title");
    Text.content("排序方式");
    Text.pop();
    RadioGroup.create();
    RadioGroup.onChange((value) => {
      this.filters.sortBy = value;
    });
    Radio.create();
    Radio.value("time");
    Text.create();
    Text.content("最新");
    Text.pop();
    Radio.pop();
    Radio.create();
    Radio.value("score");
    Text.create();
    Text.content("评分");
    Text.pop();
    Radio.pop();
    Radio.create();
    Radio.value("hot");
    Text.create();
    Text.content("热度");
    Text.pop();
    Radio.pop();
    RadioGroup.pop();
    Stack.pop();
    ScrollView.pop();
    
    Stack.create();
    Stack.className("filter-actions");
    Button.create();
    Button.onClick(this.resetFilters);
    Button.type("text");
    Text.create();
    Text.content("重置");
    Text.pop();
    Button.pop();
    Button.create();
    Button.onClick(this.applyFilters);
    Button.type("capsule");
    Text.create();
    Text.content("应用筛选");
    Text.pop();
    Button.pop();
    Stack.pop();
    Stack.pop();
    Stack.pop();
  }

  /**
   * 更新媒体类型筛选
   */
  private updateMediaTypeFilter(type: string, checked: boolean): void {
    if (!this.filters.types) {
      this.filters.types = [];
    }
    
    if (checked) {
      if (!this.filters.types.includes(type)) {
        this.filters.types.push(type);
      }
    } else {
      const index = this.filters.types.indexOf(type);
      if (index > -1) {
        this.filters.types.splice(index, 1);
      }
    }
  }

  /**
   * 渲染网格模式的搜索结果项
   */
  @Builder
  private renderGridItem(item: MediaItem): void {
    GridItem.create();
    GridItem.className("grid-item");
    GridItem.onClick(() => this.handleSearchResultClick(item));
    Stack.create();
    Stack.className("grid-item-content");
    Image.create();
    Image.className("grid-item-image");
    Image.src(item.coverUrl || item.posterUrl || "https://via.placeholder.com/100x150?text=No+Image");
    Image.objectFit("cover");
    Image.pop();
    Stack.create();
    Stack.className("grid-item-overlay");
    Text.create();
    Text.className("grid-item-title");
    Text.numberOfLines(2);
    Text.content(item.title);
    Text.pop();
    if (item.year) {
      Text.create();
      Text.className("grid-item-year");
      Text.content(item.year);
      Text.pop();
    }
    Stack.pop();
    Stack.pop();
    GridItem.pop();
  }

  /**
   * 渲染搜索结果
   */
  @Builder
  private renderSearchResults(): void {
    if (this.displayMode === 'list') {
      List.create();
      List.className("search-results-list");
      this.searchResults.forEach((item) => {
        this.renderSearchResultItem(item);
      });
      List.pop();
    } else {
      Grid.create();
      Grid.className("search-results-grid");
      Grid.columnsTemplate("1fr 1fr 1fr");
      Grid.rowsTemplate("auto");
      Grid.gap("8px");
      this.searchResults.forEach((item) => {
        this.renderGridItem(item);
      });
      Grid.pop();
    }
  }
  
  /**
   * 渲染加载状态
   */
  @Builder
  private renderLoading(): void {
    Stack.create();
    Stack.className("loading-container");
    LoadingProgress.create();
    LoadingProgress.className("loading-progress");
    LoadingProgress.color("#FF4500");
    LoadingProgress.pop();
    Text.create();
    Text.content("搜索中...");
    Text.pop();
    Stack.pop();
  }
  
  /**
   * 渲染错误状态
   */
  @Builder
  private renderError(): void {
    Stack.create();
    Stack.className("error-container");
    Text.create();
    Text.className("error-icon");
    Text.content("⚠️");
    Text.pop();
    Text.create();
    Text.className("error-message");
    Text.content(this.errorMessage);
    Text.pop();
    Button.create();
    Button.className("retry-button");
    Button.onClick(this.performSearch);
    Text.create();
    Text.content("重试");
    Text.pop();
    Button.pop();
    Stack.pop();
  }
  
  /**
   * 组件渲染
   */
  build() {
    Stack.create();
    Stack.className("search-page");
    // 搜索输入区域
    this.renderSearchInput();
    
    // 主内容区域
    ScrollView.create();
    ScrollView.className("content-scroll");
    ScrollView.scrollBar("auto");
    if (this.isSearching && this.isLoading && this.currentPage === 1) {
      this.renderLoading();
    } else if (this.errorMessage) {
      this.renderError();
    } else if (this.showHistory) {
      Stack.create();
      this.renderHotKeywords();
      this.renderSearchHistory();
      Stack.pop();
    } else {
      this.renderSearchResults();
    }
    
    Blank.create();
    Blank.className("bottom-space");
    Blank.pop();
    ScrollView.pop();
    Stack.pop();
  }
}

export default SearchPage;