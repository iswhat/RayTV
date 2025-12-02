
import { AppNavigator, PageRoute } from '../navigation/AppNavigator';
import Logger from '../common/util/Logger';
import { MediaItem } from '../data/bean/MediaItem';
import { SearchHistoryItem } from '../../data/repository/SearchHistoryRepository';
import { mediaService } from '../service/media/MediaService';
import { SearchType, SearchFilter, SearchSort } from '../data/dto/SearchDto';
import { siteManager } from '../service/spider/SiteManager';
import { lineManager } from '../service/config/LineManager';
import { Column, Row, Text, Image, Flex, Stack, Button, List, ForEach, Scroller, Blank, ImageFit, BarState, TextOverflow, FlexDirection, FlexWrap, FlexAlign, ItemAlign, HorizontalAlign } from '@ohos/arkui';

// 快速搜索结果接口
interface QuickSearchResult {
  id: string;
  title: string;
  quality: string;
  sourceType: string;
}

// 样式相关接口定义
interface ButtonStyle {
  backgroundColor?: string;
  borderRadius?: number;
  paddingHorizontal?: number;
  paddingVertical?: number;
  marginRight?: number;
}

interface TextStyle {
  fontSize?: number;
  color?: string;
  fontWeight?: number;
}

interface GridStyle {
  paddingHorizontal?: number;
  gap?: number;
  columnsTemplate?: string;
  rowsTemplate?: string;
}

interface GridItemStyle {
  gridColumnStart?: number;
  gridColumnEnd?: number;
  padding?: number;
  alignItems?: string;
  justifyContent?: string;
}

interface StackStyle {
  backgroundColor?: string;
  borderRadius?: number;
  padding?: number;
  marginHorizontal?: number;
  marginVertical?: number;
  position?: string;
  top?: number;
  left?: number;
  right?: number;
  zIndex?: number;
}

interface FlexStyle {
  flexDirection?: string;
  justifyContent?: string;
  alignItems?: string;
  marginBottom?: number;
  flex?: number;
}

interface ListStyle {
  width?: string;
  height?: number;
}

/**
 * 搜索页面组件
 * 实现媒体搜索功能，包括搜索输入、结果展示、历史搜索等
 */
@Entry
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
  @State showSourceList: boolean = false; // 是否显示快速搜索片源列表
  @State quickSearchResults: QuickSearchResult[] = []; // 快速搜索结果
  
  // 分页配置
  private pageSize: number = 20;
  private searchDebounceTimer: number | null = null;
  
  /**
   * 页面加载时调用
   */
  async aboutToAppear(): Promise<void> {
    Logger.info(this.TAG, 'SearchPage appeared');
    
    // 获取路由参数中的搜索词
    const params = this.context.router.getParams();
    if (params?.query) {
      this.searchQuery = params.query as string;
      await this.performSearch();
    } else {
      // 加载热门搜索词
      this.loadHotKeywords();
    }
    
    // 加载搜索历史（异步）
    await this.loadSearchHistory();
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
  private async loadSearchHistory(): Promise<void> {
    try {
      // 使用SearchHistoryRepository从本地存储中读取搜索历史
      const searchHistoryRepo = new SearchHistoryRepository();
      const history = await searchHistoryRepo.getHistory();
      
      // 确保history是数组类型
      if (Array.isArray(history)) {
        this.searchHistory = history;
        Logger.info(this.TAG, `Loaded ${this.searchHistory.length} search history items from repository`);
      } else {
        Logger.warn(this.TAG, `Invalid history data format, using empty array`);
        this.searchHistory = [];
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to load search history: ${error}`);
      this.searchHistory = [];
    }
  }
  
  /**
   * 保存搜索历史
   */
  private async saveSearchHistory(keyword: string): Promise<void> {
    try {
      // 去重并限制数量
      let history = this.searchHistory.filter(item => item !== keyword);
      history.unshift(keyword);
      history = history.slice(0, 10); // 最多保存10条
      
      this.searchHistory = history;
      
      // 使用SearchHistoryRepository保存到本地存储
      const searchHistoryRepo = new SearchHistoryRepository();
      await searchHistoryRepo.saveHistory(history);
      
      Logger.info(this.TAG, `Search history saved: ${keyword}`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to save search history: ${error}`);
    }
  }
  
  /**
   * 快速搜索片源
   */
  private quickSearch(keyword: string): void {
    try {
      // 获取从线路配置文件加载的真实站点列表
      const sites = siteManager.getAllSites();
      
      // 使用真实站点信息生成快速搜索结果
      this.quickSearchResults = [];
      
      // 如果有站点，使用真实站点信息
      if (sites.length > 0) {
        sites.forEach((site) => {
          // 确保站点信息有效且可搜索
          if (site && site.enabled !== false && (site.searchable === true || site.quickSearch === 1)) {
            // 尝试获取站点名称，如果名称不存在则使用key作为备用
            const siteName = site.name || site.key || '未知站点';
            
            this.quickSearchResults.push({
              id: `${keyword}-${site.key || Math.random().toString(36).substr(2, 9)}`,
              title: `${keyword} - ${siteName}`,
              quality: site.quality || '高清',
              sourceType: siteName
            });
          }
        });
        
        // 如果从站点列表中没有获取到可搜索的站点，添加一些默认站点
        if (this.quickSearchResults.length === 0) {
          this.addDefaultQuickSearchResults(keyword);
        }
      } else {
        // 如果没有站点信息，使用备用的默认站点
        this.addDefaultQuickSearchResults(keyword);
      }
      
      // 限制结果数量，避免显示过多
      this.quickSearchResults = this.quickSearchResults.slice(0, 10);
      
      // 显示快速搜索结果
      this.showSourceList = true;
      Logger.info(this.TAG, `Quick search for: ${keyword}, results: ${this.quickSearchResults.length}`);
      
      // 获取当前线路信息并记录日志
      const currentLine = lineManager.getCurrentLine();
      if (currentLine) {
        Logger.info(this.TAG, `Current line: ${currentLine.name || '未知名称'}, sources loaded from: ${currentLine.url}`);
      }
    } catch (error) {
      Logger.error(this.TAG, `Quick search failed: ${JSON.stringify(error)}`);
      // 即使出错，也添加一些默认站点供用户选择
      this.quickSearchResults = [];
      this.addDefaultQuickSearchResults(keyword);
      this.showSourceList = this.quickSearchResults.length > 0;
    }
  }
  
  /**
   * 添加默认的快速搜索结果
   */
  private addDefaultQuickSearchResults(keyword: string): void {
    // 从典型线路配置中提取的常见站点列表
    const defaultSources = [
      {key: 'lebei', name: '乐贝视频'},
      {key: 'qimi', name: '奇米影视'},
      {key: 'jiumo', name: '九猫影视'},
      {key: 'yiso', name: '易发影视'},
      {key: 'lengfan', name: '冷番影视'},
      {key: 'jinlian', name: '金濂视频'},
      {key: 'miaofan', name: '秒番影视'},
      {key: 'zhuifan', name: '追番视频'},
      {key: 'kanfan', name: '看番视频'},
      {key: 'haokan', name: '好看视频'}
    ];
    
    defaultSources.forEach((source) => {
      this.quickSearchResults.push({
        id: `${keyword}-${source.key}`,
        title: `${keyword} - ${source.name}`,
        quality: '高清全片',
        sourceType: source.name
      });
    });
  }

  /**
   * 构建页面UI
   */
  build() {
    // 这里需要实现页面的UI构建逻辑
    // 暂时返回一个空的Column作为占位符
    Column() {
      Text('搜索页面')
        .fontSize(20)
        .fontColor('#333333')
    }
  }

  /**
   * 处理快速搜索结果点击事件
   */
  private async handleQuickSearchResultClick(result: QuickSearchResult): Promise<void> {
    try {
      Logger.info(this.TAG, `Quick search result clicked: ${JSON.stringify(result)}`);
      
      // 隐藏快速搜索结果
      this.showSourceList = false;
      
      // 跳转到MediaDetailPage页面，携带相关参数
      AppNavigator.getInstance().navigateToDetail({
          title: result.title,
          sourceId: result.id,
          sourceType: result.sourceType,
          mediaType: 'video',
          keyword: this.searchQuery,
          // 传递站点信息，以便在详情页能够使用正确的搜索源
          siteName: result.sourceType,
          // 记录当前使用的线路信息
          currentLine: lineManager.getCurrentLine() ? lineManager.getCurrentLine().name : 'Default'
        });
      
      // 记录搜索历史
      await this.saveSearchHistory(this.searchQuery);
    } catch (error) {
      Logger.error(this.TAG, `Error handling quick search result click: ${error}`);
    }
  }

  /**
   * 清除搜索历史
   */
  private async clearSearchHistory(): Promise<void> {
    try {
      this.searchHistory = [];
      // 使用SearchHistoryRepository清除本地存储中的搜索历史
      const searchHistoryRepo = new SearchHistoryRepository();
      await searchHistoryRepo.clearHistory();
      
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
    
    // 输入为空时重置状态
    if (value.trim().length === 0) {
      this.resetSearchState();
      this.showSourceList = false;
      return;
    }
    
    // 快速搜索片源（当输入达到一定长度时）
    if (value.trim().length >= 2) {
      // 立即执行快速搜索
      this.quickSearch(value.trim());
      
      // 输入停止300ms后执行常规搜索
      this.searchDebounceTimer = setTimeout(async () => {
        await this.performSearch();
      }, 300);
    }
  }
  
  /**
   * 执行搜索
   */
  private async performSearch(): Promise<void> {
    const query = this.searchQuery.trim();
    if (!query) return;
    
    // 隐藏快速搜索结果
    this.showSourceList = false;
    
    this.isSearching = true;
    this.isLoading = true;
    this.errorMessage = '';
    this.showHistory = false;
    this.currentPage = 1;
    
    try {
      // 保存搜索历史（异步）
      await this.saveSearchHistory(query);
      
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
      
      // 使用await处理Promise
      const result = await mediaService.searchMedia(searchParams);
      
      // 处理搜索结果
      this.searchResults = result.items || [];
      this.hasMoreResults = result.hasMore || false;
      
      Logger.info(this.TAG, `Search completed, found ${this.searchResults.length} results`);
    } catch (error) {
      Logger.error(this.TAG, `Search failed: ${error}`);
      this.errorMessage = '搜索失败，请稍后重试';
      this.searchResults = [];
      this.hasMoreResults = false;
    } finally {
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
  private async handleKeywordClick(keyword: string): Promise<void> {
    this.searchQuery = keyword;
    await this.performSearch();
  }
  
  /**
   * 处理搜索结果项点击
   */
  private handleSearchResultClick(media: MediaItem): void {
    if (!media || !media.id) {
      Logger.error(this.TAG, `Invalid media item: ${JSON.stringify(media)}`);
      return;
    }
    
    Logger.info(this.TAG, `Search result clicked: ${media.title}`);
    
    // 跳转到详情页
    AppNavigator.getInstance().navigateToDetail({
      id: media.id,
      siteKey: media.siteKey || '',
      type: 'vod'
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
    this.context.router.back();
  }
  
  /**
   * 渲染搜索输入框
   */
  @Builder
  private renderSearchInput(): void {
    Stack({ className: "search-input-container" }) {
      Button({ className: "back-button", onClick: this.handleBack }) {
        Text("←")
      }
      Flex({ className: "search-input-wrapper" }) {
        Text({ className: "search-icon", content: "🔍" })
        TextInput({
          className: "search-input",
          value: this.searchQuery,
          onChange: this.handleSearchInputChange,
          onSubmit: this.performSearch,
          placeholder: "搜索电影、电视剧、动漫...",
          enterKeyType: "search",
          autoFocus: true
        })
        if (this.searchQuery) {
          Button({ className: "clear-button", onClick: this.handleClearInput }) {
            Text("✕")
          }
        }
      }
      Button({ className: "search-button", onClick: this.performSearch }) {
        Text("搜索")
      }
    }
  }
  
  /**
   * 渲染热门搜索
   */
  @Builder
  private renderHotKeywords(): void {
    Stack({ className: "hot-keywords-section" }) {
      Flex({ className: "section-header" }) {
        Text({ className: "section-title", content: "热门搜索" })
      }
      Flex({ className: "keywords-container", wrap: "wrap" }) {
        ForEach(this.hotKeywords, (keyword, index) => {
          Tag({
            key: `hot-${index}`,
            className: "keyword-tag hot",
            onClick: () => this.handleKeywordClick(keyword)
          }) {
            Text({ className: "keyword-rank", content: (index + 1).toString() })
            Text(keyword)
          }
        }, (keyword, index) => `hot-${index}`)
      }
    }
  }
  
  /**
   * 渲染搜索历史
   */
  @Builder
  private renderSearchHistory(): void {
    if (this.searchHistory.length > 0) {
      Stack()
      .backgroundColor('#FFFFFF')
      .borderRadius(10)
      .padding(15)
      .margin({ bottom: 15 }) {
        Flex()
        .direction(FlexDirection.Row)
        .justifyContent(FlexAlign.SpaceBetween)
        .alignItems(ItemAlign.Center)
        .margin({ bottom: 10 }) {
          Text("搜索历史")
            .fontSize(20)
            .fontColor('#333333')
            .fontWeight(600)
          Button()
          .backgroundColor('transparent')
          .onClick(this.clearSearchHistory) {
            Text("清除")
              .fontSize(16)
              .fontColor('#666666')
          }
        Flex()
        .direction(FlexDirection.Row)
        .flexWrap(FlexWrap.Wrap)
        .gap(10) {
          ForEach(this.searchHistory, (keyword, index) => {
            Button()
            .key(`history-${index}`)
            .backgroundColor('#E0E0E0')
            .borderRadius(15)
            .padding({ horizontal: 15, vertical: 8 })
            .onClick(() => this.handleKeywordClick(keyword)) {
              Flex()
              .direction(FlexDirection.Row)
              .alignItems(ItemAlign.Center)
              .gap(5) {
                Text("🕐")
                  .fontSize(16)
                Text(keyword)
                  .fontSize(16)
              }
            }
        }, (keyword, index) => `history-${index}`)
      }
    }
  }
  
  /**
   * 渲染搜索结果项
   */
  @Builder
  private renderSearchResultItem(media: MediaItem): void {
    Flex()
    .direction(FlexDirection.Row)
    .alignItems(ItemAlign.Center)
    .padding(15)
    .backgroundColor('#FFFFFF')
    .borderRadius(10)
    .margin({ bottom: 10 })
    .onClick(() => this.handleSearchResultClick(media)) {
      // 媒体封面 - 使用占位符替代Image组件
      Column()
      .width(100)
      .height(150)
      .backgroundColor('#E0E0E0')
      .borderRadius(8)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .margin({ right: 15 }) {
        Text("封面")
          .fontSize(14)
          .fontColor('#666666')
      }
      Flex()
      .direction(FlexDirection.Column)
      .flex(1) {
        Text(media.title)
          .fontSize(20)
          .fontColor('#333333')
          .fontWeight(600)
          .numberOfLines(2)
        Flex()
        .direction(FlexDirection.Row)
        .flexWrap(FlexWrap.Wrap)
        .gap(8)
        .margin({ top: 8 }) {
          if (media.year) {
            Button()
            .backgroundColor('#E0E0E0')
            .borderRadius(10)
            .padding({ horizontal: 10, vertical: 4 }) {
              Text(media.year)
                .fontSize(14)
                .fontColor('#666666')
            }
          }
          if (media.type) {
            Button()
            .backgroundColor('#E0E0E0')
            .borderRadius(10)
            .padding({ horizontal: 10, vertical: 4 }) {
              Text(media.type)
                .fontSize(14)
                .fontColor('#666666')
            }
          }
          if (media.score) {
            Button()
            .backgroundColor('#FFEB3B')
            .borderRadius(10)
            .padding({ horizontal: 10, vertical: 4 }) {
              Text(media.score)
                .fontSize(14)
                .fontColor('#000000')
                .fontWeight(600)
            }
          }
        }
        if (media.description) {
          Text(media.description)
            .fontSize(16)
            .fontColor('#666666')
            .numberOfLines(2)
            .margin({ top: 8 })
        }
        if (media.directors && media.directors.length > 0) {
          Text(`导演: ${media.directors.slice(0, 3).join(', ')}`)
            .fontSize(14)
            .fontColor('#999999')
            .numberOfLines(1)
            .margin({ top: 5 })
        }
        if (media.actors && media.actors.length > 0) {
          Text(`主演: ${media.actors.slice(0, 3).join(', ')}`)
            .fontSize(14)
            .fontColor('#999999')
            .numberOfLines(1)
            .margin({ top: 2 })
        }
      }
    }
  }
  
  /**
   * 渲染显示模式切换按钮
   */
  @Builder
  private renderDisplayModeToggle(): void {
    Button()
    .backgroundColor('#4CAF50')
    .borderRadius(20)
    .padding({ horizontal: 15, vertical: 8 })
    .onClick(this.toggleDisplayMode) {
      Text(this.displayMode === 'list' ? '网格' : '列表')
        .fontSize(16)
        .fontColor('#FFFFFF')
        .fontWeight(600)
    }
  }
  
  /**
   * 渲染筛选按钮
   */
  @Builder
  private renderFilterButton(): void {
    Button()
    .backgroundColor('#4CAF50')
    .borderRadius(20)
    .padding({ horizontal: 15, vertical: 8 })
    .onClick(this.toggleFilterPanel) {
      Text("筛选")
        .fontSize(16)
        .fontColor('#FFFFFF')
        .fontWeight(600)
    }
  }
  
  /**
   * 渲染筛选面板
   */
  @Builder
  private renderFilterPanel(): void {
    if (this.showFilterPanel) {
      Stack()
      .backgroundColor('rgba(0, 0, 0, 0.85)')
      .position({ x: 0, y: 0 })
      .width('100%')
      .height('100%')
      .zIndex(100) {
        Stack()
        .backgroundColor('#4CAF50')
        .position({ x: 0, y: 0 })
        .width('100%')
        .height('auto')
        .padding(20)
        .borderTopLeftRadius(20)
        .borderTopRightRadius(20) {
          // 标题栏
          Flex()
          .direction(FlexDirection.Row)
          .justifyContent(FlexAlign.SpaceBetween)
          .alignItems(ItemAlign.Center)
          .margin({ bottom: 20 }) {
            Text('筛选条件')
              .fontSize(28)
              .fontColor('#FFFFFF')
              .fontWeight(700)
            Button()
            .backgroundColor('transparent')
            .onClick(() => {
              this.showFilterPanel = false;
            }) {
              Text('✕')
                .fontSize(28)
                .fontColor('#FFFFFF')
            }
          }
        
        // 媒体类型筛选
        Text('媒体类型:')
          .fontSize(24)
          .fontColor('#FFFFFF')
          .margin({ bottom: 15 })
          .fontWeight(600)
        
        Flex({ direction: FlexDirection.Row, flexWrap: FlexWrap.Wrap, gap: 10, marginBottom: 20 }) {
          ForEach([
            { label: '电影', value: 'movie' },
            { label: '电视剧', value: 'tv' },
            { label: '动漫', value: 'anime' },
            { label: '综艺', value: 'variety' },
            { label: '纪录片', value: 'documentary' }
          ], (type) => {
            Button({
              backgroundColor: this.filters.types?.includes(type.value) ? '#FFEB3B' : '#FFFFFF',
              borderRadius: 15,
              paddingHorizontal: 15,
              paddingVertical: 8,
              onClick: () => {
                this.updateMediaTypeFilter(type.value, !this.filters.types?.includes(type.value));
              }
            }) {
              Text(type.label)
                .fontSize(22)
                .fontColor(this.filters.types?.includes(type.value) ? '#000000' : '#4CAF50')
                .fontWeight(600)
            }
          })
        }
        
        // 排序方式
        Text('排序方式:')
          .fontSize(24)
          .fontColor('#FFFFFF')
          .margin({ bottom: 15 })
          .fontWeight(600)
        
        Flex({
          direction: FlexDirection.Row,
          flexWrap: FlexWrap.Wrap,
          gap: 10,
          marginBottom: 20
        }) {
          ForEach([
            { label: '默认排序', value: 'default' },
            { label: '最新发布', value: 'latest' },
            { label: '评分最高', value: 'rating' },
            { label: '播放最多', value: 'popular' }
          ], (option) => {
            Button({
              backgroundColor: this.filters.sort === option.value ? '#FFEB3B' : '#FFFFFF',
              borderRadius: 15,
              paddingHorizontal: 15,
              paddingVertical: 8,
              onClick: () => {
                this.filters.sort = option.value;
              }
            }) {
              Text(option.label)
                .fontSize(22)
                .fontColor(this.filters.sort === option.value ? '#000000' : '#4CAF50')
                .fontWeight(600)
            }
          })
        }
        
        // 操作按钮
        Flex({
          direction: FlexDirection.Row,
          justifyContent: FlexAlign.SpaceBetween,
          gap: 15
        }) {
          Button({
            style: {
              backgroundColor: '#FFFFFF',
              borderRadius: 15,
              paddingHorizontal: 20,
              paddingVertical: 12,
              flex: 1
            },
            onClick: this.resetFilters
          }) {
            Text('重置')
              .fontSize(22)
              .fontColor('#4CAF50')
              .fontWeight(600)
          }
          Button({
            type: 'capsule',
            onClick: this.applyFilters
          }) {
            Text('应用筛选')
          }
        }
      }
    }
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
    if (item) {
      // 使用Column替代GridItem
      Column()
      .width('100%')
      .margin({ bottom: 15 })
      .onClick(() => this.handleSearchResultClick(item)) {
      Stack({
          width: '100%'
        }) {
        // 来源标签 - 改为绿色主题
        if (item.siteKey) {
          Text(`${item.siteKey} | APP`)
            .backgroundColor('#4CAF50')
            .fontColor('#FFFFFF')
            .fontSize(16)
            .padding({ horizontal: 8, vertical: 4 })
            .borderRadius(4)
            .position({ x: 0, y: 0 })
            .margin({ top: 8, left: 8 })
            .zIndex(10)
            .fontWeight(600)
        }
        
        // 图片 - 使用占位符替代Image组件
        Column({
          width: '100%',
          aspectRatio: 2/3,
          backgroundColor: '#E0E0E0',
          borderRadius: 8,
          justifyContent: FlexAlign.Center,
          alignItems: HorizontalAlign.Center
        }) {
          Text("封面")
            .fontSize(16)
            .fontColor('#666666')
        }
        
        // 标题
        Text(item.title || '未知标题')
          .fontSize(20)
          .fontColor('#FFFFFF')
          .margin({ top: 8 })
          .fontWeight(600)
          .textShadow({
            radius: 3,
            color: 'rgba(0, 0, 0, 0.8)',
            offset: { x: 1, y: 1 }
          })
          .numberOfLines(2)
        
        // 评分标签 - 如果有评分则显示
        if (item.score) {
          Text(`${item.score}分`)
            .backgroundColor('#FFEB3B')
            .fontColor('#000000')
            .fontSize(16)
            .padding({ horizontal: 8, vertical: 2 })
            .borderRadius(4)
            .margin({ top: 4 })
            .fontWeight(700)
        }
      }
    }
  }

  /**
   * 渲染搜索结果
   */
  @Builder
  private renderSearchResults(): void {
    // 渲染分类筛选按钮
    Scroller()
    .scrollable(ScrollDirection.Horizontal)
    .margin({ bottom: 20 }) {
      Flex()
      .padding({ horizontal: 15 })
      .alignItems(FlexAlign.Center)
      .gap(10) {
        // 全部显示按钮
        Button()
        .backgroundColor('#4CAF50')
        .borderRadius(20)
        .padding({ horizontal: 20, vertical: 8 })
        .margin({ right: 10 })
        .onClick(() => {}) {
          Text("全部显示")
            .fontSize(22)
            .fontColor('#FFFFFF')
            .fontWeight(600)
        }
        
        // 分类按钮
        ForEach(["热播 | APP", "浪酷 | APP", "秒看 | APP", "星空 | APP", "爱看 | APP", "冷心 | APP"], (category) => {
          Button()
          .backgroundColor('#FFFFFF')
          .borderRadius(20)
          .padding({ horizontal: 20, vertical: 8 })
          .margin({ right: 10 })
          .onClick(() => {}) {
            Text(category)
              .fontSize(22)
              .fontColor('#4CAF50')
              .fontWeight(600)
          }
        })
      }
    }
    
    // 渲染网格结果 - 使用Flex布局替代Grid
    Flex({
      paddingHorizontal: 15,
      gap: 15,
      flexWrap: FlexWrap.Wrap,
      justifyContent: FlexAlign.Start
    }) {
      if (this.searchResults.length === 0) {
        // 无搜索结果时的提示
        Column({ width: '100%', padding: 30, alignItems: HorizontalAlign.Center, justifyContent: FlexAlign.Center }) {
          Text('没有找到相关内容')
            .fontSize(24)
            .fontColor('#FFFFFF')
            .textAlign(TextAlign.Center)
        }
      } else {
        // 渲染搜索结果项
        ForEach(this.searchResults, (item) => {
          Column({ width: '18%', marginBottom: 15 }) {
            this.renderGridItem(item)
          }
        })
      }
    }
  }
  
  /**
   * 渲染加载状态
   */
  @Builder
  private renderLoading(): void {
    Stack({
      width: '100%',
      height: '100%',
      justifyContent: FlexAlign.Center,
      alignItems: HorizontalAlign.Center
    }) {
      // 自定义加载指示器
      Column({
        backgroundColor: '#FFFFFF',
          borderRadius: 20,
          padding: 20,
          alignItems: 'center'
        }
      }) {
        Text("●")
          .fontSize(40)
          .fontColor('#4CAF50')
          .animation({
            duration: 1000,
            iterations: -1,
            curve: 'easeInOut'
          })
        Text("搜索中...")
          .fontSize(18)
          .fontColor('#333333')
          .margin({ top: 10 })
      }
    }
  }
  
  /**
   * 渲染快速搜索结果（片源切换界面）
   */
  @Builder
  private renderQuickSearchResults(): void {
    if (this.showSourceList && this.quickSearchResults.length > 0) {
      Stack() {
        // 标题栏
        Flex() {
          Text(`为您找到相关片源: ${this.quickSearchResults.length}个`)
            .fontSize(28)
            .fontColor('#FFFFFF')
            .fontWeight(700)
          Button() {
            Text('✕')
              .fontSize(28)
              .fontColor('#FFFFFF')
          }
          .backgroundColor('transparent')
          .onClick(() => {
            this.showSourceList = false;
          })
        }
        .direction(FlexDirection.Row)
        .justifyContent(FlexAlign.SpaceBetween)
        .alignItems(ItemAlign.Center)
        .margin({ bottom: 15 })
        
        // 片源列表
        List() {
          ForEach(this.quickSearchResults, (item, index) => {
            ListItem() {
              Flex() {
                // 标题和来源
                Flex() {
                  Text(item.title)
                    .fontSize(26)
                    .fontColor('#FFFFFF')
                    .fontWeight(700)
                    .margin({ bottom: 5 })
                  Text(item.sourceType)
                    .fontSize(20)
                    .fontColor('#E0E0E0')
                }
                .flex(1)
                .direction(FlexDirection.Column)
                
                // 质量标签
                if (item.quality) {
                  Flex() {
                    Text(item.quality)
                      .fontSize(22)
                      .fontColor('#000000')
                      .fontWeight(700)
                  }
                  .backgroundColor('#FFEB3B')
                  .padding({ horizontal: 12, vertical: 6 })
                  .borderRadius(12)
                }
              }
              .direction(FlexDirection.Row)
              .justifyContent(FlexAlign.SpaceBetween)
              .alignItems(ItemAlign.Center)
            }
            .key(`${item.id || index}`)
            .backgroundColor('#66BB6A')
            .margin({ bottom: 10 })
            .padding(15)
            .borderRadius(10)
            .onClick(() => {
              this.handleQuickSearchResultClick(item);
            })
          })
        }
        .width('100%')
        .height(500)
      }
      .backgroundColor('rgba(0, 0, 0, 0.85)')
      .borderRadius(15)
      .padding(20)
      .margin({ left: 20, right: 20, top: 10, bottom: 10 })
      .position({ x: 0, y: 120 })
      .width('100%')
      .zIndex(100)
    }
  }

  /**
   * 渲染错误状态
   */
  @Builder
  private renderError(): void {
    Stack({
      alignItems: HorizontalAlign.Center,
      justifyContent: FlexAlign.Center,
      padding: 20
    }) {
      Text("⚠️")
        .fontSize(40)
        .fontColor('#FF6B6B')
        .margin({ bottom: 10 })
      Text(this.errorMessage)
        .fontSize(18)
        .fontColor('#FFFFFF')
        .textAlign(TextAlign.Center)
        .margin({ bottom: 20 })
      Button({
        backgroundColor: '#4CAF50',
        borderRadius: 20,
        paddingHorizontal: 20,
        paddingVertical: 10,
        onClick: this.performSearch
      }) {
        Text("重试")
          .fontSize(16)
          .fontColor('#FFFFFF')
          .fontWeight(600)
      }
    }
  }
  
  /**
   * 组件渲染
   */
  build() {
    Stack({
      backgroundColor: '#2E7D32',
      flexGrow: 1
    }) {
      // 搜索输入区域
      this.renderSearchInput();
      
      // 快速搜索片源切换界面
      this.renderQuickSearchResults();
      
      // 主内容区域
      ScrollView({
        scrollBar: ScrollBarState.Auto,
        flexGrow: 1
      }) {
        // 显示搜索结果数量
        if (!this.showHistory && this.searchResults.length > 0) {
          Text(`搜索(${this.searchResults.length}/${this.searchResults.length})`)
            .fontSize(22)
            .fontColor('#FFFFFF')
            .padding({ left: 15, right: 15, top: 10, bottom: 10 })
            .fontWeight(FontWeight.SemiBold)
        }
        
        if (this.isSearching && this.isLoading && this.currentPage === 1) {
          this.renderLoading();
        } else if (this.errorMessage) {
          this.renderError();
        } else if (this.showHistory) {
          Stack({
            padding: { left: 15, right: 15 }
          }) {
            this.renderHotKeywords();
            this.renderSearchHistory();
          }
        } else {
          this.renderSearchResults();
        }
        
        Blank()
          .height(50)
      }
    }
  }
}

export default SearchPage;