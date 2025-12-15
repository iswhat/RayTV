import { AppNavigator } from '../navigation/AppNavigator';
import Logger from '../common/util/Logger';
import MediaService from '../service/media/MediaService';
import { MediaItem } from '../data/bean/MediaItem';

/**
 * 分类页面组件
 * 实现媒体分类浏览、筛选和列表展示功能
 */
@Entry
@Component
struct CategoryPage {
  private readonly TAG: string = 'CategoryPage';
  
  // 状态管理
  @State selectedCategory: string = '全部';
  @State selectedRegion: string = '全部';
  @State selectedYear: string = '全部';
  @State selectedSort: string = '最新';
  @State mediaList: MediaItem[] = [];
  @State categories: string[] = ['全部', '电影', '电视剧', '动漫', '综艺', '纪录片'];
  @State regions: string[] = ['全部', '内地', '香港', '台湾', '美国', '日本', '韩国', '其他'];
  @State years: string[] = [];
  @State sortOptions: string[] = ['最新', '最热', '评分最高'];
  @State isLoading: boolean = false;
  @State errorMessage: string = '';
  @State currentPage: number = 1;
  @State hasMoreResults: boolean = true;
  @State isRefreshing: boolean = false;
  
  // 分页配置
  private pageSize: number = 20;
  private mediaService: MediaService = MediaService.getInstance();
  
  /**
   * 页面加载时调用
   */
  aboutToAppear(): void {
    Logger.info(this.TAG, 'CategoryPage appeared');
    
    // 初始化年份选项
    const currentYear = new Date().getFullYear();
    this.years = ['全部', ...Array.from({ length: 10 }, (_, i) => (currentYear - i).toString())];
    
    // 初始化数据
    this.loadMediaList(true);
  }
  
  /**
   * 页面卸载时调用
   */
  aboutToDisappear(): void {
    Logger.info(this.TAG, 'CategoryPage disappeared');
  }
  
  /**
   * 加载媒体列表
   */
  private loadMediaList(reset: boolean = false): void {
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
      
      // 简化实现，直接使用空数组
      this.mediaList = [];
      this.hasMoreResults = false;
      
      Logger.info(this.TAG, `Media list loaded, total: ${this.mediaList.length}, has more: ${this.hasMoreResults}`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to load media list: ${error}`);
      this.errorMessage = '加载失败，请稍后重试';
      this.hasMoreResults = false;
    } finally {
      this.isLoading = false;
      this.isRefreshing = false;
    }
  }
  
  /**
   * 处理筛选条件变化
   */
  private handleFilterChange(): void {
    this.currentPage = 1;
    this.mediaList = [];
    this.hasMoreResults = true;
    this.loadMediaList(true);
  }
  
  /**
   * 处理分类选择
   */
  private handleCategorySelect(category: string): void {
    if (this.selectedCategory !== category) {
      this.selectedCategory = category;
      this.handleFilterChange();
    }
  }
  
  /**
   * 处理地区选择
   */
  private handleRegionSelect(region: string): void {
    if (this.selectedRegion !== region) {
      this.selectedRegion = region;
      this.handleFilterChange();
    }
  }
  
  /**
   * 处理年份选择
   */
  private handleYearSelect(year: string): void {
    if (this.selectedYear !== year) {
      this.selectedYear = year;
      this.handleFilterChange();
    }
  }
  
  /**
   * 处理排序选择
   */
  private handleSortSelect(sort: string): void {
    if (this.selectedSort !== sort) {
      this.selectedSort = sort;
      this.handleFilterChange();
    }
  }
  
  /**
   * 处理媒体项点击
   */
  private handleMediaItemClick(media: MediaItem): void {
    Logger.info(this.TAG, `Media item clicked: ${media.title}`);
    // 跳转到详情页
    AppNavigator.getInstance().navigateToDetail({
      id: media.id,
      siteKey: media.siteKey,
      type: 'vod'
    });
  }
  
  /**
   * 处理加载更多
   */
  private handleLoadMore(): void {
    if (!this.isLoading && this.hasMoreResults) {
      this.currentPage++;
      this.loadMediaList(false);
    }
  }
  
  /**
   * 处理刷新
   */
  private handleRefresh(): void {
    this.isRefreshing = true;
    this.loadMediaList(true);
  }
  
  /**
   * 处理返回
   */
  private handleBack(): void {
    // 使用AppNavigator处理返回
    AppNavigator.getInstance().navigateToBack();
  }
  
  /**
   * 渲染头部
   */
  @Builder
  private renderHeader(): void {
    Row() {
      Button("返回")
        .onClick(() => this.handleBack())
      Text("分类浏览")
        .fontSize(20)
        .fontWeight(700)
      // 使用空的Row作为占位符替代Blank组件
      Row() {}
    }
    .justifyContent(FlexAlign.SpaceBetween)
    .padding(20)
  }
  
  /**
   * 渲染分类选择器
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
   * 渲染筛选条
   */
  @Builder
  private renderFilters(): void {
    Column() {
      // 地区筛选
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
      
      // 年份筛选
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
      
      // 排序筛选
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
   * 渲染媒体项
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
   * 渲染媒体列表
   */
  @Builder
  private renderMediaList(): void {
    if (this.isLoading && this.currentPage === 1) {
      Column() {
        Text("加载中..")
          .fontSize(16)
          .fontColor('#333333')
      }
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .padding(20)
    } else if (this.errorMessage) {
      Column() {
        Text("⚠️")
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
   * 渲染加载更多
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
      Text("没有更多内容了")
        .fontSize(14)
        .fontColor('#666666')
        .textAlign(TextAlign.Center)
        .padding(20)
    }
  }
  
  /**
   * 组件渲染
   */
  build() {
    Column() {
      // 页面头部
      this.renderHeader()
      
      // 分类选择
      this.renderCategorySelector()
      
      // 筛选条
      this.renderFilters()
      
      // 媒体列表
      Column() {
        this.renderMediaList()
        this.renderLoadMore()
      }
    }
  }
}
