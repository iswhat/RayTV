
import { AppNavigator, PageRoute } from '../navigation/AppNavigator';
import Logger from '../common/util/Logger';
import { mediaService } from '../service/media/MediaService';
import { Column, Row, Text, Image, Flex, Stack, LoadingProgress, List, ForEach, Button, HorizontalAlign, FlexAlign, ItemAlign, FlexDirection, ImageFit, TextAlign } from '@ohos/arkui';
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
  @State categories: string[] = [];
  @State regions: string[] = [];
  @State years: string[] = [];
  @State sortOptions: string[] = ['最新', '最热', '评分最高', '最早'];
  @State isLoading: boolean = false;
  @State errorMessage: string = '';
  @State currentPage: number = 1;
  @State hasMoreResults: boolean = true;
  @State isRefreshing: boolean = false;
  
  // 分页配置
  private pageSize: number = 20;
  
  /**
   * 页面加载时调用
   */
  aboutToAppear(): void {
    Logger.info(this.TAG, 'CategoryPage appeared');
    
    // 获取路由参数
    const params = this.context.router.getParams();
    if (params?.category) {
      this.selectedCategory = params.category as string;
    }
    
    // 初始化数据
    this.initCategoryData();
    this.loadMediaList(true);
  }
  
  /**
   * 页面卸载时调用
   */
  aboutToDisappear(): void {
    Logger.info(this.TAG, 'CategoryPage disappeared');
  }
  
  /**
   * 初始化分类数据
   */
  private initCategoryData(): void {
    try {
      // 加载分类列表
      mediaService.getCategories()
        .then(categories => {
          this.categories = ['全部', ...categories];
          
          // 加载地区列表
          return mediaService.getRegions();
        })
        .then(regions => {
          this.regions = ['全部', ...regions];
          
          // 加载年份列表 (最近10年)
          const currentYear = new Date().getFullYear();
          this.years = ['全部', ...Array.from({ length: 10 }, (_, i) => (currentYear - i).toString())];
          
          Logger.info(this.TAG, `Loaded categories: ${this.categories.length}, regions: ${this.regions.length}`);
        })
        .catch(error => {
          Logger.error(this.TAG, `Failed to load category data: ${error}`);
          
          // 使用默认数据
          this.categories = ['全部', '电影', '电视剧', '动漫', '综艺', '纪录片'];
          this.regions = ['全部', '内地', '香港', '台湾', '美国', '日本', '韩国', '其他'];
        });
    } catch (error) {
      Logger.error(this.TAG, `Failed to load category data: ${error}`);
      
      // 使用默认数据
      this.categories = ['全部', '电影', '电视剧', '动漫', '综艺', '纪录片'];
      this.regions = ['全部', '内地', '香港', '台湾', '美国', '日本', '韩国', '其他'];
    }
  }
  
  /**
   * 加载媒体列表
   */
  private loadMediaList(reset: boolean = false): void {
    if (this.isLoading) return;
    
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
    
    // 调用媒体服务获取列表
    mediaService.getMediaByCategory(
      category,
      region,
      year,
      this.selectedSort,
      this.currentPage,
      this.pageSize
    )
    .then(result => {
      if (reset) {
        this.mediaList = result;
      } else {
        this.mediaList = [...this.mediaList, ...result];
      }
      
      // 检查是否有更多数据
      this.hasMoreResults = result.length === this.pageSize;
      
      Logger.info(this.TAG, `Media list loaded, total: ${this.mediaList.length}, has more: ${this.hasMoreResults}`);
    })
    .catch(error => {
      Logger.error(this.TAG, `Failed to load media list: ${error}`);
      this.errorMessage = '加载失败，请稍后重试';
      this.hasMoreResults = false;
    })
    .finally(() => {
      this.isLoading = false;
      this.isRefreshing = false;
    });
  }
  
  /**
   * 处理筛选条件变更
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
    this.context.router.back();
  }
  
  /**
   * 渲染头部
   */
  @Builder
  private renderHeader(): void {
    Flex()
    .alignItems(FlexAlign.Center)
    .justifyContent(FlexAlign.SpaceBetween) {
      Button("←")
        .onClick(() => this.handleBack())
      Text("分类浏览")
      // 使用空的Flex作为占位符替代Blank组件
      Flex() {}
    }
  }
  
  /**
   * 渲染分类选择器
   */
  @Builder
  private renderCategorySelector(): void {
    Scroller()
    .scrollable(ScrollDirection.Horizontal) {
      Flex()
      .className("category-list")
      .wrap(FlexWrap.NoWrap) {
        ForEach(this.categories, (category: string) => {
          Button(category)
          .key(`category-${category}`)
          .className(`category-button ${this.selectedCategory === category ? 'selected' : ''}`)
          .onClick(() => this.handleCategorySelect(category))
        }, (category: string) => category)
      }
    }
  }
  
  /**
   * 渲染筛选条件
   */
  @Builder
  private renderFilters(): void {
    Flex()
    .alignItems(FlexAlign.Center)
    .gap(10) {
      // 地区筛选 - 使用按钮组替代Select组件
      Flex()
      .alignItems(FlexAlign.Center) {
        Text("地区:")
          .fontSize(16)
          .fontColor('#333333')
        Flex()
        .alignItems(FlexAlign.Center)
        .gap(5) {
          ForEach(this.regions.slice(0, 5), (region: string) => {
            Button(region)
            .backgroundColor(this.selectedRegion === region ? '#4CAF50' : '#E0E0E0')
            .fontColor(this.selectedRegion === region ? '#FFFFFF' : '#333333')
            .onClick(() => this.handleRegionSelect(region))
          })
        }
      }
      
      // 年份筛选 - 使用按钮组替代Select组件
      Flex()
      .alignItems(FlexAlign.Center) {
        Text("年份:")
          .fontSize(16)
          .fontColor('#333333')
        Flex()
        .alignItems(FlexAlign.Center)
        .gap(5) {
          ForEach(this.years.slice(0, 5), (year: string) => {
            Button(year)
            .backgroundColor(this.selectedYear === year ? '#4CAF50' : '#E0E0E0')
            .fontColor(this.selectedYear === year ? '#FFFFFF' : '#333333')
            .onClick(() => this.handleYearSelect(year))
          })
        }
      }
      
      // 排序筛选 - 使用按钮组替代Select组件
      Flex()
      .alignItems(FlexAlign.Center) {
        Text("排序:")
          .fontSize(16)
          .fontColor('#333333')
        Flex()
        .alignItems(FlexAlign.Center)
        .gap(5) {
          ForEach(this.sortOptions.slice(0, 3), (sort: string) => {
            Button(sort)
            .backgroundColor(this.selectedSort === sort ? '#4CAF50' : '#E0E0E0')
            .fontColor(this.selectedSort === sort ? '#FFFFFF' : '#333333')
            .onClick(() => this.handleSortSelect(sort))
          })
        }
      }
    }
  }
  
  /**
   * 渲染媒体项
   */
  @Builder
  private renderMediaItem(media: MediaItem): void {
    Flex()
    .alignItems(FlexAlign.Start)
    .gap(10)
    .padding(10)
    .backgroundColor('#F5F5F5')
    .borderRadius(8)
    .margin({ bottom: 10 })
    .onClick(() => this.handleMediaItemClick(media)) {
      Image(media.coverUrl || "https://via.placeholder.com/80x120?text=No+Image")
        .width(80)
        .height(120)
        .objectFit(ImageFit.Cover)
        .borderRadius(4)
      Flex()
      .direction(FlexDirection.Column)
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(FlexAlign.Start)
      .height(120) {
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
    }
  }
  
  /**
   * 渲染媒体列表
   */
  @Builder
  private renderMediaList(): void {
    if (this.isLoading && this.currentPage === 1) {
      Stack()
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .padding(20) {
        LoadingProgress()
          .color("#FF4500")
        Text("加载中...")
          .fontSize(16)
          .fontColor('#333333')
          .margin({ top: 10 })
      }
    } else if (this.errorMessage) {
      Stack()
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .padding(20) {
        Text("⚠️")
          .fontSize(24)
        Text(this.errorMessage)
          .fontSize(16)
          .fontColor('#333333')
          .margin({ top: 10 })
        Button("重试")
          .backgroundColor('#4CAF50')
          .fontColor('#FFFFFF')
          .margin({ top: 15 })
          .onClick(() => this.loadMediaList(true))
      }
    } else if (this.mediaList.length === 0) {
      Stack()
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .padding(20) {
        Text("暂无相关内容")
          .fontSize(16)
          .fontColor('#666666')
      }
    } else {
      List() {
        ForEach(this.mediaList, (item: MediaItem) => {
          this.renderMediaItem(item)
        }, (item: MediaItem) => item.id)
      }
      .onScrollBottom(() => this.handleLoadMore())
      .onRefresh(() => this.handleRefresh())
      .refreshing(this.isRefreshing)
    }
  }
  
  /**
   * 渲染加载更多
   */
  @Builder
  private renderLoadMore(): void {
    if (this.isLoading && this.currentPage > 1 && this.hasMoreResults) {
      Stack()
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .padding(20) {
        LoadingProgress()
          .color("#FF4500")
        Text("加载更多...")
          .fontSize(16)
          .fontColor('#333333')
          .margin({ top: 10 })
      }
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
    Stack({ className: "category-page" }) {
      // 页面头部
      this.renderHeader()
      
      // 分类选择
      this.renderCategorySelector()
      
      // 筛选条件
      this.renderFilters()
      
      // 媒体列表
      Column() {
        this.renderMediaList()
        this.renderLoadMore()
        // 使用空的Column作为占位符替代Blank组件
        Column() {}
      }
    }
  }
}

export default CategoryPage;