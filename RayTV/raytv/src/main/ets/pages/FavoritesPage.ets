
import { AppNavigator } from '../navigation/AppNavigator';
import Logger from '../common/util/Logger';
import { favoriteService } from '../service/media/FavoriteService';
import { mediaService } from '../service/media/MediaService';
import { Stack, Button, Image, ScrollView, List, LoadingProgress, Blank, Checkbox, Tag, Empty, ListItem } from '@kit.ArkUI';

/**
 * 收藏项接口定�?
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
 * 媒体项接口定�?
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
  
  // 状态管�?
  @State favorites: FavoriteItem[] = [];
  @State mediaItems: Map<string, MediaItem> = new Map();
  @State isLoading: boolean = false;
  @State errorMessage: string = '';
  @State isEditMode: boolean = false;
  @State selectedItems: Set<string> = new Set();
  @State isRefreshing: boolean = false;
  @State sortBy: 'time' | 'title' = 'time';
  
  // 初始�?
  /**
   * 页面加载时调�?
   */
  aboutToAppear(): void {
    Logger.info(this.TAG, 'FavoritesPage appeared');
    this.loadFavorites();
  }

  /**
   * 页面卸载时调�?
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
    
    // 从收藏服务获取收藏列�?
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
        return mediaService.getMediaDetail(fav.id, fav.siteKey instanceof Error ? fav.siteKey : new Error(String(fav.siteKey instanceof Error ? fav.siteKey instanceof Error ? fav.siteKey : new Error(String(fav.siteKey : new Error(String(fav.siteKey instanceof Error ? fav.siteKey : new Error(String(fav.siteKey instanceof Error ? fav.siteKey instanceof Error ? fav.siteKey : new Error(String(fav.siteKey instanceof Error ? fav.siteKey instanceof Error ? fav.siteKey : new Error(String(fav.siteKey : new Error(String(fav.siteKey instanceof Error ? fav.siteKey : new Error(String(fav.siteKey : new Error(String(fav.siteKey instanceof Error ? fav.siteKey : new Error(String(fav.siteKey instanceof Error ? fav.siteKey instanceof Error ? fav.siteKey : new Error(String(fav.siteKey : new Error(String(fav.siteKey instanceof Error ? fav.siteKey : new Error(String(fav.siteKey)))))))
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
      Logger.error(this.TAG, `Failed to load media details: ${error}` instanceof Error ? `Failed to load media details: ${error}` : new Error(String(`Failed to load media details: ${error}` instanceof Error ? `Failed to load media details: ${error}` instanceof Error ? `Failed to load media details: ${error}` : new Error(String(`Failed to load media details: ${error}` : new Error(String(`Failed to load media details: ${error}` instanceof Error ? `Failed to load media details: ${error}` : new Error(String(`Failed to load media details: ${error}` instanceof Error ? `Failed to load media details: ${error}` instanceof Error ? `Failed to load media details: ${error}` : new Error(String(`Failed to load media details: ${error}` instanceof Error ? `Failed to load media details: ${error}` instanceof Error ? `Failed to load media details: ${error}` : new Error(String(`Failed to load media details: ${error}` : new Error(String(`Failed to load media details: ${error}` instanceof Error ? `Failed to load media details: ${error}` : new Error(String(`Failed to load media details: ${error}` : new Error(String(`Failed to load media details: ${error}` instanceof Error ? `Failed to load media details: ${error}` : new Error(String(`Failed to load media details: ${error}` instanceof Error ? `Failed to load media details: ${error}` instanceof Error ? `Failed to load media details: ${error}` : new Error(String(`Failed to load media details: ${error}` : new Error(String(`Failed to load media details: ${error}` instanceof Error ? `Failed to load media details: ${error}` : new Error(String(`Failed to load media details: ${error}`)))))));
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
   * 处理全�?取消全�?
   */
  private handleSelectAll(): void {
    if (this.selectedItems.size === this.favorites.length) {
      this.selectedItems.clear();
    } else {
      this.selectedItems = new Set(this.favorites.map(item => item.id));
    }
  }
  
  /**
   * 处理删除选中�?
   */
  private handleDeleteSelected(): void {
    if (this.selectedItems.size === 0) return;
    
    const idsToDelete = Array.from(this.selectedItems);
    
    // 删除选中的收藏项
    favoriteService.removeFavorites(idsToDelete)
      .then(() => {
        // 更新本地状�?
        this.favorites = this.favorites.filter(fav => !idsToDelete.includes(fav.id));
        idsToDelete.forEach(id => {
          this.mediaItems.delete(id);
          this.selectedItems.delete(id);
        });
        
        Logger.info(this.TAG, `Deleted ${idsToDelete.length} favorites`);
        
        // 如果没有收藏项了，退出编辑模�?
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
   * 处理媒体项点�?
   */
  private handleMediaClick(favorite: FavoriteItem): void {
    if (this.isEditMode) {
      this.handleItemSelect(favorite.id);
      return;
    }
    
    Logger.info(this.TAG, `Favorite clicked: ${favorite.title}` instanceof Error ? `Favorite clicked: ${favorite.title}` : new Error(String(`Favorite clicked: ${favorite.title}` instanceof Error ? `Favorite clicked: ${favorite.title}` instanceof Error ? `Favorite clicked: ${favorite.title}` : new Error(String(`Favorite clicked: ${favorite.title}` : new Error(String(`Favorite clicked: ${favorite.title}` instanceof Error ? `Favorite clicked: ${favorite.title}` : new Error(String(`Favorite clicked: ${favorite.title}` instanceof Error ? `Favorite clicked: ${favorite.title}` instanceof Error ? `Favorite clicked: ${favorite.title}` : new Error(String(`Favorite clicked: ${favorite.title}` instanceof Error ? `Favorite clicked: ${favorite.title}` instanceof Error ? `Favorite clicked: ${favorite.title}` : new Error(String(`Favorite clicked: ${favorite.title}` : new Error(String(`Favorite clicked: ${favorite.title}` instanceof Error ? `Favorite clicked: ${favorite.title}` : new Error(String(`Favorite clicked: ${favorite.title}` : new Error(String(`Favorite clicked: ${favorite.title}` instanceof Error ? `Favorite clicked: ${favorite.title}` : new Error(String(`Favorite clicked: ${favorite.title}` instanceof Error ? `Favorite clicked: ${favorite.title}` instanceof Error ? `Favorite clicked: ${favorite.title}` : new Error(String(`Favorite clicked: ${favorite.title}` : new Error(String(`Favorite clicked: ${favorite.title}` instanceof Error ? `Favorite clicked: ${favorite.title}` : new Error(String(`Favorite clicked: ${favorite.title}`)))))));
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
    Stack({ className: "header" }) {
      Button({ className: "back-button", onClick: this.handleBack }) {
        Text("�?)
      }
      Text("我的收藏").className("page-title")
      Button({ className: "action-button", onClick: this.toggleEditMode }) {
        Text(this.isEditMode ? "取消" : "编辑")
      }
    }
  }
  
  /**
   * 渲染编辑工具�?
   */
  @Builder
  private renderEditToolbar(): void {
    if (!this.isEditMode || this.favorites.length === 0) return;
    
    Flex({ className: "edit-toolbar" }) {
      Flex({ className: "select-all" }) {
        Checkbox({ 
          checked: this.selectedItems.size === this.favorites.length && this.favorites.length > 0,
          onCheckChange: this.handleSelectAll 
        })
        Text("全�?)
      }
      Text("已选择 " + this.selectedItems.size + " �?).className("selected-count")
      Button({ 
        className: "delete-button", 
        onClick: this.handleDeleteSelected,
        disabled: this.selectedItems.size === 0 
      }) {
        Text("删除")
      }
    }
  }
  
  /**
   * 渲染排序选项
   */
  @Builder
  private renderSortOption(): void {
    if (this.isEditMode || this.favorites.length === 0) return;
    
    Flex({ className: "sort-option" }) {
      Text("排序�?)
      Button({ 
        className: `sort-button ${this.sortBy === 'time' ? 'selected' : ''}`,
        onClick: () => {
          this.sortBy = 'time';
          this.loadFavorites();
        }
      }) {
        Text("时间")
      }
      Button({ 
        className: `sort-button ${this.sortBy === 'title' ? 'selected' : ''}`,
        onClick: () => {
          this.sortBy = 'title';
          this.loadFavorites();
        }
      }) {
        Text("标题")
      }
    }
  }
  
  /**
   * 渲染收藏�?
   */
  @Builder
  private renderFavoriteItem(favorite: FavoriteItem): void {
    const media = this.mediaItems.get(favorite.id);
    
    ListItem({ onClick: () => this.handleMediaClick(favorite) }) {
      Flex({ className: "favorite-item" }) {
        if (this.isEditMode) {
          Checkbox({ 
            checked: this.selectedItems.has(favorite.id),
            onCheckChange: () => this.handleItemSelect(favorite.id) 
          })
        }
        Image({
          src: media?.coverUrl || favorite.coverUrl || "https://via.placeholder.com/120x160?text=No+Image",
          className: "media-cover",
          objectFit: "cover"
        })
        Flex({ className: "media-info", direction: "column" }) {
          Text(media?.title || favorite.title).className("media-title").numberOfLines(2)
          Flex({ className: "media-meta" }) {
            if (favorite.type) {
              Tag({ className: "meta-tag" }) {
                Text(favorite.type)
              }
            }
            if (favorite.year) {
              Tag({ className: "meta-tag" }) {
                Text(favorite.year)
              }
            }
            if (media?.score) {
              Tag({ className: "meta-tag score" }) {
                Text(media.score)
              }
            }
          }
          Text("收藏时间: " + new Date(favorite.addTime).toLocaleDateString()).className("add-time")
          if (media?.description) {
            Text(media.description).className("media-description").numberOfLines(2)
          }
        }
      }
    }
  }
  
  /**
   * 渲染收藏列表
   */
  @Builder
  private renderFavoritesList(): void {
    if (this.isLoading && !this.isRefreshing) {
      Stack({ className: "loading-container" }) {
        LoadingProgress({ className: "loading-progress", color: "#FF4500" })
        Text("加载�?..")
      }
      return;
    }
    
    if (this.errorMessage) {
      Stack({ className: "error-container" }) {
        Text("⚠️").className("error-icon")
        Text(this.errorMessage).className("error-message")
        Button({ className: "retry-button", onClick: this.loadFavorites }) {
          Text("重试")
        }
      }
      return;
    }
    
    if (this.favorites.length === 0) {
      Empty({ className: "empty-container" }) {
        Text("🌟").className("empty-icon")
        Text("暂无收藏内容")
        Button({ className: "explore-button", onClick: () => AppNavigator.getInstance().navigateToHome() }) {
          Text("去探�?)
        }
      }
      return;
    }
    
    List({
      className: "favorites-list",
      itemTemplate: this.renderFavoriteItem,
      data: this.favorites,
      onRefresh: () => this.handleRefresh(),
      refreshing: this.isRefreshing
    })
  }
  
  /**
   * 组件渲染
   */
  build() {
    Stack({ className: "favorites-page" }) {
      // 页面头部
      this.renderHeader()
      
      // 编辑工具�?
      this.renderEditToolbar()
      
      // 排序选项
      this.renderSortOption()
      
      // 收藏列表
      ScrollView({ className: "content-scroll", scrollBar: "auto" }) {
        this.renderFavoritesList()
        Blank({ className: "bottom-space" })
      }
    }
  }
}

export default FavoritesPage;


