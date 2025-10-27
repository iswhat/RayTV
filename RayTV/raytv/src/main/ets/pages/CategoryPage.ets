import { useState, useEffect, onMounted, onUnmounted } from '@ohos/base';
import { ScrollView, Text, Button, List, ListItem, Image, LoadingProgress, Empty, Flex, Tag, Select } from '@ohos/base/ui';
import { Router } from '@ohos/router';
import { mediaService } from '../service/media/MediaService';
import Logger from '@ohos/base/Logger';

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
  
  // 初始化
  onMounted(() => {
    Logger.info(this.TAG, 'CategoryPage mounted');
    
    // 获取路由参数
    const params = Router.getParams();
    if (params?.['category']) {
      this.selectedCategory = params['category'];
    }
    
    // 初始化数据
    this.initCategoryData();
    this.loadMediaList(true);
  });
  
  // 清理资源
  onUnmounted(() => {
    Logger.info(this.TAG, 'CategoryPage unmounted');
  });
  
  /**
   * 初始化分类数据
   */
  private async initCategoryData(): Promise<void> {
    try {
      // 加载分类列表
      const categories = await mediaService.getCategories();
      this.categories = ['全部', ...categories];
      
      // 加载地区列表
      const regions = await mediaService.getRegions();
      this.regions = ['全部', ...regions];
      
      // 加载年份列表 (最近10年)
      const currentYear = new Date().getFullYear();
      this.years = ['全部', ...Array.from({ length: 10 }, (_, i) => (currentYear - i).toString())];
      
      Logger.info(this.TAG, `Loaded categories: ${this.categories.length}, regions: ${this.regions.length}`);
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
  private async loadMediaList(reset: boolean = false): Promise<void> {
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
    
    try {
      const category = this.selectedCategory === '全部' ? '' : this.selectedCategory;
      const region = this.selectedRegion === '全部' ? '' : this.selectedRegion;
      const year = this.selectedYear === '全部' ? '' : this.selectedYear;
      
      Logger.info(this.TAG, `Loading media list: category=${category}, region=${region}, year=${year}, sort=${this.selectedSort}, page=${this.currentPage}`);
      
      // 调用媒体服务获取列表
      const result = await mediaService.getMediaByCategory(
        category,
        region,
        year,
        this.selectedSort,
        this.currentPage,
        this.pageSize
      );
      
      if (reset) {
        this.mediaList = result;
      } else {
        this.mediaList = [...this.mediaList, ...result];
      }
      
      // 检查是否有更多数据
      this.hasMoreResults = result.length === this.pageSize;
      
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
    Router.push({
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
    <Stack className="header">
      <Button className="back-button" onClick={this.handleBack}>
        ←
      </Button>
      <Text className="page-title">分类浏览</Text>
      <Blank className="header-right" />
    </Stack>
  }
  
  /**
   * 渲染分类选择器
   */
  @Builder
  private renderCategorySelector(): void {
    <ScrollView className="category-scroll" scrollBar="auto">
      <Flex className="category-list" wrap="nowrap">
        {this.categories.map((category) => (
          <Button
            key={`category-${category}`}
            className={`category-button ${this.selectedCategory === category ? 'selected' : ''}`}
            onClick={() => this.handleCategorySelect(category)}
          >
            <Text>{category}</Text>
          </Button>
        ))}
      </Flex>
    </ScrollView>
  }
  
  /**
   * 渲染筛选条件
   */
  @Builder
  private renderFilters(): void {
    <Flex className="filters-container">
      <Flex className="filter-item">
        <Text className="filter-label">地区</Text>
        <Select
          value={this.selectedRegion}
          options={this.regions}
          onChange={this.handleRegionSelect}
          className="filter-select"
        />
      </Flex>
      
      <Flex className="filter-item">
        <Text className="filter-label">年份</Text>
        <Select
          value={this.selectedYear}
          options={this.years}
          onChange={this.handleYearSelect}
          className="filter-select"
        />
      </Flex>
      
      <Flex className="filter-item">
        <Text className="filter-label">排序</Text>
        <Select
          value={this.selectedSort}
          options={this.sortOptions}
          onChange={this.handleSortSelect}
          className="filter-select"
        />
      </Flex>
    </Flex>
  }
  
  /**
   * 渲染媒体项
   */
  @Builder
  private renderMediaItem(media: MediaItem): void {
    <ListItem onClick={() => this.handleMediaItemClick(media)}>
      <Flex className="media-item">
        <Image
          src={media.coverUrl || 'https://via.placeholder.com/120x160?text=No+Image'}
          className="media-cover"
          objectFit="cover"
        />
        <Flex className="media-info" direction="column">
          <Text className="media-title" numberOfLines={2}>{media.title}</Text>
          <Flex className="media-meta">
            {media.year && <Tag className="meta-tag">{media.year}</Tag>}
            {media.region && <Tag className="meta-tag">{media.region}</Tag>}
            {media.score && <Tag className="meta-tag score">{media.score}</Tag>}
          </Flex>
          {media.description && (
            <Text className="media-description" numberOfLines={3}>
              {media.description}
            </Text>
          )}
          {media.actors && media.actors.length > 0 && (
n                        
            <Text className="media-actors" numberOfLines={1}>
              主演: {media.actors.slice(0, 3).join(', ')}
            </Text>
          )}
        </Flex>
      </Flex>
    </ListItem>
  }
  
  /**
   * 渲染媒体列表
   */
  @Builder
  private renderMediaList(): void {
    if (this.isLoading && this.currentPage === 1) {
      <Stack className="loading-container">
        <LoadingProgress className="loading-progress" color="#FF4500" />
        <Text>加载中...</Text>
      </Stack>
      return;
    }
    
    if (this.errorMessage) {
      <Stack className="error-container">
        <Text className="error-icon">⚠️</Text>
        <Text className="error-message">{this.errorMessage}</Text>
        <Button className="retry-button" onClick={() => this.loadMediaList(true)}>
          重试
        </Button>
      </Stack>
      return;
    }
    
    if (this.mediaList.length === 0) {
      <Empty className="empty-container">
        <Text>暂无相关内容</Text>
      </Empty>
      return;
    }
    
    <List
      className="media-list"
      itemTemplate={this.renderMediaItem}
      data={this.mediaList}
      onScrollBottom={() => this.handleLoadMore()}
      onRefresh={() => this.handleRefresh()}
      refreshing={this.isRefreshing}
    />
  }
  
  /**
   * 渲染加载更多
   */
  @Builder
  private renderLoadMore(): void {
    if (this.isLoading && this.currentPage > 1 && this.hasMoreResults) {
      <Stack className="load-more-container">
        <LoadingProgress className="loading-progress" color="#FF4500" />
        <Text>加载更多...</Text>
      </Stack>
    } else if (!this.hasMoreResults && this.mediaList.length > 0) {
      <Text className="no-more-text">没有更多内容了</Text>
    }
  }
  
  /**
   * 组件渲染
   */
  build() {
    <Stack className="category-page">
      {/* 页面头部 */}
      {this.renderHeader()}
      
      {/* 分类选择 */}
      {this.renderCategorySelector()}
      
      {/* 筛选条件 */}
      {this.renderFilters()}
      
      {/* 媒体列表 */}
      <ScrollView className="content-scroll" scrollBar="auto">
        {this.renderMediaList()}
        {this.renderLoadMore()}
        <Blank className="bottom-space" />
      </ScrollView>
    </Stack>
  }
}

export default CategoryPage;