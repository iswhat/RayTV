
import Router from '@ohos.router';
import Logger from '../common/util/Logger';
import { MediaItem } from '../data/bean/MediaItem';
import { SearchHistoryItem } from '../../data/repository/SearchHistoryRepository';
import { mediaService } from '../service/media/MediaService';
import { SearchType, SearchFilter, SearchSort } from '../data/dto/SearchDto';
import { siteManager } from '../service/spider/SiteManager';
import { lineManager } from '../service/config/LineManager';

// 快速搜索结果接口
interface QuickSearchResult {
  id: string;
  title: string;
  quality: string;
  sourceType: string;
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
  aboutToAppear(): void {
    Logger.info(this.TAG, 'SearchPage appeared');
    
    // 获取路由参数中的搜索词
    const params = this.context.router.getParams();
    if (params?.query) {
      this.searchQuery = params.query as string;
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
   * 处理快速搜索结果点击事件
   */
  private handleQuickSearchResultClick(result: QuickSearchResult): void {
    try {
      Logger.info(this.TAG, `Quick search result clicked: ${JSON.stringify(result)}`);
      
      // 隐藏快速搜索结果
      this.showSourceList = false;
      
      // 跳转到MediaDetailPage页面，携带相关参数
      Router.push({
        url: 'pages/MediaDetailPage',
        params: {
          title: result.title,
          sourceId: result.id,
          sourceType: result.sourceType,
          mediaType: 'video',
          keyword: this.searchText,
          // 传递站点信息，以便在详情页能够使用正确的搜索源
          siteName: result.sourceType,
          // 记录当前使用的线路信息
          currentLine: lineManager.getCurrentLine() ? lineManager.getCurrentLine().name : 'Default'
        }
      });
      
      // 记录搜索历史
      this.saveSearchHistory(this.searchText);
    } catch (error) {
      Logger.error(this.TAG, `Error handling quick search result click: ${error}`);
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
      this.searchDebounceTimer = setTimeout(() => {
        this.performSearch();
      }, 300);
    }
  }
  
  /**
   * 执行搜索
   */
  private performSearch(): void {
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
    if (!media || !media.id) {
      Logger.error(this.TAG, `Invalid media item: ${JSON.stringify(media)}`);
      return;
    }
    
    Logger.info(this.TAG, `Search result clicked: ${media.title}`);
    
    // 跳转到今日详情页
    Router.push({
      url: 'pages/MediaDetailPage',
      params: {
        mediaId: media.id,
        siteKey: media.siteKey || '',
        title: media.title || '',
        coverUrl: media.coverUrl || '',
        description: media.description || '',
        year: media.year || '',
        type: media.type || '',
        score: media.score || '',
        directors: media.directors || [],
        actors: media.actors || []
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
    this.context.router.back();
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
    
    Stack({
      style: {
        backgroundColor: 'rgba(0, 0, 0, 0.85)',
        position: 'absolute',
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        zIndex: 100
      }
    }) {
      Stack({
        style: {
          backgroundColor: '#4CAF50',
          position: 'absolute',
          bottom: 0,
          left: 0,
          right: 0,
          padding: 20,
          borderTopLeftRadius: 20,
          borderTopRightRadius: 20
        }
      }) {
        // 标题栏
        Flex({
          style: {
            flexDirection: 'row',
            justifyContent: 'space-between',
            alignItems: 'center',
            marginBottom: 20
          }
        }) {
          Text('筛选条件')
            .style({
              fontSize: 28,
              color: '#FFFFFF',
              fontWeight: 700
            })
          Button({
            style: {
              backgroundColor: 'transparent'
            },
            onClick: () => {
              this.showFilterPanel = false;
            }
          }) {
            Text('✕')
              .style({
                fontSize: 28,
                color: '#FFFFFF'
              })
          }
        }
        
        // 媒体类型筛选
        Text('媒体类型:')
          .style({
            fontSize: 24,
            color: '#FFFFFF',
            marginBottom: 15,
            fontWeight: 600
          })
        
        Flex({
          style: {
            flexDirection: 'row',
            flexWrap: 'wrap',
            gap: 10,
            marginBottom: 20
          }
        }) {
          const mediaTypes = [
            { label: '电影', value: 'movie' },
            { label: '电视剧', value: 'tv' },
            { label: '动漫', value: 'anime' },
            { label: '综艺', value: 'variety' },
            { label: '纪录片', value: 'documentary' }
          ];
          
          ForEach(mediaTypes, (type) => {
            Button({
              style: {
                backgroundColor: this.filters.types?.includes(type.value) ? '#FFEB3B' : '#FFFFFF',
                borderRadius: 15,
                paddingHorizontal: 15,
                paddingVertical: 8
              },
              onClick: () => {
                this.updateMediaTypeFilter(type.value, !this.filters.types?.includes(type.value));
              }
            }) {
              Text(type.label)
                .style({
                  fontSize: 22,
                  color: this.filters.types?.includes(type.value) ? '#000000' : '#4CAF50',
                  fontWeight: 600
                })
            }
          })
        }
        
        // 排序方式
        Text('排序方式:')
          .style({
            fontSize: 24,
            color: '#FFFFFF',
            marginBottom: 15,
            fontWeight: 600
          })
        
        Flex({
          style: {
            flexDirection: 'row',
            flexWrap: 'wrap',
            gap: 10,
            marginBottom: 20
          }
        }) {
          const sortOptions = [
            { label: '默认排序', value: 'default' },
            { label: '最新发布', value: 'latest' },
            { label: '评分最高', value: 'rating' },
            { label: '播放最多', value: 'popular' }
          ];
          
          ForEach(sortOptions, (option) => {
            Button({
              style: {
                backgroundColor: this.filters.sort === option.value ? '#FFEB3B' : '#FFFFFF',
                borderRadius: 15,
                paddingHorizontal: 15,
                paddingVertical: 8
              },
              onClick: () => {
                this.filters.sort = option.value;
              }
            }) {
              Text(option.label)
                .style({
                  fontSize: 22,
                  color: this.filters.sort === option.value ? '#000000' : '#4CAF50',
                  fontWeight: 600
                })
            }
          })
        }
        
        // 操作按钮
        Flex({
          style: {
            flexDirection: 'row',
            justifyContent: 'space-between',
            gap: 15
          }
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
              .style({
                fontSize: 22,
                color: '#4CAF50',
                fontWeight: 600
              })
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
    if (!item) return;
    
    GridItem({
      className: "green-grid-item",
      onClick: () => this.handleSearchResultClick(item)
    }) {
      Stack({
        className: "green-grid-item-content"
      }) {
        // 来源标签 - 改为绿色主题
        if (item.siteKey) {
          Text(`${item.siteKey} | APP`)
            .style({
              backgroundColor: '#4CAF50',
              color: '#FFFFFF',
              fontSize: 16,
              paddingHorizontal: 8,
              paddingVertical: 4,
              borderRadius: 4,
              position: 'absolute',
              top: 8,
              left: 8,
              zIndex: 10,
              fontWeight: 600
            })
        }
        
        // 图片
        Image(item.coverUrl || "https://via.placeholder.com/200x300?text=No+Image")
          .style({
            width: '100%',
            aspectRatio: 2/3,
            borderRadius: 8
          })
          .objectFit("cover")
        
        // 标题
        Text(item.title || '未知标题')
          .style({
            fontSize: 20,
            color: '#FFFFFF',
            marginTop: 8,
            fontWeight: 600,
            textShadowColor: 'rgba(0, 0, 0, 0.8)',
            textShadowOffset: {
              dx: 1,
              dy: 1
            },
            textShadowRadius: 3
          })
          .numberOfLines(2)
        
        // 评分标签 - 如果有评分则显示
        if (item.score) {
          Text(`${item.score}分`)
            .style({
              backgroundColor: '#FFEB3B',
              color: '#000000',
              fontSize: 16,
              paddingHorizontal: 8,
              paddingVertical: 2,
              borderRadius: 4,
              marginTop: 4,
              fontWeight: 700
            })
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
    ScrollView({
      style: {
        whiteSpace: 'nowrap',
        marginBottom: 20
      }
    }) {
      Flex({
        style: {
          paddingHorizontal: 15,
          alignItems: 'center',
          gap: 10
        }
      }) {
        // 全部显示按钮
        Button({
          style: {
            backgroundColor: '#4CAF50',
            borderRadius: 20,
            paddingHorizontal: 20,
            paddingVertical: 8,
            marginRight: 10
          },
          onClick: () => {}
        }) {
          Text("全部显示")
            .style({
              fontSize: 22,
              color: '#FFFFFF',
              fontWeight: 600
            })
        }
        
        // 分类按钮
        const categories = ["热播 | APP", "浪酷 | APP", "秒看 | APP", "星空 | APP", "爱看 | APP", "冷心 | APP"];
        ForEach(categories, (category) => {
          Button({
            style: {
              backgroundColor: '#FFFFFF',
              borderRadius: 20,
              paddingHorizontal: 20,
              paddingVertical: 8,
              marginRight: 10
            },
            onClick: () => {}
          }) {
            Text(category)
              .style({
                fontSize: 22,
                color: '#4CAF50',
                fontWeight: 600
              })
          }
        })
      }
    }
    
    // 渲染网格结果
    Grid({
      style: {
        paddingHorizontal: 15,
        gap: 15
      },
      columnsTemplate: "1fr 1fr 1fr 1fr 1fr",
      rowsTemplate: "auto"
    }) {
      if (this.searchResults.length === 0) {
        // 无搜索结果时的提示
        GridItem({
          style: {
            gridColumnStart: 1,
            gridColumnEnd: 6,
            padding: 30,
            alignItems: 'center',
            justifyContent: 'center'
          }
        }) {
          Text('没有找到相关内容')
            .style({
              fontSize: 24,
              color: '#FFFFFF',
              textAlign: 'center'
            })
        }
      } else {
        // 渲染搜索结果项
        ForEach(this.searchResults, (item) => {
          this.renderGridItem(item)
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
      className: "loading-container"
    }) {
      LoadingProgress()
        .className("loading-progress")
        .color("#FF4500")
      Text("搜索中...")
    }
  }
  
  /**
   * 渲染快速搜索结果（片源切换界面）
   */
  @Builder
  private renderQuickSearchResults(): void {
    if (this.showSourceList && this.quickSearchResults.length > 0) {
      Stack({
        style: {
          backgroundColor: 'rgba(0, 0, 0, 0.85)',
          borderRadius: 15,
          padding: 20,
          marginHorizontal: 20,
          marginVertical: 10,
          position: 'absolute',
          top: 120,
          left: 0,
          right: 0,
          zIndex: 100
        }
      }) {
        // 标题栏
        Flex({
          style: {
            flexDirection: 'row',
            justifyContent: 'space-between',
            alignItems: 'center',
            marginBottom: 15
          }
        }) {
          Text(`为您找到相关片源: ${this.quickSearchResults.length}个`)
            .style({
              fontSize: 28,
              color: '#FFFFFF',
              fontWeight: 700
            })
          Button({
            style: {
              backgroundColor: 'transparent'
            },
            onClick: () => {
              this.showSourceList = false;
            }
          }) {
            Text('✕')
              .style({
                fontSize: 28,
                color: '#FFFFFF'
              })
          }
        }
        
        // 片源列表
        List({
          style: {
            width: '100%',
            height: 500
          }
        }) {
          ForEach(this.quickSearchResults, (item, index) => {
            ListItem({
              key: `${item.id || index}`,
              style: {
                backgroundColor: '#66BB6A',
                marginBottom: 10,
                padding: 15,
                borderRadius: 10
              },
              onClick: () => {
                this.handleQuickSearchResultClick(item);
              }
            }) {
              Flex({
                style: {
                  flexDirection: 'row',
                  justifyContent: 'space-between',
                  alignItems: 'center'
                }
              }) {
                // 标题和来源
                Flex({
                  style: {
                    flex: 1,
                    flexDirection: 'column'
                  }
                }) {
                  Text(item.title)
                    .style({
                      fontSize: 26,
                      color: '#FFFFFF',
                      fontWeight: 700,
                      marginBottom: 5
                    })
                  Text(item.sourceType)
                    .style({
                      fontSize: 20,
                      color: '#E0E0E0'
                    })
                }
                
                // 质量标签
                if (item.quality) {
                  Flex({
                    style: {
                      backgroundColor: '#FFEB3B',
                      paddingHorizontal: 12,
                      paddingVertical: 6,
                      borderRadius: 12
                    }
                  }) {
                    Text(item.quality)
                      .style({
                        fontSize: 22,
                        color: '#000000',
                        fontWeight: 700
                      })
                  }
                }
              }
            }
          })
        }
      }
    }
  }

  /**
   * 渲染错误状态
   */
  @Builder
  private renderError(): void {
    Stack({
      className: "error-container"
    }) {
      Text("⚠️")
        .className("error-icon")
      Text(this.errorMessage)
        .className("error-message")
      Button({
        className: "retry-button",
        onClick: this.performSearch
      }) {
        Text("重试")
      }
    }
  }
  
  /**
   * 组件渲染
   */
  build() {
    Stack({
      style: {
        backgroundColor: '#2E7D32',
        flex: 1
      }
    }) {
      // 搜索输入区域
      this.renderSearchInput()
      
      // 快速搜索片源切换界面
      this.renderQuickSearchResults()
      
      // 主内容区域
      ScrollView({
        style: {
          flex: 1,
          scrollBar: 'auto'
        }
      }) {
        // 显示搜索结果数量
        if (!this.showHistory && this.searchResults.length > 0) {
          Text(`搜索(${this.searchResults.length}/${this.searchResults.length})`)
            .style({
              fontSize: 22,
              color: '#FFFFFF',
              paddingHorizontal: 15,
              paddingVertical: 10,
              fontWeight: 600
            })
        }
        
        if (this.isSearching && this.isLoading && this.currentPage === 1) {
          this.renderLoading()
        } else if (this.errorMessage) {
          this.renderError()
        } else if (this.showHistory) {
          Stack({
            style: {
              paddingHorizontal: 15
            }
          }) {
            this.renderHotKeywords()
            this.renderSearchHistory()
          }
        } else {
          this.renderSearchResults()
        }
        
        Blank()
          .style({
            height: 50
          })
      }
    }
  }
}

export default SearchPage;