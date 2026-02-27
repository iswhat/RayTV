/**
 * MainViewModel.ts
 * 主页面ViewModel - 实现响应式数据绑定和状态管理
 */

import { MediaItem } from '../data/bean/MediaItem';
import { MediaService } from '../service/media/MediaService';
import { ConfigService } from '../service/config/ConfigService';
import { CacheService } from '../service/cache/CacheService';
import Logger from '../common/util/Logger';

// ==================== 类型定义 ====================

export interface FeaturedMediaItem {
  id: string;
  title: string;
  cover?: string;
  description?: string;
  type: string;
  siteKey: string;
  rating?: string;
  isNew?: boolean;
  isHot?: boolean;
}

export interface TabItem {
  key: string;
  name: string;
}

export interface CategoryTab {
  key: string;
  name: string;
  count?: number;
}

export interface MainViewState {
  // 数据状态
  featuredMedia: FeaturedMediaItem[];
  categories: CategoryTab[];
  
  // UI状态
  isLoading: boolean;
  isError: boolean;
  errorMessage: string;
  selectedTab: string;
  selectedCategory: string;
  isLandscape: boolean;
  
  // 设备状态
  screenWidth: number;
  screenHeight: number;
  currentSite: string;
  showSiteDialog: boolean;
}

// ==================== 响应式状态管理 ====================

class ReactiveProperty<T> {
  private _value: T;
  private subscribers: ((newValue: T, oldValue: T) => void)[] = [];
  
  constructor(initialValue: T) {
    this._value = initialValue;
  }
  
  get value(): T {
    return this._value;
  }
  
  set value(newValue: T) {
    const oldValue = this._value;
    if (newValue !== oldValue) {
      this._value = newValue;
      this.notifySubscribers(newValue, oldValue);
    }
  }
  
  subscribe(callback: (newValue: T, oldValue: T) => void): () => void {
    this.subscribers.push(callback);
    // 立即执行一次回调
    callback(this._value, this._value);
    
    // 返回取消订阅函数
    return () => {
      const index = this.subscribers.indexOf(callback);
      if (index > -1) {
        this.subscribers.splice(index, 1);
      }
    };
  }
  
  private notifySubscribers(newValue: T, oldValue: T): void {
    this.subscribers.forEach(callback => {
      try {
        callback(newValue, oldValue);
      } catch (error) {
        Logger.error('MainViewModel', `Subscriber callback error: ${error}`);
      }
    });
  }
}

// ==================== MainViewModel实现 ====================

export class MainViewModel {
  private readonly TAG: string = 'MainViewModel';
  
  // 服务实例
  private mediaService: MediaService;
  private configService: ConfigService;
  private cacheService: CacheService;
  
  // 响应式状态属性
  public readonly featuredMedia = new ReactiveProperty<FeaturedMediaItem[]>([]);
  public readonly categories = new ReactiveProperty<CategoryTab[]>([]);
  public readonly isLoading = new ReactiveProperty<boolean>(true);
  public readonly isError = new ReactiveProperty<boolean>(false);
  public readonly errorMessage = new ReactiveProperty<string>('');
  public readonly selectedTab = new ReactiveProperty<string>('vod');
  public readonly selectedCategory = new ReactiveProperty<string>('全部');
  public readonly isLandscape = new ReactiveProperty<boolean>(false);
  public readonly screenWidth = new ReactiveProperty<number>(0);
  public readonly screenHeight = new ReactiveProperty<number>(0);
  public readonly currentSite = new ReactiveProperty<string>('默认片源');
  public readonly showSiteDialog = new ReactiveProperty<boolean>(false);
  
  // 计算属性
  public readonly filteredMedia = new ReactiveProperty<FeaturedMediaItem[]>([]);
  
  constructor() {
    this.mediaService = MediaService.getInstance();
    this.configService = ConfigService.getInstance();
    this.cacheService = CacheService.getInstance();
    
    // 初始化计算属性
    this.setupComputedProperties();
    
    Logger.info(this.TAG, 'MainViewModel initialized');
  }
  
  // ==================== 计算属性设置 ====================
  
  private setupComputedProperties(): void {
    // 根据选中的分类过滤媒体内容
    this.selectedCategory.subscribe((newCategory) => {
      this.filterMediaByCategory(newCategory);
    });
    
    // 当媒体数据变化时重新过滤
    this.featuredMedia.subscribe(() => {
      this.filterMediaByCategory(this.selectedCategory.value);
    });
  }
  
  private filterMediaByCategory(category: string): void {
    const allMedia = this.featuredMedia.value;
    
    if (category === '全部') {
      this.filteredMedia.value = [...allMedia];
    } else {
      this.filteredMedia.value = allMedia.filter(media => 
        media.type === category || category === '热门'
      );
    }
  }
  
  // ==================== 数据加载方法 ====================
  
  /**
   * 初始化视图模型
   */
  public async initialize(): Promise<void> {
    Logger.info(this.TAG, 'Initializing MainViewModel');
    
    try {
      this.isLoading.value = true;
      this.isError.value = false;
      
      // 并行加载多个数据源
      await Promise.all([
        this.loadFeaturedMedia(),
        this.loadCategories(),
        this.loadCurrentSite()
      ]);
      
      Logger.info(this.TAG, 'MainViewModel initialized successfully');
    } catch (error) {
      Logger.error(this.TAG, `Initialization failed: ${error}`);
      this.handleError('初始化失败', error);
    } finally {
      this.isLoading.value = false;
    }
  }
  
  /**
   * 加载推荐媒体内容
   */
  private async loadFeaturedMedia(): Promise<void> {
    try {
      Logger.info(this.TAG, 'Loading featured media');
      
      // 从缓存获取或从服务加载
      const cacheKey = 'featured_media';
      let mediaData = await this.cacheService.get<FeaturedMediaItem[]>(cacheKey);
      
      if (!mediaData || mediaData.length === 0) {
        const result = await this.mediaService.getRecommendedContent();
        
        if (result.isSuccess() && result.data) {
          mediaData = result.data.map(item => ({
            id: item.id,
            title: item.title,
            cover: item.cover,
            description: item.description,
            type: item.type || 'movie',
            siteKey: item.siteKey,
            rating: item.rating,
            isNew: Math.random() > 0.7, // 模拟新内容标记
            isHot: Math.random() > 0.8   // 模拟热门内容标记
          }));
          
          // 缓存数据
          await this.cacheService.set(cacheKey, mediaData, 300); // 5分钟缓存
        }
      }
      
      this.featuredMedia.value = mediaData || [];
      Logger.info(this.TAG, `Loaded ${this.featuredMedia.value.length} featured media items`);
      
    } catch (error) {
      Logger.error(this.TAG, `Failed to load featured media: ${error}`);
      throw error;
    }
  }
  
  /**
   * 加载分类数据
   */
  private async loadCategories(): Promise<void> {
    try {
      Logger.info(this.TAG, 'Loading categories');
      
      const categoryData: CategoryTab[] = [
        { key: '全部', name: '全部' },
        { key: 'movie', name: '电影' },
        { key: 'tv', name: '电视剧' },
        { key: 'variety', name: '综艺' },
        { key: 'anime', name: '动漫' },
        { key: 'documentary', name: '纪录片' }
      ];
      
      this.categories.value = categoryData;
      Logger.info(this.TAG, `Loaded ${categoryData.length} categories`);
      
    } catch (error) {
      Logger.error(this.TAG, `Failed to load categories: ${error}`);
      throw error;
    }
  }
  
  /**
   * 加载当前站点信息
   */
  private async loadCurrentSite(): Promise<void> {
    try {
      const currentSite = await this.configService.getCurrentSite();
      this.currentSite.value = currentSite?.name || '默认片源';
      Logger.info(this.TAG, `Current site: ${this.currentSite.value}`);
    } catch (error) {
      Logger.warn(this.TAG, `Failed to load current site: ${error}`);
      this.currentSite.value = '默认片源';
    }
  }
  
  // ==================== 用户交互方法 ====================
  
  /**
   * 处理标签页切换
   */
  public handleTabChange(tabKey: string): void {
    Logger.info(this.TAG, `Tab changed to: ${tabKey}`);
    this.selectedTab.value = tabKey;
    
    // 根据标签页类型可能需要加载不同数据
    switch (tabKey) {
      case 'vod':
        this.loadVodContent();
        break;
      case 'live':
        this.loadLiveContent();
        break;
      case 'search':
        this.navigateToSearch();
        break;
      case 'history':
        this.navigateToHistory();
        break;
      case 'config':
        this.navigateToConfig();
        break;
      case 'settings':
        this.navigateToSettings();
        break;
    }
  }
  
  /**
   * 处理分类选择
   */
  public handleCategorySelect(categoryKey: string): void {
    Logger.info(this.TAG, `Category selected: ${categoryKey}`);
    this.selectedCategory.value = categoryKey;
  }
  
  /**
   * 处理媒体项点击
   */
  public handleMediaItemClick(media: FeaturedMediaItem): void {
    Logger.info(this.TAG, `Media item clicked: ${media.title}`);
    // 导航到详情页面的逻辑将在页面组件中实现
    this.navigateToDetail(media);
  }
  
  /**
   * 处理站点切换
   */
  public async handleSiteSwitch(): Promise<void> {
    Logger.info(this.TAG, 'Site switch requested');
    this.showSiteDialog.value = true;
  }
  
  /**
   * 更新屏幕方向
   */
  public updateOrientation(isLandscape: boolean): void {
    this.isLandscape.value = isLandscape;
    Logger.info(this.TAG, `Orientation updated: ${isLandscape ? 'landscape' : 'portrait'}`);
  }
  
  /**
   * 更新屏幕尺寸
   */
  public updateScreenSize(width: number, height: number): void {
    this.screenWidth.value = width;
    this.screenHeight.value = height;
    Logger.info(this.TAG, `Screen size updated: ${width}x${height}`);
  }
  
  // ==================== 导航方法 ====================
  
  private loadVodContent(): void {
    // 加载点播内容逻辑
    Logger.info(this.TAG, 'Loading VOD content');
  }
  
  private loadLiveContent(): void {
    // 加载直播内容逻辑
    Logger.info(this.TAG, 'Loading live content');
  }
  
  private navigateToSearch(): void {
    // 导航到搜索页面
    Logger.info(this.TAG, 'Navigate to search page');
  }
  
  private navigateToHistory(): void {
    // 导航到历史页面
    Logger.info(this.TAG, 'Navigate to history page');
  }
  
  private navigateToConfig(): void {
    // 导航到配置页面
    Logger.info(this.TAG, 'Navigate to config page');
  }
  
  private navigateToSettings(): void {
    // 导航到设置页面
    Logger.info(this.TAG, 'Navigate to settings page');
  }
  
  private navigateToDetail(media: FeaturedMediaItem): void {
    // 导航到详情页面
    Logger.info(this.TAG, `Navigate to detail page for: ${media.title}`);
  }
  
  // ==================== 错误处理 ====================
  
  private handleError(message: string, error: any): void {
    this.isError.value = true;
    this.errorMessage.value = message;
    Logger.error(this.TAG, `${message}: ${error}`);
  }
  
  // ==================== 清理方法 ====================
  
  /**
   * 清理资源
   */
  public destroy(): void {
    Logger.info(this.TAG, 'MainViewModel destroyed');
    // 清理定时器、订阅等资源
  }
  
  // ==================== 状态快照 ====================
  
  /**
   * 获取当前状态快照
   */
  public getStateSnapshot(): MainViewState {
    return {
      featuredMedia: this.featuredMedia.value,
      categories: this.categories.value,
      isLoading: this.isLoading.value,
      isError: this.isError.value,
      errorMessage: this.errorMessage.value,
      selectedTab: this.selectedTab.value,
      selectedCategory: this.selectedCategory.value,
      isLandscape: this.isLandscape.value,
      screenWidth: this.screenWidth.value,
      screenHeight: this.screenHeight.value,
      currentSite: this.currentSite.value,
      showSiteDialog: this.showSiteDialog.value
    };
  }
  
  /**
   * 从快照恢复状态
   */
  public restoreFromSnapshot(snapshot: MainViewState): void {
    this.featuredMedia.value = snapshot.featuredMedia;
    this.categories.value = snapshot.categories;
    this.isLoading.value = snapshot.isLoading;
    this.isError.value = snapshot.isError;
    this.errorMessage.value = snapshot.errorMessage;
    this.selectedTab.value = snapshot.selectedTab;
    this.selectedCategory.value = snapshot.selectedCategory;
    this.isLandscape.value = snapshot.isLandscape;
    this.screenWidth.value = snapshot.screenWidth;
    this.screenHeight.value = snapshot.screenHeight;
    this.currentSite.value = snapshot.currentSite;
    this.showSiteDialog.value = snapshot.showSiteDialog;
    
    Logger.info(this.TAG, 'State restored from snapshot');
  }
}

// ==================== 单例导出 ====================

let mainViewModelInstance: MainViewModel | null = null;

export function getMainViewModel(): MainViewModel {
  if (!mainViewModelInstance) {
    mainViewModelInstance = new MainViewModel();
  }
  return mainViewModelInstance;
}

export function destroyMainViewModel(): void {
  if (mainViewModelInstance) {
    mainViewModelInstance.destroy();
    mainViewModelInstance = null;
  }
}