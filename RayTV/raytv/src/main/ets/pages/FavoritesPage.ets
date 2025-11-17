
import { AppNavigator } from '../navigation/AppNavigator';
import Logger from '../common/util/Logger';
import { favoriteService } from '../service/media/FavoriteService';
import { mediaService } from '../service/media/MediaService';
import { Stack, Flex, Text, Button, Image, ScrollView, List, LoadingProgress, Blank, Checkbox, Tag, Empty, ListItem } from '@kit.ArkUI';

/**
 * 收藏项接口定义
 */
interface FavoriteItem {
  id: string;
  siteKey: string;
  title: string;
  coverUrl?: string;
  type?: string;
  year?: string;
  addTime: string;
}

/**
 * 媒体项接口定义
 */
interface MediaItem {
  id: string;
  siteKey: string;
  title: string;
  coverUrl?: string;
  type?: string;
  year?: string;
  description: string;
  score: string;
  directors: string[];
  actors: string[];
  tags: string[];
  category: string;
  region: string;
  language: string;
  updateTime: string;
  status: string;
}

/**
 * 收藏页面组件
 * 实现收藏媒体的展示、管理、编辑等功能
 */
@Component
struct FavoritesPage {
  private readonly TAG: string = 'FavoritesPage';
  
  // 状态管理
  @State favorites: FavoriteItem[] = [];
  @State mediaItems: Map<string, MediaItem> = new Map();
  @State isLoading: boolean = false;
  @State errorMessage: string = '';
  @State isEditMode: boolean = false;
  @State selectedItems: Set<string> = new Set();
  @State isRefreshing: boolean = false;
  @State sortBy: 'time' | 'title' = 'time';
  
  // 初始化
  /**
   * 页面加载时调用
   */
  aboutToAppear(): void {
    Logger.info(this.TAG, 'FavoritesPage appeared');
    this.loadFavorites();
  }

  /**
   * 页面卸载时调用
   */
  aboutToDisappear(): void {
    Logger.info(this.TAG, 'FavoritesPage disappeared');
  }
  
  /**
   * 加载收藏列表
   */
  private loadFavorites(): void {
    this.isLoading = true;
    this.errorMessage = '';
    
    // 从收藏服务获取收藏列表
    favoriteService.getFavorites()
      .then(favorites => {
        // 根据排序方式排序
        if (this.sortBy === 'time') {
          favorites.sort((a, b) => {
            return new Date(b.addTime).getTime() - new Date(a.addTime).getTime();
          });
        } else if (this.sortBy === 'title') {
          favorites.sort((a, b) => {
            const titleA = this.mediaItems.get(a.id)?.title || a.title;
            const titleB = this.mediaItems.get(b.id)?.title || b.title;
            return titleA.localeCompare(titleB);
          });
        }
        
        this.favorites = favorites;
        
        // 加载媒体详情
        this.loadMediaDetails(favorites);
        
        Logger.info(this.TAG, `Loaded ${this.favorites.length} favorites`);
      })
      .catch(error => {
        Logger.error(this.TAG, `Failed to load favorites: ${error}`);
        this.errorMessage = '加载收藏失败，请稍后重试';
      })
      .finally(() => {
        this.isLoading = false;
        this.isRefreshing = false;
      });
  }
  
  /**
   * 加载媒体详情
   */
  private loadMediaDetails(favorites: FavoriteItem[]): void {
    try {
      // 并行加载媒体详情
      const detailPromises = favorites.map((fav) => {
        return mediaService.getMediaDetail(fav.id, fav.siteKey)
          .then(media => {
            if (media) {
              this.mediaItems.set(fav.id, media);
            }
          })
          .catch(error => {
            Logger.warn(this.TAG, `Failed to load detail for ${fav.id}: ${error}`);
            // 如果加载失败，使用收藏项中的基础信息
            const placeholderMedia: MediaItem = {
              id: fav.id,
              siteKey: fav.siteKey,
              title: fav.title,
              coverUrl: fav.coverUrl,
              type: fav.type,
              year: fav.year,
              description: '',
              score: '',
              directors: [],
              actors: [],
              tags: [],
              category: '',
              region: '',
              language: '',
              updateTime: '',
              status: ''
            };
            this.mediaItems.set(fav.id, placeholderMedia);
          });
      });
      
      Promise.all(detailPromises).catch(error => {
        Logger.error(this.TAG, `Failed in Promise.all: ${error}`);
      });
    } catch (error) {
      Logger.error(this.TAG, `Failed to load media details: ${error}`);
    }
  }
  
  /**
   * 处理返回
   */
  private handleBack(): void {
    this.context.router.back();
  }
  
  /**
   * 处理编辑模式切换
   */
  private toggleEditMode(): void {
    this.isEditMode = !this.isEditMode;
    this.selectedItems.clear();
  }
  
  /**
   * 处理项目选择
   */
  private handleItemSelect(favoriteId: string): void {
    if (this.selectedItems.has(favoriteId)) {
      this.selectedItems.delete(favoriteId);
    } else {
      this.selectedItems.add(favoriteId);
    }
  }
  
  /**
   * 处理全选/取消全选
   */
  private handleSelectAll(): void {
    if (this.selectedItems.size === this.favorites.length) {
      this.selectedItems.clear();
    } else {
      this.selectedItems = new Set(this.favorites.map(item => item.id));
    }
  }
  
  /**
   * 处理删除选中项
   */
  private handleDeleteSelected(): void {
    if (this.selectedItems.size === 0) return;
    
    const idsToDelete = Array.from(this.selectedItems);
    
    // 删除选中的收藏项
    favoriteService.removeFavorites(idsToDelete)
      .then(() => {
        // 更新本地状态
        this.favorites = this.favorites.filter(fav => !idsToDelete.includes(fav.id));
        idsToDelete.forEach(id => {
          this.mediaItems.delete(id);
          this.selectedItems.delete(id);
        });
        
        Logger.info(this.TAG, `Deleted ${idsToDelete.length} favorites`);
        
        // 如果没有收藏项了，退出编辑模式
        if (this.favorites.length === 0) {
          this.isEditMode = false;
        }
      })
      .catch(error => {
        Logger.error(this.TAG, `Failed to delete favorites: ${error}`);
        this.errorMessage = '删除失败，请稍后重试';
      });
  }
  
  /**
   * 处理媒体项点击
   */
  private handleMediaClick(favorite: FavoriteItem): void {
    if (this.isEditMode) {
      this.handleItemSelect(favorite.id);
      return;
    }
    
    Logger.info(this.TAG, `Favorite clicked: ${favorite.title}`);
    // 跳转到详情页
    AppNavigator.getInstance().navigateToDetail({
      id: favorite.id,
      siteKey: favorite.siteKey,
      type: 'vod'
    });
  }
  
  /**
   * 处理排序方式切换
   */
  private handleSortChange(): void {
    this.sortBy = this.sortBy === 'time' ? 'title' : 'time';
    this.loadFavorites();
  }
  
  /**
   * 处理刷新
   */
  private handleRefresh(): void {
    this.isRefreshing = true;
    this.mediaItems.clear();
    this.loadFavorites();
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
    Text.content("我的收藏");
    Text.pop();
    Button.create({ className: "action-button", onClick: this.toggleEditMode });
    Button.content(this.isEditMode ? "取消" : "编辑");
    Button.pop();
    Stack.pop();
  }
  
  /**
   * 渲染编辑工具栏
   */
  @Builder
  private renderEditToolbar(): void {
    if (!this.isEditMode || this.favorites.length === 0) return;
    
    Flex.create({ className: "edit-toolbar" });
    Flex.create({ className: "select-all" });
    Checkbox.create();
    Checkbox.checked(this.selectedItems.size === this.favorites.length && this.favorites.length > 0);
    Checkbox.onCheckChange(this.handleSelectAll);
    Checkbox.pop();
    Text.create();
    Text.content("全选");
    Text.pop();
    Flex.pop();
    Text.create({ className: "selected-count" });
    Text.content("已选择 " + this.selectedItems.size + " 项");
    Text.pop();
    Button.create({ 
      className: "delete-button", 
      onClick: this.handleDeleteSelected,
      disabled: this.selectedItems.size === 0 
    });
    Button.content("删除");
    Button.pop();
    Flex.pop();
  }
  
  /**
   * 渲染排序选项
   */
  @Builder
  private renderSortOption(): void {
    if (this.isEditMode || this.favorites.length === 0) return;
    
    Flex.create({ className: "sort-option" });
    Text.create();
    Text.content("排序：");
    Text.pop();
    Button.create({ 
      className: `sort-button ${this.sortBy === 'time' ? 'selected' : ''}`,
      onClick: () => {
        this.sortBy = 'time';
        this.loadFavorites();
      }
    });
    Button.content("时间");
    Button.pop();
    Button.create({ 
      className: `sort-button ${this.sortBy === 'title' ? 'selected' : ''}`,
      onClick: () => {
        this.sortBy = 'title';
        this.loadFavorites();
      }
    });
    Button.content("标题");
    Button.pop();
    Flex.pop();
  }
  
  /**
   * 渲染收藏项
   */
  @Builder
  private renderFavoriteItem(favorite: FavoriteItem): void {
    const media = this.mediaItems.get(favorite.id);
    
    ListItem.create({ onClick: () => this.handleMediaClick(favorite) });
    Flex.create({ className: "favorite-item" });
    if (this.isEditMode) {
      Checkbox.create();
      Checkbox.checked(this.selectedItems.has(favorite.id));
      Checkbox.onCheckChange(() => this.handleItemSelect(favorite.id));
      Checkbox.pop();
    }
    Image.create({
      src: media?.coverUrl || favorite.coverUrl || "https://via.placeholder.com/120x160?text=No+Image",
      className: "media-cover",
      objectFit: "cover"
    });
    Image.pop();
    Flex.create({ className: "media-info", direction: "column" });
    Text.create({ className: "media-title", numberOfLines: 2 });
    Text.content(media?.title || favorite.title);
    Text.pop();
    Flex.create({ className: "media-meta" });
    if (favorite.type) {
      Tag.create({ className: "meta-tag" });
      Tag.content(favorite.type);
      Tag.pop();
    }
    if (favorite.year) {
      Tag.create({ className: "meta-tag" });
      Tag.content(favorite.year);
      Tag.pop();
    }
    if (media?.score) {
      Tag.create({ className: "meta-tag score" });
      Tag.content(media.score);
      Tag.pop();
    }
    Flex.pop();
    Text.create({ className: "add-time" });
    Text.content("收藏时间: " + new Date(favorite.addTime).toLocaleDateString());
    Text.pop();
    if (media?.description) {
      Text.create({ className: "media-description", numberOfLines: 2 });
      Text.content(media.description);
      Text.pop();
    }
    Flex.pop();
    Flex.pop();
    ListItem.pop();
  }
  
  /**
   * 渲染收藏列表
   */
  @Builder
  private renderFavoritesList(): void {
    if (this.isLoading && !this.isRefreshing) {
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
      Button.create({ className: "retry-button", onClick: this.loadFavorites });
      Button.content("重试");
      Button.pop();
      Stack.pop();
      return;
    }
    
    if (this.favorites.length === 0) {
      Empty.create({ className: "empty-container" });
      Text.create({ className: "empty-icon" });
      Text.content("🌟");
      Text.pop();
      Text.create();
      Text.content("暂无收藏内容");
      Text.pop();
      Button.create({ className: "explore-button", onClick: () => AppNavigator.getInstance().navigateToHome() });
      Button.content("去探索");
      Button.pop();
      Empty.pop();
      return;
    }
    
    List.create({
      className: "favorites-list",
      itemTemplate: this.renderFavoriteItem,
      data: this.favorites,
      onRefresh: () => this.handleRefresh(),
      refreshing: this.isRefreshing
    });
    List.pop();
  }
  
  /**
   * 组件渲染
   */
  build() {
    Stack.create({ className: "favorites-page" });
    // 页面头部
    this.renderHeader();
    
    // 编辑工具栏
    this.renderEditToolbar();
    
    // 排序选项
    this.renderSortOption();
    
    // 收藏列表
    ScrollView.create({ className: "content-scroll", scrollBar: "auto" });
    this.renderFavoritesList();
    Blank.create({ className: "bottom-space" });
    Blank.pop();
    ScrollView.pop();
    
    Stack.pop();
  }
}

export default FavoritesPage;