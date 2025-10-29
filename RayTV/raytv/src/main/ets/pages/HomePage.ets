import { useState, useEffect, onMounted, onUnmounted } from '@kit.ArkUI';
import { List, Grid, GridItem, ScrollView, Image, Text, TextInput, Button, Blank, LoadingProgress, Swiper, SwiperItem } from '@kit.ArkUI';
import { Router } from '@kit.AbilityKit';
import { mediaService } from '../service/media/MediaService';
import { historyService } from '../service/media/HistoryService';
import { favoriteService } from '../service/media/FavoriteService';
import { configService } from '../service/config/ConfigService';
import { ThemeMode, HomePageLayout } from '../service/config/ConfigService';
import Logger from '@ohos/base/Logger';

/**
 * 首页组件
 * 应用的主界面，展示推荐内容、分类、最近播放等
 */
@Component
struct HomePage {
  private readonly TAG: string = 'HomePage';
  
  // 状态管理
  @State searchQuery: string = '';
  @State isSearchFocused: boolean = false;
  @State isLoading: boolean = false;
  @State featuredMedia: MediaItem[] = [];
  @State latestMedia: MediaItem[] = [];
  @State popularMedia: MediaItem[] = [];
  @State recentPlays: HistoryItem[] = [];
  @State categories: { id: string; name: string }[] = [];
  @State errorMessage: string = '';
  @State currentTheme: ThemeMode = ThemeMode.AUTO;
  @State homeLayout: string = 'grid';
  
  // 懒加载配置
  private pageSize: number = 20;
  private isRefreshing: boolean = false;
  
  // 初始化数据
  onMounted(() => {
    Logger.info(this.TAG, 'HomePage mounted');
    this.initializePage();
  });
  
  // 清理资源
  onUnmounted(() => {
    Logger.info(this.TAG, 'HomePage unmounted');
  });
  
  /**
   * 初始化页面
   */
  private async initializePage(): Promise<void> {
    try {
      // 加载配置
      await this.loadConfigs();
      
      // 加载页面数据
      await this.loadHomeData();
    } catch (error) {
      Logger.error(this.TAG, `Failed to initialize page: ${error}`);
      this.errorMessage = '页面初始化失败，请稍后重试';
    }
  }
  
  /**
   * 加载配置
   */
  private async loadConfigs(): Promise<void> {
    try {
      // 获取主题模式
      this.currentTheme = await configService.getConfig('themeMode') || ThemeMode.AUTO;
      
      // 获取首页布局
      this.homeLayout = await configService.getConfig('homePageLayout') || 'grid';
      
      // 获取分页大小
      this.pageSize = await configService.getConfig('pageSize') || 20;
      
      // 监听配置变化
      configService.addConfigChangeListener('themeMode', (value) => {
        this.currentTheme = value;
      });
      
      configService.addConfigChangeListener('homePageLayout', (value) => {
        this.homeLayout = value;
      });
    } catch (error) {
      Logger.error(this.TAG, `Failed to load configs: ${error}`);
    }
  }
  
  /**
   * 加载首页数据
   */
  private async loadHomeData(): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';
    
    try {
      // 并行加载所有数据
      const promises = [
        this.loadFeaturedMedia(),
        this.loadLatestMedia(),
        this.loadPopularMedia(),
        this.loadRecentPlays(),
        this.loadCategories()
      ];
      
      await Promise.allSettled(promises);
    } catch (error) {
      Logger.error(this.TAG, `Failed to load home data: ${error}`);
      this.errorMessage = '数据加载失败，请检查网络连接';
    } finally {
      this.isLoading = false;
    }
  }
  
  /**
   * 加载精选媒体
   */
  private async loadFeaturedMedia(): Promise<void> {
    try {
      this.featuredMedia = await mediaService.getRecommendedMedia(this.pageSize);
    } catch (error) {
      Logger.error(this.TAG, `Failed to load featured media: ${error}`);
    }
  }
  
  /**
   * 加载最新媒体
   */
  private async loadLatestMedia(): Promise<void> {
    try {
      this.latestMedia = await mediaService.getLatestMedia(this.pageSize);
    } catch (error) {
      Logger.error(this.TAG, `Failed to load latest media: ${error}`);
    }
  }
  
  /**
   * 加载热门媒体
   */
  private async loadPopularMedia(): Promise<void> {
    try {
      this.popularMedia = await mediaService.getPopularMedia(this.pageSize);
    } catch (error) {
      Logger.error(this.TAG, `Failed to load popular media: ${error}`);
    }
  }
  
  /**
   * 加载最近播放
   */
  private async loadRecentPlays(): Promise<void> {
    try {
      const showRecentPlays = await configService.getConfig('showRecentPlays') || true;
      if (showRecentPlays) {
        this.recentPlays = await historyService.getRecentHistory(10);
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to load recent plays: ${error}`);
    }
  }
  
  /**
   * 加载分类列表
   */
  private async loadCategories(): Promise<void> {
    try {
      const categoryList = await mediaService.getCategories();
      this.categories = categoryList.slice(0, 12); // 最多显示12个分类
    } catch (error) {
      Logger.error(this.TAG, `Failed to load categories: ${error}`);
    }
  }
  
  /**
   * 处理搜索
   */
  private handleSearch(): void {
    if (this.searchQuery.trim()) {
      Logger.info(this.TAG, `Searching for: ${this.searchQuery}`);
      // 跳转到搜索结果页
      Router.push({
        url: 'pages/SearchPage',
        params: { query: this.searchQuery.trim() }
      });
    }
  }
  
  /**
   * 处理媒体项点击
   */
  private handleMediaItemClick(mediaItem: MediaItem): void {
    Logger.info(this.TAG, `Media item clicked: ${mediaItem.title}`);
    // 跳转到详情页
    Router.push({
      url: 'pages/MediaDetailPage',
      params: { mediaId: mediaItem.id, siteKey: mediaItem.siteKey }
    });
  }
  
  /**
   * 处理历史记录点击
   */
  private handleHistoryItemClick(historyItem: HistoryItem): void {
    Logger.info(this.TAG, `History item clicked: ${historyItem.title}`);
    // 跳转到播放页
    Router.push({
      url: 'pages/PlaybackPage',
      params: {
        mediaId: historyItem.mediaId,
        siteKey: historyItem.siteKey,
        episodeId: historyItem.episodeId,
        currentTime: historyItem.currentTime
      }
    });
  }
  
  /**
   * 处理分类点击
   */
  private handleCategoryClick(category: { id: string; name: string }): void {
    Logger.info(this.TAG, `Category clicked: ${category.name}`);
    // 跳转到分类页面
    Router.push({
      url: 'pages/CategoryPage',
      params: { categoryId: category.id, categoryName: category.name }
    });
  }
  
  /**
   * 处理刷新
   */
  private async handleRefresh(): Promise<void> {
    if (this.isRefreshing) return;
    
    this.isRefreshing = true;
    try {
      await this.loadHomeData();
    } finally {
      this.isRefreshing = false;
    }
  }
  
  /**
   * 跳转到设置页面
   */
  private navigateToSettings(): void {
    Logger.info(this.TAG, 'Navigating to settings');
    Router.push({
      url: 'pages/SettingsPage'
    });
  }
  
  /**
   * 跳转到历史记录页面
   */
  private navigateToHistory(): void {
    Logger.info(this.TAG, 'Navigating to history');
    Router.push({
      url: 'pages/HistoryPage'
    });
  }
  
  /**
   * 跳转到收藏页面
   */
  private navigateToFavorites(): void {
    Logger.info(this.TAG, 'Navigating to favorites');
    Router.push({
      url: 'pages/FavoritesPage'
    });
  }
  
  /**
   * 渲染媒体卡片
   */
  @Builder
  private renderMediaCard(media: MediaItem): void {
    <GridItem onClick={() => this.handleMediaItemClick(media)}>
      <Stack className="media-card">
        <Image
          src={media.coverUrl || 'https://via.placeholder.com/200x300?text=No+Image'}
          className="media-cover"
          objectFit="cover"
          alt={media.title}
        />
        <Stack className="media-overlay">
          <Text className="media-title" numberOfLines={2}>
            {media.title}
          </Text>
          {media.year && (
            <Text className="media-year">{media.year}</Text>
          )}
        </Stack>
      </Stack>
    </GridItem>
  }
  
  /**
   * 渲染分类项
   */
  @Builder
  private renderCategoryItem(category: { id: string; name: string }): void {
    <GridItem onClick={() => this.handleCategoryClick(category)}>
      <Stack className="category-item">
        <Text className="category-name" numberOfLines={1}>
          {category.name}
        </Text>
      </Stack>
    </GridItem>
  }
  
  /**
   * 渲染历史记录项
   */
  @Builder
  private renderHistoryItem(history: HistoryItem): void {
    <List.Item onClick={() => this.handleHistoryItemClick(history)}>
      <Flex className="history-item">
        <Image
          src={history.coverUrl || 'https://via.placeholder.com/80x120?text=No+Image'}
          className="history-cover"
          objectFit="cover"
        />
        <Flex className="history-info" direction="column">
          <Text className="history-title" numberOfLines={2}>
            {history.title}
          </Text>
          {history.episodeName && (
            <Text className="history-episode" numberOfLines={1}>
              第{history.episodeName}
            </Text>
          )}
          <Text className="history-progress">
            观看至: {this.formatTime(history.currentTime)} / {this.formatTime(history.duration)}
          </Text>
          <Progress
            className="history-progress-bar"
            value={(history.currentTime / history.duration) * 100}
            type="linear"
          />
        </Flex>
      </Flex>
    </List.Item>
  }
  
  /**
   * 格式化时间
   */
  private formatTime(seconds: number): string {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const secs = Math.floor(seconds % 60);
    
    if (hours > 0) {
      return `${hours}:${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
    }
    return `${minutes}:${secs.toString().padStart(2, '0')}`;
  }
  
  /**
   * 渲染轮播图
   */
  @Builder
  private renderCarousel(): void {
    if (this.featuredMedia.length === 0) return;
    
    <Swiper className="carousel" indicatorStyle={{ color: '#FFFFFF', selectedColor: '#FF4500' }}>
      {this.featuredMedia.slice(0, 5).map((media) => (
        <SwiperItem>
          <Stack onClick={() => this.handleMediaItemClick(media)}>
            <Image
              src={media.coverUrl || 'https://via.placeholder.com/800x400?text=No+Image'}
              className="carousel-image"
              objectFit="cover"
            />
            <Stack className="carousel-overlay">
              <Text className="carousel-title">{media.title}</Text>
              {media.description && (
                <Text className="carousel-description" numberOfLines={2}>
                  {media.description}
                </Text>
              )}
            </Stack>
          </Stack>
        </SwiperItem>
      ))}
    </Swiper>
  }
  
  /**
   * 渲染加载状态
   */
  @Builder
  private renderLoading(): void {
    <Stack className="loading-container">
      <LoadingProgress className="loading-progress" color="#FF4500" />
      <Text className="loading-text">加载中...</Text>
    </Stack>
  }
  
  /**
   * 渲染错误状态
   */
  @Builder
  private renderError(): void {
    <Stack className="error-container">
      <Text className="error-icon">⚠️</Text>
      <Text className="error-message">{this.errorMessage}</Text>
      <Button className="retry-button" onClick={() => this.loadHomeData()}>
        重试
      </Button>
    </Stack>
  }
  
  /**
   * 渲染内容部分
   */
  @Builder
  private renderContent(): void {
    <ScrollView className="content-scroll" scrollBar="auto">
      {/* 轮播图 */}
      {this.renderCarousel()}
      
      {/* 分类区域 */}
      <Stack className="section">
        <Text className="section-title">分类</Text>
        <Button className="section-more" onClick={() => Router.push({ url: 'pages/CategoriesPage' })}>
          更多
        </Button>
        {this.categories.length > 0 && (
          <Grid
            className="categories-grid"
            columns={4}
            itemTemplate={this.renderCategoryItem}
            data={this.categories}
          />
        )}
      </Stack>
      
      {/* 最新更新 */}
      <Stack className="section">
        <Text className="section-title">最新更新</Text>
        <Button className="section-more" onClick={() => Router.push({ url: 'pages/LatestPage' })}>
          更多
        </Button>
        {this.latestMedia.length > 0 && (
          <Grid
            className={this.homeLayout === 'grid' ? 'media-grid' : 'media-list'}
            columns={this.homeLayout === 'grid' ? 3 : 1}
            itemTemplate={this.renderMediaCard}
            data={this.latestMedia}
          />
        )}
      </Stack>
      
      {/* 热门推荐 */}
      <Stack className="section">
        <Text className="section-title">热门推荐</Text>
        <Button className="section-more" onClick={() => Router.push({ url: 'pages/PopularPage' })}>
          更多
        </Button>
        {this.popularMedia.length > 0 && (
          <Grid
            className={this.homeLayout === 'grid' ? 'media-grid' : 'media-list'}
            columns={this.homeLayout === 'grid' ? 3 : 1}
            itemTemplate={this.renderMediaCard}
            data={this.popularMedia}
          />
        )}
      </Stack>
      
      {/* 最近播放 */}
      {this.recentPlays.length > 0 && (
        <Stack className="section">
          <Text className="section-title">继续观看</Text>
          <Button className="section-more" onClick={this.navigateToHistory}>
            更多
          </Button>
          <List
            className="history-list"
            itemTemplate={this.renderHistoryItem}
            data={this.recentPlays}
          />
        </Stack>
      )}
      
      <Blank className="bottom-space" />
    </ScrollView>
  }
  
  /**
   * 组件渲染
   */
  build() {
    <Stack className="home-page" theme={this.currentTheme}>
      {/* 顶部搜索栏 */}
      <Stack className="search-header">
        <Flex className="search-bar">
          <TextInput
            className="search-input"
            value={this.searchQuery}
            onChange={(value) => { this.searchQuery = value; }}
            onFocus={() => { this.isSearchFocused = true; }}
            onBlur={() => { this.isSearchFocused = false; }}
            onSubmit={this.handleSearch}
            placeholder="搜索电影、电视剧..."
            enterKeyType="search"
          />
          <Button className="search-button" onClick={this.handleSearch}>
            搜索
          </Button>
        </Flex>
        <Flex className="header-actions">
          <Button className="header-action" onClick={this.navigateToHistory}>
            历史
          </Button>
          <Button className="header-action" onClick={this.navigateToFavorites}>
            收藏
          </Button>
          <Button className="header-action" onClick={this.navigateToSettings}>
            设置
          </Button>
        </Flex>
      </Stack>
      
      {/* 主内容区域 */}
      {this.isLoading ? this.renderLoading() : this.errorMessage ? this.renderError() : this.renderContent()}
    </Stack>
  }
}

export default HomePage;