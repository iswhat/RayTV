
import { Router } from '@ohos.router';
import Logger from '../common/util/Logger';
import { mediaService } from '../service/media/MediaService';
import { Stack, Flex, Text, Button, Image, ScrollView, List, LoadingProgress, Blank, Select, Tag, Empty, ListItem } from '@kit.ArkUI';

/**
 * 媒体项接口定义
 */
interface MediaItem {
  id: string;
  title: string;
  coverUrl?: string;
  description?: string;
  year?: string;
  region?: string;
  score?: string;
  actors?: string[];
  siteKey: string;
}

/**
 * 分类页面组件
 * 实现媒体分类浏览、筛选和列表展示功能
 */
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
    const params = Router.getParams();
    if (params?.['category']) {
      this.selectedCategory = params['category'];
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
    Router.pushUrl({
      url: 'pages/MediaDetailPage',
      params: {
        mediaId: media.id,
        siteKey: media.siteKey
      }
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
    Router.back();
  }
  
  /**
   * 渲染头部
   */
  @Builder
  private renderHeader(): void {
    Stack.create({ className: "header" });
    Button.create({ className: "back-button", onClick: this.handleBack });
    Button.content("←");
    Button.pop();
    Text.create({ className: "page-title" });
    Text.content("分类浏览");
    Text.pop();
    Blank.create({ className: "header-right" });
    Blank.pop();
    Stack.pop();
  }
  
  /**
   * 渲染分类选择器
   */
  @Builder
  private renderCategorySelector(): void {
    ScrollView.create({ className: "category-scroll", scrollBar: "auto" });
    Flex.create({ className: "category-list", wrap: "nowrap" });
    for (let category of this.categories) {
      Button.create({ 
        key: `category-${category}`,
        className: `category-button ${this.selectedCategory === category ? 'selected' : ''}`,
        onClick: () => this.handleCategorySelect(category)
      });
      Text.create();
      Text.content(category);
      Text.pop();
      Button.pop();
    }
    Flex.pop();
    ScrollView.pop();
  }
  
  /**
   * 渲染筛选条件
   */
  @Builder
  private renderFilters(): void {
    Flex.create({ className: "filters-container" });
    Flex.create({ className: "filter-item" });
    Text.create({ className: "filter-label" });
    Text.content("地区");
    Text.pop();
    Select.create({
      value: this.selectedRegion,
      options: this.regions,
      onChange: this.handleRegionSelect,
      className: "filter-select"
    });
    Select.pop();
    Flex.pop();
    Flex.create({ className: "filter-item" });
    Text.create({ className: "filter-label" });
    Text.content("年份");
    Text.pop();
    Select.create({
      value: this.selectedYear,
      options: this.years,
      onChange: this.handleYearSelect,
      className: "filter-select"
    });
    Select.pop();
    Flex.pop();
    Flex.create({ className: "filter-item" });
    Text.create({ className: "filter-label" });
    Text.content("排序");
    Text.pop();
    Select.create({
      value: this.selectedSort,
      options: this.sortOptions,
      onChange: this.handleSortSelect,
      className: "filter-select"
    });
    Select.pop();
    Flex.pop();
    Flex.pop();
  }
  
  /**
   * 渲染媒体项
   */
  @Builder
  private renderMediaItem(media: MediaItem): void {
    ListItem.create({ onClick: () => this.handleMediaItemClick(media) });
    Flex.create({ className: "media-item" });
    Image.create({
      src: media.coverUrl || "https://via.placeholder.com/80x120?text=No+Image",
      className: "media-cover",
      objectFit: "cover"
    });
    Image.pop();
    Flex.create({ className: "media-info", direction: "column" });
    Text.create({ className: "media-title", numberOfLines: 2 });
    Text.content(media.title);
    Text.pop();
    if (media.year) {
      Text.create({ className: "media-year" });
      Text.content(media.year);
      Text.pop();
    }
    if (media.score) {
      Text.create({ className: "media-score" });
      Text.content("评分: " + media.score);
      Text.pop();
    }
    Flex.pop();
    Flex.pop();
    ListItem.pop();
  }
  
  /**
   * 渲染媒体列表
   */
  @Builder
  private renderMediaList(): void {
    if (this.isLoading && this.currentPage === 1) {
      Stack.create({ className: "loading-container" });
      LoadingProgress.create({ className: "loading-progress", color: "#FF4500" });
      LoadingProgress.pop();
      Text.create();
      Text.content("加载中...");
      Text.pop();
      Stack.pop();
      return;
    }
    
    if (this.errorMessage) {
      Stack.create({ className: "error-container" });
      Text.create({ className: "error-icon" });
      Text.content("⚠️");
      Text.pop();
      Text.create({ className: "error-message" });
      Text.content(this.errorMessage);
      Text.pop();
      Button.create({ className: "retry-button", onClick: () => this.loadMediaList(true) });
      Button.content("重试");
      Button.pop();
      Stack.pop();
      return;
    }
    
    if (this.mediaList.length === 0) {
      Empty.create({ className: "empty-container" });
      Text.create();
      Text.content("暂无相关内容");
      Text.pop();
      Empty.pop();
      return;
    }
    
    List.create({
      className: "media-list",
      itemTemplate: this.renderMediaItem,
      data: this.mediaList,
      onScrollBottom: () => this.handleLoadMore(),
      onRefresh: () => this.handleRefresh(),
      refreshing: this.isRefreshing
    });
    List.pop();
  }
  
  /**
   * 渲染加载更多
   */
  @Builder
  private renderLoadMore(): void {
    if (this.isLoading && this.currentPage > 1 && this.hasMoreResults) {
      Stack.create({ className: "load-more-container" });
      LoadingProgress.create({ className: "loading-progress", color: "#FF4500" });
      LoadingProgress.pop();
      Text.create();
      Text.content("加载更多...");
      Text.pop();
      Stack.pop();
    } else if (!this.hasMoreResults && this.mediaList.length > 0) {
      Text.create({ className: "no-more-text" });
      Text.content("没有更多内容了");
      Text.pop();
    }
  }
  
  /**
   * 组件渲染
   */
  build() {
    Stack.create({ className: "category-page" });
    // 页面头部
    this.renderHeader();
    
    // 分类选择
    this.renderCategorySelector();
    
    // 筛选条件
    this.renderFilters();
    
    // 媒体列表
    ScrollView.create({ className: "content-scroll", scrollBar: "auto" });
    this.renderMediaList();
    this.renderLoadMore();
    Blank.create({ className: "bottom-space" });
    Blank.pop();
    ScrollView.pop();
    
    Stack.pop();
  }
}

export default CategoryPage;