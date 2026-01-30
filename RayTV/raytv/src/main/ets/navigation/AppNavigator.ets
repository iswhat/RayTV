// 应用导航服务 | Application navigation service
// 管理页面路由、导航栈和页面导航 | Manage page routing, navigation stack, and page navigation

import router from '@ohos.router';
import StorageUtil, { StorageType } from '../common/util/StorageUtil';
// Logger import removed as AnalyticsService was deleted

// 页面路由常量 | Page route constants
export class PageRoute {
  static readonly HOME = 'home';
  static readonly VIDEO_PLAY = 'videoPlay';
  static readonly LINE_MANAGER = 'lineManager';
  static readonly SETTINGS = 'settings';
  static readonly SEARCH = 'search';
  static readonly SEARCH_RESULT = 'searchResult';
  static readonly HISTORY = 'history';
  static readonly CATEGORY = 'category';
  static readonly DETAIL = 'detail';
  static readonly LIVE = 'live';
}

// 视频播放参数接口 | Video playback parameters interface
export interface VideoPlayParams {
  videoId: string;
  siteKey: string;
  episodeName?: string;
  position?: number;
  fromSearch?: boolean;
}

// 分类信息接口 | Category information interface
export interface CategoryInfo {
  id: string;
  name: string;
  type?: string;
}

// 详情参数接口 | Detail parameters interface
export interface DetailParams {
  id: string;
  siteKey: string;
  type: string;
}

// 路由映射接口 | Route mapping interface
export interface RouteMapping {
  url: string;
  route: string;
  equals(other: RouteMapping): boolean;
}

// 导航历史序列化接口 | Navigation history serializable interface
export interface SerializableHistoryItem {
  route: string;
  url: string;
  timestamp: number;
}

// 路由映射实现类 | Route mapping implementation class
export class RouteMappingImpl implements RouteMapping {
  url: string = '';
  route: string = '';
  
  constructor(url?: string, route?: string) {
    if (url !== undefined) {
      this.url = url;
    }
    if (route !== undefined) {
      this.route = route;
    }
  }
  
  equals(other: RouteMapping): boolean {
    return this.url === other.url && this.route === other.route;
  }
}

// 导航历史项接口 | Navigation history item interface
export interface NavigationHistoryItem {
  route: string;
  url: string;
  params?: NavigationParams;
  timestamp: number;
  clone(): NavigationHistoryItem;
}

// 导航历史项实现类 | Navigation history item implementation class
export class NavigationHistoryItemImpl implements NavigationHistoryItem {
  route: string = '';
  url: string = '';
  params?: NavigationParams;
  timestamp: number = 0;
  
  constructor(route?: string, url?: string, params?: NavigationParams, timestamp?: number) {
    if (route !== undefined) {
      this.route = route;
    }
    if (url !== undefined) {
      this.url = url;
    }
    if (params !== undefined) {
      this.params = params;
    }
    if (timestamp !== undefined) {
      this.timestamp = timestamp;
    }
  }
  
  clone(): NavigationHistoryItem {
    const clone = new NavigationHistoryItemImpl();
    clone.route = this.route;
    clone.url = this.url;
    clone.timestamp = this.timestamp;
    if (this.params instanceof NavigationParamsImpl) {
      clone.params = this.params.clone();
    }
    return clone;
  }
}

// 导航参数接口 | Navigation parameters interface
export interface NavigationParams {
  id?: string;
  name?: string;
  title?: string;
  category?: string;
  page?: number;
  keyword?: string;
  isFavorite?: boolean;
  getParam(key: string): string | number | boolean | null | undefined;
  setParam(key: string, value: string | number | boolean | null): void;
  clone(): NavigationParams;
}

// 导航参数实现类 | Navigation parameters implementation class
export class NavigationParamsImpl implements NavigationParams {
  private _data: Record<string, string | number | boolean | null> = {};
  
  getParam(key: string): string | number | boolean | null | undefined {
    return this._data[key];
  }
  
  setParam(key: string, value: string | number | boolean | null): void {
    this._data[key] = value;
  }
  
  clone(): NavigationParams {
    const clone = new NavigationParamsImpl();
    // 使用Object.keys替代for-in循环
    const keys = Object.keys(this._data);
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      clone.setParam(key, this._data[key]);
    }
    return clone;
  }
  
  // 转换为普通对象以便在router中使用 | Convert to plain object for use in router
  toObject(): Record<string, string | number | boolean | null> {
    // 手动构建对象，避免使用Object.fromEntries
    const result: Record<string, string | number | boolean | null> = {};
    // 使用Object.keys替代for-in循环
    const keys = Object.keys(this._data);
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      const value = this._data[key];
      if (value !== undefined) {
        result[key] = value;
      }
    }
    return result;
  }
}

export class AppNavigator {
  private static instance: AppNavigator | null = null;

  private storageUtil: StorageUtil;
  private navigationHistory: Array<NavigationHistoryItem> = []; // 使用Array<Type>语法

  constructor() {
    this.storageUtil = StorageUtil.getInstance();
    this.loadNavigationHistory();
  }

  /**
   * 获取单例实例 | Get singleton instance
   */
  static getInstance(): AppNavigator {
    if (!AppNavigator.instance) {
      AppNavigator.instance = new AppNavigator();
    }
    return AppNavigator.instance;
  }

  /**
   * 导航到首页 | Navigate to home page
   */
  async navigateToHome(): Promise<void> {
    await this.navigateTo(PageRoute.HOME);
  }

  /**
   * 导航到视频播放页面 | Navigate to video playback page
   * @param params 播放参数 | Playback parameters
   */
  async navigateToVideoPlay(params: VideoPlayParams): Promise<void> {
    // 修复结构类型错误：将VideoPlayParams转换为NavigationParams
    const navParams: NavigationParams = new NavigationParamsImpl();
    navParams.setParam('videoId', params.videoId);
    // 确保传递给setParam的参数明确不是undefined
    const siteKey: string | null = params.siteKey !== undefined ? params.siteKey : null;
    const episodeName: string | null = params.episodeName !== undefined ? params.episodeName : null;
    const position: number | null = params.position !== undefined ? params.position : null;
    const fromSearch: boolean | null = params.fromSearch !== undefined ? params.fromSearch : null;
    navParams.setParam('siteKey', siteKey);
    navParams.setParam('episodeName', episodeName);
    navParams.setParam('position', position);
    navParams.setParam('fromSearch', fromSearch);
    await this.navigateTo(PageRoute.VIDEO_PLAY, navParams);
  }

  /**
   * 导航到线路管理页面 | Navigate to line manager page
   */
  async navigateToLineManager(): Promise<void> {
    await this.navigateTo(PageRoute.LINE_MANAGER);
  }

  /**
   * 导航到设置页面 | Navigate to settings page
   */
  async navigateToSettings(): Promise<void> {
    await this.navigateTo(PageRoute.SETTINGS);
  }

  /**
   * 导航到搜索页面 | Navigate to search page
   * @param prefilledKeyword 预填关键词 | Prefilled keyword
   */
  async navigateToSearch(prefilledKeyword: string): Promise<void> {
    // 确保关键词始终是字符串 - 使用类型化对象
    const searchParams: NavigationParams = new NavigationParamsImpl();
    searchParams.setParam('keyword', prefilledKeyword || '');
    await this.navigateTo(PageRoute.SEARCH, searchParams);
  }

  /**
   * 导航到搜索结果页面 | Navigate to search result page
   * @param keyword 搜索关键词 | Search keyword
   */
  async navigateToSearchResult(keyword: string): Promise<void> {
    const searchParams: NavigationParams = new NavigationParamsImpl();
    searchParams.setParam('keyword', keyword || '');
    await this.navigateTo(PageRoute.SEARCH_RESULT, searchParams);
  }

  /**
   * 导航到历史记录页面 | Navigate to history page
   */
  async navigateToHistory(): Promise<void> {
    await this.navigateTo(PageRoute.HISTORY);
  }

  /**
   * 导航到分类页面 | Navigate to category page
   * @param category 分类信息 | Category information
   */
  async navigateToCategory(category: CategoryInfo): Promise<void> {
    // 确保category对象有正确的类型 - 明确类型标记
    const categoryParams: NavigationParams = new NavigationParamsImpl();
    categoryParams.setParam('id', category.id || '');
    categoryParams.setParam('name', category.name);
    categoryParams.setParam('type', category.type || 'vod');
    await this.navigateTo(PageRoute.CATEGORY, categoryParams);
  }

  /**
   * 导航到详情页面 | Navigate to detail page
   * @param params 详情参数 | Detail parameters
   */
  async navigateToDetail(params: DetailParams): Promise<void> {
    // 修复结构类型错误：将DetailParams转换为NavigationParams
    const navParams: NavigationParams = new NavigationParamsImpl();
    navParams.setParam('id', params.id);
    navParams.setParam('siteKey', params.siteKey);
    navParams.setParam('type', params.type);
    await this.navigateTo(PageRoute.DETAIL, navParams);
  }

  /**
   * 导航到直播页面 | Navigate to live page
   */
  async navigateToLive(): Promise<void> {
    await this.navigateTo(PageRoute.LIVE);
  }

  /**
   * 导航到页面 | Navigate to page
   * @param route 页面路由 | Page route
   * @param params 导航参数 | Navigation parameters
   */
  private async navigateTo(route: string, params?: NavigationParams): Promise<void> {
    try {
      const url = this.getPageUrl(route);
      
      // 记录导航历史 - 创建符合接口定义的对象
      const historyItem: NavigationHistoryItem = new NavigationHistoryItemImpl();
      historyItem.route = route;
      historyItem.url = url;
      historyItem.params = params;
      historyItem.timestamp = Date.now();
      this.addToHistory(historyItem);

      // 使用router.push API
      const routerParams = params instanceof NavigationParamsImpl ? 
        params.toObject() : 
        (params || {} as Record<string, string | number | boolean | null>);
      await router.push({
        url: url,
        params: routerParams
      });
    } catch (error: Error) {
      console.error('Navigation to ' + route + ' failed: ' + error.message);
      throw new Error('Navigation to ' + route + ' failed: ' + error.message);
    }
  }

  /**
   * 返回上一页 | Navigate back
   */
  async navigateToBack(): Promise<void> {
    try {
      // 使用router.back方法
      await router.back();
      this.removeLastFromHistory();
    } catch (error: Error) {
      console.error('Navigation back failed: ' + error.message);
      throw new Error('Navigation back failed: ' + error.message);
    }
  }

  /**
   * 返回首页（清除导航栈） | Back to home (clear navigation stack)
   */
  async backToHome(): Promise<void> {
    try {
      // 使用新的router.push API
      await router.push({
        url: this.getPageUrl(PageRoute.HOME),
        params: {} as Record<string, string | number | boolean | null>
      });
      this.navigationHistory = [];
      await this.saveNavigationHistory();
    } catch (error: Error) {
      console.error('Navigation back to home failed: ' + error.message);
      throw new Error('Navigation back to home failed: ' + error.message);
    }
  }

  /**
   * 替换当前页面 | Replace current page
   * @param route 目标路由 | Target route
   * @param params 导航参数 | Navigation parameters
   */
  async replace(route: string, params?: NavigationParams): Promise<void> {
    try {
      const url = this.getPageUrl(route);
      // 使用新的router.replace API
      const routerParams = params instanceof NavigationParamsImpl ? 
        params.toObject() : 
        (params || {} as Record<string, string | number | boolean | null>);
      await router.replace({
        url: url,
        params: routerParams
      });
      
      // 创建符合接口定义的历史记录
      const historyItem: NavigationHistoryItem = new NavigationHistoryItemImpl();
      historyItem.route = route;
      historyItem.url = url;
      historyItem.params = params;
      historyItem.timestamp = Date.now();
      this.replaceLastInHistory(historyItem);
    } catch (error: Error) {
      console.error('Navigation replace to ' + route + ' failed: ' + error.message);
      throw new Error('Navigation replace to ' + route + ' failed: ' + error.message);
    }
  }

  /**
   * 获取页面URL | Get page URL
   * @param route 页面路由 | Page route
   */
  getPageUrl(route: string): string {
    // 使用switch语句替换映射常量，提高类型安全
    switch (route) {
      case PageRoute.HOME:
        return 'pages/MainPage'; // 实际首页组件是MainPage.ets
      case PageRoute.VIDEO_PLAY:
        return 'pages/PlaybackPage'; // 实际视频播放组件是PlaybackPage.ets
      case PageRoute.LINE_MANAGER:
        return 'pages/LineManagerPage'; // 线路管理页面存在
      case PageRoute.SETTINGS:
        return 'pages/SettingsPage'; // 设置页面存在
      case PageRoute.SEARCH:
        return 'pages/SearchPage'; // 搜索页面存在
      case PageRoute.SEARCH_RESULT:
        return 'pages/SearchResultPage'; // 搜索结果页面存在
      case PageRoute.HISTORY:
        return 'pages/HistoryPage'; // 历史记录页面存在
      case PageRoute.CATEGORY:
        return 'pages/CategoryPage'; // 分类页面存在
      case PageRoute.DETAIL:
        return 'pages/MediaDetailPage'; // 实际详情页面组件是MediaDetailPage.ets
      case PageRoute.LIVE:
        return 'pages/LivePage'; // 直播页面存在
      default:
        return 'pages/MainPage'; // 默认返回首页
    }
  }

  /**
   * 添加到历史记录 | Add to history
   * @param item 历史记录项 | History item
   */
  addToHistory(item: NavigationHistoryItem): void {
    this.navigationHistory.push(item);
    // 限制历史记录长度
    if (this.navigationHistory.length > 50) {
      this.navigationHistory = this.navigationHistory.slice(-50);
    }
    this.saveNavigationHistory();
  }

  /**
   * 从历史记录中移除最后一页 | Remove last from history
   */
  removeLastFromHistory(): void {
    if (this.navigationHistory.length > 0) {
      this.navigationHistory.pop();
      this.saveNavigationHistory();
    }
  }

  /**
   * 替换历史记录中的最后一页 | Replace last in history
   * @param item 新的历史记录项 | New history item
   */
  replaceLastInHistory(item: NavigationHistoryItem): void {
    if (this.navigationHistory.length > 0) {
      this.navigationHistory[this.navigationHistory.length - 1] = item;
      this.saveNavigationHistory();
    }
  }

  /**
   * 保存导航历史到存储 | Save navigation history to storage
   */
  async saveNavigationHistory(): Promise<void> {
    try {
      // 只保存基本数据，避免复杂对象序列化问题
      const serializableHistory: SerializableHistoryItem[] = this.navigationHistory.map(item => {
        // 显式定义对象类型为SerializableHistoryItem
        const historyItem: SerializableHistoryItem = {
          route: item.route,
          url: item.url,
          timestamp: item.timestamp
        };
        return historyItem;
      });
      // 转换为JSON字符串保存，避免类型不兼容问题
      const historyJson = JSON.stringify(serializableHistory);
      await StorageUtil.set('navigationHistory', historyJson);
    } catch (error: Error) {
      console.error('Failed to save navigation history: ' + error.message);
    }
  }

  /**
   * 从存储加载导航历史 | Load navigation history from storage
   */
  async loadNavigationHistory(): Promise<void> {
    try {
      // 使用指定的接口作为类型结尾，避免对象字面量类型
      const historyJson = await StorageUtil.getString('navigationHistory', StorageType.PREFERENCES);
      let history = [] as SerializableHistoryItem[];
      if (historyJson) {
        history = JSON.parse(historyJson) as SerializableHistoryItem[];
      }
      
      // 确保类型安全
      if (Array.isArray(history)) {
        this.navigationHistory = history.filter(item => 
          item && typeof item === 'object' && 
          typeof item.route === 'string' && 
          typeof item.url === 'string' && 
          typeof item.timestamp === 'number'
        ).map(item => {
          const newItem: NavigationHistoryItem = new NavigationHistoryItemImpl();
          newItem.route = item.route;
          newItem.url = item.url;
          newItem.timestamp = item.timestamp;
          return newItem;
        });
      } else {
        this.navigationHistory = [];
      }
    } catch (error: Error) {
      console.error('Failed to load navigation history: ' + error.message);
      this.navigationHistory = [];
    }
  }

  /**
   * 获取当前页面路由 | Get current route
   */
  getCurrentRoute(): string {
    // 从历史记录中获取当前路由
    if (this.navigationHistory.length > 0) {
      return this.navigationHistory[this.navigationHistory.length - 1].route;
    }
    return PageRoute.HOME;
  }
  
  /**
   * 获取当前路由参数 | Get current route params
   */
  getCurrentRouteParams(): DetailParams {
    // 从历史记录中获取当前参数
    if (this.navigationHistory.length > 0) {
      const currentItem = this.navigationHistory[this.navigationHistory.length - 1];
      if (currentItem.params) {
        return {
          id: currentItem.params.getParam('id') as string || '1',
          siteKey: currentItem.params.getParam('siteKey') as string || 'default',
          type: currentItem.params.getParam('type') as string || 'movie'
        };
      }
    }
    // 返回默认值
    return {
      id: '1',
      siteKey: 'default',
      type: 'movie'
    };
  }
}

// 添加默认导出
export default AppNavigator;

