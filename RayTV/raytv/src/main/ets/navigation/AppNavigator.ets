// 应用导航服务
// 管理页面路由、导航栈和页面跳转

import router from '@ohos.router';
import StorageUtil from '../common/util/StorageUtil';

// 定义router.pushUrl和router.replaceUrl方法的参数类型接口
export interface RouterOptions {
  url: string;
  params?: Record<string, string | number | boolean | null>;
  mode?: router.RouterMode;
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
   * 导航到首页
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
    navParams.setParam('siteKey', params.siteKey);
    navParams.setParam('episodeName', params.episodeName);
    navParams.setParam('position', params.position);
    navParams.setParam('fromSearch', params.fromSearch);
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
   * @param prefilledKeyword 预填关键词
   */
  async navigateToSearch(prefilledKeyword: string): Promise<void> {
    // 确保关键词始终是字符串 - 使用类型化对象
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
   * 导航到页面
   * @param route 页面路由
   * @param params 路由参数
   */
  private async navigateTo(route: string, params?: NavigationParams): Promise<void> {
    try {
      const url = this.getPageUrl(route);
      // 使用标准的router.getState()方法 - 虽然标记为已弃用，但目前没有直接替代方案
      const state = router.getState();
      const currentUrl = state.path || '';
      
      // 记录导航历史 - 创建符合接口定义的对象
      const historyItem: NavigationHistoryItem = new NavigationHistoryItemImpl();
      historyItem.route = route;
      historyItem.url = url;
      historyItem.params = params;
      historyItem.timestamp = Date.now();
      this.addToHistory(historyItem);

      // 使用新的router.pushUrl方法替代已弃用的router.push
      // 创建符合router.pushUrl要求的对象
      const routerOptions: RouterOptions = {
        url: url,
        params: params instanceof NavigationParamsImpl ? 
          params.toObject() : 
          (params || {} as Record<string, string | number | boolean | null>),
        mode: router.RouterMode.Single
      };
      await router.pushUrl(routerOptions);
    } catch (error) {
        // 安全处理错误信息
        const errorMsg: string = error instanceof Error ? error.message : 'Unknown error';
        console.error(`Navigation to ${route} failed:`, errorMsg);
        throw new Error(`Navigation to ${route} failed: ${errorMsg}`);
    }
  }

  /**
   * 返回上一页
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
   * 返回首页（清空导航栈）
   */
  async backToHome(): Promise<void> {
    try {
      // 使用新的router.pushUrl方法替代已弃用的router.push
      // 创建符合router.pushUrl要求的对象
      const routerOptions: RouterOptions = {
        url: this.getPageUrl(PageRoute.HOME),
        params: {} as Record<string, string | number | boolean | null>,
        mode: router.RouterMode.Single
      };
      await router.pushUrl(routerOptions);
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
      // 创建符合router.replaceUrl要求的对象
      const routerOptions: RouterOptions = {
        url: url,
        params: params instanceof NavigationParamsImpl ? 
          params.toObject() : 
          (params || {} as Record<string, string | number | boolean | null>)
      };
      await router.replaceUrl(routerOptions);
      
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
    // 使用switch语句替代索引签名，提高类型安全性
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
   * 添加到导航历史
   * @param item 历史记录项
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
   * 从历史记录中移除最后一项
   */
  removeLastFromHistory(): void {
    if (this.navigationHistory.length > 0) {
      this.navigationHistory.pop();
      this.saveNavigationHistory();
    }
  }

  /**
   * 替换历史记录中的最后一项
   * @param item 新的历史记录项
   */
  replaceLastInHistory(item: NavigationHistoryItem): void {
    if (this.navigationHistory.length > 0) {
      this.navigationHistory[this.navigationHistory.length - 1] = item;
      this.saveNavigationHistory();
    }
  }

  /**
   * 保存导航历史到存储
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
          // 复制基本属性
          if (item.params.id) validatedParams.id = item.params.id;
          if (item.params.name) validatedParams.name = item.params.name;
          if (item.params.title) validatedParams.title = item.params.title;
          if (item.params.category) validatedParams.category = item.params.category;
          if (item.params.page !== undefined) validatedParams.page = item.params.page;
          if (item.params.keyword) validatedParams.keyword = item.params.keyword;
          if (item.params.isFavorite !== undefined) validatedParams.isFavorite = item.params.isFavorite;
          // 处理其他可能的参数 - 使用Object.keys替代in操作符
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
   * 从存储加载导航历史
   */
  async loadNavigationHistory(): Promise<void> {
    try {
      // 修复any/unknown类型错误：明确指定返回类型
      const history: Array<NavigationHistoryItem> = await StorageUtil.get('navigationHistory', []);
      // 确保类型安全
      if (Array.isArray(history)) {
        // 避免直接类型断言，进行基本的类型检查
        this.navigationHistory = history.filter(item => 
          item && typeof item === 'object' && 
          typeof item.route === 'string' && 
          typeof item.url === 'string' && 
          typeof item.timestamp === 'number'
        ).map(item => {
          // 手动复制属性，避免使用扩展运算符
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
    // 获取当前路由状态 - 虽然标记为已弃用，但目前没有直接替代方案
    try {
      const state = router.getState();
      const url = state.path || '';
      
      // 从URL映射回路由 - 使用数组避免索引签名问题，使用构造函数避免structural typing
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

// 定义路由映射接口 - 避免structural typing问题
export interface RouteMapping {
  url: string;
  route: string;
  // 显式定义方法，避免隐式结构类型比较
  equals(other: RouteMapping): boolean;
}

// 实现路由映射类 - 确保完整实现接口
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
  
  // 明确实现equals方法，避免依赖structural typing
  equals(other: RouteMapping): boolean {
    return this.url === other.url && this.route === other.route;
  }
}

// 定义导航选项接口 - 避免structural typing
export interface RouterOptions {
  url: string;
  params?: Record<string, string | number | boolean | null>;
  mode?: number;
  // 添加明确的类型检查方法
  isValid(): boolean;
}

// 实现导航选项类 - 完整实现接口
export class RouterOptionsImpl implements RouterOptions {
  url: string = '';
  params?: Record<string, string | number | boolean | null>;
  mode?: number;
  
  constructor(url?: string, params?: Record<string, string | number | boolean | null>, mode?: number) {
    if (url !== undefined) {
      this.url = url;
    }
    if (params !== undefined) {
      this.params = params;
    }
    if (mode !== undefined) {
      this.mode = mode;
    }
  }
  
  // 实现isValid方法
  isValid(): boolean {
    return this.url !== undefined && this.url !== '';
  }
}

// 导航历史项接口
export interface NavigationHistoryItem {
  route: string;
  url: string;
  params?: NavigationParams;
  timestamp: number;
  // 添加克隆方法，避免结构类型转换问题
  clone(): NavigationHistoryItem;
}

// 实现导航历史项接口 - 完整实现所有方法
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
  
  // 实现clone方法，避免结构类型转换
  clone(): NavigationHistoryItem {
    const clone = new NavigationHistoryItemImpl();
    clone.route = this.route;
    clone.url = this.url;
    clone.timestamp = this.timestamp;
    // 深拷贝params
    if (this.params instanceof NavigationParamsImpl) {
      clone.params = this.params.clone();
    }
    return clone;
  }
}

/**
 * 页面路由常量
 */
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

/**
   * 导航参数类型
   */
// 统一NavigationParams接口定义，避免声明合并问题
export interface NavigationParams {
  // 定义常用的参数键值对
  id?: string;
  name?: string;
  title?: string;
  category?: string;
  page?: number;
  keyword?: string;
  isFavorite?: boolean;
  // 如果需要处理更多动态参数，可以使用以下方法
  getParam(key: string): string | number | boolean | null | undefined;
  setParam(key: string, value: string | number | boolean | null): void;
  // 添加clone方法，避免结构类型问题
  clone(): NavigationParams;
}

// 实现NavigationParams接口
export class NavigationParamsImpl implements NavigationParams {
  // 内部存储 - 移除any/unknown类型，使用明确类型
  private _data: Record<string, string | number | boolean | null> = {};
  
  // 实现接口方法 - 使用明确类型
  getParam(key: string): string | number | boolean | null | undefined {
    return this._data[key];
  }
  
  setParam(key: string, value: string | number | boolean | null): void {
    this._data[key] = value;
  }
  
  // 实现clone方法，避免结构类型转换问题
  clone(): NavigationParams {
    const clone = new NavigationParamsImpl();
    // 深拷贝数据 - 使用Object.keys代替for..in循环，避免ArkTS严格模式警告
    const keys = Object.keys(this._data);
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      const value = this._data[key];
      clone.setParam(key, value);
    }
    return clone;
  }
  
  // 属性访问器
  get id(): string | undefined {
    return this._data.id as string | undefined;
  }
  
  set id(value: string | undefined) {
    if (value === undefined) {
      // 修复undefined类型赋值错误：使用null或空字符串代替undefined
      this._data.id = null;
    } else {
      this._data.id = value;
    }
  }
  
  get name(): string | undefined {
    return this._data.name as string | undefined;
  }
  
  set name(value: string | undefined) {
    if (value === undefined) {
      // 修复undefined类型赋值错误：使用null或空字符串代替undefined
      this._data.name = null;
    } else {
      this._data.name = value;
    }
  }
  
  get title(): string | undefined {
    return this._data.title as string | undefined;
  }
  
  set title(value: string | undefined) {
    if (value === undefined) {
      // 修复undefined类型赋值错误：使用null或空字符串代替undefined
      this._data.title = null;
    } else {
      this._data.title = value;
    }
  }
  
  get category(): string | undefined {
    return this._data.category as string | undefined;
  }
  
  set category(value: string | undefined) {
    if (value === undefined) {
      // 修复undefined类型赋值错误：使用null或空字符串代替undefined
      this._data.category = null;
    } else {
      this._data.category = value;
    }
  }
  
  get page(): number | undefined {
    return this._data.page as number | undefined;
  }
  
  set page(value: number | undefined) {
    if (value === undefined) {
      // 修复undefined类型赋值错误：使用0或null代替undefined
      this._data.page = 0;
    } else {
      this._data.page = value;
    }
  }
  
  get keyword(): string | undefined {
    return this._data.keyword as string | undefined;
  }
  
  set keyword(value: string | undefined) {
    if (value === undefined) {
      // 修复undefined类型赋值错误：使用空字符串代替undefined
      this._data.keyword = '';
    } else {
      this._data.keyword = value;
    }
  }
  
  get isFavorite(): boolean | undefined {
    return this._data.isFavorite as boolean | undefined;
  }
  
  set isFavorite(value: boolean | undefined) {
    if (value === undefined) {
      // 修复undefined类型赋值错误：使用false代替undefined
      this._data.isFavorite = false;
    } else {
      this._data.isFavorite = value;
    }
  }
  
  // 转换为普通对象以便在router中使用
  toObject(): Record<string, string | number | boolean | null> {
    const result: Record<string, string | number | boolean | null> = {};
    // 使用Object.keys代替for..in循环，避免ArkTS严格模式警告
    const keys = Object.keys(this._data);
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      const value = this._data[key];
      // 只序列化基本类型
      if (value !== undefined) {
        result[key] = value;
      }
    }
    return result;
  }
}

/**
   * 导航历史项 - 统一接口定义，避免声明合并问题
   */
// 注释掉重复的接口定义，使用上面已经定义的NavigationHistoryItem接口
// export interface NavigationHistoryItem {
//   route: string;
//   url: string;
//   params?: NavigationParams;
//   timestamp: number;
// }

/**
 * 视频播放参数
 */
export interface VideoPlayParams {
  videoId: string;
  siteKey: string;
  episodeName: string; // 移除可选标记
  position: number; // 移除可选标记
  fromSearch: boolean; // 移除可选标记
}

/**
 * 详情页参数
 */
export interface DetailParams {
  id: string;
  siteKey: string;
  type: string; // 改为string类型
}

/**
 * 分类信息
 */
export interface CategoryInfo {
  id: string; // 移除可选标记，确保类型一致性
  name: string;
  type: string; // 改为string类型，避免联合类型
}