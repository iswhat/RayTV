import { AppNavigator } from '../navigation/AppNavigator';
import Logger from '../common/util/Logger';
import MediaService from '../service/media/MediaService';
import { MediaItem } from '../data/bean/MediaItem';
import { AnalyticsService } from '../service/analytics/AnalyticsService';

/**
 * 分类页面组件 | Category page component
 * 实现媒体分类浏览、选择和列表展示功能 | Implement media category browsing, selection and list display functionality
 */
@Entry
@Component
struct CategoryPage {
  private readonly TAG: string = 'CategoryPage';
  
  // 状态管理 | State management
  @State selectedCategory: string = '全部';
  @State selectedRegion: string = '全部';
  @State selectedYear: string = '全部';
  @State selectedSort: string = '最新';
  @State mediaList: MediaItem[] = [];
  @State categories: string[] = ['全部', '电影', '电视剧', '动画', '综艺', '纪录片'];
  @State regions: string[] = ['全部', '国内', '香港', '台湾', '美国', '日本', '韩国', '其他'];
  @State years: string[] = [];
  @State sortOptions: string[] = ['最新', '最热', '评分最高'];
  @State isLoading: boolean = false;
  @State errorMessage: string = '';
  @State currentPage: number = 1;
  @State hasMoreResults: boolean = true;
  @State isRefreshing: boolean = false;
  
  // 分页配置 | Pagination configuration
  private pageSize: number = 20;
  private mediaService: MediaService = MediaService.getInstance();
  private analyticsService: AnalyticsService = AnalyticsService.getInstance();
  
  /**
   * 页面加载时调用 | Called when page loads
   */
  async aboutToAppear(): Promise<void> {
    Logger.info(this.TAG, 'CategoryPage appeared');
    
    // 记录页面访问 | Track page view
    this.analyticsService.trackPageView('CategoryPage');
    
    // 初始化年份选项 | Initialize year options
    const currentYear = new Date().getFullYear();
    // 先构建年份数组，然后添加"全部"选项 | Build year array first, then add "全部" option
    const yearArray: string[] = [];
    yearArray.push('全部');
    for (let i = 0; i < 10; i++) {
      yearArray.push((currentYear - i).toString());
    }
    this.years = yearArray;
    
    // 初始化数据 | Initialize data
    await this.loadMediaList(true);
  }
  
  /**
   * 页面卸载时调用 | Called when page unloads
   */
  aboutToDisappear(): void {
    Logger.info(this.TAG, 'CategoryPage disappeared');
  }
  
  /**
   * 加载媒体列表 | Load media list
   */
  private async loadMediaList(reset: boolean = false): Promise<void> {
    try {
      this.isLoading = true;
      this.errorMessage = '';
      
      if (reset) {
        this.currentPage = 1;
        this.mediaList = [];
      } else if (!this.hasMoreResults) {
        this.isLoading = false;
        return;
      }
      
      const category = this.selectedCategory === '全部' ? '' : this.selectedCategory;
      const region = this.selectedRegion === '全部' ? '' : this.selectedRegion;
      const year = this.selectedYear === '全部' ? '' : this.selectedYear;
      
      Logger.info(this.TAG, `Loading media list: category=${category}, region=${region}, year=${year}, sort=${this.selectedSort}, page=${this.currentPage}`);
      
      // 调用MediaService获取真实数据 | Call MediaService to get real data
      const result = await this.mediaService.getCategoryMedia({
        category: category,
        region: region,
        year: year,
        sort: this.selectedSort,
        page: this.currentPage,
        pageSize: this.pageSize
      });
      
      if (result.isSuccess() && result.data) {
        const newMediaItems = result.data;
        
        if (reset) {
          this.mediaList = newMediaItems;
        } else {
          this.mediaList = [...this.mediaList, ...newMediaItems];
        }
        
        // 判断是否还有更多数据 | Determine if there are more results
        this.hasMoreResults = newMediaItems.length === this.pageSize;
        
        Logger.info(this.TAG, `Media list loaded, total: ${this.mediaList.length}, has more: ${this.hasMoreResults}`);
      } else {
        this.errorMessage = result.message || '加载失败，请稍后重试';
        this.hasMoreResults = false;
        Logger.warn(this.TAG, `Failed to load media list: ${this.errorMessage}`);
      }
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      Logger.error(this.TAG, `Failed to load media list: ${errorMsg}`);
      this.errorMessage = '加载失败，请稍后重试';
      this.hasMoreResults = false;
    } finally {
      this.isLoading = false;
      this.isRefreshing = false;
    }
  }
  
  /**
   * 处理筛选条件变化 | Handle filter condition changes
   */
  private async handleFilterChange(): Promise<void> {
    this.currentPage = 1;
    this.mediaList = [];
    this.hasMoreResults = true;
    await this.loadMediaList(true);
  }
  
  /**
   * 处理分类选择 | Handle category selection
   */
  private async handleCategorySelect(category: string): Promise<void> {
    if (this.selectedCategory !== category) {
      this.selectedCategory = category;
      // 记录分类选择事件 | Track category selection event
      this.analyticsService.trackPageView(`Category_Select_${category}`);
      await this.handleFilterChange();
    }
  }
  
  /**
   * 处理地区选择 | Handle region selection
   */
  private async handleRegionSelect(region: string): Promise<void> {
    if (this.selectedRegion !== region) {
      this.selectedRegion = region;
      // 记录地区选择事件 | Track region selection event
      this.analyticsService.trackPageView(`Region_Select_${region}`);
      await this.handleFilterChange();
    }
  }
  
  /**
   * 处理年份选择 | Handle year selection
   */
  private async handleYearSelect(year: string): Promise<void> {
    if (this.selectedYear !== year) {
      this.selectedYear = year;
      // 记录年份选择事件 | Track year selection event
      this.analyticsService.trackPageView(`Year_Select_${year}`);
      await this.handleFilterChange();
    }
  }
  
  /**
   * 处理排序选择 | Handle sort selection
   */
  private async handleSortSelect(sort: string): Promise<void> {
    if (this.selectedSort !== sort) {
      this.selectedSort = sort;
      // 记录排序选择事件 | Track sort selection event
      this.analyticsService.trackPageView(`Sort_Select_${sort}`);
      await this.handleFilterChange();
    }
  }
  
  /**
   * 处理媒体项点击 | Handle media item click
   */
  private handleMediaItemClick(media: MediaItem): void {
    Logger.info(this.TAG, `Media item clicked: ${media.title}`);
    // 记录媒体项点击事件 | Track media item click event
    this.analyticsService.trackPageView(`Category_Media_${media.id}`);
    // 跳转到详情页 | Navigate to detail page
    AppNavigator.getInstance().navigateToDetail({
      id: media.id,
      siteKey: media.siteKey,
      type: 'vod'
    });
  }
  
  /**
   * 处理加载更多 | Handle load more
   */
  private async handleLoadMore(): Promise<void> {
    if (!this.isLoading && this.hasMoreResults) {
      this.currentPage++;
      await this.loadMediaList(false);
    }
  }
  
  /**
   * 处理刷新 | Handle refresh
   */
  private async handleRefresh(): Promise<void> {
    this.isRefreshing = true;
    await this.loadMediaList(true);
  }
  
  /**
   * 处理返回 | Handle back
   */
  private handleBack(): void {
    // 使用AppNavigator处理返回 | Use AppNavigator to handle back
    AppNavigator.getInstance().navigateToBack();
  }
  
  /**
   * 渲染头部 | Render header
   */
  @Builder
  private renderHeader(): void {
    Row() {
      Button("返回")
        .onClick(() => this.handleBack())
      Text("分类浏览")
        .fontSize(20)
        .fontWeight(700)
      // 使用空的Row作为占位符，类似HTML blank元素 | Use empty Row as placeholder, similar to HTML blank element
      Row() {}
    }
    .justifyContent(FlexAlign.SpaceBetween)
    .padding(20)
  }
  
  /**
   * 渲染分类选择器 | Render category selector
   */
  @Builder
  private renderCategorySelector() {
    Row() {
      ForEach(this.categories, (category: string) => {
        Button(category)
        .onClick(() => this.handleCategorySelect(category))
        .margin(5)
      }, (category: string) => category)
    }
    .padding(5)
  }
  
  /**
   * 渲染筛选条件 | Render filters
   */
  @Builder
  private renderFilters(): void {
    Column() {
      // 地区筛选 | Region filter
      Row() {
        Text("地区:")
          .fontSize(16)
          .fontColor('#333333')
          .margin(10)
        Row() {
          ForEach(this.regions.slice(0, 5), (region: string) => {
            Button(region)
            .onClick(() => this.handleRegionSelect(region))
            .margin(5)
          })
        }
      }
      
      // 年份筛选 | Year filter
      Row() {
        Text("年份:")
          .fontSize(16)
          .fontColor('#333333')
          .margin(10)
        Row() {
          ForEach(this.years.slice(0, 5), (year: string) => {
            Button(year)
            .onClick(() => this.handleYearSelect(year))
            .margin(5)
          })
        }
      }
      
      // 排序筛选 | Sort filter
      Row() {
        Text("排序:")
          .fontSize(16)
          .fontColor('#333333')
          .margin(10)
        Row() {
          ForEach(this.sortOptions.slice(0, 3), (sort: string) => {
            Button(sort)
            .onClick(() => this.handleSortSelect(sort))
            .margin(5)
          })
        }
      }
    }
    .margin(20)
  }
  
  /**
   * 渲染媒体项 | Render media item
   */
  @Builder
  private renderMediaItem(media: MediaItem): void {
    Row() {
      Image(media.coverUrl || "https://via.placeholder.com/80x120?text=No+Image")
        .width(80)
        .height(120)
        .objectFit(ImageFit.Cover)
        .borderRadius(4)
      Column() {
        Text(media.title)
          .fontSize(16)
          .fontColor('#333333')
          .maxLines(2)
        if (media.year) {
          Text(media.year)
            .fontSize(12)
            .fontColor('#666666')
        }
        if (media.score) {
          Text("评分: " + media.score)
            .fontSize(12)
            .fontColor('#FF6B35')
        }
      }
      .justifyContent(FlexAlign.SpaceBetween)
      .height(120)
      .margin({ left: 10 })
    }
    .padding(10)
    .backgroundColor('#F5F5F5')
    .borderRadius(8)
    .margin({ bottom: 10 })
    .onClick(() => this.handleMediaItemClick(media))
  }
  
  /**
   * 渲染媒体列表 | Render media list
   */
  @Builder
  private renderMediaList(): void {
    if (this.isLoading && this.currentPage === 1) {
      Column() {
        Text("加载中...")
          .fontSize(16)
          .fontColor('#333333')
      }
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .padding(20)
    } else if (this.errorMessage) {
      Column() {
        Text("😔")
          .fontSize(24)
        Text(this.errorMessage)
          .fontSize(16)
          .fontColor('#333333')
          .margin({ top: 10 })
        Button("重试")
          .onClick(() => this.loadMediaList(true))
          .margin({ top: 15 })
      }
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .padding(20)
    } else if (this.mediaList.length === 0) {
      Column() {
        Text("暂无相关内容")
          .fontSize(16)
          .fontColor('#333333')
      }
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .padding(20)
    } else {
      List() {
        ForEach(this.mediaList, (item: MediaItem) => {
          ListItem() {
            this.renderMediaItem(item)
          }
        }, (item: MediaItem) => item.id)
      }
      .margin(20)
    }
  }
  
  /**
   * 渲染加载更多 | Render load more
   */
  @Builder
  private renderLoadMore(): void {
    if (this.isLoading && this.currentPage > 1 && this.hasMoreResults) {
      Column() {
        Text("加载更多...")
          .fontSize(16)
          .fontColor('#333333')
      }
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .padding(20)
    } else if (!this.hasMoreResults && this.mediaList.length > 0) {
      Text("没有更多内容啦~")
        .fontSize(14)
        .fontColor('#666666')
        .textAlign(TextAlign.Center)
        .padding(20)
    }
  }
  
  /**
   * 组件渲染 | Component render
   */
  build() {
    Column() {
      // 页面头部 | Page header
      this.renderHeader()
      
      // 分类选择 | Category selection
      this.renderCategorySelector()
      
      // 筛选条件 | Filters
      this.renderFilters()
      
      // 媒体列表 | Media list
      Column() {
        this.renderMediaList()
        this.renderLoadMore()
      }
    }
  }
}
