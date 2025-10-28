// 应用导航服务
// 管理页面路由、导航栈和页面跳转

import router from '@ohos.router';
import { StorageUtil } from '../common/util/StorageUtil';

export class AppNavigator {
  private static instance: AppNavigator;
  private storageUtil: StorageUtil;
  private navigationHistory: NavigationHistoryItem[] = [];

  private constructor() {
    this.storageUtil = StorageUtil.getInstance();
    this.loadNavigationHistory();
  }

  /**
   * 获取单例实例
   */
  public static getInstance(): AppNavigator {
    if (!AppNavigator.instance) {
      AppNavigator.instance = new AppNavigator();
    }
    return AppNavigator.instance;
  }

  /**
   * 导航到首页
   */
  public async navigateToHome(): Promise<void> {
    await this.navigateTo(PageRoute.HOME);
  }

  /**
   * 导航到视频播放页
   * @param params 播放参数
   */
  public async navigateToVideoPlay(params: VideoPlayParams): Promise<void> {
    await this.navigateTo(PageRoute.VIDEO_PLAY, params);
  }

  /**
   * 导航到线路管理页
   */
  public async navigateToLineManager(): Promise<void> {
    await this.navigateTo(PageRoute.LINE_MANAGER);
  }

  /**
   * 导航到设置页
   */
  public async navigateToSettings(): Promise<void> {
    await this.navigateTo(PageRoute.SETTINGS);
  }

  /**
   * 导航到搜索页
   * @param prefilledKeyword 预填关键词
   */
  public async navigateToSearch(prefilledKeyword?: string): Promise<void> {
    await this.navigateTo(PageRoute.SEARCH, { keyword: prefilledKeyword });
  }

  /**
   * 导航到收藏页
   */
  public async navigateToFavorites(): Promise<void> {
    await this.navigateTo(PageRoute.FAVORITES);
  }

  /**
   * 导航到历史记录页
   */
  public async navigateToHistory(): Promise<void> {
    await this.navigateTo(PageRoute.HISTORY);
  }

  /**
   * 导航到分类页
   * @param category 分类信息
   */
  public async navigateToCategory(category?: CategoryInfo): Promise<void> {
    await this.navigateTo(PageRoute.CATEGORY, category);
  }

  /**
   * 导航到详情页
   * @param params 详情参数
   */
  public async navigateToDetail(params: DetailParams): Promise<void> {
    await this.navigateTo(PageRoute.DETAIL, params);
  }

  /**
   * 导航到直播页
   */
  public async navigateToLive(): Promise<void> {
    await this.navigateTo(PageRoute.LIVE);
  }

  /**
   * 导航到页面
   * @param route 页面路由
   * @param params 路由参数
   */
  private async navigateTo(route: string, params?: any): Promise<void> {
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
      console.error(`Navigation to ${route} failed:`, error);
      throw error;
    }
  }

  /**
   * 返回上一页
   */
  public async back(): Promise<void> {
    try {
      await router.back();
      this.removeLastFromHistory();
    } catch (error) {
      console.error('Navigation back failed:', error);
      throw error;
    }
  }

  /**
   * 返回首页（清空导航栈）
   */
  public async backToHome(): Promise<void> {
    try {
      await router.clear();
      await router.pushUrl({
        url: this.getPageUrl(PageRoute.HOME)
      });
      this.navigationHistory = [];
      this.saveNavigationHistory();
    } catch (error) {
      console.error('Navigation back to home failed:', error);
      throw error;
    }
  }

  /**
   * 替换当前页面
   * @param route 目标路由
   * @param params 路由参数
   */
  public async replace(route: string, params?: any): Promise<void> {
    try {
      const url = this.getPageUrl(route);
      await router.replaceUrl({
        url,
        params
      });
      this.replaceLastInHistory({ route, url, params, timestamp: Date.now() });
    } catch (error) {
      console.error(`Navigation replace to ${route} failed:`, error);
      throw error;
    }
  }

  /**
   * 获取页面URL
   * @param route 页面路由
   */
  private getPageUrl(route: string): string {
    const urlMap: Record<string, string> = {
      [PageRoute.HOME]: 'pages/HomePage',
      [PageRoute.VIDEO_PLAY]: 'pages/VideoPlayPage',
      [PageRoute.LINE_MANAGER]: 'pages/LineManagerPage',
      [PageRoute.SETTINGS]: 'pages/SettingsPage',
      [PageRoute.SEARCH]: 'pages/SearchPage',
      [PageRoute.FAVORITES]: 'pages/FavoritesPage',
      [PageRoute.HISTORY]: 'pages/HistoryPage',
      [PageRoute.CATEGORY]: 'pages/CategoryPage',
      [PageRoute.DETAIL]: 'pages/DetailPage',
      [PageRoute.LIVE]: 'pages/LivePage'
    };

    return urlMap[route] || 'pages/HomePage';
  }

  /**
   * 添加到导航历史
   * @param item 历史记录项
   */
  private addToHistory(item: NavigationHistoryItem): void {
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
  private removeLastFromHistory(): void {
    if (this.navigationHistory.length > 0) {
      this.navigationHistory.pop();
      this.saveNavigationHistory();
    }
  }

  /**
   * 替换历史记录中的最后一项
   * @param item 新的历史记录项
   */
  private replaceLastInHistory(item: NavigationHistoryItem): void {
    if (this.navigationHistory.length > 0) {
      this.navigationHistory[this.navigationHistory.length - 1] = item;
      this.saveNavigationHistory();
    }
  }

  /**
   * 保存导航历史到存储
   */
  private async saveNavigationHistory(): Promise<void> {
    try {
      await this.storageUtil.save('navigationHistory', this.navigationHistory);
    } catch (error) {
      console.error('Failed to save navigation history:', error);
    }
  }

  /**
   * 从存储加载导航历史
   */
  private async loadNavigationHistory(): Promise<void> {
    try {
      const history = await this.storageUtil.get<any[]>('navigationHistory', []);
      this.navigationHistory = history || [];
    } catch (error) {
      console.error('Failed to load navigation history:', error);
      this.navigationHistory = [];
    }
  }

  /**
   * 获取当前页面路由
   */
  public getCurrentRoute(): string {
    const state = router.getState();
    const url = state.path;
    
    // 从URL映射回路由
    const routeMap: Record<string, string> = {
      'pages/HomePage': PageRoute.HOME,
      'pages/VideoPlayPage': PageRoute.VIDEO_PLAY,
      'pages/LineManagerPage': PageRoute.LINE_MANAGER,
      'pages/SettingsPage': PageRoute.SETTINGS,
      'pages/SearchPage': PageRoute.SEARCH,
      'pages/FavoritesPage': PageRoute.FAVORITES,
      'pages/HistoryPage': PageRoute.HISTORY,
      'pages/CategoryPage': PageRoute.CATEGORY,
      'pages/DetailPage': PageRoute.DETAIL,
      'pages/LivePage': PageRoute.LIVE
    };

    return routeMap[url] || PageRoute.HOME;
  }
}

/**
 * 页面路由常量
 */
export class PageRoute {
  public static readonly HOME = 'home';
  public static readonly VIDEO_PLAY = 'videoPlay';
  public static readonly LINE_MANAGER = 'lineManager';
  public static readonly SETTINGS = 'settings';
  public static readonly SEARCH = 'search';
  public static readonly FAVORITES = 'favorites';
  public static readonly HISTORY = 'history';
  public static readonly CATEGORY = 'category';
  public static readonly DETAIL = 'detail';
  public static readonly LIVE = 'live';
}

/**
 * 导航历史项
 */
export interface NavigationHistoryItem {
  route: string;
  url: string;
  params?: any;
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