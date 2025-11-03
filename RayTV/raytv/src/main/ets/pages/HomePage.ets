import { Stack, Flex, List, Grid, GridItem, ScrollView, Image, Text, TextInput, Button, Blank, LoadingProgress, Swiper, SwiperItem, ProgressBar, ListItem } from '@arkui/native';
import { Router } from '@ohos.router';
import Logger from '../common/util/Logger';
import { mediaService } from '../service/media/MediaService';
import { historyService } from '../service/media/HistoryService';
import { favoriteService } from '../service/media/FavoriteService';
import { configService } from '../service/config/ConfigService';
import { ThemeMode } from '../service/config/SettingService';

// 类型定义
export interface MediaItem {
  id: string;
  siteKey: string;
  title: string;
  cover: string;
  coverUrl?: string; // 添加coverUrl属性以兼容现有代码
  type?: string;
  score?: string;
  year?: string;
  status?: string;
  genres: string[];
  actors: string[];
  description?: string; // 添加description属性以兼容轮播图渲染
}

export interface HistoryItem {
  id: string;
  mediaId: string;
  siteKey: string;
  episodeId: string;
  title: string;
  coverUrl: string;
  episodeName: string;
  currentTime: number;
  duration: number;
  lastPlayTime: number;
}

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
  @State pageSize: number = 20;
  
  // 懒加载配置
  private isRefreshing: boolean = false;
  
  // 初始化页面
  aboutToAppear(): void {
    Logger.info(this.TAG, 'HomePage mounted');
    this.initializePage();
  }
  
  // 清理资源
  aboutToDisappear(): void {
    Logger.info(this.TAG, 'HomePage unmounted');
  }
  
  /**
   * 初始化页面
   */
  private initializePage(): void {
    try {
      // 加载配置
      this.loadConfigs();
      
      // 加载页面数据
      this.loadHomeData();
    } catch (error) {
      Logger.error(this.TAG, `Failed to initialize page: ${error}`);
      this.errorMessage = '页面初始化失败，请稍后重试';
    }
  }
  
  /**
   * 加载配置
   */
  private loadConfigs(): void {
    try {
      // 获取主题模式
      configService.getConfig('themeMode').then((value) => {
        this.currentTheme = value || ThemeMode.AUTO;
      });
      
      // 获取首页布局
      configService.getConfig('homePageLayout').then((value) => {
        this.homeLayout = value || 'grid';
      });
      
      // 获取分页大小
      configService.getConfig('pageSize').then((value) => {
        this.pageSize = value || 20;
      });
      
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
  private loadHomeData(): void {
    this.isLoading = true;
    this.errorMessage = '';
    
    try {
      // 并行加载所有数据
      this.loadFeaturedMedia();
      this.loadLatestMedia();
      this.loadPopularMedia();
      this.loadRecentPlays();
      this.loadCategories();
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
  private loadFeaturedMedia(): void {
    try {
      mediaService.getRecommendedMedia(this.pageSize).then((data) => {
        this.featuredMedia = data;
      });
    } catch (error) {
      Logger.error(this.TAG, `Failed to load featured media: ${error}`);
    }
  }
  
  /**
   * 加载最新媒体
   */
  private loadLatestMedia(): void {
    try {
      mediaService.getLatestMedia(this.pageSize).then((data) => {
        this.latestMedia = data;
      });
    } catch (error) {
      Logger.error(this.TAG, `Failed to load latest media: ${error}`);
    }
  }
  
  /**
   * 加载热门媒体
   */
  private loadPopularMedia(): void {
    try {
      mediaService.getPopularMedia(this.pageSize).then((data) => {
        this.popularMedia = data;
      });
    } catch (error) {
      Logger.error(this.TAG, `Failed to load popular media: ${error}`);
    }
  }
  
  /**
   * 加载最近播放
   */
  private loadRecentPlays(): void {
    try {
      configService.getConfig('showRecentPlays').then((showRecentPlays) => {
        if (showRecentPlays !== false) {
          historyService.getRecentHistory(10).then((data) => {
            this.recentPlays = data;
          });
        }
      });
    } catch (error) {
      Logger.error(this.TAG, `Failed to load recent plays: ${error}`);
    }
  }
  
  /**
   * 加载分类列表
   */
  private loadCategories(): void {
    try {
      mediaService.getCategories().then((categoryList) => {
        this.categories = categoryList.slice(0, 12); // 最多显示12个分类
      });
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
  private handleRefresh(): void {
    if (this.isRefreshing) return;
    
    this.isRefreshing = true;
    try {
      this.loadHomeData();
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
  private renderMediaCard(media: MediaItem) {
    GridItem.create({ onClick: () => this.handleMediaItemClick(media) });
     Stack.create({ className: "media-card" });
     Image.create({
       src: media.coverUrl || "https://via.placeholder.com/200x300?text=No+Image",
       className: "media-cover",
       objectFit: "cover",
       alt: media.title
     });
     Image.pop();
    Stack.create({ className: "media-overlay" });
    Text.create({ className: "media-title", numberOfLines: 2 });
    Text.text(media.title);
    Text.pop();
    if (media.year) {
      Text.create({ className: "media-year" });
      Text.text(media.year);
      Text.pop();
    }
    Stack.pop();
    Stack.pop();
    GridItem.pop();
  }
  
  /**
   * 渲染分类项
   */
  @Builder
  private renderCategoryItem(category: { id: string; name: string }) {
    GridItem.create({ onClick: () => this.handleCategoryClick(category) });
    Stack.create({ className: "category-item" });
    Text.create({ className: "category-name", numberOfLines: 1 });
    Text.text(category.name);
    Text.pop();
    Stack.pop();
    GridItem.pop();
  }
  
  /**
   * 渲染历史记录项
   */
  @Builder
  private renderHistoryItem(history: HistoryItem) {
    ListItem.create({ onClick: () => this.handleHistoryItemClick(history) });
    Flex.create({ className: "history-item" });
    Image.create({
        src: history.coverUrl || "https://via.placeholder.com/80x120?text=No+Image",
        className: "history-cover",
        objectFit: "cover"
      });
    Image.pop();
    Flex.create({ className: "history-info", direction: "column" });
    Text.create({ className: "history-title", numberOfLines: 2 });
    Text.text(history.title);
    Text.pop();
    if (history.episodeName) {
      Text.create({ className: "history-episode", numberOfLines: 1 });
      Text.text("第" + history.episodeName);
      Text.pop();
    }
    Text.create({ className: "history-progress" });
    Text.text("观看至: " + this.formatTime(history.currentTime) + " / " + this.formatTime(history.duration));
    Text.pop();
    ProgressBar.create({
      className: "history-progress-bar",
      percent: history.duration > 0 ? (history.currentTime / history.duration) * 100 : 0,
      strokeWidth: 4,
      color: "#FF4500"
    });
    ProgressBar.pop();
    Flex.pop();
    Flex.pop();
    ListItem.pop();
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
  private renderCarousel() {
    if (this.featuredMedia.length === 0) return;
    
    Swiper.create({ className: "carousel", indicatorColor: "#FFFFFF", selectedIndicatorColor: "#FF4500" });
    this.featuredMedia.slice(0, 5).forEach((media) => {
      SwiperItem.create();
      Stack.create({ onClick: () => this.handleMediaItemClick(media) });
      Image.create({
        src: media.coverUrl || "https://via.placeholder.com/800x400?text=No+Image",
        className: "carousel-image",
        objectFit: "cover"
      });
      Image.pop();
      Stack.create({ className: "carousel-overlay" });
      Text.create({ className: "carousel-title" });
      Text.text(media.title);
      Text.pop();
      if (media.description) {
        Text.create({ className: "carousel-description", numberOfLines: 2 });
        Text.text(media.description);
        Text.pop();
      }
      Stack.pop();
      Stack.pop();
      SwiperItem.pop();
    });
    Swiper.pop();
  }
  
  /**
   * 渲染加载状态
   */
  @Builder
  private renderLoading() {
    Stack.create({ className: "loading-container" });
    LoadingProgress.create({ className: "loading-progress", color: "#FF4500" });
    LoadingProgress.pop();
    Text.create({ className: "loading-text" });
    Text.text("加载中...");
    Text.pop();
    Stack.pop();
  }
  
  /**
   * 渲染错误状态
   */
  @Builder
  private renderError() {
    Stack.create({ className: "error-container" });
    Text.create({ className: "error-icon" });
    Text.text("⚠️");
    Text.pop();
    Text.create({ className: "error-message" });
    Text.text(this.errorMessage);
    Text.pop();
    Button.create({ className: "retry-button", onClick: () => this.loadHomeData() });
    Button.text("重试");
    Button.pop();
    Stack.pop();
  }
  
  /**
   * 渲染内容部分
   */
  @Builder
  private renderContent() {
    ScrollView.create({ className: "content-scroll", scrollBar: "auto" });
    
    // 轮播图
    this.renderCarousel();
    
    // 分类区域
    Stack.create({ className: "section" });
    Text.create({ className: "section-title" });
    Text.text("分类");
    Text.pop();
    Button.create({ className: "section-more", onClick: () => Router.push({ url: 'pages/CategoriesPage' }) });
    Button.text("更多");
    Button.pop();
    if (this.categories.length > 0) {
      Grid.create({ className: "categories-grid", columns: 4, itemTemplate: this.renderCategoryItem, data: this.categories });
      Grid.pop();
    }
    Stack.pop();
    
    // 最新更新
    Stack.create({ className: "section" });
    Text.create({ className: "section-title" });
    Text.text("最新更新");
    Text.pop();
    Button.create({ className: "section-more", onClick: () => Router.push({ url: 'pages/LatestPage' }) });
    Button.text("更多");
    Button.pop();
    if (this.latestMedia.length > 0) {
      Grid.create({ 
        className: this.homeLayout === 'grid' ? 'media-grid' : 'media-list', 
        columns: this.homeLayout === 'grid' ? 3 : 1, 
        itemTemplate: this.renderMediaCard, 
        data: this.latestMedia 
      });
      Grid.pop();
    }
    Stack.pop();
    
    // 热门推荐
    Stack.create({ className: "section" });
    Text.create({ className: "section-title" });
    Text.text("热门推荐");
    Text.pop();
    Button.create({ className: "section-more", onClick: () => Router.push({ url: 'pages/PopularPage' }) });
    Button.text("更多");
    Button.pop();
    if (this.popularMedia.length > 0) {
      Grid.create({ 
        className: this.homeLayout === 'grid' ? 'media-grid' : 'media-list', 
        columns: this.homeLayout === 'grid' ? 3 : 1, 
        itemTemplate: this.renderMediaCard, 
        data: this.popularMedia 
      });
      Grid.pop();
    }
    Stack.pop();
    
    // 最近播放
    if (this.recentPlays.length > 0) {
      Stack.create({ className: "section" });
      Text.create({ className: "section-title" });
      Text.text("继续观看");
      Text.pop();
      Button.create({ className: "section-more", onClick: this.navigateToHistory });
      Button.text("更多");
      Button.pop();
      List.create({ className: "history-list", itemTemplate: this.renderHistoryItem, data: this.recentPlays });
      List.pop();
      Stack.pop();
    }
    
    Blank.create({ className: "bottom-space" });
    Blank.pop();
    ScrollView.pop();
  }
  
  /**
   * 组件渲染
   */
  build() {
    Stack.create({ className: "home-page" });
    
    // 顶部搜索栏
    Stack.create({ className: "search-header" });
    Flex.create({ className: "search-bar" });
    TextInput.create({
      className: "search-input",
      value: this.searchQuery,
      onChange: (value) => { this.searchQuery = value; },
      onFocus: () => { this.isSearchFocused = true; },
      onBlur: () => { this.isSearchFocused = false; },
      onSubmit: this.handleSearch,
      placeholder: "搜索电影、电视剧...",
      enterKeyType: "search"
    });
    TextInput.pop();
    Button.create({ className: "search-button", onClick: this.handleSearch });
    Button.text("搜索");
    Button.pop();
    Flex.pop();
    
    Flex.create({ className: "header-actions" });
    Button.create({ className: "header-action", onClick: this.navigateToHistory });
    Button.text("历史");
    Button.pop();
    Button.create({ className: "header-action", onClick: this.navigateToFavorites });
    Button.text("收藏");
    Button.pop();
    Button.create({ className: "header-action", onClick: this.navigateToSettings });
    Button.text("设置");
    Button.pop();
    Flex.pop();
    Stack.pop();
    
    // 主内容区域
    if (this.isLoading) {
      this.renderLoading();
    } else if (this.errorMessage) {
      this.renderError();
    } else {
      this.renderContent();
    }
    
    Stack.pop();
  }
}

export default HomePage;