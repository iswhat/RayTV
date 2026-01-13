import { AppNavigator } from '../navigation/AppNavigator';
import Logger from '../common/util/Logger';
import { SearchHistoryRepository, SearchType } from '../data/repository/SearchHistoryRepository';
import { SearchService } from '../service/search/SearchService';
import { MediaService } from '../service/media/MediaService';
import CacheService, { CachePriority } from '../service/cache/CacheService';
import PinyinUtil from '../common/util/PinyinUtil';
import display from '@ohos.display';
import { ScrollDirection, BarState, FlexAlign, FlexDirection, ImageFit, TextAlign, VerticalAlign, HorizontalAlign } from '@ohos.arkui';

// 搜索结果接口 | Search result interface
export interface SearchResult {
  id: string;
  title: string;
  type: string;
  coverUrl: string;
  siteKey?: string;
}

// 虚拟键盘按键 | Virtual keyboard key
interface KeyboardKey {
  value: string;
  type: 'letter' | 'number' | 'symbol' | 'action';
  label?: string;
}

@Entry
@Component
struct SearchPage {
  private readonly TAG: string = 'SearchPage';
  private scroller: Scroller = new Scroller();
  private contentScroller: Scroller = new Scroller();
  
  // 状态管理 | State management
  @State searchText: string = '';
  @State searchHistory: string[] = [];
  @State hotKeywords: string[] = [];
  @State quickResults: SearchResult[] = [];
  @State pinyinRecommendations: string[] = [];
  @State isSearching: boolean = false;
  @State showQuickResults: boolean = false;
  @State showHistory: boolean = true;
  @State showHotKeywords: boolean = true;
  @State showVirtualKeyboard: boolean = true;
  @State showSystemKeyboard: boolean = false;
  @State isLandscape: boolean = false;
  @State screenWidth: number = 0;
  @State screenHeight: number = 0;
  @State selectedKeyIndex: number = -1;
  
  // 服务实例 | Service instances
  private searchHistoryRepo: SearchHistoryRepository = SearchHistoryRepository.getInstance();
  private searchService: SearchService = SearchService.getInstance();
  private mediaService: MediaService = MediaService.getInstance();
  private cacheService: CacheService = CacheService.getInstance();
  
  // 虚拟键盘按键 | Virtual keyboard keys
  private keyboardKeys: KeyboardKey[] = [
    { value: '1', type: 'number' },
    { value: '2', type: 'number', label: 'ABC' },
    { value: '3', type: 'number', label: 'DEF' },
    { value: '4', type: 'number', label: 'GHI' },
    { value: '5', type: 'number', label: 'JKL' },
    { value: '6', type: 'number', label: 'MNO' },
    { value: '7', type: 'number', label: 'PQRS' },
    { value: '8', type: 'number', label: 'TUV' },
    { value: '9', type: 'number', label: 'WXYZ' },
    { value: '0', type: 'number' },
    { value: 'backspace', type: 'action', label: '删除' },
    { value: 'clear', type: 'action', label: '清空' },
    { value: 'q', type: 'letter' },
    { value: 'w', type: 'letter' },
    { value: 'e', type: 'letter' },
    { value: 'r', type: 'letter' },
    { value: 't', type: 'letter' },
    { value: 'y', type: 'letter' },
    { value: 'u', type: 'letter' },
    { value: 'i', type: 'letter' },
    { value: 'o', type: 'letter' },
    { value: 'p', type: 'letter' },
    { value: 'a', type: 'letter' },
    { value: 's', type: 'letter' },
    { value: 'd', type: 'letter' },
    { value: 'f', type: 'letter' },
    { value: 'g', type: 'letter' },
    { value: 'h', type: 'letter' },
    { value: 'j', type: 'letter' },
    { value: 'k', type: 'letter' },
    { value: 'l', type: 'letter' },
    { value: 'z', type: 'letter' },
    { value: 'x', type: 'letter' },
    { value: 'c', type: 'letter' },
    { value: 'v', type: 'letter' },
    { value: 'b', type: 'letter' },
    { value: 'n', type: 'letter' },
    { value: 'm', type: 'letter' },
    { value: 'space', type: 'action', label: '空格' },
    { value: 'search', type: 'action', label: '搜索' }
  ];
  
  // 生命周期 | Lifecycle
  aboutToAppear() {
    Logger.info(this.TAG, 'SearchPage about to appear');
    
    // 初始化屏幕信息 | Initialize screen information
    this.initScreenInfo();
    
    // 加载热门关键词和搜索历史 | Load hot keywords and search history
    this.loadHotKeywords();
    this.loadSearchHistory();
  }
  
  // 初始化屏幕信息 | Initialize screen information
  private initScreenInfo() {
    try {
      const displayInfo = display.getDefaultDisplaySync();
      this.screenWidth = displayInfo.width;
      this.screenHeight = displayInfo.height;
      this.isLandscape = this.screenWidth > this.screenHeight;
      Logger.info(this.TAG, `Screen info: width=${this.screenWidth}, height=${this.screenHeight}, landscape=${this.isLandscape}`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to get screen info: ${error}`);
      // 默认值 | Default values
      this.screenWidth = 1920;
      this.screenHeight = 1080;
      this.isLandscape = true;
    }
  }
  
  /**
   * 加载热门关键词 | Load hot keywords
   */
  private async loadHotKeywords(): Promise<void> {
    try {
      // 生成缓存键 | Generate cache key
      const cacheKey = 'hot_keywords';
      
      // 尝试从缓存获取 | Try to get from cache
      const cachedKeywords = await this.cacheService.get<string[]>(cacheKey);
      
      if (cachedKeywords && cachedKeywords.length > 0) {
        this.hotKeywords = cachedKeywords;
        Logger.info(this.TAG, `Loaded ${this.hotKeywords.length} hot keywords from cache`);
        return;
      }
      
      // 调用实际的SearchService获取热门关键词 | Call actual SearchService to get hot keywords
      const result = await this.searchService.getHotKeywords();
      if (result.isSuccess() && result.data) {
        this.hotKeywords = result.data;
        
        // 缓存结果 | Cache result
        await this.cacheService.set(cacheKey, this.hotKeywords, {
          expiry: 86400000, // 24小时缓存 24 hours cache
          priority: CachePriority.HIGH,
          tags: ['hot', 'keywords'],
          source: 'SearchService'
        });
      } else {
        // 使用默认热门关键词 | Use default hot keywords
        this.hotKeywords = ['热门电影', '最新剧集', '经典动画', '科幻大片', '爱情喜剧'];
      }
      Logger.info(this.TAG, `Loaded ${this.hotKeywords.length} hot keywords from service`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to load hot keywords: ${error}`);
      this.hotKeywords = ['热门电影', '最新剧集', '经典动画', '科幻大片', '爱情喜剧'];
    }
  }
  
  /**
   * 加载搜索历史 | Load search history
   */
  private async loadSearchHistory(): Promise<void> {
    try {
      // 使用实际的SearchHistoryRepository从本地存储中读取搜索历史 | Use actual SearchHistoryRepository to read search history from local storage
      const historyItems = await this.searchHistoryRepo.getHistory(SearchType.ALL, 10);
      
      // 转换为字符串数组格式 | Convert to string array format
      const history: string[] = [];
      for (let i = 0; i < historyItems.length; i++) {
        history.push(historyItems[i].query);
      }
      this.searchHistory = history;
      Logger.info(this.TAG, `Loaded ${this.searchHistory.length} search history items from repository`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to load search history: ${error instanceof Error ? error.message : String(error)}`);
      this.searchHistory = [];
    }
  }
  
  /**
   * 保存搜索历史 | Save search history
   */
  private async saveSearchHistory(keyword: string): Promise<void> {
    try {
      // 去重并限制数量 | Remove duplicates and limit quantity
      let history = this.searchHistory.filter(item => item !== keyword);
      history.unshift(keyword);
      history = history.slice(0, 10); // 最多保存10条 | Save at most 10 items
      this.searchHistory = history;
      
      // 使用实际的SearchHistoryRepository保存到本地存储 | Use actual SearchHistoryRepository to save to local storage
      await this.searchHistoryRepo.saveSearch(keyword, SearchType.ALL);
      
      Logger.info(this.TAG, `Search history saved: ${keyword}`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to save search history: ${error}`);
    }
  }
  
  /**
   * 处理搜索输入变化 | Handle search input change
   */
  private onSearchTextChange(text: string): void {
    this.searchText = text;
    if (text.length > 0) {
      this.showQuickResults = true;
      // 快速搜索 | Quick search
      this.quickSearch(text);
      // 生成拼音推荐 | Generate pinyin recommendations
      this.generatePinyinRecommendations(text);
    } else {
      this.showQuickResults = false;
      this.quickResults = [];
      this.pinyinRecommendations = [];
    }
  }
  
  /**
   * 生成拼音推荐 | Generate pinyin recommendations
   */
  private generatePinyinRecommendations(text: string): void {
    try {
      // 使用PinyinUtil生成拼音首字母推荐 | Use PinyinUtil to generate pinyin initial letter recommendations
      // 这里应该调用实际的服务获取推荐，这里简化处理 | Should call actual service to get recommendations, simplified here
      this.pinyinRecommendations = [];
      Logger.info(this.TAG, `Generated pinyin recommendations for: ${text}`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to generate pinyin recommendations: ${error}`);
      this.pinyinRecommendations = [];
    }
  }
  
  /**
   * 快速搜索 | Quick search
   */
  private async quickSearch(keyword: string): Promise<void> {
    try {
      this.isSearching = true;
      
      // 生成缓存键 | Generate cache key
      const cacheKey = `quick_search_${keyword}`;
      
      // 尝试从缓存获取 | Try to get from cache
      const cachedResults = await this.cacheService.get<SearchResult[]>(cacheKey);
      
      if (cachedResults && cachedResults.length > 0) {
        this.quickResults = cachedResults;
        Logger.info(this.TAG, `Quick search for '${keyword}' returned ${this.quickResults.length} results from cache`);
        this.isSearching = false;
        return;
      }
      
      // 调用实际的SearchService获取快速搜索结果 | Call actual SearchService to get quick search results
      const result = await this.searchService.quickSearch(keyword);
      if (result.isSuccess() && result.data) {
        this.quickResults = result.data.map(item => ({
          id: item.id,
          title: item.title,
          type: item.type,
          coverUrl: item.cover || '',
          siteKey: item.siteKey
        }));
        
        // 缓存结果 | Cache result
        await this.cacheService.set(cacheKey, this.quickResults, {
          expiry: 300000, // 5分钟缓存 5 minutes cache
          priority: CachePriority.NORMAL,
          tags: ['quick', 'search'],
          source: 'SearchService'
        });
      } else {
        this.quickResults = [];
      }
      Logger.info(this.TAG, `Quick search for '${keyword}' returned ${this.quickResults.length} results from service`);
    } catch (error) {
      Logger.error(this.TAG, `Quick search failed: ${error}`);
      this.quickResults = [];
    } finally {
      this.isSearching = false;
    }
  }
  
  /**
   * 执行搜索 | Execute search
   */
  private async executeSearch(): Promise<void> {
    if (!this.searchText.trim()) return;
    
    try {
      this.isSearching = true;
      this.showQuickResults = false;
      
      // 保存搜索历史 | Save search history
      await this.saveSearchHistory(this.searchText);
      
      // 导航到搜索结果页 | Navigate to search result page
      AppNavigator.getInstance().navigateToSearchResult(this.searchText);
      
      Logger.info(this.TAG, `Executing search for: ${this.searchText}`);
    } catch (error) {
      Logger.error(this.TAG, `Search failed: ${error}`);
    } finally {
      this.isSearching = false;
    }
  }
  
  /**
   * 处理快速搜索结果点击 | Handle quick search result click
   */
  private async handleQuickResultClick(result: SearchResult): Promise<void> {
    try {
      // 保存搜索历史 | Save search history
      await this.saveSearchHistory(this.searchText);
      
      // 跳转到详情页 | Navigate to detail page
      await AppNavigator.getInstance().navigateToDetail({
        id: result.id,
        siteKey: result.siteKey || '',
        type: result.type
      });
      
      Logger.info(this.TAG, `Navigating to detail for ${result.title}`);
    } catch (error) {
      Logger.error(this.TAG, `Error handling quick search result click: ${error}`);
    }
  }
  
  /**
   * 处理热门关键词点击 | Handle hot keyword click
   */
  private async handleHotKeywordClick(keyword: string): Promise<void> {
    try {
      this.searchText = keyword;
      await this.executeSearch();
      Logger.info(this.TAG, `Searching for hot keyword: ${keyword}`);
    } catch (error) {
      Logger.error(this.TAG, `Error handling hot keyword click: ${error}`);
    }
  }
  
  /**
   * 处理搜索历史点击 | Handle search history click
   */
  private async handleHistoryClick(keyword: string): Promise<void> {
    try {
      this.searchText = keyword;
      await this.executeSearch();
      Logger.info(this.TAG, `Searching for history keyword: ${keyword}`);
    } catch (error) {
      Logger.error(this.TAG, `Error handling history click: ${error}`);
    }
  }
  
  /**
   * 处理拼音推荐点击 | Handle pinyin recommendation click
   */
  private async handlePinyinRecommendationClick(recommendation: string): Promise<void> {
    try {
      this.searchText = recommendation;
      await this.executeSearch();
      Logger.info(this.TAG, `Searching for pinyin recommendation: ${recommendation}`);
    } catch (error) {
      Logger.error(this.TAG, `Error handling pinyin recommendation click: ${error}`);
    }
  }
  
  /**
   * 清空搜索历史 | Clear search history
   */
  private async clearSearchHistory(): Promise<void> {
    try {
      this.searchHistory = [];
      // 使用实际的SearchHistoryRepository清空本地存储 | Use actual SearchHistoryRepository to clear local storage
      await this.searchHistoryRepo.clearSearchHistory(SearchType.ALL);
      Logger.info(this.TAG, 'Search history cleared');
    } catch (error) {
      Logger.error(this.TAG, `Failed to clear search history: ${error}`);
    }
  }
  
  /**
   * 处理虚拟键盘按键点击 | Handle virtual keyboard key click
   */
  private handleKeyboardKeyClick(key: KeyboardKey): void {
    switch (key.type) {
      case 'letter':
      case 'number':
      case 'symbol':
        this.onSearchTextChange(this.searchText + key.value);
        break;
      case 'action':
        if (key.value === 'backspace') {
          this.onSearchTextChange(this.searchText.slice(0, -1));
        } else if (key.value === 'clear') {
          this.onSearchTextChange('');
        } else if (key.value === 'space') {
          this.onSearchTextChange(this.searchText + ' ');
        } else if (key.value === 'search') {
          this.executeSearch();
        }
        break;
    }
  }
  
  /**
   * 处理返回 | Handle back
   */
  private async handleBack(): Promise<void> {
    try {
      await AppNavigator.getInstance().navigateToBack();
      Logger.info(this.TAG, 'Navigating back');
    } catch (error) {
      Logger.error(this.TAG, `Failed to navigate back: ${error}`);
    }
  }
  
  /**
   * 切换键盘类型 | Switch keyboard type
   */
  private toggleKeyboardType(): void {
    this.showVirtualKeyboard = !this.showVirtualKeyboard;
    this.showSystemKeyboard = !this.showSystemKeyboard;
  }
  
  // 渲染搜索栏 | Render search bar
  @Builder
  renderSearchBar() {
    Column() {
      Row() {
        // 返回按钮 | Back button
        Button() {
          Text('返回')
            .fontSize(18)
            .fontColor('#FFFFFF')
        }
        .width(100)
        .height(60)
        .backgroundColor('#007AFF')
        .borderRadius(12)
        .margin({ left: 40 })
        .onClick(() => this.handleBack())
        .focusable(true)
        .focusBorderWidth(2)
        .focusBorderColor('#FFFFFF')
        
        // 搜索输入区域 | Search input area
        Column() {
          Row() {
            Text('搜索: ' + this.searchText)
              .fontSize(20)
              .fontColor('#FFFFFF')
              .flexGrow(1)
              .margin({ left: 24 })
            
            Button() {
              Text('切换键盘')
                .fontSize(16)
                .fontColor('#FFFFFF')
            }
            .width(120)
            .height(48)
            .backgroundColor('#34C759')
            .borderRadius(8)
            .margin({ right: 16 })
            .onClick(() => this.toggleKeyboardType())
            .focusable(true)
            .focusBorderWidth(2)
            .focusBorderColor('#FFFFFF')
          }
          .width('100%')
          .height(70)
          .backgroundColor('#2C2C2C')
          .borderRadius(12)
          .alignItems(VerticalAlign.Center)
          
          // 快速搜索结果 | Quick search results
          if (this.showQuickResults && this.quickResults.length > 0) {
            Scroll(this.contentScroller) {
              Column() {
                ForEach(this.quickResults, (result: SearchResult) => {
                  Row() {
                    Image(result.coverUrl || 'https://via.placeholder.com/100x150?text=No+Image')
                      .width(100)
                      .height(150)
                      .objectFit(ImageFit.Cover)
                      .borderRadius(8)
                      .margin({ right: 20 })
                    
                    Column() {
                      Text(result.title)
                        .fontSize(18)
                        .fontColor('#FFFFFF')
                        .fontWeight(600)
                        .maxLines(2)
                      Text(result.type)
                        .fontSize(16)
                        .fontColor('#8E8E93')
                        .margin({ top: 8 })
                    }
                    .flexGrow(1)
                    
                    Text('>')
                      .fontSize(24)
                      .fontColor('#8E8E93')
                  }
                  .width('100%')
                  .padding(20)
                  .backgroundColor('#1E1E1E')
                  .borderRadius(12)
                  .margin({ top: 12 })
                  .onClick(() => this.handleQuickResultClick(result))
                  .focusable(true)
                  .focusBorderWidth(2)
                  .focusBorderColor('#007AFF')
                })
              }
              .padding(20)
            }
            .scrollBar(BarState.Auto)
            .height(this.isLandscape ? 350 : 300)
            .backgroundColor('#1E1E1E')
            .borderRadius(12)
            .margin({ top: 12 })
          }
        }
        .flexGrow(1)
        .margin({ left: 24, right: 24 })
        
        // 搜索按钮 | Search button
        Button() {
          Text('搜索')
            .fontSize(20)
            .fontColor('#FFFFFF')
            .fontWeight(600)
        }
        .width(120)
        .height(60)
        .backgroundColor('#007AFF')
        .borderRadius(12)
        .margin({ right: 40 })
        .onClick(() => this.executeSearch())
        .focusable(true)
        .focusBorderWidth(2)
        .focusBorderColor('#FFFFFF')
      }
      .width('100%')
      .height(80)
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding({ top: 24 })
  }
  
  // 渲染搜索历史 | Render search history
  @Builder
  renderSearchHistory() {
    if (this.searchHistory.length > 0 && this.showHistory && !this.searchText) {
      Column() {
        Row() {
          Text('搜索历史')
            .fontSize(22)
            .fontColor('#FFFFFF')
            .fontWeight(600)
            .margin({ left: 40 })
          
          Button() {
            Text('清空')
              .fontSize(18)
              .fontColor('#8E8E93')
          }
          .backgroundColor('transparent')
          .margin({ right: 40 })
          .onClick(() => this.clearSearchHistory())
          .focusable(true)
          .focusBorderWidth(2)
          .focusBorderColor('#007AFF')
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .alignItems(VerticalAlign.Center)
        .margin({ bottom: 20 })
        
        Scroll(this.scroller) {
          Row() {
            ForEach(this.searchHistory, (keyword: string) => {
              Button() {
                Text(keyword)
                  .fontSize(18)
                  .fontColor('#FFFFFF')
              }
              .padding({ left: 24, right: 24, top: 12, bottom: 12 })
              .backgroundColor('#2C2C2C')
              .borderRadius(24)
              .margin({ left: 40, right: 16 })
              .onClick(() => this.handleHistoryClick(keyword))
              .focusable(true)
              .focusBorderWidth(2)
              .focusBorderColor('#007AFF')
            })
          }
          .width('100%')
          .padding({ bottom: 24 })
        }
        .scrollDirection(ScrollDirection.Horizontal)
        .scrollBar(BarState.Auto)
      }
      .width('100%')
      .margin({ top: 24 })
    }
  }
  
  // 渲染热门关键词 | Render hot keywords
  @Builder
  renderHotKeywords() {
    if (this.hotKeywords.length > 0 && this.showHotKeywords && !this.searchText) {
      Column() {
        Row() {
          Text('热门搜索')
            .fontSize(22)
            .fontColor('#FFFFFF')
            .fontWeight(600)
            .margin({ left: 40 })
        }
        .width('100%')
        .margin({ bottom: 20 })
        
        Scroll(this.scroller) {
          Row() {
            ForEach(this.hotKeywords, (keyword: string) => {
              Button() {
                Text(keyword)
                  .fontSize(18)
                  .fontColor('#FFFFFF')
              }
              .padding({ left: 30, right: 30, top: 14, bottom: 14 })
              .backgroundColor('#FF9500')
              .borderRadius(28)
              .margin({ left: 40, right: 16 })
              .onClick(() => this.handleHotKeywordClick(keyword))
              .focusable(true)
              .focusBorderWidth(2)
              .focusBorderColor('#FFFFFF')
            })
          }
          .width('100%')
          .padding({ bottom: 24 })
        }
        .scrollDirection(ScrollDirection.Horizontal)
        .scrollBar(BarState.Auto)
      }
      .width('100%')
      .margin({ top: 24 })
    }
  }
  
  // 渲染拼音推荐 | Render pinyin recommendations
  @Builder
  renderPinyinRecommendations() {
    if (this.pinyinRecommendations.length > 0 && this.searchText) {
      Column() {
        Row() {
          Text('拼音推荐')
            .fontSize(20)
            .fontColor('#FFFFFF')
            .fontWeight(600)
            .margin({ left: 40 })
        }
        .width('100%')
        .margin({ bottom: 20 })
        
        Scroll(this.scroller) {
          Row() {
            ForEach(this.pinyinRecommendations, (recommendation: string) => {
              Button() {
                Text(recommendation)
                  .fontSize(18)
                  .fontColor('#FFFFFF')
              }
              .padding({ left: 24, right: 24, top: 12, bottom: 12 })
              .backgroundColor('rgba(0, 122, 255, 0.3)')
              .borderRadius(24)
              .margin({ left: 40, right: 16 })
              .onClick(() => this.handlePinyinRecommendationClick(recommendation))
              .focusable(true)
              .focusBorderWidth(2)
              .focusBorderColor('#007AFF')
            })
          }
          .width('100%')
          .padding({ bottom: 24 })
        }
        .scrollDirection(ScrollDirection.Horizontal)
        .scrollBar(BarState.Auto)
      }
      .width('100%')
      .margin({ top: 24 })
    }
  }
  
  // 渲染虚拟键盘 | Render virtual keyboard
  @Builder
  renderVirtualKeyboard() {
    if (this.showVirtualKeyboard) {
      Column() {
        Row() {
          Text('虚拟键盘')
            .fontSize(18)
            .fontColor('#8E8E93')
            .margin({ left: 40 })
          
          Button() {
            Text('使用系统键盘')
              .fontSize(16)
              .fontColor('#007AFF')
          }
          .backgroundColor('transparent')
          .margin({ right: 40 })
          .onClick(() => this.toggleKeyboardType())
          .focusable(true)
          .focusBorderWidth(2)
          .focusBorderColor('#007AFF')
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .margin({ bottom: 20 })
        
        Column() {
          // 字母数字按键 | Letter and number keys
          Row() {
            ForEach(this.keyboardKeys.slice(0, 10), (key: KeyboardKey) => {
              this.renderKeyboardKey(key);
            })
          }
          .width('100%')
          .margin({ bottom: 12 })
          
          Row() {
            ForEach(this.keyboardKeys.slice(10, 20), (key: KeyboardKey) => {
              this.renderKeyboardKey(key);
            })
          }
          .width('100%')
          .margin({ bottom: 12 })
          
          Row() {
            ForEach(this.keyboardKeys.slice(20, 30), (key: KeyboardKey) => {
              this.renderKeyboardKey(key);
            })
          }
          .width('100%')
          .margin({ bottom: 12 })
          
          Row() {
            ForEach(this.keyboardKeys.slice(30), (key: KeyboardKey) => {
              if (key.value === 'search') {
                Button() {
                  Text(key.label || key.value)
                    .fontSize(20)
                    .fontColor('#FFFFFF')
                    .fontWeight(600)
                }
                .width(240)
                .height(72)
                .backgroundColor('#007AFF')
                .borderRadius(12)
                .margin({ left: 40, right: 12 })
                .onClick(() => this.handleKeyboardKeyClick(key))
                .focusable(true)
                .focusBorderWidth(2)
                .focusBorderColor('#FFFFFF')
              } else {
                this.renderKeyboardKey(key);
              }
            })
          }
          .width('100%')
        }
        .padding({ left: 30, right: 30 })
      }
      .width('100%')
      .padding({ top: 24, bottom: 40 })
      .backgroundColor('#1E1E1E')
    }
  }
  
  // 渲染键盘按键 | Render keyboard key
  @Builder
  renderKeyboardKey(key: KeyboardKey) {
    Button() {
      Column() {
        Text(key.label || key.value)
          .fontSize(key.type === 'action' ? 18 : 20)
          .fontColor('#FFFFFF')
        if (key.label) {
          Text(key.value)
            .fontSize(14)
            .fontColor('#8E8E93')
        }
      }
    }
    .width(96)
    .height(72)
    .backgroundColor('#2C2C2C')
    .borderRadius(12)
    .margin({ right: 12 })
    .onClick(() => this.handleKeyboardKeyClick(key))
    .focusable(true)
    .focusBorderWidth(2)
    .focusBorderColor('#007AFF')
  }
  
  build() {
    Column() {
      // 顶部搜索栏 | Top search bar
      this.renderSearchBar();
      
      // 主内容区域 | Main content area
      Column() {
        // 拼音推荐 | Pinyin recommendations
        this.renderPinyinRecommendations();
        
        // 搜索历史 | Search history
        this.renderSearchHistory();
        
        // 热门关键词 | Hot keywords
        this.renderHotKeywords();
      }
      .flexGrow(1)
      .width('100%')
      .backgroundColor('#121212')
      
      // 虚拟键盘 | Virtual keyboard
      this.renderVirtualKeyboard();
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#121212')
  }
}
