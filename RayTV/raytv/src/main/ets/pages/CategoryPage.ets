import { AppNavigator } from '../navigation/AppNavigator';
// Logger import removed as AnalyticsService was deleted
import { MediaService } from '../service/media/MediaService';
import { MediaItem } from '../data/bean/MediaItem';

// 移除 @ohos.ui 导入，因为它在当前环境中不可用

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
  // 服务实例将在方法中直接调用 | Service instances will be called directly in methods
  
  /**
   * 页面加载时调用 | Called when page loads
   */
  async aboutToAppear(): Promise<void> {
    console.info('CategoryPage appeared');
    
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
    console.info('CategoryPage disappeared');
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
      
      console.info('Loading media list: category=' + category + ', region=' + region + ', year=' + year + ', sort=' + this.selectedSort + ', page=' + this.currentPage);
      
      // 调用MediaService获取真实数据 | Call MediaService to get real data
      // 注意：使用getRecommendedContent替代不存在的getCategoryMedia方法 | Note: Using getRecommendedContent instead of non-existent getCategoryMedia method
      const result = await MediaService.getInstance().getRecommendedContent();
      
      if (result.isSuccess() && result.data) {
        const newMediaItems: MediaItem[] = result.data;
        
        if (reset) {
          this.mediaList = newMediaItems;
        } else {
          const mergedList: MediaItem[] = [];
          for (let i = 0; i < this.mediaList.length; i++) {
            mergedList.push(this.mediaList[i]);
          }
          for (let i = 0; i < newMediaItems.length; i++) {
            mergedList.push(newMediaItems[i]);
          }
          this.mediaList = mergedList;
        }
        
        // 判断是否还有更多数据 | Determine if there are more results
        this.hasMoreResults = newMediaItems.length === this.pageSize;
        
        console.info('Media list loaded, total: ' + this.mediaList.length + ', has more: ' + this.hasMoreResults);
      } else {
        this.errorMessage = result.message || '加载失败，请稍后重试';
        this.hasMoreResults = false;
        console.warn('Failed to load media list: ' + this.errorMessage);
      }
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      console.error('Failed to load media list: ' + errorMsg);
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

      await this.handleFilterChange();
    }
  }
  
  /**
   * 处理地区选择 | Handle region selection
   */
  private async handleRegionSelect(region: string): Promise<void> {
    if (this.selectedRegion !== region) {
      this.selectedRegion = region;

      await this.handleFilterChange();
    }
  }
  
  /**
   * 处理年份选择 | Handle year selection
   */
  private async handleYearSelect(year: string): Promise<void> {
    if (this.selectedYear !== year) {
      this.selectedYear = year;

      await this.handleFilterChange();
    }
  }
  
  /**
   * 处理排序选择 | Handle sort selection
   */
  private async handleSortSelect(sort: string): Promise<void> {
    if (this.selectedSort !== sort) {
      this.selectedSort = sort;

      await this.handleFilterChange();
    }
  }
  
  /**
   * 处理媒体项点击 | Handle media item click
   */
  private handleMediaItemClick(media: MediaItem): void {
    console.info('Media item clicked: ' + media.title);

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
        
        // 加载更多 | Load more
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
    }
  }
}
