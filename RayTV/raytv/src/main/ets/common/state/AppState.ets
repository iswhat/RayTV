/**
 * 应用状态管理 | Application State Management
 * 集中管理应用级别的状态
 */
import EventBus from '../event/EventBus';
import Logger from '../util/Logger';

// 用户信息接口 | User info interface
export interface UserInfo {
  id: string;
  name: string;
  avatar?: string;
  isLoggedIn: boolean;
  preferences?: UserPreferences;
}

// 用户偏好设置 | User preferences
export interface UserPreferences {
  theme: 'light' | 'dark' | 'auto';
  language: string;
  playbackQuality: 'low' | 'medium' | 'high' | 'auto';
  autoPlay: boolean;
  subtitlesEnabled: boolean;
  notificationsEnabled: boolean;
}

// 路由信息接口 | Route info interface
export interface RouteInfo {
  name: string;
  path: string;
  params?: Record<string, any>;
  timestamp: number;
}

// 媒体项接口 | Media item interface
export interface MediaItem {
  id: string;
  title: string;
  coverUrl: string;
  type: 'vod' | 'live' | 'series';
  rating?: number;
  duration?: number;
}

// 应用状态事件 | App state events
export enum AppStateEvent {
  USER_LOGGED_IN = 'user_logged_in',
  USER_LOGGED_OUT = 'user_logged_out',
  THEME_CHANGED = 'theme_changed',
  LANGUAGE_CHANGED = 'language_changed',
  ROUTE_CHANGED = 'route_changed',
  FAVORITE_ADDED = 'favorite_added',
  FAVORITE_REMOVED = 'favorite_removed',
  SEARCH_QUERY_CHANGED = 'search_query_changed',
  CATEGORY_SELECTED = 'category_selected',
  NETWORK_STATUS_CHANGED = 'network_status_changed'
}

// 全局状态类 | Global state class
class GlobalState {
  // 用户状态 | User state
  private _currentUser: UserInfo | null = null;
  private _isAuthenticated: boolean = false;
  
  // 应用状态 | App state
  private _currentTheme: 'light' | 'dark' = 'dark';
  private _currentLanguage: string = 'zh-CN';
  private _isAppReady: boolean = false;
  private _appVersion: string = '1.0.0';
  
  // 导航状态 | Navigation state
  private _currentRoute: RouteInfo | null = null;
  private _navigationHistory: RouteInfo[] = [];
  private _navigationStack: RouteInfo[] = [];
  
  // 内容状态 | Content state
  private _selectedCategory: string = 'all';
  private _searchQuery: string = '';
  private _favoriteItems: MediaItem[] = [];
  private _recentlyViewed: MediaItem[] = [];
  
  // 网络状态 | Network state
  private _isNetworkConnected: boolean = true;
  private _networkType: 'wifi' | 'mobile' | 'ethernet' | 'unknown' = 'unknown';
  
  // 速率限制 | Rate limits
  private _rateLimits: Record<string, number> = {};
  
  // 事件总线和日志 | Event bus and logger
  private eventBus: EventBus;
  private logger: Logger;

  /**
   * 构造函数 | Constructor
   */
  constructor() {
    this.eventBus = EventBus.getInstance();
    this.logger = new Logger('GlobalState');
    this.initializeDefaultState();
  }

  /**
   * 初始化默认状态 | Initialize default state
   */
  private initializeDefaultState(): void {
    // 设置默认用户状态 | Set default user state
    this._currentUser = {
      id: 'guest',
      name: '访客',
      isLoggedIn: false
    };

    // 设置默认应用状态 | Set default app state
    this._currentTheme = 'dark';
    this._currentLanguage = 'zh-CN';

    // 设置默认导航状态 | Set default navigation state
    this._currentRoute = {
      name: 'home',
      path: '/',
      timestamp: Date.now()
    };
    this._navigationHistory.push(this._currentRoute);

    this.logger.info('Global state initialized with default values');
  }

  // ==================== 用户状态 ====================

  /**
   * 获取当前用户 | Get current user
   */
  public get currentUser(): UserInfo | null {
    return this._currentUser;
  }

  /**
   * 设置当前用户 | Set current user
   * @param user 用户信息 | User info
   */
  public setCurrentUser(user: UserInfo): void {
    this._currentUser = user;
    this._isAuthenticated = user.isLoggedIn;
    this.eventBus.publish(AppStateEvent.USER_LOGGED_IN, user);
    this.logger.info(`User ${user.name} logged in`);
  }

  /**
   * 注销用户 | Logout user
   */
  public logout(): void {
    this._currentUser = {
      id: 'guest',
      name: '访客',
      isLoggedIn: false
    };
    this._isAuthenticated = false;
    this.eventBus.publish(AppStateEvent.USER_LOGGED_OUT);
    this.logger.info('User logged out');
  }

  /**
   * 是否已认证 | Is authenticated
   */
  public get isAuthenticated(): boolean {
    return this._isAuthenticated;
  }

  // ==================== 应用状态 ====================

  /**
   * 获取当前主题 | Get current theme
   */
  public get currentTheme(): 'light' | 'dark' {
    return this._currentTheme;
  }

  /**
   * 设置当前主题 | Set current theme
   * @param theme 主题 | Theme
   */
  public setTheme(theme: 'light' | 'dark'): void {
    this._currentTheme = theme;
    this.eventBus.publish(AppStateEvent.THEME_CHANGED, theme);
    this.logger.info(`Theme changed to ${theme}`);
  }

  /**
   * 获取当前语言 | Get current language
   */
  public get currentLanguage(): string {
    return this._currentLanguage;
  }

  /**
   * 设置当前语言 | Set current language
   * @param language 语言 | Language
   */
  public setLanguage(language: string): void {
    this._currentLanguage = language;
    this.eventBus.publish(AppStateEvent.LANGUAGE_CHANGED, language);
    this.logger.info(`Language changed to ${language}`);
  }

  /**
   * 应用是否就绪 | Is app ready
   */
  public get isAppReady(): boolean {
    return this._isAppReady;
  }

  /**
   * 设置应用就绪状态 | Set app ready state
   * @param ready 是否就绪 | Whether ready
   */
  public setAppReady(ready: boolean): void {
    this._isAppReady = ready;
    this.logger.info(`App ready state: ${ready}`);
  }

  /**
   * 获取应用版本 | Get app version
   */
  public get appVersion(): string {
    return this._appVersion;
  }

  /**
   * 设置应用版本 | Set app version
   * @param version 版本 | Version
   */
  public setAppVersion(version: string): void {
    this._appVersion = version;
  }

  // ==================== 导航状态 ====================

  /**
   * 获取当前路由 | Get current route
   */
  public get currentRoute(): RouteInfo | null {
    return this._currentRoute;
  }

  /**
   * 设置当前路由 | Set current route
   * @param route 路由信息 | Route info
   */
  public setCurrentRoute(route: RouteInfo): void {
    this._currentRoute = route;
    this._navigationHistory.push(route);
    this._navigationStack.push(route);
    
    // 限制历史记录长度 | Limit history length
    if (this._navigationHistory.length > 50) {
      this._navigationHistory.shift();
    }
    
    this.eventBus.publish(AppStateEvent.ROUTE_CHANGED, route);
    this.logger.info(`Route changed to ${route.path}`);
  }

  /**
   * 获取导航历史 | Get navigation history
   */
  public get navigationHistory(): RouteInfo[] {
    return [...this._navigationHistory];
  }

  /**
   * 导航回退 | Navigate back
   */
  public navigateBack(): RouteInfo | null {
    if (this._navigationStack.length > 1) {
      this._navigationStack.pop();
      const previousRoute = this._navigationStack[this._navigationStack.length - 1];
      this.setCurrentRoute(previousRoute);
      return previousRoute;
    }
    return null;
  }

  /**
   * 清除导航历史 | Clear navigation history
   */
  public clearNavigationHistory(): void {
    this._navigationHistory = [];
    this._navigationStack = [];
    if (this._currentRoute) {
      this._navigationHistory.push(this._currentRoute);
      this._navigationStack.push(this._currentRoute);
    }
    this.logger.info('Navigation history cleared');
  }

  // ==================== 内容状态 ====================

  /**
   * 获取选中的分类 | Get selected category
   */
  public get selectedCategory(): string {
    return this._selectedCategory;
  }

  /**
   * 设置选中的分类 | Set selected category
   * @param category 分类ID | Category ID
   */
  public setSelectedCategory(category: string): void {
    this._selectedCategory = category;
    this.eventBus.publish(AppStateEvent.CATEGORY_SELECTED, category);
    this.logger.info(`Selected category: ${category}`);
  }

  /**
   * 获取搜索查询 | Get search query
   */
  public get searchQuery(): string {
    return this._searchQuery;
  }

  /**
   * 设置搜索查询 | Set search query
   * @param query 搜索查询 | Search query
   */
  public setSearchQuery(query: string): void {
    this._searchQuery = query;
    this.eventBus.publish(AppStateEvent.SEARCH_QUERY_CHANGED, query);
  }

  /**
   * 获取收藏项 | Get favorite items
   */
  public get favoriteItems(): MediaItem[] {
    return [...this._favoriteItems];
  }

  /**
   * 添加收藏项 | Add favorite item
   * @param item 媒体项 | Media item
   */
  public addFavorite(item: MediaItem): void {
    const existingIndex = this._favoriteItems.findIndex(fav => fav.id === item.id);
    if (existingIndex === -1) {
      this._favoriteItems.push(item);
      this.eventBus.publish(AppStateEvent.FAVORITE_ADDED, item);
      this.logger.info(`Added favorite: ${item.title}`);
    }
  }

  /**
   * 移除收藏项 | Remove favorite item
   * @param itemId 媒体项ID | Media item ID
   */
  public removeFavorite(itemId: string): void {
    const initialLength = this._favoriteItems.length;
    this._favoriteItems = this._favoriteItems.filter(item => item.id !== itemId);
    if (this._favoriteItems.length !== initialLength) {
      this.eventBus.publish(AppStateEvent.FAVORITE_REMOVED, itemId);
      this.logger.info(`Removed favorite: ${itemId}`);
    }
  }

  /**
   * 检查是否收藏 | Check if favorite
   * @param itemId 媒体项ID | Media item ID
   */
  public isFavorite(itemId: string): boolean {
    return this._favoriteItems.some(item => item.id === itemId);
  }

  /**
   * 获取最近观看 | Get recently viewed
   */
  public get recentlyViewed(): MediaItem[] {
    return [...this._recentlyViewed];
  }

  /**
   * 添加最近观看 | Add recently viewed
   * @param item 媒体项 | Media item
   */
  public addRecentlyViewed(item: MediaItem): void {
    // 移除已存在的项 | Remove existing item
    this._recentlyViewed = this._recentlyViewed.filter(viewed => viewed.id !== item.id);
    
    // 添加到开头 | Add to beginning
    this._recentlyViewed.unshift(item);
    
    // 限制数量 | Limit count
    if (this._recentlyViewed.length > 20) {
      this._recentlyViewed = this._recentlyViewed.slice(0, 20);
    }
  }

  // ==================== 网络状态 ====================

  /**
   * 网络是否连接 | Is network connected
   */
  public get isNetworkConnected(): boolean {
    return this._isNetworkConnected;
  }

  /**
   * 获取网络类型 | Get network type
   */
  public get networkType(): 'wifi' | 'mobile' | 'ethernet' | 'unknown' {
    return this._networkType;
  }

  /**
   * 设置网络状态 | Set network status
   * @param connected 是否连接 | Whether connected
   * @param type 网络类型 | Network type
   */
  public setNetworkStatus(connected: boolean, type: 'wifi' | 'mobile' | 'ethernet' | 'unknown' = 'unknown'): void {
    this._isNetworkConnected = connected;
    this._networkType = type;
    this.eventBus.publish(AppStateEvent.NETWORK_STATUS_CHANGED, { connected, type });
    this.logger.info(`Network status changed: ${connected ? 'connected' : 'disconnected'} (${type})`);
  }

  /**
   * 获取速率限制 | Get rate limits
   */
  public get rateLimits(): Record<string, number> {
    return this._rateLimits;
  }

  /**
   * 设置速率限制 | Set rate limits
   * @param limits 速率限制 | Rate limits
   */
  public set rateLimits(limits: Record<string, number>) {
    this._rateLimits = limits;
  }

  // ==================== 状态管理 ====================

  /**
   * 重置所有状态 | Reset all state
   */
  public resetState(): void {
    this.initializeDefaultState();
    this._rateLimits = {};
    this.logger.info('Global state reset to default values');
  }

  /**
   * 获取状态快照 | Get state snapshot
   */
  public getStateSnapshot(): any {
    return {
      user: this._currentUser,
      isAuthenticated: this._isAuthenticated,
      theme: this._currentTheme,
      language: this._currentLanguage,
      isAppReady: this._isAppReady,
      currentRoute: this._currentRoute,
      navigationHistory: this._navigationHistory,
      selectedCategory: this._selectedCategory,
      searchQuery: this._searchQuery,
      favoriteItems: this._favoriteItems,
      recentlyViewed: this._recentlyViewed,
      network: {
        connected: this._isNetworkConnected,
        type: this._networkType
      },
      rateLimits: this._rateLimits
    };
  }

  /**
   * 加载状态快照 | Load state snapshot
   * @param snapshot 状态快照 | State snapshot
   */
  public loadStateSnapshot(snapshot: any): void {
    if (snapshot.user) {
      this._currentUser = snapshot.user;
      this._isAuthenticated = snapshot.isAuthenticated;
    }
    if (snapshot.theme) {
      this._currentTheme = snapshot.theme;
    }
    if (snapshot.language) {
      this._currentLanguage = snapshot.language;
    }
    if (snapshot.isAppReady !== undefined) {
      this._isAppReady = snapshot.isAppReady;
    }
    if (snapshot.currentRoute) {
      this._currentRoute = snapshot.currentRoute;
    }
    if (snapshot.navigationHistory) {
      this._navigationHistory = snapshot.navigationHistory;
    }
    if (snapshot.selectedCategory) {
      this._selectedCategory = snapshot.selectedCategory;
    }
    if (snapshot.searchQuery) {
      this._searchQuery = snapshot.searchQuery;
    }
    if (snapshot.favoriteItems) {
      this._favoriteItems = snapshot.favoriteItems;
    }
    if (snapshot.recentlyViewed) {
      this._recentlyViewed = snapshot.recentlyViewed;
    }
    if (snapshot.network) {
      this._isNetworkConnected = snapshot.network.connected;
      this._networkType = snapshot.network.type;
    }
    if (snapshot.rateLimits) {
      this._rateLimits = snapshot.rateLimits;
    }
    this.logger.info('Global state loaded from snapshot');
  }
}

// 导出全局状态实例 | Export global state instance
export const AppState = new GlobalState();

export default AppState;
