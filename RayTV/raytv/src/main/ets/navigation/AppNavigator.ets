// 应用导航服务
// 管理页面路由、导航栈和页面跳转

import router from '@ohos.router';
import StorageUtil, { JsonData } from '../common/util/StorageUtil';

export class AppNavigator {
  private static instance: AppNavigator | null = null;
  private storageUtil: StorageUtil;
  private navigationHistory: NavigationHistoryItem[] = [];

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
    await this.navigateTo(PageRoute.VIDEO_PLAY, params);
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
  async navigateToSearch(prefilledKeyword?: string): Promise<void> {
    await this.navigateTo(PageRoute.SEARCH, { keyword: prefilledKeyword });
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
  async navigateToCategory(category?: CategoryInfo): Promise<void> {
    await this.navigateTo(PageRoute.CATEGORY, category);
  }

  /**
   * 导航到详情页
   * @param params 详情参数
   */
  async navigateToDetail(params: DetailParams): Promise<void> {
    await this.navigateTo(PageRoute.DETAIL, params);
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
      const currentUrl = router.getState().path;
      
      // 记录导航历史
      const historyItem: NavigationHistoryItem = {
        route,
        url,
        params,
        timestamp: Date.now()
      };
      this.addToHistory(historyItem);

      // 跳转到指定页面
      await router.pushUrl({
        url,
        params
      });
    } catch (error) {
      // 安全处理错误信息
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      console.error(`Navigation to ${route} failed:`, errorMessage);
      throw new Error(`Navigation to ${route} failed: ${errorMessage}`);
    }
  }

  /**
   * 返回上一页
   */
  async navigateToBack(): Promise<void> {
    try {
      // 使用router.back而非router.backTo，保持简单的返回逻辑
      await router.back();
      this.removeLastFromHistory();
    } catch (error) {
      console.error('Navigation back failed:', error);
      // 优化错误处理，提供更详细的错误信息
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
      throw new Error(`Navigation back failed: ${errorMsg}`);
    }
  }

  /**
   * 返回首页（清空导航栈）
   */
  async backToHome(): Promise<void> {
    try {
      // 直接使用pushUrl替换clear+push的组合
      await router.pushUrl({
        url: this.getPageUrl(PageRoute.HOME),
        params: {},
        mode: router.RouterMode.SingleTop // 使用SingleTop模式避免重复创建
      });
      this.navigationHistory = [];
      await this.saveNavigationHistory();
    } catch (error) {
      console.error('Navigation back to home failed:', error);
      // 优化错误处理
      const errorMsg = error instanceof Error ? error.message : 'Unknown error';
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
      await router.replaceUrl({
        url,
        params
      });
      this.replaceLastInHistory({ route, url, params, timestamp: Date.now() });
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
      // 将历史记录转换为可序列化格式
      const serializableHistory = this.navigationHistory.map(item => ({
        ...item,
        params: item.params ? StorageUtil.validateValue(item.params) : null
      }));
      await this.storageUtil.save('navigationHistory', serializableHistory);
    } catch (error) {
      console.error('Failed to save navigation history:', error);
    }
  }

  /**
   * 从存储加载导航历史
   */
  async loadNavigationHistory(): Promise<void> {
    try {
      const history = await this.storageUtil.get('navigationHistory', []);
      // 确保类型安全
      if (Array.isArray(history)) {
        // 避免直接类型断言，进行基本的类型检查
        this.navigationHistory = history.filter(item => 
          item && typeof item === 'object' && 
          typeof item.route === 'string' && 
          typeof item.url === 'string' && 
          typeof item.timestamp === 'number'
        ).map(item => ({ ...item }));
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
    const state = router.getState();
    const url = state.path || '';
    
    // 从URL映射回路由 - 使用数组避免索引签名问题
    const routeMap = [
      { url: 'pages/HomePage', route: PageRoute.HOME },
      { url: 'pages/VideoPlayPage', route: PageRoute.VIDEO_PLAY },
      { url: 'pages/LineManagerPage', route: PageRoute.LINE_MANAGER },
      { url: 'pages/SettingsPage', route: PageRoute.SETTINGS },
      { url: 'pages/SearchPage', route: PageRoute.SEARCH },
      { url: 'pages/FavoritesPage', route: PageRoute.FAVORITES },
      { url: 'pages/HistoryPage', route: PageRoute.HISTORY },
      { url: 'pages/CategoryPage', route: PageRoute.CATEGORY },
      { url: 'pages/DetailPage', route: PageRoute.DETAIL },
      { url: 'pages/LivePage', route: PageRoute.LIVE }
    ];

    // 查找匹配的URL
    for (let i = 0; i < routeMap.length; i++) {
      if (routeMap[i].url === url) {
        return routeMap[i].route;
      }
    }
    
    return PageRoute.HOME;
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
export type NavigationParams = {
  [key: string]: string | number | boolean | null | JsonData;
};

/**
   * 导航历史项
   */
export interface NavigationHistoryItem {
  route: string;
  url: string;
  params?: NavigationParams;
  timestamp: number;
}

/**
 * 视频播放参数
 */
export interface VideoPlayParams {
  videoId: string;
  siteKey: string;
  episodeName?: string;
  position?: number;
  fromSearch?: boolean;
}

/**
 * 详情页参数
 */
export interface DetailParams {
  id: string;
  siteKey: string;
  type?: 'vod' | 'live';
}

/**
 * 分类信息
 */
export interface CategoryInfo {
  id?: string;
  name: string;
  type?: 'vod' | 'live';
}