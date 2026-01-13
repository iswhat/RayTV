import { AppNavigator } from '../navigation/AppNavigator';
import Logger from '../common/util/Logger';
import { SearchService } from '../service/search/SearchService';
import { MediaService } from '../service/media/MediaService';
import display from '@ohos.display';
import { ScrollDirection, BarState, FlexAlign, FlexDirection, ImageFit, TextAlign, VerticalAlign, FlexWrap } from '@ohos/arkui';

// 搜索结果接口 | Search result interface
interface SearchResult {
  id: string;
  title: string;
  type: string;
  cover: string;
  siteKey: string;
  siteName: string;
  rating?: string;
}

// 片源过滤选项 | Source filter option
interface SourceFilter {
  key: string;
  name: string;
  selected: boolean;
}

@Entry
@Component
struct SearchResultPage {
  private readonly TAG: string = 'SearchResultPage';
  private scroller: Scroller = new Scroller();
  private contentScroller: Scroller = new Scroller();
  
  // 状态管理 | State management
  @State searchKeyword: string = '';
  @State searchResults: SearchResult[] = [];
  @State filteredResults: SearchResult[] = [];
  @State sourceFilters: SourceFilter[] = [];
  @State isSearching: boolean = true;
  @State isError: boolean = false;
  @State errorMessage: string = '搜索失败';
  @State isLandscape: boolean = false;
  @State screenWidth: number = 0;
  @State screenHeight: number = 0;
  @State resultItemWidth: number = 200;
  @State resultItemHeight: number = 350;
  
  // 服务实例 | Service instances
  private searchService: SearchService = SearchService.getInstance();
  private mediaService: MediaService = MediaService.getInstance();
  
  // 生命周期 | Lifecycle
  aboutToAppear() {
    Logger.info(this.TAG, 'SearchResultPage about to appear');
    
    // 初始化屏幕信息 | Initialize screen information
    this.initScreenInfo();
    
    // 获取搜索关键词 | Get search keyword
    this.getSearchKeyword();
  }
  
  // 初始化屏幕信息 | Initialize screen information
  private initScreenInfo() {
    try {
      const displayInfo = display.getDefaultDisplaySync();
      this.screenWidth = displayInfo.width;
      this.screenHeight = displayInfo.height;
      this.isLandscape = this.screenWidth > this.screenHeight;
      
      // 根据屏幕方向和宽度计算结果项大小 | Calculate result item size based on screen orientation and width
      if (this.isLandscape) {
        // 横屏模式 | Landscape mode
        this.resultItemWidth = Math.min(240, Math.floor((this.screenWidth - 80) / 6));
        this.resultItemHeight = this.resultItemWidth * 1.5;
      } else {
        // 竖屏模式 | Portrait mode
        this.resultItemWidth = Math.min(180, Math.floor((this.screenWidth - 60) / 2));
        this.resultItemHeight = this.resultItemWidth * 1.5;
      }
      
      Logger.info(this.TAG, `Screen info: width=${this.screenWidth}, height=${this.screenHeight}, landscape=${this.isLandscape}, itemWidth=${this.resultItemWidth}`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to get screen info: ${error}`);
      // 默认值 | Default values
      this.screenWidth = 1920;
      this.screenHeight = 1080;
      this.isLandscape = true;
      this.resultItemWidth = 240;
      this.resultItemHeight = 360;
    }
  }
  
  // 获取搜索关键词 | Get search keyword
  private getSearchKeyword() {
    // 这里应该从路由参数中获取搜索关键词 | Should get search keyword from route parameters
    // 暂时使用默认值，实际实现需要从导航参数中获取 | Temporarily use default value, actual implementation needs to get from navigation parameters
    this.searchKeyword = '测试';
    this.executeSearch();
  }
  
  /**
   * 执行全线路搜索 | Execute full-line search
   */
  private async executeSearch(): Promise<void> {
    if (!this.searchKeyword.trim()) {
      this.isError = true;
      this.errorMessage = '搜索关键词不能为空';
      this.isSearching = false;
      return;
    }
    
    try {
      this.isSearching = true;
      this.isError = false;
      Logger.info(this.TAG, `Executing full-line search for: ${this.searchKeyword}`);
      
      // 调用实际的SearchService执行全线路搜索 | Call actual SearchService to execute full-line search
      const result = await this.searchService.searchAllSources(this.searchKeyword);
      
      if (result.isSuccess() && result.data) {
        this.searchResults = result.data.map(item => ({
          id: item.id,
          title: item.title,
          type: item.type,
          cover: item.cover || '',
          siteKey: item.siteKey || '',
          siteName: item.siteName || '',
          rating: item.rating
        }));
        
        // 初始化片源过滤器 | Initialize source filters
        this.initSourceFilters();
        // 应用过滤器 | Apply filters
        this.applyFilters();
        
        Logger.info(this.TAG, `Search returned ${this.searchResults.length} results from ${this.sourceFilters.length} sources`);
      } else {
        this.isError = true;
        this.errorMessage = result.message || '搜索失败';
        this.searchResults = [];
        this.sourceFilters = [];
        this.filteredResults = [];
        Logger.warn(this.TAG, `Search failed: ${this.errorMessage}`);
      }
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      Logger.error(this.TAG, `Search failed: ${errorMsg}`);
      this.isError = true;
      this.errorMessage = errorMsg;
      this.searchResults = [];
      this.sourceFilters = [];
      this.filteredResults = [];
    } finally {
      this.isSearching = false;
    }
  }
  
  /**
   * 初始化片源过滤器 | Initialize source filters
   */
  private initSourceFilters() {
    // 从搜索结果中提取唯一的片源 | Extract unique sources from search results
    const sources = new Map<string, string>();
    sources.set('all', '全部片源');
    
    this.searchResults.forEach(result => {
      if (result.siteKey && result.siteName) {
        sources.set(result.siteKey, result.siteName);
      }
    });
    
    // 转换为过滤器数组 | Convert to filter array
    this.sourceFilters = Array.from(sources.entries()).map(([key, name]) => ({
      key,
      name,
      selected: key === 'all'
    }));
  }
  
  /**
   * 应用过滤器 | Apply filters
   */
  private applyFilters() {
    const selectedSources = this.sourceFilters
      .filter(filter => filter.selected)
      .map(filter => filter.key);
    
    if (selectedSources.includes('all')) {
      this.filteredResults = [...this.searchResults];
    } else {
      this.filteredResults = this.searchResults.filter(result => 
        selectedSources.includes(result.siteKey)
      );
    }
  }
  
  /**
   * 处理过滤器点击 | Handle filter click
   */
  private handleFilterClick(filter: SourceFilter) {
    if (filter.key === 'all') {
      // 全选或全不选 | Select all or select none
      const allSelected = this.sourceFilters.every(f => f.selected);
      this.sourceFilters.forEach(f => {
        f.selected = !allSelected;
      });
    } else {
      // 切换单个过滤器 | Toggle single filter
      filter.selected = !filter.selected;
      
      // 检查是否所有非全选过滤器都被取消选择 | Check if all non-all filters are deselected
      const hasSelected = this.sourceFilters.some(f => f.key !== 'all' && f.selected);
      if (!hasSelected) {
        this.sourceFilters.find(f => f.key === 'all')!.selected = true;
      } else {
        this.sourceFilters.find(f => f.key === 'all')!.selected = false;
      }
    }
    
    // 应用过滤器 | Apply filters
    this.applyFilters();
    Logger.info(this.TAG, `Filter applied, showing ${this.filteredResults.length} results`);
  }
  
  /**
   * 处理搜索结果点击 | Handle search result click
   */
  private handleResultClick(result: SearchResult) {
    Logger.info(this.TAG, `Result clicked: ${result.title} from ${result.siteName}`);
    
    // 导航到详情页 | Navigate to detail page
    AppNavigator.getInstance().navigateToDetail({
      id: result.id,
      siteKey: result.siteKey,
      type: result.type
    });
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
   * 重新搜索 | Search again
   */
  private searchAgain() {
    this.executeSearch();
  }
  
  // 渲染搜索结果项 | Render search result item
  @Builder
  renderResultItem(result: SearchResult) {
    Column() {
      Image(result.cover || 'https://via.placeholder.com/300x450?text=No+Image')
        .width(this.resultItemWidth)
        .height(this.resultItemWidth * 1.5)
        .objectFit(ImageFit.Cover)
        .borderRadius(12)
        .backgroundColor('#F5F5F5')
        .onError(() => {
          Logger.warn(this.TAG, `Failed to load cover image: ${result.cover}`);
        })
      
      Text(result.title)
        .fontSize(this.isLandscape ? 18 : 16)
        .maxLines(2)
        .margin({ top: 10, left: 4, right: 4 })
        .textAlign(TextAlign.Center)
        .fontColor('#333333')
        .fontWeight(500)
      
      Text(result.siteName)
        .fontSize(this.isLandscape ? 14 : 12)
        .fontColor('#666666')
        .margin({ top: 4 })
      
      if (result.rating) {
        Text(result.rating)
          .fontSize(this.isLandscape ? 14 : 12)
          .fontColor('#FF9800')
          .margin({ top: 2, bottom: 10 })
          .fontWeight(600)
      }
    }
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.15)', offsetY: 4 })
    .onClick(() => this.handleResultClick(result))
    .width(this.resultItemWidth + 24)
    .focusable(true)
    .onFocus(() => {
      Logger.info(this.TAG, `Result item focused: ${result.title}`);
    })
  }
  
  // 渲染片源过滤器 | Render source filters
  @Builder
  renderSourceFilters() {
    if (this.sourceFilters.length > 0) {
      Column() {
        Text('片源筛选')
          .fontSize(20)
          .fontWeight(700)
          .fontColor('#333333')
          .margin({ left: this.isLandscape ? 40 : 30, bottom: 20 })
        
        Scroll(this.scroller) {
          Row() {
            ForEach(this.sourceFilters, (filter: SourceFilter) => {
              Button() {
                Text(filter.name)
                  .fontSize(16)
                  .fontColor(filter.selected ? '#FFFFFF' : '#333333')
                  .fontWeight(filter.selected ? 600 : 400)
              }
              .padding({ left: 24, right: 24, top: 12, bottom: 12 })
              .backgroundColor(filter.selected ? '#4CAF50' : '#F5F5F5')
              .borderRadius(24)
              .margin({ left: this.isLandscape ? 40 : 30, right: 12 })
              .onClick(() => this.handleFilterClick(filter))
              .focusable(true)
              .onFocus(() => {
                Logger.info(this.TAG, `Filter focused: ${filter.name}`);
              })
            })
          }
          .width('100%')
          .padding({ bottom: 24 })
        }
        .scrollDirection(ScrollDirection.Horizontal)
        .scrollBar(BarState.Auto)
        .height(100)
      }
      .width('100%')
      .margin({ top: 20, bottom: 10 })
    }
  }
  
  // 渲染搜索结果 | Render search results
  @Builder
  renderSearchResults() {
    if (this.isSearching) {
      Column() {
        Text('搜索中...')
          .fontSize(24)
          .fontColor('#666666')
          .margin(40)
          .fontWeight(500)
      }
      .justifyContent(FlexAlign.Center)
      .height(this.isLandscape ? '80%' : 500)
    } else if (this.isError) {
      Column() {
        Text('搜索失败')
          .fontSize(24)
          .fontColor('#FF5252')
          .margin({ top: 30 })
          .fontWeight(600)
        Text(this.errorMessage)
          .fontSize(18)
          .fontColor('#FF9800')
          .margin({ top: 12, left: 40, right: 40 })
          .textAlign(TextAlign.Center)
        Row() {
          Button('重试')
            .onClick(() => this.searchAgain())
            .backgroundColor('#4CAF50')
            .fontColor('white')
            .borderRadius(20)
            .padding({ left: 40, right: 40, top: 12, bottom: 12 })
            .margin({ top: 30, right: 20 })
            .fontSize(18)
            .fontWeight(500)
            .focusable(true)
          Button('返回')
            .onClick(() => this.handleBack())
            .backgroundColor('#9E9E9E')
            .fontColor('white')
            .borderRadius(20)
            .padding({ left: 40, right: 40, top: 12, bottom: 12 })
            .margin({ top: 30, left: 20 })
            .fontSize(18)
            .fontWeight(500)
            .focusable(true)
        }
      }
      .justifyContent(FlexAlign.Center)
      .height(this.isLandscape ? '80%' : 500)
    } else if (this.filteredResults.length > 0) {
      Column() {
        Text(`搜索结果: ${this.filteredResults.length} 个 (共 ${this.searchResults.length} 个)`)
          .fontSize(20)
          .fontWeight(700)
          .fontColor('#333333')
          .margin({ left: this.isLandscape ? 40 : 30, top: 25, bottom: 20 })
        
        Scroll(this.contentScroller) {
          Row() {
            ForEach(this.filteredResults, (result: SearchResult) => {
              this.renderResultItem(result);
            })
          }
          .width('100%')
          .padding({ left: this.isLandscape ? 20 : 15, right: this.isLandscape ? 20 : 15, bottom: 40 })
          .flexWrap(FlexWrap.Wrap)
          .justifyContent(FlexAlign.Start)
          .alignItems(FlexAlign.Start)
        }
        .scrollBar(BarState.Auto)
        .flexGrow(1)
      }
      .width('100%')
    } else {
      Column() {
        Text('未找到相关结果')
          .fontSize(24)
          .fontColor('#999999')
          .margin({ top: 30 })
          .fontWeight(500)
        Text(`没有找到与 "${this.searchKeyword}" 相关的内容`)
          .fontSize(18)
          .fontColor('#CCCCCC')
          .margin({ top: 12, left: 40, right: 40 })
          .textAlign(TextAlign.Center)
        Button('返回')
          .onClick(() => this.handleBack())
          .backgroundColor('#4CAF50')
          .fontColor('white')
          .borderRadius(20)
          .padding({ left: 40, right: 40, top: 12, bottom: 12 })
          .margin({ top: 30 })
          .fontSize(18)
          .fontWeight(500)
          .focusable(true)
      }
      .justifyContent(FlexAlign.Center)
      .height(this.isLandscape ? '80%' : 500)
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
        
        // 搜索关键词显示 | Search keyword display
        Text(`搜索: ${this.searchKeyword}`)
          .fontSize(20)
          .fontColor('#333333')
          .flexGrow(1)
          .margin({ left: this.isLandscape ? 40 : 30 })
          .textAlign(TextAlign.Start)
          .fontWeight(600)
        
        // 重新搜索按钮 | Search again button
        Button() {
          Text('重新搜索')
            .fontSize(16)
            .fontColor('#FFFFFF')
            .fontWeight(500)
        }
        .width(140)
        .height(60)
        .backgroundColor('#2196F3')
        .borderRadius(12)
        .margin({ right: this.isLandscape ? 40 : 30 })
        .onClick(() => this.searchAgain())
        .focusable(true)
        .onFocus(() => {
          Logger.info(this.TAG, 'Search again button focused');
        })
      }
      .width('100%')
      .height(80)
      .alignItems(VerticalAlign.Center)
      .backgroundColor('#FFFFFF')
      .borderBottomWidth(2)
      .borderBottomColor('#E0E0E0')
      .shadow({ radius: 4, color: 'rgba(0, 0, 0, 0.1)', offsetY: 2 })
      
      // 片源过滤器 | Source filters
      this.renderSourceFilters()
      
      // 搜索结果 | Search results
      this.renderSearchResults()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
