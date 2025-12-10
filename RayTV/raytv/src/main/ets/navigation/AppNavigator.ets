// 应用导航服务
// 管理页面路由、导航栈和页面跳�?

import router from '@ohos.router';
import StorageUtil from '../common/util/StorageUtil';

// 页面路由常量
export class PageRoute {
  static readonly HOME = 'home';
  static readonly VIDEO_PLAY = 'videoPlay';
  static readonly LINE_MANAGER = 'lineManager';
  static readonly SETTINGS = 'settings';
  static readonly SEARCH = 'search';
  static readonly FAVORITES = 'favorites';
  static readonly HISTORY = 'history';
  static readonly CATEGORY = 'category';
  static readonly DETAIL = 'detail';
  static readonly LIVE = 'live';
}

// 视频播放参数接口
export interface VideoPlayParams {
  videoId: string;
  siteKey: string;
  episodeName?: string;
  position?: number;
  fromSearch?: boolean;
}

// 分类信息接口
export interface CategoryInfo {
  id: string;
  name: string;
  type?: string;
}

// 详情参数接口
export interface DetailParams {
  id: string;
  siteKey: string;
  type: string;
}

// 路由映射接口
export interface RouteMapping {
  url: string;
  route: string;
  equals(other: RouteMapping): boolean;
}

// 路由映射实现�?
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

// 导航历史项接�?
export interface NavigationHistoryItem {
  route: string;
  url: string;
  params?: NavigationParams;
  timestamp: number;
  clone(): NavigationHistoryItem;
}

// 导航历史项实现类
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

// 导航参数接口
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

// 导航参数实现�?
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
    const keys = Object.keys(this._data);
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      clone.setParam(key, this._data[key]);
    }
    return clone;
  }
  
  // 转换为普通对象以便在router中使�?
  toObject(): Record<string, string | number | boolean | null> {
    // 手动构建对象，避免使用Object.fromEntries
    const result: Record<string, string | number | boolean | null> = {};
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
   * 获取单例实例
   */
  static getInstance(): AppNavigator {
    if (!AppNavigator.instance) {
      AppNavigator.instance = new AppNavigator();
    }
    return AppNavigator.instance;
  }

  /**
   * 导航到首�?
   */
  async navigateToHome(): Promise<void> {
    await this.navigateTo(PageRoute.HOME);
  }

  /**
   * 导航到视频播放页
   * @param params 播放参数
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
   * 导航到线路管理页
   */
  async navigateToLineManager(): Promise<void> {
    await this.navigateTo(PageRoute.LINE_MANAGER);
  }

  /**
   * 导航到设置页
   */
  async navigateToSettings(): Promise<void> {
    await this.navigateTo(PageRoute.SETTINGS);
  }

  /**
   * 导航到搜索页
   * @param prefilledKeyword 预填关键�?
   */
  async navigateToSearch(prefilledKeyword: string): Promise<void> {
    // 确保关键词始终是字符�?- 使用类型化对�?
    const searchParams: NavigationParams = new NavigationParamsImpl();
    searchParams.keyword = prefilledKeyword || '';
    await this.navigateTo(PageRoute.SEARCH, searchParams);
  }

  /**
   * 导航到收藏页
   */
  async navigateToFavorites(): Promise<void> {
    await this.navigateTo(PageRoute.FAVORITES);
  }

  /**
   * 导航到历史记录页
   */
  async navigateToHistory(): Promise<void> {
    await this.navigateTo(PageRoute.HISTORY);
  }

  /**
   * 导航到分类页
   * @param category 分类信息
   */
  async navigateToCategory(category: CategoryInfo): Promise<void> {
    // 确保category对象有正确的类型 - 明确类型标注
      const categoryParams: NavigationParams = new NavigationParamsImpl();
      categoryParams.id = category.id || '';
      categoryParams.name = category.name;
      categoryParams.type = category.type || 'vod';
      await this.navigateTo(PageRoute.CATEGORY, categoryParams);
  }

  /**
   * 导航到详情页
   * @param params 详情参数
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
   * 导航到直播页
   */
  async navigateToLive(): Promise<void> {
    await this.navigateTo(PageRoute.LIVE);
  }

  /**
   * 导航到页�?
   * @param route 页面路由
   * @param params 路由参数
   */
  private async navigateTo(route: string, params?: NavigationParams): Promise<void> {
    try {
      const url = this.getPageUrl(route);
      // 使用标准的router.getState()方法 - 虽然标记为已弃用，但目前没有直接替代方案
      const state = router.getState();
      const currentUrl = state.path || '';
      
      // 记录导航历史 - 创建符合接口定义的对�?
      const historyItem: NavigationHistoryItem = new NavigationHistoryItemImpl();
      historyItem.route = route;
      historyItem.url = url;
      historyItem.params = params;
      historyItem.timestamp = Date.now();
      this.addToHistory(historyItem);

      // 使用新的router.pushUrl方法替代已弃用的router.push
      const pushOptions: router.PushOptions = {
        url: url,
        params: params instanceof NavigationParamsImpl ? 
          params.toObject() : 
          (params || {} as Record<string, string | number | boolean | null>),
        mode: router.RouterMode.Single
      };
      await router.pushUrl(pushOptions);
    } catch (error) {
        // 安全处理错误信息
        const errorMsg: string = error instanceof Error ? error.message : 'Unknown error';
        console.error(`Navigation to ${route} failed:`, errorMsg);
        throw new Error(`Navigation to ${route} failed: ${errorMsg}`);
    }
  }

  /**
   * 返回上一�?
   */
  async navigateToBack(): Promise<void> {
    try {
      // 使用router.back()方法 - 虽然标记为已弃用，但目前没有直接替代方案
      await router.back();
      this.removeLastFromHistory();
    } catch (error) {
      console.error('Navigation back failed:', error);
      // 安全处理错误信息
      const errorMsg: string = error instanceof Error ? error.message : 'Unknown error';
      throw new Error(`Navigation back failed: ${errorMsg}`);
    }
  }

  /**
   * 返回首页（清空导航栈�?
   */
  async backToHome(): Promise<void> {
    try {
      // 使用新的router.pushUrl方法替代已弃用的router.push
      const pushOptions: router.PushOptions = {
        url: this.getPageUrl(PageRoute.HOME),
        params: {} as Record<string, string | number | boolean | null>,
        mode: router.RouterMode.Single
      };
      await router.pushUrl(pushOptions);
      this.navigationHistory = [];
      await this.saveNavigationHistory();
    } catch (error) {
      console.error('Navigation back to home failed:', error);
      // 安全处理错误信息
      const errorMsg: string = error instanceof Error ? error.message : 'Unknown error';
      throw new Error(`Navigation back to home failed: ${errorMsg}`);
    }
  }

  /**
   * 替换当前页面
   * @param route 目标路由
   * @param params 路由参数
   */
  async replace(route: string, params?: NavigationParams): Promise<void> {
    try {
      const url = this.getPageUrl(route);
      // 使用新的router.replaceUrl方法替代已弃用的router.replace
      const replaceOptions: router.ReplaceOptions = {
        url: url,
        params: params instanceof NavigationParamsImpl ? 
          params.toObject() : 
          (params || {} as Record<string, string | number | boolean | null>)
      };
      await router.replaceUrl(replaceOptions);
      
      // 创建符合接口定义的历史记录项
      const historyItem: NavigationHistoryItem = new NavigationHistoryItemImpl();
      historyItem.route = route;
      historyItem.url = url;
      historyItem.params = params;
      historyItem.timestamp = Date.now();
      this.replaceLastInHistory(historyItem);
    } catch (error) {
      console.error(`Navigation replace to ${route} failed:`, error);
      throw new Error(`Navigation replace to ${route} failed`);
    }
  }

  /**
   * 获取页面URL
   * @param route 页面路由
   */
  getPageUrl(route: string): string {
    // 使用switch语句替代索引签名，提高类型安全�?
    switch (route) {
      case PageRoute.HOME:
        return 'pages/HomePage';
      case PageRoute.VIDEO_PLAY:
        return 'pages/VideoPlayPage';
      case PageRoute.LINE_MANAGER:
        return 'pages/LineManagerPage';
      case PageRoute.SETTINGS:
        return 'pages/SettingsPage';
      case PageRoute.SEARCH:
        return 'pages/SearchPage';
      case PageRoute.FAVORITES:
        return 'pages/FavoritesPage';
      case PageRoute.HISTORY:
        return 'pages/HistoryPage';
      case PageRoute.CATEGORY:
        return 'pages/CategoryPage';
      case PageRoute.DETAIL:
        return 'pages/DetailPage';
      case PageRoute.LIVE:
        return 'pages/LivePage';
      default:
        return 'pages/HomePage';
    }
  }

  /**
   * 添加到导航历�?
   * @param item 历史记录�?
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
   * 从历史记录中移除最后一�?
   */
  removeLastFromHistory(): void {
    if (this.navigationHistory.length > 0) {
      this.navigationHistory.pop();
      this.saveNavigationHistory();
    }
  }

  /**
   * 替换历史记录中的最后一�?
   * @param item 新的历史记录�?
   */
  replaceLastInHistory(item: NavigationHistoryItem): void {
    if (this.navigationHistory.length > 0) {
      this.navigationHistory[this.navigationHistory.length - 1] = item;
      this.saveNavigationHistory();
    }
  }

  /**
   * 保存导航历史到存�?
   */
  async saveNavigationHistory(): Promise<void> {
    try {
      // 修复Function.apply/call和原型赋值错误：使用Object.keys替代
      const serializableHistory = new Array<NavigationHistoryItem>();
      for (let i = 0; i < this.navigationHistory.length; i++) {
        const item = this.navigationHistory[i];
        const serializableItem: NavigationHistoryItem = new NavigationHistoryItemImpl();
        serializableItem.route = item.route;
        serializableItem.url = item.url;
        if (item.params) {
          const validatedParams: NavigationParams = new NavigationParamsImpl();
          // 复制基本属�?
          if (item.params.id) validatedParams.id = item.params.id;
          if (item.params.name) validatedParams.name = item.params.name;
          if (item.params.title) validatedParams.title = item.params.title;
          if (item.params.category) validatedParams.category = item.params.category;
          if (item.params.page !== undefined) validatedParams.page = item.params.page;
          if (item.params.keyword) validatedParams.keyword = item.params.keyword;
          if (item.params.isFavorite !== undefined) validatedParams.isFavorite = item.params.isFavorite;
          // 处理其他可能的参�?- 使用Object.keys替代in操作�?
          const keys = Object.keys(item.params);
          for (let j = 0; j < keys.length; j++) {
            const key = keys[j];
            if (!['id', 'name', 'title', 'category', 'page', 'keyword', 'isFavorite'].includes(key)) {
              const value = item.params.getParam(key);
              if (value !== undefined) {
                validatedParams.setParam(key, value);
              }
            }
          }
          serializableItem.params = validatedParams;
        } else {
          serializableItem.params = undefined; // 使用undefined而不是null
        }
        serializableItem.timestamp = item.timestamp;
        serializableHistory.push(serializableItem);
      }
      await StorageUtil.save('navigationHistory', serializableHistory);
    } catch (error) {
      console.error('Failed to save navigation history:', error);
    }
  }

  /**
   * 从存储加载导航历�?
   */
  async loadNavigationHistory(): Promise<void> {
    try {
      // 修复any/unknown类型错误：明确指定返回类�?
      const history: Array<NavigationHistoryItem> = await StorageUtil.get('navigationHistory', []);
      // 确保类型安全
      if (Array.isArray(history)) {
        // 避免直接类型断言，进行基本的类型检�?
        this.navigationHistory = history.filter(item => 
          item && typeof item === 'object' && 
          typeof item.route === 'string' && 
          typeof item.url === 'string' && 
          typeof item.timestamp === 'number'
        ).map(item => {
          // 手动复制属性，避免使用扩展运算�?
          const newItem: NavigationHistoryItem = new NavigationHistoryItemImpl();
          newItem.route = item.route;
          newItem.url = item.url;
          newItem.params = item.params;
          newItem.timestamp = item.timestamp;
          return newItem;
        });
      } else {
        this.navigationHistory = [];
      }
    } catch (error) {
      console.error('Failed to load navigation history:', error);
      this.navigationHistory = [];
    }
  }

  /**
   * 获取当前页面路由
   */
  getCurrentRoute(): string {
    // 获取当前路由状�?- 虽然标记为已弃用，但目前没有直接替代方案
    try {
      const state = router.getState();
      const url = state.path || '';
      
      // 从URL映射回路�?- 使用数组避免索引签名问题，使用构造函数避免structural typing
      const routeMap = new Array<RouteMapping>();
      
      routeMap.push(new RouteMappingImpl('pages/HomePage', PageRoute.HOME));
      routeMap.push(new RouteMappingImpl('pages/VideoPlayPage', PageRoute.VIDEO_PLAY));
      routeMap.push(new RouteMappingImpl('pages/LineManagerPage', PageRoute.LINE_MANAGER));
      routeMap.push(new RouteMappingImpl('pages/SettingsPage', PageRoute.SETTINGS));
      routeMap.push(new RouteMappingImpl('pages/SearchPage', PageRoute.SEARCH));
      routeMap.push(new RouteMappingImpl('pages/FavoritesPage', PageRoute.FAVORITES));
      routeMap.push(new RouteMappingImpl('pages/HistoryPage', PageRoute.HISTORY));
      routeMap.push(new RouteMappingImpl('pages/CategoryPage', PageRoute.CATEGORY));
      routeMap.push(new RouteMappingImpl('pages/DetailPage', PageRoute.DETAIL));
      routeMap.push(new RouteMappingImpl('pages/LivePage', PageRoute.LIVE));

      // 查找匹配的URL
      for (let i = 0; i < routeMap.length; i++) {
        if (routeMap[i].url === url) {
          return routeMap[i].route;
        }
      }
    } catch (error) {
      console.error('Failed to get current route:', error);
    }
    
    return PageRoute.HOME;
  }
}
